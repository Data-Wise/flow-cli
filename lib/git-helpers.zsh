#!/usr/bin/env zsh
# git-helpers.zsh - Git integration functions for teaching workflow
# Part of flow-cli v5.11.0 - Teaching + Git Integration Enhancement
# Phase 1: Smart post-generation workflow

# =============================================================================
# Function: _git_teaching_commit_message
# Purpose: Generate standardized commit message for teaching content
# =============================================================================
# Arguments:
#   $1 - (required) Content type (exam, quiz, slides, lecture, etc.)
#   $2 - (required) Topic or title of the content
#   $3 - (required) Full command that generated the content
#   $4 - (required) Course name (e.g., "STAT 545")
#   $5 - (required) Semester (Fall, Spring, etc.)
#   $6 - (required) Year
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Formatted commit message with conventional commit style
#
# Example:
#   msg=$(_git_teaching_commit_message "exam" "Hypothesis Testing" \
#       "teach exam \"Hypothesis Testing\" --questions 20" \
#       "STAT 545" "Fall" "2024")
#
#   # Output:
#   # teach: add exam for Hypothesis Testing
#   #
#   # Generated via: teach exam "Hypothesis Testing" --questions 20
#   # Course: STAT 545 (Fall 2024)
#   #
#   # Co-Authored-By: Scholar <scholar@example.com>
#
# Notes:
#   - Uses conventional commits style (teach: prefix)
#   - Includes Scholar co-author attribution
#   - Designed for automated git workflows
# =============================================================================
_git_teaching_commit_message() {
    local type="$1"       # exam, quiz, slides, lecture, etc.
    local topic="$2"      # Topic/title of the content
    local command="$3"    # Full command that generated the content
    local course="$4"     # Course name
    local semester="$5"   # Semester (Fall, Spring, etc.)
    local year="$6"       # Year

    # Determine action verb based on file state
    local action="add"

    # Generate conventional commit message
    cat <<EOF
teach: ${action} ${type} for ${topic}

Generated via: ${command}
Course: ${course} (${semester} ${year})

Co-Authored-By: Scholar <scholar@example.com>
EOF
}

