#!/usr/bin/env zsh
# Test script for dispatcher enhancements
# Tests new keywords added to r, qu, v, cc dispatchers
# NOTE: Requires external config files - skips gracefully in CI

# Source the test framework
source "${0:A:h}/test-framework.zsh"

# ============================================================================
# CI SKIP GUARD
# ============================================================================

if [[ ! -f "$HOME/.config/zsh/functions/smart-dispatchers.zsh" ]]; then
    echo "SKIP: External config files not found (expected in CI)"
    echo "  Required: ~/.config/zsh/functions/smart-dispatchers.zsh"
    exit 0
fi

# Source the dispatcher files
source "$HOME/.config/zsh/functions/smart-dispatchers.zsh"
source "$HOME/.config/zsh/functions/v-dispatcher.zsh" 2>/dev/null || true

# ============================================================================
# HELPER: capture dispatcher help output
# ============================================================================

_get_help_output() {
    local dispatcher="$1"
    $dispatcher help 2>&1
}

# ============================================================================
# r dispatcher keywords
# ============================================================================

test_suite_start "r dispatcher new keywords"

test_case "r help lists 'r clean' keyword"
output=$(_get_help_output r)
assert_exit_code $? 0 "r help should exit 0"
assert_contains "$output" "r clean" && test_pass

test_case "r help lists 'r deep' keyword"
output=$(_get_help_output r)
assert_contains "$output" "r deep" && test_pass

test_case "r help lists 'r tex' keyword"
output=$(_get_help_output r)
assert_contains "$output" "r tex" && test_pass

test_case "r help lists 'r commit' keyword"
output=$(_get_help_output r)
assert_contains "$output" "r commit" && test_pass

test_case "r help output is non-empty"
output=$(_get_help_output r)
assert_not_empty "$output" && test_pass

# ============================================================================
# qu dispatcher keywords
# ============================================================================

test_suite_start "qu dispatcher new keywords"

test_case "qu help lists 'qu pdf' keyword"
output=$(_get_help_output qu)
assert_exit_code $? 0 "qu help should exit 0"
assert_contains "$output" "qu pdf" && test_pass

test_case "qu help lists 'qu html' keyword"
output=$(_get_help_output qu)
assert_contains "$output" "qu html" && test_pass

test_case "qu help lists 'qu docx' keyword"
output=$(_get_help_output qu)
assert_contains "$output" "qu docx" && test_pass

test_case "qu help lists 'qu commit' keyword"
output=$(_get_help_output qu)
assert_contains "$output" "qu commit" && test_pass

test_case "qu help lists 'qu article' keyword"
output=$(_get_help_output qu)
assert_contains "$output" "qu article" && test_pass

test_case "qu help lists 'qu present' keyword"
output=$(_get_help_output qu)
assert_contains "$output" "qu present" && test_pass

# ============================================================================
# v dispatcher keywords
# ============================================================================

test_suite_start "v dispatcher new keywords"

test_case "v help lists 'v start' keyword"
output=$(_get_help_output v)
assert_exit_code $? 0 "v help should exit 0"
assert_contains "$output" "v start" && test_pass

test_case "v help lists 'v end' keyword"
output=$(_get_help_output v)
assert_contains "$output" "v end" && test_pass

test_case "v help lists 'v morning' keyword"
output=$(_get_help_output v)
assert_contains "$output" "v morning" && test_pass

test_case "v help lists 'v night' keyword"
output=$(_get_help_output v)
assert_contains "$output" "v night" && test_pass

test_case "v help lists 'v progress' keyword"
output=$(_get_help_output v)
assert_contains "$output" "v progress" && test_pass

# ============================================================================
# cc dispatcher keywords
# ============================================================================

test_suite_start "cc dispatcher verification"

test_case "cc help lists 'cc latest' keyword"
output=$(_get_help_output cc)
assert_exit_code $? 0 "cc help should exit 0"
assert_contains "$output" "cc latest" && test_pass

test_case "cc help lists 'cc haiku' keyword"
output=$(_get_help_output cc)
assert_contains "$output" "cc haiku" && test_pass

test_case "cc help lists 'cc sonnet' keyword"
output=$(_get_help_output cc)
assert_contains "$output" "cc sonnet" && test_pass

test_case "cc help lists 'cc opus' keyword"
output=$(_get_help_output cc)
assert_contains "$output" "cc opus" && test_pass

test_case "cc help lists 'cc plan' keyword"
output=$(_get_help_output cc)
assert_contains "$output" "cc plan" && test_pass

test_case "cc help lists 'cc auto' keyword"
output=$(_get_help_output cc)
assert_contains "$output" "cc auto" && test_pass

test_case "cc help lists 'cc yolo' keyword"
output=$(_get_help_output cc)
assert_contains "$output" "cc yolo" && test_pass

# ============================================================================
# Function existence checks
# ============================================================================

test_suite_start "Dispatcher functions exist"

test_case "r dispatcher function exists"
assert_function_exists "r" && test_pass

test_case "qu dispatcher function exists"
assert_function_exists "qu" && test_pass

test_case "cc dispatcher function exists"
assert_function_exists "cc" && test_pass

if (whence -f v >/dev/null 2>&1); then
    test_case "v dispatcher function exists"
    assert_function_exists "v" && test_pass
fi

# ============================================================================
# SUMMARY
# ============================================================================

test_suite_end
exit $?
