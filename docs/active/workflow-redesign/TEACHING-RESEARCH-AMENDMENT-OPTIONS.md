# Teaching & Research Amendment Options

**Date:** 2025-12-14
**Status:** ✅ Implemented (Option D)
**Philosophy:** Extend existing system, don't create parallel one

---

## Current System Recap

```
work NAME → context → pt/pb/pc → finish
  │           │          │          │
  fuzzy     .STATUS    detect     commit
  find      branch     type       log
```

**Core Commands:** `work`, `pp`, `dash`, `now`, `next`, `finish`, `js`
**Context-Aware:** `pt`, `pb`, `pc`, `pr`, `pv` (detect project type)

---

## Option A: Minimal Extension (Recommended)

**Philosophy:** Teaching and research are just more project types. Extend detection, not commands.

### Changes

1. **Enhance `_proj_detect_type()`** to recognize teaching/research:

```zsh
_proj_detect_type() {
    # Existing checks...
    elif [[ -d "$dir/lectures" || -d "$dir/slides" ]]; then
        echo "teaching"
    elif [[ -f "$dir/main.tex" ]] || [[ -d "$dir/manuscript" ]]; then
        echo "research"
    # ...
}
```

2. **Enhance context-aware commands:**

```zsh
pt() {  # test
    case $(_proj_detect_type) in
        teaching) quarto check ;;
        research) [run analysis checks] ;;
        # existing...
    esac
}

pb() {  # build
    case $(_proj_detect_type) in
        teaching) quarto render ;;
        research) latexmk -pdf main.tex || quarto render ;;
        # existing...
    esac
}

pv() {  # preview/view
    case $(_proj_detect_type) in
        teaching) quarto preview ;;
        research) open main.pdf || open *.pdf(om[1]) ;;
        # existing...
    esac
}
```

3. **Add teaching/research to `work` output:**

```zsh
work() {
    # ... existing code ...
    case "$proj_type" in
        teaching)
            echo "     pv          Preview site"
            echo "     pb          Build/render"
            echo "     finish MSG  End session"
            ;;
        research)
            echo "     pb          Build PDF"
            echo "     pv          View PDF"
            echo "     finish MSG  End session"
            ;;
    esac
}
```

### Result

```
work stat-440        # Detects teaching, shows teaching commands
work product-of-three # Detects research, shows research commands
pt                   # Runs quarto check (teaching) or analysis (research)
pb                   # Renders site (teaching) or builds PDF (research)
```

### Pros

- No new commands to learn
- Consistent with existing mental model
- `work`, `pp`, `dash` just work

### Cons

- Less discoverable for domain-specific actions
- Can't have teaching-specific commands like `tlec`

---

## Option B: Thin Alias Layer

**Philosophy:** Keep existing commands, add short memorable aliases that call them.

### Changes

1. **All of Option A**, plus:

2. **Add convenience aliases only:**

```zsh
# Teaching shortcuts (call existing commands)
alias tw='work'              # tw stat-440 = work stat-440
alias td='tst'               # Teaching dashboard (specialized)
alias tp='pp teach'          # Pick teaching project

# Research shortcuts
alias rw='work'              # rw collider = work collider
alias rd='rst'               # Research dashboard (specialized)
alias rp='pp rs'             # Pick research project
```

3. **Keep specialized dashboards** (`tst`, `rst`) because they show domain-specific info:

```zsh
tst()  # Shows week number, what to prepare, course calendar
rst()  # Shows manuscript status, simulation progress, submission deadlines
```

### Result

```
tw stat-440          # Same as: work stat-440
tp                   # Same as: pp teach
td                   # Teaching-specific dashboard
pb                   # Build (context-aware, same command everywhere)
```

### Pros

- Two paths: `tw` for speed, `work` for clarity
- Specialized dashboards surface domain info
- Minimal new learning

### Cons

- `tw` and `work` do same thing (redundancy)

---

## Option C: Domain Commands with Shared Core

**Philosophy:** Domain-specific entry points, shared operations.

### Changes

1. **Domain entry points:**

```zsh
teach() {           # Instead of twork
    local course="$1"
    work "$course"  # Reuse work()

    # Add teaching-specific context
    _show_week_info
    _show_course_calendar
}

research() {        # Instead of rwork
    local project="$1"
    work "$project"  # Reuse work()

    # Add research-specific context
    _show_manuscript_status
    _show_simulation_status
}
```

2. **Shared operations (no change):**

```zsh
pt, pb, pc, pv, finish  # Work exactly as before, detect context
```

3. **Domain-specific operations (few, only where needed):**

```zsh
# Teaching-only (no equivalent in other domains)
tweek()     # Show current week content
tcal()      # Course calendar

# Research-only (no equivalent in other domains)
rsim()      # Run simulation (unique to research)
rlit()      # Literature search (unique to research)
```

