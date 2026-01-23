# Flow CLI

[![Version](https://img.shields.io/badge/version-v5.16.0-blue)](https://github.com/Data-Wise/flow-cli/releases/tag/v5.16.0)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Tests](https://img.shields.io/github/actions/workflow/status/Data-Wise/flow-cli/test.yml?label=tests&branch=main)](https://github.com/Data-Wise/flow-cli/actions/workflows/test.yml)
[![Docs](https://img.shields.io/github/actions/workflow/status/Data-Wise/flow-cli/docs.yml?label=docs&branch=main)](https://github.com/Data-Wise/flow-cli/actions/workflows/docs.yml)
[![Pure ZSH](https://img.shields.io/badge/pure-ZSH-1f425f)](https://www.zsh.org/)
[![ADHD-Friendly](https://img.shields.io/badge/ADHD-friendly-purple)](PHILOSOPHY.md)

> **ZSH workflow tools designed for ADHD brains.**

Start working in 10 seconds. Stay motivated with visible wins. No configuration required.

!!! tldr "⚡ TL;DR - Get Started in 30 Seconds"
    ```bash
    brew tap data-wise/tap && brew install flow-cli
    dash                    # See your projects
    work my-project         # Start working
    win "tried flow-cli!"   # Log your first win
    ```
    **That's it!** [Want to learn more? →](#try-it-now)

---

## ✨ What's New in v5.16.0

!!! success "Intelligent Content Analysis - teach analyze (All Phases Complete)"
    AI-powered course content analysis with concept graphs, prerequisite validation, and slide optimization

### 🧠 Intelligent Content Analysis (teach analyze)

**Full Feature Set (Phases 0-5):**
- **📊 Concept Graph** - Extract concepts from frontmatter, build dependency graph
- **✅ Prerequisite Validation** - Detect circular dependencies and week ordering issues
- **⚡ Smart Caching** - SHA-256 content hashing with flock-based parallel processing
- **🤖 AI Analysis** - Bloom's taxonomy, cognitive load estimation, teaching time
- **📐 Slide Optimization** - Break suggestions, key concepts for emphasis, time estimates
- **📝 Reports** - JSON/Markdown reports for course-wide analysis

**Commands:**
```bash
teach analyze lectures/week-05.qmd           # Single file analysis
teach analyze --batch lectures/              # Parallel batch analysis
teach analyze --slide-breaks                 # Slide optimization
teach validate --deep                        # Prerequisite validation
```

[→ Intelligent Content Analysis Guide](guides/INTELLIGENT-CONTENT-ANALYSIS.md){ .md-button .md-button--primary }
[→ teach analyze Tutorial](tutorials/21-teach-analyze.md){ .md-button }

### ⚡ Plugin Optimization

- **Load Guards** - Prevents double/triple-sourcing of libraries (3x startup reduction)
- **Display Layer** - Extracted 270 lines to reusable `lib/analysis-display.zsh`
- **Cache Fixes** - Directory-mirroring structure prevents path collisions
- **Test Timeouts** - 30s timeouts prevent infinite hangs (13 tests pass, 5 timeout as expected)
- **Test Suite** - 31 new tests for optimization validation (100% passing)

[→ Plugin Optimization Tutorial](tutorials/22-plugin-optimization.md){ .md-button }
[→ Optimization Quick Reference](reference/REFCARD-OPTIMIZATION.md){ .md-button }

---

## Previous Releases

### 🎓 Teaching Workflow v3.0 (v5.14.0)

**Wave 1: Foundation**
- **🏥 teach doctor** - Comprehensive environment health check (--fix, --json, --quiet)
- **📖 Enhanced Help** - All 10 teach commands now have --help with EXAMPLES
- **🔄 Unified Dispatcher** - Removed standalone `teach-init`, now `teach init`

**Wave 2: Backup System**
- **💾 Automated Backups** - Timestamped snapshots on every content modification
- **📦 Retention Policies** - `archive` (keep forever) vs `semester` (auto-cleanup)
- **🗑️ Safe Deletion** - Interactive confirmation with file preview
- **📊 Status Integration** - Backup summary in `teach status`

**Wave 3: Enhancements**
- **🚀 Deploy Preview** - `teach deploy --preview` shows changes before PR
- **📚 Scholar Templates** - Template selection + automatic lesson plan loading
- **✅ Enhanced Status** - Deployment status + backup info in `teach status`

### 📹 Visual Documentation (6 GIFs)

All new features demonstrated with optimized tutorial GIFs (5.7MB total):

- **teach doctor** - Environment validation workflow
- **Backup system** - Automated content safety
- **teach init** - Project initialization
- **teach deploy** - Preview deployment flow
- **teach status** - Enhanced dashboard
- **Scholar integration** - Template & lesson plans

[→ Teaching Workflow v3.0 Guide](guides/TEACHING-WORKFLOW-V3-GUIDE.md){ .md-button .md-button--primary }
[→ Backup System Guide](guides/BACKUP-SYSTEM-GUIDE.md){ .md-button }
[→ Migration Guide (v2→v3)](guides/TEACHING-V3-MIGRATION-GUIDE.md){ .md-button }

### Previous Release: v5.13.0

**WT Enhancement + Scholar Integration**
- Enhanced worktree management with formatted overview and smart filtering
- 9 Scholar wrapper commands for teaching content generation
- Multi-select worktree actions with interactive delete

[View Full Changelog →](CHANGELOG.md){ .md-button }

---

## 🎯 Choose Your Path

Not sure where to start? Pick what fits you best:

<div class="grid cards" markdown>

-   :rocket: { .lg .middle }
    **Quick Start**

    ---

    Get up and running in 5 minutes

    [→ Quick Start](getting-started/quick-start.md)

-   :books: { .lg .middle }
    **Learn Step-by-Step**

    ---

    30-minute guided tutorial path

    [→ Tutorials](tutorials/01-first-session.md)

-   :target: { .lg .middle }
    **Solve a Problem**

    ---

    Find the workflow you need now

    [→ Workflows](guides/WORKFLOWS-QUICK-WINS.md)

-   :mag: { .lg .middle }
    **Look Up a Command**

    ---

    Quick reference for commands

    [→ Reference](reference/COMMAND-QUICK-REFERENCE.md)

-   :mortar_board: { .lg .middle }
    **Teaching System**

    ---

    Deploy course materials in < 2 minutes

    [→ Architecture](guides/TEACHING-SYSTEM-ARCHITECTURE.md)

</div>

---

## ⚡ Try It Now

```bash
work my-project    # Start session
win "Fixed bug"    # Log win → dopamine hit
finish             # Done
```

!!! success "That's the whole workflow"
    Everything else is optional enhancement.

??? example "📺 See it in action"
    ![flow-cli demo](assets/demo.gif)

    **Expected output:**

    ```
    $ work my-project
    🚀 Starting session: my-project
       📍 ~/projects/my-project

    $ win "Fixed the login bug"
    🔧 fix: Fixed the login bug
       ✨ Win #1 today!

    $ yay
    🏆 Today's Wins (2)
       🔥 2-day streak!

    $ finish
    ✅ Session complete
    ```

---

## 🎯 What Problem Does This Solve?

| ADHD Challenge           | flow-cli Solution            |
| ------------------------ | ---------------------------- |
| "Where was I?"           | `why` → shows context        |
| "What should I work on?" | `dash` → shows priorities    |
| No visible progress      | `win` → logs accomplishments |
| Context switching hurts  | `hop` → instant switch       |
| Starting is hard         | `work` → removes friction    |

---

## 🏆 Dopamine System

Every accomplishment gets logged with a category:

```bash
win "Fixed the login bug"      # → 🔧 fix
win "Deployed to production"   # → 🚀 ship
win "Added unit tests"         # → 🧪 test
win "Updated documentation"    # → 📝 docs
```

Then see your progress:

```bash
yay              # Recent wins
yay --week       # Weekly summary with graph
flow goal        # Daily progress bar
```

### 🔥 Streaks

```
Day 1: 🌱 Building momentum
Day 3: 🔥 On a roll!
Day 7: 🔥🔥 Strong week!
Day 14: 🔥🔥🔥 Exceptional!
```

---

## 🚀 Core Commands

### Session Flow

```bash
work myproject    # Start (creates session)
finish "done"     # End (optional commit)
hop other         # Quick switch (tmux)
```

### Orientation

```bash
dash              # Dashboard overview
why               # Current context
pick              # Project picker
```

### Capture

```bash
catch "idea"      # Quick capture
crumb "note"      # Breadcrumb
trail             # See your trail
```

---

## 🔌 Smart Dispatchers

Commands that adapt to your project:

| Dispatcher    | Example          | What it does                   |
| ------------- | ---------------- | ------------------------------ |
| `cc`          | `cc`             | Claude Code here               |
| `cc`          | `cc pick`        | Pick project → Claude          |
| `r`           | `r test`         | R package tests                |
| `qu`          | `qu preview`     | Quarto preview                 |
| `g`           | `g push`         | Git with safety                |
| `teach`       | `teach init "STAT 545"` | Teaching workflow commands     |

**Get help:** `cc help`, `r help`, `qu help`

---

## 📦 Install in 30 Seconds

=== "Homebrew ⭐"
    ```bash
    brew tap data-wise/tap
    brew install flow-cli
    ```
    **No shell config needed!** Commands work immediately.

=== "Antidote"
    ```bash
    antidote install data-wise/flow-cli
    ```

=== "Zinit"
    ```bash
    zinit light data-wise/flow-cli
    ```

=== "Oh-My-Zsh"
    ```bash
    git clone https://github.com/data-wise/flow-cli.git \
      ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/flow-cli
    # Add flow-cli to plugins in .zshrc
    ```

=== "Manual"
    ```bash
    git clone https://github.com/data-wise/flow-cli.git ~/.flow-cli
    echo 'source ~/.flow-cli/flow.plugin.zsh' >> ~/.zshrc
    ```

**Verify:** `flow doctor`

---

## 📚 Next Steps

<div class="grid cards" markdown>

-   :rocket: { .lg .middle }
    **Quick Start**

    ---

    Get running in 5 minutes

    [→ Quick Start](getting-started/quick-start.md)

-   :fire: { .lg .middle }
    **Dopamine Features**

    ---

    Win tracking, streaks, and goals

    [→ Dopamine](tutorials/06-dopamine-features.md)

-   :books:{ .lg .middle } **Your First Session**

    ---

    Step-by-step tutorial for beginners

    [→ Tutorial](tutorials/01-first-session.md)

-   :compass: { .lg .middle }
    **All Commands**

    ---

    Complete command reference

    [→ Reference](reference/COMMAND-QUICK-REFERENCE.md)

-   :teacher: { .lg .middle }
    **Teaching Commands**

    ---

    Comprehensive command guide (850 lines)

    [→ Commands](guides/TEACHING-COMMANDS-DETAILED.md)

-   :chart_with_upwards_trend: { .lg .middle }
    **Teaching Workflows**

    ---

    Step-by-step visual examples

    [→ Workflows](guides/TEACHING-WORKFLOW-VISUAL.md)

</div>

---

## 🧠 Design Philosophy

!!! abstract "Built for ADHD"

    | Feature | Why It Matters |
    |---------|----------------|
    | **Sub-10ms response** | No waiting = no frustration. `pick` cached (40x faster!) |
    | **Smart defaults** | Works without configuration |
    | **Visible progress** | Dopamine from seeing wins |
    | **Consistent patterns** | Less to memorize |

---

## 🔗 Links

- **[GitHub](https://github.com/Data-Wise/flow-cli)** - Source code
- **[Changelog](CHANGELOG.md)** - Version history
- **[Contributing](contributing/CONTRIBUTING.md)** - Get involved

---

**v5.10.0** · Pure ZSH · MIT License
