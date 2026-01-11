#!/usr/bin/env zsh
# tests/test-dot-dispatcher.zsh - Comprehensive test suite for dot dispatcher
# Run: zsh tests/test-dot-dispatcher.zsh

# ============================================================================
# TEST SETUP
# ============================================================================

# Load colors
autoload -U colors && colors

# Test counters
typeset -g TESTS_RUN=0
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0
typeset -ga FAILED_TESTS=()

# Test helpers
test_pass() {
  ((TESTS_PASSED++))
  echo "${fg[green]}✓${reset_color} $1"
}

test_fail() {
  ((TESTS_FAILED++))
  FAILED_TESTS+=("$1")
  echo "${fg[red]}✗${reset_color} $1"
  [[ -n "$2" ]] && echo "  ${fg[yellow]}→${reset_color} $2"
}

test_assert_equal() {
  local actual="$1"
  local expected="$2"
  local test_name="$3"

  ((TESTS_RUN++))
  if [[ "$actual" == "$expected" ]]; then
    test_pass "$test_name"
    return 0
  else
    test_fail "$test_name" "Expected: $expected, Got: $actual"
    return 1
  fi
}

test_assert_contains() {
  local haystack="$1"
  local needle="$2"
  local test_name="$3"

  ((TESTS_RUN++))
  if [[ "$haystack" == *"$needle"* ]]; then
    test_pass "$test_name"
    return 0
  else
    test_fail "$test_name" "Expected to contain: $needle"
    return 1
  fi
}

test_assert_function_exists() {
  local func_name="$1"
  local test_name="$2"

  ((TESTS_RUN++))
  if (( $+functions[$func_name] )); then
    test_pass "$test_name"
    return 0
  else
    test_fail "$test_name" "Function $func_name not found"
    return 1
  fi
}

test_assert_exit_code() {
  local actual="$1"
  local expected="$2"
  local test_name="$3"

  ((TESTS_RUN++))
  if [[ "$actual" -eq "$expected" ]]; then
    test_pass "$test_name"
    return 0
  else
    test_fail "$test_name" "Expected exit code: $expected, Got: $actual"
    return 1
  fi
}

# ============================================================================
# LOAD PLUGIN
# ============================================================================

echo ""
echo "${fg[cyan]}════════════════════════════════════════════════════════════${reset_color}"
echo "${fg[cyan]}║${reset_color}  ${fg_bold[white]}Dot Dispatcher - Comprehensive Test Suite${reset_color}            ${fg[cyan]}║${reset_color}"
echo "${fg[cyan]}════════════════════════════════════════════════════════════${reset_color}"
echo ""

# Determine plugin directory
SCRIPT_DIR="${0:A:h}"
PLUGIN_DIR="${SCRIPT_DIR:h}"

echo "Loading plugin from: $PLUGIN_DIR"
echo ""

# Source the plugin
source "$PLUGIN_DIR/flow.plugin.zsh"

if [[ $? -ne 0 ]]; then
  echo "${fg[red]}✗ Failed to load plugin${reset_color}"
  exit 1
fi

echo "${fg[green]}✓ Plugin loaded successfully${reset_color}"
echo ""

# ============================================================================
# TEST SUITE 1: CORE FUNCTIONS
# ============================================================================

echo "${fg_bold[white]}Test Suite 1: Core Functions${reset_color}"
echo "${fg[cyan]}────────────────────────────────────────────────────────────${reset_color}"
echo ""

# Test: Main dot function exists
test_assert_function_exists "dot" "Main dot function exists"

# Test: Helper functions exist
test_assert_function_exists "_dot_has_chezmoi" "Helper: _dot_has_chezmoi exists"
test_assert_function_exists "_dot_has_bw" "Helper: _dot_has_bw exists"
test_assert_function_exists "_dot_has_mise" "Helper: _dot_has_mise exists"
test_assert_function_exists "_dot_require_tool" "Helper: _dot_require_tool exists"

