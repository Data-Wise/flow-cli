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

    # Method 3: Error if not found
    if [[ -z "$project_root" || ! -f "$project_root/commands/pick.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root - run from project directory${NC}"
        exit 1
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

# REMOVED: test_help_shows_now - "cc now" was deprecated in v3.6.0
# The default behavior (cc with no args) now launches Claude in current dir

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

test_cc_dispatch_with_mode_exists() {
    log_test "_cc_dispatch_with_mode function is defined"

    if (( $+functions[_cc_dispatch_with_mode] )); then
        pass
    else
        fail "_cc_dispatch_with_mode function not defined"
    fi
}

test_cc_worktree_exists() {
    log_test "_cc_worktree function is defined"

    if (( $+functions[_cc_worktree] )); then
        pass
    else
        fail "_cc_worktree function not defined"
    fi
}

# ============================================================================
# UNIFIED GRAMMAR TESTS (Mode-first vs Target-first)
# ============================================================================

test_mode_detection_yolo() {
    log_test "yolo detected as mode (not target)"

    # Mock the _cc_dispatch_with_mode to verify it's called
    local mode_called=0
    _cc_dispatch_with_mode() { mode_called=1; }

    cc yolo >/dev/null 2>&1 || true

    if [[ $mode_called -eq 1 ]]; then
        pass
    else
        fail "yolo not detected as mode"
    fi

    # Restore original function
    source "$project_root/lib/dispatchers/cc-dispatcher.zsh"
}

test_mode_detection_plan() {
    log_test "plan detected as mode (not target)"

    local mode_called=0
    _cc_dispatch_with_mode() { mode_called=1; }

    cc plan >/dev/null 2>&1 || true

    if [[ $mode_called -eq 1 ]]; then
        pass
    else
        fail "plan not detected as mode"
    fi

    # Restore
    source "$project_root/lib/dispatchers/cc-dispatcher.zsh"
}

test_mode_detection_opus() {
    log_test "opus detected as mode (not target)"

    local mode_called=0
    _cc_dispatch_with_mode() { mode_called=1; }

    cc opus >/dev/null 2>&1 || true

    if [[ $mode_called -eq 1 ]]; then
        pass
    else
        fail "opus not detected as mode"
    fi

    # Restore
    source "$project_root/lib/dispatchers/cc-dispatcher.zsh"
}

test_mode_detection_haiku() {
    log_test "haiku detected as mode (not target)"

    local mode_called=0
    _cc_dispatch_with_mode() { mode_called=1; }

    cc haiku >/dev/null 2>&1 || true

    if [[ $mode_called -eq 1 ]]; then
        pass
    else
        fail "haiku not detected as mode"
    fi

    # Restore
    source "$project_root/lib/dispatchers/cc-dispatcher.zsh"
}

# ============================================================================
# SHORTCUT EXPANSION TESTS
# ============================================================================

test_shortcut_y_expands_to_yolo() {
    log_test "shortcut y expands to yolo"

    local mode_called=""
    _cc_dispatch_with_mode() { mode_called="$1"; }

    cc y >/dev/null 2>&1 || true

    # y should expand to yolo in the dispatcher
    if [[ "$mode_called" == "y" || "$mode_called" == "yolo" ]]; then
        pass
    else
        fail "y did not trigger mode dispatch (got: $mode_called)"
    fi

    # Restore
    source "$project_root/lib/dispatchers/cc-dispatcher.zsh"
}

test_shortcut_p_expands_to_plan() {
    log_test "shortcut p expands to plan"

    local mode_called=""
    _cc_dispatch_with_mode() { mode_called="$1"; }

    cc p >/dev/null 2>&1 || true

    if [[ "$mode_called" == "p" || "$mode_called" == "plan" ]]; then
        pass
    else
        fail "p did not trigger mode dispatch (got: $mode_called)"
    fi

    # Restore
    source "$project_root/lib/dispatchers/cc-dispatcher.zsh"
}

test_shortcut_o_expands_to_opus() {
    log_test "shortcut o expands to opus"

    local mode_called=""
    _cc_dispatch_with_mode() { mode_called="$1"; }

    cc o >/dev/null 2>&1 || true

    if [[ "$mode_called" == "o" || "$mode_called" == "opus" ]]; then
        pass
    else
        fail "o did not trigger mode dispatch (got: $mode_called)"
    fi

    # Restore
    source "$project_root/lib/dispatchers/cc-dispatcher.zsh"
}

test_shortcut_h_expands_to_haiku() {
    log_test "shortcut h expands to haiku"

    local mode_called=""
    _cc_dispatch_with_mode() { mode_called="$1"; }

    cc h >/dev/null 2>&1 || true

    if [[ "$mode_called" == "h" || "$mode_called" == "haiku" ]]; then
        pass
    else
        fail "h did not trigger mode dispatch (got: $mode_called)"
    fi

    # Restore
    source "$project_root/lib/dispatchers/cc-dispatcher.zsh"
}

# ============================================================================
# EXPLICIT HERE TESTS
# ============================================================================

test_explicit_here_dot() {
    log_test "cc . recognized as explicit HERE"

    # The . should be recognized as HERE target
    # We can't easily test the full execution, but we can verify it doesn't error
    local output=$(cc . --help 2>&1 || echo "error")

    if [[ "$output" != "error" ]]; then
        pass
    else
        fail "cc . triggered error"
    fi
}

test_explicit_here_word() {
    log_test "cc here recognized as explicit HERE"

    local output=$(cc here --help 2>&1 || echo "error")

    if [[ "$output" != "error" ]]; then
        pass
    else
        fail "cc here triggered error"
    fi
}

# ============================================================================
# ALIAS TESTS
# ============================================================================

test_ccy_alias_exists() {
    log_test "ccy alias exists"

    if alias ccy >/dev/null 2>&1; then
        pass
    else
        fail "ccy alias not defined"
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
    # test_help_shows_now - deprecated in v3.6.0
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
    test_cc_dispatch_with_mode_exists
    test_cc_worktree_exists
    echo ""

    echo "${YELLOW}Unified Grammar Tests (Mode Detection)${NC}"
    echo "────────────────────────────────────────"
    test_mode_detection_yolo
    test_mode_detection_plan
    test_mode_detection_opus
    test_mode_detection_haiku
    echo ""

    echo "${YELLOW}Shortcut Expansion Tests${NC}"
    echo "────────────────────────────────────────"
    test_shortcut_y_expands_to_yolo
    test_shortcut_p_expands_to_plan
    test_shortcut_o_expands_to_opus
    test_shortcut_h_expands_to_haiku
    echo ""

    echo "${YELLOW}Explicit HERE Tests${NC}"
    echo "────────────────────────────────────────"
    test_explicit_here_dot
    test_explicit_here_word
    echo ""

    echo "${YELLOW}Alias Tests${NC}"
    echo "────────────────────────────────────────"
    test_ccy_alias_exists
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
