# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project Overview

**flow-cli** - Pure ZSH plugin for ADHD-optimized workflow management.

- **Architecture:** Pure ZSH plugin (no Node.js runtime required)
- **Dependencies:** **ZERO** - No dependencies on Oh-My-Zsh, antidote, or any framework
- **Current Version:** v5.19.0-dev (In Development)
- **Latest Release:** v5.19.0 (2026-01-23)
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
teach <cmd>   # Teaching workflow (teach analyze, teach init, teach deploy, teach exam)
prompt <cmd>  # Prompt engine switcher (prompt status, prompt toggle)
v <cmd>       # Vibe coding mode (v on, v off, v status)
```

**Get help:** `<dispatcher> help` (e.g., `r help`, `cc help`, `teach help`)

### Token Management (v5.19.0 Phase 1) ✨

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
- API Reference: `docs/reference/DOCTOR-TOKEN-API-REFERENCE.md`
- Architecture: `docs/architecture/DOCTOR-TOKEN-ARCHITECTURE.md`
- Quick Reference: `docs/reference/REFCARD-TOKEN.md`

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
│   ├── git-helpers.zsh       # Git integration utilities
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
├── tests/                   # Test suite (423 tests)
│   ├── fixtures/            # Test fixtures
│   │   └── demo-course/     # STAT-101 demo course for E2E
│   ├── e2e-teach-analyze.zsh           # E2E: 29 tests
│   └── interactive-dog-teaching.zsh    # Interactive: 10 tasks
└── .archive/               # Archived Node.js CLI
```

---

## Key Files

| File                                       | Purpose                  | Notes                     |
| ------------------------------------------ | ------------------------ | ------------------------- |
| `flow.plugin.zsh`                          | Plugin entry point       | Source this to load       |
| `lib/core.zsh`                             | Core utilities           | Logging, colors, helpers  |
| `lib/atlas-bridge.zsh`                     | Atlas integration        | Optional state engine     |
| `lib/keychain-helpers.zsh`                 | macOS Keychain secrets   | Touch ID support          |
| `lib/config-validator.zsh`                 | Config validation        | Schema + hash validation  |
| `lib/git-helpers.zsh`                      | Git integration          | Teaching workflow         |
| `lib/dispatchers/*.zsh`                    | Smart dispatchers        | 12 active dispatchers     |
| `commands/*.zsh`                           | Core commands            | work, dash, finish, etc.  |
| `docs/reference/DISPATCHER-REFERENCE.md`   | Complete dispatcher docs | All dispatchers           |
| `docs/reference/ARCHITECTURE-OVERVIEW.md`  | System architecture      | Mermaid diagrams          |
| `docs/reference/V-DISPATCHER-REFERENCE.md` | V/Vibe dispatcher docs   | Vibe coding mode          |
| `docs/reference/DOCUMENTATION-COVERAGE.md` | Coverage metrics         | 853 funcs, 49.4% coverage |
| `.STATUS`                                  | Current progress         | Sprint tracking           |

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

**Status:** ✅ 423 tests total
**Documentation:** [Complete Testing Guide](docs/guides/TESTING.md)

