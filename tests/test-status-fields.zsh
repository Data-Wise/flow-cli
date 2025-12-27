#!/usr/bin/env zsh
# Test script for _flow_status_get_field and _flow_status_set_field
# Tests: reading, writing, case-insensitivity, missing fields

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
    if [[ -z "$project_root" || ! -f "$project_root/commands/status.zsh" ]]; then
        if [[ -f "$PWD/commands/status.zsh" ]]; then
            project_root="$PWD"
        elif [[ -f "$PWD/../commands/status.zsh" ]]; then
            project_root="$PWD/.."
        fi
    fi

    if [[ ! -f "$project_root/commands/status.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root${NC}"
        exit 1
    fi

    # Source required files
    source "$project_root/lib/core.zsh" 2>/dev/null || true
    source "$project_root/commands/status.zsh"

    # Create temp directory for test files
    TEST_DIR=$(mktemp -d)

    echo "  Project root: $project_root"
    echo "  Test dir: $TEST_DIR"
    echo ""
}

cleanup() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# ============================================================================
# TEST: _flow_status_get_field
# ============================================================================

test_get_field_existing() {
    log_test "_flow_status_get_field finds existing field"

    local tmp="$TEST_DIR/status1.txt"
    cat > "$tmp" << 'EOF'
# Test Status File
## Status: active
## Progress: 75
## Focus: Testing the get field function
EOF

    local result=$(_flow_status_get_field "$tmp" "Status")
    if [[ "$result" == "active" ]]; then
        pass
    else
        fail "Expected 'active', got '$result'"
    fi
}

test_get_field_with_spaces() {
    log_test "_flow_status_get_field handles values with spaces"

    local tmp="$TEST_DIR/status2.txt"
    cat > "$tmp" << 'EOF'
## Focus: This is a long focus with spaces
EOF

    local result=$(_flow_status_get_field "$tmp" "Focus")
    if [[ "$result" == "This is a long focus with spaces" ]]; then
        pass
    else
        fail "Expected 'This is a long focus with spaces', got '$result'"
    fi
}

test_get_field_case_insensitive() {
    log_test "_flow_status_get_field is case-insensitive"

    local tmp="$TEST_DIR/status3.txt"
    cat > "$tmp" << 'EOF'
## STATUS: active
EOF

    local result=$(_flow_status_get_field "$tmp" "status")
    if [[ "$result" == "active" ]]; then
        pass
    else
        fail "Expected 'active' (case-insensitive), got '$result'"
    fi
}

test_get_field_missing() {
    log_test "_flow_status_get_field returns 1 for missing field"

    local tmp="$TEST_DIR/status4.txt"
    cat > "$tmp" << 'EOF'
## Status: active
EOF

    local result
    result=$(_flow_status_get_field "$tmp" "NonExistent")
    local exit_code=$?

    if [[ $exit_code -eq 1 && -z "$result" ]]; then
        pass
    else
        fail "Expected exit code 1 and empty result, got code=$exit_code result='$result'"
    fi
}

test_get_field_missing_file() {
    log_test "_flow_status_get_field returns 1 for missing file"

    local result
    result=$(_flow_status_get_field "/nonexistent/file.txt" "Status")
    local exit_code=$?

    if [[ $exit_code -eq 1 ]]; then
        pass
    else
        fail "Expected exit code 1 for missing file, got $exit_code"
    fi
}

test_get_field_numeric() {
    log_test "_flow_status_get_field handles numeric values"

    local tmp="$TEST_DIR/status5.txt"
    cat > "$tmp" << 'EOF'
## Progress: 100
## Priority: 1
EOF

    local result=$(_flow_status_get_field "$tmp" "Progress")
    if [[ "$result" == "100" ]]; then
        pass
    else
        fail "Expected '100', got '$result'"
    fi
}

# ============================================================================
# TEST: _flow_status_set_field
# ============================================================================

test_set_field_update_existing() {
    log_test "_flow_status_set_field updates existing field"

    local tmp="$TEST_DIR/status6.txt"
    cat > "$tmp" << 'EOF'
## Status: active
## Progress: 50
EOF

    _flow_status_set_field "$tmp" "Progress" "75"

    local result=$(_flow_status_get_field "$tmp" "Progress")
    if [[ "$result" == "75" ]]; then
        pass
    else
        fail "Expected '75' after update, got '$result'"
    fi
}

test_set_field_add_new() {
    log_test "_flow_status_set_field adds new field"

    local tmp="$TEST_DIR/status7.txt"
    cat > "$tmp" << 'EOF'
## Status: active
EOF

    _flow_status_set_field "$tmp" "Focus" "New focus item"

    local result=$(_flow_status_get_field "$tmp" "Focus")
    if [[ "$result" == "New focus item" ]]; then
        pass
    else
        fail "Expected 'New focus item', got '$result'"
    fi
}

test_set_field_preserves_other_lines() {
    log_test "_flow_status_set_field preserves other content"

    local tmp="$TEST_DIR/status8.txt"
    cat > "$tmp" << 'EOF'
# Header comment
## Status: active
## Progress: 50
Some other content
EOF

    _flow_status_set_field "$tmp" "Progress" "100"

    # Check that header and other content still exist
    if grep -q "# Header comment" "$tmp" && grep -q "Some other content" "$tmp"; then
        pass
    else
        fail "Other content was not preserved"
    fi
}

test_set_field_case_insensitive_update() {
    log_test "_flow_status_set_field updates case-insensitively"

    local tmp="$TEST_DIR/status9.txt"
    cat > "$tmp" << 'EOF'
## STATUS: active
EOF

    _flow_status_set_field "$tmp" "status" "paused"

    # Should update the existing field (possibly changing case)
    local result=$(_flow_status_get_field "$tmp" "status")
    if [[ "$result" == "paused" ]]; then
        pass
    else
        fail "Expected 'paused', got '$result'"
    fi
}

test_set_field_missing_file() {
    log_test "_flow_status_set_field returns 1 for missing file"

    _flow_status_set_field "/nonexistent/file.txt" "Status" "active"
    local exit_code=$?

    if [[ $exit_code -eq 1 ]]; then
        pass
    else
        fail "Expected exit code 1 for missing file, got $exit_code"
    fi
}

test_set_field_special_chars() {
    log_test "_flow_status_set_field handles special characters"

    local tmp="$TEST_DIR/status10.txt"
    cat > "$tmp" << 'EOF'
## Status: active
EOF

    _flow_status_set_field "$tmp" "Focus" "Fix bug #123 - user's issue"

    local result=$(_flow_status_get_field "$tmp" "Focus")
    if [[ "$result" == "Fix bug #123 - user's issue" ]]; then
        pass
    else
        fail "Expected 'Fix bug #123 - user's issue', got '$result'"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    echo ""
    echo "=========================================="
    echo "  Status Field Functions Test Suite"
    echo "=========================================="

    setup

    echo "${YELLOW}--- _flow_status_get_field tests ---${NC}"
    test_get_field_existing
    test_get_field_with_spaces
    test_get_field_case_insensitive
    test_get_field_missing
    test_get_field_missing_file
    test_get_field_numeric

    echo ""
    echo "${YELLOW}--- _flow_status_set_field tests ---${NC}"
    test_set_field_update_existing
    test_set_field_add_new
    test_set_field_preserves_other_lines
    test_set_field_case_insensitive_update
    test_set_field_missing_file
    test_set_field_special_chars

    cleanup

    echo ""
    echo "=========================================="
    echo "  Results: ${GREEN}$TESTS_PASSED passed${NC}, ${RED}$TESTS_FAILED failed${NC}"
    echo "=========================================="
    echo ""

    if (( TESTS_FAILED > 0 )); then
        exit 1
    fi
}

main "$@"
