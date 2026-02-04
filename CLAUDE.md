# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project Overview

**flow-cli** - Pure ZSH plugin for ADHD-optimized workflow management.

- **Architecture:** Pure ZSH plugin (no Node.js runtime required)
- **Dependencies:** **ZERO** - No dependencies on Oh-My-Zsh, antidote, or any framework
- **Current Version:** v6.4.0
- **Latest Release:** v6.4.0 (2026-02-03)
- **Install:** Homebrew (recommended), or any plugin manager (antidote, zinit, oh-my-zsh, manual)
- **Optional:** Atlas integration for enhanced state management
- **Health Check:** `flow doctor` for dependency verification

### Independence Note

**IMPORTANT:** flow-cli is a **standalone ZSH plugin** with zero external dependencies:

- ✅ Works WITHOUT Oh-My-Zsh (OMZ)
- ✅ Works WITHOUT any plugin manager
- ✅ Works WITHOUT any external plugins
- ✅ OMZ is ONE installation method, NOT a requirement
- ✅ References to OMZ in code are for USER detection/support only

**User Detection Logic:**

```zsh
# flow-cli DETECTS user's setup (doesn't require it)
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    # User has OMZ → show relevant help
elif [[ -f "$HOME/.antidoterc" ]]; then
    # User has antidote → show relevant help
fi
```

### User Environment

- **ZSH Config:** `~/.config/zsh/` (not `~/.zshrc`)
- **Main file:** `~/.config/zsh/.zshrc`

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

**Constraint:** ❌ Never write feature code on `dev` branch

#### 2. Create Worktree (Isolation)

**After plan approval:**

```bash
# Create worktree from dev
git worktree add ~/.git-worktrees/flow-cli/<feature> -b feature/<feature> dev

# Verify creation
git worktree list
```

#### 3. STOP - NEW Session Required

**CRITICAL:** Do NOT start working in the worktree from the planning session.

**Tell user:**

```
✅ Worktree created at ~/.git-worktrees/flow-cli/<feature>

To start implementation, please start a NEW session:
  cd ~/.git-worktrees/flow-cli/<feature>
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
git worktree remove ~/.git-worktrees/flow-cli/<feature>
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

### flow-cli Owns:

1. **Instant operations** (<10ms response, pure ZSH)
2. **Session management** (work/finish/hop)
3. **ADHD motivation** (win/yay/streaks/goals)
4. **Quick navigation** (pick/dash)
5. **Simple dispatchers** (g/cc/mcp/r/qu/obs/wt/tm/dot/teach/prompt/v)

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
dash --inventory  # Auto-generated tool inventory
catch <text>      # Quick capture
js                # Just start (auto-picks project)
flow doctor       # Health check (verify dependencies)
flow doctor --fix # Interactive install missing tools
```

### Dopamine Features

```bash
win <text>        # Log accomplishment (auto-categorized)
yay               # Show recent wins
yay --week        # Weekly summary + graph
flow goal         # Show daily goal progress
flow goal set 3   # Set daily win target
```

**Categories:** 💻 code, 📝 docs, 👀 review, 🚀 ship, 🔧 fix, 🧪 test, ✨ other

