# SPEC: Email Dispatcher (`em`) Architecture

**Date:** 2026-02-10
**Version:** 0.1.0 (Design Phase)
**Author:** DT + Claude
**Status:** PROPOSAL
**Dependencies:** himalaya CLI, claude CLI, gemini CLI (optional), fzf, jq, w3m, bat

---

## 1. System Architecture Overview

The `em` dispatcher is a pure ZSH email command dispatcher that wraps himalaya CLI for email operations and pipes email content through AI backends (claude CLI, gemini CLI, or MCP server) for classification, summarization, draft generation, and scheduling extraction.

### 1.1 Architectural Principles

1. **Pure ZSH** -- Sub-10ms for non-AI operations. No Node.js/Python runtime.
2. **AI as a pipeline stage** -- Email always works without AI. AI enriches, never gates.
3. **himalaya as the transport abstraction** -- All IMAP/SMTP goes through himalaya. himalaya is post-1.0 (v1.0.0 Dec 2024, v1.1.0 Jan 2025) with semver guarantees, but the adapter layer still isolates CLI specifics for clean separation.
4. **Explicit send only** -- Nothing ever sends without the user pressing a confirm key. AI drafts are always review-first.
5. **Project-context-aware** -- When a `work` session is active, `em` filters and contextualizes automatically.

### 1.2 Component Diagram

```
+-----------------------------------------------------------------------+
|                        em() DISPATCHER                                 |
|  (lib/dispatchers/em-dispatcher.zsh)                                   |
|                                                                        |
|  em inbox | read | send | reply | find | pick | unread                 |
|  em dash  | folders | html | attach | doctor                          |
|  em respond | watch | cal                                              |
+-------+----+-------+--------+---------+----------+--------------------+
        |    |       |        |         |          |
        v    |       v        |         v          |
  +---------+| +----------+  |  +-----------+     |
  | himalaya || | AI Layer |  |  | Cache     |     |
  | Adapter  || | (_em_ai) |  |  | Manager   |     |
  | Layer    || |          |  |  |           |     |
  +---------+| +----+-----+  |  +-----+-----+     |
        |    |      |        |        |            |
        v    |      v        v        v            v
  +---------+| +--------+ +------+ +--------+ +--------+
  | himalaya || | claude | | .flow| | .flow/ | | macOS  |
  | CLI      || | gemini | | /em- | | email- | | notify |
  |          || | MCP    | | cfg  | | cache/ | | cal    |
  +----------+| +--------+ +------+ +--------+ +--------+
              |
              v
         +---------+
         | Render  |
         | Pipeline|
         | w3m/bat |
         | /glow   |
         +---------+
```

### 1.3 Layer Responsibilities

| Layer | Responsibility | Latency Budget |
|-------|---------------|----------------|
| Dispatcher (`em()`) | Route subcommand, parse flags | < 1ms |
| himalaya Adapter | Translate `em` calls to `himalaya` CLI commands | < 5ms overhead |
| AI Abstraction (`_em_ai_query`) | Backend selection, prompt assembly, timeout/fallback | < 50ms overhead |
| Cache Manager | TTL check, read/write `.flow/email-cache/` | < 5ms |
| Render Pipeline | Content-type detection, renderer dispatch | < 10ms |
| Notification System | Urgency classification, macOS notification dispatch | < 5ms |

---

## 2. File Structure

```
flow-cli/
  lib/
    dispatchers/
      em-dispatcher.zsh          # Main dispatcher + help
    em-himalaya.zsh              # himalaya CLI adapter (abstraction layer)
    em-ai.zsh                    # AI abstraction layer (3 backends)
    em-render.zsh                # Content rendering pipeline
    em-respond.zsh               # Draft response workflow
    em-calendar.zsh              # Scheduling extraction + calendar integration
    em-notify.zsh                # Urgency detection + macOS notifications
    em-cache.zsh                 # AI result caching with TTL
    em-templates.zsh             # YAML template loading + AI customization
  commands/
    em-doctor.zsh                # Dependency health check
  completions/
    _em                          # ZSH completions for em
```

**Per-project configuration (optional):**
```
<project-root>/
  .flow/
    email-config.yml             # Per-project email config
    email-templates/             # YAML response templates
      student-question.yml
      meeting-confirm.yml
      admin-reply.yml
    email-cache/                 # AI result cache (gitignored)
      summaries/                 # msg-id -> summary
      classifications/           # msg-id -> category
      drafts/                    # msg-id -> draft response
      schedules/                 # msg-id -> extracted dates
```

**Global configuration:**
```
~/.config/flow/
  email/
    config.yml                   # Global email settings
    templates/                   # Global templates
    backends.yml                 # AI backend preferences per operation
```

---

## 3. himalaya Adapter Layer

### 3.1 Design Rationale

himalaya reached v1.0.0 (Dec 2024) with semver guarantees -- breaking changes now require a major version bump. The adapter layer still isolates all himalaya-specific command syntax behind stable internal functions for clean architecture. himalaya also ships native OAuth2/XOAUTH2, potentially eliminating the need for `email-oauth2-proxy`.

### 3.2 Adapter API

```zsh
# lib/em-himalaya.zsh -- himalaya CLI adapter

# All functions return structured output (tab-separated or JSON)
# All functions set $? for success/failure

_em_hml_list() {
    # List messages in a folder
    # Args: folder (default: INBOX), count (default: 25)
    # Returns: tab-separated lines: ID\tFROM\tSUBJECT\tDATE\tFLAGS
    local folder="${1:-INBOX}" count="${2:-25}"
    himalaya message list --folder "$folder" --page-size "$count" \
        --output json 2>/dev/null
}

_em_hml_read() {
    # Read a single message
    # Args: message_id, format (plain|html|raw)
    # Returns: message content
    local msg_id="$1" fmt="${2:-plain}"
    case "$fmt" in
        html) himalaya message read "$msg_id" --header "Content-Type" \
                  --output json 2>/dev/null ;;
        raw)  himalaya message read "$msg_id" --raw 2>/dev/null ;;
        *)    himalaya message read "$msg_id" --output json 2>/dev/null ;;
    esac
}

_em_hml_send() {
    # Send a message (from file or stdin)
    # Args: file_path (or reads stdin)
    local msg_file="$1"
    if [[ -n "$msg_file" ]]; then
        himalaya message send < "$msg_file"
    else
        himalaya message send
    fi
}

_em_hml_reply() {
    # Create reply draft
    # Args: message_id, reply_all (bool)
    local msg_id="$1" reply_all="${2:-false}"
    if [[ "$reply_all" == "true" ]]; then
        himalaya message reply --all "$msg_id"
    else
        himalaya message reply "$msg_id"
    fi
}

_em_hml_search() {
    # Search messages
    # Args: query, folder (default: INBOX)
    local query="$1" folder="${2:-INBOX}"
    himalaya message list --folder "$folder" --query "$query" \
        --output json 2>/dev/null
}

_em_hml_folders() {
    # List available folders
    himalaya folder list --output json 2>/dev/null
}

_em_hml_unread_count() {
    # Get unread count for a folder
    # Fast path: use himalaya's envelope list with UNSEEN filter
    local folder="${1:-INBOX}"
    himalaya message list --folder "$folder" --query "unseen" \
        --output json 2>/dev/null | jq 'length'
}

_em_hml_attachments() {
    # Download attachments from a message
    # Args: message_id, output_dir
    local msg_id="$1" out_dir="${2:-.}"
    himalaya attachment download "$msg_id" --dir "$out_dir"
}

_em_hml_idle() {
    # Start IMAP IDLE watch (blocking)
    # Args: folder (default: INBOX), callback function name
    local folder="${1:-INBOX}" callback="$2"
    himalaya message watch --folder "$folder"
}

_em_hml_flags() {
    # Get/set message flags
    # Args: message_id, action (add|remove), flag
    local msg_id="$1" action="$2" flag="$3"
    case "$action" in
        add)    himalaya flag add "$msg_id" "$flag" ;;
        remove) himalaya flag remove "$msg_id" "$flag" ;;
        *)      himalaya flag list "$msg_id" ;;
    esac
}
```

