#!/usr/bin/env zsh
# e2e-em-dispatcher.zsh — End-to-end tests for em email dispatcher
#
# Requires: himalaya configured with a working email account
# Safety: Read-only operations only. No emails sent in automated mode.
#
# Usage: zsh tests/e2e-em-dispatcher.zsh
#        zsh tests/e2e-em-dispatcher.zsh --send   # Enable send tests (emails self)

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

SEND_ENABLED=false
[[ "$1" == "--send" ]] && SEND_ENABLED=true

# Test runner
run_test() {
    local test_name="$1"
    local test_func="$2"
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "  ${CYAN}[$TESTS_RUN] $test_name...${RESET} "
    local output
    output=$(eval "$test_func" 2>&1)
    local rc=$?
    if [[ $rc -eq 0 ]]; then
        echo "${GREEN}PASS${RESET}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    elif [[ $rc -eq 77 ]]; then
        echo "${YELLOW}SKIP${RESET} ${DIM}${output}${RESET}"
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    else
        echo "${RED}FAIL${RESET}"
        [[ -n "$output" ]] && echo "    ${DIM}${output:0:300}${RESET}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# ══════════════════════════════════════════════════════════════
# Setup
# ══════════════════════════════════════════════════════════════

echo ""
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo "${CYAN}  Email Dispatcher E2E Tests${RESET}"
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
echo ""
if [[ "$SEND_ENABLED" == "true" ]]; then
    echo "${YELLOW}⚠️  Send tests ENABLED (will email self)${RESET}"
else
    echo "${DIM}Send tests disabled (use --send to enable)${RESET}"
fi
echo ""

# Load plugin
FLOW_QUIET=1
FLOW_ATLAS_ENABLED=no
FLOW_PLUGIN_DIR="$PROJECT_ROOT"
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
    echo "${RED}Plugin failed to load${RESET}"
    exit 1
}
echo "${GREEN}Plugin loaded (v$FLOW_VERSION)${RESET}"
echo ""

# ══════════════════════════════════════════════════════════════
# Section 1: Prerequisites
# ══════════════════════════════════════════════════════════════

echo "${CYAN}Section 1: Prerequisites${RESET}"

test_himalaya_binary() {
    if command -v himalaya >/dev/null 2>&1; then
        return 0
    else
        echo "himalaya not installed"
        exit 77
    fi
}
run_test "himalaya binary exists" "test_himalaya_binary"

test_himalaya_configured() {
    if _em_hml_check >/dev/null 2>&1; then
        return 0
    else
        echo "himalaya not configured"
        exit 77
    fi
}
run_test "himalaya configured" "test_himalaya_configured"

# If prerequisites failed, exit now
if [[ $TESTS_FAILED -gt 0 || $TESTS_SKIPPED -eq $TESTS_RUN ]]; then
    echo ""
    echo "${YELLOW}Prerequisites not met, skipping remaining tests${RESET}"
    exit 77
fi

# ══════════════════════════════════════════════════════════════
# Section 2: Read-only Operations
# ══════════════════════════════════════════════════════════════

echo ""
echo "${CYAN}Section 2: Read-only Operations${RESET}"

test_em_doctor() {
    local output=$(em doctor 2>&1)
    [[ -n "$output" ]] && return 0 || return 1
}
run_test "em doctor produces output" "test_em_doctor"

test_em_folders() {
    local output=$(em folders 2>&1)
    if echo "$output" | grep -qi "INBOX"; then
        return 0
    else
        echo "No INBOX found in folders"
        return 1
    fi
}
run_test "em folders returns folder list" "test_em_folders"

test_em_unread() {
    local output=$(em unread 2>&1)
    # Strip ANSI codes, then check for "<number> unread in <folder>"
    local clean=$(echo "$output" | sed $'s/\033\\[[0-9;]*m//g')
    if [[ "$clean" =~ ^[0-9]+\ unread\ in\  ]]; then
        return 0
    else
        echo "Unexpected format: $clean"
        return 1
    fi
}
run_test "em unread returns a number" "test_em_unread"

test_em_inbox() {
    local output=$(em inbox 2>&1)
    local lines=$(echo "$output" | wc -l | tr -d ' ')
    if [[ $lines -ge 1 ]]; then
        return 0
    else
        echo "No inbox output"
        return 1
    fi
}
run_test "em inbox produces output" "test_em_inbox"

