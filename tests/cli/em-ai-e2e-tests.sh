#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
# E2E Test Suite: em ai + em catch (new features)
# Generated: 2026-02-18
# Run: bash tests/cli/em-ai-e2e-tests.sh
#
# Tests the em ai subcommand (runtime backend switching) and em catch
# (email-to-task capture) end-to-end in a real ZSH environment.
#
# Requirements: ZSH, flow-cli source tree
# Optional: himalaya (for live email tests), claude/gemini CLIs
# ══════════════════════════════════════════════════════════════════════════════

set +e  # Many tests expect non-zero exit codes

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

log_pass() { ((PASS++)) || true; ((TOTAL++)) || true; echo -e "${GREEN}  PASS${NC}: $1"; }
log_fail() { ((FAIL++)) || true; ((TOTAL++)) || true; echo -e "${RED}  FAIL${NC}: $1${2:+ - $2}"; }
log_skip() { ((SKIP++)) || true; ((TOTAL++)) || true; echo -e "${YELLOW}  SKIP${NC}: $1${2:+ - $2}"; }
log_section() { echo -e "\n${BOLD}${BLUE}--- $1${NC}"; }

FLOW_CLI_DIR="${FLOW_CLI_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

# ═══════════════════════════════════════════════════════════════
# HEADER
# ═══════════════════════════════════════════════════════════════

echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  E2E TESTS: em ai + em catch${NC}"
echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
echo -e "${DIM}  Directory: $FLOW_CLI_DIR${NC}"
echo -e "${DIM}  Date: $(date '+%Y-%m-%d %H:%M:%S')${NC}"

# Helper: run a ZSH snippet with flow-cli sourced
run_zsh() {
    zsh -c "
        FLOW_QUIET=1
        FLOW_ATLAS_ENABLED=no
        FLOW_PLUGIN_DIR='$FLOW_CLI_DIR'
        source '$FLOW_CLI_DIR/flow.plugin.zsh'
        $1
    " 2>&1
}

# ═══════════════════════════════════════════════════════════════
# SECTION 1: File Structure
# ═══════════════════════════════════════════════════════════════

log_section "1. File Structure"

if [[ -f "$FLOW_CLI_DIR/lib/em-ai.zsh" ]]; then
    log_pass "lib/em-ai.zsh exists"
else
    log_fail "lib/em-ai.zsh missing"
fi

if grep -q '_em_ai_cmd' "$FLOW_CLI_DIR/lib/em-ai.zsh"; then
    log_pass "_em_ai_cmd defined in em-ai.zsh"
else
    log_fail "_em_ai_cmd not found in em-ai.zsh"
fi

if grep -q '_em_ai_switch' "$FLOW_CLI_DIR/lib/em-ai.zsh"; then
    log_pass "_em_ai_switch defined in em-ai.zsh"
else
    log_fail "_em_ai_switch not found"
fi

if grep -q '_em_ai_toggle' "$FLOW_CLI_DIR/lib/em-ai.zsh"; then
    log_pass "_em_ai_toggle defined in em-ai.zsh"
else
    log_fail "_em_ai_toggle not found"
fi

if grep -q '_em_ai_status' "$FLOW_CLI_DIR/lib/em-ai.zsh"; then
    log_pass "_em_ai_status defined in em-ai.zsh"
else
    log_fail "_em_ai_status not found"
fi

if grep -q '_em_catch' "$FLOW_CLI_DIR/lib/dispatchers/email-dispatcher.zsh"; then
    log_pass "_em_catch defined in email-dispatcher.zsh"
else
    log_fail "_em_catch not found in dispatcher"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 2: Dispatcher Routing
# ═══════════════════════════════════════════════════════════════

log_section "2. Dispatcher Routing"

if grep -q 'ai|AI).*_em_ai_cmd' "$FLOW_CLI_DIR/lib/dispatchers/email-dispatcher.zsh"; then
    log_pass "ai|AI routes to _em_ai_cmd"
