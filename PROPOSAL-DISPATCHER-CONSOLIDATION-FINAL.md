# Dispatcher Consolidation - Final Proposal

**Generated:** 2025-12-19
**Purpose:** Consolidate 43 checked aliases into dispatcher keywords with full checklist
**Includes:** Standards file updates, script refactoring, file location management

---

## 📋 Executive Summary

**Current State:**

- 43 aliases marked for removal/consolidation
- 5 working dispatchers (`r`, `qu`, `vibe`, `work`, `pick`)
- Multiple script files need organization

**Proposed State:**

- Remove 43 redundant aliases
- Add 2 new dispatchers (`timer`, `peek`)
- Enhance 3 existing dispatchers (`vibe`, `pick`, `r`)
- Reorganize script files
- Update standards documentation

**Net Result:**

- 43 aliases removed
- 2 new commands created
- ~15 keywords added to existing dispatchers
- Cleaner file organization
- Updated documentation standards

---

## ✅ Part 1: Existing Dispatcher Audit

### 1.1 `r` Dispatcher - R Package Development

**Location:** `~/.config/zsh/functions/smart-dispatchers.zsh:50`

**Existing Keywords (Check if working):**

- [ ] `r` (no args) - Launch R console ✅ EXISTS
- [ ] `r load` / `r l` - Load package ✅ EXISTS
- [ ] `r test` / `r t` - Run tests ✅ EXISTS
- [ ] `r doc` / `r d` - Generate docs ✅ EXISTS
- [ ] `r check` / `r c` - R CMD check ✅ EXISTS
- [ ] `r build` / `r b` - Build package ✅ EXISTS
- [ ] `r install` / `r i` - Install package ✅ EXISTS
- [ ] `r cycle` - Full cycle (doc → test → check) ✅ EXISTS
- [ ] `r quick` / `r q` - Quick (load → test) ✅ EXISTS
- [ ] `r cov` - Coverage report ✅ EXISTS
- [ ] `r spell` - Spell check ✅ EXISTS
- [ ] `r pkgdown` / `r pd` - Build pkgdown site ✅ EXISTS
- [ ] `r preview` / `r pv` - Preview pkgdown ✅ EXISTS
- [ ] `r cran` - CRAN check ✅ EXISTS
- [ ] `r fast` - Fast check (skip examples/tests) ✅ EXISTS
- [ ] `r win` - Windows dev check ✅ EXISTS
- [ ] `r patch` - Bump patch version ✅ EXISTS
- [ ] `r minor` - Bump minor version ✅ EXISTS
- [ ] `r major` - Bump major version ✅ EXISTS
- [ ] `r info` - Package info ✅ EXISTS
- [ ] `r tree` - Package structure tree ✅ EXISTS
- [ ] `r help` / `r h` - Show help ✅ EXISTS

**NEW Keywords to Add:**

- [ ] `r clean` / `r cl` - Remove .Rhistory, .RData ⭐ ADD
- [ ] `r deep` - Deep clean (man/, NAMESPACE, docs/) ⚠️ DESTRUCTIVE ⭐ ADD
- [ ] `r tex` - Clean LaTeX files ⭐ ADD
- [ ] `r commit` / `r save` - Doc → test → commit ⭐ ADD

**Aliases This Replaces:**

- [X] `rcycle` → `r cycle` ✅ COVERED
- [X] `rquick` → `r quick` ✅ COVERED
- [X] `rcheckfast` → `r fast` ✅ COVERED
- [X] `rdoccheck` → `r doc` + `r check` ✅ COVERED
- [X] `lt` → `r quick` (or `r load` + `r test`) ✅ COVERED
- [X] `dt` → `r doc` + `r test` ✅ COVERED
- [X] `rpkgclean` → `r clean` ⭐ NEW
- [X] `rpkgdeep` → `r deep` ⭐ NEW
- [X] `cleantex` → `r tex` ⭐ NEW
- [X] `rpkgcommit` → `r commit` ⭐ NEW

---

### 1.2 `qu` Dispatcher - Quarto

**Location:** `~/.config/zsh/functions/smart-dispatchers.zsh:174`

**Existing Keywords (Check if working):**

