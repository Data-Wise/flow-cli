# commands/tutorial.zsh - Interactive flow-cli tutorial
# Learn flow-cli step by step with hands-on exercises

# ============================================================================
# TUTORIAL STATE
# ============================================================================

TUTORIAL_STATE_FILE="${FLOW_DATA_DIR:-$HOME/.local/share/flow}/tutorial-progress"

_tutorial_get_progress() {
  [[ -f "$TUTORIAL_STATE_FILE" ]] && cat "$TUTORIAL_STATE_FILE" || echo "0"
}

_tutorial_save_progress() {
  mkdir -p "$(dirname "$TUTORIAL_STATE_FILE")"
  echo "$1" > "$TUTORIAL_STATE_FILE"
}

_tutorial_reset() {
  rm -f "$TUTORIAL_STATE_FILE"
  echo "  ✅ Tutorial progress reset!"
}

# ============================================================================
# UI HELPERS
# ============================================================================

_tut_header() {
  local level="$1"
  local title="$2"
  local icon=""

  case "$level" in
    beginner) icon="🌱" ;;
    medium)   icon="🌿" ;;
    advanced) icon="🌳" ;;
  esac

  echo ""
  echo "╔════════════════════════════════════════════════════════════════╗"
  printf "║  %s %-58s║\n" "$icon" "$title"
  echo "╚════════════════════════════════════════════════════════════════╝"
  echo ""
}

_tut_lesson() {
  local num="$1"
  local title="$2"
  echo "  ┌─────────────────────────────────────────────────────────────┐"
  printf "  │  Lesson %s: %-49s│\n" "$num" "$title"
  echo "  └─────────────────────────────────────────────────────────────┘"
  echo ""
}

_tut_explain() {
  echo "  $1"
}

_tut_command() {
  echo ""
  echo "  💻 Try this command:"
  echo "  ┌─────────────────────────────────────────────────────────────┐"
  echo "    $1"
  echo "  └─────────────────────────────────────────────────────────────┘"
  echo ""
}

_tut_tip() {
  echo "  💡 Tip: $1"
}

_tut_success() {
  echo ""
  echo "  ✅ $1"
  echo ""
}

_tut_wait() {
  echo ""
  echo -n "  Press Enter to continue..."
  read -r
  echo ""
}

_tut_ask() {
  echo ""
  echo -n "  $1 (y/n): "
  read -r answer
  [[ "$answer" == "y" || "$answer" == "Y" ]]
}

# ============================================================================
# BEGINNER LESSONS
# ============================================================================

