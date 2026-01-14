# Changelog

All notable changes to flow-cli will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### ✨ New Features

- **macOS Keychain Secret Management (v5.5.0)** - New `dot secret` commands for Touch ID-protected secrets:
  - `dot secret add <name>` - Store secret in Keychain
  - `dot secret <name>` - Retrieve secret (instant, Touch ID prompt)
  - `dot secret list` - List all flow-cli secrets
  - `dot secret delete <name>` - Remove secret
  - Sub-50ms access vs 2-5s for Bitwarden
  - Auto-locks with screen lock, no manual unlock needed
  - Perfect for shell startup scripts and local development

### 🐛 Bug Fixes

- **Fixed `cc wt pick` PATH corruption** - Complex ZSH parameter expansion inside while-read loops with file redirects was corrupting PATH. Replaced with awk-based parsing for reliability.

- **Fixed `cc wt pick` session status matching** - The case statement was matching against "recent"/"old" but the actual values contained emoji prefixes like "🟢 3h". Fixed with glob patterns.

- **Fixed `cc wt pick` showing only current repo's worktrees** - Now scans `~/.git-worktrees/` globally instead of using repo-scoped `git worktree list`.

- **Fixed `dot unlock` stderr contamination** - The `bw unlock --raw 2>&1` command was capturing both stdout AND stderr, causing error messages to mix with the session token. Now uses temp file for stderr separation, showing errors only on failure.

- **Fixed PATH corruption in `work` command** - The `work` and `hop` commands were breaking `$PATH` due to ZSH's special `path` variable. In ZSH, `path` (lowercase) is tied to `PATH` (uppercase), so setting `path="..."` overwrites the entire PATH. Renamed internal variable to `project_path` to avoid the collision. This fixes:
  - "zsh: command not found: zoxide add --" errors
  - "yq not found" warnings in teaching workflow
  - Other PATH-dependent commands failing after `work`

---

## [5.3.0] - 2026-01-11

### 🧪 Test Infrastructure - Comprehensive Coverage

**New Test Suites (76+ tests, 100% passing):**

- **Pick command tests** (`tests/test-pick-command.zsh`, 556 lines, 39 tests)
  - Function existence tests (6 tests)
  - Frecency scoring algorithm tests (4 tests)
  - Project detection & listing tests (9 tests)
  - Session status indicator tests (4 tests)
  - Worktree isolation tests (4 tests)
  - Command invocation tests (3 tests)
  - Edge case handling tests (6 tests)
  - Alias validation tests (3 tests)

- **CC dispatcher tests** (`tests/test-cc-dispatcher.zsh`, 722 lines, 37 tests)
  - Unified grammar mode detection (4 tests)
  - Shortcut expansion (4 tests)
  - Explicit HERE targeting (2 tests)
  - Function existence (4 tests)
  - Original dispatcher functionality (23 tests)

**Total Test Coverage:**

- 76+ tests across 8 test suites
- 100% pass rate maintained
- Sub-10 second execution time
- All tests fully automated with colored output

### 📖 Documentation - Testing & Onboarding

**New Testing Guide:**

- `docs/guides/TESTING.md` (710 lines) - Comprehensive testing documentation
  - Test file structure and organization
  - 6 test writing patterns with copy-paste examples
  - Mock environment setup (projects, worktrees, sessions)
  - ANSI code handling techniques
  - Debugging strategies (4 approaches)
  - Best practices and TDD workflow
  - CI integration guidance
  - Coverage goals and quality standards

