# ⚡ ZSH Alias Reference Card

> **Quick Access:** `ah <category>` for interactive help

**Last Updated:** 2025-12-13 | **Total:** 145+ aliases, 30+ functions

---

## 🚀 ULTRA-FAST (Single Letter)

| Alias | Command | Usage |
|-------|---------|-------|
| `t` | `rtest` | Test R package (50x/day) |
| `c` | `claude` | Launch Claude Code (30x/day) |
| `q` | `qp` | Preview Quarto (10x/day) |

---

## 🧠 ADHD HELPERS

> When your brain won't cooperate, these commands help.

### Task Initiation
| Alias | Command | When to Use |
|-------|---------|-------------|
| `js` | `just-start` | Can't decide what to work on |
| `idk` | `just-start` | "I don't know" what to do |
| `stuck` | `just-start` | Feeling stuck/paralyzed |

### Context Recovery
| Alias | Command | When to Use |
|-------|---------|-------------|
| `why` | Show context | "Why am I here?" - lost track |

### Dopamine & Wins
| Alias | Command | When to Use |
|-------|---------|-------------|
| `win "X"` | Log a win | Finished something (anything!) |
| `w! "X"` | Log a win | Same, shorter |
| `yay` | Celebrate | Quick dopamine hit |
| `wins` | See today's wins | Review progress |
| `wh` | `wins-history` | See last 7 days |

### Time Awareness
| Alias | Command | When to Use |
|-------|---------|-------------|
| `f25` | `focus 25` | 25-min focus session |
| `f50` | `focus 50` | 50-min deep work |
| `f15` | `focus 15` | Quick sprint |
| `tc` | `time-check` | "How long have I been working?" |
| `fs` | `focus-stop` | End session early |

### Daily Kickstart
| Alias | Command | When to Use |
|-------|---------|-------------|
| `am` | `morning` | Start of day - shows yesterday's wins, project status, suggested task |

### Working Memory
| Alias | Command | When to Use |
|-------|---------|-------------|
| `bc` | `breadcrumb` | Leave note for future self: `bc 'left off at line 45'` |
| `bcs` | `crumbs` | View recent breadcrumbs in current dir |
| `bclear` | `crumbs-clear` | Clear breadcrumbs (with confirmation) |

### AI Task Suggestion
| Alias | Command | When to Use |
|-------|---------|-------------|
| `wn` | `what-next` | AI suggests ONE task based on all .STATUS files |
| `wnl` | `what-next low 30` | Low energy, 30 min available |
| `wnh` | `what-next high 90` | High energy, 90 min available |
| `wnq` | `what-next normal 15` | Quick task |

### Obsidian Bridge
| Alias | Command | When to Use |
|-------|---------|-------------|
| `od` | `obs-dashboard` | Open MediationVerse dashboard in Obsidian |
| `ops` | `obs-project-sync` | Sync .STATUS files to Obsidian table |
| `osa` | `obs-sync-all` | Sync themes/settings across all vaults |
| `or` | `obs-research` | Open Research_Lab vault |
| `ok` | `obs-knowledge` | Open Knowledge_Base vault |
| `ofp` | `obs-from-project` | Open Obsidian notes for current project |
| `oqn` | `obs-quick-note` | Create quick note in Incubator |

### Usage Tips
```bash
# Start your day:
gm                     # Morning kickstart

# Can't decide? Get AI help:
wn                     # AI picks ONE task
wnl                    # Low energy mode

# Can't start? Let the system decide:
js

# Lost track? Get context:
why
bcs                    # Check breadcrumbs

# Leave notes for future self:
bc 'investigating test failure'
bc 'left off at line 45'

# Time-box your work:
f25                    # Start 25-min focus
tc                     # Check elapsed time
fs                     # Stop early (asks to log win)

# Did something? Log it (even small things!):
win "fixed the failing test"
win "added one line of docs"

# Quick celebration:
yay
```

---

## ⚡ ATOMIC PAIRS (Common Sequences)

| Alias | Commands | Description |
|-------|----------|-------------|
| `lt` | `rload && rtest` | Load then test |
| `dt` | `rdoc && rtest` | Document then test |