_tutorial_beginner() {
  _tut_header "beginner" "BEGINNER: Core Workflow"

  echo "  Welcome to flow-cli! 🎉"
  echo ""
  echo "  This tutorial will teach you the essential commands"
  echo "  for an ADHD-friendly development workflow."
  echo ""
  echo "  Lessons:"
  echo "    1. pick  - Find and switch to projects"
  echo "    2. work  - Start a focused work session"
  echo "    3. dash  - See your project dashboard"
  echo "    4. finish - End your session cleanly"
  echo ""

  _tut_wait

  # Lesson 1: pick
  _tut_lesson "1" "pick - Interactive Project Picker"

  _tut_explain "The 'pick' command lets you fuzzy-find any project."
  _tut_explain "It uses fzf for fast, interactive selection."
  echo ""
  _tut_explain "Features:"
  _tut_explain "  • Type to filter projects"
  _tut_explain "  • Ctrl-S to view .STATUS file"
  _tut_explain "  • Ctrl-L to view git log"
  _tut_explain "  • Enter to cd to project"

  _tut_command "pick"

  _tut_tip "Try 'pick dev' to filter to dev-tools only"
  _tut_tip "Aliases: pickr (R packages), pickdev, pickq (Quarto)"

  if _tut_ask "Try 'pick --help' now?"; then
    pick --help
  fi

  _tut_wait

  # Lesson 2: work
  _tut_lesson "2" "work - Start a Work Session"

  _tut_explain "The 'work' command starts a focused session."
  _tut_explain "It tracks time, sets context, and helps you focus."
  echo ""
  _tut_explain "What it does:"
  _tut_explain "  • Changes to project directory"
  _tut_explain "  • Shows project status and context"
  _tut_explain "  • Starts session timer (if atlas connected)"
  _tut_explain "  • Sets FLOW_CURRENT_PROJECT variable"

  _tut_command "work flow-cli"

  _tut_tip "Use 'why' to remember what you're working on"
  _tut_tip "Use 'hop <project>' to quick-switch with tmux"

  _tut_wait

  # Lesson 3: dash
  _tut_lesson "3" "dash - Project Dashboard"

  _tut_explain "The 'dash' command shows a quick project overview."
  _tut_explain "Great for getting oriented at the start of a session."
  echo ""
  _tut_explain "Shows:"
  _tut_explain "  • Git status and recent commits"
  _tut_explain "  • .STATUS file contents"
  _tut_explain "  • Active tasks (from atlas or TODO.md)"

  _tut_command "dash"

  _tut_tip "Use 'dash dev' to see all dev-tools projects"
  _tut_tip "Use 'dash teach' for teaching projects"

  if _tut_ask "Run 'dash' now?"; then
    dash
  fi

  _tut_wait

  # Lesson 4: finish
  _tut_lesson "4" "finish - End Your Session"

  _tut_explain "The 'finish' command wraps up your work session."
  _tut_explain "It helps you leave clean breadcrumbs for next time."
  echo ""
  _tut_explain "What it does:"
  _tut_explain "  • Optionally commits changes"
  _tut_explain "  • Records session duration"
  _tut_explain "  • Prompts for a note about where you left off"

  _tut_command "finish 'Got tests passing'"

  _tut_tip "The note becomes your git commit message"
  _tut_tip "Alias: 'fin' for quick access"

  _tut_wait

  # Summary
  _tut_header "beginner" "Beginner Complete! 🎉"

  echo "  You learned the core workflow:"
  echo ""
  echo "    pick    → Find projects"
  echo "    work    → Start session"
  echo "    dash    → See status"
  echo "    finish  → End cleanly"
  echo ""
  echo "  Quick reference:"
  echo "    pick help | work help | dash help | finish help"
  echo ""

  _tutorial_save_progress "beginner"

  if _tut_ask "Continue to Medium level?"; then
    _tutorial_medium
  fi
}

# ============================================================================
# MEDIUM LESSONS
# ============================================================================

_tutorial_medium() {
  _tut_header "medium" "MEDIUM: Productivity Tools"

  echo "  Now let's level up your workflow! 🚀"
  echo ""
  echo "  These tools help you capture ideas, manage focus,"
  echo "  and stay on track throughout the day."
  echo ""
  echo "  Lessons:"
  echo "    5. catch/crumb - Quick capture ideas"
  echo "    6. status      - Manage .STATUS files"
  echo "    7. timer       - Focus timers"
  echo "    8. ADHD helpers - js, stuck, focus, brk"
  echo ""

  _tut_wait

  # Lesson 5: catch
  _tut_lesson "5" "catch/crumb - Quick Capture"

  _tut_explain "Capture ideas without losing focus."
  _tut_explain "Don't context-switch - just dump and continue."
  echo ""
  _tut_explain "Commands:"
  _tut_explain "  catch <idea>  - Capture to inbox"
  _tut_explain "  crumb <note>  - Leave breadcrumb in project"
  _tut_explain "  inbox         - View your inbox"
  _tut_explain "  win <text>    - Log a win (dopamine boost!)"

  _tut_command "catch 'Remember to update docs'"
  _tut_command "win 'Fixed that tricky bug!'"

  _tut_tip "Use 'catch' when an idea hits mid-flow"
  _tut_tip "Review inbox during breaks, not while coding"

  _tut_wait

  # Lesson 6: status
  _tut_lesson "6" "status - Project Status Management"

  _tut_explain ".STATUS files track project state."
  _tut_explain "The 'status' command helps manage them."
  echo ""
  _tut_explain "Commands:"
  _tut_explain "  status          - View current project status"
  _tut_explain "  status set X    - Set progress (0-100)"
  _tut_explain "  status next X   - Set next action"
  _tut_explain "  status all      - View all project statuses"

  _tut_command "status"
  _tut_command "status next 'Write unit tests'"

  _tut_tip ".STATUS files are plain markdown - edit directly too"

  _tut_wait

  # Lesson 7: timer
  _tut_lesson "7" "timer - Focus Sessions"

  _tut_explain "Pomodoro-style timers for focused work."
  _tut_explain "Helps maintain sustainable pace."
  echo ""
  _tut_explain "Commands:"
  _tut_explain "  timer 25       - 25 minute focus session"
  _tut_explain "  timer status   - Check remaining time"
  _tut_explain "  timer stop     - Cancel timer"
  _tut_explain "  brk [mins]     - Take a break (default 5 min)"

  _tut_command "timer 25"

  _tut_tip "Pair with 'focus' to set what you're working on"

  _tut_wait

  # Lesson 8: ADHD helpers
  _tut_lesson "8" "ADHD Helpers"

  _tut_explain "Special commands for when executive function is low."
  echo ""
  _tut_explain "Commands:"
  _tut_explain "  js           - 'Just Start' - picks a project for you"
  _tut_explain "  stuck        - When you're blocked - get unstuck"
  _tut_explain "  focus <text> - Set your current focus"
  _tut_explain "  next         - What should I work on?"
  _tut_explain "  why          - Why am I here? Show context"

  _tut_command "js"
  _tut_command "focus 'Writing the tutorial command'"

  _tut_tip "'js' is great when you can't decide what to work on"
  _tut_tip "'stuck' gives you a checklist to get unblocked"

  _tut_wait

  # Summary
  _tut_header "medium" "Medium Complete! 🎉"

  echo "  You learned productivity tools:"
  echo ""
  echo "    catch/crumb  → Quick capture"
  echo "    status       → Track progress"
  echo "    timer        → Focus sessions"
  echo "    js/stuck     → ADHD helpers"
  echo ""

  _tutorial_save_progress "medium"

  if _tut_ask "Continue to Advanced level?"; then
    _tutorial_advanced
  fi
}

