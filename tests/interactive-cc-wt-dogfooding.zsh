#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# INTERACTIVE DOGFOODING TEST: cc wt (Worktree + Claude)
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: ADHD-friendly interactive test that validates cc wt commands
#          by showing expected output and asking user to confirm matches
#
# Usage: ./interactive-cc-wt-dogfooding.zsh
#
# What it tests:
#   - cc wt help
#   - cc wt (list worktrees)
#   - cc wt <branch> (create/use worktree)
#   - Mode chaining (yolo, plan, opus)
#   - Aliases (ccw, ccwy, ccwp)
#   - User validation of output
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

# Themed emojis for worktree/branching concept
TREE='🌳'
BRANCH='🌿'
ROBOT='🤖'
CHECK='✅'
CROSS='❌'
ROCKET='🚀'
THINKING='🤔'
STAR='⭐'
COFFEE='☕'
CELEBRATE='🎉'

# Game state
TASKS_COMPLETED=0
TOTAL_TASKS=8
ENERGY=100

# Test state
SCRIPT_DIR="${0:A:h}"
TEST_DIR=""
ORIGINAL_DIR="$PWD"

# ══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

print_banner() {
    clear
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${TREE}  ${BOLD}CC WT DOGFOODING TEST${NC}  ${BRANCH}                          ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}     ${DIM}Worktree + Claude Integration${NC}                          ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_status() {
    local progress=$((TASKS_COMPLETED * 100 / TOTAL_TASKS))
    local bar_filled=$((progress / 5))
    local bar_empty=$((20 - bar_filled))

    echo -e "${CYAN}╭─ Progress ────────────────────────────────────────────────╮${NC}"
    printf "${CYAN}│${NC} ["
    for ((i=0; i<bar_filled; i++)); do printf "${GREEN}█${NC}"; done
    for ((i=0; i<bar_empty; i++)); do printf "${DIM}░${NC}"; done
    printf "] ${GREEN}$progress%%${NC}\n"
    echo -e "${CYAN}│${NC} Tasks: ${GREEN}$TASKS_COMPLETED${NC}/${TOTAL_TASKS} completed  Energy: ${YELLOW}$ENERGY%${NC}"
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────╯${NC}"
    echo ""
}

drink_coffee() {
    ENERGY=$((ENERGY + 20))
    [[ $ENERGY -gt 100 ]] && ENERGY=100
    echo -e "\n${COFFEE} ${GREEN}Energy boost! +20%${NC}\n"
    sleep 1
}

complete_task() {
    ((TASKS_COMPLETED++))
    ENERGY=$((ENERGY - 10))
    [[ $ENERGY -lt 0 ]] && ENERGY=0
    echo -e "\n${CHECK} ${GREEN}Task completed!${NC} ${STAR}"
    sleep 0.5
}

skip_task() {
    echo -e "\n${YELLOW}⏭ Skipped${NC}"
    sleep 0.3
}

fail_task() {
    ENERGY=$((ENERGY - 5))
    echo -e "\n${CROSS} ${RED}Something went wrong${NC}"
    sleep 0.5
}

press_any_key() {
    echo -e "\n${DIM}Press any key to continue...${NC}"
    read -k 1
}

ask_yes_no() {
    local prompt=$1
    echo -e "\n${THINKING} ${prompt}"
    echo -e "   ${GREEN}[y]${NC} Yes   ${RED}[n]${NC} No   ${YELLOW}[s]${NC} Skip   ${BLUE}[c]${NC} Coffee break"
    read -k 1 answer
    echo ""
    case $answer in
        y|Y) return 0 ;;
        n|N) return 1 ;;
        s|S) return 2 ;;
        c|C) drink_coffee; return 3 ;;
        *) return 1 ;;
    esac
}

create_test_repo() {
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR" || return 1
    git init --quiet
    git config user.email "test@test.com"
    git config user.name "Test User"
    echo "# Test Project" > README.md
    git add README.md
    git commit --quiet -m "Initial commit"
    export FLOW_WORKTREE_DIR="$TEST_DIR/.worktrees"
    echo -e "${DIM}Created test repo at $TEST_DIR${NC}"
}

cleanup_test_repo() {
    cd "$ORIGINAL_DIR" || return
    if [[ -n "$TEST_DIR" && -d "$TEST_DIR" ]]; then
        git -C "$TEST_DIR" worktree list --porcelain 2>/dev/null | \
            grep "^worktree " | cut -d' ' -f2 | \
            while read wt; do
                [[ "$wt" != "$TEST_DIR" ]] && git -C "$TEST_DIR" worktree remove --force "$wt" 2>/dev/null
            done
        command rm -rf "$TEST_DIR" 2>/dev/null || true
    fi
    TEST_DIR=""
}

