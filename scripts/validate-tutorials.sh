#!/bin/bash
#
# Tutorial Validation Script for flow-cli v2.0
#
# Purpose: Validate that all commands mentioned in tutorials actually exist
# Usage: ./scripts/validate-tutorials.sh
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Arrays to store results
declare -a FAILED_COMMANDS
declare -a MISSING_ALIASES
declare -a MISSING_FUNCTIONS
declare -a DEPRECATED_REFS

echo ""
echo "╭────────────────────────────────────────────────╮"
echo "│  📚 flow-cli Tutorial Validation Suite        │"
echo "│  Version 2.0.0-alpha.1                         │"
echo "╰────────────────────────────────────────────────╯"
echo ""

# ==============================================================================
# STEP 1: Check ZSH configuration files exist
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 Step 1: Checking ZSH Configuration Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

check_file() {
    local file=$1
    local description=$2
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}✗${NC} $description - NOT FOUND"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

check_file "$HOME/.config/zsh/.zshrc" "Main ZSH config"
check_file "$HOME/.config/zsh/functions/adhd-helpers.zsh" "ADHD helpers"
check_file "$HOME/.config/zsh/functions/smart-dispatchers.zsh" "Smart dispatchers"
check_file "$HOME/.config/zsh/functions/work.zsh" "Work command"

echo ""

# ==============================================================================
# STEP 2: Extract and validate aliases
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚡ Step 2: Validating R Package Aliases (23 expected)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Expected R package aliases (from 28-alias system)
R_ALIASES=(
    "rload"
    "rtest"
    "rdoc"
    "rcheck"
    "rbuild"
    "rinstall"
    "rcov"
    "rcovrep"
    "rdoccheck"
    "rspell"
    "rpkgdown"
    "rpkgpreview"
    "rcheckfast"
    "rcheckcran"
    "rcheckwin"
    "rcheckrhub"
    "rdeps"
    "rdepsupdate"
    "rbumppatch"
    "rbumpminor"
    "rbumpmajor"
    "rpkgtree"
    "rpkg"
)

for alias_name in "${R_ALIASES[@]}"; do
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if grep -q "^alias $alias_name=" "$HOME/.config/zsh/.zshrc" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $alias_name"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}✗${NC} $alias_name - NOT FOUND"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        MISSING_ALIASES+=("$alias_name")
    fi
done

echo ""

# ==============================================================================
# STEP 3: Validate Claude Code aliases
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 Step 3: Validating Claude Code Aliases (2 expected)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

CLAUDE_ALIASES=(
    "ccp"
    "ccr"
)

for alias_name in "${CLAUDE_ALIASES[@]}"; do
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if grep -q "^alias $alias_name=" "$HOME/.config/zsh/.zshrc" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $alias_name"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}✗${NC} $alias_name - NOT FOUND"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        MISSING_ALIASES+=("$alias_name")
    fi
done

echo ""

# ==============================================================================
# STEP 4: Validate focus timer aliases
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⏱️  Step 4: Validating Focus Timers (2 expected)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

TIMER_ALIASES=(
    "f25"
    "f50"
)

for alias_name in "${TIMER_ALIASES[@]}"; do
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if grep -q "^alias $alias_name=" "$HOME/.config/zsh/.zshrc" 2>/dev/null || \
       grep -q "^alias $alias_name=" "$HOME/.config/zsh/functions/adhd-helpers.zsh" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $alias_name"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}✗${NC} $alias_name - NOT FOUND"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        MISSING_ALIASES+=("$alias_name")
    fi
done

echo ""

# ==============================================================================
# STEP 5: Validate ADHD helper functions
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧠 Step 5: Validating ADHD Helper Functions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ADHD_FUNCTIONS=(
    "just-start"
    "why"
    "win"
    "focus"
    "morning"
    "dash"
    "work"
    "pick"
    "finish"
    "status"
    "what-next"
)

for func_name in "${ADHD_FUNCTIONS[@]}"; do
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    # Use fgrep (fixed string) instead of grep -E to avoid regex special chars in function names
    # Check all function files in ~/.config/zsh/functions/
    if grep -qF "${func_name}()" "$HOME/.config/zsh/functions/adhd-helpers.zsh" 2>/dev/null || \
       grep -qF "${func_name}()" "$HOME/.config/zsh/functions/smart-dispatchers.zsh" 2>/dev/null || \
       grep -qF "${func_name}()" "$HOME/.config/zsh/functions/work.zsh" 2>/dev/null || \
       grep -qF "${func_name}()" "$HOME/.config/zsh/functions/${func_name}.zsh" 2>/dev/null || \
       grep -qF "${func_name}()" "$HOME/.config/zsh/functions.zsh" 2>/dev/null || \
       grep -qF "function ${func_name}" "$HOME/.config/zsh/functions/adhd-helpers.zsh" 2>/dev/null || \
       grep -qF "function ${func_name}" "$HOME/.config/zsh/functions/smart-dispatchers.zsh" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $func_name()"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}✗${NC} $func_name() - NOT FOUND"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        MISSING_FUNCTIONS+=("$func_name")
    fi
