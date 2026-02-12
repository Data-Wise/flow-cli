#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# Email Helpers — Config, safety gate, draft file utilities
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
