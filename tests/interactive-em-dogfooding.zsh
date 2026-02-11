#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# INTERACTIVE EM EMAIL DISPATCHER DOGFOODING TEST
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Walk through every em subcommand with real himalaya, asking the
#          user to visually confirm each output looks correct.
#
# Prerequisites: himalaya installed and configured
#
# Safety:
#   - Phase 1-3: Read-only (no emails sent)
#   - Phase 4: Send tests (ONLY to self, requires explicit opt-in)
#   - Phase 5: AI features (requires claude or gemini)
#
# Usage:
#   zsh tests/interactive-em-dogfooding.zsh             # Read-only phases
#   zsh tests/interactive-em-dogfooding.zsh --send      # Include send phase
#
# ══════════════════════════════════════════════════════════════════════════════

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

# ═══════════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Dog feeding game
DOG='🐕'
FOOD='🥩'
HAPPY='😊'
SAD='😢'
STAR='⭐'
EYES='👀'
QUESTION='❓'
MAIL='📬'
SEARCH='🔍'
AI='🤖'
SEND_ICON='📤'
TOOLS='🔧'

HUNGER=100
HAPPINESS=50
TASKS_COMPLETED=0
TOTAL_TASKS=0

# Flags
SEND_ENABLED=false
[[ "$1" == "--send" ]] && SEND_ENABLED=true

# Capture email ID from inbox for later tests
CAPTURED_EMAIL_ID=""

# ═══════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════

print_banner() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${MAIL}  ${BOLD}INTERACTIVE EM DOGFOODING TEST${NC}  ${DOG}                 ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${DIM}Tests the em email dispatcher with real himalaya${NC}"
    echo ""
    if [[ "$SEND_ENABLED" == "true" ]]; then
        echo -e "${YELLOW}⚠️  Send tests ENABLED (will email yourself only)${NC}"
    else
        echo -e "${DIM}Send tests disabled (use --send to enable)${NC}"
    fi
    echo ""
}

print_dog_status() {
    local mood
    if [[ $HAPPINESS -gt 70 ]]; then
        mood="${GREEN}${HAPPY} Very Happy${NC}"
    elif [[ $HAPPINESS -gt 40 ]]; then
        mood="${YELLOW}🤔 Okay${NC}"
    else
        mood="${RED}${SAD} Sad${NC}"
    fi

    echo ""
    echo -e "${CYAN}╭─ Dog Status ─────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} Hunger:    ${YELLOW}$HUNGER%${NC}"
    echo -e "${CYAN}│${NC} Happiness: $mood"
    echo -e "${CYAN}│${NC} Tasks:     ${GREEN}$TASKS_COMPLETED${NC}/${TOTAL_TASKS} completed"
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────╯${NC}"
    echo ""
}

feed_dog() {
    local amount=${1:-10}
    HUNGER=$((HUNGER - amount))
    HAPPINESS=$((HAPPINESS + amount / 2))
    [[ $HUNGER -lt 0 ]] && HUNGER=0
    [[ $HAPPINESS -gt 100 ]] && HAPPINESS=100
    echo -e "${GREEN}${FOOD} Fed the dog! ${HAPPY}${NC}"
    ((TASKS_COMPLETED++))
}

disappoint_dog() {
    HAPPINESS=$((HAPPINESS - 10))
    [[ $HAPPINESS -lt 0 ]] && HAPPINESS=0
    echo -e "${RED}The dog is disappointed ${SAD}${NC}"
    ((TASKS_COMPLETED++))
}

press_any_key() {
    echo ""
    echo -e "${DIM}Press any key to continue...${NC}"
    read -k 1 -s
}

