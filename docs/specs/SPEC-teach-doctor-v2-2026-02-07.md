# SPEC: teach doctor v2 — Fast Default, Full Opt-in, renv-Aware

**Status:** draft
**Created:** 2026-02-07
**From Brainstorm:** BRAINSTORM-teach-doctor-improvements-2026-02-07.md
**Target Version:** v6.5.0

---

## Overview

Redesign `teach doctor` around a two-mode architecture: **quick** (default, < 3s) and **full** (opt-in, comprehensive). Fix 3 existing bugs (Quarto arithmetic error, R package false negatives from renv isolation, section nesting). Add renv-awareness, spinner UX with elapsed time, severity-grouped summary with fix commands, and a status-line health indicator on `teach` startup.

---

## Primary User Story

**As a** course instructor using flow-cli,
**I want** instant environment health feedback with smart R/renv detection,
**So that** I can catch issues fast without waiting 30+ seconds or seeing false warnings.

### Acceptance Criteria

- [ ] `teach doctor` (quick mode) completes in < 3 seconds
- [ ] `teach doctor --full` runs all checks including per-package R, cache, macros, style
- [ ] Quarto extensions check no longer crashes on non-numeric input
- [ ] R package check detects renv and reports status (active/inactive, library path, lock freshness, sync status)
- [ ] R section shows summary + exceptions only: "R: 25/27 installed | Missing: pkgA, pkgB"
- [ ] Spinner per section with elapsed time shown after 5 seconds
- [ ] Summary grouped by severity: failures with fix commands first, then warning count, then pass count
- [ ] `--fix` mode offers renv vs system install choice for R packages
- [ ] Quick mode shows inline hints: "R: ok (run --full for package details)"
- [ ] `teach` startup shows green/yellow/red health dot from quick doctor results
- [ ] `teach doctor --ci` exits non-zero on failure, no color, machine-readable
- [ ] `--quiet` renamed to `--brief`
- [ ] All existing tests pass (`./tests/run-all.sh`)
- [ ] New tests for all changed behavior

---

## Secondary User Stories

**As a** CI/CD pipeline (GitHub Action),
**I want** `teach doctor --ci` with non-zero exit on failures,
**So that** PRs are blocked when the teaching environment is broken.

**As an** instructor in a non-teaching directory,
**I want** doctor to gracefully detect context and skip irrelevant checks,
**So that** I don't see 27 false R package warnings.

**As an** instructor using renv,
**I want** doctor to explain which library it's checking and whether renv.lock is synced,
**So that** I understand why packages might appear missing.

---

## Architecture

```
teach doctor [flags]
  -> _teach_doctor()
       |-- Parse flags (--full, --brief, --fix, --json, --ci)
       |-- Determine mode (quick or full)
       |
       |-- QUICK MODE (default, < 3s):
       |     |-- _teach_doctor_check_dependencies()  # CLI tools only
       |     |-- _teach_doctor_check_r_quick()        # R available? renv status?
       |     |-- _teach_doctor_check_config()         # Config exists?
       |     |-- _teach_doctor_check_git()            # Branch, remote
       |     +-- Inline hints for skipped sections
       |
       |-- FULL MODE (--full):
       |     |-- Everything in quick mode, PLUS:
       |     |-- _teach_doctor_check_r_packages()     # Per-package with batch R
       |     |-- _teach_doctor_check_quarto_extensions()
       |     |-- _teach_doctor_check_scholar()
       |     |-- _teach_doctor_check_hooks()
       |     |-- _teach_doctor_check_cache()
       |     |-- _teach_doctor_check_macros()
       |     +-- _teach_doctor_check_teaching_style()
       |
       |-- _teach_doctor_summary()  # Severity-grouped
       +-- Exit code (0=ok, 1=failures)
```

### Status Line Integration

```
teach [any subcommand]
  -> Check last doctor result (file-based, no cache TTL)
  -> If stale or missing: run quick doctor silently
  -> Show dot in header: green/yellow/red
```

---

## Technical Requirements

### Bug Fix 1: Quarto Extensions Arithmetic Error

**File:** `lib/dispatchers/teach-doctor-impl.zsh` lines 473-501

**Problem:** `find _extensions | wc -l` produces non-numeric output, breaking ZSH arithmetic.

**Fix:** Replace with pure ZSH glob:

```zsh
_teach_doctor_check_quarto_extensions() {
    if [[ ! -d "_extensions" ]]; then
        return 0
    fi
    # ...header...
    local -a ext_dirs=(_extensions/*/*(/N))
    local ext_count=${#ext_dirs}
    # ... rest of function uses ext_count safely ...
}
```

### Bug Fix 2: R Package False Negatives (renv Isolation)

**Problem:** `R --quiet --slave -e "require('pkg')"` checks the active library. Under renv, that's the project library, not the system library. Packages appear "not found" even though they're system-installed.

