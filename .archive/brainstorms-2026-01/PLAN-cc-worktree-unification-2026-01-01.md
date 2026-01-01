# CC Dispatcher Worktree Unification Plan

**Generated:** 2026-01-01
**Context:** flow-cli CC dispatcher simplification
**Goal:** Unify worktree workflows, keep `cc` and `ccy`, skip Docker

---

## Executive Summary

**Decision:** Don't implement Docker sandboxes (`cc sand`)
**Keep:** Current `cc` and `ccy` aliases
**Focus:** Unify and simplify worktree workflows
**Result:** Simpler, faster, more consistent CC dispatcher

---

## Part 1: Current State Analysis

### Current CC Dispatcher Commands

```bash
# Launch modes
cc                      # HERE (acceptEdits)
cc pick                 # Pick → Claude
cc <project>            # Direct jump → Claude
cc yolo                 # HERE (YOLO mode)
cc yolo pick            # Pick → YOLO
cc plan                 # HERE (plan mode)
cc plan pick            # Pick → plan
cc opus                 # HERE (Opus model)
cc haiku                # HERE (Haiku model)

# Session
cc resume               # Resume picker
cc continue             # Continue recent

# Quick actions
cc ask <question>       # Quick question
cc file <file>          # Analyze file
cc diff                 # Review changes
cc rpkg                 # R package context

# Worktrees
cc wt <branch>          # Worktree → Claude
cc wt yolo <branch>     # Worktree → YOLO
cc wt plan <branch>     # Worktree → plan
cc wt opus <branch>     # Worktree → Opus
cc wt pick              # Pick worktree → Claude
cc wt status            # Show worktrees
```

### Current Aliases

```bash
# Deprecated (should remove)
ccy                     # cc yolo (cryptic)

# Active (keep)
ccw                     # cc wt
ccwy                    # cc wt yolo
ccwp                    # cc wt pick
```

### Problems with Current Design

1. **Inconsistent patterns**
   - `cc yolo pick` works (pick → YOLO)
   - `cc pick yolo` doesn't work (should it?)

2. **Worktree-specific commands**
   - `cc wt status` only for worktrees
   - No equivalent `cc status` for main branch

3. **Mode chaining confusion**
   - `cc wt yolo <branch>` = worktree + YOLO
   - `cc yolo wt <branch>` doesn't work (inconsistent)

4. **Alias proliferation**
   - `ccy`, `ccw`, `ccwy`, `ccwp` (too many)
   - Users don't know what they mean

---

## Part 2: All Worktree Workflows (Comprehensive)

### Create & Launch Workflows

```bash
# Create worktree + launch Claude
cc wt feature/auth              # Auto-creates if missing, launches Claude
cc wt yolo bugfix/picker        # Create → YOLO mode
cc wt plan refactor/commands    # Create → plan mode
cc wt opus experiment/new-ui    # Create → Opus model
```

**Behavior:**

1. Checks if worktree exists at `~/.git-worktrees/<repo>-<branch>/`
2. If missing → runs `wt create <branch>`
3. Launches Claude in worktree directory

### Pick Existing Worktree

```bash
# FZF picker for existing worktrees
cc wt pick                      # Pick → Claude (acceptEdits)
cc wt pick yolo                 # Pick → YOLO mode (NOT IMPLEMENTED)
```

**Current limitation:** Can't chain modes after `pick`

### Status & Management

```bash
# Show all worktrees with session info
cc wt status                    # List with 🟢/🟡 indicators
cc wt st                        # Short alias

# Git worktree list (via wt dispatcher)
wt list                         # Native git worktree list
wt status                       # Same as cc wt status
```

### Integration with Pick

```bash
# Pick project → create worktree
pick wt flow                    # Creates worktree for flow-cli

# Direct via CC
cc wt pick                      # Pick from existing worktrees only
```

---

## Part 3: Proposed Unified Design

### Design Principle: One Mental Model

**Philosophy:** Mode flags work consistently everywhere

```bash
# Pattern: cc [mode] [target]
#
# Modes: yolo, plan, opus, haiku
# Targets: (here), pick, wt, <project>
```

### Proposed Command Structure

