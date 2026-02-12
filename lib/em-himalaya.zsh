#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# himalaya Adapter Layer — Isolates all himalaya CLI specifics
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         lib/em-himalaya.zsh
# Version:      0.1
# Date:         2026-02-10
#
# Used by:      lib/dispatchers/email-dispatcher.zsh
# Backend:      himalaya CLI v1.0+ (semver guaranteed)
#
# Design:       All himalaya-specific command syntax lives HERE.
#               The dispatcher and helpers call _em_hml_* functions only.
#               If himalaya changes CLI args, fix only this file.
#
# ══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════
# CONNECTION CHECK
# ═══════════════════════════════════════════════════════════════════

_em_hml_check() {
    # Verify himalaya is installed and can connect
    # Returns: 0 on success, 1 on failure
    if ! command -v himalaya &>/dev/null; then
        _flow_log_error "himalaya not installed"
        echo "Install: ${_C_CYAN}brew install himalaya${_C_NC} or ${_C_CYAN}cargo install himalaya${_C_NC}"
        return 1
    fi

    # Quick connectivity test (list 1 message)
    if ! himalaya envelope list --page-size 1 &>/dev/null; then
        _flow_log_error "himalaya cannot connect to mailbox"
        echo "Check config: ${_C_CYAN}himalaya account list${_C_NC}"
        return 1
    fi
    return 0
}

# ═══════════════════════════════════════════════════════════════════
# MESSAGE LISTING
# ═══════════════════════════════════════════════════════════════════

_em_hml_list() {
    # List messages in a folder
    # Args: folder (default: INBOX), count (default: 25)
    # Returns: JSON array of envelope objects
    local folder="${1:-INBOX}" count="${2:-25}"
    himalaya envelope list -f "$folder" --page-size "$count" \
        --output json 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════════
# MESSAGE READING
# ═══════════════════════════════════════════════════════════════════

_em_hml_read() {
    # Read a single message
    # Args: message_id, format (plain|html|raw), folder (optional)
    # Returns: message content on stdout
    #
    # himalaya v1.1.0 notes:
    #   - `message read` returns human-friendly plain text (no --html/--raw flags)
    #   - `message export` extracts MIME parts (index.html for HTML)
    #   - `message export --full` exports raw .eml
    local msg_id="$1" fmt="${2:-plain}" folder="${3:-INBOX}"
    case "$fmt" in
        html)
            # Export MIME parts → read the HTML file
            local tmpdir
            tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/em-html-XXXXXX")
            if himalaya message export -f "$folder" -d "$tmpdir" "$msg_id" &>/dev/null; then
                if [[ -f "$tmpdir/index.html" ]]; then
                    cat "$tmpdir/index.html"
                fi
            fi
            rm -rf "$tmpdir"
            ;;
        raw)
            # Export full raw .eml
            local tmpdir
            tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/em-raw-XXXXXX")
            if himalaya message export --full -f "$folder" -d "$tmpdir" "$msg_id" &>/dev/null; then
                local eml_file
                eml_file=$(find "$tmpdir" -name "*.eml" -type f 2>/dev/null | head -1)
                if [[ -n "$eml_file" ]]; then
                    cat "$eml_file"
                fi
            fi
            rm -rf "$tmpdir"
            ;;
        *)
            himalaya message read -f "$folder" "$msg_id" 2>/dev/null
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# COMPOSE & REPLY — INTERACTIVE (opens $EDITOR)
# ═══════════════════════════════════════════════════════════════════

