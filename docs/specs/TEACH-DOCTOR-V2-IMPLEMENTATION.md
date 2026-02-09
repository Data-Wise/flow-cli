# Teach Doctor Implementation Guide

**Version:** v6.5.0 (Doctor v2)
**Status:** ✅ Complete Implementation
**Files:**
- `lib/dispatchers/teach-doctor-impl.zsh` (~1220 lines)
- `tests/test-teach-doctor-unit.zsh` (86 assertions, 19 suites)
- `tests/e2e-teach-doctor-v2.zsh` (33 tests, 14 workflows)
- `tests/dogfood-teach-doctor-v2.zsh` (43 tests, 11 sections)

---

## Overview

`teach doctor` is a two-mode health check system for teaching environments. Quick mode (default, < 3s) checks essentials; full mode (`--full`) runs all 11 check categories.

### Key Features

1. **Two-Mode Architecture** - Quick (< 3s) and Full (`--full`) checks
2. **10 Check Categories** - Dependencies, R env, Config, Git, R packages, Quarto ext, Scholar, Hooks, Cache, Macros, Teaching Style
3. **Interactive Fix Mode** (`--fix`) - Auto-fix missing deps, hooks, R packages
4. **CI/CD Mode** (`--ci`) - No color, machine-readable, exit 1 on failure
5. **JSON Output** (`--json`) - Machine-readable structured output
6. **Brief Mode** (`--brief`) - Only warnings/failures
7. **Verbose Mode** (`--verbose`) - Per-package R listing, full macro list
8. **Health Indicator** - Green/yellow/red dot on `teach` startup via `.flow/doctor-status.json`
9. **Spinner UX** - Background spinner for slow checks (> 5s shows elapsed)
10. **Non-destructive** - All checks are read-only (except with `--fix`)

---

## Usage

### Basic Health Check

```bash
teach doctor
```

**Output:**

```
╭────────────────────────────────────────────────────────────╮
│  📚 Teaching Environment Health Check                       │
╰────────────────────────────────────────────────────────────╯

Dependencies:
  ✓ yq (4.35.2)
  ✓ git (2.42.0)
  ✓ quarto (1.4.549)
  ✓ gh (2.40.1)
  ✓ examark (0.6.6)
  ✓ claude (installed)

R Packages:
  ✓ R package: ggplot2
  ✓ R package: dplyr
  ✓ R package: tidyr
  ✓ R package: knitr
  ✓ R package: rmarkdown

Quarto Extensions:
  ✓ 3 Quarto extensions installed
    → quarto/examify
    → quarto/manuscript
    → quarto/revealjs-custom

Project Configuration:
  ✓ .flow/teach-config.yml exists
  ✓ Config validates against schema
  ✓ Course name: STAT 440 - Regression Analysis
  ✓ Semester: Spring 2024
  ✓ Dates configured (2024-01-15 - 2024-05-10)

Git Setup:
  ✓ Git repository initialized
  ✓ Draft branch exists
  ✓ Production branch exists: main
  ✓ Remote configured: origin
  ✓ Working tree clean

Scholar Integration:
  ✓ Claude Code available
  ✓ Scholar skills accessible
  ✓ Lesson plan found: lesson-plan.yml

Git Hooks:
  ✓ Hook installed: pre-commit (flow-cli managed)
  ✓ Hook installed: pre-push (flow-cli managed)
  ✓ Hook installed: prepare-commit-msg (flow-cli managed)

Cache Health:
  ✓ Freeze cache exists (125M)
  ✓ Cache is fresh (rendered today)
    → 142 cached files

────────────────────────────────────────────────────────────
Summary: 28 passed, 0 warnings, 0 failures
────────────────────────────────────────────────────────────
```

### Interactive Fix Mode

```bash
teach doctor --fix
```

**Interactive Prompts:**

```
Dependencies:
  ✗ yq not found
  → Install yq? [Y/n] y
  → brew install yq
  ✓ yq installed

  ✗ examark not found (optional)
  → Install examark (optional)? [y/N] y
  → npm install -g examark
  ✓ examark installed

R Packages:
  ⚠ R package 'ggplot2' not found (optional)
  → Install R package 'ggplot2'? [y/N] y
  → Rscript -e "install.packages('ggplot2')"
  ✓ ggplot2 installed

Cache Health:
  ⚠ Cache is stale (31 days old)
  → Clear stale cache? [y/N] n
```

### Brief Mode

```bash
teach doctor --brief
```

**Only shows warnings and failures:**

```
  ⚠ examark not found (optional)
    → Install: npm install -g examark

  ⚠ Draft branch not found
    → Create with: git checkout -b draft

  ⚠ Cache is stale (31 days old)
    → Run: quarto render

────────────────────────────────────────────────────────────
Summary: 25 passed, 3 warnings, 0 failures
────────────────────────────────────────────────────────────
```

### JSON Output (CI/CD)

```bash
teach doctor --json
```

**Output:**

