# ZSH Config Maintenance

## Philosophy

> **Just type `zsh-clean` and everything gets done. Zero decisions.**

## Architecture

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│  ~/.config/zsh (symlink)                                                    │
│       │                                                                     │
│       ▼                                                                     │
│  ~/projects/dev-tools/flow-cli/zsh/                                │
│       │                                                                     │
│       ├──────────────────┬──────────────────┐                               │
│       │                  │                  │                               │
│       ▼                  ▼                  ▼                               │
│   GitHub             Google Drive       Local                               │
│   (zsh-clean)        (auto-sync)        (working copy)                      │
│   full history       real-time          instant access                      │
└─────────────────────────────────────────────────────────────────────────────┘
```text

## Commands

| Command            | Description                                       |
| ------------------ | ------------------------------------------------- |
| `zsh-clean`        | **Do everything** (archive junk + sync to GitHub) |
| `zsh-clean status` | Health check only                                 |
| `zsh-clean undo`   | Discard uncommitted changes                       |
| `zsh-clean test`   | Run test suite                                    |
| `zsh-clean help`   | Show help                                         |

---

## Usage

### Daily Maintenance (Just This!)

```bash
$ zsh-clean

═══════════════════════════════════════════════════════════
  🧹 ZSH Config Maintenance
═══════════════════════════════════════════════════════════

  1. Cleaning up...
  ✓ No junk to archive
  2. Syncing to GitHub...
  ✓ Committed changes
  ✓ Pushed to GitHub

───────────────────────────────────────────────────────────
  ✓ Done! Config is clean and backed up.
```zsh

That's it. One command does everything:

1. Archives any junk files (`.bak`, `.tmp`, etc.)
2. Commits changes to git
3. Pushes to GitHub

### Undo Changes

```bash
$ zsh-clean undo

═══════════════════════════════════════════════════════════
  ⏪ Undo Changes
═══════════════════════════════════════════════════════════

  Changes to discard:
    M zsh/functions/adhd-helpers.zsh

  ⚠  Discard these changes? [y/N] y
  ✓ Changes discarded

  Run 'source ~/.config/zsh/.zshrc' to reload
```text

### Check Status

```bash
$ zsh-clean status

═══════════════════════════════════════════════════════════
  🩺 ZSH Configuration Health
═══════════════════════════════════════════════════════════

  📁 Config: /Users/dt/.config/zsh (1.5M)
  📦 Functions: 18 files
  ☁️  Git: synced
  🧹 Junk: none
```bash

---

## Recovery

| Scenario                     | Solution                                            |
| ---------------------------- | --------------------------------------------------- |
| **Broke something just now** | `zsh-clean undo`                                    |
| **Need older version**       | `git log --oneline` → `git checkout <hash> -- zsh/` |
| **Catastrophic loss**        | Clone from GitHub or Google Drive                   |

### Restore Specific File

```bash
cd ~/projects/dev-tools/flow-cli
git log --oneline zsh/functions/adhd-helpers.zsh
git checkout abc1234 -- zsh/functions/adhd-helpers.zsh
source ~/.config/zsh/.zshrc
```diff

---

## Backup Strategy

| Method           | When              | History          |
| ---------------- | ----------------- | ---------------- |
| **GitHub**       | Every `zsh-clean` | Full git history |
| **Google Drive** | Automatic         | ~30 days         |

No local tarballs needed — two cloud backups are enough.

---

## File Structure

```text
~/projects/dev-tools/flow-cli/
├── zsh/                      # ← Config (symlinked from ~/.config/zsh)
│   ├── .zshrc
│   ├── .p10k.zsh
│   ├── functions/
│   │   └── zsh-clean.zsh     # This tool
│   ├── tests/
│   └── .archive/             # Junk files (local only)
├── docs/
└── README.md
```

## Tracked vs Ignored

**Tracked (GitHub):**

- `.zshrc`, `.p10k.zsh`, `.zsh_plugins.*`
- `functions/*.zsh`
- `tests/`, `help/`

**Ignored (local):**

- `.archive/` — archived junk
- `.zcompdump*`, `.zsh_history`, `.zsh_sessions/`
- `.zshrc.local` — machine-specific