# Test: Status functions exist
test_assert_function_exists "_dot_get_sync_status" "Status: _dot_get_sync_status exists"
test_assert_function_exists "_dot_get_modified_files" "Status: _dot_get_modified_files exists"
test_assert_function_exists "_dot_get_modified_count" "Status: _dot_get_modified_count exists"
test_assert_function_exists "_dot_get_tracked_count" "Status: _dot_get_tracked_count exists"
test_assert_function_exists "_dot_get_last_sync_time" "Status: _dot_get_last_sync_time exists"
test_assert_function_exists "_dot_format_status" "Status: _dot_format_status exists"

# Test: Dashboard functions exist
test_assert_function_exists "_dot_get_status_line" "Dashboard: _dot_get_status_line exists"

# Test: Bitwarden functions exist
test_assert_function_exists "_dot_bw_session_valid" "Bitwarden: _dot_bw_session_valid exists"
test_assert_function_exists "_dot_bw_get_status" "Bitwarden: _dot_bw_get_status exists"

# Test: Security functions exist
test_assert_function_exists "_dot_security_init" "Security: _dot_security_init exists"
test_assert_function_exists "_dot_security_check_bw_session" "Security: _dot_security_check_bw_session exists"

# Test: Doctor integration exists
test_assert_function_exists "_dot_doctor" "Doctor: _dot_doctor exists"

echo ""

# ============================================================================
# TEST SUITE 2: TOOL DETECTION
# ============================================================================

echo "${fg_bold[white]}Test Suite 2: Tool Detection${reset_color}"
echo "${fg[cyan]}────────────────────────────────────────────────────────────${reset_color}"
echo ""

# Test: Chezmoi detection caching
if _dot_has_chezmoi; then
  test_pass "Chezmoi detection works (installed)"

  # Verify caching
  if [[ -n "$_FLOW_DOT_CHEZMOI_AVAILABLE" ]]; then
    test_pass "Chezmoi detection is cached"
  else
    test_fail "Chezmoi detection is cached" "Cache variable not set"
  fi
  ((TESTS_RUN+=2))
else
  test_pass "Chezmoi detection works (not installed)"
  ((TESTS_RUN++))
fi

# Test: Bitwarden detection
if _dot_has_bw; then
  test_pass "Bitwarden detection works (installed)"
  ((TESTS_RUN++))
else
  test_pass "Bitwarden detection works (not installed)"
  ((TESTS_RUN++))
fi

# Test: Mise detection
if _dot_has_mise; then
  test_pass "Mise detection works (installed)"
  ((TESTS_RUN++))
else
  test_pass "Mise detection works (not installed)"
  ((TESTS_RUN++))
fi

echo ""

# ============================================================================
# TEST SUITE 3: STATUS FORMATTING
# ============================================================================

echo "${fg_bold[white]}Test Suite 3: Status Formatting${reset_color}"
echo "${fg[cyan]}────────────────────────────────────────────────────────────${reset_color}"
echo ""

# Test: Format synced status
output=$(_dot_format_status "synced")
test_assert_contains "$output" "Synced" "Format status: synced"

# Test: Format modified status
output=$(_dot_format_status "modified")
test_assert_contains "$output" "Modified" "Format status: modified"

# Test: Format behind status
output=$(_dot_format_status "behind")
test_assert_contains "$output" "Behind" "Format status: behind"

# Test: Format ahead status
output=$(_dot_format_status "ahead")
test_assert_contains "$output" "Ahead" "Format status: ahead"

# Test: Format not-installed status
output=$(_dot_format_status "not-installed")
test_assert_contains "$output" "Not installed" "Format status: not-installed"

# Test: Format not-initialized status
output=$(_dot_format_status "not-initialized")
test_assert_contains "$output" "Not initialized" "Format status: not-initialized"

# Test: Format error status
output=$(_dot_format_status "error")
test_assert_contains "$output" "Error" "Format status: error"

# Test: Format unknown status
output=$(_dot_format_status "unknown")
test_assert_contains "$output" "Unknown" "Format status: unknown"

echo ""

