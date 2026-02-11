#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# Email AI Abstraction Layer — Backend selection, prompts, fallback
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         lib/em-ai.zsh
# Version:      0.1
# Date:         2026-02-10
#
# Used by:      lib/dispatchers/email-dispatcher.zsh, lib/em-cache.zsh
#
# Backends:     claude CLI, gemini CLI (extensible)
# Design:       Per-operation backend selection, timeout, fallback chain,
#               cache integration to avoid redundant AI calls.
#
# ══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════
# BACKEND CONFIGURATION
# ═══════════════════════════════════════════════════════════════════

typeset -gA _EM_AI_BACKENDS=(
    [claude_cmd]="claude"
    [claude_flags]="-p --output-format text"
    [gemini_cmd]="gemini"
    [gemini_flags]=""
    [default]="${FLOW_EMAIL_AI:-claude}"
    [timeout]="${FLOW_EMAIL_AI_TIMEOUT:-15}"
)

# Per-operation defaults (timeout in seconds)
typeset -gA _EM_AI_OP_TIMEOUT=(
    [classify]=10
    [summarize]=15
    [draft]=30
    [schedule]=15
    [template]=20
)

# ═══════════════════════════════════════════════════════════════════
# CORE QUERY FUNCTION
# ═══════════════════════════════════════════════════════════════════

_em_ai_query() {
    # Core AI query function with cache, timeout, fallback
    # Args:
    #   $1 - operation: classify|summarize|draft|schedule|template
    #   $2 - prompt: the system/instruction prompt
    #   $3 - input: email content to process
    #   $4 - backend_override: force specific backend (optional)
    #   $5 - cache_key: message ID for caching (optional)
    #
    # Returns: AI response on stdout, exit code 0/1
    local operation="$1"
    local prompt="$2"
    local input="$3"
    local backend_override="$4"
    local cache_key="${5:-}"

    # --- Step 1: Cache check ---
    if [[ -n "$cache_key" ]] && typeset -f _em_cache_get &>/dev/null; then
        local cached
        cached=$(_em_cache_get "$operation" "$cache_key" 2>/dev/null)
        if [[ -n "$cached" ]]; then
            echo "$cached"
            return 0
        fi
    fi

    # --- Step 2: Backend selection ---
    local backend
    if [[ -n "$backend_override" ]]; then
        backend="$backend_override"
    else
        backend=$(_em_ai_backend_for_op "$operation")
    fi

    # --- Step 3: Execute with timeout ---
    local timeout_s
    timeout_s=$(_em_ai_timeout_for_op "$operation")
    local result=""
    result=$(_em_ai_execute "$backend" "$prompt" "$input" "$timeout_s")
    local exit_code=$?

    # --- Step 4: Fallback on failure ---
    if [[ $exit_code -ne 0 ]]; then
        local fallback
        for fallback in $(_em_ai_fallback_chain "$backend"); do
            _flow_log_debug "em-ai: trying fallback backend: $fallback" 2>/dev/null
            result=$(_em_ai_execute "$fallback" "$prompt" "$input" "$timeout_s")
            exit_code=$?
            [[ $exit_code -eq 0 ]] && break
        done
    fi

    # --- Step 5: Cache result ---
    if [[ $exit_code -eq 0 && -n "$cache_key" && -n "$result" ]]; then
        if typeset -f _em_cache_set &>/dev/null; then
            _em_cache_set "$operation" "$cache_key" "$result"
        fi
    fi

    # --- Step 6: Log usage ---
    if typeset -f _flow_ai_log_usage &>/dev/null; then
        _flow_ai_log_usage "em" "em:$operation" \
            "$( [[ $exit_code -eq 0 ]] && echo true || echo false )" \
            "0" 2>/dev/null
    fi

    [[ $exit_code -eq 0 ]] && echo "$result"
    return $exit_code
}

# ═══════════════════════════════════════════════════════════════════
# BACKEND EXECUTION
# ═══════════════════════════════════════════════════════════════════

_em_ai_execute() {
    # Execute a single AI backend call
    # Args: backend, prompt, input, timeout_seconds
    local backend="$1" prompt="$2" input="$3" timeout_s="${4:-15}"

    case "$backend" in
        claude)
            if ! command -v claude &>/dev/null; then
                return 1
            fi
            echo "$input" | timeout "$timeout_s" \
                claude -p "$prompt" --output-format text 2>/dev/null
            local rc=$?
            if [[ $rc -eq 124 ]]; then
                _flow_log_warning "AI timed out (claude, ${timeout_s}s)" 2>/dev/null
            fi
            return $rc
            ;;
        gemini)
            if ! command -v gemini &>/dev/null; then
                return 1
            fi
            echo "$input" | timeout "$timeout_s" \
                gemini "$prompt" 2>/dev/null
            local rc=$?
            if [[ $rc -eq 124 ]]; then
                _flow_log_warning "AI timed out (gemini, ${timeout_s}s)" 2>/dev/null
            fi
            return $rc
            ;;
        none|off)
            return 1
            ;;
        *)
            _flow_log_error "em-ai: unknown backend: $backend" 2>/dev/null
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# BACKEND SELECTION HELPERS
# ═══════════════════════════════════════════════════════════════════

