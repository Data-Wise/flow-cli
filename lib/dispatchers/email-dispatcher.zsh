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

: ${FLOW_EMAIL_AI:=claude}              # AI backend: claude | gemini | none
: ${FLOW_EMAIL_PAGE_SIZE:=25}           # Default inbox page size
: ${FLOW_EMAIL_FOLDER:=INBOX}           # Default folder
: ${FLOW_EMAIL_TRASH_FOLDER:=Trash}     # Trash folder (Exchange: "Deleted Items")
: ${FLOW_EMAIL_AI_TIMEOUT:=30}          # AI draft timeout in seconds

# Load config file overrides (project .flow/email.conf > global)
_em_load_config 2>/dev/null

# ═══════════════════════════════════════════════════════════════════
# V2.0 MODULE SOURCING (lazy — only if files exist)
# ═══════════════════════════════════════════════════════════════════

{
    local _em_lib_dir="${0:A:h:h}"  # lib/ directory (parent of dispatchers/)
    [[ -f "$_em_lib_dir/em-ics.zsh" ]]   && source "$_em_lib_dir/em-ics.zsh"
    [[ -f "$_em_lib_dir/em-watch.zsh" ]]  && source "$_em_lib_dir/em-watch.zsh"
}

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
        # MANAGE
        # ─────────────────────────────────────────────────────────────
        delete|del|rm) shift; _em_delete "$@" ;;
        move|mv)       shift; _em_move "$@" ;;
        restore)       shift; _em_restore "$@" ;;
        flag|fl)       shift; _em_flag "$@" ;;
        unflag)        shift; _em_unflag "$@" ;;

        # ─────────────────────────────────────────────────────────────
        # FOLDERS
        # ─────────────────────────────────────────────────────────────
        create-folder|cf)  shift; _em_create_folder "$@" ;;
        delete-folder|df)  shift; _em_delete_folder "$@" ;;

        # ─────────────────────────────────────────────────────────────
        # AI FEATURES
        # ─────────────────────────────────────────────────────────────
        respond|resp|repond) shift; _em_respond "$@" ;;
        classify|cl)  shift; _em_classify "$@" ;;
        summarize|sum) shift; _em_summarize "$@" ;;
        catch|c)      shift; _em_catch "$@" ;;
        todo|td)      shift; _em_todo "$@" ;;
        event|ev)     shift; _em_event "$@" ;;
        ai|AI)        shift; _em_ai_cmd "$@" ;;

        # ─────────────────────────────────────────────────────────────
        # ORGANIZE
        # ─────────────────────────────────────────────────────────────
        star|flag)    shift; _em_star "$@" ;;
        starred)      shift; _em_starred "$@" ;;
        move|mv)      shift; _em_move "$@" ;;
        thread|th)    shift; _em_thread "$@" ;;
        snooze|snz)   shift; _em_snooze "$@" ;;
        snoozed)      shift; _em_snoozed "$@" ;;
        digest|dg)    shift; _em_digest "$@" ;;

        # ─────────────────────────────────────────────────────────────
        # QUICK INFO
        # ─────────────────────────────────────────────────────────────
        unread|u)     shift; _em_unread "$@" ;;
        dash|d)       shift; _em_dash "$@" ;;
        folders)      shift; _em_folders "$@" ;;

        # ─────────────────────────────────────────────────────────────
        # CALENDAR & WATCH (v2.0)
        # ─────────────────────────────────────────────────────────────
        calendar|cal)  shift; em_calendar "$@" ;;
        watch|w)       shift; em_watch "$@" ;;

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

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(daily workflow)${_C_NC}:
  ${_C_CYAN}em${_C_NC}                 Quick pulse (unread + 10 latest)
  ${_C_CYAN}em read <ID>${_C_NC}      Read email (--html, --md, --raw)
  ${_C_CYAN}em reply <ID>${_C_NC}     AI-draft reply in \$EDITOR
  ${_C_CYAN}em send${_C_NC}           Compose new email
  ${_C_CYAN}em pick${_C_NC}           fzf email browser

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} em                      ${_C_DIM}# Quick pulse check${_C_NC}
  ${_C_DIM}\$${_C_NC} em r 42                 ${_C_DIM}# Read email #42${_C_NC}
  ${_C_DIM}\$${_C_NC} em r --html 42          ${_C_DIM}# Read HTML version${_C_NC}
  ${_C_DIM}\$${_C_NC} em r --md 42            ${_C_DIM}# Read as Markdown (pandoc)${_C_NC}
  ${_C_DIM}\$${_C_NC} em re 42                ${_C_DIM}# Reply with AI draft${_C_NC}
  ${_C_DIM}\$${_C_NC} em re 42 --all          ${_C_DIM}# Reply-all${_C_NC}
  ${_C_DIM}\$${_C_NC} em re 42 --batch        ${_C_DIM}# Non-interactive (preview+confirm)${_C_NC}
  ${_C_DIM}\$${_C_NC} em s                    ${_C_DIM}# Compose new email${_C_NC}
  ${_C_DIM}\$${_C_NC} em p                    ${_C_DIM}# Browse with fzf${_C_NC}
  ${_C_DIM}\$${_C_NC} em f \"quarterly report\" ${_C_DIM}# Search emails${_C_NC}
  ${_C_DIM}\$${_C_NC} em resp                 ${_C_DIM}# Batch AI drafts for actionable emails${_C_NC}

${_C_BLUE}📋 INBOX & READING${_C_NC}:
  ${_C_CYAN}em inbox [N]${_C_NC}      List N recent emails (default: ${FLOW_EMAIL_PAGE_SIZE})
  ${_C_CYAN}em read <ID>${_C_NC}      Read email (smart rendering)
  ${_C_CYAN}em read --html <ID>${_C_NC} Read HTML version (w3m/lynx)
  ${_C_CYAN}em read --md <ID>${_C_NC}   Read as clean Markdown (pandoc)
  ${_C_CYAN}em read --raw <ID>${_C_NC}  Dump raw MIME source
  ${_C_CYAN}em unread${_C_NC}         Show unread count
  ${_C_CYAN}em html <ID>${_C_NC}      Render HTML email ${_C_DIM}(alias for read --html)${_C_NC}

${_C_BLUE}COMPOSE & REPLY${_C_NC}:
  ${_C_CYAN}em send${_C_NC}           Compose new (opens \$EDITOR)
  ${_C_CYAN}em reply <ID>${_C_NC}     Reply with AI draft (--no-ai, --all, --batch)
  ${_C_CYAN}em attach <ID>${_C_NC}    Download attachments

${_C_BLUE}ORGANIZE${_C_NC}:
  ${_C_CYAN}em star <ID>${_C_NC}     Toggle starred (flagged) status
  ${_C_CYAN}em starred${_C_NC}       List starred emails
  ${_C_CYAN}em thread <ID>${_C_NC}   Show conversation thread
  ${_C_CYAN}em snooze <ID> <T>${_C_NC} Snooze (2h, 1d, tomorrow, monday)
  ${_C_CYAN}em snoozed${_C_NC}       List snoozed emails
  ${_C_CYAN}em digest${_C_NC}        AI-grouped daily summary (--week)