_em_hml_send() {
    # Compose new message interactively (opens $EDITOR)
    # Args: body_lines... (optional, pre-fills body via [BODY] positional arg)
    # If body provided, $EDITOR opens with body pre-populated
    # If no args, $EDITOR opens with blank body
    if [[ $# -gt 0 ]]; then
        himalaya message write "$@"
    else
        himalaya message write
    fi
}

_em_hml_reply() {
    # Reply to message interactively (opens $EDITOR)
    # Args: message_id, body (optional AI draft), reply_all (bool)
    # Returns: 0 = sent, 1 = error, 2 = user discarded
    #
    # himalaya exits 0 for both "Send" and "Discard" — we use script(1)
    # to capture terminal output and detect which action the user chose.
    local msg_id="$1" body="$2" reply_all="${3:-false}"
    local -a flags=()
    [[ "$reply_all" == "true" ]] && flags+=(--all)

    local tmplog="${TMPDIR:-/tmp}/em-reply-$$.log"

    if [[ -n "$body" ]]; then
        script -q "$tmplog" himalaya message reply "${flags[@]}" "$msg_id" "$body"
    else
        script -q "$tmplog" himalaya message reply "${flags[@]}" "$msg_id"
    fi

    # Detect discard from himalaya's interactive prompt output
    if grep -aq "Discard" "$tmplog" 2>/dev/null; then
        rm -f "$tmplog"
        return 2
    fi

    rm -f "$tmplog"
    return 0
}

# ═══════════════════════════════════════════════════════════════════
# TEMPLATE SUBSYSTEM — NON-INTERACTIVE (for scripting/batch)
# ═══════════════════════════════════════════════════════════════════

_em_hml_template_reply() {
    # Get reply template as MML (no $EDITOR, for scripting/batch)
    # Args: message_id, reply_all (bool)
    # Returns: MML template on stdout (headers + empty body)
    local msg_id="$1" reply_all="${2:-false}"
    if [[ "$reply_all" == "true" ]]; then
        himalaya template reply --all "$msg_id" 2>/dev/null
    else
        himalaya template reply "$msg_id" 2>/dev/null
    fi
}

_em_hml_template_write() {
    # Get compose template as MML (no $EDITOR, for scripting)
    # Returns: MML template on stdout
    himalaya template write 2>/dev/null
}

_em_hml_template_send() {
    # Send MML template from stdin (no $EDITOR)
    # Used for batch/non-interactive send after AI draft + user confirm
    himalaya template send 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════════
# SEARCH
# ═══════════════════════════════════════════════════════════════════

_em_hml_search() {
    # Search messages via IMAP SEARCH
    # Args: query, folder (default: INBOX)
    # Returns: JSON array of matching envelopes
    local query="$1" folder="${2:-INBOX}"
    himalaya envelope list -f "$folder" --query "$query" \
        --output json 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════════
# FOLDER MANAGEMENT
# ═══════════════════════════════════════════════════════════════════

_em_hml_folders() {
    # List available mail folders
    # Returns: folder list (text or JSON depending on himalaya version)
    himalaya folder list 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════════
# QUICK COUNTS
# ═══════════════════════════════════════════════════════════════════

_em_hml_unread_count() {
    # Get unread count for a folder
    # Args: folder (default: INBOX)
    # Returns: integer count on stdout
    local folder="${1:-INBOX}"
    himalaya envelope list -f "$folder" --output json 2>/dev/null \
        | jq '[.[] | select(.flags | contains(["Seen"]) | not)] | length' 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════════
# ATTACHMENTS
# ═══════════════════════════════════════════════════════════════════

_em_hml_attachments() {
    # Download attachments from a message
    # Args: message_id, output_dir (default: .)
    local msg_id="$1" out_dir="${2:-.}"
    himalaya attachment download "$msg_id" --dir "$out_dir" 2>&1
}

# ═══════════════════════════════════════════════════════════════════
# FLAGS
# ═══════════════════════════════════════════════════════════════════

_em_hml_flags() {
    # Get/set message flags
    # Args: action (add|remove|list), message_id, flag
    local action="$1" msg_id="$2" flag="$3"
    case "$action" in
        add)    himalaya flag add "$msg_id" "$flag" 2>/dev/null ;;
        remove) himalaya flag remove "$msg_id" "$flag" 2>/dev/null ;;
        *)      himalaya flag list "$msg_id" 2>/dev/null ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# IMAP IDLE (WATCH)
# ═══════════════════════════════════════════════════════════════════

_em_hml_idle() {
    # Start IMAP IDLE watch (blocking)
    # Args: folder (default: INBOX)
    local folder="${1:-INBOX}"
    himalaya message watch --folder "$folder" 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════════
# MML INJECTION HELPER
# ═══════════════════════════════════════════════════════════════════

_em_mml_inject_body() {
    # Inject body text into an MML template
    # MML format: headers then blank line then body
    # Args: mml_template, body_text
    local mml="$1" body="$2"

    # Find the blank line separating headers from body, inject after it
    echo "$mml" | awk -v body="$body" '
        /^$/ && !found { found=1; print; print body; next }
        { print }
    '
}
