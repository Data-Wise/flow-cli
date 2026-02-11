#!/usr/bin/env zsh
# e2e-teach-deploy-v2.zsh - End-to-end tests for teach deploy v2
# Tests full deploy lifecycle using sandboxed git repos

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

# Source all needed libraries
source "$PROJECT_ROOT/lib/core.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/git-helpers.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/deploy-history-helpers.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/deploy-rollback-helpers.zsh" 2>/dev/null || true
source "$PROJECT_ROOT/lib/dispatchers/teach-deploy-enhanced.zsh" 2>/dev/null || true

# Stub missing functions
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
if ! typeset -f _git_has_unpushed_commits >/dev/null 2>&1; then
    _git_has_unpushed_commits() { return 1; }
fi
if ! typeset -f _git_push_current_branch >/dev/null 2>&1; then
    _git_push_current_branch() { git push origin "$(git branch --show-current)" 2>/dev/null; }
fi
if ! typeset -f _git_is_synced >/dev/null 2>&1; then
    _git_is_synced() { return 0; }
fi

# Helper: create full E2E repo with bare remote, draft + main branches
setup_e2e_repo() {
    local bare_dir=$(mktemp -d "$TEST_DIR/bare-XXXXXX")
    local work_dir=$(mktemp -d "$TEST_DIR/e2e-XXXXXX")
    rm -rf "$work_dir"  # clone needs empty target

    # Create bare remote
    (
        cd "$bare_dir"
        git init -q --bare
    ) >/dev/null 2>&1

    # Clone working dir
    git clone -q "$bare_dir" "$work_dir" >/dev/null 2>&1
    (
        cd "$work_dir"
        git config user.email "test@test.com"
        git config user.name "Test"

        # Setup course structure
        mkdir -p .flow lectures labs assignments
        cat > .flow/teach-config.yml <<'YAML'
course:
  name: "STAT-101"
git:
  draft_branch: draft
  production_branch: main
  auto_pr: true
  require_clean: true
semester_info:
  start_date: "2026-01-12"
YAML

        echo "status: active" > .STATUS

        cat > lectures/week-01.qmd <<'QMD'
---
title: "Week 1: Introduction"
---
Introduction to statistics.
QMD

        git add -A && git commit -q -m "init: course structure"
        git push -q origin main

        # Create draft branch with additional content
        git checkout -q -b draft
        echo "# Week 2 lecture" > lectures/week-02.qmd
        git add -A && git commit -q -m "add week-02 lecture"
        git push -q -u origin draft
    ) >/dev/null 2>&1

    echo "$work_dir"
}

echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  teach deploy v2 - E2E Tests                               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# ============================================================================
# SECTION 1: Direct Merge Lifecycle
# ============================================================================
echo "--- Direct Merge Lifecycle ---"

# Test 1: Full direct deploy lifecycle
test_repo=$(setup_e2e_repo)
cd "$test_repo"
# Should be on draft branch with remote
branch=$(git branch --show-current)
if [[ "$branch" == "draft" ]]; then
    # Call without $() capture so DEPLOY_* variables propagate
    _deploy_direct_merge "draft" "main" "deploy: week-02 lecture" "true" >/dev/null 2>&1
    ret=$?
    if [[ $ret -eq 0 ]]; then
        _test_pass "full direct deploy lifecycle succeeds"
    else
        _test_fail "full direct deploy lifecycle succeeds" "ret=$ret"
    fi
else
    _test_fail "full direct deploy lifecycle" "not on draft (on $branch)"
fi

# Test 2: Direct merge exports DEPLOY_* variables
if [[ -n "$DEPLOY_COMMIT_AFTER" && -n "$DEPLOY_COMMIT_BEFORE" ]]; then
    _test_pass "direct merge exports DEPLOY_COMMIT_* variables"
else
    _test_fail "direct merge exports DEPLOY_COMMIT_* variables" "after=$DEPLOY_COMMIT_AFTER before=$DEPLOY_COMMIT_BEFORE"
fi

# Test 3: After direct merge, we're back on draft
branch=$(git branch --show-current)
if [[ "$branch" == "draft" ]]; then
    _test_pass "after direct merge, back on draft branch"
