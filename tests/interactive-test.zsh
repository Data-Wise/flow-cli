#!/usr/bin/env zsh
# interactive-test.zsh - Step-by-step interactive testing for flow-cli
#
# IMPORTANT: This script requires a real terminal (iTerm, Terminal.app)
# Run with: zsh tests/interactive-test.zsh
#
# For automated testing without user input, use:
#   zsh tests/automated-test.zsh
#
# Features:
# - Logs all output to tests/test-results.log
# - Captures both stdout and stderr
# - Highlights errors in red
# - Auto-detects common error patterns

# Auto mode for CI/debugging (pass --auto flag)
AUTO_MODE=0
if [[ "$1" == "--auto" ]]; then
  AUTO_MODE=1
  echo "Running in AUTO mode - all prompts will be auto-answered 'y'"
fi

# Check if running in a real terminal (skip in auto mode)
if [[ $AUTO_MODE -eq 0 ]] && [[ ! -t 0 ]]; then
  echo "ERROR: This script requires an interactive terminal."
  echo ""
  echo "Run it directly in iTerm or Terminal.app:"
  echo "  zsh tests/interactive-test.zsh"
  echo ""
  echo "For automated testing, use:"
  echo "  zsh tests/automated-test.zsh"
  echo ""
  echo "Or run with --auto flag:"
  echo "  zsh tests/interactive-test.zsh --auto"
  exit 1
fi

# ============================================================================
# LOGGING SETUP
# ============================================================================

# Log file location
SCRIPT_DIR="${0:h}"
LOG_FILE="${SCRIPT_DIR}/test-results.log"
ERROR_LOG="${SCRIPT_DIR}/test-errors.log"

# Initialize logs
echo "=== FLOW-CLI TEST RUN ===" > "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"
echo "=========================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

> "$ERROR_LOG"  # Clear error log

# Colors - use ANSI codes directly for maximum compatibility
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

# Test counters
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0
typeset -g TESTS_SKIPPED=0
typeset -g AUTO_ERRORS=0

# ============================================================================
# LOGGING HELPERS
# ============================================================================

log() {
  echo "$1"
  echo "$1" >> "$LOG_FILE"
}

log_section() {
  echo "" >> "$LOG_FILE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$LOG_FILE"
  echo "$1" >> "$LOG_FILE"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$LOG_FILE"
}

# Detect errors in output
check_for_errors() {
  local output="$1"
  local test_name="$2"
  local errors_found=0

  # Common error patterns
  local -a error_patterns=(
    "command not found"
    "not found"
    "error:"
    "Error:"
    "ERROR:"
    "failed"
    "FAILED"
    "permission denied"
    "No such file"
    "syntax error"
    "undefined"
    "segmentation fault"
    "core dumped"
  )

  for pattern in "${error_patterns[@]}"; do
    if [[ "$output" == *"$pattern"* ]]; then
      # Exclude expected errors
      if [[ "$test_name" == *"session file removed"* ]] && [[ "$pattern" == "No such file" ]]; then
        continue  # This is expected
      fi

      echo "${RED}⚠ AUTO-DETECTED ERROR: '$pattern' found${RESET}"
      echo "[$test_name] ERROR: $pattern" >> "$ERROR_LOG"
      echo "  Output: ${output:0:200}" >> "$ERROR_LOG"
      ((errors_found++))
      ((AUTO_ERRORS++))
    fi
  done

  return $errors_found
}

# ============================================================================
# UI HELPERS
# ============================================================================

header() {
  log_section "$1"
  echo ""
  echo "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo "${BOLD}${BLUE}  $1${RESET}"
  echo "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""
}

step() {
  local step_name="$1"
  echo "" >> "$LOG_FILE"
  echo "▶ STEP: $step_name" >> "$LOG_FILE"
  echo ""
  echo "${BOLD}${CYAN}▶ STEP: $step_name${RESET}"
  echo "${YELLOW}─────────────────────────────────────────────────────────────${RESET}"
}

expect() {
  echo "EXPECTED:" >> "$LOG_FILE"
  echo "$1" >> "$LOG_FILE"
  echo ""
  echo "${GREEN}✓ EXPECTED:${RESET}"
  echo "$1" | while IFS= read -r line; do
    echo "    $line"
  done
  echo ""
}