### 3.3 Error Handling

```zsh
_em_hml_check() {
    # Verify himalaya is configured and can connect
    # Returns: 0 on success, 1 on failure
    # Used by: em doctor, em dash (pre-check)
    if ! command -v himalaya &>/dev/null; then
        _flow_log_error "himalaya not installed"
        _flow_log_info "Install: brew install himalaya"
        return 1
    fi

    # Quick connectivity test (list 1 message)
    if ! himalaya message list --page-size 1 &>/dev/null; then
        _flow_log_error "himalaya cannot connect to mailbox"
        _flow_log_info "Check config: himalaya account list"
        return 1
    fi
    return 0
}
```

---

## 4. AI Abstraction Layer

### 4.1 Design Goals

- Support 3 backends: `claude` CLI, `gemini` CLI, Claude Desktop MCP
- Per-operation backend selection (summaries via gemini, drafts via claude)
- Timeout + fallback chain
- Cache integration to avoid redundant AI calls
- Zero API keys required (uses CLI auth: Claude Max subscription, Google AI Studio free tier)

### 4.2 Backend Configuration

```yaml
# ~/.config/flow/email/backends.yml
default: claude

# Per-operation backend overrides
operations:
  classify:    { backend: gemini, timeout: 10 }
  summarize:   { backend: gemini, timeout: 15 }
  draft:       { backend: claude, timeout: 30 }
  schedule:    { backend: claude, timeout: 15 }
  template:    { backend: claude, timeout: 20 }

# Fallback chain (tried in order if primary fails)
fallback_chain:
  - claude
  - gemini

# Backend-specific settings
backends:
  claude:
    command: claude
    flags: ["-p", "--output-format", "text"]
    max_input_tokens: 100000       # claude handles long threads
  gemini:
    command: gemini
    flags: []                       # gemini CLI uses different syntax
    max_input_tokens: 32000
  mcp:
    server: email-ai               # MCP server name
    tool: process_email             # Tool name to invoke
```

### 4.3 Core AI Function

```zsh
# lib/em-ai.zsh -- AI abstraction layer

# Global config (loaded once at source time)
typeset -gA _EM_AI_BACKENDS=(
    [claude_cmd]="claude"
    [claude_flags]="-p --output-format text"
    [gemini_cmd]="gemini"
    [gemini_flags]=""
    [default]="claude"
    [timeout]=15
)

_em_ai_query() {
    # Core AI query function
    # Args:
    #   $1 - operation: classify|summarize|draft|schedule|template
    #   $2 - prompt: the system/instruction prompt
    #   $3 - input: email content to process
    #   $4 - backend_override: force specific backend (optional)
    #
    # Returns: AI response on stdout, exit code 0/1
    #
    # Behavior:
    #   1. Check cache first (skip AI if cached result exists)
    #   2. Select backend (operation config > override > default)
    #   3. Execute with timeout
    #   4. On failure, try fallback chain
    #   5. Cache successful result
    #   6. Log usage stats

    local operation="$1"
    local prompt="$2"
    local input="$3"
    local backend_override="$4"
    local cache_key="${5:-}"  # optional cache key (message ID)

    # --- Step 1: Cache check ---
    if [[ -n "$cache_key" ]]; then
        local cached=$(_em_cache_get "$operation" "$cache_key")
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
    local result=""
    local timeout=$(_em_ai_timeout_for_op "$operation")

    result=$(_em_ai_execute "$backend" "$prompt" "$input" "$timeout")
    local exit_code=$?

    # --- Step 4: Fallback on failure ---
    if [[ $exit_code -ne 0 ]]; then
        local fallback
        for fallback in $(_em_ai_fallback_chain "$backend"); do
            _flow_log_debug "em-ai: trying fallback backend: $fallback"
            result=$(_em_ai_execute "$fallback" "$prompt" "$input" "$timeout")
            exit_code=$?
            [[ $exit_code -eq 0 ]] && break
        done
    fi

    # --- Step 5: Cache result ---
    if [[ $exit_code -eq 0 && -n "$cache_key" && -n "$result" ]]; then
        _em_cache_set "$operation" "$cache_key" "$result"
    fi

    # --- Step 6: Log usage ---
    local duration_ms=$(( SECONDS * 1000 ))  # approximate
    _flow_ai_log_usage "em" "em:$operation" \
        "$( [[ $exit_code -eq 0 ]] && echo true || echo false )" \
        "$duration_ms" 2>/dev/null

    [[ $exit_code -eq 0 ]] && echo "$result"
    return $exit_code
}

_em_ai_execute() {
    # Execute a single AI backend call
    # Args: backend, prompt, input, timeout_seconds
    local backend="$1" prompt="$2" input="$3" timeout_s="${4:-15}"

    case "$backend" in
        claude)
            echo "$input" | _flow_timeout "$timeout_s" \
                claude -p "$prompt" --output-format text 2>/dev/null
            ;;
        gemini)
            # gemini CLI takes prompt as argument, reads stdin
            echo "$input" | _flow_timeout "$timeout_s" \
                gemini "$prompt" 2>/dev/null
            ;;
        mcp)
            # MCP tool call via claude CLI with MCP server
            # This uses claude's MCP integration to call a custom tool
            _flow_timeout "$timeout_s" \
                claude -p "Use the process_email tool: $prompt

Input email:
$input" --output-format text 2>/dev/null
            ;;
        *)
            _flow_log_error "em-ai: unknown backend: $backend"
            return 1
            ;;
    esac
}

_em_ai_backend_for_op() {
    # Get configured backend for an operation
    # Falls back to default if no per-op config
    local operation="$1"
    local config_file="${FLOW_CONFIG_DIR}/email/backends.yml"

    if [[ -f "$config_file" ]] && command -v yq &>/dev/null; then
        local backend=$(yq -r ".operations.${operation}.backend // .default" \
            "$config_file" 2>/dev/null)
        echo "${backend:-${_EM_AI_BACKENDS[default]}}"
    else
        echo "${_EM_AI_BACKENDS[default]}"
    fi
}

_em_ai_timeout_for_op() {
    local operation="$1"
    local config_file="${FLOW_CONFIG_DIR}/email/backends.yml"

    if [[ -f "$config_file" ]] && command -v yq &>/dev/null; then
        local timeout=$(yq -r ".operations.${operation}.timeout // .timeout // 15" \
            "$config_file" 2>/dev/null)
        echo "${timeout:-15}"
    else
        echo "15"
    fi
}

_em_ai_fallback_chain() {
    # Return fallback backends (excluding the one that just failed)
    local failed_backend="$1"
    local chain=("claude" "gemini")
    local fb
    for fb in "${chain[@]}"; do
        [[ "$fb" != "$failed_backend" ]] && echo "$fb"
    done
}

_em_ai_available() {
    # Check which AI backends are available
    # Returns: space-separated list of available backends
    local available=()
    command -v claude &>/dev/null && available+=(claude)
    command -v gemini &>/dev/null && available+=(gemini)
    echo "${available[*]}"
}
```

