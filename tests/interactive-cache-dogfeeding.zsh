#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# PROJECT CACHE INTERACTIVE DOG FEEDING TEST
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: ADHD-friendly interactive test for project cache functionality
#          Tests cache generation, TTL, performance, and commands
#
# Usage: ./interactive-cache-dogfeeding.zsh
#
# What it tests:
#   - Cache file generation
#   - TTL-based validity
#   - Auto-regeneration on stale cache
#   - Cache commands (refresh, clear, status)
#   - Performance improvements
#   - Graceful degradation
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
ROCKET='🚀'
CACHE='💾'
CLOCK='⏱️'
REFRESH='🔄'

# Game state
HUNGER=100
HAPPINESS=50
TASKS_COMPLETED=0
TOTAL_TASKS=15
STREAK=0

# Test setup
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

# ══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

print_banner() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${DOG}${CACHE}  ${BOLD}PROJECT CACHE DOG FEEDING TEST${NC}  ${CACHE}${DOG}           ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${DIM}Feed the dog by passing cache tests!${NC}"
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

    local hunger_bar=$(create_progress_bar $HUNGER 20)
    local happy_bar=$(create_progress_bar $HAPPINESS 20)

    echo ""
    echo -e "${CYAN}╭─ Dog Status ─────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}│${NC} Hunger:    ${YELLOW}$hunger_bar${NC} ${DIM}$HUNGER%${NC}"
    echo -e "${CYAN}│${NC} Happiness: $happy_bar $mood"
    echo -e "${CYAN}│${NC} Tasks:     ${GREEN}$TASKS_COMPLETED${NC}/${TOTAL_TASKS} ${DIM}(Streak: ${STREAK})${NC}"
    echo -e "${CYAN}╰──────────────────────────────────────────────────────────╯${NC}"
    echo ""
}

create_progress_bar() {
    local value=$1
    local max_width=$2
    local filled=$((value * max_width / 100))
    local empty=$((max_width - filled))

    local bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    echo "$bar"
}

feed_dog() {
    local amount=$1
    local difficulty=${2:-"basic"}

    HUNGER=$((HUNGER - amount))
    local happiness_gain=$((amount / 2))

    # Streak bonus
    ((STREAK++))
    if [[ $STREAK -ge 3 ]]; then
        happiness_gain=$((happiness_gain + 5))
        echo -e "${YELLOW}${STAR} Streak bonus! +5 happiness${NC}"
    fi

    HAPPINESS=$((HAPPINESS + happiness_gain))

    # Cap values
    [[ $HUNGER -lt 0 ]] && HUNGER=0
    [[ $HAPPINESS -gt 100 ]] && HAPPINESS=100

    echo -e "${GREEN}${FOOD} Fed the dog! ${HAPPY} +${amount}% food, +${happiness_gain}% happiness${NC}"
    ((TASKS_COMPLETED++))
}

disappoint_dog() {
    HAPPINESS=$((HAPPINESS - 15))
    [[ $HAPPINESS -lt 0 ]] && HAPPINESS=0
    STREAK=0
    echo -e "${RED}${SAD} The dog is disappointed... (streak reset)${NC}"
}

press_any_key() {
    echo ""
    echo -ne "${DIM}Press any key to continue...${NC}"
    read -k1 -s
    echo ""
}

