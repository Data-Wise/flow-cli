# Workflow Quick Reference

**Date:** 2025-12-14 (Updated 2025-12-25)
**Version:** 2.1 - Week 2 CLI Enhancements Complete

> **✨ New Features (2025-12-24):**
>
> - `flow status` - Enhanced with ASCII visualizations, worklog integration, productivity metrics
> - `flow dashboard` - Interactive real-time TUI with keyboard shortcuts (r=refresh, q=quit, ?=help)
> - 10x faster project scanning with in-memory caching (~3ms → <1ms)
>
> **⚠️ Updates (2025-12-25):**
>
> - Removed deprecated `v`/`vibe` dispatcher - use `flow` command directly
> - Removed single-letter aliases (`d`, `f`, `pp`, `ah`) - use full commands
> - Added `qu` and `r` dispatchers for Quarto and R workflows
> - See `ALIAS-REFERENCE-CARD.md` for current aliases (28 total)
> - See `DISPATCHER-REFERENCE.md` for active dispatchers (5 total: g, mcp, obs, qu, r)

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

**Full guide:** `WORKFLOW-ANALYSIS-2025-12-14.md`
