# Start Here: flow-cli Documentation Hub

**Welcome to flow-cli!** This is your central hub for all documentation.

**Version:** v5.18.0-dev
**Last Updated:** 2026-01-24
**Target Audience:** All users (beginners → advanced)

---

## 🎯 Quick Navigation

Choose your path based on what you need right now:

<details>
<summary><strong>🚀 I'm brand new - where do I start?</strong></summary>

Perfect! Start here for a gentle introduction:

1. **[5-Minute Quick Start](../getting-started/quick-start.md)** ← Start here!
   - Install flow-cli (2 minutes)
   - Your first session (3 minutes)
   - See immediate results

2. **[Choose Your Learning Path](../getting-started/choose-your-path.md)**
   - Role-based paths (developer, researcher, teacher)
   - Skill-based paths (beginner, power user)
   - Time-based paths (weekend warrior, daily driver)

3. **[Tutorial 01: Your First Session](../tutorials/01-first-session.md)**
   - Work command basics
   - Dashboard overview
   - Finishing sessions
   - ADHD-friendly tips

**Estimated Time:** 10-15 minutes to get productive

</details>

<details>
<summary><strong>📖 I want to learn features step-by-step</strong></summary>

Follow our progressive tutorial series:

### Beginner Path (Week 1 - Core Workflows)

1. [Tutorial 01: First Session](../tutorials/01-first-session.md) - work, finish, dash
2. [Tutorial 02: Multiple Projects](../tutorials/02-multiple-projects.md) - hop, pick
3. [Tutorial 03: Status Visualizations](../tutorials/03-status-visualizations.md) - tracking progress
4. [Tutorial 04: Web Dashboard](../tutorials/04-web-dashboard.md) - visual insights

**Time:** 30 minutes total

### Intermediate Path (Week 2 - Smart Dispatchers)

1. [Tutorial 05: AI-Powered Commands](../tutorials/05-ai-commands.md) - AI integration
2. [Tutorial 06: Dopamine Features](../tutorials/06-dopamine-features.md) - Win tracking
3. [Tutorial 07: Sync Command](../tutorials/07-sync-command.md) - Project sync
4. [Tutorial 08: Git Feature Workflow](../tutorials/08-git-feature-workflow.md) - Advanced git

**Time:** 1 hour total

### Advanced Path (Week 3+ - Power User)

1. [Tutorial 09: Worktrees](../tutorials/09-worktrees.md) - wt dispatcher
2. [Tutorial 10: CC Dispatcher](../tutorials/10-cc-dispatcher.md) - Claude Code
3. [Tutorial 11: TM Dispatcher](../tutorials/11-tm-dispatcher.md) - Terminal manager
4. [Tutorial 12: DOT Dispatcher](../tutorials/12-dot-dispatcher.md) - Dotfile management

**See all:** [Complete Tutorial Index](../tutorials/index.md)

</details>

<details>
<summary><strong>⚡ I need a quick command reference</strong></summary>

Jump straight to our cheat sheets:

- **[Quick Reference](QUICK-REFERENCE.md)** ← Single-page command lookup
  - All 12 dispatchers
  - Core commands
  - Keyboard shortcuts
  - Common aliases

- **[Workflows Guide](WORKFLOWS.md)** ← Common workflow patterns
  - Daily workflows (work → finish)
  - Git workflows (feature branches)
  - Project workflows (teaching, research, dev)
  - Plugin workflows (226 git aliases)

- **[Master Reference Guides](../reference/)** ← Comprehensive references
  - [MASTER-DISPATCHER-GUIDE.md](../reference/MASTER-DISPATCHER-GUIDE.md) - All 12 dispatchers
  - [MASTER-API-REFERENCE.md](../reference/MASTER-API-REFERENCE.md) - Complete API
  - [MASTER-ARCHITECTURE.md](../reference/MASTER-ARCHITECTURE.md) - System architecture

**Format:** Copy-paste ready, with expected outputs

</details>

<details>
<summary><strong>🔧 Something's broken - I need help</strong></summary>

Troubleshooting and support:

