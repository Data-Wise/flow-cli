# 🎨 Prompt Management UX Specification

**Generated:** 2026-01-21
**Based on:** Deep dive Q&A on local vs global storage
**Status:** Complete UX design, ready for implementation

---

## 📋 Overview

This document specifies the **complete user experience** for managing teaching prompts in flow-cli, covering:

1. **Viewing** prompts (`teach prompt show`)
2. **Editing** prompts (`teach prompt edit`)
3. **Enhancing** prompts (`teach prompt enhance`)
4. **Adding** new prompts (`teach prompt add`)
5. **Promoting** prompts (`teach prompt promote`)
6. **Conflict resolution** (when same prompt exists globally + locally)

---

## 1️⃣ Viewing Prompts (`teach prompt show`)

### Command

```bash
teach prompt show <type>
```bash

### Behavior

**Output to terminal with pagination:**

```bash
$ teach prompt show lecture

# (Output piped to less automatically)

<!--
Version: 1.0.0
Last Modified: 2026-01-21
Author: flow-cli team
Compatible with: flow-cli 5.14.0+, Scholar 2.x
-->

# Comprehensive Lecture Notes Generator

## Purpose

Generate instructor-facing lecture notes (20-40 pages) for statistics courses...

(Press q to quit, / to search, space for next page)
```bash

### Implementation

```zsh
_teach_prompt_show() {
    local type="$1"
    local prompt_file=$(_resolve_prompt "$type")

    if [[ -z "$prompt_file" ]]; then
        echo "❌ Prompt not found: $type"
        echo "Available prompts: $(teach prompt list)"
        return 1
    fi

    # Show with pagination
    cat "$prompt_file" | less -R

    # Show metadata footer after quit
    echo ""
    echo "📍 Location: $prompt_file"
    echo "🔧 Edit: teach prompt edit $type"
}
```text

---

## 2️⃣ Editing Prompts (`teach prompt edit`)

### Command

```bash
teach prompt edit <type>
```yaml

### Behavior: Copy to Course, Then Edit

**Workflow:**

```bash
$ teach prompt edit lecture

📝 Editing: lecture-notes

Current location: ~/.flow/prompts/lecture-notes.md (global)

📋 Edit Strategy:
  → Will copy to .claude/prompts/lecture-notes.local.md (course-specific)
  → Opens in $EDITOR for editing
  → Changes apply to this course only

Rationale:
  ✅ Preserves global default (others can still use it)
  ✅ Course-specific customization (versioned with repo)
  ✅ Share with TAs (git push shares edits)

Continue? [Y/n]: y

Copying: ~/.flow/prompts/lecture-notes.md
      → .claude/prompts/lecture-notes.local.md

✅ Copied successfully!

Opening in: /usr/local/bin/nvim

(Editor opens, user makes changes, saves, quits)

✅ Changes saved to .claude/prompts/lecture-notes.local.md

Next steps:
  1. Test: teach lecture "Test Topic"
  2. Commit: git add .claude/prompts/ && git commit
  3. Promote to global: teach prompt promote lecture (if you want to use in all courses)
```text

### Edge Cases

#### Case 1: Already Exists in .claude/prompts/

```bash
$ teach prompt edit lecture

📝 Editing: lecture-notes

✅ Course-specific version already exists:
   .claude/prompts/lecture-notes.local.md

Opening in: $EDITOR

(No copy needed, directly edit local version)
```text

#### Case 2: No Global, Only Local

```bash
$ teach prompt edit lecture

📝 Editing: lecture-notes

📍 Location: .claude/prompts/lecture-notes.local.md (course-only)

⚠️  Warning: No global version exists
   This prompt is unique to this course

Opening in: $EDITOR
```text

---

## 3️⃣ Enhancing Prompts (`teach prompt enhance`)

### Command

```bash
teach prompt enhance <type>
```sql

### Behavior: Interactive Wizard

**Workflow:**

