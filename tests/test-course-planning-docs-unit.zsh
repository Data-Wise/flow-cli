#!/usr/bin/env zsh
# tests/test-course-planning-docs-unit.zsh
# Unit tests for Course Planning Best Practices documentation (Phases 2-4)

# Test setup
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/test-framework.zsh"

DOCS_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)/docs/guides"
DOCS_FILE="$DOCS_DIR/COURSE-PLANNING-BEST-PRACTICES.md"

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

# Check if docs file exists
if [[ ! -f "$DOCS_FILE" ]]; then
    echo "${RED}ERROR: Documentation file not found: $DOCS_FILE${RESET}"
    exit 1
fi

test_suite_start "Course Planning Docs - Unit Tests"

echo "Target: $DOCS_FILE"

# ============================================================================
# SECTION 1: Document Structure Tests
# ============================================================================
section "1. Document Structure Tests"

subsection "1.1 File existence and size"
test_case "Documentation file exists"
if [[ -f "$DOCS_FILE" ]]; then
    test_pass
else
    test_fail "Documentation file not found"
fi

LINE_COUNT=$(wc -l < "$DOCS_FILE")
test_case "File has substantial content ($LINE_COUNT lines)"
if [[ $LINE_COUNT -gt 5000 ]]; then
    test_pass
else
    test_fail "File seems too short ($LINE_COUNT lines, expected >5000)"
fi

subsection "1.2 Version and metadata"
test_case "Version metadata present"
if grep -q "**Version:**" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Version metadata missing"
fi

test_case "Status metadata present"
if grep -q "**Status:**" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Status metadata missing"
fi

subsection "1.3 Table of Contents structure"
test_case "Table of Contents section exists"
if grep -q "## Table of Contents" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Table of Contents section missing"
fi

# Check for all 4 phases in TOC
for phase in "Phase 1" "Phase 2" "Phase 3" "Phase 4"; do
    test_case "Phase reference found: $phase"
    if grep -q "$phase" "$DOCS_FILE"; then
        test_pass
    else
        test_fail "Missing phase reference: $phase"
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
    test_case "Section $section_num exists: $section_name"
    if grep -q "^## $section_name" "$DOCS_FILE"; then
        test_pass
    else
        test_fail "Section $section_num missing: $section_name"
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
    test_case "Subsection ${SUBSECTIONS[$subsection_name]} exists: $subsection_name"
    if grep -q "^### $subsection_name" "$DOCS_FILE"; then
        test_pass
    else
        test_fail "Subsection ${SUBSECTIONS[$subsection_name]} missing: $subsection_name"
    fi
done

# ============================================================================
# SECTION 4: Cross-Reference Tests
# ============================================================================
section "4. Cross-Reference Tests"

# Check for internal links (Markdown anchors)
ANCHOR_COUNT=$(grep -oE '\]\(#[^)]+\)' "$DOCS_FILE" | wc -l)
test_case "Sufficient internal links ($ANCHOR_COUNT anchors)"
if [[ $ANCHOR_COUNT -gt 50 ]]; then
    test_pass
else
    test_fail "Too few internal links (found $ANCHOR_COUNT, expected >50)"
fi

# Check for "See Also" sections
SEE_ALSO_COUNT=$(grep -c "## See Also\|### See Also\|**See Also**" "$DOCS_FILE" 2>/dev/null || echo 0)
test_case "Cross-reference sections present ($SEE_ALSO_COUNT found)"
if [[ $SEE_ALSO_COUNT -gt 5 ]]; then
    test_pass
else
    test_fail "Cross-reference sections sparse (found $SEE_ALSO_COUNT)"
fi

# ============================================================================
# SECTION 5: Code Example Structure Tests
# ============================================================================
section "5. Code Example Structure Tests"

# Count YAML code blocks
YAML_BLOCKS=$(grep -c '```yaml' "$DOCS_FILE" 2>/dev/null || echo 0)
test_case "Sufficient YAML examples ($YAML_BLOCKS blocks)"
if [[ $YAML_BLOCKS -ge 50 ]]; then
    test_pass
else
    test_fail "Need more YAML examples (found $YAML_BLOCKS, expected >=50)"
fi

# Count bash/zsh code blocks
BASH_BLOCKS=$(grep -c '```bash\|```zsh' "$DOCS_FILE" 2>/dev/null || echo 0)
test_case "Sufficient bash examples ($BASH_BLOCKS blocks)"
if [[ $BASH_BLOCKS -ge 20 ]]; then
    test_pass
else
    test_fail "Need more bash examples (found $BASH_BLOCKS, expected >=20)"
fi

# Count R code blocks
R_BLOCKS=$(grep -c '```r\|```R' "$DOCS_FILE" 2>/dev/null || echo 0)
test_case "Sufficient R examples ($R_BLOCKS blocks)"
if [[ $R_BLOCKS -ge 10 ]]; then
    test_pass
