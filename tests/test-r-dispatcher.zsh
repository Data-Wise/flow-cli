#!/usr/bin/env zsh
# Test script for r dispatcher
# Tests: help, subcommand detection, keyword recognition, cleanup commands

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

    if [[ -n "${0:A}" ]]; then
        project_root="${0:A:h:h}"
    fi

    if [[ -z "$project_root" || ! -f "$project_root/lib/dispatchers/r-dispatcher.zsh" ]]; then
        if [[ -f "$PWD/lib/dispatchers/r-dispatcher.zsh" ]]; then
            project_root="$PWD"
        elif [[ -f "$PWD/../lib/dispatchers/r-dispatcher.zsh" ]]; then
            project_root="$PWD/.."
        fi
    fi

    if [[ -z "$project_root" || ! -f "$project_root/lib/dispatchers/r-dispatcher.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root - run from project directory${NC}"
        exit 1
    fi

    echo "  Project root: $project_root"

    # Source r dispatcher
    source "$project_root/lib/dispatchers/r-dispatcher.zsh"

    echo "  Loaded: r-dispatcher.zsh"
    echo ""
}

# ============================================================================
# FUNCTION EXISTENCE TESTS
# ============================================================================

test_r_function_exists() {
    log_test "r function is defined"

    if (( $+functions[r] )); then
        pass
    else
        fail "r function not defined"
    fi
}

test_r_help_function_exists() {
    log_test "_r_help function is defined"

    if (( $+functions[_r_help] )); then
        pass
    else
        fail "_r_help function not defined"
    fi
}

# ============================================================================
# HELP TESTS
# ============================================================================

test_r_help() {
    log_test "r help shows usage"

    local output=$(r help 2>&1)

    if echo "$output" | grep -q "R Package Development"; then
        pass
    else
        fail "Help header not found"
    fi
}

test_r_help_flag() {
    log_test "r h works (shortcut)"

    local output=$(r h 2>&1)

    if echo "$output" | grep -q "R Package Development"; then
        pass
    else
        fail "h shortcut not working"
    fi
}

# ============================================================================
# HELP CONTENT TESTS
# ============================================================================

test_help_shows_test() {
    log_test "help shows test command"

    local output=$(r help 2>&1)

    if echo "$output" | grep -q "r test"; then
        pass
    else
        fail "test not in help"
    fi
}

test_help_shows_cycle() {
    log_test "help shows cycle command"

    local output=$(r help 2>&1)

    if echo "$output" | grep -q "r cycle"; then
        pass
    else
        fail "cycle not in help"
    fi
}

test_help_shows_doc() {
    log_test "help shows doc command"

    local output=$(r help 2>&1)

    if echo "$output" | grep -q "r doc"; then
        pass
    else
        fail "doc not in help"
    fi
}

test_help_shows_check() {
    log_test "help shows check command"

    local output=$(r help 2>&1)

    if echo "$output" | grep -q "r check"; then
        pass
    else
        fail "check not in help"
    fi
}

test_help_shows_build() {
    log_test "help shows build command"

    local output=$(r help 2>&1)

    if echo "$output" | grep -q "r build"; then
        pass
    else
        fail "build not in help"
    fi
}

test_help_shows_cran() {
    log_test "help shows cran command"

    local output=$(r help 2>&1)

    if echo "$output" | grep -q "r cran"; then
        pass
    else
        fail "cran not in help"
    fi
}

test_help_shows_shortcuts() {
    log_test "help shows version bumps section"

    local output=$(r help 2>&1)

    if echo "$output" | grep -q "VERSION BUMPS"; then
        pass
    else
        fail "version bumps section not found"
    fi
}

test_help_shows_cleanup() {
    log_test "help shows cleanup section"

    local output=$(r help 2>&1)

    if echo "$output" | grep -q "CLEANUP"; then
        pass
    else
        fail "cleanup section not found"
    fi
}

# ============================================================================
# UNKNOWN COMMAND TESTS
# ============================================================================

test_unknown_command() {
    log_test "r unknown-cmd shows error"

    local output=$(r unknown-xyz-command 2>&1)

    if echo "$output" | grep -q "Unknown action"; then
        pass
    else
        fail "Unknown action error not shown"
    fi
}

test_unknown_command_suggests_help() {
    log_test "unknown command suggests r help"

    local output=$(r foobar 2>&1)

    if echo "$output" | grep -q "r help"; then
        pass
    else
        fail "Doesn't suggest r help"
    fi
}

# ============================================================================
# CLEANUP COMMAND TESTS (safe to run)
# ============================================================================

test_clean_command() {
    log_test "r clean removes files (in temp dir)"

    # Create temp dir with test files
    local temp_dir=$(mktemp -d)
    touch "$temp_dir/.Rhistory"
    touch "$temp_dir/.RData"

    # Run clean in that directory
    local output=$(cd "$temp_dir" && r clean 2>&1)

    if echo "$output" | grep -q "Removed .Rhistory"; then
        pass
    else
        fail "clean command message not shown"
    fi

    # Cleanup
    rm -rf "$temp_dir"
}

test_tex_command() {
    log_test "r tex removes LaTeX files (in temp dir)"

    # Create temp dir with test files
    local temp_dir=$(mktemp -d)
    touch "$temp_dir/test.aux"
    touch "$temp_dir/test.log"

    # Run tex in that directory
    local output=$(cd "$temp_dir" && r tex 2>&1)

    if echo "$output" | grep -q "Removed LaTeX"; then
        pass
    else
        fail "tex command message not shown"
    fi

    # Cleanup
    rm -rf "$temp_dir"
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  R Dispatcher Tests                                        ║"
    echo "╚════════════════════════════════════════════════════════════╝"

    setup

    echo "${YELLOW}Function Existence Tests${NC}"
    echo "────────────────────────────────────────"
    test_r_function_exists
    test_r_help_function_exists
    echo ""

    echo "${YELLOW}Help Tests${NC}"
    echo "────────────────────────────────────────"
    test_r_help
    test_r_help_flag
    echo ""

    echo "${YELLOW}Help Content Tests${NC}"
    echo "────────────────────────────────────────"
    test_help_shows_test
    test_help_shows_cycle
    test_help_shows_doc
    test_help_shows_check
    test_help_shows_build
    test_help_shows_cran
    test_help_shows_shortcuts
    test_help_shows_cleanup
    echo ""

    echo "${YELLOW}Unknown Command Tests${NC}"
    echo "────────────────────────────────────────"
    test_unknown_command
    test_unknown_command_suggests_help
    echo ""

    echo "${YELLOW}Cleanup Command Tests${NC}"
    echo "────────────────────────────────────────"
    test_clean_command
    test_tex_command
    echo ""

    echo "════════════════════════════════════════"
    echo "${CYAN}Summary${NC}"
    echo "────────────────────────────────────────"
    echo "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo "  Failed: ${RED}$TESTS_FAILED${NC}"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "${GREEN}✓ All tests passed!${NC}"
        exit 0
    else
        echo "${RED}✗ Some tests failed${NC}"
        exit 1
    fi
}

main "$@"