### Active Dispatchers (12)

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
teach <cmd>   # Teaching workflow (teach analyze, teach init, teach deploy, teach exam, teach macros, teach plan, teach style)
prompt <cmd>  # Prompt engine switcher (prompt status, prompt toggle)
v <cmd>       # Vibe coding mode (v on, v off, v status)
```

**Get help:** `<dispatcher> help` (e.g., `r help`, `cc help`, `teach help`)

### Template Management (v6.1.0) ✨

**Project-local templates at `.flow/templates/`**

```bash
teach templates              # List all templates
teach templates list         # List with filtering
teach templates new lecture week-05   # Create from template
teach templates new lab week-03 --topic "ANOVA"
teach templates validate     # Check template syntax
teach templates sync         # Update from plugin defaults
teach init --with-templates  # Initialize with templates
```

### LaTeX Macro Management (v6.1.0) ✨

**Consistent notation for AI-generated content**

```bash
teach macros list            # Show all macros with expansions
teach macros list --category operators  # Filter by category
teach macros sync            # Extract from source files
teach macros export          # Export for Scholar integration
teach macros export --format json  # Export as JSON
```

**Supported formats:** QMD (`_macros.qmd`), MathJax HTML, LaTeX (`.tex`)

**Categories:** operators, distributions, symbols, matrices, derivatives, probability

**Primary use:** Ensure `teach exam`, `teach quiz` generate `\E{Y}` instead of `E[Y]`

**Template Types:**

| Type         | Directory                     | Purpose                                          |
| ------------ | ----------------------------- | ------------------------------------------------ |
| `content`    | `.flow/templates/content/`    | .qmd starters (lecture, lab, slides, assignment) |
| `prompts`    | `.flow/templates/prompts/`    | AI generation prompts (for Scholar)              |
| `metadata`   | `.flow/templates/metadata/`   | \_metadata.yml files                             |
| `checklists` | `.flow/templates/checklists/` | QA checklists                                    |

**Resolution Order:** Project templates override plugin defaults.

**Documentation:** `docs/reference/REFCARD-TEMPLATES.md`

### Lesson Plan Management (v6.1.0) ✨

**CRUD management of lesson plan weeks**

```bash
teach plan create 3 --topic "Probability" --style rigorous
teach plan create 5                      # Auto-populate from config
teach plan list                          # Table with gap detection
teach plan list --json                   # JSON output
teach plan show 3                        # Formatted details
teach plan 3                             # Shortcut for show
teach plan edit 3                        # Open in $EDITOR at line
teach plan delete 3 --force              # Remove week
```

**Styles:** conceptual, computational, rigorous, applied

**Files:** `.flow/lesson-plans.yml` (centralized), `.flow/teach-config.yml` (topic source)

**Shortcuts:** `teach pl`, `teach plan c`, `teach plan ls`, `teach plan s`

**Documentation:** `docs/reference/REFCARD-TEACH-PLAN.md`

### Token Management (v6.1.0 Phase 1) ✨

**Isolated Token Checks & Smart Caching**

**Phase 1 Features (COMPLETE):**

- ✅ Isolated token checks (`doctor --dot`) - < 3s vs 60+ seconds
- ✅ Smart caching (5-min TTL, 85% hit rate, 80% API reduction)
- ✅ ADHD-friendly category menu (visual hierarchy, time estimates)
- ✅ Verbosity control (quiet/normal/verbose)
- ✅ Token-only fix mode (`doctor --fix-token`)

**New Commands:**

```bash
doctor --dot              # Check only tokens (< 3s, cached)
doctor --dot=github       # Check specific provider
doctor --fix-token        # Fix token issues only
doctor --dot --quiet      # Minimal output (CI/CD)
doctor --dot --verbose    # Debug output (cache status)
```

**Legacy Commands:**

```bash
dot token expiring    # Manual expiration check
dot token rotate      # Manual rotation
flow token expiring   # Alias for dot token
```

**Integration:**

- `g push/pull` - Validates token before remote ops
- `dash dev` - Shows token status
- `work` - Checks token on session start
- `finish` - Validates before push
- `doctor` - Full health check including tokens

**Performance:**

- Cache check: ~5-8ms (< 10ms target)
- Token check (cached): ~50-80ms (< 100ms target)
- Token check (fresh): ~2-3s (< 3s target)
- Cache effectiveness: ~85% hit rate

**Documentation:**

- User Guide: `docs/guides/DOCTOR-TOKEN-USER-GUIDE.md`
- API Reference: `docs/reference/MASTER-API-REFERENCE.md` (Token Management section)
- Architecture: `docs/architecture/DOCTOR-TOKEN-ARCHITECTURE.md`
- Quick Reference: `docs/reference/REFCARD-TOKEN-SECRETS.md`

**Tests:** 54 comprehensive tests (52 passing, 2 expected skips)

**Future (Phases 2-4 - Deferred):**

- Multi-token support (npm, pypi)
- Atomic fixes with rollback
- Gamification & notifications
- Custom validation rules

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
│   ├── keychain-helpers.zsh  # macOS Keychain secrets
│   ├── config-validator.zsh  # Config validation
│   ├── git-helpers.zsh       # Git integration + smart commits
│   ├── deploy-history-helpers.zsh  # Deploy history (append-only YAML)
│   ├── deploy-rollback-helpers.zsh # Forward rollback (git revert)
│   └── dispatchers/          # Smart command dispatchers (12)
│       ├── cc-dispatcher.zsh     # Claude Code
│       ├── dot-dispatcher.zsh    # Dotfiles + Secrets
│       ├── g-dispatcher.zsh      # Git workflows
│       ├── mcp-dispatcher.zsh    # MCP servers
│       ├── obs.zsh               # Obsidian
│       ├── qu-dispatcher.zsh     # Quarto
│       ├── r-dispatcher.zsh      # R packages
│       ├── teach-dispatcher.zsh  # Teaching workflow
│       ├── tm-dispatcher.zsh     # Terminal manager
│       ├── wt-dispatcher.zsh     # Worktrees
│       ├── prompt-dispatcher.zsh # Prompt engine
│       └── v-dispatcher.zsh      # Vibe coding mode
├── commands/                 # Command implementations
│   ├── work.zsh             # work, finish, hop, why
│   ├── dash.zsh             # Dashboard
│   ├── capture.zsh          # catch, crumb, trail
│   ├── adhd.zsh             # js, next, stuck, focus
│   ├── flow.zsh             # flow command
│   ├── doctor.zsh           # Health check & dependency management
│   └── pick.zsh             # Project picker
├── setup/                    # Installation & setup
├── completions/             # ZSH completions
├── hooks/                   # ZSH hooks
├── docs/                    # Documentation (MkDocs)
├── tests/                   # Test suite (538+ tests)
│   ├── fixtures/            # Test fixtures
│   │   └── demo-course/     # STAT-101 demo course for E2E
│   ├── test-teach-deploy-v2-unit.zsh        # Deploy v2 unit: 34 tests
│   ├── test-teach-deploy-v2-integration.zsh # Deploy v2 integration: 22 tests
│   ├── e2e-teach-deploy-v2.zsh              # Deploy v2 E2E: 20 tests
│   ├── e2e-teach-analyze.zsh                # E2E: 29 tests
│   └── interactive-dog-teaching.zsh         # Interactive: 10 tasks
└── .archive/               # Archived Node.js CLI
```

