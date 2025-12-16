# Universal Project Workflow Proposal

**Date:** 2025-12-14
**Scope:** All projects across R packages, dev-tools, quarto, research, apps

---

## Current Project Landscape

```
~/projects/
├── apps/                           # Applications
│   └── examark
│
├── dev-tools/                      # Development tooling (12 projects)
│   ├── apple-notes-sync
│   ├── claude-mcp
│   ├── claude-statistical-research
│   ├── emacs-r-devkit
│   ├── iterm2-context-switcher
│   ├── obsidian-cli-ops
│   ├── zsh-claude-workflow
│   ├── zsh-configuration
│   └── ...
│
├── quarto/                         # Quarto projects
│   ├── extensions/
│   ├── manuscripts/
│   └── presentations/
│
├── r-packages/                     # R packages
│   ├── active/                     # 5 packages (mediationverse ecosystem)
│   │   ├── medfit
│   │   ├── mediationverse
│   │   ├── medrobust
│   │   ├── medsim
│   │   └── probmed
│   ├── stable/                     # 1 package
│   │   └── rmediation
│   └── recovery/                   # Archived/recovering
│
└── research/                       # Research projects
    └── mediation-planning
```

**Total: ~25+ projects across 5 categories**

---

## The Problem

Current tools are **mediationverse-specific**:
- `mvst`, `mvwork`, `mvdone` only work for 5 R packages
- No unified way to navigate ALL projects
- No status overview across categories
- Different workflows for different project types
- Context switching is expensive (ADHD!)

---

## Design Principles

1. **Universal + Specialized** - One system for all, with category-specific extensions
2. **Progressive Disclosure** - Simple commands reveal complexity as needed
3. **Context-Aware** - Detect project type, suggest relevant actions
4. **ADHD-Friendly** - Visual, guided, low cognitive load
5. **Fast Navigation** - Get to any project in 2-3 keystrokes
6. **Unified Status** - See everything at a glance

---

## Option A: Single Universal Command (`p`)

**Philosophy:** One command to rule them all.

```
┌─────────────────────────────────────────────────────────────┐
│  p [COMMAND] [PROJECT] [ARGS]                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  DASHBOARD                                                  │
│    p               Full dashboard (all projects)            │
│    p s             Status summary                           │
│    p ls            List all projects                        │
│    p ls -r         List R packages only                     │
│    p ls -d         List dev-tools only                      │
│                                                             │
│  NAVIGATION                                                 │
│    p cd NAME       Go to project (fuzzy match)              │
│    p .             Show current project info                │
│                                                             │
│  WORKFLOW                                                   │
│    p w NAME        Start work (cd + branch + status)        │
│    p d [MSG]       Done (commit, context-aware)             │
│    p c MSG         Quick commit                             │
│    p push          Push current project                     │
│    p pull          Pull current project                     │
│                                                             │
│  CATEGORY SHORTCUTS                                         │
│    p r             R packages dashboard                     │
│    p r check       R CMD check (current or specified)       │
│    p r test        devtools::test()                         │
│    p r doc         devtools::document()                     │
│    p r build       Build package                            │
│                                                             │
│    p q             Quarto dashboard                         │
│    p q render      Render current quarto project            │
│    p q preview     Preview in browser                       │
│                                                             │
│    p dt            Dev-tools dashboard                      │
│    p dt test       Run tests (npm/make/etc)                 │
│                                                             │
│  SEARCH                                                     │
│    p find TERM     Search across all projects               │
│    p recent        Recently modified projects               │
│                                                             │
│  SYNC                                                       │
│    p sync          Sync status to Apple Notes               │
│    p notes         Open Apple Notes projects folder         │
│                                                             │
│  HELP                                                       │
│    p h             Quick reference                          │
│    p h COMMAND     Detailed help                            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Dashboard Example (`p`)

```
╔════════════════════════════════════════════════════════════╗
║  📊 PROJECT DASHBOARD                                      ║
╚════════════════════════════════════════════════════════════╝

  📦 R PACKAGES (6)
  ────────────────────────────────────────
  medfit          ⚠️  [dev] 1 untracked    P0 70%
  mediationverse  ✅  [main]               P1 40%
  medrobust       ✅  [main]               P0 65%
  medsim          🔄  [main] dev behind    P2 50%
  probmed         🔄  [main] dev behind    P1 55%
  rmediation      ✅  [main]               stable

  🔧 DEV-TOOLS (4 with changes)
  ────────────────────────────────────────
  apple-notes-sync    ✅  [main]           P2 85%
  zsh-configuration   ⚠️  [dev] modified   P2 new
  obsidian-cli-ops    ✅  [main]           P2 70%
  + 8 more stable...

  📝 QUARTO (0 changes)
  ────────────────────────────────────────
  All clean

  🔬 RESEARCH (1)
  ────────────────────────────────────────
  mediation-planning  ✅  [main]           active

