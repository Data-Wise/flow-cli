# Workflow Quick Reference

**Date:** 2025-12-14 (Updated 2025-12-26)
**Version:** 3.1 - Doctor Command & Man Pages

> **✨ New in v3.1.0 (2025-12-26):**
>
> - `flow doctor` - Dependency verification with --fix, --fix -y, --ai modes
> - Comprehensive man pages: `man flow`, `man r`, `man g`, `man qu`, `man mcp`, `man obs`
> - 6 active dispatchers (added `cc` for Claude Code workflows)
>
> **Previous (v2.0):**
>
> - `flow status` - ASCII visualizations, worklog integration, productivity metrics
> - `flow dashboard` - Interactive real-time TUI with keyboard shortcuts
> - Removed deprecated `v`/`vibe` dispatcher - use `flow` command directly
> - See `ALIAS-REFERENCE-CARD.md` for current aliases (28 total)
> - See `DISPATCHER-REFERENCE.md` for active dispatchers (6 total: g, mcp, obs, qu, r, cc)

---

## 🎯 THE BIG THREE (Master Commands)

### 1. `dash` - See Everything

**Show all work:**

```bash
dash                 # All projects
dash teaching        # Teaching only
dash research        # Research only
dash packages        # R packages only
```

**ADHD Score:** 9/10 - <5 second scan

### 2. `status` - Update Projects

**Interactive:**

```bash
status mediationverse
```

**Quick:**

```bash
status medfit active P1 "Add vignette" 60
```

**ADHD Score:** 8/10 - No manual editing

### 3. `js` - Just Start

```bash
js              # Picks P0, then P1, then active
```

**ADHD Score:** 9/10 - Zero decisions

---

## 📋 .STATUS Format

```yaml
project: name
status: active|ready|paused|blocked
priority: P0|P1|P2
progress: 0-100
next: task description
```

---

## 🚀 Quick Workflows

**Start day:**

```bash
dash → js
```

**Update status:**

```bash
status <name> active P0 "Task" 75
```

**Switch projects:**

```bash
dash teaching → work stat-440
```

---

## 🔧 Setup & Diagnostics

**Check your environment:**

```bash
flow doctor              # Check all dependencies
flow doctor --fix        # Interactive install missing
flow doctor --fix -y     # Auto-install all
```

**First-time setup:**

```bash
brew bundle --file=~/projects/dev-tools/flow-cli/setup/Brewfile
flow doctor              # Verify installation
```

---

**Full guide:** `WORKFLOW-ANALYSIS-2025-12-14.md`
**Man pages:** `man flow`, `man r`, `man g`, `man qu`, `man mcp`, `man obs`
