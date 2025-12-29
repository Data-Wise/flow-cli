# Proposal: Git Feature Branch Workflow

**Date:** 2025-12-29
**Status:** ✅ IMPLEMENTED (v4.1.0)
**Version:** 2.1
**Related:** aiterm FEATURE-BRANCH-WORKFLOW.md

---

## Summary

Add shell commands for the `feature → dev → main` git workflow pattern, including:
- Feature branch commands in `g` dispatcher
- Workflow guards to prevent accidental pushes to protected branches
- New `wt` dispatcher for worktree management

**This is flow-cli's portion of a split workflow:**
- **flow-cli** → Shell-native operations (fast, zero overhead)
- **aiterm** → Rich visualization and automation
- **craft** → AI-assisted workflows

---

## Motivation

1. **Branch discipline** - Prevent accidental merges to main/dev
2. **Parallel development** - Work on multiple features without branch switching
3. **ADHD-friendly** - Instant commands, no context loss
4. **Zero overhead** - Pure shell, sub-10ms response

---

## Recommended Implementation: Option A + C Hybrid

1. **Extend `g` dispatcher** with feature workflow commands
2. **Add workflow guards** to prevent direct push to main/dev
3. **Add `wt` dispatcher** for worktree management
4. **Add standalone aliases** for ultra-quick access

---

## Implementation Details

### 1. G Dispatcher Extensions

**File:** `lib/dispatchers/g-dispatcher.zsh`

Add to the main `g()` case statement:

```zsh
        # ─────────────────────────────────────────────────────────────
        # FEATURE WORKFLOW
        # ─────────────────────────────────────────────────────────────
        feature|feat)
            shift
            _g_feature "$@"
            ;;

        promote|pr)
            _g_promote
            ;;

        release|rel)
            _g_release
            ;;
```

Modify the existing push case to add workflow guard:

```zsh
        push|p)
            shift
            # Check workflow guard (unless GIT_WORKFLOW_SKIP=1)
            if [[ -z "$GIT_WORKFLOW_SKIP" ]]; then
                _g_check_workflow || return 1
            fi
            git push "$@"
            ;;
```

#### Feature Command Implementation

```zsh
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
                _flow_log_error "Feature name required"
                echo "Usage: g feature start <name>"
                return 1
            fi
            # Ensure clean state
            if ! git diff --quiet HEAD 2>/dev/null; then
                _flow_log_warning "You have uncommitted changes. Stash or commit first."
                return 1
            fi
            git checkout dev && git pull origin dev
            git checkout -b "feature/$name"
            _flow_log_success "Created feature/$name from dev"
            ;;

        sync)
            local branch=$(git branch --show-current)
            if [[ "$branch" != feature/* ]]; then
                _flow_log_error "Not on a feature branch (current: $branch)"
                return 1
            fi
            git fetch origin
            git rebase origin/dev
            _flow_log_success "Rebased $branch onto dev"
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
                _flow_log_error "Not on a feature/bugfix branch"
                return 1
            fi
            _flow_log_info "Creating PR: $branch → dev"
            git push -u origin HEAD
            gh pr create --base dev --fill
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

${_C_YELLOW}WORKFLOW${_C_NC}:
  ${_C_DIM}feature/*${_C_NC} ──► ${_C_CYAN}dev${_C_NC} ──► ${_C_GREEN}main${_C_NC}
  ${_C_DIM}hotfix/*${_C_NC}  ────┴───────┘
  ${_C_DIM}bugfix/*${_C_NC}  ────┘

${_C_YELLOW}EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} g feature start auth     ${_C_DIM}# → feature/auth from dev${_C_NC}
  ${_C_DIM}\$${_C_NC} g feature sync           ${_C_DIM}# Rebase onto dev${_C_NC}
  ${_C_DIM}\$${_C_NC} g feature finish         ${_C_DIM}# Push + PR to dev${_C_NC}
"
}
```

#### Promote and Release Commands