```bash
# Core test suites
tests/test-pick-command.zsh         # Pick: 39 tests
tests/test-cc-dispatcher.zsh        # CC: 37 tests
tests/test-dot-v5.19.0-unit.zsh     # DOT: 112+ tests
tests/test-teach-dates-unit.zsh     # Teaching dates: 33 tests
tests/test-teach-dates-integration.zsh  # Integration: 16 tests

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

| Document                                     | Purpose                   |
| -------------------------------------------- | ------------------------- |
| `docs/guides/DOPAMINE-FEATURES-GUIDE.md`     | Win/streak/goal features  |
| `docs/reference/DISPATCHER-REFERENCE.md`     | Complete dispatcher guide |
| `docs/reference/ALIAS-REFERENCE-CARD.md`     | All aliases               |
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

---

## Current Status

**Version:** v5.19.0-dev (In Development)
**Latest Release:** v5.19.0 (2026-01-23)
**Status:** Production - Documentation consolidation complete
**Branch:** `dev` (clean working tree, API docs 13.8% coverage)
**Release (latest):** https://github.com/Data-Wise/flow-cli/releases/tag/v5.19.0
**Performance:** Sub-10ms for core commands, 3-10x speedup from optimization
**Documentation:** https://Data-Wise.github.io/flow-cli/
**Tests:** 14 test suites + 54 token automation tests (100% core tests, 416+ total tests)

---

## Recent Releases

### v5.19.0 - Token Automation Phase 1 ✨ (2026-01-23)

**Released:** 2026-01-23
**PR #292:** https://github.com/Data-Wise/flow-cli/pull/292 (MERGED)
**PR #293:** https://github.com/Data-Wise/flow-cli/pull/293 (Release PR)
**Release:** https://github.com/Data-Wise/flow-cli/releases/tag/v5.19.0
**Changes:** 35 files, +13,546 / -187 lines

**Major Features:**

- Isolated token checks (--dot, --dot=TOKEN, --fix-token)
- Smart caching (5-min TTL, 80% API reduction, 85% hit rate)
- ADHD-friendly category menu with visual hierarchy
- Verbosity control (quiet/normal/verbose)
- Integration across 9 dispatchers (g, dash, work, finish, etc.)

**Command:** `commands/teach-analyze.zsh` (1,203 lines)

- 2,150+ lines across 4 comprehensive guides
- 11 Mermaid architecture diagrams
- Complete API reference (800+ lines)

**Tests:**

- 54 comprehensive tests (96.3% pass rate)
- Unit, E2E, cache, and interactive test suites

**Performance:**

- 20x faster token checks (3s vs 60s)
- Cache checks: ~5-8ms (50% better than target)
- 80% API call reduction

### v5.19.0 - Intelligent Content Analysis (2026-01-22)

**Released:** 2026-01-22
**PR #291:** https://github.com/Data-Wise/flow-cli/pull/291
**Release:** https://github.com/Data-Wise/flow-cli/releases/tag/v5.19.0
**Changes:** 58 commits, +39,228 / -1,750 lines

**Major Features:**

- Complete teach analyze system (Phases 0-5) with AI-powered insights
- Plugin optimization (load guards, display extraction, cache fixes)
- Documentation debt remediation (348 functions, 49.4% coverage)
- Enhanced prerequisite display with dependency tree visualization
- wt dispatcher passthrough fix

**Release Session (2026-01-22):**

- Enhanced prerequisite display with per-concept dependency trees
- Fixed concept extraction bugs (array-of-objects YAML, prerequisite merging)
- Fixed slide optimizer key concept extraction
- Updated documentation (REFCARD + API reference)
- Complete release workflow (version bump → PR → merge → tag → release)
- Post-release cleanup (.STATUS update, branch cleanup)

---

## Previous Milestones (2026-01-22)

### E2E and Interactive Test Infrastructure (commit ad4d4c5d)

**Created comprehensive test infrastructure for teach analyze:**

1. **E2E Test Suite** (`tests/e2e-teach-analyze.zsh`)
   - 29 automated tests across 8 sections
   - Setup, single file, validation, batch, slide optimization, reports, integration, extended cases
   - Uses demo course fixture (STAT-101)
   - 48% pass rate (expected - validates implementation readiness)

2. **Interactive Dog Feeding Test** (`tests/interactive-dog-teaching.zsh`)
   - 10 gamified tasks with ADHD-friendly mechanics
   - Dog hunger/happiness tracking (0-100)
   - Star rating system (0-5 ⭐)
   - User validation approach
   - Expected output shown before commands

3. **Demo Course Fixture** (`tests/fixtures/demo-course/`)
   - STAT-101: Introduction to Statistics
   - 11 concepts across 5 weeks (8 valid + 2 broken for error testing)
   - Proper Bloom taxonomy (Remember → Evaluate)
   - Cognitive load distribution (low/medium/high)
   - Prerequisite chains for dependency validation
   - Broken files: circular dependency, missing prerequisite

4. **Documentation**
   - `tests/E2E-TEST-README.md` - Complete E2E and interactive testing guide
   - `tests/fixtures/demo-course/README.md` - Demo course structure and usage
   - Updated `tests/run-all.sh` to include E2E tests

**Test Count:** 393 → 423 tests (+29 E2E, +1 interactive = +30 total)

### Documentation Update: Plugin Optimization Tutorial & Reference

- **Tutorial 22:** Plugin optimization step-by-step (`docs/tutorials/22-plugin-optimization.md`)
  - Load guard patterns
  - Display layer extraction
  - Cache path collision fixes
  - Test timeout mechanisms
- **Quick Reference:** Optimization patterns (`docs/reference/REFCARD-OPTIMIZATION.md`)
- **CHANGELOG.md:** Updated with teach analyze (PR #289), optimization (PR #290), and fixes
- **mkdocs.yml:** Added 2 new navigation entries

### Teach Analyze - Complete (PR #289 + #290)

**All Phases (0-5) Merged to dev:**

### Phase Summary

| Phase       | Feature                                           | Status | Tests |
| ----------- | ------------------------------------------------- | ------ | ----- |
| 0           | Concept extraction, prerequisite validation       | ✅     | ~65   |
| 1           | Integration (teach validate, teach status)        | ✅     | ~20   |
| 2           | Cache (SHA-256, flock), reports, interactive mode | ✅     | ~65   |
| 3           | AI analysis (claude CLI, cost tracking)           | ✅     | 55    |
| 4           | Slide optimizer (breaks, key concepts, timing)    | ✅     | 109   |
| 5           | Error handling, slide cache, dependency checks    | ✅     | 33    |
| Integration | teach slides --optimize pipeline                  | ✅     | 29    |

### Key Files

**Libraries (6):**

- `lib/concept-extraction.zsh` (446 lines) - YAML frontmatter parsing
- `lib/prerequisite-checker.zsh` (376 lines) - DAG validation
- `lib/analysis-cache.zsh` (1,383 lines) - SHA-256 cache with flock
- `lib/report-generator.zsh` (985 lines) - Markdown/JSON reports
- `lib/ai-analysis.zsh` (514 lines) - Claude CLI integration
- `lib/slide-optimizer.zsh` (627 lines) - Heuristic slide breaks

**Command:** `commands/teach-analyze.zsh` (1,203 lines)

**Documentation (5):**

- `docs/guides/INTELLIGENT-CONTENT-ANALYSIS.md` (user guide)
- `docs/reference/TEACH-ANALYZE-API-REFERENCE.md` (API docs)
- `docs/reference/TEACH-ANALYZE-ARCHITECTURE.md` (Mermaid diagrams)
- `docs/reference/REFCARD-TEACH-ANALYZE.md` (quick reference)
- `docs/tutorials/21-teach-analyze.md` (interactive tutorial)

---

## Recent Releases

### v5.19.0 (2026-01-21) - Documentation Updates

- Architecture overview with 6 Mermaid diagrams
- V-dispatcher reference documentation
- Documentation coverage report (853 functions, 8.6% documented)
- teach prompt command specs (paused for Scholar coordination)

### v5.19.0 (2026-01-21) - Architecture & Documentation

- Architecture overview with 6 Mermaid diagrams
- V-dispatcher reference documentation
- Documentation coverage report (853 functions, 8.6% → 49.4%)
- teach prompt command specs (paused for Scholar coordination)

### v5.19.0 (2026-01-21) - Comprehensive Help System

- 18 help functions for all teach commands
- 800-line Help System Guide
- 450-line Quick Reference Card
- Progressive disclosure UX pattern
- ADHD-friendly design principles
- PR #282 merged (38 commits, +66,767/-1,614 lines)

### v5.19.0 (2026-01-19) - Teaching Workflow v3.0 + Quarto Workflow

**Teaching Workflow v3.0:**

- teach doctor with 6 health check categories
- Automated backup system with retention policies
- Enhanced teach status with deployment info
- Scholar template selection
- teach init reimplemented with --config/--github flags

**Quarto Workflow Phase 1+2:**

- 3-10x parallel rendering speedup
- Custom validator framework
- Advanced cache management
- Performance monitoring dashboard
- 545+ tests (100% passing)

---

## Next Development Cycle (v5.19.0)

**Current:** v5.19.0-dev - Documentation consolidation complete, API coverage at 13.8%

**Completed in v5.19.0:**

- Documentation consolidation (66 → 7 master files)
- API documentation improvement (2.7% → 13.8%, +411% increase)
- Documentation health check (54 critical broken links fixed)
- Master documents created (MASTER-API-REFERENCE, MASTER-DISPATCHER-GUIDE, MASTER-ARCHITECTURE)

**Potential Focus Areas:**

- Continue API documentation (target: 80% coverage, currently 13.8%)
- Config → concept graph integration (Phase 1 enhancement)
- teach prompt command (needs Scholar coordination)
- Token automation Phases 2-4 (deferred - multi-token, gamification)
- Quarto workflow Phase 2 enhancements
- Additional teach analyze improvements

**Future Roadmap:**

- Installation improvements (curl one-liner)
- Remote state sync (optional cloud backup)
- Multi-device support
- Shared templates

---

## Common Tasks

### Update Dispatcher

1. Edit `lib/dispatchers/<name>-dispatcher.zsh`
2. Update help function `_<name>_help()`
3. Test: `source flow.plugin.zsh && <name> help`
4. Update docs: `docs/reference/DISPATCHER-REFERENCE.md`

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
./scripts/release.sh 5.13.0

# Review changes
git diff

# Commit and tag
git add -A && git commit -m "chore: bump version to 5.13.0"
git tag -a v5.19.0 -m "v5.19.0"

# Push (requires PR for protected branch)
git push origin main && git push origin v5.19.0
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

**Last Updated:** 2026-01-22
**Status:** Production Ready (v5.19.0)
