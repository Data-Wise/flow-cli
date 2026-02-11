#!/usr/bin/env zsh
#
# Enhanced Deploy Implementation (v5.14.0 - Quarto Workflow Week 5-7)
# Purpose: Partial deployment with dependency tracking and index management
#
# Features:
# - Partial deploys: teach deploy lectures/week-05.qmd
# - Dependency tracking
# - Index management (ADD/UPDATE/REMOVE)
# - Auto-commit + Auto-tag
# - Cross-reference validation
# - CI mode (--ci flag or auto-detect non-TTY)
#

# ============================================================================
# MATH BLANK-LINE DETECTOR (pure ZSH)
# ============================================================================

# Check a single file for blank lines or unclosed $$ display-math blocks.
# Returns: 0 = clean, 1 = blank line inside $$ block, 2 = unclosed $$ block.
# Usage: _check_math_blanks /path/to/file.qmd
_check_math_blanks() {
    setopt LOCAL_OPTIONS EXTENDED_GLOB
    local filepath="$1"
    [[ ! -f "$filepath" ]] && return 0
    local _in_math=0 _line _stripped
    while IFS= read -r _line || [[ -n "$_line" ]]; do
        _stripped="${_line##[[:space:]]#}"
        _stripped="${_stripped%%[[:space:]]#}"
        if [[ "$_stripped" == '$$' ]]; then
            if (( _in_math )); then
                _in_math=0
            else
                _in_math=1
            fi
        elif (( _in_math )) && [[ -z "$_stripped" ]]; then
            return 1
        fi
    done < "$filepath"
    (( _in_math )) && return 2
    return 0
}

# ============================================================================
# SHARED PREFLIGHT CHECKS
# ============================================================================