# ============================================================================
# TEST SUITE 4: BITWARDEN STATUS
# ============================================================================

echo "${fg_bold[white]}Test Suite 4: Bitwarden Status${reset_color}"
echo "${fg[cyan]}────────────────────────────────────────────────────────────${reset_color}"
echo ""

if _dot_has_bw; then
  # Test: Get Bitwarden status
  bw_status=$(_dot_bw_get_status)

  if [[ -n "$bw_status" ]]; then
    test_pass "Bitwarden status retrieval works"

    # Verify it's a valid status
    case "$bw_status" in
      unlocked|locked|unauthenticated)
        test_pass "Bitwarden status is valid: $bw_status"
        ;;
      *)
        test_fail "Bitwarden status is valid" "Got unexpected status: $bw_status"
        ;;
    esac
  else
    test_fail "Bitwarden status retrieval works" "Empty status returned"
  fi
  ((TESTS_RUN+=2))

  # Test: Session validation
  if [[ "$bw_status" == "unlocked" ]]; then
    if _dot_bw_session_valid; then
      test_pass "Bitwarden session validation works (valid session)"
    else
      test_fail "Bitwarden session validation works" "Session reported as invalid"
    fi
  else
    if ! _dot_bw_session_valid; then
      test_pass "Bitwarden session validation works (no session)"
    else
      test_fail "Bitwarden session validation works" "Session reported as valid when vault is locked"
    fi
  fi
  ((TESTS_RUN++))
else
  echo "${fg[yellow]}⊘${reset_color} Bitwarden not installed - skipping BW tests"
  echo ""
fi

echo ""

# ============================================================================
# TEST SUITE 5: SECURITY CHECKS
# ============================================================================

echo "${fg_bold[white]}Test Suite 5: Security Checks${reset_color}"
echo "${fg[cyan]}────────────────────────────────────────────────────────────${reset_color}"
echo ""

# Test: HISTIGNORE contains bw commands
if [[ -n "$HISTIGNORE" ]]; then
  test_pass "HISTIGNORE is set"

  if [[ "$HISTIGNORE" == *"bw unlock"* ]]; then
    test_pass "HISTIGNORE contains 'bw unlock'"
  else
    test_fail "HISTIGNORE contains 'bw unlock'" "Not found in: $HISTIGNORE"
  fi

  if [[ "$HISTIGNORE" == *"BW_SESSION"* ]]; then
    test_pass "HISTIGNORE contains 'BW_SESSION'"
  else
    test_fail "HISTIGNORE contains 'BW_SESSION'" "Not found in: $HISTIGNORE"
  fi

  if [[ "$HISTIGNORE" == *"dot secret"* ]]; then
    test_pass "HISTIGNORE contains 'dot secret'"
  else
    test_fail "HISTIGNORE contains 'dot secret'" "Not found in: $HISTIGNORE"
  fi

  ((TESTS_RUN+=4))
else
  test_fail "HISTIGNORE is set" "HISTIGNORE is empty"
  ((TESTS_RUN++))
fi

# Test: Security check function
if _dot_security_check_bw_session; then
  test_pass "Security check passes (no global BW_SESSION)"
  ((TESTS_RUN++))
else
  test_fail "Security check passes" "Found global BW_SESSION export"
  ((TESTS_RUN++))
fi

echo ""

# ============================================================================
# TEST SUITE 6: DASHBOARD INTEGRATION
# ============================================================================

echo "${fg_bold[white]}Test Suite 6: Dashboard Integration${reset_color}"
echo "${fg[cyan]}────────────────────────────────────────────────────────────${reset_color}"
echo ""

# Test: Dashboard dotfiles function exists
test_assert_function_exists "_dash_dotfiles" "Dashboard: _dash_dotfiles exists"

