# Command Integration Analysis

**Date:** 2025-12-16
**Purpose:** Analyze new fzf helper commands vs existing aliases/functions

---

## 📊 Summary of New Commands

### Tools Added

1. **atuin** - History manager (Ctrl+R, atuin search)
2. **direnv** - Auto environment loader (direnv allow)
3. **15 fzf helpers** - Interactive fuzzy finders

---

## 🔍 Conflict & Integration Analysis

### ✅ NO CONFLICTS FOUND

All 15 new fzf helper commands use **unique names** that don't conflict with existing aliases or functions.

---

## 📦 New Commands vs Existing Workflows

### R Package Development

#### NEW fzf helpers

| New  | Description          | Existing Equivalent                   | Integration                           |
| ---- | -------------------- | ------------------------------------- | ------------------------------------- |
| `re` | Fuzzy find R files   | Manual navigation + `vim R/file.R`    | ✅ **Complements** - Faster discovery |
| `rt` | Fuzzy run test       | `rtestfile tests/testthat/test-foo.R` | ✅ **Enhances** - Interactive picker  |
| `rv` | Fuzzy find vignettes | Manual `vim vignettes/foo.Rmd`        | ✅ **New capability**                 |

**Workflow Integration:**

```bash
# OLD workflow
cd ~/projects/r-packages/active/medfit
ls R/                    # See files
vim R/fit.R             # Open file
rtest                    # Run all tests

# NEW workflow (optional, coexists)
fr                       # Jump to package (fuzzy)
re                       # Pick R file to edit (fuzzy)
rt                       # Pick specific test (fuzzy)
```

**Recommendation:** ✅ **Keep both** - fzf helpers add discoverability, existing commands keep speed

---

### Project Status & Navigation

#### NEW fzf helpers

| New  | Description            | Existing Equivalent       | Integration                                |
| ---- | ---------------------- | ------------------------- | ------------------------------------------ |
| `fs` | Fuzzy find .STATUS     | `pstatlist` + manual edit | ✅ **Enhances** - Interactive with preview |
| `fh` | Fuzzy find PROJECT-HUB | Manual navigation         | ✅ **New capability**                      |
| `fp` | Fuzzy find projects    | `z` / `@bookmarks` + `ls` | ⚠️ **Overlaps** with `z`                   |
| `fr` | Fuzzy find R packages  | `@rpkg` + `ls` / `z rpkg` | ⚠️ **Overlaps** with workflow              |

**Existing .STATUS workflow:**

```bash
# Current
pstat                    # Scan all .STATUS
pstatlist                # List .STATUS files
pstatview                # View formatted
vim ~/projects/.../medfit/.STATUS  # Edit manually

# New option
fs                       # Fuzzy find + preview + edit
```

**Analysis:**

- `fs` is **much faster** than `pstatlist` → manual edit
- `fp` and `fr` **overlap** with `z` / `@bookmarks` but add **preview** capability
- Tradeoff: Speed (z/bookmarks) vs Discovery (fp/fr with preview)

**Recommendation:**

- ✅ **Keep `fs`** - Clear win over manual workflow
- ⚠️ **Consider renaming `fp`/`fr`** or positioning as "discovery" tools for when you "forgot what's there"

---

### Git Workflows

#### NEW fzf helpers

| New          | Description           | Existing Equivalent        | Conflict?                         |
| ------------ | --------------------- | -------------------------- | --------------------------------- |
| `gb`         | Fuzzy checkout branch | `git checkout <branch>`    | ✅ **Complements**                |
| `gdf`        | Interactive diff      | `git diff`                 | ✅ **Complements**                |
| `gshow`      | Fuzzy git log         | `glog` (alias for git log) | ⚠️ **Similar name**               |
| `ga`         | Interactive stage     | `git add`                  | ⚠️ **Overlaps** with common alias |
| `gundostage` | Interactive unstage   | `git reset HEAD`           | ✅ **New capability**             |

**Existing git aliases:**

```bash
gs='git status -sb'
glog='git log --oneline --graph --decorate --all'
gloga='git log --oneline --graph --decorate --all --author'
gundo='git reset --soft HEAD~1'
```

**Conflicts:**

- **`gshow`** is similar to **`glog`** but different purpose (interactive browse vs display)
- **`ga`** might conflict with common git alias patterns (though not defined in your config)

**Workflow comparison:**

```bash
# OLD git workflow
git status
git add R/file.R tests/test-file.R
git commit -m "..."

# NEW option (coexists)
gs                       # Still works
ga                       # Interactive picker with preview
git commit -m "..."
```

**Recommendation:**

- ✅ **Keep `gb`** - Huge win for branch switching
- ✅ **Keep `gdf`** - Interactive diff is valuable
- ⚠️ **Consider renaming `gshow`** to `gfl` (git fuzzy log) to distinguish from `glog`
- ⚠️ **Keep `ga`** - You don't have a `ga` alias defined, but be aware of conventions

---

## 🎯 Integration Recommendations

### Tier 1: Clear Wins (Keep As-Is)

These add **new capability** or are **significantly better** than existing workflows:

| Command      | Why Keep                       | ADHD Value |
| ------------ | ------------------------------ | ---------- |
| `re`         | Discovery of R files           | ⭐⭐⭐⭐⭐ |
| `rt`         | Interactive test runner        | ⭐⭐⭐⭐⭐ |
| `fs`         | Faster than pstatlist workflow | ⭐⭐⭐⭐⭐ |
| `gb`         | Branch switching with preview  | ⭐⭐⭐⭐⭐ |
| `gdf`        | Interactive diff               | ⭐⭐⭐⭐   |
| `gundostage` | New capability                 | ⭐⭐⭐     |

