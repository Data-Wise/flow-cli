#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# DOT DISPATCHER v5.1.1 - UNIT TESTS
# ══════════════════════════════════════════════════════════════════════════════
#
# Tests for isolated functions (no external dependencies required)
# These tests mock external commands to test logic in isolation
#
# Run: zsh tests/test-dot-v5.1.1-unit.zsh
#
# ══════════════════════════════════════════════════════════════════════════════

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
declare -a FAILED_TESTS

# ══════════════════════════════════════════════════════════════════════════════
# TEST FRAMEWORK
# ══════════════════════════════════════════════════════════════════════════════

print_header() {
  echo ""
  echo "${CYAN}═══════════════════════════════════════════════════════════${NC}"
  echo "${BOLD}$1${NC}"
  echo "${CYAN}═══════════════════════════════════════════════════════════${NC}"
}

print_test() {
  echo "${YELLOW}TEST:${NC} $1"
}

print_pass() {
  echo "${GREEN}✓ PASS${NC}: $1"
  ((TESTS_PASSED++))
}

print_fail() {
  echo "${RED}✗ FAIL${NC}: $1"
  echo "  ${YELLOW}→${NC} $2"
  ((TESTS_FAILED++))
  FAILED_TESTS+=("$1")
}

run_test() {
  ((TESTS_RUN++))
}

# ══════════════════════════════════════════════════════════════════════════════
# SETUP
# ══════════════════════════════════════════════════════════════════════════════

