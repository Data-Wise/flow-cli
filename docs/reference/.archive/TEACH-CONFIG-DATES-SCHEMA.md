# teach-config.yml Dates Schema Reference

**Version:** v5.11.0
**Status:** Complete
**Last Updated:** 2026-01-16

---

## Overview

This document provides complete reference documentation for the `semester_info` section of `teach-config.yml`. This section stores all temporal information for a course: weeks, holidays, deadlines, and exams.

**Schema Location:** `lib/templates/teaching/teach-config.schema.json`

**Primary Use:** Single source of truth for all course dates

---

## Quick Reference

```yaml
semester_info:
  start_date: "YYYY-MM-DD"           # Required
  end_date: "YYYY-MM-DD"             # Required
  
  weeks:                             # Required
    - number: integer
      start_date: "YYYY-MM-DD"
      topic: string
  
  holidays:                          # Optional
    - name: string
      date: "YYYY-MM-DD"
      type: enum
  
  deadlines:                         # Optional
    <assignment_id>:
      due_date: "YYYY-MM-DD"         # Absolute
      # OR
      week: integer                  # Relative
      offset_days: integer
  
  exams:                             # Optional
    - name: string
      date: "YYYY-MM-DD"
```

---

## Field Reference

### semester_info (Root Object)

Container for all semester schedule information.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `start_date` | string | ✅ | Semester start date (YYYY-MM-DD) |
| `end_date` | string | ✅ | Semester end date (YYYY-MM-DD) |
| `weeks` | array | ✅ | Weekly schedule |
| `holidays` | array | ❌ | Holidays and breaks |
| `deadlines` | object | ❌ | Assignment deadlines |
| `exams` | array | ❌ | Exam schedule |

**Example:**

```yaml
semester_info:
  start_date: "2025-01-13"
  end_date: "2025-05-02"
  weeks: [...]
  holidays: [...]
  deadlines: {...}
  exams: [...]
```

---

### weeks (Array)

Weekly schedule with start dates and topics.

**Schema:**

```json
{
  "type": "array",
  "items": {
    "type": "object",
    "required": ["number", "start_date"],
    "properties": {
      "number": {"type": "integer", "minimum": 1, "maximum": 52},
      "start_date": {"type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}$"},
      "topic": {"type": "string"}
    }
  }
}
```

**Fields:**

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| `number` | integer | ✅ | 1-52 | Week number (sequential) |
| `start_date` | string | ✅ | YYYY-MM-DD | Week start date |
| `topic` | string | ❌ | - | Week topic or title |

**Example:**

```yaml
weeks:
  - number: 1
    start_date: "2025-01-13"
    topic: "Introduction to R and RStudio"
  
  - number: 2
    start_date: "2025-01-20"
    topic: "Data Wrangling with dplyr"
  
  - number: 3
    start_date: "2025-01-27"
    topic: "Data Visualization with ggplot2"
```

**Validation Rules:**
- Week numbers must be sequential (1, 2, 3, ...)
- No duplicate week numbers
- Start dates should be chronological
- Typical range: 15-16 weeks per semester

---

### holidays (Array)

Holidays, breaks, and no-class days.

**Schema:**

```json
{
  "type": "array",
  "items": {
    "type": "object",
    "required": ["name", "date"],
    "properties": {
      "name": {"type": "string"},
      "date": {"type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}$"},
      "type": {"enum": ["break", "holiday", "no_class"]}
    }
  }
}
```

**Fields:**

| Field | Type | Required | Values | Description |
|-------|------|----------|--------|-------------|
| `name` | string | ✅ | Any | Holiday name |
| `date` | string | ✅ | YYYY-MM-DD | Holiday date |
| `type` | enum | ❌ | break, holiday, no_class | Holiday type |

**Holiday Types:**

| Type | Use Case | Example |
|------|----------|---------|
| `break` | Multi-day break | Spring Break, Fall Break |
| `holiday` | University closed | MLK Day, Thanksgiving |
| `no_class` | Instructor absence | Conference, personal day |

**Example:**

```yaml
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
  
  - name: "Instructor at JSM Conference"
    date: "2025-08-10"
    type: "no_class"
```

---

### deadlines (Object)

Assignment deadlines (absolute or relative dates).

**Schema:**

```json
{
  "type": "object",
  "additionalProperties": {
    "type": "object",
    "oneOf": [
      {
        "required": ["due_date"],
        "properties": {
          "due_date": {"type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}$"}
        }
      },
      {
        "required": ["week", "offset_days"],
        "properties": {
          "week": {"type": "integer", "minimum": 1, "maximum": 52},
          "offset_days": {"type": "integer"}
        }
      }
    ]
  }
}
```