```bash
# Launch HERE (current directory)
cc                              # acceptEdits (default)
cc yolo                         # YOLO mode
cc plan                         # Plan mode
cc opus                         # Opus model
cc haiku                        # Haiku model

# Pick project first
cc pick                         # Pick → acceptEdits
cc yolo pick                    # Pick → YOLO
cc plan pick                    # Pick → plan
cc opus pick                    # Pick → Opus

# Worktree (create/use)
cc wt <branch>                  # Worktree → acceptEdits
cc yolo wt <branch>             # Worktree → YOLO
cc plan wt <branch>             # Worktree → plan
cc opus wt <branch>             # Worktree → Opus

# Worktree picker
cc wt pick                      # Pick worktree → acceptEdits
cc yolo wt pick                 # Pick worktree → YOLO
cc plan wt pick                 # Pick worktree → plan

# Direct jump
cc <project>                    # Jump → acceptEdits
cc yolo <project>               # Jump → YOLO
cc plan <project>               # Jump → plan
```

**Key change:** Modes come FIRST (consistent order)

### Why This is Better

**Before (inconsistent):**

```bash
cc yolo pick                    # ✅ Works
cc pick yolo                    # ❌ Doesn't work
cc wt yolo <branch>             # ✅ Works (different order!)
cc yolo wt <branch>             # ❌ Doesn't work
```

**After (consistent):**

```bash
cc yolo pick                    # ✅ Mode → target
cc yolo wt <branch>             # ✅ Mode → target
cc plan pick                    # ✅ Mode → target
cc opus wt pick                 # ✅ Mode → target
```

---

## Part 4: Implementation Changes

### Changes to cc-dispatcher.zsh

#### 1. Reorder Case Statement (Mode First)

**Current order:**

```zsh
case "$1" in
    pick)       # Target first
    yolo)       # Mode second
    plan)       # Mode third
    wt)         # Target fourth
esac
```

**Proposed order:**

```zsh
case "$1" in
    # Modes (check first)
    yolo|y)
        shift
        _cc_dispatch_with_mode "yolo" "$@"
        ;;

    plan|p)
        shift
        _cc_dispatch_with_mode "plan" "$@"
        ;;

    opus|o)
        shift
        _cc_dispatch_with_mode "opus" "$@"
        ;;

    haiku|h)
        shift
        _cc_dispatch_with_mode "haiku" "$@"
        ;;

    # Targets (check second)
    pick)
        shift
        _cc_launch_with_pick "acceptEdits" "$@"
        ;;

    wt|worktree|w)
        shift
        _cc_worktree "acceptEdits" "$@"
        ;;

    # ... rest of commands
esac
```

#### 2. New Helper Function: \_cc_dispatch_with_mode

```zsh
_cc_dispatch_with_mode() {
    local mode="$1"
    shift

    local mode_args
    case "$mode" in
        yolo)
            mode_args="--dangerously-skip-permissions"
            ;;
        plan)
            mode_args="--permission-mode plan"
            ;;
        opus)
            mode_args="--model opus --permission-mode acceptEdits"
            ;;
        haiku)
            mode_args="--model haiku --permission-mode acceptEdits"
            ;;
    esac

    # Check target
    case "$1" in
        pick)
            shift
            _cc_launch_with_pick "$mode" "$@"
            ;;

        wt|worktree|w)
            shift
            _cc_worktree "$mode" "$@"
            ;;

        "")
            # No target = launch HERE
            claude $mode_args
            ;;

        *)
            # Assume it's a project name (direct jump)
            local project="$1"
            shift
            if pick --no-claude "$project"; then
                claude $mode_args "$@"
            fi
            ;;
    esac
}
```

#### 3. Update \_cc_worktree to Accept Mode

```zsh
_cc_worktree() {
    local mode="${1:-acceptEdits}"
    shift

    local mode_args=""
    case "$mode" in
        yolo)
            mode_args="--dangerously-skip-permissions"
            ;;
        plan)
            mode_args="--permission-mode plan"
            ;;
        opus)
            mode_args="--model opus --permission-mode acceptEdits"
            ;;
        haiku)
            mode_args="--model haiku --permission-mode acceptEdits"
            ;;
        acceptEdits)
            mode_args="--permission-mode acceptEdits"
            ;;
    esac

    # Check for subcommands
    case "$1" in
        pick)
            shift
            _cc_worktree_pick "$mode" "$@"
            return
            ;;

        status|st)
            shift
            _cc_worktree_status "$@"
            return
            ;;

        # ... rest of worktree subcommands
    esac

    # Default: create/use worktree
    local branch="$1"
    if [[ -z "$branch" ]]; then
        wt list
        echo ""
        echo "Usage: cc wt <branch> or cc wt pick"
        return
    fi

    # Get or create worktree
    local wt_path=$(_wt_get_path "$branch")
    if [[ -z "$wt_path" ]]; then
        wt create "$branch"
        wt_path=$(_wt_get_path "$branch")
    fi

    # Launch Claude
    cd "$wt_path" && eval "claude $mode_args"
}
```

