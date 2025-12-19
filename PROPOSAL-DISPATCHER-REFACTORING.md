# Dispatcher Refactoring Proposal - Keyword Overloading

**Generated:** 2025-12-19
**Purpose:** Consolidate aliases into keyword-based dispatchers for main workflow functions
**Pattern:** Follow existing `r`, `qu`, `cc`, `gm` dispatcher model
**Priority:** High-value commands with multiple related actions

---

## 📋 Analysis of Checked Items

Based on WORKFLOW-OPTIONS-CLEANUP.md, you marked **43 items** for removal. These break down into clear patterns for consolidation:

### Identified Consolidation Opportunities

1. **Quarto** (`qu`) - ✅ Already implemented
2. **Pick** - 7 aliases → `pick` with keywords
3. **Work/Vib** - Session management consolidation
4. **Focus/Timer** - Time management consolidation
5. **Peek** - 6 viewer commands → unified viewer
6. **R Package Cleanup** - 4 maintenance commands

---

## 🎯 Guiding Principles

**From existing dispatchers (r, qu, cc, gm):**

1. **Mnemonic root command** - Short, memorable (2-3 chars max)
2. **Full-word keywords** - `preview`, `render`, `test` (not `p`, `r`, `t`)
3. **No args = help** - Shows available actions
4. **Backward compatible** - Old aliases can coexist during transition
5. **Self-documenting** - Built-in help with examples
6. **ADHD-friendly** - Visual hierarchy, clear examples

**Pattern:**
```zsh
command_name() {
    if [[ $# -eq 0 ]]; then
        command_name help
        return
    fi

    case "$1" in
        keyword1|k1) action1 ;;
        keyword2|k2) action2 ;;
        help|h) show_help ;;
        *) echo "Unknown: $1"; command_name help; return 1 ;;
    esac
}
```

---

## 💡 Proposed Dispatchers

### 1. `vib` - Workflow & Session Management ⭐ NEW

**Purpose:** Consolidate session/workflow/energy management
**Etymology:** "vibe" - workflow energy and rhythm management
**Replaces:** `startsession`, `endsession`, `progress_check`, `status`, `gm`, `gn`

```zsh
vib() {
    case "$1" in
        # Session management
        start|s)        startsession "$@" ;;
        end|e)          endsession "$@" ;;
        status|st)      show_current_session ;;

        # Energy/time of day
        morning|gm)     pmorning ;;
        night|gn)       pnight ;;

        # Progress tracking
        progress|p)     progress_check ;;
        check|c)        progress_check ;;

        # Help
        help|h)         _vib_help ;;

        *)
            echo "Unknown action: $1"
            vib help
            return 1
            ;;
    esac
}
```

**Usage examples:**
```bash
vib morning              # Morning routine (replaces gm)
vib start medfit         # Start session (replaces startsession)
vib end                  # End session (replaces endsession)
vib progress             # Show all project progress
vib status               # Current session status
```

**Removed aliases:** `gm`, `gn`, `pmorning`, `pnight`, `startsession`, `endsession`, `progress_check`, `status`

---

### 2. `pick` - Enhanced Project Navigation ⭐ REFACTOR

**Current:** Already has dispatcher structure via fzf, but aliases for filters
**Enhancement:** Add keyword-based filters alongside existing behavior
**Replaces:** `pickr`, `pickdev`, `pickq`, `pickteach`, `pickrs`, `pp`, `cdproj`

**Current behavior (keep):**
```bash
pick              # Interactive fzf picker
pick r            # Filter R packages
pick dev          # Filter dev tools
```

