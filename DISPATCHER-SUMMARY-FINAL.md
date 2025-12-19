# Dispatcher Summary - What Actually Exists vs What's Missing

**Generated:** 2025-12-19
**Purpose:** Accurate inventory of existing dispatchers and gaps
**Finding:** Most dispatchers already exist and work!

---

## ✅ What Already Exists and Works

### 1. `r` - R Package Development (COMPLETE)

**Location:** `~/.config/zsh/functions/smart-dispatchers.zsh:50`

**Keywords:**
- Core: `load|l`, `test|t`, `doc|d`, `check|c`, `build|b`, `install|i`
- Workflows: `cycle`, `quick|q`
- Quality: `cov`, `spell`
- Docs: `pkgdown|pd`, `preview|pv`
- CRAN: `cran`, `fast`, `win`
- Version: `patch`, `minor`, `major`
- Info: `info`, `tree`

**Status:** ✅ COMPLETE - Covers all checked R aliases

---

### 2. `qu` - Quarto (COMPLETE)

**Location:** `~/.config/zsh/functions/smart-dispatchers.zsh:174`

**Keywords:**
- Core: `preview|p`, `render|r`, `check|c`, `clean`
- Project: `new|n`, `serve|s`

**Status:** ✅ COMPLETE - Covers all checked Quarto aliases

---

### 3. `vibe` / `v` - Workflow Automation (COMPLETE)

**Location:** `~/.config/zsh/functions/v-dispatcher.zsh:166`

**Keywords:**
- Testing: `test` (with watch, cov, scaffold, file, docs)
- Coordination: `coord` (sync, status, deps, release)
- Planning: `plan` (sprint, roadmap, add, backlog)
- Logging: `log` (delegates to workflow)
- Direct: `dash`, `status`, `health`

**Status:** ✅ COMPLETE - Already has comprehensive workflow management

---

### 4. `work` - Session Starter (COMPLETE)

**Location:** `~/.config/zsh/functions/work.zsh:19`

**Flags:**
- `--editor=EDITOR` or `-e`, `-c`, `-p`, `-a`, `-t`
- `--mode=MODE`

**Status:** ✅ COMPLETE - Multi-editor intent router working

---

### 5. `pick` - Project Navigation (COMPLETE)

**Location:** `~/.config/zsh/functions/adhd-helpers.zsh:1875`

**Filters:**
- `pick r` - R packages
- `pick dev` - Dev tools
- `pick q` - Quarto
- `pick teach` - Teaching
- `pick rs` - Research
- `pick app` - Applications

**Status:** ✅ WORKS - Has proposals for mgmt and recent sections

---

### 6. `gm` - Morning Routine (EXISTS)

**Location:** `~/.config/zsh/functions/smart-dispatchers.zsh`

**Status:** ✅ EXISTS

---

### 7. `cc` - Claude Code (NEED TO VERIFY)

**Location:** `~/.config/zsh/functions/smart-dispatchers.zsh:246`

**Status:** ❓ NEED TO CHECK what keywords exist

---

## ❌ What's Missing (From Your 43 Checked Items)

### Missing Dispatcher: `timer`

**Purpose:** Consolidate focus/timer/break functions
**Solves:** `focus()` conflict (defined 3 times per ZSH-OPTIMIZATION-PROPOSAL)

**Should replace:**
- `focus` → `timer focus`
- `unfocus` → `timer stop`
- `worktimer` → `timer focus <minutes>`
- `quickbreak` → `timer break`
- `deepwork` → `timer deep`
- `break` → `timer break`

**Status:** ⭐ NEEDS TO BE CREATED

---

### Missing Dispatcher: `peek`

**Purpose:** Unified file viewer
**Should replace:**
- `peekr` → `peek r`
- `peekrd` → `peek rd`
- `peekqmd` → `peek qmd`
- `peekdesc` → `peek desc`
- `peeknews` → `peek news`
- `peeklog` → `peek log`

**Status:** ⭐ NEEDS TO BE CREATED

---

### Missing Keywords in `vibe`

**Purpose:** Add session/energy management
**Should add:**
- `vibe start` (replaces startsession)
- `vibe end` (replaces endsession)
- `vibe morning` (replaces gm)
- `vibe night` (replaces gn)
- `vibe progress` (replaces progress_check)

**Status:** 🔧 ENHANCEMENT NEEDED

---

### Missing Keywords in `pick`

**Purpose:** Add management and recent sections
**Should add:**
- `pick mgmt` - Management projects (from PROPOSAL-PICK-ENHANCEMENTS.md)
- `pick recent` - Recently used (from PROPOSAL-PICK-RECENT-SECTION.md)

**Status:** 🔧 ENHANCEMENT NEEDED (proposals already exist!)

---

### Missing in `r` (Maybe?)

**Check if these exist:**
- `r clean` - Remove .Rhistory, .RData
- `r deep` - Deep clean (man/, NAMESPACE, docs/)
- `r tex` - Clean LaTeX files
- `r commit` - Doc → test → commit

**Status:** ❓ NEED TO VERIFY (likely missing, should add)

---

