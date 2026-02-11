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
        respond|resp) shift; _em_respond "$@" ;;
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
  ${_C_CYAN}em read <ID>${_C_NC}      Read email
  ${_C_CYAN}em reply <ID>${_C_NC}     AI-draft reply in \$EDITOR
  ${_C_CYAN}em send${_C_NC}           Compose new email
  ${_C_CYAN}em pick${_C_NC}           fzf email browser

${_C_YELLOW}QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} em                      ${_C_DIM}# Quick pulse check${_C_NC}
  ${_C_DIM}\$${_C_NC} em r 42                 ${_C_DIM}# Read email #42${_C_NC}
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
  ${_C_CYAN}em unread${_C_NC}         Show unread count
  ${_C_CYAN}em html <ID>${_C_NC}      Render HTML email in terminal

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
    if ! command -v himalaya &>/dev/null; then
        _flow_log_error "himalaya not found"
        echo "Install: ${_C_CYAN}cargo install himalaya${_C_NC} or ${_C_CYAN}brew install himalaya${_C_NC}"
        echo "Setup:   ${_C_CYAN}em doctor${_C_NC} for full dependency check"
        return 1
    fi
    return 0
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
    local msg_id="$1"
    if [[ -z "$msg_id" ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em read <ID>${_C_NC}"
        return 1
    fi

    _em_hml_read "$msg_id" | _em_smart_render
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

    # Pre-compute stats for header
    local unread_count
    unread_count=$(_em_hml_unread_count "$folder" 2>/dev/null)

    local header_line
    header_line="Folder: ${folder}  |  Unread: ${unread_count:-?}
Enter=read  Ctrl-R=reply  Ctrl-S=summarize  Ctrl-A=archive  Ctrl-D=delete
* = unread  + = attachment"

    local selected
    selected=$(_em_hml_list "$folder" 50 \
        | jq -r '.[] | [
            .id,
            (if (.flags | contains(["Seen"])) then " " else "*" end),
            (if .has_attachment then "+" else " " end),
            ((.from.name // .from.addr // "unknown") | if length > 20 then .[:17] + "..." else . end),
            ((.subject // "(no subject)") | if length > 50 then .[:47] + "..." else . end),
            (.date | split("T")[0] // .date)
          ] | @tsv' \
        | fzf --delimiter='\t' \
              --with-nth='2..' \
              --preview='_em_preview_message {1}' \
              --preview-window='right:60%:wrap' \
              --header="$header_line" \
              --header-lines=0 \
              --bind='ctrl-r:become(echo REPLY:{1})' \
              --bind='ctrl-s:become(echo SUMMARIZE:{1})' \
              --bind='ctrl-a:become(echo ARCHIVE:{1})' \
              --bind='ctrl-d:become(echo DELETE:{1})' \
              --no-multi \
              --ansi)

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
    _em_require_himalaya || return 1
    local review_mode=false
    local count=10
    local folder="$FLOW_EMAIL_FOLDER"
    local auto_review=true

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --review|-r)     review_mode=true; shift ;;
            --count|-n)      shift; count="$1"; shift ;;
            --folder|-f)     shift; folder="$1"; shift ;;
            --no-review)     auto_review=false; shift ;;
            --clear)         _em_cache_clear; return ;;
            --help|-h)       _em_respond_help; return ;;
            *)               shift ;;
        esac
    done

    if [[ "$review_mode" == "true" ]]; then
        _em_respond_review
        return
    fi

    # Batch draft generation with progress
    echo -e "${_C_BOLD}em respond${_C_NC} ${_C_DIM}— scanning ${count} emails in ${folder}${_C_NC}"
    echo -e "${_C_DIM}$(printf '%.0s━' {1..60})${_C_NC}"

    local messages
    messages=$(_em_hml_list "$folder" "$count")
    if [[ -z "$messages" || "$messages" == "[]" ]]; then
        _flow_log_info "No messages in $folder"
        return 0
    fi

    # Collect message IDs into array (avoids subshell variable loss)
    local -a msg_ids=()
    local -a msg_subjects=()
    local -a msg_froms=()
    local msg_count
    msg_count=$(echo "$messages" | jq 'length')

    local i
    for (( i=0; i < msg_count; i++ )); do
        msg_ids+=($(echo "$messages" | jq -r ".[$i].id"))
        msg_subjects+=($(echo "$messages" | jq -r ".[$i].subject // \"(no subject)\"" | head -c 50))
        msg_froms+=($(echo "$messages" | jq -r ".[$i].from.name // .[$i].from.addr // \"unknown\"" | head -c 20))
    done

    local total=${#msg_ids[@]} drafted=0 skipped=0 non_actionable=0
    echo ""

    local idx
    for (( idx=1; idx <= total; idx++ )); do
        local mid="${msg_ids[$idx]}"
        local subj="${msg_subjects[$idx]}"
        local from="${msg_froms[$idx]}"

        # Progress indicator
        printf "  ${_C_DIM}[%d/%d]${_C_NC} #%-6s %-20s " "$idx" "$total" "$mid" "$from"

        # Skip if draft already cached
        if _em_cache_get "drafts" "$mid" &>/dev/null; then
            echo -e "${_C_DIM}cached${_C_NC}"
            (( skipped++ ))
            continue
        fi

        # Read email content
        local content
        content=$(_em_hml_read "$mid" plain 2>/dev/null)
        if [[ -z "$content" ]]; then
            echo -e "${_C_DIM}empty${_C_NC}"
            continue
        fi

        # Classify
        local category
        category=$(_em_ai_query "classify" "$(_em_ai_classify_prompt)" "$content" "" "$mid" 2>/dev/null)
        local icon=$(_em_category_icon "$category")

        # Skip non-actionable categories
        case "$category" in
            newsletter|automated|admin-info|spam)
                echo -e "${_C_DIM}${icon} ${category}${_C_NC}"
                (( non_actionable++ ))
                continue
                ;;
        esac

        # Generate draft for actionable email
        local draft
        draft=$(_em_ai_query "draft" "$(_em_ai_draft_prompt)" "$content" "" "$mid" 2>/dev/null)
        if [[ -n "$draft" ]]; then
            (( drafted++ ))
            echo -e "${_C_GREEN}${icon} drafted${_C_NC} ${_C_DIM}(${category})${_C_NC}"
        else
            echo -e "${_C_YELLOW}${icon} no draft${_C_NC} ${_C_DIM}(AI failed)${_C_NC}"
        fi
    done

    # Summary
    echo ""
    echo -e "${_C_DIM}$(printf '%.0s━' {1..60})${_C_NC}"
    echo -e "  ${_C_GREEN}${drafted} drafted${_C_NC}  ${_C_DIM}${non_actionable} skipped (non-actionable)  ${skipped} cached${_C_NC}"

    # Auto-enter review if we have drafts
    if [[ "$auto_review" == "true" && "$drafted" -gt 0 ]]; then
        echo ""
        printf "  Review drafts now? [Y/n] "
        local response
        read -r response
        if [[ ! "$response" =~ ^[Nn]$ ]]; then
            _em_respond_review
        fi
    elif [[ "$drafted" -gt 0 ]]; then
        echo -e "  Review: ${_C_CYAN}em respond --review${_C_NC}"
    fi
}