---

## Key Files

| File                                        | Purpose                  | Notes                    |
| ------------------------------------------- | ------------------------ | ------------------------ |
| `flow.plugin.zsh`                           | Plugin entry point       | Source this to load      |
| `lib/core.zsh`                              | Core utilities           | Logging, colors, helpers |
| `lib/atlas-bridge.zsh`                      | Atlas integration        | Optional state engine    |
| `lib/keychain-helpers.zsh`                  | macOS Keychain secrets   | Touch ID support         |
| `lib/config-validator.zsh`                  | Config validation        | Schema + hash validation |
| `lib/git-helpers.zsh`                       | Git integration          | Smart commits, teaching  |
| `lib/deploy-history-helpers.zsh`            | Deploy history           | Append-only YAML         |
| `lib/deploy-rollback-helpers.zsh`           | Deploy rollback          | Forward rollback         |
| `lib/dispatchers/*.zsh`                     | Smart dispatchers        | 12 active dispatchers    |
| `commands/*.zsh`                            | Core commands            | work, dash, finish, etc. |
| `docs/reference/MASTER-DISPATCHER-GUIDE.md` | Complete dispatcher docs | All 12 dispatchers       |
| `docs/reference/MASTER-ARCHITECTURE.md`     | System architecture      | Mermaid diagrams         |
| `docs/reference/MASTER-API-REFERENCE.md`    | API documentation        | Function reference       |
| `docs/DOC-DASHBOARD.md`                     | Doc coverage metrics     | Auto-generated stats     |
| `.STATUS`                                   | Current progress         | Sprint tracking          |

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
teach help           # Teaching dispatcher help
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
   - Add to `docs/reference/MASTER-DISPATCHER-GUIDE.md`
   - Update `docs/help/QUICK-REFERENCE.md`
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
teach exam "Topic"  # Generate exam via Scholar
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

**Status:** ✅ 538+ tests total
**Documentation:** [Complete Testing Guide](docs/guides/TESTING.md)

