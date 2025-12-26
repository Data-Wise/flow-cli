#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# INTERACTIVE DOG FEEDING TEST
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: ADHD-friendly interactive test that validates flow-cli commands
#          through a gamified dog feeding scenario
#
# Usage: ./interactive-dog-feeding.zsh
#
# What it tests:
#   - Plugin loading
#   - Session management (work/finish)
#   - Capture commands (catch/win)
#   - Dashboard display
#   - ADHD helpers (js, next)
#   - User interaction and feedback
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

press_any_key() {
    echo -e "${DIM}Press any key to continue...${NC}"
    read -k1 -s
}

run_test() {
    local task_name="$1"
    local command="$2"
    local success_msg="$3"
    local reward=${4:-10}
    
    echo -e "${BOLD}${BLUE}Task: ${task_name}${NC}"
    echo -e "${DIM}Running: ${command}${NC}"
    echo ""
    
    # Run the command and capture output
    local output
    output=$(eval "$command" 2>&1)
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}${CHECK} Success!${NC}"
        echo "$output" | head -5
        echo ""
        echo -e "${success_msg}"
        feed_dog $reward
        return 0
    else
        echo -e "${RED}${CROSS} Failed${NC}"
        echo "$output" | head -10
        echo ""
        echo -e "${RED}The dog is disappointed ${SAD}${NC}"
        HAPPINESS=$((HAPPINESS - 5))
        return 1
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# SETUP
# ══════════════════════════════════════════════════════════════════════════════

print_banner

echo -e "${CYAN}Welcome to the Interactive Dog Feeding Test!${NC}"
echo ""
echo -e "Your mission: ${BOLD}Feed the dog by completing flow-cli tasks${NC}"
echo ""
echo -e "Each successful task earns you ${FOOD} to feed your dog."
echo -e "The happier the dog, the better your flow-cli setup!"
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
echo ""
press_any_key

run_test \
    "Show Project Dashboard" \
    "dash 2>&1 | head -20" \
    "${GREEN}The dog sees all your projects! ${HAPPY}${NC}" \
    15

press_any_key

# ══════════════════════════════════════════════════════════════════════════════
# TASK 2: Start a work session
# ══════════════════════════════════════════════════════════════════════════════

print_dog_status

echo -e "${DOG} ${CYAN}\"Let's start working on something!\"${NC}"
echo ""
press_any_key

# Clean up any existing session first
finish 2>/dev/null || true

run_test \
    "Start Work Session" \
    "work flow-cli 2>&1" \
    "${GREEN}Work session started! The dog approves ${STAR}${NC}" \
    20

press_any_key

# ══════════════════════════════════════════════════════════════════════════════
# TASK 3: Capture an idea
# ══════════════════════════════════════════════════════════════════════════════

print_dog_status

echo -e "${DOG} ${CYAN}\"Quick! Catch this idea before it runs away!\"${NC}"
echo ""
press_any_key

run_test \
    "Capture an Idea" \
    "catch 'Make the dog even happier with more tests' 2>&1" \
    "${GREEN}Idea captured! The dog loves organized thoughts ${THINKING}${NC}" \
    15

press_any_key

# ══════════════════════════════════════════════════════════════════════════════
# TASK 4: Log a win
# ══════════════════════════════════════════════════════════════════════════════

print_dog_status

echo -e "${DOG} ${CYAN}\"Tell me about something good you did!\"${NC}"
echo ""
press_any_key

run_test \
    "Log a Win" \
    "win 'Successfully fed the test dog' 2>&1" \
    "${GREEN}Win logged! The dog is proud of you ${STAR}${HAPPY}${NC}" \
    15

press_any_key

# ══════════════════════════════════════════════════════════════════════════════
# TASK 5: Check session with dash
# ══════════════════════════════════════════════════════════════════════════════

print_dog_status

echo -e "${DOG} ${CYAN}\"Show me that active session!\"${NC}"
echo ""
press_any_key

run_test \
    "Verify Active Session" \
    "[[ -f ~/.local/share/flow/.current-session ]] && echo 'Session is active!' || echo 'No session found'" \
    "${GREEN}Session confirmed active! ${CHECK}${NC}" \
    10

press_any_key

# ══════════════════════════════════════════════════════════════════════════════
# TASK 6: Use ADHD helper
# ══════════════════════════════════════════════════════════════════════════════

print_dog_status

echo -e "${DOG} ${CYAN}\"Sometimes you just need to start... show me 'js'!\"${NC}"
echo ""
press_any_key

run_test \
    "ADHD Helper - Just Start" \
    "js 2>&1 | head -10" \
    "${GREEN}Motivation delivered! The dog believes in you ${STAR}${NC}" \
    10

press_any_key

# ══════════════════════════════════════════════════════════════════════════════
# TASK 7: End the session
# ══════════════════════════════════════════════════════════════════════════════

print_dog_status

echo -e "${DOG} ${CYAN}\"Time to wrap up! Finish your session.\"${NC}"
echo ""
press_any_key

run_test \
    "End Work Session" \
    "finish 'Fed the test dog successfully' 2>&1" \
    "${GREEN}Session ended cleanly! ${CHECK}${NC}" \
    15

press_any_key

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
    final_message="${GREEN}${DOG} The dog is ECSTATIC! All tests passed! ${HAPPY}${STAR}${NC}"
elif [[ $TASKS_COMPLETED -ge 5 ]]; then
    stars_earned="${STAR}${STAR}${STAR}${STAR}"
    grade="${GREEN}EXCELLENT!${NC}"
    final_message="${GREEN}${DOG} The dog is very happy! Most tests passed! ${HAPPY}${NC}"
elif [[ $TASKS_COMPLETED -ge 3 ]]; then
    stars_earned="${STAR}${STAR}${STAR}"
    grade="${YELLOW}GOOD${NC}"
    final_message="${YELLOW}${DOG} The dog is satisfied. Keep improving! ${THINKING}${NC}"
else
    stars_earned="${STAR}"
    grade="${RED}NEEDS WORK${NC}"
    final_message="${RED}${DOG} The dog is still hungry. Fix those errors! ${SAD}${NC}"
fi

echo -e "  Tasks Completed: ${BOLD}$TASKS_COMPLETED / $TOTAL_TASKS${NC}"
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
    echo ""
    exit 0
else
    echo -e "${YELLOW}Some tasks failed. Check the output above for details.${NC}"
    echo ""
    exit 1
fi