### 4.4 Operation-Specific Prompts

```zsh
# Prompt templates for each AI operation

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
```

---

## 5. Caching Strategy

### 5.1 Cache Architecture

AI results are expensive (2-30 seconds per call). Cache aggressively.

```
.flow/email-cache/
  summaries/
    <message-id-hash>.txt        # 1-line summary
  classifications/
    <message-id-hash>.txt        # category name
  drafts/
    <message-id-hash>.txt        # draft response
  schedules/
    <message-id-hash>.json       # extracted dates
  metadata.json                  # cache stats, last cleanup timestamp
```

### 5.2 Cache Implementation

```zsh
# lib/em-cache.zsh

# TTL values (seconds)
typeset -gA _EM_CACHE_TTL=(
    [summaries]=86400      # 24 hours -- summaries don't change
    [classifications]=86400 # 24 hours -- classification is stable
    [drafts]=3600          # 1 hour -- drafts might need refreshing
    [schedules]=86400      # 24 hours
    [unread]=60            # 1 minute -- unread count changes often
)

_em_cache_dir() {
    # Get cache directory (project-local or global)
    local project_root=$(_flow_find_project_root 2>/dev/null)
    if [[ -n "$project_root" && -d "$project_root/.flow" ]]; then
        echo "$project_root/.flow/email-cache"
    else
        echo "${FLOW_DATA_DIR}/email-cache"
    fi
}

_em_cache_key() {
    # Generate cache key from message ID
    # Uses md5 hash to avoid filesystem-unfriendly characters
    local msg_id="$1"
    echo "$msg_id" | md5 -q 2>/dev/null || echo "$msg_id" | md5sum | cut -d' ' -f1
}

_em_cache_get() {
    # Get cached result if fresh
    # Args: operation (summaries|classifications|drafts|schedules), message_id
    # Returns: cached content or empty string
    local operation="$1" msg_id="$2"
    local cache_dir="$(_em_cache_dir)/$operation"
    local key=$(_em_cache_key "$msg_id")
    local cache_file="$cache_dir/$key.txt"

    [[ ! -f "$cache_file" ]] && return 1

    # Check TTL
    local ttl="${_EM_CACHE_TTL[$operation]:-3600}"
    local file_age=$(( $(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || echo 0) ))

    if (( file_age > ttl )); then
        # Expired
        rm -f "$cache_file"
        return 1
    fi

    cat "$cache_file"
    return 0
}

_em_cache_set() {
    # Write result to cache
    # Args: operation, message_id, content
    local operation="$1" msg_id="$2" content="$3"
    local cache_dir="$(_em_cache_dir)/$operation"
    local key=$(_em_cache_key "$msg_id")

    [[ ! -d "$cache_dir" ]] && mkdir -p "$cache_dir"

    echo "$content" > "$cache_dir/$key.txt"
}

_em_cache_invalidate() {
    # Invalidate cache for a message (all operations)
    local msg_id="$1"
    local cache_base="$(_em_cache_dir)"
    local key=$(_em_cache_key "$msg_id")

    for op_dir in "$cache_base"/*(N/); do
        rm -f "$op_dir/$key.txt"
    done
}

_em_cache_clear() {
    # Clear entire cache
    local cache_dir="$(_em_cache_dir)"
    if [[ -d "$cache_dir" ]]; then
        local size=$(du -sh "$cache_dir" 2>/dev/null | awk '{print $1}')
        rm -rf "$cache_dir"
        _flow_log_success "Email cache cleared ($size freed)"
    else
        _flow_log_info "No email cache to clear"
    fi
}

_em_cache_stats() {
    # Show cache statistics
    local cache_dir="$(_em_cache_dir)"
    [[ ! -d "$cache_dir" ]] && echo "No cache" && return

    echo ""
    echo "${FLOW_COLORS[header]}Email Cache${FLOW_COLORS[reset]}"
    for op_dir in "$cache_dir"/*(N/); do
        local op_name="${op_dir:t}"
        local count=$(ls -1 "$op_dir" 2>/dev/null | wc -l | tr -d ' ')
        local size=$(du -sh "$op_dir" 2>/dev/null | awk '{print $1}')
        printf "  %-18s %4s items  %s\n" "$op_name" "$count" "$size"
    done
    echo ""
}
```

### 5.3 Cache Warming Strategy

When `em dash` is called, it can warm the cache in the background:

```zsh
_em_cache_warm() {
    # Background-warm cache for latest N messages
    # Called by: em dash, em inbox (background)
    local count="${1:-10}"

    # Get latest message IDs
    local msg_ids=($(_em_hml_list INBOX "$count" | jq -r '.[].id'))

    for msg_id in "${msg_ids[@]}"; do
        # Skip if already cached
        _em_cache_get "summaries" "$msg_id" &>/dev/null && continue

        # Background: classify + summarize
        {
            local content=$(_em_hml_read "$msg_id" plain)
            _em_ai_query "classify" "$(_em_ai_classify_prompt)" "$content" "" "$msg_id"
            _em_ai_query "summarize" "$(_em_ai_summarize_prompt)" "$content" "" "$msg_id"
        } &
    done

    # Don't wait -- let it run in background
}
```

---

## 6. Data Flow Diagrams

### 6.1 Flow: `em inbox` with AI Summaries

```
User: em inbox 25
    |
    v
em() dispatcher
    |
    v
_em_inbox(25)
    |
    +---> _em_hml_list(INBOX, 25)  ---- himalaya message list --json --->  IMAP
    |         |
    |         v
    |     JSON array of 25 messages (id, from, subject, date, flags)
    |         |
    |         v
    +---> For each message:
    |       |
    |       +---> _em_cache_get("summaries", msg_id)
    |       |       |
    |       |       +--[HIT]---> use cached summary
    |       |       |
    |       |       +--[MISS]--> _em_cache_get("classifications", msg_id)
    |       |                     |
    |       |                     +--[MISS]--> queue for batch AI
    |       |
    |       +---> _em_cache_get("classifications", msg_id)
    |               +--[HIT]---> use cached category
    |               +--[MISS]--> queue for batch AI
    |
    +---> Batch AI (for uncached messages):
    |       |
    |       +---> _em_ai_batch_enrich(message_ids)
    |               |
    |               +---> For each uncached msg:
    |               |       _em_ai_query("classify", ..., msg_id)
    |               |       _em_ai_query("summarize", ..., msg_id)
    |               |       (results auto-cached by _em_ai_query)
    |               |
    |               +---> Return enriched data
    |
    +---> Render table:
            |
            +---> printf formatted output:
                  [category-icon] [from] [subject] [summary] [age]

                  Example:
                  [Q] john@uni.edu    Assignment 3 help       Needs extension for Q3   2h
                  [!] dean@uni.edu    Budget deadline          FY27 due Friday          4h
                  [N] nature.com      Weekly digest            Top papers this week     1d
```

### 6.2 Flow: `em respond` Draft Workflow

