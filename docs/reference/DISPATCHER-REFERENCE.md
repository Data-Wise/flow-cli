# Dispatcher Reference - flow-cli

**Last Updated:** January 14, 2026
**Version:** flow-cli v5.8.0

---

## Overview

Dispatchers are smart command routers that provide context-aware workflows for specific tools. Each dispatcher provides a unified interface with smart defaults and common subcommands.

**Location:** `~/projects/dev-tools/flow-cli/lib/dispatchers/`

---

## Active Dispatchers (11)

### 1. `g` - Git Workflows

**File:** `g-dispatcher.zsh`
**Purpose:** Smart Git command shortcuts with feature branch workflow
**Updated:** December 29, 2025 (v4.1.0)

**Common Commands:**

```bash
g status          # Git status
g commit "msg"    # Git commit with message
g push            # Git push (with workflow guard)
g pull            # Git pull
g log             # Git log
g help            # Show help
```

**Feature Branch Workflow (v4.1.0+):**

```bash
# Feature development
g feature start <name>   # Create feature/<name> from dev
g feature sync           # Rebase feature onto dev
g feature list           # List feature/hotfix branches
g feature finish         # Push + create PR to dev

# Promotion flow
g promote                # Create PR: feature → dev
g release                # Create PR: dev → main

# Status & cleanup (v4.2.0+)
g feature status             # Show merged vs active branches
g feature prune              # Delete merged feature branches
g feature prune --all        # Also delete remote branches
g feature prune -n           # Dry run (preview only)
g feature prune --force      # Skip confirmation (v4.3.0)
g feature prune --older-than 30d  # Only branches older than 30 days (v4.3.0)
```

**Workflow Guard:**

- Blocks direct push to `main` and `dev` branches
- Shows helpful message with correct workflow
- Override with `GIT_WORKFLOW_SKIP=1 g push`

**Workflow Diagram:**

```
feature/* ──► dev ──► main
     └── g promote    └── g release
```

**Branch Cleanup (v4.2.0):**

The `g feature prune` command safely cleans up merged branches:
- Only deletes branches merged to dev (or main)
- Never deletes: main, master, dev, develop
- Never deletes current branch
- Only targets: feature/\*, bugfix/\*, hotfix/\*

**Features:**

- Smart defaults for common operations
- ADHD-friendly quick commands
- Feature branch workflow enforcement
- Workflow guards for protected branches
- Context-aware suggestions
- Safe branch cleanup with prune

**See also:** [G-DISPATCHER-REFERENCE.md](G-DISPATCHER-REFERENCE.md)

---

### 2. `mcp` - MCP Server Management

**File:** `mcp-dispatcher.zsh`  
**Purpose:** MCP (Model Context Protocol) server management

**Common Commands:**

```bash
mcp list          # List all MCP servers
mcp cd <server>   # Change to server directory
mcp test <server> # Test server
mcp status        # Show server status
mcp pick          # Interactive picker
mcp help          # Show help
```

**Features:**

- List and navigate MCP servers
- Quick access to server directories
- Test and validate servers
- Interactive selection

**See also:** [MCP-DISPATCHER-REFERENCE.md](MCP-DISPATCHER-REFERENCE.md)

---

### 3. `obs` - Obsidian Integration

**File:** `obs.zsh`  
**Purpose:** Obsidian vault management and integration

**Common Commands:**

```bash
obs help          # Show help
obs discover      # Discover Obsidian vaults
obs vaults        # List all vaults
obs stats         # Show vault statistics
obs ai            # AI integration
obs analyze       # Analyze vault
```

**Features:**

- Discover and list vaults
- Vault statistics
- Integration with AI tools
- Vault analysis

**See also:** [OBS-DISPATCHER-REFERENCE.md](OBS-DISPATCHER-REFERENCE.md)

---

### 4. `prompt` - Prompt Engine Manager

**File:** `prompt-dispatcher.zsh`
**Purpose:** Unified management of prompt themes (Powerlevel10k, Starship, Oh My Posh)
**Added:** January 14, 2026 (v5.7.0)

**Common Commands:**

```bash
# Status & info
prompt                    # Show help (default)
prompt status             # Show current engine + alternatives
prompt list               # Table view of all engines

# Engine switching
prompt toggle             # Interactive menu to pick engine
prompt starship           # Switch to Starship
prompt p10k               # Switch to Powerlevel10k
prompt ohmyposh           # Switch to Oh My Posh

# Setup & configuration
prompt setup-ohmyposh     # Interactive Oh My Posh wizard
prompt help               # Show help

# Options
prompt --dry-run toggle   # Preview changes without applying
```

