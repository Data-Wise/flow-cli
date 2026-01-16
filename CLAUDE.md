# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project Overview

**flow-cli** - Pure ZSH plugin for ADHD-optimized workflow management.

- **Architecture:** Pure ZSH plugin (no Node.js runtime required)
- **Status:** Production ready (v5.11.0 released)
- **Install:** Via plugin manager (antidote, zinit, oh-my-zsh)
- **Optional:** Atlas integration for enhanced state management
- **Health Check:** `flow doctor` for dependency verification

### User Environment

- **ZSH Config:** `~/.config/zsh/` (not `~/.zshrc`)
- **Main file:** `~/.config/zsh/.zshrc`

### What It Does

- Instant workflow commands: `work`, `dash`, `finish`, `hop`
- 10 smart dispatchers: `g`, `mcp`, `obs`, `qu`, `r`, `cc`, `tm`, `wt`, `dot`, `teach`
- ADHD-friendly design (sub-10ms response, smart defaults)
- Session tracking, project switching, quick capture
- macOS Keychain secret management (v5.11.0)

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

**Constraint:** ❌ Never write feature code on `dev` branch

#### 2. Create Worktree (Isolation)

**After plan approval:**

```bash
# Create worktree from dev
git worktree add ~/.git-worktrees/flow-cli-<feature> -b feature/<feature> dev

# Verify creation
git worktree list
```

#### 3. STOP - NEW Session Required

**CRITICAL:** Do NOT start working in the worktree from the planning session.

**Tell user:**

```
✅ Worktree created at ~/.git-worktrees/flow-cli-<feature>

To start implementation, please start a NEW session:
  cd ~/.git-worktrees/flow-cli-<feature>
  claude
```

**Why?** Fresh session ensures:

- Clean context (no planning baggage)
- Correct working directory
- Proper git state verification
- Isolated focus on implementation

#### 4. Atomic Development (In Worktree)

**Use Conventional Commits:**

- `feat:` - New feature
- `fix:` - Bug fix
- `refactor:` - Code restructure
- `docs:` - Documentation only
- `test:` - Add/modify tests
- `chore:` - Maintenance

**Before each commit:**

- Run tests: `./tests/run-all.sh`
- Verify builds: `source flow.plugin.zsh`
- Keep commits small and functional

#### 5. Integration (feature → dev)

```bash
# Rebase onto latest dev (linear history)
git fetch origin dev
git rebase origin/dev

# Run full test suite
./tests/run-all.sh

# Create PR to dev
gh pr create --base dev

# After merge, cleanup worktree
git worktree remove ~/.git-worktrees/flow-cli-<feature>
git branch -d feature/<feature>
```

#### 6. Release (dev → main)

**Maintainers only:**

```bash
# Create release PR
gh pr create --base main --head dev --title "Release v5.X.0"

# After merge, tag release
git tag -a v5.X.0 -m "Release v5.X.0"
git push --tags
```

### Tool Usage Constraints

**Always verify before git operations:**

```bash
# Check current branch/worktree
git branch --show-current
git worktree list | grep $(pwd)
```

**ABORT conditions:**

1. ⛔ **About to commit to main** → Redirect to PR workflow
2. ⚠️ **About to commit to dev** → Confirm if spec/planning commit
3. ⛔ **Push to main/dev without PR** → Block, require PR
4. ⚠️ **Working in worktree from planning session** → Stop, tell user to start NEW session

**See:** `docs/contributing/BRANCH-WORKFLOW.md` for complete workflow documentation

---

## Layered Architecture (flow-cli + aiterm + craft)

flow-cli is part of a 3-layer developer tooling stack:

```
┌─────────────────────────────────────────────────────────────────┐
│  Layer 3: craft plugin (Claude Code)                            │
│  /craft:git:feature - AI-assisted, tests, changelog             │
├─────────────────────────────────────────────────────────────────┤
│  Layer 2: aiterm (Python CLI)                                   │
│  ait feature - rich visualization, complex automation           │
├─────────────────────────────────────────────────────────────────┤
│  Layer 1: flow-cli (Pure ZSH) ← YOU ARE HERE                    │
│  g, wt, cc - instant (<10ms), zero overhead, ADHD-friendly      │
└─────────────────────────────────────────────────────────────────┘
```

