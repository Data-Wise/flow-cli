#!/usr/bin/env zsh
# tests/test-course-planning-commands-unit.zsh
# Unit tests for Course Planning command documentation

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

echo "========================================="
echo "  Course Planning Commands - Unit Tests"
echo "========================================="
echo ""

# ============================================================================
# SECTION 1: Teach Command Overview Tests
# ============================================================================
section "1. Teach Command Overview Tests"

subsection "1.1 Main teach command documented"
if grep -q "^## [0-9].*teach\|### teach " "$DOCS_FILE"; then
    pass "Teach command section exists"
else
    fail "Teach command section not found"
fi

if grep -qE "teach help|teach status|teach doctor" "$DOCS_FILE"; then
    pass "Basic teach commands documented"
else
    fail "Basic teach commands not documented"
fi

# ============================================================================
# SECTION 2: Teach Init Command Tests
# ============================================================================
section "2. Teach Init Command Tests"

subsection "2.1 Command existence"
if grep -qE "teach init" "$DOCS_FILE"; then
    pass "teach init documented"
else
    fail "teach init not documented"
fi

subsection "2.2 Command syntax"
if grep -qE "teach init.*--course|teach init.*--semester" "$DOCS_FILE"; then
    pass "teach init flags documented"
else
    fail "teach init flags not documented"
fi

if grep -qE "teach init.*--config|teach init.*--github" "$DOCS_FILE"; then
    pass "teach init advanced flags documented"
else
    fail "teach init advanced flags not documented"
fi

subsection "2.3 Examples"
if grep -qE "teach init.*STAT 545|teach init.*\"Course Name\"" "$DOCS_FILE"; then
    pass "teach init examples provided"
else
    fail "teach init examples missing"
fi

# ============================================================================
# SECTION 3: Teach Doctor Command Tests
# ============================================================================
section "3. Teach Doctor Command Tests"

subsection "3.1 Command documentation"
if grep -qE "teach doctor" "$DOCS_FILE"; then
    pass "teach doctor documented"
else
    fail "teach doctor not documented"
fi

subsection "3.2 Flags"
for flag in "--json" "--quiet" "--fix" "--check" "--verbose"; do
    if grep -qE "teach doctor.*$flag" "$DOCS_FILE"; then
        pass "teach doctor $flag documented"
    else
        fail "teach doctor $flag not found"
    fi
done

subsection "3.3 Checks documented"
if grep -qE "teach doctor.*dependencies|teach doctor.*config" "$DOCS_FILE"; then
    pass "teach doctor check types documented"
else
    fail "teach doctor check types not documented"
fi

# ============================================================================
# SECTION 4: Teach Status Command Tests
# ============================================================================
section "4. Teach Status Command Tests"

if grep -qE "teach status" "$DOCS_FILE"; then
    pass "teach status documented"
else
    fail "teach status not documented"
fi

if grep -qE "teach status.*--verbose|teach status.*--json" "$DOCS_FILE"; then
    pass "teach status flags documented"
else
    fail "teach status flags not documented"
fi

# ============================================================================
# SECTION 5: Teach Backup Command Tests
# ============================================================================
section "5. Teach Backup Command Tests"

subsection "5.1 Command documentation"
if grep -qE "teach backup" "$DOCS_FILE"; then
    pass "teach backup documented"
else
    fail "teach backup not documented"
fi

subsection "5.2 Subcommands"
for subcmd in "create" "list" "restore" "delete" "archive"; do
    if grep -qE "teach backup.*$subcmd" "$DOCS_FILE"; then
        pass "teach backup $subcmd documented"
    else
        fail "teach backup $subcmd not found"
    fi
done

subsection "5.3 Options documented"
if grep -qE "teach backup.*--type|teach backup.*--tag" "$DOCS_FILE"; then
    pass "teach backup options documented"
else
    fail "teach backup options not documented"
fi

# ============================================================================
# SECTION 6: Teach Deploy Command Tests
# ============================================================================
section "6. Teach Deploy Command Tests"

if grep -qE "teach deploy" "$DOCS_FILE"; then
    pass "teach deploy documented"
else
    fail "teach deploy not documented"
fi

if grep -qE "teach deploy.*--branch|teach deploy.*--preview" "$DOCS_FILE"; then
    pass "teach deploy flags documented"
else
    fail "teach deploy flags not documented"
fi

if grep -qE "teach deploy.*--create-pr|teach deploy.*--tag" "$DOCS_FILE"; then
    pass "teach deploy advanced options documented"
else
    fail "teach deploy advanced options not documented"
fi

