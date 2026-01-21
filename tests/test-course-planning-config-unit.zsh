#!/usr/bin/env zsh
# tests/test-course-planning-config-unit.zsh
# Unit tests for Course Planning configuration examples

# Test setup
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOCS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)/docs/guides"
DOCS_FILE="$DOCS_DIR/COURSE-PLANNING-BEST-PRACTICES.md"

# Temp file for YAML extraction
TEMP_YAML="/tmp/course-planning-test-$$.yaml"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
pass() {
    ((TESTS_RUN++))
    ((TESTS_PASSED++))
    echo -e "${GREEN}✓${NC} $1"
}

fail() {
    ((TESTS_RUN++))
    ((TESTS_FAILED++))
    echo -e "${RED}✗${NC} $1"
    [[ -n "${2:-}" ]] && echo -e "  ${RED}Error: $2${NC}"
}

section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

subsection() {
    echo ""
    echo -e "${CYAN}── $1 ──${NC}"
}

cleanup() {
    rm -f "$TEMP_YAML"
}
trap cleanup EXIT

echo "========================================="
echo "  Course Planning Config - Unit Tests"
echo "========================================="
echo ""

# ============================================================================
# SECTION 1: YAML Extraction Tests
# ============================================================================
section "1. YAML Extraction Tests"

subsection "1.1 Extract all YAML blocks"
# Extract first YAML block and test basic structure
YAML_COUNT=$(grep -c '```yaml' "$DOCS_FILE" 2>/dev/null || echo 0)
if [[ $YAML_COUNT -ge 50 ]]; then
    pass "Found $YAML_COUNT YAML code blocks"
else
    fail "Expected at least 50 YAML blocks, found $YAML_COUNT"
fi

subsection "1.2 First YAML block validity"
# Extract and validate first complete YAML block
FIRST_YAML=$(sed -n '/```yaml/,/```/p' "$DOCS_FILE" | head -30)
if echo "$FIRST_YAML" | grep -q "course:"; then
    pass "First YAML block contains course structure"
else
    fail "First YAML block missing course structure"
fi

# ============================================================================
# SECTION 2: teach-config.yml Structure Tests
# ============================================================================
section "2. teach-config.yml Structure Tests"

subsection "2.1 course section"
if grep -A 10 "course:" "$DOCS_FILE" | grep -q "name:"; then
    pass "course.name documented"
else
    fail "course.name not found in docs"
fi

if grep -A 10 "course:" "$DOCS_FILE" | grep -q "semester:"; then
    pass "course.semester documented"
else
    fail "course.semester not found in docs"
fi

if grep -A 10 "course:" "$DOCS_FILE" | grep -q "year:"; then
    pass "course.year documented"
else
    fail "course.year not found in docs"
fi

if grep -A 10 "course:" "$DOCS_FILE" | grep -q "credits:"; then
    pass "course.credits documented"
else
    fail "course.credits not found in docs"
fi

subsection "2.2 instructor section"
if grep -q "instructor:" "$DOCS_FILE"; then
    pass "instructor section documented"
else
    fail "instructor section not found"
fi

if grep -A 10 "instructor:" "$DOCS_FILE" | grep -q "name:"; then
    pass "instructor.name documented"
else
    fail "instructor.name not found in docs"
fi

if grep -A 10 "instructor:" "$DOCS_FILE" | grep -q "email:"; then
    pass "instructor.email documented"
else
    fail "instructor.email not found in docs"
fi

subsection "2.3 learning_outcomes section"
if grep -q "learning_outcomes:" "$DOCS_FILE"; then
    pass "learning_outcomes section documented"
else
    fail "learning_outcomes section not found"
fi

# Check for outcome structure
if grep -A 20 "learning_outcomes:" "$DOCS_FILE" | grep -q "id:"; then
    pass "Outcome id field documented"
else
    fail "Outcome id field not found"
fi

if grep -A 20 "learning_outcomes:" "$DOCS_FILE" | grep -q "description:"; then
    pass "Outcome description field documented"
else
    fail "Outcome description field not found"
fi

if grep -A 20 "learning_outcomes:" "$DOCS_FILE" | grep -q "bloom_level:"; then
    pass "Outcome bloom_level field documented"
else
    fail "Outcome bloom_level field not found"
fi

# ============================================================================
# SECTION 3: Assessment Structure Tests
# ============================================================================
section "3. Assessment Structure Tests"

subsection "3.1 assessments section"
if grep -q "assessments:" "$DOCS_FILE"; then
    pass "assessments section documented"
else
    fail "assessments section not found"
fi

# Check assessment structure
if grep -A 15 "assessments:" "$DOCS_FILE" | grep -q "name:"; then
    pass "Assessment name field documented"
else
    fail "Assessment name field not found"
fi

