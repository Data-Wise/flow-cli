# Teaching Dates Automation Guide

**Centralize semester dates and eliminate manual updates**

**Version:** 5.11.0
**Status:** Complete
**Last Updated:** 2026-01-16

---

## Overview

### What This Feature Does

Teaching Dates Automation centralizes all semester dates in `teach-config.yml` and automatically synchronizes them across your entire course repository. Instead of manually updating 40+ date references across syllabus, assignments, lectures, and schedules, you define dates once and sync everywhere.

**One source of truth for:**
- Week start dates
- Assignment due dates
- Exam dates and times
- Holiday breaks
- Office hours schedules
- Any temporal information in your course

### Why You Need This

Teaching a course involves managing dates in multiple places:

**Without date automation:**

```
❌ syllabus.qmd:        "Homework 1 due Jan 22"
❌ assignments/hw1.qmd:  due: "2025-01-20"  # ← Mismatch!
❌ schedule.qmd:        "Week 2: January 22, 2025"
❌ lectures/week02.qmd: "Due: Jan 22, 2025"
```

**Problems:**
- 📅 40+ dates to update manually each semester
- ⚠️ Date inconsistencies between files
- 🕐 2+ hours for semester rollover
- 🐛 Students see conflicting deadlines

**With date automation:**

```yaml
# teach-config.yml (single source of truth)
semester_info:
  deadlines:
    hw1:
      week: 2
      offset_days: 2  # Due Friday of Week 2
```

Run `teach dates sync` and all files update automatically.

### Key Benefits

| Benefit | Impact |
|---------|--------|
| **Consistency** | All dates match across files - no student confusion |
| **Speed** | Semester rollover: 2 hours → 5 minutes |
| **Confidence** | Preview changes before applying |
| **Flexibility** | Use relative dates (week + offset) or absolute dates |
| **Safety** | Interactive prompts and dry-run mode |

---

## Getting Started

### Prerequisites

Before using date automation, ensure you have:

```bash
# Required tools
brew install yq        # YAML processing
brew install coreutils # GNU date (macOS)

# Verify installation
yq --version           # v4.0 or higher
date --version         # GNU date or BSD date

# flow-cli v5.11.0+
teach dates help
```

### Initial Setup

Navigate to your teaching repository and initialize:

```bash
# Step 1: Initialize date configuration
cd ~/projects/teaching/stat-545
teach dates init

# Step 2: Follow the wizard
Semester start date (YYYY-MM-DD): 2025-01-13

# Step 3: Verify config was created
cat .flow/teach-config.yml
```

**What gets created:**
- 15 weeks with start dates (auto-calculated)
- `semester_info.start_date` and `end_date`
- Empty sections for `holidays`, `deadlines`, `exams`

### Quick Example

Complete workflow from setup to sync:

```bash
# 1. Initialize dates
teach dates init
# Enter: 2025-01-13

# 2. Edit config to add deadlines
vim .flow/teach-config.yml

# Add:
semester_info:
  deadlines:
    hw1:
      week: 2
      offset_days: 2  # Friday of week 2

# 3. Preview what would change
teach dates sync --dry-run

# Output:
# ⚠️  Date Mismatches Found
# 1. assignments/hw1.qmd (1 mismatch)
#    due: 2025-01-20 → 2025-01-22

# 4. Apply changes
teach dates sync

# Prompt for each file:
# Apply changes to assignments/hw1.qmd? [y/n/d/q]
# y

# ✅ Date Sync Complete
# Applied: 1 files
```

---

## Date Configuration Structure

### semester_info Section Overview

All dates live in the `semester_info` section of `teach-config.yml`:

```yaml
semester_info:
  start_date: "2025-01-13"      # Required: First day of semester
  end_date: "2025-05-02"        # Required: Last day of semester

  weeks: []                     # Array of week objects
  holidays: []                  # Array of holiday/break objects
  deadlines: {}                 # Object mapping assignment IDs to dates
  exams: []                     # Array of exam objects
```

### Required Fields

Minimum configuration for date automation to work:

```yaml
semester_info:
  start_date: "2025-01-13"
  end_date: "2025-05-02"

  weeks:
    - number: 1
      start_date: "2025-01-13"
      topic: "Introduction"
    # ... weeks 2-15
```

**Validation:**
- `start_date` and `end_date` must be ISO format (`YYYY-MM-DD`)
- Week numbers must be sequential (1, 2, 3, ...)
- Week start dates should be chronological

### Optional Fields

#### Weeks Array

Each week can have additional metadata:

```yaml
weeks:
  - number: 1
    start_date: "2025-01-13"
    topic: "Introduction to Statistical Computing"
    notes: "First week - cover syllabus"

  - number: 2
    start_date: "2025-01-20"
    topic: "Data Manipulation with dplyr"
    reading: "Chapter 3"
```

**Fields:**
- `number` (required): Week number (integer)
- `start_date` (required): Week start date (YYYY-MM-DD)
- `topic` (optional): Week topic/title
- `notes` (optional): Instructor notes
- `reading` (optional): Required reading

#### Holidays Array

