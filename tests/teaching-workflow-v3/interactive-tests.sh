#!/usr/bin/env bash
# Interactive Test Suite for Teaching Workflow v3.0 Phase 1
# Generated: 2026-01-18
# Human-guided QA with expected/actual comparison

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Counters
PASS=0
FAIL=0
SKIP=0
TOTAL_TESTS=28

# Setup
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/interactive-test-$(date +%Y%m%d-%H%M%S).log"

cd "$PROJECT_ROOT"

# Helper function to run test
run_test() {
    local test_num="$1"
    local test_name="$2"
    local command="$3"
    local expected="$4"

    echo "" | tee -a "$LOG_FILE"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}TEST $test_num/$TOTAL_TESTS: $test_name${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"

    echo -e "${CYAN}Command:${NC}" | tee -a "$LOG_FILE"
    echo "  $command" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"

    echo -e "${CYAN}Expected Behavior:${NC}" | tee -a "$LOG_FILE"
    echo "  $expected" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"

    echo -e "${CYAN}Actual Output:${NC}" | tee -a "$LOG_FILE"
    echo "  Running command..." | tee -a "$LOG_FILE"

    # Run command and capture output
    local output
    if output=$(eval "$command" 2>&1); then
        echo "$output" | tee -a "$LOG_FILE"
    else
        echo "$output" | tee -a "$LOG_FILE"
        echo -e "${RED}  (Command failed with exit code $?)${NC}" | tee -a "$LOG_FILE"
    fi

    echo "" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}Does the output match expected behavior?${NC}"
    echo -e "  ${GREEN}[y]${NC} Pass  ${RED}[n]${NC} Fail  ${BLUE}[s]${NC} Skip  ${YELLOW}[q]${NC} Quit"
    echo -n "  Your choice: "

    read -r -n 1 choice
    echo ""

    case "$choice" in
        y|Y)
            ((PASS++))
            echo -e "${GREEN}✓ PASS${NC}" | tee -a "$LOG_FILE"
            ;;
        n|N)
            ((FAIL++))
            echo -e "${RED}✗ FAIL${NC}" | tee -a "$LOG_FILE"
            ;;
        s|S)
            ((SKIP++))
            echo -e "${BLUE}⊘ SKIP${NC}" | tee -a "$LOG_FILE"
            ;;
        q|Q)
            echo "" | tee -a "$LOG_FILE"
            echo -e "${YELLOW}Test suite interrupted by user${NC}" | tee -a "$LOG_FILE"
            print_summary
            exit 0
            ;;
        *)
            ((SKIP++))
            echo -e "${BLUE}⊘ SKIP (invalid input)${NC}" | tee -a "$LOG_FILE"
            ;;
    esac
}

print_summary() {
    local total=$((PASS + FAIL + SKIP))

    echo "" | tee -a "$LOG_FILE"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    echo -e "${YELLOW}TEST SUMMARY${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo -e "Total Tests:  $total" | tee -a "$LOG_FILE"
    echo -e "${GREEN}Passed:       $PASS${NC}" | tee -a "$LOG_FILE"
    echo -e "${RED}Failed:       $FAIL${NC}" | tee -a "$LOG_FILE"
    echo -e "${BLUE}Skipped:      $SKIP${NC}" | tee -a "$LOG_FILE"
    echo "" | tee -a "$LOG_FILE"
    echo -e "Log saved to: ${CYAN}$LOG_FILE${NC}"
    echo ""
}

# Banner
clear
echo ""
echo -e "${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  Teaching Workflow v3.0 - Interactive Test Suite      ║${NC}"
echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "This suite tests all 10 tasks from Waves 1-3."
echo "For each test, review the output and judge if it matches expectations."
echo ""
echo -e "${YELLOW}Total Tests: $TOTAL_TESTS${NC}"
echo ""
echo "Press Enter to start..."
read -r

# ============================================================================
# WAVE 1 TESTS
# ============================================================================

echo "" | tee -a "$LOG_FILE"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
echo -e "${BLUE}WAVE 1: Foundation Tests (Tasks 1-4)${NC}" | tee -a "$LOG_FILE"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"

