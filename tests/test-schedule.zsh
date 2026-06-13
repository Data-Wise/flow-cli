#!/usr/bin/env zsh
# Test script for the schedule engine (lib/schedule.zsh)
# Tests: classification, relative days, .STATUS parsing, teach items,
#        recurrence expansion (incl. month/year boundaries), window filter,
#        no-yq fallback, atlas-absent no-op.

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

    # Isolated project root with a research project that has a ## Schedule: block
    TEST_ROOT=$(mktemp -d)
    mkdir -p "$TEST_ROOT/research/mock-study"
    FLOW_PROJECTS_ROOT="$TEST_ROOT"

    # Pin "today" reference for date-sensitive assertions
    zmodload zsh/datetime 2>/dev/null
    TODAY=$(strftime '%Y-%m-%d' $EPOCHSECONDS)
    PAST=$(_date_add_days "$TODAY" -2)
    SOON=$(_date_add_days "$TODAY" 3)
    FAR=$(_date_add_days "$TODAY" 20)

    cat > "$TEST_ROOT/research/mock-study/.STATUS" <<EOF
## Status: active
## Focus: writing

## Schedule:
- $PAST | Overdue manuscript task | research
- $TODAY | Due today item | research
- $SOON | Submit revision | research
- $FAR | Beta milestone | general
- weekly:fri | Grading window | recurring
- garbage line that should be ignored
- not-a-date | still ignored | general

## Notes:
- this is not a schedule item
EOF
    STATUS_FILE="$TEST_ROOT/research/mock-study/.STATUS"
}

