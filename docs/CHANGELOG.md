# Changelog

All notable changes to flow-cli are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/), and this project adheres to [Semantic Versioning](https://semver.org/).

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
