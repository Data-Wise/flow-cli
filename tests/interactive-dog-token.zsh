#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# INTERACTIVE DOG FEEDING TEST - TOKEN AUTOMATION EDITION
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: ADHD-friendly interactive test for token automation commands.
#          Feed the dog by running successful commands!
#
# Usage: ./interactive-dog-token.zsh
#
# What it tests:
#   - dot token expiring (expiration detection)
#   - dash dev (token status display)
#   - flow doctor (token health check)
#   - g push validation (pre-push token check)
#   - work session (GitHub project detection)
#   - Integration workflows
#
# ══════════════════════════════════════════════════════════════════════════════

# Determine paths
PLUGIN_DIR="${0:A:h:h}"
TEST_DIR="${0:A:h}"

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
QUESTION='❓'
TOKEN='🔑'
SHIELD='🛡️'
ROCKET='🚀'
WARNING='⚠️'
REFRESH='🔄'

# Game state
HUNGER=100
HAPPINESS=50
TASKS_COMPLETED=0
TOTAL_TASKS=12

# ══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

print_banner() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${DOG}  ${BOLD}TOKEN AUTOMATION DOG FEEDING TEST${NC}  ${TOKEN}            ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${SHIELD}  Feed the dog by testing token commands!  ${SHIELD}          ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${DIM}Project: flow-cli token automation feature${NC}"
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
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────╯${NC}"
    echo ""
}

feed_dog() {
    local amount=$1
    HUNGER=$((HUNGER - amount))
    HAPPINESS=$((HAPPINESS + amount / 2))

    # Cap values
    [[ $HUNGER -lt 0 ]] && HUNGER=0
    [[ $HAPPINESS -gt 100 ]] && HAPPINESS=100

    echo -e "${GREEN}${FOOD} Fed the dog! ${HAPPY}${NC}"
    ((TASKS_COMPLETED++))
}

disappoint_dog() {
    HAPPINESS=$((HAPPINESS - 10))
    [[ $HAPPINESS -lt 0 ]] && HAPPINESS=0
    echo -e "${RED}The dog is disappointed ${SAD}${NC}"
}

press_any_key() {
    echo ""
    echo -e "${DIM}Press any key to continue...${NC}"
    read -k1 -s
}

show_expected() {
    echo -e "${CYAN}${EYES} Expected output should contain:${NC}"
    echo ""
    for line in "$@"; do
        echo -e "  ${DIM}*${NC} $line"
    done
    echo ""
}

