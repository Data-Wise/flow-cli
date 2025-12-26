# Command Quick Reference (ADHD-Friendly)

> **Pattern:** `command + keyword + options`
> **Philosophy:** One command per domain, discoverable with `help`

---

## Dispatchers

### R Package Development: `r`

```bash
r                   # R console (radian)
r test              # Run tests
r doc               # Document package
r check             # Check package
r build             # Build package
r cycle             # Full cycle: doc → test → check
r quick             # Quick: load → test
r cov               # Coverage report
r cran              # CRAN check
r help              # Show all commands
```

### Git: `g`

```bash
g                   # Status (short)
g status            # Full status
g add .             # Stage all
g commit "msg"      # Commit with message
g push              # Push to remote
g pull              # Pull from remote
g log               # Pretty log (20 lines)
g branch            # List branches
g checkout <b>      # Switch branch
g stash             # Stash changes
g stash pop         # Pop stash
g undo              # Undo last commit (keep changes)
g help              # Show all commands
```

### Quarto Publishing: `qu`

```bash
qu                  # Smart default: render → preview
qu preview          # Live preview
qu render           # Render document
qu pdf              # Render to PDF
qu check            # Check installation
qu clean            # Remove build artifacts
qu new <name>       # Create new project
qu help             # Show all commands
```

### MCP Server Manager: `mcp`

```bash
mcp                 # Show server status
mcp status          # Detailed status
mcp logs <server>   # View server logs
mcp restart <srv>   # Restart server
mcp help            # Show all commands
```

### Obsidian Integration: `obs`

```bash
obs                 # Quick capture note
obs search <term>   # Search notes
obs daily           # Open daily note
obs help            # Show all commands
```

### AI Tools

```bash
ccy                 # Project picker → Claude Code (function in .zshrc)
gem                 # Gemini (see 13 gem* aliases)
gemf                # Gemini Flash
gemp                # Gemini Pro
```

---

## Setup & Diagnostics

### Health Check: `flow doctor`

```bash
flow doctor              # Check all dependencies
flow doctor --fix        # Interactive install missing tools
flow doctor --fix -y     # Auto-install all missing (no prompts)
flow doctor --ai         # AI-assisted troubleshooting (Claude CLI)
flow doctor --help       # Show all options
```

**What it checks:**

- Required: fzf
- Recommended: eza, bat, zoxide, fd, ripgrep
- Optional: dust, duf, btop, delta, gh, jq
- Integrations: atlas, radian
- ZSH plugins: p10k, autosuggestions, syntax-highlighting

**Quick fix all:**

```bash
brew bundle --file=$FLOW_PLUGIN_DIR/setup/Brewfile
```

---

## Workflow Functions

### Session Management

```bash
work <project>      # Start work session
finish [msg]        # End session (commit + push)
here                # Quick context (pwd + status + ls)
```

### Project Operations

```bash
pb                  # Build (auto-detects type)
pv                  # Preview/view
pt                  # Test
pick                # FZF picker
dash                # Master dashboard
```

### Teaching

```bash
tst                 # Teaching status
tweek               # Current week
tlec [N]            # Open lecture N
tpublish            # Deploy to GitHub Pages
```

### Research

```bash
rst                 # Research status
rms                 # Open manuscript
rsim                # Run simulation
```

---

## Utility Aliases

```bash
..                  # cd ..
...                 # cd ../..
ll                  # Long listing (eza)
la                  # All files
reload              # Reload zshrc
```

---

## Pattern Summary

| Domain         | Command       | Pattern                     |
| -------------- | ------------- | --------------------------- |
| R Package      | `r`           | `r <action> [args]`         |
| Git            | `g`           | `g <action> [args]`         |
| Quarto         | `qu`          | `qu <action> [args]`        |
| MCP Servers    | `mcp`         | `mcp <action> [srv]`        |
| Obsidian Notes | `obs`         | `obs <action> [arg]`        |
| Claude         | `ccy`         | Function (no args)          |
| Gemini         | `gem*`        | See aliases in .zshrc       |
| Health Check   | `flow doctor` | `flow doctor [--fix\|--ai]` |

**Get help:** Any dispatcher + `help` (e.g., `r help`, `g help`, `qu help`, `flow doctor --help`)

---

## Files

| File                                                               | Purpose                     |
| ------------------------------------------------------------------ | --------------------------- |
| `~/projects/dev-tools/flow-cli/lib/dispatchers/`                   | All dispatchers             |
| `~/projects/dev-tools/flow-cli/lib/dispatchers/r-dispatcher.zsh`   | r (R package dev)           |
| `~/projects/dev-tools/flow-cli/lib/dispatchers/g-dispatcher.zsh`   | g (git workflows)           |
| `~/projects/dev-tools/flow-cli/lib/dispatchers/qu-dispatcher.zsh`  | qu (Quarto publishing)      |
| `~/projects/dev-tools/flow-cli/lib/dispatchers/mcp-dispatcher.zsh` | mcp (MCP servers)           |
| `~/projects/dev-tools/flow-cli/lib/dispatchers/obs.zsh`            | obs (Obsidian notes)        |
| `~/projects/dev-tools/flow-cli/commands/doctor.zsh`                | flow doctor (health check)  |
| `~/projects/dev-tools/flow-cli/setup/Brewfile`                     | Homebrew bundle             |
| `~/.config/zsh/.zshrc`                                             | ccy function, gem\* aliases |

**Removed:** `v-dispatcher.zsh` (deprecated, use `flow` command instead)

---

_Updated: 2025-12-26_
