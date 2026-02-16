#!/usr/bin/env zsh
# tests/test-course-planning-commands-unit.zsh
# Unit tests for Course Planning command documentation

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

test_suite_start "Course Planning Commands - Unit Tests"

# ============================================================================
# SECTION 1: Teach Command Overview Tests
# ============================================================================
section "1. Teach Command Overview Tests"

subsection "1.1 Main teach command documented"
test_case "Teach command section exists"
if grep -q "^## [0-9].*teach\|### teach " "$DOCS_FILE"; then
    test_pass
else
    test_fail "Teach command section not found"
fi

test_case "Basic teach commands documented"
if grep -qE "teach help|teach status|teach doctor" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Basic teach commands not documented"
fi

# ============================================================================
# SECTION 2: Teach Init Command Tests
# ============================================================================
section "2. Teach Init Command Tests"

subsection "2.1 Command existence"
test_case "teach init documented"
if grep -qE "teach init" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach init not documented"
fi

subsection "2.2 Command syntax"
test_case "teach init flags documented"
if grep -qE "teach init.*--course|teach init.*--semester" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach init flags not documented"
fi

test_case "teach init advanced flags documented"
if grep -qE "teach init.*--config|teach init.*--github" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach init advanced flags not documented"
fi

subsection "2.3 Examples"
test_case "teach init examples provided"
if grep -qE 'teach init.*STAT 545|teach init.*"Course Name"' "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach init examples missing"
fi

# ============================================================================
# SECTION 3: Teach Doctor Command Tests
# ============================================================================
section "3. Teach Doctor Command Tests"

subsection "3.1 Command documentation"
test_case "teach doctor documented"
if grep -qE "teach doctor" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach doctor not documented"
fi

subsection "3.2 Flags"
for flag in "--json" "--quiet" "--fix" "--check" "--verbose"; do
    test_case "teach doctor $flag documented"
    if grep -qE "teach doctor.*$flag" "$DOCS_FILE"; then
        test_pass
    else
        test_fail "teach doctor $flag not found"
    fi
done

subsection "3.3 Checks documented"
test_case "teach doctor check types documented"
if grep -qE "teach doctor.*dependencies|teach doctor.*config" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach doctor check types not documented"
fi

# ============================================================================
# SECTION 4: Teach Status Command Tests
# ============================================================================
section "4. Teach Status Command Tests"

test_case "teach status documented"
if grep -qE "teach status" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach status not documented"
fi

test_case "teach status flags documented"
if grep -qE "teach status.*--verbose|teach status.*--json" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach status flags not documented"
fi

# ============================================================================
# SECTION 5: Teach Backup Command Tests
# ============================================================================
section "5. Teach Backup Command Tests"

subsection "5.1 Command documentation"
test_case "teach backup documented"
if grep -qE "teach backup" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach backup not documented"
fi

subsection "5.2 Subcommands"
for subcmd in "create" "list" "restore" "delete" "archive"; do
    test_case "teach backup $subcmd documented"
    if grep -qE "teach backup.*$subcmd" "$DOCS_FILE"; then
        test_pass
    else
        test_fail "teach backup $subcmd not found"
    fi
done

subsection "5.3 Options documented"
test_case "teach backup options documented"
if grep -qE "teach backup.*--type|teach backup.*--tag" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach backup options not documented"
fi

# ============================================================================
# SECTION 6: Teach Deploy Command Tests
# ============================================================================
section "6. Teach Deploy Command Tests"

test_case "teach deploy documented"
if grep -qE "teach deploy" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach deploy not documented"
fi

test_case "teach deploy flags documented"
if grep -qE "teach deploy.*--branch|teach deploy.*--preview" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach deploy flags not documented"
fi

test_case "teach deploy advanced options documented"
if grep -qE "teach deploy.*--create-pr|teach deploy.*--tag" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach deploy advanced options not documented"
fi

# ============================================================================
# SECTION 7: Teach Lecture Command Tests
# ============================================================================
section "7. Teach Lecture Command Tests"

test_case "teach lecture documented"
if grep -qE "teach lecture" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach lecture not documented"
fi