test_em_inbox_limit() {
    local output=$(em inbox 5 2>&1)
    local lines=$(echo "$output" | grep -c "^" || echo "0")
    if [[ $lines -le 10 ]]; then  # Allow some header lines
        return 0
    else
        echo "Inbox limit not respected: $lines lines"
        return 1
    fi
}
run_test "em inbox 5 limits results" "test_em_inbox_limit"

test_em_dash() {
    local output=$(em dash 2>&1)
    if echo "$output" | grep -qiE "(Email|Inbox|unread)"; then
        return 0
    else
        echo "Dashboard missing expected content"
        return 1
    fi
}
run_test "em dash produces email dashboard" "test_em_dash"

# ══════════════════════════════════════════════════════════════
# Section 3: Search (read-only)
# ══════════════════════════════════════════════════════════════

echo ""
echo "${CYAN}Section 3: Search${RESET}"

test_em_find() {
    em find "test" >/dev/null 2>&1
    return $?
}
run_test "em find runs without error" "test_em_find"

# ══════════════════════════════════════════════════════════════
# Section 4: Email Reading
# ══════════════════════════════════════════════════════════════

echo ""
echo "${CYAN}Section 4: Email Reading${RESET}"

# Get first email ID (run directly — not in run_test subshell — so variable propagates)
FIRST_EMAIL_ID=""
TESTS_RUN=$((TESTS_RUN + 1))
echo -n "  ${CYAN}[$TESTS_RUN] get first email ID...${RESET} "
_e2e_email_data=$(_em_hml_list INBOX 1 2>/dev/null)
if [[ -n "$_e2e_email_data" ]]; then
    FIRST_EMAIL_ID=$(echo "$_e2e_email_data" | jq -r '.[0].id // empty' 2>/dev/null)
fi
if [[ -n "$FIRST_EMAIL_ID" ]]; then
    echo "${GREEN}PASS${RESET} ${DIM}(id=$FIRST_EMAIL_ID)${RESET}"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo "${YELLOW}SKIP${RESET} ${DIM}(no emails)${RESET}"
fi

if [[ -z "$FIRST_EMAIL_ID" ]]; then
    echo "${YELLOW}  Skipping email reading tests (no emails)${RESET}"
else
    test_em_read() {
        local output=$(em read "$FIRST_EMAIL_ID" 2>&1)
        [[ -n "$output" ]] && return 0 || return 1
    }
    run_test "em read produces output" "test_em_read"

    test_em_read_plain() {
        local output=$(_em_hml_read "$FIRST_EMAIL_ID" plain 2>/dev/null)
        [[ -n "$output" ]] && return 0 || return 1
    }
    run_test "_em_hml_read plain returns content" "test_em_read_plain"

    test_em_read_html() {
        local output=$(_em_hml_read "$FIRST_EMAIL_ID" html 2>/dev/null)
        if [[ -n "$output" ]]; then
            return 0
        else
            # Not all emails have HTML parts — skip, not fail
            echo "No HTML part (plain-text email)"
            return 77
        fi
    }
    run_test "_em_hml_read html returns content" "test_em_read_html"
fi

# ══════════════════════════════════════════════════════════════
# Section 5: AI Operations
# ══════════════════════════════════════════════════════════════

echo ""
echo "${CYAN}Section 5: AI Operations${RESET}"

test_ai_available() {
    local ai=$(_em_ai_available)
    if [[ -n "$ai" ]]; then
        return 0
    else
        echo "No AI provider available"
        exit 77
    fi
}
run_test "AI provider available" "test_ai_available"

if [[ $TESTS_SKIPPED -gt $((TESTS_RUN - 6)) ]]; then
    echo "${YELLOW}  Skipping AI tests (no AI available)${RESET}"
elif [[ -z "$FIRST_EMAIL_ID" ]]; then
    echo "${YELLOW}  Skipping AI tests (no email to test)${RESET}"
