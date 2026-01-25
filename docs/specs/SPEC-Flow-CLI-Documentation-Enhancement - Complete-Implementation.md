# Flow CLI Documentation Enhancement - Complete Implementation Guide

**Version:** 1.0  
**Date:** January 11, 2026  
**Branch:** docs/adhd-friendly-enhancements  
**Author:** Documentation Enhancement Project

---

## 📋 Table of Contents

1. [Quick Start Instructions](#quick-start-instructions)
2. [File Structure Overview](#file-structure-overview)
3. [Implementation Checklist](#implementation-checklist)
4. [File Contents](#file-contents)
   - [File 1: im-stuck.md](#file-1-im-stuckmd)
   - [File 2: choose-your-path.md](#file-2-choose-your-pathmd)
   - [File 3: quick-reference-card.md](#file-3-quick-reference-cardmd)
   - [File 4: extra.css](#file-4-extracss)
   - [File 5: index.md (modifications)](#file-5-indexmd-modifications)
   - [File 6: mkdocs.yml (modifications)](#file-6-mkdocsyml-modifications)
5. [Git Commands](#git-commands)
6. [Testing Checklist](#testing-checklist)
7. [Pull Request Template](#pull-request-template)

---

## Quick Start Instructions

### Step 1: Save This File

Save this entire document as `flow-cli-docs-implementation.md` somewhere easy to access.

### Step 2: Navigate to Your Repo

````bash
cd /path/to/flow-cli
git checkout main
git pull origin main
````

### Step 3: Create Feature Branch

````bash
git checkout -b docs/adhd-friendly-enhancements
````

### Step 4: Create Directory Structure

````bash
mkdir -p docs/stylesheets
````

### Step 5: Create Files

Copy each file section below into the appropriate location.

### Step 6: Commit and Push

````bash
git add .
git commit -m "docs: add ADHD-friendly enhancements - Phase 1"
git push origin docs/adhd-friendly-enhancements
````

---

## File Structure Overview

````
flow-cli/
├── docs/
│   ├── getting-started/
│   │   ├── im-stuck.md                  [NEW]
│   │   ├── choose-your-path.md          [NEW]
│   │   └── 00-welcome.md                [MODIFY]
│   ├── quick-reference-card.md          [NEW]
│   ├── index.md                         [MODIFY]
│   └── stylesheets/
│       └── extra.css                    [NEW]
└── mkdocs.yml                           [MODIFY]
````

---

## Implementation Checklist

- [ ] Create feature branch `docs/adhd-friendly-enhancements`
- [ ] Create directory `docs/stylesheets/`
- [ ] Add File 1: `docs/getting-started/im-stuck.md`
- [ ] Add File 2: `docs/getting-started/choose-your-path.md`
- [ ] Add File 3: `docs/quick-reference-card.md`
- [ ] Add File 4: `docs/stylesheets/extra.css`
- [ ] Modify File 5: `docs/index.md`
- [ ] Modify File 6: `mkdocs.yml`
- [ ] Test with `mkdocs serve`
- [ ] Check all links work
- [ ] Verify print layout (reference card)
- [ ] Test mobile responsive design
- [ ] Commit changes
- [ ] Push to GitHub
- [ ] Create Pull Request

---

## File Contents

---

### File 1: im-stuck.md

**Location:** `docs/getting-started/im-stuck.md`

**Action:** CREATE NEW FILE

````markdown
---
title: 🆘 I'm Stuck - Troubleshooting Guide
description: Quick solutions when Flow CLI isn't working as expected
---

# 🆘 I'm Stuck

!!! tldr "TL;DR - Try These First (30 seconds)"
```bash
    source ~/.zshrc              # Reload shell
    flow doctor                  # Run diagnostics
    ls ~/.config/zsh/functions/  # Check installation
```

---

## 🔧 Quick Fixes

Try these in order - most common solutions first:

### ❌ "Command not found: dash" / "Command not found: work"

**What this means:** Flow CLI commands aren't loaded in your shell.

**Fix it:**
```bash
# Option 1: Reload your shell config
source ~/.zshrc

# Option 2: Check if functions file exists
ls ~/.config/zsh/functions/adhd-helpers.zsh

# Option 3: Reinstall
brew reinstall flow-cli  # If using Homebrew
```

**Why this works:** Shell needs to source the Flow CLI functions after installation.

---

### ❌ "No projects found"

**What this means:** Flow CLI can't find any projects with `.STATUS` files.

**Fix it:**
```bash
# Check your projects directory
ls ~/projects/

# Create .STATUS for an existing project
cd ~/projects/your-project
status your-project --create

# Or use quick mode
status your-project ready P2 "Initial setup"
```

**Why this works:** Flow CLI tracks projects using `.STATUS` files.

---

### ❌ "Editor didn't open" / "work command does nothing"

**What this means:** Project type not detected or editor not in PATH.

**Fix it:**
```bash
# Check what's in your project
cd ~/projects/your-project
ls -la

# Manually open your preferred editor
code .        # VS Code
rstudio .     # RStudio  
emacs .       # Emacs

# Check if editor is in PATH
which code    # Should show path to executable
```

**Why this works:** `work` command tries to auto-detect project type. If detection fails, use editor directly.

---

### ❌ Timer not showing / "f25 command not found"

**What this means:** Timer functions not loaded or tmux not installed.

**Fix it:**
```bash
# Check if tmux is installed
which tmux

# Install if needed (macOS)
brew install tmux

# Reload shell
source ~/.zshrc
```

---

### ❌ Wins not logging / "win command does nothing"

**What this means:** Worklog file permissions or path issue.

**Fix it:**
```bash
# Check worklog file
ls -la ~/.config/zsh/.worklog

# Create if missing
touch ~/.config/zsh/.worklog
chmod 644 ~/.config/zsh/.worklog

# Try again
win "Test win"
```

---

## 🔍 Still Stuck?

### Run Full Diagnostics
```bash
flow doctor
```

This checks:
- ✓ Installation paths
- ✓ Required dependencies
- ✓ Configuration files
- ✓ Project detection
- ✓ Common issues

### Check Your Setup
```bash
# Verify installation
echo $PATH | grep flow-cli

# Check ZSH config
cat ~/.zshrc | grep flow

# Verify project structure
tree ~/projects/ -L 2
```

---

## 🆘 Emergency Contacts

### Search the Docs
Use the search bar (top right) to find specific commands or concepts.

### Common Issues Database
- [Installation Problems](troubleshooting.md#installation)
- [Project Detection Issues](../reference/.archive/PROJECT-DETECTION-GUIDE.md)
- [Command Reference](../help/QUICK-REFERENCE.md)

### Ask the Community
- **GitHub Discussions**: [Ask a Question](https://github.com/data-wise/flow-cli/discussions)
- **GitHub Issues**: [Report a Bug](https://github.com/data-wise/flow-cli/issues/new)

---

## 📚 Next Steps

Once you're unstuck:

!!! success "You're back on track!"
    - [Try the Quick Start →](quick-start.md)
    - [Complete Your First Session →](../tutorials/01-first-session.md)
    - [Learn Core Commands →](../help/QUICK-REFERENCE.md)
````

---

### File 2: choose-your-path.md

**Location:** `docs/getting-started/choose-your-path.md`

**Action:** CREATE NEW FILE

````markdown
---
title: Choose Your Learning Path
description: Find the right starting point for your goals
---

# 🎯 Choose Your Learning Path

**Welcome!** Let's find the best way for you to learn Flow CLI based on what you want to accomplish.

---

## 🚀 "Just Make It Work" (5 minutes)

**Perfect if you:** Want to see results immediately, learn by doing

**You'll get:** Working installation + first successful command

[→ Start Quick Start](quick-start.md){ .md-button .md-button--primary }

---

## 📚 "Teach Me Properly" (30 minutes)

**Perfect if you:** Want to understand the system, build solid foundations

**You'll get:** Complete understanding of core workflow + hands-on practice

**Path:**
1. [Install & Verify](installation.md) (5 min)
2. [Your First Session Tutorial](../tutorials/01-first-session.md) (15 min)
3. [Multiple Projects Tutorial](../tutorials/02-multiple-projects.md) (10 min)

[→ Start Tutorial Path](../tutorials/01-first-session.md){ .md-button .md-button--primary }

---

## 🎯 "Solve My Problem" (2 minutes)

**Perfect if you:** Have a specific issue or task right now

**Choose your scenario:**

### I need to...

=== "Track my work sessions"
    **Solution:** [Session Tracking Workflow](../guides/WORKFLOWS-QUICK-WINS.md#quick-test-cycle)
```bash
    work my-project
    win "Completed feature X"
    finish
```

=== "Manage multiple projects"
    **Solution:** [Project Management Guide](../tutorials/02-multiple-projects.md)
```bash
    dash              # See all projects
    pick              # Choose one
    hop other-project # Quick switch
```

=== "See my progress/stats"
    **Solution:** [Dopamine Features Guide](../guides/DOPAMINE-FEATURES-GUIDE.md)
```bash
    wins              # Today's wins
    yay --week        # Weekly summary
    flow goal         # Progress tracking
```

=== "Set up dotfile management"
    **Solution:** [Dotfile Workflow](../guides/DOT-WORKFLOW.md)
```bash
    dot status        # Check dotfiles
    dot link          # Create symlinks
    dot push          # Backup to git
```

=== "Integrate with git workflow"
    **Solution:** [Git Feature Workflow](../tutorials/08-git-feature-workflow.md)
```bash
    g new feature-x   # Start feature
    g push            # Safe push with checks
    g done            # Merge and cleanup
```

---

## 🔍 "Look Something Up" (30 seconds)

**Perfect if you:** Already using Flow CLI, need quick reference

[→ Command Cheatsheet](../help/QUICK-REFERENCE.md){ .md-button }
[→ Search Docs](../../search.md){ .md-button }

---

## 💡 "Understand the Philosophy" (10 minutes)

**Perfect if you:** Want to know *why* Flow CLI works this way

[→ Design Philosophy](../PHILOSOPHY.md){ .md-button }
[→ ADHD-Optimized Design](../conventions/adhd/){ .md-button }

---

## ❓ "I'm Completely Lost"

**Start here if:** Nothing makes sense yet, feeling overwhelmed

[→ Emergency Help](im-stuck.md){ .md-button .md-button--primary }

---

## 🎮 Learning Style Quiz

Not sure which path? Answer these questions:

1. **How do you prefer to learn?**
   - "Show me, I'll figure it out" → Quick Start
   - "Explain it step by step" → Tutorial Path
   - "Let me search when I need it" → Reference Docs

2. **How much time do you have right now?**
   - 5 minutes → Quick Start
   - 30 minutes → Tutorial Path
   - 2 minutes → Workflow Browser

3. **What's your goal today?**
   - Get something done NOW → Workflow Browser
   - Learn the system properly → Tutorial Path
   - Fix a problem → Troubleshooting

---

!!! tip "Pro Tip: Bookmark This Page"
    You can always come back here if you want to switch paths or try a different approach.
````

---

### File 3: quick-reference-card.md

**Location:** `docs/quick-reference-card.md`

**Action:** CREATE NEW FILE

````markdown
---
title: 📋 Starter Quick Reference Card
description: Essential commands on one page - print friendly
---

# 📋 Flow CLI Starter Card

!!! info "💾 Printable Version"
    Use your browser's print function (Cmd/Ctrl+P) to save as PDF

---

## 🚀 Core Commands (Start Here)

| Command | What It Does | Example |
|---------|-------------|---------|
| `dash` | 📊 Show all projects | `dash` |
| `work <project>` | 🎯 Start working on project | `work my-app` |
| `why` | 📍 Show current context | `why` |
| `win "message"` | ✅ Log accomplishment | `win "Fixed bug"` |
| `finish` | 🏁 End session | `finish` |
| `pick` | 🔍 Search/pick project | `pick` |

---

## ⚡ Quick Workflows

### Start Your Day
```bash
dash              # See all projects
just-start        # Auto-pick high priority
work .            # Open in editor
f25               # Start 25-min timer
```

### During Work
```bash
why               # Where am I?
win "did thing"   # Log progress
hop other         # Switch project
```

### End of Day
```bash
status .          # Update progress
wins              # See today's wins
finish            # Close session
```

---

## 🏆 Progress Tracking

| Command | Shows |
|---------|-------|
| `wins` | Today's accomplishments |
| `yay` | Recent wins list |
| `yay --week` | Weekly summary graph |
| `flow goal` | Daily progress bar |
| `trail` | Your breadcrumb trail |

---

## 🔌 Smart Dispatchers

### R Package Development: `r`
```bash
r load            # Load package
r test            # Run tests
r doc             # Generate docs
r help            # Show all commands
```

### Git with Safety: `g`
```bash
g status          # Safe git status
g push            # Push with checks
g new feature-x   # Start feature branch
g help            # Show all commands
```

### Claude Code: `cc`
```bash
cc pick           # Open project in Claude
cc ask "query"    # Ask Claude
cc help           # Show all commands
```

---

## 🔥 Timers & Focus

| Command | Duration | Use For |
|---------|----------|---------|
| `f25` | 25 minutes | Pomodoro |
| `f50` | 50 minutes | Deep work |
| `f <num>` | Custom | Any duration |

---

## 🆘 Emergency Commands

| Problem | Solution |
|---------|----------|
| Commands not found | `source ~/.zshrc` |
| Check if installed | `flow doctor` |
| No projects showing | `status <name> --create` |
| Editor won't open | `code .` manually |

---

## 🎯 Status Values

**State:** `active`, `paused`, `blocked`, `ready`, `done`

**Priority:** `P0` (urgent) → `P4` (someday)

**Update status:**
```bash
status my-project active P0 "Next task description"
```

---

## 📚 Get More Help

- **Full docs:** [https://data-wise.github.io/flow-cli](https://data-wise.github.io/flow-cli)
- **Stuck?:** [Troubleshooting Guide](getting-started/im-stuck.md)
- **Commands:** [Complete Reference](help/QUICK-REFERENCE.md)
- **Community:** [GitHub Discussions](https://github.com/data-wise/flow-cli/discussions)

---

<small>Flow CLI v5.2.0 | MIT License | [github.com/data-wise/flow-cli](https://github.com/data-wise/flow-cli)</small>
````

---

### File 4: extra.css

**Location:** `docs/stylesheets/extra.css`

**Action:** CREATE NEW FILE

````css
/* ADHD-Friendly Styling Enhancements for Flow CLI Documentation */

/* Progress Bar Styling */
.progress-bar {
    background: #e0e0e0;
    border-radius: 8px;
    height: 24px;
    margin: 1em 0;
    overflow: hidden;
}

.progress-fill {
    background: linear-gradient(90deg, #4CAF50 0%, #8BC34A 100%);
    height: 100%;
    transition: width 0.3s ease;
    display: flex;
    align-items: center;
    padding: 0 10px;
    color: white;
    font-weight: bold;
    font-size: 0.9em;
}

/* Reference Card Print Styling */
@media print {
    .md-sidebar, .md-header, .md-footer, .md-nav {
        display: none !important;
    }
    
    .reference-card {
        break-inside: avoid;
        page-break-inside: avoid;
    }
    
    body {
        font-size: 10pt;
        line-height: 1.4;
    }
    
    table {
        font-size: 9pt;
    }
    
    .md-content {
        max-width: 100%;
    }
}

/* ADHD-Friendly Content Boxes */
.tldr-box {
    background: #e8f5e9;
    border-left: 4px solid #4CAF50;
    padding: 1em 1.5em;
    margin: 1.5em 0;
    border-radius: 4px;
}

.quick-win {
    background: #fff3e0;
    border-left: 4px solid #FF9800;
    padding: 0.8em 1.2em;
    margin: 1em 0;
    border-radius: 4px;
}

.checkpoint {
    background: #e3f2fd;
    border-left: 4px solid #2196F3;
    padding: 1em 1.5em;
    margin: 1.5em 0;
    border-radius: 4px;
}

.context-reminder {
    background: #f3e5f5;
    border-left: 4px solid #9C27B0;
    padding: 0.8em 1.2em;
    margin: 1em 0;
    border-radius: 4px;
    font-style: italic;
}

/* Success Indicators */
.success-indicator {
    background: #e8f5e9;
    padding: 1em 1.5em;
    border-radius: 8px;
    margin: 1em 0;
    border: 1px solid #4CAF50;
}

.success-indicator::before {
    content: "✓ ";
    color: #4CAF50;
    font-weight: bold;
    font-size: 1.2em;
}

/* Warning/Error Boxes */
.common-mistake {
    background: #ffebee;
    border-left: 4px solid #f44336;
    padding: 0.8em 1.2em;
    margin: 1em 0;
    border-radius: 4px;
}

.common-mistake::before {
    content: "⚠️ ";
    font-weight: bold;
}

/* Copy Button Enhancement */
.md-clipboard {
    background: #4CAF50 !important;
    color: white !important;
    transition: all 0.3s ease;
}

.md-clipboard:hover {
    background: #45a049 !important;
    transform: scale(1.05);
}

/* Grid Cards for Path Selection */
.grid.cards {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 1rem;
    margin: 2rem 0;
}

.grid.cards > div {
    border: 1px solid #e0e0e0;
    border-radius: 8px;
    padding: 1.5rem;
    transition: all 0.3s ease;
    background: white;
}

.grid.cards > div:hover {
    box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    transform: translateY(-2px);
    border-color: #4CAF50;
}

/* Button Enhancements */
.md-button {
    transition: all 0.3s ease;
}

.md-button:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 8px rgba(0,0,0,0.2);
}

.md-button--primary {
    background-color: #4CAF50 !important;
}

.md-button--primary:hover {
    background-color: #45a049 !important;
}

/* Table Enhancements for Reference Cards */
.reference-card table {
    width: 100%;
    border-collapse: collapse;
    margin: 1em 0;
}

.reference-card th {
    background: #f5f5f5;
    padding: 0.8em;
    text-align: left;
    border-bottom: 2px solid #4CAF50;
}

.reference-card td {
    padding: 0.8em;
    border-bottom: 1px solid #e0e0e0;
}

.reference-card tr:hover {
    background: #f9f9f9;
}

/* Code Block Enhancements */
.highlight {
    border-radius: 6px;
    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

/* Collapsible Sections */
details {
    background: #f5f5f5;
    border-left: 3px solid #2196F3;
    padding: 1em;
    margin: 1em 0;
    border-radius: 4px;
}

details summary {
    cursor: pointer;
    font-weight: bold;
    user-select: none;
    padding: 0.5em;
}

details summary:hover {
    background: #e0e0e0;
    border-radius: 4px;
}

details[open] {
    padding-bottom: 1em;
}

/* Emoji Enhancement */
.emoji-large {
    font-size: 1.5em;
    vertical-align: middle;
}

/* Skip Links for Accessibility */
.skip-link {
    background: #4CAF50;
    color: white;
    padding: 0.5em 1em;
    text-decoration: none;
    border-radius: 4px;
    display: inline-block;
    margin: 0.5em 0;
}

.skip-link:hover {
    background: #45a049;
}

/* Dark Mode Adjustments */
[data-md-color-scheme="slate"] .tldr-box {
    background: #1e4620;
}

[data-md-color-scheme="slate"] .quick-win {
    background: #3d2b1f;
}

[data-md-color-scheme="slate"] .checkpoint {
    background: #1a2b3d;
}

[data-md-color-scheme="slate"] .grid.cards > div {
    background: #2d2d2d;
    border-color: #444;
}

[data-md-color-scheme="slate"] .reference-card th {
    background: #2d2d2d;
}

/* Mobile Responsiveness */
@media screen and (max-width: 768px) {
    .grid.cards {
        grid-template-columns: 1fr;
    }
    
    .reference-card table {
        font-size: 0.9em;
    }
    
    .tldr-box, .checkpoint, .quick-win {
        padding: 0.8em 1em;
    }
}
````

---

### File 5: index.md (modifications)

**Location:** `docs/index.md`

**Action:** MODIFY EXISTING FILE

**Instructions:** Add this section right after the main heading and tagline:

````markdown
!!! tldr "⚡ TL;DR - Get Started in 30 Seconds"
```bash
    brew tap data-wise/tap && brew install flow-cli
    dash                    # See your projects
    work my-project         # Start working
    win "tried flow-cli!"   # Log your first win
```
    **That's it!** [Want to learn more? →](#try-it-now)

---

## 🎯 Choose Your Path

Not sure where to start? Pick what fits you best:

<div class="grid cards" markdown>

-   :rocket:{ .lg .middle } **Quick Start**

    ---

    Get up and running in 5 minutes

    [→ Quick Start](getting-started/quick-start.md)

-   :books:{ .lg .middle } **Learn Step-by-Step**

    ---

    30-minute guided tutorial path

    [→ Tutorials](tutorials/01-first-session.md)

-   :target:{ .lg .middle } **Solve a Problem**

    ---

    Find the workflow you need now

    [→ Workflows](guides/WORKFLOWS-QUICK-WINS.md)

-   :mag:{ .lg .middle } **Look Up a Command**

    ---

    Quick reference for commands

    [→ Reference](help/QUICK-REFERENCE.md)

</div>

---
````

**Note:** Insert this AFTER the existing tagline "Start working in 10 seconds..." and BEFORE the "⚡ Try It Now" section.

---

### File 6: mkdocs.yml (modifications)

**Location:** `mkdocs.yml`

**Action:** MODIFY EXISTING FILE

**Instructions:**

1. **Add extra CSS reference** (add to the file if not already present):

````yaml
extra_css:
  - stylesheets/extra.css
````

1. **Update navigation structure** (replace the existing `nav:` section):

````yaml
nav:
  - Home: index.md
  - Getting Started:
      - 🎯 Choose Your Path: getting-started/choose-your-path.md
      - ⚡ Quick Start (5-min): getting-started/quick-start.md
      - 📦 Installation: getting-started/installation.md
      - 🆘 I'm Stuck: getting-started/im-stuck.md
      - ❓ FAQ: getting-started/faq.md
      - 🔄 Troubleshooting: getting-started/troubleshooting.md
      - 📜 Changelog: CHANGELOG.md
  
  - 🎓 Learn (Tutorials):
      - tutorials/01-first-session.md
      - tutorials/02-multiple-projects.md
      - tutorials/03-status-visualizations.md
      - tutorials/04-web-dashboard.md
      - tutorials/05-ai-commands.md
      - tutorials/06-dopamine-features.md
      - tutorials/07-sync-command.md
      - tutorials/08-git-feature-workflow.md
      - tutorials/09-worktrees.md
      - tutorials/10-cc-dispatcher.md
      - tutorials/11-tm-dispatcher.md
      - tutorials/12-dot-dispatcher.md
  
  - ⚡ Workflows (Quick Tasks):
      - Quick Wins: guides/WORKFLOWS-QUICK-WINS.md
      - Git Feature Workflow: tutorials/08-git-feature-workflow.md
      - Worktree Workflow: guides/WORKTREE-WORKFLOW.md
      - Dotfile Workflow: guides/DOT-WORKFLOW.md
      - YOLO Mode: guides/YOLO-MODE-WORKFLOW.md
      - Workflow Tutorial: guides/WORKFLOW-TUTORIAL.md
      - Plugin Management: guides/PLUGIN-MANAGEMENT-WORKFLOW.md
      - Config Management: guides/CONFIG-MANAGEMENT-WORKFLOW.md
  
  - 📋 Reference (Lookup):
      - 📋 Quick Reference Card: quick-reference-card.md
      - Quick References:
          - Command Cheatsheet: help/QUICK-REFERENCE.md
          - Alias Card: reference/ALIAS-REFERENCE-CARD.md
          - Workflow Patterns: reference/WORKFLOW-QUICK-REFERENCE.md
          - Dashboard Quick Ref: reference/.archive/DASHBOARD-QUICK-REF.md
      - Dispatchers:
          - All Dispatchers: reference/MASTER-DISPATCHER-GUIDE.md
          - CC Dispatcher: reference/CC-DISPATCHER-REFERENCE.md
          - DOT Dispatcher: reference/MASTER-DISPATCHER-GUIDE.md#dot-dispatcher
          - G Dispatcher: reference/MASTER-DISPATCHER-GUIDE.md#g-dispatcher
          - MCP Dispatcher: reference/MCP-DISPATCHER-REFERENCE.md
          - OBS Dispatcher: reference/OBS-DISPATCHER-REFERENCE.md
          - QU Dispatcher: reference/QU-DISPATCHER-REFERENCE.md
          - R Dispatcher: reference/R-DISPATCHER-REFERENCE.md
          - TM Dispatcher: reference/TM-DISPATCHER-REFERENCE.md
          - WT Dispatcher: reference/WT-DISPATCHER-REFERENCE.md
      - Quick Reference Cards:
          - DOT Quick Ref: reference/REFCARD-DOT.md
      - Project Tools:
          - Command Explorer: reference/COMMAND-EXPLORER.md
          - Pick Reference: reference/.archive/PICK-COMMAND-REFERENCE.md
          - Pick Project Discovery: reference/PICK-PROJECT-DISCOVERY.md
          - Project Status Guide: reference/PROJECT-STATUS-GUIDE.md
          - Project Detection: reference/.archive/PROJECT-DETECTION-GUIDE.md
          - Workspace Audit: reference/WORKSPACE-AUDIT-GUIDE.md
      - Deep Dives:
          - ADHD Helpers Map: reference/.archive/ADHD-HELPERS-FUNCTION-MAP.md
          - Command Patterns: reference/CLI-COMMAND-PATTERNS-RESEARCH.md
          - System Summary: reference/EXISTING-SYSTEM-SUMMARY.md
          - ZSH Workflows: reference/ZSH-CLEAN-WORKFLOW.md
  
  - 🔧 Guides (Deep Dives):
      - Start Here: guides/00-START-HERE.md
      - Dotfile Management: guides/DOTFILE-MANAGEMENT.md
      - Dopamine Features: guides/DOPAMINE-FEATURES-GUIDE.md
      - Mermaid Diagrams: guides/MERMAID-DIAGRAMS-QUICK-START.md
      - Enhanced Help: guides/ENHANCED-HELP-QUICK-START.md
      - Monorepo Commands: guides/MONOREPO-COMMANDS-TUTORIAL.md
      - Project Scope: guides/PROJECT-SCOPE.md
  
  - 🎨 Visuals:
      - Documentation Templates: conventions/adhd/
      - GIF Creation Guide: conventions/adhd/GIF-GUIDELINES.md
  
  - Commands:
      - commands/flow.md
      - commands/work.md
      - commands/finish.md
      - commands/hop.md
      - commands/pick.md
      - commands/alias.md
      - commands/capture.md
      - commands/timer.md
      - commands/morning.md
      - commands/dash.md
      - commands/status.md
      - commands/sync.md
      - commands/doctor.md
      - commands/config.md
      - commands/plugin.md
      - commands/ai.md
      - commands/do.md
      - commands/install.md
      - commands/upgrade.md
      - commands/dashboard.md
  
  - Testing:
      - Testing Guide: testing/TESTING.md
      - Interactive Dog Test: testing/DOG-FEEDING-TEST-README.md
      - Interactive Test Guide: testing/INTERACTIVE-TEST-GUIDE.md
      - Testing Quick Ref: reference/TESTING-QUICK-REF.md
  
  - Development:
      - Contributing: contributing/CONTRIBUTING.md
      - PR Workflow Guide: contributing/PR-WORKFLOW-GUIDE.md
      - Documentation Style Guide: contributing/DOCUMENTATION-STYLE-GUIDE.md
      - Guidelines: ZSH-DEVELOPMENT-GUIDELINES.md
      - Conventions: CONVENTIONS.md
      - Philosophy: PHILOSOPHY.md
  
  - Planning:
      - v4.3.0+ Roadmap: planning/V4.3-ROADMAP.md
      - Install Improvements: planning/INSTALL-IMPROVEMENTS.md
````

---

## Git Commands

### Complete Implementation Workflow

````bash
# 1. Navigate to repository
cd /path/to/flow-cli

# 2. Ensure you're on main and up to date
git checkout main
git pull origin main

# 3. Create feature branch
git checkout -b docs/adhd-friendly-enhancements

# 4. Create directory structure
mkdir -p docs/stylesheets

# 5. Create new files (copy content from above)
# Use your text editor to create:
#   - docs/getting-started/im-stuck.md
#   - docs/getting-started/choose-your-path.md
#   - docs/quick-reference-card.md
#   - docs/stylesheets/extra.css

# 6. Modify existing files
#   - docs/index.md (add TL;DR and path selection)
#   - mkdocs.yml (add CSS and update navigation)

# 7. Stage all changes
git add docs/getting-started/im-stuck.md
git add docs/getting-started/choose-your-path.md
git add docs/quick-reference-card.md
git add docs/stylesheets/extra.css
git add docs/index.md
git add mkdocs.yml

# 8. Check what will be committed
git status

# 9. Commit with descriptive message
git commit -m "docs: add ADHD-friendly enhancements - Phase 1

- Add 'I'm Stuck' emergency troubleshooting page
- Add 'Choose Your Path' landing page for new users
- Create printable quick reference card
- Add TL;DR boxes to main pages
- Restructure navigation for better discoverability
- Add custom CSS for ADHD-friendly styling

This implements Phase 1 of documentation enhancement plan
focusing on new user experience and ADHD-friendly content."

# 10. Push to GitHub
git push origin docs/adhd-friendly-enhancements

# 11. Create Pull Request
# Go to: https://github.com/Data-Wise/flow-cli
# You'll see a banner to create PR from your branch
````

---

## Testing Checklist

Before creating Pull Request:

### Local Testing

````bash
# Install MkDocs if not already installed
pip install mkdocs-material

# Navigate to repo
cd /path/to/flow-cli

# Serve locally
mkdocs serve

# Open browser to http://127.0.0.1:8000
````

### Manual Checks

- [ ] **Navigation works**: All menu items clickable
- [ ] **Links functional**: No 404 errors
- [ ] **Search works**: Can find new pages
- [ ] **Mobile responsive**: Check on narrow browser
- [ ] **Dark mode**: Toggle and verify readability
- [ ] **Print layout**: Cmd/Ctrl+P on reference card
- [ ] **CSS loads**: Verify colored boxes appear
- [ ] **TL;DR boxes**: Display correctly
- [ ] **Grid cards**: Display in 2x2 or 1 column on mobile
- [ ] **Code copy buttons**: Green and functional
- [ ] **Emoji render**: All emoji display correctly

### Content Review

- [ ] No typos in new content
- [ ] All commands accurate
- [ ] All file paths correct
- [ ] Consistent formatting
- [ ] Voice/tone matches existing docs
- [ ] All cross-references work

---

## Pull Request Template

**Title:** 📚 Docs: ADHD-Friendly Enhancements - Phase 1

**Description:**

````markdown
## 🎯 Summary

This PR implements Phase 1 of the documentation enhancement plan, focusing on high-impact improvements for new users and ADHD-friendly content organization.

## 📝 Changes

### New Pages
- 🆘 **I'm Stuck** (`docs/getting-started/im-stuck.md`) - Emergency troubleshooting with common fixes
- 🎯 **Choose Your Path** (`docs/getting-started/choose-your-path.md`) - Intelligent routing for different learning styles
- 📋 **Quick Reference Card** (`docs/quick-reference-card.md`) - Printable one-page cheatsheet

### Enhanced Navigation
- Restructured docs hierarchy with clearer categories (Learn, Workflows, Reference, Guides)
- Added emoji visual anchors for faster scanning
- Grouped content by user intent

### Content Improvements
- Added TL;DR box to homepage (`docs/index.md`)
- Added path selection cards to homepage
- Enhanced quick start experience

### Visual Enhancements
- Custom CSS for ADHD-friendly styling (`docs/stylesheets/extra.css`)
- Print-friendly reference cards
- Improved button hover effects
- Progress bar styling (for future use in tutorials)

## ✅ Testing Checklist

- [x] All links work (tested locally)
- [x] Prints correctly (reference card)
- [x] Mobile responsive (tested at 375px width)
- [x] Dark mode compatible
- [x] No broken navigation
- [x] Search indexes new pages
- [x] CSS loads properly

## 📸 Screenshots

(Add screenshots of key changes if desired)

## 🚀 Next Steps (Future PRs)

Phase 2 will include:
- Collapsible sections for long content
- Video/GIF demonstrations
- Interactive exercises
- Progress indicators in tutorials
- Additional quick reference cards

## 📚 Related Issues

Addresses user feedback about:
- New user onboarding experience
- Difficulty finding specific information
- Need for quick troubleshooting guide
- ADHD-friendly content organization

---

**Ready for review!** 🎉
````

---

## Additional Notes

### Markdown Syntax Tips

- **Code blocks**: Use triple backticks with language identifier
- **Admonitions**: Use `!!! type "Title"` format
- **Tabs**: Use `=== "Tab Name"` format
- **Buttons**: Use `[Text](link){ .md-button .md-button--primary }`
- **Grid cards**: Use `<div class="grid cards" markdown>` wrapper

### Common Issues

**Issue**: CSS not loading
**Fix**: Ensure `extra_css` is in mkdocs.yml AND file exists at correct path

**Issue**: Navigation broken
**Fix**: Check YAML indentation in mkdocs.yml (must be exact)

**Issue**: Links 404
**Fix**: Verify relative paths are correct from file location

---

## Version History

- **v1.0** (2026-01-11): Initial implementation package created

---

## Support

If you encounter issues during implementation:
