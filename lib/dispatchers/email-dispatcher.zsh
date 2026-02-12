#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# EM - Email Dispatcher (himalaya wrapper)
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         lib/dispatchers/email-dispatcher.zsh
# Version:      1.0 (Full spec — adapter layer + AI + cache)
# Date:         2026-02-10
# Pattern:      command + keyword + options
#
# Usage:        em <action> [args]
#
# Examples:
#   em                  # Quick dashboard
#   em inbox            # List recent emails
#   em read <ID>        # Read email
#   em reply <ID>       # AI-draft reply in $EDITOR
#   em send             # Compose new email
#   em pick             # fzf email browser
#   em respond          # Batch AI draft generation
#   em help             # Show all commands
#
# Backend:      himalaya CLI (https://github.com/pimalaya/himalaya)
# Adapter:      lib/em-himalaya.zsh (isolates CLI specifics)
# AI:           lib/em-ai.zsh (claude / gemini / fallback chain)
# Cache:        lib/em-cache.zsh (TTL-based AI result caching)
# Render:       lib/em-render.zsh (HTML/markdown/plain detection)
# Editor:       $EDITOR (nvim recommended)
#
# ══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════
# COLOR DEFINITIONS
# ═══════════════════════════════════════════════════════════════════

if [[ -z "$_C_BOLD" ]]; then
    _C_BOLD='\033[1m'
    _C_DIM='\033[2m'
    _C_NC='\033[0m'
    _C_RED='\033[31m'
    _C_GREEN='\033[32m'
    _C_YELLOW='\033[33m'
    _C_BLUE='\033[34m'
    _C_MAGENTA='\033[35m'
    _C_CYAN='\033[36m'
fi

# ═══════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════

: ${FLOW_EMAIL_AI:=claude}           # AI backend: claude | gemini | none
: ${FLOW_EMAIL_PAGE_SIZE:=25}        # Default inbox page size
: ${FLOW_EMAIL_FOLDER:=INBOX}        # Default folder
: ${FLOW_EMAIL_AI_TIMEOUT:=30}       # AI draft timeout in seconds

# Load config file overrides (project .flow/email.conf > global)
_em_load_config 2>/dev/null

# ═══════════════════════════════════════════════════════════════════
# MAIN EM() DISPATCHER
# ═══════════════════════════════════════════════════════════════════

em() {
    # No arguments → smart dashboard (quick pulse check)
    if [[ $# -eq 0 ]]; then
        _em_dash
        return
    fi

    # Bare number → read that email (em 42 = em read 42)
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        _em_read "$@"
        return
    fi

    # Top-level flags → route to inbox (em -n 5 = em inbox 5)
    if [[ "$1" == "-n" ]]; then
        shift
        _em_inbox "$@"
        return
    fi

    case "$1" in
        # ─────────────────────────────────────────────────────────────
        # CORE EMAIL OPERATIONS
        # ─────────────────────────────────────────────────────────────
        inbox|i)      shift; _em_inbox "$@" ;;
        read|r)       shift; _em_read "$@" ;;
        send|s)       shift; _em_send "$@" ;;
        reply|re)     shift; _em_reply "$@" ;;

        # ─────────────────────────────────────────────────────────────
        # SEARCH & BROWSE
        # ─────────────────────────────────────────────────────────────
        find|f)       shift; _em_find "$@" ;;
        pick|p)       shift; _em_pick "$@" ;;

        # ─────────────────────────────────────────────────────────────
        # AI FEATURES
        # ─────────────────────────────────────────────────────────────
        respond|resp|repond) shift; _em_respond "$@" ;;
        classify|cl)  shift; _em_classify "$@" ;;
        summarize|sum) shift; _em_summarize "$@" ;;

        # ─────────────────────────────────────────────────────────────
        # QUICK INFO
        # ─────────────────────────────────────────────────────────────
        unread|u)     shift; _em_unread "$@" ;;
        dash|d)       shift; _em_dash "$@" ;;
        folders)      shift; _em_folders "$@" ;;

        # ─────────────────────────────────────────────────────────────
        # UTILITIES
        # ─────────────────────────────────────────────────────────────
        html)         shift; _em_html "$@" ;;
        attach|a)     shift; _em_attach "$@" ;;
        cache)        shift; _em_cache_cmd "$@" ;;
        doctor|dr)    shift; _em_doctor "$@" ;;

        # ─────────────────────────────────────────────────────────────
        # HELP
        # ─────────────────────────────────────────────────────────────
        help|h|--help|-h) _em_help ;;

        *)
            _flow_log_error "Unknown command: $1"
            echo "Run ${_C_CYAN}em help${_C_NC} for available commands"
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# HELP SYSTEM
# ═══════════════════════════════════════════════════════════════════

_em_help() {
    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ em - Email Dispatcher (himalaya)             │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_BOLD}Usage:${_C_NC} em [subcommand] [args]

${_C_GREEN}MOST COMMON${_C_NC} ${_C_DIM}(daily workflow)${_C_NC}:
  ${_C_CYAN}em${_C_NC}                 Quick pulse (unread + 10 latest)
  ${_C_CYAN}em read <ID>${_C_NC}      Read email (--html, --raw)
  ${_C_CYAN}em reply <ID>${_C_NC}     AI-draft reply in \$EDITOR
  ${_C_CYAN}em send${_C_NC}           Compose new email
  ${_C_CYAN}em pick${_C_NC}           fzf email browser

${_C_YELLOW}QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} em                      ${_C_DIM}# Quick pulse check${_C_NC}
  ${_C_DIM}\$${_C_NC} em r 42                 ${_C_DIM}# Read email #42${_C_NC}
  ${_C_DIM}\$${_C_NC} em r --html 42          ${_C_DIM}# Read HTML version${_C_NC}
  ${_C_DIM}\$${_C_NC} em re 42                ${_C_DIM}# Reply with AI draft${_C_NC}
  ${_C_DIM}\$${_C_NC} em re 42 --all          ${_C_DIM}# Reply-all${_C_NC}
  ${_C_DIM}\$${_C_NC} em re 42 --batch        ${_C_DIM}# Non-interactive (preview+confirm)${_C_NC}
  ${_C_DIM}\$${_C_NC} em s                    ${_C_DIM}# Compose new email${_C_NC}
  ${_C_DIM}\$${_C_NC} em p                    ${_C_DIM}# Browse with fzf${_C_NC}
  ${_C_DIM}\$${_C_NC} em f \"quarterly report\" ${_C_DIM}# Search emails${_C_NC}
  ${_C_DIM}\$${_C_NC} em resp                 ${_C_DIM}# Batch AI drafts for actionable emails${_C_NC}

${_C_BLUE}INBOX & READING${_C_NC}:
  ${_C_CYAN}em inbox [N]${_C_NC}      List N recent emails (default: ${FLOW_EMAIL_PAGE_SIZE})
  ${_C_CYAN}em read <ID>${_C_NC}      Read email (smart rendering)
  ${_C_CYAN}em read --html <ID>${_C_NC} Read HTML version (w3m/lynx)
  ${_C_CYAN}em read --raw <ID>${_C_NC}  Dump raw MIME source
  ${_C_CYAN}em unread${_C_NC}         Show unread count
  ${_C_CYAN}em html <ID>${_C_NC}      Render HTML email ${_C_DIM}(alias for read --html)${_C_NC}

${_C_BLUE}COMPOSE & REPLY${_C_NC}:
  ${_C_CYAN}em send${_C_NC}           Compose new (opens \$EDITOR)
  ${_C_CYAN}em reply <ID>${_C_NC}     Reply with AI draft (--no-ai, --all, --batch)
  ${_C_CYAN}em attach <ID>${_C_NC}    Download attachments

${_C_BLUE}AI FEATURES${_C_NC}:
  ${_C_CYAN}em respond${_C_NC}        Batch AI drafts for actionable emails
  ${_C_CYAN}em respond --review${_C_NC} Review/send generated drafts
  ${_C_CYAN}em classify <ID>${_C_NC}  Classify email (AI)
  ${_C_CYAN}em summarize <ID>${_C_NC} One-line summary (AI)

${_C_BLUE}SEARCH & BROWSE${_C_NC}:
  ${_C_CYAN}em find <query>${_C_NC}   Search emails
  ${_C_CYAN}em pick [FOLDER]${_C_NC}  fzf browser with preview

${_C_BLUE}INFO & MANAGEMENT${_C_NC}:
  ${_C_CYAN}em dash${_C_NC}           Quick dashboard (unread + recent)
  ${_C_CYAN}em folders${_C_NC}        List mail folders
  ${_C_CYAN}em cache stats${_C_NC}    Show AI cache statistics
  ${_C_CYAN}em cache clear${_C_NC}    Clear AI cache
  ${_C_CYAN}em doctor${_C_NC}         Check dependencies

${_C_MAGENTA}SAFETY${_C_NC}: Every send requires explicit ${_C_YELLOW}[y/N]${_C_NC} confirmation (default: No)

${_C_MAGENTA}AI BACKEND${_C_NC}: \$FLOW_EMAIL_AI=${_C_CYAN}${FLOW_EMAIL_AI}${_C_NC} ${_C_DIM}(claude | gemini | none)${_C_NC}
${_C_MAGENTA}AI TIMEOUT${_C_NC}: \$FLOW_EMAIL_AI_TIMEOUT=${_C_CYAN}${FLOW_EMAIL_AI_TIMEOUT}s${_C_NC}

${_C_DIM}Config: \$FLOW_CONFIG_DIR/email.conf or .flow/email.conf (project)${_C_NC}
${_C_DIM}Backend: himalaya CLI | Editor: \${EDITOR:-nvim}${_C_NC}
${_C_DIM}See also: em doctor (check deps), flow doctor (full health)${_C_NC}
"
}

# ═══════════════════════════════════════════════════════════════════
# HIMALAYA DEPENDENCY CHECK (quick gate)
# ═══════════════════════════════════════════════════════════════════

_em_require_himalaya() {
    if command -v himalaya &>/dev/null; then
        return 0
    fi

    # Check common install locations not in PATH
    local loc
    for loc in "$HOME/.cargo/bin/himalaya" /opt/homebrew/bin/himalaya /usr/local/bin/himalaya; do
        if [[ -x "$loc" ]]; then
            # Add to PATH for this session so subsequent calls find it
            export PATH="${loc:h}:$PATH"
            return 0
        fi
    done

    _flow_log_error "himalaya not found"
    echo "Install: ${_C_CYAN}brew install himalaya${_C_NC} or ${_C_CYAN}cargo install himalaya${_C_NC}"
    echo "Setup:   ${_C_CYAN}em doctor${_C_NC} for full dependency check"
    return 1
}

# ═══════════════════════════════════════════════════════════════════
# CORE SUBCOMMANDS
# ═══════════════════════════════════════════════════════════════════

_em_inbox() {
    _em_require_himalaya || return 1
    local page_size="${1:-$FLOW_EMAIL_PAGE_SIZE}"
    local folder="${2:-$FLOW_EMAIL_FOLDER}"

    _em_hml_list "$folder" "$page_size" | _em_render_inbox_json
}

