# Tutorial: Lesson Plan Management

> **What you'll learn:** Create, manage, and use lesson plans with `teach plan` to drive AI content generation
>
> **Time:** ~15 minutes | **Level:** Beginner
> **Version:** v5.22.0

---

## Prerequisites

Before starting, you should:

- [ ] Have an initialized course (`teach init`)
- [ ] Have flow-cli v5.22.0+ installed
- [ ] Have `yq` installed (`brew install yq`)

**Verify your setup:**

```bash
# Check version
flow --version  # Should show 5.22.0+

# Check you're in a course directory
ls .flow/teach-config.yml

# Check yq is available
yq --version
```

---

## What You'll Learn

By the end of this tutorial, you will:

1. Understand the lesson plan structure and purpose
2. Create lesson plans for individual weeks
3. List and review plans with gap detection
4. View detailed plan content
5. Edit plans in your editor
6. Use plans with Scholar for content generation
7. Manage plans over a semester lifecycle

---

## Step 1: Understanding Lesson Plans

### What Is a Lesson Plan?

A lesson plan is a structured YAML entry for a single week that captures:

- **Topic** - What the week covers
- **Style** - Teaching approach (conceptual, computational, rigorous, applied)
- **Objectives** - What students should learn
- **Subtopics** - Detailed breakdown
- **Key concepts** and **prerequisites** - For dependency tracking

### Where Are Plans Stored?

All plans live in a single centralized file:

```
.flow/lesson-plans.yml
```

This is different from the old format where plans were embedded in `teach-config.yml`. If you have an existing config with embedded weeks, see [Tutorial 25: Migration](25-lesson-plan-migration.md) first.

### Why Use Lesson Plans?

Plans inform Scholar's content generation. When you run:

```bash
teach slides --week 5
teach lecture --week 5
teach exam --week 5
```

Scholar reads the plan for week 5 to generate more targeted, course-specific content.

---

## Step 2: Create Your First Plan

### With Flags (Quick)

```bash
teach plan create 1 --topic "Introduction to Regression" --style conceptual
```

You'll be prompted for optional objectives and subtopics:

```
Objectives (comma-separated, Enter to skip): Define regression, Identify variables
Subtopics (comma-separated, Enter to skip): Dependent vs independent, Scatter plots

✓ Created lesson plan for Week 1: "Introduction to Regression" (conceptual)
```

### Fully Interactive

Just provide the week number:

```bash
teach plan create 2
```

You'll be prompted for everything:

```
Topic for Week 2: Multiple Regression
Style [conceptual/computational/rigorous/applied] (default: conceptual): computational
Objectives (comma-separated, Enter to skip): Fit multiple regression, Interpret coefficients
Subtopics (comma-separated, Enter to skip): Matrix formulation, Adjusted R-squared
```

### Auto-Populate from Config

If your `teach-config.yml` has week topics defined, they're used automatically:

```bash
# Creates week 5 with topic from config — no --topic needed
teach plan create 5 --style applied
```

```
ℹ Auto-populated topic from config: "Polynomial Regression"
```

---

## Step 3: List and Review Plans

### Table View

```bash
teach plan list
```

```
  Week   Topic                               Style           Objectives
  ────   ─────────────────────────────────── ─────────────── ──────────
  1      Introduction to Regression          conceptual      2
  2      Multiple Regression                 computational   2
  5      Polynomial Regression               applied         0

  3 week(s) total
  ⚠ Gaps: weeks 3 4
```

The gap detection tells you which weeks still need plans.

### JSON Output (for Scripts)

```bash
teach plan list --json
```

```json
[
  {"number": 1, "topic": "Introduction to Regression", "style": "conceptual", ...},
  {"number": 2, "topic": "Multiple Regression", "style": "computational", ...},
  {"number": 5, "topic": "Polynomial Regression", "style": "applied", ...}
]
```

---

## Step 4: View Plan Details

