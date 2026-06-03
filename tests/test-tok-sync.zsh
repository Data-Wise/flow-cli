#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# UNIT TEST SUITE - TOK AUTO-SYNC FOUNDATION (lib/tok-sync.zsh)
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: TDD coverage for config-driven fan-out of a secret value to
#          GitHub Actions secrets across repos.
#
# Standalone: `zsh tests/test-tok-sync.zsh` exits 0 when green.
# ══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

export FLOW_QUIET=1
export FLOW_ATLAS_ENABLED=no
export FLOW_PLUGIN_DIR="$PROJECT_ROOT"

# ──────────────────────────────────────────────────────────────────────────────
# SETUP / CLEANUP
# ──────────────────────────────────────────────────────────────────────────────

CONF_FILE=""

setup() {
    # Source the lib directly (not the whole plugin) for test isolation.
    source "$PROJECT_ROOT/lib/core.zsh" 2>/dev/null
    source "$PROJECT_ROOT/lib/tok-sync.zsh" 2>/dev/null
}

make_conf() {
    CONF_FILE="$(mktemp -t tok-sync-conf.XXXXXX)"
    chmod 0600 "$CONF_FILE"
    print -r -- "$1" > "$CONF_FILE"
    export FLOW_TOK_SYNC_CONF="$CONF_FILE"
}

make_conf_escaped() {
    # Like make_conf but interprets \t and \r escapes in the content.
    CONF_FILE="$(mktemp -t tok-sync-conf.XXXXXX)"
    chmod 0600 "$CONF_FILE"
    print -- "$1" > "$CONF_FILE"
    export FLOW_TOK_SYNC_CONF="$CONF_FILE"
}

teardown_conf() {
    [[ -n "$CONF_FILE" && -f "$CONF_FILE" ]] && rm -f "$CONF_FILE"
    CONF_FILE=""
    unset FLOW_TOK_SYNC_CONF
}

# ──────────────────────────────────────────────────────────────────────────────
# FUNCTION EXISTENCE
# ──────────────────────────────────────────────────────────────────────────────

test_functions_exist() {
    test_case "core tok-sync functions exist"
    assert_function_exists "_tok_sync_conf_path" || return
    assert_function_exists "_tok_sync_load_targets" || return
    assert_function_exists "_tok_sync_resolve_value" || return
    assert_function_exists "_tok_sync_push" || return
    test_pass
}

# ──────────────────────────────────────────────────────────────────────────────
# CONF PATH
# ──────────────────────────────────────────────────────────────────────────────

test_conf_path_uses_env() {
    test_case "_tok_sync_conf_path honors FLOW_TOK_SYNC_CONF"
    export FLOW_TOK_SYNC_CONF="/tmp/custom-tok-sync.conf"
    local got="$(_tok_sync_conf_path)"
    unset FLOW_TOK_SYNC_CONF
    assert_equals "$got" "/tmp/custom-tok-sync.conf" && test_pass
}

test_conf_path_default() {
    test_case "_tok_sync_conf_path defaults under HOME/.config/flow"
    unset FLOW_TOK_SYNC_CONF
    local got="$(_tok_sync_conf_path)"
    assert_equals "$got" "$HOME/.config/flow/tok-sync.conf" && test_pass
}

# ──────────────────────────────────────────────────────────────────────────────
# LOAD TARGETS
# ──────────────────────────────────────────────────────────────────────────────

test_load_targets_parses_matching_name() {
    test_case "load_targets emits only rows matching the name, skips comments/blanks"
    make_conf '# header comment
github-app   APP_ID           data-wise/flow-cli

github-app   APP_PRIVATE_KEY  data-wise/flow-cli
pypi         PYPI_TOKEN       data-wise/nexus-cli   oidc'
    local out="$(_tok_sync_load_targets github-app)"
    teardown_conf

    assert_contains "$out" "APP_ID	data-wise/flow-cli" || return
    assert_contains "$out" "APP_PRIVATE_KEY	data-wise/flow-cli" || return
    assert_not_contains "$out" "PYPI_TOKEN" || return
    # exactly two emitted lines
    local n=$(print -r -- "$out" | grep -c .)
    assert_equals "$n" "2" && test_pass
}