cleanup() {
    reset_mocks
    [[ -d "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

# ============================================================================
# TESTS: module loading + constants
# ============================================================================

test_engine_loaded() {
    test_case "schedule engine module guard set"
    assert_equals "$_FLOW_SCHEDULE_LOADED" "1" "_FLOW_SCHEDULE_LOADED should be 1" && test_pass
}

test_default_window() {
    test_case "SCHEDULE_DEFAULT_WINDOW is 7"
    assert_equals "$SCHEDULE_DEFAULT_WINDOW" "7" "default window should be 7" && test_pass
}

test_functions_exist() {
    test_case "core engine functions exist"
    assert_function_exists "_schedule_classify" && \
    assert_function_exists "_schedule_relative_days" && \
    assert_function_exists "_schedule_parse_status" && \
    assert_function_exists "_schedule_teach_items" && \
    assert_function_exists "_schedule_expand_recurring" && \
    assert_function_exists "_schedule_collect" && \
    assert_function_exists "_schedule_filter_window" && \
    assert_function_exists "_schedule_sort" && \
    assert_function_exists "_schedule_render_line" && \
    assert_function_exists "_flow_schedule_to_atlas" && test_pass
}

# ============================================================================
# TESTS: classification (frozen "today" arg)
# ============================================================================

test_classify_overdue() {
    test_case "classify past date -> overdue"
    assert_equals "$(_schedule_classify "$PAST" 7)" "overdue" && test_pass
}

test_classify_today() {
    test_case "classify today -> today"
    assert_equals "$(_schedule_classify "$TODAY" 7)" "today" && test_pass
}

test_classify_soon() {
    test_case "classify in-window date -> soon"
    assert_equals "$(_schedule_classify "$SOON" 7)" "soon" && test_pass
}

test_classify_later() {
    test_case "classify beyond-window date -> later"
    assert_equals "$(_schedule_classify "$FAR" 7)" "later" && test_pass
}

test_classify_boundary() {
    test_case "classify exactly at window edge -> soon (inclusive)"
    local edge=$(_date_add_days "$TODAY" 7)
    assert_equals "$(_schedule_classify "$edge" 7)" "soon" && test_pass
}

# ============================================================================
# TESTS: relative days
# ============================================================================

test_relative_today() {
    test_case "relative days: today"
    assert_equals "$(_schedule_relative_days "$TODAY")" "today" && test_pass
}

test_relative_future() {
    test_case "relative days: in 3d"
    assert_equals "$(_schedule_relative_days "$SOON")" "in 3d" && test_pass
}

test_relative_overdue() {
    test_case "relative days: overdue 2d"
    assert_equals "$(_schedule_relative_days "$PAST")" "overdue 2d" && test_pass
}

# ============================================================================
# TESTS: .STATUS parsing
# ============================================================================

test_parse_status_count() {
    test_case "parse_status emits 5 records (4 ISO + 1 recurring)"
    local out=$(_schedule_parse_status "$STATUS_FILE")
    local n=$(print -r -- "$out" | grep -c .)
    assert_equals "$n" "5" "should parse exactly 5 records, got $n" && test_pass
}

test_parse_status_infers_project() {
    test_case "parse_status infers project from path"
    local out=$(_schedule_parse_status "$STATUS_FILE")
    assert_contains "$out" "|mock-study|" "project should be mock-study" && test_pass
}

test_parse_status_recurring_empty_date() {
    test_case "parse_status emits recurring with empty date + recurrence token"
    local out=$(_schedule_parse_status "$STATUS_FILE")
    assert_contains "$out" "|Grading window|recurring|mock-study|weekly:fri|status" && test_pass
}

test_parse_status_default_type() {
    test_case "parse_status defaults ISO type to general when omitted"
    # (mock-study has explicit types; test the default via a temp file)
    local tmp=$(mktemp -d)/.STATUS
    printf '## Schedule:\n- 2030-01-01 | Untyped item\n' > "$tmp"
    local out=$(_schedule_parse_status "$tmp")
    assert_contains "$out" "2030-01-01|Untyped item|general|" && test_pass
}

test_parse_status_empty_file() {
    test_case "parse_status on missing file -> no crash, no output"
    local out=$(_schedule_parse_status "/nonexistent/.STATUS" 2>&1)
    assert_empty "$out" "should produce no output" && test_pass
}

test_parse_status_no_section() {
    test_case "parse_status with no Schedule section -> empty"
    local tmp=$(mktemp -d)/.STATUS
    printf '## Status: active\n## Focus: x\n' > "$tmp"
    local out=$(_schedule_parse_status "$tmp")
    assert_empty "$out" "no schedule section should yield nothing" && test_pass
}

test_parse_status_pipe_in_label() {
    test_case "parse_status keeps a well-formed record when the label contains '|'"
    local tmp=$(mktemp -d)/.STATUS
    printf '## Schedule:\n- 2030-02-02 | Submit A|B revision | research\n' > "$tmp"
    local out=$(_schedule_parse_status "$tmp")
    local nf=$(print -r -- "$out" | awk -F'|' '{print NF}')
    local typ=$(print -r -- "$out" | awk -F'|' '{print $3}')
    assert_equals "$nf" "6" "record must stay 6 fields despite pipe in label (got $nf)" && \
    assert_equals "$typ" "research" "type must be research, not corrupted (got '$typ')" && \
    assert_contains "$out" "Submit A/B revision" "inner pipe sanitized to '/'" && test_pass
}

# ============================================================================
# TESTS: recurrence expansion (month + year boundaries)
# ============================================================================

test_expand_basic() {
    test_case "expand weekly:fri yields Fridays in range"
    # 2026-06-01 is a Monday; first Friday is 2026-06-05
    local out=$(_schedule_expand_recurring "weekly:fri" "2026-06-01" "2026-06-30")
    assert_contains "$out" "2026-06-05" "first Friday" && \
    assert_contains "$out" "2026-06-12" "second Friday" && \
    assert_contains "$out" "2026-06-26" "last Friday in June" && test_pass
}

test_expand_month_boundary() {
    test_case "expand crosses month boundary"
    local out=$(_schedule_expand_recurring "weekly:wed" "2026-06-28" "2026-07-10")
    # Wednesdays: 2026-07-01, 2026-07-08
    assert_contains "$out" "2026-07-01" "Wed after month change" && \
    assert_contains "$out" "2026-07-08" "next Wed" && test_pass
}

test_expand_year_boundary() {
    test_case "expand crosses year boundary"
    local out=$(_schedule_expand_recurring "weekly:thu" "2026-12-28" "2027-01-10")
    # Thursdays: 2026-12-31, 2027-01-07
    assert_contains "$out" "2026-12-31" "Thu in Dec" && \
    assert_contains "$out" "2027-01-07" "Thu in Jan next year" && test_pass
}

test_expand_unknown_dow() {
    test_case "expand unknown weekday -> no output"
    local out=$(_schedule_expand_recurring "weekly:funday" "2026-06-01" "2026-06-30")
    assert_empty "$out" "unknown dow should produce nothing" && test_pass
}

# ============================================================================
# TESTS: collection + window filter
# ============================================================================

test_collect_runs() {
    test_case "collect runs and includes overdue + soon items"
    local out=$(_schedule_collect 7)
    assert_contains "$out" "Overdue manuscript task" && \
    assert_contains "$out" "Submit revision" && test_pass
}

test_collect_expands_recurring() {
    test_case "collect expands recurring into concrete dates"
    local out=$(_schedule_collect 7)
    # recurring grading window should appear with a concrete ISO date prefix
    assert_contains "$out" "Grading window" "recurring item present" && \
    assert_contains "$out" "weekly:fri" "recurrence token preserved" && test_pass
}

test_collect_category_filter() {
    test_case "collect honors category filter (dev finds nothing here)"
    local out=$(_schedule_collect 7 dev)
    assert_empty "$out" "no dev-category projects -> empty" && test_pass
}

test_collect_category_by_type() {
    test_case "category filter matches record TYPE across project categories"
    # 'webapp' lives at the root -> detected category 'dev', but it carries a
    # research-TYPED schedule item. Filtering by 'research' must surface it.
    mkdir -p "$TEST_ROOT/webapp"
    cat > "$TEST_ROOT/webapp/.STATUS" <<EOF
## Schedule:
- $SOON | JRSS-B revision | research
EOF
    local out=$(_schedule_collect 30 research)
    rm -rf "$TEST_ROOT/webapp"
    assert_contains "$out" "JRSS-B revision" "research item in a dev-category project matches 'research'" && \
    assert_contains "$out" "Submit revision" "research items in a research-category project still match" && test_pass
}

test_collect_category_type_precision() {
    test_case "category filter excludes records of other types"
    local out=$(_schedule_collect 30 general)
    assert_contains "$out" "Beta milestone" "general-typed item matches 'general'" && \
    assert_not_contains "$out" "Submit revision" "research-typed item excluded from 'general'" && test_pass
}

test_collect_category_teach_synonym() {
    test_case "category 'teach' matches record type 'teaching' (synonym)"
    mkdir -p "$TEST_ROOT/webapp2"
    cat > "$TEST_ROOT/webapp2/.STATUS" <<EOF
## Schedule:
- $SOON | Lecture 5 prep | teaching
EOF
    local out=$(_schedule_collect 30 teach)
    rm -rf "$TEST_ROOT/webapp2"
    assert_contains "$out" "Lecture 5 prep" "teaching-typed item matches 'teach' synonym" && test_pass
}

test_drop_holidays_by_type_field() {
    test_case "drop_holidays filters the TYPE field, not a substring"
    # A general item whose LABEL is literally 'holiday' must survive; only
    # records TYPED holiday are dropped.
    local input="2030-01-01|holiday|general|p|none|status
2030-01-02|Fall break|holiday|p|none|status"
    local out=$(print -r -- "$input" | _schedule_drop_holidays)
    assert_contains "$out" "2030-01-01|holiday|general" "general item labeled 'holiday' kept" && \
    assert_not_contains "$out" "Fall break" "holiday-TYPED record dropped" && test_pass
}

test_collect_cache_keyed_on_root() {
    test_case "collect cache is keyed on FLOW_PROJECTS_ROOT (no cross-root leak)"
    local saved_nc="${FLOW_SCHEDULE_NO_CACHE:-}" saved_root="$FLOW_PROJECTS_ROOT"
    unset FLOW_SCHEDULE_NO_CACHE                       # enable caching
    _SCHEDULE_CACHE_KEY=""; _SCHEDULE_CACHE_RECORDS=""; _SCHEDULE_CACHE_TIME=0
    local r1=$(mktemp -d) r2=$(mktemp -d)
    local f1=$(mktemp) f2=$(mktemp)
    mkdir -p "$r1/a" "$r2/b"
    printf '## Schedule:\n- 2030-03-03 | Root1 item | general\n' > "$r1/a/.STATUS"
    printf '## Schedule:\n- 2030-03-03 | Root2 item | general\n' > "$r2/b/.STATUS"
    # Call with redirection (NOT $(...)) so the session cache persists in this
    # shell — that is what exposes a root-agnostic cache key.
    FLOW_PROJECTS_ROOT="$r1"; _schedule_collect 3650 > "$f1"
    FLOW_PROJECTS_ROOT="$r2"; _schedule_collect 3650 > "$f2"
    local out2=$(<"$f2")
    FLOW_PROJECTS_ROOT="$saved_root"
    [[ -n "$saved_nc" ]] && FLOW_SCHEDULE_NO_CACHE="$saved_nc"
    _SCHEDULE_CACHE_KEY=""; _SCHEDULE_CACHE_RECORDS=""; _SCHEDULE_CACHE_TIME=0
    rm -rf "$r1" "$r2" "$f1" "$f2"
    assert_contains "$out2" "Root2 item" "second root returns its own items" && \
    assert_not_contains "$out2" "Root1 item" "no stale cross-root cache leak" && test_pass
}

test_filter_window_drops_later() {
    test_case "filter_window drops beyond-window, keeps overdue"
    local out=$(_schedule_collect 30 | _schedule_filter_window 7)
    assert_contains "$out" "Overdue manuscript task" "overdue always kept" && \
    assert_not_contains "$out" "Beta milestone" "20d item dropped at window 7" && test_pass
}

test_filter_window_wide_keeps() {
    test_case "filter_window at 30d keeps the 20d item"
    local out=$(_schedule_collect 30 | _schedule_filter_window 30)
    assert_contains "$out" "Beta milestone" "20d item kept at window 30" && test_pass
}

test_sort_orders_by_date() {
    test_case "sort orders overdue before future"
    local out=$(_schedule_collect 30 | _schedule_filter_window 30 | _schedule_sort)
    local first=$(print -r -- "$out" | head -1)
    assert_contains "$first" "Overdue manuscript task" "earliest date first" && test_pass
}

# ============================================================================
# TESTS: render line
# ============================================================================

test_render_line() {
    test_case "render_line shows relative day, label, project"
    local out=$(_schedule_render_line "${TODAY}|Demo task|research|myproj|none|status")
    assert_contains "$out" "today" "relative day" && \
    assert_contains "$out" "Demo task" "label" && \
    assert_contains "$out" "myproj" "project" && test_pass
}

test_render_line_recurring_mark() {
    test_case "render_line flags recurrence for a non-recurring type"
    # A research weekly block keeps its 🔬 type icon + a trailing 🔁 marker.
    local out=$(_schedule_render_line "${TODAY}|Advisor meeting|research|myproj|weekly:mon|status")
    assert_contains "$out" "🔬" "type icon preserved" && \
    assert_contains "$out" "🔁" "recurrence marker present" && test_pass
}

# ============================================================================
# TESTS: teach items (yq-guarded) + no-yq fallback
# ============================================================================

test_teach_items_no_yq_fallback() {
    test_case "teach_items returns nothing without yq (graceful)"
    # Shadow yq with a command -v that fails: run in a subshell w/ PATH cleared
    local out=$(PATH="/nonexistent" _schedule_teach_items "/whatever/teach-config.yml" proj 2>&1)
    assert_empty "$out" "no yq + no file -> empty" && test_pass
}

test_teach_items_with_fixture() {
    test_case "teach_items parses fixture with weeks[].start_date"
    if ! command -v yq >/dev/null 2>&1; then
        test_skip "yq not installed"
        return
    fi
    local fixture="$PROJECT_ROOT/tests/fixtures/teach-config-scheduled.yml"
    if [[ ! -f "$fixture" ]]; then
        test_skip "fixture not present"
        return
    fi
    local out=$(_schedule_teach_items "$fixture" stat-202)
    assert_contains "$out" "|teaching|stat-202|none|teach-config" "teaching records emitted" && \
    assert_contains "$out" "Week 1" "week record present" && test_pass
}

# ============================================================================
# TESTS: atlas opportunistic push (absent -> no-op)
# ============================================================================

test_atlas_noop_when_absent() {
    test_case "atlas push is a no-op when atlas absent (async not called)"
    # FLOW_ATLAS_ENABLED=no => _flow_has_atlas false
    create_mock "_flow_atlas_async"
    _flow_schedule_to_atlas "${TODAY}|x|research|p|none|status"
    assert_mock_not_called "_flow_atlas_async" && test_pass
    reset_mocks
}

test_records_to_json_valid() {
    test_case "records_to_json escapes quotes/backslashes into valid JSON"
    local rec='2030-01-01|He said "hi" \ done|research|p|none|status'
    local json=$(_schedule_records_to_json "$rec")
    if command -v python3 >/dev/null 2>&1; then
        local ok=$(print -r -- "$json" | python3 -c 'import sys,json; json.load(sys.stdin); print("VALID")' 2>/dev/null)
        assert_equals "$ok" "VALID" "output must be parseable JSON (got: $json)" && \
        assert_contains "$json" '\"hi\"' "quotes escaped" && test_pass
    else
        assert_contains "$json" '\"hi\"' "quotes escaped" && \
        assert_contains "$json" '\\ done' "backslash escaped" && test_pass
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite_start "Schedule Engine Tests"
    setup

    echo "${CYAN}--- Module + constants ---${RESET}"
    test_engine_loaded
    test_default_window
    test_functions_exist

    echo ""
    echo "${CYAN}--- Classification ---${RESET}"
    test_classify_overdue
    test_classify_today
    test_classify_soon
    test_classify_later
    test_classify_boundary

    echo ""
    echo "${CYAN}--- Relative days ---${RESET}"
    test_relative_today
    test_relative_future
    test_relative_overdue

    echo ""
    echo "${CYAN}--- .STATUS parsing ---${RESET}"
    test_parse_status_count
    test_parse_status_infers_project
    test_parse_status_recurring_empty_date
    test_parse_status_default_type
    test_parse_status_empty_file
    test_parse_status_no_section
    test_parse_status_pipe_in_label

    echo ""
    echo "${CYAN}--- Recurrence expansion ---${RESET}"
    test_expand_basic
    test_expand_month_boundary
    test_expand_year_boundary
    test_expand_unknown_dow

    echo ""
    echo "${CYAN}--- Collection + window filter ---${RESET}"
    test_collect_runs
    test_collect_expands_recurring
    test_collect_category_filter
    test_collect_category_by_type
    test_collect_category_type_precision
    test_collect_category_teach_synonym
    test_drop_holidays_by_type_field
    test_collect_cache_keyed_on_root
    test_filter_window_drops_later
    test_filter_window_wide_keeps
    test_sort_orders_by_date

    echo ""
    echo "${CYAN}--- Render line ---${RESET}"
    test_render_line
    test_render_line_recurring_mark

    echo ""
    echo "${CYAN}--- Teach items + no-yq fallback ---${RESET}"
    test_teach_items_no_yq_fallback
    test_teach_items_with_fixture

    echo ""
    echo "${CYAN}--- Atlas opportunistic push ---${RESET}"
    test_atlas_noop_when_absent
    test_records_to_json_valid

    cleanup
    test_suite_end
    exit $?
}

main "$@"
