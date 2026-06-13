#!/usr/bin/env zsh
# Test script for schedule enrichment of the daily/weekly cadence commands
# (commands/morning.zsh): morning, morning -q, today, week.

# ============================================================================
# FRAMEWORK
# ============================================================================

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# ============================================================================
# SETUP
# ============================================================================

setup() {
    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$PROJECT_ROOT"
    FLOW_SCHEDULE_NO_CACHE=1
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
        echo "${RED}Plugin failed to load${RESET}"
        exit 1
    }
    exec < /dev/null

    # Isolate data dir (worklog) to keep dashboard/cadence output deterministic
    export FLOW_DATA_DIR=$(mktemp -d)

    zmodload zsh/datetime 2>/dev/null
    TODAY=$(strftime '%Y-%m-%d' $EPOCHSECONDS)

    TEST_ROOT=$(mktemp -d)
    FLOW_PROJECTS_ROOT="$TEST_ROOT"
    mkdir -p "$TEST_ROOT/research/study-x"
    {
        echo "## Status: active"
        echo "## Schedule:"
        echo "- $(_date_add_days "$TODAY" -2) | Late paper | research"
        echo "- $TODAY | Daily standup | general"
        echo "- $(_date_add_days "$TODAY" 3) | Submit revision | research"
    } > "$TEST_ROOT/research/study-x/.STATUS"

    EMPTY_ROOT=$(mktemp -d)
    mkdir -p "$EMPTY_ROOT/research/none"
    echo "## Status: active" > "$EMPTY_ROOT/research/none/.STATUS"
}

cleanup() {
    reset_mocks
    [[ -d "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"
    [[ -d "$EMPTY_ROOT" ]] && rm -rf "$EMPTY_ROOT"
    [[ -n "$FLOW_DATA_DIR" && -d "$FLOW_DATA_DIR" ]] && rm -rf "$FLOW_DATA_DIR"
}
trap cleanup EXIT

# ============================================================================
# TESTS: function existence
# ============================================================================

test_cadence_functions_exist() {
    test_case "cadence agenda helpers exist"
    assert_function_exists "_flow_morning_agenda" && \
    assert_function_exists "_flow_today_agenda" && \
    assert_function_exists "_flow_week_agenda" && \
    assert_function_exists "_flow_agenda_count" && test_pass
}

# ============================================================================
# TESTS: morning
# ============================================================================

test_morning_shows_upcoming() {
    test_case "morning shows the Upcoming block with dated items"
    local out=$(morning 2>&1)
    assert_contains "$out" "Upcoming" "upcoming header" && \
    assert_contains "$out" "Late paper" "overdue item" && \
    assert_contains "$out" "Submit revision" "soon item" && test_pass
}

test_morning_upcoming_suppresses() {
    test_case "morning Upcoming self-suppresses when nothing due"
    local saved="$FLOW_PROJECTS_ROOT"
    FLOW_PROJECTS_ROOT="$EMPTY_ROOT"
    local out=$(morning 2>&1)
    FLOW_PROJECTS_ROOT="$saved"
    assert_not_contains "$out" "Upcoming (next 7 days)" "no upcoming block" && test_pass
}

test_morning_quick_oneliner() {
    test_case "morning -q shows 'due soon' count"
    local out=$(morning -q 2>&1)
    assert_contains "$out" "due soon" "quick one-liner shows due count" && test_pass
}

# ============================================================================
# TESTS: today
# ============================================================================

test_today_due_today() {
    test_case "today shows 'Due today' with today + overdue items"
    local out=$(today 2>&1)
    assert_contains "$out" "Due today" "due-today header" && \
    assert_contains "$out" "Daily standup" "today item" && \
    assert_contains "$out" "Late paper" "overdue item" && \
    assert_not_contains "$out" "Submit revision" "future item excluded" && test_pass
}

# ============================================================================
# TESTS: week
# ============================================================================

test_week_deadlines() {
    test_case "week shows 'This week's deadlines' grouped by weekday"
    local out=$(week 2>&1)
    assert_contains "$out" "This week's deadlines" "deadlines header" && \
    assert_contains "$out" "Overdue:" "overdue group label" && \
    assert_contains "$out" "Submit revision" "in-window item" && test_pass
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite_start "Cadence Agenda Enrichment Tests"
    setup

    echo "${CYAN}--- Function existence ---${RESET}"
    test_cadence_functions_exist

    echo ""
    echo "${CYAN}--- morning ---${RESET}"
    test_morning_shows_upcoming
    test_morning_upcoming_suppresses
    test_morning_quick_oneliner

    echo ""
    echo "${CYAN}--- today ---${RESET}"
    test_today_due_today

    echo ""
    echo "${CYAN}--- week ---${RESET}"
    test_week_deadlines

    cleanup
    test_suite_end
    exit $?
}

main "$@"
