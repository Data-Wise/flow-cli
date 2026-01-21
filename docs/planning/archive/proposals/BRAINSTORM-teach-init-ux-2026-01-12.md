# 🧠 BRAINSTORM: teach-init UX Enhancements

**Generated:** 2026-01-12
**Mode:** Feature (User Experience)
**Context:** flow-cli teach-init command

---

## 📋 Overview

Enhance `teach-init` with:

1. **Interactive mode flags** - Guided wizard for new users
2. **Non-interactive mode** - Accept defaults for automation
3. **ADHD-friendly completion summary** - Clear "what happened" with tagging explanation

---

## 🎯 User Requirements

| Requirement                | Priority | Current State                              |
| -------------------------- | -------- | ------------------------------------------ |
| Interactive wizard mode    | High     | Partial (strategy menu only)               |
| Non-interactive/batch mode | Medium   | Missing                                    |
| Completion summary         | High     | Minimal ("Migration complete")             |
| Tagging explanation        | High     | Missing (users don't know how to rollback) |

---

## ⚡ Quick Wins (< 30 min each)

### 1. Add `--yes` / `-y` Flag (Non-Interactive)

Accept all defaults without prompting:

- Strategy: Option 1 (in-place conversion)
- renv: Exclude (yes)
- GitHub push: Skip (no)

```bash
teach-init -y "STAT 545"  # No prompts, uses safe defaults
```

**Implementation:** ~15 min

```zsh
# In teach-init()
local interactive=true
case "$1" in
  -y|--yes) interactive=false; shift ;;
esac
```

---

### 2. ADHD-Friendly Completion Summary

Replace minimal "Migration complete" with visual summary box:

```
┌─────────────────────────────────────────────────────────────┐
│ 🎉 TEACHING WORKFLOW INITIALIZED!                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ 📋 What Just Happened:                                      │
│                                                             │
│   ✅ Created rollback tag: spring-2026-pre-migration        │
│      └─ Your safety net! See "How to Rollback" below        │
│                                                             │
│   ✅ Renamed main → production                              │
│      └─ This is what students see (deployed site)           │
│                                                             │
│   ✅ Created draft branch (you're on it now)                │
│      └─ Safe to edit - students won't see until you deploy  │
│                                                             │
│   ✅ Created files:                                         │
│      • .flow/teach-config.yml    (course settings)          │
│      • scripts/quick-deploy.sh   (deploy draft→production)  │
│      • scripts/semester-archive.sh (end-of-semester)        │
│      • .github/workflows/deploy.yml (GitHub Actions)        │
│      • MIGRATION-COMPLETE.md     (this summary)             │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ 🏷️  HOW TO ROLLBACK (if anything goes wrong):              │
│                                                             │
│   The tag 'spring-2026-pre-migration' is your safety net.   │
│   If migration caused issues:                               │
│                                                             │
│   # See what the tag contains:                              │
│   git log spring-2026-pre-migration --oneline -5            │
│                                                             │
│   # Completely undo migration:                              │
│   git checkout spring-2026-pre-migration                    │
│   git checkout -b main                                      │
│   rm -rf .flow scripts MIGRATION-COMPLETE.md                │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ 🚀 NEXT STEPS:                                              │
│                                                             │
│   1. Start working (safe on draft branch):                  │
│      work stat-545                                          │
│                                                             │
│   2. Make edits, commit as usual                            │
│                                                             │
│   3. Deploy when ready:                                     │
│      ./scripts/quick-deploy.sh                              │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ 📚 Learn more: https://data-wise.github.io/flow-cli/        │
│                guides/TEACHING-WORKFLOW/                    │
└─────────────────────────────────────────────────────────────┘
```

**Implementation:** ~20 min (new `_teach_show_completion_summary` function)

---

### 3. Progress Indicators During Migration

Add step numbers and visual feedback:

```
🎓 Initializing teaching workflow for: STAT 545

Step 1/6: Validating project...
  ✅ Quarto project detected
  ✅ _quarto.yml found
  ✅ index.qmd found

Step 2/6: Creating safety tag...
  ✅ Tag created: spring-2026-pre-migration

Step 3/6: Setting up branches...
  ✅ Renamed main → production
  ✅ Created draft branch

Step 4/6: Installing templates...
  ✅ Created .flow/teach-config.yml
  ✅ Created scripts/quick-deploy.sh
  ✅ Created scripts/semester-archive.sh

Step 5/6: Configuring semester...
  [Interactive prompts here]

Step 6/6: Generating documentation...
  ✅ Created MIGRATION-COMPLETE.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[Shows completion summary box]
```

**Implementation:** ~15 min (add step counters to existing functions)

---

## 🔧 Medium Effort (1-2 hours)

### 4. Interactive Wizard Mode (`--wizard` / `-w`)

Full guided experience with explanations:

```bash
teach-init --wizard "STAT 545"
```

```
┌─────────────────────────────────────────────────────────────┐
│ 🎓 TEACHING WORKFLOW WIZARD                                 │
│                                                             │
│ This wizard will help you set up a teaching workflow.       │
│ You can cancel at any time with Ctrl+C.                     │
└─────────────────────────────────────────────────────────────┘

Step 1: Project Detection
─────────────────────────
We detected a Quarto project (_quarto.yml found).

  ? Is this correct? [Y/n]

Step 2: Migration Strategy
──────────────────────────
How should we set up your branches?

  1. Convert existing (Recommended)
     Your current branch becomes 'production' (what students see)
     A new 'draft' branch is created for editing

  2. Keep existing + add new
     Your current branch stays the same
     New 'draft' and 'production' branches are added

  3. Fresh start
     Current state is archived
     Clean 'draft' and 'production' branches created

  ? Choose [1/2/3]:

Step 3: Safety Backup
─────────────────────
Before making changes, we'll create a git tag as a safety net.

  Tag name: spring-2026-pre-migration

  This tag lets you undo the migration if anything goes wrong.

  ? Create safety tag? [Y/n]

[...continues with semester dates, GitHub push, etc.]
```

**Implementation:** ~1.5 hours (wrapper around existing functions)

---

### 5. Configuration Presets

Pre-defined configurations for common scenarios:

```bash
# Fresh course (Spring 2026)
teach-init --preset spring-2026 "STAT 545"

# Mid-semester takeover
teach-init --preset mid-semester "STAT 440"

# Archive mode (end of semester)
teach-init --preset archive "STAT 579"
```

**Implementation:** ~1 hour

---

## 🏗️ Long-term (Future Sessions)

### 6. TUI Mode with gum/fzf

Rich terminal UI using gum or fzf:

```bash
teach-init --tui "STAT 545"
```

Uses gum for beautiful prompts:

- `gum choose` for strategy selection
- `gum input` for dates
- `gum confirm` for confirmations
- `gum spin` for progress

---

### 7. Undo Command

Dedicated undo that uses the rollback tag:

```bash
teach-init --undo
# Finds most recent pre-migration tag and offers to restore
```

---

## 📊 Implementation Priority

| Enhancement                 | Effort | Impact | Priority  |
| --------------------------- | ------ | ------ | --------- |
| Completion summary          | 20 min | High   | ⭐⭐⭐ P1 |
| `-y` flag (non-interactive) | 15 min | Medium | ⭐⭐⭐ P1 |
| Progress indicators         | 15 min | Medium | ⭐⭐ P2   |
| Wizard mode                 | 1.5 hr | Medium | ⭐ P3     |
| Presets                     | 1 hr   | Low    | P4        |
| TUI mode                    | 2 hr   | Low    | P5        |

---

## ✅ Recommended Path

**Phase 1 (Now, ~35 min):**

1. Add `-y` / `--yes` flag for non-interactive mode
2. Add `_teach_show_completion_summary()` function
3. Replace "Migration complete" with visual summary
4. Include rollback tag explanation

**Phase 2 (Later):** 5. Add progress indicators (Step 1/6, etc.)

**POSTPONED:**

- `--wizard` mode (interactive wizard) - Not needed now
- Configuration presets - Low priority
- TUI mode with gum/fzf - Future enhancement

---

## 🎯 Acceptance Criteria

- [ ] `teach-init -y "Course"` runs without prompts
- [ ] Completion summary shows all created files
- [ ] Completion summary explains rollback tag usage
- [ ] Summary includes exact commands to undo
- [ ] Progress indicators show current step
- [ ] ADHD-friendly: visual hierarchy, clear next steps

---

## 📝 Notes

- Keep existing behavior as default (backward compatible)
- Non-interactive mode should use safest defaults
- Summary should be skippable with `--quiet`
- Consider adding `--verbose` for extra detail