**Supported Engines:**

| Engine | Config Path | Description |
|--------|-------------|-------------|
| Powerlevel10k | `~/.config/zsh/.p10k.zsh` | Feature-rich, highly customizable |
| Starship | `~/.config/starship.toml` | Minimal, fast Rust-based |
| Oh My Posh | `~/.config/ohmyposh/config.json` | Modular with extensive themes |

**Environment Variable:**

```bash
# Control which engine is active
export FLOW_PROMPT_ENGINE="starship"  # Valid: powerlevel10k, starship, ohmyposh
```

**Features:**

- One-command engine switching with validation
- Interactive toggle menu for quick switching
- Dry-run mode to preview changes
- Automatic shell reload after switch
- Setup wizard for Oh My Posh
- Integration with `flow doctor` for health checks

**See also:** [PROMPT-DISPATCHER-REFERENCE.md](PROMPT-DISPATCHER-REFERENCE.md)

---

### 5. `qu` - Quarto Publishing

**File:** `qu-dispatcher.zsh`  
**Purpose:** Quarto document and presentation workflows  
**Restored:** December 25, 2025

**Common Commands:**

```bash
# Smart defaults
qu                # Render → preview → open browser

# Core commands
qu preview        # Live preview with browser
qu render         # Render document/project
qu check          # Check Quarto installation
qu clean          # Remove output files
qu publish        # Publish to web

# Format-specific
qu pdf            # Render to PDF
qu html           # Render to HTML
qu docx           # Render to Word

# Project creation
qu new <name>     # Create new project
qu article <name> # Create article project
qu present <name> # Create presentation project

# Workflow
qu commit         # Render and commit changes
```

**Smart Default Workflow:**

1. Renders current Quarto document
2. Starts preview server (--no-browser)
3. Auto-opens browser at http://localhost:4200
4. Skips preview if render fails

**Features:**

- One-command render and preview
- Format-specific rendering (PDF, HTML, DOCX)
- Project scaffolding
- Integrated commit workflow

**See also:** [QU-DISPATCHER-REFERENCE.md](QU-DISPATCHER-REFERENCE.md)

---

### 6. `r` - R Package Development

**File:** `r-dispatcher.zsh`  
**Purpose:** R package development workflows  
**Restored:** December 25, 2025

**Common Commands:**

```bash
# Console
r                 # Launch R console (radian/R)

# Core workflow
r load            # devtools::load_all()
r test            # devtools::test()
r doc             # devtools::document()
r check           # devtools::check()
r build           # devtools::build()
r install         # devtools::install()

# Combined workflows
r cycle           # doc → test → check (full cycle)
r quick           # load → test (quick iteration)

# Quality checks
r cov             # covr::package_coverage()
r spell           # spelling::spell_check_package()

# Documentation
r pkgdown         # pkgdown::build_site()
r preview         # pkgdown::preview_site()

# CRAN checks
r cran            # check --as-cran
r fast            # Fast check (skip examples/tests/vignettes)
r win             # check_win_devel()

# Version bumps
r patch           # Bump patch version (0.0.X)
r minor           # Bump minor version (0.X.0)
r major           # Bump major version (X.0.0)

# Cleanup
r clean           # Remove .Rhistory, .RData
r deep            # Deep clean (man/, NAMESPACE, docs/)
r tex             # Remove LaTeX build files

# Workflow
r commit          # Document, test, and commit
r info            # Package info summary
r tree            # Package structure tree
```

**Features:**

- Full R package development cycle
- Combined workflows for efficiency
- CRAN-ready checks
- Automated version bumping
- Multiple cleanup levels
- Integrated documentation

**See also:** [R-DISPATCHER-REFERENCE.md](R-DISPATCHER-REFERENCE.md)

---

### 7. `cc` - Claude Code Workflows

**File:** `cc-dispatcher.zsh`
**Purpose:** Smart Claude Code project workflows
**Added:** December 26, 2025
**Updated:** December 29, 2025 (v4.2.0 - worktree integration)

**Common Commands:**