subsection "7.1 Options"
for opt in "--week" "--outcomes" "--template" "--length" "--style" "--include-code"; do
    test_case "teach lecture $opt documented"
    if grep -qE "teach lecture.*$opt" "$DOCS_FILE"; then
        test_pass
    else
        test_fail "teach lecture $opt not found"
    fi
done

subsection "7.2 Templates"
for tmpl in "quarto" "markdown" "beamer" "pptx"; do
    test_case "teach lecture $tmpl template documented"
    if grep -qE "teach lecture.*$tmpl" "$DOCS_FILE"; then
        test_pass
    else
        test_fail "teach lecture $tmpl template not found"
    fi
done

# ============================================================================
# SECTION 8: Teach Assignment Command Tests
# ============================================================================
section "8. Teach Assignment Command Tests"

test_case "teach assignment documented"
if grep -qE "teach assignment" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach assignment not documented"
fi

subsection "8.1 Options"
for opt in "--outcomes" "--level" "--points" "--problems" "--template" "--include-rubric" "--include-solutions"; do
    test_case "teach assignment $opt documented"
    if grep -qE "teach assignment.*$opt" "$DOCS_FILE"; then
        test_pass
    else
        test_fail "teach assignment $opt not found"
    fi
done

subsection "8.2 Level values"
for level in "I" "R" "M" "Introduced" "Reinforced" "Mastery"; do
    test_case "teach assignment level $level documented"
    if grep -qE "teach assignment.*$level" "$DOCS_FILE"; then
        test_pass
    else
        test_fail "teach assignment level $level not found"
    fi
done

# ============================================================================
# SECTION 9: Teach Exam Command Tests
# ============================================================================
section "9. Teach Exam Command Tests"

test_case "teach exam documented"
if grep -qE "teach exam" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach exam not documented"
fi

subsection "9.1 Options"
for opt in "--scope" "--outcomes" "--duration" "--points" "--format" "--question-types" "--bloom-distribution" "--include-answer-key"; do
    test_case "teach exam $opt documented"
    if grep -qE "teach exam.*$opt" "$DOCS_FILE"; then
        test_pass
    else
        test_fail "teach exam $opt not found"
    fi
done

subsection "9.2 Question types"
for qt in "mcq" "short" "problem" "multiple-choice"; do
    test_case "teach exam question type $qt documented"
    if grep -qE "teach exam.*$qt" "$DOCS_FILE"; then
        test_pass
    else
        test_fail "teach exam question type $qt not found"
    fi
done

# ============================================================================
# SECTION 10: Teach Rubric Command Tests
# ============================================================================
section "10. Teach Rubric Command Tests"

test_case "teach rubric documented"
if grep -qE "teach rubric" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach rubric not documented"
fi

for opt in "--outcomes" "--dimensions" "--levels" "--points" "--type"; do
    test_case "teach rubric $opt documented"
    if grep -qE "teach rubric.*$opt" "$DOCS_FILE"; then
        test_pass
    else
        test_fail "teach rubric $opt not found"
    fi
done

# ============================================================================
# SECTION 11: Teach Plan Command Tests
# ============================================================================
section "11. Teach Plan Command Tests"

test_case "teach plan documented"
if grep -qE "teach plan" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach plan not documented"
fi

subsection "11.1 Subcommands"
for subcmd in "week" "generate" "validate" "--interactive"; do
    test_case "teach plan $subcmd documented"
    if grep -qE "teach plan.*$subcmd" "$DOCS_FILE"; then
        test_pass
    else
        test_fail "teach plan $subcmd not found"
    fi
done

# ============================================================================
# SECTION 12: Teach Quiz Command Tests
# ============================================================================
section "12. Teach Quiz Command Tests"

test_case "teach quiz documented"
if grep -qE "teach quiz" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach quiz not documented"
fi

for opt in "--outcomes" "--questions" "--time" "--format"; do
    test_case "teach quiz $opt documented"
    if grep -qE "teach quiz.*$opt" "$DOCS_FILE"; then
        test_pass
    else
        test_fail "teach quiz $opt not found"
    fi
done

# ============================================================================
# SECTION 13: Teach Lab Command Tests
# ============================================================================
section "13. Teach Lab Command Tests"

