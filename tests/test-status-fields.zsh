#!/usr/bin/env zsh
# Test script for _flow_status_get_field and _flow_status_set_field
# Tests: reading, writing, case-insensitivity, missing fields

# ============================================================================
# FRAMEWORK
# ============================================================================

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh"

# ============================================================================
# SETUP
# ============================================================================

setup() {
    # Get project root
    local project_root="$PROJECT_ROOT"
    if [[ ! -f "$project_root/commands/status.zsh" ]]; then
        if [[ -f "$PWD/commands/status.zsh" ]]; then
            project_root="$PWD"
        elif [[ -f "$PWD/../commands/status.zsh" ]]; then
            project_root="$PWD/.."
        fi
    fi

    if [[ ! -f "$project_root/commands/status.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root${RESET}"
        exit 1
    fi

    # Source required files
    source "$project_root/lib/core.zsh" 2>/dev/null || true
    source "$project_root/commands/status.zsh"

    # Create temp directory for test files
    TEST_DIR=$(mktemp -d)
}

cleanup() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
    reset_mocks
}

# ============================================================================
# TEST: _flow_status_get_field
# ============================================================================

test_get_field_existing() {
    test_case "_flow_status_get_field finds existing field"

    local tmp="$TEST_DIR/status1.txt"
    cat > "$tmp" << 'EOF'
# Test Status File
## Status: active
## Progress: 75
## Focus: Testing the get field function
EOF

    local result=$(_flow_status_get_field "$tmp" "Status")
    assert_equals "$result" "active" && test_pass
}

test_get_field_with_spaces() {
    test_case "_flow_status_get_field handles values with spaces"

    local tmp="$TEST_DIR/status2.txt"
    cat > "$tmp" << 'EOF'
## Focus: This is a long focus with spaces
EOF

    local result=$(_flow_status_get_field "$tmp" "Focus")
    assert_equals "$result" "This is a long focus with spaces" && test_pass
}

test_get_field_case_insensitive() {
    test_case "_flow_status_get_field is case-insensitive"

    local tmp="$TEST_DIR/status3.txt"
    cat > "$tmp" << 'EOF'
## STATUS: active
EOF

    local result=$(_flow_status_get_field "$tmp" "status")
    assert_equals "$result" "active" && test_pass
}

test_get_field_missing() {
    test_case "_flow_status_get_field returns 1 for missing field"

    local tmp="$TEST_DIR/status4.txt"
    cat > "$tmp" << 'EOF'
## Status: active
EOF

    local result
    result=$(_flow_status_get_field "$tmp" "NonExistent")
    local exit_code=$?

    assert_exit_code "$exit_code" 1 && assert_empty "$result" && test_pass
}

test_get_field_missing_file() {
    test_case "_flow_status_get_field returns 1 for missing file"

    local result
    result=$(_flow_status_get_field "/nonexistent/file.txt" "Status")
    local exit_code=$?

    assert_exit_code "$exit_code" 1 && test_pass
}

test_get_field_numeric() {
    test_case "_flow_status_get_field handles numeric values"

    local tmp="$TEST_DIR/status5.txt"
    cat > "$tmp" << 'EOF'
## Progress: 100
## Priority: 1
EOF

    local result=$(_flow_status_get_field "$tmp" "Progress")
    assert_equals "$result" "100" && test_pass
}

# ============================================================================
# TEST: _flow_status_set_field
# ============================================================================

test_set_field_update_existing() {
    test_case "_flow_status_set_field updates existing field"

    local tmp="$TEST_DIR/status6.txt"
    cat > "$tmp" << 'EOF'
## Status: active
## Progress: 50
EOF

    _flow_status_set_field "$tmp" "Progress" "75"

    local result=$(_flow_status_get_field "$tmp" "Progress")
    assert_equals "$result" "75" && test_pass
}

test_set_field_add_new() {
    test_case "_flow_status_set_field adds new field"

    local tmp="$TEST_DIR/status7.txt"
    cat > "$tmp" << 'EOF'
## Status: active
EOF

    _flow_status_set_field "$tmp" "Focus" "New focus item"

    local result=$(_flow_status_get_field "$tmp" "Focus")
    assert_equals "$result" "New focus item" && test_pass
}

test_set_field_preserves_other_lines() {
    test_case "_flow_status_set_field preserves other content"

    local tmp="$TEST_DIR/status8.txt"
    cat > "$tmp" << 'EOF'
# Header comment
## Status: active
## Progress: 50
Some other content
EOF

    _flow_status_set_field "$tmp" "Progress" "100"

    local content
    content=$(<"$tmp")
    assert_contains "$content" "# Header comment" && \
    assert_contains "$content" "Some other content" && test_pass
}

test_set_field_case_insensitive_update() {
    test_case "_flow_status_set_field updates case-insensitively"

    local tmp="$TEST_DIR/status9.txt"
    cat > "$tmp" << 'EOF'
## STATUS: active
EOF

    _flow_status_set_field "$tmp" "status" "paused"

    local result=$(_flow_status_get_field "$tmp" "status")
    assert_equals "$result" "paused" && test_pass
}

test_set_field_missing_file() {
    test_case "_flow_status_set_field returns 1 for missing file"

    _flow_status_set_field "/nonexistent/file.txt" "Status" "active"
    local exit_code=$?

    assert_exit_code "$exit_code" 1 && test_pass
}

test_set_field_special_chars() {
    test_case "_flow_status_set_field handles special characters"

    local tmp="$TEST_DIR/status10.txt"
    cat > "$tmp" << 'EOF'
## Status: active
EOF

    _flow_status_set_field "$tmp" "Focus" "Fix bug #123 - user's issue"

    local result=$(_flow_status_get_field "$tmp" "Focus")
    assert_equals "$result" "Fix bug #123 - user's issue" && test_pass
}

# ============================================================================
# FUNCTION EXISTS CHECKS
# ============================================================================

test_functions_exist() {
    test_case "_flow_status_get_field function exists"
    assert_function_exists "_flow_status_get_field" && test_pass

    test_case "_flow_status_set_field function exists"
    assert_function_exists "_flow_status_set_field" && test_pass
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite_start "Status Field Functions Test Suite"

    setup

    test_functions_exist

    test_suite_start "--- _flow_status_get_field tests ---"
    test_get_field_existing
    test_get_field_with_spaces
    test_get_field_case_insensitive
    test_get_field_missing
    test_get_field_missing_file
    test_get_field_numeric

    test_suite_start "--- _flow_status_set_field tests ---"
    test_set_field_update_existing
    test_set_field_add_new
    test_set_field_preserves_other_lines
    test_set_field_case_insensitive_update
    test_set_field_missing_file
    test_set_field_special_chars

    cleanup

    test_suite_end
    exit $?
}

main "$@"
