# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project Overview

**flow-cli** - Pure ZSH plugin for ADHD-optimized workflow management. Zero dependencies. Standalone (works without Oh-My-Zsh or any plugin manager).

- **Architecture:** Pure ZSH plugin (no Node.js runtime required)
- **Current Version:** v6.6.0
- **Install:** Homebrew (recommended), or any plugin manager
- **Optional:** Atlas integration for enhanced state management
- **Health Check:** `flow doctor` for dependency verification
- **User ZSH Config:** `~/.config/zsh/` (not `~/.zshrc`)

### What It Does

- Instant workflow commands: `work`, `dash`, `finish`, `hop`
- 12 smart dispatchers: `g`, `mcp`, `obs`, `qu`, `r`, `cc`, `tm`, `wt`, `dot`, `teach`, `prompt`, `v`
- ADHD-friendly design (sub-10ms response, smart defaults)
- Session tracking, project switching, quick capture
- Teaching workflow with Scholar integration
- macOS Keychain secret management

---

## Git Workflow & Standards

**CRITICAL:** Follow these mandatory workflow rules when developing for flow-cli.

### Branch Architecture

- **main**: Production. PROTECTED. No direct commits. Only merges from `dev`.
- **dev**: Planning & Integration Hub. All features start here.
- **feature/**: Isolated implementation branches (via worktrees).

### Mandatory Workflow Steps

#### 1. Plan on `dev` Branch

**Before writing any code:**

```bash
git checkout dev && git pull origin dev
```

- Analyze requirements on `dev` branch
- Create comprehensive implementation plan
- Document in `docs/specs/SPEC-*.md`
- **Wait for user approval**
- Commit approved plan to `dev`

**Constraint:** Never write feature code on `dev` branch

#### 2. Create Worktree (Isolation)

```bash
git worktree add ~/.git-worktrees/flow-cli/<feature> -b feature/<feature> dev
git worktree list
```

#### 3. STOP - NEW Session Required

**CRITICAL:** Do NOT start working in the worktree from the planning session. Tell user to `cd` into worktree and start a new `claude` session.

#### 4. Atomic Development (In Worktree)

**Conventional Commits:** `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`

**Before each commit:** Run `./tests/run-all.sh`, verify `source flow.plugin.zsh`

#### 5. Integration (feature -> dev)

```bash
git fetch origin dev && git rebase origin/dev
./tests/run-all.sh
gh pr create --base dev
# After merge: git worktree remove ~/.git-worktrees/flow-cli/<feature>
```

#### 6. Release (dev -> main)

```bash
gh pr create --base main --head dev --title "Release vX.Y.Z"
git tag -a vX.Y.Z -m "vX.Y.Z" && git push --tags
```

### ABORT Conditions

1. About to commit to main -> Redirect to PR workflow
2. About to commit to dev -> Confirm if spec/planning commit
3. Push to main/dev without PR -> Block, require PR
4. Working in worktree from planning session -> Stop, tell user new session

**See:** `docs/contributing/BRANCH-WORKFLOW.md`

---

## Layered Architecture

flow-cli is Layer 1 of a 3-layer stack: **flow-cli** (pure ZSH, <10ms) < **aiterm** (Python CLI, rich viz) < **craft** (Claude Code plugin). flow-cli owns instant operations, session management, ADHD motivation, quick navigation, and simple dispatchers.

---

## Quick Reference

### Core Commands

```bash
work <project>    # Start session
finish [note]     # End session (optional commit)
hop <project>     # Quick switch (tmux)
dash [category]   # Project dashboard
catch <text>      # Quick capture
js                # Just start (auto-picks project)
flow doctor       # Health check
flow doctor --fix # Interactive install missing tools
```

### Dopamine Features

```bash
win <text>        # Log accomplishment (auto-categorized)
yay               # Show recent wins
yay --week        # Weekly summary + graph
flow goal set 3   # Set daily win target
```

### Active Dispatchers (12)

```bash
g <cmd>       # Git workflows
mcp <cmd>     # MCP server management
obs <cmd>     # Obsidian notes
qu <cmd>      # Quarto publishing
r <cmd>       # R package dev
cc [cmd]      # Claude Code launcher
tm <cmd>      # Terminal manager
wt <cmd>      # Worktree management
dot <cmd>     # Dotfile management
teach <cmd>   # Teaching workflow
prompt <cmd>  # Prompt engine switcher
v <cmd>       # Vibe coding mode
```

**Get help:** `<dispatcher> help` (e.g., `r help`, `teach help`)

### Teaching Subcommands

`teach analyze`, `teach init`, `teach deploy`, `teach doctor`, `teach exam`, `teach macros`, `teach map`, `teach plan`, `teach style`, `teach templates`, `teach prompt`

- **Doctor (v2):** Two-mode architecture — quick (default, < 3s) and full (`--full`, 11 categories)
  - Quick mode: CLI deps, R + renv, config, git (4 categories)
  - Full mode: + per-package R checks, quarto ext, scholar, hooks, cache, macros, style
  - Flags: `--full`, `--brief`, `--fix`, `--json`, `--ci`, `--verbose`
  - `--fix` offers renv vs system install choice for R packages
  - `--ci` exits non-zero on failure, no color, machine-readable output
  - Health dot shown on `teach` startup (refreshed on next `teach doctor` run)
- **Deploy:** `teach deploy --direct` (8-15s direct merge) or `teach deploy` (PR workflow)
- **Deploy preflight:** Display math `$$` validation (blank lines, unclosed blocks) — also runs at pre-commit via lint-staged
- **Deploy extras:** `--dry-run`, `--ci`, `--history [N]`, `--rollback [N]`
- **Templates:** `.flow/templates/` (content, prompts, metadata, checklists)
- **Macros:** `teach macros list|sync|export` (LaTeX notation consistency)
- **Plans:** `teach plan create|list|show|edit|delete` (lesson plan CRUD)
- **Prompts:** `teach prompt list|show|edit|validate|export` (3-tier resolution)

---

## Project Structure

```
flow-cli/
├── flow.plugin.zsh           # Plugin entry point
├── lib/                      # Core libraries (63 files)
│   ├── core.zsh              # Colors, logging, utilities
│   ├── git-helpers.zsh       # Git integration + smart commits
│   ├── keychain-helpers.zsh  # macOS Keychain secrets
│   ├── tui.zsh               # Terminal UI components
│   └── dispatchers/          # 12 smart command dispatchers
├── commands/                 # 31 command files (work, dash, doctor, teach-*, etc.)
├── setup/                    # Installation & setup
├── completions/              # ZSH completions
├── hooks/                    # ZSH hooks
├── docs/                     # Documentation (MkDocs)
│   └── internal/             # Internal conventions & contributor templates
├── scripts/                  # Standalone validators (check-math.zsh)
├── tests/                    # 143 test files, 8000+ test functions
│   └── fixtures/demo-course/ # STAT-101 demo course for E2E
└── .archive/                 # Archived Node.js CLI
```

### Key Files

| File                                        | Purpose                                   |
| ------------------------------------------- | ----------------------------------------- |
| `flow.plugin.zsh`                           | Plugin entry point (source to load)       |
| `lib/core.zsh`                              | Core utilities (logging, colors, helpers) |
| `lib/dispatchers/*.zsh`                     | 12 smart dispatchers                      |
| `commands/*.zsh`                            | Core commands (work, dash, finish, etc.)  |
| `docs/reference/MASTER-DISPATCHER-GUIDE.md` | Complete dispatcher docs                  |
| `docs/reference/MASTER-API-REFERENCE.md`    | API function reference                    |
| `docs/reference/MASTER-ARCHITECTURE.md`     | System architecture                       |
| `scripts/check-math.zsh`                    | Pre-commit math validator (lint-staged)   |
| `.STATUS`                                   | Current progress/sprint tracking          |

---

## Development

### Adding New Commands

1. Core command -> `commands/<name>.zsh`; Dispatcher subcommand -> `lib/dispatchers/<name>-dispatcher.zsh`
2. Use helpers: `_flow_log_success`, `_flow_log_error`, `_flow_find_project_root`, `_flow_detect_project_type`
3. Add completion in `completions/_<commandname>`
4. Every dispatcher MUST have `_<cmd>_help()` function using color scheme from `lib/core.zsh`

### Adding New Dispatcher

```bash
x() {
    case "$1" in
        action1) shift; _x_action1 "$@" ;;
        help|--help|-h) _x_help ;;
        *) _x_help ;;
    esac
}
```

Update: `MASTER-DISPATCHER-GUIDE.md`, `QUICK-REFERENCE.md`, `mkdocs.yml`

### Common Tasks

| Task              | Steps                                                                                          |
| ----------------- | ---------------------------------------------------------------------------------------------- |
| Update dispatcher | Edit `lib/dispatchers/<name>-dispatcher.zsh` -> update `_<name>_help()` -> test -> update docs |
| Deploy docs       | `mkdocs gh-deploy --force`                                                                     |
| Create release    | `./scripts/release.sh X.Y.Z` -> commit -> tag -> push                                          |

**Release script updates:** `package.json`, `README.md`, `CLAUDE.md`, `CC-DISPATCHER-REFERENCE.md`

---

## Architecture Principles

1. **Pure ZSH** - Sub-10ms response, no build step, no dependencies
2. **ADHD-Friendly** - Discoverable (built-in help), consistent patterns, smart defaults, fast (cached scanning)
3. **Dispatcher Pattern** - `command + keyword + options` (e.g., `r test`, `g push`, `teach exam "Topic"`)
4. **Optional Enhancement** - Atlas integration is optional; graceful degradation

---

## Testing

**143 test files, 8000+ test functions.** Run: `./tests/run-all.sh` (42/42 passing, 0 timeouts) or individual suites in `tests/`.

See `docs/guides/TESTING.md` for patterns, mocks, assertions, TDD workflow.

---

## Documentation

**Site:** https://Data-Wise.github.io/flow-cli/
**Build:** `mkdocs serve` (local) | `mkdocs gh-deploy --force` (deploy)
**Key docs:** `docs/guides/`, `docs/reference/`, `docs/help/QUICK-REFERENCE.md`, `docs/CONVENTIONS.md`
**Internal:** `docs/internal/` (conventions, contributor templates — excluded from site nav)

---

## Configuration

```zsh
export FLOW_PROJECTS_ROOT="$HOME/projects"  # Project root
export FLOW_ATLAS_ENABLED="auto"             # Atlas (auto|yes|no)
export FLOW_QUIET=1                          # Suppress welcome
export FLOW_DEBUG=1                          # Debug mode
```

---

## Current Status

**Version:** v6.6.0 | **Tests:** 8000+ (42/42 suite) | **Docs:** https://Data-Wise.github.io/flow-cli/

---

**Last Updated:** 2026-02-10 (v6.6.0)
