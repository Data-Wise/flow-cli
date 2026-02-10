#!/usr/bin/env zsh
# dogfood-math-blanks-preflight.zsh - Dogfooding tests for math blank-line preflight
# Run with: zsh tests/dogfood-math-blanks-preflight.zsh
#
# Tests the REAL plugin functions against the demo course fixture.
# Loads the full plugin (source flow.plugin.zsh) -- not mocked.
#
# Sections:
#   1. Function Load Verification            (3 tests)
#   2. _check_math_blanks on Demo Course     (5 tests)
#   3. Preflight with Injected Math Issues   (4 tests)
#   4. Preflight with Demo Course (Clean)    (3 tests)
# Total: 15 tests

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

# Counters
typeset -g TESTS_RUN=0
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0
typeset -g TESTS_SKIPPED=0

# Get script directory
SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR}/.."
DEMO_COURSE="$PROJECT_ROOT/tests/fixtures/demo-course"

# Global temp dirs to clean up
typeset -ga _DOGFOOD_TEMP_DIRS=()

cleanup_all() {
    for d in "${_DOGFOOD_TEMP_DIRS[@]}"; do
        [[ -d "$d" ]] && rm -rf "$d"
    done
}
trap cleanup_all EXIT

# Load plugin
echo "${CYAN}Loading flow-cli plugin...${RESET}"
source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
    echo "${RED}ERROR: Failed to load plugin${RESET}"
    exit 1
}
echo "${GREEN}Plugin loaded${RESET}"
echo ""

