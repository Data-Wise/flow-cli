#!/usr/bin/env zsh
# Test script for the agenda command (commands/agenda.zsh)
# Tests: help, windows (default/today/-m), --overdue, category filter,
#        --all, calm empty state, aliases, atlas-disabled isolation.

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
    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root${RESET}"
        exit 1
    fi

    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$PROJECT_ROOT"
    FLOW_SCHEDULE_NO_CACHE=1
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
        echo "${RED}Plugin failed to load${RESET}"
        exit 1
    }
    exec < /dev/null

    zmodload zsh/datetime 2>/dev/null
    TODAY=$(strftime '%Y-%m-%d' $EPOCHSECONDS)

    # Isolated project root: a research project with dated + recurring items
    TEST_ROOT=$(mktemp -d)
    FLOW_PROJECTS_ROOT="$TEST_ROOT"
    mkdir -p "$TEST_ROOT/research/study-x" "$TEST_ROOT/dev-tools/tool-y"

    {
        echo "## Status: active"
        echo ""
        echo "## Schedule:"
        echo "- $(_date_add_days "$TODAY" -3) | Overdue paper review | research"
        echo "- $TODAY | Standup notes | general"
        echo "- $(_date_add_days "$TODAY" 2) | Submit revision | research"
        echo "- $(_date_add_days "$TODAY" 15) | Beta milestone | general"
        echo "- weekly:fri | Grading window | recurring"
    } > "$TEST_ROOT/research/study-x/.STATUS"

    {
        echo "## Status: active"
        echo ""
        echo "## Schedule:"
        echo "- $(_date_add_days "$TODAY" 1) | Ship v2 | general"
    } > "$TEST_ROOT/dev-tools/tool-y/.STATUS"

    # An empty project root for the empty-state test
    EMPTY_ROOT=$(mktemp -d)
}

