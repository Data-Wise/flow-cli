#!/usr/bin/env zsh
# test-alias-management.zsh - Automated tests for alias management commands
# Run with: zsh tests/test-alias-management.zsh
#
# Tests the alias management functionality including:
# - flow alias doctor (health check)
# - flow alias find (search)
# - flow alias add (create)
# - flow alias rm (remove)
# - flow alias test (validate + dry-run)
# - doctor integration (alias section in flow doctor)

# Don't use set -e - we want to continue after failures

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

# Test environment
typeset -g TEST_ZSHRC=""
typeset -g ORIGINAL_ZDOTDIR=""

# ============================================================================
# TEST HELPERS
# ============================================================================

test_start() {
  echo -n "${CYAN}TEST: $1${RESET} ... "
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

assert_equals() {
  local actual="$1"
  local expected="$2"
  local message="${3:-Values should be equal}"

  if [[ "$actual" == "$expected" ]]; then
    return 0
  else
    test_fail "$message (expected: '$expected', got: '$actual')"
    return 1
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-Should contain substring}"

  if [[ "$haystack" == *"$needle"* ]]; then
    return 0
  else
    test_fail "$message (expected to contain: '$needle')"
    return 1
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="${3:-Should NOT contain substring}"

  if [[ "$haystack" != *"$needle"* ]]; then
    return 0
  else
    test_fail "$message (should not contain: '$needle')"
    return 1
  fi
}

assert_exit_code() {
  local expected="$1"
  local actual="$2"
  local message="${3:-Exit code should match}"

  if [[ "$actual" -eq "$expected" ]]; then
    return 0
  else
    test_fail "$message (expected exit: $expected, got: $actual)"
    return 1
  fi
}

assert_function_exists() {
  local func_name="$1"

  if (( $+functions[$func_name] )); then
    return 0
  else
    test_fail "Function '$func_name' should exist"
    return 1
  fi
}

# Strip ANSI codes for easier testing
strip_ansi() {
  echo "$1" | sed 's/\x1b\[[0-9;]*m//g'
}

# ============================================================================
# TEST ENVIRONMENT SETUP
# ============================================================================

setup_test_env() {
  echo ""
  echo "${YELLOW}Setting up test environment...${RESET}"

  # Create temp directory for test zshrc
  TEST_ZSHRC=$(mktemp)

  # Create test aliases in temp file
  cat > "$TEST_ZSHRC" << 'EOF'
# Test .zshrc for alias management tests
# DO NOT MODIFY - auto-generated for testing

# Valid aliases
alias testalias1='echo hello'
alias testalias2='ls -la'
alias testbrew='brew list'

# Alias that shadows a command
alias cat='bat'

# Alias with long command
alias testlong='cd /some/very/long/path/that/exceeds/sixty/characters/for/testing/purposes && echo done'

# Alias with missing target (for broken target test)
alias testbroken='nonexistentcommand123 --flag'

EOF

  # Save original ZDOTDIR and set to temp
  ORIGINAL_ZDOTDIR="$ZDOTDIR"
  export ZDOTDIR="$(dirname $TEST_ZSHRC)"

  # Rename temp file to .zshrc
  mv "$TEST_ZSHRC" "$ZDOTDIR/.zshrc"
  TEST_ZSHRC="$ZDOTDIR/.zshrc"

  echo "  Test zshrc: $TEST_ZSHRC"
  echo ""
}

cleanup_test_env() {
  echo ""
  echo "${YELLOW}Cleaning up test environment...${RESET}"

  # Restore ZDOTDIR
  if [[ -n "$ORIGINAL_ZDOTDIR" ]]; then
    export ZDOTDIR="$ORIGINAL_ZDOTDIR"
  else
    unset ZDOTDIR
  fi

  # Remove temp files
  if [[ -n "$TEST_ZSHRC" && -f "$TEST_ZSHRC" ]]; then
    rm -f "$TEST_ZSHRC"
    rm -f "${TEST_ZSHRC}.alias-backup"
    rmdir "$(dirname $TEST_ZSHRC)" 2>/dev/null
  fi

  echo ""
}

# ============================================================================
# LOAD FLOW-CLI
# ============================================================================

load_flow_cli() {
  echo "${YELLOW}Loading flow-cli...${RESET}"

  # Get the script directory (handle both direct run and sourcing)
  local script_dir
  if [[ -n "${(%):-%x}" ]]; then
    script_dir="${${(%):-%x}:a:h}"
  else
    script_dir="${0:a:h}"
  fi
  local plugin_dir="${script_dir:h}"

  echo "  Plugin dir: $plugin_dir"

  # Source the plugin
  source "$plugin_dir/flow.plugin.zsh"

  if (( $+functions[flow_alias] )); then
    echo "  ${GREEN}✓${RESET} flow_alias loaded"
  else
    echo "  ${RED}✗${RESET} flow_alias not loaded"
    exit 1
  fi

  echo ""
}