setup() {
  # Find flow-cli root - handle both direct execution and sourced
  local script_dir
  if [[ -n "${0:A:h}" ]]; then
    script_dir="${0:A:h}"
  else
    script_dir="$(cd "$(dirname "$0")" && pwd)"
  fi
  export FLOW_CLI_ROOT="${script_dir:h}"

  # Verify the path exists
  if [[ ! -d "$FLOW_CLI_ROOT/lib" ]]; then
    # Try absolute path
    FLOW_CLI_ROOT="/Users/dt/projects/dev-tools/flow-cli"
  fi

  echo "${DIM}FLOW_CLI_ROOT: $FLOW_CLI_ROOT${NC}"

  # Source core first for logging functions
  if [[ -f "$FLOW_CLI_ROOT/lib/core.zsh" ]]; then
    source "$FLOW_CLI_ROOT/lib/core.zsh"
  fi

  # Source the files we're testing
  if [[ -f "$FLOW_CLI_ROOT/lib/dotfile-helpers.zsh" ]]; then
    source "$FLOW_CLI_ROOT/lib/dotfile-helpers.zsh"
  else
    echo "${RED}ERROR: Could not find dotfile-helpers.zsh at $FLOW_CLI_ROOT/lib/dotfile-helpers.zsh${NC}"
    exit 1
  fi

  if [[ -f "$FLOW_CLI_ROOT/lib/dispatchers/dot-dispatcher.zsh" ]]; then
    source "$FLOW_CLI_ROOT/lib/dispatchers/dot-dispatcher.zsh"
  else
    echo "${RED}ERROR: Could not find dot-dispatcher.zsh${NC}"
    exit 1
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE 1: _dots_add_file() Unit Tests
# ══════════════════════════════════════════════════════════════════════════════

test_add_file_rejects_nonexistent() {
  print_test "_dots_add_file rejects non-existent file"
  run_test

  local output
  output=$(_dots_add_file "/nonexistent/path/file.txt" 2>&1)
  local exit_code=$?

  if [[ $exit_code -ne 0 ]] && [[ "$output" == *"does not exist"* ]]; then
    print_pass "_dots_add_file rejects non-existent file"
  else
    print_fail "_dots_add_file rejects non-existent file" "Exit: $exit_code, Output: $output"
  fi
}

test_add_file_expands_tilde() {
  print_test "_dots_add_file expands ~ to HOME"
  run_test

  # Create a temp file in HOME
  local test_file="$HOME/.test-dot-add-tilde-$$"
  echo "test" > "$test_file"

  # Mock chezmoi to just echo what it received
  function chezmoi() {
    if [[ "$1" == "add" ]]; then
      echo "CHEZMOI_ADD: $2"
      return 0
    fi
  }

  local output
  output=$(_dots_add_file "~/.test-dot-add-tilde-$$" 2>&1)

  # Cleanup
  rm -f "$test_file"
  unfunction chezmoi 2>/dev/null

  if [[ "$output" == *"$HOME/.test-dot-add-tilde-$$"* ]] || [[ "$output" == *"Added"* ]]; then
    print_pass "_dots_add_file expands tilde correctly"
  else
    print_fail "_dots_add_file expands tilde correctly" "Output: $output"
  fi
}

test_add_file_handles_relative_paths() {
  print_test "_dots_add_file converts relative paths to absolute"
  run_test

  # Create a temp file in HOME
  local test_file="$HOME/.test-dot-relative-$$"
  echo "test" > "$test_file"

  # Mock chezmoi
  function chezmoi() {
    if [[ "$1" == "add" ]]; then
      # Check if path is absolute
      if [[ "$2" == /* ]]; then
        return 0
      else
        return 1
      fi
    fi
  }

  # Call with relative path (will be converted to $HOME/...)
  local output
  output=$(_dots_add_file ".test-dot-relative-$$" 2>&1)
  local exit_code=$?

  # Cleanup
  rm -f "$test_file"
  unfunction chezmoi 2>/dev/null

  if [[ $exit_code -eq 0 ]]; then
    print_pass "_dots_add_file converts relative to absolute paths"
  else
    print_fail "_dots_add_file converts relative to absolute paths" "Exit: $exit_code"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE 2: _dots_add() Unit Tests
# ══════════════════════════════════════════════════════════════════════════════

test_dots_add_requires_argument() {
  print_test "_dots_add requires file argument"
  run_test

  local output
  output=$(_dots_add 2>&1)
  local exit_code=$?

  if [[ $exit_code -ne 0 ]] && [[ "$output" == *"Usage:"* ]]; then
    print_pass "_dots_add shows usage when no argument"
  else
    print_fail "_dots_add shows usage when no argument" "Exit: $exit_code, Output: $output"
  fi
}

test_dots_add_rejects_nonexistent() {
  print_test "_dots_add rejects non-existent file"
  run_test

  local output
  output=$(_dots_add "/this/file/does/not/exist.txt" 2>&1)
  local exit_code=$?

  if [[ $exit_code -ne 0 ]] && [[ "$output" == *"does not exist"* ]]; then
    print_pass "_dots_add rejects non-existent file"
  else
    print_fail "_dots_add rejects non-existent file" "Exit: $exit_code, Output: $output"
  fi
}

test_dots_add_shows_tip() {
  print_test "_dots_add shows next step tip"
  run_test

  # Create test file
  local test_file="$HOME/.test-dot-add-tip-$$"
  echo "test" > "$test_file"

  # Mock chezmoi commands
  function chezmoi() {
    case "$1" in
      add) return 0 ;;
      managed) echo "" ;;  # Not yet tracked
      source-path) echo "~/.local/share/chezmoi/dot_test" ;;
    esac
  }

  local output
  output=$(_dots_add "$test_file" 2>&1)

  # Cleanup
  rm -f "$test_file"
  unfunction chezmoi 2>/dev/null

  if [[ "$output" == *"Tip:"* ]] && [[ "$output" == *"dots edit"* ]]; then
    print_pass "_dots_add shows edit tip"
  else
    print_fail "_dots_add shows edit tip" "Output: $output"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE 3: _dotf_has_bitwarden_template() Unit Tests
# ══════════════════════════════════════════════════════════════════════════════

test_bw_template_detects_bitwarden() {
  print_test "_dotf_has_bitwarden_template detects {{ bitwarden }}"
  run_test

  local test_file="/tmp/test-bw-template-$$.tmpl"
  echo 'export TOKEN="{{ bitwarden "myitem" "password" }}"' > "$test_file"

  if _dotf_has_bitwarden_template "$test_file"; then
    print_pass "Detects bitwarden template syntax"
  else
    print_fail "Detects bitwarden template syntax" "Function returned false"
  fi

  rm -f "$test_file"
}

test_bw_template_ignores_non_tmpl() {
  print_test "_dotf_has_bitwarden_template ignores non-.tmpl files"
  run_test

  local test_file="/tmp/test-not-tmpl-$$.txt"
  echo '{{ bitwarden "myitem" "password" }}' > "$test_file"

  if ! _dotf_has_bitwarden_template "$test_file"; then
    print_pass "Ignores bitwarden syntax in non-.tmpl files"
  else
    print_fail "Ignores bitwarden syntax in non-.tmpl files" "Function returned true"
  fi

  rm -f "$test_file"
}

test_bw_template_ignores_other_templates() {
  print_test "_dotf_has_bitwarden_template ignores other template functions"
  run_test

  local test_file="/tmp/test-other-tmpl-$$.tmpl"
  echo '{{ env "HOME" }}' > "$test_file"
  echo '{{ include "file.txt" }}' >> "$test_file"

  if ! _dotf_has_bitwarden_template "$test_file"; then
    print_pass "Ignores non-bitwarden template functions"
  else
    print_fail "Ignores non-bitwarden template functions" "Function returned true"
  fi

  rm -f "$test_file"
}

test_bw_template_handles_spacing() {
  print_test "_dotf_has_bitwarden_template handles varied spacing"
  run_test

  local test_file="/tmp/test-spacing-$$.tmpl"
  echo '{{bitwarden "item" "field"}}' > "$test_file"  # No spaces

  if _dotf_has_bitwarden_template "$test_file"; then
    print_pass "Handles template with no spaces"
  else
    print_fail "Handles template with no spaces" "Function returned false"
  fi

  rm -f "$test_file"
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE 4: _dots_print_summary() Unit Tests
# ══════════════════════════════════════════════════════════════════════════════

test_summary_shows_file_action_status() {
  print_test "_dots_print_summary includes all parameters"
  run_test

  local output
  output=$(_dots_print_summary ".zshrc" "Added" "Applied" 2>&1)

  if [[ "$output" == *".zshrc"* ]] && [[ "$output" == *"Added"* ]] && [[ "$output" == *"Applied"* ]]; then
    print_pass "Summary includes file, action, and status"
  else
    print_fail "Summary includes file, action, and status" "Output: $output"
  fi
}

test_summary_push_tip_for_applied() {
  print_test "_dots_print_summary shows push tip for Applied"
  run_test

  local output
  output=$(_dots_print_summary ".test" "Edited" "Applied" 2>&1)

  if [[ "$output" == *"dots push"* ]]; then
    print_pass "Shows 'dots push' tip for Applied status"
  else
    print_fail "Shows 'dots push' tip for Applied status" "Output: $output"
  fi
}

test_summary_apply_tip_for_staging() {
  print_test "_dots_print_summary shows apply tip for Staging"
  run_test

  local output
  output=$(_dots_print_summary ".test" "Edited" "Staging" 2>&1)

  if [[ "$output" == *"dots apply"* ]]; then
    print_pass "Shows 'dots apply' tip for Staging status"
  else
    print_fail "Shows 'dots apply' tip for Staging status" "Output: $output"
  fi
}

test_summary_no_tip_for_no_changes() {
  print_test "_dots_print_summary shows no tip for No changes"
  run_test

  local output
  output=$(_dots_print_summary ".test" "Edited" "No changes" 2>&1)

  # Should not show any tip
  if [[ "$output" != *"dots push"* ]] && [[ "$output" != *"dots apply"* ]]; then
    print_pass "No tip shown for 'No changes' status"
  else
    print_fail "No tip shown for 'No changes' status" "Output: $output"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE 5: ZDOTDIR Support Tests
# ══════════════════════════════════════════════════════════════════════════════

test_zdotdir_pattern_in_source() {
  print_test "ZDOTDIR pattern used in security check"
  run_test

  local helpers_file="$FLOW_CLI_ROOT/lib/dotfile-helpers.zsh"

  if [[ -f "$helpers_file" ]]; then
    local source_code=$(< "$helpers_file")
    if [[ "$source_code" == *'${ZDOTDIR:-$HOME}'* ]]; then
      print_pass "Uses \${ZDOTDIR:-\$HOME} pattern"
    else
      print_fail "Uses \${ZDOTDIR:-\$HOME} pattern" "Pattern not found in source"
    fi
  else
    print_fail "Uses \${ZDOTDIR:-\$HOME} pattern" "Helper file not found at $helpers_file"
  fi
}

test_zdotdir_not_hardcoded() {
  print_test "Shell config paths not hardcoded"
  run_test

  local helpers_file="$FLOW_CLI_ROOT/lib/dotfile-helpers.zsh"

  if [[ -f "$helpers_file" ]]; then
    local source_code=$(< "$helpers_file")
    # Check that we don't have hardcoded paths like $HOME/.zshrc in the security check
    # The pattern should be ${ZDOTDIR:-$HOME}/.zshrc not $HOME/.zshrc
    local security_func=$(grep -A 20 "_dotf_security_check_bw_session" "$helpers_file" | head -20)

    if [[ "$security_func" != *'$HOME/.zshrc'* ]] || [[ "$security_func" == *'${ZDOTDIR:-$HOME}'* ]]; then
      print_pass "No hardcoded \$HOME/.zshrc paths"
    else
      print_fail "No hardcoded \$HOME/.zshrc paths" "Found hardcoded path"
    fi
  else
    print_fail "No hardcoded \$HOME/.zshrc paths" "Helper file not found at $helpers_file"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE 6: Help Text Tests
# ══════════════════════════════════════════════════════════════════════════════

test_help_includes_add_command() {
  print_test "Help text includes add command"
  run_test

  local output
  output=$(dots help 2>&1)

  if [[ "$output" == *"dots add"* ]]; then
    print_pass "Help includes 'dots add' command"
  else
    print_fail "Help includes 'dots add' command" "Not found in help output"
  fi
}

test_help_shows_create_feature() {
  print_test "Help text shows create feature in edit"
  run_test

  local output
  output=$(dots help 2>&1)

  if [[ "$output" == *"auto-add"* ]] || [[ "$output" == *"Create"* ]] || [[ "$output" == *"create"* ]]; then
    print_pass "Help mentions file creation capability"
  else
    print_fail "Help mentions file creation capability" "Feature not documented"
  fi
}

test_help_shows_examples() {
  print_test "Help text includes new feature examples"
  run_test

  local output
  output=$(dots help 2>&1)

  if [[ "$output" == *"dots add"* ]] && [[ "$output" == *"~"* ]]; then
    print_pass "Help shows example with tilde path"
  else
    print_fail "Help shows example with tilde path" "Example not found"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# RUN ALL TESTS
# ══════════════════════════════════════════════════════════════════════════════

main() {
  echo ""
  echo "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
  echo "${CYAN}║${NC}  ${BOLD}DOT DISPATCHER v5.1.1 - UNIT TESTS${NC}                         ${CYAN}║${NC}"
  echo "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"

  setup

  print_header "Suite 1: _dots_add_file() Tests"
  test_add_file_rejects_nonexistent
  test_add_file_expands_tilde
  test_add_file_handles_relative_paths

  print_header "Suite 2: _dots_add() Tests"
  test_dots_add_requires_argument
  test_dots_add_rejects_nonexistent
  test_dots_add_shows_tip

  print_header "Suite 3: _dotf_has_bitwarden_template() Tests"
  test_bw_template_detects_bitwarden
  test_bw_template_ignores_non_tmpl
  test_bw_template_ignores_other_templates
  test_bw_template_handles_spacing

  print_header "Suite 4: _dots_print_summary() Tests"
  test_summary_shows_file_action_status
  test_summary_push_tip_for_applied
  test_summary_apply_tip_for_staging
  test_summary_no_tip_for_no_changes

  print_header "Suite 5: ZDOTDIR Support Tests"
  test_zdotdir_pattern_in_source
  test_zdotdir_not_hardcoded

  print_header "Suite 6: Help Text Tests"
  test_help_includes_add_command
  test_help_shows_create_feature
  test_help_shows_examples

  # Summary
  echo ""
  echo "${CYAN}═══════════════════════════════════════════════════════════${NC}"
  echo "${BOLD}TEST RESULTS${NC}"
  echo "${CYAN}═══════════════════════════════════════════════════════════${NC}"
  echo ""
  echo "Tests run:    ${BOLD}$TESTS_RUN${NC}"
  echo "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
  echo "Tests failed: ${RED}$TESTS_FAILED${NC}"
  echo ""

  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}${BOLD}✓ All unit tests passed!${NC}"
    exit 0
  else
    echo "${RED}${BOLD}✗ Some tests failed:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
      echo "  ${RED}•${NC} $test"
    done
    exit 1
  fi
}

main "$@"