# ============================================================================
# SECTION 7: Teach Lecture Command Tests
# ============================================================================
section "7. Teach Lecture Command Tests"

if grep -qE "teach lecture" "$DOCS_FILE"; then
    pass "teach lecture documented"
else
    fail "teach lecture not documented"
fi

subsection "7.1 Options"
for opt in "--week" "--outcomes" "--template" "--length" "--style" "--include-code"; do
    if grep -qE "teach lecture.*$opt" "$DOCS_FILE"; then
        pass "teach lecture $opt documented"
    else
        fail "teach lecture $opt not found"
    fi
done

subsection "7.2 Templates"
for tmpl in "quarto" "markdown" "beamer" "pptx"; do
    if grep -qE "teach lecture.*$tmpl" "$DOCS_FILE"; then
        pass "teach lecture $tmpl template documented"
    else
        fail "teach lecture $tmpl template not found"
    fi
done

# ============================================================================
# SECTION 8: Teach Assignment Command Tests
# ============================================================================
section "8. Teach Assignment Command Tests"

if grep -qE "teach assignment" "$DOCS_FILE"; then
    pass "teach assignment documented"
else
    fail "teach assignment not documented"
fi

subsection "8.1 Options"
for opt in "--outcomes" "--level" "--points" "--problems" "--template" "--include-rubric" "--include-solutions"; do
    if grep -qE "teach assignment.*$opt" "$DOCS_FILE"; then
        pass "teach assignment $opt documented"
    else
        fail "teach assignment $opt not found"
    fi
done

subsection "8.2 Level values"
for level in "I" "R" "M" "Introduced" "Reinforced" "Mastery"; do
    if grep -qE "teach assignment.*$level" "$DOCS_FILE"; then
        pass "teach assignment level $level documented"
    else
        fail "teach assignment level $level not found"
    fi
done

# ============================================================================
# SECTION 9: Teach Exam Command Tests
# ============================================================================
section "9. Teach Exam Command Tests"

if grep -qE "teach exam" "$DOCS_FILE"; then
    pass "teach exam documented"
else
    fail "teach exam not documented"
fi

subsection "9.1 Options"
for opt in "--scope" "--outcomes" "--duration" "--points" "--format" "--question-types" "--bloom-distribution" "--include-answer-key"; do
    if grep -qE "teach exam.*$opt" "$DOCS_FILE"; then
        pass "teach exam $opt documented"
    else
        fail "teach exam $opt not found"
    fi
done

subsection "9.2 Question types"
for qt in "mcq" "short" "problem" "multiple-choice"; do
    if grep -qE "teach exam.*$qt" "$DOCS_FILE"; then
        pass "teach exam question type $qt documented"
    else
        fail "teach exam question type $qt not found"
    fi
done

# ============================================================================
# SECTION 10: Teach Rubric Command Tests
# ============================================================================
section "10. Teach Rubric Command Tests"

if grep -qE "teach rubric" "$DOCS_FILE"; then
    pass "teach rubric documented"
else
    fail "teach rubric not documented"
fi

for opt in "--outcomes" "--dimensions" "--levels" "--points" "--type"; do
    if grep -qE "teach rubric.*$opt" "$DOCS_FILE"; then
        pass "teach rubric $opt documented"
    else
        fail "teach rubric $opt not found"
    fi
done

# ============================================================================
# SECTION 11: Teach Plan Command Tests
# ============================================================================
section "11. Teach Plan Command Tests"

if grep -qE "teach plan" "$DOCS_FILE"; then
    pass "teach plan documented"
else
    fail "teach plan not documented"
fi

subsection "11.1 Subcommands"
for subcmd in "week" "generate" "validate" "--interactive"; do
    if grep -qE "teach plan.*$subcmd" "$DOCS_FILE"; then
        pass "teach plan $subcmd documented"
    else
        fail "teach plan $subcmd not found"
    fi
done

# ============================================================================
# SECTION 12: Teach Quiz Command Tests
# ============================================================================
section "12. Teach Quiz Command Tests"

if grep -qE "teach quiz" "$DOCS_FILE"; then
    pass "teach quiz documented"
else
    fail "teach quiz not documented"
fi

for opt in "--outcomes" "--questions" "--time" "--format"; do
    if grep -qE "teach quiz.*$opt" "$DOCS_FILE"; then
        pass "teach quiz $opt documented"
    else
        fail "teach quiz $opt not found"
    fi
done

# ============================================================================
# SECTION 13: Teach Lab Command Tests
# ============================================================================
section "13. Teach Lab Command Tests"

