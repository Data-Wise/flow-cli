# Standards Hub

> **TL;DR:** Consistent conventions across all projects. Less thinking, more doing.

## Role in Hub Architecture

This is the **Standards Hub** — one tier of the three-tier project management system:

```
┌─────────────────────────────────────────────────────────────┐
│  project-hub/           │ Master aggregation & weekly plan  │
├─────────────────────────────────────────────────────────────┤
│  mediation-planning/    │ R packages coordination           │
│  dev-planning/          │ Dev tools coordination            │
├─────────────────────────────────────────────────────────────┤
│  zsh-configuration/     │                                   │
│    └─ standards/        │ ← YOU ARE HERE                    │
│                         │ Universal conventions for ALL     │
└─────────────────────────────────────────────────────────────┘
```

**This folder contains:** Universal standards referenced by all projects across all domains.

**See also:** [../docs/planning/PROJECT-HUB-PROPOSAL.md](../docs/planning/PROJECT-HUB-PROPOSAL.md) for full architecture.

---

## Quick Links

| Category | What's There |
|----------|--------------|
| [**adhd/**](adhd/) | ADHD-friendly templates and recovery guides |
| [**code/**](code/) | Style guides (R, Python, ZSH) |
| [**documentation/**](documentation/) | Website design, MkDocs standards |
| [**project/**](project/) | Project structure, PM system, coordination |
| [**workflow/**](workflow/) | Git workflow, releases, reviews |

## Philosophy

1. **Copy-paste ready** — Every guide has commands you can run
2. **TL;DR first** — Summary at the top, details below
3. **Decision trees** — "If X, do Y" not essays
4. **One source of truth** — Standards live here, nowhere else

## How to Use

```bash
# Quick reference
cat standards/adhd/QUICK-START-TEMPLATE.md

# When starting a new project
proj new r-package mypackage   # Uses templates/

# Check compliance
proj check                     # Validates against standards
```

## Index

### ADHD Guides
- `adhd/QUICK-START-TEMPLATE.md` — 30-second project onboarding
- `adhd/GETTING-STARTED-TEMPLATE.md` — 10-minute user training guide
- `adhd/TUTORIAL-TEMPLATE.md` — Step-by-step deep learning guides
- `adhd/REFCARD-TEMPLATE.md` — One-page quick reference cards
- `adhd/DECISION-TREES.md` — "What do I do when..."
- `adhd/CONTEXT-RECOVERY.md` — "Where was I?"

### Code Style
- `code/R-STYLE-GUIDE.md` — R coding conventions
- `code/ZSH-COMMANDS-HELP.md` — ZSH command help output standard
- `code/COMMIT-MESSAGES.md` — Git commit format

### Project Standards
- `project/PROJECT-STRUCTURE.md` — Directory conventions
- `project/PROJECT-MANAGEMENT-STANDARDS.md` — Two-tier PM system (.STATUS + PROJECT-HUB.md) ⭐ NEW
- `project/COORDINATION-GUIDE.md` — Cross-project coordination ⭐ NEW
- `project/README-TEMPLATE.md` — Standard README format
- `project/VERSIONING.md` — Semantic versioning

### Workflow
- `workflow/GIT-WORKFLOW.md` — Branches, PRs, merges
- `workflow/RELEASE-PROCESS.md` — How to release
