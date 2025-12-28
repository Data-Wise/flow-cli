# Teaching & Research Workflow Expansion

**Date:** 2025-12-14
**Status:** Proposal

---

## Current Project Landscape (Expanded)

```
~/projects/
├── apps/                           # Applications (1 project)
│   └── examark
│
├── dev-tools/                      # Development tooling (16 projects)
│   ├── apple-notes-sync
│   ├── claude-mcp
│   ├── claude-statistical-research
│   └── ...
│
├── quarto/                         # Quarto templates (empty - projects self-contained)
│   ├── extensions/
│   ├── manuscripts/
│   └── presentations/
│
├── r-packages/                     # R packages (6 packages)
│   ├── active/                     # mediationverse ecosystem
│   │   ├── medfit, mediationverse, medrobust, medsim, probmed
│   └── stable/
│       └── rmediation
│
├── research/                       # Research projects (6 projects) ⭐ NEW
│   ├── mediation-planning          # Ecosystem coordination hub
│   ├── product of three            # JASA manuscript (active)
│   ├── collider                    # Methodology paper (under review)
│   ├── sensitivity                 # Mplus simulations
│   ├── mult_med                    # Literature archive
│   └── pmed                        # Completed manuscript
│
└── teaching/                       # Teaching courses (3 courses) ⭐ NEW
    ├── stat-440                    # Regression Analysis (active)
    ├── causal-inference            # STAT 579 (active)
    └── S440_regression_Fall_2024   # Fall 2024 archive
```

**Total: ~35 projects across 6 categories**

---

## Proposed Category Structure

| Category   | Code    | Icon | Path                      | Projects |
| ---------- | ------- | ---- | ------------------------- | -------- |
| R Packages | `r`     | 📦   | r-packages/active, stable | 6        |
| Dev Tools  | `dt`    | 🔧   | dev-tools                 | 16       |
| Teaching   | `teach` | 🎓   | teaching                  | 3        |
| Research   | `rs`    | 🔬   | research                  | 6        |
| Quarto     | `q`     | 📝   | quarto/\*                 | 0        |
| Apps       | `app`   | 📱   | apps                      | 1        |

---

## Teaching Workflow

### Course Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│  TEACHING WORKFLOW                                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  📅 SEMESTER PLANNING                                       │
│    tcal [COURSE]      Show/edit course calendar             │
│    tweek [N]          Current week content                  │
│    tnext              What to prepare next                  │
│                                                             │
│  📝 CONTENT CREATION                                        │
│    tlec [WEEK]        Open/create lecture for week          │
│    tslide [WEEK]      Open/create slides for week           │
│    tassign [N]        Open/create assignment N              │
│    tlab [N]           Open/create lab N                     │
│                                                             │
│  🔨 BUILD & PREVIEW                                         │
│    trender            Render current file (detect type)     │
│    tpreview           Preview course website locally        │
│    tbuild             Full site build                       │
│    tpdf [FILE]        Render to PDF (lectures/handouts)     │
│                                                             │
│  📤 DEPLOYMENT                                              │
│    tpublish           Deploy to GitHub Pages                │
│    tsync              Sync grades/roster (if configured)    │
│                                                             │
│  📊 STATUS                                                  │
│    tst [COURSE]       Teaching status dashboard             │
│    tprogress          Semester progress overview            │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Course Status Dashboard (`tst`)

```
╔════════════════════════════════════════════════════════════╗
║  🎓 TEACHING DASHBOARD                                     ║
╚════════════════════════════════════════════════════════════╝

  Updated: 2025-12-14 13:00

  📚 ACTIVE COURSES
  ────────────────────────────────────────
  stat-440         🟢 Week 14/16  Diagnostics
                      Next: Final review slides
  causal-inference 🟢 Week 13/15  Target trials
                      Next: Student presentations

  📦 ARCHIVED
  ────────────────────────────────────────
  S440_Fall_2024   ✅ Complete

────────────────────────────────────────────────────────────
  💡 Commands: twork COURSE | tlec | tpreview | tpublish
```

---

## Research Workflow

