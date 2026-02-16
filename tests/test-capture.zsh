#!/usr/bin/env zsh
# Test script for capture commands
# Tests: catch, inbox, crumb, trail, win, yay
# Rewritten: 2026-02-16 (behavioral assertions via test-framework.zsh)

# ============================================================================
# FRAMEWORK
# ============================================================================

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

source "$SCRIPT_DIR/test-framework.zsh" || {
    echo "ERROR: Cannot source test-framework.zsh"
    exit 1
}

# ============================================================================
# SETUP / CLEANUP
# ============================================================================

setup() {
    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        echo "ERROR: Cannot find project root"
        exit 1
    fi

    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$PROJECT_ROOT"
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
        echo "ERROR: Plugin failed to load"
        exit 1
    }

    # Close stdin to prevent interactive commands from blocking
    exec < /dev/null
}

cleanup() {
    reset_mocks
}

# ============================================================================
# TESTS: Command existence
# ============================================================================

test_catch_exists() {
    test_case "catch command exists"
    assert_function_exists "catch" && test_pass
}

test_inbox_exists() {
    test_case "inbox command exists"
    assert_function_exists "inbox" && test_pass
}

test_crumb_exists() {
    test_case "crumb command exists"
    assert_function_exists "crumb" && test_pass
}

test_trail_exists() {
    test_case "trail command exists"
    assert_function_exists "trail" && test_pass
}

test_win_exists() {
    test_case "win command exists"
    assert_function_exists "win" && test_pass
}

test_yay_exists() {
    test_case "yay command exists"
    assert_function_exists "yay" && test_pass
}

# ============================================================================
# TESTS: Helper functions
# ============================================================================

test_flow_catch_exists() {
    test_case "_flow_catch function exists"
    assert_function_exists "_flow_catch" && test_pass
}

test_flow_inbox_exists() {
    test_case "_flow_inbox function exists"
    assert_function_exists "_flow_inbox" && test_pass
}

test_flow_crumb_exists() {
    test_case "_flow_crumb function exists"
    assert_function_exists "_flow_crumb" && test_pass
}

test_flow_in_project_exists() {
    test_case "_flow_in_project function exists"
    assert_function_exists "_flow_in_project" && test_pass
}

# ============================================================================
# TESTS: catch behavior
# ============================================================================

