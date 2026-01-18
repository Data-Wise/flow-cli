#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# INTERACTIVE WT DOGFOODING TEST
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: ADHD-friendly interactive test that validates WT workflow enhancement
#          by showing expected output and asking user to confirm matches
#
# Usage: ./tests/interactive-wt-dogfooding.zsh
#
# What it tests:
#   Phase 1: wt overview display
#   Phase 2: pick wt actions (delete, refresh)
#   Integration: wt + pick wt workflow
#
# Features:
#   - Dog feeding game mechanics
#   - Visual progress tracking
#   - Clear expected vs actual comparisons
#   - Single keystroke validation (y/n/q)
#
# ══════════════════════════════════════════════════════════════════════════════

# Colors and emojis
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

DOG='🐕'
FOOD='🥩'
BOWL='🥣'
HAPPY='😊'
SAD='😢'
STAR='⭐'
CHECK='✅'
CROSS='❌'
THINKING='🤔'
EYES='👀'
QUESTION='❓'
TREE='🌳'
TRASH='🗑️'
REFRESH='⟳'

# Game state
HUNGER=100
HAPPINESS=50
TASKS_COMPLETED=0
TOTAL_TASKS=10

# ══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

print_banner() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${TREE}  ${BOLD}INTERACTIVE WT DOGFOODING TEST${NC}  ${DOG}                  ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${DIM}Tests the WT Workflow Enhancement (Phases 1-2)${NC}"
    echo -e "${DIM}Spec: docs/specs/SPEC-wt-workflow-enhancement-2026-01-17.md${NC}"
    echo ""
}

print_dog_status() {
    local mood
    if [[ $HAPPINESS -gt 70 ]]; then
        mood="${GREEN}${HAPPY} Very Happy${NC}"
    elif [[ $HAPPINESS -gt 40 ]]; then
        mood="${YELLOW}${THINKING} Okay${NC}"
    else
        mood="${RED}${SAD} Sad${NC}"
    fi

    echo ""
    echo -e "${CYAN}╭─ Dog Status ─────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} Hunger:    ${YELLOW}$HUNGER%${NC}"
    echo -e "${CYAN}│${NC} Happiness: $mood"
    echo -e "${CYAN}│${NC} Tasks:     ${GREEN}$TASKS_COMPLETED${NC}/${TOTAL_TASKS} completed"
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────╯${NC}"
    echo ""
}

feed_dog() {
    local amount=$1
    HUNGER=$((HUNGER - amount))
    HAPPINESS=$((HAPPINESS + amount / 2))

    # Cap values
    [[ $HUNGER -lt 0 ]] && HUNGER=0
    [[ $HAPPINESS -gt 100 ]] && HAPPINESS=100

    echo -e "${GREEN}${FOOD} Fed the dog! ${HAPPY}${NC}"
    ((TASKS_COMPLETED++))
}

disappoint_dog() {
    HAPPINESS=$((HAPPINESS - 10))
    [[ $HAPPINESS -lt 0 ]] && HAPPINESS=0
    echo -e "${RED}The dog is disappointed ${SAD}${NC}"
}

press_any_key() {
    echo ""
    echo -e "${DIM}Press any key to continue...${NC}"
    read -k 1 -s
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST EXECUTION FRAMEWORK
# ══════════════════════════════════════════════════════════════════════════════

run_test() {
    local test_num=$1
    local test_name="$2"
    local expected="$3"
    local command="$4"

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}TEST $test_num/$TOTAL_TASKS: $test_name${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Show expected behavior
    echo -e "${YELLOW}${EYES} EXPECTED:${NC}"
    echo -e "${DIM}$expected${NC}"
    echo ""

    # Show command being run
    echo -e "${BLUE}${STAR} COMMAND:${NC}"
    echo -e "${CYAN}  $ $command${NC}"
    echo ""

    press_any_key

    # Run the actual command
    echo -e "${MAGENTA}${THINKING} ACTUAL OUTPUT:${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────${NC}"
    eval "$command"
    echo -e "${DIM}────────────────────────────────────────────────────────────${NC}"
    echo ""

    # Ask for validation
    echo -e "${QUESTION} ${BOLD}Does the output match expectations?${NC}"
    echo -e "  ${GREEN}[y]${NC} Yes, test passed"
    echo -e "  ${RED}[n]${NC} No, test failed"
    echo -e "  ${YELLOW}[q]${NC} Quit testing"
    echo ""
    echo -n "Your choice: "

    local choice
    read -k 1 choice
    echo ""

    case "$choice" in
        y|Y)
            feed_dog 10
            print_dog_status
            return 0
            ;;
        n|N)
            disappoint_dog
            print_dog_status
            return 1
            ;;
        q|Q)
            echo ""
            echo -e "${YELLOW}Quitting test suite...${NC}"
            print_final_summary
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Treating as failure.${NC}"
            disappoint_dog
            print_dog_status
            return 1
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 1 TESTS: wt Overview
# ══════════════════════════════════════════════════════════════════════════════