### Manuscript Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│  RESEARCH WORKFLOW                                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  📄 MANUSCRIPT MANAGEMENT                                   │
│    rwork [PROJECT]    Start research session                │
│    rms [PROJECT]      Open main manuscript file             │
│    rbib [PROJECT]     Open/edit bibliography                │
│    rnote [TOPIC]      Quick research note                   │
│                                                             │
│  🔬 SIMULATION & ANALYSIS                                   │
│    rsim [MODE]        Run simulation (test/local/cluster)   │
│    ranalysis          Run analysis pipeline                 │
│    rfig [N]           Generate/regenerate figure N          │
│    rtable [N]         Generate/regenerate table N           │
│                                                             │
│  🔨 BUILD                                                   │
│    rpdf               Build PDF (detect LaTeX/Quarto)       │
│    rword              Build Word doc (for journals)         │
│    rclean             Clean build artifacts                 │
│                                                             │
│  📚 LITERATURE                                              │
│    rlit [QUERY]       Search literature (Zotero/local)      │
│    rcite KEY          Copy citation for key                 │
│    rnotes KEY         View/add notes for paper              │
│                                                             │
│  📤 SUBMISSION                                              │
│    rsub [JOURNAL]     Prepare submission package            │
│    rcover             Generate cover letter template        │
│    rresponse          Start revision response document      │
│                                                             │
│  📊 STATUS                                                  │
│    rst [PROJECT]      Research status dashboard             │
│    rpipeline          Show analysis pipeline status         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Research Status Dashboard (`rst`)

```
╔════════════════════════════════════════════════════════════╗
║  🔬 RESEARCH DASHBOARD                                     ║
╚════════════════════════════════════════════════════════════╝

  Updated: 2025-12-14 13:00

  📝 MANUSCRIPTS
  ────────────────────────────────────────
  product-of-three  🟡 Draft    Target: JASA
                       Sims: ✅ Done  Figs: 4/6
                       Next: Complete Results section
  collider          🟢 Review   Under review (Rev 3)
                       Next: Wait for decision

  📊 PLANNING & COORDINATION
  ────────────────────────────────────────
  mediation-planning 🟢 Active   Ecosystem hub
                        Next: medfit API design

  📚 ARCHIVES
  ────────────────────────────────────────
  sensitivity       ⏸️ Paused   Mplus sims
  mult_med          📚 Archive  Literature
  pmed              ✅ Complete

────────────────────────────────────────────────────────────
  💡 Commands: rwork PROJECT | rpdf | rsim | rlit
```

---

## Integrated Universal Commands (Updated)

