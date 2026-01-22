# Intelligent Content Analysis Guide

**Version:** v5.16.0 (Teach Analyze Phase 5)
**Last Updated:** 2026-01-22

---

## Overview

The **Intelligent Content Analysis** system (`teach analyze`) automatically extracts concepts from lecture frontmatter and validates prerequisite ordering. This helps ensure students learn concepts in the right sequence and identifies gaps in course structure.

### Key Features

**Core (Phase 0-1):**
- **Automatic Concept Extraction**: Scans lecture `.qmd` files for `concepts:` frontmatter
- **Prerequisite Validation**: Detects missing or future prerequisites
- **Concept Graph Generation**: Creates `.teach/concepts.json` for visualization
- **Integration**: Works with `teach validate --concepts` and `teach status`

**Advanced (Phase 2):**
- **Smart Caching**: Content-hash based cache with 85%+ hit rate
- **Report Generation**: Markdown and JSON reports for analysis results
- **Interactive Mode**: Guided analysis with ADHD-friendly prompts
- **Deep Validation**: Layer 6 validation with deploy blocking

**AI-Powered (Phase 3):**
- **AI Analysis**: Claude-powered pedagogical analysis (`--ai` flag)
- **Cost Tracking**: Monitor and review AI usage costs (`--costs`)
- **Pedagogical Insights**: Learning objective alignment, difficulty assessment

**Slide Optimization (Phase 4):**
- **Slide Break Analysis**: Detect where slides need breaks (`--slide-breaks`)
- **Break Preview**: Detailed preview of suggested breaks (`--preview-breaks`)
- **Key Concept Callouts**: Auto-identify concepts for slide emphasis
- **Time Estimation**: Presentation timing from content density

**Polish (Phase 5):**
- **Improved Error Messages**: File suggestions, extension warnings
- **Dependency Checks**: jq/yq availability with install hints
- **Slide Cache**: SHA-256 content-hash caching for slide optimization

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

# Interactive mode (guided analysis)
teach analyze --interactive

# Generate a report
teach analyze --report analysis-report.md

# Or use validation integration
teach validate --concepts
```

### 3. Check Status

```bash
# View concept summary in status dashboard
teach status

# View cache statistics
teach analyze --stats
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

# Interactive mode (guided analysis)
teach analyze --interactive
teach analyze -i

# Generate report
teach analyze --report analysis.md
teach analyze --report analysis.json --format json

# View cache statistics
teach analyze --stats

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

### teach analyze --interactive

Guided, ADHD-friendly analysis with step-by-step prompts.

```bash
teach analyze --interactive
# or
teach analyze -i
```

**Interactive Mode Flow:**

```
┌──────────────────────────────────────────────────────────────┐
│  🔬 INTERACTIVE CONCEPT ANALYSIS                             │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  Select analysis scope:                                      │
│  1) Full course                                              │
│  2) Single week                                              │
│  3) Single file                                              │
│                                                              │
│  > 1                                                         │
│                                                              │
│  Select analysis mode:                                       │
│  1) Quick (concepts only)                                    │
│  2) Full (concepts + prerequisites)                          │
│  3) Deep (+ cache rebuild)                                   │
│                                                              │
│  > 2                                                         │
│                                                              │
│  ⏳ Analyzing... ████████████████████ 100%                   │
│                                                              │
│  ✓ Found 18 concepts across 6 weeks                          │
│  ⚠ 2 warnings found                                          │
│                                                              │
│  Review violations? (y/n) > y                                │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

**Features:**
- Step-by-step scope and mode selection
- Progress indicators during analysis
- Review violations one at a time
- Suggested fixes with confirmation
- Clear next steps at completion

### teach analyze --report

Generate analysis reports in markdown or JSON format.

```bash
# Markdown report (default)
teach analyze --report analysis.md

# JSON report for scripting/CI
teach analyze --report analysis.json --format json

# Summary only
teach analyze --report summary.md --summary-only

# Violations only
teach analyze --report violations.md --violations-only
```

**Markdown Report Structure:**

```markdown
# Concept Analysis Report

**Course:** STAT 440 - Regression Analysis
**Generated:** 2026-01-22 14:30:00
**Cache Status:** HIT (85% hit rate)

## Summary

| Metric | Value |
|--------|-------|
| Total Concepts | 18 |
| Weeks Covered | 6 |
| Missing Prerequisites | 0 |
| Future Prerequisites | 2 |
| Orphan Concepts | 3 |

## Violations

### ⚠ Future Prerequisites

| Concept | Required By | Introduced In |
|---------|-------------|---------------|
| correlation | Week 2 | Week 4 |

