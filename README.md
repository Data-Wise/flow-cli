# 🐚 ZSH Workflow Manager

**Minimalist ZSH workflow tools with smart dispatchers**

A streamlined system for managing development workflows. Features 28 essential aliases, 6 smart dispatchers, and 226+ git aliases (via plugin). Optimized for muscle memory over memorization.

**Recent updates:**

- **2025-12-23:** Hybrid Dashboard (CLI + Web) - Express server, WebSocket, Chart.js visualizations
- **2025-12-23:** Clean Architecture Foundation - Week 1 complete (265 tests, 19 files, 3-layer architecture)
- **2025-12-21:** Architecture Documentation Sprint - 7,629 lines of comprehensive architecture docs, site deployed
- **2025-12-19:** Alias cleanup - Reduced from 179 to 28 custom aliases (84% reduction)

---

## 🚀 Installation

**Quick install (2 commands):**

```bash
npm install
npm run install:cli
```

**Verify:**

```bash
flow --version
flow help
flow status
```

**Web Dashboard:**

```bash
flow status --web    # Opens browser with real-time dashboard
```

See [INSTALL.md](INSTALL.md) for detailed instructions and troubleshooting.

---

## ⚡ Quick Start

### For CLI Users

**Read this first:** `docs/user/WORKFLOWS-QUICK-WINS.md`
**Look up aliases:** `docs/user/ALIAS-REFERENCE-CARD.md`
**Daily health check:** `docs/user/WORKSPACE-AUDIT-GUIDE.md`

### For Contributors

**Start here:** [CONTRIBUTING.md](CONTRIBUTING.md) - Complete contributor onboarding guide
**Architecture:** [docs/architecture/](docs/architecture/) - System architecture & patterns
**Quick wins:** [docs/architecture/ARCHITECTURE-QUICK-WINS.md](docs/architecture/ARCHITECTURE-QUICK-WINS.md) - Copy-paste patterns

### For Developers

**Setup:** `./scripts/setup.sh`
**CLI tools:** `cli/README.md`
**Monorepo guide:** `MONOREPO-COMMANDS-TUTORIAL.md`

### Strategic Overview

**Project roadmap:** `PROJECT-HUB.md`
**Claude guidance:** `CLAUDE.md`
**Current status:** `.STATUS`

---

## 📁 Project Structure

```
flow-cli/
├── cli/                          # CLI integration layer (Clean Architecture)
│   ├── domain/                   # Business entities & rules (153 tests)
│   │   ├── entities/             # Session, Project, Task
│   │   ├── value-objects/        # SessionState, ProjectType, TaskPriority
│   │   ├── repositories/         # Repository interfaces
│   │   └── events/               # Domain events
│   ├── use-cases/                # Application workflows (70 tests)
│   │   ├── session/              # CreateSession, EndSession
│   │   ├── project/              # ScanProjects, GetRecentProjects
│   │   └── dashboard/            # GetStatus
│   ├── adapters/                 # Infrastructure (42 tests)
│   │   ├── repositories/         # FileSystem persistence
│   │   └── Container.js          # Dependency injection
│   ├── test/                     # Test suites (265 tests total)
│   └── README.md
│
├── docs/                         # All documentation (102 files)
│   ├── architecture/             # Architecture docs (11 pages)
│   │   ├── README.md             # Architecture hub
│   │   ├── ARCHITECTURE-QUICK-WINS.md  # Copy-paste patterns
│   │   ├── decisions/            # 3 ADRs (Architecture Decision Records)
│   │   └── ...
│   ├── api/                      # API documentation (2 pages)
│   ├── user/                     # User-facing guides (9 pages)
│   │   ├── ALIAS-REFERENCE-CARD.md
│   │   ├── WORKFLOWS-QUICK-WINS.md
│   │   └── ...
│   ├── reference/                # Technical reference (6 pages)
│   ├── planning/                 # Active planning docs
│   │   ├── current/              # Current phase work
│   │   └── proposals/            # Future proposals
│   ├── implementation/           # Implementation tracking
│   │   ├── help-system/
│   │   ├── alias-refactoring/
│   │   ├── workflow-redesign/
│   │   └── status-command/
│   ├── archive/                  # Historical docs
│   │   ├── 2025-12-20-app-removal/  # Archived Electron app
│   │   └── planning-brainstorms-2025-12/  # Archived brainstorms
│   └── ideas/                    # Ideas backlog
│
├── config/                       # Configuration files
│   ├── claude/                   # Claude Code settings
│   ├── backups/                  # Config backups
│   └── examples/                 # Example configs
│
├── tests/                        # Test suites (integration)
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
└── package.json                  # Package config
```

