#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: Em v2.0 - Security Validation
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Validate input sanitization and injection prevention for the em
#          dispatcher v2.0. Tests message ID validation, folder name validation,
#          config safe-parsing, and AI argument sanitization.
#
# Functions under test:
#   _em_validate_msg_id       - Numeric message ID validation
#   _em_validate_folder_name  - Folder name safety checks
#   _em_load_config           - Safe config parser (no eval injection)
#   _em_ai_validate_extra_args - AI subcommand argument sanitization
#
# Created: 2026-02-26 (TDD — tests first)
# ══════════════════════════════════════════════════════════════════════════════

# Source shared test framework
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# ============================================================================
# SETUP / CLEANUP
# ============================================================================

setup() {
    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$PROJECT_ROOT"
    exec < /dev/null

    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null
}

cleanup() {
    reset_mocks
}
trap cleanup EXIT

setup

# ============================================================================
# TESTS
# ============================================================================

test_suite_start "Em v2.0 - Security Validation"

# ---------------------------------------------------------------------------
# Function existence
# ---------------------------------------------------------------------------

test_case "_em_validate_msg_id function exists"
assert_function_exists "_em_validate_msg_id" || true
test_pass

test_case "_em_validate_folder_name function exists"
assert_function_exists "_em_validate_folder_name" || true
test_pass

test_case "_em_load_config function exists"
assert_function_exists "_em_load_config" || true
test_pass

test_case "_em_ai_validate_extra_args function exists"
assert_function_exists "_em_ai_validate_extra_args" || true
test_pass

# ---------------------------------------------------------------------------
# Message ID validation
# ---------------------------------------------------------------------------

test_case "Valid numeric message ID '123' accepted"
_em_validate_msg_id "123" 2>/dev/null
assert_exit_code $? 0
test_pass

test_case "Valid large numeric ID '999999' accepted"
_em_validate_msg_id "999999" 2>/dev/null
assert_exit_code $? 0
test_pass

test_case "Alphabetic ID 'abc' rejected"
_em_validate_msg_id "abc" 2>/dev/null
assert_exit_code $? 1
test_pass

test_case "Empty message ID rejected"
_em_validate_msg_id "" 2>/dev/null
assert_exit_code $? 1
test_pass

test_case "Command injection via semicolon rejected: '123; rm -rf /'"
_em_validate_msg_id '123; rm -rf /' 2>/dev/null
assert_exit_code $? 1
test_pass

test_case "Quote injection rejected: '123\"; echo pwned'"
_em_validate_msg_id '123"; echo pwned' 2>/dev/null
assert_exit_code $? 1
test_pass

test_case "Pipe injection rejected: '123 | cat /etc/passwd'"
_em_validate_msg_id '123 | cat /etc/passwd' 2>/dev/null
assert_exit_code $? 1
test_pass

test_case "Backtick injection rejected: '123\`whoami\`'"
_em_validate_msg_id '123`whoami`' 2>/dev/null
assert_exit_code $? 1
test_pass

test_case "Subshell injection rejected: '123\$(id)'"
_em_validate_msg_id '123$(id)' 2>/dev/null
assert_exit_code $? 1
test_pass

test_case "Negative ID '-1' rejected"
_em_validate_msg_id "-1" 2>/dev/null
assert_exit_code $? 1
test_pass

# ---------------------------------------------------------------------------
# Folder name validation
# ---------------------------------------------------------------------------

test_case "Valid folder name 'Archive' accepted"
_em_validate_folder_name "Archive" 2>/dev/null
assert_exit_code $? 0
test_pass

test_case "Valid folder name 'My Folder' accepted (spaces OK)"
_em_validate_folder_name "My Folder" 2>/dev/null
assert_exit_code $? 0
test_pass

test_case "Empty folder name rejected"
_em_validate_folder_name "" 2>/dev/null
assert_exit_code $? 1
test_pass

test_case "Leading dash '-flag' rejected (option injection)"
_em_validate_folder_name "-flag" 2>/dev/null
assert_exit_code $? 1
test_pass

test_case "Slash in folder name 'foo/bar' rejected"
_em_validate_folder_name "foo/bar" 2>/dev/null
assert_exit_code $? 1
test_pass

test_case "Backslash in folder name rejected"
_em_validate_folder_name 'foo\bar' 2>/dev/null
assert_exit_code $? 1
test_pass

test_case "Folder name > 255 chars rejected"
local long_name=$(printf 'a%.0s' {1..256})
_em_validate_folder_name "$long_name" 2>/dev/null
assert_exit_code $? 1
test_pass

test_case "Folder name at exactly 255 chars accepted"
local ok_name=$(printf 'a%.0s' {1..255})
_em_validate_folder_name "$ok_name" 2>/dev/null
assert_exit_code $? 0
test_pass

test_case "Null byte in folder name rejected"
_em_validate_folder_name $'foo\x00bar' 2>/dev/null
assert_exit_code $? 1
test_pass

