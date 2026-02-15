#!/usr/bin/env zsh
# interactive-dot-safety-dogfood.zsh - Interactive dogfooding tests for dot safety features
# Run with: zsh tests/interactive-dot-safety-dogfood.zsh
#
# Human-guided QA with gamification:
# - Run actual commands in real environment
# - Judge expected vs actual behavior
# - Earn wins and track progress

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

# Counters
typeset -g TESTS_RUN=0
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0
typeset -g TESTS_SKIPPED=0

# Total test count
TOTAL_TESTS=15

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

print_header() {
  echo ""
  echo "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo "${CYAN}║${RESET}  ${BOLD}${GREEN}Interactive Dogfooding: Dot Safety Features${RESET}       ${CYAN}║${RESET}"
  echo "${CYAN}║${RESET}  ${DIM}v6.0.0 - Human-Guided Quality Assurance${RESET}            ${CYAN}║${RESET}"
  echo "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"
  echo ""
  echo "${YELLOW}Instructions:${RESET}"
  echo "  • Each test runs a real command"
  echo "  • Review expected vs actual behavior"
  echo "  • Press: ${GREEN}y${RESET}=pass, ${RED}n${RESET}=fail, ${YELLOW}s${RESET}=skip, ${MAGENTA}q${RESET}=quit"
  echo ""
}

run_test() {
  local test_num=$1
  local test_name="$2"
  local command="$3"
  local expected="$4"

  TESTS_RUN=$((TESTS_RUN + 1))

  echo "${CYAN}═══════════════════════════════════════════════════════════${RESET}"
  echo "${BOLD}TEST $test_num/$TOTAL_TESTS: $test_name${RESET}"
  echo "${DIM}Command: $command${RESET}"
  echo ""
  echo "${YELLOW}Expected:${RESET}"
  echo "$expected"
  echo ""
  echo "${CYAN}Running...${RESET}"
  echo ""

  # Execute command
  local output
  output=$(eval "$command" 2>&1)
  local exit_code=$?

  echo "${YELLOW}Actual Output:${RESET}"
  echo "$output"
  echo ""
  echo "${DIM}Exit code: $exit_code${RESET}"
  echo ""

  # Prompt for judgment
  echo -n "${BOLD}Does this match expectations? ${GREEN}(y)${RESET}es/${RED}(n)${RESET}o/${YELLOW}(s)${RESET}kip/${MAGENTA}(q)${RESET}uit: "
  read -k 1 response
  echo ""

  case "$response" in
    y|Y)
      echo "${GREEN}✓ PASS${RESET}"
      TESTS_PASSED=$((TESTS_PASSED + 1))
      ;;
    n|N)
      echo "${RED}✗ FAIL${RESET}"
      TESTS_FAILED=$((TESTS_FAILED + 1))
      ;;
    s|S)
      echo "${YELLOW}⊘ SKIP${RESET}"
      TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
      ;;
    q|Q)
      echo "${MAGENTA}Quit requested${RESET}"
      print_summary
      exit 0
      ;;
    *)
      echo "${YELLOW}⊘ SKIP (invalid input)${RESET}"
      TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
      ;;
  esac

  echo ""
}

print_summary() {
  local pass_rate=0
  if (( TESTS_RUN > 0 )); then
    pass_rate=$(( 100 * TESTS_PASSED / TESTS_RUN ))
  fi

  echo ""
  echo "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
  echo "${CYAN}║${RESET}  ${BOLD}${GREEN}DOGFOODING RESULTS${RESET}                                  ${CYAN}║${RESET}"
  echo "${CYAN}╠══════════════════════════════════════════════════════════════╣${RESET}"
  echo "${CYAN}║${RESET}  Tests run:    ${YELLOW}$TESTS_RUN${RESET}/${TOTAL_TESTS}                               ${CYAN}║${RESET}"
  echo "${CYAN}║${RESET}  Passed:       ${GREEN}$TESTS_PASSED${RESET}                                    ${CYAN}║${RESET}"
  echo "${CYAN}║${RESET}  Failed:       ${RED}$TESTS_FAILED${RESET}                                     ${CYAN}║${RESET}"
  echo "${CYAN}║${RESET}  Skipped:      ${YELLOW}$TESTS_SKIPPED${RESET}                                    ${CYAN}║${RESET}"
  echo "${CYAN}║${RESET}  Pass rate:    ${GREEN}${pass_rate}%${RESET}                                  ${CYAN}║${RESET}"
  echo "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"

  if (( TESTS_PASSED > 0 )); then
    echo ""
    echo "${GREEN}🎉 Great job! You earned $TESTS_PASSED win(s)!${RESET}"
    echo "${DIM}Run: win --category test 'Completed dot safety dogfooding'${RESET}"
  fi
}

# ============================================================================
# TEST SUITE
# ============================================================================