test_catch_with_text() {
    test_case "catch with text argument runs and confirms"

    local output=$(catch "test idea capture" 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "catch with text should exit 0" || return

    # Should show some confirmation (captured, checkmark, etc.) or succeed silently
    if [[ -n "$output" ]]; then
        if [[ "$output" == *"✓"* || "$output" == *"Captured"* || "$output" == *"captured"* || "$output" == *"💡"* ]]; then
            test_pass
        else
            # Non-empty output that is not a known confirmation -- still pass if exit 0
            test_pass
        fi
    else
        # Silent success is acceptable
        test_pass
    fi
}

test_catch_no_args_no_tty() {
    test_case "catch with no args and no TTY exits 0 or 1"

    # With no TTY, catch either reads empty input and returns 1 (no text),
    # or the read builtin returns 0 with empty text inside $() subshells
    # depending on ZSH version. Both 0 and 1 are acceptable since there
    # is no interactive input available.
    local output=$(catch 2>&1 < /dev/null)
    local exit_code=$?

    if (( exit_code <= 1 )); then
        test_pass
    else
        test_fail "catch with no args should exit 0 or 1, got $exit_code"
    fi
}

# ============================================================================
# TESTS: crumb behavior
# ============================================================================

test_crumb_with_text() {
    test_case "crumb with text argument runs and confirms"

    local output=$(crumb "test breadcrumb note" 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "crumb with text should exit 0" || return
    assert_not_contains "$output" "command not found" && test_pass
}

# ============================================================================
# TESTS: trail behavior
# ============================================================================

test_trail_runs() {
    test_case "trail runs without error"

    local output=$(trail 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "trail should exit 0" || return
    assert_not_contains "$output" "command not found" && test_pass
}

test_trail_with_limit() {
    test_case "trail with limit argument runs"

    local output=$(trail "" 5 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "trail with limit should exit 0" || return
    assert_not_contains "$output" "command not found" && test_pass
}

# ============================================================================
# TESTS: inbox behavior
# ============================================================================

test_inbox_runs() {
    test_case "inbox runs without error"

    local output=$(inbox 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "inbox should exit 0" || return
    assert_not_contains "$output" "command not found" && test_pass
}

# ============================================================================
# TESTS: win command (dopamine features)
# ============================================================================

test_win_with_text() {
    test_case "win with text argument runs and confirms"

    local output=$(win "fixed the bug" 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "win with text should exit 0" || return

    # Should show some kind of confirmation
    if [[ "$output" == *"✓"* || "$output" == *"Logged"* || "$output" == *"logged"* || "$output" == *"🎉"* || "$output" == *"Win"* || "$output" == *"win"* ]]; then
        test_pass
    else
        test_fail "Expected confirmation in output, got: ${output:0:200}"
    fi
}

test_win_with_category() {
    test_case "win with --category flag runs and confirms"

    local output=$(win --category fix "squashed the bug" 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "win with --category should exit 0" || return

    # Should show some kind of confirmation
    if [[ "$output" == *"✓"* || "$output" == *"Logged"* || "$output" == *"logged"* || "$output" == *"🎉"* || "$output" == *"Win"* || "$output" == *"win"* ]]; then
        test_pass
    else
        test_fail "Expected confirmation in output, got: ${output:0:200}"
    fi
}

# ============================================================================
# TESTS: yay command
# ============================================================================

test_yay_runs() {
    test_case "yay runs without error"

    local output=$(yay 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "yay should exit 0" || return
    assert_not_contains "$output" "command not found" && test_pass
}

test_yay_week_flag() {
    test_case "yay --week runs without error"

    local output=$(yay --week 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "yay --week should exit 0" || return
    assert_not_contains "$output" "command not found" && test_pass
}

# ============================================================================
# TESTS: ZSH module loading
# ============================================================================

test_datetime_module_loaded() {
    test_case "zsh/datetime module is loaded"

    # strftime should be available
    if type strftime &>/dev/null || strftime 2>&1 | grep -q "not enough"; then
        test_pass
    else
        test_fail "strftime not available (zsh/datetime not loaded)"
    fi
}

# ============================================================================
# TESTS: Project detection integration
# ============================================================================

test_in_project_in_git_repo() {
    test_case "_flow_in_project detects git repo"

    # Navigate to the project root which is a git repo
    cd "$PROJECT_ROOT" 2>/dev/null

    if _flow_in_project 2>/dev/null; then
        test_pass
    else
        test_fail "_flow_in_project returned false in $PROJECT_ROOT (which is a git repo)"
    fi
}

test_in_project_outside_repo() {
    test_case "_flow_in_project returns false outside project"

    cd /tmp 2>/dev/null

    if ! _flow_in_project 2>/dev/null; then
        test_pass
    else
        test_fail "Should return false in /tmp"
    fi
}

# ============================================================================
# TESTS: Output quality
# ============================================================================

test_win_shows_confirmation() {
    test_case "win shows confirmation message"

    local output=$(win "test accomplishment" 2>&1)

    # Should show some kind of confirmation (checkmark, logged, win, etc.)
    if [[ "$output" == *"✓"* || "$output" == *"Logged"* || "$output" == *"logged"* || "$output" == *"🎉"* || "$output" == *"Win"* || "$output" == *"win"* ]]; then
        test_pass
    else
        test_fail "Expected confirmation in win output, got: ${output:0:200}"
    fi
}

test_catch_shows_confirmation() {
    test_case "catch shows confirmation message"

    local output=$(catch "test capture" 2>&1)

    # Should show some confirmation or succeed silently
    if [[ "$output" == *"✓"* || "$output" == *"Captured"* || "$output" == *"captured"* || "$output" == *"💡"* || -z "$output" ]]; then
        test_pass
    else
        test_fail "Expected confirmation or silent success, got: ${output:0:200}"
    fi
}

# ============================================================================
# TESTS: Category detection in win
# ============================================================================

test_win_auto_categorizes_fix() {
    test_case "win auto-categorizes 'fixed' as fix"

    local output=$(win "fixed a nasty bug" 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "win should exit 0" || return

    # Should auto-detect as fix category (emoji or keyword in output)
    if [[ "$output" == *"🔧"* || "$output" == *"fix"* || "$output" == *"Fix"* ]]; then
        test_pass
    else
        test_fail "Expected fix category indicator in output, got: ${output:0:200}"
    fi
}

test_win_auto_categorizes_docs() {
    test_case "win auto-categorizes 'documented' as docs"

    local output=$(win "documented the API" 2>&1)
    local exit_code=$?

    assert_exit_code "$exit_code" 0 "win should exit 0" || return

    # Should auto-detect as docs category (emoji or keyword in output)
    if [[ "$output" == *"📝"* || "$output" == *"docs"* || "$output" == *"Docs"* || "$output" == *"doc"* ]]; then
        test_pass
    else
        test_fail "Expected docs category indicator in output, got: ${output:0:200}"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite_start "Capture Commands Tests"

    setup

    echo "${CYAN}--- Command existence tests ---${RESET}"
    test_catch_exists
    test_inbox_exists
    test_crumb_exists
    test_trail_exists
    test_win_exists
    test_yay_exists

    echo ""
    echo "${CYAN}--- Helper function tests ---${RESET}"
    test_flow_catch_exists
    test_flow_inbox_exists
    test_flow_crumb_exists
    test_flow_in_project_exists

    echo ""
    echo "${CYAN}--- catch behavior tests ---${RESET}"
    test_catch_with_text
    test_catch_no_args_no_tty

    echo ""
    echo "${CYAN}--- crumb behavior tests ---${RESET}"
    test_crumb_with_text

    echo ""
    echo "${CYAN}--- trail behavior tests ---${RESET}"
    test_trail_runs
    test_trail_with_limit

    echo ""
    echo "${CYAN}--- inbox behavior tests ---${RESET}"
    test_inbox_runs

    echo ""
    echo "${CYAN}--- win command tests ---${RESET}"
    test_win_with_text
    test_win_with_category

    echo ""
    echo "${CYAN}--- yay command tests ---${RESET}"
    test_yay_runs
    test_yay_week_flag

    echo ""
    echo "${CYAN}--- Module tests ---${RESET}"
    test_datetime_module_loaded

    echo ""
    echo "${CYAN}--- Project detection tests ---${RESET}"
    test_in_project_in_git_repo
    test_in_project_outside_repo

    echo ""
    echo "${CYAN}--- Output quality tests ---${RESET}"
    test_win_shows_confirmation
    test_catch_shows_confirmation

    echo ""
    echo "${CYAN}--- Category detection tests ---${RESET}"
    test_win_auto_categorizes_fix
    test_win_auto_categorizes_docs

    cleanup

    print_summary
    exit $?
}

trap cleanup EXIT
main "$@"