_em_respond_review() {
    # Review and act on generated drafts
    local cache_base="$(_em_cache_dir)/drafts"
    if [[ ! -d "$cache_base" ]] || [[ -z "$(ls -A "$cache_base" 2>/dev/null)" ]]; then
        _flow_log_info "No drafts to review. Run ${_C_CYAN}em respond${_C_NC} first."
        return 0
    fi

    echo -e "\n${_C_BOLD}Draft Review${_C_NC}"
    echo -e "${_C_DIM}$(printf '%.0s━' {1..60})${_C_NC}\n"

    # Iterate through drafts one by one
    local draft_file sent=0 edited=0 discarded=0 remaining=0
    local -a draft_files=("$cache_base"/*.txt(N))
    local total_drafts=${#draft_files[@]}

    if [[ $total_drafts -eq 0 ]]; then
        _flow_log_info "No drafts to review."
        return 0
    fi

    local idx=0
    for draft_file in "${draft_files[@]}"; do
        (( idx++ ))
        local draft_content
        draft_content=$(< "$draft_file")
        local cache_key="${draft_file:t:r}"

        # Try to find the original message ID from cache key
        # Cache key is md5 hash — look up classification for context
        local class_content=""
        local class_file="$(_em_cache_dir)/classifications/${cache_key}.txt"
        [[ -f "$class_file" ]] && class_content=$(< "$class_file")

        echo -e "  ${_C_BOLD}Draft ${idx}/${total_drafts}${_C_NC}${class_content:+  ${_C_DIM}($class_content)${_C_NC}}"
        echo -e "  ${_C_DIM}$(printf '%.0s─' {1..56})${_C_NC}"
        echo "$draft_content" | head -10
        [[ $(echo "$draft_content" | wc -l) -gt 10 ]] && echo -e "  ${_C_DIM}... ($(echo "$draft_content" | wc -l | tr -d ' ') lines total)${_C_NC}"
        echo -e "  ${_C_DIM}$(printf '%.0s─' {1..56})${_C_NC}"
        echo ""

        # Action prompt
        printf "  [${_C_GREEN}s${_C_NC}]end  [${_C_CYAN}e${_C_NC}]dit  [${_C_RED}d${_C_NC}]iscard  [${_C_DIM}n${_C_NC}]ext  [${_C_DIM}q${_C_NC}]uit: "
        local action
        read -r -k1 action
        echo ""

        case "$action" in
            s|S)
                # Send: get original msg ID, construct reply, confirm
                echo -e "  ${_C_YELLOW}Send not yet wired — use ${_C_CYAN}em reply <ID> --batch${_C_NC} with the draft${_C_NC}"
                echo -e "  ${_C_DIM}Draft preserved in cache for manual send${_C_NC}"
                (( remaining++ ))
                ;;
            e|E)
                # Edit in $EDITOR then keep
                local tmpfile
                tmpfile=$(mktemp "${TMPDIR:-/tmp}/em-draft-XXXXXX.txt")
                echo "$draft_content" > "$tmpfile"
                ${EDITOR:-nvim} "$tmpfile"
                # Save edited draft back to cache
                local edited_content
                edited_content=$(< "$tmpfile")
                if [[ "$edited_content" != "$draft_content" ]]; then
                    echo "$edited_content" > "$draft_file"
                    echo -e "  ${_C_GREEN}Draft updated${_C_NC}"
                    (( edited++ ))
                else
                    echo -e "  ${_C_DIM}No changes${_C_NC}"
                fi
                rm -f "$tmpfile"
                (( remaining++ ))
                ;;
            d|D)
                # Discard draft
                rm -f "$draft_file"
                echo -e "  ${_C_RED}Discarded${_C_NC}"
                (( discarded++ ))
                ;;
            q|Q)
                (( remaining += total_drafts - idx ))
                break
                ;;
            *)
                # Skip/next
                (( remaining++ ))
                ;;
        esac
        echo ""
    done

    # Summary
    echo -e "${_C_DIM}$(printf '%.0s━' {1..60})${_C_NC}"
    echo -e "  ${_C_GREEN}${edited} edited${_C_NC}  ${_C_RED}${discarded} discarded${_C_NC}  ${_C_DIM}${remaining} remaining${_C_NC}"
}

_em_respond_help() {
    echo -e "
${_C_BOLD}em respond${_C_NC} — Batch AI draft generation

${_C_CYAN}em respond${_C_NC}              Scan emails → classify → draft → review
${_C_CYAN}em respond --review${_C_NC}     Review cached drafts (edit/discard)
${_C_CYAN}em respond -n 15${_C_NC}        Process 15 emails (default: 10)
${_C_CYAN}em respond --no-review${_C_NC}  Generate drafts without auto-review
${_C_CYAN}em respond --clear${_C_NC}      Clear all cached drafts

${_C_DIM}Workflow: scan → classify → skip non-actionable → AI draft → review${_C_NC}
${_C_DIM}Categories: student-question, admin-important, scheduling, etc.${_C_NC}
${_C_DIM}Non-actionable (auto-skipped): newsletter, automated, admin-info${_C_NC}
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
        *)
            echo -e "${_C_BOLD}em cache${_C_NC} — AI Cache Management"
            echo ""
            echo -e "  ${_C_CYAN}em cache stats${_C_NC}    Show cache statistics"
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
    _em_doctor_check "himalaya"   "required" "Email CLI backend"   "cargo install himalaya"
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
