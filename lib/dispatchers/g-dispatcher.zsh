#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# G - Git Commands Dispatcher
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         ~/.config/zsh/functions/g-dispatcher.zsh
# Version:      1.0
# Date:         2025-12-17
# Pattern:      command + keyword + options
#
# Usage:        g <action> [args]
#
# Examples:
#   g                   # Status (short)
#   g status            # Full status
#   g add .             # Stage all
#   g commit "msg"      # Commit with message
#   g push              # Push to remote
#   g log               # Pretty log
#   g help              # Show all commands

# Unalias conflicting OMZ git plugin alias
# (Our dispatcher provides a smarter g command)
unalias g 2>/dev/null
#
# ══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════
# COLOR DEFINITIONS
# ═══════════════════════════════════════════════════════════════════

if [[ -z "$_C_BOLD" ]]; then
    _C_BOLD='\033[1m'
    _C_DIM='\033[2m'
    _C_NC='\033[0m'
    _C_RED='\033[31m'
    _C_GREEN='\033[32m'
    _C_YELLOW='\033[33m'
    _C_BLUE='\033[34m'
    _C_MAGENTA='\033[35m'
    _C_CYAN='\033[36m'
fi

# ═══════════════════════════════════════════════════════════════════
# MAIN G() DISPATCHER
# ═══════════════════════════════════════════════════════════════════

g() {
    # No arguments → git status (short)
    if [[ $# -eq 0 ]]; then
        git status -sb
        return
    fi

    case "$1" in
        # ─────────────────────────────────────────────────────────────
        # STATUS & INFO
        # ─────────────────────────────────────────────────────────────
        status|s)
            shift
            git status "$@"
            ;;

        diff|d)
            shift
            git diff "$@"
            ;;

        ds|staged)
            shift
            git diff --staged "$@"
            ;;

        log|l)
            shift
            git log --oneline --graph --decorate -20 "$@"
            ;;

        loga|la)
            shift
            git log --oneline --graph --decorate --all -20 "$@"
            ;;

        blame|bl)
            shift
            git blame "$@"
            ;;

        # ─────────────────────────────────────────────────────────────
        # STAGING & COMMITS
        # ─────────────────────────────────────────────────────────────
        add|a)
            shift
            git add "$@"
            ;;

        aa)
            git add --all
            ;;

        commit|c)
            shift
            if [[ $# -eq 0 ]]; then
                git commit
            else
                git commit -m "$*"
            fi
            ;;

        amend)
            git commit --amend --no-edit
            ;;

        amendm)
            shift
            git commit --amend -m "$*"
            ;;

        # ─────────────────────────────────────────────────────────────
        # BRANCHES
        # ─────────────────────────────────────────────────────────────
        branch|b)
            shift
            git branch "$@"
            ;;

        ba)
            git branch -a
            ;;

        checkout|co)
            shift
            git checkout "$@"
            ;;

        cob)
            shift
            git checkout -b "$@"
            ;;

        switch|sw)
            shift
            git switch "$@"
            ;;

        swc)
            shift
            git switch -c "$@"
            ;;

        main|m)
            git checkout main 2>/dev/null || git checkout master
            ;;

        # ─────────────────────────────────────────────────────────────
        # REMOTE OPERATIONS
        # ─────────────────────────────────────────────────────────────
        push|p)
            shift
            # Check workflow guard (unless GIT_WORKFLOW_SKIP=1)
            if [[ -z "$GIT_WORKFLOW_SKIP" ]]; then
                _g_check_workflow || return 1
            fi
            git push "$@"
            ;;

        pushu|pu)
            git push -u origin HEAD
            ;;

        pull|pl)
            shift
            git pull "$@"
            ;;

        fetch|f)
            shift
            git fetch "$@"
            ;;

        fa)
            git fetch --all
            ;;

        # ─────────────────────────────────────────────────────────────
        # STASH
        # ─────────────────────────────────────────────────────────────
        stash|st)
            shift
            if [[ $# -eq 0 ]]; then
                git stash
            else
                git stash "$@"
            fi
            ;;

        pop|stp)
            git stash pop
            ;;

        stl)
            git stash list
            ;;

        # ─────────────────────────────────────────────────────────────
        # RESET & UNDO
        # ─────────────────────────────────────────────────────────────
        reset|rs)
            shift
            git reset "$@"
            ;;

        undo)
            echo "${_C_YELLOW}Undoing last commit (keeping changes)...${_C_NC}"
            git reset --soft HEAD~1
            ;;

        unstage)
            shift
            git reset HEAD "$@"
            ;;

        discard)
            shift
            git checkout -- "$@"
            ;;

        clean)
            echo "${_C_YELLOW}Removing untracked files...${_C_NC}"
            git clean -fd
            ;;

        # ─────────────────────────────────────────────────────────────
        # REBASE & MERGE
        # ─────────────────────────────────────────────────────────────
        rebase|rb)
            shift
            git rebase "$@"
            ;;

        rbc)
            git rebase --continue
            ;;

        rba)
            git rebase --abort
            ;;

        merge|mg)
            shift
            git merge "$@"
            ;;

        # ─────────────────────────────────────────────────────────────
        # FEATURE WORKFLOW
        # ─────────────────────────────────────────────────────────────
        feature|feat)
            shift
            _g_feature "$@"
            ;;

        promote)
            _g_promote
            ;;

        release|rel)
            _g_release
            ;;

        # ─────────────────────────────────────────────────────────────
        # HELP
        # ─────────────────────────────────────────────────────────────
        help|h|--help|-h)
            _g_help
            ;;

        # ─────────────────────────────────────────────────────────────
        # PASSTHROUGH (anything else goes to git)
        # ─────────────────────────────────────────────────────────────
        *)
            git "$@"
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# HELP SYSTEM
# ═══════════════════════════════════════════════════════════════════

