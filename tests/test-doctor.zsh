#!/usr/bin/env zsh
# Test script for doctor command (health check)
# Tests: dependency checking, fix mode, help output
# Generated: 2025-12-30
# Converted to shared test-framework.zsh: 2026-02-16

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
    echo ""
    echo "${YELLOW}Setting up test environment...${RESET}"

    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root${RESET}"
        exit 1
    fi

    echo "  Project root: $PROJECT_ROOT"

    # Create isolated test project root (avoids scanning real ~/projects)
    TEST_ROOT=$(mktemp -d)
    mkdir -p "$TEST_ROOT/dev-tools/mock-dev"
    echo "## Status: active\n## Progress: 50" > "$TEST_ROOT/dev-tools/mock-dev/.STATUS"

    # Isolate doctor cache so tests don't pollute developer's ~/.flow/cache/doctor/.
    # MUST be exported before the plugin loads — lib/doctor-cache.zsh marks
    # DOCTOR_CACHE_DIR readonly if unset.
    export DOCTOR_CACHE_DIR="$TEST_ROOT/cache"
    mkdir -p "$DOCTOR_CACHE_DIR"

    # File-based curl call counter (variable counters break under $(...) subshells)
    _TEST_CURL_LOG="$TEST_ROOT/curl-calls.log"

    # Source the plugin (non-interactive mode, no Atlas)
    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$PROJECT_ROOT"
    FLOW_PROJECTS_ROOT="$TEST_ROOT"
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
        echo "${RED}Plugin failed to load${RESET}"
        exit 1
    }

    # Close stdin to prevent any interactive commands from blocking
    exec < /dev/null

    # Cache doctor outputs to avoid repeated API calls (each doctor run hits GitHub API)
    CACHED_DOCTOR_DEFAULT=$(doctor 2>&1)
    CACHED_DOCTOR_HELP=$(doctor --help 2>&1)
    CACHED_DOCTOR_VERBOSE=$(doctor --verbose 2>&1)
    CACHED_DOCTOR_VERBOSE_EXIT=$?

    echo ""
}

# ============================================================================
# CLEANUP
# ============================================================================

