---
tags:
  - getting-started
  - adhd
  - commands
---

# Flow CLI

[![Version](https://img.shields.io/github/v/release/Data-Wise/flow-cli?label=version&color=blue)](https://github.com/Data-Wise/flow-cli/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Tests](https://img.shields.io/github/actions/workflow/status/Data-Wise/flow-cli/test.yml?label=tests&branch=main)](https://github.com/Data-Wise/flow-cli/actions/workflows/test.yml)
[![Docs](https://img.shields.io/github/actions/workflow/status/Data-Wise/flow-cli/docs.yml?label=docs&branch=main)](https://github.com/Data-Wise/flow-cli/actions/workflows/docs.yml)
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

!!! success "🎉 What's New in v7.0.0: Email Dispatcher"
    New `em` dispatcher — ADHD-friendly email management powered by himalaya. AI classify/summarize/draft, fzf picker, smart rendering, and batch triage with `em respond`.
    [→ Email Guide](guides/EMAIL-DISPATCHER-GUIDE.md){ .md-button }
    [→ See what's new](CHANGELOG.md){ .md-button }

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

Choose your path based on what you need right now:

<div class="grid cards" markdown>

-   :rocket:{ .lg .middle }
    **5-Minute Quick Start**

    ---

    First session walkthrough

    [→ Quick Start](getting-started/quick-start.md)

-   :books:{ .lg .middle }
    **Step-by-Step Tutorials**

    ---

    30-minute guided learning path

    [→ Tutorial 01](tutorials/01-first-session.md)

-   :fire:{ .lg .middle }
    **Dopamine Features**

    ---

    Win tracking, streaks, goals

    [→ Dopamine Guide](tutorials/06-dopamine-features.md)

-   :email:{ .lg .middle }
    **Email in Neovim**

    ---

    Himalaya + AI email actions

    [→ Email Setup](guides/HIMALAYA-SETUP.md)

-   :compass:{ .lg .middle }
    **Command Reference**

    ---

    Quick lookup for all commands

    [→ Reference](help/QUICK-REFERENCE.md)

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

-   :email:{ .lg .middle }
    **Email Management**

    ---

    AI-powered email with himalaya

    [→ Email Guide](guides/EMAIL-DISPATCHER-GUIDE.md)

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
| `obs` | `obs vaults` / `obs stats` | Obsidian notes |
| `wt` | `wt create` / `wt status` | Worktree management |
| `tm` | `tm title` / `tm ghost` | Terminal manager |
| `dot` | `dot add` / `dot sync` | Dotfile management |
| `prompt` | `prompt toggle` | Prompt engine switcher |
| `v` | `v on` / `v status` | Vibe coding mode |
| `em` | `em inbox` / `em pick` | Email management (himalaya) |

**Get help:** `<dispatcher> help` (e.g., `r help`, `teach help`)

[→ Complete dispatcher guide](reference/MASTER-DISPATCHER-GUIDE.md){ .md-button }

### Core Session Commands

```bash
work <project>    # Start session
finish [note]     # End session
hop <project>     # Quick switch (tmux)
dash              # Dashboard
catch "idea"      # Quick capture
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

**v7.0.0** · Pure ZSH · Zero Dependencies · MIT License