```
┌─────────────────────────────────────────────────────────────┐
│  UNIVERSAL PROJECT WORKFLOW (v2.0)                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  🎯 SESSION MANAGEMENT                                      │
│    work NAME          Start session (any project type)      │
│    finish [MSG]       End session with commit               │
│    now                 Current status                        │
│    next                What needs attention                  │
│                                                             │
│  🔍 NAVIGATION                                              │
│    pp                  Project picker (all)                  │
│    ppr                 R packages only                       │
│    ppd                 Dev tools only                        │
│    ppt                 Teaching only ⭐ NEW                  │
│    pprs                Research only ⭐ NEW                  │
│    pcd NAME            Quick cd (fuzzy)                     │
│                                                             │
│  📊 DASHBOARDS                                              │
│    dash                Master dashboard (all)               │
│    dash r              R packages                           │
│    dash dt             Dev tools                            │
│    dash teach          Teaching ⭐ NEW                      │
│    dash rs             Research ⭐ NEW                      │
│    dash sync           Sync to Apple Notes                  │
│                                                             │
│  🔨 CONTEXT-AWARE OPERATIONS                                │
│    pt                  Test (R/Node/Quarto check)           │
│    pb                  Build (R/Node/Quarto/LaTeX)          │
│    pc MSG              Commit                               │
│    pr                  Run/Render                           │
│    pv                  Preview (Quarto/web)                 │
│                                                             │
│  📦 R PACKAGE SPECIFIC                                      │
│    pcheck              R CMD check                          │
│    pdoc                devtools::document                   │
│    pinstall            devtools::install                    │
│    pload               devtools::load_all                   │
│                                                             │
│  🎓 TEACHING SPECIFIC ⭐ NEW                                │
│    tlec [WEEK]         Open lecture file                    │
│    tslide [WEEK]       Open slides                          │
│    tpreview            Preview course site                  │
│    tpublish            Deploy course site                   │
│    tweek               Current week info                    │
│                                                             │
│  🔬 RESEARCH SPECIFIC ⭐ NEW                                │
│    rms                 Open manuscript                      │
│    rsim [MODE]         Run simulation                       │
│    rpdf                Build PDF                            │
│    rlit [QUERY]        Search literature                    │
│                                                             │
│  🛠️ UTILITIES                                               │
│    plog [N]            Recent commits                       │
│    pmorning            Morning routine                      │
│    phelp               Quick reference                      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Project Type Detection (Enhanced)

```
Project Type Detection Priority:
1. _quarto.yml           → Quarto (check for course structure)
2. DESCRIPTION           → R Package
3. package.json          → Node.js
4. main.tex / *.tex      → LaTeX manuscript
5. Makefile              → Make-based project
6. .Rproj                → R Project
7. requirements.txt      → Python
8. lectures/ + slides/   → Teaching course
9. manuscript/ or *.qmd  → Research manuscript
```

---

## Morning Routine (Enhanced)

```bash
pmorning() {
    # Pull all projects
    # Show unified dashboard
    # Highlight:
    #   - Teaching: what to prepare this week
    #   - Research: manuscript deadlines, simulation status
    #   - R packages: CI status, issues
    #   - Dev tools: pending commits
}
```

### Example Output

```
╔════════════════════════════════════════════════════════════╗
║  ☀️ GOOD MORNING                           Dec 14, 2025    ║
╚════════════════════════════════════════════════════════════╝

  📥 Pulling updates...
     ✅ 35 projects synced

  🎓 TEACHING (Week 14)
  ────────────────────────────────────────
  stat-440:          Prepare final review
  causal-inference:  Grade project proposals

  🔬 RESEARCH PRIORITIES
  ────────────────────────────────────────
  product-of-three:  Complete Results section
  collider:          Awaiting review decision

  📦 R PACKAGES
  ────────────────────────────────────────
  medfit:            1 uncommitted file
  medsim:            dev 9 behind main

  🔧 DEV-TOOLS
  ────────────────────────────────────────
  apple-notes-sync:  1 uncommitted file

────────────────────────────────────────────────────────────
  💡 Suggested: work stat-440 (teaching prep due)
```

---

## Implementation Plan

### Phase 1: Configuration

1. Add teaching/research to PROJ_CATEGORIES
2. Update \_proj_detect_type for new project types
3. Update dashboard templates

### Phase 2: Teaching Commands

1. `twork`, `tlec`, `tslide`, `tpreview`, `tpublish`
2. `tweek`, `tst` (teaching status)
3. Course calendar integration

### Phase 3: Research Commands

1. `rwork`, `rms`, `rsim`, `rpdf`
2. `rlit` (literature search via MCP/Zotero)
3. `rst` (research status)

### Phase 4: Integration

1. Enhanced `pmorning` with teaching/research priorities
2. Apple Notes sync for all categories
3. Tab completion for new commands

---

## Command Summary (Option D - Implemented)

| Category  | Entry Point    | Context-Aware          | Unique Commands                              |
| --------- | -------------- | ---------------------- | -------------------------------------------- |
| Universal | `work NAME`    | `pb`, `pv`, `pt`, `pc` | `pp`, `dash`, `finish`                       |
| R Package | `work NAME`    | `pb`, `pt`             | `pcheck`, `pdoc`, `pload`                    |
| Teaching  | `work COURSE`  | `pb`, `pv`             | `tweek`, `tlec`, `tslide`, `tpublish`, `tst` |
| Research  | `work PROJECT` | `pb`, `pv`             | `rms`, `rsim`, `rlit`, `rst`                 |

---

## ADHD-Friendly Alias Naming Convention

### Design Principles

1. **Two paths to same place** - Short for speed, long for discovery
2. **Consistent 2-letter pattern** - `[category][action]`
3. **Natural words** - Long forms are real words, no memorization needed
4. **No collisions** - Avoid conflicts with common commands (rm, pp, etc.)
5. **Muscle memory friendly** - Frequently used = shorter

### Alias Scheme

```
┌─────────────────────────────────────────────────────────────┐
│  ADHD-FRIENDLY ALIASES                                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  SHORT        LONG            ACTION                        │
│  (2-char)     (memorable)                                   │
│                                                             │
│  TEACHING (t = teach)                                       │
│  ─────────────────────────────────────────────────────────  │
│  tw           teach           Start teaching session        │
│  td           tclass          Teaching dashboard            │
│  tp           tcourse         Pick course (fuzzy finder)    │
│  ts           tstatus         Quick status check            │
│  tl           tlecture        Open lecture file             │
│  tv           tview           Preview course site           │
│  tb           tbuild          Build/render course           │
│  tx           tdeploy         Deploy to GitHub Pages        │
│                                                             │
│  RESEARCH (r = research)                                    │
│  ─────────────────────────────────────────────────────────  │
│  rw           research        Start research session        │
│  rd           rpapers         Research dashboard            │
│  rp           rproject        Pick project (fuzzy finder)   │
│  rs           rstatus         Quick status check            │
│  rm̲s          manuscript      Open manuscript (not rm!)     │
│  rb           rbuild          Build PDF                     │
│  rx           rsim            Run simulation (x=execute)    │
│  rl           rlit            Literature search             │
│                                                             │
│  UNIVERSAL (unchanged)                                      │
│  ─────────────────────────────────────────────────────────  │
│  work         -               Start any session             │
│  dash         -               Master dashboard              │
│  pp           -               Project picker (all)          │
│  now          -               Current status                │
│  next         -               What needs attention          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Why This Works for ADHD

