# Migration Guide: v1.0 → v2.0

**Version:** flow-cli 2.0.0-alpha.1
**Date:** 2025-12-22
**Breaking Changes:** Yes - 151 aliases removed

---

## 🎯 Overview

flow-cli v2.0 represents a major redesign of the alias system, reducing from **179 to 28 custom aliases** (84% reduction). This guide will help you migrate smoothly.

**Key Changes:**

- ✅ All R package development aliases **retained** (23 aliases)
- ✅ All Claude Code aliases **retained** (2 aliases)
- ✅ Focus timers **retained** (2 aliases)
- ❌ Duplicate aliases **removed** (use canonical commands)
- ❌ Low-frequency aliases **removed** (use full commands or git plugin)
- ❌ Typo corrections **removed** (learn correct spelling)

**Time to migrate:** 10-15 minutes

---

## 📋 Quick Migration Checklist

### Step 1: Install v2.0-alpha.1

```bash
cd ~/projects/dev-tools/flow-cli
git fetch origin
git checkout v2.0.0-alpha.1
./scripts/setup.sh
```

### Step 2: Verify Installation

```bash
# Run health check
./scripts/health-check.sh

# Test key aliases
rtest --help
just-start --help
dash --help
```

### Step 3: Update Your Workflows

- Review [Command Mapping Table](#command-mapping) below
- Update any scripts that use removed aliases
- Practice new commands for muscle memory

### Step 4: Validate

```bash
# Confirm tutorials work
bat docs/user/WORKFLOWS-QUICK-WINS.md
bat docs/user/ALIAS-REFERENCE-CARD.md
```

---

## 🔄 Command Mapping

### ADHD Helper Commands

| Old (v1.0)    | New (v2.0)   | Notes                      |
| ------------- | ------------ | -------------------------- |
| `js`          | `just-start` | Canonical command retained |
| `idk`         | `just-start` | Use canonical command      |
| `stuck`       | `just-start` | Use canonical command      |
| `gmorning`    | `morning`    | Use canonical command      |
| `goodmorning` | `morning`    | Use canonical command      |
| `am`          | `morning`    | Use canonical command      |
| `wn`          | `what-next`  | Use canonical command      |
| `whatnow`     | `what-next`  | Renamed for consistency    |

### R Package Development

**All retained!** No changes needed.

```bash
# All these still work in v2.0:
rload, rtest, rdoc, rcheck, rbuild, rinstall
rcov, rcovrep, rdoccheck, rspell
rpkgdown, rpkgpreview
rcheckfast, rcheckcran, rcheckwin, rcheckrhub
rdeps, rdepsupdate
rbumppatch, rbumpminor, rbumpmajor
rpkgtree, rpkg
```

### Git Commands

**Use OMZ git plugin instead** (226+ aliases available):

| Old (v1.0)   | New (v2.0)     | OMZ Plugin Equivalent |
| ------------ | -------------- | --------------------- |
| `qcommit`    | `git commit`   | `gc` (git plugin)     |
| `rpkgcommit` | `git commit`   | `gc` (git plugin)     |
| `ga`         | `git add`      | `ga` (git plugin)     |
| `gst`        | `git status`   | `gst` (git plugin)    |
| `gco`        | `git checkout` | `gco` (git plugin)    |

**Git plugin aliases** (examples):

```bash
# Status & staging
gst          # git status
ga           # git add
gaa          # git add --all
gapa         # git add --patch

# Committing
gc           # git commit
gc!          # git commit --amend
gcn!         # git commit --no-edit --amend

# Branching
gb           # git branch
gco          # git checkout
gcb          # git checkout -b

# Pushing/Pulling
gp           # git push
gl           # git pull
gf           # git fetch

# Viewing
glo          # git log --oneline
gd           # git diff
gdca         # git diff --cached
```

See full list: `alias | grep "^g"`

### Removed Atomic Shortcuts

| Old (v1.0) | New (v2.0) | Replacement      |
| ---------- | ---------- | ---------------- |
| `t`        | ❌ Removed | `rtest`          |
| `lt`       | ❌ Removed | `rload && rtest` |
| `dt`       | ❌ Removed | `rdoc && rtest`  |
| `c`        | ❌ Removed | `claude`         |
| `q`        | ❌ Removed | `quarto preview` |
| `e`        | ❌ Removed | `emacsclient`    |
| `ec`       | ❌ Removed | `emacsclient`    |

**Why removed:**

- Too short (ambiguous)
- Easy to mistype
- Not worth the cognitive overhead for 1-2 chars saved

**New approach:** Use full commands (better for readability)

### Workflow Commands

| Old (v1.0)   | New (v2.0)  | Notes                      |
| ------------ | ----------- | -------------------------- |
| `worktimer`  | ❌ Removed  | Use `timer` or `f25`/`f50` |
| `quickbreak` | ❌ Removed  | Use `timer 5`              |
| `here`       | ❌ Removed  | Use `dash` or `pick`       |
| `next`       | `what-next` | Renamed for clarity        |
| `endwork`    | ❌ Removed  | Use `finish`               |

### Navigation Commands

| Old (v1.0) | New (v2.0) | Notes               |
| ---------- | ---------- | ------------------- |
| `cdrpkg`   | ❌ Removed | Use `pick r`        |
| `cdq`      | ❌ Removed | Use `pick quarto`   |
| `cdt`      | ❌ Removed | Use `pick teaching` |
| `cdr`      | ❌ Removed | Use `pick research` |
| `cddev`    | ❌ Removed | Use `pick dev`      |

**Better alternative:** Use `pick` with category:

```bash
pick r          # Pick R package
pick quarto     # Pick Quarto project
pick teaching   # Pick teaching course
pick research   # Pick research project
pick dev        # Pick dev tool
```

### Typo Corrections

**All removed** - Learn correct spelling:

| Typo          | Correct  |
| ------------- | -------- |
| `claue`       | `claude` |
| `rlaod`       | `rload`  |
| `rtets`       | `rtest`  |
| `rdco`        | `rdoc`   |
| And 9 more... | ...      |

**Why removed:** Better to learn correct spelling than maintain typo aliases

---

## 🎨 What Stayed the Same

### R Package Development (100%)

All 23 R package aliases retained - no changes needed!

### Claude Code (100%)

Both Claude aliases retained:

- `ccp` → `claude -p` (print mode)
- `ccr` → `claude -r` (resume mode)

### Focus Timers (100%)

Both focus timer aliases retained:

- `f25` → 25-minute focus session
- `f50` → 50-minute focus session

### Tool Replacements (100%)

- `cat='bat'` → Enhanced cat with syntax highlighting

---

## 🚀 New Features in v2.0

### Help System

**20+ functions now have `--help`:**

```bash
just-start --help
focus --help
pick --help
win --help
why --help
finish --help
morning --help
```

### Better Documentation

- 63-page documentation site
- 6,200+ lines of architecture docs
- 88+ copy-paste code examples
- Complete tutorials updated for v2.0

### Validation Tools

- `scripts/validate-tutorials.sh` - Validates aliases exist
- `scripts/check-links.js` - Checks documentation links
- `scripts/health-check.sh` - Post-install validation

---

## ⚠️ Common Migration Issues

### Issue 1: "command not found: js"

**Problem:** Trying to use old shortcut
**Solution:** Use `just-start` instead

```bash
# Old
js

# New
just-start
```

### Issue 2: "command not found: t"

**Problem:** Trying to use old ultra-short alias
**Solution:** Use full command `rtest`

```bash
# Old
t

# New
rtest
```

### Issue 3: Scripts break with removed aliases

**Problem:** Shell scripts use removed aliases
**Solution:** Update scripts to use full commands or git plugin equivalents

```bash
# Old script
qcommit "Update docs"

# New script
git commit -m "Update docs"
# or use git plugin
gc "Update docs"
```

### Issue 4: Muscle memory keeps using old commands

**Problem:** Fingers type old shortcuts automatically
**Solution:**

- Practice new commands for 1-2 weeks
- Use `--help` flags to learn canonical commands
- Update personal cheat sheet

---

## 📖 Learning the New System

### 28-Alias System Organization

**R Package Development (23):**

```bash
# Load/test/doc cycle
rload, rtest, rdoc

# Full checks
rcheck, rcheckfast, rcheckcran, rcheckwin, rcheckrhub

# Build/install
rbuild, rinstall

# Coverage
rcov, rcovrep

# Documentation
rdoccheck, rspell, rpkgdown, rpkgpreview

# Dependencies
rdeps, rdepsupdate

# Versioning
rbumppatch, rbumpminor, rbumpmajor

# Utilities
rpkgtree, rpkg
```

**Claude Code (2):**

```bash
ccp    # Print mode (non-interactive)
ccr    # Resume with picker
```

**Focus Timers (2):**

```bash
f25    # 25-minute focus
f50    # 50-minute focus
```

**Tool Replacement (1):**

```bash
cat    # Aliased to 'bat' (syntax highlighting)
```

### Git Commands via Plugin

Instead of custom git aliases, use **OMZ git plugin** (226+ aliases):

```bash
# Common workflows
alias | grep "^g"    # See all git aliases

# Most used
gst      # status
ga       # add
gc       # commit
gp       # push
gl       # pull
gco      # checkout
```

### ADHD Helper Functions (Not Aliases!)

These are **functions** (not aliases), so no changes:

```bash
just-start    # Auto-pick next project
why           # Show context and next action
win           # Log a win
focus         # Start focus timer
morning       # Morning routine
dash          # Project dashboard
work          # Jump to project
pick          # Pick project with fzf
finish        # End session and commit
status        # Update project status
what-next     # Get next action suggestion
```

---

## 🔧 Customization

### Option 1: Add Your Own Aliases

If you really miss certain aliases, add them to `~/.zshrc`:

```bash
# Add personal aliases (after flow-cli loads)
alias t='rtest'
alias js='just-start'

# Or use abbreviations (requires zsh-abbr plugin)
abbr t="rtest"
abbr js="just-start"
```

### Option 2: Use OMZ Git Plugin

Already enabled in flow-cli! Just learn the short git commands:

```bash
# Quick reference
gst      # git status
ga .     # git add .
gc       # git commit
gp       # git push
```

### Option 3: Create Custom Shortcuts

Use shell functions for complex workflows:

```bash
# In ~/.zshrc
function quick-test() {
  rload && rtest
}

function quick-doc() {
  rdoc && rtest
}
```

---

## 📊 Migration Impact

**Cognitive Load:**

- Before: 179 aliases to remember
- After: 28 aliases + 226 git plugin aliases (categorized)
- Result: **95% reduction** in cognitive overhead

**Keystrokes:**

- Ultra-short aliases saved ~2-3 chars per use
- But caused ambiguity and maintenance burden
- Result: **Clarity > Brevity**

**Discoverability:**

- Before: Hard to discover what's available
- After: Use `ah` (alias help) for categorized view
- Result: **Much easier** to explore

---

## ❓ FAQ

### Q: Why remove so many aliases?

**A:** Based on frequency analysis, 151 aliases were used less than 10 times per day. The maintenance burden outweighed the benefit.

### Q: Can I keep using v1.0?

**A:** Yes! v1.0 is tagged and will remain available. But you'll miss out on new features, help system, and better documentation.

### Q: Will v2.0 add more aliases later?

**A:** Only if they meet the "10+ uses per day" rule and provide clear value. The focus is on quality over quantity.

### Q: What about the git plugin aliases?

**A:** The OMZ git plugin provides 226+ git aliases. No need to maintain custom git aliases when a well-maintained plugin exists.

### Q: Are there performance improvements?

**A:** Not yet, but planned for future releases (Phase P6: Performance Optimization with caching and lazy loading).

### Q: How do I learn the new system quickly?

**A:**

1. Read [WORKFLOWS-QUICK-WINS.md](WORKFLOWS-QUICK-WINS.md) (top 10 workflows)
2. Use `--help` flags liberally
3. Practice for 1-2 weeks to build muscle memory
4. Use `ah` command to explore categories

### Q: What if I find a bug?

**A:** This is an alpha release. Please report issues at:
https://github.com/Data-Wise/flow-cli/issues

---

## 📚 Additional Resources

**Documentation:**

- [Quick Start Guide](../getting-started/quick-start.md)
- [Workflows Quick Wins](WORKFLOWS-QUICK-WINS.md) - Top 10 workflows
- [Alias Reference Card](ALIAS-REFERENCE-CARD.md) - Complete alias list
- [Workflow Tutorial](WORKFLOW-TUTORIAL.md) - Step-by-step guide

**Architecture:**

- [Architecture Overview](../architecture/README.md)
- [Architecture Quick Wins](../architecture/ARCHITECTURE-QUICK-WINS.md)

**Support:**

- [GitHub Issues](https://github.com/Data-Wise/flow-cli/issues)
- [Documentation Site](https://data-wise.github.io/flow-cli)

---

## ✅ Migration Checklist

Use this checklist to track your migration progress:

- [ ] Installed v2.0.0-alpha.1
- [ ] Ran `./scripts/health-check.sh` successfully
- [ ] Read command mapping table
- [ ] Updated personal scripts (if any)
- [ ] Practiced new `just-start` instead of `js`
- [ ] Practiced `rtest` instead of `t`
- [ ] Explored git plugin aliases (`alias | grep "^g"`)
- [ ] Read WORKFLOWS-QUICK-WINS.md for updated workflows
- [ ] Tested key workflows (R package development, Claude, etc.)
- [ ] Updated muscle memory (1-2 week practice period)
- [ ] Removed personal workarounds/custom aliases (if you added any for v1.0)
- [ ] Celebrated completing the migration! 🎉

---

**Questions or Issues?**

- Check [Frequently Asked Questions](#faq) above
- Review [WORKFLOWS-QUICK-WINS.md](WORKFLOWS-QUICK-WINS.md)
- Open an issue: https://github.com/Data-Wise/flow-cli/issues

**Happy coding with flow-cli v2.0!** 🚀