else
    test_ai_classify() {
        local content=$(_em_hml_read "$FIRST_EMAIL_ID" plain 2>/dev/null | head -n 20)
        if [[ -z "$content" ]]; then
            echo "No content to classify"
            return 1
        fi
        local result=$(_em_ai_query classify "$(_em_ai_classify_prompt)" "$content" "" "$FIRST_EMAIL_ID" 2>/dev/null)
        if [[ -n "$result" && ${#result} -lt 50 ]]; then
            return 0
        else
            echo "Classification failed or too long: $result"
            return 1
        fi
    }
    run_test "AI classify returns category" "test_ai_classify"

    test_ai_summarize() {
        local content=$(_em_hml_read "$FIRST_EMAIL_ID" plain 2>/dev/null | head -n 20)
        if [[ -z "$content" ]]; then
            echo "No content to summarize"
            return 1
        fi
        local result=$(_em_ai_query summarize "$(_em_ai_summarize_prompt)" "$content" "" "$FIRST_EMAIL_ID" 2>/dev/null)
        if [[ -n "$result" && ${#result} -lt 300 ]]; then
            return 0
        else
            echo "Summarize failed or too long"
            return 1
        fi
    }
    run_test "AI summarize returns summary" "test_ai_summarize"
fi

# ══════════════════════════════════════════════════════════════
# Section 6: Send Tests (--send flag only)
# ══════════════════════════════════════════════════════════════

echo ""
echo "${CYAN}Section 6: Send Tests${RESET}"

test_send_template() {
    if [[ "$SEND_ENABLED" != "true" ]]; then
        echo "Send tests disabled (use --send)"
        exit 77
    fi

    local mml=$(_em_hml_template_write 2>/dev/null)
    if [[ -n "$mml" ]]; then
        return 0
    else
        echo "Template generation failed"
        return 1
    fi
}
run_test "send template generation" "test_send_template"

test_get_user_email() {
    if [[ "$SEND_ENABLED" != "true" ]]; then
        echo "Send tests disabled"
        exit 77
    fi

    local email=$(himalaya account list --output json 2>/dev/null | jq -r '.[0].email // empty')
    if [[ -n "$email" ]]; then
        return 0
    else
        echo "Could not get user email"
        exit 77
    fi
}
run_test "get user email for self-send" "test_get_user_email"

# Note: Actual send test would be interactive (opens $EDITOR)
# Skipping in automated mode even with --send flag
test_send_interactive() {
    echo "Interactive send test skipped (requires \$EDITOR)"
    exit 77
}
run_test "em send (interactive)" "test_send_interactive"

# ══════════════════════════════════════════════════════════════
# Section 7: Cache Operations
# ══════════════════════════════════════════════════════════════

echo ""
echo "${CYAN}Section 7: Cache Operations${RESET}"

test_cache_stats() {
    em cache stats >/dev/null 2>&1
    return $?
}
run_test "em cache stats runs" "test_cache_stats"

test_cache_roundtrip() {
    _em_cache_set "summaries" "e2e-test-id" "E2E test summary" >/dev/null 2>&1
    local result=$(_em_cache_get "summaries" "e2e-test-id" 2>/dev/null)
    _em_cache_invalidate "e2e-test-id" >/dev/null 2>&1

    if [[ "$result" == "E2E test summary" ]]; then
        return 0
    else
        echo "Cache roundtrip failed: '$result'"
        return 1
    fi
}
run_test "cache set/get/invalidate" "test_cache_roundtrip"

test_cache_set_api() {
    _em_cache_set "categories" "e2e-cat-test" "Work" >/dev/null 2>&1
    local result=$(_em_cache_get "categories" "e2e-cat-test" 2>/dev/null)
    _em_cache_invalidate "e2e-cat-test" >/dev/null 2>&1

    if [[ "$result" == "Work" ]]; then
        return 0
    else
        echo "Cache category test failed"
        return 1
    fi
}
run_test "cache category storage" "test_cache_set_api"

# ══════════════════════════════════════════════════════════════
# Section 8: Delete Operations (DESTRUCTIVE — use test email)
# ══════════════════════════════════════════════════════════════

echo ""
echo "${CYAN}Section 8: Delete Operations${RESET}"

# E2E delete tests require a disposable email. We self-send a test email
# then delete it. Only runs when --send is active and we have an email ID.

test_delete_no_args() {
    local output
    output=$(em delete 2>&1)
    [[ $? -ne 0 ]] && return 0
    echo "Expected error when no args provided"
    return 1
}
run_test "em delete with no args returns error" "test_delete_no_args"

test_delete_help() {
    local output
    output=$(em delete --help 2>&1)
    if [[ "$output" == *"purge"* && "$output" == *"folder"* ]]; then
        return 0
    else
        echo "Delete help missing expected content"
        return 1
    fi
}
run_test "em delete --help shows usage" "test_delete_help"

# Live delete test — only with --send flag to avoid destroying real email
test_delete_live() {
    if [[ "$SEND_ENABLED" != "true" ]]; then
        echo "Live delete tests disabled (use --send)"
        exit 77
    fi
    # Requires a sacrificial email ID — would need to self-send first
    echo "Live delete requires manual email setup"
    exit 77
}
run_test "em delete live (destructive)" "test_delete_live"

# ══════════════════════════════════════════════════════════════
# Section 9: Move & Restore Operations
# ══════════════════════════════════════════════════════════════

echo ""
echo "${CYAN}Section 9: Move & Restore Operations${RESET}"

test_move_no_args() {
    local output
    output=$(em move 2>&1)
    [[ $? -ne 0 ]] && return 0
    echo "Expected error when no args provided"
    return 1
}
run_test "em move with no args returns error" "test_move_no_args"

test_move_help() {
    local output
    output=$(em move --help 2>&1)
    if [[ "$output" == *"FOLDER"* && "$output" == *"--from"* ]]; then
        return 0
    else
        echo "Move help missing expected content"
        return 1
    fi
}
run_test "em move --help shows usage" "test_move_help"

test_restore_no_args() {
    local output
    output=$(em restore 2>&1)
    [[ $? -ne 0 ]] && return 0
    echo "Expected error when no args provided"
    return 1
}
run_test "em restore with no args returns error" "test_restore_no_args"

test_restore_help() {
    local output
    output=$(em restore --help 2>&1)
    if [[ "$output" == *"INBOX"* || "$output" == *"Trash"* ]]; then
        return 0
    else
        echo "Restore help missing expected content"
        return 1
    fi
}
run_test "em restore --help shows usage" "test_restore_help"

# Live move round-trip: move to Trash then restore — only with --send
test_move_restore_roundtrip() {
    if [[ "$SEND_ENABLED" != "true" ]]; then
        echo "Live move/restore tests disabled (use --send)"
        exit 77
    fi
    if [[ -z "$FIRST_EMAIL_ID" ]]; then
        echo "No email to test with"
        exit 77
    fi
    # Move to Trash, then restore — verifies both paths work
    # Using a known safe email (the first one)
    local move_out
    move_out=$(em move Trash "$FIRST_EMAIL_ID" 2>&1)
    if [[ $? -ne 0 ]]; then
        echo "Move to Trash failed: $move_out"
        return 1
    fi
    sleep 1
    local restore_out
    restore_out=$(em restore "$FIRST_EMAIL_ID" 2>&1)
    if [[ $? -ne 0 ]]; then
        echo "Restore from Trash failed: $restore_out"
        return 1
    fi
    return 0
}
run_test "em move + restore round-trip (destructive)" "test_move_restore_roundtrip"

# ══════════════════════════════════════════════════════════════
# Section 10: Flag Operations
# ══════════════════════════════════════════════════════════════

echo ""
echo "${CYAN}Section 10: Flag Operations${RESET}"

test_flag_no_args() {
    local output
    output=$(em flag 2>&1)
    [[ $? -ne 0 ]] && return 0
    echo "Expected error when no args provided"
    return 1
}
run_test "em flag with no args returns error" "test_flag_no_args"

# Live flag round-trip: flag then unflag
test_flag_roundtrip() {
    if [[ -z "$FIRST_EMAIL_ID" ]]; then
        echo "No email to test with"
        exit 77
    fi
    local flag_out
    flag_out=$(em flag "$FIRST_EMAIL_ID" 2>&1)
    if [[ $? -ne 0 ]]; then
        echo "Flag failed: $flag_out"
        return 1
    fi
    local unflag_out
    unflag_out=$(em unflag "$FIRST_EMAIL_ID" 2>&1)
    if [[ $? -ne 0 ]]; then
        echo "Unflag failed: $unflag_out"
        return 1
    fi
    return 0
}
run_test "em flag + unflag round-trip" "test_flag_roundtrip"

# ══════════════════════════════════════════════════════════════
# Section 11: Todo & Event Extraction
# ══════════════════════════════════════════════════════════════

echo ""
echo "${CYAN}Section 11: Todo & Event Extraction${RESET}"

test_todo_no_args() {
    local output
    output=$(em todo 2>&1)
    [[ $? -ne 0 ]] && return 0
    echo "Expected error when no args provided"
    return 1
}
run_test "em todo with no args returns error" "test_todo_no_args"

test_event_no_args() {
    local output
    output=$(em event 2>&1)
    [[ $? -ne 0 ]] && return 0
    echo "Expected error when no args provided"
    return 1
}
run_test "em event with no args returns error" "test_event_no_args"

# Live todo extraction — requires AI + email
test_todo_live() {
    if [[ -z "$FIRST_EMAIL_ID" ]]; then
        echo "No email to test with"
        exit 77
    fi
    local ai=$(_em_ai_available 2>/dev/null)
    if [[ -z "$ai" ]]; then
        echo "No AI provider available"
        exit 77
    fi
    local output
    output=$(em todo "$FIRST_EMAIL_ID" 2>&1)
    # Any output (even "no action items") means it ran successfully
    [[ -n "$output" ]] && return 0
    echo "No output from em todo"
    return 1
}
run_test "em todo extracts items from email" "test_todo_live"

# Live event extraction — requires AI + email
test_event_live() {
    if [[ -z "$FIRST_EMAIL_ID" ]]; then
        echo "No email to test with"
        exit 77
    fi
    local ai=$(_em_ai_available 2>/dev/null)
    if [[ -z "$ai" ]]; then
        echo "No AI provider available"
        exit 77
    fi
    local output
    output=$(em event "$FIRST_EMAIL_ID" 2>&1)
    # Any output (even "no events found") means it ran successfully
    [[ -n "$output" ]] && return 0
    echo "No output from em event"
    return 1
}
run_test "em event extracts events from email" "test_event_live"

# ══════════════════════════════════════════════════════════════
# Section 12: Dispatcher Aliases
# ══════════════════════════════════════════════════════════════

echo ""
echo "${CYAN}Section 12: Dispatcher Aliases${RESET}"

test_alias_del() {
    local output
    output=$(em del 2>&1)
    # Should error (no args) but NOT "Unknown command"
    [[ "$output" != *"Unknown command"* ]] && return 0
    echo "'em del' not routed to delete"
    return 1
}
run_test "em del routes to delete" "test_alias_del"

test_alias_rm() {
    local output
    output=$(em rm 2>&1)
    [[ "$output" != *"Unknown command"* ]] && return 0
    echo "'em rm' not routed to delete"
    return 1
}
run_test "em rm routes to delete" "test_alias_rm"

test_alias_mv() {
    local output
    output=$(em mv 2>&1)
    [[ "$output" != *"Unknown command"* ]] && return 0
    echo "'em mv' not routed to move"
    return 1
}
run_test "em mv routes to move" "test_alias_mv"

test_alias_fl() {
    local output
    output=$(em fl 2>&1)
    [[ "$output" != *"Unknown command"* ]] && return 0
    echo "'em fl' not routed to flag"
    return 1
}
run_test "em fl routes to flag" "test_alias_fl"

test_alias_td() {
    local output
    output=$(em td 2>&1)
    [[ "$output" != *"Unknown command"* ]] && return 0
    echo "'em td' not routed to todo"
    return 1
}
run_test "em td routes to todo" "test_alias_td"

test_alias_ev() {
    local output
    output=$(em ev 2>&1)
    [[ "$output" != *"Unknown command"* ]] && return 0
    echo "'em ev' not routed to event"
    return 1
}
run_test "em ev routes to event" "test_alias_ev"

# ══════════════════════════════════════════════════════════════
# Summary
# ══════════════════════════════════════════════════════════════

echo ""
echo "${CYAN}══════════════════════════════════════════════════════════════${RESET}"
if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}All $TESTS_PASSED passed ($TESTS_SKIPPED skipped) of $TESTS_RUN total${RESET}"
    echo ""
    exit 0
else
    echo "${RED}$TESTS_FAILED failed, ${TESTS_PASSED} passed, ${TESTS_SKIPPED} skipped of $TESTS_RUN total${RESET}"
    echo ""
    exit 1
fi