```bash
$ teach prompt enhance lecture

🎨 Enhance Lecture Prompt: lecture-notes

Current version: 1.0.0 (global)
Location: ~/.flow/prompts/lecture-notes.md

╔══════════════════════════════════════════════════════════════╗
║  Enhancement Wizard                                          ║
║  We'll walk through sections to add/modify/remove            ║
╚══════════════════════════════════════════════════════════════╝

Step 1/5: R Package Customization
──────────────────────────────────
Current packages:
  emmeans, lme4, car, ggplot2, dplyr, performance

Add more packages? [y/N]: y
Package names (comma-separated): DHARMa, broom, gtsummary

✅ Will add: DHARMa, broom, gtsummary

Step 2/5: Derivation Depth
───────────────────────────
Current: rigorous-with-intuition

Options:
  1. Heuristic only (intuitive explanations, skip proofs)
  2. Rigorous-with-intuition (current) ✓
  3. Full rigor (every step, formal proofs)

Choice [1-3]: 2 (keep current)

Step 3/5: Practice Problems
────────────────────────────
Current: 4-10 problems recommended

Change count? [y/N]: y
New count: 6-8 problems

✅ Will update to: 6-8 problems

Step 4/5: Add New Section
──────────────────────────
Add a custom section? [y/N]: y

Section name: Computational Performance Tips

Section content (markdown):
(Opens nano for multi-line input)

## Computational Performance Tips

- Use `data.table` for large datasets (>100k rows)
- Profile code with `profvis::profvis()`
- Consider `future` for parallel computing

(Save and quit nano)

✅ Section added

Step 5/5: Save Location
────────────────────────
Where should enhanced prompt be saved?

Options:
  (g) Global - ~/.flow/prompts/lecture-notes.md
      Pro: Available to all future courses
      Con: Overwrites your global default

  (l) Local - .claude/prompts/lecture-notes.local.md
      Pro: Course-specific, versioned with repo
      Con: Only this course benefits

  (n) New file - Save as new prompt (e.g., lecture-notes-v2.md)
      Pro: Keeps original, creates variant
      Con: Need to remember to use new version

Default: (l) Local [recommended for first enhancement]

Choice [g/l/n]: l

╔══════════════════════════════════════════════════════════════╗
║  Enhancement Summary                                         ║
╠══════════════════════════════════════════════════════════════╣
║  Base: lecture-notes (v1.0.0)                                ║
║  Changes:                                                    ║
║    ✓ Added packages: DHARMa, broom, gtsummary               ║
║    ✓ Updated practice problems: 6-8 (was 4-10)              ║
║    ✓ Added section: Computational Performance Tips          ║
║  Destination: .claude/prompts/lecture-notes.local.md        ║
╚══════════════════════════════════════════════════════════════╝

Apply enhancements? [Y/n]: y

Creating enhanced prompt...
  ✓ Copied base template
  ✓ Updated R packages section
  ✓ Modified practice problems count
  ✓ Inserted custom section
  ✓ Updated metadata header

✅ Enhanced prompt saved!

Location: .claude/prompts/lecture-notes.local.md
Based on: lecture-notes v1.0.0
Enhancements: 3 changes

Next steps:
  1. Test: teach lecture "Test Topic"
  2. Review: teach prompt show lecture (will use enhanced version)
  3. Promote: teach prompt promote lecture (if you want to use globally)
```text

---

## 4️⃣ Adding New Prompts (`teach prompt add`)

### Command

```bash
teach prompt add <name>
```diff

### Behavior: Ask Every Time (Detailed Explanation)

**Workflow:**

```bash
$ teach prompt add lab-worksheet

📦 Creating New Prompt: lab-worksheet

╔══════════════════════════════════════════════════════════════╗
║  Where should this prompt be saved?                          ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  (g) Global - ~/.flow/prompts/lab-worksheet.md               ║
║      ✅ Available to all courses                             ║
║      ✅ Use in future courses automatically                  ║
║      ✅ Part of your personal prompt library                 ║
║      ⚠️  Changes affect all courses using it                 ║
║                                                              ║
║  (l) Local - .claude/prompts/lab-worksheet.local.md          ║
║      ✅ Course-specific (versioned with repo)                ║
║      ✅ Share with TAs via git                               ║
║      ✅ Won't affect other courses                           ║
║      ⚠️  Only available in this course                       ║
║                                                              ║
║  Default recommendation: (g) Global                          ║
║  Rationale: New prompts are usually reusable across courses  ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

Choice [g/l] (default: g): g

✅ Will save to: ~/.flow/prompts/lab-worksheet.md

Template:
  (1) Start from scratch (empty file)
  (2) Copy from existing prompt (lecture-notes, slides, etc.)
  (3) Use minimal template (pre-filled structure)

Choice [1-3]: 3

Creating from minimal template...

Opening in: $EDITOR

(Editor opens with template:)

<!--
Version: 1.0.0
Last Modified: 2026-01-21
Author: DT
Compatible with: flow-cli 5.14.0+
-->

# Lab Worksheet Generator

## Purpose

[Describe what this prompt generates]

## Structure Requirements

### 1. [Section name]

[Section description]

### 2. [Section name]

...

## Quality Checklist

- [ ] [Requirement 1]
- [ ] [Requirement 2]

(User fills in template, saves, quits)

✅ Prompt created!

Location: ~/.flow/prompts/lab-worksheet.md

Next steps:
  1. Register command: teach prompt register lab-worksheet
     (Optional: adds 'teach lab "Topic"' command)
  2. Use: teach prompt show lab-worksheet
  3. Test: Generate content with Scholar or direct use
```text

