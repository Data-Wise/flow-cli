#!/usr/bin/env zsh
# tests/test-status-field-accessor.zsh
# Red-then-green unit tests for the new shared accessor `_flow_status_field`
# (SPEC-planning-coordination-2026-07-01 §3.1, ORCHESTRATE task 1.1/1.2).
#
# Signature: _flow_status_field <project-root-dir> <field>
# (unlike _dash_get_status_field, which takes the FULL .STATUS file path —
# _flow_status_field takes the project ROOT and appends /.STATUS itself.)

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
    mkdir -p "$TEST_ROOT/md" "$TEST_ROOT/yaml" "$TEST_ROOT/synonym"
    cat > "$TEST_ROOT/md/.STATUS" <<'EOF'
## Status: active
## Focus: Fix: the bug at 80% coverage
## Progress: 42%
EOF
    printf "status: active\npriority: 2\n" > "$TEST_ROOT/yaml/.STATUS"
    printf "## Status: In Progress\n" > "$TEST_ROOT/synonym/.STATUS"
}

cleanup() {
    reset_mocks
    [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

test_function_exists() {
    test_case "_flow_status_field function exists"
    assert_function_exists "_flow_status_field" && test_pass
}

test_markdown_dialect() {
    test_case "_flow_status_field reads '## Field:' markdown dialect"
    local v=$(_flow_status_field "$TEST_ROOT/md" "Focus")
    assert_equals "$v" "Fix: the bug at 80% coverage" "markdown dialect" && test_pass
}

test_yaml_dialect() {
    test_case "_flow_status_field reads 'field:' YAML-ish dialect"
    local v=$(_flow_status_field "$TEST_ROOT/yaml" "status")
    assert_equals "$v" "active" "yaml dialect" && test_pass
}

test_percent_not_stripped_by_default() {
    test_case "_flow_status_field does NOT strip % (call sites do that themselves)"
    local v=$(_flow_status_field "$TEST_ROOT/md" "Progress")
    assert_equals "$v" "42%" "raw value keeps %" && test_pass
}

test_missing_field_returns_empty() {
    test_case "_flow_status_field returns empty for a missing field"
    local v=$(_flow_status_field "$TEST_ROOT/md" "NoSuchField")
    assert_empty "$v" "missing field" && test_pass
}

test_missing_status_file_returns_empty() {
    test_case "_flow_status_field returns empty (exit 1) when .STATUS is absent"
    local v
    v=$(_flow_status_field "$TEST_ROOT/does-not-exist" "Status")
    local rc=$?
    assert_empty "$v" "missing file -> empty" && \
    assert_exit_code $rc 1 "missing file -> exit 1" && test_pass
}

test_status_synonym_mapping() {
    test_case "_flow_status_field normalizes Status synonyms ('In Progress' -> 'active')"
    local v=$(_flow_status_field "$TEST_ROOT/synonym" "Status")
    assert_equals "$v" "active" "status synonym mapping preserved" && test_pass
}

main() {
    test_suite "_flow_status_field accessor"
    setup

    test_function_exists
    test_markdown_dialect
    test_yaml_dialect
    test_percent_not_stripped_by_default
    test_missing_field_returns_empty
    test_missing_status_file_returns_empty
    test_status_synonym_mapping

    cleanup
    test_suite_end
    exit $?
}

main "$@"