- [ ] `qu` (no args) - Show help ✅ EXISTS
- [ ] `qu preview` / `qu p` - Live preview ✅ EXISTS
- [ ] `qu render` / `qu r` - Render document ✅ EXISTS
- [ ] `qu check` / `qu c` - Check installation ✅ EXISTS
- [ ] `qu clean` - Remove generated files ✅ EXISTS
- [ ] `qu new` / `qu n` - Create new project ✅ EXISTS
- [ ] `qu serve` / `qu s` - Serve project ✅ EXISTS
- [ ] `qu help` / `qu h` - Show help ✅ EXISTS

**NEW Keywords to Add:**

- [ ] `qu pdf` - Render to PDF ⭐ ADD
- [ ] `qu html` - Render to HTML ⭐ ADD
- [ ] `qu docx` - Render to DOCX ⭐ ADD
- [ ] `qu commit` - Quick commit for Quarto ⭐ ADD
- [ ] `qu article` - Create article template ⭐ ADD
- [ ] `qu present` - Create presentation template ⭐ ADD

**Aliases This Replaces:**

- [X] `q` / `qp` → `qu preview` or `qu p` ✅ COVERED
- [X] `qr` → `qu render` ✅ COVERED
- [X] `qpdf` → `qu pdf` ⭐ NEW
- [X] `qhtml` → `qu html` ⭐ NEW
- [X] `qdocx` → `qu docx` ⭐ NEW
- [X] `qcommit` → `qu commit` ⭐ NEW
- [X] `qarticle` → `qu article` ⭐ NEW
- [X] `qpresent` → `qu present` ⭐ NEW

---

### 1.3 `vibe` / `v` Dispatcher - Workflow Automation

**Location:** `~/.config/zsh/functions/v-dispatcher.zsh:166`

**Existing Keywords (Check if working):**

- [ ] `v test` - Run tests (auto-detect) ✅ EXISTS
- [ ] `v test watch` - Watch mode ✅ EXISTS
- [ ] `v test cov` - Coverage ✅ EXISTS
- [ ] `v test scaffold` - Generate test template ✅ EXISTS
- [ ] `v test file` - Run specific test ✅ EXISTS
- [ ] `v test docs` - Generate test docs ✅ EXISTS
- [ ] `v coord` - Show ecosystems ✅ EXISTS
- [ ] `v coord sync` - Sync ecosystem ✅ EXISTS
- [ ] `v coord status` - Ecosystem dashboard ✅ EXISTS
- [ ] `v coord deps` - Dependency graph ✅ EXISTS
- [ ] `v coord release` - Coordinate release ✅ EXISTS
- [ ] `v plan` - Current sprint ✅ EXISTS
- [ ] `v plan sprint` - Sprint management ✅ EXISTS
- [ ] `v plan roadmap` - View roadmap ✅ EXISTS
- [ ] `v plan add` - Add task ✅ EXISTS
- [ ] `v plan backlog` - View backlog ✅ EXISTS
- [ ] `v log` - Recent activity (→ workflow) ✅ EXISTS
- [ ] `v log today` - Today's log ✅ EXISTS
- [ ] `v log started` - Log session start ✅ EXISTS
- [ ] `v dash` - Dashboard (→ dash) ✅ EXISTS
- [ ] `v status` - Project status ✅ EXISTS
- [ ] `v health` - Combined health check ✅ EXISTS
- [ ] `vibe` - Full name alias to `v` ✅ EXISTS

**NEW Keywords to Add:**

- [ ] `v start` / `v begin` - Start session ⭐ ADD
- [ ] `v end` / `v stop` - End session ⭐ ADD
- [ ] `v morning` / `v gm` - Morning routine ⭐ ADD
- [ ] `v night` / `v gn` - Night routine ⭐ ADD
- [ ] `v progress` / `v prog` / `v p` - Progress check ⭐ ADD

**Aliases This Replaces:**

- [X] `startsession` → `v start` or `vibe start` ⭐ NEW
- [X] `endsession` → `v end` or `vibe end` ⭐ NEW
- [X] `gm` / `pmorning` → `v morning` or `vibe morning` ⭐ NEW
- [X] `gn` / `pnight` → `v night` or `vibe night` ⭐ NEW
- [X] `progress_check` → `v progress` or `vibe progress` ⭐ NEW
- [X] `status` → `v status` ✅ COVERED