Track breaks and no-class days:

```yaml
holidays:
  - name: "Spring Break"
    date: "2025-03-10"
    type: "break"

  - name: "Memorial Day"
    date: "2025-05-26"
    type: "holiday"

  - name: "No class - conference"
    date: "2025-04-15"
    type: "no_class"
```

**Types:**
- `break` - Multi-day break (Spring/Fall break)
- `holiday` - Single holiday (university closed)
- `no_class` - Instructor absence

#### Deadlines Object

Assignment deadlines support **absolute** or **relative** dates:

```yaml
deadlines:
  # Absolute date (fixed)
  hw1:
    due_date: "2025-01-22"

  # Relative date (computed from week)
  hw2:
    week: 3              # Week 3 start date
    offset_days: 2       # + 2 days (Friday)

  # Negative offset (before week start)
  project_proposal:
    week: 8
    offset_days: -2      # Due before week 8 starts
```

**Why relative dates?**
- Automatically adjust when semester dates shift
- Maintain "always due on Fridays" logic
- Easier semester rollover

**When to use absolute vs relative:**
- Absolute: Fixed external deadlines (final exam day)
- Relative: Regular assignments tied to course schedule

#### Exams Array

Track exams with full details:

```yaml
exams:
  - name: "Midterm Exam"
    date: "2025-03-05"
    time: "2:00 PM - 3:50 PM"
    location: "Gilman Hall 132"
    notes: "Bring calculator, closed book"

  - name: "Final Exam"
    date: "2025-05-08"
    time: "10:00 AM - 12:00 PM"
    location: "Same as midterm"
```

### Date Formats Supported

#### ISO Dates (YYYY-MM-DD)

**Recommended format** - unambiguous and sortable:

```yaml
start_date: "2025-01-13"
due_date: "2025-03-22"
```

Used in:
- ✅ Config file (`teach-config.yml`)
- ✅ YAML frontmatter (`date:`, `due:`)
- ✅ Internal date storage

#### Relative Dates (Week + Offset)

**Flexible format** - auto-computed from week start:

```yaml
hw1:
  week: 2
  offset_days: 2   # Week 2 start (Mon) + 2 = Wed
```

**Examples:**
- `week: 2, offset_days: 0` → Monday of week 2
- `week: 2, offset_days: 4` → Friday of week 2
- `week: 5, offset_days: -1` → Sunday before week 5

#### Date Range Formats

For events spanning multiple days:

```yaml
spring_break:
  name: "Spring Break"
  start_date: "2025-03-10"
  end_date: "2025-03-14"
  type: "break"
```

---

## Supported Date Patterns

### Quarto YAML Frontmatter Dates

The date parser recognizes these YAML fields:

#### Standard Date Fields

```yaml
---
date: "2025-01-22"              # Document date
due: "2025-01-22"               # Assignment due date
published: "2025-01-15"         # Publication date
modified: "2025-01-20"          # Last modified
exam_date: "2025-03-05"         # Exam date
---
```

**Recognized fields:**
- `date`, `due`, `published`, `modified`
- `exam_date`, `quiz_date`, `deadline`
- `start_date`, `end_date`

#### Custom Date Fields

You can add custom fields:

```yaml
---
office_hours_start: "2025-01-13"
project_checkpoint_1: "2025-02-15"
peer_review_due: "2025-03-01"
---
```

The parser will extract any field ending in `_date` or named `due`.

#### Examples from Real Courses

**Assignment:**

```yaml
---
title: "Homework 1: Data Wrangling"
due: "2025-01-22"
points: 100
---
```

**Syllabus:**

```yaml
---
title: "Course Syllabus"
date: "2025-01-13"
semester: "Spring 2025"
---
```

**Lecture:**

```yaml
---
title: "Week 2: dplyr Basics"
date: "2025-01-20"
week: 2
---
```

### Markdown Inline Dates

The parser also finds dates in prose text:

#### Week-Based Date Patterns

```markdown
**Week 2: January 20, 2025** - Data Manipulation

Due: Week 2, Friday (January 22, 2025)
```

Matches:
- `Week N: <date>`
- `Week N, <day> (<date>)`

#### Long Form Date Patterns

```markdown
The midterm exam is on **March 5, 2025** at 2:00 PM.

Assignment due: January 22, 2025
```

Matches:
- `January 22, 2025`
- `Jan 22, 2025`
- `March 5, 2025`

#### Short Form Date Patterns

```markdown
Due: 1/22/2025
Exam: 3/5/2025
```

Matches:
- `M/D/YYYY`
- `MM/DD/YYYY`

⚠️ **Note:** Month/day order depends on locale. Use ISO dates for clarity.

#### Table Date Patterns

```markdown
| Week | Date       | Topic              |
|------|------------|--------------------|
| 1    | Jan 13     | Introduction       |
| 2    | Jan 20     | Data Manipulation  |
| 3    | Jan 27     | Visualization      |
```

Matches:
- `Jan 13` (infers current year)
- `January 20`
- `1/20` (US format)

---

## Command Reference

### teach dates sync

Synchronize dates from config to all teaching files.

