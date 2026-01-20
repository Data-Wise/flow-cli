#!/usr/bin/env zsh
# tests/test-course-planning-docs-unit.zsh
# Unit tests for Course Planning Best Practices documentation (Phases 2-4)

# Test setup
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOCS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)/docs/guides"
DOCS_FILE="$DOCS_DIR/COURSE-PLANNING-BEST-PRACTICES.md"

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
TESTS_SKIPPED=0

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

# Check if docs file exists
if [[ ! -f "$DOCS_FILE" ]]; then
    echo -e "${RED}ERROR: Documentation file not found: $DOCS_FILE${NC}"
    exit 1
fi

echo "========================================="
echo "  Course Planning Docs - Unit Tests"
echo "========================================="
echo ""
echo "Target: $DOCS_FILE"

# ============================================================================
# SECTION 1: Document Structure Tests
# ============================================================================
section "1. Document Structure Tests"

subsection "1.1 File existence and size"
if [[ -f "$DOCS_FILE" ]]; then
    pass "Documentation file exists"
    LINE_COUNT=$(wc -l < "$DOCS_FILE")
    if [[ $LINE_COUNT -gt 5000 ]]; then
        pass "File has substantial content ($LINE_COUNT lines)"
    else
        fail "File seems too short ($LINE_COUNT lines, expected >5000)"
    fi
else
    fail "Documentation file not found"
fi

subsection "1.2 Version and metadata"
if grep -q "**Version:**" "$DOCS_FILE"; then
    pass "Version metadata present"
else
    fail "Version metadata missing"
fi

if grep -q "**Status:**" "$DOCS_FILE"; then
    pass "Status metadata present"
else
    fail "Status metadata missing"
fi

subsection "1.3 Table of Contents structure"
if grep -q "## Table of Contents" "$DOCS_FILE"; then
    pass "Table of Contents section exists"
else
    fail "Table of Contents section missing"
fi

# Check for all 4 phases in TOC
for phase in "Phase 1" "Phase 2" "Phase 3" "Phase 4"; do
    if grep -q "$phase" "$DOCS_FILE"; then
        pass "Phase reference found: $phase"
    else
        fail "Missing phase reference: $phase"
    fi
done

# ============================================================================
# SECTION 2: Section Existence Tests
# ============================================================================
section "2. Section Existence Tests"

# Main sections (H2)
MAIN_SECTIONS=(
    "1. Course Planning Overview"
    "2. Backward Design Principles"
    "3. Bloom's Taxonomy Integration"
    "4. Syllabus Design"
    "5. Assessment Design"
    "6. Grading Schema Design"
    "7. Lesson Planning"
    "8. Content Creation with Scholar"
    "9. Course Timeline"
    "10. Semester Maintenance"
    "11. Quality Assurance"
    "12. Continuous Improvement"
)

for section_name in "${MAIN_SECTIONS[@]}"; do
    section_num=$(echo "$section_name" | cut -d. -f1)
    if grep -q "^## $section_name" "$DOCS_FILE"; then
        pass "Section $section_num exists: $section_name"
    else
        fail "Section $section_num missing: $section_name"
    fi
done

# ============================================================================
# SECTION 3: Subsection Structure Tests
# ============================================================================
section "3. Subsection Structure Tests"

# Check subsections for key sections
declare -A SUBSECTIONS=(
    ["3.1 Understanding Bloom's Taxonomy"]="3.1"
    ["3.2 The Six Cognitive Levels"]="3.2"
    ["3.3 Writing Measurable Learning Outcomes"]="3.3"
    ["3.4 Bloom's Level Progression"]="3.4"
    ["4.1 Essential Syllabus Components"]="4.1"
    ["5.1 Assessment Types Overview"]="5.1"
    ["5.2 GRASPS Framework"]="5.2"
    ["5.3 Alignment Matrix Design"]="5.3"
    ["6.1 Grading System Options"]="6.1"
    ["7.1 WHERETO Framework"]="7.1"
    ["8.1 Scholar Integration Overview"]="8.1"
    ["9.1 Timeline Overview"]="9.1"
    ["10.1 Weekly Instructor Workflow"]="10.1"
    ["11.1 Pre-Semester Checklist"]="11.1"
    ["12.1 Mid-Semester Feedback"]="12.1"
)