**Key Format:** `<assignment_id>` (lowercase, underscores, matches filename)

**Option 1: Absolute Date**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `due_date` | string | ✅ | Absolute due date (YYYY-MM-DD) |

```yaml
deadlines:
  final_project:
    due_date: "2025-05-08"  # Fixed date (finals week)
```

**Option 2: Relative Date**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `week` | integer | ✅ | Week number (1-52) |
| `offset_days` | integer | ✅ | Days offset from week start (can be negative) |

```yaml
deadlines:
  hw1:
    week: 2
    offset_days: 4   # Friday of Week 2 (Mon + 4 days)
  
  reading_quiz:
    week: 3
    offset_days: -1  # Sunday before Week 3
```

**Complete Example:**

```yaml
deadlines:
  # Regular homework (Fridays)
  hw1:
    week: 2
    offset_days: 4
  
  hw2:
    week: 4
    offset_days: 4
  
  hw3:
    week: 6
    offset_days: 4
  
  # Project milestones (absolute dates)
  project_proposal:
    due_date: "2025-02-28"
  
  project_final:
    due_date: "2025-05-08"
  
  # Reading (Sunday before lecture)
  reading_week3:
    week: 3
    offset_days: -1
```

**Validation Rules:**
- Must provide `due_date` XOR (`week` AND `offset_days`)
- Week must exist in `semester_info.weeks`
- Computed dates should fall within semester range (warning if not)

---

### exams (Array)

Exam schedule with dates, times, and locations.

**Schema:**

```json
{
  "type": "array",
  "items": {
    "type": "object",
    "required": ["name", "date"],
    "properties": {
      "name": {"type": "string"},
      "date": {"type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}$"},
      "time": {"type": "string"},
      "location": {"type": "string"}
    }
  }
}
```

**Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | ✅ | Exam name |
| `date` | string | ✅ | Exam date (YYYY-MM-DD) |
| `time` | string | ❌ | Exam time |
| `location` | string | ❌ | Exam location |

**Example:**

```yaml
exams:
  - name: "Midterm 1"
    date: "2025-02-19"
    time: "2:00 PM - 3:50 PM"
    location: "Gilman Hall 132"
  
  - name: "Midterm 2"
    date: "2025-04-02"
    time: "2:00 PM - 3:50 PM"
    location: "Gilman Hall 132"
  
  - name: "Final Exam"
    date: "2025-05-08"
    time: "10:00 AM - 12:00 PM"
    location: "Per registrar (TBD)"
```

**Validation Rules:**
- Exam dates should fall within semester range
- No duplicate exam names
- Date format must be YYYY-MM-DD

---

## Complete Examples

### Minimal Configuration

```yaml
semester_info:
  start_date: "2025-01-13"
  end_date: "2025-05-02"
  
  weeks:
    - number: 1
      start_date: "2025-01-13"
    - number: 2
      start_date: "2025-01-20"
    # ... 13 more weeks
```

### Standard Course (15 weeks)

```yaml
semester_info:
  start_date: "2025-01-13"
  end_date: "2025-05-02"
  
  weeks:
    - number: 1
      start_date: "2025-01-13"
      topic: "Introduction"
    - number: 2
      start_date: "2025-01-20"
      topic: "Data Wrangling"
    - number: 3
      start_date: "2025-01-27"
      topic: "Visualization"
    # ... weeks 4-15
  
  holidays:
    - name: "Spring Break"
      date: "2025-03-10"
      type: "break"
  
  deadlines:
    hw1: {week: 2, offset_days: 4}
    hw2: {week: 4, offset_days: 4}
    hw3: {week: 6, offset_days: 4}
  
  exams:
    - name: "Midterm"
      date: "2025-03-05"
      time: "2:00 PM"
    - name: "Final"
      date: "2025-05-08"
      time: "10:00 AM"
```

### Complex Course (with multiple assignment types)

