---
tags:
  - tutorial
  - dispatchers
  - r
  - package-development
---

# Tutorial: R Package Development with r

Develop R packages faster with single-letter shortcuts for every stage of the development cycle — from loading to CRAN submission.

**Time:** 15 minutes | **Level:** Intermediate | **Requires:** R, devtools, flow-cli

## What You'll Learn

1. Opening an R console via the dispatcher
2. Core development workflow (load, test, document, check, build, install)
3. Combined workflows for fast iteration
4. Quality checks and code coverage
5. Building documentation with pkgdown
6. CRAN submission preparation
7. Version bumping
8. Cleanup utilities

---

## Step 1: Open the R Console

Run `r` with no arguments to open an interactive R session:

```zsh
r
```

flow-cli automatically uses **radian** if it is installed (a modern R console with syntax highlighting and multi-line editing). If radian is not found, it falls back to `R --quiet`.

**Tip:** Install radian for a significantly improved experience: `pip install radian`

---

## Step 2: Core Development Workflow

Every step of the R package workflow has a dedicated subcommand:

| Command | Shortcut | devtools equivalent | Purpose |
|---------|----------|---------------------|---------|
| `r load` | `r l` | `devtools::load_all()` | Load package into memory |
| `r test` | `r t` | `devtools::test()` | Run all tests |
| `r doc` | `r d` | `devtools::document()` | Generate documentation |
| `r check` | `r c` | `devtools::check()` | Run R CMD check |
| `r build` | `r b` | `devtools::build()` | Build source tarball |
| `r install` | `r i` | `devtools::install()` | Install package locally |

```zsh
r load      # Load the package
r test      # Run the test suite
r doc       # Regenerate man/ pages from roxygen2
r check     # Full R CMD check
```

---

## Step 3: Combined Workflows for Fast Iteration

Two combined commands cover the most common multi-step patterns:

**`r cycle` — document, test, check in sequence:**

```zsh
r cycle
```

Runs `devtools::document()` -> `devtools::test()` -> `devtools::check()` in one shot. Use before committing.

**`r quick` — load and test for rapid iteration:**

```zsh
r quick     # or: r q
```

Runs `devtools::load_all()` -> `devtools::test()`. The inner-loop command during active development.

**80% of daily R package work fits into two commands: `r quick` while building, `r cycle` before committing.**

---

## Step 4: Quality Checks

**Test coverage:**

```zsh
r cov
```

Runs `covr::package_coverage()` and prints a coverage report.

**Spell checking:**

```zsh
r spell
```

Runs `spelling::spell_check_package()` to catch typos in documentation. CRAN reviewers check for spelling errors.

Both `covr` and `spelling` must be installed:

```r
install.packages(c("covr", "spelling"))
```

---

## Step 5: Building Documentation

If your package uses **pkgdown** for its documentation website:

```zsh
r pkgdown     # or: r pd — build the full site
r preview     # or: r pv — preview in browser
```

---

## Step 6: CRAN Submission Prep

Three commands target different aspects of CRAN compliance:

```zsh
r cran     # Full --as-cran check (strictest)
r fast     # Quick structural check (skip examples, tests, vignettes)
r win      # Submit to win-builder for Windows compatibility
```

**Typical CRAN prep sequence:**

```zsh
r spell       # Fix documentation typos
r cov         # Review test coverage
r cran        # Full --as-cran check
r win         # Submit to win-builder
```

---

## Step 7: Version Bumps

Bump the package version in `DESCRIPTION` using usethis:

```zsh
r patch    # 0.1.0 → 0.1.1   (bug fixes)
r minor    # 0.1.0 → 0.2.0   (new features)
r major    # 0.1.0 → 1.0.0   (breaking changes)
```

---

## Step 8: Cleanup Utilities

```zsh
r clean     # Remove .Rhistory and .RData
r deep      # Remove man/, NAMESPACE, docs/ (with confirmation)
r tex       # Remove LaTeX build artifacts (.aux, .log, .out, etc.)
r commit "Fix validation"  # Document, test, then git commit
```

**Bonus:** `r info` shows package metadata, `r tree` shows directory structure.

---

## FAQ

### What happened to the ZSH builtin `r` command?

The ZSH builtin `r` is an alias for `fc -e -` (repeat last command). flow-cli disables it with `disable r` so this dispatcher works. Use `!!` to repeat the last command instead.

### Does the dispatcher work outside of an R package directory?

`r` (no args, opens the console) works anywhere. Subcommands that call devtools require a valid R package in the current directory (a `DESCRIPTION` file). Use `r info` to verify.

### radian vs. plain R?

The dispatcher auto-detects radian in your PATH. If found, `r` uses it. If not, standard R in quiet mode. No configuration needed.

### What if devtools is not installed?

Install the full toolkit:

```r
install.packages(c("devtools", "usethis", "covr", "spelling", "pkgdown"))
```

---

## Next Steps

- **[MASTER-DISPATCHER-GUIDE](../reference/MASTER-DISPATCHER-GUIDE.md)** — Complete reference for all 15 dispatchers
- **[R Packages book](https://r-pkgs.org/)** — The definitive R package development reference
- **[devtools documentation](https://devtools.r-lib.org/)** — Full API reference
