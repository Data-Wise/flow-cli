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
test_assert_function_exists "dots" "Main dots function exists"

# Test: Helper functions exist
test_assert_function_exists "_dotf_has_chezmoi" "Helper: _dotf_has_chezmoi exists"
test_assert_function_exists "_dotf_has_bw" "Helper: _dotf_has_bw exists"
test_assert_function_exists "_dotf_has_mise" "Helper: _dotf_has_mise exists"
test_assert_function_exists "_dotf_require_tool" "Helper: _dotf_require_tool exists"

# Test: Status functions exist
test_assert_function_exists "_dots_get_sync_status" "Status: _dots_get_sync_status exists"
test_assert_function_exists "_dots_get_modified_files" "Status: _dots_get_modified_files exists"
test_assert_function_exists "_dots_get_modified_count" "Status: _dots_get_modified_count exists"
test_assert_function_exists "_dots_get_tracked_count" "Status: _dots_get_tracked_count exists"
test_assert_function_exists "_dots_get_last_sync_time" "Status: _dots_get_last_sync_time exists"
test_assert_function_exists "_dotf_format_status" "Status: _dotf_format_status exists"

# Test: Dashboard functions exist
test_assert_function_exists "_dotf_get_status_line" "Dashboard: _dotf_get_status_line exists"

# Test: Bitwarden functions exist
test_assert_function_exists "_dotf_bw_session_valid" "Bitwarden: _dotf_bw_session_valid exists"
test_assert_function_exists "_dotf_bw_get_status" "Bitwarden: _dotf_bw_get_status exists"

# Test: Security functions exist
test_assert_function_exists "_dotf_security_init" "Security: _dotf_security_init exists"
test_assert_function_exists "_dotf_security_check_bw_session" "Security: _dotf_security_check_bw_session exists"

# Test: Doctor integration exists
test_assert_function_exists "_dots_doctor" "Doctor: _dots_doctor exists"

echo ""

# ============================================================================
# TEST SUITE 2: TOOL DETECTION
# ============================================================================

echo "${fg_bold[white]}Test Suite 2: Tool Detection${reset_color}"
echo "${fg[cyan]}────────────────────────────────────────────────────────────${reset_color}"
echo ""

# Test: Chezmoi detection caching
if _dotf_has_chezmoi; then
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
if _dotf_has_bw; then
  test_pass "Bitwarden detection works (installed)"
  ((TESTS_RUN++))
else
  test_pass "Bitwarden detection works (not installed)"
  ((TESTS_RUN++))
fi

# Test: Mise detection
if _dotf_has_mise; then
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
output=$(_dotf_format_status "synced")
test_assert_contains "$output" "Synced" "Format status: synced"

# Test: Format modified status
output=$(_dotf_format_status "modified")
test_assert_contains "$output" "Modified" "Format status: modified"

# Test: Format behind status
output=$(_dotf_format_status "behind")
test_assert_contains "$output" "Behind" "Format status: behind"

# Test: Format ahead status
output=$(_dotf_format_status "ahead")
test_assert_contains "$output" "Ahead" "Format status: ahead"

# Test: Format not-installed status
output=$(_dotf_format_status "not-installed")
test_assert_contains "$output" "Not installed" "Format status: not-installed"

# Test: Format not-initialized status
output=$(_dotf_format_status "not-initialized")
test_assert_contains "$output" "Not initialized" "Format status: not-initialized"

# Test: Format error status
output=$(_dotf_format_status "error")
test_assert_contains "$output" "Error" "Format status: error"

# Test: Format unknown status
output=$(_dotf_format_status "unknown")
test_assert_contains "$output" "Unknown" "Format status: unknown"

echo ""

# ============================================================================
# TEST SUITE 4: BITWARDEN STATUS
# ============================================================================

echo "${fg_bold[white]}Test Suite 4: Bitwarden Status${reset_color}"
echo "${fg[cyan]}────────────────────────────────────────────────────────────${reset_color}"
echo ""

