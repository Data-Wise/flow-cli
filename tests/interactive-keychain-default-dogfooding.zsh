#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# INTERACTIVE DOG FEEDING TEST - KEYCHAIN DEFAULT EDITION
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: ADHD-friendly interactive test for the Keychain Default feature.
#          Feed the dog by testing commands and verifying outputs!
#
# Usage: ./tests/interactive-keychain-default-dogfooding.zsh
#
# What it tests:
#   - sec status (backend configuration display)
#   - sec sync --status (sync comparison)
#   - Backend switching (keychain, bitwarden, both)
#   - Token workflow without Bitwarden (the main feature!)
#   - Help text updates
#
# Controls:
#   y - Test passed, feed the dog
#   n - Test failed, dog gets hungry
#   s - Skip this test
#   q - Quit early
#
# ══════════════════════════════════════════════════════════════════════════════

# Determine paths
PLUGIN_DIR="${0:A:h:h}"
TEST_DIR="${0:A:h}"
LOG_DIR="${TEST_DIR}/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="${LOG_DIR}/keychain-default-interactive-${TIMESTAMP}.log"

mkdir -p "$LOG_DIR"

# Colors and emojis
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

DOG='🐕'
FOOD='🥩'
BOWL='🥣'
HAPPY='😊'
SAD='😢'
STAR='⭐'
CHECK='✅'
CROSS='❌'
THINKING='🤔'
EYES='👀'
KEY='🔑'
LOCK='🔐'
UNLOCK='🔓'
SYNC='🔄'
CLOUD='☁️'
LOCAL='💻'

# Game state
HUNGER=100
HAPPINESS=50
TASKS_COMPLETED=0
TOTAL_TASKS=15
PASSED=0
FAILED=0
SKIPPED=0

# Source the plugin
source "$PLUGIN_DIR/flow.plugin.zsh" 2>/dev/null

# ══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

log() {
    echo "[$(date +%H:%M:%S)] $*" >> "$LOG_FILE"
}

print_banner() {
    clear
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${DOG}  ${BOLD}KEYCHAIN DEFAULT DOG FEEDING TEST${NC}  ${KEY}              ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${LOCK}  Test the new Keychain-first secret backend!  ${UNLOCK}        ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${DIM}Feature: Keychain is now the default backend (no unlock needed!)${NC}"
    echo -e "${DIM}Log: $LOG_FILE${NC}"
    echo ""
}

print_dog_status() {
    local mood
    if [[ $HAPPINESS -gt 70 ]]; then
        mood="${GREEN}${HAPPY} Very Happy${NC}"
    elif [[ $HAPPINESS -gt 40 ]]; then
        mood="${YELLOW}${THINKING} Okay${NC}"
    else
        mood="${RED}${SAD} Sad${NC}"
    fi

    echo ""
    echo -e "${CYAN}╭─ Dog Status ─────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} Hunger:    ${YELLOW}$HUNGER%${NC}"
    echo -e "${CYAN}│${NC} Happiness: $mood"
    echo -e "${CYAN}│${NC} Tasks:     ${GREEN}$TASKS_COMPLETED${NC}/${TOTAL_TASKS} completed"

    # Show rating
    local stars=$((TASKS_COMPLETED * 5 / TOTAL_TASKS))
    local star_display=""
    for ((i=1; i<=5; i++)); do
        if [[ $i -le $stars ]]; then
            star_display="${star_display}${STAR}"
        else
            star_display="${star_display}☆"
        fi
    done
    echo -e "${CYAN}│${NC} Rating:    $star_display"
    echo -e "${CYAN}╰───────────────────────────────────────────────────────────╯${NC}"
    echo ""
}

feed_dog() {
    ((HUNGER -= 8))
    ((HAPPINESS += 5))
    [[ $HUNGER -lt 0 ]] && HUNGER=0
    [[ $HAPPINESS -gt 100 ]] && HAPPINESS=100
    echo -e "\n${GREEN}${FOOD} Yum! Dog fed! ${DOG}${NC}\n"
    log "Dog fed - Hunger: $HUNGER, Happiness: $HAPPINESS"
}

hungry_dog() {
    ((HUNGER += 5))
    ((HAPPINESS -= 10))
    [[ $HUNGER -gt 100 ]] && HUNGER=100
    [[ $HAPPINESS -lt 0 ]] && HAPPINESS=0
    echo -e "\n${RED}${SAD} Dog is disappointed... ${DOG}${NC}\n"
    log "Test failed - Hunger: $HUNGER, Happiness: $HAPPINESS"
}

