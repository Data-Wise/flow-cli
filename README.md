# 🐚 ZSH Workflow Manager

**ADHD-optimized ZSH workflow tools with desktop app interface**

A comprehensive system for managing development workflows through both CLI and desktop app interfaces. Features 183+ aliases, 108+ functions, and smart context detection optimized for ADHD-friendly productivity.

---

## ⚡ Quick Start

### For CLI Users
**Read this first:** `docs/user/WORKFLOWS-QUICK-WINS.md`
**Look up aliases:** `docs/user/ALIAS-REFERENCE-CARD.md`
**Daily health check:** `docs/user/WORKSPACE-AUDIT-GUIDE.md`

### For App Developers
**Setup:** `./scripts/setup.sh`
**App docs:** `app/README.md`
**CLI integration:** `cli/README.md`

### Strategic Overview
**Project roadmap:** `PROJECT-HUB.md`
**Claude guidance:** `CLAUDE.md`
**Current status:** `.STATUS`

---

## 📁 Project Structure

```
zsh-configuration/
├── app/                          # Desktop application (Electron)
│   ├── src/                      # App source code
│   │   ├── main/                 # Main process
│   │   ├── renderer/             # UI layer
│   │   ├── preload/              # IPC bridge
│   │   └── shared/               # Shared utilities
│   ├── assets/                   # Icons, images
│   └── package.json
│
├── cli/                          # CLI integration layer
│   ├── adapters/                 # ZSH function wrappers
│   ├── api/                      # Node.js API for app
│   └── README.md
│
├── docs/                         # All documentation
│   ├── user/                     # User-facing guides
│   │   ├── ALIAS-REFERENCE-CARD.md
│   │   ├── WORKFLOWS-QUICK-WINS.md
│   │   └── ...
│   ├── reference/                # Technical reference
│   ├── planning/                 # Active planning docs
│   │   ├── current/              # Current phase work
│   │   └── proposals/            # Future proposals
│   ├── implementation/           # Implementation tracking
│   │   ├── help-system/
│   │   ├── alias-refactoring/
│   │   ├── workflow-redesign/
│   │   └── status-command/
│   ├── archive/                  # Historical docs
│   └── ideas/                    # Ideas backlog
│
├── config/                       # Configuration files
│   ├── claude/                   # Claude Code settings
│   ├── backups/                  # Config backups
│   └── examples/                 # Example configs
│
├── tests/                        # Test suites
│   ├── cli/                      # CLI integration tests
│   └── app/                      # App tests
│
├── scripts/                      # Utility scripts
│   ├── setup.sh                  # Initial setup
│   ├── sync-zsh.sh               # Sync with ~/.config/zsh/
│   └── deploy/                   # Deployment scripts
│
├── README.md                     # This file
├── PROJECT-HUB.md                # Strategic roadmap
├── CLAUDE.md                     # Claude Code guidance
├── .STATUS                       # Daily progress tracking
└── package.json                  # Monorepo config
```

---

## 🚀 Development Setup

### Prerequisites
- Node.js 18+ and npm 9+
- ZSH configuration at `~/.config/zsh/`
- macOS (for Electron app development)

### Installation

```bash
# Clone and setup
git clone <repo-url>
cd zsh-configuration

# Install all dependencies (root + app + cli)
npm run setup

# Start app in development mode
npm run dev

# Or work on specific components
cd app && npm run dev          # App development
cd cli && npm test             # Test CLI adapters
```

### Workspace Commands

```bash
npm run setup      # Initial setup (install deps)
npm run dev        # Start app development
npm run test       # Run all tests
npm run build      # Build app for distribution
npm run sync       # Sync ZSH functions
```

---

## 🔗 ZSH Configuration Integration

**Important:** The actual ZSH configuration files live at `~/.config/zsh/`. This repository:
- Documents the CLI workflows
- Provides a desktop app interface
- Integrates via the `/cli` adapter layer

### ZSH Config Location

```
~/.config/zsh/
├── .zshrc                    # Main config (840 lines)
├── functions.zsh             # Legacy functions (492 lines)
├── functions/
│   ├── adhd-helpers.zsh      # ADHD system (3034 lines)
│   ├── smart-dispatchers.zsh # Modern pattern (841 lines)
│   ├── work.zsh              # Work command (387 lines)
│   └── ... (13+ other files)
├── .zsh_plugins.txt          # Plugin list
└── .p10k.zsh                 # Powerlevel10k theme
```

### How CLI/App Integration Works

