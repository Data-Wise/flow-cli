#!/usr/bin/env zsh
# e2e-dispatcher-split.zsh - E2E tests for dot → dots/sec/tok split (v7.1.0)
# Run with: zsh tests/e2e-dispatcher-split.zsh
#
# Tests the complete dispatcher split:
#   - All 3 dispatchers load and route correctly
#   - Function naming conventions (_dots_, _sec_, _tok_, _dotf_)
#   - Cross-dispatcher references work
#   - Old `dot` command no longer exists
#   - Help text accuracy for each dispatcher
#   - Subcommand routing for each dispatcher

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

# Counters
typeset -g TESTS_RUN=0
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0

# Resolve paths at script level (before functions override $0)
typeset -g SCRIPT_DIR="${0:A:h}"
typeset -g PROJECT_ROOT="${SCRIPT_DIR}/.."

# ============================================================================
# TEST HELPERS
# ============================================================================

test_start() {
  echo -n "${CYAN}E2E: $1${RESET} ... "
  TESTS_RUN=$((TESTS_RUN + 1))
}

test_pass() {
  echo "${GREEN}✓ PASS${RESET}"
  TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
  echo "${RED}✗ FAIL${RESET}"
  echo "  ${RED}→ $1${RESET}"
  TESTS_FAILED=$((TESTS_FAILED + 1))
}

assert_success() {
  local exit_code=$1
  if (( exit_code == 0 )); then
    return 0
  else
    echo "  ${DIM}Exit code: $exit_code (expected 0)${RESET}"
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" == *"$needle"* ]]; then
    return 0
  else
    echo "  ${DIM}Expected to contain: $needle${RESET}"
    return 1
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    return 0
  else
    echo "  ${DIM}Should NOT contain: $needle${RESET}"
    return 1
  fi
}

assert_function_exists() {
  local func_name="$1"
  if type "$func_name" >/dev/null 2>&1; then
    return 0
  else
    echo "  ${DIM}Function not found: $func_name${RESET}"
    return 1
  fi
}

assert_function_missing() {
  local func_name="$1"
  if ! type "$func_name" >/dev/null 2>&1; then
    return 0
  else
    echo "  ${DIM}Function should NOT exist: $func_name${RESET}"
    return 1
  fi
}

# ============================================================================
# SETUP
# ============================================================================

setup() {
  echo "${CYAN}Loading flow-cli plugin...${RESET}"
  source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null
  if ! type dots >/dev/null 2>&1; then
    echo "${RED}ERROR: Failed to load plugin${RESET}"
    exit 1
  fi
  echo "${GREEN}✓ Plugin loaded${RESET}"
  echo ""
}

print_section() {
  echo ""
  echo "${YELLOW}═══ $1 ═══${RESET}"
}

# ============================================================================
# SCENARIO 1: Dispatcher Registration
# ============================================================================

test_dispatcher_registration() {
  print_section "Scenario 1: Dispatcher Registration"

  test_start "dots() is a shell function"
  if assert_function_exists "dots"; then
    test_pass
  else
    test_fail "dots dispatcher not loaded"
  fi

  test_start "sec() is a shell function"
  if assert_function_exists "sec"; then
    test_pass
  else
    test_fail "sec dispatcher not loaded"
  fi

  test_start "tok() is a shell function"
  if assert_function_exists "tok"; then
    test_pass
  else
    test_fail "tok dispatcher not loaded"
  fi

  test_start "Old dot-dispatcher.zsh is not sourced"
  local dot_source
  dot_source=$(type dot 2>&1)
  if [[ "$dot_source" != *"dot-dispatcher.zsh"* ]]; then
    test_pass
  else
    test_fail "Old dot-dispatcher.zsh is still being sourced"
  fi
}

# ============================================================================
# SCENARIO 2: dots Dispatcher Help & Routing
# ============================================================================

