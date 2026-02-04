#!/usr/bin/env zsh
#
# Deploy Rollback Helpers (teach deploy v2)
# Purpose: Forward rollback via git revert with history tracking
#
# Design decisions:
#   - Forward rollback only (git revert) — never destructive git reset
#   - Rollback of a PR deploy pushes a direct revert commit (not a revert PR)
#   - Rollback is recorded in deploy history with mode "rollback"
#   - CI mode requires explicit index (no interactive picker)
#   - On revert conflict, stays on target branch for manual resolution
#
# Functions:
#   _deploy_rollback          - Main rollback with interactive picker
#   _deploy_perform_rollback  - Execute forward rollback via git revert

# ============================================================================
# MAIN ROLLBACK FUNCTION
# ============================================================================

# Rollback a deployment by reverting its commit on production
# Usage: _deploy_rollback [N] [--ci]
# N = display index from history (1 = most recent). If omitted, shows interactive picker.
_deploy_rollback() {
    local target_idx=""
    local ci_mode=false

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --ci) ci_mode=true; shift ;;
            [0-9]*) target_idx="$1"; shift ;;
            *) shift ;;
        esac
    done

    # Source history helpers if not loaded
    if ! typeset -f _deploy_history_list >/dev/null 2>&1; then
        local helper_path="${0:A:h}/deploy-history-helpers.zsh"
        if [[ -f "$helper_path" ]]; then
            source "$helper_path"
        else
            _teach_error "Deploy history helpers not found"
            return 1
        fi
    fi

    # Check history exists
    local total=$(_deploy_history_count)
    if [[ "$total" -eq 0 ]]; then
        echo ""
        echo "${FLOW_COLORS[warn]}  No deployment history found${FLOW_COLORS[reset]}"
        echo "  Deploy first with 'teach deploy' to build history."
        return 1
    fi

    # If no target specified, show interactive picker
    if [[ -z "$target_idx" ]]; then
        if [[ "$ci_mode" == "true" ]]; then
            _teach_error "CI mode requires explicit rollback index: teach deploy --rollback 1"
            return 1
        fi

        _deploy_history_list 5

        echo -n "${FLOW_COLORS[prompt]}  Rollback which deployment? [1]: ${FLOW_COLORS[reset]}"
        read -r target_idx
        [[ -z "$target_idx" ]] && target_idx=1
    fi

    # Validate index
    if [[ ! "$target_idx" =~ ^[0-9]+$ ]] || [[ "$target_idx" -lt 1 ]] || [[ "$target_idx" -gt "$total" ]]; then
        _teach_error "Invalid deployment index: $target_idx" \
            "Use a number between 1 and $total"
        return 1
    fi

    # Get deploy entry
    if ! _deploy_history_get "$target_idx"; then
        _teach_error "Failed to read deployment #$target_idx"
        return 1
    fi

    # Show what we're rolling back
    echo ""
    echo "${FLOW_COLORS[info]}  Rollback Target${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo "  Deploy:  #$target_idx"
    echo "  Mode:    $DEPLOY_HIST_MODE"
    echo "  Commit:  $DEPLOY_HIST_COMMIT"
    echo "  Message: $DEPLOY_HIST_MESSAGE"
    echo "  When:    $DEPLOY_HIST_TIMESTAMP"
    echo ""

    # Confirm (unless CI mode)
    if [[ "$ci_mode" != "true" ]]; then
        echo -n "${FLOW_COLORS[prompt]}  Proceed with rollback? [y/N]: ${FLOW_COLORS[reset]}"
        read -r confirm
        case "$confirm" in
            y|Y|yes|Yes|YES) ;;
            *) echo "  Rollback cancelled."; return 1 ;;
        esac
    fi

    # Perform the rollback
    _deploy_perform_rollback "$DEPLOY_HIST_COMMIT" "$DEPLOY_HIST_BRANCH_TO" "$DEPLOY_HIST_MESSAGE" "$ci_mode"
    return $?
}

