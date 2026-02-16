#!/usr/bin/env zsh
# tests/test-course-planning-config-unit.zsh
# Unit tests for Course Planning configuration examples

# Test setup
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/test-framework.zsh"

DOCS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)/docs/guides"
DOCS_FILE="$DOCS_DIR/COURSE-PLANNING-BEST-PRACTICES.md"

# Temp file for YAML extraction
TEMP_YAML="/tmp/course-planning-test-$$.yaml"

# Visual grouping helpers (non-framework)
section() {
    echo ""
    echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo "${CYAN}$1${RESET}"
    echo "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

subsection() {
    echo ""
    echo "${CYAN}── $1 ──${RESET}"
}

cleanup() {
    rm -f "$TEMP_YAML"
}
trap cleanup EXIT

test_suite_start "Course Planning Config - Unit Tests"

# ============================================================================
# SECTION 1: YAML Extraction Tests
# ============================================================================
section "1. YAML Extraction Tests"

subsection "1.1 Extract all YAML blocks"
YAML_COUNT=$(grep -c '```yaml' "$DOCS_FILE" 2>/dev/null || echo 0)
test_case "Found $YAML_COUNT YAML code blocks"
if [[ $YAML_COUNT -ge 50 ]]; then
    test_pass
else
    test_fail "Expected at least 50 YAML blocks, found $YAML_COUNT"
fi

subsection "1.2 First YAML block validity"
FIRST_YAML=$(sed -n '/```yaml/,/```/p' "$DOCS_FILE" | head -30)
test_case "First YAML block contains course structure"
if echo "$FIRST_YAML" | grep -q "course:"; then
    test_pass
else
    test_fail "First YAML block missing course structure"
fi

# ============================================================================
# SECTION 2: teach-config.yml Structure Tests
# ============================================================================
section "2. teach-config.yml Structure Tests"

subsection "2.1 course section"
test_case "course.name documented"
if grep -A 10 "course:" "$DOCS_FILE" | grep -q "name:"; then
    test_pass
else
    test_fail "course.name not found in docs"
fi

test_case "course.semester documented"
if grep -A 10 "course:" "$DOCS_FILE" | grep -q "semester:"; then
    test_pass
else
    test_fail "course.semester not found in docs"
fi

test_case "course.year documented"
if grep -A 10 "course:" "$DOCS_FILE" | grep -q "year:"; then
    test_pass
else
    test_fail "course.year not found in docs"
fi

test_case "course.credits documented"
if grep -A 10 "course:" "$DOCS_FILE" | grep -q "credits:"; then
    test_pass
else
    test_fail "course.credits not found in docs"
fi

subsection "2.2 instructor section"
test_case "instructor section documented"
if grep -q "instructor:" "$DOCS_FILE"; then
    test_pass
else
    test_fail "instructor section not found"
fi

test_case "instructor.name documented"
if grep -A 10 "instructor:" "$DOCS_FILE" | grep -q "name:"; then
    test_pass
else
    test_fail "instructor.name not found in docs"
fi

test_case "instructor.email documented"
if grep -A 10 "instructor:" "$DOCS_FILE" | grep -q "email:"; then
    test_pass
else
    test_fail "instructor.email not found in docs"
fi

subsection "2.3 learning_outcomes section"
test_case "learning_outcomes section documented"
if grep -q "learning_outcomes:" "$DOCS_FILE"; then
    test_pass
else
    test_fail "learning_outcomes section not found"
fi

test_case "Outcome id field documented"
if grep -A 20 "learning_outcomes:" "$DOCS_FILE" | grep -q "id:"; then
    test_pass
else
    test_fail "Outcome id field not found"
fi

test_case "Outcome description field documented"
if grep -A 20 "learning_outcomes:" "$DOCS_FILE" | grep -q "description:"; then
    test_pass
else
    test_fail "Outcome description field not found"
fi

test_case "Outcome bloom_level field documented"
if grep -A 20 "learning_outcomes:" "$DOCS_FILE" | grep -q "bloom_level:"; then
    test_pass
else
    test_fail "Outcome bloom_level field not found"
fi

# ============================================================================
# SECTION 3: Assessment Structure Tests
# ============================================================================
section "3. Assessment Structure Tests"

subsection "3.1 assessments section"
test_case "assessments section documented"
if grep -q "assessments:" "$DOCS_FILE"; then
    test_pass
else
    test_fail "assessments section not found"
fi

test_case "Assessment name field documented"
if grep -A 15 "assessments:" "$DOCS_FILE" | grep -q "name:"; then
    test_pass
else
    test_fail "Assessment name field not found"
fi

test_case "Assessment weight field documented"
if grep -A 15 "assessments:" "$DOCS_FILE" | grep -q "weight:"; then
    test_pass
else
    test_fail "Assessment weight field not found"
fi

subsection "3.2 Assessment types documented"
test_case "Assessment types documented"
if grep -q "type:.*performance_task\|type:.*exam\|type:.*problem_set" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Assessment types not clearly documented"
fi

subsection "3.3 GRASPS framework"
test_case "GRASPS framework documented"
if grep -q "grasps:" "$DOCS_FILE"; then
    test_pass
else
    test_fail "GRASPS framework not found"
fi

# Check GRASPS components
for component in "Goal" "Role" "Audience" "Situation" "Product" "Standards"; do
    test_case "GRASPS $component documented"
    if grep -q "$component" "$DOCS_FILE"; then
        test_pass
    else
        test_fail "GRASPS $component not found"
    fi
done

# ============================================================================
# SECTION 4: Bloom's Level Tests
# ============================================================================
section "4. Bloom's Level Tests"

subsection "4.1 All six levels documented"
BLOOM_LEVELS=("remember" "understand" "apply" "analyze" "evaluate" "create")
for level in "${BLOOM_LEVELS[@]}"; do
    test_case "Bloom's level '$level' documented"
    if grep -q "bloom_level:.*'$level'\|bloom_level:.*\"$level\"" "$DOCS_FILE"; then
        test_pass
    else
        test_fail "Bloom's level '$level' not found"
    fi
done

subsection "4.2 Action verbs for each level"
# Remember verbs
test_case "Remember level verbs documented"
if grep -qE "Define|List|Identify|Recall" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Remember level verbs not found"
fi

# Understand verbs
test_case "Understand level verbs documented"
if grep -qE "Explain|Interpret|Describe|Summarize" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Understand level verbs not found"
fi

# Apply verbs
test_case "Apply level verbs documented"
if grep -qE "Apply|Implement|Use|Execute" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Apply level verbs not found"
fi

# Analyze verbs
test_case "Analyze level verbs documented"
if grep -qE "Analyze|Compare|Contrast|Differentiate" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Analyze level verbs not found"
fi

# Evaluate verbs
test_case "Evaluate level verbs documented"
if grep -qE "Evaluate|Judge|Critique|Justify" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Evaluate level verbs not found"
fi

# Create verbs
test_case "Create level verbs documented"
if grep -qE "Create|Design|Develop|Construct" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Create level verbs not found"
fi

# ============================================================================
# SECTION 5: Grading Configuration Tests
# ============================================================================
section "5. Grading Configuration Tests"

subsection "5.1 Grading scale"
test_case "grading section documented"
if grep -q "grading:" "$DOCS_FILE"; then
    test_pass
else
    test_fail "grading section not found"
fi

test_case "grading.scale documented"
if grep -A 15 "grading:" "$DOCS_FILE" | grep -q "scale:"; then
    test_pass
else
    test_fail "grading.scale not found"
fi

test_case "Letter grade scale documented"
if grep -qE "A:|B:|C:|D:|F:" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Letter grade scale not found"
fi

subsection "5.2 Grade calculation"
test_case "Grade calculation documented"
if grep -q "calculation:" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Grade calculation not found"
fi

test_case "Grade calculation options documented"
if grep -qE "weighted_average|rounding|borderline" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Grade calculation options not found"
fi

subsection "5.3 Late work policies"
test_case "Late work policy documented"
if grep -q "late_work:" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Late work policy not found"
fi

test_case "Late work policy types documented"
if grep -qE "strict|flexible|token" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Late work policy types not found"
fi

# ============================================================================
# SECTION 6: Course Structure Tests
# ============================================================================
section "6. Course Structure Tests"

subsection "6.1 course_structure section"
test_case "course_structure section documented"
if grep -q "course_structure:" "$DOCS_FILE"; then
    test_pass
else
    test_fail "course_structure section not found"
fi

subsection "6.2 Structure fields"
test_case "Structure week field documented"
if grep -A 10 "course_structure:" "$DOCS_FILE" | grep -q "week:"; then
    test_pass
else
    test_fail "Structure week field not found"
fi

test_case "Structure topic field documented"
if grep -A 10 "course_structure:" "$DOCS_FILE" | grep -q "topic:"; then
    test_pass
else
    test_fail "Structure topic field not found"
fi

test_case "Structure outcomes field documented"
if grep -A 10 "course_structure:" "$DOCS_FILE" | grep -q "outcomes:"; then
    test_pass
else
    test_fail "Structure outcomes field not found"
fi

test_case "Structure assessments field documented"
if grep -A 10 "course_structure:" "$DOCS_FILE" | grep -q "assessments:"; then
    test_pass
else
    test_fail "Structure assessments field not found"
fi

# ============================================================================
# SECTION 7: Lesson Plan Structure Tests
# ============================================================================
section "7. Lesson Plan Structure Tests"

subsection "7.1 WHERETO elements"
WHERETO=("where" "hook" "equip" "rethink" "evaluate" "tailored" "organized")
for element in "${WHERETO[@]}"; do
    test_case "WHERETO $element documented"
    if grep -q "$element:" "$DOCS_FILE"; then
        test_pass
    else
        test_fail "WHERETO $element not found"
    fi
done

subsection "7.2 Lesson plan fields"
test_case "lesson-plan.yml referenced"
if grep -q "lesson-plan.yml\|lesson_plan.yml" "$DOCS_FILE"; then
    test_pass
else
    test_fail "lesson-plan.yml not referenced"
fi

test_case "Essential question documented"
if grep -A 5 "where:" "$DOCS_FILE" | grep -q "essential_question:"; then
    test_pass
else
    test_fail "Essential question not found"
fi

test_case "Hook activity documented"
if grep -A 5 "hook:" "$DOCS_FILE" | grep -q "activity:"; then
    test_pass
else
    test_fail "Hook activity not found"
fi

# ============================================================================
# SECTION 8: Alignment Matrix Tests
# ============================================================================
section "8. Alignment Matrix Tests"

subsection "8.1 I/R/M progression"
test_case "I/R/M progression notation documented"
if grep -qE "I/|R/|M/" "$DOCS_FILE"; then
    test_pass
else
    test_fail "I/R/M progression notation not found"
fi

test_case "I/R/M terminology explained"
if grep -qE "Introduced|Reinforced|Mastery" "$DOCS_FILE"; then
    test_pass
else
    test_fail "I/R/M terminology not explained"
fi

subsection "8.2 Alignment matrix format"
test_case "Alignment matrix format documented"
if grep -qE "\| Outcome.*HW.*Midterm" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Alignment matrix format not found"
fi

# ============================================================================
# SECTION 9: Rubric Structure Tests
# ============================================================================
section "9. Rubric Structure Tests"

subsection "9.1 Rubric types"
test_case "rubric structure documented"
if grep -q "rubric:" "$DOCS_FILE"; then
    test_pass
else
    test_fail "rubric structure not found"
fi

test_case "Rubric types documented"
if grep -qE "analytic|holistic|single-point" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Rubric types not found"
fi

subsection "9.2 Rubric fields"
test_case "Rubric fields documented"
if grep -qE "dimensions:|levels:|descriptors:" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Rubric fields not found"
fi

test_case "Rubric scoring documented"
if grep -qE "weight:|score:|description:" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Rubric scoring not found"
fi

# ============================================================================
# SECTION 10: Scholar Configuration Tests
# ============================================================================
section "10. Scholar Configuration Tests"

subsection "10.1 Scholar section"
test_case "scholar section documented"
if grep -q "scholar:" "$DOCS_FILE"; then
    test_pass
else
    test_fail "scholar section not found"
fi

subsection "10.2 Scholar settings"
test_case "Scholar field setting documented"
if grep -A 10 "scholar:" "$DOCS_FILE" | grep -q "field:"; then
    test_pass
else
    test_fail "Scholar field setting not found"
fi

test_case "Scholar level setting documented"
if grep -A 10 "scholar:" "$DOCS_FILE" | grep -q "level:"; then
    test_pass
else
    test_fail "Scholar level setting not found"
fi

test_case "Scholar style settings documented"
if grep -A 10 "scholar:" "$DOCS_FILE" | grep -q "style:"; then
    test_pass
else
    test_fail "Scholar style settings not found"
fi

test_case "Scholar style presets documented"
if grep -qE "conceptual|computational|rigorous|applied" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Scholar style presets not found"
fi

test_suite_end
exit $?
