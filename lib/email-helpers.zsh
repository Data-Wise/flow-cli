#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# Email Helpers — Rendering, fzf, AI, safety gate
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         lib/email-helpers.zsh
# Version:      0.1 (Phase 1 — stubs)
# Date:         2026-02-10
#
# Used by:      lib/dispatchers/email-dispatcher.zsh
# Backend:      himalaya CLI
#
# ══════════════════════════════════════════════════════════════════════════════

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
    # Phase 3: full content-type detection pipeline
    # For now: bat if available, cat otherwise
    if command -v bat &>/dev/null; then
        bat --style=plain --color=always --paging=always
    else
        cat
    fi
}

# ═══════════════════════════════════════════════════════════════════
# INBOX RENDERING
# ═══════════════════════════════════════════════════════════════════

_em_render_inbox() {
    # Phase 2: formatted table with colors, flags, truncation
    # For now: passthrough
    cat
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

    case "$ai_backend" in
        claude)
            if ! command -v claude &>/dev/null; then
                _flow_log_warning "claude CLI not found, skipping AI draft"
                return 1
            fi
            echo "$original_email" | claude -p \
                "Draft a professional reply to this email. Be concise. Only output the reply body, no headers."
            ;;
        gemini)
            if ! command -v gemini &>/dev/null; then
                _flow_log_warning "gemini CLI not found, skipping AI draft"
                return 1
            fi
            echo "$original_email" | gemini \
                "Draft a professional reply to this email. Be concise. Only output the reply body, no headers."
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
