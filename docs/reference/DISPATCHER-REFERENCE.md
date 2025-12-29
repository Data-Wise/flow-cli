# Dispatcher Reference - flow-cli

**Last Updated:** December 29, 2025
**Version:** flow-cli v4.1.0

---

## Overview

Dispatchers are smart command routers that provide context-aware workflows for specific tools. Each dispatcher provides a unified interface with smart defaults and common subcommands.

**Location:** `~/projects/dev-tools/flow-cli/lib/dispatchers/`

---

## Active Dispatchers (7)

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

**Feature Branch Workflow (v4.1.0):**

```bash
# Feature development
g feature start <name>   # Create feature/<name> from dev
g feature sync           # Rebase feature onto dev
g feature list           # List feature/hotfix branches
g feature finish         # Push + create PR to dev

# Promotion flow
g promote                # Create PR: feature → dev
g release                # Create PR: dev → main
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

**Features:**

- Smart defaults for common operations
- ADHD-friendly quick commands
- Feature branch workflow enforcement
- Workflow guards for protected branches
- Context-aware suggestions

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

---

### 4. `qu` - Quarto Publishing

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

---

### 5. `r` - R Package Development

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

---

### 6. `cc` - Claude Code Workflows

**File:** `cc-dispatcher.zsh`
**Purpose:** Smart Claude Code project workflows
**Added:** December 26, 2025

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
```

**Features:**

- Default launches Claude in current directory (no picker)
- Use `pick` subcommand to select project first
- Direct jump with project name (e.g., `cc flow`)
- Multiple permission modes (acceptEdits, YOLO, plan)
- Session resume with Claude's built-in picker
- Quick actions for common tasks
- Model selection shortcuts

**Shortcuts:** `y`=yolo, `p`=plan, `r`=resume, `c`=continue, `a`=ask, `f`=file, `d`=diff, `o`=opus, `h`=haiku

**See also:** [CC-DISPATCHER-REFERENCE.md](CC-DISPATCHER-REFERENCE.md)

---

### 7. `wt` - Git Worktree Management

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
```

**Aliases:**

- `wt ls` → `wt list`
- `wt add` / `wt c` → `wt create`
- `wt mv` → `wt move`
- `wt rm` → `wt remove`
- `wt prune` → `wt clean`

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

**Active Dispatchers:** 7 (g, mcp, obs, qu, r, cc, wt)
**Removed:** 2 (v, vibe)
**Not Restored:** 3 (gm, note, timer - alternatives available)
**Total Commands:** ~120+ subcommands across all dispatchers

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
- [Architecture Overview](../architecture/README.md) - Plugin structure
