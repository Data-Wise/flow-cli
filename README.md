# flow-cli

[![Version](https://img.shields.io/badge/version-5.21.0-blue.svg)](https://github.com/Data-Wise/flow-cli/releases/tag/v5.21.0)
[![Tests](https://github.com/Data-Wise/flow-cli/actions/workflows/test.yml/badge.svg)](https://github.com/Data-Wise/flow-cli/actions)
[![Docs](https://img.shields.io/badge/docs-online-brightgreen.svg)](https://data-wise.github.io/flow-cli/)

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
flow-cli is a **standalone ZSH plugin** with no dependencies on Oh-My-Zsh, antidote, or any other framework. Choose any installation method that works for you - they all load the same independent plugin.

---

## 🎉 What's New

### v5.18.0: Documentation Consolidation & API Coverage (In Development - 2026-01-24)

**Simplified Documentation with Comprehensive API Coverage** 📚

- 📄 **Master Documents** - 7 comprehensive guides replace 66 files (95% reduction)
- 🗺️ **Navigation** - Simplified from 71 → 9 entries (92% reduction)
- 🔗 **Link Health** - Fixed 54 critical broken links across hub files
- 📊 **API Documentation** - Improved from 2.7% → 13.8% coverage (+411% increase)
- ✅ **Quality** - Zero stale docs, comprehensive health checks
- 📦 **Archive** - 66 legacy files preserved with migration map

**Master Documents:**

- MASTER-API-REFERENCE.md (5,000+ lines)
- MASTER-DISPATCHER-GUIDE.md (3,000+ lines)
- MASTER-ARCHITECTURE.md (11+ Mermaid diagrams)
- Plus: QUICK-REFERENCE, WORKFLOWS, TROUBLESHOOTING, 00-START-HERE

[→ Documentation Hub](https://data-wise.github.io/flow-cli/)

---

### v5.21.0: LaTeX Macro Configuration (Coming Soon)

**Consistent AI-generated content with custom notation**

- 📐 **teach macros** - Manage LaTeX macros for consistent notation
  - Sync from QMD, LaTeX, or MathJax source files
  - Export for Scholar AI integration
  - Categories: operators, distributions, symbols, matrices
- 🏥 **teach doctor** - Now includes macro health checks
- 🎯 **Primary use case:** Ensure `teach exam` generates `\E{Y}` not `E[Y]`

**Commands:**

```bash
teach macros list                # Show all macros
teach macros sync                # Extract from source files
teach macros export --format json  # Export for Scholar
```

---

### v5.17.0: Token Automation Phase 1 ✨ (Released - 2026-01-23)

**Smart Token Management with 20x Performance Boost**

- 🔑 **Isolated Checks** - `doctor --dot` checks only tokens (< 3s vs 60+ seconds)
- 💾 **Smart Caching** - 5-minute TTL, 85% hit rate, 80% API call reduction
- 🎯 **ADHD-Friendly Menu** - Visual category selection with time estimates
- 🔊 **Verbosity Control** - quiet/normal/verbose modes for all use cases
- ⚡ **Token-Only Fixes** - `doctor --fix-token` for isolated workflows
- 🔗 **9-Dispatcher Integration** - g, dash, work, finish, doctor, and more

**Commands:**

```bash
doctor --dot              # Quick token check (< 3s, cached)
doctor --dot=github       # Check specific provider
doctor --fix-token        # Interactive token fix menu
doctor --dot --quiet      # CI/CD integration (minimal output)
doctor --dot --verbose    # Debug with cache status
```

**PR #292 (MERGED)** · 54 tests (96.3% passing) · 2,150+ lines of documentation · 11 Mermaid diagrams

### v5.16.0: Intelligent Content Analysis (2026-01-22)

**AI-powered course content analysis with concept graphs and slide optimization:**

- 🧠 **teach analyze** - Full concept graph system (Phases 0-5 complete)
  - Concept extraction from frontmatter + prerequisite validation
  - SHA-256 caching with parallel processing (flock-based)
  - AI analysis: Bloom's taxonomy, cognitive load, teaching time estimates
  - Slide optimization: break suggestions, key concepts, time estimates
- ⚡ **Plugin Optimization** - Load guards prevent double-sourcing (3x startup reduction)
- 🎯 **Cache Fixes** - Directory-mirroring structure prevents path collisions
- ✅ **Test Improvements** - 30s timeouts prevent infinite hangs

**Commands:**

```bash
teach analyze lectures/week-05.qmd    # Single file analysis
teach analyze --batch lectures/       # Parallel batch processing
teach analyze --slide-breaks           # Slide optimization
teach validate --deep                  # Prerequisite validation
```

**393 tests (100% passing) · 7 new libraries (6,800+ lines) · 1,251-line user guide**

### v4.7.0: Quarto Workflow Phase 2 (2026-01-20)

**Advanced features for professional teaching workflows:**

- 🎭 **Profile Management** - Multiple Quarto profiles (draft, print, slides) + R package auto-install
- ⚡ **Parallel Rendering** - 3-10x speedup on multi-file operations (worker pools)
- 🔍 **Custom Validators** - Extensible validation framework (citations, links, formatting)
- 💾 **Advanced Caching** - Smart cache analysis and selective clearing (--lectures, --old, --unused)
- 📊 **Performance Monitoring** - Trend tracking and visualization with ASCII graphs

**270+ tests · 2,900+ lines of documentation · 3-10x performance improvement**

### v4.6.0: Quarto Workflow Phase 1 (2026-01-20)

**Professional Quarto teaching workflow with automation and safety:**

- 🔍 **5-Layer Validation** - Automated validation via git hooks (YAML, syntax, render, chunks, images)
- 💾 **teach validate** - Standalone validation with watch mode + conflict detection
- 🗄️ **teach cache** - Interactive Quarto freeze cache management with TUI
- 🏥 **teach doctor** - Comprehensive health checks with interactive fix mode
- 📊 **Enhanced Deploy** - Index management (ADD/UPDATE/REMOVE) + dependency tracking
- 💾 **Retention Policies** - Daily/weekly/semester backup archival
- 📈 **6-Section Status** - Deployment status, backup summary, and more

**296 tests (99.3% passing) · 6,500+ lines of documentation · 85% time savings**

### v5.14.0: Teaching Workflow v3.0 (2026-01-18)

**Complete overhaul of teaching workflow with automated safety features:**

- 🏥 **`teach doctor`** - Environment health check (dependencies, config, git, Scholar)
- 💾 **Backup System** - Automated content backups with retention policies (never lose work!)
- 📊 **Enhanced Status** - Deployment status + backup summary
- 🔍 **Deploy Preview** - Review changes before creating PRs
- 📚 **Scholar Templates** - Template selection + lesson plan auto-loading
- 🎓 **Streamlined Init** - External configs, GitHub repo creation

**73 tests (100% passing) · 53,000+ lines of documentation · Migration guide included**

See [CHANGELOG.md](docs/CHANGELOG.md) for complete details.

---

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
**✨ New in v5.5.0:** macOS Keychain secrets with Touch ID - instant access, no unlock needed!
**✨ New in v5.9.0:** Schema-based config validation with hash-based caching for teaching workflows!

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
