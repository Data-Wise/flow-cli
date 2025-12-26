#!/usr/bin/env zsh
# automated-test.zsh - Non-interactive automated tests for flow-cli
# Run with: zsh tests/automated-test.zsh
#
# Returns exit code 0 if all tests pass, non-zero otherwise
# All output goes to stdout/stderr for easy capture

# Don't use set -e - we want to continue after failures

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Counters
typeset -g TESTS_RUN=0
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0

# ============================================================================
# TEST HELPERS
# ============================================================================

test_start() {
  echo -n "${CYAN}TEST: $1${RESET} ... "
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_pass() {
  echo "${GREEN}PASS${RESET}"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
  echo "${RED}FAIL${RESET}"
  echo "  ${RED}→ $1${RESET}"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

# Check command output for error patterns
check_no_errors() {
  local output="$1"
  local context="$2"

  local -a error_patterns=(
    "command not found"
    "error:"
    "Error:"
    "ERROR:"
    "syntax error"
    "undefined"
    "segmentation fault"
  )

  for pattern in "${error_patterns[@]}"; do
    if [[ "$output" == *"$pattern"* ]]; then
      test_fail "Found '$pattern' in output"
      echo "  Output: ${output:0:200}"
      return 1
    fi
  done

  return 0
}

# ============================================================================
# SETUP
# ============================================================================

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  FLOW-CLI AUTOMATED TEST SUITE"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Source the plugin
SCRIPT_DIR="${0:h}"
PLUGIN_FILE="${SCRIPT_DIR}/../flow.plugin.zsh"

test_start "Plugin loads without errors"
plugin_output=$(source "$PLUGIN_FILE" 2>&1)
if check_no_errors "$plugin_output" "plugin load"; then
  source "$PLUGIN_FILE" 2>/dev/null
  test_pass
fi

# ============================================================================
# CORE COMMAND TESTS
# ============================================================================

echo ""
echo "── Core Commands ──"

test_start "dash runs without errors"
output=$(dash 2>&1)
if check_no_errors "$output" "dash"; then
  if [[ "$output" == *"FLOW DASHBOARD"* ]]; then
    test_pass
  else
    test_fail "Missing 'FLOW DASHBOARD' header"
  fi
fi

test_start "dash dev runs without errors"
output=$(dash dev 2>&1)
if check_no_errors "$output" "dash dev"; then
  if [[ "$output" == *"DEV-TOOLS"* ]]; then
    test_pass
  else
    test_fail "Missing 'DEV-TOOLS' header"
  fi
fi

test_start "dash r runs without errors"
output=$(dash r 2>&1)
if check_no_errors "$output" "dash r"; then
  if [[ "$output" == *"R-PACKAGES"* ]]; then
    test_pass
  else
    test_fail "Missing 'R-PACKAGES' header"
  fi
fi

test_start "dash research runs without errors"
output=$(dash research 2>&1)
if check_no_errors "$output" "dash research"; then
  if [[ "$output" == *"RESEARCH"* ]]; then
    test_pass
  else
    test_fail "Missing 'RESEARCH' header"
  fi
fi

test_start "dash --help runs without errors"
output=$(dash --help 2>&1)
if check_no_errors "$output" "dash --help"; then
  if [[ "$output" == *"USAGE"* ]]; then
    test_pass
  else
    test_fail "Missing 'USAGE' section"
  fi
fi

test_start "dash -a runs without errors"
output=$(dash -a 2>&1 | head -30)
if check_no_errors "$output" "dash -a"; then
  if [[ "$output" == *"ALL PROJECTS"* ]]; then
    test_pass
  else
    test_fail "Missing 'ALL PROJECTS' header"
  fi
fi

# ============================================================================
# SESSION TESTS
# ============================================================================

echo ""
echo "── Session Tracking ──"

# Clean up any existing session
finish 2>/dev/null || true

test_start "work command starts session"
output=$(work flow-cli 2>&1)
if check_no_errors "$output" "work flow-cli"; then
  if [[ -f ~/.local/share/flow/.current-session ]]; then
    test_pass
  else
    test_fail "Session file not created"
  fi
fi

test_start "Session file has correct format"
if [[ -f ~/.local/share/flow/.current-session ]]; then
  session_content=$(cat ~/.local/share/flow/.current-session)
  if [[ "$session_content" == *"project="* ]] && [[ "$session_content" == *"start="* ]]; then
    test_pass
  else
    test_fail "Session file missing expected fields"
    echo "  Content: $session_content"
  fi
else
  test_fail "Session file does not exist"
fi

test_start "dash shows ACTIVE NOW when session active"
output=$(dash 2>&1)
if [[ "$output" == *"ACTIVE NOW"* ]]; then
  test_pass
else
  test_fail "Missing 'ACTIVE NOW' section"
fi

test_start "finish command ends session"
output=$(finish "automated test" 2>&1)
if check_no_errors "$output" "finish"; then
  if [[ ! -f ~/.local/share/flow/.current-session ]]; then
    test_pass
  else
    test_fail "Session file still exists after finish"
  fi
fi

test_start "dash hides ACTIVE NOW when no session"
output=$(dash 2>&1)
if [[ "$output" != *"ACTIVE NOW"* ]]; then
  test_pass
else
  test_fail "'ACTIVE NOW' should not appear without active session"
fi

# ============================================================================
# STATUS PARSING TESTS
# ============================================================================

echo ""
echo "── Status Parsing ──"

test_start "_dash_get_project_status parses Markdown format"
if [[ -f ~/projects/dev-tools/flow-cli/.STATUS ]]; then
  proj_status=$(_dash_get_project_status ~/projects/dev-tools/flow-cli/.STATUS)
  if [[ "$proj_status" == "active" ]]; then
    test_pass
  else
    test_fail "Expected 'active', got '$proj_status'"
  fi
else
  test_fail ".STATUS file not found"
fi

test_start "_dash_get_project_progress parses Markdown format"
if [[ -f ~/projects/dev-tools/flow-cli/.STATUS ]]; then
  proj_progress=$(_dash_get_project_progress ~/projects/dev-tools/flow-cli/.STATUS)
  if [[ "$proj_progress" =~ ^[0-9]+$ ]]; then
    test_pass
  else
    test_fail "Expected number, got '$proj_progress'"
  fi
else
  test_fail ".STATUS file not found"
fi

test_start "_dash_get_project_focus parses Focus field"
if [[ -f ~/projects/dev-tools/flow-cli/.STATUS ]]; then
  proj_focus=$(_dash_get_project_focus ~/projects/dev-tools/flow-cli/.STATUS)
  if [[ -n "$proj_focus" ]]; then
    test_pass
  else
    test_fail "Focus is empty"
  fi
else
  test_fail ".STATUS file not found"
fi

# ============================================================================
# ALIAS TESTS
# ============================================================================

echo ""
echo "── Aliases ──"

test_start "'d' alias works"
output=$(d 2>&1)
if check_no_errors "$output" "d alias"; then
  if [[ "$output" == *"FLOW DASHBOARD"* ]]; then
    test_pass
  else
    test_fail "Missing dashboard output"
  fi
fi

# ============================================================================
# RESULTS
# ============================================================================

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  RESULTS"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "  Tests run:    $TESTS_RUN"
echo "  ${GREEN}Passed:       $TESTS_PASSED${RESET}"
echo "  ${RED}Failed:       $TESTS_FAILED${RESET}"
echo ""

if (( TESTS_FAILED == 0 )); then
  echo "${GREEN}✓ All tests passed!${RESET}"
  exit 0
else
  echo "${RED}✗ Some tests failed${RESET}"
  exit 1
fi