### Tier 2: Overlaps But Adds Value

These **overlap** with existing tools but add **preview/discovery** value:

| Command | Overlaps With     | When to Use New        | When to Use Old         |
| ------- | ----------------- | ---------------------- | ----------------------- |
| `fp`    | `z`, `@bookmarks` | "What projects exist?" | "Jump to known project" |
| `fr`    | `@rpkg`, `z rpkg` | "Browse R packages"    | "Jump to known package" |

**Recommendation:** Position as **discovery tools** vs **speed tools**

- **Fast/known:** Use `z medfit` or `@medfit` (muscle memory)
- **Discovery/forgot:** Use `fp` or `fr` (visual preview)

### Tier 3: Naming Conflicts to Consider

| Command | Issue                       | Suggested Fix                            |
| ------- | --------------------------- | ---------------------------------------- |
| `gshow` | Similar to `glog`           | Rename to `gfl` (git fuzzy log) or `glf` |
| `ga`    | Common git alias convention | Keep but document                        |

---

## 💡 Suggested Changes

### 1. Rename `gshow` → `glf` (git log fuzzy)

**Rationale:**

- Avoids confusion with `glog`
- More descriptive: "git log fuzzy"
- Follows pattern: `gl` prefix = git log

```bash
# Change in fzf-helpers.zsh
glf() {  # was gshow()
    # ... same implementation
}
```

### 2. Position `fp`/`fr` as Discovery Tools

Update documentation to clarify:

- **Speed navigation:** `z`, `@bookmarks` (when you know where you're going)
- **Discovery navigation:** `fp`, `fr` (when browsing, exploring, forgot)

### 3. Add Aliases for Common Patterns

Based on your existing alias patterns, consider:

```bash
# Ultra-short aliases (if heavily used)
alias e='re'     # Edit (R file)
alias t='rt'     # Test (fuzzy)

# Or keep longer names for discoverability
```

**Recommendation:** Wait and see which ones you use frequently before aliasing

---

## 🔄 Integration with Existing Workflows

### Morning Workflow

```bash
# Existing
gm                       # Morning kickstart (from adhd-helpers)
wn                       # What-next AI suggestion

# Enhanced with new tools
fs                       # Pick .STATUS to update
Ctrl+R → "what-next"     # Find last what-next command via atuin
```

### R Package Development Workflow

```bash
# Existing
@medfit                  # Jump to package
status                   # Check .STATUS
rload && rtest          # Load & test

# Enhanced
fr                       # If you forgot which package (discovery)
re                       # If you forgot which file (discovery)
rt                       # If you want specific test (precision)
```

### Git Workflow

```bash
# Existing
gs                       # Git status
git add <files>
git commit -m "..."

# Enhanced
gs
ga                       # Interactive staging with preview
git commit -m "..."
```

---

## 📊 Command Usage Prediction

Based on ADHD-friendly design and your workflows:

### High Usage Potential (⭐⭐⭐⭐⭐)

- `fs` - Editing .STATUS files (daily task)
- `re` - Finding R files (when can't remember name)
- `gb` - Switching branches (visual preview helps)
- `Ctrl+R` (atuin) - History search (constant need)

### Medium Usage (⭐⭐⭐)

- `rt` - Running specific tests (when debugging)
- `fp`/`fr` - When exploring/discovering (less frequent)
- `gdf` - Reviewing changes before commit

### Lower Usage (⭐⭐)

- `rv` - Vignettes (if you write many vignettes)
- `fh` - PROJECT-HUB (less frequent access)
- `gshow` - Git log browsing (nice-to-have)

---

## ✅ Final Recommendations

### Do This Now

1. ✅ **Keep all commands as-is** - No critical conflicts
2. ✅ **Try for 1 week** - See what you actually use
3. ✅ **Document as "discovery tools"** vs "speed tools"

### Consider After 1 Week

1. Rename `gshow` → `glf` if confusion occurs
2. Add ultra-short aliases for heavily-used commands
3. Remove any commands you never use

### Integration Strategy

- **Coexistence:** New fzf helpers **complement** existing aliases (not replace)
- **Use case split:**
  - Known destination → Use `z`, `@bookmarks` (fast)
  - Discovery/forgot → Use `fp`, `fr`, `fs`, `re` (visual)
  - Git operations → Use new `gb`, `ga`, `gdf` (preview helps decision-making)

---

## 🎯 Quick Reference: When to Use What

| Goal              | Fast Method                  | Discovery Method       |
| ----------------- | ---------------------------- | ---------------------- |
| Jump to R package | `@medfit` or `z medfit`      | `fr` (browse all)      |
| Edit R file       | `vim R/fit.R`                | `re` (browse all)      |
| Run test          | `rtest` (all) or `rtestfile` | `rt` (pick one)        |
| Edit .STATUS      | `vim ~/path/.STATUS`         | `fs` (browse all)      |
| Checkout branch   | `git checkout <branch>`      | `gb` (browse all)      |
| Stage files       | `git add <file>`             | `ga` (preview & pick)  |
| Search history    | Up arrow                     | `Ctrl+R` (atuin fuzzy) |

---

**Status:** ✅ No critical issues
**Action:** Try for 1 week, then refine based on usage patterns
**Updated:** 2025-12-16