_g_help() {
    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ g - Git Commands                            │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_BOLD}Usage:${_C_NC} g [subcommand] [args]

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}g${_C_NC}                 Status (short)
  ${_C_CYAN}g add .${_C_NC}           Stage all changes
  ${_C_CYAN}g commit \"msg\"${_C_NC}   Commit with message
  ${_C_CYAN}g push${_C_NC}            Push to remote
  ${_C_CYAN}g pull${_C_NC}            Pull from remote

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} g                      ${_C_DIM}# Quick status${_C_NC}
  ${_C_DIM}\$${_C_NC} g aa                   ${_C_DIM}# Add all${_C_NC}
  ${_C_DIM}\$${_C_NC} g commit \"fix bug\"    ${_C_DIM}# Commit${_C_NC}
  ${_C_DIM}\$${_C_NC} g push                 ${_C_DIM}# Push${_C_NC}
  ${_C_DIM}\$${_C_NC} g undo                 ${_C_DIM}# Undo last commit${_C_NC}

${_C_BLUE}📋 STATUS & INFO${_C_NC}:
  ${_C_CYAN}g${_C_NC} / ${_C_CYAN}g s${_C_NC}          Status
  ${_C_CYAN}g d${_C_NC} / ${_C_CYAN}g diff${_C_NC}     Show diff
  ${_C_CYAN}g ds${_C_NC}              Staged diff
  ${_C_CYAN}g l${_C_NC} / ${_C_CYAN}g log${_C_NC}      Pretty log (20)
  ${_C_CYAN}g la${_C_NC}              Log all branches
  ${_C_CYAN}g blame <file>${_C_NC}    Blame

${_C_BLUE}📝 STAGING & COMMITS${_C_NC}:
  ${_C_CYAN}g a${_C_NC} / ${_C_CYAN}g add${_C_NC}      Add files
  ${_C_CYAN}g aa${_C_NC}              Add all
  ${_C_CYAN}g c${_C_NC} / ${_C_CYAN}g commit${_C_NC}   Commit
  ${_C_CYAN}g commit \"msg\"${_C_NC}   Commit with message
  ${_C_CYAN}g amend${_C_NC}           Amend (no edit)
  ${_C_CYAN}g amendm \"msg\"${_C_NC}   Amend with message