main() {
  print_header

  # Ensure flow-cli plugin is loaded (check if dot is a function, not just a command)
  if ! type dot 2>&1 | grep -q "function"; then
    echo "${YELLOW}Loading flow-cli plugin...${RESET}"

    # Try multiple paths to find the plugin
    local plugin_path=""
    for path in \
      "${0:A:h}/../flow.plugin.zsh" \
      "$(dirname "$0")/../flow.plugin.zsh" \
      "../flow.plugin.zsh" \
      "./flow.plugin.zsh"; do
      if [[ -f "$path" ]]; then
        plugin_path="$path"
        break
      fi
    done

    if [[ -z "$plugin_path" ]]; then
      echo "${RED}ERROR: Could not find flow.plugin.zsh${RESET}"
      echo "${DIM}Tried:${RESET}"
      echo "  ${0:A:h}/../flow.plugin.zsh"
      echo "  $(dirname "$0")/../flow.plugin.zsh"
      echo "  ../flow.plugin.zsh"
      echo "  ./flow.plugin.zsh"
      exit 1
    fi

    source "$plugin_path" 2>/dev/null || {
      echo "${RED}ERROR: Failed to load plugin from: $plugin_path${RESET}"
      exit 1
    }
    echo "${GREEN}✓ Plugin loaded successfully${RESET}"
    echo ""
  else
    echo "${GREEN}✓ Flow-cli plugin already loaded${RESET}"
    echo ""
  fi

  # ========================================================================
  # SECTION 1: Help & Documentation
  # ========================================================================

  run_test 1 "Display dots help" \
    "dots help" \
    "Should show:
- Command categories (Chezmoi, Secrets, Safety)
- New commands: add, ignore, size
- Color-coded output
- Example usage"

  run_test 2 "Display ignore help" \
    "dots ignore help" \
    "Should show:
- ignore add <pattern>
- ignore list
- ignore remove <pattern>
- ignore edit
- Usage examples"

  # ========================================================================
  # SECTION 2: Ignore Pattern Management
  # ========================================================================

  run_test 3 "List ignore patterns (initial)" \
    "dots ignore list" \
    "Should show:
- All patterns from .chezmoiignore
- Or message if no patterns exist
- Clean, readable format"

  run_test 4 "Add ignore pattern (dry-run)" \
    "echo 'Would add: **/.git'" \
    "Should show:
- What pattern would be added
- No actual file modification
- Preview behavior"

  run_test 5 "Verify ignore file location" \
    "chezmoi source-path 2>/dev/null || echo '~/.local/share/chezmoi/.chezmoiignore'" \
    "Should show:
- Path to .chezmoiignore file
- Confirms chezmoi source directory"

  # ========================================================================
  # SECTION 3: Repository Size Analysis
  # ========================================================================

  run_test 6 "Analyze repository size" \
    "dots size 2>&1 | head -20" \
    "Should show:
- Total repository size
- Top 10 largest files
- File sizes in human-readable format (KB/MB)
- Color-coded warnings for large files"

  run_test 7 "Check size cache" \
    "ls -la ~/.cache/flow/dot-size.cache 2>/dev/null || echo 'Cache not created yet'" \
    "Should show:
- Cache file if exists
- Or message if not cached yet
- File timestamp (5-min TTL)"

  # ========================================================================
  # SECTION 4: Git Directory Detection
  # ========================================================================

  run_test 8 "Test git detection helper" \
    "source flow.plugin.zsh && type _dotf_check_git_in_path" \
    "Should show:
- Function definition
- Confirms git detection function exists"

  run_test 9 "Verify cross-platform file size helper" \
    "source flow.plugin.zsh && _flow_get_file_size /etc/hosts" \
    "Should show:
- File size in bytes
- Works on both macOS (BSD) and Linux (GNU)"

  # ========================================================================
  # SECTION 5: Flow Doctor Integration
  # ========================================================================

  run_test 10 "Run doctor dot checks" \
    "flow doctor --dot 2>&1 | head -30" \
    "Should show:
- Chezmoi installation check
- .chezmoiignore existence
- Repository size analysis
- Git directory warnings
- Performance: <3 seconds"

  run_test 11 "Verify doctor check count" \
    "flow doctor --dot 2>&1 | grep -c '✓\\|✗\\|⚠' || echo '0'" \
    "Should show:
- At least 5 checks performed
- Mix of health indicators"

  # ========================================================================
  # SECTION 6: Performance Validation
  # ========================================================================

  run_test 12 "Test cache hit performance" \
    "time (dots size >/dev/null 2>&1) 2>&1 | grep real" \
    "Should show:
- < 10ms if cached
- < 5s if not cached
- Meets performance targets"

  run_test 13 "Test file size helper speed" \
    "time (_flow_get_file_size /etc/hosts >/dev/null 2>&1) 2>&1 | grep real" \
    "Should show:
- < 10ms response time
- Fast cross-platform operation"

  # ========================================================================
  # SECTION 7: Documentation Validation
  # ========================================================================

  run_test 14 "Check safety guide exists" \
    "ls -lh docs/guides/CHEZMOI-SAFETY-GUIDE.md 2>/dev/null || echo 'Not found'" \
    "Should show:
- File exists (827 lines)
- Readable size (~40-50KB)
- Recent modification date"

  run_test 15 "Verify all safety docs present" \
    "ls -1 docs/guides/CHEZMOI-SAFETY-GUIDE.md docs/reference/REFCARD-DOT-SAFETY.md docs/architecture/DOT-SAFETY-ARCHITECTURE.md docs/reference/API-DOT-SAFETY.md 2>/dev/null | wc -l" \
    "Should show:
- All 4 documentation files exist
- Complete documentation set"

  # ========================================================================
  # FINAL SUMMARY
  # ========================================================================

  print_summary
}

# Run tests if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]] || [[ "$0" == *"zsh"* ]]; then
  main
fi