---

### 1.4 `work` Dispatcher - Session Starter

**Location:** `~/.config/zsh/functions/work.zsh:19`

**Existing Functionality (Check if working):**

- [ ] `work <project>` - Auto-detect editor ✅ EXISTS
- [ ] `work <project> --editor=EDITOR` - Specify editor ✅ EXISTS
- [ ] `work <project> --mode=MODE` - Specify mode ✅ EXISTS
- [ ] `work <project> -e` / `--emacs` - Force Emacs ✅ EXISTS
- [ ] `work <project> -c` / `--code` - Force VS Code ✅ EXISTS
- [ ] `work <project> -p` / `--positron` - Force Positron ✅ EXISTS
- [ ] `work <project> -a` / `--ai` / `--claude` - Force Claude ✅ EXISTS
- [ ] `work <project> -t` / `--terminal` - Force terminal ✅ EXISTS
- [ ] `work --help` / `work -h` - Show help ✅ EXISTS

**Status:** ✅ COMPLETE - No changes needed

---

### 1.5 `pick` Dispatcher - Project Navigation

**Location:** `~/.config/zsh/functions/adhd-helpers.zsh:1875`

**Existing Functionality (Check if working):**

- [ ] `pick` (no args) - Interactive fzf picker ✅ EXISTS
- [ ] `pick r` - Filter R packages ✅ EXISTS
- [ ] `pick dev` - Filter dev tools ✅ EXISTS
- [ ] `pick q` - Filter Quarto projects ✅ EXISTS
- [ ] `pick teach` - Filter teaching courses ✅ EXISTS
- [ ] `pick rs` - Filter research projects ✅ EXISTS
- [ ] `pick app` - Filter applications ✅ EXISTS

**Existing fzf Keybinds:**

- [ ] **Enter** - Navigate to directory ✅ EXISTS
- [X] **Ctrl-W** - Start work session ✅ EXISTS
- [X] **Ctrl-O** - Open in VS Code ✅ EXISTS
- [ ] **Ctrl-S** - View .STATUS file ✅ EXISTS
- [ ] **Ctrl-L** - View git log ✅ EXISTS

**NEW Keywords to Add:**

- [ ] `pick mgmt` / `pick meta` / `pick manage` - Management projects ⭐ ADD
- [ ] `pick recent` / `pick rec` / `pick last` - Recently used ⭐ ADD
- [ ] `pick list` / `pick ls` - Show all projects ⭐ ADD
- [ ] `pick tree` - Project tree view ⭐ ADD
- [ ] `pick help` / `pick h` - Show help ⭐ ADD

**Aliases This Replaces:**

- [X] `pickr` → `pick r` ✅ COVERED
- [X] `pickdev` → `pick dev` ✅ COVERED
- [X] `pickq` → `pick q` ✅ COVERED
- [X] `pickteach` → `pick teach` ✅ COVERED
- [X] `pickrs` → `pick rs` ✅ COVERED
- [X] `pp` → `pick` ✅ COVERED
- [X] `cdproj` → `pick` ✅ COVERED

---

### 1.6 `gm` Dispatcher - Morning Routine

**Location:** `~/.config/zsh/functions/smart-dispatchers.zsh`

**Existing Functionality (Check if working):**

- [X] `gm` - Morning routine ✅ EXISTS

**Status:** ✅ COMPLETE - Will be aliased to `vibe morning` for consistency

---

### 1.7 `cc` Dispatcher - Claude Code

**Location:** `~/.config/zsh/functions/smart-dispatchers.zsh:246`

**Existing Keywords (NEED TO VERIFY):**

- [ ] `cc` (no args) - Interactive mode ❓ VERIFY
- [ ] `cc help` / `cc h` - Show help ❓ VERIFY

**NEW Keywords to Check/Add:**