```zsh
_g_promote() {
    local branch=$(git branch --show-current)

    # Validate branch type
    if [[ "$branch" != feature/* && "$branch" != bugfix/* && "$branch" != hotfix/* ]]; then
        _flow_log_error "Not on a promotable branch (feature/*, bugfix/*, hotfix/*)"
        _flow_log_info "Current branch: $branch"
        return 1
    fi

    # Check for uncommitted changes
    if ! git diff --quiet HEAD 2>/dev/null; then
        _flow_log_warning "Uncommitted changes. Commit or stash first."
        return 1
    fi

    git push -u origin HEAD
    gh pr create --base dev --fill
    _flow_log_success "Created PR: $branch → dev"
}

_g_release() {
    local branch=$(git branch --show-current)

    if [[ "$branch" != "dev" ]]; then
        _flow_log_error "Must be on 'dev' branch to create release PR"
        _flow_log_info "Run: git checkout dev"
        return 1
    fi

    # Ensure dev is up to date
    git fetch origin
    local behind=$(git rev-list --count HEAD..origin/dev 2>/dev/null || echo "0")
    if (( behind > 0 )); then
        _flow_log_warning "dev is $behind commits behind origin. Pull first."
        return 1
    fi

    gh pr create --base main --fill
    _flow_log_success "Created PR: dev → main"
}
```

#### Workflow Guard

```zsh
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
```

#### Update _g_help()

Add this section to the existing `_g_help()` function:

```zsh
${_C_BLUE}🌳 FEATURE WORKFLOW${_C_NC}:
  ${_C_CYAN}g feature start <n>${_C_NC}  Create feature branch from dev
  ${_C_CYAN}g feature sync${_C_NC}       Rebase feature onto dev
  ${_C_CYAN}g feature list${_C_NC}       List feature/hotfix branches
  ${_C_CYAN}g feature finish${_C_NC}     Push + create PR to dev
  ${_C_CYAN}g promote${_C_NC}            PR: feature → dev
  ${_C_CYAN}g release${_C_NC}            PR: dev → main
```

---

### 2. WT Dispatcher (New File)

**File:** `lib/dispatchers/wt-dispatcher.zsh`

```zsh
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
            _flow_log_info "Changed to: $FLOW_WORKTREE_DIR"
            ls -la
        else
            mkdir -p "$FLOW_WORKTREE_DIR"
            cd "$FLOW_WORKTREE_DIR"
            _flow_log_success "Created and changed to: $FLOW_WORKTREE_DIR"
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
            _flow_log_success "Pruned stale worktrees"
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
# WORKTREE OPERATIONS
# ═══════════════════════════════════════════════════════════════════

_wt_create() {
    local branch="$1"

    if [[ -z "$branch" ]]; then
        _flow_log_error "Branch name required"
        echo "Usage: wt create <branch>"
        echo "Examples:"
        echo "  wt create feature/auth"
        echo "  wt create hotfix/urgent-fix"
        return 1
    fi

    # Get project name from git root
    local git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -z "$git_root" ]]; then
        _flow_log_error "Not in a git repository"
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
        _flow_log_success "Created worktree: $target_dir"
        echo ""
        echo -e "${_C_DIM}Navigate: cd $target_dir${_C_NC}"
    fi
}

_wt_move() {
    local branch=$(git branch --show-current 2>/dev/null)

    if [[ -z "$branch" ]]; then
        _flow_log_error "Not on a branch (detached HEAD?)"
        return 1
    fi

    if [[ "$branch" == "main" || "$branch" == "master" || "$branch" == "dev" ]]; then
        _flow_log_error "Cannot move protected branch '$branch' to worktree"
        return 1
    fi

    # Create worktree for current branch
    _wt_create "$branch"
}

_wt_remove() {
    local path="$1"

    if [[ -z "$path" ]]; then
        _flow_log_error "Worktree path required"
        echo "Usage: wt remove <path>"
        echo ""
        echo "Current worktrees:"
        git worktree list
        return 1
    fi

    git worktree remove "$path"
    if [[ $? -eq 0 ]]; then
        _flow_log_success "Removed worktree: $path"
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
```

---

### 3. Standalone Aliases (Optional)

Add to user's `.zshrc` or a separate file (not in flow-cli core):

```zsh
# Feature branch shortcuts (optional speed aliases)
alias gfs='g feature start'
alias gfl='g feature list'
alias gfsync='g feature sync'
alias gfp='g promote'
alias gfr='g release'

# Worktree shortcuts
alias wtl='wt list'
alias wtc='wt create'
```

---

## Testing Plan

### Test File: `tests/test-g-feature.zsh`

