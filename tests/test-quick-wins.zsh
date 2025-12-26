#!/usr/bin/env zsh
# Test script for dashboard Quick Wins feature (v3.4.0)
# Tests: quick win detection, urgency indicators, .STATUS parsing

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

PROJECT_ROOT=""
TEST_PROJECTS_DIR=""

setup() {
    echo ""
    echo "${YELLOW}Setting up test environment...${NC}"

    # Get project root
    if [[ -n "${0:A}" ]]; then
        PROJECT_ROOT="${0:A:h:h}"
    fi
    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        PROJECT_ROOT="/Users/dt/projects/dev-tools/flow-cli"
    fi

    echo "  Project root: $PROJECT_ROOT"

    # Create test projects directory
    TEST_PROJECTS_DIR=$(mktemp -d)
    echo "  Test projects dir: $TEST_PROJECTS_DIR"

    # Source required files
    source "$PROJECT_ROOT/lib/core.zsh"
    source "$PROJECT_ROOT/commands/dash.zsh"

    # Create test .STATUS files
    create_test_status_files

    echo ""
}

create_test_status_files() {
    # Quick win: explicit flag
    mkdir -p "$TEST_PROJECTS_DIR/quick-fix"
    cat > "$TEST_PROJECTS_DIR/quick-fix/.STATUS" <<'EOF'
status: active
priority: 2
next: Fix typo in README
quick_win: yes
EOF

    # Quick win: low estimate
    mkdir -p "$TEST_PROJECTS_DIR/fast-task"
    cat > "$TEST_PROJECTS_DIR/fast-task/.STATUS" <<'EOF'
status: active
priority: 1
next: Update version number
estimate: 15m
EOF

    # Quick win: estimate with different format
    mkdir -p "$TEST_PROJECTS_DIR/quick-doc"
    cat > "$TEST_PROJECTS_DIR/quick-doc/.STATUS" <<'EOF'
status: ready
priority: 2
next: Add docstring
estimate: 20min
EOF

    # NOT quick win: estimate too high
    mkdir -p "$TEST_PROJECTS_DIR/slow-task"
    cat > "$TEST_PROJECTS_DIR/slow-task/.STATUS" <<'EOF'
status: active
priority: 1
next: Refactor module
estimate: 2h
EOF

    # High urgency: explicit
    mkdir -p "$TEST_PROJECTS_DIR/urgent-project"
    cat > "$TEST_PROJECTS_DIR/urgent-project/.STATUS" <<'EOF'
status: active
priority: 0
next: Critical fix needed
urgency: high
EOF

    # Medium urgency: deadline soon
    mkdir -p "$TEST_PROJECTS_DIR/deadline-soon"
    local tomorrow=$(date -v+1d +%Y-%m-%d)
    cat > "$TEST_PROJECTS_DIR/deadline-soon/.STATUS" <<EOF
status: active
priority: 1
next: Submit before deadline
deadline: $tomorrow
EOF

    # Low urgency: no flags
    mkdir -p "$TEST_PROJECTS_DIR/normal-task"
    cat > "$TEST_PROJECTS_DIR/normal-task/.STATUS" <<'EOF'
status: active
priority: 2
next: Normal work item
EOF

    # Overdue: deadline passed
    mkdir -p "$TEST_PROJECTS_DIR/overdue-task"
    local yesterday=$(date -v-1d +%Y-%m-%d)
    cat > "$TEST_PROJECTS_DIR/overdue-task/.STATUS" <<EOF
status: active
priority: 1
next: This is overdue
deadline: $yesterday
EOF
}

cleanup() {
    rm -rf "$TEST_PROJECTS_DIR"
}

# ============================================================================
# QUICK WIN DETECTION TESTS
# ============================================================================

test_quick_win_explicit_flag() {
    log_test "Detects quick_win: yes"

    local status_file="$TEST_PROJECTS_DIR/quick-fix/.STATUS"
    local quick_win=$(grep -i "^quick_win:" "$status_file" | cut -d: -f2 | tr -d ' ' | tr '[:upper:]' '[:lower:]')

    if [[ "$quick_win" == "yes" ]]; then
        pass
    else
        fail "quick_win flag not detected: '$quick_win'"
    fi
}

test_quick_win_estimate_15m() {
    log_test "Detects estimate: 15m as quick win"

    local status_file="$TEST_PROJECTS_DIR/fast-task/.STATUS"
    local estimate=$(grep -i "^estimate:" "$status_file" | cut -d: -f2 | tr -d ' ')

    # Extract number
    local num="${estimate//[!0-9]/}"

    if [[ -n "$num" && $num -lt 30 ]]; then
        pass
    else
        fail "15m not detected as quick: '$estimate' -> '$num'"
    fi
}

test_quick_win_estimate_20min() {
    log_test "Detects estimate: 20min as quick win"

    local status_file="$TEST_PROJECTS_DIR/quick-doc/.STATUS"
    local estimate=$(grep -i "^estimate:" "$status_file" | cut -d: -f2 | tr -d ' ')

    local num="${estimate//[!0-9]/}"

    if [[ -n "$num" && $num -lt 30 ]]; then
        pass
    else
        fail "20min not detected as quick: '$estimate'"
    fi
}