**Fix:** Use `installed.packages()` in a single batch call, with renv-awareness:

```zsh
_teach_doctor_check_r_packages() {
    # Detect renv first
    local renv_active=false
    if [[ -f "renv.lock" && -f "renv/activate.R" ]]; then
        renv_active=true
    fi

    # Batch check: single R invocation for ALL packages
    local installed_list
    installed_list=$(R --quiet --slave -e "cat(rownames(installed.packages()), sep='\n')" 2>/dev/null)

    # Compare against expected packages
    # ...
}
```

### Bug Fix 3: Section Nesting

**Problem:** R packages and Quarto extensions are called inside `_teach_doctor_check_dependencies()`.

**Fix:** Promote both to top-level calls in `_teach_doctor()`.

### Feature: Two-Mode Architecture

| Aspect | Quick (default) | Full (--full) |
|--------|----------------|---------------|
| Runtime target | < 3 seconds | < 30 seconds |
| CLI dependencies | yes | yes |
| Config exists | yes | yes |
| Git status | yes | yes |
| R available | yes | yes |
| R per-package checks | no (summary hint) | yes (batch) |
| Quarto extensions | no | yes |
| Scholar integration | no | yes |
| Git hooks | no | yes |
| Cache freshness | no | yes |
| LaTeX macros | no | yes |
| Teaching style | no | yes |

### Feature: Spinner with Elapsed Time

```zsh
_teach_doctor_spinner_start() {
    local label="$1"
    # Start background spinner
    # After 5s, append "(Xs)" with updating timer
}

_teach_doctor_spinner_stop() {
    # Stop spinner, show result
}
```

Implementation: Background subshell writes spinner characters to `/dev/tty`. Main process sends SIGUSR1 or writes to a named pipe to stop it. Elapsed time updates every second after 5s threshold.

### Feature: Severity-Grouped Summary

```
────────────────────────────────────────────────────────────
Failures (2):
  x R package 'ggplot2' not found
    -> Install: R -e "install.packages('ggplot2')"
  x Quarto not found
    -> Install: brew install --cask quarto

Warnings: 3 | Passed: 12
────────────────────────────────────────────────────────────
```

### Feature: renv-Aware R Section

**Quick mode output:**
```
R Environment:
  ok R (4.4.2) | renv active | library synced
     -> Run --full for 27 package details
```

**Full mode output:**
```
R Environment:
  ok R (4.4.2)
  ok renv active (library: renv/library/macos/R-4.4/aarch64-apple-darwin20)
  ok renv.lock last updated: 2026-02-01
  ok renv sync: 27/27 packages match lock file
  ok R: 25/27 installed | Missing: pkgA, pkgB
```

**renv detection details:**
- renv status: active/inactive (check `renv/activate.R` exists + sourced in `.Rprofile`)
- Library path: `renv/library/...` path
- Lock file freshness: `stat -f %m renv.lock` → human-readable age
- Sync status: Compare `installed.packages()` against `renv.lock` entries

### Feature: --fix with renv Choice

When fixing R packages with renv detected:

```
Missing R packages: pkgA, pkgB
  -> Install via renv or system? [r/s]
  r) renv::install(c("pkgA", "pkgB"))  # Project-local
  s) install.packages(c("pkgA", "pkgB"))  # System-wide
```

### Feature: Status Line Health Indicator

On `teach` startup (any subcommand):

```zsh
_teach_health_indicator() {
    # Read last quick-doctor result from .flow/doctor-status.json
    # If file missing or > 1 hour old, run quick doctor silently
    # Return emoji: green_dot / yellow_dot / red_dot
}
```

Status file: `.flow/doctor-status.json`
```json
{
    "timestamp": "2026-02-07T10:30:00Z",
    "passed": 12,
    "warnings": 3,
    "failures": 0,
    "status": "yellow"
}
```

### Feature: --ci Mode + GitHub Action

```zsh
# teach doctor --ci
# - No color codes (FLOW_COLORS all empty)
# - No spinners
# - Exit code 1 on any failure
# - Stdout: machine-parseable summary
# - Compatible with GitHub Actions annotation format
```

GitHub Action integration (future):

```yaml
# .github/workflows/teach-doctor.yml
- name: Check teaching environment
  run: teach doctor --ci
```

### Feature: --brief (renamed from --quiet)

`--brief` shows only failures and warnings, no passed checks. `--quiet` remains as deprecated alias.

### Feature: --verbose (new)

`--verbose` shows expanded info for every check (library paths, versions, config values). Default shows medium detail.

---

## API Design

N/A - CLI command, no API changes.

---

## Data Models

### .flow/doctor-status.json (new)