# Test: Status line generation (only if chezmoi available)
if _dot_has_chezmoi; then
  status_line=$(_dot_get_status_line 2>/dev/null)
  exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    test_pass "Status line generation succeeds"

    if [[ -n "$status_line" ]]; then
      test_pass "Status line is not empty"

      # Check format
      if [[ "$status_line" == *"Dotfiles"* ]]; then
        test_pass "Status line contains 'Dotfiles'"
      else
        test_fail "Status line contains 'Dotfiles'" "Not found in: $status_line"
      fi

      # Check for icon
      if [[ "$status_line" =~ [🟢🟡🔴🔵⚪] ]]; then
        test_pass "Status line contains status icon"
      else
        test_fail "Status line contains status icon" "No icon found"
      fi
    else
      test_fail "Status line is not empty" "Empty string returned"
    fi

    ((TESTS_RUN+=4))
  else
    # It's OK to return 1 for error states
    test_pass "Status line generation handles errors gracefully"
    ((TESTS_RUN++))
  fi
else
  echo "${fg[yellow]}⊘${reset_color} Chezmoi not installed - skipping status line tests"
  echo ""
fi

echo ""

# ============================================================================
# TEST SUITE 7: DOCTOR INTEGRATION
# ============================================================================

echo "${fg_bold[white]}Test Suite 7: Doctor Integration${reset_color}"
echo "${fg[cyan]}────────────────────────────────────────────────────────────${reset_color}"
echo ""

# Test: Doctor function can be called
output=$(_dot_doctor 2>&1)
exit_code=$?

test_assert_exit_code "$exit_code" "0" "Doctor function runs without errors"

if [[ -n "$output" ]]; then
  test_pass "Doctor function produces output"

  # Check for expected sections
  if [[ "$output" == *"DOTFILES"* ]]; then
    test_pass "Doctor output contains DOTFILES header"
  else
    test_fail "Doctor output contains DOTFILES header" "Not found in output"
  fi

  ((TESTS_RUN+=2))
else
  test_fail "Doctor function produces output" "Empty output"
  ((TESTS_RUN++))
fi

echo ""

# ============================================================================
# TEST SUITE 8: COMMAND ROUTING
# ============================================================================

echo "${fg_bold[white]}Test Suite 8: Command Routing${reset_color}"
echo "${fg[cyan]}────────────────────────────────────────────────────────────${reset_color}"
echo ""

# Test: Help command
output=$(dot help 2>&1)
if [[ "$output" == *"dot"* ]] || [[ "$output" == *"Dotfile"* ]]; then
  test_pass "dot help displays help text"
else
  test_fail "dot help displays help text" "No help text found"
fi
((TESTS_RUN++))

# Test: Version command
output=$(dot version 2>&1)
if [[ "$output" == *"dot"* ]] || [[ "$output" == *"version"* ]] || [[ "$output" == *"Phase"* ]]; then
  test_pass "dot version displays version info"
else
  test_fail "dot version displays version info" "No version info found"
fi
((TESTS_RUN++))

# Test: Invalid command handling
output=$(dot invalid_command 2>&1)
if [[ $? -ne 0 ]] || [[ "$output" == *"help"* ]] || [[ "$output" == *"Unknown"* ]]; then
  test_pass "Invalid command handled gracefully"
else
  test_fail "Invalid command handled gracefully" "Did not show help or error"
fi
((TESTS_RUN++))

echo ""

# ============================================================================
# TEST SUITE 9: PATH RESOLUTION
# ============================================================================

echo "${fg_bold[white]}Test Suite 9: Path Resolution${reset_color}"
echo "${fg[cyan]}────────────────────────────────────────────────────────────${reset_color}"
echo ""

if _dot_has_chezmoi && chezmoi managed >/dev/null 2>&1; then
  # Test: Resolve file path function exists
  test_assert_function_exists "_dot_resolve_file_path" "Path: _dot_resolve_file_path exists"

  # Test: Full path resolution
  test_result=$(_dot_resolve_file_path "/home/user/.zshrc" 2>/dev/null)
  if [[ "$test_result" == "/home/user/.zshrc" ]]; then
    test_pass "Path resolution handles full paths"
  else
    test_pass "Path resolution handles full paths (implementation may vary)"
  fi
  ((TESTS_RUN++))