# Shared preflight checks for all deploy modes
# Returns 0 if all checks pass
# Sets: DEPLOY_DRAFT_BRANCH, DEPLOY_PROD_BRANCH, DEPLOY_COURSE_NAME, DEPLOY_AUTO_PR, DEPLOY_REQUIRE_CLEAN
_deploy_preflight_checks() {
    local ci_mode="${1:-false}"

    # Check if in git repo
    if ! _git_in_repo; then
        _teach_error "Not in a git repository" \
            "Initialize git first with: git init"
        return 1
    fi

    # Check config file
    local config_file=".flow/teach-config.yml"
    if [[ ! -f "$config_file" ]]; then
        _teach_error ".flow/teach-config.yml not found" \
            "Run 'teach init' to create the configuration"
        return 1
    fi

    # Read config (export for caller)
    DEPLOY_DRAFT_BRANCH=$(yq '.git.draft_branch // .branches.draft // "draft"' "$config_file" 2>/dev/null) || DEPLOY_DRAFT_BRANCH="draft"
    DEPLOY_PROD_BRANCH=$(yq '.git.production_branch // .branches.production // "main"' "$config_file" 2>/dev/null) || DEPLOY_PROD_BRANCH="main"
    DEPLOY_AUTO_PR=$(yq '.git.auto_pr // true' "$config_file" 2>/dev/null) || DEPLOY_AUTO_PR="true"
    DEPLOY_REQUIRE_CLEAN=$(yq '.git.require_clean // true' "$config_file" 2>/dev/null) || DEPLOY_REQUIRE_CLEAN="true"
    DEPLOY_COURSE_NAME=$(yq '.course.name // "Teaching Project"' "$config_file" 2>/dev/null) || DEPLOY_COURSE_NAME="Teaching Project"

    # Output header
    echo ""
    echo "${FLOW_COLORS[info]}  Pre-flight Checks${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"

    # Check: git repo
    echo "${FLOW_COLORS[success]}  [ok]${FLOW_COLORS[reset]} Git repository"

    # Check: config
    echo "${FLOW_COLORS[success]}  [ok]${FLOW_COLORS[reset]} Config file found"

    # Check: on draft branch
    local current_branch=$(_git_current_branch)
    if [[ "$current_branch" != "$DEPLOY_DRAFT_BRANCH" ]]; then
        if [[ "$ci_mode" == "true" ]]; then
            echo "${FLOW_COLORS[error]}  [!!]${FLOW_COLORS[reset]} Not on $DEPLOY_DRAFT_BRANCH branch (on: $current_branch)"
            _teach_error "Not on $DEPLOY_DRAFT_BRANCH branch (on: $current_branch)" \
                "CI mode cannot switch branches. Ensure correct branch before running."
            return 1
        fi
        echo "${FLOW_COLORS[error]}  [!!]${FLOW_COLORS[reset]} Not on $DEPLOY_DRAFT_BRANCH branch (on: $current_branch)"
        echo ""
        echo -n "${FLOW_COLORS[prompt]}  Switch to $DEPLOY_DRAFT_BRANCH? [Y/n]:${FLOW_COLORS[reset]} "
        read -r switch_confirm
        case "$switch_confirm" in
            n|N|no|No|NO) return 1 ;;
            *)
                git checkout "$DEPLOY_DRAFT_BRANCH" || {
                    _teach_error "Failed to switch to $DEPLOY_DRAFT_BRANCH"
                    return 1
                }
                echo "${FLOW_COLORS[success]}  [ok]${FLOW_COLORS[reset]} Switched to $DEPLOY_DRAFT_BRANCH"
                ;;
        esac
    else
        echo "${FLOW_COLORS[success]}  [ok]${FLOW_COLORS[reset]} On $DEPLOY_DRAFT_BRANCH branch"
    fi

    # Check: working tree status (report only; prompting handled after preflight)
    if ! _git_is_clean; then
        echo "${FLOW_COLORS[warn]}  [--]${FLOW_COLORS[reset]} Working tree has uncommitted changes"
    else
        echo "${FLOW_COLORS[success]}  [ok]${FLOW_COLORS[reset]} Working tree clean"
    fi

    # Check: display math issues (blank lines + unclosed blocks)
    # Only check .qmd files changed between draft and production
    local _math_blanks_files _repo_root
    _repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    _math_blanks_files=$(git diff --name-only "$DEPLOY_PROD_BRANCH".."$DEPLOY_DRAFT_BRANCH" -- '*.qmd' 2>/dev/null)
    if [[ -n "$_math_blanks_files" ]]; then
        local _math_blank_files=() _math_unclosed_files=() _abs_path _qmd_file
        while IFS= read -r _qmd_file; do
            _abs_path="${_repo_root}/${_qmd_file}"
            _check_math_blanks "$_abs_path"
            case $? in
                1) _math_blank_files+=("$_qmd_file") ;;
                2) _math_unclosed_files+=("$_qmd_file") ;;
            esac
        done <<< "$_math_blanks_files"

        local _has_math_issues=0

        if [[ ${#_math_blank_files[@]} -gt 0 ]]; then
            _has_math_issues=1
            echo "${FLOW_COLORS[warn]}  [!!]${FLOW_COLORS[reset]} Blank lines in display math (breaks PDF):"
            for _mf in "${_math_blank_files[@]}"; do
                echo "       ${FLOW_COLORS[dim]}$_mf${FLOW_COLORS[reset]}"
            done
            echo "       ${FLOW_COLORS[dim]}Remove blank lines between \$\$ delimiters in the files above${FLOW_COLORS[reset]}"
        fi

        if [[ ${#_math_unclosed_files[@]} -gt 0 ]]; then
            _has_math_issues=1
            echo "${FLOW_COLORS[warn]}  [!!]${FLOW_COLORS[reset]} Unclosed \$\$ block (breaks render):"
            for _mf in "${_math_unclosed_files[@]}"; do
                echo "       ${FLOW_COLORS[dim]}$_mf${FLOW_COLORS[reset]}"
            done
            echo "       ${FLOW_COLORS[dim]}Add missing closing \$\$ delimiter in the files above${FLOW_COLORS[reset]}"
        fi

        if [[ $_has_math_issues -eq 1 ]]; then
            if [[ "$ci_mode" == "true" ]]; then
                _teach_error "Display math issues detected" \
                    "Fix math block issues in .qmd files before deploying"
                return 1
            fi
        else
            echo "${FLOW_COLORS[success]}  [ok]${FLOW_COLORS[reset]} Display math blocks valid"
        fi
    else
        echo "${FLOW_COLORS[success]}  [ok]${FLOW_COLORS[reset]} Display math blocks valid"
    fi

    # Check: no conflicts with production
    if _git_detect_production_conflicts "$DEPLOY_DRAFT_BRANCH" "$DEPLOY_PROD_BRANCH" 2>/dev/null; then
        echo "${FLOW_COLORS[success]}  [ok]${FLOW_COLORS[reset]} No production conflicts"
    else
        echo "${FLOW_COLORS[warn]}  [!!]${FLOW_COLORS[reset]} Production has new commits"
        if [[ "$ci_mode" == "true" ]]; then
            _teach_error "CI mode: production conflicts detected. Resolve manually."
            return 1
        fi
    fi

    return 0
}

# ============================================================================
# DEPLOY PROGRESS HELPERS
# ============================================================================

# Step progress indicator for deploy operations
# Usage: _deploy_step <step> <total> <label> <status>
# Status: done (green ✓), active (blue ⏳), fail (red ✗)
_deploy_step() {
    local step="$1" total="$2" label="$3" step_status="${4:-pending}"
    case "$step_status" in
        done)    printf "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} [%d/%d] %s\n" "$step" "$total" "$label" ;;
        active)  printf "  ${FLOW_COLORS[info]}⏳${FLOW_COLORS[reset]} [%d/%d] %s\n" "$step" "$total" "$label" ;;
        fail)    printf "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} [%d/%d] %s\n" "$step" "$total" "$label" ;;
        skip)    printf "  ${FLOW_COLORS[warn]}—${FLOW_COLORS[reset]} [%d/%d] %s ${FLOW_COLORS[dim]}(skipped)${FLOW_COLORS[reset]}\n" "$step" "$total" "$label" ;;
    esac
}

# Deployment summary box shown after successful deploy
# Usage: _deploy_summary_box <mode> <file_count> <insertions> <deletions> <duration> <commit_hash> <url>
_deploy_summary_box() {
    local mode="$1"
    local file_count="$2"
    local insertions="$3"
    local deletions="$4"
    local duration="$5"
    local commit_hash="$6"
    local url="$7"
    local width=54

    echo ""
    printf "╭─ Deployment Summary "
    printf '─%.0s' {1..33}
    printf "╮\n"

    printf "│  🚀 %-8s %-42s│\n" "Mode:" "$mode"
    printf "│  📦 %-8s %-42s│\n" "Files:" "${file_count} changed (+${insertions} / -${deletions})"
    printf "│  ⏱  %-8s %-42s│\n" "Duration:" "${duration}s"
    printf "│  🔀 %-8s %-42s│\n" "Commit:" "${commit_hash}"

    if [[ -n "$url" && "$url" != "null" ]]; then
        printf "│  🌐 %-8s %-42s│\n" "URL:" "$url"
    fi

    # GitHub Actions monitoring link
    local repo_slug
    repo_slug=$(git config --get remote.origin.url 2>/dev/null | \
        sed 's|.*github\.com[:/]\(.*\)\.git$|\1|; s|.*github\.com[:/]\(.*\)$|\1|')
    if [[ -n "$repo_slug" && "$repo_slug" != "$(git config --get remote.origin.url 2>/dev/null)" ]]; then
        printf "│  ⚙  %-8s %-42s│\n" "Actions:" "https://github.com/${repo_slug}/actions"
    fi

    printf "╰"
    printf '─%.0s' {1..${width}}
    printf "╯\n"
}

# ============================================================================
# COMMIT FAILURE GUIDANCE (DRY helper)
# ============================================================================

_deploy_commit_failure_guidance() {
    echo ""
    _teach_error "Commit failed (likely pre-commit hook)"
    echo ""
    echo "  ${FLOW_COLORS[dim]}Options:${FLOW_COLORS[reset]}"
    echo "    1. Fix the issues above, then run ${FLOW_COLORS[info]}teach deploy${FLOW_COLORS[reset]} again"
    echo "    2. Skip validation: ${FLOW_COLORS[info]}QUARTO_PRE_COMMIT_RENDER=0 teach deploy ...${FLOW_COLORS[reset]}"
    echo "    3. Force commit: ${FLOW_COLORS[info]}git commit --no-verify -m \"message\"${FLOW_COLORS[reset]}"
    echo ""
    echo "  ${FLOW_COLORS[dim]}Your changes are still staged. Nothing was lost.${FLOW_COLORS[reset]}"
}

# ============================================================================
# DIRECT MERGE MODE
# ============================================================================

# Direct merge mode: merge draft -> production without PR
# Usage: _deploy_direct_merge <draft_branch> <prod_branch> <commit_message> <ci_mode>
# Returns: 0 on success, 1 on failure
# This is the fast path (8-15s vs 45-90s for PR mode)
_deploy_direct_merge() {
    local draft_branch="$1"
    local prod_branch="$2"
    local commit_message="$3"
    local ci_mode="${4:-false}"
    local start_time=$SECONDS

    local total_steps=6

    # Safety: always return to draft branch on error or signal
    trap "git checkout '$draft_branch' 2>/dev/null" EXIT INT TERM

    echo ""
    echo "${FLOW_COLORS[info]}  Direct merge: $draft_branch -> $prod_branch${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"

    # Guard: working tree must be clean before branch switch
    if ! _git_is_clean; then
        _teach_error "Working tree must be clean for direct merge" \
            "Commit or stash changes first"
        return 1
    fi

    # Save the PRODUCTION branch HEAD for rollback reference (not current branch)
    local commit_before=$(git rev-parse "$prod_branch" 2>/dev/null)

    # Ensure draft is pushed to remote first
    local push_err
    push_err=$(git push origin "$draft_branch" 2>&1)
    if [[ $? -ne 0 ]]; then
        # If push fails, might be nothing to push (ok) or real error
        if ! _git_is_synced 2>/dev/null; then
            _teach_error "Failed to push $draft_branch to origin" "$push_err"
            return 1
        fi
    fi
    _deploy_step 1 $total_steps "Push $draft_branch to origin" done

    # Switch to production branch
    local checkout_err
    checkout_err=$(git checkout "$prod_branch" 2>&1) || {
        _deploy_step 2 $total_steps "Switch to $prod_branch" fail
        _teach_error "Failed to switch to $prod_branch" "$checkout_err"
        return 1
    }
    _deploy_step 2 $total_steps "Switch to $prod_branch" done

    # Pull latest production
    local pull_err
    pull_err=$(git pull origin "$prod_branch" --ff-only 2>&1) || {
        # If ff-only fails, try regular pull
        pull_err=$(git pull origin "$prod_branch" 2>&1) || {
            _teach_error "Failed to pull latest $prod_branch" "$pull_err"
            git checkout "$draft_branch" >/dev/null 2>&1
            return 1
        }
    }

    # Merge draft into production
    local merge_err
    merge_err=$(git merge "$draft_branch" --no-edit -m "$commit_message" 2>&1)
    if [[ $? -ne 0 ]]; then
        _teach_error "Merge conflict! Aborting merge." "$merge_err"
        git merge --abort 2>/dev/null
        git checkout "$draft_branch" >/dev/null 2>&1
        echo ""
        echo "${FLOW_COLORS[dim]}  Tip: Resolve conflicts manually or use PR mode${FLOW_COLORS[reset]}"
        return 1
    fi
    _deploy_step 3 $total_steps "Merge $draft_branch into $prod_branch" done

    # Push production to origin
    local push_prod_err
    push_prod_err=$(git push origin "$prod_branch" 2>&1)
    if [[ $? -ne 0 ]]; then
        _teach_error "Failed to push $prod_branch to origin" "$push_prod_err"
        git checkout "$draft_branch" >/dev/null 2>&1
        return 1
    fi
    _deploy_step 4 $total_steps "Push to origin/$prod_branch" done

    # Get the new commit hash
    local commit_after=$(git rev-parse HEAD 2>/dev/null)

    # Switch back to draft branch
    git checkout "$draft_branch" >/dev/null 2>&1 || {
        _deploy_step 5 $total_steps "Switch back to $draft_branch" fail
        _teach_error "Warning: Failed to switch back to $draft_branch"
    }
    _deploy_step 5 $total_steps "Switch back to $draft_branch" done

    # Back-merge: keep draft in sync with production (prevents #372 recurrence)
    git fetch origin "$prod_branch" --quiet 2>/dev/null
    if git merge "origin/$prod_branch" --ff-only 2>/dev/null; then
        _deploy_step 6 $total_steps "Sync $draft_branch with $prod_branch" done
    else
        _deploy_step 6 $total_steps "Sync $draft_branch with $prod_branch" skip
        echo "       ${FLOW_COLORS[dim]}Draft has new commits — run 'teach deploy --sync' later${FLOW_COLORS[reset]}"
    fi

    local elapsed=$(( SECONDS - start_time ))

    # Collect diff stats for summary
    local _diff_stat _insertions _deletions _file_ct
    _diff_stat=$(git diff --stat "$commit_before".."$commit_after" 2>/dev/null | tail -1)
    _file_ct=$(echo "$_diff_stat" | grep -oE '[0-9]+ files?' | grep -oE '[0-9]+' || echo "0")
    _insertions=$(echo "$_diff_stat" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo "0")
    _deletions=$(echo "$_diff_stat" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || echo "0")
    local _short_hash=$(git rev-parse --short=8 "$commit_after" 2>/dev/null)

    # Export for history tracking
    DEPLOY_COMMIT_BEFORE="$commit_before"
    DEPLOY_COMMIT_AFTER="$commit_after"
    DEPLOY_DURATION="$elapsed"
    DEPLOY_MODE="direct"
    DEPLOY_FILE_COUNT="${_file_ct:-0}"
    DEPLOY_INSERTIONS="${_insertions:-0}"
    DEPLOY_DELETIONS="${_deletions:-0}"
    DEPLOY_SHORT_HASH="${_short_hash}"

    # Clear trap before normal return (don't interfere with caller)
    trap - EXIT INT TERM
    return 0
}

# ============================================================================
# DRY-RUN REPORT
# ============================================================================

# Dry-run report: preview deploy without executing
# Usage: _deploy_dry_run_report <draft_branch> <prod_branch> <course_name> <direct_mode> <commit_message>
_deploy_dry_run_report() {
    local draft_branch="$1"
    local prod_branch="$2"
    local course_name="$3"
    local direct_mode="${4:-false}"
    local commit_message="${5:-}"

    echo ""
    echo "${FLOW_COLORS[warn]}  DRY RUN — No changes will be made${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"

    # Show files that would be deployed
    local files_changed
    files_changed=$(git diff --name-status "$prod_branch"..."$draft_branch" 2>/dev/null)

    if [[ -n "$files_changed" ]]; then
        local file_count=$(echo "$files_changed" | wc -l | tr -d ' ')
        echo ""
        echo "  Would deploy $file_count files:"

        while IFS=$'\t' read -r fstatus file; do
            case "$fstatus" in
                M)  echo "    ${FLOW_COLORS[warn]}M${FLOW_COLORS[reset]} $file" ;;
                A)  echo "    ${FLOW_COLORS[success]}A${FLOW_COLORS[reset]} $file" ;;
                D)  echo "    ${FLOW_COLORS[error]}D${FLOW_COLORS[reset]} $file" ;;
                R*) echo "    ${FLOW_COLORS[info]}R${FLOW_COLORS[reset]} $file" ;;
                *)  echo "    $fstatus $file" ;;
            esac
        done <<< "$files_changed"
    else
        echo ""
        echo "  No changes to deploy."
        return 0
    fi

    # Show commit message
    echo ""
    if [[ -n "$commit_message" ]]; then
        echo "  Would commit: \"$commit_message\""
    elif typeset -f _generate_smart_commit_message >/dev/null 2>&1; then
        local smart_msg=$(_generate_smart_commit_message "$draft_branch" "$prod_branch")
        echo "  Would commit: \"$smart_msg\""
    else
        echo "  Would commit: \"deploy: $course_name update\""
    fi

    # Show mode
    echo ""
    if [[ "$direct_mode" == "true" ]]; then
        echo "  Would merge: $draft_branch -> $prod_branch (direct mode)"
    else
        echo "  Would create: PR from $draft_branch -> $prod_branch"
    fi

    # Show history entry
    local deploy_count=0
    if typeset -f _deploy_history_count >/dev/null 2>&1; then
        deploy_count=$(_deploy_history_count)
    fi
    local next_num=$(( deploy_count + 1 ))
    echo "  Would log: deploy #$next_num to .flow/deploy-history.yml"

    # Show .STATUS update hint
    if [[ -f ".STATUS" ]]; then
        echo "  Would update: .STATUS"
    fi

    echo ""
    echo "${FLOW_COLORS[dim]}  Run without --dry-run to execute${FLOW_COLORS[reset]}"

    return 0
}

