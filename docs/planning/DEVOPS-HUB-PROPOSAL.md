# DevOps Hub: zsh-configuration as Central Command

## Vision

> **One place to rule them all.** `zsh-configuration` becomes the single source of truth for all project workflows, standards, and automation.

---

## Current State

```
~/projects/
├── dev-tools/           # 16 projects
│   ├── zsh-configuration/    ← HUB (this repo)
│   ├── zsh-claude-workflow/
│   ├── claude-statistical-research/
│   └── ...
├── r-packages/          # 6 R packages
│   ├── active/
│   ├── stable/
│   └── scratch/
├── research/            # 11 projects
├── teaching/            # 3 courses
└── quarto/              # Presentations & manuscripts
```

**Problem:** Each project has its own conventions, no unified standards, context-switching is expensive (ADHD tax).

---

## Proposed Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     zsh-configuration (THE HUB)                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Standards │  │  Templates  │  │  Workflows  │  │    Tools    │        │
│  │   & Docs    │  │  & Configs  │  │  & Scripts  │  │  & Helpers  │        │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘        │
│         │                │                │                │               │
│         └────────────────┴────────────────┴────────────────┘               │
│                                    │                                        │
│                                    ▼                                        │
│                          Symlinks / Sources                                 │
│                                    │                                        │
└────────────────────────────────────┼────────────────────────────────────────┘
                                     │
        ┌────────────────────────────┼────────────────────────────┐
        │                            │                            │
        ▼                            ▼                            ▼
┌───────────────┐          ┌───────────────┐          ┌───────────────┐
│  R Packages   │          │   Research    │          │   Teaching    │
│  (6 projects) │          │ (11 projects) │          │  (3 courses)  │
└───────────────┘          └───────────────┘          └───────────────┘
```

---

## Directory Structure

### Standards & Documentation

```
standards/
├── README.md                    # Standards index
├── code/
│   ├── R-STYLE-GUIDE.md         # R coding standards
│   ├── PYTHON-STYLE-GUIDE.md
│   ├── ZSH-STYLE-GUIDE.md
│   └── COMMIT-MESSAGES.md       # Git commit conventions
├── project/
│   ├── PROJECT-STRUCTURE.md     # Directory conventions
│   ├── README-TEMPLATE.md       # Standard README format
│   ├── CHANGELOG-FORMAT.md
│   └── VERSIONING.md            # Semantic versioning rules
├── workflow/
│   ├── GIT-WORKFLOW.md          # Branch naming, PR process
│   ├── RELEASE-PROCESS.md
│   └── REVIEW-CHECKLIST.md
└── adhd/
    ├── QUICK-START-TEMPLATE.md  # 30-second project onboarding
    ├── DECISION-TREES.md        # "What do I do when..." guides
    └── CONTEXT-RECOVERY.md      # "Where was I?" helpers
```

### Project Templates

```
templates/
├── r-package/
│   ├── DESCRIPTION.template
│   ├── .Rbuildignore
│   ├── .gitignore
│   ├── README.md.template
│   ├── _pkgdown.yml.template
│   └── .github/workflows/R-CMD-check.yaml
├── quarto-manuscript/
│   ├── _quarto.yml.template
│   ├── manuscript.qmd.template
│   └── references.bib
├── research-project/
│   ├── .STATUS.template
│   ├── README.md.template
│   └── analysis/
└── teaching-course/
    ├── syllabus.qmd.template
    └── week-template/
```

### R Ecosystem Management

```
r-ecosystem/
├── PACKAGE-REGISTRY.md          # All packages, status, dependencies
├── DEPENDENCY-GRAPH.md          # Inter-package dependencies
├── RELEASE-SCHEDULE.md          # Coordinated release planning
├── shared/
│   ├── R-CMD-check.yaml         # Shared GitHub Action
│   ├── pkgdown-theme/           # Consistent documentation style
│   └── test-helpers.R           # Shared test utilities
└── scripts/
    ├── check-all.sh             # Check all packages
    ├── update-deps.sh           # Update dependencies
    └── release-prep.sh          # Pre-release checklist