#### Usage

```bash
teach dates sync [options]
```

#### Flags

| Flag | Description |
|------|-------------|
| `--dry-run` | Preview changes without modifying files |
| `--force` | Skip prompts, apply all changes automatically |
| `--verbose, -v` | Show detailed progress |
| `--assignments` | Sync only assignment files |
| `--lectures` | Sync only lecture files |
| `--syllabus` | Sync only syllabus/schedule files |
| `--file <path>` | Sync a specific file |

#### Interactive Mode

Default behavior prompts for each file:

```bash
teach dates sync

# For each mismatched file:
File: assignments/hw1.qmd
│ YAML Frontmatter:
│   due: 2025-01-20 → 2025-01-22
├─────────────────────────────────────
Apply changes? [y/n/d/q]
  y - Yes, update this file
  n - No, skip this file
  d - Show diff
  q - Quit (no more changes)
```

**Options:**
- `y` - Apply changes to this file
- `n` - Skip this file (no changes)
- `d` - Show detailed diff, then ask again
- `q` - Quit sync (stop processing)

#### Dry-Run Preview

Safe preview of what would change:

```bash
teach dates sync --dry-run

# Output:
⚠️  Date Mismatches Found
1. assignments/hw1.qmd (1 mismatch)
   due: 2025-01-20 → 2025-01-22
2. syllabus.qmd (3 mismatches)
   ...

ℹ  Dry-run mode: No changes made
  Run without --dry-run to apply changes
```

#### Examples

```bash
# Preview all changes
teach dates sync --dry-run

# Interactive sync (default)
teach dates sync

# Auto-apply all changes
teach dates sync --force

# Sync only assignments
teach dates sync --assignments

# Sync only lecture files
teach dates sync --lectures

# Sync a specific file
teach dates sync --file assignments/hw3.qmd

# Verbose output
teach dates sync -v
```

### teach dates status

Show date configuration summary and consistency status.

#### Usage

```bash
teach dates status
```

#### Output Format

```
📅 Date Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Config Dates Loaded: 23
Teaching Files Found: 18

Upcoming Deadlines (Next 7 Days):
  Jan 22 - Homework 1 (2 days)
  Jan 24 - Quiz 1 (4 days)

Date Sync Status: ✅ All files in sync
```

#### Examples

```bash
# Quick status check
teach dates status

# Check before making changes
teach dates status
teach dates sync --dry-run
```

### teach dates init

Initialize date configuration with interactive wizard.

#### Usage

```bash
teach dates init
```

#### Wizard Flow

```
📅 Initialize Date Configuration

Semester start date (YYYY-MM-DD): 2025-01-13

Generating 15 weeks starting from 2025-01-13...

✓ Date configuration initialized!
  Start: 2025-01-13
  End:   2025-05-02
  Weeks: 15

Next: Edit .flow/teach-config.yml to add:
  - Week topics
  - Holidays
  - Assignment deadlines
  - Exam dates
```

**What it creates:**
1. `semester_info.start_date`
2. `semester_info.end_date` (start + 105 days)
3. 15 weeks with auto-calculated start dates
4. Empty arrays for holidays/exams/deadlines

#### Examples

```bash
# Run wizard
teach dates init

# Enter start date:
2025-01-13

# Config is created, now edit it:
vim .flow/teach-config.yml
```

### teach dates validate

Validate date configuration for errors.

#### Usage

```bash
teach dates validate
```

#### Validation Rules

Checks for:

✅ **Format Validation:**
- All dates are ISO format (`YYYY-MM-DD`)
- Week numbers are sequential
- No duplicate week numbers

✅ **Logical Validation:**
- End date is after start date
- Week dates are chronological
- Exam dates are within semester range

✅ **Required Fields:**
- `start_date` and `end_date` exist
- Weeks have `number` and `start_date`

⚠️ **Warnings (not errors):**
- Deadlines outside semester range
- Holiday on a weekend (likely wrong)
- Week gaps > 8 days

#### Examples

```bash
# Validate after editing config
vim .flow/teach-config.yml
teach dates validate

# Output:
✓ Validating Date Configuration

✓ Config file exists
✓ All dates valid ISO format
✓ Week dates chronological
⚠️  Warning: holiday "Spring Break" on Saturday
✅ Validation complete: 0 errors, 1 warning
```

---

## Workflow Examples

### Daily Workflow: Checking Date Consistency

**Scenario:** You edited some files manually and want to ensure dates match the config.

```bash
# 1. Check current status
teach dates status

# 2. Preview any mismatches
teach dates sync --dry-run

# 3. If mismatches found, sync
teach dates sync

# 4. Review changes before committing
git diff

# 5. Commit
git add -A
git commit -m "chore: sync dates to config"
```

**Frequency:** Run before each deployment or weekly.

### Semester Start: Initial Date Setup

**Scenario:** Setting up dates for a new semester.