────────────────────────────────────────────────────────────
  💡 SUGGESTED:
     p w medfit        Continue work (has changes)
     p r check medfit  R CMD check before commit

  Type 'p h' for help
```

### Context-Aware Commands

```bash
# When inside an R package directory:
$ cd ~/projects/r-packages/active/medfit
$ p .                    # Shows R package info
$ p check                # Runs R CMD check (detected R package)
$ p test                 # Runs devtools::test()
$ p doc                  # Runs devtools::document()

# When inside a Quarto project:
$ cd ~/projects/quarto/manuscripts/paper1
$ p .                    # Shows Quarto project info
$ p render               # Runs quarto render
$ p preview              # Runs quarto preview

# When inside a dev-tool:
$ cd ~/projects/dev-tools/claude-mcp
$ p .                    # Shows project info
$ p test                 # Runs npm test (detected package.json)
```

**Pros:**
- Single command to learn
- Works everywhere
- Context-aware reduces typing
- Scales to any number of projects

**Cons:**
- Lots of subcommands to remember
- May feel too abstract
- `p` alone might be too minimal

---

## Option B: Category-Based Commands

**Philosophy:** Separate commands per project type, unified structure.

```
┌─────────────────────────────────────────────────────────────┐
│  CATEGORY COMMANDS                                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  rp [CMD] [PKG]     R Packages                              │
│    rp               Dashboard                               │
│    rp s             Status all                              │
│    rp w NAME        Start work                              │
│    rp check NAME    R CMD check                             │
│    rp test NAME     Run tests                               │
│                                                             │
│  dt [CMD] [NAME]    Dev Tools                               │
│    dt               Dashboard                               │
│    dt s             Status all                              │
│    dt w NAME        Start work                              │
│    dt test          Run tests                               │
│                                                             │
│  qp [CMD] [NAME]    Quarto Projects                         │
│    qp               Dashboard                               │
│    qp render        Render                                  │
│    qp preview       Preview                                 │
│                                                             │
│  rs [CMD] [NAME]    Research                                │
│    rs               Dashboard                               │
│    rs w NAME        Start work                              │
│                                                             │
│  UNIVERSAL                                                  │
│    proj             Master dashboard (all categories)       │
│    proj s           Status everything                       │
│    proj sync        Sync to Apple Notes                     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### R Package Commands (`rp`)

```
╔════════════════════════════════════════════════════════════╗
║  📦 R PACKAGES                                             ║
╚════════════════════════════════════════════════════════════╝

  ACTIVE
  ────────────────────────────────────────
  [1] medfit          ⚠️  [dev] 1 untracked    70%
  [2] mediationverse  ✅  [main]               40%
  [3] medrobust       ✅  [main]               65%
  [4] medsim          🔄  [main] dev behind    50%
  [5] probmed         🔄  [main] dev behind    55%

  STABLE
  ────────────────────────────────────────
  [6] rmediation      ✅  [main]               CRAN

────────────────────────────────────────────────────────────
  💡 Commands:
     rp w 1           Start work on medfit
     rp check 1       R CMD check medfit
     rp test 1        Test medfit
     rp all check     Check all packages
```

**Pros:**
- Clear mental model per category
- Shorter commands within category
- Natural grouping
- Easier to remember category-specific operations

**Cons:**
- Multiple commands to learn (rp, dt, qp, rs)
- Cross-category operations harder
- Duplication of similar functionality

