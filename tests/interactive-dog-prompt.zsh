#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# INTERACTIVE DOG FEEDING TEST - TEACH PROMPT EDITION
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: ADHD-friendly interactive test for teach prompt commands
#          using the demo course. Feed the dog by running successful commands!
#
# Usage: ./interactive-dog-prompt.zsh
#
# What it tests:
#   - teach prompt list (basic and filtered)
#   - teach prompt show (with various flags)
#   - teach prompt edit (creating overrides)
#   - teach prompt validate (syntax and Scholar compatibility)
#   - teach prompt export (variable rendering)
#   - 3-tier resolution (course > user > plugin)
#   - Override detection and tier indicators
#   - Scholar integration
#
# ══════════════════════════════════════════════════════════════════════════════

# Determine paths
PLUGIN_DIR="${0:A:h:h}"
TEST_DIR="${0:A:h}"
DEMO_COURSE="$TEST_DIR/fixtures/demo-course"

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
BOOK='📚'
TEACHER='👩‍🏫'
PROMPT='📝'
SPARKLE='✨'
ROCKET='🚀'
GEAR='⚙️'
MAGNIFY='🔍'

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
    echo -e "${BLUE}║${NC}  ${DOG}  ${BOLD}TEACH PROMPT DOG FEEDING TEST${NC}  ${PROMPT}                ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${BOOK}  Feed the dog by testing prompt commands!  ${BOOK}         ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${DIM}Demo Course: STAT-101 (Introduction to Statistics)${NC}"
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

    echo -e "${CYAN}│${NC} Rating:    ${star_display}"
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────╯${NC}"
    echo ""
}

print_task() {
    local num=$1
    local title="$2"
    local icon="$3"

    echo ""
    echo -e "${MAGENTA}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}Task ${num}/${TOTAL_TASKS}: ${icon} ${title}${NC}"
    echo -e "${MAGENTA}════════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_command() {
    local cmd="$1"
    echo ""
    echo -e "${CYAN}${GEAR} Command to run:${NC}"
    echo -e "${BOLD}  $ ${cmd}${NC}"
    echo ""
}

print_expected() {
    local desc="$1"
    echo -e "${DIM}${EYES} Expected: ${desc}${NC}"
    echo ""
}

wait_for_user() {
    echo -ne "${YELLOW}Press ENTER when you've run the command and want to verify...${NC}"
    read
}

ask_user() {
    local question="$1"
    echo ""
    echo -e "${QUESTION} ${question}"
    echo -ne "${YELLOW}[y/n]: ${NC}"
    read -r response
    [[ "$response" =~ ^[Yy] ]]
}

feed_dog() {
    local amount=$1
    HUNGER=$((HUNGER - amount))
    HAPPINESS=$((HAPPINESS + amount / 2))
    ((TASKS_COMPLETED++))

    echo ""
    echo -e "${GREEN}${FOOD} Yum! Dog ate ${amount} points of food!${NC}"
    echo -e "${GREEN}${HAPPY} Happiness increased!${NC}"
}

punish_dog() {
    HAPPINESS=$((HAPPINESS - 10))
    echo ""
    echo -e "${RED}${SAD} Dog is sad because the task failed...${NC}"
}

# ══════════════════════════════════════════════════════════════════════════════
# SETUP
# ══════════════════════════════════════════════════════════════════════════════