```
User: em respond
    |
    v
em() dispatcher
    |
    v
_em_respond()
    |
    +---> _em_hml_list(INBOX, 50)  -- get recent messages
    |
    +---> Filter: only messages needing replies
    |       |
    |       +---> Exclude: automated, newsletters, already-replied
    |       +---> Include: student-question, admin-important, scheduling, personal
    |       |
    |       v
    |     actionable_messages[] (e.g., 8 messages)
    |
    +---> For each actionable message:
    |       |
    |       +---> _em_hml_read(msg_id)  -- full content + thread
    |       |
    |       +---> _em_ai_query("draft", prompt_with_context, content, "", msg_id)
    |       |       |
    |       |       +---> Prompt includes:
    |       |               - Project context (syllabus, office hours from .flow/)
    |       |               - Template structure (if matching template exists)
    |       |               - Thread history (previous messages)
    |       |
    |       +---> Store draft in .flow/email-cache/drafts/<hash>.txt
    |
    +---> _flow_log_success "8 drafts generated"
    |
    v
User: em respond --review
    |
    v
_em_respond_review()
    |
    +---> Load all drafts from cache
    |
    +---> fzf picker (preview pane shows: original email + draft side by side)
    |       |
    |       +---> User sees each draft:
    |               [a]pprove  [e]dit  [s]kip  [r]egenerate  [q]uit
    |               |
    |               +--[approve]--> Mark for send queue
    |               +--[edit]-----> Open in $EDITOR, then mark for send
    |               +--[skip]-----> Next draft
    |               +--[regen]----> _em_ai_query("draft", ...) again
    |               +--[quit]-----> Exit review
    |
    +---> Show send queue summary:
    |       "Ready to send 5 of 8 drafts. Confirm? [y/N]"
    |
    +--[confirmed]--> For each approved:
    |                   _em_hml_reply(msg_id)  -- send via himalaya
    |                   _em_cache_invalidate(msg_id)
    |
    +---> _flow_log_success "5 replies sent"
```

### 6.3 Flow: Scheduling Extraction

```
User: em read 42
    |
    v
_em_read(42)
    |
    +---> _em_hml_read(42)  -- get message content
    |
    +---> _em_render(content)  -- display formatted
    |
    +---> _em_ai_query("schedule", schedule_prompt, content, "", "42")
    |       |
    |       v
    |     JSON: {"events": [{"title": "Faculty meeting", "date": "2026-02-14",
    |                        "time": "10:00", "duration_minutes": 60,
    |                        "location": "Room 301", "type": "meeting"}]}
    |
    +---> If events found:
            |
            +---> Display:
            |       "Found 1 event: Faculty meeting (Feb 14, 10:00 AM, Room 301)"
            |       "Add to calendar? [y/N]"
            |
            +--[yes]--> _em_cal_add(event_json)
                        |
                        +---> _em_cal_detect()  -- find calendar app
                        |       |
                        |       +--[Calendar.app]--> osascript AppleScript
                        |       +--[Fantastical]---> osascript AppleScript
                        |       +--[gcalcli]-------> gcalcli add ...
                        |       +--[none]----------> Generate .ics file
                        |
                        +---> _flow_log_success "Added to Calendar.app"
```

---

## 7. Dispatcher Implementation

### 7.1 Main Dispatcher

```zsh
# lib/dispatchers/em-dispatcher.zsh
# Email dispatcher - wraps himalaya with AI intelligence

em() {
    # No arguments -> show unread count + quick status
    if [[ $# -eq 0 ]]; then
        _em_quick_status
        return
    fi

    case "$1" in
        # ---- Core email operations ----
        inbox|in)       shift; _em_inbox "$@" ;;
        read|r)         shift; _em_read "$@" ;;
        send|s)         shift; _em_send "$@" ;;
        reply|re)       shift; _em_reply "$@" ;;
        find|search)    shift; _em_find "$@" ;;
        pick|p)         shift; _em_pick "$@" ;;
        unread|u)       shift; _em_unread "$@" ;;

        # ---- Views ----
        dash|d)         shift; _em_dash "$@" ;;
        folders|f)      shift; _em_folders "$@" ;;
        html)           shift; _em_html "$@" ;;
        attach|att)     shift; _em_attach "$@" ;;

        # ---- AI features ----
        respond|resp)   shift; _em_respond "$@" ;;
        classify|cl)    shift; _em_classify "$@" ;;
        summarize|sum)  shift; _em_summarize "$@" ;;
        cal|calendar)   shift; _em_cal "$@" ;;

        # ---- System ----
        watch|w)        shift; _em_watch "$@" ;;
        cache)          shift; _em_cache_cmd "$@" ;;
        config|cfg)     shift; _em_config "$@" ;;
        doctor|doc)     shift; _em_doctor "$@" ;;

        # ---- Help ----
        help|--help|-h) _em_help ;;

        # ---- Passthrough to himalaya ----
        *)              himalaya "$@" ;;
    esac
}
```

### 7.2 Key Command Implementations

```zsh
_em_quick_status() {
    # Default: show unread count (fast, cached)
    local cached_count=$(_em_cache_get "unread" "inbox")
    if [[ -n "$cached_count" ]]; then
        echo "${FLOW_COLORS[accent]}$cached_count${FLOW_COLORS[reset]} unread"
    else
        local count=$(_em_hml_unread_count)
        _em_cache_set "unread" "inbox" "$count"
        echo "${FLOW_COLORS[accent]}$count${FLOW_COLORS[reset]} unread"
    fi
}

_em_inbox() {
    local count="${1:-25}"
    local folder="${2:-INBOX}"
    local no_ai=false

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-ai)    no_ai=true; shift ;;
            --folder)   shift; folder="$1"; shift ;;
            -n|--count) shift; count="$1"; shift ;;
            *)          shift ;;
        esac
    done

    # Fetch messages
    local messages=$(_em_hml_list "$folder" "$count")
    if [[ -z "$messages" ]] || [[ "$messages" == "[]" ]]; then
        _flow_log_info "No messages in $folder"
        return 0
    fi

    # Display header
    echo ""
    echo "${FLOW_COLORS[header]}Inbox${FLOW_COLORS[reset]} ($folder)"
    echo "${FLOW_COLORS[muted]}$(printf '%.0s-' {1..60})${FLOW_COLORS[reset]}"

    # Process each message
    echo "$messages" | jq -c '.[]' | while IFS= read -r msg; do
        local msg_id=$(echo "$msg" | jq -r '.id')
        local from=$(echo "$msg" | jq -r '.from // "unknown"' | cut -c1-20)
        local subject=$(echo "$msg" | jq -r '.subject // "(no subject)"' | cut -c1-35)
        local date_str=$(echo "$msg" | jq -r '.date // ""')

        # AI enrichment (if enabled and available)
        local category_icon=" "
        local summary=""

        if [[ "$no_ai" != "true" ]] && [[ -n "$(_em_ai_available)" ]]; then
            # Try cache first (instant)
            local cached_cat=$(_em_cache_get "classifications" "$msg_id" 2>/dev/null)
            if [[ -n "$cached_cat" ]]; then
                category_icon=$(_em_category_icon "$cached_cat")
            fi

            local cached_sum=$(_em_cache_get "summaries" "$msg_id" 2>/dev/null)
            if [[ -n "$cached_sum" ]]; then
                summary="$cached_sum"
            fi
        fi

        # Format output
        printf " %s %-20s %-35s %s\n" \
            "$category_icon" "$from" "$subject" \
            "${summary:+${FLOW_COLORS[muted]}$summary${FLOW_COLORS[reset]}}"
    done

    echo ""

    # Background: warm cache for uncached messages
    if [[ "$no_ai" != "true" ]]; then
        _em_cache_warm "$count" &
    fi
}

_em_read() {
    local msg_id="$1"
    [[ -z "$msg_id" ]] && _flow_log_error "Message ID required" && return 1

    # Fetch message
    local content=$(_em_hml_read "$msg_id" "plain")
    [[ -z "$content" ]] && _flow_log_error "Could not read message $msg_id" && return 1

    # Detect content type and render
    _em_render "$content"

    # Check for schedule-worthy content (non-blocking)
    local schedule_result=$(_em_cache_get "schedules" "$msg_id" 2>/dev/null)
    if [[ -z "$schedule_result" && -n "$(_em_ai_available)" ]]; then
        # Run schedule extraction
        schedule_result=$(_em_ai_query "schedule" "$(_em_ai_schedule_prompt)" "$content" "" "$msg_id")
    fi

    # Show extracted events
    if [[ -n "$schedule_result" ]]; then
        local event_count=$(echo "$schedule_result" | jq '.events | length' 2>/dev/null)
        if [[ "$event_count" -gt 0 ]]; then
            echo ""
            echo "${FLOW_COLORS[accent]}Found $event_count event(s):${FLOW_COLORS[reset]}"
            echo "$schedule_result" | jq -r '.events[] |
                "  \(.date) \(.time // "all-day") - \(.title)\(.location | if . then " (\(.))" else "" end)"'
            echo ""
            if _flow_confirm "Add to calendar?"; then
                _em_cal_add "$schedule_result"
            fi
        fi
    fi
}

_em_pick() {
    # Interactive email picker with fzf
    local folder="${1:-INBOX}"

    command -v fzf &>/dev/null || {
        _flow_log_error "fzf required for pick mode"
        _flow_log_info "Install: brew install fzf"
        return 1
    }

    local messages=$(_em_hml_list "$folder" 50)
    [[ -z "$messages" ]] && _flow_log_info "No messages" && return 0

    # Build fzf input: ID | From | Subject
    local selected=$(echo "$messages" | jq -r '.[] | "\(.id)\t\(.from)\t\(.subject)"' | \
        fzf --delimiter='\t' \
            --with-nth=2.. \
            --preview="himalaya message read {1} 2>/dev/null | head -40" \
            --preview-window=right:50%:wrap \
            --header="Select email (Enter=read, Ctrl-R=reply, Ctrl-D=delete)" \
            --bind="ctrl-r:execute(em reply {1})" \
            --bind="ctrl-d:execute(himalaya message delete {1})")

    if [[ -n "$selected" ]]; then
        local selected_id=$(echo "$selected" | cut -f1)
        _em_read "$selected_id"
    fi
}
```

