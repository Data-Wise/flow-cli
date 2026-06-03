#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# UNIT TEST SUITE - TOK DISPATCHER AUTO-SYNC WIRING (lib/dispatchers/tok-dispatcher.zsh)
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Coverage for the dispatcher-side wiring of tok auto-sync:
#          - `tok sync repos <name>` dry-run inspection (no writes)
#          - --no-sync flag parsing / stripping / reset
#          - _tok_autosync_hook guard logic (--no-sync, FLOW_TOK_AUTOSYNC=0)
#
# Standalone: `zsh tests/test-tok.zsh` exits 0 when green.
# ══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

export FLOW_QUIET=1
export FLOW_ATLAS_ENABLED=no
export FLOW_PLUGIN_DIR="$PROJECT_ROOT"

CONF_FILE=""

setup() {
    # Source the lib + dispatcher directly (not the whole plugin) for test isolation.
    source "$PROJECT_ROOT/lib/core.zsh" 2>/dev/null
    source "$PROJECT_ROOT/lib/tok-sync.zsh" 2>/dev/null
    source "$PROJECT_ROOT/lib/dispatchers/tok-dispatcher.zsh" 2>/dev/null
}

make_conf() {
    CONF_FILE="$(mktemp -t tok-conf.XXXXXX)"
    chmod 0600 "$CONF_FILE"
    print -r -- "$1" > "$CONF_FILE"
    export FLOW_TOK_SYNC_CONF="$CONF_FILE"
}

teardown_conf() {
    [[ -n "$CONF_FILE" && -f "$CONF_FILE" ]] && rm -f "$CONF_FILE"
    CONF_FILE=""
    unset FLOW_TOK_SYNC_CONF
}

# ──────────────────────────────────────────────────────────────────────────────
# TESTS
# ──────────────────────────────────────────────────────────────────────────────

test_functions_exist() {
    test_case "dispatcher + new helpers exist"
    assert_function_exists "tok" || return
    assert_function_exists "_tok_sync_repos" || return
    assert_function_exists "_tok_autosync_hook" || return
    test_pass
}

test_sync_repos_lists_targets() {
    test_case "tok sync repos lists push targets + OIDC notes, no writes"
    make_conf "$(print -l \
        'mytoken SECRET_A owner/repo1' \
        'mytoken SECRET_B owner/repo2' \
        'mytoken PYPI_TOKEN owner/repo3 oidc')"
    local out
    out="$(tok sync repos mytoken 2>&1)"
    teardown_conf
    assert_contains "$out" "owner/repo1 : SECRET_A" || return
    assert_contains "$out" "owner/repo2 : SECRET_B" || return
    assert_contains "$out" "OIDC" || return
    assert_contains "$out" "would push 2 secret(s) across 2 repo(s)" || return
    test_pass
}

test_sync_repos_requires_name() {
    test_case "tok sync repos requires a name"
    local rc
    tok sync repos >/dev/null 2>&1
    rc=$?
    assert_equals "$rc" "1" || return
    test_pass
}

test_sync_no_targets() {
    test_case "tok sync repos reports no targets gracefully"
    make_conf 'othertoken SECRET_X owner/repo'
    local out
    out="$(tok sync repos mytoken 2>&1)"
    teardown_conf
    assert_contains "$out" "no sync targets" || return
    test_pass
}

test_sync_unknown_subcommand() {
    test_case "tok sync <bogus> shows three-subcommand usage"
    local out
    out="$(tok sync bogus 2>&1)"
    assert_contains "$out" "tok sync <gh|push|repos>" || return
    test_pass
}

test_no_sync_flag_stripped_and_routes() {
    test_case "--no-sync is stripped and subcommand still routes"
    make_conf 'mytoken SECRET_A owner/repo1'
    local out
    out="$(tok sync --no-sync repos mytoken 2>&1)"
    teardown_conf
    assert_contains "$out" "owner/repo1 : SECRET_A" || return
    test_pass
}

test_no_sync_alone_shows_help() {
    test_case "tok --no-sync (empty subcommand) shows help, not unknown-provider error"
    local out
    out="$(tok --no-sync 2>&1)"
    assert_contains "$out" "tok - Token Management" || return
    assert_not_contains "$out" "Unknown token provider" || return
    test_pass
}