```bash
# Core test suites
tests/test-pick-command.zsh         # Pick: 39 tests
tests/test-cc-dispatcher.zsh        # CC: 37 tests
tests/test-dot-v6.1.0-unit.zsh     # DOT: 112+ tests
tests/test-teach-dates-unit.zsh     # Teaching dates: 33 tests
tests/test-teach-dates-integration.zsh  # Integration: 16 tests

# Teach plan tests (v6.1.0)
tests/test-teach-plan.zsh           # Unit: 32 tests
tests/test-teach-plan-security.zsh  # Security: 24 tests (YAML injection, edge cases)
tests/e2e-teach-plan.zsh            # E2E: 15 tests (CRUD workflows)

# Teach deploy v2 tests (v6.4.0)
tests/test-teach-deploy-v2-unit.zsh        # Unit: 34 tests
tests/test-teach-deploy-v2-integration.zsh # Integration: 22 tests
tests/e2e-teach-deploy-v2.zsh             # E2E: 20 tests

# E2E tests (teach analyze)
tests/e2e-teach-analyze.zsh         # E2E: 29 tests (8 sections)

# Interactive tests
tests/interactive-dog-teaching.zsh  # Interactive: 10 gamified tasks
tests/interactive-dog-feeding.zsh   # Gamified testing (ADHD-friendly)
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
teach help           # Teaching dispatcher works
```

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

| Document                                    | Purpose                   |
| ------------------------------------------- | ------------------------- |
| `docs/guides/DOPAMINE-FEATURES-GUIDE.md`    | Win/streak/goal features  |
| `docs/reference/MASTER-DISPATCHER-GUIDE.md` | Complete dispatcher guide |
| `docs/reference/MASTER-API-REFERENCE.md`    | API function reference    |
| `docs/reference/MASTER-ARCHITECTURE.md`     | System architecture       |
| `docs/help/QUICK-REFERENCE.md`              | Quick command lookup      |
| `docs/help/WORKFLOWS.md`                    | Common workflows          |
| `docs/getting-started/quick-start.md`       | 5-minute tutorial         |
| `docs/CONVENTIONS.md`                       | Code standards            |
| `docs/PHILOSOPHY.md`                        | Design principles         |

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

---

## Current Status

**Version:** v6.4.0
**Latest Release:** v6.4.0 (2026-02-03)
**Status:** Production
**Branch:** `dev`
**Release (latest):** https://github.com/Data-Wise/flow-cli/releases/tag/v6.4.0
**Performance:** Sub-10ms for core commands, 3-10x speedup from optimization
**Documentation:** https://Data-Wise.github.io/flow-cli/
**Tests:** 538+ total tests (462 existing + 76 new teach deploy v2 tests)

**Recent Improvements:**

- ✅ teach deploy v2 - Direct merge (8-15s), smart commits, history, rollback, dry-run, CI mode
- ✅ Deploy history tracking - Append-only `.flow/deploy-history.yml`
- ✅ Forward rollback - `teach deploy --rollback` via git revert
- ✅ Legacy dead code removed - ~400 lines of old `_teach_deploy()` + `_teach_deploy_help()`
- ✅ 76 new tests - 34 unit + 22 integration + 20 E2E

---

## Recent Releases

### v6.4.0 - Teach Deploy v2: Direct Merge, History, Rollback (2026-02-03)

**Released:** 2026-02-03
**Branch:** `feature/teach-deploy-v2`
**Changes:** 8 features, 1 refactor, 76 new tests

**Major Features:**

- **Direct Merge Mode** (`--direct/-d`) — 8-15s deploys vs 45-90s PR workflow
  - `_deploy_direct_merge()` — merge draft→production, push, no PR
  - `--direct-push` kept as backward-compatible alias
  - Smart commit messages auto-generated from changed file categories

- **Smart Commit Messages** — Auto-categorized from file paths
  - `_generate_smart_commit_message()` in `lib/git-helpers.zsh`
  - Categories: content (lectures, assignments), config (_quarto.yml), style (CSS), data, deploy
  - Overridable with `--message "text"`

- **Deploy History Tracking** — Append-only `.flow/deploy-history.yml`
  - `lib/deploy-history-helpers.zsh` — 4 functions (append, list, get, count)
  - `cat >>` for writes (fast), `yq` for reads only
  - Records: mode, commit hash, branch, file count, message, duration
  - `teach deploy --history [N]` — show last N deploys