${_C_BLUE}MANAGE${_C_NC}:
  ${_C_CYAN}em delete <ID>${_C_NC}       Delete email (move to Trash)
  ${_C_CYAN}em delete --pick${_C_NC}     Interactive multi-select delete
  ${_C_CYAN}em delete --purge${_C_NC}    Permanent delete (requires \"yes\")
  ${_C_CYAN}em move <ID> [F]${_C_NC}    Move to folder (fzf picker if no folder)
  ${_C_CYAN}em restore <ID>${_C_NC}     Restore from Trash to INBOX
  ${_C_CYAN}em flag <ID>${_C_NC}        Star for follow-up
  ${_C_CYAN}em unflag <ID>${_C_NC}      Remove star

${_C_BLUE}AI FEATURES${_C_NC}:
  ${_C_CYAN}em respond${_C_NC}        Batch AI drafts for actionable emails
  ${_C_CYAN}em respond --review${_C_NC} Review/send generated drafts
  ${_C_CYAN}em classify <ID>${_C_NC}  Classify email (AI)
  ${_C_CYAN}em summarize <ID>${_C_NC} One-line summary (AI)
  ${_C_CYAN}em catch <ID>${_C_NC}     Capture email as task
  ${_C_CYAN}em todo <ID>${_C_NC}      Extract action items -> flow + Reminders.app
  ${_C_CYAN}em event <ID>${_C_NC}     Extract events -> flow + Calendar.app

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

${_C_BLUE}AI BACKEND${_C_NC}:
  ${_C_CYAN}em ai${_C_NC}              Show current AI backend
  ${_C_CYAN}em ai claude${_C_NC}       Switch to Claude
  ${_C_CYAN}em ai gemini${_C_NC}       Switch to Gemini
  ${_C_CYAN}em ai none${_C_NC}         Disable AI
  ${_C_CYAN}em ai toggle${_C_NC}       Cycle backends
  ${_C_CYAN}em ai auto${_C_NC}         Smart per-op routing

${_C_MAGENTA}CURRENT${_C_NC}: \$FLOW_EMAIL_AI=${_C_CYAN}${FLOW_EMAIL_AI}${_C_NC}  ${_C_DIM}Timeout: ${FLOW_EMAIL_AI_TIMEOUT}s${_C_NC}

${_C_MAGENTA}💡 TIP${_C_NC}: Use ${_C_CYAN}em pick${_C_NC} for fzf-powered email browsing with preview

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
    [[ "$1" == "--help" || "$1" == "-h" ]] && { _em_help; return 0; }
    _em_require_himalaya || return 1
    local msg_id="" fmt="plain" raw=false

    # Parse flags: em read [--html|--md|--raw] <ID>
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --html|-H) fmt="html"; shift ;;
            --md|-M)   fmt="md"; shift ;;
            --raw)     raw=true; shift ;;
            *)         msg_id="$1"; shift ;;
        esac
    done

    if [[ -z "$msg_id" ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em read [--html|--md|--raw] <ID>${_C_NC}"
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
        _em_validate_msg_id "$msg_id" || return 1
        envelope=$(_em_hml_list "$folder" 100 2>/dev/null \
            | jq -r --argjson id "$msg_id" '.[] | select(.id == $id)' 2>/dev/null)
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
        if [[ "$fmt" == "html" || "$fmt" == "md" ]]; then
            local html_body
            html_body=$(_em_hml_read "$msg_id" html "$folder")
            if [[ -n "$html_body" ]]; then
                if [[ "$fmt" == "md" ]]; then
                    _em_render_markdown "$html_body"
                else
                    _em_render "$html_body" "html"
                fi
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
    if [[ "$fmt" == "html" || "$fmt" == "md" ]]; then
        body=$(_em_hml_read "$msg_id" html "$folder")
        if [[ -z "$body" ]]; then
            # No HTML part — fall back to plain text
            _flow_log_warning "No HTML part — showing plain text"
            body=$(himalaya message read -f "$folder" "$msg_id" 2>/dev/null)
            if [[ -n "$body" ]]; then
                echo "$body" | _em_render_email_body
            fi
        elif [[ "$fmt" == "md" ]]; then
            _em_render_markdown "$body"
        else
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

# ═══════════════════════════════════════════════════════════════════
# TWO-PHASE SAFETY GATE (v2.0) — preview + confirm before send
# ═══════════════════════════════════════════════════════════════════

_em_compose_draft() {
    # Create temp draft file from to/subject/body
    # Args: $1=to, $2=subject, $3=body
    # Returns: path to temp file on stdout
    local to="$1" subject="$2" body="$3"
    local tmpfile
    tmpfile=$(mktemp "${TMPDIR:-/tmp}/em-draft-XXXXXX.eml")
    chmod 0600 "$tmpfile"

    {
        echo "To: $to"
        echo "Subject: $subject"
        echo ""
        [[ -n "$body" ]] && echo "$body"
    } > "$tmpfile"

    echo "$tmpfile"
}

_em_safety_gate() {
    # Two-phase preview + confirm before send
    # Args: $1=draft_file, $2=action_label (e.g., "Send" or "Reply")
    # Optional: $3=--force or --yes bypasses gate
    # Returns: 0=proceed, 1=error, 2=user-abort
    #
    # TOCTOU fix: read draft into variable BEFORE confirm, send from variable
    local draft_file="$1"
    local action_label="${2:-Send}"
    local force_flag="$3"

    if [[ ! -f "$draft_file" ]]; then
        _flow_log_error "Draft file not found: $draft_file"
        return 1
    fi

    # Read draft into variable BEFORE user interaction (TOCTOU fix)
    local draft_content
    draft_content=$(<"$draft_file")

    if [[ -z "$draft_content" ]]; then
        _flow_log_error "Draft file is empty"
        return 1
    fi

    # Force mode: skip preview/confirm
    if [[ "$force_flag" == "--force" || "$force_flag" == "--yes" ]]; then
        return 0
    fi

    # Parse header fields for preview
    local to_line subject_line body_text
    to_line=$(echo "$draft_content" | sed -n 's/^To: //p' | head -1)
    subject_line=$(echo "$draft_content" | sed -n 's/^Subject: //p' | head -1)
    body_text=$(echo "$draft_content" | awk '/^$/{found=1;next} found{print}')

    # Check for empty body
    if [[ -z "$body_text" || "$(echo "$body_text" | tr -d '[:space:]')" == "" ]]; then
        _flow_log_warning "Empty email body"
    fi

    # Phase 1: Preview
    echo ""
    echo -e "${_C_BOLD}${action_label} Preview${_C_NC}"
    echo -e "${_C_DIM}$(printf '%.0s─' {1..60})${_C_NC}"
    [[ -n "$to_line" ]] && echo -e "  ${_C_BLUE}To:${_C_NC}      $to_line"
    [[ -n "$subject_line" ]] && echo -e "  ${_C_BLUE}Subject:${_C_NC} $subject_line"
    echo ""
    if [[ -n "$body_text" ]]; then
        echo "$body_text" | head -15
        local total_lines
        total_lines=$(echo "$body_text" | wc -l | tr -d ' ')
        (( total_lines > 15 )) && echo -e "  ${_C_DIM}... ($((total_lines - 15)) more lines)${_C_NC}"
    fi
    echo -e "${_C_DIM}$(printf '%.0s─' {1..60})${_C_NC}"
    echo ""

    # Phase 2: Confirm [y/N/e]
    while true; do
        printf "  ${action_label}? [y/N/e] "
        local response
        read -r response
        case "$response" in
            [Yy]|[Yy]es)
                return 0
                ;;
            [Ee]|edit)
                # Re-open editor, then re-preview
                _em_open_in_editor "$draft_file"
                # Re-read after edit (content may have changed)
                draft_content=$(<"$draft_file")
                to_line=$(echo "$draft_content" | sed -n 's/^To: //p' | head -1)
                subject_line=$(echo "$draft_content" | sed -n 's/^Subject: //p' | head -1)
                body_text=$(echo "$draft_content" | awk '/^$/{found=1;next} found{print}')
                echo ""
                echo -e "${_C_BOLD}${action_label} Preview (updated)${_C_NC}"
                echo -e "${_C_DIM}$(printf '%.0s─' {1..60})${_C_NC}"
                [[ -n "$to_line" ]] && echo -e "  ${_C_BLUE}To:${_C_NC}      $to_line"
                [[ -n "$subject_line" ]] && echo -e "  ${_C_BLUE}Subject:${_C_NC} $subject_line"
                echo ""
                if [[ -n "$body_text" ]]; then
                    echo "$body_text" | head -15
                fi
                echo -e "${_C_DIM}$(printf '%.0s─' {1..60})${_C_NC}"
                echo ""
                ;;
            *)
                # Default is No — save draft and abort
                local draft_dir="${FLOW_DATA_DIR}/email-drafts"
                [[ -d "$draft_dir" ]] || mkdir -p "$draft_dir"
                local saved="${draft_dir}/draft-$(date +%Y%m%d-%H%M%S).eml"
                cp "$draft_file" "$saved"
                _flow_log_info "Draft saved: $saved"
                return 2
                ;;
        esac
    done
}

_em_draft_cleanup() {
    # Remove temp draft file
    # Args: $1=draft_file_path
    local draft_file="$1"
    [[ -n "$draft_file" && -f "$draft_file" ]] && rm -f "$draft_file"
}

_em_v2_migration_notice() {
    # One-time notice: "em v2.0 now previews emails before sending"
    # Tracked via ~/.config/flow/em-v2-notice-shown
    local notice_file="${HOME}/.config/flow/em-v2-notice-shown"
    [[ -f "$notice_file" ]] && return 0

    echo ""
    echo -e "  ${_C_MAGENTA}em v2.0${_C_NC}: Emails are now previewed before sending."
    echo -e "  ${_C_DIM}Use [y] to send, [e] to edit, [N] to cancel (default).${_C_NC}"
    echo -e "  ${_C_DIM}Pass --force or --yes to skip preview.${_C_NC}"
    echo ""

    mkdir -p "${notice_file:h}" 2>/dev/null
    touch "$notice_file"
}

_em_send() {
    _em_require_himalaya || return 1
    local to="" subject="" use_ai=false force_flag=""

    # Parse args: em send [--ai] [--force|--yes] [to] [subject]
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --ai) use_ai=true; shift ;;
            --force|--yes) force_flag="$1"; shift ;;
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

    # Show v2 migration notice (once)
    _em_v2_migration_notice

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
    draft_file=$(_em_compose_draft "$to" "$subject" "$ai_body")

    # Trap: clean up temp file on interrupt
    trap "_em_draft_cleanup '$draft_file'" INT TERM

    _em_open_in_editor "$draft_file"

    # [4] TWO-PHASE SAFETY GATE — preview + confirm
    local gate_result
    _em_safety_gate "$draft_file" "Send" "$force_flag"
    gate_result=$?

    if [[ $gate_result -eq 0 ]]; then
        # [5] Send via himalaya (read from file to avoid TOCTOU)
        himalaya message send < "$draft_file"
        if [[ $? -eq 0 ]]; then
            _flow_log_success "Email sent"
            _em_draft_cleanup "$draft_file"
        else
            _flow_log_error "Failed to send — draft preserved: $draft_file"
            trap - INT TERM
            return 1
        fi
    elif [[ $gate_result -eq 2 ]]; then
        _em_draft_cleanup "$draft_file"
        trap - INT TERM
        return 0  # user chose to cancel — not an error
    else
        _em_draft_cleanup "$draft_file"
        trap - INT TERM
        return 1  # actual error
    fi

    trap - INT TERM
    return 0
}

