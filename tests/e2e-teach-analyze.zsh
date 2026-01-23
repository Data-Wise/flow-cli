#!/usr/bin/env zsh
# =============================================================================
# e2e-teach-analyze.zsh
# End-to-end tests for teach analyze using demo course
#
# Tests full workflow:
# - Concept extraction from real .qmd files
# - Prerequisite validation
# - Batch analysis
# - Slide optimization
# - Report generation
# =============================================================================

# Determine plugin and test directory
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
    # Clean up any cache files
    rm -rf "$DEMO_COURSE/.teach/analysis-cache" 2>/dev/null
    rm -rf "$DEMO_COURSE/.teach/reports" 2>/dev/null
}

# =============================================================================
# SECTION 1: Setup and Prerequisites
# =============================================================================

log_section "Setup and Prerequisites"

# Test 1.1: Demo course exists
test_demo_course_exists() {
    if [[ -d "$DEMO_COURSE" ]]; then
        log_pass "Demo course directory exists"
    else
        log_fail "Demo course directory not found: $DEMO_COURSE"
        return 1
    fi
}

# Test 1.2: Lecture files exist
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

# Test 1.3: Concepts.json exists
test_concepts_json_exists() {
    if [[ -f "$DEMO_COURSE/.teach/concepts.json" ]]; then
        log_pass "concepts.json exists"
    else
        log_fail "concepts.json not found"
        return 1
    fi
}

# Test 1.4: Plugin can be sourced
test_plugin_sources() {
    if zsh -c "source '$PLUGIN_DIR/flow.plugin.zsh'" 2>/dev/null; then
        log_pass "Plugin sources successfully"
    else
        log_fail "Plugin failed to source"
        return 1
    fi
}

# =============================================================================
# SECTION 2: Single File Analysis
# =============================================================================

log_section "Single File Analysis"

