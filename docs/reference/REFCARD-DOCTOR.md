# Health Check Quick Reference Card

> Quick reference for `teach doctor` and `flow doctor` commands (v6.5.0+)

## Commands

| Command | Description |
|---------|-------------|
| `teach doctor` | Quick teaching environment check (< 3s) |
| `teach doctor --full` | Full comprehensive check (all categories) |
| `teach doctor --fix` | Auto-fix issues (implies --full) |
| `flow doctor` | Check flow-cli environment health |
| `flow doctor --dot` | Check only DOT tokens (isolated, fast) |

## teach doctor Quick Examples

```bash
# Quick check: deps, R, config, git (< 3s)
teach doctor

# Full check: all categories including packages, macros, hooks
teach doctor --full

# Auto-fix issues (interactive)
teach doctor --fix

# Warnings/failures only
teach doctor --brief

# Individual R package listing + full macro list
teach doctor --verbose

# Machine-readable output for CI/CD
teach doctor --ci
teach doctor --json

# Combine flags
teach doctor --full --verbose
```

## teach doctor Options

| Flag | Description |
|------|-------------|
| `--full` | Full comprehensive check (all 10 categories) |
| `--brief` | Show only warnings and failures |
| `--fix` | Interactive fix mode (implies --full) |
| `--verbose` | Detailed output: per-package R, full macro list (implies --full) |
| `--json` | Machine-readable JSON output |
| `--ci` | CI mode: no color, exit 1 on failure |
| `--help` | Show help |

## teach doctor Two-Mode Architecture

### Quick Mode (default, < 3s)

| Category | Checks |
|----------|--------|
| Dependencies | yq, git, quarto, gh, examark, claude |
| R Environment | R version, renv status, package count |
| Config | .flow/teach-config.yml, schema, course, semester, dates |
| Git Setup | repo, branches, remote, working tree |

### Full Mode (--full)

All quick mode checks plus:

| Category | Checks |
|----------|--------|
| R Packages | Per-package install verification (batch check) |
| Quarto Extensions | Extension count and listing |
| Scholar Integration | Claude Code, Scholar plugin, lesson plans |
| Git Hooks | pre-commit, pre-push, prepare-commit-msg |
| Cache Health | Freeze cache size, freshness, file count |
| LaTeX Macros | Sources, registry sync, CLAUDE.md docs, unused (opt-in) |
| Teaching Style | Style config, approach, overrides, legacy shim |

## Health Indicator

After each run, teach doctor writes `.flow/doctor-status.json`. The health dot shows on `teach` startup:

| Dot | Status | Meaning |
|-----|--------|---------|
| Green | All passed | No warnings or failures |
| Yellow | Warnings | Non-blocking issues found |
| Red | Failures | Critical issues need fixing |

## flow doctor Check Categories

### 1. Shell & Core

- `zsh` - Shell
- `git` - Version control

### 2. Required Tools

- `fzf` - Fuzzy finder

### 3. Recommended Tools

- `eza` - Enhanced ls
- `bat` - Enhanced cat
- `zoxide` - Smart cd
- `fd` - Enhanced find
- `rg` (ripgrep) - Enhanced grep

### 4. Optional Tools

- `dust` - Disk usage
- `duf` - Disk free
- `btop` - System monitor
- `delta` - Git diff viewer
- `gh` - GitHub CLI
- `jq` - JSON processor

### 5. Integrations

- `atlas` - State management
- `radian` - R console (if R exists)

### 6. ZSH Plugin Manager

Checks:
- antidote/zinit/oh-my-zsh installed
- Plugin bundle file

### 7. ZSH Plugins

- powerlevel10k
- zsh-autosuggestions
- zsh-syntax-highlighting
- zsh-completions

### 8. flow-cli Status

- Plugin loaded
- Version
- Atlas connection

### 9. GitHub Token

- Token configured
- Token validity
- Token expiration
- Token-dependent services (gh CLI, Claude MCP)

### 10. Aliases

- Total alias count
- Shadow detection
- Broken target detection

## Fix Mode Categories

Interactive menu when running `--fix`:

```
╭─ Select Category to Fix ────────────────────────╮
│                                                  │
│  1. 🔑 GitHub Token (1 issue, ~30s)              │
│  2. 📦 Missing Tools (3 tools, ~1m 30s)          │
│  3. ⚡ Aliases (2 issues, ~10s)                  │
│                                                  │
│  4. ✨ Fix All Categories (~2m 10s)              │
│                                                  │
│  0. Exit without fixing                          │
│                                                  │
╰──────────────────────────────────────────────────╯
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All checks passed OR no issues found |
| 1 | Failures detected OR user cancelled |

## teach doctor JSON Output Format

```json
{
  "version": 1,
  "mode": "quick",
  "summary": {
    "passed": 12,
    "warnings": 3,
    "failures": 0,
    "status": "yellow"
  },
  "checks": [
    {
      "check": "dep_yq",
      "status": "pass",
      "message": "4.52.2"
    },
    {
      "check": "config_valid",
      "status": "warn",
      "message": "invalid"
    }
  ]
}
```

## Token Checks (--dot)

Isolated token validation (< 3s):

```bash
# All DOT tokens
flow doctor --dot

# Specific token
flow doctor --dot=github
```

Output:
```
🔑 DOT TOKENS
  ✓ Valid (@username)
  ⚠  Expiring in 7 days
```

## teach doctor Performance

| Operation | Time |
|-----------|------|
| Quick check (default) | < 1 second |
| Full check (--full) | 3-5 seconds |
| Full + verbose | 3-5 seconds |
| Fix mode | Varies by issues |

## STAT-101 Demo Example

```bash
# Navigate to demo course
cd tests/fixtures/demo-course

# Quick check (deps, R, config, git)
teach doctor

# Full check (all 10 categories)
teach doctor --full

# Auto-fix issues
teach doctor --fix

# CI pipeline
teach doctor --ci --full
```

## Common Workflows

```bash
# First-time setup
teach doctor --fix

# Quick pre-commit check
teach doctor --brief

# Full audit before deploy
teach doctor --full

# CI/CD pipeline
teach doctor --ci --full || exit 1

# JSON for automation
teach doctor --json --full | jq '.summary.status'

# Detailed debugging
teach doctor --verbose
```

## flow doctor Options

| Flag | Short | Description |
|------|-------|-------------|
| `--fix` | `-f` | Interactive install missing tools |
| `--fix-token` | - | Fix only token issues (< 60s) |
| `--dot` | - | Check only DOT tokens (isolated check) |
| `--quiet` | `-q` | Minimal output (errors only) |
| `--verbose` | `-v` | Detailed output + cache status |
| `--json` | - | Machine-readable JSON output |
| `--help` | `-h` | Show help |

## Integration

| Tool | How It Uses Doctor |
|------|---------------------|
| `teach init` | Validates dependencies before setup |
| `teach deploy` | Pre-deployment health check |
| `teach` startup | Shows health dot (green/yellow/red) |
| `g push/pull` | Validates token before remote ops |
| `work` | Checks token on session start |

## See Also

- [Dispatcher Guide: teach doctor](MASTER-DISPATCHER-GUIDE.md) — Full command reference
- [Doctor Command](../commands/doctor.md) — Doctor workflow
- [Token Management Guide](../guides/DOCTOR-TOKEN-USER-GUIDE.md) — Token automation details
- [API Reference](MASTER-API-REFERENCE.md) — Function signatures

---

**Version:** v6.5.0
**Last Updated:** 2026-02-08
