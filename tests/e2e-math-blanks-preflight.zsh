#!/usr/bin/env zsh
# e2e-math-blanks-preflight.zsh - End-to-end tests for math blank-line preflight
# Tests the full _deploy_preflight_checks flow with display-math validation
# in sandboxed git repos with bare remotes.
#
# Sections:
#   1. Clean .qmd files pass preflight           (3 tests)
#   2. Blank lines in $$ detected                (3 tests)
#   3. Unclosed $$ blocks detected               (2 tests)
#   4. CI mode blocks deploy on math issues      (3 tests)
#   5. Path resolution from subdirectory         (2 tests)
# Total: 13 tests

# Test framework setup
PASS=0
FAIL=0
SKIP=0

_test_pass() { ((PASS++)); echo "  ✅ $1"; }
_test_fail() { ((FAIL++)); echo "  ❌ $1: $2"; }
_test_skip() { ((SKIP++)); echo "  ⏭️  $1 (skipped)"; }

# ============================================================================
# SETUP
# ============================================================================

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
TEST_DIR=$(mktemp -d)
ORIGINAL_DIR=$(pwd)

cleanup() {
    cd "$ORIGINAL_DIR"
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Minimal FLOW_COLORS for non-interactive tests
typeset -gA FLOW_COLORS
FLOW_COLORS[info]=""
FLOW_COLORS[success]=""
FLOW_COLORS[error]=""
FLOW_COLORS[warn]=""
FLOW_COLORS[dim]=""
FLOW_COLORS[bold]=""
FLOW_COLORS[reset]=""
FLOW_COLORS[prompt]=""
FLOW_COLORS[muted]=""

# Source needed libraries
source "$PROJECT_ROOT/lib/core.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/git-helpers.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/dispatchers/teach-deploy-enhanced.zsh" 2>/dev/null || true

# Stub functions
if ! typeset -f _teach_error >/dev/null 2>&1; then
    _teach_error() { echo "ERROR: $1" >&2; }
fi
if ! typeset -f _git_in_repo >/dev/null 2>&1; then
    _git_in_repo() { git rev-parse --git-dir >/dev/null 2>&1; }
fi
if ! typeset -f _git_current_branch >/dev/null 2>&1; then
    _git_current_branch() { git branch --show-current 2>/dev/null; }
fi
if ! typeset -f _git_is_clean >/dev/null 2>&1; then
    _git_is_clean() { [[ -z "$(git status --porcelain 2>/dev/null)" ]]; }
fi
if ! typeset -f _git_detect_production_conflicts >/dev/null 2>&1; then
    _git_detect_production_conflicts() { return 0; }
fi

# Verify function loaded
if ! typeset -f _deploy_preflight_checks >/dev/null 2>&1; then
    echo "❌ FATAL: _deploy_preflight_checks not found"
    exit 1
fi

# yq required for preflight config reading
if ! command -v yq >/dev/null 2>&1; then
    echo "⏭️  yq not available — skipping E2E math-blanks tests"
    exit 0
fi

# ============================================================================
# HELPER: Create E2E repo with bare remote + draft/main branches
# Args: qmd_files_on_draft... (written to lectures/ on draft branch)
# ============================================================================
setup_math_repo() {
    local bare_dir=$(mktemp -d "$TEST_DIR/bare-XXXXXX")
    local work_dir=$(mktemp -d "$TEST_DIR/e2e-XXXXXX")
    rm -rf "$work_dir"

    (
        cd "$bare_dir" && git init -q --bare
    ) >/dev/null 2>&1

    git clone -q "$bare_dir" "$work_dir" >/dev/null 2>&1
    (
        cd "$work_dir"
        git config user.email "test@test.com"
        git config user.name "Test"

        mkdir -p .flow lectures
        cat > .flow/teach-config.yml <<'YAML'
course:
  name: "STAT-101"
git:
  draft_branch: draft
  production_branch: main
  auto_pr: true
  require_clean: true
YAML

        # Minimal main branch (no .qmd files)
        echo "# Test" > README.md
        git add -A && git commit -q -m "init"
        git push -q origin main

        # Draft branch
        git checkout -q -b draft
    ) >/dev/null 2>&1

    echo "$work_dir"
}

# Helper: add a .qmd file on draft, commit and push
# Usage: add_qmd_to_draft <repo_dir> <filename> <content>
add_qmd_to_draft() {
    local repo_dir="$1" fname="$2" content="$3"
    (
        cd "$repo_dir"
        echo "$content" > "lectures/$fname"
        git add "lectures/$fname"
        git commit -q -m "add $fname"
        git push -q origin draft
    ) >/dev/null 2>&1
}

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║   E2E Tests: Math Blank-Line Preflight                   ║"
echo "╚════════════════════════════════════════════════════════════╝"

# ============================================================================
# SECTION 1: Clean .qmd files pass preflight
# ============================================================================
echo ""
echo "── Section 1: Clean .qmd Files Pass Preflight ──"

# Test 1.1: No .qmd files changed → preflight passes
test_no_qmd_changes() {
    local repo=$(setup_math_repo)
    (
        cd "$repo"
        # No .qmd files added to draft
        local output
        output=$(_deploy_preflight_checks "false" 2>&1)
        local rc=$?
        [[ $rc -eq 0 ]]
    )
    if [[ $? -eq 0 ]]; then
        _test_pass "No .qmd changes → preflight passes"
    else
        _test_fail "No .qmd changes → preflight passes" "preflight returned non-zero"
    fi
}

# Test 1.2: Clean math blocks → preflight passes with "valid" message
test_clean_math_passes() {
    local repo=$(setup_math_repo)
    add_qmd_to_draft "$repo" "week-01.qmd" '---
title: "Week 1"
---
$$
\bar{X} = \frac{1}{n} \sum X_i
$$

Some text.

$$
\sigma^2 = E[(X - \mu)^2]
$$'

    local output
    (
        cd "$repo"
        output=$(_deploy_preflight_checks "false" 2>&1)
    )
    output=$( cd "$repo" && _deploy_preflight_checks "false" 2>&1 )
    if [[ "$output" == *"Display math blocks valid"* ]]; then
        _test_pass "Clean math → 'Display math blocks valid'"
    else
        _test_fail "Clean math → 'Display math blocks valid'" "message not found in output"
    fi
}

# Test 1.3: .qmd with no math at all → passes
test_no_math_passes() {
    local repo=$(setup_math_repo)
    add_qmd_to_draft "$repo" "week-01.qmd" '---
title: "Week 1"
---
# Introduction

Just regular text, no math here.'

    local output
    output=$( cd "$repo" && _deploy_preflight_checks "false" 2>&1 )
    local rc=$?
    if [[ $rc -eq 0 ]]; then
        _test_pass "No math content → preflight passes"
    else
        _test_fail "No math content → preflight passes" "returned $rc"
    fi
}

# ============================================================================
# SECTION 2: Blank lines in $$ detected
# ============================================================================
echo ""
echo "── Section 2: Blank Lines in \$\$ Detected ──"

# Test 2.1: Single file with blank in $$ → warning in output
test_blank_detected_in_output() {
    local repo=$(setup_math_repo)
    add_qmd_to_draft "$repo" "week-01.qmd" '---
title: "Week 1"
---
$$
x = 1

y = 2
$$'

    local output
    output=$( cd "$repo" && _deploy_preflight_checks "false" 2>&1 )
    if [[ "$output" == *"Blank lines in display math"* ]]; then
        _test_pass "Blank in math → warning shown"
    else
        _test_fail "Blank in math → warning shown" "warning not in output"
    fi
}

# Test 2.2: File name appears in warning
test_blank_shows_filename() {
    local repo=$(setup_math_repo)
    add_qmd_to_draft "$repo" "week-03.qmd" '---
title: "Week 3"
---
$$
a + b

= c
$$'

    local output
    output=$( cd "$repo" && _deploy_preflight_checks "false" 2>&1 )
    if [[ "$output" == *"week-03.qmd"* ]]; then
        _test_pass "Warning includes filename (week-03.qmd)"
    else
        _test_fail "Warning includes filename" "week-03.qmd not in output"
    fi
}

# Test 2.3: Actionable fix message shown (not scripts/fix-math-blanks.sh)
test_blank_shows_fix_message() {
    local repo=$(setup_math_repo)
    add_qmd_to_draft "$repo" "week-01.qmd" '---
title: "Week 1"
---
$$
x

y
$$'

    local output
    output=$( cd "$repo" && _deploy_preflight_checks "false" 2>&1 )
    if [[ "$output" == *"Remove blank lines between"* ]] && [[ "$output" != *"scripts/fix-math-blanks"* ]]; then
        _test_pass "Shows actionable fix message (no script reference)"
    else
        _test_fail "Shows actionable fix message" "wrong fix message in output"
    fi
}

# ============================================================================
# SECTION 3: Unclosed $$ blocks detected
# ============================================================================
echo ""
echo "── Section 3: Unclosed \$\$ Blocks Detected ──"

# Test 3.1: Unclosed $$ → warning in output
test_unclosed_detected() {
    local repo=$(setup_math_repo)
    add_qmd_to_draft "$repo" "week-01.qmd" '---
title: "Week 1"
---
$$
x = 1
y = 2
Forgot to close the block.'

    local output
    output=$( cd "$repo" && _deploy_preflight_checks "false" 2>&1 )
    if [[ "$output" == *"Unclosed"* ]]; then
        _test_pass "Unclosed \$\$ block → warning shown"
    else
        _test_fail "Unclosed \$\$ block → warning shown" "warning not in output"
    fi
}

# Test 3.2: Unclosed shows "Add missing closing $$" message
test_unclosed_fix_message() {
    local repo=$(setup_math_repo)
    add_qmd_to_draft "$repo" "week-02.qmd" '---
title: "Week 2"
---
$$
a = b'

    local output
    output=$( cd "$repo" && _deploy_preflight_checks "false" 2>&1 )
    if [[ "$output" == *"Add missing closing"* ]]; then
        _test_pass "Unclosed → actionable fix message"
    else
        _test_fail "Unclosed → actionable fix message" "fix message not found"
    fi
}

# ============================================================================
# SECTION 4: CI mode blocks deploy on math issues
# ============================================================================
echo ""
echo "── Section 4: CI Mode Blocks Deploy ──"

# Test 4.1: ci_mode=true + blank → return 1
test_ci_blocks_on_blank() {
    local repo=$(setup_math_repo)
    add_qmd_to_draft "$repo" "week-01.qmd" '---
title: "Week 1"
---
$$
x

y
$$'

    (
        cd "$repo"
        _deploy_preflight_checks "true" >/dev/null 2>&1
    )
    local rc=$?
    if [[ $rc -ne 0 ]]; then
        _test_pass "CI mode + blank line → blocks deploy (rc=$rc)"
    else
        _test_fail "CI mode + blank line → blocks deploy" "returned 0 (should fail)"
    fi
}

# Test 4.2: ci_mode=true + unclosed → return 1
test_ci_blocks_on_unclosed() {
    local repo=$(setup_math_repo)
    add_qmd_to_draft "$repo" "week-01.qmd" '---
title: "Week 1"
---
$$
x = 1'

    (
        cd "$repo"
        _deploy_preflight_checks "true" >/dev/null 2>&1
    )
    local rc=$?
    if [[ $rc -ne 0 ]]; then
        _test_pass "CI mode + unclosed \$\$ → blocks deploy (rc=$rc)"
    else
        _test_fail "CI mode + unclosed \$\$ → blocks deploy" "returned 0 (should fail)"
    fi
}

# Test 4.3: ci_mode=false + blank → does NOT block (returns 0)
test_interactive_does_not_block() {
    local repo=$(setup_math_repo)
    add_qmd_to_draft "$repo" "week-01.qmd" '---
title: "Week 1"
---
$$
x

y
$$'

    (
        cd "$repo"
        _deploy_preflight_checks "false" >/dev/null 2>&1
    )
    local rc=$?
    if [[ $rc -eq 0 ]]; then
        _test_pass "Interactive mode + blank → warns but passes (rc=0)"
    else
        _test_fail "Interactive mode + blank → warns but passes" "returned $rc (expected 0)"
    fi
}

# ============================================================================
# SECTION 5: Path resolution (git-relative paths → absolute)
# ============================================================================
echo ""
echo "── Section 5: Path Resolution ──"

# Test 5.1: _check_math_blanks works with absolute path from repo root
test_path_absolute() {
    local repo=$(setup_math_repo)
    add_qmd_to_draft "$repo" "week-01.qmd" '---
title: "Week 1"
---
$$
x

y
$$'

    # The preflight uses $(git rev-parse --show-toplevel)/$relative_path
    # Verify the function works with the absolute path it would receive
    if ! _check_math_blanks "$repo/lectures/week-01.qmd"; then
        _test_pass "Absolute path resolves and detects blank"
    else
        _test_fail "Absolute path resolves and detects blank" "returned 0"
    fi
}

# Test 5.2: Multiple files, only bad ones reported
test_multiple_files_selective() {
    local repo=$(setup_math_repo)
    add_qmd_to_draft "$repo" "week-01.qmd" '---
title: "Week 1"
---
$$
x = 1
$$'
    add_qmd_to_draft "$repo" "week-02.qmd" '---
title: "Week 2"
---
$$
a

b
$$'

    local output
    output=$( cd "$repo" && _deploy_preflight_checks "false" 2>&1 )
    if [[ "$output" == *"week-02.qmd"* ]] && [[ "$output" != *"week-01.qmd"*"Blank"* ]]; then
        _test_pass "Only bad file (week-02.qmd) reported"
    else
        _test_fail "Only bad file reported" "output: ${output:0:200}"
    fi
}

# ============================================================================
# RUN ALL
# ============================================================================

test_no_qmd_changes
test_clean_math_passes
test_no_math_passes
test_blank_detected_in_output
test_blank_shows_filename
test_blank_shows_fix_message
test_unclosed_detected
test_unclosed_fix_message
test_ci_blocks_on_blank
test_ci_blocks_on_unclosed
test_interactive_does_not_block
test_path_absolute
test_multiple_files_selective

# ============================================================================
# SUMMARY
# ============================================================================

echo ""
echo "═══════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed, $SKIP skipped"
echo "═══════════════════════════════════════════"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
