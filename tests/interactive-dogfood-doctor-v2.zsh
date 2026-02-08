#!/usr/bin/env zsh
# =============================================================================
# Interactive Dogfooding Test - teach doctor v2
# =============================================================================
#
# PURPOSE: Walk through every teach doctor v2 mode and flag on real projects
#
# TESTS:
#   Phase 1: Sandbox (safe temp dir) - all flags and modes
#   Phase 2: Real project (stat-545) - read-only checks
#   Phase 3: Demo course fixture - verify fixture quality
#
# SAFETY:
#   - Phase 1 uses a temp sandbox (auto-cleaned)
#   - Phase 2 is READ-ONLY (no --fix on real projects)
#   - Phase 3 copies fixture to temp dir
#
# RUN:
#   zsh tests/interactive-dogfood-doctor-v2.zsh
#
# =============================================================================

setopt NO_ERR_EXIT 2>/dev/null || true

# =============================================================================
# Configuration
# =============================================================================

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
FLOW_CLI_PATH="$PROJECT_ROOT"
SANDBOX_BASE="/tmp/doctor-v2-dogfood-$$"
REAL_COURSE="$HOME/projects/teaching/stat-545"
DEMO_COURSE="$PROJECT_ROOT/tests/fixtures/demo-course"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# Counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo ""
    echo "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${RESET}"
    echo "${BOLD}${CYAN}  $1${RESET}"
    echo "${BOLD}${CYAN}═══════════════════════════════════════════════════════════════${RESET}"
    echo ""
}

print_section() {
    echo ""
    echo "${BOLD}${BLUE}─── $1 ───${RESET}"
    echo ""
}

print_test() {
    ((TESTS_RUN++))
    echo ""
    echo "${BOLD}${YELLOW}[$TESTS_RUN] $1${RESET}"
}

print_expect() {
    echo "${DIM}Expected: $1${RESET}"
}

print_cmd() {
    echo "${CYAN}\$ $1${RESET}"
}

pass() {
    ((TESTS_PASSED++))
    echo "${GREEN}  PASS: $1${RESET}"
}

fail() {
    ((TESTS_FAILED++))
    echo "${RED}  FAIL: $1${RESET}"
}

skip() {
    ((TESTS_SKIPPED++))
    echo "${YELLOW}  SKIP: $1${RESET}"
}

wait_for_user() {
    echo ""
    echo -n "${DIM}Press ENTER to continue...${RESET}"
    read -r
}

ask_visual() {
    echo ""
    echo -n "${YELLOW}Does the output look correct? [Y/n]: ${RESET}"
    read -r response
    if [[ "$response" =~ ^[Nn] ]]; then
        fail "$1"
    else
        pass "$1"
    fi
}

# =============================================================================
# Cleanup
# =============================================================================

cleanup() {
    echo ""
    echo "${DIM}Cleaning up sandbox...${RESET}"
    [[ -d "$SANDBOX_BASE" ]] && rm -rf "$SANDBOX_BASE"
    echo "${GREEN}Done.${RESET}"
}
trap cleanup EXIT

# =============================================================================
# Load Plugin
# =============================================================================

print_header "teach doctor v2 - Interactive Dogfood Test"

echo "This test walks through every doctor v2 flag and mode."
echo ""
echo "  Phase 1: Sandbox tests (safe temp dir)"
echo "  Phase 2: Real project (stat-545, read-only)"
echo "  Phase 3: Demo course fixture"
echo ""
echo "${GREEN}Your real projects will NOT be modified.${RESET}"

wait_for_user

echo ""
echo "${CYAN}Loading flow.plugin.zsh...${RESET}"
FLOW_QUIET=1
FLOW_PLUGIN_DIR="$PROJECT_ROOT"
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
    echo "${RED}Plugin failed to load!${RESET}"
    exit 1
}
echo "${GREEN}Plugin loaded (v${FLOW_VERSION:-unknown})${RESET}"

# =============================================================================
# PHASE 1: Sandbox Tests
# =============================================================================

print_header "Phase 1: Sandbox Tests (all flags)"

# Create sandbox
mkdir -p "$SANDBOX_BASE/sandbox/.flow"
git init "$SANDBOX_BASE/sandbox" >/dev/null 2>&1
git -C "$SANDBOX_BASE/sandbox" checkout -b draft >/dev/null 2>&1

cat > "$SANDBOX_BASE/sandbox/.flow/teach-config.yml" <<'YAML'
course:
  name: "DOGFOOD-101"
  semester: "Spring 2026"
semester_info:
  start_date: "2026-01-12"
  end_date: "2026-05-01"
  total_weeks: 15
YAML

echo "${GREEN}Sandbox created: $SANDBOX_BASE/sandbox${RESET}"
cd "$SANDBOX_BASE/sandbox"