if grep -A 15 "assessments:" "$DOCS_FILE" | grep -q "weight:"; then
    pass "Assessment weight field documented"
else
    fail "Assessment weight field not found"
fi

subsection "3.2 Assessment types documented"
if grep -q "type:.*performance_task\|type:.*exam\|type:.*problem_set" "$DOCS_FILE"; then
    pass "Assessment types documented"
else
    fail "Assessment types not clearly documented"
fi

subsection "3.3 GRASPS framework"
if grep -q "grasps:" "$DOCS_FILE"; then
    pass "GRASPS framework documented"
else
    fail "GRASPS framework not found"
fi

# Check GRASPS components
for component in "Goal" "Role" "Audience" "Situation" "Product" "Standards"; do
    if grep -q "$component" "$DOCS_FILE"; then
        pass "GRASPS $component documented"
    else
        fail "GRASPS $component not found"
    fi
done

# ============================================================================
# SECTION 4: Bloom's Level Tests
# ============================================================================
section "4. Bloom's Level Tests"

subsection "4.1 All six levels documented"
BLOOM_LEVELS=("remember" "understand" "apply" "analyze" "evaluate" "create")
for level in "${BLOOM_LEVELS[@]}"; do
    if grep -q "bloom_level:.*'$level'\|bloom_level:.*\"$level\"" "$DOCS_FILE"; then
        pass "Bloom's level '$level' documented"
    else
        fail "Bloom's level '$level' not found"
    fi
done

subsection "4.2 Action verbs for each level"
# Remember verbs
if grep -qE "Define|List|Identify|Recall" "$DOCS_FILE"; then
    pass "Remember level verbs documented"
else
    fail "Remember level verbs not found"
fi

# Understand verbs
if grep -qE "Explain|Interpret|Describe|Summarize" "$DOCS_FILE"; then
    pass "Understand level verbs documented"
else
    fail "Understand level verbs not found"
fi

# Apply verbs
if grep -qE "Apply|Implement|Use|Execute" "$DOCS_FILE"; then
    pass "Apply level verbs documented"
else
    fail "Apply level verbs not found"
fi

# Analyze verbs
if grep -qE "Analyze|Compare|Contrast|Differentiate" "$DOCS_FILE"; then
    pass "Analyze level verbs documented"
else
    fail "Analyze level verbs not found"
fi

# Evaluate verbs
if grep -qE "Evaluate|Judge|Critique|Justify" "$DOCS_FILE"; then
    pass "Evaluate level verbs documented"
else
    fail "Evaluate level verbs not found"
fi

# Create verbs
if grep -qE "Create|Design|Develop|Construct" "$DOCS_FILE"; then
    pass "Create level verbs documented"
else
    fail "Create level verbs not found"
fi

# ============================================================================
# SECTION 5: Grading Configuration Tests
# ============================================================================
section "5. Grading Configuration Tests"

subsection "5.1 Grading scale"
if grep -q "grading:" "$DOCS_FILE"; then
    pass "grading section documented"
else
    fail "grading section not found"
fi

if grep -A 15 "grading:" "$DOCS_FILE" | grep -q "scale:"; then
    pass "grading.scale documented"
else
    fail "grading.scale not found"
fi

if grep -qE "A:|B:|C:|D:|F:" "$DOCS_FILE"; then
    pass "Letter grade scale documented"
else
    fail "Letter grade scale not found"
fi

subsection "5.2 Grade calculation"
if grep -q "calculation:" "$DOCS_FILE"; then
    pass "Grade calculation documented"
else
    fail "Grade calculation not found"
fi

if grep -qE "weighted_average|rounding|borderline" "$DOCS_FILE"; then
    pass "Grade calculation options documented"
else
    fail "Grade calculation options not found"
fi

subsection "5.3 Late work policies"
if grep -q "late_work:" "$DOCS_FILE"; then
    pass "Late work policy documented"
else
    fail "Late work policy not found"
fi

if grep -qE "strict|flexible|token" "$DOCS_FILE"; then
    pass "Late work policy types documented"
else
    fail "Late work policy types not found"
fi

# ============================================================================
# SECTION 6: Course Structure Tests
# ============================================================================
section "6. Course Structure Tests"

subsection "6.1 course_structure section"
if grep -q "course_structure:" "$DOCS_FILE"; then
    pass "course_structure section documented"
else
    fail "course_structure section not found"
fi

subsection "6.2 Structure fields"
if grep -A 10 "course_structure:" "$DOCS_FILE" | grep -q "week:"; then
    pass "Structure week field documented"
else
    fail "Structure week field not found"
fi

if grep -A 10 "course_structure:" "$DOCS_FILE" | grep -q "topic:"; then
    pass "Structure topic field documented"
else
    fail "Structure topic field not found"
fi

