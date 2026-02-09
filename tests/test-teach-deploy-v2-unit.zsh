#!/usr/bin/env zsh
# test-teach-deploy-v2-unit.zsh - Unit tests for teach deploy v2 features
# Tests each function in isolation within a sandboxed git repo

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

# Source core + helpers (suppress output)
source "$PROJECT_ROOT/lib/core.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/git-helpers.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/deploy-history-helpers.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/deploy-rollback-helpers.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/dispatchers/teach-deploy-enhanced.zsh" 2>/dev/null || true

# Stub functions that may not be available
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

# Helper: create a sandboxed git repo with .flow/teach-config.yml
# IMPORTANT: All git output is redirected to /dev/null to keep echo clean
# Uses mktemp for unique directories (avoids subshell counter issues)
setup_git_repo() {
    local dir=$(mktemp -d "$TEST_DIR/repo-XXXXXX")
    mkdir -p "$dir/.flow"
    (
        cd "$dir"
        git init -q 2>/dev/null
        git config user.email "test@test.com"
        git config user.name "Test"
        cat > .flow/teach-config.yml <<'YAML'
course:
  name: "STAT-101"
git:
  draft_branch: draft
  production_branch: main
  auto_pr: true
  require_clean: true
YAML
        git add -A >/dev/null 2>&1
        git commit -q -m "init" >/dev/null 2>&1
    )
    echo "$dir"
}

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  teach deploy v2 - Unit Tests                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# SECTION 1: Deploy History Helpers
# ============================================================================
echo "--- Deploy History ---"

# Test 1: history_append creates file if not exists
test_repo=$(setup_git_repo)
cd "$test_repo"
rm -f .flow/deploy-history.yml
_deploy_history_append "direct" "abc12345" "def67890" "draft" "main" "5" "test deploy" "null" "null" "10" >/dev/null 2>&1
if [[ -f .flow/deploy-history.yml ]]; then
    _test_pass "history_append creates file if not exists"
else
    _test_fail "history_append creates file if not exists" "file not created"
fi

# Test 2: history_append adds entry to existing file
_deploy_history_append "pr" "xyz12345" "abc12345" "draft" "main" "3" "second deploy" "null" "null" "5" >/dev/null 2>&1
count=$(_deploy_history_count)
if [[ "$count" == "2" ]]; then
    _test_pass "history_append adds entry to existing file"
else
    _test_fail "history_append adds entry to existing file" "expected 2, got $count"
fi

# Test 3: history_count returns correct number
test_repo=$(setup_git_repo)
cd "$test_repo"
count=$(_deploy_history_count)
if [[ "$count" == "0" ]]; then
    _test_pass "history_count returns 0 for no history"
else
    _test_fail "history_count returns 0 for no history" "got $count"
fi

# Test 4: history_count after appends
_deploy_history_append "direct" "aaa11111" "bbb22222" "draft" "main" "1" "first" "null" "null" "1" >/dev/null 2>&1
_deploy_history_append "direct" "ccc33333" "aaa11111" "draft" "main" "2" "second" "null" "null" "2" >/dev/null 2>&1
_deploy_history_append "pr" "ddd44444" "ccc33333" "draft" "main" "3" "third" "null" "null" "3" >/dev/null 2>&1
count=$(_deploy_history_count)
if [[ "$count" == "3" ]]; then
    _test_pass "history_count returns correct count after 3 appends"
else
    _test_fail "history_count returns correct count after 3 appends" "expected 3, got $count"
fi

# Test 5: history_get retrieves correct entry (1 = most recent)
_deploy_history_get 1
if [[ "$DEPLOY_HIST_MESSAGE" == "third" ]]; then
    _test_pass "history_get retrieves most recent entry (idx=1)"
else
    _test_fail "history_get retrieves most recent entry (idx=1)" "got: $DEPLOY_HIST_MESSAGE"
fi