```bash
# Launch modes (default = current directory)
cc                # Launch Claude HERE (acceptEdits mode)
cc pick           # Pick project → Claude (acceptEdits)
cc flow           # Direct jump → Claude
cc yolo           # Launch HERE in YOLO mode (skip permissions)
cc yolo pick      # Pick project → YOLO mode
cc yolo flow      # Direct jump → YOLO mode
cc plan           # Launch HERE in Plan mode
cc plan pick      # Pick project → Plan mode

# Session management
cc resume         # Resume with Claude session picker
cc continue       # Resume most recent conversation

# Quick actions
cc ask "query"    # Quick question (print mode)
cc file <file>    # Analyze a file
cc diff           # Review git changes
cc rpkg           # R package context helper

# Model selection (default = current directory)
cc opus           # Launch HERE with Opus model
cc opus pick      # Pick project → Opus model
cc haiku          # Launch HERE with Haiku model
cc haiku pick     # Pick project → Haiku model

# Worktree integration (v4.2.0)
cc wt                   # List current worktrees
cc wt <branch>          # Launch Claude in worktree
cc wt pick              # Pick worktree → Claude (fzf)
cc wt yolo <branch>     # Worktree + YOLO mode
cc wt plan <branch>     # Worktree + Plan mode
cc wt opus <branch>     # Worktree + Opus model
```

**Features:**

- Default launches Claude in current directory (no picker)
- Use `pick` subcommand to select project first
- Direct jump with project name (e.g., `cc flow`)
- Multiple permission modes (acceptEdits, YOLO, plan)
- Session resume with Claude's built-in picker
- Quick actions for common tasks
- Model selection shortcuts
- Worktree integration for parallel development (v4.2.0)

**Shortcuts:** `y`=yolo, `p`=plan, `r`=resume, `c`=continue, `a`=ask, `f`=file, `d`=diff, `o`=opus, `h`=haiku, `w`=wt

**Aliases:** `ccy`, `ccp`, `ccr`, `ccc`, `cca`, `ccf`, `ccd`, `cco`, `cch`, `ccw`, `ccwy`, `ccwp`

**See also:** [CC-DISPATCHER-REFERENCE.md](CC-DISPATCHER-REFERENCE.md)

---

### 8. `wt` - Git Worktree Management

**File:** `wt-dispatcher.zsh`
**Purpose:** Git worktree management for parallel development
**Added:** December 29, 2025 (v4.1.0)

**Common Commands:**

```bash
wt                    # Navigate to worktrees folder
wt list               # List all worktrees
wt create <branch>    # Create worktree for branch
wt move               # Move current branch to worktree
wt remove <path>      # Remove a worktree
wt clean              # Prune stale worktrees
wt help               # Show help

# Status & cleanup (v4.3.0)
wt status             # Show worktree health and disk usage
wt prune              # Comprehensive cleanup (worktrees + merged branches)
wt prune --branches   # Also delete merged feature branches
wt prune --force      # Skip confirmation
wt prune --dry-run    # Preview only
```

**Aliases:**

- `wt ls` → `wt list`
- `wt add` / `wt c` → `wt create`
- `wt mv` → `wt move`
- `wt rm` → `wt remove`
- `wt st` → `wt status`

**Configuration:**

```bash
# Set custom worktree directory (default: ~/.git-worktrees)
export FLOW_WORKTREE_DIR="$HOME/worktrees"
```

**Passthrough:**

Unknown commands pass through to `git worktree`:

```bash
wt lock <path>     # → git worktree lock <path>
wt unlock <path>   # → git worktree unlock <path>
```

**Features:**

