#!/usr/bin/env zsh
# tests/test-status-field-parity.zsh
# Characterization tests for the .STATUS field readers, SNAPSHOTTED BEFORE the
# Phase 1 shared-accessor refactor (SPEC-planning-coordination-2026-07-01
# §3.1, ORCHESTRATE-planning-coordination.md task 1.0).
#
# This suite locks down the CURRENT byte-exact output of:
#   - _dash_get_status_field / _dash_get_project_status / _dash_get_project_focus
#     / _dash_get_project_progress   (commands/dash.zsh)
#   - the inline greps in `morning` (commands/morning.zsh) and `next`
#     (commands/adhd.zsh)
#   - _flow_read_goal's inline daily_goal grep (commands/capture.zsh)
#   - _flow_where_fallback's inline Status/Focus greps (lib/atlas-bridge.zsh)
#
# It must be GREEN on today's code, before `_flow_status_field` exists. After
# the refactor migrates these call sites onto the shared accessor, this same
# suite must stay green (parity) — see task 1.7. The one sanctioned exception
# is `_flow_where_fallback`: it originally CRASHED on `local status=...`
# (`status` is a zsh read-only special variable, even as a function-local)
# and never printed Status:/Focus: at all. That crash was characterized first
# (see git history for `test_where_fallback_currently_crashes_on_status`),
# THEN updated to `test_where_fallback_status_and_focus_now_print` once the
# atlas-bridge.zsh:836 migration (task 1.5) fixed it as an unavoidable side
# effect of renaming the colliding local. This is a discovered bug fix, not a
# silent behavior-loss regression — flagged explicitly in the Phase 1 report
# rather than silently hiding the diff, per the "don't adjust the test"
# rule's one sanctioned exception.

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
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
        echo "${RED}Plugin failed to load${RESET}"
        exit 1
    }
    _flow_has_atlas() { return 1 }
    exec < /dev/null

    TEST_ROOT=$(mktemp -d)

    # proj1: the discriminating fixture — colon-in-value, % in a non-progress
    # field, markdown dialect.
    mkdir -p "$TEST_ROOT/proj1"
    cat > "$TEST_ROOT/proj1/.STATUS" <<'EOF'
## Status: active
## Focus: Fix: the bug at 80% coverage
## Progress: 42%
## Priority: P1
## daily_goal: 3
EOF

    # proj2: Focus missing -> _dash_get_project_focus falls back to "next"
    mkdir -p "$TEST_ROOT/proj2"
    printf "## Status: active\n## next: Write the tests\n" > "$TEST_ROOT/proj2/.STATUS"

    # proj3: Status value needing synonym normalization ("In Progress" -> "active")
    mkdir -p "$TEST_ROOT/proj3"
    printf "## Status: In Progress\n" > "$TEST_ROOT/proj3/.STATUS"

    # proj_yaml: YAML dialect (no "## " prefix) — only _dash_get_status_field
    # supports this today; the inline greps (morning/adhd/capture/atlas-bridge)
    # only match the markdown "## Field:" dialect.
    mkdir -p "$TEST_ROOT/proj_yaml"
    printf "status: active\npriority: 2\n" > "$TEST_ROOT/proj_yaml/.STATUS"

    # proj_nofocus: active, no Focus/Progress fields at all (missing-field case)
    mkdir -p "$TEST_ROOT/proj_nofocus"
    printf "## Status: active\n" > "$TEST_ROOT/proj_nofocus/.STATUS"

    # proj_where: fixture for the _flow_where_fallback crash characterization
    mkdir -p "$TEST_ROOT/proj_where"
    printf "## Status: active\n## Focus: Ship it\n" > "$TEST_ROOT/proj_where/.STATUS"

    # Separate, minimal root for `morning`/`next` command-level rendering
    # tests: both cap the visible project list (morning: top 5, next: top 3)
    # and filesystem readdir order is not alphabetical, so a 6-project root
    # can silently truncate proj1 out of view. Two projects keeps both
    # commands' rendering deterministic regardless of directory order.
    CMD_ROOT=$(mktemp -d)
    mkdir -p "$CMD_ROOT/proj1" "$CMD_ROOT/proj_nofocus"
    cp "$TEST_ROOT/proj1/.STATUS" "$CMD_ROOT/proj1/.STATUS"
    cp "$TEST_ROOT/proj_nofocus/.STATUS" "$CMD_ROOT/proj_nofocus/.STATUS"
}

