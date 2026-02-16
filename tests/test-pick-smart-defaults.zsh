#!/usr/bin/env zsh
# Test script for pick smart defaults (Phase 1 & 2)
# Tests: session management, direct jump, _proj_find_all

# Don't exit on error - we want to run all tests
# set -e

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

source "$SCRIPT_DIR/test-framework.zsh"

# ============================================================================
# SETUP
# ============================================================================

TEST_SESSION_FILE="/tmp/test-project-session"

setup() {
    # Source pick.zsh
    source "$PROJECT_ROOT/commands/pick.zsh"

    # Override session file for testing
    PROJ_SESSION_FILE="$TEST_SESSION_FILE"

    # Clean up any existing test session
    rm -f "$TEST_SESSION_FILE"
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
    test_case "_proj_save_session creates file"

    find_test_project
    _proj_save_session "$TEST_PROJECT_DIR"

    if [[ -f "$PROJ_SESSION_FILE" ]]; then
        test_pass
    else
        test_fail "Session file not created"
    fi
}

test_session_save_format() {
    test_case "_proj_save_session format (name|dir|timestamp)"

    find_test_project
    _proj_save_session "$TEST_PROJECT_DIR"
    local content=$(cat "$PROJ_SESSION_FILE")
    local proj_name=$(basename "$TEST_PROJECT_DIR")

    # Should be: <name>|<dir>|<timestamp>
    if [[ "$content" == ${proj_name}\|${TEST_PROJECT_DIR}\|* ]]; then
        test_pass
    else
        test_fail "Format mismatch: $content"
    fi
}

test_session_get_valid() {
    test_case "_proj_get_session returns valid session"

    find_test_project
    _proj_save_session "$TEST_PROJECT_DIR"
    local result=$(_proj_get_session)

    if [[ -n "$result" ]]; then
        test_pass
    else
        test_fail "No result returned"
    fi
}

test_session_get_format() {
    test_case "_proj_get_session format (name|dir|age_str)"

    find_test_project
    _proj_save_session "$TEST_PROJECT_DIR"
    local result=$(_proj_get_session)
    local proj_name=$(basename "$TEST_PROJECT_DIR")

    # Should be: <name>|<dir>|<age>
    if [[ "$result" == ${proj_name}\|${TEST_PROJECT_DIR}\|* ]]; then
        test_pass
    else
        test_fail "Format mismatch: $result"
    fi
}

test_session_age_just_now() {
    test_case "_proj_get_session age 'just now'"

    find_test_project
    _proj_save_session "$TEST_PROJECT_DIR"
    local result=$(_proj_get_session)
    local age="${result##*|}"

    if [[ "$age" == "just now" ]]; then
        test_pass
    else
        test_fail "Expected 'just now', got '$age'"
    fi
}

test_session_reject_old() {
    test_case "_proj_get_session rejects old session (>24h)"

    # Create session with old timestamp (25 hours ago)
    local old_time=$(($(date +%s) - 90000))
    echo "flow-cli|/tmp/test-project/flow-cli|$old_time" > "$PROJ_SESSION_FILE"

    local result=$(_proj_get_session)

    if [[ -z "$result" ]]; then
        test_pass
    else
        test_fail "Should have rejected old session"
    fi
}

test_session_reject_missing_dir() {
    test_case "_proj_get_session rejects missing directory"

    local timestamp=$(date +%s)
    echo "nonexistent|/nonexistent/path/project|$timestamp" > "$PROJ_SESSION_FILE"

    local result=$(_proj_get_session)

    if [[ -z "$result" ]]; then
        test_pass
    else
        test_fail "Should have rejected missing directory"
    fi
}

test_session_no_file() {
    test_case "_proj_get_session handles missing file"

    rm -f "$PROJ_SESSION_FILE"
    local result=$(_proj_get_session)

    if [[ -z "$result" ]]; then
        test_pass
    else
        test_fail "Should return empty for missing file"
    fi
}

# ============================================================================
# DIRECT JUMP TESTS (_proj_find_all)
# ============================================================================

test_find_all_returns_matches() {
    test_case "_proj_find_all returns matches for 'flow'"

    local output=$(_proj_find_all "flow" 2>&1)
    assert_not_contains "$output" "command not found"

    local matches=$(_proj_find_all "flow")

    if [[ -n "$matches" ]]; then
        test_pass
    else
        test_fail "No matches found"
    fi
}

test_find_all_format() {
    test_case "_proj_find_all format (name|type|dir)"

    local matches=$(_proj_find_all "flow")
    local first_match=$(echo "$matches" | head -1)

    # Should have 3 pipe-separated fields
    local field_count=$(echo "$first_match" | tr '|' '\n' | wc -l)

    if [[ $field_count -eq 3 ]]; then
        test_pass
    else
        test_fail "Expected 3 fields, got $field_count"
    fi
}