**Enhanced dispatcher (add):**
```zsh
pick() {
    # No args → interactive picker (current behavior)
    if [[ $# -eq 0 ]]; then
        _pick_interactive
        return
    fi

    case "$1" in
        # Project type filters (KEEP current short codes)
        r|pkg|package)          _pick_filter "r" ;;
        dev|tool|tools)         _pick_filter "dev" ;;
        q|quarto|doc)           _pick_filter "q" ;;
        teach|course)           _pick_filter "teach" ;;
        rs|research)            _pick_filter "rs" ;;
        app|apps)               _pick_filter "app" ;;

        # New: Management section (from PROPOSAL-PICK-ENHANCEMENTS.md)
        mgmt|meta|manage)       _pick_filter "mgmt" ;;

        # New: Recently used (from PROPOSAL-PICK-RECENT-SECTION.md)
        recent|rec|last)        _pick_recent ;;

        # Utility
        list|ls)                _proj_list_all ;;
        tree)                   _proj_tree ;;

        # Help
        help|h)                 _pick_help ;;

        *)
            # Fallback: treat as filter if matches category
            _pick_filter "$1"
            ;;
    esac
}
```

**Usage:**
```bash
pick                    # Interactive (current)
pick r                  # R packages (current - KEEP)
pick dev                # Dev tools (current - KEEP)
pick recent             # Recently used (NEW)
pick mgmt               # Management projects (NEW)
pick list               # Show all projects
```

**Removed aliases:** `pickr`, `pickdev`, `pickq`, `pickteach`, `pickrs`, `pp` (redundant with `pick`)

**Note:** Keep short codes (`r`, `dev`, `q`) for speed. Keywords are additive.

---

### 3. `work` - Session Starter ✅ KEEP AS-IS

**Status:** Already well-designed with keyword support
**Location:** `~/.config/zsh/functions/work.zsh`
**No changes needed** - already follows dispatcher pattern with `--editor`, `--mode` flags

**Current usage (already good):**
```bash
work medfit                  # Auto-detect editor
work medfit --emacs          # Force Emacs
work medfit --claude         # Force Claude Code
```

---

### 4. `timer` - Focus & Time Management ⭐ NEW

**Purpose:** Consolidate all timer/focus/break functionality
**Replaces:** `focus`, `unfocus`, `worktimer`, `quickbreak`, `break`, `deepwork`

```zsh
timer() {
    case "$1" in
        # Focus sessions
        focus|f)
            local minutes="${2:-25}"  # Default 25 min Pomodoro
            _timer_focus "$minutes"
            ;;

        deep|d)
            local minutes="${2:-90}"  # Default 90 min deep work
            _timer_focus "$minutes" "deep"
            ;;

        # Breaks
        break|b)
            local minutes="${2:-5}"   # Default 5 min break
            _timer_break "$minutes"
            ;;

        long|l)
            local minutes="${2:-15}"  # Default 15 min long break
            _timer_break "$minutes" "long"
            ;;

        # Stop
        stop|end|x)
            _timer_stop
            ;;

        # Status
        status|st)
            _timer_status
            ;;

        # Pomodoro cycle
        pom|pomodoro)
            _timer_pomodoro_cycle   # 25/5/25/5/25/15
            ;;

        # Help
        help|h)
            _timer_help
            ;;

        *)
            echo "Unknown action: $1"
            timer help
            return 1
            ;;
    esac
}
```

**Usage examples:**
```bash
timer focus              # 25 min focus (default)
timer focus 45           # 45 min focus
timer deep               # 90 min deep work
timer break              # 5 min break
timer long               # 15 min long break
timer stop               # End current timer
timer pom                # Full Pomodoro cycle
```

**Removed functions:** `focus`, `unfocus`, `worktimer`, `quickbreak`, `break`, `deepwork`

**Implementation notes:**
- Merge `focus()` from 3 locations (per ZSH-OPTIMIZATION-PROPOSAL)
- Use best implementation from smart-dispatchers.zsh
- Add notification support (macOS `osascript`, Linux `notify-send`)
- Integrate with `vib` for session tracking

---

### 5. `peek` - Unified File Viewer ⭐ NEW

**Purpose:** Single command for viewing files with syntax highlighting
**Replaces:** `peekr`, `peekrd`, `peekqmd`, `peekdesc`, `peeknews`, `peeklog`