```bash
# 1. Initialize base dates
teach dates init
# Enter: 2025-01-13

# 2. Edit config to add details
vim .flow/teach-config.yml

# Add:
# - Week topics
# - Holidays (Spring break, etc.)
# - Assignment deadlines
# - Exam dates

# 3. Validate config
teach dates validate

# 4. Sync to files
teach dates sync --dry-run   # Preview
teach dates sync             # Apply

# 5. Commit setup
git add -A
git commit -m "feat: initialize Spring 2025 dates"
```

**Time:** ~15 minutes (vs 2 hours manually)

### Mid-Semester: Updating Assignment Due Dates

**Scenario:** You need to push back HW3 due date by 2 days.

```bash
# 1. Edit config (single change)
vim .flow/teach-config.yml

# Change:
deadlines:
  hw3:
    week: 5
    offset_days: 2  # Was 0 (Monday), now 2 (Wednesday)

# 2. Sync just the assignment file
teach dates sync --file assignments/hw3.qmd

# Prompt:
File: assignments/hw3.qmd
│   due: 2025-02-03 → 2025-02-05
Apply changes? [y/n/d/q] y

✓ Updated: assignments/hw3.qmd

# 3. Commit
git add .flow/teach-config.yml assignments/hw3.qmd
git commit -m "chore: extend hw3 deadline by 2 days"

# 4. Deploy
teach deploy
```

**Time:** ~15 seconds with `teach deploy -d` (or < 2 min via PR)

### Semester Rollover: New Semester Setup

**Scenario:** Rolling over Fall 2025 course to Spring 2026.

**Coming in v5.12.0:** `teach semester rollover` command

**Current workflow (manual):**

```bash
# 1. Copy course repo
cp -r ~/teaching/stat-545-fall-2025 ~/teaching/stat-545-spring-2026
cd ~/teaching/stat-545-spring-2026

# 2. Update config metadata
vim .flow/teach-config.yml

# Change:
course:
  semester: "Spring"
  year: 2026

# 3. Recalculate dates
teach dates init
# Enter new start date: 2026-01-12

# 4. Edit topics/content if needed
vim .flow/teach-config.yml

# 5. Sync all files
teach dates sync --force  # Auto-apply all

# 6. Verify
git diff | less

# 7. Commit
git add -A
git commit -m "feat: roll over to Spring 2026"
```

**Time:** ~5 minutes (vs 2+ hours of manual find/replace)

### Selective Sync: Update Only Assignments

**Scenario:** You changed assignment deadlines but don't want to touch lectures/syllabus.

```bash
# 1. Edit assignment deadlines in config
vim .flow/teach-config.yml

# 2. Sync only assignments
teach dates sync --assignments --dry-run

# Output:
Found 8 files
  Filter: assignments

⚠️  Date Mismatches Found
1. assignments/hw1.qmd (1 mismatch)
2. assignments/hw2.qmd (1 mismatch)

# 3. Apply
teach dates sync --assignments

# Prompts for each, press 'y'

# 4. Commit
git add assignments/ .flow/teach-config.yml
git commit -m "chore: update assignment deadlines"
```

---

## Date Synchronization Details

### How Date Matching Works

The sync algorithm:

1. **Extract dates from files**
   - Parse YAML frontmatter (`due:`, `date:`, etc.)
   - Scan markdown content for inline dates

2. **Load dates from config**
   - Read `semester_info` section
   - Compute relative dates (week + offset)

3. **Match file to config dates**
   - Heuristic: filename → config key
   - Example: `hw1.qmd` → `deadline_hw1`

4. **Compare and flag mismatches**
   - File date ≠ config date → mismatch

5. **Prompt user for each mismatch**
   - Show old → new date
   - Allow selective application

### Conflict Resolution

When dates don't match, the **config is always the source of truth**:

```
Config: hw1 due 2025-01-22
File:   hw1.qmd due: 2025-01-20

→ File will be updated to 2025-01-22
```

**Override:** Manually edit the file after sync if config is wrong.

**Best practice:** Always update config first, then sync.

### Backup Strategy

Safety mechanisms:

1. **Backup before modification**

   ```bash
   # Auto-created: file.qmd.bak
   ```

2. **Removed on success**

   ```bash
   # If sync succeeds, .bak file deleted
   ```

3. **Kept on error**

   ```bash
   # If sync fails, restore from .bak
   ```

4. **Git is your friend**

   ```bash
   # Always review with: git diff
   # Revert with: git restore <file>
   ```

### What Files Are Synced

**Included:**
- `assignments/*.qmd`
- `lectures/*.qmd`
- `exams/*.qmd`
- `quizzes/*.qmd`
- `slides/*.qmd`
- `rubrics/*.qmd`
- `syllabus.qmd`, `schedule.qmd`, `index.qmd` (root)

**Excluded:**
- `README.md` (not course content)
- Files in `.git/`, `_site/`, `_freeze/`
- Non-Quarto/Markdown files

**Depth:** Searches 2 levels deep in each directory

---

## Schema Reference

### weeks Array

**Structure:**

```yaml
weeks:
  - number: integer (1, 2, 3, ...)
    start_date: string (YYYY-MM-DD)
    topic: string (optional)
    notes: string (optional)
    reading: string (optional)
```

**Example:**