test_phase1() {
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  PHASE 1: Enhanced wt Default${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    run_test 1 "wt overview display" \
        "Should show formatted table with:
  - Header: 🌳 Worktrees (N total)
  - Columns: BRANCH | STATUS | SESSION | PATH
  - Status icons: ✅ active, 🧹 merged, ⚠️ stale, 🏠 main
  - Session indicators: 🟢 active, 🟡 recent, ⚪ none
  - Footer with tip about filtering" \
        "wt"

    run_test 2 "wt with filter" \
        "Should show only worktrees matching 'flow':
  - Filtered header showing count
  - Same table format
  - Only flow-cli related worktrees" \
        "wt flow"

    run_test 3 "wt list (passthrough)" \
        "Should show raw git worktree list output:
  - Multiple lines with paths
  - Branch names in brackets
  - HEAD indicators" \
        "wt list"

    run_test 4 "wt help" \
        "Should show help with:
  - Usage examples for wt, wt <filter>
  - Updated MOST COMMON section
  - Examples showing wt flow
  - Tip about pick wt" \
        "wt help"
}

# ══════════════════════════════════════════════════════════════════════════════
# PHASE 2 TESTS: pick wt Actions
# ══════════════════════════════════════════════════════════════════════════════

test_phase2_info() {
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  PHASE 2: pick wt Actions${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    echo -e "${YELLOW}${EYES} NOTE:${NC}"
    echo "  Phase 2 tests require interactive fzf usage."
    echo "  We'll test the helper functions and give instructions for manual testing."
    echo ""
    press_any_key
}

test_phase2() {
    test_phase2_info

    run_test 5 "pick help mentions worktree actions" \
        "Should show in help output:
  - WORKTREE ACTIONS section
  - Tab for multi-select
  - Ctrl-X for delete
  - Ctrl-R for refresh" \
        "pick --help | grep -A 5 'WORKTREE ACTIONS'"

    run_test 6 "Refresh action function exists" \
        "Should display:
  - Refreshing worktree cache message
  - Cache cleared confirmation
  - Updated wt overview output" \
        "_pick_wt_refresh"

    # Manual test instructions
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}MANUAL TEST: pick wt delete action${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "To test the delete action manually:"
    echo ""
    echo "  1. Run: ${CYAN}pick wt${NC}"
    echo "  2. Use ${CYAN}Tab${NC} to select one or more worktrees"
    echo "  3. Press ${CYAN}Ctrl-X${NC} to trigger delete action"
    echo "  4. Confirm deletion prompts appear with [y/n/a/q] options"
    echo "  5. Choose 'n' to skip (don't actually delete)"
    echo "  6. Verify cache invalidation message"
    echo ""
    echo -e "${YELLOW}${QUESTION} Did you test pick wt delete manually?${NC}"
    echo -e "  ${GREEN}[y]${NC} Yes, it worked"
    echo -e "  ${RED}[n]${NC} No, there were issues"
    echo -e "  ${YELLOW}[s]${NC} Skip (will test later)"
    echo ""
    echo -n "Your choice: "

    local choice
    read -k 1 choice
    echo ""

    case "$choice" in
        y|Y)
            feed_dog 15
            print_dog_status
            ;;
        n|N)
            disappoint_dog
            print_dog_status
            ;;
        s|S)
            echo -e "${YELLOW}Skipped - remember to test later!${NC}"
            ;;
    esac

    # Similar for refresh
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}MANUAL TEST: pick wt refresh action${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "To test the refresh action manually:"
    echo ""
    echo "  1. Run: ${CYAN}pick wt${NC}"
    echo "  2. Press ${CYAN}Ctrl-R${NC} to trigger refresh"
    echo "  3. Verify 'Refreshing worktree cache...' message"
    echo "  4. Verify 'Cache cleared' message"
    echo "  5. Verify updated wt overview appears"
    echo ""
    echo -e "${YELLOW}${QUESTION} Did you test pick wt refresh manually?${NC}"
    echo -e "  ${GREEN}[y]${NC} Yes, it worked"
    echo -e "  ${RED}[n]${NC} No, there were issues"
    echo -e "  ${YELLOW}[s]${NC} Skip (will test later)"
    echo ""
    echo -n "Your choice: "

    read -k 1 choice
    echo ""

    case "$choice" in
        y|Y)
            feed_dog 15
            print_dog_status
            ;;
        n|N)
            disappoint_dog
            print_dog_status
            ;;
        s|S)
            echo -e "${YELLOW}Skipped - remember to test later!${NC}"
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# INTEGRATION TESTS
# ══════════════════════════════════════════════════════════════════════════════