done

echo ""

# ==============================================================================
# STEP 6: Check for deprecated commands in tutorials
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  Step 6: Checking for Deprecated Commands"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Deprecated commands that were removed in v2.0
DEPRECATED_COMMANDS=(
    "js"        # replaced by just-start
    "idk"       # replaced by just-start
    "stuck"     # replaced by just-start
    "t"         # replaced by rtest
    "lt"        # replaced by rload && rtest
    "dt"        # replaced by rdoc && rtest
    "qcommit"   # replaced by git commands
    "rpkgcommit" # replaced by git commands
    "worktimer" # removed
    "quickbreak" # removed
    "here"      # removed
    "next"      # replaced by what-next
    "endwork"   # removed
)

TUTORIAL_FILES=(
    "docs/user/WORKFLOW-TUTORIAL.md"
    "docs/user/WORKFLOWS-QUICK-WINS.md"
    "docs/user/ALIAS-REFERENCE-CARD.md"
    "docs/getting-started/quick-start.md"
    "README.md"
)

for deprecated_cmd in "${DEPRECATED_COMMANDS[@]}"; do
    found_in_files=()

    for tutorial_file in "${TUTORIAL_FILES[@]}"; do
        if [ -f "$tutorial_file" ]; then
            # Look for command in code blocks or as standalone references
            # Ignore strikethrough text (~~command~~) as these are intentionally showing deprecated commands
            if grep -qE "(\`${deprecated_cmd}\`|^${deprecated_cmd} |^${deprecated_cmd}$)" "$tutorial_file" 2>/dev/null && \
               ! grep -qF "~~\`${deprecated_cmd}\`~~" "$tutorial_file" 2>/dev/null && \
               ! grep -qF "~~${deprecated_cmd}~~" "$tutorial_file" 2>/dev/null; then
                found_in_files+=("$(basename "$tutorial_file")")
            fi
        fi
    done

    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    if [ ${#found_in_files[@]} -eq 0 ]; then
        echo -e "${GREEN}✓${NC} No references to deprecated '$deprecated_cmd'"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${YELLOW}⚠${NC} Found '$deprecated_cmd' in: ${found_in_files[*]}"
        WARNING_CHECKS=$((WARNING_CHECKS + 1))
        DEPRECATED_REFS+=("$deprecated_cmd in ${found_in_files[*]}")
    fi
done

echo ""

# ==============================================================================
# STEP 7: Validate tutorial files exist
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📄 Step 7: Checking Tutorial Files"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for tutorial_file in "${TUTORIAL_FILES[@]}"; do
    check_file "$tutorial_file" "$(basename "$tutorial_file")"
done

echo ""

# ==============================================================================
# STEP 8: Check for --help support
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "❓ Step 8: Validating --help Support"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

HELP_FUNCTIONS=(
    "just-start"
    "focus"
    "pick"
    "win"
    "why"
    "finish"
    "morning"
)

for func_name in "${HELP_FUNCTIONS[@]}"; do
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))

    # Check if function has --help handler (use -F for fixed string matching)
    if grep -F -A 20 "${func_name}()" "$HOME/.config/zsh/functions/adhd-helpers.zsh" 2>/dev/null | grep -q '\--help'; then
        echo -e "${GREEN}✓${NC} $func_name --help"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${YELLOW}⚠${NC} $func_name --help - NOT IMPLEMENTED"
        WARNING_CHECKS=$((WARNING_CHECKS + 1))
    fi
done

echo ""

# ==============================================================================
# FINAL SUMMARY
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 VALIDATION SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PASS_RATE=$(( (PASSED_CHECKS * 100) / TOTAL_CHECKS ))

echo -e "Total Checks:    ${CYAN}$TOTAL_CHECKS${NC}"
echo -e "Passed:          ${GREEN}$PASSED_CHECKS${NC} (${PASS_RATE}%)"
echo -e "Failed:          ${RED}$FAILED_CHECKS${NC}"
echo -e "Warnings:        ${YELLOW}$WARNING_CHECKS${NC}"
echo ""