# ---------------------------------------------------------------------------
# Config safe parser
# ---------------------------------------------------------------------------

test_case "_em_parse_config_file reads allowlisted key=value pairs"
local tmpfile=$(mktemp)
echo 'FLOW_EMAIL_AI=claude' > "$tmpfile"
echo 'FLOW_EMAIL_PAGE_SIZE=25' >> "$tmpfile"
unset FLOW_EMAIL_AI FLOW_EMAIL_PAGE_SIZE 2>/dev/null
_em_parse_config_file "$tmpfile" 2>/dev/null
local rc=$?
rm -f "$tmpfile"
assert_exit_code $rc 0
assert_equals "${FLOW_EMAIL_AI:-}" "claude" "Expected FLOW_EMAIL_AI=claude"
unset FLOW_EMAIL_AI FLOW_EMAIL_PAGE_SIZE 2>/dev/null
test_pass

test_case "_em_parse_config_file does not execute \$(...) in values"
local tmpfile=$(mktemp)
echo 'FLOW_EMAIL_AI=$(whoami)' > "$tmpfile"
unset FLOW_EMAIL_AI 2>/dev/null
_em_parse_config_file "$tmpfile" 2>/dev/null
rm -f "$tmpfile"
# The parser sets the literal string '$(whoami)', NOT the result of execution
# Both literal-string and empty are safe outcomes
if [[ -z "${FLOW_EMAIL_AI:-}" ]]; then
    test_pass  # Parser rejected it entirely — safe
elif [[ "${FLOW_EMAIL_AI}" == '$(whoami)' ]]; then
    test_pass  # Parser stored literal string without executing — safe
else
    test_fail "Config parser executed code: FLOW_EMAIL_AI=$FLOW_EMAIL_AI"
fi
unset FLOW_EMAIL_AI 2>/dev/null

test_case "_em_parse_config_file does not execute backticks in values"
local tmpfile=$(mktemp)
printf 'FLOW_EMAIL_AI=`whoami`\n' > "$tmpfile"
unset FLOW_EMAIL_AI 2>/dev/null
_em_parse_config_file "$tmpfile" 2>/dev/null
rm -f "$tmpfile"
if [[ -z "${FLOW_EMAIL_AI:-}" ]]; then
    test_pass  # Rejected — safe
elif [[ "${FLOW_EMAIL_AI}" == '`whoami`' ]]; then
    test_pass  # Stored literal — safe
else
    test_fail "Config parser executed backticks: FLOW_EMAIL_AI=$FLOW_EMAIL_AI"
fi
unset FLOW_EMAIL_AI 2>/dev/null

test_case "_em_parse_config_file ignores non-allowlisted keys with semicolons"
local tmpfile=$(mktemp)
echo 'account=test; rm -rf /' > "$tmpfile"
unset account 2>/dev/null
_em_parse_config_file "$tmpfile" 2>/dev/null
local rc=$?
rm -f "$tmpfile"
# 'account' is not in the allowlist, so it is silently skipped (rc=0)
assert_exit_code $rc 0
assert_empty "${account:-}" "Non-allowlisted key should not be set"
test_pass

test_case "_em_parse_config_file ignores comment lines"
local tmpfile=$(mktemp)
echo '# This is a comment' > "$tmpfile"
echo 'FLOW_EMAIL_PAGE_SIZE=25' >> "$tmpfile"
unset FLOW_EMAIL_PAGE_SIZE 2>/dev/null
_em_parse_config_file "$tmpfile" 2>/dev/null
local rc=$?
rm -f "$tmpfile"
assert_exit_code $rc 0
assert_equals "${FLOW_EMAIL_PAGE_SIZE:-}" "25" "Expected FLOW_EMAIL_PAGE_SIZE=25"
unset FLOW_EMAIL_PAGE_SIZE 2>/dev/null
test_pass

# ---------------------------------------------------------------------------
# AI extra args validation
# ---------------------------------------------------------------------------

test_case "Valid AI args '--model gpt4' accepted"
_em_ai_validate_extra_args "--model gpt4" 2>/dev/null
assert_exit_code $? 0
test_pass

test_case "Semicolon injection in AI args rejected"
_em_ai_validate_extra_args "; rm -rf /" 2>/dev/null
assert_exit_code $? 1
test_pass

test_case "Pipe injection in AI args rejected"
_em_ai_validate_extra_args "| cat /etc/passwd" 2>/dev/null
assert_exit_code $? 1
test_pass

test_case "Backtick injection in AI args rejected"
_em_ai_validate_extra_args '`whoami`' 2>/dev/null
assert_exit_code $? 1
test_pass

test_case "Subshell injection in AI args rejected"
_em_ai_validate_extra_args '$(id)' 2>/dev/null
assert_exit_code $? 1
test_pass

test_suite_end
exit $?
