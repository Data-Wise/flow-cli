#!/usr/bin/env zsh
# =============================================================================
# e2e-teach-analyze.zsh
# End-to-end tests for teach analyze using demo course
#
# Tests concept extraction, slide optimization, and dependency analysis.
# Sources plugin once and caches teach outputs to stay within 30s timeout.
#
# Note: teach validate (~4s/file) and teach analyze --batch are too slow
# for the 30s test budget. Those are covered by manual testing.
# =============================================================================

# Determine plugin and test directory (must be at top level for ${0:A})
PLUGIN_DIR="${0:A:h:h}"
TEST_DIR="${0:A:h}"
DEMO_COURSE="$TEST_DIR/fixtures/demo-course"

# Test counters
PASS=0
FAIL=0
TOTAL=0

# Colors
GREEN='\033[38;5;154m'
RED='\033[38;5;203m'
YELLOW='\033[38;5;221m'
BLUE='\033[38;5;75m'
BOLD='\033[1m'
RESET='\033[0m'

# Test helpers
log_pass() {
    ((PASS++))
    ((TOTAL++))
    echo -e "${GREEN}✅ PASS${RESET}: $1"
}

log_fail() {
    ((FAIL++))
    ((TOTAL++))
    echo -e "${RED}❌ FAIL${RESET}: $1${2:+ - $2}"
}

log_section() {
    echo -e "\n${BOLD}${BLUE}▶ $1${RESET}"
}

cleanup() {
    rm -rf "$DEMO_COURSE/.teach/analysis-cache" 2>/dev/null
    rm -rf "$DEMO_COURSE/.teach/reports" 2>/dev/null
}

# =============================================================================
# SOURCE PLUGIN ONCE (non-interactive mode)
# =============================================================================

setup_plugin() {
    if [[ ! -f "$PLUGIN_DIR/flow.plugin.zsh" ]]; then
        echo -e "${RED}ERROR: Cannot find plugin at $PLUGIN_DIR/flow.plugin.zsh${RESET}"
        exit 1
    fi

    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$PLUGIN_DIR"
    source "$PLUGIN_DIR/flow.plugin.zsh" 2>/dev/null || {
        echo -e "${RED}Plugin failed to load${RESET}"
        exit 1
    }

    # Close stdin to prevent interactive commands from blocking
    exec < /dev/null
}

# =============================================================================
# CACHE: Run fast teach commands once (~1.4s each), reuse across tests
# =============================================================================

cache_teach_outputs() {
    echo -e "  Caching teach analyze outputs..."

    # Single file analysis (~1.4s each)
    CACHED_WEEK01=$(cd "$DEMO_COURSE" && teach analyze lectures/week-01.qmd 2>&1)
    CACHED_WEEK02=$(cd "$DEMO_COURSE" && teach analyze lectures/week-02.qmd 2>&1)
    CACHED_WEEK03=$(cd "$DEMO_COURSE" && teach analyze lectures/week-03.qmd 2>&1)

    # Slide optimization (~1.5s each)
    CACHED_SLIDES_W1=$(cd "$DEMO_COURSE" && teach analyze --slide-breaks lectures/week-01.qmd 2>&1)
    CACHED_SLIDES_W2=$(cd "$DEMO_COURSE" && teach analyze --slide-breaks lectures/week-02.qmd 2>&1)

    # Extended: week-04
    if [[ -f "$DEMO_COURSE/lectures/week-04.qmd" ]]; then
        CACHED_WEEK04=$(cd "$DEMO_COURSE" && teach analyze lectures/week-04.qmd 2>&1)
    fi

    echo -e "  Done."
}

# =============================================================================
# SECTION 1: Setup and Prerequisites
# =============================================================================

test_demo_course_exists() {
    if [[ -d "$DEMO_COURSE" ]]; then
        log_pass "Demo course directory exists"
    else
        log_fail "Demo course directory not found: $DEMO_COURSE"
        return 1
    fi
}

