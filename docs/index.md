# Flow CLI

> **ZSH workflow tools designed for ADHD brains.**

Start working in 10 seconds. Stay motivated with visible wins. No configuration required.

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

| Dispatcher | Example      | What it does          |
| ---------- | ------------ | --------------------- |
| `cc`       | `cc`         | Claude Code here      |
| `cc`       | `cc pick`    | Pick project → Claude |
| `r`        | `r test`     | R package tests       |
| `qu`       | `qu preview` | Quarto preview        |
| `g`        | `g push`     | Git with safety       |

**Get help:** `cc help`, `r help`, `qu help`

---

## 📦 Install in 30 Seconds

=== "Antidote"
`bash
    antidote install data-wise/flow-cli
    `

=== "Zinit"
`bash
    zinit light data-wise/flow-cli
    `

=== "Oh-My-Zsh"
`bash
    git clone https://github.com/data-wise/flow-cli.git \
      ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/flow-cli
    # Add flow-cli to plugins in .zshrc
    `

=== "Manual"
`bash
    git clone https://github.com/data-wise/flow-cli.git ~/.flow-cli
    echo 'source ~/.flow-cli/flow.plugin.zsh' >> ~/.zshrc
    `

**Verify:** `flow doctor`

---

## 📚 Next Steps

<div class="grid cards" markdown>

- :material-rocket-launch: **[Quick Start](getting-started/quick-start.md)**

  Get running in 5 minutes

- :material-emoticon-happy: **[Dopamine Features](tutorials/06-dopamine-features.md)**

  Win tracking, streaks, goals

- :material-book-open: **[Your First Session](tutorials/01-first-session.md)**

  Step-by-step tutorial

- :material-format-list-bulleted: **[All Commands](reference/COMMAND-QUICK-REFERENCE.md)**

  Complete reference

</div>

---

## 🧠 Design Philosophy

!!! abstract "Built for ADHD"

    | Feature | Why It Matters |
    |---------|----------------|
    | **Sub-10ms response** | No waiting = no frustration |
    | **Smart defaults** | Works without configuration |
    | **Visible progress** | Dopamine from seeing wins |
    | **Consistent patterns** | Less to memorize |

---

## 🔗 Links

- **[GitHub](https://github.com/Data-Wise/flow-cli)** - Source code
- **[Changelog](CHANGELOG.md)** - Version history
- **[Contributing](contributing/CONTRIBUTING.md)** - Get involved

---

**v4.0.1** · Pure ZSH · MIT License