cleanup() {
    reset_mocks
    unset -f _flow_has_atlas 2>/dev/null
    [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"
    [[ -n "$CMD_ROOT" && -d "$CMD_ROOT" ]] && rm -rf "$CMD_ROOT"
}
trap cleanup EXIT

# ============================================================================
# TESTS: _dash_get_status_field (commands/dash.zsh) — raw field reader
# ============================================================================

test_dash_field_colon_in_value() {
    test_case "_dash_get_status_field preserves a colon inside the value"
    local v=$(_dash_get_status_field "$TEST_ROOT/proj1/.STATUS" "Focus")
    assert_equals "$v" "Fix: the bug at 80% coverage" "colon-in-value focus" && test_pass
}

test_dash_field_percent_in_non_progress_field() {
    test_case "_dash_get_status_field does not touch a % inside Focus"
    local v=$(_dash_get_status_field "$TEST_ROOT/proj1/.STATUS" "Focus")
    assert_contains "$v" "80%" "% preserved in non-progress field" && test_pass
}

test_dash_field_progress_keeps_percent() {
    test_case "_dash_get_status_field('Progress') keeps the raw '%' (no strip in the reader itself)"
    local v=$(_dash_get_status_field "$TEST_ROOT/proj1/.STATUS" "Progress")
    assert_equals "$v" "42%" "raw Progress field value" && test_pass
}

test_dash_field_missing_returns_empty() {
    test_case "_dash_get_status_field returns empty for a missing field"
    local v=$(_dash_get_status_field "$TEST_ROOT/proj1/.STATUS" "NoSuchField")
    assert_empty "$v" "missing field -> empty" && test_pass
}

test_dash_field_yaml_dialect() {
    test_case "_dash_get_status_field matches the YAML-ish 'field:' dialect (no ##)"
    local v=$(_dash_get_status_field "$TEST_ROOT/proj_yaml/.STATUS" "status")
    assert_equals "$v" "active" "yaml dialect field read" && test_pass
}

# ============================================================================
# TESTS: dash.zsh wrapper functions (status/focus/progress)
# ============================================================================

test_dash_project_status() {
    test_case "_dash_get_project_status reads Status"
    local v=$(_dash_get_project_status "$TEST_ROOT/proj1/.STATUS")
    assert_equals "$v" "active" "project status" && test_pass
}

test_dash_project_status_missing_file() {
    test_case "_dash_get_project_status on a missing file returns empty"
    local v=$(_dash_get_project_status "$TEST_ROOT/does-not-exist/.STATUS")
    assert_empty "$v" "missing file -> empty status" && test_pass
}

test_dash_project_status_synonym_mapping() {
    test_case "_dash_get_project_status normalizes 'In Progress' -> 'active'"
    local v=$(_dash_get_project_status "$TEST_ROOT/proj3/.STATUS")
    assert_equals "$v" "active" "status synonym mapping" && test_pass
}

test_dash_project_focus_fallback_to_next() {
    test_case "_dash_get_project_focus falls back to 'next' when Focus is absent"
    local v=$(_dash_get_project_focus "$TEST_ROOT/proj2/.STATUS")
    assert_equals "$v" "Write the tests" "focus falls back to next" && test_pass
}

test_dash_project_progress_percent_not_actually_stripped() {
    test_case "_dash_get_project_progress: the '%' is NOT actually stripped today (zsh pattern quirk in \${var//%/})"
    local v=$(_dash_get_project_progress "$TEST_ROOT/proj1/.STATUS")
    # Pre-existing bug in dash.zsh, out of Phase 1's migration scope (only
    # _dash_get_status_field itself is migrated) — characterized so it is
    # not silently changed by an unrelated edit.
    assert_equals "$v" "42%" "dash progress wrapper's %-strip is a known no-op" && test_pass
}

# ============================================================================
# TESTS: morning (commands/morning.zsh) inline Focus/Progress greps
# ============================================================================

test_morning_focus_with_colon_and_percent() {
    test_case "morning renders a Focus value containing a colon and a %"
    local output=$(FLOW_PROJECTS_ROOT="$CMD_ROOT" morning 2>&1)
    assert_contains "$output" "Fix: the bug at 80% coverage" "morning focus rendering" && test_pass
}

test_morning_progress_strips_percent_and_pads() {
    test_case "morning renders Progress as ' 42%' (tr -d '%' then re-added by printf)"
    local output=$(FLOW_PROJECTS_ROOT="$CMD_ROOT" morning 2>&1)
    assert_contains "$output" "[ 42%]" "morning progress rendering" && test_pass
}

test_morning_missing_focus_omits_arrow() {
    test_case "morning omits the focus arrow when Focus is absent"
    local output=$(FLOW_PROJECTS_ROOT="$CMD_ROOT" morning 2>&1)
    local line=$(echo "$output" | grep "proj_nofocus")
    assert_not_contains "$line" "→" "no focus -> no arrow" && test_pass
}

# ============================================================================
# TESTS: next (commands/adhd.zsh) inline Focus grep
# ============================================================================

test_next_focus_with_colon_and_percent() {
    test_case "next renders a Focus value containing a colon and a %"
    local output=$(FLOW_PROJECTS_ROOT="$CMD_ROOT" next 2>&1)
    assert_contains "$output" "Fix: the bug at 80% coverage" "next focus rendering" && test_pass
}

test_next_missing_focus_omits_arrow() {
    test_case "next omits the focus arrow when Focus is absent"
    local output=$(FLOW_PROJECTS_ROOT="$CMD_ROOT" next 2>&1)
    local line=$(echo "$output" | grep "proj_nofocus")
    assert_not_contains "$line" "→" "no focus -> no arrow" && test_pass
}

# ============================================================================
# TESTS: capture.zsh's _flow_read_goal (inline daily_goal grep)
# ============================================================================

test_capture_reads_daily_goal_from_status() {
    test_case "_flow_read_goal reads '## daily_goal:' from the project .STATUS"
    local result
    (cd "$TEST_ROOT/proj1" && result=$(_flow_read_goal); echo "$result") > /tmp/.capture_goal_result.$$
    result=$(< /tmp/.capture_goal_result.$$)
    rm -f /tmp/.capture_goal_result.$$
    assert_equals "$result" "3" "daily_goal read from .STATUS" && test_pass
}

# ============================================================================
# TESTS: _flow_where_fallback (lib/atlas-bridge.zsh)
# ============================================================================
#
# UPDATED post-refactor (the one sanctioned exception to "don't adjust the
# characterization test", per this file's header comment): pre-refactor, this
# assertion captured `_flow_where_fallback` CRASHING on `local status=...`
# (status is a zsh read-only special variable, even function-local) and
# never printing Status:/Focus: at all — see git history for the original
# `test_where_fallback_currently_crashes_on_status`. The atlas-bridge.zsh:836
# migration (task 1.5) necessarily renamed that colliding local as part of
# routing the read through `_flow_status_field`, which fixed the crash as an
# unavoidable side effect. This is a discovered bug fix, not a silent
# behavior-loss regression — flagged in the Phase 1 report.

test_where_fallback_status_and_focus_now_print() {
    test_case "_flow_where_fallback: Status:/Focus: now print correctly (crash fixed by the migration)"
    local output
    (cd "$TEST_ROOT/proj_where" && FLOW_PROJECTS_ROOT="$TEST_ROOT" _flow_where_fallback "proj_where" 2>/dev/null) > /tmp/.where_result.$$
    output=$(< /tmp/.where_result.$$)
    rm -f /tmp/.where_result.$$
    assert_contains "$output" "📁 Project: proj_where" "project line prints" && \
    assert_contains "$output" "Status: active" "Status: now prints" && \
    assert_contains "$output" "Focus: Ship it" "Focus: now prints" && test_pass
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite "Status Field Reader Characterization (Phase 1 parity guard)"

    setup

    echo "${CYAN}--- _dash_get_status_field (raw reader) ---${RESET}"
    test_dash_field_colon_in_value
    test_dash_field_percent_in_non_progress_field
    test_dash_field_progress_keeps_percent
    test_dash_field_missing_returns_empty
    test_dash_field_yaml_dialect

    echo ""
    echo "${CYAN}--- dash.zsh wrapper functions ---${RESET}"
    test_dash_project_status
    test_dash_project_status_missing_file
    test_dash_project_status_synonym_mapping
    test_dash_project_focus_fallback_to_next
    test_dash_project_progress_percent_not_actually_stripped

    echo ""
    echo "${CYAN}--- morning (inline greps) ---${RESET}"
    test_morning_focus_with_colon_and_percent
    test_morning_progress_strips_percent_and_pads
    test_morning_missing_focus_omits_arrow

    echo ""
    echo "${CYAN}--- next (inline greps) ---${RESET}"
    test_next_focus_with_colon_and_percent
    test_next_missing_focus_omits_arrow

    echo ""
    echo "${CYAN}--- capture.zsh _flow_read_goal ---${RESET}"
    test_capture_reads_daily_goal_from_status

    echo ""
    echo "${CYAN}--- _flow_where_fallback ---${RESET}"
    test_where_fallback_status_and_focus_now_print

    cleanup
    test_suite_end
    exit $?
}

main "$@"