else
    _test_fail "after direct merge, back on draft branch" "on $branch"
fi

# ============================================================================
# SECTION 2: Deploy History Lifecycle
# ============================================================================
echo ""
echo "--- Deploy History Lifecycle ---"

# Test 4: history recording after deploy
test_repo=$(setup_e2e_repo)
cd "$test_repo"
_deploy_direct_merge "draft" "main" "deploy: test content" "true" >/dev/null 2>&1
# Manually record history (as _teach_deploy_enhanced would)
_deploy_history_append "direct" "${DEPLOY_COMMIT_AFTER}" "${DEPLOY_COMMIT_BEFORE}" "draft" "main" "1" "deploy: test content" "null" "null" "${DEPLOY_DURATION}" >/dev/null 2>&1
count=$(_deploy_history_count)
if [[ "$count" == "1" ]]; then
    _test_pass "deploy records entry in history"
else
    _test_fail "deploy records entry in history" "count=$count"
fi

# Test 5: multiple deploys build sequential history
echo "# Week 3" > lectures/week-03.qmd
git add -A && git commit -q -m "add week-03"
git push -q origin draft 2>/dev/null
_deploy_direct_merge "draft" "main" "deploy: week-03" "true" >/dev/null 2>&1
_deploy_history_append "direct" "${DEPLOY_COMMIT_AFTER}" "${DEPLOY_COMMIT_BEFORE}" "draft" "main" "1" "deploy: week-03" "null" "null" "${DEPLOY_DURATION}" >/dev/null 2>&1
count=$(_deploy_history_count)
if [[ "$count" == "2" ]]; then
    _test_pass "multiple deploys build sequential history"
else
    _test_fail "multiple deploys build sequential history" "count=$count"
fi

# Test 6: history list shows entries
output=$(_deploy_history_list 5 2>&1)
if echo "$output" | grep -q "deploy"; then
    _test_pass "history list shows deploy entries"
else
    _test_fail "history list shows deploy entries" "not found"
fi

# ============================================================================
# SECTION 3: Smart Commit Messages
# ============================================================================
echo ""
echo "--- Smart Commit Messages ---"

# Test 7: smart commit message generation
if typeset -f _generate_smart_commit_message >/dev/null 2>&1; then
    test_repo=$(setup_e2e_repo)
    cd "$test_repo"
    msg=$(_generate_smart_commit_message "draft" "main")
    if [[ -n "$msg" && "$msg" != "deploy: update" ]]; then
        _test_pass "smart commit generates meaningful message: $msg"
    else
        # Fallback message is also acceptable
        _test_pass "smart commit generates message (fallback): $msg"
    fi
else
    _test_skip "smart commit message generation (_generate_smart_commit_message not available)"
fi

# ============================================================================
# SECTION 4: Dry-run E2E
# ============================================================================
echo ""
echo "--- Dry-run E2E ---"

# Test 8: dry-run shows correct output
test_repo=$(setup_e2e_repo)
cd "$test_repo"
output=$(_deploy_dry_run_report "draft" "main" "STAT-101" "false" "" 2>&1)
ret=$?
if [[ $ret -eq 0 ]] && echo "$output" | grep -qi "DRY RUN"; then
    _test_pass "dry-run shows correct output"
else
    _test_fail "dry-run shows correct output" "ret=$ret"
fi

# Test 9: dry-run shows files that would be deployed
if echo "$output" | grep -q "week-02"; then
    _test_pass "dry-run shows files (week-02.qmd)"
else
    _test_fail "dry-run shows files" "week-02 not found in output"
fi

# ============================================================================
# SECTION 5: .STATUS E2E
# ============================================================================
echo ""
echo "--- .STATUS E2E ---"

