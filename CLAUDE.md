# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project Overview

**flow-cli** - Pure ZSH plugin for ADHD-optimized workflow management. Zero dependencies. Standalone (works without Oh-My-Zsh or any plugin manager).

- **Architecture:** Pure ZSH plugin (no Node.js runtime required)
- **Current Version:** v7.10.0
- **Install:** Homebrew (recommended), or any plugin manager
- **Source:** `source /opt/homebrew/opt/flow-cli/flow.plugin.zsh` (via Homebrew)
- **Optional:** Atlas integration for enhanced state management
- **Health Check:** `flow doctor` for dependency verification
- **User ZSH Config:** `~/.config/zsh/` (not `~/.zshrc`)

### What It Does

- Instant workflow commands: `work`, `dash`, `finish`, `hop`
- 14 smart dispatchers: `g`, `mcp`, `qu`, `r`, `cc`, `tm`, `wt`, `dots`, `sec`, `tok`, `teach`, `prompt`, `v`, `em`
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
dash [category]   # Project dashboard (shows UPCOMING schedule section)
agenda [window]   # Forward-looking schedule (today|-w|-m|--all|--overdue|<type|cat>)
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

### Active Dispatchers (14)

```bash
g <cmd>       # Git workflows
mcp <cmd>     # MCP server management
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

`teach` has 20+ subcommands (analyze, init, deploy, doctor, exam, macros, map, plan, style, templates, prompt, cache, profiles, migrate, validate, solution, sync, validate-r, config check/diff/show/scaffold). Doctor is two-mode (quick < 3s / `--full` 11 categories); deploy supports `--direct`/`--dry-run`/`--sync`/`--rollback` with `$$` math preflight.

→ Full reference: [`docs/guides/TEACH-DEPLOY-GUIDE.md`](docs/guides/TEACH-DEPLOY-GUIDE.md), [`docs/reference/REFCARD-DOCTOR.md`](docs/reference/REFCARD-DOCTOR.md)

---

## Project Structure

```zsh
flow-cli/
├── flow.plugin.zsh           # Plugin entry point
├── lib/                      # Core libraries (77 files)
│   ├── core.zsh              # Colors, logging, utilities
│   ├── git-helpers.zsh       # Git integration + smart commits
│   ├── keychain-helpers.zsh  # macOS Keychain secrets
│   ├── tui.zsh               # Terminal UI components
│   └── dispatchers/          # 14 smart command dispatchers
├── commands/                 # 32 command files (work, dash, agenda, doctor, teach-*, etc.)
├── setup/                    # Installation & setup
├── completions/              # ZSH completions
├── hooks/                    # ZSH hooks
├── docs/                     # Documentation (MkDocs)
│   └── internal/             # Internal conventions & contributor templates
├── scripts/                  # Standalone validators (check-math.zsh)
├── tests/                    # 213 test files, 12000+ test functions
│   └── fixtures/demo-course/ # STAT-101 demo course for E2E
└── .archive/                 # Archived Node.js CLI
```

### Key Files

| File                                        | Purpose                                   |
| ------------------------------------------- | ----------------------------------------- |
| `flow.plugin.zsh`                           | Plugin entry point (source to load)       |
| `lib/core.zsh`                              | Core utilities (logging, colors, helpers) |
| `lib/dispatchers/*.zsh`                     | 14 smart dispatchers                      |
| `commands/*.zsh`                            | Core commands (work, dash, finish, etc.)  |
| `docs/reference/MASTER-DISPATCHER-GUIDE.md` | Complete dispatcher docs                  |
| `docs/reference/MASTER-API-REFERENCE.md`    | API function reference                    |
| `docs/reference/MASTER-ARCHITECTURE.md`     | System architecture                       |
| `scripts/check-math.zsh`                    | Pre-commit math validator (lint-staged)   |
| `.STATUS`                                   | Current progress/sprint tracking          |

---

## Development

**Add a command:** core → `commands/<name>.zsh`; dispatcher subcommand → `lib/dispatchers/<name>-dispatcher.zsh`. Use helpers (`_flow_log_*`, `_flow_find_project_root`, `_flow_detect_project_type`); add `completions/_<name>`; every dispatcher MUST have a `_<cmd>_help()` using `lib/core.zsh` colors. New dispatcher = a `command + keyword + options` case block.

**After changes:** update `MASTER-DISPATCHER-GUIDE.md` + `QUICK-REFERENCE.md` + `mkdocs.yml`. **Release:** `./scripts/release.sh X.Y.Z` → commit → tag → push (bumps `flow.plugin.zsh` FLOW_VERSION, `package.json`, `README.md`, `CLAUDE.md`). Docs deploy automatically (don't run `mkdocs gh-deploy`).

→ Dispatcher template + patterns: [`docs/reference/MASTER-DISPATCHER-GUIDE.md`](docs/reference/MASTER-DISPATCHER-GUIDE.md)

**New dispatcher = new man page:** add `man/man1/<cmd>.1` (model `g.1`); the guard `tests/test-manpage-version-sync.zsh` fails CI on a missing page or `.TH` version drift. Details: [`ZSH-COMMANDS-HELP.md`](docs/internal/conventions/code/ZSH-COMMANDS-HELP.md) (Man Pages).

---

## Architecture Principles

1. **Pure ZSH** - Sub-10ms response, no build step, no dependencies
2. **ADHD-Friendly** - Discoverable (built-in help), consistent patterns, smart defaults, fast (cached scanning)
3. **Dispatcher Pattern** - `command + keyword + options` (e.g., `r test`, `g push`, `teach exam "Topic"`)
4. **Optional Enhancement** - Atlas integration is optional; graceful degradation (see [`docs/ATLAS-CONTRACT.md`](docs/ATLAS-CONTRACT.md) for API contract)
5. **Terminal hygiene on handoff** - Any command that runs an interactive TUI (fzf, etc.) and then execs/launches another program (e.g. `pick` → `claude`) MUST restore terminal state first: reset focus-reporting/mouse modes (`\e[?1004l\e[?1000l\e[?1002l\e[?1003l\e[?1006l\e[?2004l`) and drain pending input before handing off. Otherwise the next TUI inherits enabled modes + stray query responses → garbled characters and broken input. Use the shared helper **`_flow_tty_handoff_cleanup`** (`lib/core.zsh`) after every fzf call — it guards on `/dev/tty` (not stdout `[[ -t 1 ]]`, which is false when the picker's output is command-substituted). All three pickers call it: `pick()`, `_proj_pick_worktree_path` (`cc wt pick`/`ccy`), and `_flow_pick_project` (`work`). The regression guard `tests/test-terminal-hygiene-regression.zsh` enforces that any new fzf→exec picker calls it.

---

## Testing

**213 test files, 12000+ test functions.** Run: `./tests/run-all.sh` (64/64 passing, 1 expected interactive/tmux timeout) or individual suites in `tests/`.

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

# Binary-precedence guard (drops a dispatcher that shadows a PATH binary)
export FLOW_INTENTIONAL_SHADOWS=(r mcp cc tm) # Commands kept even when a same-named binary exists
export FLOW_FORCE_DISPATCHER_OBS=1           # Force-keep one dispatcher (FLOW_FORCE_DISPATCHER_<NAME>)
```

> **Guard caveat:** `FLOW_INTENTIONAL_SHADOWS` defaults to `(r mcp cc tm)` only when unset (`tm` was added in the ci-full-suite-gate work — a `tm` binary exists on some Linux/CI runners and was silently dropping the dispatcher). Setting it to an empty array (`=()`) is treated as an explicit override, so `cc` (vs `/usr/bin/cc`) etc. would then be dropped — append (`+=(...)`) rather than reassign if you only want to add entries.

---

## Current Status

**Version:** v7.10.0 | **Tests:** 12000+ (64/64 suite, 1 interactive timeout) | **Docs:** https://Data-Wise.github.io/flow-cli/

---

**Last Updated:** 2026-06-13 (v7.10.0)
