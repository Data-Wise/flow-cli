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
        # CLEAN (basic)
        # ─────────────────────────────────────────────────────────────
        clean)
            git worktree prune
            echo -e "${_C_GREEN}✓ Pruned stale worktrees${_C_NC}"
            ;;

        # ─────────────────────────────────────────────────────────────
        # PRUNE (comprehensive cleanup)
        # ─────────────────────────────────────────────────────────────
        prune)
            shift
            _wt_prune "$@"
            ;;

        # ─────────────────────────────────────────────────────────────
        # STATUS (health and disk usage)
        # ─────────────────────────────────────────────────────────────
        status|st)
            _wt_status
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

    # First, check git worktree list for existing worktree with this branch
    # This handles any naming convention (flat or hierarchical)
    local wt_path
    wt_path=$(git worktree list --porcelain 2>/dev/null | \
        awk -v branch="$branch" '
            /^worktree / { path = substr($0, 10) }
            /^branch refs\/heads\// {
                sub(/^branch refs\/heads\//, "")
                if ($0 == branch) { print path; exit }
            }
        ')

    if [[ -n "$wt_path" && -d "$wt_path" ]]; then
        echo "$wt_path"
        return 0
    fi

    # Fallback: check expected hierarchical path
    local project=$(basename "$git_root")
    local folder=$(echo "$branch" | tr '/' '-')
    local expected_path="$FLOW_WORKTREE_DIR/$project/$folder"

    if [[ -d "$expected_path" ]]; then
        echo "$expected_path"
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
# WORKTREE STATUS
# ═══════════════════════════════════════════════════════════════════

_wt_status() {
    echo -e "${_C_BOLD}🌳 Worktree Status${_C_NC}"
    echo -e "${_C_DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_C_NC}"

    # Determine base branch
    local base_branch="dev"
    if ! git show-ref --verify --quiet refs/heads/dev 2>/dev/null; then
        base_branch="main"
    fi

    local total_count=0
    local active_count=0
    local merged_count=0
    local stale_count=0

    printf "\n  ${_C_BOLD}%-35s %-12s %-8s %s${_C_NC}\n" "BRANCH" "STATUS" "SIZE" "PATH"
    echo -e "  ${_C_DIM}───────────────────────────────── ──────────── ──────── ─────────────────────${_C_NC}"

    # Parse worktree list
    local wt_path wt_branch wt_status wt_size
    while IFS= read -r line; do
        case "$line" in
            "worktree "*)
                wt_path="${line#worktree }"
                ;;
            "branch "*)
                wt_branch="${line#branch refs/heads/}"
                ;;
            "detached")
                wt_branch="(detached)"
                ;;
            "")
                if [[ -n "$wt_path" ]]; then
                    ((total_count++))

                    # Calculate size
                    wt_size=$(du -sh "$wt_path" 2>/dev/null | cut -f1)
                    [[ -z "$wt_size" ]] && wt_size="?"

                    # Determine status
                    if [[ ! -d "$wt_path/.git" && ! -f "$wt_path/.git" ]]; then
                        wt_status="${_C_RED}⚠️  stale${_C_NC}"
                        ((stale_count++))
                    elif [[ "$wt_branch" == "main" || "$wt_branch" == "master" || "$wt_branch" == "dev" || "$wt_branch" == "develop" ]]; then
                        wt_status="${_C_BLUE}🏠 main${_C_NC}"
                        ((active_count++))
                    elif [[ "$wt_branch" == feature/* || "$wt_branch" == bugfix/* || "$wt_branch" == hotfix/* ]]; then
                        # Check if merged
                        if git branch --merged "$base_branch" 2>/dev/null | grep -q "^\s*$wt_branch$"; then
                            wt_status="${_C_YELLOW}🧹 merged${_C_NC}"
                            ((merged_count++))
                        else
                            wt_status="${_C_GREEN}✅ active${_C_NC}"
                            ((active_count++))
                        fi
                    else
                        wt_status="${_C_GREEN}✅ active${_C_NC}"
                        ((active_count++))
                    fi

                    # Shorten path for display
                    local short_path="${wt_path/#$HOME/~}"
                    if [[ ${#short_path} -gt 40 ]]; then
                        short_path="...${short_path: -37}"
                    fi

                    # Use %b for fields with escape sequences
                    printf "  %-35s %-20b %-8s %b\n" \
                        "${wt_branch:-unknown}" \
                        "$wt_status" \
                        "$wt_size" \
                        "${_C_DIM}$short_path${_C_NC}"
                fi
                wt_path="" wt_branch=""
                ;;
        esac
    done < <(git worktree list --porcelain 2>/dev/null; echo "")

    # Summary
    echo -e "\n${_C_DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${_C_NC}"
    echo -e "${_C_BOLD}Summary:${_C_NC} $total_count worktree(s) | ${_C_GREEN}$active_count active${_C_NC} | ${_C_YELLOW}$merged_count merged${_C_NC} | ${_C_RED}$stale_count stale${_C_NC}"

    # Tips
    if [[ $merged_count -gt 0 || $stale_count -gt 0 ]]; then
        echo ""
        [[ $merged_count -gt 0 ]] && echo -e "${_C_MAGENTA}💡 Tip:${_C_NC} Run ${_C_CYAN}wt prune${_C_NC} to clean up merged worktrees"
        [[ $stale_count -gt 0 ]] && echo -e "${_C_MAGENTA}💡 Tip:${_C_NC} Run ${_C_CYAN}wt clean${_C_NC} to prune stale references"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# COMPREHENSIVE PRUNE
# ═══════════════════════════════════════════════════════════════════

_wt_prune() {
    local dry_run=false
    local force_flag=false
    local branches_flag=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run|-n) dry_run=true ;;
            --force|-f) force_flag=true ;;
            --branches|-b) branches_flag=true ;;
            --help|-h) _wt_prune_help; return 0 ;;
            *) echo -e "${_C_RED}✗ Unknown option: $1${_C_NC}"; return 1 ;;
        esac
        shift
    done

    echo -e "${_C_BOLD}Worktree Cleanup${_C_NC}"
    echo -e "${_C_DIM}────────────────────────────────────────${_C_NC}"

    # Step 1: Prune stale worktree references
    echo -e "\n${_C_BLUE}Step 1:${_C_NC} Pruning stale worktree references..."
    if [[ "$dry_run" == true ]]; then
        git worktree prune --dry-run 2>&1 | sed 's/^/  /'
        echo -e "  ${_C_YELLOW}(dry run)${_C_NC}"
    else
        git worktree prune
        echo -e "  ${_C_GREEN}✓ Pruned stale references${_C_NC}"
    fi

    # Step 2: Find worktrees for merged branches
    echo -e "\n${_C_BLUE}Step 2:${_C_NC} Checking for worktrees with merged branches..."

    # Get base branch
    local base_branch="dev"
    if ! git show-ref --verify --quiet refs/heads/dev 2>/dev/null; then
        base_branch="main"
    fi

    local protected="main master dev develop"
    local current_branch=$(git branch --show-current 2>/dev/null)
    local worktrees_to_remove=()
    local branches_to_delete=()

    # Parse worktree list
    local wt_path wt_branch
    while IFS= read -r line; do
        case "$line" in
            "worktree "*)
                wt_path="${line#worktree }"
                ;;
            "branch "*)
                wt_branch="${line#branch refs/heads/}"
                ;;
            "")
                if [[ -n "$wt_path" && -n "$wt_branch" ]]; then
                    # Skip protected branches
                    if [[ " $protected " == *" $wt_branch "* ]]; then
                        wt_path="" wt_branch=""
                        continue
                    fi
                    # Skip current branch
                    if [[ "$wt_branch" == "$current_branch" ]]; then
                        wt_path="" wt_branch=""
                        continue
                    fi
                    # Check if merged
                    if git branch --merged "$base_branch" 2>/dev/null | grep -q "^\s*$wt_branch$"; then
                        if [[ "$wt_branch" == feature/* || "$wt_branch" == bugfix/* || "$wt_branch" == hotfix/* ]]; then
                            worktrees_to_remove+=("$wt_path|$wt_branch")
                            branches_to_delete+=("$wt_branch")
                        fi
                    fi
                fi
                wt_path="" wt_branch=""
                ;;
        esac
    done < <(git worktree list --porcelain 2>/dev/null; echo "")

    if [[ ${#worktrees_to_remove[@]} -eq 0 ]]; then
        echo -e "  ${_C_GREEN}✓ No merged worktrees to clean${_C_NC}"
    else
        echo -e "\n  ${_C_BOLD}Worktrees with merged branches:${_C_NC}"
        for entry in "${worktrees_to_remove[@]}"; do
            local path="${entry%%|*}"
            local branch="${entry##*|}"
            local short_path="${path/#$HOME/~}"
            echo -e "    ${_C_DIM}•${_C_NC} $short_path ${_C_DIM}[$branch]${_C_NC}"
        done

        if [[ "$dry_run" == true ]]; then
            echo -e "\n  ${_C_YELLOW}(dry run - no changes made)${_C_NC}"
        else
            # Confirm unless --force
            if [[ "$force_flag" != true ]]; then
                echo ""
                echo -n "  Remove ${#worktrees_to_remove[@]} worktree(s)? [y/N] "
                read -r confirm
                if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                    echo -e "  ${_C_YELLOW}Cancelled${_C_NC}"
                    return 0
                fi
            fi

            # Remove worktrees
            local removed=0
            for entry in "${worktrees_to_remove[@]}"; do
                local path="${entry%%|*}"
                if git worktree remove "$path" 2>/dev/null; then
                    echo -e "  ${_C_GREEN}✓ Removed${_C_NC} $path"
                    ((removed++))
                else
                    echo -e "  ${_C_RED}✗ Failed${_C_NC} $path"
                fi
            done
            echo -e "\n  ${_C_GREEN}Removed $removed worktree(s)${_C_NC}"

            # Also delete branches if --branches flag
            if [[ "$branches_flag" == true && ${#branches_to_delete[@]} -gt 0 ]]; then
                echo -e "\n${_C_BLUE}Step 3:${_C_NC} Deleting merged branches..."
                local deleted=0
                for branch in "${branches_to_delete[@]}"; do
                    if git branch -d "$branch" 2>/dev/null; then
                        echo -e "  ${_C_GREEN}✓ Deleted${_C_NC} $branch"
                        ((deleted++))
                    else
                        echo -e "  ${_C_RED}✗ Failed${_C_NC} $branch"
                    fi
                done
                echo -e "\n  ${_C_GREEN}Deleted $deleted branch(es)${_C_NC}"
            fi
        fi
    fi

    echo ""
}

_wt_prune_help() {
    echo -e "
${_C_BOLD}wt prune${_C_NC} - Comprehensive worktree cleanup

${_C_YELLOW}USAGE${_C_NC}:
  ${_C_CYAN}wt prune${_C_NC}              Clean worktrees for merged branches
  ${_C_CYAN}wt prune --branches${_C_NC}   Also delete the merged branches
  ${_C_CYAN}wt prune --force${_C_NC}      Skip confirmation prompts
  ${_C_CYAN}wt prune --dry-run${_C_NC}    Show what would be cleaned

${_C_YELLOW}OPTIONS${_C_NC}:
  ${_C_CYAN}--branches, -b${_C_NC}  Also delete merged branches
  ${_C_CYAN}--force, -f${_C_NC}     Skip confirmation prompts
  ${_C_CYAN}--dry-run, -n${_C_NC}   Preview without changes
  ${_C_CYAN}--help, -h${_C_NC}      Show this help

${_C_YELLOW}WHAT IT DOES${_C_NC}:
  1. Prunes stale worktree references
  2. Finds worktrees for merged feature branches
  3. Removes those worktrees (with confirmation)
  4. Optionally deletes the merged branches

${_C_YELLOW}SAFE BY DEFAULT${_C_NC}:
  • Asks for confirmation before removing
  • Only targets merged feature/bugfix/hotfix branches
  • Never removes main, master, dev, develop
  • Never removes current branch

${_C_YELLOW}EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} wt prune             ${_C_DIM}# Clean merged worktrees${_C_NC}
  ${_C_DIM}\$${_C_NC} wt prune -n          ${_C_DIM}# Preview what would be cleaned${_C_NC}
  ${_C_DIM}\$${_C_NC} wt prune -b          ${_C_DIM}# Also delete branches${_C_NC}
  ${_C_DIM}\$${_C_NC} wt prune -bf         ${_C_DIM}# Delete all, no confirmation${_C_NC}

${_C_YELLOW}SEE ALSO${_C_NC}:
  ${_C_DIM}g feature prune${_C_NC}     Clean merged branches (without worktrees)
  ${_C_DIM}wt clean${_C_NC}            Simple git worktree prune
"
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
  ${_C_CYAN}wt status${_C_NC}        Show health, disk usage, merge status
  ${_C_CYAN}wt create <b>${_C_NC}    Create worktree for branch
  ${_C_CYAN}wt move${_C_NC}          Move current branch to worktree
  ${_C_CYAN}wt remove <path>${_C_NC} Remove a worktree
  ${_C_CYAN}wt clean${_C_NC}         Prune stale worktree references
  ${_C_CYAN}wt prune${_C_NC}         Clean worktrees for merged branches

${_C_BLUE}⚙️ CONFIGURATION${_C_NC}:
  ${_C_DIM}FLOW_WORKTREE_DIR${_C_NC}  Worktree base directory
                     ${_C_DIM}Default: ~/.git-worktrees${_C_NC}

${_C_MAGENTA}💡 TIP${_C_NC}: Unknown commands pass through to git worktree
  ${_C_DIM}wt lock <path>  → git worktree lock <path>${_C_NC}

${_C_CYAN}🔗 See also${_C_NC}: ${_C_DIM}ait feature status${_C_NC} for rich pipeline visualization
            ${_C_DIM}ait feature start -w${_C_NC} for full automation with deps
"
}
