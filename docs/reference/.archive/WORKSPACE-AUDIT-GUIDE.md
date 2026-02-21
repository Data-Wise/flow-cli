# 🔍 Workspace Audit Guide

> **Quick Start:** Run `ma` for a complete daily health check

**Last Updated:** 2025-12-14 | **Version:** 1.0 | **Source:** zsh-claude-workflow v1.5.0

---

## Overview

Four new commands for maintaining workspace hygiene across all projects. Originally a standalone tool (workspace-auditor), now merged into zsh-claude-workflow for better integration.

| Command         | Alias | Purpose                   | Frequency |
| --------------- | ----- | ------------------------- | --------- |
| `git-audit`     | `ga`  | Find dirty/unpushed repos | Daily     |
| `file-audit`    | `fa`  | Find large files (>50MB)  | Weekly    |
| `activity-heat` | `ah`  | 7-day activity heatmap    | Daily     |
| `morning-audit` | `ma`  | Full workspace check      | Daily     |

---

## 🔴 git-audit — Repository Health

Scans `~/projects` (depth 3) for repositories with uncommitted changes or unpushed commits.

### Usage

```bash
ga                  # Full audit with file lists
ga -q               # Quick summary only (recommended for daily use)
ga -a               # Show clean repos too
ga ~/code           # Audit specific directory
```text

### Output Example

```yaml
================
Git Repository Audit
================

⚠ research/mediation-planning — uncommitted changes
    M  R/analysis.R
    M  manuscript/draft.qmd
⚠ r-packages/active/medfit — uncommitted changes
    M  R/fit_model.R
    ?? tests/test-edge-cases.R
ℹ dev-tools/obsidian-cli-ops — unpushed commits
    + abc1234 feat: add new search command

Summary: 9 dirty, 1 unpushed
⚠ Consider a cleanup commit spree!
```bash

### Environment Variables

| Variable          | Default      | Description                 |
| ----------------- | ------------ | --------------------------- |
| `PROJECTS_DIR`    | `~/projects` | Base directory to scan      |
| `GIT_AUDIT_DEPTH` | `3`          | How deep to search for .git |

### Integration with Workflow

```bash
# Morning routine
ga -q               # Quick check
# If issues found:
cd ~/projects/problem-repo
gs                  # git status
qcommit "WIP: save progress"  # Quick commit
```text

---

## 🐘 file-audit — Large File Detection

Finds files over 50MB that may need cleanup, archiving, or .gitignore entries.

### Usage

```bash
fa                  # Find files >50MB in ~/projects
fa -s 100M          # Find files >100MB
fa -s 10M ~/data    # Audit data folder with lower threshold
```text

### Output Example

```yaml
========================
Large File Audit (>50M)
========================

127M  r-packages/active/dataprep/inst/extdata/census.csv
 89M  research/mediation-planning/data/raw/survey_2024.rds
 67M  apps/examark/public/assets/video-tutorial.mp4

Found: 3 files
⚠ Consider archiving or adding to .gitignore
```diff

### Exclusions (Automatic)

These directories are always skipped:

- `.git/`
- `node_modules/`
- `.venv/`
- `__pycache__/`
- `renv/`

### Color Coding

| Color   | File Type                                           |
| ------- | --------------------------------------------------- |
| Yellow  | Data files (.csv, .parquet, .rds, .RData, .feather) |
| Blue    | Archives (.zip, .tar, .gz, .7z)                     |
| Magenta | Media (.pdf, .png, .jpg, .mp4)                      |
| White   | Other                                               |

### Action Items

When large files are found:

1. **Data files** → Add to `.gitignore`, use Git LFS, or move to cloud storage
2. **Archives** → Delete if temporary, or move to external storage
3. **Media** → Consider compression or external hosting

---

## 🔥 activity-heat — Project Heatmap

Visual representation of which projects have the most recent file activity.

### Usage

```bash
ah                  # Last 7 days, top 10 projects
ah -d 30            # Last 30 days
ah -n 5             # Top 5 only
ah -d 1             # Today only
```text

### Output Example

```text
==============================
Activity Heatmap (Last 7 Days)
==============================

 446 r-packages/active          ████████████████████
 197 apps/examark               ████████████████████
 170 dev-tools/zsh-claude-workflow ████████████████████
 144 r-packages/stable          ████████████████████
 141 r-packages/recovery        ████████████████████
  89 research/mediation-planning █████████████████
  45 quarto/manuscripts         █████████
  23 dev-tools/spacemacs-rstats ████

ℹ Today: 203 files modified
```text

### Color Intensity

| Count | Color  | Meaning            |
| ----- | ------ | ------------------ |
| 1-20  | Green  | Normal activity    |
| 21-50 | Yellow | High activity      |
| 50+   | Red    | Very high activity |

### Use Cases

1. **Identify active work** — See where you've been focusing
2. **Find forgotten projects** — Low activity may mean stalled work
3. **Prioritize reviews** — High activity projects may need commits
4. **Time tracking** — Correlate with work logs

---

## 🌅 morning-audit — Daily Health Check

Orchestrates all audit commands into a single daily report.

### Usage

```bash
ma                  # Quick terminal output
ma -s               # Save markdown report to ~/logs/audit/
ma -o               # Save and open report (macOS)
ma -q               # Minimal output
```bash

### What It Runs