```yaml
weeks:
  - number: 1
    start_date: "2025-01-13"
    topic: "Introduction to R and RStudio"
    reading: "Chapter 1"
    notes: "Go slow, many students new to R"

  - number: 2
    start_date: "2025-01-20"
    topic: "Data Wrangling with dplyr"
    reading: "Chapters 3-4"
```

### holidays Array

**Structure:**

```yaml
holidays:
  - name: string
    date: string (YYYY-MM-DD)
    type: enum(break|holiday|no_class)
    notes: string (optional)
```

**Example:**

```yaml
holidays:
  - name: "Martin Luther King Jr. Day"
    date: "2025-01-20"
    type: "holiday"

  - name: "Spring Break"
    date: "2025-03-10"
    type: "break"
    notes: "Week-long break, no assignments due"

  - name: "Instructor at conference"
    date: "2025-04-15"
    type: "no_class"
```

### deadlines Object

**Structure:**

```yaml
deadlines:
  <assignment_id>:
    # Option 1: Absolute date
    due_date: string (YYYY-MM-DD)

    # Option 2: Relative date
    week: integer
    offset_days: integer

    # Optional metadata
    points: integer
    notes: string
```

**Example:**

```yaml
deadlines:
  hw1:
    week: 2
    offset_days: 4     # Friday
    points: 100

  hw2:
    week: 4
    offset_days: 4
    points: 100

  final_project:
    due_date: "2025-05-08"  # Fixed: finals week
    points: 300
```

### exams Array

**Structure:**

```yaml
exams:
  - name: string
    date: string (YYYY-MM-DD)
    time: string (optional)
    location: string (optional)
    notes: string (optional)
```

**Example:**

```yaml
exams:
  - name: "Midterm 1"
    date: "2025-02-19"
    time: "2:00 PM - 3:50 PM"
    location: "Gilman Hall 132"
    notes: "Closed book, calculator allowed"

  - name: "Midterm 2"
    date: "2025-04-02"
    time: "2:00 PM - 3:50 PM"
    location: "Gilman Hall 132"

  - name: "Final Exam"
    date: "2025-05-08"
    time: "10:00 AM - 12:00 PM"
    location: "Check registrar for room"
```

---

## Troubleshooting

### Common Issues

#### Date Format Mismatches

**Problem:**

```
ERROR: Invalid date format: 01/22/2025 (expected YYYY-MM-DD)
```

**Cause:** Date in config is not ISO format

**Fix:**

```yaml
# Wrong:
start_date: 01/22/2025

# Right:
start_date: "2025-01-22"
```

#### Missing Config Fields

**Problem:**

```
⚠️  No dates found in config
Add semester_info section to .flow/teach-config.yml
```

**Cause:** Config missing `semester_info` or it's empty

**Fix:**

```bash
# Initialize dates
teach dates init
```

Or manually add:

```yaml
semester_info:
  start_date: "2025-01-13"
  end_date: "2025-05-02"
  weeks: []
```

#### File Not Found

**Problem:**

```
ERROR: File not found: assignments/hw1.qmd
```

**Cause:** Trying to sync a file that doesn't exist

**Fix:**

```bash
# Check file path
ls assignments/

# Use correct path
teach dates sync --file assignments/homework-1.qmd
```

#### Invalid Date Calculation

**Problem:**

```
ERROR: Week 5 not found in config
```

**Cause:** Relative date references week that doesn't exist

**Fix:**

```bash
# Check week count
yq eval '.semester_info.weeks | length' .flow/teach-config.yml

# If < 15, add more weeks
teach dates init  # Regenerates 15 weeks
```

#### yq Command Not Found

**Problem:**

```
ERROR: yq required for date syncing
Install: brew install yq
```

**Cause:** `yq` not installed

**Fix:**

```bash
# macOS
brew install yq

# Linux (Debian/Ubuntu)
sudo apt install yq

# Verify
yq --version  # Should be v4.0+
```

#### Dates Not Syncing to Files

**Problem:** Ran `teach dates sync` but files unchanged

**Cause 1:** File has no date field in YAML frontmatter

**Fix:**

```yaml
# Add to file:
---
due: "2025-01-22"
---
```

**Cause 2:** Filename doesn't match config key

**Fix:**

```yaml
# If file is: homework-one.qmd
# Config key should be: homework_one

deadlines:
  homework_one:
    week: 2
    offset_days: 4
```

#### Relative Dates Not Computing

**Problem:** Config has `week: 2, offset_days: 2` but sync says "no config date"

**Cause:** Week 2 not defined in `semester_info.weeks`

**Fix:**

```bash
# Check weeks
yq eval '.semester_info.weeks[] | select(.number == 2)' .flow/teach-config.yml

# If empty, add week:
yq eval '.semester_info.weeks += [{"number": 2, "start_date": "2025-01-20"}]' -i .flow/teach-config.yml
```

#### sed/yq Corruption

**Problem:** File corrupted after sync

**Cause:** sed command malformed or yq error

**Fix:**

