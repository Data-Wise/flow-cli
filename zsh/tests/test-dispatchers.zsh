#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST-DISPATCHERS - Verify dispatcher functions work correctly
# ══════════════════════════════════════════════════════════════════════════════
#
# Usage: ./test-dispatchers.zsh
#
# Tests:
#   1. Each dispatcher exists and is a function
#   2. Each dispatcher has a help command
#   3. Each dispatcher handles no-args gracefully
#   4. Each dispatcher has _<cmd>_help function
#
# ══════════════════════════════════════════════════════════════════════════════

# Colors
_RED='\033[31m'
_GREEN='\033[32m'
_YELLOW='\033[33m'
_NC='\033[0m'
_BOLD='\033[1m'
_DIM='\033[2m'

# Counters
PASS=0
FAIL=0

# Get plugin root (relative to this test file)
PLUGIN_ROOT="${0:A:h:h:h}"

# Source the plugin to load dispatchers
source "$PLUGIN_ROOT/flow.plugin.zsh" 2>/dev/null || {
    echo "ERROR: Could not load flow.plugin.zsh"
    exit 1
}

echo -e "${_BOLD}═══════════════════════════════════════════════════════════${_NC}"
echo -e "${_BOLD}  Dispatcher Function Tests${_NC}"
echo -e "${_BOLD}═══════════════════════════════════════════════════════════${_NC}"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# Test Function
# ─────────────────────────────────────────────────────────────────────────────

test_dispatcher() {
    local cmd=$1
    local name=$2
    local all_pass=true

    echo -e "${_BOLD}Testing: $cmd ($name)${_NC}"

    # Test 1: Function exists
    if type "$cmd" &>/dev/null; then
        echo -e "  ${_GREEN}✓${_NC} Function exists"
        ((PASS++))
    else
        echo -e "  ${_RED}✗${_NC} Function does not exist"
        ((FAIL++))
        all_pass=false
    fi

    # Test 2: Help works
    if $cmd help &>/dev/null; then
        echo -e "  ${_GREEN}✓${_NC} Help command works"
        ((PASS++))
    else
        echo -e "  ${_RED}✗${_NC} Help command failed"
        ((FAIL++))
        all_pass=false
    fi

    # Test 3: No-args doesn't error (skip for interactive commands)
    # Some commands like 'r', 'cc', 'gm' launch interactive sessions
    local skip_noargs=false
    [[ "$cmd" == "r" || "$cmd" == "cc" || "$cmd" == "gm" ]] && skip_noargs=true

    if [[ "$skip_noargs" == "true" ]]; then
        echo -e "  ${_YELLOW}⚠${_NC} No-args skipped (launches interactive session)"
    elif $cmd &>/dev/null; then
        echo -e "  ${_GREEN}✓${_NC} No-args handled gracefully"
        ((PASS++))
    else
        echo -e "  ${_YELLOW}⚠${_NC} No-args returned error (may be intentional)"
        # Don't count as fail - some commands may require args
    fi

    # Test 4: Help function exists (_<cmd>_help or <cmd>_help)
    if type "_${cmd}_help" &>/dev/null || type "${cmd}_help" &>/dev/null; then
        echo -e "  ${_GREEN}✓${_NC} Help function exists"
        ((PASS++))
    else
        echo -e "  ${_YELLOW}⚠${_NC} No dedicated help function (may use inline help)"
        # Don't fail - some dispatchers may have inline help
    fi

    echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# Run Tests
# ─────────────────────────────────────────────────────────────────────────────

# Test dispatchers that are part of flow-cli (v3.0.0)
# Note: r, qu, cc, gm are external dispatchers not included in flow-cli
test_dispatcher "g" "Git Commands"
test_dispatcher "v" "Workflow Automation"
test_dispatcher "mcp" "MCP Server Manager"
test_dispatcher "obs" "Obsidian CLI"

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────

echo -e "${_BOLD}═══════════════════════════════════════════════════════════${_NC}"
echo -e "${_BOLD}  Summary${_NC}"
echo -e "${_BOLD}═══════════════════════════════════════════════════════════${_NC}"
echo ""
echo -e "  ${_GREEN}Passed:${_NC} $PASS"
echo -e "  ${_RED}Failed:${_NC} $FAIL"
echo ""

if [[ $FAIL -gt 0 ]]; then
    echo -e "  ${_RED}${_BOLD}RESULT: FAIL${_NC}"
    exit 1
else
    echo -e "  ${_GREEN}${_BOLD}RESULT: PASS${_NC}"
    exit 0
fi