```

---

## Unified Command System

### Current (Inconsistent)
```bash
rload && rtest          # R packages
quarto render           # Quarto
npm test                # Node.js
pytest                  # Python
```

### Proposed (Unified)
```bash
pb                      # Project Build (auto-detects type)
pt                      # Project Test
pd                      # Project Deploy/Document
pc                      # Project Check/Lint
```

### Implementation

```zsh
# Universal project commands
pb() { _proj_dispatch build "$@" }
pt() { _proj_dispatch test "$@" }
pd() { _proj_dispatch docs "$@" }
pc() { _proj_dispatch check "$@" }

_proj_dispatch() {
    local action=$1; shift
    local ptype=$(proj-type)

    case "$ptype:$action" in
        r-package:build) R CMD build . ;;
        r-package:test)  Rscript -e "devtools::test()" ;;
        r-package:docs)  Rscript -e "devtools::document()" ;;
        r-package:check) R CMD check . ;;
        quarto:build)    quarto render ;;
        node:build)      npm run build ;;
        node:test)       npm test ;;
        python:test)     pytest ;;
        *) echo "Unknown: $ptype:$action" ;;
    esac
}
```

### Project Creation
```bash
proj new r-package mypackage     # Creates from template
proj new research "My Study"     # Creates research project
proj new teaching STAT-500       # Creates course structure
```

---

## ADHD-Friendly Principles

| Principle | Implementation |
|-----------|----------------|
| **One command** | Every task has a single command entry point |
| **Zero memory** | System remembers context, not you |
| **Visual feedback** | Progress bars, colors, emojis |
| **Decision minimization** | Smart defaults, ask only when necessary |
| **Interrupt recovery** | Save state automatically, restore seamlessly |
| **Time blindness** | Built-in timers, reminders, deadlines |
| **Dopamine hits** | Celebrate completions, show progress |

### Context Recovery System

```bash
# When leaving a project
$ finish "Implemented bootstrap CI"
# Saves: current file, cursor position, git status, next TODO

# When returning
$ work product-of-three
═══════════════════════════════════════════════════════════════════════════════
  📂 Resuming: product-of-three
═══════════════════════════════════════════════════════════════════════════════

  Last session: 2 days ago
  You were: editing R/bootstrap.R (line 142)
  Git status: 3 uncommitted files
  Last note: "Implemented bootstrap CI"

  Next TODO: Write unit tests for bootstrap function

  [Enter] Resume  [n] New task  [s] Show history
```

### Project Dashboard

```bash
$ dash

═══════════════════════════════════════════════════════════════════════════════
  📊 Project Dashboard                                            2025-12-17
═══════════════════════════════════════════════════════════════════════════════

  R PACKAGES
  ──────────────────────────────────────────────────────────────────────────────
  ✓ rmediation      stable    v1.2.0   Last: 3 days ago
  ⚠ mediationsens   active    v0.3.1   Last: 2 weeks ago   ← needs attention
  ● pof3            draft     v0.1.0   Last: today

  RESEARCH
  ──────────────────────────────────────────────────────────────────────────────
  📝 product-of-three   Draft        75%   Next: Write discussion
  📤 collider           Under Review      Next: Address R2 comments
  ✓ pmed               Published

  TEACHING
  ──────────────────────────────────────────────────────────────────────────────
  📚 STAT-440   Week 14/15   Next: Final exam prep
  📚 STAT-579   Week 14/15   Next: Project presentations

  ⚡ QUICK ACTIONS
  ──────────────────────────────────────────────────────────────────────────────
  [1] Continue: product-of-three (last edited)
  [2] Review: mediationsens (stale)
  [3] Prepare: STAT-440 final