1. `git-audit -q` — Find dirty/unpushed repos
2. `activity-heat -n 5` — Top 5 active projects
3. `file-audit` — Large files (in saved report only)
4. `obs audit` — Obsidian vault structure (if `obs` command available)

### Report Location

Reports are saved to: `~/logs/audit/audit_report_YYYY-MM-DD.md`

### Sample Report

```markdown
# Workspace Audit Report (2025-12-14)

Generated at: Sat Dec 14 09:45:00 PST 2025

## Git Status

⚠ research/mediation-planning — uncommitted changes
⚠ r-packages/active/medfit — uncommitted changes
Summary: 2 dirty, 0 unpushed

## Activity Heatmap

446 r-packages/active ████████████████████
197 apps/examark ████████████████████
ℹ Today: 203 files modified

## Large Files

127M r-packages/active/dataprep/inst/extdata/census.csv
Found: 1 files

## Obsidian Vault

✓ Vault structure clean.
```bash

### Recommended Workflow

```bash
# Option 1: Quick terminal check (most common)
ma

# Option 2: Generate report for reference
ma -o

# Option 3: Add to shell startup for passive awareness
# In ~/.zshrc:
# ma -q 2>/dev/null  # Silent daily check on terminal open
```bash

---

## 🔗 Integration with Other Tools

### With obs (Obsidian CLI)

If you have `obsidian-cli-ops` installed, `morning-audit` automatically runs `obs audit` to check your Obsidian vault structure.

```bash
# Standalone Obsidian audit
obs audit

# Integrated in morning audit
ma  # Includes obs audit automatically
```bash

### With Workflow Logging

Combine with workflow functions for comprehensive tracking:

```bash
# Start of day
ma                          # Check workspace health
startsession "morning"      # Start work session

# End of day
endsession                  # End work session
ga -q                       # Quick commit check
```bash

### With Claude Code

```bash
# Before starting Claude session
ga -q                       # Ensure clean git state
cc                          # Start Claude Code

# After Claude session
ga                          # Review what changed
qcommit "feat: implement X" # Commit changes
```bash

---

## ⚙️ Configuration

### Default Paths

All commands default to scanning `~/projects`. Override with environment variables:

```bash
# In ~/.zshrc
export PROJECTS_DIR="$HOME/code"           # Change base directory
export GIT_AUDIT_DEPTH=4                    # Search deeper
export FILE_AUDIT_SIZE="100M"               # Higher threshold
export ACTIVITY_HEAT_DAYS=14                # Longer lookback
export ACTIVITY_HEAT_TOP=15                 # More results
export AUDIT_LOG_DIR="$HOME/Documents/logs" # Different log location
```bash

### Adding to PATH

The commands are in `~/projects/dev-tools/zsh-claude-workflow/commands/`. If not already in PATH:

```bash
# In ~/.zshrc
export PATH="$HOME/projects/dev-tools/zsh-claude-workflow/commands:$PATH"
```bash

### Aliases

Add to your shell for quick access:

```bash
# Already included in zsh-claude-workflow install.sh
alias ga='git-audit'
alias fa='file-audit'
alias ah='activity-heat'
alias ma='morning-audit'
```diff

---

## 📊 Quick Reference Card

| Task                 | Command    | Time |
| -------------------- | ---------- | ---- |
| Daily health check   | `ma`       | ~5s  |
| Quick git status     | `ga -q`    | ~3s  |
| Find large files     | `fa`       | ~5s  |
| See active projects  | `ah`       | ~3s  |
| Generate report      | `ma -o`    | ~10s |
| Deep audit (30 days) | `ah -d 30` | ~5s  |

---

## 🔧 Troubleshooting

### "Command not found"

```bash
# Verify commands exist
ls ~/projects/dev-tools/zsh-claude-workflow/commands/*audit*
ls ~/projects/dev-tools/zsh-claude-workflow/commands/activity-heat

# Check PATH
echo $PATH | tr ':' '\n' | grep zsh-claude

# Re-run install
cd ~/projects/dev-tools/zsh-claude-workflow
./install.sh
source ~/.zshrc
```bash

### "No git repos found"

```bash
# Check the directory being scanned
echo $PROJECTS_DIR  # Should be ~/projects or your custom path

# Verify depth setting
git-audit -h  # Shows current defaults
```bash

### Slow performance

```bash
# Reduce search depth
export GIT_AUDIT_DEPTH=2

# Use quick mode
ga -q  # Much faster than full output
```

---

## 📁 Source Files

| File          | Location                                                              |
| ------------- | --------------------------------------------------------------------- |
| git-audit     | `~/projects/dev-tools/zsh-claude-workflow/commands/git-audit`         |
| file-audit    | `~/projects/dev-tools/zsh-claude-workflow/commands/file-audit`        |
| activity-heat | `~/projects/dev-tools/zsh-claude-workflow/commands/activity-heat`     |
| morning-audit | `~/projects/dev-tools/zsh-claude-workflow/commands/morning-audit`     |
| Documentation | `~/projects/dev-tools/zsh-claude-workflow/docs/commands/reference.md` |

---

## 🔗 Related Documentation

- **ALIAS-REFERENCE-CARD.md** — All aliases including audit shortcuts
- **WORKFLOWS-QUICK-WINS.md** — Daily workflow patterns
- **zsh-claude-workflow README** — Full project documentation

---

**History:**

- 2025-12-14: Created from workspace-auditor merge into zsh-claude-workflow v1.5.0