```json
{
    "version": 1,
    "timestamp": "2026-02-07T10:30:00Z",
    "mode": "quick",
    "checks": {
        "dependencies": {"passed": 6, "warnings": 0, "failures": 0},
        "r_environment": {"passed": 1, "warnings": 0, "failures": 0, "renv": true},
        "config": {"passed": 3, "warnings": 1, "failures": 0},
        "git": {"passed": 4, "warnings": 0, "failures": 0}
    },
    "totals": {"passed": 14, "warnings": 1, "failures": 0},
    "status": "yellow"
}
```

---

## Dependencies

- No new external dependencies (pure ZSH)
- Existing: `R` (optional), `yq`, `git`, `quarto`, `gh`

---

## UI/UX Specifications

### Quick Mode Output (Default)

```
 Teaching Environment (quick check)            [2.1s]

Dependencies:
  ok yq (4.52.2)
  ok git (2.52.0)
  ok quarto (1.8.27)
  ok gh (2.86.0)
  ok examark (0.6.6)
  ok claude (2.1.37)

R Environment:
  ok R (4.4.2) | renv active | 27/27 synced
     -> Run --full for package details

Project Configuration:
  ok .flow/teach-config.yml
  ok Course: STAT-545 (Spring 2026)

Git:
  ok Clean working tree
  ok Remote: origin/main (up to date)

Skipped (run --full): quarto extensions, hooks, cache, macros, style

Summary: 14 passed, 0 warnings, 0 failures
```

### Full Mode Output

```
 Teaching Environment (full check)

Dependencies:                                   [0.8s]
  ok yq (4.52.2)
  ok git (2.52.0)
  ...

R Environment:                                  [4.2s]
  ok R (4.4.2)
  ok renv active (renv/library/macos/R-4.4/aarch64-apple-darwin20)
  ok renv.lock updated: 3 days ago
  ok renv sync: 27/27 match
  ok R: 25/27 installed | Missing: bayestestR, modelbased

Quarto Extensions:                              [0.3s]
  ok 4 extensions installed
     -> quarto-ext/fontawesome
     -> quarto-ext/lightbox
     ...

...more sections...

Failures (2):
  x R package 'bayestestR' not found
    -> R -e "renv::install('bayestestR')"
  x R package 'modelbased' not found
    -> R -e "renv::install('modelbased')"

Warnings: 1 | Passed: 38
```

### Accessibility

N/A - CLI output. Uses existing FLOW_COLORS system with fallback for no-color terminals.

---

## Open Questions

1. **Health indicator refresh strategy:** Should the status line dot persist from last explicit `teach doctor` run, or silently re-run quick checks? (Current decision: file-based, re-run if > 1 hour stale)
2. **GitHub Action:** Should this be a separate spec or part of this one? (Suggest: separate spec for the Action, this spec covers `--ci` flag only)
3. **Spinner implementation:** Named pipe vs temp file vs /dev/tty direct write? Need to test which approach works reliably across iTerm2/Terminal.app/tmux.

---

## Review Checklist

- [ ] All 3 bugs fixed and tested
- [ ] Quick mode < 3s verified on real teaching project
- [ ] Full mode backward-compatible with current output
- [ ] --brief, --fix, --json, --ci all work
- [ ] renv detection works with and without renv
- [ ] Spinner works in iTerm2 + tmux
- [ ] Status line health dot displays correctly
- [ ] All existing tests pass
- [ ] New tests cover mode switching, renv detection, edge cases
- [ ] CLAUDE.md updated with new flags

---

## Implementation Notes

### Incremental Delivery (Suggested)

| Increment | Scope | Effort |
|-----------|-------|--------|
| **1. Bug fixes** | Fix 3 bugs (quarto, R batch, section nesting) | 1 hour |
| **2. Two-mode architecture** | Quick/full split, inline hints | 2 hours |
| **3. renv awareness** | Detect renv, report status, fix choice | 2 hours |
| **4. Spinner UX** | Per-section spinner with elapsed time | 1.5 hours |
| **5. Summary redesign** | Severity-grouped with fix commands | 1 hour |
| **6. --brief, --ci, --verbose** | Flag renames and additions | 1 hour |
| **7. Status line integration** | Health dot on teach startup | 1.5 hours |
| **8. Tests** | Comprehensive test suite | 2 hours |

**Total estimated increments:** 8 | **Recommended order:** 1 -> 2 -> 3 -> 5 -> 4 -> 6 -> 7 -> 8

### Key Design Decisions from Brainstorm

- Quick mode is the **default** (no flag needed)
- Full mode is opt-in via `--full`
- No result caching (always fresh checks)
- Per-issue prompts in --fix mode (current behavior kept)
- Spinner shows elapsed time after 5s threshold
- R section: summary + exceptions only (not full package list)
- renv: always offer install choice (renv vs system)
- `--quiet` -> `--brief` rename (quiet still works as alias)

---

## History

| Date | Change |
|------|--------|
| 2026-02-07 | Initial draft from deep brainstorm (20 questions) |