```bash
# Restore from backup
mv assignments/hw1.qmd.bak assignments/hw1.qmd

# Or use git
git restore assignments/hw1.qmd

# Report issue to flow-cli
```

### Error Messages Explained

| Error | Meaning | Solution |
|-------|---------|----------|
| `Invalid date format` | Date not YYYY-MM-DD | Use ISO format |
| `Week N not found` | Week missing from config | Add week to config |
| `Config file not found` | No teach-config.yml | Run `teach init` |
| `yq required` | Missing dependency | Install yq |
| `No dates in config` | Empty semester_info | Run `teach dates init` |
| `Failed to update file` | Write permission or syntax error | Check file permissions |

### Debug Mode

Enable verbose output for troubleshooting:

```bash
# Verbose sync
teach dates sync --verbose

# Shows:
# - Which files are scanned
# - Dates extracted from each file
# - Config dates loaded
# - Comparison logic
# - sed/yq commands executed
```

---

## Migration Guide

### Adding Dates to Existing Courses

**Scenario:** You have an existing course with manual dates scattered across files.

**Steps:**

```bash
# 1. Ensure you have a clean git state
git status

# 2. Initialize date config
teach dates init
# Enter semester start date

# 3. Extract existing dates from files
# (Manual step - look at assignments/hw1.qmd, etc.)

# 4. Add deadlines to config
vim .flow/teach-config.yml

# Add:
deadlines:
  hw1:
    due_date: "2025-01-22"  # Copy from hw1.qmd
  hw2:
    due_date: "2025-02-05"  # Copy from hw2.qmd
  # ... etc

# 5. Validate (should be no mismatches)
teach dates sync --dry-run

# If mismatches, fix config to match files

# 6. Now switch to relative dates
vim .flow/teach-config.yml

# Change:
deadlines:
  hw1:
    week: 2
    offset_days: 4  # Convert 2025-01-22 to week+offset

# 7. Sync (this updates files to computed dates)
teach dates sync

# 8. Commit
git add -A
git commit -m "feat: centralize course dates in config"
```

### Migrating from Manual Date Management

**Before (manual):**

```bash
# Semester rollover workflow:
# 1. Copy course directory
# 2. Find all instances of "2025" → replace with "2026"
# 3. Find all dates, manually update
# 4. Cross-check syllabus vs assignments
# 5. Fix inconsistencies
# Time: 2-4 hours
```

**After (automated):**

```bash
# Semester rollover workflow:
# 1. Update config start date
teach dates init
# Enter: 2026-01-13

# 2. Sync all files
teach dates sync --force

# 3. Commit
git add -A && git commit -m "feat: Spring 2026"

# Time: 5 minutes
```

### Rollback Strategy

If date automation causes problems:

**Option 1: Git revert**

```bash
# Undo last commit
git revert HEAD

# Or restore specific files
git restore assignments/*.qmd
```

**Option 2: Remove automation**

```bash
# Remove semester_info from config
vim .flow/teach-config.yml

# Delete:
semester_info:
  ...

# Files keep their current dates (no change)
# teach dates sync becomes no-op
```

**Option 3: Hybrid approach**

```bash
# Use automation for some files, manual for others

# In config, only add assignments:
deadlines:
  hw1:
    week: 2
    offset_days: 4

# Don't add exams (keep manual in files)
```

---

## Advanced Topics

### Multi-Meeting Weeks (Future)

**Coming in v5.12.0:** Support for courses with multiple meetings per week

```yaml
# Planned syntax:
weeks:
  - number: 1
    meetings:
      - date: "2025-01-13"
        topic: "Introduction"
      - date: "2025-01-15"
        topic: "Setup & RStudio"
```

**Current workaround:** Use single meeting date (Monday) and handle others manually

### External Calendar Import (Future)

**Planned feature:** Import university calendar (holidays, finals week)

```bash
# Planned command:
teach dates import-calendar university-calendar.ics
```

Would auto-populate `holidays` array

### Custom Date Fields

Add your own date fields to YAML frontmatter:

```yaml
---
title: "Homework 1"
due: "2025-01-22"
available: "2025-01-15"        # Custom field
peer_review_due: "2025-01-24"  # Custom field
---
```

**To sync custom fields:**

Currently: Manual process (sync handles `due` automatically)

Future: Configure which fields to sync in `teach-config.yml`

### Date Validation Rules

Customize validation strictness:

```yaml
# Planned config option:
semester_info:
  validation:
    strict_week_spacing: true   # Enforce 7-day week spacing
    allow_weekend_exams: false  # Flag exams on weekends
    warn_tight_deadlines: true  # Warn if deadlines < 7 days apart
```

---

## Best Practices

### Organizing Your Semester Config

**Structure your config logically:**

```yaml
semester_info:
  # 1. Semester boundaries (top)
  start_date: "2025-01-13"
  end_date: "2025-05-02"

  # 2. Weeks (core structure)
  weeks: [...]

  # 3. Disruptions (holidays)
  holidays: [...]

  # 4. Regular assessments (assignments)
  deadlines: {...}

  # 5. Major events (exams)
  exams: [...]
```

**Add comments for clarity:**

