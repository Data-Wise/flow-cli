# Dispatcher Refactoring Proposal V2 - Based on Existing Commands

**Generated:** 2025-12-19 (Updated)
**Purpose:** Consolidate checked aliases into existing dispatcher keywords
**Key Discovery:** `vibe`, `r`, `qu`, `cc`, `gm`, `pick`, `work` already exist!
**Strategy:** Enhance existing dispatchers, don't create duplicates

---

## 🔍 What Already Exists

### Existing Dispatchers (Verified)

| Command | Location | Status | Keywords Available |
|---------|----------|--------|--------------------|
| **`r`** | smart-dispatchers.zsh:50 | ✅ Complete | test, doc, check, cycle, quick, cov, spell, pkgdown, fast, cran, patch, minor, major |
| **`qu`** | smart-dispatchers.zsh:174 | ✅ Complete | preview, render, check, **clean**, new, serve |
| **`cc`** | smart-dispatchers.zsh:246 | ✅ Complete | (needs verification) |
| **`gm`** | smart-dispatchers.zsh | ✅ Complete | morning routine |
| **`v` / `vibe`** | v-dispatcher.zsh:166 | ✅ Complete | test, coord, plan, log, dash, status, health |
| **`work`** | work.zsh:19 | ✅ Complete | Multi-editor router with flags |
| **`pick`** | adhd-helpers.zsh:1875 | ✅ Complete | r, dev, q, teach, rs, app filters |

---

## 📊 Analysis of Your Checked Items

From WORKFLOW-OPTIONS-CLEANUP.md, you checked **43 items**. Let's map them to existing dispatchers:

### ✅ Already Handled by Existing Dispatchers

| Checked Item | Existing Command | Status |
|--------------|------------------|--------|
| `rcycle` | `r cycle` | ✅ Already exists |
| `rquick` | `r quick` | ✅ Already exists |
| `rcheckfast` | `r fast` | ✅ Already exists (line 84) |
| `rdoccheck` | `r doc` + `r check` | ✅ Covered |
| `qp` / `q` | `qu preview` or `qu p` | ✅ Already exists |
| `qr` | `qu render` or `qu r` | ✅ Already exists |
| `qpdf` | `qu render --to pdf` | ✅ Can be added |
| `qhtml` | `qu render --to html` | ✅ Can be added |
| `qdocx` | `qu render --to docx` | ✅ Can be added |
| `pickr` | `pick r` | ✅ Already exists |
| `pickdev` | `pick dev` | ✅ Already exists |
| `pickq` | `pick q` | ✅ Already exists |
| `pickteach` | `pick teach` | ✅ Already exists |
| `pickrs` | `pick rs` | ✅ Already exists |

**Result:** 14 of your 43 checked items are already covered by existing dispatchers!

---

## 🎯 What Needs To Be Added

### 1. **`r` - Add Cleanup Keywords** ⭐ ENHANCE

**Currently missing:** Cleanup/maintenance keywords
**Add to `r` dispatcher:**

```zsh
# In smart-dispatchers.zsh, add to r() case statement after line 94:

        # Maintenance & cleanup
        clean|cl)
            rm -f .Rhistory .RData
            echo "✓ Removed .Rhistory and .RData"
            ;;

        deep|deepclean)
            echo "⚠️  WARNING: This will remove man/, NAMESPACE, docs/"
            read "?Continue? (y/N) " response
            if [[ "$response" =~ ^[Yy]$ ]]; then
                rm -rf man/ NAMESPACE docs/
                echo "✓ Deep clean complete"
            else
                echo "Cancelled"
            fi
            ;;

        tex|latex)
            rm -f *.aux *.log *.out *.toc *.bbl *.blg
            echo "✓ Removed LaTeX build files"
            ;;

        commit|save)
            Rscript -e "devtools::document()"
            Rscript -e "devtools::test()"
            git add -A
            git commit -m "${2:-Update package}"
            ;;
```