# ============================================================================
# .STATUS FILE UPDATE
# ============================================================================

# Update .STATUS file after deployment
# Sets deploy_count, last_deploy, and teaching_week (if determinable)
_deploy_update_status_file() {
    local status_file=".STATUS"
    [[ ! -f "$status_file" ]] && return 0  # Non-destructive: skip if absent

    local deploy_count
    if typeset -f _deploy_history_count >/dev/null 2>&1; then
        deploy_count=$(_deploy_history_count)
    else
        deploy_count=""
    fi

    # Update last_deploy
    if command -v yq >/dev/null 2>&1; then
        local today=$(date '+%Y-%m-%d')
        yq -i ".last_deploy = \"$today\"" "$status_file" 2>/dev/null
        if [[ -n "$deploy_count" ]]; then
            yq -i ".deploy_count = $deploy_count" "$status_file" 2>/dev/null
        fi

        # Attempt teaching_week from semester_info.start_date
        local start_date
        start_date=$(yq '.semester_info.start_date // ""' .flow/teach-config.yml 2>/dev/null)
        if [[ -n "$start_date" && "$start_date" != "null" ]]; then
            local start_epoch today_epoch week_num
            start_epoch=$(date -j -f "%Y-%m-%d" "$start_date" "+%s" 2>/dev/null)
            today_epoch=$(date "+%s")
            if [[ -n "$start_epoch" ]]; then
                week_num=$(( (today_epoch - start_epoch) / 604800 + 1 ))
                if [[ $week_num -ge 1 && $week_num -le 20 ]]; then
                    yq -i ".teaching_week = $week_num" "$status_file" 2>/dev/null
                fi
            fi
        fi

        echo "  ${FLOW_COLORS[dim]}.STATUS updated${FLOW_COLORS[reset]}"
    fi
}

