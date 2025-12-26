#!/usr/bin/env zsh
# Test script for cc dispatcher
# Tests: help, subcommand detection, keyword recognition

# Don't exit on error - we want to run all tests
# set -e

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

    # Get project root - try multiple methods
    local project_root=""

    # Method 1: From script location
    if [[ -n "${0:A}" ]]; then
        project_root="${0:A:h:h}"
    fi

    # Method 2: Check if we're already in the project
    if [[ -z "$project_root" || ! -f "$project_root/commands/pick.zsh" ]]; then
        if [[ -f "$PWD/commands/pick.zsh" ]]; then
            project_root="$PWD"
        elif [[ -f "$PWD/../commands/pick.zsh" ]]; then
            project_root="$PWD/.."
        fi
    fi

    # Method 3: Hardcoded fallback
    if [[ -z "$project_root" || ! -f "$project_root/commands/pick.zsh" ]]; then
        project_root="/Users/dt/projects/dev-tools/flow-cli"
    fi

    echo "  Project root: $project_root"

    # Source pick first (cc depends on it)
    source "$project_root/commands/pick.zsh"

    # Source cc dispatcher
    source "$project_root/lib/dispatchers/cc-dispatcher.zsh"

    echo "  Loaded: pick.zsh"
    echo "  Loaded: cc-dispatcher.zsh"
    echo ""
}

# ============================================================================
# HELP TESTS
# ============================================================================

test_cc_help() {
    log_test "cc help shows usage"

    local output=$(cc help 2>&1)

    # Check for "CC" and "Claude Code" (may have ANSI codes between)
    if echo "$output" | grep -q "CC" && echo "$output" | grep -q "Claude Code"; then
        pass
    else
        fail "Help header not found"
    fi
}

test_cc_help_flag() {
    log_test "cc --help works"

    local output=$(cc --help 2>&1)

    if echo "$output" | grep -q "CC" && echo "$output" | grep -q "Claude Code"; then
        pass
    else
        fail "--help flag not working"
    fi
}

test_cc_help_short_flag() {
    log_test "cc -h works"

    local output=$(cc -h 2>&1)

    if echo "$output" | grep -q "CC" && echo "$output" | grep -q "Claude Code"; then
        pass
    else
        fail "-h flag not working"
    fi
}

# ============================================================================
# SUBCOMMAND DOCUMENTATION TESTS
# ============================================================================

test_help_shows_yolo() {
    log_test "help shows yolo mode"

    local output=$(cc help 2>&1)

    if echo "$output" | grep -q "yolo"; then
        pass
    else
        fail "yolo not in help"
    fi
}

test_help_shows_plan() {
    log_test "help shows plan mode"

    local output=$(cc help 2>&1)

    if echo "$output" | grep -q "plan"; then
        pass
    else
        fail "plan not in help"
    fi
}

test_help_shows_resume() {
    log_test "help shows resume"

    local output=$(cc help 2>&1)

    if echo "$output" | grep -q "resume"; then
        pass
    else
        fail "resume not in help"
    fi
}

test_help_shows_continue() {
    log_test "help shows continue"

    local output=$(cc help 2>&1)

    if echo "$output" | grep -q "continue"; then
        pass
    else
        fail "continue not in help"
    fi
}

test_help_shows_ask() {
    log_test "help shows ask"

    local output=$(cc help 2>&1)

    if echo "$output" | grep -q "ask"; then
        pass
    else
        fail "ask not in help"
    fi
}

test_help_shows_file() {
    log_test "help shows file"

    local output=$(cc help 2>&1)

    if echo "$output" | grep -q "file"; then
        pass
    else
        fail "file not in help"
    fi
}

test_help_shows_diff() {
    log_test "help shows diff"

    local output=$(cc help 2>&1)

    if echo "$output" | grep -q "diff"; then
        pass
    else
        fail "diff not in help"
    fi
}

test_help_shows_opus() {
    log_test "help shows opus"

    local output=$(cc help 2>&1)

    if echo "$output" | grep -q "opus"; then
        pass
    else
        fail "opus not in help"
    fi
}

test_help_shows_haiku() {
    log_test "help shows haiku"

    local output=$(cc help 2>&1)

    if echo "$output" | grep -q "haiku"; then
        pass
    else
        fail "haiku not in help"
    fi
}

test_help_shows_now() {
    log_test "help shows now"

    local output=$(cc help 2>&1)

    if echo "$output" | grep -q "now"; then
        pass
    else
        fail "now not in help"
    fi
}

test_help_shows_direct_jump() {
    log_test "help shows direct jump"

    local output=$(cc help 2>&1)

    if echo "$output" | grep -q "DIRECT JUMP"; then
        pass
    else
        fail "direct jump not in help"
    fi
}