# ══════════════════════════════════════════════════════════════════════════════
# LOAD PLUGIN
# ══════════════════════════════════════════════════════════════════════════════

source "${SCRIPT_DIR}/../flow.plugin.zsh" 2>/dev/null

# ══════════════════════════════════════════════════════════════════════════════
# TESTS
# ══════════════════════════════════════════════════════════════════════════════

run_tests() {
    # ─────────────────────────────────────────────────────────────────────────
    # TEST 1: Help System
    # ─────────────────────────────────────────────────────────────────────────
    print_banner
    print_status

    echo -e "${BOLD}${BRANCH} Test 1: Help System${NC}"
    echo -e "${DIM}Running: cc wt help${NC}"
    echo ""
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
    cc wt help
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"

    ask_yes_no "Does the help show CC WT title and commands?"
    case $? in
        0) complete_task ;;
        1) fail_task ;;
        2) skip_task ;;
        3) run_tests; return ;;
    esac

    press_any_key

    # ─────────────────────────────────────────────────────────────────────────
    # TEST 2: Aliases Exist
    # ─────────────────────────────────────────────────────────────────────────
    print_banner
    print_status

    echo -e "${BOLD}${BRANCH} Test 2: Aliases${NC}"
    echo -e "${DIM}Checking: ccw, ccwy, ccwp${NC}"
    echo ""
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
    echo "ccw  → $(alias ccw 2>/dev/null || echo 'NOT FOUND')"
    echo "ccwy → $(alias ccwy 2>/dev/null || echo 'NOT FOUND')"
    echo "ccwp → $(alias ccwp 2>/dev/null || echo 'NOT FOUND')"
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"

    ask_yes_no "Are all three aliases defined correctly?"
    case $? in
        0) complete_task ;;
        1) fail_task ;;
        2) skip_task ;;
        3) run_tests; return ;;
    esac

    press_any_key

    # ─────────────────────────────────────────────────────────────────────────
    # TEST 3: List Worktrees (no args)
    # ─────────────────────────────────────────────────────────────────────────
    print_banner
    print_status

    echo -e "${BOLD}${BRANCH} Test 3: List Worktrees${NC}"
    echo -e "${DIM}Creating test repo and running: cc wt${NC}"
    echo ""

    create_test_repo

    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
    cc wt
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"

    ask_yes_no "Does it show worktree list and usage hint?"
    case $? in
        0) complete_task ;;
        1) fail_task ;;
        2) skip_task ;;
        3) cleanup_test_repo; run_tests; return ;;
    esac

    cleanup_test_repo
    press_any_key

    # ─────────────────────────────────────────────────────────────────────────
    # TEST 4: Create Worktree
    # ─────────────────────────────────────────────────────────────────────────
    print_banner
    print_status

    echo -e "${BOLD}${TREE} Test 4: Create Worktree${NC}"
    echo -e "${DIM}This will attempt to create a worktree and launch Claude.${NC}"
    echo -e "${DIM}(Press Ctrl+C in Claude to exit back to test)${NC}"
    echo ""

    create_test_repo

    echo -e "${YELLOW}NOTE: This will actually launch Claude in a worktree!${NC}"
    ask_yes_no "Ready to test cc wt feature/test-branch?"
    case $? in
        0)
            echo -e "${ROCKET} Running: cc wt feature/test-branch"
            echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
            cc wt feature/test-branch
            echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"

            # Verify worktree was created
            if [[ -d "$FLOW_WORKTREE_DIR" ]]; then
                echo -e "\n${GREEN}Worktree directory created: $FLOW_WORKTREE_DIR${NC}"
                ls -la "$FLOW_WORKTREE_DIR"
            fi

            ask_yes_no "Did Claude launch in the worktree?"
            case $? in
                0) complete_task ;;
                1) fail_task ;;
                *) skip_task ;;
            esac
            ;;
        2) skip_task ;;
        3) cleanup_test_repo; run_tests; return ;;
        *) skip_task ;;
    esac

    cleanup_test_repo
    press_any_key

    # ─────────────────────────────────────────────────────────────────────────
    # TEST 5: YOLO Mode
    # ─────────────────────────────────────────────────────────────────────────
    print_banner
    print_status

    echo -e "${BOLD}${ROCKET} Test 5: YOLO Mode${NC}"
    echo -e "${DIM}Testing: cc wt yolo feature/yolo-test${NC}"
    echo ""

    create_test_repo

    echo -e "${YELLOW}NOTE: This will launch Claude in YOLO mode (no confirmations)!${NC}"
    ask_yes_no "Ready to test YOLO mode?"
    case $? in
        0)
            echo -e "${ROCKET} Running: cc wt yolo feature/yolo-test"
            echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
            cc wt yolo feature/yolo-test
            echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"

            ask_yes_no "Did Claude launch with YOLO mode enabled?"
            case $? in
                0) complete_task ;;
                1) fail_task ;;
                *) skip_task ;;
            esac
            ;;
        2) skip_task ;;
        3) cleanup_test_repo; run_tests; return ;;
        *) skip_task ;;
    esac

    cleanup_test_repo
    press_any_key

    # ─────────────────────────────────────────────────────────────────────────
    # TEST 6: Plan Mode
    # ─────────────────────────────────────────────────────────────────────────
    print_banner
    print_status

    echo -e "${BOLD}${THINKING} Test 6: Plan Mode${NC}"
    echo -e "${DIM}Testing: cc wt plan feature/plan-test${NC}"
    echo ""

    create_test_repo

    ask_yes_no "Ready to test Plan mode?"
    case $? in
        0)
            echo -e "${THINKING} Running: cc wt plan feature/plan-test"
            echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
            cc wt plan feature/plan-test
            echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"

            ask_yes_no "Did Claude launch in Plan mode?"
            case $? in
                0) complete_task ;;
                1) fail_task ;;
                *) skip_task ;;
            esac
            ;;
        2) skip_task ;;
        3) cleanup_test_repo; run_tests; return ;;
        *) skip_task ;;
    esac

    cleanup_test_repo
    press_any_key

    # ─────────────────────────────────────────────────────────────────────────
    # TEST 7: ccwy Alias (Shortcut)
    # ─────────────────────────────────────────────────────────────────────────
    print_banner
    print_status

    echo -e "${BOLD}${STAR} Test 7: ccwy Alias${NC}"
    echo -e "${DIM}Testing the ccwy shortcut (= cc wt yolo)${NC}"
    echo ""

    create_test_repo

    ask_yes_no "Ready to test ccwy feature/shortcut-test?"
    case $? in
        0)
            echo -e "${STAR} Running: ccwy feature/shortcut-test"
            echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
            ccwy feature/shortcut-test
            echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"

            ask_yes_no "Did the alias work (YOLO mode in worktree)?"
            case $? in
                0) complete_task ;;
                1) fail_task ;;
                *) skip_task ;;
            esac
            ;;
        2) skip_task ;;
        3) cleanup_test_repo; run_tests; return ;;
        *) skip_task ;;
    esac

    cleanup_test_repo
    press_any_key

    # ─────────────────────────────────────────────────────────────────────────
    # TEST 8: cc help integration
    # ─────────────────────────────────────────────────────────────────────────
    print_banner
    print_status

    echo -e "${BOLD}${ROBOT} Test 8: CC Help Integration${NC}"
    echo -e "${DIM}Checking if cc help includes WORKTREE section${NC}"
    echo ""
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
    cc help | grep -A 10 -i "worktree" || echo "No WORKTREE section found"
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"

    ask_yes_no "Does cc help show the WORKTREE section with cc wt commands?"
    case $? in
        0) complete_task ;;
        1) fail_task ;;
        2) skip_task ;;
        3) run_tests; return ;;
    esac

    press_any_key
}