```

---

## Implementation Phases

### Phase 1: Foundation (Week 1)

| Task | Effort | Impact |
|------|--------|--------|
| Create `standards/` directory structure | 1 hour | High |
| Write R-STYLE-GUIDE.md | 2 hours | High |
| Create PROJECT-STRUCTURE.md | 1 hour | High |
| Create QUICK-START-TEMPLATE.md | 1 hour | High |

### Phase 2: Templates & Commands (Week 2)

| Task | Effort | Impact |
|------|--------|--------|
| Create R package template | 2 hours | High |
| Create `proj new` command | 2 hours | High |
| Implement unified `pb/pt/pd/pc` | 3 hours | Very High |
| Create research project template | 1 hour | Medium |

### Phase 3: Dashboard & Context (Week 3-4)

| Task | Effort | Impact |
|------|--------|--------|
| Implement project dashboard | 4 hours | Very High |
| Create context save/restore | 3 hours | Very High |
| Add `.STATUS` file parsing | 2 hours | High |

### Phase 4: R Ecosystem (Month 2)

| Task | Effort | Impact |
|------|--------|--------|
| Create package registry | 1 hour | Medium |
| Implement `r ecosystem` command | 2 hours | High |
| Share GitHub Actions across packages | 2 hours | High |

---

## Research & Best Practices

### DevOps Standards (Industry)

| Practice | Relevance | Adapt For |
|----------|-----------|-----------|
| **12-Factor App** | Configuration, dependencies | R packages, research |
| **GitFlow** | Branch strategy | Simplified for solo dev |
| **Semantic Versioning** | Release management | All projects |
| **CI/CD** | Automated testing | GitHub Actions |
| **Infrastructure as Code** | Reproducibility | Project templates |

### ADHD-Specific Research

| Finding | Application |
|---------|-------------|
| **Working memory limits** | External systems (notes, dashboards) |
| **Time blindness** | Built-in timers, visible progress |
| **Hyperfocus risk** | Forced breaks, session limits |
| **Context switching cost** | Minimize, save/restore state |
| **Decision fatigue** | Smart defaults, fewer choices |
| **Novelty seeking** | Progress visualization, achievements |

### R Package Best Practices

| Practice | Source | Implementation |
|----------|--------|----------------|
| **usethis conventions** | RStudio | Templates |
| **testthat 3e** | Wickham | Test structure |
| **pkgdown** | RStudio | Documentation |
| **GitHub Actions** | r-lib | CI/CD |
| **roxygen2** | RStudio | Documentation |

---

## Quick Wins to Start Today

### 1. Create Standards Directory

```bash
mkdir -p standards/{code,project,workflow,adhd}
mkdir -p templates/{r-package,quarto-manuscript,research-project}
mkdir -p r-ecosystem/{shared,scripts}
```

### 2. First Standard Document

Create `standards/adhd/QUICK-START-TEMPLATE.md`:

```markdown
# [Project Name] - Quick Start

## 30-Second Setup
\`\`\`bash
[one command to get running]
\`\`\`

## What This Does
[2-3 bullet points max]

## Common Tasks
| I want to... | Run this |
|--------------|----------|
| Build | `pb` |
| Test | `pt` |
| Deploy | `pd` |

## Where Things Are
- Main code: `src/` or `R/`
- Tests: `tests/`
- Docs: `docs/`

## Current Status
See `.STATUS` file or run `proj status`
```

### 3. Unified Commands Stub

Add to `zsh/functions/project-commands.zsh`:

```zsh
pb() { echo "Project Build - TODO: implement" }
pt() { echo "Project Test - TODO: implement" }
pd() { echo "Project Docs - TODO: implement" }
pc() { echo "Project Check - TODO: implement" }
```

---

## Success Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Commands to remember | 50+ | 10 |
| Context switch time | 5-10 min | 30 sec |
| "Where was I?" frequency | Daily | Never |
| Project setup time | 30 min | 2 min |
| Consistent code style | 30% | 100% |

---

## Document History

- **2025-12-17**: Initial proposal created during brainstorming session