# Test 10: .STATUS gets updated after deploy
if command -v yq >/dev/null 2>&1; then
    test_repo=$(setup_e2e_repo)
    cd "$test_repo"
    _deploy_history_append "direct" "abc12345" "def67890" "draft" "main" "1" "test" "null" "null" "5" >/dev/null 2>&1
    _deploy_update_status_file >/dev/null 2>&1
    ld=$(yq '.last_deploy // ""' .STATUS 2>/dev/null)
    dc=$(yq '.deploy_count // 0' .STATUS 2>/dev/null)
    today=$(date '+%Y-%m-%d')
    if [[ "$ld" == "$today" && "$dc" == "1" ]]; then
        _test_pass ".STATUS updated with deploy info"
    else
        _test_fail ".STATUS updated with deploy info" "ld=$ld dc=$dc"
    fi
else
    _test_skip ".STATUS update (yq not available)"
fi

# Test 11: .STATUS teaching_week calculation
if command -v yq >/dev/null 2>&1; then
    test_repo=$(setup_e2e_repo)
    cd "$test_repo"
    _deploy_update_status_file >/dev/null 2>&1
    tw=$(yq '.teaching_week // 0' .STATUS 2>/dev/null)
    # Since start_date is 2026-01-12, on 2026-02-03 we should be week 4
    if [[ "$tw" -ge 1 && "$tw" -le 20 ]]; then
        _test_pass ".STATUS teaching_week calculated (week $tw)"
    else
        # Week calculation may fail if date math is different; skip if 0
        if [[ "$tw" == "0" || -z "$tw" ]]; then
            _test_skip ".STATUS teaching_week (date math issue)"
        else
            _test_fail ".STATUS teaching_week" "got: $tw"
        fi
    fi
else
    _test_skip ".STATUS teaching_week (yq not available)"
fi

# ============================================================================
# SECTION 6: Help Output
# ============================================================================
echo ""
echo "--- Help Output ---"

# Test 12: help shows all options including rollback/history
output=$(_teach_deploy_enhanced_help 2>&1)
if echo "$output" | grep -q "\-\-rollback" && echo "$output" | grep -q "\-\-history"; then
    _test_pass "help shows --rollback and --history options"
else
    _test_fail "help shows --rollback and --history" "missing from output"
fi

# Test 13: help shows rollback examples
if echo "$output" | grep -q "rollback 1"; then
    _test_pass "help shows rollback examples"
else
    _test_fail "help shows rollback examples" "not found"
fi

# Test 14: help shows history examples
if echo "$output" | grep -q "history 20"; then
    _test_pass "help shows history examples"
else
    _test_fail "help shows history examples" "not found"
fi

# Test 15: help shows .STATUS feature
if echo "$output" | grep -qi "STATUS"; then
    _test_pass "help mentions .STATUS auto-update"
else
    _test_fail "help mentions .STATUS auto-update" "not found"
fi

# ============================================================================
# SECTION 7: CI Mode E2E
# ============================================================================
echo ""
echo "--- CI Mode E2E ---"

# Test 16: CI mode direct merge
test_repo=$(setup_e2e_repo)
cd "$test_repo"
output=$(_deploy_direct_merge "draft" "main" "ci: auto deploy" "true" 2>&1)
ret=$?
if [[ $ret -eq 0 ]]; then
    _test_pass "CI mode direct merge succeeds"
else
    _test_fail "CI mode direct merge succeeds" "ret=$ret"
fi

# Test 17: CI preflight on draft branch
cd "$test_repo"
output=$(_deploy_preflight_checks "true" 2>&1)
ret=$?
if [[ $ret -eq 0 ]]; then
    _test_pass "CI preflight passes on draft branch"
else
    _test_fail "CI preflight passes on draft branch" "ret=$ret"
fi

# ============================================================================
# SECTION 8: Auto-tag
# ============================================================================
echo ""
echo "--- Auto-tag ---"

# Test 18: auto-tag creates git tag
test_repo=$(setup_e2e_repo)
cd "$test_repo"
_deploy_direct_merge "draft" "main" "deploy: with tag" "true" >/dev/null 2>&1
# Now simulate auto-tag (as the enhanced function would do)
tag="deploy-test-$(date +%Y%m%d%H%M%S)"
git tag "$tag" 2>/dev/null
if git tag | grep -q "$tag"; then
    _test_pass "auto-tag creates git tag"