for subsection_name in "${(@k)SUBSECTIONS}"; do
    if grep -q "^### $subsection_name" "$DOCS_FILE"; then
        pass "Subsection ${SUBSECTIONS[$subsection_name]} exists: $subsection_name"
    else
        fail "Subsection ${SUBSECTIONS[$subsection_name]} missing: $subsection_name"
    fi
done

# ============================================================================
# SECTION 4: Cross-Reference Tests
# ============================================================================
section "4. Cross-Reference Tests"

# Check for internal links (Markdown anchors)
ANCHOR_COUNT=$(grep -oE '\]\(#[^)]+\)' "$DOCS_FILE" | wc -l)
if [[ $ANCHOR_COUNT -gt 50 ]]; then
    pass "Sufficient internal links ($ANCHOR_COUNT anchors)"
else
    fail "Too few internal links (found $ANCHOR_COUNT, expected >50)"
fi

# Check for "See Also" sections
SEE_ALSO_COUNT=$(grep -c "## See Also\|### See Also\|**See Also**" "$DOCS_FILE" 2>/dev/null || echo 0)
if [[ $SEE_ALSO_COUNT -gt 5 ]]; then
    pass "Cross-reference sections present ($SEE_ALSO_COUNT found)"
else
    fail "Cross-reference sections sparse (found $SEE_ALSO_COUNT)"
fi

# ============================================================================
# SECTION 5: Code Example Structure Tests
# ============================================================================
section "5. Code Example Structure Tests"

# Count YAML code blocks
YAML_BLOCKS=$(grep -c '```yaml' "$DOCS_FILE" 2>/dev/null || echo 0)
if [[ $YAML_BLOCKS -ge 50 ]]; then
    pass "Sufficient YAML examples ($YAML_BLOCKS blocks)"
else
    fail "Need more YAML examples (found $YAML_BLOCKS, expected >=50)"
fi

# Count bash/zsh code blocks
BASH_BLOCKS=$(grep -c '```bash\|```zsh' "$DOCS_FILE" 2>/dev/null || echo 0)
if [[ $BASH_BLOCKS -ge 20 ]]; then
    pass "Sufficient bash examples ($BASH_BLOCKS blocks)"
else
    fail "Need more bash examples (found $BASH_BLOCKS, expected >=20)"
fi

# Count R code blocks
R_BLOCKS=$(grep -c '```r\|```R' "$DOCS_FILE" 2>/dev/null || echo 0)
if [[ $R_BLOCKS -ge 10 ]]; then
    pass "Sufficient R examples ($R_BLOCKS blocks)"
else
    fail "Need more R examples (found $R_BLOCKS, expected >=10)"
fi

# Count mermaid diagrams
MERMAID_BLOCKS=$(grep -c '```mermaid' "$DOCS_FILE" 2>/dev/null || echo 0)
if [[ $MERMAID_BLOCKS -ge 3 ]]; then
    pass "Mermaid diagrams present ($MERMAID_BLOCKS found)"
else
    fail "Need more mermaid diagrams (found $MERMAID_BLOCKS, expected >=3)"
fi

# ============================================================================
# SECTION 6: STAT 545 Example Tests
# ============================================================================
section "6. STAT 545 Example Tests"

# Check for STAT 545 references
STAT545_REFS=$(grep -c "STAT 545\|STAT545" "$DOCS_FILE" 2>/dev/null || echo 0)
if [[ $STAT545_REFS -ge 50 ]]; then
    pass "STAT 545 examples well-represented ($STAT545_REFs references)"
else
    fail "Need more STAT 545 examples (found $STAT545_REFS, expected >=50)"
fi

# Check for specific STAT 545 outcomes example
if grep -q "LO1.*Visualize\|LO2.*Build Models\|LO3.*Communicate" "$DOCS_FILE"; then
    pass "STAT 545 learning outcomes documented"
