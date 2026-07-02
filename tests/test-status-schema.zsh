#!/usr/bin/env zsh
# tests/test-status-schema.zsh
# Red-then-green tests for scripts/check-status.zsh (SPEC-planning-
# coordination-2026-07-01 §3.6, ORCHESTRATE Phase 3, D9/D11).
#
# D11 (warn-only, hard constraint): check-status.zsh must exit 0 ALWAYS this
# cycle, no matter how malformed the input — it prints violations, never
# blocks. Every test below that feeds it a broken fixture also asserts
# exit 0, not just the warning text.

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

CHECKER="$PROJECT_ROOT/scripts/check-status.zsh"
TEMPLATE="$PROJECT_ROOT/templates/.STATUS.template"

setup() {
    TEST_ROOT=$(mktemp -d)
}

cleanup() {
    [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

test_checker_script_exists() {
    test_case "scripts/check-status.zsh exists"
    assert_file_exists "$CHECKER" && test_pass
}

test_template_exists() {
    test_case "templates/.STATUS.template exists"
    assert_file_exists "$TEMPLATE" && test_pass
}

test_clean_fixture_no_warnings_exit_0() {
    test_case "a fully valid .STATUS: no warnings printed, exit 0"
    mkdir -p "$TEST_ROOT/clean"
    cat > "$TEST_ROOT/clean/.STATUS" <<'EOF'
## Project: demo
## Type: zsh-plugin
## Status: active
## Focus: Ship it
## Phase: Building
## Priority: 2
## Progress: 42

## Schedule:
- 2030-01-01 | New year check-in | general
- weekly:fri | Grading window | recurring
EOF
    local output rc
    output=$(zsh "$CHECKER" "$TEST_ROOT/clean/.STATUS" 2>&1)
    rc=$?
    assert_exit_code $rc 0 "clean fixture -> exit 0" && \
    assert_not_contains "$output" "WARN" "clean fixture -> no warnings" && test_pass
}

test_missing_required_field_warns_but_exits_0() {
    test_case "missing required field: warns, still exits 0"
    mkdir -p "$TEST_ROOT/missing-field"
    cat > "$TEST_ROOT/missing-field/.STATUS" <<'EOF'
## Project: demo
## Type: zsh-plugin
## Status: active
## Priority: 2
## Progress: 42
EOF
    local output rc
    output=$(zsh "$CHECKER" "$TEST_ROOT/missing-field/.STATUS" 2>&1)
    rc=$?
    assert_exit_code $rc 0 "missing field -> still exit 0 (warn-only)" && \
    assert_contains "$output" "Focus" "reports the missing Focus field" && test_pass
}

test_bad_progress_warns_but_exits_0() {
    test_case "Progress out of 0-100 range: warns, still exits 0"
    mkdir -p "$TEST_ROOT/bad-progress"
    cat > "$TEST_ROOT/bad-progress/.STATUS" <<'EOF'
## Project: demo
## Type: zsh-plugin
## Status: active
## Focus: Ship it
## Phase: Building
## Priority: 2
## Progress: 150
EOF
    local output rc
    output=$(zsh "$CHECKER" "$TEST_ROOT/bad-progress/.STATUS" 2>&1)
    rc=$?
    assert_exit_code $rc 0 "bad Progress -> still exit 0 (warn-only)" && \
    assert_contains "$output" "Progress" "reports the bad Progress value" && test_pass
}

test_non_numeric_progress_warns_but_exits_0() {
    test_case "non-numeric Progress: warns, still exits 0"
    mkdir -p "$TEST_ROOT/nonnumeric-progress"
    cat > "$TEST_ROOT/nonnumeric-progress/.STATUS" <<'EOF'
## Project: demo
## Type: zsh-plugin
## Status: active
## Focus: Ship it
## Phase: Building
## Priority: 2
## Progress: mostly-done
EOF
    local output rc
    output=$(zsh "$CHECKER" "$TEST_ROOT/nonnumeric-progress/.STATUS" 2>&1)
    rc=$?
    assert_exit_code $rc 0 "non-numeric Progress -> still exit 0" && \
    assert_contains "$output" "Progress" "reports the non-numeric Progress value" && test_pass
}

test_bad_status_warns_but_exits_0() {
    test_case "Status outside the allowed set: warns, still exits 0"
    mkdir -p "$TEST_ROOT/bad-status"
    cat > "$TEST_ROOT/bad-status/.STATUS" <<'EOF'
## Project: demo
## Type: zsh-plugin
## Status: wibble
## Focus: Ship it
## Phase: Building
## Priority: 2
## Progress: 42
EOF
    local output rc
    output=$(zsh "$CHECKER" "$TEST_ROOT/bad-status/.STATUS" 2>&1)
    rc=$?
    assert_exit_code $rc 0 "bad Status -> still exit 0" && \
    assert_contains "$output" "Status" "reports the bad Status value" && test_pass
}

test_status_synonym_accepted() {
    test_case "Status synonym ('In Progress', normalized by _flow_status_field) is NOT flagged"
    mkdir -p "$TEST_ROOT/status-synonym"
    cat > "$TEST_ROOT/status-synonym/.STATUS" <<'EOF'
## Project: demo
## Type: zsh-plugin
## Status: In Progress
## Focus: Ship it
## Phase: Building
## Priority: 2
## Progress: 42
EOF
    local output rc
    output=$(zsh "$CHECKER" "$TEST_ROOT/status-synonym/.STATUS" 2>&1)
    rc=$?
    assert_exit_code $rc 0 "synonym status -> exit 0" && \
    assert_not_contains "$output" "Status 'In Progress'" "synonym accepted, not flagged as invalid" && test_pass
}

test_malformed_schedule_line_warns_but_exits_0() {
    test_case "malformed Schedule line: warns, still exits 0"
    mkdir -p "$TEST_ROOT/bad-schedule"
    cat > "$TEST_ROOT/bad-schedule/.STATUS" <<'EOF'
## Project: demo
## Type: zsh-plugin
## Status: active
## Focus: Ship it
## Phase: Building
## Priority: 2
## Progress: 42

## Schedule:
- next tuesday | Fuzzy date | general
EOF
    local output rc
    output=$(zsh "$CHECKER" "$TEST_ROOT/bad-schedule/.STATUS" 2>&1)
    rc=$?
    assert_exit_code $rc 0 "malformed Schedule line -> still exit 0" && \
    assert_contains "$output" "Schedule" "reports the malformed Schedule line" && test_pass
}

test_maximally_broken_fixture_still_exits_0() {
    test_case "D11 hard constraint: a maximally malformed .STATUS still exits 0"
    mkdir -p "$TEST_ROOT/maximally-broken"
    cat > "$TEST_ROOT/maximally-broken/.STATUS" <<'EOF'
this is not a .STATUS file at all
## Status: nonsense
## Progress: -5
## Schedule:
- garbage line with no pipes
EOF
    local rc
    zsh "$CHECKER" "$TEST_ROOT/maximally-broken/.STATUS" >/dev/null 2>&1
    rc=$?
    assert_exit_code $rc 0 "even a maximally broken .STATUS never blocks (D11)" && test_pass
}

test_template_passes_clean() {
    test_case "templates/.STATUS.template itself passes clean (per SPEC §3.6)"
    local output rc
    output=$(zsh "$CHECKER" "$TEMPLATE" 2>&1)
    rc=$?
    assert_exit_code $rc 0 "template -> exit 0" && \
    assert_not_contains "$output" "WARN" "template -> no warnings" && test_pass
}

test_flow_cli_own_status_passes_clean() {
    test_case "flow-cli's own .STATUS passes clean (per SPEC §3.6)"
    local output rc
    output=$(zsh "$CHECKER" "$PROJECT_ROOT/.STATUS" 2>&1)
    rc=$?
    assert_exit_code $rc 0 "flow-cli's own .STATUS -> exit 0" && \
    assert_not_contains "$output" "WARN" "flow-cli's own .STATUS -> no warnings" && test_pass
}

test_no_args_exits_0() {
    test_case "no arguments: usage message, exit 0 (not an error)"
    local rc
    zsh "$CHECKER" >/dev/null 2>&1
    rc=$?
    assert_exit_code $rc 0 "no args -> exit 0" && test_pass
}

test_lint_staged_wired() {
    test_case "package.json lint-staged has an extensionless '.STATUS' entry (not a glob)"
    local pkg="$PROJECT_ROOT/package.json"
    local content=$(cat "$pkg")
    assert_contains "$content" '".STATUS"' "lint-staged has a literal .STATUS filename key" && \
    assert_contains "$content" "check-status.zsh" "lint-staged entry runs check-status.zsh" && test_pass
}

main() {
    test_suite ".STATUS Schema Enforcer (warn-only, D9/D11)"
    setup

    echo "${CYAN}--- Files exist ---${RESET}"
    test_checker_script_exists
    test_template_exists

    echo ""
    echo "${CYAN}--- Clean fixtures ---${RESET}"
    test_clean_fixture_no_warnings_exit_0
    test_template_passes_clean
    test_flow_cli_own_status_passes_clean

    echo ""
    echo "${CYAN}--- Violations (warn, never block) ---${RESET}"
    test_missing_required_field_warns_but_exits_0
    test_bad_progress_warns_but_exits_0
    test_non_numeric_progress_warns_but_exits_0
    test_bad_status_warns_but_exits_0
    test_status_synonym_accepted
    test_malformed_schedule_line_warns_but_exits_0
    test_maximally_broken_fixture_still_exits_0

    echo ""
    echo "${CYAN}--- CLI + wiring ---${RESET}"
    test_no_args_exits_0
    test_lint_staged_wired

    cleanup
    test_suite_end
    exit $?
}

main "$@"
