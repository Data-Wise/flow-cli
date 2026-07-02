#!/usr/bin/env zsh
# tests/test-suggest-project.zsh
# Red-then-green unit tests for `_flow_suggest_project <strategy>` (SPEC §3.1,
# ORCHESTRATE task 1.1/1.4) — one active/priority scan replacing the 5
# reimplementations (dash.zsh:181 `_dash_right_now`, dash.zsh:1139
# `_dash_footer`, morning.zsh:144 `_flow_morning_suggest`, adhd.zsh `next`/`js`).
#
# NOT byte-parity guarded (unlike the field readers) — these 5 call sites
# genuinely differ in selection logic today. Each strategy mode below is
# pinned by its own red test instead.
#
# Strategies:
#   active             - first active project (dash footer)
#   active-with-focus  - first active project with a non-empty Focus (dash
#                        "right now")
#   priority           - first active project with Priority 1/P1 (morning)
#   random-active      - random pick from the active list, or first 5 of all
#                        projects if none active (adhd `js`)

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

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
}

cleanup() {
    reset_mocks
    unset -f _flow_has_atlas 2>/dev/null
    [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

test_function_exists() {
    test_case "_flow_suggest_project function exists"
    assert_function_exists "_flow_suggest_project" && test_pass
}

test_active_strategy_picks_first_active() {
    test_case "strategy 'active': first active project, paused ones skipped"
    local root=$(mktemp -d)
    mkdir -p "$root/a-paused" "$root/b-active"
    printf "## Status: paused\n" > "$root/a-paused/.STATUS"
    printf "## Status: active\n" > "$root/b-active/.STATUS"
    local v=$(FLOW_PROJECTS_ROOT="$root" _flow_suggest_project active)
    rm -rf "$root"
    assert_equals "$v" "b-active" "picks the active one" && test_pass
}

test_active_with_focus_requires_focus() {
    test_case "strategy 'active-with-focus': skips active projects with no Focus"
    local root=$(mktemp -d)
    mkdir -p "$root/a-no-focus" "$root/b-has-focus"
    printf "## Status: active\n" > "$root/a-no-focus/.STATUS"
    printf "## Status: active\n## Focus: Ship it\n" > "$root/b-has-focus/.STATUS"
    local v=$(FLOW_PROJECTS_ROOT="$root" _flow_suggest_project active-with-focus)
    rm -rf "$root"
    assert_equals "$v" "b-has-focus" "only the focused one qualifies" && test_pass
}

test_active_with_focus_empty_when_none_qualify() {
    test_case "strategy 'active-with-focus': empty when no active project has Focus"
    local root=$(mktemp -d)
    mkdir -p "$root/a-no-focus"
    printf "## Status: active\n" > "$root/a-no-focus/.STATUS"
    local v=$(FLOW_PROJECTS_ROOT="$root" _flow_suggest_project active-with-focus)
    rm -rf "$root"
    assert_empty "$v" "no qualifying project -> empty" && test_pass
}

test_priority_strategy_matches_p1_variants() {
    test_case "strategy 'priority': matches Priority '1' or 'P1' (trailing-space tolerant)"
    local root=$(mktemp -d)
    mkdir -p "$root/a-p2" "$root/b-p1"
    printf "## Status: active\n## Priority: 2\n" > "$root/a-p2/.STATUS"
    printf "## Status: active\n## Priority: P1 \n" > "$root/b-p1/.STATUS"
    local v=$(FLOW_PROJECTS_ROOT="$root" _flow_suggest_project priority)
    rm -rf "$root"
    assert_equals "$v" "b-p1" "P1 with trailing space still matches" && test_pass
}

test_priority_strategy_skips_paused_p1() {
    test_case "strategy 'priority': a paused P1 project does not qualify"
    local root=$(mktemp -d)
    mkdir -p "$root/a-paused-p1"
    printf "## Status: paused\n## Priority: P1\n" > "$root/a-paused-p1/.STATUS"
    local v=$(FLOW_PROJECTS_ROOT="$root" _flow_suggest_project priority)
    rm -rf "$root"
    assert_empty "$v" "paused P1 doesn't qualify" && test_pass
}

test_random_active_returns_a_known_active_project() {
    test_case "strategy 'random-active': returns one of the active projects"
    local root=$(mktemp -d)
    mkdir -p "$root/only-active"
    printf "## Status: active\n" > "$root/only-active/.STATUS"
    local v=$(FLOW_PROJECTS_ROOT="$root" _flow_suggest_project random-active)
    rm -rf "$root"
    assert_equals "$v" "only-active" "single-candidate random pick is deterministic" && test_pass
}

test_no_projects_returns_empty() {
    test_case "no projects at all -> empty output, exit 1"
    local root=$(mktemp -d)
    local out rc
    out=$(FLOW_PROJECTS_ROOT="$root" _flow_suggest_project active)
    rc=$?
    rm -rf "$root"
    assert_empty "$out" "no projects -> empty" && \
    assert_exit_code $rc 1 "no projects -> exit 1" && test_pass
}

main() {
    test_suite "_flow_suggest_project strategies"
    setup

    test_function_exists
    test_active_strategy_picks_first_active
    test_active_with_focus_requires_focus
    test_active_with_focus_empty_when_none_qualify
    test_priority_strategy_matches_p1_variants
    test_priority_strategy_skips_paused_p1
    test_random_active_returns_a_known_active_project
    test_no_projects_returns_empty

    cleanup
    test_suite_end
    exit $?
}

main "$@"