test_dots_dispatcher() {
  print_section "Scenario 2: dots Dispatcher (Dotfiles)"

  test_start "dots help shows MOST COMMON section"
  local output=$(dots help 2>&1)
  if assert_contains "$output" "MOST COMMON"; then
    test_pass
  else
    test_fail "dots help missing MOST COMMON section"
  fi

  test_start "dots help mentions sec and tok"
  if assert_contains "$output" "sec" && assert_contains "$output" "tok"; then
    test_pass
  else
    test_fail "dots help should reference related dispatchers"
  fi

  test_start "dots help does NOT mention 'dot unlock'"
  if assert_not_contains "$output" "dot unlock"; then
    test_pass
  else
    test_fail "dots help still references old dot command"
  fi

  test_start "dots --help routes to help"
  local help_output=$(dots --help 2>&1)
  if assert_contains "$help_output" "MOST COMMON"; then
    test_pass
  else
    test_fail "dots --help didn't route to help"
  fi

  test_start "_dots_status function exists"
  if assert_function_exists "_dots_status"; then
    test_pass
  else
    test_fail "_dots_status not found"
  fi

  test_start "_dots_edit function exists"
  if assert_function_exists "_dots_edit"; then
    test_pass
  else
    test_fail "_dots_edit not found"
  fi

  test_start "_dots_ignore function exists"
  if assert_function_exists "_dots_ignore"; then
    test_pass
  else
    test_fail "_dots_ignore not found"
  fi

  test_start "_dots_doctor function exists"
  if assert_function_exists "_dots_doctor"; then
    test_pass
  else
    test_fail "_dots_doctor not found"
  fi

  test_start "_dots_env function exists"
  if assert_function_exists "_dots_env"; then
    test_pass
  else
    test_fail "_dots_env not found"
  fi
}

# ============================================================================
# SCENARIO 3: sec Dispatcher Help & Routing
# ============================================================================

test_sec_dispatcher() {
  print_section "Scenario 3: sec Dispatcher (Secrets)"

  test_start "sec help shows output"
  local output=$(sec help 2>&1)
  if [[ -n "$output" ]]; then
    test_pass
  else
    test_fail "sec help returned empty output"
  fi

  test_start "sec help mentions unlock/lock"
  if assert_contains "$output" "unlock" && assert_contains "$output" "lock"; then
    test_pass
  else
    test_fail "sec help missing unlock/lock commands"
  fi

  test_start "sec help mentions list/add/delete"
  if assert_contains "$output" "list" && assert_contains "$output" "add"; then
    test_pass
  else
    test_fail "sec help missing CRUD commands"
  fi

  test_start "_sec_unlock function exists"
  if assert_function_exists "_sec_unlock"; then
    test_pass
  else
    test_fail "_sec_unlock not found"
  fi

  test_start "_sec_list function exists"
  if assert_function_exists "_sec_list"; then
    test_pass
  else
    test_fail "_sec_list not found"
  fi

  test_start "_sec_dashboard function exists"
  if assert_function_exists "_sec_dashboard"; then
    test_pass
  else
    test_fail "_sec_dashboard not found"
  fi

  test_start "_sec_sync function exists"
  if assert_function_exists "_sec_sync"; then
    test_pass
  else
    test_fail "_sec_sync not found"
  fi

  test_start "_sec_bw function exists"
  if assert_function_exists "_sec_bw"; then
    test_pass
  else
    test_fail "_sec_bw not found"
  fi

  test_start "_sec_doctor function exists"
  if assert_function_exists "_sec_doctor"; then
    test_pass
  else
    test_fail "_sec_doctor not found"
  fi
}

# ============================================================================
# SCENARIO 4: tok Dispatcher Help & Routing
# ============================================================================