---

## 📦 R PACKAGE DEVELOPMENT

### Core Workflow
| Short | Mnemonic | Long | Description | Time |
|-------|----------|------|-------------|------|
| `ld` | - | `rload` | Load all package code | ~2s |
| `ts` | - | `rtest` | Run all tests | ~10-30s |
| `dc` | `rd` | `rdoc` | Generate documentation | ~5s |
| `ck` | `rc` | `rcheck` | R CMD check | ~30-60s |
| `bd` | `rb` | `rbuild` | Build tar.gz | ~10s |

### Checks & Quality
| Alias | Description | Time |
|-------|-------------|------|
| `rcycle` | Full cycle: doc → test → check | ~60-120s |
| `rquick` | Quick: load → test only | ~10-30s |
| `rcov` | Code coverage analysis | ~30s |
| `rspell` | Spell check package | ~5s |
| `rcheckfast` | Fast check (no examples/tests/vignettes) | ~15s |
| `rcheckcran` | CRAN submission check | ~60s |

### Documentation & Site
| Alias | Description |
|-------|-------------|
| `rpkgdown` | Build pkgdown site |
| `rpkgpreview` | Preview pkgdown site |
| `rdoccheck` | Check documentation |

### Maintenance
| Alias | Description | Danger |
|-------|-------------|--------|
| `rpkgclean` | Remove .Rhistory, .RData | 🟢 Safe |
| `rpkgdeep` | Remove man/, NAMESPACE, docs/ | 🔴 Destructive |
| `rpkgcommit` | Doc → test → commit | 🟢 Safe |

### Versioning
| Alias | Bumps Version |
|-------|---------------|
| `rbumppatch` | 1.2.3 → 1.2.4 |
| `rbumpminor` | 1.2.3 → 1.3.0 |
| `rbumpmajor` | 1.2.3 → 2.0.0 |

### Info & Navigation
| Alias | Description |
|-------|-------------|
| `rpkg` | Show package info |
| `rpkgstatus` | Status of all packages |
| `rpkgtree` | Tree view (excluding artifacts) |

### File Viewing
| Alias | Target | Language |
|-------|--------|----------|
| `peekr` | R files | R syntax |
| `peekrd` | .Rd files | Markdown |
| `peekqmd` | .qmd files | Markdown |
| `peekdesc` | DESCRIPTION | Plain text |
| `peeknews` | NEWS.md | Markdown |

---

## 🤖 CLAUDE CODE

### Launch & Models
| Alias | Description |
|-------|-------------|
| `cc` | Interactive mode |
| `ccc` | Continue last conversation |
| `ccl` | Resume latest session |
| `cch` | Use Haiku (fastest) |
| `ccs` | Use Sonnet (default) |
| `cco` | Use Opus (most capable) |

### Permission Modes
| Alias | Mode | Description |
|-------|------|-------------|
| `ccplan` | Plan | Review before executing |
| `ccauto` | Auto-accept | Accept edits only |
| `ccyolo` | Bypass | Bypass all permissions |

### R-Specific Tasks
| Alias | Task |
|-------|------|
| `ccrdoc` | Generate roxygen2 docs |
| `ccrtest` | Generate testthat tests |
| `ccrexplain` | Explain R code |
| `ccrfix` | Fix R CMD check issues |
| `ccroptimize` | Optimize R code |
| `ccrrefactor` | Refactor (tidyverse style) |
| `ccrstyle` | Apply tidyverse style |

### General Code Tasks
| Alias | Task |
|-------|------|
| `ccfix` | Fix bugs |
| `ccreview` | Review code |
| `cctest` | Generate tests |
| `ccdoc` | Generate docs |
| `ccexplain` | Explain code |
| `ccrefactor` | Refactor |
| `ccoptimize` | Optimize |
| `ccsecurity` | Security review |

### Output Formats
| Alias | Format |
|-------|--------|
| `ccp` | Print mode (non-interactive) |
| `ccjson` | JSON output |
| `ccstream` | Streaming JSON |

---

## 📊 PROJECT STATUS & NOTES SYNC

**Purpose:** Manage project `.STATUS` files and sync to Apple Notes dashboard