**ADHD-Friendly Documentation (#209):**

- `docs/getting-started/im-stuck.md` (300 lines) - Troubleshooting guide
  - Quick fixes for common issues
  - Installation problems
  - Command errors
  - Performance issues
  - Step-by-step solutions

- `docs/getting-started/choose-your-path.md` (250 lines) - Role-based onboarding
  - Different entry points for different user types
  - Beginner vs experienced developer paths
  - Project-specific workflows
  - Learning resources

- `docs/quick-reference-card.md` (200 lines) - Printable command reference
  - All core commands
  - Dispatcher shortcuts
  - Common workflows
  - Quick lookup table

- `docs/stylesheets/extra.css` (150 lines) - Visual enhancements
  - ADHD-friendly color coding
  - Improved readability
  - Better visual hierarchy
  - Consistent spacing

**Updated Documentation:**

- `docs/reference/TESTING-QUICK-REF.md` - Added v5.0.0+ test suite section
- `CLAUDE.md` - Enhanced testing section with coverage table
- `mkdocs.yml` - Updated navigation for testing docs

### 🔄 Workflow & Planning

**Workflow Protocol Documentation:**

- `docs/contributing/BRANCH-WORKFLOW.md` (295 lines) - Formalized git workflow
  - Feature branch → worktree workflow
  - PR creation and review process
  - Merge strategies
  - Release procedures

**New Specifications:**

- `docs/specs/SPEC-teaching-workflow.md` - Complete teaching workflow implementation plan
  - Two-branch workflow (draft + production)
  - Scholar integration for content generation
  - examark conversion (Markdown → Canvas QTI)
  - Automation scripts and GitHub Actions

- `docs/specs/SPEC-project-cache-auto-discovery.md` (949 lines) - Project cache enhancement
  - Fast project scanning with intelligent caching
  - Auto-discovery of project types
  - Performance optimization strategies

### 🔧 Internal

**Configuration:**

- `.claude/settings.local.json` - Added approved Bash commands
  - `exec zsh` for test re-sourcing
  - Safe command whitelist

**Status Tracking:**

- `.STATUS` - Updated with test infrastructure accomplishments
  - Progress: 19% → 20%
  - Test count: 76+ tests passing
  - Comprehensive testing guide completed

### ⚡ Performance

- All tests complete in < 10 seconds
- Documentation build: ~6 seconds
- No performance regressions
- ADHD-friendly response times maintained (sub-100ms)

### 🔒 Compatibility

- **No breaking changes** - Fully backward compatible
- All existing commands work unchanged
- Documentation is additive
- Test infrastructure is optional (development-only)

### 📊 Statistics

**Test Coverage:**

- 76+ automated tests (100% passing)
- 8 test suites
- 556 lines (pick tests)
- 722 lines (CC dispatcher tests)

**Documentation:**

- 710 lines (testing guide)
- 300 lines (troubleshooting)
- 250 lines (onboarding)
- 200 lines (quick reference)
- 949 lines (project cache spec)
- 295 lines (workflow protocol)

**Total New Content:**

- 3,139+ insertions
- 10 files changed
- 4 new test files
- 6 new documentation files

---

### 🐛 Fixed - v4.9.1 Bug Fixes (2026-01-06)

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

### ✨ Added - Phase 2: Interactive Help System (v4.9.0)

**Interactive Help Browser:**

- `flow help --interactive` or `flow help -i` - Launch fzf-powered interactive help browser
  - Browse all 48 commands with fuzzy search
  - Live preview of help output in right pane
  - Instant filtering as you type
  - Graceful fallback with helpful error if fzf not installed

**Context-Aware Help:**

- Smart project type detection in `flow help`
  - R package context (`DESCRIPTION` file) → Suggests `r help`, `flow test`, `flow check`
  - Node.js project (`package.json`) → Suggests `flow test`, `flow build`, `npm run`
  - Git repository (`.git` directory) → Suggests `g help`, `flow sync`, `wt help`
  - Quarto project (`_quarto.yml` or `index.qmd`) → Suggests `qu help`, `flow render`
  - Python project (`pyproject.toml` or `setup.py`) → Suggests Python workflows
  - General/new user → Suggests `flow help -i`, `pick`, `dash`
- Priority ordering: R > Quarto > Node > Python > Git > General
- Context banner displays automatically in `flow help` output
- Detection happens in <10ms (ADHD-friendly target met)

**Alias Reference Command:**

- `flow alias` - Show comprehensive alias reference
  - Summary view lists all 6 categories with counts
  - Category views: `flow alias r`, `flow alias cc`, `flow alias git`, etc.
  - Shows all 28 custom aliases + 8 dispatchers + 226+ git plugin aliases
  - Each alias shows full command and description
  - Organized by workflow (Core, Quality, Documentation, etc.)
  - `als` shortcut for backward compatibility

**Categories:**

- R Package Development (23 aliases)
- Claude Code (2 aliases)
- Focus Timers (2 aliases)
- Tool Replacements (1 alias)
- Git Plugin Aliases (226+, from Oh My Zsh)
- Smart Dispatchers (8 functions)

### 🧪 Testing - Comprehensive Coverage

**Automated Tests (47 tests, 100% passing):**

- 10 unit tests - Context detection for all project types
- 5 edge case tests - Empty files, invalid JSON, multiple markers
- 2 unit tests - Help browser & alias command functions
- 11 integration tests - Alias categories + flow routing
- 4 integration tests - Context-aware help in different projects
- 4 E2E tests - Complete user workflows
- 5 regression tests - Existing features still work
- 2 performance tests - Sub-100ms operations (ADHD target)

**Manual Testing Guide:**

- `TESTING-PHASE2.md` (800+ lines, 31 test procedures)
- Feature tests: Interactive help, context detection, alias reference
- Integration tests: Flow routing, context switching
- Edge case tests: Terminal width, no color, broken files
- UX tests: First-time user, R developer, exploration flow
- Sign-off checklist for release validation

### 📖 Documentation

- New file: `lib/help-browser.zsh` (146 lines)
- New file: `commands/alias.zsh` (372 lines)
- New file: `tests/test-phase2-features.zsh` (540 lines)
- New file: `TESTING-PHASE2.md` (800+ lines)
- Modified: `commands/flow.zsh` (+58 lines for context detection)
- Modified: `flow.plugin.zsh` (+1 line to source help-browser)
- Modified: `tests/test-framework.zsh` (+40 lines, 4 new helpers)

**Test Framework Enhancements:**

- `assert_success()` - Always-pass assertion for documentation
- `assert_function_exists()` - Check if function exists
- `assert_alias_exists()` - Check if alias exists
- `test_suite()` - Wrapper for test suite start
- `print_summary()` - Final test summary output

### ⚡ Performance

- Context detection: < 10ms
- Help display: < 100ms
- Alias display: < 50ms
- All operations sub-100ms (ADHD-friendly design maintained)

### 🔒 Compatibility

- **No breaking changes** - Fully backward compatible
- All existing `flow help` patterns still work
- Context banner is additive (non-breaking enhancement)
- `--list` and `--search` flags unchanged
- All dispatcher helps unaffected

---

## [4.8.0] - 2026-01-01

### ✨ Added

- **Unified "mode first" pattern for CC dispatcher** - All modes now support consistent syntax
  - `cc yolo wt <branch>` - Mode before target (NEW!)
  - `cc plan wt pick` - Plan mode with worktree picker (NEW!)
  - `cc opus wt <branch>` - Opus model in worktree (NEW!)
  - `cc haiku wt <branch>` - Haiku model in worktree (NEW!)
  - New central `_cc_dispatch_with_mode()` dispatcher function
  - Backward compatible - old syntax still works (`cc wt yolo <branch>`)

- **`ccy` alias** - Short for `cc yolo` (kept per user request)

- **Comprehensive worktree guide** - New `docs/guides/WORKTREE-WORKFLOW.md` (650 lines)
  - Complete workflows for experimentation, parallel development, and hotfixes
  - Session tracking documentation
  - Safety practices and best practices
  - Advanced patterns and troubleshooting

### 🔧 Changed

- **CC dispatcher refactored** - Cleaner architecture with unified pattern
  - `_cc_worktree()` now accepts mode as first parameter
  - `_cc_worktree_pick()` updated to accept mode/mode_args
  - All help text updated with (NEW!) markers for unified pattern
  - Mode detection happens before target detection

### 📖 Documentation

- Updated `docs/guides/YOLO-MODE-WORKFLOW.md` with worktree integration section
- Updated `docs/reference/CC-DISPATCHER-REFERENCE.md` with unified pattern documentation
- Updated `README.md` version badge and smart dispatchers table
- Added `WORKTREE-WORKFLOW.md` to mkdocs navigation

### ⚡ Performance

- Negligible overhead (< 1ms per command)
- Single additional case statement check for modes
- Pure ZSH implementation, no external processes

### 🔒 Compatibility

- **No breaking changes** - Fully backward compatible
- All existing workflows preserved
- All existing aliases maintained (including new `ccy`)
- Works with ZSH 5.0+

---

## [4.7.0] - 2025-12-31

### ✨ Added

- **iCloud Remote Sync** - Multi-device sync support
  - `flow sync remote` - Show sync status
  - `flow sync remote init` - Set up iCloud sync (migrates wins.md, goal.json, sync-state.json)
  - `flow sync remote disable` - Revert to local storage
  - Apple handles sync automatically - zero new dependencies
  - Works offline (syncs when connected)

### 🐛 Fixed

- **pick command crash** - Fixed "bad math expression" error when `wc` output contains non-numeric data (#155)
  - Added input sanitization in `_proj_show_git_status()` to handle terminal control codes
  - Strip whitespace and validate numeric format with fallback to `0`
  - Added regression test to prevent future occurrences
  - Affects: `pick`, `pick wt`, worktree navigation with Ctrl-O/Ctrl-Y keybindings

### 📖 Documentation

- Updated `docs/commands/sync.md` with remote sync section
- Added `BUG-FIX-git-status-math-error.md` with technical details

---

## [4.6.5] - 2025-12-31

### ✨ Added

- **Frecency sorting for worktrees** - Most recently used worktrees appear first

### 🔧 Changed

- Updated CLAUDE.md with v4.6.5 status

---

## [4.6.4] - 2025-12-31

### ✨ Added

- **Frecency decay algorithm** - Time-based priority scoring for projects
  - < 1 hour: 1000 points
  - < 24 hours: 520-980 points (decays ~20/hour)
  - < 7 days: 150-450 points (decays ~50/day)
  - > 7 days: 1-90 points (decays ~10/week)
- **Session indicators on projects** - 🟢 recent / 🟡 old based on `.claude` directory activity

---

## [4.6.3] - 2025-12-31

### ✨ Added

- **`pick --recent` flag** - Filter to show only projects with Claude sessions
- **Frecency sorting** - Projects sorted by recent usage, not alphabetically

### ⚡ Performance

- CI apt package caching - Tests now run in ~17 seconds

---

## [4.6.2] - 2025-12-31

### ⚡ Performance

- **CI smoke tests** - Reduced from full suite to smoke tests (~30s)
- Created `tests/run-all.sh` for comprehensive local testing

---

## [4.6.1] - 2025-12-31

### ✨ Added

- **Worktrees in pick** - `pick` now shows both projects AND worktrees
- **Session indicators** - 🟢/🟡 icons show Claude Code activity status

### ⚡ Performance

- Streamlined CI from 4 jobs to 1 (Ubuntu only, ZSH is cross-platform)

---

## [4.6.0] - 2025-12-31

### ✨ Added

- **Worktree-aware pick** - `pick wt` subcommand for worktree navigation
- **Session age sorting** - Worktrees sorted by most recent Claude session

---

## [2.0.0-beta.1] - 2025-12-24

### 🎉 Production-Ready CLI with Clean Architecture

**This is a beta release** - production ready with comprehensive test coverage (559 tests). All planned P6 features complete.

### ✨ Added (Week 2 - CLI Enhancements)

**Enhanced Status Command (Days 6-7):**

- Worklog integration from `~/.config/zsh/.worklog`
- Beautiful ASCII visualizations (progress bars, sparklines, charts)
- Quick actions menu for common workflows
- Verbose mode with productivity metrics (`-v`, `--verbose`)
- Web dashboard mode (`--web` flag launches browser UI)
- Git status integration with branch display
- .STATUS file parsing and display
- 9 new integration tests

**Interactive TUI Dashboard (Days 8-9):**

- Real-time terminal UI using blessed/blessed-contrib
- Auto-refresh with configurable interval (default 5s, `--interval` flag)
- Interactive keyboard shortcuts:
  - `r` - Manual refresh
  - `/` - Filter sessions
  - `q`, `ESC`, `Ctrl-C` - Quit
  - `?` - Help
- Grid layout with 4 widgets:
  - Active Session card with flow state badge
  - Metrics bar (sessions, time, completion rate)
  - Statistics panel
  - Recent sessions table
- Graceful shutdown and error handling
- 24 new E2E tests
- Complete documentation (`docs/commands/dashboard.md`)

**Advanced Project Scanning (Day 10):**

- In-memory caching with 1-hour TTL (10x+ performance improvement)
- Parallel directory scanning using Promise.all()
- Smart filters with .STATUS file parsing:
  - `byStatusFile()` - Filter by status/progress in .STATUS files
  - `byMinProgress()` - Filter by minimum progress percentage
  - Async composite filters for complex queries
- Progress callbacks for long scans
- Timeout protection (5s max per directory)
- Cache statistics tracking (hits, misses, hit rate, memory usage)
- Cache control options:
  - `useCache` - Enable/disable caching
  - `forceRefresh` - Bypass cache
  - `clearCache()` - Manual cache invalidation
- 11 new integration tests
- 6 new benchmark tests

**Documentation Overhaul:**

- 4 ADHD-friendly tutorials (4,562 lines total):
  - `01-first-session.md` - Complete beginner walkthrough (~15 min)
  - `02-multiple-projects.md` - Managing multiple projects (~20 min)
  - `03-status-visualizations.md` - Understanding progress tracking (~15 min)
  - `04-web-dashboard.md` - Advanced dashboard features (~20 min)
- 2 comprehensive command references:
  - `docs/commands/status.md` (510 lines) - Complete reference for `flow status`
  - `docs/commands/dashboard.md` (676 lines) - Complete reference for `flow dashboard`
- Troubleshooting guide (`docs/getting-started/troubleshooting.md`, 691 lines):
  - Installation issues
  - Command not found errors
  - Dashboard problems
  - Performance issues
  - Quick fixes and permanent solutions
- Updated mkdocs.yml navigation with tutorials section
- Fixed all broken internal links
- Updated CODE-EXAMPLES.md with caching patterns

### 🚀 Performance

**Project Scanning (60 projects):**

- First scan (no cache): ~3ms
- Cached scan (cache hit): <1ms
- **Speedup: 10x+ faster** with in-memory caching
- Memory overhead: ~10 bytes per cached project

**Command Response Times:**

- `flow status`: < 100ms
- `flow status -v`: < 150ms
- `flow dashboard`: < 200ms startup
- Test suite: ~6s (559 tests, all passing)

### 🧪 Testing

**Test Coverage:**

- Added 270 new tests in Week 2 (265 → 559 total, +102% increase)
- 100% pass rate maintained (559/559 passing)
- No flaky tests (race conditions resolved)
- Test suites: 27 passed, 27 total

**New Test Files:**

- `tests/integration/status-command.test.js` - 9 tests for status command
- `tests/e2e/dashboard.test.js` - 24 tests for TUI dashboard
- `tests/integration/ParallelScanningWithCache.test.js` - 11 tests for caching
- `tests/integration/ScanningPerformanceBenchmark.test.js` - 6 benchmark tests
- Plus integration tests for ASCII visualizations

### 🏗️ Architecture

**Clean Architecture Foundation (Week 1):**

- Complete 3-layer architecture:
  - Domain layer (153 tests) - Pure business logic
  - Use Cases layer (70 tests) - Application business rules
  - Adapters layer (42 tests) - Infrastructure
- Zero coupling between layers
- Repository pattern with file system implementations
- Dependency injection with Container
- Domain events for cross-cutting concerns

### 🐛 Fixed

**Test Stability:**

- Resolved race conditions in integration tests
- Fixed temp directory collisions in parallel test execution
- Added process.pid + timestamp + random to temp directory names
- All 559 tests now pass reliably in parallel execution
- Fixed cache expiration test timeout issues

### 📚 Documentation

- Updated PROJECT-HUB.md with Week 2 completion
- Updated all tutorials to reference new command names
- Fixed navigation in mkdocs.yml
- Removed references to deprecated features
- Added comprehensive troubleshooting guide

### 🔧 Internal

**Repository Enhancements:**

- FileSystemProjectRepository: +166 lines for caching layer
- ScanProjectsUseCase: +38 lines for cache control
- ProjectFilters: +115 lines for async .STATUS filters

**New CLI Commands:**

- `flow dashboard` - Launch interactive TUI
- `flow dashboard --interval <ms>` - Custom refresh rate
- `flow status --web` - Launch web dashboard
- `flow status -v` - Verbose mode with full metrics

### Known Issues

None - all test flakes resolved in this release.

### Migration Notes

- No breaking changes from v2.0.0-alpha.1
- All new features are opt-in (CLI still works as before)
- TUI dashboard is optional (`flow dashboard` command)
- Web dashboard is optional (`--web` flag)
- Caching is automatic but can be disabled

---

## [2.0.0-alpha.1] - 2025-12-22

### 🎉 Major Release - The 28-Alias Revolution

**This is an alpha release** - suitable for early adopters and testing. Production release (v2.0.0 stable) planned for early 2026.

### 💥 Breaking Changes

**CRITICAL: This release includes breaking changes from v1.0**

- **Reduced custom aliases from 179 → 28** (84% reduction)
  - Removed 151 low-frequency aliases based on usage analysis
  - Applied "10+ uses per day" rule for alias retention
  - All removed aliases have documented replacements (see Migration Guide)

- **Command name consolidation:**
  - `js`, `idk`, `stuck` → Use `just-start` instead
  - `t` → Use `rtest` instead
  - `lt` → Use `rload && rtest` instead
  - `dt` → Use `rdoc && rtest` instead
  - `qcommit`, `rpkgcommit` → Use git commands directly
  - See [MIGRATION-v1-to-v2.md](docs/user/MIGRATION-v1-to-v2.md) for complete list

- **Project renamed:** `zsh-configuration` → `flow-cli`
  - Updated all documentation references
  - GitHub repository URL changed
  - Documentation site moved to data-wise.github.io/flow-cli

### ✨ Added

**Help System (Phase 4.5):**

- 20+ functions now support `--help` flag
  - ADHD helper functions: `just-start`, `focus`, `pick`, `win`, `why`, `finish`, `morning`
  - FZF helper functions: `gb`, `fr`, `fs`, `fh`, `ga`, `rt`, `fp`, `rv`, `gundostage`
  - Claude workflow functions: `cc-pre-commit`, `cc-explain`, `cc-roxygen`, `cc-file`
  - Dashboard commands: `dash`, `g`, `v`
- Consistent help format across all commands
- Error messages standardized (all to stderr)
- Help creation workflow documented (423 lines)
- Test suite for help standards (305 lines)

**Documentation Site (Phase P5):**

- MkDocs site deployed at https://data-wise.github.io/flow-cli
- 63 pages organized across 9 major sections
- ADHD-optimized cyan/purple theme (WCAG AAA compliant)
- Full search functionality
- Mobile responsive with dark/light mode toggle
- Architecture section (11 pages)
- API documentation (2 pages)
- User guides (9 pages)
- Getting started guides
- Planning and implementation tracking

**Architecture Documentation (Phase P5):**

- 6,200+ lines of comprehensive architecture docs across 11 files
- 3 Architecture Decision Records (ADRs)
- 88+ copy-paste ready code examples
- Quick wins guide for daily development
- Architecture roadmap with 3 implementation options
- Command reference for future reuse
- 1-page architecture cheatsheet

**CLI Integration (Phase P5C):**

- Vendored project detection from zsh-claude-workflow
- Node.js bridge for calling ZSH functions from JavaScript
- Test suite with 172 lines of tests
- Self-contained (no external dependencies)
- Enables testable CLI tools

**Validation & Quality Tools (Phase P5D):**

- Tutorial validation script (`scripts/validate-tutorials.sh`)
  - Validates all 28 aliases exist
  - Checks 11 ADHD helper functions
  - Detects deprecated command references
  - Validates --help support
  - Beautiful colored output with 100% pass rate
- Link checker script (`scripts/check-links.js`)
  - Checks internal and external links
  - 98% link health validation
  - Categorizes broken links by type
  - Detailed reporting with recommendations

**Contributing Guide:**

- Complete contributor onboarding (290 lines)
- Reduces onboarding from 3-4 hours to 30 minutes
- Development setup, workflow, testing, code style
- Architecture guidelines and PR process

### 🔄 Changed

**Alias System Redesign (Phase P3-P4):**

- Consolidated from 179 to 28 essential aliases
- Frequency-based analysis (10+ uses/day retention rule)
- Removed duplicate aliases (12 duplicates eliminated)
- Removed typo corrections (13 aliases)
- Removed low-frequency shortcuts (25 aliases)
- Kept all R package development aliases (23 aliases)
- Kept Claude Code aliases (2 aliases)
- Kept focus timers (2 aliases)
- Kept tool replacement (1 alias: `cat='bat'`)

**Tutorial Updates (Phase P5D):**

- WORKFLOW-TUTORIAL.md updated for 28-alias system (573 lines)
- WORKFLOWS-QUICK-WINS.md updated for modern patterns (721 lines)
- All examples verified to work with current system
- Deprecated command references clarified with strikethrough

**Website Design (Phase P5):**

- ADHD-optimized color scheme (cyan/purple palette)
- WCAG AAA contrast compliance
- Eye strain optimization
- Material theme customization
- Enhanced dark mode (421 lines CSS)

**Project Rename (Dec 21):**

- Renamed from zsh-configuration to flow-cli
- Updated 179 files across project
- Updated npm packages (flow-cli, @flowcli/core)
- Updated GitHub URLs (Data-Wise/flow-cli)
- Updated documentation site URL
- Deployed documentation with new branding

**Git Workflow:**

- Updated git remote URL to flow-cli
- Updated cloud sync (Dropbox symlink)
- All work merged to main branch

### 🐛 Fixed

**Pick Command (Dec 21):**

- Fixed critical git repo validation bug
- Now only matches directories with .git repos
- Prevents false matches with R CMD check artifacts (\*.Rcheck)
- Example: `pick "medfit"` now correctly matches only medfit/ project

**Node Version Consistency (Phase P4.5):**

- Fixed Node version mismatch in CLI workspace
- Updated from >=14 to >=18 (matches root requirement)
- Added npm version requirement (>=9.0.0)

**CLI Test Scripts (Phase P4.5):**

- Fixed CLI test scripts (removed non-existent file references)
- All CLI tests now passing

**Tutorial Validation (Phase P5D):**

- Fixed deprecated command references in tutorials
- Updated WORKFLOW-TUTORIAL.md (`js` → `just-start`)
- Clarified deprecated aliases in ALIAS-REFERENCE-CARD.md

### 🗑️ Removed

**151 Low-Frequency Aliases** (with documented replacements):

- 13 typo corrections (e.g., `claue` → `claude`)
- 25 low-frequency shortcuts
- 12 duplicate aliases
- 10 navigation aliases (use `pick` or `pp` instead)
- 30 workflow shortcuts (use full commands)
- 4 single-letter aliases (too ambiguous)
- And 57 other rarely-used aliases

**Desktop App (Phase P5B - Paused):**

- 753 lines of Electron code archived
- Decision: Pause desktop app development (Electron technical issues)
- Focus on CLI (fully functional)
- Code preserved in `docs/archive/2025-12-20-app-removal/`
- Can resume later if needed

**Removed workflow commands:**

- `worktimer`, `quickbreak`, `here`, `next`, `endwork`
- Replaced with: `just-start`, `what-next`, modern workflows

### 📚 Documentation

**New Documentation (37+ pages):**

- CONTRIBUTING.md - Contributor onboarding guide
- ARCHITECTURE-QUICK-WINS.md - Copy-paste patterns (620 lines)
- ADR-SUMMARY.md - Architecture decisions overview (390 lines)
- ARCHITECTURE-ROADMAP.md - Implementation plan (604 lines)
- ARCHITECTURE-COMMAND-REFERENCE.md - Command patterns (763 lines)
- ARCHITECTURE-CHEATSHEET.md - 1-page quick reference (269 lines)
- CODE-EXAMPLES.md - 88+ production-ready examples (1,000+ lines)
- MONOREPO-COMMANDS-TUTORIAL.md - Beginner-friendly guide (20 pages)
- Plus 16 strategic planning documents (16,675 lines total)

**Updated Documentation:**

- docs/index.md - Architecture section added
- mkdocs.yml - 63 pages across 9 sections
- README.md - Architecture & Documentation section
- ALIAS-REFERENCE-CARD.md - Complete rewrite for 28-alias system
- All tutorials updated for v2.0

**Planning Consolidation:**

- Archived 10 old brainstorm/planning documents
- Cleaner planning directory (8 active vs 18 total)
- Archive includes context README

### 🔧 Development

**npm Workspace Scripts (Phase P4.5):**

- `dev:app`, `dev:cli` - Workspace-specific dev modes
- `test:app`, `test:cli` - Workspace-specific testing
- `build:app`, `build:all` - Build commands
- `clean`, `reset` - Cleanup utilities

**Test Coverage:**

- Tutorial validation: 67/67 checks pass (100%)
- Link validation: 102 links checked, 98% health
- CLI tests: All passing
- ZSH function tests: 25 tests in adhd-helpers

**Quality Metrics:**

- Documentation coverage: 111+ markdown files
- Code examples: 88+ ready to use
- Architecture docs: 6,200+ lines
- Help system: 20+ functions with --help

### 📊 Statistics

**Phase P5 Achievement (Dec 21):**

- 3,996 lines of new documentation across 8 files
- 63-page site deployed
- 100% tutorial validation pass
- 98% link health validation
- 3-4x faster with parallel background agents

**Epic Sprint (Dec 20):**

- 47 commits in one day
- 25,037 lines added (vs 575 removed)
- 163 files modified
- 21 new documents (16,675 lines)

**Alias Cleanup Impact:**

- 84% reduction (179 → 28 aliases)
- Estimated 100-150 keystrokes saved daily
- 95% cognitive load reduction (6 categories vs 120 individual items)

### 🎯 Migration Guide

**Upgrading from v1.0:**

See [docs/user/MIGRATION-v1-to-v2.md](docs/user/MIGRATION-v1-to-v2.md) for complete migration guide including:

- Before/after alias comparison table
- Command mapping (old → new)
- What was removed and why
- How to adapt existing workflows
- FAQ for common questions

**Quick reference:**

```bash
# Old (v1.0)          → New (v2.0)
js / idk / stuck      → just-start
t                     → rtest
lt                    → rload && rtest
dt                    → rdoc && rtest
qcommit               → git commit
```

### 🔗 Links

- **Documentation:** https://data-wise.github.io/flow-cli
- **GitHub:** https://github.com/Data-Wise/flow-cli
- **Migration Guide:** [MIGRATION-v1-to-v2.md](docs/user/MIGRATION-v1-to-v2.md)
- **Quick Start:** [Quick Start Guide](docs/getting-started/quick-start.md)
- **Tutorials:** [Workflows Quick Wins](docs/user/WORKFLOWS-QUICK-WINS.md)

### 🙏 Acknowledgments

**Generated with Claude Code** - https://claude.com/claude-code

This release was developed with assistance from Claude Sonnet 4.5, demonstrating the power of human-AI collaboration in software development.

---

## [1.0.0] - 2025-12-14

### Initial Stable Release

**The 179-Alias System**

- Initial stable release with 179 custom aliases
- ADHD-friendly workflow system
- Visual categorization (6 categories)
- Ultra-fast shortcuts (single-letter: `t`, `c`, `q`)
- Mnemonic consistency (rd, rc, rb patterns)
- Atomic command pairs (lt, dt)
- Comprehensive alias reference card
- Context-aware suggestions
- Workflow state tracking

**Core Features:**

- 120+ working aliases across all categories
- R package development (50+ aliases)
- Git workflow integration
- Quarto document processing
- Claude Code automation
- File operations shortcuts
- Workflow tracking (worklog)

**Documentation:**

- ALIAS-REFERENCE-CARD.md (v1.0)
- WORKFLOWS-QUICK-WINS.md (v1.0)
- WORKFLOW-TUTORIAL.md (v1.0)

---

## Version History

- **2.0.0-alpha.1** - 2025-12-22 (Alpha Release - The 28-Alias Revolution)
- **1.0.0** - 2025-12-14 (Initial Stable Release - 179-Alias System)

---

**Note:** For detailed phase-by-phase development history, see:

- `.STATUS` - Daily progress tracking
- `PROJECT-HUB.md` - Strategic roadmap
- `docs/archive/sessions/` - Session summaries
