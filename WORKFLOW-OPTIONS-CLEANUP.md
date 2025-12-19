# Workflow Options - Cleanup Checklist

**Generated:** 2025-12-19
**Purpose:** Interactive cleanup tool for workflow functions, options, and features
**Usage:** Check boxes `[x]` to mark items for removal, then say "Process workflow cleanup"

---

## 🧹 How to Use

1. **Review each category** below
2. **Check boxes** `[x]` for features/options you want to remove or deprecate
3. **Ask Claude:** "Process workflow cleanup"
4. **Review plan:** Claude shows what will be deleted
5. **Approve:** Claude executes safely with backups

---

## 📋 Workflow Function Categories

### Session Management Workflows

- [ ] `work` - Start work session - Location: adhd-helpers.zsh
- [ ] `finish` - End work session (commit + merge prompt) - Location: adhd-helpers.zsh
- [ ] `now` - What am I working on? - Location: adhd-helpers.zsh
- [ ] `next` - What should I work on next? - Location: adhd-helpers.zsh
- [X] `startsession` - Start named session - Location: adhd-helpers.zsh
- [X] `endsession` - End current session - Location: adhd-helpers.zsh

**Purpose:** Manage work sessions and context
**Usage frequency:** Daily (work, finish), Weekly (now, next)

---

### Focus & Time Management

- [ ] `focus` - Start focus session with timer - Location: adhd-helpers.zsh or smart-dispatchers.zsh
- [ ] `unfocus` - End focus session - Location: adhd-helpers.zsh
- [ ] `worktimer` - Set work timer (Pomodoro-style) - Location: adhd-helpers.zsh
- [ ] `quickbreak` - Quick break timer - Location: adhd-helpers.zsh
- [ ] `break` - Take a break - Location: adhd-helpers.zsh
- [ ] `deepwork` - Start deep work session - Location: adhd-helpers.zsh

**Purpose:** ADHD-friendly time management
**Usage frequency:** Daily (focus sessions), As needed (breaks)

⚠️ **Note:** `focus()` has 3 duplicate definitions (see ZSH-OPTIMIZATION-PROPOSAL-2025-12-16.md)

---

### Dashboard & Status Commands

- [ ] `dash` - Show all projects dashboard - Location: dash.zsh
- [ ] `dash r` - R packages dashboard - Location: dash.zsh
- [ ] `dash dev` - Dev tools dashboard - Location: dash.zsh
- [ ] `dash teach` - Teaching dashboard - Location: dash.zsh
- [ ] `dash rs` - Research dashboard - Location: dash.zsh
- [ ] `here` - Show current context - Location: adhd-helpers.zsh
- [X] `progress_check` - Show progress bars for all projects - Location: adhd-helpers.zsh
- [X] `status` - Show .STATUS file - Location: adhd-helpers.zsh

**Purpose:** Quick overview of projects and progress
**Usage frequency:** Daily (dash), Weekly (progress_check)

---

### Energy & Motivation Helpers

- [X] `gm` / `pmorning` - Good morning routine - Location: adhd-helpers.zsh
- [X] `gn` / `pnight` - Good night routine - Location: adhd-helpers.zsh
- [ ] `win` - Log a win (dopamine boost) - Location: adhd-helpers.zsh
- [ ] `why` - Show context/motivation for current work - Location: adhd-helpers.zsh
- [ ] `js` - Just start (overcome initiation paralysis) - Location: adhd-helpers.zsh
- [ ] `stuck` - Help when stuck - Location: adhd-helpers.zsh

**Purpose:** ADHD workflow support and motivation
**Usage frequency:** Daily (gm, win), As needed (js, stuck, why)

---

### Project Navigation & Selection

- [ ] `pick` - Interactive project picker (fzf) - Location: adhd-helpers.zsh
- [X] `pickr` - Pick R package - Location: adhd-helpers.zsh:2075
- [X] `pickdev` - Pick dev tool - Location: adhd-helpers.zsh:2076
- [X] `pickq` - Pick Quarto project - Location: adhd-helpers.zsh:2077
- [X] `pickteach` - Pick teaching course - Location: adhd-helpers.zsh:2991
- [X] `pickrs` - Pick research project - Location: adhd-helpers.zsh:3163
- [X] `pp` - Project picker alias - Location: adhd-helpers.zsh
- [X] `cdproj` - CD to project directory - Location: adhd-helpers.zsh

**Purpose:** Fast project navigation
**Usage frequency:** Multiple times daily

**Note:** pick* aliases are shortcuts for `pick <category>` (2 char savings)

---

### R Package Development Workflows

#### Core Cycle Commands