test_tok_dispatcher() {
  print_section "Scenario 4: tok Dispatcher (Tokens)"

  test_start "tok help shows output"
  local output=$(tok help 2>&1)
  if [[ -n "$output" ]]; then
    test_pass
  else
    test_fail "tok help returned empty output"
  fi

  test_start "tok help mentions github/npm/pypi"
  if assert_contains "$output" "github" && assert_contains "$output" "npm" && assert_contains "$output" "pypi"; then
    test_pass
  else
    test_fail "tok help missing provider commands"
  fi

  test_start "_tok_github function exists"
  if assert_function_exists "_tok_github"; then
    test_pass
  else
    test_fail "_tok_github not found"
  fi

  test_start "_tok_npm function exists"
  if assert_function_exists "_tok_npm"; then
    test_pass
  else
    test_fail "_tok_npm not found"
  fi

  test_start "_tok_pypi function exists"
  if assert_function_exists "_tok_pypi"; then
    test_pass
  else
    test_fail "_tok_pypi not found"
  fi

  test_start "_tok_rotate function exists"
  if assert_function_exists "_tok_rotate"; then
    test_pass
  else
    test_fail "_tok_rotate not found"
  fi

  test_start "_tok_expiring function exists"
  if assert_function_exists "_tok_expiring"; then
    test_pass
  else
    test_fail "_tok_expiring not found"
  fi

  test_start "_tok_refresh function exists"
  if assert_function_exists "_tok_refresh"; then
    test_pass
  else
    test_fail "_tok_refresh not found"
  fi

  test_start "_tok_age_days function exists"
  if assert_function_exists "_tok_age_days"; then
    test_pass
  else
    test_fail "_tok_age_days not found"
  fi

  test_start "_tok_doctor function exists"
  if assert_function_exists "_tok_doctor"; then
    test_pass
  else
    test_fail "_tok_doctor not found"
  fi
}

# ============================================================================
# SCENARIO 5: Shared Helper Functions (_dotf_ prefix)
# ============================================================================

test_shared_helpers() {
  print_section "Scenario 5: Shared Helpers (_dotf_ prefix)"

  test_start "_dotf_has_chezmoi exists"
  if assert_function_exists "_dotf_has_chezmoi"; then
    test_pass
  else
    test_fail "_dotf_has_chezmoi not found"
  fi

  test_start "_dotf_require_tool exists"
  if assert_function_exists "_dotf_require_tool"; then
    test_pass
  else
    test_fail "_dotf_require_tool not found"
  fi

  test_start "_dotf_secret_backend exists"
  if assert_function_exists "_dotf_secret_backend"; then
    test_pass
  else
    test_fail "_dotf_secret_backend not found"
  fi

  test_start "_dotf_kc_get exists"
  if assert_function_exists "_dotf_kc_get"; then
    test_pass
  else
    test_fail "_dotf_kc_get not found"
  fi

  test_start "_dotf_kc_add exists"
  if assert_function_exists "_dotf_kc_add"; then
    test_pass
  else
    test_fail "_dotf_kc_add not found"
  fi

  test_start "_dotf_kc_list exists"
  if assert_function_exists "_dotf_kc_list"; then
    test_pass
  else
    test_fail "_dotf_kc_list not found"
  fi

  test_start "_dotf_bw_session_valid exists"
  if assert_function_exists "_dotf_bw_session_valid"; then
    test_pass
  else
    test_fail "_dotf_bw_session_valid not found"
  fi

  test_start "_dots_ignore exists (dispatcher function)"
  if assert_function_exists "_dots_ignore"; then
    test_pass
  else
    test_fail "_dots_ignore not found"
  fi

  test_start "_dotf_check_git_in_path exists"
  if assert_function_exists "_dotf_check_git_in_path"; then
    test_pass
  else
    test_fail "_dotf_check_git_in_path not found"
  fi

  # Verify OLD names are GONE
  test_start "Old _dot_has_chezmoi is REMOVED"
  if assert_function_missing "_dot_has_chezmoi"; then
    test_pass
  else
    test_fail "Old _dot_has_chezmoi still exists"
  fi

  test_start "Old _dot_require_tool is REMOVED"
  if assert_function_missing "_dot_require_tool"; then
    test_pass
  else
    test_fail "Old _dot_require_tool still exists"
  fi

  test_start "Old _dot_kc_get is REMOVED"
  if assert_function_missing "_dot_kc_get"; then
    test_pass
  else
    test_fail "Old _dot_kc_get still exists"
  fi
}

# ============================================================================
# SCENARIO 6: Old Dispatcher Functions Removed
# ============================================================================

test_old_functions_removed() {
  print_section "Scenario 6: Old Dispatcher Functions Removed"

  local -a old_functions=(
    "_dot_help"
    "_dot_status"
    "_dot_edit"
    "_dot_sync"
    "_dot_push"
    "_dot_unlock"
    "_dot_lock"
    "_dot_secret"
    "_dot_token"
    "_dot_token_github"
    "_dot_token_npm"
    "_dot_token_pypi"
    "_dot_token_rotate"
    "_dot_token_expiring"
  )

  for func in "${old_functions[@]}"; do
    test_start "Old ${func}() is REMOVED"
    if assert_function_missing "$func"; then
      test_pass
    else
      test_fail "Old $func still exists"
    fi
  done
}

