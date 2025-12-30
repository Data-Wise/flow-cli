#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# WT - Git Worktree Dispatcher
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         lib/dispatchers/wt-dispatcher.zsh
# Version:      1.0
# Date:         2025-12-29
# Pattern:      command + keyword + options
#
# Usage:        wt <action> [args]
#
# Examples:
#   wt                   # Navigate to worktrees folder
#   wt list              # List all worktrees
#   wt create <branch>   # Create worktree for branch
#   wt clean             # Prune stale worktrees
#   wt help              # Show all commands
#
# ══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════
# COLOR DEFINITIONS (fallback if not loaded from core.zsh)
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
# CONFIGURATION
# ═══════════════════════════════════════════════════════════════════

FLOW_WORKTREE_DIR="${FLOW_WORKTREE_DIR:-$HOME/.git-worktrees}"

# ═══════════════════════════════════════════════════════════════════
# MAIN WT() DISPATCHER
# ═══════════════════════════════════════════════════════════════════

wt() {
    # No arguments → navigate to worktrees folder
    if [[ $# -eq 0 ]]; then
        if [[ -d "$FLOW_WORKTREE_DIR" ]]; then
            cd "$FLOW_WORKTREE_DIR"
            echo -e "${_C_BLUE}ℹ Changed to: $FLOW_WORKTREE_DIR${_C_NC}"
            ls -la
        else
            mkdir -p "$FLOW_WORKTREE_DIR"
            cd "$FLOW_WORKTREE_DIR"
            echo -e "${_C_GREEN}✓ Created and changed to: $FLOW_WORKTREE_DIR${_C_NC}"
        fi
        return
    fi

    case "$1" in
        # ─────────────────────────────────────────────────────────────
        # LIST
        # ─────────────────────────────────────────────────────────────
        list|ls|l)
            git worktree list
            ;;

        # ─────────────────────────────────────────────────────────────
        # CREATE
        # ─────────────────────────────────────────────────────────────
        create|add|c)
            shift
            _wt_create "$@"
            ;;

        # ─────────────────────────────────────────────────────────────
        # MOVE (current branch to worktree)
        # ─────────────────────────────────────────────────────────────
        move|mv)
            shift
            _wt_move "$@"
            ;;

        # ─────────────────────────────────────────────────────────────
        # CLEAN
        # ─────────────────────────────────────────────────────────────
        clean|prune)
            git worktree prune
            echo -e "${_C_GREEN}✓ Pruned stale worktrees${_C_NC}"
            ;;

        # ─────────────────────────────────────────────────────────────
        # REMOVE
        # ─────────────────────────────────────────────────────────────
        remove|rm)
            shift
            _wt_remove "$@"
            ;;

        # ─────────────────────────────────────────────────────────────
        # HELP
        # ─────────────────────────────────────────────────────────────
        help|h|--help|-h)
            _wt_help
            ;;

        # ─────────────────────────────────────────────────────────────
        # PASSTHROUGH (anything else goes to git worktree)
        # ─────────────────────────────────────────────────────────────
        *)
            git worktree "$@"
            ;;
    esac
}

# ═══════════════════════════════════════════════════════════════════
# WORKTREE UTILITIES
# ═══════════════════════════════════════════════════════════════════

# Get the path for a worktree given a branch name
# Returns empty string if worktree doesn't exist
_wt_get_path() {
    local branch="$1"
    [[ -z "$branch" ]] && return 1

    local git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    [[ -z "$git_root" ]] && return 1

    local project=$(basename "$git_root")
    local folder=$(echo "$branch" | tr '/' '-')
    local wt_path="$FLOW_WORKTREE_DIR/$project/$folder"

    # Return path if it exists
    if [[ -d "$wt_path" ]]; then
        echo "$wt_path"
        return 0
    fi

    return 1
}

# ═══════════════════════════════════════════════════════════════════
# WORKTREE OPERATIONS
# ═══════════════════════════════════════════════════════════════════

