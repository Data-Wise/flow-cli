# Mediationverse Workflow Refactoring Proposal

**Date:** 2025-12-14
**Status:** Pending Review

---

## Current State Analysis

**Existing Commands (14 total):**

| Command | Purpose | ADHD-Friendly? |
|---------|---------|----------------|
| `mvr` | Terminal report | ✅ Good visual |
| `mvs` | Sync to Notes | ✅ |
| `mvst` | Git status | ✅ Enhanced |
| `mvcd` | cd to package | ⚠️ No feedback |
| `mvci` | Commit | ⚠️ No confirmation |
| `mvpush` | Push | ⚠️ No status after |
| `mvpull` | Pull | ⚠️ Minimal feedback |
| `mvmerge` | Merge dev→main | ⚠️ No guardrails |
| `mvrebase` | Rebase dev | ⚠️ Dangerous, no confirmation |
| `mvdev` | Checkout dev | ⚠️ Silent |
| `sp` | Set progress | ✅ |

**Problems Identified:**

1. **No guided workflows** - User must remember sequence of commands
2. **Missing commands** - No stash, log, diff, undo
3. **No guardrails** - Destructive ops have no confirmation
4. **Inconsistent feedback** - Some verbose, some silent
5. **No help/discovery** - Hard to remember all commands
6. **No "smart" mode** - Can't auto-detect what needs doing

---

## Option A: Enhanced Granular Commands

**Philosophy:** Keep individual commands but make each ADHD-friendly with visual feedback, confirmations, and context.

```
┌─────────────────────────────────────────────────────────────┐
│  MEDIATIONVERSE COMMANDS (Option A)                         │
├─────────────────────────────────────────────────────────────┤
│  DASHBOARD                                                  │
│    mvr          Terminal report                             │
│    mvs          Sync to Apple Notes                         │
│    mvst [PKG]   Status (enhanced)                          │
│    mvhelp       Show all commands                          │
│                                                             │
│  NAVIGATION                                                 │
│    mvcd PKG     cd to package (shows status after)         │
│    mvls         List all packages with status              │
│                                                             │
│  CHANGES                                                    │
│    mvci PKG     Commit (interactive, shows diff first)     │
│    mvstash PKG  Stash changes                              │
│    mvdiff PKG   Show diff                                  │
│    mvlog PKG    Show recent commits                        │
│                                                             │
│  SYNC                                                       │
│    mvpush PKG   Push (shows status after)                  │
│    mvpull [PKG] Pull (all or one)                          │
│                                                             │
│  BRANCHES                                                   │
│    mvdev PKG    Checkout dev (shows status)                │
│    mvmain PKG   Checkout main                              │
│    mvmerge PKG  Merge dev→main (with confirmation)         │
│    mvrebase PKG Rebase dev (with confirmation)             │
└─────────────────────────────────────────────────────────────┘
```

**Pros:**
- Familiar pattern, easy to learn incrementally
- Each command does one thing well
- Flexible for power users

**Cons:**
- Still requires remembering sequence
- 18+ commands to remember
- No guided workflows

---

## Option B: Smart Workflow Commands

**Philosophy:** High-level commands that figure out what to do and guide you through.

```
┌─────────────────────────────────────────────────────────────┐
│  MEDIATIONVERSE COMMANDS (Option B)                         │
├─────────────────────────────────────────────────────────────┤
│  SMART WORKFLOWS                                            │
│    mvwork PKG   Start working: cd, checkout dev, status    │
│    mvdone PKG   Finish: commit, optionally merge & push    │
│    mvfix        Auto-fix all warnings (guided)             │
│    mvsync       Pull all, push all pending                 │
│                                                             │
│  DASHBOARD                                                  │
│    mv           Main dashboard (status + suggestions)       │
│    mvr          Detailed report                            │
│    mvs          Sync to Apple Notes                        │
│                                                             │
│  GRANULAR (when needed)                                     │
│    mvci, mvpush, mvpull, mvmerge, mvrebase, mvdev          │
└─────────────────────────────────────────────────────────────┘
```