---

## 🚀 Development Setup

### Prerequisites

- Node.js 18+ and npm 9+
- ZSH configuration at `~/.config/zsh/`

### Installation

```bash
# Clone and setup
git clone https://github.com/Data-Wise/flow-cli
cd flow-cli

# Install dependencies
npm run setup

# Test CLI tools
npm run test
```

### Available Commands

```bash
npm run setup      # Initial setup (install deps)
npm run dev        # Run CLI in dev mode
npm run test       # Run CLI tests
npm run sync       # Sync ZSH functions
npm run clean      # Clean node_modules
npm run reset      # Clean and reinstall
```

---

## 🔗 ZSH Configuration Integration

**Important:** The actual ZSH configuration files live at `~/.config/zsh/`. This repository:

- Documents the CLI workflows
- Provides Node.js APIs for ZSH functions
- Contains comprehensive guides and references

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

### How CLI Integration Works

```
Node.js API → Adapters → exec() → ZSH Shell → Functions
```

See [cli/README.md](cli/README.md) for detailed integration guide.

---

## 🌐 Cross-Project Integrations

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

---

## ☁️ Cloud Sync

Changes auto-sync via symlinks:

- **Primary:** `~/projects/dev-tools/flow-cli/`
- **Google Drive:** `~/Library/CloudStorage/GoogleDrive-.../My Drive/dev-tools/flow-cli`
- **Dropbox:** `~/Library/CloudStorage/Dropbox/dev-tools/flow-cli`

See `docs/reference/SYNC-SETUP.md` for setup details.

---

## 🏗️ Architecture & Documentation

### Documentation Site

**Live site:** [https://Data-Wise.github.io/flow-cli/](https://Data-Wise.github.io/flow-cli/)

- 📚 **63 pages** organized across 9 major sections
- 🎨 **ADHD-optimized** cyan/purple theme (WCAG AAA)
- 🔍 **Search functionality** for all documentation
- 📱 **Mobile responsive** with dark/light mode

### Architecture Documentation (December 2025)

- ✅ **6,200+ lines** of comprehensive architecture documentation
- ✅ **3 ADRs** (Architecture Decision Records) explaining key decisions
- ✅ **88+ code examples** ready to copy-paste
- ✅ **Quick Wins guide** - Practical patterns for daily development
- ✅ **Clean Architecture** with 4-layer design (Domain, Use Cases, Adapters, Frameworks)

**Key documents:**

- [Architecture Hub](docs/architecture/README.md) - Complete overview
- [Architecture Quick Wins](docs/architecture/ARCHITECTURE-QUICK-WINS.md) - Copy-paste patterns
- [ADR Summary](docs/architecture/decisions/ADR-SUMMARY.md) - Executive overview of decisions
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contributor onboarding (30-minute path)

---

## 📊 Project Status

### CLI System (P0-P5C: Complete)

- ✅ **28 custom aliases** (down from 179 - 84% reduction)
- ✅ **226+ git aliases** (standard OMZ git plugin)
- ✅ **6 smart dispatchers** (context-aware functions)
- ✅ **108 workflow functions** (ADHD helpers implemented)
- ✅ **Help system** (Phase 1 complete, 20+ functions with --help)
- ✅ **Cross-project integrations** (unified context detection)
- ✅ **CLI integration layer** (Node.js adapters for ZSH functions)
- ✅ **Documentation site** (63 pages deployed to GitHub Pages)

### Future Enhancements (P6)

- 🔄 **Enhanced status command** (real-time worklog integration)
- 🔄 **Interactive TUI** (terminal dashboard)
- 🔄 **Web dashboard** (optional browser interface)

### Archived Projects

- 📦 **Desktop App** (Electron) - Archived 2025-12-20
  - See [docs/archive/2025-12-20-app-removal/](docs/archive/2025-12-20-app-removal/) for details
  - 753 lines of production-ready code preserved for potential future use

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
