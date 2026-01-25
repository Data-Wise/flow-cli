# Command Quick Reference (ADHD-Friendly)

> **Pattern:** `command + keyword + options`
> **Philosophy:** One command per domain, discoverable with `help`
> **Version:** v5.9.0 (2026-01-14)

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
g push              # Push to remote (with workflow guard)
g pull              # Pull from remote
g log               # Pretty log (20 lines)
g branch            # List branches
g checkout <b>      # Switch branch
g stash             # Stash changes
g stash pop         # Pop stash
g undo              # Undo last commit (keep changes)
g help              # Show all commands
```

**Feature Workflow (v4.1.0):**

```bash
g feature start <n> # Create feature/<n> from dev
g feature sync      # Rebase feature onto dev
g feature list      # List feature/hotfix branches
g feature finish    # Push + create PR to dev
g promote           # Create PR: feature → dev
g release           # Create PR: dev → main
```

### Git Worktrees: `wt`

```bash
wt                  # Formatted overview (status icons + sessions) [v5.13.0]
wt flow             # Filter to show only flow-cli worktrees [v5.13.0]
wt list             # Raw git worktree list output
wt create <branch>  # Create worktree for branch
wt move             # Move current branch to worktree
wt remove <path>    # Remove a worktree
wt clean            # Prune stale worktrees
wt help             # Show all commands
pick wt             # Interactive picker with Ctrl-X delete, Ctrl-R refresh [v5.13.0]
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

### Dotfile Management: `dot`

```bash
dot                 # Status overview
dot status          # Show sync status
dot edit FILE       # Edit with preview & apply
dot sync            # Pull from remote
dot push            # Push to remote
dot diff            # Show pending changes
dot apply           # Apply changes
dot unlock          # Unlock Bitwarden vault
dot secret NAME     # Retrieve Keychain secret (v5.5.0)
dot secret add NAME # Store in Keychain (v5.5.0)
dot secret list     # List available secrets
dot secret delete   # Remove from Keychain
dot doctor          # Run diagnostics
dot help            # Show all commands
```

**Quick Workflows:**

```bash
# Edit dotfile
dot edit .zshrc     # Edit → Preview → Apply

# Sync from remote
dot sync            # Pull → Preview → Apply

# Use Keychain secret (v5.5.0 - instant, Touch ID)
TOKEN=$(dot secret api-key)

# Use Bitwarden secret (cross-device)
dot unlock
dot edit .gitconfig
# Add: {{ bitwarden "item" "github-token" }}
```

### Terminal Manager: `tm`

```bash
tm                  # Show terminal info
tm title <text>     # Set tab/window title
tm profile <name>   # Switch iTerm2 profile
tm which            # Show detected terminal
tm ghost            # Ghostty status (via aiterm)
tm switch           # Apply terminal context
tm detect           # Detect project context
tm help             # Show all commands
```

**Aliases:** `tmt` (title), `tmp` (profile), `tmg` (ghost), `tms` (switch)

### Prompt Engine Manager: `prompt` (v5.7.0)

```bash
prompt              # Show help
prompt status       # Show current engine + alternatives
prompt list         # Table view of all engines
prompt toggle       # Interactive menu to pick engine
prompt starship     # Switch to Starship
prompt p10k         # Switch to Powerlevel10k
prompt ohmyposh     # Switch to Oh My Posh
prompt setup-ohmyposh  # Interactive Oh My Posh wizard
prompt help         # Show all commands
```

**Options:**

```bash
prompt --dry-run toggle     # Preview changes without applying
prompt --dry-run starship   # Preview Starship switch
```

**Supported Engines:** Powerlevel10k, Starship, Oh My Posh

### Teaching Workflow: `teach` (v5.4.1+)

```bash
teach init "STAT 545"     # Initialize teaching workflow
teach init -y "STAT 440"  # Non-interactive mode
teach status              # Show project status (validates config)
teach status --verbose    # Show validation details
teach week                # Show current week number
teach config              # Edit teach-config.yml
teach deploy              # Deploy draft → production
teach archive             # Archive semester
teach help                # Show all commands
```

**Scholar Wrappers (v5.8.0):**