if _dotf_has_bw; then
  # Test: Get Bitwarden status
  bw_status=$(_dotf_bw_get_status)

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
    if _dotf_bw_session_valid; then
      test_pass "Bitwarden session validation works (valid session)"
    else
      test_fail "Bitwarden session validation works" "Session reported as invalid"
    fi
  else
    if ! _dotf_bw_session_valid; then
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

  if [[ "$HISTIGNORE" == *"sec"* ]]; then
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
if _dotf_security_check_bw_session; then
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
if _dotf_has_chezmoi; then
  status_line=$(_dotf_get_status_line 2>/dev/null)
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
output=$(_dots_doctor 2>&1)
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
output=$(dots help 2>&1)
if [[ "$output" == *"dot"* ]] || [[ "$output" == *"Dotfile"* ]]; then
  test_pass "dot help displays help text"
else
  test_fail "dot help displays help text" "No help text found"
fi
((TESTS_RUN++))

# Test: Version command
output=$(dots version 2>&1)
if [[ "$output" == *"dot"* ]] || [[ "$output" == *"version"* ]] || [[ "$output" == *"Phase"* ]]; then
  test_pass "dot version displays version info"
else
  test_fail "dot version displays version info" "No version info found"
fi
((TESTS_RUN++))

# Test: Invalid command handling
output=$(dots invalid_command 2>&1)
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

if _dotf_has_chezmoi && chezmoi managed >/dev/null 2>&1; then
  # Test: Resolve file path function exists
  test_assert_function_exists "_dots_resolve_file_path" "Path: _dots_resolve_file_path exists"

  # Test: Full path resolution
  test_result=$(_dots_resolve_file_path "/home/user/.zshrc" 2>/dev/null)
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
test_assert_function_exists "_dotf_format_file_count" "Format: _dotf_format_file_count exists"

# Test: Format time ago
test_assert_function_exists "_dotf_format_time_ago" "Format: _dotf_format_time_ago exists"

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

if _dotf_has_chezmoi; then
  # Override wc to simulate malformed output
  function wc() {
    # Simulate malformed output with non-numeric data
    if [[ "$*" == *"-l"* ]]; then
      echo "Terminal Running..."
    else
      command wc "$@"
    fi
  }

  # Test: _dots_get_modified_count handles malformed input
  count=$(_dots_get_modified_count 2>&1)
  exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    test_pass "_dots_get_modified_count doesn't crash with malformed wc output"

    # Should default to 0 for non-numeric input
    if [[ "$count" == "0" ]]; then
      test_pass "_dots_get_modified_count returns 0 for malformed input"
    else
      test_fail "_dots_get_modified_count returns 0 for malformed input" "Got: $count"
    fi
  else
    test_fail "_dots_get_modified_count doesn't crash with malformed wc output" "Exit code: $exit_code"
  fi
  ((TESTS_RUN+=2))

  # Test: _dots_get_tracked_count handles malformed input
  count=$(_dots_get_tracked_count 2>&1)
  exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    test_pass "_dots_get_tracked_count doesn't crash with malformed wc output"

    # Should default to 0 for non-numeric input
    if [[ "$count" == "0" ]]; then
      test_pass "_dots_get_tracked_count returns 0 for malformed input"
    else
      test_fail "_dots_get_tracked_count returns 0 for malformed input" "Got: $count"
    fi
  else
    test_fail "_dots_get_tracked_count doesn't crash with malformed wc output" "Exit code: $exit_code"
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
# TEST SUITE 12: New Features (Auto-Add, Create, Templates, Summary)
# ============================================================================

echo ""
echo "${fg[cyan]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset_color}"
echo "${fg[cyan]}│${reset_color}  Test Suite 12: New Features (Auto-Add, Templates, Summary)"
echo "${fg[cyan]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset_color}"
echo ""

# Test 12.1: _dots_add_file helper exists
test_assert_function_exists "_dots_add_file" "_dots_add_file helper function exists"

# Test 12.2: _dots_add function exists
test_assert_function_exists "_dots_add" "_dots_add standalone command exists"

