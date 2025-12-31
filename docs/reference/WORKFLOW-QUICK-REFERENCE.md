# Workflow Quick Reference

**Date:** 2025-12-14 (Updated 2025-12-31)
**Version:** 4.7.0 - iCloud Remote Sync

> **✨ New in v4.7.0 (2025-12-31):**
>
> - `flow sync remote` - iCloud sync for multi-device access
> - `flow sync remote init` - Set up iCloud sync (migrates wins, goals)
> - Apple handles sync automatically - zero new dependencies
>
> **v4.5.x-4.6.x (2025-12-30):**
>
> - `tm` dispatcher - Terminal manager (iTerm2, Ghostty)
> - `pick wt` - Worktree picker with session indicators
> - Frecency sorting for projects and worktrees
>
> **Previous:**
>
> - 8 active dispatchers: g, mcp, obs, qu, r, cc, tm, wt
> - See `DISPATCHER-REFERENCE.md` for complete dispatcher guide

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

## ☁️ Multi-Device Sync (v4.7.0)

**Set up once:**

```bash
flow sync remote init        # Migrates wins.md, goal.json
# Add to ~/.zshrc: source ~/.config/flow/remote.conf
```

**Daily sync:**

```bash
flow sync                    # Smart sync (auto-detect)
flow sync all                # Full sync
flow sync --status           # View dashboard
```

**What syncs:** wins.md, goal.json, sync-state.json (via iCloud)

---

**Full guide:** See `docs/commands/sync.md`
**Man pages:** `man flow`, `man r`, `man g`, `man qu`, `man mcp`, `man obs`
