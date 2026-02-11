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
    if [[ "$output" =~ ^[0-9]+$ ]]; then
        return 0
    else
        echo "Unread count not numeric: $output"
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

# Get first email ID
FIRST_EMAIL_ID=""
test_get_first_email() {
    local email_data=$(_em_hml_list INBOX 1 2>/dev/null)
    if [[ -z "$email_data" ]]; then
        echo "No emails in inbox"
        exit 77
    fi
    FIRST_EMAIL_ID=$(echo "$email_data" | jq -r '.[0].id // empty' 2>/dev/null)
    if [[ -z "$FIRST_EMAIL_ID" ]]; then
        echo "Could not extract email ID"
        exit 77
    fi
    return 0
}
run_test "get first email ID" "test_get_first_email"

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
        [[ -n "$output" ]] && return 0 || return 1
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