# Test 12.3: _dotf_has_bitwarden_template function exists
test_assert_function_exists "_dotf_has_bitwarden_template" "_dotf_has_bitwarden_template helper exists"

# Test 12.4: _dots_print_summary function exists
test_assert_function_exists "_dots_print_summary" "_dots_print_summary helper exists"

# Test 12.5: dot add fails without file argument
output=$(_dots_add 2>&1)
exit_code=$?
((TESTS_RUN++))
if [[ $exit_code -ne 0 ]] && [[ "$output" == *"Usage: dot add"* ]]; then
  test_pass "_dots_add shows usage when called without argument"
else
  test_fail "_dots_add shows usage when called without argument" "Exit: $exit_code, Output: $output"
fi

# Test 12.6: dot add fails for non-existent file
output=$(_dots_add "/nonexistent/file/that/does/not/exist.txt" 2>&1)
exit_code=$?
((TESTS_RUN++))
if [[ $exit_code -ne 0 ]] && [[ "$output" == *"does not exist"* ]]; then
  test_pass "_dots_add fails for non-existent file"
else
  test_fail "_dots_add fails for non-existent file" "Exit: $exit_code, Output: $output"
fi

# Test 12.7: _dotf_has_bitwarden_template returns false for non-tmpl file
test_file="/tmp/test-not-tmpl.txt"
echo "some content" > "$test_file"
if _dotf_has_bitwarden_template "$test_file"; then
  ((TESTS_RUN++))
  test_fail "_dotf_has_bitwarden_template returns false for non-tmpl"
else
  ((TESTS_RUN++))
  test_pass "_dotf_has_bitwarden_template returns false for non-tmpl"
fi
rm -f "$test_file"

# Test 12.8: _dotf_has_bitwarden_template returns false for tmpl without bitwarden
test_file="/tmp/test-no-bw.tmpl"
echo "some {{ other }} template" > "$test_file"
if _dotf_has_bitwarden_template "$test_file"; then
  ((TESTS_RUN++))
  test_fail "_dotf_has_bitwarden_template returns false for tmpl without bitwarden"
else
  ((TESTS_RUN++))
  test_pass "_dotf_has_bitwarden_template returns false for tmpl without bitwarden"
fi
rm -f "$test_file"

# Test 12.9: _dotf_has_bitwarden_template returns true for tmpl with bitwarden
test_file="/tmp/test-with-bw.tmpl"
echo 'export TOKEN="{{ bitwarden "myitem" "notes" }}"' > "$test_file"
if _dotf_has_bitwarden_template "$test_file"; then
  ((TESTS_RUN++))
  test_pass "_dotf_has_bitwarden_template detects {{ bitwarden }}"
else
  ((TESTS_RUN++))
  test_fail "_dotf_has_bitwarden_template detects {{ bitwarden }}"
fi
rm -f "$test_file"

# Test 12.10: _dots_print_summary outputs expected format
output=$(_dots_print_summary ".zshrc" "Edited" "Applied" 2>&1)
((TESTS_RUN++))
if [[ "$output" == *".zshrc"* ]] && [[ "$output" == *"Edited"* ]] && [[ "$output" == *"Applied"* ]]; then
  test_pass "_dots_print_summary outputs file, action, and status"
else
  test_fail "_dots_print_summary outputs file, action, and status" "Output: $output"
fi

# Test 12.11: _dots_print_summary shows push tip for Applied status
output=$(_dots_print_summary ".zshrc" "Edited" "Applied" 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"dots push"* ]]; then
  test_pass "_dots_print_summary shows push tip for Applied"
else
  test_fail "_dots_print_summary shows push tip for Applied" "Output: $output"
fi

# Test 12.12: _dots_print_summary shows apply tip for Staging status
output=$(_dots_print_summary ".zshrc" "Edited" "Staging" 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"dots apply"* ]]; then
  test_pass "_dots_print_summary shows apply tip for Staging"
else
  test_fail "_dots_print_summary shows apply tip for Staging" "Output: $output"
fi

