# Existing System Summary - ZSH Workflow Manager

**Generated:** 2025-12-19 14:20
**Purpose:** Comprehensive overview + interactive cleanup tool
**Location:** `/Users/dt/projects/dev-tools/zsh-configuration/`

---

## 🧹 How to Use This as a Cleanup Tool

This document doubles as an **interactive cleanup checklist**:

1. **Mark items for deletion:** Change `- [ ]` to `- [x]` for any alias/function/category you want to remove
2. **Ask Claude to process:** Say "Process checked items for deletion"
3. **Review the plan:** Claude will show all files and lines to be modified
4. **Approve:** Claude executes the deletions safely (with backups)
5. **Reload shell:** `source ~/.zshrc` to apply changes

**Safety:** Backups created before deletion. Dependency checking. User approval required.

See [PROPOSAL-INTERACTIVE-CLEANUP.md](../../PROPOSAL-INTERACTIVE-CLEANUP.md) for full details.

---

## 📊 System Overview

**Totals:**

- **183 aliases** (documented in ALIAS-REFERENCE-CARD.md)
- **108 functions** (across multiple files in `~/.config/zsh/functions/`)
- **8 project categories** (r, dev, q, teach, rs, app, mgmt)
- **5 keybinds** in `pick` command (Enter, Ctrl-W, Ctrl-O, Ctrl-S, Ctrl-L)

---

## 🎯 Project Categories (PROJ_CATEGORIES)

From `adhd-helpers.zsh:1648-1657`:

```zsh
PROJ_BASE="$HOME/projects"
PROJ_CATEGORIES=(
    "r-packages/active:r:📦"
    "r-packages/stable:r:📦"
    "dev-tools:dev:🔧"
    "teaching:teach:🎓"
    "research:rs:🔬"
    "quarto/manuscripts:q:📝"
    "quarto/presentations:q:📊"
    "apps:app:📱"
)
```

### Category Breakdown

| Code    | Name         | Icon | Path                                         | Projects    |
| ------- | ------------ | ---- | -------------------------------------------- | ----------- |
| `r`     | R Packages   | 📦    | `r-packages/active`, `r-packages/stable`     | ~6 packages |
| `dev`   | Dev Tools    | 🔧    | `dev-tools/`                                 | 17 projects |
| `q`     | Quarto       | 📝📊   | `quarto/manuscripts`, `quarto/presentations` | Multiple    |
| `teach` | Teaching     | 🎓    | `teaching/`                                  | 3 courses   |
| `rs`    | Research     | 🔬    | `research/`                                  | 11 projects |
| `app`   | Applications | 📱    | `apps/`                                      | 1 project   |

---

## 🔍 `pick` Command - Existing Implementation

**Location:** `~/.config/zsh/functions/adhd-helpers.zsh:1875-2073`

### Current Keybinds (Already Implemented)

```zsh
# fzf bindings (line 1990-1998)
--bind="ctrl-w:execute-silent(echo work > $action_file)+accept"
--bind="ctrl-o:execute-silent(echo code > $action_file)+accept"
--bind="ctrl-s:execute-silent(echo status > $action_file)+accept"
--bind="ctrl-l:execute-silent(echo log > $action_file)+accept"
```

| Keybind    | Action | Description                               | Implementation       |
| ---------- | ------ | ----------------------------------------- | -------------------- |
| **Enter**  | cd     | Navigate to directory                     | Default fzf behavior |
| **Ctrl-W** | work   | Start work session (calls `work` command) | Lines 2026-2031      |
| **Ctrl-O** | code   | Open in VS Code (`code .`)                | Lines 2032-2037      |
| **Ctrl-S** | status | View .STATUS file (bat/cat)               | Lines 2038-2053      |
| **Ctrl-L** | log    | View git log (tig/git)                    | Lines 2054-2064      |

### Current Filter System