run_test() {
    local test_num=$1
    local test_name="$2"
    local expected="$3"
    local command="$4"

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}TEST $test_num/$TOTAL_TASKS: $test_name${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo -e "${YELLOW}${EYES} EXPECTED:${NC}"
    echo -e "${DIM}$expected${NC}"
    echo ""

    echo -e "${BLUE}${STAR} COMMAND:${NC}"
    echo -e "${CYAN}  \$ $command${NC}"
    echo ""

    press_any_key

    echo -e "${MAGENTA}🤔 ACTUAL OUTPUT:${NC}"
    echo -e "${DIM}────────────────────────────────────────────────────────────${NC}"
    eval "$command"
    echo -e "${DIM}────────────────────────────────────────────────────────────${NC}"
    echo ""

    echo -e "${QUESTION} ${BOLD}Does the output match expectations?${NC}"
    echo -e "  ${GREEN}[y]${NC} Yes, test passed"
    echo -e "  ${RED}[n]${NC} No, test failed"
    echo -e "  ${YELLOW}[s]${NC} Skip (will test later)"
    echo -e "  ${RED}[q]${NC} Quit testing"
    echo ""
    echo -n "Your choice: "

    local choice
    read -k 1 choice
    echo ""

    case "$choice" in
        y|Y)
            feed_dog 10
            ;;
        n|N)
            disappoint_dog
            ;;
        s|S)
            echo -e "${YELLOW}Skipped${NC}"
            ((TASKS_COMPLETED++))
            ;;
        q|Q)
            echo ""
            echo -e "${YELLOW}Quitting test suite...${NC}"
            print_final_summary
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Treating as skip.${NC}"
            ((TASKS_COMPLETED++))
            ;;
    esac
}

ask_email_id() {
    echo ""
    echo -e "${YELLOW}${QUESTION} Enter an email ID from the inbox above for read/AI tests:${NC}"
    echo -n "Email ID (or Enter to use '1'): "
    read CAPTURED_EMAIL_ID
    [[ -z "$CAPTURED_EMAIL_ID" ]] && CAPTURED_EMAIL_ID="1"
    echo -e "${GREEN}Using email ID: $CAPTURED_EMAIL_ID${NC}"
}

# ═══════════════════════════════════════════════════════════════════
# CALCULATE TOTAL TASKS
# ═══════════════════════════════════════════════════════════════════