```zsh
#!/usr/bin/env zsh
# Tests for g feature workflow

source "${0:A:h}/../flow.plugin.zsh"

# Setup test repo
setup() {
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
    git init
    git commit --allow-empty -m "Initial commit"
    git checkout -b dev
    git checkout -b main
}

# Cleanup
teardown() {
    cd /
    rm -rf "$TEST_DIR"
}

test_feature_start_requires_name() {
    setup
    output=$(g feature start 2>&1)
    [[ "$output" == *"Feature name required"* ]] || echo "FAIL: Should require name"
    teardown
}

test_feature_start_creates_branch() {
    setup
    git checkout dev
    g feature start test-feature
    branch=$(git branch --show-current)
    [[ "$branch" == "feature/test-feature" ]] || echo "FAIL: Should create feature branch"
    teardown
}

test_promote_requires_feature_branch() {
    setup
    git checkout main
    output=$(g promote 2>&1)
    [[ "$output" == *"Not on a promotable branch"* ]] || echo "FAIL: Should reject main"
    teardown
}

test_release_requires_dev_branch() {
    setup
    git checkout main
    output=$(g release 2>&1)
    [[ "$output" == *"Must be on 'dev' branch"* ]] || echo "FAIL: Should reject main"
    teardown
}

test_workflow_guard_blocks_main() {
    setup
    git checkout main
    output=$(_g_check_workflow 2>&1)
    result=$?
    [[ $result -ne 0 ]] || echo "FAIL: Should block main"
    [[ "$output" == *"blocked"* ]] || echo "FAIL: Should show blocked message"
    teardown
}

test_workflow_guard_allows_feature() {
    setup
    git checkout -b feature/test
    _g_check_workflow
    [[ $? -eq 0 ]] || echo "FAIL: Should allow feature branch"
    teardown
}

# Run tests
echo "Running g feature tests..."
test_feature_start_requires_name
test_feature_start_creates_branch
test_promote_requires_feature_branch
test_release_requires_dev_branch
test_workflow_guard_blocks_main
test_workflow_guard_allows_feature
echo "Done."
```

### Test File: `tests/test-wt-dispatcher.zsh`

```zsh
#!/usr/bin/env zsh
# Tests for wt dispatcher

source "${0:A:h}/../flow.plugin.zsh"

test_wt_help() {
    output=$(wt help 2>&1)
    [[ "$output" == *"Git Worktree Management"* ]] || echo "FAIL: Help should show title"
}

test_wt_create_requires_branch() {
    output=$(wt create 2>&1)
    [[ "$output" == *"Branch name required"* ]] || echo "FAIL: Should require branch"
}

test_wt_list() {
    # Should not error
    wt list >/dev/null 2>&1
    [[ $? -eq 0 ]] || echo "FAIL: wt list should work"
}

# Run tests
echo "Running wt dispatcher tests..."
test_wt_help
test_wt_create_requires_branch
test_wt_list
echo "Done."
```

---

## Documentation Updates

### 1. Update `docs/reference/DISPATCHER-REFERENCE.md`

Add section for feature workflow and wt dispatcher.

### 2. Update `CLAUDE.md` Quick Reference

```markdown
### G Dispatcher - Feature Workflow

```bash
g feature start <name>   # Create feature branch from dev
g feature sync           # Rebase feature onto dev
g feature list           # List feature/hotfix branches
g promote                # PR: feature → dev
g release                # PR: dev → main
```

### WT Dispatcher - Worktrees

```bash
wt                       # Navigate to ~/.git-worktrees
wt list                  # List all worktrees
wt create <branch>       # Create worktree for branch
wt move                  # Move current branch to worktree
wt clean                 # Prune stale worktrees
```
```

### 3. Create `docs/commands/wt.md`

Full documentation for the wt dispatcher.

---

## Effort Estimate (Updated)

| Component | Effort | Lines |
|-----------|--------|-------|
| g dispatcher extensions | 1.5 hours | ~150 |
| Workflow guard | 30 min | ~40 |
| wt dispatcher (full file) | 1 hour | ~180 |
| Tests | 1 hour | ~80 |
| Documentation | 30 min | ~100 |
| **Total** | **~4.5 hours** | **~550** |

---

## Implementation Checklist

### v4.1.0 (COMPLETE ✅)