# ── Test 1: Quick mode (default) ──

print_test "Quick mode (default)"
print_expect "Header says 'quick check', shows deps/R/config/git, skip hint at bottom"
print_cmd "teach doctor"
echo ""
_teach_doctor 2>&1
ask_visual "Quick mode output"

# ── Test 2: Full mode ──

print_test "Full mode (--full)"
print_expect "Header says 'full check', shows ALL sections, no skip hint"
print_cmd "teach doctor --full"
echo ""
_teach_doctor --full 2>&1
ask_visual "Full mode output"

# ── Test 3: Brief mode ──

print_test "Brief mode (--brief)"
print_expect "NO header, only warnings/failures shown, fix hint at bottom"
print_cmd "teach doctor --brief"
echo ""
_teach_doctor --brief 2>&1
ask_visual "Brief mode output"

# ── Test 4: CI mode ──

print_test "CI mode (--ci)"
print_expect "Machine-readable key=value lines: doctor:status=, doctor:passed=, doctor:mode=quick"
print_cmd "teach doctor --ci"
echo ""
_teach_doctor --ci 2>&1
ask_visual "CI mode output"

# ── Test 5: CI + Full ──

print_test "CI + Full mode (--ci --full)"
print_expect "Same key=value format, doctor:mode=full"
print_cmd "teach doctor --ci --full"
echo ""
_teach_doctor --ci --full 2>&1
ask_visual "CI full mode output"

# ── Test 6: JSON mode ──

print_test "JSON output (--json)"
print_expect "Valid JSON with version, mode, summary, checks array"
print_cmd "teach doctor --json"
echo ""
local json_out
json_out=$(_teach_doctor --json 2>/dev/null)
echo "$json_out"

if command -v jq &>/dev/null; then
    if echo "$json_out" | jq . &>/dev/null; then
        pass "JSON is valid (jq verified)"
    else
        fail "JSON is invalid"
    fi
else
    ask_visual "JSON output"
fi

# ── Test 7: JSON + Full ──

print_test "JSON + Full mode (--json --full)"
print_expect "JSON with mode=full, more checks in array"
print_cmd "teach doctor --json --full | jq .summary"
echo ""
_teach_doctor --json --full 2>/dev/null | jq .summary 2>/dev/null || _teach_doctor --json --full 2>/dev/null
ask_visual "JSON full summary"

# ── Test 8: Verbose mode ──

print_test "Verbose mode (--verbose)"
print_expect "Implies --full, shows renv.lock age detail"
print_cmd "teach doctor --verbose"
echo ""

# Add renv for verbose test
echo '{"R":{"Version":"4.4.2"},"Packages":{"ggplot2":{"Package":"ggplot2","Version":"3.5.1"}}}' > renv.lock
mkdir -p renv
echo "# activate" > renv/activate.R

_teach_doctor --verbose 2>&1

# Cleanup renv
rm -f renv.lock renv/activate.R
rmdir renv 2>/dev/null

ask_visual "Verbose mode output (should show renv.lock age)"

# ── Test 9: Fix hint ──

print_test "Fix hint in summary"
print_expect "Summary footer shows: 'Run teach doctor --fix to auto-fix issues'"
print_cmd "teach doctor"
echo ""
local fix_out
fix_out=$(_teach_doctor 2>&1)
echo "$fix_out"

if echo "$fix_out" | grep -q "teach doctor --fix"; then
    pass "Fix hint present in summary"
else
    fail "Fix hint missing from summary"
fi

# ── Test 10: Status file ──

print_test "Status file creation"
print_expect ".flow/doctor-status.json created with green/yellow/red status"
print_cmd "_teach_doctor --brief; cat .flow/doctor-status.json"
echo ""
_teach_doctor --brief >/dev/null 2>&1

if [[ -f .flow/doctor-status.json ]]; then
    cat .flow/doctor-status.json
    echo ""
    if command -v jq &>/dev/null; then
        local doc_status
        doc_status=$(jq -r '.status' .flow/doctor-status.json 2>/dev/null)
        if [[ "$doc_status" =~ ^(green|yellow|red)$ ]]; then
            pass "Status file valid (status=$doc_status)"
        else
            fail "Status file has unexpected status: $doc_status"
        fi
    else
        ask_visual "Status file"
    fi
else
    fail "Status file not created"
fi

# ── Test 11: Health indicator ──

print_test "Health indicator dot"
print_expect "Colored dot (green/yellow/red circle character)"
print_cmd "_teach_health_dot"
echo ""
local dot
dot=$(_teach_health_dot)
echo "Dot output: '$dot'"

if [[ -n "$dot" ]]; then
    pass "Health dot is non-empty"
else
    fail "Health dot is empty"
fi

