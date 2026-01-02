#!/usr/bin/env zsh
# Test CC Unified Grammar (v4.8.0)
# Tests both mode-first and target-first patterns

# ============================================================================
# TEST FRAMEWORK
# ============================================================================

TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_test() {
    echo -n "${CYAN}Testing:${NC} $1 ... "
}

pass() {
    echo "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
}

fail() {
    echo "${RED}✗ FAIL${NC} - $1"
    ((TESTS_FAILED++))
}

# ============================================================================
# SETUP
# ============================================================================

setup() {
    echo ""
    echo "${YELLOW}Setting up test environment...${NC}"

    # Get project root
    local project_root=""

    # Method 1: From script location
    if [[ -n "${0:A}" ]]; then
        project_root="${0:A:h:h}"
    fi

    # Method 2: Check if we're already in the project
    if [[ -z "$project_root" || ! -f "$project_root/lib/core.zsh" ]]; then
        if [[ -f "$PWD/lib/core.zsh" ]]; then
            project_root="$PWD"
        elif [[ -f "$PWD/../lib/core.zsh" ]]; then
            project_root="$PWD/.."
        fi
    fi

    # Method 3: Error if not found
    if [[ -z "$project_root" || ! -f "$project_root/lib/core.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root - run from project directory${NC}"
        exit 1
    fi

    echo "  Project root: $project_root"

    # Load core
    source "$project_root/lib/core.zsh"

    # Load dispatcher
    source "$project_root/lib/dispatchers/cc-dispatcher.zsh"

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

    echo "${GREEN}✓${NC} Environment set up"
}

# ============================================================================
# TEST RUNNER
# ============================================================================

run_test() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"

    log_test "$test_name"

    if [[ "$actual" == *"$expected"* ]]; then
        pass
    else
        fail "Expected: $expected, Got: $actual"
    fi
}

# ============================================================================
# TESTS
# ============================================================================

setup

echo ""
echo "🧪 Testing CC Unified Grammar"
echo "=============================="
echo ""

# Group 1: Mode-First Patterns (Current Behavior)
echo "${YELLOW}Test Group 1: Mode-First Patterns${NC}"

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
echo "${YELLOW}Test Group 2: Target-First Patterns (NEW)${NC}"

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
echo "${YELLOW}Test Group 3: Explicit HERE Targets (NEW)${NC}"

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
echo "${YELLOW}Test Group 4: Direct Project Jump${NC}"

run_test "cc opus testproject (mode + project)" \
    "PICK_CALLED_NO_CLAUDE:testproject" \
    "$(cc opus testproject 2>&1)"

run_test "cc testproject opus (project + mode, target-first)" \
    "PICK_CALLED_NO_CLAUDE:testproject" \
    "$(cc testproject opus 2>&1)"

echo ""

# Group 5: Short Aliases
echo "${YELLOW}Test Group 5: Short Aliases${NC}"

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
echo "${YELLOW}Test Group 6: Edge Cases${NC}"

run_test "cc (no args, default HERE)" \
    "CLAUDE_CALLED:--permission-mode acceptEdits" \
    "$(cc 2>&1)"

run_test "cc pick (picker only, no mode)" \
    "PICK_CALLED_NO_CLAUDE" \
    "$(cc pick 2>&1)"

echo ""

# Group 7: Pick with Filters (Mode-First)
echo "${YELLOW}Test Group 7: Pick with Filters${NC}"

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

echo ""

# ============================================================================
# SUMMARY
# ============================================================================

echo "=============================="
echo "Tests: $((TESTS_PASSED + TESTS_FAILED))"
echo "Passed: ${GREEN}$TESTS_PASSED${NC}"
echo "Failed: ${RED}$TESTS_FAILED${NC}"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo "${RED}❌ Some tests failed${NC}"
    exit 1
fi