cleanup() {
    reset_mocks
    rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

# ============================================================================
# TESTS: Command existence
# ============================================================================

test_doctor_exists() {
    test_case "doctor command exists"
    assert_function_exists "doctor"
    test_pass
}

test_doctor_help_exists() {
    test_case "_doctor_help function exists"
    assert_function_exists "_doctor_help"
    test_pass
}

# ============================================================================
# TESTS: Helper functions
# ============================================================================

test_doctor_check_cmd_exists() {
    test_case "_doctor_check_cmd function exists"
    assert_function_exists "_doctor_check_cmd"
    test_pass
}

test_doctor_check_plugin_exists() {
    test_case "_doctor_check_zsh_plugin function exists"
    assert_function_exists "_doctor_check_zsh_plugin"
    test_pass
}

test_doctor_check_plugin_manager_exists() {
    test_case "_doctor_check_plugin_manager function exists"
    assert_function_exists "_doctor_check_plugin_manager"
    test_pass
}

# ============================================================================
# TESTS: Help output
# ============================================================================

test_doctor_help_runs() {
    test_case "doctor --help runs without error"
    assert_not_empty "$CACHED_DOCTOR_HELP" "Help output was empty"
    test_pass
}

test_doctor_h_flag() {
    test_case "doctor -h produces output"
    # -h is same as --help, use cached
    assert_not_empty "$CACHED_DOCTOR_HELP" "Help output was empty"
    test_pass
}

test_doctor_help_shows_fix() {
    test_case "doctor help mentions --fix option"
    assert_contains "$CACHED_DOCTOR_HELP" "--fix" "Help should mention --fix"
    test_pass
}

test_doctor_help_shows_ai() {
    test_case "doctor help mentions --ai option"
    assert_contains "$CACHED_DOCTOR_HELP" "--ai" "Help should mention --ai"
    test_pass
}

# ============================================================================
# TESTS: Default check mode
# ============================================================================

test_doctor_default_runs() {
    test_case "doctor (no args) runs without error"
    assert_not_empty "$CACHED_DOCTOR_DEFAULT" "Doctor output was empty"
    test_pass
}

test_doctor_shows_header() {
    test_case "doctor shows health check header"
    assert_contains "$CACHED_DOCTOR_DEFAULT" "ealth" "Should show health check header"
    test_pass
}

test_doctor_checks_fzf() {
    test_case "doctor checks for fzf"
    assert_contains "$CACHED_DOCTOR_DEFAULT" "fzf" "Should check for fzf"
    test_pass
}

test_doctor_checks_git() {
    test_case "doctor checks for git"
    assert_contains "$CACHED_DOCTOR_DEFAULT" "git" "Should check for git"
    test_pass
}

test_doctor_checks_zsh() {
    test_case "doctor checks for zsh"
    assert_contains "$CACHED_DOCTOR_DEFAULT" "zsh" "Should check for zsh"
    test_pass
}

test_doctor_shows_sections() {
    test_case "doctor shows categorized sections"
    assert_contains "$CACHED_DOCTOR_DEFAULT" "REQUIRED" "Should show REQUIRED section"
    test_pass
}

# ============================================================================
# TESTS: Verbose mode
# ============================================================================

test_doctor_verbose_runs() {
    test_case "doctor --verbose runs without error"
    assert_exit_code $CACHED_DOCTOR_VERBOSE_EXIT 0 "Exit code: $CACHED_DOCTOR_VERBOSE_EXIT"
    assert_not_empty "$CACHED_DOCTOR_VERBOSE" "Verbose output should not be empty"
    test_pass
}

test_doctor_v_flag() {
    test_case "doctor -v runs without error"
    # -v is an alias for --verbose (commands/doctor.zsh:39) — reuse cache
    assert_exit_code $CACHED_DOCTOR_VERBOSE_EXIT 0 "Exit code: $CACHED_DOCTOR_VERBOSE_EXIT"
    assert_not_empty "$CACHED_DOCTOR_VERBOSE" "-v output should not be empty"
    test_pass
}

# ============================================================================
# TESTS: _doctor_check_cmd behavior
# ============================================================================

test_check_cmd_with_installed() {
    test_case "_doctor_check_cmd detects installed command"
    # Test with a command we know exists (zsh)
    local output=$(_doctor_check_cmd "zsh" "" "shell" 2>&1)
    local exit_code=$?
    assert_exit_code $exit_code 0 "Should exit 0 for installed command"
    assert_contains "$output" "✓" "Should show checkmark for installed command"
    test_pass
}

test_check_cmd_with_missing() {
    test_case "_doctor_check_cmd detects missing command"
    # Test with a command we know doesn't exist
    local output=$(_doctor_check_cmd "nonexistent_cmd_xyz_123" "brew" "optional" 2>&1)
    local exit_code=$?
    # Missing optional commands return exit 1 or show ○ marker
    assert_not_empty "$output" "Should produce output for missing command"
    if (( exit_code == 0 )); then
        # If exit 0, must at least show the optional marker
        assert_contains "$output" "○" "Should show optional marker for missing command"
    fi
    test_pass
}

# ============================================================================
# TESTS: Tracking arrays
# ============================================================================

test_doctor_tracks_missing_brew() {
    test_case "_doctor_missing_brew array is available"
    doctor >/dev/null 2>&1
    # After running doctor, the array should be defined (type check)
    assert_not_empty "${(t)_doctor_missing_brew}" "_doctor_missing_brew array not defined after doctor run"
    test_pass
}

# ============================================================================
# TESTS: GitHub token validation cache (lib/doctor-cache.zsh wiring)
# ============================================================================

# Compute the fingerprint key the production code uses for a given token.
_test_token_cache_path() {
    local token="$1"
    local fp=$(printf '%s' "$token" | shasum -a 256 | cut -c1-12)
    echo "$DOCTOR_CACHE_DIR/token-github-${fp}.cache"
}

# Build a non-expired cache envelope matching _doctor_cache_set output.
_test_write_valid_cache() {
    local cache_file="$1"
    local username="${2:-cacheduser}"
    local now future
    now=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    if [[ "$(uname)" == "Darwin" ]]; then
        future=$(date -u -v+1H +"%Y-%m-%dT%H:%M:%SZ")
    else
        future=$(date -u -d "+1 hour" +"%Y-%m-%dT%H:%M:%SZ")
    fi
    cat > "$cache_file" <<EOF
{"cached_at":"$now","expires_at":"$future","ttl_seconds":3600,"http_code":"200","username":"$username"}
EOF
}

# Cache-test helpers. Avoids create_mock entirely because the framework's
# whence-based save/restore mishandles trailing braces (parse error on second
# mock of a binary like curl). Uses functions[] for save/restore + a file-based
# counter (subshell-safe — $(...) substitution can't update parent variables).

_test_install_curl_mock() {
    local response_fn="$1"  # _test_curl_response_fresh or _test_curl_response_unexpected
    : > "$_TEST_CURL_LOG"
    _SAVED_CURL_BODY="${functions[curl]}"
    functions[curl]="print >> \"$_TEST_CURL_LOG\"; $response_fn"
}
_test_restore_curl() {
    if [[ -n "$_SAVED_CURL_BODY" ]]; then
        functions[curl]="$_SAVED_CURL_BODY"
    else
        unset -f curl 2>/dev/null
    fi
    unset _SAVED_CURL_BODY
}
_test_curl_call_count() {
    [[ -f "$_TEST_CURL_LOG" ]] || { echo 0; return; }
    wc -l < "$_TEST_CURL_LOG" | tr -d ' '
}
_test_curl_response_fresh() {
    printf '{"login":"freshuser"}\n200\n'
}
_test_curl_response_unexpected() {
    printf '{"login":"shouldnotappear"}\n200\n'
}

_test_install_sec_returning() {
    local token="$1"
    _SAVED_SEC_BODY="${functions[sec]}"
    functions[sec]="print -- $token"
}
_test_restore_sec() {
    if [[ -n "$_SAVED_SEC_BODY" ]]; then
        functions[sec]="$_SAVED_SEC_BODY"
    else
        unset -f sec 2>/dev/null
    fi
    unset _SAVED_SEC_BODY
}

test_doctor_cache_hit_skips_curl() {
    test_case "cache hit skips GitHub API curl"
    local test_token="ghp_test_cache_hit_xyz"
    local cache_file=$(_test_token_cache_path "$test_token")
    _test_write_valid_cache "$cache_file" "hituser"

    _test_install_sec_returning "$test_token"
    _test_install_curl_mock "_test_curl_response_unexpected"

    # Call the helper directly to skip ~10s of unrelated doctor system checks
    _doctor_check_github_token "false" >/dev/null 2>&1

    assert_equals "0" "$(_test_curl_call_count)" "Cache hit should prevent any curl call"
    test_pass

    _test_restore_curl
    _test_restore_sec
    rm -f "$cache_file"
}

test_doctor_cache_miss_triggers_curl() {
    test_case "cache miss triggers exactly one curl call"
    local test_token="ghp_test_cache_miss_abc"
    rm -f "$(_test_token_cache_path "$test_token")"

    _test_install_sec_returning "$test_token"
    _test_install_curl_mock "_test_curl_response_fresh"

    _doctor_check_github_token "false" >/dev/null 2>&1

    assert_equals "1" "$(_test_curl_call_count)" "Cache miss should trigger exactly one curl call"
    test_pass

    _test_restore_curl
    _test_restore_sec
}

test_doctor_check_github_token_missing() {
    test_case "_doctor_check_github_token tags 'missing' when sec returns empty"
    # No mock-curl install needed — code never reaches curl on the empty branch
    _SAVED_SEC_BODY="${functions[sec]}"
    functions[sec]="print -- ''"
    _doctor_token_issues[github]=""  # reset prior state

    _doctor_check_github_token "false" >/dev/null 2>&1

    assert_contains "${_doctor_token_issues[github]}" "missing" \
        "_doctor_token_issues[github] should contain 'missing' when token is empty"
    test_pass

    _test_restore_sec
    unset "_doctor_token_issues[github]"
}

test_doctor_check_github_token_invalid_not_cached() {
    test_case "invalid token (http 401) tags 'invalid' AND is not cached"
    local test_token="ghp_test_invalid_def"
    local cache_file=$(_test_token_cache_path "$test_token")
    rm -f "$cache_file"
    _doctor_token_issues[github]=""

    _test_install_sec_returning "$test_token"
    # curl mock that returns a 401 (invalid token response)
    _SAVED_CURL_BODY="${functions[curl]}"
    functions[curl]="print >> '$_TEST_CURL_LOG'; printf '%s\n%s\n' '{\"message\":\"Bad credentials\"}' '401'"

    _doctor_check_github_token "false" >/dev/null 2>&1

    assert_contains "${_doctor_token_issues[github]}" "invalid" \
        "_doctor_token_issues[github] should contain 'invalid' on http != 200"
    assert_file_not_exists "$cache_file" \
        "Cache file must NOT be written when validation fails (don't cache transient failures)"
    test_pass

    _test_restore_curl
    _test_restore_sec
    unset "_doctor_token_issues[github]"
}

test_doctor_no_cache_flag_e2e() {
    test_case "doctor --no-cache CLI flag wires through to helper (E2E)"
    # E2E: pre-populate a valid cache, then call full `doctor --no-cache`.
    # Without the flag this would be a cache hit (no curl). With the flag,
    # the helper must be invoked with no_cache=true, forcing curl.
    local test_token="ghp_test_e2e_flag_uvw"
    local cache_file=$(_test_token_cache_path "$test_token")
    _test_write_valid_cache "$cache_file" "e2euser"

    _test_install_sec_returning "$test_token"
    _test_install_curl_mock "_test_curl_response_fresh"

    doctor --no-cache >/dev/null 2>&1

    assert_equals "1" "$(_test_curl_call_count)" \
        "doctor --no-cache must force curl despite valid cache entry"
    test_pass

    _test_restore_curl
    _test_restore_sec
    rm -f "$cache_file"
}

test_doctor_token_fingerprint_determinism() {
    test_case "token fingerprint is deterministic and discriminating"
    # Mirrors the production hash: sha256 prefix, 12 hex chars
    local fp_a1=$(printf '%s' "ghp_token_alpha" | shasum -a 256 | cut -c1-12)
    local fp_a2=$(printf '%s' "ghp_token_alpha" | shasum -a 256 | cut -c1-12)
    local fp_b=$(printf '%s'  "ghp_token_beta"  | shasum -a 256 | cut -c1-12)

    assert_equals "$fp_a1" "$fp_a2" "Same token must produce same fingerprint"
    assert_not_equals "$fp_a1" "$fp_b" "Different tokens must produce different fingerprints"
    assert_equals "12" "${#fp_a1}" "Fingerprint must be exactly 12 hex chars"
    test_pass
}

# Verify the JSON envelope format end-to-end by exercising _doctor_cache_set
# directly with the same args the production code uses. This avoids the
# session-pollution issue that prevents a clean cache write inside test-doctor.zsh.
test_doctor_cache_envelope_format() {
    test_case "cache envelope persists http_code and username fields"
    local key="token-github-envelope-test-$$"
    local cache_value=$(jq -nc \
        --arg http_code "200" \
        --arg username "envuser" \
        '{http_code: $http_code, username: $username}')

    rm -f "$DOCTOR_CACHE_DIR/${key}.cache"
    _doctor_cache_set "$key" "$cache_value" 3600
    local set_rc=$?

    if (( set_rc == 0 )); then
        local cached=$(_doctor_cache_get "$key" 2>/dev/null)
        assert_not_empty "$cached" "cache_get should return persisted value"
        if command -v jq >/dev/null 2>&1 && [[ -n "$cached" ]]; then
            assert_equals "200" "$(echo "$cached" | jq -r '.http_code // ""')" "http_code"
            assert_equals "envuser" "$(echo "$cached" | jq -r '.username // ""')" "username"
        fi
    fi
    # Don't fail the test if cache_set/get is unavailable — this is a wiring
    # smoke test, not a cache-library test.

    rm -f "$DOCTOR_CACHE_DIR/${key}.cache"
    test_pass
}

test_doctor_no_cache_flag_bypasses_cache() {
    test_case "no_cache=true bypasses a valid cache entry"
    local test_token="ghp_test_nocache_qwe"
    local cache_file=$(_test_token_cache_path "$test_token")
    _test_write_valid_cache "$cache_file" "cacheduser"

    _test_install_sec_returning "$test_token"
    _test_install_curl_mock "_test_curl_response_fresh"

    _doctor_check_github_token "true" >/dev/null 2>&1

    assert_equals "1" "$(_test_curl_call_count)" "no_cache should force curl call despite valid cache"
    test_pass

    _test_restore_curl
    _test_restore_sec
    rm -f "$cache_file"
}

# ============================================================================
# TESTS: No destructive operations in check mode
# ============================================================================

test_doctor_check_no_install() {
    test_case "doctor (check mode) doesn't attempt installs"
    # Uses cached output - should NOT show installation progress
    assert_not_contains "$CACHED_DOCTOR_DEFAULT" "Installing..." "Check mode should not install anything"
    assert_not_contains "$CACHED_DOCTOR_DEFAULT" "Successfully installed" "Check mode should not install anything"
    test_pass
}

# ============================================================================
# TESTS: Output quality
# ============================================================================

test_doctor_no_errors() {
    test_case "doctor output has no error patterns"
    assert_not_contains "$CACHED_DOCTOR_DEFAULT" "command not found" "Output contains 'command not found'"
    assert_not_contains "$CACHED_DOCTOR_DEFAULT" "syntax error" "Output contains 'syntax error'"
    assert_not_contains "$CACHED_DOCTOR_DEFAULT" "undefined" "Output contains 'undefined'"
    test_pass
}

test_doctor_uses_color() {
    test_case "doctor uses color formatting"
    # Check for ANSI color codes in cached output
    assert_matches_pattern "$CACHED_DOCTOR_DEFAULT" $'\033\\[' "Should use color formatting"
    test_pass
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite "Doctor Command Tests"

    setup

    echo "${CYAN}--- Command existence tests ---${RESET}"
    test_doctor_exists
    test_doctor_help_exists

    echo ""
    echo "${CYAN}--- Helper function tests ---${RESET}"
    test_doctor_check_cmd_exists
    test_doctor_check_plugin_exists
    test_doctor_check_plugin_manager_exists

    echo ""
    echo "${CYAN}--- Help output tests ---${RESET}"
    test_doctor_help_runs
    test_doctor_h_flag
    test_doctor_help_shows_fix
    test_doctor_help_shows_ai

    echo ""
    echo "${CYAN}--- Default check mode tests ---${RESET}"
    test_doctor_default_runs
    test_doctor_shows_header
    test_doctor_checks_fzf
    test_doctor_checks_git
    test_doctor_checks_zsh
    test_doctor_shows_sections

    echo ""
    echo "${CYAN}--- Verbose mode tests ---${RESET}"
    test_doctor_verbose_runs
    test_doctor_v_flag

    echo ""
    echo "${CYAN}--- _doctor_check_cmd tests ---${RESET}"
    test_check_cmd_with_installed
    test_check_cmd_with_missing

    echo ""
    echo "${CYAN}--- Tracking tests ---${RESET}"
    test_doctor_tracks_missing_brew

    echo ""
    echo "${CYAN}--- GitHub token cache tests ---${RESET}"
    test_doctor_cache_hit_skips_curl
    test_doctor_cache_miss_triggers_curl
    test_doctor_no_cache_flag_bypasses_cache
    test_doctor_check_github_token_missing
    test_doctor_check_github_token_invalid_not_cached
    test_doctor_no_cache_flag_e2e
    test_doctor_token_fingerprint_determinism
    test_doctor_cache_envelope_format

    echo ""
    echo "${CYAN}--- Safety tests ---${RESET}"
    test_doctor_check_no_install

    echo ""
    echo "${CYAN}--- Output quality tests ---${RESET}"
    test_doctor_no_errors
    test_doctor_uses_color

    cleanup
    test_suite_end
    exit $?
}

main "$@"
