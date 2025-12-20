#!/usr/bin/env zsh

# ============================================================================
# Anti-Pattern Tests
# ============================================================================
# Purpose: Detect common ZSH anti-patterns in configuration files
# Created: 2025-12-19
# Location: ~/.config/zsh/tests/test-anti-patterns.zsh
#
# Tests:
#   1. Interactive function command substitution ($(pick))
#   2. Alias/function name conflicts
#   3. Stdout pollution in programmatic functions
#   4. Missing stderr redirection
#
# Usage:
#   ./test-anti-patterns.zsh
#   ./run-all-tests.zsh
# ============================================================================

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# ============================================================================
# Test Infrastructure
# ============================================================================

print_test_header() {
    echo ""
    echo "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo "${BLUE}║  Anti-Pattern Tests                                        ║${NC}"
    echo "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

pass() {
    local test_name="$1"
    ((PASSED_TESTS++))
    ((TOTAL_TESTS++))
    echo "${GREEN}✓${NC} ${test_name}"
}

fail() {
    local test_name="$1"
    local message="$2"
    ((FAILED_TESTS++))
    ((TOTAL_TESTS++))
    echo "${RED}✗${NC} ${test_name}"
    if [[ -n "$message" ]]; then
        echo "  ${RED}→${NC} $message"
    fi
}

warn() {
    local test_name="$1"
    local message="$2"
    echo "${YELLOW}⚠${NC} ${test_name}"
    if [[ -n "$message" ]]; then
        echo "  ${YELLOW}→${NC} $message"
    fi
}

print_summary() {
    echo ""
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo "  Total Tests: $TOTAL_TESTS"
    echo "  ${GREEN}Passed: $PASSED_TESTS${NC}"
    if [[ $FAILED_TESTS -gt 0 ]]; then
        echo "  ${RED}Failed: $FAILED_TESTS${NC}"
    else
        echo "  ${GREEN}Failed: 0${NC}"
    fi
    echo "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo ""

    if [[ $FAILED_TESTS -gt 0 ]]; then
        return 1
    else
        return 0
    fi
}

# ============================================================================
# Anti-Pattern 1: Interactive Function Command Substitution
# ============================================================================

test_no_pick_command_substitution() {
    local test_name="No \$(pick) command substitution"
    local pattern='local.*=\$\(pick'

    # Search in all function files
    local results=$(grep -r "$pattern" ~/.config/zsh/functions/ 2>/dev/null)

    if [[ -n "$results" ]]; then
        fail "$test_name" "Found $(pick) command substitution:"
        echo "$results" | while IFS= read -r line; do
            echo "    ${RED}→${NC} $line"
        done
    else
        pass "$test_name"
    fi
}

test_no_pickr_command_substitution() {
    local test_name="No \$(pickr) command substitution"
    local pattern='local.*=\$\(pickr'

    local results=$(grep -r "$pattern" ~/.config/zsh/functions/ 2>/dev/null)

    if [[ -n "$results" ]]; then
        fail "$test_name" "Found $(pickr) command substitution"
    else
        pass "$test_name"
    fi
}

test_no_pickdev_command_substitution() {
    local test_name="No \$(pickdev) command substitution"
    local pattern='local.*=\$\(pickdev'

    local results=$(grep -r "$pattern" ~/.config/zsh/functions/ 2>/dev/null)

    if [[ -n "$results" ]]; then
        fail "$test_name" "Found $(pickdev) command substitution"
    else
        pass "$test_name"
    fi
}

test_no_bare_fzf_substitution() {
    local test_name="Warn on bare \$(fzf) without stderr redirect"
    local pattern='local.*=\$\(fzf[^<]'

    # This is a warning, not a failure - fzf can be used programmatically
    local results=$(grep -r "$pattern" ~/.config/zsh/functions/ 2>/dev/null | grep -v ">&2")

    if [[ -n "$results" ]]; then
        warn "$test_name" "Found bare fzf usage (may need stderr redirect)"
        echo "$results" | head -5 | while IFS= read -r line; do
            echo "    ${YELLOW}→${NC} $line"
        done
    else
        pass "$test_name"
    fi
}

# ============================================================================
# Anti-Pattern 2: Alias/Function Name Conflicts
# ============================================================================

test_no_alias_function_conflicts() {
    local test_name="No alias/function name conflicts"

    # Get all aliases
    local alias_file=$(mktemp)
    grep -r "^alias [a-zA-Z_]" ~/.config/zsh/ 2>/dev/null | \
        sed -E "s/.*alias ([a-zA-Z_][a-zA-Z0-9_]*)=.*/\1/" | \
        sort -u > "$alias_file"

    # Get all functions
    local function_file=$(mktemp)
    grep -r "^[a-zA-Z_][a-zA-Z0-9_]*() {" ~/.config/zsh/functions/ 2>/dev/null | \
        sed -E "s/.*:([a-zA-Z_][a-zA-Z0-9_]*)\(\).*/\1/" | \
        sort -u > "$function_file"

    # Find conflicts
    local conflicts=$(comm -12 "$alias_file" "$function_file")

    rm -f "$alias_file" "$function_file"

    if [[ -n "$conflicts" ]]; then
        fail "$test_name" "Found alias/function conflicts:"
        echo "$conflicts" | while IFS= read -r name; do
            echo "    ${RED}→${NC} $name (both alias and function)"
        done
    else
        pass "$test_name"
    fi
}

# ============================================================================
# Anti-Pattern 3: Stdout Pollution
# ============================================================================

test_programmatic_functions_clean_output() {
    local test_name="Programmatic functions have clean output"

    # Functions that return values should only output data, not messages
    # Check for common message patterns in functions that get captured
    local suspicious_patterns=(
        "echo.*Processing"
        "echo.*Loading"
        "echo.*╔"
        "echo.*║"
        "echo.*✓"
        "echo.*❌"
    )

    local found_issues=0

    # Check functions that are commonly captured with $()
    local programmatic_functions=(
        "_proj_find"
        "_proj_name_from_path"
        "_proj_detect_type"
    )

    for func in "${programmatic_functions[@]}"; do
        for pattern in "${suspicious_patterns[@]}"; do
            local matches=$(grep -A 20 "^${func}()" ~/.config/zsh/functions/*.zsh 2>/dev/null | \
                           grep -E "$pattern" | \
                           grep -v ">&2")

            if [[ -n "$matches" ]]; then
                ((found_issues++))
                if [[ $found_issues -eq 1 ]]; then
                    fail "$test_name" "Found stdout pollution in programmatic functions:"
                fi
                echo "    ${RED}→${NC} $func: $(echo "$matches" | head -1)"
            fi
        done
    done

    if [[ $found_issues -eq 0 ]]; then
        pass "$test_name"
    fi
}

# ============================================================================
# Anti-Pattern 4: Interactive Functions Used Programmatically
# ============================================================================

test_interactive_functions_not_captured() {
    local test_name="Interactive functions not captured with \$()"

    # List of known interactive functions
    local interactive_functions=(
        "pick"
        "pickr"
        "pickdev"
        "pickq"
        "dash"
        "tst"
        "rst"
    )

    local found_issues=0

    for func in "${interactive_functions[@]}"; do
        # Look for $(<function>) pattern
        local matches=$(grep -r "\$($func)" ~/.config/zsh/functions/ 2>/dev/null | \
                       grep -v "^#" | \
                       grep -v "grep")

        if [[ -n "$matches" ]]; then
            ((found_issues++))
            if [[ $found_issues -eq 1 ]]; then
                fail "$test_name" "Found interactive functions being captured:"
            fi
            echo "    ${RED}→${NC} $matches"
        fi
    done

    if [[ $found_issues -eq 0 ]]; then
        pass "$test_name"
    fi
}

# ============================================================================
# Code Quality Checks
# ============================================================================

test_functions_use_local_variables() {
    local test_name="Functions use local variables"

    # This is a warning - check for variable assignments without 'local'
    # in function bodies
    local suspicious=$(grep -r "^[a-zA-Z_]" ~/.config/zsh/functions/*.zsh 2>/dev/null | \
                      grep "() {" -A 50 | \
                      grep -E "^[[:space:]]+[a-zA-Z_][a-zA-Z0-9_]*=" | \
                      grep -v "local " | \
                      grep -v "export " | \
                      grep -v "readonly " | \
                      head -10)

    if [[ -n "$suspicious" ]]; then
        warn "$test_name" "Found variable assignments without 'local'"
        echo "$suspicious" | head -5 | while IFS= read -r line; do
            echo "    ${YELLOW}→${NC} $line"
        done
    else
        pass "$test_name"
    fi
}

test_no_unquoted_variables() {
    local test_name="Warn on potentially unquoted variables"

    # Check for common unquoted variable patterns in critical locations
    local suspicious=$(grep -r 'cd \$[a-zA-Z_]' ~/.config/zsh/functions/*.zsh 2>/dev/null | \
                      grep -v 'cd "\$' | \
                      head -10)

    if [[ -n "$suspicious" ]]; then
        warn "$test_name" "Found potentially unquoted variables in cd commands"
        echo "$suspicious" | head -3 | while IFS= read -r line; do
            echo "    ${YELLOW}→${NC} $line"
        done
    else
        pass "$test_name"
    fi
}

# ============================================================================
# Main Test Runner
# ============================================================================

main() {
    print_test_header

    echo "${BLUE}Testing Interactive Function Patterns...${NC}"
    test_no_pick_command_substitution
    test_no_pickr_command_substitution
    test_no_pickdev_command_substitution
    test_no_bare_fzf_substitution
    test_interactive_functions_not_captured

    echo ""
    echo "${BLUE}Testing Alias/Function Conflicts...${NC}"
    test_no_alias_function_conflicts

    echo ""
    echo "${BLUE}Testing Output Hygiene...${NC}"
    test_programmatic_functions_clean_output

    echo ""
    echo "${BLUE}Testing Code Quality...${NC}"
    test_functions_use_local_variables
    test_no_unquoted_variables

    print_summary
}

# Run tests
main "$@"
