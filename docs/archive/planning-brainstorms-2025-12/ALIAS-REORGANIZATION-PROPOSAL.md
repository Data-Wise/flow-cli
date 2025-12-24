c# Shell Alias Reorganization Proposal v2

**Date:** 2025-12-17
**Status:** 🔶 PENDING YOUR DECISION
**Choice:** Plan D (Hybrid) - Modified
**Pattern:** `command + keyword + options` (vibe-style dispatchers)

---

## TL;DR - Your Choice

You chose **Plan D (Hybrid)** with modifications:

- ✅ Keep dispatcher pattern (`command + keyword + options`)
- ✅ `qu` = Quarto (already implemented in smart-dispatchers.zsh)
- 🗑️ Remove quota tracking system (no longer needed)
- 🆕 Add `g` dispatcher for git

---

## Changes Summary

### What Gets REMOVED (Quota System)

**Files to delete from `~/.claude/bin/`:**

```
quota-fetcher.sh
quota-auto-fetcher.sh
quota-refresh.sh
quota-fetcher
claude-quota-toggle
quota-daemon-setup.sh
claude-quota
```

**Files to delete from `~/.claude/tests/`:**

```
test-quota-fetcher.sh
test-quota-integration.sh
test-quota.sh
```

**Files to delete from `~/.claude/logs/`:**

```
quota-refresh-out.log
quota-fetcher-out.log
quota-refresh.log
quota-refresh-err.log
quota-fetcher-err.log
quota-fetcher.log
```

**Update `~/.claude/CLAUDE.md`:**

- Remove "Quota Tracking" section
- Remove references to `qu X Y Z` for quota
- Remove `cq` alias reference

**Update statusline (optional):**

- Remove quota display from `~/.claude/statusline-p10k.sh`
- Or leave it (will just show nothing if no quota file)

---

### What Gets KEPT

**Dispatchers (command + keyword + options):**

```bash
# R Package Development
r                   # R console (no args)
r test              # Run tests
r doc               # Document
r check             # Check package
r build             # Build
r cycle             # Full cycle (doc → test → check)

# Quarto Publishing (qu = quarto)
qu                  # Show help (no args)
qu preview          # Live preview
qu render           # Render document
qu check            # Check installation
qu clean            # Remove build artifacts
qu new <name>       # Create new project

# Workflow Automation
v                   # vibe - workflow dispatcher
v test              # Run tests
v coord             # Coordination
v plan              # Planning
v dash              # Dashboard

# AI Tools
cc                  # Claude Code
gm                  # Gemini

# Git (NEW - to be added)
g                   # git status (no args)
g status            # git status
g add .             # git add
g commit "msg"      # git commit -m
g push              # git push
g pull              # git pull
g log               # git log pretty
g branch            # git branch
g checkout <branch> # git checkout
g stash             # git stash
g help              # Show all commands
```

**Workflow Functions (unchanged):**

```bash
work <project>      # Start work session
dash                # Master dashboard
pick                # FZF picker
pb                  # Project build
pv                  # Project view/preview
pt                  # Project test
here                # Quick context
finish              # End session
```

**Utility Aliases (unchanged):**

```bash
..                  # cd ..
...                 # cd ../..
ll                  # eza -lah
la                  # eza -A
reload              # source ~/.zshrc
```

---

### What Gets ADDED

**New `g` dispatcher for Git:**

```bash
# File: ~/.config/zsh/functions/g-dispatcher.zsh

g() {
    # No arguments → git status
    if [[ $# -eq 0 ]]; then
        git status -sb
        return
    fi

    case "$1" in
        # Status & Info
        status|s)    shift; git status -sb "$@" ;;
        diff|d)      shift; git diff "$@" ;;
        log|l)       git log --oneline --graph --decorate -20 ;;

        # Staging & Commits
        add|a)       shift; git add "$@" ;;
        commit|c)    shift; git commit -m "$@" ;;
        amend)       git commit --amend --no-edit ;;

        # Branches
        branch|b)    shift; git branch "$@" ;;
        checkout|co) shift; git checkout "$@" ;;
        switch|sw)   shift; git switch "$@" ;;

        # Remote
        push|p)      shift; git push "$@" ;;
        pull|pl)     shift; git pull "$@" ;;
        fetch|f)     shift; git fetch "$@" ;;

        # Stash
        stash|st)    shift; git stash "$@" ;;

        # Reset
        reset|rs)    shift; git reset "$@" ;;
        undo)        git reset --soft HEAD~1 ;;

        # Help
        help|h)      _g_help ;;

        # Pass through anything else
        *)           git "$@" ;;
    esac
}

_g_help() {
    echo "
╭─────────────────────────────────────────────╮
│ g - Git Commands                            │
╰─────────────────────────────────────────────╯

MOST COMMON:
  g                 Status (short)
  g add .           Stage all
  g commit \"msg\"   Commit with message
  g push            Push to remote
  g pull            Pull from remote

STATUS & INFO:
  g status          Full status
  g diff            Show changes
  g log             Pretty log (20 lines)

BRANCHES:
  g branch          List branches
  g checkout <b>    Switch branch
  g switch <b>      Switch branch (new syntax)

STAGING & COMMITS:
  g add <files>     Stage files
  g commit \"msg\"   Commit
  g amend           Amend last commit

REMOTE:
  g push            Push
  g pull            Pull
  g fetch           Fetch

STASH & RESET:
  g stash           Stash changes
  g stash pop       Pop stash
  g undo            Undo last commit (keep changes)
  g reset           Reset

PASSTHROUGH:
  g <anything>      Passes to git directly
"
}
```

