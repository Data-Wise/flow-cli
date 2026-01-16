# Command Naming Options - Teaching Dates Automation

**Date:** 2026-01-16
**Context:** Teaching dates automation feature (Track C, v5.11.0)
**Goal:** Design intuitive command structure and keywords for date management

---

## Overview

The date automation feature needs a command structure that:

- Integrates naturally with existing `teach` dispatcher
- Supports multiple operations (sync, preview, rollover, status)
- Follows flow-cli conventions (discoverable, consistent, ADHD-friendly)
- Minimizes cognitive load for instructors

---

## Command Structure Options

### Option A: `teach dates` (Subcommand Hierarchy) ⭐ RECOMMENDED

**Pattern:** `teach dates <action> [options]`

```bash
# Core operations
teach dates sync              # Sync dates from config to all files
teach dates sync --dry-run    # Preview changes without applying
teach dates preview           # Show what would be synced (alias for --dry-run)
teach dates status            # Show date summary and inconsistencies

# Semester management
teach dates rollover          # Wizard for new semester (shift all dates)
teach dates init              # Initialize date config section
teach dates validate          # Check date consistency across files

# Selective sync
teach dates sync --assignments    # Only assignment files
teach dates sync --lectures       # Only lecture files
teach dates sync --syllabus       # Only syllabus
teach dates sync --file <path>    # Specific file

# Advanced
teach dates detect            # Auto-detect dates in files
teach dates import            # Import dates from external calendar
```

**Pros:**

- Natural grouping under `teach` dispatcher
- Intuitive action verbs (sync, rollover, preview)
- Scales well (easy to add new date-related commands)
- Matches existing pattern (`teach status`, `teach deploy`)

**Cons:**

- Two-word subcommand (teach + dates) might feel verbose
- Could be confused with "teaching dates" vs "date management"

**Help Output:**

```
teach dates help

Date Management for Teaching Materials

Usage: teach dates <action> [options]

ACTIONS:
  sync              Sync dates from config to teaching files
  preview           Preview date changes without applying
  status            Show date summary and inconsistencies
  rollover          Start new semester (shift all dates)
  init              Initialize date config section
  validate          Check date consistency across files

OPTIONS:
  --dry-run         Preview changes without applying
  --assignments     Only sync assignment files
  --lectures        Only sync lecture files
  --syllabus        Only sync syllabus
  --file <path>     Sync specific file
  --force           Skip confirmation prompts
  --verbose         Show detailed output

EXAMPLES:
  teach dates sync                    # Interactive sync all files
  teach dates sync --dry-run          # Preview without changes
  teach dates rollover                # Start new semester wizard
  teach dates status                  # Check date consistency
  teach dates sync --assignments      # Only update assignment dates
```

---

### Option B: `teach semester` (Semester-Centric)

**Pattern:** `teach semester <action> [options]`

```bash
# Semester operations
teach semester sync           # Sync dates for current semester
teach semester new            # Create new semester (rollover)
teach semester status         # Show semester date summary
teach semester validate       # Check consistency

# Date operations
teach semester dates          # Show all dates
teach semester dates sync     # Sync dates
teach semester dates rollover # Roll dates to new semester
```

**Pros:**

- Emphasizes semester as the organizing concept
- Clear semantic meaning (semester operations)
- Natural for `teach semester new` (rollover)

**Cons:**

- Less clear that it's about date management
- Mixes high-level (semester) with low-level (date sync)
- Harder to extend beyond semester context

---

### Option C: `teach sync` (Action-First)

**Pattern:** `teach sync dates [options]`

```bash
teach sync dates              # Sync all dates
teach sync dates --assignments
teach sync dates --preview
teach sync dates --rollover   # New semester
```

**Pros:**

- Emphasizes the action (sync)
- Shorter command
- Could extend to `teach sync config`, `teach sync files`

**Cons:**

- Less discoverable (hidden under `sync`)
- Doesn't scale well for non-sync operations (status, validate, init)
- Breaks from `teach <noun>` pattern

---

### Option D: Top-Level `dates` Dispatcher (New Dispatcher)

**Pattern:** `dates <action> [context]`

```bash
# General date operations
dates sync                    # Sync dates in current project
dates status                  # Show date summary
dates rollover                # New semester wizard

# Context-specific
dates sync teach              # Sync teaching dates
dates sync project            # Sync project dates (future)
```