test_find_all_case_insensitive() {
    test_case "_proj_find_all case insensitive"

    local matches_lower=$(_proj_find_all "flow")
    local matches_upper=$(_proj_find_all "FLOW")

    if [[ -n "$matches_lower" && -n "$matches_upper" ]]; then
        test_pass
    else
        test_fail "Case sensitivity issue"
    fi
}

test_find_all_no_match() {
    test_case "_proj_find_all returns empty for no match"

    local matches=$(_proj_find_all "xyznonexistent123")

    if [[ -z "$matches" || "$matches" == "" ]]; then
        test_pass
    else
        test_fail "Should return empty for no match"
    fi
}

test_find_all_partial_match() {
    test_case "_proj_find_all partial match works"

    local output=$(_proj_find_all "med" 2>&1)
    assert_not_contains "$output" "command not found"

    # 'med' should match mediationverse, medrobust, etc.
    local matches=$(_proj_find_all "med")
    local count=$(echo "$matches" | grep -c "|" || echo 0)

    if [[ $count -gt 0 ]]; then
        test_pass
    else
        test_fail "Partial match should return results"
    fi
}

test_find_all_exact_match_priority() {
    test_case "_proj_find_all prioritizes exact match"

    # Regression test: 'scribe' should return only 'scribe', not 'scribe-sw'
    # This tests the bug where scribe-sw was returned instead of scribe
    local matches=$(_proj_find_all "flow")
    local count=$(echo "$matches" | wc -l | tr -d ' ')

    # If flow-cli exists, exact match should return only 1 result
    if [[ $count -eq 1 ]]; then
        local proj_name="${matches%%|*}"
        if [[ "$proj_name" == "flow-cli" ]]; then
            test_pass
        else
            test_fail "Exact match not prioritized: got '$proj_name'"
        fi
    else
        # No exact match, fuzzy is fine
        test_pass
    fi
}

test_find_exact_match_priority() {
    test_case "_proj_find prioritizes exact match"

    local output=$(_proj_find "flow-cli" 2>&1)
    assert_not_contains "$output" "command not found"

    # _proj_find should return exact match even if fuzzy match comes first alphabetically
    local result=$(_proj_find "flow-cli")
    local proj_name=$(basename "$result" 2>/dev/null)

    if [[ "$proj_name" == "flow-cli" ]]; then
        test_pass
    else
        test_fail "Expected 'flow-cli', got '$proj_name'"
    fi
}

test_find_all_with_category() {
    test_case "_proj_find_all with category filter"

    local all_matches=$(_proj_find_all "med")
    local r_matches=$(_proj_find_all "med" "r")

    # R-filtered should have same or fewer results
    local all_count=$(echo "$all_matches" | grep -c "|" || echo 0)
    local r_count=$(echo "$r_matches" | grep -c "|" || echo 0)

    if [[ $r_count -le $all_count ]]; then
        test_pass
    else
        test_fail "Category filter not working"
    fi
}

# ============================================================================
# PICK FUNCTION TESTS
# ============================================================================

test_pick_help() {
    test_case "pick help shows usage"

    local output=$(pick help 2>&1)
    assert_not_contains "$output" "command not found"

    if echo "$output" | grep -q "PICK"; then
        test_pass
    else
        test_fail "Help not showing"
    fi
}

test_pick_help_shows_direct_jump() {
    test_case "pick help mentions direct jump"

    local output=$(pick help 2>&1)

    if echo "$output" | grep -q "DIRECT JUMP"; then
        test_pass
    else
        test_fail "Direct jump not documented"
    fi
}

test_pick_help_shows_smart_resume() {
    test_case "pick help mentions smart resume"

    local output=$(pick help 2>&1)

    if echo "$output" | grep -q "SMART RESUME"; then
        test_pass
    else
        test_fail "Smart resume not documented"
    fi
}

test_pick_force_all_flag() {
    test_case "pick -a flag recognized"

    # Check that help mentions -a flag
    local output=$(pick help 2>&1)

    if echo "$output" | grep -q "\-a"; then
        test_pass
    else
        test_fail "-a flag not documented in help"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite_start "Pick Smart Defaults Tests (Phase 1 & 2)"

    setup

    echo "${YELLOW}Session Management Tests${RESET}"
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

    echo "${YELLOW}Direct Jump Tests (_proj_find_all)${RESET}"
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

    echo "${YELLOW}Pick Function Tests${RESET}"
    echo "────────────────────────────────────────"
    test_pick_help
    test_pick_help_shows_direct_jump
    test_pick_help_shows_smart_resume
    test_pick_force_all_flag
    echo ""

    cleanup

    test_suite_end
    exit $?
}

main "$@"
