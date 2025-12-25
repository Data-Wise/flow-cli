#!/usr/bin/env zsh
# interactive-test.zsh - Step-by-step interactive testing for flow-cli
# Run with: zsh tests/interactive-test.zsh

# Colors
autoload -U colors && colors
RED=$fg[red]
GREEN=$fg[green]
YELLOW=$fg[yellow]
BLUE=$fg[blue]
CYAN=$fg[cyan]
BOLD=$bold_color
RESET=$reset_color

# Test counters
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0
typeset -g TESTS_SKIPPED=0

# ============================================================================
# HELPERS
# ============================================================================

header() {
  echo ""
  echo "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo "${BOLD}${BLUE}  $1${RESET}"
  echo "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""
}

step() {
  echo ""
  echo "${BOLD}${CYAN}▶ STEP: $1${RESET}"
  echo "${YELLOW}─────────────────────────────────────────────────────────────${RESET}"
}

expect() {
  echo ""
  echo "${GREEN}✓ EXPECTED:${RESET}"
  echo "$1" | sed 's/^/    /'
  echo ""
}

run_cmd() {
  echo "${BOLD}$ $1${RESET}"
  echo ""
  eval "$1"
  echo ""
}

ask_result() {
  echo ""
  echo -n "${YELLOW}Did you see the expected output? [y/n/s(kip)] ${RESET}"
  read -k1 answer
  echo ""

  case "$answer" in
    y|Y)
      echo "${GREEN}✓ PASSED${RESET}"
      ((TESTS_PASSED++))
      ;;
    n|N)
      echo "${RED}✗ FAILED${RESET}"
      ((TESTS_FAILED++))
      echo -n "Notes (optional): "
      read notes
      [[ -n "$notes" ]] && echo "  → $notes"
      ;;
    s|S)
      echo "${YELLOW}○ SKIPPED${RESET}"
      ((TESTS_SKIPPED++))
      ;;
  esac
}

wait_continue() {
  echo ""
  echo -n "${CYAN}Press ENTER to continue...${RESET}"
  read
}

# ============================================================================
# SETUP
# ============================================================================

header "FLOW-CLI INTERACTIVE TEST SUITE"

echo "This script will walk you through testing the flow-cli features."
echo "You'll run commands and verify the output matches expectations."
echo ""
echo "Loading flow-cli plugin..."

# Source the plugin
source "${0:h:h}/flow.plugin.zsh" 2>/dev/null || {
  echo "${RED}Error: Could not load flow.plugin.zsh${RESET}"
  echo "Make sure you're running from the flow-cli directory"
  exit 1
}

echo "${GREEN}✓ Plugin loaded${RESET}"
wait_continue

# ============================================================================
# TEST 1: BASIC DASHBOARD
# ============================================================================

header "TEST 1: Basic Dashboard"

step "Run the dashboard command"

expect "
• Header with date and time (🕐 HH:MM)
• Stats row showing 'Today: X sessions'
• QUICK ACCESS section with 5 projects
• BY CATEGORY section with progress bars
• Footer with tips
"

run_cmd "dash"

ask_result
wait_continue

# ============================================================================
# TEST 2: CATEGORY EXPANSION
# ============================================================================

header "TEST 2: Category Expansion"

step "Expand the dev-tools category"

expect "
• Header shows '🔧 DEV-TOOLS'
• Active projects (🟢) appear FIRST
• Progress bars shown (████░░ XX%)
• Focus text below each project
• Footer: '← dash to return'
"

run_cmd "dash dev"

ask_result
wait_continue

step "Try R packages category"

expect "
• Header shows '📦 R-PACKAGES'
• Projects like medfit, rmediation visible
• Active status and progress shown
"

run_cmd "dash r"

ask_result
wait_continue

# ============================================================================
# TEST 3: SESSION TRACKING
# ============================================================================

header "TEST 3: Session Tracking"

step "End any existing session first"

run_cmd "finish 'cleanup' 2>/dev/null || echo 'No active session'"

step "Start a new work session"

expect "
• Project context shown (icon, name, type)
• Status info from .STATUS file
• Session file created
"

run_cmd "work atlas"

ask_result

step "Verify session file exists"

expect "
• File contains: project=atlas
• File contains: start=<timestamp>
• File contains: date=<today>
"

run_cmd "cat ~/.local/share/flow/.current-session"

ask_result
wait_continue

step "Check dashboard shows ACTIVE NOW"