if grep -A 10 "course_structure:" "$DOCS_FILE" | grep -q "outcomes:"; then
    pass "Structure outcomes field documented"
else
    fail "Structure outcomes field not found"
fi

if grep -A 10 "course_structure:" "$DOCS_FILE" | grep -q "assessments:"; then
    pass "Structure assessments field documented"
else
    fail "Structure assessments field not found"
fi

# ============================================================================
# SECTION 7: Lesson Plan Structure Tests
# ============================================================================
section "7. Lesson Plan Structure Tests"

subsection "7.1 WHERETO elements"
WHERETO=("where" "hook" "equip" "rethink" "evaluate" "tailored" "organized")
for element in "${WHERETO[@]}"; do
    if grep -q "$element:" "$DOCS_FILE"; then
        pass "WHERETO $element documented"
    else
        fail "WHERETO $element not found"
    fi
done

subsection "7.2 Lesson plan fields"
if grep -q "lesson-plan.yml\|lesson_plan.yml" "$DOCS_FILE"; then
    pass "lesson-plan.yml referenced"
else
    fail "lesson-plan.yml not referenced"
fi

if grep -A 5 "where:" "$DOCS_FILE" | grep -q "essential_question:"; then
    pass "Essential question documented"
else
    fail "Essential question not found"
fi

if grep -A 5 "hook:" "$DOCS_FILE" | grep -q "activity:"; then
    pass "Hook activity documented"
else
    fail "Hook activity not found"
fi

# ============================================================================
# SECTION 8: Alignment Matrix Tests
# ============================================================================
section "8. Alignment Matrix Tests"

subsection "8.1 I/R/M progression"
if grep -qE "I/|R/|M/" "$DOCS_FILE"; then
    pass "I/R/M progression notation documented"
else
    fail "I/R/M progression notation not found"
fi

if grep -qE "Introduced|Reinforced|Mastery" "$DOCS_FILE"; then
    pass "I/R/M terminology explained"
else
    fail "I/R/M terminology not explained"
fi

subsection "8.2 Alignment matrix format"
if grep -qE "\| Outcome.*HW.*Midterm" "$DOCS_FILE"; then
    pass "Alignment matrix format documented"
else
    fail "Alignment matrix format not found"
fi

# ============================================================================
# SECTION 9: Rubric Structure Tests
# ============================================================================
section "9. Rubric Structure Tests"

subsection "9.1 Rubric types"
if grep -q "rubric:" "$DOCS_FILE"; then
    pass "rubric structure documented"
else
    fail "rubric structure not found"
fi

if grep -qE "analytic|holistic|single-point" "$DOCS_FILE"; then
    pass "Rubric types documented"
else
    fail "Rubric types not found"
fi

subsection "9.2 Rubric fields"
if grep -qE "dimensions:|levels:|descriptors:" "$DOCS_FILE"; then
    pass "Rubric fields documented"
else
    fail "Rubric fields not found"
fi

if grep -qE "weight:|score:|description:" "$DOCS_FILE"; then
    pass "Rubric scoring documented"
else
    fail "Rubric scoring not found"
fi

# ============================================================================
# SECTION 10: Scholar Configuration Tests
# ============================================================================
section "10. Scholar Configuration Tests"

subsection "10.1 Scholar section"
if grep -q "scholar:" "$DOCS_FILE"; then
    pass "scholar section documented"
else
    fail "scholar section not found"
fi

subsection "10.2 Scholar settings"
if grep -A 10 "scholar:" "$DOCS_FILE" | grep -q "field:"; then
    pass "Scholar field setting documented"
else
    fail "Scholar field setting not found"
fi

if grep -A 10 "scholar:" "$DOCS_FILE" | grep -q "level:"; then
    pass "Scholar level setting documented"
else
    fail "Scholar level setting not found"
fi

if grep -A 10 "scholar:" "$DOCS_FILE" | grep -q "style:"; then
    pass "Scholar style settings documented"
else
    fail "Scholar style settings not found"
fi

if grep -qE "conceptual|computational|rigorous|applied" "$DOCS_FILE"; then
    pass "Scholar style presets documented"
else
    fail "Scholar style presets not found"
fi

# ============================================================================
# TEST SUMMARY
# ============================================================================
section "TEST SUMMARY"

TOTAL=$((TESTS_PASSED + TESTS_FAILED))

echo ""
echo "────────────────────────────────────────────"
echo -e "  ${GREEN}Passed:${NC} $TESTS_PASSED"
echo -e "  ${RED}Failed:${NC} $TESTS_FAILED"
echo -e "  ${BLUE}Total:${NC}  $TOTAL"
echo "────────────────────────────────────────────"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}✅ All configuration unit tests passed!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some tests failed. Please review.${NC}"
    exit 1
fi