```bash
pick           # Show all projects
pick r         # Filter: R packages only
pick dev       # Filter: Dev tools only
pick q         # Filter: Quarto projects only
pick teach     # Filter: Teaching courses only
pick rs        # Filter: Research projects only
pick app       # Filter: Applications only
```

### Existing Aliases for `pick`

- [X] `pickr` - pick r (R packages) - Location: adhd-helpers.zsh
- [X] `pickdev` - pick dev (Dev tools) - Location: adhd-helpers.zsh
- [X] `pickq` - pick q (Quarto) - Location: adhd-helpers.zsh
- [X] `pickteach` - pick teach (Teaching) - Location: adhd-helpers.zsh
- [X] `pickrs` - pick rs (Research) - Location: adhd-helpers.zsh

**Note:** There is NO `pickmgmt` or `pm` alias currently.

---

## ⚡ Command Aliases - Categories

### Ultra-Fast (1-character)

From `ALIAS-REFERENCE-CARD.md`:

- [X] `t` - rtest (50x/day usage) - Location: adhd-helpers.zsh
- [X] `c` - claude (30x/day usage) - Location: adhd-helpers.zsh
- [X] `q` - qp - Quarto preview (10x/day usage) - Location: adhd-helpers.zsh

### Atomic Pairs

- [X] `lt` - rload && rtest (load then test) - Location: adhd-helpers.zsh
- [X] `dt` - rdoc && rtest (doc then test) - Location: adhd-helpers.zsh

### R Package Development (30+ aliases)

Core workflow:

- [ ] `rload` / `ld` - Load package - Location: adhd-helpers.zsh
- [ ] `rtest` / `ts` / `t` - Run tests - Location: adhd-helpers.zsh
- [ ] `rdoc` / `dc` / `rd` - Generate docs - Location: adhd-helpers.zsh
- [ ] `rcheck` / `ck` / `rc` - R CMD check - Location: adhd-helpers.zsh
- [ ] `rbuild` / `bd` / `rb` - Build tar.gz - Location: adhd-helpers.zsh

Comprehensive:

- [X] `rcycle` - Full cycle: doc → test → check - Location: adhd-helpers.zsh
- [X] `rquick` - Quick: load → test only - Location: adhd-helpers.zsh
- [ ] `rcov` - Code coverage - Location: adhd-helpers.zsh
- [ ] `rpkgdown` - Build pkgdown site - Location: adhd-helpers.zsh

### Claude Code (15+ aliases)

Launch:

- [ ] `cc` - Interactive mode - Location: adhd-helpers.zsh
- [ ] `ccc` - Continue last conversation - Location: adhd-helpers.zsh
- [X] `ccl` - Resume latest session - Location: adhd-helpers.zsh

Models:

- [X] `cch` - Use Haiku (fastest) - Location: adhd-helpers.zsh
- [X] `ccs` - Use Sonnet (default) - Location: adhd-helpers.zsh
- [X] `cco` - Use Opus (most capable) - Location: adhd-helpers.zsh

### Git (20+ aliases)

Standard:

- [ ] `gs` - git status - Location: adhd-helpers.zsh
- [ ] `ga` - git add - Location: adhd-helpers.zsh
- [ ] `gc` - git commit - Location: adhd-helpers.zsh
- [ ] `gp` - git push - Location: adhd-helpers.zsh

Workflow:

- [ ] `qcommit` - Quick commit - Location: adhd-helpers.zsh
- [ ] `gundo` - Undo last commit - Location: adhd-helpers.zsh
- [ ] `smartgit` - Full git overview - Location: adhd-helpers.zsh

---

## 🏗️ Project Detection System

From `adhd-helpers.zsh:1667-1699`, `_proj_detect_type()` function:

### Detection Order

1. **Path-based** (highest priority):

   - `*/projects/teaching/*` → "teaching"
   - `*/projects/research/*` → "research" (with sub-types)
2. **File-based**:

   - `DESCRIPTION` file → "r" (R package)
   - `package.json` → "node"
   - `_quarto.yml` or `index.qmd` → "quarto"
   - `setup.py` or `pyproject.toml` → "python"
   - `.Rproj` → "r"
   - `Makefile` → "make"
