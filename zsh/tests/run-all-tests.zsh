#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# RUN-ALL-TESTS - Execute all shell configuration tests
# ══════════════════════════════════════════════════════════════════════════════
#
# Usage: ./run-all-tests.zsh [--quick]
#
# Options:
#   --quick    Skip performance test (faster)
#
# ══════════════════════════════════════════════════════════════════════════════

# Colors
_RED='\033[31m'
_GREEN='\033[32m'
_YELLOW='\033[33m'
_NC='\033[0m'
_BOLD='\033[1m'

# Parse args
QUICK=false
[[ "$1" == "--quick" ]] && QUICK=true

# Test directory
TEST_DIR="${0:A:h}"

# Results
PASSED=0
FAILED=0
SKIPPED=0

echo ""
echo -e "${_BOLD}╭─────────────────────────────────────────────────────────────╮${_NC}"
echo -e "${_BOLD}│           ZSH Configuration Test Suite                      │${_NC}"
echo -e "${_BOLD}╰─────────────────────────────────────────────────────────────╯${_NC}"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Run a test and track results
# ─────────────────────────────────────────────────────────────────────────────

run_test() {
    local name=$1
    local script=$2
    local skip=${3:-false}

    echo -e "${_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_NC}"
    echo -e "${_BOLD}  $name${_NC}"
    echo -e "${_BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_NC}"
    echo ""

    if [[ "$skip" == "true" ]]; then
        echo -e "  ${_YELLOW}SKIPPED${_NC} (use without --quick to run)"
        ((SKIPPED++))
        echo ""
        return
    fi

    if [[ -f "$script" ]]; then
        chmod +x "$script"
        if "$script"; then
            ((PASSED++))
        else
            ((FAILED++))
        fi
    else
        echo -e "  ${_RED}ERROR${_NC}: Test script not found: $script"
        ((FAILED++))
    fi

    echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# Run Tests
# ─────────────────────────────────────────────────────────────────────────────

run_test "Duplicate Definition Check" "$TEST_DIR/test-duplicates.zsh"
run_test "Dispatcher Function Tests" "$TEST_DIR/test-dispatchers.zsh"
run_test "Startup Performance Test" "$TEST_DIR/test-performance.zsh" "$QUICK"

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────

echo -e "${_BOLD}╭─────────────────────────────────────────────────────────────╮${_NC}"
echo -e "${_BOLD}│                    Final Summary                            │${_NC}"
echo -e "${_BOLD}╰─────────────────────────────────────────────────────────────╯${_NC}"
echo ""
echo -e "  ${_GREEN}Passed:${_NC}  $PASSED"
echo -e "  ${_RED}Failed:${_NC}  $FAILED"
echo -e "  ${_YELLOW}Skipped:${_NC} $SKIPPED"
echo ""

if [[ $FAILED -gt 0 ]]; then
    echo -e "  ${_RED}${_BOLD}OVERALL: FAIL${_NC}"
    echo ""
    echo "  Fix the failing tests before committing."
    exit 1
else
    echo -e "  ${_GREEN}${_BOLD}OVERALL: PASS${_NC}"
    exit 0
fi
