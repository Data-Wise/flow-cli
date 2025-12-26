#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# INTERACTIVE DOG FEEDING TEST
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: ADHD-friendly interactive test that validates flow-cli commands
#          by showing expected output and asking user to confirm matches
#
# Usage: ./interactive-dog-feeding.zsh
#
# What it tests:
#   - Plugin loading
#   - Session management (work/finish)
#   - Capture commands (catch/win)
#   - Dashboard display
#   - ADHD helpers (js, next)
#   - User validation of output
#
# ══════════════════════════════════════════════════════════════════════════════

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

# Game state
HUNGER=100
HAPPINESS=50
TASKS_COMPLETED=0
TOTAL_TASKS=7

# ══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

print_banner() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${DOG}  ${BOLD}INTERACTIVE DOG FEEDING TEST${NC}  ${DOG}                     ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
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

ask_confirmation() {
    local prompt="$1"
    local default="${2:-y}"
    
    echo ""
    echo -e "${BOLD}${QUESTION} ${prompt}${NC}"
    echo -e "${DIM}(y/n, default: ${default})${NC}"
    echo -n "> "
    
    local response
    read -k1 response
    echo ""
    
    # Handle empty response (just Enter)
    [[ -z "$response" ]] && response="$default"
    
    # Normalize to lowercase
    response="${response:l}"
    
    if [[ "$response" == "y" ]]; then
        return 0
    else
        return 1
    fi
}

show_expected_output() {
    local title="$1"
    shift
    local -a expected_lines=("$@")
    
    echo ""
    echo -e "${MAGENTA}╭─ Expected Output ────────────────────────────────────────╮${NC}"
    echo -e "${MAGENTA}│${NC} ${BOLD}${title}${NC}"
    echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────╯${NC}"
    
    for line in "${expected_lines[@]}"; do
        echo -e "${DIM}  ${line}${NC}"
    done
    echo ""
}