run_interactive_test() {
    local test_num="$1"
    local test_title="$2"
    local command="$3"
    local expected="$4"
    local notes="${5:-}"

    ((TASKS_COMPLETED++))

    print_banner
    print_dog_status

    echo -e "${YELLOW}╭─ Task $test_num/$TOTAL_TASKS ─────────────────────────────────────────╮${NC}"
    echo -e "${YELLOW}│${NC} ${BOLD}$test_title${NC}"
    echo -e "${YELLOW}╰───────────────────────────────────────────────────────────╯${NC}"
    echo ""

    if [[ -n "$notes" ]]; then
        echo -e "${DIM}$notes${NC}"
        echo ""
    fi

    echo -e "${CYAN}Command:${NC}"
    echo -e "  ${BOLD}$command${NC}"
    echo ""

    echo -e "${CYAN}Expected:${NC}"
    echo -e "  $expected"
    echo ""

    echo -e "${CYAN}Running...${NC}"
    echo ""

    # Run the command
    local output
    output=$(eval "$command" 2>&1)

    echo -e "${CYAN}Actual Output:${NC}"
    echo "$output" | head -20
    if [[ $(echo "$output" | wc -l) -gt 20 ]]; then
        echo -e "${DIM}... (output truncated)${NC}"
    fi
    echo ""

    echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}Does the output match expected? ${NC}[y=pass, n=fail, s=skip, q=quit]"

    local response
    read -k1 "response?"
    echo ""

    case "$response" in
        y|Y)
            ((PASSED++))
            feed_dog
            log "PASS: $test_title"
            ;;
        n|N)
            ((FAILED++))
            hungry_dog
            log "FAIL: $test_title"
            ;;
        s|S)
            ((SKIPPED++))
            echo -e "\n${YELLOW}Skipped${NC}\n"
            log "SKIP: $test_title"
            ;;
        q|Q)
            print_summary
            exit 0
            ;;
    esac

    sleep 1
}

print_summary() {
    clear
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${DOG}  ${BOLD}KEYCHAIN DEFAULT - TEST COMPLETE${NC}  ${KEY}                ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    print_dog_status

    echo -e "${CYAN}━━━ Test Results ━━━${NC}"
    echo -e "  ${GREEN}Passed:${NC}  $PASSED"
    echo -e "  ${RED}Failed:${NC}  $FAILED"
    echo -e "  ${YELLOW}Skipped:${NC} $SKIPPED"
    echo ""

    if [[ $FAILED -eq 0 && $PASSED -gt 0 ]]; then
        echo -e "${GREEN}${CHECK} All tests passed! The dog is very happy! ${DOG}${HAPPY}${NC}"
    elif [[ $FAILED -gt 0 ]]; then
        echo -e "${RED}${CROSS} Some tests failed. The dog needs more attention. ${DOG}${SAD}${NC}"
    fi

    echo ""
    echo -e "${DIM}Log saved to: $LOG_FILE${NC}"
    echo ""

    log "SUMMARY: Passed=$PASSED, Failed=$FAILED, Skipped=$SKIPPED"
}

# ══════════════════════════════════════════════════════════════════════════════
# TESTS
# ══════════════════════════════════════════════════════════════════════════════

log "Starting interactive tests for Keychain Default Phase 1"

# Save current backend setting
SAVED_BACKEND="$FLOW_SECRET_BACKEND"

# ─── Test 1: Default Backend ───
run_interactive_test 1 \
    "Check Default Backend" \
    "_dotf_secret_backend" \
    "Should output: ${GREEN}keychain${NC}" \
    "The default backend is now Keychain (no FLOW_SECRET_BACKEND set)"

# ─── Test 2: Status Command ───
run_interactive_test 2 \
    "sec status (default)" \
    "unset FLOW_SECRET_BACKEND; sec status" \
    "Should show:
  - Backend: ${GREEN}keychain (default)${NC}
  - Keychain: active with location
  - Bitwarden: not configured" \
    "Status command shows current backend configuration"

# ─── Test 3: Status with Bitwarden Backend ───
run_interactive_test 3 \
    "sec status (bitwarden mode)" \
    "export FLOW_SECRET_BACKEND=bitwarden; sec status" \
    "Should show:
  - Backend: ${YELLOW}bitwarden (legacy mode)${NC}
  - Keychain: not used
  - Bitwarden: locked or unlocked" \
    "When set to bitwarden, shows legacy mode indicator"

# ─── Test 4: Status with Both Backend ───
run_interactive_test 4 \
    "sec status (both mode)" \
    "export FLOW_SECRET_BACKEND=both; sec status" \
    "Should show:
  - Backend: ${CYAN}both (sync mode)${NC}
  - Keychain: active (primary)
  - Bitwarden: status shown" \
    "When set to both, shows sync mode with both backends"

# Reset backend
unset FLOW_SECRET_BACKEND