```bash
teach exam "Midterm"      # Create exam via Scholar plugin
teach quiz "Topic"        # Create quiz via Scholar plugin
teach slides "Topic"      # Generate slides via Scholar plugin
teach syllabus            # Generate syllabus via Scholar plugin
teach rubric "Name"       # Generate rubric via Scholar plugin
teach feedback "Work"     # Generate feedback via Scholar plugin
teach demo                # Demo teaching workflow
```

**Universal Flags:** `--dry-run`, `--format`, `--output`, `--verbose`

**Config Validation (v5.9.0):**

```bash
# Auto-validates teach-config.yml on:
# - teach status (with summary)
# - teach exam/quiz/etc (before Scholar invocation)

# Validates:
# - Required field: course.name
# - Enum values: semester (Spring|Summer|Fall|Winter)
# - Range: year (2020-2100)
# - Date format: YYYY-MM-DD
# - Grading sum (~100%)

# Hash-based caching - only re-validates when config changes
```

---

## Sync & Data Management (v4.7.0)

### Sync: `flow sync`

```bash
flow sync           # Smart sync (auto-detect what needs syncing)
flow sync all       # Sync everything
flow sync status    # Update .STATUS timestamps
flow sync wins      # Aggregate wins to global file
flow sync goals     # Recalculate goal progress
flow sync git       # Smart git push/pull
flow sync --status  # View sync dashboard
flow sync --dry-run # Preview changes
```

**Remote Sync (v4.7.0):**

```bash
flow sync remote            # Show iCloud sync status
flow sync remote init       # Set up iCloud sync
flow sync remote disable    # Revert to local storage
```

**Synced to iCloud:** wins.md, goal.json, sync-state.json

**Setup:**

1. `flow sync remote init` - Migrates core data
2. Add `source ~/.config/flow/remote.conf` to ~/.zshrc
3. Restart shell - Apple handles sync automatically

---

## AI-Powered Commands (v3.2.0)

### Ask AI: `flow ai`

```bash
flow ai "how do I..."           # Ask anything with project context
flow ai --explain <code>        # Explain code or concepts
flow ai --fix <problem>         # Get fix suggestions
flow ai --suggest <goal>        # Get improvement ideas
flow ai --create <spec>         # Generate code from description
flow ai --context "query"       # Force include project context
flow ai --verbose "query"       # Show context being sent
flow ai --help                  # Show all options
```

### Natural Language: `flow do`

```bash
flow do "show git log"          # Translates to: git log --oneline -20
flow do "find large files"      # Translates to: find . -size +10M
flow do "count lines of code"   # Translates to: find . -name "*.zsh" | xargs wc -l
flow do --dry-run "..."         # Show command without executing
flow do --verbose "..."         # Show AI reasoning
flow do --help                  # Show all options
```

**Safety:** Dangerous commands (rm -rf, etc.) require confirmation.

### ADHD Helpers with AI

```bash
stuck --ai                      # AI help when blocked
stuck --ai "tests failing"      # AI help with specific problem
next --ai                       # AI-powered task suggestion
```

### Claude Code: `cc`

```bash
cc                  # Launch Claude HERE (current dir)
cc pick             # Pick project → Claude
cc <project>        # Direct jump → Claude
cc yolo             # Launch HERE in YOLO mode (skip permissions)
cc yolo pick        # Pick project → YOLO mode
cc plan             # Launch HERE in Plan mode
cc opus             # Launch HERE with Opus model
cc haiku            # Launch HERE with Haiku model
cc resume           # Resume Claude session picker
cc continue         # Resume most recent conversation
cc ask "query"      # Quick question (print mode)
cc file <file>      # Analyze a file
cc diff             # Review git changes
cc help             # Show all commands
```

**Worktree Integration (v4.2.0):**

```bash
cc wt               # List current worktrees
cc wt <branch>      # Launch Claude in worktree (creates if needed)
cc wt pick          # Pick worktree → Claude (fzf)
cc wt yolo <branch> # Worktree + YOLO mode
cc wt plan <branch> # Worktree + Plan mode
cc wt opus <branch> # Worktree + Opus model
```

**Aliases:** `ccy` (yolo), `ccw` (wt), `ccwy` (wt yolo), `ccwp` (wt pick)

