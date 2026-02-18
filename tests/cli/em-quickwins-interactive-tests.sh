#!/bin/bash
# Interactive Dogfood Test Suite: em Quick-Win Commands
# Generated: 2026-02-18
# Run: bash tests/cli/em-quickwins-interactive-tests.sh
#
# REQUIRES: Live himalaya connection (real IMAP mailbox)
#
# Walk through each new em command with your actual mailbox.
# Each test shows a command — you run it and judge the result.
#
# Tests: em star, em starred, em move, em thread, em snooze,
#        em snoozed, em digest

set -e

PASS=0
FAIL=0
SKIP=0
CURRENT_TEST=""
FAILED_TESTS=()
SKIPPED_TESTS=()

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

ask_result() {
    echo ""
    read -p "  Result? (p)ass / (f)ail / (s)kip: " -n 1 -r
    echo ""
    case "$REPLY" in
        p|P) ((PASS++)) || true; echo -e "  ${GREEN}PASS${NC}" ;;
        f|F) ((FAIL++)) || true; echo -e "  ${RED}FAIL${NC}"; FAILED_TESTS+=("$CURRENT_TEST") ;;
        *)   ((SKIP++)) || true; echo -e "  ${YELLOW}SKIP${NC}"; SKIPPED_TESTS+=("$CURRENT_TEST") ;;
    esac
}

run_test() {
    local num="$1" title="$2" cmd="$3" expected="$4"
    CURRENT_TEST="TEST ${num}: ${title}"
    echo ""
    echo -e "${BLUE}${BOLD}TEST ${num}: ${title}${NC}"
    echo -e "  ${DIM}Command:${NC}  ${cmd}"
    echo -e "  ${DIM}Expected:${NC} ${expected}"
    echo ""
    read -p "  Run? (y/n/q) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Qq]$ ]]; then
        echo -e "\n${YELLOW}Quitting early.${NC}"
        print_summary
        exit 0
    fi
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "  ${CYAN}--- output ---${NC}"
        eval "$cmd" 2>&1 | head -30 || true
        echo -e "  ${CYAN}--- end ---${NC}"
        ask_result
    else
        ((SKIP++)) || true
        echo -e "  ${YELLOW}SKIP${NC}"
        SKIPPED_TESTS+=("$CURRENT_TEST")
    fi
}

print_summary() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "  ${GREEN}Passed: $PASS${NC}"
    echo -e "  ${RED}Failed: $FAIL${NC}"
    echo -e "  ${YELLOW}Skipped: $SKIP${NC}"
    if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
        echo ""
        echo -e "  ${RED}Failed tests:${NC}"
        for t in "${FAILED_TESTS[@]}"; do
            echo -e "    ${RED}- $t${NC}"
        done
    fi
    echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
}

# ═══════════════════════════════════════════════════════════════
# HEADER
# ═══════════════════════════════════════════════════════════════

echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  INTERACTIVE DOGFOOD TESTS: em Quick-Win Commands${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  This walks you through testing the 5 new em commands"
echo -e "  with your live mailbox. Each test shows a command —"
echo -e "  you run it and judge the result."
echo ""
echo -e "  ${YELLOW}Prerequisites:${NC}"
echo -e "    - himalaya configured and connected"
echo -e "    - flow-cli loaded (source flow.plugin.zsh)"
echo -e "    - At least a few emails in INBOX"
echo ""
echo -e "  ${DIM}Tip: Run ${CYAN}em inbox${DIM} first to find a valid email ID.${NC}"
echo ""
read -p "Ready? (Enter to start, q to quit) " -r
[[ "$REPLY" =~ ^[Qq]$ ]] && exit 0

# ═══════════════════════════════════════════════════════════════
# SETUP: Get a valid email ID
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}=== SETUP ===${NC}"
echo ""
echo -e "  Let's find a valid email ID to test with."
echo -e "  Running: ${CYAN}em inbox 5${NC}"
echo -e "  ${CYAN}--- output ---${NC}"
em inbox 5 2>&1 | head -10 || true
echo -e "  ${CYAN}--- end ---${NC}"
echo ""
read -p "  Enter an email ID to use for testing: " TEST_ID
if [[ -z "$TEST_ID" ]]; then
    echo -e "  ${YELLOW}No ID provided — using '1'${NC}"
    TEST_ID=1
fi
echo -e "  ${GREEN}Using email #${TEST_ID} for tests${NC}"
echo ""

# ═══════════════════════════════════════════════════════════════
# SECTION 1: em star
# ═══════════════════════════════════════════════════════════════

echo -e "${BOLD}=== em star ===${NC}"

run_test 1 \
    "Star an email" \
    "em star $TEST_ID" \
    "Shows 'Starred #${TEST_ID}' or 'Unstarred #${TEST_ID}' with star icon"

run_test 2 \
    "Star toggle (run again to reverse)" \
    "em star $TEST_ID" \
    "Should reverse the previous action (star ↔ unstar)"

run_test 3 \
    "List starred emails" \
    "em starred" \
    "Shows list of flagged emails (or 'No starred emails' if none)"

run_test 4 \
    "Star alias: em flag" \
    "em flag $TEST_ID" \
    "Same as em star — toggles the flag"