---

## Option C: Hybrid Universal + Category

**Philosophy:** Universal command with category namespaces.

```
┌─────────────────────────────────────────────────────────────┐
│  proj [CATEGORY] [COMMAND] [NAME]                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  UNIVERSAL (no category)                                    │
│    proj             Master dashboard                        │
│    proj s           Status all                              │
│    proj cd NAME     Go to any project (fuzzy)               │
│    proj w NAME      Start work (any project)                │
│    proj sync        Sync to Apple Notes                     │
│                                                             │
│  R PACKAGES                                                 │
│    proj r           R packages dashboard                    │
│    proj r s         R packages status                       │
│    proj r w NAME    Start work on R package                 │
│    proj r check     R CMD check                             │
│    proj r test      devtools::test()                        │
│    proj r doc       devtools::document()                    │
│    proj r build     Build package                           │
│    proj r release   CRAN release workflow                   │
│                                                             │
│  DEV TOOLS                                                  │
│    proj dt          Dev-tools dashboard                     │
│    proj dt w NAME   Start work                              │
│    proj dt test     Run tests                               │
│                                                             │
│  QUARTO                                                     │
│    proj q           Quarto dashboard                        │
│    proj q render    Render                                  │
│    proj q preview   Preview                                 │
│                                                             │
│  RESEARCH                                                   │
│    proj rs          Research dashboard                      │
│                                                             │
│  ALIASES (shortcuts)                                        │
│    rp = proj r      R packages                              │
│    dt = proj dt     Dev tools                               │
│    qp = proj q      Quarto                                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Pros:**
- Best of both worlds
- Clear hierarchy
- Category aliases for speed
- Extensible

**Cons:**
- More verbose for category-specific ops
- Three-part commands can be long

---

## Option D: Smart Context + Quick Keys

**Philosophy:** Minimal typing, maximum context awareness.

```
┌─────────────────────────────────────────────────────────────┐
│  SMART COMMANDS                                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  INSTANT ACCESS (2-3 chars)                                 │
│    pp              Project picker (fzf)                     │
│    ps              Project status (all)                     │
│    pw NAME         Project work (start)                     │
│    pd              Project done (commit)                    │
│    pc MSG          Project commit                           │
│                                                             │
│  CONTEXT-AWARE (auto-detect project type)                   │
│    pt              Project test (npm/R/make)                │
│    pb              Project build                            │
│    pr              Project run/render                       │
│                                                             │
│  CATEGORY DASHBOARDS                                        │
│    rp              R packages (interactive)                 │
│    dt              Dev tools (interactive)                  │
│    qp              Quarto (interactive)                     │
│                                                             │
│  FZF PICKERS                                                │
│    pp              All projects                             │
│    pp r            R packages only                          │
│    pp d            Dev tools only                           │
│    pp q            Quarto only                              │
│    pp recent       Recently worked on                       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### The `pp` Picker (fzf integration)

```bash
$ pp
╔════════════════════════════════════════════════════════════╗
║  🔍 PROJECT PICKER                                         ║
╚════════════════════════════════════════════════════════════╝

  > medfit                        📦 R pkg   ⚠️ changes
    mediationverse                📦 R pkg   ✅
    medrobust                     📦 R pkg   ✅
    apple-notes-sync              🔧 dev     ✅
    zsh-configuration             🔧 dev     ⚠️ changes
    obsidian-cli-ops              🔧 dev     ✅
    mediation-planning            🔬 research ✅

  [Type to filter, Enter to select, Ctrl-C to cancel]

  Actions after select:
    Enter     → cd to project
    Ctrl-W    → Start work session
    Ctrl-S    → Show status
```

### Context Detection

```bash
# Automatic test command based on project type:
$ pt

# In R package → Rscript -e 'devtools::test()'
# In npm project → npm test
# In Python → pytest
# In Make project → make test
# In Quarto → quarto check
```

**Pros:**
- Minimum keystrokes
- Visual picker reduces memory load
- Context detection = less typing
- Very ADHD-friendly (no decisions)

**Cons:**
- Requires fzf
- Less explicit (magic can confuse)
- Harder to script

---

