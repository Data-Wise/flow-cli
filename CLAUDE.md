# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project Overview

**flow-cli** - Pure ZSH plugin for ADHD-optimized workflow management. Zero dependencies. Standalone (works without Oh-My-Zsh or any plugin manager).

- **Architecture:** Pure ZSH plugin (no Node.js runtime required)
- **Current Version:** v7.8.0
- **Install:** Homebrew (recommended), or any plugin manager
- **Source:** `source /opt/homebrew/opt/flow-cli/flow.plugin.zsh` (via Homebrew)
- **Optional:** Atlas integration for enhanced state management
- **Health Check:** `flow doctor` for dependency verification
- **User ZSH Config:** `~/.config/zsh/` (not `~/.zshrc`)

### What It Does

- Instant workflow commands: `work`, `dash`, `finish`, `hop`
- 15 smart dispatchers: `g`, `mcp`, `obs`, `qu`, `r`, `cc`, `tm`, `wt`, `dots`, `sec`, `tok`, `teach`, `prompt`, `v`, `em`
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

1. **Plan on `dev`** — `git checkout dev && git pull origin dev`. Analyze, write a `docs/specs/SPEC-*.md`, wait for approval, commit the spec to `dev`. **Never write feature code on `dev`.**
2. **Worktree + plan** — `git worktree add ~/.git-worktrees/flow-cli/<feature> -b feature/<feature> dev`, then write `ORCHESTRATE-<feature>.md` **to the worktree** (task list, file changes, verification) and commit it to the feature branch.
3. **STOP — new session required.** The dev/planning session's job ends after the worktree + ORCHESTRATE commit. Do NOT implement from it; tell the user to `cd` into the worktree and start a new `claude` session.
4. **Atomic development (in worktree)** — conventional commits (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`). Before each commit: `./tests/run-all.sh` + verify `source flow.plugin.zsh`.
5. **Integrate** — `git fetch origin dev && git rebase origin/dev` → `./tests/run-all.sh` → `gh pr create --base dev`. After merge: `git worktree remove ...`.
6. **Release (dev → main)** — `gh pr create --base main --head dev --title "Release vX.Y.Z"`, then tag `vX.Y.Z` and push tags.

### ABORT Conditions

1. About to commit to main -> Redirect to PR workflow
2. About to commit to dev -> Confirm if spec/planning commit
3. Push to main/dev without PR -> Block, require PR
4. Working in worktree from planning session -> Stop, tell user new session
5. About to implement code after creating worktree on dev -> STOP, write orchestration plan only

**See:** `docs/contributing/BRANCH-WORKFLOW.md`

---

## Layered Architecture

flow-cli is Layer 1 of a 3-layer stack: **flow-cli** (pure ZSH, <10ms) < **aiterm** (Python CLI, rich viz) < **craft** (Claude Code plugin). flow-cli owns instant operations, session management, ADHD motivation, quick navigation, and simple dispatchers.

---

## Quick Reference

### Core Commands

```bash
work <project>    # Start session (cd + context, no editor)
work <proj> -e    # Start session + open $EDITOR
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

### Active Dispatchers (15)

```bash
g <cmd>       # Git workflows
mcp <cmd>     # MCP server management
obs <cmd>     # Obsidian notes
qu <cmd>      # Quarto publishing
r <cmd>       # R package dev
cc [cmd]      # Claude Code launcher
tm <cmd>      # Terminal manager
wt <cmd>      # Worktree management
dots <cmd>    # Dotfile management (chezmoi)
sec <cmd>     # Secret management (Keychain/Bitwarden)
tok <cmd>     # Token management (create/rotate/expire/sync→GH secrets)
teach <cmd>   # Teaching workflow
prompt <cmd>  # Prompt engine switcher
v <cmd>       # Vibe coding mode
em <cmd>      # Email management (himalaya)
at <cmd>      # Atlas bridge (project intelligence, optional)
```

**Get help:** `<dispatcher> help` (e.g., `r help`, `teach help`, `at help`)

### Teaching Subcommands

`teach analyze`, `teach init`, `teach deploy`, `teach doctor`, `teach exam`, `teach macros`, `teach map`, `teach plan`, `teach style`, `teach templates`, `teach prompt`, `teach cache`, `teach profiles`, `teach migrate`, `teach validate`, `teach solution`, `teach sync`, `teach validate-r`, `teach config check`, `teach config diff`, `teach config show`, `teach config scaffold`

- **Doctor (v2):** Two-mode architecture — quick (default, < 3s) and full (`--full`, 11 categories)
  - Quick mode: CLI deps, R + renv, config, git, Scholar config (5 categories)
  - Full mode: + per-package R checks, quarto ext, scholar, hooks, cache, macros, style
  - Flags: `--full`, `--brief`, `--fix`, `--json`, `--ci`, `--verbose`
  - `--fix` offers renv vs system install choice for R packages
  - `--ci` exits non-zero on failure, no color, machine-readable output
  - Health dot shown on `teach` startup (refreshed on next `teach doctor` run)
- **Deploy:** `teach deploy --direct` (8-15s direct merge) or `teach deploy` (PR workflow)
- **Deploy preflight:** Display math `$$` validation (blank lines, unclosed blocks) — also runs at pre-commit via lint-staged
- **Deploy extras:** `--dry-run`, `--ci`, `--history [N]`, `--rollback [N]`, `--sync`
- **Deploy sync:** `teach deploy --sync` merges production into draft (ff-only first, then regular merge). Auto back-merge runs after `--direct` deploys to prevent false conflict detection.
- **Templates:** `.flow/templates/` (content, prompts, metadata, checklists)
- **Macros:** `teach macros list|sync|export` (LaTeX notation consistency)
- **Plans:** `teach plan create|list|show|edit|delete` (lesson plan CRUD)
- **Prompts:** `teach prompt list|show|edit|validate|export` (3-tier resolution)

---

## Project Structure

```zsh
flow-cli/
├── flow.plugin.zsh           # Plugin entry point
├── lib/                      # Core libraries (74 files)
│   ├── core.zsh              # Colors, logging, utilities
│   ├── git-helpers.zsh       # Git integration + smart commits
│   ├── keychain-helpers.zsh  # macOS Keychain secrets
│   ├── tui.zsh               # Terminal UI components
│   └── dispatchers/          # 15 smart command dispatchers
├── commands/                 # 31 command files (work, dash, doctor, teach-*, etc.)
├── setup/                    # Installation & setup
├── completions/              # ZSH completions
├── hooks/                    # ZSH hooks
├── docs/                     # Documentation (MkDocs)
│   └── internal/             # Internal conventions & contributor templates
├── scripts/                  # Standalone validators (check-math.zsh)
├── tests/                    # 210 test files, 12000+ test functions
│   └── fixtures/demo-course/ # STAT-101 demo course for E2E
└── .archive/                 # Archived Node.js CLI
```

### Key Files

| File                                        | Purpose                                   |
| ------------------------------------------- | ----------------------------------------- |
| `flow.plugin.zsh`                           | Plugin entry point (source to load)       |
| `lib/core.zsh`                              | Core utilities (logging, colors, helpers) |
| `lib/dispatchers/*.zsh`                     | 15 smart dispatchers                      |
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

**Release script updates:** `flow.plugin.zsh` (FLOW_VERSION), `package.json`, `README.md`, `CLAUDE.md`, `CC-DISPATCHER-REFERENCE.md`

---

## Architecture Principles

1. **Pure ZSH** - Sub-10ms response, no build step, no dependencies
2. **ADHD-Friendly** - Discoverable (built-in help), consistent patterns, smart defaults, fast (cached scanning)
3. **Dispatcher Pattern** - `command + keyword + options` (e.g., `r test`, `g push`, `teach exam "Topic"`)
4. **Optional Enhancement** - Atlas integration is optional; graceful degradation (see [`docs/ATLAS-CONTRACT.md`](docs/ATLAS-CONTRACT.md) for API contract)
5. **Terminal hygiene on handoff** - Any command that runs an interactive TUI (fzf, etc.) and then execs/launches another program (e.g. `pick` → `claude`) MUST restore terminal state first: reset focus-reporting/mouse modes (`\e[?1004l\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?2004l`) and drain pending input before handing off. Otherwise the next TUI inherits enabled modes + stray query responses → garbled characters and broken input. Use the shared helper **`_flow_tty_handoff_cleanup`** (`lib/core.zsh`) after every fzf call — it guards on `/dev/tty` (not stdout `[[ -t 1 ]]`, which is false when the picker's output is command-substituted). All three pickers call it: `pick()`, `_proj_pick_worktree_path` (`cc wt pick`/`ccy`), and `_flow_pick_project` (`work`). The regression guard `tests/test-terminal-hygiene-regression.zsh` enforces that any new fzf→exec picker calls it.

---

## Testing

**210 test files, 12000+ test functions.** Run: `./tests/run-all.sh` (58/58 passing, 1 expected interactive/tmux timeout) or individual suites in `tests/`.

See `docs/guides/TESTING.md` for patterns, mocks, assertions, TDD workflow.

---

## Documentation

**Site:** https://Data-Wise.github.io/flow-cli/
**Build:** `mkdocs serve` (local). **Deploy is automatic** — `docs.yml` CI deploys to gh-pages on push to `main` (don't run `mkdocs gh-deploy`; the branch guard blocks the gh-pages push).
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

**Version:** v7.8.0 | **Tests:** 12000+ (58/58 suite, 1 interactive timeout) | **Docs:** https://Data-Wise.github.io/flow-cli/

---

**Last Updated:** 2026-06-04 (v7.8.0)
