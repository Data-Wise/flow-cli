#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# ICS (iCalendar) Parser — Pure ZSH RFC 5545 VEVENT extraction
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         lib/em-ics.zsh
# Version:      0.1
# Date:         2026-02-26
#
# Used by:      lib/dispatchers/email-dispatcher.zsh (em calendar <ID>)
# Backend:      Pure ZSH parser with optional Python icalendar fallback
#
# Design:       Parse ICS attachments from email messages. Extracts VEVENT
#               blocks, formats datetime values, and optionally creates
#               Apple Calendar events via osascript.
#
# Security:     1MB file limit, 10-event cap, field sanitization,
#               no heredoc interpolation in osascript.
#
# ══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════
# CONSTANTS
# ═══════════════════════════════════════════════════════════════════

_EM_ICS_MAX_SIZE=1048576   # 1MB
_EM_ICS_MAX_EVENTS=10

# ═══════════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════════

_em_calendar_help() {
    echo -e "${_C_BOLD}em calendar${_C_NC} — Parse ICS calendar events from email"
    echo ""
    echo -e "  ${_C_CYAN}em calendar <message-id>${_C_NC}   Extract and display ICS events"
    echo ""
    echo -e "${_C_DIM}Downloads .ics attachment, parses VEVENT blocks, and optionally${_C_NC}"
    echo -e "${_C_DIM}adds events to Apple Calendar via osascript.${_C_NC}"
}

em_calendar() {
    # Parse and display ICS calendar event(s) from an email attachment
    # Args: $1 - message ID or 'help'
    local msg_id="$1"

    # Help text
    if [[ "$msg_id" == "help" || "$msg_id" == "--help" || "$msg_id" == "-h" ]]; then
        _em_calendar_help
        return 0
    fi

    if [[ -z "$msg_id" ]]; then
        _flow_log_error "Usage: em calendar <message-id>"
        return 1
    fi

    local ics_file
    ics_file=$(_em_ics_extract_from_msg "$msg_id") || return 1

    # Try Python enhanced parser first, fall back to pure ZSH
    if command -v python3 &>/dev/null && python3 -c "import icalendar" 2>/dev/null; then
        _em_ics_parse_enhanced "$ics_file"
    else
        _em_ics_parse "$ics_file"
    fi
    local rc=$?

    rm -f "$ics_file" 2>/dev/null
    return $rc
}

# ═══════════════════════════════════════════════════════════════════
# ICS EXTRACTION
# ═══════════════════════════════════════════════════════════════════