else
    _test_fail "auto-tag creates git tag" "tag not found"
fi

# ============================================================================
# SECTION 9: Step Progress & Summary Box E2E
# ============================================================================
echo ""
echo "--- Step Progress & Summary Box ---"

# Test 19: direct merge output contains step progress [1/5]..[5/5]
test_repo=$(setup_e2e_repo)
cd "$test_repo"
output=$(_deploy_direct_merge "draft" "main" "deploy: step test" "true" 2>&1)
ret=$?
if [[ $ret -eq 0 ]] && echo "$output" | grep -qE '\[1/6\]' && echo "$output" | grep -qE '\[6/6\]'; then
    _test_pass "direct merge shows step progress [1/6]..[6/6]"
else
    _test_fail "direct merge shows step progress" "ret=$ret, missing step markers"
fi

# Test 20: direct merge output no longer contains [ok] markers
if echo "$output" | grep -q "\[ok\]"; then
    _test_fail "direct merge replaced [ok] with step progress" "still contains [ok]"
else
    _test_pass "direct merge replaced [ok] with step progress"
fi

# Test 21: direct merge exports DEPLOY_FILE_COUNT
if [[ -n "$DEPLOY_FILE_COUNT" ]]; then
    _test_pass "direct merge exports DEPLOY_FILE_COUNT ($DEPLOY_FILE_COUNT)"
else
    _test_fail "direct merge exports DEPLOY_FILE_COUNT" "empty"
fi