```
Desktop App → CLI API → Adapters → exec() → ZSH Shell → Functions
```

See `cli/README.md` for detailed integration guide.

---

## 🌐 Cross-Project Integrations

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

---

## ☁️ Cloud Sync

Changes auto-sync via symlinks:
- **Primary:** `~/projects/dev-tools/zsh-configuration/`
- **Google Drive:** `~/Library/CloudStorage/GoogleDrive-.../My Drive/dev-tools/zsh-configuration`
- **Dropbox:** `~/Library/CloudStorage/Dropbox/dev-tools/zsh-configuration`

See `docs/reference/SYNC-SETUP.md` for setup details.

---

## 📊 Project Status

### CLI System (P0-P4: Complete)
- ✅ **183 aliases** (7 conflicts resolved in P4B)
- ✅ **108 functions** (smart dispatchers implemented)
- ✅ **Help system** (Phase 1 complete, Phases 2-3 planned)
- ✅ **ADHD helpers** (full suite operational)
- ✅ **Cross-project integrations** (unified context detection)

### Desktop App (P5: In Progress)
- 🟡 **P5A:** Project reorganization ← **You are here**
- ⬜ **P5B:** Core UI components
- ⬜ **P5C:** CLI integration layer
- ⬜ **P5D:** Alpha release

### Success Metrics
- **95% cognitive load reduction** (6 categories vs 120 items)
- **60-80% faster commands** (mnemonic aliases)
- **ADHD-optimized** design patterns throughout
- **Shell startup:** 250ms → target 50ms (P4D optimization)
- **Project scans:** 400ms → target <10ms (P4D optimization)

---

## 📖 Documentation Navigation

### User Guides (Start Here)
- `docs/user/WORKFLOWS-QUICK-WINS.md` - Top 10 ADHD-friendly workflows
- `docs/user/ALIAS-REFERENCE-CARD.md` - Complete alias catalog
- `docs/user/WORKSPACE-AUDIT-GUIDE.md` - Daily health check procedures
- `docs/user/WORKFLOW-TUTORIAL.md` - Step-by-step workflow guide

### Developer Docs
- `app/README.md` - Desktop app architecture & development
- `cli/README.md` - CLI integration layer guide
- `PROJECT-HUB.md` - Strategic roadmap (P0-P5 phases)
- `CLAUDE.md` - Claude Code integration guide

### Technical Reference
- `docs/reference/INDEX.md` - Documentation index
- `docs/reference/CLI-COMMAND-PATTERNS-RESEARCH.md` - Command naming patterns
- `docs/reference/SYNC-SETUP.md` - Cloud sync configuration

### Planning & Implementation
- `docs/planning/current/` - Active phase work (P4 optimization)
- `docs/planning/proposals/` - Future proposals
- `docs/implementation/` - Implementation tracking by feature
- `docs/archive/` - Historical decisions and completed work
- `docs/ideas/` - Ideas backlog

---

## 🎯 Key Features

### CLI Features (Operational)
- **Ultra-fast shortcuts:** Single-letter commands (t, c, q)
- **Atomic pairs:** Combined commands (lt = load+test, dt = doc+test)
- **Smart dispatchers:** Context-aware pb/pv/pt commands
- **ADHD helpers:** js (just-start), why (context), win (dopamine log)
- **Session management:** work/finish with automatic tracking
- **Multi-editor support:** Emacs, VS Code, Cursor, Positron, RStudio

### App Features (Planned)
- **Dashboard:** Session status, quota, recent commands
- **Alias viewer:** Searchable reference with categories
- **Session control:** Start/end workflows with GUI
- **Workflow automation:** V/Vibe dispatcher integration
- **Focus mode:** ADHD-optimized minimal interface
- **Dopamine tracking:** Wins and celebrations visualized

---

## 🧪 Testing

```bash
# Run all tests
npm test

# Test specific workspace
npm test --workspace=app
npm test --workspace=cli

# CLI adapter tests
cd cli && npm test

# ZSH function tests (separate repo)
~/.config/zsh/tests/test-adhd-helpers.zsh
```

---

## 🛠️ Contributing

1. Follow ADHD-optimized design principles
2. Keep aliases mnemonic and meaningful
3. Test with actual ZSH integration
4. Update documentation in `/docs`
5. Run tests before committing

---

## 📄 License

MIT

---

**Last Updated:** 2025-12-16
**Status:** 🟢 CLI Operational | 🟡 App Development In Progress
**Current Phase:** P5A - Project Reorganization Complete