else
    fail "STAT 545 learning outcomes not clearly documented"
fi

# Check for STAT 545 assessment plan
if grep -q "Homework.*30%\|Midterm.*20%\|Project.*30%\|Final.*20%" "$DOCS_FILE"; then
    pass "STAT 545 assessment weights documented"
else
    fail "STAT 545 assessment weights not clearly documented"
fi

# ============================================================================
# SECTION 7: teach-config.yml Example Tests
# ============================================================================
section "7. teach-config.yml Example Tests"

# Check for teach-config.yml examples
if grep -q "teach-config.yml" "$DOCS_FILE"; then
    pass "teach-config.yml referenced in documentation"
else
    fail "teach-config.yml not referenced"
fi

# Check for learning_outcomes structure
if grep -q "learning_outcomes:" "$DOCS_FILE"; then
    pass "learning_outcomes structure documented"
else
    fail "learning_outcomes structure not documented"
fi

# Check for assessments structure
if grep -q "assessments:" "$DOCS_FILE"; then
    pass "assessments structure documented"
else
    fail "assessments structure not documented"
fi

# Check for course_structure
if grep -q "course_structure:" "$DOCS_FILE"; then
    pass "course_structure documented"
else
    fail "course_structure not documented"
fi

# ============================================================================
# SECTION 8: Research Citation Tests
# ============================================================================
section "8. Research Citation Tests"

# Check for research citations
if grep -q "Research Citations\|References" "$DOCS_FILE"; then
    pass "Research citations section referenced"
else
    fail "Research citations section not found"
fi

# Check for Harvard-style citations
HARVARD_CITATIONS=$(grep -cE '\([0-9]{4}\)\.' "$DOCS_FILE" 2>/dev/null || echo 0)
if [[ $HARVARD_CITATIONS -ge 5 ]]; then
    pass "Harvard-style citations present ($HARVARD_CITATIONS found)"
else
    fail "Need more Harvard-style citations (found $HARVARD_CITATIONS, expected >=5)"
fi

# ============================================================================
# SECTION 9: Command Documentation Tests
# ============================================================================
section "9. Command Documentation Tests"

# Check for teach command documentation
TEACH_CMDS=$(grep -cE 'teach [a-z]+' "$DOCS_FILE" 2>/dev/null || echo 0)
if [[ $TEACH_CMDS -ge 30 ]]; then
    pass "teach commands documented ($TEACH_CMDS occurrences)"
else
    fail "Need more teach command documentation (found $TEACH_CMDS, expected >=30)"
fi

# Check for specific commands
declare -A COMMANDS=(
    ["teach doctor"]="doctor"
    ["teach status"]="status"
    ["teach init"]="init"
    ["teach backup"]="backup"
    ["teach deploy"]="deploy"
    ["teach lecture"]="lecture"
    ["teach assignment"]="assignment"
    ["teach exam"]="exam"
    ["teach rubric"]="rubric"
    ["teach plan"]="plan"
)

for cmd_pattern in "${(@k)COMMANDS}"; do
    if grep -qE "$cmd_pattern" "$DOCS_FILE"; then
        pass "${COMMANDS[$cmd_pattern]} command documented"
    else
        fail "${COMMANDS[$cmd_pattern]} command not found in docs"
    fi
done

# ============================================================================
# SECTION 10: Flow-cli Integration Tests
# ============================================================================
section "10. flow-cli Integration Tests"

# Check for flow-cli references
if grep -q "flow-cli" "$DOCS_FILE"; then
    pass "flow-cli referenced in documentation"
else
    fail "flow-cli not referenced"
fi

# Check for .flow directory
if grep -q "\.flow/" "$DOCS_FILE"; then
    pass ".flow directory referenced"
else
    fail ".flow directory not referenced"
fi

# Check for lib/ references
if grep -q "lib/" "$DOCS_FILE"; then
    pass "lib/ directory referenced"
else
    fail "lib/ directory not referenced"
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
    echo -e "${GREEN}✅ All unit tests passed!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some tests failed. Please review.${NC}"
    exit 1
fi
