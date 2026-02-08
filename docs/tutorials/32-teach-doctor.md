# Tutorial 32: Teaching Environment Health Check

> A step-by-step guide to `teach doctor` v2 — the two-mode health check for teaching projects.

---

## What You'll Learn

- Run quick and full health checks on your teaching project
- Understand each check category and what it validates
- Use output modes (brief, verbose, JSON, CI) for different workflows
- Auto-fix common issues with `--fix`
- Integrate health checks into your CI/CD pipeline

## Prerequisites

- flow-cli v6.5.0+ installed
- A teaching project initialized with `teach init`

---

## Step 1: Quick Check (Default)

The default `teach doctor` runs a **quick check** targeting < 3 seconds:

```bash
teach doctor
```

**Output:**
```
╭────────────────────────────────────────────────────────────╮
│  Teaching Environment (quick check)                        │
╰────────────────────────────────────────────────────────────╯

Dependencies:
  ✓ yq (4.52.2)
  ✓ git (2.52.0)
  ✓ quarto (1.8.27)
  ✓ gh (2.86.0)
  ✓ examark (0.6.6)
  ✓ claude (2.1.37)

R Environment:
  ✓ R (4.5.2) | renv active | 27 packages locked

Project Configuration:
  ✓ .flow/teach-config.yml exists
  ✓ Course name: STAT 545
  ✓ Semester: spring
  ✓ Dates configured (2026-01-19 - 2026-05-16)

Git Setup:
  ✓ Git repository initialized
  ✓ Draft branch exists
  ✓ Production branch exists: production
  ✓ Remote configured: origin
  ✓ Working tree clean

  Skipped (run --full): R packages, quarto extensions, hooks, cache, macros, style

────────────────────────────────────────────────────────────
Passed: 17  [0s]
────────────────────────────────────────────────────────────
```

**Quick mode checks 4 categories:**

| Category | What It Validates |
|----------|-------------------|
| Dependencies | Required: yq, git, quarto, gh. Optional: examark, claude |
| R Environment | R version, renv status, package count summary |
| Configuration | `.flow/teach-config.yml` exists, course name, semester, dates |
| Git Setup | Repo initialized, draft/production branches, remote, working tree |

---

## Step 2: Full Check

Add `--full` to run all 11 check categories:

```bash
teach doctor --full
```

This adds 7 more categories with a spinner for slower checks:

| Category | What It Validates |
|----------|-------------------|
| R Packages | Per-package install verification (single R invocation) |
| Quarto Extensions | Extension count and listing |
| Scholar Integration | Claude Code, Scholar plugin, lesson plans |
| Git Hooks | pre-commit, pre-push, prepare-commit-msg |
| Cache Health | `_freeze/` size, freshness, file count |
| LaTeX Macros | Sources, registry sync, CLAUDE.md docs, unused macros |
| Teaching Style | Config location, pedagogical approach, command overrides |

!!! note "Macro and registry checks are opt-in"
    The macro registry and unused macro checks only run when
    `scholar.latex_macros.enabled: true` is set in your teach-config.yml.
    Projects using direct Quarto `include-in-header` won't see false positives.

---

## Step 3: Understanding Status Levels

Each check returns one of three statuses:

| Symbol | Status | Meaning |
|--------|--------|---------|
| `✓` (green) | Pass | Check succeeded |
| `⚠` (yellow) | Warning | Non-blocking issue, fix suggested |
| `✗` (red) | Failure | Critical issue, must fix |

The summary footer shows totals:

```
────────────────────────────────────────────────────────────
Warnings: 3 | Passed: 28  [5s]

  Run teach doctor --fix to auto-fix issues
────────────────────────────────────────────────────────────
```

---

## Step 4: Auto-Fix Issues

Use `--fix` to interactively resolve issues:

```bash
teach doctor --fix
```

This implies `--full` and prompts for each fixable issue:

```
Dependencies:
  ✗ examark (not found)
    Install examark? [y/N]: y
    → npm install -g examark
    ✓ examark installed

R Packages:
  ⚠ 3/5 R packages installed | Missing: tidyr, knitr
    Install via renv or system? [r/s]: r
    → renv::install(c("tidyr", "knitr"))
```

**What `--fix` can resolve:**

- Missing dependencies (brew/npm install)
- Missing R packages (renv or system install)
- Missing git hooks (`teach hooks install`)
- Stale freeze cache (clear and re-render)

---

## Step 5: Output Modes

### Brief Mode

Show only warnings and failures:

```bash
teach doctor --brief
```

```
  ⚠ Config validation failed
    → Fix with: teach validate
  ⚠ Hook not installed: prepare-commit-msg
    → Install with: teach hooks install
────────────────────────────────────────────────────────────
Warnings: 2  [0s]
────────────────────────────────────────────────────────────
```

### Verbose Mode

Show expanded detail for every check (implies `--full`):

```bash
teach doctor --verbose
```

Verbose adds:

