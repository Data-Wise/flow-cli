#!/usr/bin/env zsh
# Test script for r dispatcher
# Tests: help, subcommand detection, keyword recognition, cleanup commands

# ============================================================================
# FRAMEWORK SETUP
# ============================================================================

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

source "$SCRIPT_DIR/test-framework.zsh"

# ============================================================================
# SETUP / CLEANUP
# ============================================================================

setup() {
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
        echo "${RED}ERROR: Cannot find project root - run from project directory${RESET}"
        exit 1
    fi

    # Source r dispatcher
    source "$project_root/lib/dispatchers/r-dispatcher.zsh"
}

cleanup() {
    reset_mocks
}

# ============================================================================
# FUNCTION EXISTENCE TESTS
# ============================================================================

test_r_function_exists() {
    test_case "r function is defined"

    if (( $+functions[r] )); then
        test_pass
    else
        test_fail "r function not defined"
    fi
}

test_r_help_function_exists() {
    test_case "_r_help function is defined"

    if (( $+functions[_r_help] )); then
        test_pass
    else
        test_fail "_r_help function not defined"
    fi
}

# ============================================================================
# HELP TESTS
# ============================================================================

test_r_help() {
    test_case "r help shows usage"

    local output=$(r help 2>&1)
    assert_not_contains "$output" "command not found"

    if echo "$output" | grep -q "R Package Development"; then
        test_pass
    else
        test_fail "Help header not found"
    fi
}

test_r_help_flag() {
    test_case "r h works (shortcut)"

    local output=$(r h 2>&1)
    assert_not_contains "$output" "command not found"

    if echo "$output" | grep -q "R Package Development"; then
        test_pass
    else
        test_fail "h shortcut not working"
    fi
}

# ============================================================================
# HELP CONTENT TESTS
# ============================================================================

test_help_shows_test() {
    test_case "help shows test command"

    local output=$(r help 2>&1)

    if echo "$output" | grep -q "r test"; then
        test_pass
    else
        test_fail "test not in help"
    fi
}

test_help_shows_cycle() {
    test_case "help shows cycle command"

    local output=$(r help 2>&1)

    if echo "$output" | grep -q "r cycle"; then
        test_pass
    else
        test_fail "cycle not in help"
    fi
}

test_help_shows_doc() {
    test_case "help shows doc command"

    local output=$(r help 2>&1)

    if echo "$output" | grep -q "r doc"; then
        test_pass
    else
        test_fail "doc not in help"
    fi
}

test_help_shows_check() {
    test_case "help shows check command"

    local output=$(r help 2>&1)

    if echo "$output" | grep -q "r check"; then
        test_pass
    else
        test_fail "check not in help"
    fi
}

test_help_shows_build() {
    test_case "help shows build command"

    local output=$(r help 2>&1)

    if echo "$output" | grep -q "r build"; then
        test_pass
    else
        test_fail "build not in help"
    fi
}

test_help_shows_cran() {
    test_case "help shows cran command"

    local output=$(r help 2>&1)

    if echo "$output" | grep -q "r cran"; then
        test_pass
    else
        test_fail "cran not in help"
    fi
}

test_help_shows_shortcuts() {
    test_case "help shows version bumps section"

    local output=$(r help 2>&1)

    if echo "$output" | grep -q "VERSION BUMPS"; then
        test_pass
    else
        test_fail "version bumps section not found"
    fi
}

test_help_shows_cleanup() {
    test_case "help shows cleanup section"

    local output=$(r help 2>&1)

    if echo "$output" | grep -q "CLEANUP"; then
        test_pass
    else
        test_fail "cleanup section not found"
    fi
}

# ============================================================================
# UNKNOWN COMMAND TESTS
# ============================================================================

test_unknown_command() {
    test_case "r unknown-cmd shows error"

    local output=$(r unknown-xyz-command 2>&1)

    if echo "$output" | grep -q "Unknown action"; then
        test_pass
    else
        test_fail "Unknown action error not shown"
    fi
}

test_unknown_command_suggests_help() {
    test_case "unknown command suggests r help"

    local output=$(r foobar 2>&1)

    if echo "$output" | grep -q "r help"; then
        test_pass
    else
        test_fail "Doesn't suggest r help"
    fi
}

# ============================================================================
# CLEANUP COMMAND TESTS (safe to run)
# ============================================================================

test_clean_command() {
    test_case "r clean removes files (in temp dir)"

    # Create temp dir with test files
    local temp_dir=$(mktemp -d)
    touch "$temp_dir/.Rhistory"
    touch "$temp_dir/.RData"

    # Run clean in that directory
    local output=$(cd "$temp_dir" && r clean 2>&1)

    if echo "$output" | grep -q "Removed .Rhistory"; then
        test_pass
    else
        test_fail "clean command message not shown"
    fi

    # Cleanup
    rm -rf "$temp_dir"
}

test_tex_command() {
    test_case "r tex removes LaTeX files (in temp dir)"

    # Create temp dir with test files
    local temp_dir=$(mktemp -d)
    touch "$temp_dir/test.aux"
    touch "$temp_dir/test.log"

    # Run tex in that directory
    local output=$(cd "$temp_dir" && r tex 2>&1)

    if echo "$output" | grep -q "Removed LaTeX"; then
        test_pass
    else
        test_fail "tex command message not shown"
    fi

    # Cleanup
    rm -rf "$temp_dir"
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite_start "R Dispatcher Tests"

    setup

    echo "${YELLOW}Function Existence Tests${RESET}"
    echo "────────────────────────────────────────"
    test_r_function_exists
    test_r_help_function_exists
    echo ""

    echo "${YELLOW}Help Tests${RESET}"
    echo "────────────────────────────────────────"
    test_r_help
    test_r_help_flag
    echo ""

    echo "${YELLOW}Help Content Tests${RESET}"
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

    echo "${YELLOW}Unknown Command Tests${RESET}"
    echo "────────────────────────────────────────"
    test_unknown_command
    test_unknown_command_suggests_help
    echo ""

    echo "${YELLOW}Cleanup Command Tests${RESET}"
    echo "────────────────────────────────────────"
    test_clean_command
    test_tex_command
    echo ""

    cleanup
    test_suite_end
}

main "$@"
exit $?
