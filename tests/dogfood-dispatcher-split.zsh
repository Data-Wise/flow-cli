#!/usr/bin/env zsh
# dogfood-dispatcher-split.zsh - Interactive dogfooding for dots/sec/tok split
# Run with: zsh tests/dogfood-dispatcher-split.zsh
#
# ADHD-friendly interactive test: runs each command, shows expected behavior,
# asks you to confirm if it looks correct.
#
# Tests real-world usage of all 3 new dispatchers.

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Counters
typeset -g TOTAL_TESTS=0
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0
typeset -g TESTS_SKIPPED=0

# Resolve paths at script level (before functions override $0)
typeset -g SCRIPT_DIR="${0:A:h}"
typeset -g PROJECT_ROOT="${SCRIPT_DIR}/.."

# ============================================================================
# HELPERS
# ============================================================================

print_banner() {
  echo ""
  echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${MAGENTA}║${NC}  ${BOLD}DISPATCHER SPLIT DOGFOODING${NC}  (v7.1.0)                   ${MAGENTA}║${NC}"
  echo -e "${MAGENTA}║${NC}  ${DIM}dots (dotfiles) | sec (secrets) | tok (tokens)${NC}          ${MAGENTA}║${NC}"
  echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

run_interactive_test() {
  local test_name="$1"
  local command="$2"
  local expected="$3"

  TOTAL_TESTS=$((TOTAL_TESTS + 1))

  echo ""
  echo -e "${CYAN}──── TEST $TOTAL_TESTS: $test_name ────${NC}"
  echo -e "${DIM}Command:  ${NC}${BOLD}$command${NC}"
  echo -e "${DIM}Expected: ${NC}$expected"
  echo ""

  # Run the command
  echo -e "${YELLOW}--- OUTPUT ---${NC}"
  eval "$command" 2>&1
  local exit_code=$?
  echo -e "${YELLOW}--- END (exit: $exit_code) ---${NC}"
  echo ""

  # Ask user
  echo -n -e "${MAGENTA}Did it match? ${NC}[${GREEN}y${NC}=pass / ${RED}n${NC}=fail / ${BLUE}s${NC}=skip / ${YELLOW}q${NC}=quit] "
  read -k1 answer
  echo ""

  case "$answer" in
    y|Y)
      echo -e "${GREEN}PASS${NC}"
      TESTS_PASSED=$((TESTS_PASSED + 1))
      ;;
    n|N)
      echo -e "${RED}FAIL${NC}"
      TESTS_FAILED=$((TESTS_FAILED + 1))
      ;;
    s|S)
      echo -e "${BLUE}SKIPPED${NC}"
      TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
      ;;
    q|Q)
      print_summary
      exit 0
      ;;
  esac
}

print_summary() {
  echo ""
  echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}  ${BOLD}DOGFOODING RESULTS${NC}                                      ${CYAN}║${NC}"
  echo -e "${CYAN}╠════════════════════════════════════════════════════════════╣${NC}"
  echo -e "${CYAN}║${NC}  Total:    ${YELLOW}$TOTAL_TESTS${NC}"
  echo -e "${CYAN}║${NC}  Passed:   ${GREEN}$TESTS_PASSED${NC}"
  echo -e "${CYAN}║${NC}  Failed:   ${RED}$TESTS_FAILED${NC}"
  echo -e "${CYAN}║${NC}  Skipped:  ${BLUE}$TESTS_SKIPPED${NC}"

  if (( TESTS_FAILED == 0 )); then
    echo -e "${CYAN}║${NC}  Verdict:  ${GREEN}ALL GOOD${NC}"
  else
    echo -e "${CYAN}║${NC}  Verdict:  ${YELLOW}NEEDS ATTENTION${NC}"
  fi
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
}

# ============================================================================
# SETUP
# ============================================================================

setup() {
  echo -e "${CYAN}Loading flow-cli plugin...${NC}"
  source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null
  if ! type dots >/dev/null 2>&1; then
    echo -e "${RED}ERROR: Failed to load plugin${NC}"
    exit 1
  fi
  echo -e "${GREEN}Plugin loaded${NC}"
}

# ============================================================================
# DOTS DISPATCHER TESTS
# ============================================================================