# Test 1: teach-init deletion
run_test 1 "Task 1: teach-init deletion" \
    "test -f commands/teach-init.zsh && echo 'EXISTS' || echo 'DELETED'" \
    "Should output 'DELETED'"

# Test 2: teach doctor basic
run_test 2 "Task 2: teach doctor basic check" \
    "source flow.plugin.zsh && typeset -f _teach_doctor >/dev/null && echo 'Function exists'" \
    "Should output 'Function exists'"

# Test 3: teach doctor dependency check
run_test 3 "Task 2: teach doctor dependency checks" \
    "grep -c '_teach_doctor_check_dep' lib/dispatchers/teach-doctor-impl.zsh" \
    "Should show multiple calls to dependency check function"

# Test 4: teach doctor --json
run_test 4 "Task 4: teach doctor JSON output" \
    "grep -q '_teach_doctor_json_output' lib/dispatchers/teach-doctor-impl.zsh && echo 'JSON support exists'" \
    "Should output 'JSON support exists'"

# Test 5: teach doctor git checks
run_test 5 "Task 4: teach doctor git status checks" \
    "grep -q '_teach_doctor_check_git' lib/dispatchers/teach-doctor-impl.zsh && echo 'Git checks exist'" \
    "Should output 'Git checks exist'"

# Test 6: Help system - EXAMPLES
run_test 6 "Task 3: Help system EXAMPLES sections" \
    "grep -c 'EXAMPLES' lib/dispatchers/teach-dispatcher.zsh" \
    "Should show multiple EXAMPLES sections"

# Test 7: Help functions
run_test 7 "Task 3: Help functions exist" \
    "grep -E '_teach_(status|week|scholar)_help' lib/dispatchers/teach-dispatcher.zsh | wc -l" \
    "Should show 3 or more help functions"

# ============================================================================
# WAVE 2 TESTS
# ============================================================================

echo "" | tee -a "$LOG_FILE"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
echo -e "${BLUE}WAVE 2: Backup System Tests (Tasks 5-6)${NC}" | tee -a "$LOG_FILE"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"

# Test 8: backup-helpers.zsh exists
run_test 8 "Task 5: backup-helpers.zsh file" \
    "test -f lib/backup-helpers.zsh && wc -l lib/backup-helpers.zsh" \
    "Should show ~320 lines"

# Test 9: Backup functions
run_test 9 "Task 5: Backup functions implemented" \
    "grep -E '^_(teach_backup_content|teach_get_retention_policy|teach_list_backups|teach_count_backups)' lib/backup-helpers.zsh | wc -l" \
    "Should show 4 or more functions"

# Test 10: Retention policy
run_test 10 "Task 5: Retention policy logic" \
    "grep -c 'archive\\|semester' lib/backup-helpers.zsh" \
    "Should show multiple references to retention policies"

# Test 11: Delete confirmation
run_test 11 "Task 6: Delete confirmation function" \
    "grep -q '_teach_confirm_delete' lib/backup-helpers.zsh && echo 'Confirmation exists'" \
    "Should output 'Confirmation exists'"

# Test 12: Interactive prompting
run_test 12 "Task 6: Interactive delete prompt" \
    "grep -q 'read -q' lib/backup-helpers.zsh && echo 'Interactive prompt exists'" \
    "Should output 'Interactive prompt exists'"

# Test 13: Archive semester
run_test 13 "Task 5: Archive semester function" \
    "grep -q '_teach_archive_semester' lib/backup-helpers.zsh && echo 'Archive function exists'" \
    "Should output 'Archive function exists'"

# Test 14: Sourced in plugin
run_test 14 "Task 5: backup-helpers sourced" \
    "grep -q 'backup-helpers.zsh' flow.plugin.zsh && echo 'Sourced in plugin'" \
    "Should output 'Sourced in plugin'"

# ============================================================================
# WAVE 3 TESTS
# ============================================================================