### Result

```
teach stat-440       # work + teaching context
research collider    # work + research context
pb                   # Build (same command, detects context)
tweek                # Teaching-specific (no p* equivalent)
rsim test            # Research-specific (no p* equivalent)
```

### Pros

- Clear domain entry points
- Shared operations stay unified
- Domain commands only where truly unique

### Cons

- `teach` vs `work` - when to use which?

---

## Option D: Enhanced Context with Smart `work`

**Philosophy:** Make `work` smarter, add domain hints.

### Changes

1. **Smart `work` with domain detection:**

```zsh
work() {
    local query="$1"
    local proj_dir=$(_proj_find "$query")
    local proj_type=$(_proj_detect_type "$proj_dir")

    # Standard work() setup...

    # Domain-specific enhancements
    case "$proj_type" in
        teaching)
            _show_teaching_context "$proj_dir"
            ;;
        research)
            _show_research_context "$proj_dir"
            ;;
    esac
}

_show_teaching_context() {
    local week=$(_get_current_week)
    echo "  📅 Week: $week"
    echo "  📋 Prepare: $(grep "^week-$week" "$1/.STATUS" 2>/dev/null)"
}

_show_research_context() {
    echo "  📄 Status: $(grep "^status:" "$1/.STATUS" 2>/dev/null)"
    echo "  🎯 Next: $(grep "^next:" "$1/.STATUS" 2>/dev/null)"
}
```

2. **Enhanced `dash` with domain sections:**

```zsh
dash() {
    # Existing categories + richer teaching/research display
    # For teaching: show week, upcoming deadlines
    # For research: show manuscript stage, submission status
}
```

3. **Minimal new commands (only unique operations):**

```zsh
rsim [MODE]    # Run simulation (research-only)
tweek          # What's happening this week (teaching-only)
```

### Result

```
work stat-440        # Shows teaching context automatically
work collider        # Shows research context automatically
dash                 # Unified view with rich domain info
rsim local           # Research-specific command
tweek                # Teaching-specific command
```

### Pros

- Minimal new commands
- `work` is smarter, not different
- Domain context surfaces automatically

### Cons

- `work` output varies by type (could be confusing?)

---

## Comparison Matrix

| Feature                  | Option A      | Option B    | Option C               | Option D       |
| ------------------------ | ------------- | ----------- | ---------------------- | -------------- |
| New commands to learn    | 0             | 3-4 aliases | 2 entry + few specific | 2-3 specific   |
| Consistency              | High          | High        | Medium                 | High           |
| Discoverability          | Low           | Medium      | High                   | Medium         |
| Domain-specific features | Via detection | Via tst/rst | Via teach/research     | Via smart work |
| Implementation effort    | Low           | Low         | Medium                 | Medium         |
| Mental model change      | None          | Minimal     | Moderate               | Minimal        |

---

## Recommendation

**Option B (Thin Alias Layer)** or **Option D (Enhanced Context)**

### Rationale

1. **Keep `work`, `pp`, `dash`, `pt`, `pb` unchanged** - they already work
2. **Add detection for teaching/research** - context-aware commands adapt
3. **Keep `tst` and `rst`** - specialized dashboards add value
4. **Add only truly unique commands:**
   - `tweek` - teaching week info (no p\* equivalent)
   - `rsim` - run simulation (unique workflow)
   - `rlit` - literature search (unique to research)
5. **Optional short aliases** - `tw`, `td`, `rw`, `rd` for muscle memory

### Implementation Order

```
Phase 1: Detection
  └─ Update _proj_detect_type for teaching/research

Phase 2: Context-aware operations
  └─ Update pt, pb, pv for teaching/research cases

Phase 3: Specialized dashboards
  └─ Keep tst, rst (already done)

Phase 4: Unique commands (only if needed)
  └─ tweek, rsim, rlit

Phase 5: Short aliases (optional)
  └─ tw, td, tp, rw, rd, rp
```

---

## Decision

**Selected: Option D (Enhanced Context with Smart `work`)**

---

## Implementation Summary (2025-12-14)

### What Was Implemented

#### 1. Enhanced Project Detection

```zsh
_proj_detect_type() {
    local dir="${1:-$(pwd)}"

    # Path-based detection (teaching/research folders)
    if [[ "$dir" == */projects/teaching/* ]]; then
        echo "teaching"
    elif [[ "$dir" == */projects/research/* ]]; then
        if [[ -f "$dir/main.tex" ]]; then
            echo "research-tex"
        elif [[ -f "$dir/_quarto.yml" ]]; then
            echo "research-qmd"
        else
            echo "research"
        fi
    # File-based detection (existing)
    elif [[ -f "$dir/DESCRIPTION" ]]; then
        echo "r"
    # ... etc
    fi
}
```