# ============================================================================
# ENHANCED TEACH DEPLOY - WITH PARTIAL DEPLOYMENT SUPPORT
# ============================================================================

_teach_deploy_enhanced() {
    local direct_push=false
    local partial_deploy=false
    local deploy_files=()
    local auto_commit=false
    local auto_tag=false
    local skip_index=false
    local check_prereqs=false
    local ci_mode=false
    local custom_message=""
    local dry_run=false

    # Auto-detect CI mode: no TTY means non-interactive
    if [[ ! -t 0 ]]; then
        ci_mode=true
    fi

    # Parse flags and files
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --ci)
                ci_mode=true
                shift
                ;;
            --direct|-d|--direct-push)
                direct_push=true
                shift
                ;;
            --message|-m)
                shift
                custom_message="$1"
                shift
                ;;
            --auto-commit)
                auto_commit=true
                shift
                ;;
            --auto-tag)
                auto_tag=true
                shift
                ;;
            --skip-index)
                skip_index=true
                shift
                ;;
            --check-prereqs|--check-prerequisites)
                check_prereqs=true
                shift
                ;;
            --dry-run|--preview)
                dry_run=true
                shift
                ;;
            --rollback)
                shift
                local rollback_idx=""
                # Check if next arg is a number (optional index)
                if [[ $# -gt 0 && "$1" =~ ^[0-9]+$ ]]; then
                    rollback_idx="$1"
                    shift
                fi
                # Dispatch to rollback immediately (no preflight needed)
                if [[ "$ci_mode" == "true" ]]; then
                    _deploy_rollback "$rollback_idx" --ci
                else
                    _deploy_rollback "$rollback_idx"
                fi
                return $?
                ;;
            --history)
                shift
                local history_count=10
                if [[ $# -gt 0 && "$1" =~ ^[0-9]+$ ]]; then
                    history_count="$1"
                    shift
                fi
                _deploy_history_list "$history_count"
                return $?
                ;;
            --sync)
                shift
                # Quick branch sync: merge production into draft (ff-only first, then regular)
                local _sync_config=".flow/teach-config.yml"
                local _sync_prod
                _sync_prod=$(yq '.git.production_branch // .branches.production // "main"' "$_sync_config" 2>/dev/null) || _sync_prod="main"
                echo ""
                echo "${FLOW_COLORS[info]}  Syncing with $_sync_prod...${FLOW_COLORS[reset]}"
                git fetch origin "$_sync_prod" --quiet 2>/dev/null
                if git merge "origin/$_sync_prod" --ff-only 2>/dev/null; then
                    echo "${FLOW_COLORS[success]}  [ok]${FLOW_COLORS[reset]} Fast-forward sync with $_sync_prod"
                elif git merge "origin/$_sync_prod" --no-edit 2>/dev/null; then
                    echo "${FLOW_COLORS[success]}  [ok]${FLOW_COLORS[reset]} Merged $_sync_prod (merge commit created)"
                else
                    _teach_error "Sync failed — merge conflicts" \
                        "Resolve conflicts manually, then commit"
                    return 1
                fi
                return 0
                ;;
            --help|-h|help)
                _teach_deploy_enhanced_help
                return 0
                ;;
            -*)
                _teach_error "Unknown flag: $1" "Run 'teach deploy --help' for usage"
                return 1
                ;;
            *)
                # File argument - enable partial deploy mode
                if [[ -f "$1" ]]; then
                    partial_deploy=true
                    deploy_files+=("$1")
                elif [[ -d "$1" ]]; then
                    # Directory - add all .qmd files in it
                    partial_deploy=true
                    for file in "$1"/**/*.qmd; do
                        [[ -f "$file" ]] && deploy_files+=("$file")
                    done
                else
                    _teach_error "File or directory not found: $1"
                    return 1
                fi
                shift
                ;;
        esac
    done

    # ============================================
    # PRE-FLIGHT CHECKS (shared function)
    # ============================================
    {

    _deploy_preflight_checks "$ci_mode" || return 1

    # Read exported variables from preflight
    local draft_branch="$DEPLOY_DRAFT_BRANCH"
    local prod_branch="$DEPLOY_PROD_BRANCH"
    local course_name="$DEPLOY_COURSE_NAME"
    local auto_pr="$DEPLOY_AUTO_PR"
    local require_clean="$DEPLOY_REQUIRE_CLEAN"

    # ============================================
    # UNCOMMITTED CHANGES HANDLER (all modes)
    # ============================================
    if [[ "$require_clean" != "false" ]] && ! _git_is_clean; then
        if [[ "$ci_mode" == "true" ]]; then
            _teach_error "Uncommitted changes detected" \
                "Commit changes before deploying in CI mode"
            return 1
        fi

        echo ""
        echo "${FLOW_COLORS[warn]}  Uncommitted changes detected${FLOW_COLORS[reset]}"

        local smart_msg
        smart_msg=$(_generate_smart_commit_message 2>/dev/null)
        [[ -z "$smart_msg" ]] && smart_msg="deploy: update content"

        echo "  ${FLOW_COLORS[info]}Suggested:${FLOW_COLORS[reset]} $smart_msg"
        echo ""
        echo -n "${FLOW_COLORS[prompt]}  Commit and continue? [Y/n]:${FLOW_COLORS[reset]} "
        read -r commit_confirm

        case "$commit_confirm" in
            n|N|no|No|NO)
                echo "  Deploy cancelled."
                return 1
                ;;
            *)
                git add -A
                if ! git commit -m "$smart_msg"; then
                    _deploy_commit_failure_guidance
                    return 1
                fi
                echo "  ${FLOW_COLORS[success]}[ok]${FLOW_COLORS[reset]} Committed: $smart_msg"
                ;;
        esac
    fi

    # ============================================
    # DRY-RUN MODE
    # ============================================
    if [[ "$dry_run" == "true" && "$partial_deploy" != "true" ]]; then
        local smart_msg=""
        if [[ -n "$custom_message" ]]; then
            smart_msg="$custom_message"
        fi
        _deploy_dry_run_report "$draft_branch" "$prod_branch" "$course_name" "$direct_push" "$smart_msg"
        return 0
    fi

    # ============================================
    # PREREQUISITE CHECK (if --check-prereqs flag)
    # ============================================
    if [[ "$check_prereqs" == "true" ]]; then
        echo ""
        echo "${FLOW_COLORS[info]}🔍 Prerequisite Validation${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"

        if ! _check_prerequisites_for_deploy; then
            echo ""
            _teach_error "Deploy blocked: Prerequisite validation failed" \
                "Fix missing prerequisites before deploying"
            echo ""
            echo "${FLOW_COLORS[dim]}Tip: Run 'teach validate --deep' to see full details${FLOW_COLORS[reset]}"
            return 1
        fi

        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} All prerequisites satisfied"
    fi

    # ============================================
    # PARTIAL DEPLOY MODE
    # ============================================

    if [[ "$partial_deploy" == "true" ]]; then
        echo ""
        echo "${FLOW_COLORS[info]}📦 Partial Deploy Mode${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"
        echo ""
        echo "${FLOW_COLORS[bold]}Files to deploy:${FLOW_COLORS[reset]}"
        for file in "${deploy_files[@]}"; do
            echo "  • $file"
        done

        # Validate cross-references
        echo ""
        echo "${FLOW_COLORS[info]}🔗 Validating cross-references...${FLOW_COLORS[reset]}"
        if _validate_cross_references "${deploy_files[@]}"; then
            echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} All cross-references valid"
        else
            if [[ "$ci_mode" == "true" ]]; then
                _teach_error "CI mode: broken cross-references detected. Fix before deploying."
                return 1
            fi
            echo ""
            echo -n "${FLOW_COLORS[prompt]}Continue with broken references? [y/N]:${FLOW_COLORS[reset]} "
            read -r continue_confirm
            case "$continue_confirm" in
                y|Y|yes|Yes|YES) ;;
                *) return 1 ;;
            esac
        fi

        # Find dependencies
        echo ""
        echo "${FLOW_COLORS[info]}🔍 Finding dependencies...${FLOW_COLORS[reset]}"
        local all_files=()
        local dep_count=0

        for file in "${deploy_files[@]}"; do
            all_files+=("$file")

            # Find dependencies for this file
            local deps=($(_find_dependencies "$file"))

            if [[ ${#deps[@]} -gt 0 ]]; then
                echo "${FLOW_COLORS[dim]}  Dependencies for $file:${FLOW_COLORS[reset]}"
                for dep in "${deps[@]}"; do
                    # Check if dependency is already in deploy list
                    if [[ ! " ${all_files[@]} " =~ " $dep " ]]; then
                        all_files+=("$dep")
                        echo "    • $dep"
                        ((dep_count++))
                    fi
                done
            fi
        done

        if [[ $dep_count -gt 0 ]]; then
            echo ""
            echo "${FLOW_COLORS[info]}Found $dep_count additional dependencies${FLOW_COLORS[reset]}"
            if [[ "$ci_mode" == "true" ]]; then
                # CI mode: auto-include dependencies
                deploy_files=("${all_files[@]}")
            else
                echo -n "${FLOW_COLORS[prompt]}Include dependencies in deployment? [Y/n]:${FLOW_COLORS[reset]} "
                read -r include_deps
                case "$include_deps" in
                    n|N|no|No|NO)
                        # Keep only original files
                        all_files=("${deploy_files[@]}")
                        ;;
                    *)
                        # Use all files including dependencies
                        deploy_files=("${all_files[@]}")
                        ;;
                esac
            fi
        fi

        # Dry-run: show what would happen and exit (partial deploy)
        if [[ "$dry_run" == "true" ]]; then
            echo ""
            echo "${FLOW_COLORS[warn]}  DRY RUN — No changes will be made${FLOW_COLORS[reset]}"
            echo ""
            echo "  Would deploy ${#deploy_files[@]} files:"
            for file in "${deploy_files[@]}"; do
                echo "    $file"
            done
            echo ""
            echo "${FLOW_COLORS[dim]}  Run without --dry-run to execute${FLOW_COLORS[reset]}"
            return 0
        fi

        # Check for uncommitted changes in deploy files
        local uncommitted_files=()
        for file in "${deploy_files[@]}"; do
            if ! git diff --quiet HEAD -- "$file" 2>/dev/null; then
                uncommitted_files+=("$file")
            fi
        done

        # Auto-commit if requested or if there are uncommitted changes
        if [[ ${#uncommitted_files[@]} -gt 0 ]]; then
            echo ""
            echo "${FLOW_COLORS[warn]}⚠️  Uncommitted changes detected${FLOW_COLORS[reset]}"
            echo ""
            for file in "${uncommitted_files[@]}"; do
                echo "  • $file"
            done
            echo ""

            if [[ "$auto_commit" == "true" || "$ci_mode" == "true" ]]; then
                # Auto-commit mode (or CI mode)
                echo "${FLOW_COLORS[info]}Auto-commit mode enabled${FLOW_COLORS[reset]}"
                local commit_msg="Update: $(date +%Y-%m-%d)"

                git add "${uncommitted_files[@]}"
                if ! git commit -m "$commit_msg"; then
                    _deploy_commit_failure_guidance
                    return 1
                fi

                echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Auto-committed changes"
            else
                # Prompt for commit
                echo -n "${FLOW_COLORS[prompt]}Commit message (or Enter for auto): ${FLOW_COLORS[reset]}"
                read -r commit_msg

                if [[ -z "$commit_msg" ]]; then
                    commit_msg="Update: $(date +%Y-%m-%d)"
                fi

                git add "${uncommitted_files[@]}"
                if ! git commit -m "$commit_msg"; then
                    _deploy_commit_failure_guidance
                    return 1
                fi

                echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Committed changes"
            fi
        fi

        # Index management (if not skipped)
        if [[ "$skip_index" == "false" ]]; then
            _process_index_changes "${deploy_files[@]}"

            # Check if index files were modified
            local index_modified=false
            for idx_file in home_lectures.qmd home_labs.qmd home_exams.qmd; do
                if [[ -f "$idx_file" ]] && ! git diff --quiet HEAD -- "$idx_file" 2>/dev/null; then
                    index_modified=true
                    break
                fi
            done

            if [[ "$index_modified" == "true" ]]; then
                echo ""
                echo "${FLOW_COLORS[info]}📝 Committing index changes...${FLOW_COLORS[reset]}"
                git add home_*.qmd
                git commit -m "Update index files"
                echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Index changes committed"
            fi
        fi

        # Push to remote
        if [[ "$ci_mode" == "true" ]]; then
            # CI mode: auto-push
            if _git_push_current_branch; then
                echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Pushed to origin/$draft_branch"
            else
                return 1
            fi
        else
            echo ""
            echo -n "${FLOW_COLORS[prompt]}Push to origin/$draft_branch? [Y/n]:${FLOW_COLORS[reset]} "
            read -r push_confirm

            case "$push_confirm" in
                n|N|no|No|NO)
                    echo "Deployment cancelled"
                    return 1
                    ;;
                *)
                    if _git_push_current_branch; then
                        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Pushed to origin/$draft_branch"
                    else
                        return 1
                    fi
                    ;;
            esac
        fi

        # Auto-tag if requested
        if [[ "$auto_tag" == "true" ]]; then
            local tag="deploy-$(date +%Y-%m-%d-%H%M)"
            git tag "$tag"
            git push origin "$tag"
            echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Tagged as $tag"
        fi

        # Create PR
        if [[ "$auto_pr" == "true" ]]; then
            local pr_title="Deploy: Partial Update"
            local pr_body="Deployed files:\n\n"
            for file in "${deploy_files[@]}"; do
                pr_body+="- $file\n"
            done

            if [[ "$ci_mode" == "true" ]]; then
                # CI mode: auto-create PR
                if _git_create_deploy_pr "$draft_branch" "$prod_branch" "$pr_title" "$pr_body"; then
                    echo ""
                    echo "${FLOW_COLORS[success]}✅ Pull Request Created${FLOW_COLORS[reset]}"
                else
                    return 1
                fi
            else
                echo ""
                echo -n "${FLOW_COLORS[prompt]}Create pull request? [Y/n]:${FLOW_COLORS[reset]} "
                read -r pr_confirm

                case "$pr_confirm" in
                    n|N|no|No|NO)
                        echo "PR creation skipped"
                        ;;
                    *)
                        if _git_create_deploy_pr "$draft_branch" "$prod_branch" "$pr_title" "$pr_body"; then
                            echo ""
                            echo "${FLOW_COLORS[success]}✅ Pull Request Created${FLOW_COLORS[reset]}"
                        else
                            return 1
                        fi
                        ;;
                esac
            fi
        fi

        echo ""
        echo "${FLOW_COLORS[success]}✅ Partial deployment complete${FLOW_COLORS[reset]}"
        return 0
    fi

    # ============================================
    # FULL SITE DEPLOY MODE (existing behavior)
    # ============================================

    # Fall back to original _teach_deploy implementation
    # This preserves the existing full-site deployment workflow

    # ============================================
    # DEPLOY MODE DISPATCH
    # ============================================

    if [[ "$direct_push" == "true" ]]; then
        # Direct merge mode (fast path, 8-15s)
        local smart_message
        if [[ -n "$custom_message" ]]; then
            smart_message="$custom_message"
        elif typeset -f _generate_smart_commit_message >/dev/null 2>&1; then
            smart_message=$(_generate_smart_commit_message "$draft_branch" "$prod_branch")
        else
            smart_message="deploy: $course_name update"
        fi

        echo ""
        echo "${FLOW_COLORS[info]}  Smart commit: $smart_message${FLOW_COLORS[reset]}"

        _deploy_direct_merge "$draft_branch" "$prod_branch" "$smart_message" "$ci_mode" || return 1

        # Auto-tag if requested
        if [[ "$auto_tag" == "true" ]]; then
            local tag="deploy-$(date +%Y-%m-%d-%H%M)"
            git tag "$tag" 2>/dev/null
            git push origin "$tag" 2>/dev/null
            echo "${FLOW_COLORS[success]}  [ok]${FLOW_COLORS[reset]} Tagged as $tag"
        fi

        # Record in deploy history
        if typeset -f _deploy_history_append >/dev/null 2>&1; then
            local _commit_after="${DEPLOY_COMMIT_AFTER:-$(git rev-parse --short=8 HEAD 2>/dev/null)}"
            local _commit_before="${DEPLOY_COMMIT_BEFORE:-}"
            local _file_count="${DEPLOY_FILE_COUNT:-$(git diff --name-only HEAD~1 HEAD 2>/dev/null | wc -l | tr -d ' ')}"
            local _elapsed="${DEPLOY_DURATION:-0}"
            _deploy_history_append "direct" "$_commit_after" "$_commit_before" "$draft_branch" "$prod_branch" "$_file_count" "$smart_message" "null" "null" "$_elapsed"
            echo "  ${FLOW_COLORS[dim]}History logged: #$(( $(_deploy_history_count) )) ($(date '+%Y-%m-%d %H:%M'))${FLOW_COLORS[reset]}"
        fi

        # Update .STATUS file
        _deploy_update_status_file 2>/dev/null

        # Show deployment summary box
        local site_url
        site_url=$(yq '.site.url // ""' .flow/teach-config.yml 2>/dev/null)
        _deploy_summary_box \
            "Direct merge" \
            "${DEPLOY_FILE_COUNT:-0}" \
            "${DEPLOY_INSERTIONS:-0}" \
            "${DEPLOY_DELETIONS:-0}" \
            "${DEPLOY_DURATION:-0}" \
            "${DEPLOY_SHORT_HASH:-$(git rev-parse --short=8 HEAD 2>/dev/null)}" \
            "$site_url"

        return 0
    fi

    # Track PR deploy timing
    local pr_deploy_start=$SECONDS

    # Safety: always return to draft branch on error or signal (PR mode)
    trap "git checkout '$draft_branch' 2>/dev/null" EXIT INT TERM

    # Check 2: Verify clean (should be clean after uncommitted handler above)
    if ! _git_is_clean; then
        echo "${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} Uncommitted changes detected"
        echo ""
        echo "  ${FLOW_COLORS[dim]}Commit or stash changes before deploying${FLOW_COLORS[reset]}"
        return 1
    else
        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} No uncommitted changes"
    fi

    # Check 3: Check for unpushed commits
    if _git_has_unpushed_commits; then
        echo "${FLOW_COLORS[warn]}⚠️  ${FLOW_COLORS[reset]} Unpushed commits detected"
        if [[ "$ci_mode" == "true" ]]; then
            # CI mode: auto-push
            if _git_push_current_branch; then
                echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Pushed to origin/$draft_branch"
            else
                return 1
            fi
        else
            echo ""
            echo -n "${FLOW_COLORS[prompt]}Push to origin/$draft_branch first? [Y/n]:${FLOW_COLORS[reset]} "
            read -r push_confirm

            case "$push_confirm" in
                n|N|no|No|NO)
                    echo "${FLOW_COLORS[warn]}Continuing without push...${FLOW_COLORS[reset]}"
                    ;;
                *)
                    if _git_push_current_branch; then
                        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Pushed to origin/$draft_branch"
                    else
                        return 1
                    fi
                    ;;
            esac
        fi
    else
        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Remote is up-to-date"
    fi

    # Check 4: Conflict detection
    if _git_detect_production_conflicts "$draft_branch" "$prod_branch"; then
        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} No conflicts with production"
    else
        echo "${FLOW_COLORS[warn]}⚠️  ${FLOW_COLORS[reset]} Production ($prod_branch) has new commits"
        if [[ "$ci_mode" == "true" ]]; then
            _teach_error "CI mode: production conflicts detected. Resolve manually."
            return 1
        fi
        echo ""
        echo "${FLOW_COLORS[prompt]}Production branch has updates. Rebase first?${FLOW_COLORS[reset]}"
        echo ""
        echo "  ${FLOW_COLORS[dim]}[1]${FLOW_COLORS[reset]} Yes - Rebase $draft_branch onto $prod_branch (Recommended)"
        echo "  ${FLOW_COLORS[dim]}[2]${FLOW_COLORS[reset]} No - Continue anyway (may have merge conflicts in PR)"
        echo "  ${FLOW_COLORS[dim]}[3]${FLOW_COLORS[reset]} Cancel deployment"
        echo ""
        echo -n "${FLOW_COLORS[prompt]}Your choice [1-3]:${FLOW_COLORS[reset]} "
        read -r rebase_choice

        case "$rebase_choice" in
            1)
                if _git_rebase_onto_production "$draft_branch" "$prod_branch"; then
                    echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Rebase successful"
                else
                    return 1
                fi
                ;;
            2)
                echo "${FLOW_COLORS[warn]}Continuing without rebase...${FLOW_COLORS[reset]}"
                ;;
            3|*)
                echo "Deployment cancelled"
                return 1
                ;;
        esac
    fi

    echo ""

    # Generate PR details
    local commit_count=$(_git_get_commit_count "$draft_branch" "$prod_branch")
    local pr_title="Deploy: $course_name Updates"
    local pr_body=$(_git_generate_pr_body "$draft_branch" "$prod_branch")

    # Show PR preview
    echo "${FLOW_COLORS[info]}📋 Pull Request Preview${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"
    echo ""
    echo "${FLOW_COLORS[bold]}Title:${FLOW_COLORS[reset]} $pr_title"
    echo "${FLOW_COLORS[bold]}From:${FLOW_COLORS[reset]} $draft_branch → $prod_branch"
    echo "${FLOW_COLORS[bold]}Commits:${FLOW_COLORS[reset]} $commit_count"
    echo ""

    # Show changes preview
    echo ""
    echo "${FLOW_COLORS[info]}📋 Changes Preview${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[dim]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"

    local files_changed=$(git diff --name-status "$prod_branch"..."$draft_branch" 2>/dev/null)
    if [[ -n "$files_changed" ]]; then
        echo ""
        echo "${FLOW_COLORS[dim]}Files Changed:${FLOW_COLORS[reset]}"
        while IFS=$'\t' read -r file_status file; do
            case "$file_status" in
                M)  echo "  ${FLOW_COLORS[warn]}M${FLOW_COLORS[reset]}  $file" ;;
                A)  echo "  ${FLOW_COLORS[success]}A${FLOW_COLORS[reset]}  $file" ;;
                D)  echo "  ${FLOW_COLORS[error]}D${FLOW_COLORS[reset]}  $file" ;;
                R*) echo "  ${FLOW_COLORS[info]}R${FLOW_COLORS[reset]}  $file" ;;
                *)  echo "  ${FLOW_COLORS[muted]}$file_status${FLOW_COLORS[reset]}  $file" ;;
            esac
        done <<< "$files_changed"

        local modified=$(echo "$files_changed" | grep -c "^M" || echo 0)
        local added=$(echo "$files_changed" | grep -c "^A" || echo 0)
        local deleted=$(echo "$files_changed" | grep -c "^D" || echo 0)
        local total=$(echo "$files_changed" | wc -l | tr -d ' ')

        echo ""
        echo "${FLOW_COLORS[dim]}Summary: $total files ($added added, $modified modified, $deleted deleted)${FLOW_COLORS[reset]}"
    else
        echo "${FLOW_COLORS[muted]}No changes detected${FLOW_COLORS[reset]}"
    fi

    # Create PR
    echo ""
    if [[ "$auto_pr" == "true" ]]; then
        if [[ "$ci_mode" == "true" ]]; then
            # CI mode: auto-create PR
            echo ""
            if _git_create_deploy_pr "$draft_branch" "$prod_branch" "$pr_title" "$pr_body"; then
                echo ""
                echo "${FLOW_COLORS[success]}✅ Pull Request Created${FLOW_COLORS[reset]}"
            else
                return 1
            fi
        else
            echo "${FLOW_COLORS[prompt]}Create pull request?${FLOW_COLORS[reset]}"
            echo ""
            echo "  ${FLOW_COLORS[dim]}[1]${FLOW_COLORS[reset]} Yes - Create PR (Recommended)"
            echo "  ${FLOW_COLORS[dim]}[2]${FLOW_COLORS[reset]} Push to $draft_branch only (no PR)"
            echo "  ${FLOW_COLORS[dim]}[3]${FLOW_COLORS[reset]} Cancel"
            echo ""
            echo -n "${FLOW_COLORS[prompt]}Your choice [1-3]:${FLOW_COLORS[reset]} "
            read -r pr_choice

            case "$pr_choice" in
                1)
                    echo ""
                    if _git_create_deploy_pr "$draft_branch" "$prod_branch" "$pr_title" "$pr_body"; then
                        echo ""
                        echo "${FLOW_COLORS[success]}✅ Pull Request Created${FLOW_COLORS[reset]}"
                    else
                        return 1
                    fi
                    ;;
                2)
                    if _git_push_current_branch; then
                        echo ""
                        echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Pushed to origin/$draft_branch"
                    else
                        return 1
                    fi
                    ;;
                3|*)
                    echo "Deployment cancelled"
                    return 1
                    ;;
            esac
        fi
    else
        if _git_push_current_branch; then
            echo ""
            echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Pushed to origin/$draft_branch"
        else
            return 1
        fi
    fi

    # Collect PR deploy stats
    local pr_deploy_elapsed=$(( SECONDS - pr_deploy_start ))
    local _pr_commit=$(git rev-parse --short=8 HEAD 2>/dev/null)
    local _pr_diff_stat=$(git diff --stat "$prod_branch"..."$draft_branch" 2>/dev/null | tail -1)
    local _pr_file_count=$(echo "$_pr_diff_stat" | grep -oE '[0-9]+ files?' | grep -oE '[0-9]+' || echo "0")
    local _pr_insertions=$(echo "$_pr_diff_stat" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo "0")
    local _pr_deletions=$(echo "$_pr_diff_stat" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || echo "0")

    # Record PR deploy in history
    if typeset -f _deploy_history_append >/dev/null 2>&1; then
        local _pr_message="deploy: $course_name PR update"
        _deploy_history_append "pr" "$_pr_commit" "" "$draft_branch" "$prod_branch" "${_pr_file_count:-0}" "$_pr_message" "null" "null" "$pr_deploy_elapsed"
        echo "  ${FLOW_COLORS[dim]}History logged: #$(( $(_deploy_history_count) )) ($(date '+%Y-%m-%d %H:%M'))${FLOW_COLORS[reset]}"
    fi

    # Update .STATUS file
    _deploy_update_status_file 2>/dev/null

    # Show deployment summary box (PR mode)
    local pr_url
    pr_url=$(gh pr list --head "$draft_branch" --base "$prod_branch" --json url --jq '.[0].url' 2>/dev/null)
    _deploy_summary_box \
        "Pull request" \
        "${_pr_file_count:-0}" \
        "${_pr_insertions:-0}" \
        "${_pr_deletions:-0}" \
        "$pr_deploy_elapsed" \
        "$_pr_commit" \
        "$pr_url"

    # Clear trap before normal return (don't interfere with caller)
    trap - EXIT INT TERM

    } always {
        _deploy_cleanup_globals
    }
}