_em_read() {
    _em_require_himalaya || return 1
    local msg_id="" fmt="plain" raw=false

    # Parse flags: em read [--html|--raw] <ID>
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --html|-H) fmt="html"; shift ;;
            --raw)     raw=true; shift ;;
            *)         msg_id="$1"; shift ;;
        esac
    done

    if [[ -z "$msg_id" ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em read [--html|--raw] <ID>${_C_NC}"
        return 1
    fi

    local folder="${FLOW_EMAIL_FOLDER:-INBOX}"

    # --raw: dump raw MIME source (for debugging/piping)
    if [[ "$raw" == true ]]; then
        _em_hml_read "$msg_id" raw "$folder"
        return
    fi

    # [1] Validate ID exists — himalaya silently returns empty for non-existent UIDs
    local envelope=""
    if command -v jq &>/dev/null; then
        envelope=$(_em_hml_list "$folder" 100 2>/dev/null \
            | jq -r ".[] | select(.id == ($msg_id | tonumber))" 2>/dev/null)
    fi

    if [[ -z "$envelope" ]]; then
        # ID might be beyond the last 100, or genuinely invalid
        # Try to read anyway — if himalaya returns content, it's valid
        local test_body
        test_body=$(himalaya message read -f "$folder" "$msg_id" 2>/dev/null)
        if [[ -z "$test_body" ]]; then
            _flow_log_error "Email #${msg_id} not found in ${folder}"
            echo -e "  ${_C_DIM}Use ${_C_CYAN}em inbox${_C_DIM} to see valid email IDs${_C_NC}"
            return 1
        fi
        # Body is valid but envelope wasn't in cache — display without header
        if [[ "$fmt" == "html" ]]; then
            local html_body
            html_body=$(_em_hml_read "$msg_id" html "$folder")
            if [[ -n "$html_body" ]]; then
                _em_render "$html_body" "html"
            else
                echo "$test_body" | _em_render_email_body
            fi
        else
            echo "$test_body" | _em_render_email_body
        fi
        return
    fi

    # [2] Display header from envelope
    local from_name from_addr subject edate
    from_name=$(echo "$envelope" | jq -r '.from.name // empty' 2>/dev/null)
    from_addr=$(echo "$envelope" | jq -r '.from.addr // empty' 2>/dev/null)
    subject=$(echo "$envelope" | jq -r '.subject // "(no subject)"' 2>/dev/null)
    edate=$(echo "$envelope" | jq -r '.date // empty' 2>/dev/null)

    local from_display="${from_name:-$from_addr}"
    [[ -n "$from_name" && -n "$from_addr" ]] && from_display="$from_name <$from_addr>"

    echo ""
    echo -e "  ${_C_BOLD}${subject}${_C_NC}"
    echo -e "  ${_C_DIM}From: ${from_display}${_C_NC}"
    echo -e "  ${_C_DIM}Date: ${edate%%T*}${_C_NC}"
    echo -e "  ${_C_DIM}─────────────────────────────────────────────────${_C_NC}"
    echo ""

    # [3] Render body
    local body=""
    if [[ "$fmt" == "html" ]]; then
        body=$(_em_hml_read "$msg_id" html "$folder")
        if [[ -z "$body" ]]; then
            # No HTML part — fall back to plain text
            _flow_log_warning "No HTML part — showing plain text"
            body=$(himalaya message read -f "$folder" "$msg_id" 2>/dev/null)
        fi
        if [[ -n "$body" ]]; then
            _em_render "$body" "html"
        fi
    else
        body=$(himalaya message read -f "$folder" "$msg_id" 2>/dev/null)
        if [[ -n "$body" ]]; then
            echo "$body" | _em_render_email_body
        fi
    fi

    if [[ -z "$body" ]]; then
        echo -e "  ${_C_DIM}(no content)${_C_NC}"
        return 1
    fi
}

_em_send() {
    _em_require_himalaya || return 1
    local to="" subject="" use_ai=false

    # Parse args: em send [--ai] [to] [subject]
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --ai) use_ai=true; shift ;;
            *)
                if [[ -z "$to" ]]; then
                    to="$1"
                elif [[ -z "$subject" ]]; then
                    subject="$1"
                fi
                shift
                ;;
        esac
    done

    # [1] Prompt for missing fields
    if [[ -z "$to" ]]; then
        printf "${_C_BLUE}To:${_C_NC} "
        read -r to
        if [[ -z "$to" ]]; then
            _flow_log_error "Recipient required"
            return 1
        fi
    fi

    if [[ -z "$subject" ]]; then
        printf "${_C_BLUE}Subject:${_C_NC} "
        read -r subject
    fi

    # [2] Optional AI draft from subject
    local ai_body=""
    if [[ "$use_ai" == true && -n "$subject" && "$FLOW_EMAIL_AI" != "none" ]]; then
        _flow_log_info "Generating AI draft from subject..."
        ai_body=$(_em_ai_query "draft" \
            "$(_em_ai_draft_prompt)" \
            "Compose a professional email about: $subject" 2>/dev/null)
        if [[ -n "$ai_body" ]]; then
            _flow_log_success "AI draft ready — edit in \$EDITOR"
        fi
    fi

    # [3] Create temp file + open in $EDITOR
    local draft_file
    draft_file=$(_em_create_draft_file "$to" "$subject" "$ai_body")
    _em_open_in_editor "$draft_file"

    # [4] SAFETY GATE — preview + confirm
    if _em_confirm_send "$draft_file"; then
        # [5] Send via himalaya
        himalaya message send < "$draft_file"
        if [[ $? -eq 0 ]]; then
            _flow_log_success "Email sent"
            rm -f "$draft_file"
        else
            _flow_log_error "Failed to send — draft preserved: $draft_file"
            return 1
        fi
    fi
}