- Organized worktree storage by project
- Protected branch validation (can't move main/dev)
- Smart branch detection (creates new or uses existing)
- Automatic directory structure creation

**See also:** [WT-DISPATCHER-REFERENCE.md](WT-DISPATCHER-REFERENCE.md)

---

### 9. `tm` - Terminal Manager

**File:** `tm-dispatcher.zsh`
**Purpose:** Terminal management via aiterm integration
**Added:** December 30, 2025 (v4.4.0)

**Common Commands:**

```bash
# Shell-native (instant, no Python)
tm title <text>       # Set tab/window title (OSC 2)
tm profile <name>     # Switch iTerm2 profile
tm var <key> <val>    # Set iTerm2 status bar variable
tm which              # Show detected terminal

# Aiterm delegation
tm ghost              # Ghostty status
tm ghost theme        # List/set Ghostty themes
tm ghost font         # Get/set Ghostty font
tm switch             # Apply terminal context
tm detect             # Detect project context
tm doctor             # Check terminal health
tm compare            # Compare terminal features
tm features           # Show terminal features
tm help               # Show help
```

**Shortcuts:**

- `t` = title, `p` = profile, `v` = var, `w` = which
- `g` = ghost, `s` = switch, `d` = detect

**Aliases:**

- `tmt` → `tm title`
- `tmp` → `tm profile`
- `tmv` → `tm var`
- `tmw` → `tm which`
- `tmg` → `tm ghost`
- `tms` → `tm switch`
- `tmd` → `tm detect`

**Terminal Detection:**

Automatically detects: iTerm2, Ghostty, WezTerm, Kitty, Alacritty, VS Code, Terminal.app

**Requirements:**

- **aiterm** (`ait`) for rich features (optional for shell-native commands)
- Install: `brew install data-wise/tap/aiterm` or `pip install aiterm-dev`

**Features:**

- Shell-native commands for instant response (no Python overhead)
- Delegates complex operations to aiterm Python CLI
- Auto-detects terminal emulator
- chpwd hook integration for auto-context switching

**See also:** [TM-DISPATCHER-REFERENCE.md](TM-DISPATCHER-REFERENCE.md)

---

### 10. `dot` - Dotfile Management

**File:** `dot-dispatcher.zsh`
**Purpose:** Dotfile sync via chezmoi + secret management via Bitwarden
**Added:** January 9, 2026 (v5.0.0)
**Version:** 1.2.0 (Phase 4 - Dashboard Integration)

**Common Commands:**

```bash
# Status & Info
dot                   # Show status
dot status            # Show detailed status
dot help              # Show help

# Dotfile Management
dot edit <file>       # Edit dotfile (with preview & apply)
dot sync              # Pull from remote (with preview)
dot push              # Commit & push to remote
dot diff              # Show pending changes
dot apply             # Apply pending changes

# Secret Management (Bitwarden)
dot unlock            # Unlock Bitwarden vault
dot secret <name>     # Retrieve secret (no echo)
dot secret list       # List available secrets

# Troubleshooting
dot doctor            # Run diagnostics
dot undo              # Rollback last apply
dot init              # Initialize dotfile management
```

**Shortcuts:**

- `s` = status, `e` = edit, `d` = diff, `a` = apply
- `p` = push, `u` = unlock, `dr` = doctor

**Key Features:**

- **ADHD-friendly:** Smart defaults, clear status, progressive disclosure
- **Fast:** < 500ms for most operations
- **Secure:** Session-scoped secrets, no terminal echo
- **Safe:** Preview before apply, easy undo
- **Optional:** Graceful degradation if tools not installed

**Dashboard Integration:**

Shows status automatically in `dash` command:

```
📝 Dotfiles: 🟢 Synced (2h ago) · 12 files tracked
```

Status icons: 🟢 Synced, 🟡 Modified, 🔴 Behind, 🔵 Ahead

**Doctor Integration:**

Included in `flow doctor` health checks:

```
📁 DOTFILES
  ✓ chezmoi v2.45.0
  ✓ Bitwarden CLI v2024.1.0
  ✓ Chezmoi initialized with git
  ✓ Remote configured
  ✓ Synced with remote
```

**Requirements:**

- **chezmoi** (brew install chezmoi) - for dotfile management
- **bitwarden-cli** (brew install bitwarden-cli) - for secret management
- **jq** (brew install jq) - optional, for pretty secret listing

**Security:**

- BW_SESSION only in current shell (not persistent)
- Secrets never echoed to terminal
- History exclusion patterns for sensitive commands
- Security checks in `flow doctor`

**Template Support:**

Use Bitwarden secrets in chezmoi templates:

```go
# In ~/.local/share/chezmoi/dot_gitconfig.tmpl
[github]
    token = {{ bitwarden "item" "github-token" }}
```

**Workflow:**

1. Edit dotfiles with `dot edit` (shows diff, prompts to apply)
2. Sync across machines with `dot sync` / `dot push`
3. Manage secrets with `dot unlock` / `dot secret`
4. Check health with `dot doctor`

**See also:** [DOT-DISPATCHER-REFERENCE.md](DOT-DISPATCHER-REFERENCE.md), [SECRET-MANAGEMENT.md](../SECRET-MANAGEMENT.md)

---

### 11. `teach` - Teaching Workflow

**File:** `teach-dispatcher.zsh`
**Purpose:** Unified teaching workflow for course websites
**Added:** January 12, 2026 (v5.4.1)

**Common Commands:**

```bash
teach init "STAT 545"     # Initialize teaching workflow
teach init -y "STAT 440"  # Non-interactive mode
teach exam "Midterm 1"    # Create exam/quiz
teach deploy              # Deploy draft → production
teach archive             # Archive semester
teach config              # Edit teach-config.yml
teach status              # Show project status
teach week                # Show current week number
teach help                # Show help

### Date Management (v5.11.0+)

Centralize semester dates in teach-config.yml and auto-sync to all files.

```bash
# Initialize dates
teach dates init           # Wizard: create 15 weeks from start date

# Sync dates from config to files
teach dates sync           # Interactive sync
teach dates sync --dry-run # Preview changes only
teach dates sync --force   # Auto-apply all

# Status & validation
teach dates status         # Show date summary
teach dates validate       # Validate config

# Selective sync
teach dates sync --assignments  # Assignments only
teach dates sync --lectures     # Lectures only
teach dates sync --file hw3.qmd # Single file
```

**See:** [Teaching Dates Guide](../guides/TEACHING-DATES-GUIDE.md) | [Quick Reference](TEACH-DATES-QUICK-REFERENCE.md)
```

**Shortcuts:**

| Short | Full | Description |
|-------|------|-------------|
| `i` | `init` | Initialize course |
| `e` | `exam` | Create exam |
| `d` | `deploy` | Deploy to production |
| `a` | `archive` | Archive semester |
| `c` | `config` | Edit config |
| `s` | `status` | Show status |
| `w` | `week` | Show week |

**Non-Interactive Mode:**

The `-y` / `--yes` flag accepts safe defaults:
- Strategy 1: In-place conversion (preserves history)
- Auto-exclude renv/ from git
- Skip GitHub push (push manually later)
- Use auto-suggested semester dates
- Skip break configuration

**Workflow:**

```
teach init → work course → teach deploy → teach archive
```

**See also:** [teach-init.md](../commands/teach-init.md), [TEACHING-WORKFLOW.md](../guides/TEACHING-WORKFLOW.md)

---

## Removed Dispatchers

### `v` / `vibe` - DEPRECATED

**Removed:** December 25, 2025  
**Commit:** `7cdd78f`  
**Reason:** Deprecated wrappers around `flow` command

**Migration:**

```bash
# Old              # New
v test       →    flow test
v build      →    flow build
v preview    →    flow preview
vibe         →    flow
```

**Use `flow` command directly** - It provides the same functionality with a clearer, unified interface.

---

### `gm` / `gem` - Gemini Dispatcher

**Status:** Archived  
**Alternative:** 13 personal Gemini aliases in .zshrc

**Why not restored:**

- Comprehensive `gem*` aliases already in .zshrc
- No GraphicsMagick conflict (uses `gem` prefix)
- Personal shortcuts more flexible

**Available alternatives:**

```bash
gem, gemi, gemy, gems, gemr    # Main commands
gemf, gemp                      # Model selection
gemj, gemsj                     # Output formats
gemw, gemws                     # Web search
gemc, geme, gemd                # Workflows
```

---

### `note` - Note Dispatcher

**Status:** Archived  
**Alternative:** `obs` dispatcher for Obsidian

**Why not restored:**

- `obs` dispatcher provides note functionality
- Obsidian is primary note system
- No clear use case separate from `obs`

---

### `timer` - Timer Functions

**Status:** Archived  
**Alternative:** `flow timer` command

**Why not restored:**

- Timer functionality available via `flow timer`
- Core command integration is cleaner
- No need for separate dispatcher

---

## Usage Patterns

### Basic Pattern

```bash
<dispatcher>              # Show help or default action
<dispatcher> help         # Show help
<dispatcher> <command>    # Execute specific command
```

### Examples

```bash
# Git
g status                  # Show git status
g commit "fix: bug"       # Commit with message

# Quarto
qu                        # Render and preview
qu pdf                    # Render to PDF

# R Package
r test                    # Run tests
r cycle                   # Full development cycle

# MCP
mcp list                  # List servers
mcp cd statistical        # Go to statistical-research server

# Obsidian
obs discover              # Find vaults
obs stats                 # Show statistics
```

---

## Setup & Diagnostics

### `flow doctor` - Health Check

**File:** `commands/doctor.zsh`
**Purpose:** Dependency verification and system health checks
**Added:** December 26, 2025

**Commands:**

```bash
flow doctor              # Check all dependencies
flow doctor --fix        # Interactive install missing tools
flow doctor --fix -y     # Auto-install all (no prompts)
flow doctor --ai         # AI-assisted troubleshooting (Claude CLI)
flow doctor --verbose    # Verbose output
flow doctor --help       # Show help
```

**Features:**

- Checks required, recommended, and optional dependencies
- Multi-package manager support (Homebrew, npm, pip)
- Interactive fix mode with confirmation prompts
- AI-assisted troubleshooting via Claude CLI
- ZSH plugin health verification

**Dependency Categories:**

| Category         | Tools                                      |
| ---------------- | ------------------------------------------ |
| **Required**     | fzf                                        |
| **Recommended**  | eza, bat, zoxide, fd, ripgrep              |
| **Optional**     | dust, duf, btop, delta, gh, jq             |
| **Integrations** | atlas, radian                              |
| **ZSH Plugins**  | p10k, autosuggestions, syntax-highlighting |

**Quick Fix All:**

```bash
brew bundle --file=$FLOW_PLUGIN_DIR/setup/Brewfile
```

---

## Integration with Flow

All dispatchers integrate with the main `flow` command namespace:

```bash
# Can also use:
flow test                 # Calls appropriate dispatcher
flow build                # Context-aware build
flow preview              # Context-aware preview
flow doctor               # Health check
```

---

## Creating New Dispatchers

**Template Structure:**

```zsh
# my-dispatcher.zsh - Tool Name Dispatcher

my_dispatcher() {
    # Help check
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        _my_dispatcher_help
        return 0
    fi

    local cmd="${1:-default}"
    shift 2>/dev/null || true

    case "$cmd" in
        command1)
            # Implementation
            ;;
        command2)
            # Implementation
            ;;
        help)
            _my_dispatcher_help
            ;;
        *)
            echo "Unknown command: $cmd"
            return 1
            ;;
    esac
}

_my_dispatcher_help() {
    cat << 'EOF'
# Help text here
EOF
}
```

**Location:** Place in `lib/dispatchers/my-dispatcher.zsh`  
**Auto-loading:** Automatically loaded by `flow.plugin.zsh`

---

## Troubleshooting

### Dispatcher Not Found

```bash
# Reload plugin
source ~/.zsh/plugins/flow-cli/flow.plugin.zsh

# Or reload shell
exec zsh
```

### Conflict with System Command

- Check for conflicts: `which <command>`
- Choose unique name for dispatcher
- Use different prefix if needed

### Dispatcher Not Loading

```bash
# Check if file exists
ls ~/projects/dev-tools/flow-cli/lib/dispatchers/

# Check FLOW_LOAD_DISPATCHERS setting
echo $FLOW_LOAD_DISPATCHERS  # Should be "yes"

# Manually source
source ~/projects/dev-tools/flow-cli/lib/dispatchers/<name>.zsh
```

---

## Summary

**Active Dispatchers:** 11 (g, mcp, obs, prompt, qu, r, cc, wt, tm, dot, teach)
**Removed:** 2 (v, vibe)
**Not Restored:** 3 (gm, note, timer - alternatives available)
**Total Commands:** ~150+ subcommands across all dispatchers

**New in v5.7.0:**

- `prompt` dispatcher - Prompt engine manager (Powerlevel10k, Starship, Oh My Posh)
- Interactive engine switching with validation
- Dry-run mode for previewing changes
- Setup wizard for Oh My Posh

**New in v5.4.1:**

- `teach` dispatcher - Teaching workflow for course websites
- Non-interactive mode with `-y` flag

**New in v5.0.0:**

- `dot` dispatcher - Dotfile management + secret management
- macOS Keychain integration (v5.5.0)

**New in v4.4.0:**

- `tm` dispatcher - Terminal manager (aiterm integration)
- Shell-native commands for instant terminal control

**New in v4.3.0:**

- `g feature status` - Show merged vs active branches
- `g feature prune --older-than` - Filter by branch age
- `g feature prune --force` - Skip confirmation
- `wt status` - Show worktree health and disk usage
- `wt prune` - Comprehensive cleanup with branch deletion

**New in v4.1.0:**

- `g feature` - Feature branch workflow commands
- `g promote` / `g release` - PR creation helpers
- Workflow guards for protected branches
- `wt` dispatcher for git worktree management

**Philosophy:** Each dispatcher provides a unified, ADHD-friendly interface for complex tool workflows with smart defaults and common operations.

---

**See Also:**

- [Command Quick Reference](./COMMAND-QUICK-REFERENCE.md)
- [Workflow Quick Reference](./WORKFLOW-QUICK-REFERENCE.md)
- [Contributing Guide](../contributing/CONTRIBUTING.md) - Plugin development
