# Teach Analyze - Quick Reference Card

**Version:** flow-cli v5.16.0+
**Phases:** 0-5 (Concepts → AI → Slides → Polish)

---

## At a Glance

```bash
teach analyze <file>                          # Basic concept analysis
teach analyze --ai <file>                     # + AI pedagogical insights
teach analyze --slide-breaks <file>           # + Slide optimization
teach analyze --preview-breaks <file>         # Detailed break preview
teach analyze --interactive <file>            # Guided ADHD-friendly mode
teach analyze --report analysis.md <file>     # Generate report
```

---

## Phases

| Phase | Flag | What It Does |
|-------|------|--------------|
| 0 | *(always)* | Concept extraction, prerequisite validation |
| 2 | `--report`, `--interactive` | Reports, interactive mode |
| 3 | `--ai` | Claude-powered pedagogical analysis |
| 4 | `--slide-breaks` | Slide break detection, key concepts, timing |
| 5 | *(always)* | Error handling, file suggestions, caching |

---

## All Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--mode MODE` | | Strictness: strict, moderate, relaxed |
| `--summary` | `-s` | Compact output |
| `--quiet` | `-q` | Suppress progress |
| `--interactive` | `-i` | Guided step-by-step mode |
| `--report [FILE]` | | Generate report file |
| `--format FORMAT` | | Report format: markdown, json |
| `--ai` | | AI-powered analysis |
| `--costs` | | Show AI usage costs |
| `--slide-breaks` | | Analyze slide structure |
| `--preview-breaks` | | Detailed break preview (exits early) |
| `--help` | `-h` | Show help |

---

## Common Workflows

### Before Making Slides

```bash
# 1. Check prerequisites are in order
teach analyze lectures/week-05-regression.qmd

# 2. See where slides need breaks
teach analyze --slide-breaks lectures/week-05-regression.qmd

# 3. Get detailed preview
teach analyze --preview-breaks lectures/week-05-regression.qmd

# 4. Generate slides with optimization
teach slides --optimize lectures/week-05-regression.qmd
```

### Course Structure Audit

```bash
# Analyze each week and generate a report
teach analyze lectures/week-01.qmd --report week1.md
teach analyze lectures/week-02.qmd --report week2.md
teach analyze lectures/week-03.qmd --report week3.md

# Or use AI for deeper insights
teach analyze --ai lectures/week-05.qmd
```

### Pre-Deployment Check

```bash
# Validate prerequisites before deploying
teach analyze lectures/week-05.qmd --mode strict
teach deploy --check-prereqs
```

---

## Frontmatter Setup

Add to each lecture `.qmd` file:

```yaml
---
title: "Week 3: Regression"
week: 3
concepts:
  introduces:
    - simple-regression
    - residuals
    - r-squared
  requires:
    - correlation
    - variance
---
```

**Naming:** lowercase, hyphenated (`chi-squared`, not `Chi Squared`)

---

## Output Sections

### Phase 0 Output

```
╔══════════════════════════════════════════╗
│ CONCEPT COVERAGE                         │
├──────────────────────────────────────────┤
│ Introduces: regression, residuals        │
│ Requires:   correlation, variance        │
├──────────────────────────────────────────┤
│ 🔗 PREREQUISITES                         │
│                                          │
│ For concepts introduced in Week 3:       │
│                                          │
│ Linear Regression                        │
│   ✓ Correlation (Week 2)                 │
│     ↳ Descriptive Statistics (Week 1)    │
│       (via Correlation)                  │
│   ✓ Statistical Inference (Week 2)       │
│                                          │
│ Residuals                                │
│   ✓ Linear Regression (Week 3)           │
│   ✓ Variance (Week 1)                    │
│                                          │
├──────────────────────────────────────────┤
│ SUMMARY                                  │
│ Phase: 0 (concept-validated)             │
╚══════════════════════════════════════════╝
```

### Prerequisite Display Format

