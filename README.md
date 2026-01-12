# flow-cli

[![Version](https://img.shields.io/badge/version-5.3.0-blue.svg)](https://github.com/Data-Wise/flow-cli/releases)
[![Tests](https://github.com/Data-Wise/flow-cli/actions/workflows/test.yml/badge.svg)](https://github.com/Data-Wise/flow-cli/actions)
[![Docs](https://img.shields.io/badge/docs-online-brightgreen.svg)](https://data-wise.github.io/flow-cli/)

> **ZSH workflow tools designed for ADHD brains.**
> Start working in 10 seconds. Stay motivated with visible wins.

---

## ⚡ 10-Second Start

```bash
# 1. Install
antidote install data-wise/flow-cli   # or: zinit light data-wise/flow-cli

# 2. Work
work my-project    # Start session
win "Fixed bug"    # Log win → get dopamine
finish             # Done for now
```

**That's it.** Everything else is optional.

<details>
<summary>📺 See it in action (click to expand)</summary>

![flow-cli demo](https://data-wise.github.io/flow-cli/assets/demo.gif)

**Or try the commands yourself:**

```
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

```
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

| Command           | What it does                 |
| ----------------- | ---------------------------- |
| `cc`              | Launch Claude Code here      |
| `cc pick`         | Pick project → Claude        |
| `cc pick opus` ✨ | Pick → Opus (natural order!) |
| `dot`             | Manage dotfiles & secrets    |
| `dot edit .zshrc` | Edit dotfile with preview    |
| `r test`          | Run R package tests          |
| `qu preview`      | Preview Quarto doc           |
| `g push`          | Git push with safety         |
| `flow sync`       | Sync data across devices     |

Each dispatcher has built-in help: `cc help`, `dot help`, `r help`, etc.

**✨ New in v4.8.0:** Unified grammar - both `cc opus pick` AND `cc pick opus` work identically!
**✨ New in v5.0.0:** Dotfile management with `dot` dispatcher

---

## 🎓 Teaching Workflow (v5.3.0)

**Deployment-focused workflow for course websites.** Solve the 5-15 minute deployment pain point.

```bash
# Initialize teaching workflow
cd ~/teaching/my-course
teach-init "STAT 545"

# Start session (auto-checks branch safety)
work stat-545
# ⚠️  Warns if on production branch!

# Deploy (typo to live in < 2 min)
./scripts/quick-deploy.sh
```

**Key Features:**
- ✅ **Fast Deployment** - < 2 minute typo-to-live workflow
- ✅ **Branch Safety** - Warns when editing production (students see this!)
- ✅ **Automation Scripts** - One-command deployment and archival
- ✅ **Course Context** - Teaching-aware work sessions with shortcuts
- ✅ **Semester Management** - Easy semester transitions

**Learn More:**
- [Complete Guide](https://data-wise.github.io/flow-cli/guides/TEACHING-WORKFLOW/)
- [Quick Reference](https://data-wise.github.io/flow-cli/reference/REFCARD-TEACHING/)
- [Demo Walkthrough](https://data-wise.github.io/flow-cli/demos/)

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

---

## 🤝 Philosophy

1. **Instant response** - Sub-10ms, no waiting
2. **Smart defaults** - Works without config
3. **Visible progress** - See your wins
4. **Low friction** - Start working fast

---

**License:** MIT
**Docs:** [data-wise.github.io/flow-cli](https://data-wise.github.io/flow-cli/)
