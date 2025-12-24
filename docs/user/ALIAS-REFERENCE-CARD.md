# ⚡ ZSH Alias Reference Card

> **Quick Access:** Type `als` to list all aliases by category

**Last Updated:** 2025-12-19 | **Total:** 28 custom aliases + 226+ git aliases (from plugin)

**Philosophy:** Minimalist, high-frequency only. Removed 151 aliases (2025-12-19) to reduce memory load.

---

## 📊 Quick Stats

- **Before cleanup:** 179 custom aliases
- **After cleanup:** 28 custom aliases (84% reduction)
- **Memorization burden:** ~30 commands (vs 179)
- **Git aliases:** Handled by git plugin (standard, no memorization needed)

---

## 🛠️ TOOL REPLACEMENTS (1)

Modern CLI tools with better UX:

| Alias       | Replaces | Why                                                |
| ----------- | -------- | -------------------------------------------------- |
| `cat='bat'` | cat      | Syntax highlighting, line numbers, git integration |

**Removed 2025-12-19:**

- `find='fd'` - Use `fd` directly (it's short enough)
- `grep='rg'` - Use `rg` directly

---

## 📦 R PACKAGE DEVELOPMENT (23)

### Core Workflow (6)

| Alias      | Full Command           | Description            | Frequency |
| ---------- | ---------------------- | ---------------------- | --------- |
| `rload`    | `devtools::load_all()` | Load all package code  | 50x/day   |
| `rtest`    | `devtools::test()`     | Run all tests          | 30x/day   |
| `rdoc`     | `devtools::document()` | Generate documentation | 20x/day   |
| `rcheck`   | `devtools::check()`    | R CMD check            | 10x/day   |
| `rbuild`   | `devtools::build()`    | Build tar.gz           | 5x/day    |
| `rinstall` | `devtools::install()`  | Install package        | 5x/day    |

### Quality & Coverage (2)

| Alias     | Description                     | Time |
| --------- | ------------------------------- | ---- |
| `rcov`    | Code coverage report            | ~30s |
| `rcovrep` | Open coverage report in browser | ~2s  |

### Documentation (3)

| Alias         | Description                      |
| ------------- | -------------------------------- |
| `rdoccheck`   | Check documentation completeness |
| `rspell`      | Spell check package docs         |
| `rpkgdown`    | Build pkgdown website            |
| `rpkgpreview` | Preview pkgdown site locally     |

### CRAN Checks (4)

| Alias        | Description                              | Time   |
| ------------ | ---------------------------------------- | ------ |
| `rcheckfast` | Fast check (no examples/tests/vignettes) | ~15s   |
| `rcheckcran` | Full CRAN submission check               | ~60s   |
| `rcheckwin`  | Check on Windows (via win-builder)       | ~5min  |
| `rcheckrhub` | Check on R-hub (multiple platforms)      | ~10min |

### Dependencies (2)

| Alias         | Description               |
| ------------- | ------------------------- |
| `rdeps`       | Show package dependencies |
| `rdepsupdate` | Update dependencies       |

### Versioning (3)

| Alias        | Description             | Example       |
| ------------ | ----------------------- | ------------- |
| `rbumppatch` | Increment patch version | 0.1.0 → 0.1.1 |
| `rbumpminor` | Increment minor version | 0.1.0 → 0.2.0 |
| `rbumpmajor` | Increment major version | 0.1.0 → 1.0.0 |

### Utilities (3)

| Alias      | Description                          |
| ---------- | ------------------------------------ |
| `rpkgtree` | Tree view (excludes build artifacts) |
| `rpkg`     | Quick package info & status          |

**Removed 2025-12-19:**

- `rpkgclean` - Removed artifacts cleanup (use manual `rm`)
- `rpkgdeep` - Removed deep clean (use manual `rm`)

---

## 🤖 CLAUDE CODE (2)

| Alias | Full Command | Description                  | Frequency |
| ----- | ------------ | ---------------------------- | --------- |
| `ccp` | `claude -p`  | Print mode (non-interactive) | 10x/day   |
| `ccr` | `claude -r`  | Resume session with picker   | 5x/day    |

**Note:** Use `cc` function (dispatcher) for project-aware Claude sessions.

**Removed 2025-12-19:**

- All other `cc*` aliases (15+) - Use full commands or `cc` dispatcher

---

## ⏱️ FOCUS TIMERS (2)

| Alias | Description         | Use Case          |
| ----- | ------------------- | ----------------- |
| `f25` | 25-minute Pomodoro  | Deep work, coding |
| `f50` | 50-minute deep work | Research, writing |

**Removed 2025-12-19:**

- `f15`, `f90` - Use `focus <minutes>` directly for other durations

---

## 🚫 WHAT WAS REMOVED (2025-12-19)

### Categories Eliminated (151 aliases)

1. **Typo corrections (13)** - Type correctly instead
   - `claue`, `clade`, `clera`, `sl`, `pdw`, `qurto`, etc.

2. **Low-frequency shortcuts (25)**
   - Claude: `ccplan`, `ccyolo`, `cctx`, `cinit`, `cshow`, etc.
   - Obsidian: All `o*` shortcuts (12)
   - Project status: `pstat*`, `nsync*` variants (9)

3. **Single-letter aliases (4)**
   - `e`, `d`, etc. - Too ambiguous

4. **Duplicate aliases (12)** - REMOVED in v2.0
   - ~~`stuck`~~, ~~`idk`~~, ~~`js`~~ → Use `just-start` instead
   - ~~`e`~~ and ~~`ec`~~ → Both were emacsclient
   - ~~`gmorning`~~, ~~`goodmorning`~~, ~~`am`~~ → Use `morning` instead

5. **Navigation aliases (10)**
   - `cdrpkg`, `cdq`, etc. → Use `pick` or `pp` instead

6. **Workflow shortcuts (30)**
   - `w!`, `wh`, `wn*`, `wl*`, `sf*`, etc. → Use full commands

7. **Meta-aliases (7)**
   - `aliases-claude`, `aliases-r`, etc. → Use `aliases <category>` directly

8. **Peek shortcuts (5)**
   - `peekr`, `peekrd`, `peekqmd`, etc. → Use `peek` dispatcher

9. **Work shortcuts (10)**
   - `we`, `wc`, `wf`, etc. → Use `work <project> --editor=<name>`

10. **Breadcrumb/context aliases (4)**
    - `bc`, `bcs`, `bclear`, `ds` → Use full commands

11. **Emacs aliases (2)**
    - `e`, `ec` → Use `emacs` or `emacsclient` directly

---

## 🎯 DISPATCHERS (Functions, not aliases)

These smart functions provide context-aware workflows:

| Command | Description    | Auto-detects                            |
| ------- | -------------- | --------------------------------------- |
| `cc`    | Claude Code    | Project type, opens in project root     |
| `gm`    | Gemini         | Project type, opens in project root     |
| `peek`  | File viewer    | File type, uses bat with correct syntax |
| `qu`    | Quarto         | Operation type (preview/render/check)   |
| `work`  | Work session   | Project type, sets up environment       |
| `pick`  | Project picker | Shows all projects with fzf             |

---

## 📚 GIT ALIASES (226+)

Provided by OMZ git plugin (enabled 2025-12-19):

**Common examples:**

- `g` = `git`
- `ga` = `git add`
- `gaa` = `git add --all`
- `gcmsg` = `git commit -m`
- `gp` = `git push`
- `gst` = `git status`
- `glo` = `git log --oneline`

**Full list:** Run `aliases git` or see [OMZ git plugin docs](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git)

**Removed custom git aliases (2025-12-19):**

- `gti`, `tgi`, `gis`, `gitstatus`, `gpkgcommit` → Use git plugin instead

---

## 🎓 HOW TO USE THIS REFERENCE

### Quick Lookups

```bash
# List all aliases by category
als

# Interactive help (if ah function exists)
ah <category>

# Git plugin aliases
aliases git
```

### Learning Strategy

1. **Master the 6 core R aliases** (rload, rtest, rdoc, rcheck, rbuild, rinstall)
2. **Learn the 2 Claude aliases** (ccp, ccr)
3. **Use dispatchers** (cc, gm, peek, qu, work, pick)
4. **Git plugin aliases** - Learn standard ones (gst, ga, gcmsg, gp)

### Memory Aid

- **R package dev:** 23 aliases, all start with `r`
- **Claude:** 2 aliases, both start with `cc`
- **Focus:** 2 aliases, start with `f` + duration
- **Tool replacement:** 1 alias (`cat`)

---

## 🔄 MIGRATION GUIDE

If you're used to old aliases:

| Old Alias  | New Approach                               |
| ---------- | ------------------------------------------ |
| `e` / `ec` | `emacs` or `emacsclient -c -a ''`          |
| `find`     | `fd` (direct command)                      |
| `grep`     | `rg` (direct command)                      |
| `cdrpkg`   | `pick` or `cd ~rpkg` (bookmark)            |
| `cdq`      | `pick` or `cd ~quarto` (bookmark)          |
| `ccplan`   | `claude --permission-mode plan`            |
| `cctx`     | `claude-ctx` (full command)                |
| `peekr`    | `peek <file>` or `bat --language=r <file>` |
| `f15`      | `focus 15`                                 |
| `stuck`    | `just-start`                               |
| `wn`       | `what-next`                                |
| All typos  | Type correctly!                            |

---

## 📖 ADDITIONAL RESOURCES

- **Workflow Quick Reference:** `~/projects/dev-tools/flow-cli/docs/user/WORKFLOW-QUICK-REFERENCE.md`
- **Pick Command Guide:** `~/projects/dev-tools/flow-cli/docs/user/PICK-COMMAND-REFERENCE.md`
- **ZSH Development Guidelines:** `~/projects/dev-tools/flow-cli/docs/ZSH-DEVELOPMENT-GUIDELINES.md`

---

**Last cleanup:** 2025-12-19 (Reduced from 179 to 28 aliases)