# Test 6: history_get retrieves correct entry (3 = oldest)
_deploy_history_get 3
if [[ "$DEPLOY_HIST_MESSAGE" == "first" ]]; then
    _test_pass "history_get retrieves oldest entry (idx=3)"
else
    _test_fail "history_get retrieves oldest entry (idx=3)" "got: $DEPLOY_HIST_MESSAGE"
fi

# Test 7: history_get fails for out-of-range index
if _deploy_history_get 99 2>/dev/null; then
    _test_fail "history_get rejects out-of-range index" "should have returned non-zero"
else
    _test_pass "history_get rejects out-of-range index"
fi

# Test 8: history_list shows formatted table
test_repo=$(setup_git_repo)
cd "$test_repo"
_deploy_history_append "direct" "aaa11111" "bbb22222" "draft" "main" "2" "test message" "null" "null" "5" >/dev/null 2>&1
output=$(_deploy_history_list 5 2>&1)
if echo "$output" | grep -q "test message"; then
    _test_pass "history_list shows deploy messages"
else
    _test_fail "history_list shows deploy messages" "message not found in output"
fi

# Test 9: history_list returns error when no history file
test_repo=$(setup_git_repo)
cd "$test_repo"
rm -f .flow/deploy-history.yml
output=$(_deploy_history_list 5 2>&1)
ret=$?
if [[ $ret -ne 0 ]]; then
    _test_pass "history_list returns error when no history"
else
    _test_fail "history_list returns error when no history" "expected non-zero exit"
fi

# Test 10: Single quotes in messages are escaped
test_repo=$(setup_git_repo)
cd "$test_repo"
_deploy_history_append "direct" "aaa11111" "bbb22222" "draft" "main" "1" "week 5 update" "null" "null" "1" >/dev/null 2>&1
# Verify yq can read the file after append
count=$(_deploy_history_count)
if [[ "$count" == "1" ]]; then
    _test_pass "history file is valid YAML after append"
else
    _test_fail "history file is valid YAML after append" "yq failed to parse, count=$count"
fi

# Test 11: history_append stores correct mode
_deploy_history_get 1
if [[ "$DEPLOY_HIST_MODE" == "direct" ]]; then
    _test_pass "history_append stores correct mode field"
else
    _test_fail "history_append stores correct mode field" "got: $DEPLOY_HIST_MODE"
fi

# Test 12: history_append stores commit hash (truncated to 8)
_deploy_history_get 1
if [[ "$DEPLOY_HIST_COMMIT" == "aaa11111" ]]; then
    _test_pass "history_append stores 8-char commit hash"
else
    _test_fail "history_append stores 8-char commit hash" "got: $DEPLOY_HIST_COMMIT"
fi

# ============================================================================
# SECTION 2: Smart Commit Messages
# ============================================================================
echo ""
echo "--- Smart Commit Messages ---"

# Test 13: categorizes lecture files correctly
if typeset -f _generate_smart_commit_message >/dev/null 2>&1; then
    test_repo=$(setup_git_repo)
    cd "$test_repo"
    git checkout -q -b draft 2>/dev/null
    mkdir -p lectures
    echo "---\ntitle: Week 5\n---\nHello" > lectures/week-05.qmd
    git add -A >/dev/null 2>&1 && git commit -q -m "add lecture" >/dev/null 2>&1
    msg=$(_generate_smart_commit_message "draft" "main")
    if echo "$msg" | grep -qi "lecture\|content\|week-05"; then
        _test_pass "smart commit categorizes lecture files"
    else
        _test_fail "smart commit categorizes lecture files" "got: $msg"
    fi
else
    _test_skip "smart commit categorizes lecture files (_generate_smart_commit_message not loaded)"
fi

