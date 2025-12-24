# Pick Command Reference

Interactive project picker with fuzzy search

**Location:** `~/.config/zsh/functions/adhd-helpers.zsh:1875-2050`

---

## Quick Start

```bash
pick --help       # Show built-in help
pick              # Show all projects
pick r            # Show only R packages
pick dev          # Show only dev tools
pick qu           # Show only Quarto projects
pick --fast       # Skip git status (faster)
```

---

## Usage

```bash
pick [--fast] [category]
```

### Arguments

| Argument   | Description                             |
| ---------- | --------------------------------------- |
| `category` | Optional project category filter        |
| `--fast`   | Skip git status checks (faster loading) |

### Categories

All category names are case-insensitive and support multiple aliases:

| Category  | Aliases                              | Description       |
| --------- | ------------------------------------ | ----------------- |
| **r**     | `r`, `R`, `rpack`, `rpkg`            | R packages        |
| **dev**   | `dev`, `Dev`, `DEV`, `tool`, `tools` | Development tools |
| **q**     | `q`, `Q`, `qu`, `quarto`             | Quarto projects   |
| **teach** | `teach`, `teaching`                  | Teaching courses  |
| **rs**    | `rs`, `research`, `res`              | Research projects |
| **app**   | `app`, `apps`                        | Applications      |

---

## Interactive Keys

| Key        | Action | Description                          |
| ---------- | ------ | ------------------------------------ |
| **Enter**  | cd     | Change to selected project directory |
| **Ctrl-W** | work   | cd + start work session              |
| **Ctrl-O** | code   | cd + open in VS Code                 |
| **Ctrl-S** | status | View .STATUS file (with bat/cat)     |
| **Ctrl-L** | log    | View git log (with tig/git)          |
| **Ctrl-C** | cancel | Exit without action                  |

---

## Display Format

```text
project-name         icon type
────────────────────────────────
flow-cli    🔧 dev
mediationverse       📦 r
medrobust            📦 r
apple-notes-sync     🔧 dev
```

**Note:** Git status display was removed for simplicity and reliability. A `--git` flag may be added in future versions to optionally show branch and status information.

### Icons by Category

- 📦 - R packages (`r`)
- 🔧 - Dev tools (`dev`)
- 📝 - Quarto projects (`q`)
- 📚 - Teaching courses (`teach`)
- 🔬 - Research projects (`rs`)
- 📱 - Applications (`app`)

---

## Examples

### Basic Usage

```bash
# Pick from all projects
pick

# Pick from R packages only
pick r

# Pick from dev tools (case-insensitive)
pick DEV

# Fast mode (no git status)
pick --fast

# Fast mode with filter
pick --fast r
```

### Interactive Actions

```bash
# After selecting a project:
#   - Press Enter to cd
#   - Press Ctrl-W to start work session
#   - Press Ctrl-O to open in VS Code
#   - Press Ctrl-S to view .STATUS file
#   - Press Ctrl-L to view git log
```

---

## Aliases

Shortcuts available for common categories:

```bash
pickr             # Expands to: pick r
pickdev           # Expands to: pick dev
pickq             # Expands to: pick q
```

---

## Features

### ADHD-Friendly Design

- **Color-coded status** - Pre-attentive processing (see status before reading)
- **Forgiving input** - Multiple aliases, case-insensitive
- **Visual hierarchy** - Icons, colors, clear sections
- **Fast mode** - Skip git checks when you need speed
- **Dynamic headers** - Always know what you're filtering

### Technical Features

- Process substitution (no subshell pollution)
- Branch name truncation (20 chars max)
- ANSI color support with fzf `--ansi` flag
- Comprehensive error handling
- Git status caching potential

---

## Integration

Works with:

- `work` command - Start work session in selected project
- VS Code - Open project with `code .`
- `bat` - Syntax-highlighted .STATUS viewing
- `tig` - Interactive git log browser

---

## Files

| File                                                 | Purpose                                     |
| ---------------------------------------------------- | ------------------------------------------- |
| `PROPOSAL-PICK-COMMAND-ENHANCEMENT.md`               | Technical proposal & implementation details |
| `QUICK-WINS-IMPLEMENTED.md`                          | Quick enhancements documentation            |
| `docs/planning/proposals/PICK-COMMAND-NEXT-PHASE.md` | Future enhancement roadmap (P6A-P6F)        |

---

## Next Phase Enhancements

See [PICK-COMMAND-NEXT-PHASE.md](../planning/proposals/PICK-COMMAND-NEXT-PHASE.md) for planned features:

- **P6A:** Preview pane showing .STATUS, README, git info
- **P6B:** Frecency sorting (frequency + recency)
- **P6C:** Multi-select batch operations
- **P6D:** Advanced actions (PR creation, deployment)
- **P6E:** Smart filters (by git status, .STATUS progress)
- **P6F:** Performance optimization (parallel git, caching)

---

## Troubleshooting

### Colors not showing?

Make sure your terminal supports ANSI colors and fzf has the `--ansi` flag.

### Parse error at line 49?

Reload the function:

```bash
source ~/.config/zsh/functions/adhd-helpers.zsh
```

### Formatting broken?

Check that ANSI escape codes use **double quotes** in printf:

```zsh
# Correct:
printf "\033[32m✅\033[0m"

# Incorrect:
printf '\033[32m✅\033[0m'  # Single quotes don't interpret escapes
```

---

**Last Updated:** 2025-12-18
**Status:** ✅ Fully implemented and tested