# ============================================================================
# TESTS: FUNCTION EXISTENCE
# ============================================================================

run_function_tests() {
  echo ""
  echo "${YELLOW}═══ FUNCTION EXISTENCE TESTS ═══${RESET}"
  echo ""

  test_start "flow_alias function exists"
  if assert_function_exists "flow_alias"; then
    test_pass
  fi

  test_start "_flow_alias_doctor function exists"
  if assert_function_exists "_flow_alias_doctor"; then
    test_pass
  fi

  test_start "_flow_alias_find function exists"
  if assert_function_exists "_flow_alias_find"; then
    test_pass
  fi

  test_start "_flow_alias_add function exists"
  if assert_function_exists "_flow_alias_add"; then
    test_pass
  fi

  test_start "_flow_alias_remove function exists"
  if assert_function_exists "_flow_alias_remove"; then
    test_pass
  fi

  test_start "_flow_alias_test function exists"
  if assert_function_exists "_flow_alias_test"; then
    test_pass
  fi

  test_start "_flow_alias_check_shadow function exists"
  if assert_function_exists "_flow_alias_check_shadow"; then
    test_pass
  fi

  test_start "_flow_alias_check_target function exists"
  if assert_function_exists "_flow_alias_check_target"; then
    test_pass
  fi
}

# ============================================================================
# TESTS: HELP
# ============================================================================

run_help_tests() {
  echo ""
  echo "${YELLOW}═══ HELP TESTS ═══${RESET}"
  echo ""

  test_start "flow alias help shows usage"
  local output=$(flow_alias help 2>&1)
  output=$(strip_ansi "$output")
  if assert_contains "$output" "flow alias" "Should contain command name"; then
    if assert_contains "$output" "doctor" "Should mention doctor command"; then
      test_pass
    fi
  fi

  test_start "flow alias help shows all management commands"
  local output=$(flow_alias help 2>&1)
  output=$(strip_ansi "$output")
  local has_all=true
  for cmd in doctor find edit add rm test; do
    if [[ "$output" != *"$cmd"* ]]; then
      has_all=false
      test_fail "Missing command: $cmd"
      break
    fi
  done
  if $has_all; then
    test_pass
  fi
}

# ============================================================================
# TESTS: DOCTOR
# ============================================================================

run_doctor_tests() {
  echo ""
  echo "${YELLOW}═══ DOCTOR TESTS ═══${RESET}"
  echo ""

  test_start "doctor shows header"
  local output=$(flow_alias doctor 2>&1)
  output=$(strip_ansi "$output")
  if assert_contains "$output" "Alias Health Check" "Should show health check header"; then
    test_pass
  fi

  test_start "doctor finds aliases in test zshrc"
  local output=$(flow_alias doctor 2>&1)
  output=$(strip_ansi "$output")
  if assert_contains "$output" "aliases" "Should count aliases"; then
    test_pass
  fi

  test_start "doctor detects shadow (cat shadows /bin/cat)"
  local output=$(flow_alias doctor 2>&1)
  output=$(strip_ansi "$output")
  if assert_contains "$output" "Shadows" "Should detect shadow"; then
    if assert_contains "$output" "cat" "Should mention cat alias"; then
      test_pass
    fi
  fi

  test_start "doctor detects broken target"
  local output=$(flow_alias doctor 2>&1)
  output=$(strip_ansi "$output")
  if assert_contains "$output" "testbroken" "Should find broken alias"; then
    test_pass
  fi

  test_start "doctor shows summary"
  local output=$(flow_alias doctor 2>&1)
  output=$(strip_ansi "$output")
  if assert_contains "$output" "Summary" "Should show summary"; then
    test_pass
  fi
}

# ============================================================================
# TESTS: FIND
# ============================================================================

run_find_tests() {
  echo ""
  echo "${YELLOW}═══ FIND TESTS ═══${RESET}"
  echo ""

  test_start "find without pattern shows usage"
  local output
  output=$(flow_alias find 2>&1)
  # Note: Exit code lost in subshell, just test output
  output=$(strip_ansi "$output")
  if assert_contains "$output" "Usage" "Should show usage"; then
    test_pass
  fi

  test_start "find matches pattern in alias name"
  local output=$(flow_alias find "testalias" 2>&1)
  output=$(strip_ansi "$output")
  if assert_contains "$output" "testalias1" "Should find testalias1"; then
    if assert_contains "$output" "testalias2" "Should find testalias2"; then
      test_pass
    fi
  fi

  test_start "find matches pattern in command"
  local output=$(flow_alias find "brew" 2>&1)
  output=$(strip_ansi "$output")
  if assert_contains "$output" "testbrew" "Should find testbrew"; then
    test_pass
  fi

  test_start "find shows no results for non-matching pattern"
  local output=$(flow_alias find "zzzznonexistent" 2>&1)
  output=$(strip_ansi "$output")
  if assert_contains "$output" "No aliases found" "Should indicate no matches"; then
    test_pass
  fi
}