# ============================================================================
# ADVANCED LESSONS
# ============================================================================

_tutorial_advanced() {
  _tut_header "advanced" "ADVANCED: Power Features"

  echo "  Time for the advanced features! 💪"
  echo ""
  echo "  These require some setup but unlock"
  echo "  powerful workflow capabilities."
  echo ""
  echo "  Lessons:"
  echo "    9.  Atlas integration"
  echo "    10. Smart dispatchers (g, v, mcp, obs)"
  echo "    11. Customization and hooks"
  echo "    12. Morning routine"
  echo ""

  _tut_wait

  # Lesson 9: Atlas
  _tut_lesson "9" "Atlas State Engine"

  _tut_explain "Atlas is an optional state management engine."
  _tut_explain "It provides persistent state across sessions."
  echo ""
  _tut_explain "Features with Atlas:"
  _tut_explain "  • Session history and analytics"
  _tut_explain "  • Cross-project task tracking"
  _tut_explain "  • Smart project suggestions"
  _tut_explain "  • Time tracking and reports"
  echo ""
  _tut_explain "Installation:"
  _tut_command "npm install -g @data-wise/atlas"
  echo ""
  _tut_explain "Check status:"
  _tut_command "atlas status"

  _tut_tip "flow-cli works without Atlas, but it's more powerful with it"

  _tut_wait

  # Lesson 10: Dispatchers
  _tut_lesson "10" "Smart Dispatchers"

  _tut_explain "Dispatchers provide context-aware shortcuts."
  _tut_explain "Same command, different behavior per project type."
  echo ""
  _tut_explain "Available dispatchers:"
  _tut_explain "  g <action>   - Git operations (smart shortcuts)"
  _tut_explain "  v <action>   - Editor/viewer (vi, code, etc)"
  _tut_explain "  mcp <action> - MCP server management"
  _tut_explain "  obs <action> - Obsidian vault operations"

  _tut_command "g s     # smart git status"
  _tut_command "g sync  # pull, push, handle conflicts"
  _tut_command "v .     # open project in editor"

  _tut_tip "Run 'g help' to see all git shortcuts"

  _tut_wait

  # Lesson 11: Customization
  _tut_lesson "11" "Customization"

  _tut_explain "flow-cli can be customized via environment variables."
  echo ""
  _tut_explain "Key variables (set before sourcing plugin):"
  echo ""
  _tut_explain "  FLOW_PROJECTS_ROOT   - Base projects directory"
  _tut_explain "  FLOW_ATLAS_ENABLED   - auto|yes|no"
  _tut_explain "  FLOW_LOAD_DISPATCHERS - yes|no"
  _tut_explain "  FLOW_QUIET           - Suppress welcome message"
  echo ""
  _tut_explain "Config location: ~/.config/flow/"
  _tut_explain "Data location:   ~/.local/share/flow/"

  _tut_wait

  # Lesson 12: Morning
  _tut_lesson "12" "Morning Routine"

  _tut_explain "The 'morning' command helps start your day."
  _tut_explain "It reduces decision fatigue with a guided routine."
  echo ""
  _tut_explain "What it does:"
  _tut_explain "  • Shows inbox items to process"
  _tut_explain "  • Displays active project statuses"
  _tut_explain "  • Suggests what to work on first"
  _tut_explain "  • Sets up your focus for the day"

  _tut_command "morning"

  _tut_tip "Run 'morning' when you sit down to code"
  _tut_tip "It takes 2 minutes and saves hours of drift"

  _tut_wait

  # Summary
  _tut_header "advanced" "Tutorial Complete! 🎓"

  echo "  Congratulations! You've completed the flow-cli tutorial."
  echo ""
  echo "  Quick reference of all commands:"
  echo ""
  echo "  Core:        pick, work, dash, finish, why, hop"
  echo "  Capture:     catch, crumb, inbox, win"
  echo "  Focus:       timer, focus, brk"
  echo "  ADHD:        js, next, stuck"
  echo "  Status:      status, morning"
  echo "  Dispatchers: g, v, mcp, obs"
  echo ""
  echo "  Get help:    <command> help  (e.g., 'pick help')"
  echo "  Reset:       tutorial reset"
  echo ""

  _tutorial_save_progress "advanced"
}