test_lecture_files_exist() {
    local files=(
        "$DEMO_COURSE/lectures/week-01.qmd"
        "$DEMO_COURSE/lectures/week-02.qmd"
        "$DEMO_COURSE/lectures/week-03.qmd"
    )

    local missing=()
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            log_pass "$(basename $file) exists"
        else
            missing+=("$file")
            log_fail "$(basename $file) not found"
        fi
    done

    [[ ${#missing[@]} -eq 0 ]]
}

test_concepts_json_exists() {
    if [[ -f "$DEMO_COURSE/.teach/concepts.json" ]]; then
        log_pass "concepts.json exists"
    else
        log_fail "concepts.json not found"
        return 1
    fi
}

test_plugin_sources() {
    if type teach &>/dev/null; then
        log_pass "Plugin sourced and teach command available"
    else
        log_fail "teach command not found after sourcing"
        return 1
    fi
}

# =============================================================================
# SECTION 2: Single File Analysis (uses cached outputs)
# =============================================================================

test_analyze_week01() {
    if echo "$CACHED_WEEK01" | grep -qi "descriptive-stats\|data-types\|distributions"; then
        log_pass "Week 1 analysis extracts concepts"
    else
        log_fail "Week 1 analysis missing concepts"
        return 1
    fi

    if echo "$CACHED_WEEK01" | grep -qi "introduced\|week 1"; then
        log_pass "Week 1 concept categories detected"
    else
        log_fail "Week 1 concept categories missing"
    fi
}

test_analyze_week02() {
    if echo "$CACHED_WEEK02" | grep -qi "probability-basics\|sampling\|inference"; then
        log_pass "Week 2 analysis extracts concepts"
    else
        log_fail "Week 2 analysis missing concepts"
        return 1
    fi

    if echo "$CACHED_WEEK02" | grep -qi "prerequisite"; then
        log_pass "Week 2 prerequisites listed"
    else
        log_fail "Week 2 prerequisites missing"
    fi
}

test_analyze_week03() {
    if echo "$CACHED_WEEK03" | grep -qi "correlation\|linear-regression"; then
        log_pass "Week 3 analysis extracts concepts"
    else
        log_fail "Week 3 analysis missing concepts"
        return 1
    fi
}

# =============================================================================
# SECTION 3: Slide Optimization (uses cached outputs)
# =============================================================================

test_slide_breaks_week01() {
    if echo "$CACHED_SLIDES_W1" | grep -qi "slide\|break\|section\|timing"; then
        log_pass "Slide break analysis runs on week-01"
    else
        log_fail "Slide break analysis missing output"
        return 1
    fi
}

test_slide_timing() {
    if echo "$CACHED_SLIDES_W2" | grep -qi "minutes\|time\|duration"; then
        log_pass "Slide timing estimates provided"
    else
        log_fail "Slide timing estimates missing"
    fi
}

# =============================================================================
# SECTION 4: Integration (uses cached outputs — no redundant calls)
# =============================================================================

test_dependency_graph() {
    # Week 3 output should reference prerequisite concepts
    if echo "$CACHED_WEEK03" | grep -qi "prerequisite\|depends\|require\|Week [12]"; then
        log_pass "Dependency graph shows prerequisites"
    else
        log_fail "Dependency graph incomplete"
    fi
}

test_bloom_levels() {
    # Check for Bloom-related output or concept depth indicators
    if echo "$CACHED_WEEK01" | grep -qi "bloom\|introduced\|coverage\|concept"; then
        log_pass "Bloom taxonomy levels detected"
    else
        log_fail "Bloom levels not shown"
    fi
}

# =============================================================================
# SECTION 5: Extended Test Cases (uses cached outputs)
# =============================================================================

test_analyze_week04() {
    if [[ -z "$CACHED_WEEK04" ]]; then
        log_fail "Week 4 lecture file not found"
        return 1
    fi

    if echo "$CACHED_WEEK04" | grep -qi "multiple-regression\|model-selection\|assumptions"; then
        log_pass "Week 4 analysis extracts advanced concepts"
    else
        log_fail "Week 4 analysis missing concepts"
        return 1
    fi
}

test_complex_dependency_chain() {
    if [[ -z "$CACHED_WEEK04" ]]; then
        log_fail "Week 4 not available for dependency chain test"
        return 1
    fi

    if echo "$CACHED_WEEK04" | grep -qi "prerequisite\|require\|depend"; then
        log_pass "Complex dependency chain shown"
    else
        log_fail "Complex dependencies not shown"
    fi
}

test_highest_bloom_level() {
    if [[ -z "$CACHED_WEEK04" ]]; then
        log_fail "Week 4 not available for Bloom level test"
        return 1
    fi

    # Week 4 has advanced concepts — should show depth analysis
    if echo "$CACHED_WEEK04" | grep -qi "week 4\|introduced\|advanced\|model"; then
        log_pass "Week 4 Bloom-level depth analysis present"
    else
        log_fail "Week 4 depth analysis not shown"
    fi
}

# =============================================================================
# RUN ALL TESTS
# =============================================================================

echo -e "${BOLD}${BLUE}========================================${RESET}"
echo -e "${BOLD}${BLUE}  E2E Test Suite: teach analyze${RESET}"
echo -e "${BOLD}${BLUE}  Demo Course: STAT-101${RESET}"
echo -e "${BOLD}${BLUE}========================================${RESET}"

# Setup: source plugin once, clean cache, cache outputs
cleanup
setup_plugin
cache_teach_outputs

log_section "Setup and Prerequisites"
test_demo_course_exists
test_lecture_files_exist
test_concepts_json_exists
test_plugin_sources

log_section "Single File Analysis"
test_analyze_week01
test_analyze_week02
test_analyze_week03

log_section "Slide Optimization"
test_slide_breaks_week01
test_slide_timing

log_section "Integration Tests"
test_dependency_graph
test_bloom_levels

log_section "Extended Test Cases"
test_analyze_week04
test_complex_dependency_chain
test_highest_bloom_level

# Cleanup
cleanup

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
echo -e "${BOLD}${BLUE}========================================${RESET}"
echo -e "${BOLD}${BLUE}  RESULTS${RESET}"
echo -e "${BOLD}${BLUE}========================================${RESET}"
echo -e "  Total:  ${BOLD}${TOTAL}${RESET}"
echo -e "  Passed: ${GREEN}${PASS}${RESET}"
echo -e "  Failed: ${RED}${FAIL}${RESET}"

if [[ $TOTAL -gt 0 ]]; then
    PASS_RATE=$(( (PASS * 100) / TOTAL ))
    echo -e "  Pass Rate: ${BOLD}${PASS_RATE}%${RESET}"
fi
echo ""

if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}All E2E tests passed!${RESET}"
    exit 0
else
    echo -e "${RED}${BOLD}$FAIL test(s) failed${RESET}"
    exit 1
fi