# ============================================================================
# SHORTCUT DOCUMENTATION TESTS
# ============================================================================

test_help_shows_shortcuts() {
    log_test "help shows shortcuts section"

    local output=$(cc help 2>&1)

    if echo "$output" | grep -q "SHORTCUTS"; then
        pass
    else
        fail "shortcuts section not found"
    fi
}

test_shortcut_y_documented() {
    log_test "shortcut y = yolo documented"

    local output=$(cc help 2>&1)

    if echo "$output" | grep -q "y = yolo"; then
        pass
    else
        fail "y shortcut not documented"
    fi
}

test_shortcut_p_documented() {
    log_test "shortcut p = plan documented"

    local output=$(cc help 2>&1)

    if echo "$output" | grep -q "p = plan"; then
        pass
    else
        fail "p shortcut not documented"
    fi
}

test_shortcut_r_documented() {
    log_test "shortcut r = resume documented"

    local output=$(cc help 2>&1)

    if echo "$output" | grep -q "r = resume"; then
        pass
    else
        fail "r shortcut not documented"
    fi
}

# ============================================================================
# CC ASK VALIDATION TESTS
# ============================================================================

test_cc_ask_no_args() {
    log_test "cc ask with no args shows usage"

    local output=$(cc ask 2>&1)

    if echo "$output" | grep -q "Usage: cc ask"; then
        pass
    else
        fail "Usage message not shown"
    fi
}

# ============================================================================
# CC FILE VALIDATION TESTS
# ============================================================================

test_cc_file_no_args() {
    log_test "cc file with no args shows usage"

    local output=$(cc file 2>&1)

    if echo "$output" | grep -q "Usage: cc file"; then
        pass
    else
        fail "Usage message not shown"
    fi
}

test_cc_file_nonexistent() {
    log_test "cc file with nonexistent file shows error"

    local output=$(cc file /nonexistent/file.txt 2>&1)

    if echo "$output" | grep -q "not found"; then
        pass
    else
        fail "Error message not shown for missing file"
    fi
}

# ============================================================================
# CC DIFF VALIDATION TESTS
# ============================================================================

test_cc_diff_not_in_repo() {
    log_test "cc diff outside git repo shows error"

    # Run in /tmp which is not a git repo
    local output=$(cd /tmp && cc diff 2>&1)

    if echo "$output" | grep -q "Not in a git repository"; then
        pass
    else
        fail "Error not shown for non-repo directory"
    fi
}

# ============================================================================
# CC RPKG VALIDATION TESTS
# ============================================================================

test_cc_rpkg_not_in_package() {
    log_test "cc rpkg outside R package shows error"

    # Run in /tmp which has no DESCRIPTION file
    local output=$(cd /tmp && cc rpkg 2>&1)

    if echo "$output" | grep -q "Not in an R package"; then
        pass
    else
        fail "Error not shown for non-package directory"
    fi
}

# ============================================================================
# FUNCTION EXISTENCE TESTS
# ============================================================================

test_cc_function_exists() {
    log_test "cc function is defined"

    if (( $+functions[cc] )); then
        pass
    else
        fail "cc function not defined"
    fi
}

test_cc_help_function_exists() {
    log_test "_cc_help function is defined"

    if (( $+functions[_cc_help] )); then
        pass
    else
        fail "_cc_help function not defined"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  CC Dispatcher Tests                                       ║"
    echo "╚════════════════════════════════════════════════════════════╝"

    setup

    echo "${YELLOW}Help Tests${NC}"
    echo "────────────────────────────────────────"
    test_cc_help
    test_cc_help_flag
    test_cc_help_short_flag
    echo ""

    echo "${YELLOW}Subcommand Documentation Tests${NC}"
    echo "────────────────────────────────────────"
    test_help_shows_yolo
    test_help_shows_plan
    test_help_shows_resume
    test_help_shows_continue
    test_help_shows_ask
    test_help_shows_file
    test_help_shows_diff
    test_help_shows_opus
    test_help_shows_haiku
    test_help_shows_now
    test_help_shows_direct_jump
    echo ""

    echo "${YELLOW}Shortcut Documentation Tests${NC}"
    echo "────────────────────────────────────────"
    test_help_shows_shortcuts
    test_shortcut_y_documented
    test_shortcut_p_documented
    test_shortcut_r_documented
    echo ""

    echo "${YELLOW}Validation Tests${NC}"
    echo "────────────────────────────────────────"
    test_cc_ask_no_args
    test_cc_file_no_args
    test_cc_file_nonexistent
    test_cc_diff_not_in_repo
    test_cc_rpkg_not_in_package
    echo ""

    echo "${YELLOW}Function Existence Tests${NC}"
    echo "────────────────────────────────────────"
    test_cc_function_exists
    test_cc_help_function_exists
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
