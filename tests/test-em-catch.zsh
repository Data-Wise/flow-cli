#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: Email Catch (email-to-task capture)
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Validate _em_catch function (AI summarize -> catch integration)
# Tests: arg validation, AI summary path, subject fallback, catch cmd presence
#
# Created: 2026-02-18
# ══════════════════════════════════════════════════════════════════════════════

# Source shared test framework
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# ══════════════════════════════════════════════════════════════════════════════
# SETUP / CLEANUP
# ══════════════════════════════════════════════════════════════════════════════

# Save original function bodies for restoration
typeset -g _SAVED_HML_READ=""
typeset -g _SAVED_AI_QUERY=""
typeset -g _SAVED_HML_LIST=""
typeset -g _SAVED_REQUIRE_HML=""

setup() {
    typeset -g project_root=""
    if [[ -n "${0:A}" ]]; then project_root="${0:A:h:h}"; fi
    if [[ -z "$project_root" || ! -f "$project_root/flow.plugin.zsh" ]]; then
        if [[ -f "$PWD/flow.plugin.zsh" ]]; then project_root="$PWD"
        elif [[ -f "$PWD/../flow.plugin.zsh" ]]; then project_root="$PWD/.."
        fi
    fi
    [[ -z "$project_root" || ! -f "$project_root/flow.plugin.zsh" ]] && { echo "ERROR: Cannot find project root"; exit 1; }

    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$project_root"
    exec < /dev/null  # Non-interactive
    source "$project_root/flow.plugin.zsh"

    # Save originals for restoration
    _SAVED_HML_READ="$(whence -f _em_hml_read 2>/dev/null)"
    _SAVED_AI_QUERY="$(whence -f _em_ai_query 2>/dev/null)"
    _SAVED_HML_LIST="$(whence -f _em_hml_list 2>/dev/null)"
    _SAVED_REQUIRE_HML="$(whence -f _em_require_himalaya 2>/dev/null)"

    # Always let _em_require_himalaya pass in tests
    _em_require_himalaya() { return 0; }
}

_restore_functions() {
    [[ -n "$_SAVED_HML_READ" ]] && eval "$_SAVED_HML_READ"
    [[ -n "$_SAVED_AI_QUERY" ]] && eval "$_SAVED_AI_QUERY"
    [[ -n "$_SAVED_HML_LIST" ]] && eval "$_SAVED_HML_LIST"
    [[ -n "$_SAVED_REQUIRE_HML" ]] && eval "$_SAVED_REQUIRE_HML"
}

cleanup() {
    reset_mocks
    _restore_functions
    unset FLOW_EMAIL_AI
}
trap cleanup EXIT

# ═══════════════════════════════════════════════════════════════
# Section 1: _em_catch Requires ID
# ═══════════════════════════════════════════════════════════════

test_catch_requires_id() {
    test_case "_em_catch with no args returns 1"
    local output
    output=$(_em_catch 2>&1)
    if [[ $? -eq 1 ]]; then
        test_pass
    else
        test_fail "Expected exit code 1 when no ID provided"
    fi
}

