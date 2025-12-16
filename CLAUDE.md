# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **ZSH Workflow Manager** - an ADHD-optimized workflow system with both CLI and desktop app interfaces. The repo contains:
- Documentation for 183+ aliases and 108+ workflow functions
- Desktop app source code (Electron-based)
- CLI integration layer (Node.js adapters to ZSH functions)
- ADHD-optimized workflow guides
- Progress tracking and planning documents
- Cloud sync setup (Google Drive + Dropbox via symlinks)

**Important:** The actual ZSH configuration files live in `~/.config/zsh/` (separate location).

## Project Structure

| Directory | Purpose |
|-----------|---------|
| `app/` | Desktop application (Electron) |
| `cli/` | CLI integration layer (adapters + API) |
| `docs/` | All documentation (organized by type) |
| `config/` | Configuration files and backups |
| `tests/` | Test suites for CLI and app |
| `scripts/` | Utility scripts (setup, sync, deploy) |

## Key Files

| File | Purpose |
|------|---------|
| `README.md` | Project overview and setup guide |
| `PROJECT-HUB.md` | Strategic roadmap (P0-P5 phases) |
| `.STATUS` | Daily progress tracking |
| `docs/user/WORKFLOWS-QUICK-WINS.md` | Top 10 ADHD-friendly workflows |
| `docs/user/ALIAS-REFERENCE-CARD.md` | Complete alias reference |
| `app/README.md` | Desktop app architecture |
| `cli/README.md` | CLI integration guide |

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
2. **App development**: Work in `app/` directory, see `app/README.md`
3. **CLI adapters**: Add to `cli/adapters/`, see `cli/README.md`
4. **ZSH config changes**: Edit files in `~/.config/zsh/`, then update docs here
5. **Testing**:
   - App tests: `npm test --workspace=app`
   - CLI tests: `npm test --workspace=cli`
   - ZSH tests: `~/.config/zsh/tests/test-adhd-helpers.zsh`
6. **Config backups**: Stored in `config/backups/` before major changes

## Current Phase

- **P0-P3 (Complete)**: Core CLI system, ADHD helpers, integrations
- **P4 (In Progress)**: Optimization (audit complete, conflicts identified)
- **P5 (Active)**: Desktop App Development
  - **P5A (Complete)**: Project reorganization ← Just completed!
  - **P5B (Next)**: Core UI components
  - **P5C (Planned)**: CLI integration layer implementation
  - **P5D (Planned)**: Alpha release

## Cross-Project Integrations

This project integrates with other dev-tools:

| Project | Integration |
|---------|-------------|
| `zsh-claude-workflow` | Shared `project-detector.zsh` for unified context detection |
| `iterm2-context-switcher` | Session-aware profiles (Focus mode on `startsession`) |
| `apple-notes-sync` | Dashboard shows workflow activity from `worklog` |

**Key symlinks:**
```
~/.config/zsh/functions/project-detector.zsh → zsh-claude-workflow/lib/project-detector.sh
~/.config/zsh/functions/core-utils.zsh → zsh-claude-workflow/lib/core.sh
```

## Cloud Sync

Changes auto-sync via symlinks:
- Primary: `~/projects/dev-tools/zsh-configuration/`
- Google Drive: `~/Library/CloudStorage/GoogleDrive-.../My Drive/dev-tools/zsh-configuration`
- Dropbox: `~/Library/CloudStorage/Dropbox/dev-tools/zsh-configuration`