### External AI Tools

```bash
gem                 # Gemini (see 13 gem* aliases)
gemf                # Gemini Flash
gemp                # Gemini Pro
```

---

## Setup & Diagnostics

### Health Check: `flow doctor`

```bash
flow doctor              # Check all dependencies + alias health
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
- **Aliases:** shadows, broken targets, health summary (v5.4.0)

### Alias Management: `flow alias` (v5.4.0)

```bash
flow alias doctor           # Health check all aliases (shadows, broken targets)
flow alias find <pattern>   # Search aliases by name or command
flow alias find --exact gst # Exact match only
flow alias edit             # Open .zshrc at alias section
flow alias add name='cmd'   # Create alias (one-liner)
flow alias add              # Create alias (interactive wizard)
flow alias rm <name>        # Remove alias (safe: comments out, backups)
flow alias test <name>      # Show definition + validation
flow alias test <n> --dry   # Show what would execute
flow alias test <n> --exec  # Actually run the alias
flow alias help             # Show all commands
```

**Safety Features:**

- Shadow detection: warns if alias shadows system command
- Target validation: checks if target command exists
- Safe removal: comments out instead of deleting, creates backup
- Duplicate checking: prevents overwriting existing aliases

**Quick fix all:**

```bash
brew bundle --file=$FLOW_PLUGIN_DIR/setup/Brewfile
```

### Install Tools: `flow install`

```bash
flow install                        # Interactive installer
flow install --profile minimal      # Essential: fzf, zoxide, bat
flow install --profile developer    # Full dev: + fd, rg, gh, delta, jq
flow install --profile researcher   # Academic: + quarto
flow install --profile writer       # Publishing: + pandoc, quarto
flow install --profile full         # Everything
flow install --category core        # Just core tools
flow install --dry-run              # Show what would install
flow install --list                 # List all profiles
flow install --help                 # Show all options
```

**Profiles:**

| Profile    | Tools                              |
| ---------- | ---------------------------------- |
| minimal    | fzf, zoxide, bat                   |
| developer  | + eza, fd, rg, gh, delta, jq       |
| researcher | + quarto                           |
| writer     | + pandoc, quarto                   |
| full       | All of the above + dust, duf, btop |

### Upgrade: `flow upgrade`

```bash
flow upgrade self               # Update flow-cli via git pull
flow upgrade tools              # Update Homebrew packages
flow upgrade plugins            # Update ZSH plugins (antidote)
flow upgrade all                # Update everything
flow upgrade --check            # Check for updates (no install)
flow upgrade --changelog        # Show what's new
flow upgrade --force            # Skip confirmations
flow upgrade --help             # Show all options
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
dash                # Master dashboard
dash -i             # Interactive TUI
dash --watch        # Live refresh
```

### Pick - Project Picker (v4.6.0)

```bash
pick                # FZF picker (all projects)
pick r              # R packages only
pick dev            # Dev tools only
pick wt             # All worktrees (new!)
pick wt scribe      # Scribe's worktrees only
pick flow           # Direct jump to flow-cli
```

**Categories:** `r`, `dev`, `q`, `teach`, `rs`, `app`, `wt`

**Interactive Keys:**

| Key | Action |
|-----|--------|
| Enter | cd to selection |
| Ctrl-O | cd + launch Claude (`cc` mode) |
| Ctrl-Y | cd + launch Claude YOLO (`ccy` mode) |
| Ctrl-S | View .STATUS file |
| Ctrl-L | View git log |
| Space | Force full picker (bypass resume) |

**Worktree Session Indicators:**
- 🟢 Xh/m - Recent Claude session (< 24h)
- 🟡 old - Older Claude session
- (none) - No session

**Aliases:** `pickr`, `pickdev`, `pickq`, `pickwt`

### Dopamine Features (v3.5.0)

```bash
win "text"          # Log accomplishment (auto-categorized)
win --category fix  # Log with explicit category
yay                 # Show recent wins
yay --week          # Weekly summary + graph
flow goal           # Show daily goal progress
flow goal set 3     # Set daily win target
```

**Categories:** 💻 code, 📝 docs, 👀 review, 🚀 ship, 🔧 fix, 🧪 test, ✨ other

### Capture & Breadcrumbs

```bash
catch "idea"        # Quick capture
inbox               # View captured items
crumb "note"        # Leave breadcrumb
trail               # Show breadcrumb trail
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

