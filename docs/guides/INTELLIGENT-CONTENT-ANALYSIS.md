# Intelligent Content Analysis Guide

**Version:** v5.16.0 (Teach Analyze Phase 1)
**Last Updated:** 2026-01-22

---

## Overview

The **Intelligent Content Analysis** system (`teach analyze`) automatically extracts concepts from lecture frontmatter and validates prerequisite ordering. This helps ensure students learn concepts in the right sequence and identifies gaps in course structure.

### Key Features

- **Automatic Concept Extraction**: Scans lecture `.qmd` files for `concepts:` frontmatter
- **Prerequisite Validation**: Detects missing or future prerequisites
- **Concept Graph Generation**: Creates `.teach/concepts.json` for visualization
- **Integration**: Works with `teach validate --concepts` and `teach status`

---

## Quick Start

### 1. Add Concepts to Lecture Frontmatter

```yaml
---
title: "Week 2: Correlation and Covariance"
week: 2
concepts:
  introduces:
    - correlation
    - covariance
  requires:
    - mean
    - variance
---
```

### 2. Run Analysis

```bash
# Analyze course and validate prerequisites
teach analyze

# Or use validation integration
teach validate --concepts
```

### 3. Check Status

```bash
# View concept summary in status dashboard
teach status
```

---

## Frontmatter Specification

### Concepts Field Structure

```yaml
concepts:
  introduces:           # Concepts taught in this lecture
    - concept-name-1
    - concept-name-2
  requires:             # Prerequisites from earlier weeks
    - prerequisite-1
    - prerequisite-2
```

### Naming Conventions

| Good | Avoid |
|------|-------|
| `mean` | `Mean` (capitalize) |
| `standard-deviation` | `standard_deviation` (underscores) |
| `t-test` | `t test` (spaces) |
| `chi-squared` | `χ²` (unicode) |

### Complete Example

```yaml
---
title: "Introduction to Regression"
subtitle: "Week 3 - Simple Linear Regression"
week: 3
date: "2026-01-27"

concepts:
  introduces:
    - simple-regression
    - residuals
    - r-squared
  requires:
    - correlation
    - variance
    - mean
---

# Introduction to Regression

Today we'll build on our understanding of correlation...
```

---

## Commands

### teach analyze

Builds concept graph and validates prerequisites.

```bash
# Basic usage
teach analyze

# Verbose output
teach analyze --verbose

# Output as JSON (for scripting)
teach analyze --json

# Help
teach analyze --help
```

**Output:**

```
📊 Concept Analysis

Building concept graph...
✓ Found 18 concepts across 6 weeks

Validating prerequisites...
✓ All prerequisites satisfied (18 concepts checked)

Concept graph saved to .teach/concepts.json
```

### teach validate --concepts

Integrated validation with other checks.

```bash
# Run all validations including concepts
teach validate --concepts

# Concept validation only (quiet mode)
teach validate --concepts --quiet

# Combined with YAML validation
teach validate --yaml --concepts
```

### teach status

View concept summary in status dashboard.

```bash
teach status
```

Shows:
```
┌─────────────────────────────────────────────────┐
│ 📚 STAT 440 - Regression Analysis              │
├─────────────────────────────────────────────────┤
│ 📊 Concepts    │ 18 concepts, 6 weeks (2h ago) │
└─────────────────────────────────────────────────┘
```

---

## Concept Graph File

Analysis creates `.teach/concepts.json`:

```json
{
  "version": "1.0",
  "schema_version": "concept-graph-v1",
  "metadata": {
    "last_updated": "2026-01-22T12:00:00Z",
    "course_hash": "abc123def456",
    "total_concepts": 9,
    "weeks": 3,
    "extraction_method": "frontmatter"
  },
  "concepts": {
    "mean": {
      "id": "mean",
      "name": "Mean",
      "prerequisites": [],
      "introduced_in": {
        "week": 1,
        "lecture": "lectures/week-01-lecture.qmd",
        "line_number": 8
      }
    },
    "variance": {
      "id": "variance",
      "name": "Variance",
      "prerequisites": ["mean"],
      "introduced_in": {
        "week": 1,
        "lecture": "lectures/week-01-lecture.qmd",
        "line_number": 9
      }
    }
  }
}
```

### Use Cases

- **Visualization**: Generate dependency diagrams with Mermaid
- **Syllabus Generation**: Auto-populate concept lists
- **Student Resources**: Create prerequisite checklists
- **CI/CD**: Validate course structure on push

---

## Configuration

### teach-config.yml

Add concept analysis settings to your course config:

```yaml
# Concept analysis settings (v5.16.0+)
concepts:
  # Enable concept extraction from frontmatter
  auto_extract: true

  # Validation settings
  analysis:
    strict_ordering: true    # Enforce week-based prerequisite ordering
    warn_orphans: false      # Warn about concepts with no prerequisites

  # Optional: Week-level concept definitions (overrides frontmatter)
  # weeks:
  #   1:
  #     introduces: [mean, variance, standard-deviation]
  #     requires: []
  #   2:
  #     introduces: [correlation, covariance]
  #     requires: [mean, variance]

  # Optional: External prerequisites (concepts assumed known)
  # global_prerequisites:
  #   - concept: calculus
  #     required_for: [optimization, derivatives]
  #     introduced: 'external'
```

