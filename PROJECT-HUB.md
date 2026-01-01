# ⚡ flow-cli - Project Control Hub

> **Quick Status:** 🎉 v4.7.0 Production | ✅ Pure ZSH Plugin | 📚 Docs Live | 🧪 23 Tests Passing

**Last Updated:** 2026-01-01
**Current Version:** v4.7.0
**Status:** Production ready - Actively maintained
**Recent Release:** v4.7.0 - Pick command bug fix + Frecency sorting

---

## 🎯 Quick Reference

| What                   | Status        | Link                                     |
| ---------------------- | ------------- | ---------------------------------------- |
| **Version**            | ✅ v4.7.0     | Production release                       |
| **Architecture**       | ✅ Pure ZSH   | No Node.js runtime required              |
| **Smart Dispatchers**  | ✅ 8 active   | g, mcp, obs, qu, r, cc, tm, wt           |
| **Core Commands**      | ✅ 15+        | work, finish, hop, dash, pick, win, etc. |
| **Documentation Site** | ✅ Live       | https://data-wise.github.io/flow-cli     |
| **Tests**              | ✅ 23 passing | ZSH unit/integration tests               |
| **Installation**       | ✅ Multiple   | Plugin manager, Homebrew, curl install   |
| **Help System**        | ✅ Complete   | `<dispatcher> help` pattern              |

---

## 📊 Project Overview

### What is flow-cli?

**flow-cli** is a pure ZSH plugin for ADHD-optimized workflow management. It provides instant (<10ms) workflow commands and smart dispatchers for common development tasks.

**Key Features:**

- 🚀 **Instant response** - Sub-10ms for core commands
- 🧠 **ADHD-friendly** - Smart defaults, discoverable help
- 🎯 **8 dispatchers** - Domain-specific command routing
- 📊 **Dopamine features** - Win tracking, streaks, goals
- 🔄 **Session management** - work/finish/hop workflow
- 🎨 **Project picker** - FZF-based with frecency sorting

---

## 🚀 Current Release: v4.7.0 (2025-12-31)

### Bug Fix: Pick Command Crash

**Fixed Issues:**