# ═══════════════════════════════════════════════════════════════
# SECTION 2: em move
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}=== em move ===${NC}"
echo ""
echo -e "  ${YELLOW}WARNING: em move actually moves emails!${NC}"
echo -e "  ${YELLOW}Answer 'N' at the confirmation prompt to cancel.${NC}"

run_test 5 \
    "Move with explicit folder (dry run — say N)" \
    "em move $TEST_ID Archive" \
    "Shows confirmation prompt 'Move #${TEST_ID} to Archive? [y/N]' — answer N to cancel"

run_test 6 \
    "Move without folder → fzf picker" \
    "em move $TEST_ID" \
    "Opens fzf folder picker (requires fzf). Press Escape to cancel."

run_test 7 \
    "Move alias: em mv" \
    "em mv $TEST_ID Trash" \
    "Same as em move — shows confirmation. Answer N."

run_test 8 \
    "Move with no ID → error" \
    "em move" \
    "Shows error: 'Email ID required' + usage line"

# ═══════════════════════════════════════════════════════════════
# SECTION 3: em thread
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}=== em thread ===${NC}"
echo ""
echo -e "  ${DIM}Works best with a reply chain. Pick an email that's part of a conversation.${NC}"
echo ""
read -p "  Enter a thread email ID (or Enter to use $TEST_ID): " THREAD_ID
THREAD_ID="${THREAD_ID:-$TEST_ID}"

run_test 9 \
    "Show conversation thread" \
    "em thread $THREAD_ID" \
    "Shows chronological thread with current message highlighted (→). May show 'standalone message' if no thread."

run_test 10 \
    "Thread alias: em th" \
    "em th $THREAD_ID" \
    "Same as em thread"

run_test 11 \
    "Thread with no ID → error" \
    "em thread" \
    "Shows error: 'Email ID required' + usage"

# ═══════════════════════════════════════════════════════════════
# SECTION 4: em snooze
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}=== em snooze ===${NC}"
echo ""
echo -e "  ${YELLOW}NOTE: em snooze will attempt to move email to 'Snoozed' folder.${NC}"
echo -e "  ${YELLOW}This may fail if your IMAP doesn't have a Snoozed folder — that's OK.${NC}"
echo -e "  ${YELLOW}The local JSON tracking still works regardless.${NC}"

run_test 12 \
    "Snooze for 2 hours" \
    "em snooze $TEST_ID 2h" \
    "Shows 'Snoozed #${TEST_ID} until [datetime]' with the email subject"

run_test 13 \
    "List snoozed emails" \
    "em snoozed" \
    "Shows list with snooze time and status (READY if expired, time if pending)"

run_test 14 \
    "Snooze with invalid time → error" \
    "em snooze $TEST_ID blorp" \
    "Shows error: 'Could not parse time: blorp' + valid examples"

run_test 15 \
    "Snooze with no args → error" \
    "em snooze" \
    "Shows error: 'Email ID and time required'"

run_test 16 \
    "Snooze alias: em snz" \
    "em snz $TEST_ID 1d" \
    "Same as em snooze — snoozes for 1 day"

# ═══════════════════════════════════════════════════════════════
# SECTION 5: em digest
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}=== em digest ===${NC}"

run_test 17 \
    "Daily digest (today)" \
    "em digest" \
    "Shows today's emails grouped by priority (AI) or by unread/read (fallback). May show 'No emails today' if inbox is quiet."

run_test 18 \
    "Weekly digest" \
    "em digest --week" \
    "Shows this week's emails grouped by priority or unread/read"

run_test 19 \
    "Digest alias: em dg" \
    "em dg" \
    "Same as em digest"

run_test 20 \
    "Digest with count limit" \
    "em digest -n 5" \
    "Digests only 5 emails (faster, smaller scope)"

# ═══════════════════════════════════════════════════════════════
# SECTION 6: em pick Keybinds
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}=== em pick Keybinds ===${NC}"
echo ""
echo -e "  ${DIM}These test the new keybinds added to the fzf email picker.${NC}"

run_test 21 \
    "em pick → Ctrl-F to star" \
    "em pick" \
    "In fzf picker: select an email, press Ctrl-F. Should toggle star. Press Escape to exit."

run_test 22 \
    "em pick → Ctrl-M to move" \
    "em pick" \
    "In fzf picker: select an email, press Ctrl-M. Should trigger move (with folder prompt). Press Escape to exit."

# ═══════════════════════════════════════════════════════════════
# SECTION 7: Integration & Edge Cases
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}=== Integration & Edge Cases ===${NC}"

run_test 23 \
    "em help shows ORGANIZE section" \
    "em help" \
    "Help output includes ORGANIZE section with: star, starred, move, thread, snooze, snoozed, digest"

run_test 24 \
    "Unknown command still errors" \
    "em foobar123" \
    "Shows 'Unknown command: foobar123' + help hint"

# ═══════════════════════════════════════════════════════════════
# CLEANUP
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}=== Cleanup ===${NC}"
echo ""
echo -e "  ${DIM}If you snoozed emails during testing, you can clear them:${NC}"
echo -e "  ${CYAN}rm -rf ~/.flow/email-snooze/${NC}"
echo ""
echo -e "  ${DIM}If you moved emails, find them in the target folder:${NC}"
echo -e "  ${CYAN}em folders${NC}"
echo ""

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════

print_summary
