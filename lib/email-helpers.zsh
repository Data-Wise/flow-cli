#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# Email Helpers — Rendering, fzf, AI, safety gate
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         lib/email-helpers.zsh
# Version:      0.5 (Phase 4+5 — AI pipeline + config + doctor)
# Date:         2026-02-10
#
# Used by:      lib/dispatchers/email-dispatcher.zsh
# Backend:      himalaya CLI
#
# ══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════
# CONFIGURATION LOADER
# ═══════════════════════════════════════════════════════════════════
#
# Loads .flow/email.conf (shell key=value format) from project root.
# Falls back to env vars which are already set by email-dispatcher.zsh.
#
# Example .flow/email.conf:
#   FLOW_EMAIL_AI=claude         # claude | gemini | none
#   FLOW_EMAIL_PAGE_SIZE=25      # Inbox page size
#   FLOW_EMAIL_FOLDER=INBOX      # Default folder
#   FLOW_EMAIL_AI_TIMEOUT=30     # AI draft timeout in seconds

_em_load_config() {
    local config_file="${FLOW_CONFIG_DIR}/email.conf"
    local project_config=""

    # Project-level config takes priority
    if typeset -f _flow_find_project_root &>/dev/null; then
        local proj_root
        proj_root=$(_flow_find_project_root 2>/dev/null)
        if [[ -n "$proj_root" && -f "${proj_root}/.flow/email.conf" ]]; then
            project_config="${proj_root}/.flow/email.conf"
        fi
    fi

    # Source global config first, then project override
    if [[ -f "$config_file" ]]; then
        source "$config_file"
    fi
    if [[ -n "$project_config" ]]; then
        source "$project_config"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# SMART RENDERING PIPELINE
# ═══════════════════════════════════════════════════════════════════
#
# Content type detection:
#   text/html + w3m available     → w3m -dump | bat
#   text/plain + markdown markers → glow
#   text/plain                    → bat --style=plain
#   fallback                      → cat

_em_smart_render() {
    # Content-type detection pipeline
    # Reads stdin into temp file, detects type, routes to best renderer
    local tmpfile
    tmpfile=$(mktemp "${TMPDIR:-/tmp}/em-render-XXXXXX")
    cat > "$tmpfile"

    local content
    content=$(< "$tmpfile")

    if [[ -z "$content" ]]; then
        rm -f "$tmpfile"
        return 0
    fi

    # Detect HTML content
    if echo "$content" | grep -qi '<html\|<body\|<div\|<table\|<p>'; then
        if command -v w3m &>/dev/null; then
            w3m -dump -T text/html < "$tmpfile" | _em_pager
        elif command -v bat &>/dev/null; then
            bat --style=plain --color=always --language=html < "$tmpfile"
        else
            cat "$tmpfile"
        fi
    # Detect markdown indicators
    elif echo "$content" | grep -q '^\#\|^\*\*\|^```\|^\- \['; then
        if command -v glow &>/dev/null; then
            glow "$tmpfile"
        elif command -v bat &>/dev/null; then
            bat --style=plain --color=always --language=markdown < "$tmpfile"
        else
            cat "$tmpfile"
        fi
    # Plain text
    else
        _em_pager < "$tmpfile"
    fi

    rm -f "$tmpfile"
}

_em_pager() {
    # Smart pager: bat if available, otherwise less/cat
    if command -v bat &>/dev/null; then
        bat --style=plain --color=always --paging=always
    elif [[ -t 1 ]]; then
        less -R
    else
        cat
    fi
}

# ═══════════════════════════════════════════════════════════════════
# INBOX RENDERING
# ═══════════════════════════════════════════════════════════════════

_em_render_inbox() {
    # Legacy: colorize himalaya text table output (fallback)
    local line
    local is_header=true
    while IFS= read -r line; do
        if [[ "$is_header" == true ]]; then
            echo -e "${_C_BOLD}${line}${_C_NC}"
            is_header=false
        elif [[ "$line" == *"───"* || "$line" == *"━━━"* || "$line" == *"---"* ]]; then
            echo -e "${_C_DIM}${line}${_C_NC}"
        elif [[ "$line" != *"Seen"* && "$line" != *"seen"* ]]; then
            echo -e "${_C_YELLOW}${_C_BOLD}${line}${_C_NC}"
        else
            echo "$line"
        fi
    done
}

_em_render_inbox_json() {
    # Structured JSON renderer for himalaya envelope list --output json
    # Schema: {id, flags, subject, from: {name, addr}, date, has_attachment}
    if ! command -v jq &>/dev/null; then
        # Fallback: pipe through text renderer
        cat | _em_render_inbox
        return
    fi

    local json
    json=$(cat)

    if [[ -z "$json" || "$json" == "[]" ]]; then
        echo -e "  ${_C_DIM}(no emails)${_C_NC}"
        return
    fi

    # Header
    printf "  ${_C_BOLD}%-5s %-2s %-20s %-40s %s${_C_NC}\n" "ID" "" "From" "Subject" "Date"
    echo -e "  ${_C_DIM}───── ── ──────────────────── ──────────────────────────────────────── ──────────${_C_NC}"

    # Rows
    echo "$json" | jq -r '.[] | [
        (.id | tostring),
        (if (.flags | contains(["Seen"])) then " " else "*" end),
        (if .has_attachment then "+" else " " end),
        (.from.name // .from.addr // "unknown"),
        .subject,
        (.date | split("T")[0] // .date)
    ] | @tsv' | while IFS=$'\t' read -r eid flag attach sender subj edate; do
        # Truncate long fields
        [[ ${#sender} -gt 20 ]] && sender="${sender:0:17}..."
        [[ ${#subj} -gt 40 ]] && subj="${subj:0:37}..."

        local indicator="${flag}${attach}"
        if [[ "$flag" == "*" ]]; then
            # Unread: bold yellow
            printf "  ${_C_YELLOW}${_C_BOLD}%-5s %-2s %-20s %-40s %s${_C_NC}\n" "$eid" "$indicator" "$sender" "$subj" "$edate"
        else
            printf "  %-5s %-2s %-20s %-40s ${_C_DIM}%s${_C_NC}\n" "$eid" "$indicator" "$sender" "$subj" "$edate"
        fi
    done
}

# ═══════════════════════════════════════════════════════════════════
# SAFETY GATE — SEND CONFIRMATION
# ═══════════════════════════════════════════════════════════════════
#
# CRITICAL: Every send MUST pass through this gate.
# Default is NO — only explicit 'y' or 'yes' sends.

_em_confirm_send() {
    local draft_file="$1"

    if [[ ! -f "$draft_file" ]]; then
        _flow_log_error "Draft file not found: $draft_file"
        return 1
    fi

    # Check for empty body
    local body_lines
    body_lines=$(awk '/^$/{found=1;next} found{print}' "$draft_file" | wc -l | tr -d ' ')
    if [[ "$body_lines" -eq 0 ]]; then
        _flow_log_warning "Empty email body"
        printf "  Send anyway? [y/N] "
        local empty_response
        read -r empty_response
        [[ ! "$empty_response" =~ ^[Yy]$ ]] && return 1
    fi

    echo ""
    echo -e "${_C_BLUE}  To:${_C_NC}      $(head -1 "$draft_file" | sed 's/^To: //')"
    echo -e "${_C_BLUE}  Subject:${_C_NC} $(sed -n '2p' "$draft_file" | sed 's/^Subject: //')"
    echo ""
    echo -e "${_C_DIM}--- Body Preview ---${_C_NC}"
    awk '/^$/{found=1;next} found{print}' "$draft_file" | head -10
    echo -e "${_C_DIM}--- End Preview ---${_C_NC}"
    echo ""

    local response
    printf "  Send this email? [y/N] "
    read -r response
    [[ "$response" =~ ^[Yy]$ ]] && return 0

    # Save draft on cancel
    local draft_dir="${FLOW_DATA_DIR}/email-drafts"
    [[ -d "$draft_dir" ]] || mkdir -p "$draft_dir"
    local saved="${draft_dir}/draft-$(date +%Y%m%d-%H%M%S).eml"
    cp "$draft_file" "$saved"
    _flow_log_info "Draft saved: $saved"
    return 1
}

# ═══════════════════════════════════════════════════════════════════
# AI DRAFT PIPELINE
# ═══════════════════════════════════════════════════════════════════

_em_ai_draft() {
    local original_email="$1"
    local ai_backend="${FLOW_EMAIL_AI:-claude}"
    local ai_timeout="${FLOW_EMAIL_AI_TIMEOUT:-30}"

    case "$ai_backend" in
        claude)
            if ! command -v claude &>/dev/null; then
                _flow_log_warning "claude CLI not found, skipping AI draft"
                return 1
            fi
            echo "$original_email" | timeout "$ai_timeout" claude -p \
                "Draft a professional reply to this email. Be concise. Only output the reply body, no headers."
            local rc=$?
            if [[ $rc -eq 124 ]]; then
                _flow_log_warning "AI draft timed out after ${ai_timeout}s"
                return 1
            fi
            return $rc
            ;;
        gemini)
            if ! command -v gemini &>/dev/null; then
                _flow_log_warning "gemini CLI not found, skipping AI draft"
                return 1
            fi
            echo "$original_email" | timeout "$ai_timeout" gemini \
                "Draft a professional reply to this email. Be concise. Only output the reply body, no headers."
            local rc=$?
            if [[ $rc -eq 124 ]]; then
                _flow_log_warning "AI draft timed out after ${ai_timeout}s"
                return 1
            fi
            return $rc
            ;;
        none|off)
            return 1  # No AI — user writes from scratch
            ;;
        *)
            _flow_log_warning "Unknown AI backend: $ai_backend (use: claude, gemini, none)"
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# TEMP FILE HELPERS
# ═══════════════════════════════════════════════════════════════════

_em_create_draft_file() {
    local to="$1" subject="$2" body="$3"
    local tmpfile
    tmpfile=$(mktemp "${TMPDIR:-/tmp}/em-draft-XXXXXX.eml")

    {
        echo "To: $to"
        echo "Subject: $subject"
        echo ""
        [[ -n "$body" ]] && echo "$body"
    } > "$tmpfile"

    echo "$tmpfile"
}

_em_open_in_editor() {
    local draft_file="$1"
    local editor="${EDITOR:-nvim}"

    # Add mail filetype modeline for nvim
    if [[ "$editor" == *nvim* || "$editor" == *vim* ]]; then
        echo "# vim: ft=mail" >> "$draft_file"
    fi

    "$editor" "$draft_file"
}
