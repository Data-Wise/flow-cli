# commands/timer.zsh - ADHD-friendly timer commands
# Pomodoro, focus timers, and break reminders

# ============================================================================
# TIMER COMMAND
# ============================================================================

timer() {
  local cmd="${1:-status}"
  shift 2>/dev/null
  
  case "$cmd" in
    -h|--help|help) _flow_timer_help ;;
    start|focus)    _flow_timer_focus "$@" ;;
    break|brk)      _flow_timer_break "$@" ;;
    stop)           _flow_timer_stop ;;
    status|st)      _flow_timer_status ;;
    pomodoro|pom)   _flow_timer_pomodoro "$@" ;;
    *)              
      # If first arg is a number, treat as focus timer
      if [[ "$cmd" =~ ^[0-9]+$ ]]; then
        _flow_timer_focus "$cmd" "$@"
      else
        _flow_timer_help
      fi
      ;;
  esac
}

# ============================================================================
# FOCUS TIMER
# ============================================================================

_flow_timer_focus() {
  local duration="${1:-25}"
  local label="${2:-Focus session}"
  
  echo ""
  echo "${FLOW_COLORS[header]}🎯 FOCUS MODE${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[muted]}$label - $duration minutes${FLOW_COLORS[reset]}"
  echo ""
  
  # Save timer state
  local timer_file="${FLOW_DATA_DIR}/timer.state"
  local end_time=$((EPOCHSECONDS + duration * 60))
  echo "type=focus" > "$timer_file"
  echo "end=$end_time" >> "$timer_file"
  echo "label=$label" >> "$timer_file"
  
  # Leave breadcrumb
  if _flow_in_project; then
    _flow_crumb "Started $duration min focus: $label"
  fi
  
  # Countdown
  local seconds=$((duration * 60))
  while (( seconds > 0 )); do
    printf "\r  ⏱️  %d:%02d " $((seconds / 60)) $((seconds % 60))
    _flow_timer_progress_mini $seconds $((duration * 60))
    sleep 1
    ((seconds--))
    
    # Check for interrupt
    if [[ ! -f "$timer_file" ]]; then
      echo ""
      echo "  ${FLOW_COLORS[warning]}Timer stopped${FLOW_COLORS[reset]}"
      return 1
    fi
  done
  
  rm -f "$timer_file"
  
  echo ""
  echo ""
  echo "  ${FLOW_COLORS[success]}✓ Focus session complete!${FLOW_COLORS[reset]}"
  
  # Notification (macOS)
  if command -v osascript &>/dev/null; then
    osascript -e "display notification \"$label complete!\" with title \"Focus Timer\" sound name \"Glass\""
  fi
  
  # Prompt for break
  echo ""
  echo "  ${FLOW_COLORS[muted]}Take a break? (y/n)${FLOW_COLORS[reset]}"
  read -k1 response
  if [[ "$response" == "y" ]]; then
    echo ""
    _flow_timer_break
  fi
}

# ============================================================================
# BREAK TIMER
# ============================================================================

_flow_timer_break() {
  local duration="${1:-5}"
  
  echo ""
  echo "${FLOW_COLORS[info]}☕ BREAK TIME${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[muted]}$duration minutes - stretch, hydrate, move${FLOW_COLORS[reset]}"
  echo ""
  
  # Save timer state
  local timer_file="${FLOW_DATA_DIR}/timer.state"
  local end_time=$((EPOCHSECONDS + duration * 60))
  echo "type=break" > "$timer_file"
  echo "end=$end_time" >> "$timer_file"
  
  # Countdown
  local seconds=$((duration * 60))
  while (( seconds > 0 )); do
    printf "\r  ☕ %d:%02d remaining  " $((seconds / 60)) $((seconds % 60))
    sleep 1
    ((seconds--))
    
    if [[ ! -f "$timer_file" ]]; then
      echo ""
      return 1
    fi
  done
  
  rm -f "$timer_file"
  
  echo ""
  echo ""
  echo "  ${FLOW_COLORS[success]}Break over! Ready to focus?${FLOW_COLORS[reset]}"
  
  # Notification
  if command -v osascript &>/dev/null; then
    osascript -e "display notification \"Break over - time to focus!\" with title \"Break Timer\" sound name \"Ping\""
  fi
}

# ============================================================================
# POMODORO CYCLE
# ============================================================================

_flow_timer_pomodoro() {
  local cycles="${1:-4}"
  local focus_min="${2:-25}"
  local break_min="${3:-5}"
  local long_break="${4:-15}"
  
  echo ""
  echo "${FLOW_COLORS[header]}🍅 POMODORO${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[muted]}$cycles cycles: ${focus_min}m focus, ${break_min}m break${FLOW_COLORS[reset]}"
  echo ""
  
  local cycle=1
  while (( cycle <= cycles )); do
    echo "${FLOW_COLORS[accent]}━━━ Cycle $cycle of $cycles ━━━${FLOW_COLORS[reset]}"
    echo ""
    
    # Focus
    _flow_timer_focus "$focus_min" "Pomodoro $cycle"
    
    # Break (long break after 4 cycles)
    if (( cycle == cycles )); then
      echo ""
      echo "  🎉 ${FLOW_COLORS[success]}All $cycles pomodoros complete!${FLOW_COLORS[reset]}"
      echo "  Take a long break ($long_break min)"
      _flow_timer_break "$long_break"
    elif (( cycle % 4 == 0 )); then
      echo "  Long break time!"
      _flow_timer_break "$long_break"
    else
      _flow_timer_break "$break_min"
    fi
    
    ((cycle++))
  done
}

