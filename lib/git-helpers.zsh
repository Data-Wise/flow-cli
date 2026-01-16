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
    git status --porcelain 2>/dev/null | \
        grep -E "$pattern" | \
        awk '{print $2}'
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

# Create deployment pull request (Phase 2 - stub for now)
# Usage: _git_create_deploy_pr <title> <body>
# Returns: 0 on success, 1 on error
_git_create_deploy_pr() {
    local title="$1"
    local body="$2"

    # Check if gh CLI is available
    if ! command -v gh &>/dev/null; then
        _flow_log_error "gh CLI not found. Install with: brew install gh"
        return 1
    fi

    # Create PR from draft to main (default branches)
    gh pr create \
        --base main \
        --head draft \
        --title "$title" \
        --body "$body" \
        --label "teaching,deploy"
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
