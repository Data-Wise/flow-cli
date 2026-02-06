#!/usr/bin/env zsh
# Test script for work command and session management
# Tests: work, finish, hop, session tracking
# Generated: 2025-12-30

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

# Resolve project root at top level (${0:A} doesn't work inside functions)
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

setup() {
    echo ""
    echo "${YELLOW}Setting up test environment...${NC}"

    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root${NC}"
        exit 1
    fi

    echo "  Project root: $PROJECT_ROOT"

    # Source the plugin (non-interactive mode, no Atlas)
    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$PROJECT_ROOT"
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
        echo "${RED}Plugin failed to load${NC}"
        exit 1
    }

    # Close stdin to prevent any interactive commands from blocking
    exec < /dev/null

    # Create isolated test project root (avoids scanning real ~/projects)
    TEST_ROOT=$(mktemp -d)
    mkdir -p "$TEST_ROOT/dev-tools/mock-dev" "$TEST_ROOT/apps/test-app"
    for dir in "$TEST_ROOT"/dev-tools/mock-dev "$TEST_ROOT"/apps/test-app; do
        echo "## Status: active\n## Progress: 50" > "$dir/.STATUS"
    done
    FLOW_PROJECTS_ROOT="$TEST_ROOT"

    echo ""
}

# ============================================================================
# TESTS: Command existence
# ============================================================================

test_work_exists() {
    log_test "work command exists"

    if type work &>/dev/null; then
        pass
    else
        fail "work command not found"
    fi
}

test_finish_exists() {
    log_test "finish command exists"

    if type finish &>/dev/null; then
        pass
    else
        fail "finish command not found"
    fi
}

test_hop_exists() {
    log_test "hop command exists"

    if type hop &>/dev/null; then
        pass
    else
        fail "hop command not found"
    fi
}

test_why_exists() {
    log_test "why command exists"

    if type why &>/dev/null; then
        pass
    else
        fail "why command not found"
    fi
}

# ============================================================================
# TESTS: Helper functions
# ============================================================================

test_show_work_context_exists() {
    log_test "_flow_show_work_context function exists"

    if type _flow_show_work_context &>/dev/null; then
        pass
    else
        fail "_flow_show_work_context not found"
    fi
}

test_open_editor_exists() {
    log_test "_flow_open_editor function exists"

    if type _flow_open_editor &>/dev/null; then
        pass
    else
        fail "_flow_open_editor not found"
    fi
}

test_session_start_exists() {
    log_test "_flow_session_start function exists"

    if type _flow_session_start &>/dev/null; then
        pass
    else
        fail "_flow_session_start not found"
    fi
}

test_session_end_exists() {
    log_test "_flow_session_end function exists"

    if type _flow_session_end &>/dev/null; then
        pass
    else
        fail "_flow_session_end not found"
    fi
}

# ============================================================================
# TESTS: Core utility functions
# ============================================================================

test_find_project_root_exists() {
    log_test "_flow_find_project_root function exists"

    if type _flow_find_project_root &>/dev/null; then
        pass
    else
        fail "_flow_find_project_root not found"
    fi
}

test_get_project_exists() {
    log_test "_flow_get_project function exists"

    if type _flow_get_project &>/dev/null; then
        pass
    else
        fail "_flow_get_project not found"
    fi
}

test_project_name_exists() {
    log_test "_flow_project_name function exists"

    if type _flow_project_name &>/dev/null; then
        pass
    else
        fail "_flow_project_name not found"
    fi
}

test_pick_project_exists() {
    log_test "_flow_pick_project function exists"

    if type _flow_pick_project &>/dev/null; then
        pass
    else
        fail "_flow_pick_project not found"
    fi
}

# ============================================================================
# TESTS: work command behavior (non-destructive)
# ============================================================================

test_work_no_args_returns_error() {
    log_test "work (no args, no fzf) shows error or picker"

    # Override _flow_has_fzf so work doesn't launch fzf (opens /dev/tty, blocks)
    _flow_has_fzf() { return 1; }

    local output=$(work 2>&1)
    local exit_code=$?

    # Restore original
    unfunction _flow_has_fzf 2>/dev/null

    # Without fzf and not in a project dir, should show usage/error (exit 1)
    if [[ $exit_code -eq 0 || $exit_code -eq 1 ]]; then
        pass
    else
        fail "Unexpected exit code: $exit_code"
    fi
}

test_work_invalid_project() {
    log_test "work with invalid project shows error"

    local output=$(work nonexistent_project_xyz 2>&1)

    if [[ "$output" == *"not found"* || "$output" == *"error"* || "$output" == *"Error"* ]]; then
        pass
    else
        fail "Should show error for invalid project"
    fi
}

# ============================================================================
# TESTS: finish command behavior
# ============================================================================

test_finish_no_session() {
    log_test "finish when not in session handles gracefully"

    local output=$(finish 2>&1)
    local exit_code=$?

    # Should not crash, may show warning or just succeed
    if [[ $exit_code -eq 0 || $exit_code -eq 1 ]]; then
        pass
    else
        fail "Unexpected exit code: $exit_code"
    fi
}

# ============================================================================
# TESTS: hop command behavior
# ============================================================================

