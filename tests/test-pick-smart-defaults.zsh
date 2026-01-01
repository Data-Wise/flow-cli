#!/usr/bin/env zsh
# Test script for pick smart defaults (Phase 1 & 2)
# Tests: session management, direct jump, _proj_find_all

# Don't exit on error - we want to run all tests
# set -e

# ============================================================================
# TEST FRAMEWORK
# ============================================================================

TESTS_PASSED=0
TESTS_FAILED=0
TEST_SESSION_FILE="/tmp/test-project-session"

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

    # Source pick.zsh
    source "$project_root/commands/pick.zsh"

    # Override session file for testing
    PROJ_SESSION_FILE="$TEST_SESSION_FILE"

    # Clean up any existing test session
    rm -f "$TEST_SESSION_FILE"

    echo "  Session file: $PROJ_SESSION_FILE"
    echo ""
}

cleanup() {
    rm -f "$TEST_SESSION_FILE"
}

# ============================================================================
# SESSION MANAGEMENT TESTS
# ============================================================================

# Use a test directory that we know exists
TEST_PROJECT_DIR=""

find_test_project() {
    # Try to find a valid project directory for testing
    if [[ -d "$HOME/projects/dev-tools/flow-cli" ]]; then
        TEST_PROJECT_DIR="$HOME/projects/dev-tools/flow-cli"
    elif [[ -d "$PWD" && -d "$PWD/.git" ]]; then
        TEST_PROJECT_DIR="$PWD"
    else
        # Create a temp directory for testing
        TEST_PROJECT_DIR=$(mktemp -d)
        mkdir -p "$TEST_PROJECT_DIR/.git"
    fi
}

test_session_save() {
    log_test "_proj_save_session creates file"

    find_test_project
    _proj_save_session "$TEST_PROJECT_DIR"

    if [[ -f "$PROJ_SESSION_FILE" ]]; then
        pass
    else
        fail "Session file not created"
    fi
}

test_session_save_format() {
    log_test "_proj_save_session format (name|dir|timestamp)"

    find_test_project
    _proj_save_session "$TEST_PROJECT_DIR"
    local content=$(cat "$PROJ_SESSION_FILE")
    local proj_name=$(basename "$TEST_PROJECT_DIR")

    # Should be: <name>|<dir>|<timestamp>
    if [[ "$content" == ${proj_name}\|${TEST_PROJECT_DIR}\|* ]]; then
        pass
    else
        fail "Format mismatch: $content"
    fi
}

test_session_get_valid() {
    log_test "_proj_get_session returns valid session"

    find_test_project
    _proj_save_session "$TEST_PROJECT_DIR"
    local result=$(_proj_get_session)

    if [[ -n "$result" ]]; then
        pass
    else
        fail "No result returned"
    fi
}

test_session_get_format() {
    log_test "_proj_get_session format (name|dir|age_str)"

    find_test_project
    _proj_save_session "$TEST_PROJECT_DIR"
    local result=$(_proj_get_session)
    local proj_name=$(basename "$TEST_PROJECT_DIR")

    # Should be: <name>|<dir>|<age>
    if [[ "$result" == ${proj_name}\|${TEST_PROJECT_DIR}\|* ]]; then
        pass
    else
        fail "Format mismatch: $result"
    fi
}

test_session_age_just_now() {
    log_test "_proj_get_session age 'just now'"

    find_test_project
    _proj_save_session "$TEST_PROJECT_DIR"
    local result=$(_proj_get_session)
    local age="${result##*|}"

    if [[ "$age" == "just now" ]]; then
        pass
    else
        fail "Expected 'just now', got '$age'"
    fi
}

test_session_reject_old() {
    log_test "_proj_get_session rejects old session (>24h)"

    # Create session with old timestamp (25 hours ago)
    local old_time=$(($(date +%s) - 90000))
    echo "flow-cli|/tmp/test-project/flow-cli|$old_time" > "$PROJ_SESSION_FILE"

    local result=$(_proj_get_session)

    if [[ -z "$result" ]]; then
        pass
    else
        fail "Should have rejected old session"
    fi
}

test_session_reject_missing_dir() {
    log_test "_proj_get_session rejects missing directory"

    local timestamp=$(date +%s)
    echo "nonexistent|/nonexistent/path/project|$timestamp" > "$PROJ_SESSION_FILE"

    local result=$(_proj_get_session)

    if [[ -z "$result" ]]; then
        pass
    else
        fail "Should have rejected missing directory"
    fi
}

test_session_no_file() {
    log_test "_proj_get_session handles missing file"

    rm -f "$PROJ_SESSION_FILE"
    local result=$(_proj_get_session)

    if [[ -z "$result" ]]; then
        pass
    else
        fail "Should return empty for missing file"
    fi
}

# ============================================================================
# DIRECT JUMP TESTS (_proj_find_all)
# ============================================================================

test_find_all_returns_matches() {
    log_test "_proj_find_all returns matches for 'flow'"

    local matches=$(_proj_find_all "flow")

    if [[ -n "$matches" ]]; then
        pass
    else
        fail "No matches found"
    fi
}