# ══════════════════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════════════════

# Run tests
run_tests

# ══════════════════════════════════════════════════════════════════════════════
# FINAL RESULTS
# ══════════════════════════════════════════════════════════════════════════════

print_banner
print_status

echo -e "${BOLD}${CELEBRATE} DOGFOODING COMPLETE! ${CELEBRATE}${NC}"
echo ""

if [[ $TASKS_COMPLETED -eq $TOTAL_TASKS ]]; then
    echo -e "${GREEN}${TREE} Perfect score! All tests passed! ${TREE}${NC}"
    echo -e "${DIM}The cc wt feature is working great!${NC}"
elif [[ $TASKS_COMPLETED -ge $((TOTAL_TASKS * 3 / 4)) ]]; then
    echo -e "${GREEN}${BRANCH} Great job! Most tests passed.${NC}"
    echo -e "${DIM}Minor issues might need attention.${NC}"
elif [[ $TASKS_COMPLETED -ge $((TOTAL_TASKS / 2)) ]]; then
    echo -e "${YELLOW}${THINKING} Some tests need work.${NC}"
    echo -e "${DIM}Check the failing areas.${NC}"
else
    echo -e "${RED}${CROSS} Several issues found.${NC}"
    echo -e "${DIM}Review the test failures.${NC}"
fi

echo ""
echo -e "${DIM}Thanks for dogfooding! ${ROBOT}${NC}"
echo ""

# Cleanup
cleanup_test_repo
