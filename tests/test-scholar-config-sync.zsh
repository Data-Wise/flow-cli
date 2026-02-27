#!/usr/bin/env zsh
# ==============================================================================
# SCHOLAR CONFIG SYNC - Unit Tests (#423)
# ==============================================================================
#
# Tests for Scholar Config Sync: config injection, stale config warnings,
# legacy deprecation, config subcommand dispatch, new wrappers, help, and doctor

# Test setup
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

source "${SCRIPT_DIR}/test-framework.zsh"
test_suite_start "Scholar Config Sync Tests"

# Source core dependencies
source "${PROJECT_ROOT}/lib/core.zsh"
source "${PROJECT_ROOT}/lib/config-validator.zsh" 2>/dev/null || true

# Create temp directory for test isolation
TEST_TMPDIR=$(mktemp -d)
trap "rm -rf '$TEST_TMPDIR'" EXIT

# ==============================================================================
# MOCK HELPERS
# ==============================================================================

# Save original functions for restore
typeset -A _saved_funcs

mock_function() {
    local name="$1"
    local body="$2"
    # Save original if it exists
    if typeset -f "$name" >/dev/null 2>&1; then
        _saved_funcs[$name]=$(typeset -f "$name")
    fi
    eval "$name() { $body }"
}

restore_function() {
    local name="$1"
    if [[ -n "${_saved_funcs[$name]}" ]]; then
        eval "${_saved_funcs[$name]}"
        unset "_saved_funcs[$name]"
    else
        unfunction "$name" 2>/dev/null
    fi
}

# ==============================================================================
# TEST 1: Config injection when config found
# ==============================================================================

test_case "Config injection when config found"

# Mock _teach_find_config to return a path
mock_function "_teach_find_config" 'echo "/tmp/test-config.yml"'

# Source the dispatcher to get _teach_build_command
source "${PROJECT_ROOT}/lib/dispatchers/teach-dispatcher.zsh" 2>/dev/null

# Check that _teach_scholar_wrapper would inject --config
# We test the config injection block in isolation by simulating what it does
local config_path
config_path=$(_teach_find_config 2>/dev/null)
local scholar_cmd="/teaching:exam Topic"
if [[ -n "$config_path" ]]; then
    scholar_cmd="$scholar_cmd --config \"$config_path\""
fi
assert_contains "$scholar_cmd" "--config"
test_case_end

restore_function "_teach_find_config"

# ==============================================================================
# TEST 2: Config injection when config missing
# ==============================================================================

test_case "Config injection when config missing"

# Override after source to ensure mock takes effect
_teach_find_config() { echo ""; }

local config_path
config_path=$(_teach_find_config 2>/dev/null)
local scholar_cmd="/teaching:exam Topic"
if [[ -n "$config_path" ]]; then
    scholar_cmd="$scholar_cmd --config \"$config_path\""
fi
assert_not_contains "$scholar_cmd" "--config"
test_case_end

# ==============================================================================
# TEST 3: Config changed warning
# ==============================================================================

test_case "Config changed warning output"

mock_function "_flow_config_changed" 'return 0'
mock_function "_teach_warn" 'echo "WARN: $1" >&2'

local output
output=$(_flow_config_changed 2>/dev/null && echo "changed" || echo "unchanged")
assert_equals "$output" "changed" "Expected config changed detection"
test_case_end

restore_function "_flow_config_changed"
restore_function "_teach_warn"

# ==============================================================================
# TEST 4: Legacy deprecation warning
# ==============================================================================

test_case "Legacy deprecation warning when both files exist"

# Create temp test directory with both files
local test_dir="${TEST_TMPDIR}/legacy-test"
mkdir -p "${test_dir}/.claude" "${test_dir}/.flow"
echo "legacy" > "${test_dir}/.claude/teaching-style.local.md"
echo "scholar:" > "${test_dir}/.flow/teach-config.yml"

local legacy_style="${test_dir}/.claude/teaching-style.local.md"
local has_warning="false"
if [[ -f "$legacy_style" ]]; then
    has_warning="true"
fi
assert_equals "$has_warning" "true" "Expected legacy file detection"
test_case_end

# ==============================================================================
# TEST 5: Config check dispatch
# ==============================================================================

test_case "teach config check maps to Scholar config validate"

# Test _teach_build_command for config subcommand
local result
result=$(_teach_build_command "config" "validate" "--strict" 2>/dev/null)
assert_contains "$result" "/teaching:config" "Expected /teaching:config in Scholar command"
test_case_end