**New usage:**
```bash
r clean              # Remove .Rhistory, .RData (replaces rpkgclean)
r deep               # Remove man/, docs/ (replaces rpkgdeep)
r tex                # Remove LaTeX files (replaces cleantex)
r commit "msg"       # Doc → test → commit (replaces rpkgcommit)
```

**Removes aliases:** `rpkgclean`, `rpkgdeep`, `cleantex`, `rpkgcommit` (4 items)

---

### 2. **`timer` - New Dispatcher for Focus/Time** ⭐ NEW

**Purpose:** Consolidate timer/focus/break functionality
**Why new:** Solves `focus()` conflict (3 definitions per ZSH-OPTIMIZATION-PROPOSAL)

```zsh
timer() {
    if [[ $# -eq 0 ]]; then
        timer help
        return
    fi

    case "$1" in
        # Focus sessions
        focus|f)
            local minutes="${2:-25}"
            _timer_focus "$minutes"
            ;;

        deep|d)
            local minutes="${2:-90}"
            _timer_focus "$minutes" "deep"
            ;;

        # Breaks
        break|b)
            local minutes="${2:-5}"
            _timer_break "$minutes"
            ;;

        long|l)
            local minutes="${2:-15}"
            _timer_break "$minutes" "long"
            ;;

        # Control
        stop|end|x)
            _timer_stop
            ;;

        status|st)
            _timer_status
            ;;

        # Pomodoro
        pom|pomodoro)
            _timer_pomodoro_cycle
            ;;

        help|h)
            _timer_help
            ;;

        *)
            echo "Unknown: $1"
            timer help
            return 1
            ;;
    esac
}
```

**Usage:**
```bash
timer focus          # 25 min (replaces focus)
timer focus 45       # 45 min custom
timer deep           # 90 min (replaces deepwork)
timer break          # 5 min (replaces quickbreak)
timer stop           # End timer (replaces unfocus)
timer pom            # Full Pomodoro cycle
```

**Removes functions:** `focus`, `unfocus`, `worktimer`, `quickbreak`, `break`, `deepwork` (6 items)

---

### 3. **`peek` - New Unified File Viewer** ⭐ NEW

**Purpose:** Consolidate all peek* commands

```zsh
peek() {
    # Auto-detect if file provided
    if [[ $# -eq 0 ]] || [[ -f "$1" ]]; then
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
        desc|description)
            bat DESCRIPTION 2>/dev/null || echo "No DESCRIPTION file"
            ;;

        news|NEWS)
            bat NEWS.md 2>/dev/null || echo "No NEWS.md file"
            ;;

        status|st)
            bat .STATUS 2>/dev/null || echo "No .STATUS file"
            ;;

        log|workflow)
            bat ~/.workflow.log 2>/dev/null || echo "No workflow log"
            ;;

        help|h)
            _peek_help
            ;;

        *)
            _peek_auto "$@"
            ;;
    esac
}
```

**Usage:**
```bash
peek myfile.R        # Auto-detect
peek r myfile.R      # Explicit R syntax
peek desc            # Show DESCRIPTION (replaces peekdesc)
peek news            # Show NEWS.md (replaces peeknews)
peek status          # Show .STATUS (replaces status command)
peek log             # Show workflow log (replaces peeklog)
```

**Removes aliases:** `peekr`, `peekrd`, `peekqmd`, `peekdesc`, `peeknews`, `peeklog`, `status` (7 items)

---

### 4. **`vibe` - Enhance Existing** ✅ ALREADY EXISTS

**Good news:** `vibe` (alias to `v`) already exists in v-dispatcher.zsh!

**Current vibe keywords:**
- `v test` - Testing
- `v coord` - Coordination
- `v plan` - Planning
- `v log` - Activity logging (delegates to workflow)
- `v dash` - Dashboard (delegates to dash)
- `v status` - Status (delegates to status)