_em_reply() {
    _em_require_himalaya || return 1
    local msg_id=""
    local skip_ai=false
    local reply_all=false
    local batch_mode=false

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-ai)     skip_ai=true; shift ;;
            --all|-a)    reply_all=true; shift ;;
            --batch|-b)  batch_mode=true; shift ;;
            *)           msg_id="$1"; shift ;;
        esac
    done

    if [[ -z "$msg_id" ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em reply <ID>${_C_NC}  ${_C_DIM}(--no-ai --all --batch)${_C_NC}"
        return 1
    fi

    # --- Path 1: Interactive reply (opens $EDITOR via himalaya) ---
    if [[ "$batch_mode" != "true" ]]; then
        local body=""

        # Generate AI draft if available and enabled
        if [[ "$skip_ai" != true && "$FLOW_EMAIL_AI" != "none" && "$FLOW_EMAIL_AI" != "off" ]]; then
            _flow_log_info "Generating AI draft..."
            local original
            original=$(_em_hml_read "$msg_id" plain)
            if [[ -n "$original" ]]; then
                body=$(_em_ai_query "draft" \
                    "$(_em_ai_draft_prompt)" \
                    "$original" "" "$msg_id" 2>/dev/null)
                if [[ -n "$body" ]]; then
                    _flow_log_success "AI draft ready — edit in \$EDITOR"
                else
                    _flow_log_warning "AI draft unavailable — composing from scratch"
                fi
            fi
        fi

        # Open $EDITOR with draft pre-populated via himalaya [BODY] arg
        _em_hml_reply "$msg_id" "$body" "$reply_all"
        return $?
    fi

    # --- Path 2: Batch/non-interactive (preview + confirm + send) ---
    _flow_log_info "Fetching email #${msg_id}..."
    local content
    content=$(_em_hml_read "$msg_id" plain)
    if [[ -z "$content" ]]; then
        _flow_log_error "Could not read email #${msg_id}"
        return 1
    fi

    local draft
    draft=$(_em_ai_query "draft" "$(_em_ai_draft_prompt)" "$content" "" "$msg_id")
    if [[ -z "$draft" ]]; then
        _flow_log_error "Could not generate draft"
        return 1
    fi

    # Get MML template (headers pre-filled, no $EDITOR)
    local mml
    mml=$(_em_hml_template_reply "$msg_id" "$reply_all")

    # Inject AI draft body into MML template
    local mml_with_body
    mml_with_body=$(_em_mml_inject_body "$mml" "$draft")

    # Preview
    echo ""
    echo -e "${_C_BOLD}Draft Reply${_C_NC}"
    echo -e "${_C_DIM}$(printf '%.0s─' {1..60})${_C_NC}"
    echo "$mml_with_body" | head -5
    echo -e "${_C_DIM}---${_C_NC}"
    echo "$draft"
    echo -e "${_C_DIM}$(printf '%.0s─' {1..60})${_C_NC}"
    echo ""

    # Safety gate: explicit confirmation, default NO
    printf "  Send this reply? [y/N] "
    local response
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "$mml_with_body" | _em_hml_template_send
        _em_cache_invalidate "$msg_id"
        _flow_log_success "Reply sent"
    else
        _em_cache_set "drafts" "$msg_id" "$draft"
        _flow_log_info "Draft saved. Review with: ${_C_CYAN}em respond --review${_C_NC}"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# SEARCH & BROWSE
# ═══════════════════════════════════════════════════════════════════

_em_find() {
    _em_require_himalaya || return 1
    local query="$*"
    if [[ -z "$query" ]]; then
        _flow_log_error "Search query required"
        echo "Usage: ${_C_CYAN}em find <query>${_C_NC}"
        return 1
    fi

    _flow_log_info "Searching: $query"

    # Single fetch, filter client-side
    local json
    json=$(_em_hml_list "$FLOW_EMAIL_FOLDER" 100)

    echo "$json" | jq -r --arg q "$query" '
        [.[] | select(
            (.subject | ascii_downcase | contains($q | ascii_downcase)) or
            (.from.name // "" | ascii_downcase | contains($q | ascii_downcase)) or
            (.from.addr // "" | ascii_downcase | contains($q | ascii_downcase))
        )] | .[] | [.id, .from.name // .from.addr, .subject, (.date | split("T")[0] // .date)] | @tsv' \
        | column -t -s $'\t'

    local result_count
    result_count=$(echo "$json" | jq --arg q "$query" '
        [.[] | select(
            (.subject | ascii_downcase | contains($q | ascii_downcase)) or
            (.from.name // "" | ascii_downcase | contains($q | ascii_downcase)) or
            (.from.addr // "" | ascii_downcase | contains($q | ascii_downcase))
        )] | length')
    echo ""
    echo -e "${_C_DIM}${result_count:-0} results${_C_NC}"
}

_em_preview_message() {
    # Formatted email preview for fzf preview window
    # Args: message_id
    # Output: Colored header block + rendered body (truncated)
    local msg_id="$1"
    [[ -z "$msg_id" ]] && return 1

    # Fetch envelope metadata (JSON)
    local envelope
    envelope=$(himalaya envelope list --page-size 100 --output json 2>/dev/null \
        | jq -r ".[] | select(.id == ($msg_id | tonumber))" 2>/dev/null)

    # Extract fields from envelope
    local from_name from_addr subject edate flags
    from_name=$(echo "$envelope" | jq -r '.from.name // empty' 2>/dev/null)
    from_addr=$(echo "$envelope" | jq -r '.from.addr // empty' 2>/dev/null)
    subject=$(echo "$envelope" | jq -r '.subject // "(no subject)"' 2>/dev/null)
    edate=$(echo "$envelope" | jq -r '.date // empty' 2>/dev/null)
    flags=$(echo "$envelope" | jq -r '.flags // [] | join(", ")' 2>/dev/null)

    local from_display="${from_name:-$from_addr}"
    [[ -n "$from_name" && -n "$from_addr" ]] && from_display="$from_name <$from_addr>"

    # Build flag badges
    local badges=""
    [[ "$flags" == *"Seen"* ]]    || badges="${badges}[NEW] "
    [[ "$flags" == *"Flagged"* ]] && badges="${badges}[FLAGGED] "
    [[ "$flags" == *"Answered"* ]] && badges="${badges}[REPLIED] "

    # Format date (show date portion)
    local date_display="${edate%%T*}"

    # Print formatted header
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    printf "  Message #%s %s\n" "$msg_id" "$badges"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    printf "  From:     %s\n" "$from_display"
    printf "  Subject:  %s\n" "$subject"
    printf "  Date:     %s\n" "$date_display"
    [[ -n "$badges" ]] && printf "  Flags:    %s\n" "$badges"
    echo ""
    echo "──────────────────────────────────────────────────"
    echo ""

    # Fetch and render body (truncated for preview)
    local body
    body=$(himalaya message read "$msg_id" 2>/dev/null | head -60)
    if [[ -n "$body" ]]; then
        echo "$body"
    else
        echo "  (no content)"
    fi
}

_em_pick() {
    _em_require_himalaya || return 1
    if ! command -v fzf &>/dev/null; then
        _flow_log_error "fzf required for email picker"
        echo "Install: ${_C_CYAN}brew install fzf${_C_NC}"
        return 1
    fi
    if ! command -v jq &>/dev/null; then
        _flow_log_error "jq required for email picker"
        echo "Install: ${_C_CYAN}brew install jq${_C_NC}"
        return 1
    fi

    local folder="${1:-$FLOW_EMAIL_FOLDER}"

    # [1] Pre-fetch envelopes once (reused for list + preview)
    local cache_file
    cache_file=$(mktemp "${TMPDIR:-/tmp}/em-pick-XXXXXX.json")
    _em_hml_list "$folder" 50 > "$cache_file" 2>/dev/null

    if [[ ! -s "$cache_file" ]]; then
        _flow_log_error "Could not fetch emails"
        rm -f "$cache_file"
        return 1
    fi

    # Count unread from cached data
    local unread_count
    unread_count=$(jq '[.[] | select(.flags | contains(["Seen"]) | not)] | length' "$cache_file" 2>/dev/null)

    local header_line
    header_line="Folder: ${folder}  |  Unread: ${unread_count:-?}
Enter=read  Ctrl-R=reply  Ctrl-S=summarize  Ctrl-A=archive  Ctrl-D=delete
* = unread  + = attachment"

    # [2] Write preview script (avoids shell escaping nightmare)
    local preview_script
    preview_script=$(mktemp "${TMPDIR:-/tmp}/em-preview-XXXXXX.sh")
    cat > "$preview_script" <<PREVIEW_EOF
#!/bin/sh
id="\$1"

# ── Header (from cached envelope JSON) ──
env=\$(jq -r ".[] | select(.id == (\$id | tonumber))" "$cache_file" 2>/dev/null)
if [ -n "\$env" ]; then
  subj=\$(echo "\$env" | jq -r '.subject // "(no subject)"')
  from=\$(echo "\$env" | jq -r '.from.name // .from.addr // "unknown"')
  dt=\$(echo "\$env" | jq -r '.date // ""' | cut -dT -f1)
  printf '\033[1m  %s\033[0m\n' "\$subj"
  printf '\033[2m  From: %s  •  %s\033[0m\n' "\$from" "\$dt"
  printf '\033[2m  ─────────────────────────────────────────────────\033[0m\n'
  echo ''
fi

# ── Body: fast plain text via bat, HTML export only as last resort ──
# --preview avoids marking email as read; --no-headers avoids duplication
body=\$(himalaya message read --no-headers --preview "\$id" 2>/dev/null)
if [ -n "\$body" ]; then
  # Strip noise: CID image refs, Safe Links, MIME markers, angle-bracket URLs
  body=\$(echo "\$body" | sed \\
    -e 's/\[cid:[^]]*\]//g' \\
    -e 's|(https://nam[0-9]*\.safelinks\.protection\.outlook\.com[^)]*)||g' \\
    -e '/<#part/d' \\
    -e '/<#\/part>/d' \\
    -e 's/<http[^>]*>//g' \\
    -e 's/(mailto:[^)]*)//g' \\
  )
  if command -v bat >/dev/null 2>&1; then
    echo "\$body" | bat --style=plain --color=always --paging=never --language=Email --terminal-width=72 2>/dev/null | head -80
  else
    echo "\$body" | head -80
  fi
else
  # No plain text — try HTML export as last resort
  if command -v w3m >/dev/null 2>&1; then
    tmpdir=\$(mktemp -d "\${TMPDIR:-/tmp}/em-prev-XXXXXX")
    himalaya message export -d "\$tmpdir" "\$id" >/dev/null 2>&1
    if [ -f "\$tmpdir/index.html" ]; then
      w3m -dump -T text/html -cols 72 "\$tmpdir/index.html" 2>/dev/null | head -80
    else
      echo "  (no content)"
    fi
    rm -rf "\$tmpdir"
  else
    echo "  (no content)"
  fi
fi
PREVIEW_EOF
    chmod +x "$preview_script"

    # [3] Render list from cached JSON + launch fzf
    local selected
    selected=$(jq -r '.[] | [
            .id,
            (if (.flags | contains(["Seen"])) then " " else "*" end),
            (if .has_attachment then "+" else " " end),
            ((.from.name // .from.addr // "unknown") | if length > 20 then .[:17] + "..." else . end),
            ((.subject // "(no subject)") | if length > 50 then .[:47] + "..." else . end),
            (.date | split("T")[0] // .date)
          ] | @tsv' "$cache_file" \
        | fzf --delimiter='\t' \
              --with-nth='2..' \
              --preview="$preview_script {1}" \
              --preview-window='right:60%:wrap' \
              --header="$header_line" \
              --header-lines=0 \
              --bind='ctrl-r:become(echo REPLY:{1})' \
              --bind='ctrl-s:become(echo SUMMARIZE:{1})' \
              --bind='ctrl-a:become(echo ARCHIVE:{1})' \
              --bind='ctrl-d:become(echo DELETE:{1})' \
              --no-multi \
              --ansi)

    # [4] Cleanup temp files
    rm -f "$cache_file" "$preview_script"

    # Handle selection
    if [[ -z "$selected" ]]; then
        return 0  # User pressed Escape
    fi

    local action_id
    if [[ "$selected" == REPLY:* ]]; then
        action_id="${selected#REPLY:}"
        _em_reply "$action_id"
    elif [[ "$selected" == SUMMARIZE:* ]]; then
        action_id="${selected#SUMMARIZE:}"
        _em_summarize "$action_id"
    elif [[ "$selected" == ARCHIVE:* ]]; then
        action_id="${selected#ARCHIVE:}"
        _em_hml_flags add "$action_id" Seen
        _flow_log_success "Email #${action_id} archived (marked read)"
    elif [[ "$selected" == DELETE:* ]]; then
        action_id="${selected#DELETE:}"
        printf "  Flag email #${action_id} as deleted? [y/N] "
        local confirm
        read -r confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            _em_hml_flags add "$action_id" Deleted
            _flow_log_success "Email #${action_id} flagged as deleted"
        fi
    else
        # Default: read the selected email
        action_id=$(echo "$selected" | cut -f1)
        _em_read "$action_id"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# AI FEATURES
# ═══════════════════════════════════════════════════════════════════

_em_classify() {
    _em_require_himalaya || return 1
    local msg_id="$1"
    if [[ -z "$msg_id" ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em classify <ID>${_C_NC}"
        return 1
    fi

    local content
    content=$(_em_hml_read "$msg_id" plain)
    if [[ -z "$content" ]]; then
        _flow_log_error "Could not read email #${msg_id}"
        return 1
    fi

    local category
    category=$(_em_ai_query "classify" "$(_em_ai_classify_prompt)" "$content" "" "$msg_id")
    if [[ -n "$category" ]]; then
        local icon
        icon=$(_em_category_icon "$category")
        echo -e "  ${icon} ${_C_BOLD}${category}${_C_NC}"
    else
        _flow_log_warning "Classification failed (no AI backend available?)"
    fi
}

_em_summarize() {
    _em_require_himalaya || return 1
    local msg_id="$1"
    if [[ -z "$msg_id" ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em summarize <ID>${_C_NC}"
        return 1
    fi

    local content
    content=$(_em_hml_read "$msg_id" plain)
    if [[ -z "$content" ]]; then
        _flow_log_error "Could not read email #${msg_id}"
        return 1
    fi

    local summary
    summary=$(_em_ai_query "summarize" "$(_em_ai_summarize_prompt)" "$content" "" "$msg_id")
    if [[ -n "$summary" ]]; then
        echo -e "  ${_C_DIM}Summary:${_C_NC} $summary"
    else
        _flow_log_warning "Summarization failed (no AI backend available?)"
    fi
}

_em_respond() {
    # Batch respond: classify → draft → edit in $EDITOR → confirm send
    # Same flow as `em reply` but loops through actionable emails

    # Help check before dependency gate (help should always work)
    [[ "$1" == "--help" || "$1" == "-h" ]] && { _em_respond_help; return; }

    _em_require_himalaya || return 1
    local count=10
    local folder="$FLOW_EMAIL_FOLDER"
    local dry_run=false

    local review_mode=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --count|-n)    shift; count="$1"; shift ;;
            --folder|-f)   shift; folder="$1"; shift ;;
            --dry-run)     dry_run=true; shift ;;
            --review|-R)   review_mode=true; shift ;;
            --clear)       _em_cache_clear; return ;;
            *)             shift ;;
        esac
    done

    if [[ "$review_mode" == "true" ]]; then
        echo -e "${_C_BOLD}em respond --review${_C_NC} ${_C_DIM}— reviewing cached drafts in ${folder}${_C_NC}"
    else
        echo -e "${_C_BOLD}em respond${_C_NC} ${_C_DIM}— scanning ${count} emails in ${folder}${_C_NC}"
    fi
    echo -e "${_C_DIM}$(printf '%.0s━' {1..60})${_C_NC}"

    local messages
    messages=$(_em_hml_list "$folder" "$count")
    if [[ -z "$messages" || "$messages" == "[]" ]]; then
        _flow_log_info "No messages in $folder"
        return 0
    fi

    # Collect into arrays (avoids subshell variable loss)
    local -a msg_ids=() msg_subjects=() msg_froms=() msg_tos=()
    local msg_count
    msg_count=$(echo "$messages" | jq 'length')

    local i
    for (( i=0; i < msg_count; i++ )); do
        msg_ids+=($(echo "$messages" | jq -r ".[$i].id"))
        msg_subjects+=("$(echo "$messages" | jq -r ".[$i].subject // \"(no subject)\"" | head -c 50)")
        msg_froms+=("$(echo "$messages" | jq -r ".[$i].from.name // .[$i].from.addr // \"unknown\"" | head -c 25)")
        msg_tos+=("$(echo "$messages" | jq -r ".[$i].to.addr // empty" 2>/dev/null)")
    done

    local -a actionable_ids=() actionable_cats=()
    local total=${#msg_ids[@]}

    # Declare all loop variables once to avoid ZSH local re-declaration leak
    local idx mid from subj content category icon cached_draft to_addrs
    local found=0 non_actionable=0 actionable_count=0 proceed
    local -a listserv_flags=()

    if [[ "$review_mode" == "true" ]]; then
        # Review mode: skip classification, find emails with cached drafts
        echo ""
        for (( idx=1; idx <= total; idx++ )); do
            mid="${msg_ids[$idx]}"
            from="${msg_froms[$idx]}"
            subj="${msg_subjects[$idx]}"

            cached_draft=$(_em_cache_get "drafts" "$mid" 2>/dev/null)
            if [[ $? -eq 0 && -n "$cached_draft" ]]; then
                (( found++ ))
                echo -e "  ${_C_GREEN}✓${_C_NC} #${mid}  ${from}  ${_C_DIM}${subj:0:35}${_C_NC}"
                actionable_ids+=("$mid")
                actionable_cats+=("cached")
            fi
        done

        actionable_count=${#actionable_ids[@]}
        echo ""
        echo -e "${_C_DIM}$(printf '%.0s━' {1..60})${_C_NC}"
        echo -e "  ${_C_GREEN}${actionable_count} cached drafts${_C_NC} found in ${total} emails"

        if [[ $actionable_count -eq 0 ]]; then
            _flow_log_info "No cached drafts to review"
            _flow_log_info "Generate drafts first: ${_C_CYAN}em respond${_C_NC}"
            return 0
        fi
    else
        # Normal mode: classify all emails (Phase 1)
        echo ""

        for (( idx=1; idx <= total; idx++ )); do
            mid="${msg_ids[$idx]}"
            from="${msg_froms[$idx]}"
            subj="${msg_subjects[$idx]}"
            to_addrs="${msg_tos[$idx]}"

            printf "  ${_C_DIM}[%d/%d]${_C_NC} %-25s " "$idx" "$total" "$from"

            # Skip listserv / campus-wide emails (never auto-respond)
            if [[ "$to_addrs" == *"@LIST."* || "$to_addrs" == *"@list."* || "$to_addrs" == *"-L@"* ]]; then
                echo -e "${_C_DIM}${_C_YELLOW}L${_C_NC} ${_C_DIM}listserv — skip${_C_NC}"
                (( non_actionable++ ))
                continue
            fi

            content=$(_em_hml_read "$mid" plain 2>/dev/null)
            if [[ -z "$content" ]]; then
                echo -e "${_C_DIM}(empty)${_C_NC}"
                continue
            fi

            category=$(_em_ai_query "classify" "$(_em_ai_classify_prompt)" "$content" "" "$mid" 2>/dev/null)
            # Normalize AI response: first line, trimmed, lowercase
            category="${category%%$'\n'*}"
            category="${category## }"
            category="${category%% }"
            category="${(L)category}"
            icon=$(_em_category_icon "$category")

            case "$category" in
                newsletter|automated|admin-info|vendor|spam)
                    echo -e "${_C_DIM}${icon} ${category} — skip${_C_NC}"
                    (( non_actionable++ ))
                    ;;
                *)
                    echo -e "${_C_GREEN}${icon} ${category}${_C_NC} ${_C_DIM}${subj:0:30}${_C_NC}"
                    actionable_ids+=("$mid")
                    actionable_cats+=("$category")
                    # Track if To: was a listserv (for warning in Phase 2)
                    if [[ "$to_addrs" == *"LIST"* || "$to_addrs" == *"list"* ]]; then
                        listserv_flags+=("true")
                    else
                        listserv_flags+=("false")
                    fi
                    ;;
            esac
        done

        actionable_count=${#actionable_ids[@]}
        echo ""
        echo -e "${_C_DIM}$(printf '%.0s━' {1..60})${_C_NC}"
        echo -e "  ${_C_GREEN}${actionable_count} actionable${_C_NC}  ${_C_DIM}${non_actionable} skipped${_C_NC}  of ${total} total"

        if [[ $actionable_count -eq 0 ]]; then
            _flow_log_info "Nothing to respond to"
            return 0
        fi

        if [[ "$dry_run" == "true" ]]; then
            _flow_log_info "Dry run — no drafts generated"
            return 0
        fi
    fi

    # Phase 2: For each actionable email → draft → $EDITOR → confirm send
    echo ""
    if [[ "$review_mode" == "true" ]]; then
        printf "  Review ${actionable_count} cached drafts? [Y/n] "
    else
        printf "  Proceed to draft ${actionable_count} replies? [Y/n] "
    fi
    read -r proceed
    if [[ "$proceed" =~ ^[Nn]$ ]]; then
        return 0
    fi

    local sent=0 skipped_drafts=0
    local cat draft rc cont
    for (( idx=1; idx <= actionable_count; idx++ )); do
        mid="${actionable_ids[$idx]}"
        cat="${actionable_cats[$idx]}"
        icon=$(_em_category_icon "$cat")

        echo ""
        echo -e "${_C_BOLD}Reply ${idx}/${actionable_count}${_C_NC}  ${icon} ${cat}  ${_C_DIM}#${mid}${_C_NC}"
        echo -e "${_C_DIM}$(printf '%.0s─' {1..60})${_C_NC}"

        # Warn about listserv replies
        if [[ "${listserv_flags[$idx]}" == "true" ]]; then
            echo -e "  ${_C_YELLOW}⚠ WARNING: This email was sent to a mailing list${_C_NC}"
            echo -e "  ${_C_YELLOW}  Replying may go to ALL list members. Review carefully.${_C_NC}"
        fi

        # Show original email snippet
        content=$(_em_hml_read "$mid" plain 2>/dev/null)
        echo -e "${_C_DIM}$(echo "$content" | head -5)${_C_NC}"
        echo -e "${_C_DIM}$(printf '%.0s─' {1..60})${_C_NC}"

        if [[ "$review_mode" == "true" ]]; then
            # Review mode: use cached draft (already verified to exist)
            draft=$(_em_cache_get "drafts" "$mid" 2>/dev/null)
            _flow_log_success "Cached draft loaded — opening in \$EDITOR"
        else
            # Normal mode: generate AI draft
            _flow_log_info "Generating AI draft..."
            draft=$(_em_ai_query "draft" "$(_em_ai_draft_prompt)" "$content" "" "$mid" 2>/dev/null)

            if [[ -z "$draft" ]]; then
                _flow_log_warning "AI draft unavailable — opening blank reply"
            else
                _flow_log_success "Draft ready — opening in \$EDITOR"
            fi
        fi

        # Open reply in $EDITOR (same as em reply)
        _em_hml_reply "$mid" "$draft"
        rc=$?

        case $rc in
            0) (( sent++ )) ;;
            2) _flow_log_info "Draft discarded"
               (( skipped_drafts++ )) ;;
            *) _flow_log_warning "Reply failed (rc=$rc)"
               (( skipped_drafts++ )) ;;
        esac

        # Continue prompt (unless last one)
        if [[ $idx -lt $actionable_count ]]; then
            echo ""
            printf "  Continue to next? [Y/n/q] "
            read -r cont
            if [[ "$cont" =~ ^[NnQq]$ ]]; then
                (( skipped_drafts += actionable_count - idx ))
                break
            fi
        fi
    done

    # Summary
    echo ""
    echo -e "${_C_DIM}$(printf '%.0s━' {1..60})${_C_NC}"
    echo -e "  ${_C_GREEN}${sent} replied${_C_NC}  ${_C_DIM}${skipped_drafts} skipped${_C_NC}"
}

_em_respond_help() {
    echo -e "
${_C_BOLD}em respond${_C_NC} — Batch reply to actionable emails

${_C_CYAN}em respond${_C_NC}              Classify → draft → edit in \$EDITOR → send
${_C_CYAN}em respond --review|-R${_C_NC}  Review/send cached drafts (skip classification)
${_C_CYAN}em respond -n 5${_C_NC}         Process 5 emails (default: 10)
${_C_CYAN}em respond --dry-run${_C_NC}    Classify only (no drafts, no \$EDITOR)
${_C_CYAN}em respond --clear${_C_NC}      Clear AI cache

${_C_DIM}Flow: scan → classify → [actionable?] → AI draft → \$EDITOR → confirm send${_C_NC}
${_C_DIM}Review: scan → find cached drafts → \$EDITOR → confirm send${_C_NC}
${_C_DIM}Non-actionable (auto-skipped): newsletter, automated, admin-info, vendor${_C_NC}
${_C_DIM}Listserv emails (*@LIST.*) are always skipped; warnings shown if actionable${_C_NC}
${_C_DIM}Safety: every send requires explicit [y/N] confirmation${_C_NC}
"
}

# ═══════════════════════════════════════════════════════════════════
# QUICK INFO
# ═══════════════════════════════════════════════════════════════════

_em_unread() {
    _em_require_himalaya || return 1
    local folder="${1:-INBOX}"
    local unread_count
    unread_count=$(_em_hml_unread_count "$folder")

    if [[ -n "$unread_count" && "$unread_count" -gt 0 ]]; then
        echo -e "${_C_YELLOW}${unread_count}${_C_NC} unread in ${folder}"
    else
        echo -e "${_C_GREEN}0${_C_NC} unread in ${folder}"
    fi
}

_em_dash() {
    _em_require_himalaya || return 1

    echo -e "${_C_BOLD}em${_C_NC} ${_C_DIM}— quick pulse${_C_NC}"
    echo -e "${_C_DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_C_NC}"

    # Unread count (via adapter)
    local unread_count
    unread_count=$(_em_hml_unread_count)
    if [[ -n "$unread_count" && "$unread_count" -gt 0 ]]; then
        echo -e "  ${_C_YELLOW}${unread_count} unread${_C_NC}"
    else
        echo -e "  ${_C_GREEN}Inbox zero${_C_NC}"
    fi

    echo ""

    # Latest 10 subjects (via adapter)
    echo -e "${_C_DIM}Recent:${_C_NC}"
    _em_hml_list INBOX 10 | _em_render_inbox_json

    echo ""
    echo -e "${_C_DIM}Full inbox:${_C_NC} ${_C_CYAN}em i${_C_NC}  ${_C_DIM}Browse:${_C_NC} ${_C_CYAN}em p${_C_NC}  ${_C_DIM}Help:${_C_NC} ${_C_CYAN}em h${_C_NC}"

    # Background maintenance: prune expired + warm AI cache
    _em_cache_prune &>/dev/null &
    _em_cache_warm 10 &>/dev/null &
}

_em_folders() {
    _em_require_himalaya || return 1
    _em_hml_folders
}

# ═══════════════════════════════════════════════════════════════════
# UTILITIES
# ═══════════════════════════════════════════════════════════════════

_em_html() {
    _em_require_himalaya || return 1
    local msg_id="$1"
    if [[ -z "$msg_id" ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em html <ID>${_C_NC}"
        return 1
    fi

    local html_content
    html_content=$(_em_hml_read "$msg_id" html 2>/dev/null)
    if [[ -z "$html_content" ]]; then
        _flow_log_error "No HTML content for email $msg_id"
        echo "Try: ${_C_CYAN}em read ${msg_id}${_C_NC} for plain text"
        return 1
    fi

    _em_render "$html_content" "html"
}

_em_attach() {
    _em_require_himalaya || return 1
    local msg_id="$1"
    if [[ -z "$msg_id" ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em attach <ID>${_C_NC}"
        return 1
    fi

    local download_dir="${2:-${HOME}/Downloads}"
    [[ -d "$download_dir" ]] || mkdir -p "$download_dir"

    _flow_log_info "Downloading attachments from email #${msg_id}..."
    _em_hml_attachments "$msg_id" "$download_dir"
    if [[ $? -eq 0 ]]; then
        _flow_log_success "Attachments saved to: $download_dir"
    else
        _flow_log_error "No attachments or download failed"
    fi
}

_em_cache_cmd() {
    # Cache management subcommand
    case "$1" in
        stats|status)  _em_cache_stats ;;
        clear|flush)   _em_cache_clear ;;
        warm)          _em_cache_warm "${2:-10}" ;;
        prune)
            local pruned
            pruned=$(_em_cache_prune)
            if (( pruned > 0 )); then
                _flow_log_success "Pruned $pruned expired cache entries"
            else
                _flow_log_info "No expired entries to prune"
            fi
            ;;
        *)
            echo -e "${_C_BOLD}em cache${_C_NC} — AI Cache Management"
            echo ""
            echo -e "  ${_C_CYAN}em cache stats${_C_NC}    Show cache size, TTLs, expired count"
            echo -e "  ${_C_CYAN}em cache prune${_C_NC}    Remove expired entries only"
            echo -e "  ${_C_CYAN}em cache clear${_C_NC}    Clear all cached AI results"
            echo -e "  ${_C_CYAN}em cache warm${_C_NC}     Pre-warm cache for latest emails"
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# DOCTOR — DEPENDENCY HEALTH CHECK
# ═══════════════════════════════════════════════════════════════════

_em_doctor() {
    echo -e "${_C_BOLD}em doctor${_C_NC} — Email Dependency Check"
    echo -e "${_C_DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_C_NC}"

    local ok=0 warn=0 fail=0

    # Required
    _em_doctor_check "himalaya"   "required" "Email CLI backend"   "brew install himalaya"
    _em_doctor_version_check "himalaya" "1.0.0"
    _em_doctor_check "jq"         "required" "JSON processing"     "brew install jq"

    # Recommended
    _em_doctor_check "fzf"               "recommended" "Interactive picker"  "brew install fzf"
    _em_doctor_check "bat"               "recommended" "Syntax highlighting" "brew install bat"
    # HTML rendering fallback chain: w3m > lynx > pandoc > bat
    if command -v w3m &>/dev/null; then
        _em_doctor_check "w3m"     "recommended" "HTML rendering (primary)" "brew install w3m"
    elif command -v lynx &>/dev/null; then
        _em_doctor_check "lynx"    "recommended" "HTML rendering (fallback)" "brew install lynx"
    elif command -v pandoc &>/dev/null; then
        _em_doctor_check "pandoc"  "recommended" "HTML rendering (fallback)" "brew install pandoc"
    else
        _em_doctor_check "w3m"     "recommended" "HTML rendering"            "brew install w3m"
    fi
    _em_doctor_check "glow"              "recommended" "Markdown rendering"  "brew install glow"

    # Infrastructure
    _em_doctor_check "email-oauth2-proxy" "recommended" "OAuth2 IMAP/SMTP proxy" "pip install email-oauth2-proxy"
    _em_doctor_check "terminal-notifier"  "optional"    "Desktop notifications"   "brew install terminal-notifier"

    # Optional (AI)
    if [[ "$FLOW_EMAIL_AI" == "claude" ]]; then
        _em_doctor_check "claude" "optional" "AI drafts (claude)" "npm install -g @anthropic-ai/claude-code"
    elif [[ "$FLOW_EMAIL_AI" == "gemini" ]]; then
        _em_doctor_check "gemini" "optional" "AI drafts (gemini)" "pip install google-generativeai"
    fi

    echo -e "${_C_DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_C_NC}"
    echo -e "${_C_GREEN}$ok passed${_C_NC}  ${_C_YELLOW}$warn warnings${_C_NC}  ${_C_RED}$fail failed${_C_NC}"

    # Config info
    echo ""
    echo -e "${_C_DIM}Config:${_C_NC}"
    echo -e "  AI backend:  ${_C_CYAN}${FLOW_EMAIL_AI}${_C_NC}"
    echo -e "  AI timeout:  ${_C_CYAN}${FLOW_EMAIL_AI_TIMEOUT}s${_C_NC}"
    echo -e "  Page size:   ${_C_CYAN}${FLOW_EMAIL_PAGE_SIZE}${_C_NC}"
    echo -e "  Folder:      ${_C_CYAN}${FLOW_EMAIL_FOLDER}${_C_NC}"
    if [[ -f "${FLOW_CONFIG_DIR}/email.conf" ]]; then
        echo -e "  Config file: ${_C_GREEN}${FLOW_CONFIG_DIR}/email.conf${_C_NC}"
    else
        echo -e "  Config file: ${_C_DIM}(none — using env defaults)${_C_NC}"
    fi
}

_em_doctor_check() {
    local cmd="$1" level="$2" desc="$3" install="$4"

    if command -v "$cmd" &>/dev/null; then
        local ver
        ver=$("$cmd" --version 2>/dev/null | head -1)
        printf "  ${_C_GREEN}%-3s${_C_NC} %-20s ${_C_DIM}%s${_C_NC}\n" "ok" "$cmd" "$ver"
        (( ok++ ))
    elif [[ "$level" == "required" ]]; then
        printf "  ${_C_RED}%-3s${_C_NC} %-20s ${_C_DIM}%s${_C_NC}\n" "!!!" "$cmd ($desc)" "$install"
        (( fail++ ))
    else
        printf "  ${_C_YELLOW}%-3s${_C_NC} %-20s ${_C_DIM}%s${_C_NC}\n" "---" "$cmd ($desc)" "$install"
        (( warn++ ))
    fi
}

_em_doctor_version_check() {
    # Compare installed version against minimum required
    # Args: command, min_version (e.g., "1.0.0")
    # Prints warning if outdated, skips silently if command missing
    local cmd="$1" min_ver="$2"
    command -v "$cmd" &>/dev/null || return 0

    local raw_ver
    raw_ver=$("$cmd" --version 2>/dev/null | head -1)
    # Extract semver digits (e.g., "himalaya 1.1.0" -> "1.1.0")
    local cur_ver="${raw_ver//[^0-9.]}"
    [[ -z "$cur_ver" ]] && return 0

    if _em_semver_lt "$cur_ver" "$min_ver"; then
        printf "  ${_C_YELLOW}%-3s${_C_NC} %-20s ${_C_DIM}%s${_C_NC}\n" \
            "!!!" "$cmd version" "v${cur_ver} < v${min_ver} (upgrade: brew upgrade $cmd)"
        (( warn++ ))
    fi
}

_em_semver_lt() {
    # Returns 0 if $1 < $2 (semver comparison), 1 otherwise
    local a="$1" b="$2"
    local a_major a_minor a_patch b_major b_minor b_patch
    a_major="${a%%.*}"; a="${a#*.}"; a_minor="${a%%.*}"; a_patch="${a#*.}"
    b_major="${b%%.*}"; b="${b#*.}"; b_minor="${b%%.*}"; b_patch="${b#*.}"
    # Default missing components to 0
    : "${a_major:=0}" "${a_minor:=0}" "${a_patch:=0}"
    : "${b_major:=0}" "${b_minor:=0}" "${b_patch:=0}"

    (( a_major < b_major )) && return 0
    (( a_major > b_major )) && return 1
    (( a_minor < b_minor )) && return 0
    (( a_minor > b_minor )) && return 1
    (( a_patch < b_patch )) && return 0
    return 1
}