**Example `mv` (main dashboard):**

```
╔════════════════════════════════════════════════════════════╗
║  📊 MEDIATIONVERSE                                         ║
╚════════════════════════════════════════════════════════════╝

  medfit          ⚠️ [dev] 1 untracked, dev +2 ahead
  mediationverse  ✅ [main]
  medrobust       ✅ [main]
  medsim          🔄 [main] dev 9 behind
  probmed         🔄 [main] dev 7 behind

────────────────────────────────────────
  💡 SUGGESTED ACTIONS:
     1. mvwork medfit     → Continue work on medfit
     2. mvfix medsim      → Update stale dev branch
     3. mvfix probmed     → Update stale dev branch

  Type 'mvhelp' for all commands
```

**Example `mvwork medfit`:**

```
╔════════════════════════════════════════════════════════════╗
║  🚀 STARTING WORK: medfit                                  ║
╚════════════════════════════════════════════════════════════╝

  📂 Changed to: ~/projects/r-packages/active/medfit
  🌿 On branch: dev

  📊 Current Status:
     ❓ 1 untracked file
        ?? PROJECT-HUB.md
     🔶 dev is 2 commits ahead of main

────────────────────────────────────────
  💡 NEXT STEPS:
     • Edit files as needed
     • When done: mvdone medfit "your message"
     • Quick commit: mvci medfit "message"
```

**Example `mvdone medfit "Add feature X"`:**

```
╔════════════════════════════════════════════════════════════╗
║  ✅ FINISHING WORK: medfit                                 ║
╚════════════════════════════════════════════════════════════╝

  📦 Committing changes...
     ✅ Committed: "Add feature X"

  🔶 dev is now 3 commits ahead of main

  ❓ What would you like to do?
     [1] Keep on dev (default)
     [2] Merge to main
     [3] Merge to main and push

  Choice [1]:
```

**Pros:**
- Reduces cognitive load dramatically
- Guided workflows prevent mistakes
- Smart suggestions based on state
- Interactive when decisions needed

**Cons:**
- Less control for power users
- More complex implementation
- May feel "hand-holdy" for simple tasks

---

## Option C: Unified `mv` Command with Subcommands

**Philosophy:** Single entry point with discoverable subcommands (like `git`).

```
┌─────────────────────────────────────────────────────────────┐
│  mv COMMAND [PKG] [ARGS]                                    │
├─────────────────────────────────────────────────────────────┤
│  mv              Dashboard with suggestions                 │
│  mv status       Status of all packages                    │
│  mv work PKG     Start working on package                  │
│  mv done PKG     Finish and commit                         │
│  mv commit PKG   Just commit                               │
│  mv push PKG     Push changes                              │
│  mv pull         Pull all                                  │
│  mv merge PKG    Merge dev to main                         │
│  mv fix [PKG]    Fix branch issues                         │
│  mv sync         Sync to Apple Notes                       │
│  mv help         Show all commands                         │
└─────────────────────────────────────────────────────────────┘
```

**Pros:**
- Single command to remember
- Tab-completion friendly
- Discoverable via `mv help`
- Consistent with git/docker patterns

**Cons:**
- Longer to type (`mv commit` vs `mvci`)
- Conflicts if `mv` is used elsewhere (note: `mv` is the Unix move command!)
- Less "quick" for frequent operations

---

## Option D: Hybrid (Recommended) ⭐

**Philosophy:** Best of all worlds - smart workflows + granular commands + unified help.