1. **[Troubleshooting Guide](TROUBLESHOOTING.md)** ← Start here
   - Installation issues
   - Command not found errors
   - Git integration problems
   - Plugin issues
   - Performance problems

2. **[Health Check](TROUBLESHOOTING.md#health-check)**

   ```bash
   flow doctor              # Full health check
   flow doctor --fix        # Interactive fix mode
   flow doctor --dot        # Token check only (< 3s)
   ```

3. **[Common Issues](TROUBLESHOOTING.md#common-issues)**
   - "Command not found: work"
   - "Git remote operation failed"
   - "Atlas connection error"
   - "Slow command response"

4. **[Get Help](https://github.com/Data-Wise/flow-cli/issues)**
   - Search existing issues
   - Create new issue
   - Include `flow doctor` output

</details>

<details>
<summary><strong>🎓 I'm teaching/researching/developing</strong></summary>

Role-specific guides:

### For Teachers

- **[Teaching Workflow Guide](../guides/TEACHING-WORKFLOW-V3-GUIDE.md)** - Complete teaching system
- **[teach Dispatcher Reference](../reference/MASTER-DISPATCHER-GUIDE.md#teach-dispatcher)** - All commands
- **[Scholar Integration](../tutorials/scholar-enhancement/)** - AI-powered course tools

**Quick Start:**

```bash
teach init              # Initialize course
teach analyze           # Content analysis
teach deploy            # Publish to GitHub Pages
```

### For Researchers

- **[r Dispatcher Reference](../reference/MASTER-DISPATCHER-GUIDE.md#r-dispatcher)** - R development workflow
- **[qu Dispatcher Reference](../reference/MASTER-DISPATCHER-GUIDE.md#qu-dispatcher)** - Quarto commands
- **[Quarto Workflow Phase 2](../guides/QUARTO-WORKFLOW-PHASE-2-GUIDE.md)** - Advanced publishing

**Quick Start:**

```bash
r test                  # Run tests
r doc                   # Build documentation
qu preview              # Preview document
```

### For Developers

- **[Git Feature Workflow](../tutorials/08-git-feature-workflow.md)** - Feature branch workflow
- **[Worktree Guide](../tutorials/09-worktrees.md)** - Parallel development
- **[Claude Code Integration](../tutorials/10-cc-dispatcher.md)** - AI pair programming

**Quick Start:**

```bash
g feature start my-feature    # Create feature branch
wt create feature/fix-bug     # Create worktree
cc                            # Launch Claude Code
```

</details>

---

## 📚 Documentation Types

flow-cli has 8 types of documentation - each serves a different purpose:

### 1. Help Files (`docs/help/` - **YOU ARE HERE**)

**Purpose:** Quick-access help for active users

- **[00-START-HERE.md](00-START-HERE.md)** ← This file!
- **[QUICK-REFERENCE.md](QUICK-REFERENCE.md)** - Single-page command lookup
- **[WORKFLOWS.md](WORKFLOWS.md)** - Common workflow patterns
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Issues & solutions

**When to use:** You know what you want but need syntax/options

---

### 2. Getting Started (`docs/getting-started/`)

**Purpose:** Onboarding new users

- [Quick Start](../getting-started/quick-start.md) - 5-minute tutorial
- [Installation](../getting-started/installation.md) - Setup guide
- [Choose Your Path](../getting-started/choose-your-path.md) - Learning paths
- [FAQ](../getting-started/faq.md) - Common questions

**When to use:** First time using flow-cli

---

### 3. Tutorials (`docs/tutorials/`)

**Purpose:** Step-by-step learning (5-10 minutes each)

- **Beginner** (01-04): Core workflows
- **Intermediate** (05-12): Dispatchers & features
- **Advanced** (13-23): Power user features
- **Plugins** (24-31): Plugin integration

**When to use:** Want to learn a specific feature hands-on

**See:** [Complete Tutorial Index](../tutorials/index.md)

---

### 4. Guides (`docs/guides/`)

**Purpose:** Comprehensive topic guides (15-30 minutes)

- [Teaching Workflow](../guides/TEACHING-WORKFLOW-V3-GUIDE.md)
- [ZSH Plugin Ecosystem](../guides/ZSH-PLUGIN-ECOSYSTEM-GUIDE.md)
- [Dopamine Features](../guides/DOPAMINE-FEATURES-GUIDE.md)
- [Testing Guide](../guides/TESTING.md)

**When to use:** Need deep understanding of a workflow or feature

**See:** [All Guides](../guides/00-START-HERE.md)

---

### 5. Reference (`docs/reference/`)

**Purpose:** Complete technical reference (lookup)

- **[MASTER-DISPATCHER-GUIDE.md](../reference/MASTER-DISPATCHER-GUIDE.md)** - All 12 dispatchers (3,000-4,000 lines)
- **[MASTER-API-REFERENCE.md](../reference/MASTER-API-REFERENCE.md)** - Complete API (5,000-7,000 lines)
- **[MASTER-ARCHITECTURE.md](../reference/MASTER-ARCHITECTURE.md)** - System architecture (2,000-3,000 lines)

**When to use:** Need exact function signature or advanced details

---

### 6. Commands (`docs/commands/`)

**Purpose:** Individual command documentation

- Each command has dedicated file
- Synopsis, options, examples
- See also links

**When to use:** Need full details on a specific command

---

### 7. Contributing (`docs/contributing/`)

**Purpose:** Contributor guidelines

- [Documentation Style Guide](../contributing/DOCUMENTATION-STYLE-GUIDE.md) ← Documentation standards
- [Branch Workflow](../contributing/BRANCH-WORKFLOW.md) - Git workflow
- [Testing Guide](../guides/TESTING.md) - Test suite

**When to use:** Contributing code or documentation

---

### 8. Architecture (`docs/architecture/`)

**Purpose:** Design decisions and architecture

- ADR format
- Mermaid diagrams
- Trade-off analysis

**When to use:** Understanding design decisions

---

## 🗺️ Learning Paths

Choose a path based on your goals:

### Path 1: Developer (Daily Driver)

**Goal:** Use flow-cli for all development work

**Time:** 2 hours total

```
Week 1: Core Workflows (30 min)
  → Tutorial 01-04 (work, hop, catch, git basics)

Week 2: Dispatchers (1 hour)
  → Tutorial 07-09 (cc, git workflows, worktrees)

Week 3: Plugins (30 min)
  → Tutorial 24 (Git workflow - 226 aliases)
```

**Success:** Replace manual git commands with flow-cli dispatchers

---

### Path 2: Teacher

**Goal:** Manage teaching workflows with Scholar integration

**Time:** 1.5 hours total

```
Week 1: Teaching Basics (30 min)
  → Teaching Workflow Guide

Week 2: Content Analysis (45 min)
  → Tutorial 21 (teach analyze)

Week 3: Scholar Enhancement (15 min)
  → Scholar Enhancement Tutorials
```

**Success:** Full course management with AI assistance

---

### Path 3: Researcher

**Goal:** R package development and Quarto publishing

**Time:** 1 hour total

```
Week 1: R Workflow (30 min)
  → Tutorial 05 (r dispatcher)
  → R Package Guide

Week 2: Quarto Publishing (30 min)
  → Tutorial 06 (qu dispatcher)
  → Quarto Workflow Guide
```

**Success:** Streamlined R development and publishing

---

### Path 4: Weekend Warrior (Fastest Path)

**Goal:** Get productive in 30 minutes

**Time:** 30 minutes total

```
Now: Quick Start (5 min)
  → Install + first session

+10 min: Core Commands (10 min)
  → work, dash, finish, hop

+15 min: One Dispatcher (15 min)
  → Choose: g (git), r (R), cc (Claude), or teach
```

**Success:** Basic productivity immediately

---

## 🔍 How to Find What You Need

### If You Know What You Want

```bash
# In terminal (uses grep)
grep -r "search term" ~/projects/dev-tools/flow-cli/docs/

# On website (uses search bar)
# https://Data-Wise.github.io/flow-cli/
# Click search icon (magnifying glass)
```

---

### If You're Exploring

Use the **progressive disclosure** approach:

1. **Start broad** - [Choose Your Path](../getting-started/choose-your-path.md)
2. **Go specific** - Pick a tutorial from your path
3. **Go deep** - Read related guide
4. **Reference** - Look up exact syntax in MASTER guides

---

### If You're Lost

**No problem!** Try:

1. **[FAQ](../getting-started/faq.md)** - Common questions
2. **[Troubleshooting](TROUBLESHOOTING.md)** - Common issues
3. **[GitHub Issues](https://github.com/Data-Wise/flow-cli/issues)** - Search/ask

---

## 🎮 Interactive Learning

### Command Completions

flow-cli has rich tab completions:

```bash
work <Tab>           # See all projects
g <Tab>              # See all git commands
teach <Tab>          # See all teach commands
```

**Enable completions:** Automatic with plugin managers (antidote, zinit, oh-my-zsh)

---

### Built-in Help

Every dispatcher has help:

```bash
g help               # Git dispatcher help
r help               # R dispatcher help
teach help           # Teaching dispatcher help
mcp help             # MCP dispatcher help
```

**Pattern:** `<dispatcher> help` always works

---

### Health Check

Verify everything works:

```bash
flow doctor          # Full health check (~60s)
flow doctor --fix    # Interactive fixes
flow doctor --dot    # Token check only (< 3s)
```

**When to run:**

- After installation
- Before reporting issues
- Monthly maintenance

---

## 📊 Documentation Stats

**Status:** Consolidated (v5.18.0-dev)

- **Master Documents:** 7 (QUICK-REFERENCE, WORKFLOWS, TROUBLESHOOTING, MASTER-DISPATCHER-GUIDE, MASTER-API-REFERENCE, MASTER-ARCHITECTURE, 00-START-HERE)
- **Tutorials:** 23+ (01-23, plus Scholar enhancement)
- **Guides:** 15+ (topic-focused deep dives)
- **Reference Files:** 3 master documents + archive
- **Total Documentation Files:** 360+ markdown files

**Coverage:**

- Commands: 100% (all core commands documented)
- Dispatchers: 100% (all 12 dispatchers)
- Functions: 13.8% (704 functions, 97 documented) - Growing daily!
- Tutorials: 23 complete

---

## 🚀 What's Next?

After reading this guide, you should:

1. **New users:** [Quick Start](../getting-started/quick-start.md) (5 minutes)
2. **Returning users:** [Quick Reference](QUICK-REFERENCE.md) (lookup)
3. **Contributors:** [Documentation Style Guide](../contributing/DOCUMENTATION-STYLE-GUIDE.md)

---

## 💡 Pro Tips

### ADHD-Friendly Features

- **Progressive Disclosure:** Start simple, add complexity gradually
- **Quick Wins:** Every tutorial has immediate payoff
- **Visual Hierarchy:** Headings, bullets, tables for scanning
- **Time Estimates:** Know how long each section takes
- **Concrete Examples:** Real commands, real projects, real outputs

### Documentation Navigation

- **Search First:** Use website search or `grep`
- **Follow Paths:** Tutorials → Guides → Reference
- **Use Completions:** Tab completion shows options
- **Check Help:** `<command> help` always available

### Maintenance

- **Monthly:** Run `flow doctor` health check
- **Quarterly:** Review new features in CHANGELOG
- **Releases:** Read migration notes for breaking changes

---

## 📝 Feedback

Help us improve documentation:

- **Found an error?** [Create issue](https://github.com/Data-Wise/flow-cli/issues/new)
- **Missing topic?** [Request tutorial](https://github.com/Data-Wise/flow-cli/issues/new)
- **Unclear section?** [Suggest improvement](https://github.com/Data-Wise/flow-cli/issues/new)

---

**Last Updated:** 2026-01-24
**Version:** v5.18.0-dev
**Contributors:** See [CHANGELOG.md](../CHANGELOG.md)

---

## Quick Links

- [Website](https://Data-Wise.github.io/flow-cli/)
- [GitHub](https://github.com/Data-Wise/flow-cli)
- [Issues](https://github.com/Data-Wise/flow-cli/issues)
- [Changelog](../CHANGELOG.md)
- [Contributing](../contributing/CONTRIBUTING.md)