| Task | Priority | Status |
|------|----------|--------|
| Add `_g_feature()` to g-dispatcher.zsh | P0 | ✅ |
| Add `_g_promote()` with validation | P0 | ✅ |
| Add `_g_release()` with validation | P0 | ✅ |
| Add `_g_check_workflow()` guard | P0 | ✅ |
| Wire guard into `g push` case | P0 | ✅ |
| Update `_g_help()` with FEATURE WORKFLOW section | P0 | ✅ |
| Create `lib/dispatchers/wt-dispatcher.zsh` | P1 | ✅ |
| Source wt-dispatcher in flow.plugin.zsh | P1 | ✅ |
| Create `tests/test-g-feature.zsh` | P1 | ✅ |
| Create `tests/test-wt-dispatcher.zsh` | P1 | ✅ |
| Update DISPATCHER-REFERENCE.md | P2 | ✅ |
| Update CLAUDE.md Quick Reference | P2 | ✅ |
| Create docs/commands/wt.md | P2 | 🔲 |
| Add ZSH completions for new commands | P3 | 🔲 |

### v4.2.0 (PLANNED)

| Task | Priority | Status |
|------|----------|--------|
| Add `g feature prune` for branch cleanup | P0 | 🔲 |
| Add `g feature prune --all` for remote cleanup | P0 | 🔲 |
| Integrate prune with `wt clean` | P1 | 🔲 |
| Add `cc wt <branch>` to cc-dispatcher.zsh | P1 | 🔲 |
| Update project-detector for worktree paths | P2 | 🔲 |
| Create `tests/test-g-feature-prune.zsh` | P2 | 🔲 |
| Update DISPATCHER-REFERENCE.md | P2 | 🔲 |

*Note: Hotfix workflow removed - see "Why No Hotfix Workflow?" section*

---

## Decision

**Recommended:** Implement Option A + C Hybrid with workflow guards

**Benefits:**
- Low effort, high impact
- Fits existing patterns
- ADHD-friendly (instant feedback)
- Prevents accidental pushes to protected branches
- Complements aiterm's rich visualization

---

## Relationship to Other Tools

| Capability | flow-cli | aiterm |
|------------|----------|--------|
| Quick branch creation | ✅ `g feature start` | - |
| Quick PR creation | ✅ `g promote`, `g release` | - |
| Quick worktree ops | ✅ `wt create` | - |
| Workflow guards | ✅ `_g_check_workflow` | - |
| Pipeline visualization | - | ✅ `ait feature status` |
| Full feature setup | - | ✅ `ait feature start` |
| Interactive cleanup | - | ✅ `ait feature cleanup` |

**Principle:** flow-cli for speed, aiterm for power.

---

---

## Future Enhancements (v4.2.0 Roadmap)

Building on v4.1.0's foundation, these enhancements are planned:

### 1. Branch Cleanup 🧹

**Why it fits:** After PRs merge, stale branches accumulate. This automates cleanup.

```bash
g feature prune         # Delete local branches merged to dev
g feature prune --all   # Also delete remote tracking branches
```

**Integration with existing tools:**
- Coordinates with `wt clean` for worktree cleanup
- Respects protected branches (main, dev)
- Safe by default (only merged branches)
- Note: Rich interactive cleanup → aiterm (`ait feature cleanup`)

### 2. Worktree + Claude Integration 🤖

**Why it fits:** You use worktrees for parallel development and Claude for coding. Combining them enables seamless context switching.

```bash
cc wt <branch>          # Launch Claude in worktree (creates if needed)
cc wt auth              # → Opens Claude in ~/.git-worktrees/project/feature-auth
```

**Benefits:**
- **ADHD-friendly:** One command to switch context entirely
- **Session isolation:** Each worktree gets its own Claude session
- **Worktree-aware detection:** `_flow_detect_project_type` recognizes worktree paths

---

## How v4.2.0 Builds on v4.1.0

| v4.1.0 Foundation | v4.2.0 Enhancement |
|-------------------|---------------------|
| `wt create` | `cc wt` (Claude integration) |
| `wt clean` | `g feature prune` (branch cleanup) |

### Why No Hotfix Workflow?

Hotfix workflows (`g hotfix start/finish`) were considered but **removed** because:
- flow-cli is a personal dev tool, not production software
- No urgent production pressure requiring faster paths
- Normal feature workflow is already fast (~2 minutes end-to-end)
- Adds complexity without clear benefit for solo development

**Design principle:** v4.2.0 fills gaps in the workflow without changing the core patterns.

---

*Created: 2025-12-28*
*Enhanced: 2025-12-29*
*v4.2.0 Roadmap: 2025-12-29*
*Author: Claude Code*
