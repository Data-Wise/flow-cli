---
tags:
  - reference
  - commands
---

# Quick Reference: flow-cli Commands

**Purpose:** Single-page command lookup for all flow-cli features
**Format:** Copy-paste ready with expected outputs
**Version:** v7.0.2
**Last Updated:** 2026-02-12

---

## Table of Contents

- [Core Commands](#core-commands) - work, finish, dash, hop, catch
- [Git Dispatcher (g)](#git-dispatcher-g) - Git workflows
- [Claude Code (cc)](#claude-code-cc) - AI pair programming
- [R Dispatcher (r)](#r-dispatcher-r) - R package development
- [Quarto (qu)](#quarto-qu) - Publishing workflow
- [MCP (mcp)](#mcp-mcp) - MCP server management
- [Obsidian (obs)](#obsidian-obs) - Note management
- [Worktree (wt)](#worktree-wt) - Parallel development
- [DOT (dot)](#dot-dot) - Dotfile & secrets
- [Teaching (teach)](#teaching-teach) - Course management
- [Terminal (tm)](#terminal-tm) - Terminal profiles
- [Prompt (prompt)](#prompt-prompt) - Prompt engine switching
- [Vibe (v)](#vibe-v) - Vibe coding mode
- [Email (em)](#email-em) - Email management (himalaya)
- [Dopamine Features](#dopamine-features) - ADHD-friendly motivation
- [Environment Variables](#environment-variables)

---

## Core Commands

### Session Management

```bash
# Start working on a project
work <project_name>
# Output: 🚀 Starting work on flow-cli...
#         Project: flow-cli
#         Type: Node.js
#         Location: ~/projects/dev-tools/flow-cli
#         Session started at 18:30

# Auto-pick project (just start)
js
# Output: [Interactive project picker if multiple options]

# Quick capture note
catch "Implement feature X"
# Output: ✅ Captured: Implement feature X
#         Location: ~/.cache/flow/captures/2026-01-24.md

# Leave breadcrumb
crumb "Fixed bug in parser"
# Output: 🍞 Breadcrumb added: Fixed bug in parser

# Finish session (with optional commit)
finish "Add user authentication"
# Output: ✅ Session complete
#         Duration: 1h 23m
#         Changes: +234 -12 lines
#         [Creates git commit if in git repo]

# Finish without commit message (prompt)
finish
# Output: [Prompts for commit message]

# Switch to another project (tmux)
hop <project_name>
# Output: [Switches tmux session]

# Why am I here? (show session context)
why
# Output: Session: flow-cli
#         Started: 18:30 (1h 23m ago)
#         Type: Node.js
#         Goal: Implement feature X
```

---

### Dashboard

```bash
# Show all projects
dash
# Output: [Table of all projects with status]

# Interactive dashboard (TUI)
dash -i
# Output: [fzf interface for project selection]

# Filter by category
dash dev
dash teaching
dash research
# Output: [Filtered project list]

# Watch mode (live refresh)
dash --watch
# Output: [Auto-refreshing dashboard]

# Tool inventory
dash --inventory
# Output: [Auto-generated tool inventory with health status]

# Specific project status
dash flow-cli
# Output: flow-cli
#         Type: Node.js
#         Status: Active
#         Branch: dev
#         Last commit: 2h ago
#         Progress: 75%
```

---

### Project Picker

```bash
# Interactive picker
pick
# Output: [fzf interface for project selection]

# Filter by type
pick --type node
pick --type r
pick --type quarto
# Output: [Filtered project list]

# Recent projects
pick --recent
# Output: [5 most recent projects]

# Show help
pick help
# Output: [Help information]
```

---

### Health Check

```bash
# Full health check (~60s)
flow doctor
# Output: [6 categories: dependencies, git, tokens, config, atlas, plugins]

# Interactive fix mode
flow doctor --fix
# Output: [Interactive prompts to fix issues]

# Token check only (<3s, cached)
flow doctor --dot
# Output: GitHub Token
#         ✅ Valid (expires in 45 days)
#         Last checked: 2 minutes ago (cached)

# Specific provider
flow doctor --dot=github
flow doctor --dot=npm
# Output: [Provider-specific token check]

# Fix tokens only
flow doctor --fix-token
# Output: [Interactive token fix workflow]

# Quiet mode (CI/CD)
flow doctor --quiet
# Output: [Exit code only: 0 = pass, 1 = fail]

# Verbose mode (debugging)
flow doctor --verbose
# Output: [Detailed output with cache status]
```

---

## Git Dispatcher (g)

### Basic Git Commands

```bash
# Status
g status
g st
# Output: On branch dev
#         Your branch is up to date with 'origin/dev'.
#         nothing to commit, working tree clean

# Add files
g add .
g add <file>

# Commit
g commit "feat: add user auth"
g cm "fix: resolve login bug"
# Output: [dev 72150b6e] feat: add user auth
#         3 files changed, 125 insertions(+), 12 deletions(-)

# Push
g push
# Output: [Validates token before push]
#         To https://github.com/Data-Wise/flow-cli.git
#            72150b6e..abc123de  dev -> dev

# Pull
g pull
# Output: [Validates token before pull]
#         Already up to date.

# Diff
g diff
g diff --staged
# Output: [Shows changes]

# Log
g log
g log --oneline
g log --graph
# Output: [Commit history]
```

---

### Feature Branch Workflow

```bash
# Start feature
g feature start my-feature
# Output: ✅ Created feature/my-feature from dev
#         Switched to feature/my-feature

# List features
g feature list
# Output: * feature/my-feature
#           feature/another-feature

# Push feature
g feature push
# Output: [Pushes current feature branch]

# Create PR
g feature pr
# Output: [Creates PR to dev branch via gh cli]

# Finish feature (after PR merge)
g feature finish
# Output: ✅ Switched to dev
#         ✅ Deleted feature/my-feature

# Cleanup merged branches
g feature prune
# Output: ✅ Deleted 3 merged feature branches
```

---

### Advanced Git

```bash
# Sync (pull + rebase)
g sync
# Output: [Pulls and rebases current branch]

# Stash
g stash
g stash pop
g stash list

# Reset
g reset HEAD~1    # Soft reset
g reset --hard    # Hard reset (DANGEROUS)

# Cherry-pick
g cherry-pick <commit>

# Rebase
g rebase dev
g rebase -i HEAD~3
```

---

## Claude Code (cc)

```bash
# Launch Claude Code in current directory
cc
# Output: [Launches Claude Code CLI]

# Launch with project picker
cc pick
# Output: [Interactive project selection, then launch]

# Launch in yolo mode (accepts all permissions)
cc yolo
# Output: [Launches with auto-approval]

# Show help
cc help
# Output: cc - Claude Code launcher
#
#         Usage:
#           cc           Launch in current directory
#           cc pick      Pick project interactively
#           cc yolo      Launch with auto-approval
#           cc help      Show this help
```

---

## R Dispatcher (r)

```bash
# Run tests
r test
# Output: [Runs testthat tests]
#         ✔ | F W  S  OK | Context
#         ✔ |     8      | my_function
#
#         ══ Results ═══════════════════════════════════
#         Duration: 0.5 s
#
#         [ FAIL 0 | WARN 0 | SKIP 0 | PASS 8 ]

# Build documentation
r doc
# Output: [Runs roxygen2::roxygenize()]
#         ℹ Loading package
#         Writing NAMESPACE
#         Writing man pages

# Check package
r check
# Output: [Runs R CMD check]
#         ── R CMD check results ───
#         0 errors ✔ | 0 warnings ✔ | 0 notes ✔

# Install package
r install
# Output: [Installs package locally]

# Build package
r build
# Output: [Builds source tarball]
#         ✔  checking for file 'DESCRIPTION' ...
#         ─  building 'package_0.1.0.tar.gz'

# Load package
r load
# Output: [Loads with devtools::load_all()]

# Show help
r help
# Output: [R dispatcher help]
```

---

## Quarto (qu)

```bash
# Preview document
qu preview
qu preview document.qmd
# Output: [Starts preview server]
#         Preparing to preview
#         Watching files for changes
#         Browse at http://localhost:4567/

# Render document
qu render
qu render document.qmd
# Output: [Renders document]
#         processing file: document.qmd
#         output file: document.html
#         Output created: document.html

# Render website
qu render --website
# Output: [Renders entire website]

# Publish to GitHub Pages
qu publish gh-pages
# Output: [Deploys to GitHub Pages]

# Create new document
qu create article
qu create website
# Output: [Creates Quarto project]

# Show help
qu help
# Output: [Quarto dispatcher help]
```

---

## MCP (mcp)

```bash
# List MCP servers
mcp list
mcp ls
# Output: statistical-research (running)
#         rforge (running)
#         nexus (running)
#         playwright (stopped)

# Show server status
mcp status
# Output: [Detailed status table]

# Start server
mcp start <server_name>
# Output: ✅ Started statistical-research

# Stop server
mcp stop <server_name>
# Output: ✅ Stopped statistical-research

# Restart server
mcp restart <server_name>
# Output: ✅ Restarted statistical-research

# Show logs
mcp logs <server_name>
# Output: [Tails server logs]

# Test server
mcp test <server_name>
# Output: [Tests server connectivity]

# Show help
mcp help
# Output: [MCP dispatcher help]
```

---

## Obsidian (obs)

```bash
# List vaults
obs vaults
# Output: main-vault (/Users/dt/Obsidian/main-vault)
#         work-vault (/Users/dt/Obsidian/work-vault)

# Show vault stats
obs stats
# Output: Total notes: 1,234
#         Total links: 5,678
#         Orphan notes: 12
#         Broken links: 3

# Search notes
obs search "search term"
# Output: [List of matching notes]

# Open note
obs open "note name"
# Output: [Opens in Obsidian]

# Create note
obs new "note title"
# Output: ✅ Created: note title.md

# Show help
obs help
# Output: [Obsidian dispatcher help]
```

---

## Worktree (wt)

```bash
# Create worktree
wt create feature/new-feature
wt create feature/bug-fix dev
# Output: ✅ Created worktree at ~/.git-worktrees/flow-cli/feature-new-feature
#         Switched to branch 'feature/new-feature'

# List worktrees
wt list
wt ls
# Output: main      /Users/dt/projects/dev-tools/flow-cli
#         feature-x ~/.git-worktrees/flow-cli/feature-x

# Show worktree status
wt status
# Output: [Status of all worktrees]

# Remove worktree
wt remove feature/new-feature
wt rm feature/new-feature
# Output: ✅ Removed worktree feature/new-feature

# Prune deleted worktrees
wt prune
# Output: ✅ Pruned 2 worktrees

# Show help
wt help
# Output: [Worktree dispatcher help]
```

---

## DOT (dot)

### Dotfile Management

```bash
# Edit dotfile
dot edit zshrc
dot edit vimrc
# Output: [Opens in $EDITOR]

# Sync dotfiles
dot sync
# Output: ✅ Synced 12 dotfiles
#         ~/.zshrc → ~/dotfiles/zshrc
#         ~/.vimrc → ~/dotfiles/vimrc

# Show dotfile status
dot status
# Output: [Shows sync status]

# Restore dotfile
dot restore zshrc
# Output: ✅ Restored ~/.zshrc from ~/dotfiles/zshrc
```

---

### Secret Management (macOS Keychain)

```bash
# Store secret
dot secret set GITHUB_TOKEN
# Output: Enter value for GITHUB_TOKEN:
#         [Touch ID prompt]
#         ✅ Stored GITHUB_TOKEN in keychain

# Get secret
dot secret get GITHUB_TOKEN
# Output: [Touch ID prompt]
#         ghp_xxxxxxxxxxxxxxxxxxxx

# List secrets
dot secret list
# Output: GITHUB_TOKEN
#         NPM_TOKEN
#         HOMEBREW_GITHUB_API_TOKEN

# Delete secret
dot secret delete GITHUB_TOKEN
# Output: [Touch ID prompt]
#         ✅ Deleted GITHUB_TOKEN

# Rotate secret (get + update)
dot secret rotate GITHUB_TOKEN
# Output: [Touch ID prompt]
#         Current value: ghp_old...
#         Enter new value:
#         [Touch ID prompt]
#         ✅ Rotated GITHUB_TOKEN

# Unlock keychain
dot unlock
# Output: [Touch ID prompt]
#         ✅ Keychain unlocked

# Show help
dot help
# Output: [DOT dispatcher help]
```

---

### Token Management (v5.17.0)

```bash
# Check token expiration (fast, cached)
dot token expiring
# Output: GitHub Token: 45 days remaining ✅
#         (cached 2 minutes ago)

# Force refresh (no cache)
dot token expiring --force
# Output: [Fresh check, ~2-3s]

# Rotate token
dot token rotate github
# Output: [Interactive token rotation]
```

---

## Teaching (teach)

### Course Management

```bash
# Initialize course
teach init
teach init --config course-config.yml
teach init --github
# Output: ✅ Created course structure
#         📁 lectures/
#         📁 assignments/
#         📁 exams/

# Migrate lesson plans (v5.20.0+)
teach migrate-config --dry-run    # Preview changes
teach migrate-config              # Extract weeks to lesson-plans.yml
# Output: ✅ Extracted 15 weeks to lesson-plans.yml

# Manage templates (v5.20.0+)
teach templates                   # List available templates
teach templates new lecture week-05   # Create from template
teach templates sync --dry-run    # Preview template updates
# Output: ✅ Created: lectures/week-05.qmd

# Show course status
teach status
# Output: Course: STAT-440
#         Semester: Spring 2026
#         Lectures: 28 (12 deployed)
#         Assignments: 8 (3 graded)
#         Next deadline: HW3 (2026-02-15)

# Analyze content
teach analyze
teach analyze lectures/week-01/
teach analyze --batch
# Output: [AI-powered content analysis]
#         Concept: Linear Regression
#         Complexity: Medium
#         Prerequisites: Basic statistics
#         Bloom Level: Apply

# Generate exam
teach exam "Midterm 1 Topics"
# Output: [Uses Scholar to generate exam]
#         ✅ Generated exam in exams/midterm-1.md

# Deploy course site
teach deploy
# Output: [Deploys to GitHub Pages]
#         ✅ Deployed to https://username.github.io/course

# Show help
teach help
# Output: [Teaching dispatcher help]

# Ecosystem map (v6.6.0) — all commands across flow-cli + Scholar + Craft
teach map
# Output: Grouped view of all teaching commands by workflow phase
#         Shows which tool provides each command
#         Dims commands from uninstalled tools
```

---

### Health Check (Doctor v2)

```bash
# Quick check (default, < 3s) — deps, R, config, git
teach doctor
# Output: ✅ Dependencies   yq, git, quarto, gh, claude
#         ✅ R Environment  R 4.4.2, renv active (48 packages)
#         ✅ Configuration  .flow/teach-config.yml
#         ✅ Git Setup      main + gh-pages, clean

# Full check (all 11 categories)
teach doctor --full
# Output: [Quick checks + R packages, quarto ext, scholar, hooks, cache, macros, style]

# Fix issues interactively (implies --full)
teach doctor --fix
# Output: [Prompts to install missing R packages via renv or system]

# CI mode (no color, exit 1 on failure)
teach doctor --ci --full

# Machine-readable JSON output
teach doctor --json

# Summary only (failures and warnings)
teach doctor --brief
```

---

### Scholar Integration

```bash
# Check Scholar status
teach scholar status
# Output: Scholar CLI: ✅ Installed
#         Version: 2.1.0
#         Templates: 12 available

# Use Scholar template
teach exam --template scholar/midterm
teach quiz --template scholar/weekly

# Analyze with Scholar
teach analyze --ai
# Output: [Uses Scholar AI analysis]
```

---

## Terminal (tm)

```bash
# Set terminal title
tm title "flow-cli dev"
# Output: [Terminal title updated]

# Switch profile
tm profile "Solarized Dark"
# Output: ✅ Switched to profile: Solarized Dark

# Ghost mode (hide from Alfred/Spotlight)
tm ghost on
tm ghost off
# Output: ✅ Ghost mode enabled

# Show current settings
tm status
# Output: Profile: Solarized Dark
#         Title: flow-cli dev
#         Ghost: enabled

# Show help
tm help
# Output: [Terminal dispatcher help]
```

---

## Prompt (prompt)

```bash
# Show current prompt engine
prompt status
# Output: Current engine: claude (Anthropic)
#         Available: claude, gemini

# Switch to Gemini
prompt toggle
prompt use gemini
# Output: ✅ Switched to gemini

# Switch to Claude
prompt use claude
# Output: ✅ Switched to claude

# Show help
prompt help
# Output: [Prompt dispatcher help]
```

---

## Vibe (v)

```bash
# Enable vibe coding mode
v on
# Output: 🎵 Vibe coding mode: ON
#         Music: ✅
#         Do Not Disturb: ✅
#         Focus: Maximum

# Disable vibe mode
v off
# Output: 🎵 Vibe coding mode: OFF

# Show status
v status
# Output: Vibe mode: ON
#         Started: 2h ago
#         Sessions: 3

# Show help
v help
# Output: [Vibe dispatcher help]
```

---

## Email (em)

### Daily Workflow

```bash
# Quick pulse — unread count + 10 latest
em
# Output: 19 unread in INBOX
#         [10 most recent emails]

# Show unread count
em unread
# Output: 19 unread in INBOX

# List inbox (default 25)
em inbox
em inbox 5          # Just 5 most recent

# Read email
em read 42
# Output: [Smart-rendered email content]

# Render HTML email
em html 42
```

### Compose & Reply

```bash
# Compose new email (opens $EDITOR)
em send

# Reply with AI draft
em reply 42
# Output: [AI generates draft → opens in $EDITOR → confirm send]

# Reply-all
em reply 42 --all

# Reply without AI draft
em reply 42 --no-ai

# Non-interactive batch reply
em reply 42 --batch
```

### AI Features

```bash
# Classify email category
em classify 42
# Output: student

# One-line summary
em summarize 42
# Output: Student asks about midterm grading policy

# Batch AI drafts for actionable emails
em respond
em respond --dry-run      # Classify only (no drafts)
em respond -n 50          # Process 50 emails
em respond --review       # Review/send cached drafts
```

### Browse & Search

```bash
# fzf email browser with preview
em pick
# Keybindings: Enter=read, Ctrl-S=summarize, Ctrl-A=archive, Ctrl-R=reply

# Browse specific folder
em pick Sent

# Search emails
em find "quarterly report"

# Dashboard view
em dash

# List folders
em folders

# Download attachments
em attach 42
```

### Management

```bash
# Check dependencies
em doctor

# Cache management
em cache stats                # Show cache size, TTLs, counts
em cache clear                # Remove all cached AI results
em cache prune                # Remove expired entries only
em cache warm 20              # Pre-warm latest 20 emails (background)

# Configuration
export FLOW_EMAIL_AI=claude     # AI backend (claude/gemini/none)
export FLOW_EMAIL_PAGE_SIZE=25  # Inbox page size
```

> **Safety:** Every send requires `[y/N]` confirmation (default: No)

---

## Dopamine Features

### Win Logging (ADHD Motivation)

```bash
# Log a win
win "Implemented user authentication"
# Output: 🎉 Win logged!
#         Category: 💻 code
#         Streak: 5 days
#         Daily goal: 2/3

# Show recent wins
yay
# Output: 🎉 Recent Wins (Last 24h):
#         💻 Implemented user authentication (14:32)
#         📝 Updated documentation (12:15)
#         🔧 Fixed login bug (10:30)

# Show weekly summary
yay --week
# Output: 📊 Week Summary:
#         Total wins: 15
#         💻 code: 8
#         📝 docs: 4
#         🔧 fix: 3
#         [ASCII graph]

# Show monthly summary
yay --month
# Output: [Monthly statistics]

# Win categories
# 💻 code    - Code written
# 📝 docs    - Documentation
# 👀 review  - Code reviews
# 🚀 ship    - Deployed features
# 🔧 fix     - Bug fixes
# 🧪 test    - Tests written
# ✨ other   - Miscellaneous
```

---

### Goal Tracking

```bash
# Show daily goal
flow goal
# Output: Daily Goal: 2/3 wins ⚡⚡○
#         Streak: 5 days 🔥

# Set daily goal
flow goal set 3
# Output: ✅ Daily goal set to 3 wins

# Show streak
flow streak
# Output: Current streak: 5 days 🔥
#         Best streak: 12 days
#         Total days: 45
```

---

## Environment Variables

### Configuration

```bash
# Set in ~/.zshrc BEFORE sourcing flow.plugin.zsh:

# Project root directory
export FLOW_PROJECTS_ROOT="$HOME/projects"

# Atlas integration (auto|yes|no)
export FLOW_ATLAS_ENABLED="auto"

# Quiet mode (suppress welcome message)
export FLOW_QUIET=1

# Debug mode (verbose logging)
export FLOW_DEBUG=1

# Default editor for dotfiles
export EDITOR="nvim"

# GitHub token (for git operations)
export GITHUB_TOKEN="ghp_xxxx"  # Or use keychain
```

---

### Feature Flags

```bash
# Enable experimental features
export FLOW_EXPERIMENTAL=1

# Enable performance profiling
export FLOW_PROFILE=1

# Cache timeout (seconds)
export FLOW_CACHE_TTL=300

# Token cache timeout (seconds)
export FLOW_TOKEN_CACHE_TTL=300
```

---

## Keyboard Shortcuts

### Terminal Shortcuts

These work if configured in your terminal app (iTerm2, Terminal.app):

```bash
Ctrl+R    # Reverse search history (fzf if installed)
Ctrl+T    # File fuzzy finder (fzf)
Ctrl+Alt+F  # Project switcher (custom binding)

# In flow-cli commands:
Tab       # Auto-completion
Ctrl+C    # Cancel operation
Ctrl+D    # Exit interactive mode
```

---

## Common Workflows

### Daily Development Workflow

```bash
# Morning routine
work my-project          # Start session
dash                     # Check status
g pull                   # Sync with remote

# During work
catch "Implement X"      # Quick notes
win "Fixed bug"          # Log progress
crumb "Important decision" # Leave breadcrumb

# End of day
finish "Daily progress"  # Commit & end session
yay                      # Review wins
```

---

### Feature Development Workflow

```bash
# Start feature
g feature start my-feature    # Create feature branch
wt create feature/my-feature  # OR use worktree

# Work
work my-project
# ... code ...
win "Implemented X"

# Finish
g feature push               # Push feature
g feature pr                 # Create PR
# ... after PR merge ...
g feature finish             # Cleanup
```

---

### Teaching Workflow

```bash
# Setup
teach init --config course.yml
teach scholar status

# Content creation
teach analyze lectures/      # Analyze content
teach exam "Midterm Topics"  # Generate exam

# Deployment (v6.4.0)
teach deploy --direct        # Direct merge deploy
teach deploy --dry-run       # Preview deploy
teach deploy --rollback 1    # Undo last deploy
teach deploy --history       # Show deploy log
teach status                 # Verify
```

---

## Tips & Tricks

### Aliases

flow-cli integrates with 22 ZSH plugins providing 351 aliases. See [Tutorial 24: Git Workflow](../tutorials/17-lazyvim-basics.md) for complete guide.

**Most useful git aliases:**

```bash
gst     → git status
ga      → git add
gcmsg   → git commit -m
gp      → git push
gl      → git pull
glog    → git log --oneline --graph
```

---

### Tab Completion

All commands support tab completion:

```bash
work <Tab>        # List all projects
g <Tab>           # List all git subcommands
teach <Tab>       # List all teach subcommands
```

---

### Help System

Every dispatcher has help:

```bash
<dispatcher> help

# Examples:
g help
r help
teach help
mcp help
```

---

### Performance

- **Sub-10ms response:** Core commands use cached project scanning
- **Token caching:** 80% API call reduction, 5-min TTL
- **Smart defaults:** No configuration needed
- **ADHD-friendly:** Quick wins, visual feedback, progress tracking

---

## Next Steps

- **Beginners:** [Quick Start Guide](../getting-started/quick-start.md)
- **Learning:** [Tutorial Index](../tutorials/index.md)
- **Workflows:** [Common Workflows](WORKFLOWS.md)
- **Troubleshooting:** [Troubleshooting Guide](TROUBLESHOOTING.md)
- **Reference:** [Master Dispatcher Guide](../reference/MASTER-DISPATCHER-GUIDE.md)

---

**Version:** v7.0.2
**Last Updated:** 2026-02-12
**Contributors:** See [CHANGELOG.md](../CHANGELOG.md)
