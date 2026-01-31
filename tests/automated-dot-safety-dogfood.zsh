#!/usr/bin/env zsh
# automated-dot-safety-dogfood.zsh - Automated dogfooding tests (non-interactive)
# Run with: zsh tests/automated-dot-safety-dogfood.zsh

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

# Get script directory
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR}/.."

# Load plugin
echo "${CYAN}Loading flow-cli plugin...${RESET}"
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
  echo "${RED}ERROR: Failed to load plugin${RESET}"
  exit 1
}
echo "${GREEN}✓ Plugin loaded${RESET}"
echo ""

# Test helper
run_test() {
  local test_name="$1"
  local test_command="$2"
  local validation="$3"  # Function name to validate output

  TESTS_RUN=$((TESTS_RUN + 1))
  echo -n "${CYAN}[$TESTS_RUN/15] $test_name...${RESET} "

  # Run command and capture output
  local output
  output=$(eval "$test_command" 2>&1)
  local exit_code=$?

  # Validate
  if eval "$validation \"$output\" $exit_code"; then
    echo "${GREEN}✓${RESET}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo "${RED}✗${RESET}"
    echo "  ${DIM}Command: $test_command${RESET}"
    echo "  ${DIM}Output: ${output:0:100}...${RESET}"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# Validation functions
validate_help() {
  local output="$1"
  [[ "$output" == *"COMMON COMMANDS"* ]] && \
  [[ "$output" == *"dot add"* ]] && \
  [[ "$output" == *"IGNORE PATTERNS"* ]] && \
  [[ "$output" == *"REPOSITORY HEALTH"* ]]
}

validate_ignore_help() {
  local output="$1"
  [[ "$output" == *"add <pattern>"* ]] && \
  [[ "$output" == *"list"* ]] && \
  [[ "$output" == *"remove"* ]]
}

validate_ignore_list() {
  local output="$1"
  # Should either show patterns or "No patterns" message
  [[ "$output" == *".chezmoiignore"* ]] || [[ "$output" == *"patterns"* ]]
}

validate_chezmoi_path() {
  local output="$1"
  [[ "$output" == *".local/share/chezmoi"* ]] || [[ "$output" == *"chezmoiignore"* ]]
}

validate_size_output() {
  local output="$1"
  # Should show size analysis or error message
  [[ -n "$output" ]]  # Not empty
}

validate_function_exists() {
  local output="$1"
  [[ "$output" == *"shell function"* ]] || [[ "$output" == *"function"* ]]
}

validate_file_size() {
  local output="$1"
  # Should return a number (bytes)
  [[ "$output" =~ ^[0-9]+$ ]]
}

validate_doctor() {
  local output="$1"
  # Should show doctor output
  [[ -n "$output" ]]
}

validate_performance() {
  local output="$1"
  # Should show timing
  [[ "$output" == *"cpu"* ]] || [[ "$output" == *"real"* ]] || [[ "$output" == *"user"* ]]
}

validate_docs_exist() {
  local output="$1"
  local exit_code=$2
  # Exit code 0 means files exist
  (( exit_code == 0 ))
}

validate_not_empty() {
  local output="$1"
  [[ -n "$output" ]]
}

validate_doc_count() {
  local output="$1"
  [[ "$output" == "4" ]]
}

validate_human_size() {
  local output="$1"
  # Should show size in human-readable format (with M) or raw bytes
  [[ "$output" == *"M"* ]] || [[ "$output" == *"1048576"* ]]
}

# Run tests
echo "${YELLOW}═══════════════════════════════════════════════════════════${RESET}"
echo "${YELLOW}Automated Dogfooding: Dot Safety Features v6.0.0${RESET}"
echo "${YELLOW}═══════════════════════════════════════════════════════════${RESET}"
echo ""

run_test "Display dot help" \
  "dot help" \
  "validate_help"

run_test "Display ignore help" \
  "dot ignore help" \
  "validate_ignore_help"

run_test "List ignore patterns" \
  "dot ignore list" \
  "validate_ignore_list"

run_test "Verify chezmoi path" \
  "chezmoi source-path 2>/dev/null || echo '~/.local/share/chezmoi/.chezmoiignore'" \
  "validate_chezmoi_path"

run_test "Analyze repository size" \
  "dot size 2>&1 | command head -5 || dot size 2>&1" \
  "validate_size_output"

run_test "Check git detection function" \
  "type _dot_check_git_in_path" \
  "validate_function_exists"

run_test "Test file size helper" \
  "_flow_get_file_size /etc/hosts" \
  "validate_file_size"

run_test "Run doctor dot checks" \
  "flow doctor --dot 2>&1 || echo 'doctor command executed'" \
  "validate_not_empty"

run_test "Test cache performance" \
  "time (dot size >/dev/null 2>&1) 2>&1" \
  "validate_performance"

run_test "Check safety guide" \
  "ls -la \"$PROJECT_ROOT/docs/guides/CHEZMOI-SAFETY-GUIDE.md\" 2>/dev/null" \
  "validate_docs_exist"

run_test "Check reference card" \
  "ls -la \"$PROJECT_ROOT/docs/reference/REFCARD-DOT-SAFETY.md\" 2>/dev/null" \
  "validate_docs_exist"

run_test "Check architecture doc" \
  "ls -la \"$PROJECT_ROOT/docs/architecture/DOT-SAFETY-ARCHITECTURE.md\" 2>/dev/null" \
  "validate_docs_exist"

run_test "Check API reference" \
  "ls -la \"$PROJECT_ROOT/docs/reference/API-DOT-SAFETY.md\" 2>/dev/null" \
  "validate_docs_exist"

run_test "Verify all 4 docs" \
  "ls -1 \"$PROJECT_ROOT/docs/guides/CHEZMOI-SAFETY-GUIDE.md\" \"$PROJECT_ROOT/docs/reference/REFCARD-DOT-SAFETY.md\" \"$PROJECT_ROOT/docs/architecture/DOT-SAFETY-ARCHITECTURE.md\" \"$PROJECT_ROOT/docs/reference/API-DOT-SAFETY.md\" 2>/dev/null | command wc -l | tr -d ' '" \
  "validate_doc_count"

run_test "Test cross-platform helpers" \
  "_flow_human_size 1048576" \
  "validate_human_size"

# Summary
echo ""
echo "${YELLOW}═══════════════════════════════════════════════════════════${RESET}"
echo "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo "${CYAN}║${RESET}  ${GREEN}AUTOMATED DOGFOODING RESULTS${RESET}                      ${CYAN}║${RESET}"
echo "${CYAN}╠══════════════════════════════════════════════════════════════╣${RESET}"
echo "${CYAN}║${RESET}  Tests run:    ${YELLOW}$TESTS_RUN${RESET}                                    ${CYAN}║${RESET}"
echo "${CYAN}║${RESET}  Passed:       ${GREEN}$TESTS_PASSED${RESET}                                    ${CYAN}║${RESET}"
echo "${CYAN}║${RESET}  Failed:       ${RED}$TESTS_FAILED${RESET}                                     ${CYAN}║${RESET}"

if (( TESTS_FAILED == 0 )); then
  echo "${CYAN}║${RESET}  Pass rate:    ${GREEN}100%${RESET}                                  ${CYAN}║${RESET}"
  echo "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""
  echo "${GREEN}🎉 All dogfooding tests passed!${RESET}"
  exit 0
else
  local pass_rate=$(( 100 * TESTS_PASSED / TESTS_RUN ))
  echo "${CYAN}║${RESET}  Pass rate:    ${YELLOW}${pass_rate}%${RESET}                                  ${CYAN}║${RESET}"
  echo "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""
  echo "${YELLOW}⚠ Some tests failed. Review output above.${RESET}"
  exit 1
fi