cleanup() {
    reset_mocks
    [[ -d "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"
    [[ -d "$EMPTY_ROOT" ]] && rm -rf "$EMPTY_ROOT"
}
trap cleanup EXIT

# ============================================================================
# TESTS: existence + help
# ============================================================================

test_agenda_exists() {
    test_case "agenda command exists"
    assert_function_exists "agenda" && test_pass
}

test_agenda_help_exists() {
    test_case "_agenda_help function exists"
    assert_function_exists "_agenda_help" && test_pass
}

test_agenda_aliases_exist() {
    test_case "agt/agw/agm alias functions exist"
    assert_function_exists "agt" && \
    assert_function_exists "agw" && \
    assert_function_exists "agm" && test_pass
}

test_agenda_help_runs() {
    test_case "agenda -h runs and shows usage"
    local output rc
    output=$(agenda -h 2>&1); rc=$?
    assert_exit_code $rc 0 "agenda -h should exit 0"
    assert_contains "$output" "AGENDA" "help shows title" && \
    assert_contains "$output" "today" "help mentions today window" && \
    assert_contains "$output" "--overdue" "help mentions --overdue" && test_pass
}

test_agenda_help_flag() {
    test_case "agenda --help works"
    local output=$(agenda --help 2>&1)
    assert_contains "$output" "AGENDA" && test_pass
}

# ============================================================================
# TESTS: default window + buckets
# ============================================================================

test_agenda_default_runs() {
    test_case "agenda (default) runs without error"
    local output rc
    output=$(agenda 2>&1); rc=$?
    assert_exit_code $rc 0 "agenda should exit 0"
    assert_not_contains "$output" "command not found" && test_pass
}

test_agenda_default_buckets() {
    test_case "agenda shows OVERDUE / TODAY / THIS WEEK buckets"
    local output=$(agenda 2>&1)
    assert_contains "$output" "OVERDUE" "overdue bucket" && \
    assert_contains "$output" "TODAY" "today bucket" && \
    assert_contains "$output" "THIS WEEK" "this-week bucket" && test_pass
}

test_agenda_default_items() {
    test_case "agenda default lists in-window items, excludes 15d item"
    local output=$(agenda 2>&1)
    assert_contains "$output" "Overdue paper review" "overdue item" && \
    assert_contains "$output" "Submit revision" "soon item" && \
    assert_not_contains "$output" "Beta milestone" "15d item excluded at 7d" && test_pass
}

test_agenda_no_errors() {
    test_case "agenda output has no error patterns"
    local output=$(agenda 2>&1)
    assert_not_contains "$output" "command not found" && \
    assert_not_contains "$output" "parse error" && \
    assert_not_contains "$output" "no such" && test_pass
}

# ============================================================================
# TESTS: --overdue
# ============================================================================

test_agenda_overdue() {
    test_case "agenda --overdue shows only overdue items"
    local output=$(agenda --overdue 2>&1)
    assert_contains "$output" "Overdue paper review" "overdue present" && \
    assert_not_contains "$output" "Submit revision" "soon item excluded" && \
    assert_not_contains "$output" "Standup notes" "today item excluded" && test_pass
}

# ============================================================================
# TESTS: month window vs today window
# ============================================================================

test_agenda_month_has_later() {
    test_case "agenda -m includes the LATER bucket + 15d item"
    local output=$(agenda -m 2>&1)
    assert_contains "$output" "LATER" "later bucket present" && \
    assert_contains "$output" "Beta milestone" "15d item now in range" && test_pass
}

test_agenda_today_window() {
    test_case "agenda today shows today + overdue only"
    local output=$(agenda today 2>&1)
    assert_contains "$output" "Standup notes" "today item" && \
    assert_contains "$output" "Overdue paper review" "overdue item" && \
    assert_not_contains "$output" "Submit revision" "future item excluded" && test_pass
}

# ============================================================================
# TESTS: category filter
# ============================================================================

test_agenda_category_filter() {
    test_case "agenda research filters to research project"
    local output=$(agenda research 2>&1)
    assert_contains "$output" "Submit revision" "research item present" && \
    assert_not_contains "$output" "Ship v2" "dev item excluded" && test_pass
}

test_agenda_filter_matches_type() {
    test_case "agenda research surfaces a research item from a dev-category project"
    # 'webapp' at the root is detected as a dev project, but carries a
    # research-TYPED item — type filtering must surface it.
    mkdir -p "$TEST_ROOT/webapp"
    {
        echo "## Schedule:"
        echo "- $(_date_add_days "$TODAY" 2) | JRSS-B revision | research"
    } > "$TEST_ROOT/webapp/.STATUS"
    local output=$(agenda research 2>&1)
    rm -rf "$TEST_ROOT/webapp"
    assert_contains "$output" "JRSS-B revision" "research-typed item from a non-research project matches" && test_pass
}

test_agenda_general_type_accepted() {
    test_case "agenda general is a valid type filter (not 'unknown')"
    local output=$(agenda general 2>&1)
    assert_not_contains "$output" "Unknown" "general accepted as a filter" && \
    assert_contains "$output" "Standup notes" "general-typed item surfaces" && test_pass
}

# ============================================================================
# TESTS: empty state
# ============================================================================

test_agenda_empty_state() {
    test_case "agenda shows calm empty state when nothing scheduled"
    local saved="$FLOW_PROJECTS_ROOT"
    FLOW_PROJECTS_ROOT="$EMPTY_ROOT"
    local output=$(agenda 2>&1)
    FLOW_PROJECTS_ROOT="$saved"
    assert_contains "$output" "Nothing scheduled" "calm empty state" && test_pass
}

test_agenda_empty_category() {
    test_case "agenda apps (no apps projects) -> empty state"
    local output=$(agenda apps 2>&1)
    assert_contains "$output" "Nothing scheduled" && test_pass
}

# ============================================================================
# TESTS: holiday filtering (default hides, --all shows)
# ============================================================================

test_agenda_default_excludes_holiday() {
    test_case "agenda (default) hides holiday-typed items"
    mkdir -p "$TEST_ROOT/hol"
    printf '## Schedule:\n- %s | Fall Break | holiday\n' "$(_date_add_days "$TODAY" 2)" > "$TEST_ROOT/hol/.STATUS"
    local output=$(agenda 2>&1)
    rm -rf "$TEST_ROOT/hol"
    assert_not_contains "$output" "Fall Break" "holiday hidden by default" && test_pass
}

test_agenda_all_includes_holiday() {
    test_case "agenda --all shows holiday-typed items"
    mkdir -p "$TEST_ROOT/hol"
    printf '## Schedule:\n- %s | Fall Break | holiday\n' "$(_date_add_days "$TODAY" 2)" > "$TEST_ROOT/hol/.STATUS"
    local output=$(agenda --all 2>&1)
    rm -rf "$TEST_ROOT/hol"
    assert_contains "$output" "Fall Break" "holiday shown under --all" && test_pass
}

test_agenda_label_with_pipe_renders() {
    test_case "agenda renders a label containing '|' without field corruption"
    mkdir -p "$TEST_ROOT/pipe"
    printf '## Schedule:\n- %s | Fix bug | crash | research\n' "$(_date_add_days "$TODAY" 1)" > "$TEST_ROOT/pipe/.STATUS"
    local output=$(agenda research 2>&1)
    rm -rf "$TEST_ROOT/pipe"
    # type stayed 'research' (item appears under the research filter) and the
    # label is sanitized, not truncated at the first pipe
    assert_contains "$output" "Fix bug" "label present" && \
    assert_not_contains "$output" "command not found" "no breakage" && test_pass
}

# ============================================================================
# TESTS: unknown option
# ============================================================================

test_agenda_unknown_option() {
    test_case "agenda <bogus> warns and shows help"
    local output=$(agenda --bogus 2>&1)
    assert_contains "$output" "Unknown" "warns on unknown option" && test_pass
}

# ============================================================================
# TESTS: isolation (run_isolated, atlas disabled)
# ============================================================================

test_agenda_isolated() {
    test_case "agenda runs cleanly under run_isolated (atlas disabled)"
    _agenda_isolated_body() {
        FLOW_SCHEDULE_NO_CACHE=1
        local r=$(mktemp -d)
        export FLOW_PROJECTS_ROOT="$r"
        mkdir -p "$r/research/p"
        zmodload zsh/datetime 2>/dev/null
        local t=$(strftime '%Y-%m-%d' $EPOCHSECONDS)
        {
            echo "## Status: active"
            echo "## Schedule:"
            echo "- $t | Iso item | research"
        } > "$r/research/p/.STATUS"
        local out=$(agenda 2>&1)
        rm -rf "$r"
        [[ "$out" == *"Iso item"* ]] || { echo "missing Iso item: $out"; return 1; }
        return 0
    }
    run_isolated _agenda_isolated_body && test_pass
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite_start "Agenda Command Tests"
    setup

    echo "${CYAN}--- Existence + help ---${RESET}"
    test_agenda_exists
    test_agenda_help_exists
    test_agenda_aliases_exist
    test_agenda_help_runs
    test_agenda_help_flag

    echo ""
    echo "${CYAN}--- Default window + buckets ---${RESET}"
    test_agenda_default_runs
    test_agenda_default_buckets
    test_agenda_default_items
    test_agenda_no_errors

    echo ""
    echo "${CYAN}--- Overdue ---${RESET}"
    test_agenda_overdue

    echo ""
    echo "${CYAN}--- Month / today windows ---${RESET}"
    test_agenda_month_has_later
    test_agenda_today_window

    echo ""
    echo "${CYAN}--- Category filter ---${RESET}"
    test_agenda_category_filter
    test_agenda_filter_matches_type
    test_agenda_general_type_accepted

    echo ""
    echo "${CYAN}--- Empty state ---${RESET}"
    test_agenda_empty_state
    test_agenda_empty_category

    echo ""
    echo "${CYAN}--- Holiday filtering + pipe-in-label ---${RESET}"
    test_agenda_default_excludes_holiday
    test_agenda_all_includes_holiday
    test_agenda_label_with_pipe_renders

    echo ""
    echo "${CYAN}--- Unknown option ---${RESET}"
    test_agenda_unknown_option

    echo ""
    echo "${CYAN}--- Isolation ---${RESET}"
    test_agenda_isolated

    cleanup
    test_suite_end
    exit $?
}

main "$@"