# ============================================================================
# Test runner -- exit 0=pass, 77=skip, other=fail
# ============================================================================
run_test() {
    local test_name="$1"
    local test_func="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "${CYAN}[$TESTS_RUN] $test_name...${RESET} "

    local output
    output=$(eval "$test_func" 2>&1)
    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        echo "${GREEN}PASS${RESET}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    elif [[ $exit_code -eq 77 ]]; then
        echo "${YELLOW}SKIP${RESET}"
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    else
        echo "${RED}FAIL${RESET}"
        echo "  ${DIM}Output: ${output:0:200}${RESET}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# yq probe
_YQ_AVAILABLE=false
if command -v yq >/dev/null 2>&1; then
    _probe=$(echo "test: value" | yq '.test' 2>/dev/null)
    [[ "$_probe" == "value" ]] && _YQ_AVAILABLE=true
    unset _probe
fi

if [[ "$_YQ_AVAILABLE" != "true" ]]; then
    echo "${YELLOW}Warning: yq not available -- preflight tests will be skipped${RESET}"
    echo ""
fi

# ============================================================================
# HELPER: Create repo from demo course with bare remote
# ============================================================================
_create_demo_repo() {
    local tmpdir=$(mktemp -d)
    local remotedir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir" "$remotedir")

    (
        cd "$remotedir" && git init --bare -q
    ) >/dev/null 2>&1

    (
        cp -R "$DEMO_COURSE"/. "$tmpdir"/
        cd "$tmpdir"
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test"
        git add -A && git commit -q -m "init demo course"

        git remote add origin "$remotedir"
        git push -q origin main 2>/dev/null

        # Create draft branch with a change
        git checkout -q -b draft
        echo "\n## Updated" >> lectures/week-01.qmd
        git add -A && git commit -q -m "update week-01"
        git push -q origin draft 2>/dev/null
    ) >/dev/null 2>&1

    echo "$tmpdir"
}

# ============================================================================
# HELPER: Create repo with injected math issues
# ============================================================================
_create_repo_with_math_issue() {
    local issue_type="$1"  # "blank" or "unclosed"
    local tmpdir=$(mktemp -d)
    local remotedir=$(mktemp -d)
    _DOGFOOD_TEMP_DIRS+=("$tmpdir" "$remotedir")

    (
        cd "$remotedir" && git init --bare -q
    ) >/dev/null 2>&1

    (
        cp -R "$DEMO_COURSE"/. "$tmpdir"/
        cd "$tmpdir"
        git init -q
        git config user.email "test@example.com"
        git config user.name "Test"
        git add -A && git commit -q -m "init demo course"

        git remote add origin "$remotedir"
        git push -q origin main 2>/dev/null

        # Create draft branch with a math issue
        git checkout -q -b draft

        if [[ "$issue_type" == "blank" ]]; then
            cat > lectures/week-05-math-issue.qmd <<'QMD'
---
title: "Week 5: Broken Math"
---

$$
\bar{X} = \frac{1}{n}

\sum_{i=1}^{n} X_i
$$
QMD
        elif [[ "$issue_type" == "unclosed" ]]; then
            cat > lectures/week-05-math-issue.qmd <<'QMD'
---
title: "Week 5: Unclosed Math"
---

$$
\bar{X} = \frac{1}{n} \sum_{i=1}^{n} X_i
Some text after forgotten closing.
QMD
        fi

        git add -A && git commit -q -m "add broken math file"
        git push -q origin draft 2>/dev/null
    ) >/dev/null 2>&1

    echo "$tmpdir"
}

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Dogfood Tests: Math Blank-Line Preflight                ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# SECTION 1: Function Load Verification
# ============================================================================
echo "${CYAN}── Section 1: Function Load Verification ──${RESET}"

run_test "_check_math_blanks function loaded" '
    typeset -f _check_math_blanks >/dev/null 2>&1 || return 1
'

run_test "_deploy_preflight_checks function loaded" '
    typeset -f _deploy_preflight_checks >/dev/null 2>&1 || return 1
'

run_test "_check_math_blanks returns 0 for nonexistent file" '
    _check_math_blanks "/tmp/nonexistent-$$-test.qmd"
    [[ $? -eq 0 ]] || return 1
'

# ============================================================================
# SECTION 2: _check_math_blanks on Demo Course Files
# ============================================================================
echo ""
echo "${CYAN}── Section 2: _check_math_blanks on Demo Course ──${RESET}"

run_test "week-01.qmd (inline math only) → clean" '
    _check_math_blanks "$DEMO_COURSE/lectures/week-01.qmd"
    [[ $? -eq 0 ]] || return 1
'

run_test "week-02.qmd (inline math only) → clean" '
    _check_math_blanks "$DEMO_COURSE/lectures/week-02.qmd"
    [[ $? -eq 0 ]] || return 1
'

run_test "week-03.qmd (has \$\$ blocks, no blanks) → clean" '
    _check_math_blanks "$DEMO_COURSE/lectures/week-03.qmd"
    [[ $? -eq 0 ]] || return 1
'

run_test "week-04.qmd (has \$\$ block, no blanks) → clean" '
    _check_math_blanks "$DEMO_COURSE/lectures/week-04.qmd"
    [[ $? -eq 0 ]] || return 1
'

run_test "_macros.qmd (macro definitions) → clean" '
    _check_math_blanks "$DEMO_COURSE/_macros.qmd"
    [[ $? -eq 0 ]] || return 1
'

# ============================================================================
# SECTION 3: Preflight with Injected Math Issues
# ============================================================================
echo ""
echo "${CYAN}── Section 3: Preflight with Injected Math Issues ──${RESET}"

run_test "Blank line in math → warning in preflight output" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local repo=$(_create_repo_with_math_issue "blank")
    local output
    output=$(cd "$repo" && _deploy_preflight_checks "false" 2>&1)
    [[ "$output" == *"Blank lines in display math"* ]] || return 1
'

run_test "Unclosed \$\$ → warning in preflight output" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local repo=$(_create_repo_with_math_issue "unclosed")
    local output
    output=$(cd "$repo" && _deploy_preflight_checks "false" 2>&1)
    [[ "$output" == *"Unclosed"* ]] || return 1
'

run_test "CI mode + blank → preflight returns non-zero" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local repo=$(_create_repo_with_math_issue "blank")
    (cd "$repo" && _deploy_preflight_checks "true" >/dev/null 2>&1)
    [[ $? -ne 0 ]] || return 1
'

run_test "CI mode + unclosed → preflight returns non-zero" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local repo=$(_create_repo_with_math_issue "unclosed")
    (cd "$repo" && _deploy_preflight_checks "true" >/dev/null 2>&1)
    [[ $? -ne 0 ]] || return 1
'

# ============================================================================
# SECTION 4: Preflight with Demo Course (Clean)
# ============================================================================
echo ""
echo "${CYAN}── Section 4: Preflight with Demo Course (Clean) ──${RESET}"

run_test "Demo course passes preflight (no math issues)" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local repo=$(_create_demo_repo)
    local output
    output=$(cd "$repo" && _deploy_preflight_checks "false" 2>&1)
    local rc=$?
    [[ $rc -eq 0 ]] || return 1
'

run_test "Demo course preflight shows 'Display math blocks valid'" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local repo=$(_create_demo_repo)
    local output
    output=$(cd "$repo" && _deploy_preflight_checks "false" 2>&1)
    [[ "$output" == *"Display math blocks valid"* ]] || return 1
'

run_test "Demo course preflight in CI mode passes" '
    [[ "$_YQ_AVAILABLE" == "true" ]] || return 77
    local repo=$(_create_demo_repo)
    (cd "$repo" && _deploy_preflight_checks "true" >/dev/null 2>&1)
    [[ $? -eq 0 ]] || return 1
'

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "═══════════════════════════════════════════"
if [[ $TESTS_FAILED -gt 0 ]]; then
    echo "${RED}  Results: $TESTS_PASSED passed, $TESTS_FAILED failed, $TESTS_SKIPPED skipped${RESET}"
else
    echo "${GREEN}  Results: $TESTS_PASSED passed, $TESTS_FAILED failed, $TESTS_SKIPPED skipped${RESET}"
fi
echo "═══════════════════════════════════════════"

if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
fi
exit 0
