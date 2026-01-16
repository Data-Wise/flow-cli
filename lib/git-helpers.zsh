#!/usr/bin/env zsh
# git-helpers.zsh - Git integration functions for teaching workflow
# Part of flow-cli v5.11.0 - Teaching + Git Integration Enhancement
# Phase 1: Smart post-generation workflow

# Generate commit message for teaching content
# Usage: _git_teaching_commit_message <type> <topic> <command> <course> <semester> <year>
# Example: _git_teaching_commit_message "exam" "Hypothesis Testing" "teach exam \"Hypothesis Testing\" --questions 20" "STAT 545" "Fall" "2024"
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

# Check if current branch is clean (no uncommitted changes)
# Returns: 0 if clean, 1 if dirty
_git_is_clean() {
    [[ -z "$(git status --porcelain 2>/dev/null)" ]]
}

# Check if remote is up-to-date (no unpushed/unpulled commits)
# Returns: 0 if synced, 1 if behind/ahead/diverged
_git_is_synced() {
    # Silently fetch latest from remote
    git fetch --quiet 2>/dev/null || return 1

    local ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
    local behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo 0)

    [[ $ahead -eq 0 && $behind -eq 0 ]]
}

# Get list of teaching-related files (uncommitted changes only)
# Returns: List of file paths (one per line)
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

# Interactive commit workflow for teaching content
# Usage: _git_interactive_commit <file> <type> <topic> <command> <course> <semester> <year>
# Returns: 0 on success, 1 on skip/error
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

# Create deployment pull request (Phase 2 - v5.11.0+)
# Usage: _git_create_deploy_pr <draft_branch> <prod_branch> <title> <body>
# Returns: 0 on success, 1 on error
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

# Detect if we're in a git repository
# Returns: 0 if in git repo, 1 otherwise
_git_in_repo() {
    git rev-parse --is-inside-work-tree &>/dev/null
}

# Get current git branch name
# Returns: Branch name or empty string if not in git repo
_git_current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null
}

# Get remote tracking branch name
# Returns: Remote branch name or empty string
_git_remote_branch() {
    git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null
}

# Commit staged files with generated message
# Usage: _git_commit_teaching_content <message>
# Returns: 0 on success, 1 on error
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

# Push current branch to remote
# Usage: _git_push_current_branch
# Returns: 0 on success, 1 on error
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

# Check if production branch has new commits (conflict detection)
# Usage: _git_detect_production_conflicts <draft_branch> <prod_branch>
# Returns: 0 if no conflicts, 1 if production has new commits
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

# Get commit count between draft and production
# Usage: _git_get_commit_count <draft_branch> <prod_branch>
# Returns: Number of commits in draft ahead of production
_git_get_commit_count() {
    local draft_branch="$1"
    local prod_branch="$2"

    git rev-list --count "origin/${prod_branch}..${draft_branch}" 2>/dev/null || echo 0
}

# Get list of commits for PR body
# Usage: _git_get_commit_list <draft_branch> <prod_branch>
# Returns: Formatted commit list (one per line)
_git_get_commit_list() {
    local draft_branch="$1"
    local prod_branch="$2"

    git log "origin/${prod_branch}..${draft_branch}" \
        --pretty=format:"- %s" \
        --no-merges 2>/dev/null || echo ""
}

# Generate PR body for deployment
# Usage: _git_generate_pr_body <draft_branch> <prod_branch>
# Returns: Formatted PR body with commits and metadata
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

# Rebase draft onto production branch
# Usage: _git_rebase_onto_production <draft_branch> <prod_branch>
# Returns: 0 on success, 1 on error/conflicts
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

# Check if current branch has unpushed commits
# Returns: 0 if has unpushed commits, 1 if all pushed
_git_has_unpushed_commits() {
    local branch=$(_git_current_branch)

    # Get commits ahead of remote
    local ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)

    [[ $ahead -gt 0 ]]
}