- [ ] `rload` / `ld` - Load package - Location: adhd-helpers.zsh
- [ ] `rtest` / `ts` / `t` - Run tests - Location: adhd-helpers.zsh
- [ ] `rdoc` / `dc` / `rd` - Generate docs - Location: adhd-helpers.zsh
- [ ] `rcheck` / `ck` / `rc` - R CMD check - Location: adhd-helpers.zsh
- [ ] `rbuild` / `bd` / `rb` - Build tar.gz - Location: adhd-helpers.zsh

**Purpose:** R package development core workflow
**Usage frequency:** Multiple times per hour when developing R packages

#### Comprehensive Workflows

- [X] `rcycle` - Full cycle: doc → test → check - Location: adhd-helpers.zsh
- [X] `rquick` - Quick: load → test only - Location: adhd-helpers.zsh
- [ ] `rcov` - Code coverage - Location: adhd-helpers.zsh
- [ ] `rspell` - Spell check - Location: adhd-helpers.zsh
- [X] `rcheckfast` - Fast check (skip examples/tests) - Location: adhd-helpers.zsh
- [ ] `rcheckcran` - CRAN submission check - Location: adhd-helpers.zsh

**Purpose:** Comprehensive R package checks
**Usage frequency:** Daily (rcycle), Weekly (CRAN checks)

#### Documentation & Site

- [ ] `rpkgdown` - Build pkgdown site - Location: adhd-helpers.zsh
- [ ] `rpkgpreview` - Preview pkgdown site - Location: adhd-helpers.zsh
- [X] `rdoccheck` - Check documentation - Location: adhd-helpers.zsh

**Purpose:** Package documentation and website
**Usage frequency:** Weekly

#### Atomic Pairs (Convenience Aliases)

- [X] `lt` - rload && rtest (load then test) - Location: .zshrc:265 (COMMENTED)
- [X] `dt` - rdoc && rtest (doc then test) - Location: Not found

**Note:** These were removed 2025-12-14 per .zshrc comments

---

### Claude Code Workflows

#### Launch Aliases

- [ ] `cc` - Interactive mode - Location: adhd-helpers.zsh
- [ ] `ccc` - Continue last conversation - Location: adhd-helpers.zsh
- [X] `ccl` - Resume latest session - Location: adhd-helpers.zsh

**Purpose:** Quick Claude Code access
**Usage frequency:** Daily

#### Model Selection

- [X] `cch` - Use Haiku (fastest) - Location: adhd-helpers.zsh
- [X] `ccs` - Use Sonnet (default) - Location: adhd-helpers.zsh
- [X] `cco` - Use Opus (most capable) - Location: adhd-helpers.zsh

**Purpose:** Model switching shortcuts
**Usage frequency:** As needed

#### Mode Aliases

- [X] `ccplan` - Planning mode - Location: adhd-helpers.zsh
- [X] `ccauto` - Auto mode - Location: adhd-helpers.zsh
- [X] `ccyolo` - YOLO mode (minimal prompts) - Location: adhd-helpers.zsh
- [X] `cccode` - Code mode - Location: adhd-helpers.zsh

**Purpose:** Quick mode switching
**Usage frequency:** Daily

---

### Quarto Workflows

- [X] `q` / `qp` - Quarto preview - Location: adhd-helpers.zsh
- [X] `qr` - Quarto render - Location: adhd-helpers.zsh
- [X] `qpdf` - Render to PDF - Location: adhd-helpers.zsh
- [X] `qhtml` - Render to HTML - Location: adhd-helpers.zsh
- [X] `qdocx` - Render to DOCX - Location: adhd-helpers.zsh
- [X] `qcommit` - Quick commit for Quarto - Location: adhd-helpers.zsh
- [X] `qarticle` - Create article template - Location: adhd-helpers.zsh
- [X] `qpresent` - Create presentation template - Location: adhd-helpers.zsh

**Purpose:** Quarto document workflows
**Usage frequency:** Daily when working on manuscripts/presentations

---

### Git Workflows

#### Standard Git Shortcuts

- [ ] `gs` - git status - Location: adhd-helpers.zsh
- [ ] `ga` - git add - Location: adhd-helpers.zsh
- [ ] `gc` - git commit - Location: adhd-helpers.zsh
- [ ] `gp` - git push - Location: adhd-helpers.zsh
- [ ] `gl` - git pull - Location: adhd-helpers.zsh
- [ ] `gd` - git diff - Location: adhd-helpers.zsh
- [ ] `glog` - git log - Location: adhd-helpers.zsh

**Purpose:** Git command shortcuts
**Usage frequency:** Multiple times daily

#### Workflow Helpers

- [ ] `qcommit` - Quick commit (add all + commit with message) - Location: adhd-helpers.zsh
- [ ] `gundo` - Undo last commit - Location: adhd-helpers.zsh
- [ ] `smartgit` - Full git overview - Location: adhd-helpers.zsh
- [ ] `gclean` - Clean working directory - Location: adhd-helpers.zsh

**Purpose:** Git workflow automation
**Usage frequency:** Daily

