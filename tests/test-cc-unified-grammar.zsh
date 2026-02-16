#!/usr/bin/env zsh
# Test CC Unified Grammar (v4.8.0)
# Tests both mode-first and target-first patterns

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

source "$SCRIPT_DIR/test-framework.zsh"

# ============================================================================
# SETUP
# ============================================================================

setup() {
    # Load core
    source "$PROJECT_ROOT/lib/core.zsh"

    # Load dispatcher
    source "$PROJECT_ROOT/lib/dispatchers/cc-dispatcher.zsh"

    # Mock pick function
    pick() {
        local args=("$@")
        if [[ "$1" == "--no-claude" ]]; then
            shift
            echo "PICK_CALLED_NO_CLAUDE:$@"
        else
            echo "PICK_CALLED:$@"
        fi
        return 0
    }

    # Mock claude function
    claude() {
        echo "CLAUDE_CALLED:$@"
    }
}

# ============================================================================
# TEST RUNNER HELPER
# ============================================================================

run_test() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"

    test_case "$test_name"

    if [[ "$actual" == *"$expected"* ]]; then
        test_pass
    else
        test_fail "Expected: $expected, Got: $actual"
    fi
}

# ============================================================================
# TESTS
# ============================================================================

setup

test_suite_start "CC Unified Grammar"

# Group 1: Mode-First Patterns (Current Behavior)
echo "${YELLOW}Test Group 1: Mode-First Patterns${RESET}"

run_test "cc opus (mode-first, HERE)" \
    "CLAUDE_CALLED:--model opus --permission-mode acceptEdits" \
    "$(cc opus 2>&1)"

run_test "cc haiku (mode-first, HERE)" \
    "CLAUDE_CALLED:--model haiku --permission-mode acceptEdits" \
    "$(cc haiku 2>&1)"

run_test "cc yolo (mode-first, HERE)" \
    "CLAUDE_CALLED:--dangerously-skip-permissions" \
    "$(cc yolo 2>&1)"

run_test "cc plan (mode-first, HERE)" \
    "CLAUDE_CALLED:--permission-mode plan" \
    "$(cc plan 2>&1)"

run_test "cc opus pick (mode-first + picker)" \
    "PICK_CALLED_NO_CLAUDE" \
    "$(cc opus pick 2>&1)"

run_test "cc haiku pick (mode-first + picker)" \
    "PICK_CALLED_NO_CLAUDE" \
    "$(cc haiku pick 2>&1)"

echo ""

# Group 2: Target-First Patterns (NEW)
echo "${YELLOW}Test Group 2: Target-First Patterns (NEW)${RESET}"

run_test "cc pick opus (target-first)" \
    "PICK_CALLED_NO_CLAUDE" \
    "$(cc pick opus 2>&1)"

run_test "cc pick haiku (target-first)" \
    "PICK_CALLED_NO_CLAUDE" \
    "$(cc pick haiku 2>&1)"

run_test "cc pick yolo (target-first)" \
    "PICK_CALLED_NO_CLAUDE" \
    "$(cc pick yolo 2>&1)"

run_test "cc pick plan (target-first)" \
    "PICK_CALLED_NO_CLAUDE" \
    "$(cc pick plan 2>&1)"

echo ""

# Group 3: Explicit HERE Targets (NEW)
echo "${YELLOW}Test Group 3: Explicit HERE Targets (NEW)${RESET}"

run_test "cc . (explicit HERE)" \
    "CLAUDE_CALLED:--permission-mode acceptEdits" \
    "$(cc . 2>&1)"

run_test "cc here (explicit HERE)" \
    "CLAUDE_CALLED:--permission-mode acceptEdits" \
    "$(cc here 2>&1)"

run_test "cc opus . (mode + explicit HERE)" \
    "CLAUDE_CALLED:--model opus --permission-mode acceptEdits" \
    "$(cc opus . 2>&1)"

run_test "cc haiku here (mode + explicit HERE)" \
    "CLAUDE_CALLED:--model haiku --permission-mode acceptEdits" \
    "$(cc haiku here 2>&1)"

run_test "cc . opus (HERE + mode, target-first)" \
    "CLAUDE_CALLED:--model opus --permission-mode acceptEdits" \
    "$(cc . opus 2>&1)"

run_test "cc here haiku (HERE + mode, target-first)" \
    "CLAUDE_CALLED:--model haiku --permission-mode acceptEdits" \
    "$(cc here haiku 2>&1)"

echo ""

# Group 4: Direct Project Jump (Mode-First)
echo "${YELLOW}Test Group 4: Direct Project Jump${RESET}"

run_test "cc opus testproject (mode + project)" \
    "PICK_CALLED_NO_CLAUDE:testproject" \
    "$(cc opus testproject 2>&1)"

run_test "cc testproject opus (project + mode, target-first)" \
    "PICK_CALLED_NO_CLAUDE:testproject" \
    "$(cc testproject opus 2>&1)"

echo ""

# Group 5: Short Aliases
echo "${YELLOW}Test Group 5: Short Aliases${RESET}"

run_test "cc o (opus short)" \
    "CLAUDE_CALLED:--model opus" \
    "$(cc o 2>&1)"

run_test "cc h (haiku short)" \
    "CLAUDE_CALLED:--model haiku" \
    "$(cc h 2>&1)"

run_test "cc y (yolo short)" \
    "CLAUDE_CALLED:--dangerously-skip-permissions" \
    "$(cc y 2>&1)"

run_test "cc p (plan short)" \
    "CLAUDE_CALLED:--permission-mode plan" \
    "$(cc p 2>&1)"

run_test "cc o pick (short + picker)" \
    "PICK_CALLED_NO_CLAUDE" \
    "$(cc o pick 2>&1)"

run_test "cc pick h (picker + short, target-first)" \
    "PICK_CALLED_NO_CLAUDE" \
    "$(cc pick h 2>&1)"

echo ""

# Group 6: Edge Cases
echo "${YELLOW}Test Group 6: Edge Cases${RESET}"

run_test "cc (no args, default HERE)" \
    "CLAUDE_CALLED:--permission-mode acceptEdits" \
    "$(cc 2>&1)"

run_test "cc pick (picker only, no mode)" \
    "PICK_CALLED_NO_CLAUDE" \
    "$(cc pick 2>&1)"

echo ""

# Group 7: Pick with Filters (Mode-First)
echo "${YELLOW}Test Group 7: Pick with Filters${RESET}"

run_test "cc opus pick wt (mode + pick + filter)" \
    "PICK_CALLED_NO_CLAUDE:wt" \
    "$(cc opus pick wt 2>&1)"

run_test "cc pick wt opus (pick + filter + mode, target-first)" \
    "PICK_CALLED_NO_CLAUDE:wt" \
    "$(cc pick wt opus 2>&1)"

run_test "cc haiku pick dev (mode + pick + filter)" \
    "PICK_CALLED_NO_CLAUDE:dev" \
    "$(cc haiku pick dev 2>&1)"

run_test "cc pick dev haiku (pick + filter + mode, target-first)" \
    "PICK_CALLED_NO_CLAUDE:dev" \
    "$(cc pick dev haiku 2>&1)"

# ============================================================================
# SUMMARY
# ============================================================================

test_suite_end
exit $?