### 📊 Project Status (Local Operations)

Scan and analyze `.STATUS` files without external syncing.

| Long Form | Short | Description | Output |
|-----------|-------|-------------|--------|
| `pstat` | - | Scan .STATUS files → JSON | ✅ Scanned 5 projects |
| `pstatview` | `psv` | View formatted project list | P0 medfit [25%] - Next action |
| `pstatlist` | `psl` | List all .STATUS files | Path to each .STATUS file |
| `pstatcount` | `psc` | Quick stats summary | Total: 5 | Blocked: 1 | Active: 2 |
| `pstatshow` | `pss` | Pretty-print JSON (less) | Colorized JSON with pager |

### 📝 Notes Sync (Apple Notes Operations)

Sync project status to Apple Notes and other destinations.

| Long Form | Short | Description | Destination |
|-----------|-------|-------------|-------------|
| `nsync` | `ns` | Full sync to Apple Notes | ⭐ Apple Notes (iCloud) |
| `nsyncview` | `nsv` | View current Apple Note | Terminal display |
| `nsyncclip` | `nsc` | Copy RTF to clipboard | Clipboard (manual paste) |
| `nsyncexport` | `nse` | Export to MD/RTF/TXT files | Files in current dir |

### 🔄 Deprecated (Use new aliases instead)

| Old Alias | New Alias | Warning |
|-----------|-----------|---------|
| `dashupdate` | `pstat` | ⚠️ Shows deprecation notice |
| `dashsync` | `nsync` | ⚠️ Shows deprecation notice |
| `dashclip` | `nsyncclip` | ⚠️ Shows deprecation notice |
| `dashexport` | `nsyncexport` | ⚠️ Shows deprecation notice |

### 🎯 Quick Start

```bash
# Local operations (no syncing)
pstat         # Scan projects → JSON
psv           # View formatted list
psc           # Quick stats

# Sync to Apple Notes
ns            # Full sync (scan + update Notes) ⭐
nsv           # View current Apple Note

# Ultra-fast workflow
ns && nsv     # Sync and immediately view result
```

**Docs:** `~/projects/dev-tools/apple-notes-sync/README.md`

---

## 🎯 WORK COMMAND (Multi-Editor Router)

> Part of Option B+ Quadrant System (2025-12-13)

### Quick Launch
| Alias | Editor | When to Use |
|-------|--------|-------------|
| `w <project>` | Auto | Let it decide |
| `we <project>` | Emacs | Deep focus, vim flow |
| `wc <project>` | VS Code | Quick fix, familiar |
| `wp <project>` | Positron | See data while coding |
| `wa <project>` | Claude Code | AI-assisted session |
| `wt <project>` | Terminal | Just navigate |

### Mode Shortcuts
| Alias | Mode | Opens |
|-------|------|-------|
| `wf <project>` | Focus | Emacs |
| `wx <project>` | Explore | Positron |
| `wai <project>` | AI | Claude Code |
| `wq <project>` | Quick | Terminal |

### Features
- Auto-detects project type (rpkg, quarto, website)
- Shows git status, .STATUS next action
- Sets directory bookmarks (`~pkgr`, `~pkgtest`, etc.)
- `work --help` for full usage

---

## 🤖 CLAUDE CODE WORKFLOWS (Enhanced)

> AI-assisted R development workflows (2025-12-13)

### Project-Aware
| Alias | Command | Description |
|-------|---------|-------------|
| `ccp` | `cc-project` | Start with CLAUDE.md + .STATUS context |
| `ccf <file>` | `cc-file` | Start with file in context |

### Implementation
| Alias | Command | Description |
|-------|---------|-------------|
| `cci "task"` | `cc-implement` | Implement feature with AI |
| `cccycle "task"` | `cc-cycle` | Full: implement → test → fix |

### Testing & Review
| Alias | Command | Description |
|-------|---------|-------------|
| `ccft` | `cc-fix-tests` | Run tests, ask AI to fix failures |
| `ccpc` | `cc-pre-commit` | Review changes before commit |

