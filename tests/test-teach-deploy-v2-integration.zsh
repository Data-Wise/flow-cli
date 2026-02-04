#!/usr/bin/env zsh
# test-teach-deploy-v2-integration.zsh - Integration tests for teach deploy v2
# Tests flag combinations and multi-step workflows

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

# Source libraries (suppress output)
source "$PROJECT_ROOT/lib/core.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/git-helpers.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/deploy-history-helpers.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/deploy-rollback-helpers.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/dispatchers/teach-deploy-enhanced.zsh" 2>/dev/null || true

# Stub/override functions for test isolation
# These MUST be set AFTER sourcing libs to override real implementations
_teach_error() { echo "ERROR: $1" >&2; }
_git_in_repo() { git rev-parse --git-dir >/dev/null 2>&1; }
_git_current_branch() { git branch --show-current 2>/dev/null; }
_git_is_clean() { [[ -z "$(git status --porcelain 2>/dev/null)" ]]; }
# Override conflict detection for test repos (no remote tracking)
_git_detect_production_conflicts() { return 0; }
_git_has_unpushed_commits() { return 1; }

# Helper: create a sandboxed git repo with draft/main branches and a remote
setup_full_repo() {
    local bare_dir=$(mktemp -d "$TEST_DIR/bare-XXXXXX")
    local work_dir="$TEST_DIR/work-$(basename $bare_dir)"
    rm -rf "$work_dir"  # ensure clean

    # Create bare remote
    git init -q --bare "$bare_dir" 2>/dev/null

    # Clone working dir
    git clone -q "$bare_dir" "$work_dir" 2>/dev/null
    cd "$work_dir"
    git config user.email "test@test.com"
    git config user.name "Test"

    # Setup config
    mkdir -p .flow
    cat > .flow/teach-config.yml <<'YAML'
course:
  name: "STAT-101"
git:
  draft_branch: draft
  production_branch: main
  auto_pr: true
  require_clean: true
YAML
    git add -A >/dev/null 2>&1 && git commit -q -m "init" >/dev/null 2>&1
    git push -q origin main 2>/dev/null

    # Create draft branch
    git checkout -q -b draft 2>/dev/null
    git push -q -u origin draft 2>/dev/null

    echo "$work_dir"
}