```yaml
# Spring 2026 semester dates
start_date: "2026-01-12"

deadlines:
  # Regular homework (due Fridays)
  hw1:
    week: 2
    offset_days: 4

  # Major project (due end of semester)
  final_project:
    due_date: "2026-05-08"
```

### Naming Conventions

**Assignment IDs:**
- Use lowercase: `hw1`, not `HW1`
- Use underscores: `hw_1`, not `hw-1`
- Match filename: `hw1.qmd` → `hw1` (not `homework_1`)

**Why?** Filename matching algorithm expects this pattern.

**Week topics:**
- Be concise: "Data Wrangling" not "Week 2: Introduction to Data Wrangling with dplyr"
- Front-load keywords: "Regression Basics" not "Basics of Regression"

### Testing Date Changes

**Always use --dry-run first:**

```bash
# Bad: Blind sync
teach dates sync --force

# Good: Preview then apply
teach dates sync --dry-run
# Review output
teach dates sync
```

**Workflow:**

1. Edit config
2. `teach dates sync --dry-run` (preview)
3. Fix any unexpected changes
4. `teach dates sync` (apply)
5. `git diff` (review)
6. Commit

### Git Workflow Integration

**Commit strategy:**

**Option 1: Separate commits**

```bash
# Commit 1: Config change
git add .flow/teach-config.yml
git commit -m "chore: update hw3 deadline"

# Commit 2: File sync
git add assignments/hw3.qmd
git commit -m "chore: sync hw3 date to config"
```

**Option 2: Combined commit**

```bash
git add .flow/teach-config.yml assignments/
git commit -m "chore: extend hw3 deadline by 2 days"
```

**Recommendation:** Use combined commits (less noise)

**Branch strategy:**

For major date changes (semester rollover):

```bash
# Create branch
git checkout -b spring-2026-dates

# Make changes
teach dates init
teach dates sync --force

# Commit
git add -A
git commit -m "feat: roll over to Spring 2026"

# PR/merge
git push origin spring-2026-dates
# Create PR on GitHub
```

---

## FAQ

### General Questions

**Q: Do I have to use date automation?**

A: No. It's optional. Without `semester_info` in config, dates in files are left alone.

**Q: Can I mix automated and manual dates?**

A: Yes. Only dates defined in config are synced. Other dates remain manual.

**Q: What if I prefer absolute dates over relative dates?**

A: Use `due_date` instead of `week + offset`. Both work.

**Q: Does this work with Markdown (.md) files?**

A: Yes. Works with both `.qmd` (Quarto) and `.md` (plain Markdown).

**Q: Can I undo a sync?**

A: Yes. Use `git restore <file>` or restore from `.bak` files.

### Technical Questions

**Q: What date formats are supported?**

A: Config requires ISO (`YYYY-MM-DD`). Files can have ISO, US (`M/D/YYYY`), or long form (`January 22, 2025`).

**Q: How are relative dates calculated?**

A: Week start date + offset days. Example: Week 2 start (2025-01-20) + 2 days = 2025-01-22.

**Q: What if I have 2 meetings per week?**

A: Currently, track one meeting per week. Multi-meeting support coming in v5.12.0.

**Q: Does sync modify prose text?**

A: Yes, if it finds dates matching old dates. Be careful with dates in examples.

**Q: What if sync breaks a file?**

A: Restore from `.bak` file or `git restore`. Report issue to flow-cli.

**Q: Can I sync only specific fields?**

A: Not yet. Sync updates all date fields it recognizes.

**Q: Does sync work offline?**

A: Yes. All operations are local (no network required).

### Workflow Questions

**Q: How often should I run sync?**

A: After editing config, and before each deployment. Or run `teach dates status` daily.

**Q: Should I sync before or after editing files?**

A: Edit config first, then sync. Config is source of truth.

**Q: Can I automate sync (run on commit)?**

A: Yes. Add to git pre-commit hook:

```bash
# .git/hooks/pre-commit
#!/bin/bash
teach dates sync --dry-run || exit 1
```

**Q: What if students already have old dates?**

A: Update config and sync, then announce change to students. They'll see new dates on website.

**Q: How do I handle last-minute deadline extensions?**

A:

```bash
# 1. Update config
vim .flow/teach-config.yml

# 2. Sync the one file
teach dates sync --file assignments/hw3.qmd

# 3. Deploy immediately
teach deploy
```

**Q: Can I preview semester rollover?**

A: Yes (after v5.12.0 `teach semester rollover` ships):

```bash
teach semester rollover --dry-run
```

---

## Examples

### Complete teach-config.yml Example