---

## 5️⃣ Promoting Prompts (`teach prompt promote`)

### Command

```bash
teach prompt promote <type>
```yaml

### Behavior: Copy Local → Global

**Workflow:**

```bash
$ teach prompt promote lecture

🚀 Promoting: lecture-notes (local → global)

Source: .claude/prompts/lecture-notes.local.md
Destination: ~/.flow/prompts/lecture-notes.md

⚠️  Warning: This will OVERWRITE the global version!

Current global version:
  Version: 1.0.0
  Last Modified: 2026-01-15
  Author: flow-cli team

Your local version:
  Version: 1.0.0 (customized)
  Last Modified: 2026-01-21
  Customizer: DT (STAT 440)
  Changes: +3 sections, +2 packages

╔══════════════════════════════════════════════════════════════╗
║  Promotion Impact                                            ║
╠══════════════════════════════════════════════════════════════╣
║  ✅ Future courses will use your customized version          ║
║  ✅ Other courses can benefit from your improvements         ║
║  ⚠️  Existing courses using global will see changes          ║
║  💡 Tip: Consider versioning (save as v2) instead            ║
╚══════════════════════════════════════════════════════════════╝

Promote to global? [y/N]: y

Options:
  (o) Overwrite global (replace v1.0.0 with customized)
  (v) Save as new version (lecture-notes-v2.md)
  (b) Backup first (save current global to lecture-notes-v1.0.0-backup.md)

Choice [o/v/b] (recommended: b): b

Creating backup...
  ✓ Saved: ~/.flow/prompts/lecture-notes-v1.0.0-backup.md

Promoting...
  ✓ Copied: .claude/prompts/lecture-notes.local.md
         → ~/.flow/prompts/lecture-notes.md

✅ Promoted successfully!

New global version:
  Location: ~/.flow/prompts/lecture-notes.md
  Based on: STAT 440 customizations
  Backup: ~/.flow/prompts/lecture-notes-v1.0.0-backup.md

Next steps:
  1. Test in new course: cd ~/teaching/new-course && teach lecture "Topic"
  2. Rollback if needed: teach prompt restore lecture-notes-v1.0.0-backup
```bash

---

## 6️⃣ Conflict Resolution (Duplicate Prompts)

### Scenario: Prompt Exists in Both Global AND Local

**Detection:**

```zsh
_detect_prompt_conflict() {
    local type="$1"

    local global="$HOME/.flow/prompts/${type}.md"
    local local=".claude/prompts/${type}.local.md"

    if [[ -f "$global" && -f "$local" ]]; then
        # Conflict exists
        return 0
    fi
    return 1
}
```yaml

**Resolution Workflow:**

