# ⚡ ZSH Alias Reference Card

> **Quick Access:** `ah <category>` for interactive help

**Last Updated:** 2025-12-16 | **Total:** 183 aliases, 108 functions

⚠️ **Optimization in progress:** See `ZSH-OPTIMIZATION-PROPOSAL-2025-12-16.md` for details on duplicate resolution

---

## 🚀 ULTRA-FAST (Single Letter)

| Alias | Command | Usage |
|-------|---------|-------|
| `t` | `rtest` | Test R package (50x/day) |
| `c` | `claude` | Launch Claude Code (30x/day) |
| `q` | `qp` | Preview Quarto (10x/day) |

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

## 🔍 WORKSPACE AUDIT (v1.5.0)

> **Full Guide:** `WORKSPACE-AUDIT-GUIDE.md`

### Quick Commands
| Alias | Command | Description |
|-------|---------|-------------|
| `ga` | `git-audit` | Find dirty/unpushed repos |
| `fa` | `file-audit` | Find large files (>50MB) |
| `ah` | `activity-heat` | 7-day activity heatmap |
| `ma` | `morning-audit` | Full daily health check |

### Common Usage
```bash
ma              # Daily health check (recommended)
ga -q           # Quick git status across all repos
ah -n 5         # Top 5 active projects
fa -s 100M      # Find files >100MB
ma -o           # Generate and open report
```

### What Each Does
| Command | Scans | Output |
|---------|-------|--------|
| `git-audit` | ~/projects (depth 3) | Dirty repos, unpushed commits |
| `file-audit` | ~/projects | Files >50MB (excludes node_modules, .git) |
| `activity-heat` | ~/projects | Visual bar chart of recent activity |
| `morning-audit` | All of above + obs audit | Combined daily report |

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

## ⚡ WORKFLOW FUNCTIONS

### Context Awareness
| Function | Description |
|----------|-------------|
| `whatnext` | **Fast** context-aware suggestions (detects R pkg, git, quarto) |
| `wnow` | Alias for whatnext |
| `here` | Show current context (location, package, git) |
| `next` | Show next action from .STATUS |
| `progress_check` | Show progress bars from .STATUS |

### Session Management
| Function | Description |
|----------|-------------|
| `startwork <project>` | Jump to project + show context |
| `endwork` | Update .STATUS |
| `worktimer <min>` | Work session timer |
| `startsession [name]` | Start tracked workflow session |
| `endsession` | End session with duration stats |
| `sessioninfo` | Show current session info |

### Project Navigation

| Function | Description | Usage |
|----------|-------------|-------|
| `pick [category]` | Interactive project picker (fzf) | `pick r`, `pick dev` |
| `pick --help` | Show pick command help | `pick -h` |
| `pickr` | Alias for `pick r` | R packages only |
| `pickdev` | Alias for `pick dev` | Dev tools only |
| `pickq` | Alias for `pick q` | Quarto projects only |

**Pick Interactive Keys:**

- **Enter** - cd to project directory
- **Ctrl-W** - cd + start work session
- **Ctrl-O** - cd + open in VS Code
- **Ctrl-S** - View .STATUS file
- **Ctrl-L** - View git log
- **Ctrl-C** - Exit without action

**Pick Categories:** r, dev, q, teach, rs, app (case-insensitive, forgiving aliases)

### Workflow Logging
| Function | Description |
|----------|-------------|
| `worklog 'action' 'details'` | Log a workflow action |
| `wl` | Alias for worklog |
| `wls` / `wld` / `wlb` / `wlp` | Quick: started/done/blocked/paused |
| `showflow [n] [filter]` | Show recent workflow activity |
| `sf` | Alias for showflow |
| `sft` | Show 50 entries |
| `flowstats` / `fs` | Today's stats by project/action |
| `logged <cmd>` | Run command with auto-logging |

### Dashboard Integration
| Function | Description |
|----------|-------------|
| `dashsync` / `ds` | Sync workflow + projects to Apple Notes dashboard |

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

## 🔧 TYPO TOLERANCE (ADHD-Friendly)

Common typos auto-correct - just keep typing!

| Typo | Corrects To | Category |
|------|-------------|----------|
| `claue`, `cluade`, `clade` | `claude` | AI |
| `rlaod`, `rlod` | `rload` | R |
| `rtets`, `rtset` | `rtest` | R |
| `rdco` | `rdoc` | R |
| `rchekc`, `rchck` | `rcheck` | R |
| `rcylce` | `rcycle` | R |
| `gti`, `tgi` | `git` | Git |
| `gis` | `gs` | Git |
| `clera`, `claer` | `clear` | Shell |
| `sl` | `ls` | Shell |
| `qurto`, `qaurt` | `quarto` | Quarto |

---

## 📊 Quick Stats

- **Total Aliases:** 144+
- **Total Functions:** 26
- **Categories:** 8
- **Ultra-fast (1 char):** 3 (t, c, q)
- **Atomic pairs (2 char):** 2 (lt, dt)
- **Mnemonic (2 char):** 12 (ld, ts, dc, ck, bd, rd, rc, rb, ga, fa, ah, ma)
- **Typo corrections:** 20+

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

**Last Updated:** 2025-12-18
**Version:** 1.2 (Pick command simplified, Project Navigation added)
**Next:** P1 features (progress indicators, smart confirmations)