## 📊 Your 43 Checked Items - Status Breakdown

### ✅ Already Covered by Existing Dispatchers (27 items)

**R dispatcher covers (6):**
- `rcycle` → `r cycle` ✅
- `rquick` → `r quick` ✅
- `rcheckfast` → `r fast` ✅
- `rdoccheck` → `r doc` + `r check` ✅
- `lt` → `r load` + `r test` (or `r quick`) ✅
- `dt` → `r doc` + `r test` ✅

**Quarto dispatcher covers (8):**
- `q` / `qp` → `qu preview` or `qu p` ✅
- `qr` → `qu render` ✅
- `qpdf` → `qu render --to pdf` (may need explicit keyword)
- `qhtml` → `qu render --to html` (may need explicit keyword)
- `qdocx` → `qu render --to docx` (may need explicit keyword)
- `qcommit` → Needs checking
- `qarticle` → Needs checking
- `qpresent` → Needs checking

**Pick dispatcher covers (5):**
- `pickr` → `pick r` ✅
- `pickdev` → `pick dev` ✅
- `pickq` → `pick q` ✅
- `pickteach` → `pick teach` ✅
- `pickrs` → `pick rs` ✅

**Claude dispatcher (8 - NEED TO VERIFY):**
- `ccl`, `cch`, `ccs`, `cco`, `ccplan`, `ccauto`, `ccyolo`, `cccode`

### ⭐ Need New Dispatcher (12 items)

**Timer (6):**
- `focus`, `unfocus`, `worktimer`, `quickbreak`, `break`, `deepwork`

**Peek (6):**
- `peekr`, `peekrd`, `peekqmd`, `peekdesc`, `peeknews`, `peeklog`

### 🔧 Need Enhancement (10 items)

**Vibe enhancement (7):**
- `startsession`, `endsession`, `gm`, `gn`, `pmorning`, `pnight`, `progress_check`

**Pick enhancement (2):**
- `pp`, `cdproj` (add mgmt and recent sections)

**R enhancement (4 - IF MISSING):**
- `rpkgclean`, `rpkgdeep`, `rpkgcommit`, `cleantex`

### ❓ Need Status Check (7 items)

**Claude aliases:**
- `ccl`, `cch`, `ccs`, `cco`, `ccplan`, `ccauto`, `ccyolo`, `cccode`

---

## 🎯 Action Plan - In Priority Order

### Step 1: VERIFY (5 minutes)

Check what already exists:

```bash
# Check r cleanup keywords
r help | grep -i clean

# Check cc keywords
cc help

# Check vibe keywords
vibe help | grep -i "start\|end\|morning"
```

### Step 2: CREATE NEW (2-3 hours)

1. **`timer` dispatcher** (1.5 hours)
   - Solves focus() conflict
   - Consolidates 6 functions
   - High ADHD value

2. **`peek` dispatcher** (1 hour)
   - Simple file viewer
   - Consolidates 6 commands
   - Clean namespace

### Step 3: ENHANCE EXISTING (2-3 hours)

3. **Enhance `vibe`** (1 hour)
   - Add 5 keywords: start, end, morning, night, progress
   - Removes 7 aliases

4. **Enhance `pick`** (2 hours)
   - Implement mgmt section (PROPOSAL-PICK-ENHANCEMENTS.md)
   - Implement recent section (PROPOSAL-PICK-RECENT-SECTION.md)

5. **Enhance `r`** - IF needed (30 min)
   - Add: clean, deep, tex, commit keywords
   - Only if they don't already exist

### Step 4: REMOVE ALIASES (30 minutes)

Once dispatchers are working:
- Delete redundant aliases from adhd-helpers.zsh
- Update documentation (ALIAS-REFERENCE-CARD.md)
- Uncheck items in EXISTING-SYSTEM-SUMMARY.md

---

## 💡 Key Insights

### What You Already Built

**You have 5 working dispatchers:**
1. `r` - Complete R package development (20+ keywords)
2. `qu` - Complete Quarto (6+ keywords)
3. `vibe` / `v` - Complete workflow automation (10+ keywords)
4. `work` - Complete session starter (flag-based)
5. `pick` - Complete project navigation (filter-based)

**Pattern is proven and working!**

### What's Actually Missing

**Only 2 new dispatchers needed:**
1. `timer` - Focus/time management
2. `peek` - File viewing

**Plus enhancements to existing:**
- `vibe` - Add session/energy keywords
- `pick` - Add mgmt/recent (proposals already exist)
- `r` - Maybe add cleanup keywords (need to verify)

---

## 📝 Next Steps

**Immediate:**
1. Run verification commands (Step 1 above)
2. Report back what exists vs what's missing
3. Decide implementation order

**Then:**
1. Create `timer` dispatcher (highest priority - solves conflict)
2. Create `peek` dispatcher (simple, clean)
3. Enhance `vibe` with 5 keywords
4. Implement `pick` mgmt/recent sections

---

**Created:** 2025-12-19
**Status:** 🟢 Ready for Verification
**Next:** Check what keywords `r`, `cc`, `vibe` already have
**Recommendation:** Create `timer` first (solves focus() conflict)