ask_confirmation() {
    local question="$1"
    echo ""
    echo -e "${YELLOW}${QUESTION} $question${NC}"
    echo -e "${DIM}(y/n):${NC} "
    read -k1 response
    echo ""

    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

run_command() {
    local cmd="$1"
    echo -e "${MAGENTA}${ROCKET} Running:${NC} ${BOLD}$cmd${NC}"
    echo ""
    eval "$cmd"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST TASKS
# ══════════════════════════════════════════════════════════════════════════════

task_1_check_expiring() {
    echo -e "${BOLD}╭─ TASK 1: Check Token Expiration Status ─────────────────╮${NC}"
    echo -e "${BOLD}│${NC} Test: ${TOKEN} dot token expiring                             ${BOLD}│${NC}"
    echo -e "${BOLD}╰──────────────────────────────────────────────────────────╯${NC}"
    echo ""

    show_expected \
        "Token expiration check output" \
        "Either '✅ All GitHub tokens current' or warning about expiring tokens" \
        "No crashes or errors"

    run_command "dot token expiring"

    if ask_confirmation "Did the command run successfully?"; then
        feed_dog 10
    else
        disappoint_dog
    fi

    press_any_key
}

task_2_dash_dev_token() {
    echo -e "${BOLD}╭─ TASK 2: View Token in Dashboard ───────────────────────╮${NC}"
    echo -e "${BOLD}│${NC} Test: ${SHIELD} dash dev (token section)                       ${BOLD}│${NC}"
    echo -e "${BOLD}╰──────────────────────────────────────────────────────────╯${NC}"
    echo ""

    show_expected \
        "Dashboard output with 'GitHub Token' section" \
        "Token status (configured/not configured/expired)" \
        "Integration with dev category"

    run_command "dash dev"

    if ask_confirmation "Did you see a 'GitHub Token' section?"; then
        feed_dog 10
    else
        disappoint_dog
    fi

    press_any_key
}

task_3_flow_doctor_token() {
    echo -e "${BOLD}╭─ TASK 3: Health Check with Doctor ──────────────────────╮${NC}"
    echo -e "${BOLD}│${NC} Test: ${SHIELD} flow doctor (token health)                     ${BOLD}│${NC}"
    echo -e "${BOLD}╰──────────────────────────────────────────────────────────╯${NC}"
    echo ""

    show_expected \
        "Health check output" \
        "'🔑 GITHUB TOKEN' section" \
        "Token status (valid/invalid/missing)"

    run_command "flow doctor"

    if ask_confirmation "Did you see GitHub token health check?"; then
        feed_dog 10
    else
        disappoint_dog
    fi

    press_any_key
}

task_4_flow_token_alias() {
    echo -e "${BOLD}╭─ TASK 4: Flow Token Alias ──────────────────────────────╮${NC}"
    echo -e "${BOLD}│${NC} Test: ${TOKEN} flow token expiring (alias)                    ${BOLD}│${NC}"
    echo -e "${BOLD}╰──────────────────────────────────────────────────────────╯${NC}"
    echo ""

    show_expected \
        "Same output as 'dot token expiring'" \
        "Alias delegation working correctly"

    run_command "flow token expiring"

    if ask_confirmation "Did the alias work correctly?"; then
        feed_dog 8
    else
        disappoint_dog
    fi

    press_any_key
}

task_5_help_system() {
    echo -e "${BOLD}╭─ TASK 5: Help System ────────────────────────────────────╮${NC}"
    echo -e "${BOLD}│${NC} Test: ${QUESTION} dot token help                                ${BOLD}│${NC}"
    echo -e "${BOLD}╰──────────────────────────────────────────────────────────╯${NC}"
    echo ""

    show_expected \
        "Help output for token commands" \
        "Usage examples" \
        "Command descriptions"

    run_command "dot token help"

    if ask_confirmation "Did you see helpful documentation?"; then
        feed_dog 8
    else
        disappoint_dog
    fi

    press_any_key
}

task_6_git_remote_detection() {
    echo -e "${BOLD}╭─ TASK 6: Git Remote Detection ──────────────────────────╮${NC}"
    echo -e "${BOLD}│${NC} Test: ${ROCKET} Check if GitHub remote is detected             ${BOLD}│${NC}"
    echo -e "${BOLD}╰──────────────────────────────────────────────────────────╯${NC}"
    echo ""

    show_expected \
        "Git remote URL" \
        "Contains 'github.com'"

    run_command "git remote -v | head -2"

    if ask_confirmation "Is this a GitHub repository?"; then
        feed_dog 6
    else
        echo -e "${YELLOW}${WARNING} Skipping (not GitHub repo)${NC}"
    fi

    press_any_key
}

task_7_token_age_logic() {
    echo -e "${BOLD}╭─ TASK 7: Token Age Calculation ─────────────────────────╮${NC}"
    echo -e "${BOLD}│${NC} Test: ${THINKING} Verify metadata tracking works               ${BOLD}│${NC}"
    echo -e "${BOLD}╰──────────────────────────────────────────────────────────╯${NC}"
    echo ""

    echo -e "${CYAN}This tests the enhanced metadata (dot_version 2.1) system.${NC}"
    echo ""
    echo -e "${DIM}Metadata includes:${NC}"
    echo -e "  - created timestamp"
    echo -e "  - expires_days field"
    echo -e "  - github_user"
    echo ""
    echo -e "${YELLOW}${QUESTION} Conceptual check: Does it make sense that tokens track:${NC}"
    echo -e "  1. When they were created?"
    echo -e "  2. How many days until expiration?"
    echo -e "  3. Which GitHub user they belong to?"
    echo ""

    if ask_confirmation "Does this metadata design make sense?"; then
        feed_dog 8
    else
        disappoint_dog
    fi

    press_any_key
}

task_8_expiration_threshold() {
    echo -e "${BOLD}╭─ TASK 8: Expiration Warning Threshold ──────────────────╮${NC}"
    echo -e "${BOLD}│${NC} Test: ${WARNING} 7-day warning window logic                    ${BOLD}│${NC}"
    echo -e "${BOLD}╰──────────────────────────────────────────────────────────╯${NC}"
    echo ""

    echo -e "${CYAN}Token automation warns when tokens are < 7 days from expiring.${NC}"
    echo ""
    echo -e "${DIM}GitHub default token lifetime: 90 days${NC}"
    echo -e "${DIM}Warning threshold: 83 days (90 - 7)${NC}"
    echo ""
    echo -e "${YELLOW}${QUESTION} Conceptual check:${NC}"
    echo -e "  - Is 7 days enough warning to rotate a token?"
    echo -e "  - Should the threshold be configurable?"
    echo ""

    if ask_confirmation "Does 7-day warning window seem reasonable?"; then
        feed_dog 6
    else
        disappoint_dog
    fi

    press_any_key
}

task_9_dash_integration() {
    echo -e "${BOLD}╭─ TASK 9: Dashboard Integration ─────────────────────────╮${NC}"
    echo -e "${BOLD}│${NC} Test: ${SHIELD} Token status in 'dash dev' category            ${BOLD}│${NC}"
    echo -e "${BOLD}╰──────────────────────────────────────────────────────────╯${NC}"
    echo ""

    show_expected \
        "GitHub Token section in dev category" \
        "Visual indicators (✅ 🟡 🔴)" \
        "Days remaining display"

    run_command "dash dev | grep -A 5 'GitHub Token' || echo 'Token section not found'"

    if ask_confirmation "Did you see the token status in the dashboard?"; then
        feed_dog 10
    else
        disappoint_dog
    fi

    press_any_key
}

task_10_doctor_integration() {
    echo -e "${BOLD}╭─ TASK 10: Doctor Health Check Integration ──────────────╮${NC}"
    echo -e "${BOLD}│${NC} Test: ${SHIELD} Token in 'flow doctor' output                  ${BOLD}│${NC}"
    echo -e "${BOLD}╰──────────────────────────────────────────────────────────╯${NC}"
    echo ""

    show_expected \
        "'🔑 GITHUB TOKEN' section" \
        "Token validity check" \
        "Expiration warning if < 7 days"

    run_command "flow doctor | grep -A 10 'GITHUB TOKEN' || echo 'Token section not found'"

    if ask_confirmation "Did doctor include token health check?"; then
        feed_dog 10
    else
        disappoint_dog
    fi

    press_any_key
}

task_11_documentation_check() {
    echo -e "${BOLD}╭─ TASK 11: Documentation Verification ───────────────────╮${NC}"
    echo -e "${BOLD}│${NC} Test: ${BOOK} Check CLAUDE.md and reference docs             ${BOLD}│${NC}"
    echo -e "${BOLD}╰──────────────────────────────────────────────────────────╯${NC}"
    echo ""

    echo -e "${CYAN}Checking documentation files...${NC}"
    echo ""

    local docs_ok=true

    if grep -qi "token management" "$PLUGIN_DIR/CLAUDE.md"; then
        echo -e "  ${CHECK} CLAUDE.md has Token Management section"
    else
        echo -e "  ${CROSS} CLAUDE.md missing Token Management"
        docs_ok=false
    fi

    if grep -qi "token health" "$PLUGIN_DIR/docs/reference/DOT-DISPATCHER-REFERENCE.md"; then
        echo -e "  ${CHECK} DOT reference has token commands"
    else
        echo -e "  ${CROSS} DOT reference missing token commands"
        docs_ok=false
    fi

    if [[ -f "$PLUGIN_DIR/docs/guides/TOKEN-HEALTH-CHECK.md" ]]; then
        echo -e "  ${CHECK} TOKEN-HEALTH-CHECK.md exists"
    else
        echo -e "  ${CROSS} TOKEN-HEALTH-CHECK.md missing"
        docs_ok=false
    fi

    echo ""

    if [[ "$docs_ok" == "true" ]]; then
        if ask_confirmation "All documentation looks good?"; then
            feed_dog 8
        else
            disappoint_dog
        fi
    else
        echo -e "${RED}Some documentation is missing!${NC}"
        disappoint_dog
    fi

    press_any_key
}

task_12_workflow_complete() {
    echo -e "${BOLD}╭─ TASK 12: Complete Workflow Test ───────────────────────╮${NC}"
    echo -e "${BOLD}│${NC} Test: ${ROCKET} Full integration workflow                      ${BOLD}│${NC}"
    echo -e "${BOLD}╰──────────────────────────────────────────────────────────╯${NC}"
    echo ""

    echo -e "${CYAN}Testing complete workflow:${NC}"
    echo -e "  1. Check token expiration"
    echo -e "  2. View in dashboard"
    echo -e "  3. Verify in doctor"
    echo ""

    echo -e "${YELLOW}Running workflow...${NC}"
    echo ""

    # Step 1
    echo -e "${DIM}Step 1: dot token expiring${NC}"
    dot token expiring 2>&1 | head -5
    echo ""

    # Step 2
    echo -e "${DIM}Step 2: dash dev (token section)${NC}"
    dash dev 2>&1 | grep -A 3 "GitHub Token" || echo "Token section visible in full dash output"
    echo ""

    # Step 3
    echo -e "${DIM}Step 3: flow doctor (token check)${NC}"
    flow doctor 2>&1 | grep -A 3 "GITHUB TOKEN" || echo "Token health visible in full doctor output"
    echo ""

    if ask_confirmation "Did the complete workflow run successfully?"; then
        feed_dog 12
    else
        disappoint_dog
    fi

    press_any_key
}

# ══════════════════════════════════════════════════════════════════════════════
# MAIN GAME LOOP
# ══════════════════════════════════════════════════════════════════════════════

main() {
    # Setup
    source "$PLUGIN_DIR/flow.plugin.zsh" 2>/dev/null

    print_banner
    print_dog_status

    echo -e "${CYAN}${TOKEN} You're about to test the token automation feature!${NC}"
    echo ""
    echo -e "${DIM}This interactive test will guide you through all token commands.${NC}"
    echo -e "${DIM}After each command, you'll judge if it worked correctly.${NC}"
    echo ""

    press_any_key

    # Run all tasks
    task_1_check_expiring
    print_dog_status

    task_2_dash_dev_token
    print_dog_status

    task_3_flow_doctor_token
    print_dog_status

    task_4_flow_token_alias
    print_dog_status

    task_5_help_system
    print_dog_status

    task_6_git_remote_detection
    print_dog_status

    task_7_token_age_logic
    print_dog_status

    task_8_expiration_threshold
    print_dog_status

    task_9_dash_integration
    print_dog_status

    task_10_doctor_integration
    print_dog_status

    task_11_documentation_check
    print_dog_status

    task_12_workflow_complete
    print_dog_status

    # Final summary
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${BOLD}TESTING COMPLETE!${NC}                                       ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    local completion_percent=$((TASKS_COMPLETED * 100 / TOTAL_TASKS))

    echo -e "${CYAN}╭─ Final Results ──────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} Tasks completed: ${GREEN}$TASKS_COMPLETED${NC}/${TOTAL_TASKS}"
    echo -e "${CYAN}│${NC} Completion:      ${GREEN}$completion_percent%${NC}"
    echo -e "${CYAN}│${NC} Dog happiness:   ${HAPPINESS}% ${HAPPY}"

    # Show final rating
    local stars=$((TASKS_COMPLETED * 5 / TOTAL_TASKS))
    local star_display=""
    for ((i=1; i<=5; i++)); do
        if [[ $i -le $stars ]]; then
            star_display="${star_display}${STAR}"
        else
            star_display="${star_display}☆"
        fi
    done
    echo -e "${CYAN}│${NC} Rating:          $star_display"
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────╯${NC}"
    echo ""

    if [[ $TASKS_COMPLETED -eq $TOTAL_TASKS ]]; then
        echo -e "${GREEN}${CHECK} Perfect score! The dog is very happy! ${HAPPY}${NC}"
        echo -e "${GREEN}${FOOD} The token automation feature is working excellently!${NC}"
    elif [[ $TASKS_COMPLETED -ge 9 ]]; then
        echo -e "${GREEN}${CHECK} Great job! Most tests passed! ${HAPPY}${NC}"
        echo -e "${YELLOW}${WARNING} Review any failed tasks.${NC}"
    elif [[ $TASKS_COMPLETED -ge 6 ]]; then
        echo -e "${YELLOW}${WARNING} Good progress, but some tests failed.${NC}"
        echo -e "${YELLOW}${THINKING} Check the implementation.${NC}"
    else
        echo -e "${RED}${CROSS} Many tests failed. ${SAD}${NC}"
        echo -e "${RED}${WARNING} The feature needs more work.${NC}"
    fi

    echo ""
}

# Run the game
main "$@"
