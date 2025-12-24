# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **ZSH Workflow Manager** - an ADHD-optimized CLI workflow system. The repo contains:

- Documentation for 183+ aliases and 108+ workflow functions
- CLI integration layer (Node.js adapters to ZSH functions)
- ADHD-optimized workflow guides
- Progress tracking and planning documents
- Cloud sync setup (Google Drive + Dropbox via symlinks)

**Important:** The actual ZSH configuration files live in `~/.config/zsh/` (separate location).

**Note:** Desktop app (Electron) was archived 2025-12-20 due to environment issues. See `docs/archive/2025-12-20-app-removal/` for details.

## Project Structure

| Directory                              | Purpose                                |
| -------------------------------------- | -------------------------------------- |
| `cli/`                                 | CLI integration layer (adapters + API) |
| `docs/`                                | All documentation (organized by type)  |
| `docs/archive/2025-12-20-app-removal/` | Archived Electron app code             |
| `config/`                              | Configuration files and backups        |
| `tests/`                               | Test suites for CLI                    |
| `scripts/`                             | Utility scripts (setup, sync, deploy)  |

## Key Files

| File                                | Purpose                                    |
| ----------------------------------- | ------------------------------------------ |
| `README.md`                         | Project overview and setup guide           |
| `PROJECT-HUB.md`                    | Strategic roadmap (P0-P6 phases)           |
| `.STATUS`                           | Daily progress tracking                    |
| `docs/user/WORKFLOWS-QUICK-WINS.md` | Top 10 ADHD-friendly workflows             |
| `docs/user/ALIAS-REFERENCE-CARD.md` | Complete alias reference                   |
| `cli/README.md`                     | CLI integration guide                      |
| `MONOREPO-COMMANDS-TUTORIAL.md`     | Beginner's guide to npm workspace commands |

## Actual Configuration Location

The ZSH configuration files are at:

```
~/.config/zsh/
├── .zshrc                    # Main config
├── functions.zsh             # Legacy functions
├── functions/
│   ├── adhd-helpers.zsh      # ADHD helper commands
│   ├── work.zsh              # Multi-editor work command
│   └── claude-workflows.zsh  # Claude Code workflows
├── tests/
│   └── test-adhd-helpers.zsh # Test suite (25 tests)
├── .zsh_plugins.txt          # Antidote plugins
└── .p10k.zsh                 # Powerlevel10k theme
```

## Key Alias Categories

- **Ultra-fast (1-char)**: `t` (test), `c` (claude), `q` (quarto preview)
- **Atomic pairs**: `lt` (load+test), `dt` (doc+test)
- **R package**: `rload`, `rtest`, `rdoc`, `rcheck`, `rcycle`
- **Claude Code**: `cc`, `ccc`, `ccplan`, `ccauto`, `ccyolo`
- **ADHD helpers**: `js` (just-start), `why` (context), `win` (dopamine log), `gm` (morning routine)

## Help System

```bash
ah              # Show all categories
ah r            # R package development
ah claude       # Claude Code aliases
ah git          # Git shortcuts
ah workflow     # Workflow functions
```

## Documentation Organization

The `/docs` directory is organized by purpose:

- **`docs/user/`** - User-facing guides (workflows, alias reference, tutorials)
- **`docs/reference/`** - Technical reference (command patterns, sync setup)
- **`docs/planning/`** - Active planning documents
  - `current/` - Current phase work (P4 optimization)
  - `proposals/` - Future proposals
- **`docs/implementation/`** - Implementation tracking by feature
  - `help-system/` - Help system overhaul
  - `alias-refactoring/` - Alias refactoring work
  - `workflow-redesign/` - Workflow redesign proposals
  - `status-command/` - Status command research
- **`docs/archive/`** - Historical decisions and completed work
- **`docs/ideas/`** - Ideas backlog (TODO items)

## Editing Guidelines

1. **Documentation changes**: Edit files in `docs/` subdirectories
2. **CLI adapters**: Add to `cli/adapters/`, see `cli/README.md`
3. **ZSH config changes**: Edit files in `~/.config/zsh/`, then update docs here
4. **Testing**:
   - CLI tests: `npm test` or `npm run test`
   - ZSH tests: `~/.config/zsh/tests/test-adhd-helpers.zsh`
5. **Config backups**: Stored in `config/backups/` before major changes

## Current Phase

- **P0-P5C (Complete)**: Core CLI system, ADHD helpers, integrations, CLI adapters
- **P5 Desktop App (Archived 2025-12-20)**: See `docs/archive/2025-12-20-app-removal/`
- **P6 (Next)**: CLI Enhancements
  - Enhanced status command (worklog integration)
  - Interactive TUI dashboard
  - Web-based dashboard (optional)

## Cross-Project Integrations

This project integrates with other dev-tools:

| Project                   | Integration                                                 |
| ------------------------- | ----------------------------------------------------------- |
| `zsh-claude-workflow`     | Shared `project-detector.zsh` for unified context detection |
| `iterm2-context-switcher` | Session-aware profiles (Focus mode on `startsession`)       |
| `apple-notes-sync`        | Dashboard shows workflow activity from `worklog`            |

**Key symlinks:**

```
~/.config/zsh/functions/project-detector.zsh → zsh-claude-workflow/lib/project-detector.sh
~/.config/zsh/functions/core-utils.zsh → zsh-claude-workflow/lib/core.sh
```

## Cloud Sync

Changes auto-sync via symlinks:

- Primary: `~/projects/dev-tools/flow-cli/`
- Google Drive: `~/Library/CloudStorage/GoogleDrive-.../My Drive/dev-tools/flow-cli`
- Dropbox: `~/Library/CloudStorage/Dropbox/dev-tools/flow-cli`