## Recommendations

1. Move `correlation` introduction to Week 1
2. Consider adding prerequisites for orphan concepts
```

**JSON Report Structure:**

```json
{
  "metadata": {
    "course": "STAT 440",
    "generated": "2026-01-22T14:30:00Z",
    "cache_status": "HIT"
  },
  "summary": {
    "total_concepts": 18,
    "weeks": 6,
    "errors": 0,
    "warnings": 2
  },
  "violations": [...],
  "recommendations": [...]
}
```

### teach analyze --stats

View cache statistics and performance metrics.

```bash
teach analyze --stats
```

**Output:**

```
📊 Cache Statistics

Cache Location: .teach/analysis-cache/
Cache Size: 128 KB (42 entries)

Performance:
  Hit Rate: 87.3%
  Avg Read Time: 2ms
  Avg Write Time: 8ms

Storage:
  Lectures: 24 entries (64 KB)
  Assignments: 12 entries (32 KB)
  Exams: 6 entries (32 KB)

Last Rebuild: 2h ago
Next Expiry: 4 entries in 6h
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

### teach validate --deep

**Phase 2 Feature:** Layer 6 deep validation with cache integration.

```bash
# Deep validation (Layer 6 - concept analysis)
teach validate --deep

# Combine with other layers
teach validate --yaml --syntax --deep

# Quiet mode for CI
teach validate --deep --quiet
```

**Output:**

```
🔍 Validation (Layer 6 - Concept Analysis)

Checking cache... HIT (87% hit rate)
Building concept graph from cache...
✓ Loaded 18 concepts from cache

Validating prerequisites...
✓ 16 concepts: prerequisites satisfied
⚠ 2 concepts: future prerequisites (warnings)
✗ 0 concepts: missing prerequisites (errors)

Layer 6 Result: PASS (2 warnings)
```

**Validation Layers:**

| Layer | Name | Command Flag |
|-------|------|--------------|
| 1 | YAML Frontmatter | `--yaml` |
| 2 | Syntax Check | `--syntax` |
| 3 | Render Test | `--render` |
| 4 | Empty Chunks | (automatic) |
| 5 | Image References | (automatic) |
| **6** | **Concept Analysis** | `--deep` |

### teach deploy --check-prereqs

**Phase 2 Feature:** Block deployment on missing prerequisites.

```bash
# Deploy with prerequisite checking
teach deploy --check-prereqs

# Dry-run to see what would be blocked
teach deploy --check-prereqs --dry-run
```

**Behavior:**

- **Errors (missing prerequisites):** Blocks deployment
- **Warnings (future prerequisites):** Allows deployment with warning

**Output when blocked:**

```
🚀 Deploy Check

Validating prerequisites for deployment...

✗ BLOCKED: Missing prerequisites detected

  Week 3 requires 'variance' but it's never introduced
  Week 4 requires 'covariance' but it's never introduced

Fix these issues before deploying:
  1. Add missing concepts to earlier weeks
  2. Or use --force to override (not recommended)

Run 'teach analyze --interactive' for guided fixes.
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

## Caching System (Phase 2)

The caching system accelerates analysis by storing results based on content hashes.

### How It Works

1. **Content Hashing**: SHA-256 hash of file contents
2. **Cache Storage**: Results stored in `.teach/analysis-cache/`
3. **Invalidation**: Automatic when file content changes
4. **TTL Expiry**: Configurable time-to-live (default: 24h)

### Cache Location

```
.teach/
├── concepts.json           # Current concept graph
└── analysis-cache/
    ├── cache-index.json    # Index of all cache entries
    ├── lectures/           # Lecture analysis cache
    ├── assignments/        # Assignment analysis cache
    └── exams/              # Exam analysis cache
```

### Cache Index Structure

```json
{
  "version": "1.0",
  "created": "2026-01-22T10:00:00Z",
  "entries": {
    "lectures/week-01-lecture.qmd": {
      "content_hash": "abc123...",
      "cache_file": "lectures/week-01-lecture.json",
      "created": "2026-01-22T10:00:00Z",
      "expires": "2026-01-23T10:00:00Z",
      "hit_count": 5
    }
  }
}
```

### Cache Operations

```bash
# View cache statistics
teach analyze --stats

# Force cache rebuild
teach analyze --rebuild-cache

# Clear expired entries
teach cache clean --expired

# Clear all analysis cache
teach cache clear --analysis
```

### Performance Targets

| Metric | Target | Typical |
|--------|--------|---------|
| Cache Hit Rate | 85%+ | 87-92% |
| Cache Read | < 10ms | 2-5ms |
| Cache Write | < 50ms | 8-15ms |
| Hash Computation | < 20ms | 5-10ms |

### Cascade Invalidation

When a concept is modified, dependent concepts are automatically invalidated:

```
correlation (modified)
    └── simple-regression (invalidated)
        └── multiple-regression (invalidated)
