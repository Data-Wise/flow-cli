# Changelog

All notable changes to flow-cli are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

---

## [7.4.0] - 2026-02-20

### Added

- **`em` organize commands** — `em star`, `em thread`, `em snooze`, `em digest` for inbox management (#402)
- **`em` manage commands** — `em delete`, `em move`, `em restore`, `em flag`, `em todo`, `em event` with `--pick` multi-select (#403)
- **10 email tutorials** — step-by-step guides for all em subcommands (tutorials 27-36)
- **fzf multi-select** — `{+1}` pattern across all em pick modes with indicator keybinds (`Ctrl-F` star, `Ctrl-M` move, `Ctrl-O` todo, `Ctrl-E` event)

### Fixed

- **jq type mismatch** — `_em_star` now uses `tonumber` for ID comparison
- **printf format injection** — `_em_move` uses `%s` format specifiers
- **AppleScript injection** — sanitized inputs in `_em_create_reminder` and `_em_create_calendar_event`
- **Dead code removal** — removed 686 lines of duplicate function definitions

---

## [7.3.0] - 2026-02-18

### Added

- **`em ai` subcommand** — Runtime AI backend switching (`em ai claude|gemini|none|auto|toggle`), status display, and live `FLOW_EMAIL_AI` mutation
- **`em catch` command** — Email-to-task capture with AI summary, subject-line fallback, and `catch` integration
- **`extra_args` support** — Configurable CLI flags per backend (e.g., Gemini's `-e none` for fast startup via `FLOW_EMAIL_GEMINI_EXTRA_ARGS`)
- **fzf picker integration** — `Ctrl-T` keybind in `em pick` to capture emails as tasks inline
- 22 unit tests (`test-em-ai-switch.zsh`), 9 unit tests (`test-em-catch.zsh`), 38 E2E tests (`em-ai-e2e-tests.sh`)

---

## [7.2.1] - 2026-02-16

### Changed

- **Testing overhaul** — migrated 134 test files from inline frameworks to shared `test-framework.zsh`; 14 assertion helpers, mock registry (`create_mock`/`assert_mock_called`/`reset_mocks`), subshell isolation (`run_isolated`)
- **Removed semantic-release** — manual releases via `gh release create` + `/craft:release`; removed 5 devDependencies and `.releaserc.json`

### Added

- **Dogfood scanner** (`tests/dogfood-test-quality.zsh`) — meta-test that catches 4 anti-pattern categories: permissive exit codes, existence-only tests, unused output captures, inline frameworks
- **test_pass double-counting guard** — prevents inflated pass counts when `test_fail` already fired for a test case
- **`with_env` scalar limitation note** — documents that ZSH arrays/assoc arrays need manual save/restore

### Removed

- `semantic-release`, `@semantic-release/*`, `conventional-changelog-conventionalcommits` devDependencies
- `.releaserc.json` configuration file
- Semantic release CI workflow reference from QUALITY-GATES.md

---

## [7.2.0] - 2026-02-16

### Changed

- **`work` command no longer auto-opens editor** — `work flow` now just cd's to project and shows context without launching an editor
- **New `-e`/`--editor` flag** — explicitly request an editor: `work flow -e` (uses `$EDITOR`), `work flow -e code` (VS Code), etc.
- **Claude Code editor modes** — `work flow -e cc` (acceptEdits), `-e ccy` (yolo), `-e cc:new` (new Ghostty window)
- **Positional editor arg deprecated** — `work proj nvim` still works but shows deprecation warning; use `work proj -e nvim` instead
- **New `_work_launch_claude_code()` function** — handles current terminal, new window, and yolo Claude Code modes

### Added

- 39 new tests in `tests/test-work.zsh` (70 total) — covers `-e` flag parsing, Claude Code modes, deprecation warning, help output, edge cases, `.STATUS` parsing, finish/hop help, teaching workflow, first-run welcome, token validation

### Documentation

- Updated `docs/commands/work.md` — new synopsis, `-e` flag, Claude Code editors, deprecation notice
- Updated `docs/help/QUICK-REFERENCE.md` — work command examples with `-e` flag

---

## [7.1.0] - 2026-02-14

### Changed

- **`dot` dispatcher split into 3 focused dispatchers** — `dots` (dotfiles/chezmoi), `sec` (secrets/Keychain/Bitwarden), `tok` (tokens/create/rotate/expire)
- **Internal function renames** — `_dot_*` shared helpers renamed to `_dotf_*`; dispatcher-specific functions use `_dots_*`, `_sec_*`, `_tok_*` prefixes
- **`flow doctor --dot` flag preserved** for backward compatibility
- **15 dispatchers total** (was 13) — `dot` replaced by `dots`, `sec`, `tok`
- Dispatcher count in docs, architecture diagrams, and CLAUDE.md updated to 15
- Test suite: 45/45 passing (186 test files)

### Added

- `docs/guides/MIGRATION-DOT-SPLIT.md` — complete migration guide with before/after command tables
- `docs/tutorials/12-dot-dispatcher.md` — rewritten for dots/sec/tok split

### Documentation

- Updated MASTER-ARCHITECTURE.md, MASTER-DISPATCHER-GUIDE.md, QUICK-REFERENCE.md, index.md for 15-dispatcher architecture

---

## [7.0.2] - 2026-02-12

### Added

- **Email doctor integration** — `flow doctor` now includes an EMAIL section when the `em` dispatcher is loaded
  - `_doctor_check_email()` — checks himalaya (required, version >= 1.0.0), w3m/lynx/pandoc (any-of), glow, email-oauth2-proxy, terminal-notifier, AI backend (claude/gemini)
  - `_doctor_check_email_cmd()` — per-dep checker with level tracking (required/recommended/optional/conditional)
  - `_doctor_email_connectivity()` — IMAP ping, OAuth2 proxy status, SMTP config validation (verbose mode, 5s timeout per test)
  - `_doctor_email_setup()` — guided himalaya config wizard with provider auto-detection (Gmail, Outlook, Yahoo, iCloud)
  - `_doctor_fix_email()` — install missing email brew/pip packages in fix mode
  - Conditional gate: EMAIL section only appears when `em()` function is loaded
  - Config summary: AI backend, timeout, page size, folder, config file path
  - Deduplication: shared deps (fzf, bat, jq) checked in earlier sections, skipped in email
- **Email category in fix mode menu** — `flow doctor --fix` includes "Email Tools" category with brew + pip install support
- **56 new test assertions** across 3 email doctor test suites:
  - `test-doctor-email.zsh` (13 tests) — function existence, conditional gates, tracking arrays, config summary, semver comparison
  - `test-doctor-email-e2e.zsh` (20 tests) — full E2E with PATH manipulation, fake binaries, isolated XDG config
  - `test-doctor-email-interactive.zsh` (23 tests) — headless interactive testing: confirm branching, menu selection, install simulation, guided setup wizard, cancel/edge cases

### Fixed

- **`_doctor_select_fix_category` crash** — `${[[ ... ]]}` inline plural pattern inside associative array assignments caused "bad output format specification" → replaced with pre-computed suffix variables for all 4 category_info lines (tokens, tools, aliases, email)

### Documentation

- Updated `docs/commands/doctor.md` — EMAIL dependency table, verbose connectivity section, fix mode email example, guided setup wizard, updated key functions list
- Updated `docs/reference/REFCARD-DOCTOR.md` — EMAIL category (#6→#11), email in fix mode menu, `--yes`/`-y` option, email integration entry

---

## [7.0.1] - 2026-02-12

### Added

- **Himalaya Neovim integration docs** — dedicated setup guide, tutorial, and quick reference for in-editor email with AI actions
- 3 himalaya test suites with file-existence guards for portability
- Cross-reference links between CLI and Neovim email documentation

### Fixed

- **MASTER-ARCHITECTURE.md** — added em dispatcher to diagram (was showing 12, now 13), added himalaya CLI to Layer 0 integrations
- **HIMALAYA-SETUP.md** — restored original CLI setup content that was overwritten by Neovim guide; Neovim content split to `HIMALAYA-NVIM-SETUP.md`

---

## [7.0.0] - 2026-02-12

### Added

- **Email dispatcher (`em`)** — 13th smart dispatcher for ADHD-friendly email management via himalaya CLI; 18 subcommands, 6-layer architecture, AI classify/summarize/draft, fzf picker, smart rendering, batch triage with `em respond`
- **Himalaya Neovim integration docs** — dedicated setup guide (`HIMALAYA-NVIM-SETUP.md`), tutorial (`33-himalaya-email.md`), and quick reference (`REFCARD-HIMALAYA.md`) for in-editor email with AI actions (summarize, draft reply, extract todos, compose)
- **Email nav section** — new `Email` top-level nav in mkdocs with CLI and Editor (Neovim) subsections
- 3 himalaya test suites — automated, headless keybind, and interactive tests with file-existence guards for portability

### Changed

- `HIMALAYA-SETUP.md` restored to CLI-only content (OAuth2, IMAP/SMTP, Keychain); Neovim content split to `HIMALAYA-NVIM-SETUP.md`
- Test suite: 45/45 passing (181 test files, up from 148)

---

## [6.7.1] - 2026-02-10

### Fixed

- **False positive production conflicts (#372)** — `_git_detect_production_conflicts()` now uses `--is-ancestor` fast path and `git log --no-merges` to ignore `--no-ff` merge commits from previous deploys; accumulated merge commits (60+ in STAT-545) no longer permanently block `teach deploy`
- **Three-dot diff syntax** — deploy preflight math check now uses `...` (symmetric difference) instead of `..` for correct "what's new on draft" semantics

### Added

- **Auto back-merge** — after `teach deploy --direct`, draft branch is automatically synced with production via fast-forward merge (step 6/6); prevents #372 recurrence
- **`teach deploy --sync`** — manual branch sync command: merges production into draft (ff-only first, falls back to regular merge)
- **`_deploy_commit_failure_guidance()` helper** — DRY extraction of 3-option commit failure message (replaces 3 duplicate blocks)
- **ZSH `always` block cleanup** — deploy body wrapped in `{ } always { _deploy_cleanup_globals }` for guaranteed global cleanup on all exit paths
- **7 dedicated conflict detection tests** — unit tests for `_git_detect_production_conflicts` covering merge commits, ancestry, back-merge, and accumulation scenarios
- **16 new E2E + dogfood test assertions** for back-merge sync, `--sync` flag, skip status, and three-dot diff verification

### Changed

- Direct merge deploy: 5 steps → 6 steps (new sync step)
- `_deploy_step()` now supports `skip` status for reporting skipped steps
- Test suite: 43/43 passing (144 test files, up from 143)

---

## [6.7.0] - 2026-02-10

### Added

- **Display math validation** — pure ZSH state machine (`_check_math_blanks`) detects blank lines and unclosed `$$` blocks in `.qmd` files (PR #368)
- **Pre-commit gate** — lint-staged validates `.qmd` files at commit time via `scripts/check-math.zsh`
- **Deploy preflight: math check** — display math validation runs as check 3 of 5 during `teach deploy`; CI mode blocks, interactive warns
- **Quality Gates documentation** — new `docs/guides/QUALITY-GATES.md` mapping every validation layer from keystroke to production
- **41 new test assertions** across 3 suites (unit, E2E with sandboxed repos, dogfood against demo course)

### Changed

- Deploy preflight checks renumbered: unpushed commits → check 4, production conflicts → check 5
- Test suite: 42/42 passing (143 test files, up from 140)

---

## [6.6.0] - 2026-02-09

### Added

- **Deploy safety: trap handler** — direct merge and PR modes now auto-return to draft branch on any error or signal (EXIT, INT, TERM)
- **Deploy safety: uncommitted changes prompt** — `teach deploy` with dirty tree offers smart commit-and-continue instead of blocking; CI mode fails fast with clear error
- **Deploy safety: pre-commit hook recovery** — 3-option actionable message on commit failure (fix & retry, skip validation with `QUARTO_PRE_COMMIT_RENDER=0`, force with `--no-verify`)
- **Deploy summary: GitHub Actions link** — deployment summary box now includes a direct link to GitHub Actions (supports SSH and HTTPS remotes)
- **7 new test assertions** for deploy safety features (trap handler, Actions URL variants, hook failure, dirty tree detection)

### Changed

- Pre-flight check no longer hard-fails on dirty working tree; delegates to new uncommitted changes handler
- Test suite: 42/42 passing (58 deploy-v2 unit tests, up from 50)

---

## [6.5.0] - 2026-02-08

### Added

- **Teach Doctor v2** — two-mode health check architecture (PR #360)
  - Quick mode (default, < 3s): CLI deps, R + renv, config, git (4 categories)
  - Full mode (`--full`): all 11 categories including per-package R checks, quarto ext, scholar, hooks, cache, macros, style
  - Health indicator (green/yellow/red dot) on `teach` startup
  - `--fix`, `--ci`, `--json`, `--verbose`, `--brief` flags
  - Batch R package check, renv-aware detection
- **Macro registry rename** — `cache.yml` → `registry.yml` (backwards compatible)
- **162 new test assertions** across 3 new suites (unit, e2e, dogfood)
- **New tutorial** — Doctor v2 walkthrough (`tutorials/32-teach-doctor.md`)
- **New refcard** — Doctor quick reference (`reference/REFCARD-DOCTOR.md`)

### Fixed

- Spinner cleanup trap on unexpected exit (INT/TERM)
- Health indicator auto-refresh removed (was adding latency)
- Doc count consistency: "10 categories" → "11 categories"

### Changed

- Test suite: 40/40 → 42/42 passing

---

## [6.4.3] - 2026-02-06

### Fixed

- **ZSH `local path=` bug** — `local path=` inside functions shadows ZSH's `$path` array (tied to `$PATH`), silently breaking all external command calls (yq, sed, jq, etc.). Renamed 20+ instances across lib/ and commands/ to safe names (`src_path`, `project_path`, `plugin_path`, etc.)
- **`teach style show` error** — "yq required" false error caused by the `local path=` shadowing bug
- **Missing teaching style config** — added `teaching_style` section to `.flow/teach-config.yml`

### Added

- **Regression test** — scans all production code for `local path=`, `for path in`, `local fpath=`, `local cdpath=` patterns (10 assertions)
- **Full-plugin dogfood test** — sources `flow.plugin.zsh` and verifies all 12 dispatchers, core commands, help output, library functions, plugin system, and runtime safety (56 assertions)
- **Core commands e2e test** — status CRUD, catch, win/yay, doctor, project type detection for Node/R/Python/Quarto (22 assertions)
- **Plugin system e2e test** — full lifecycle: create, install, list, dev-mode symlink, remove (18 assertions)
- **run-all.sh expanded** — 26 to 34 passing tests (8 new + 4 existing wired in)
- **Non-interactive test conversion** — converted 6 timeout tests (test-dash, test-work, test-doctor, test-adhd, test-flow, e2e-teach-analyze) to non-interactive sourcing pattern. Test suite now at 40/40 passing with 0 timeouts

---

## [6.4.2] - 2026-02-04

### Removed

- **54 orphaned doc pages** — planning archives, obsolete guides, duplicate tutorials, stale implementation notes (32,636 lines removed)

### Added

- **`docs/internal/` directory** — conventions and contributor templates organized into internal/
- **3 nav entries** — Doctor Token Guide, Prompt Dispatcher Guide, Date Automation tutorial

### Fixed

- 10 broken cross-references across testing, teaching, and help docs
- `mkdocs.yml` exclude globs updated for internal/ subdirectories

### Documentation

- CLAUDE.md updated with accurate file counts (62 lib, 31 commands, 126 test files)
- CHANGELOG.md rewritten to Keep a Changelog format (2442 → 576 lines)
- Zero MkDocs build warnings

---

## [6.4.1] - 2026-02-04

### Added

- **Deploy Step Progress** - 5-step progress indicator for direct merge mode
  - Replaces inline `[ok]` markers with numbered `[1/5]..[5/5]` steps
  - States: ✓ done, ⏳ active, ✗ fail
  - `_deploy_step()` helper function

- **Deployment Summary Box** - Post-deploy summary for both modes
  - Shows mode, files changed (+/-), duration, commit hash, site URL
  - Direct mode: site URL from config
  - PR mode: PR URL from GitHub API
  - `_deploy_summary_box()` helper function

### Fixed

- Git checkout stdout noise suppressed during deploy steps (`>/dev/null 2>&1`)

### Documentation

- Updated `REFCARD-DEPLOY-V2.md` output format section
- Updated `31-teach-deploy-v2.md` tutorial expected output
- Updated `TEACH-DEPLOY-GUIDE.md` with step progress and summary box

### Tests

- 20 new tests: 14 unit (step progress + summary box) + 6 E2E assertions

---

## [6.4.0] - 2026-02-03

### Added

- **Teach Deploy v2** (`teach deploy --direct`) - Direct merge deployment with 8-15s cycle time
  - `--direct` / `-d` - Direct merge deploy (draft → main, push)
  - `--dry-run` / `--dry` - Preview deploy without side effects
  - `--rollback [N]` / `--rb [N]` - Forward rollback via `git revert` (N=display index)
  - `--history` / `--hist` - View deploy history table
  - `--ci` - Non-interactive CI mode (auto-detected when no TTY)
  - `-m "message"` - Custom commit message
  - Smart commit messages - auto-categorize by file type (content, config, infra, deploy)
  - `.STATUS` auto-update - Sets `last_deploy`, `deploy_count`, `teaching_week`

- **Deploy History Tracking** (`.flow/deploy-history.yml`) - Append-only YAML history
  - Records timestamp, mode, commit hashes, branch, file count, user, duration
  - `yq`-based reading for list/get/count operations
  - YAML injection prevention via single-quote escaping

- **Deploy Rollback** - Forward rollback via `git revert`
  - Interactive picker or explicit index (`--rollback 1`)
  - Merge commit detection with `-m 1` parent specification
  - Rollback recorded in history with `mode: "rollback"`
  - CI mode requires explicit index (no interactive picker)

### Fixed

- Merge commit rollback now detects parent count and uses `git revert -m 1`
- `commit_before` captures target branch HEAD (not current branch)
- Dirty worktree guard prevents deploy with uncommitted changes
- Stderr capture pattern prevents silent failures (replaced `2>/dev/null` with `$(cmd 2>&1)`)
- Dead dry-run code path fixed (was unreachable due to wrong condition)
- `_deploy_cleanup_globals` prevents variable leakage between calls

### Documentation

- `docs/guides/TEACH-DEPLOY-GUIDE.md` (1,092 lines) - Complete user guide
- `docs/reference/REFCARD-DEPLOY-V2.md` (216 lines) - Quick reference card
- `docs/tutorials/31-teach-deploy-v2.md` (336 lines) - Step-by-step tutorial
- `docs/reference/MASTER-API-REFERENCE.md` - 14 new function entries

### Tests

- 81 new tests: 36 unit + 22 integration + 23 E2E
- 51-test dogfooding suite against demo-course fixture
- Merge commit rollback regression tests (diverged branches, parent detection)

---

## [5.20.0] - 2026-01-28

### Added

- **Template Management System** (`teach templates`) - Create content from reusable templates (#301, #302)
  - `teach templates list` - View available templates by type (content/prompts/metadata/checklists)
  - `teach templates new <type> <week>` - Create from template with variable substitution
  - `teach templates validate` - Check template syntax and variables
  - `teach templates sync` - Update project templates from plugin defaults
  - Variable substitution: `{{WEEK}}`, `{{TOPIC}}`, `{{COURSE}}`, `{{DATE}}`, `{{INSTRUCTOR}}`
  - Template types: content (.qmd starters), prompts (AI generation), metadata, checklists
  - Resolution order: Project templates override plugin defaults

- **Lesson Plan Migration** (`teach migrate-config`) - Extract embedded lesson plans (#298, #300)
  - Separates course metadata from curriculum content
  - Creates `.flow/lesson-plans.yml` from embedded `semester_info.weeks`
  - `--dry-run` - Preview migration without changes
  - `--force` - Skip confirmation prompt
  - `--no-backup` - Don't create `.bak` backup file
  - Automatic backup creation for safety
  - Backward compatible (old format works with deprecation warning)

### Fixed

- **Token Age Bug** - Correct Keychain metadata field for expiration calculation (#302)
  - Fixed `cdat` → `mdat` field usage for token creation date
  - Accurate expiration warnings for GitHub tokens

### Documentation

- **API Documentation Phase 1** (#303)
  - 9 core libraries documented with 86 functions
  - MASTER-API-REFERENCE.md created (26.1% coverage)
  - Documentation dashboard with coverage metrics

- **New Tutorials**
  - Tutorial 24: Template Management (430 lines)
  - Tutorial 25: Lesson Plan Migration (328 lines)

- **Reference Cards**
  - REFCARD-TEMPLATES.md - Template quick reference

- **Fixes**
  - 14 broken anchor links fixed across 10 files
  - 442 markdown lint violations resolved
  - Added Aliases section to MASTER-DISPATCHER-GUIDE.md

### Tests

- Template management test suite (560 lines)
- Lesson plan extraction test suite (954 lines)

---

## [5.15.1] - 2026-01-21

### Documentation

- **ARCHITECTURE-OVERVIEW.md** - System architecture with Mermaid diagrams (~365 lines)
- **V-DISPATCHER-REFERENCE.md** - V/Vibe dispatcher documentation (~275 lines)
- **DOCUMENTATION-COVERAGE.md** - Documentation coverage report with metrics
- Updated mkdocs.yml navigation for new reference docs
- Added teach prompt command specs (paused for Scholar coordination)

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
  - R/Python environments (renv, venv, **pycache**)
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

- Updated `docs/reference/MASTER-DISPATCHER-GUIDE.md` - Complete teach dispatcher git features
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
