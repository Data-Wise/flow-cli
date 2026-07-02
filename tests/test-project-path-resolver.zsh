#!/usr/bin/env zsh
# tests/test-project-path-resolver.zsh
# Red-then-green unit tests for `_flow_resolve_project_path` (SPEC §3.1,
# ORCHESTRATE task 1.1/1.3) — merges _dash_find_project_path (dash.zsh:1284,
# has apps + quarto/manuscripts + presentations) and
# _flow_get_project_fallback (atlas-bridge.zsh:370). Always emits
# `project_path=`, never `path=`.

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
    exec < /dev/null

    TEST_ROOT=$(mktemp -d)
    mkdir -p "$TEST_ROOT/dev-tools/dt-proj"
    mkdir -p "$TEST_ROOT/apps/app-proj"
    mkdir -p "$TEST_ROOT/r-packages/active/rpkg-proj"
    mkdir -p "$TEST_ROOT/r-packages/stable/rstable-proj"
    mkdir -p "$TEST_ROOT/research/research-proj"
    mkdir -p "$TEST_ROOT/teaching/teach-proj"
    mkdir -p "$TEST_ROOT/quarto/manuscripts/ms-proj"
    mkdir -p "$TEST_ROOT/quarto/presentations/pres-proj"
    mkdir -p "$TEST_ROOT/root-proj"
    FLOW_PROJECTS_ROOT="$TEST_ROOT"
}

cleanup() {
    reset_mocks
    [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

test_function_exists() {
    test_case "_flow_resolve_project_path function exists"
    assert_function_exists "_flow_resolve_project_path" && test_pass
}

_resolve() {
    local out
    out=$(FLOW_PROJECTS_ROOT="$TEST_ROOT" _flow_resolve_project_path "$1") || { echo ""; return 1; }
    local project_path
    eval "$out"
    echo "$project_path"
}

test_finds_dev_tools() {
    test_case "resolves a dev-tools project"
    assert_equals "$(_resolve dt-proj)" "$TEST_ROOT/dev-tools/dt-proj" "dev-tools" && test_pass
}

test_finds_apps() {
    test_case "resolves an apps project (dash's superset over atlas fallback)"
    assert_equals "$(_resolve app-proj)" "$TEST_ROOT/apps/app-proj" "apps" && test_pass
}

test_finds_r_packages_active() {
    test_case "resolves an r-packages/active project"
    assert_equals "$(_resolve rpkg-proj)" "$TEST_ROOT/r-packages/active/rpkg-proj" "r-packages active" && test_pass
}

test_finds_r_packages_stable() {
    test_case "resolves an r-packages/stable project"
    assert_equals "$(_resolve rstable-proj)" "$TEST_ROOT/r-packages/stable/rstable-proj" "r-packages stable" && test_pass
}

test_finds_research() {
    test_case "resolves a research project"
    assert_equals "$(_resolve research-proj)" "$TEST_ROOT/research/research-proj" "research" && test_pass
}

test_finds_teaching() {
    test_case "resolves a teaching project"
    assert_equals "$(_resolve teach-proj)" "$TEST_ROOT/teaching/teach-proj" "teaching" && test_pass
}

test_finds_quarto_manuscripts() {
    test_case "resolves a quarto/manuscripts project"
    assert_equals "$(_resolve ms-proj)" "$TEST_ROOT/quarto/manuscripts/ms-proj" "quarto manuscripts" && test_pass
}

test_finds_quarto_presentations() {
    test_case "resolves a quarto/presentations project"
    assert_equals "$(_resolve pres-proj)" "$TEST_ROOT/quarto/presentations/pres-proj" "quarto presentations" && test_pass
}

test_finds_root_exact_match() {
    test_case "resolves a project directly under FLOW_PROJECTS_ROOT"
    assert_equals "$(_resolve root-proj)" "$TEST_ROOT/root-proj" "root exact match" && test_pass
}

test_unknown_project_empty() {
    test_case "unknown project name resolves to empty and exit 1"
    local out
    out=$(FLOW_PROJECTS_ROOT="$TEST_ROOT" _flow_resolve_project_path "totally-unknown-xyz")
    local rc=$?
    assert_empty "$out" "unknown -> empty" && \
    assert_exit_code $rc 1 "unknown -> exit 1" && test_pass
}

test_emits_project_path_key() {
    test_case "output uses the key 'project_path=', never 'path='"
    local out
    out=$(FLOW_PROJECTS_ROOT="$TEST_ROOT" _flow_resolve_project_path "dt-proj")
    assert_contains "$out" "project_path=" "has project_path=" && \
    assert_not_contains "$out" $'\npath=' "never bare path=" && test_pass
}

main() {
    test_suite "_flow_resolve_project_path resolver"
    setup

    test_function_exists
    test_finds_dev_tools
    test_finds_apps
    test_finds_r_packages_active
    test_finds_r_packages_stable
    test_finds_research
    test_finds_teaching
    test_finds_quarto_manuscripts
    test_finds_quarto_presentations
    test_finds_root_exact_match
    test_unknown_project_empty
    test_emits_project_path_key

    cleanup
    test_suite_end
    exit $?
}

main "$@"