_em_reply() {
    [[ "$1" == "--help" || "$1" == "-h" ]] && { _em_help; return 0; }
    _em_require_himalaya || return 1
    local msg_id=""
    local skip_ai=false
    local reply_all=false
    local batch_mode=false
    local force_flag=""

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-ai)         skip_ai=true; shift ;;
            --all|-a)        reply_all=true; shift ;;
            --batch|-b)      batch_mode=true; shift ;;
            --force|--yes)   force_flag="$1"; shift ;;
            *)               msg_id="$1"; shift ;;
        esac
    done

    if [[ -z "$msg_id" ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em reply <ID>${_C_NC}  ${_C_DIM}(--no-ai --all --batch --force)${_C_NC}"
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

    # Write to temp file for safety gate
    local draft_file
    draft_file=$(mktemp "${TMPDIR:-/tmp}/em-reply-draft-XXXXXX.eml")
    chmod 0600 "$draft_file"
    echo "$mml_with_body" > "$draft_file"

    # Trap: clean up temp file on interrupt
    trap "_em_draft_cleanup '$draft_file'" INT TERM

    # Two-phase safety gate
    local gate_result
    _em_safety_gate "$draft_file" "Reply" "$force_flag"
    gate_result=$?

    if [[ $gate_result -eq 0 ]]; then
        # TOCTOU fix: read draft content before sending
        local send_content
        send_content=$(<"$draft_file")
        echo "$send_content" | _em_hml_template_send
        _em_cache_invalidate "$msg_id"
        _flow_log_success "Reply sent"
        _em_draft_cleanup "$draft_file"
    elif [[ $gate_result -eq 2 ]]; then
        _em_cache_set "drafts" "$msg_id" "$draft"
        _flow_log_info "Draft saved. Review with: ${_C_CYAN}em respond --review${_C_NC}"
        _em_draft_cleanup "$draft_file"
    else
        _em_draft_cleanup "$draft_file"
        trap - INT TERM
        return 1
    fi

    trap - INT TERM
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

    # Server-side IMAP SEARCH via adapter (much faster than client-side)
    local json
    json=$(_em_hml_search "$query" "$FLOW_EMAIL_FOLDER")

    # Fallback: if server-side search returns empty/error, try client-side
    if [[ -z "$json" || "$json" == "[]" || "$json" == "null" ]]; then
        _flow_log_warning "Server search returned no results — trying client-side filter"
        json=$(_em_hml_list "$FLOW_EMAIL_FOLDER" 100)
        json=$(echo "$json" | jq --arg q "$query" '
            [.[] | select(
                (.subject | ascii_downcase | contains($q | ascii_downcase)) or
                (.from.name // "" | ascii_downcase | contains($q | ascii_downcase)) or
                (.from.addr // "" | ascii_downcase | contains($q | ascii_downcase))
            )]' 2>/dev/null)
    fi

    if [[ -z "$json" || "$json" == "[]" || "$json" == "null" ]]; then
        echo ""
        echo -e "${_C_DIM}0 results${_C_NC}"
        return 0
    fi

    echo "$json" | jq -r '
        .[] | [.id, .from.name // .from.addr, .subject, (.date | split("T")[0] // .date)] | @tsv' \
        | column -t -s $'\t'

    local result_count
    result_count=$(echo "$json" | jq 'length' 2>/dev/null)
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
    _em_validate_msg_id "$msg_id" || return 1
    envelope=$(himalaya envelope list --page-size 100 --output json 2>/dev/null \
        | jq -r --argjson id "$msg_id" '.[] | select(.id == $id)' 2>/dev/null)

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
Tab=select  Enter=read  Ctrl-R=reply  Ctrl-S=summarize  Ctrl-T=catch
Ctrl-F=star  Ctrl-M=move  Ctrl-A=archive  Ctrl-D=delete  Ctrl-O=todo  Ctrl-E=event
• = unread  ★ = starred  + = attachment"

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

    # [3] Render list from cached JSON + launch fzf (multi-select enabled)
    local selected
    selected=$(jq -r '.[] | [
            .id,
            ([(if (.flags | contains(["Seen"])) then "" else "•" end),
              (if (.flags | contains(["Flagged"])) then "★" else "" end),
              (if .has_attachment then "+" else "" end)] | join("")),
            ((.from.name // .from.addr // "unknown") | if length > 20 then .[:17] + "..." else . end),
            ((.subject // "(no subject)") | if length > 50 then .[:47] + "..." else . end),
            (.date | split(" ")[0] // .date)
          ] | @tsv' "$cache_file" \
        | fzf --delimiter='\t' \
              --with-nth='2..' \
              --preview="$preview_script {1}" \
              --preview-window='right:60%:wrap' \
              --header="$header_line" \
              --header-lines=0 \
              --bind='ctrl-r:become(echo REPLY:{+1})' \
              --bind='ctrl-s:become(echo SUMMARIZE:{+1})' \
              --bind='ctrl-a:become(echo ARCHIVE:{+1})' \
              --bind='ctrl-d:become(echo DELETE:{+1})' \
              --bind='ctrl-t:become(echo CATCH:{+1})' \
              --bind='ctrl-f:become(echo STAR:{+1})' \
              --bind='ctrl-m:become(echo MOVE:{+1})' \
              --bind='ctrl-o:become(echo TODO:{+1})' \
              --bind='ctrl-e:become(echo EVENT:{+1})' \
              --multi \
              --ansi)

    # [4] Cleanup temp files
    rm -f "$cache_file" "$preview_script"

    # Handle selection
    if [[ -z "$selected" ]]; then
        return 0  # User pressed Escape
    fi

    # Extract action prefix and IDs
    local action="" first_line
    first_line=$(echo "$selected" | head -1)

    if [[ "$first_line" == *:* && "$first_line" =~ ^[A-Z]+: ]]; then
        # Action keybind: PREFIX:id1\nPREFIX:id2... or PREFIX:id1 id2...
        action="${first_line%%:*}"
        local raw_ids="${first_line#*:}"
        local -a pick_ids=()
        # IDs may be space-separated (fzf {+1} joins with spaces)
        local pid
        for pid in ${=raw_ids}; do
            pick_ids+=("$pid")
        done
    else
        # Plain Enter: extract IDs from tab-delimited lines
        local -a pick_ids=()
        while IFS=$'\t' read -r sel_id _rest; do
            [[ -n "$sel_id" ]] && pick_ids+=("$sel_id")
        done <<< "$selected"
        local sel_count=${#pick_ids[@]}

        if [[ $sel_count -eq 1 ]]; then
            # Single Enter = read
            _em_read "${pick_ids[1]}"
            return
        fi

        # Multi-select Enter: action menu (D4)
        echo ""
        echo -e "  ${_C_BOLD}${sel_count} emails selected:${_C_NC}"
        echo -e "    ${_C_CYAN}1.${_C_NC} Delete"
        echo -e "    ${_C_CYAN}2.${_C_NC} Move"
        echo -e "    ${_C_CYAN}3.${_C_NC} Flag"
        echo -e "    ${_C_CYAN}4.${_C_NC} Catch"
        echo -e "    ${_C_DIM}q. Cancel${_C_NC}"
        printf "  Choice: "
        local choice
        read -r choice
        case "$choice" in
            1) action="DELETE" ;;
            2) action="MOVE" ;;
            3) action="FLAG" ;;
            4) action="CATCH" ;;
            *) return 0 ;;
        esac
    fi

    # Route action to handler
    case "$action" in
        REPLY)
            _em_reply "${pick_ids[1]}"
            ;;
        SUMMARIZE)
            _em_summarize "${pick_ids[1]}"
            ;;
        ARCHIVE)
            local arc_id
            for arc_id in "${pick_ids[@]}"; do
                _em_hml_flags add "$arc_id" Seen
            done
            _flow_log_success "Archived ${#pick_ids[@]} email(s) (marked read)"
            ;;
        DELETE)
            _em_delete "${pick_ids[@]}"
            ;;
        CATCH)
            local cat_id
            for cat_id in "${pick_ids[@]}"; do
                _em_catch "$cat_id"
            done
            ;;
        TODO)
            _em_todo "${pick_ids[@]}"
            ;;
        EVENT)
            _em_event "${pick_ids[@]}"
            ;;
        FLAG)
            _em_flag "${pick_ids[@]}"
            ;;
        STAR)
            local star_id
            for star_id in "${pick_ids[@]}"; do
                _em_star "$star_id"
            done
            ;;
        MOVE)
            # Need target folder — use fzf picker
            if command -v fzf &>/dev/null; then
                local move_target
                move_target=$(_em_hml_folders 2>/dev/null | fzf --prompt="Move to: ")
                if [[ -n "$move_target" ]]; then
                    _em_hml_move "${FLOW_EMAIL_FOLDER:-INBOX}" "$move_target" "${pick_ids[@]}"
                    _flow_log_success "Moved ${#pick_ids[@]} email(s) to $move_target"
                fi
            else
                _flow_log_error "fzf required for folder selection"
            fi
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# AI FEATURES
# ═══════════════════════════════════════════════════════════════════