_em_ics_extract_from_msg() {
    # Download ICS attachment from email to temp file
    # Args: $1 - message ID
    # Stdout: path to temp ICS file
    local msg_id="$1"
    local tmpdir="${TMPDIR:-/tmp}"
    local ics_file="${tmpdir}/flow-em-ics-${msg_id}-$$.ics"

    # Download attachments via himalaya adapter
    if ! _em_hml_attachment_download "$msg_id" "$tmpdir" 2>/dev/null; then
        _flow_log_error "Failed to download attachments for message $msg_id"
        return 1
    fi

    # Find the .ics file among downloaded attachments
    local found=""
    for f in "${tmpdir}"/flow-em-att-${msg_id}-*/*.ics "${tmpdir}"/*.ics; do
        [[ -f "$f" ]] && found="$f" && break
    done

    if [[ -z "$found" ]]; then
        _flow_log_error "No .ics attachment found in message $msg_id"
        return 1
    fi

    # Security: file size check
    local fsize
    fsize=$(stat -f %z "$found" 2>/dev/null || echo 0)
    if (( fsize > _EM_ICS_MAX_SIZE )); then
        _flow_log_error "ICS file exceeds 1MB limit (${fsize} bytes)"
        rm -f "$found" 2>/dev/null
        return 1
    fi

    echo "$found"
}

# ═══════════════════════════════════════════════════════════════════
# PURE ZSH PARSER
# ═══════════════════════════════════════════════════════════════════

_em_ics_parse() {
    # Parse VEVENT blocks from ICS file (pure ZSH, RFC 5545)
    # Args: $1 - path to .ics file
    local ics_file="$1"
    [[ -f "$ics_file" ]] || { _flow_log_error "ICS file not found: $ics_file"; return 1; }

    local in_vevent=0 event_count=0
    local line prev_line="" unfolded=""
    typeset -A event

    # Unfold continuation lines (RFC 5545 sec 3.1) then parse
    local -a lines=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Strip trailing CR
        line="${line%$'\r'}"
        # Continuation line: starts with space or tab
        if [[ "$line" == [[:blank:]]* && ${#lines[@]} -gt 0 ]]; then
            lines[-1]+="${line#?}"
        else
            lines+=("$line")
        fi
    done < "$ics_file"

    for line in "${lines[@]}"; do
        case "$line" in
            BEGIN:VEVENT)
                in_vevent=1
                event=()
                ;;
            END:VEVENT)
                if (( in_vevent )); then
                    (( event_count++ ))
                    if (( event_count > _EM_ICS_MAX_EVENTS )); then
                        _flow_log_warning "Stopped after $_EM_ICS_MAX_EVENTS events (limit reached)"
                        break
                    fi
                    _em_ics_display_event event
                    in_vevent=0
                fi
                ;;
            *)
                if (( in_vevent )); then
                    local key="${line%%:*}" val="${line#*:}"
                    # Strip parameters (e.g., DTSTART;TZID=...:value)
                    key="${key%%;*}"
                    case "$key" in
                        SUMMARY)     event[summary]="$val" ;;
                        DTSTART)     event[dtstart]="$val" ;;
                        DTEND)       event[dtend]="$val" ;;
                        LOCATION)    event[location]="$val" ;;
                        DESCRIPTION) event[description]="$val" ;;
                        ORGANIZER)   event[organizer]="$val" ;;
                    esac
                fi
                ;;
        esac
    done

    if (( event_count == 0 )); then
        _flow_log_warning "No VEVENT blocks found in ICS file"
        return 1
    fi
    _flow_log_info "$event_count event(s) parsed"
}

# ═══════════════════════════════════════════════════════════════════
# PYTHON ENHANCED PARSER
# ═══════════════════════════════════════════════════════════════════

_em_ics_parse_enhanced() {
    # Parse ICS using Python icalendar library (handles recurrence, timezones)
    # Args: $1 - path to .ics file
    local ics_file="$1"
    local event_count=0

    local json_output
    json_output=$(python3 -c "
import json, sys
from icalendar import Calendar
with open(sys.argv[1], 'rb') as f:
    cal = Calendar.from_ical(f.read())
events = []
for comp in cal.walk():
    if comp.name == 'VEVENT':
        events.append({
            'summary': str(comp.get('summary', '')),
            'dtstart': str(comp.get('dtstart').dt) if comp.get('dtstart') else '',
            'dtend': str(comp.get('dtend').dt) if comp.get('dtend') else '',
            'location': str(comp.get('location', '')),
            'description': str(comp.get('description', ''))[:500],
            'organizer': str(comp.get('organizer', ''))
        })
        if len(events) >= ${_EM_ICS_MAX_EVENTS}:
            break
print(json.dumps(events))
" "$ics_file" 2>/dev/null)

    if [[ $? -ne 0 || -z "$json_output" ]]; then
        _flow_log_warning "Python parser failed, falling back to ZSH parser"
        _em_ics_parse "$ics_file"
        return $?
    fi

    # Parse JSON events and display
    typeset -A event
    local i=0
    while IFS= read -r line; do
        case "$line" in
            *\"summary\":*)  event[summary]="${${line#*: \"}%\"*}" ;;
            *\"dtstart\":*)  event[dtstart]="${${line#*: \"}%\"*}" ;;
            *\"dtend\":*)    event[dtend]="${${line#*: \"}%\"*}" ;;
            *\"location\":*) event[location]="${${line#*: \"}%\"*}" ;;
            *\"organizer\":*) event[organizer]="${${line#*: \"}%\"*}" ;;
            *\}*)
                if [[ -n "${event[summary]}" ]]; then
                    (( event_count++ ))
                    _em_ics_display_event event
                    event=()
                fi
                ;;
        esac
    done <<< "$json_output"

    (( event_count > 0 )) && _flow_log_info "$event_count event(s) parsed (enhanced)"
}

# ═══════════════════════════════════════════════════════════════════
# DATETIME FORMATTING
# ═══════════════════════════════════════════════════════════════════

_em_ics_format_dt() {
    # Format ICS datetime to human-readable
    # Input:  20260226T140000Z or 20260226T140000 or 2026-02-26 14:00:00
    # Output: 2026-02-26 14:00
    local raw="$1"
    # Already formatted (from Python parser)
    if [[ "$raw" == *-*-*\ *:* ]]; then
        echo "${raw%:*}"  # Trim seconds
        return
    fi
    # Strip trailing Z
    raw="${raw%Z}"
    # YYYYMMDDTHHMMSS → YYYY-MM-DD HH:MM
    if [[ "$raw" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})T([0-9]{2})([0-9]{2}) ]]; then
        echo "${match[1]}-${match[2]}-${match[3]} ${match[4]}:${match[5]}"
    else
        echo "$raw"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# DISPLAY
# ═══════════════════════════════════════════════════════════════════

_em_ics_display_event() {
    # Display a parsed event with colors
    # Args: $1 - name of associative array
    local -n ev="$1" 2>/dev/null || return

    local start end
    start=$(_em_ics_format_dt "${ev[dtstart]}")
    end=$(_em_ics_format_dt "${ev[dtend]}")

    echo ""
    echo "${FLOW_COLORS[header]}  Calendar Event${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[muted]}  ──────────────────────────────────${FLOW_COLORS[reset]}"
    [[ -n "${ev[summary]}" ]]     && echo "  ${FLOW_COLORS[bold]}${ev[summary]}${FLOW_COLORS[reset]}"
    [[ -n "$start" ]]             && echo "  ${FLOW_COLORS[info]}Start:${FLOW_COLORS[reset]}    $start"
    [[ -n "$end" ]]               && echo "  ${FLOW_COLORS[info]}End:${FLOW_COLORS[reset]}      $end"
    [[ -n "${ev[location]}" ]]    && echo "  ${FLOW_COLORS[info]}Location:${FLOW_COLORS[reset]} ${ev[location]}"
    [[ -n "${ev[organizer]}" ]]   && echo "  ${FLOW_COLORS[info]}From:${FLOW_COLORS[reset]}     ${ev[organizer]#mailto:}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════
# APPLE CALENDAR INTEGRATION
# ═══════════════════════════════════════════════════════════════════

_em_ics_create_event() {
    # Create Apple Calendar event via osascript
    # Args: $1=summary, $2=start datetime, $3=end datetime, $4=location (optional)
    local summary="$1" start_dt="$2" end_dt="$3" location="${4:-}"

    if [[ -z "$summary" || -z "$start_dt" || -z "$end_dt" ]]; then
        _flow_log_error "Usage: _em_ics_create_event <summary> <start> <end> [location]"
        return 1
    fi

    # Security: sanitize all fields (printable chars only)
    summary="${summary//[^[:print:]]/}"
    start_dt="${start_dt//[^[:print:]]/}"
    end_dt="${end_dt//[^[:print:]]/}"
    location="${location//[^[:print:]]/}"

    # Confirm before creating
    echo "Create calendar event:"
    echo "  ${FLOW_COLORS[bold]}$summary${FLOW_COLORS[reset]}"
    echo "  $start_dt - $end_dt"
    [[ -n "$location" ]] && echo "  Location: $location"
    echo ""
    printf "Add to Apple Calendar? [y/N] "
    local confirm
    read -r confirm
    [[ "$confirm" != [yY] ]] && { _flow_log_info "Cancelled"; return 0; }

    # Use 'on run argv' to pass data as arguments (prevents injection)
    osascript - "$summary" "$start_dt" "$end_dt" "$location" <<'APPLESCRIPT' 2>/dev/null
on run argv
    set eventSummary to item 1 of argv
    set eventStart to item 2 of argv
    set eventEnd to item 3 of argv
    set eventLocation to item 4 of argv
    tell application "Calendar"
        tell calendar "Calendar"
            set newEvent to make new event with properties {summary:eventSummary, start date:date eventStart, end date:date eventEnd}
            if eventLocation is not "" then
                set location of newEvent to eventLocation
            end if
        end tell
    end tell
end run
APPLESCRIPT

    if [[ $? -eq 0 ]]; then
        _flow_log_success "Event created in Apple Calendar"
    else
        _flow_log_error "Failed to create calendar event"
        return 1
    fi
}
