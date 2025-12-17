# Project Structure Standards

> **TL;DR:** Consistent directories across all projects. Know where to find things instantly.

## Universal Files (All Projects)

Every project MUST have:

```
project/
├── README.md          # Quick start (use QUICK-START-TEMPLATE)
├── .STATUS            # Machine-readable status
├── .gitignore         # Git ignores
└── CHANGELOG.md       # Version history (for packages/releases)
```

## .STATUS File Format

```yaml
status: active          # active | draft | stable | paused | archived
progress: 75            # 0-100 (optional)
next: Write discussion  # Next action item
target: JASA            # Target journal/milestone (optional)
updated: 2025-12-17     # Last update date
```

**Valid statuses:**
| Status | Meaning |
|--------|---------|
| `active` | Currently working on |
| `draft` | In development, not ready |
| `stable` | Production ready |
| `paused` | Temporarily stopped |
| `archived` | No longer maintained |
| `under-review` | Submitted, waiting feedback |
| `published` | Completed and released |

---

## R Package Structure

```
mypackage/
├── README.md              # Quick start
├── .STATUS                # Package status
├── DESCRIPTION            # Package metadata
├── NAMESPACE              # Exports (auto-generated)
├── LICENSE                # License file
├── NEWS.md                # Changelog
├── .Rbuildignore          # Build ignores
├── .gitignore
│
├── R/                     # Source code
│   ├── mypackage-package.R   # Package-level docs
│   ├── main_function.R       # One major function per file
│   └── utils.R               # Internal helpers
│
├── man/                   # Documentation (auto-generated)
│
├── tests/
│   ├── testthat.R         # Test runner
│   └── testthat/
│       ├── test-main.R
│       └── helper-utils.R
│
├── vignettes/             # Long-form docs
│   └── introduction.Rmd
│
├── inst/                  # Installed files
│   └── extdata/           # Example data
│
├── data/                  # Package data (.rda)
├── data-raw/              # Scripts to create data
│
└── .github/
    └── workflows/
        └── R-CMD-check.yaml
```

---

## Research Project Structure

```
my-research/
├── README.md              # Quick start
├── .STATUS                # Project status
├── .gitignore
│
├── manuscript/            # Paper files
│   ├── manuscript.qmd     # Main document
│   ├── references.bib     # Bibliography
│   ├── figures/           # Figure outputs
│   └── tables/            # Table outputs
│
├── R/                     # Analysis code
│   ├── 00-setup.R         # Load packages, set options
│   ├── 01-data-prep.R     # Data cleaning
│   ├── 02-analysis.R      # Main analysis
│   ├── 03-simulations.R   # Simulation study
│   └── utils.R            # Helper functions
│
├── data/
│   ├── raw/               # Original data (never modify)
│   └── processed/         # Cleaned data
│
├── output/                # Analysis outputs
│   ├── figures/
│   ├── tables/
│   └── results/
│
└── docs/                  # Notes, drafts, reviews
    ├── notes.md
    └── reviews/
```

---

## Teaching Course Structure

```
STAT-440/
├── README.md              # Course quick start
├── .STATUS                # Current week, next task
├── .gitignore
│
├── syllabus/
│   └── syllabus.qmd
│
├── lectures/
│   ├── week-01/
│   │   ├── slides.qmd
│   │   ├── notes.md
│   │   └── code/
│   ├── week-02/
│   └── ...
│
├── assignments/
│   ├── hw01/
│   │   ├── hw01.qmd
│   │   └── hw01-solutions.qmd
│   └── ...
│
├── exams/
│   ├── midterm/
│   └── final/
│
├── data/                  # Course datasets
│
└── resources/             # Supplementary materials
```

---

## Quarto Manuscript Structure

```
my-manuscript/
├── README.md
├── .STATUS
├── _quarto.yml            # Quarto config
│
├── manuscript.qmd         # Main document
├── references.bib         # Bibliography
├── template.tex           # LaTeX template (optional)
│
├── sections/              # For long documents
│   ├── 01-introduction.qmd
│   ├── 02-methods.qmd
│   ├── 03-results.qmd
│   └── 04-discussion.qmd
│
├── figures/
├── tables/
│
└── supplementary/
    └── appendix.qmd
```

---

## Node.js/Dev Tool Structure

```
my-tool/
├── README.md
├── .STATUS
├── package.json
├── .gitignore
│
├── src/                   # Source code
│   ├── index.js           # Entry point
│   ├── cli.js             # CLI interface
│   └── lib/               # Library code
│
├── tests/
│   └── *.test.js
│
├── docs/
│
└── .github/
    └── workflows/
```

---

## Quick Reference

| Project Type | Main Code | Tests | Docs | Config |
|--------------|-----------|-------|------|--------|
| R Package | `R/` | `tests/testthat/` | `man/`, `vignettes/` | `DESCRIPTION` |
| Research | `R/` | — | `manuscript/` | `.STATUS` |
| Teaching | `lectures/` | — | `syllabus/` | `.STATUS` |
| Quarto | `*.qmd` | — | — | `_quarto.yml` |
| Node.js | `src/` | `tests/` | `docs/` | `package.json` |
| ZSH | `functions/` | `tests/` | `help/` | `.zshrc` |

---

## Commands to Scaffold

```bash
# Create new project from template
proj new r-package mypackage
proj new research "My Study"
proj new teaching STAT-500

# Validate structure
proj check              # Checks against standards
```