## Option E: Workspace Sessions

**Philosophy:** Think in terms of work sessions, not commands.

```
┌─────────────────────────────────────────────────────────────┐
│  SESSION-BASED WORKFLOW                                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  SESSION MANAGEMENT                                         │
│    work NAME       Start session (cd, branch, status, log)  │
│    done [MSG]      End session (commit, log, suggest next)  │
│    pause           Pause session (stash, log)               │
│    resume          Resume last session                      │
│    switch NAME     Switch to different project              │
│                                                             │
│  QUICK STATUS                                               │
│    now             What am I working on?                    │
│    next            What should I work on next?              │
│    today           Today's activity                         │
│                                                             │
│  PROJECT OPS (context-aware)                                │
│    test            Run tests                                │
│    build           Build project                            │
│    check           Check/lint                               │
│    run             Run/preview                              │
│                                                             │
│  DASHBOARDS                                                 │
│    dash            Master dashboard                         │
│    dash r          R packages                               │
│    dash dt         Dev tools                                │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Session Flow

```bash
$ work medfit
╔════════════════════════════════════════════════════════════╗
║  🚀 STARTING SESSION: medfit                               ║
╚════════════════════════════════════════════════════════════╝

  📂 ~/projects/r-packages/active/medfit
  🌿 Branch: dev
  📦 Type: R Package

  📊 Status:
     ❓ 1 untracked file
     🔶 dev +2 ahead of main

  ⏱️  Session started at 10:45 AM

────────────────────────────────────────
  💡 Available commands:
     test     Run devtools::test()
     check    Run R CMD check
     doc      Run devtools::document()
     done     Finish session

$ # ... do work ...

$ done "Add mixed model support"
╔════════════════════════════════════════════════════════════╗
║  ✅ SESSION COMPLETE: medfit                               ║
╚════════════════════════════════════════════════════════════╝

  📦 Committed: "Add mixed model support"
  ⏱️  Duration: 45 minutes
  📝 Logged to workflow

  ❓ What next?
     [1] Keep working on medfit
     [2] Merge to main & push
     [3] Switch to another project
     [4] Take a break

  Choice [1]:
```

### The `now` Command

```bash
$ now
╔════════════════════════════════════════════════════════════╗
║  📍 CURRENT STATUS                                         ║
╚════════════════════════════════════════════════════════════╝

  🔧 Active Session: medfit
     Started: 10:45 AM (45 min ago)
     Changes: 3 files modified

  📋 Recent Activity:
     11:20  medfit      Modified fit_model.R
     11:15  medfit      Added test_mixed.R
     10:50  medfit      Started session

  💡 Suggestions:
     • Run 'test' to verify changes
     • Run 'done "msg"' when ready
```

**Pros:**
- Matches mental model of "working on something"
- Automatic session tracking
- Natural pause/resume flow
- Great for ADHD (clear start/end)
- Integrated activity logging

**Cons:**
- More stateful (tracking active session)
- What if you forget to `done`?
- May feel restrictive

---

## Comparison Matrix

| Feature | Option A | Option B | Option C | Option D | Option E |
|---------|----------|----------|----------|----------|----------|
| Commands to learn | 1 (`p`) | 4 (`rp`,`dt`,`qp`,`rs`) | 1 (`proj`) | ~10 short | ~8 session |
| Keystrokes (avg) | Medium | Low | High | Very Low | Low |
| Discoverability | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| ADHD-friendly | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Context-aware | ⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Cross-category | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Scriptable | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| Implementation | Medium | Medium | High | Medium | High |

---

## My Recommendation: Option D + E Hybrid

Combine the **quick keys** of Option D with the **session mindset** of Option E:

```
┌─────────────────────────────────────────────────────────────┐
│  RECOMMENDED: Quick Keys + Session Workflow                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  SESSION COMMANDS (primary workflow)                        │
│    work NAME       Start session on any project             │
│    done [MSG]      End session                              │
│    now             Current status                           │
│    next            Suggestions                              │
│                                                             │
│  QUICK NAVIGATION                                           │
│    pp              Project picker (fzf)                     │
│    pp r            R packages only                          │
│    pp d            Dev tools only                           │
│                                                             │
│  CONTEXT-AWARE OPS (work in current project)                │
│    pt              Test                                     │
│    pb              Build                                    │
│    pc MSG          Commit                                   │
│    pp              Push                                     │
│                                                             │
│  DASHBOARDS                                                 │
│    dash            Master dashboard                         │
│    dash r          R packages (keeps mv* as aliases)        │
│    dash dt         Dev tools                                │
│                                                             │
│  KEEP EXISTING (backwards compatible)                       │
│    mvst, mvci...   Still work for mediationverse            │
│    ds, ws, sp...   Still work                               │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Implementation Priority

