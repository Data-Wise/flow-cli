# Getting Started with flow-cli

**Welcome to flow-cli!** This guide will help you get started with ZSH workflow tools designed for ADHD brains.

---

## 🚀 Quick Start

### Installation

See the [Installation Guide](../getting-started/installation.md) for detailed setup instructions.

```bash
# Via plugin manager (recommended)
antidote install data-wise/flow-cli

# Via Homebrew
brew install data-wise/tap/flow-cli
```

### First Steps

```bash
# Start a session
work my-project

# Log accomplishments
win "Fixed bug"
win "Added tests"

# End session
finish
```

---

## 📚 Essential Guides

### For New Users

1. **[Quick Start](../getting-started/quick-start.md)**
   - 5-minute tutorial
   - Core commands
   - Basic workflow

2. **[Workflow Tutorial](WORKFLOW-TUTORIAL.md)**
   - Session management
   - Project switching
   - ADHD-friendly tips

3. **[Dopamine Features Guide](DOPAMINE-FEATURES-GUIDE.md)**
   - Win tracking
   - Streak system
   - Goal setting

### For Power Users

4. **[YOLO Mode Workflow](YOLO-MODE-WORKFLOW.md)**
   - Zero-friction Claude launching
   - Skip all confirmations
   - When to use (and not use)

5. **[Worktree Workflow](WORKTREE-WORKFLOW.md)**
   - Parallel development
   - Feature branches
   - Quick context switching

6. **[Workflows Quick Wins](WORKFLOWS-QUICK-WINS.md)**
   - Time-saving tips
   - Advanced patterns
   - Pro shortcuts

---

## 🔌 Smart Dispatchers

flow-cli uses **dispatchers** - context-aware commands that adapt to your project:

| Dispatcher | Purpose | Example |
|------------|---------|---------|
| `cc` | Launch Claude Code | `cc pick opus` |
| `r` | R package development | `r test`, `r doc` |
| `qu` | Quarto publishing | `qu preview`, `qu render` |
| `g` | Git workflows | `g push`, `g commit` |
| `wt` | Worktree management | `wt create feature` |
| `mcp` | MCP server management | `mcp status`, `mcp logs` |

**Get help:** Every dispatcher has built-in help via `<dispatcher> help`

Example: `cc help`, `r help`, `qu help`

---

## 📖 Reference Documentation

### Command References

- **[Command Quick Reference](../reference/COMMAND-QUICK-REFERENCE.md)** - All commands at a glance
- **[CC Dispatcher Reference](../reference/CC-DISPATCHER-REFERENCE.md)** - Complete `cc` command guide
- **[Dispatcher Reference](../reference/DISPATCHER-REFERENCE.md)** - All 8 dispatchers
- **[Workflow Quick Reference](../reference/WORKFLOW-QUICK-REFERENCE.md)** - Common workflows

### Alias & Shortcut References

- **[Alias Reference Card](../reference/ALIAS-REFERENCE-CARD.md)** - All 28 aliases
- **[Git Alias Reference](../reference/GIT-ALIAS-REFERENCE.md)** - Git shortcuts

---

## 🎯 Common Tasks

### Start Working

```bash
# Start a session
work my-project

# Or pick interactively
pick
```

### Track Progress

```bash
# Log a win
win "Implemented feature"

# See today's wins
yay

# Check weekly progress
yay --week
```

### Launch Claude Code

```bash
# Launch HERE
cc

# Pick project first
cc pick

# Jump directly
cc flow

# With specific model
cc opus pick

# Target-first (NEW v4.8.0!)
cc pick opus
```

### Switch Projects

```bash
# Quick switch
hop other-project

# Interactive picker
pick

# Recent sessions only
pick --recent
```

---

## 💡 ADHD-Friendly Features

### Visible Progress

- **Win tracking** - Every accomplishment logged
- **Streak system** - See your consistency
- **Goal setting** - Daily win targets
- **Progress bars** - Visual feedback

### Zero Friction

- **Smart defaults** - Minimal typing needed
- **Direct jumps** - Skip pickers when you know what you want
- **Muscle memory** - Consistent patterns across all commands
- **Sub-10ms** - Instant response time

### Stay Oriented

```bash
dash           # What's happening?
why            # Where was I?
pick           # Choose a project
flow goal      # Daily progress
```

---

## 🔧 Configuration

### Environment Variables

Set in `.zshrc` before sourcing flow-cli:

```bash
# Project root
export FLOW_PROJECTS_ROOT="$HOME/projects"

# Atlas integration (optional)
export FLOW_ATLAS_ENABLED="auto"

# Quiet mode
export FLOW_QUIET=1
```

### Plugin Setup

```bash
# antidote (~/.zsh_plugins.txt)
data-wise/flow-cli

# zinit (~/.zshrc)
zinit light data-wise/flow-cli

# oh-my-zsh (custom/plugins/)
plugins=(... flow-cli)
```

---

## 🆘 Getting Help

### Built-in Help

Every command has help:

```bash
flow help              # Main help
cc help                # CC dispatcher
r help                 # R dispatcher
pick help              # Pick command
```

### Documentation

- **Website:** https://data-wise.github.io/flow-cli/
- **GitHub:** https://github.com/Data-Wise/flow-cli
- **Issues:** https://github.com/Data-Wise/flow-cli/issues

### Health Check

```bash
flow doctor            # Check dependencies
flow doctor --fix      # Install missing tools
```

---

## 🎓 Learning Path

### Week 1: Core Workflow

1. Learn `work`, `finish`, `hop`
2. Start tracking wins with `win` and `yay`
3. Use `dash` to stay oriented

### Week 2: Smart Dispatchers

1. Master `cc` for Claude launches
2. Learn project-specific dispatchers (`r`, `qu`, `g`)
3. Explore `pick` for project switching

### Week 3: Advanced Features

1. Try YOLO mode for rapid iteration
2. Set up worktrees for parallel work
3. Customize with environment variables

---

## 📊 What's New

### v4.8.0 - CC Unified Grammar (2026-01-02)

✨ **Flexible command ordering:**
- Both `cc opus pick` AND `cc pick opus` work!
- Explicit HERE: `cc .` and `cc here`
- Natural project jumping: `cc flow opus`

See [Release Notes](https://github.com/Data-Wise/flow-cli/releases/tag/v4.8.0)

---

## 🚦 Next Steps

1. ✅ Install flow-cli
2. ✅ Read this guide
3. → Try the [Quick Start Tutorial](../getting-started/quick-start.md)
4. → Explore [Dopamine Features](DOPAMINE-FEATURES-GUIDE.md)
5. → Master the [CC Dispatcher](../reference/CC-DISPATCHER-REFERENCE.md)

**Ready to get started?** Pick a guide above and dive in! 🎯

---

**Last Updated:** 2026-01-02
**Version:** v4.8.0