```
┌─────────────────────────────────────────────────────────────┐
│  MEDIATIONVERSE COMMANDS                                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  🎯 QUICK START (most used)                                │
│    mv            Dashboard + suggestions                   │
│    mvwork PKG    Start working (cd + dev + status)        │
│    mvdone PKG    Finish work (commit + optional merge)    │
│                                                             │
│  📊 DASHBOARD                                               │
│    mvst [PKG]    Detailed status                          │
│    mvr           Full terminal report                      │
│    mvs           Sync to Apple Notes                       │
│                                                             │
│  ⚡ QUICK ACTIONS                                           │
│    mvci PKG MSG  Quick commit                              │
│    mvpush PKG    Push                                      │
│    mvpull        Pull all                                  │
│                                                             │
│  🔧 BRANCH MANAGEMENT                                       │
│    mvfix [PKG]   Auto-fix branch issues (guided)          │
│    mvmerge PKG   Merge dev→main (with confirmation)       │
│    mvrebase PKG  Update dev from main (with confirmation) │
│    mvdev PKG     Switch to dev                            │
│                                                             │
│  🔍 INSPECTION                                              │
│    mvlog PKG     Recent commits                           │
│    mvdiff PKG    Show changes                             │
│    mvcd PKG      Navigate to package                      │
│                                                             │
│  ❓ HELP                                                    │
│    mvhelp        Show this reference                      │
│    mvhelp CMD    Detailed help for command                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Key Enhancements

#### 1. `mv` - Smart Dashboard
Shows status + actionable suggestions. Answers "What should I do next?"

#### 2. `mvwork PKG` - Start Session
- cd to package
- Checkout dev (create if needed)
- Show status
- Log to worklog

#### 3. `mvdone PKG [MSG]` - End Session
- Show diff preview
- Commit with message
- Ask: keep on dev / merge / merge+push
- Log to worklog

#### 4. `mvfix [PKG]` - Auto-Fix
- Detects issues (stale dev, uncommitted, etc.)
- Guides through fixes interactively
- Can fix all packages at once

#### 5. `mvhelp` - Contextual Help
- Shows command reference
- `mvhelp mvmerge` shows detailed usage

#### 6. Confirmation Prompts
- `mvmerge` asks "Merge dev→main? [y/N]"
- `mvrebase` warns about rewriting history

---

## Additional Workflow Suggestions

### 1. Morning Routine Integration

```bash
mvmorning() {
    echo "☀️ Good morning! Let's check mediationverse..."
    mvpull           # Pull all updates
    mv               # Show dashboard with suggestions
}
```

### 2. Quick Package Picker (fzf integration)

```bash
mvp() {
    # Interactive package picker
    local pkg=$(echo "${MV_PACKAGES[@]}" | tr ' ' '\n' | fzf --prompt="Package: ")
    [[ -n "$pkg" ]] && mvwork "$pkg"
}
```

### 3. Release Workflow

```bash
mvrelease PKG() {
    # Guided CRAN release checklist
    # - R CMD check
    # - Update version
    # - Update NEWS
    # - Merge to main
    # - Tag release
}
```

### 4. Weekly Review

```bash
mvweekly() {
    # Show commits this week across all packages
    # Show progress changes
    # Suggest next priorities
}
```

---

## Comparison Matrix

| Feature | Option A | Option B | Option C | Option D |
|---------|----------|----------|----------|----------|
| Easy to learn | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Quick for experts | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| ADHD-friendly | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Guided workflows | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Flexibility | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Implementation effort | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |

---

## Recommendation: Option D (Hybrid)

**Why:**

1. **Progressive disclosure** - Simple commands for beginners, power commands available
2. **Smart suggestions** - Reduces "what do I do next?" paralysis
3. **Guided workflows** - `mvwork`/`mvdone` handle 80% of daily use
4. **Guardrails** - Confirmations prevent mistakes
5. **Still flexible** - Granular commands when needed
6. **Discoverable** - `mvhelp` teaches the system

**Implementation Priority:**

1. `mv` - Smart dashboard (high value, moderate effort)
2. `mvwork`/`mvdone` - Core workflow (high value)
3. `mvfix` - Auto-repair (high value for maintenance)
4. `mvhelp` - Discoverability
5. Enhance existing commands with confirmations/feedback

---

## Decision

**Selected Option:** _______________

**Notes:**

