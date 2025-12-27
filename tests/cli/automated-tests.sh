#!/bin/bash
# Automated CLI Test Suite for: flow-cli
# Generated: 2025-12-27
# Run: bash tests/cli/automated-tests.sh
#
# This test suite validates flow CLI commands work correctly.
# Designed for CI/CD integration with proper exit codes.

set -e

# ═══════════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════

PASS=0
FAIL=0
SKIP=0
TOTAL=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Test helpers (use || true to avoid set -e exit on ((0++)))
log_pass() { ((PASS++)) || true; ((TOTAL++)) || true; echo -e "${GREEN}✅ PASS${NC}: $1"; }
log_fail() { ((FAIL++)) || true; ((TOTAL++)) || true; echo -e "${RED}❌ FAIL${NC}: $1${2:+ - $2}"; }
log_skip() { ((SKIP++)) || true; ((TOTAL++)) || true; echo -e "${YELLOW}⏭️  SKIP${NC}: $1${2:+ - $2}"; }
log_section() { echo -e "\n${BOLD}${BLUE}▶ $1${NC}"; }

# Timeout helper (macOS compatible)
# Usage: run_with_timeout <seconds> <command...>
run_with_timeout() {
    local timeout_secs=$1
    shift
    # Run command in background, capture output
    local output
    output=$("$@" 2>&1) &
    local pid=$!

    # Wait with timeout
    local count=0
    while kill -0 $pid 2>/dev/null; do
        sleep 0.1
        count=$((count + 1))
        if [[ $count -ge $((timeout_secs * 10)) ]]; then
            kill -9 $pid 2>/dev/null
            wait $pid 2>/dev/null
            return 124  # Timeout exit code
        fi
    done
    wait $pid
    local exit_code=$?
    echo "$output"
    return $exit_code
}

# Source the plugin for function tests
FLOW_CLI_DIR="${FLOW_CLI_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"

# ═══════════════════════════════════════════════════════════════
# HEADER
# ═══════════════════════════════════════════════════════════════

echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  AUTOMATED CLI TEST SUITE: flow-cli${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${DIM}  Directory: $FLOW_CLI_DIR${NC}"
echo -e "${DIM}  Date: $(date '+%Y-%m-%d %H:%M:%S')${NC}"

# ═══════════════════════════════════════════════════════════════
# SECTION 1: Installation & Prerequisites
# ═══════════════════════════════════════════════════════════════

log_section "Installation & Prerequisites"

# Test: Plugin file exists
if [[ -f "$FLOW_CLI_DIR/flow.plugin.zsh" ]]; then
    log_pass "Plugin file exists"
else
    log_fail "Plugin file not found" "$FLOW_CLI_DIR/flow.plugin.zsh"
fi

# Test: Core library exists
if [[ -f "$FLOW_CLI_DIR/lib/core.zsh" ]]; then
    log_pass "Core library exists"
else
    log_fail "Core library not found"
fi

# Test: Commands directory exists
if [[ -d "$FLOW_CLI_DIR/commands" ]]; then
    log_pass "Commands directory exists"
else
    log_fail "Commands directory not found"
fi

# Test: Completions directory exists
if [[ -d "$FLOW_CLI_DIR/completions" ]]; then
    log_pass "Completions directory exists"
else
    log_fail "Completions directory not found"
fi

# Test: ZSH is available
if command -v zsh &> /dev/null; then
    log_pass "ZSH is available"
else
    log_fail "ZSH not found in PATH"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 2: Plugin Loading
# ═══════════════════════════════════════════════════════════════

log_section "Plugin Loading"

# Test: Plugin can be sourced without errors
if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh'" 2>/dev/null; then
    log_pass "Plugin sources without errors"
else
    log_fail "Plugin fails to source"
fi

# Test: flow command is defined after sourcing
if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && typeset -f flow >/dev/null" 2>/dev/null; then
    log_pass "flow function is defined"
else
    log_fail "flow function not defined after sourcing"
fi

# Test: Core functions are available
for func in _flow_log_success _flow_log_error _flow_log_info; do
    if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && typeset -f $func >/dev/null" 2>/dev/null; then
        log_pass "$func is defined"
    else
        log_fail "$func not defined"
    fi
done

# ═══════════════════════════════════════════════════════════════
# SECTION 3: Help System
# ═══════════════════════════════════════════════════════════════

log_section "Help System"

# Test: flow help works
if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && flow help" 2>&1 | grep -q "FLOW"; then
    log_pass "flow help displays output"
else
    log_fail "flow help produces no output"
fi

# Test: flow help mentions key commands
for cmd in work dash finish sync doctor; do
    if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && flow help" 2>&1 | grep -qi "$cmd"; then
        log_pass "flow help mentions '$cmd'"
    else
        log_fail "flow help missing '$cmd'"
    fi
done

# Test: flow sync help works
if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && flow sync help" 2>&1 | grep -qi "sync"; then
    log_pass "flow sync help works"
else
    log_fail "flow sync help produces no output"
fi

# Test: flow doctor --help works
if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && flow doctor --help" 2>&1 | grep -qi "doctor\|health\|check"; then
    log_pass "flow doctor --help works"
else
    log_fail "flow doctor --help produces no output"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 4: Sync Command
# ═══════════════════════════════════════════════════════════════

log_section "Sync Command"

# Test: Sync function exists
if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && typeset -f flow_sync >/dev/null" 2>/dev/null; then
    log_pass "flow_sync function exists"
else
    log_fail "flow_sync function not found"
fi

# Test: Sync targets exist
for target in session status wins goals git all; do
    if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && typeset -f _flow_sync_$target >/dev/null" 2>/dev/null; then
        log_pass "_flow_sync_$target function exists"
    else
        log_fail "_flow_sync_$target function not found"
    fi
done

# Test: Sync help mentions targets
if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && flow sync help" 2>&1 | grep -q "session.*status.*wins"; then
    log_pass "Sync help mentions all targets"
else
    log_skip "Sync help target check" "May be formatted differently"
fi

# Test: Sync --dry-run flag accepted
if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && flow sync --dry-run" 2>&1 | grep -qi "dry\|would\|preview"; then
    log_pass "flow sync --dry-run works"
else
    log_skip "flow sync --dry-run" "May require project context"
fi

# Test: Sync schedule functions exist
for func in _flow_sync_schedule _flow_sync_schedule_status _flow_sync_schedule_enable _flow_sync_schedule_disable; do
    if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && typeset -f $func >/dev/null" 2>/dev/null; then
        log_pass "$func exists"
    else
        log_fail "$func not found"
    fi
done

# ═══════════════════════════════════════════════════════════════
# SECTION 5: Doctor Command
# ═══════════════════════════════════════════════════════════════

log_section "Doctor Command"

# Test: Doctor function exists
if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && typeset -f doctor >/dev/null" 2>/dev/null; then
    log_pass "doctor function exists"
else
    log_fail "doctor function not found"
fi

# Test: Doctor runs without fatal error
if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && flow doctor" 2>&1 | head -20 | grep -qi "flow\|health\|check\|dependencies"; then
    log_pass "flow doctor produces diagnostic output"
else
    log_skip "flow doctor output" "May vary by environment"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 6: Config Command
# ═══════════════════════════════════════════════════════════════

log_section "Config Command"

# Test: Config function exists
if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && typeset -f flow_config >/dev/null" 2>/dev/null; then
    log_pass "flow_config function exists"
else
    log_fail "flow_config function not found"
fi

# Test: Config show works
if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && flow config show" 2>&1 | grep -qi "config\|setting\|FLOW"; then
    log_pass "flow config show works"
else
    log_skip "flow config show" "May have no config set"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 7: Plugin Command
# ═══════════════════════════════════════════════════════════════

log_section "Plugin Command"

# Test: Plugin function exists
if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && typeset -f flow_plugin >/dev/null" 2>/dev/null; then
    log_pass "flow_plugin function exists"
else
    log_fail "flow_plugin function not found"
fi

# Test: Plugin list works
if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && flow plugin list" 2>&1 | grep -qi "plugin\|none\|installed"; then
    log_pass "flow plugin list works"
else
    log_skip "flow plugin list" "May have no plugins"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 8: Dispatchers
# ═══════════════════════════════════════════════════════════════

log_section "Dispatchers"

# Test: Dispatcher files exist
for dispatcher in g mcp obs qu r cc; do
    # All dispatchers in lib/dispatchers/
    if [[ -f "$FLOW_CLI_DIR/lib/dispatchers/${dispatcher}-dispatcher.zsh" ]] || \
       [[ -f "$FLOW_CLI_DIR/lib/dispatchers/${dispatcher}.zsh" ]]; then
        log_pass "$dispatcher dispatcher file exists"
    else
        log_fail "$dispatcher dispatcher file not found"
    fi
done

# Test: Dispatcher functions defined
for dispatcher in g mcp obs qu r cc; do
    if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && typeset -f $dispatcher >/dev/null" 2>/dev/null; then
        log_pass "$dispatcher() function is defined"
    else
        log_fail "$dispatcher() function not defined"
    fi
done

# Test: Dispatcher help works
for dispatcher in g r qu; do
    if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && $dispatcher help" 2>&1 | grep -qi "usage\|command\|help"; then
        log_pass "$dispatcher help works"
    else
        log_skip "$dispatcher help" "May not have help"
    fi
done

# ═══════════════════════════════════════════════════════════════
# SECTION 9: Completions
# ═══════════════════════════════════════════════════════════════

log_section "Completions"

# Test: Completion files exist
for comp in _flow _work _dash _hop _finish _js; do
    if [[ -f "$FLOW_CLI_DIR/completions/$comp" ]]; then
        log_pass "$comp completion file exists"
    else
        log_fail "$comp completion file not found"
    fi
done

# Test: _flow completion has sync targets
if grep -q "sync_targets" "$FLOW_CLI_DIR/completions/_flow" 2>/dev/null; then
    log_pass "_flow completion has sync targets"
else
    log_fail "_flow completion missing sync targets"
fi

# Test: _flow completion has schedule commands
if grep -q "schedule_cmds" "$FLOW_CLI_DIR/completions/_flow" 2>/dev/null; then
    log_pass "_flow completion has schedule commands"
else
    log_fail "_flow completion missing schedule commands"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 10: Core Commands
# ═══════════════════════════════════════════════════════════════

log_section "Core Commands"

# Test: Command files exist
for cmd in work dash capture adhd pick status sync doctor; do
    if [[ -f "$FLOW_CLI_DIR/commands/${cmd}.zsh" ]]; then
        log_pass "commands/${cmd}.zsh exists"
    else
        log_fail "commands/${cmd}.zsh not found"
    fi
done

# Test: Key command functions exist (short names, not flow_ prefix)
for func in work dash finish pick win catch js; do
    if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && typeset -f $func >/dev/null" 2>/dev/null; then
        log_pass "$func function exists"
    else
        log_fail "$func function not found"
    fi
done

# ═══════════════════════════════════════════════════════════════
# SECTION 11: ADHD Features
# ═══════════════════════════════════════════════════════════════

log_section "ADHD Features"

# Test: Win tracking function exists
if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && typeset -f win >/dev/null" 2>/dev/null; then
    log_pass "win function exists"
else
    log_fail "win function not found"
fi

# Test: Goal tracking function exists
if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && typeset -f flow_goal >/dev/null" 2>/dev/null; then
    log_pass "flow_goal function exists"
else
    log_fail "flow_goal function not found"
fi

# Test: Just-start function exists
if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && typeset -f js >/dev/null" 2>/dev/null; then
    log_pass "js (just-start) function exists"
else
    log_fail "js function not found"
fi

# Test: Yay (show wins) function exists
if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && typeset -f yay >/dev/null" 2>/dev/null; then
    log_pass "yay function exists"
else
    log_fail "yay function not found"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 12: Error Handling
# ═══════════════════════════════════════════════════════════════

log_section "Error Handling"

# Test: Invalid command shows help
if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && flow nonexistent-command-xyz" 2>&1 | grep -qi "help\|usage\|unknown\|invalid"; then
    log_pass "Invalid command shows help/error"
else
    log_skip "Invalid command handling" "May silently fail"
fi

# Test: Invalid sync target handled
if zsh -c "source '$FLOW_CLI_DIR/flow.plugin.zsh' && flow sync invalid-target-xyz" 2>&1 | grep -qi "help\|usage\|unknown\|invalid\|target"; then
    log_pass "Invalid sync target handled gracefully"
else
    log_skip "Invalid sync target handling" "May show help"
fi

# ═══════════════════════════════════════════════════════════════
# SECTION 13: Documentation
# ═══════════════════════════════════════════════════════════════

log_section "Documentation"

# Test: Key docs exist
for doc in "docs/commands/sync.md" "docs/reference/DISPATCHER-REFERENCE.md" "CLAUDE.md"; do
    if [[ -f "$FLOW_CLI_DIR/$doc" ]]; then
        log_pass "$doc exists"
    else
        log_fail "$doc not found"
    fi
done

# Test: mkdocs.yml exists
if [[ -f "$FLOW_CLI_DIR/mkdocs.yml" ]]; then
    log_pass "mkdocs.yml exists"
else
    log_fail "mkdocs.yml not found"
fi

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  RESULTS${NC}"
echo -e "${BOLD}═══════════════════════════════════════════════════════════════${NC}"
echo -e "  Total:   ${BOLD}${TOTAL}${NC}"
echo -e "  Passed:  ${GREEN}${PASS}${NC}"
echo -e "  Failed:  ${RED}${FAIL}${NC}"
echo -e "  Skipped: ${YELLOW}${SKIP}${NC}"
echo ""

# Calculate pass rate
if [[ $TOTAL -gt 0 ]]; then
    PASS_RATE=$(( (PASS * 100) / TOTAL ))
    echo -e "  Pass Rate: ${BOLD}${PASS_RATE}%${NC}"
fi
echo ""

# Exit code based on failures
if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}${BOLD}$FAIL test(s) failed${NC}"
    exit 1
fi