```yaml
# Course metadata
course:
  name: "STAT 545 - Statistical Programming"
  semester: "Spring"
  year: 2025
  credits: 3

# Semester schedule
semester_info:
  start_date: "2025-01-13"
  end_date: "2025-05-02"

  weeks:
    - number: 1
      start_date: "2025-01-13"
      topic: "Introduction to R and RStudio"
      reading: "Chapter 1"

    - number: 2
      start_date: "2025-01-20"
      topic: "Data Wrangling with dplyr"
      reading: "Chapters 3-4"

    - number: 3
      start_date: "2025-01-27"
      topic: "Data Visualization with ggplot2"
      reading: "Chapter 5"

    # ... weeks 4-15

  holidays:
    - name: "Martin Luther King Jr. Day"
      date: "2025-01-20"
      type: "holiday"

    - name: "Spring Break"
      date: "2025-03-10"
      type: "break"

    - name: "Good Friday"
      date: "2025-04-18"
      type: "holiday"

  deadlines:
    # Regular homework (Fridays)
    hw1:
      week: 2
      offset_days: 4
      points: 100

    hw2:
      week: 4
      offset_days: 4
      points: 100

    hw3:
      week: 6
      offset_days: 4
      points: 100

    # Project milestones (absolute dates)
    project_proposal:
      due_date: "2025-02-28"
      points: 50

    project_final:
      due_date: "2025-05-08"
      points: 300

  exams:
    - name: "Midterm 1"
      date: "2025-02-19"
      time: "2:00 PM - 3:50 PM"
      location: "Gilman Hall 132"
      notes: "Closed book, one page of notes allowed"

    - name: "Midterm 2"
      date: "2025-04-02"
      time: "2:00 PM - 3:50 PM"
      location: "Gilman Hall 132"

    - name: "Final Exam"
      date: "2025-05-08"
      time: "10:00 AM - 12:00 PM"
      location: "Per registrar (TBD)"
```

### Example Course Schedule

**File:** `schedule.qmd`

```markdown
---
title: "Course Schedule"
date: "2025-01-13"
---

# STAT 545 Schedule - Spring 2025

## Week-by-Week

### Week 1: January 13, 2025
**Topic:** Introduction to R and RStudio
**Reading:** Chapter 1
**Due:** Setup checklist (not graded)

### Week 2: January 20, 2025
**Topic:** Data Wrangling with dplyr
**Reading:** Chapters 3-4
**Due:** Homework 1 (Friday, January 22)

### Week 3: January 27, 2025
**Topic:** Data Visualization
**Reading:** Chapter 5
**Due:** Homework 2 (Friday, February 5)

## Important Dates

- **Midterm 1:** February 19, 2025 (2:00 PM)
- **Spring Break:** March 10-14, 2025
- **Midterm 2:** April 2, 2025 (2:00 PM)
- **Final Project:** Due May 8, 2025
- **Final Exam:** May 8, 2025 (10:00 AM)
```

**After running `teach dates sync`, all dates match config automatically.**

### Example Assignment with Dates

**File:** `assignments/hw1.qmd`

```yaml
---
title: "Homework 1: Data Wrangling"
subtitle: "STAT 545 - Spring 2025"
due: "2025-01-22"
points: 100
format: html
---

## Overview

This assignment covers data wrangling techniques using the `dplyr` package.

**Due Date:** Friday, January 22, 2025 at 11:59 PM

**Submission:** Upload to Canvas

## Problems

### Problem 1: Filtering Rows (20 points)

... problem description ...

### Problem 2: Creating New Variables (30 points)

... problem description ...

## Grading Rubric

...
```

**Config sync updates both YAML `due:` field and inline "January 22, 2025" text.**

---

## Reference

### Date Format Specifications

| Format | Example | Use Case | Parser Support |
|--------|---------|----------|----------------|
| ISO 8601 | `2025-01-22` | Config, YAML frontmatter | ✅ Primary |
| US Short | `1/22/2025` | Inline text | ✅ Supported |
| US Long | `January 22, 2025` | Prose, schedules | ✅ Supported |
| Abbreviated | `Jan 22, 2025` | Informal | ✅ Supported |
| Week + Offset | `week: 2, offset_days: 4` | Config only | ✅ Computed |

**Recommendation:** Use ISO format everywhere for consistency.

### Command Quick Reference

| Command | Purpose | Flags |
|---------|---------|-------|
| `teach dates sync` | Sync dates to files | `--dry-run`, `--force`, `--verbose`, `--assignments`, `--lectures`, `--file` |
| `teach dates status` | Show summary | (none) |
| `teach dates init` | Initialize wizard | (none) |
| `teach dates validate` | Validate config | (none) |

### Related Commands

| Command | Purpose |
|---------|---------|
| `teach status` | Show course status (includes date summary) |
| `teach init` | Initialize teaching workflow (calls `teach dates init` if needed) |
| `teach deploy` | Deploy changes to production |

### External Resources

- [Quarto Documentation](https://quarto.org/)
- [YAML Specification](https://yaml.org/)
- [ISO 8601 Date Format](https://en.wikipedia.org/wiki/ISO_8601)
- [yq Documentation](https://mikefarah.gitbook.io/yq/)
- [flow-cli Teaching Workflow](../tutorials/14-teach-dispatcher.md)

---

**Next:** [Command Reference](../reference/MASTER-DISPATCHER-GUIDE.md) | [Tutorial 14: Teaching Workflow](../tutorials/14-teach-dispatcher.md) | [Quick Reference Card](../reference/MASTER-API-REFERENCE.md#teaching-libraries)