echo "" | tee -a "$LOG_FILE"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"
echo -e "${BLUE}WAVE 3: Enhancement Tests (Tasks 7-10)${NC}" | tee -a "$LOG_FILE"
echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}" | tee -a "$LOG_FILE"

# Test 15: teach status - Deployment Status
run_test 15 "Task 7: Deployment Status section" \
    "grep -A5 'Deployment Status' lib/dispatchers/teach-dispatcher.zsh | head -6" \
    "Should show Deployment Status section header"

# Test 16: teach status - Backup Summary
run_test 16 "Task 7: Backup Summary section" \
    "grep -A5 'Backup Summary' lib/dispatchers/teach-dispatcher.zsh | head -6" \
    "Should show Backup Summary section header"

# Test 17: teach status - Last deploy
run_test 17 "Task 7: Last deploy check" \
    "grep -q 'Last Deploy' lib/dispatchers/teach-dispatcher.zsh && echo 'Last deploy check exists'" \
    "Should output 'Last deploy check exists'"

# Test 18: teach status - PR status
run_test 18 "Task 7: Open PRs check" \
    "grep -q 'Open PRs' lib/dispatchers/teach-dispatcher.zsh && echo 'PR check exists'" \
    "Should output 'PR check exists'"

# Test 19: teach deploy - Changes Preview
run_test 19 "Task 8: Deploy preview section" \
    "grep -A3 'Changes Preview' lib/dispatchers/teach-dispatcher.zsh | head -4" \
    "Should show Changes Preview section"

# Test 20: teach deploy - Files changed
run_test 20 "Task 8: Files changed summary" \
    "grep -q 'files_changed=.*git diff' lib/dispatchers/teach-dispatcher.zsh && echo 'Files summary exists'" \
    "Should output 'Files summary exists'"

# Test 21: teach deploy - View diff
run_test 21 "Task 8: View full diff option" \
    "grep -q 'View full diff?' lib/dispatchers/teach-dispatcher.zsh && echo 'Diff viewing exists'" \
    "Should output 'Diff viewing exists'"

# Test 22: Scholar - lesson-plan.yml auto-load
run_test 22 "Task 9: lesson-plan.yml auto-load" \
    "grep -B2 -A2 'lesson-plan.yml' lib/dispatchers/teach-dispatcher.zsh | grep -q 'use_context=true' && echo 'Auto-load exists'" \
    "Should output 'Auto-load exists'"

# Test 23: Scholar - template flag
run_test 23 "Task 9: Template flag support" \
    "grep -q -- '--template' lib/dispatchers/teach-dispatcher.zsh && echo 'Template flag exists'" \
    "Should output 'Template flag exists'"

# Test 24: Scholar - template in context
run_test 24 "Task 9: Template in context files" \
    "grep -B5 -A5 'potential_files=(' lib/dispatchers/teach-dispatcher.zsh | grep -q 'lesson-plan.yml' && echo 'In context files'" \
    "Should output 'In context files'"

# Test 25: teach init - Function exists
run_test 25 "Task 10: teach init function" \
    "grep -q '^_teach_init()' lib/dispatchers/teach-dispatcher.zsh && echo 'teach init exists'" \
    "Should output 'teach init exists'"

# Test 26: teach init - --config flag
run_test 26 "Task 10: --config flag support" \
    "grep -A10 '^_teach_init()' lib/dispatchers/teach-dispatcher.zsh | grep -q 'external_config' && echo '--config supported'" \
    "Should output '--config supported'"

# Test 27: teach init - --github flag
run_test 27 "Task 10: --github flag support" \
    "grep -A10 '^_teach_init()' lib/dispatchers/teach-dispatcher.zsh | grep -q 'create_github' && echo '--github supported'" \
    "Should output '--github supported'"

# Test 28: teach init - Default config generation
run_test 28 "Task 10: Default config template" \
    "grep -A20 'cat > .flow/teach-config.yml' lib/dispatchers/teach-dispatcher.zsh | grep -q 'backups:' && echo 'Config template exists'" \
    "Should output 'Config template exists'"

# ============================================================================
# SUMMARY
# ============================================================================

print_summary
