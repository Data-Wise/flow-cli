# Flow CLI

**Minimalist ZSH workflow tools with smart dispatchers**

A streamlined system for managing development workflows. Features **28 essential aliases**, **6 smart dispatchers**, and **226+ git aliases** (via plugin). Optimized for muscle memory over memorization.

---

## ⚡ Quick Stats

- **Custom aliases:** 28 (down from 179)
- **Reduction:** 84% fewer aliases to memorize
- **Git plugin:** 226+ standard aliases included
- **Smart dispatchers:** 6 context-aware functions
- **Documentation:** 102 markdown files, 60+ pages on site
- **Architecture:** Clean Architecture with 3 ADRs
- **Last major update:** 2025-12-21 (Architecture + Site)

---

## 🚀 Quick Start

### 1. Learn the Core Aliases

**R Package Development (23 aliases)**

Master these 6 first:
```bash
rload    # Load package code
rtest    # Run tests
rdoc     # Generate docs
rcheck   # R CMD check
rbuild   # Build package
rinstall # Install package
```

**Claude Code (2 aliases)**
```bash
ccp      # Claude print mode
ccr      # Claude resume
```

**Focus Timers (2 aliases)**
```bash
f25      # 25-minute Pomodoro
f50      # 50-minute deep work
```

### 2. Use Smart Dispatchers

Instead of memorizing more aliases, use context-aware functions:

```bash
cc       # Project-aware Claude
gm       # Project-aware Gemini
peek     # Smart file viewer
qu       # Quarto operations
work     # Start work session
pick     # Project picker
```

### 3. Git Plugin Aliases

Standard OMZ git plugin provides 226+ aliases:
```bash
g        # git
gst      # git status
ga       # git add
gcmsg    # git commit -m
gp       # git push
glo      # git log --oneline
```

---

## 📚 Essential Documentation

!!! tip "Start Here"
    **New to this project?** Read the [Quick Start Guide](getting-started/quick-start.md) in 5 minutes!

### Core Guides

- **[Quick Start Guide](getting-started/quick-start.md)** - Get running in 5 minutes
- **[Alias Reference Card](user/ALIAS-REFERENCE-CARD.md)** - All 28 aliases + migration guide
- **[Workflow Quick Reference](user/WORKFLOW-QUICK-REFERENCE.md)** - Daily workflows
- **[Complete Documentation Index](doc-index.md)** - All docs organized

### Architecture & Design

- **[Architecture Hub](architecture/README.md)** - Complete architecture documentation (6,200+ lines)
- **[Architecture Quick Reference](architecture/QUICK-REFERENCE.md)** - 1-page printable desk reference
- **[Architecture Quick Wins](architecture/ARCHITECTURE-QUICK-WINS.md)** - Practical patterns for daily use
- **[Architecture Decisions (ADRs)](architecture/decisions/README.md)** - 3 decision records explaining "why"

### Specialized Guides

- **[Pick Command Reference](user/PICK-COMMAND-REFERENCE.md)** - Project navigation
- **[Dashboard Quick Ref](user/DASHBOARD-QUICK-REF.md)** - Dashboard commands
- **[Workflows & Quick Wins](user/WORKFLOWS-QUICK-WINS.md)** - Productivity tips

---

## 🎯 Recent Updates

### December 21, 2025 - Architecture Documentation Sprint

**Completed comprehensive architecture documentation:**

- ✅ **6,200+ lines** of architecture documentation across 21 files
- ✅ **3 ADRs** (Architecture Decision Records) documenting key decisions
- ✅ **88+ code examples** ready to copy-paste
- ✅ **Documentation site** updated with 60+ pages
- ✅ **Architecture Reference Suite** (5 docs, 2,567 lines) for reuse across projects

**New Guides:**

- [Architecture Patterns Analysis](architecture/ARCHITECTURE-PATTERNS-ANALYSIS.md) - Clean Architecture deep dive (1,181 lines)
- [API Design Review](architecture/API-DESIGN-REVIEW.md) - Node.js API best practices (919 lines)
- [Code Examples](architecture/CODE-EXAMPLES.md) - Production-ready patterns (1,000+ lines)
- [Vendor Integration Architecture](architecture/VENDOR-INTEGRATION-ARCHITECTURE.md) - External code integration (673 lines)