${_C_BLUE}🌿 BRANCHES${_C_NC}:
  ${_C_CYAN}g b${_C_NC} / ${_C_CYAN}g branch${_C_NC}   List branches
  ${_C_CYAN}g ba${_C_NC}              All branches
  ${_C_CYAN}g co <b>${_C_NC}          Checkout branch
  ${_C_CYAN}g cob <b>${_C_NC}         Create & checkout
  ${_C_CYAN}g sw <b>${_C_NC}          Switch branch
  ${_C_CYAN}g swc <b>${_C_NC}         Switch create
  ${_C_CYAN}g main${_C_NC}            Checkout main/master

${_C_BLUE}🔄 REMOTE${_C_NC}:
  ${_C_CYAN}g p${_C_NC} / ${_C_CYAN}g push${_C_NC}     Push
  ${_C_CYAN}g pu${_C_NC}              Push -u origin HEAD
  ${_C_CYAN}g pl${_C_NC} / ${_C_CYAN}g pull${_C_NC}    Pull
  ${_C_CYAN}g f${_C_NC} / ${_C_CYAN}g fetch${_C_NC}    Fetch
  ${_C_CYAN}g fa${_C_NC}              Fetch all

${_C_BLUE}📦 STASH${_C_NC}:
  ${_C_CYAN}g st${_C_NC} / ${_C_CYAN}g stash${_C_NC}   Stash
  ${_C_CYAN}g pop${_C_NC}             Stash pop
  ${_C_CYAN}g stl${_C_NC}             Stash list

${_C_BLUE}⏪ RESET & UNDO${_C_NC}:
  ${_C_CYAN}g undo${_C_NC}            Undo last commit (soft)
  ${_C_CYAN}g unstage <f>${_C_NC}     Unstage file
  ${_C_CYAN}g discard <f>${_C_NC}     Discard changes
  ${_C_CYAN}g clean${_C_NC}           Remove untracked

${_C_BLUE}🔀 REBASE & MERGE${_C_NC}:
  ${_C_CYAN}g rb${_C_NC}              Rebase
  ${_C_CYAN}g rbc${_C_NC}             Rebase continue
  ${_C_CYAN}g rba${_C_NC}             Rebase abort
  ${_C_CYAN}g mg${_C_NC}              Merge

${_C_BLUE}🌳 FEATURE WORKFLOW${_C_NC}:
  ${_C_CYAN}g feature start <n>${_C_NC}  Create feature branch from dev
  ${_C_CYAN}g feature sync${_C_NC}       Rebase feature onto dev
  ${_C_CYAN}g feature list${_C_NC}       List feature/hotfix branches
  ${_C_CYAN}g feature finish${_C_NC}     Push + create PR to dev
  ${_C_CYAN}g promote${_C_NC}            PR: feature → dev
  ${_C_CYAN}g release${_C_NC}            PR: dev → main

${_C_MAGENTA}💡 TIP${_C_NC}: Unknown commands pass through to git
  ${_C_DIM}g remote -v        → git remote -v${_C_NC}
  ${_C_DIM}g cherry-pick xxx  → git cherry-pick xxx${_C_NC}

${_C_DIM}📚 See also:${_C_NC}
  ${_C_CYAN}wt${_C_NC} - Manage git worktrees
  ${_C_CYAN}cc wt${_C_NC} - Launch Claude in worktree
  ${_C_CYAN}flow sync${_C_NC} - Sync project state & git
"
}

# ═══════════════════════════════════════════════════════════════════
# FEATURE WORKFLOW
# ═══════════════════════════════════════════════════════════════════