### When to Use flow-cli vs aiterm

| Need                      | Use      | Command                  |
| ------------------------- | -------- | ------------------------ |
| **Quick branch creation** | flow-cli | `g feature start <name>` |
| **Quick worktree**        | flow-cli | `wt create <branch>`     |
| **Quick cleanup**         | flow-cli | `g feature prune`        |
| Full feature setup (deps) | aiterm   | `ait feature start -w`   |
| Pipeline visualization    | aiterm   | `ait feature status`     |
| Interactive cleanup       | aiterm   | `ait feature cleanup`    |
| **Quick MCP check**       | flow-cli | `mcp test <name>`        |
| Full MCP validation       | aiterm   | `ait mcp validate`       |
| **Launch Claude**         | flow-cli | `cc`, `cc yolo`          |
| Configure Claude settings | aiterm   | `ait claude settings`    |

### Delegation to aiterm

The `tm` dispatcher delegates to aiterm for rich operations:

- `tm ghost` → `ait ghost` (Ghostty terminal status)
- `tm detect` → `ait detect` (project context detection)
- `tm switch` → `ait switch` (apply context to terminal)

### flow-cli Owns:

1. **Instant operations** (<10ms response, pure ZSH)
2. **Session management** (work/finish/hop)
3. **ADHD motivation** (win/yay/streaks/goals)
4. **Quick navigation** (pick/dash)
5. **Simple dispatchers** (g/cc/mcp/r/qu/obs/wt/tm)

### aiterm Owns:

1. **Rich visualization** (tables, panels, trees via Rich)
2. **Complex automation** (deps install, multi-step workflows)
3. **Claude Code integration** (settings, hooks, approvals, MCP)
4. **Terminal configuration** (profiles, themes, fonts)
5. **Session tracking** (live sessions, conflicts, history)
6. **Workflow templates** (full workflow management)

**Repo:** https://github.com/Data-Wise/aiterm

---

## Quick Reference

### Core Commands

```bash
work <project>    # Start session
finish [note]     # End session (optional commit)
hop <project>     # Quick switch (tmux)
dash [category]   # Project dashboard
dash -i           # Interactive TUI (fzf)
dash --watch      # Live refresh mode
dash --inventory  # Auto-generated tool inventory (from .STATUS files)
catch <text>      # Quick capture
js                # Just start (auto-picks project)
flow doctor       # Health check (verify dependencies)
flow doctor --fix # Interactive install missing tools
```

### Dopamine Features (v5.11.0)

```bash
win <text>        # Log accomplishment (auto-categorized)
yay               # Show recent wins
yay --week        # Weekly summary + graph
flow goal         # Show daily goal progress
flow goal set 3   # Set daily win target
```

**Categories:** 💻 code, 📝 docs, 👀 review, 🚀 ship, 🔧 fix, 🧪 test, ✨ other

### Active Dispatchers (11)

```bash
g <cmd>       # Git workflows (g status, g push, g commit)
mcp <cmd>     # MCP server management (mcp status, mcp logs)
obs <cmd>     # Obsidian notes (obs vaults, obs stats)
qu <cmd>      # Quarto publishing (qu preview, qu render)
r <cmd>       # R package dev (r test, r doc, r check)
cc [cmd]      # Claude Code launcher (cc, cc pick, cc yolo)
tm <cmd>      # Terminal manager (tm title, tm profile, tm ghost)
wt <cmd>      # Worktree management (wt create, wt status, wt prune)
dot <cmd>     # Dotfile management (dot edit, dot sync, dot secret)
teach <cmd>   # Teaching workflow (teach init, teach deploy, teach exam)
prompt <cmd>  # Prompt engine switcher (prompt status, prompt toggle) [v5.11.0]
```