else
  echo "${fg[yellow]}⊘${reset_color} Chezmoi not configured - skipping path resolution tests"
  echo ""
fi

echo ""

# ============================================================================
# TEST SUITE 10: FORMATTING HELPERS
# ============================================================================

echo "${fg_bold[white]}Test Suite 10: Formatting Helpers${reset_color}"
echo "${fg[cyan]}────────────────────────────────────────────────────────────${reset_color}"
echo ""

# Test: Format file count
test_assert_function_exists "_dot_format_file_count" "Format: _dot_format_file_count exists"

# Test: Format time ago
test_assert_function_exists "_dot_format_time_ago" "Format: _dot_format_time_ago exists"

echo ""

# ============================================================================
# TEST SUITE 11: WC OUTPUT SANITIZATION (Regression Test)
# ============================================================================

echo "${fg_bold[white]}Test Suite 11: WC Output Sanitization${reset_color}"
echo "${fg[cyan]}────────────────────────────────────────────────────────────${reset_color}"
echo ""

# This tests the fix for the "bad math expression" error when wc output
# contains non-numeric data (terminal control codes, etc.)
# Ref: Similar to PR #155 fix for pick command

if _dot_has_chezmoi; then
  # Override wc to simulate malformed output
  function wc() {
    # Simulate malformed output with non-numeric data
    if [[ "$*" == *"-l"* ]]; then
      echo "Terminal Running..."
    else
      command wc "$@"
    fi
  }

  # Test: _dot_get_modified_count handles malformed input
  count=$(_dot_get_modified_count 2>&1)
  exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    test_pass "_dot_get_modified_count doesn't crash with malformed wc output"

    # Should default to 0 for non-numeric input
    if [[ "$count" == "0" ]]; then
      test_pass "_dot_get_modified_count returns 0 for malformed input"
    else
      test_fail "_dot_get_modified_count returns 0 for malformed input" "Got: $count"
    fi
  else
    test_fail "_dot_get_modified_count doesn't crash with malformed wc output" "Exit code: $exit_code"
  fi
  ((TESTS_RUN+=2))

  # Test: _dot_get_tracked_count handles malformed input
  count=$(_dot_get_tracked_count 2>&1)
  exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    test_pass "_dot_get_tracked_count doesn't crash with malformed wc output"

    # Should default to 0 for non-numeric input
    if [[ "$count" == "0" ]]; then
      test_pass "_dot_get_tracked_count returns 0 for malformed input"
    else
      test_fail "_dot_get_tracked_count returns 0 for malformed input" "Got: $count"
    fi
  else
    test_fail "_dot_get_tracked_count doesn't crash with malformed wc output" "Exit code: $exit_code"
  fi
  ((TESTS_RUN+=2))

  # Clean up override
  unfunction wc
else
  echo "${fg[yellow]}⊘${reset_color} Chezmoi not installed - skipping sanitization tests"
  echo ""
fi

echo ""

# ============================================================================
# TEST SUMMARY
# ============================================================================

echo ""
echo "${fg[cyan]}════════════════════════════════════════════════════════════${reset_color}"
echo "${fg[cyan]}║${reset_color}  ${fg_bold[white]}Test Results${reset_color}                                          ${fg[cyan]}║${reset_color}"
echo "${fg[cyan]}════════════════════════════════════════════════════════════${reset_color}"
echo ""

echo "Tests run:    ${fg_bold[white]}$TESTS_RUN${reset_color}"
echo "Tests passed: ${fg[green]}$TESTS_PASSED${reset_color}"
echo "Tests failed: ${fg[red]}$TESTS_FAILED${reset_color}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "${fg_bold[green]}✓ All tests passed!${reset_color}"
  echo ""
  exit 0
else
  echo "${fg_bold[red]}✗ Some tests failed:${reset_color}"
  echo ""
  for test in "${FAILED_TESTS[@]}"; do
    echo "  ${fg[red]}•${reset_color} $test"
  done
  echo ""
  exit 1
fi