```zsh
peek() {
    # Smart detection if no type specified
    if [[ $# -eq 0 ]] || [[ ! "$1" =~ ^[a-z]+$ ]]; then
        # Auto-detect from file extension
        _peek_auto "$@"
        return
    fi

    case "$1" in
        # File types
        r|R)            shift; bat --language=r "$@" ;;
        rd|Rd)          shift; bat --language=markdown "$@" ;;
        qmd|quarto)     shift; bat --language=markdown "$@" ;;
        md|markdown)    shift; bat --language=markdown "$@" ;;

        # Special files
        desc|description)   bat ~/projects/*/DESCRIPTION ;;
        news|NEWS)          bat ~/projects/*/NEWS.md ;;
        status|STATUS)      bat .STATUS 2>/dev/null || echo "No .STATUS file" ;;
        log|workflow)       bat ~/.workflow.log ;;

        # Help
        help|h)         _peek_help ;;

        *)
            # Treat as filename
            _peek_auto "$@"
            ;;
    esac
}
```

**Usage:**
```bash
peek myfile.R            # Auto-detect and highlight
peek r myfile.R          # Explicit R syntax
peek qmd manuscript.qmd  # Explicit Quarto
peek desc                # Show DESCRIPTION file
peek status              # Show .STATUS
peek log                 # Show workflow log
```

**Removed aliases:** `peekr`, `peekrd`, `peekqmd`, `peekdesc`, `peeknews`, `peeklog`

---

### 6. `rpkg` - R Package Maintenance ⭐ NEW

**Purpose:** Package maintenance and cleanup operations
**Replaces:** `rpkgclean`, `rpkgdeep`, `rpkgcommit`, `cleantex`

```zsh
rpkg() {
    case "$1" in
        # Safe cleanup
        clean|c)
            rm -f .Rhistory .RData
            echo "✓ Removed .Rhistory and .RData"
            ;;

        # DESTRUCTIVE cleanup
        deep|d)
            echo "⚠️  WARNING: This will remove man/, NAMESPACE, docs/"
            read "?Continue? (y/N) " response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                rm -rf man/ NAMESPACE docs/
                echo "✓ Deep clean complete"
            else
                echo "Cancelled"
            fi
            ;;

        # LaTeX cleanup
        tex|latex)
            rm -f *.aux *.log *.out *.toc *.bbl *.blg
            echo "✓ Removed LaTeX build files"
            ;;

        # Doc + test + commit
        commit|save)
            Rscript -e "devtools::document()"
            Rscript -e "devtools::test()"
            git add -A
            git commit -m "${2:-Update package}"
            ;;

        # Help
        help|h)
            _rpkg_help
            ;;

        *)
            echo "Unknown action: $1"
            rpkg help
            return 1
            ;;
    esac
}
```

**Usage:**
```bash
rpkg clean               # Safe: remove .Rhistory, .RData
rpkg deep                # DESTRUCTIVE: remove man/, docs/
rpkg tex                 # Remove LaTeX files
rpkg commit "message"    # Doc → test → commit
```

**Removed aliases:** `rpkgclean`, `rpkgdeep`, `cleantex`, `rpkgcommit`

---

## 📊 Consolidation Summary

### Before (Aliases to Remove)

| Category | Aliases | Count |
|----------|---------|-------|
| Session/Energy | `startsession`, `endsession`, `gm`, `gn`, `pmorning`, `pnight`, `progress_check`, `status` | 8 |
| Pick shortcuts | `pickr`, `pickdev`, `pickq`, `pickteach`, `pickrs`, `pp`, `cdproj` | 7 |
| Focus/Timer | `focus`, `unfocus`, `worktimer`, `quickbreak`, `break`, `deepwork` | 6 |
| Peek commands | `peekr`, `peekrd`, `peekqmd`, `peekdesc`, `peeknews`, `peeklog` | 6 |
| R cleanup | `rpkgclean`, `rpkgdeep`, `rpkgcommit`, `cleantex` | 4 |
| Claude modes | `ccl`, `cch`, `ccs`, `cco`, `ccplan`, `ccauto`, `ccyolo`, `cccode` | 8 |
| Quarto | `qp`, `qr`, `qpdf`, `qhtml`, `qdocx`, `qcommit`, `qarticle`, `qpresent` | 8 |
| R workflows | `rcycle`, `rquick`, `rcheckfast`, `rdoccheck`, `lt`, `dt` | 6 |
| **TOTAL** | | **53** |

