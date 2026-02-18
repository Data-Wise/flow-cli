#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
# Interactive Dogfooding Tests: em ai + em catch
# Generated: 2026-02-18
# Run: bash tests/cli/em-ai-interactive-tests.sh
#
# Human-guided QA for the new em ai and em catch features.
# Requires: himalaya configured, ZSH, flow-cli sourced in shell
#
# Each test runs a command, shows expected behavior, and asks you to judge.
# ══════════════════════════════════════════════════════════════════════════════

set -e

# ═══════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════

PASS=0
FAIL=0
SKIP=0
TOTAL=0
TOTAL_TESTS=14
LOG_DIR="$(dirname "$0")/logs"
LOG_FILE="$LOG_DIR/em-ai-dogfood-$(date '+%Y%m%d-%H%M%S').log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

mkdir -p "$LOG_DIR"

# ═══════════════════════════════════════════════════════════════
# TEST RUNNER
# ═══════════════════════════════════════════════════════════════

run_test() {
    local test_num=$1
    local test_name="$2"
    local command="$3"
    local expected="$4"

    ((TOTAL++)) || true
    echo ""
    echo -e "${BOLD}${BLUE}━━━ TEST $test_num/$TOTAL_TESTS: $test_name ━━━${NC}"
    echo -e "${DIM}Command:${NC}  $command"
    echo -e "${DIM}Expected:${NC} $expected"
    echo ""
    echo -e "${CYAN}Running...${NC}"
    echo ""

    # Log the test
    echo "=== TEST $test_num: $test_name ===" >> "$LOG_FILE"
    echo "CMD: $command" >> "$LOG_FILE"
    echo "EXPECTED: $expected" >> "$LOG_FILE"

    # Execute in user's shell
    echo -e "${DIM}────────── output ──────────${NC}"
    bash -c "$command" 2>&1 | tee -a "$LOG_FILE"
    echo -e "${DIM}────────── end ──────────${NC}"
    echo ""

    # Ask for judgment
    echo -ne "${BOLD}Result? ${NC}[${GREEN}y${NC}=pass / ${RED}n${NC}=fail / ${YELLOW}s${NC}=skip / ${RED}q${NC}=quit]: "
    read -r -n1 verdict
    echo ""

    case "$verdict" in
        y|Y)
            ((PASS++)) || true
            echo -e "${GREEN}  PASS${NC}"
            echo "RESULT: PASS" >> "$LOG_FILE"
            ;;
        n|N)
            ((FAIL++)) || true
            echo -e "${RED}  FAIL${NC}"
            echo -ne "  ${DIM}Notes (optional):${NC} "
            read -r notes
            echo "RESULT: FAIL — $notes" >> "$LOG_FILE"
            ;;
        s|S)
            ((SKIP++)) || true
            echo -e "${YELLOW}  SKIP${NC}"
            echo "RESULT: SKIP" >> "$LOG_FILE"
            ;;
        q|Q)
            echo -e "\n${YELLOW}Quitting early.${NC}"
            print_summary
            exit 0
            ;;
        *)
            ((SKIP++)) || true
            echo -e "${YELLOW}  SKIP (unrecognized input)${NC}"
            echo "RESULT: SKIP" >> "$LOG_FILE"
            ;;
    esac
    echo "" >> "$LOG_FILE"
}

print_summary() {
    echo ""
    echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  DOGFOODING RESULTS${NC}"
    echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
    echo -e "  ${GREEN}Passed:  $PASS${NC}"
    echo -e "  ${RED}Failed:  $FAIL${NC}"
    echo -e "  ${YELLOW}Skipped: $SKIP${NC}"
    echo -e "  Total:   $TOTAL / $TOTAL_TESTS"
    echo ""
    echo -e "${DIM}  Log: $LOG_FILE${NC}"
    echo ""
    if [[ $FAIL -gt 0 ]]; then
        echo -e "${RED}${BOLD}  ISSUES FOUND — review log for details${NC}"
    else
        echo -e "${GREEN}${BOLD}  ALL TESTED FEATURES WORKING${NC}"
    fi
}

# ═══════════════════════════════════════════════════════════════
# HEADER
# ═══════════════════════════════════════════════════════════════

echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  DOGFOODING: em ai + em catch${NC}"
echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"
echo -e "${DIM}  Date: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${DIM}  Log:  $LOG_FILE${NC}"
echo ""
echo -e "${YELLOW}Prerequisites:${NC}"
echo -e "  1. flow-cli sourced (run: source flow.plugin.zsh)"
echo -e "  2. himalaya configured and working"
echo -e "  3. At least one email in INBOX"
echo ""
echo -ne "${BOLD}Ready to start? ${NC}[Enter to continue, q to quit]: "
read -r ready
[[ "$ready" == "q" ]] && exit 0

# ═══════════════════════════════════════════════════════════════
# TESTS
# ═══════════════════════════════════════════════════════════════

run_test 1 \
    "em ai — show status" \
    "zsh -ic 'source flow.plugin.zsh 2>/dev/null; em ai'" \
    "Shows: Current backend, Available backends, Timeout, switch hint"

run_test 2 \
    "em ai claude — switch to claude" \
    "zsh -ic 'source flow.plugin.zsh 2>/dev/null; em ai claude'" \
    "Shows success message: AI backend -> claude"

run_test 3 \
    "em ai gemini — switch to gemini" \
    "zsh -ic 'source flow.plugin.zsh 2>/dev/null; em ai gemini'" \
    "Shows success message: AI backend -> gemini"

run_test 4 \
    "em ai none — disable AI" \
    "zsh -ic 'source flow.plugin.zsh 2>/dev/null; em ai none'" \
    "Shows success message: AI backend -> none"

run_test 5 \
    "em ai toggle — cycle backends" \
    "zsh -ic 'source flow.plugin.zsh 2>/dev/null; em ai claude; em ai toggle'" \
    "First shows claude, then toggles to gemini (or another available backend)"

run_test 6 \
    "em ai bogus — invalid backend error" \
    "zsh -ic 'source flow.plugin.zsh 2>/dev/null; em ai bogus_backend_xyz'" \
    "Shows error: Unknown backend + available list"

run_test 7 \
    "em ai persistence — switch + verify" \
    "zsh -ic 'source flow.plugin.zsh 2>/dev/null; em ai gemini; em ai'" \
    "After switching to gemini, status should show Current: gemini"

run_test 8 \
    "em help — shows new commands" \
    "zsh -ic 'source flow.plugin.zsh 2>/dev/null; em help' | grep -E 'em (ai|catch)'" \
    "Help output includes both 'em ai' and 'em catch' entries"

run_test 9 \
    "em catch (no args) — error message" \
    "zsh -ic 'source flow.plugin.zsh 2>/dev/null; em catch'" \
    "Shows error: Email ID required + Usage hint"

run_test 10 \
    "em doctor — shows extra_args" \
    "zsh -ic 'source flow.plugin.zsh 2>/dev/null; em doctor' 2>&1 | head -20" \
    "Doctor output includes AI backend info and gemini extra_args if configured"

# Live email tests (require himalaya)
run_test 11 \
    "em catch <ID> — real email with AI" \
    "zsh -ic 'source flow.plugin.zsh 2>/dev/null; em ai claude; ID=\$(himalaya message list --output json 2>/dev/null | jq -r \".[0].id\" 2>/dev/null); echo \"Using email #\$ID\"; em catch \$ID'" \
    "Reads first email, AI summarizes it, shows Captured: or Capture: message"

run_test 12 \
    "em catch <ID> — AI=none fallback" \
    "zsh -ic 'source flow.plugin.zsh 2>/dev/null; em ai none; ID=\$(himalaya message list --output json 2>/dev/null | jq -r \".[0].id\" 2>/dev/null); echo \"Using email #\$ID\"; em catch \$ID'" \
    "Falls back to subject line since AI is disabled. Shows Capture: or Captured:"

run_test 13 \
    "em pick — Ctrl-T hint visible" \
    "echo '(Open em pick manually — look for Ctrl-T=catch in fzf header)'" \
    "When you run 'em pick', the fzf header should show Ctrl-T=catch alongside other keybinds"

run_test 14 \
    "Full workflow: switch + catch + switch back" \
    "zsh -ic 'source flow.plugin.zsh 2>/dev/null; echo \"Step 1: Switch to gemini\"; em ai gemini; echo; echo \"Step 2: Check status\"; em ai; echo; echo \"Step 3: Switch back\"; em ai claude; echo; echo \"Step 4: Final status\"; em ai'" \
    "Smooth transition: gemini -> status shows gemini -> claude -> status shows claude"

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════

print_summary
