#!/usr/bin/env zsh
# Test script for qu dispatcher
# Tests: help, subcommand detection, keyword recognition, clean command

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
    echo ""
    echo "${YELLOW}Setting up test environment...${RESET}"

    local project_root="$PROJECT_ROOT"

    if [[ -z "$project_root" || ! -f "$project_root/lib/dispatchers/qu-dispatcher.zsh" ]]; then
        if [[ -f "$PWD/lib/dispatchers/qu-dispatcher.zsh" ]]; then
            project_root="$PWD"
        elif [[ -f "$PWD/../lib/dispatchers/qu-dispatcher.zsh" ]]; then
            project_root="$PWD/.."
        fi
    fi

    if [[ -z "$project_root" || ! -f "$project_root/lib/dispatchers/qu-dispatcher.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root - run from project directory${RESET}"
        exit 1
    fi

    echo "  Project root: $project_root"

    # Source qu dispatcher
    source "$project_root/lib/dispatchers/qu-dispatcher.zsh"

    echo "  Loaded: qu-dispatcher.zsh"
    echo ""
}

cleanup() {
    reset_mocks
}
trap cleanup EXIT

# ============================================================================
# FUNCTION EXISTENCE TESTS
# ============================================================================

test_qu_function_exists() {
    test_case "qu function is defined"

    if (( $+functions[qu] )); then
        test_pass
    else
        test_fail "qu function not defined"
    fi
}

test_qu_help_function_exists() {
    test_case "_qu_help function is defined"

    if (( $+functions[_qu_help] )); then
        test_pass
    else
        test_fail "_qu_help function not defined"
    fi
}

# ============================================================================
# HELP TESTS
# ============================================================================

test_qu_help() {
    test_case "qu help shows usage"

    local output=$(qu help 2>&1)
    assert_not_contains "$output" "command not found"

    if echo "$output" | grep -q "Quarto Publishing"; then
        test_pass
    else
        test_fail "Help header not found"
    fi
}

test_qu_help_h_flag() {
    test_case "qu -h works"

    local output=$(qu -h 2>&1)
    assert_not_contains "$output" "command not found"

    if echo "$output" | grep -q "Quarto Publishing"; then
        test_pass
    else
        test_fail "-h flag not working"
    fi
}

test_qu_help_long_flag() {
    test_case "qu --help works"

    local output=$(qu --help 2>&1)
    assert_not_contains "$output" "command not found"

    if echo "$output" | grep -q "Quarto Publishing"; then
        test_pass
    else
        test_fail "--help flag not working"
    fi
}

# ============================================================================
# HELP CONTENT TESTS
# ============================================================================

test_help_shows_preview() {
    test_case "help shows preview command"

    local output=$(qu help 2>&1)

    if echo "$output" | grep -q "qu preview"; then
        test_pass
    else
        test_fail "preview not in help"
    fi
}

test_help_shows_render() {
    test_case "help shows render command"

    local output=$(qu help 2>&1)

    if echo "$output" | grep -q "qu render"; then
        test_pass
    else
        test_fail "render not in help"
    fi
}

test_help_shows_pdf() {
    test_case "help shows pdf command"

    local output=$(qu help 2>&1)

    if echo "$output" | grep -q "qu pdf"; then
        test_pass
    else
        test_fail "pdf not in help"
    fi
}

test_help_shows_html() {
    test_case "help shows html command"

    local output=$(qu help 2>&1)

    if echo "$output" | grep -q "qu html"; then
        test_pass
    else
        test_fail "html not in help"
    fi
}

test_help_shows_docx() {
    test_case "help shows docx command"

    local output=$(qu help 2>&1)

    if echo "$output" | grep -q "qu docx"; then
        test_pass
    else
        test_fail "docx not in help"
    fi
}

test_help_shows_publish() {
    test_case "help shows publish command"

    local output=$(qu help 2>&1)

    if echo "$output" | grep -q "qu publish"; then
        test_pass
    else
        test_fail "publish not in help"
    fi
}

test_help_shows_clean() {
    test_case "help shows clean command"

    local output=$(qu help 2>&1)

    if echo "$output" | grep -q "qu clean"; then
        test_pass
    else
        test_fail "clean not in help"
    fi
}

test_help_shows_new() {
    test_case "help shows new command"

    local output=$(qu help 2>&1)

    if echo "$output" | grep -q "qu new"; then
        test_pass
    else
        test_fail "new not in help"
    fi
}

test_help_shows_smart_default() {
    test_case "help shows smart default workflow"

    local output=$(qu help 2>&1)

    if echo "$output" | grep -q "SMART DEFAULT"; then
        test_pass
    else
        test_fail "smart default section not found"
    fi
}

# ============================================================================
# UNKNOWN COMMAND TESTS
# ============================================================================

test_unknown_command() {
    test_case "qu unknown-cmd shows error"

    local output=$(qu unknown-xyz-command 2>&1)
    assert_not_contains "$output" "command not found"

    if echo "$output" | grep -q "unknown command"; then
        test_pass
    else
        test_fail "Unknown command error not shown"
    fi
}

test_unknown_command_suggests_help() {
    test_case "unknown command suggests qu help"

    local output=$(qu foobar 2>&1)
    assert_not_contains "$output" "command not found"

    if echo "$output" | grep -q "qu help"; then
        test_pass
    else
        test_fail "Doesn't suggest qu help"
    fi
}

# ============================================================================
# CLEAN COMMAND TEST (safe to run)
# ============================================================================

test_clean_command() {
    test_case "qu clean removes cache directories"

    # Create temp dir with Quarto cache directories
    local temp_dir=$(mktemp -d)
    mkdir -p "$temp_dir/_site"
    mkdir -p "$temp_dir/document_cache"
    mkdir -p "$temp_dir/document_files"

    # Run clean in that directory
    (cd "$temp_dir" && qu clean 2>&1)

    # Check directories were removed
    if [[ ! -d "$temp_dir/_site" ]]; then
        test_pass
    else
        test_fail "_site not removed"
    fi

    # Cleanup
    rm -rf "$temp_dir"
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite_start "QU Dispatcher Tests"

    setup

    echo "${YELLOW}Function Existence Tests${RESET}"
    echo "────────────────────────────────────────"
    test_qu_function_exists
    test_qu_help_function_exists
    echo ""

    echo "${YELLOW}Help Tests${RESET}"
    echo "────────────────────────────────────────"
    test_qu_help
    test_qu_help_h_flag
    test_qu_help_long_flag
    echo ""

    echo "${YELLOW}Help Content Tests${RESET}"
    echo "────────────────────────────────────────"
    test_help_shows_preview
    test_help_shows_render
    test_help_shows_pdf
    test_help_shows_html
    test_help_shows_docx
    test_help_shows_publish
    test_help_shows_clean
    test_help_shows_new
    test_help_shows_smart_default
    echo ""

    echo "${YELLOW}Unknown Command Tests${RESET}"
    echo "────────────────────────────────────────"
    test_unknown_command
    test_unknown_command_suggests_help
    echo ""

    echo "${YELLOW}Clean Command Tests${RESET}"
    echo "────────────────────────────────────────"
    test_clean_command
    echo ""

    cleanup
    test_suite_end
}

main "$@"
exit $?