### Docs & Learning
| Alias | Command | Description |
|-------|---------|-------------|
| `cce <file>` | `cc-explain` | Explain code |
| `ccrdoc <file>` | `cc-roxygen` | Generate roxygen docs |
| `cchelp` | `cc-help` | Show all workflows |

---

## 💎 GEMINI

### Launch
| Alias | Description |
|-------|-------------|
| `gm` | Quick launch interactive |
| `gmpi` | Prompt then stay interactive |
| `gmr` | Resume latest session |

### Power Modes
| Alias | Mode |
|-------|------|
| `gmy` | YOLO (auto-approve) |
| `gms` | Sandbox (safe mode) |
| `gmd` | Debug mode |
| `gmys` | YOLO + Sandbox |
| `gmyd` | YOLO + Debug |
| `gmsd` | Sandbox + Debug |

### Management
| Alias | Function |
|-------|----------|
| `gmm` | MCP server management |
| `gme` | Extension management |
| `gmei` | Install extension |
| `gmel` | List extensions |
| `gmeu` | Update extensions |
| `gmls` | List sessions |
| `gmds` | Delete session |

---

## 📝 QUARTO

| Alias | Command | Description |
|-------|---------|-------------|
| `qp` | `quarto preview` | Preview document |
| `qr` | `quarto render` | Render document |
| `qc` | `quarto check` | Check installation |
| `qclean` | Remove outputs | Clean build artifacts |

---

## ⌨️ EMACS/SPACEMACS (R Development)

> Vim keybindings enabled. Prefix: `,` (major mode) or `SPC m`

### devtools Commands
| Key | Command | R Equivalent |
|-----|---------|---------------|
| `, l` | Load package | `devtools::load_all()` |
| `, t` | Test package | `devtools::test()` |
| `, d` | Document | `devtools::document()` |
| `, c` | Check | `devtools::check()` |
| `, i` | Install | `devtools::install()` |

### Pipe & Assignment (Insert Mode)
| Key | Inserts | Note |
|-----|---------|------|
| `, p` | ` \|> ` | Native pipe |
| `, -` | ` <- ` | Assignment |
| `M-p` | ` \|> ` | Alt+p (faster) |
| `M--` | ` <- ` | Alt+minus |

### ESS Defaults
- RStudio-style indentation
- LSP backend (languageserver)
- Non-blocking evaluation

---

## 🔧 GIT

| Alias | Command | Description |
|-------|---------|-------------|
| `gs` | `git status -sb` | Short status |
| `glog` | Git log graph | All branches with graph |
| `gloga` | Git log by author | Filter by author |
| `gundo` | Reset soft HEAD~1 | Undo last commit (keep changes) |
| `qcommit` | Stage all + commit | Quick commit |
| `qpush` | Commit + push | Quick commit and push |
| `smartgit` | Status + log + diff | Show everything |

---

## 📁 FILE OPERATIONS

### Better Tools
| Alias | Replaces | Tool |
|-------|----------|------|
| `cat` | cat | bat (syntax highlighting) |
| `find` | find | fd (faster, better UX) |
| `grep` | grep | rg (ripgrep, faster) |

### Quick Views
| Alias | Use | Example |
|-------|-----|---------|
| `peek` | View any file | `peek script.R` |
| `ll` | Long list with details | `ll` |
| `la` | List all (including hidden) | `la` |
| `l` | List (short format) | `l` |
| `d` | Directory stack | `d` |

---

## 🧭 SMART NAVIGATION & HISTORY

### Zoxide (Frecency-based Jump)

**Installed:** ✅ Homebrew (`brew install zoxide`)
**Speed:** 10-40x faster than old z plugin (Rust-based)

| Command | Description | Example |
|---------|-------------|---------|
| `z <dir>` | Jump to directory | `z medfit` |
| `zi <dir>` | Interactive fzf selection | `zi med` |
| `za <dir>` | Manually add to database | `za ~/special/path` |
| `z -` | Jump to previous directory | `z -` |
| `zoxide query <term>` | Query database | `zoxide query med` |

**How it works:**
- Tracks directories you visit (automatically)
- Uses "frecency" algorithm: **frequency** + **recency**
- Learns your habits over time
- Integrates with fzf for interactive selection