- **R packages**: Individual `✓ R package: ggplot2` lines for each package
- **renv.lock age**: `renv.lock updated 2 days ago`
- **Unused macros**: Full list instead of truncated `(+N more, use --verbose)`

### JSON Output

Machine-readable output for scripting:

```bash
teach doctor --json --full | jq '.summary'
```

```json
{
  "passed": 28,
  "warnings": 3,
  "failures": 0,
  "status": "yellow"
}
```

### CI Mode

No colors, machine-readable key=value, exits with code 1 on failure:

```bash
teach doctor --ci --full
```

```
doctor:status=pass
doctor:passed=28
doctor:warnings=3
doctor:failures=0
doctor:mode=full
doctor:elapsed=5s
```

---

## Step 6: Health Indicator

After each run, `teach doctor` writes `.flow/doctor-status.json`. The `teach` command shows a colored dot on startup:

| Dot Color | Status | Meaning |
|-----------|--------|---------|
| Green `●` | All passed | No warnings or failures |
| Yellow `●` | Warnings | Non-blocking issues found |
| Red `●` | Failures | Critical issues need attention |

The dot auto-refreshes if the status file is older than 1 hour.

---

## Common Workflows

### Pre-Commit Quick Check

```bash
teach doctor --brief
```

### Pre-Deploy Full Audit

```bash
teach doctor --full
# Fix any issues before deploying
teach doctor --fix
teach deploy --direct
```

### CI/CD Pipeline

```yaml
# GitHub Actions example
- name: Health check
  run: teach doctor --ci --full || exit 1
```

Or with JSON parsing:

```bash
status=$(teach doctor --json --full | jq -r '.summary.status')
if [ "$status" = "red" ]; then
  echo "Health check failed"
  exit 1
fi
```

### First-Time Setup

```bash
teach init
teach doctor --fix
```

### Debugging Issues

```bash
# Full detail on every check
teach doctor --verbose

# JSON for programmatic analysis
teach doctor --json --full | jq '.checks[] | select(.status == "warn")'
```

---

## Check Reference

### Quick Mode Checks

#### Dependencies

| Tool | Required | Install |
|------|----------|---------|
| yq | Yes | `brew install yq` |
| git | Yes | `xcode-select --install` |
| quarto | Yes | `brew install --cask quarto` |
| gh | Yes | `brew install gh` |
| examark | No | `npm install -g examark` |
| claude | No | [code.claude.com](https://code.claude.com) |

#### R Environment

- Checks R availability and version (`R --version`)
- Detects renv activation (`renv.lock` + `renv/activate.R`)
- Counts locked packages from `renv.lock`
- Verbose mode: shows renv.lock age

#### Project Configuration

- `.flow/teach-config.yml` exists
- Config schema validation (if `_teach_validate_config` available)
- Course name, semester, and date fields populated

#### Git Setup

- Git repo initialized (works in worktrees too)
- Draft and production branches exist
- Remote origin configured
- Working tree status (excludes `doctor-status.json`)

### Full Mode Checks

#### R Packages

- Single R invocation to query all installed packages (fast, renv-safe)
- Compares against packages defined in teach-config.yml, renv.lock, or DESCRIPTION
- Falls back to common teaching packages: ggplot2, dplyr, tidyr, knitr, rmarkdown
- `--fix` mode: offers renv or system install

#### Quarto Extensions

- Counts extensions in `_extensions/*/*` directories
- Lists each extension by `org/name` format

#### Scholar Integration

- Claude Code CLI available
- Scholar plugin installed at `~/.claude/plugins/scholar`
- Lesson plans at `.flow/lesson-plans.yml` (optional)

#### Git Hooks

- Checks: pre-commit, pre-push, prepare-commit-msg
- Distinguishes flow-cli managed vs custom hooks
- `--fix` mode: offers `teach hooks install`

#### Cache Health

- `_freeze/` directory existence and size
- Cache freshness: today, < 7 days, < 30 days, 30+ days (stale)
- File count in cache
- `--fix` mode: offers to clear stale cache

#### LaTeX Macros (opt-in)

Only runs when `scholar.latex_macros.enabled: true` in teach-config.yml:

1. **Source files**: Discovers and lists macro source files
2. **Registry sync**: Checks `.flow/macros/registry.yml` freshness vs sources
3. **CLAUDE.md**: Verifies macro documentation exists for AI context
4. **Unused macros**: Scans content files for macro usage, reports unused count

#### Teaching Style

- Detects style source (teach-config.yml or legacy .md file)
- Reports pedagogical approach, command overrides count
- Detects legacy shim redirect
- Warns on unconfigured style

---

## See Also

- [Health Check Refcard](../reference/REFCARD-DOCTOR.md) — Quick reference card
- [Doctor Command](../commands/doctor.md) — `flow doctor` (not teach doctor)
- [Token Management](../guides/DOCTOR-TOKEN-USER-GUIDE.md) — GitHub token checks
- [LaTeX Macros Tutorial](26-latex-macros.md) — Macro system setup

---

**Version:** v6.5.0
**Last Updated:** 2026-02-08