test_load_targets_emits_oidc_flag() {
    test_case "load_targets carries the oidc flag in the third column"
    make_conf 'pypi   PYPI_TOKEN   data-wise/nexus-cli   oidc'
    local out="$(_tok_sync_load_targets pypi)"
    teardown_conf
    assert_contains "$out" "PYPI_TOKEN	data-wise/nexus-cli	oidc" && test_pass
}

test_load_targets_missing_conf_empty() {
    test_case "load_targets returns nothing and rc 0 when conf missing"
    export FLOW_TOK_SYNC_CONF="/tmp/does-not-exist-$$.conf"
    local out; out="$(_tok_sync_load_targets github-app)"; local rc=$?
    unset FLOW_TOK_SYNC_CONF
    assert_exit_code "$rc" 0 || return
    assert_empty "$out" && test_pass
}

test_load_targets_rejects_bad_repo() {
    test_case "load_targets skips rows with invalid repo, keeps valid rows"
    make_conf 'github-app   APP_ID   data-wise/flow-cli
github-app   BAD_ROW   bad repo with spaces
github-app   APP_KEY   data-wise/other'
    local out="$(_tok_sync_load_targets github-app 2>/dev/null)"
    teardown_conf
    assert_contains "$out" "APP_ID	data-wise/flow-cli" || return
    assert_contains "$out" "APP_KEY	data-wise/other" || return
    assert_not_contains "$out" "BAD_ROW" && test_pass
}

test_load_targets_rejects_bad_secret() {
    test_case "load_targets skips rows with invalid secret name"
    make_conf 'github-app   BAD;NAME   data-wise/flow-cli
github-app   GOOD_NAME   data-wise/flow-cli'
    local out="$(_tok_sync_load_targets github-app 2>/dev/null)"
    teardown_conf
    assert_contains "$out" "GOOD_NAME	data-wise/flow-cli" || return
    assert_not_contains "$out" "BAD;NAME" && test_pass
}

test_load_targets_bad_row_warns() {
    test_case "load_targets prints a warning for rejected rows"
    make_conf 'github-app   APP_ID   bad repo'
    local warn; warn="$(_tok_sync_load_targets github-app 2>&1 >/dev/null)"
    teardown_conf
    assert_not_empty "$warn" && test_pass
}

test_load_targets_skips_tab_only_line() {
    test_case "load_targets skips a tab-only blank line"
    make_conf_escaped "github-app   APP_ID   data-wise/flow-cli
\t
github-app   APP_KEY   data-wise/other"
    local out="$(_tok_sync_load_targets github-app 2>/dev/null)"
    teardown_conf
    assert_contains "$out" "APP_ID	data-wise/flow-cli" || return
    assert_contains "$out" "APP_KEY	data-wise/other" || return
    local n=$(print -r -- "$out" | grep -c .)
    assert_equals "$n" "2" && test_pass
}

test_load_targets_skips_indented_comment() {
    test_case "load_targets skips space- and tab-indented comments"
    make_conf "github-app   APP_ID   data-wise/flow-cli
   # space-indented comment
\t# tab-indented comment
github-app   APP_KEY   data-wise/other"
    local out="$(_tok_sync_load_targets github-app 2>/dev/null)"
    teardown_conf
    assert_not_contains "$out" "comment" || return
    assert_contains "$out" "APP_ID	data-wise/flow-cli" || return
    assert_contains "$out" "APP_KEY	data-wise/other" || return
    local n=$(print -r -- "$out" | grep -c .)
    assert_equals "$n" "2" && test_pass
}

test_load_targets_skips_cr_blank_line() {
    test_case "load_targets skips a carriage-return-only blank line"
    make_conf_escaped "github-app   APP_ID   data-wise/flow-cli
\r
github-app   APP_KEY   data-wise/other"
    local out="$(_tok_sync_load_targets github-app 2>/dev/null)"
    teardown_conf
    assert_contains "$out" "APP_ID	data-wise/flow-cli" || return
    assert_contains "$out" "APP_KEY	data-wise/other" || return
    local n=$(print -r -- "$out" | grep -c .)
    assert_equals "$n" "2" && test_pass
}

test_push_rejects_invalid_name() {
    test_case "push rejects an invalid token name at the boundary"
    make_conf 'github-app   APP_ID   data-wise/flow-cli'
    mock_gh_counting

    _tok_sync_push 'bad;name' "secretvalue" >/dev/null 2>&1 <<< "y"; local rc=$?
    local called="$(set_count)"
    reset_mocks
    teardown_gh
    teardown_conf

    assert_exit_code "$rc" 1 || return
    assert_equals "$called" "0" && test_pass
}