```yaml
semester_info:
  start_date: "2025-01-13"
  end_date: "2025-05-02"
  
  weeks:
    - number: 1
      start_date: "2025-01-13"
      topic: "Introduction to R"
    # ... weeks 2-15
  
  holidays:
    - name: "MLK Day"
      date: "2025-01-20"
      type: "holiday"
    - name: "Spring Break"
      date: "2025-03-10"
      type: "break"
    - name: "Good Friday"
      date: "2025-04-18"
      type: "holiday"
  
  deadlines:
    # Weekly homework (Fridays)
    hw1: {week: 2, offset_days: 4}
    hw2: {week: 4, offset_days: 4}
    hw3: {week: 6, offset_days: 4}
    hw4: {week: 8, offset_days: 4}
    hw5: {week: 10, offset_days: 4}
    
    # Reading quizzes (Sunday before lecture)
    quiz_week3: {week: 3, offset_days: -1}
    quiz_week5: {week: 5, offset_days: -1}
    quiz_week7: {week: 7, offset_days: -1}
    
    # Project milestones (absolute dates)
    project_proposal:
      due_date: "2025-02-28"
    project_draft:
      due_date: "2025-04-11"
    project_final:
      due_date: "2025-05-08"
  
  exams:
    - name: "Midterm 1"
      date: "2025-02-19"
      time: "2:00 PM - 3:50 PM"
      location: "Gilman Hall 132"
    - name: "Midterm 2"
      date: "2025-04-02"
      time: "2:00 PM - 3:50 PM"
      location: "Gilman Hall 132"
    - name: "Final Exam"
      date: "2025-05-08"
      time: "10:00 AM - 12:00 PM"
      location: "Per registrar"
```

---

## Validation

### JSON Schema Validation

The config is validated against `teach-config.schema.json`:

```bash
# Validate config
teach dates validate

# Or use yq + ajv
yq eval . .flow/teach-config.yml | \
  ajv validate -s lib/templates/teaching/teach-config.schema.json
```

### Common Validation Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Pattern mismatch: start_date` | Wrong date format | Use YYYY-MM-DD |
| `Missing required property: weeks` | No weeks array | Add weeks array |
| `Additional property not allowed: due_dat` | Typo in field name | Fix typo: `due_date` |
| `Must match exactly one schema` (deadlines) | Both `due_date` and `week` provided | Use one or the other |
| `Value out of range: number` | Week number < 1 or > 52 | Use 1-52 |

---

## Best Practices

### Week Numbering

✅ **Do:** Use sequential week numbers starting at 1

```yaml
weeks:
  - number: 1
  - number: 2
  - number: 3
```

❌ **Don't:** Skip numbers or use non-sequential

```yaml
weeks:
  - number: 1
  - number: 3  # ← Skipped 2
  - number: 2  # ← Out of order
```

### Date Format Consistency

✅ **Do:** Always use ISO format (YYYY-MM-DD)

```yaml
start_date: "2025-01-13"
end_date: "2025-05-02"
```

❌ **Don't:** Mix date formats

```yaml
start_date: "01/13/2025"  # ← US format
end_date: "2025-05-02"    # ← ISO format
```

### Assignment IDs

✅ **Do:** Match filename (lowercase, underscores)

```yaml
deadlines:
  hw1: {...}          # ← matches assignments/hw1.qmd
  project_proposal: {...}  # ← matches assignments/project_proposal.qmd
```

❌ **Don't:** Use different naming

```yaml
deadlines:
  HW1: {...}              # ← uppercase doesn't match hw1.qmd
  project-proposal: {...} # ← hyphen doesn't match project_proposal.qmd
```

### Relative vs Absolute Dates

✅ **Use Relative** for regular assignments (tied to schedule)

```yaml
hw1: {week: 2, offset_days: 4}  # Always Friday of Week 2
```

✅ **Use Absolute** for fixed external deadlines

```yaml
final_project:
  due_date: "2025-05-08"  # Finals week (fixed by registrar)
```

---

## Migration from Manual Dates

### Step 1: Extract Existing Dates

```bash
# Find all due dates in files
grep -r "due:" assignments/ lectures/ | \
  sed 's/^.*due: "\([^"]*\)".*$/\1/' | \
  sort -u
```

### Step 2: Add to Config

```yaml
deadlines:
  hw1:
    due_date: "2025-01-22"  # Copy from grep output
  hw2:
    due_date: "2025-02-05"
  # ... etc
```

### Step 3: Validate

```bash
# Dry-run to check
teach dates sync --dry-run

# Should show: 0 mismatches
```

### Step 4: Switch to Relative Dates

```yaml
# Convert absolute to relative
deadlines:
  hw1:
    week: 2              # Jan 13 + 7 days = Jan 20
    offset_days: 2       # Jan 20 + 2 days = Jan 22
```

---

## See Also

- [Teaching Dates Guide](../guides/TEACHING-DATES-GUIDE.md) - User guide
- [Date Parser API](DATE-PARSER-API-REFERENCE.md) - API documentation
- [Architecture](../architecture/TEACHING-DATES-ARCHITECTURE.md) - System design

---

**Last Updated:** 2026-01-16
**Version:** v5.11.0
**Status:** Complete
