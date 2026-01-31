#!/usr/bin/env zsh
# interactive-dog-lint.zsh - Dogfooding test for teach validate --lint
# Interactive manual testing checklist for real-world usage
#
# Run with: zsh tests/interactive-dog-lint.zsh

SCRIPT_DIR="${0:A:h}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Source plugin
source "${SCRIPT_DIR}/../flow.plugin.zsh"

# Task tracking
typeset -g TOTAL_TASKS=10
typeset -g COMPLETED_TASKS=0

print_header() {
    echo ""
    echo "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo "${BOLD}${CYAN}  teach validate --lint - Dogfooding Test${RESET}"
    echo "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    echo "This interactive test helps you manually verify the lint feature"
    echo "by using it on real course files."
    echo ""
}

print_task() {
    local num=$1
    local desc=$2
    echo "${YELLOW}[$num/$TOTAL_TASKS]${RESET} ${BOLD}$desc${RESET}"
}

wait_for_enter() {
    echo ""
    echo -n "${CYAN}Press Enter when done... ${RESET}"
    read
    ((COMPLETED_TASKS++))
    echo "${GREEN}✓ Task completed ($COMPLETED_TASKS/$TOTAL_TASKS)${RESET}"
    echo ""
}

check_stat545() {
    if [[ ! -d "$HOME/projects/teaching/stat-545" ]]; then
        echo "${RED}✗ STAT 545 project not found${RESET}"
        echo "This dogfooding test requires the stat-545 course site."
        echo "Location: ~/projects/teaching/stat-545"
        exit 1
    fi
}

print_header
check_stat545

STAT545="$HOME/projects/teaching/stat-545"

# ============================================================================
# Task 1: Basic lint run
# ============================================================================

print_task 1 "Run basic lint check on a single file"
echo ""
echo "Command to run:"
echo "${CYAN}  cd $STAT545"
echo "  teach validate --lint slides/week-02_crd-anova_slides.qmd${RESET}"
echo ""
echo "Expected: Should show lint warnings for the file"
echo "Look for: LINT_CODE_LANG_TAG, LINT_DIV_BALANCE, LINT_CALLOUT_VALID, LINT_HEADING_HIERARCHY"
wait_for_enter

# ============================================================================
# Task 2: Quick checks flag
# ============================================================================

print_task 2 "Test --quick-checks flag"
echo ""
echo "Command to run:"
echo "${CYAN}  cd $STAT545"
echo "  teach validate --quick-checks slides/week-02_crd-anova_slides.qmd${RESET}"
echo ""
echo "Expected: Should run only lint-shared validator"
echo "Look for: No warnings about lint-slides/lectures/labs not found"
wait_for_enter

# ============================================================================
# Task 3: Multiple files
# ============================================================================

print_task 3 "Lint multiple files at once"
echo ""
echo "Command to run:"
echo "${CYAN}  cd $STAT545"
echo "  teach validate --lint slides/week-02*.qmd${RESET}"
echo ""
echo "Expected: Should process all week-02 slide files"
echo "Look for: Each file listed with its lint results"
wait_for_enter

# ============================================================================
# Task 4: Auto-discovery
# ============================================================================

print_task 4 "Auto-discover files (no files specified)"
echo ""
echo "Command to run:"
echo "${CYAN}  cd $STAT545/slides"
echo "  teach validate --lint${RESET}"
echo ""
echo "Expected: Should find all .qmd files in slides/"
echo "Look for: Multiple files being processed"
wait_for_enter

# ============================================================================
# Task 5: Help text
# ============================================================================

print_task 5 "Verify help text includes lint flags"
echo ""
echo "Command to run:"
echo "${CYAN}  teach validate --help | grep -A2 lint${RESET}"
echo ""
echo "Expected: Should show --lint and --quick-checks flags"
echo "Look for: Clear descriptions of what each flag does"
wait_for_enter

# ============================================================================
# Task 6: Clean file (no errors)
# ============================================================================

print_task 6 "Test on a clean file with no lint errors"
echo ""
echo "Create a clean test file:"
echo "${CYAN}  cat > /tmp/clean-test.qmd <<'EOF'
---
title: \"Clean Test\"
---

# Section

## Subsection

\`\`\`{r}
x <- 1
\`\`\`
EOF"
echo "  teach validate --lint /tmp/clean-test.qmd${RESET}"
echo ""
echo "Expected: Should pass with no errors"
echo "Look for: Success message or no error output"
wait_for_enter

# ============================================================================
# Task 7: Intentional errors
# ============================================================================

print_task 7 "Test error detection with intentional issues"
echo ""
echo "Create a file with multiple errors:"
echo "${CYAN}  cat > /tmp/error-test.qmd <<'EOF'
---
title: \"Error Test\"
---

# Section

### Skipped h2

\`\`\`
bare code block
\`\`\`

::: {.callout-invalid}
Bad callout
:::

::: {.callout-note}
Unclosed div
EOF"
echo "  teach validate --lint /tmp/error-test.qmd${RESET}"
echo ""
echo "Expected: Should detect all 4 types of errors"
echo "Look for: LINT_HEADING_HIERARCHY, LINT_CODE_LANG_TAG, LINT_CALLOUT_VALID, LINT_DIV_BALANCE"
wait_for_enter

# ============================================================================
# Task 8: Integration with pre-commit hook
# ============================================================================

print_task 8 "Test pre-commit hook integration"
echo ""
echo "Command to run:"
echo "${CYAN}  cd $STAT545"
echo "  git add slides/week-02_crd-anova_slides.qmd"
echo "  bash .git/hooks/pre-commit | grep -A5 'lint check'${RESET}"
echo ""
echo "Expected: Should see lint checks running in pre-commit hook"
echo "Look for: 'Running Quarto lint checks...' message"
echo "Note: Hook is warn-only, won't block commit"
wait_for_enter

# ============================================================================
# Task 9: Performance check
# ============================================================================

print_task 9 "Check performance on multiple files"
echo ""
echo "Command to run:"
echo "${CYAN}  cd $STAT545"
echo "  time teach validate --lint lectures/*.qmd${RESET}"
echo ""
echo "Expected: Should complete in reasonable time (<5s for ~10 files)"
echo "Look for: Time output, should be sub-second per file"
wait_for_enter

# ============================================================================
# Task 10: Validator file deployment
# ============================================================================

print_task 10 "Verify validator deployed to stat-545"
echo ""
echo "Command to run:"
echo "${CYAN}  ls -la $STAT545/.teach/validators/lint-shared.zsh"
echo "  head -20 $STAT545/.teach/validators/lint-shared.zsh${RESET}"
echo ""
echo "Expected: File exists and shows correct validator metadata"
echo "Look for: VALIDATOR_NAME, VALIDATOR_VERSION, VALIDATOR_DESCRIPTION"
wait_for_enter

# ============================================================================
# Summary
# ============================================================================

echo ""
echo "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo "${BOLD}${GREEN}  Dogfooding Complete! 🎉${RESET}"
echo "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo "All $COMPLETED_TASKS/$TOTAL_TASKS tasks completed!"
echo ""
echo "${CYAN}Additional exploration ideas:${RESET}"
echo "  • Try lint on different content types (labs, lectures, appendix)"
echo "  • Test with large files (100+ lines)"
echo "  • Run lint before quarto preview to catch issues early"
echo "  • Integrate into your daily workflow"
echo ""
echo "${YELLOW}Feedback:${RESET}"
echo "  • Did the lint checks catch real issues?"
echo "  • Were the error messages helpful?"
echo "  • Any false positives?"
echo "  • Performance acceptable?"
echo ""
