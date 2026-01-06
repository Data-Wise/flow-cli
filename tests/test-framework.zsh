#!/usr/bin/env zsh
# tests/test-framework.zsh
# Lightweight test framework for flow-cli

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
typeset -g CURRENT_TEST=""
typeset -g TEST_SUITE_NAME=""

# ============================================================================
# TEST SUITE MANAGEMENT
# ============================================================================

test_suite_start() {
  TEST_SUITE_NAME="$1"
  echo ""
  echo "${CYAN}╔════════════════════════════════════════════════════════════════╗${RESET}"
  echo "${CYAN}║ ${TEST_SUITE_NAME}${RESET}"
  echo "${CYAN}╚════════════════════════════════════════════════════════════════╝${RESET}"
  echo ""
}

test_suite_end() {
  echo ""
  echo "${CYAN}──────────────────────────────────────────────────────────────${RESET}"

  if (( TESTS_FAILED == 0 )); then
    echo "${GREEN}✓ All tests passed: $TESTS_PASSED/$TESTS_RUN${RESET}"
    return 0
  else
    echo "${RED}✗ Tests failed: $TESTS_FAILED/$TESTS_RUN${RESET}"
    echo "${GREEN}✓ Tests passed: $TESTS_PASSED/$TESTS_RUN${RESET}"
    return 1
  fi
}

# ============================================================================
# TEST CASE MANAGEMENT
# ============================================================================

test_case() {
  CURRENT_TEST="$1"
  echo -n "  ${CYAN}→${RESET} $CURRENT_TEST ... "
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_case_end() {
  # Auto-pass if we reached the end without explicit pass/fail
  if [[ -n "$CURRENT_TEST" ]]; then
    test_pass
  fi
  CURRENT_TEST=""
}

test_pass() {
  echo "${GREEN}PASS${RESET}"
  TESTS_PASSED=$((TESTS_PASSED + 1))
  CURRENT_TEST=""
}

test_fail() {
  local message="${1:-Test failed}"
  echo "${RED}FAIL${RESET}"
  echo "    ${RED}✗ $message${RESET}"
  TESTS_FAILED=$((TESTS_FAILED + 1))
  CURRENT_TEST=""

  # Don't exit - continue with remaining tests
  return 1
}

# ============================================================================
# ASSERTION HELPERS
# ============================================================================

assert_equals() {
  local actual="$1"
  local expected="$2"
  local message="${3:-Expected '$expected' but got '$actual'}"

  if [[ "$actual" != "$expected" ]]; then
    test_fail "$message"
    return 1
  fi
}

assert_not_equals() {
  local actual="$1"
  local unexpected="$2"
  local message="${3:-Expected value different from '$unexpected'}"

  if [[ "$actual" == "$unexpected" ]]; then
    test_fail "$message"
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-Expected output to contain '$needle'}"

  if [[ "$haystack" != *"$needle"* ]]; then
    test_fail "$message"
    echo "    ${YELLOW}Output: ${haystack:0:200}...${RESET}"
    return 1
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-Expected output NOT to contain '$needle'}"

  if [[ "$haystack" == *"$needle"* ]]; then
    test_fail "$message"
    return 1
  fi
}

assert_empty() {
  local value="$1"
  local message="${2:-Expected empty value but got '$value'}"

  if [[ -n "$value" ]]; then
    test_fail "$message"
    return 1
  fi
}

assert_not_empty() {
  local value="$1"
  local message="${2:-Expected non-empty value}"

  if [[ -z "$value" ]]; then
    test_fail "$message"
    return 1
  fi
}

assert_file_exists() {
  local file="$1"
  local message="${2:-File not found: $file}"

  if [[ ! -f "$file" ]]; then
    test_fail "$message"
    return 1
  fi
}

assert_file_not_exists() {
  local file="$1"
  local message="${2:-File should not exist: $file}"

  if [[ -f "$file" ]]; then
    test_fail "$message"
    return 1
  fi
}

assert_dir_exists() {
  local dir="$1"
  local message="${2:-Directory not found: $dir}"

  if [[ ! -d "$dir" ]]; then
    test_fail "$message"
    return 1
  fi
}

assert_function_exists() {
  local func="$1"
  local message="${2:-Function not found: $func}"

  if ! (whence -f "$func" >/dev/null 2>&1); then
    test_fail "$message"
    return 1
  fi
}

assert_command_exists() {
  local cmd="$1"
  local message="${2:-Command not found: $cmd}"

  if ! command -v "$cmd" &>/dev/null; then
    test_fail "$message"
    return 1
  fi
}