expect "
• 🎯 ACTIVE NOW section visible
• Shows 'atlas' as current project
• Shows elapsed time (⏱ Xm)
"

run_cmd "dash"

ask_result
wait_continue

step "End the session"

expect "
• Shows 'Session ended: Xm'
• Duration calculated correctly
"

run_cmd "finish 'test session complete'"

ask_result

step "Verify session file removed"

expect "
• Error: No such file or directory
"

run_cmd "cat ~/.local/share/flow/.current-session 2>&1"

ask_result
wait_continue

# ============================================================================
# TEST 4: INTERACTIVE MODE
# ============================================================================

header "TEST 4: Interactive Mode (fzf)"

step "Launch interactive dashboard"

expect "
• fzf picker opens full screen
• Projects listed with category icons (🔧📦🔬)
• Status icons visible (🟢🟡⚪)
• Preview pane on RIGHT shows .STATUS content
• Header shows keybindings

ACTIONS TO TRY:
  ↑↓  Navigate projects (preview updates)
  Type to filter (try 'med')
  ESC to cancel without action
"

echo "${YELLOW}Press ENTER to launch fzf (press ESC to exit)...${RESET}"
read

run_cmd "dash -i"

ask_result
wait_continue

# ============================================================================
# TEST 5: DUAL FORMAT PARSING
# ============================================================================

header "TEST 5: Dual .STATUS Format Parsing"

step "Check Markdown format (dev-tools)"

expect "
• Uses '## Status: Active' format
• Uses '## Progress: XX' format
"

run_cmd "head -6 ~/projects/dev-tools/flow-cli/.STATUS"

ask_result

step "Check YAML format (research)"

expect "
• Uses 'status: under review' format (lowercase)
• Uses 'progress: XX' format
• Uses 'next: ...' for focus text
"

run_cmd "head -6 ~/projects/research/collider/.STATUS"

ask_result

step "Dashboard parses research projects correctly"

expect "
• Research projects show status icons
• Progress bars display
• 'under review' shows as active (🟢)
"

run_cmd "dash research"

ask_result
wait_continue

# ============================================================================
# TEST 6: HELP AND ALIASES
# ============================================================================

header "TEST 6: Help and Aliases"

step "Check help output"

expect "
• Shows USAGE section
• Lists OPTIONS: -a, -i, -f, -h
• Lists CATEGORIES: dev, r, research, teach
• Shows LEGEND for status icons
"

run_cmd "dash --help"

ask_result

step "Test 'd' alias"

expect "
• Same output as 'dash'
"

run_cmd "d"

ask_result
wait_continue

# ============================================================================
# TEST 7: ALL PROJECTS VIEW
# ============================================================================

header "TEST 7: All Projects View"

step "Show all projects (flat list)"

expect "
• Shows ALL projects in flat list
• Status icons visible
• Focus text shown inline
• No grouping by category
"

run_cmd "dash -a | head -20"

ask_result
wait_continue

# ============================================================================
# TEST 8: EDGE CASES
# ============================================================================

header "TEST 8: Edge Cases"

step "Dashboard with no active session"

expect "
• NO 'ACTIVE NOW' section
• Dashboard still displays normally
"

run_cmd "finish 2>/dev/null; dash | head -15"

ask_result

step "Project without .STATUS file"

expect "
• Shows ⚪ (unknown) status icon
• No progress bar
• No focus text
• Still navigable
"

echo "Look for projects with ⚪ in the dev category:"
run_cmd "dash dev | grep '⚪'"

ask_result
wait_continue

# ============================================================================
# RESULTS
# ============================================================================

header "TEST RESULTS"

echo ""
echo "  ${GREEN}✓ Passed:  $TESTS_PASSED${RESET}"
echo "  ${RED}✗ Failed:  $TESTS_FAILED${RESET}"
echo "  ${YELLOW}○ Skipped: $TESTS_SKIPPED${RESET}"
echo ""

TOTAL=$((TESTS_PASSED + TESTS_FAILED))
if (( TOTAL > 0 )); then
  PERCENT=$((TESTS_PASSED * 100 / TOTAL))
  echo "  Pass rate: ${PERCENT}%"
fi

echo ""

if (( TESTS_FAILED == 0 )); then
  echo "${GREEN}${BOLD}All tests passed! 🎉${RESET}"
else
  echo "${YELLOW}Some tests failed. Review the output above.${RESET}"
fi

echo ""
echo "Test session complete."