| Domain         | Command        | Pattern                        |
| -------------- | -------------- | ------------------------------ |
| R Package      | `r`            | `r <action> [args]`            |
| Git            | `g`            | `g <action> [args]`            |
| Git Worktrees  | `wt`           | `wt <action> [branch]`         |
| Quarto         | `qu`           | `qu <action> [args]`           |
| MCP Servers    | `mcp`          | `mcp <action> [srv]`           |
| Obsidian Notes | `obs`          | `obs <action> [arg]`           |
| Terminal       | `tm`           | `tm <action> [arg]`            |
| Prompt (v5.7)  | `prompt`       | `prompt <action> [engine]`     |
| Teaching (v5.9)| `teach`        | `teach <action> [args]`        |
| Sync (v4.7.0)  | `flow sync`    | `flow sync [target] [opts]`    |
| AI Assistant   | `flow ai`      | `flow ai [--mode] "query"`     |
| Natural Lang   | `flow do`      | `flow do "command in English"` |
| Health Check   | `flow doctor`  | `flow doctor [--fix\|--ai]`    |
| Alias Mgmt     | `flow alias`   | `flow alias <action> [arg]`    |
| Install        | `flow install` | `flow install [--profile p]`   |
| Upgrade        | `flow upgrade` | `flow upgrade [target]`        |
| Wins (v3.5.0)  | `win`          | `win [--category] "text"`      |
| Goals (v3.5.0) | `flow goal`    | `flow goal [set N]`            |
| Claude         | `cc`           | `cc [mode] [project]`          |
| Gemini         | `gem*`         | See aliases in .zshrc          |

**Get help:** Any command + `help` or `--help` (e.g., `r help`, `flow ai --help`)

---

## Files

| File                                                                | Purpose                      |
| ------------------------------------------------------------------- | ---------------------------- |
| `~/projects/dev-tools/flow-cli/lib/dispatchers/`                    | All dispatchers              |
| `~/projects/dev-tools/flow-cli/lib/dispatchers/r-dispatcher.zsh`    | r (R package dev)            |
| `~/projects/dev-tools/flow-cli/lib/dispatchers/g-dispatcher.zsh`    | g (git workflows)            |
| `~/projects/dev-tools/flow-cli/lib/dispatchers/qu-dispatcher.zsh`   | qu (Quarto publishing)       |
| `~/projects/dev-tools/flow-cli/lib/dispatchers/mcp-dispatcher.zsh`  | mcp (MCP servers)            |
| `~/projects/dev-tools/flow-cli/lib/dispatchers/obs.zsh`             | obs (Obsidian notes)         |
| `~/projects/dev-tools/flow-cli/lib/dispatchers/prompt-dispatcher.zsh` | prompt (engines, v5.7.0)   |
| `~/projects/dev-tools/flow-cli/lib/dispatchers/teach-dispatcher.zsh` | teach (teaching, v5.4.1)    |
| `~/projects/dev-tools/flow-cli/lib/config-validator.zsh`            | Config validation (v5.9.0)   |
| `~/projects/dev-tools/flow-cli/commands/ai.zsh`                     | flow ai, flow do (v3.2.0)    |
| `~/projects/dev-tools/flow-cli/commands/install.zsh`                | flow install (v3.2.0)        |
| `~/projects/dev-tools/flow-cli/commands/upgrade.zsh`                | flow upgrade (v3.2.0)        |
| `~/projects/dev-tools/flow-cli/commands/doctor.zsh`                 | flow doctor (health check)   |
| `~/projects/dev-tools/flow-cli/commands/alias.zsh`                  | flow alias (v5.4.0)          |
| `~/projects/dev-tools/flow-cli/setup/Brewfile`                      | Homebrew bundle              |
| `~/.config/zsh/.zshrc`                                              | ccy function, gem\* aliases  |

**Removed:** `v-dispatcher.zsh` (deprecated, use `flow` command instead)

---

*Updated: 2026-01-14 (v5.9.0)*
