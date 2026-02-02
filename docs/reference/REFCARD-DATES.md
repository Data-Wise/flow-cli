# Date Management Quick Reference Card

> Quick reference for `teach dates` command (v5.11.0+)

## Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `teach dates sync` | `teach dates s` | Synchronize dates from config to files |
| `teach dates status` | `teach dates st` | Show date consistency status |
| `teach dates init` | `teach dates i` | Initialize date configuration wizard |
| `teach dates validate` | `teach dates v` | Validate date configuration |
| `teach dates help` | - | Show usage help |

## Quick Examples

```bash
# Initialize dates for semester
teach dates init

# Preview changes (dry-run)
teach dates sync --dry-run

# Interactive sync with prompts
teach dates sync

# Auto-apply all changes
teach dates sync --force

# Sync only assignments
teach dates sync --assignments

# Sync only lectures
teach dates sync --lectures

# Sync only syllabus
teach dates sync --syllabus

# Sync specific file
teach dates sync --file assignments/hw1.qmd

# Check status
teach dates status

# Validate configuration
teach dates validate

# Verbose output
teach dates sync --verbose
```

## sync Options

| Flag | Short | Description |
|------|-------|-------------|
| `--dry-run` | - | Preview changes without modifying files |
| `--force` | - | Skip prompts, apply all changes automatically |
| `--verbose` | `-v` | Show detailed progress |
| `--assignments` | - | Sync only assignment files |
| `--lectures` | - | Sync only lecture files |
| `--syllabus` | - | Sync only syllabus/schedule files |
| `--file` | - | Sync a specific file |
| `--help` | `-h` | Show help |

## Date Format

All dates must be in **YYYY-MM-DD** format:

```yaml
# Valid
start_date: "2026-01-13"
deadline_hw1: "2026-02-03"

# Invalid
start_date: "01/13/2026"
deadline_hw1: "Feb 3, 2026"
```

## Configuration Structure

```yaml
# .flow/teach-config.yml
semester_info:
  start_date: "2026-01-13"
  end_date: "2026-04-28"

  weeks:
    - number: 1
      start_date: "2026-01-13"
      topic: "Introduction to Statistics"

    - number: 2
      start_date: "2026-01-20"
      topic: "Probability Foundations"

  deadlines:
    deadline_hw1: "2026-02-03"
    deadline_hw2: "2026-02-17"
    deadline_midterm: "2026-03-10"
    deadline_final: "2026-04-28"

  holidays:
    - date: "2026-03-16"
      name: "Spring Break"
```

## Workflow

```
teach dates init              # Step 1: Generate semester dates
  ↓
Edit .flow/teach-config.yml   # Step 2: Customize weeks/deadlines
  ↓
teach dates sync --dry-run    # Step 3: Preview changes
  ↓
teach dates sync              # Step 4: Apply changes interactively
  ↓
teach dates validate          # Step 5: Verify configuration
```

## Sync Behavior

### Interactive Mode (default)

For each file with mismatches:

```
File: assignments/hw1.qmd
├─────────────────────────────────────────────────────────────┤
│ YAML Frontmatter:
│   due: 2026-01-30 → 2026-02-03
├─────────────────────────────────────────────────────────────┤
Apply changes? [y/n/d/q]
```

Options:
- `y` - Apply changes
- `n` - Skip this file
- `d` - Show diff preview
- `q` - Quit

### Force Mode (`--force`)

Automatically applies all changes without prompts.

## Date Matching Logic

Files are matched to config dates using:

1. **Filename patterns**: `hw1.qmd` → `deadline_hw1`
2. **Directory context**: `/assignments/` or `/lectures/`
3. **YAML frontmatter**: `due:` field extracted

## File Discovery

Scans for teaching files:

```
lectures/*.qmd
lectures/*.md
assignments/*.qmd
assignments/*.md
syllabus.qmd
schedule.qmd
```

## Status Output

```bash
teach dates status

📅 Date Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Config Dates Loaded: 17
Teaching Files Found: 12
```

## init Wizard

```bash
teach dates init

Semester start date (YYYY-MM-DD): 2026-01-13

Generating 15 weeks starting from 2026-01-13...

✓ Date configuration initialized!
  Start: 2026-01-13
  End:   2026-04-28
  Weeks: 15
```

## Validation Checks

```bash
teach dates validate

✓ Validating Date Configuration

✓ Config file exists
✓ Course name: STAT-101
✓ Semester: Spring 2026
✓ Dates configured (2026-01-13 - 2026-04-28)
```

## STAT-101 Demo Example

```bash
# Navigate to demo course
cd tests/fixtures/demo-course

# Initialize dates
teach dates init

# Edit config to add deadlines
vim .flow/teach-config.yml

# Preview changes
teach dates sync --dry-run

# Apply changes
teach dates sync --force

# Verify
teach dates validate
```

## Integration

| Tool | How It Uses Dates |
|------|-------------------|
| `teach init` | Sets up initial date structure |
| `teach validate` | Checks date consistency |
| `teach analyze` | Uses week numbers for sequencing |
| Scholar plugin | References semester timeline |

## Common Patterns

```bash
# Setup workflow
teach init --with-dates
teach dates init
teach dates sync --force

# Semester rollover
teach dates init
teach dates sync --dry-run
# Review changes
teach dates sync

# Fix one file
teach dates sync --file lectures/week-05.qmd

# Check before deploy
teach dates validate
teach dates status
```

## Dependencies

| Tool | Purpose | Install |
|------|---------|---------|
| `yq` | YAML processing | `brew install yq` |

## See Also

- [Dispatcher Guide: teach dates](MASTER-DISPATCHER-GUIDE.md) — Full command reference
- [Tutorial 20: Date Management](../tutorials/20-teaching-dates-automation.md) — Date workflow
- [API Reference](MASTER-API-REFERENCE.md) — Function signatures

---

**Version:** v5.11.0
**Last Updated:** 2026-02-02