**Examples:**
```bash
# Jump to most frequent/recent match
$ z medfit        # Jumps to ~/projects/r-packages/active/medfit

# Partial matches work
$ z med           # Smart: likely goes to medfit

# Interactive mode (if multiple matches)
$ zi med          # Shows fzf menu to choose

# Add manually (rare, usually automatic)
$ za ~/some/deep/path
```

**Combined Workflows:**
```bash
# Use @ bookmarks for main areas, zoxide for deep navigation
$ @rpkg           # Jump to r-packages (bookmark)
$ z robust        # Then zoxide to medrobust (frecency)

# Quick return
$ z -             # Go back to previous directory
```

### Atuin (Supercharged Shell History)

**Installed:** ✅ Homebrew (`brew install atuin`)
**Upgrade:** Context-aware, searchable, syncable history

| Keybinding | Description |
|------------|-------------|
| `Ctrl+R` | Interactive fuzzy search (replaces default) |
| `Up arrow` | Search history starting with typed text |

**Search Commands:**
```bash
atuin search rtest              # Find all rtest commands
atuin search --cwd ~/projects   # Search in specific directory
atuin search --exit 0           # Only successful commands
atuin search --exit 1           # Only failed commands
atuin stats                     # Show usage statistics
```

**ADHD Benefits:**
- "What was that command I used last week?"
- Filter by directory, time, success/failure
- See command context (when, where, did it work?)
- Sync across all your machines

### Direnv (Auto Environment Loader)

**Installed:** ✅ Homebrew (`brew install direnv`)
**Purpose:** Automatically load/unload environment per directory

**Setup per project:**
```bash
# Create .envrc in project root
cd ~/projects/r-packages/active/medfit
cat > .envrc << 'EOF'
export R_LIBS_USER=~/R/medfit-libs
export RENV_ACTIVE=TRUE
layout python3  # Optional: auto venv
EOF

# Allow direnv to load it (one-time per project)
direnv allow

# Now whenever you cd into medfit, these env vars load automatically!
```

**Common use cases:**
```bash
# R package with custom library
export R_LIBS_USER=~/R/project-libs
source renv/activate.R

# Node project
export NODE_ENV=development
export API_KEY=$(security find-generic-password -a "$USER" -s api_key -w)

# Python project
layout python3

# Claude MCP project
export MCP_DEBUG=true
export LOG_LEVEL=debug
```

**ADHD Benefits:**
- Zero mental load - environments "just work"
- No more "did I activate renv?"
- No more "is the right PATH set?"
- Automatic cleanup when leaving directory

---

## 🔍 FZF HELPER FUNCTIONS

**New:** 2025-12-16 | **Requires:** fzf, fd, bat

### R Package Helpers

| Command | Description | Preview |
|---------|-------------|---------|
| `re` | Fuzzy find & edit R files | Syntax highlighted preview |
| `rt` | Fuzzy find & run test file | Shows test code |
| `rv` | Fuzzy find & view vignettes | Shows vignette content |

### Project Status

| Command | Description | Preview |
|---------|-------------|---------|
| `fs` | Fuzzy find & edit .STATUS | Shows status content |
| `fh` | Fuzzy find & view PROJECT-HUB | Shows hub content |
| `fp` | Fuzzy find projects | Shows directory + .STATUS |
| `fr` | Fuzzy find R packages | Shows DESCRIPTION |

### Git Helpers

| Command | Description | Preview |
|---------|-------------|---------|
| `gb` | Fuzzy checkout branch | Shows recent commits |
| `gdf` | Interactive git diff | Shows file diffs |
| `gshow` | Fuzzy git log | Shows commit details |
| `ga` | Interactive git add | Preview changes before staging |
| `gundostage` | Interactive git unstage | Preview staged changes |

### Quick Reference

```bash
# R development workflow
re                # Pick R file to edit
rt                # Pick test to run
fs                # Update .STATUS file

# Git workflow
ga                # Stage files (with preview)
gb                # Switch branch (with preview)
gshow             # Browse commits

# Project navigation
fp                # Jump to any project
fr                # Jump to R package

# Help
fzf-help          # Show all fzf commands
```