### Configuration Options

| Option | Default | Description |
|--------|---------|-------------|
| `auto_extract` | `true` | Scan lecture frontmatter automatically |
| `strict_ordering` | `true` | Prerequisites must be taught in earlier weeks |
| `warn_orphans` | `false` | Warn about concepts with no prerequisites |

---

## Validation Rules

### 1. Missing Prerequisites

**Error:** A concept requires a prerequisite that is never introduced.

```
✗ ERROR: Missing prerequisite: variance
   Week 2 requires 'variance' but it's never introduced
   Suggestion: Add variance to earlier week
```

**Fix:** Add the missing concept to an earlier lecture's `introduces:` list.

### 2. Future Prerequisites

**Warning:** A concept requires a prerequisite introduced in a later week.

```
⚠ WARNING: Future prerequisite: correlation
   Week 2 requires 'correlation' but it's introduced in week 4
   Suggestion: Reorder content or move correlation earlier
```

**Fix:** Either reorder lectures or adjust the prerequisite declaration.

### 3. Orphan Concepts (optional)

Concepts with no prerequisites (when `warn_orphans: true`):

```
⚠ WARNING: Orphan concept: probability
   'probability' has no prerequisites
   This may be intentional for foundational concepts
```

---

## Best Practices

### 1. Start Simple

Begin with fundamental concepts that have no prerequisites:

```yaml
# Week 1 - Foundations
concepts:
  introduces:
    - mean
    - variance
    - standard-deviation
  requires: []  # No prerequisites for first week
```

### 2. Build Incrementally

Each week should build on previous concepts:

```yaml
# Week 2
concepts:
  introduces:
    - correlation
    - covariance
  requires:
    - mean      # From week 1
    - variance  # From week 1
```

### 3. Be Explicit

List all prerequisites, even if they seem obvious:

```yaml
# Week 3
concepts:
  introduces:
    - simple-regression
  requires:
    - correlation  # Direct prerequisite
    - variance     # Also needed for regression
    - mean         # Foundation for everything
```

### 4. Use Consistent Naming

Pick a naming convention and stick to it:

```yaml
# Good: lowercase with hyphens
introduces:
  - standard-deviation
  - chi-squared
  - t-test

# Avoid: mixed conventions
introduces:
  - Standard_Deviation  # ❌ Mixed case and underscores
  - chi squared         # ❌ Spaces
  - TTest               # ❌ Camel case
```

### 5. Run Analysis Regularly

Integrate into your workflow:

```bash
# Before content changes
teach validate --concepts

# After adding new lectures
teach analyze

# Check status dashboard
teach status
```

---

## Troubleshooting

### "No concepts found"

**Cause:** Lectures don't have `concepts:` in frontmatter.

**Solution:**
```yaml
---
title: "Week 1 Lecture"
week: 1
concepts:          # Add this block
  introduces:
    - mean
  requires: []
---
```

### "yq not found"

**Cause:** Missing YAML parser dependency.

**Solution:**
```bash
# Install yq
brew install yq

# Or verify with teach doctor
teach doctor --fix
```

### Concept count mismatch

**Cause:** Duplicate concept names or parsing issues.

**Solution:**
```bash
# Check the generated graph
cat .teach/concepts.json | jq '.concepts | keys'

# Look for duplicates or variations
```

### Prerequisites not detected

**Cause:** Typos in concept names between files.

**Solution:**
```bash
# List all unique concept names
grep -r "introduces:" lectures/ | sort -u
grep -r "requires:" lectures/ | sort -u

# Compare for inconsistencies
```

---

## Integration with Scholar

The concept graph can be used with Scholar for intelligent content generation:

```bash
# Generate exam covering specific concepts
teach exam "Midterm 1" --concepts correlation,regression

# Generate quiz for recent concepts
teach quiz "Week 3 Check" --concepts-from-week 3

# Validate that exam covers prerequisites
teach validate --exam exams/midterm1.md --concepts
```

---

## API Reference

### Functions (for developers)

| Function | Purpose |
|----------|---------|
| `_extract_concepts_from_frontmatter` | Parse YAML frontmatter |
| `_parse_introduced_concepts` | Get `introduces:` array |
| `_parse_required_concepts` | Get `requires:` array |
| `_build_concept_graph` | Create full concept graph |
| `_check_prerequisites` | Validate prerequisites |
| `_find_missing_prerequisites` | Detect missing prereqs |
| `_find_future_prerequisites` | Detect future prereqs |

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success (all prerequisites satisfied) |
| `1+` | Number of missing prerequisites |

---

## Related Documentation

- [Teaching Workflow Guide](TEACHING-WORKFLOW-V3-GUIDE.md)
- [Teach Dispatcher Reference](../reference/TEACH-DISPATCHER-REFERENCE-v5.14.0.md)
- [Configuration Schema](../../lib/templates/teaching/teach-config.schema.json)

---

**Next Steps:**
1. Add `concepts:` to your lecture frontmatter
2. Run `teach analyze` to build concept graph
3. Fix any prerequisite issues
4. Check `teach status` for summary