3. **Fallback**: "generic"

### Project Type Icons

```zsh
r       → 📦 (R package)
dev     → 🔧 (Development tool)
teach   → 🎓 (Teaching/course)
rs      → 🔬 (Research)
q       → 📝📊 (Quarto manuscript/presentation)
app     → 📱 (Application)
mgmt    → ⚙️  (Management - proposed, not yet implemented)
```

---

## 📁 Project Structure

```
~/projects/
├── r-packages/
│   ├── active/          # Active development (medfit, mediationverse, etc.)
│   └── stable/          # Stable/production (rmediation)
├── dev-tools/           # 17 projects
│   ├── zsh-configuration/
│   ├── dev-planning/
│   ├── mcp-servers/
│   ├── aiterm/
│   └── ... (13 more)
├── quarto/
│   ├── manuscripts/
│   └── presentations/
├── teaching/            # 3 courses
│   ├── stat-440/
│   ├── causal-inference/
│   └── ...
├── research/            # 11 projects
│   ├── mediation-planning/
│   ├── collider/
│   └── ...
└── apps/                # 1 project
    └── examify/
```

---

## 🔄 Existing Workflows

### R Package Workflow (Primary)

From `WORKFLOWS-QUICK-WINS.md`:

1. **Quick Test** (`t`) - 5 min, 🟢 Easy
2. **Load + Test** (`lt`) - 5 min, 🟢 Easy
3. **Doc + Test** (`dt`) - 8 min, 🟢 Easy
4. **Full Check** (`rcycle`) - 60 min, 🟡 Medium
5. **Quick Commit** (`qcommit`) - 3 min, 🟢 Easy

### Session Management

- [ ] `work` - Start work session - Location: adhd-helpers.zsh
- [ ] `finish` - End work session (commit + merge prompt) - Location: adhd-helpers.zsh
- [ ] `now` - What am I working on? - Location: adhd-helpers.zsh
- [ ] `next` - What should I work on next? - Location: adhd-helpers.zsh

### Focus & Time Management

- [ ] `focus` - Start focus session - Location: adhd-helpers.zsh
- [ ] `unfocus` - End focus session - Location: adhd-helpers.zsh
- [ ] `worktimer` - Set work timer - Location: adhd-helpers.zsh
- [ ] `quickbreak` - Quick break timer - Location: adhd-helpers.zsh

### Dashboard & Status

- [ ] `dash` - Show all projects dashboard - Location: adhd-helpers.zsh
- [ ] `here` - Show current context - Location: adhd-helpers.zsh
- [ ] `progress_check` - Show progress bars - Location: adhd-helpers.zsh

---

## 🎨 Design Patterns

### Mnemonic Naming

- **Single letter** - Ultra-high frequency (`t`, `c`, `q`)
- **2-letter pairs** - Common sequences (`lt`, `dt`)
- **Prefix-based** - Logical grouping:
  - `r*` - R package commands (`rload`, `rtest`, `rdoc`)
  - `cc*` - Claude Code commands (`ccc`, `ccl`, `cch`)
  - `g*` - Git commands (`gs`, `ga`, `gc`)
  - `pick*` - Project picker filters (`pickr`, `pickdev`, `pickq`)

### ADHD-Optimized Principles

From design docs:

1. **Reduce cognitive load** - One command does one thing clearly
2. **Minimal keystrokes** - Single letters for frequent actions
3. **Visual feedback** - Icons, colors, clear output
4. **Context preservation** - `.STATUS` files, session tracking
5. **Undo-friendly** - Easy to reverse (`gundo`, `qcommit` safety)

---

## 🚫 What Does NOT Exist (Yet)

### Management Category

- **NOT implemented**: `mgmt` project type
- **NOT implemented**: Management section in `pick`
- **NOT implemented**: `PROJ_MANAGEMENT` array
- **Proposed**: Show meta/coordination projects first in `pick`