# Test 2.1: Analyze week-01 (foundational concepts)
test_analyze_week01() {
    local output
    output=$(zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach analyze lectures/week-01.qmd 2>&1
    ")

    if echo "$output" | grep -q "descriptive-stats\|data-types\|distributions"; then
        log_pass "Week 1 analysis extracts concepts"
    else
        log_fail "Week 1 analysis missing concepts"
        return 1
    fi

    # Check for concept categories
    if echo "$output" | grep -q "fundamental.*core"; then
        log_pass "Week 1 concept categories detected"
    else
        log_fail "Week 1 concept categories missing"
    fi
}

# Test 2.2: Analyze week-02 (with prerequisites)
test_analyze_week02() {
    local output
    output=$(zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach analyze lectures/week-02.qmd 2>&1
    ")

    if echo "$output" | grep -q "probability-basics\|sampling\|inference"; then
        log_pass "Week 2 analysis extracts concepts"
    else
        log_fail "Week 2 analysis missing concepts"
        return 1
    fi

    # Check for prerequisites
    if echo "$output" | grep -q "Prerequisites"; then
        log_pass "Week 2 prerequisites listed"
    else
        log_fail "Week 2 prerequisites missing"
    fi
}

# Test 2.3: Analyze week-03 (advanced concepts)
test_analyze_week03() {
    local output
    output=$(zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach analyze lectures/week-03.qmd 2>&1
    ")

    if echo "$output" | grep -q "correlation.*linear-regression"; then
        log_pass "Week 3 analysis extracts concepts"
    else
        log_fail "Week 3 analysis missing concepts"
        return 1
    fi
}

# =============================================================================
# SECTION 3: Prerequisite Validation
# =============================================================================

log_section "Prerequisite Validation"

# Test 3.1: Validate proper dependency chain
test_validate_proper_deps() {
    local output
    output=$(zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach validate --deep lectures/week-01.qmd lectures/week-02.qmd lectures/week-03.qmd 2>&1
    ")

    if echo "$output" | grep -qi "valid\|success\|✓\|✅"; then
        log_pass "Proper dependency chain validates"
    else
        log_fail "Validation failed for proper dependencies"
        return 1
    fi
}

# Test 3.2: Detect circular dependency in broken file
test_detect_circular_dependency() {
    local output
    output=$(zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach validate --deep lectures/week-03-broken.qmd 2>&1
    ")

    if echo "$output" | grep -qi "circular\|cycle\|invalid"; then
        log_pass "Circular dependency detected in broken file"
    else
        log_fail "Circular dependency not detected"
        return 1
    fi
}

# Test 3.3: Validate concept ordering
test_validate_concept_ordering() {
    local output
    output=$(zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach validate --concepts lectures/ 2>&1
    ")

    # Should pass validation for week 1-3, fail for broken file
    if echo "$output" | grep -q "week-01\|week-02\|week-03"; then
        log_pass "Concept ordering validation runs"
    else
        log_fail "Concept ordering validation failed"
        return 1
    fi
}

# =============================================================================
# SECTION 4: Batch Analysis
# =============================================================================

log_section "Batch Analysis"

# Test 4.1: Batch analyze all lectures
test_batch_analyze() {
    local output
    output=$(zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach analyze --batch lectures/ 2>&1
    ")

    if echo "$output" | grep -q "week-01\|week-02\|week-03"; then
        log_pass "Batch analysis processes multiple files"
    else
        log_fail "Batch analysis missing files"
        return 1
    fi

    # Check for summary
    if echo "$output" | grep -qi "total.*files\|summary\|analyzed"; then
        log_pass "Batch analysis shows summary"
    else
        log_fail "Batch analysis missing summary"
    fi
}

# Test 4.2: Cache is created during batch analysis
test_batch_cache_created() {
    # Run batch analysis
    zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach analyze --batch lectures/ >/dev/null 2>&1
    "

    if [[ -d "$DEMO_COURSE/.teach/analysis-cache" ]]; then
        log_pass "Cache directory created"
    else
        log_fail "Cache directory not created"
        return 1
    fi

    # Check for cached files
    local cache_files=($(find "$DEMO_COURSE/.teach/analysis-cache" -name "*.json" 2>/dev/null))
    if [[ ${#cache_files[@]} -gt 0 ]]; then
        log_pass "Cache files created (${#cache_files[@]} files)"
    else
        log_fail "No cache files created"
    fi
}

# Test 4.3: Second run uses cache
test_batch_uses_cache() {
    # First run (creates cache)
    zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach analyze --batch lectures/ >/dev/null 2>&1
    "

    # Second run (should use cache)
    local output
    output=$(zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach analyze --batch lectures/ 2>&1
    ")

    if echo "$output" | grep -qi "cache\|cached\|using.*existing"; then
        log_pass "Second run uses cache"
    else
        log_fail "Second run didn't mention cache usage"
    fi
}

# =============================================================================
# SECTION 5: Slide Optimization
# =============================================================================

log_section "Slide Optimization"

# Test 5.1: Slide break analysis on week-01
test_slide_breaks_week01() {
    local output
    output=$(zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach analyze --slide-breaks lectures/week-01.qmd 2>&1
    ")

    if echo "$output" | grep -qi "slide\|break\|section\|timing"; then
        log_pass "Slide break analysis runs on week-01"
    else
        log_fail "Slide break analysis missing output"
        return 1
    fi
}

# Test 5.2: Slide timing estimates
test_slide_timing() {
    local output
    output=$(zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach analyze --slide-breaks lectures/week-02.qmd 2>&1
    ")

    if echo "$output" | grep -qi "minutes\|time\|duration"; then
        log_pass "Slide timing estimates provided"
    else
        log_fail "Slide timing estimates missing"
    fi
}

# =============================================================================
# SECTION 6: Report Generation
# =============================================================================

log_section "Report Generation"

# Test 6.1: JSON report generated
test_json_report() {
    zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach analyze --batch lectures/ --format json >/dev/null 2>&1
    "

    if [[ -f "$DEMO_COURSE/.teach/reports/analysis-report.json" ]] || \
       ls "$DEMO_COURSE/.teach/"*report*.json &>/dev/null; then
        log_pass "JSON report generated"
    else
        log_fail "JSON report not found"
        return 1
    fi
}

# Test 6.2: Markdown report generated
test_markdown_report() {
    zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach analyze --batch lectures/ --format markdown >/dev/null 2>&1
    "

    if [[ -f "$DEMO_COURSE/.teach/reports/analysis-report.md" ]] || \
       ls "$DEMO_COURSE/.teach/"*report*.md &>/dev/null; then
        log_pass "Markdown report generated"
    else
        log_fail "Markdown report not found"
    fi
}

# =============================================================================
# SECTION 7: Integration Tests
# =============================================================================

log_section "Integration Tests"

# Test 7.1: Full workflow (analyze → validate → optimize)
test_full_workflow() {
    local exit_code=0

    # Step 1: Batch analyze
    zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach analyze --batch lectures/ >/dev/null 2>&1
    " || exit_code=1

    # Step 2: Validate
    zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach validate --deep lectures/*.qmd >/dev/null 2>&1
    " || exit_code=1

    # Step 3: Optimize slides
    zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach analyze --slide-breaks lectures/week-01.qmd >/dev/null 2>&1
    " || exit_code=1

    if [[ $exit_code -eq 0 ]]; then
        log_pass "Full workflow completes without errors"
    else
        log_fail "Full workflow encountered errors"
    fi
}

# Test 7.2: Concepts build proper dependency graph
test_dependency_graph() {
    local output
    output=$(zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach analyze lectures/week-03.qmd 2>&1
    ")

    # linear-regression should require: correlation, inference
    if echo "$output" | grep -qi "correlation.*inference"; then
        log_pass "Dependency graph shows prerequisites"
    else
        log_fail "Dependency graph incomplete"
    fi
}

# Test 7.3: Bloom levels correctly assigned
test_bloom_levels() {
    local output
    output=$(zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach analyze lectures/week-01.qmd 2>&1
    ")

    # Should show different Bloom levels
    if echo "$output" | grep -qi "remember.*understand\|understand.*apply\|analyze"; then
        log_pass "Bloom taxonomy levels detected"
    else
        log_fail "Bloom levels not shown"
    fi
}

# =============================================================================
# SECTION 8: Extended Test Cases (Week 4+)
# =============================================================================

log_section "Extended Test Cases"

# Test 8.1: Analyze week-04 (multiple regression concepts)
test_analyze_week04() {
    local output
    output=$(zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach analyze lectures/week-04.qmd 2>&1
    ")

    if echo "$output" | grep -q "multiple-regression\|model-selection\|assumptions"; then
        log_pass "Week 4 analysis extracts advanced concepts"
    else
        log_fail "Week 4 analysis missing concepts"
        return 1
    fi
}

# Test 8.2: Detect missing prerequisite
test_missing_prerequisite() {
    local output
    output=$(zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach validate --deep lectures/week-05-missing-prereq.qmd 2>&1
    ")

    if echo "$output" | grep -qi "missing\|not found\|nonexistent"; then
        log_pass "Missing prerequisite detected"
    else
        log_fail "Missing prerequisite not detected"
        return 1
    fi
}

# Test 8.3: Complex dependency chain (Week 4 builds on Weeks 1-3)
test_complex_dependency_chain() {
    local output
    output=$(zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach analyze lectures/week-04.qmd 2>&1
    ")

    # model-selection should ultimately require concepts from earlier weeks
    if echo "$output" | grep -qi "prerequisite\|require\|depend"; then
        log_pass "Complex dependency chain shown"
    else
        log_fail "Complex dependencies not shown"
    fi
}

# Test 8.4: Highest Bloom level (evaluate)
test_highest_bloom_level() {
    local output
    output=$(zsh -c "
        source '$PLUGIN_DIR/flow.plugin.zsh' 2>/dev/null
        cd '$DEMO_COURSE'
        teach analyze lectures/week-04.qmd 2>&1
    ")

    if echo "$output" | grep -qi "evaluate"; then
        log_pass "Highest Bloom level (evaluate) detected in Week 4"
    else
        log_fail "Evaluate Bloom level not shown"
    fi
}

# =============================================================================
# CLEANUP AND RUN ALL TESTS
# =============================================================================

echo -e "${BOLD}${BLUE}========================================${RESET}"
echo -e "${BOLD}${BLUE}  E2E Test Suite: teach analyze${RESET}"
echo -e "${BOLD}${BLUE}  Demo Course: STAT-101${RESET}"
echo -e "${BOLD}${BLUE}========================================${RESET}"

# Setup
cleanup
test_demo_course_exists
test_lecture_files_exist
test_concepts_json_exists
test_plugin_sources

# Single file analysis
test_analyze_week01
test_analyze_week02
test_analyze_week03

# Prerequisite validation
test_validate_proper_deps
test_detect_circular_dependency
test_validate_concept_ordering

# Batch analysis
test_batch_analyze
test_batch_cache_created
test_batch_uses_cache

# Slide optimization
test_slide_breaks_week01
test_slide_timing

# Report generation
test_json_report
test_markdown_report

# Integration
test_full_workflow
test_dependency_graph
test_bloom_levels

# Section 8: Extended Test Cases
test_analyze_week04
test_missing_prerequisite
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

# Exit with appropriate code
if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}All E2E tests passed!${RESET}"
    exit 0
else
    echo -e "${RED}${BOLD}$FAIL test(s) failed${RESET}"
    exit 1
fi