_wt_create() {
    local branch="$1"

    if [[ -z "$branch" ]]; then
        echo -e "${_C_RED}✗ Branch name required${_C_NC}"
        echo "Usage: wt create <branch>"
        echo "Examples:"
        echo "  wt create feature/auth"
        echo "  wt create hotfix/urgent-fix"
        return 1
    fi

    # Get project name from git root
    local git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$git_root" ]]; then
        echo -e "${_C_RED}✗ Not in a git repository${_C_NC}"
        return 1
    fi

    local project=$(basename "$git_root")
    local folder=$(echo "$branch" | tr '/' '-')
    local target_dir="$FLOW_WORKTREE_DIR/$project/$folder"

    # Create project directory if needed
    mkdir -p "$FLOW_WORKTREE_DIR/$project"

    # Check if branch exists
    if git show-ref --verify --quiet "refs/heads/$branch" 2>/dev/null; then
        # Branch exists, create worktree
        git worktree add "$target_dir" "$branch"
    else
        # Branch doesn't exist, create new branch
        git worktree add -b "$branch" "$target_dir"
    fi

    if [[ $? -eq 0 ]]; then
        echo -e "${_C_GREEN}✓ Created worktree: $target_dir${_C_NC}"
        echo ""
        echo -e "${_C_DIM}Navigate: cd $target_dir${_C_NC}"
    fi
}

_wt_move() {
    local branch=$(git branch --show-current 2>/dev/null)

    if [[ -z "$branch" ]]; then
        echo -e "${_C_RED}✗ Not on a branch (detached HEAD?)${_C_NC}"
        return 1
    fi

    if [[ "$branch" == "main" || "$branch" == "master" || "$branch" == "dev" ]]; then
        echo -e "${_C_RED}✗ Cannot move protected branch '$branch' to worktree${_C_NC}"
        return 1
    fi

    # Create worktree for current branch
    _wt_create "$branch"
}

_wt_remove() {
    local path="$1"

    if [[ -z "$path" ]]; then
        echo -e "${_C_RED}✗ Worktree path required${_C_NC}"
        echo "Usage: wt remove <path>"
        echo ""
        echo "Current worktrees:"
        git worktree list
        return 1
    fi

    git worktree remove "$path"
    if [[ $? -eq 0 ]]; then
        echo -e "${_C_GREEN}✓ Removed worktree: $path${_C_NC}"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# HELP SYSTEM
# ═══════════════════════════════════════════════════════════════════

_wt_help() {
    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ wt - Git Worktree Management                │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_BOLD}Usage:${_C_NC} wt [subcommand] [args]

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}wt${_C_NC}                 Navigate to worktrees folder
  ${_C_CYAN}wt list${_C_NC}            List all worktrees
  ${_C_CYAN}wt create <branch>${_C_NC} Create worktree for branch

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} wt create feature/auth   ${_C_DIM}# Create worktree${_C_NC}
  ${_C_DIM}\$${_C_NC} wt list                  ${_C_DIM}# Show all worktrees${_C_NC}
  ${_C_DIM}\$${_C_NC} wt clean                 ${_C_DIM}# Prune stale${_C_NC}
  ${_C_DIM}\$${_C_NC} wt move                  ${_C_DIM}# Move current branch${_C_NC}

${_C_BLUE}📋 COMMANDS${_C_NC}:
  ${_C_CYAN}wt${_C_NC}               Navigate to ~/.git-worktrees
  ${_C_CYAN}wt list${_C_NC}          List all worktrees
  ${_C_CYAN}wt create <b>${_C_NC}    Create worktree for branch
  ${_C_CYAN}wt move${_C_NC}          Move current branch to worktree
  ${_C_CYAN}wt remove <path>${_C_NC} Remove a worktree
  ${_C_CYAN}wt clean${_C_NC}         Prune stale worktrees

${_C_BLUE}⚙️ CONFIGURATION${_C_NC}:
  ${_C_DIM}FLOW_WORKTREE_DIR${_C_NC}  Worktree base directory
                     ${_C_DIM}Default: ~/.git-worktrees${_C_NC}

${_C_MAGENTA}💡 TIP${_C_NC}: Unknown commands pass through to git worktree
  ${_C_DIM}wt lock <path>  → git worktree lock <path>${_C_NC}
"
}