_em_classify() {
    [[ "$1" == "--help" || "$1" == "-h" ]] && { _em_help; return 0; }
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
    [[ "$1" == "--help" || "$1" == "-h" ]] && { _em_help; return 0; }
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


_em_catch() {
    _em_require_himalaya || return 1
    local msg_id="$1"

    if [[ -z "$msg_id" ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em catch <ID>${_C_NC}"
        return 1
    fi

    # Get email content
    local content
    content=$(_em_hml_read "$msg_id" plain 2>/dev/null)
    if [[ -z "$content" ]]; then
        _flow_log_error "Could not read email $msg_id"
        return 1
    fi

    # AI summarize (if available)
    local summary=""
    if [[ "${FLOW_EMAIL_AI:-claude}" != "none" ]]; then
        summary=$(_em_ai_query "summarize" "$(_em_ai_summarize_prompt)" \
            "$content" "" "$msg_id" 2>/dev/null)
    fi

    # Fallback to subject line if AI unavailable or failed
    if [[ -z "$summary" ]]; then
        if command -v jq &>/dev/null; then
            _em_validate_msg_id "$msg_id" || return 1
            summary=$(_em_hml_list "${FLOW_EMAIL_FOLDER:-INBOX}" 100 2>/dev/null \
                | jq -r --argjson id "$msg_id" '.[] | select(.id == $id) | .subject' 2>/dev/null)
        fi
    fi

    if [[ -z "$summary" ]]; then
        _flow_log_error "Could not generate summary for email $msg_id"
        return 1
    fi

    # Feed into catch command (if available)
    if typeset -f catch &>/dev/null; then
        catch "Email #$msg_id: $summary"
        _flow_log_success "Captured: $summary"
    else
        # Fallback: just display for manual capture
        echo -e "${_C_BOLD}Capture:${_C_NC} Email #$msg_id: $summary"
        echo -e "${_C_DIM}(catch command not available — copy manually)${_C_NC}"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# DELETE / MOVE / RESTORE
# ═══════════════════════════════════════════════════════════════════

_em_delete() {
    [[ "$1" == "--help" || "$1" == "-h" ]] && { _em_delete_help; return 0; }
    _em_require_himalaya || return 1

    local purge=false pick=false folder="" query=""
    local -a ids=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --purge)       purge=true; shift ;;
            --pick)        pick=true; shift ;;
            --folder|-f)   shift; folder="$1"; shift ;;
            --query|-q)    shift; query="$1"; shift ;;
            *)             ids+=("$1"); shift ;;
        esac
    done

    local src_folder="${FLOW_EMAIL_FOLDER:-INBOX}"
    local trash_folder="${FLOW_EMAIL_TRASH_FOLDER:-Trash}"

    # Mode: --pick (fzf multi-select)
    if [[ "$pick" == true ]]; then
        if ! command -v fzf &>/dev/null; then
            _flow_log_error "fzf required for --pick mode"
            return 1
        fi
        local cache_file
        cache_file=$(mktemp "${TMPDIR:-/tmp}/em-delpick-XXXXXX.json")
        _em_hml_list "$src_folder" 50 > "$cache_file" 2>/dev/null
        if [[ ! -s "$cache_file" ]]; then
            _flow_log_error "Could not fetch emails"
            rm -f "$cache_file"
            return 1
        fi
        local selected
        selected=$(jq -r '.[] | [.id, (.from.name // .from.addr // "unknown") | .[:20], (.subject // "(no subject)") | .[:50], (.date | split("T")[0])] | @tsv' "$cache_file" \
            | fzf --multi --delimiter='\t' --with-nth='2..' --header="Select emails to delete (Tab=toggle, Enter=confirm)")
        rm -f "$cache_file"
        [[ -z "$selected" ]] && return 0
        ids=()
        while IFS=$'\t' read -r sel_id _rest; do
            ids+=("$sel_id")
        done <<< "$selected"
        [[ ${#ids[@]} -eq 0 ]] && return 0
    fi

    # Mode: --folder (delete all in folder)
    if [[ -n "$folder" ]]; then
        local json count
        json=$(_em_hml_list "$folder" 500 2>/dev/null)
        count=$(echo "$json" | jq 'length' 2>/dev/null)
        if [[ -z "$count" || "$count" -eq 0 ]]; then
            _flow_log_info "No emails in $folder"
            return 0
        fi
        ids=()
        local i
        for (( i=0; i < count; i++ )); do
            ids+=($(echo "$json" | jq -r ".[$i].id"))
        done
        src_folder="$folder"
        if ! _em_delete_confirm "$count" "$json"; then
            return 0
        fi
        if [[ "$purge" == true ]]; then
            if ! _em_purge_confirm "$count"; then
                return 0
            fi
            local del_id
            for del_id in "${ids[@]}"; do
                _em_hml_flags add "$del_id" Deleted 2>/dev/null
            done
            _em_hml_expunge "$folder"
            _flow_log_success "Permanently purged $count emails from $folder"
            return 0
        fi
        _em_hml_delete "$src_folder" "${ids[@]}"
        _flow_log_success "Deleted $count emails from $folder (moved to $trash_folder)"
        return 0
    fi

    # Mode: --query (delete matching search results)
    if [[ -n "$query" ]]; then
        local json count
        json=$(_em_hml_search "$query" "$src_folder" 2>/dev/null)
        count=$(echo "$json" | jq 'length' 2>/dev/null)
        if [[ -z "$count" || "$count" -eq 0 ]]; then
            _flow_log_info "No emails matching: $query"
            return 0
        fi
        ids=()
        local i
        for (( i=0; i < count; i++ )); do
            ids+=($(echo "$json" | jq -r ".[$i].id"))
        done
        if ! _em_delete_confirm "$count" "$json"; then
            return 0
        fi
        _em_hml_delete "$src_folder" "${ids[@]}"
        _flow_log_success "Deleted $count matching emails (moved to $trash_folder)"
        return 0
    fi

    # Mode: single/batch by IDs
    if [[ ${#ids[@]} -eq 0 ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em delete <ID> [<ID>...]${_C_NC}"
        echo "       ${_C_CYAN}em delete --folder <FOLDER>${_C_NC}"
        echo "       ${_C_CYAN}em delete --query \"<SEARCH>\"${_C_NC}"
        echo "       ${_C_CYAN}em delete --pick${_C_NC}"
        return 1
    fi

    if [[ "$purge" == true ]]; then
        if ! _em_purge_confirm "${#ids[@]}"; then
            return 0
        fi
        local del_id
        for del_id in "${ids[@]}"; do
            _em_hml_flags add "$del_id" Deleted 2>/dev/null
        done
        _em_hml_expunge "$src_folder"
        _flow_log_success "Permanently purged ${#ids[@]} email(s)"
        return 0
    fi

    # Standard delete: confirm then move to Trash
    local count=${#ids[@]}
    printf "  Delete $count email(s)? [y/N] "
    local confirm
    read -r confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        _em_hml_delete "$src_folder" "${ids[@]}"
        _flow_log_success "Deleted $count email(s) (moved to $trash_folder)"
    else
        _flow_log_info "Cancelled"
    fi
}

_em_delete_confirm() {
    # Show count + first 5 subjects, prompt for confirmation
    # Args: count, json_array
    local count="$1" json="$2"
    echo ""
    echo -e "  ${_C_BOLD}Delete $count email(s)?${_C_NC}"
    local i subj
    local show=$(( count < 5 ? count : 5 ))
    for (( i=0; i < show; i++ )); do
        subj=$(echo "$json" | jq -r ".[$i].subject // \"(no subject)\"" 2>/dev/null)
        echo -e "    ${_C_DIM}$((i+1)). \"${subj:0:60}\"${_C_NC}"
    done
    if [[ $count -gt 5 ]]; then
        echo -e "    ${_C_DIM}... and $((count - 5)) more${_C_NC}"
    fi
    echo ""
    printf "  Confirm delete? [y/N] "
    local response
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

_em_purge_confirm() {
    # Permanent deletion requires typing full "yes"
    # Args: count
    local count="$1"
    echo ""
    echo -e "  ${_C_RED}${_C_BOLD}PERMANENT DELETE${_C_NC} — $count email(s) will be irrecoverable"
    printf "  Type 'yes' to confirm: "
    local response
    read -r response
    [[ "$response" == "yes" ]]
}

_em_delete_help() {
    echo -e "
${_C_BOLD}em delete${_C_NC} — Delete emails

${_C_CYAN}em delete <ID> [<ID>...]${_C_NC}       Move email(s) to Trash
${_C_CYAN}em delete --folder <FOLDER>${_C_NC}    Delete all in folder (confirms)
${_C_CYAN}em delete --query \"<SEARCH>\"${_C_NC}  Delete matching emails (confirms)
${_C_CYAN}em delete --pick${_C_NC}               Interactive fzf multi-select
${_C_CYAN}em delete --purge <ID>${_C_NC}         ${_C_RED}PERMANENT${_C_NC} delete (requires 'yes')
${_C_CYAN}em delete --folder X --purge${_C_NC}   ${_C_RED}PERMANENT${_C_NC} delete all in folder

${_C_DIM}Aliases: em del, em rm${_C_NC}
${_C_DIM}Safety: All deletes confirm [y/N]. --purge requires typing 'yes'.${_C_NC}
"
}

_em_move() {
    [[ "$1" == "--help" || "$1" == "-h" ]] && { _em_move_help; return 0; }
    _em_require_himalaya || return 1

    local src_folder="${FLOW_EMAIL_FOLDER:-INBOX}" pick=false target=""
    local -a ids=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --from)  shift; src_folder="$1"; shift ;;
            --pick)  pick=true; shift ;;
            *)
                if [[ -z "$target" ]]; then
                    target="$1"
                else
                    ids+=("$1")
                fi
                shift
                ;;
        esac
    done

    # --pick mode: fzf folder selection
    if [[ "$pick" == true ]]; then
        if ! command -v fzf &>/dev/null; then
            _flow_log_error "fzf required for --pick mode"
            return 1
        fi
        # IDs come after --pick (target is actually an ID in this mode)
        if [[ -n "$target" ]]; then
            ids=("$target" "${ids[@]}")
        fi
        if [[ ${#ids[@]} -eq 0 ]]; then
            _flow_log_error "Email ID required with --pick"
            echo "Usage: ${_C_CYAN}em move --pick <ID> [<ID>...]${_C_NC}"
            return 1
        fi
        local folder_list
        folder_list=$(_em_hml_folders 2>/dev/null)
        if [[ -z "$folder_list" ]]; then
            _flow_log_error "Could not list folders"
            return 1
        fi
        target=$(echo "$folder_list" | fzf --prompt="Move to: " --header="Select target folder")
        [[ -z "$target" ]] && return 0
    fi

    if [[ -z "$target" ]]; then
        _flow_log_error "Target folder required"
        echo "Usage: ${_C_CYAN}em move <FOLDER> <ID> [<ID>...]${_C_NC}"
        return 1
    fi
    if [[ ${#ids[@]} -eq 0 ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em move <FOLDER> <ID> [<ID>...]${_C_NC}"
        return 1
    fi

    _em_hml_move "$src_folder" "$target" "${ids[@]}"
    if [[ $? -eq 0 ]]; then
        _flow_log_success "Moved ${#ids[@]} email(s) to $target"
    else
        _flow_log_error "Move failed"
        return 1
    fi
}

_em_move_help() {
    echo -e "
${_C_BOLD}em move${_C_NC} — Move emails between folders

${_C_CYAN}em move <FOLDER> <ID> [<ID>...]${_C_NC}         Move email(s) to folder
${_C_CYAN}em move --from <SRC> <FOLDER> <ID>${_C_NC}      Move from non-default source
${_C_CYAN}em move --pick <ID> [<ID>...]${_C_NC}           fzf folder picker

${_C_DIM}Aliases: em mv${_C_NC}
${_C_DIM}Default source: \$FLOW_EMAIL_FOLDER (${FLOW_EMAIL_FOLDER:-INBOX})${_C_NC}
"
}

_em_restore() {
    [[ "$1" == "--help" || "$1" == "-h" ]] && { _em_restore_help; return 0; }
    _em_require_himalaya || return 1

    local target="INBOX"
    local -a ids=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --to) shift; target="$1"; shift ;;
            *)    ids+=("$1"); shift ;;
        esac
    done

    if [[ ${#ids[@]} -eq 0 ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em restore <ID> [<ID>...] [--to <FOLDER>]${_C_NC}"
        return 1
    fi

    local trash_folder="${FLOW_EMAIL_TRASH_FOLDER:-Trash}"
    _em_hml_move "$trash_folder" "$target" "${ids[@]}"
    if [[ $? -eq 0 ]]; then
        _flow_log_success "Restored ${#ids[@]} email(s) to $target"
    else
        _flow_log_error "Restore failed"
        return 1
    fi
}

_em_restore_help() {
    echo -e "
${_C_BOLD}em restore${_C_NC} — Restore emails from Trash

${_C_CYAN}em restore <ID> [<ID>...]${_C_NC}         Move from Trash to INBOX
${_C_CYAN}em restore <ID> --to <FOLDER>${_C_NC}     Move from Trash to specific folder

${_C_DIM}Source: \$FLOW_EMAIL_TRASH_FOLDER (${FLOW_EMAIL_TRASH_FOLDER:-Trash})${_C_NC}
"
}

# ═══════════════════════════════════════════════════════════════════
# FLAG / UNFLAG
# ═══════════════════════════════════════════════════════════════════

_em_flag() {
    _em_require_himalaya || return 1
    if [[ $# -eq 0 ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em flag <ID> [<ID>...]${_C_NC}"
        return 1
    fi

    local msg_id
    for msg_id in "$@"; do
        _em_hml_flags add "$msg_id" Flagged
        _flow_log_success "Flagged email #$msg_id"
    done
}

_em_unflag() {
    _em_require_himalaya || return 1
    if [[ $# -eq 0 ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em unflag <ID> [<ID>...]${_C_NC}"
        return 1
    fi

    local msg_id
    for msg_id in "$@"; do
        _em_hml_flags remove "$msg_id" Flagged
        _flow_log_success "Unflagged email #$msg_id"
    done
}

# ═══════════════════════════════════════════════════════════════════
# TODO / EVENT (AI extraction + macOS integration)
# ═══════════════════════════════════════════════════════════════════

_em_todo() {
    _em_require_himalaya || return 1
    if [[ $# -eq 0 ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em todo <ID> [<ID>...]${_C_NC}"
        return 1
    fi

    local msg_id
    for msg_id in "$@"; do
        local content
        content=$(_em_hml_read "$msg_id" plain 2>/dev/null)
        if [[ -z "$content" ]]; then
            _flow_log_error "Could not read email #$msg_id"
            continue
        fi

        # AI extract action items
        local items=""
        if [[ "${FLOW_EMAIL_AI:-claude}" != "none" ]]; then
            items=$(_em_ai_query "todo" "$(_em_ai_todo_prompt)" \
                "$content" "" "$msg_id" 2>/dev/null)
        fi

        # Fallback to subject line
        if [[ -z "$items" || "$items" == "NONE" ]]; then
            local subj=""
            if command -v jq &>/dev/null; then
                _em_validate_msg_id "$msg_id" || continue
                subj=$(_em_hml_list "${FLOW_EMAIL_FOLDER:-INBOX}" 100 2>/dev/null \
                    | jq -r --argjson id "$msg_id" '.[] | select(.id == $id) | .subject' 2>/dev/null)
            fi
            if [[ -n "$subj" ]]; then
                items="Follow up on: $subj"
            else
                _flow_log_warning "No action items found in email #$msg_id"
                continue
            fi
        fi

        # Display extracted items
        echo ""
        echo -e "  ${_C_BOLD}Action items from email #$msg_id:${_C_NC}"
        local line_num=0
        while IFS= read -r item; do
            [[ -z "$item" ]] && continue
            (( line_num++ ))
            echo -e "    ${_C_CYAN}$line_num.${_C_NC} $item"

            # Feed into catch command
            if typeset -f catch &>/dev/null; then
                catch "Email #$msg_id: $item"
            fi
        done <<< "$items"

        # Reminders.app prompt (macOS only)
        if [[ "$(uname)" == "Darwin" ]]; then
            echo ""
            printf "  Add to Reminders.app? [y/N] "
            local response
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                while IFS= read -r item; do
                    [[ -z "$item" ]] && continue
                    _em_create_reminder "$item"
                done <<< "$items"
                _flow_log_success "Added to Reminders.app"
            fi
        fi
    done
}

_em_event() {
    _em_require_himalaya || return 1
    if [[ $# -eq 0 ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em event <ID> [<ID>...]${_C_NC}"
        return 1
    fi

    local msg_id
    for msg_id in "$@"; do
        local content
        content=$(_em_hml_read "$msg_id" plain 2>/dev/null)
        if [[ -z "$content" ]]; then
            _flow_log_error "Could not read email #$msg_id"
            continue
        fi

        # AI extract events
        local result=""
        if [[ "${FLOW_EMAIL_AI:-claude}" != "none" ]]; then
            result=$(_em_ai_query "schedule" "$(_em_ai_schedule_prompt)" \
                "$content" "" "$msg_id" 2>/dev/null)
        fi

        if [[ -z "$result" ]]; then
            _flow_log_warning "Could not extract events from email #$msg_id"
            continue
        fi

        # Parse events JSON
        local event_count
        event_count=$(echo "$result" | jq '.events | length' 2>/dev/null)
        if [[ -z "$event_count" || "$event_count" -eq 0 ]]; then
            _flow_log_info "No events found in email #$msg_id"
            continue
        fi

        echo ""
        echo -e "  ${_C_BOLD}Events from email #$msg_id:${_C_NC}"
        local i title edate etime duration location etype
        for (( i=0; i < event_count; i++ )); do
            title=$(echo "$result" | jq -r ".events[$i].title // \"(untitled)\"" 2>/dev/null)
            edate=$(echo "$result" | jq -r ".events[$i].date // \"TBD\"" 2>/dev/null)
            etime=$(echo "$result" | jq -r ".events[$i].time // \"\"" 2>/dev/null)
            duration=$(echo "$result" | jq -r ".events[$i].duration_minutes // \"\"" 2>/dev/null)
            location=$(echo "$result" | jq -r ".events[$i].location // \"\"" 2>/dev/null)
            etype=$(echo "$result" | jq -r ".events[$i].type // \"event\"" 2>/dev/null)

            echo -e "    ${_C_CYAN}$((i+1)).${_C_NC} ${_C_BOLD}$title${_C_NC}"
            echo -e "       ${_C_DIM}Date: $edate${etime:+  Time: $etime}${duration:+  ($duration min)}${_C_NC}"
            [[ -n "$location" && "$location" != "null" ]] && echo -e "       ${_C_DIM}Location: $location${_C_NC}"
            echo -e "       ${_C_DIM}Type: $etype${_C_NC}"

            # Feed into catch command
            if typeset -f catch &>/dev/null; then
                catch "Email #$msg_id: $title on $edate${etime:+ at $etime}"
            fi
        done

        # Calendar.app prompt (macOS only)
        if [[ "$(uname)" == "Darwin" ]]; then
            echo ""
            printf "  Add to Calendar.app? [y/N] "
            local response
            read -r response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                for (( i=0; i < event_count; i++ )); do
                    title=$(echo "$result" | jq -r ".events[$i].title // \"(untitled)\"" 2>/dev/null)
                    edate=$(echo "$result" | jq -r ".events[$i].date // \"\"" 2>/dev/null)
                    etime=$(echo "$result" | jq -r ".events[$i].time // \"09:00\"" 2>/dev/null)
                    duration=$(echo "$result" | jq -r ".events[$i].duration_minutes // 60" 2>/dev/null)
                    location=$(echo "$result" | jq -r ".events[$i].location // \"\"" 2>/dev/null)
                    _em_create_calendar_event "$title" "$edate" "$etime" "$duration" "$location"
                done
                _flow_log_success "Added to Calendar.app"
            fi
        fi
    done
}

# ═══════════════════════════════════════════════════════════════════
# macOS INTEGRATION HELPERS
# ═══════════════════════════════════════════════════════════════════

_em_create_reminder() {
    # Create a reminder in macOS Reminders.app (default list)
    # Args: title
    local title="${1//\"/\'}"
    [[ "$(uname)" != "Darwin" ]] && return 1
    osascript -e "tell application \"Reminders\" to make new reminder with properties {name:\"$title\"}" 2>/dev/null
}

_em_create_calendar_event() {
    # Create an event in macOS Calendar.app (default calendar)
    # Args: title, date (YYYY-MM-DD), time (HH:MM), duration_minutes, location
    local title="${1//\"/\'}" edate="$2" etime="${3:-09:00}" duration="${4:-60}" location="${5//\"/\'}"
    [[ "$(uname)" != "Darwin" ]] && return 1

    # Convert YYYY-MM-DD + HH:MM to AppleScript date string
    local month day year hour minute
    year="${edate%%-*}"
    local rest="${edate#*-}"
    month="${rest%%-*}"
    day="${rest#*-}"
    hour="${etime%%:*}"
    minute="${etime#*:}"

    local end_minute=$(( (10#$hour * 60 + 10#$minute + duration) % 1440 ))
    local end_hour=$(( end_minute / 60 ))
    end_minute=$(( end_minute % 60 ))

    osascript <<APPLESCRIPT 2>/dev/null
tell application "Calendar"
    set startDate to current date
    set year of startDate to $year
    set month of startDate to $month
    set day of startDate to $day
    set hours of startDate to $hour
    set minutes of startDate to $minute
    set seconds of startDate to 0
    set endDate to current date
    set year of endDate to $year
    set month of endDate to $month
    set day of endDate to $day
    set hours of endDate to $end_hour
    set minutes of endDate to $end_minute
    set seconds of endDate to 0
    tell (first calendar whose name is not missing value)
        make new event with properties {summary:"$title", start date:startDate, end date:endDate, location:"$location"}
    end tell
end tell
APPLESCRIPT
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
# ORGANIZE — star, move, thread, snooze, digest
# ═══════════════════════════════════════════════════════════════════

_em_star() {
    _em_require_himalaya || return 1
    local msg_id="$1"
    if [[ -z "$msg_id" ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em star <ID>${_C_NC}"
        return 1
    fi

    local folder="${FLOW_EMAIL_FOLDER:-INBOX}"

    # Check current flags to determine toggle direction
    local flags
    flags=$(_em_hml_list "$folder" 100 2>/dev/null \
        | jq -r --arg id "$msg_id" '.[] | select(.id == ($id | tonumber)) | .flags | join(",")' 2>/dev/null)

    if [[ "$flags" == *"Flagged"* ]]; then
        _em_hml_flags remove "$msg_id" Flagged
        echo -e "  ${_C_DIM}☆${_C_NC} Unstarred #${msg_id}"
    else
        _em_hml_flags add "$msg_id" Flagged
        echo -e "  ${_C_YELLOW}★${_C_NC} Starred #${msg_id}"
    fi
}

_em_starred() {
    _em_require_himalaya || return 1
    local folder="${1:-INBOX}"

    echo -e "${_C_BOLD}★ Starred emails${_C_NC} ${_C_DIM}(${folder})${_C_NC}"
    echo -e "${_C_DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_C_NC}"

    local json
    json=$(_em_hml_list "$folder" 100 2>/dev/null \
        | jq '[.[] | select(.flags | contains(["Flagged"]))]' 2>/dev/null)

    if [[ -z "$json" || "$json" == "[]" || "$json" == "null" ]]; then
        echo -e "  ${_C_DIM}No starred emails${_C_NC}"
        return 0
    fi

    echo "$json" | _em_render_inbox_json

    local count
    count=$(echo "$json" | jq 'length' 2>/dev/null)
    echo -e "\n  ${_C_DIM}${count:-0} starred${_C_NC}"
}

_em_move() {
    _em_require_himalaya || return 1
    local msg_id="$1" target_folder="$2"

    if [[ -z "$msg_id" ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em move <ID> [folder]${_C_NC}"
        return 1
    fi

    local folder="${FLOW_EMAIL_FOLDER:-INBOX}"

    # No folder specified → fzf picker
    if [[ -z "$target_folder" ]]; then
        if ! command -v fzf &>/dev/null; then
            _flow_log_error "Folder required (fzf not available for picker)"
            echo "Usage: ${_C_CYAN}em move <ID> <folder>${_C_NC}"
            return 1
        fi

        target_folder=$(_em_hml_folders 2>/dev/null \
            | fzf --prompt="Move #${msg_id} to > " --height=15 --no-multi \
            | awk '{print $1}')

        if [[ -z "$target_folder" ]]; then
            return 0  # User cancelled
        fi
    fi

    # Safety: confirm before moving
    printf "  Move #%s to %b%s%b? [y/N] " "$msg_id" "${_C_CYAN}" "$target_folder" "${_C_NC}"
    local confirm
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        _flow_log_info "Cancelled"
        return 0
    fi

    if _em_hml_move "$msg_id" "$target_folder" "$folder"; then
        _flow_log_success "Moved #${msg_id} → ${target_folder}"
    else
        _flow_log_error "Failed to move #${msg_id}"
        return 1
    fi
}

_em_thread() {
    _em_require_himalaya || return 1
    local msg_id="$1"
    if [[ -z "$msg_id" ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em thread <ID>${_C_NC}"
        return 1
    fi

    local folder="${FLOW_EMAIL_FOLDER:-INBOX}"

    # Get headers of the target message
    local headers
    headers=$(_em_hml_headers "$msg_id" "$folder")
    if [[ -z "$headers" ]]; then
        _flow_log_error "Could not read headers for #${msg_id}"
        return 1
    fi

    # Extract threading headers (unfold RFC 822 continuation lines)
    local unfolded
    unfolded=$(echo "$headers" | awk '
        /^[^ \t]/ { if (line) print line; line=$0; next }
        /^[ \t]/  { line=line " " substr($0, 2); next }
        END       { if (line) print line }
    ')
    local message_id in_reply_to references
    message_id=$(echo "$unfolded" | grep -i '^Message-ID:' | head -1 | sed 's/^[^:]*: *//; s/\r$//')
    in_reply_to=$(echo "$unfolded" | grep -i '^In-Reply-To:' | head -1 | sed 's/^[^:]*: *//; s/\r$//')
    references=$(echo "$unfolded" | grep -i '^References:' | head -1 | sed 's/^[^:]*: *//; s/\r$//')

    # Build search set: all Message-IDs from References + current + In-Reply-To
    local -a thread_ids=()
    if [[ -n "$references" ]]; then
        # References contains space-separated Message-IDs
        local ref
        for ref in ${(z)references}; do
            thread_ids+=("$ref")
        done
    fi
    [[ -n "$in_reply_to" ]] && thread_ids+=("$in_reply_to")
    [[ -n "$message_id" ]] && thread_ids+=("$message_id")

    # Remove duplicates
    thread_ids=(${(u)thread_ids})

    if [[ ${#thread_ids[@]} -le 1 ]]; then
        echo -e "  ${_C_DIM}No thread found — this appears to be a standalone message${_C_NC}"
        return 0
    fi

    echo -e "${_C_BOLD}Thread for #${msg_id}${_C_NC}"
    echo -e "${_C_DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_C_NC}"

    # Fetch all envelopes and match by subject similarity (fallback)
    # Since IMAP search by Message-ID is unreliable, we search by subject
    local subject
    subject=$(echo "$unfolded" | grep -i '^Subject:' | head -1 | sed 's/^[^:]*: *//; s/\r$//')
    # Strip Re:/Fwd: prefixes for search
    local base_subject="${subject}"
    base_subject="${base_subject#Re: }"
    base_subject="${base_subject#RE: }"
    base_subject="${base_subject#Fwd: }"
    base_subject="${base_subject#FW: }"

    local json
    json=$(_em_hml_search "$base_subject" "$folder" 2>/dev/null)

    # Filter search results to match exact subject (IMAP keyword search is broad)
    if [[ -n "$json" && "$json" != "[]" ]]; then
        json=$(echo "$json" | jq --arg subj "$base_subject" '
            [.[] | select(.subject | ascii_downcase | contains($subj | ascii_downcase))]' 2>/dev/null)
    fi

    if [[ -z "$json" || "$json" == "[]" ]]; then
        # Fallback: list recent and filter
        json=$(_em_hml_list "$folder" 100 2>/dev/null \
            | jq --arg subj "$base_subject" '
                [.[] | select(.subject | ascii_downcase | contains($subj | ascii_downcase))]' 2>/dev/null)
    fi

    if [[ -z "$json" || "$json" == "[]" ]]; then
        echo -e "  ${_C_DIM}Could not find related messages${_C_NC}"
        return 0
    fi

    # Display thread as chronological list with current message highlighted
    echo "$json" | jq -r '
        sort_by(.date) | .[] |
        [.id, .from.name // .from.addr // "unknown", .subject // "(no subject)", (.date | split(" ")[0] // .date)] | join("|")' \
    | while IFS='|' read -r tid tfrom tsubj tdate; do
        if [[ "$tid" == "$msg_id" ]]; then
            echo -e "  ${_C_YELLOW}→${_C_NC} ${_C_BOLD}#${tid}${_C_NC}  ${tfrom}  ${_C_DIM}${tdate}${_C_NC}"
            echo -e "    ${_C_BOLD}${tsubj}${_C_NC}"
        else
            echo -e "    ${_C_DIM}#${tid}${_C_NC}  ${tfrom}  ${_C_DIM}${tdate}${_C_NC}"
            echo -e "    ${_C_DIM}${tsubj}${_C_NC}"
        fi
    done

    local thread_count
    thread_count=$(echo "$json" | jq 'length' 2>/dev/null)
    echo -e "\n  ${_C_DIM}${thread_count:-0} messages in thread${_C_NC}"
}

_em_snooze() {
    _em_require_himalaya || return 1
    local msg_id="$1" time_spec="$2"

    if [[ -z "$msg_id" ]]; then
        _flow_log_error "Email ID and time required"
        echo "Usage: ${_C_CYAN}em snooze <ID> <time>${_C_NC}"
        echo "  Times: ${_C_DIM}2h, 4h, tomorrow, monday, 1d, 3d${_C_NC}"
        return 1
    fi

    if [[ -z "$time_spec" ]]; then
        _flow_log_error "Snooze time required"
        echo "  Times: ${_C_DIM}2h, 4h, tomorrow, monday, 1d, 3d${_C_NC}"
        return 1
    fi

    # Parse time spec → epoch timestamp
    local wake_epoch
    wake_epoch=$(_em_snooze_parse_time "$time_spec")
    if [[ -z "$wake_epoch" || "$wake_epoch" == "0" ]]; then
        _flow_log_error "Could not parse time: $time_spec"
        echo "  Valid: ${_C_DIM}2h, 4h, tomorrow, monday, tuesday, 1d, 3d, 1w${_C_NC}"
        return 1
    fi

    local folder="${FLOW_EMAIL_FOLDER:-INBOX}"
    local wake_display
    wake_display=$(date -r "$wake_epoch" "+%Y-%m-%d %H:%M" 2>/dev/null)

    # Get subject for display
    local subject
    _em_validate_msg_id "$msg_id" || return 1
    subject=$(_em_hml_list "$folder" 100 2>/dev/null \
        | jq -r --argjson id "$msg_id" '.[] | select(.id == $id) | .subject // "(no subject)"' 2>/dev/null)

    # Ensure snooze directory exists
    local snooze_dir="${HOME}/.flow/email-snooze"
    [[ -d "$snooze_dir" ]] || mkdir -p "$snooze_dir"

    local pending_file="${snooze_dir}/pending.json"

    # Initialize file if needed
    [[ -f "$pending_file" ]] || echo '[]' > "$pending_file"

    # Add snooze entry
    local now_epoch
    now_epoch=$(date +%s)
    local tmp_file="${pending_file}.tmp"
    jq --arg id "$msg_id" \
       --arg subject "$subject" \
       --arg folder "$folder" \
       --argjson wake "$wake_epoch" \
       --argjson created "$now_epoch" \
       --arg time_spec "$time_spec" \
       '. + [{id: $id, subject: $subject, folder: $folder, wake: $wake, created: $created, time_spec: $time_spec}]' \
       "$pending_file" > "$tmp_file" && mv "$tmp_file" "$pending_file"

    # Move to Snoozed folder (best effort — folder may not exist)
    _em_hml_move "$msg_id" "Snoozed" "$folder" 2>/dev/null

    echo -e "  ${_C_MAGENTA}💤${_C_NC} Snoozed #${msg_id} until ${_C_CYAN}${wake_display}${_C_NC}"
    [[ -n "$subject" ]] && echo -e "  ${_C_DIM}${subject}${_C_NC}"

    # Schedule notification (if terminal-notifier available)
    if command -v terminal-notifier &>/dev/null; then
        local delay=$(( wake_epoch - now_epoch ))
        if (( delay > 0 )); then
            (sleep "$delay" && terminal-notifier \
                -title "Email Reminder" \
                -message "Snoozed: ${subject:-#${msg_id}}" \
                -sound default) &>/dev/null &
            disown
        fi
    fi
}

_em_snoozed() {
    local snooze_dir="${HOME}/.flow/email-snooze"
    local pending_file="${snooze_dir}/pending.json"

    if [[ ! -f "$pending_file" ]]; then
        echo -e "  ${_C_DIM}No snoozed emails${_C_NC}"
        return 0
    fi

    local count
    count=$(jq 'length' "$pending_file" 2>/dev/null)

    if [[ -z "$count" || "$count" == "0" ]]; then
        echo -e "  ${_C_DIM}No snoozed emails${_C_NC}"
        return 0
    fi

    echo -e "${_C_BOLD}💤 Snoozed emails${_C_NC}"
    echo -e "${_C_DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_C_NC}"

    local now_epoch
    now_epoch=$(date +%s)

    local wake_display
    jq -r '.[] | [.id, .subject // "(no subject)", (.wake | tostring), .time_spec] | join("|")' "$pending_file" \
    | while IFS='|' read -r sid ssubj swake stime; do
        wake_display=$(date -r "$swake" "+%Y-%m-%d %H:%M" 2>/dev/null)
        if (( swake <= now_epoch )); then
            echo -e "  ${_C_YELLOW}⏰${_C_NC} #${sid}  ${_C_BOLD}READY${_C_NC}  ${_C_DIM}${ssubj:0:40}${_C_NC}"
        else
            echo -e "  ${_C_MAGENTA}💤${_C_NC} #${sid}  ${wake_display}  ${_C_DIM}${ssubj:0:40}${_C_NC}"
        fi
    done

    echo -e "\n  ${_C_DIM}${count} snoozed${_C_NC}"
}

_em_digest() {
    _em_require_himalaya || return 1
    local period="today" count=50
    local folder="${FLOW_EMAIL_FOLDER:-INBOX}"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --week|-w)   period="week"; shift ;;
            --all|-a)    period="all"; shift ;;
            -n)          shift; count="$1"; shift ;;
            *)           shift ;;
        esac
    done

    echo -e "${_C_BOLD}em digest${_C_NC} ${_C_DIM}— ${period}'s email summary${_C_NC}"
    echo -e "${_C_DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_C_NC}"

    # Fetch emails
    local json
    json=$(_em_hml_list "$folder" "$count" 2>/dev/null)

    if [[ -z "$json" || "$json" == "[]" ]]; then
        echo -e "  ${_C_DIM}No emails in ${folder}${_C_NC}"
        return 0
    fi

    # Filter by date if needed
    local today_str week_ago_str
    today_str=$(date "+%Y-%m-%d")
    week_ago_str=$(date -v-7d "+%Y-%m-%d" 2>/dev/null)

    if [[ "$period" == "today" ]]; then
        json=$(echo "$json" | jq --arg today "$today_str" \
            '[.[] | select(.date | split(" ")[0] == $today)]' 2>/dev/null)
    elif [[ "$period" == "week" ]]; then
        json=$(echo "$json" | jq --arg since "$week_ago_str" \
            '[.[] | select(.date | split(" ")[0] >= $since)]' 2>/dev/null)
    fi

    local total
    total=$(echo "$json" | jq 'length' 2>/dev/null)

    if [[ -z "$total" || "$total" == "0" ]]; then
        echo -e "  ${_C_GREEN}No emails ${period}${_C_NC}"
        return 0
    fi

    # If AI is available, do AI-powered grouping
    if [[ "${FLOW_EMAIL_AI:-claude}" != "none" ]]; then
        # Build a summary of all emails for batch classification
        local email_list
        email_list=$(echo "$json" | jq -r '.[] | "#\(.id) | \(.from.name // .from.addr) | \(.subject // "(no subject)")"')

        local ai_result
        ai_result=$(_em_ai_query "classify" \
            "Group these emails into exactly 3 categories. Output ONLY the grouping, no commentary.
Format each group as:
ACTION REQUIRED:
- #ID Subject
FYI:
- #ID Subject
LOW PRIORITY:
- #ID Subject

If a category is empty, omit it." \
            "$email_list" 2>/dev/null)

        if [[ -n "$ai_result" ]]; then
            echo ""
            echo "$ai_result" | while IFS= read -r line; do
                case "$line" in
                    ACTION*)    echo -e "${_C_RED}${_C_BOLD}${line}${_C_NC}" ;;
                    FYI*)       echo -e "${_C_YELLOW}${_C_BOLD}${line}${_C_NC}" ;;
                    LOW*)       echo -e "${_C_DIM}${_C_BOLD}${line}${_C_NC}" ;;
                    -*)         echo -e "  ${line}" ;;
                    *)          echo -e "  ${line}" ;;
                esac
            done
            echo ""
            echo -e "${_C_DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_C_NC}"
            echo -e "  ${_C_DIM}${total} emails ${period}${_C_NC}"
            return 0
        fi
    fi

    # Fallback: simple unread/read grouping (no AI)
    local unread_json read_json
    unread_json=$(echo "$json" | jq '[.[] | select(.flags | contains(["Seen"]) | not)]' 2>/dev/null)
    read_json=$(echo "$json" | jq '[.[] | select(.flags | contains(["Seen"]))]' 2>/dev/null)

    local unread_count read_count
    unread_count=$(echo "$unread_json" | jq 'length' 2>/dev/null)
    read_count=$(echo "$read_json" | jq 'length' 2>/dev/null)

    if [[ "${unread_count:-0}" -gt 0 ]]; then
        echo ""
        echo -e "${_C_YELLOW}${_C_BOLD}UNREAD (${unread_count}):${_C_NC}"
        echo "$unread_json" | jq -r '.[] |
            "  - #\(.id) \(.from.name // .from.addr // "?") — \(.subject // "(no subject)")"' 2>/dev/null
    fi

    if [[ "${read_count:-0}" -gt 0 ]]; then
        echo ""
        echo -e "${_C_DIM}${_C_BOLD}READ (${read_count}):${_C_NC}"
        echo "$read_json" | jq -r '.[] |
            "  - #\(.id) \(.from.name // .from.addr // "?") — \(.subject // "(no subject)")"' 2>/dev/null
    fi

    echo ""
    echo -e "${_C_DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_C_NC}"
    echo -e "  ${_C_DIM}${total} emails ${period} (${unread_count:-0} unread)${_C_NC}"
}

_em_snooze_parse_time() {
    # Parse human-friendly time spec → epoch timestamp
    # Supports: Nh (hours), Nd (days), Nw (weeks), tomorrow, monday-sunday
    local spec="${(L)1}"  # lowercase
    local now_epoch
    now_epoch=$(date +%s)

    case "$spec" in
        tomorrow)
            # Tomorrow at 9am (must be before *w glob — "tomorrow" ends in 'w')
            date -v+1d -v9H -v0M -v0S +%s 2>/dev/null
            ;;
        monday|tuesday|wednesday|thursday|friday|saturday|sunday)
            # Next occurrence of that day at 9am
            local -A day_map=(monday 1 tuesday 2 wednesday 3 thursday 4 friday 5 saturday 6 sunday 7)
            local target_dow="${day_map[$spec]}"
            local current_dow
            current_dow=$(date +%u)
            local days_ahead=$(( (target_dow - current_dow + 7) % 7 ))
            (( days_ahead == 0 )) && days_ahead=7  # Next week if today
            date -v+${days_ahead}d -v9H -v0M -v0S +%s 2>/dev/null
            ;;
        *h)
            local hours="${spec%h}"
            echo $(( now_epoch + hours * 3600 ))
            ;;
        *d)
            local days="${spec%d}"
            echo $(( now_epoch + days * 86400 ))
            ;;
        *w)
            local weeks="${spec%w}"
            echo $(( now_epoch + weeks * 604800 ))
            ;;
        *)
            echo "0"
            ;;
    esac
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

    # Background maintenance: prune expired cache entries
    _em_cache_prune &>/dev/null &
    # Cache warming (opt-in via config)
    [[ "$FLOW_EMAIL_CACHE_WARM" == "true" ]] && _em_cache_warm 10 &>/dev/null &
}

_em_folders() {
    _em_require_himalaya || return 1
    _em_hml_folders
}

# ═══════════════════════════════════════════════════════════════════
# UTILITIES
# ═══════════════════════════════════════════════════════════════════

_em_html() {
    [[ "$1" == "--help" || "$1" == "-h" ]] && { _em_help; return 0; }
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
    [[ "$1" == "--help" || "$1" == "-h" ]] && { _em_help; return 0; }
    _em_require_himalaya || return 1

    # Subcommand dispatch
    case "$1" in
        list|ls)   shift; _em_attach_list "$@" ;;
        get|dl)    shift; _em_attach_get "$@" ;;
        *)
            # Default: download all attachments (legacy behavior)
            local msg_id="$1"
            if [[ -z "$msg_id" ]]; then
                _flow_log_error "Email ID required"
                echo "Usage: ${_C_CYAN}em attach <ID>${_C_NC}           Download all"
                echo "       ${_C_CYAN}em attach list <ID>${_C_NC}      List attachments"
                echo "       ${_C_CYAN}em attach get <ID> <file>${_C_NC} Download specific file"
                return 1
            fi

            _em_validate_msg_id "$msg_id" || return 1

            local download_dir="${2:-${HOME}/Downloads}"
            [[ -d "$download_dir" ]] || mkdir -p "$download_dir"

            _flow_log_info "Downloading attachments from email #${msg_id}..."
            _em_hml_attachments "$msg_id" "$download_dir"
            if [[ $? -eq 0 ]]; then
                _flow_log_success "Attachments saved to: $download_dir"
            else
                _flow_log_error "No attachments or download failed"
            fi
            ;;
    esac
}

_em_attach_list() {
    # em attach list <ID> — show table: filename, MIME type, size
    local msg_id="$1"
    if [[ -z "$msg_id" ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em attach list <ID>${_C_NC}"
        return 1
    fi

    _em_validate_msg_id "$msg_id" || return 1

    local json
    json=$(_em_hml_attachment_list "$msg_id")

    if [[ -z "$json" || "$json" == "[]" || "$json" == "null" ]]; then
        echo -e "  ${_C_DIM}No attachments on email #${msg_id}${_C_NC}"
        return 0
    fi

    echo -e "${_C_BOLD}Attachments for email #${msg_id}${_C_NC}"
    echo -e "${_C_DIM}$(printf '%.0s─' {1..60})${_C_NC}"

    if command -v jq &>/dev/null; then
        # Structured JSON output (himalaya 1.2+)
        echo "$json" | jq -r '.[] | [.filename // "(unnamed)", .mime_type // "unknown", (.size // 0 | tostring)] | @tsv' 2>/dev/null \
        | while IFS=$'\t' read -r fname mime size; do
            # Human-readable size
            local hr_size="$size B"
            (( size > 1024 )) && hr_size="$(( size / 1024 )) KB"
            (( size > 1048576 )) && hr_size="$(( size / 1048576 )) MB"
            printf "  ${_C_CYAN}%-30s${_C_NC} %-25s %s\n" "$fname" "$mime" "$hr_size"
        done
    else
        # Plain text fallback
        echo "$json"
    fi
}

_em_attach_get() {
    # em attach get <ID> <filename> [dir]
    # Download specific attachment by filename
    local msg_id="$1"
    local filename="$2"
    local out_dir="${3:-${HOME}/Downloads}"

    if [[ -z "$msg_id" || -z "$filename" ]]; then
        _flow_log_error "Email ID and filename required"
        echo "Usage: ${_C_CYAN}em attach get <ID> <filename> [dir]${_C_NC}"
        return 1
    fi

    _em_validate_msg_id "$msg_id" || return 1

    # Path traversal protection: strip directory components and control chars
    local safe_filename="${filename##*/}"           # strip directory components
    safe_filename="${safe_filename//[^[:print:]]/}"  # strip control chars
    safe_filename="${safe_filename//\.\./}"           # strip ..

    if [[ -z "$safe_filename" ]]; then
        _flow_log_error "Invalid filename after sanitization"
        return 1
    fi

    [[ -d "$out_dir" ]] || mkdir -p "$out_dir"

    # Verify output dir containment (realpath check)
    local resolved_dir
    resolved_dir=$(cd "$out_dir" 2>/dev/null && pwd -P)
    local target_path="${resolved_dir}/${safe_filename}"

    # Download all, then check if the file appeared
    _flow_log_info "Downloading '$safe_filename' from email #${msg_id}..."
    _em_hml_attachment_download "$msg_id" "$safe_filename" "$resolved_dir"

    if [[ -f "$target_path" ]]; then
        _flow_log_success "Saved: $target_path"
    else
        _flow_log_error "File '$safe_filename' not found in attachments"
        echo "Use ${_C_CYAN}em attach list ${msg_id}${_C_NC} to see available files"
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════════
# FOLDER CRUD (v2.0)
# ═══════════════════════════════════════════════════════════════════

_em_create_folder() {
    _em_require_himalaya || return 1
    local name="$1"
    if [[ -z "$name" ]]; then
        _flow_log_error "Folder name required"
        echo "Usage: ${_C_CYAN}em create-folder <name>${_C_NC}"
        return 1
    fi

    # Validate folder name (Wave 1 adapter security check)
    _em_validate_folder_name "$name" || return 1

    if _em_hml_folder_create "$name"; then
        _flow_log_success "Folder created: $name"
    else
        _flow_log_error "Failed to create folder: $name"
        return 1
    fi
}

_em_delete_folder() {
    _em_require_himalaya || return 1
    local name="$1"
    if [[ -z "$name" ]]; then
        _flow_log_error "Folder name required"
        echo "Usage: ${_C_CYAN}em delete-folder <name>${_C_NC}"
        return 1
    fi

    # Validate folder name
    _em_validate_folder_name "$name" || return 1

    # Type-to-confirm: user must type exact folder name
    echo -e "  ${_C_RED}Warning:${_C_NC} This will permanently delete folder ${_C_BOLD}${name}${_C_NC} and all its contents."
    printf "  Type folder name to confirm deletion: "
    local confirmation
    read -r confirmation

    if [[ "$confirmation" != "$name" ]]; then
        _flow_log_info "Deletion cancelled (name did not match)"
        return 2
    fi

    if _em_hml_folder_delete "$name"; then
        _flow_log_success "Folder deleted: $name"
    else
        _flow_log_error "Failed to delete folder: $name"
        return 1
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
    # Extra args
    local _gemini_extra="${_EM_AI_BACKENDS[gemini_extra_args]:-}"
    if [[ -n "$_gemini_extra" ]]; then
        echo -e "  Gemini args: ${_C_CYAN}${_gemini_extra}${_C_NC}"
    fi
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
