# R Dispatcher Reference

> **R package development workflows with devtools integration and full CRAN check support**

**Location:** `lib/dispatchers/r-dispatcher.zsh`

---

## Quick Start

```bash
r                     # Launch R console (radian if available)
r test                # Run tests
r cycle               # Full cycle: doc → test → check
r check               # R CMD check
```

---

## Usage

```bash
r [command] [args]
```

### Key Insight

- `r` with no arguments launches R console (radian preferred)
- All commands wrap devtools functions for consistency
- `r cycle` is the most common development workflow
- ADHD-friendly shortcuts for frequent operations

---

## Core Workflow Commands

| Command | Shortcut | Description |
|---------|----------|-------------|
| `r load` | `r l` | Load package (`devtools::load_all`) |
| `r test` | `r t` | Run tests (`devtools::test`) |
| `r doc` | `r d` | Generate documentation (`devtools::document`) |
| `r check` | `r c` | R CMD check (`devtools::check`) |
| `r build` | `r b` | Build package (`devtools::build`) |
| `r install` | `r i` | Install package (`devtools::install`) |

### Examples

```bash
r load                # Load package for testing
r test                # Run all tests
r doc                 # Regenerate documentation
r check               # Full R CMD check
```

---

## Combined Workflows

| Command | Description |
|---------|-------------|
| `r cycle` | Full cycle: doc → test → check |
| `r quick` | Quick iteration: load → test |

### Examples

```bash
# Full development cycle
r cycle

# Quick iteration loop
r quick
# or manually:
r load && r test
```

---

## Quality Commands

| Command | Description |
|---------|-------------|
| `r cov` | Coverage report (`covr::package_coverage`) |
| `r spell` | Spell check package (`spelling::spell_check_package`) |

### Examples

```bash
r cov                 # Generate coverage report
r spell               # Check spelling in docs
```

---

## Documentation Commands

| Command | Shortcut | Description |
|---------|----------|-------------|
| `r pkgdown` | `r pd` | Build pkgdown site |
| `r preview` | `r pv` | Preview pkgdown site |

### Examples

```bash
r pkgdown             # Build documentation site
r preview             # Preview in browser
```

---

## CRAN Checks

| Command | Description |
|---------|-------------|
| `r cran` | Check as CRAN (`--as-cran` flag) |
| `r fast` | Fast check (skip examples/tests/vignettes) |
| `r win` | Windows development check |

### Examples

```bash
# Before CRAN submission
r cran

# Quick syntax check
r fast

# Windows compatibility
r win
```

---

## Version Bumps

| Command | Description |
|---------|-------------|
| `r patch` | Bump patch version (0.0.X) |
| `r minor` | Bump minor version (0.X.0) |
| `r major` | Bump major version (X.0.0) |

### Examples

```bash
# Bug fix release
r patch               # 0.1.0 → 0.1.1

# New feature release
r minor               # 0.1.1 → 0.2.0

# Breaking change release
r major               # 0.2.0 → 1.0.0
```

---

## Cleanup Commands

| Command | Shortcut | Description |
|---------|----------|-------------|
| `r clean` | `r cl` | Remove .Rhistory and .RData |
| `r deep` | `r deepclean` | Deep clean (man/, NAMESPACE, docs/) |
| `r tex` | `r latex` | Remove LaTeX build files |
| `r commit` | `r save` | Document, test, and commit |

### Examples

```bash
# Quick cleanup
r clean

# Full cleanup (with confirmation)
r deep
# ⚠️  WARNING: This will remove man/, NAMESPACE, docs/
# Continue? (y/N)

# After LaTeX rendering
r tex

# Save work with auto-commit
r commit "Add new feature"
```

---

## Info Commands

| Command | Description |
|---------|-------------|
| `r info` | Package info summary (calls `rpkginfo`) |
| `r tree` | Package structure tree (calls `rpkgtree`) |

### Examples

```bash
r info                # Show package metadata
r tree                # Display file structure
```

---

## R Console

Running `r` with no arguments launches the R console:

```bash
r                     # Launch R console
```

**Behavior:**
- Uses radian if installed (better REPL experience)
- Falls back to standard R console
- Runs in quiet mode (`--quiet`)

---

## Examples

### Daily Development

```bash
# Start of day
cd ~/projects/r-packages/mypackage
r load                # Load package

# Make changes, then test
r test                # Run tests
r doc                 # Update docs

# Full check before commit
r cycle               # doc → test → check
```

### Pre-CRAN Submission

```bash
# Full check sequence
r cycle               # Full development cycle
r cran                # CRAN-style check
r win                 # Windows compatibility
r spell               # Spell check

# Bump version
r minor               # Update version
```

### Quick Iteration

```bash
# Fast feedback loop
r quick               # load → test
# or
r load && r test
```

### Documentation

```bash
# Update and preview docs
r doc                 # Generate Rd files
r pkgdown             # Build site
r preview             # View in browser
```

---

## Integration

### With G Dispatcher

Use git workflows with R development:

```bash
g feature start new-function
r load && r test
g aa && g commit "feat: add new function"
g promote             # PR to dev
```

### With CC Dispatcher

Launch Claude for R package work:

```bash
cc pick               # Pick R package project
# Claude with R package context
```

---

## Troubleshooting

### "devtools not installed"

Install required packages:

```r
install.packages(c("devtools", "usethis", "covr", "spelling", "pkgdown"))
```

### "radian not found"

Install radian for better REPL:

```bash
pip install radian
```

Or use standard R console (automatic fallback).

### "covr::package_coverage failed"

Ensure tests pass first:

```bash
r test                # Fix any failing tests
r cov                 # Then run coverage
```

---

## See Also

- **Dispatcher:** [g](G-DISPATCHER-REFERENCE.md) - Git workflows for R packages
- **Dispatcher:** [qu](QU-DISPATCHER-REFERENCE.md) - Quarto for R Markdown workflows
- **Dispatcher:** [cc](CC-DISPATCHER-REFERENCE.md) - Launch Claude for R help
- **Reference:** [Dispatcher Reference](DISPATCHER-REFERENCE.md) - All dispatchers
- **External:** [devtools Package](https://devtools.r-lib.org/) - Official devtools documentation

---

**Last Updated:** 2026-01-07
**Version:** v4.8.0
**Status:** ✅ Production ready with devtools integration