test_catch_no_id_shows_error() {
    test_case "_em_catch with no args shows error message"
    local output
    output=$(_em_catch 2>&1)
    if [[ "$output" == *"ID required"* || "$output" == *"Usage:"* ]]; then
        test_pass
    else
        test_fail "Expected error about ID required, got: $output"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Section 2: _em_catch with AI Summary
# ═══════════════════════════════════════════════════════════════

test_catch_with_ai_summary() {
    test_case "_em_catch with AI summary includes summary text"

    # Override functions directly (avoids create_mock eval issues)
    _em_hml_read() { echo "Dear Prof, I will be absent on Friday. Thanks, Student"; }
    _em_ai_query() { echo "Student absent Friday, requests notes"; }
    catch() { true; }

    export FLOW_EMAIL_AI="claude"
    local output
    output=$(_em_catch "42" 2>&1)

    if [[ "$output" == *"Student absent Friday"* || "$output" == *"Captured:"* ]]; then
        test_pass
    else
        test_fail "Expected output to include AI summary, got: $output"
    fi

    # Restore
    _restore_functions
    unset -f catch 2>/dev/null
    _em_require_himalaya() { return 0; }
}

test_catch_ai_query_is_used() {
    test_case "_em_catch uses AI query result in output"

    # Use a unique marker to verify AI query output is used
    _em_hml_read() { echo "Email body content here"; }
    _em_ai_query() { echo "UNIQUE_AI_MARKER_12345"; }
    catch() { true; }

    export FLOW_EMAIL_AI="claude"
    local output
    output=$(_em_catch "99" 2>&1)

    if [[ "$output" == *"UNIQUE_AI_MARKER_12345"* ]]; then
        test_pass
    else
        test_fail "Expected AI query result in output, got: $output"
    fi

    _restore_functions
    unset -f catch 2>/dev/null
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# Section 3: _em_catch Fallback to Subject
# ═══════════════════════════════════════════════════════════════

test_catch_fallback_to_subject() {
    test_case "_em_catch falls back to subject when AI fails"

    _em_hml_read() { echo "Some email body"; }
    _em_ai_query() { return 1; }
    _em_hml_list() { echo '[{"id":"55","subject":"Homework submission question"}]'; }
    catch() { true; }

    export FLOW_EMAIL_AI="claude"
    local output
    output=$(_em_catch "55" 2>&1)

    if [[ "$output" == *"Homework submission"* || "$output" == *"Captured:"* ]]; then
        test_pass
    else
        test_fail "Expected subject line fallback, got: $output"
    fi

    _restore_functions
    unset -f catch 2>/dev/null
    _em_require_himalaya() { return 0; }
}

test_catch_no_summary_no_subject_fails() {
    test_case "_em_catch fails when no summary and no subject available"

    _em_hml_read() { echo "Email body"; }
    _em_ai_query() { return 1; }
    _em_hml_list() { echo '[]'; }

    export FLOW_EMAIL_AI="claude"
    local output
    output=$(_em_catch "77" 2>&1)

    if [[ $? -eq 1 || "$output" == *"Could not generate summary"* ]]; then
        test_pass
    else
        test_fail "Expected failure when no summary available, got: $output"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# Section 4: _em_catch Without catch Command
# ═══════════════════════════════════════════════════════════════

test_catch_without_catch_cmd() {
    test_case "_em_catch without catch command shows display-only output"

    _em_hml_read() { echo "Email body content"; }
    _em_ai_query() { echo "Quick summary of email"; }

    # Make sure catch function does NOT exist
    unset -f catch 2>/dev/null

    export FLOW_EMAIL_AI="claude"
    local output
    output=$(_em_catch "30" 2>&1)

    if [[ "$output" == *"Capture:"* || "$output" == *"copy manually"* || "$output" == *"catch command not available"* ]]; then
        test_pass
    else
        test_fail "Expected display-only output, got: $output"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# Section 5: _em_catch With catch Command
# ═══════════════════════════════════════════════════════════════

test_catch_with_catch_cmd() {
    test_case "_em_catch with catch command shows Captured message"

    _em_hml_read() { echo "Email body content"; }
    _em_ai_query() { echo "Meeting moved to Thursday"; }
    catch() { true; }

    export FLOW_EMAIL_AI="claude"
    local output
    output=$(_em_catch "12" 2>&1)

    # When catch exists, _em_catch shows "Captured:" via _flow_log_success
    if [[ "$output" == *"Captured:"* || "$output" == *"Meeting moved"* ]]; then
        test_pass
    else
        test_fail "Expected Captured message, got: $output"
    fi

    _restore_functions
    unset -f catch 2>/dev/null
    _em_require_himalaya() { return 0; }
}

test_catch_formats_string_with_id() {
    test_case "_em_catch passes formatted string with email ID to catch"

    _em_hml_read() { echo "Email body content"; }
    _em_ai_query() { echo "Grade inquiry from student"; }

    # Use a catch that records its argument to a temp file
    typeset -g _CATCH_TEST_TMPFILE=$(mktemp)
    catch() { echo "$*" > "$_CATCH_TEST_TMPFILE"; }

    export FLOW_EMAIL_AI="claude"
    _em_catch "88" &>/dev/null

    local caught_args=""
    [[ -f "$_CATCH_TEST_TMPFILE" ]] && caught_args=$(cat "$_CATCH_TEST_TMPFILE")
    rm -f "$_CATCH_TEST_TMPFILE" 2>/dev/null

    if [[ "$caught_args" == *"#88"* && "$caught_args" == *"Grade inquiry"* ]]; then
        test_pass
    else
        test_fail "Expected catch args with '#88' and summary, got: '$caught_args'"
    fi

    _restore_functions
    unset -f catch 2>/dev/null
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════

main() {
    test_suite_start "Email Catch (email-to-task capture)"

    setup

    echo "${CYAN}Section 1: _em_catch Requires ID${RESET}"
    test_catch_requires_id
    test_catch_no_id_shows_error
    echo ""

    echo "${CYAN}Section 2: _em_catch with AI Summary${RESET}"
    test_catch_with_ai_summary
    test_catch_ai_query_is_used
    echo ""

    echo "${CYAN}Section 3: _em_catch Fallback to Subject${RESET}"
    test_catch_fallback_to_subject
    test_catch_no_summary_no_subject_fails
    echo ""

    echo "${CYAN}Section 4: _em_catch Without catch Command${RESET}"
    test_catch_without_catch_cmd
    echo ""

    echo "${CYAN}Section 5: _em_catch With catch Command${RESET}"
    test_catch_with_catch_cmd
    test_catch_formats_string_with_id
    echo ""

    cleanup
    test_suite_end
    exit $?
}

# Run tests
main