- ✅ "bad math expression" error in `_proj_show_git_status()` (#155)
- ✅ Input sanitization for `wc` output (handles terminal control codes)
- ✅ Added regression test to prevent future occurrences

**Enhancements:**

- ✅ Frecency decay scoring (time-based priority decay)
- ✅ Session indicators (🟢/🟡) on all projects
- ✅ Projects sorted by recent Claude activity
- ✅ `pick --recent` / `pick -r` - Show only projects with Claude sessions
- ✅ CI optimized to ~17s (from 5+ minutes)

**Testing:**

- ✅ All 23 tests passing (100% pass rate)
- ✅ Regression tests added for git status sanitization

**Documentation:**

- 📚 Updated docs for pick worktree features
- 📚 Session-age sorting documentation
- 📚 CI optimization guide

---

## 🏗️ Architecture

### Pure ZSH Plugin

```
flow-cli/
├── flow.plugin.zsh           # Plugin entry point
├── lib/
│   ├── core.zsh              # Colors, logging, utilities
│   ├── atlas-bridge.zsh      # Optional Atlas integration
│   ├── project-detector.zsh  # Project type detection
│   ├── tui.zsh               # Terminal UI components
│   └── dispatchers/          # 8 smart dispatchers
│       ├── g-dispatcher.zsh      # Git workflows
│       ├── mcp-dispatcher.zsh    # MCP servers
│       ├── obs.zsh               # Obsidian
│       ├── qu-dispatcher.zsh     # Quarto
│       ├── r-dispatcher.zsh      # R packages
│       ├── cc-dispatcher.zsh     # Claude Code
│       ├── tm-dispatcher.zsh     # Terminal manager
│       └── wt-dispatcher.zsh     # Worktrees
├── commands/                 # Core command implementations
│   ├── work.zsh             # Session management
│   ├── dash.zsh             # Dashboard
│   ├── pick.zsh             # Project picker
│   ├── adhd.zsh             # Dopamine features
│   └── flow.zsh             # Flow command
├── completions/             # ZSH completions
├── docs/                    # MkDocs documentation
└── tests/                   # Test suite
```

**Design Principles:**

1. **Pure ZSH** - No Node.js runtime required
2. **Sub-10ms** - Instant response for all core commands
3. **ADHD-friendly** - Smart defaults, built-in help
4. **Modular** - Clean separation of concerns
5. **Optional enhancement** - Atlas integration is optional

---

## 🎯 Core Commands

### Session Management

```bash
work <project>    # Start session
finish [note]     # End session (optional commit)
hop <project>     # Quick switch (tmux)
```

### Navigation & Discovery

```bash
dash              # Project dashboard
dash -i           # Interactive TUI (fzf)
pick              # Project picker (frecency sorted)
pick --recent     # Projects with recent Claude sessions
pick wt           # Worktree picker
```

### Dopamine Features (v4.7.0)

```bash
win <text>        # Log accomplishment
yay               # Show recent wins
yay --week        # Weekly summary + graph
flow goal         # Daily goal progress
flow goal set 3   # Set daily win target
```

### Quick Capture

```bash
catch <text>      # Quick capture
js                # Just start (auto-pick project)
```

---

## 🔧 Smart Dispatchers (8 Active)

### Git Workflows (g)

```bash
g status          # Git status
g push            # Git push
g commit          # Git commit
g feature start   # Create feature branch
g feature prune   # Clean merged branches
g help            # Full help
```

### Claude Code (cc)

```bash
cc                # Launch HERE (current dir)
cc pick           # Pick project → Claude
cc yolo           # Launch in YOLO mode
cc plan           # Launch in Plan mode
cc resume         # Resume session picker
cc help           # Full help
```

### MCP Servers (mcp)

```bash
mcp status        # Show all servers
mcp logs <name>   # View logs
mcp test <name>   # Test server
mcp help          # Full help
```

### Terminal Manager (tm)

```bash
tm title <text>   # Set tab title
tm profile <name> # Switch iTerm profile
tm ghost          # Ghostty status
tm switch         # Apply terminal context
tm help           # Full help
```

### R Packages (r)

```bash
r test            # Run tests
r doc             # Build docs
r check           # R CMD check
r help            # Full help
```

### Quarto (qu)

```bash
qu preview        # Preview document
qu render         # Render document
qu help           # Full help
```

### Obsidian (obs)

```bash
obs vaults        # List vaults
obs stats         # Show stats
obs help          # Full help
```

### Worktrees (wt)

```bash
wt create <name>  # Create worktree
wt status         # List all worktrees
wt prune          # Clean deleted worktrees
wt help           # Full help
```

---

## 📚 Documentation

### Live Documentation Site

**URL:** https://data-wise.github.io/flow-cli/

**Sections:**

- 🚀 Getting Started (Installation, Quick Start)
- 📖 Guides (Tutorials, How-tos)
- 📋 Reference (Commands, Dispatchers)
- 🏗️ Architecture (Design, Patterns)
- 🧪 Testing (Test Guide, Standards)
- 🤝 Contributing (Setup, Workflow)

### Key Documents

| Document                                     | Purpose                   |
| -------------------------------------------- | ------------------------- |
| `README.md`                                  | Project overview          |
| `CLAUDE.md`                                  | AI assistant guide        |
| `CHANGELOG.md`                               | Release history           |
| `docs/reference/DISPATCHER-REFERENCE.md`     | Complete dispatcher guide |
| `docs/reference/COMMAND-QUICK-REFERENCE.md`  | Quick command lookup      |
| `docs/reference/WORKFLOW-QUICK-REFERENCE.md` | Common workflows          |
| `docs/guides/DOPAMINE-FEATURES-GUIDE.md`     | Win/streak/goal features  |

---

## 🧪 Testing

### Test Suite Status

**Total Tests:** 23 (all passing ✅)

**Test Coverage:**

- Core functionality tests
- Dispatcher tests
- Integration tests
- Regression tests (git status sanitization)

**Test Locations:**

```
tests/
├── unit/           # Unit tests
├── integration/    # Integration tests
└── run-all.sh      # Full test suite runner
```

**CI Status:**

- ✅ Smoke tests (~17s)
- ✅ Full suite via `./tests/run-all.sh` locally
- ✅ Optimized with apt caching

---

## 🔄 Layered Architecture (flow-cli + aiterm + craft)

flow-cli is part of a 3-layer developer tooling stack:

```
┌─────────────────────────────────────────────────────────────────┐
│  Layer 3: craft plugin (Claude Code)                            │
│  /craft:git:feature - AI-assisted, tests, changelog             │
├─────────────────────────────────────────────────────────────────┤
│  Layer 2: aiterm (Python CLI)                                   │
│  ait feature - rich visualization, complex automation           │
├─────────────────────────────────────────────────────────────────┤
│  Layer 1: flow-cli (Pure ZSH) ← YOU ARE HERE                    │
│  g, wt, cc - instant (<10ms), zero overhead, ADHD-friendly      │
└─────────────────────────────────────────────────────────────────┘
```

### When to Use flow-cli vs aiterm

| Need                      | Use      | Command                  |
| ------------------------- | -------- | ------------------------ |
| **Quick branch creation** | flow-cli | `g feature start <name>` |
| **Quick worktree**        | flow-cli | `wt create <branch>`     |
| **Quick cleanup**         | flow-cli | `g feature prune`        |
| Full feature setup (deps) | aiterm   | `ait feature start -w`   |
| Pipeline visualization    | aiterm   | `ait feature status`     |
| Interactive cleanup       | aiterm   | `ait feature cleanup`    |

---

## 🚢 Installation

### Via Plugin Manager (Recommended)

**Antidote:**

```bash
# Add to ~/.zsh_plugins.txt
data-wise/flow-cli kind:clone
```

**Zinit:**

```bash
# Add to ~/.zshrc
zinit light data-wise/flow-cli
```

**Oh-My-Zsh:**

```bash
git clone https://github.com/Data-Wise/flow-cli \
  ~/.oh-my-zsh/custom/plugins/flow-cli
# Add 'flow-cli' to plugins=(...) in ~/.zshrc
```

### Via Homebrew

```bash
brew tap data-wise/tap
brew install flow-cli
```

### Via Curl (Quick Install)

```bash
curl -fsSL https://raw.githubusercontent.com/Data-Wise/flow-cli/main/install.sh | bash
```

---

## ⚙️ Configuration

### Environment Variables

Set in `.zshrc` **before** sourcing the plugin:

```zsh
# Project root directory
export FLOW_PROJECTS_ROOT="$HOME/projects"

# Atlas integration (auto|yes|no)
export FLOW_ATLAS_ENABLED="auto"

# Quiet mode (suppress welcome)
export FLOW_QUIET=1

# Debug mode
export FLOW_DEBUG=1
```

### Optional Atlas Integration

flow-cli can optionally integrate with [Atlas](https://github.com/Data-Wise/atlas) for enhanced state management:

- **Without Atlas:** Fully functional ZSH-only mode
- **With Atlas:** Enhanced project tracking, session management

**Install Atlas:**

```bash
npm install -g @data-wise/atlas
```

---

## 🎯 Roadmap

### ✅ v4.7.0 Complete

- [x] Pick command bug fix (git status sanitization)
- [x] Frecency sorting with session indicators
- [x] Pick --recent flag
- [x] CI optimization (~17s)
- [x] All 23 tests passing

### 📋 Future: Installation Improvements

- [ ] Enhanced install.sh (curl one-liner, auto-detect plugin manager)
- [ ] Install methods comparison table
- [ ] Update installation docs to match aiterm quality
- [ ] Test on fresh environment

### 📋 Future: Remote & Team Features

- [ ] Remote state sync (optional cloud backup)
- [ ] Multi-device support
- [ ] Shared templates

---

## 📈 Performance

### Benchmarks

| Metric                | Target | Actual | Status |
| --------------------- | ------ | ------ | ------ |
| Core command response | <10ms  | ~5ms   | ✅     |
| Plugin load time      | <50ms  | ~30ms  | ✅     |
| Project scan (cached) | <100ms | <50ms  | ✅     |
| Dashboard render      | <200ms | ~100ms | ✅     |
| CI smoke tests        | <30s   | ~17s   | ✅     |
| Full test suite       | <60s   | ~30s   | ✅     |

---

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for:

- Development setup
- Code standards
- Testing guidelines
- PR process

**Quick Start:**

```bash
# Clone repo
git clone https://github.com/Data-Wise/flow-cli
cd flow-cli

# Load plugin
source flow.plugin.zsh

# Run tests
./tests/run-all.sh
```

---

## 📝 License

MIT License - See [LICENSE](LICENSE)

---

## 🔗 Related Projects

| Project                  | Purpose                 | Integration        |
| ------------------------ | ----------------------- | ------------------ |
| **aiterm**               | Rich Python CLI         | Delegates rich ops |
| **atlas**                | Optional state engine   | Enhanced tracking  |
| **zsh-claude-workflow**  | Shared project patterns | Detection library  |
| **claude-mcp**           | Browser extension MCP   | Complementary      |
| **statistical-research** | MCP server (R, Zotero)  | Via mcp dispatcher |

---

## 📞 Support

- **Documentation:** https://data-wise.github.io/flow-cli/
- **Issues:** https://github.com/Data-Wise/flow-cli/issues
- **Discussions:** https://github.com/Data-Wise/flow-cli/discussions

---

**Last Updated:** 2026-01-01
**Status:** Production Ready (v4.7.0)