# Clean up DEPLOY_* global variables to avoid polluting the shell environment
_deploy_cleanup_globals() {
    unset DEPLOY_DRAFT_BRANCH DEPLOY_PROD_BRANCH DEPLOY_COURSE_NAME
    unset DEPLOY_AUTO_PR DEPLOY_REQUIRE_CLEAN
    unset DEPLOY_COMMIT_BEFORE DEPLOY_COMMIT_AFTER DEPLOY_DURATION DEPLOY_MODE
    unset DEPLOY_FILE_COUNT DEPLOY_INSERTIONS DEPLOY_DELETIONS DEPLOY_SHORT_HASH
    unset DEPLOY_HIST_TIMESTAMP DEPLOY_HIST_MODE DEPLOY_HIST_COMMIT
    unset DEPLOY_HIST_COMMIT_BEFORE DEPLOY_HIST_BRANCH_FROM DEPLOY_HIST_BRANCH_TO
    unset DEPLOY_HIST_FILE_COUNT DEPLOY_HIST_MESSAGE DEPLOY_HIST_PR
    unset DEPLOY_HIST_TAG DEPLOY_HIST_USER DEPLOY_HIST_DURATION
}

# Help for enhanced teach deploy
_teach_deploy_enhanced_help() {
    # Color fallbacks for standalone use
    if [[ -z "$_C_BOLD" ]]; then
        _C_BOLD='\033[1m'
        _C_DIM='\033[2m'
        _C_NC='\033[0m'
        _C_GREEN='\033[32m'
        _C_YELLOW='\033[33m'
        _C_BLUE='\033[34m'
        _C_MAGENTA='\033[35m'
        _C_CYAN='\033[36m'
    fi

    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ teach deploy - Course Site Deployment        │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_BOLD}Usage:${_C_NC} teach deploy [files...] [options]

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}teach deploy -d${_C_NC}              Direct merge (fast, no PR)
  ${_C_CYAN}teach deploy${_C_NC}                 Full site deploy via PR
  ${_C_CYAN}teach deploy -d -m \"msg\"${_C_NC}   Direct merge with message
  ${_C_CYAN}teach deploy --dry-run${_C_NC}       Preview without changes

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} teach deploy -d                          ${_C_DIM}# Quick deploy (8-15s)${_C_NC}
  ${_C_DIM}\$${_C_NC} teach deploy -d -m \"Week 5 ANOVA\"       ${_C_DIM}# Direct + message${_C_NC}
  ${_C_DIM}\$${_C_NC} teach deploy lectures/week-05.qmd        ${_C_DIM}# Partial deploy${_C_NC}
  ${_C_DIM}\$${_C_NC} teach deploy --preview -d                ${_C_DIM}# Dry run direct${_C_NC}
  ${_C_DIM}\$${_C_NC} teach deploy --rollback 1                ${_C_DIM}# Undo last deploy${_C_NC}