### Recent Projects Tracking

- **NOT implemented**: Project access log
- **NOT implemented**: Recent section in `pick`
- **NOT implemented**: Time-based sorting
- **Proposed**: Add "Recently Used" section

### AI Assistant Keybinds

- **NOT implemented**: Ctrl-C (claude) or Ctrl-G (gemini)
- **REJECTED**: User feedback - don't add without approval
- **Existing**: Ctrl-W (work), Ctrl-O (code) already handle editor launching

### Additional Aliases

- **NOT implemented**: `pm` (pick mgmt)
- **NOT implemented**: `pickcc` (pick with claude)
- **REJECTED**: Don't add aliases without approval

---

## 📝 Key Insights for Proposals

### What Works Well (Keep These Patterns)

1. **Filter system** - `pick <category>` is established and works
2. **Keybind pattern** - Ctrl-W/O/S/L are known and used
3. **Icon system** - Emojis for visual hierarchy (📦 🔧 🎓 🔬)
4. **Mnemonic aliases** - Short + memorable = high adoption
5. **Session tracking** - `PROJ_SESSION_FILE` infrastructure exists

### What to Avoid

1. **New keybinds** - Existing Ctrl-W/O/S/L sufficient
2. **New aliases** - Need user approval first
3. **Breaking changes** - Must be backward compatible
4. **Over-engineering** - KISS principle (keep it simple)

### Opportunities

1. **Reuse filter system** - `pick mgmt` follows existing pattern
2. **Leverage session file** - Can track recent projects
3. **Extend category array** - `PROJ_MANAGEMENT` parallel to `PROJ_CATEGORIES`
4. **Use existing icons** - ⚙️  for management type
5. **Follow help patterns** - `ah workflow` for documentation

---

## 🎯 How Proposals Fit

### PROPOSAL-PICK-ENHANCEMENTS.md (Management Section)

**Fits existing patterns:**

- ✅ Uses existing filter system (`pick mgmt`)
- ✅ Follows category icon pattern (⚙️ )
- ✅ Parallels `PROJ_CATEGORIES` structure
- ✅ No new keybinds needed (uses existing Ctrl-W/O/S/L)
- ✅ Backward compatible (adds section, doesn't change existing)

**Requires:**

- New `PROJ_MANAGEMENT` array (5 projects)
- Modify `_proj_list_all()` to output management first
- Add "mgmt" to category normalization

**Estimated complexity:** Medium (2-3 hours)

### PROPOSAL-PICK-RECENT-SECTION.md (Recently Used)

**Fits existing patterns:**

- ✅ Uses existing session tracking (`PROJ_SESSION_FILE`)
- ✅ Follows section display pattern (like management)
- ✅ Can reuse icon system (🕐 for time)
- ✅ Natural evolution of `worklog` infrastructure

**Requires:**

- New `PROJ_ACCESS_LOG` file (`~/.project-access-log`)
- New `_proj_recent()` function
- Modify `_proj_list_all()` to output recent first
- Add access tracking on every `pick` action

**Estimated complexity:** Medium-High (3-4 hours for basic, +2-3 for smart ranking)

**Recommendation order:**

1. Implement management section FIRST (simpler, high value)
2. Collect usage data (which management projects used most?)
3. Implement recent section SECOND (builds on management)

---

## 📚 Standard Documents Referenced

1. **ALIAS-REFERENCE-CARD.md** - Complete alias catalog
2. **WORKFLOWS-QUICK-WINS.md** - Top 10 ADHD-friendly workflows
3. **PROJECT-HUB.md** - Strategic roadmap
4. **dev-planning/TOOL-INVENTORY.md** - 17 dev-tools breakdown
5. **dev-planning/PROJECT-HUB.md** - Domain coordination hub
6. **adhd-helpers.zsh** - Implementation (3034 lines)

---

**Last Updated:** 2025-12-19 14:20
**Purpose:** Reference for all proposals - ensures new features fit existing patterns
**Maintainer:** Update when system architecture changes