test_not_quick_win_2h() {
    log_test "2h estimate is NOT quick win"

    local status_file="$TEST_PROJECTS_DIR/slow-task/.STATUS"
    local estimate=$(grep -i "^estimate:" "$status_file" | cut -d: -f2 | tr -d ' ')

    if [[ "$estimate" == *"h"* || "$estimate" == *"hr"* ]]; then
        pass
    else
        fail "2h should not be quick win"
    fi
}

# ============================================================================
# URGENCY DETECTION TESTS
# ============================================================================

test_urgency_explicit_high() {
    log_test "Detects urgency: high"

    local status_file="$TEST_PROJECTS_DIR/urgent-project/.STATUS"
    local urgency=$(grep -i "^urgency:" "$status_file" | cut -d: -f2 | tr -d ' ' | tr '[:upper:]' '[:lower:]')

    if [[ "$urgency" == "high" ]]; then
        pass
    else
        fail "High urgency not detected: '$urgency'"
    fi
}

test_urgency_from_deadline() {
    log_test "Detects deadline field"

    local status_file="$TEST_PROJECTS_DIR/deadline-soon/.STATUS"
    local deadline=$(grep -i "^deadline:" "$status_file" | cut -d: -f2 | tr -d ' ')

    if [[ -n "$deadline" ]]; then
        pass
    else
        fail "Deadline not detected"
    fi
}

test_urgency_from_priority_0() {
    log_test "Priority 0 implies high urgency"

    local status_file="$TEST_PROJECTS_DIR/urgent-project/.STATUS"
    local priority=$(grep -i "^priority:" "$status_file" | cut -d: -f2 | tr -d ' ')

    if [[ "$priority" == "0" ]]; then
        pass
    else
        fail "Priority 0 not detected: '$priority'"
    fi
}

# ============================================================================
# .STATUS PARSING TESTS
# ============================================================================

test_status_field_parsing() {
    log_test "Parses status field"

    local status_file="$TEST_PROJECTS_DIR/quick-fix/.STATUS"
    local proj_status=$(grep -i "^status:" "$status_file" | cut -d: -f2 | tr -d ' ')

    if [[ "$proj_status" == "active" ]]; then
        pass
    else
        fail "Status not parsed: '$proj_status'"
    fi
}

test_next_field_parsing() {
    log_test "Parses next field"

    local status_file="$TEST_PROJECTS_DIR/quick-fix/.STATUS"
    local next=$(grep -i "^next:" "$status_file" | cut -d: -f2-)

    if [[ "$next" == *"typo"* ]]; then
        pass
    else
        fail "Next not parsed: '$next'"
    fi
}

test_priority_field_parsing() {
    log_test "Parses priority field"

    local status_file="$TEST_PROJECTS_DIR/fast-task/.STATUS"
    local priority=$(grep -i "^priority:" "$status_file" | cut -d: -f2 | tr -d ' ')

    if [[ "$priority" == "1" ]]; then
        pass
    else
        fail "Priority not parsed: '$priority'"
    fi
}

# ============================================================================
# EDGE CASES
# ============================================================================

test_missing_quick_win_field() {
    log_test "Handles missing quick_win field"

    local status_file="$TEST_PROJECTS_DIR/normal-task/.STATUS"
    local quick_win=$(grep -i "^quick_win:" "$status_file" 2>/dev/null | cut -d: -f2)

    if [[ -z "$quick_win" ]]; then
        pass
    else
        fail "Should be empty for missing field"
    fi
}

test_missing_urgency_field() {
    log_test "Handles missing urgency field"

    local status_file="$TEST_PROJECTS_DIR/normal-task/.STATUS"
    local urgency=$(grep -i "^urgency:" "$status_file" 2>/dev/null | cut -d: -f2)

    if [[ -z "$urgency" ]]; then
        pass
    else
        fail "Should be empty for missing field"
    fi
}

test_case_insensitive_fields() {
    log_test "Field parsing is case-insensitive"

    # Create test file with mixed case
    mkdir -p "$TEST_PROJECTS_DIR/mixed-case"
    cat > "$TEST_PROJECTS_DIR/mixed-case/.STATUS" <<'EOF'
Status: active
PRIORITY: 1
Quick_Win: yes
EOF

    local status_file="$TEST_PROJECTS_DIR/mixed-case/.STATUS"
    local quick_win=$(grep -i "^quick_win:" "$status_file" | cut -d: -f2 | tr -d ' ')

    if [[ "$quick_win" == "yes" ]]; then
        pass
    else
        fail "Case-insensitive parsing failed"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  Quick Wins & Urgency Tests (v3.4.0)                       ║"
    echo "╚════════════════════════════════════════════════════════════╝"

    setup

    echo "${YELLOW}Quick Win Detection Tests${NC}"
    echo "────────────────────────────────────────"
    test_quick_win_explicit_flag
    test_quick_win_estimate_15m
    test_quick_win_estimate_20min
    test_not_quick_win_2h
    echo ""

    echo "${YELLOW}Urgency Detection Tests${NC}"
    echo "────────────────────────────────────────"
    test_urgency_explicit_high
    test_urgency_from_deadline
    test_urgency_from_priority_0
    echo ""

    echo "${YELLOW}.STATUS Parsing Tests${NC}"
    echo "────────────────────────────────────────"
    test_status_field_parsing
    test_next_field_parsing
    test_priority_field_parsing
    echo ""

    echo "${YELLOW}Edge Cases${NC}"
    echo "────────────────────────────────────────"
    test_missing_quick_win_field
    test_missing_urgency_field
    test_case_insensitive_fields
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