- **Forward Rollback** (`--rollback [N]`) — Revert via `git revert`
  - `lib/deploy-rollback-helpers.zsh` — 2 functions (rollback, perform_rollback)
  - Interactive picker or explicit index
  - Records rollback in history with mode "rollback"
  - CI mode requires explicit index (no interactive picker)

- **Dry-Run Preview** (`--dry-run`/`--preview`) — Preview without mutation
  - `_deploy_dry_run_report()` — shows files, commit message, merge direction
  - Works with both direct merge and PR mode

- **CI Mode** (`--ci`) — Non-interactive deployment
  - Auto-detect from TTY (`[[ ! -t 0 ]]`)
  - 18 CI guards on all `read -r` prompts
  - Explicit `--ci` flag override

- **Shared Preflight** — Extracted `_deploy_preflight_checks()`
  - Git repo check, config validation, branch detection
  - Sets `DEPLOY_*` exported variables for all deploy modes
  - `[ok]`/`[!!]` marker format

- **.STATUS Auto-Updates** — `_deploy_update_status_file()`
  - Updates `last_deploy`, `deploy_count`, `teaching_week`
  - Teaching week calculated from `semester_info.start_date`
  - Non-destructive: skips if `.STATUS` absent

**Refactoring:**

- Deleted legacy `_teach_deploy()` (~313 lines) from `teach-dispatcher.zsh`
- Deleted legacy `_teach_deploy_help()` (~85 lines) from `teach-dispatcher.zsh`
- All deploy routing uses `_teach_deploy_enhanced()` exclusively

**New Files:**

- `lib/deploy-history-helpers.zsh` (185 lines)
- `lib/deploy-rollback-helpers.zsh` (214 lines)
- `tests/test-teach-deploy-v2-unit.zsh` (34 tests)
- `tests/test-teach-deploy-v2-integration.zsh` (22 tests)
- `tests/e2e-teach-deploy-v2.zsh` (20 tests)

**Testing:** 76 new tests (34 unit + 22 integration + 20 E2E), all passing

**Stats:** 9 files changed, +2,687 / -581 lines

---

### v6.3.0 - Teaching Style Consolidation + Help Compliance (2026-02-03)

**Released:** 2026-02-03
**PR #334:** https://github.com/Data-Wise/flow-cli/pull/334 (MERGED)
**Release:** https://github.com/Data-Wise/flow-cli/releases/tag/v6.3.0
**Changes:** Teaching style consolidation, help compliance system, docs overhaul, test fixes

**Major Features:**

