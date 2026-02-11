#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# EM - Email Dispatcher (himalaya wrapper)
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         lib/dispatchers/email-dispatcher.zsh
# Version:      0.5 (Phase 4+5 — AI pipeline + config + doctor)
# Date:         2026-02-10
# Pattern:      command + keyword + options
#
# Usage:        em <action> [args]
#
# Examples:
#   em                  # Inbox (default)
#   em inbox            # List recent emails
#   em read <ID>        # Read email
#   em reply <ID>       # AI-draft reply in $EDITOR
#   em send             # Compose new email
#   em pick             # fzf email browser
#   em help             # Show all commands
#
# Backend:      himalaya CLI (https://github.com/pimalaya/himalaya)
# Editor:       $EDITOR (nvim recommended)
# AI:           claude -p / gemini (configurable)
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
  ${_C_CYAN}em${_C_NC}                 Quick pulse (unread + 5 latest)
  ${_C_CYAN}em read <ID>${_C_NC}      Read email
  ${_C_CYAN}em reply <ID>${_C_NC}     AI-draft reply in \$EDITOR
  ${_C_CYAN}em send${_C_NC}           Compose new email
  ${_C_CYAN}em pick${_C_NC}           fzf email browser

${_C_YELLOW}QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} em                      ${_C_DIM}# Quick pulse check${_C_NC}
  ${_C_DIM}\$${_C_NC} em r 42                 ${_C_DIM}# Read email #42${_C_NC}
  ${_C_DIM}\$${_C_NC} em re 42                ${_C_DIM}# Reply with AI draft${_C_NC}
  ${_C_DIM}\$${_C_NC} em s                    ${_C_DIM}# Compose new email${_C_NC}
  ${_C_DIM}\$${_C_NC} em p                    ${_C_DIM}# Browse with fzf${_C_NC}
  ${_C_DIM}\$${_C_NC} em f \"quarterly report\" ${_C_DIM}# Search emails${_C_NC}

${_C_BLUE}INBOX & READING${_C_NC}:
  ${_C_CYAN}em inbox [N]${_C_NC}      List N recent emails (default: ${FLOW_EMAIL_PAGE_SIZE})
  ${_C_CYAN}em read <ID>${_C_NC}      Read email (smart rendering)
  ${_C_CYAN}em unread${_C_NC}         Show unread count
  ${_C_CYAN}em html <ID>${_C_NC}      Render HTML email in terminal

${_C_BLUE}COMPOSE & REPLY${_C_NC}:
  ${_C_CYAN}em send${_C_NC}           Compose new (opens \$EDITOR)
  ${_C_CYAN}em reply <ID>${_C_NC}     Reply with AI draft
  ${_C_CYAN}em attach <ID>${_C_NC}    Download attachments

${_C_BLUE}SEARCH & BROWSE${_C_NC}:
  ${_C_CYAN}em find <query>${_C_NC}   Search emails
  ${_C_CYAN}em pick [FOLDER]${_C_NC}  fzf browser with preview

${_C_BLUE}INFO & MANAGEMENT${_C_NC}:
  ${_C_CYAN}em dash${_C_NC}           Quick dashboard (unread + recent)
  ${_C_CYAN}em folders${_C_NC}        List mail folders
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
# HIMALAYA DEPENDENCY CHECK
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
# SUBCOMMAND STUBS (Phase 2-5 implementation)
# ═══════════════════════════════════════════════════════════════════

_em_inbox() {
    _em_require_himalaya || return 1
    local page_size="${1:-$FLOW_EMAIL_PAGE_SIZE}"
    local folder="${2:-$FLOW_EMAIL_FOLDER}"

    himalaya envelope list -f "$folder" --page-size "$page_size" --output json 2>/dev/null \
        | _em_render_inbox_json
}