# ============================================================================
# TESTS: ADD (validation only - don't actually add)
# ============================================================================

run_add_tests() {
  echo ""
  echo "${YELLOW}═══ ADD TESTS ═══${RESET}"
  echo ""

  test_start "add parses one-liner format"
  # Test with 'n' to decline adding
  local output=$(echo "n" | flow_alias add "newtest='echo test'" 2>&1)
  output=$(strip_ansi "$output")
  if assert_contains "$output" "Preview" "Should show preview"; then
    if assert_contains "$output" "newtest" "Should parse alias name"; then
      test_pass
    fi
  fi

  test_start "add validates target exists"
  local output=$(echo "n" | flow_alias add "validtest='echo hello'" 2>&1)
  output=$(strip_ansi "$output")
  if assert_contains "$output" "Validation passed" "Should pass validation for valid target"; then
    test_pass
  fi

  test_start "add detects duplicate"
  local output=$(echo "n" | flow_alias add "testalias1='echo something'" 2>&1)
  output=$(strip_ansi "$output")
  if assert_contains "$output" "Duplicate" "Should detect duplicate"; then
    test_pass
  fi

  test_start "add detects missing target"
  local output=$(echo "n" | flow_alias add "badtest='nonexistentcmd456'" 2>&1)
  output=$(strip_ansi "$output")
  if assert_contains "$output" "Target not found" "Should detect missing target"; then
    test_pass
  fi

  test_start "add rejects invalid alias name"
  local output
  output=$(flow_alias add "123invalid='echo test'" 2>&1)
  output=$(strip_ansi "$output")
  if assert_contains "$output" "Invalid alias name" "Should reject invalid name"; then
    test_pass
  fi

  test_start "add detects shadow warning"
  local output=$(echo "n" | flow_alias add "ls='eza'" 2>&1)
  output=$(strip_ansi "$output")
  if assert_contains "$output" "Shadow" "Should warn about shadow"; then
    test_pass
  fi
}

# ============================================================================
# TESTS: RM (using test file)
# ============================================================================

run_rm_tests() {
  echo ""
  echo "${YELLOW}═══ RM TESTS ═══${RESET}"
  echo ""

  test_start "rm without name shows usage"
  local output
  output=$(flow_alias rm 2>&1)
  output=$(strip_ansi "$output")
  if assert_contains "$output" "Usage" "Should show usage"; then
    test_pass
  fi

  test_start "rm reports not found for missing alias"
  local output
  output=$(flow_alias rm "nonexistentalias123" 2>&1)
  output=$(strip_ansi "$output")
  if assert_contains "$output" "not found" "Should report not found"; then
    test_pass
  fi

  test_start "rm finds existing alias"
  # Test with 'n' to decline removal
  local output=$(echo "n" | flow_alias rm "testalias1" 2>&1)
  output=$(strip_ansi "$output")
  if assert_contains "$output" "Found" "Should find alias"; then
    if assert_contains "$output" "testalias1" "Should show alias name"; then
      test_pass
    fi
  fi

  test_start "rm shows line number"
  local output=$(echo "n" | flow_alias rm "testalias1" 2>&1)
  output=$(strip_ansi "$output")
  if assert_contains "$output" "Line" "Should show line number"; then
    test_pass
  fi
}

# ============================================================================
# TESTS: TEST COMMAND
# ============================================================================

run_test_tests() {
  echo ""
  echo "${YELLOW}═══ TEST COMMAND TESTS ═══${RESET}"
  echo ""

  test_start "test without name shows usage"
  local output
  output=$(flow_alias test 2>&1)
  output=$(strip_ansi "$output")
  if assert_contains "$output" "Usage" "Should show usage"; then
    test_pass
  fi

  test_start "test reports not found for missing alias"
  local output
  output=$(flow_alias test "nonexistentalias123" 2>&1)
  output=$(strip_ansi "$output")
  if assert_contains "$output" "not found" "Should report not found"; then
    test_pass
  fi

  test_start "test shows definition"
  # Create alias in current shell for testing
  alias testshellalias='echo from shell'
  local output=$(echo "n" | flow_alias test "testshellalias" 2>&1)
  output=$(strip_ansi "$output")
  unalias testshellalias 2>/dev/null
  if assert_contains "$output" "Definition" "Should show definition"; then
    test_pass
  fi

  test_start "test shows validation results"
  alias testshellalias2='echo valid'
  local output=$(echo "n" | flow_alias test "testshellalias2" 2>&1)
  output=$(strip_ansi "$output")
  unalias testshellalias2 2>/dev/null
  if assert_contains "$output" "Validation" "Should show validation"; then
    test_pass
  fi

  test_start "test shows dry-run"
  alias testshellalias3='echo dryrun'
  local output=$(echo "n" | flow_alias test "testshellalias3" 2>&1)
  output=$(strip_ansi "$output")
  unalias testshellalias3 2>/dev/null
  if assert_contains "$output" "Dry-run" "Should show dry-run"; then
    if assert_contains "$output" "Would execute" "Should show what would execute"; then
      test_pass
    fi
  fi
}