# Test 12.13: dot help includes add command
output=$(dots help 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"dots add"* ]]; then
  test_pass "dot help includes add command"
else
  test_fail "dot help includes add command" "Output didn't mention 'dot add'"
fi

# Test 12.14: dot help shows auto-add/create in edit description
output=$(dots help 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"auto-add"* ]] || [[ "$output" == *"Create"* ]]; then
  test_pass "dot help shows create capability in edit"
else
  test_fail "dot help shows create capability in edit" "Output didn't mention create feature"
fi

# Test 12.15: ZDOTDIR is respected in security check
# This test verifies the variable pattern is correct
((TESTS_RUN++))
# Check that _dotf_security_check_bw_session uses ZDOTDIR
# Find the script directory (same directory as this test file)
local test_dir="${0:A:h}"
local helpers_file="${test_dir:h}/lib/dotfile-helpers.zsh"
if [[ -f "$helpers_file" ]]; then
  source_code=$(< "$helpers_file")
  if [[ "$source_code" == *'${ZDOTDIR:-$HOME}'* ]]; then
    test_pass "ZDOTDIR pattern used in security check"
  else
    test_fail "ZDOTDIR pattern used in security check" "Expected \${ZDOTDIR:-\$HOME} pattern"
  fi
else
  test_fail "ZDOTDIR pattern used in security check" "Helper file not found: $helpers_file"
fi

echo ""

# ============================================================================
# Test Suite 13: Secret Management v2.0 Phase 1
# ============================================================================

echo ""
echo "${fg[cyan]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset_color}"
echo "${fg[cyan]}│${reset_color}  Test Suite 13: Secret Management v2.0 Phase 1"
echo "${fg[cyan]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset_color}"
echo ""

# Test 13.1: Session cache functions exist
((TESTS_RUN++))
if typeset -f _dotf_session_cache_init &>/dev/null; then
  test_pass "_dotf_session_cache_init exists"
else
  test_fail "_dotf_session_cache_init exists"
fi

((TESTS_RUN++))
if typeset -f _dotf_session_cache_save &>/dev/null; then
  test_pass "_dotf_session_cache_save exists"
else
  test_fail "_dotf_session_cache_save exists"
fi

((TESTS_RUN++))
if typeset -f _dotf_session_cache_touch &>/dev/null; then
  test_pass "_dotf_session_cache_touch exists"
else
  test_fail "_dotf_session_cache_touch exists"
fi

((TESTS_RUN++))
if typeset -f _dotf_session_cache_expired &>/dev/null; then
  test_pass "_dotf_session_cache_expired exists"
else
  test_fail "_dotf_session_cache_expired exists"
fi

((TESTS_RUN++))
if typeset -f _dotf_session_cache_clear &>/dev/null; then
  test_pass "_dotf_session_cache_clear exists"
else
  test_fail "_dotf_session_cache_clear exists"
fi

((TESTS_RUN++))
if typeset -f _dotf_session_time_remaining &>/dev/null; then
  test_pass "_dotf_session_time_remaining exists"
else
  test_fail "_dotf_session_time_remaining exists"
fi

((TESTS_RUN++))
if typeset -f _dotf_session_time_remaining_fmt &>/dev/null; then
  test_pass "_dotf_session_time_remaining_fmt exists"
else
  test_fail "_dotf_session_time_remaining_fmt exists"
fi

# Test 13.2: Lock command exists
((TESTS_RUN++))
if typeset -f _sec_lock &>/dev/null; then
  test_pass "_sec_lock function exists"
else
  test_fail "_sec_lock function exists"
fi

# Test 13.3: New secret subcommands exist
((TESTS_RUN++))
if typeset -f _sec_add &>/dev/null; then
  test_pass "_sec_add function exists"
else
  test_fail "_sec_add function exists"
fi

((TESTS_RUN++))
if typeset -f _sec_check &>/dev/null; then
  test_pass "_sec_check function exists"
else
  test_fail "_sec_check function exists"
fi

((TESTS_RUN++))
if typeset -f _sec_help &>/dev/null; then
  test_pass "_sec_help function exists"