```bash
$ teach lecture "ANOVA"

⚠️  Prompt Conflict Detected!

Prompt: lecture-notes exists in BOTH locations:
  Global: ~/.flow/prompts/lecture-notes.md
  Local:  .claude/prompts/lecture-notes.local.md

Which version should we use?

Options:
  (l) Local - Use course-specific version (default) ✓
  (g) Global - Use user-wide version
  (d) Diff - Show differences first, then decide
  (m) Merge - Interactively merge sections

Choice [l/g/d/m]: d

╔══════════════════════════════════════════════════════════════╗
║  Diff: Global vs Local                                       ║
╚══════════════════════════════════════════════════════════════╝

Differences found in 3 sections:

┌──────────────────────────────────────────────────────────────┐
│ Section: R Package Loading                                   │
├──────────────────────────────────────────────────────────────┤
│ Global:                                                       │
│   pacman::p_load(emmeans, lme4, car, ggplot2, dplyr)         │
│                                                               │
│ Local:                                                        │
│   pacman::p_load(emmeans, lme4, car, ggplot2, dplyr,         │
│                  DHARMa, broom, gtsummary)                    │
│                                                               │
│ Change: +3 packages                                           │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ Section: Practice Problems                                   │
├──────────────────────────────────────────────────────────────┤
│ Global: 4-10 problems recommended                             │
│ Local:  6-8 problems recommended                              │
│                                                               │
│ Change: Count adjusted                                        │
└──────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────┐
│ Section: (New in Local)                                      │
├──────────────────────────────────────────────────────────────┤
│ Local:                                                        │
│   ## Computational Performance Tips                           │
│   - Use data.table for large datasets                        │
│   - Profile code with profvis                                │
│                                                               │
│ Change: +1 section (new)                                      │
└──────────────────────────────────────────────────────────────┘

Summary:
  Local has: +3 packages, adjusted count, +1 section
  Global is: Original v1.0.0 (unchanged)

Which version should we use for this lecture?

  (l) Local - Use course customizations (recommended for this course)
  (g) Global - Use original template
  (m) Merge - Combine sections interactively
  (s) Set preference - Always use local for this course

Choice [l/g/m/s]: l

✅ Using local version: .claude/prompts/lecture-notes.local.md

Generating lecture "ANOVA" with course-specific customizations...

💡 Tip: To always use local in this course, run:
   teach prompt prefer local
```yaml

---

## 7️⃣ Preference Management

### Default Save Location Preference

**User Choice:** Yes, but always confirm

**Configuration:**

```yaml
# ~/.flow/config.yml
prompts:
  default_save_location: global  # global | local
  always_confirm: true           # Show default, allow override
  auto_promote: false            # Prompt before promoting
```text

**Behavior with Preference:**

```bash
$ teach prompt add exam-generator

📦 Creating New Prompt: exam-generator

Default save location: (g) Global [from ~/.flow/config.yml]

╔══════════════════════════════════════════════════════════════╗
║  Save to: ~/.flow/prompts/exam-generator.md (global)         ║
║                                                              ║
║  Override? Press 'l' for local, or Enter to accept          ║
╚══════════════════════════════════════════════════════════════╝

Choice [g/l] (default: g): [Enter]

✅ Using default: global

Creating prompt...
```diff

---

## 8️⃣ Complete Command Reference

### Core Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `teach prompt list` | Show available prompts | `teach prompt list` |
| `teach prompt show <type>` | Display prompt (paginated) | `teach prompt show lecture` |
| `teach prompt edit <type>` | Copy to course & edit | `teach prompt edit lecture` |
| `teach prompt enhance <type>` | Interactive wizard | `teach prompt enhance lecture` |
| `teach prompt add <name>` | Create new prompt | `teach prompt add lab-worksheet` |
| `teach prompt promote <type>` | Local → Global | `teach prompt promote lecture` |
| `teach prompt info <type>` | Show metadata | `teach prompt info lecture` |

### Management Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `teach prompt diff <type>` | Compare global vs local | `teach prompt diff lecture` |
| `teach prompt merge <type>` | Interactive merge | `teach prompt merge lecture` |
| `teach prompt prefer <location>` | Set course preference | `teach prompt prefer local` |
| `teach prompt restore <backup>` | Restore from backup | `teach prompt restore lecture-v1.0.0-backup` |
| `teach prompt reset <type>` | Restore to original | `teach prompt reset lecture` |

### Advanced Commands

| Command | Purpose | Example |
|---------|---------|---------|
| `teach prompt register <type>` | Add teach command | `teach prompt register lab` → `teach lab "Topic"` |
| `teach prompt validate <file>` | Validate against prompt | `teach validate lecture.qmd` |
| `teach prompt catalog browse` | Browse built-in catalog | `teach prompt catalog browse` |
| `teach prompt catalog install <name>` | Install from catalog | `teach prompt catalog install bayesian-lecture` |

---

## 9️⃣ Implementation Checklist

### Phase 1: Core Viewing/Editing (30 min)

- [ ] Implement `teach prompt show` (cat | less)
- [ ] Implement `teach prompt edit` (copy to course, open in $EDITOR)
- [ ] Add metadata footer to show command
- [ ] Test: View prompt, edit prompt, verify .local.md created

### Phase 1.5: Enhancement Wizard (45 min)

