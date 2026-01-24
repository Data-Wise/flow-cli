# Teaching Dates Quick Reference

**One-page command reference for date automation**

**Version:** 5.11.0 | **Last Updated:** 2026-01-16

---

## Commands

### teach dates sync

Synchronize dates from config to files.

```bash
# Preview changes
teach dates sync --dry-run

# Interactive sync (default)
teach dates sync

# Auto-apply all changes
teach dates sync --force

# Sync only assignments
teach dates sync --assignments

# Sync only lectures
teach dates sync --lectures

# Sync specific file
teach dates sync --file assignments/hw3.qmd

# Verbose output
teach dates sync -v
```

### teach dates status

Show date configuration summary.

```bash
teach dates status
```

### teach dates init

Initialize date configuration wizard.

```bash
teach dates init
```

### teach dates validate

Validate date configuration.

```bash
teach dates validate
```

---

## Config Structure

```yaml
semester_info:
  start_date: "2025-01-13"      # Required
  end_date: "2025-05-02"        # Required

  weeks:                        # Required
    - number: 1
      start_date: "2025-01-13"
      topic: "Introduction"

  deadlines:                    # Optional
    hw1:
      week: 2                   # Relative date
      offset_days: 4            # Friday of week 2

    final_exam:
      due_date: "2025-05-08"    # Absolute date

  exams:                        # Optional
    - name: "Midterm"
      date: "2025-03-05"
      time: "2:00 PM - 3:50 PM"
      location: "Gilman Hall 132"

  holidays:                     # Optional
    - name: "Spring Break"
      date: "2025-03-10"
      type: "break"
```

---

## Date Formats

| Format | Example | Use |
|--------|---------|-----|
| **ISO** | `2025-01-22` | Config, YAML frontmatter ✅ |
| **US Short** | `1/22/2025` | Inline text |
| **US Long** | `January 22, 2025` | Prose |
| **Relative** | `week: 2, offset_days: 4` | Deadlines |

**Recommendation:** Always use ISO format in config.

---

## Common Workflows

### Initial Setup

```bash
# 1. Initialize
teach dates init
# Enter: 2025-01-13

# 2. Edit config
vim .flow/teach-config.yml

# 3. Preview sync
teach dates sync --dry-run

# 4. Apply
teach dates sync
```

### Change Deadline

```bash
# 1. Edit config
vim .flow/teach-config.yml

# 2. Sync one file
teach dates sync --file assignments/hw3.qmd

# 3. Deploy
teach deploy
```

### Semester Rollover

```bash
# 1. Reinitialize with new start date
teach dates init
# Enter: 2026-01-13

# 2. Sync all files
teach dates sync --force

# 3. Commit
git add -A && git commit -m "feat: Spring 2026"
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `yq required` | `brew install yq` |
| `No dates in config` | Run `teach dates init` |
| `Week N not found` | Add week to config |
| `Invalid date format` | Use ISO: `YYYY-MM-DD` |
| File not syncing | Check filename matches config key |

---

## Flags Reference

| Flag | Command | Description |
|------|---------|-------------|
| `--dry-run` | sync | Preview only |
| `--force` | sync | Skip prompts |
| `--verbose, -v` | sync | Show details |
| `--assignments` | sync | Assignments only |
| `--lectures` | sync | Lectures only |
| `--syllabus` | sync | Syllabus/schedule only |
| `--file <path>` | sync | Single file |

---

## Interactive Prompts

```
Apply changes? [y/n/d/q]
  y - Yes, update this file
  n - No, skip this file
  d - Show diff
  q - Quit (stop syncing)
```

---

## Files Synced

**Included:**
- `assignments/*.qmd`
- `lectures/*.qmd`
- `exams/*.qmd`, `quizzes/*.qmd`
- `syllabus.qmd`, `schedule.qmd`

**Excluded:**
- `README.md`
- Files in `.git/`, `_site/`, `_freeze/`

---

## Examples

### Absolute Date

```yaml
deadlines:
  final_project:
    due_date: "2025-05-08"
```

### Relative Date

```yaml
deadlines:
  hw1:
    week: 2
    offset_days: 4  # Week 2 Monday + 4 = Friday
```

**Calculation:**
- Week 2 start: `2025-01-20` (Monday)
- +4 days = `2025-01-22` (Friday)

---

## Quick Links

- **Full Guide:** [Teaching Dates Guide](../guides/TEACHING-DATES-GUIDE.md)
- **Tutorial:** [Teaching Workflow](../tutorials/14-teach-dispatcher.md)
- **Dispatcher Ref:** [DISPATCHER-REFERENCE.md](DISPATCHER-REFERENCE.md)

---

**Pro Tips:**

✅ Always use `--dry-run` first
✅ Use relative dates for regular assignments
✅ Use absolute dates for fixed events
✅ Run `git diff` before committing
✅ Validate config after manual edits