#### 4. Update \_cc_worktree_pick to Accept Mode

```zsh
_cc_worktree_pick() {
    local mode="${1:-acceptEdits}"
    shift

    local mode_args=""
    case "$mode" in
        yolo)
            mode_args="--dangerously-skip-permissions"
            ;;
        plan)
            mode_args="--permission-mode plan"
            ;;
        opus)
            mode_args="--model opus --permission-mode acceptEdits"
            ;;
        haiku)
            mode_args="--model haiku --permission-mode acceptEdits"
            ;;
        acceptEdits)
            mode_args="--permission-mode acceptEdits"
            ;;
    esac

    # FZF picker for worktrees
    local selected
    selected=$(git worktree list --porcelain 2>/dev/null | \
        grep "^worktree " | \
        cut -d' ' -f2- | \
        fzf --prompt="Select worktree: " --height=40% --reverse)

    if [[ -n "$selected" ]]; then
        cd "$selected" && eval "claude $mode_args"
    fi
}
```

---

## Part 5: Simplified Alias Strategy

### Remove Deprecated Aliases

```zsh
# REMOVE these from ~/.zshrc (deprecated)
alias ccy='cc yolo'             # Cryptic, users should type 'cc yolo'
```

### Keep Essential Aliases

```zsh
# KEEP these (clear, useful)
alias ccw='cc wt'               # Common worktree workflow
alias ccwy='cc yolo wt'         # Common YOLO worktree workflow
alias ccwp='cc wt pick'         # Worktree picker
```

### Rationale

**Why remove `ccy`:**

- Too cryptic (what does "ccy" mean?)
- Users should learn `cc yolo` (self-documenting)
- `cc yolo` is only 7 characters (not much longer)

**Why keep `ccw*` aliases:**

- Worktree workflows are common (used often)
- Prefix `ccw` is clear (cc + worktree)
- Consistent naming (`ccw`, `ccwy`, `ccwp`)

---

## Part 6: Complete Command Reference (After Unification)

### Basic Launch

```bash
cc                      # HERE, acceptEdits
cc yolo                 # HERE, YOLO mode
cc plan                 # HERE, plan mode
cc opus                 # HERE, Opus model
cc haiku                # HERE, Haiku model
```

### With Project Picker

```bash
cc pick                 # Pick → acceptEdits
cc yolo pick            # Pick → YOLO
cc plan pick            # Pick → plan
cc opus pick            # Pick → Opus
cc haiku pick           # Pick → Haiku
```

### With Direct Jump

```bash
cc flow                 # flow-cli → acceptEdits
cc yolo flow            # flow-cli → YOLO
cc plan stat            # stat-440 → plan
cc opus med             # mediationverse → Opus
```

### With Worktrees

```bash
# Create/use worktree
cc wt <branch>          # Worktree → acceptEdits
cc yolo wt <branch>     # Worktree → YOLO
cc plan wt <branch>     # Worktree → plan
cc opus wt <branch>     # Worktree → Opus

# Pick existing worktree
cc wt pick              # Pick worktree → acceptEdits
cc yolo wt pick         # Pick worktree → YOLO
cc plan wt pick         # Pick worktree → plan
cc opus wt pick         # Pick worktree → Opus

# Worktree management
cc wt status            # Show all worktrees with session info
cc wt st                # Short alias
```

### Session Management

```bash
cc resume               # Resume session picker
cc continue             # Continue most recent
cc r                    # Short for resume
cc c                    # Short for continue
```

### Quick Actions

```bash
cc ask <question>       # Quick question (print mode)
cc file <file>          # Analyze file
cc diff                 # Review git diff
cc rpkg                 # R package context
cc print <prompt>       # Print mode
```

### Aliases (Recommended)

```bash
ccw <branch>            # Same as: cc wt <branch>
ccwy <branch>           # Same as: cc yolo wt <branch>
ccwp                    # Same as: cc wt pick
```

---

## Part 7: Migration Guide

### For Users

**Old habits (still work):**

```bash
cc yolo pick            # ✅ Still works
cc wt yolo <branch>     # ✅ Still works (but...)
ccy                     # ⚠️ Deprecated, use 'cc yolo'
```

**New consistent syntax:**