```

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

### Cache not updating (Phase 2)

**Cause:** Stale cache or file system issues.

**Solution:**
```bash
# Force cache rebuild
teach analyze --rebuild-cache

# Or clear cache completely
teach cache clear --analysis

# Check cache stats
teach analyze --stats
```

### Report generation fails (Phase 2)

**Cause:** Missing concepts.json or invalid format.

**Solution:**
```bash
# Regenerate concept graph first
teach analyze

# Then generate report
teach analyze --report analysis.md

# Check if concepts.json exists
ls -la .teach/concepts.json
```

### Interactive mode not responding (Phase 2)

**Cause:** Terminal doesn't support interactive input.

**Solution:**
```bash
# Use non-interactive mode instead
teach analyze --verbose

# Or ensure you're in a proper terminal
echo $TERM  # Should show xterm-256color or similar
```

### Deploy blocked unexpectedly (Phase 2)

**Cause:** Missing prerequisites detected by `--check-prereqs`.

**Solution:**
```bash
# See what's blocking
teach validate --deep

# Fix the issues with interactive mode
teach analyze --interactive

# Or override (not recommended)
teach deploy --force
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

### Core Functions (Phase 0-1)

| Function | Purpose |
|----------|---------|
| `_extract_concepts_from_frontmatter` | Parse YAML frontmatter |
| `_parse_introduced_concepts` | Get `introduces:` array |
| `_parse_required_concepts` | Get `requires:` array |
| `_build_concept_graph` | Create full concept graph |
| `_check_prerequisites` | Validate prerequisites |
| `_find_missing_prerequisites` | Detect missing prereqs |
| `_find_future_prerequisites` | Detect future prereqs |

### Cache Functions (Phase 2)

| Function | Purpose |
|----------|---------|
| `_cache_init` | Initialize cache directory structure |
| `_cache_get_content_hash` | Compute SHA-256 hash of file |
| `_cache_check_valid` | Check if cache entry is valid |
| `_cache_read` | Read cached analysis result |
| `_cache_write` | Write analysis result to cache |
| `_cache_invalidate` | Invalidate single cache entry |
| `_cache_cascade_invalidate` | Invalidate entry and dependents |
| `_cache_clean_expired` | Remove expired entries |
| `_cache_get_stats` | Get cache statistics as JSON |
| `_cache_rebuild_index` | Rebuild cache index from files |

### Report Functions (Phase 2)

| Function | Purpose |
|----------|---------|
| `_report_generate` | Main report generation entry |
| `_report_format_markdown` | Format report as markdown |
| `_report_format_json` | Format report as JSON |
| `_report_summary_stats` | Generate summary statistics |
| `_report_violations_table` | Generate violations table |
| `_report_concept_graph_text` | Generate text graph representation |
| `_report_week_breakdown` | Generate week-by-week breakdown |
| `_report_recommendations` | Generate fix recommendations |
| `_report_save` | Save report to file |

### Interactive Functions (Phase 2)

| Function | Purpose |
|----------|---------|
| `_teach_analyze_interactive` | Main interactive mode entry |
| `_interactive_select_scope` | Prompt for analysis scope |
| `_interactive_select_mode` | Prompt for analysis mode |
| `_interactive_display_results` | Display analysis results |
| `_interactive_review_violations` | Step through violations |
| `_interactive_next_steps` | Show suggested next actions |

### Validation Functions (Phase 2)

| Function | Purpose |
|----------|---------|
| `_teach_validate_deep` | Layer 6 deep validation |
| `_check_prerequisites_for_deploy` | Check prereqs before deploy |

### AI Functions (Phase 3)

| Function | Purpose |
|----------|---------|
| `_ai_analyze_content` | Run AI analysis on lecture content |
| `_ai_format_results` | Format AI analysis for display |
| `_ai_track_cost` | Record AI usage cost |
| `_ai_get_cost_summary` | Get cumulative cost summary |

### Slide Optimizer Functions (Phase 4)

| Function | Purpose |
|----------|---------|
| `_slide_analyze_structure` | Parse lecture structure (sections, words, code) |
| `_slide_suggest_breaks` | Apply 4 heuristic rules for break detection |
| `_slide_identify_key_concepts` | Find concepts for callout boxes |
| `_slide_estimate_time` | Calculate presentation time estimate |
| `_slide_optimize` | Full optimization pipeline |
| `_slide_preview_breaks` | Formatted break preview display |
| `_slide_apply_breaks` | Apply suggestions to generate slides |
| `_slide_extract_sections` | Helper: extract sections from JSON |

### Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success (all prerequisites satisfied) |
| `1` | General error (missing file, bad args) |
| `2+` | Number of missing prerequisites |
| `10` | Cache error |
| `20` | Report generation error |

---

## AI-Powered Analysis (Phase 3)

The `--ai` flag enables Claude-powered pedagogical analysis that goes beyond heuristic checks.

### Usage

```bash
# AI analysis of a specific lecture
teach analyze --ai lectures/week-05-regression.qmd

# AI analysis with cost tracking
teach analyze --ai --costs lectures/week-05-regression.qmd

# View cumulative AI costs
teach analyze --costs
```

### What AI Analysis Provides

When enabled, the AI layer examines:

1. **Learning Objective Alignment** - Are content and stated objectives consistent?
2. **Difficulty Progression** - Does complexity build appropriately?
3. **Pedagogical Patterns** - Are definitions followed by examples?
4. **Cognitive Load** - Is too much introduced at once?

### Cost Tracking

AI analysis costs are tracked per-session and cumulatively:

```
AI Analysis Costs:
  This session: $0.03 (2 analyses)
  Total tracked: $0.42 (28 analyses)
  Avg per analysis: $0.015
```

### Requirements

- Claude CLI must be installed and authenticated
- Works with Claude Haiku for cost efficiency
- Falls back gracefully if Claude unavailable

---

## Slide Optimization (Phase 4)

The slide optimizer analyzes lecture content to suggest where to insert slide breaks for presentations.

### Quick Start

```bash
# Analyze a lecture for slide break opportunities
teach analyze --slide-breaks lectures/week-05-regression.qmd

# Detailed preview of all suggested breaks
teach analyze --preview-breaks lectures/week-05-regression.qmd
```

### How It Works

The optimizer uses 4 heuristic rules to detect where slides need breaks:

| Rule | Trigger | Priority |
|------|---------|----------|
| **Word Density** | Section has >300 words without breaks | High |
| **Code Chunks** | Section has 3+ code blocks | Medium |
| **Definition Boundary** | Definition followed by example | Medium |
| **Dense Text** | >150 words without any code | Low |

### Output

```
┌──────────────────────────────────────────────────────┐
│ SLIDE OPTIMIZATION                                    │
├──────────────────────────────────────────────────────┤
│ Suggested breaks: 3                                   │
│                                                       │
│ Section          Priority   Reason                    │
│ ─────────────────────────────────────────────────    │
│ Regression       high       Word density (312 words)  │
│ Diagnostics      medium     Multiple code chunks (4)  │
│ Assumptions      low        Dense text (180 words)    │
│                                                       │
│ Key concepts for callout boxes:                       │
│ • regression-coefficient (definition)                 │
│ • residuals (concept graph)                           │
│ • r-squared (emphasis)                                │
│                                                       │
│ Estimated time: 28 min                                │
├──────────────────────────────────────────────────────┤
│ Phase: 4 (slide-optimized)                            │
└──────────────────────────────────────────────────────┘
```

### Key Concept Detection

Three strategies identify concepts worth highlighting on slides:

1. **Concept Graph** - Concepts from the `.teach/concepts.json` that appear in this lecture
2. **Definition Patterns** - Lines with "Definition:", "**Definition**", etc.
3. **Emphasis Patterns** - Bold terms (`**term**`) in explanatory context

### Time Estimation

Presentation time is estimated from content:

- **Content words**: words ÷ 150 wpm × 2 min per unit
- **Code blocks**: 3 min each (demonstration time)
- **Examples**: 2 min each (discussion time)

### Integration with `teach slides`

The slide optimizer integrates with the slides dispatcher:

```bash
# Optimize an existing lecture's slides
teach slides --optimize lectures/week-05-regression.qmd

# Preview breaks before applying
teach slides --preview-breaks lectures/week-05-regression.qmd

# Apply suggestions and generate slides
teach slides --apply-suggestions lectures/week-05-regression.qmd

# Show key concepts for callout boxes
teach slides --key-concepts lectures/week-05-regression.qmd
```

### Caching

Slide optimization results are cached based on file content hash (SHA-256):

- **Cache location**: `.teach/slide-optimization-<filename>.json`
- **Invalidation**: Automatic when file content changes
- **Cache hit**: Displays `✓ (cached)` in output
- Second run of same file skips re-analysis

---

## Error Handling and Dependencies (Phase 5)

### Improved Error Messages

When no file is specified:

```
Error: File path required

Usage: teach analyze <file> [options]

Examples:
  teach analyze lectures/week-05-regression.qmd
  teach analyze --slide-breaks lectures/week-05.qmd
  teach analyze --interactive

Run 'teach analyze --help' for full documentation.
```

When a file is not found, alternatives are suggested:

```
Error: File not found: lectures/bad-name.qmd

Available .qmd files in lectures/:
  lectures/week-01-foundations.qmd
  lectures/week-02-building.qmd
  lectures/week-03-applications.qmd
```

### Extension Validation

Non-.qmd files trigger a warning:

```
Warning: Expected .qmd or .md file, got .txt
Analysis works best with Quarto (.qmd) files containing YAML frontmatter.
```

### Dependency Checks

Missing tools are detected with install instructions:

```
Warning: jq not installed - some features unavailable
  Install: brew install jq
Warning: yq not installed - prerequisite checking limited
  Install: brew install yq
```

---

## Complete Flag Reference

| Flag | Phase | Description |
|------|-------|-------------|
| `--mode MODE` | 0 | Strictness: strict, moderate, relaxed |
| `--summary`, `-s` | 0 | Compact summary only |
| `--quiet`, `-q` | 0 | Suppress progress indicators |
| `--interactive`, `-i` | 2 | ADHD-friendly guided mode |
| `--report [FILE]` | 2 | Generate analysis report |
| `--format FORMAT` | 2 | Report format: markdown, json |
| `--ai` | 3 | Enable AI-powered analysis |
| `--costs` | 3 | Show AI usage costs |
| `--slide-breaks` | 4 | Analyze slide structure |
| `--preview-breaks` | 4 | Detailed break preview (exits early) |
| `--help`, `-h` | - | Show help |

---

## Slides Integration Workflow

The `teach analyze` system integrates with `teach slides --optimize` for an end-to-end slide generation workflow.

### Quick Workflow

```bash
# 1. Analyze prerequisites
teach analyze lectures/week-05-regression.qmd

# 2. Check slide structure
teach analyze --slide-breaks lectures/week-05-regression.qmd

# 3. Preview where breaks are needed
teach analyze --preview-breaks lectures/week-05-regression.qmd

# 4. See key concepts for callout boxes
teach slides --optimize --key-concepts lectures/week-05-regression.qmd

# 5. Generate optimized slides with callouts
teach slides --optimize --apply-suggestions --key-concepts lectures/week-05-regression.qmd
```

### Auto-Analyze

When you run `teach slides --optimize`, the system automatically:
1. Checks for `.teach/concepts.json`
2. If missing, runs `teach analyze --quiet` in the background
3. Uses the concept graph for optimization
4. Caches results for subsequent runs

This means you can skip step 1 if you just want slides.

### Key Concepts for Callout Boxes

The `--key-concepts` flag identifies important terms for slide callout boxes using three strategies:

| Strategy | Source | Example |
|----------|--------|---------|
| Concept graph | `.teach/concepts.json` | Concepts this lecture introduces |
| Definitions | `**Definition**:` patterns | Formal term definitions |
| Emphasis | `**bold terms**` in text | Important highlighted terms |

### Caching

Slide optimization results are cached by content hash:
- **Location:** `.teach/slide-optimization-<basename>.json`
- **Invalidation:** Automatic when file content changes (SHA-256)
- **Effect:** Instant results on unchanged files

---

## Related Documentation

- [Architecture Documentation](../reference/TEACH-ANALYZE-ARCHITECTURE.md)
- [API Reference](../reference/TEACH-ANALYZE-API-REFERENCE.md)
- [Quick Reference Card](../reference/REFCARD-TEACH-ANALYZE.md)
- [Teaching Workflow Guide](TEACHING-WORKFLOW-V3-GUIDE.md)
- [Teach Dispatcher Reference](../reference/TEACH-DISPATCHER-REFERENCE-v4.6.0.md)

---

**Getting Started:**
1. Add `concepts:` to your lecture frontmatter
2. Run `teach analyze lectures/week-01.qmd` to build concept graph
3. Fix any prerequisite issues
4. Check `teach status` for summary

**Advanced Usage:**
5. Use `teach analyze --interactive` for guided analysis (Phase 2)
6. Generate reports with `teach analyze --report analysis.md` (Phase 2)
7. Run `teach analyze --ai` for pedagogical insights (Phase 3)
8. Run `teach analyze --slide-breaks` before making slides (Phase 4)
9. Use `teach slides --optimize --key-concepts` for slide callout concepts
10. Use `teach slides --optimize --apply-suggestions` for optimized slide generation
