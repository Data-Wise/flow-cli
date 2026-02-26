#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# Email Watch — IMAP IDLE background watcher with desktop notifications
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         lib/em-watch.zsh
# Version:      0.1
# Date:         2026-02-26
#
# Used by:      lib/dispatchers/email-dispatcher.zsh (em watch <cmd>)
# Backend:      himalaya envelope watch (IMAP IDLE)
# Notify:       terminal-notifier (macOS)
#
# Design:       Background process watches IMAP folder via himalaya IDLE.
#               New envelopes trigger macOS notifications. Single-instance
#               enforced via PID file. Rate-limited to 1 notification / 10s.
#
# Status:       EXPERIMENTAL — API may change
#
# Security:     Subject sanitized (no control chars, 100-char truncation).
#               Never uses -execute flag. Static notification title.
#               PID file mode 0600.
#
# ══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════
# CONSTANTS & PATHS
# ═══════════════════════════════════════════════════════════════════

_EM_WATCH_STATE_DIR="${FLOW_STATE_DIR:-$HOME/.flow}"
_EM_WATCH_PID_FILE="${_EM_WATCH_STATE_DIR}/em-watch.pid"
_EM_WATCH_LOG_FILE="${_EM_WATCH_STATE_DIR}/em-watch.log"
_EM_WATCH_RATE_LIMIT=10    # seconds between notifications
_EM_WATCH_SUBJECT_MAX=100  # max subject length in notification

# ═══════════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════════

em_watch() {
    # Subcommand dispatch for email watcher
    # Usage: em watch [start|stop|status|log|help]
    local subcmd="${1:-status}"
    shift 2>/dev/null

    case "$subcmd" in
        start)  _em_watch_start "$@" ;;
        stop)   _em_watch_stop ;;
        status) _em_watch_status ;;
        log)    _em_watch_log ;;
        help|--help|-h) _em_watch_help ;;
        *)
            _flow_log_error "Unknown watch command: $subcmd"
            _em_watch_help
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# START / STOP
# ═══════════════════════════════════════════════════════════════════

_em_watch_start() {
    # Start background IMAP IDLE watcher
    # Args: $1 - folder (default: INBOX)
    local folder="${1:-INBOX}"

    # Dependency check: terminal-notifier
    if ! command -v terminal-notifier &>/dev/null; then
        _flow_log_error "terminal-notifier not found"
        echo "Install: ${_C_CYAN:-\033[36m}brew install terminal-notifier${_C_NC:-\033[0m}"
        return 1
    fi

    # Dependency check: himalaya
    if ! command -v himalaya &>/dev/null; then
        _flow_log_error "himalaya not found"
        return 1
    fi

    # Single-instance guard
    if _em_watch_is_running; then
        _flow_log_warning "Watch already running (PID $(cat "$_EM_WATCH_PID_FILE" 2>/dev/null))"
        _em_watch_status
        return 0
    fi

    # Ensure state directory exists
    mkdir -p "$_EM_WATCH_STATE_DIR" 2>/dev/null

    _flow_log_info "Starting email watcher on folder: $folder"

    # Launch background watcher
    (
        local last_notify=0

        # Log startup
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] STARTED watching $folder (PID $$)" >> "$_EM_WATCH_LOG_FILE"

        himalaya envelope watch --folder "$folder" 2>/dev/null | while IFS= read -r line; do
            _em_watch_handle_line "$line" "$last_notify"
            # Update last notify time if notification was sent
            local now
            now=$(date +%s)
            if (( now - last_notify >= _EM_WATCH_RATE_LIMIT )); then
                last_notify=$now
            fi
        done

        # Log shutdown
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] STOPPED (envelope watch exited)" >> "$_EM_WATCH_LOG_FILE"
        rm -f "$_EM_WATCH_PID_FILE" 2>/dev/null
    ) &!

    local bg_pid=$!

    # Write PID file (mode 0600)
    echo "$bg_pid" > "$_EM_WATCH_PID_FILE"
    chmod 0600 "$_EM_WATCH_PID_FILE"

    # Record folder being watched
    echo "$folder" > "${_EM_WATCH_STATE_DIR}/em-watch.folder"

    _flow_log_success "Watcher started (PID $bg_pid, folder: $folder)"
    echo "${FLOW_COLORS[muted]}  Stop: ${FLOW_COLORS[reset]}em watch stop"
    echo "${FLOW_COLORS[muted]}  Logs: ${FLOW_COLORS[reset]}em watch log"
}

