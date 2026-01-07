#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# INTERACTIVE DOG FEEDING TEST - PHASE 2
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: ADHD-friendly interactive test for flow-cli v4.9.0 Phase 2 features
#          Tests interactive help, context-aware help, and alias reference
#
# Usage: ./interactive-dog-feeding-phase2.zsh
#
# What it tests:
#   - Interactive help browser (flow help -i)
#   - Context-aware help detection
#   - Alias reference command (flow alias)
#   - Help cross-references ("See also" sections)
#   - Random tips in dashboard
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
BOOK='📚'
LIGHTBULB='💡'

# Game state
HUNGER=100
HAPPINESS=50
TASKS_COMPLETED=0
TOTAL_TASKS=5

# ══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

print_banner() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${DOG}  ${BOLD}PHASE 2 DOG FEEDING TEST${NC}  ${BOOK}                      ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}  ${CYAN}Interactive Help & Discoverability Features${NC}              ${BLUE}║${NC}"
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
    shift 2  # Remove first two parameters

    # Last parameter is reward, second to last is success message
    local reward="${@[-1]}"
    local success_msg="${@[-2]}"

    # Everything else (except last 2) are expected patterns
    local num_patterns=$(($# - 2))
    local -a expected_patterns=("${@:1:$num_patterns}")

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

echo -e "${CYAN}Welcome to the Phase 2 Dog Feeding Test!${NC}"
echo ""
echo -e "Your mission: ${BOLD}Feed the dog by confirming Phase 2 features work${NC}"
echo ""
echo -e "Phase 2 Features:"
echo -e "  ${BOOK} ${DIM}Interactive help browser${NC}"
echo -e "  ${BOOK} ${DIM}Context-aware help${NC}"
echo -e "  ${BOOK} ${DIM}Comprehensive alias reference${NC}"
echo -e "  ${LIGHTBULB} ${DIM}Help cross-references${NC}"
echo -e "  ${LIGHTBULB} ${DIM}Random tips${NC}"
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
# TASK 1: Test alias reference command
# ══════════════════════════════════════════════════════════════════════════════

print_dog_status

echo -e "${DOG} ${CYAN}\"Show me all those handy shortcuts!\"${NC}"
press_any_key

run_interactive_test \
    "Alias Reference Command" \
    "flow alias" \
    "╭─────────────────────── (border at top)" \
    "│ 📋 FLOW-CLI COMMAND ALIASES (header)" \
    "╰─────────────────────── (border below header)" \
    "🚀 Core Workflow (category header)" \
    "  ccy → cc yolo (alias → expansion)" \
    "  Multiple aliases listed with descriptions" \
    "📊 Dashboard & Status (another category)" \
    "🔧 Dispatchers (category with g, r, qu, etc.)" \
    "💡 ADHD Helpers (category)" \
    "⚡ Quick Actions (category)" \
    "🎯 Productivity (category)" \
    "Total of 6 categories with aliases" \
    "${GREEN}Alias reference working! The dog knows all the shortcuts ${BOOK}${NC}" \
    20

# ══════════════════════════════════════════════════════════════════════════════
# TASK 2: Test context-aware help in R package
# ══════════════════════════════════════════════════════════════════════════════

print_dog_status

echo -e "${DOG} ${CYAN}\"Let's see context-aware help in action!\"${NC}"
echo ""
echo -e "${DIM}Note: We'll run 'flow help' from an R package directory${NC}"
echo -e "${DIM}to test context detection. If no R package nearby, we'll${NC}"
echo -e "${DIM}test in the current directory (should show general help).${NC}"
press_any_key

# Try to find an R package in the system
R_PKG_DIR=""
if [[ -d ~/projects/r-packages/active ]]; then
    # Look for first R package
    for dir in ~/projects/r-packages/active/*(N); do
        if [[ -f "$dir/DESCRIPTION" ]]; then
            R_PKG_DIR="$dir"
            break
        fi
    done
fi

if [[ -n "$R_PKG_DIR" ]]; then
    echo -e "${CYAN}Found R package: ${BOLD}$(basename "$R_PKG_DIR")${NC}"
    echo -e "${DIM}Testing context-aware help there...${NC}"
    echo ""

    run_interactive_test \
        "Context-Aware Help (R Package)" \
        "cd '$R_PKG_DIR' && flow help && cd -" \
        "📋 flow-cli Quick Help (header)" \
        "🔬 R PACKAGE CONTEXT DETECTED (context banner)" \
        "R Package Commands: (section header)" \
        "  r test - Run package tests" \
        "  r check - R CMD check" \
        "  r doc - Build documentation" \
        "  r install - Install package locally" \
        "Additional context-specific commands shown" \
        "${GREEN}Context detection working! The dog loves smart help ${BOOK}${THINKING}${NC}" \
        20
else
    echo -e "${YELLOW}No R package found, testing general help instead${NC}"
    echo ""

    run_interactive_test \
        "Context-Aware Help (General)" \
        "flow help" \
        "📋 flow-cli Quick Help (header)" \
        "Core Commands: (section)" \
        "  work <project> - Start working" \
        "  dash - Project dashboard" \
        "  catch <text> - Quick capture" \
        "Dispatchers: (section)" \
        "  g <cmd> - Git workflows" \
        "  r <cmd> - R packages" \
        "Additional commands listed" \
        "${GREEN}General help working! The dog appreciates the guidance ${BOOK}${NC}" \
        20
fi

# ══════════════════════════════════════════════════════════════════════════════
# TASK 3: Test dispatcher help cross-references
# ══════════════════════════════════════════════════════════════════════════════

print_dog_status

echo -e "${DOG} ${CYAN}\"Show me those helpful 'See also' links!\"${NC}"
press_any_key

run_interactive_test \
    "Help Cross-References" \
    "r help" \
    "╭─────────────────────── (border)" \
    "│ 📦 R PACKAGE DISPATCHER (header)" \
    "╰─────────────────────── (border)" \
    "Commands listed (r test, r check, etc.)" \
    "EXAMPLES: (section near bottom)" \
    "  $ r test (example command)" \
    "  $ r doc (another example)" \
    "SEE ALSO: (section at bottom)" \
    "  • flow help - Main help" \
    "  • Other related commands" \
    "${GREEN}Cross-references found! The dog can discover more ${LIGHTBULB}${NC}" \
    15

# ══════════════════════════════════════════════════════════════════════════════
# TASK 4: Test interactive help browser (requires fzf)
# ══════════════════════════════════════════════════════════════════════════════

print_dog_status

echo -e "${DOG} ${CYAN}\"Let's try that fancy interactive help picker!\"${NC}"
echo ""

# Check if fzf is available
if ! command -v fzf >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  fzf not installed, skipping interactive help test${NC}"
    echo -e "${DIM}Install with: brew install fzf${NC}"
    echo ""
    echo -e "${CYAN}The dog understands - not all tools are available ${THINKING}${NC}"
    press_any_key
else
    echo -e "${CYAN}This test requires user interaction:${NC}"
    echo -e "  ${DIM}1. The fzf picker will open${NC}"
    echo -e "  ${DIM}2. You'll see a list of commands${NC}"
    echo -e "  ${DIM}3. Press ESC or Ctrl-C to close it${NC}"
    echo -e "  ${DIM}4. Then confirm the interface appeared${NC}"
    echo ""
    press_any_key

    echo -e "${BOLD}${BLUE}Running: flow help -i${NC}"
    echo -e "${DIM}(Press ESC or Ctrl-C to exit the picker)${NC}"
    echo ""

    # Run the interactive help (user will exit it)
    flow help -i 2>&1 || true

    echo ""
    echo -e "${MAGENTA}╭─ Expected Behavior ──────────────────────────────────────╮${NC}"
    echo -e "${MAGENTA}│${NC} ${BOLD}What you should have seen:${NC}"
    echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────╯${NC}"
    echo -e "${DIM}  • fzf interface opened with command list${NC}"
    echo -e "${DIM}  • Commands categorized or searchable${NC}"
    echo -e "${DIM}  • Preview pane showing help text (NOT 'command not found')${NC}"
    echo -e "${DIM}  • Full help for selected command (e.g., 'DASH - Project Dashboard')${NC}"
    echo -e "${DIM}  • Arrow keys navigate, Enter selects, ESC exits${NC}"
    echo ""

    if ask_confirmation "Did the interactive help browser work as expected?"; then
        echo -e "${GREEN}${CHECK} Great! Interactive help confirmed!${NC}"
        echo ""
        echo -e "${GREEN}The dog loves the fancy picker! ${BOOK}${STAR}${NC}"
        feed_dog 20
    else
        echo -e "${RED}${CROSS} Interactive help had issues${NC}"
        disappoint_dog

        if ! ask_confirmation "Continue to next test anyway?" "y"; then
            echo ""
            echo -e "${RED}Test suite stopped by user${NC}"
            exit 1
        fi
    fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# TASK 5: Test random tips in dashboard
# ══════════════════════════════════════════════════════════════════════════════

print_dog_status

echo -e "${DOG} ${CYAN}\"Let's check if the dashboard shows random tips!\"${NC}"
echo ""
echo -e "${DIM}Note: Tips appear randomly (~20% chance)${NC}"
echo -e "${DIM}We'll run 'dash' a few times to increase chances.${NC}"
echo ""
press_any_key

echo -e "${CYAN}Running dashboard 3 times to look for tips...${NC}"
echo ""

local tip_found=false
for i in {1..3}; do
    echo -e "${BOLD}Attempt $i:${NC}"
    local output=$(dash 2>&1)

    # Check if output contains tip marker
    if echo "$output" | grep -q "💡 TIP:"; then
        tip_found=true
        echo -e "${GREEN}✓ Tip found in output!${NC}"
        echo ""
        # Show the tip
        echo "$output" | grep -A2 "💡 TIP:"
        echo ""
        break
    else
        echo -e "${YELLOW}No tip in this run${NC}"
    fi

    [[ $i -lt 3 ]] && echo ""
done

echo ""
echo -e "${MAGENTA}╭─ Expected Behavior ──────────────────────────────────────╮${NC}"
echo -e "${MAGENTA}│${NC} ${BOLD}Random tips should occasionally appear:${NC}"
echo -e "${MAGENTA}╰──────────────────────────────────────────────────────────╯${NC}"
echo -e "${DIM}  • 💡 TIP: (tip marker at bottom of dashboard)${NC}"
echo -e "${DIM}  • Helpful suggestion or command reminder${NC}"
echo -e "${DIM}  • Appears ~20% of the time (random)${NC}"
echo ""

if [[ "$tip_found" == true ]]; then
    if ask_confirmation "Did you see a tip with '💡 TIP:' marker?"; then
        echo -e "${GREEN}${CHECK} Tips confirmed!${NC}"
        echo ""
        echo -e "${GREEN}The dog loves helpful hints! ${LIGHTBULB}${HAPPY}${NC}"
        feed_dog 15
    else
        echo -e "${YELLOW}Tip appeared but user didn't confirm${NC}"
        disappoint_dog
    fi
else
    echo -e "${YELLOW}No tip appeared in 3 attempts (random chance)${NC}"
    echo ""
    if ask_confirmation "Tips appear randomly. Accept this test anyway?"; then
        echo -e "${GREEN}${CHECK} Random nature accepted!${NC}"
        echo ""
        echo -e "${GREEN}The dog trusts the randomness ${THINKING}${NC}"
        feed_dog 10
    else
        echo -e "${YELLOW}Keep running 'dash' manually to see a tip eventually${NC}"
        disappoint_dog
    fi
fi

# ══════════════════════════════════════════════════════════════════════════════
# FINAL RESULTS
# ══════════════════════════════════════════════════════════════════════════════

print_dog_status

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  ${BOLD}PHASE 2 TEST RESULTS${NC}                                      ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

local grade stars_earned final_message

if [[ $TASKS_COMPLETED -eq $TOTAL_TASKS ]]; then
    stars_earned="${STAR}${STAR}${STAR}${STAR}${STAR}"
    grade="${GREEN}${BOLD}PERFECT!${NC}"
    final_message="${GREEN}${DOG} The dog is ECSTATIC! All Phase 2 features confirmed! ${HAPPY}${STAR}${BOOK}${NC}"
elif [[ $TASKS_COMPLETED -ge 4 ]]; then
    stars_earned="${STAR}${STAR}${STAR}${STAR}"
    grade="${GREEN}EXCELLENT!${NC}"
    final_message="${GREEN}${DOG} The dog is very happy! Most Phase 2 features work! ${HAPPY}${NC}"
elif [[ $TASKS_COMPLETED -ge 3 ]]; then
    stars_earned="${STAR}${STAR}${STAR}"
    grade="${YELLOW}GOOD${NC}"
    final_message="${YELLOW}${DOG} The dog is satisfied. Some Phase 2 issues to fix! ${THINKING}${NC}"
else
    stars_earned="${STAR}"
    grade="${RED}NEEDS WORK${NC}"
    final_message="${RED}${DOG} The dog is still hungry. Several Phase 2 issues found! ${SAD}${NC}"
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
    echo -e "${CYAN}Your flow-cli Phase 2 features are working perfectly!${NC}"
    echo -e "${CYAN}All interactive help and discoverability features confirmed.${NC}"
    echo ""
    echo -e "${BOOK} Phase 2 Features Validated:"
    echo -e "  ${CHECK} Alias reference (flow alias)"
    echo -e "  ${CHECK} Context-aware help"
    echo -e "  ${CHECK} Help cross-references"
    echo -e "  ${CHECK} Interactive help browser"
    echo -e "  ${CHECK} Random tips"
    echo ""
    exit 0
elif [[ $TASKS_COMPLETED -ge 4 ]]; then
    echo -e "${YELLOW}Most Phase 2 tests confirmed! One feature may need review.${NC}"
    echo -e "${DIM}Check the failed test and verify the feature works manually.${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}Several Phase 2 tests failed confirmation.${NC}"
    echo -e "${YELLOW}This suggests some Phase 2 features may not be working correctly.${NC}"
    echo -e "${DIM}Review the output and fix any issues before release.${NC}"
    echo ""
    exit 1
fi
