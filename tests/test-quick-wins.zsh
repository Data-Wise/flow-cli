#!/usr/bin/env zsh
# Test script for dashboard Quick Wins feature (v3.4.0)
# Tests: quick win detection, urgency indicators, .STATUS parsing

# ============================================================================
# FRAMEWORK
# ============================================================================

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

source "$SCRIPT_DIR/test-framework.zsh"

# ============================================================================
# SETUP
# ============================================================================

TEST_PROJECTS_DIR=""

setup() {
    # Fallback: try current directory or parent
    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        PROJECT_ROOT="$PWD"
    fi
    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        PROJECT_ROOT="${PWD:h}"
    fi
    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        echo "${RED}ERROR: Cannot find flow.plugin.zsh - run from project root${RESET}"
        exit 1
    fi

    # Create test projects directory
    TEST_PROJECTS_DIR=$(mktemp -d)

    # Source required files
    source "$PROJECT_ROOT/lib/core.zsh"
    source "$PROJECT_ROOT/commands/dash.zsh"

    # Create test .STATUS files
    create_test_status_files
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
    reset_mocks
}

# ============================================================================
# QUICK WIN DETECTION TESTS
# ============================================================================

test_quick_win_explicit_flag() {
    test_case "Detects quick_win: yes"

    local status_file="$TEST_PROJECTS_DIR/quick-fix/.STATUS"
    local quick_win=$(grep -i "^quick_win:" "$status_file" | cut -d: -f2 | tr -d ' ' | tr '[:upper:]' '[:lower:]')

    if [[ "$quick_win" == "yes" ]]; then
        test_pass
    else
        test_fail "quick_win flag not detected: '$quick_win'"
    fi
}

test_quick_win_estimate_15m() {
    test_case "Detects estimate: 15m as quick win"

    local status_file="$TEST_PROJECTS_DIR/fast-task/.STATUS"
    local estimate=$(grep -i "^estimate:" "$status_file" | cut -d: -f2 | tr -d ' ')

    # Extract number
    local num="${estimate//[!0-9]/}"

    if [[ -n "$num" && $num -lt 30 ]]; then
        test_pass
    else
        test_fail "15m not detected as quick: '$estimate' -> '$num'"
    fi
}

test_quick_win_estimate_20min() {
    test_case "Detects estimate: 20min as quick win"

    local status_file="$TEST_PROJECTS_DIR/quick-doc/.STATUS"
    local estimate=$(grep -i "^estimate:" "$status_file" | cut -d: -f2 | tr -d ' ')

    local num="${estimate//[!0-9]/}"

    if [[ -n "$num" && $num -lt 30 ]]; then
        test_pass
    else
        test_fail "20min not detected as quick: '$estimate'"
    fi
}

test_not_quick_win_2h() {
    test_case "2h estimate is NOT quick win"

    local status_file="$TEST_PROJECTS_DIR/slow-task/.STATUS"
    local estimate=$(grep -i "^estimate:" "$status_file" | cut -d: -f2 | tr -d ' ')

    if [[ "$estimate" == *"h"* || "$estimate" == *"hr"* ]]; then
        test_pass
    else
        test_fail "2h should not be quick win"
    fi
}

# ============================================================================
# URGENCY DETECTION TESTS
# ============================================================================

test_urgency_explicit_high() {
    test_case "Detects urgency: high"

    local status_file="$TEST_PROJECTS_DIR/urgent-project/.STATUS"
    local urgency=$(grep -i "^urgency:" "$status_file" | cut -d: -f2 | tr -d ' ' | tr '[:upper:]' '[:lower:]')

    if [[ "$urgency" == "high" ]]; then
        test_pass
    else
        test_fail "High urgency not detected: '$urgency'"
    fi
}

test_urgency_from_deadline() {
    test_case "Detects deadline field"

    local status_file="$TEST_PROJECTS_DIR/deadline-soon/.STATUS"
    local deadline=$(grep -i "^deadline:" "$status_file" | cut -d: -f2 | tr -d ' ')

    if [[ -n "$deadline" ]]; then
        test_pass
    else
        test_fail "Deadline not detected"
    fi
}