- [ ] `cc continue` / `cc c` - Continue last conversation ❓ CHECK
- [X] `cc latest` / `cc l` - Resume latest session ❓ CHECK
- [X] `cc haiku` / `cc h` - Use Haiku model ❓ CHECK
- [X] `cc sonnet` / `cc s` - Use Sonnet model ❓ CHECK
- [X] `cc opus` / `cc o` - Use Opus model ❓ CHECK
- [ ] `cc plan` - Planning mode ❓ CHECK
- [ ] `cc auto` - Auto mode ❓ CHECK
- [ ] `cc yolo` - YOLO mode ❓ CHECK
- [X] `cc code` - Code mode ❓ CHECK

**Aliases to Replace (IF keywords don't exist):**

- [X] `ccl` → `cc latest` ⭐ ADD IF NEEDED
- [X] `cch` → `cc haiku` ⭐ ADD IF NEEDED
- [X] `ccs` → `cc sonnet` ⭐ ADD IF NEEDED
- [X] `cco` → `cc opus` ⭐ ADD IF NEEDED
- [X] `ccplan` → `cc plan` ⭐ ADD IF NEEDED
- [X] `ccauto` → `cc auto` ⭐ ADD IF NEEDED
- [X] `ccyolo` → `cc yolo` ⭐ ADD IF NEEDED
- [X] `cccode` → `cc code` ⭐ ADD IF NEEDED

---

## ⭐ Part 2: New Dispatchers to Create

### 2.1 `timer` Dispatcher - Focus & Time Management

**Purpose:** Consolidate all timer/focus/break functionality
**Solves:** `focus()` conflict (defined 3 times per ZSH-OPTIMIZATION-PROPOSAL)
**Location:** `~/.config/zsh/functions/smart-dispatchers.zsh` (add after gm)

**Keywords to Implement:**

- [ ] `timer` (no args) - Show help ⭐ NEW
- [ ] `timer focus` / `timer f` - Focus session (default 25 min) ⭐ NEW
- [ ] `timer deep` / `timer d` - Deep work (default 90 min) ⭐ NEW
- [ ] `timer break` / `timer b` - Short break (default 5 min) ⭐ NEW
- [ ] `timer long` / `timer l` - Long break (default 15 min) ⭐ NEW
- [ ] `timer stop` / `timer end` / `timer x` - Stop current timer ⭐ NEW
- [ ] `timer status` / `timer st` - Show timer status ⭐ NEW
- [ ] `timer pom` / `timer pomodoro` - Full Pomodoro cycle ⭐ NEW
- [ ] `timer help` / `timer h` - Show help ⭐ NEW

**Functions This Replaces:**

- [X] `focus` → `timer focus` ⭐ REMOVE
- [X] `unfocus` → `timer stop` ⭐ REMOVE
- [X] `worktimer` → `timer focus <minutes>` ⭐ REMOVE
- [X] `quickbreak` → `timer break` ⭐ REMOVE
- [X] `break` → `timer break` ⭐ REMOVE
- [X] `deepwork` → `timer deep` ⭐ REMOVE

**Implementation Checklist:**

- [ ] Create `timer()` function in smart-dispatchers.zsh
- [ ] Create `_timer_focus()` helper function
- [ ] Create `_timer_break()` helper function
- [ ] Create `_timer_stop()` helper function
- [ ] Create `_timer_status()` helper function
- [ ] Create `_timer_pomodoro_cycle()` helper function
- [ ] Create `_timer_help()` helper function
- [ ] Add macOS notification support (osascript)
- [ ] Add Linux notification support (notify-send) - optional
- [ ] Remove old `focus()` from adhd-helpers.zsh
- [ ] Remove old `focus()` from functions.zsh
- [ ] Remove old `focus()` from smart-dispatchers.zsh (if exists)
- [ ] Test all timer commands
- [ ] Update help documentation

---

### 2.2 `peek` Dispatcher - Unified File Viewer

**Purpose:** Consolidate all peek* file viewing commands
**Location:** `~/.config/zsh/functions/smart-dispatchers.zsh` (add after timer)

**Keywords to Implement:**

- [ ] `peek <file>` - Auto-detect and view file ⭐ NEW
- [ ] `peek r <file>` - View R file with syntax ⭐ NEW
- [ ] `peek rd <file>` - View .Rd file ⭐ NEW
- [ ] `peek qu <file>` - View Quarto file ⭐ NEW
- [ ] `peek md <file>` - View markdown file ⭐ NEW
- [ ] `peek desc` - View DESCRIPTION file ⭐ NEW
- [ ] `peek news` - View NEWS.md file ⭐ NEW
- [ ] `peek status` / `peek st` - View .STATUS file ⭐ NEW
- [ ] `peek log` - View workflow log ⭐ NEW
- [ ] `peek help` / `peek h` - Show help ⭐ NEW

**Aliases This Replaces:**

- [X] `peekr` → `peek r` ⭐ REMOVE
- [X] `peekrd` → `peek rd` ⭐ REMOVE
- [X] `peekqmd` → `peek qu` ⭐ REMOVE
- [X] `peekdesc` → `peek desc` ⭐ REMOVE
- [X] `peeknews` → `peek news` ⭐ REMOVE
- [X] `peeklog` → `peek log` ⭐ REMOVE

**Implementation Checklist:**

- [ ] Create `peek()` function in smart-dispatchers.zsh
- [ ] Create `_peek_auto()` helper for auto-detection
- [ ] Create `_peek_help()` helper function
- [ ] Add dependency check for `bat` command
- [ ] Add fallback to `cat` if bat not available
- [ ] Remove old peek* aliases from adhd-helpers.zsh
- [ ] Test all peek commands
- [ ] Update help documentation

---

## 📂 Part 3: File Organization & Refactoring

### 3.1 Current Script Locations

**Dispatcher Scripts:**

- [ ] `~/.config/zsh/functions/smart-dispatchers.zsh` - r, qu, cc, gm ✅ EXISTS
- [ ] `~/.config/zsh/functions/v-dispatcher.zsh` - v/vibe ✅ EXISTS
- [ ] `~/.config/zsh/functions/g-dispatcher.zsh` - git dispatcher ✅ EXISTS
- [ ] `~/.config/zsh/functions/mcp-dispatcher.zsh` - MCP dispatcher ✅ EXISTS
- [ ] `~/.config/zsh/functions/work.zsh` - work command ✅ EXISTS

**Other Function Files:**

- [ ] `~/.config/zsh/functions/adhd-helpers.zsh` - Main helpers (3034 lines) ✅ EXISTS
- [ ] `~/.config/zsh/functions/functions.zsh` - Legacy functions ✅ EXISTS
- [ ] `~/.config/zsh/functions/dash.zsh` - Dashboard ✅ EXISTS
- [ ] `~/.config/zsh/functions/fzf-helpers.zsh` - FZF utilities ✅ EXISTS
- [ ] `~/.config/zsh/functions/core-utils.zsh` - Core utilities ✅ EXISTS
- [ ] `~/.config/zsh/functions/bg-agents.zsh` - Background agents ✅ EXISTS
- [ ] `~/.config/zsh/functions/claude-workflows.zsh` - Claude workflows ✅ EXISTS
- [ ] `~/.config/zsh/functions/claude-response-viewer.zsh` - Response viewer ✅ EXISTS
- [ ] `~/.config/zsh/functions/genpass.zsh` - Password generator ✅ EXISTS

### 3.2 Proposed Reorganization

**Consolidate Dispatchers:**

- [ ] Merge all dispatchers into single file: `~/.config/zsh/functions/dispatchers.zsh` ⭐ REFACTOR
  - [ ] Move `r()` from smart-dispatchers.zsh
  - [ ] Move `qu()` from smart-dispatchers.zsh
  - [ ] Move `cc()` from smart-dispatchers.zsh
  - [ ] Move `gm()` from smart-dispatchers.zsh
  - [ ] Move `v()` / `vibe()` from v-dispatcher.zsh
  - [ ] Move `g()` from g-dispatcher.zsh (if exists)
  - [ ] Move `mcp()` from mcp-dispatcher.zsh
  - [ ] Add new `timer()` dispatcher
  - [ ] Add new `peek()` dispatcher
  - [ ] Keep helper functions in separate files if large

**OR Keep Separate (Alternative):**

- [ ] Keep `smart-dispatchers.zsh` for r, qu, cc, gm, timer, peek ⭐ ALTERNATIVE
- [ ] Keep `v-dispatcher.zsh` for v/vibe (already large)
- [ ] Keep `g-dispatcher.zsh` for git
- [ ] Keep `mcp-dispatcher.zsh` for MCP
- [ ] Rename files to follow pattern: `{name}-dispatcher.zsh`

**Refactor adhd-helpers.zsh:**

- [ ] Extract pick() to `pick-dispatcher.zsh` or `project-picker.zsh` ⭐ REFACTOR
- [ ] Extract work() to `work-dispatcher.zsh` (already separate as work.zsh) ✅ DONE
- [ ] Remove redundant aliases after dispatcher migration
- [ ] Split into logical modules:
  - [ ] `session-management.zsh` - startsession, endsession, etc.
  - [ ] `energy-helpers.zsh` - gm, gn, win, why, js, stuck
  - [ ] `project-detection.zsh` - _proj_detect_type, etc.
  - [ ] `adhd-core.zsh` - Core ADHD helper functions

### 3.3 File Location Standards

**Create Standards Document:**

- [ ] Create `~/.config/zsh/STANDARDS.md` ⭐ NEW
  - [ ] Document file naming conventions
  - [ ] Document function naming conventions
  - [ ] Document dispatcher pattern
  - [ ] Document helper function pattern
  - [ ] Document where to add new commands

**Document Current Organization:**

- [ ] Update `~/projects/dev-tools/zsh-configuration/CLAUDE.md` with:
  - [ ] List of all dispatcher files
  - [ ] List of all function files
  - [ ] Explanation of file organization
  - [ ] How to add new dispatchers
  - [ ] How to add new keywords to existing dispatchers

---

## 📚 Part 4: Documentation Updates

### 4.1 Update Standard Documents

**zsh-configuration Repository:**

- [ ] Update `/Users/dt/projects/dev-tools/zsh-configuration/CLAUDE.md`

  - [ ] Add dispatcher pattern explanation
  - [ ] Add file organization section
  - [ ] Add "How to Add New Commands" section
  - [ ] Update actual configuration location section
- [ ] Update `/Users/dt/projects/dev-tools/zsh-configuration/docs/user/ALIAS-REFERENCE-CARD.md`

  - [ ] Remove 43 deleted aliases
  - [ ] Add dispatcher reference section
  - [ ] Add keyword quick reference
  - [ ] Update totals (183 aliases → ~140 aliases)
- [ ] Update `/Users/dt/projects/dev-tools/zsh-configuration/docs/user/WORKFLOWS-QUICK-WINS.md`

  - [ ] Update R package workflow to use `r` dispatcher
  - [ ] Update Quarto workflow to use `qu` dispatcher
  - [ ] Add timer workflow examples
  - [ ] Add vibe workflow examples
- [ ] Update `/Users/dt/projects/dev-tools/zsh-configuration/docs/reference/EXISTING-SYSTEM-SUMMARY.md`

  - [ ] Uncheck all removed aliases
  - [ ] Add dispatcher section
  - [ ] Update statistics
- [ ] Create `/Users/dt/projects/dev-tools/zsh-configuration/docs/reference/DISPATCHER-REFERENCE.md` ⭐ NEW

  - [ ] Complete list of all dispatchers
  - [ ] All keywords for each dispatcher
  - [ ] Usage examples
  - [ ] Pattern explanation

### 4.2 Update ZSH Configuration Files

**~/.config/zsh/:**

- [ ] Create `~/.config/zsh/STANDARDS.md` ⭐ NEW

  - [ ] File organization standards
  - [ ] Naming conventions
  - [ ] Dispatcher pattern documentation
  - [ ] Helper function conventions
- [ ] Update `~/.config/zsh/functions/README.md` (if exists) or create ⭐ NEW

  - [ ] List all function files
  - [ ] Explain each file's purpose
  - [ ] Show dependency graph
  - [ ] Document sourcing order

### 4.3 Global Configuration Documentation

**~/.claude/:**

- [ ] Update `~/.claude/CLAUDE.md` (global instructions)
  - [ ] Add dispatcher pattern as standard
  - [ ] Reference zsh-configuration standards
  - [ ] Update ZSH workflow section

---

## 🔧 Part 5: Implementation Plan

### Phase 1: Audit & Verification (1 hour)

- [ ] Verify all existing dispatcher keywords work
- [ ] Check `r` for all 22 keywords
- [ ] Check `qu` for all 7 keywords
- [ ] Check `vibe` for all 23 keywords
- [ ] Check `work` for all flags
- [ ] Check `pick` for all 7 filters
- [ ] Check `cc` for existing keywords
- [ ] Document what exists vs what's missing

### Phase 2: Create New Dispatchers (3-4 hours)

**timer Dispatcher (2 hours):**

- [ ] Create `timer()` function with 9 keywords
- [ ] Create helper functions (_timer_focus, _timer_break, etc.)
- [ ] Add notification support
- [ ] Test all timer commands
- [ ] Create help system

**peek Dispatcher (1-2 hours):**

- [ ] Create `peek()` function with 10 keywords
- [ ] Create _peek_auto() helper
- [ ] Test all peek commands
- [ ] Create help system

### Phase 3: Enhance Existing Dispatchers (2-3 hours)

**r Dispatcher (30 min):**

- [ ] Add `clean`, `deep`, `tex`, `commit` keywords
- [ ] Update help text
- [ ] Test new keywords

**qu Dispatcher (1 hour):**

- [ ] Add `pdf`, `html`, `docx`, `commit`, `article`, `present` keywords
- [ ] Update help text
- [ ] Test new keywords

**vibe Dispatcher (1 hour):**

- [ ] Add `start`, `end`, `morning`, `night`, `progress` keywords
- [ ] Update help text
- [ ] Test new keywords

**pick Dispatcher (1 hour):**

- [ ] Implement mgmt section (from PROPOSAL-PICK-ENHANCEMENTS.md)
- [ ] Implement recent section (from PROPOSAL-PICK-RECENT-SECTION.md)
- [ ] Add `list`, `tree`, `help` keywords
- [ ] Update help text

**cc Dispatcher (30 min - if needed):**

- [ ] Add missing keywords for model/mode selection
- [ ] Update help text
- [ ] Test new keywords

### Phase 4: Remove Redundant Aliases (1-2 hours)

**From adhd-helpers.zsh:**

- [ ] Remove 5 pick* aliases (pickr, pickdev, pickq, pickteach, pickrs)
- [ ] Remove 6 peek* aliases (peekr, peekrd, peekqmd, peekdesc, peeknews, peeklog)
- [ ] Remove 4 rpkg* aliases (rpkgclean, rpkgdeep, rpkgcommit, cleantex)
- [ ] Remove 6 R workflow aliases (rcycle, rquick, rcheckfast, rdoccheck, lt, dt)
- [ ] Remove 8 Quarto aliases (q, qp, qr, qpdf, qhtml, qdocx, qcommit, qarticle, qpresent)
- [ ] Remove 8 Claude aliases (ccl, cch, ccs, cco, ccplan, ccauto, ccyolo, cccode)
- [ ] Remove 7 vibe aliases (startsession, endsession, gm, gn, pmorning, pnight, progress_check)
- [ ] Remove 6 timer functions (focus, unfocus, worktimer, quickbreak, break, deepwork)
- [ ] Remove 2 pick aliases (pp, cdproj)

**From functions.zsh:**

- [ ] Remove duplicate focus() if exists
- [ ] Remove duplicate next() if exists
- [ ] Remove other duplicates per ZSH-OPTIMIZATION-PROPOSAL

**From .zshrc:**

- [ ] Remove commented aliases (lt, dt)
- [ ] Clean up old references

### Phase 5: Refactor File Organization (2-3 hours)

**Option A: Consolidate (Recommended):**

- [ ] Create unified `dispatchers.zsh`
- [ ] Move all dispatcher functions to it
- [ ] Keep v-dispatcher separate (it's large)
- [ ] Update sourcing in .zshrc

**Option B: Standardize Names:**

- [ ] Rename to dispatcher pattern
- [ ] Keep files separate
- [ ] Document organization

**Extract from adhd-helpers.zsh:**

- [ ] Extract pick() to separate file
- [ ] Split adhd-helpers into logical modules
- [ ] Update sourcing

### Phase 6: Documentation Updates (2-3 hours)

- [ ] Update CLAUDE.md (zsh-configuration)
- [ ] Update ALIAS-REFERENCE-CARD.md
- [ ] Update WORKFLOWS-QUICK-WINS.md
- [ ] Update EXISTING-SYSTEM-SUMMARY.md
- [ ] Create DISPATCHER-REFERENCE.md
- [ ] Create STANDARDS.md (~/.config/zsh/)
- [ ] Create functions/README.md
- [ ] Update global ~/.claude/CLAUDE.md

### Phase 7: Testing & Validation (1-2 hours)

- [ ] Source updated configuration
- [ ] Test all dispatcher keywords
- [ ] Test all new dispatchers (timer, peek)
- [ ] Test enhanced dispatchers (r, qu, vibe, pick)
- [ ] Verify removed aliases are gone
- [ ] Check for broken dependencies
- [ ] Run test suite if exists

---

## 📊 Final Statistics

### Before

- **Total Aliases:** 183
- **Dispatcher Files:** 5 (smart-dispatchers, v-dispatcher, g-dispatcher, mcp-dispatcher, work)
- **Main Helper File:** adhd-helpers.zsh (3034 lines)
- **Conflicts:** focus() defined 3 times

### After

- **Total Aliases:** ~140 (43 removed)
- **Total Dispatchers:** 7 main commands (r, qu, vibe, work, pick, timer, peek)
- **Total Keywords:** ~90+ keywords across all dispatchers
- **Conflicts:** 0 (focus() resolved)
- **Organization:** Clear file structure with standards

### Consolidation Results

| Category  | Aliases Removed | Dispatcher | Keywords Added                                |
| --------- | --------------- | ---------- | --------------------------------------------- |
| R Package | 10              | `r`        | 4 (clean, deep, tex, commit)                  |
| Quarto    | 8               | `qu`       | 6 (pdf, html, docx, commit, article, present) |
| Vibe      | 7               | `vibe`     | 5 (start, end, morning, night, progress)      |
| Pick      | 7               | `pick`     | 5 (mgmt, recent, list, tree, help)            |
| Timer     | 6               | `timer`    | 9 (NEW dispatcher)                            |
| Peek      | 6               | `peek`     | 10 (NEW dispatcher)                           |
| Claude    | 8               | `cc`       | TBD (verify existing)                         |
| **TOTAL** | **43**          | **7**      | **~45+**                                      |

---

## ✅ Success Criteria

**All checkboxes completed:**

- [ ] All existing dispatcher keywords verified working
- [ ] 2 new dispatchers created (timer, peek)
- [ ] 5 dispatchers enhanced (r, qu, vibe, pick, cc)
- [ ] 43 redundant aliases removed
- [ ] File organization refactored
- [ ] Standards documentation created
- [ ] All documentation updated
- [ ] All tests passing
- [ ] Zero conflicts
- [ ] Shell reloads without errors

---

## 📝 Next Steps

1. **Review this proposal** - Check all boxes match your intentions
2. **Decide on file organization** - Option A (consolidate) or Option B (standardize)?
3. **Begin Phase 1** - Audit existing dispatchers
4. **Proceed through phases** - One phase at a time
5. **Test thoroughly** - After each phase

---

**Created:** 2025-12-19
**Status:** 🟡 Awaiting Review
**Completeness:** All 43 items accounted for with checkboxes
**Includes:** Standards, refactoring, file management
**Ready for:** Implementation

---

## 🎯 Summary Checklist

**Proposal Completeness:**

- [X] Checkboxes for all existing dispatcher keywords
- [X] Checkboxes for all new keywords to add
- [X] Checkboxes for all aliases to remove
- [X] Checkboxes for all new dispatchers to create
- [X] Checkboxes for file organization tasks
- [X] Checkboxes for documentation updates
- [X] Checkboxes for implementation phases
- [X] Standards file location updates included
- [X] Script management and refactoring included
- [X] Complete audit of existing vs new items

**Ready for your review!**
