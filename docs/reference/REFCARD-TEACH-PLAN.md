# Lesson Plan Quick Reference Card

> Quick reference for `teach plan` command (v5.22.0+)

## Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `teach plan create <week>` | `teach pl c` | Add week to lesson plans |
| `teach plan list` | `teach pl ls` | Show all weeks in table |
| `teach plan show <week>` | `teach pl s` | Display week details |
| `teach plan edit <week>` | `teach pl e` | Open in $EDITOR at line |
| `teach plan delete <week>` | `teach pl del` | Remove week (with confirm) |
| `teach plan help` | `teach pl help` | Show usage help |
| `teach plan <number>` | — | Shortcut for show |

## Quick Examples

```bash
# Create a week with topic and style
teach plan create 3 --topic "Probability" --style rigorous

# Create interactively (prompted for details)
teach plan create 5

# Auto-populate topic from teach-config.yml
teach plan create 5 --style computational

# List all weeks (table with gap detection)
teach plan list

# List as JSON (for scripting)
teach plan list --json

# Show week details
teach plan show 3
teach plan 3                 # shortcut

# Show as JSON
teach plan show 3 --json

# Edit in $EDITOR (jumps to correct line)
teach plan edit 3

# Delete with confirmation
teach plan delete 3

# Force delete (no prompt)
teach plan delete 3 --force

# Overwrite existing week
teach plan create 3 --topic "Updated" --force
```

## Options

| Flag | Short | Description |
|------|-------|-------------|
| `--topic` | `-t` | Topic name (bypasses interactive prompt) |
| `--style` | `-s` | Content style preset |
| `--force` | `-f` | Skip confirmation / overwrite existing |
| `--json` | `-j` | Machine-readable JSON output |
| `--help` | `-h` | Show help |

## Styles

| Style | Description | Use For |
|-------|-------------|---------|
| `conceptual` | Theory and understanding | Intro lectures, foundations |
| `computational` | Methods and calculations | Labs, applied work |
| `rigorous` | Proofs and formal treatment | Advanced theory, proofs |
| `applied` | Real-world applications | Case studies, projects |

## YAML Schema

```yaml
# .flow/lesson-plans.yml
weeks:
  - number: 3
    topic: "Probability Foundations"
    style: "rigorous"
    objectives:
      - "Define sample spaces and events"
      - "Apply counting rules"
    subtopics:
      - "Axioms of probability"
      - "Conditional probability"
    key_concepts: []
    prerequisites: []
```

## Auto-Populate from Config

When `--topic` is omitted, `teach plan create` reads from `.flow/teach-config.yml`:

```yaml
# .flow/teach-config.yml
semester_info:
  weeks:
    - number: 5
      topic: "Polynomial Regression"   # ← auto-used
```

## Integration

| Tool | How It Uses Plans |
|------|-------------------|
| `teach slides --week N` | Reads topic, style, objectives from plan |
| `teach lecture --week N` | Uses plan data for lecture generation |
| `teach exam --week N` | References key concepts from plan |
| Scholar plugin | Loads plan via `_teach_load_lesson_plan()` |

## Workflow

```
teach migrate-config          # Step 1: Extract from old config
  ↓
teach plan list               # Step 2: Review what migrated
  ↓
teach plan create N           # Step 3: Add missing weeks
  ↓
teach plan edit N             # Step 4: Refine details
  ↓
teach slides --week N         # Step 5: Generate content
```

## Gap Detection

`teach plan list` warns about missing weeks:

```
  3 week(s) total
  ⚠ Gaps: weeks 2 4
```

## Boundary Values

| Constraint | Value |
|-----------|-------|
| Min week | 1 |
| Max week | 20 |
| Valid styles | conceptual, computational, rigorous, applied |

## Files

| File | Purpose |
|------|---------|
| `.flow/lesson-plans.yml` | Centralized lesson plan data |
| `.flow/teach-config.yml` | Course config (topic auto-populate source) |
| `.flow/lesson-plans.yml.bak` | Temporary backup during writes |

## See Also

- [Dispatcher Guide: Lesson Plans](MASTER-DISPATCHER-GUIDE.md) — Full dispatcher reference
- [Tutorial 25: Migration](../tutorials/25-lesson-plan-migration.md) — Migration + plan workflow
- [API Reference](MASTER-API-REFERENCE.md) — Function signatures

---

**Version:** v5.22.0
**Last Updated:** 2026-01-29