# ── Test 12: Working tree excludes doctor-status.json ──

print_test "Working tree excludes doctor-status.json"
print_expect "Working tree clean (doctor-status.json not counted)"
print_cmd "teach doctor (check git section)"
echo ""
# Stage everything except doctor-status
git -C "$SANDBOX_BASE/sandbox" add -A >/dev/null 2>&1
git -C "$SANDBOX_BASE/sandbox" commit -m "init" --allow-empty >/dev/null 2>&1

# Run doctor (creates doctor-status.json as only change)
_teach_doctor --brief >/dev/null 2>&1

local git_out
git_out=$(_teach_doctor --ci 2>&1)
echo "$git_out"

if echo "$git_out" | grep -q "working_tree.*clean" || ! echo "$git_out" | grep -q "uncommitted"; then
    pass "doctor-status.json excluded from uncommitted count"
else
    fail "doctor-status.json still counted as uncommitted"
fi

wait_for_user

# =============================================================================
# PHASE 2: Real Project (stat-545)
# =============================================================================

print_header "Phase 2: Real Project (stat-545)"

if [[ -d "$REAL_COURSE" ]]; then
    echo "${GREEN}Found: $REAL_COURSE${RESET}"
    echo "${DIM}All checks are READ-ONLY. No --fix will be run.${RESET}"
    cd "$REAL_COURSE"

    # ── Test 13: Quick mode on real project ──

    print_test "Quick mode on stat-545"
    print_expect "< 1 second, shows deps/R/config/git"
    print_cmd "teach doctor"
    echo ""
    local start_ts=$EPOCHSECONDS
    _teach_doctor 2>&1
    local elapsed=$(( EPOCHSECONDS - start_ts ))
    echo ""
    echo "${DIM}Elapsed: ${elapsed}s${RESET}"

    if (( elapsed <= 3 )); then
        pass "Quick mode completes in ${elapsed}s (<= 3s)"
    else
        fail "Quick mode too slow: ${elapsed}s"
    fi

    # ── Test 14: Full mode on real project ──

    print_test "Full mode on stat-545"
    print_expect "Shows all sections including R packages (succinct), macros (succinct), style"
    print_cmd "teach doctor --full"
    echo ""
    start_ts=$EPOCHSECONDS
    _teach_doctor --full 2>&1
    elapsed=$(( EPOCHSECONDS - start_ts ))
    echo ""
    echo "${DIM}Elapsed: ${elapsed}s${RESET}"
    ask_visual "Full mode on real project"

    # ── Test 15: R packages succinct ──

    print_test "R packages succinct (no individual lines)"
    print_expect "Shows 'N/N R packages installed' NOT 'R package: ggplot2' etc."
    print_cmd "teach doctor --full 2>&1 | grep -E 'R package|packages installed'"
    echo ""
    local r_out
    r_out=$(_teach_doctor --full 2>&1)
    echo "$r_out" | grep -E "R package|packages installed"

    if echo "$r_out" | grep -q "packages installed" && ! echo "$r_out" | grep -q "R package:"; then
        pass "R packages show summary only (no individual lines)"
    else
        fail "R packages still showing individual lines"
    fi

    # ── Test 16: Macros succinct ──

    print_test "Macros succinct (first 5 + count)"
    print_expect "Shows '99/100 macros unused' with '... (+N more, use --verbose)'"
    print_cmd "teach doctor --full 2>&1 | grep -E 'macros unused|--verbose'"
    echo ""
    echo "$r_out" | grep -E "macros unused|--verbose"

    if echo "$r_out" | grep -q "use --verbose"; then
        pass "Macros show truncated list with --verbose hint"
    else
        # May not have unused macros
        skip "No unused macros or different format"
    fi

    # ── Test 17: Verbose mode shows individual R packages ──

    print_test "Verbose mode shows individual R packages"
    print_expect "Each R package listed: 'R package: ggplot2' etc."
    print_cmd "teach doctor --verbose 2>&1 | grep 'R package:' | head -5"
    echo ""
    local verbose_out
    verbose_out=$(_teach_doctor --verbose 2>&1)
    echo "$verbose_out" | grep "R package:" | head -5
    echo "${DIM}  ... (showing first 5)${RESET}"

    if echo "$verbose_out" | grep -q "R package:"; then
        pass "Verbose mode shows individual R packages"
    else
        fail "Verbose mode missing individual R packages"
    fi

    # ── Test 18: Verbose macros shows full list ──

    print_test "Verbose mode shows full macro list"
    print_expect "Full 'Unused:' line without '--verbose' truncation hint"
    print_cmd "teach doctor --verbose 2>&1 | grep 'Unused:'"
    echo ""
    echo "$verbose_out" | grep "Unused:"

    if echo "$verbose_out" | grep -q "Unused:" && ! echo "$verbose_out" | grep -q "use --verbose"; then
        pass "Verbose mode shows full macro list"
    else
        skip "Cannot verify (may not have unused macros)"
    fi

    # ── Test 19: Fix hint shows on real project ──

    print_test "Fix hint on real project"
    print_expect "'Run teach doctor --fix to auto-fix issues' in summary"
    echo ""
    if echo "$r_out" | grep -q "teach doctor --fix"; then
        pass "Fix hint present"
    else
        # No warnings = no hint needed
        if echo "$r_out" | grep -q "Warnings:"; then
            fail "Fix hint missing despite warnings"
        else
            pass "No warnings, no fix hint needed"
        fi
    fi

    # ── Test 20: Lesson plan detection ──

    print_test "Lesson plan detection"
    print_expect "Finds .flow/lesson-plans.yml (not stale lesson-plan.yml warning)"
    print_cmd "teach doctor --full 2>&1 | grep -i lesson"
    echo ""
    echo "$r_out" | grep -i "lesson"

    if echo "$r_out" | grep -q "Lesson plans found"; then
        pass "Lesson plan detected at .flow/lesson-plans.yml"
    elif echo "$r_out" | grep -q "No lesson plans"; then
        fail "Lesson plan not detected (should find .flow/lesson-plans.yml)"
    else
        skip "No lesson plan output found"
    fi