if grep -qE "teach lab" "$DOCS_FILE"; then
    pass "teach lab documented"
else
    fail "teach lab not documented"
fi

for opt in "--outcomes" "--activities" "--data" "--template"; do
    if grep -qE "teach lab.*$opt" "$DOCS_FILE"; then
        pass "teach lab $opt documented"
    else
        fail "teach lab $opt not found"
    fi
done

# ============================================================================
# SECTION 14: Additional Teach Commands Tests
# ============================================================================
section "14. Additional Teach Commands"

# Teach sync/scholar commands
if grep -qE "teach sync" "$DOCS_FILE"; then
    pass "teach sync documented"
else
    fail "teach sync not documented"
fi

# Teach grades command
if grep -qE "teach grades" "$DOCS_FILE"; then
    pass "teach grades documented"
else
    fail "teach grades not documented"
fi

for opt in "calculate" "distribution" "report" "audit"; do
    if grep -qE "teach grades.*$opt" "$DOCS_FILE"; then
        pass "teach grades $opt documented"
    else
        fail "teach grades $opt not found"
    fi
done

# Teach alignment command
if grep -qE "teach alignment" "$DOCS_FILE"; then
    pass "teach alignment documented"
else
    fail "teach alignment not documented"
fi

for opt in "matrix" "validate" "check"; do
    if grep -qE "teach alignment.*$opt" "$DOCS_FILE"; then
        pass "teach alignment $opt documented"
    else
        fail "teach alignment $opt not found"
    fi
done

# ============================================================================
# SECTION 15: Help System Tests
# ============================================================================
section "15. Help System Tests"

if grep -qE "teach help" "$DOCS_FILE"; then
    pass "teach help documented"
else
    fail "teach help not documented"
fi

if grep -qE "--help\|-h" "$DOCS_FILE"; then
    pass "Help flags documented"
else
    fail "Help flags not documented"
fi

# ============================================================================
# SECTION 16: Command Syntax Validation Tests
# ============================================================================
section "16. Command Syntax Validation"

subsection "16.1 Code block format"
# Check that command examples use proper code blocks
BASH_EXAMPLES=$(grep -c '```bash' "$DOCS_FILE" 2>/dev/null || echo 0)
if [[ $BASH_EXAMPLES -ge 15 ]]; then
    pass "Sufficient bash examples ($BASH_EXAMPLES blocks)"
else
    fail "Need more bash examples (found $BASH_EXAMPLES, expected >=15)"
fi

subsection "16.2 Command completion"
# Verify commands end with proper punctuation in examples
INCOMPLETE_CMDS=$(grep -E "teach [a-z]+$" "$DOCS_FILE" | wc -l)
if [[ $INCOMPLETE_CMDS -lt 5 ]]; then
    pass "Most commands have complete examples"
else
    fail "Found $INCOMPLETE_CMDS potentially incomplete command examples"
fi

# ============================================================================
# SECTION 17: Integration Command Tests
# ============================================================================
section "17. Integration Command Tests"

subsection "17.1 Git integration"
if grep -qE "git checkout|git branch|git status" "$DOCS_FILE"; then
    pass "Git integration documented"
else
    fail "Git integration not documented"
fi

subsection "17.2 GitHub integration"
if grep -qE "gh pr create|gh repo" "$DOCS_FILE"; then
    pass "GitHub CLI integration documented"
else
    fail "GitHub CLI integration not documented"
fi

subsection "17.3 Deployment integration"
if grep -qE "GitHub Pages|deploy.*branch" "$DOCS_FILE"; then
    pass "Deployment integration documented"
else
    fail "Deployment integration not documented"
fi

# ============================================================================
# SECTION 18: Workflow Command Tests
# ============================================================================
section "18. Workflow Command Tests"

subsection "18.1 Weekly workflow"
if grep -qE "teach status.*weekly|teach backup.*weekly" "$DOCS_FILE"; then
    pass "Weekly workflow documented"
else
    fail "Weekly workflow not clearly documented"
fi

subsection "18.2 Semester workflow"
if grep -qE "teach doctor.*--comprehensive|teach backup.*archive" "$DOCS_FILE"; then
    pass "Semester workflow documented"
else
    fail "Semester workflow not clearly documented"
fi

subsection "18.3 Quality workflow"
if grep -qE "teach validate|teach doctor" "$DOCS_FILE"; then
    pass "Quality workflow documented"
else
    fail "Quality workflow not documented"
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
    echo -e "${GREEN}✅ All command unit tests passed!${NC}"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Some tests failed. Please review.${NC}"
    exit 1
fi