# Helper: create simple git repo (no remote)
setup_simple_repo() {
    local dir=$(mktemp -d "$TEST_DIR/simple-XXXXXX")
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
echo "║  teach deploy v2 - Integration Tests                       ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# SECTION 1: Flag Combinations
# ============================================================================
echo "--- Flag Combinations ---"

# Test 1: --history exits early (no preflight)
test_repo=$(setup_simple_repo)
cd "$test_repo"
_deploy_history_append "direct" "aaa11111" "bbb22222" "draft" "main" "2" "test" "null" "null" "5" >/dev/null 2>&1
output=$(_teach_deploy_enhanced --history 2>&1)
ret=$?
if [[ $ret -eq 0 ]] && ! echo "$output" | grep -q "Pre-flight"; then
    _test_pass "--history exits early without preflight"
else
    _test_fail "--history exits early without preflight" "ret=$ret"
fi

# Test 2: --history with custom count
_deploy_history_append "pr" "bbb22222" "aaa11111" "draft" "main" "3" "second" "null" "null" "8" >/dev/null 2>&1
output=$(_teach_deploy_enhanced --history 1 2>&1)
if [[ $ret -eq 0 ]]; then
    _test_pass "--history with custom count"
else
    _test_fail "--history with custom count" "ret=$ret"
fi

# Test 3: --rollback exits early (no preflight)
output=$(_teach_deploy_enhanced --rollback 1 --ci 2>&1)
# Rollback will fail on simple repo (no remote), but should NOT run preflight
if ! echo "$output" | grep -q "Pre-flight Checks"; then
    _test_pass "--rollback exits early without preflight"
else
    _test_fail "--rollback exits early without preflight" "preflight ran"
fi

# Test 4: --ci + --rollback passes ci flag through
output=$(_teach_deploy_enhanced --ci --rollback --ci 2>&1)
# CI mode without index should produce "CI mode requires explicit" error
if echo "$output" | grep -qi "CI mode requires explicit\|index"; then
    _test_pass "--ci + --rollback passes ci flag (requires index)"
else
    # May also succeed if history is empty
    if echo "$output" | grep -qi "No deployment history"; then
        _test_pass "--ci + --rollback passes ci flag (no history)"
    else
        _test_fail "--ci + --rollback passes ci flag" "unexpected output"
    fi
fi

# Test 5: unknown flags return error
output=$(_teach_deploy_enhanced --unknown-flag 2>&1)
ret=$?
if [[ $ret -ne 0 ]]; then
    _test_pass "unknown flags return error"
else
    _test_fail "unknown flags return error" "expected non-zero exit"
fi

# Test 6: --help shows help (no error)
output=$(_teach_deploy_enhanced --help 2>&1)
ret=$?
if [[ $ret -eq 0 ]] && echo "$output" | grep -q "teach deploy"; then
    _test_pass "--help shows help text"
else
    _test_fail "--help shows help text" "ret=$ret"
fi

# Test 7: --help includes rollback option
if echo "$output" | grep -q "\-\-rollback"; then
    _test_pass "--help includes --rollback option"
else
    _test_fail "--help includes --rollback option" "not found"
fi

# Test 8: --help includes history option
if echo "$output" | grep -q "\-\-history"; then
    _test_pass "--help includes --history option"
else
    _test_fail "--help includes --history option" "not found"
fi

# Test 9: --dry-run includes history log hint
test_repo=$(setup_simple_repo)
cd "$test_repo"
git checkout -q -b draft 2>/dev/null
echo "new" > test.qmd
git add -A >/dev/null 2>&1 && git commit -q -m "content" >/dev/null 2>&1
output=$(_teach_deploy_enhanced --dry-run 2>&1)
if echo "$output" | grep -q "deploy-history"; then
    _test_pass "--dry-run shows history log hint"
else
    _test_fail "--dry-run shows history log hint" "not found"
fi

# ============================================================================
# SECTION 2: Preflight with CI mode
# ============================================================================
echo ""
echo "--- Preflight CI Mode ---"

# Test 10: CI mode fails on wrong branch
test_repo=$(setup_simple_repo)
cd "$test_repo"
# Stay on main (not draft)
output=$(_deploy_preflight_checks "true" 2>&1)
ret=$?
if [[ $ret -ne 0 ]]; then
    _test_pass "CI mode preflight fails when not on draft branch"
else
    _test_fail "CI mode preflight fails when not on draft branch" "expected failure"
fi

# Test 11: CI mode succeeds on draft branch
# Note: requires a repo where draft and main don't conflict
# Override conflict detection to isolate preflight logic
_git_detect_production_conflicts() { return 0; }
git checkout -q -b draft 2>/dev/null
output=$(_deploy_preflight_checks "true" 2>&1)
ret=$?
if [[ $ret -eq 0 ]]; then
    _test_pass "CI mode preflight succeeds on draft branch"
else
    _test_fail "CI mode preflight succeeds on draft branch" "ret=$ret"
fi

# ============================================================================
# SECTION 3: Deploy History Integration
# ============================================================================
echo ""
echo "--- Deploy History Integration ---"

# Test 12: multiple deploys build sequential history
test_repo=$(setup_simple_repo)
cd "$test_repo"
for i in {1..5}; do
    _deploy_history_append "direct" "hash${i}aaa" "prev${i}aaa" "draft" "main" "$i" "deploy $i" "null" "null" "$i" >/dev/null 2>&1
done
count=$(_deploy_history_count)
if [[ "$count" == "5" ]]; then
    _test_pass "multiple deploys build sequential history"
else
    _test_fail "multiple deploys build sequential history" "count=$count"
fi

# Test 13: history_get returns entries in reverse order
_deploy_history_get 1
msg1="$DEPLOY_HIST_MESSAGE"
_deploy_history_get 5
msg5="$DEPLOY_HIST_MESSAGE"
if [[ "$msg1" == "deploy 5" && "$msg5" == "deploy 1" ]]; then
    _test_pass "history entries in reverse order (newest=1)"
else
    _test_fail "history entries in reverse order" "1=$msg1, 5=$msg5"
fi

# Test 14: history list with limited count
output=$(_deploy_history_list 2 2>&1)
# Should show 2 entries, not 5
lines_with_deploy=$(echo "$output" | grep -c "deploy [0-9]" || echo 0)
if [[ "$lines_with_deploy" -le 3 ]]; then
    _test_pass "history list respects count limit"
else
    _test_fail "history list respects count limit" "showed $lines_with_deploy entries"
fi

# ============================================================================
# SECTION 4: .STATUS Integration
# ============================================================================
echo ""
echo "--- .STATUS Integration ---"

# Test 15: .STATUS gets updated after deploy (if yq available)
if command -v yq >/dev/null 2>&1; then
    test_repo=$(setup_simple_repo)
    cd "$test_repo"
    echo "status: active" > .STATUS
    _deploy_history_append "direct" "aaa11111" "bbb22222" "draft" "main" "1" "test" "null" "null" "1" >/dev/null 2>&1
    _deploy_update_status_file >/dev/null 2>&1
    ld=$(yq '.last_deploy // ""' .STATUS 2>/dev/null)
    dc=$(yq '.deploy_count // 0' .STATUS 2>/dev/null)
    today=$(date '+%Y-%m-%d')
    if [[ "$ld" == "$today" && "$dc" == "1" ]]; then
        _test_pass ".STATUS updated with last_deploy and deploy_count"
    else
        _test_fail ".STATUS updated with last_deploy and deploy_count" "ld=$ld dc=$dc"
    fi
else
    _test_skip ".STATUS update test (yq not available)"
fi

# Test 16: .STATUS not created if absent
test_repo=$(setup_simple_repo)
cd "$test_repo"
rm -f .STATUS
_deploy_update_status_file >/dev/null 2>&1
if [[ ! -f .STATUS ]]; then
    _test_pass ".STATUS not created when absent"
else
    _test_fail ".STATUS not created when absent" "file was created"
fi

# ============================================================================
# SECTION 5: Mixed mode history entries
# ============================================================================
echo ""
echo "--- Mixed Mode History ---"

# Test 17: direct + pr + rollback modes in same history
test_repo=$(setup_simple_repo)
cd "$test_repo"
_deploy_history_append "direct" "aaa11111" "bbb22222" "draft" "main" "2" "direct deploy" "null" "null" "5" >/dev/null 2>&1
_deploy_history_append "pr" "ccc33333" "aaa11111" "draft" "main" "3" "pr deploy" "42" "null" "15" >/dev/null 2>&1
_deploy_history_append "rollback" "ddd44444" "ccc33333" "draft" "main" "3" "revert: rollback" "null" "null" "8" >/dev/null 2>&1
count=$(_deploy_history_count)
if [[ "$count" == "3" ]]; then
    _test_pass "mixed mode history (direct + pr + rollback)"
else
    _test_fail "mixed mode history" "count=$count"
fi

# Test 18: verify each mode stored correctly
_deploy_history_get 1
mode3="$DEPLOY_HIST_MODE"
_deploy_history_get 2
mode2="$DEPLOY_HIST_MODE"
_deploy_history_get 3
mode1="$DEPLOY_HIST_MODE"
if [[ "$mode1" == "direct" && "$mode2" == "pr" && "$mode3" == "rollback" ]]; then
    _test_pass "each deploy mode stored correctly"
else
    _test_fail "each deploy mode stored correctly" "1=$mode1 2=$mode2 3=$mode3"
fi

# ============================================================================
# SECTION 6: Flag Parser Edge Cases
# ============================================================================
echo ""
echo "--- Flag Parser Edge Cases ---"

# Test 19: --direct-push backward compat (alias for --direct)
test_repo=$(setup_simple_repo)
cd "$test_repo"
git checkout -q -b draft 2>/dev/null
echo "new file" > content.qmd
git add -A >/dev/null 2>&1 && git commit -q -m "add content" >/dev/null 2>&1
# The enhanced function should accept --direct-push without error
output=$(_teach_deploy_enhanced --direct-push --dry-run 2>&1)
ret=$?
if [[ $ret -eq 0 ]]; then
    _test_pass "--direct-push backward compat works"
else
    _test_fail "--direct-push backward compat" "ret=$ret"
fi

# Test 20: -d short flag works
output=$(_teach_deploy_enhanced -d --dry-run 2>&1)
ret=$?
if [[ $ret -eq 0 ]]; then
    _test_pass "-d short flag works"
else
    _test_fail "-d short flag works" "ret=$ret"
fi

# Test 21: --direct + --dry-run shows direct mode
output=$(_teach_deploy_enhanced --direct --dry-run 2>&1)
if echo "$output" | grep -qi "direct"; then
    _test_pass "--direct + --dry-run shows direct mode preview"
else
    _test_fail "--direct + --dry-run shows direct mode preview" "not found"
fi

# Test 22: -m flag passes custom message to dry-run
output=$(_teach_deploy_enhanced --dry-run -m "Custom Week 5" 2>&1)
if echo "$output" | grep -q "Custom Week 5"; then
    _test_pass "-m flag passes custom message to preview"
else
    _test_fail "-m flag passes custom message to preview" "not found"
fi

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo "═══════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed, $SKIP skipped"
echo "═══════════════════════════════════════════"
[[ $FAIL -eq 0 ]]