# ============================================================================
# SCENARIO 7: Dispatcher File Existence
# ============================================================================

test_dispatcher_files() {
  print_section "Scenario 7: Dispatcher Files"

  local lib_dir="$PROJECT_ROOT/lib/dispatchers"

  test_start "dots-dispatcher.zsh exists"
  if [[ -f "$lib_dir/dots-dispatcher.zsh" ]]; then
    test_pass
  else
    test_fail "dots-dispatcher.zsh not found"
  fi

  test_start "sec-dispatcher.zsh exists"
  if [[ -f "$lib_dir/sec-dispatcher.zsh" ]]; then
    test_pass
  else
    test_fail "sec-dispatcher.zsh not found"
  fi

  test_start "tok-dispatcher.zsh exists"
  if [[ -f "$lib_dir/tok-dispatcher.zsh" ]]; then
    test_pass
  else
    test_fail "tok-dispatcher.zsh not found"
  fi

  test_start "Old dot-dispatcher.zsh is REMOVED"
  if [[ ! -f "$lib_dir/dot-dispatcher.zsh" ]]; then
    test_pass
  else
    test_fail "Old dot-dispatcher.zsh still exists"
  fi
}

# ============================================================================
# SCENARIO 8: Completions
# ============================================================================

test_completions() {
  print_section "Scenario 8: Completion Files"

  local comp_dir="$PROJECT_ROOT/completions"

  test_start "_dots completion file exists"
  if [[ -f "$comp_dir/_dots" ]]; then
    test_pass
  else
    test_fail "_dots completion not found"
  fi

  test_start "_sec completion file exists"
  if [[ -f "$comp_dir/_sec" ]]; then
    test_pass
  else
    test_fail "_sec completion not found"
  fi

  test_start "_tok completion file exists"
  if [[ -f "$comp_dir/_tok" ]]; then
    test_pass
  else
    test_fail "_tok completion not found"
  fi

  test_start "Old _dot completion is REMOVED"
  if [[ ! -f "$comp_dir/_dot" ]]; then
    test_pass
  else
    test_fail "Old _dot completion still exists"
  fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
  echo "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo "${CYAN}║${RESET}  ${GREEN}E2E Test: Dispatcher Split dot → dots/sec/tok (v7.1.0)${RESET} ${CYAN}║${RESET}"
  echo "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  setup

  test_dispatcher_registration
  test_dots_dispatcher
  test_sec_dispatcher
  test_tok_dispatcher
  test_shared_helpers
  test_old_functions_removed
  test_dispatcher_files
  test_completions

  # Results
  echo ""
  echo "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo "${CYAN}║${RESET}  ${GREEN}E2E DISPATCHER SPLIT RESULTS${RESET}                             ${CYAN}║${RESET}"
  echo "${CYAN}╠══════════════════════════════════════════════════════════════╣${RESET}"
  echo "${CYAN}║${RESET}  Tests run:    ${YELLOW}$TESTS_RUN${RESET}"
  echo "${CYAN}║${RESET}  Passed:       ${GREEN}$TESTS_PASSED${RESET}"
  echo "${CYAN}║${RESET}  Failed:       ${RED}$TESTS_FAILED${RESET}"

  if (( TESTS_FAILED == 0 )); then
    echo "${CYAN}║${RESET}  Pass rate:    ${GREEN}100%${RESET}"
    echo "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo "${GREEN}All dispatcher split E2E tests passed!${RESET}"
    exit 0
  else
    local pass_rate=$(( 100 * TESTS_PASSED / TESTS_RUN ))
    echo "${CYAN}║${RESET}  Pass rate:    ${YELLOW}${pass_rate}%${RESET}"
    echo "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    echo "${YELLOW}Some tests failed. Review output above.${RESET}"
    exit 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "$0" == *"zsh"* ]]; then
  main
fi
