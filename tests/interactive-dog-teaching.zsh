#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# INTERACTIVE DOG FEEDING TEST - TEACHING EDITION
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: ADHD-friendly interactive test for teach analyze commands
#          using the demo course. Feed the dog by running successful commands!
#
# Usage: ./interactive-dog-teaching.zsh
#
# What it tests:
#   - teach analyze single file
#   - teach analyze batch mode
#   - teach validate (prerequisite checking)
#   - teach analyze --slide-breaks
#   - Cache usage and invalidation
#   - Circular dependency detection
#   - User validation of output
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
GRAPH='📊'
BRAIN='🧠'

# Game state
HUNGER=100
HAPPINESS=50
TASKS_COMPLETED=0
TOTAL_TASKS=10

# ══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

print_banner() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${DOG}  ${BOLD}TEACH ANALYZE DOG FEEDING TEST${NC}  ${TEACHER}              ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${BOOK}  Feed the dog by testing teach commands!  ${BOOK}          ${BLUE}║${NC}"
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

cleanup_demo_course() {
    rm -rf "$DEMO_COURSE/.teach/analysis-cache" 2>/dev/null
    rm -rf "$DEMO_COURSE/.teach/reports" 2>/dev/null
}

log_test_result() {
    local task_num="$1"
    local task_name="$2"
    local command="$3"
    local success="$4"
    local output="$5"

    echo "═══════════════════════════════════════════════════════════════" >> "$LOG_FILE"
    echo "Task $task_num: $task_name" >> "$LOG_FILE"
    echo "Time: $(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
    echo "Command: $command" >> "$LOG_FILE"
    echo "Success: $success" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "Output:" >> "$LOG_FILE"
    echo "$output" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
}

# ══════════════════════════════════════════════════════════════════════════════
# MAIN TEST SEQUENCE
# ══════════════════════════════════════════════════════════════════════════════