**Live Site:** [https://Data-Wise.github.io/flow-cli/](https://Data-Wise.github.io/flow-cli/)

---

## 📊 What Changed (2025-12-19)

!!! warning "Major Cleanup"
    Reduced from **179 to 28 aliases** (84% reduction) based on user feedback about cognitive load.

### The Problem
User reported: "I cannot memorize that many" referring to 179 custom aliases.

### The Solution
Aggressive cleanup retaining only high-frequency daily-use commands.

### What Was Removed

**11 categories eliminated (151 aliases total):**

| Category | Count | Replacement |
|----------|-------|-------------|
| Typo corrections | 13 | Type correctly |
| Low-frequency shortcuts | 25 | Full commands |
| Single-letter aliases | 4 | Explicit names |
| Duplicate aliases | 12 | Canonical names |
| Navigation aliases | 10 | `pick` dispatcher |
| Workflow shortcuts | 30 | Full commands |
| Meta-aliases | 7 | Direct calls |
| Peek shortcuts | 5 | `peek` dispatcher |
| Work shortcuts | 10 | `work` command |
| Breadcrumb aliases | 4 | Full commands |
| Tool replacements | 2 | Direct commands |
| Git aliases | 5 | Plugin (226+) |
| Emacs aliases | 2 | Direct commands |

---

## 🎯 Design Philosophy

### Before → After

| Aspect | Before | After |
|--------|--------|-------|
| **Philosophy** | ADHD-friendly with typo tolerance | Minimalist with muscle memory |
| **Alias count** | 179 custom aliases | 28 essential aliases |
| **Git support** | 5 custom aliases | 226+ standard plugin |
| **Approach** | Many shortcuts for everything | Smart dispatchers + patterns |

### Key Principles

1. **Muscle memory over memorization** - Keep only daily-use commands
2. **Patterns over individual** - `r*` pattern easier than 23 aliases
3. **Standard over custom** - Use community standards (git plugin)
4. **Functions over aliases** - Smart behavior > static shortcuts
5. **Explicit over implicit** - Full commands > cryptic shortcuts

---

## 🔄 Migration Guide

!!! info "For Existing Users"
    If you used the old 179-alias system, see the complete migration guide in [Alias Reference Card](user/ALIAS-REFERENCE-CARD.md).

### Common Changes

| Old Alias | New Approach |
|-----------|--------------|
| `e` / `ec` | `emacs` or `emacsclient -c -a ''` |
| `find` | `fd` (direct command) |
| `grep` | `rg` (direct command) |
| `cdrpkg` | `pick` or `cd ~rpkg` |
| `ccplan` | `claude --permission-mode plan` |
| `peekr` | `peek <file>` or `bat --language=r` |
| `stuck` | `just-start` |
| `wn` | `what-next` |
| All typos | Type correctly! |

### Git Workflow
- **Before:** 5 custom git aliases
- **After:** 226+ standard OMZ git plugin aliases
- **Benefit:** Standard across all OMZ users, better documentation

---

## 🎓 Learning Path

### Day 1: Essentials
1. Read [Alias Reference Card](user/ALIAS-REFERENCE-CARD.md)
2. Master 6 core R aliases (rload, rtest, rdoc, rcheck, rbuild, rinstall)
3. Learn 2 Claude aliases (ccp, ccr)
4. Try dispatchers (cc, pick, peek)

### Week 1: Workflows
1. Read [Workflow Quick Reference](user/WORKFLOW-QUICK-REFERENCE.md)
2. Practice daily workflows
3. Learn git plugin aliases (gst, ga, gcmsg, gp)
4. Set up focus timers (f25, f50)

### Month 1: Mastery
1. Customize for your workflow
2. Add aliases only if >10 uses/day
3. Share feedback for improvements

---

## 🛠️ Contributing

### Reporting Issues
Create `.md` files in root or `docs/` directory with issue details.

### Adding New Aliases

!!! warning "Think Before Adding"
    Before adding new aliases, ensure they meet ALL criteria:

**Checklist:**
- [ ] Used 10+ times per day?
- [ ] Saves significant typing (10+ characters)?
- [ ] Follows clear pattern (`r*`, `cc*`, `f*`)?
- [ ] Can't be handled by dispatcher function?

---

## 📖 Additional Resources

- **[Complete Documentation Index](doc-index.md)** - All docs organized
- **[ZSH Development Guidelines](ZSH-DEVELOPMENT-GUIDELINES.md)** - Coding standards
- **[OMZ Git Plugin](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git)** - Git aliases reference

---

**Last updated:** 2025-12-19
**Maintainer:** DT
**Repository:** [GitHub](https://github.com/Data-Wise/flow-cli)