_g_feature() {
    local action="${1:-help}"
    shift 2>/dev/null

    case "$action" in
        start|s)
            local name="$1"
            if [[ -z "$name" ]]; then
                echo -e "${_C_RED}✗ Feature name required${_C_NC}"
                echo "Usage: g feature start <name>"
                return 1
            fi
            # Ensure clean state
            if ! git diff --quiet HEAD 2>/dev/null; then
                echo -e "${_C_YELLOW}⚠ You have uncommitted changes. Stash or commit first.${_C_NC}"
                return 1
            fi
            git checkout dev && git pull origin dev
            git checkout -b "feature/$name"
            echo -e "${_C_GREEN}✓ Created feature/$name from dev${_C_NC}"
            ;;

        sync)
            local branch=$(git branch --show-current)
            if [[ "$branch" != feature/* ]]; then
                echo -e "${_C_RED}✗ Not on a feature branch (current: $branch)${_C_NC}"
                return 1
            fi
            git fetch origin
            git rebase origin/dev
            echo -e "${_C_GREEN}✓ Rebased $branch onto dev${_C_NC}"
            ;;

        list|ls)
            echo -e "${_C_BOLD}Feature branches:${_C_NC}"
            git branch --list 'feature/*' 2>/dev/null | sed 's/^/  /' || echo "  (none)"
            echo -e "\n${_C_BOLD}Hotfix branches:${_C_NC}"
            git branch --list 'hotfix/*' 2>/dev/null | sed 's/^/  /' || echo "  (none)"
            echo -e "\n${_C_BOLD}Bugfix branches:${_C_NC}"
            git branch --list 'bugfix/*' 2>/dev/null | sed 's/^/  /' || echo "  (none)"
            ;;

        finish|done)
            local branch=$(git branch --show-current)
            if [[ "$branch" != feature/* && "$branch" != bugfix/* ]]; then
                echo -e "${_C_RED}✗ Not on a feature/bugfix branch${_C_NC}"
                return 1
            fi
            echo -e "${_C_BLUE}ℹ Creating PR: $branch → dev${_C_NC}"
            git push -u origin HEAD
            gh pr create --base dev --fill
            ;;

        prune|clean)
            _g_feature_prune "$@"
            ;;

        status|st)
            _g_feature_status "$@"
            ;;

        help|--help|-h|*)
            _g_feature_help
            ;;
    esac
}

_g_feature_help() {
    echo -e "
${_C_BOLD}g feature${_C_NC} - Feature branch workflow

${_C_YELLOW}COMMANDS${_C_NC}:
  ${_C_CYAN}g feature start <name>${_C_NC}   Create feature branch from dev
  ${_C_CYAN}g feature sync${_C_NC}           Rebase feature onto dev
  ${_C_CYAN}g feature list${_C_NC}           List feature/hotfix/bugfix branches
  ${_C_CYAN}g feature finish${_C_NC}         Push and create PR to dev
  ${_C_CYAN}g feature status${_C_NC}         Show merged vs active branches
  ${_C_CYAN}g feature prune${_C_NC}          Delete merged branches

${_C_YELLOW}WORKFLOW${_C_NC}:
  ${_C_DIM}feature/*${_C_NC} ──► ${_C_CYAN}dev${_C_NC} ──► ${_C_GREEN}main${_C_NC}
  ${_C_DIM}hotfix/*${_C_NC}  ────┴───────┘
  ${_C_DIM}bugfix/*${_C_NC}  ────┘

${_C_YELLOW}EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} g feature start auth       ${_C_DIM}# → feature/auth from dev${_C_NC}
  ${_C_DIM}\$${_C_NC} g feature sync             ${_C_DIM}# Rebase onto dev${_C_NC}
  ${_C_DIM}\$${_C_NC} g feature finish           ${_C_DIM}# Push + PR to dev${_C_NC}
  ${_C_DIM}\$${_C_NC} g feature status           ${_C_DIM}# Show stale vs active${_C_NC}
  ${_C_DIM}\$${_C_NC} g feature prune            ${_C_DIM}# Delete merged branches${_C_NC}
  ${_C_DIM}\$${_C_NC} g feature prune --all      ${_C_DIM}# Also clean remotes${_C_NC}
  ${_C_DIM}\$${_C_NC} g feature prune --older-than 30d  ${_C_DIM}# Only old branches${_C_NC}
"
}

# ═══════════════════════════════════════════════════════════════════
# FEATURE STATUS
# ═══════════════════════════════════════════════════════════════════

_g_feature_status() {
    # Determine base branch
    local base_branch="dev"
    if ! git show-ref --verify --quiet refs/heads/dev 2>/dev/null; then
        base_branch="main"
    fi

    echo -e "${_C_BOLD}📊 Feature Branch Status${_C_NC}"
    echo -e "${_C_DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_C_NC}"

    # Stale (merged) branches
    echo -e "\n${_C_GREEN}🧹 Stale branches${_C_NC} ${_C_DIM}(merged to $base_branch)${_C_NC}:"
    local stale_count=0
    local branch age
    while IFS= read -r branch; do
        branch="${branch#\* }"
        branch="${branch#"${branch%%[![:space:]]*}"}"
        branch="${branch%"${branch##*[![:space:]]}"}"
        [[ -z "$branch" ]] && continue
        [[ "$branch" == feature/* || "$branch" == bugfix/* || "$branch" == hotfix/* ]] || continue
        age=$(git log -1 --format="%cr" "$branch" 2>/dev/null)
        printf "  ${_C_DIM}•${_C_NC} %-40s ${_C_DIM}(%s)${_C_NC}\n" "$branch" "$age"
        ((stale_count++))
    done < <(git branch --merged "$base_branch" 2>/dev/null)
    [[ $stale_count -eq 0 ]] && echo -e "  ${_C_DIM}(none)${_C_NC}"

    # Active (unmerged) branches
    echo -e "\n${_C_YELLOW}⚠️  Active branches${_C_NC} ${_C_DIM}(not merged to $base_branch)${_C_NC}:"
    local active_count=0
    local commits
    while IFS= read -r branch; do
        branch="${branch#\* }"
        branch="${branch#"${branch%%[![:space:]]*}"}"
        branch="${branch%"${branch##*[![:space:]]}"}"
        [[ -z "$branch" ]] && continue
        [[ "$branch" == feature/* || "$branch" == bugfix/* || "$branch" == hotfix/* ]] || continue
        commits=$(git rev-list --count "$base_branch".."$branch" 2>/dev/null || echo "?")
        age=$(git log -1 --format="%cr" "$branch" 2>/dev/null)
        printf "  ${_C_DIM}•${_C_NC} %-40s ${_C_CYAN}%s commits ahead${_C_NC} ${_C_DIM}(%s)${_C_NC}\n" "$branch" "$commits" "$age"
        ((active_count++))
    done < <(git branch --no-merged "$base_branch" 2>/dev/null)
    [[ $active_count -eq 0 ]] && echo -e "  ${_C_DIM}(none)${_C_NC}"

    # Summary and tip
    echo -e "\n${_C_DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_C_NC}"
    echo -e "${_C_BOLD}Summary:${_C_NC} $stale_count stale, $active_count active"
    if [[ $stale_count -gt 0 ]]; then
        echo -e "${_C_MAGENTA}💡 Tip:${_C_NC} Run ${_C_CYAN}g feature prune${_C_NC} to clean up merged branches"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# DURATION PARSER
# ═══════════════════════════════════════════════════════════════════

# Parse duration string to days: 30d → 30, 1w → 7, 2m → 60
_g_parse_duration() {
    local duration="$1"
    case "$duration" in
        *d) echo "${duration%d}" ;;
        *w) echo "$((${duration%w} * 7))" ;;
        *m) echo "$((${duration%m} * 30))" ;;
        *) echo "0" ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# FEATURE PRUNE
# ═══════════════════════════════════════════════════════════════════

_g_feature_prune() {
    local all_flag=false
    local dry_run=false
    local force_flag=false
    local older_than=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --all|-a) all_flag=true ;;
            --dry-run|-n) dry_run=true ;;
            --force|-f) force_flag=true ;;
            --older-than)
                shift
                older_than="$1"
                if [[ -z "$older_than" ]]; then
                    echo -e "${_C_RED}✗ --older-than requires a duration (e.g., 30d, 1w, 2m)${_C_NC}"
                    return 1
                fi
                ;;
            --help|-h) _g_feature_prune_help; return 0 ;;
            *) echo -e "${_C_RED}✗ Unknown option: $1${_C_NC}"; return 1 ;;
        esac
        shift
    done

    # Get current branch to avoid deleting it
    local current_branch=$(git branch --show-current 2>/dev/null)

    # Protected branches that should never be deleted
    local protected="main master dev develop"

    # Find merged feature/bugfix/hotfix branches
    local merged_branches=()
    local branch

    # Get branches merged to dev (or main if dev doesn't exist)
    local base_branch="dev"
    if ! git show-ref --verify --quiet refs/heads/dev 2>/dev/null; then
        base_branch="main"
    fi

    # Calculate age cutoff if --older-than specified
    local max_age_days=0
    local cutoff_time=0
    if [[ -n "$older_than" ]]; then
        max_age_days=$(_g_parse_duration "$older_than")
        if [[ $max_age_days -eq 0 ]]; then
            echo -e "${_C_RED}✗ Invalid duration format: $older_than${_C_NC}"
            echo "Use: 30d (days), 1w (weeks), 2m (months)"
            return 1
        fi
        cutoff_time=$(($(date +%s) - max_age_days * 86400))
        echo -e "${_C_BLUE}ℹ Filtering branches older than $older_than${_C_NC}\n"
    fi

    # Collect merged local branches
    while IFS= read -r branch; do
        # Skip empty lines
        [[ -z "$branch" ]] && continue
        # Remove leading asterisk (current branch marker)
        branch="${branch#\* }"
        # Remove all leading/trailing whitespace
        branch="${branch#"${branch%%[![:space:]]*}"}"
        branch="${branch%"${branch##*[![:space:]]}"}"
        # Skip protected branches
        [[ " $protected " == *" $branch "* ]] && continue
        # Skip current branch
        [[ "$branch" == "$current_branch" ]] && continue
        # Only include feature/bugfix/hotfix branches
        if [[ "$branch" == feature/* || "$branch" == bugfix/* || "$branch" == hotfix/* ]]; then
            # Apply age filter if specified
            if [[ $cutoff_time -gt 0 ]]; then
                local commit_time=$(git log -1 --format=%ct "$branch" 2>/dev/null || echo "0")
                [[ $commit_time -ge $cutoff_time ]] && continue  # Skip if too recent
            fi
            merged_branches+=("$branch")
        fi
    done < <(git branch --merged "$base_branch" 2>/dev/null)

    # Report what we found
    if [[ ${#merged_branches[@]} -eq 0 ]]; then
        echo -e "${_C_GREEN}✓ No merged feature branches to prune${_C_NC}"
    else
        echo -e "${_C_BOLD}Merged branches to delete:${_C_NC}"
        for branch in "${merged_branches[@]}"; do
            echo -e "  ${_C_DIM}•${_C_NC} $branch"
        done
        echo ""

        if [[ "$dry_run" == true ]]; then
            echo -e "${_C_YELLOW}Dry run - no branches deleted${_C_NC}"
        else
            # Confirm unless --force
            if [[ "$force_flag" != true ]]; then
                echo -n "Delete ${#merged_branches[@]} branch(es)? [y/N] "
                read -r confirm
                if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                    echo -e "${_C_YELLOW}Cancelled${_C_NC}"
                    return 0
                fi
            fi

            # Delete local branches
            local deleted=0
            for branch in "${merged_branches[@]}"; do
                if git branch -d "$branch" 2>/dev/null; then
                    echo -e "${_C_GREEN}✓ Deleted${_C_NC} $branch"
                    ((deleted++))
                else
                    echo -e "${_C_RED}✗ Failed to delete${_C_NC} $branch"
                fi
            done
            echo -e "\n${_C_GREEN}Deleted $deleted local branch(es)${_C_NC}"
        fi
    fi

    # Handle remote branches if --all flag
    if [[ "$all_flag" == true ]]; then
        echo -e "\n${_C_BOLD}Checking remote branches...${_C_NC}"

        # Prune stale remote tracking references first
        git remote prune origin 2>/dev/null

        # Find remote branches that are merged
        local remote_merged=()
        while IFS= read -r branch; do
            [[ -z "$branch" ]] && continue
            # Remove 'origin/' prefix
            local short_branch="${branch#origin/}"
            # Skip protected
            [[ " $protected " == *" $short_branch "* ]] && continue
            # Only feature/bugfix/hotfix
            if [[ "$short_branch" == feature/* || "$short_branch" == bugfix/* || "$short_branch" == hotfix/* ]]; then
                # Apply age filter if specified
                if [[ $cutoff_time -gt 0 ]]; then
                    local commit_time=$(git log -1 --format=%ct "origin/$short_branch" 2>/dev/null || echo "0")
                    [[ $commit_time -ge $cutoff_time ]] && continue  # Skip if too recent
                fi
                remote_merged+=("$short_branch")
            fi
        done < <(git branch -r --merged "$base_branch" 2>/dev/null | grep "origin/" | sed 's/^[[:space:]]*//')

        if [[ ${#remote_merged[@]} -eq 0 ]]; then
            echo -e "${_C_GREEN}✓ No merged remote branches to prune${_C_NC}"
        else
            echo -e "${_C_BOLD}Remote branches to delete:${_C_NC}"
            for branch in "${remote_merged[@]}"; do
                echo -e "  ${_C_DIM}•${_C_NC} origin/$branch"
            done
            echo ""

            if [[ "$dry_run" == true ]]; then
                echo -e "${_C_YELLOW}Dry run - no remote branches deleted${_C_NC}"
            else
                # Confirm unless --force
                if [[ "$force_flag" != true ]]; then
                    echo -n "Delete ${#remote_merged[@]} remote branch(es)? [y/N] "
                    read -r confirm
                    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                        echo -e "${_C_YELLOW}Cancelled${_C_NC}"
                        return 0
                    fi
                fi

                local remote_deleted=0
                for branch in "${remote_merged[@]}"; do
                    if git push origin --delete "$branch" 2>/dev/null; then
                        echo -e "${_C_GREEN}✓ Deleted${_C_NC} origin/$branch"
                        ((remote_deleted++))
                    else
                        echo -e "${_C_RED}✗ Failed to delete${_C_NC} origin/$branch"
                    fi
                done
                echo -e "\n${_C_GREEN}Deleted $remote_deleted remote branch(es)${_C_NC}"
            fi
        fi
    fi
}

_g_feature_prune_help() {
    echo -e "
${_C_BOLD}g feature prune${_C_NC} - Clean up merged feature branches

${_C_YELLOW}USAGE${_C_NC}:
  ${_C_CYAN}g feature prune${_C_NC}                   Delete local merged branches (with confirmation)
  ${_C_CYAN}g feature prune --force${_C_NC}           Skip confirmation prompts
  ${_C_CYAN}g feature prune --all${_C_NC}             Also delete remote branches
  ${_C_CYAN}g feature prune --dry-run${_C_NC}         Show what would be deleted
  ${_C_CYAN}g feature prune --older-than 30d${_C_NC}  Only branches older than 30 days

${_C_YELLOW}OPTIONS${_C_NC}:
  ${_C_CYAN}--force, -f${_C_NC}         Skip confirmation prompts
  ${_C_CYAN}--all, -a${_C_NC}           Also prune remote branches
  ${_C_CYAN}--dry-run, -n${_C_NC}       Show what would be deleted without deleting
  ${_C_CYAN}--older-than <d>${_C_NC}    Only prune branches older than duration
  ${_C_CYAN}--help, -h${_C_NC}          Show this help

${_C_YELLOW}DURATION FORMAT${_C_NC}:
  ${_C_DIM}30d${_C_NC}  → 30 days
  ${_C_DIM}1w${_C_NC}   → 1 week (7 days)
  ${_C_DIM}2m${_C_NC}   → 2 months (60 days)

${_C_YELLOW}SAFE BY DEFAULT${_C_NC}:
  • Asks for confirmation before deleting
  • Only deletes branches merged to dev (or main)
  • Never deletes: main, master, dev, develop
  • Never deletes current branch
  • Only targets: feature/*, bugfix/*, hotfix/*

${_C_YELLOW}EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} g feature prune               ${_C_DIM}# Clean local (with confirmation)${_C_NC}
  ${_C_DIM}\$${_C_NC} g feature prune -f            ${_C_DIM}# Clean local (no confirmation)${_C_NC}
  ${_C_DIM}\$${_C_NC} g feature prune -n            ${_C_DIM}# Preview what would be deleted${_C_NC}
  ${_C_DIM}\$${_C_NC} g feature prune --all         ${_C_DIM}# Also clean remote branches${_C_NC}
  ${_C_DIM}\$${_C_NC} g feature prune --older-than 30d  ${_C_DIM}# Only >30 days old${_C_NC}
  ${_C_DIM}\$${_C_NC} g feature prune --older-than 1w   ${_C_DIM}# Only >1 week old${_C_NC}
"
}

# ═══════════════════════════════════════════════════════════════════
# PROMOTE & RELEASE
# ═══════════════════════════════════════════════════════════════════

_g_promote() {
    local branch=$(git branch --show-current)

    # Validate branch type
    if [[ "$branch" != feature/* && "$branch" != bugfix/* && "$branch" != hotfix/* ]]; then
        echo -e "${_C_RED}✗ Not on a promotable branch (feature/*, bugfix/*, hotfix/*)${_C_NC}"
        echo -e "${_C_BLUE}ℹ Current branch: $branch${_C_NC}"
        return 1
    fi

    # Check for uncommitted changes
    if ! git diff --quiet HEAD 2>/dev/null; then
        echo -e "${_C_YELLOW}⚠ Uncommitted changes. Commit or stash first.${_C_NC}"
        return 1
    fi

    git push -u origin HEAD
    gh pr create --base dev --fill
    echo -e "${_C_GREEN}✓ Created PR: $branch → dev${_C_NC}"
}

_g_release() {
    local branch=$(git branch --show-current)

    if [[ "$branch" != "dev" ]]; then
        echo -e "${_C_RED}✗ Must be on 'dev' branch to create release PR${_C_NC}"
        echo -e "${_C_BLUE}ℹ Run: git checkout dev${_C_NC}"
        return 1
    fi

    # Ensure dev is up to date
    git fetch origin
    local behind=$(git rev-list --count HEAD..origin/dev 2>/dev/null || echo "0")
    if (( behind > 0 )); then
        echo -e "${_C_YELLOW}⚠ dev is $behind commits behind origin. Pull first.${_C_NC}"
        return 1
    fi

    gh pr create --base main --fill
    echo -e "${_C_GREEN}✓ Created PR: dev → main${_C_NC}"
}

# ═══════════════════════════════════════════════════════════════════
# WORKFLOW GUARD
# ═══════════════════════════════════════════════════════════════════

_g_check_workflow() {
    local branch=$(git branch --show-current 2>/dev/null)
    [[ -z "$branch" ]] && return 0  # Detached HEAD, allow

    # Allow hotfix to main
    [[ "$branch" == hotfix/* ]] && return 0

    # Block direct push to main/dev
    if [[ "$branch" == "main" || "$branch" == "master" || "$branch" == "dev" ]]; then
        echo -e "${_C_YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_C_NC}"
        echo -e "${_C_RED}⛔ Direct push to '${branch}' blocked${_C_NC}"
        echo -e "${_C_YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_C_NC}"
        echo ""
        echo -e "Workflow: ${_C_CYAN}feature/*${_C_NC} → ${_C_CYAN}dev${_C_NC} → ${_C_CYAN}main${_C_NC}"
        echo ""
        echo -e "${_C_BOLD}Use instead:${_C_NC}"
        if [[ "$branch" == "dev" ]]; then
            echo -e "  ${_C_CYAN}g release${_C_NC}     Create PR: dev → main"
        else
            echo -e "  ${_C_CYAN}g feature start <name>${_C_NC}  Start feature branch"
            echo -e "  ${_C_CYAN}g promote${_C_NC}               Create PR: feature → dev"
        fi
        echo ""
        echo -e "${_C_DIM}Override: GIT_WORKFLOW_SKIP=1 git push${_C_NC}"

        # Log violation (optional, for tracking)
        local log_file="${HOME}/.claude/workflow-violations.log"
        [[ -d "${HOME}/.claude" ]] && \
            echo "$(date +%Y-%m-%d\ %H:%M:%S) | push blocked | $branch | $(pwd)" >> "$log_file"

        return 1
    fi

    return 0
}