run_interactive_test() {
    local task_name="$1"
    local command="$2"
    local -a expected_patterns=("${(@)@:3:$#-4}")
    local success_msg="${@[-2]}"
    local reward="${@[-1]}"
    
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}Task: ${task_name}${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Show what we're about to run
    echo -e "${CYAN}Command to run:${NC}"
    echo -e "${BOLD}  $ ${command}${NC}"
    
    # Show expected output
    show_expected_output "Look for these elements:" "${expected_patterns[@]}"
    
    echo -e "${YELLOW}${EYES} Watch carefully as the command runs...${NC}"
    press_any_key
    
    # Run the command and show output
    echo ""
    echo -e "${CYAN}╭─ Actual Output ──────────────────────────────────────────╮${NC}"
    eval "$command" 2>&1
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────╯${NC}"
    
    # Ask user to confirm
    if ask_confirmation "Does the output match the expected patterns?"; then
        echo -e "${GREEN}${CHECK} Great! Test passed!${NC}"
        echo ""
        echo -e "${success_msg}"
        feed_dog $reward
        return 0
    else
        echo -e "${RED}${CROSS} Hmm, something doesn't match${NC}"
        echo ""
        echo -e "${YELLOW}Let's investigate:${NC}"
        echo -e "  ${DIM}1. Check if the command ran without errors${NC}"
        echo -e "  ${DIM}2. Look for the expected patterns in the output${NC}"
        echo -e "  ${DIM}3. If missing, there may be a bug to fix${NC}"
        disappoint_dog
        
        # Ask if they want to continue anyway
        echo ""
        if ask_confirmation "Continue to next test anyway?" "y"; then
            return 1
        else
            echo ""
            echo -e "${RED}Test suite stopped by user${NC}"
            exit 1
        fi
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# SETUP
# ══════════════════════════════════════════════════════════════════════════════

print_banner

echo -e "${CYAN}Welcome to the Interactive Dog Feeding Test!${NC}"
echo ""
echo -e "Your mission: ${BOLD}Feed the dog by confirming flow-cli works${NC}"
echo ""
echo -e "How it works:"
echo -e "  ${DIM}1. We show you what to expect${NC}"
echo -e "  ${DIM}2. We run a command${NC}"
echo -e "  ${DIM}3. You confirm the output matches${NC}"
echo -e "  ${DIM}4. The dog gets fed if you confirm ${FOOD}${NC}"
echo ""
echo -e "Each successful confirmation makes the dog happier! ${HAPPY}"
echo ""

press_any_key

# Load the plugin
SCRIPT_DIR="${0:h}"
PLUGIN_FILE="${SCRIPT_DIR}/../flow.plugin.zsh"

echo -e "${BOLD}${BLUE}Loading flow-cli plugin...${NC}"
if ! source "$PLUGIN_FILE" 2>/dev/null; then
    echo -e "${RED}${CROSS} Failed to load plugin!${NC}"
    echo -e "${RED}The dog is very hungry and sad ${SAD}${NC}"
    exit 1
fi
echo -e "${GREEN}${CHECK} Plugin loaded!${NC}"
echo ""

# ══════════════════════════════════════════════════════════════════════════════
# TASK 1: Show the dashboard
# ══════════════════════════════════════════════════════════════════════════════

print_dog_status

echo -e "${DOG} ${CYAN}\"Woof! Show me the dashboard first!\"${NC}"
press_any_key

run_interactive_test \
    "Show Project Dashboard" \
    "dash" \
    "╭──────────── border line at top" \
    "│  🌊 FLOW DASHBOARD                        Dec 25, 2025  🕐 HH:MM │" \
    "╰──────────── border line below header" \
    "📊 Today: session stats" \
    "⚡ RIGHT NOW section with suggestion box" \
    "│  💡 SUGGESTION: message about what to work on" \
    "│  📊 TODAY: stats with sessions, streak, goal" \
    "📁 QUICK ACCESS (Active first)" \
    "├─ 🟢 project-name followed by description" \
    "└─ More projects listed..." \
    "📋 BY CATEGORY (X total)" \
    "├─ 📦 r-packages  [progress bar]  NN%  │  N active / N" \
    "├─ 🔧 dev-tools   [progress bar]  NN%  │  N active / N" \
    "Footer with tips: 'Try: work...' 'dash -i...' 'h for help'" \
    "${GREEN}The dog sees all your projects! ${HAPPY}${NC}" \
    15

# ══════════════════════════════════════════════════════════════════════════════
# TASK 2: Start a work session
# ══════════════════════════════════════════════════════════════════════════════

print_dog_status

echo -e "${DOG} ${CYAN}\"Let's start working on something!\"${NC}"
press_any_key

# Clean up any existing session first
finish 2>/dev/null || true

run_interactive_test \
    "Start Work Session" \
    "work flow-cli" \
    "━━━━━━━━━━━━━━━━━━ separator line at top" \
    "📗 flow-cli (node)" \
    "━━━━━━━━━━━━━━━━━━ separator line below project name" \
    "🟢 Status: active" \
    "📍 Phase: (version or phase description)" \
    "Additional project details may appear" \
    "${GREEN}Work session started! The dog approves ${STAR}${NC}" \
    20

# ══════════════════════════════════════════════════════════════════════════════
# TASK 3: Capture an idea
# ══════════════════════════════════════════════════════════════════════════════

print_dog_status

echo -e "${DOG} ${CYAN}\"Quick! Catch this idea before it runs away!\"${NC}"
press_any_key

run_interactive_test \
    "Capture an Idea" \
    "catch 'Make the dog even happier with more tests'" \
    "📥 Captured: \"Make the dog even happier with more tests\"" \
    "(Single line of confirmation)" \
    "(No errors or warnings)" \
    "${GREEN}Idea captured! The dog loves organized thoughts ${THINKING}${NC}" \
    15

# ══════════════════════════════════════════════════════════════════════════════
# TASK 4: Log a win
# ══════════════════════════════════════════════════════════════════════════════

print_dog_status

echo -e "${DOG} ${CYAN}\"Tell me about something good you did!\"${NC}"
press_any_key

run_interactive_test \
    "Log a Win" \
    "win 'Successfully fed the test dog'" \
    "(Blank line)" \
    "  🎉 WIN LOGGED!" \
    "  Successfully fed the test dog" \
    "(Blank line)" \
    "${GREEN}Win logged! The dog is proud of you ${STAR}${HAPPY}${NC}" \
    15

# ══════════════════════════════════════════════════════════════════════════════
# TASK 5: Check session is active
# ══════════════════════════════════════════════════════════════════════════════

print_dog_status

echo -e "${DOG} ${CYAN}\"Show me that active session in the dashboard!\"${NC}"
press_any_key

run_interactive_test \
    "Verify Active Session Shows in Dashboard" \
    "dash" \
    "🎯 ACTIVE SESSION • Nm elapsed" \
    "┏━━━━━━━━━━━━━━━━━━━━ box border at top" \
    "┃  📗 flow-cli (project name in the box)" \
    "┃  Focus: (focus text or description)" \
    "┗━━━━━━━━━━━━━━━━━━━━ box border at bottom" \
    "The session appears in a highlighted box with borders" \
    "${GREEN}Session confirmed active! ${CHECK}${NC}" \
    10

# ══════════════════════════════════════════════════════════════════════════════
# TASK 6: Use ADHD helper
# ══════════════════════════════════════════════════════════════════════════════

print_dog_status

echo -e "${DOG} ${CYAN}\"Sometimes you just need to start... show me 'js'!\"${NC}"
press_any_key

run_interactive_test \
    "ADHD Helper - Just Start" \
    "js" \
    "(Blank line)" \
    "🚀 JUST START" \
    "(Picking something for you...)" \
    "(Blank line)" \
    "  → project-name" \
    "(Blank line or project card with ━━━━ separators)" \
    "${GREEN}Motivation delivered! The dog believes in you ${STAR}${NC}" \
    10

# ══════════════════════════════════════════════════════════════════════════════
# TASK 7: End the session
# ══════════════════════════════════════════════════════════════════════════════

print_dog_status

echo -e "${DOG} ${CYAN}\"Time to wrap up! Finish your session.\"${NC}"
press_any_key

run_interactive_test \
    "End Work Session" \
    "finish 'Fed the test dog successfully'" \
    "✓ Session ended: Nm (time display)" \
    "OR (completely silent, no output)" \
    "(No error messages)" \
    "${GREEN}Session ended cleanly! ${CHECK}${NC}" \
    15

# ══════════════════════════════════════════════════════════════════════════════
# FINAL RESULTS
# ══════════════════════════════════════════════════════════════════════════════

print_dog_status

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  ${BOLD}FINAL RESULTS${NC}                                              ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

local grade stars_earned final_message

if [[ $TASKS_COMPLETED -eq $TOTAL_TASKS ]]; then
    stars_earned="${STAR}${STAR}${STAR}${STAR}${STAR}"
    grade="${GREEN}${BOLD}PERFECT!${NC}"
    final_message="${GREEN}${DOG} The dog is ECSTATIC! All tests confirmed! ${HAPPY}${STAR}${NC}"
elif [[ $TASKS_COMPLETED -ge 5 ]]; then
    stars_earned="${STAR}${STAR}${STAR}${STAR}"
    grade="${GREEN}EXCELLENT!${NC}"
    final_message="${GREEN}${DOG} The dog is very happy! Most tests confirmed! ${HAPPY}${NC}"
elif [[ $TASKS_COMPLETED -ge 3 ]]; then
    stars_earned="${STAR}${STAR}${STAR}"
    grade="${YELLOW}GOOD${NC}"
    final_message="${YELLOW}${DOG} The dog is satisfied. Some issues to fix! ${THINKING}${NC}"
else
    stars_earned="${STAR}"
    grade="${RED}NEEDS WORK${NC}"
    final_message="${RED}${DOG} The dog is still hungry. Several issues found! ${SAD}${NC}"
fi

echo -e "  Tasks Confirmed: ${BOLD}$TASKS_COMPLETED / $TOTAL_TASKS${NC}"
echo -e "  Final Happiness: ${BOLD}$HAPPINESS%${NC}"
echo -e "  Grade:           $grade"
echo -e "  Stars:           $stars_earned"
echo ""
echo -e "$final_message"
echo ""

if [[ $TASKS_COMPLETED -eq $TOTAL_TASKS ]]; then
    echo -e "${GREEN}${BOLD}${BOWL}${FOOD}${DOG}${HAPPY} CONGRATULATIONS! ${HAPPY}${DOG}${FOOD}${BOWL}${NC}"
    echo ""
    echo -e "${CYAN}Your flow-cli installation is working perfectly!${NC}"
    echo -e "${CYAN}All commands produced expected output.${NC}"
    echo ""
    exit 0
elif [[ $TASKS_COMPLETED -ge 4 ]]; then
    echo -e "${YELLOW}Most tests confirmed! A few issues to investigate.${NC}"
    echo -e "${DIM}Review the failed tests and check for bugs.${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}Several tests failed confirmation.${NC}"
    echo -e "${YELLOW}This suggests flow-cli may not be working correctly.${NC}"
    echo -e "${DIM}Review the output and fix any issues before using.${NC}"
    echo ""
    exit 1
fi