### 7.3 Category Icons

```zsh
_em_category_icon() {
    # Map AI classification to display icon
    local category="$1"
    case "$category" in
        student-question)  echo "${FLOW_COLORS[info]}Q${FLOW_COLORS[reset]}" ;;
        admin-important)   echo "${FLOW_COLORS[error]}!${FLOW_COLORS[reset]}" ;;
        admin-info)        echo "${FLOW_COLORS[muted]}i${FLOW_COLORS[reset]}" ;;
        scheduling)        echo "${FLOW_COLORS[accent]}S${FLOW_COLORS[reset]}" ;;
        newsletter)        echo "${FLOW_COLORS[muted]}N${FLOW_COLORS[reset]}" ;;
        personal)          echo "${FLOW_COLORS[success]}P${FLOW_COLORS[reset]}" ;;
        automated)         echo "${FLOW_COLORS[muted]}A${FLOW_COLORS[reset]}" ;;
        urgent)            echo "${FLOW_COLORS[error]}U${FLOW_COLORS[reset]}" ;;
        *)                 echo " " ;;
    esac
}
```

---

## 8. Content Rendering Pipeline

```zsh
# lib/em-render.zsh

_em_render() {
    # Smart content renderer
    # Detects content type and dispatches to best renderer
    local content="$1"
    local force_renderer="$2"  # optional: override detection

    if [[ -n "$force_renderer" ]]; then
        _em_render_with "$force_renderer" "$content"
        return
    fi

    # Detect content type
    if echo "$content" | grep -q '<html\|<div\|<table\|<p>' 2>/dev/null; then
        # HTML content
        _em_render_with "html" "$content"
    elif echo "$content" | grep -q '^#\|^\*\*\|^-\s' 2>/dev/null; then
        # Markdown-like content
        _em_render_with "markdown" "$content"
    else
        # Plain text
        _em_render_with "plain" "$content"
    fi
}

_em_render_with() {
    local renderer="$1"
    local content="$2"

    case "$renderer" in
        html)
            if command -v w3m &>/dev/null; then
                echo "$content" | w3m -dump -T text/html
            elif command -v lynx &>/dev/null; then
                echo "$content" | lynx -stdin -dump
            else
                echo "$content"  # raw fallback
            fi
            ;;
        markdown)
            if command -v glow &>/dev/null; then
                echo "$content" | glow -
            elif command -v bat &>/dev/null; then
                echo "$content" | bat --language=md --style=plain
            else
                echo "$content"
            fi
            ;;
        plain)
            if command -v bat &>/dev/null; then
                echo "$content" | bat --style=plain --paging=never
            else
                echo "$content"
            fi
            ;;
    esac
}
```

---

## 9. Response Workflow (`em respond`)

### 9.1 Batch Draft Generation

```zsh
# lib/em-respond.zsh

_em_respond() {
    local review_mode=false
    local count=20
    local folder="INBOX"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --review|-r)     review_mode=true; shift ;;
            --count|-n)      shift; count="$1"; shift ;;
            --folder|-f)     shift; folder="$1"; shift ;;
            --clear)         _em_cache_clear_drafts; return ;;
            --help|-h)       _em_respond_help; return ;;
            *)               shift ;;
        esac
    done

    if [[ "$review_mode" == "true" ]]; then
        _em_respond_review
        return
    fi

    # Check AI availability
    if [[ -z "$(_em_ai_available)" ]]; then
        _flow_log_error "No AI backend available (need claude or gemini CLI)"
        return 1
    fi

    _flow_log_info "Analyzing inbox for actionable emails..."

    # Get messages
    local messages=$(_em_hml_list "$folder" "$count")
    [[ -z "$messages" ]] && _flow_log_info "No messages" && return 0

    # Filter actionable messages
    local actionable=()
    local msg_id category
    echo "$messages" | jq -c '.[]' | while IFS= read -r msg; do
        msg_id=$(echo "$msg" | jq -r '.id')

        # Check classification
        category=$(_em_cache_get "classifications" "$msg_id" 2>/dev/null)
        if [[ -z "$category" ]]; then
            local content=$(_em_hml_read "$msg_id" plain 2>/dev/null)
            category=$(_em_ai_query "classify" "$(_em_ai_classify_prompt)" "$content" "" "$msg_id")
        fi

        # Filter: only actionable categories
        case "$category" in
            student-question|admin-important|scheduling|personal|urgent)
                # Check if already drafted
                if ! _em_cache_get "drafts" "$msg_id" &>/dev/null; then
                    echo "$msg_id"  # Add to actionable list
                fi
                ;;
        esac
    done | while IFS= read -r msg_id; do
        # Generate draft for each actionable message
        local content=$(_em_hml_read "$msg_id" plain)
        local context_file=$(_em_project_context_file)
        local template=$(_em_find_template "$msg_id")
        local prompt=$(_em_ai_draft_prompt "$context_file" "$template")

        _flow_log_info "Drafting reply for $msg_id..."
        _em_ai_query "draft" "$prompt" "$content" "" "$msg_id"
    done

    local draft_count=$(ls -1 "$(_em_cache_dir)/drafts/" 2>/dev/null | wc -l | tr -d ' ')
    _flow_log_success "$draft_count drafts ready for review"
    _flow_log_info "Review with: ${FLOW_COLORS[cmd]}em respond --review${FLOW_COLORS[reset]}"
}

_em_respond_review() {
    # Interactive draft review with fzf
    local cache_dir="$(_em_cache_dir)/drafts"
    [[ ! -d "$cache_dir" ]] && _flow_log_info "No drafts to review" && return 0

    local draft_files=("$cache_dir"/*.txt(N))
    [[ ${#draft_files[@]} -eq 0 ]] && _flow_log_info "No drafts to review" && return 0

    local approved=()
    local skipped=0

    for draft_file in "${draft_files[@]}"; do
        local hash="${${draft_file:t}%.txt}"
        local draft_content=$(cat "$draft_file")

        echo ""
        echo "${FLOW_COLORS[header]}Draft Reply${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[muted]}$(printf '%.0s-' {1..60})${FLOW_COLORS[reset]}"
        echo "$draft_content"
        echo "${FLOW_COLORS[muted]}$(printf '%.0s-' {1..60})${FLOW_COLORS[reset]}"
        echo ""
        echo "[${FLOW_COLORS[success]}a${FLOW_COLORS[reset]}]pprove  " \
             "[${FLOW_COLORS[accent]}e${FLOW_COLORS[reset]}]dit  " \
             "[${FLOW_COLORS[muted]}s${FLOW_COLORS[reset]}]kip  " \
             "[${FLOW_COLORS[info]}r${FLOW_COLORS[reset]}]egenerate  " \
             "[${FLOW_COLORS[error]}q${FLOW_COLORS[reset]}]uit"

        read -k1 "choice?"
        echo ""

        case "$choice" in
            a) approved+=("$draft_file") ;;
            e)
                local tmp_file=$(mktemp /tmp/em-draft-XXXXX)
                echo "$draft_content" > "$tmp_file"
                "${EDITOR:-vim}" "$tmp_file"
                cp "$tmp_file" "$draft_file"
                rm -f "$tmp_file"
                approved+=("$draft_file")
                ;;
            s) ((skipped++)) ;;
            r)
                # Re-run AI draft generation
                _flow_log_info "Regenerating draft..."
                # Would need to map hash back to msg_id -- needs metadata
                ;;
            q) break ;;
        esac
    done

    # Send approved drafts
    if [[ ${#approved[@]} -gt 0 ]]; then
        echo ""
        _flow_log_info "Ready to send ${#approved[@]} replies"
        if _flow_confirm "Send all approved drafts?"; then
            for draft_file in "${approved[@]}"; do
                # Send via himalaya
                # Note: would need to reconstruct the reply (To, Subject, etc.)
                _flow_log_success "Sent reply ($(basename "$draft_file"))"
                rm -f "$draft_file"
            done
        fi
    fi

    echo ""
    _flow_log_info "Reviewed: ${#approved[@]} approved, $skipped skipped"
}
```