_em_read() {
    _em_require_himalaya || return 1
    local msg_id="$1"
    if [[ -z "$msg_id" ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em read <ID>${_C_NC}"
        return 1
    fi
    himalaya message read "$msg_id" | _em_smart_render
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
        ai_body=$(_em_ai_draft "Compose a professional email about: $subject" 2>/dev/null)
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
    local msg_id="$1"
    local skip_ai=false

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-ai) skip_ai=true; shift ;;
            *) msg_id="$1"; shift ;;
        esac
    done

    if [[ -z "$msg_id" ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em reply <ID>${_C_NC}  ${_C_DIM}(--no-ai to skip AI draft)${_C_NC}"
        return 1
    fi

    # [1] Fetch original email
    _flow_log_info "Fetching email #${msg_id}..."
    local original
    original=$(himalaya message read "$msg_id" 2>/dev/null)
    if [[ -z "$original" ]]; then
        _flow_log_error "Could not read email #${msg_id}"
        return 1
    fi

    # [2] Extract reply headers from original
    local from_addr subject
    from_addr=$(echo "$original" | grep -m1 '^From:' | sed 's/^From: *//')
    subject=$(echo "$original" | grep -m1 '^Subject:' | sed 's/^Subject: *//')
    [[ "$subject" != Re:* ]] && subject="Re: $subject"

    # [3] AI draft (with spinner, graceful fallback)
    local ai_body=""
    if [[ "$skip_ai" != true && "$FLOW_EMAIL_AI" != "none" && "$FLOW_EMAIL_AI" != "off" ]]; then
        _flow_log_info "Generating AI draft..."
        ai_body=$(_em_ai_draft "$original" 2>/dev/null)
        if [[ -n "$ai_body" ]]; then
            _flow_log_success "AI draft ready — edit in \$EDITOR"
        else
            _flow_log_warning "AI draft unavailable — composing from scratch"
        fi
    fi

    # [4] Create temp file + open in $EDITOR
    local draft_file
    draft_file=$(_em_create_draft_file "$from_addr" "$subject" "$ai_body")
    _em_open_in_editor "$draft_file"

    # [5] SAFETY GATE — preview + confirm
    if _em_confirm_send "$draft_file"; then
        # [6] Send via himalaya
        himalaya message send < "$draft_file"
        if [[ $? -eq 0 ]]; then
            _flow_log_success "Reply sent"
            rm -f "$draft_file"
        else
            _flow_log_error "Failed to send — draft preserved: $draft_file"
            return 1
        fi
    fi
}

_em_find() {
    _em_require_himalaya || return 1
    local query="$*"
    if [[ -z "$query" ]]; then
        _flow_log_error "Search query required"
        echo "Usage: ${_C_CYAN}em find <query>${_C_NC}"
        return 1
    fi

    _flow_log_info "Searching: $query"
    himalaya envelope list --output json 2>/dev/null \
        | jq -r --arg q "$query" '
            [.[] | select(
                (.subject | ascii_downcase | contains($q | ascii_downcase)) or
                (.from.name // "" | ascii_downcase | contains($q | ascii_downcase)) or
                (.from.addr // "" | ascii_downcase | contains($q | ascii_downcase))
            )] | .[] | [.id, .from.name // .from.addr, .subject, (.date | split("T")[0] // .date)] | @tsv' \
        | column -t -s $'\t'

    local result_count
    result_count=$(himalaya envelope list --output json 2>/dev/null \
        | jq --arg q "$query" '
            [.[] | select(
                (.subject | ascii_downcase | contains($q | ascii_downcase)) or
                (.from.name // "" | ascii_downcase | contains($q | ascii_downcase)) or
                (.from.addr // "" | ascii_downcase | contains($q | ascii_downcase))
            )] | length')
    echo ""
    echo -e "${_C_DIM}${result_count:-0} results${_C_NC}"
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

    # Build fzf input from himalaya JSON output
    # Schema: {id, flags, subject, from: {name, addr}, date, has_attachment}
    local selected
    selected=$(himalaya envelope list -f "$folder" --page-size 50 --output json 2>/dev/null \
        | jq -r '.[] | [
            .id,
            (if (.flags | contains(["Seen"])) then " " else "*" end),
            (if .has_attachment then "+" else " " end),
            (.from.name // .from.addr // "unknown"),
            .subject,
            (.date | split("T")[0] // .date)
          ] | @tsv' \
        | fzf --delimiter='\t' \
              --with-nth='2..' \
              --preview='himalaya message read {1} 2>/dev/null | head -80' \
              --preview-window='right:60%:wrap' \
              --header='* = unread  + = attachment | Enter=read  Ctrl-R=reply  Ctrl-D=delete' \
              --bind='ctrl-r:become(echo REPLY:{1})' \
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
    elif [[ "$selected" == DELETE:* ]]; then
        action_id="${selected#DELETE:}"
        printf "  Flag email #${action_id} as deleted? [y/N] "
        local confirm
        read -r confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            himalaya flag add "$action_id" Deleted
            _flow_log_success "Email #${action_id} flagged as deleted"
        fi
    else
        # Default: read the selected email
        action_id=$(echo "$selected" | cut -f1)
        _em_read "$action_id"
    fi
}

_em_unread() {
    _em_require_himalaya || return 1
    local folder="${1:-INBOX}"
    local unread_count
    unread_count=$(himalaya envelope list -f "$folder" --output json 2>/dev/null \
        | jq '[.[] | select(.flags | contains(["Seen"]) | not)] | length' 2>/dev/null)

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

    # Unread count
    local unread_count
    unread_count=$(himalaya envelope list -f INBOX --output json 2>/dev/null \
        | jq '[.[] | select(.flags | contains(["Seen"]) | not)] | length' 2>/dev/null)
    if [[ -n "$unread_count" && "$unread_count" -gt 0 ]]; then
        echo -e "  ${_C_YELLOW}${unread_count} unread${_C_NC}"
    else
        echo -e "  ${_C_GREEN}Inbox zero${_C_NC}"
    fi

    echo ""

    # Latest 10 subjects
    echo -e "${_C_DIM}Recent:${_C_NC}"
    himalaya envelope list --page-size 10 --output json 2>/dev/null | _em_render_inbox_json

    echo ""
    echo -e "${_C_DIM}Full inbox:${_C_NC} ${_C_CYAN}em i${_C_NC}  ${_C_DIM}Browse:${_C_NC} ${_C_CYAN}em p${_C_NC}  ${_C_DIM}Help:${_C_NC} ${_C_CYAN}em h${_C_NC}"
}

_em_folders() {
    _em_require_himalaya || return 1
    himalaya folder list
}

_em_html() {
    _em_require_himalaya || return 1
    local msg_id="$1"
    if [[ -z "$msg_id" ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em html <ID>${_C_NC}"
        return 1
    fi

    if ! command -v w3m &>/dev/null; then
        _flow_log_error "w3m required for HTML rendering"
        echo "Install: ${_C_CYAN}brew install w3m${_C_NC}"
        echo "Fallback: ${_C_CYAN}em read ${msg_id}${_C_NC} for plain text"
        return 1
    fi

    himalaya message read --html "$msg_id" 2>/dev/null \
        | w3m -dump -T text/html \
        | _em_pager
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
    himalaya attachment download -f INBOX "$msg_id" --dir "$download_dir" 2>&1
    if [[ $? -eq 0 ]]; then
        _flow_log_success "Attachments saved to: $download_dir"
    else
        _flow_log_error "No attachments or download failed"
    fi
}

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
    _em_doctor_check "w3m"               "recommended" "HTML rendering"      "brew install w3m"
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
