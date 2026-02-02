# Content Analysis Quick Reference Card

> Quick reference for `teach analyze` command (v6.1.0+)

## Commands

| Command | Description |
|---------|-------------|
| `teach analyze <file>` | Analyze single file for concepts and prerequisites |
| `teach analyze --interactive` | ADHD-friendly guided analysis workflow |
| `teach analyze --report` | Generate markdown report |
| `teach analyze --ai` | AI-powered concept extraction |
| `teach analyze --slide-breaks` | Analyze optimal slide structure |
| `teach analyze --preview-breaks` | Show slide break suggestions |

## Quick Examples

```bash
# Basic analysis
teach analyze lectures/week-05-regression.qmd

# Interactive mode (ADHD-friendly)
teach analyze --interactive
teach analyze -i lectures/week-05.qmd

# With strictness mode
teach analyze lectures/week-05.qmd --mode strict

# Generate markdown report
teach analyze lectures/week-05.qmd --report

# Generate JSON report with custom filename
teach analyze lectures/week-05.qmd --report analysis.json --format json

# Quick summary only
teach analyze lectures/week-05.qmd --summary

# Silent analysis with report
teach analyze lectures/week-05.qmd --quiet --report

# AI-powered analysis (Phase 3)
teach analyze --ai lectures/week-05.qmd
teach analyze --ai --costs lectures/week-05.qmd

# Show AI cost summary only
teach analyze --costs

# Slide optimization (Phase 4)
teach analyze --slide-breaks lectures/week-05.qmd
teach analyze --preview-breaks lectures/week-05.qmd
```

## Options

| Flag | Short | Description |
|------|-------|-------------|
| `--mode` | - | Analysis strictness (strict/moderate/relaxed) |
| `--summary` | `-s` | Show compact summary only |
| `--quiet` | `-q` | Suppress progress indicators |
| `--interactive` | `-i` | Step-through ADHD-friendly mode |
| `--report [FILE]` | - | Generate analysis report (optional filename) |
| `--format` | - | Report format (markdown/json) |
| `--ai` | - | Enable AI-powered analysis |
| `--costs` | - | Show AI analysis cost summary |
| `--slide-breaks` | - | Analyze for optimal slide structure |
| `--preview-breaks` | - | Show suggested slide breaks (then exit) |
| `--help` | `-h` | Show help |

## Analysis Phases

| Phase | Description | Enabled By | Speed |
|-------|-------------|------------|-------|
| Phase 0 | Heuristic concept extraction | Default | Fast |
| Phase 2 | Report generation | `--report` | Medium |
| Phase 3 | AI-powered concept extraction | `--ai` | Slow |
| Phase 4 | Slide structure optimization | `--slide-breaks` | Medium |

## Strictness Modes

| Mode | Description | Use For |
|------|-------------|---------|
| `relaxed` | Warnings only | Draft content, exploration |
| `moderate` | Default balance | General use, development |
| `strict` | All issues reported | Pre-deployment, quality checks |

## Interactive Mode Workflow

1. **Select Scope**: File, week, or entire course
2. **Choose Mode**: Relaxed, moderate, or strict
3. **Watch Progress**: Real-time concept graph building
4. **Review Issues**: One-by-one with fix suggestions
5. **Get Next Steps**: Clear actionable recommendations

## Report Sections

Generated reports include:

- **Summary**: Concept count, week count, violations, coverage %
- **Prerequisite Violations**: Table of issues with suggestions
- **Concept Map**: Text-based dependency visualization by week
- **Week Breakdown**: Per-week concept counts and lectures
- **Recommendations**: Actionable suggestions to fix issues

## Output Locations

| Item | Location |
|------|----------|
| Concept graph | `.teach/concepts.json` |
| Reports | `.teach/reports/analysis-TIMESTAMP.{md,json}` |
| Slide cache | `.teach/analysis-cache/SUBDIR/FILE-slides.json` |
| AI costs | `.teach/ai-costs.json` |

## Frontmatter Format

Add to your .qmd files:

```yaml
---
title: 'Linear Regression'
week: 5
concepts:
  introduces:
    - regression-basics
    - residual-analysis
  requires:
    - correlation
    - variance
---
```

## Integration

| Tool | How It Uses Analysis |
|------|----------------------|
| `teach validate` | Checks syntax and render validity |
| `teach status` | Shows project overview |
| `teach deploy` | Pre-deployment validation |
| Scholar plugin | Loads concept graph for context |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success (no violations) |
| 1 | Error or violations found |

## Dependencies

| Tool | Purpose | Install |
|------|---------|---------|
| `jq` | JSON processing | `brew install jq` |
| `yq` | YAML processing | `brew install yq` |
| `claude` | AI analysis (optional) | `https://code.claude.com` |

## Performance

| Operation | Typical Time |
|-----------|--------------|
| Basic analysis | 1-2 seconds |
| With report | 2-3 seconds |
| AI analysis | 5-10 seconds |
| Slide optimization | 2-4 seconds |
| Full course scan | 10-30 seconds |

## STAT-101 Demo Example

```bash
# Navigate to demo course
cd tests/fixtures/demo-course

# Analyze single lecture
teach analyze lectures/week-02-probability.qmd

# Interactive analysis of entire course
teach analyze --interactive

# Generate comprehensive report
teach analyze lectures/week-02-probability.qmd --report --ai

# Check slide structure
teach analyze --slide-breaks lectures/week-02-probability.qmd
```

## See Also

- [Dispatcher Guide: teach analyze](MASTER-DISPATCHER-GUIDE.md) — Full command reference
- [Tutorial 21: Content Analysis](../tutorials/21-teach-analyze.md) — Analysis workflow
- [API Reference](MASTER-API-REFERENCE.md) — Function signatures

---

**Version:** v6.1.0
**Last Updated:** 2026-02-02