---

## 10. Calendar Integration

```zsh
# lib/em-calendar.zsh

_em_cal_detect() {
    # Detect available calendar application
    # Priority: Calendar.app > Fantastical > gcalcli > .ics fallback
    if [[ -d "/Applications/Fantastical.app" ]]; then
        echo "fantastical"
    elif [[ -d "/System/Applications/Calendar.app" ]] || \
         [[ -d "/Applications/Calendar.app" ]]; then
        echo "calendar.app"
    elif command -v gcalcli &>/dev/null; then
        echo "gcalcli"
    else
        echo "ics"  # universal fallback
    fi
}

_em_cal_add() {
    local events_json="$1"
    local calendar_app=$(_em_cal_detect)

    echo "$events_json" | jq -c '.events[]' | while IFS= read -r event; do
        local title=$(echo "$event" | jq -r '.title')
        local date_str=$(echo "$event" | jq -r '.date')
        local time_str=$(echo "$event" | jq -r '.time // empty')
        local duration=$(echo "$event" | jq -r '.duration_minutes // 60')
        local location=$(echo "$event" | jq -r '.location // empty')

        case "$calendar_app" in
            calendar.app)
                _em_cal_add_applescript "$title" "$date_str" "$time_str" \
                    "$duration" "$location"
                ;;
            fantastical)
                _em_cal_add_fantastical "$title" "$date_str" "$time_str" \
                    "$duration" "$location"
                ;;
            gcalcli)
                _em_cal_add_gcalcli "$title" "$date_str" "$time_str" \
                    "$duration" "$location"
                ;;
            ics)
                _em_cal_generate_ics "$title" "$date_str" "$time_str" \
                    "$duration" "$location"
                ;;
        esac
    done
}

_em_cal_add_applescript() {
    local title="$1" date_str="$2" time_str="$3"
    local duration="$4" location="$5"

    local start_date="$date_str"
    [[ -n "$time_str" ]] && start_date="$date_str $time_str"

    osascript <<EOF
tell application "Calendar"
    tell calendar "Home"
        set newEvent to make new event with properties \\
            {summary:"$title", start date:date "$start_date", \\
             duration:$duration * 60}
        $([ -n "$location" ] && echo "set location of newEvent to \"$location\"")
    end tell
end tell
EOF
    _flow_log_success "Added to Calendar.app: $title"
}

_em_cal_add_fantastical() {
    local title="$1" date_str="$2" time_str="$3"
    local duration="$4" location="$5"

    local natural_lang="$title on $date_str"
    [[ -n "$time_str" ]] && natural_lang+=" at $time_str"
    [[ -n "$duration" ]] && natural_lang+=" for ${duration}m"
    [[ -n "$location" ]] && natural_lang+=" at $location"

    osascript -e "tell application \"Fantastical\" to parse sentence \"$natural_lang\""
    _flow_log_success "Added to Fantastical: $title"
}

_em_cal_generate_ics() {
    local title="$1" date_str="$2" time_str="$3"
    local duration="$4" location="$5"

    local ics_file="/tmp/em-event-$(date +%s).ics"
    local dtstart=$(echo "$date_str" | tr -d '-')
    [[ -n "$time_str" ]] && dtstart+="T$(echo "$time_str" | tr -d ':')00"

    cat > "$ics_file" <<ICS
BEGIN:VCALENDAR
VERSION:2.0
BEGIN:VEVENT
DTSTART:${dtstart}
DURATION:PT${duration}M
SUMMARY:${title}
$([ -n "$location" ] && echo "LOCATION:${location}")
END:VEVENT
END:VCALENDAR
ICS

    _flow_log_success "Generated: $ics_file"
    _flow_log_info "Open with: open $ics_file"
}
```

---

## 11. Notification System

```zsh
# lib/em-notify.zsh

_em_notify() {
    # Dispatch notification based on urgency level
    # Args: level (normal|urgent|critical), title, message
    local level="$1" title="$2" message="$3"

    case "$level" in
        normal)
            # Terminal badge only (iTerm2)
            printf '\e]1337;SetBadgeFormat=%s\a' \
                $(echo -n "$title" | base64)
            ;;
        urgent)
            # macOS notification
            if command -v terminal-notifier &>/dev/null; then
                terminal-notifier \
                    -title "em: $title" \
                    -message "$message" \
                    -group "flow-email" \
                    -sound "default"
            elif command -v osascript &>/dev/null; then
                osascript -e "display notification \"$message\" with title \"em: $title\""
            fi
            ;;
        critical)
            # Notification + sound + calendar prompt
            if command -v terminal-notifier &>/dev/null; then
                terminal-notifier \
                    -title "URGENT: $title" \
                    -message "$message" \
                    -group "flow-email" \
                    -sound "Basso" \
                    -execute "em read latest"
            fi
            # Also play system sound
            afplay /System/Library/Sounds/Basso.aiff &
            ;;
    esac
}

_em_urgency_level() {
    # Determine urgency from classification + content signals
    local category="$1" subject="$2" from="$3"

    # Critical: explicit urgent flag
    [[ "$category" == "urgent" ]] && echo "critical" && return

    # Urgent: admin-important from known senders
    if [[ "$category" == "admin-important" ]]; then
        echo "urgent"
        return
    fi

    # Normal: everything else
    echo "normal"
}
```