```bash
cc yolo pick            # ✅ Mode first (consistent)
cc yolo wt <branch>     # ✅ Mode first (NEW!)
cc yolo                 # ✅ Type full command (no alias)
```

**What changed:**

- ✅ `cc yolo wt <branch>` now works (mode first)
- ✅ `cc plan wt pick` now works (mode first)
- ✅ All mode combinations work consistently
- ⚠️ `ccy` alias deprecated (use `cc yolo`)

### For Documentation

**Update these files:**

1. `docs/reference/CC-DISPATCHER-REFERENCE.md`
   - Rewrite with unified pattern
   - Show "mode first" examples
   - Remove `ccy` from examples

2. `docs/guides/YOLO-MODE-WORKFLOW.md`
   - Update Method 2 examples
   - Show `cc yolo wt` pattern
   - Remove `ccy` mentions

3. `README.md`
   - Update quick start examples
   - Show consistent syntax

4. `CHANGELOG.md`
   - Document breaking changes
   - Migration guide for `ccy` users

---

## Part 8: Implementation Checklist

### Phase 1: Core Unification (2 hours)

- [ ] Refactor `cc-dispatcher.zsh`:
  - [ ] Reorder case statement (modes first)
  - [ ] Add `_cc_dispatch_with_mode()` helper
  - [ ] Update `_cc_worktree()` to accept mode parameter
  - [ ] Update `_cc_worktree_pick()` to accept mode parameter

- [ ] Test new syntax:
  - [ ] `cc yolo wt <branch>` works
  - [ ] `cc plan wt pick` works
  - [ ] `cc opus wt <branch>` works
  - [ ] All existing commands still work (backward compat)

- [ ] Update help text:
  - [ ] Update `_cc_help()` with new pattern
  - [ ] Add examples showing "mode first" syntax
  - [ ] Mark deprecated features

### Phase 2: Alias Cleanup (30 min)

