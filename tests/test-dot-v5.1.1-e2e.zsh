#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# DOT DISPATCHER v5.1.1 - END-TO-END TESTS
# ══════════════════════════════════════════════════════════════════════════════
#
# Tests that actually interact with chezmoi (requires chezmoi to be installed)
# These tests create real files and use chezmoi add/forget
#
# Run: zsh tests/test-dot-v5.1.1-e2e.zsh
#
# Prerequisites:
#   - chezmoi installed and initialized
#   - Write permissions to $HOME
#
# ══════════════════════════════════════════════════════════════════════════════

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0
declare -a FAILED_TESTS
declare -a TEST_CLEANUP_FILES

# Test file prefix (unique per run)
TEST_PREFIX=".dot-e2e-test-$$"

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

print_skip() {
  echo "${DIM}⊘ SKIP${NC}: $1"
  echo "  ${DIM}→${NC} $2"
  ((TESTS_SKIPPED++))
}

run_test() {
  ((TESTS_RUN++))
}

# ══════════════════════════════════════════════════════════════════════════════
# SETUP & TEARDOWN
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
    FLOW_CLI_ROOT="/Users/dt/projects/dev-tools/flow-cli"
  fi

  echo "${DIM}FLOW_CLI_ROOT: $FLOW_CLI_ROOT${NC}"

  # Source core first
  if [[ -f "$FLOW_CLI_ROOT/lib/core.zsh" ]]; then
    source "$FLOW_CLI_ROOT/lib/core.zsh"
  fi

  # Source the files we're testing
  if [[ -f "$FLOW_CLI_ROOT/lib/dotfile-helpers.zsh" ]]; then
    source "$FLOW_CLI_ROOT/lib/dotfile-helpers.zsh"
  else
    echo "${RED}ERROR: Could not find dotfile-helpers.zsh${NC}"
    exit 1
  fi

  if [[ -f "$FLOW_CLI_ROOT/lib/dispatchers/dot-dispatcher.zsh" ]]; then
    source "$FLOW_CLI_ROOT/lib/dispatchers/dot-dispatcher.zsh"
  else
    echo "${RED}ERROR: Could not find dot-dispatcher.zsh${NC}"
    exit 1
  fi

  # Check prerequisites
  if ! command -v chezmoi &>/dev/null; then
    echo "${RED}ERROR: chezmoi not installed${NC}"
    echo "Install with: brew install chezmoi"
    exit 1
  fi

  if [[ ! -d "$HOME/.local/share/chezmoi" ]]; then
    echo "${RED}ERROR: chezmoi not initialized${NC}"
    echo "Initialize with: chezmoi init"
    exit 1
  fi

  echo "${GREEN}✓${NC} Prerequisites met: chezmoi installed and initialized"
}

cleanup() {
  echo ""
  echo "${DIM}Cleaning up test files...${NC}"

  # Forget from chezmoi first
  for file in "${TEST_CLEANUP_FILES[@]}"; do
    if chezmoi managed 2>/dev/null | grep -qF "${file#$HOME/}"; then
      chezmoi forget "$file" 2>/dev/null
    fi
    rm -f "$file" 2>/dev/null
  done

  # Also clean any files matching our test prefix
  # Use nullglob to avoid errors when no files match
  setopt localoptions nullglob
  for file in $HOME/${TEST_PREFIX}*; do
    if [[ -f "$file" ]]; then
      chezmoi forget "$file" 2>/dev/null
      rm -f "$file"
    fi
  done

  # Clean up any test directories
  rm -rf "$HOME/.config/dot-e2e-test-$$" 2>/dev/null

  echo "${GREEN}✓${NC} Cleanup complete"
}

# Trap to ensure cleanup on exit
trap cleanup EXIT

# ══════════════════════════════════════════════════════════════════════════════
# E2E TEST SUITE 1: dots add Command
# ══════════════════════════════════════════════════════════════════════════════

test_e2e_add_real_file() {
  print_test "E2E: dots add adds real file to chezmoi"
  run_test

  local test_file="$HOME/${TEST_PREFIX}-add-real"
  TEST_CLEANUP_FILES+=("$test_file")

  # Create test file
  echo "# Test file for dots add E2E" > "$test_file"

  # Run dots add
  local output
  output=$(_dots_add "$test_file" 2>&1)
  local exit_code=$?

  # Verify it's now tracked
  if chezmoi managed 2>/dev/null | grep -qF "${test_file#$HOME/}"; then
    print_pass "File added and tracked by chezmoi"
  else
    print_fail "File added and tracked by chezmoi" "Exit: $exit_code, File not in chezmoi managed list"
  fi
}

test_e2e_add_shows_source_path() {
  print_test "E2E: dots add shows chezmoi source path"
  run_test

  local test_file="$HOME/${TEST_PREFIX}-add-source"
  TEST_CLEANUP_FILES+=("$test_file")

  echo "# Test" > "$test_file"

  local output
  output=$(_dots_add "$test_file" 2>&1)

  if [[ "$output" == *"Source:"* ]] || [[ "$output" == *".local/share/chezmoi"* ]]; then
    print_pass "Shows source path in chezmoi directory"
  else
    print_fail "Shows source path in chezmoi directory" "Output: $output"
  fi
}

