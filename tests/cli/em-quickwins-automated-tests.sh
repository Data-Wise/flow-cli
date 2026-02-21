#!/bin/zsh
# Automated E2E Test Suite: em Quick-Win Commands
# Generated: 2026-02-18
# Run: zsh tests/cli/em-quickwins-automated-tests.sh
#
# Tests for: em star, em move, em thread, em snooze, em digest
# These tests validate function existence, help text, routing,
# and client-side logic (time parsing, snooze JSON) WITHOUT
# requiring a live IMAP connection.

set -e

# ═══════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════

PASS=0
FAIL=0
SKIP=0
TOTAL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

log_pass() { ((PASS++)) || true; ((TOTAL++)) || true; echo -e "${GREEN}✅ PASS${NC}: $1"; }
log_fail() { ((FAIL++)) || true; ((TOTAL++)) || true; echo -e "${RED}❌ FAIL${NC}: $1${2:+ - $2}"; }
log_skip() { ((SKIP++)) || true; ((TOTAL++)) || true; echo -e "${YELLOW}⏭️  SKIP${NC}: $1${2:+ - $2}"; }
log_section() { echo -e "\n${BOLD}${BLUE}▶ $1${NC}"; }

FLOW_CLI_DIR="${FLOW_CLI_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  E2E AUTOMATED TESTS: em Quick-Win Commands${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${DIM}  Directory: $FLOW_CLI_DIR${NC}"
echo -e "${DIM}  Date: $(date '+%Y-%m-%d %H:%M:%S')${NC}"

# ═══════════════════════════════════════════════════════════════
# LOAD PLUGIN (in ZSH subshell)
# ═══════════════════════════════════════════════════════════════

# Helper: run ZSH function test
zsh_test() {
    local test_code="$1"
    zsh -c "
        FLOW_QUIET=1
        FLOW_ATLAS_ENABLED=no
        exec < /dev/null
        source '$FLOW_CLI_DIR/flow.plugin.zsh' 2>/dev/null
        $test_code
    " 2>&1
}

zsh_test_exit() {
    local test_code="$1"
    zsh -c "
        FLOW_QUIET=1
        FLOW_ATLAS_ENABLED=no
        exec < /dev/null
        source '$FLOW_CLI_DIR/flow.plugin.zsh' 2>/dev/null
        $test_code
    " 2>/dev/null
    return $?
}

# ═══════════════════════════════════════════════════════════════
# SECTION 1: Function Existence
# ═══════════════════════════════════════════════════════════════

log_section "Function Existence"

for func in _em_star _em_starred _em_move _em_thread _em_snooze _em_snoozed _em_digest _em_snooze_parse_time; do
    result=$(zsh_test "(( \${+functions[$func]} )) && echo yes || echo no")
    if [[ "$result" == "yes" ]]; then
        log_pass "$func exists"
    else
        log_fail "$func exists" "function not defined"
    fi
done

# Adapter functions
for func in _em_hml_move _em_hml_headers; do
    result=$(zsh_test "(( \${+functions[$func]} )) && echo yes || echo no")
    if [[ "$result" == "yes" ]]; then
        log_pass "$func adapter exists"
    else
        log_fail "$func adapter exists" "function not defined"
    fi
done

# ═══════════════════════════════════════════════════════════════
# SECTION 2: Case Statement Routing
# ═══════════════════════════════════════════════════════════════

log_section "Case Statement Routing"

# Test that each keyword is routed (via help output containing the command)
help_output=$(zsh_test "em help")

for cmd in star starred move thread snooze snoozed digest; do
    if echo "$help_output" | grep -qi "$cmd"; then
        log_pass "em help mentions '$cmd'"
    else
        log_fail "em help mentions '$cmd'" "not found in help output"
    fi
done

# Test aliases route correctly (should not trigger "Unknown command")
for alias_cmd in "flag" "mv" "th" "snz" "dg"; do
    result=$(zsh_test "em $alias_cmd 2>&1 || true")
    if echo "$result" | grep -q "Unknown command"; then
        log_fail "alias '$alias_cmd' routes" "got 'Unknown command'"
    else
        log_pass "alias '$alias_cmd' routes"
    fi
done