```json
{
  "summary": {
    "passed": 28,
    "warnings": 3,
    "failures": 0,
    "status": "healthy"
  },
  "checks": [
    {"check":"dep_yq","status":"pass","message":"4.35.2"},
    {"check":"dep_git","status":"pass","message":"2.42.0"},
    {"check":"dep_quarto","status":"pass","message":"1.4.549"},
    {"check":"dep_gh","status":"pass","message":"2.40.1"},
    {"check":"dep_examark","status":"warn","message":"not found (optional)"},
    {"check":"config_exists","status":"pass","message":"exists"},
    {"check":"config_valid","status":"pass","message":"valid"},
    {"check":"course_name","status":"pass","message":"STAT 440"},
    {"check":"git_repo","status":"pass","message":"initialized"},
    {"check":"draft_branch","status":"warn","message":"not found"},
    {"check":"cache_exists","status":"pass","message":"125M"},
    {"check":"cache_freshness","status":"warn","message":"31 days old"}
  ]
}
```

**CI/CD Integration:**

```yaml
# .github/workflows/health-check.yml
- name: Health Check
  run: |
    teach doctor --json > health.json
    jq -e '.summary.status == "healthy"' health.json
```

---

## Check Categories

### 1. Dependencies

**Required:**
- `yq` - YAML processing (brew install yq)
- `git` - Version control (xcode-select --install)
- `quarto` - Document rendering (brew install --cask quarto)
- `gh` - GitHub CLI (brew install gh)