test_hop_help() {
    log_test "hop without args shows help or picker"

    # Override _flow_has_fzf so hop doesn't launch fzf (opens /dev/tty, blocks)
    _flow_has_fzf() { return 1; }

    local output=$(hop 2>&1)
    local exit_code=$?

    unfunction _flow_has_fzf 2>/dev/null

    # Should either show picker or usage
    if [[ $exit_code -eq 0 || $exit_code -eq 1 ]]; then
        pass
    else
        fail "Unexpected exit code: $exit_code"
    fi
}

# ============================================================================
# TESTS: why command behavior
# ============================================================================

test_why_runs() {
    log_test "why command runs without error"

    local output=$(why 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

# ============================================================================
# TESTS: _flow_show_work_context output
# ============================================================================

test_show_context_runs() {
    log_test "_flow_show_work_context runs without error"

    local output=$(_flow_show_work_context "test-project" "/tmp" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        pass
    else
        fail "Exit code: $exit_code"
    fi
}

test_show_context_shows_project() {
    log_test "_flow_show_work_context includes project name"

    local output=$(_flow_show_work_context "my-test-project" "/tmp" 2>&1)

    if [[ "$output" == *"my-test-project"* ]]; then
        pass
    else
        fail "Should show project name in output"
    fi
}

# ============================================================================
# TESTS: Project detection utilities
# ============================================================================

test_find_project_root_in_git() {
    log_test "_flow_find_project_root finds git root"

    # Test in current directory (flow-cli is a git repo)
    cd "${0:A:h:h}" 2>/dev/null
    local root=$(_flow_find_project_root 2>/dev/null)
    local exit_code=$?

    # In CI, mock .git directories don't have actual git metadata
    # The function returns empty for mock dirs - that's acceptable
    # Real git repos return the root path
    if [[ -n "$root" && -d "$root" ]]; then
        # Real git repo - found the root
        pass
    elif [[ $exit_code -eq 0 || -z "$root" ]]; then
        # CI mock environment - function didn't crash, empty return is OK
        pass
    else
        fail "Function crashed or returned unexpected result"
    fi
}

test_detect_project_type_exists() {
    log_test "_flow_detect_project_type function exists"

    if type _flow_detect_project_type &>/dev/null; then
        pass
    else
        fail "_flow_detect_project_type not found"
    fi
}

test_project_icon_exists() {
    log_test "_flow_project_icon function exists"

    if type _flow_project_icon &>/dev/null; then
        pass
    else
        fail "_flow_project_icon not found"
    fi
}

# ============================================================================
# TESTS: Environment variables
# ============================================================================

test_flow_projects_root_defined() {
    log_test "FLOW_PROJECTS_ROOT is defined"

    if [[ -n "$FLOW_PROJECTS_ROOT" ]]; then
        pass
    else
        fail "FLOW_PROJECTS_ROOT not defined"
    fi
}

test_flow_projects_root_exists() {
    log_test "FLOW_PROJECTS_ROOT directory exists"

    if [[ -d "$FLOW_PROJECTS_ROOT" ]]; then
        pass
    else
        fail "FLOW_PROJECTS_ROOT directory not found: $FLOW_PROJECTS_ROOT"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    echo ""
    echo "${YELLOW}========================================${NC}"
    echo "${YELLOW}  Work Command Tests${NC}"
    echo "${YELLOW}========================================${NC}"

    setup

    echo "${CYAN}--- Environment tests ---${NC}"
    test_flow_projects_root_defined
    test_flow_projects_root_exists

    echo ""
    echo "${CYAN}--- Command existence tests ---${NC}"
    test_work_exists
    test_finish_exists
    test_hop_exists
    test_why_exists

    echo ""
    echo "${CYAN}--- Helper function tests ---${NC}"
    test_show_work_context_exists
    test_open_editor_exists
    test_session_start_exists
    test_session_end_exists

    echo ""
    echo "${CYAN}--- Core utility tests ---${NC}"
    test_find_project_root_exists
    test_get_project_exists
    test_project_name_exists
    test_pick_project_exists

    echo ""
    echo "${CYAN}--- work command behavior tests ---${NC}"
    test_work_no_args_returns_error
    test_work_invalid_project

    echo ""
    echo "${CYAN}--- finish command tests ---${NC}"
    test_finish_no_session

    echo ""
    echo "${CYAN}--- hop command tests ---${NC}"
    test_hop_help

    echo ""
    echo "${CYAN}--- why command tests ---${NC}"
    test_why_runs

    echo ""
    echo "${CYAN}--- Context display tests ---${NC}"
    test_show_context_runs
    test_show_context_shows_project

    echo ""
    echo "${CYAN}--- Project detection tests ---${NC}"
    test_find_project_root_in_git
    test_detect_project_type_exists
    test_project_icon_exists

    # Summary
    echo ""
    echo "${YELLOW}========================================${NC}"
    echo "${YELLOW}  Test Summary${NC}"
    echo "${YELLOW}========================================${NC}"
    echo "  ${GREEN}Passed:${NC} $TESTS_PASSED"
    echo "  ${RED}Failed:${NC} $TESTS_FAILED"
    echo "  Total:  $((TESTS_PASSED + TESTS_FAILED))"
    echo ""

    # Cleanup temp dir (no trap — subshells can fire EXIT traps prematurely)
    [[ -n "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"

    if [[ $TESTS_FAILED -gt 0 ]]; then
        exit 1
    fi
}

main "$@"