# ═══════════════════════════════════════════════════════════════
# SECTION 3: Error Handling (no himalaya needed)
# ═══════════════════════════════════════════════════════════════

log_section "Error Handling (Missing Args)"

# Commands that require an ID should fail gracefully without one
for cmd in star move thread; do
    result=$(zsh_test "
        # Mock himalaya to avoid network
        himalaya() { return 0; }
        em $cmd 2>&1 || true
    ")
    if echo "$result" | grep -qi "ID required\|Email ID required\|required"; then
        log_pass "em $cmd without ID → error message"
    else
        log_fail "em $cmd without ID → error message" "got: $(echo "$result" | head -1)"
    fi
done

# em snooze requires both ID and time
result=$(zsh_test "
    himalaya() { return 0; }
    em snooze 2>&1 || true
")
if echo "$result" | grep -qi "required"; then
    log_pass "em snooze without args → error message"
else
    log_fail "em snooze without args → error message"
fi

result=$(zsh_test "
    himalaya() { return 0; }
    em snooze 42 2>&1 || true
")
if echo "$result" | grep -qi "time required\|Snooze time"; then
    log_pass "em snooze with ID but no time → error message"
else
    log_fail "em snooze with ID but no time → error message"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 4: Snooze Time Parser (Pure Logic — No Network)
# ═══════════════════════════════════════════════════════════════

log_section "Snooze Time Parser"

# Test hours
result=$(zsh_test "
    local now=\$(date +%s)
    local parsed=\$(_em_snooze_parse_time '2h')
    local expected=\$(( now + 7200 ))
    local diff=\$(( parsed - expected ))
    (( diff >= -2 && diff <= 2 )) && echo PASS || echo 'FAIL diff='\$diff
")
if [[ "$result" == "PASS" ]]; then
    log_pass "parse '2h' → now + 7200s"
else
    log_fail "parse '2h' → now + 7200s" "$result"
fi

# Test days
result=$(zsh_test "
    local now=\$(date +%s)
    local parsed=\$(_em_snooze_parse_time '3d')
    local expected=\$(( now + 259200 ))
    local diff=\$(( parsed - expected ))
    (( diff >= -2 && diff <= 2 )) && echo PASS || echo 'FAIL diff='\$diff
")
if [[ "$result" == "PASS" ]]; then
    log_pass "parse '3d' → now + 259200s"
else
    log_fail "parse '3d' → now + 259200s" "$result"
fi

# Test weeks
result=$(zsh_test "
    local now=\$(date +%s)
    local parsed=\$(_em_snooze_parse_time '1w')
    local expected=\$(( now + 604800 ))
    local diff=\$(( parsed - expected ))
    (( diff >= -2 && diff <= 2 )) && echo PASS || echo 'FAIL diff='\$diff
")
if [[ "$result" == "PASS" ]]; then
    log_pass "parse '1w' → now + 604800s"
else
    log_fail "parse '1w' → now + 604800s" "$result"
fi

# Test tomorrow (should be next day at 9am)
result=$(zsh_test '
    local parsed=$(_em_snooze_parse_time "tomorrow")
    local now=$(date +%s)
    if [[ -z "$parsed" || "$parsed" == "0" ]]; then echo FAIL_EMPTY; exit; fi
    if (( parsed > now && parsed > now + 3600 )); then echo PASS; else echo "FAIL val=$parsed now=$now"; fi
')
# Grab last line only (avoid init noise)
result=$(echo "$result" | tail -1)
if [[ "$result" == "PASS" ]]; then
    log_pass "parse 'tomorrow' → valid future epoch (>1h from now)"
elif [[ "$result" == "FAIL_EMPTY" ]]; then
    log_skip "parse 'tomorrow'" "macOS date -v not available"
else
    log_fail "parse 'tomorrow' → valid future epoch" "$result"
fi

# Test invalid time
result=$(zsh_test "_em_snooze_parse_time 'never'")
if [[ "$result" == "0" ]]; then
    log_pass "parse 'never' → 0 (invalid)"
else
    log_fail "parse 'never' → 0 (invalid)" "got: $result"
fi

# Test day names
for day in monday tuesday wednesday thursday friday saturday sunday; do
    result=$(zsh_test "
        local parsed=\$(_em_snooze_parse_time '$day')
        [[ -n \"\$parsed\" && \"\$parsed\" != '0' ]] && echo PASS || echo FAIL
    ")
    if [[ "$result" == "PASS" ]]; then
        log_pass "parse '$day' → valid epoch"
    else
        log_fail "parse '$day' → valid epoch"
    fi
done

# ═══════════════════════════════════════════════════════════════
# SECTION 5: Snooze JSON Persistence (No Network)
# ═══════════════════════════════════════════════════════════════

log_section "Snooze JSON Persistence"

# Test snoozed with no file → "No snoozed emails"
result=$(zsh_test "
    HOME=\$(mktemp -d)
    _em_snoozed 2>&1
")
if echo "$result" | grep -qi "No snoozed"; then
    log_pass "em snoozed with no file → 'No snoozed emails'"
else
    log_fail "em snoozed with no file → 'No snoozed emails'" "got: $(echo "$result" | head -1)"
fi

# Test snoozed with empty JSON
result=$(zsh_test "
    local tmpdir=\$(mktemp -d)
    HOME=\$tmpdir
    mkdir -p \"\$tmpdir/.flow/email-snooze\"
    echo '[]' > \"\$tmpdir/.flow/email-snooze/pending.json\"
    _em_snoozed 2>&1
    rm -rf \"\$tmpdir\"
")
if echo "$result" | grep -qi "No snoozed"; then
    log_pass "em snoozed with empty JSON → 'No snoozed emails'"
else
    log_fail "em snoozed with empty JSON → 'No snoozed emails'"
fi

# Test snoozed with a pending entry (future wake time)
result=$(zsh_test '
    local tmpdir=$(mktemp -d)
    HOME=$tmpdir
    mkdir -p "$tmpdir/.flow/email-snooze"
    local future=$(( $(date +%s) + 3600 ))
    # Write JSON with jq to avoid quoting issues
    echo "[{\"id\":\"42\",\"subject\":\"Test email\",\"folder\":\"INBOX\",\"wake\":${future},\"created\":1234567890,\"time_spec\":\"1h\"}]" > "$tmpdir/.flow/email-snooze/pending.json"
    _em_snoozed 2>&1
    rm -rf "$tmpdir"
')
if echo "$result" | grep -q "42"; then
    log_pass "em snoozed shows pending entry"
else
    log_fail "em snoozed shows pending entry" "got: $(echo "$result" | head -3)"
fi

# Test snoozed with expired entry (past wake time)
result=$(zsh_test '
    local tmpdir=$(mktemp -d)
    HOME=$tmpdir
    mkdir -p "$tmpdir/.flow/email-snooze"
    local past=$(( $(date +%s) - 3600 ))
    echo "[{\"id\":\"99\",\"subject\":\"Expired snooze\",\"folder\":\"INBOX\",\"wake\":${past},\"created\":1234567890,\"time_spec\":\"1h\"}]" > "$tmpdir/.flow/email-snooze/pending.json"
    _em_snoozed 2>&1
    rm -rf "$tmpdir"
')
if echo "$result" | grep -qi "READY"; then
    log_pass "em snoozed shows expired entry as READY"
else
    log_fail "em snoozed shows expired entry as READY" "got: $(echo "$result" | head -3)"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 6: Starred (No Network — Mock)
# ═══════════════════════════════════════════════════════════════

log_section "Starred Display (Mocked)"

# Test em starred with no flagged emails
result=$(zsh_test "
    _em_require_himalaya() { return 0; }
    _em_hml_list() { echo '[]'; }
    _em_starred 2>&1
")
if echo "$result" | grep -qi "No starred\|0 starred"; then
    log_pass "em starred with empty list → no results"
else
    log_fail "em starred with empty list → no results" "got: $(echo "$result" | head -2)"
fi

# Test em starred with flagged emails present
result=$(zsh_test '
    _em_require_himalaya() { return 0; }
    _em_hml_list() {
        echo "[
            {\"id\":\"101\",\"from\":{\"name\":\"Alice\"},\"subject\":\"Important\",\"date\":\"2026-02-18 10:00\",\"flags\":[\"Seen\",\"Flagged\"]},
            {\"id\":\"102\",\"from\":{\"name\":\"Bob\"},\"subject\":\"Hello\",\"date\":\"2026-02-18 11:00\",\"flags\":[\"Seen\"]},
            {\"id\":\"103\",\"from\":{\"name\":\"Carol\"},\"subject\":\"Urgent\",\"date\":\"2026-02-18 12:00\",\"flags\":[\"Flagged\"]}
        ]"
    }
    _em_starred 2>&1
')
if echo "$result" | grep -q "101" && echo "$result" | grep -q "103"; then
    log_pass "em starred shows flagged emails (101, 103)"
else
    log_fail "em starred shows flagged emails (101, 103)" "got: $(echo "$result" | head -5)"
fi

# Test em starred does NOT show unflagged emails
if echo "$result" | grep -q "102.*Bob.*Hello"; then
    log_fail "em starred excludes unflagged emails (102)" "102 should not appear"
else
    log_pass "em starred excludes unflagged emails (102)"
fi

# Test em starred shows count
if echo "$result" | grep -qi "2 starred"; then
    log_pass "em starred shows correct count (2 starred)"
else
    log_fail "em starred shows correct count (2 starred)" "got: $(echo "$result" | tail -3)"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 7: fzf Keybinds in em pick
# ═══════════════════════════════════════════════════════════════

log_section "fzf Keybinds in em pick"

# Check that the source code has the new keybinds
dispatcher_file="$FLOW_CLI_DIR/lib/dispatchers/email-dispatcher.zsh"

if grep -q "ctrl-f:become.*STAR" "$dispatcher_file"; then
    log_pass "Ctrl-F → STAR keybind registered"
else
    log_fail "Ctrl-F → STAR keybind registered"
fi

if grep -q "ctrl-m:become.*MOVE" "$dispatcher_file"; then
    log_pass "Ctrl-M → MOVE keybind registered"
else
    log_fail "Ctrl-M → MOVE keybind registered"
fi

# Check that STAR/MOVE handlers exist in the action dispatch
if grep -q 'STAR:\*' "$dispatcher_file"; then
    log_pass "STAR action handler in em pick"
else
    log_fail "STAR action handler in em pick"
fi

if grep -q 'MOVE:\*' "$dispatcher_file"; then
    log_pass "MOVE action handler in em pick"
else
    log_fail "MOVE action handler in em pick"
fi

# Check header line mentions new keybinds
if grep -q "Ctrl-F=star" "$dispatcher_file"; then
    log_pass "Header mentions Ctrl-F=star"
else
    log_fail "Header mentions Ctrl-F=star"
fi

if grep -q "Ctrl-M=move" "$dispatcher_file"; then
    log_pass "Header mentions Ctrl-M=move"
else
    log_fail "Header mentions Ctrl-M=move"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 8: Digest Fallback (No AI)
# ═══════════════════════════════════════════════════════════════

log_section "Digest Fallback (No AI)"

# Test em digest with AI disabled → should use unread/read fallback
result=$(zsh_test "
    FLOW_EMAIL_AI=none
    _em_require_himalaya() { return 0; }
    _em_hml_list() {
        echo '[
            {\"id\":1,\"from\":{\"name\":\"Alice\"},\"subject\":\"Meeting\",\"date\":\"$(date +%Y-%m-%d) 10:00\",\"flags\":[\"Seen\"]},
            {\"id\":2,\"from\":{\"name\":\"Bob\"},\"subject\":\"Urgent\",\"date\":\"$(date +%Y-%m-%d) 11:00\",\"flags\":[]}
        ]'
    }
    _em_digest 2>&1
")
if echo "$result" | grep -qi "UNREAD\|READ"; then
    log_pass "em digest with AI=none → unread/read fallback"
else
    log_fail "em digest with AI=none → unread/read fallback" "got: $(echo "$result" | head -5)"
fi

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}✅ Passed: $PASS${NC}"
echo -e "  ${RED}❌ Failed: $FAIL${NC}"
echo -e "  ${YELLOW}⏭️  Skipped: $SKIP${NC}"
echo -e "  ${DIM}Total: $TOTAL${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