test_integration() {
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  INTEGRATION: Complete Workflow${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    run_test 7 "Session indicators in wt overview" \
        "Should show session status for current worktree:
  - Current worktree should show 🟢 or 🟡
  - Other worktrees may show ⚪
  - Session column properly aligned" \
        "wt"

    run_test 8 "Status icons reflect git state" \
        "Check status icons make sense:
  - Main branch shows 🏠 main
  - Unmerged feature branches show ✅ active
  - If any merged branches, show 🧹 merged" \
        "wt"

    run_test 9 "Filter works across projects" \
        "If you have multiple projects with worktrees:
  - wt <project> filters correctly
  - Count in header matches filtered results
  - Tip still shows at bottom" \
        "wt $(basename $(pwd))"

    run_test 10 "Help text consistency" \
        "Both commands should mention each other:
  - wt help mentions 'pick wt for interactive'
  - pick help mentions wt overview" \
        "wt help && echo '\n---\n' && pick --help | grep -B2 -A2 'pick wt'"
}

# ══════════════════════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

print_final_summary() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}FINAL RESULTS${NC}                                           ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "  Tasks Completed: ${GREEN}$TASKS_COMPLETED${NC}/${TOTAL_TASKS}"
    echo -e "  Dog Happiness:   ${YELLOW}$HAPPINESS%${NC}"
    echo ""

    if [[ $HAPPINESS -gt 80 ]]; then
        echo -e "${GREEN}${BOLD}${HAPPY} The dog is VERY HAPPY! Great job testing! ${HAPPY}${NC}"
    elif [[ $HAPPINESS -gt 50 ]]; then
        echo -e "${YELLOW}${THINKING} The dog is content. Some tests could be improved.${NC}"
    else
        echo -e "${RED}${SAD} The dog needs more treats. Review failed tests.${NC}"
    fi

    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "  - Review any failed tests"
    echo "  - Complete any skipped manual tests"
    echo "  - Run unit tests: ./tests/test-wt-enhancement-unit.zsh"
    echo "  - Update documentation if needed"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════════════════

main() {
    print_banner
    print_dog_status

    # Verify we're in the right environment
    if ! source flow.plugin.zsh 2>/dev/null; then
        echo -e "${RED}Failed to load flow.plugin.zsh${NC}"
        echo "Make sure you're in the flow-cli directory"
        exit 1
    fi

    echo -e "${GREEN}✓ Plugin loaded successfully${NC}"
    press_any_key

    # Run test phases
    test_phase1
    test_phase2
    test_integration

    # Final summary
    print_final_summary
}

main "$@"