### Formatted Display

```bash
teach plan show 1
```

```
╔════════════════════════════════════════════════════╗
║  Week 1: Introduction to Regression
╚════════════════════════════════════════════════════╝

  Style:          conceptual

  Objectives:
    • Define regression
    • Identify variables

  Subtopics:
    - Dependent vs independent
    - Scatter plots

  Edit:   teach plan edit 1
  Delete: teach plan delete 1
```

### Quick View (Shortcut)

```bash
teach plan 1    # Same as teach plan show 1
```

### JSON Output

```bash
teach plan show 1 --json
```

---

## Step 5: Edit Plans

Open a plan in your `$EDITOR` — it jumps directly to the correct line:

```bash
teach plan edit 1
```

```
ℹ Week 1 starts at line 3
```

Your editor opens `lesson-plans.yml` at the right position. After saving, YAML is validated automatically:

```
✓ YAML validated successfully
```

If the YAML is invalid after editing, you get up to 3 retries:

```
✗ Invalid YAML detected after edit
Re-open editor to fix? [Y/n]:
```

---

## Step 6: Use Plans with Scholar

Plans integrate directly with content generation commands:

```bash
# Generate slides — uses plan topic, style, and objectives
teach slides --week 1

# Generate lecture notes — includes plan context
teach lecture --week 2

# Generate exam — references key concepts
teach exam --week 5
```

Scholar reads the plan and adjusts its output:

- **Topic** drives the content focus
- **Style** affects the approach (proofs for rigorous, examples for applied)
- **Objectives** become learning outcomes in generated materials
- **Prerequisites** inform assumed knowledge

---

## Step 7: Semester Lifecycle

### Build Out All Weeks

```bash
# Create remaining weeks (auto-populate topics from config)
for w in 3 4 6 7 8 9 10 11 12 13 14 15; do
    teach plan create $w --style conceptual
done

# Review the full semester
teach plan list
```

### Modify a Plan

```bash
# Overwrite an existing week
teach plan create 5 --topic "Updated Topic" --style rigorous --force
```

### Remove a Week

```bash
# With confirmation prompt
teach plan delete 8

# Skip confirmation
teach plan delete 8 --force
```

### Review Before Content Generation

Before generating materials for a week, check the plan:

```bash
teach plan 5           # Review plan
teach slides --week 5  # Generate slides
```

---

## Quick Reference

| Action | Command |
|--------|---------|
| Create week | `teach plan create 3 --topic "T" --style S` |
| Create interactively | `teach plan create 3` |
| List all | `teach plan list` |
| List as JSON | `teach plan list --json` |
| Show week | `teach plan show 3` or `teach plan 3` |
| Edit in editor | `teach plan edit 3` |
| Delete week | `teach plan delete 3 --force` |
| Overwrite week | `teach plan create 3 --force` |

**Shortcuts:** `teach pl` = `teach plan`, `c` = create, `ls` = list, `s` = show, `e` = edit, `del` = delete

---

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| "yq not found" | yq not installed | `brew install yq` |
| ".flow directory not found" | Not in a course dir | `teach init` or `cd` to course |
| "Week N already exists" | Duplicate week | Use `--force` to overwrite |
| "Week must be between 1 and 20" | Invalid week number | Use weeks 1-20 |
| "Invalid style" | Typo in style name | Use: conceptual, computational, rigorous, applied |

---

## Next Steps

- **Add detail** to plans with `teach plan edit` (key concepts, prerequisites)
- **Generate content** using `teach slides --week N`, `teach lecture --week N`
- **Export** plans with `teach plan list --json` for integration
- See [REFCARD: Lesson Plans](../reference/REFCARD-TEACH-PLAN.md) for complete reference
- See [Tutorial 25: Migration](25-lesson-plan-migration.md) if upgrading from embedded config

---

**Version:** v5.22.0
**Last Updated:** 2026-01-29