_em_watch_stop() {
    # Stop the background watcher via PID file
    if ! _em_watch_is_running; then
        _flow_log_info "No watcher is running"
        return 0
    fi

    local pid
    pid=$(cat "$_EM_WATCH_PID_FILE" 2>/dev/null)
    if [[ -n "$pid" ]]; then
        kill "$pid" 2>/dev/null
        # Wait briefly for clean shutdown
        local tries=0
        while kill -0 "$pid" 2>/dev/null && (( tries < 5 )); do
            sleep 0.2
            (( tries++ ))
        done
        # Force kill if still alive
        kill -0 "$pid" 2>/dev/null && kill -9 "$pid" 2>/dev/null
    fi

    rm -f "$_EM_WATCH_PID_FILE" 2>/dev/null
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] STOPPED by user" >> "$_EM_WATCH_LOG_FILE"
    _flow_log_success "Watcher stopped"
}

# ═══════════════════════════════════════════════════════════════════
# STATUS & MONITORING
# ═══════════════════════════════════════════════════════════════════

_em_watch_is_running() {
    # Check if watcher process is alive
    # Returns: 0 if running, 1 if not
    [[ -f "$_EM_WATCH_PID_FILE" ]] || return 1
    local pid
    pid=$(cat "$_EM_WATCH_PID_FILE" 2>/dev/null)
    [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

_em_watch_status() {
    # Display watcher status
    if _em_watch_is_running; then
        local pid folder
        pid=$(cat "$_EM_WATCH_PID_FILE" 2>/dev/null)
        folder=$(cat "${_EM_WATCH_STATE_DIR}/em-watch.folder" 2>/dev/null || echo "unknown")
        echo ""
        echo "${FLOW_COLORS[success]}  Email watcher: RUNNING${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[muted]}  ──────────────────────────────────${FLOW_COLORS[reset]}"
        echo "  PID:    $pid"
        echo "  Folder: $folder"
        echo "  Log:    $_EM_WATCH_LOG_FILE"
        echo ""
    else
        echo ""
        echo "${FLOW_COLORS[warning]}  Email watcher: STOPPED${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[muted]}  Start: ${FLOW_COLORS[reset]}em watch start [folder]"
        echo ""
        # Cleanup stale PID file
        [[ -f "$_EM_WATCH_PID_FILE" ]] && rm -f "$_EM_WATCH_PID_FILE" 2>/dev/null
    fi
}

_em_watch_log() {
    # Show last 20 log entries
    if [[ ! -f "$_EM_WATCH_LOG_FILE" ]]; then
        _flow_log_info "No watch log found"
        return 0
    fi
    echo ""
    echo "${FLOW_COLORS[header]}  Watch Log (last 20 entries)${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[muted]}  ──────────────────────────────────${FLOW_COLORS[reset]}"
    tail -20 "$_EM_WATCH_LOG_FILE" | while IFS= read -r logline; do
        echo "  $logline"
    done
    echo ""
}

# ═══════════════════════════════════════════════════════════════════
# LINE HANDLER & NOTIFICATION
# ═══════════════════════════════════════════════════════════════════

_em_watch_handle_line() {
    # Parse an envelope line from himalaya watch and trigger notification
    # Args: $1 - raw line, $2 - last notification timestamp
    local line="$1" last_notify="${2:-0}"

    # Skip empty lines and status messages
    [[ -z "$line" || "$line" == "Watching"* || "$line" == "Connected"* ]] && return 0

    local now
    now=$(date +%s)

    # Rate limit: max 1 notification per _EM_WATCH_RATE_LIMIT seconds
    if (( now - last_notify < _EM_WATCH_RATE_LIMIT )); then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] RATE-LIMITED: $line" >> "$_EM_WATCH_LOG_FILE"
        return 0
    fi

    # Extract subject from envelope line
    # himalaya watch output varies; extract what looks like a subject
    local safe_subject="$line"

    # Security: strip control characters and newlines
    safe_subject="${safe_subject//[$'\x00'-$'\x1f']/}"
    safe_subject="${safe_subject//[$'\x7f']/}"

    # Truncate to max length
    if (( ${#safe_subject} > _EM_WATCH_SUBJECT_MAX )); then
        safe_subject="${safe_subject:0:$_EM_WATCH_SUBJECT_MAX}..."
    fi

    # Sanitize: printable characters only
    safe_subject="${safe_subject//[^[:print:]]/}"

    # Log the event
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] NEW: $safe_subject" >> "$_EM_WATCH_LOG_FILE"

    # Send notification — NEVER use -execute flag (RCE prevention)
    # Static -title (never from email content)
    terminal-notifier \
        -title "New Email" \
        -message "$safe_subject" \
        -group "flow-em-watch" \
        -sound default \
        2>/dev/null
}

# ═══════════════════════════════════════════════════════════════════
# DOCTOR INTEGRATION
# ═══════════════════════════════════════════════════════════════════

_em_watch_doctor() {
    # Check for orphaned watch processes (called by em doctor)
    # Returns: 0 if clean, 1 if orphan found
    if [[ -f "$_EM_WATCH_PID_FILE" ]]; then
        local pid
        pid=$(cat "$_EM_WATCH_PID_FILE" 2>/dev/null)
        if [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then
            _flow_log_warning "Orphaned watch PID file (process $pid not running)"
            echo "  Clean up: rm $_EM_WATCH_PID_FILE"
            return 1
        fi
    fi
    return 0
}

# ═══════════════════════════════════════════════════════════════════
# HELP
# ═══════════════════════════════════════════════════════════════════

_em_watch_help() {
    local _C_NC='\033[0m' _C_BOLD='\033[1m' _C_DIM='\033[2m'
    local _C_CYAN='\033[36m' _C_YELLOW='\033[33m'

    echo ""
    echo "${_C_BOLD}em watch${_C_NC} — Background email watcher ${_C_YELLOW}[experimental]${_C_NC}"
    echo "${_C_DIM}──────────────────────────────────────${_C_NC}"
    echo ""
    echo "${_C_BOLD}Usage:${_C_NC} em watch <command>"
    echo ""
    echo "${_C_BOLD}Commands:${_C_NC}"
    echo "  ${_C_CYAN}start${_C_NC} [folder]   Start watching (default: INBOX)"
    echo "  ${_C_CYAN}stop${_C_NC}             Stop the watcher"
    echo "  ${_C_CYAN}status${_C_NC}           Show watcher status"
    echo "  ${_C_CYAN}log${_C_NC}              Show recent log entries"
    echo ""
    echo "${_C_BOLD}Requirements:${_C_NC}"
    echo "  ${_C_CYAN}terminal-notifier${_C_NC}  brew install terminal-notifier"
    echo "  ${_C_CYAN}himalaya${_C_NC}           brew install himalaya"
    echo ""
    echo "${_C_BOLD}Notes:${_C_NC}"
    echo "  ${_C_DIM}Single instance — only one watcher at a time${_C_NC}"
    echo "  ${_C_DIM}Survives shell exit (backgrounded with disown)${_C_NC}"
    echo "  ${_C_DIM}Rate-limited: max 1 notification per ${_EM_WATCH_RATE_LIMIT}s${_C_NC}"
    echo ""
}