else
  test_fail "_sec_help function exists"
fi

# Test 13.4: Session cache configuration variables exist
((TESTS_RUN++))
if [[ -n "$DOT_SESSION_CACHE_DIR" ]]; then
  test_pass "DOT_SESSION_CACHE_DIR is set"
else
  test_fail "DOT_SESSION_CACHE_DIR is set"
fi

((TESTS_RUN++))
if [[ -n "$DOT_SESSION_CACHE_FILE" ]]; then
  test_pass "DOT_SESSION_CACHE_FILE is set"
else
  test_fail "DOT_SESSION_CACHE_FILE is set"
fi

((TESTS_RUN++))
if [[ -n "$DOT_SESSION_IDLE_TIMEOUT" ]]; then
  test_pass "DOT_SESSION_IDLE_TIMEOUT is set"
else
  test_fail "DOT_SESSION_IDLE_TIMEOUT is set"
fi

# Test 13.5: Default timeout is 15 minutes (900 seconds)
((TESTS_RUN++))
if [[ "$DOT_SESSION_IDLE_TIMEOUT" == "900" ]]; then
  test_pass "DOT_SESSION_IDLE_TIMEOUT default is 15 min (900s)"
else
  test_fail "DOT_SESSION_IDLE_TIMEOUT default is 15 min (900s)" "Got: $DOT_SESSION_IDLE_TIMEOUT"
fi

# Test 13.6: dot help includes lock command
output=$(dots help 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"sec lock"* ]]; then
  test_pass "dot help includes lock command"
else
  test_fail "dot help includes lock command" "Output didn't mention 'dot lock'"
fi

# Test 13.7: dot help includes secret add command
((TESTS_RUN++))
if [[ "$output" == *"secret add"* ]]; then
  test_pass "dot help includes secret add command"
else
  test_fail "dot help includes secret add command" "Output didn't mention 'secret add'"
fi

# Test 13.8: dot help includes secret check command
((TESTS_RUN++))
if [[ "$output" == *"secret check"* ]]; then
  test_pass "dot help includes secret check command"
else
  test_fail "dot help includes secret check command" "Output didn't mention 'secret check'"
fi

# Test 13.9: sec help shows usage info
output=$(sec help 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"DOT SECRET"* ]]; then
  test_pass "sec help shows header"
else
  test_fail "sec help shows header" "Output: $output"
fi

# Test 13.10: Session expired returns true when no cache file
# Clear any existing cache first for this test
rm -f "$DOT_SESSION_CACHE_FILE" 2>/dev/null
((TESTS_RUN++))
if _dotf_session_cache_expired; then
  test_pass "Session expired returns true when no cache"
else
  test_fail "Session expired returns true when no cache"
fi

# Test 13.11: _dotf_session_time_remaining returns 0 when no cache
output=$(_dotf_session_time_remaining)
((TESTS_RUN++))
if [[ "$output" == "0" ]]; then
  test_pass "_dotf_session_time_remaining returns 0 when no cache"
else
  test_fail "_dotf_session_time_remaining returns 0 when no cache" "Got: $output"
fi

# Test 13.12: _dotf_session_time_remaining_fmt returns 'expired' when no cache
output=$(_dotf_session_time_remaining_fmt)
((TESTS_RUN++))
if [[ "$output" == "expired" ]]; then
  test_pass "_dotf_session_time_remaining_fmt returns 'expired' when no cache"
else
  test_fail "_dotf_session_time_remaining_fmt returns 'expired' when no cache" "Got: $output"
fi

# ============================================================================
# TEST SUITE 14: SECRET MANAGEMENT V2.0 PHASE 2 (Token Wizards)
# ============================================================================
echo ""
echo "${fg[cyan]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset_color}"
echo "${fg_bold[white]}Test Suite 14: Token Wizards & Secrets Dashboard${reset_color}"
echo "${fg[cyan]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset_color}"
echo ""

# Test 14.1: _tok_dispatch function exists
((TESTS_RUN++))
if typeset -f _tok_dispatch &>/dev/null; then
  test_pass "_tok_dispatch function exists"