main() {
    # Set up logging
    local LOG_FILE="$TEST_DIR/interactive-test-results-$(date +%Y%m%d-%H%M%S).log"

    print_banner

    # Check prerequisites
    if [[ ! -d "$DEMO_COURSE" ]]; then
        echo -e "${RED}${CROSS} Demo course not found!${NC}"
        echo -e "${DIM}Expected at: $DEMO_COURSE${NC}"
        exit 1
    fi

    # Source plugin
    if ! source "$PLUGIN_DIR/flow.plugin.zsh" 2>/dev/null; then
        echo -e "${RED}${CROSS} Failed to load plugin${NC}"
        exit 1
    fi

    # Navigate to demo course
    cd "$DEMO_COURSE" || exit 1

    echo -e "${GREEN}${CHECK} Plugin loaded successfully${NC}"
    echo -e "${GREEN}${CHECK} Demo course ready${NC}"
    echo -e "${CYAN}${EYES} Logging results to: $LOG_FILE${NC}"

    # Initialize log file
    cat > "$LOG_FILE" <<EOF
═══════════════════════════════════════════════════════════════
INTERACTIVE DOG FEEDING TEST - RESULTS LOG
═══════════════════════════════════════════════════════════════
Started: $(date '+%Y-%m-%d %H:%M:%S')
Demo Course: STAT-101 (Introduction to Statistics)
═══════════════════════════════════════════════════════════════

EOF

    cleanup_demo_course

    press_any_key
    print_dog_status

    # ═══════════════════════════════════════════════════════════════════════
    # TEST 1: Analyze Single File (Week 1)
    # ═══════════════════════════════════════════════════════════════════════

    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${MAGENTA} Task 1: Analyze Week 1 Lecture${NC}"
    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}${TEACHER} Let's analyze the first week's lecture!${NC}"
    echo ""
    show_expected \
        "📊 CONCEPT COVERAGE table with ${BOLD}12 total concepts${NC}" \
        "Week 1 concepts: Descriptive-Stats, Data-Types, Distributions" \
        "All concepts show '✓ Introduced (Week X)' status" \
        "Prerequisites table (may be empty for Week 1)"

    echo -e "${BOLD}Command:${NC} teach analyze lectures/week-01.qmd"
    echo ""
    teach analyze lectures/week-01.qmd

    if ask_confirmation "Did you see 12 concepts in the CONCEPT COVERAGE table?"; then
        feed_dog 15
    else
        disappoint_dog
    fi

    press_any_key
    print_dog_status

    # ═══════════════════════════════════════════════════════════════════════
    # TEST 2: Analyze Week 2 (Prerequisites)
    # ═══════════════════════════════════════════════════════════════════════

    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${MAGENTA} Task 2: Analyze Week 2 (With Prerequisites)${NC}"
    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}${BRAIN} Week 2 builds on Week 1 concepts!${NC}"
    echo ""
    show_expected \
        "📊 CONCEPT COVERAGE shows ${BOLD}all 12 course concepts${NC}" \
        "Week 2 concepts: Probability-Basics, Sampling, Inference" \
        "🔗 PREREQUISITES table shows required concepts" \
        "Summary shows '✓ All prerequisites satisfied'"

    echo -e "${BOLD}Command:${NC} teach analyze lectures/week-02.qmd"
    echo ""
    teach analyze lectures/week-02.qmd

    if ask_confirmation "Did you see concepts AND prerequisites tables populated?"; then
        feed_dog 15
    else
        disappoint_dog
    fi

    press_any_key
    print_dog_status

    # ═══════════════════════════════════════════════════════════════════════
    # TEST 3: Batch Analysis (Future Feature - Skipped)
    # ═══════════════════════════════════════════════════════════════════════

    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${MAGENTA} Task 3: Analyze Week 3 (Advanced Concepts)${NC}"
    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}${GRAPH} Week 3 has more complex prerequisite chains!${NC}"
    echo ""
    show_expected \
        "📊 CONCEPT COVERAGE shows ${BOLD}all 12 concepts${NC}" \
        "Week 3 concepts: Linear-Regression, Correlation" \
        "Prerequisites include Week 1 & 2 concepts" \
        "All concepts properly linked"

    echo -e "${BOLD}Command:${NC} teach analyze lectures/week-03.qmd"
    echo ""
    echo -e "${YELLOW}Note: --batch flag not yet implemented, using single file analysis${NC}"
    echo ""
    teach analyze lectures/week-03.qmd

    if ask_confirmation "Did you see Week 3 concepts with their prerequisites?"; then
        feed_dog 20
    else
        disappoint_dog
    fi

    press_any_key
    print_dog_status

    # ═══════════════════════════════════════════════════════════════════════
    # TEST 4: Concept Graph Persistence
    # ═══════════════════════════════════════════════════════════════════════

    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${MAGENTA} Task 4: Check Concept Graph Persistence${NC}"
    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}⚡ Concept graph saved to .teach/concepts.json!${NC}"
    echo ""
    show_expected \
        "${BOLD}.teach/concepts.json${NC} file exists" \
        "Contains all 12 concepts" \
        "Graph includes prerequisite mappings"

    echo -e "${BOLD}Command:${NC} cat .teach/concepts.json | jq '.metadata'"
    echo ""
    if [[ -f .teach/concepts.json ]]; then
        cat .teach/concepts.json | jq '.metadata'
        echo ""
        if ask_confirmation "Does the metadata show 12 total_concepts?"; then
            feed_dog 10
        else
            disappoint_dog
        fi
    else
        echo -e "${RED}✗ .teach/concepts.json not found${NC}"
        disappoint_dog
    fi

    press_any_key
    print_dog_status

    # ═══════════════════════════════════════════════════════════════════════
    # TEST 5: Prerequisite Validation (Valid)
    # ═══════════════════════════════════════════════════════════════════════

    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${MAGENTA} Task 5: Validate Prerequisites (Valid Files)${NC}"
    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}${CHECK} Let's validate the proper lecture files!${NC}"
    echo ""
    show_expected \
        "Running validation for multiple files" \
        "Each file shows: ${GREEN}✓ YAML valid, ✓ Syntax valid${NC}" \
        "All files pass validation" \
        "No circular dependencies detected"

    echo -e "${BOLD}Command:${NC} teach validate lectures/week-01.qmd lectures/week-02.qmd lectures/week-03.qmd"
    echo ""
    teach validate lectures/week-01.qmd lectures/week-02.qmd lectures/week-03.qmd

    if ask_confirmation "Did validation pass without errors?"; then
        feed_dog 15
    else
        disappoint_dog
    fi

    press_any_key
    print_dog_status

    # ═══════════════════════════════════════════════════════════════════════
    # TEST 6: Detect Circular Dependency
    # ═══════════════════════════════════════════════════════════════════════

    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${MAGENTA} Task 6: Detect Circular Dependency (Broken File)${NC}"
    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}⚠️  Test the broken file with circular dependency!${NC}"
    echo ""
    show_expected \
        "${RED}ERROR${NC} or ${RED}FAILED${NC} validation" \
        "Mentions: ${BOLD}circular dependency${NC}" \
        "Shows: linear-regression ↔ correlation cycle"

    echo -e "${BOLD}Command:${NC} teach validate lectures/week-03-broken.qmd"
    echo ""
    teach validate lectures/week-03-broken.qmd

    if ask_confirmation "Did it detect the circular dependency?"; then
        feed_dog 20
    else
        disappoint_dog
    fi

    press_any_key
    print_dog_status

    # ═══════════════════════════════════════════════════════════════════════
    # TEST 7: Slide Break Analysis (Week 1)
    # ═══════════════════════════════════════════════════════════════════════

    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${MAGENTA} Task 7: Slide Break Optimization (Week 1)${NC}"
    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}📊 Optimize slides for better teaching flow!${NC}"
    echo ""
    show_expected \
        "Slide break suggestions" \
        "Timing estimates (minutes)" \
        "Key concepts to emphasize"

    echo -e "${BOLD}Command:${NC} teach analyze --slide-breaks lectures/week-01.qmd"
    echo ""
    teach analyze --slide-breaks lectures/week-01.qmd

    if ask_confirmation "Did you see slide break suggestions with timing?"; then
        feed_dog 15
    else
        disappoint_dog
    fi

    press_any_key
    print_dog_status

    # ═══════════════════════════════════════════════════════════════════════
    # TEST 8: Prerequisite Chains
    # ═══════════════════════════════════════════════════════════════════════

    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${MAGENTA} Task 8: Verify Prerequisite Chains${NC}"
    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}${BRAIN} Check concepts file for full dependency graph!${NC}"
    echo ""
    show_expected \
        "View ${BOLD}.teach/concepts.json${NC} structure" \
        "Each concept shows prerequisites array" \
        "Complete dependency graph visible"

    echo -e "${BOLD}Command:${NC} cat .teach/concepts.json | jq '.concepts | to_entries[:3]'"
    echo ""
    if [[ -f .teach/concepts.json ]]; then
        cat .teach/concepts.json | jq '.concepts | to_entries[:3]'
        echo ""
        if ask_confirmation "Can you see concept IDs with their prerequisites?"; then
            feed_dog 10
        else
            disappoint_dog
        fi
    else
        echo -e "${RED}✗ .teach/concepts.json not found${NC}"
        disappoint_dog
    fi

    press_any_key
    print_dog_status

    # ═══════════════════════════════════════════════════════════════════════
    # TEST 9: Summary Status
    # ═══════════════════════════════════════════════════════════════════════

    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${MAGENTA} Task 9: Check Summary Status${NC}"
    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}🧠 Verify the SUMMARY section!${NC}"
    echo ""
    show_expected \
        "${GREEN}Status: ✓ READY TO DEPLOY${NC} (0 errors, 0 warnings)" \
        "${GREEN}✓ All prerequisites satisfied${NC}" \
        "${GREEN}✓ All concepts properly defined${NC}" \
        "Next steps shown"

    echo -e "${BOLD}Command:${NC} teach analyze lectures/week-02.qmd"
    echo ""
    teach analyze lectures/week-02.qmd

    if ask_confirmation "Did you see the green checkmarks in the SUMMARY?"; then
        feed_dog 10
    else
        disappoint_dog
    fi

    press_any_key
    print_dog_status

    # ═══════════════════════════════════════════════════════════════════════
    # TEST 10: Concept Dependency Graph
    # ═══════════════════════════════════════════════════════════════════════

    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${MAGENTA} Task 10: Visualize Dependency Graph${NC}"
    echo -e "${BOLD}${MAGENTA}═══════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}${GRAPH} See how concepts connect!${NC}"
    echo ""
    show_expected \
        "Week 3 regression requires: ${BOLD}correlation, inference${NC}" \
        "Inference requires: probability, sampling, distributions" \
        "Full dependency chain visible"

    echo -e "${BOLD}Command:${NC} teach analyze lectures/week-03.qmd"
    echo ""
    teach analyze lectures/week-03.qmd

    if ask_confirmation "Did you see the full dependency chain for regression?"; then
        feed_dog 20
    else
        disappoint_dog
    fi

    press_any_key

    # ═══════════════════════════════════════════════════════════════════════
    # FINAL RESULTS
    # ═══════════════════════════════════════════════════════════════════════

    print_dog_status

    echo -e "${BOLD}${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║                    FINAL RESULTS                           ║${NC}"
    echo -e "${BOLD}${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [[ $TASKS_COMPLETED -eq $TOTAL_TASKS ]]; then
        echo -e "${GREEN}${BOLD}${STAR}${STAR}${STAR}${STAR}${STAR} PERFECT SCORE! ${STAR}${STAR}${STAR}${STAR}${STAR}${NC}"
        echo -e "${GREEN}${DOG} The dog is extremely happy and well-fed! ${HAPPY}${NC}"
        echo -e "${GREEN}You are now a teach analyze expert!${NC}"
    elif [[ $TASKS_COMPLETED -ge 8 ]]; then
        echo -e "${GREEN}${BOLD}${STAR}${STAR}${STAR}${STAR} EXCELLENT! ${STAR}${STAR}${STAR}${STAR}${NC}"
        echo -e "${GREEN}${DOG} The dog is very happy! ${HAPPY}${NC}"
        echo -e "${GREEN}Great job with teach analyze!${NC}"
    elif [[ $TASKS_COMPLETED -ge 5 ]]; then
        echo -e "${YELLOW}${BOLD}${STAR}${STAR}${STAR} GOOD! ${STAR}${STAR}${STAR}${NC}"
        echo -e "${YELLOW}${DOG} The dog is satisfied ${THINKING}${NC}"
        echo -e "${YELLOW}You understand the basics - keep practicing!${NC}"
    else
        echo -e "${RED}${BOLD}${STAR}${STAR} NEEDS WORK ${STAR}${STAR}${NC}"
        echo -e "${RED}${DOG} The dog is still hungry ${SAD}${NC}"
        echo -e "${RED}Review the documentation and try again!${NC}"
    fi

    echo ""
    echo -e "${CYAN}Tasks completed: ${BOLD}$TASKS_COMPLETED/$TOTAL_TASKS${NC}"
    echo -e "${CYAN}Final happiness: ${BOLD}$HAPPINESS%${NC}"
    echo ""

    cleanup_demo_course

    echo -e "${DIM}Demo course cache cleaned up${NC}"
    echo ""
    echo -e "${BOLD}Thanks for testing teach analyze! ${DOG}${FOOD}${NC}"
    echo ""
}

# Run main function
main
