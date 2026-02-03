#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# HELP COMPLIANCE TEST SUITE
# ══════════════════════════════════════════════════════════════════════════════
#
# Validates all 12 dispatcher help functions against CONVENTIONS.md:173-199
# Uses lib/help-compliance.zsh shared validation library.
#
# Usage:    ./tests/test-help-compliance.zsh
# Expected: All 12 dispatchers pass all 9 compliance rules
#
# ══════════════════════════════════════════════════════════════════════════════

# Test framework setup
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
FAILED_TESTS=()

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Source flow-cli
FLOW_DIR="$(cd "$(dirname "$0")/.." && pwd)"
source "$FLOW_DIR/flow.plugin.zsh" 2>/dev/null || {
    # Fallback: source core + dispatchers individually
    source "$FLOW_DIR/lib/core.zsh" 2>/dev/null
    for f in "$FLOW_DIR"/lib/dispatchers/*.zsh; do
        source "$f" 2>/dev/null
    done
}

# Source the compliance library
source "$FLOW_DIR/lib/help-compliance.zsh" 2>/dev/null || {
    echo -e "${RED}ERROR: Cannot source lib/help-compliance.zsh${NC}"
    exit 1
}

echo "══════════════════════════════════════════════════════════════"
echo "  Help Compliance Test Suite (9 rules × 12 dispatchers)"
echo "══════════════════════════════════════════════════════════════"
echo ""

# ═══════════════════════════════════════════════════════════════════
# Test: Each dispatcher passes compliance check
# ═══════════════════════════════════════════════════════════════════

_test_single_dispatcher() {
    local dispatcher="$1"
    local help_fn="${_FLOW_HELP_FUNCTIONS[$dispatcher]}"

    ((TESTS_RUN++))
    echo -e "${BLUE}Testing: $dispatcher ($help_fn)${NC}"

    # Check if function exists
    if ! typeset -f "$help_fn" > /dev/null 2>&1; then
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$dispatcher: $help_fn() not found")
        echo -e "  ${RED}✗${NC} $help_fn() not defined"
        echo ""
        return
    fi

    # Run compliance check and capture output
    local check_output
    check_output="$(_flow_help_compliance_check "$dispatcher" false 2>&1)"
    local check_result=$?

    if [[ $check_result -eq 0 ]]; then
        ((TESTS_PASSED++))
        echo -e "  ${GREEN}✓${NC} $dispatcher passes all 9 rules"
    else
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$dispatcher")
        echo -e "  ${RED}✗${NC} $dispatcher failed compliance check:"
        echo "$check_output" | grep "FAIL" | while read -r line; do
            echo -e "    ${RED}$line${NC}"
        done
    fi
    echo ""
}

for dispatcher in "${_FLOW_HELP_DISPATCHERS[@]}"; do
    _test_single_dispatcher "$dispatcher"
done

# ═══════════════════════════════════════════════════════════════════
# Test: Compliance check_all function works
# ═══════════════════════════════════════════════════════════════════

_test_check_all() {
    ((TESTS_RUN++))
    echo -e "${BLUE}Testing: _flow_help_compliance_check_all()${NC}"
    local all_output
    all_output="$(_flow_help_compliance_check_all false 2>&1)"
    local all_result=$?
    if [[ $all_result -eq 0 ]]; then
        ((TESTS_PASSED++))
        echo -e "  ${GREEN}✓${NC} All dispatchers compliant via check_all"
    else
        ((TESTS_FAILED++))
        FAILED_TESTS+=("check_all: not all compliant")
        echo -e "  ${RED}✗${NC} check_all reports non-compliant dispatchers"
    fi
    echo ""
}
_test_check_all

# ═══════════════════════════════════════════════════════════════════
# Test: Rules function returns content
# ═══════════════════════════════════════════════════════════════════

_test_rules() {
    ((TESTS_RUN++))
    echo -e "${BLUE}Testing: _flow_help_compliance_rules()${NC}"
    local rules_output
    rules_output="$(_flow_help_compliance_rules 2>&1)"
    if [[ "$rules_output" == *"box_header"* ]] && [[ "$rules_output" == *"function_naming"* ]]; then
        ((TESTS_PASSED++))
        echo -e "  ${GREEN}✓${NC} Rules function returns all 9 rules"
    else
        ((TESTS_FAILED++))
        FAILED_TESTS+=("rules: incomplete output")
        echo -e "  ${RED}✗${NC} Rules function missing expected content"
    fi
    echo ""
}
_test_rules

# ═══════════════════════════════════════════════════════════════════
# RESULTS
# ═══════════════════════════════════════════════════════════════════

echo "══════════════════════════════════════════════════════════════"
echo "  Results: $TESTS_PASSED/$TESTS_RUN passed, $TESTS_FAILED failed"
echo "══════════════════════════════════════════════════════════════"

if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
    echo ""
    echo -e "${RED}Failed tests:${NC}"
    for t in "${FAILED_TESTS[@]}"; do
        echo -e "  ${RED}✗${NC} $t"
    done
fi

echo ""

[[ $TESTS_FAILED -eq 0 ]]