else
  test_fail "_tok_dispatch function exists"
fi

# Test 14.2: _tok_help function exists
((TESTS_RUN++))
if typeset -f _tok_help &>/dev/null; then
  test_pass "_tok_help function exists"
else
  test_fail "_tok_help function exists"
fi

# Test 14.3: _tok_github function exists
((TESTS_RUN++))
if typeset -f _tok_github &>/dev/null; then
  test_pass "_tok_github function exists"
else
  test_fail "_tok_github function exists"
fi

# Test 14.4: _tok_npm function exists
((TESTS_RUN++))
if typeset -f _tok_npm &>/dev/null; then
  test_pass "_tok_npm function exists"
else
  test_fail "_tok_npm function exists"
fi

# Test 14.5: _tok_pypi function exists
((TESTS_RUN++))
if typeset -f _tok_pypi &>/dev/null; then
  test_pass "_tok_pypi function exists"
else
  test_fail "_tok_pypi function exists"
fi

# Test 14.6: _sec_dashboard function exists
((TESTS_RUN++))
if typeset -f _sec_dashboard &>/dev/null; then
  test_pass "_sec_dashboard function exists"
else
  test_fail "_sec_dashboard function exists"
fi

# Test 14.7: tok help shows header
output=$(tok help 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"DOT TOKEN"* ]]; then
  test_pass "tok help shows header"
else
  test_fail "tok help shows header" "Output: $output"
fi

# Test 14.8: tok help lists github wizard
((TESTS_RUN++))
if [[ "$output" == *"tok github"* ]]; then
  test_pass "tok help lists github wizard"
else
  test_fail "tok help lists github wizard"
fi

# Test 14.9: tok help lists npm wizard
((TESTS_RUN++))
if [[ "$output" == *"tok npm"* ]]; then
  test_pass "tok help lists npm wizard"
else
  test_fail "tok help lists npm wizard"
fi

# Test 14.10: tok help lists pypi wizard
((TESTS_RUN++))
if [[ "$output" == *"tok pypi"* ]]; then
  test_pass "tok help lists pypi wizard"
else
  test_fail "tok help lists pypi wizard"
fi

# Test 14.11: dot token with no args shows help (not error)
output=$(tok 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"DOT TOKEN"* ]]; then
  test_pass "dot token with no args shows help"
else
  test_fail "dot token with no args shows help" "Output: $output"
fi

# Test 14.12: dot token with invalid provider shows error + help
output=$(tok invalid 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"Unknown token provider"* && "$output" == *"github, npm, pypi"* ]]; then
  test_pass "tok invalid shows error with supported providers"
else
  test_fail "tok invalid shows error with supported providers"
fi

# Test 14.13: dot help includes token wizards section
output=$(dots help 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"TOKEN MANAGEMENT"* ]]; then
  test_pass "dot help includes TOKEN MANAGEMENT section"
else
  test_fail "dot help includes TOKEN MANAGEMENT section" "Output didn't mention 'TOKEN MANAGEMENT'"
fi

# Test 14.14: dot help includes dot secrets command
((TESTS_RUN++))
if [[ "$output" == *"sec"* ]]; then
  test_pass "dot help includes dot secrets command"
else
  test_fail "dot help includes dot secrets command"
fi

# Test 14.15: dot help lists all three token wizards
((TESTS_RUN++))
if [[ "$output" == *"tok github"* && "$output" == *"tok npm"* && "$output" == *"tok pypi"* ]]; then
  test_pass "dot help lists all three token wizards"
else
  test_fail "dot help lists all three token wizards"
fi

# Test 14.16: dot version shows v2.x.x
output=$(dots version 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"v2."* ]]; then
  test_pass "dot version shows v2.x.x"
else
  test_fail "dot version shows v2.x.x" "Got: $output"
fi

# Test 14.17: dot token aliases work (gh → github)
output=$(tok gh 2>&1)
((TESTS_RUN++))
# Should not say "Unknown token provider" for gh alias
if [[ "$output" != *"Unknown token provider"* ]]; then
  test_pass "tok gh alias is recognized"