---

## What Gets CLEANED UP

**Remove from `~/.config/zsh/.zshrc`:**

```bash
# These are redundant with dispatchers:
alias qp='quarto preview'    # → qu preview
alias qr='quarto render'     # → qu render
alias qc='quarto check'      # → qu check
alias qclean='...'           # → qu clean

# Note: Keep typo tolerance aliases (they're helpful!)
```

**Remove from `zsh-claude-workflow/shell/aliases.zsh`:**

```bash
# Git aliases (will use g dispatcher instead):
gst, gco, gp, gl, gd, ga, gc, etc.
```

---

## Final Command Structure

```
╭─────────────────────────────────────────────────────────────╮
│  DISPATCHERS (command + keyword + options)                  │
├─────────────────────────────────────────────────────────────┤
│  r test          R package tests                            │
│  r doc           Document package                           │
│  r check         Check package                              │
│  r cycle         Full dev cycle                             │
│                                                             │
│  g status        Git status                                 │
│  g add .         Git add                                    │
│  g commit "msg"  Git commit                                 │
│  g push          Git push                                   │
│  g pull          Git pull                                   │
│  g log           Git log                                    │
│                                                             │
│  qu preview      Quarto preview                             │
│  qu render       Quarto render                              │
│  qu clean        Clean build files                          │
│                                                             │
│  v test          Workflow tests                             │
│  v dash          Dashboard                                  │
│  v coord         Coordination                               │
│                                                             │
│  cc              Claude Code                                │
│  gm              Gemini                                     │
├─────────────────────────────────────────────────────────────┤
│  WORKFLOW FUNCTIONS                                         │
├─────────────────────────────────────────────────────────────┤
│  work <name>     Start session    │  dash    Dashboard      │
│  pb              Build            │  pv      Preview        │
│  pt              Test             │  pick    FZF picker     │
│  here            Context          │  finish  End session    │
├─────────────────────────────────────────────────────────────┤
│  <cmd> help      Show all options for any dispatcher        │
╰─────────────────────────────────────────────────────────────╯
```

---

## Implementation Steps

When you approve, I will:

### Step 1: Remove Quota System

```bash
# Delete quota files
rm ~/.claude/bin/quota-*.sh
rm ~/.claude/bin/quota-fetcher
rm ~/.claude/bin/claude-quota*
rm ~/.claude/tests/test-quota*.sh
rm ~/.claude/logs/quota-*.log
```

### Step 2: Update CLAUDE.md

- Remove "Quota Tracking" section
- Remove `qu` and `cq` references for quota

### Step 3: Create `g` Dispatcher

- New file: `~/.config/zsh/functions/g-dispatcher.zsh`
- Source it from `.zshrc`

### Step 4: Clean Up Aliases

- Remove `qp`, `qr`, `qc`, `qclean` from `.zshrc` (use `qu` instead)
- Remove git aliases from `zsh-claude-workflow/shell/aliases.zsh`

### Step 5: Update Documentation

- Update `WORKFLOW-QUICK-REFERENCE.md`
- Create updated cheatsheet

---

## Before/After Summary

| Item          | Before                                  | After                                 |
| ------------- | --------------------------------------- | ------------------------------------- |
| **Quarto**    | `qp`, `qr`, `qc` aliases                | `qu preview`, `qu render`, `qu check` |
| **Git**       | `gst`, `gco`, `gp` aliases (duplicated) | `g status`, `g checkout`, `g push`    |
| **Quota**     | `qu X Y Z`, `cq` + bin files            | 🗑️ REMOVED                            |
| **R Package** | `r test`, `r doc`                       | ✅ Keep as-is                         |
| **Workflow**  | `v test`, `work`, `dash`                | ✅ Keep as-is                         |
| **AI**        | `cc`, `gm`                              | ✅ Keep as-is                         |

---

## Ready to Proceed?

**Approve to start implementation:**

- Tell me "yes" or "proceed" to begin
- Or ask questions first

**What I'll do:**

1. Remove quota files
2. Update CLAUDE.md
3. Create g-dispatcher
4. Clean up aliases
5. Update docs

---

_Saved: ~/ALIAS-REORGANIZATION-PROPOSAL-V2.md_