# ============================================================================
# MAIN TUTORIAL COMMAND
# ============================================================================

tutorial() {
  local level="${1:-}"

  # Help
  if [[ "$level" == "help" || "$level" == "--help" || "$level" == "-h" ]]; then
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════╗
║  📚 TUTORIAL - Interactive flow-cli Tutorial                  ║
╚════════════════════════════════════════════════════════════════╝

USAGE:
  tutorial [level|action]

LEVELS:
  beginner    Core workflow (pick, work, dash, finish)
  medium      Productivity tools (catch, status, timer, ADHD helpers)
  advanced    Power features (atlas, dispatchers, customization)

ACTIONS:
  reset       Reset progress and start over
  progress    Show current progress

EXAMPLES:
  tutorial           # Start from current progress
  tutorial beginner  # Start beginner lessons
  tutorial reset     # Reset and start fresh
EOF
    return 0
  fi

  # Reset
  if [[ "$level" == "reset" ]]; then
    _tutorial_reset
    return 0
  fi

  # Progress
  if [[ "$level" == "progress" ]]; then
    local prog=$(_tutorial_get_progress)
    echo ""
    echo "  📊 Tutorial Progress: $prog"
    echo ""
    case "$prog" in
      0) echo "  Status: Not started" ;;
      beginner) echo "  Status: Beginner complete, ready for Medium" ;;
      medium) echo "  Status: Medium complete, ready for Advanced" ;;
      advanced) echo "  Status: All complete! 🎓" ;;
    esac
    echo ""
    return 0
  fi

  # Specific level
  case "$level" in
    beginner|1)
      _tutorial_beginner
      ;;
    medium|2)
      _tutorial_medium
      ;;
    advanced|3)
      _tutorial_advanced
      ;;
    "")
      # Auto-resume from progress
      local prog=$(_tutorial_get_progress)
      case "$prog" in
        0) _tutorial_beginner ;;
        beginner) _tutorial_medium ;;
        medium) _tutorial_advanced ;;
        advanced)
          echo ""
          echo "  🎓 You've completed all tutorials!"
          echo ""
          echo "  Run 'tutorial reset' to start over"
          echo "  Or 'tutorial <level>' to revisit a specific level"
          echo ""
          ;;
      esac
      ;;
    *)
      echo "Unknown level: $level"
      echo "Try: tutorial help"
      return 1
      ;;
  esac
}

# Alias
alias tut='tutorial'