**Pros:**

- Reusable beyond teaching context
- Shorter commands
- Clear domain separation

**Cons:**

- Breaking from flow-cli convention (no single-letter dispatchers anymore)
- Less discoverable (not under `teach`)
- Over-engineering for single use case
- Teaching-specific needs might clash with general date operations

---

## Action Verb Options

### Primary Actions

| Verb         | Meaning                         | Example                |
| ------------ | ------------------------------- | ---------------------- |
| **sync**     | Sync dates from config to files | `teach dates sync`     |
| **preview**  | Show changes without applying   | `teach dates preview`  |
| **status**   | Show date summary               | `teach dates status`   |
| **rollover** | New semester wizard             | `teach dates rollover` |
| **init**     | Initialize date config          | `teach dates init`     |
| **validate** | Check consistency               | `teach dates validate` |

### Alternative Verbs Considered

| Verb           | Why Not?                                         |
| -------------- | ------------------------------------------------ |
| **update**     | Too generic, implies modification without source |
| **apply**      | Implies changes already defined elsewhere        |
| **refresh**    | Ambiguous (from where?)                          |
| **propagate**  | Too technical                                    |
| **distribute** | Too formal                                       |
| **cascade**    | Too technical                                    |

---

## Flag Options

### Universal Flags (All Commands)

```bash
--dry-run          # Preview without applying (MANDATORY)
--verbose          # Detailed output
--quiet            # Minimal output
--force            # Skip confirmations (dangerous)
--help, -h         # Show help
```

### Sync-Specific Flags

```bash
# File filters
--assignments      # Only assignment files
--lectures         # Only lecture files
--syllabus         # Only syllabus
--schedule         # Only course schedule
--file <path>      # Specific file

# Behavior
--interactive      # Prompt for each file (default)
--auto             # No prompts (use with --dry-run first)
--backup           # Create backup before changes
```

### Rollover-Specific Flags

```bash
--semester <name>  # New semester name
--start <date>     # New start date (YYYY-MM-DD)
--shift <weeks>    # Shift dates by N weeks
--preserve         # Preserve relative spacing
```

---

## Keyword Alternatives

### For "Sync"

- **sync** ⭐ - Industry standard, clear meaning
- **update** - Too generic
- **apply** - Implies pre-existing changes
- **refresh** - Ambiguous direction

### For "Rollover"

- **rollover** ⭐ - Financial term, implies cyclical change
- **new** - Too ambiguous (new what?)
- **migrate** - Too technical
- **rotate** - Implies circular, not forward
- **advance** - Less common

### For "Preview"

- **preview** ⭐ - Clear visual metaphor
- **diff** - Too technical (git-specific)
- **show** - Too generic
- **check** - Ambiguous with validate

---

## Recommended Command Structure

### Primary Commands (Option A: `teach dates`)

```bash
# Daily workflow
teach dates sync              # Main command: interactive sync
teach dates sync --dry-run    # Preview before applying
teach dates status            # Check consistency

# Semester rollover
teach dates rollover          # Wizard: new semester dates

# Setup & validation
teach dates init              # First-time setup
teach dates validate          # Check consistency

# Selective operations
teach dates sync --assignments
teach dates sync --lectures
teach dates sync --file path/to/file.qmd
```

### Aliases (For Convenience)

```bash
# Short aliases
teach ds                      # teach dates sync
teach dr                      # teach dates rollover
teach dv                      # teach dates validate

# Alternative names
teach sync-dates              # alias for teach dates sync
teach new-semester            # alias for teach dates rollover
```

---

## Help System Design

### Top-Level Help

```bash
teach help

Teaching Workflow Commands

DISPATCHERS:
  ...
  dates             Manage semester dates and deadlines
  ...

For detailed help: teach <command> help
```

### Dates Help