test_no_sync_suppresses_push() {
    test_case "--no-sync (via tok parsing) suppresses auto-sync push; default fires it"
    make_conf 'mytoken SECRET_A owner/repo1'

    # Mock the fan-out so we can count invocations rather than touch the network.
    local push_calls=0
    _tok_sync_push() { push_calls=$((push_calls + 1)) }

    # SUPPRESSED: tok parses --no-sync and sets _TOK_NO_SYNC=1; the hook must
    # then call _tok_sync_push 0 times.
    unset FLOW_TOK_AUTOSYNC
    tok sync --no-sync repos mytoken >/dev/null 2>&1   # parses + sets _TOK_NO_SYNC=1
    _tok_autosync_hook "mytoken" "val"
    local suppressed=$push_calls

    # ENABLED: a normal invocation resets _TOK_NO_SYNC=0; the hook must fire.
    push_calls=0
    tok sync repos mytoken >/dev/null 2>&1             # resets _TOK_NO_SYNC=0
    _tok_autosync_hook "mytoken" "val"
    local enabled=$push_calls

    unset -f _tok_sync_push
    typeset -g _TOK_NO_SYNC=0
    teardown_conf

    assert_equals "$suppressed" "0" || return
    assert_equals "$enabled" "1" || return
    test_pass
}

test_no_sync_resets_between_calls() {
    test_case "_TOK_NO_SYNC resets to 0 on next invocation"
    make_conf 'mytoken SECRET_A owner/repo1'
    tok sync --no-sync repos mytoken >/dev/null 2>&1
    tok sync repos mytoken >/dev/null 2>&1
    teardown_conf
    assert_equals "${_TOK_NO_SYNC:-unset}" "0" || return
    test_pass
}

test_hook_skips_when_no_sync() {
    test_case "_tok_autosync_hook skips when _TOK_NO_SYNC=1"
    local fired=0
    _tok_sync_push() { fired=1 }
    typeset -g _TOK_NO_SYNC=1
    _tok_autosync_hook "mytoken" "val"
    unset -f _tok_sync_push
    typeset -g _TOK_NO_SYNC=0
    assert_equals "$fired" "0" || return
    test_pass
}

test_hook_skips_when_env_disabled() {
    test_case "_tok_autosync_hook skips when FLOW_TOK_AUTOSYNC=0"
    local fired=0
    _tok_sync_push() { fired=1 }
    typeset -g _TOK_NO_SYNC=0
    FLOW_TOK_AUTOSYNC=0 _tok_autosync_hook "mytoken" "val"
    unset -f _tok_sync_push
    assert_equals "$fired" "0" || return
    test_pass
}

test_hook_fires_by_default() {
    test_case "_tok_autosync_hook fires with value when enabled"
    local got_name="" got_value=""
    _tok_sync_push() { got_name="$1"; got_value="$2" }
    typeset -g _TOK_NO_SYNC=0
    unset FLOW_TOK_AUTOSYNC
    _tok_autosync_hook "mytoken" "secretval"
    unset -f _tok_sync_push
    assert_equals "$got_name" "mytoken" || return
    assert_equals "$got_value" "secretval" || return
    test_pass
}

test_sync_push_routes_to_push() {
    test_case "tok sync push <name> routes to _tok_sync_push with that name"
    create_mock _tok_sync_push 'return 0'
    tok sync push mytoken >/dev/null 2>&1
    local rc=$?
    assert_mock_called "_tok_sync_push" 1 || { reset_mocks; return; }
    assert_mock_args "_tok_sync_push" "mytoken" || { reset_mocks; return; }
    reset_mocks
    test_pass
}

test_sync_gh_still_routes() {
    test_case "tok sync gh still routes to _tok_sync_gh and not push/repos"
    create_mock _tok_sync_gh 'return 0'
    create_mock _tok_sync_push 'return 0'
    create_mock _tok_sync_repos 'return 0'
    tok sync gh >/dev/null 2>&1
    assert_mock_called "_tok_sync_gh" 1 || { reset_mocks; return; }
    assert_mock_not_called "_tok_sync_push" || { reset_mocks; return; }
    assert_mock_not_called "_tok_sync_repos" || { reset_mocks; return; }
    reset_mocks
    test_pass
}

# ──────────────────────────────────────────────────────────────────────────────
# MAIN
# ──────────────────────────────────────────────────────────────────────────────

main() {
    test_suite_start "Tok Dispatcher Auto-Sync Wiring"

    setup

    test_functions_exist
    test_sync_repos_lists_targets
    test_sync_repos_requires_name
    test_sync_no_targets
    test_sync_unknown_subcommand
    test_no_sync_flag_stripped_and_routes
    test_no_sync_alone_shows_help
    test_no_sync_suppresses_push
    test_no_sync_resets_between_calls
    test_hook_skips_when_no_sync
    test_hook_skips_when_env_disabled
    test_hook_fires_by_default
    test_sync_push_routes_to_push
    test_sync_gh_still_routes

    test_suite_end
    exit $?
}

main "$@"