# ============================================================================
# TIMER CONTROL
# ============================================================================

_flow_timer_stop() {
  local timer_file="${FLOW_DATA_DIR}/timer.state"
  
  if [[ -f "$timer_file" ]]; then
    rm -f "$timer_file"
    echo "  ${FLOW_COLORS[warning]}Timer stopped${FLOW_COLORS[reset]}"
  else
    echo "  No active timer"
  fi
}

_flow_timer_status() {
  local timer_file="${FLOW_DATA_DIR}/timer.state"
  
  if [[ ! -f "$timer_file" ]]; then
    echo "  No active timer"
    echo "  Start one with: timer 25"
    return
  fi
  
  source "$timer_file"
  local remaining=$((end - EPOCHSECONDS))
  
  if (( remaining <= 0 )); then
    rm -f "$timer_file"
    echo "  Timer complete!"
    return
  fi
  
  local icon="⏱️"
  [[ "$type" == "break" ]] && icon="☕"
  
  echo ""
  printf "  %s %s: %d:%02d remaining\n" "$icon" "${type:-focus}" $((remaining / 60)) $((remaining % 60))
  [[ -n "$label" ]] && echo "     $label"
  echo ""
}

# Mini progress bar for timer
_flow_timer_progress_mini() {
  local remaining="$1"
  local total="$2"
  local width=20
  
  local filled=$(( (total - remaining) * width / total ))
  local empty=$((width - filled))
  
  printf "["
  printf "%${filled}s" | tr ' ' '█'
  printf "%${empty}s" | tr ' ' '░'
  printf "]"
}

# ============================================================================
# HELP
# ============================================================================

_flow_timer_help() {
  # Colors
  local _C_BOLD="${_C_BOLD:-\033[1m}"
  local _C_NC="${_C_NC:-\033[0m}"
  local _C_GREEN="${_C_GREEN:-\033[0;32m}"
  local _C_CYAN="${_C_CYAN:-\033[0;36m}"
  local _C_BLUE="${_C_BLUE:-\033[0;34m}"
  local _C_YELLOW="${_C_YELLOW:-\033[0;33m}"
  local _C_MAGENTA="${_C_MAGENTA:-\033[0;35m}"
  local _C_DIM="${_C_DIM:-\033[2m}"

  echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ ⏱️  TIMER - Focus & Break Management         │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_BOLD}Usage:${_C_NC} timer [command] [options]

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}timer${_C_NC}              Start 25-minute focus (default)
  ${_C_CYAN}timer 45${_C_NC}           Start 45-minute focus
  ${_C_CYAN}timer break${_C_NC}        Start 5-minute break
  ${_C_CYAN}timer status${_C_NC}       Check remaining time

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} timer                  ${_C_DIM}# 25 min focus${_C_NC}
  ${_C_DIM}\$${_C_NC} timer 45               ${_C_DIM}# 45 min focus${_C_NC}
  ${_C_DIM}\$${_C_NC} timer break            ${_C_DIM}# 5 min break${_C_NC}
  ${_C_DIM}\$${_C_NC} timer pomodoro         ${_C_DIM}# 4 pomodoro cycles${_C_NC}

${_C_BLUE}📋 COMMANDS${_C_NC}:
  ${_C_CYAN}timer${_C_NC} [minutes]     Start focus timer (default: 25)
  ${_C_CYAN}timer focus${_C_NC} <min>   Start focus session
  ${_C_CYAN}timer break${_C_NC} <min>   Start break timer (default: 5)
  ${_C_CYAN}timer stop${_C_NC}          Stop active timer
  ${_C_CYAN}timer status${_C_NC}        Show timer status

${_C_BLUE}🍅 POMODORO${_C_NC}:
  ${_C_CYAN}timer pomodoro${_C_NC} [n]  Run n pomodoro cycles (default: 4)
  ${_C_CYAN}timer pom${_C_NC}           Alias for pomodoro

${_C_BLUE}⚙️  POMODORO OPTIONS${_C_NC}:
  ${_C_DIM}timer pomodoro [cycles] [focus] [break] [long-break]${_C_NC}
  ${_C_DIM}timer pomodoro 4 25 5 15   # 4 cycles, 25m focus, 5m break, 15m long${_C_NC}

${_C_MAGENTA}💡 TIP${_C_NC}: Press Ctrl+C to interrupt any timer

${_C_DIM}See also:${_C_NC} flow break, morning help
"
}

# ============================================================================
# ALIASES
# ============================================================================

# Shortcuts
pom() { timer pomodoro "$@" }