# ──────────────────────────────────────────────────────────────────────────────
# PUSH: guards / no-ops
# ──────────────────────────────────────────────────────────────────────────────

# Helpers: SET_COUNT counts only `gh secret set` invocations (auth-status calls
# are answered but not counted), so assertions target real writes.
GH_SET_LOG=""

mock_gh_counting() {
    # body: succeed on `auth status`, log + succeed on `secret set`
    GH_SET_LOG="$(mktemp -t tok-sync-set.XXXXXX)"
    create_mock gh "
        if [[ \"\$1\" == auth ]]; then return 0; fi
        if [[ \"\$1\" == secret && \"\$2\" == set ]]; then
            cat >/dev/null 2>&1
            echo set >> '$GH_SET_LOG'
            return 0
        fi
        return 0
    "
}

set_count() {
    local c=0
    [[ -f "$GH_SET_LOG" ]] && c=$(grep -c . "$GH_SET_LOG" 2>/dev/null)
    print -r -- "${c:-0}"
}

teardown_gh() {
    [[ -n "$GH_SET_LOG" && -f "$GH_SET_LOG" ]] && rm -f "$GH_SET_LOG"
    GH_SET_LOG=""
}

test_push_noop_missing_gh() {
    test_case "push is a non-fatal no-op when gh is absent"
    make_conf 'github-app   APP_ID   data-wise/flow-cli'
    create_mock command 'if [[ "$1" == "-v" && "$2" == "gh" ]]; then return 1; fi; builtin command "$@"'
    mock_gh_counting

    _tok_sync_push github-app "secretvalue" >/dev/null 2>&1; local rc=$?
    local called="$(set_count)"
    reset_mocks
    teardown_gh
    teardown_conf

    assert_exit_code "$rc" 0 || return
    assert_equals "$called" "0" && test_pass
}

test_push_noop_zero_targets() {
    test_case "push no-ops when there are no targets for the name"
    make_conf 'pypi   PYPI_TOKEN   data-wise/nexus-cli'
    mock_gh_counting

    _tok_sync_push github-app "secretvalue" >/dev/null 2>&1; local rc=$?
    local called="$(set_count)"
    reset_mocks
    teardown_gh
    teardown_conf

    assert_exit_code "$rc" 0 || return
    assert_equals "$called" "0" && test_pass
}

test_push_noop_empty_value() {
    test_case "push refuses to write when resolved value is empty"
    make_conf 'github-app   APP_ID   data-wise/flow-cli'
    mock_gh_counting
    # resolve returns empty
    create_mock _tok_sync_resolve_value 'printf ""'

    _tok_sync_push github-app >/dev/null 2>&1; local rc=$?
    local called="$(set_count)"
    reset_mocks
    teardown_gh
    teardown_conf

    assert_exit_code "$rc" 0 || return
    assert_equals "$called" "0" && test_pass
}

# ──────────────────────────────────────────────────────────────────────────────
# PUSH: confirm gate
# ──────────────────────────────────────────────────────────────────────────────

test_push_confirm_no_skips_writes() {
    test_case "answering N at the confirm prompt performs no writes"
    make_conf 'github-app   APP_ID   data-wise/flow-cli'
    mock_gh_counting

    _tok_sync_push github-app "secretvalue" >/dev/null 2>&1 <<< "n"
    local called="$(set_count)"
    reset_mocks
    teardown_gh
    teardown_conf

    assert_equals "$called" "0" && test_pass
}

test_push_confirm_yes_pushes_each_row() {
    test_case "answering y pushes one gh secret set per target row"
    make_conf 'github-app   APP_ID           data-wise/flow-cli
github-app   APP_PRIVATE_KEY  data-wise/flow-cli'
    mock_gh_counting

    _tok_sync_push github-app "secretvalue" >/dev/null 2>&1 <<< "y"
    local called="$(set_count)"
    reset_mocks
    teardown_gh
    teardown_conf

    assert_equals "$called" "2" && test_pass
}

test_push_value_via_stdin() {
    test_case "the secret value is piped to gh on stdin (never argv)"
    local capture; capture="$(mktemp -t tok-sync-stdin.XXXXXX)"
    make_conf 'github-app   APP_ID   data-wise/flow-cli'
    # mock gh: answer auth status; on secret set dump stdin to capture file.
    # argv must NOT carry the secret value.
    create_mock gh "
        if [[ \"\$1\" == auth ]]; then return 0; fi
        if [[ \"\$1\" == secret && \"\$2\" == set ]]; then cat > '$capture'; return 0; fi
        return 0
    "

    _tok_sync_push github-app "supersecret" >/dev/null 2>&1 <<< "y"
    local stdin_got="$(cat "$capture")"
    local argv="${MOCK_ARGS[gh]}"
    reset_mocks
    rm -f "$capture"
    teardown_conf

    assert_equals "$stdin_got" "supersecret" || return
    assert_not_contains "$argv" "supersecret" && test_pass
}

# ──────────────────────────────────────────────────────────────────────────────
# PUSH: oidc handling
# ──────────────────────────────────────────────────────────────────────────────

test_push_oidc_row_not_pushed() {
    test_case "oidc rows are skipped from push and an OIDC note is printed"
    make_conf 'pypi   PYPI_TOKEN   data-wise/nexus-cli   oidc'
    mock_gh_counting

    local out; out="$(_tok_sync_push pypi "secretvalue" 2>&1 <<< "y")"
    local called="$(set_count)"
    reset_mocks
    teardown_gh
    teardown_conf

    assert_equals "$called" "0" || return
    assert_contains "$out" "OIDC" && test_pass
}

# ──────────────────────────────────────────────────────────────────────────────
# PUSH: fan-out failure handling
# ──────────────────────────────────────────────────────────────────────────────

test_push_continues_past_failure() {
    test_case "push continues past a mid-fanout failure and summarizes"
    make_conf 'github-app   APP_ID           data-wise/flow-cli
github-app   APP_PRIVATE_KEY  data-wise/flow-cli'
    # gh: auth ok; secret set succeeds for APP_ID, fails for APP_PRIVATE_KEY.
    # Log every attempted set so we can confirm the loop did not abort early.
    GH_SET_LOG="$(mktemp -t tok-sync-set.XXXXXX)"
    create_mock gh "
        if [[ \"\$1\" == auth ]]; then return 0; fi
        if [[ \"\$1\" == secret && \"\$2\" == set ]]; then
            cat >/dev/null 2>&1
            echo \"\${@: -1}\" >> '$GH_SET_LOG'
            if [[ \"\${@: -1}\" == APP_PRIVATE_KEY ]]; then return 1; fi
            return 0
        fi
        return 0
    "

    local out; out="$(_tok_sync_push github-app "secretvalue" 2>&1 <<< "y")"; local rc=$?
    local attempted; attempted="$(grep -c . "$GH_SET_LOG" 2>/dev/null)"
    local first_ok="" second_ok=""
    grep -q APP_ID "$GH_SET_LOG" && first_ok=1
    grep -q APP_PRIVATE_KEY "$GH_SET_LOG" && second_ok=1
    reset_mocks
    teardown_gh
    teardown_conf

    assert_exit_code "$rc" 1 || return
    assert_equals "$attempted" "2" || return
    assert_equals "$first_ok" "1" || return
    assert_equals "$second_ok" "1" || return
    assert_contains "$out" "1 of 2" || return
    assert_contains "$out" "push(es) failed" && test_pass
}

test_push_noop_gh_unauthenticated() {
    test_case "push is a non-fatal no-op when gh is unauthenticated; never writes"
    make_conf 'github-app   APP_ID   data-wise/flow-cli'
    # gh present but auth status fails. secret set would write a sentinel if reached.
    local sentinel; sentinel="$(mktemp -t tok-sync-sentinel.XXXXXX)"
    rm -f "$sentinel"
    create_mock gh "
        if [[ \"\$1\" == auth ]]; then return 1; fi
        if [[ \"\$1\" == secret && \"\$2\" == set ]]; then
            cat >/dev/null 2>&1
            echo set > '$sentinel'
            return 0
        fi
        return 0
    "

    local out; out="$(_tok_sync_push github-app "secretvalue" 2>&1 <<< "y")"; local rc=$?
    local reached=""
    [[ -f "$sentinel" ]] && reached=1
    reset_mocks
    rm -f "$sentinel"
    teardown_conf

    assert_exit_code "$rc" 0 || return
    assert_empty "$reached" || return
    assert_contains "$out" "not authenticated" && test_pass
}

test_push_multiline_value_via_stdin() {
    test_case "a multi-line PEM value is piped to gh intact on stdin (never argv)"
    local capture; capture="$(mktemp -t tok-sync-stdin.XXXXXX)"
    local pem=$'-----BEGIN PRIVATE KEY-----\nLINE1\nLINE2\n-----END PRIVATE KEY-----'
    make_conf 'github-app   APP_PRIVATE_KEY   data-wise/flow-cli'
    create_mock gh "
        if [[ \"\$1\" == auth ]]; then return 0; fi
        if [[ \"\$1\" == secret && \"\$2\" == set ]]; then cat > '$capture'; return 0; fi
        return 0
    "

    _tok_sync_push github-app "$pem" >/dev/null 2>&1 <<< "y"
    local stdin_got; stdin_got="$(cat "$capture")"
    local argv="${MOCK_ARGS[gh]}"
    reset_mocks
    rm -f "$capture"
    teardown_conf

    assert_equals "$stdin_got" "$pem" || return
    assert_not_contains "$argv" "LINE1" || return
    assert_not_contains "$argv" "BEGIN PRIVATE KEY" && test_pass
}

test_push_mixed_oidc_and_push() {
    test_case "for one name, push rows are pushed while oidc rows are skipped"
    make_conf 'multi   GH_SECRET    data-wise/flow-cli
multi   PYPI_TOKEN   data-wise/nexus-cli   oidc'
    GH_SET_LOG="$(mktemp -t tok-sync-set.XXXXXX)"
    create_mock gh "
        if [[ \"\$1\" == auth ]]; then return 0; fi
        if [[ \"\$1\" == secret && \"\$2\" == set ]]; then
            cat >/dev/null 2>&1
            echo \"\${@: -1}\" >> '$GH_SET_LOG'
            return 0
        fi
        return 0
    "

    local out; out="$(_tok_sync_push multi "secretvalue" 2>&1 <<< "y")"; local rc=$?
    local pushed_normal="" pushed_oidc=""
    grep -q GH_SECRET "$GH_SET_LOG" && pushed_normal=1
    grep -q PYPI_TOKEN "$GH_SET_LOG" && pushed_oidc=1
    reset_mocks
    teardown_gh
    teardown_conf

    assert_exit_code "$rc" 0 || return
    assert_equals "$pushed_normal" "1" || return
    assert_empty "$pushed_oidc" || return
    assert_contains "$out" "OIDC" && test_pass
}

# ──────────────────────────────────────────────────────────────────────────────
# RESOLVE VALUE
# ──────────────────────────────────────────────────────────────────────────────

test_resolve_value_reads_from_sec() {
    test_case "resolve_value reads the token value from the sec vault"
    create_mock sec 'printf "vaultsecret"'
    local got="$(_tok_sync_resolve_value github-app)"
    reset_mocks
    assert_equals "$got" "vaultsecret" && test_pass
}

# ──────────────────────────────────────────────────────────────────────────────
# MAIN
# ──────────────────────────────────────────────────────────────────────────────

main() {
    test_suite_start "Tok Auto-Sync Foundation"

    setup

    test_functions_exist
    test_conf_path_uses_env
    test_conf_path_default
    test_load_targets_parses_matching_name
    test_load_targets_emits_oidc_flag
    test_load_targets_missing_conf_empty
    test_load_targets_rejects_bad_repo
    test_load_targets_rejects_bad_secret
    test_load_targets_bad_row_warns
    test_load_targets_skips_tab_only_line
    test_load_targets_skips_indented_comment
    test_load_targets_skips_cr_blank_line
    test_push_rejects_invalid_name
    test_push_noop_missing_gh
    test_push_noop_zero_targets
    test_push_noop_empty_value
    test_push_confirm_no_skips_writes
    test_push_confirm_yes_pushes_each_row
    test_push_value_via_stdin
    test_push_oidc_row_not_pushed
    test_push_continues_past_failure
    test_push_noop_gh_unauthenticated
    test_push_multiline_value_via_stdin
    test_push_mixed_oidc_and_push
    test_resolve_value_reads_from_sec

    test_suite_end
    exit $?
}

main "$@"
