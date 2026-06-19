#!/usr/bin/env zsh
# ============================================================================
# Static regression guard: flow doctor's atlas health checks must use
# spec-compliant atlas calls (see docs/ATLAS-CONTRACT.md).
#
# Prevents re-introducing the out-of-spec calls fixed in atlas-contract-v1.1:
#   OOS-1: `atlas config get backend`  → `atlas config show` (parse `.storage`)
#   OOS-2: `atlas mcp status`          → `command -v atlas-mcp` (separate binary)
# and the false-positive fix: "connected" is gated on a captured config-show
# response, not merely on the atlas binary being on PATH.
#
# This is a STATIC test — it greps the source, so it needs neither a working
# atlas nor jq and runs identically on every machine and CI runner.
# ============================================================================

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh"

DOCTOR_FILE="$PROJECT_ROOT/commands/doctor.zsh"

test_doctor_file_exists() {
    test_case "commands/doctor.zsh exists"
    assert_file_exists "$DOCTOR_FILE" && test_pass
}

test_uses_config_show_not_get() {
    test_case "uses 'atlas config show' and not the nonexistent 'atlas config get'"
    local content="$(cat "$DOCTOR_FILE")"
    assert_contains "$content" "atlas config show" && \
        assert_not_contains "$content" "atlas config get" && test_pass
}

test_uses_atlas_mcp_binary_not_subcommand() {
    test_case "checks 'command -v atlas-mcp', not the nonexistent 'atlas mcp status'"
    local content="$(cat "$DOCTOR_FILE")"
    assert_contains "$content" "command -v atlas-mcp" && \
        assert_not_contains "$content" "atlas mcp status" && test_pass
}

test_connected_gated_on_response() {
    test_case "'connected' is gated on a captured config-show response (not just command -v atlas)"
    local content="$(cat "$DOCTOR_FILE")"
    assert_contains "$content" 'atlas_cfg=' && \
        assert_contains "$content" 'not responding' && test_pass
}

test_storage_parse_is_anchored() {
    test_case "no-jq backend parse anchors on the \"storage\" key (no greedy last-quote match)"
    local content="$(cat "$DOCTOR_FILE")"
    # The hardened sed matches '"storage"...:..."<value>"'; assert the anchor is present.
    assert_contains "$content" '"storage"' && test_pass
}

main() {
    test_suite_start "Doctor Atlas Calls — spec-compliance guard"

    test_doctor_file_exists
    test_uses_config_show_not_get
    test_uses_atlas_mcp_binary_not_subcommand
    test_connected_gated_on_response
    test_storage_parse_is_anchored

    test_suite_end
    exit $?
}

main "$@"