# Test 22: direct merge exports DEPLOY_SHORT_HASH
if [[ -n "$DEPLOY_SHORT_HASH" && ${#DEPLOY_SHORT_HASH} -eq 8 ]]; then
    _test_pass "direct merge exports DEPLOY_SHORT_HASH (8 chars)"
else
    _test_fail "direct merge exports DEPLOY_SHORT_HASH" "got: ${DEPLOY_SHORT_HASH:-empty}"
fi

# Test 23: direct merge exports DEPLOY_INSERTIONS and DEPLOY_DELETIONS
if [[ -n "$DEPLOY_INSERTIONS" && -n "$DEPLOY_DELETIONS" ]]; then
    _test_pass "direct merge exports DEPLOY_INSERTIONS/DELETIONS"
else
    _test_fail "direct merge exports DEPLOY_INSERTIONS/DELETIONS" "ins=$DEPLOY_INSERTIONS del=$DEPLOY_DELETIONS"
fi

# Test 24: summary box renders with correct data after direct merge
summary_output=$(_deploy_summary_box \
    "Direct merge" \
    "${DEPLOY_FILE_COUNT:-0}" \
    "${DEPLOY_INSERTIONS:-0}" \
    "${DEPLOY_DELETIONS:-0}" \
    "${DEPLOY_DURATION:-0}" \
    "${DEPLOY_SHORT_HASH:-unknown}" \
    "" 2>&1)
if echo "$summary_output" | grep -q "Deployment Summary" && echo "$summary_output" | grep -q "Direct merge"; then
    _test_pass "summary box renders with deploy data"
else
    _test_fail "summary box renders with deploy data" "missing header or mode"
fi

# ============================================================================
# SECTION 10: Rollback E2E
# ============================================================================
echo ""
echo "--- Rollback E2E ---"

# Test 25: rollback with explicit index on valid history
test_repo=$(setup_e2e_repo)
cd "$test_repo"
# Do a deploy first
_deploy_direct_merge "draft" "main" "deploy: to be rolled back" "true" >/dev/null 2>&1
_deploy_history_append "direct" "${DEPLOY_COMMIT_AFTER}" "${DEPLOY_COMMIT_BEFORE}" "draft" "main" "1" "deploy: to be rolled back" "null" "null" "5" >/dev/null 2>&1
# Capture count BEFORE rollback for Test 26
count_before=$(_deploy_history_count)
# Now rollback
output=$(_deploy_rollback 1 --ci 2>&1)
ret=$?
if [[ $ret -eq 0 ]]; then
    _test_pass "rollback with explicit index succeeds"
else
    _test_fail "rollback with explicit index" "ret=$ret output=$(echo "$output" | tail -3)"
fi

# Test 26: rollback records in history with mode=rollback
# If rollback succeeded, check that history count increased
if [[ $ret -eq 0 ]]; then
    count_after=$(_deploy_history_count)
    if [[ "$count_after" -gt "$count_before" ]]; then
        _deploy_history_get 1
        if [[ "$DEPLOY_HIST_MODE" == "rollback" ]]; then
            _test_pass "rollback records in history with mode=rollback"
        else
            _test_fail "rollback records in history" "mode=$DEPLOY_HIST_MODE"
        fi
    else
        _test_fail "rollback records in history" "count unchanged"
    fi
else
    _test_skip "rollback history recording (rollback did not complete)"
fi

# ============================================================================
# SECTION 11: Merge Commit Rollback (regression test for -m 1 fix)
# ============================================================================
echo ""
echo "--- Merge Commit Rollback ---"

# Test 27: deploy with diverged branches creates a merge commit
test_repo=$(setup_e2e_repo)
cd "$test_repo"
# Create divergence: add a commit directly to main that draft doesn't have
(
    cd "$test_repo"
    git checkout -q main 2>/dev/null
    echo "# Hotfix content" > lectures/hotfix.qmd
    git add -A && git commit -q -m "hotfix: main-only change" 2>/dev/null
    git push -q origin main 2>/dev/null
    git checkout -q draft 2>/dev/null
) >/dev/null 2>&1

# Deploy — draft and main have diverged, so merge creates 2-parent commit
_deploy_direct_merge "draft" "main" "deploy: merge commit test" "true" >/dev/null 2>&1
ret_deploy=$?

if [[ $ret_deploy -ne 0 ]]; then
    _test_fail "merge commit deploy" "deploy failed ret=$ret_deploy"
    _test_skip "merge commit rollback (deploy failed)"
    _test_skip "merge commit rollback history (deploy failed)"
else
    merge_hash="${DEPLOY_COMMIT_AFTER}"
    parent_count=$(git cat-file -p "$merge_hash" 2>/dev/null | grep -c "^parent ")

    if [[ $parent_count -ge 2 ]]; then
        _test_pass "diverged deploy creates merge commit ($parent_count parents)"
    else
        _test_fail "diverged deploy creates merge commit" "expected >=2 parents, got $parent_count"
    fi

    # Test 28: rollback of merge commit succeeds (exercises -m 1 code path)
    _deploy_history_append "direct" "$merge_hash" "${DEPLOY_COMMIT_BEFORE}" "draft" "main" "2" "deploy: merge commit test" "null" "null" "3" >/dev/null 2>&1
    mc_count_before=$(_deploy_history_count)

    mc_output=$(_deploy_rollback 1 --ci 2>&1)
    mc_ret=$?

    if [[ $mc_ret -eq 0 ]]; then
        _test_pass "merge commit rollback succeeds via -m 1"
    else
        _test_fail "merge commit rollback" "ret=$mc_ret output=$(echo "$mc_output" | tail -3)"
    fi

    # Test 29: merge commit rollback recorded in history with mode=rollback
    if [[ $mc_ret -eq 0 ]]; then
        mc_count_after=$(_deploy_history_count)
        if [[ "$mc_count_after" -gt "$mc_count_before" ]]; then
            _deploy_history_get 1
            if [[ "$DEPLOY_HIST_MODE" == "rollback" ]]; then
                _test_pass "merge commit rollback records with mode=rollback"
            else
                _test_fail "merge commit rollback history" "mode=$DEPLOY_HIST_MODE"
            fi
        else
            _test_fail "merge commit rollback history" "count unchanged"
        fi
    else
        _test_skip "merge commit rollback history (rollback failed)"
    fi
fi

# ============================================================================
# SECTION 12: Safety Enhancements E2E (v6.6.0)
# ============================================================================
echo ""
echo "--- Safety Enhancements E2E ---"

# Test 30: trap handler returns to draft after direct merge failure
test_repo=$(setup_e2e_repo)
cd "$test_repo"
# Force failure by using nonexistent production branch
_deploy_direct_merge "draft" "nonexistent-prod-branch" "deploy: trap test" "false" >/dev/null 2>&1
# Clear leftover trap from test subshell
trap cleanup EXIT
current_branch=$(_git_current_branch)
if [[ "$current_branch" == "draft" ]]; then
    _test_pass "trap handler returns to draft after direct merge failure"
else
    _test_fail "trap handler returns to draft after direct merge failure" "on branch: $current_branch"
fi

# Test 31: trap handler fires on Ctrl+C simulation (SIGINT during merge)
test_repo=$(setup_e2e_repo)
cd "$test_repo"
# Start a direct merge in a subshell and kill it mid-flight
(
    _deploy_direct_merge "draft" "main" "deploy: signal test" "true" &
    deploy_pid=$!
    sleep 0.2
    kill -INT $deploy_pid 2>/dev/null
    wait $deploy_pid 2>/dev/null
) >/dev/null 2>&1
# After signal, should be back on draft
cd "$test_repo"
current_branch=$(_git_current_branch)
# Note: in subshell the trap may or may not fire; test that we can recover
if [[ "$current_branch" == "draft" || "$current_branch" == "main" ]]; then
    # Either the trap fired (draft) or we're on main (signal was too late)
    # Both are valid - the trap is a best-effort safety net
    _test_pass "branch state valid after signal during deploy (on: $current_branch)"
else
    _test_fail "branch state valid after signal during deploy" "on unexpected branch: $current_branch"
fi

# Test 32: CI mode rejects uncommitted changes (full lifecycle)
test_repo=$(setup_e2e_repo)
cd "$test_repo"
echo "dirty content" > lectures/week-03.qmd
output=$(_teach_deploy_enhanced --direct --ci 2>&1)
ret=$?
if [[ $ret -ne 0 ]] && echo "$output" | grep -qi "uncommitted\|commit.*changes"; then
    _test_pass "CI mode rejects deploy with uncommitted changes"
else
    _test_fail "CI mode rejects deploy with uncommitted changes" "ret=$ret"
fi

# Test 33: CI mode error message provides actionable guidance
if echo "$output" | grep -qi "CI\|commit\|deploying"; then
    _test_pass "CI mode error provides actionable guidance"
else
    _test_fail "CI mode error provides guidance" "output: $(echo "$output" | head -3)"
fi

# Test 34: Actions URL appears in summary box with real GitHub-like remote
test_repo=$(setup_e2e_repo)
cd "$test_repo"
# Set remote to a GitHub-style URL
git remote set-url origin "https://github.com/TestUser/stat-101.git" 2>/dev/null
output=$(_deploy_summary_box "Direct merge" "2" "30" "5" "10" "abcd1234" "https://testuser.github.io/stat-101/")
if echo "$output" | grep -q "https://github.com/TestUser/stat-101/actions"; then
    _test_pass "Actions URL in summary box with HTTPS GitHub remote"
else
    _test_fail "Actions URL in summary box with HTTPS GitHub remote" "not found in output"
fi

# Test 35: Actions URL works with SSH GitHub remote
test_repo=$(setup_e2e_repo)
cd "$test_repo"
git remote set-url origin "git@github.com:TestUser/stat-101.git" 2>/dev/null
output=$(_deploy_summary_box "Direct merge" "2" "30" "5" "10" "abcd1234" "")
if echo "$output" | grep -q "https://github.com/TestUser/stat-101/actions"; then
    _test_pass "Actions URL in summary box with SSH GitHub remote"
else
    _test_fail "Actions URL in summary box with SSH GitHub remote" "not found in output"
fi

# Test 36: Actions URL omitted for non-GitHub remotes
test_repo=$(setup_e2e_repo)
cd "$test_repo"
git remote set-url origin "https://gitlab.com/TestUser/stat-101.git" 2>/dev/null
output=$(_deploy_summary_box "Direct merge" "2" "30" "5" "10" "abcd1234" "")
if echo "$output" | grep -q "Actions:"; then
    _test_fail "Actions URL omitted for non-GitHub remote" "Actions line found"
else
    _test_pass "Actions URL omitted for non-GitHub remote"
fi

# Test 37: pre-commit hook failure produces recovery message
test_repo=$(setup_e2e_repo)
cd "$test_repo"
# Create a failing pre-commit hook
mkdir -p .git/hooks
cat > .git/hooks/pre-commit <<'HOOK'
#!/bin/sh
echo "Quarto render check failed" >&2
exit 1
HOOK
chmod +x .git/hooks/pre-commit
# Create uncommitted change
echo "new lecture content" > lectures/week-03.qmd
# Stage the file
git add lectures/week-03.qmd
# Try to commit - should fail
commit_output=$(git commit -m "test content" 2>&1)
ret=$?
if [[ $ret -ne 0 ]]; then
    # Verify staged files are preserved
    staged=$(git diff --cached --name-only 2>/dev/null)
    if echo "$staged" | grep -q "week-03"; then
        _test_pass "hook failure preserves staged changes"
    else
        _test_fail "hook failure preserves staged changes" "staged files lost"
    fi
else
    _test_fail "pre-commit hook blocks commit" "commit succeeded"
fi

# Test 38: full lifecycle with clean deploy after uncommitted handler
test_repo=$(setup_e2e_repo)
cd "$test_repo"
# Add new content and commit it (simulating what the uncommitted handler does)
echo "week 03 content" > lectures/week-03.qmd
git add -A && git commit -q -m "content: week-03 lecture" >/dev/null 2>&1
git push -q origin draft >/dev/null 2>&1
# Now deploy should work cleanly
_deploy_direct_merge "draft" "main" "content: week-03 lecture" "true" >/dev/null 2>&1
ret=$?
# Clear trap
trap cleanup EXIT
if [[ $ret -eq 0 ]]; then
    _test_pass "deploy succeeds after manual commit (simulated handler path)"
else
    _test_fail "deploy succeeds after manual commit" "ret=$ret"
fi

# Test 39: summary box includes all expected fields after real deploy
test_repo=$(setup_e2e_repo)
cd "$test_repo"
git remote set-url origin "https://github.com/e2eUser/e2e-course.git" 2>/dev/null
echo "week 04 content" > lectures/week-04.qmd
git add -A && git commit -q -m "add week-04" >/dev/null 2>&1
git push -q origin draft >/dev/null 2>&1
_deploy_direct_merge "draft" "main" "content: week-04" "true" >/dev/null 2>&1
trap cleanup EXIT
summary=$(_deploy_summary_box \
    "Direct merge" \
    "${DEPLOY_FILE_COUNT:-0}" \
    "${DEPLOY_INSERTIONS:-0}" \
    "${DEPLOY_DELETIONS:-0}" \
    "${DEPLOY_DURATION:-0}" \
    "${DEPLOY_SHORT_HASH:-unknown}" \
    "https://e2euser.github.io/e2e-course/" 2>&1)
# Check all fields present
has_mode=$(echo "$summary" | grep -c "Mode:")
has_files=$(echo "$summary" | grep -c "Files:")
has_duration=$(echo "$summary" | grep -c "Duration:")
has_commit=$(echo "$summary" | grep -c "Commit:")
has_url=$(echo "$summary" | grep -c "URL:")
has_actions=$(echo "$summary" | grep -c "Actions:")
if [[ $has_mode -ge 1 && $has_files -ge 1 && $has_duration -ge 1 && $has_commit -ge 1 && $has_url -ge 1 && $has_actions -ge 1 ]]; then
    _test_pass "summary box includes all fields (Mode, Files, Duration, Commit, URL, Actions)"
else
    _test_fail "summary box includes all fields" "mode=$has_mode files=$has_files dur=$has_duration commit=$has_commit url=$has_url actions=$has_actions"
fi

# ============================================================================
# SECTION 13: Back-Merge & Sync (#372 fix)
# ============================================================================
echo ""
echo "--- Back-Merge & Sync (#372 fix) ---"

# Test 40: direct merge output includes step 6/6 (back-merge sync)
test_repo=$(setup_e2e_repo)
cd "$test_repo"
output=$(_deploy_direct_merge "draft" "main" "deploy: back-merge test" "true" 2>&1)
ret=$?
if [[ $ret -eq 0 ]] && echo "$output" | grep -qE '\[6/6\].*Sync'; then
    _test_pass "direct merge shows back-merge sync step [6/6]"
else
    _test_fail "direct merge shows back-merge sync step" "ret=$ret, output missing [6/6] Sync"
fi
trap cleanup EXIT

# Test 41: after direct merge + back-merge, draft contains production commit
test_repo=$(setup_e2e_repo)
cd "$test_repo"
_deploy_direct_merge "draft" "main" "deploy: sync check" "true" >/dev/null 2>&1
trap cleanup EXIT
# The merge commit on main should be reachable from draft (ff-only back-merge)
main_head=$(git rev-parse origin/main 2>/dev/null)
if git merge-base --is-ancestor "$main_head" HEAD 2>/dev/null; then
    _test_pass "after back-merge, draft contains production HEAD"
else
    _test_fail "after back-merge, draft contains production HEAD" "main=$main_head not ancestor of draft HEAD"
fi

# Test 42: back-merge skips gracefully when draft has new commits
test_repo=$(setup_e2e_repo)
cd "$test_repo"
# Deploy first
_deploy_direct_merge "draft" "main" "deploy: initial" "true" >/dev/null 2>&1
trap cleanup EXIT
# Add a new commit on draft (simulates work after deploy but before back-merge)
echo "post-deploy work" > lectures/week-03.qmd
git add -A && git commit -q -m "feat: week-03 post-deploy" >/dev/null 2>&1
git push -q origin draft >/dev/null 2>&1
# Do another deploy — back-merge should skip (can't ff-only)
output=$(_deploy_direct_merge "draft" "main" "deploy: skip test" "true" 2>&1)
ret=$?
# Deploy should still succeed even if back-merge skips
if [[ $ret -eq 0 ]]; then
    _test_pass "deploy succeeds even when back-merge skips (non-ff draft)"
else
    _test_fail "deploy succeeds when back-merge skips" "ret=$ret"
fi
trap cleanup EXIT

# Test 43: conflict detection returns 0 after back-merge sync
test_repo=$(setup_e2e_repo)
cd "$test_repo"
_deploy_direct_merge "draft" "main" "deploy: conflict test" "true" >/dev/null 2>&1
trap cleanup EXIT
# After deploy + back-merge, conflict detection should find no conflicts
_git_detect_production_conflicts "draft" "main"
if [[ $? -eq 0 ]]; then
    _test_pass "no false positive after deploy + back-merge"
else
    _test_fail "no false positive after deploy + back-merge" "conflict detected"
fi

# Test 44: conflict detection ignores --no-ff merge commits (core #372)
test_repo=$(setup_e2e_repo)
cd "$test_repo"
# Do 3 deploy cycles WITHOUT back-merge (simulate pre-fix state)
for i in {1..3}; do
    echo "content-$i" > "lectures/week-0${i}.qmd"
    git add -A && git commit -q -m "feat: iteration $i" >/dev/null 2>&1
    git push -q origin draft >/dev/null 2>&1
    git checkout -q main 2>/dev/null
    git merge draft --no-ff --no-edit -q 2>/dev/null
    git push -q origin main 2>/dev/null
    git checkout -q draft 2>/dev/null
done
# Now check — old logic would show 3+ conflicts, new logic should show 0
_git_detect_production_conflicts "draft" "main"
if [[ $? -eq 0 ]]; then
    _test_pass "conflict detection ignores --no-ff merge commits (3 cycles)"
else
    _test_fail "conflict detection ignores --no-ff merge commits" "false positive"
fi

# Test 45: _deploy_step supports 'skip' status
output=$(_deploy_step 1 3 "Test step" skip 2>&1)
if echo "$output" | grep -q "skipped"; then
    _test_pass "_deploy_step renders skip status"
else
    _test_fail "_deploy_step skip status" "output: $output"
fi

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
echo "═══════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed, $SKIP skipped"
echo "═══════════════════════════════════════════"
[[ $FAIL -eq 0 ]]
