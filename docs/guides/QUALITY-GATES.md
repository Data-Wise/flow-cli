---
tags:
  - guide
  - quality
  - ci
---

# Quality Gates

> Every validation layer in flow-cli, from keystroke to production.
>
> **Version:** v6.6.0+

---

## Overview

flow-cli uses multiple validation layers to catch issues at the earliest possible stage. Each layer targets different failure modes and runs at a different point in the development lifecycle.

```
Keystroke → Pre-commit → Manual lint → CI → Deploy preflight → Production
```

---

## Layer 1: Pre-Commit Hooks

**When:** Every `git commit` (automatic via Husky + lint-staged)

### Prettier (Formatting)

| Setting | Value |
|---------|-------|
| Files | `*.{json,md,yml,yaml}` |
| Action | Auto-fix on stage (`prettier --write`) |
| Config | `.prettierrc` / defaults |

Catches inconsistent formatting before it enters the commit history.

### Display Math Validation

| Setting | Value |
|---------|-------|
| Files | `*.qmd` |
| Action | Fail on issues (`zsh scripts/check-math.zsh`) |
| Checks | Blank lines inside `$$` blocks, unclosed `$$` blocks |

Catches two Quarto rendering issues early:

1. **Blank lines in `$$` blocks** — silently breaks PDF output
2. **Unclosed `$$` blocks** — breaks page rendering entirely

The same validation runs during `teach deploy` preflight, but this pre-commit gate gives immediate feedback without waiting for deploy time.

**Bypass (emergency):**

```bash
git commit --no-verify -m "message"
```

### Setup

Pre-commit hooks require a one-time install:

```bash
npm install   # installs husky + lint-staged
```

Husky auto-configures via the `prepare` script in `package.json`.

---

## Layer 2: Manual Linters

**When:** On-demand, developer-initiated

### ZSH Lint (`teach lint`)

Validates ZSH source files for syntax and style issues.

```bash
# Quick check
teach lint

# Specific file
teach lint lib/dispatchers/teach-deploy-enhanced.zsh
```

### Quarto Lint

Validates `.qmd` content structure:

```bash
# Validate single file
teach validate lectures/week-05.qmd

# Deep validation with prerequisites
teach validate --deep
```

### Markdown Lint

General markdown quality:

```bash
# Via npm script
npm run format:check

# Fix automatically
npm run format
```

### ESLint

JavaScript/config file linting:

```bash
npm run lint
npm run lint:fix
```

---

## Layer 3: CI Workflows

**When:** On push/PR to `main` or `dev` (automatic via GitHub Actions)

### ZSH Plugin Tests (`test.yml`)

| Trigger | Push/PR to `main`, `dev` |
|---------|--------------------------|
| Runner | Ubuntu latest |
| Tests | `test-flow.zsh` (smoke), `test-install.sh` |

Runs core smoke tests in a clean Ubuntu environment with mock project structure. Full test suite (137 files, 8000+ functions) runs locally via `./tests/run-all.sh`.

### Install Script Tests (`release.yml`)

| Trigger | Push to `main` |
|---------|----------------|
| Matrix | Ubuntu 22.04, Debian Bookworm, Alpine 3.20 |
| Tests | `test-install.sh`, `install.sh` syntax check |

Validates the install script across multiple Linux distributions before release.

### Documentation Deploy (`docs.yml`)

| Trigger | Push to `main` (paths: `docs/**`, `mkdocs.yml`) |
|---------|--------------------------------------------------|
| Action | `mkdocs gh-deploy --force --clean` |

Builds and deploys MkDocs site to GitHub Pages.

### Semantic Release (`release.yml`)

| Trigger | Push to `main` (after install tests pass) |
|---------|-------------------------------------------|
| Action | `npx semantic-release` |

Auto-generates changelog, creates GitHub release, bumps version based on conventional commits.

### Homebrew Release (`homebrew-release.yml`)

| Trigger | GitHub release published |
|---------|------------------------|
| Action | Updates Homebrew tap formula |

Updates the `data-wise/tap` formula with new version SHA and triggers auto-merge.

---

## Layer 4: Deploy Preflight

**When:** Every `teach deploy` invocation (automatic)

The deploy command runs five sequential checks before any branch operations:

| # | Check | Pass | Fail (interactive) | Fail (CI) |
|---|-------|------|--------------------|-----------|
| 1 | Branch verification | On draft branch | Offers switch | Blocks |
| 2 | Uncommitted changes | Clean tree | Offers commit | Blocks |
| 3 | Display math validation | `$$` blocks valid | Warns | Blocks |
| 4 | Unpushed commits | Synced with remote | Offers push | Blocks |
| 5 | Production conflicts | No divergence | Offers rebase | Blocks |

### Display Math Validation (Detail)

Only checks `.qmd` files in the `git diff` between draft and production branches — not the entire course. Reports specific files and issue types:

```
[!!] Blank lines in display math (breaks PDF):
     lectures/week-05.qmd

[!!] Unclosed $$ block (breaks render):
     lectures/week-03.qmd
```

See [Teach Deploy Guide — Display Math Validation](TEACH-DEPLOY-GUIDE.md#check-3-display-math-validation) for full details.

---

## Summary Table

| Gate | Stage | Trigger | Automated | Blocking |
|------|-------|---------|-----------|----------|
| Prettier | Pre-commit | `git commit` | Yes | Yes |
| Math `$$` check | Pre-commit | `git commit` (`.qmd`) | Yes | Yes |
| ZSH lint | Manual | `teach lint` | No | No |
| Quarto validate | Manual | `teach validate` | No | No |
| ESLint | Manual | `npm run lint` | No | No |
| Markdown format | Manual | `npm run format:check` | No | No |
| ZSH smoke tests | CI | Push/PR to main/dev | Yes | Yes |
| Install tests | CI | Push to main | Yes | Yes |
| Docs deploy | CI | Push to main (docs/) | Yes | N/A |
| Semantic release | CI | Push to main | Yes | N/A |
| Homebrew update | CI | Release published | Yes | N/A |
| Branch check | Deploy | `teach deploy` | Yes | Yes (CI) |
| Uncommitted check | Deploy | `teach deploy` | Yes | Yes (CI) |
| Math `$$` check | Deploy | `teach deploy` | Yes | Yes (CI) |
| Unpushed check | Deploy | `teach deploy` | Yes | Yes (CI) |
| Conflict check | Deploy | `teach deploy` | Yes | Yes (CI) |

---

## Known Gaps

Areas where validation could be added in the future:

| Gap | Impact | Effort |
|-----|--------|--------|
| No ShellCheck in CI | ZSH style issues reach main | Medium (needs ZSH compat flags) |
| No pre-push hooks | Untested code can be pushed | Low |
| No markdown lint in CI | Formatting drift in docs | Low |
| Full test suite not in CI | Only smoke tests run remotely | Medium (42 suites, timing) |
| No Quarto render check in CI | Broken renders not caught until deploy | High (needs Quarto in runner) |

---

## See Also

- [Teach Deploy Guide](TEACH-DEPLOY-GUIDE.md) — Full deployment workflow
- [Lint Validation Guide](LINT-GUIDE.md) — Content validation details
- [Lint Workflow](../workflows/WORKFLOW-LINT.md) — Lint workflow reference
- [Testing Guide](TESTING.md) — Test patterns and running tests
- [Developer Guide](DEVELOPER-GUIDE.md) — Contributing workflow

---

**Last Updated:** 2026-02-10
**Version:** v6.7.0
