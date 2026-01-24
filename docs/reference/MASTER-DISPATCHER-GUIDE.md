# Master Dispatcher Guide

**Purpose:** Complete reference for all 12 flow-cli dispatchers
**Audience:** All users (beginner → intermediate → advanced)
**Format:** Progressive disclosure (basics → advanced features)
**Version:** v5.17.0-dev
**Last Updated:** 2026-01-24

---

## Overview

flow-cli uses **dispatchers** - single-letter or short commands that group related functionality. Each dispatcher follows a consistent pattern:

```bash
<dispatcher> <subcommand> [options] [args]
```

**Example:**
```bash
g status              # Git status
r test                # Run R tests
teach init            # Initialize course
```

### The 12 Dispatchers

| Dispatcher | Domain | Commands | Complexity |
|------------|--------|----------|------------|
| [g](#g-dispatcher) | Git workflows | 20+ | Beginner → Advanced |
| [cc](#cc-dispatcher) | Claude Code | 4 | Beginner |
| [r](#r-dispatcher) | R packages | 10+ | Intermediate |
| [qu](#qu-dispatcher) | Quarto publishing | 8+ | Intermediate |
| [mcp](#mcp-dispatcher) | MCP servers | 8 | Intermediate |
| [obs](#obs-dispatcher) | Obsidian notes | 6 | Beginner |
| [wt](#wt-dispatcher) | Worktrees | 6 | Advanced |
| [dot](#dot-dispatcher) | Dotfiles & secrets | 12+ | Intermediate → Advanced |
| [teach](#teach-dispatcher) | Teaching workflow | 15+ | Intermediate → Advanced |
| [tm](#tm-dispatcher) | Terminal manager | 5 | Beginner |
| [prompt](#prompt-dispatcher) | Prompt engine | 3 | Beginner |
| [v](#v-dispatcher) | Vibe coding mode | 4 | Beginner |

---

## How to Use This Guide

### For Beginners

Start with the **Basics** section of each dispatcher:
- Core commands you'll use daily
- Simple examples
- Common use cases

**Recommended Learning Order:**
1. [tm](#tm-dispatcher) - Terminal (easiest)
2. [cc](#cc-dispatcher) - Claude Code
3. [g](#g-dispatcher) basics - Git
4. [obs](#obs-dispatcher) - Obsidian (if you use it)

### For Intermediate Users

Explore **Intermediate** sections:
- Advanced subcommands
- Workflow patterns
- Integration with other tools

**Recommended Path:**
1. [g](#g-dispatcher) feature workflow
2. [r](#r-dispatcher) or [qu](#qu-dispatcher) (based on your work)
3. [teach](#teach-dispatcher) (if teaching)
4. [dot](#dot-dispatcher) - Secret management

### For Advanced Users

Deep dive into **Advanced** sections:
- Power user features
- Automation patterns
- Edge cases and customization

**Focus Areas:**
1. [wt](#wt-dispatcher) - Parallel development with worktrees
2. [dot](#dot-dispatcher) advanced - Secret rotation, automation
3. [teach](#teach-dispatcher) advanced - AI integration
4. [mcp](#mcp-dispatcher) - Server management

---

## Progressive Disclosure Pattern

Each dispatcher section follows this structure:

```markdown
## Dispatcher Name

### Basics (Beginner)
- Most common commands
- Simple examples
- Quick wins

### Intermediate
- Advanced features
- Workflow patterns
- Integration tips

### Advanced
- Power user features
- Automation
- Edge cases

### Reference
- Complete command list
- All options
- Examples
```

---

# Dispatchers

## g Dispatcher

**Domain:** Git workflows
**Complexity:** Beginner → Advanced
**Most Used:** Yes (daily git operations)

### Basics (Beginner)

**What it does:** Simplifies common git operations with short commands.

#### Essential Commands

**Check status:**
```bash
g status
g st                 # Alias for status
```

**Stage changes:**
```bash
g add .              # Add all changes
g add file.txt       # Add specific file
```

**Commit:**
```bash
g commit "feat: add user authentication"
g cm "fix: resolve login bug"
```

**Push/Pull:**
```bash
g push               # Push to remote
g pull               # Pull from remote
```

**View history:**
```bash
g log                # Full log
g log --oneline      # Compact log
g log --graph        # Visual graph
```

**Show changes:**
```bash
g diff               # Unstaged changes
g diff --staged      # Staged changes
```

**Expected Workflow (Beginner):**
```bash
# 1. Check what changed
g status

# 2. Stage changes
g add .

# 3. Commit
g commit "feat: add feature X"

# 4. Push
g push
```

---

### Intermediate

#### Feature Branch Workflow

**Create feature branch:**
```bash
g feature start my-feature
```

This:
- Creates `feature/my-feature` from `dev` (or main)
- Switches to new branch
- Ready to work

**Push feature:**
```bash
g feature push
```

**Create PR:**
```bash
g feature pr
# Uses gh cli to create PR to dev branch
```

**Finish feature (after merge):**
```bash
g feature finish
```

This:
- Switches back to dev
- Pulls latest changes
- Deletes feature branch locally

**Complete Feature Workflow:**
```bash
# Day 1: Start
g feature start user-profiles
# ... work on feature ...
g add .
g commit "feat: add user profile page"
g feature push

# Day 2: Create PR
g feature pr

# Day 5: PR merged
g feature finish
```

---

#### Branch Management

**List branches:**
```bash
g branch              # Local branches
g branch -r           # Remote branches
g branch -a           # All branches
```

**Create branch:**
```bash
g checkout -b new-branch
g co -b new-branch    # Short form
```

**Switch branches:**
```bash
g checkout branch-name
g co branch-name
```

**Delete branch:**
```bash
g branch -d branch-name        # Safe delete (merged only)
g branch -D branch-name        # Force delete
```

**Cleanup merged branches:**
```bash
g feature prune
# Deletes all local branches that are merged into dev
```

---

#### Stash Commands

**Save work in progress:**
```bash
g stash
g stash save "WIP: refactoring auth"
```

**List stashes:**
```bash
g stash list
```

**Apply stash:**
```bash
g stash pop            # Apply and remove
g stash apply          # Apply but keep
```

**Clear all stashes:**
```bash
g stash clear
```

---

### Advanced

#### Rebase & History Rewriting

**Rebase onto branch:**
```bash
g rebase dev
g rebase origin/dev
```

**Interactive rebase:**
```bash
g rebase -i HEAD~3
# Allows: pick, reword, edit, squash, fixup, drop
```

**Squash last 3 commits:**
```bash
g rebase -i HEAD~3
# Change 'pick' to 'squash' for commits to merge
```

---

#### Cherry-pick

**Pick specific commit:**
```bash
g cherry-pick <commit-hash>
```

**Pick range:**
```bash
g cherry-pick commit1..commit2
```

---

#### Reset & Restore

**Undo last commit (keep changes):**
```bash
g reset HEAD~1
```

**Undo last commit (discard changes):**
```bash
g reset --hard HEAD~1
```

**Restore file from specific commit:**
```bash
g restore --source=<commit> file.txt
```

**Restore staged file:**
```bash
g restore --staged file.txt
```

---

#### Sync Workflow

**Update branch with latest:**
```bash
g sync
```

This:
- Fetches from origin
- Rebases current branch onto origin/dev
- Pushes if needed

**Force push (DANGEROUS):**
```bash
g push --force-with-lease    # Safer force push
```

---

### Reference

<details>
<summary>Complete g Dispatcher Command List</summary>

**Basic Commands:**
- `g status` / `g st` - Show working tree status
- `g add <files>` - Stage changes
- `g commit <message>` / `g cm <message>` - Create commit
- `g push` - Push to remote
- `g pull` - Pull from remote
- `g diff` - Show changes
- `g log` - Show commit history

**Branch Commands:**
- `g branch` - List/create branches
- `g checkout <branch>` / `g co <branch>` - Switch branches
- `g checkout -b <branch>` - Create and switch to new branch
- `g branch -d <branch>` - Delete branch
- `g feature start <name>` - Start feature branch
- `g feature push` - Push current feature
- `g feature pr` - Create PR
- `g feature finish` - Finish and cleanup
- `g feature prune` - Delete merged branches
- `g feature list` - List all features

**Stash Commands:**
- `g stash` - Stash changes
- `g stash list` - List stashes
- `g stash pop` - Apply and remove stash
- `g stash apply` - Apply stash
- `g stash drop` - Remove stash
- `g stash clear` - Clear all stashes

**History Commands:**
- `g log` - Full log
- `g log --oneline` - Compact log
- `g log --graph` - Visual graph
- `g log --all` - All branches
- `g rebase <branch>` - Rebase onto branch
- `g rebase -i <commit>` - Interactive rebase
- `g cherry-pick <commit>` - Cherry-pick commit
- `g reset <commit>` - Reset to commit
- `g reset --hard <commit>` - Hard reset

**Advanced Commands:**
- `g sync` - Fetch, rebase, push
- `g restore <file>` - Restore file
- `g restore --staged <file>` - Unstage file

</details>

---

## cc Dispatcher

**Domain:** Claude Code launcher
**Complexity:** Beginner
**Most Used:** Yes (if using Claude Code)

### Basics (Beginner)

**What it does:** Launches Claude Code CLI with smart defaults.

#### Essential Commands

**Launch in current directory:**
```bash
cc
```

Output: [Launches Claude Code CLI in current directory]

**Launch with project picker:**
```bash
cc pick
```

This:
- Shows interactive project list (fzf)
- Select project
- Launch Claude Code in that directory

**Launch in yolo mode (auto-approve all):**
```bash
cc yolo
```

**WARNING:** Auto-approves all permission requests. Only use in trusted environments.

**Show help:**
```bash
cc help
```

---

### Intermediate

#### Integration with work Command

```bash
# Start work session, then launch Claude
work my-project
cc
# Claude launches in my-project directory
```

---

#### Custom Launch Options

**Environment variables respected:**
```bash
export CLAUDE_CODE_MODEL="opus"    # Use Opus model
export CLAUDE_CODE_YOLO=1          # Auto-approve by default
```

---

### Reference

<details>
<summary>Complete cc Dispatcher Command List</summary>

- `cc` - Launch Claude Code in current directory
- `cc pick` - Interactive project picker, then launch
- `cc yolo` - Launch with auto-approval
- `cc help` - Show help

</details>

---

## r Dispatcher

**Domain:** R package development
**Complexity:** Intermediate
**Most Used:** Yes (if doing R development)

### Basics (Beginner)

**What it does:** Streamlines R package development workflow.

#### Essential Commands

**Run tests:**
```bash
r test
```

Output:
```
✔ | F W  S  OK | Context
✔ |     8      | my_function

══ Results ═══════════════════════════════════
Duration: 0.5 s

[ FAIL 0 | WARN 0 | SKIP 0 | PASS 8 ]
```

**Build documentation:**
```bash
r doc
```

This runs `roxygen2::roxygenize()` to generate man pages from roxygen comments.

**Check package:**
```bash
r check
```

Runs `R CMD check` - comprehensive package validation.

**Install package:**
```bash
r install
```

Installs package locally for testing.

---

### Intermediate

#### Development Workflow

**Load package in R session:**
```bash
r load
```

Runs `devtools::load_all()` - fast iteration without full install.

**Build source tarball:**
```bash
r build
```

Creates `.tar.gz` file for distribution.

**Run example:**
```bash
r example my_function
```

Runs examples from function documentation.

---

#### Complete Development Cycle

```bash
# 1. Write function with roxygen comments
# 2. Generate documentation
r doc

# 3. Run tests
r test

# 4. Check package
r check

# 5. Install locally
r install

# 6. If all pass, commit
g commit "feat: add new function"
```

---

### Advanced

#### Custom Test Options

**Run specific test file:**
```bash
r test test-my-function.R
```

**Run with coverage:**
```bash
r coverage
```

Shows test coverage report.

**Run with profiling:**
```bash
r profile
```

Profiles package performance.

---

### Reference

<details>
<summary>Complete r Dispatcher Command List</summary>

**Basic:**
- `r test` - Run testthat tests
- `r doc` - Build documentation (roxygen2)
- `r check` - R CMD check
- `r install` - Install package
- `r build` - Build source tarball
- `r load` - Load with devtools::load_all()

**Advanced:**
- `r test <file>` - Run specific test
- `r coverage` - Test coverage report
- `r example <function>` - Run function example
- `r profile` - Profile performance
- `r help` - Show help

</details>

---

## qu Dispatcher

**Domain:** Quarto publishing
**Complexity:** Intermediate
**Most Used:** Yes (if using Quarto)

### Basics (Beginner)

**What it does:** Simplifies Quarto document rendering and publishing.

#### Essential Commands

**Preview document:**
```bash
qu preview
qu preview document.qmd
```

Starts preview server at `http://localhost:4567/`

**Render document:**
```bash
qu render
qu render document.qmd
```

Renders to default output format (usually HTML).

**Render to PDF:**
```bash
qu render document.qmd --to pdf
```

**Render to Word:**
```bash
qu render document.qmd --to docx
```

---

### Intermediate

#### Website/Book Publishing

**Render entire website:**
```bash
qu render --website
```

**Publish to GitHub Pages:**
```bash
qu publish gh-pages
```

**Create new project:**
```bash
qu create website
qu create book
qu create manuscript
```

---

### Reference

<details>
<summary>Complete qu Dispatcher Command List</summary>

- `qu preview [file]` - Start preview server
- `qu render [file]` - Render document
- `qu render --to <format>` - Render to specific format
- `qu render --website` - Render entire website
- `qu publish gh-pages` - Publish to GitHub Pages
- `qu create <type>` - Create new project
- `qu help` - Show help

</details>

---

## mcp Dispatcher

**Domain:** MCP server management
**Complexity:** Intermediate
**Most Used:** Yes (if using MCP servers)

### Basics (Beginner)

**What it does:** Manages MCP (Model Context Protocol) servers.

#### Essential Commands

**List servers:**
```bash
mcp list
mcp ls
```

Output:
```
statistical-research (running)
rforge (running)
nexus (running)
playwright (stopped)
```

**Show status:**
```bash
mcp status
```

Shows detailed status table.

**Start server:**
```bash
mcp start statistical-research
```

**Stop server:**
```bash
mcp stop statistical-research
```

**Restart server:**
```bash
mcp restart statistical-research
```

---

### Intermediate

**Show logs:**
```bash
mcp logs statistical-research
```

Tails server logs in real-time.

**Test server:**
```bash
mcp test statistical-research
```

Tests server connectivity and health.

---

### Reference

<details>
<summary>Complete mcp Dispatcher Command List</summary>

- `mcp list` / `mcp ls` - List all servers
- `mcp status` - Show detailed status
- `mcp start <name>` - Start server
- `mcp stop <name>` - Stop server
- `mcp restart <name>` - Restart server
- `mcp logs <name>` - Show logs
- `mcp test <name>` - Test connectivity
- `mcp help` - Show help

</details>

---

## obs Dispatcher

**Domain:** Obsidian note management
**Complexity:** Beginner
**Most Used:** Yes (if using Obsidian)

### Basics (Beginner)

**What it does:** Integrates with Obsidian vaults.

#### Essential Commands

**List vaults:**
```bash
obs vaults
```

Output:
```
main-vault (/Users/dt/Obsidian/main-vault)
work-vault (/Users/dt/Obsidian/work-vault)
```

**Show vault stats:**
```bash
obs stats
```

Output:
```
Total notes: 1,234
Total links: 5,678
Orphan notes: 12
Broken links: 3
```

**Search notes:**
```bash
obs search "machine learning"
```

**Open note:**
```bash
obs open "My Note"
```

Opens note in Obsidian.

**Create note:**
```bash
obs new "New Note Title"
```

---

### Reference

<details>
<summary>Complete obs Dispatcher Command List</summary>

- `obs vaults` - List vaults
- `obs stats` - Show vault statistics
- `obs search <query>` - Search notes
- `obs open <note>` - Open note in Obsidian
- `obs new <title>` - Create new note
- `obs help` - Show help

</details>

---

## Remaining Dispatchers

The following dispatchers will be completed in Day 4:

- [wt](#wt-dispatcher) - Worktrees (Advanced)
- [dot](#dot-dispatcher) - Dotfiles & Secrets (Intermediate → Advanced)
- [teach](#teach-dispatcher) - Teaching Workflow (Intermediate → Advanced)
- [tm](#tm-dispatcher) - Terminal Manager (Beginner)
- [prompt](#prompt-dispatcher) - Prompt Engine (Beginner)
- [v](#v-dispatcher) - Vibe Coding Mode (Beginner)

**Status:** Day 3/7 - Framework Complete, 6 dispatchers documented

---

**Version:** v5.17.0-dev
**Last Updated:** 2026-01-24
**Next:** Day 4 completes remaining 6 dispatchers (3,000-4,000 lines total)
