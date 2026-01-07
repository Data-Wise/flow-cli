# flow-cli Conventions & Standards

> **TL;DR:** Consistent conventions across all dev-tools projects. Less thinking, more doing.

**Migrated From:** dev-planning/standards/ (2026-01-07)

---

## Philosophy

1. **Copy-paste ready** — Every guide has commands you can run
2. **TL;DR first** — Summary at the top, details below
3. **Decision trees** — "If X, do Y" not essays
4. **One source of truth** — Standards live here, nowhere else

---

## Quick Links

| Category | What's There |
|----------|--------------|
| [**adhd/**](adhd/) | ADHD-friendly templates and recovery guides |
| [**code/**](code/) | Style guides (R, Python, ZSH) |
| [**documentation/**](documentation/) | Website design, MkDocs standards |
| [**project/**](project/) | Project structure, PM system, coordination |
| [**workflow/**](workflow/) | Git workflow, releases, reviews |

---

## Index

### ADHD Guides

- `adhd/QUICK-START-TEMPLATE.md` — 30-second project onboarding
- `adhd/GETTING-STARTED-TEMPLATE.md` — 10-minute user training guide
- `adhd/TUTORIAL-TEMPLATE.md` — Step-by-step deep learning guides
- `adhd/REFCARD-TEMPLATE.md` — One-page quick reference cards

### Code Style

- `code/R-STYLE-GUIDE.md` — R coding conventions
- `code/ZSH-COMMANDS-HELP.md` — ZSH command help output standard
- `code/COMMIT-MESSAGES.md` — Git commit format

### Project Standards

- `project/PROJECT-STRUCTURE.md` — Directory conventions
- `project/PROJECT-MANAGEMENT-STANDARDS.md` — .STATUS + PROJECT-HUB.md system
- `project/COORDINATION-GUIDE.md` — Cross-project coordination

### Workflow

- `workflow/GIT-WORKFLOW.md` — Branches, PRs, merges
- `workflow/RELEASE-PROCESS.md` — How to release

---

## How to Use

### View Standards

```bash
# Navigate to conventions
cd /Users/dt/projects/dev-tools/flow-cli/docs/conventions

# Read a specific standard
cat code/COMMIT-MESSAGES.md

# Browse all standards
ls -R
```

### Access from flow-cli

```bash
# Quick reference
flow help conventions    # (future feature)

# Check compliance
flow check               # (future feature)
```

---

## Why Here?

**flow-cli owns these standards because:**

1. **Natural fit** - flow-cli implements shell workflow conventions
2. **Authority** - What flow-cli does becomes the standard
3. **Enforcement** - Future `flow check` will validate compliance
4. **Documentation** - Standards live with the tool that uses them

---

## Related Documentation

- **Integration maps**: `atlas/docs/INTEGRATIONS.md`
- **flow-cli docs**: https://data-wise.github.io/flow-cli/
- **Tool inventory**: `flow dash --inventory`

---

**Maintained by:** flow-cli project
**Last Updated:** 2026-01-07
**Migrated from:** dev-planning/standards/
