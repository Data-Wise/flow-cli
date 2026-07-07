#!/usr/bin/env zsh
# e2e-handoff.zsh - End-to-end tests for `flow handoff` command
#
# Tests the full flow handoff path against an isolated temp git repo (never
# touches the real flow-cli repo state):
# - Help display
# - Fresh slug creates file with expected sections
# - Existing slug refuses to overwrite
# - --base override changes the diff base
# - Relevant Files pre-fill (non-empty diff, and empty-diff placeholder)
# - --issue fails clearly without `gh` on PATH
# - Clean `zsh -f` invocation produces no unexpected stray stdout
#
# Usage: zsh tests/e2e-handoff.zsh

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_func="$2"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -n "  ${CYAN}[$TESTS_RUN] $test_name...${RESET} "

    local output
    output=$(eval "$test_func" 2>&1)
    local rc=$?

    if [[ $rc -eq 0 ]]; then
        echo "${GREEN}PASS${RESET}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo "${RED}FAIL${RESET}"
        echo "${DIM}$output${RESET}" | sed 's/^/      /'
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# ── Isolated temp repo setup ────────────────────────────────────────────────

TMP_REPO=$(mktemp -d)
trap 'rm -rf "$TMP_REPO"' EXIT

setup_temp_repo() {
    cd "$TMP_REPO" || return 1
    git init -q -b dev
    git config user.email "test@example.com"
    git config user.name "Test"
    echo "seed" > seed.txt
    git add seed.txt
    git commit -qm "seed"
}

setup_temp_repo

source "$PROJECT_ROOT/lib/handoff-helpers.zsh"

echo "${CYAN}Running e2e tests for flow handoff (temp repo: $TMP_REPO)${RESET}"
echo ""

test_help_display() {
    cd "$TMP_REPO" || return 1
    local out
    out=$(_flow_handoff --help 2>&1)
    [[ "$out" == *"USAGE"* ]] || return 1
    return 0
}

test_fresh_slug_creates_file() {
    cd "$TMP_REPO" || return 1
    _flow_handoff e2e-fresh-slug >/dev/null 2>&1
    local f="$TMP_REPO/docs/planning/HANDOFF-e2e-fresh-slug.md"
    [[ -f "$f" ]] || return 1
    grep -q "## Summary" "$f" || return 1
    grep -q "## Relevant Files" "$f" || return 1
    grep -q "## Verification Note" "$f" || return 1
    return 0
}

test_existing_slug_refuses() {
    cd "$TMP_REPO" || return 1
    local f="$TMP_REPO/docs/planning/HANDOFF-e2e-fresh-slug.md"
    local before_mtime
    before_mtime=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null)
    _flow_handoff e2e-fresh-slug >/dev/null 2>&1
    local rc=$?
    [[ $rc -ne 0 ]] || return 1
    local after_mtime
    after_mtime=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null)
    [[ "$before_mtime" == "$after_mtime" ]] || return 1
    return 0
}

test_relevant_files_nonempty_on_real_diff() {
    cd "$TMP_REPO" || return 1
    git checkout -qb e2e-diff-branch
    echo "change" > changed.txt
    git add changed.txt
    git commit -qm "add changed file"
    _flow_handoff e2e-diff-check --base dev >/dev/null 2>&1
    local f="$TMP_REPO/docs/planning/HANDOFF-e2e-diff-check.md"
    grep -q "changed.txt" "$f" || return 1
    git checkout -q dev
    git branch -D e2e-diff-branch -q
    return 0
}

test_empty_diff_placeholder() {
    cd "$TMP_REPO" || return 1
    _flow_handoff e2e-empty-diff --base dev >/dev/null 2>&1
    local f="$TMP_REPO/docs/planning/HANDOFF-e2e-empty-diff.md"
    grep -q "no diff vs dev yet" "$f" || return 1
    return 0
}

test_issue_fails_without_gh() {
    cd "$TMP_REPO" || return 1
    local fake_path
    fake_path=$(mktemp -d)
    # PATH with no gh binary reachable
    local out
    out=$(PATH="$fake_path:/usr/bin:/bin" _flow_handoff e2e-issue-test --issue 2>&1)
    local rc=$?
    rm -rf "$fake_path"
    [[ $rc -ne 0 ]] || return 1
    [[ "$out" == *"gh"* ]] || return 1
    return 0
}

test_clean_zshf_no_stray_output() {
    cd "$TMP_REPO" || return 1
    local out
    out=$(zsh -f -c "source '$PROJECT_ROOT/lib/handoff-helpers.zsh'; cd '$TMP_REPO'; _flow_handoff e2e-clean-run --base dev" 2>&1)
    # Only expect our own known ✓/⚠ lines and the dim sub-line - no bare
    # "varname=value" style stray assignment echoes
    if echo "$out" | grep -qE '^[a-zA-Z_]+=[^ ]'; then
        return 1
    fi
    return 0
}

run_test "help display works"                                  test_help_display
run_test "fresh slug creates file with expected sections"      test_fresh_slug_creates_file
run_test "existing slug refuses to overwrite"                  test_existing_slug_refuses
run_test "relevant files populated on real diff"               test_relevant_files_nonempty_on_real_diff
run_test "empty diff uses placeholder line"                    test_empty_diff_placeholder
run_test "--issue fails clearly without gh on PATH"             test_issue_fails_without_gh
run_test "clean zsh -f run has no stray stdout"                 test_clean_zshf_no_stray_output

echo ""
echo "${CYAN}Results:${RESET} $TESTS_PASSED/$TESTS_RUN passed, $TESTS_FAILED failed"
[[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1