**Optional:**
- `examark` - Exam generation (npm install -g examark)
- `claude` - Claude Code CLI (https://code.claude.com)

**R Packages (if R available):**
- ggplot2, dplyr, tidyr, knitr, rmarkdown

**Quarto Extensions:**
- Detected from `_extensions/` directory
- Lists all installed extensions

### 2. Project Configuration

**Checks:**
- `.flow/teach-config.yml` exists
- YAML syntax valid (via yq)
- Schema validation (if validator available)
- Course name configured
- Semester configured
- Semester dates configured

**Fix Actions:**
- Missing config → `teach init`
- Invalid syntax → Check with `yq eval`
- Missing dates → `teach dates`

### 3. Git Setup

**Checks:**
- Git repository initialized
- Draft branch exists
- Production branch exists (main or production)
- Remote configured (origin)
- Working tree clean

**Fix Actions:**
- Not a repo → `git init`
- Missing branches → `git checkout -b <branch>`
- No remote → `git remote add origin <url>`

### 4. Scholar Integration

**Checks:**
- Claude Code CLI available
- Scholar skills accessible (via `claude --list-skills`)
- Lesson plan file exists (optional)

**Fix Actions:**
- Missing Claude → Install from https://code.claude.com
- Missing Scholar → Install Scholar plugin

### 5. Git Hooks

**Checks:**
- pre-commit hook installed
- pre-push hook installed
- prepare-commit-msg hook installed
- Hook version tracking (flow-cli managed vs custom)

**Fix Actions:**
- Missing hooks → `teach hooks install` (prompts in --fix mode)

### 6. Cache Health

**Checks:**
- `_freeze/` directory exists
- Cache size (du -sh)
- Last render time (find + stat)
- Cache freshness:
  - 0 days: Fresh (today)
  - 1-7 days: Recent
  - 8-30 days: Aging
  - 31+ days: Stale
- Cache file count

**Fix Actions:**
- Stale cache → Prompt to clear (--fix mode)

---

## Implementation Details

### Architecture

```
teach doctor
  ├── Flag parsing (--brief, --fix, --json, --help)
  ├── Header output
  ├── Check runners (6 categories)
  │   ├── _teach_doctor_check_dependencies()
  │   ├── _teach_doctor_check_config()
  │   ├── _teach_doctor_check_git()
  │   ├── _teach_doctor_check_scholar()
  │   ├── _teach_doctor_check_hooks()
  │   └── _teach_doctor_check_cache()
  ├── Result tracking (passed, warnings, failures)
  └── Output formatting (text or JSON)
```

### State Variables

```zsh
local brief=false      # --brief flag
local fix=false        # --fix flag
local json=false       # --json flag
local -i passed=0      # Pass counter
local -i warnings=0    # Warning counter
local -i failures=0    # Failure counter
local -a json_results  # JSON result array
```

### Helper Functions

**Output Helpers:**

```zsh
_teach_doctor_pass "message"              # ✓ green
_teach_doctor_warn "message" "fix hint"   # ⚠ yellow
_teach_doctor_fail "message" "fix hint"   # ✗ red
```

**Interactive Fix:**

```zsh
_teach_doctor_interactive_fix "name" "install_cmd" ["optional"]
```

**Specialized Checks:**

```zsh
_teach_doctor_check_dep "name" "cmd" "fix_cmd" "required"
_teach_doctor_check_r_packages
_teach_doctor_check_quarto_extensions
```

### JSON Result Format

Each check appends to `json_results` array:

```zsh
json_results+=("{\"check\":\"$name\",\"status\":\"$status\",\"message\":\"$msg\"}")
```

**Status values:** `pass`, `warn`, `fail`

### Exit Codes

- `0` - All checks passed (warnings OK)
- `1` - One or more checks failed

---

## Testing

### Test Suite

**File:** `tests/test-teach-doctor-unit.zsh`
**Tests:** 39 total (100% passing)

**Test Suites:**

1. **Helper Functions** (6 tests)
   - Pass/warn/fail counters
   - Output formatting

2. **Dependency Checks** (4 tests)
   - Existing commands detected
   - Missing required commands fail
   - Missing optional commands warn
   - Version detection

3. **R Package Checks** (2 tests)
   - Function exists
   - Common packages checked

4. **Quarto Extension Checks** (3 tests)
   - No extensions directory
   - Empty directory
   - Extensions detected

5. **Git Hook Checks** (4 tests)
   - No hooks installed
   - Managed hooks detected
   - Custom hooks detected

6. **Cache Health Checks** (4 tests)
   - No cache warns
   - Fresh cache passes
   - Old cache detected

7. **Config Validation** (3 tests)
   - Config file detected
   - Missing config fails
   - Invalid YAML detected

8. **Git Setup Checks** (5 tests)
   - Git repo detected
   - Branch detection
   - Remote detection

9. **JSON Output** (5 tests)
   - Summary structure
   - Check array
   - Proper formatting

10. **Interactive Fix Mode** (1 test)
    - Function exists

11. **Flag Handling** (3 tests)
    - Help flag
    - JSON flag
    - Quiet flag

### Running Tests

```bash
# Run all tests
./tests/test-teach-doctor-unit.zsh

# Expected output
Total Tests:   39
Passed:        39
Failed:        0

All tests passed! ✓
```

### Demo Script

```bash
# Interactive demo
./tests/demo-teach-doctor.sh
```

---

## Performance

**Target:** <5 seconds for complete health check

**Optimizations:**
- Parallel checks where possible
- Cached results (no re-checks within same run)
- Fast file system operations
- Minimal external command calls

**Benchmarks:**
- Basic check: ~2-3 seconds
- With R packages: ~3-4 seconds
- With all extensions: ~4-5 seconds

---

## Color Scheme

Uses flow-cli standard colors:

```zsh
✓ Success   - FLOW_COLORS[success]  # Soft green
⚠ Warning   - FLOW_COLORS[warning]  # Warm yellow
✗ Failure   - FLOW_COLORS[error]    # Soft red
→ Action    - FLOW_COLORS[info]     # Calm blue
  Muted     - FLOW_COLORS[muted]    # Gray
```

---

## Future Enhancements

**Planned:**
1. Custom check plugins (user-defined checks)
2. Check profiles (minimal, standard, comprehensive)
3. Auto-fix mode (non-interactive: `--auto-fix`)
4. Remote health check (via API)
5. Historical health tracking
6. Slack/email notifications for CI failures

**Possible:**
- Integration with `teach status` dashboard
- Weekly health check reminders
- Dependency version tracking
- Security vulnerability scanning

---

## Troubleshooting

### Common Issues

**Issue:** `yq` not found but installed

```bash
# Check PATH
which yq

# Reinstall
brew reinstall yq
```

**Issue:** R packages check fails

```bash
# Install R packages manually
R
> install.packages(c("ggplot2", "dplyr", "tidyr", "knitr", "rmarkdown"))
```

**Issue:** Git hooks show as "not installed" but exist

```bash
# Check hook permissions
ls -la .git/hooks/

# Make executable
chmod +x .git/hooks/pre-commit
```

**Issue:** Cache freshness check incorrect

```bash
# Verify _freeze timestamps
find _freeze -type f -exec stat -f "%m %N" {} \; | sort -rn | head
```

### Debug Mode

```bash
# Enable debug output
FLOW_DEBUG=1 teach doctor
```

---

## API Reference

### Main Function

```zsh
_teach_doctor [OPTIONS]
```

**Options:**
- `--brief` - Only show warnings and failures
- `--fix` - Interactive fix mode
- `--json` - JSON output for CI/CD
- `--help`, `-h` - Show help

### Check Functions

```zsh
_teach_doctor_check_dependencies()
_teach_doctor_check_config()
_teach_doctor_check_git()
_teach_doctor_check_scholar()
_teach_doctor_check_hooks()
_teach_doctor_check_cache()
```

### Helper Functions

```zsh
_teach_doctor_pass "message"
_teach_doctor_warn "message" "hint"
_teach_doctor_fail "message" "hint"
_teach_doctor_interactive_fix "name" "cmd" ["optional"]
_teach_doctor_check_dep "name" "cmd" "fix_cmd" "required"
_teach_doctor_check_r_packages()
_teach_doctor_check_quarto_extensions()
_teach_doctor_json_output()
_teach_doctor_help()
```

---

## Change Log

**v4.6.0** (2025-01-20)
- ✅ Complete implementation
- ✅ 6 check categories
- ✅ Interactive --fix mode
- ✅ JSON output for CI/CD
- ✅ 39 unit tests (100% passing)
- ✅ Comprehensive documentation

---

**Last Updated:** 2025-01-20
**Author:** Data-Wise
**Status:** Production Ready ✅