**Get help:** `<dispatcher> help` (e.g., `r help`, `cc help`, `teach help`)

### CC Dispatcher Quick Reference (v5.11.0)

**✨ Unified Grammar:** Both mode-first AND target-first orders work!

```bash
# Basic
cc                # Launch Claude HERE (current dir, acceptEdits)
cc .              # Explicit HERE (NEW!)
cc pick           # Pick project → Claude
cc <project>      # Direct jump → Claude (e.g., cc flow)

# Modes (both orders work!)
cc yolo           # Launch HERE in YOLO mode (skip permissions)
cc yolo pick      # Pick → YOLO mode (mode-first)
cc pick yolo      # Pick → YOLO mode (target-first) ✨
cc plan           # Launch HERE in Plan mode
cc plan pick      # Pick → Plan (mode-first)
cc pick plan      # Pick → Plan (target-first) ✨
cc opus           # Launch HERE with Opus model
cc opus pick      # Pick → Opus (mode-first)
cc pick opus      # Pick → Opus (target-first) ✨

# Session
cc resume         # Resume Claude session picker
cc continue       # Continue most recent conversation
```

**Alias:** `ccy` = `cc yolo`
**Shortcuts:** `o` = opus, `h` = haiku, `y` = yolo, `p` = plan

### TM Dispatcher Quick Reference

```bash
# Shell-native (instant, no Python)
tm title <text>       # Set tab/window title
tm profile <name>     # Switch iTerm2 profile
tm which              # Show detected terminal

# Aiterm delegation
tm ghost              # Ghostty status
tm ghost theme        # List/set Ghostty themes
tm switch             # Apply terminal context
tm detect             # Detect project context
```

**Aliases:** `tmt` = title, `tmp` = profile, `tmg` = ghost, `tms` = switch

### Pick - Project Picker (v5.11.0)

```bash
pick                # FZF picker (all projects)
pick r              # R packages only
pick dev            # Dev tools only
pick wt             # All worktrees
pick wt scribe      # Scribe's worktrees only
pick flow           # Direct jump to flow-cli
```

**Categories:** `r`, `dev`, `q`, `teach`, `rs`, `app`, `wt`

**Interactive Keys:** Enter (cd), Ctrl-O (cc), Ctrl-Y (ccy), Ctrl-S (status), Ctrl-L (log)

**Worktree Session Indicators:** 🟢 recent (< 24h), 🟡 old, (none) = no session

**Aliases:** `pickr`, `pickdev`, `pickq`, `pickwt`

### Deprecated (Removed 2025-12-25)

```bash
v / vibe      → Use 'flow' command instead
d             → Use 'dash' command
f             → Use 'flow' command
pp            → Use 'pick' command
ah            → Use 'aliashelp' command
```

**Note:** The `r` dispatcher no longer conflicts with `alias r=` - the alias was removed from ~/.config/zsh/.zshrc

---

## Project Structure