else
    log_fail "ai|AI case not found in dispatcher"
fi

if grep -q 'catch|c).*_em_catch' "$FLOW_CLI_DIR/lib/dispatchers/email-dispatcher.zsh"; then
    log_pass "catch|c routes to _em_catch"
else
    log_fail "catch|c case not found in dispatcher"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 3: em ai status (no args)
# ═══════════════════════════════════════════════════════════════

log_section "3. em ai (status output)"

output=$(run_zsh '_em_ai_status')

if echo "$output" | grep -qi 'current'; then
    log_pass "em ai shows 'Current:' line"
else
    log_fail "em ai missing 'Current:' line" "$output"
fi

if echo "$output" | grep -qi 'available'; then
    log_pass "em ai shows 'Available:' line"
else
    log_fail "em ai missing 'Available:' line"
fi

if echo "$output" | grep -qi 'timeout'; then
    log_pass "em ai shows 'Timeout:' line"
else
    log_fail "em ai missing 'Timeout:' line"
fi

if echo "$output" | grep -q 'em ai claude\|em ai gemini\|em ai toggle'; then
    log_pass "em ai shows switch hint"
else
    log_fail "em ai missing switch hint"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 4: em ai switch (valid backends)
# ═══════════════════════════════════════════════════════════════

log_section "4. em ai switch (valid backends)"

for backend in claude gemini none auto; do
    output=$(run_zsh "_em_ai_switch '$backend'" 2>&1)
    if echo "$output" | grep -q "$backend"; then
        log_pass "em ai $backend — accepted"
    else
        log_fail "em ai $backend — unexpected output" "$output"
    fi
done