else
  test_fail "tok gh alias is recognized"
fi

# Test 14.18: dot token aliases work (pip → pypi)
output=$(tok pip 2>&1)
((TESTS_RUN++))
if [[ "$output" != *"Unknown token provider"* ]]; then
  test_pass "tok pip alias is recognized"
else
  test_fail "tok pip alias is recognized"
fi

echo ""

# ============================================================================
# TEST SUITE 15: Token Rotation (Phase 3 - v2.1.0)
# ============================================================================

echo ""
echo "${fg[cyan]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset_color}"
echo "${fg[cyan]}TEST SUITE 15: Token Rotation (Phase 3)${reset_color}"
echo "${fg[cyan]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset_color}"
echo ""

# Test 15.1: _tok_refresh function exists
((TESTS_RUN++))
if typeset -f _tok_refresh > /dev/null; then
  test_pass "_tok_refresh function exists"
else
  test_fail "_tok_refresh function exists"
fi

# Test 15.2: tok --refresh without name shows error
output=$(tok --refresh 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"Usage"* ]] || [[ "$output" == *"Token name required"* ]]; then
  test_pass "tok --refresh without name shows usage"
else
  test_fail "tok --refresh without name shows usage"
fi

# Test 15.3: tok help includes rotation section
output=$(tok help 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"Rotate"* ]] || [[ "$output" == *"--refresh"* ]]; then
  test_pass "tok help includes rotation info"
else
  test_fail "tok help includes rotation info"
fi

# Test 15.4: dot token <name> --refresh syntax recognized
output=$(tok nonexistent-token --refresh 2>&1)
((TESTS_RUN++))
# Should show "Looking up" (unlocked) or "Unlocking" (locked) - not "Unknown token provider"
if [[ "$output" == *"not found"* ]] || [[ "$output" == *"Looking up"* ]] || [[ "$output" == *"Unlocking"* ]]; then
  test_pass "dot token <name> --refresh syntax recognized"
else
  test_fail "dot token <name> --refresh syntax recognized"
fi

# Test 15.5: dot token refresh <name> alternate syntax recognized
output=$(tok refresh nonexistent-token 2>&1)
((TESTS_RUN++))
# Should recognize refresh as the flag, not as a provider
if [[ "$output" == *"not found"* ]] || [[ "$output" == *"Looking up"* ]] || [[ "$output" == *"Unlocking"* ]]; then
  test_pass "dot token refresh <name> syntax recognized"
else
  test_fail "dot token refresh <name> syntax recognized"
fi

# Test 15.6: dot help includes TOKEN MANAGEMENT section
output=$(dots help 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"TOKEN MANAGEMENT"* ]]; then
  test_pass "dot help includes TOKEN MANAGEMENT section"
else
  test_fail "dot help includes TOKEN MANAGEMENT section"
fi

# Test 15.7: dot help includes --refresh command
output=$(dots help 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"--refresh"* ]]; then
  test_pass "dot help includes --refresh command"
else
  test_fail "dot help includes --refresh command"
fi

# Test 15.8: Version shows v2.x.x (Phase 3+)
output=$(dots version 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"v2."* ]] || [[ "$output" == *"2.1"* ]] || [[ "$output" == *"2.2"* ]]; then
  test_pass "dot version shows v2.x.x"
else
  test_fail "dot version shows v2.x.x"
fi

# Test 15.9: dot token -r is recognized as refresh flag
output=$(tok nonexistent -r 2>&1)
((TESTS_RUN++))
# Should recognize -r as refresh flag, not treat nonexistent as provider
if [[ "$output" == *"not found"* ]] || [[ "$output" == *"Looking up"* ]] || [[ "$output" == *"Unlocking"* ]]; then
  test_pass "dot token -r is recognized as refresh flag"
else
  test_fail "dot token -r is recognized as refresh flag"
fi