| Problem                         | Solution                                       |
| ------------------------------- | ---------------------------------------------- |
| "What was that command?"        | Long form is a real word (`teach`, `research`) |
| "Too many keystrokes"           | Short form is always 2 chars (`tw`, `rw`)      |
| "Which prefix?"                 | Consistent: t=teaching, r=research             |
| "Conflicts with other commands" | Avoided `rm`, `pp` standalone                  |
| "Forgot the pattern"            | `[category][action]` everywhere                |

### Collision Avoidance

| Avoided         | Why                             | Alternative                        |
| --------------- | ------------------------------- | ---------------------------------- |
| `rm`            | Unix remove command             | `ms` or `manuscript`               |
| `pp` standalone | Already used for project picker | Keep as-is                         |
| `ppt`           | PowerPoint association          | `tp` (teaching pick)               |
| `rs`            | Could conflict                  | Context: only in teaching/research |

### Quick Reference Card

```
TEACHING                    RESEARCH
─────────────────────────   ─────────────────────────
tw  → start session         rw  → start session
td  → dashboard             rd  → dashboard
tp  → pick course           rp  → pick project
ts  → status                rs  → status
tl  → lecture               ms  → manuscript
tv  → preview               rb  → build PDF
tb  → build                 rx  → run simulation
tx  → deploy                rl  → literature
```

---

## Decision

**Selected: Option D (Enhanced Context with Smart `work`)**

**Status:** ✅ Fully Implemented (2025-12-14)

### What Was Done

1. **Enhanced `_proj_detect_type()`** - Detects teaching/research from path
2. **Added context helpers** - `_show_teaching_context()`, `_show_research_context()`
3. **Smart `work` command** - Shows domain-specific context automatically
4. **Context-aware operations** - `pb`, `pv`, `pt` work for all project types
5. **Unique commands only** - Removed redundant `twork`, `rwork`, `tpreview`, `rpdf`
6. **Added `.STATUS` files** - 14 files across teaching/research projects

### Key Principle

> **One mental model: `work` to start, `pb` to build, `pv` to view — context does the rest.**

### Files Modified

- `~/.config/zsh/functions/adhd-helpers.zsh` - Core implementation
- `~/projects/teaching/*/.STATUS` - 3 teaching status files
- `~/projects/research/*/.STATUS` - 11 research status files

### Related Documents

- [Amendment Options](../../implementation/workflow-redesign/TEACHING-RESEARCH-AMENDMENT-OPTIONS.md) - Full Option D implementation details
- adhd-helpers.zsh (`~/.config/zsh/functions/adhd-helpers.zsh`) - Source code

**Notes:**