```bash
teach dates help

Date Management for Teaching Materials

Centralize dates in teach-config.yml and sync to all teaching files
(syllabus, assignments, lectures, schedule). Supports Quarto YAML
frontmatter and inline markdown dates.

USAGE:
  teach dates <action> [options]

CORE ACTIONS:
  sync              Sync dates from config to teaching files
                    Interactive by default, prompts for each file

  preview           Preview date changes without applying
                    (Alias for: teach dates sync --dry-run)

  status            Show date summary and inconsistencies
                    Lists all dates, missing dates, conflicts

SEMESTER MANAGEMENT:
  rollover          Start new semester wizard
                    - Shift all dates by N weeks
                    - Update semester name
                    - Preserve relative spacing

  init              Initialize date config section
                    Adds semester_info to teach-config.yml

VALIDATION:
  validate          Check date consistency across files
                    Reports mismatches between config and files

OPTIONS:
  --dry-run         Preview changes without applying
  --assignments     Only sync assignment files
  --lectures        Only sync lecture files
  --syllabus        Only sync syllabus
  --file <path>     Sync specific file
  --force           Skip confirmation prompts
  --verbose         Show detailed output
  --quiet           Minimal output

EXAMPLES:
  # Daily workflow
  teach dates status                  # Check what needs syncing
  teach dates sync --dry-run          # Preview changes
  teach dates sync                    # Apply changes interactively

  # Semester rollover
  teach dates rollover                # Wizard for new semester

  # Selective sync
  teach dates sync --assignments      # Only update assignments
  teach dates sync --file hw01.qmd    # Single file

  # Setup
  teach dates init                    # First-time config setup
  teach dates validate                # Check consistency

CONFIG STRUCTURE:
  teach-config.yml should contain:

  semester_info:
    start_date: "2025-01-13"
    end_date: "2025-05-02"

    weeks:
      - number: 1
        start_date: "2025-01-13"
        topic: "Introduction"

    deadlines:
      hw1:
        week: 2
        offset_days: 2    # Due 2 days after Week 2 starts

    exams:
      - name: "Midterm 1"
        date: "2025-02-24"
        time: "2:00 PM"

    holidays:
      - name: "Spring Break"
        date: "2025-03-10"
        type: "break"

SUPPORTED DATE FORMATS:
  - Quarto YAML: date: "2025-01-13"
  - Markdown inline: Week 3: January 22, 2025
  - Relative: hw1 due Week 2 + 2 days

For more: https://flow-cli.io/guides/teaching-dates
```

---

## Tab Completion Design

### Completion Structure

```bash
# Level 1: teach dates <TAB>
teach dates <TAB>
→ sync  preview  status  rollover  init  validate  help

# Level 2: teach dates sync <TAB>
teach dates sync <TAB>
→ --dry-run  --assignments  --lectures  --syllabus  --file  --force  --verbose

# Level 3: teach dates sync --file <TAB>
teach dates sync --file <TAB>
→ syllabus.qmd  hw01.qmd  hw02.qmd  lecture01.qmd  ...
```

### Smart Context-Aware Completion

```bash
# If no date config exists, suggest init
teach dates <TAB>
→ init  help

# If dates exist but not synced, prioritize sync
teach dates <TAB>
→ sync* preview  status  rollover  validate  help
```

---

## UX Considerations

### ADHD-Friendly Design

1. **Immediate Feedback**

   ```bash
   teach dates sync
   → Found 12 files with dates
   → 8 need updates, 4 are current
   → Processing files interactively...
   ```

2. **Clear Next Steps**

   ```bash
   teach dates status
   → ⚠️  5 files have outdated dates
   → Run 'teach dates sync' to update
   ```

3. **Safe by Default**

   ```bash
   teach dates sync
   → Preview changes for each file
   → Confirm before applying
   → Always use --dry-run first if unsure
   ```

4. **Progress Indicators**
   ```bash
   teach dates sync
   → [1/8] hw01.qmd - Update due date? [y/n/a/q]
   → [2/8] hw02.qmd - Update due date? [y/n/a/q]
   ```

### Error Messages

```bash
# No config
teach dates sync
→ ❌ Error: No date config found in teach-config.yml
→ Run 'teach dates init' to create date config
→ Or see: teach dates help

# Conflicting dates
teach dates validate
→ ⚠️  Found 3 date conflicts:
→   hw01.qmd: Feb 5 (file) vs Feb 3 (config)
→   hw02.qmd: Feb 12 (file) vs Feb 10 (config)
→ Run 'teach dates sync' to resolve

# Invalid date format
teach dates sync
→ ❌ Error: Invalid date format in config
→   weeks[2].start_date: "Jan 22" (should be YYYY-MM-DD)
→ Fix teach-config.yml and try again
```