# Run command and capture all output
run_cmd() {
  local cmd="$1"
  local test_name="${2:-$cmd}"

  echo "COMMAND: $cmd" >> "$LOG_FILE"
  echo "${BOLD}$ $cmd${RESET}"
  echo ""

  # Capture both stdout and stderr
  local output
  local exit_code

  output=$(eval "$cmd" 2>&1)
  exit_code=$?

  # Display output
  echo "$output"

  # Log output
  echo "EXIT CODE: $exit_code" >> "$LOG_FILE"
  echo "OUTPUT:" >> "$LOG_FILE"
  echo "$output" >> "$LOG_FILE"
  echo "" >> "$LOG_FILE"

  # Check for errors
  if (( exit_code != 0 )) && [[ "$test_name" != *"expected to fail"* ]]; then
    echo "${RED}⚠ Non-zero exit code: $exit_code${RESET}"
    echo "[$test_name] EXIT CODE: $exit_code" >> "$ERROR_LOG"
  fi

  check_for_errors "$output" "$test_name"

  echo ""
}

ask_result() {
  echo ""

  # Auto mode: always pass
  if [[ $AUTO_MODE -eq 1 ]]; then
    echo "${GREEN}✓ PASSED (auto)${RESET}"
    echo "RESULT: PASSED (auto)" >> "$LOG_FILE"
    ((TESTS_PASSED++))
    return
  fi

  echo -n "${YELLOW}Did you see the expected output? [y/n/s(kip)] ${RESET}"

  # Read single character - try -k1 first, fall back to regular read
  local answer
  if read -k1 answer 2>/dev/null; then
    echo ""
  else
    # Fallback: read full line and take first char
    read answer
    answer="${answer:0:1}"
  fi

  case "$answer" in
    y|Y)
      echo "${GREEN}✓ PASSED${RESET}"
      echo "RESULT: PASSED" >> "$LOG_FILE"
      ((TESTS_PASSED++))
      ;;
    n|N)
      echo "${RED}✗ FAILED${RESET}"
      echo "RESULT: FAILED" >> "$LOG_FILE"
      ((TESTS_FAILED++))
      echo -n "Notes (optional): "
      read notes
      if [[ -n "$notes" ]]; then
        echo "  → $notes"
        echo "NOTES: $notes" >> "$LOG_FILE"
        echo "[Manual] FAILED: $notes" >> "$ERROR_LOG"
      fi
      ;;
    s|S)
      echo "${YELLOW}○ SKIPPED${RESET}"
      echo "RESULT: SKIPPED" >> "$LOG_FILE"
      ((TESTS_SKIPPED++))
      ;;
  esac
}