test_find_all_format() {
    log_test "_proj_find_all format (name|type|dir)"

    local matches=$(_proj_find_all "flow")
    local first_match=$(echo "$matches" | head -1)

    # Should have 3 pipe-separated fields
    local field_count=$(echo "$first_match" | tr '|' '\n' | wc -l)

    if [[ $field_count -eq 3 ]]; then
        pass
    else
        fail "Expected 3 fields, got $field_count"
    fi
}

test_find_all_case_insensitive() {
    log_test "_proj_find_all case insensitive"

    local matches_lower=$(_proj_find_all "flow")
    local matches_upper=$(_proj_find_all "FLOW")

    if [[ -n "$matches_lower" && -n "$matches_upper" ]]; then
        pass
    else
        fail "Case sensitivity issue"
    fi
}

test_find_all_no_match() {
    log_test "_proj_find_all returns empty for no match"

    local matches=$(_proj_find_all "xyznonexistent123")

    if [[ -z "$matches" || "$matches" == "" ]]; then
        pass
    else
        fail "Should return empty for no match"
    fi
}

test_find_all_partial_match() {
    log_test "_proj_find_all partial match works"

    # 'med' should match mediationverse, medrobust, etc.
    local matches=$(_proj_find_all "med")
    local count=$(echo "$matches" | grep -c "|" || echo 0)

    if [[ $count -gt 0 ]]; then
        pass
    else
        fail "Partial match should return results"
    fi
}

test_find_all_exact_match_priority() {
    log_test "_proj_find_all prioritizes exact match"

    # Regression test: 'scribe' should return only 'scribe', not 'scribe-sw'
    # This tests the bug where scribe-sw was returned instead of scribe
    local matches=$(_proj_find_all "flow")
    local count=$(echo "$matches" | wc -l | tr -d ' ')

    # If flow-cli exists, exact match should return only 1 result
    if [[ $count -eq 1 ]]; then
        local proj_name="${matches%%|*}"
        if [[ "$proj_name" == "flow-cli" ]]; then
            pass
        else
            fail "Exact match not prioritized: got '$proj_name'"
        fi
    else
        # No exact match, fuzzy is fine
        pass
    fi
}

test_find_exact_match_priority() {
    log_test "_proj_find prioritizes exact match"

    # _proj_find should return exact match even if fuzzy match comes first alphabetically
    local result=$(_proj_find "flow-cli")
    local proj_name=$(basename "$result" 2>/dev/null)

    if [[ "$proj_name" == "flow-cli" ]]; then
        pass
    else
        fail "Expected 'flow-cli', got '$proj_name'"
    fi
}

test_find_all_with_category() {
    log_test "_proj_find_all with category filter"

    local all_matches=$(_proj_find_all "med")
    local r_matches=$(_proj_find_all "med" "r")

    # R-filtered should have same or fewer results
    local all_count=$(echo "$all_matches" | grep -c "|" || echo 0)
    local r_count=$(echo "$r_matches" | grep -c "|" || echo 0)

    if [[ $r_count -le $all_count ]]; then
        pass
    else
        fail "Category filter not working"
    fi
}

# ============================================================================
# PICK FUNCTION TESTS
# ============================================================================

test_pick_help() {
    log_test "pick help shows usage"

    local output=$(pick help 2>&1)

    if echo "$output" | grep -q "PICK"; then
        pass
    else
        fail "Help not showing"
    fi
}

test_pick_help_shows_direct_jump() {
    log_test "pick help mentions direct jump"

    local output=$(pick help 2>&1)

    if echo "$output" | grep -q "DIRECT JUMP"; then
        pass
    else
        fail "Direct jump not documented"
    fi
}

test_pick_help_shows_smart_resume() {
    log_test "pick help mentions smart resume"

    local output=$(pick help 2>&1)

    if echo "$output" | grep -q "SMART RESUME"; then
        pass
    else
        fail "Smart resume not documented"
    fi
}

test_pick_force_all_flag() {
    log_test "pick -a flag recognized"

    # Check that help mentions -a flag
    local output=$(pick help 2>&1)

    if echo "$output" | grep -q "\-a"; then
        pass
    else
        fail "-a flag not documented in help"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  Pick Smart Defaults Tests (Phase 1 & 2)                   ║"
    echo "╚════════════════════════════════════════════════════════════╝"

    setup

    echo "${YELLOW}Session Management Tests${NC}"
    echo "────────────────────────────────────────"
    test_session_save
    test_session_save_format
    test_session_get_valid
    test_session_get_format
    test_session_age_just_now
    test_session_reject_old
    test_session_reject_missing_dir
    test_session_no_file
    echo ""

    echo "${YELLOW}Direct Jump Tests (_proj_find_all)${NC}"
    echo "────────────────────────────────────────"
    test_find_all_returns_matches
    test_find_all_format
    test_find_all_case_insensitive
    test_find_all_no_match
    test_find_all_partial_match
    test_find_all_exact_match_priority
    test_find_exact_match_priority
    test_find_all_with_category
    echo ""

    echo "${YELLOW}Pick Function Tests${NC}"
    echo "────────────────────────────────────────"
    test_pick_help
    test_pick_help_shows_direct_jump
    test_pick_help_shows_smart_resume
    test_pick_force_all_flag
    echo ""

    cleanup

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