${_C_BLUE}📋 DEPLOY MODES${_C_NC}:
  ${_C_CYAN}teach deploy${_C_NC}                 Full site via PR (team review)
  ${_C_CYAN}teach deploy -d${_C_NC}              Direct merge, no PR (solo)
  ${_C_CYAN}teach deploy <files>${_C_NC}         Partial deploy (specific files)
  ${_C_CYAN}teach deploy --ci${_C_NC}            Non-interactive (CI pipelines)
  ${_C_CYAN}teach deploy --ci -d${_C_NC}         CI + direct merge

${_C_BLUE}📋 OPTIONS${_C_NC}:
  ${_C_CYAN}--direct, -d${_C_NC}          Direct merge (draft -> prod, 8-15s)
  ${_C_CYAN}--message, -m MSG${_C_NC}     Custom commit message
  ${_C_CYAN}--dry-run, --preview${_C_NC}  Preview without making changes
  ${_C_CYAN}--ci${_C_NC}                  Force non-interactive mode
  ${_C_CYAN}--auto-commit${_C_NC}         Auto-commit uncommitted changes
  ${_C_CYAN}--auto-tag${_C_NC}            Auto-tag with timestamp
  ${_C_CYAN}--skip-index${_C_NC}          Skip index management prompts
  ${_C_CYAN}--check-prereqs${_C_NC}       Validate prerequisites first

