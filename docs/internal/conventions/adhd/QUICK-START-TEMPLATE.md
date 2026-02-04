# Quick Start Template

> **Use this template** for every project's README or QUICK-START.md

---

## Template

```markdown
# [Project Name]

> **TL;DR:** [One sentence: what this does]

## 30-Second Setup

\`\`\`bash
# Clone and run
git clone [url]
cd [project]
[one command to get running]
\`\`\`

## What This Does

- [Bullet 1: Main feature]
- [Bullet 2: Secondary feature]
- [Bullet 3: Who it's for]

## Common Tasks

| I want to... | Run this |
|--------------|----------|
| Build | `pb` |
| Test | `pt` |
| Document | `pd` |
| Check/Lint | `pc` |
| Deploy | `[command]` |

## Where Things Are

| Location | Contents |
|----------|----------|
| `R/` or `src/` | Main code |
| `tests/` | Test files |
| `docs/` | Documentation |
| `data/` | Data files |

## Current Status

See `.STATUS` file or run:
\`\`\`bash
proj status
\`\`\`

## Need Help?

- **Stuck?** Check `docs/troubleshooting.md`
- **Context lost?** Run `proj context` to see where you left off
- **Standards?** See `~/projects/dev-tools/zsh-configuration/standards/`
```

---

## Example: R Package

```markdown
# rmediation

> **TL;DR:** R package for causal mediation analysis with sensitivity analysis.

## 30-Second Setup

\`\`\`bash
git clone https://github.com/Data-Wise/rmediation
cd rmediation
R -e "devtools::load_all(); devtools::test()"
\`\`\`

## What This Does

- Estimates natural direct and indirect effects
- Provides sensitivity analysis for unmeasured confounding
- Supports continuous and binary mediators/outcomes

## Common Tasks

| I want to... | Run this |
|--------------|----------|
| Load package | `devtools::load_all()` or `rload` |
| Run tests | `devtools::test()` or `pt` |
| Build docs | `devtools::document()` or `pd` |
| Full check | `devtools::check()` or `pc` |

## Where Things Are

| Location | Contents |
|----------|----------|
| `R/` | Package functions |
| `tests/testthat/` | Unit tests |
| `man/` | Documentation (auto-generated) |
| `vignettes/` | Long-form tutorials |

## Current Status

\`\`\`
status: stable
version: 1.2.0
next: Add bootstrap CI option
\`\`\`
```

---

## Example: Research Project

```markdown
# Product of Three Mediators

> **TL;DR:** JASA manuscript on sequential mediation with three mediators.

## 30-Second Setup

\`\`\`bash
cd ~/projects/research/product-of-three
quarto preview manuscript.qmd
\`\`\`

## What This Does

- Develops identification theory for three sequential mediators
- Provides sensitivity analysis framework
- Includes simulation study and real data application

## Common Tasks

| I want to... | Run this |
|--------------|----------|
| Preview manuscript | `quarto preview` or `pv` |
| Render PDF | `quarto render` or `pb` |
| Run simulations | `Rscript R/simulations.R` |
| Update references | `Rscript R/update-refs.R` |

## Where Things Are

| Location | Contents |
|----------|----------|
| `manuscript.qmd` | Main paper |
| `R/` | Analysis scripts |
| `data/` | Datasets |
| `figures/` | Generated figures |

## Current Status

\`\`\`
status: draft
progress: 75%
next: Write discussion section
target: JASA
\`\`\`
```

---

## ADHD Tips for This Template

1. **Fill it out immediately** when creating a project
2. **Keep it updated** — 30 seconds when things change
3. **Use `.STATUS` files** for machine-readable status
4. **Link to standards** for detailed conventions
