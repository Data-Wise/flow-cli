# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **documentation-only** repository for ZSH configuration. The actual configuration files live in `~/.config/zsh/`. This repo contains:
- Reference documentation for 120+ aliases and 22 workflow functions
- ADHD-optimized workflow guides
- Progress tracking files
- Cloud sync setup (Google Drive + Dropbox via symlinks)

## Key Files

| File | Purpose |
|------|---------|
| `WORKFLOWS-QUICK-WINS.md` | Top 10 ADHD-friendly workflows - start here |
| `ALIAS-REFERENCE-CARD.md` | Complete alias reference (R, Claude, Git, Quarto) |
| `PROJECT-HUB.md` | Strategic overview with P0/P1/P2 roadmap |
| `.STATUS` | Daily progress tracking |
| `SYNC-SETUP.md` | Cloud sync configuration |

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

## Editing Guidelines

1. **Documentation changes**: Edit files in this repo directly
2. **Configuration changes**: Edit files in `~/.config/zsh/`, then update documentation here
3. **Testing**: Run `~/.config/zsh/tests/test-adhd-helpers.zsh` after config changes
4. **Backups**: Use `backups/` directory for config snapshots before major changes

## Current Phase

- **P0 (Complete)**: Core aliases, help system, antidote fix
- **P1 (Complete)**: ADHD helpers, multi-editor work command
- **P2 (Complete)**: Context-aware suggestions, typo tolerance, workflow tracking
- **P3 (Complete)**: Cross-project integrations

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
