# Safe Testing Guide - flow-cli v5.9.0

**Purpose:** Test Scholar deep integration on real courses WITHOUT risk of data loss.

---

## Why This Guide Exists

When testing new software features on production data (your real courses), there's always anxiety about "what if something goes wrong?" This guide helps you:

1. **Understand what operations are truly safe** (and why)
2. **Build confidence** through incremental testing
3. **Know your escape hatches** before you need them

---

## 🎓 Understanding Read vs Write Operations

### The Fundamental Distinction

```
┌─────────────────────────────────────────────────────────────┐
│  READ Operations (Safe)         WRITE Operations (Caution) │
├─────────────────────────────────────────────────────────────┤
│  • Open file, look at contents  • Create new file          │
│  • Validate data structure      • Modify existing file     │
│  • Compute hash/checksum        • Delete file              │
│  • Display information          • Change permissions       │
│  • Parse and analyze            • Git commit/push          │
└─────────────────────────────────────────────────────────────┘
```

**Key insight:** A read operation, by definition, cannot change your data. It's like looking at a photograph vs. editing it.

### Why v5.9.0 Features Are Mostly Safe

| Feature | What It Actually Does | Why Safe |
|---------|----------------------|----------|
| **Config Validation** | Opens YAML, checks structure | Only reads, never modifies config |
| **Hash Detection** | Reads file bytes, computes SHA-256 | Math on bytes, no file changes |
| **Flag Validation** | Checks command arguments | String comparison, no I/O |
| **teach status** | Reads config + lists files | `ls` and `cat` equivalent |
| **Spinner** | Prints characters to terminal | Display only, no file access |

---

## 🎓 Understanding the --dry-run Pattern

### What --dry-run Means

`--dry-run` is a widely-used convention meaning: **"Show me what you WOULD do, but don't actually do it."**

```bash
# Without --dry-run: Actually creates exam file
teach exam "Topic"  → Creates exams/topic-exam.qmd

# With --dry-run: Shows what WOULD be created
teach exam "Topic" --dry-run  → Prints preview, creates NOTHING
```

### Why --dry-run Is Trustworthy

The implementation literally checks for the flag and exits early:

```zsh
# Simplified logic inside teach exam
if [[ "$dry_run" == "true" ]]; then
    echo "Would create: exams/$topic-exam.qmd"
    echo "Content preview:"
    echo "$generated_content"
    return 0  # ← EXIT HERE, never reaches file write
fi

# This code only runs if NOT dry-run
echo "$generated_content" > "exams/$topic-exam.qmd"
```

---

## 🎓 Understanding Git as a Safety Net

### Why Git Makes Testing Fearless

Git is a **time machine** for your files. Any change can be undone:

```
┌─────────────────────────────────────────────────────────────┐
│  Your Course Directory (Working Tree)                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  files you see and edit                              │   │
│  └─────────────────────────────────────────────────────┘   │
│                          ↓ git add                          │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Staging Area (index)                                │   │
│  └─────────────────────────────────────────────────────┘   │
│                          ↓ git commit                       │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  Repository (.git/) - PERMANENT HISTORY              │   │
│  │  Every commit is saved forever (recoverable)         │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Recovery Commands Explained

```bash
# "Undo all uncommitted changes" - Restores files to last commit
git checkout -- .
# Think: "Make my files look like the last snapshot"

# "Save my work temporarily" - Like a clipboard for changes
git stash push -m "description"
# Think: "Put my changes in a drawer for later"

# "Get my saved work back"
git stash pop
# Think: "Take my changes out of the drawer"

