# Health Check Quick Reference Card

> Quick reference for `teach doctor` and `flow doctor` commands (v5.14.0+)

## Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `teach doctor` | - | Check teaching environment health |
| `flow doctor` | `doctor` | Check flow-cli environment health |
| `flow doctor --dot` | - | Check only DOT tokens (isolated, fast) |
| `flow doctor --fix` | - | Interactive install missing tools |
| `flow doctor --fix-token` | - | Fix only token issues |

## Quick Examples

```bash
# Full health check
teach doctor
flow doctor

# Check only tokens (< 3s)
flow doctor --dot

# Check specific token
flow doctor --dot=github

# Interactive fix
flow doctor --fix

# Auto-install all
flow doctor --fix -y

# Fix only token issues
flow doctor --fix-token

# Minimal output
flow doctor --quiet

# Detailed output
flow doctor --verbose

# JSON output
flow doctor --json
```

## Options

| Flag | Short | Description |
|------|-------|-------------|
| `--fix` | `-f` | Interactive install missing tools |
| `--fix-token` | - | Fix only token issues (< 60s) |
| `--yes` | `-y` | Skip confirmations (use with --fix) |
| `--quiet` | `-q` | Minimal output (errors only) |
| `--verbose` | `-v` | Detailed output + cache status |
| `--dot` | - | Check only DOT tokens (isolated check) |
| `--dot=TOKEN` | - | Check specific token (e.g., github) |
| `--json` | - | Machine-readable JSON output |
| `--ai` | `-a` | AI-assisted troubleshooting (Claude CLI) |
| `--update-docs` | `-u` | Regenerate help files and docs |
| `--help` | `-h` | Show help |

## teach doctor Check Categories

### 1. Dependencies

Required:
- `yq` - YAML processing
- `git` - Version control
- `quarto` - Document rendering
- `gh` - GitHub CLI

Optional:
- `examark` - Exam generation
- `claude` - Claude Code integration

### 2. Project Configuration

Checks:
- `.flow/teach-config.yml` exists
- Config validates against schema
- Course name configured
- Semester configured
- Dates configured

### 3. Git Setup

Checks:
- Git repository initialized
- Draft branch exists
- Production branch exists (main/production)
- Remote configured
- Working tree status

### 4. Scholar Integration

Checks:
- Claude Code available
- Scholar skills accessible
- Lesson plan file (optional)

### 5. Git Hooks

Checks:
- pre-commit hook
- pre-push hook
- prepare-commit-msg hook

### 6. Cache Health

Checks:
- Freeze cache exists
- Cache freshness (age in days)
- Cache file count

### 7. LaTeX Macros

Checks:
- Macro source files exist
- Config cache up to date
- CLAUDE.md has macro documentation
- Macro usage (unused macros warning)

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

## JSON Output Format

```json
{
  "summary": {
    "passed": 12,
    "warnings": 3,
    "failures": 1,
    "status": "unhealthy"
  },
  "checks": [
    {
      "check": "dep_fzf",
      "status": "pass",
      "message": "4.0.0"
    },
    {
      "check": "github_token",
      "status": "warn",
      "message": "expiring in 5 days"
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

## Performance

| Operation | Time |
|-----------|------|
| Full check | ~2-5 seconds |
| Token check (--dot) | < 3 seconds |
| Token check (cached) | < 100ms |
| Fix all | Varies by tools |

## Cache Behavior

Token checks use 5-minute cache:

```bash
# First call: validates via API (~2s)
flow doctor --dot

# Subsequent calls: uses cache (<100ms)
flow doctor --dot

# Show cache status
flow doctor --dot --verbose
```

Cache hit rate: ~85%

## STAT-101 Demo Example

```bash
# Navigate to demo course
cd tests/fixtures/demo-course

# Full teaching environment check
teach doctor

# Install missing tools
teach doctor --fix

# Validate configuration
teach doctor --quiet
```

## Common Workflows

```bash
# First-time setup
flow doctor --fix
teach doctor --fix

# Pre-commit check
teach doctor --quiet

# Token rotation
flow doctor --fix-token

# Quick status
flow doctor --dot
```

## Integration

| Tool | How It Uses Doctor |
|------|---------------------|
| `teach init` | Validates dependencies before setup |
| `teach deploy` | Pre-deployment health check |
| `g push/pull` | Validates token before remote ops |
| `work` | Checks token on session start |
| `finish` | Validates before push |

## See Also

- [Dispatcher Guide: teach doctor](MASTER-DISPATCHER-GUIDE.md) — Full command reference
- [Doctor Command](../commands/doctor.md) — Doctor workflow
- [Token Management Guide](../guides/DOCTOR-TOKEN-USER-GUIDE.md) — Token automation details
- [API Reference](MASTER-API-REFERENCE.md) — Function signatures

---

**Version:** v5.14.0
**Last Updated:** 2026-02-02