${_C_BLUE}📋 HISTORY & ROLLBACK${_C_NC}:
  ${_C_CYAN}teach deploy --history${_C_NC}       Show last 10 deployments
  ${_C_CYAN}teach deploy --history 20${_C_NC}    Show last 20 deployments
  ${_C_CYAN}teach deploy --rollback${_C_NC}      Interactive rollback picker
  ${_C_CYAN}teach deploy --rollback 1${_C_NC}    Rollback most recent deploy
  ${_C_CYAN}teach deploy --sync${_C_NC}          Sync draft with production

${_C_MAGENTA}💡 TIP${_C_NC}: Direct merge (-d) is best for solo instructors.
  ${_C_DIM}PR mode (default) is better for team-reviewed courses.${_C_NC}
  ${_C_DIM}Smart commit messages auto-generate from changed files.${_C_NC}

${_C_DIM}📚 See also:${_C_NC}
  ${_C_CYAN}teach analyze${_C_NC} - Validate content before deploy
  ${_C_CYAN}teach status${_C_NC} - Check course status
  ${_C_CYAN}teach config${_C_NC} - View deploy configuration
"
}

# ============================================================================
# PREREQUISITE VALIDATION FOR DEPLOY
# ============================================================================

# Check prerequisites before deploy
# Returns 0 if no errors, 1 if missing prerequisites (errors) found
# Warnings (future prerequisites) do NOT block deploy
_check_prerequisites_for_deploy() {
    local course_dir="$PWD"

    # Source concept extraction if not loaded
    if ! typeset -f _build_concept_graph >/dev/null 2>&1; then
        local concept_path="${0:A:h:h}/concept-extraction.zsh"
        [[ -f "$concept_path" ]] && source "$concept_path"
    fi

    # Source prerequisite checker if not loaded
    if ! typeset -f _check_prerequisites >/dev/null 2>&1; then
        local prereq_path="${0:A:h:h}/prerequisite-checker.zsh"
        [[ -f "$prereq_path" ]] && source "$prereq_path"
    fi

    # Source analysis cache if not loaded (for cache support)
    if ! typeset -f _cache_read >/dev/null 2>&1; then
        local cache_path="${0:A:h:h}/analysis-cache.zsh"
        [[ -f "$cache_path" ]] && source "$cache_path"
    fi

    # Try to use cached concept graph first
    local graph_json=""
    local use_cache=0

    if typeset -f _cache_read >/dev/null 2>&1; then
        local cached_graph
        cached_graph=$(_cache_read "concepts-graph" "$course_dir" 2>/dev/null)
        if [[ -n "$cached_graph" && "$cached_graph" != "null" ]]; then
            graph_json="$cached_graph"
            use_cache=1
            echo "${FLOW_COLORS[dim]}  Using cached concept graph${FLOW_COLORS[reset]}"
        fi
    fi

    if [[ $use_cache -eq 0 ]]; then
        # Build concept graph fresh
        echo "${FLOW_COLORS[dim]}  Building concept graph...${FLOW_COLORS[reset]}"

        local graph_file
        graph_file=$(_build_concept_graph "$course_dir" 2>/dev/null)

        if [[ -z "$graph_file" || ! -f "$graph_file" ]]; then
            # No concepts found - not an error, just no validation needed
            echo "${FLOW_COLORS[dim]}  No concept metadata found - skipping validation${FLOW_COLORS[reset]}"
            return 0
        fi

        graph_json=$(cat "$graph_file")
        rm -f "$graph_file"

        # Cache for future use
        if typeset -f _cache_write >/dev/null 2>&1; then
            _cache_write "concepts-graph" "$graph_json" "$course_dir" 2>/dev/null
        fi
    fi

    # Check concept count
    local concept_count
    concept_count=$(echo "$graph_json" | jq '.metadata.total_concepts // 0' 2>/dev/null)

    if [[ "$concept_count" -eq 0 ]]; then
        echo "${FLOW_COLORS[dim]}  No concepts defined - skipping validation${FLOW_COLORS[reset]}"
        return 0
    fi

    echo "${FLOW_COLORS[dim]}  Checking $concept_count concepts...${FLOW_COLORS[reset]}"

    # Convert graph to course_data format
    local course_data
    course_data=$(echo "$graph_json" | jq '
        .concepts | to_entries |
        group_by(.value.introduced_in.week) |
        map({
            week_num: .[0].value.introduced_in.week,
            concepts: map({
                id: .key,
                prerequisites: .value.prerequisites
            })
        }) |
        {weeks: sort_by(.week_num)}
    ' 2>/dev/null)

    # Check prerequisites
    local violations_json raw_output
    raw_output=$(_check_prerequisites "$course_data" 2>/dev/null)
    violations_json=$(echo "$raw_output" | awk '/^\[/,/^\]/' | jq -c '.' 2>/dev/null)
    [[ -z "$violations_json" || "$violations_json" == "null" ]] && violations_json="[]"

    # Count errors (missing prerequisites) - these block deploy
    local error_count=0
    local warning_count=0

    if [[ -n "$violations_json" && "$violations_json" != "[]" ]]; then
        error_count=$(echo "$violations_json" | jq '[.[] | select(.type == "missing")] | length' 2>/dev/null || echo "0")
        warning_count=$(echo "$violations_json" | jq '[.[] | select(.type == "future")] | length' 2>/dev/null || echo "0")
    fi

    # Report results
    if [[ "$error_count" -gt 0 ]]; then
        echo ""
        echo "${FLOW_COLORS[error]}✗ Found $error_count missing prerequisite(s)${FLOW_COLORS[reset]}"

        # Show violations
        echo "$violations_json" | jq -r '.[] | select(.type == "missing") | "  • \(.concept_id) requires \(.prerequisite_id) (not defined)"' 2>/dev/null
        return 1
    fi

    if [[ "$warning_count" -gt 0 ]]; then
        echo "${FLOW_COLORS[warn]}⚠ Found $warning_count future prerequisite(s) (warnings only)${FLOW_COLORS[reset]}"
        # Warnings do not block deploy
    fi

    return 0
}