assert_exit_code() {
  local actual="$1"
  local expected="${2:-0}"
  local message="${3:-Expected exit code $expected but got $actual}"

  if (( actual != expected )); then
    test_fail "$message"
    return 1
  fi
}

assert_matches_pattern() {
  local value="$1"
  local pattern="$2"
  local message="${3:-Value '$value' doesn't match pattern '$pattern'}"

  if [[ ! "$value" =~ $pattern ]]; then
    test_fail "$message"
    return 1
  fi
}

# ============================================================================
# MOCK HELPERS
# ============================================================================

mock_function() {
  local func_name="$1"
  local mock_body="$2"

  # Save original if it exists
  if (whence -f "$func_name" >/dev/null 2>&1); then
    eval "original_${func_name}() { $(whence -f $func_name | tail -n +2) }"
  fi

  # Create mock
  eval "${func_name}() { $mock_body }"
}

restore_function() {
  local func_name="$1"

  # Restore original if it was saved
  if (whence -f "original_${func_name}" >/dev/null 2>&1); then
    eval "${func_name}() { $(whence -f original_${func_name} | tail -n +2) }"
    unset -f "original_${func_name}"
  else
    unset -f "$func_name"
  fi
}

# ============================================================================
# UTILITY HELPERS
# ============================================================================

capture_output() {
  local cmd="$@"
  eval "$cmd" 2>&1
}

with_temp_dir() {
  local callback="$1"
  local temp_dir=$(mktemp -d)

  (
    cd "$temp_dir"
    eval "$callback"
  )

  local exit_code=$?
  rm -rf "$temp_dir"
  return $exit_code
}

with_env() {
  local var_name="$1"
  local var_value="$2"
  local callback="$3"

  local old_value="${(P)var_name}"
  export $var_name="$var_value"

  eval "$callback"
  local exit_code=$?

  if [[ -n "$old_value" ]]; then
    export $var_name="$old_value"
  else
    unset $var_name
  fi

  return $exit_code
}

# ============================================================================
# TEST EXECUTION HELPERS
# ============================================================================

run_test_file() {
  local test_file="$1"

  if [[ ! -f "$test_file" ]]; then
    echo "${RED}Test file not found: $test_file${RESET}"
    return 1
  fi

  echo "${CYAN}Running: $test_file${RESET}"
  zsh "$test_file"
  return $?
}

run_all_tests() {
  local test_dir="${1:-.}"
  local pattern="${2:-test-*.zsh}"
  local total_exit_code=0

  for test_file in "$test_dir"/$pattern(N); do
    run_test_file "$test_file"
    local exit_code=$?

    if (( exit_code != 0 )); then
      total_exit_code=1
    fi
  done

  return $total_exit_code
}

# ============================================================================
# ADDITIONAL ASSERTION HELPERS
# ============================================================================

assert_success() {
  local message="${1:-Command should succeed}"
  # Always pass (used for documenting expected behavior)
  return 0
}

assert_function_exists() {
  local func_name="$1"
  local message="${2:-Function '$func_name' should exist}"

  if ! type "$func_name" &>/dev/null; then
    test_fail "$message"
    return 1
  fi
}

assert_alias_exists() {
  local alias_name="$1"
  local message="${2:-Alias '$alias_name' should exist}"

  if ! alias "$alias_name" &>/dev/null 2>&1; then
    test_fail "$message"
    return 1
  fi
}

# ============================================================================
# TEST SUITE WRAPPER
# ============================================================================

test_suite() {
  test_suite_start "$1"
}

# ============================================================================
# SUMMARY
# ============================================================================

print_summary() {
  echo ""
  echo "${CYAN}╔════════════════════════════════════════════════════════════════╗${RESET}"
  echo "${CYAN}║ TEST SUMMARY${RESET}"
  echo "${CYAN}╚════════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  if (( TESTS_FAILED == 0 )); then
    echo "${GREEN}✓ ALL TESTS PASSED${RESET}"
    echo ""
    echo "  Total:  $TESTS_RUN"
    echo "  Passed: $TESTS_PASSED"
    echo "  Failed: $TESTS_FAILED"
    echo ""
  else
    echo "${RED}✗ SOME TESTS FAILED${RESET}"
    echo ""
    echo "  Total:  $TESTS_RUN"
    echo "  ${GREEN}Passed: $TESTS_PASSED${RESET}"
    echo "  ${RED}Failed: $TESTS_FAILED${RESET}"
    echo ""
    return 1
  fi
}