else
    test_fail "Need more R examples (found $R_BLOCKS, expected >=10)"
fi

# Count mermaid diagrams
MERMAID_BLOCKS=$(grep -c '```mermaid' "$DOCS_FILE" 2>/dev/null || echo 0)
test_case "Mermaid diagrams present ($MERMAID_BLOCKS found)"
if [[ $MERMAID_BLOCKS -ge 3 ]]; then
    test_pass
else
    test_fail "Need more mermaid diagrams (found $MERMAID_BLOCKS, expected >=3)"
fi

# ============================================================================
# SECTION 6: STAT 545 Example Tests
# ============================================================================
section "6. STAT 545 Example Tests"

# Check for STAT 545 references
STAT545_REFS=$(grep -c "STAT 545\|STAT545" "$DOCS_FILE" 2>/dev/null || echo 0)
test_case "STAT 545 examples well-represented ($STAT545_REFS references)"
if [[ $STAT545_REFS -ge 50 ]]; then
    test_pass
else
    test_fail "Need more STAT 545 examples (found $STAT545_REFS, expected >=50)"
fi

# Check for specific STAT 545 outcomes example
test_case "STAT 545 learning outcomes documented"
if grep -q "LO1.*Visualize\|LO2.*Build Models\|LO3.*Communicate" "$DOCS_FILE"; then
    test_pass
else
    test_fail "STAT 545 learning outcomes not clearly documented"
fi

# Check for STAT 545 assessment plan
test_case "STAT 545 assessment weights documented"
if grep -q "Homework.*30%\|Midterm.*20%\|Project.*30%\|Final.*20%" "$DOCS_FILE"; then
    test_pass
else
    test_fail "STAT 545 assessment weights not clearly documented"
fi

# ============================================================================
# SECTION 7: teach-config.yml Example Tests
# ============================================================================
section "7. teach-config.yml Example Tests"

test_case "teach-config.yml referenced in documentation"
if grep -q "teach-config.yml" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach-config.yml not referenced"
fi

test_case "learning_outcomes structure documented"
if grep -q "learning_outcomes:" "$DOCS_FILE"; then
    test_pass
else
    test_fail "learning_outcomes structure not documented"
fi

test_case "assessments structure documented"
if grep -q "assessments:" "$DOCS_FILE"; then
    test_pass
else
    test_fail "assessments structure not documented"
fi

test_case "course_structure documented"
if grep -q "course_structure:" "$DOCS_FILE"; then
    test_pass
else
    test_fail "course_structure not documented"
fi

# ============================================================================
# SECTION 8: Research Citation Tests
# ============================================================================
section "8. Research Citation Tests"

test_case "Research citations section referenced"
if grep -q "Research Citations\|References" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Research citations section not found"
fi

# Check for Harvard-style citations
HARVARD_CITATIONS=$(grep -cE '\([0-9]{4}\)\.' "$DOCS_FILE" 2>/dev/null || echo 0)
test_case "Harvard-style citations present ($HARVARD_CITATIONS found)"
if [[ $HARVARD_CITATIONS -ge 5 ]]; then
    test_pass
else
    test_fail "Need more Harvard-style citations (found $HARVARD_CITATIONS, expected >=5)"
fi

# ============================================================================
# SECTION 9: Command Documentation Tests
# ============================================================================
section "9. Command Documentation Tests"

# Check for teach command documentation
TEACH_CMDS=$(grep -cE 'teach [a-z]+' "$DOCS_FILE" 2>/dev/null || echo 0)
test_case "teach commands documented ($TEACH_CMDS occurrences)"
if [[ $TEACH_CMDS -ge 30 ]]; then
    test_pass
else
    test_fail "Need more teach command documentation (found $TEACH_CMDS, expected >=30)"
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
    test_case "${COMMANDS[$cmd_pattern]} command documented"
    if grep -qE "$cmd_pattern" "$DOCS_FILE"; then
        test_pass
    else
        test_fail "${COMMANDS[$cmd_pattern]} command not found in docs"
    fi
done

# ============================================================================
# SECTION 10: Flow-cli Integration Tests
# ============================================================================
section "10. flow-cli Integration Tests"

test_case "flow-cli referenced in documentation"
if grep -q "flow-cli" "$DOCS_FILE"; then
    test_pass
else
    test_fail "flow-cli not referenced"
fi

test_case ".flow directory referenced"
if grep -q "\.flow/" "$DOCS_FILE"; then
    test_pass
else
    test_fail ".flow directory not referenced"
fi

test_case "lib/ directory referenced"
if grep -q "lib/" "$DOCS_FILE"; then
    test_pass
else
    test_fail "lib/ directory not referenced"
fi

test_suite_end
exit $?