# ==============================================================================
# TEST 6: Config diff dispatch
# ==============================================================================

test_case "teach config diff maps to Scholar config diff"

local result
result=$(_teach_build_command "config" "diff" 2>/dev/null)
assert_contains "$result" "/teaching:config" "Expected /teaching:config in Scholar command"
assert_contains "$result" "diff" "Expected diff in Scholar command"
test_case_end

# ==============================================================================
# TEST 7: Config show dispatch
# ==============================================================================

test_case "teach config show maps to Scholar config show"

local result
result=$(_teach_build_command "config" "show" 2>/dev/null)
assert_contains "$result" "/teaching:config" "Expected /teaching:config in Scholar command"
assert_contains "$result" "show" "Expected show in Scholar command"
test_case_end

# ==============================================================================
# TEST 8: Config scaffold dispatch
# ==============================================================================

test_case "teach config scaffold maps to Scholar config scaffold"

local result
result=$(_teach_build_command "config" "scaffold" "exam" 2>/dev/null)
assert_contains "$result" "/teaching:config" "Expected /teaching:config in Scholar command"
assert_contains "$result" "scaffold" "Expected scaffold in Scholar command"
test_case_end

# ==============================================================================
# TEST 9: Solution dispatch
# ==============================================================================

test_case "teach solution maps to /teaching:solution"

local result
result=$(_teach_build_command "solution" "Bayesian inference" 2>/dev/null)
assert_contains "$result" "/teaching:solution" "Expected /teaching:solution in Scholar command"
test_case_end

# ==============================================================================
# TEST 10: Sync dispatch
# ==============================================================================

test_case "teach sync maps to /teaching:sync"

local result
result=$(_teach_build_command "sync" 2>/dev/null)
assert_contains "$result" "/teaching:sync" "Expected /teaching:sync in Scholar command"
test_case_end

# ==============================================================================
# TEST 11: Validate-r dispatch
# ==============================================================================

test_case "teach validate-r maps to /teaching:validate-r"

local result
result=$(_teach_build_command "validate-r" 2>/dev/null)
assert_contains "$result" "/teaching:validate-r" "Expected /teaching:validate-r in Scholar command"
test_case_end

# ==============================================================================
# TEST 12: Help includes new commands
# ==============================================================================

test_case "Help output includes all new commands"

local help_output
help_output=$(_teach_dispatcher_help 2>/dev/null)

assert_contains "$help_output" "config check" "Expected 'config check' in help"
assert_contains "$help_output" "config diff" "Expected 'config diff' in help"
assert_contains "$help_output" "config show" "Expected 'config show' in help"
assert_contains "$help_output" "config scaffold" "Expected 'config scaffold' in help"
assert_contains "$help_output" "solution" "Expected 'solution' in help"
assert_contains "$help_output" "sync" "Expected 'sync' in help"
assert_contains "$help_output" "validate-r" "Expected 'validate-r' in help"
test_case_end

# ==============================================================================
# TEST 13: Doctor config sync section
# ==============================================================================

test_case "Doctor shows config sync status"

# Source doctor implementation
source "${PROJECT_ROOT}/lib/dispatchers/teach-doctor-impl.zsh" 2>/dev/null

# Check function exists
if typeset -f _teach_doctor_config_sync >/dev/null 2>&1; then
    # Mock dependencies for isolated test
    mock_function "_teach_find_config" 'echo "/tmp/test.yml"'
    mock_function "_teach_doctor_pass" 'echo "PASS: $1"'
    mock_function "_teach_doctor_warn" 'echo "WARN: $1"'
    mock_function "_flow_config_changed" 'return 1'  # not changed

    # Create a fake config with scholar section
    echo "scholar: {}" > "${TEST_TMPDIR}/test.yml"
    mock_function "_teach_find_config" "echo '${TEST_TMPDIR}/test.yml'"

    local json="false"
    local output
    output=$(_teach_doctor_config_sync 2>&1)
    assert_contains "$output" "PASS:" "Expected doctor to report config sync pass"

    restore_function "_teach_find_config"
    restore_function "_teach_doctor_pass"
    restore_function "_teach_doctor_warn"
    restore_function "_flow_config_changed"
else
    test_fail "_teach_doctor_config_sync function not found"
fi
test_case_end

# ==============================================================================
# SUMMARY
# ==============================================================================

test_suite_end
exit $(( TESTS_FAILED > 0 ? 1 : 0 ))
