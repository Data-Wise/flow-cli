# flow install

> Profile-based tool installation

## Synopsis

```bash
flow install [options]
flow install --profile <name>
flow install --category <name>
flow install <tool> [tool...]
```

## Description

`flow install` provides a convenient way to install recommended CLI tools using Homebrew. It supports profile-based installation for different workflows and category-based installation for specific tool groups.

## Options

| Option                  | Description                            |
| ----------------------- | -------------------------------------- |
| `-p, --profile <name>`  | Install tools from a profile           |
| `-c, --category <name>` | Install tools from a category          |
| `-n, --dry-run`         | Show what would be installed           |
| `-f, --force`           | Reinstall even if present              |
| `-l, --list`            | List available profiles and categories |
| `-h, --help`            | Show help message                      |

## Profiles

| Profile      | Tools                        | Use Case               |
| ------------ | ---------------------------- | ---------------------- |
| `minimal`    | fzf, zoxide, bat             | Essential tools only   |
| `developer`  | + eza, fd, rg, gh, delta, jq | Full development setup |
| `researcher` | + quarto                     | Academic writing       |
| `writer`     | + pandoc, quarto             | Publishing workflows   |
| `full`       | + dust, duf, btop            | Everything             |

### Profile Details

**minimal** (3 tools)

```
fzf      - Fuzzy finder (required for pick, dash-tui)
zoxide   - Smart cd replacement
bat      - Cat with syntax highlighting
```

**developer** (9 tools)

```
+ eza    - Modern ls replacement
+ fd     - Fast file finder
+ rg     - Ripgrep (fast grep)
+ gh     - GitHub CLI
+ delta  - Git diff viewer
+ jq     - JSON processor
```

**researcher** (10 tools)

```
+ quarto - Scientific publishing
```

**writer** (5 tools)

```
fzf, bat, pandoc, quarto
```

**full** (13 tools)

```
+ dust   - Disk usage analyzer
+ duf    - Disk free viewer
+ btop   - System monitor
```

## Categories

| Category       | Tools          |
| -------------- | -------------- |
| `core`         | fzf, bat, eza  |
| `productivity` | zoxide, fzf    |
| `git`          | gh, delta      |
| `dev`          | fd, rg, jq     |
| `research`     | quarto, pandoc |

## Examples

### Interactive Installation

```bash
flow install
```

Launches an interactive menu to select tools.

### Profile-Based

```bash
# Essential tools only
flow install --profile minimal

# Full developer setup
flow install --profile developer

# Academic workflow
flow install --profile researcher
```

### Category-Based

```bash
# Just git tools
flow install --category git

# Core productivity tools
flow install --category core
```

### Individual Tools

```bash
# Install specific tools
flow install fzf bat eza
```

### Dry Run

```bash
# See what would be installed
flow install --profile developer --dry-run
```

Output:

```
🔍 DRY RUN - Would install:
  • fzf
  • zoxide
  • bat
  • eza
  • fd
  • rg (ripgrep)
  • gh
  • delta (git-delta)
  • jq

Total: 9 tools
```

### List Available Options

```bash
flow install --list
```

## Requirements

- Homebrew must be installed
- macOS or Linux with Linuxbrew

## Related Commands

- [`flow doctor`](doctor.md) - Check which tools are installed
- [`flow upgrade`](upgrade.md) - Update installed tools

## See Also

- [Installation Guide](../getting-started/installation.md)
- [Brewfile](https://github.com/data-wise/flow-cli/blob/main/setup/Brewfile)

---

**Last Updated:** 2026-01-07
**Command Version:** v4.8.0 (install v3.2.0)
**Status:** ✅ Production ready with profile-based installation