---

### Help System

- [ ] `ah` - Alias helper (show categories) - Location: adhd-helpers.zsh
- [ ] `ah r` - R package aliases help - Location: adhd-helpers.zsh
- [ ] `ah claude` - Claude Code aliases help - Location: adhd-helpers.zsh
- [ ] `ah git` - Git aliases help - Location: adhd-helpers.zsh
- [ ] `ah workflow` - Workflow functions help - Location: adhd-helpers.zsh

**Purpose:** Interactive help system
**Usage frequency:** Weekly (when learning/remembering commands)

---

### File Viewers (peek* commands)

- [X] `peekr` - View R files with syntax highlighting - Location: adhd-helpers.zsh
- [X] `peekrd` - View .Rd files - Location: adhd-helpers.zsh
- [X] `peekqmd` - View .qmd files - Location: adhd-helpers.zsh
- [X] `peekdesc` - View DESCRIPTION file - Location: adhd-helpers.zsh
- [X] `peeknews` - View NEWS.md - Location: adhd-helpers.zsh
- [X] `peeklog` - View workflow log - Location: adhd-helpers.zsh

**Purpose:** Quick file viewing with syntax highlighting
**Usage frequency:** Daily

---

### Maintenance & Cleanup

- [X] `rpkgclean` - Remove .Rhistory, .RData (safe) - Location: adhd-helpers.zsh
- [X] `rpkgdeep` - Remove man/, NAMESPACE, docs/ (DESTRUCTIVE) - Location: adhd-helpers.zsh
- [X] `rpkgcommit` - Doc → test → commit workflow - Location: adhd-helpers.zsh
- [ ] `cleanr` - Clean R temporary files - Location: adhd-helpers.zsh
- [X] `cleantex` - Clean LaTeX build files - Location: adhd-helpers.zsh

**Purpose:** Cleanup and maintenance
**Usage frequency:** Weekly

⚠️ **Danger:** `rpkgdeep` is DESTRUCTIVE - removes generated files

---

## 🎯 Cleanup Decision Matrix

### Keep These (High Value, High Usage)

- `work`, `finish` - Core session management
- `pick` - Primary project navigation
- `dash` - Quick status overview
- `cc` - Claude Code primary launcher
- R core: `rload`, `rtest`, `rdoc`, `rcheck`

### Consider Removing (Low Usage)

- `pick*` aliases - Save only 2 characters vs `pick <type>`
- Model-specific Claude aliases if you always use default
- Duplicate functions (focus, next, etc.)
- Commented/removed aliases

### Investigate (May Not Exist)

- Ultra-fast aliases (`t`, `c`, `q`)
- Atomic pairs (`lt`, `dt`) - already commented in .zshrc
- Model aliases (`cch`, `ccs`, `cco`)

---

## 📊 Statistics

**Total workflow items documented:** ~108 functions + options

**Categories:**

- Session Management: 6 functions
- Focus & Time: 6 functions
- Dashboard & Status: 8 functions
- Energy & Motivation: 6 functions
- Project Navigation: 8 functions
- R Package Development: 25+ aliases/functions
- Claude Code: 12+ aliases
- Quarto: 10+ aliases
- Git: 11+ aliases
- Help System: 5 functions
- File Viewers: 6 functions
- Maintenance: 5 functions

---

## 🔄 Processing Workflow

When you check items and say "Process workflow cleanup", Claude will:

1. **Detect checked items** using grep `- \[x\]`
2. **Search for definitions** in all ZSH files
3. **Find all references** in documentation
4. **Create deletion plan** with line numbers
5. **Show dependencies** (what might break)
6. **Request approval** before making changes
7. **Create backups** of all files to be modified
8. **Execute deletions** atomically
9. **Update documentation** to match
10. **Verify changes** (source .zshrc, test commands)

---

## 🎓 Learning Notes

### Why You Might Remove Things

1. **Duplicate functionality** - Same feature, different names
2. **Low usage** - Defined but rarely/never used
3. **Better alternatives** - Newer/improved versions exist
4. **Complexity reduction** - Simplify configuration
5. **Conflicts** - Resolve naming conflicts

### Safe Removal Criteria

✅ **Safe to remove if:**

- Has clear alternative (e.g., `pickr` → `pick r`)
- Not referenced in other scripts
- Low/no usage in your workflow
- Duplicate of another command

⚠️ **Be careful removing:**

- Ultra-fast aliases (t, c, q) - high usage
- Core workflow commands (work, finish, pick)
- Commands in your daily habits

🔴 **Don't remove:**

- Core functions that other commands depend on
- Commands you use daily without thinking
- Safety/undo commands (gundo, etc.)

---

**Created:** 2025-12-19
**Purpose:** Comprehensive workflow cleanup tool
**Usage:** Check boxes, ask Claude to process
**Status:** 🟢 Ready for use
