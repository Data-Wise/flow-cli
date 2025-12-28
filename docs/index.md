# Flow CLI

**Minimalist ZSH workflow tools with smart dispatchers**

A streamlined system for managing development workflows. Features **28 essential aliases**, **6 smart dispatchers**, and **226+ git aliases** (via plugin). Optimized for muscle memory over memorization.

---

## Quick Stats

| Metric                | Value                                  |
| --------------------- | -------------------------------------- |
| **Version**           | v4.0.1                                 |
| **Status**            | Production Ready                       |
| **Custom aliases**    | 28 (down from 179)                     |
| **Smart dispatchers** | 6 (`g`, `mcp`, `obs`, `qu`, `r`, `cc`) |
| **Tests**             | 100% pass rate                         |
| **Architecture**      | Pure ZSH plugin                        |

---

## What's New in v4.0

- **Dopamine Features** - Win tracking, streaks, and daily goals
- **Unified Sync** - `flow sync all` orchestrates all data
- **CC Dispatcher** - Project-aware Claude Code launcher

See the full [Changelog](CHANGELOG.md) for version history.

---

## Quick Start

### 1. Core Commands

```bash
work my-project   # Start session
win "Fixed bug"   # Log accomplishment
finish            # End session
dash              # View dashboard
```

### 2. Smart Dispatchers

Context-aware functions that adapt to your project:

```bash
cc       # Project-aware Claude Code
gem      # Project-aware Gemini
r        # R package development
qu       # Quarto operations
g        # Git workflows
pick     # Project picker
```

### 3. Dopamine Features

Stay motivated with visible progress:

```bash
win "Completed feature"   # Log a win (auto-categorized)
yay                       # See recent wins
flow goal set 3           # Set daily target
flow goal                 # Check progress
```

**Categories:** 💻 code, 📝 docs, 👀 review, 🚀 ship, 🔧 fix, 🧪 test

---

## Essential Documentation

!!! tip "Start Here"
**New to flow-cli?** Read the [Quick Start Guide](getting-started/quick-start.md) in 5 minutes!

### Core Guides

| Guide                                                     | Description              |
| --------------------------------------------------------- | ------------------------ |
| [Quick Start](getting-started/quick-start.md)             | Get running in 5 minutes |
| [Your First Session](tutorials/01-first-session.md)       | Step-by-step tutorial    |
| [Dopamine Features](tutorials/06-dopamine-features.md)    | Win tracking & goals     |
| [Command Reference](reference/COMMAND-QUICK-REFERENCE.md) | All commands             |

### Reference Cards

| Reference                                                  | Description       |
| ---------------------------------------------------------- | ----------------- |
| [Alias Card](reference/ALIAS-REFERENCE-CARD.md)            | All 28 aliases    |
| [Workflow Patterns](reference/WORKFLOW-QUICK-REFERENCE.md) | Daily workflows   |
| [Dispatcher Reference](reference/DISPATCHER-REFERENCE.md)  | Smart dispatchers |

---

## Testing Your Installation

!!! success "Interactive Dog Feeding Test 🐕"
Validate your installation with our gamified test suite!

```bash
./tests/interactive-dog-feeding.zsh
```

- 👀 Shows 60+ comprehensive expected patterns
- ✅ Interactive y/n validation
- ⭐ Earn 1-5 stars based on performance

Or run the health check:

```bash
flow doctor
```

---

## Design Philosophy

### Key Principles

1. **Muscle memory over memorization** - Keep only daily-use commands
2. **Patterns over individual** - `r*` pattern easier than 23 aliases
3. **Standard over custom** - Use community standards (git plugin)
4. **Functions over aliases** - Smart behavior > static shortcuts
5. **Explicit over implicit** - Full commands > cryptic shortcuts

### ADHD-Friendly Design

| Feature             | Purpose                        |
| ------------------- | ------------------------------ |
| Sub-10ms response   | No waiting, no frustration     |
| Smart defaults      | Works without configuration    |
| Visual feedback     | Dopamine from visible progress |
| Consistent patterns | Less to memorize               |

---

## Architecture

```
flow-cli/
├── flow.plugin.zsh      # Entry point
├── lib/                 # Core utilities
│   ├── core.zsh         # Colors, logging
│   ├── dispatchers/     # Smart dispatchers
│   └── tui.zsh          # Terminal UI
├── commands/            # Command implementations
├── completions/         # ZSH completions
└── tests/               # Test suite
```

See [Architecture Overview](architecture/README.md) for details.

---

## Contributing

See the [Contributing Guide](contributing/CONTRIBUTING.md) for:

- Adding new commands
- Code standards
- Testing requirements
- PR workflow

---

## Links

- **Documentation:** [https://data-wise.github.io/flow-cli/](https://data-wise.github.io/flow-cli/)
- **Repository:** [https://github.com/Data-Wise/flow-cli](https://github.com/Data-Wise/flow-cli)
- **Changelog:** [Version History](CHANGELOG.md)

---

**Last updated:** 2025-12-27 | **Maintainer:** DT