# "Nuclear reset" - Discard EVERYTHING since last commit
git reset --hard HEAD
# Think: "Time machine back to last commit, forget everything since"
```

---

## 🎓 Understanding Where Files Get Written

### The Write Locations in v5.9.0

```
┌─────────────────────────────────────────────────────────────┐
│  Your Course Directory (e.g., ~/projects/teaching/stat-440) │
│  ├── .flow/teach-config.yml    ← NEVER written by v5.9.0   │
│  ├── exams/                    ← Only if teach exam runs   │
│  ├── quizzes/                  ← Only if teach quiz runs   │
│  └── .STATUS                   ← Only after generation     │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  System Cache (~/.local/share/flow-cli/)                    │
│  └── cache/teach-config.hash   ← Hash cache (harmless)     │
└─────────────────────────────────────────────────────────────┘
```

**Key insight:** The hash cache is written to YOUR home directory, not the course. Even if something went wrong with caching, your course files are untouched.

---

## 🎓 Understanding Idempotent Operations

### What "Idempotent" Means

An **idempotent** operation produces the same result no matter how many times you run it.

```bash
# Idempotent: Running 10 times = same as running once
teach status
teach status
teach status
# Result: Same output every time, no side effects

# NOT idempotent: Each run creates a NEW file
teach exam "Topic"
teach exam "Topic"  # Creates topic-exam-2.qmd or overwrites!
```

### All v5.9.0 Read Operations Are Idempotent

| Command | Run 100 times? |
|---------|---------------|
| `teach status` | ✅ Same output, no changes |
| `_teach_validate_config` | ✅ Same validation result |
| `_flow_config_hash` | ✅ Same hash (file unchanged) |
| `teach exam --dry-run` | ✅ Same preview, no files |

---

## Safety Principles

1. **Read-only first** - All status/validation commands are safe
2. **--dry-run always** - Preview without writing files
3. **No auto-stage in tests** - Post-generation hooks won't run with --dry-run
4. **Git safety net** - Stash changes before testing

---

## Pre-Flight Checklist

Before testing on a real course:

```bash
# 1. Navigate to course
cd ~/projects/teaching/stat-440

# 2. Check git status (should be clean)
git status

# 3. Stash any uncommitted work (safety net)
git stash push -m "pre-v5.9.0-test"

# 4. Verify stash saved
git stash list
```

---

## Safe Commands (Read-Only)

These commands **NEVER modify files**:

### 1. teach status

```bash
# Shows course info, validation status, content inventory
teach status
```

**What it does:** Reads config, validates, displays info
**Risk:** ⚪ NONE

### 2. teach help

```bash
teach help
teach exam --help
teach quiz --help
```

**What it does:** Displays help text
**Risk:** ⚪ NONE

### 3. Config Validation

```bash
# Source flow-cli first
source ~/projects/dev-tools/flow-cli/flow.plugin.zsh

# Validate config (read-only)
_teach_validate_config .flow/teach-config.yml

# Check Scholar section exists
_teach_has_scholar_config .flow/teach-config.yml

# Get config values (read-only)
_teach_config_get "course.name"
_teach_config_get "course.semester"
```

**What it does:** Reads and validates YAML
**Risk:** ⚪ NONE

### 4. Hash Functions

```bash
# Compute hash (read-only)
_flow_config_hash .flow/teach-config.yml

