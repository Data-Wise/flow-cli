# Tutorials

> **Learn flow-cli step by step** - From your first session to advanced workflows.
>
> **Total time:** ~4 hours | **17 tutorials** | **Beginner → Intermediate**

---

## Learning Path

Choose your journey based on what you want to accomplish:

```mermaid
flowchart TD
    subgraph START["🚀 Getting Started"]
        T1["<a href='01-first-session/'>Tutorial 1</a><br/>First Session<br/>⏱ 15 min"]
    end

    subgraph CORE["📦 Core Skills"]
        T2["<a href='02-multiple-projects/'>Tutorial 2</a><br/>Multiple Projects<br/>⏱ 20 min"]
        T3["<a href='03-status-visualizations/'>Tutorial 3</a><br/>Status Visuals<br/>⏱ 15 min"]
        T6["<a href='06-dopamine-features/'>Tutorial 6</a><br/>Dopamine Features<br/>⏱ 15 min"]
    end

    subgraph TOOLS["🔧 Dispatcher Deep Dives"]
        T10["<a href='10-cc-dispatcher/'>Tutorial 10</a><br/>Claude Code<br/>⏱ 20 min"]
        T11["<a href='11-tm-dispatcher/'>Tutorial 11</a><br/>Terminal Manager<br/>⏱ 15 min"]
        T12["<a href='12-dot-dispatcher/'>Tutorial 12</a><br/>Dotfiles & Secrets<br/>⏱ 25 min"]
        T13["<a href='13-prompt-dispatcher/'>Tutorial 13</a><br/>Prompt Engine<br/>⏱ 15 min"]
    end

    subgraph ADVANCED["🎓 Advanced Workflows"]
        T8["<a href='08-git-feature-workflow/'>Tutorial 8</a><br/>Git Workflow<br/>⏱ 20 min"]
        T9["<a href='09-worktrees/'>Tutorial 9</a><br/>Worktrees<br/>⏱ 20 min"]
        T14["<a href='14-teach-dispatcher/'>Tutorial 14</a><br/>Teaching<br/>⏱ 20 min"]
        T21["<a href='21-teach-analyze/'>Tutorial 21</a><br/>Teach Analyze<br/>⏱ 25 min"]
        T22["<a href='22-plugin-optimization/'>Tutorial 22</a><br/>Plugin Optimization<br/>⏱ 20 min"]
        T23["<a href='23-token-automation/'>Tutorial 23</a><br/>Token Automation<br/>⏱ 15 min"]
        T24["<a href='24-template-management/'>Tutorial 24</a><br/>Templates<br/>⏱ 15 min"]
        T25["<a href='25-lesson-plan-migration/'>Tutorial 25</a><br/>Lesson Plans<br/>⏱ 10 min"]
        T26["<a href='26-latex-macros/'>Tutorial 26</a><br/>LaTeX Macros<br/>⏱ 15 min"]
    end

    subgraph OPTIONAL["📚 Optional"]
        T4["<a href='04-web-dashboard/'>Tutorial 4</a><br/>Web Dashboard<br/>⏱ 20 min"]
        T5["<a href='05-ai-commands/'>Tutorial 5</a><br/>AI Commands<br/>⏱ 10 min"]
        T7["<a href='07-sync-command/'>Tutorial 7</a><br/>Sync<br/>⏱ 15 min"]
    end

    T1 --> T2
    T1 --> T3
    T1 --> T6

    T2 --> T8
    T2 --> T10
    T2 --> T11

    T3 --> T4

    T6 --> T12

    T8 --> T9

    T10 --> T14
    T12 --> T14
    T14 --> T21
    T21 --> T22
    T22 --> T23
    T23 --> T24
    T24 --> T25
    T24 --> T26

    T11 --> T13

    classDef beginner fill:#d4edda,stroke:#28a745,color:#155724
    classDef intermediate fill:#fff3cd,stroke:#ffc107,color:#856404
    classDef optional fill:#e2e3e5,stroke:#6c757d,color:#383d41

    class T1,T2,T3,T6,T10,T11,T12,T13 beginner
    class T8,T9,T14,T21,T22,T23,T24,T25,T26 intermediate
    class T4,T5,T7 optional
```

**Legend:** 🟢 Beginner | 🟡 Intermediate | ⚪ Optional

---

## Quick Paths

### 🏃 "I want to start using flow-cli immediately"

1. **[Tutorial 1: First Session](01-first-session.md)** - Track your first work session (15 min)
2. **[Tutorial 6: Dopamine Features](06-dopamine-features.md)** - Log wins, build streaks (15 min)