wait_continue() {
  # Skip in auto mode
  if [[ $AUTO_MODE -eq 1 ]]; then
    return
  fi

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
echo "${CYAN}Logs will be saved to:${RESET}"
echo "  • ${LOG_FILE}"
echo "  • ${ERROR_LOG}"
echo ""
echo "Loading flow-cli plugin..."

# Get the plugin path
PLUGIN_DIR="${0:h:h}"
PLUGIN_FILE="${PLUGIN_DIR}/flow.plugin.zsh"

echo "  Plugin path: ${PLUGIN_FILE}"

if [[ ! -f "$PLUGIN_FILE" ]]; then
  echo "${RED}Error: Plugin file not found: ${PLUGIN_FILE}${RESET}"
  echo "PLUGIN NOT FOUND" >> "$ERROR_LOG"
  exit 1
fi

# Source the plugin
if source "$PLUGIN_FILE" 2>&1; then
  echo "${GREEN}✓ Plugin loaded${RESET}"
  echo "Plugin loaded successfully" >> "$LOG_FILE"
else
  echo "${RED}Error: Failed to source plugin${RESET}"
  echo "PLUGIN SOURCE FAILED" >> "$ERROR_LOG"
  exit 1
fi

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

run_cmd "dash" "Basic Dashboard"

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

run_cmd "dash dev" "Category: dev-tools"

ask_result
wait_continue

step "Try R packages category"

expect "
• Header shows '📦 R-PACKAGES'
• Projects like medfit, rmediation visible
• Active status and progress shown
"

run_cmd "dash r" "Category: r-packages"

ask_result
wait_continue

# ============================================================================
# TEST 3: SESSION TRACKING
# ============================================================================

header "TEST 3: Session Tracking"

step "End any existing session first"

run_cmd "finish 'cleanup' 2>/dev/null || echo 'No active session'" "Session cleanup (expected to fail if no session)"

step "Start a new work session"

expect "
• Project context shown (icon, name, type)
• Status info from .STATUS file
• Session file created
"

run_cmd "work atlas" "Start work session"

ask_result

step "Verify session file exists"

expect "
• File contains: project=atlas
• File contains: start=<timestamp>
• File contains: date=<today>
"

run_cmd "cat ~/.local/share/flow/.current-session" "Session file contents"

ask_result
wait_continue

step "Check dashboard shows ACTIVE NOW"

expect "
• 🎯 ACTIVE NOW section visible
• Shows 'atlas' as current project
• Shows elapsed time (⏱ Xm)
"

run_cmd "dash" "Dashboard with active session"

ask_result
wait_continue

step "End the session"

expect "
• Shows 'Session ended: Xm'
• Duration calculated correctly
"

run_cmd "finish 'test session complete'" "End session"

ask_result

step "Verify session file removed"

expect "
• Error: No such file or directory (THIS IS EXPECTED)
"

run_cmd "cat ~/.local/share/flow/.current-session 2>&1" "Verify session file removed (expected to fail)"

ask_result
wait_continue

# ============================================================================
# TEST 4: INTERACTIVE MODE
# ============================================================================

header "TEST 4: Interactive Mode (fzf)"

# Skip fzf in auto mode (requires real terminal interaction)
if [[ $AUTO_MODE -eq 1 ]]; then
  echo "${YELLOW}Skipping fzf test in auto mode${RESET}"
  echo "RESULT: SKIPPED (auto - fzf requires terminal)" >> "$LOG_FILE"
  ((TESTS_SKIPPED++))
else
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

  run_cmd "dash -i" "Interactive mode (fzf)"

  ask_result
  wait_continue
fi

# ============================================================================
# TEST 5: DUAL FORMAT PARSING
# ============================================================================

header "TEST 5: Dual .STATUS Format Parsing"

step "Check Markdown format (dev-tools)"

expect "
• Uses '## Status: Active' format
• Uses '## Progress: XX' format
"

run_cmd "head -12 ~/projects/dev-tools/flow-cli/.STATUS" "Markdown .STATUS format"

ask_result

step "Check YAML format (research)"

expect "
• Uses 'status: under review' format (lowercase)
• Uses 'progress: XX' format
• Uses 'next: ...' for focus text
"

run_cmd "head -12 ~/projects/research/collider/.STATUS" "YAML .STATUS format"

ask_result

step "Dashboard parses research projects correctly"

expect "
• Research projects show status icons
• Progress bars display
• 'under review' shows as active (🟢)
"

run_cmd "dash research" "Research category parsing"

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

run_cmd "dash --help" "Help output"

ask_result

step "Test 'd' alias"

expect "
• Same output as 'dash'
"

run_cmd "d" "Alias: d → dash"

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

run_cmd "dash -a | head -20" "All projects view"

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

run_cmd "finish 2>/dev/null; dash | head -15" "Dashboard without session"

ask_result

step "Project without .STATUS file"

expect "
• Shows ⚪ (unknown) status icon
• No progress bar
• No focus text
• Still navigable
"

echo "Look for projects with ⚪ in the dev category:"
run_cmd "dash dev | grep '⚪' || echo '(No projects without .STATUS)'" "Projects without .STATUS"

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

if (( AUTO_ERRORS > 0 )); then
  echo "  ${RED}⚠ Auto-detected errors: $AUTO_ERRORS${RESET}"
  echo ""
fi

TOTAL=$((TESTS_PASSED + TESTS_FAILED))
if (( TOTAL > 0 )); then
  PERCENT=$((TESTS_PASSED * 100 / TOTAL))
  echo "  Pass rate: ${PERCENT}%"
fi

echo ""

# Write summary to log
echo "" >> "$LOG_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$LOG_FILE"
echo "SUMMARY" >> "$LOG_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$LOG_FILE"
echo "Passed: $TESTS_PASSED" >> "$LOG_FILE"
echo "Failed: $TESTS_FAILED" >> "$LOG_FILE"
echo "Skipped: $TESTS_SKIPPED" >> "$LOG_FILE"
echo "Auto-detected errors: $AUTO_ERRORS" >> "$LOG_FILE"
echo "Pass rate: ${PERCENT:-0}%" >> "$LOG_FILE"

if (( TESTS_FAILED == 0 && AUTO_ERRORS == 0 )); then
  echo "${GREEN}${BOLD}All tests passed! 🎉${RESET}"
  echo "Status: ALL PASSED" >> "$LOG_FILE"
else
  echo "${YELLOW}Some tests failed or had errors. Check:${RESET}"
  echo "  • Full log: ${LOG_FILE}"
  echo "  • Errors only: ${ERROR_LOG}"
  echo "Status: ISSUES DETECTED" >> "$LOG_FILE"
fi

echo ""
echo "Test session complete."
echo ""
echo "${CYAN}Log files:${RESET}"
echo "  ${LOG_FILE}"
echo "  ${ERROR_LOG}"

# Show error summary if any
if [[ -s "$ERROR_LOG" ]]; then
  echo ""
  echo "${RED}━━━ ERROR SUMMARY ━━━${RESET}"
  cat "$ERROR_LOG"
fi