---

## 12. Per-Project Integration

### 12.1 Project Email Configuration

```yaml
# <project-root>/.flow/email-config.yml

# Filter inbox when this project is active (via `work` command)
filters:
  include_senders:
    - "*@university.edu"
    - "*@department.edu"
  include_subjects:
    - "STAT 301"
    - "STAT-301"
    - "assignment"
    - "office hours"
  exclude_senders:
    - "noreply@*"

# Context files injected into AI prompts when drafting replies
context_files:
  - syllabus.md
  - office-hours.md
  - course-info.yml

# AI behavior overrides
ai:
  draft_tone: "friendly-professional"
  sign_off: "Best,\nDT"
  include_office_hours: true
```

### 12.2 Email Templates

```yaml
# .flow/email-templates/student-question.yml
name: Student Question Reply
trigger:
  category: student-question
structure: |
  Hi {{student_name}},

  {{ai_answer}}

  {{#if needs_meeting}}
  If you'd like to discuss further, my office hours are {{office_hours}}.
  {{/if}}

  Best,
  {{instructor_name}}
variables:
  office_hours: "from .flow/office-hours.md"
  instructor_name: "from .flow/course-info.yml"
```

### 12.3 Context Injection

```zsh
_em_project_context_file() {
    # Build a merged context file from project .flow/ config
    local project_root=$(_flow_find_project_root 2>/dev/null)
    [[ -z "$project_root" ]] && return

    local config_file="$project_root/.flow/email-config.yml"
    [[ ! -f "$config_file" ]] && return

    # Merge context files into a single string
    local context=""
    if command -v yq &>/dev/null; then
        local files=($(yq -r '.context_files[]' "$config_file" 2>/dev/null))
        for ctx_file in "${files[@]}"; do
            local full_path="$project_root/$ctx_file"
            if [[ -f "$full_path" ]]; then
                context+="--- $ctx_file ---"$'\n'
                context+="$(cat "$full_path")"$'\n\n'
            fi
        done
    fi

    if [[ -n "$context" ]]; then
        local tmp=$(mktemp /tmp/em-context-XXXXX)
        echo "$context" > "$tmp"
        echo "$tmp"
    fi
}
```

---

## 13. Doctor / Health Check

```zsh
# commands/em-doctor.zsh

_em_doctor() {
    echo ""
    echo "${FLOW_COLORS[header]}em doctor${FLOW_COLORS[reset]} -- Email Dispatcher Health Check"
    echo "${FLOW_COLORS[muted]}$(printf '%.0s-' {1..50})${FLOW_COLORS[reset]}"

    local issues=0

    # Required
    _em_doc_check "himalaya" "brew install himalaya" true  || ((issues++))
    _em_doc_check "jq"       "brew install jq"       true  || ((issues++))

    # AI backends (at least one required for AI features)
    local has_ai=false
    command -v claude &>/dev/null && has_ai=true
    command -v gemini &>/dev/null && has_ai=true

    if [[ "$has_ai" == "true" ]]; then
        _flow_log_success "AI backend available"
        command -v claude &>/dev/null && echo "  claude: $(claude --version 2>/dev/null)"
        command -v gemini &>/dev/null && echo "  gemini: $(which gemini)"
    else
        _flow_log_warning "No AI backend (install claude or gemini CLI for AI features)"
        echo "  ${FLOW_COLORS[muted]}Email works without AI -- summaries/drafts disabled${FLOW_COLORS[reset]}"
    fi

    # Renderers (optional)
    echo ""
    echo "${FLOW_COLORS[bold]}Renderers:${FLOW_COLORS[reset]}"
    _em_doc_check "w3m"  "brew install w3m"  false
    _em_doc_check "bat"  "brew install bat"  false
    _em_doc_check "glow" "brew install glow" false

    # Interactive tools (optional)
    echo ""
    echo "${FLOW_COLORS[bold]}Interactive:${FLOW_COLORS[reset]}"
    _em_doc_check "fzf" "brew install fzf" false

    # Calendar (optional)
    echo ""
    echo "${FLOW_COLORS[bold]}Calendar:${FLOW_COLORS[reset]}"
    local cal=$(_em_cal_detect)
    _flow_log_success "Calendar: $cal"

    # Notifications (optional)
    echo ""
    echo "${FLOW_COLORS[bold]}Notifications:${FLOW_COLORS[reset]}"
    _em_doc_check "terminal-notifier" "brew install terminal-notifier" false

    # himalaya connectivity
    echo ""
    echo "${FLOW_COLORS[bold]}Connection:${FLOW_COLORS[reset]}"
    if command -v himalaya &>/dev/null; then
        if himalaya account list &>/dev/null; then
            _flow_log_success "himalaya connected"
        else
            _flow_log_error "himalaya configured but cannot connect"
            ((issues++))
        fi
    fi

    # Summary
    echo ""
    if [[ $issues -eq 0 ]]; then
        _flow_log_success "All checks passed"
    else
        _flow_log_warning "$issues issue(s) found"
    fi
    echo ""
}

_em_doc_check() {
    local tool="$1" install_cmd="$2" required="$3"

    if command -v "$tool" &>/dev/null; then
        _flow_log_success "$tool"
        return 0
    elif [[ "$required" == "true" ]]; then
        _flow_log_error "$tool (required: $install_cmd)"
        return 1
    else
        _flow_log_muted "  $tool (optional: $install_cmd)"
        return 0
    fi
}
```

---

## 14. Security Considerations

### 14.1 Email Content Through AI

**Risk:** Email content is piped to AI CLI tools. The content leaves the local machine and goes to Anthropic/Google servers.

**Mitigations:**

1. **Opt-in AI** -- AI features are never mandatory. `em inbox --no-ai` works without any AI calls.

2. **Per-project AI policy** -- `.flow/email-config.yml` can disable AI for sensitive projects:
   ```yaml
   ai:
     enabled: false  # No AI for this project's emails
   ```

3. **Content filtering** -- Strip signatures, disclaimers, and forwarded chains before sending to AI. Reduce to the minimum content needed for classification/summary.

4. **No credential exposure** -- Never pipe email headers containing auth tokens to AI. Extract only From, Subject, Date, and body text.

5. **Local cache** -- AI results are cached locally in `.flow/email-cache/` (gitignored). No cache syncing to cloud.

6. **Audit trail** -- All AI calls logged to `~/.local/share/flow/ai-usage.jsonl` with operation type, timestamp, and backend used. User can review what was sent.

### 14.2 Attachment Safety

- `em attach` downloads to current directory or specified path
- Never auto-open downloaded attachments
- Show file type and size before download
- Warn on executable or script attachments

### 14.3 Send Confirmation

- `em send` and `em reply` always require explicit confirmation
- `em respond` drafts are never sent without review
- The dispatch chain: AI draft -> user review -> explicit confirm -> himalaya send

---

## 15. Graceful Degradation

The system is designed as a stack of optional enhancements:

| Condition | Behavior |
|-----------|----------|
| No himalaya | `em doctor` reports error, all commands fail gracefully |
| No AI backends | Email works normally. No summaries, classifications, or drafts. Inbox shows raw subject lines only |
| No fzf | `em pick` fails with install suggestion. Other commands work |
| No w3m | HTML emails rendered raw or via bat fallback |
| No jq | Most AI parsing fails gracefully. himalaya text output used instead of JSON |
| Offline | Cached results shown. New AI calls fail silently. Email operations depend on himalaya's own offline handling |
| AI timeout | Falls back through fallback chain, then shows email without enrichment |

