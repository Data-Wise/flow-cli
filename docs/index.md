---
tags:
  - getting-started
  - adhd
  - commands
---

# Flow CLI

[![Version](https://img.shields.io/github/v/release/Data-Wise/flow-cli?label=version&color=blue&cacheSeconds=300)](https://github.com/Data-Wise/flow-cli/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-green)](https://github.com/Data-Wise/flow-cli/blob/main/LICENSE)
[![Tests](https://img.shields.io/github/actions/workflow/status/Data-Wise/flow-cli/test.yml?label=tests&branch=main&cacheSeconds=300)](https://github.com/Data-Wise/flow-cli/actions/workflows/test.yml)
[![Docs](https://img.shields.io/github/actions/workflow/status/Data-Wise/flow-cli/docs.yml?label=docs&branch=main&cacheSeconds=300)](https://github.com/Data-Wise/flow-cli/actions/workflows/docs.yml)
[![Pure ZSH](https://img.shields.io/badge/pure-ZSH-1f425f)](https://www.zsh.org/)
[![ADHD-Friendly](https://img.shields.io/badge/ADHD-friendly-purple)](PHILOSOPHY.md)

> **ZSH workflow tools designed for ADHD brains.**
>
> Start working in 10 seconds. Stay motivated with visible wins.

!!! tldr "⚡ Get Started in 30 Seconds"
    ```bash
    brew tap data-wise/tap && brew install flow-cli
    work my-project         # Start session
    win "installed flow!"   # Log your first win
    ```
    **That's it!** No configuration required.

    **New here?** `setup` walks you through configuration interactively, or run `tutorial` for
    12 hands-on lessons at your own pace — both are guided, no docs required to start.

!!! success "🎉 What's New in v7.17.1"
    **`teach deploy --dry-run` is genuinely read-only** — it no longer aborts in CI mode, no longer prompts to commit (a pty wrapper used to auto-accept that and create a real commit), and it now names the uncommitted files its plan excludes.
    **`teach deploy --direct` merges with `--no-ff`** — every deploy is one revertable commit again, so `teach deploy --rollback` can undo a multi-commit deploy as a unit.
    **`em undo`** — single-step undo of the last `em star`/`flag`/`unflag`/`move`, plus `em move --recent` for quick folder re-picks.
    **Shipped pipelines are alias-proof** — a user alias on a coreutil (e.g. `tr`) could hijack internal pipelines and replace counts with unrelated output; all 101 sites now use `command tr`.
    Full details → [Changelog](CHANGELOG.md).

---

## ⚡ See It in Action

The entire workflow in 3 commands:

```bash
work my-project    # Start session
win "Fixed bug"    # Log win → dopamine hit
finish             # Done
```

**Expected output:**

```text
$ work my-project
🚀 Starting session: my-project
   📍 ~/projects/my-project

$ win "Fixed the login bug"
🔧 fix: Fixed the login bug
   ✨ Win #1 today!

$ finish
✅ Session complete
   💾 Changes saved
```

!!! tip "Everything else is optional enhancement"
    These 3 commands are the core. Dispatchers (`cc`, `r`, `qu`, `teach`), dopamine tracking
    (`yay`, `flow goal`), and advanced features are bonuses.

??? example "📺 Demo GIF"
    ![flow-cli demo](assets/demo.gif)

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

## 🏆 Built-in Dopamine System

Every win gets categorized and tracked:

```bash
win "Fixed login bug"       # → 🔧 fix
win "Deployed to prod"      # → 🚀 ship
win "Added tests"           # → 🧪 test
```

**See your progress:**

```bash
yay              # Recent wins
yay --week       # Weekly graph
flow goal        # Daily progress (🌱🔥🔥🔥 streaks!)
```

[→ Learn about dopamine features](tutorials/06-dopamine-features.md){ .md-button }

---

## 📦 Installation

=== "Homebrew ⭐ Recommended"
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
    # Add 'flow-cli' to plugins array in .zshrc
    ```

=== "Manual"
    ```bash
    git clone https://github.com/data-wise/flow-cli.git ~/.flow-cli
    echo 'source ~/.flow-cli/flow.plugin.zsh' >> ~/.zshrc
    ```

**Verify installation:** `flow doctor`

---

## 🧭 Next Steps

Three questions, pick the one that matches where you are — not eight options at once.

### 🆕 New here?

<div class="grid cards" markdown>

-   :rocket:{ .lg .middle }
    **5-Minute Quick Start**

    ---

    First session walkthrough

    [→ Quick Start](getting-started/quick-start.md)

-   :wrench:{ .lg .middle }
    **Interactive Setup Wizard**

    ---

    Guided configuration — run `setup` in your terminal

    [→ Setup Command](commands/setup.md)

-   :books:{ .lg .middle }
    **Step-by-Step Tutorials**

    ---

    12 hands-on lessons — run `tutorial`, or read online

    [→ Tutorial 01](tutorials/01-first-session.md)

-   :fire:{ .lg .middle }
    **Dopamine Features**

    ---

    How the win/streak/goal loop works

    [→ Dopamine Guide](tutorials/06-dopamine-features.md)

</div>

### 🔧 Solve a specific problem

<div class="grid cards" markdown>

-   :email:{ .lg .middle }
    **Email Management**

    ---

    CLI + Neovim email with himalaya

    [→ CLI Guide](guides/EMAIL-DISPATCHER-GUIDE.md) ·
    [→ Neovim Setup](guides/HIMALAYA-NVIM-SETUP.md)

-   :key:{ .lg .middle }
    **Tokens & Secrets**

    ---

    Auto-sync tokens to GitHub Actions secrets

    [→ Token Cookbook](guides/TOKEN-COOKBOOK.md) ·
    [→ Auto-sync Tutorial](tutorials/47-tok-auto-sync.md)

-   :teacher:{ .lg .middle }
    **Teaching Workflow**

    ---

    Deploy courses in 8-15 seconds

    [→ Teaching Guide](guides/TEACHING-SYSTEM-ARCHITECTURE.md)

-   :mag:{ .lg .middle }
    **Common Workflows**

    ---

    Solve specific problems fast

    [→ Workflows](guides/WORKFLOWS-QUICK-WINS.md)

</div>

### 📚 Already using it? Look something up

<div class="grid cards" markdown>

-   :compass:{ .lg .middle }
    **Command Reference**

    ---

    Quick lookup for all commands — also try `ref` in your terminal

    [→ Reference](help/QUICK-REFERENCE.md)

-   :calendar:{ .lg .middle }
    **Daily & Weekly Cookbook**

    ---

    Copy-paste routines for the two cadences flow-cli is built around

    [→ Cookbook](guides/WORKFLOW-COOKBOOK.md)

</div>

---

## 🔌 Command Architecture

### Smart Dispatchers

Commands that adapt to your project type:

| Dispatcher | Example | What it does |
| ---------- | ------- | ------------ |
| `cc` | `cc` / `cc pick` | Launch Claude Code (here or picker) |
| `r` | `r test` / `r check` | R package development |
| `qu` | `qu preview` / `qu render` | Quarto publishing |
| `g` | `g push` / `g commit` | Git with smart safety |
| `teach` | `teach init` / `teach deploy` | Teaching workflow |
| `mcp` | `mcp status` / `mcp logs` | MCP server management |
| `wt` | `wt create` / `wt status` | Worktree management |
| `tm` | `tm title` / `tm ghost` | Terminal manager |
| `dots` | `dots edit` / `dots sync` | Dotfile management |
| `sec` | `sec add` / `sec list` | Secret management |
| `tok` | `tok github` / `tok rotate` | Token management |
| `prompt` | `prompt toggle` | Prompt engine switcher |
| `v` | `v on` / `v status` | Vibe coding mode |
| `em` | `em inbox` / `em pick` / `em forward` | Email: 38 commands (read, reply, forward, AI, organize, manage) |

**Get help:** `<dispatcher> help` (e.g., `r help`, `teach help`)

[→ Complete dispatcher guide](reference/MASTER-DISPATCHER-GUIDE.md){ .md-button }

### Core Session Commands

```bash
work <project>    # Start session
finish [note]     # End session
hop <project>     # Quick switch (tmux)
dash              # Dashboard (what's happening now)
agenda            # What's due soon (deadlines, exams, milestones)
catch "idea"      # Quick capture
ref               # Quick-reference card (forgot the syntax? this is faster than docs)
```

[→ All commands](help/QUICK-REFERENCE.md){ .md-button }

---

## 🧠 Design Philosophy

!!! abstract "Built for ADHD Brains"
    | Principle | Implementation |
    | --------- | -------------- |
    | **Sub-10ms response** | No waiting = no frustration |
    | **Smart defaults** | Works without configuration |
    | **Visible progress** | Dopamine from seeing wins |
    | **Consistent patterns** | Less to memorize |
    | **Forgiving** | Hard to break things |

[→ Read full philosophy](PHILOSOPHY.md){ .md-button }

---

## 🔗 Links & Resources

- **[GitHub Repository](https://github.com/Data-Wise/flow-cli)** - Source code, issues, discussions
- **[Release Notes](RELEASES.md)** - What's new in each version
- **[Changelog](CHANGELOG.md)** - Complete version history
- **[Contributing](contributing/CONTRIBUTING.md)** - Get involved
- **[Philosophy](PHILOSOPHY.md)** - Design principles deep dive

---

**v7.17.2** · Pure ZSH · Zero Dependencies · MIT License