# ============================================================================
# TESTS: SHADOW DETECTION
# ============================================================================

run_shadow_tests() {
  echo ""
  echo "${YELLOW}═══ SHADOW DETECTION TESTS ═══${RESET}"
  echo ""

  test_start "_flow_alias_check_shadow detects /bin/cat"
  local result=$(_flow_alias_check_shadow "cat" 2>/dev/null)
  if [[ -n "$result" && "$result" == *"cat"* ]]; then
    test_pass
  else
    test_fail "Should detect cat shadows /bin/cat"
  fi

  test_start "_flow_alias_check_shadow detects /bin/ls"
  local result=$(_flow_alias_check_shadow "ls" 2>/dev/null)
  if [[ -n "$result" && "$result" == *"ls"* ]]; then
    test_pass
  else
    test_fail "Should detect ls shadows /bin/ls"
  fi

  test_start "_flow_alias_check_shadow returns empty for non-command"
  local result=$(_flow_alias_check_shadow "zzzznotacommand" 2>/dev/null)
  if [[ -z "$result" ]]; then
    test_pass
  else
    test_fail "Should return empty for non-command"
  fi
}

# ============================================================================
# TESTS: TARGET CHECK
# ============================================================================

run_target_tests() {
  echo ""
  echo "${YELLOW}═══ TARGET CHECK TESTS ═══${RESET}"
  echo ""

  test_start "_flow_alias_check_target finds echo"
  if _flow_alias_check_target "echo"; then
    test_pass
  else
    test_fail "Should find echo"
  fi

  test_start "_flow_alias_check_target finds ls"
  if _flow_alias_check_target "ls"; then
    test_pass
  else
    test_fail "Should find ls"
  fi

  test_start "_flow_alias_check_target fails for nonexistent"
  if ! _flow_alias_check_target "zzzznonexistentcmd123"; then
    test_pass
  else
    test_fail "Should fail for nonexistent command"
  fi
}

# ============================================================================
# TESTS: DOCTOR INTEGRATION (in flow doctor)
# ============================================================================

run_doctor_integration_tests() {
  echo ""
  echo "${YELLOW}═══ DOCTOR INTEGRATION TESTS ═══${RESET}"
  echo ""

  test_start "_doctor_check_aliases function exists"
  if assert_function_exists "_doctor_check_aliases"; then
    test_pass
  fi

  test_start "_doctor_check_aliases shows ALIASES section"
  local output=$(_doctor_check_aliases 2>&1)
  output=$(strip_ansi "$output")
  if assert_contains "$output" "ALIASES" "Should show ALIASES header"; then
    test_pass
  fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
  echo ""
  echo "${CYAN}╔═══════════════════════════════════════════════════════════╗${RESET}"
  echo "${CYAN}║  ALIAS MANAGEMENT TEST SUITE                              ║${RESET}"
  echo "${CYAN}╚═══════════════════════════════════════════════════════════╝${RESET}"
  echo ""

  # Load flow-cli
  load_flow_cli

  # Setup test environment
  setup_test_env

  # Run all test groups
  run_function_tests
  run_help_tests
  run_doctor_tests
  run_find_tests
  run_add_tests
  run_rm_tests
  run_test_tests
  run_shadow_tests
  run_target_tests
  run_doctor_integration_tests

  # Cleanup
  cleanup_test_env

  # Summary
  echo ""
  echo "${CYAN}═══════════════════════════════════════════════════════════${RESET}"
  echo ""
  echo "${CYAN}SUMMARY${RESET}"
  echo "  Total:  $TESTS_RUN"
  echo "  Passed: ${GREEN}$TESTS_PASSED${RESET}"
  echo "  Failed: ${RED}$TESTS_FAILED${RESET}"
  echo ""

  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}✓ All tests passed!${RESET}"
    echo ""
    return 0
  else
    echo "${RED}✗ Some tests failed${RESET}"
    echo ""
    return 1
  fi
}

# Run if executed directly
if [[ "${(%):-%N}" == "$0" ]]; then
  main "$@"
fi