```
flow-cli/
├── flow.plugin.zsh           # Plugin entry point
├── lib/
│   ├── core.zsh              # Colors, logging, utilities
│   ├── atlas-bridge.zsh      # Atlas integration
│   ├── project-detector.zsh  # Project type detection
│   ├── tui.zsh               # Terminal UI components
│   ├── inventory.zsh         # Tool inventory generator
│   ├── keychain-helpers.zsh  # macOS Keychain secrets (v5.11.0)
│   └── dispatchers/          # Smart command dispatchers (10)
│       ├── cc-dispatcher.zsh     # Claude Code
│       ├── dot-dispatcher.zsh    # Dotfiles + Secrets
│       ├── g-dispatcher.zsh      # Git workflows
│       ├── mcp-dispatcher.zsh    # MCP servers
│       ├── obs.zsh               # Obsidian
│       ├── qu-dispatcher.zsh     # Quarto
│       ├── r-dispatcher.zsh      # R packages
│       ├── teach-dispatcher.zsh  # Teaching workflow
│       ├── tm-dispatcher.zsh     # Terminal manager
│       └── wt-dispatcher.zsh     # Worktrees
├── commands/                 # Command implementations
│   ├── work.zsh             # work, finish, hop, why
│   ├── dash.zsh             # Dashboard
│   ├── capture.zsh          # catch, crumb, trail
│   ├── adhd.zsh             # js, next, stuck, focus
│   ├── flow.zsh             # flow command
│   ├── doctor.zsh           # Health check & dependency management
│   └── pick.zsh             # Project picker
├── setup/                    # Installation & setup
│   ├── Brewfile             # Recommended Homebrew packages
│   └── README.md            # Setup instructions
├── completions/             # ZSH completions
│   ├── _work, _dash, _flow, _hop, _pick, _dot
├── hooks/                   # ZSH hooks
│   ├── chpwd.zsh           # Directory change
│   └── precmd.zsh          # Pre-command
├── docs/                    # Documentation (MkDocs)
│   ├── reference/          # Reference cards + ARCHITECTURE.md
│   ├── tutorials/          # Step-by-step guides
│   ├── guides/             # How-to guides
│   ├── commands/           # Command docs
│   └── conventions/        # Standards
├── tests/                   # Test suite (39 keychain tests)
├── zsh/functions/          # Legacy (backward compat)
└── .archive/               # Archived Node.js CLI
```

---

## Key Files

| File                                     | Purpose                  | Notes                    |
| ---------------------------------------- | ------------------------ | ------------------------ |
| `flow.plugin.zsh`                        | Plugin entry point       | Source this to load      |
| `lib/core.zsh`                           | Core utilities           | Logging, colors, helpers |
| `lib/atlas-bridge.zsh`                   | Atlas integration        | Optional state engine    |
| `lib/keychain-helpers.zsh`               | macOS Keychain secrets   | v5.11.0 - Touch ID       |
| `lib/config-validator.zsh`               | Config validation        | v5.11.0 - Schema + hash  |
| `lib/dispatchers/*.zsh`                  | Smart dispatchers        | 11 active dispatchers    |
| `commands/*.zsh`                         | Core commands            | work, dash, finish, etc. |
| `docs/reference/DISPATCHER-REFERENCE.md` | Complete dispatcher docs | All dispatchers          |
| `docs/reference/ARCHITECTURE.md`         | System architecture      | Mermaid diagrams         |
| `docs/reference/API-REFERENCE.md`        | API reference            | v5.11.0 - All functions  |
| `.STATUS`                                | Current progress         | Sprint tracking          |

---

## Development

### Testing the Plugin

```bash
# Load in current shell
source flow.plugin.zsh

# Test commands
work <Tab>           # Completions work
dash                 # Dashboard displays
r help               # Dispatcher help
qu help              # Dispatcher help
```

### Adding New Commands

1. **Choose location:**
   - Core command → `commands/<name>.zsh`
   - Dispatcher subcommand → `lib/dispatchers/<name>-dispatcher.zsh`

2. **Use helpers from `lib/core.zsh`:**

   ```bash
   _flow_log_success "Message"
   _flow_log_error "Error"
   _flow_find_project_root
   _flow_detect_project_type "$PWD"
   ```

3. **Add completion:**
   - Create `completions/_<commandname>`
   - Follow existing patterns

4. **Add help:**
   - Every dispatcher MUST have `_<cmd>_help()` function
   - Use color scheme from `lib/core.zsh`

### Adding New Dispatcher

1. **Create file:** `lib/dispatchers/<name>-dispatcher.zsh`

2. **Pattern:**

   ```bash
   # Single-letter or 2-letter function name
   x() {
       case "$1" in
           action1) shift; _x_action1 "$@" ;;
           action2) shift; _x_action2 "$@" ;;
           help|--help|-h) _x_help ;;
           *) _x_help ;;
       esac
   }

   _x_help() {
       # Formatted help with examples
   }
   ```