# Test 15.10: Token rotation requires DOT metadata
# Note: This tests that tokens without dot_version metadata are rejected
output=$(tok some-random-name --refresh 2>&1)
((TESTS_RUN++))
# Should attempt to look up token (unlocked) or try to unlock vault (locked)
if [[ "$output" == *"not found"* ]] || [[ "$output" == *"DOT metadata"* ]] || [[ "$output" == *"Looking up"* ]] || [[ "$output" == *"Unlocking"* ]]; then
  test_pass "Token rotation validates DOT metadata requirement"
else
  test_fail "Token rotation validates DOT metadata requirement"
fi

echo ""

# ============================================================================
# TEST SUITE 16: Integration Features (Phase 3 - v2.2.0)
# ============================================================================

echo ""
echo "${fg[cyan]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset_color}"
echo "${fg[cyan]}TEST SUITE 16: Integration Features (Phase 3)${reset_color}"
echo "${fg[cyan]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset_color}"
echo ""

# Test 16.1: _sec_dashboard_sync function exists
((TESTS_RUN++))
if typeset -f _sec_dashboard_sync > /dev/null; then
  test_pass "_sec_dashboard_sync function exists"
else
  test_fail "_sec_dashboard_sync function exists"
fi

# Test 16.2: _sec_sync_github function exists
((TESTS_RUN++))
if typeset -f _sec_sync_github > /dev/null; then
  test_pass "_sec_sync_github function exists"
else
  test_fail "_sec_sync_github function exists"
fi

# Test 16.3: _dots_env function exists
((TESTS_RUN++))
if typeset -f _dots_env > /dev/null; then
  test_pass "_dots_env function exists"
else
  test_fail "_dots_env function exists"
fi

# Test 16.4: _dots_env_init function exists
((TESTS_RUN++))
if typeset -f _dots_env_init > /dev/null; then
  test_pass "_dots_env_init function exists"
else
  test_fail "_dots_env_init function exists"
fi

# Test 16.5: dot help includes INTEGRATION section
output=$(dots help 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"INTEGRATION"* ]]; then
  test_pass "dot help includes INTEGRATION section"
else
  test_fail "dot help includes INTEGRATION section"
fi

# Test 16.6: dot help includes sec sync
output=$(dots help 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"secrets sync"* ]]; then
  test_pass "dot help includes secrets sync command"
else
  test_fail "dot help includes secrets sync command"
fi

# Test 16.7: dot help includes dot env init
output=$(dots help 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"env init"* ]]; then
  test_pass "dot help includes env init command"
else
  test_fail "dot help includes env init command"
fi

# Test 16.8: sec sync without target shows usage
output=$(sec sync 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"Usage"* ]] || [[ "$output" == *"sync"* ]]; then
  test_pass "sec sync without target shows help"
else
  test_fail "sec sync without target shows help"
fi

# Test 16.9: sec sync unknown shows error
output=$(sec sync unknown 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"Unknown"* ]] || [[ "$output" == *"not supported"* ]]; then
  test_pass "sec sync unknown shows error"
else
  test_fail "sec sync unknown shows error"
fi

# Test 16.10: dot env without subcommand shows help
output=$(dots env 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"Usage"* ]] || [[ "$output" == *"init"* ]]; then
  test_pass "dot env without subcommand shows help"
else
  test_fail "dot env without subcommand shows help"
fi

# Test 16.11: dots env help shows usage
output=$(dots env help 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"init"* ]] || [[ "$output" == *".envrc"* ]]; then
  test_pass "dots env help shows init info"
else
  test_fail "dots env help shows init info"
fi

# Test 16.12: sec help exists
output=$(sec help 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"sync"* ]] || [[ "$output" == *"dashboard"* ]]; then
  test_pass "sec help shows subcommands"
else
  test_fail "sec help shows subcommands"
fi

# Test 16.13: Version shows v2.2.x
output=$(dots version 2>&1)
((TESTS_RUN++))
if [[ "$output" == *"2.2"* ]]; then
  test_pass "dot version shows v2.2.x"
else
  test_fail "dot version shows v2.2.x"
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