count_tasks() {
    # Phase 1: Prerequisites (2)
    # Phase 2: Core read-only (7)
    # Phase 3: Utilities (4)
    # Phase 4: Send (2, conditional)
    # Phase 5: AI features (3, conditional)
    TOTAL_TASKS=16
    [[ "$SEND_ENABLED" == "true" ]] && TOTAL_TASKS=$((TOTAL_TASKS + 2))
    # AI is always attempted (may skip)
    TOTAL_TASKS=$((TOTAL_TASKS + 3))
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 1: Prerequisites
# ═══════════════════════════════════════════════════════════════════

test_phase1() {
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  ${TOOLS} PHASE 1: Prerequisites${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    run_test 1 "em doctor (dependency check)" \
        "Should show:
  - himalaya binary: found with version
  - fzf: found (optional)
  - AI backend status (claude/gemini)
  - Config file locations
  - Overall health status" \
        "em doctor"

    run_test 2 "em help (all subcommands)" \
        "Should show formatted help with:
  - Header: 'em - Email Dispatcher (himalaya)'
  - MOST COMMON section (em, read, reply, send, pick)
  - QUICK EXAMPLES with alias shortcuts
  - All subcommands listed: inbox, read, send, reply, find, pick,
    respond, classify, summarize, unread, dash, folders, html,
    attach, cache, doctor" \
        "em help"
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 2: Core Read-Only Operations
# ═══════════════════════════════════════════════════════════════════

test_phase2() {
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  ${MAIL} PHASE 2: Core Read-Only Operations${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    run_test 3 "em (no args → dashboard)" \
        "Should show quick pulse dashboard:
  - Unread count
  - Recent emails (last ~10)
  - Formatted with sender, subject, date" \
        "em"

    run_test 4 "em inbox (paginated email list)" \
        "Should show:
  - Recent emails (default 25)
  - Each line: ID, From, Subject, Date
  - Formatted and readable" \
        "em inbox"

    # Ask user to pick an email ID for subsequent tests
    ask_email_id

    run_test 5 "em read <ID> (read single email)" \
        "Should show:
  - Email headers (From, To, Subject, Date)
  - Email body rendered (HTML/markdown/plain)
  - Content displayed via smart render pipeline" \
        "em read $CAPTURED_EMAIL_ID"

    run_test 6 "em unread (unread count)" \
        "Should show:
  - Number of unread emails
  - Quick count, no full listing" \
        "em unread"

    run_test 7 "em dash (explicit dashboard)" \
        "Should show same dashboard as 'em' with no args:
  - Unread count
  - Latest emails
  - Quick pulse format" \
        "em dash"

    run_test 8 "em folders (list mail folders)" \
        "Should show:
  - INBOX (always present)
  - Sent / Drafts / Trash / Archive (common)
  - Any custom folders" \
        "em folders"

    run_test 9 "em find (search emails)" \
        "Should show:
  - Search results matching query
  - Each result: ID, From, Subject, Date
  - Or 'no results' message if nothing matches" \
        "em find \"test\""
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 3: Utilities & Cache
# ═══════════════════════════════════════════════════════════════════

test_phase3() {
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  ${TOOLS} PHASE 3: Utilities & Cache${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    run_test 10 "em html <ID> (HTML render)" \
        "Should show:
  - Raw HTML rendered to terminal (via w3m/lynx/cat fallback)
  - Or plain text if email has no HTML part" \
        "em html $CAPTURED_EMAIL_ID"

    run_test 11 "em attach <ID> (list/download attachments)" \
        "Should show:
  - List of attachments (if any)
  - Or 'no attachments' message
  - Does NOT auto-download without confirmation" \
        "em attach $CAPTURED_EMAIL_ID"

    run_test 12 "em cache stats (cache statistics)" \
        "Should show:
  - Cache directory location
  - Number of cached entries per category
  - Total cache size
  - Or 'no cache' if first run" \
        "em cache stats"

    run_test 13 "em pick (fzf email browser)" \
        "Should open:
  - fzf interface with email list
  - Preview pane showing email content
  - Select email → read it
  - Press Ctrl-C to exit fzf

  ${YELLOW}NOTE: This is interactive — browse around, then exit with Ctrl-C${NC}" \
        "em pick"
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 4: Send Operations (opt-in, self only)
# ═══════════════════════════════════════════════════════════════════

test_phase4() {
    if [[ "$SEND_ENABLED" != "true" ]]; then
        echo ""
        echo -e "${DIM}Phase 4: Send tests skipped (use --send to enable)${NC}"
        return
    fi

    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  ${SEND_ICON} PHASE 4: Send Operations (self only)${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  These tests will send emails TO YOURSELF.${NC}"
    echo -e "${YELLOW}   Your configured email: $(himalaya account list 2>/dev/null | grep -o '[^ ]*@[^ ]*' | head -1)${NC}"
    echo ""
    press_any_key

    local test_num=$((TOTAL_TASKS - 4))  # Adjust based on position

    run_test 14 "em send (compose new email to self)" \
        "Should:
  - Open \$EDITOR with email template (To/Subject/Body)
  - Pre-fill 'To:' with your own address
  - After saving and closing editor:
    → Show draft preview
    → Ask for send confirmation [y/n]
  - Confirm and send to yourself

  ${YELLOW}TIP: Address it to yourself, write 'em dogfood test', then confirm send${NC}" \
        "em send"

    run_test 15 "em reply <ID> (AI-draft reply)" \
        "Should:
  - Fetch email #$CAPTURED_EMAIL_ID
  - Generate AI draft reply
  - Open \$EDITOR with draft
  - After saving:
    → Preview the reply
    → Ask for send confirmation [y/n]
  - You can cancel at the confirmation step

  ${YELLOW}TIP: Review the AI draft, then choose 'n' to skip sending${NC}" \
        "em reply $CAPTURED_EMAIL_ID"
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 5: AI Features
# ═══════════════════════════════════════════════════════════════════

test_phase5() {
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  ${AI} PHASE 5: AI Features${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${DIM}These tests require an AI backend (claude/gemini).${NC}"
    echo -e "${DIM}If no AI is available, tests will show an error — mark as skip.${NC}"
    echo ""

    run_test 16 "em classify <ID> (AI classify email)" \
        "Should show:
  - Category icon + label (e.g. 📩 student-question)
  - One of: student-question, admin-important, scheduling,
    newsletter, personal, automated, urgent, other
  - Or error if no AI backend available" \
        "em classify $CAPTURED_EMAIL_ID"

    run_test 17 "em summarize <ID> (AI summarize email)" \
        "Should show:
  - 2-3 sentence summary of the email
  - Concise and accurate
  - Cached for subsequent calls
  - Or error if no AI backend available" \
        "em summarize $CAPTURED_EMAIL_ID"

    run_test 18 "em respond (batch AI drafts)" \
        "Should show:
  - Scan unread emails
  - For each actionable email:
    → Classification
    → AI draft generation
    → Preview of draft
  - Or 'no actionable emails' message
  - Or error if no AI backend available

  ${YELLOW}NOTE: This processes multiple emails. Review output carefully.${NC}" \
        "em respond"
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 6: Alias & Error Handling
# ═══════════════════════════════════════════════════════════════════

test_phase6() {
    echo ""
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  ${SEARCH} PHASE 6: Aliases & Error Handling${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""

    run_test 19 "em --help (flag alias for help)" \
        "Should show same help output as 'em help':
  - Header with 'Email Dispatcher'
  - All subcommands listed" \
        "em --help"

    run_test 20 "em i (alias for inbox)" \
        "Should show same inbox listing as 'em inbox':
  - Paginated email list
  - ID, From, Subject, Date columns" \
        "em i"

    run_test 21 "em __bogus__ (unknown command error)" \
        "Should show:
  - Error: 'Unknown command: __bogus__'
  - Hint: 'Run em help for available commands'
  - Non-zero exit code" \
        "em __bogus__; echo \"Exit code: \$?\""
}

# ═══════════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ═══════════════════════════════════════════════════════════════════

print_final_summary() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${BOLD}FINAL RESULTS${NC}                                           ${CYAN}║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "  Tasks Completed: ${GREEN}$TASKS_COMPLETED${NC}/${TOTAL_TASKS}"
    echo -e "  Dog Happiness:   ${YELLOW}$HAPPINESS%${NC}"
    echo ""

    if [[ $HAPPINESS -gt 80 ]]; then
        echo -e "${GREEN}${BOLD}${HAPPY} The dog is VERY HAPPY! Great job testing! ${HAPPY}${NC}"
    elif [[ $HAPPINESS -gt 50 ]]; then
        echo -e "${YELLOW}🤔 The dog is content. Some tests could be improved.${NC}"
    else
        echo -e "${RED}${SAD} The dog needs more treats. Review failed tests.${NC}"
    fi

    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    if [[ "$SEND_ENABLED" != "true" ]]; then
        echo "  - Run with --send to test send/reply operations"
    fi
    echo "  - Run automated tests:  zsh tests/test-em-dispatcher.zsh"
    echo "  - Run E2E tests:        zsh tests/e2e-em-dispatcher.zsh"
    echo "  - Run dogfood tests:    zsh tests/dogfood-em-dispatcher.zsh"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════

main() {
    print_banner
    count_tasks

    # Load plugin
    echo -e "${CYAN}Loading flow.plugin.zsh...${NC}"
    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$PROJECT_ROOT"
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
        echo -e "${RED}Plugin failed to load${NC}"
        exit 1
    }
    echo -e "${GREEN}Plugin loaded (v$FLOW_VERSION)${NC}"

    # Verify himalaya
    if ! command -v himalaya >/dev/null 2>&1; then
        echo ""
        echo -e "${RED}himalaya not found in PATH${NC}"
        echo -e "${DIM}Install: cargo install himalaya${NC}"
        echo -e "${DIM}Binary:  ~/.cargo/bin/himalaya${NC}"
        exit 1
    fi
    echo -e "${GREEN}himalaya found: $(command -v himalaya)${NC}"

    if ! _em_hml_check >/dev/null 2>&1; then
        echo ""
        echo -e "${RED}himalaya not configured (no accounts)${NC}"
        echo -e "${DIM}Run: himalaya account list${NC}"
        exit 1
    fi
    echo -e "${GREEN}himalaya configured${NC}"
    echo ""

    print_dog_status
    press_any_key

    # Run test phases
    test_phase1   # Prerequisites & help
    test_phase2   # Core read-only
    test_phase3   # Utilities & cache
    test_phase4   # Send (conditional)
    test_phase5   # AI features
    test_phase6   # Aliases & error handling

    print_final_summary
}

main "$@"