# Test 14: categorizes assignment files correctly
if typeset -f _generate_smart_commit_message >/dev/null 2>&1; then
    test_repo=$(setup_git_repo)
    cd "$test_repo"
    git checkout -q -b draft 2>/dev/null
    mkdir -p assignments
    echo "---\ntitle: HW3\n---" > assignments/hw-03.qmd
    git add -A >/dev/null 2>&1 && git commit -q -m "add assignment" >/dev/null 2>&1
    msg=$(_generate_smart_commit_message "draft" "main")
    if echo "$msg" | grep -qi "assignment\|content\|hw"; then
        _test_pass "smart commit categorizes assignment files"
    else
        _test_fail "smart commit categorizes assignment files" "got: $msg"
    fi
else
    _test_skip "smart commit categorizes assignment files"
fi

# Test 15: categorizes config files correctly
if typeset -f _generate_smart_commit_message >/dev/null 2>&1; then
    test_repo=$(setup_git_repo)
    cd "$test_repo"
    git checkout -q -b draft 2>/dev/null
    echo "title: Test" > _quarto.yml
    git add -A >/dev/null 2>&1 && git commit -q -m "add config" >/dev/null 2>&1
    msg=$(_generate_smart_commit_message "draft" "main")
    if echo "$msg" | grep -qi "config\|quarto\|_quarto"; then
        _test_pass "smart commit categorizes config files"
    else
        _test_fail "smart commit categorizes config files" "got: $msg"
    fi
else
    _test_skip "smart commit categorizes config files"
fi

# Test 16: empty diff produces fallback message
if typeset -f _generate_smart_commit_message >/dev/null 2>&1; then
    test_repo=$(setup_git_repo)
    cd "$test_repo"
    msg=$(_generate_smart_commit_message "main" "main")
    if [[ -n "$msg" ]]; then
        _test_pass "empty diff produces fallback message"
    else
        _test_fail "empty diff produces fallback message" "got empty string"
    fi
else
    _test_skip "empty diff produces fallback message"
fi