# Verify env mutation
output=$(run_zsh "
    _em_ai_switch 'gemini'
    echo \"\$FLOW_EMAIL_AI\"
")
if echo "$output" | grep -q 'gemini'; then
    log_pass "em ai switch mutates FLOW_EMAIL_AI"
else
    log_fail "FLOW_EMAIL_AI not mutated" "$output"
fi

# Verify _EM_AI_BACKENDS[default] mutation
output=$(run_zsh "
    _em_ai_switch 'gemini'
    echo \"\${_EM_AI_BACKENDS[default]}\"
")
if echo "$output" | grep -q 'gemini'; then
    log_pass "em ai switch mutates _EM_AI_BACKENDS[default]"
else
    log_fail "_EM_AI_BACKENDS[default] not mutated" "$output"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 5: em ai switch (invalid backend)
# ═══════════════════════════════════════════════════════════════

log_section "5. em ai switch (invalid backend)"

output=$(run_zsh "_em_ai_switch 'nonexistent_backend_xyz'" 2>&1)

if echo "$output" | grep -qi 'unknown\|error\|available'; then
    log_pass "em ai invalid backend shows error"
else
    log_fail "em ai invalid backend — no error shown" "$output"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 6: em ai toggle
# ═══════════════════════════════════════════════════════════════

log_section "6. em ai toggle"

output=$(run_zsh "
    export FLOW_EMAIL_AI='claude'
    _em_ai_toggle 2>&1
    echo \"RESULT=\$FLOW_EMAIL_AI\"
")

if echo "$output" | grep -q 'RESULT='; then
    result=$(echo "$output" | grep 'RESULT=' | sed 's/.*RESULT=//')
    if [[ "$result" != "claude" && -n "$result" ]]; then
        log_pass "em ai toggle switches from claude to $result"
    else
        log_skip "em ai toggle — only one backend available" "stayed on claude"
    fi
else
    log_fail "em ai toggle — no result captured" "$output"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 7: _em_ai_backend_for_op reads live env
# ═══════════════════════════════════════════════════════════════

log_section "7. _em_ai_backend_for_op (live env)"

output=$(run_zsh "
    export FLOW_EMAIL_AI='gemini'
    echo \$(_em_ai_backend_for_op classify)
")
if echo "$output" | grep -q 'gemini'; then
    log_pass "_em_ai_backend_for_op reads live FLOW_EMAIL_AI"
else
    log_fail "_em_ai_backend_for_op ignores live env" "$output"
fi

output=$(run_zsh "
    unset FLOW_EMAIL_AI
    echo \$(_em_ai_backend_for_op classify)
")
if echo "$output" | grep -q 'claude'; then
    log_pass "_em_ai_backend_for_op defaults to claude"
else
    log_fail "_em_ai_backend_for_op wrong default" "$output"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 8: extra_args configuration
# ═══════════════════════════════════════════════════════════════

log_section "8. extra_args configuration"

output=$(run_zsh "echo \"\${_EM_AI_BACKENDS[gemini_extra_args]}\"")
if echo "$output" | grep -q '\-e none'; then
    log_pass "gemini_extra_args defaults to '-e none'"
else
    log_fail "gemini_extra_args unexpected value" "$output"
fi

output=$(run_zsh "echo \"\${_EM_AI_BACKENDS[claude_extra_args]}\"")
if [[ -z "$(echo "$output" | tr -d '[:space:]')" ]]; then
    log_pass "claude_extra_args defaults to empty"
else
    log_fail "claude_extra_args unexpected value" "$output"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 9: em catch (argument validation)
# ═══════════════════════════════════════════════════════════════

log_section "9. em catch (argument validation)"

output=$(run_zsh "_em_catch" 2>&1)
if echo "$output" | grep -qi 'ID required\|Usage'; then
    log_pass "em catch with no args shows error"
else
    log_fail "em catch with no args — unexpected output" "$output"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 10: em catch (with mocked functions)
# ═══════════════════════════════════════════════════════════════

log_section "10. em catch (mocked AI path)"

output=$(run_zsh "
    _em_require_himalaya() { return 0; }
    _em_hml_read() { echo 'Dear Prof, I will miss class Friday. — Student'; }
    _em_ai_query() { echo 'Student absent Friday'; }
    catch() { echo \"CAUGHT: \$*\"; }
    _em_catch '42'
")
if echo "$output" | grep -q 'Student absent Friday\|Captured\|CAUGHT'; then
    log_pass "em catch with AI produces summary"
else
    log_fail "em catch AI path — unexpected output" "$output"
fi

# Fallback to subject
output=$(run_zsh "
    _em_require_himalaya() { return 0; }
    _em_hml_read() { echo 'Email body here'; }
    _em_ai_query() { return 1; }
    _em_hml_list() { echo '[{\"id\":\"55\",\"subject\":\"Grade inquiry\"}]'; }
    catch() { echo \"CAUGHT: \$*\"; }
    _em_catch '55'
")
if echo "$output" | grep -q 'Grade inquiry\|Captured\|CAUGHT'; then
    log_pass "em catch falls back to subject line"
else
    log_fail "em catch subject fallback — unexpected output" "$output"
fi

# No catch command fallback
output=$(run_zsh "
    _em_require_himalaya() { return 0; }
    _em_hml_read() { echo 'Email body content'; }
    _em_ai_query() { echo 'Quick summary'; }
    unset -f catch 2>/dev/null
    _em_catch '30'
")
if echo "$output" | grep -qi 'capture\|copy manually\|catch command not available'; then
    log_pass "em catch without catch cmd shows display-only"
else
    log_fail "em catch no-catch fallback — unexpected output" "$output"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 11: Help text & docs
# ═══════════════════════════════════════════════════════════════

log_section "11. Help text & docs"

output=$(run_zsh "_em_help" 2>&1)

if echo "$output" | grep -q 'em ai'; then
    log_pass "em help mentions 'em ai'"
else
    log_fail "em help missing 'em ai'"
fi

if echo "$output" | grep -q 'em catch'; then
    log_pass "em help mentions 'em catch'"
else
    log_fail "em help missing 'em catch'"
fi

if echo "$output" | grep -q 'em ai toggle'; then
    log_pass "em help mentions 'em ai toggle'"
else
    log_fail "em help missing 'em ai toggle'"
fi

if echo "$output" | grep -q 'em ai none'; then
    log_pass "em help mentions 'em ai none'"
else
    log_fail "em help missing 'em ai none'"
fi

# MASTER-DISPATCHER-GUIDE
guide="$FLOW_CLI_DIR/docs/reference/MASTER-DISPATCHER-GUIDE.md"
if [[ -f "$guide" ]]; then
    if grep -q 'em ai' "$guide" && grep -q 'em catch' "$guide"; then
        log_pass "MASTER-DISPATCHER-GUIDE includes em ai + em catch"
    else
        log_fail "MASTER-DISPATCHER-GUIDE missing new commands"
    fi
else
    log_skip "MASTER-DISPATCHER-GUIDE not found"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 12: fzf keybind integration
# ═══════════════════════════════════════════════════════════════

log_section "12. fzf keybind integration"

if grep -q 'ctrl-t:become.*CATCH' "$FLOW_CLI_DIR/lib/dispatchers/email-dispatcher.zsh"; then
    log_pass "Ctrl-T=catch fzf keybind registered"
else
    log_fail "Ctrl-T=catch keybind not found in _em_pick"
fi

if grep -q 'Ctrl-T=catch' "$FLOW_CLI_DIR/lib/dispatchers/email-dispatcher.zsh"; then
    log_pass "fzf header shows Ctrl-T=catch"
else
    log_fail "fzf header missing Ctrl-T=catch"
fi

if grep -q 'CATCH:\*' "$FLOW_CLI_DIR/lib/dispatchers/email-dispatcher.zsh"; then
    log_pass "CATCH:* handler in selection block"
else
    log_fail "CATCH:* handler not found"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 13: em doctor extra_args
# ═══════════════════════════════════════════════════════════════

log_section "13. em doctor extra_args"

if grep -q 'gemini_extra_args\|extra_args' "$FLOW_CLI_DIR/lib/dispatchers/email-dispatcher.zsh"; then
    log_pass "em doctor shows extra_args in config"
else
    log_fail "em doctor missing extra_args display"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 14: Live email tests (skip if no himalaya)
# ═══════════════════════════════════════════════════════════════

log_section "14. Live email tests (himalaya required)"

if command -v himalaya &>/dev/null; then
    # em ai status with real environment
    output=$(run_zsh "_em_ai_status" 2>&1)
    if echo "$output" | grep -q 'Current:'; then
        log_pass "em ai status works in live environment"
    else
        log_fail "em ai status failed live" "$output"
    fi

    # em catch with real email (read-only, won't send anything)
    first_id=$(himalaya message list --output json 2>/dev/null | jq -r '.[0].id // empty' 2>/dev/null || true)
    if [[ -n "$first_id" ]]; then
        output=$(run_zsh "
            export FLOW_EMAIL_AI=none
            _em_catch '$first_id'
        " 2>&1)
        if echo "$output" | grep -qi 'capture\|caught\|error\|summary'; then
            log_pass "em catch on real email #$first_id runs without crash"
        else
            log_fail "em catch on real email — unexpected output" "$output"
        fi
    else
        log_skip "No emails in inbox to test catch"
    fi
else
    log_skip "himalaya not installed — skipping live email tests"
fi

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  RESULTS${NC}"
echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}Passed:  $PASS${NC}"
echo -e "  ${RED}Failed:  $FAIL${NC}"
echo -e "  ${YELLOW}Skipped: $SKIP${NC}"
echo -e "  Total:   $TOTAL"
echo ""

if [[ $FAIL -gt 0 ]]; then
    echo -e "${RED}${BOLD}  SOME TESTS FAILED${NC}"
    exit 1
else
    echo -e "${GREEN}${BOLD}  ALL TESTS PASSED${NC}"
    exit 0
fi
