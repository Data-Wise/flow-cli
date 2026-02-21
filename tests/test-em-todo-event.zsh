#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST SUITE: Email Todo & Event (action item and calendar extraction)
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Validate _em_todo and _em_event functions (AI extraction + catch integration)
# Tests: arg validation, AI item extraction, subject fallback, batch processing,
#        event JSON parsing, empty event handling, catch command integration
#
# Created: 2026-02-20
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
    unset -f catch 2>/dev/null
}
trap cleanup EXIT

# ═══════════════════════════════════════════════════════════════
# Section 1: _em_todo Requires ID
# ═══════════════════════════════════════════════════════════════

test_todo_requires_id() {
    test_case "_em_todo with no args returns 1"
    local output
    output=$(_em_todo 2>&1)
    if [[ $? -eq 1 ]]; then
        test_pass
    else
        test_fail "Expected exit code 1 when no ID provided"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Section 2: _em_todo with AI Path
# ═══════════════════════════════════════════════════════════════

test_todo_ai_path() {
    test_case "_em_todo uses AI query result to extract action items"

    _em_hml_read() { echo "Please review the draft and submit the form by Friday."; }
    _em_ai_query() { printf "Review draft\nSubmit form"; }
    catch() { true; }

    export FLOW_EMAIL_AI="claude"
    local output
    output=$(_em_todo "42" 2>&1)

    if [[ "$output" == *"Review draft"* || "$output" == *"Submit form"* ]]; then
        test_pass
    else
        test_fail "Expected AI-extracted action items in output, got: $output"
    fi

    _restore_functions
    unset -f catch 2>/dev/null
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# Section 3: _em_todo Fallback to Subject
# ═══════════════════════════════════════════════════════════════

test_todo_fallback_subject() {
    test_case "_em_todo falls back to email subject when AI returns empty"

    _em_hml_read() { echo "Some email body content here."; }
    _em_ai_query() { echo "NONE"; }
    _em_hml_list() { echo '[{"id":"55","subject":"Quarterly report due"}]'; }
    catch() { true; }

    export FLOW_EMAIL_AI="claude"
    local output
    output=$(_em_todo "55" 2>&1)

    if [[ "$output" == *"Quarterly report"* || "$output" == *"Follow up on:"* ]]; then
        test_pass
    else
        test_fail "Expected subject line fallback in output, got: $output"
    fi

    _restore_functions
    unset -f catch 2>/dev/null
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# Section 4: _em_todo with Empty Content
# ═══════════════════════════════════════════════════════════════

test_todo_empty_content_fails() {
    test_case "_em_todo returns error when email content is empty"

    _em_hml_read() { echo ""; }

    export FLOW_EMAIL_AI="claude"
    local output
    output=$(_em_todo "99" 2>&1)

    if [[ $? -eq 1 || "$output" == *"Could not read"* || "$output" == *"Error"* || "$output" == *"error"* ]]; then
        test_pass
    else
        test_fail "Expected error when email content is empty, got: $output"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# Section 5: _em_todo Batch Processing
# ═══════════════════════════════════════════════════════════════

test_todo_batch_processes_each() {
    test_case "_em_todo with multiple IDs processes each one"

    # Use temp file to capture across subshell boundary
    typeset -g _TODO_BATCH_TMPFILE=$(mktemp)
    _em_hml_read() {
        echo "read:$1" >> "$_TODO_BATCH_TMPFILE"
        echo "Email body for id $1"
    }
    _em_ai_query() { echo "Action item for email $2"; }
    catch() { true; }

    export FLOW_EMAIL_AI="claude"
    _em_todo "42" "43" &>/dev/null

    local call_log=""
    [[ -f "$_TODO_BATCH_TMPFILE" ]] && call_log=$(cat "$_TODO_BATCH_TMPFILE")
    rm -f "$_TODO_BATCH_TMPFILE" 2>/dev/null

    if [[ "$call_log" == *"read:42"* && "$call_log" == *"read:43"* ]]; then
        test_pass
    else
        test_fail "Expected both IDs 42 and 43 to be processed, call log: $call_log"
    fi

    _restore_functions
    unset -f catch 2>/dev/null
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# Section 6: _em_event Requires ID
# ═══════════════════════════════════════════════════════════════

test_event_requires_id() {
    test_case "_em_event with no args returns 1"
    local output
    output=$(_em_event 2>&1)
    if [[ $? -eq 1 ]]; then
        test_pass
    else
        test_fail "Expected exit code 1 when no ID provided"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Section 7: _em_event AI JSON Parsing
# ═══════════════════════════════════════════════════════════════

test_event_ai_json_parse() {
    test_case "_em_event parses AI JSON response and displays event details"

    _em_hml_read() { echo "Let's meet in Room 101 on March 1st at 10am for an hour."; }
    _em_ai_query() {
        echo '{"events":[{"title":"Meeting","date":"2026-03-01","time":"10:00","duration_minutes":60,"location":"Room 101","type":"meeting"}]}'
    }
    catch() { true; }

    export FLOW_EMAIL_AI="claude"
    local output
    output=$(_em_event "42" 2>&1)

    if [[ "$output" == *"Meeting"* && "$output" == *"2026-03-01"* ]]; then
        test_pass
    else
        test_fail "Expected parsed event title and date in output, got: $output"
    fi

    _restore_functions
    unset -f catch 2>/dev/null
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# Section 8: _em_event Empty Events Array
# ═══════════════════════════════════════════════════════════════

test_event_empty_events() {
    test_case "_em_event shows no events message when AI returns empty array"

    _em_hml_read() { echo "Thanks for the update. Looking forward to it."; }
    _em_ai_query() { echo '{"events":[]}'; }

    export FLOW_EMAIL_AI="claude"
    local output
    output=$(_em_event "77" 2>&1)

    if [[ "$output" == *"No events"* || "$output" == *"no events"* || $? -eq 0 ]]; then
        test_pass
    else
        test_fail "Expected no events message, got: $output"
    fi

    _restore_functions
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# Section 9: _em_event Feeds catch Command
# ═══════════════════════════════════════════════════════════════

test_event_feeds_catch() {
    test_case "_em_event passes event data to catch command"

    _em_hml_read() { echo "Budget review meeting on March 5th at 2pm."; }
    _em_ai_query() {
        echo '{"events":[{"title":"Budget Review","date":"2026-03-05","time":"14:00","duration_minutes":90,"location":"Conference Room","type":"meeting"}]}'
    }

    typeset -g _EVENT_CATCH_TMPFILE=$(mktemp)
    catch() { echo "$*" >> "$_EVENT_CATCH_TMPFILE"; }

    export FLOW_EMAIL_AI="claude"
    _em_event "88" &>/dev/null

    local caught_args=""
    [[ -f "$_EVENT_CATCH_TMPFILE" ]] && caught_args=$(cat "$_EVENT_CATCH_TMPFILE")
    rm -f "$_EVENT_CATCH_TMPFILE" 2>/dev/null

    if [[ "$caught_args" == *"Budget Review"* && "$caught_args" == *"2026-03-05"* ]]; then
        test_pass
    else
        test_fail "Expected catch called with event title and date, got: '$caught_args'"
    fi

    _restore_functions
    unset -f catch 2>/dev/null
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# Section 10: _em_event Batch Processing
# ═══════════════════════════════════════════════════════════════

test_event_batch() {
    test_case "_em_event with multiple IDs processes each one"

    # Use temp file to capture across subshell boundary
    typeset -g _EVENT_BATCH_TMPFILE=$(mktemp)
    _em_hml_read() {
        echo "read:$1" >> "$_EVENT_BATCH_TMPFILE"
        echo "Meeting scheduled for next week."
    }
    _em_ai_query() {
        echo '{"events":[{"title":"Weekly Sync","date":"2026-03-10","time":"09:00","duration_minutes":30,"location":"","type":"meeting"}]}'
    }
    catch() { true; }

    export FLOW_EMAIL_AI="claude"
    _em_event "42" "43" &>/dev/null

    local call_log=""
    [[ -f "$_EVENT_BATCH_TMPFILE" ]] && call_log=$(cat "$_EVENT_BATCH_TMPFILE")
    rm -f "$_EVENT_BATCH_TMPFILE" 2>/dev/null

    if [[ "$call_log" == *"read:42"* && "$call_log" == *"read:43"* ]]; then
        test_pass
    else
        test_fail "Expected both IDs 42 and 43 to be processed, call log: $call_log"
    fi

    _restore_functions
    unset -f catch 2>/dev/null
    _em_require_himalaya() { return 0; }
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════

main() {
    test_suite_start "Email Todo & Event (action item and calendar extraction)"

    setup

    echo "${CYAN}Section 1: _em_todo Requires ID${RESET}"
    test_todo_requires_id
    echo ""

    echo "${CYAN}Section 2: _em_todo with AI Path${RESET}"
    test_todo_ai_path
    echo ""

    echo "${CYAN}Section 3: _em_todo Fallback to Subject${RESET}"
    test_todo_fallback_subject
    echo ""

    echo "${CYAN}Section 4: _em_todo with Empty Content${RESET}"
    test_todo_empty_content_fails
    echo ""

    echo "${CYAN}Section 5: _em_todo Batch Processing${RESET}"
    test_todo_batch_processes_each
    echo ""

    echo "${CYAN}Section 6: _em_event Requires ID${RESET}"
    test_event_requires_id
    echo ""

    echo "${CYAN}Section 7: _em_event AI JSON Parsing${RESET}"
    test_event_ai_json_parse
    echo ""

    echo "${CYAN}Section 8: _em_event Empty Events Array${RESET}"
    test_event_empty_events
    echo ""

    echo "${CYAN}Section 9: _em_event Feeds catch Command${RESET}"
    test_event_feeds_catch
    echo ""

    echo "${CYAN}Section 10: _em_event Batch Processing${RESET}"
    test_event_batch
    echo ""

    cleanup
    test_suite_end
    exit $?
}

# Run tests
main