The prerequisites section shows a **dependency tree** for each concept introduced in the analyzed file:

```
🔗 PREREQUISITES

For concepts introduced in Week 3:

Linear Regression
  ✓ Correlation (Week 2)
    ↳ Descriptive Statistics (Week 1)
      (via Correlation)
  ✓ Statistical Inference (Week 2)
```

**Features:**

- **Per-concept breakdown**: Each introduced concept listed separately
- **Direct prerequisites**: First-level indentation (2 spaces)
- **Transitive prerequisites**: Second-level indentation (4 spaces) with `↳` arrow
- **Attribution**: Shows `(via X)` to indicate which prerequisite brings in transitive dependencies
- **Status indicators**:
  - `✓` Green: Covered in earlier week
  - `⚠` Yellow: Covered in same week (reordering suggested)
  - `✗` Red: Not found or future week (error)

**Example Interpretation:**

In the example above:
- `Linear Regression` requires `Correlation` (Week 2) ← direct
- `Correlation` itself requires `Descriptive Statistics` (Week 1) ← transitive
- The `(via Correlation)` shows that `Descriptive Statistics` is a transitive dependency through `Correlation`

### Phase 4 Output (--slide-breaks)

```
┌──────────────────────────────────────────┐
│ SLIDE OPTIMIZATION                        │
├──────────────────────────────────────────┤
│ Suggested breaks: 3                       │
│                                           │
│ Section       Priority  Reason            │
│ Regression    high      312 words         │
│ Diagnostics   medium    4 code chunks     │
│ Assumptions   low       Dense text        │
│                                           │
│ Key concepts: regression-coefficient,     │
│   residuals, r-squared                    │
│                                           │
│ Estimated time: 28 min                    │
│ Phase: 4 (slide-optimized)                │
└──────────────────────────────────────────┘
```

---

## Slide Break Rules

| # | Condition | Priority | What It Means |
|---|-----------|----------|---------------|
| 1 | >300 words in section | **high** | Too much text for one slide |
| 2 | 3+ code blocks | **medium** | Split into demo steps |
| 3 | Definition + example | **medium** | Natural conceptual boundary |
| 4 | >150 words, no code | **low** | Consider adding visuals |

---

## Key Concept Detection

Three strategies find concepts for slide callout boxes:

| Strategy | How | Example |
|----------|-----|---------|
| Concept graph | From `.teach/concepts.json` | Concepts this lecture introduces |
| Definitions | `**Definition**:` patterns | Formal term definitions |
| Emphasis | `**bold terms**` in text | Important highlighted terms |

---

## Caching

Slide optimization results are cached by content hash:

```
.teach/
└── slide-optimization-week-05-regression.json
```

- **Cache hit**: File unchanged → instant results
- **Cache miss**: File modified → re-analyzes
- **Hash**: SHA-256 of file contents

---

## Dependencies

| Tool | Required For | Install |
|------|-------------|---------|
| `jq` | JSON processing, slide optimizer | `brew install jq` |
| `yq` | YAML frontmatter parsing | `brew install yq` |
| `claude` | AI analysis (`--ai`) | Claude CLI |

Check with: `teach doctor`

---

## Error Messages

| Error | Cause | Fix |
|-------|-------|-----|
| "File path required" | No argument given | Provide a `.qmd` file path |
| "File not found" | Wrong path | Check suggestions shown |
| "Expected .qmd" | Wrong extension | Use `.qmd` or `.md` files |
| "jq not installed" | Missing dependency | `brew install jq` |

---

## Dispatcher Aliases

```bash
teach analyze ...     # Full name
teach concept ...     # Alias
teach concepts ...    # Alias
```

---

## Related

- Full guide: `docs/guides/INTELLIGENT-CONTENT-ANALYSIS.md`
- API reference: `docs/reference/TEACH-ANALYZE-API-REFERENCE.md`
- Dispatcher: `docs/reference/TEACH-DISPATCHER-REFERENCE-v4.6.0.md`
