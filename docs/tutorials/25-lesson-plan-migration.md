# Tutorial: Lesson Plan Migration

> **What you'll learn:** Extract and migrate lesson plans using `teach migrate-config`
>
> **Time:** ~10 minutes | **Level:** Beginner
> **Version:** v5.20.0

---

## Prerequisites

Before starting, you should:

- [ ] Have an existing course with `teach-config.yml`
- [ ] Have `yq` installed (`brew install yq`)

**Verify your setup:**

```bash
# Check yq is installed
yq --version

# Check you have a teach-config.yml
ls .flow/teach-config.yml
```

---

## What You'll Learn

By the end of this tutorial, you will:

1. Understand the new lesson plan structure
2. Preview migration changes
3. Run the migration
4. Verify the results
5. Use the new format

---

## Step 1: Understanding the Change

**Before (embedded weeks):**

```yaml
# .flow/teach-config.yml
course:
  name: "STAT 545"

semester_info:
  semester: "Spring 2026"
  weeks:
    week-01:
      title: "Introduction"
      topics: [overview, syllabus]
    week-02:
      title: "Data Types"
      topics: [vectors, dataframes]
    # ... more weeks embedded here
```

**After (separate file):**

```yaml
# .flow/teach-config.yml
course:
  name: "STAT 545"

semester_info:
  semester: "Spring 2026"
  lesson_plans: "lesson-plans.yml"  # Reference to new file
```

```yaml
# .flow/lesson-plans.yml (NEW)
weeks:
  week-01:
    title: "Introduction"
    topics: [overview, syllabus]
  week-02:
    title: "Data Types"
    topics: [vectors, dataframes]
```

**Why?**

- Cleaner separation of concerns
- Course metadata vs curriculum content
- Easier to share lesson plans between courses
- Required for Scholar plugin coordination

---

## Step 2: Preview Migration

Always preview before migrating:

```bash
teach migrate-config --dry-run
```

**Example output:**

```
╭─────────────────────────────────────────────────────────────╮
│ MIGRATION PREVIEW (Dry Run)                                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ Source: .flow/teach-config.yml                              │
│ Target: .flow/lesson-plans.yml                              │
│                                                             │
│ Will extract 15 weeks:                                      │
│   week-01: Introduction to Statistics                       │
│   week-02: Data Types and Structures                        │
│   week-03: Descriptive Statistics                           │
│   week-04: Probability Basics                               │
│   week-05: Distributions                                    │
│   ... and 10 more weeks                                     │
│                                                             │
│ Changes to teach-config.yml:                                │
│   - Remove: semester_info.weeks (inline data)               │
│   + Add: semester_info.lesson_plans: "lesson-plans.yml"     │
│                                                             │
│ No files modified (dry run)                                 │
│                                                             │
│ Run without --dry-run to apply changes                      │
╰─────────────────────────────────────────────────────────────╯
```

---

## Step 3: Run Migration

When you're ready:

```bash
teach migrate-config
```

**What happens:**

1. Creates backup: `.flow/teach-config.yml.bak`
2. Extracts weeks to `.flow/lesson-plans.yml`
3. Updates `teach-config.yml` with reference
4. Shows summary

**Example output:**

```
╭─────────────────────────────────────────────────────────────╮
│ MIGRATION COMPLETE                                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ ✓ Created backup: .flow/teach-config.yml.bak                │
│ ✓ Extracted 15 weeks to lesson-plans.yml                    │
│ ✓ Updated teach-config.yml with reference                   │
│                                                             │
│ Files:                                                      │
│   .flow/teach-config.yml     (updated)                      │
│   .flow/lesson-plans.yml     (created)                      │
│   .flow/teach-config.yml.bak (backup)                       │
│                                                             │
│ Next steps:                                                 │
│   1. Verify: teach week --list                              │
│   2. Test: teach week 1                                     │
│   3. Delete backup when satisfied                           │
╰─────────────────────────────────────────────────────────────╯
```

---

## Step 4: Verify Results

Check the migration worked:

```bash
# List all weeks (should work same as before)
teach week --list

# View specific week
teach week 1

# Check new file exists
cat .flow/lesson-plans.yml
```

---

## Step 5: Options

### Skip Confirmation

```bash
teach migrate-config --force
```

### Skip Backup

```bash
teach migrate-config --no-backup
```

### Preview + Force (careful!)

```bash
# Preview first
teach migrate-config --dry-run

# Then apply without prompts
teach migrate-config --force
```

---

## Step 6: Backward Compatibility

**Don't want to migrate yet?** That's fine!

The old format still works with a warning:

```bash
$ teach week 1

⚠️ Using embedded weeks in teach-config.yml
   Consider migrating: teach migrate-config

Week 1: Introduction to Statistics
...
```

**The warning reminds you to migrate** but doesn't block functionality.

---

## Step 7: Restore from Backup

Made a mistake? Restore from backup:

```bash
# Check backup exists
ls .flow/teach-config.yml.bak

# Restore
cp .flow/teach-config.yml.bak .flow/teach-config.yml

# Remove migrated file
rm .flow/lesson-plans.yml
```

---

## Quick Reference

| Command | Description |
|---------|-------------|
| `teach migrate-config --dry-run` | Preview changes |
| `teach migrate-config` | Run migration |
| `teach migrate-config --force` | Skip confirmation |
| `teach migrate-config --no-backup` | Don't create .bak |

---

## File Structure After Migration

```
.flow/
├── teach-config.yml          # Course metadata + reference
├── lesson-plans.yml          # Extracted lesson plans (NEW)
└── teach-config.yml.bak      # Backup of original
```

---

## Troubleshooting

### "No embedded weeks found"

Your config may already be migrated or doesn't have weeks:

```bash
# Check for existing lesson-plans.yml
ls .flow/lesson-plans.yml

# Check teach-config.yml structure
cat .flow/teach-config.yml | grep -A5 semester_info
```

### "yq not found"

Install yq:

```bash
brew install yq
```

### Migration failed

Restore from backup:

```bash
cp .flow/teach-config.yml.bak .flow/teach-config.yml
```

---

## Scholar Integration

After migration, the Scholar plugin reads from `lesson-plans.yml` directly:

```bash
# Scholar commands work with new format
teach exam "Midterm" --week 1-7
teach quiz "Week 5" --topic "Distributions"
```

---

## Next Steps

- **Delete backup** when satisfied (`.flow/teach-config.yml.bak`)
- **Update Scholar** if you use it (`teach scholar update`)
- See [MASTER-DISPATCHER-GUIDE.md](../reference/MASTER-DISPATCHER-GUIDE.md#teach-dispatcher) for more teach commands

---

**Version:** v5.20.0
**Last Updated:** 2026-01-28