---

## 16. Phase Plan

### Phase 1: Foundation (MVP)
**Goal:** Working email dispatcher that wraps himalaya. No AI yet.

Files to create:
- `lib/dispatchers/em-dispatcher.zsh` -- Main dispatcher with help
- `lib/em-himalaya.zsh` -- himalaya adapter layer
- `lib/em-render.zsh` -- Content rendering pipeline
- `commands/em-doctor.zsh` -- Health check
- `completions/_em` -- ZSH completions

Commands working:
- `em` (quick status), `em inbox`, `em read`, `em send`, `em reply`
- `em find`, `em folders`, `em html`, `em attach`
- `em pick` (fzf picker), `em unread`, `em doctor`

Estimated effort: 8-12 hours

### Phase 2: AI Layer + Caching
**Goal:** AI abstraction with classification and summaries in inbox view.

Files to create:
- `lib/em-ai.zsh` -- AI abstraction (claude + gemini backends)
- `lib/em-cache.zsh` -- Cache manager with TTL

Commands enhanced:
- `em inbox` -- Shows category icons + AI summaries
- `em classify <ID>` -- Manual classification
- `em summarize <ID>` -- Manual summary
- `em cache stats|clear` -- Cache management

Estimated effort: 6-8 hours

### Phase 3: Response Workflow
**Goal:** AI-powered draft responses with review workflow.

Files to create:
- `lib/em-respond.zsh` -- Draft generation + review
- `lib/em-templates.zsh` -- Template loading

Commands working:
- `em respond` -- Batch draft generation
- `em respond --review` -- Interactive review with approve/edit/skip

Estimated effort: 6-8 hours

### Phase 4: Calendar + Notifications
**Goal:** Schedule extraction and notification system.

Files to create:
- `lib/em-calendar.zsh` -- Calendar integration
- `lib/em-notify.zsh` -- Notification system

Commands working:
- `em cal` -- Manual calendar extraction
- `em watch` -- IMAP IDLE monitoring
- `em dash` -- Full dashboard with AI summaries

Estimated effort: 4-6 hours

### Phase 5: Project Integration
**Goal:** Per-project email filtering and context injection.

Files to create:
- Template `.flow/email-config.yml`
- Template `.flow/email-templates/`

Features:
- `work my-course` + `em inbox` filters by project
- AI drafts use project context (syllabus, office hours)
- Project-specific templates

Estimated effort: 4-6 hours

---

## 17. Help Text

```zsh
_em_help() {
    echo -e "
${_C_BOLD}+---------------------------------------------+${_C_NC}
${_C_BOLD}| em - Email Dispatcher                       |${_C_NC}
${_C_BOLD}+---------------------------------------------+${_C_NC}

${_C_BOLD}Usage:${_C_NC} em [subcommand] [args]

${_C_GREEN}MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}em${_C_NC}                 Unread count
  ${_C_CYAN}em inbox${_C_NC}           List inbox with AI summaries
  ${_C_CYAN}em read <ID>${_C_NC}       Read message (smart rendering)
  ${_C_CYAN}em reply <ID>${_C_NC}      Reply to message
  ${_C_CYAN}em pick${_C_NC}            fzf interactive picker
  ${_C_CYAN}em respond${_C_NC}         AI drafts for all actionable emails

${_C_BLUE}EMAIL${_C_NC}:
  ${_C_CYAN}em inbox [N]${_C_NC}       List inbox (default 25)
  ${_C_CYAN}em read <ID>${_C_NC}       Read message
  ${_C_CYAN}em send${_C_NC}            Compose new message
  ${_C_CYAN}em reply <ID>${_C_NC}      Reply to message
  ${_C_CYAN}em find <query>${_C_NC}    Search emails
  ${_C_CYAN}em unread${_C_NC}          Unread count (cached)
  ${_C_CYAN}em folders${_C_NC}         List folders
  ${_C_CYAN}em html <ID>${_C_NC}       Render HTML email
  ${_C_CYAN}em attach <ID>${_C_NC}     Download attachments

${_C_BLUE}AI FEATURES${_C_NC}:
  ${_C_CYAN}em respond${_C_NC}         AI drafts for actionable emails
  ${_C_CYAN}em respond --review${_C_NC} Review/approve/edit drafts
  ${_C_CYAN}em classify <ID>${_C_NC}   Classify single email
  ${_C_CYAN}em summarize <ID>${_C_NC}  Summarize single email
  ${_C_CYAN}em dash${_C_NC}            Dashboard: unread + summaries
  ${_C_CYAN}em cal <ID>${_C_NC}        Extract dates to calendar

${_C_BLUE}SYSTEM${_C_NC}:
  ${_C_CYAN}em watch${_C_NC}           IMAP IDLE monitoring
  ${_C_CYAN}em cache stats${_C_NC}     Show AI cache stats
  ${_C_CYAN}em cache clear${_C_NC}     Clear AI cache
  ${_C_CYAN}em doctor${_C_NC}          Check dependencies

${_C_MAGENTA}TIP${_C_NC}: Unknown commands pass through to himalaya
  ${_C_DIM}em account list  ->  himalaya account list${_C_NC}

${_C_DIM}See also:${_C_NC}
  ${_C_CYAN}em inbox --no-ai${_C_NC} -- Skip AI enrichment (fast mode)
  ${_C_CYAN}em respond --review${_C_NC} -- Never sends without your approval
"
}
```

---

## 18. Completion

```zsh
# completions/_em

#compdef em

_em() {
    local -a subcommands
    subcommands=(
        'inbox:List inbox messages'
        'read:Read a message'
        'send:Compose new message'
        'reply:Reply to message'
        'find:Search emails'
        'pick:Interactive fzf picker'
        'unread:Unread count'
        'dash:Dashboard with AI summaries'
        'folders:List folders'
        'html:Render HTML email'
        'attach:Download attachments'
        'respond:AI draft responses'
        'classify:Classify email'
        'summarize:Summarize email'
        'cal:Calendar extraction'
        'watch:IMAP IDLE monitoring'
        'cache:Manage AI cache'
        'config:Email configuration'
        'doctor:Health check'
        'help:Show help'
    )

    _describe 'subcommand' subcommands
}

_em "$@"
```

---

## 19. Open Questions / Trade-offs

| Decision | Options | Recommendation |
|----------|---------|----------------|
| himalaya JSON vs text output | JSON (structured, parseable) vs text (human-readable fallback) | **JSON** with text fallback when jq is missing |
| AI batch vs per-message | Batch all messages in one AI call vs individual calls | **Individual** -- better caching, easier retry, cache hits skip the call entirely |
| Draft storage format | Plain text vs EML vs JSON with metadata | **Plain text** for drafts (simple), **JSON sidecar** for metadata (msg_id, from, subject) |
| Background AI warm vs on-demand | Warm cache in background on inbox vs only when user reads | **Background warm** for inbox view (non-blocking `&`), on-demand for everything else |
| MCP backend priority | Whether MCP should be a first-class backend | **Phase 2+** -- Start with claude/gemini CLI pipes. Add MCP when MCP server is built |
| Thread depth for AI context | How much thread history to include in draft prompts | **3 messages** max to keep within token limits and reduce cost |
| himalaya version pinning | Pin to specific himalaya version or track latest | **Track latest** but abstract all commands through adapter layer for easy migration |

---

**End of Specification**