### After (New Dispatchers)

| Dispatcher | Purpose | Replaces |
|------------|---------|----------|
| `vib` | Workflow/session/energy management | 8 aliases |
| `pick` | Enhanced project navigation (refactor) | 7 aliases |
| `work` | Session starter (keep as-is) | - |
| `timer` | Focus & time management | 6 aliases |
| `peek` | Unified file viewer | 6 aliases |
| `rpkg` | R package maintenance | 4 aliases |
| `qu` | Quarto (already exists) | 8 aliases |
| `r` | R package dev (already exists) | 6 aliases |
| `cc` | Claude (enhance existing) | 8 aliases |

**Net result:** 53 aliases → 6 dispatchers (3 new, 3 enhanced)

---

## 🎓 Keyword Naming Principles

**From your existing dispatchers:**

1. **Full words preferred** - `preview` not `p`, `render` not `r`
2. **Common abbreviations OK** - `gm` (good morning), `st` (status)
3. **Multiple keywords per action** - `help|h`, `start|s`, `break|b`
4. **Intuitive mnemonics** - `deep` for deep work, `pom` for pomodoro
5. **Short + long variants** - `f` and `focus`, `b` and `break`

**Pattern:**
```zsh
# Primary (full word)
primary|short|abbrev)  action ;;

Examples:
preview|p|pv)     # preview, p, or pv all work
status|st|stat)   # status, st, or stat
```

---

## 🔧 Implementation Strategy

### Phase 1: New Dispatchers (Low Risk)

Create new dispatchers that don't conflict:

1. **`vib`** - New command, no conflicts
2. **`timer`** - New command, resolves focus() conflicts
3. **`peek`** - New command, consolidates peek*
4. **`rpkg`** - New command, consolidates rpkg*

**Actions:**
- Add to `smart-dispatchers.zsh`
- Keep old aliases temporarily (deprecated)
- Add deprecation warnings
- Update documentation

### Phase 2: Enhance Existing (Medium Risk)

Enhance existing dispatchers:

1. **`pick`** - Add keywords, keep short codes
2. **`qu`** - Already done, possibly add more
3. **`r`** - Already done, possibly clean up
4. **`cc`** - Add mode keywords if needed

**Actions:**
- Extend case statements
- Test backward compatibility
- Update help text

### Phase 3: Deprecation (Safe Removal)

After 2-4 weeks of using new dispatchers:

1. Add deprecation warnings to old aliases
2. Update all documentation
3. Remove old aliases from adhd-helpers.zsh
4. Update ALIAS-REFERENCE-CARD.md

---

## 🎯 Migration Guide for Users

### Before

```bash
# Session management
gm                           # Morning routine
startsession medfit          # Start session
endsession                   # End session
progress_check               # Check progress

# Project navigation
pickr                        # Pick R package
pickdev                      # Pick dev tool

# Focus & time
focus 25                     # 25 min focus
quickbreak 5                 # 5 min break
unfocus                      # Stop timer

# File viewing
peekr myfile.R               # View R file
peekdesc                     # View DESCRIPTION
peeklog                      # View workflow log

# R cleanup
rpkgclean                    # Clean safe files
rpkgdeep                     # Deep clean
```

### After