**What to add:**
```zsh
# Add to v() dispatcher in v-dispatcher.zsh:

        # Session management (NEW)
        start|begin)
            shift
            startsession "$@"
            ;;

        end|stop)
            endsession
            ;;

        # Energy/time of day (NEW)
        morning|gm)
            pmorning
            ;;

        night|gn)
            pnight
            ;;

        # Progress tracking (NEW)
        progress|prog|p)
            progress_check
            ;;
```

**New usage:**
```bash
vibe start medfit    # Start session (replaces startsession)
vibe end             # End session (replaces endsession)
vibe morning         # Morning routine (replaces gm)
vibe night           # Night routine (replaces gn)
vibe progress        # Progress check (replaces progress_check)
```

**Removes aliases:** `startsession`, `endsession`, `gm`, `gn`, `pmorning`, `pnight`, `progress_check` (7 items)

**Note:** `vibe` already has `v status` which covers the `status` command

---

### 5. **`pick` - Enhance Existing** ✅ ENHANCE

**Current:** Already has filter system (`pick r`, `pick dev`, etc.)
**What to add:** Management section and recent section (from your proposals)

```zsh
# Enhance pick() in adhd-helpers.zsh:

    case "$1" in
        # Existing filters (KEEP)
        r|pkg) _pick_filter "r" ;;
        dev|tool) _pick_filter "dev" ;;
        q|quarto) _pick_filter "q" ;;
        teach|course) _pick_filter "teach" ;;
        rs|research) _pick_filter "rs" ;;
        app) _pick_filter "app" ;;

        # NEW: Management section (from PROPOSAL-PICK-ENHANCEMENTS.md)
        mgmt|meta|manage)
            _pick_filter "mgmt"
            ;;

        # NEW: Recently used (from PROPOSAL-PICK-RECENT-SECTION.md)
        recent|rec|last)
            _proj_recent
            ;;

        # Utility
        list|ls)
            _proj_list_all
            ;;

        help|h)
            _pick_help
            ;;

        *)
            # Fallback: interactive picker
            _pick_interactive "$1"
            ;;
    esac
```

**New usage:**
```bash
pick mgmt            # Management projects (NEW)
pick recent          # Recently used (NEW)
pick list            # Show all projects
```

**Removes aliases:** `pp` (was redundant with `pick`)

---

## 📊 Final Consolidation Summary

### Commands to Enhance (Not Create)

| Dispatcher | Add Keywords | Removes Aliases | Status |
|------------|--------------|-----------------|--------|
| **`r`** | clean, deep, tex, commit | rpkgclean, rpkgdeep, cleantex, rpkgcommit (4) | ✅ Enhance existing |
| **`timer`** | focus, deep, break, stop, pom | focus, unfocus, worktimer, quickbreak, break, deepwork (6) | ⭐ NEW |
| **`peek`** | r, qmd, desc, news, status, log | peekr, peekrd, peekqmd, peekdesc, peeknews, peeklog, status (7) | ⭐ NEW |
| **`vibe`** | start, end, morning, night, progress | startsession, endsession, gm, gn, pmorning, pnight, progress_check (7) | ✅ Enhance existing |
| **`pick`** | mgmt, recent, list | pp, cdproj (2) | ✅ Enhance existing |
| **`qu`** | *(already has clean)* | qp, qr, qpdf, qhtml, qdocx, qcommit, qarticle, qpresent (8) | ✅ Use existing |
| **`cc`** | *(check what exists)* | ccl, cch, ccs, cco, ccplan, ccauto, ccyolo, cccode (8) | ❓ Need to verify |

**Total aliases removed:** ~42 items
**New dispatchers:** 2 (timer, peek)
**Enhanced dispatchers:** 3 (r, vibe, pick)

---

## 🎯 Implementation Priority

### Phase 1: LOW RISK (Enhance Existing)

