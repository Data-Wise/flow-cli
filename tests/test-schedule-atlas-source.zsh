#!/usr/bin/env zsh
# tests/test-schedule-atlas-source.zsh
# Red-then-green unit tests for `_schedule_atlas_items <window>` (SPEC
# §3.4, ORCHESTRATE Phase 2, task 2.1) — the dark-ready atlas agenda source
# merged into the schedule engine.
#
# D15: atlas-absent is simulated via the capability-flag override
# (_flow_has_atlas / _FLOW_ATLAS_HAS_AGENDA), NOT `FLOW_ATLAS_ENABLED=no`
# alone (memory: capture-real-agenda-output-for-docs).
# D16: atlas-present is simulated via a stub `atlas` shim on PATH returning
# tests/fixtures/atlas-agenda-stub.json (real atlas has no `agenda` command
# yet, so it cannot be used for this).

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

FIXTURE="$PROJECT_ROOT/tests/fixtures/atlas-agenda-stub.json"

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

    STUB_BIN=$(mktemp -d)
}

cleanup() {
    reset_mocks
    _FLOW_ATLAS_AVAILABLE=""
    _FLOW_ATLAS_HAS_AGENDA=""
    [[ -n "$STUB_BIN" && -d "$STUB_BIN" ]] && rm -rf "$STUB_BIN"
}
trap cleanup EXIT

# Reset the two session caches this function consults, so each test gets a
# fresh capability probe regardless of what a prior test in this file did.
_reset_atlas_caches() {
    _FLOW_ATLAS_AVAILABLE=""
    _FLOW_ATLAS_HAS_AGENDA=""
}

# Writes a stub `atlas` executable to $STUB_BIN and prepends it to PATH.
# $1 - "capable"   -> agenda --help exits 0; agenda <window> --format=json cats the fixture
#      "incapable" -> everything exits 1 (simulates an atlas without `agenda`)
_install_stub_atlas() {
    local mode="$1"
    if [[ "$mode" == "capable" ]]; then
        cat > "$STUB_BIN/atlas" <<EOF
#!/bin/sh
if [ "\$1" = "agenda" ] && [ "\$2" = "--help" ]; then
  exit 0
fi
if [ "\$1" = "agenda" ]; then
  cat "$FIXTURE"
  exit 0
fi
exit 1
EOF
    else
        cat > "$STUB_BIN/atlas" <<'EOF'
#!/bin/sh
exit 1
EOF
    fi
    chmod +x "$STUB_BIN/atlas"
    export PATH="$STUB_BIN:$PATH"
}

test_function_exists() {
    test_case "_schedule_atlas_items function exists"
    assert_function_exists "_schedule_atlas_items" && test_pass
}

test_absent_via_capability_flag_is_empty() {
    test_case "atlas absent (capability-flag override): empty output, no crash"
    _reset_atlas_caches
    create_mock "_flow_has_atlas" "return 1"
    local out=$(_schedule_atlas_items 7)
    reset_mocks
    assert_empty "$out" "no atlas -> empty" && test_pass
}

test_present_but_no_agenda_capability_is_empty() {
    test_case "atlas present but lacks 'agenda' (older atlas): empty output"
    if ! command -v jq >/dev/null 2>&1; then
        test_skip "jq not installed"
        return
    fi
    _reset_atlas_caches
    local old_path="$PATH"
    _install_stub_atlas incapable
    local out=$(_schedule_atlas_items 7)
    PATH="$old_path"
    assert_empty "$out" "incapable atlas -> empty" && test_pass
}

test_capable_atlas_maps_fixture_to_records() {
    test_case "atlas present + capable: fixture maps to date|label|type|project|recurrence|atlas"
    if ! command -v jq >/dev/null 2>&1; then
        test_skip "jq not installed"
        return
    fi
    _reset_atlas_caches
    local old_path="$PATH"
    _install_stub_atlas capable
    local out=$(_schedule_atlas_items 7)
    PATH="$old_path"
    assert_contains "$out" "2026-07-05|Submit grant report|research|grant-writing|none|atlas" "first fixture record mapped" && \
    assert_contains "$out" "2026-07-12|NIH progress report|research|grant-writing|none|atlas" "second fixture record mapped" && test_pass
}

test_capability_probe_is_cached() {
    test_case "capability probe result is cached in _FLOW_ATLAS_HAS_AGENDA"
    if ! command -v jq >/dev/null 2>&1; then
        test_skip "jq not installed"
        return
    fi
    _reset_atlas_caches
    local old_path="$PATH"
    _install_stub_atlas capable
    _schedule_atlas_items 7 >/dev/null
    PATH="$old_path"
    assert_equals "$_FLOW_ATLAS_HAS_AGENDA" "yes" "cached as yes after a capable probe" && test_pass
}

test_no_jq_is_graceful_noop() {
    test_case "jq absent: graceful no-op, not a crash"
    _reset_atlas_caches
    local old_path="$PATH"
    _install_stub_atlas capable
    # Minimal explicit PATH (stub atlas dir + /bin only) rather than trying to
    # subtract jq's directory from $PATH — this box has jq on more than one
    # PATH entry (e.g. both /opt/homebrew/bin and /usr/bin), so a single
    # subtraction doesn't reliably hide it. /bin has no jq and covers the
    # POSIX utilities the harness itself needs.
    PATH="$STUB_BIN:/bin"
    local out
    out=$(_schedule_atlas_items 7 2>&1)
    local rc=$?
    PATH="$old_path"
    assert_empty "$out" "no jq -> empty, no crash" && \
    assert_exit_code $rc 0 "no jq -> exit 0 (graceful)" && test_pass
}

main() {
    test_suite "_schedule_atlas_items (dark-ready atlas agenda source)"
    setup

    test_function_exists
    test_absent_via_capability_flag_is_empty
    test_present_but_no_agenda_capability_is_empty
    test_capable_atlas_maps_fixture_to_records
    test_capability_probe_is_cached
    test_no_jq_is_graceful_noop

    cleanup
    test_suite_end
    exit $?
}

main "$@"