_em_ai_backend_for_op() {
    # Get configured backend for an operation
    # Falls back to default if no per-op config
    local operation="$1"
    echo "${_EM_AI_BACKENDS[default]}"
}

_em_ai_timeout_for_op() {
    # Get timeout for an operation
    local operation="$1"
    echo "${_EM_AI_OP_TIMEOUT[$operation]:-${_EM_AI_BACKENDS[timeout]}}"
}

_em_ai_fallback_chain() {
    # Return fallback backends (excluding the one that just failed)
    local failed_backend="$1"
    local -a chain=(claude gemini)
    local fb
    for fb in "${chain[@]}"; do
        [[ "$fb" != "$failed_backend" ]] && command -v "$fb" &>/dev/null && echo "$fb"
    done
}

_em_ai_available() {
    # Check which AI backends are available
    # Returns: space-separated list of available backends
    local -a available=()
    command -v claude &>/dev/null && available+=(claude)
    command -v gemini &>/dev/null && available+=(gemini)
    echo "${available[*]}"
}

# ═══════════════════════════════════════════════════════════════════
# OPERATION-SPECIFIC PROMPTS
# ═══════════════════════════════════════════════════════════════════

_em_ai_classify_prompt() {
    cat <<'PROMPT'
Classify this email into exactly ONE category. Return ONLY the category name.

Categories:
- student-question (academic query, assignment question, grade inquiry)
- admin-important (department notice, policy change, deadline, requires action)
- admin-info (FYI notices, newsletters from institution)
- scheduling (meeting request, calendar invite, office hours, event)
- newsletter (external newsletter, marketing, mailing list)
- personal (colleague, friend, non-work)
- automated (CI/CD, GitHub, system alerts, receipts)
- urgent (deadline today, emergency, escalation)

Return only the category name, nothing else.
PROMPT
}

_em_ai_summarize_prompt() {
    cat <<'PROMPT'
Summarize this email in exactly ONE line (max 80 characters).
Focus on: who wants what and by when.
No greeting, no pleasantries. Just the core ask or information.
Return only the summary line, nothing else.
PROMPT
}

_em_ai_draft_prompt() {
    local context_file="$1"
    local template_content="$2"

    local base_prompt='Draft a reply to this email. Be professional, concise, and helpful.'

    # Inject project context if available
    if [[ -n "$context_file" && -f "$context_file" ]]; then
        base_prompt+="

Context about the sender/topic (use this to personalize the reply):
$(cat "$context_file")"
    fi

    # Inject template structure if provided
    if [[ -n "$template_content" ]]; then
        base_prompt+="

Use this template structure (adapt tone and specifics to the email):
$template_content"
    fi

    base_prompt+='

Rules:
- Match the formality level of the original email
- Be direct and helpful
- If the email asks a question, answer it
- If the email requests action, acknowledge and commit to timeline
- Keep it under 200 words unless the topic requires more detail
- Do NOT add a subject line. Return only the reply body.'

    echo "$base_prompt"
}

_em_ai_schedule_prompt() {
    cat <<'PROMPT'
Extract any dates, times, deadlines, or meeting information from this email.

Return JSON (and ONLY JSON, no markdown fences) in this format:
{
  "events": [
    {
      "title": "Brief event title",
      "date": "YYYY-MM-DD",
      "time": "HH:MM" or null,
      "duration_minutes": number or null,
      "location": "string" or null,
      "type": "meeting|deadline|event|office-hours"
    }
  ]
}

If no dates/times found, return: {"events": []}
PROMPT
}

# ═══════════════════════════════════════════════════════════════════
# CATEGORY DISPLAY
# ═══════════════════════════════════════════════════════════════════

_em_category_icon() {
    # Map AI classification to display icon
    local category="$1"
    case "$category" in
        student-question)  echo "${_C_BLUE}Q${_C_NC}" ;;
        admin-important)   echo "${_C_RED}!${_C_NC}" ;;
        admin-info)        echo "${_C_DIM}i${_C_NC}" ;;
        scheduling)        echo "${_C_CYAN}S${_C_NC}" ;;
        newsletter)        echo "${_C_DIM}N${_C_NC}" ;;
        personal)          echo "${_C_GREEN}P${_C_NC}" ;;
        automated)         echo "${_C_DIM}A${_C_NC}" ;;
        urgent)            echo "${_C_RED}U${_C_NC}" ;;
        *)                 echo " " ;;
    esac
}