```bash
# Session management
vib morning                  # Morning routine (was: gm)
vib start medfit             # Start session (was: startsession)
vib end                      # End session (was: endsession)
vib progress                 # Check progress (was: progress_check)

# Project navigation
pick r                       # Pick R package (was: pickr)
pick dev                     # Pick dev tool (was: pickdev)
pick recent                  # NEW: Recently used

# Focus & time
timer focus 25               # 25 min focus (was: focus)
timer break 5                # 5 min break (was: quickbreak)
timer stop                   # Stop timer (was: unfocus)
timer pom                    # NEW: Full Pomodoro cycle

# File viewing
peek r myfile.R              # View R file (was: peekr)
peek desc                    # View DESCRIPTION (was: peekdesc)
peek log                     # View workflow log (was: peeklog)

# R cleanup
rpkg clean                   # Clean safe files (was: rpkgclean)
rpkg deep                    # Deep clean (was: rpkgdeep)
```

---

## 💡 Benefits

### For ADHD Workflow

1. **Fewer commands to remember** - 6 dispatchers vs 53 aliases
2. **Self-documenting** - `timer help` shows all options
3. **Discoverable** - Running dispatcher with no args shows help
4. **Consistent pattern** - Same structure across all dispatchers
5. **Context grouping** - Related actions grouped together

### Technical Benefits

1. **Reduced configuration size** - Less code to maintain
2. **Easier to extend** - Add keyword to case statement
3. **Better testing** - Test one dispatcher vs many aliases
4. **Clearer documentation** - One help per dispatcher
5. **Conflict resolution** - Solves focus() 3-way conflict

### Backward Compatibility

1. **Gradual migration** - Keep old aliases during transition
2. **Deprecation warnings** - Inform users of new commands
3. **Documentation updates** - Clear migration guide
4. **Training period** - 2-4 weeks before removal

---

## ⚠️ Potential Issues

### Muscle Memory

**Issue:** You're used to typing `gm`, `pickr`, `focus 25`

**Mitigation:**
- Keep old aliases for 2-4 weeks
- Add deprecation warnings that show new command
- Update to new pattern gradually

**Example warning:**
```bash
gm() {
    echo "⚠️  'gm' is deprecated. Use 'vib morning' instead."
    sleep 1
    vib morning "$@"
}
```

### Typing Length

**Issue:** `vib morning` is longer than `gm`

**Mitigation:**
- Keep short alternatives: `vib gm` also works
- Ultra-fast aliases can stay: `gm='vib morning'` if needed
- Balance between brevity and discoverability

### Learning Curve

**Issue:** Need to learn new dispatcher keywords

**Mitigation:**
- Built-in help for every dispatcher
- Examples in help output
- Gradual rollout (one dispatcher at a time)

---

## 📝 Recommendations

### Priority Order

1. **`timer`** - Solves focus() conflict (HIGH PRIORITY)
2. **`vib`** - Consolidates session/energy (HIGH VALUE)
3. **`peek`** - Low risk, high clarity
4. **`rpkg`** - R-specific, contained scope
5. **`pick`** - Enhance existing (low risk)

### Start with Timer

**Why start with `timer`?**
1. Solves immediate conflict (focus defined 3 times)
2. Clear consolidation target (6 related functions)
3. No conflicts with existing commands
4. High ADHD value (Pomodoro, deep work)

**Implementation:**
```bash
# 1. Create timer dispatcher in smart-dispatchers.zsh
# 2. Keep old functions with deprecation warnings
# 3. Use for 2 weeks
# 4. Remove old functions if working well
```

### Test Pattern

Test with `timer` first:
- If it works well → roll out `vib`, `peek`, `rpkg`
- If too cumbersome → keep some standalone aliases
- If muscle memory too hard → extend deprecation period

---

## 🎯 Next Steps

1. **Review this proposal** - Does the pattern make sense?
2. **Choose starting point** - Timer? Vib? All at once?
3. **Implement first dispatcher** - Start with `timer` or `vib`
4. **Test for 1-2 weeks** - Does it feel natural?
5. **Iterate** - Adjust keywords based on usage
6. **Roll out remaining** - Once pattern is validated

---

**Created:** 2025-12-19
**Status:** 🟡 Proposal - Awaiting Decision
**Recommended:** Start with `timer` dispatcher
**Pattern:** Follow existing `r`, `qu`, `cc`, `gm` model