#### 2. Domain Context Helpers

```zsh
_show_teaching_context() {
    # Shows: Week number, recent files, .STATUS next action
}

_show_research_context() {
    # Shows: Manuscript type, word count, status, target journal
}
```

#### 3. Smart `work` Command

The `work` command now automatically displays domain-specific context:

```
work stat-440
╔════════════════════════════════════════════════════════════╗
║  🚀 STARTING SESSION: stat-440                             ║
╚════════════════════════════════════════════════════════════╝

  📂 /Users/dt/projects/teaching/stat-440/
  🌿 Branch: main
  📦 Type: teaching

  📊 Status: 168 uncommitted changes

  🎓 TEACHING CONTEXT
  ─────────────────────────────────
  📅 Week: 15 of 16
  📝 Recent: assignment-11.qmd

────────────────────────────────────────
  💡 Commands:
     pb          Build site (quarto render)
     pv          Preview (quarto preview)
     tweek       Current week info
     finish MSG  End session
```

#### 4. Context-Aware Operations

| Command | Teaching       | Research-tex | Research-qmd   | R Package       |
| ------- | -------------- | ------------ | -------------- | --------------- |
| `pb`    | quarto render  | latexmk -pdf | quarto render  | devtools::build |
| `pv`    | quarto preview | open PDF     | quarto preview | -               |
| `pt`    | quarto check   | lacheck      | quarto check   | devtools::test  |

#### 5. Commands Kept (Unique Only)

**Teaching:**

- `tweek` - Show current week info
- `tlec [WEEK]` - Open lecture file
- `tslide [WEEK]` - Open slides
- `tpublish` - Deploy to GitHub Pages
- `tst` - Teaching dashboard
- `thelp` - Quick reference

**Research:**

- `rms` - Open manuscript file
- `rsim [MODE]` - Run simulation
- `rlit [QUERY]` - Search literature
- `rst` - Research dashboard
- `rhelp` - Quick reference

#### 6. Commands Removed (Redundant)

| Removed    | Use Instead    |
| ---------- | -------------- |
| `twork`    | `work COURSE`  |
| `rwork`    | `work PROJECT` |
| `tpreview` | `pv`           |
| `trender`  | `pb`           |
| `rpdf`     | `pb`           |

### Final Command Structure

```
┌─────────────────────────────────────────────────────────────┐
│  OPTION D: ENHANCED CONTEXT WORKFLOW                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  UNIVERSAL (unchanged)                                      │
│  ─────────────────────────────────────────────────────────  │
│  work NAME       Start session (smart context)              │
│  pp [CATEGORY]   Project picker                             │
│  dash [FILTER]   Dashboard                                  │
│  pb              Build (context-aware)                      │
│  pv              Preview/View (context-aware)               │
│  pt              Test (context-aware)                       │
│  pc MSG          Commit                                     │
│  finish [MSG]    End session                                │
│                                                             │
│  TEACHING (unique only)                                     │
│  ─────────────────────────────────────────────────────────  │
│  tweek           Current week info                          │
│  tlec [WEEK]     Open lecture                               │
│  tslide [WEEK]   Open slides                                │
│  tpublish        Deploy to GitHub Pages                     │
│  tst             Teaching dashboard                         │
│  ppt             Pick teaching project (alias: pp teach)    │
│                                                             │
│  RESEARCH (unique only)                                     │
│  ─────────────────────────────────────────────────────────  │
│  rms             Open manuscript                            │
│  rsim [MODE]     Run simulation                             │
│  rlit [QUERY]    Search literature                          │
│  rst             Research dashboard                         │
│  pprs            Pick research project (alias: pp rs)       │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Key Principle

> **One mental model: `work` to start, `pb` to build, `pv` to view — context does the rest.**

### Files Modified

- `~/.config/zsh/functions/adhd-helpers.zsh`
  - Updated `_proj_detect_type()` for teaching/research
  - Added `_show_teaching_context()` and `_show_research_context()`
  - Enhanced `work()` to show domain context
  - Updated `pt()`, `pb()`, `pv()` for teaching/research cases
  - Added `tweek()`
  - Removed redundant: `twork`, `rwork`, `tpreview`, `trender`, `rpdf`
  - Updated `thelp()` and `rhelp()` to reflect new structure

### Testing

```bash
# Source and test
source ~/.config/zsh/functions/adhd-helpers.zsh

# Test detection
work stat-440      # Should show teaching context
work collider      # Should show research context

# Test dashboards
tst                # Teaching status
rst                # Research status

# Test help
thelp              # Teaching commands
rhelp              # Research commands
```

### Future Enhancements

1. Add `.STATUS` files to all teaching/research projects
2. Integrate `rlit` with MCP/Zotero for literature search
3. Add tab completion for course/project names
4. Calendar integration for `tweek`
