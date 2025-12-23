#!/bin/bash
#
# flow-cli v2.0 Health Check Script
#
# Purpose: Validate installation after setup
# Usage: ./scripts/health-check.sh
#

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Counters
TOTAL_CHECKS=0
PASSED=0
FAILED=0
WARNINGS=0

echo ""
echo "╭────────────────────────────────────────────────╮"
echo "│  🏥 flow-cli v2.0 Health Check                │"
echo "│  Installation Validation                       │"
echo "╰────────────────────────────────────────────────╯"
echo ""

# ==============================================================================
# Helper Functions
# ==============================================================================

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    PASSED=$((PASSED + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    FAILED=$((FAILED + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    WARNINGS=$((WARNINGS + 1))
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
}

# ==============================================================================
# STEP 1: Check ZSH Configuration
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📁 Step 1: Checking ZSH Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if main config exists
if [ -f "$HOME/.config/zsh/.zshrc" ]; then
    check_pass "Main ZSH config exists (~/.config/zsh/.zshrc)"
else
    check_fail "Main ZSH config missing (~/.config/zsh/.zshrc)"
fi

# Check if adhd-helpers exists
if [ -f "$HOME/.config/zsh/functions/adhd-helpers.zsh" ]; then
    check_pass "ADHD helpers found"
else
    check_fail "ADHD helpers missing"
fi

# Check if current shell is ZSH
if [ -n "$ZSH_VERSION" ]; then
    check_pass "Running in ZSH shell"
else
    check_warn "Not running in ZSH (current: $SHELL)"
fi

echo ""

# ==============================================================================
# STEP 2: Check R Package Aliases (23 expected)
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📦 Step 2: Checking R Package Aliases (23 expected)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

R_ALIASES=(
    "rload" "rtest" "rdoc" "rcheck" "rbuild"
    "rinstall" "rcov" "rcovrep" "rdoccheck" "rspell"
    "rpkgdown" "rpkgpreview" "rcheckfast" "rcheckcran"
    "rcheckwin" "rcheckrhub" "rdeps" "rdepsupdate"
    "rbumppatch" "rbumpminor" "rbumpmajor" "rpkgtree" "rpkg"
)

r_alias_count=0
for alias_name in "${R_ALIASES[@]}"; do
    if alias "$alias_name" &>/dev/null 2>&1; then
        r_alias_count=$((r_alias_count + 1))
    fi
done

if [ $r_alias_count -eq 23 ]; then
    check_pass "All 23 R package aliases loaded"
else
    check_warn "Only $r_alias_count/23 R package aliases found"
fi

echo ""

# ==============================================================================
# STEP 3: Check ADHD Helper Functions
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🧠 Step 3: Checking ADHD Helper Functions"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

FUNCTIONS=(
    "just-start" "why" "win" "focus" "morning"
    "dash" "work" "pick" "finish" "status"
)

func_count=0
for func_name in "${FUNCTIONS[@]}"; do
    if type "$func_name" &>/dev/null 2>&1; then
        func_count=$((func_count + 1))
    fi
done

if [ $func_count -eq 10 ]; then
    check_pass "All 10 ADHD helper functions loaded"
elif [ $func_count -gt 7 ]; then
    check_warn "Only $func_count/10 ADHD helper functions found"
else
    check_fail "Only $func_count/10 ADHD helper functions found"
fi

echo ""

# ==============================================================================
# STEP 4: Check Help System
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "❓ Step 4: Checking Help System"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test just-start --help
if type just-start &>/dev/null 2>&1; then
    if just-start --help 2>&1 | grep -q "Usage:"; then
        check_pass "just-start --help works"
    else
        check_warn "just-start --help doesn't show usage"
    fi
else
    check_fail "just-start command not found"
fi

# Test focus --help
if type focus &>/dev/null 2>&1; then
    if focus --help 2>&1 | grep -q "Usage:"; then
        check_pass "focus --help works"
    else
        check_warn "focus --help doesn't show usage"
    fi
else
    check_fail "focus command not found"
fi

echo ""

# ==============================================================================
# STEP 5: Check Claude Code Aliases
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 Step 5: Checking Claude Code Aliases (2 expected)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

claude_count=0
if alias ccp &>/dev/null 2>&1; then
    claude_count=$((claude_count + 1))
fi
if alias ccr &>/dev/null 2>&1; then
    claude_count=$((claude_count + 1))
fi

if [ $claude_count -eq 2 ]; then
    check_pass "Both Claude Code aliases loaded (ccp, ccr)"
else
    check_warn "Only $claude_count/2 Claude Code aliases found"
fi

echo ""

# ==============================================================================
# STEP 6: Check Focus Timers
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⏱️  Step 6: Checking Focus Timers (2 expected)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

timer_count=0
if alias f25 &>/dev/null 2>&1 || type f25 &>/dev/null 2>&1; then
    timer_count=$((timer_count + 1))
fi
if alias f50 &>/dev/null 2>&1 || type f50 &>/dev/null 2>&1; then
    timer_count=$((timer_count + 1))
fi

if [ $timer_count -eq 2 ]; then
    check_pass "Both focus timers loaded (f25, f50)"
else
    check_warn "Only $timer_count/2 focus timers found"
fi

echo ""

# ==============================================================================
# STEP 7: Check Git Plugin
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌳 Step 7: Checking Git Plugin"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check for common git plugin aliases
git_alias_count=0
for git_alias in "gst" "ga" "gc" "gp" "gl"; do
    if alias "$git_alias" &>/dev/null 2>&1; then
        git_alias_count=$((git_alias_count + 1))
    fi
done

if [ $git_alias_count -ge 4 ]; then
    check_pass "Git plugin loaded (found $git_alias_count/5 common aliases)"
else
    check_warn "Git plugin may not be loaded (found $git_alias_count/5 aliases)"
fi

echo ""

# ==============================================================================
# STEP 8: Check Documentation
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📚 Step 8: Checking Documentation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

DOC_FILES=(
    "docs/user/WORKFLOWS-QUICK-WINS.md"
    "docs/user/ALIAS-REFERENCE-CARD.md"
    "docs/user/MIGRATION-v1-to-v2.md"
    "docs/getting-started/quick-start.md"
    "CHANGELOG.md"
)

doc_count=0
for doc_file in "${DOC_FILES[@]}"; do
    if [ -f "$doc_file" ]; then
        doc_count=$((doc_count + 1))
    fi
done

if [ $doc_count -eq 5 ]; then
    check_pass "All 5 key documentation files found"
else
    check_warn "Only $doc_count/5 documentation files found"
fi

echo ""

# ==============================================================================
# STEP 9: Check Validation Scripts
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Step 9: Checking Validation Scripts"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ -f "scripts/validate-tutorials.sh" ] && [ -x "scripts/validate-tutorials.sh" ]; then
    check_pass "Tutorial validation script found and executable"
else
    check_warn "Tutorial validation script missing or not executable"
fi

if [ -f "scripts/check-links.js" ]; then
    check_pass "Link checker script found"
else
    check_warn "Link checker script missing"
fi

echo ""

# ==============================================================================
# FINAL SUMMARY
# ==============================================================================

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 HEALTH CHECK SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PASS_RATE=$(( (PASSED * 100) / TOTAL_CHECKS ))

echo -e "Total Checks:    ${CYAN}$TOTAL_CHECKS${NC}"
echo -e "Passed:          ${GREEN}$PASSED${NC} (${PASS_RATE}%)"
echo -e "Failed:          ${RED}$FAILED${NC}"
echo -e "Warnings:        ${YELLOW}$WARNINGS${NC}"
echo ""

# Final verdict
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $FAILED -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ INSTALLATION HEALTHY!${NC} 🎉"
    echo "  flow-cli v2.0 is ready to use"
    echo ""
    echo "Next steps:"
    echo "  1. Read: docs/user/WORKFLOWS-QUICK-WINS.md"
    echo "  2. Try: just-start"
    echo "  3. Explore: ah (alias help)"
    EXIT_CODE=0
elif [ $FAILED -eq 0 ]; then
    echo -e "${YELLOW}⚠ INSTALLATION OK WITH WARNINGS${NC}"
    echo "  flow-cli is usable but some features may not work"
    echo ""
    echo "Review warnings above and check:"
    echo "  - ZSH configuration loaded properly"
    echo "  - All required files in place"
    EXIT_CODE=0
else
    echo -e "${RED}✗ INSTALLATION INCOMPLETE${NC}"
    echo "  Some critical components are missing"
    echo ""
    echo "Recommended actions:"
    echo "  1. Check ~/.config/zsh/.zshrc exists"
    echo "  2. Run: source ~/.config/zsh/.zshrc"
    echo "  3. Re-run: ./scripts/setup.sh"
    EXIT_CODE=1
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Print helpful commands
if [ $FAILED -eq 0 ]; then
    echo "📖 Quick Reference:"
    echo ""
    echo "  Get started:"
    echo "    just-start          # Auto-pick next project"
    echo "    dash                # View project dashboard"
    echo "    pick                # Pick project with fzf"
    echo ""
    echo "  Learn more:"
    echo "    ah                  # Alias help (categorized)"
    echo "    just-start --help   # Command help"
    echo "    bat docs/user/WORKFLOWS-QUICK-WINS.md"
    echo ""
    echo "  Documentation site:"
    echo "    https://data-wise.github.io/flow-cli"
    echo ""
fi

exit $EXIT_CODE