test_dots_section() {
  echo ""
  echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════${NC}"
  echo -e "${BOLD}${GREEN}  SECTION 1: dots (Dotfile Management)${NC}"
  echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════${NC}"

  run_interactive_test \
    "dots help" \
    "dots help" \
    "Shows help with COMMON COMMANDS, IGNORE PATTERNS, RELATED section mentioning sec/tok"

  run_interactive_test \
    "dots status" \
    "dots status" \
    "Shows chezmoi sync status (tracked files, modifications, last sync time)"

  run_interactive_test \
    "dots version" \
    "dots version" \
    "Shows version information"

  run_interactive_test \
    "dots ignore help" \
    "dots ignore help" \
    "Shows ignore subcommands: add, list/ls, remove/rm, edit"

  run_interactive_test \
    "dots ignore list" \
    "dots ignore list" \
    "Shows current .chezmoiignore patterns (or 'no patterns' message)"

  run_interactive_test \
    "dots diff" \
    "dots diff" \
    "Shows pending chezmoi changes (diff output or 'no changes' message)"

  run_interactive_test \
    "dots doctor" \
    "dots doctor" \
    "Runs dotfile-specific diagnostics (chezmoi health, git, etc.)"
}

# ============================================================================
# SEC DISPATCHER TESTS
# ============================================================================

test_sec_section() {
  echo ""
  echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════${NC}"
  echo -e "${BOLD}${GREEN}  SECTION 2: sec (Secret Management)${NC}"
  echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════${NC}"

  run_interactive_test \
    "sec help" \
    "sec help" \
    "Shows secret management help with unlock/lock, list/add/delete, bw, sync, dashboard"

  run_interactive_test \
    "sec status" \
    "sec status" \
    "Shows backend config status (keychain/bitwarden), vault lock state"

  run_interactive_test \
    "sec list" \
    "sec list" \
    "Lists secrets from keychain (names only, no values shown)"

  run_interactive_test \
    "sec dashboard" \
    "sec dashboard" \
    "Shows secrets overview dashboard with counts and health status"

  run_interactive_test \
    "sec bw help" \
    "sec bw help" \
    "Shows Bitwarden-specific subcommands: list, add, check"

  run_interactive_test \
    "sec sync help" \
    "sec sync help" \
    "Shows sync subcommands: status, to-bitwarden, from-bitwarden, interactive, github"

  run_interactive_test \
    "sec doctor" \
    "sec doctor" \
    "Runs secret-specific diagnostics (backends, vault status, expiration)"
}

# ============================================================================
# TOK DISPATCHER TESTS
# ============================================================================

test_tok_section() {
  echo ""
  echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════${NC}"
  echo -e "${BOLD}${GREEN}  SECTION 3: tok (Token Management)${NC}"
  echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════${NC}"

  run_interactive_test \
    "tok help" \
    "tok help" \
    "Shows token help with github/npm/pypi wizards, rotate, refresh, expiring"

  run_interactive_test \
    "tok expiring" \
    "tok expiring" \
    "Shows tokens nearing expiration (or 'no expiring tokens' message)"

  run_interactive_test \
    "tok doctor" \
    "tok doctor" \
    "Runs token-specific diagnostics"
}

# ============================================================================
# CROSS-DISPATCHER TESTS
# ============================================================================

test_cross_section() {
  echo ""
  echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════${NC}"
  echo -e "${BOLD}${GREEN}  SECTION 4: Cross-Dispatcher Integration${NC}"
  echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════${NC}"

  run_interactive_test \
    "Invalid subcommand shows help" \
    "dots nonexistent_command 2>&1" \
    "Should show dots help (unknown command falls through to help)"

  run_interactive_test \
    "sec with no args shows help" \
    "sec 2>&1" \
    "Should show sec help text"

  run_interactive_test \
    "tok with no args shows help" \
    "tok 2>&1" \
    "Should show tok help text"

  run_interactive_test \
    "flow doctor --dot still works" \
    "flow doctor --dot 2>&1 | head -10" \
    "Doctor --dot flag runs dotfile/secret/token checks (flag preserved)"

  run_interactive_test \
    "type dots shows correct source" \
    "type dots" \
    "Shows: dots is a shell function from .../dots-dispatcher.zsh"

  run_interactive_test \
    "type sec shows correct source" \
    "type sec" \
    "Shows: sec is a shell function from .../sec-dispatcher.zsh"

  run_interactive_test \
    "type tok shows correct source" \
    "type tok" \
    "Shows: tok is a shell function from .../tok-dispatcher.zsh"
}

# ============================================================================
# MAIN
# ============================================================================

main() {
  print_banner
  setup

  test_dots_section
  test_sec_section
  test_tok_section
  test_cross_section

  print_summary

  if (( TESTS_FAILED > 0 )); then
    exit 1
  else
    exit 0
  fi
}

main
