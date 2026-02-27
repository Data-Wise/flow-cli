# flow-cli

[![Version](https://img.shields.io/github/v/release/Data-Wise/flow-cli?label=version&color=blue&cacheSeconds=300)](https://github.com/Data-Wise/flow-cli/releases/latest)
[![CI](https://img.shields.io/github/actions/workflow/status/Data-Wise/flow-cli/test.yml?label=CI&branch=main&cacheSeconds=300)](https://github.com/Data-Wise/flow-cli/actions/workflows/test.yml)
[![Docs](https://img.shields.io/github/actions/workflow/status/Data-Wise/flow-cli/docs.yml?label=docs&branch=main&cacheSeconds=300)](https://github.com/Data-Wise/flow-cli/actions/workflows/docs.yml)
[![License](https://img.shields.io/badge/license-MIT-green)](https://github.com/Data-Wise/flow-cli/blob/main/LICENSE)
[![Pure ZSH](https://img.shields.io/badge/pure-ZSH-1f425f)](https://www.zsh.org/)

> **ZSH workflow tools designed for ADHD brains.**
> Start working in 10 seconds. Stay motivated with visible wins.

---

## ⚡ 10-Second Start

```bash
# 1. Install
brew install data-wise/tap/flow-cli   # macOS (recommended)
# or: antidote install data-wise/flow-cli
# or: zinit light data-wise/flow-cli

# 2. Work
work my-project    # Start session
win "Fixed bug"    # Log win → get dopamine
finish             # Done for now
```

**That's it.** Everything else is optional.

!!! info "Zero Dependencies"
flow-cli is a **standalone ZSH plugin** with no dependencies on Oh-My-Zsh, antidote,
or any other framework. Choose any installation method that works for you.

---

## What's New

### v7.4.0: 31 Email Commands

- **Organize:** `em star`, `em thread`, `em snooze`, `em digest` — manage your inbox without leaving the terminal
- **Manage:** `em delete`, `em move`, `em restore`, `em flag`, `em todo`, `em event` — full email lifecycle with `--pick` multi-select
- **AI:** Switch backends with `em ai gemini`, capture tasks with `em catch 42`
- **10 Tutorials** — step-by-step guides for every em subcommand

```bash
em star 42                   # Star a message
em move 42 Archive           # Move to folder
em todo 42                   # Create reminder from email
em pick                      # Interactive multi-select
```

[Full Changelog](docs/CHANGELOG.md) | [All Releases](https://github.com/Data-Wise/flow-cli/releases)

---

<details>
<summary>📺 See it in action (click to expand)</summary>

![flow-cli demo](https://data-wise.github.io/flow-cli/assets/demo.gif)

**Or try the commands yourself:**

```text
$ work my-project
🚀 Starting session: my-project
   📍 ~/projects/my-project

$ win "Fixed the login bug"
🔧 fix: Fixed the login bug
   ✨ Win #1 today!

$ win "Added unit tests"
🧪 test: Added unit tests
   ✨ Win #2 today!

$ yay
╭──────────────────────────────────────╮
│ 🏆 Today's Wins (2)                 │
├──────────────────────────────────────┤
│ 🔧 Fixed the login bug              │
│ 🧪 Added unit tests                 │
╰──────────────────────────────────────╯
   🔥 2-day streak!

$ finish
✅ Session complete (47 min, 2 wins)
```

</details>

---

## 🎯 Why This Exists

| ADHD Challenge         | flow-cli Solution             |
| ---------------------- | ----------------------------- |
| "Where was I?"         | `why` shows your context      |
| "What should I do?"    | `dash` shows priorities       |
| No visible progress    | `win` logs accomplishments    |
| Context switching pain | `hop` instant project switch  |
| Starting is hard       | `work` removes friction       |
| Multiple devices       | `flow sync` keeps wins synced |

---

## 🚀 Core Commands

### Start & Stop

```bash
work myproject     # Start working (creates session)
finish "done X"    # End session (optional commit)
hop other          # Quick switch (tmux)
```

### Stay Motivated

```bash
win "Fixed the bug"     # Log accomplishment → 🔧 fix
win "Deployed v2"       # Log accomplishment → 🚀 ship
yay                     # See your wins
flow goal set 3         # Daily target
```

### Stay Oriented

```bash
dash           # What's happening?
why            # Where was I?
pick           # Choose a project
```

---

## 🧠 ADHD-Friendly Features

### 🏆 Dopamine Hits

Every `win` gives you a category and emoji:

- 💻 code - "Implemented feature"
- 🔧 fix - "Fixed that bug"
- 🚀 ship - "Deployed to prod"
- 📝 docs - "Updated README"
- 🧪 test - "Added tests"

### 🔥 Streak Tracking

```text
Day 1: work → 🌱 1 day
Day 3: work → 🔥 3 days - On a roll!
Day 7: work → 🔥🔥 Strong week!
```

### 📊 Dashboard

```bash
dash              # Quick overview
dash -i           # Interactive picker
dash --watch      # Live updates
```

### ☁️ Multi-Device Sync (v4.7.0)

Sync your wins and goals across devices via iCloud:

```bash
flow sync remote init    # Set up once
flow sync                # Auto-sync daily
```

Works offline, syncs when connected. Zero config after setup.

### ⚡ Performance Optimization (v5.3.0)

Sub-10ms project picker with intelligent caching:

```bash
pick              # < 10ms (cached)
flow cache status # Check cache age
flow cache refresh # Force rebuild
```

**40x faster** than v5.2.0 for large project sets (100+ repos). Transparent 5-minute cache with automatic refresh.

---

## 🔌 Smart Dispatchers

Context-aware commands that adapt to your project:

| Command            | What it does                   |
| ------------------ | ------------------------------ |
| `cc`               | Launch Claude Code here        |
| `cc pick`          | Pick project → Claude          |
| `cc pick opus` ✨  | Pick → Opus (natural order!)   |
| `dots`             | Manage dotfiles (chezmoi)      |
| `dots edit .zshrc` | Edit dotfile with preview      |
| `dots ignore add`  | Add ignore pattern (safety) ✨ |
| `dots size`        | Analyze repository size ✨     |
| `sec`              | Secret management (Keychain)   |
| `tok`              | Token management (API tokens)  |
| `r test`           | Run R package tests            |
| `qu preview`       | Preview Quarto doc             |
| `g push`           | Git push with safety           |
| `em`               | Email management (himalaya)    |
| `em inbox`         | Browse inbox with fzf          |
| `em pick`          | Interactive email picker       |
| `flow sync`        | Sync data across devices       |
| `at catch "idea"`  | Quick capture via Atlas bridge |
| `at stats`         | Project stats (requires Atlas) |

Each dispatcher has built-in help: `cc help`, `dots help`, `r help`, `em help`, `at help`, etc.

**✨ New in v7.6.0:** `em --prompt` AI-guided composition, `--backend` provider override, `em forward`, help guards on all 34 em subcommands
**✨ v7.5.0:** em v2.0 safety gate, ICS calendar, IMAP watch, folder CRUD
**✨ v7.4.2:** Atlas bridge (`at`) — project intelligence, context parking, quick capture
**✨ v7.4.0:** 38 email commands — read, reply, forward, AI compose, organize, manage
**✨ v7.1.0:** Dispatcher split — `dot` → `dots` (dotfiles) + `sec` (secrets) + `tok` (tokens)
**✨ 15 dispatchers + Atlas bridge** with unified grammar, built-in help, and fzf integration

---

## 🎓 Teaching Workflow (v5.3.0+)

**Deployment-focused workflow for course websites.** Solve the 5-15 minute deployment pain point.

**v5.9.0:** Now with schema-based config validation and Scholar AI integration!

```bash
# Initialize teaching workflow (with semester scheduling)
cd ~/teaching/my-course
teach-init "STAT 545"
# Prompts for: semester dates, break weeks, auto-calculates end date

# Start session (shows semester context)
work stat-545
📚 STAT 545 - Design of Experiments
  Branch: draft
  Semester: Spring 2026
  Current Week: Week 8

  Recent Changes:
    Add week 8 lecture notes
    Update assignment rubric

# Deploy (typo to live in < 2 min)
./scripts/quick-deploy.sh
```

**Key Features:**

- ✅ **Fast Deployment** - < 2 minute typo-to-live workflow
- ✅ **Branch Safety** - Warns when editing production (students see this!)
- ✅ **Semester Context** - Shows current week, detects breaks, displays recent commits
- ✅ **Week Calculation** - Auto-calculates week number from semester start date
- ✅ **Automation Scripts** - One-command deployment and archival
- ✅ **Semester Management** - Easy semester transitions with archival tags
- ✅ **Config Validation** (v5.9.0) - Schema-based validation with hash caching
- ✅ **Scholar Integration** (v5.8.0+) - AI-powered exam/quiz/slides generation

**Scholar AI Commands (v5.8.0+):**

```bash
teach exam "Hypothesis Testing"  # Generate exam via Scholar plugin
teach quiz "Chapter Review"      # Generate quiz
teach slides "Regression"        # Generate lecture slides
teach --dry-run exam "Topic"     # Preview without writing files
teach map                        # Show full ecosystem overview
```

**Learn More:**

- [Complete Guide](https://data-wise.github.io/flow-cli/guides/TEACHING-WORKFLOW/)
- [Quick Reference](https://data-wise.github.io/flow-cli/reference/REFCARD-TEACHING/)
- [Demo Walkthrough](https://data-wise.github.io/flow-cli/demos/)

---

## 📚 Quarto Workflow Phase 1 (v4.6.0+)

**Professional teaching workflow with automated validation, caching, and deployment.**

### Automated Validation

- **Git Hooks**: Automatic validation on commit/push
  - 5-layer validation: YAML, syntax, render, empty chunks, images
  - Production branch protection
  - Zero-config installation
- **teach validate**: Standalone validation with watch mode
  - Four modes: `--yaml`, `--syntax`, `--render`, `full`
  - Continuous validation with file system monitoring
  - Conflict detection with `quarto preview`

### Cache Management

- **teach cache**: Interactive Quarto freeze cache management
  - Status, clear, rebuild, analyze, clean operations
  - Storage analysis and diagnostics
  - TUI menu for easy interaction

### Health Monitoring

- **teach doctor**: Comprehensive health checks
  - 6 check categories (dependencies, config, git, scholar, hooks, cache)
  - Interactive fix mode (`--fix` flag)
  - JSON output for CI/CD integration

### Enhanced Deployment

- **Index Management**: Automatic ADD/UPDATE/REMOVE of links
  - Smart week-based link insertion in index.qmd
  - Source file and cross-reference detection
  - Partial deployment support
  - Preview mode before PR creation

### Backup Management

- **Retention Policies**: Daily/weekly/semester archival rules
  - Archive support for semester-end
  - Storage-efficient incremental backups
  - Safe deletion with confirmation

### Status Dashboard

- **6-Section Overview**: Project, Git, Deployment, Backup, Scholar, Hooks
  - Color-coded health indicators
  - Comprehensive project information
  - All information in one command

**Example Workflow:**

```bash
# Check project health
teach doctor
teach doctor --fix  # Interactive dependency installation

# Validate .qmd files
teach validate lectures/week-01.qmd
teach validate --watch  # Continuous validation

# Manage Quarto freeze cache
teach cache              # Interactive TUI menu
teach cache status       # View cache size
teach cache rebuild      # Clear and regenerate

# Install git hooks (automatic validation)
teach hooks install
teach hooks status

# Deploy with index management
teach deploy --preview   # Preview changes first
teach deploy             # Create PR with index updates

# Check comprehensive status
teach status             # 6-section dashboard
```

**Documentation:**

- [Quarto Workflow Guide](docs/guides/TEACHING-QUARTO-WORKFLOW-GUIDE.md)
- [Teach Dispatcher Reference](docs/reference/TEACH-DISPATCHER-REFERENCE-v4.6.0.md)

---

## 📦 Installation

### Homebrew (Recommended for macOS)

```bash
# Tap the repository
brew tap data-wise/tap

# Install flow-cli
brew install flow-cli
```

**That's it!** Homebrew handles everything. No plugin manager needed.

### Alternative: Quick Install Script

```bash
curl -fsSL https://raw.githubusercontent.com/Data-Wise/flow-cli/main/install.sh | bash
```

Auto-detects your plugin manager and installs accordingly.

**Install specific version:**

```bash
FLOW_VERSION=v4.8.0 curl -fsSL https://raw.githubusercontent.com/Data-Wise/flow-cli/main/install.sh | bash
```

### Installation Methods Comparison

| Method            | Command                                        | Best For       |
| ----------------- | ---------------------------------------------- | -------------- |
| **Homebrew**      | `brew tap data-wise/tap && brew install ...`   | macOS users ⭐ |
| **Quick Install** | `curl -fsSL .../install.sh \| bash`            | Auto-detection |
| **Antidote**      | Add `Data-Wise/flow-cli` to `.zsh_plugins.txt` | Antidote users |
| **Zinit**         | `zinit light Data-Wise/flow-cli`               | Zinit users    |
| **Oh-My-Zsh**     | Clone to `$ZSH_CUSTOM/plugins/`                | OMZ users      |
| **Manual**        | `git clone` + source                           | Full control   |

<details>
<summary>📋 Manual installation commands</summary>

**Antidote:**

```bash
echo "Data-Wise/flow-cli" >> ~/.zsh_plugins.txt
antidote update
```

**Zinit:**

```bash
zinit light Data-Wise/flow-cli
```

**Oh-My-Zsh:**

```bash
git clone https://github.com/Data-Wise/flow-cli.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/flow-cli
# Then add 'flow-cli' to plugins=(...) in ~/.zshrc
```

**Manual:**

```bash
git clone https://github.com/Data-Wise/flow-cli.git ~/.flow-cli
echo 'source ~/.flow-cli/flow.plugin.zsh' >> ~/.zshrc
```

</details>

### Verify Installation

```bash
flow doctor        # Health check
```

### Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/Data-Wise/flow-cli/main/uninstall.sh | bash
```

---

## ✅ Testing

Interactive dog feeding test (yes, really):

```bash
./tests/interactive-dog-feeding.zsh
```

- 🐕 Feed a virtual dog by confirming commands work
- ⭐ Earn 1-5 stars
- 👀 See expected output before running

---

## ⚙️ Configuration

```bash
# In .zshrc (before sourcing plugin)
export FLOW_PROJECTS_ROOT="$HOME/projects"  # Where your projects live
export FLOW_QUIET=1                         # Skip welcome message
```

---

## 📚 Documentation

- **[Quick Start](https://data-wise.github.io/flow-cli/getting-started/quick-start/)** - 5 minutes
- **[Dopamine Features](https://data-wise.github.io/flow-cli/tutorials/06-dopamine-features/)** - Win tracking
- **[Sync Command](https://data-wise.github.io/flow-cli/commands/sync/)** - Multi-device sync
- **[All Commands](https://data-wise.github.io/flow-cli/reference/COMMAND-QUICK-REFERENCE/)** - Reference

### API Reference

**348 functions documented** across 32 library files (49.4% coverage):

| Reference                                                                                    | Functions | Scope                     |
| -------------------------------------------------------------------------------------------- | --------- | ------------------------- |
| [Core API](https://data-wise.github.io/flow-cli/reference/CORE-API-REFERENCE/)               | 47        | Logging, TUI, Git helpers |
| [Teaching API](https://data-wise.github.io/flow-cli/reference/TEACHING-API-REFERENCE/)       | 61        | Validation, backup, cache |
| [Integration API](https://data-wise.github.io/flow-cli/reference/INTEGRATION-API-REFERENCE/) | 80        | Atlas, plugins, config    |
| [Specialized API](https://data-wise.github.io/flow-cli/reference/SPECIALIZED-API-REFERENCE/) | 160       | Dotfiles, AI, rendering   |

---

## 🤝 Philosophy

1. **Instant response** - Sub-10ms, no waiting
2. **Smart defaults** - Works without config
3. **Visible progress** - See your wins
4. **Low friction** - Start working fast

---

**License:** MIT
**Docs:** [data-wise.github.io/flow-cli](https://data-wise.github.io/flow-cli/)