# Check if changed (reads cache file)
_flow_config_changed .flow/teach-config.yml
```

**What it does:** Computes SHA-256, compares with cache
**Risk:** ⚪ NONE (cache file is in ~/.local/share/flow-cli/)

### 5. Flag Validation

```bash
# Test flag validation (no execution)
_teach_validate_flags exam --questions 5 --duration 60
_teach_validate_flags exam --invalid-flag  # Should error
```

**What it does:** Validates flags, returns error for invalid
**Risk:** ⚪ NONE

---

## Safe Commands with --dry-run

These commands **preview output without writing**:

### 6. teach exam --dry-run

```bash
# Preview exam generation (NO files written)
teach exam "Regression Diagnostics" --dry-run
```

**What it does:** Shows what WOULD be generated
**Risk:** ⚪ NONE (--dry-run prevents file creation)

### 7. teach quiz --dry-run

```bash
teach quiz "Hypothesis Testing" --dry-run --questions 10
```

**Risk:** ⚪ NONE

### 8. teach slides --dry-run

```bash
teach slides "ANOVA" --dry-run
```

**Risk:** ⚪ NONE

---

## Commands That WRITE Files

⚠️ **DO NOT run these without --dry-run during testing:**

| Command | What it writes | Reversible? |
|---------|---------------|-------------|
| `teach exam "Topic"` | `exams/*.qmd` | Yes (git) |
| `teach quiz "Topic"` | `quizzes/*.qmd` | Yes (git) |
| `teach slides "Topic"` | `slides/*.qmd` | Yes (git) |
| `teach syllabus` | `syllabus.qmd` | Yes (git) |

**Recovery if accidentally run:**

```bash
# Discard all uncommitted changes
git checkout -- .

# Or restore from stash
git stash pop
```

---

## Complete Safe Test Script

Copy and run this script for comprehensive safe testing:

```bash
#!/usr/bin/env zsh
# Safe v5.9.0 Test - Real Course
# Run from course directory (e.g., stat-440)

echo "═══════════════════════════════════════════════"
echo "flow-cli v5.9.0 Safe Testing - $(basename $PWD)"
echo "═══════════════════════════════════════════════"

# Source plugin
source ~/projects/dev-tools/flow-cli/flow.plugin.zsh

echo "\n[1] teach status (read-only)"
echo "─────────────────────────────"
teach status

echo "\n[2] Config validation (read-only)"
echo "───────────────────────────────────"
_teach_validate_config .flow/teach-config.yml

echo "\n[3] Config values (read-only)"
echo "──────────────────────────────"
echo "Course: $(_teach_config_get 'course.name')"
echo "Semester: $(_teach_config_get 'course.semester')"
echo "Year: $(_teach_config_get 'course.year')"

echo "\n[4] Hash detection (read-only)"
echo "────────────────────────────────"
echo "Hash: $(_flow_config_hash .flow/teach-config.yml | head -c 16)..."

echo "\n[5] Flag validation (read-only)"
echo "─────────────────────────────────"
if _teach_validate_flags exam --questions 5 2>/dev/null; then
    echo "✓ Valid flags accepted"
else
    echo "✗ Flag validation failed"
fi

if ! _teach_validate_flags exam --bad-flag 2>/dev/null; then
    echo "✓ Invalid flags rejected"
else
    echo "✗ Invalid flag not caught"
fi

echo "\n[6] Help system (read-only)"
echo "─────────────────────────────"
teach exam --help | head -5

echo "\n═══════════════════════════════════════════════"
echo "✓ All safe tests complete - no files modified"
echo "═══════════════════════════════════════════════"
```

---

## Testing on stat-440

```bash
# 1. Go to course
cd ~/projects/teaching/stat-440

# 2. Safety stash
git stash push -m "pre-test"

# 3. Run safe tests
source ~/projects/dev-tools/flow-cli/flow.plugin.zsh
teach status
_teach_validate_config .flow/teach-config.yml

# 4. Preview generation (--dry-run = safe)
teach exam "Model Diagnostics" --dry-run

# 5. Verify no changes
git status  # Should show "nothing to commit"

# 6. Restore stash if needed
git stash pop
```

---

## What's Actually At Risk?

### Low Risk (Auto-recoverable)

- Cache files in `~/.local/share/flow-cli/` - Can be deleted
- Generated content files - Git tracked, easily reverted

### No Risk

- Course config `.flow/teach-config.yml` - Never written by v5.9.0 features
- Existing course content - Never modified
- Git history - Never altered

### The v5.9.0 Features Are Read-Heavy

| Feature | Reads | Writes |
|---------|-------|--------|
| JSON Schema validation | ✓ config | ✗ nothing |
| Hash detection | ✓ config | ✓ cache only |
| Flag validation | ✓ flags | ✗ nothing |
| Spinner | ✗ nothing | ✗ nothing |
| teach status | ✓ config, files | ✗ nothing |
| Post-gen hooks | ✓ output | ✓ .STATUS, git stage |

**Post-generation hooks only run when content is actually generated** (not with --dry-run).

---

## Emergency Recovery

If something goes wrong:

```bash
# Option 1: Discard all changes
git checkout -- .

# Option 2: Restore from stash
git stash pop

# Option 3: Hard reset (nuclear option)
git reset --hard HEAD
```

---

*Generated: 2026-01-14*
*For: flow-cli v5.9.0 Scholar Deep Integration*
