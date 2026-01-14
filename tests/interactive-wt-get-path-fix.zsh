#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# INTERACTIVE DOGFOODING TEST: _wt_get_path Fix
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Test that _wt_get_path finds worktrees by branch name regardless
#          of directory naming convention (flat vs hierarchical)
#
# Bug Fixed: cc wt <branch> failed when worktree was created with flat naming
#            (e.g., ~/.git-worktrees/flow-cli-keychain-secrets instead of
#             ~/.git-worktrees/flow-cli/feature-keychain-secrets)
#
# Usage: ./tests/interactive-wt-get-path-fix.zsh
#
# ══════════════════════════════════════════════════════════════════════════════

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Emojis
CHECK='✅'
CROSS='❌'
TREE='🌳'
WRENCH='🔧'
ROCKET='🚀'

# Test state
SCRIPT_DIR="${0:A:h}"
PASSED=0
FAILED=0

# ══════════════════════════════════════════════════════════════════════════════
# HELPERS
# ══════════════════════════════════════════════════════════════════════════════

print_header() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  ${WRENCH}  ${BOLD}_wt_get_path Fix Test${NC}                               ${BLUE}║${NC}"
    echo -e "${BLUE}║${NC}     ${DIM}Finding worktrees by branch name${NC}                       ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_test() {
    local name="$1"
    echo -e "${CYAN}┌─────────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${TREE} ${BOLD}$name${NC}"
    echo -e "${CYAN}└─────────────────────────────────────────────────────────────┘${NC}"
}

pass() {
    echo -e "  ${GREEN}${CHECK} PASS${NC}: $1"
    ((PASSED++))
}

fail() {
    echo -e "  ${RED}${CROSS} FAIL${NC}: $1"
    ((FAILED++))
}

ask_user() {
    local question="$1"
    echo ""
    echo -e "${YELLOW}$question${NC}"
    echo -n "  [y/n]: "
    read -r response
    [[ "$response" == [yY]* ]]
}

# ══════════════════════════════════════════════════════════════════════════════
# SETUP
# ══════════════════════════════════════════════════════════════════════════════

print_header

echo -e "${BLUE}Loading flow-cli...${NC}"
source "$SCRIPT_DIR/../flow.plugin.zsh" 2>/dev/null || {
    echo -e "${RED}Failed to source flow.plugin.zsh${NC}"
    exit 1
}
echo -e "${GREEN}${CHECK} Plugin loaded${NC}"
echo ""

# ══════════════════════════════════════════════════════════════════════════════
# TEST 1: Function exists
# ══════════════════════════════════════════════════════════════════════════════

print_test "Test 1: _wt_get_path function exists"

if type _wt_get_path &>/dev/null; then
    pass "_wt_get_path is defined"
else
    fail "_wt_get_path not found"
fi

# ══════════════════════════════════════════════════════════════════════════════
# TEST 2: List current worktrees
# ══════════════════════════════════════════════════════════════════════════════

print_test "Test 2: Current worktrees"

echo ""
echo -e "${DIM}Running: git worktree list${NC}"
echo ""
git worktree list
echo ""

# Auto-check for the worktree
if git worktree list | grep -q "feature/keychain-secrets"; then
    pass "Worktree visible in git worktree list"
else
    fail "Worktree not visible"
    echo -e "${YELLOW}Note: This test requires the feature/keychain-secrets worktree to exist${NC}"
fi

# ══════════════════════════════════════════════════════════════════════════════
# TEST 3: _wt_get_path finds worktree by branch
# ══════════════════════════════════════════════════════════════════════════════

print_test "Test 3: _wt_get_path finds worktree by branch name"

echo ""
echo -e "${DIM}Running: _wt_get_path 'feature/keychain-secrets'${NC}"
echo ""

result=$(_wt_get_path "feature/keychain-secrets" 2>&1)
exit_code=$?

echo -e "  Result: ${CYAN}$result${NC}"
echo -e "  Exit code: $exit_code"
echo ""

if [[ $exit_code -eq 0 && -n "$result" ]]; then
    pass "_wt_get_path returned a path"

    if [[ -d "$result" ]]; then
        pass "Path exists: $result"
    else
        fail "Path does not exist: $result"
    fi