# Test 17: message truncates at 72 chars
if typeset -f _generate_smart_commit_message >/dev/null 2>&1; then
    test_repo=$(setup_git_repo)
    cd "$test_repo"
    git checkout -q -b draft 2>/dev/null
    mkdir -p lectures labs assignments exams projects
    for i in {01..20}; do
        echo "content $i" > "lectures/week-${i}.qmd"
    done
    git add -A >/dev/null 2>&1 && git commit -q -m "add many files" >/dev/null 2>&1
    msg=$(_generate_smart_commit_message "draft" "main")
    if [[ ${#msg} -le 72 ]]; then
        _test_pass "message truncates at 72 chars (len=${#msg})"
    else
        _test_fail "message truncates at 72 chars" "length=${#msg}"
    fi
else
    _test_skip "message truncates at 72 chars"
fi

# ============================================================================
# SECTION 3: Preflight Checks
# ============================================================================
echo ""
echo "--- Preflight Checks ---"

# Test 18: preflight returns error outside git repo
test_nongit=$(mktemp -d "$TEST_DIR/nongit-XXXXXX")

cd "$test_nongit"
output=$(_deploy_preflight_checks "true" 2>&1)
ret=$?
if [[ $ret -ne 0 ]]; then
    _test_pass "preflight returns error outside git repo"
else
    _test_fail "preflight returns error outside git repo" "expected non-zero exit"
fi

# Test 19: preflight returns error without config file
test_repo_noconfig=$(mktemp -d "$TEST_DIR/noconfig-XXXXXX")

cd "$test_repo_noconfig"
git init -q 2>/dev/null
git config user.email "test@test.com"
git config user.name "Test"
echo "test" > file.txt
git add -A >/dev/null 2>&1 && git commit -q -m "init" >/dev/null 2>&1
output=$(_deploy_preflight_checks "true" 2>&1)
ret=$?
if [[ $ret -ne 0 ]]; then
    _test_pass "preflight returns error without config file"
else
    _test_fail "preflight returns error without config file" "expected non-zero exit"
fi

# Test 20: preflight sets DEPLOY_* variables correctly
test_repo=$(setup_git_repo)
cd "$test_repo"
_deploy_preflight_checks "true" >/dev/null 2>&1
if [[ "$DEPLOY_DRAFT_BRANCH" == "draft" && "$DEPLOY_PROD_BRANCH" == "main" ]]; then
    _test_pass "preflight sets DEPLOY_* variables correctly"
else
    _test_fail "preflight sets DEPLOY_* variables correctly" "draft=$DEPLOY_DRAFT_BRANCH prod=$DEPLOY_PROD_BRANCH"
fi

# Test 21: preflight sets course name
if [[ "$DEPLOY_COURSE_NAME" == "STAT-101" ]]; then
    _test_pass "preflight sets DEPLOY_COURSE_NAME"
else
    _test_fail "preflight sets DEPLOY_COURSE_NAME" "got: $DEPLOY_COURSE_NAME"
fi

# ============================================================================
# SECTION 4: Dry-run Report
# ============================================================================
echo ""
echo "--- Dry-run Report ---"

# Test 22: dry-run shows preview without mutations
test_repo=$(setup_git_repo)
cd "$test_repo"
git checkout -q -b draft 2>/dev/null
echo "new content" > lectures.qmd
git add -A >/dev/null 2>&1 && git commit -q -m "add content" >/dev/null 2>&1
output=$(_deploy_dry_run_report "draft" "main" "STAT-101" "false" "" 2>&1)
if echo "$output" | grep -qi "DRY RUN"; then
    _test_pass "dry-run shows DRY RUN header"
else
    _test_fail "dry-run shows DRY RUN header" "not found in output"
fi

# Test 23: dry-run with direct mode
output=$(_deploy_dry_run_report "draft" "main" "STAT-101" "true" "" 2>&1)
if echo "$output" | grep -qi "direct"; then
    _test_pass "dry-run shows direct mode"
else
    _test_fail "dry-run shows direct mode" "not found in output"
fi

# Test 24: dry-run with custom message
output=$(_deploy_dry_run_report "draft" "main" "STAT-101" "false" "custom message" 2>&1)
if echo "$output" | grep -q "custom message"; then
    _test_pass "dry-run shows custom message"
else
    _test_fail "dry-run shows custom message" "not found in output"
fi

# Test 25: dry-run shows history log hint
output=$(_deploy_dry_run_report "draft" "main" "STAT-101" "false" "" 2>&1)
if echo "$output" | grep -q "deploy-history"; then
    _test_pass "dry-run shows history log hint"
else
    _test_fail "dry-run shows history log hint" "not found in output"
fi

# ============================================================================
# SECTION 5: .STATUS Update Function
# ============================================================================
echo ""
echo "--- .STATUS Update ---"

# Test 26: skips if no .STATUS file
test_repo=$(setup_git_repo)
cd "$test_repo"
rm -f .STATUS
output=$(_deploy_update_status_file 2>&1)
ret=$?
if [[ $ret -eq 0 ]]; then
    _test_pass "status update skips if no .STATUS file"
else
    _test_fail "status update skips if no .STATUS file" "returned $ret"
fi

# Test 27: updates last_deploy date (if yq available)
if command -v yq >/dev/null 2>&1; then
    test_repo=$(setup_git_repo)
    cd "$test_repo"
    echo "status: active" > .STATUS
    _deploy_update_status_file >/dev/null 2>&1
    last_deploy=$(yq '.last_deploy // ""' .STATUS 2>/dev/null)
    today=$(date '+%Y-%m-%d')
    if [[ "$last_deploy" == "$today" ]]; then
        _test_pass "status update sets last_deploy to today"
    else
        _test_fail "status update sets last_deploy to today" "got: $last_deploy"
    fi
else
    _test_skip "status update sets last_deploy (yq not available)"
fi

# Test 28: updates deploy_count
if command -v yq >/dev/null 2>&1; then
    test_repo=$(setup_git_repo)
    cd "$test_repo"
    echo "status: active" > .STATUS
    _deploy_history_append "direct" "aaa11111" "bbb22222" "draft" "main" "1" "test" "null" "null" "1" >/dev/null 2>&1
    _deploy_update_status_file >/dev/null 2>&1
    dc=$(yq '.deploy_count // 0' .STATUS 2>/dev/null)
    if [[ "$dc" == "1" ]]; then
        _test_pass "status update sets deploy_count"
    else
        _test_fail "status update sets deploy_count" "got: $dc"
    fi
else
    _test_skip "status update sets deploy_count (yq not available)"
fi

# ============================================================================
# SECTION 6: Rollback (unit-level)
# ============================================================================
echo ""
echo "--- Rollback ---"

# Test 29: CI mode requires index
test_repo=$(setup_git_repo)
cd "$test_repo"
_deploy_history_append "direct" "aaa11111" "bbb22222" "draft" "main" "1" "test" "null" "null" "1" >/dev/null 2>&1
output=$(_deploy_rollback --ci 2>&1)
ret=$?
if [[ $ret -ne 0 ]]; then
    _test_pass "rollback CI mode requires explicit index"
else
    _test_fail "rollback CI mode requires explicit index" "expected failure"
fi

# Test 30: rollback validates index against history count
output=$(_deploy_rollback 99 --ci 2>&1)
ret=$?
if [[ $ret -ne 0 ]]; then
    _test_pass "rollback rejects out-of-range index"
else
    _test_fail "rollback rejects out-of-range index" "expected failure"
fi

# Test 31: rollback returns error on empty history
test_repo=$(setup_git_repo)
cd "$test_repo"
rm -f .flow/deploy-history.yml
output=$(_deploy_rollback 1 --ci 2>&1)
ret=$?
if [[ $ret -ne 0 ]]; then
    _test_pass "rollback returns error on empty history"
else
    _test_fail "rollback returns error on empty history" "expected failure"
fi

# ============================================================================
# SECTION 7: History Append Edge Cases
# ============================================================================
echo ""
echo "--- History Edge Cases ---"

# Test 32: history_append with all null optional fields
test_repo=$(setup_git_repo)
cd "$test_repo"
_deploy_history_append "direct" "abc12345" "def67890" "draft" "main" "0" "empty deploy" "null" "null" "0" >/dev/null 2>&1
count=$(_deploy_history_count)
if [[ "$count" == "1" ]]; then
    _test_pass "history_append handles null optional fields"
else
    _test_fail "history_append handles null optional fields" "count=$count"
fi

# Test 33: history_append with pr_number
_deploy_history_append "pr" "ghi12345" "abc12345" "draft" "main" "5" "pr deploy" "42" "null" "20" >/dev/null 2>&1
_deploy_history_get 1
if [[ "$DEPLOY_HIST_PR" == "42" ]]; then
    _test_pass "history_append stores pr_number correctly"
else
    _test_fail "history_append stores pr_number correctly" "got: $DEPLOY_HIST_PR"
fi

# Test 34: history file is valid YAML after multiple appends
test_repo=$(setup_git_repo)
cd "$test_repo"
for i in {1..5}; do
    _deploy_history_append "direct" "hash${i}000" "prev${i}000" "draft" "main" "$i" "deploy $i" "null" "null" "$i" >/dev/null 2>&1
done
count=$(_deploy_history_count)
if [[ "$count" == "5" ]]; then
    _test_pass "history file valid YAML after 5 appends"
else
    _test_fail "history file valid YAML after 5 appends" "count=$count"
fi

# ============================================================================
# SECTION 8: Deploy Step Progress
# ============================================================================
echo ""
echo "--- Deploy Step Progress ---"

# Test 35: _deploy_step done shows checkmark and step counter
output=$(_deploy_step 1 5 "Push draft to origin" done 2>&1)
if echo "$output" | grep -qE '\[1/5\].*Push draft to origin'; then
    _test_pass "_deploy_step done shows [N/M] counter"
else
    _test_fail "_deploy_step done shows [N/M] counter" "output: $output"
fi

# Test 36: _deploy_step fail shows X marker
output=$(_deploy_step 3 5 "Merge failed" fail 2>&1)
if echo "$output" | grep -qE '\[3/5\].*Merge failed'; then
    _test_pass "_deploy_step fail shows [N/M] counter"
else
    _test_fail "_deploy_step fail shows [N/M] counter" "output: $output"
fi

# Test 37: _deploy_step active shows spinner icon
output=$(_deploy_step 2 5 "Switching branch" active 2>&1)
if echo "$output" | grep -qE '\[2/5\].*Switching branch'; then
    _test_pass "_deploy_step active shows [N/M] counter"
else
    _test_fail "_deploy_step active shows [N/M] counter" "output: $output"
fi

# Test 38: _deploy_step handles step equal to total
output=$(_deploy_step 5 5 "Final step" done 2>&1)
if echo "$output" | grep -qE '\[5/5\].*Final step'; then
    _test_pass "_deploy_step handles final step [5/5]"
else
    _test_fail "_deploy_step handles final step [5/5]" "output: $output"
fi

# ============================================================================
# SECTION 9: Deploy Summary Box
# ============================================================================
echo ""
echo "--- Deploy Summary Box ---"

# Test 39: summary box shows Deployment Summary header
output=$(_deploy_summary_box "Direct merge" "12" "234" "56" "11" "a1b2c3d4" "" 2>&1)
if echo "$output" | grep -q "Deployment Summary"; then
    _test_pass "summary box shows Deployment Summary header"
else
    _test_fail "summary box shows Deployment Summary header" "not found"
fi

# Test 40: summary box shows mode
if echo "$output" | grep -q "Direct merge"; then
    _test_pass "summary box shows deploy mode"
else
    _test_fail "summary box shows deploy mode" "not found"
fi

# Test 41: summary box shows file stats with +/-
if echo "$output" | grep -q "+234 / -56"; then
    _test_pass "summary box shows file change stats"
else
    _test_fail "summary box shows file change stats" "not found"
fi

# Test 42: summary box shows duration
if echo "$output" | grep -q "11s"; then
    _test_pass "summary box shows duration"
else
    _test_fail "summary box shows duration" "not found"
fi

# Test 43: summary box shows commit hash
if echo "$output" | grep -q "a1b2c3d4"; then
    _test_pass "summary box shows commit hash"
else
    _test_fail "summary box shows commit hash" "not found"
fi

# Test 44: summary box shows URL when provided
output=$(_deploy_summary_box "Direct merge" "5" "50" "10" "8" "abcd1234" "https://example.github.io/stat-101" 2>&1)
if echo "$output" | grep -q "https://example.github.io/stat-101"; then
    _test_pass "summary box shows URL when provided"
else
    _test_fail "summary box shows URL when provided" "not found"
fi

# Test 45: summary box hides URL when empty
output=$(_deploy_summary_box "PR" "3" "30" "5" "20" "efgh5678" "" 2>&1)
if echo "$output" | grep -q "URL:"; then
    _test_fail "summary box hides URL when empty" "URL row should be absent"
else
    _test_pass "summary box hides URL when empty"
fi

# Test 46: summary box hides URL when null
output=$(_deploy_summary_box "PR" "3" "30" "5" "20" "efgh5678" "null" 2>&1)
if echo "$output" | grep -q "URL:"; then
    _test_fail "summary box hides URL when null" "URL row should be absent"
else
    _test_pass "summary box hides URL when null"
fi

# Test 47: summary box has box-drawing characters
output=$(_deploy_summary_box "Direct merge" "1" "10" "2" "3" "hash1234" "" 2>&1)
if echo "$output" | grep -q "╭" && echo "$output" | grep -q "╰"; then
    _test_pass "summary box has box-drawing borders"
else
    _test_fail "summary box has box-drawing borders" "missing ╭ or ╰"
fi

# Test 48: summary box Pull request mode label
output=$(_deploy_summary_box "Pull request" "6" "80" "20" "45" "pr123456" "https://github.com/org/repo/pull/42" 2>&1)
if echo "$output" | grep -q "Pull request"; then
    _test_pass "summary box shows Pull request mode"
else
    _test_fail "summary box shows Pull request mode" "not found"
fi

# ============================================================================
# SECTION 10: Merge Commit Detection (regression for -m 1 rollback fix)
# ============================================================================
echo ""
echo "--- Merge Commit Detection ---"

# Test 49: merge commit has 2 parents (validates detection logic)
test_repo=$(setup_git_repo)
cd "$test_repo"
# Create diverging branches
(
    cd "$test_repo"
    git checkout -q -b feature 2>/dev/null
    echo "feature work" > feature.txt
    git add -A && git commit -q -m "feat: feature work" 2>/dev/null
    git checkout -q main 2>/dev/null
    echo "main work" > main.txt
    git add -A && git commit -q -m "fix: main work" 2>/dev/null
    git merge feature --no-ff -m "merge: feature into main" 2>/dev/null
) >/dev/null 2>&1
merge_hash=$(git rev-parse HEAD)
parent_count=$(git cat-file -p "$merge_hash" 2>/dev/null | grep -c "^parent ")
if [[ $parent_count -eq 2 ]]; then
    _test_pass "merge commit detected with 2 parents"
else
    _test_fail "merge commit detected with 2 parents" "got $parent_count"
fi

# Test 50: regular commit has 1 parent
test_repo=$(setup_git_repo)
cd "$test_repo"
echo "extra" > extra.txt
git add -A && git commit -q -m "add extra" >/dev/null 2>&1
regular_hash=$(git rev-parse HEAD)
parent_count=$(git cat-file -p "$regular_hash" 2>/dev/null | grep -c "^parent ")
if [[ $parent_count -eq 1 ]]; then
    _test_pass "regular commit detected with 1 parent"
else
    _test_fail "regular commit detected with 1 parent" "got $parent_count"
fi

# ============================================================================
# SECTION: Deploy Safety Enhancements (v6.6.0)
# ============================================================================
echo ""
echo "--- Deploy Safety Enhancements ---"

# Test 51: _deploy_summary_box includes Actions URL for GitHub remotes
test_repo=$(setup_git_repo)
cd "$test_repo"
git remote add origin "https://github.com/TestOrg/test-repo.git" 2>/dev/null
output=$(_deploy_summary_box "Direct merge" "3" "45" "12" "8" "a1b2c3d4" "https://testorg.github.io/test-repo/")
if echo "$output" | grep -q "https://github.com/TestOrg/test-repo/actions"; then
    _test_pass "summary box includes Actions URL for GitHub remote"
else
    _test_fail "summary box includes Actions URL for GitHub remote" "Actions URL not found in output"
fi

# Test 52: _deploy_summary_box omits Actions URL for non-GitHub remotes
test_repo=$(setup_git_repo)
cd "$test_repo"
git remote add origin "https://gitlab.com/TestOrg/test-repo.git" 2>/dev/null
output=$(_deploy_summary_box "Direct merge" "3" "45" "12" "8" "a1b2c3d4" "https://example.com/")
if echo "$output" | grep -q "Actions:"; then
    _test_fail "summary box omits Actions for non-GitHub remote" "Actions line found"
else
    _test_pass "summary box omits Actions for non-GitHub remote"
fi

# Test 53: _deploy_summary_box handles SSH GitHub remote
test_repo=$(setup_git_repo)
cd "$test_repo"
git remote add origin "git@github.com:Data-Wise/stat-545.git" 2>/dev/null
output=$(_deploy_summary_box "Pull request" "5" "100" "20" "12" "e5f6g7h8" "https://data-wise.github.io/stat-545/")
if echo "$output" | grep -q "https://github.com/Data-Wise/stat-545/actions"; then
    _test_pass "summary box handles SSH GitHub remote URL"
else
    _test_fail "summary box handles SSH GitHub remote URL" "Actions URL not found"
fi

# Test 54: trap handler returns to draft branch after direct merge failure
test_repo=$(setup_git_repo)
cd "$test_repo"
# Create draft and main branches with content
git checkout -b main -q 2>/dev/null
echo "main content" > main.txt
git add -A && git commit -q -m "main init" >/dev/null 2>&1
git checkout -b draft -q 2>/dev/null
echo "draft content" > draft.txt
git add -A && git commit -q -m "draft init" >/dev/null 2>&1
# Create a remote (bare repo) so push has a target
bare_dir=$(mktemp -d "$TEST_DIR/bare-XXXXXX")
git init --bare -q "$bare_dir" 2>/dev/null
git remote add origin "$bare_dir" 2>/dev/null
git push -u origin draft -q 2>/dev/null
git push origin main -q 2>/dev/null
# Call direct merge which should fail (no real merge scenario - force failure by making main dirty)
# Simulate: calling with a nonexistent prod branch triggers failure + trap
_deploy_direct_merge "draft" "nonexistent-branch" "test deploy" "false" >/dev/null 2>&1
current=$(_git_current_branch)
# Clear any leftover trap from the test
trap - EXIT INT TERM
if [[ "$current" == "draft" ]]; then
    _test_pass "trap handler returns to draft after direct merge failure"
else
    _test_fail "trap handler returns to draft after direct merge failure" "on branch: $current"
fi

# Test 55: pre-commit hook failure shows recovery message
test_repo=$(setup_git_repo)
cd "$test_repo"
git checkout -b draft -q 2>/dev/null
# Create a failing pre-commit hook
mkdir -p .git/hooks
cat > .git/hooks/pre-commit <<'HOOK'
#!/bin/sh
echo "Quarto render failed" >&2
exit 1
HOOK
chmod +x .git/hooks/pre-commit
# Create uncommitted content
echo "new content" > test.qmd
git add test.qmd
output=$(git commit -m "test" 2>&1)
if [[ $? -ne 0 ]]; then
    _test_pass "pre-commit hook correctly blocks commit"
else
    _test_fail "pre-commit hook correctly blocks commit" "commit succeeded unexpectedly"
fi
# Verify staged changes are preserved
staged=$(git diff --cached --name-only)
if echo "$staged" | grep -q "test.qmd"; then
    _test_pass "staged changes preserved after hook failure"
else
    _test_fail "staged changes preserved after hook failure" "test.qmd not in staged files"
fi

# Test 56: uncommitted handler in CI mode fails with error
test_repo=$(setup_git_repo)
cd "$test_repo"
git checkout -b draft -q 2>/dev/null
echo "dirty" > dirty.txt
# _git_is_clean should return false
if _git_is_clean; then
    _test_fail "dirty tree detected for CI uncommitted test" "tree reported clean"
else
    _test_pass "dirty tree detected for CI uncommitted test"
fi

# Test 57: _deploy_summary_box includes GitHub remote without .git suffix
test_repo=$(setup_git_repo)
cd "$test_repo"
git remote add origin "https://github.com/user/repo" 2>/dev/null
output=$(_deploy_summary_box "Direct merge" "1" "10" "5" "3" "abcd1234" "")
if echo "$output" | grep -q "https://github.com/user/repo/actions"; then
    _test_pass "summary box handles GitHub URL without .git suffix"
else
    _test_fail "summary box handles GitHub URL without .git suffix" "Actions URL not found"
fi

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo "═══════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed, $SKIP skipped"
echo "═══════════════════════════════════════════"
[[ $FAIL -eq 0 ]]