1. **`pp` picker** - Instant navigation to any project
2. **`work`/`done`** - Session-based workflow
3. **`now`/`next`** - Status and suggestions
4. **`dash`** - Universal dashboard
5. **Context-aware ops** - `pt`, `pb`, `pc`
6. **Keep `mv*`** - Backwards compatible

---

## Decision

**Selected:** Option D + E Hybrid

**Implementation Date:** 2025-12-14

---

## Final Implementation

### Commands Implemented

#### Session Workflow
| Command | Description |
|---------|-------------|
| `work NAME` | Start session (cd + branch + status + log) |
| `finish [MSG]` | End session (commit + merge prompt) |
| `now` | What am I working on? |
| `next` | What should I work on next? |

#### Navigation
| Command | Description |
|---------|-------------|
| `pp` | Project picker (fzf) - all projects |
| `ppr` | R packages only |
| `ppd` | Dev tools only |
| `ppq` | Quarto only |
| `pcd NAME` | Quick cd to project |

#### Context-Aware Operations
| Command | Description |
|---------|-------------|
| `pt` | Test (R→devtools, Node→npm, Python→pytest) |
| `pb` | Build (R→devtools, Node→npm, Quarto→render) |
| `pc MSG` | Quick commit (git add -A && commit) |
| `pr` | Run/render (Quarto→render, Node→start) |
| `pv` | Preview (Quarto only) |

#### R Package Specific
| Command | Description |
|---------|-------------|
| `pcheck` | R CMD check (devtools::check) |
| `pdoc` | Document (devtools::document) |
| `pinstall` | Install (devtools::install) |
| `pload` | Load all (devtools::load_all) |

#### Dashboards
| Command | Description |
|---------|-------------|
| `dash` | Master dashboard (all projects) |
| `dash r` | R packages only |
| `dash dt` | Dev tools only |
| `dash sync` | Sync to Apple Notes |

#### Utilities
| Command | Description |
|---------|-------------|
| `plog [N]` | Show recent N commits (default 10) |
| `pmorning` | Morning routine (pull all + dashboard) |
| `phelp` | Quick reference card |

### Aliases
```
gm = pmorning      # good morning
wdone = finish     # alternative for finish
fin = finish       # short for finish
```

### Project Categories Configured
```
~/projects/r-packages/active    → r    📦
~/projects/r-packages/stable    → r    📦
~/projects/dev-tools            → dt   🔧
~/projects/quarto/manuscripts   → q    📝
~/projects/quarto/presentations → q    📊
~/projects/research             → rs   🔬
~/projects/apps                 → app  📱
```

### Backwards Compatible
All existing `mv*` commands for mediationverse remain functional:
- `mvst`, `mvr`, `mvs`, `mvci`, `mvpush`, `mvpull`, `mvmerge`, `mvrebase`, `mvdev`

---

## Usage Examples

```bash
# Morning routine
pmorning              # Pull all + show dashboard

# Start working
work medfit           # cd to medfit, checkout dev, show status

# While working
pt                    # Run tests
pdoc                  # Update documentation
pc "Add feature"      # Quick commit

# End session
finish "Feature done" # Commit + merge prompt

# Navigation
pp                    # Pick any project with fzf
pcd claude            # Quick cd (fuzzy match)

# Status
dash                  # See all projects
next                  # What needs attention?
plog                  # Recent commits
```

---

## File Location

All commands implemented in:
`~/.config/zsh/functions/adhd-helpers.zsh`

Lines 1581-2608 (Universal Project Workflow section)