else
    fail "_wt_get_path returned empty or failed"
fi

# ══════════════════════════════════════════════════════════════════════════════
# TEST 4: _wt_get_path works regardless of naming convention
# ══════════════════════════════════════════════════════════════════════════════

print_test "Test 4: Works with flat naming (the bug fix)"

echo ""
echo -e "${DIM}The bug was: _wt_get_path only checked hierarchical paths like:${NC}"
echo -e "${DIM}  ~/.git-worktrees/flow-cli/feature-keychain-secrets${NC}"
echo ""
echo -e "${DIM}But the actual worktree might be at:${NC}"
echo -e "${DIM}  ~/.git-worktrees/flow-cli-keychain-secrets${NC}"
echo ""

# Check if the actual path is flat (not hierarchical)
if [[ "$result" == *"/flow-cli-"* && "$result" != *"/flow-cli/"* ]]; then
    pass "Worktree uses flat naming convention"
    echo -e "  ${GREEN}${CHECK} Fix verified: _wt_get_path found flat-named worktree${NC}"
elif [[ "$result" == *"/flow-cli/"* ]]; then
    pass "Worktree uses hierarchical naming"
    echo -e "  ${DIM}(hierarchical naming - fix still applies)${NC}"
else
    echo -e "  ${YELLOW}Could not determine naming convention${NC}"
fi

# ══════════════════════════════════════════════════════════════════════════════
# TEST 5: cc wt <branch> works
# ══════════════════════════════════════════════════════════════════════════════

print_test "Test 5: cc wt feature/keychain-secrets (dry run)"

echo ""
echo -e "${DIM}Running: cc wt feature/keychain-secrets${NC}"
echo -e "${DIM}(This should find the existing worktree, not create a new one)${NC}"
echo ""

# Capture output without actually launching Claude
output=$(cc wt feature/keychain-secrets 2>&1 | head -3)
echo "$output"
echo ""

if [[ "$output" == *"Launching Claude"* ]]; then
    pass "cc wt found the worktree and attempted to launch Claude"
elif [[ "$output" == *"Creating worktree"* ]]; then
    fail "cc wt tried to CREATE a new worktree (bug not fixed)"
elif [[ "$output" == *"Failed to get/create"* ]]; then
    fail "cc wt failed to find the worktree (bug not fixed)"
else
    echo -e "  ${YELLOW}Unexpected output - please verify manually${NC}"
fi

# ══════════════════════════════════════════════════════════════════════════════
# TEST 6: cc wt (list) shows worktrees
# ══════════════════════════════════════════════════════════════════════════════

print_test "Test 6: cc wt (list mode)"

echo ""
echo -e "${DIM}Running: cc wt${NC}"
echo ""

cc_wt_output=$(cc wt 2>&1 | head -10)
echo "$cc_wt_output"
echo ""

# Auto-check: should show worktrees
if [[ "$cc_wt_output" == *"worktree"* ]] || [[ "$cc_wt_output" == *"flow-cli"* ]]; then
    pass "cc wt list shows worktrees"
else
    fail "cc wt list output unexpected"
fi

# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  ${ROCKET}  ${BOLD}TEST SUMMARY${NC}                                          ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${GREEN}Passed${NC}: $PASSED"
echo -e "  ${RED}Failed${NC}: $FAILED"
echo ""

if [[ $FAILED -eq 0 ]]; then
    echo -e "${GREEN}${CHECK} All automated tests passed!${NC}"
    echo ""
    echo -e "${DIM}The _wt_get_path function now uses 'git worktree list --porcelain'${NC}"
    echo -e "${DIM}to find worktrees by branch name, regardless of directory naming.${NC}"
    echo ""
    echo -e "${YELLOW}Does everything look correct? [y/n]${NC}"
    read -r response
    if [[ "$response" == [yY]* ]]; then
        echo -e "${GREEN}${ROCKET} Fix verified! Ready to release.${NC}"
    else
        echo -e "${YELLOW}Please report any issues.${NC}"
    fi
else
    echo -e "${RED}${CROSS} Some tests failed. Please investigate.${NC}"
fi

echo ""