3. **Update docs:**
   - Add to `docs/reference/DISPATCHER-REFERENCE.md`
   - Update `docs/reference/COMMAND-QUICK-REFERENCE.md`
   - Update `mkdocs.yml` if needed

---

## Architecture Principles

### 1. Pure ZSH (No Node.js)

- All core commands in ZSH
- Sub-10ms response time
- No build step, no dependencies

### 2. ADHD-Friendly Design

| Principle        | Implementation              |
| ---------------- | --------------------------- |
| **Discoverable** | Built-in help: `<cmd> help` |
| **Consistent**   | Same pattern everywhere     |
| **Forgiving**    | Smart defaults, no errors   |
| **Fast**         | Cached project scanning     |

### 3. Dispatcher Pattern

```bash
# Pattern: command + keyword + options
r test              # R package: run tests
g push              # Git: push to remote
qu preview          # Quarto: preview document
```

**Benefits:**

- One command per domain
- Self-documenting
- Passthrough for advanced usage

### 4. Optional Enhancement

- Atlas integration is **optional**
- Graceful degradation without Atlas
- ZSH-only mode is fully functional

---

## Testing

### Test Suite Overview

**Status:** ✅ 76+ tests passing (100%)
**Documentation:** [Complete Testing Guide](docs/guides/TESTING.md)

```bash
# Core test suites (v5.11.0+)
tests/test-pick-command.zsh         # Pick: 39 tests (556 lines)
tests/test-cc-dispatcher.zsh        # CC: 37 tests (722 lines)
tests/test-dot-v5.11.0-unit.zsh      # DOT: 112+ tests
tests/test-cc-unified-grammar.zsh   # CC unified grammar
tests/test-pick-smart-defaults.zsh  # Pick defaults
tests/test-pick-wt.zsh              # Pick worktrees

# Interactive tests
tests/interactive-dog-feeding.zsh   # Gamified testing (ADHD-friendly)
tests/interactive-test.zsh
```

### Running Tests

```bash
# Run all test suites
./tests/run-all.sh

# Run specific suite
./tests/test-pick-command.zsh
./tests/test-cc-dispatcher.zsh

# Quick verification
source flow.plugin.zsh
work <Tab>           # Completions work
dash                 # Dashboard displays
pick help            # Help system works
cc help              # CC dispatcher works
```

### Test Coverage

| Component      | File                      | Tests   | Coverage |
| -------------- | ------------------------- | ------- | -------- |
| Pick command   | test-pick-command.zsh     | 39      | ✅ 100%  |
| CC dispatcher  | test-cc-dispatcher.zsh    | 37      | ✅ 100%  |
| DOT dispatcher | test-dot-v5.11.0-unit.zsh | 112+    | ✅ 100%  |
| **Total**      | **8 suites**              | **76+** | **100%** |

### Writing Tests

See [Testing Guide](docs/guides/TESTING.md) for:

- Test file structure and patterns
- Mock environment setup
- ANSI code handling
- Assertion helpers
- Debugging test failures
- TDD workflow

---

## Documentation

### Website

**URL:** https://Data-Wise.github.io/flow-cli/  
**Build:** `mkdocs build`  
**Deploy:** `mkdocs gh-deploy --force`

### Key Docs

| Document                                     | Purpose                   |
| -------------------------------------------- | ------------------------- |
| `docs/guides/DOPAMINE-FEATURES-GUIDE.md`     | Win/streak/goal features  |
| `docs/reference/DISPATCHER-REFERENCE.md`     | Complete dispatcher guide |
| `docs/reference/ALIAS-REFERENCE-CARD.md`     | All 28 aliases            |
| `docs/reference/COMMAND-QUICK-REFERENCE.md`  | Quick command lookup      |
| `docs/reference/WORKFLOW-QUICK-REFERENCE.md` | Common workflows          |
| `docs/getting-started/quick-start.md`        | 5-minute tutorial         |
| `docs/CONVENTIONS.md`                        | Code standards            |
| `docs/PHILOSOPHY.md`                         | Design principles         |

### Updating Docs