---

## Comparison Matrix

| Aspect              | Option A: `teach dates` | Option B: `teach semester` | Option C: `teach sync` | Option D: `dates` |
| ------------------- | ----------------------- | -------------------------- | ---------------------- | ----------------- |
| **Discoverability** | ⭐⭐⭐⭐⭐              | ⭐⭐⭐⭐                   | ⭐⭐⭐                 | ⭐⭐              |
| **Clarity**         | ⭐⭐⭐⭐⭐              | ⭐⭐⭐⭐                   | ⭐⭐⭐                 | ⭐⭐⭐⭐          |
| **Consistency**     | ⭐⭐⭐⭐⭐              | ⭐⭐⭐⭐                   | ⭐⭐⭐                 | ⭐⭐              |
| **Extensibility**   | ⭐⭐⭐⭐⭐              | ⭐⭐⭐                     | ⭐⭐⭐⭐               | ⭐⭐⭐⭐⭐        |
| **Brevity**         | ⭐⭐⭐⭐                | ⭐⭐⭐⭐                   | ⭐⭐⭐⭐⭐             | ⭐⭐⭐⭐⭐        |
| **ADHD-Friendly**   | ⭐⭐⭐⭐⭐              | ⭐⭐⭐⭐                   | ⭐⭐⭐                 | ⭐⭐⭐            |

---

## Final Recommendation

### Primary: Option A (`teach dates`)

**Command Structure:**

```bash
teach dates sync              # Main command
teach dates sync --dry-run    # Safe preview
teach dates status            # Check consistency
teach dates rollover          # New semester
teach dates init              # Setup
teach dates validate          # Validate
```

**Rationale:**

1. **Discoverability**: Natural fit under `teach` dispatcher
2. **Clarity**: `dates` clearly indicates domain
3. **Consistency**: Matches `teach status`, `teach deploy` pattern
4. **Extensibility**: Easy to add new date operations
5. **ADHD-Friendly**: Clear, predictable, safe defaults

**Aliases for Power Users:**

```bash
alias tds='teach dates sync'
alias tdr='teach dates rollover'
alias tdv='teach dates validate'
```

---

## Implementation Notes

### Phase 1: Core Commands

- `teach dates sync` (with --dry-run)
- `teach dates status`
- `teach dates init`

### Phase 2: Semester Management

- `teach dates rollover`
- `teach dates validate`

### Phase 3: Selective Sync

- `--assignments`, `--lectures`, `--syllabus` flags
- `--file <path>` for single-file sync

### Phase 4: Advanced

- `teach dates import` (external calendar)
- `teach dates detect` (auto-discover dates)
- `teach dates export` (to calendar format)

---

## Alternative Considerations

### If User Prefers Shorter Commands

Use top-level `dates` dispatcher (Option D):

```bash
dates sync                    # Instead of teach dates sync
dates status                  # Instead of teach dates status
dates rollover                # Instead of teach dates rollover
```

**Trade-offs:**

- ✅ Shorter, faster to type
- ✅ Could extend to non-teaching contexts
- ❌ Less discoverable (not under `teach`)
- ❌ Breaks flow-cli convention (no single-letter dispatchers)

### If User Prefers Semester Focus

Use `teach semester` (Option B):

```bash
teach semester sync           # Instead of teach dates sync
teach semester new            # Instead of teach dates rollover
teach semester status         # Instead of teach dates status
```

**Trade-offs:**

- ✅ Emphasizes semester lifecycle
- ✅ Natural for `teach semester new`
- ❌ Less clear about date management
- ❌ Harder to extend beyond semester

---

## Questions for User

1. **Command Length**: Do you prefer `teach dates sync` (clear) or `dates sync` (short)?
2. **Action Verb**: Do you prefer `sync` (industry standard) or `update` (more common)?
3. **Rollover Command**: Do you prefer `teach dates rollover` or `teach dates new` or `teach semester new`?
4. **Aliases**: Should we provide short aliases (`tds`, `tdr`) by default?
5. **Preview Command**: Should `preview` be a standalone command or just `--dry-run` flag?

---

**Created:** 2026-01-16
**For:** Teaching Dates Automation (Track C, v5.11.0)
**Status:** Awaiting user feedback on command structure
