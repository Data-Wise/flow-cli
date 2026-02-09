# Changelog

All notable changes to flow-cli will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [6.5.0] - 2026-02-08

### Added

- **Teach Doctor v2** — two-mode health check architecture (PR #360)
  - Quick mode (default, < 3s): CLI deps, R + renv, config, git (4 categories)
  - Full mode (`--full`): all 11 categories including per-package R checks, quarto ext, scholar, hooks, cache, macros, style
  - Health indicator (green/yellow/red dot) on `teach` startup from `.flow/doctor-status.json`
  - `--fix` flag with interactive renv vs system install choice for R packages
  - `--ci` flag for CI/CD: no color, key=value output, exit 1 on failure
  - `--json` flag for structured output
  - `--verbose` flag for detailed check information
  - `--brief` flag for summary-only output
  - Batch R package check (single `R --quiet --slave` call instead of N individual)
  - renv-aware: detects renv activation, reports package count from lockfile
- **Macro registry rename** — `cache.yml` → `registry.yml` with backwards compatibility
- **New test suites** — teach-doctor-unit (86 tests), e2e-teach-doctor-v2 (33 tests), dogfood-teach-doctor-v2 (43 tests)
- **New tutorial** — `docs/tutorials/32-teach-doctor.md` (Doctor v2 walkthrough)
- **New refcard** — `docs/reference/REFCARD-DOCTOR.md` (Doctor quick reference)
- **Demo course fixtures** — renv.lock, renv/activate.R, quarto lightbox extension for full doctor E2E coverage

### Fixed

- Standardized `teach analyze --help` to match help compliance conventions
- Standardized `teach deploy --help` to match help compliance conventions
- Spinner cleanup trap on unexpected exit (INT/TERM)
- Health indicator no longer auto-refreshes (removed latency from `teach` subcommands)
- Doc count consistency: "10 categories" → "11 categories" across all docs

### Changed

- Optimized CLAUDE.md for context efficiency (1212 to 287 lines)
- Test suite: 40/40 → 42/42 passing (2 new suites)

---

## [6.4.1] - 2026-02-04

### Added

- Deploy step progress bar with 5-step numbered display `[1/5]..[5/5]` in direct merge mode
- `_deploy_step()` helper with done/active/fail state icons
- Deployment summary box (Unicode) showing mode, files changed, duration, commit hash, URL
- `_deploy_summary_box()` helper for both direct merge and PR deploy modes
- New exports: `DEPLOY_FILE_COUNT`, `DEPLOY_INSERTIONS`, `DEPLOY_DELETIONS`, `DEPLOY_SHORT_HASH`
- 20 new tests (14 unit + 6 E2E) for progress bar and summary box

### Fixed

- Suppressed git checkout stdout noise during deploy steps (`>/dev/null 2>&1`)
- Added numeric guards to status dashboard arithmetic comparisons

---

## [6.4.0] - 2026-02-03

### Added

- **Teach Deploy v2** with direct merge mode (`--direct`/`-d`) for 8-15s deploys vs 45-90s PR workflow
- Smart commit messages auto-generated from changed file categories (content, config, style, data, deploy)
- Deploy history tracking in append-only `.flow/deploy-history.yml` with `teach deploy --history [N]`
- Forward rollback via `git revert` with `teach deploy --rollback [N]`
- Dry-run preview mode (`--dry-run`/`--preview`) for both direct merge and PR modes
- CI mode (`--ci`) with auto-detection from TTY and 18 CI guards on all interactive prompts
- Shared preflight checks extracted to `_deploy_preflight_checks()` with exported `DEPLOY_*` variables
- `.STATUS` auto-updates after deployment with deploy count, teaching week, and last deploy timestamp
- `lib/deploy-history-helpers.zsh` (185 lines) with 4 functions (append, list, get, count)
- `lib/deploy-rollback-helpers.zsh` (214 lines) with 2 functions (rollback, perform_rollback)
- 101 new tests (50 unit + 22 integration + 29 E2E) for deploy v2

### Removed

- Legacy `_teach_deploy()` (~313 lines) and `_teach_deploy_help()` (~85 lines) from teach-dispatcher.zsh

---

## [6.3.0] - 2026-02-03

### Added

- Teaching style consolidation: read `teaching_style:` and `command_overrides:` from `.flow/teach-config.yml`
- `lib/teach-style-helpers.zsh` with 4 helper functions for style resolution
- `teach style` / `teach style show` to display current teaching style config
- `teach style check` to validate teaching style configuration
- `teach doctor` "Teaching Style" section reporting source and config status
- Help compliance system: 9-rule automated validator (`flow doctor --help-check`) for all 12 dispatchers
- `lib/help-compliance.zsh` reusable compliance engine

### Changed

- All 12 dispatchers brought to full help compliance (box header, MOST COMMON, QUICK EXAMPLES, TIP, See Also)
- Color fallback pattern standardized to global `if [[ -z "$_C_BOLD" ]]` block
- `teach help` expanded with 26-alias shortcuts table and workflow examples

### Fixed

- cc-dispatcher scope bug in tests
- obs-dispatcher stale assertions in tests
- e2e-dot-safety sandbox guard

---

## [6.2.1] - 2026-02-02

### Added

- Help compliance checker: 9-rule automated validator for all 12 dispatcher help functions
- `flow doctor --help-check` validates against CONVENTIONS.md standards
- 356 new tests (14 core + 342 dogfooding suite with negative tests)

### Changed

- All 12 dispatchers standardized to full help compliance
- `mkdocs.yml`: removed deprecated `tags_file` option (Material 9.6+)
- `doctor --help-check` header migrated from `FLOW_COLORS[]` to `_C_*`

---

## [6.2.0] - 2026-02-02

### Added

- Website reorganization: reduced top-level navigation from 14 to 7 sections
- 11 new teaching docs (6 REFCARDs, 3 Guides, 2 Tutorials)
- Section landing pages with grid cards
- MkDocs Material tags plugin with 14 topic tags across ~39 pages
- Tags index page at `/tags/`
- Index page redesign with ADHD-friendly visual hierarchy
- Bidirectional cross-references added to 6 existing tutorials

### Fixed

- Resolved all 28 MkDocs build warnings (broken links, orphaned files)
- `pymdownx.emoji` extension for grid card rendering
- `attr_list` spacing fix for emoji rendering

### Removed

- 7 orphaned documentation files cleaned up

---

## [6.1.0] - 2026-02-01

### Added

- `teach validate --lint` Quarto-aware structural lint checking (pure ZSH, 340 lines, zero deps)
- 4 lint rules: `LINT_CODE_LANG_TAG`, `LINT_DIV_BALANCE`, `LINT_CALLOUT_VALID`, `LINT_HEADING_HIERARCHY`
- `--quick-checks` flag for Phase 1 rules only
- Custom validator plugin API integration
- Pre-commit hook integration (warn-only mode, never blocks commits)
- 41 tests (28 automated passing = 93.3%)
- ~5,600 lines of documentation (REFCARD, guide, tutorial, workflow, summary)

### Changed

- Removed emoji duplication in lint error messages
- Improved whitespace handling for tabs after backticks
- Enhanced regex portability for ZSH version compatibility

---

## [6.0.0] - 2026-01-31

### Added

- Preview-before-add (`dot add`) with file analysis, large file warnings, and auto-ignore suggestions
- Ignore pattern management (`dot ignore`) with add/list/remove/edit and deduplication
- Repository size analysis (`dot size`) with health indicators and cleanup suggestions
- Enhanced health checks (`flow doctor --dot`) with 9 comprehensive chezmoi validation checks
- Cross-platform support via `lib/platform-helpers.zsh` (BSD/GNU `find` and `du` wrappers)
- 170+ tests across 5 suites for safety features
- ~1,950 lines of documentation (user guide, refcard, architecture, API reference)

### Changed

- `dot add` now includes safety preview before adding to chezmoi
- `flow doctor` enhanced with `--dot` flag for chezmoi-only checks

---

## [5.23.0] - 2026-01-29

### Added

- `teach prompt` command with 3-tier resolution (Course > User > Plugin)
- `teach prompt list/show/edit/validate/export` subcommands
- Scholar auto-resolve: prompts automatically injected for every Scholar call
- VHS tape validation script (`scripts/validate-vhs-tapes.sh`)
- VHS tape style guide with standard templates and best practices
- 107 tests (62 unit + 33 E2E + 12 interactive)

### Changed

- Standardized font sizes to 18px across 21 teaching GIFs
- Fixed 133 ZSH syntax errors in 9 VHS tapes
- Optimized GIF file sizes (10.9% reduction: 2.48MB to 2.21MB)

---

## [5.22.1] - 2026-01-29

### Added

- `flow <dispatcher>` unified namespace for all 12 dispatchers
- `teach help` system brought to 100% CONVENTIONS.md compliance
- `teach plan` CRUD command for lesson plan weeks in `.flow/lesson-plans.yml`
- Auto-populate topics from `teach-config.yml`, sorted insertion, gap detection

### Fixed

- Stale test path in `automated-tests.sh` for archived `DISPATCHER-REFERENCE.md`

### Removed

- Dead code `_teach_lecture_from_plan()` and unused `--from-plan` flag

---

## [5.22.0] - 2026-01-29

_Tag exists but no separate release notes. Changes folded into v5.22.1._

---

## [5.21.0] - 2026-01-28

### Added

- `teach macros` command (list, sync, export) for LaTeX macro management
- 3 source format parsers (QMD, MathJax HTML, LaTeX) with 6 macro categories
- `latex_macros` config section in `teach-config.yml` schema
- `teach doctor` macro health section (source files, cache sync, unused detection)
- `teach templates` command (list, new, validate, sync) with 4 template types and 15 defaults
- `teach migrate-config` command for extracting lesson plans to separate YAML
- `teach init --with-templates` for course initialization with templates
- 54 macro parser tests + 560 template tests + 28 migration tests

### Fixed

- Token age calculation bug: `_dot_token_age_days()` now searches correct `icmt` Keychain field

---

## [5.20.0] - 2026-01-28

_Tag exists but no separate release notes. Changes folded into v5.21.0._

---

## [5.19.1] - 2026-01-27

### Fixed

- Line continuation syntax breaking `security add-generic-password` command
- User mismatch check skipped when old token was expired ("unknown")
- Token name mismatch during rotation (wizard now pre-fills name)
- Revocation message shows helpful guidance when old token user is unknown
- Password leakage prevention: suppress debug output in `dot secret list`

### Added

- Enhanced `dot secret list` with box format, type detection icons, and expiration status
- Backup token management with separate display section and cleanup commands
- 55 new tests (14 bug fix + 41 secret list)

---

## [5.19.0] - 2026-01-25

### Added

- Backend abstraction for secret storage: keychain/bitwarden/both via `FLOW_SECRET_BACKEND`
- Conditional Bitwarden dependency (only required when backend needs it)
- 67 tests (20 unit + 47 automated) for backend modes

### Changed

- Default storage backend changed from dual (Keychain + Bitwarden) to Keychain-only
- Faster token operations: no Bitwarden unlock prompt, no cloud sync overhead

---

## [5.18.0] - 2026-01-24

### Added

- Claude Code environment troubleshooting guide

### Fixed

- Tutorial auto-launch bug: fixed source detection using `ZSH_EVAL_CONTEXT`
- Fixed path resolution in dot dispatcher using `$FLOW_PLUGIN_DIR`
- Fixed 4 broken links in `docs/index.md`

---

## [5.17.0] - 2026-01-23

### Added

- Isolated token checks (`doctor --dot`, `--dot=TOKEN`, `--fix-token`)
- Smart caching system with 5-min TTL, 85% hit rate, 80% API reduction
- ADHD-friendly category menu with visual hierarchy and time estimates
- Verbosity control (`--quiet`/`--normal`/`--verbose`)
- Integration across 9 dispatchers (g push/pull, dash, work, finish, doctor)
- Cache manager: `lib/doctor-cache.zsh` (797 lines, 13 functions)
- 54 tests (30 unit + 22 E2E + 2 cache)

### Changed

- Token checks 20x faster (3s vs 60s) with smart caching

---

## [5.16.0] - 2026-01-22

### Added

- Intelligent content analysis (`teach analyze`) with full concept graph system (Phases 0-5)
- AI analysis integration: Bloom's taxonomy, cognitive load, teaching time estimates
- Slide optimization with break suggestions, key concepts, time estimates
- Batch analysis with parallel processing and SHA-256 caching
- 7 new library files (~6,800 lines) for concept extraction, analysis, and reporting
- Plugin optimization: self-protecting load guards, display layer extraction
- Documentation debt remediation: 348 functions documented (8.6% to 49.4% coverage)
- E2E test suite (29 tests) and interactive dog feeding test (10 gamified tasks)
- Demo course fixture (STAT-101, 11 concepts, 5 weeks) for testing
- 362+ tests for teach analyze (100% passing)

### Fixed

- `wt` dispatcher passthrough for lock/unlock/repair commands
- Test runner timeouts: 30s timeout mechanism prevents infinite hangs

---

## [5.15.1] - 2026-01-21

### Added

- System architecture documentation with 6 Mermaid diagrams
- V dispatcher reference documentation
- Core API reference (47 functions, 1,661 lines)
- Documentation coverage metrics report

---

## [5.15.0] - 2026-01-20

### Added

- Comprehensive help system: 18 help functions for all teach commands
- Progressive disclosure pattern: Quick Start, Options, Examples, Tips, See Also
- Help system guide (800 lines) and quick reference card (450 lines)
- 77 tests (100% passing)

---

## [5.14.0] - 2026-01-18

### Added

- Teaching Workflow v3.0: complete overhaul with 10 tasks across 3 waves
- `teach doctor` health check with dependency validation and `--fix` mode
- Automated backup system with timestamped snapshots and retention policies
- Enhanced `teach status` with deployment status, backup summary, course info
- Enhanced `teach deploy` with preview changes before PR creation
- Scholar integration: template selection, lesson plan auto-loading
- Reimplemented `teach init` with `--config`, `--github` flags
- 6 tutorial GIFs (5.7MB optimized) and 73 new tests

### Removed

- Standalone `teach-init` command (fully integrated into teach dispatcher)

---

## [5.12.0] - 2026-01-17

### Added

- Smart post-generation workflow: 3-option interactive menu after content generation
- `teach deploy` for draft-to-production deployment with pre-flight validation
- Git-aware `teach status` showing uncommitted teaching files
- Teaching mode (`workflow.teaching_mode`) for auto-commit after generation
- Enhanced `teach init` with complete git repo setup and teaching-specific .gitignore
- `lib/git-helpers.zsh` (311 lines, 20+ reusable git helper functions)
- 12 tests (100% passing)

---

## [5.11.0] - 2026-01-16

### Added

- 4 nvim/LazyVim tutorials: Quick Start, Vim Motions, LazyVim Basics, LazyVim Showcase
- Nvim quick reference card (411 lines, 1-page printable)
- ~2,900 lines of nvim documentation, 70-minute progressive learning path

---

## [5.10.0] - 2026-01-15

### Added

- macOS Keychain secret management (`dot secret add/get/list/delete`) with Touch ID
- Sub-50ms secret access vs 2-5s for Bitwarden

### Fixed

- `cc wt pick` PATH corruption from ZSH parameter expansion in while-read loops
- `cc wt pick` session status matching with emoji-prefixed values
- `cc wt pick` now scans `~/.git-worktrees/` globally instead of repo-scoped
- `dot unlock` stderr contamination from `bw unlock --raw 2>&1`
- PATH corruption in `work`/`hop` commands from ZSH `path` variable collision

---

## [5.3.0] - 2026-01-11

### Added

- Pick command test suite (39 tests) and CC dispatcher test suite (37 tests)
- Testing guide (710 lines) with patterns, mock setup, debugging strategies
- ADHD-friendly onboarding docs: troubleshooting, choose-your-path, quick reference card
- Branch workflow documentation (295 lines)
- Teaching workflow and project cache specs
- 76+ tests total across 8 suites (100% passing)

---

## [4.9.2] - 2026-01-06

### Fixed

- Help browser preview pane "command not found" errors in fzf isolated subshell
- Missing `ccy` alias in `flow alias cc` reference command

---

## [4.9.1] - 2026-01-06

_Bug fixes only. See v4.9.2._

---

## [4.8.1] - 2026-01-01

_Patch release. Changes folded into v4.8.0 notes._

---

## [4.8.0] - 2026-01-01

### Added

- Unified "mode first" pattern for CC dispatcher (`cc yolo wt <branch>`, `cc plan wt pick`)
- `ccy` alias for `cc yolo`
- Worktree workflow guide (650 lines)

### Changed

- CC dispatcher refactored with `_cc_dispatch_with_mode()` central dispatcher

---

## [4.7.0] - 2025-12-31

### Added

- iCloud remote sync (`flow sync remote init/disable`)
- Quarto Workflow Phase 2: profile management, parallel rendering (3-10x speedup), custom validators, advanced caching, performance monitoring
- 322 Phase 2 tests (100% passing)

### Fixed

- `pick` command "bad math expression" crash from non-numeric `wc` output

---

## [4.6.0] - 2025-12-31

### Added

- Quarto Workflow Phase 1 (Weeks 1-8): hooks, validation, cache, doctor, deploy, backup, status
- `teach validate` with YAML/syntax/render modes and watch mode
- `teach cache` interactive TUI for freeze cache management
- `teach doctor` comprehensive health validation (6 check categories)
- `teach deploy` with index management, dependency tracking, partial deployment
- `teach backup` with retention policies and archive management
- Enhanced `teach status` 6-section dashboard
- 296 tests (275 unit + 21 integration, 99.3% pass rate)

### Fixed

- Missing `_teach_dispatcher_help()` function
- Index link manipulation (3 broken functions)
- Dependency scanning macOS compatibility (`grep -oP` replaced with ZSH native regex)

---

## [4.5.0] - [4.5.5] - 2025-12-31

_Incremental pick command and worktree improvements. Frecency sorting, session indicators, worktree-aware pick._

---

## [2.0.0-beta.1] - 2025-12-24

### Added

- Enhanced status command with worklog integration and ASCII visualizations
- Interactive TUI dashboard with real-time refresh and keyboard shortcuts
- Advanced project scanning with in-memory caching (10x+ speedup)
- 4 ADHD-friendly tutorials (4,562 lines)
- Troubleshooting guide (691 lines)
- 270 new tests (559 total, 100% passing)

---

## [2.0.0-alpha.1] - 2025-12-22

### Added

- Help system: 20+ functions with `--help` flag support
- MkDocs documentation site (63 pages, 9 sections) at data-wise.github.io/flow-cli
- Architecture documentation (6,200+ lines across 11 files)
- Tutorial validation and link checker scripts
- Contributing guide (290 lines)

### Changed

- Alias system redesigned: 179 to 28 essential aliases (84% reduction)
- Project renamed from zsh-configuration to flow-cli

### Removed

- 151 low-frequency aliases (documented replacements provided)
- Desktop app (Electron code archived)

---

## [1.0.0] - 2025-12-14

### Added

- Initial stable release with 179 custom aliases
- ADHD-friendly workflow system with visual categorization
- R package development (50+ aliases), Git integration, Quarto processing
- Claude Code automation, file operations shortcuts, workflow tracking

---

_Releases prior to v1.0.0 predate this changelog._

[Unreleased]: https://github.com/Data-Wise/flow-cli/compare/v6.4.1...HEAD
[6.4.1]: https://github.com/Data-Wise/flow-cli/compare/v6.4.0...v6.4.1
[6.4.0]: https://github.com/Data-Wise/flow-cli/compare/v6.3.0...v6.4.0
[6.3.0]: https://github.com/Data-Wise/flow-cli/compare/v6.2.1...v6.3.0
[6.2.1]: https://github.com/Data-Wise/flow-cli/compare/v6.2.0...v6.2.1
[6.2.0]: https://github.com/Data-Wise/flow-cli/compare/v6.1.0...v6.2.0
[6.1.0]: https://github.com/Data-Wise/flow-cli/compare/v6.0.0...v6.1.0
[6.0.0]: https://github.com/Data-Wise/flow-cli/compare/v5.23.0...v6.0.0
[5.23.0]: https://github.com/Data-Wise/flow-cli/compare/v5.22.1...v5.23.0
[5.22.1]: https://github.com/Data-Wise/flow-cli/compare/v5.22.0...v5.22.1
[5.22.0]: https://github.com/Data-Wise/flow-cli/compare/v5.21.0...v5.22.0
[5.21.0]: https://github.com/Data-Wise/flow-cli/compare/v5.20.0...v5.21.0
[5.20.0]: https://github.com/Data-Wise/flow-cli/compare/v5.19.1...v5.20.0
[5.19.1]: https://github.com/Data-Wise/flow-cli/compare/v5.19.0...v5.19.1
[5.19.0]: https://github.com/Data-Wise/flow-cli/compare/v5.18.0...v5.19.0
[5.18.0]: https://github.com/Data-Wise/flow-cli/compare/v5.17.0...v5.18.0
[5.17.0]: https://github.com/Data-Wise/flow-cli/compare/v5.16.0...v5.17.0
[5.16.0]: https://github.com/Data-Wise/flow-cli/compare/v5.15.1...v5.16.0
[5.15.1]: https://github.com/Data-Wise/flow-cli/compare/v5.15.0...v5.15.1
[5.15.0]: https://github.com/Data-Wise/flow-cli/compare/v5.14.0...v5.15.0
[5.14.0]: https://github.com/Data-Wise/flow-cli/compare/v5.12.0...v5.14.0
[5.12.0]: https://github.com/Data-Wise/flow-cli/compare/v5.11.0...v5.12.0
[5.11.0]: https://github.com/Data-Wise/flow-cli/compare/v5.10.0...v5.11.0
[5.10.0]: https://github.com/Data-Wise/flow-cli/compare/v5.3.0...v5.10.0
[5.3.0]: https://github.com/Data-Wise/flow-cli/compare/v4.9.2...v5.3.0
[4.9.2]: https://github.com/Data-Wise/flow-cli/compare/v4.9.1...v4.9.2
[4.9.1]: https://github.com/Data-Wise/flow-cli/compare/v4.8.1...v4.9.1
[4.8.1]: https://github.com/Data-Wise/flow-cli/compare/v4.8.0...v4.8.1
[4.8.0]: https://github.com/Data-Wise/flow-cli/compare/v4.7.0...v4.8.0
[4.7.0]: https://github.com/Data-Wise/flow-cli/compare/v4.6.5...v4.7.0
[4.6.0]: https://github.com/Data-Wise/flow-cli/compare/v4.5.5...v4.6.0
[2.0.0-beta.1]: https://github.com/Data-Wise/flow-cli/compare/v2.0.0-alpha.1...v2.0.0-beta.1
[2.0.0-alpha.1]: https://github.com/Data-Wise/flow-cli/compare/v1.0.0...v2.0.0-alpha.1
[1.0.0]: https://github.com/Data-Wise/flow-cli/releases/tag/v1.0.0