# ============================================================================
# ROLLBACK EXECUTION
# ============================================================================

# Execute forward rollback via git revert
# Usage: _deploy_perform_rollback <commit_hash> <branch> <original_message> <ci_mode>
_deploy_perform_rollback() {
    local commit_hash="$1"
    local target_branch="$2"
    local original_message="$3"
    local ci_mode="${4:-false}"
    local start_time=$SECONDS

    local current_branch=$(_git_current_branch)

    echo ""
    echo "${FLOW_COLORS[info]}  Rolling back...${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"

    # Save state for history
    local commit_before=$(git rev-parse HEAD 2>/dev/null)

    # Switch to target branch (usually production)
    if [[ "$current_branch" != "$target_branch" ]]; then
        git checkout "$target_branch" 2>/dev/null || {
            _teach_error "Failed to switch to $target_branch"
            return 1
        }
        echo "${FLOW_COLORS[success]}  [ok]${FLOW_COLORS[reset]} Switched to $target_branch"
    fi

    # Pull latest
    git pull origin "$target_branch" --ff-only 2>/dev/null

    # Find the full commit hash from the short hash
    local full_hash
    full_hash=$(git rev-parse "$commit_hash" 2>/dev/null)
    if [[ -z "$full_hash" ]]; then
        _teach_error "Commit $commit_hash not found"
        git checkout "$current_branch" 2>/dev/null
        return 1
    fi

    # Perform git revert (forward rollback)
    local revert_message="revert: rollback deploy ($original_message)"
    if ! git revert "$full_hash" --no-edit 2>/dev/null; then
        _teach_error "Revert failed — conflicts detected"
        echo ""
        echo "${FLOW_COLORS[dim]}  Tip: Resolve conflicts manually, then commit${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[dim]}  Or abort with: git revert --abort${FLOW_COLORS[reset]}"
        # Don't switch back — let user resolve
        return 1
    fi

    # Amend the revert commit message to be more descriptive
    git commit --amend -m "$revert_message" --no-edit 2>/dev/null
    echo "${FLOW_COLORS[success]}  [ok]${FLOW_COLORS[reset]} Reverted commit $commit_hash"

    # Push to origin
    if ! git push origin "$target_branch" 2>/dev/null; then
        _teach_error "Failed to push revert to origin"
        git checkout "$current_branch" 2>/dev/null
        return 1
    fi
    echo "${FLOW_COLORS[success]}  [ok]${FLOW_COLORS[reset]} Pushed to origin/$target_branch"

    local commit_after=$(git rev-parse HEAD 2>/dev/null)

    # Switch back to original branch
    if [[ "$current_branch" != "$target_branch" ]]; then
        git checkout "$current_branch" 2>/dev/null
        echo "${FLOW_COLORS[success]}  [ok]${FLOW_COLORS[reset]} Back on $current_branch"
    fi

    local elapsed=$(( SECONDS - start_time ))

    # Record rollback in deploy history
    if typeset -f _deploy_history_append >/dev/null 2>&1; then
        local file_count=0
        file_count=$(git diff --name-only "${full_hash}^" "$full_hash" 2>/dev/null | wc -l | tr -d ' ')
        _deploy_history_append \
            "rollback" \
            "$commit_after" \
            "$commit_before" \
            "$current_branch" \
            "$target_branch" \
            "$file_count" \
            "$revert_message" \
            "null" \
            "null" \
            "$elapsed"
    fi

    echo ""
    echo "${FLOW_COLORS[success]}  Rollback complete${FLOW_COLORS[reset]}"
    echo "  Reverted deployment commit $commit_hash in ${elapsed}s"

    # Export for callers
    DEPLOY_COMMIT_BEFORE="$commit_before"
    DEPLOY_COMMIT_AFTER="$commit_after"
    DEPLOY_DURATION="$elapsed"
    DEPLOY_MODE="rollback"

    return 0
}