run_test() {
    local description=$1
    local command=$2
    local expected=$3
    local food_value=${4:-10}
    local difficulty=${5:-"basic"}

    echo ""
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${EYES} ${BOLD}${description}${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Show command
    echo -e "${BLUE}📝 Command:${NC}"
    echo -e "   ${DIM}${command}${NC}"
    echo ""

    # Show expected output
    echo -e "${YELLOW}✨ Expected:${NC}"
    echo -e "   ${expected}"
    echo ""

    # Run command and capture output
    echo -e "${MAGENTA}🔍 Actual Output:${NC}"
    echo -e "${DIM}───────────────────────────────────────────────────────────${NC}"
    local output=$(eval "$command" 2>&1)
    local result=$?
    echo "$output"
    echo -e "${DIM}───────────────────────────────────────────────────────────${NC}"
    echo ""

    # Show exit code
    if [[ $result -eq 0 ]]; then
        echo -e "${GREEN}Exit code: 0 (success)${NC}"
    else
        echo -e "${RED}Exit code: $result (failure)${NC}"
    fi
    echo ""

    # Ask user
    echo -ne "${QUESTION} ${BOLD}Did this test pass?${NC} (y/n): "
    read -k1 answer
    echo ""

    if [[ $answer == "y" || $answer == "Y" ]]; then
        echo -e "${GREEN}${CHECK} Test passed!${NC}"
        feed_dog $food_value $difficulty
    else
        echo -e "${RED}${CROSS} Test failed${NC}"
        disappoint_dog
    fi

    print_dog_status
    press_any_key
}

section_header() {
    local title=$1
    local emoji=$2
    echo ""
    echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║${NC}  ${emoji}  ${BOLD}${title}${NC}"
    echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# MAIN TEST SEQUENCE
# ══════════════════════════════════════════════════════════════════════════════

main() {
    print_banner
    print_dog_status

    echo -e "${YELLOW}${DOG} Woof! I'm hungry! Feed me by passing cache tests!${NC}"
    press_any_key

    # Load plugin
    section_header "Setup: Loading flow-cli" "🔧"

    echo "Loading flow-cli plugin..."
    source "$PROJECT_ROOT/flow.plugin.zsh"
    echo -e "${GREEN}${CHECK} Plugin loaded${NC}"

    print_dog_status
    press_any_key

    # ══════════════════════════════════════════════════════════════════════════
    # SECTION 1: BASIC CACHE GENERATION (Food value: 10% each)
    # ══════════════════════════════════════════════════════════════════════════

    section_header "Section 1: Basic Cache Generation" "${CACHE}"

    run_test \
        "Test 1.1: Cache file is created" \
        "flow cache refresh && [[ -f \"\$PROJ_CACHE_FILE\" ]] && echo '✅ Cache file exists at: \$PROJ_CACHE_FILE'" \
        "✅ Cache refreshed message, cache stats displayed, '✅ Cache file exists' message" \
        10 "basic"

    run_test \
        "Test 1.2: Cache has timestamp header" \
        "head -1 \"\$PROJ_CACHE_FILE\" | grep -q '# Generated:' && echo '✅ Timestamp header found'" \
        "✅ Timestamp header found" \
        10 "basic"

    run_test \
        "Test 1.3: Cache contains project data" \
        "tail -n +2 \"\$PROJ_CACHE_FILE\" | wc -l | grep -qv '^0' && echo '✅ Cache has project data'" \
        "✅ Cache has project data" \
        10 "basic"

    # ══════════════════════════════════════════════════════════════════════════
    # SECTION 2: CACHE VALIDITY & TTL (Food value: 15% each)
    # ══════════════════════════════════════════════════════════════════════════

    section_header "Section 2: TTL Validation" "${CLOCK}"

    run_test \
        "Test 2.1: Fresh cache is valid" \
        "_proj_cache_is_valid && echo '✅ Cache is valid (within TTL)' || echo '❌ Cache is invalid'" \
        "✅ Cache is valid (within TTL)" \
        15 "validation"

    run_test \
        "Test 2.2: Cache stats show age" \
        "flow cache status | grep -q 'Age:' && echo '✅ Stats show cache age'" \
        "Cache status display with 'Age:' field, then '✅ Stats show cache age'" \
        15 "validation"

    run_test \
        "Test 2.3: Stale cache detection" \
        "echo 'Creating 10-second-old cache...'; echo '# Generated: \$((\$(date +%s) - 10))' > \"\$PROJ_CACHE_FILE\"; echo 'test|dev|🔧|/path|' >> \"\$PROJ_CACHE_FILE\"; _proj_cache_is_valid && echo '✅ Still valid (< 5 min)' || echo '❌ Invalid'" \
        "Creating 10-second-old cache..., then '✅ Still valid (< 5 min)' (since 10s < 5min TTL)" \
        15 "validation"

    # ══════════════════════════════════════════════════════════════════════════
    # SECTION 3: CACHE COMMANDS (Food value: 15% each)
    # ══════════════════════════════════════════════════════════════════════════

    section_header "Section 3: Cache Commands" "${REFRESH}"

    run_test \
        "Test 3.1: flow cache refresh regenerates" \
        "flow cache refresh && echo '✅ Cache refreshed'" \
        "Cache refresh message, stats displayed, then '✅ Cache refreshed'" \
        15 "commands"

    run_test \
        "Test 3.2: flow cache status displays info" \
        "flow cache status && echo '✅ Stats displayed'" \
        "Cache status: Valid/Invalid, Age, TTL, Projects count, Location, then '✅ Stats displayed'" \
        15 "commands"

    run_test \
        "Test 3.3: flow cache clear deletes file" \
        "flow cache clear && [[ ! -f \"\$PROJ_CACHE_FILE\" ]] && echo '✅ Cache cleared' || echo '❌ Cache still exists'" \
        "'✅ Cache cleared' message, then '✅ Cache cleared' confirmation" \
        15 "commands"

    # ══════════════════════════════════════════════════════════════════════════
    # SECTION 4: AUTO-REGENERATION (Food value: 20% each)
    # ══════════════════════════════════════════════════════════════════════════

    section_header "Section 4: Auto-Regeneration" "${ROCKET}"

    run_test \
        "Test 4.1: Missing cache auto-generates" \
        "rm -f \"\$PROJ_CACHE_FILE\" && _proj_list_all_cached >/dev/null && [[ -f \"\$PROJ_CACHE_FILE\" ]] && echo '✅ Cache auto-generated on missing'" \
        "No output (redirected to /dev/null), then '✅ Cache auto-generated on missing'" \
        20 "advanced"

    run_test \
        "Test 4.2: Stale cache auto-regenerates" \
        "echo '# Generated: \$((\$(date +%s) - 400))' > \"\$PROJ_CACHE_FILE\"; _proj_list_all_cached >/dev/null && _proj_cache_is_valid && echo '✅ Stale cache was regenerated'" \
        "No output (redirected to /dev/null), then '✅ Stale cache was regenerated'" \
        20 "advanced"

    run_test \
        "Test 4.3: Corrupt cache auto-regenerates" \
        "echo 'invalid data' > \"\$PROJ_CACHE_FILE\" && _proj_list_all_cached >/dev/null && _proj_cache_is_valid && echo '✅ Corrupt cache was regenerated'" \
        "No output (redirected to /dev/null), then '✅ Corrupt cache was regenerated'" \
        20 "advanced"

    # ══════════════════════════════════════════════════════════════════════════
    # SECTION 5: PERFORMANCE & INTEGRATION (Food value: 25% each)
    # ══════════════════════════════════════════════════════════════════════════

    section_header "Section 5: Performance & Integration" "${ROCKET}"

    run_test \
        "Test 5.1: Cached access is fast" \
        "flow cache refresh >/dev/null && time (_proj_list_all_cached >/dev/null) && echo '✅ Check if time is < 10ms'" \
        "Timing output showing execution time (should be < 0.010s), then '✅ Check if time is < 10ms'" \
        25 "integration"

    run_test \
        "Test 5.2: Cache disabled fallback works" \
        "FLOW_CACHE_ENABLED=0 _proj_list_all_cached >/dev/null && echo '✅ Fallback to uncached works'" \
        "No output (redirected to /dev/null), then '✅ Fallback to uncached works'" \
        25 "integration"

    # ══════════════════════════════════════════════════════════════════════════
    # FINAL RESULTS
    # ══════════════════════════════════════════════════════════════════════════

    section_header "Final Results" "${STAR}"

    print_dog_status

    if [[ $HUNGER -eq 0 && $HAPPINESS -gt 70 ]]; then
        echo -e "${GREEN}${BOLD}"
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║                                                            ║"
        echo "║  🎉  CONGRATULATIONS! THE DOG IS FULL AND HAPPY!  🎉      ║"
        echo "║                                                            ║"
        echo "║  You passed all cache tests!                              ║"
        echo "║  The project cache is working perfectly! ${ROCKET}              ║"
        echo "║                                                            ║"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
    elif [[ $TASKS_COMPLETED -ge 12 ]]; then
        echo -e "${YELLOW}${BOLD}"
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║                                                            ║"
        echo "║  ${HAPPY}  GREAT JOB! THE DOG IS MOSTLY SATISFIED!  ${HAPPY}       ║"
        echo "║                                                            ║"
        echo "║  Most cache tests passed!                                 ║"
        echo "║  Just a few issues to investigate.                        ║"
        echo "║                                                            ║"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
    else
        echo -e "${RED}${BOLD}"
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║                                                            ║"
        echo "║  ${SAD}  THE DOG IS STILL HUNGRY...  ${SAD}                      ║"
        echo "║                                                            ║"
        echo "║  Several cache tests failed.                              ║"
        echo "║  Time to debug! Check the unit tests for details.        ║"
        echo "║                                                            ║"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
    fi

    echo ""
    echo -e "${CYAN}Cache Test Summary:${NC}"
    echo -e "  Tasks completed: ${GREEN}$TASKS_COMPLETED${NC}/${TOTAL_TASKS}"
    echo -e "  Final streak:    ${YELLOW}$STREAK${NC}"
    echo -e "  Dog hunger:      ${YELLOW}$HUNGER%${NC}"
    echo -e "  Dog happiness:   ${GREEN}$HAPPINESS%${NC}"
    echo ""

    if [[ $TASKS_COMPLETED -lt $TOTAL_TASKS ]]; then
        echo -e "${DIM}Run the unit tests for detailed diagnostics:${NC}"
        echo -e "${DIM}  ./tests/run-unit-tests.zsh${NC}"
        echo ""
    fi
}

# Run the test suite
main