# =============================================================================
# Function: _generate_smart_commit_message
# Purpose: Generate descriptive commit message from changed files
# =============================================================================
# Arguments:
#   $1 - (optional) Draft branch name
#   $2 - (optional) Production branch name
#   If both given, diffs between branches; otherwise uses staged/modified files
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Single-line commit message like "content: week-05 lecture, assignment 3"
#
# Categories:
#   lectures/*.qmd     → "lecture" (extracts week number)
#   labs/*.qmd          → "lab"
#   assignments/*.qmd   → "assignment" (extracts number)
#   exams/*.qmd         → "exam"
#   projects/*.qmd      → "project"
#   scripts/*.R|*.py    → "script"
#   home_*.qmd          → "index"
#   _quarto.yml         → "config"
#   _metadata.yml       → "config"
#   .flow/*.yml         → "config"
#   .STATUS             → "config"
#   *.css|*.scss        → "style"
#   images/*|img/*      → "media"
#   data/*              → "data"
#   *.qmd               → "content" (catch-all)
#   *                   → "misc" (catch-all)
#
# Prefix logic:
#   If >50% files are one category, use that as prefix
#   Otherwise use "deploy"
#
# Example:
#   msg=$(_generate_smart_commit_message "draft" "gh-pages")
#   # → "content: week-05 lecture, assignment 3"
#
#   msg=$(_generate_smart_commit_message)
#   # Uses staged files → "config: quarto settings, metadata"
#
# Notes:
#   - Pure ZSH implementation (no external tools except git)
#   - Messages truncated to 72 characters
#   - Ported from STAT-545's generate_smart_message() logic
# =============================================================================
_generate_smart_commit_message() {
    local draft_branch="${1:-}"
    local prod_branch="${2:-}"
    local changed_files=()

    # Get changed files
    if [[ -n "$draft_branch" && -n "$prod_branch" ]]; then
        # Files different between branches
        changed_files=(${(f)"$(git diff --name-only "$prod_branch"..."$draft_branch" 2>/dev/null)"})
    else
        # Staged files
        changed_files=(${(f)"$(git diff --cached --name-only 2>/dev/null)"})
        # If nothing staged, use modified files
        if [[ ${#changed_files[@]} -eq 0 ]]; then
            changed_files=(${(f)"$(git diff --name-only 2>/dev/null)"})
        fi
    fi

    # If no files, generic message
    if [[ ${#changed_files[@]} -eq 0 ]]; then
        echo "deploy: update"
        return 0
    fi

    # Categorize files
    local -A categories  # category -> count
    local -a descriptions  # human-readable descriptions
    local total=${#changed_files[@]}

    for file in "${changed_files[@]}"; do
        [[ -z "$file" ]] && continue
        local basename="${file:t}"   # filename only
        local dirname="${file:h}"    # directory only
        local ext="${file:e}"        # extension

        case "$file" in
            lectures/*.qmd)
                categories[content]=$(( ${categories[content]:-0} + 1 ))
                # Extract week number
                if [[ "$basename" =~ "week-([0-9]+)" ]]; then
                    descriptions+=("week-${match[1]} lecture")
                else
                    descriptions+=("${basename%.qmd} lecture")
                fi
                ;;
            labs/*.qmd)
                categories[content]=$(( ${categories[content]:-0} + 1 ))
                if [[ "$basename" =~ "week-([0-9]+)" ]]; then
                    descriptions+=("week-${match[1]} lab")
                else
                    descriptions+=("${basename%.qmd} lab")
                fi
                ;;
            assignments/*.qmd)
                categories[content]=$(( ${categories[content]:-0} + 1 ))
                if [[ "$basename" =~ "([0-9]+)" ]]; then
                    descriptions+=("assignment ${match[1]}")
                else
                    descriptions+=("${basename%.qmd} assignment")
                fi
                ;;
            exams/*.qmd)
                categories[content]=$(( ${categories[content]:-0} + 1 ))
                descriptions+=("${basename%.qmd} exam")
                ;;
            projects/*.qmd)
                categories[content]=$(( ${categories[content]:-0} + 1 ))
                descriptions+=("${basename%.qmd} project")
                ;;
            scripts/*.R|scripts/*.py)
                categories[content]=$(( ${categories[content]:-0} + 1 ))
                descriptions+=("${basename} script")
                ;;
            home_*.qmd)
                categories[config]=$(( ${categories[config]:-0} + 1 ))
                descriptions+=("index update")
                ;;
            _quarto.yml|_metadata.yml)
                categories[config]=$(( ${categories[config]:-0} + 1 ))
                descriptions+=("${basename}")
                ;;
            .flow/*.yml)
                categories[config]=$(( ${categories[config]:-0} + 1 ))
                descriptions+=("flow config")
                ;;
            .STATUS)
                categories[config]=$(( ${categories[config]:-0} + 1 ))
                descriptions+=("status")
                ;;
            *.css|*.scss)
                categories[style]=$(( ${categories[style]:-0} + 1 ))
                descriptions+=("style")
                ;;
            images/*|img/*)
                categories[content]=$(( ${categories[content]:-0} + 1 ))
                descriptions+=("media")
                ;;
            data/*)
                categories[data]=$(( ${categories[data]:-0} + 1 ))
                descriptions+=("data")
                ;;
            *.qmd)
                categories[content]=$(( ${categories[content]:-0} + 1 ))
                descriptions+=("${basename%.qmd}")
                ;;
            *)
                categories[misc]=$(( ${categories[misc]:-0} + 1 ))
                ;;
        esac
    done

    # Determine prefix from dominant category
    local prefix="deploy"
    local max_count=0
    for cat count in ${(kv)categories}; do
        if [[ $count -gt $max_count ]]; then
            max_count=$count
            prefix="$cat"
        fi
    done

    # If dominant is >50% of total, use it; otherwise "deploy"
    if [[ $max_count -le $(( total / 2 )) ]]; then
        prefix="deploy"
    fi

    # "misc" isn't a good prefix
    [[ "$prefix" == "misc" ]] && prefix="deploy"

    # Deduplicate descriptions
    local -a unique_descs=()
    local -A seen_descs
    for desc in "${descriptions[@]}"; do
        [[ -z "$desc" ]] && continue
        if [[ -z "${seen_descs[$desc]:-}" ]]; then
            seen_descs[$desc]=1
            unique_descs+=("$desc")
        fi
    done

    # Build message body
    local body=""
    if [[ ${#unique_descs[@]} -eq 0 ]]; then
        body="update"
    elif [[ $total -gt 10 && ${#unique_descs[@]} -gt 5 ]]; then
        body="full site update ($total files)"
    elif [[ ${#unique_descs[@]} -le 3 ]]; then
        body="${(j:, :)unique_descs}"
    else
        # Take first 3, add "+N more"
        local first_three=("${unique_descs[@]:0:3}")
        local remaining=$(( ${#unique_descs[@]} - 3 ))
        body="${(j:, :)first_three} +${remaining} more"
    fi

    # Truncate to 72 chars
    local message="${prefix}: ${body}"
    if [[ ${#message} -gt 72 ]]; then
        message="${message:0:69}..."
    fi

    echo "$message"
    return 0
}

# =============================================================================
# Function: _git_is_clean
# Purpose: Check if working directory has no uncommitted changes
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Working directory is clean (no uncommitted changes)
#   1 - Working directory is dirty (has uncommitted changes)
#
# Example:
#   if _git_is_clean; then
#       echo "Ready to switch branches"
#   else
#       echo "Commit or stash changes first"
#   fi
#
# Notes:
#   - Uses git status --porcelain for scriptable output
#   - Includes untracked files in "dirty" check
#   - Returns 1 if not in a git repository
# =============================================================================
_git_is_clean() {
    [[ -z "$(git status --porcelain 2>/dev/null)" ]]
}

# =============================================================================
# Function: _git_is_synced
# Purpose: Check if local branch is synchronized with remote
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Branch is synced (no unpushed or unpulled commits)
#   1 - Branch is out of sync (ahead, behind, or diverged)
#
# Example:
#   if _git_is_synced; then
#       echo "Branch is up to date"
#   else
#       echo "Need to push or pull"
#   fi
#
# Notes:
#   - Fetches from remote first (may take a moment)
#   - Returns 1 if no upstream branch configured
#   - Checks both ahead (local commits) and behind (remote commits)
# =============================================================================
_git_is_synced() {
    # Silently fetch latest from remote
    git fetch --quiet 2>/dev/null || return 1

    local ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
    local behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo 0)

    [[ $ahead -eq 0 && $behind -eq 0 ]]
}

# =============================================================================
# Function: _git_teaching_files
# Purpose: Get list of uncommitted teaching-related files
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - File paths (one per line), sorted and deduplicated
#
# Recognized Paths:
#   exams/        - Exam files
#   slides/       - Presentation slides
#   assignments/  - Assignment materials
#   lectures/     - Lecture notes
#   quizzes/      - Quiz files
#   homework/     - Homework assignments
#   labs/         - Lab materials
#
# Example:
#   local files=$(_git_teaching_files)
#   if [[ -n "$files" ]]; then
#       echo "Teaching files to commit:"
#       echo "$files"
#   fi
#
# Notes:
#   - Includes both staged and unstaged changes
#   - Includes untracked files in teaching directories
#   - Returns empty if no teaching files changed
# =============================================================================
_git_teaching_files() {
    # Common teaching content paths
    local paths=("exams/" "slides/" "assignments/" "lectures/" "quizzes/" "homework/" "labs/")

    # Build regex pattern for grep
    local pattern=$(printf '%s|' "${paths[@]}" | sed 's/|$//')

    # Get uncommitted files matching teaching paths
    # Use ls-files for untracked to get individual files, not just directories
    {
        # Modified/staged files
        git status --porcelain 2>/dev/null | grep -E "$pattern" | awk '{print $2}'
        # Untracked files in teaching directories
        git ls-files --others --exclude-standard 2>/dev/null | grep -E "$pattern"
    } | sort -u
}

# =============================================================================
# Function: _git_interactive_commit
# Purpose: Interactive commit workflow for teaching content (stub)
# =============================================================================
# Arguments:
#   $1 - (required) File path
#   $2 - (required) Content type
#   $3 - (required) Topic
#   $4 - (required) Command that generated content
#   $5 - (required) Course name
#   $6 - (required) Semester
#   $7 - (required) Year
#
# Returns:
#   0 - Setup complete (actual commit in teach dispatcher)
#   1 - Error (e.g., missing dependencies)
#
# Notes:
#   - This is a stub function for Phase 1
#   - Actual interactive prompting handled by teach dispatcher
#   - Sources core.zsh for logging helpers
# =============================================================================
_git_interactive_commit() {
    local file="$1"
    local type="$2"
    local topic="$3"
    local command="$4"
    local course="$5"
    local semester="$6"
    local year="$7"

    # Source core helpers for logging
    source "${0:A:h}/core.zsh" 2>/dev/null || return 1

    # Use AskUserQuestion to prompt for next action
    # Note: This will be implemented in the teach dispatcher
    # For now, return success to indicate setup is complete
    return 0
}

# =============================================================================
# Function: _git_create_deploy_pr
# Purpose: Create a pull request for teaching content deployment
# =============================================================================
# Arguments:
#   $1 - (required) Source branch (draft/development)
#   $2 - (required) Target branch (production)
#   $3 - (required) PR title
#   $4 - (required) PR body (markdown)
#
# Returns:
#   0 - PR created successfully
#   1 - Error (gh not installed, not authenticated, or creation failed)
#
# Dependencies:
#   - gh CLI (GitHub CLI)
#   - gh auth login (authenticated)
#
# Example:
#   _git_create_deploy_pr "draft" "main" \
#       "Deploy: Week 5 materials" \
#       "$(cat pr-body.md)"
#
# Notes:
#   - Adds labels: teaching, deploy
#   - Requires authenticated GitHub CLI
#   - Sources core.zsh for error logging
# =============================================================================
_git_create_deploy_pr() {
    local draft_branch="$1"
    local prod_branch="$2"
    local title="$3"
    local body="$4"

    # Source core helpers for logging
    source "${0:A:h}/core.zsh" 2>/dev/null || return 1

    # Check if gh CLI is available
    if ! command -v gh &>/dev/null; then
        _flow_log_error "gh CLI not found. Install with: brew install gh"
        _flow_log_info "  Run: brew install gh && gh auth login"
        return 1
    fi

    # Check if gh is authenticated
    if ! gh auth status &>/dev/null; then
        _flow_log_error "gh CLI not authenticated"
        _flow_log_info "  Run: gh auth login"
        return 1
    fi

    # Create PR from draft to production branch
    if gh pr create \
        --base "$prod_branch" \
        --head "$draft_branch" \
        --title "$title" \
        --body "$body" \
        --label "teaching,deploy" 2>&1; then
        return 0
    else
        _flow_log_error "Failed to create pull request"
        return 1
    fi
}

# =============================================================================
# Function: _git_in_repo
# Purpose: Check if current directory is inside a git repository
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - In a git repository
#   1 - Not in a git repository
#
# Example:
#   if _git_in_repo; then
#       echo "Branch: $(_git_current_branch)"
#   else
#       echo "Not a git repository"
#   fi
#
# Notes:
#   - Works from any subdirectory of the repo
#   - Suppresses all error output
# =============================================================================
_git_in_repo() {
    git rev-parse --is-inside-work-tree &>/dev/null
}

# =============================================================================
# Function: _git_current_branch
# Purpose: Get the name of the current git branch
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Branch name, or empty if not in git repo
#
# Example:
#   local branch=$(_git_current_branch)
#   echo "Currently on: $branch"
#
# Special Cases:
#   - Detached HEAD returns "HEAD"
#   - Not in repo returns empty string
# =============================================================================
_git_current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null
}

# =============================================================================
# Function: _git_remote_branch
# Purpose: Get the upstream tracking branch name
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Remote branch name (e.g., "origin/main"), or empty if none
#
# Example:
#   local upstream=$(_git_remote_branch)
#   if [[ -n "$upstream" ]]; then
#       echo "Tracking: $upstream"
#   else
#       echo "No upstream configured"
#   fi
#
# Notes:
#   - Returns empty if no upstream branch configured
#   - Format: remote/branch (e.g., "origin/main")
# =============================================================================
_git_remote_branch() {
    git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null
}

# =============================================================================
# Function: _git_commit_teaching_content
# Purpose: Commit staged files with a teaching-formatted message
# =============================================================================
# Arguments:
#   $1 - (required) Commit message (usually from _git_teaching_commit_message)
#
# Returns:
#   0 - Commit successful
#   1 - Error (no staged changes or commit failed)
#
# Example:
#   git add exams/midterm.qmd
#   local msg=$(_git_teaching_commit_message "exam" "Midterm" ...)
#   _git_commit_teaching_content "$msg"
#
# Notes:
#   - Requires files to be staged first (git add)
#   - Uses _flow_log functions for status output
#   - Fails gracefully if nothing staged
# =============================================================================
_git_commit_teaching_content() {
    local message="$1"

    # Verify we have staged changes
    if [[ -z "$(git diff --cached --name-only 2>/dev/null)" ]]; then
        _flow_log_error "No staged changes to commit"
        return 1
    fi

    # Commit with the generated message
    if git commit -m "$message" 2>/dev/null; then
        _flow_log_success "Committed changes"
        return 0
    else
        _flow_log_error "Failed to commit changes"
        return 1
    fi
}

# =============================================================================
# Function: _git_push_current_branch
# Purpose: Push current branch to origin remote
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Push successful
#   1 - Error (not on branch or push failed)
#
# Example:
#   if _git_push_current_branch; then
#       echo "Changes pushed"
#   fi
#
# Notes:
#   - Always pushes to 'origin' remote
#   - Requires branch to exist on remote (use -u for first push)
#   - Shows git push output for progress
# =============================================================================
_git_push_current_branch() {
    local branch=$(_git_current_branch)

    if [[ -z "$branch" ]]; then
        _flow_log_error "Not on a branch"
        return 1
    fi

    # Push to remote
    if git push origin "$branch" 2>&1; then
        _flow_log_success "Pushed to origin/$branch"
        return 0
    else
        _flow_log_error "Failed to push to origin/$branch"
        return 1
    fi
}

# ============================================================================
# PHASE 2: BRANCH-AWARE DEPLOYMENT (v5.11.0+)
# ============================================================================

# =============================================================================
# Function: _git_detect_production_conflicts
# Purpose: Check if production branch has commits that could cause conflicts
# =============================================================================
# Arguments:
#   $1 - (required) Draft/development branch name
#   $2 - (required) Production branch name
#
# Returns:
#   0 - No conflicts (production hasn't diverged)
#   1 - Potential conflicts (production has new commits)
#
# Example:
#   if ! _git_detect_production_conflicts "draft" "main"; then
#       echo "Warning: Production has new commits"
#       echo "Consider rebasing before PR"
#   fi
#
# Notes:
#   - Fetches from remote before checking
#   - Uses merge-base to find common ancestor
#   - Returns 1 if production has commits since divergence
# =============================================================================
_git_detect_production_conflicts() {
    local draft_branch="$1"
    local prod_branch="$2"

    # Fetch latest from remote
    git fetch origin "$prod_branch" --quiet 2>/dev/null || return 1

    # Get merge base (common ancestor)
    local merge_base=$(git merge-base "$draft_branch" "origin/$prod_branch" 2>/dev/null)

    # Check if production branch has commits ahead of merge base
    local commits_ahead=$(git rev-list --count "${merge_base}..origin/${prod_branch}" 2>/dev/null || echo 0)

    if [[ $commits_ahead -gt 0 ]]; then
        return 1  # Conflicts detected (production has new commits)
    else
        return 0  # No conflicts
    fi
}

# =============================================================================
# Function: _git_get_commit_count
# Purpose: Count commits in draft branch not yet in production
# =============================================================================
# Arguments:
#   $1 - (required) Draft/development branch name
#   $2 - (required) Production branch name
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Number of commits (integer)
#
# Example:
#   local count=$(_git_get_commit_count "draft" "main")
#   echo "Ready to deploy $count commits"
#
# Notes:
#   - Compares against remote production branch
#   - Returns 0 if branches are identical or error
# =============================================================================
_git_get_commit_count() {
    local draft_branch="$1"
    local prod_branch="$2"

    git rev-list --count "origin/${prod_branch}..${draft_branch}" 2>/dev/null || echo 0
}

# =============================================================================
# Function: _git_get_commit_list
# Purpose: Get markdown-formatted list of commits for PR body
# =============================================================================
# Arguments:
#   $1 - (required) Draft/development branch name
#   $2 - (required) Production branch name
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Commit subjects as markdown list, one per line
#
# Example:
#   local commits=$(_git_get_commit_list "draft" "main")
#   # Output:
#   # - teach: add exam for Hypothesis Testing
#   # - teach: add lecture slides for Week 5
#   # - fix: correct typo in assignment
#
# Notes:
#   - Excludes merge commits
#   - Format: "- subject" (markdown list item)
#   - Empty output if no commits or error
# =============================================================================
_git_get_commit_list() {
    local draft_branch="$1"
    local prod_branch="$2"

    git log "origin/${prod_branch}..${draft_branch}" \
        --pretty=format:"- %s" \
        --no-merges 2>/dev/null || echo ""
}

# =============================================================================
# Function: _git_generate_pr_body
# Purpose: Generate complete markdown PR body for deployment
# =============================================================================
# Arguments:
#   $1 - (required) Draft/development branch name
#   $2 - (required) Production branch name
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Complete markdown PR body with:
#     - Changes section (commit list)
#     - Commits section (count and branch info)
#     - Deploy checklist
#     - Attribution footer
#
# Example:
#   local body=$(_git_generate_pr_body "draft" "main")
#   gh pr create --body "$body" ...
#
# Notes:
#   - Uses _git_get_commit_count and _git_get_commit_list
#   - Includes standard deploy checklist items
#   - Attribution shows teach deploy command
# =============================================================================
_git_generate_pr_body() {
    local draft_branch="$1"
    local prod_branch="$2"

    local commit_count=$(_git_get_commit_count "$draft_branch" "$prod_branch")
    local commit_list=$(_git_get_commit_list "$draft_branch" "$prod_branch")

    cat <<EOF
## Changes

${commit_list}

## Commits ($commit_count)

**From:** \`$draft_branch\`
**To:** \`$prod_branch\`

## Deploy Checklist

- [ ] Content reviewed for accuracy
- [ ] Links tested
- [ ] Build passes locally
- [ ] No broken references

---

🤖 Generated via: \`teach deploy\`
EOF
}

# =============================================================================
# Function: _git_rebase_onto_production
# Purpose: Rebase draft branch onto latest production
# =============================================================================
# Arguments:
#   $1 - (required) Draft/development branch name
#   $2 - (required) Production branch name
#
# Returns:
#   0 - Rebase successful
#   1 - Error (fetch failed or conflicts)
#
# Example:
#   if _git_rebase_onto_production "draft" "main"; then
#       echo "Ready for clean merge"
#   else
#       echo "Resolve conflicts manually"
#   fi
#
# Notes:
#   - Fetches latest production before rebase
#   - Provides helpful error messages on conflict
#   - User must resolve conflicts manually if they occur
# =============================================================================
_git_rebase_onto_production() {
    local draft_branch="$1"
    local prod_branch="$2"

    # Source core helpers for logging
    source "${0:A:h}/core.zsh" 2>/dev/null || return 1

    _flow_log_info "Rebasing $draft_branch onto origin/$prod_branch..."

    # Fetch latest
    git fetch origin "$prod_branch" --quiet 2>/dev/null || {
        _flow_log_error "Failed to fetch origin/$prod_branch"
        return 1
    }

    # Attempt rebase
    if git rebase "origin/$prod_branch" 2>&1; then
        _flow_log_success "Rebase successful"
        return 0
    else
        _flow_log_error "Rebase failed - conflicts detected"
        _flow_log_info "Resolve conflicts and run: git rebase --continue"
        _flow_log_info "Or abort with: git rebase --abort"
        return 1
    fi
}

# =============================================================================
# Function: _git_has_unpushed_commits
# Purpose: Check if current branch has local commits not pushed to remote
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Has unpushed commits
#   1 - All commits pushed (or no upstream)
#
# Example:
#   if _git_has_unpushed_commits; then
#       echo "You have local commits to push"
#   fi
#
# Notes:
#   - Requires upstream branch configured
#   - Returns 1 if no upstream (acts as "nothing to push")
#   - Does not fetch first (uses cached remote state)
# =============================================================================
_git_has_unpushed_commits() {
    local branch=$(_git_current_branch)

    # Get commits ahead of remote
    local ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)

    [[ $ahead -gt 0 ]]
}