else
    echo "${YELLOW}stat-545 not found at $REAL_COURSE${RESET}"
    echo "${DIM}Skipping real project tests${RESET}"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 8))
fi

wait_for_user

# =============================================================================
# PHASE 3: Demo Course Fixture
# =============================================================================

print_header "Phase 3: Demo Course Fixture"

if [[ -d "$DEMO_COURSE" ]]; then
    local demo_tmp
    demo_tmp=$(mktemp -d "$SANDBOX_BASE/demo-XXXXXXXX")
    cp -r "$DEMO_COURSE/." "$demo_tmp/"
    git init "$demo_tmp" >/dev/null 2>&1
    cd "$demo_tmp"

    echo "${GREEN}Demo course copied to: $demo_tmp${RESET}"

    # ── Test 21: Doctor on demo fixture ──

    print_test "Quick mode on demo course"
    print_expect "Runs without crash, shows some warnings (expected — no branches/remote)"
    print_cmd "teach doctor"
    echo ""
    _teach_doctor 2>&1
    ask_visual "Demo course quick mode"

    # ── Test 22: Full mode on demo fixture ──

    print_test "Full mode on demo course"
    print_expect "Shows all 10 sections, more warnings (no hooks, cache, etc.)"
    print_cmd "teach doctor --full"
    echo ""
    _teach_doctor --full 2>&1
    ask_visual "Demo course full mode"

    # ── Test 23: JSON on demo fixture ──

    print_test "JSON on demo course"
    print_expect "Valid JSON with checks array"
    print_cmd "teach doctor --json | jq .summary"
    echo ""
    local demo_json
    demo_json=$(_teach_doctor --json 2>/dev/null)
    echo "$demo_json" | jq .summary 2>/dev/null || echo "$demo_json"

    if command -v jq &>/dev/null && echo "$demo_json" | jq . &>/dev/null; then
        pass "Demo course JSON is valid"
    else
        ask_visual "Demo course JSON"
    fi

    # ── Test 24: CI on demo fixture ──

    print_test "CI mode on demo course"
    print_expect "Key=value format, no ANSI colors"
    print_cmd "teach doctor --ci"
    echo ""
    local ci_out
    ci_out=$(_teach_doctor --ci 2>&1)
    echo "$ci_out"

    if echo "$ci_out" | grep -q "^doctor:status="; then
        pass "CI mode produces key=value output"
    else
        fail "CI mode output format wrong"
    fi

else
    echo "${YELLOW}Demo course not found at $DEMO_COURSE${RESET}"
    TESTS_SKIPPED=$((TESTS_SKIPPED + 4))
fi

# =============================================================================
# SUMMARY
# =============================================================================

print_header "Summary"

echo "  ${GREEN}Passed:  $TESTS_PASSED${RESET}"
[[ $TESTS_FAILED -gt 0 ]] && echo "  ${RED}Failed:  $TESTS_FAILED${RESET}"
[[ $TESTS_SKIPPED -gt 0 ]] && echo "  ${YELLOW}Skipped: $TESTS_SKIPPED${RESET}"
echo "  ${DIM}Total:   $TESTS_RUN${RESET}"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo "${GREEN}${BOLD}All tests passed!${RESET}"
else
    echo "${RED}${BOLD}$TESTS_FAILED test(s) failed.${RESET}"
fi

echo ""
echo "${DIM}Sandbox will be cleaned up automatically.${RESET}"