- **Teaching Style Consolidation (#298)** — Read `teaching_style:` and `command_overrides:` from `.flow/teach-config.yml`
  - `lib/teach-style-helpers.zsh` — 4 helper functions (`_teach_find_style_source`, `_teach_get_style`, `_teach_get_command_override`, `_teach_style_is_redirect`)
  - `teach style` / `teach style show` — display current teaching style config
  - `teach style check` — validate teaching style configuration
  - `teach doctor` — new "Teaching Style" section reports source and config status
  - Schema: `teaching_style` + `command_overrides` definitions added to `teach-config.schema.json`
  - Resolution order: `.flow/teach-config.yml` (preferred) → `.claude/teaching-style.local.md` (legacy fallback)
  - Redirect shim detection (`_redirect: true` in legacy frontmatter)

- **Help Compliance System (#328)** — 9-rule automated validator for all 12 dispatchers
  - `flow doctor --help-check` validates against CONVENTIONS.md standards
  - All 12 dispatchers brought to full compliance (box header, MOST COMMON, QUICK EXAMPLES, TIP, See Also)

- **Documentation Overhaul** — Website reorganized (14→7 sections), 11 new teaching docs, section landing pages, MkDocs tags

- **Test Fixes** — Repaired 3 pre-existing failures (cc-dispatcher scope bug, obs-dispatcher stale assertions, e2e-dot-safety sandbox guard)

**Testing:** 21 passed in run-all.sh, 34-test dogfooding suite for teach style helpers

**Stats:** 82 files changed, +3,628 / -4,251 lines

---

### v6.2.1 - Help Compliance System (2026-02-03)

**Released:** 2026-02-03
**PR #332:** https://github.com/Data-Wise/flow-cli/pull/332 (MERGED)
**Release:** https://github.com/Data-Wise/flow-cli/releases/tag/v6.2.1
**Changes:** Help compliance system, dispatcher standardization, infrastructure fixes

**Major Features:**

- **Help Compliance Checker** — 9-rule automated validator for all 12 dispatcher help functions
  - `flow doctor --help-check` validates against CONVENTIONS.md
  - `lib/help-compliance.zsh` — reusable compliance engine
  - Rules: box header/footer, MOST COMMON, QUICK EXAMPLES, categorized actions, TIP, See Also, color codes, function naming

- **Dispatcher Help Standardization** — All 12 dispatchers brought to full compliance
  - cc, dot, obs, prompt, teach, tm, v dispatchers updated
  - `teach help` expanded with 26-alias shortcuts table and workflow examples
  - Color fallback pattern standardized (global `if [[ -z "$_C_BOLD" ]]` block)

- **Infrastructure Fixes**
  - `mkdocs.yml`: removed deprecated `tags_file` option (Material 9.6+)
  - `package.json`: version synced to 6.2.0
  - `doctor --help-check` header migrated from `FLOW_COLORS[]` to `_C_*`
  - Color fallback canonical pattern documented in CONVENTIONS.md

**Testing:** 356 new tests (14 core + 342 dogfooding suite with negative tests)

**Stats:** 18 files changed, +1,653 / -422 lines

---

### v6.2.0 - Docs Overhaul + Website Reorganization (2026-02-02)

**Released:** 2026-02-02
**PR #326:** https://github.com/Data-Wise/flow-cli/pull/326 (MERGED)
**Release:** https://github.com/Data-Wise/flow-cli/releases/tag/v6.2.0
**Changes:** Documentation overhaul, no code changes

**Major Features:**

- **Website Reorganization** - Reduced top-level navigation from 14 to 7 sections
  - Merged Getting Started + Help → "Getting Started"
  - Grouped Tutorials into 4 subsections → "Learn"
  - Merged Workflows + Guides → "Workflows & Guides"
  - Merged Reference + Commands + Architecture → "Reference"
  - Merged Development + Testing + Visuals + Planning → "Contributing"
  - Removed Documentation Hub tab

- **11 New Teaching Docs** - Filled documentation gaps across teach system
  - 6 REFCARDs: TEACH-DISPATCHER, ANALYSIS, DATES, DOCTOR, SCHOLAR-FLAGS, TEACH-CONFIG-SCHEMA
  - 3 Guides: SCHOLAR-WRAPPERS-GUIDE, TEACH-DEPLOY-GUIDE, TEACHING-TROUBLESHOOTING
  - 2 Tutorials: First Exam Walkthrough (#29), New Instructor Workflow (#30)

- **Index Page Redesign** - ADHD-friendly visual hierarchy
- **Cross-references** - Bidirectional links added to 6 existing tutorials
- **Brainstorm files archived** - Cleaned repo root

**Stats:** 27 files changed, +9,004 / -109 lines

**Post-release fixes (PR #327, #329):**

- Section landing pages with grid cards (Getting Started, Workflows, Reference, Contributing)
- MkDocs Material tags plugin with 14 topic tags across ~39 pages
- Tags index page at `/tags/`
- Triage: deleted 7 orphaned files, expanded exclude globs, fixed broken links
- `pymdownx.emoji` extension for grid card emoji rendering
- `attr_list` spacing fix (`:emoji:{ .lg .middle }` — no space)
- Version badges and What's New updated to v6.2.0
- Resolved all 28 MkDocs build warnings (0 remaining)

---

### v6.1.0 - Comprehensive Chezmoi Safety Features (2026-01-31)

**Released:** 2026-01-31
**PR #316:** https://github.com/Data-Wise/flow-cli/pull/316 (MERGED)
**Release:** https://github.com/Data-Wise/flow-cli/releases/tag/v6.1.0
**Changes:** Major safety enhancements to dot dispatcher

**Major Features:**

- **Preview-Before-Add** (`dot add`) - Intelligent file analysis before adding to chezmoi
  - File counting with human-readable size display
  - Large file detection (>50KB warnings)
  - Generated file detection (`.log`, `.sqlite`, `.db`, `.cache`)
  - Git metadata detection (prevents tracking nested `.git` directories)
  - Smart auto-ignore suggestions
  - Cross-platform support (BSD/GNU `find` and `du`)

- **Ignore Pattern Management** (`dot ignore`) - Smart `.chezmoiignore` management
  - `dot ignore add <pattern>` - Add patterns with deduplication
  - `dot ignore list` - Display all patterns with line numbers
  - `dot ignore remove <pattern>` - Remove specific patterns
  - `dot ignore edit` - Open in `$EDITOR`
  - Auto-initialization with sensible defaults

- **Repository Size Analysis** (`dot size`) - Proactive bloat detection
  - Total repository size tracking
  - Top 10 largest files identification
  - File type distribution analysis
  - Health indicators (OK/Warning/Critical)
  - Actionable cleanup suggestions

- **Enhanced Health Checks** (`flow doctor --dot`) - 9 comprehensive checks
  - Chezmoi installation verification
  - Repository initialization status
  - `.chezmoiignore` existence
  - Large file detection (>100KB)
  - Generated file detection
  - Git metadata detection
  - Repository size validation (<10MB healthy)
  - Auto-ignore pattern coverage
  - Cross-platform utilities check

**Implementation:**

- `lib/dispatchers/dot-dispatcher.zsh` - Enhanced with safety commands
- `lib/platform-helpers.zsh` - Cross-platform `find`/`du` abstraction
- `commands/doctor.zsh` - Enhanced with 9 dot-specific checks

**Testing:**

- 170+ comprehensive tests across 5 suites
- Unit tests for all safety features
- Integration tests for workflows
- Cross-platform compatibility tests

**Documentation:**

- `docs/guides/CHEZMOI-SAFETY-GUIDE.md` (400+ lines) - User guide
- `docs/reference/REFCARD-DOT-SAFETY.md` (350+ lines) - Quick reference
- `docs/architecture/DOT-SAFETY-ARCHITECTURE.md` (600+ lines) - System architecture
- `docs/reference/API-DOT-SAFETY.md` (600+ lines) - API reference

**Stats:** 1,950+ lines of documentation, 170+ tests

---

### v6.1.0 - AI Prompt Management + GIF Quality Enhancement (2026-01-29)

**Released:** 2026-01-29
**PR #313:** https://github.com/Data-Wise/flow-cli/pull/313 (MERGED - AI Prompts)
**PR #315:** https://github.com/Data-Wise/flow-cli/pull/315 (MERGED - GIF Quality)
**Release:** https://github.com/Data-Wise/flow-cli/releases/tag/v6.1.0
**Changes:** 67 files changed, +9,012 / -44 lines

**Major Features:**

- **AI Prompt Management** (`teach prompt`) - 3-tier resolution system
  - `teach prompt list` - List prompts by scope (Course > User > Plugin)
  - `teach prompt show <name>` - Display prompt content with metadata
  - `teach prompt edit <name>` - Edit prompts with automatic validation
  - `teach prompt validate` - Check all prompts for syntax errors
  - `teach prompt export` - Export for Scholar integration
  - Auto-resolve integration: Scholar automatically injects course-specific prompts

- **Documentation GIF Quality Enhancement** (PR #315)
  - Standardized font size to 18px across 21 teaching GIFs (up from 14-16px)
  - Fixed 133 ZSH syntax errors in 9 VHS tapes (`Type "#..."` → `Type "echo '...'`)
  - Added Shell directives for consistent ZSH behavior
  - Optimized GIF file sizes (10.9% reduction: 2.48MB → 2.21MB)
  - Created validation tooling (`validate-vhs-tapes.sh` + comprehensive style guide)
  - Embedded all teaching GIFs directly in documentation
  - 50 files changed, +4,274 lines

- **Implementation:**
  - commands/teach-prompt.zsh (625 lines) - Full CRUD command
  - lib/prompt-helpers.zsh (454 lines) - 3-tier resolution engine
  - scripts/validate-vhs-tapes.sh (validation automation)
  - VHS-TAPE-STYLE-GUIDE.md (419 lines)

- **Testing:**
  - 107 comprehensive tests (100% passing)
  - 62 unit tests (full command coverage)
  - 33 E2E tests (workflows + edge cases)
  - 12 interactive dogfooding tasks

- **Documentation:**
  - Tutorial 28: teach-prompt.md (step-by-step guide)
  - REFCARD-PROMPTS.md (quick reference)
  - VHS-TAPE-STYLE-GUIDE.md (complete standards)
  - Demo course v6.1.0 with prompts + lesson plans + macros

**Combined Stats:** 67 files, +9,012 / -44 lines

---

### v6.1.0 - Template Management & Lesson Plan Migration (2026-01-28)

**Released:** 2026-01-28
**Changes:** 88 commits, 51 files changed, +12,341 / -1,977 lines

**Major Features:**

- **Template Management** (`teach templates`) - Create content from reusable templates
  - `teach templates list` - View available templates by type/source
  - `teach templates new lecture week-05` - Create from template with variable substitution
  - `teach templates validate` - Check template syntax
  - `teach templates sync` - Update from plugin defaults
  - Variable substitution: `{{WEEK}}`, `{{TOPIC}}`, `{{COURSE}}`, `{{DATE}}`

- **Lesson Plan Migration** (`teach migrate-config`) - Extract embedded lesson plans
  - Separates course metadata from curriculum content
  - `--dry-run` preview, `--force` skip confirmation
  - Automatic backup creation
  - Backward compatible (old format still works with warning)

- **Token Age Bug Fix** - Correct Keychain metadata field for expiration calculation

- **API Documentation Phase 1** - Core libraries documented (26.1% coverage)
  - 9 libraries documented with 86 functions
  - MASTER-API-REFERENCE.md created

- **Documentation Improvements**
  - Tutorial 24: Template Management
  - Tutorial 25: Lesson Plan Migration
  - 14 broken anchor links fixed
  - 442 markdown lint violations fixed

**New Files:**

- `commands/teach-templates.zsh` (22KB)
- `commands/teach-migrate.zsh` (14KB)
- `lib/template-helpers.zsh` (15KB)
- `docs/tutorials/24-template-management.md`
- `docs/tutorials/25-lesson-plan-migration.md`
- `docs/reference/REFCARD-TEMPLATES.md`

---

### v6.1.0 - Token Automation Phase 1 (2026-01-23)

**Released:** 2026-01-23
**PR #292:** https://github.com/Data-Wise/flow-cli/pull/292 (MERGED)
**Changes:** 35 files, +13,546 / -187 lines

**Major Features:**

- Isolated token checks (--dot, --dot=TOKEN, --fix-token)
- Smart caching (5-min TTL, 80% API reduction, 85% hit rate)
- ADHD-friendly category menu with visual hierarchy
- Verbosity control (quiet/normal/verbose)
- Integration across 9 dispatchers

**Tests:** 54 comprehensive tests (96.3% pass rate)

**Performance:**

- 20x faster token checks (3s vs 60s)
- Cache checks: ~5-8ms (50% better than target)
- 80% API call reduction

---

### v6.1.0 - Intelligent Content Analysis (2026-01-22)

**Released:** 2026-01-22
**PR #291:** https://github.com/Data-Wise/flow-cli/pull/291
**Changes:** 58 commits, +39,228 / -1,750 lines

**Major Features:**

- Complete teach analyze system (Phases 0-5) with AI-powered insights
- Plugin optimization (load guards, display extraction, cache fixes)
- Documentation debt remediation (348 functions, 49.4% coverage)
- Enhanced prerequisite display with dependency tree visualization
- wt dispatcher passthrough fix

---

## Common Tasks

### Update Dispatcher

1. Edit `lib/dispatchers/<name>-dispatcher.zsh`
2. Update help function `_<name>_help()`
3. Test: `source flow.plugin.zsh && <name> help`
4. Update docs: `docs/reference/MASTER-DISPATCHER-GUIDE.md`

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
./scripts/release.sh 5.23.0

# Review changes
git diff

# Commit and tag
git add -A && git commit -m "chore: bump version to 5.23.0"
git tag -a v6.2.0 -m "v6.2.0"

# Push (requires PR for protected branch)
git push origin main && git push origin v6.2.0
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

**Last Updated:** 2026-02-03 (v6.4.0)
**Status:** Production Ready (v6.4.0)
