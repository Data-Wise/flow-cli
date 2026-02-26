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
# INPUT VALIDATION — MESSAGE ID & FOLDER NAME
# ═══════════════════════════════════════════════════════════════════

_em_validate_msg_id() {
    # Validate message ID is numeric only (Finding 2 — prevents arg injection)
    # Args: message_id
    # Returns: 0 if valid, 1 if invalid
    local msg_id="$1"
    if [[ -z "$msg_id" ]]; then
        _flow_log_error "Message ID is required"
        return 1
    fi
    if [[ ! "$msg_id" =~ ^[0-9]+$ ]]; then
        _flow_log_error "Invalid message ID: must be numeric only"
        return 1
    fi
    return 0
}

_em_validate_folder_name() {
    # Validate folder name to prevent argument injection (Finding 7)
    # Rejects: empty, leading dash, path separators, control chars, >255 chars
    # Args: folder_name
    # Returns: 0 if valid, 1 if invalid
    local name="$1"

    if [[ -z "$name" ]]; then
        _flow_log_error "Folder name cannot be empty"
        return 1
    fi

    if [[ "${#name}" -gt 255 ]]; then
        _flow_log_error "Folder name too long (max 255 chars)"
        return 1
    fi

    # Reject leading dash (would be interpreted as a flag)
    if [[ "$name" == -* ]]; then
        _flow_log_error "Folder name cannot start with a dash"
        return 1
    fi

    # Reject path separators and control characters
    if [[ "$name" == */* || "$name" == *\\* ]]; then
        _flow_log_error "Folder name cannot contain path separators"
        return 1
    fi

    # Reject null bytes (0x00)
    if [[ "$name" == *$'\x00'* ]]; then
        _flow_log_error "Folder name cannot contain control characters"
        return 1
    fi

    # Reject control characters (0x01–0x1F) by checking each byte
    # ZSH regex alternation with literal $'...' requires a variable
    local _ctrl_re=$'[\x01-\x1f]'
    if [[ "$name" =~ $_ctrl_re ]]; then
        _flow_log_error "Folder name cannot contain control characters"
        return 1
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════════
# VERSION DETECTION — PROGRESSIVE ENHANCEMENT
# ═══════════════════════════════════════════════════════════════════

# Session-scoped cache — zero disk I/O after first call
typeset -g _EM_HML_VERSION=""

_em_hml_version() {
    # Parse and cache himalaya version string
    # Returns: version string (e.g. "1.2.0") on stdout, sets $_EM_HML_VERSION
    # Caches in session-scoped global to avoid repeated subprocess forks
    if [[ -n "$_EM_HML_VERSION" ]]; then
        echo "$_EM_HML_VERSION"
        return 0
    fi

    if ! command -v himalaya &>/dev/null; then
        return 1
    fi

    # `himalaya --version` outputs: "himalaya 1.2.0"
    local raw
    raw=$(himalaya --version 2>/dev/null)
    if [[ -z "$raw" ]]; then
        return 1
    fi

    # Extract the version number (last whitespace-delimited token)
    local version
    version="${raw##* }"

    # Sanity check: must look like X.Y.Z (or X.Y or X)
    if [[ ! "$version" =~ ^[0-9]+(\.[0-9]+)*$ ]]; then
        _flow_log_warning "em: could not parse himalaya version from: $raw"
        return 1
    fi

    _EM_HML_VERSION="$version"
    echo "$version"
    return 0
}

_em_hml_version_gte() {
    # Compare current himalaya version >= min_version (semver, numeric)
    # Correctly handles 1.9.0 vs 1.10.0 (numeric comparison per segment)
    # Args: min_version (e.g. "1.2.0")
    # Returns: 0 if installed version >= min_version, 1 otherwise
    local min_version="$1"
    local current
    current=$(_em_hml_version 2>/dev/null)
    [[ -z "$current" ]] && return 1

    # Split on '.' into arrays
    local -a cur_parts=( ${(s:.:)current} )
    local -a min_parts=( ${(s:.:)min_version} )

    # Pad shorter array with zeros
    local max_len=$(( ${#cur_parts} > ${#min_parts} ? ${#cur_parts} : ${#min_parts} ))
    local i
    for (( i=1; i<=max_len; i++ )); do
        local cur_seg="${cur_parts[$i]:-0}"
        local min_seg="${min_parts[$i]:-0}"
        if (( cur_seg > min_seg )); then
            return 0
        elif (( cur_seg < min_seg )); then
            return 1
        fi
    done

    # All segments equal — versions are identical, satisfies >=
    return 0
}

_em_require_version() {
    # Gate a feature behind a minimum version requirement
    # Args: min_version, feature_name (for user-friendly error)
    # Returns: 0 if requirement met, 1 with error message if not
    local min_version="$1" feature="$2"
    if ! _em_hml_version_gte "$min_version"; then
        local current
        current=$(_em_hml_version 2>/dev/null)
        _flow_log_error "em: '$feature' requires himalaya >= $min_version (installed: ${current:-unknown})"
        echo "Upgrade: ${_C_CYAN}brew upgrade himalaya${_C_NC} or ${_C_CYAN}cargo install --force himalaya${_C_NC}"
        return 1
    fi
    return 0
}

_em_hml_version_clear_cache() {
    # Clear the cached version (called by em doctor --fix or after upgrade)
    _EM_HML_VERSION=""
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
    #
    # Security (Finding 2): validate msg_id is numeric before use
    # Security (Finding 5): body passed via temp file, not positional arg
    # Security (Finding 14): tmplog via mktemp + chmod 0600 + trap cleanup
    local msg_id="$1" body="$2" reply_all="${3:-false}"

    # Finding 2: validate message ID
    if ! _em_validate_msg_id "$msg_id"; then
        return 1
    fi

    local -a flags=()
    [[ "$reply_all" == "true" ]] && flags+=(--all)

    # Finding 14: use mktemp for log file, restrict permissions, register cleanup
    local tmplog
    tmplog=$(mktemp "${TMPDIR:-/tmp}/em-reply-XXXXXX.log")
    chmod 0600 "$tmplog"
    # Trap ensures cleanup even if function exits early
    trap "rm -f '$tmplog'" RETURN

    if [[ -n "$body" ]]; then
        # Finding 5: pass body via temp file instead of positional arg
        # Prevents body content from being interpreted as himalaya flags
        local tmpbody
        tmpbody=$(mktemp "${TMPDIR:-/tmp}/em-body-XXXXXX")
        chmod 0600 "$tmpbody"
        printf '%s' "$body" > "$tmpbody"
        # himalaya reads body from stdin when no positional body arg is given
        script -q "$tmplog" sh -c "himalaya message reply ${(j: :)${(@q)flags}} '$msg_id' < '$tmpbody'"
        rm -f "$tmpbody"
    else
        script -q "$tmplog" himalaya message reply "${flags[@]}" "$msg_id"
    fi

    # Detect discard from himalaya's interactive prompt output
    if grep -aq "Discard" "$tmplog" 2>/dev/null; then
        return 2
    fi

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
    # Search messages via IMAP SEARCH (single keyword — himalaya limitation)
    # Args: query, folder (default: INBOX)
    # Returns: JSON array of matching envelopes
    local query="$1" folder="${2:-INBOX}"
    # himalaya only supports single-word subject search;
    # pick the longest word as the most distinctive keyword
    local keyword
    keyword=$(echo "$query" | tr ' ' '\n' | awk '{ print length, $0 }' | sort -rn | head -1 | cut -d' ' -f2-)
    [[ -z "$keyword" ]] && keyword="$query"
    himalaya envelope list -f "$folder" --output json \
        subject "$keyword" 2>/dev/null
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
# HEADERS
# ═══════════════════════════════════════════════════════════════════

_em_hml_headers() {
    # Extract specific headers from a raw message
    # Args: message_id, folder (default: INBOX)
    # Returns: raw headers (up to first blank line of the .eml)
    local msg_id="$1" folder="${2:-INBOX}"
    local tmpdir
    tmpdir=$(mktemp -d "${TMPDIR:-/tmp}/em-hdr-XXXXXX")
    if himalaya message export --full -f "$folder" -d "$tmpdir" "$msg_id" &>/dev/null; then
        local eml_file
        eml_file=$(find "$tmpdir" -name "*.eml" -type f 2>/dev/null | head -1)
        if [[ -n "$eml_file" ]]; then
            # Output headers only (up to first blank line)
            sed '/^$/q' "$eml_file"
        fi
    fi
    rm -rf "$tmpdir"
}

# ═══════════════════════════════════════════════════════════════════
# MESSAGE MOVE
# ═══════════════════════════════════════════════════════════════════

_em_hml_move() {
    # Move message to a different folder
    # Args: message_id, target_folder, source_folder (default: INBOX)
    local msg_id="$1" target="$2" source="${3:-INBOX}"
    himalaya message move -f "$source" "$msg_id" "$target" 2>/dev/null
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
# DELETE / MOVE / EXPUNGE
# ═══════════════════════════════════════════════════════════════════

_em_hml_delete() {
    # Move message(s) to Trash (himalaya message delete)
    # Args: folder, IDs...
    # Note: himalaya "delete" = move to Trash, NOT permanent
    local folder="$1"; shift
    [[ $# -eq 0 ]] && return 1
    himalaya message delete -f "$folder" "$@" 2>/dev/null
}

_em_hml_move() {
    # Move message(s) between folders
    # Args: source_folder, target_folder, IDs...
    local src="$1" dst="$2"; shift 2
    [[ $# -eq 0 ]] && return 1
    himalaya message move -f "$src" "$dst" "$@" 2>/dev/null
}

_em_hml_expunge() {
    # Permanently remove messages flagged as Deleted from a folder
    # Args: folder
    local folder="$1"
    himalaya folder expunge "$folder" 2>/dev/null
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

# ═══════════════════════════════════════════════════════════════════
# FOLDER CRUD — with -- terminator to prevent arg injection (Finding 7)
# ═══════════════════════════════════════════════════════════════════

_em_hml_folder_create() {
    # Create a new mail folder
    # Args: folder_name
    # Security: validates name, uses -- terminator before user-supplied name
    local name="$1"
    if ! _em_validate_folder_name "$name"; then
        return 1
    fi
    himalaya folder create -- "$name" 2>/dev/null
}

_em_hml_folder_delete() {
    # Delete a mail folder
    # Args: folder_name
    # Security: validates name, uses -- terminator before user-supplied name
    local name="$1"
    if ! _em_validate_folder_name "$name"; then
        return 1
    fi
    himalaya folder delete -- "$name" 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════════
# ATTACHMENT OPERATIONS — version-aware
# ═══════════════════════════════════════════════════════════════════

_em_hml_attachment_list() {
    # List attachments for a message (version-aware output format)
    # Args: message_id
    # v1.2+: JSON output; v1.0–v1.1: plain text
    local msg_id="$1"
    if ! _em_validate_msg_id "$msg_id"; then
        return 1
    fi

    if _em_hml_version_gte "1.2.0"; then
        himalaya attachment list --output json "$msg_id" 2>/dev/null
    else
        himalaya attachment list "$msg_id" 2>/dev/null
    fi
}

_em_hml_attachment_download() {
    # Download a specific attachment to a directory
    # Args: message_id, filename (for logging), output_dir
    local msg_id="$1" file="$2" out_dir="${3:-.}"
    if ! _em_validate_msg_id "$msg_id"; then
        return 1
    fi
    himalaya attachment download "$msg_id" --dir "$out_dir" 2>/dev/null
}

# ═══════════════════════════════════════════════════════════════════
# ENVELOPE WATCH (non-blocking wrapper for IMAP IDLE)
# ═══════════════════════════════════════════════════════════════════

_em_hml_watch() {
    # Watch a folder for new messages via IMAP IDLE (blocking)
    # Args: folder (default: INBOX)
    # Named _em_hml_watch to distinguish from the older _em_hml_idle
    local folder="${1:-INBOX}"
    himalaya envelope watch --folder "$folder" 2>/dev/null
}
