# Changelog

All notable changes to flow-cli are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

---

## [5.15.0] - 2026-01-21

### Added

- **Comprehensive Help System** - Complete help system for all teach commands (#281)
  - 18 help functions covering all teach sub-commands
  - Progressive disclosure UX pattern
  - ADHD-friendly design principles
  - Contextual examples in every help message

- **Teaching Prompts Templates** - Claude Code prompts for statistics courses (#283)
  - `lecture-notes.md` - 20-40 page instructor lecture notes
  - `revealjs-slides.md` - RevealJS presentation generation
  - `derivations-appendix.md` - Mathematical derivation appendices
  - `README.md` - Template usage guide

- **Lecture-to-Slides Conversion** - Convert lecture notes to slides (#284)
  - `teach slides --from-lecture FILE` - Convert specific lecture file
  - `teach slides --week N` - Auto-detect lecture from config
  - `teach slides --dry-run` - Preview content analysis
  - LaTeX preservation (math expressions intact)
  - Multi-part week support

### Documentation

- **HELP-SYSTEM-GUIDE.md** - 800-line comprehensive guide
- **REFCARD-HELP-SYSTEM.md** - 450-line quick reference card
- **V-DISPATCHER-REFERENCE.md** - V/Vibe dispatcher documentation
- **ARCHITECTURE-OVERVIEW.md** - System architecture with Mermaid diagrams
- **DOCUMENTATION-COVERAGE.md** - Documentation coverage report

### Tests

- 77 tests passing (100%)

---

## [5.14.0] - 2026-01-19

### Added

- **Teaching Workflow v3.0 Phase 1** - Complete teaching workflow overhaul (#272)

  **Wave 1 - Foundation:**
  - `teach doctor` - Comprehensive environment health check
    - Dependency validation (yq, git, quarto, gh, examark, claude)
    - Config validation with schema checking
    - Git status verification (branch, remote, clean state)
    - Scholar integration checks
    - Flags: `--quiet`, `--json`, `--fix` (interactive install)
  - Help system enhancement - All 10 sub-commands now have `--help` with EXAMPLES
  - Removed standalone `teach-init` command (integrated into dispatcher)

  **Wave 2 - Backup System:**
  - Automated backup system with timestamped snapshots (`.backups/<name>.<YYYY-MM-DD-HHMM>/`)
  - Content-type retention policies (archive vs semester)
    - Assessments (exam/quiz/assignment): archive (keep forever)
    - Syllabi/rubrics: archive (keep forever)
    - Lectures/slides: semester (clean after semester end)
  - Interactive delete confirmation with file preview
  - Archive management for semester-end cleanup
  - 343 lines of backup helper functions

  **Wave 3 - Enhancements:**
  - Enhanced `teach status` - Added deployment status and backup summary sections
  - Deploy preview - Shows changes preview before PR creation (file list, diff viewer)
  - Scholar template selection - `--template` flag for output customization
  - Lesson plan auto-loading - Automatic `--context lesson-plan.yml` when present
  - `teach init` reimplementation:
    - `--config FILE` to load external configuration
    - `--github` to create GitHub repository automatically
    - Non-interactive mode for automation
    - Default config generation improvements

### Changed

- **BREAKING:** `teach-init` command removed (use `teach init` instead)
- `teach doctor` is now the primary environment validation command
- All teach sub-commands support `--help` flag with detailed examples
- Deploy workflow now includes preview step (can skip with `--direct-push`)

### Documentation

- **TEACHING-WORKFLOW-V3-GUIDE.md** - 25,000+ lines complete workflow guide
- **BACKUP-SYSTEM-GUIDE.md** - 18,000+ lines deep dive with API reference
- **TEACH-DISPATCHER-REFERENCE-v3.0.md** - 10,000+ lines command reference
- **REFCARD-TEACHING-V3.md** - Quick reference card for v3.0 features
- **TEACHING-V3-MIGRATION-GUIDE.md** - Complete v2.x → v3.0 upgrade guide
- **TEACHING-V3-WORKFLOWS.md** - 7 comprehensive Mermaid diagrams

### Tests

- 73 comprehensive tests (100% passing)
  - 45 automated tests (syntax, features, integration)
  - 28 interactive tests (human-guided QA)
- Test coverage: 100% of v3.0 features

### Migration

Users upgrading from v2.x should:
1. Replace `teach-init` with `teach init` in all scripts
2. Run `teach doctor` to validate environment
3. Review backup retention policies in config
4. See TEACHING-V3-MIGRATION-GUIDE.md for complete guide

---

## [5.13.0] - 2026-01-18

### Added

- **WT Workflow Enhancement** - Enhanced worktree management (#267)

  **Phase 1 - Enhanced wt Default:**
  - `wt` now shows formatted table with status icons and session indicators
  - `wt <project>` filters worktrees by project name
  - Status icons: ✅ active, 🧹 merged, ⚠️ stale, 🏠 main
  - Session detection: 🟢 active (<30m), 🟡 recent (<24h), ⚪ none

  **Phase 2 - pick wt Actions:**
  - Multi-select worktrees with Tab key for batch operations
  - Ctrl-X to delete selected worktree(s) with confirmation
  - Ctrl-R to refresh cache and show updated overview
  - Safe branch deletion: tries `-d` first, prompts for `-D` if needed

- **Teach/Scholar Enhancement** - 9 Scholar wrapper commands (#268)

  **Content Generation:**
  - `teach generate quiz` - Generate quizzes with `--style` and content flags
  - `teach generate exam` - Create comprehensive exams
  - `teach generate homework` - Create homework assignments
  - `teach generate lecture` - Generate lecture notes
  - `teach generate rubric` - Create grading rubrics
  - `teach generate syllabus` - Generate course syllabi
  - `teach generate slides` - Create presentation slides
  - `teach generate feedback` - Generate student feedback
  - `teach generate solution` - Create solution keys

  **Smart Defaults:**
  - Auto-detect current week from teach-config.yml
  - `--content-preset` for style bundles (minimal, standard, comprehensive, exam)
  - Content modifiers: `+math`, `-examples`, `+code`, `+diagrams`
  - Output formats: `--format md|pdf|docx|typst`

  **Interactive Features:**
  - `--interactive` wizard mode for step-by-step generation
  - `--revise` workflow for iterating on content
  - `--context` integration with course materials
  - YAML-driven lesson plans with `--lesson`

### Documentation

- **Scholar Enhancement Tutorial Series** - 3-part comprehensive guide
  - Getting Started (14 sections, installation → first generation)
  - Intermediate Guide (batch generation, revision workflow, YAML integration)
  - Advanced Guide (custom presets, MCP integration, automation)
- **8 GIF Demos** - Visual tutorials for all major workflows
- **API Reference** - 1,100+ lines of technical specifications
- **Architecture Diagrams** - Component interaction, data flow, state management

### Tests

- 45 teach/scholar tests (100% passing)
- 23 wt-enhancement tests (22 passing, 1 env issue)
- Performance fix: cached `git branch --merged` before loop

---

## [5.12.0] - 2026-01-17

### Added

- **Teaching Dates Automation** - Centralized date management (#260)
  - `teach dates sync` - Update all course dates from single config
  - `teach dates init` - Semester rollover wizard
  - `teach dates status` - Check date consistency
  - `teach dates validate` - Validate date configuration
  - Selective sync: `--assignments`, `--lectures`, `--syllabus`, `--file`
  - Dry-run mode for safe preview

- **Date Parser Module** - 620 lines, 8 functions
  - `_date_normalize()` - Convert any format to YYYY-MM-DD
  - `_date_add_days()` - Date arithmetic
  - `_date_parse_quarto_yaml()` - Extract YAML frontmatter
  - `_date_compute_from_week()` - Week + offset calculation
  - Cross-platform support (GNU/BSD date)

- **pick wt Support** - Worktree selection in project picker
  - Session indicators (🟢🟡⚪) in worktree list
  - Filter by project name
  - Frecency sorting for recent projects

### Documentation

- Teaching Dates Guide (1,885 lines)
- Date Parser API Reference (1,256 lines)
- Config Schema Reference (603 lines)
- Architecture documentation (960 lines)
- Updated Tutorial 14 with dates section

### Tests

- 94 tests total (100% passing)
  - 45 date-parser unit tests
  - 33 dispatcher unit tests
  - 16 integration tests

---

## [5.11.0] - 2026-01-16

### Added

- **Teaching + Git Integration** - Complete 5-phase git workflow for teaching projects (#257)

  **Phase 1 - Smart Post-Generation Workflow:**
  - Interactive commit prompts after content generation
  - Auto-generated commit messages with Scholar co-authorship
  - Three workflow options: Review in editor | Commit now | Skip
  - Optional push to remote

  **Phase 2 - Branch-Aware Deployment:**
  - `teach deploy` creates PRs from draft → main
  - Pre-flight checks (clean state, no conflicts, no unpushed commits)
  - Auto-generated PR bodies with commit lists and deploy checklists
  - Interactive rebase support for production conflicts

  **Phase 3 - Git-Aware teach status:**
  - `teach status` displays uncommitted teaching files
  - Interactive cleanup workflow (commit/stash/diff/skip)
  - Smart filtering of teaching content paths only

  **Phase 4 - Teaching Mode Configuration:**
  - New `workflow` section in teach-config.yml
  - `teaching_mode: true` - Streamlined auto-commit workflow
  - `auto_commit: true` - Auto-commit after content generation
  - `auto_push: false` - Safety: manual push control
  - Backward compatible (defaults to false)

  **Phase 5 - Git Initialization for Fresh Repos:**
  - `teach init --no-git` - Skip git initialization
  - Auto-initializes git repository for fresh projects
  - Creates teaching-specific .gitignore template
  - Sets up draft and main branches
  - Makes initial commit with conventional commits format
  - Offers GitHub repo creation via gh CLI

- **New git-helpers.zsh library** - 15+ git integration functions
  - `_git_teaching_commit_message()` - Generate conventional commits
  - `_git_teaching_files()` - Detect uncommitted teaching content
  - `_git_create_deploy_pr()` - Create deployment PRs
  - `_git_detect_production_conflicts()` - Conflict detection
  - `_git_generate_pr_body()` - Auto-generate PR descriptions

- **New .gitignore template** - Teaching-specific patterns
  - Quarto output directories (`/.quarto/`, `/_site/`)
  - Solution directories (`**/solutions/`, `**/answer-keys/`)
  - Student work (`submissions/`, `grades/`)
  - R/Python environments (renv, venv, __pycache__)
  - macOS artifacts (.DS_Store)

- **Configuration schema updates** - teach-config.yml
  - New `git` section (draft_branch, production_branch, auto_pr, require_clean)
  - New `workflow` section (teaching_mode, auto_commit, auto_push)
  - Full JSON schema validation support

### Fixed

- **teach-init --no-git template installation** - Now installs templates even when git is skipped
- **Teaching file detection** - `_git_teaching_files()` now detects individual untracked files (not just directories)

### Tests

- 16 integration tests (100% passing)
- `tests/simple-integration-test.zsh` - Fast verification suite
- `tests/integration-test-suite.zsh` - Comprehensive test suite
- Tests cover all 5 phases of git integration

### Documentation

- Updated `docs/reference/DISPATCHER-REFERENCE.md` - Complete teach dispatcher git features
- Added Phase 1-5 examples and workflows
- Added git configuration reference
- Updated CLAUDE.md with all phase completion statuses

---

## [5.4.1] - 2026-01-12

### Added

- **`teach` dispatcher** - Unified teaching workflow commands (#230)
  - `teach init` - Initialize teaching workflow (wraps teach-init)
  - `teach exam` - Create exam/quiz (wraps teach-exam)
  - `teach deploy` - Deploy draft → production
  - `teach archive` - Archive semester
  - `teach config` - Edit teach-config.yml
  - `teach status` - Show project status
  - `teach week` - Show current week number
  - Shortcuts: `i`, `e`, `d`, `a`, `c`, `s`, `w`

- **Non-interactive mode for teach-init** (`-y`/`--yes` flag)
  - Accept safe defaults without prompts
  - Strategy 1: In-place conversion (preserves history)
  - Auto-exclude renv/ from git
  - Skip GitHub push (push manually later)
  - Use auto-suggested semester dates

- **ADHD-friendly completion summary**
  - Visual box showing "What Just Happened"
  - Rollback instructions with exact commands
  - "Next Steps" section with work/deploy workflow

- **Help flags for workflow commands**
  - `work -h`, `work --help`, `work help`
  - `hop -h`, `hop --help`, `hop help`
  - `teach-init -h`, `teach-init --help`, `teach-init help`

### Fixed

- **Already-initialized detection** - `teach-init` now detects already-initialized projects and prevents re-migration errors (#228)

### Documentation

- New `docs/commands/teach.md` command reference
- Updated DISPATCHER-REFERENCE.md with teach dispatcher (#10)
- Updated REFCARD-TEACHING.md to v2.1
- 19 new tests for teach-init UX enhancements

---

## [4.9.1] - 2026-01-06

### Fixed

**Two critical UX bugs discovered during Phase 2 dogfooding:**

1. **Help Browser Preview Pane** - Fixed "command not found" errors
   - **Problem:** `flow help -i` preview pane showed "command not found: dash" instead of help text
   - **Root Cause:** fzf `--preview` runs in isolated subshell without plugin loaded
   - **Solution:** Created `_flow_show_help_preview()` helper function following existing pattern from `lib/tui.zsh`
   - **Files Changed:** `lib/help-browser.zsh` (+18 lines, -13 lines simplified)
   - **Tests Added:** `tests/test-help-browser-preview.zsh` (6 tests, all passing)
   - **Pattern:** Helper functions run in current shell, avoiding subshell isolation

2. **Missing `ccy` Alias** - Added to alias reference command
   - **Problem:** `flow alias cc` didn't show `ccy` (shortcut for `cc yolo`)
   - **Root Cause:** Alias defined in `cc-dispatcher.zsh` but not added to `alias.zsh`
   - **Solution:** Added `ccy` to both summary and detailed views, updated counts
   - **Files Changed:** `commands/alias.zsh` (updated counts 2→3, 28→29)
   - **Tests Added:** Updated Test 22 in `test-phase2-features.zsh`
   - **Prevention:** Added checklist for new alias additions

**Test Results:**
- All 47 tests passing
- 6 new preview tests + 1 updated alias test
- Full regression coverage maintained

**Documentation:**
- `BUG-FIX-help-browser-preview.md` (168 lines)
- `BUG-FIX-ccy-alias-missing.md` (171 lines)

---

## [4.8.1] - 2026-01-05

### Changed

- **Documentation overhaul** - Homebrew now the primary installation method (#165)
  - README.md: Homebrew moved to top with ⭐ designation
  - docs/index.md: Homebrew tab added first with "No shell config needed!" note
  - docs/getting-started/installation.md: Complete rewrite
    - Homebrew as first method with benefits list
    - "No reload needed" note for Homebrew users
    - Added Homebrew sections to Updating and Uninstalling
    - Added Homebrew-specific troubleshooting
  - docs/getting-started/faq.md: Added "How do I install flow-cli?" with Homebrew first
  - Better onboarding: One command (`brew install`) vs plugin manager configuration
  - Faster time-to-first-command: ~30 seconds vs ~5-10 minutes

---

## [4.5.5] - 2025-12-31

### Fixed

- **FLOW_VERSION sync** - `flow --version` now shows correct version (was stuck at 3.6.0)
- **Release script** - Now updates `flow.plugin.zsh` version automatically
- **Docs CI** - Added missing `mkdocs-exclude` plugin to workflow

### Changed

- **Homebrew formula** updated to v4.5.5
- **awesome-zsh-plugins PR** - [#2058](https://github.com/unixorn/awesome-zsh-plugins/pull/2058) submitted (all checks pass)

---

## [4.5.4] - 2025-12-31

### Added

- **Repo is now public** - curl install works for everyone
- **Homebrew formula** - `brew install Data-Wise/tap/flow-cli`
- **Uninstall script** - `curl .../uninstall.sh | bash`
- **awesome-zsh-plugins entry** - Ready to submit PR

---

## [4.5.3] - 2025-12-31

### Added

- **Version pinning for all install methods**
  - Antidote: `FLOW_VERSION=v4.5.0` → adds `Data-Wise/flow-cli@v4.5.0`
  - Zinit: `FLOW_VERSION=v4.5.0` → uses `zinit ice ver"v4.5.0"`
  - Oh-my-zsh/Manual: Git checkout after clone
- **28 unit tests** - Added 2 plugin manager version tests

---

## [4.5.2] - 2025-12-31

### Added

- **Version pinning** - Install specific versions with `FLOW_VERSION`
  - `FLOW_VERSION=v4.5.1 curl -fsSL .../install.sh | bash`
  - Works with oh-my-zsh and manual install methods
  - Graceful error if version tag not found
- **Alpine Linux support** - Docker tests now include Alpine 3.19/3.20
  - Smaller containers for faster CI
  - Package manager detection (apk vs apt-get)
- **26 unit tests** - Added 4 FLOW_VERSION tests

---

## [4.5.1] - 2025-12-31

### Added

- **Install script tests** - 22 unit tests for `install.sh`
  - Detection tests for all 4 plugin managers
  - Idempotency tests
  - Script validation tests
- **Docker integration tests** - End-to-end install testing
  - Ubuntu 22.04, 24.04
  - Debian Bookworm, Bullseye
  - Full plugin sourcing and command verification
- **CI improvements**
  - Install tests run on Ubuntu and macOS
  - Release workflow requires install tests to pass

---

## [4.5.0] - 2025-12-31

### Added

- **One-liner installer** - `curl -fsSL .../install.sh | bash`
  - Auto-detects plugin manager (antidote → zinit → oh-my-zsh → manual)
  - Idempotent installation (safe to run multiple times)
  - Color-coded output with quick start guide
- **Installation methods table** in README for easy comparison
- **Improved installation docs** with time estimates, checkpoints, and tabs

### Changed

- Rewrote `docs/getting-started/installation.md` with MkDocs Material tabs
- Added troubleshooting and uninstalling sections

---

## [4.4.3] - 2025-12-30

### Added

- **CI automation** - All 8 dispatcher tests now run in GitHub Actions
  - Ubuntu: 8 individual test steps for granular feedback
  - macOS: 7 combined + 1 separate (tm) step
  - TM tests use `continue-on-error` (requires aiterm)

### Changed

- Split tm dispatcher tests on macOS for graceful handling

---

## [4.4.2] - 2025-12-30

### Added

- **Complete dispatcher test coverage** - 85 new tests across 5 files
  - `test-r-dispatcher.zsh` (16 tests) - R package dev commands
  - `test-qu-dispatcher.zsh` (17 tests) - Quarto publishing
  - `test-mcp-dispatcher.zsh` (21 tests) - MCP server management
  - `test-tm-dispatcher.zsh` (19 tests) - Terminal manager
  - `test-obs-dispatcher.zsh` (12 tests) - Obsidian integration

### Changed

- All 8 dispatchers now have test coverage (cc, g, wt, mcp, r, qu, tm, obs)

---

## [4.4.1] - 2025-12-30

### Added

- **9 dispatcher reference pages** - Complete documentation for all dispatchers
  - CC-DISPATCHER-REFERENCE.md - Claude Code launcher
  - G-DISPATCHER-REFERENCE.md - Git workflows (452 lines)
  - MCP-DISPATCHER-REFERENCE.md - MCP server management
  - OBS-DISPATCHER-REFERENCE.md - Obsidian integration
  - QU-DISPATCHER-REFERENCE.md - Quarto publishing
  - R-DISPATCHER-REFERENCE.md - R package development
  - TM-DISPATCHER-REFERENCE.md - Terminal manager
  - WT-DISPATCHER-REFERENCE.md - Worktree management
  - Plus main DISPATCHER-REFERENCE.md overview

- **Tutorial 11** - TM Dispatcher tutorial

### Changed

- **CLAUDE.md** - Updated Active Dispatchers to 8 (added wt)
- **Cross-references** - All dispatcher pages linked with "See also"
- **aiterm integration** - Added links to aiterm MCP and flow-cli docs

---

## [4.4.0] - 2025-12-30

### Added

- **tm dispatcher** - Terminal manager (aiterm integration)
  - `tm title <text>` - Set tab/window title (instant, shell-native)
  - `tm profile <name>` - Switch iTerm2 profile
  - `tm ghost` - Ghostty theme/font management
  - `tm switch` - Apply terminal context
  - `tm detect` - Detect project context
  - Aliases: `tmt`, `tmp`, `tmg`, `tms`, `tmd`

---

## [4.3.1] - 2025-12-30

### Fixed

- **wt status** - Fixed color rendering (use `%b` format for ANSI escape sequences)

---

## [4.3.0] - 2025-12-30

### Added

- **cc wt status** - Show worktrees with Claude session info
  - 🟢 Recent session (< 24h), 🟡 Old session, ⚪ No session
  - Shows branch name and last session timestamp

- **wt prune** - Comprehensive worktree cleanup
  - Prunes stale worktree references
  - Removes worktrees for merged feature branches
  - `--branches` flag to also delete the merged branches
  - `--force` to skip confirmation, `--dry-run` to preview

- **wt status** - Show worktree health and disk usage
  - Shows all worktrees with status (active/merged/stale)
  - Displays disk usage per worktree
  - Provides cleanup suggestions

- **g feature status** - Show merged vs active branches
  - Lists stale branches (merged to dev)
  - Lists active branches with commit count
  - Shows age of each branch

- **g feature prune --older-than** - Filter by branch age
  - `--older-than 30d` - Only branches older than 30 days
  - `--older-than 1w` - Only branches older than 1 week
  - `--older-than 2m` - Only branches older than 2 months

### Changed

- **g feature prune** - Now asks for confirmation before deleting
  - `--force` flag to skip confirmation (for scripting)
  - Safer default behavior

---

## [4.2.0] - 2025-12-29

### Added

- **Worktree + Claude Integration** - `cc wt` commands
  - `cc wt <branch>` - Launch Claude in worktree (creates if needed)
  - `cc wt pick` - fzf picker for existing worktrees
  - `cc wt yolo|plan|opus|haiku <branch>` - Mode chaining
  - Aliases: `ccw`, `ccwy`, `ccwp`
  - `_wt_get_path()` helper in wt-dispatcher

- **Branch Cleanup** - `g feature prune`
  - Delete merged feature branches safely
  - `--all` flag to also clean remote tracking branches
  - `-n` dry run to preview changes
  - Never deletes main, master, dev, develop, or current branch

### Fixed

- ZSH path array conflict in tests (renamed `local path` → `local result_path`)

---

## [4.1.0] - 2025-12-29

### Added

- **Git Feature Branch Workflow**
  - `g feature start <name>` - Create feature branch from dev
  - `g feature sync` - Rebase feature onto dev
  - `g feature list` - List feature/hotfix branches
  - `g feature finish` - Push and create PR to dev
  - `g promote` - Create PR: feature → dev
  - `g release` - Create PR: dev → main

- **Workflow Guard**
  - Blocks direct push to main/dev branches
  - Shows helpful message with correct workflow
  - Override: `GIT_WORKFLOW_SKIP=1 g push`

- **Git Worktree Dispatcher** - `wt`
  - `wt` - Navigate to worktrees folder
  - `wt list` - List all worktrees
  - `wt create <branch>` - Create worktree for branch
  - `wt move` - Move current branch to worktree
  - `wt remove <path>` - Remove a worktree
  - `wt clean` - Prune stale worktrees

### Changed

- Established feature → dev → main branching workflow

---

## [4.0.1] - 2025-12-27

### Added

- Code coverage documentation
- CI performance monitoring
- Phase 3 documentation (tutorials, FAQ)

### Fixed

- Minor documentation fixes

---

## [4.0.0] - 2025-12-27

### Added

- **Unified Sync Command** - `flow sync` orchestrates all data synchronization
  - Smart sync detection (shows what needs syncing)
  - Individual targets: `session`, `status`, `wins`, `goals`, `git`
  - Dry-run mode: `flow sync all --dry-run`
  - Scheduled sync via macOS launchd
  - Skip git option: `--skip-git` for quick local sync

- **Dopamine Features** - ADHD-friendly motivation system
  - Win tracking with `win "accomplishment"`
  - Auto-categorization: 💻 code, 📝 docs, 👀 review, 🚀 ship, 🔧 fix, 🧪 test
  - Streak tracking with visual indicators
  - Daily goals: `flow goal set 3`
  - Weekly summaries: `yay --week`

- **Extended .STATUS Format**
  - `wins:` - Win count for current day
  - `streak:` - Consecutive work days
  - `last_active:` - Last activity timestamp
  - `tags:` - Project tags for filtering

- **Dashboard Enhancements**
  - `Ctrl-E` - Edit .STATUS file
  - `Ctrl-S` - Quick status update
  - `Ctrl-W` - Log a win
  - Watch mode: `dash --watch`

### Changed

- Version bump from 3.6.x to 4.0.0 (major feature release)

---

## [3.6.3] - 2025-12-27

### Added

- Unit tests for `_flow_status_get_field` and `_flow_status_set_field`
- Release automation script (`scripts/release.sh`)
- Architecture roadmap and v4.0.0 planning docs

### Fixed

- Pure ZSH implementation in `win` command (removed bash dependencies)
- Static badge for private repository README

### Changed

- Improved code quality from review feedback

---

## [3.6.2] - 2025-12-27

### Fixed

- CC dispatcher now passes project args to `pick` instead of `claude`
- Pick variants work correctly with project names

### Changed

- Updated CC dispatcher reference documentation

---

## [3.6.1] - 2025-12-27

### Fixed

- Minor bug fixes and stability improvements

---

## [3.6.0] - 2025-12-26

### Added

- **CC Dispatcher** - Claude Code launcher with smart defaults
  - `cc` - Launch Claude in current directory
  - `cc pick` - Pick project, then launch Claude
  - `cc <project>` - Direct jump to project
  - `cc yolo` - Launch in YOLO mode (skip permissions)
  - `cc plan` - Launch in Plan mode
  - `cc opus` - Launch with Opus model
  - `cc resume` / `cc continue` - Resume sessions

### Changed

- CC dispatcher default changed to launch in current directory
- Updated documentation for CC dispatcher patterns

---

## [3.5.0] - 2025-12-26

### Added

- **Dopamine Features Documentation**
  - Comprehensive guide for win tracking
  - Streak system explained
  - Goal setting workflow

- **Navigation Improvements**
  - Updated mkdocs navigation
  - Exclude patterns for internal docs

### Changed

- Synced command reference with v3.5.0 features
- CI dependency updates (actions/checkout, actions/setup-python, actions/setup-node)

---

## [2.0.0] - 2025-12-25

### Added

- MIT License for plugin publishing
- Public repository setup

### Changed

- Major restructuring for open source release

---

## [2.0.0-beta.1] - 2025-12-24

### Added

- Week 2 CLI enhancements complete
- Phase P6 implementation

---

## [2.0.0-alpha.1] - 2025-12-22

### Added

- Phase P5D Phase 3 complete
- Version and release package system

---

## Version History Summary

| Version | Date       | Highlights                                        |
| ------- | ---------- | ------------------------------------------------- |
| 4.0.1   | 2025-12-27 | CI improvements, Phase 3 docs                     |
| 4.0.0   | 2025-12-27 | Sync command, dopamine features, extended .STATUS |
| 3.6.x   | 2025-12-26 | CC dispatcher, pure ZSH fixes                     |
| 3.5.0   | 2025-12-26 | Dopamine docs, CI updates                         |
| 2.0.0   | 2025-12-25 | Open source release                               |

---

## Upgrade Guides

### Upgrading to 4.0.0

No breaking changes. New features are additive:

```bash
# New sync command
flow sync          # Check what needs syncing
flow sync all      # Sync everything

# New dopamine features
win "Fixed bug"    # Log accomplishment
yay                # View recent wins
flow goal set 3    # Set daily goal

# Extended .STATUS (optional fields)
## wins: 5
## streak: 7
## last_active: 2025-12-27
```

### Upgrading to 3.6.0

New CC dispatcher available:

```bash
cc          # Launch Claude here
cc pick     # Pick project → Claude
cc yolo     # YOLO mode
```

---

## What's Next (v4.3.0+)

See [V4.3-ROADMAP.md](planning/V4.3-ROADMAP.md) for detailed implementation plans.

**Planned Features:**

- `cc wt status` - Show worktrees with Claude session info
- `cc wt clean` - Remove worktrees for merged branches
- `g feature prune --force` - Skip confirmation
- `g feature prune --older-than` - Filter by age
- `g feature status` - Show merged/unmerged branches
- `wt prune` - Combined cleanup (worktrees + branches)
- `wt status` - Show worktree health

**Future Considerations:**

- Remote state sync
- Multi-device support
- Shared templates

---

## Links

- **Documentation:** https://data-wise.github.io/flow-cli/
- **Repository:** https://github.com/Data-Wise/flow-cli
- **Issues:** https://github.com/Data-Wise/flow-cli/issues
- **Roadmap:** [V4.3-ROADMAP.md](planning/V4.3-ROADMAP.md)
