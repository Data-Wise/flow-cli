#!/usr/bin/env bash
# Automated Test Suite for Teaching Workflow v3.0 Phase 1
# Generated: 2026-01-18
# Tests all 10 tasks from Wave 1, 2, and 3

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
PASS=0
FAIL=0
TOTAL=0

# Test results array
declare -a FAILED_TESTS=()

# Helper functions
pass() {
    ((PASS++))
    ((TOTAL++))
    echo -e "${GREEN}✓${NC} $1"
}

fail() {
    ((FAIL++))
    ((TOTAL++))
    FAILED_TESTS+=("$1")
    echo -e "${RED}✗${NC} $1"
    [[ -n "${2:-}" ]] && echo -e "  ${RED}Error: $2${NC}"
}

section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

echo ""
echo -e "${YELLOW}Teaching Workflow v3.0 - Automated Test Suite${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════${NC}"
echo ""

# ============================================================================
# WAVE 1 TESTS (Tasks 1-4)
# ============================================================================

section "WAVE 1: Foundation Tests"

# Task 1: teach-init deletion
if [[ -f "commands/teach-init.zsh" ]]; then
    fail "Task 1: commands/teach-init.zsh should be deleted"
else
    pass "Task 1: commands/teach-init.zsh deleted"
fi

# Task 2 & 4: teach doctor implementation
if [[ -f "lib/dispatchers/teach-doctor-impl.zsh" ]]; then
    pass "Task 2: teach-doctor-impl.zsh exists"

    # Check for key functions
    if grep -q "^_teach_doctor()" "lib/dispatchers/teach-doctor-impl.zsh"; then
        pass "Task 2: _teach_doctor() function exists"
    else
        fail "Task 2: _teach_doctor() function missing"
    fi

    # Check for --json support
    if grep -q "^_teach_doctor_json_output()" "lib/dispatchers/teach-doctor-impl.zsh"; then
        pass "Task 4: JSON output support exists"
    else
        fail "Task 4: JSON output support missing"
    fi

    # Check for check functions
    if grep -q "^_teach_doctor_check_dependencies()" "lib/dispatchers/teach-doctor-impl.zsh"; then
        pass "Task 2: Dependency checks implemented"
    else
        fail "Task 2: Dependency checks missing"
    fi
else
    fail "Task 2: teach-doctor-impl.zsh not found"
fi

# Task 3: Help system enhancement
if grep -q "EXAMPLES" "lib/dispatchers/teach-dispatcher.zsh"; then
    pass "Task 3: EXAMPLES sections added to help"
else
    fail "Task 3: EXAMPLES sections missing from help"
fi

# Check for help functions
for help_func in "_teach_status_help" "_teach_week_help" "_teach_scholar_help"; do
    if grep -q "^${help_func}()" "lib/dispatchers/teach-dispatcher.zsh"; then
        pass "Task 3: ${help_func} exists"
    else
        fail "Task 3: ${help_func} missing"
    fi
done

# ============================================================================
# WAVE 2 TESTS (Tasks 5-6)
# ============================================================================

section "WAVE 2: Backup System Tests"

# Task 5: Backup system
if [[ -f "lib/backup-helpers.zsh" ]]; then
    pass "Task 5: backup-helpers.zsh exists"

    # Check for key functions
    for func in "_teach_backup_content" "_teach_get_retention_policy" "_teach_list_backups" "_teach_count_backups"; do
        if grep -q "^${func}()" "lib/backup-helpers.zsh"; then
            pass "Task 5: ${func} exists"
        else
            fail "Task 5: ${func} missing"
        fi
    done

    # Task 6: Delete confirmation
    if grep -q "^_teach_confirm_delete()" "lib/backup-helpers.zsh"; then
        pass "Task 6: Delete confirmation implemented"
    else
        fail "Task 6: Delete confirmation missing"
    fi
else
    fail "Task 5: backup-helpers.zsh not found"
fi

# Check backup-helpers is sourced in flow.plugin.zsh
if grep -q "backup-helpers.zsh" "flow.plugin.zsh"; then
    pass "Task 5: backup-helpers.zsh sourced in flow.plugin.zsh"