setup() {
    # Source the plugin
    if [[ -f "$PLUGIN_DIR/flow.plugin.zsh" ]]; then
        source "$PLUGIN_DIR/flow.plugin.zsh"
    else
        echo -e "${RED}${CROSS} Error: Cannot find flow.plugin.zsh${NC}"
        exit 1
    fi

    # Change to demo course directory
    if [[ -d "$DEMO_COURSE" ]]; then
        cd "$DEMO_COURSE"
    else
        echo -e "${RED}${CROSS} Error: Demo course not found at $DEMO_COURSE${NC}"
        exit 1
    fi

    # Clean user-level prompts from previous runs
    rm -rf ~/.flow/prompts 2>/dev/null

    echo -e "${GREEN}${CHECK} Setup complete!${NC}"
    echo -e "${DIM}Working directory: $(pwd)${NC}"
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST TASKS
# ══════════════════════════════════════════════════════════════════════════════

task_1_list_all() {
    print_task 1 "List All Teaching Prompts" "$MAGNIFY"

    echo "Let's see what teaching prompts are available!"
    echo ""
    echo "The demo course has 2 course-level prompts that override plugin defaults."

    print_command "teach prompt list"
    print_expected "Should show prompts with [C], [U], [P] tier indicators"

    wait_for_user

    if ask_user "Did you see a list of prompts with tier indicators?"; then
        feed_dog 10
    else
        punish_dog
    fi
}

task_2_list_filtered() {
    print_task 2 "Filter by Tier" "$MAGNIFY"

    echo "Now let's filter to see only course-level overrides."

    print_command "teach prompt list --tier course"
    print_expected "Should show only prompts with [C] indicator (2 prompts)"

    wait_for_user

    if ask_user "Did you see only course-level prompts (lecture-notes, quiz-questions)?"; then
        feed_dog 8
    else
        punish_dog
    fi
}

task_3_show_basic() {
    print_task 3 "Show Prompt Content" "$EYES"

    echo "Let's look at the lecture-notes prompt in detail."

    print_command "teach prompt show lecture-notes"
    print_expected "Should open in pager with header showing [course] tier"

    wait_for_user

    if ask_user "Did you see the prompt content with course-specific instructions?"; then
        feed_dog 10
    else
        punish_dog
    fi
}

task_4_show_raw() {
    print_task 4 "Show Raw Prompt" "$PROMPT"

    echo "Now let's see the raw content including YAML frontmatter."

    print_command "teach prompt show lecture-notes --raw"
    print_expected "Should show YAML frontmatter and full content (no pager)"

    wait_for_user

    if ask_user "Did you see the YAML frontmatter (---...---)? "; then
        feed_dog 8
    else
        punish_dog
    fi
}

task_5_show_plugin() {
    print_task 5 "View Plugin Default" "$BOOK"

    echo "Let's look at a prompt that only exists at the plugin level."

    print_command "teach prompt show derivations-appendix"
    print_expected "Should show plugin-level prompt with [plugin] tier"

    wait_for_user

    if ask_user "Did you see the derivations-appendix prompt from plugin defaults?"; then
        feed_dog 8
    else
        punish_dog
    fi
}

task_6_validate_all() {
    print_task 6 "Validate All Prompts" "$CHECK"

    echo "Let's validate syntax and Scholar compatibility for all prompts."

    print_command "teach prompt validate"
    print_expected "Should show validation results with ✓ or ✗ for each prompt"

    wait_for_user

    if ask_user "Did validation pass for all (or most) prompts?"; then
        feed_dog 10
    else
        punish_dog
    fi
}

task_7_edit_global() {
    print_task 7 "Create User-Level Override" "$GEAR"

    echo "Let's create a user-level override for revealjs-slides."
    echo "This will copy the plugin default to ~/.flow/prompts/"

    print_command "teach prompt edit revealjs-slides --global"
    print_expected "Should copy plugin prompt to ~/.flow/prompts/ and open in editor"
    echo ""
    echo -e "${YELLOW}${THINKING} Note: Just save and quit the editor (don't make changes)${NC}"

    wait_for_user

    if [[ -f ~/.flow/prompts/revealjs-slides.md ]]; then
        if ask_user "Did the editor open with the prompt content?"; then
            feed_dog 12
        else
            punish_dog
        fi
    else
        echo -e "${RED}${CROSS} File not created at ~/.flow/prompts/revealjs-slides.md${NC}"
        punish_dog
    fi
}

task_8_verify_override() {
    print_task 8 "Verify User Override" "$SPARKLE"

    echo "Now let's verify that the user-level override shows up with [U] indicator."

    print_command "teach prompt list"
    print_expected "revealjs-slides should now show [U] instead of [P]"

    wait_for_user

    if ask_user "Does revealjs-slides show [U] tier indicator?"; then
        feed_dog 10
    else
        punish_dog
    fi
}

task_9_edit_course() {
    print_task 9 "Modify Course Prompt" "$GEAR"

    echo "Let's edit the existing course-level lecture-notes prompt."

    print_command "teach prompt edit lecture-notes"
    print_expected "Should open existing .flow/templates/prompts/lecture-notes.md"
    echo ""
    echo -e "${YELLOW}${THINKING} Note: Just save and quit (don't make changes)${NC}"

    wait_for_user

    if ask_user "Did the editor open with the course-level prompt?"; then
        feed_dog 8
    else
        punish_dog
    fi
}

task_10_export_basic() {
    print_task 10 "Export Rendered Prompt" "$ROCKET"

    echo "Let's export a prompt with variables resolved."
    echo "This shows what gets sent to Scholar."

    print_command "teach prompt export lecture-notes"
    print_expected "Should show rendered prompt with {{COURSE}} etc. replaced"

    wait_for_user

    if ask_user "Did you see rendered content with variables filled in?"; then
        feed_dog 10
    else
        punish_dog
    fi
}

task_11_export_json() {
    print_task 11 "Export as JSON" "$BOOK"

    echo "Let's export prompt metadata as JSON for programmatic use."

    print_command "teach prompt export lecture-notes --json"
    print_expected "Should show JSON with name, tier, path, and rendered content"

    wait_for_user

    if ask_user "Did you see JSON output with 'name', 'tier', 'rendered' fields?"; then
        feed_dog 8
    else
        punish_dog
    fi
}

task_12_help_system() {
    print_task 12 "Explore Help System" "$QUESTION"

    echo "Finally, let's check out the built-in help."

    print_command "teach prompt help"
    print_expected "Should show comprehensive help with examples and 3-tier diagram"

    wait_for_user

    if ask_user "Did you see the help with usage, examples, and tier resolution info?"; then
        feed_dog 10
    else
        punish_dog
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# FINAL SCORE
# ══════════════════════════════════════════════════════════════════════════════

show_final_score() {
    echo ""
    echo -e "${MAGENTA}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}                     FINAL RESULTS                          ${NC}"
    echo -e "${MAGENTA}════════════════════════════════════════════════════════════${NC}"
    echo ""

    print_dog_status

    local percentage=$((TASKS_COMPLETED * 100 / TOTAL_TASKS))
    local grade

    if [[ $percentage -ge 90 ]]; then
        grade="${GREEN}A+ Excellent!${NC} ${STAR}${STAR}${STAR}${STAR}${STAR}"
    elif [[ $percentage -ge 80 ]]; then
        grade="${GREEN}A Great work!${NC} ${STAR}${STAR}${STAR}${STAR}"
    elif [[ $percentage -ge 70 ]]; then
        grade="${YELLOW}B Good job!${NC} ${STAR}${STAR}${STAR}"
    elif [[ $percentage -ge 60 ]]; then
        grade="${YELLOW}C Fair${NC} ${STAR}${STAR}"
    else
        grade="${RED}D Needs work${NC} ${STAR}"
    fi

    echo -e "${BOLD}Score: ${percentage}%${NC}"
    echo -e "Grade: ${grade}"
    echo ""

    if [[ $TASKS_COMPLETED -eq $TOTAL_TASKS ]]; then
        echo -e "${GREEN}${SPARKLE} Perfect score! The dog is very happy! ${DOG}${HAPPY}${NC}"
        echo ""
        echo -e "${GREEN}You've mastered teach prompt commands!${NC}"
    elif [[ $TASKS_COMPLETED -ge 10 ]]; then
        echo -e "${GREEN}${HAPPY} Great job! The dog is happy! ${DOG}${NC}"
    elif [[ $TASKS_COMPLETED -ge 8 ]]; then
        echo -e "${YELLOW}${THINKING} Good effort! The dog is satisfied. ${DOG}${NC}"
    else
        echo -e "${RED}${SAD} The dog needs more food... Try again? ${DOG}${NC}"
    fi

    echo ""
    echo -e "${CYAN}╭─ What You Learned ───────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} ${CHECK} How to list teaching prompts"
    echo -e "${CYAN}│${NC} ${CHECK} How to view prompt content"
    echo -e "${CYAN}│${NC} ${CHECK} How to create course and user overrides"
    echo -e "${CYAN}│${NC} ${CHECK} How to validate prompt syntax"
    echo -e "${CYAN}│${NC} ${CHECK} How to export rendered prompts"
    echo -e "${CYAN}│${NC} ${CHECK} Understanding 3-tier resolution"
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────╯${NC}"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════════════════

main() {
    print_banner
    setup

    echo ""
    echo -e "${BOLD}${SPARKLE} Let's start feeding the dog! ${DOG}${SPARKLE}${NC}"
    echo ""
    echo -e "${DIM}You'll run each command and verify the output."
    echo -e "The dog gets fed when you complete tasks successfully!${NC}"
    echo ""

    echo -ne "${YELLOW}Press ENTER to begin...${NC}"
    read

    # Run all tasks
    task_1_list_all
    task_2_list_filtered
    task_3_show_basic
    task_4_show_raw
    task_5_show_plugin
    task_6_validate_all
    task_7_edit_global
    task_8_verify_override
    task_9_edit_course
    task_10_export_basic
    task_11_export_json
    task_12_help_system

    show_final_score
}

# Run the test
main