# ─── Test 5: Sync Help ───
run_interactive_test 5 \
    "sec sync --help" \
    "sec sync --help" \
    "Should show sync commands:
  - sec sync (interactive)
  - sec sync --status
  - sec sync --to-bw
  - sec sync --from-bw" \
    "Sync help shows all available sync options"

# ─── Test 6: Sync Status ───
run_interactive_test 6 \
    "sec sync --status" \
    "sec sync --status" \
    "Should show:
  - Sync Status header
  - Keychain secrets listed
  - Bitwarden note (locked if not unlocked)" \
    "Sync status compares Keychain and Bitwarden secrets"

# ─── Test 7: Help Text Updated ───
run_interactive_test 7 \
    "sec help includes new commands" \
    "sec help" \
    "Should include:
  - ${KEY} sec status
  - ${SYNC} sec sync
  - ${LOCAL} FLOW_SECRET_BACKEND" \
    "Help text shows new backend configuration commands"

# ─── Test 8: Keychain Helper - needs_bitwarden ───
run_interactive_test 8 \
    "Keychain mode doesn't need Bitwarden" \
    "unset FLOW_SECRET_BACKEND; _dotf_secret_needs_bitwarden && echo 'needs BW' || echo 'no BW needed'" \
    "Should output: ${GREEN}no BW needed${NC}" \
    "When in keychain mode, Bitwarden is NOT required"

# ─── Test 9: Both Mode - needs_bitwarden ───
run_interactive_test 9 \
    "Both mode needs Bitwarden" \
    "export FLOW_SECRET_BACKEND=both; _dotf_secret_needs_bitwarden && echo 'needs BW' || echo 'no BW needed'" \
    "Should output: ${YELLOW}needs BW${NC}" \
    "When in both mode, Bitwarden IS required for writes"

# Reset
unset FLOW_SECRET_BACKEND

# ─── Test 10: Keychain uses_keychain ───
run_interactive_test 10 \
    "Keychain mode uses Keychain" \
    "unset FLOW_SECRET_BACKEND; _dotf_secret_uses_keychain && echo 'uses KC' || echo 'no KC'" \
    "Should output: ${GREEN}uses KC${NC}" \
    "Keychain mode uses macOS Keychain for storage"

# ─── Test 11: Bitwarden mode no keychain ───
run_interactive_test 11 \
    "Bitwarden mode doesn't use Keychain" \
    "export FLOW_SECRET_BACKEND=bitwarden; _dotf_secret_uses_keychain && echo 'uses KC' || echo 'no KC'" \
    "Should output: ${RED}no KC${NC}" \
    "Legacy bitwarden mode doesn't use Keychain"

# Reset
unset FLOW_SECRET_BACKEND

# ─── Test 12: Secret List Works ───
run_interactive_test 12 \
    "sec list (Keychain secrets)" \
    "sec list" \
    "Should show:
  - Secrets in Keychain (flow-cli):
  - List of secret names (if any)
  - Or message if none" \
    "List shows secrets stored in Keychain"

# ─── Test 13: Invalid Backend Fallback ───
run_interactive_test 13 \
    "Invalid backend falls back to keychain" \
    "export FLOW_SECRET_BACKEND=invalid_xyz; _dotf_secret_backend 2>&1 | tail -1" \
    "Should output: ${GREEN}keychain${NC}
  (May also show warning about invalid value)" \
    "Invalid backend values fall back to safe default"

# Reset
unset FLOW_SECRET_BACKEND

# ─── Test 14: Tutorial Not Auto-Run ───
run_interactive_test 14 \
    "sec status doesn't trigger tutorial" \
    "zsh -c 'source $PLUGIN_DIR/flow.plugin.zsh && sec status 2>&1 | head -5'" \
    "Should show Status output:
  - Secret Backend Status
  - ${GREEN}NOT${NC} Tutorial header
  - ${GREEN}NOT${NC} Step 1/7" \
    "Bug fix: status command no longer triggers tutorial"

# ─── Test 15: Quick Status Check ───
run_interactive_test 15 \
    "Quick Backend Check" \
    "echo 'Backend:' \$(_dotf_secret_backend); echo 'Needs BW:' \$(_dotf_secret_needs_bitwarden && echo yes || echo no); echo 'Uses KC:' \$(_dotf_secret_uses_keychain && echo yes || echo no)" \
    "Should output:
  Backend: keychain
  Needs BW: no
  Uses KC: yes" \
    "Summary check of all helper functions"

# ══════════════════════════════════════════════════════════════════════════════
# CLEANUP & SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

# Restore saved backend
[[ -n "$SAVED_BACKEND" ]] && export FLOW_SECRET_BACKEND="$SAVED_BACKEND" || unset FLOW_SECRET_BACKEND

print_summary

if [[ $FAILED -eq 0 && $PASSED -gt 0 ]]; then
    exit 0
else
    exit 1
fi