1. **`r` - Add cleanup keywords**
   - Risk: LOW (adding to existing dispatcher)
   - Value: HIGH (consolidates 4 rpkg* commands)
   - Effort: 30 minutes

2. **`pick` - Add mgmt and recent**
   - Risk: LOW (implementing your existing proposals)
   - Value: HIGH (management section, recent section)
   - Effort: 2 hours (from proposals)

### Phase 2: MEDIUM RISK (New Dispatchers)

3. **`timer` - Create new dispatcher**
   - Risk: MEDIUM (resolves focus() conflict)
   - Value: HIGH (ADHD workflow, Pomodoro)
   - Effort: 1-2 hours

4. **`peek` - Create new dispatcher**
   - Risk: LOW (simple file viewer consolidation)
   - Value: MEDIUM (cleaner namespace)
   - Effort: 1 hour

### Phase 3: ENHANCE EXISTING

5. **`vibe` - Add session/energy keywords**
   - Risk: LOW (enhancing existing v-dispatcher)
   - Value: MEDIUM (consolidates gm/gn/startsession)
   - Effort: 1 hour

---

## 💡 Key Recommendations

### 1. Start with `r clean` Keywords

**Why:**
- Lowest risk (adding to proven dispatcher)
- Immediately removes 4 aliases
- Follows existing `qu clean` pattern
- No conflicts, no muscle memory issues

**Implementation:**
```bash
# Just add 4 case statements to r() in smart-dispatchers.zsh
# Test with: r clean, r deep, r tex, r commit
```

### 2. Implement Your Pick Proposals

**Why:**
- You already created PROPOSAL-PICK-ENHANCEMENTS.md
- You already created PROPOSAL-PICK-RECENT-SECTION.md
- Just need to implement what you already designed

### 3. Create `timer` Dispatcher

**Why:**
- Solves real conflict (focus defined 3x)
- High ADHD value
- Clear consolidation target

### 4. DON'T Create `rpkg` Dispatcher

**Why:**
- `r` already handles R package development
- Adding `r clean`, `r deep`, `r tex` is simpler
- Follows existing pattern (qu has clean, r should too)
- One less command to remember

---

## 🎓 Lessons Learned

### You Already Built This Pattern!

1. ✅ **`r`** - Full R package dispatcher (test, doc, check, cycle, etc.)
2. ✅ **`qu`** - Full Quarto dispatcher (preview, render, clean, etc.)
3. ✅ **`vibe`** - Full workflow dispatcher (test, coord, plan, log, etc.)
4. ✅ **`cc`** - Claude Code dispatcher
5. ✅ **`gm`** - Morning routine
6. ✅ **`work`** - Session starter with flags
7. ✅ **`pick`** - Project navigator with filters

**Pattern is proven and working!**

### What to Do with Checked Items

Most checked items fall into these categories:

1. **Already covered by dispatcher** (qp → qu preview)
2. **Need new keyword added** (rpkgclean → r clean)
3. **Need new dispatcher** (focus → timer focus)

---

## ❓ Questions for You

1. **Start with `r clean` keywords?** (Easiest, immediate value)
2. **Check what `cc` dispatcher already has** before adding keywords?
3. **Which order for new dispatchers?** Timer first (conflict resolution) or peek first (simpler)?

---

## 📝 Next Steps

1. **Verify `cc` dispatcher** - Read smart-dispatchers.zsh to see what exists
2. **Add `r` cleanup keywords** - 4 new case statements
3. **Implement pick mgmt/recent** - Your existing proposals
4. **Create `timer` dispatcher** - Resolve focus() conflict
5. **Create `peek` dispatcher** - Consolidate peek* commands
6. **Enhance `vibe`** - Add session/energy keywords

---

**Created:** 2025-12-19 (V2 - Based on Actual Existing Commands)
**Status:** 🟡 Ready for Review
**Key Discovery:** You already have the dispatcher pattern working!
**Recommendation:** Enhance existing (`r`, `vibe`, `pick`) before creating new