- [ ] Design interactive wizard flow
- [ ] Implement section-by-section enhancement
- [ ] Add "Save Location" decision point with detailed explanation
- [ ] Test: Enhance lecture prompt, verify enhancements applied

### Phase 2: Add/Promote/Conflict (1 hour)

- [ ] Implement `teach prompt add` with save location prompt
- [ ] Add detailed explanation box for global vs local
- [ ] Implement `teach prompt promote` with backup option
- [ ] Implement conflict detection + diff display
- [ ] Test: Add new prompt, promote to global, resolve conflict

### Phase 2.5: Preferences (30 min)

- [ ] Add `~/.flow/config.yml` prompt section
- [ ] Implement default + confirm behavior
- [ ] Add `teach prompt prefer` command
- [ ] Test: Set preference, verify always-confirm works

### Phase 3: Advanced Features (2 hours)

- [ ] Implement `teach prompt diff` (standalone diff)
- [ ] Implement `teach prompt merge` (interactive merge)
- [ ] Implement `teach prompt restore` (from backup)
- [ ] Add `teach prompt register` (create teach commands)
- [ ] Test: Full workflow end-to-end

---

## 🎯 Success Criteria

**Core Viewing/Editing is successful if:**
- ✅ Users can view any prompt with pagination
- ✅ Editing auto-copies to .claude/prompts/
- ✅ $EDITOR preference respected
- ✅ Metadata shown after viewing

**Enhancement Wizard is successful if:**
- ✅ Step-by-step wizard is intuitive
- ✅ Save location decision is clear
- ✅ Enhancements persist correctly
- ✅ Wizard completes in < 2 min

**Add/Promote is successful if:**
- ✅ Save location prompt shows pros/cons
- ✅ Default recommendation is helpful
- ✅ Promote includes backup option
- ✅ Conflict resolution shows clear diff

**Preferences is successful if:**
- ✅ Default saves time (one-key confirm)
- ✅ Override is always available
- ✅ Preference persists across sessions
- ✅ `teach prompt prefer` updates config.yml

---

## 📊 UX Flow Diagrams

### Edit Prompt Flow

```text
teach prompt edit lecture
         ↓
   Check if .local exists
         ↓
    ┌────┴────┐
    │         │
   YES       NO
    │         │
    │    Copy global → .local
    │         │
    └────┬────┘
         ↓
   Open in $EDITOR
         ↓
    User saves
         ↓
   Show next steps
   (test, commit, promote)
```text

### Add Prompt Flow

```text
teach prompt add exam
         ↓
   Show save location prompt
   (detailed pros/cons)
         ↓
    User chooses g/l
         ↓
   Default: g (confirm or override)
         ↓
   Choose template
   (scratch/copy/minimal)
         ↓
   Open in $EDITOR
         ↓
   User creates prompt
         ↓
   Show next steps
   (register, test)
```text

### Conflict Resolution Flow

```text
teach lecture "Topic"
         ↓
   Check for conflict
         ↓
   Global + Local exist?
         ↓
    ┌────┴────┐
    │         │
   YES       NO
    │         │
    │    Use normal precedence
    │         │
    └────┬────┘
         ↓
   Show diff prompt
         ↓
   User chooses: l/g/d/m
         ↓
   d (diff) selected?
         ↓
   Show side-by-side diff
         ↓
   User chooses: l/g/m/s
         ↓
   Use selected version
```

---

## 💡 UX Best Practices Applied

### 1. Progressive Disclosure

- Show simple options first (g/l)
- Detailed explanation on demand (diff)
- Advanced features hidden until needed (merge)

### 2. Clear Defaults

- Recommend based on context (global for new prompts)
- Always allow override (never force)
- Show rationale (why this default?)

### 3. Reversibility

- Backup before overwrite (promote with backup)
- Restore command available (teach prompt restore)
- Diff before merge (show what changes)

### 4. Visual Hierarchy

- Boxes for important decisions (╔═══╗)
- Colors for status (✅ ⚠️ ❌)
- Indentation for sub-items

### 5. Context-Aware Help

- Next steps after actions (test, commit, promote)
- Tips at decision points (💡 Tip: ...)
- Warnings before destructive actions (⚠️ Warning: ...)

---

**Generated:** 2026-01-21
**Status:** ✅ Complete UX specification, ready for implementation
**Next:** Integrate into Phase 1/2 implementation plan

