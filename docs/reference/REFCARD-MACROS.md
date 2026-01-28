# LaTeX Macros Quick Reference Card

> Quick reference for `teach macros` command (v5.21.0+)

## Commands

| Command | Description |
|---------|-------------|
| `teach macros` | Show all macros with examples |
| `teach macros list` | List macros with filtering options |
| `teach macros sync` | Extract macros from source files |
| `teach macros export` | Export for Scholar or other tools |
| `teach macros validate` | Check for undefined/unused macros |
| `teach macros help` | Show usage help |

## Quick Examples

```bash
# List all macros
teach macros

# List only operator macros
teach macros list --category operators

# Sync from source files
teach macros sync

# Export for Scholar integration
teach macros export --format json

# Export as MathJax config
teach macros export --format mathjax > mathjax-config.js

# Validate macro usage
teach macros validate
```

## Configuration

Add to `teach-config.yml`:

```yaml
teaching_style:
  latex_macros:
    enabled: true
    sources:
      - path: "_macros.qmd"
        format: "qmd"
    auto_discover: true
    validation:
      warn_undefined: true
      warn_unused: true
      warn_conflicts: true
    scholar:
      export_format: "json"
      include_in_prompts: true
```

## Source File Formats

| Format | File Extension | Extraction Pattern |
|--------|----------------|-------------------|
| QMD (Quarto) | `.qmd` | `{=tex}` blocks with `\newcommand` |
| LaTeX | `.tex` | Standard `\newcommand`, `\DeclareMathOperator` |
| MathJax | `.html` | `MathJax.Hub.Config` Macros section |

### QMD Example (`_macros.qmd`)

```markdown
```{=tex}
\newcommand{\E}{\mathbb{E}}
\newcommand{\Var}{\operatorname{Var}}
\DeclareMathOperator{\Cov}{Cov}
```
```

### LaTeX Example (`macros.tex`)

```latex
\newcommand{\E}{\mathbb{E}}
\newcommand{\Var}{\operatorname{Var}}
\DeclareMathOperator{\Cov}{Cov}
```

## Common Macro Categories

| Category | Examples | Description |
|----------|----------|-------------|
| Operators | `\E`, `\Var`, `\Cov`, `\Corr` | Expectation, variance, covariance |
| Distributions | `\Normal`, `\Binomial`, `\Poisson` | Distribution notation |
| Symbols | `\indep`, `\iid` | Independence, identical distribution |
| Matrices | `\bX`, `\bbeta`, `\bSigma` | Bold matrix/vector notation |
| Estimators | `\bhat`, `\btilde` | Estimator notation |

## Export Formats

| Format | Flag | Use Case |
|--------|------|----------|
| JSON | `--format json` | Programmatic use, Scholar |
| MathJax | `--format mathjax` | Web inclusion |
| LaTeX | `--format latex` | .tex files |
| QMD | `--format qmd` | Quarto documents |

### Export Examples

```bash
# JSON for Scholar integration
teach macros export --format json > .flow/macros.json

# MathJax for web
teach macros export --format mathjax > _includes/mathjax-macros.js

# LaTeX preamble
teach macros export --format latex > _macros.tex
```

## teach doctor Integration

The `teach doctor` command includes a MACROS section:

```
MACROS
  Macro file          ✓ _macros.qmd found
  Macro count         ✓ 24 macros defined
  Validation          ✓ No undefined references
  Scholar export      ✓ .flow/macros.json up to date
```

## Validation Warnings

| Warning | Meaning | Fix |
|---------|---------|-----|
| Undefined macro | Macro used but not defined | Add definition to source |
| Unused macro | Macro defined but never used | Remove or document |
| Conflicting definitions | Same macro in multiple files | Consolidate sources |

## Flags Reference

| Flag | Commands | Description |
|------|----------|-------------|
| `--category CAT` | list | Filter by category |
| `--format FMT` | export | Output format (json, mathjax, latex, qmd) |
| `--output FILE` | export | Write to file instead of stdout |
| `--dry-run, -n` | sync | Preview without changes |
| `--force, -f` | sync | Overwrite existing cache |
| `--quiet, -q` | validate | Suppress warnings |
| `--json` | list, validate | Output as JSON |

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Macros not found | Wrong source path | Check `sources:` in config |
| Export empty | No `{=tex}` blocks | Use proper QMD format |
| Scholar not using macros | Export not run | Run `teach macros export` |
| Validation errors | Typos in macro names | Check spelling, run sync |

## See Also

- `teach init` - Initialize course with macro support
- `teach validate` - Validate .qmd files
- `teach doctor` - Health check including macros
- `teach analyze` - Content analysis with macro awareness