1. **Edit markdown files in `docs/`**
2. **Test locally:** `mkdocs serve` (http://127.0.0.1:8000)
3. **Build:** `mkdocs build`
4. **Deploy:** `mkdocs gh-deploy --force`

**Navigation:** Update `mkdocs.yml` when adding new pages

---

## Configuration

### Environment Variables

Set in `.zshrc` **before** sourcing the plugin:

```zsh
# Project root directory
export FLOW_PROJECTS_ROOT="$HOME/projects"

# Atlas integration (auto|yes|no)
export FLOW_ATLAS_ENABLED="auto"

# Quiet mode (suppress welcome)
export FLOW_QUIET=1

# Debug mode
export FLOW_DEBUG=1
```

### User Preferences (2025-12-25)

- **Explicit commands** over shortcuts
- **No single-letter aliases** (too ambiguous)
- **Full command names** (dash, flow, pick, not d, f, pp)
- **Dispatchers** for domain-specific workflows

---

## Integration Points

| Project                  | Integration                              | Status             |
| ------------------------ | ---------------------------------------- | ------------------ |
| **atlas**                | Optional state engine (@data-wise/atlas) | Optional           |
| **zsh-claude-workflow**  | Shared project patterns                  | Active             |
| **claude-mcp**           | Browser extension MCP                    | Complementary      |
| **statistical-research** | MCP server (R, Zotero)                   | Via mcp dispatcher |

---

## Current Status (2026-01-15)

### ✅ v5.11.0 RELEASED - Config Validation & Scholar Deep Integration

**Release:** https://github.com/Data-Wise/flow-cli/releases/tag/v5.11.0
**PR:** #249 (merged)

**What's New:**

- [x] Schema-based config validation for teach-config.yml
- [x] Hash-based change detection (SHA-256 caching)
- [x] Flag validation before Scholar invocation
- [x] Config ownership protocol (flow-cli vs Scholar sections)
- [x] New `lib/config-validator.zsh` module
- [x] API Reference documentation
- [x] Safe Testing guide with sandbox approach
- [x] Interactive dogfeeding test suite

**Validation Features:**

```bash
# Auto-validates on teach status/exam/quiz/etc
teach status              # Shows validation summary
teach status --verbose    # Shows validation details

# Validates:
# - Required field: course.name
# - Enum: semester (Spring|Summer|Fall|Winter)
# - Range: year (2020-2100)
# - Date format: YYYY-MM-DD
# - Grading sum (~100%)
```

---

### ✅ v5.11.0 RELEASED - Scholar Teaching Wrappers

**Release:** https://github.com/Data-Wise/flow-cli/releases/tag/v5.11.0 (bundled)
**PR:** #246 (merged)

**What's New:**

- [x] 9 Scholar wrapper commands via `teach` dispatcher
- [x] `teach exam/quiz/slides/lecture/assignment/syllabus/rubric/feedback/demo`
- [x] Preflight validation (checks config + Claude CLI)
- [x] Universal flags: `--dry-run`, `--format`, `--output`, `--verbose`
- [x] Tab completion for all commands and flags
- [x] 28 tests (100% passing)

**New Commands:**

```bash
# Generate exam via Scholar (AI-powered)
teach exam "Hypothesis Testing" --format quarto

# Generate quiz
teach quiz "Chapter 5 Review" --questions 10

# Generate slides from topic
teach slides "Introduction to Regression"

# All commands support --dry-run preview
teach exam "Topic" --dry-run --verbose
```

---

### ✅ v5.11.0 RELEASED - Prompt Engine Dispatcher

**Release:** https://github.com/Data-Wise/flow-cli/releases/tag/v5.11.0 (bundled)
**PR:** #245 (merged)

**What's New:**

- [x] New `prompt` dispatcher with 8 subcommands
- [x] Support for 3 engines: Powerlevel10k, Starship, OhMyPosh
- [x] Interactive toggle menu for switching engines
- [x] OhMyPosh setup wizard
- [x] `--dry-run` flag for safe preview
- [x] 224+ tests (97% passing)
- [x] Comprehensive guides and reference documentation

**New Commands:**

```bash
# Check current prompt engine
prompt status

# Interactive switch menu
prompt toggle

# Direct switch
prompt starship
prompt p10k
prompt ohmyposh

# Preview switch without making changes
prompt --dry-run toggle

# Setup wizard for OhMyPosh
prompt setup-ohmyposh
```

---

### ✅ v5.11.0 RELEASED - macOS Keychain Secrets

**Release:** https://github.com/Data-Wise/flow-cli/releases/tag/v5.11.0

- [x] `dot secret add/get/list/delete` - Native macOS Keychain storage
- [x] `dot secret import` - One-time Bitwarden migration
- [x] Touch ID / Apple Watch authentication support
- [x] Zero session management (no `dot unlock` needed)
- [x] 39 tests for keychain helpers (100% passing)

---

### ✅ v5.11.0 RELEASED - Bug Fixes

**Release:** https://github.com/Data-Wise/flow-cli/releases/tag/v5.11.0

- [x] Fixed `dot unlock` stderr contamination
- [x] Fixed `cc wt` worktree path detection (flat naming support)

---

### ✅ v5.11.0 RELEASED - Teaching Workflow & UX Enhancements

**Release:** https://github.com/Data-Wise/flow-cli/releases/tag/v5.11.0
**PR:** #230

**What Was Delivered:**

- [x] `teach` dispatcher - unified teaching commands
- [x] Non-interactive mode (`-y`/`--yes`) for teach-init
- [x] ADHD-friendly completion summary with rollback instructions
- [x] Help flags (`-h`/`--help`/`help`) for work, hop, teach-init
- [x] Already-initialized project detection
- [x] 19 new tests for teach-init UX
- [x] Complete documentation (teach.md, DISPATCHER-REFERENCE.md)

**New Commands:**

```bash
teach init "STAT 545"     # Initialize teaching workflow
teach init -y "STAT 440"  # Non-interactive mode
teach exam "Midterm"      # Create exam
teach deploy              # Deploy draft → production
teach status              # Show project status
teach week                # Show current week
```

**Help Flags Now Work:**

```bash
work --help               # Show work command help
hop -h                    # Show hop command help
teach-init help           # Show teach-init help
```

---

### ✅ v5.11.0 RELEASED - Secret Management v2.0 Complete

**Feature:** Complete Secret Management Lifecycle
**Status:** Released and deployed
**Release:** https://github.com/Data-Wise/flow-cli/releases/tag/v5.11.0

**What Was Delivered:**

- [x] Phase 1: Foundation (dot secret add/check, dot lock, 15-min cache)
- [x] Phase 2: Token Wizards (dot token github/npm/pypi, dot secrets)
- [x] Phase 3: Token Rotation (dot token <name> --refresh)
- [x] Integration: CI/CD sync (dot secrets sync github, dot env init)
- [x] 134 unit tests (100% passing)
- [x] Complete documentation (guide, reference, refcard)

**Key Commands (v5.11.0):**

```bash
# Token Wizards
dot token github              # GitHub PAT creation wizard
dot token npm                 # NPM token wizard
dot token pypi                # PyPI token wizard

# Token Rotation
dot token github-token --refresh    # Rotate existing token

# Secrets Dashboard
dot secrets                   # View all secrets with expiration

# CI/CD Integration
dot secrets sync github       # Sync to GitHub repo secrets
dot env init                  # Generate .envrc for direnv
```

**Integration:**

- 15-minute session cache with auto-lock
- Dashboard shows vault status with time remaining
- Token expiration tracking and warnings
- Metadata stored in Bitwarden notes field

---

### ✅ v5.11.0 Released - Bug Fix: Pick Command Crash

- [x] Fixed "bad math expression" error in `_proj_show_git_status()` (#155)
- [x] Added input sanitization for `wc` output (handles terminal control codes)
- [x] Added regression test to prevent future occurrences
- [x] All 23 tests passing

### ✅ v5.11.0 Released - Frecency & Session Indicators

- [x] Frecency decay scoring (time-based priority decay)
- [x] Session indicators (🟢/🟡) on regular projects, not just worktrees
- [x] Projects sorted by recent Claude activity

### ✅ v5.11.0 Released - Frecency Sorting

- [x] `pick --recent` / `pick -r` - Show only projects with Claude sessions
- [x] Frecency sorting (most recently used first)
- [x] CI apt caching (~17s vs 5+ min)

### ✅ v5.11.0 Released - CI Optimization

- [x] CI reduced to smoke tests (~30s)
- [x] `./tests/run-all.sh` for local full test suite
- [x] Pick worktree docs and session-age sorting

### ✅ v5.11.0 Released

- [x] `pick` shows worktrees in default view (🌳 icons)
- [x] CI streamlined: 4 jobs → 1 job

### ✅ v5.11.0 Released - Worktree-Aware Pick

- [x] `pick wt` - List all worktrees from `~/.git-worktrees/`
- [x] Session indicators: 🟢 recent / 🟡 old
- [x] Ctrl-O/Y - cd + launch Claude

### 🎯 Production Ready

- **Version:** v5.11.0 released
- **Released:** 2026-01-14
- **Status:** Production use phase
- **Performance:** Sub-10ms for core commands, CI ~17s
- **Documentation:** https://Data-Wise.github.io/flow-cli/
- **Tests:** 300+ tests across all features (224 prompt tests, 28 Scholar tests, 31 config validation tests)

### 📋 Future: Installation Improvements

- [ ] Create `install.sh` (curl one-liner, auto-detect plugin manager)
- [ ] Add install methods comparison table to README
- [ ] Update `docs/getting-started/installation.md` to match aiterm quality
- [ ] Test on fresh environment

**Reference:** aiterm's installation approach (`/Users/dt/projects/dev-tools/aiterm/install.sh`)

### 📋 Future Roadmap

**Remote & Team Features**

- [ ] Remote state sync (optional cloud backup)
- [ ] Multi-device support
- [ ] Shared templates

---

## Common Tasks

### Update Dispatcher

1. Edit `lib/dispatchers/<name>-dispatcher.zsh`
2. Update help function `_<name>_help()`
3. Test: `source flow.plugin.zsh && <name> help`
4. Update docs: `docs/reference/DISPATCHER-REFERENCE.md`

### Add Alias

1. Check frequency: Only if used 10+ times/day
2. Add to appropriate section in .zshrc (NOT in flow-cli)
3. Update `docs/reference/ALIAS-REFERENCE-CARD.md`
4. Avoid conflicts with system commands

### Fix Startup Error

Common issues:

```bash
# Alias/function conflict
# Fix: Remove alias, keep function
unalias <name>

# Missing dependency
# Fix: Add conditional check
command -v <tool> >/dev/null || return

# Syntax error
# Fix: Check ZSH syntax (not bash)
```

### Deploy Documentation

```bash
# Build and test locally
mkdocs serve

# Deploy to GitHub Pages
mkdocs gh-deploy --force

# Verify
open https://Data-Wise.github.io/flow-cli/
```

### Create Release

```bash
# Use the release script to bump all version files
./scripts/release.sh 3.7.0

# Review changes
git diff

# Commit and tag
git add -A && git commit -m "chore: bump version to 3.7.0"
git tag -a v5.11.0 -m "v5.11.0"

# Push (requires PR for protected branch)
git push origin main && git push origin v5.11.0
```

**Files updated by release script:**

- `package.json` - version field
- `README.md` - badge version
- `CLAUDE.md` - version references
- `docs/reference/CC-DISPATCHER-REFERENCE.md` - version

---

## Support

- **Documentation:** https://Data-Wise.github.io/flow-cli/
- **Issues:** https://github.com/Data-Wise/flow-cli/issues
- **Tests:** `./tests/interactive-dog-feeding.zsh`

---

**Last Updated:** 2026-01-15
**Status:** Production Ready