else
    fail "Task 5: backup-helpers.zsh not sourced"
fi

# ============================================================================
# WAVE 3 TESTS (Tasks 7-10)
# ============================================================================

section "WAVE 3: Enhancement Tests"

# Task 7: Enhanced teach status
if grep -q "Deployment Status" "lib/dispatchers/teach-dispatcher.zsh"; then
    pass "Task 7: Deployment Status section added"
else
    fail "Task 7: Deployment Status section missing"
fi

if grep -q "Backup Summary" "lib/dispatchers/teach-dispatcher.zsh"; then
    pass "Task 7: Backup Summary section added"
else
    fail "Task 7: Backup Summary section missing"
fi

# Task 8: Deploy preview
if grep -q "Changes Preview" "lib/dispatchers/teach-dispatcher.zsh"; then
    pass "Task 8: Deploy preview implemented"
else
    fail "Task 8: Deploy preview missing"
fi

if grep -q "View full diff?" "lib/dispatchers/teach-dispatcher.zsh"; then
    pass "Task 8: Full diff viewing option added"
else
    fail "Task 8: Full diff viewing option missing"
fi

# Task 9: Scholar template + lesson plan
if grep -q "lesson-plan.yml" "lib/dispatchers/teach-dispatcher.zsh"; then
    pass "Task 9: lesson-plan.yml auto-load implemented"
else
    fail "Task 9: lesson-plan.yml auto-load missing"
fi

if grep -q "template" "lib/dispatchers/teach-dispatcher.zsh"; then
    pass "Task 9: Template selection support added"
else
    fail "Task 9: Template selection support missing"
fi

# Task 10: teach init enhancements
if grep -q "^_teach_init()" "lib/dispatchers/teach-dispatcher.zsh"; then
    pass "Task 10: _teach_init() function reimplemented"
else
    fail "Task 10: _teach_init() function missing"
fi

if grep -q -- "--config" "lib/dispatchers/teach-dispatcher.zsh" && \
   grep -q -- "--github" "lib/dispatchers/teach-dispatcher.zsh"; then
    pass "Task 10: --config and --github flags implemented"
else
    fail "Task 10: --config and --github flags missing"
fi

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

section "INTEGRATION TESTS"

# Test plugin loading (syntax check instead of full source to avoid hangs)
if zsh -n "flow.plugin.zsh" 2>&1; then
    pass "Integration: Plugin loads without syntax errors"
else
    fail "Integration: Plugin has syntax errors"
fi

# Test teach doctor routing
if grep -q "doctor)" "lib/dispatchers/teach-dispatcher.zsh"; then
    pass "Integration: teach doctor routing exists"
else
    fail "Integration: teach doctor routing missing"
fi

# Test teach init routing
if grep -q "init|i)" "lib/dispatchers/teach-dispatcher.zsh"; then
    pass "Integration: teach init routing exists"
else
    fail "Integration: teach init routing missing"
fi

# Test teach archive routing
if grep -q "archive|a)" "lib/dispatchers/teach-dispatcher.zsh"; then
    pass "Integration: teach archive routing exists"
else
    fail "Integration: teach archive routing missing"
fi

# ============================================================================
# SYNTAX VALIDATION
# ============================================================================

section "SYNTAX VALIDATION"

# Check ZSH syntax for all modified files
for file in \
    "lib/dispatchers/teach-dispatcher.zsh" \
    "lib/dispatchers/teach-doctor-impl.zsh" \
    "lib/backup-helpers.zsh" \
    "flow.plugin.zsh"; do

    if [[ -f "$file" ]]; then
        if zsh -n "$file" 2>&1; then
            pass "Syntax: $file validates"
        else
            fail "Syntax: $file has syntax errors"
        fi
    fi
done

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}TEST SUMMARY${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Total Tests:  $TOTAL"
echo -e "${GREEN}Passed:       $PASS${NC}"
echo -e "${RED}Failed:       $FAIL${NC}"
echo ""

if [[ $FAIL -gt 0 ]]; then
    echo -e "${RED}Failed Tests:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo -e "  ${RED}✗${NC} $test"
    done
    echo ""
    exit 1
else
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo ""
    exit 0
fi