test_e2e_add_already_tracked() {
  print_test "E2E: dots add handles already tracked files"
  run_test

  local test_file="$HOME/${TEST_PREFIX}-add-tracked"
  TEST_CLEANUP_FILES+=("$test_file")

  echo "# Test" > "$test_file"

  # Add it once
  _dots_add "$test_file" >/dev/null 2>&1

  # Try to add again
  local output
  output=$(_dots_add "$test_file" 2>&1)

  if [[ "$output" == *"Already tracked"* ]]; then
    print_pass "Reports already tracked file"
  else
    print_fail "Reports already tracked file" "Output: $output"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# E2E TEST SUITE 2: Path Resolution
# ══════════════════════════════════════════════════════════════════════════════

test_e2e_resolve_full_path() {
  print_test "E2E: _dots_resolve_file_path handles full paths"
  run_test

  local test_file="$HOME/${TEST_PREFIX}-resolve"
  TEST_CLEANUP_FILES+=("$test_file")

  echo "# Test" > "$test_file"
  chezmoi add "$test_file" 2>/dev/null

  local resolved
  resolved=$(_dots_resolve_file_path "$test_file" 2>/dev/null)

  if [[ "$resolved" == "$test_file" ]]; then
    print_pass "Resolves full path correctly"
  else
    print_fail "Resolves full path correctly" "Expected: $test_file, Got: $resolved"
  fi
}

test_e2e_resolve_fuzzy_match() {
  print_test "E2E: _dots_resolve_file_path fuzzy matches basename"
  run_test

  local test_file="$HOME/${TEST_PREFIX}-fuzzy"
  TEST_CLEANUP_FILES+=("$test_file")

  echo "# Test" > "$test_file"
  chezmoi add "$test_file" 2>/dev/null

  # Search by partial name (without leading dot and full prefix)
  local search_term="fuzzy"
  local resolved
  resolved=$(_dots_resolve_file_path "$search_term" 2>/dev/null)
  local resolve_status=$?

  # Should find our file
  if [[ $resolve_status -ne 1 ]] && [[ "$resolved" == *"fuzzy"* ]]; then
    print_pass "Fuzzy matches basename"
  else
    print_fail "Fuzzy matches basename" "Status: $resolve_status, Resolved: $resolved"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# E2E TEST SUITE 3: File Creation Flow
# ══════════════════════════════════════════════════════════════════════════════

test_e2e_mkdir_creates_parents() {
  print_test "E2E: File creation creates parent directories"
  run_test

  local test_dir="$HOME/.config/dot-e2e-test-$$"
  local test_file="$test_dir/nested/deep/config.zsh"

  # Simulate what _dots_edit does for file creation (mkdir -p)
  local parent_dir="${test_file:h}"
  mkdir -p "$parent_dir"

  if [[ -d "$parent_dir" ]]; then
    print_pass "Creates nested parent directories"
    TEST_CLEANUP_FILES+=("$test_file")
    rm -rf "$test_dir"
  else
    print_fail "Creates nested parent directories" "Directory not created: $parent_dir"
  fi
}

test_e2e_touch_creates_file() {
  print_test "E2E: File creation creates empty file"
  run_test

  local test_file="$HOME/${TEST_PREFIX}-created"
  TEST_CLEANUP_FILES+=("$test_file")

  # Simulate file creation
  touch "$test_file"

  if [[ -f "$test_file" ]]; then
    print_pass "Creates empty file with touch"
  else
    print_fail "Creates empty file with touch" "File not created"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# E2E TEST SUITE 4: Template Detection with Real Files
# ══════════════════════════════════════════════════════════════════════════════

test_e2e_template_real_file() {
  print_test "E2E: Template detection works with real .tmpl file"
  run_test

  local test_file="$HOME/${TEST_PREFIX}.tmpl"
  TEST_CLEANUP_FILES+=("$test_file")

  echo 'export SECRET="{{ bitwarden "github" "api_token" }}"' > "$test_file"

  if _dotf_has_bitwarden_template "$test_file"; then
    print_pass "Detects bitwarden in real .tmpl file"
  else
    print_fail "Detects bitwarden in real .tmpl file" "Function returned false"
  fi
}

test_e2e_template_chezmoi_source() {
  print_test "E2E: Template detection works on chezmoi source files"
  run_test

  local test_file="$HOME/${TEST_PREFIX}-env"
  TEST_CLEANUP_FILES+=("$test_file")

  echo 'export TEST=value' > "$test_file"
  chezmoi add "$test_file" 2>/dev/null

  local source_path
  source_path=$(chezmoi source-path "$test_file" 2>/dev/null)

  # The source file should exist
  if [[ -f "$source_path" ]]; then
    print_pass "Can locate chezmoi source file for template check"
  else
    print_fail "Can locate chezmoi source file for template check" "Source: $source_path"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# E2E TEST SUITE 5: Chezmoi Integration
# ══════════════════════════════════════════════════════════════════════════════

test_e2e_chezmoi_apply_works() {
  print_test "E2E: chezmoi apply works after add"
  run_test

  local test_file="$HOME/${TEST_PREFIX}-apply"
  TEST_CLEANUP_FILES+=("$test_file")

  echo "# Original" > "$test_file"
  chezmoi add "$test_file" 2>/dev/null

  # Modify the source file
  local source_path
  source_path=$(chezmoi source-path "$test_file" 2>/dev/null)

  if [[ -f "$source_path" ]]; then
    echo "# Modified in source" > "$source_path"

    # Apply changes
    chezmoi apply "$test_file" 2>/dev/null

    # Check target file was updated
    local content
    content=$(< "$test_file")

    if [[ "$content" == *"Modified"* ]]; then
      print_pass "chezmoi apply updates target file"
    else
      print_fail "chezmoi apply updates target file" "Content: $content"
    fi
  else
    print_fail "chezmoi apply updates target file" "Source path not found"
  fi
}

test_e2e_chezmoi_diff_shows_changes() {
  print_test "E2E: chezmoi diff shows pending changes"
  run_test

  local test_file="$HOME/${TEST_PREFIX}-diff"
  TEST_CLEANUP_FILES+=("$test_file")

  echo "# Original content" > "$test_file"
  chezmoi add "$test_file" 2>/dev/null

  # Modify source to create diff
  local source_path
  source_path=$(chezmoi source-path "$test_file" 2>/dev/null)

  if [[ -f "$source_path" ]]; then
    echo "# Different content" > "$source_path"

    local diff_output
    diff_output=$(chezmoi diff "$test_file" 2>&1)

    if [[ -n "$diff_output" ]]; then
      print_pass "chezmoi diff shows changes"
    else
      print_fail "chezmoi diff shows changes" "No diff output"
    fi

    # Restore to avoid leftover changes
    chezmoi apply "$test_file" 2>/dev/null
  else
    print_fail "chezmoi diff shows changes" "Source path not found"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# E2E TEST SUITE 6: Dispatcher Integration
# ══════════════════════════════════════════════════════════════════════════════

test_e2e_dot_status_works() {
  print_test "E2E: dots status runs without error"
  run_test

  local output
  output=$(dots status 2>&1)
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    print_pass "dots status completes successfully"
  else
    print_fail "dots status completes successfully" "Exit: $exit_code"
  fi
}

test_e2e_dot_diff_works() {
  print_test "E2E: dots diff runs without error"
  run_test

  local output
  output=$(dots diff 2>&1)
  local exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    print_pass "dots diff completes successfully"
  else
    print_fail "dots diff completes successfully" "Exit: $exit_code"
  fi
}

test_e2e_dot_help_works() {
  print_test "E2E: dots help shows add command"
  run_test

  local output
  output=$(dots help 2>&1)

  if [[ "$output" == *"dots add"* ]]; then
    print_pass "dots help includes add command"
  else
    print_fail "dots help includes add command" "Not found in output"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# RUN ALL TESTS
# ══════════════════════════════════════════════════════════════════════════════

main() {
  echo ""
  echo "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
  echo "${CYAN}║${NC}  ${BOLD}DOT DISPATCHER v5.1.1 - END-TO-END TESTS${NC}                    ${CYAN}║${NC}"
  echo "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
  echo ""

  setup

  print_header "E2E Suite 1: dots add Command"
  test_e2e_add_real_file
  test_e2e_add_shows_source_path
  test_e2e_add_already_tracked

  print_header "E2E Suite 2: Path Resolution"
  test_e2e_resolve_full_path
  test_e2e_resolve_fuzzy_match

  print_header "E2E Suite 3: File Creation Flow"
  test_e2e_mkdir_creates_parents
  test_e2e_touch_creates_file

  print_header "E2E Suite 4: Template Detection"
  test_e2e_template_real_file
  test_e2e_template_chezmoi_source

  print_header "E2E Suite 5: Chezmoi Integration"
  test_e2e_chezmoi_apply_works
  test_e2e_chezmoi_diff_shows_changes

  print_header "E2E Suite 6: Dispatcher Integration"
  test_e2e_dot_status_works
  test_e2e_dot_diff_works
  test_e2e_dot_help_works

  # Summary
  echo ""
  echo "${CYAN}═══════════════════════════════════════════════════════════${NC}"
  echo "${BOLD}E2E TEST RESULTS${NC}"
  echo "${CYAN}═══════════════════════════════════════════════════════════${NC}"
  echo ""
  echo "Tests run:    ${BOLD}$TESTS_RUN${NC}"
  echo "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
  echo "Tests failed: ${RED}$TESTS_FAILED${NC}"
  echo "Tests skipped: ${DIM}$TESTS_SKIPPED${NC}"
  echo ""

  if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}${BOLD}✓ All E2E tests passed!${NC}"
    exit 0
  else
    echo "${RED}${BOLD}✗ Some E2E tests failed:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
      echo "  ${RED}•${NC} $test"
    done
    exit 1
  fi
}

main "$@"