**Tips:**
- **Tab** - Select multiple items
- **Ctrl+/** - Toggle preview window
- **Ctrl+N/P** - Navigate in preview
- **Esc** - Cancel selection

---

## ⚡ WORKFLOW FUNCTIONS

### Context Awareness
| Function | Description |
|----------|-------------|
| `here` | Show current context (location, package, git) |
| `next` | Show next action from .STATUS |
| `progress_check` | Show progress bars from .STATUS |

### Session Management
| Function | Description |
|----------|-------------|
| `startwork <project>` | Jump to project + show context |
| `endwork` | Update .STATUS |
| `worktimer <min>` | Work session timer |

### R Package Functions
| Function | Description |
|----------|-------------|
| `rcycle` | Full cycle: load → doc → test → check |
| `rquick` | Quick cycle: load → test |
| `rpkgstatus` | Status of all R packages |
| `rpkginfo` | Detailed package info |

### Focus Management
| Function | Description |
|----------|-------------|
| `focus [min]` | Minimize distractions |
| `unfocus` | Restore notifications |
| `quickbreak <min>` | Timed break (default 5 min) |

### Git Workflows
| Function | Description |
|----------|-------------|
| `smartgit` | Status + recent commits + changed files |
| `qcommit 'msg'` | Stage all + commit |
| `qpush 'msg'` | Stage all + commit + push |

### Search & Status
| Function | Description |
|----------|-------------|
| `findproject <pattern>` | Find files across all projects |
| `recent [days]` | Recently modified files |
| `critical` | Show all 🔴 blocked items |
| `active` | Show all 🟢 active work |

---

## 🆘 HELP SYSTEM

### Interactive Help
```bash
ah              # Show all categories
ah r            # R package development
ah claude       # Claude Code
ah git          # Git shortcuts
ah quarto       # Quarto
ah files        # File operations
ah workflow     # Workflow functions
```

### Category Aliases
```bash
aliases-r       # Same as: aliases r
aliases-claude  # Same as: aliases claude
aliases-git     # Same as: aliases git
aliases-quarto  # Same as: aliases quarto
aliases-files   # Same as: aliases files
aliases-short   # Show ultra-short aliases
```

---

## 📊 Quick Stats

- **Total Aliases:** 133+
- **Total Functions:** 22
- **Categories:** 6
- **Ultra-fast (1 char):** 3 (t, c, q)
- **Atomic pairs (2 char):** 2 (lt, dt)
- **Mnemonic (2 char):** 8 (ld, ts, dc, ck, bd, rd, rc, rb)

---

## 💡 Tips

### ADHD-Optimized Patterns
1. **Visual categories** reduce cognitive load (6 groups vs 120 items)
2. **Ultra-fast shortcuts** for high-frequency tasks (t, c, q)
3. **Mnemonic consistency** makes learning easier (rd, rc, rb)
4. **Atomic pairs** combine common sequences (lt, dt)
5. **Help system** always available (ah <category>)

### Workflow Optimization
- Use `t` instead of `rtest` (90% faster to type)
- Use `lt` for load-test combo (common pattern)
- Use `ah r` when you forget an alias (instant lookup)
- Use `here` to understand current context
- Use `next` to see what to do next

### Time-Saving Calculations
- **Per command:** 3-6 chars saved × 200 commands/day = 600-1200 chars/day
- **Per week:** ~5,000 characters saved
- **Per month:** ~20,000 characters saved
- **Cognitive switches:** 80% reduction

---

## 🔗 Related Files

- **PROJECT-HUB.md** - Strategic overview
- **~/.config/zsh/.zshrc** - Main configuration
- **~/.config/zsh/functions.zsh** - Function implementations
- **/mnt/project/ZSHRC-IMPROVEMENTS.md** - Enhancement proposals

---

**Last Updated:** 2025-12-16
**Version:** 1.2 (Added atuin, direnv, fzf helpers)
**Changes:**
- Added atuin (supercharged history)
- Added direnv (auto environment loader)
- Added 15 new fzf helper functions (re, rt, rv, fs, fh, fp, fr, gb, gdf, gshow, ga, gundostage)

**Next:** P1 features (progress indicators, smart confirmations)