- [ ] Update aliases in flow-cli:
  - [ ] Keep `ccw`, `ccwy`, `ccwp`
  - [ ] Remove `ccy` from documentation
  - [ ] Add deprecation warning to `ccy` (don't break it yet)

- [ ] Update ZSH config (user action):
  - [ ] Remove `alias ccy='cc yolo'` from `~/.zshrc`
  - [ ] Keep worktree aliases

### Phase 3: Documentation (1 hour)

- [ ] Update `docs/reference/CC-DISPATCHER-REFERENCE.md`:
  - [ ] Rewrite with unified "mode first" pattern
  - [ ] Add comparison table (before/after)
  - [ ] Add migration guide

- [ ] Update `docs/guides/YOLO-MODE-WORKFLOW.md`:
  - [ ] Use `cc yolo wt` in examples
  - [ ] Remove `ccy` references

- [ ] Update `README.md`:
  - [ ] Quick start with consistent syntax
  - [ ] Feature list updates

- [ ] Create `docs/guides/WORKTREE-WORKFLOW.md` (NEW):
  - [ ] Complete worktree workflow guide
  - [ ] When to use worktrees
  - [ ] All `cc wt` commands
  - [ ] Session indicators explained

### Phase 4: Testing (30 min)

- [ ] Manual testing:
  - [ ] Test all new mode combinations
  - [ ] Test backward compatibility
  - [ ] Test worktree creation/launch
  - [ ] Test worktree picker with modes

- [ ] Integration testing:
  - [ ] Test with `pick` command
  - [ ] Test with `wt` dispatcher
  - [ ] Test session indicators

### Phase 5: Deployment (1 hour)

- [ ] Create git commit
- [ ] Update `CHANGELOG.md` with breaking changes
- [ ] Create GitHub release notes
- [ ] Deploy docs to GitHub Pages
- [ ] Update Homebrew formula (if needed)

---

## Part 9: Breaking Changes

### For v4.8.0 Release

**Breaking changes:**

1. ⚠️ `ccy` alias deprecated (still works, but not documented)
2. ✅ `cc yolo wt <branch>` now works (was broken before)
3. ✅ `cc plan wt pick` now works (was broken before)

**Migration:**

```bash
# Old way (still works but deprecated)
ccy                     # Use: cc yolo
ccy pick                # Use: cc yolo pick

# New way (recommended)
cc yolo                 # More explicit
cc yolo pick            # Consistent pattern
cc yolo wt <branch>     # NEW! Now works!
```

**User impact:** Minimal

- Most users don't use `ccy` (they type `cc yolo`)
- New features added (more mode combinations)
- Existing commands keep working

---

## Part 10: Future Enhancements (Not in This Plan)

**Not implementing (deferred):**

1. ❌ Docker sandbox integration (`cc sand`)
2. ❌ Container workflows
3. ❌ `--sandbox` flag for `cc yolo`

**Reason:** Worktrees solve 95% of use cases, Docker adds complexity

**If users request Docker later:**

- Can add `cc yolo --sandbox` flag (opt-in)
- Can document manual Docker commands
- Can create separate guide for advanced users

**For now:** Keep it simple with worktrees only

---

## Part 11: Documentation Structure

### New Guide: WORKTREE-WORKFLOW.md

**Outline:**

```markdown
# Worktree Workflow Guide

## What Are Worktrees?

- Multiple working directories for same repo
- Each on different branch
- Instant creation (<1s)
- Git-native feature

## When to Use Worktrees

- Work on 2+ features simultaneously
- Test breaking changes safely
- Quick experiments (disposable)
- Review PRs locally

## CC Worktree Commands

### Create & Launch

cc wt <branch> # Create → Claude
cc yolo wt <branch> # Create → YOLO mode

### Pick Existing

cc wt pick # FZF picker
cc yolo wt pick # Picker → YOLO

### Status & Management

cc wt status # Show all with sessions
wt list # Native git list

## Workflows

### Parallel Feature Development

1. Create worktree for feature-A
2. Work on feature-A
3. Switch to main branch (or create worktree for feature-B)
4. Work on feature-B
5. Both features progress independently

### Safe Experimentation

1. Create worktree for experiment
2. Run `cc yolo wt experiment`
3. Make risky changes
4. If successful → merge
5. If failed → `wt remove experiment` (instant cleanup)

## Session Indicators

🟢 Recent session (< 24h)
🟡 Old session (> 24h)
(none) No Claude session

## Best Practices

- Use descriptive branch names
- Clean up old worktrees regularly
- Review changes before merging
- Use YOLO mode in worktrees (safer than main)
```

---

## Part 12: Success Metrics

**How we'll know this succeeded:**

1. **Consistency:** All mode combinations work
   - `cc yolo wt`, `cc plan wt`, `cc opus wt` all work
   - "Mode first" pattern is intuitive

2. **Simplicity:** Fewer aliases
   - Removed `ccy` (users type full command)
   - Kept essential worktree aliases only

3. **User feedback:** Positive reception
   - Users find new syntax clearer
   - Fewer support questions about "which command to use?"

4. **Adoption:** Worktree usage increases
   - More users discover `cc wt` workflows
   - Session indicators useful

5. **Documentation:** Clearer guides
   - WORKTREE-WORKFLOW.md comprehensive
   - CC-DISPATCHER-REFERENCE.md consistent

---

## Summary

### What We're Doing

**✅ Implement:**

1. Unified "mode first" pattern (`cc yolo wt <branch>`)
2. Worktree mode chaining (`cc plan wt pick`)
3. Simplified aliases (remove `ccy`, keep `ccw*`)
4. Complete worktree workflow documentation

**❌ Not Implementing:**

1. Docker sandbox integration
2. `cc sand` command
3. Container workflows

**⏸️ Deferred:**

1. `cc yolo --sandbox` flag (if users request)
2. DevContainer integration
3. Custom sandbox configs

### Why This Approach

**Principles:**

1. **KISS** - Keep worktrees simple (no Docker complexity)
2. **ADHD-friendly** - Instant startup (<1s), no 5s penalty
3. **Consistency** - One pattern works everywhere (mode first)
4. **Git-native** - Use built-in git features (no new tools)

**Result:** Faster, simpler, more consistent CC dispatcher

---

## Next Steps

**Immediate (Today):**

1. Review this plan
2. Approve unified design
3. Start Phase 1 (core unification)

**This Week:**

1. Implement Phase 1-2 (refactor + aliases)
2. Test thoroughly
3. Update core documentation

**Next Week:**

1. Complete Phase 3-5 (docs + testing + deployment)
2. Create v4.8.0 release
3. Deploy updated docs

---

**Estimated Time:**

- Phase 1: 2 hours (core implementation)
- Phase 2: 30 min (alias cleanup)
- Phase 3: 1 hour (documentation)
- Phase 4: 30 min (testing)
- Phase 5: 1 hour (deployment)
- **Total:** ~5 hours

**Status:** Ready for implementation
**Confidence:** High (builds on existing, proven worktree system)

---

**Last Updated:** 2026-01-01