test_case "teach lab documented"
if grep -qE "teach lab" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach lab not documented"
fi

for opt in "--outcomes" "--activities" "--data" "--template"; do
    test_case "teach lab $opt documented"
    if grep -qE "teach lab.*$opt" "$DOCS_FILE"; then
        test_pass
    else
        test_fail "teach lab $opt not found"
    fi
done

# ============================================================================
# SECTION 14: Additional Teach Commands Tests
# ============================================================================
section "14. Additional Teach Commands"

# Teach sync/scholar commands
test_case "teach sync documented"
if grep -qE "teach sync" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach sync not documented"
fi

# Teach grades command
test_case "teach grades documented"
if grep -qE "teach grades" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach grades not documented"
fi

for opt in "calculate" "distribution" "report" "audit"; do
    test_case "teach grades $opt documented"
    if grep -qE "teach grades.*$opt" "$DOCS_FILE"; then
        test_pass
    else
        test_fail "teach grades $opt not found"
    fi
done

# Teach alignment command
test_case "teach alignment documented"
if grep -qE "teach alignment" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach alignment not documented"
fi

for opt in "matrix" "validate" "check"; do
    test_case "teach alignment $opt documented"
    if grep -qE "teach alignment.*$opt" "$DOCS_FILE"; then
        test_pass
    else
        test_fail "teach alignment $opt not found"
    fi
done

# ============================================================================
# SECTION 15: Help System Tests
# ============================================================================
section "15. Help System Tests"

test_case "teach help documented"
if grep -qE "teach help" "$DOCS_FILE"; then
    test_pass
else
    test_fail "teach help not documented"
fi

test_case "Help flags documented"
if grep -qE "--help\|-h" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Help flags not documented"
fi

# ============================================================================
# SECTION 16: Command Syntax Validation Tests
# ============================================================================
section "16. Command Syntax Validation"

subsection "16.1 Code block format"
BASH_EXAMPLES=$(grep -c '```bash' "$DOCS_FILE" 2>/dev/null || echo 0)
test_case "Sufficient bash examples ($BASH_EXAMPLES blocks)"
if [[ $BASH_EXAMPLES -ge 15 ]]; then
    test_pass
else
    test_fail "Need more bash examples (found $BASH_EXAMPLES, expected >=15)"
fi

subsection "16.2 Command completion"
INCOMPLETE_CMDS=$(grep -E "teach [a-z]+$" "$DOCS_FILE" | wc -l)
test_case "Most commands have complete examples"
if [[ $INCOMPLETE_CMDS -lt 5 ]]; then
    test_pass
else
    test_fail "Found $INCOMPLETE_CMDS potentially incomplete command examples"
fi

# ============================================================================
# SECTION 17: Integration Command Tests
# ============================================================================
section "17. Integration Command Tests"

subsection "17.1 Git integration"
test_case "Git integration documented"
if grep -qE "git checkout|git branch|git status" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Git integration not documented"
fi

subsection "17.2 GitHub integration"
test_case "GitHub CLI integration documented"
if grep -qE "gh pr create|gh repo" "$DOCS_FILE"; then
    test_pass
else
    test_fail "GitHub CLI integration not documented"
fi

subsection "17.3 Deployment integration"
test_case "Deployment integration documented"
if grep -qE "GitHub Pages|deploy.*branch" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Deployment integration not documented"
fi

# ============================================================================
# SECTION 18: Workflow Command Tests
# ============================================================================
section "18. Workflow Command Tests"

subsection "18.1 Weekly workflow"
test_case "Weekly workflow documented"
if grep -qE "teach status.*weekly|teach backup.*weekly" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Weekly workflow not clearly documented"
fi

subsection "18.2 Semester workflow"
test_case "Semester workflow documented"
if grep -qE "teach doctor.*--comprehensive|teach backup.*archive" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Semester workflow not clearly documented"
fi

subsection "18.3 Quality workflow"
test_case "Quality workflow documented"
if grep -qE "teach validate|teach doctor" "$DOCS_FILE"; then
    test_pass
else
    test_fail "Quality workflow not documented"
fi

test_suite_end
exit $?