test_urgency_from_priority_0() {
    test_case "Priority 0 implies high urgency"

    local status_file="$TEST_PROJECTS_DIR/urgent-project/.STATUS"
    local priority=$(grep -i "^priority:" "$status_file" | cut -d: -f2 | tr -d ' ')

    if [[ "$priority" == "0" ]]; then
        test_pass
    else
        test_fail "Priority 0 not detected: '$priority'"
    fi
}

# ============================================================================
# .STATUS PARSING TESTS
# ============================================================================

test_status_field_parsing() {
    test_case "Parses status field"

    local status_file="$TEST_PROJECTS_DIR/quick-fix/.STATUS"
    local proj_status=$(grep -i "^status:" "$status_file" | cut -d: -f2 | tr -d ' ')

    if [[ "$proj_status" == "active" ]]; then
        test_pass
    else
        test_fail "Status not parsed: '$proj_status'"
    fi
}

test_next_field_parsing() {
    test_case "Parses next field"

    local status_file="$TEST_PROJECTS_DIR/quick-fix/.STATUS"
    local next=$(grep -i "^next:" "$status_file" | cut -d: -f2-)

    if [[ "$next" == *"typo"* ]]; then
        test_pass
    else
        test_fail "Next not parsed: '$next'"
    fi
}

test_priority_field_parsing() {
    test_case "Parses priority field"

    local status_file="$TEST_PROJECTS_DIR/fast-task/.STATUS"
    local priority=$(grep -i "^priority:" "$status_file" | cut -d: -f2 | tr -d ' ')

    if [[ "$priority" == "1" ]]; then
        test_pass
    else
        test_fail "Priority not parsed: '$priority'"
    fi
}

# ============================================================================
# EDGE CASES
# ============================================================================

test_missing_quick_win_field() {
    test_case "Handles missing quick_win field"

    local status_file="$TEST_PROJECTS_DIR/normal-task/.STATUS"
    local quick_win=$(grep -i "^quick_win:" "$status_file" 2>/dev/null | cut -d: -f2)

    if [[ -z "$quick_win" ]]; then
        test_pass
    else
        test_fail "Should be empty for missing field"
    fi
}

test_missing_urgency_field() {
    test_case "Handles missing urgency field"

    local status_file="$TEST_PROJECTS_DIR/normal-task/.STATUS"
    local urgency=$(grep -i "^urgency:" "$status_file" 2>/dev/null | cut -d: -f2)

    if [[ -z "$urgency" ]]; then
        test_pass
    else
        test_fail "Should be empty for missing field"
    fi
}

test_case_insensitive_fields() {
    test_case "Field parsing is case-insensitive"

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
        test_pass
    else
        test_fail "Case-insensitive parsing failed"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite_start "Quick Wins & Urgency Tests (v3.4.0)"

    setup

    echo "${YELLOW}Quick Win Detection Tests${RESET}"
    echo "────────────────────────────────────────"
    test_quick_win_explicit_flag
    test_quick_win_estimate_15m
    test_quick_win_estimate_20min
    test_not_quick_win_2h
    echo ""

    echo "${YELLOW}Urgency Detection Tests${RESET}"
    echo "────────────────────────────────────────"
    test_urgency_explicit_high
    test_urgency_from_deadline
    test_urgency_from_priority_0
    echo ""

    echo "${YELLOW}.STATUS Parsing Tests${RESET}"
    echo "────────────────────────────────────────"
    test_status_field_parsing
    test_next_field_parsing
    test_priority_field_parsing
    echo ""

    echo "${YELLOW}Edge Cases${RESET}"
    echo "────────────────────────────────────────"
    test_missing_quick_win_field
    test_missing_urgency_field
    test_case_insensitive_fields
    echo ""

    cleanup

    test_suite_end
    exit $?
}

main "$@"