**Total: 30 minutes to productivity**

---

### 💻 "I use Claude Code daily"

1. **[Tutorial 1: First Session](01-first-session.md)** - Basics (15 min)
2. **[Tutorial 10: CC Dispatcher](10-cc-dispatcher.md)** - Launch Claude anywhere (20 min)
3. **[Tutorial 12: Dot Dispatcher](12-dot-dispatcher.md)** - Manage secrets (25 min)

**Total: 1 hour to Claude mastery**

---

### 🌳 "I work on multiple features simultaneously"

1. **[Tutorial 1: First Session](01-first-session.md)** - Basics (15 min)
2. **[Tutorial 2: Multiple Projects](02-multiple-projects.md)** - Project switching (20 min)
3. **[Tutorial 8: Git Feature Workflow](08-git-feature-workflow.md)** - Feature branches (20 min)
4. **[Tutorial 9: Worktrees](09-worktrees.md)** - Parallel development (20 min)

**Total: 1.25 hours to parallel workflow mastery**

---

### 📚 "I teach courses"

1. **[Tutorial 1: First Session](01-first-session.md)** - Basics (15 min)
2. **[Tutorial 10: CC Dispatcher](10-cc-dispatcher.md)** - Claude for content (20 min)
3. **[Tutorial 14: Teaching Workflow](14-teach-dispatcher.md)** - Full teaching workflow (20 min)

**Total: 55 minutes to teaching workflow**

---

## All Tutorials

| # | Tutorial | Time | Level | What You'll Learn |
|---|----------|------|-------|-------------------|
| 1 | [First Session](01-first-session.md) | 15 min | 🟢 Beginner | Track & complete your first work session |
| 2 | [Multiple Projects](02-multiple-projects.md) | 20 min | 🟢 Beginner | Manage multiple active projects |
| 3 | [Status Visualizations](03-status-visualizations.md) | 15 min | 🟢 Beginner | Understand dashboard visuals |
| 4 | [Web Dashboard](04-web-dashboard.md) | 20 min | ⚪ Optional | Web-based dashboard access |
| 5 | [AI Commands](05-ai-commands.md) | 10 min | ⚪ Optional | AI-powered features overview |
| 6 | [Dopamine Features](06-dopamine-features.md) | 15 min | 🟢 Beginner | Win tracking, streaks, goals |
| 7 | [Sync Command](07-sync-command.md) | 15 min | ⚪ Optional | Sync across multiple machines |
| 8 | [Git Feature Workflow](08-git-feature-workflow.md) | 20 min | 🟡 Intermediate | Git branching workflow |
| 9 | [Worktrees](09-worktrees.md) | 20 min | 🟡 Intermediate | Git worktree management |
| 10 | [CC Dispatcher](10-cc-dispatcher.md) | 20 min | 🟢 Beginner | Launch Claude Code with modes |
| 11 | [TM Dispatcher](11-tm-dispatcher.md) | 15 min | 🟢 Beginner | Terminal management |
| 12 | [DOT Dispatcher](12-dot-dispatcher.md) | 25 min | 🟢 Beginner | Dotfile & secret management |
| 13 | [Prompt Dispatcher](13-prompt-dispatcher.md) | 15 min | 🟢 Beginner | Prompt engine switching |
| 14 | [Teach Dispatcher](14-teach-dispatcher.md) | 20 min | 🟡 Intermediate | Teaching workflow (v5.9.0+) |
| 21 | [Teach Analyze](21-teach-analyze.md) | 25 min | 🟡 Intermediate | AI content analysis (v5.16.0) |
| 22 | [Plugin Optimization](22-plugin-optimization.md) | 20 min | 🟡 Intermediate | Load guards & performance |
| 23 | [Token Automation](23-token-automation.md) | 15 min | 🟡 Intermediate | Smart token management (v5.17.0) ⭐ **NEW** |

**Total estimated time:** ~5 hours (all tutorials)

---

## Prerequisites

Before starting any tutorial, ensure you have:

- [ ] flow-cli installed and loaded in your shell
- [ ] A project directory to work in
- [ ] Basic familiarity with the terminal

**Verify installation:**

```bash
# Check flow-cli is loaded
flow doctor

# If not loaded, add to your .zshrc:
# antidote bundle Data-Wise/flow-cli
```

---

## After the Tutorials

Once you've completed the tutorials, explore:

- **[Workflows](../workflows/)** - Real-world workflow patterns
- **[Guides](../guides/)** - In-depth feature guides
- **[Reference](../reference/)** - Complete command reference

---

**Tip:** Start with Tutorial 1, then follow the arrows in the learning path to your goal!
