#!/usr/bin/env zsh
# Test script for qu dispatcher
# Tests: help, subcommand detection, keyword recognition, clean command

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

    if [[ -z "$project_root" || ! -f "$project_root/lib/dispatchers/qu-dispatcher.zsh" ]]; then
        if [[ -f "$PWD/lib/dispatchers/qu-dispatcher.zsh" ]]; then
            project_root="$PWD"
        elif [[ -f "$PWD/../lib/dispatchers/qu-dispatcher.zsh" ]]; then
            project_root="$PWD/.."
        fi
    fi

    if [[ -z "$project_root" || ! -f "$project_root/lib/dispatchers/qu-dispatcher.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root - run from project directory${NC}"
        exit 1
    fi

    echo "  Project root: $project_root"

    # Source qu dispatcher
    source "$project_root/lib/dispatchers/qu-dispatcher.zsh"

    echo "  Loaded: qu-dispatcher.zsh"
    echo ""
}

# ============================================================================
# FUNCTION EXISTENCE TESTS
# ============================================================================

test_qu_function_exists() {
    log_test "qu function is defined"

    if (( $+functions[qu] )); then
        pass
    else
        fail "qu function not defined"
    fi
}

test_qu_help_function_exists() {
    log_test "_qu_help function is defined"

    if (( $+functions[_qu_help] )); then
        pass
    else
        fail "_qu_help function not defined"
    fi
}

# ============================================================================
# HELP TESTS
# ============================================================================

test_qu_help() {
    log_test "qu help shows usage"

    local output=$(qu help 2>&1)

    if echo "$output" | grep -q "Quarto Publishing"; then
        pass
    else
        fail "Help header not found"
    fi
}

test_qu_help_h_flag() {
    log_test "qu -h works"

    local output=$(qu -h 2>&1)

    if echo "$output" | grep -q "Quarto Publishing"; then
        pass
    else
        fail "-h flag not working"
    fi
}

test_qu_help_long_flag() {
    log_test "qu --help works"

    local output=$(qu --help 2>&1)

    if echo "$output" | grep -q "Quarto Publishing"; then
        pass
    else
        fail "--help flag not working"
    fi
}

# ============================================================================
# HELP CONTENT TESTS
# ============================================================================

test_help_shows_preview() {
    log_test "help shows preview command"

    local output=$(qu help 2>&1)

    if echo "$output" | grep -q "qu preview"; then
        pass
    else
        fail "preview not in help"
    fi
}

test_help_shows_render() {
    log_test "help shows render command"

    local output=$(qu help 2>&1)

    if echo "$output" | grep -q "qu render"; then
        pass
    else
        fail "render not in help"
    fi
}

test_help_shows_pdf() {
    log_test "help shows pdf command"

    local output=$(qu help 2>&1)

    if echo "$output" | grep -q "qu pdf"; then
        pass
    else
        fail "pdf not in help"
    fi
}

test_help_shows_html() {
    log_test "help shows html command"

    local output=$(qu help 2>&1)

    if echo "$output" | grep -q "qu html"; then
        pass
    else
        fail "html not in help"
    fi
}

test_help_shows_docx() {
    log_test "help shows docx command"

    local output=$(qu help 2>&1)

    if echo "$output" | grep -q "qu docx"; then
        pass
    else
        fail "docx not in help"
    fi
}

test_help_shows_publish() {
    log_test "help shows publish command"

    local output=$(qu help 2>&1)

    if echo "$output" | grep -q "qu publish"; then
        pass
    else
        fail "publish not in help"
    fi
}

test_help_shows_clean() {
    log_test "help shows clean command"

    local output=$(qu help 2>&1)

    if echo "$output" | grep -q "qu clean"; then
        pass
    else
        fail "clean not in help"
    fi
}

test_help_shows_new() {
    log_test "help shows new command"

    local output=$(qu help 2>&1)

    if echo "$output" | grep -q "qu new"; then
        pass
    else
        fail "new not in help"
    fi
}

test_help_shows_smart_default() {
    log_test "help shows smart default workflow"

    local output=$(qu help 2>&1)

    if echo "$output" | grep -q "SMART DEFAULT"; then
        pass
    else
        fail "smart default section not found"
    fi
}

# ============================================================================
# UNKNOWN COMMAND TESTS
# ============================================================================

test_unknown_command() {
    log_test "qu unknown-cmd shows error"

    local output=$(qu unknown-xyz-command 2>&1)

    if echo "$output" | grep -q "unknown command"; then
        pass
    else
        fail "Unknown command error not shown"
    fi
}

test_unknown_command_suggests_help() {
    log_test "unknown command suggests qu help"

    local output=$(qu foobar 2>&1)

    if echo "$output" | grep -q "qu help"; then
        pass
    else
        fail "Doesn't suggest qu help"
    fi
}

# ============================================================================
# CLEAN COMMAND TEST (safe to run)
# ============================================================================

test_clean_command() {
    log_test "qu clean removes cache directories"

    # Create temp dir with Quarto cache directories
    local temp_dir=$(mktemp -d)
    mkdir -p "$temp_dir/_site"
    mkdir -p "$temp_dir/document_cache"
    mkdir -p "$temp_dir/document_files"

    # Run clean in that directory
    (cd "$temp_dir" && qu clean 2>&1)

    # Check directories were removed
    if [[ ! -d "$temp_dir/_site" ]]; then
        pass
    else
        fail "_site not removed"
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
    echo "║  QU Dispatcher Tests                                       ║"
    echo "╚════════════════════════════════════════════════════════════╝"

    setup

    echo "${YELLOW}Function Existence Tests${NC}"
    echo "────────────────────────────────────────"
    test_qu_function_exists
    test_qu_help_function_exists
    echo ""

    echo "${YELLOW}Help Tests${NC}"
    echo "────────────────────────────────────────"
    test_qu_help
    test_qu_help_h_flag
    test_qu_help_long_flag
    echo ""

    echo "${YELLOW}Help Content Tests${NC}"
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

    echo "${YELLOW}Unknown Command Tests${NC}"
    echo "────────────────────────────────────────"
    test_unknown_command
    test_unknown_command_suggests_help
    echo ""

    echo "${YELLOW}Clean Command Tests${NC}"
    echo "────────────────────────────────────────"
    test_clean_command
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