# Show failures
if [ ${#MISSING_ALIASES[@]} -gt 0 ]; then
    echo -e "${RED}✗ Missing Aliases:${NC}"
    for alias_name in "${MISSING_ALIASES[@]}"; do
        echo "  - $alias_name"
    done
    echo ""
fi

if [ ${#MISSING_FUNCTIONS[@]} -gt 0 ]; then
    echo -e "${RED}✗ Missing Functions:${NC}"
    for func_name in "${MISSING_FUNCTIONS[@]}"; do
        echo "  - $func_name()"
    done
    echo ""
fi

if [ ${#DEPRECATED_REFS[@]} -gt 0 ]; then
    echo -e "${YELLOW}⚠ Deprecated References Found:${NC}"
    for ref in "${DEPRECATED_REFS[@]}"; do
        echo "  - $ref"
    done
    echo ""
fi

# Final verdict
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $FAILED_CHECKS -eq 0 ] && [ $WARNING_CHECKS -eq 0 ]; then
    echo -e "${GREEN}✓ ALL VALIDATIONS PASSED!${NC} 🎉"
    echo "  Tutorials are ready for v2.0.0-alpha.1 release"
    EXIT_CODE=0
elif [ $FAILED_CHECKS -eq 0 ]; then
    echo -e "${YELLOW}⚠ VALIDATION PASSED WITH WARNINGS${NC}"
    echo "  Consider addressing warnings before release"
    EXIT_CODE=0
else
    echo -e "${RED}✗ VALIDATION FAILED${NC}"
    echo "  Fix critical issues before release"
    EXIT_CODE=1
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Save results to file
RESULTS_FILE="docs/testing/TUTORIAL-VALIDATION-RESULTS.md"
mkdir -p "$(dirname "$RESULTS_FILE")"

cat > "$RESULTS_FILE" << EOF
# Tutorial Validation Results

**Date:** $(date '+%Y-%m-%d %H:%M:%S')
**Version:** flow-cli v2.0.0-alpha.1
**Script:** scripts/validate-tutorials.sh

---

## Summary

- **Total Checks:** $TOTAL_CHECKS
- **Passed:** $PASSED_CHECKS (${PASS_RATE}%)
- **Failed:** $FAILED_CHECKS
- **Warnings:** $WARNING_CHECKS

---

## Detailed Results

### ✅ Passed Checks
$PASSED_CHECKS checks passed successfully.

EOF

if [ ${#MISSING_ALIASES[@]} -gt 0 ]; then
    cat >> "$RESULTS_FILE" << EOF
### ❌ Missing Aliases
$(for alias_name in "${MISSING_ALIASES[@]}"; do echo "- \`$alias_name\`"; done)

EOF
fi

if [ ${#MISSING_FUNCTIONS[@]} -gt 0 ]; then
    cat >> "$RESULTS_FILE" << EOF
### ❌ Missing Functions
$(for func_name in "${MISSING_FUNCTIONS[@]}"; do echo "- \`$func_name()\`"; done)

EOF
fi

if [ ${#DEPRECATED_REFS[@]} -gt 0 ]; then
    cat >> "$RESULTS_FILE" << EOF
### ⚠️ Deprecated References
$(for ref in "${DEPRECATED_REFS[@]}"; do echo "- $ref"; done)

EOF
fi

cat >> "$RESULTS_FILE" << EOF
---

## Recommendations

EOF

if [ $FAILED_CHECKS -gt 0 ]; then
    cat >> "$RESULTS_FILE" << EOF
**CRITICAL:** Fix missing aliases/functions before release:
1. Add missing aliases to ~/.config/zsh/.zshrc
2. Implement missing functions in appropriate files
3. Re-run this validation script

EOF
fi

if [ ${#DEPRECATED_REFS[@]} -gt 0 ]; then
    cat >> "$RESULTS_FILE" << EOF
**WARNING:** Update tutorials to remove deprecated commands:
1. Replace deprecated commands with modern equivalents
2. Update examples to use 28-alias system
3. Re-run validation to confirm

EOF
fi

if [ $FAILED_CHECKS -eq 0 ] && [ $WARNING_CHECKS -eq 0 ]; then
    cat >> "$RESULTS_FILE" << EOF
**SUCCESS:** All validations passed! Tutorials are ready for alpha release.

Next steps:
1. Proceed to Phase 2 (Site & Link Quality)
2. Build documentation site with \`mkdocs build --strict\`
3. Continue with release process

EOF
fi

cat >> "$RESULTS_FILE" << EOF
---

**Validation Report Generated:** $(date)
EOF

echo -e "${CYAN}📄 Results saved to:${NC} $RESULTS_FILE"
echo ""

exit $EXIT_CODE
