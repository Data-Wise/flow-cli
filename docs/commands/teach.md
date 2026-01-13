# teach - Teaching Workflow Dispatcher

Unified command interface for managing course websites and teaching workflows.

## Quick Start

```bash
# Initialize a new course
teach init "STAT 545"

# Non-interactive mode (accept defaults)
teach init -y "STAT 440"

# Check project status
teach status

# Deploy changes to production
teach deploy
```

---

## Synopsis

```bash
teach <command> [args]
```

---

## Commands

| Command | Shortcut | Description |
|---------|----------|-------------|
| `init [name]` | `i` | Initialize teaching workflow |
| `exam [name]` | `e` | Create exam/quiz |
| `deploy` | `d` | Deploy draft → production |
| `archive` | `a` | Archive semester |
| `config` | `c` | Edit teach-config.yml |
| `status` | `s` | Show project status |
| `week` | `w` | Show current week number |
| `help` | `-h` | Show help |

---

## Examples

### Initialize a New Course

```bash
# Interactive mode (prompts for options)
teach init "STAT 545"

# Non-interactive mode (uses safe defaults)
teach init -y "STAT 545"

# Preview migration plan without changes
teach init --dry-run "STAT 545"
```

### Daily Workflow

```bash
# Start working
work stat-545

# Check current week
teach week

# Make edits...

# Deploy when ready
teach deploy
```

### End of Semester

```bash
# Archive the semester
teach archive

# This creates a tagged snapshot and prepares for next semester
```

### Create Exam

```bash
# Create a new exam
teach exam "Midterm 1"

# Uses examark if installed
```

---

## Subcommand Details

### `teach init`

Initialize teaching workflow for a course repository. Creates:
- `.flow/teach-config.yml` - Course configuration
- `scripts/quick-deploy.sh` - Deployment script
- `scripts/semester-archive.sh` - Archive script
- Branch structure (`draft` / `production`)

**Flags:**
- `-y`, `--yes` - Non-interactive mode (accept safe defaults)
- `--dry-run` - Preview migration plan without changes
- `-h`, `--help` - Show help

**See:** [teach-init](teach-init.md) for full documentation.

### `teach deploy`

Deploy changes from `draft` branch to `production` branch.

```bash
teach deploy
# Runs ./scripts/quick-deploy.sh
```

### `teach archive`

Archive the current semester before starting a new one.

```bash
teach archive
# Runs ./scripts/semester-archive.sh
```

### `teach status`

Show teaching project status including:
- Course name and semester
- Current branch
- Safety warnings (if on production)

```bash
teach status
# 📚 Teaching Project Status
# ━━━━━━━━━━━━━━━━━━━━━━━━━━
#   Course:   STAT 545
#   Semester: Spring 2026
#   Branch:   draft
#   ✓ Safe to edit (draft branch)
```

### `teach week`

Show current week number based on semester start date.

```bash
teach week
# 📅 Week 8
#   Semester started: 2026-01-13
#   Days elapsed: 52
```

### `teach config`

Open the teaching configuration file in your editor.

```bash
teach config
# Opens .flow/teach-config.yml in $EDITOR
```

---

## Configuration

Teaching projects use `.flow/teach-config.yml`:

```yaml
course:
  name: STAT 545
  code: stat-545
  semester: Spring 2026

semester:
  start_date: 2026-01-13
  end_date: 2026-05-08

branches:
  draft: draft
  production: production
```

---

## Related Commands

| Command | Purpose |
|---------|---------|
| [teach-init](teach-init.md) | Full initialization docs |
| [teach-exam](teach-exam.md) | Create exams |
| [work](work.md) | Start work session |
| [finish](finish.md) | End work session |

---

## See Also

- [Teaching Workflow Guide](../guides/TEACHING-WORKFLOW.md)
- [Teaching Reference Card](../reference/REFCARD-TEACHING.md)
- [Dispatcher Reference](../reference/DISPATCHER-REFERENCE.md#10-teach---teaching-workflow)
