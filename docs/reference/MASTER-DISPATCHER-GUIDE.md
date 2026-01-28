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

## wt Dispatcher

**Domain:** Git worktree management
**Complexity:** Advanced
**Most Used:** Yes (advanced git workflows)

### Basics (Beginner)

**What it does:** Manages multiple working trees for a single git repository, enabling parallel development without branch switching.

**Why use worktrees:**
- Work on multiple features simultaneously
- Test PR without disrupting current work
- No need to stash or commit incomplete work
- Each worktree has its own working directory

#### Essential Commands

**Create worktree:**
```bash
wt create feature/new-feature
wt create feature/bug-fix dev
```

Output:
```
✅ Created worktree at ~/.git-worktrees/flow-cli/feature-new-feature
Switched to branch 'feature/new-feature'
```

**List worktrees:**
```bash
wt list
wt ls
```

Output:
```
main      /Users/dt/projects/dev-tools/flow-cli (main branch)
feature-x ~/.git-worktrees/flow-cli/feature-x (feature/x branch)
hotfix-y  ~/.git-worktrees/flow-cli/hotfix-y (hotfix/y branch)
```

**Remove worktree:**
```bash
wt remove feature/new-feature
wt rm feature/new-feature
```

**Prune deleted worktrees:**
```bash
wt prune
```

Cleans up worktrees that were manually deleted from filesystem.

---

### Intermediate

#### Worktree Workflow Pattern

**Scenario:** Working on Feature A, urgent Feature B needed

**Steps:**

1. **Feature A in progress (main repo):**
   ```bash
   cd ~/projects/dev-tools/flow-cli
   # Working on feature A, uncommitted changes
   ```

2. **Create Feature B worktree:**
   ```bash
   wt create feature/urgent-fix dev
   cd ~/.git-worktrees/flow-cli/feature-urgent-fix
   ```

3. **Work on Feature B:**
   ```bash
   # ... implement urgent fix ...
   g commit "fix: urgent bug"
   g push
   gh pr create
   ```

4. **Return to Feature A:**
   ```bash
   cd ~/projects/dev-tools/flow-cli
   # All your Feature A changes are still here!
   ```

5. **Cleanup after merge:**
   ```bash
   wt prune
   ```

---

#### Show Worktree Status

**Check status of all worktrees:**
```bash
wt status
```

Output:
```
main      /Users/dt/projects/dev-tools/flow-cli
  Branch: main
  Status: clean

feature-x ~/.git-worktrees/flow-cli/feature-x
  Branch: feature/user-profiles
  Status: 2 files modified, 1 file added

hotfix-y  ~/.git-worktrees/flow-cli/hotfix-y
  Branch: hotfix/login-bug
  Status: clean, ready to push
```

---

### Advanced

#### Worktree Best Practices

**1. Keep main repo on stable branch:**
```bash
# Main repo should stay on main or dev
cd ~/projects/dev-tools/flow-cli
git checkout main
# Never work directly in main repo
```

**2. Create worktrees from main repo:**
```bash
# Always create worktrees from main repo directory
cd ~/projects/dev-tools/flow-cli  # Main repo
wt create feature/new-feature dev
```

**3. Cleanup regularly:**
```bash
# Weekly cleanup
wt prune
```

**4. Name worktrees clearly:**
```bash
# Good names
wt create feature/user-authentication
wt create hotfix/critical-security-bug
wt create test/performance-optimization

# Bad names
wt create fix
wt create temp
```

---

#### Integration with work Command

**Start work in worktree:**
```bash
cd ~/.git-worktrees/flow-cli/feature-new-feature
work new-feature
# ... develop feature ...
finish "Add feature X"
```

---

#### Worktree Locations

**Default location:** `~/.git-worktrees/<repo>/<branch>/`

**Custom location:**
```bash
# Not recommended, but possible:
git worktree add /path/to/custom/location -b branch-name
```

**Why default is better:**
- Organized (all worktrees in one place)
- Easy to find
- Consistent structure
- Works with flow-cli's project detection

---

### Reference

<details>
<summary>Complete wt Dispatcher Command List</summary>

**Basic:**
- `wt create <branch>` - Create worktree for branch (creates branch from dev)
- `wt create <branch> <from-branch>` - Create worktree from specific branch
- `wt list` / `wt ls` - List all worktrees
- `wt remove <branch>` / `wt rm <branch>` - Remove worktree
- `wt prune` - Cleanup deleted worktrees

**Status:**
- `wt status` - Show status of all worktrees

**Help:**
- `wt help` - Show help

</details>

---

## dot Dispatcher

**Domain:** Dotfile management & secret storage
**Complexity:** Intermediate → Advanced
**Most Used:** Yes (configuration & security)

### Basics (Beginner)

**What it does:** Manages dotfiles and stores secrets securely in macOS Keychain with Touch ID.

#### Dotfile Management

**Edit dotfile:**
```bash
dot edit zshrc
dot edit vimrc
dot edit gitconfig
```

Opens dotfile in `$EDITOR`.

**Sync dotfiles:**
```bash
dot sync
```

Output:
```
✅ Synced 12 dotfiles
~/.zshrc → ~/dotfiles/zshrc
~/.vimrc → ~/dotfiles/vimrc
~/.gitconfig → ~/dotfiles/gitconfig
```

**Show sync status:**
```bash
dot status
```

Output:
```
dotfiles: 12 tracked
  ✅ ~/.zshrc (synced)
  ✅ ~/.vimrc (synced)
  ⚠️  ~/.gitconfig (modified, needs sync)
```

**Restore dotfile:**
```bash
dot restore zshrc
```

Restores `~/.zshrc` from `~/dotfiles/zshrc`.

---

#### Secret Management (macOS Keychain)

**Store secret:**
```bash
dot secret set GITHUB_TOKEN
```

Workflow:
1. Prompts: `Enter value for GITHUB_TOKEN:`
2. You paste token
3. Touch ID prompt
4. ✅ Stored in keychain

**Get secret:**
```bash
dot secret get GITHUB_TOKEN
```

Workflow:
1. Touch ID prompt
2. Shows token value

**List secrets:**
```bash
dot secret list
```

Output:
```
GITHUB_TOKEN
NPM_TOKEN
HOMEBREW_GITHUB_API_TOKEN
ANTHROPIC_API_KEY
```

**Delete secret:**
```bash
dot secret delete GITHUB_TOKEN
```

Workflow:
1. Touch ID prompt
2. ✅ Deleted

---

### Intermediate

#### Token Rotation Workflow

**Check token expiration:**
```bash
dot token expiring
```

Output:
```
GitHub Token: 45 days remaining ✅
NPM Token: 5 days remaining ⚠️
```

**Rotate token:**
```bash
dot token rotate GITHUB_TOKEN
```

Workflow:
1. Touch ID (get current value)
2. Shows current value (for reference)
3. Prompts for new value
4. Touch ID (store new value)
5. ✅ Token rotated

**Complete rotation example:**
```bash
# 1. Check expiration
flow doctor --dot
# Output: GitHub Token: 5 days remaining ⚠️

# 2. Generate new token on GitHub
# (Settings → Developer Settings → Tokens)

# 3. Rotate
dot token rotate GITHUB_TOKEN
# Current: ghp_old...
# Enter new: [paste new token]
# ✅ Rotated

# 4. Verify
flow doctor --dot=github
# Output: ✅ Valid (expires in 90 days)
```

---

#### Integration with git

**Automatic token usage:**
```bash
# flow-cli automatically uses keychain token for git
g push
# [Retrieves GITHUB_TOKEN from keychain]
# [Validates before push]
# [Pushes to remote]
```

**Manual token export:**
```bash
# Export to environment (for other tools)
export GITHUB_TOKEN=$(dot secret get GITHUB_TOKEN)
```

---

#### Unlock Keychain

**Unlock for session:**
```bash
dot unlock
```

Touch ID prompt → Unlocks keychain for 5 minutes.

**Why use this:**
- Batch operations (multiple secret reads)
- Automation scripts
- Avoid repeated Touch ID prompts

---

### Advanced

#### Secret Backup & Restore

**Export secrets (encrypted):**
```bash
dot secret export secrets-backup.enc
```

Creates encrypted backup of all secrets.

**Import secrets:**
```bash
dot secret import secrets-backup.enc
```

Restores secrets from backup.

**⚠️ Security Note:**
- Backup file is encrypted with keychain password
- Store backup in secure location (1Password, encrypted USB)
- Never commit backup to git

---

#### Automation with Secrets

**Safe script pattern:**
```bash
#!/bin/bash
# get-secret-safe.sh

# Unlock keychain once
dot unlock

# Use secrets multiple times (no repeated Touch ID)
GITHUB_TOKEN=$(dot secret get GITHUB_TOKEN)
NPM_TOKEN=$(dot secret get NPM_TOKEN)

# Use in script
curl -H "Authorization: token $GITHUB_TOKEN" ...
npm publish --token "$NPM_TOKEN"
```

**Unsafe pattern (avoid):**
```bash
# ❌ DON'T: Hard-code secrets
export GITHUB_TOKEN="ghp_hardcoded"  # NEVER DO THIS

# ❌ DON'T: Store in .zshrc unencrypted
echo 'export GITHUB_TOKEN="ghp_..."' >> ~/.zshrc

# ✅ DO: Use keychain
export GITHUB_TOKEN=$(dot secret get GITHUB_TOKEN)
```

---

#### Token Cache Management (v5.17.0)

**Check cache status:**
```bash
flow doctor --dot --verbose
```

Output:
```
GitHub Token
  Status: ✅ Valid
  Expires: 45 days
  Last checked: 2 minutes ago (cached)
  Cache file: ~/.cache/flow/doctor/tokens.cache
```

**Clear cache:**
```bash
rm ~/.cache/flow/doctor/tokens.cache
```

Forces fresh token check on next `flow doctor --dot`.

**Cache TTL:**
- Default: 5 minutes
- Configurable: `export FLOW_TOKEN_CACHE_TTL=300`

---

### Reference

<details>
<summary>Complete dot Dispatcher Command List</summary>

**Dotfile Management:**
- `dot edit <file>` - Edit dotfile in $EDITOR
- `dot sync` - Sync all dotfiles
- `dot status` - Show sync status
- `dot restore <file>` - Restore dotfile from backup

**Secret Management:**
- `dot secret set <name>` - Store secret in keychain
- `dot secret get <name>` - Retrieve secret (Touch ID)
- `dot secret list` - List all secrets
- `dot secret delete <name>` - Delete secret
- `dot secret rotate <name>` - Rotate secret (get old, set new)
- `dot unlock` - Unlock keychain for session

**Token Management (v5.17.0):**
- `dot token expiring` - Check token expiration (cached)
- `dot token expiring --force` - Force fresh check
- `dot token rotate <provider>` - Rotate token

**Backup (Advanced):**
- `dot secret export <file>` - Export encrypted backup
- `dot secret import <file>` - Import from backup

**Help:**
- `dot help` - Show help

</details>

---

## teach Dispatcher

**Domain:** Teaching workflow & course management
**Complexity:** Intermediate → Advanced
**Most Used:** Yes (if teaching)

### Basics (Beginner)

**What it does:** Manages teaching workflow with AI-powered course tools via Scholar integration.

#### Essential Commands

**Initialize course:**
```bash
teach init
teach init --config course-config.yml
teach init --github
```

Creates:
```
course/
├── lectures/
├── assignments/
├── exams/
├── syllabus.qmd
└── _quarto.yml
```

**Show course status:**
```bash
teach status
```

Output:
```
Course: STAT-440 Regression Analysis
Semester: Spring 2026
Instructor: Dr. Smith

Content:
  Lectures: 28 (12 deployed, 16 draft)
  Assignments: 8 (3 graded, 5 pending)
  Exams: 2 (1 graded, 1 upcoming)

Next Deadlines:
  HW3 due: 2026-02-15 (3 days)
  Midterm 1: 2026-02-20 (8 days)

Last Deploy: 2026-02-10 (2 days ago)
Site: https://username.github.io/stat-440/
```

**Deploy course site:**
```bash
teach deploy
```

Deploys to GitHub Pages.

---

### Intermediate

#### Content Analysis (AI-Powered)

**Analyze lecture content:**
```bash
teach analyze
teach analyze lectures/week-01/
```

Output (AI-powered via Scholar):
```
Analysis: lectures/week-01/01-introduction.qmd

Concepts Identified:
  1. Linear Regression (Bloom: Understand)
     Prerequisites: Basic statistics, algebra
     Complexity: Medium

  2. Least Squares Method (Bloom: Apply)
     Prerequisites: Linear regression
     Complexity: Medium

Content Quality:
  ✅ Clear learning objectives
  ✅ Appropriate complexity progression
  ⚠️  Missing worked example for concept 2

Recommendations:
  - Add worked example: Calculating least squares by hand
  - Consider visual: Residual plot explanation
```

**Batch analysis:**
```bash
teach analyze --batch
```

Analyzes all lectures, generates report.

---

#### Exam Generation (Scholar Integration)

**Generate exam:**
```bash
teach exam "Midterm 1: Chapters 1-4"
```

Scholar workflow:
1. Analyzes course content (lectures, assignments)
2. Identifies key concepts
3. Generates questions at appropriate Bloom levels
4. Creates answer key
5. Outputs markdown file

Output:
```
✅ Generated: exams/midterm-1.md
   - 10 questions (3 Remember, 4 Apply, 3 Analyze)
   - Answer key included
   - Estimated time: 50 minutes
```

**With custom template:**
```bash
teach exam --template scholar/midterm "Midterm 1"
```

---

#### Quiz Generation

**Weekly quiz:**
```bash
teach quiz "Week 5: Regression Diagnostics"
```

Similar to exam but shorter, focused on single week.

---

### Advanced

#### Scholar Configuration

**Check Scholar status:**
```bash
teach scholar status
```

Output:
```
Scholar CLI: ✅ Installed
Version: 2.1.0
Path: /opt/homebrew/bin/scholar

Templates Available:
  - midterm (comprehensive exam)
  - final (cumulative exam)
  - weekly-quiz (10-15 min quiz)
  - homework (problem set)

Course Config: ✅ Found
  File: .scholar-config.yml
  Course: STAT-440
  Level: Undergraduate
```

**Select template:**
```bash
teach exam --template scholar/final "Final Exam"
teach quiz --template scholar/weekly "Week 10 Quiz"
```

---

#### Content Analysis Workflows

**Pre-lecture analysis:**
```bash
# Before creating lecture
teach analyze lectures/week-05/

# Review recommendations
# Create lecture with improvements
```

**Post-lecture analysis:**
```bash
# After creating lecture
teach analyze lectures/week-05/regression.qmd

# Check:
# - Bloom level distribution
# - Prerequisite coverage
# - Complexity progression
```

**Batch report:**
```bash
teach analyze --batch > analysis-report.md
```

Creates comprehensive course analysis.

---

#### Deployment Workflows

**Preview before deploy:**
```bash
qu preview
# Review site locally
# Fix any issues

teach deploy
# Deploy to production
```

**Deploy with validation:**
```bash
# Check for broken links
markdown-link-check lectures/**/*.md

# Deploy
teach deploy

# Verify
curl -I https://username.github.io/stat-440/
```

---

#### Configuration Migration (v5.20.0)

**Extract lesson plans to separate file:**
```bash
# Preview what will be migrated
teach migrate-config --dry-run

# Run migration (creates backup)
teach migrate-config

# Force overwrite existing lesson-plans.yml
teach migrate-config --force
```

**Before migration:**
```
.flow/
└── teach-config.yml    # 657 lines (course + 14 weeks)
```

**After migration:**
```
.flow/
├── teach-config.yml      # ~50 lines (course meta)
├── teach-config.yml.bak  # Backup
└── lesson-plans.yml      # ~600 lines (weeks)
```

**Rollback if needed:**
```bash
cp .flow/teach-config.yml.bak .flow/teach-config.yml
rm .flow/lesson-plans.yml
```

---

#### Template Management (v5.20.0)

**List available templates:**
```bash
teach templates                        # List all templates
teach templates list --type content    # Filter by type
teach templates list --source project  # Show only project templates
```

Output:
```
┌──────────────────────────────────────────────────────────────┐
│ 📁 Teaching Templates                                        │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│ CONTENT (.flow/templates/content/)                           │
│   lecture.qmd      v1.0  Standard lecture with concepts      │
│   lab.qmd          v1.0  R lab exercise template         [P] │
│   slides.qmd       v1.0  RevealJS slides template            │
│                                                              │
│ PROMPTS (.flow/templates/prompts/)                           │
│   lecture-notes.md    v1.0  AI lecture notes generator       │
│   revealjs-slides.md  v1.0  AI slides generator          [D] │
│                                                              │
│ Legend: [P] = Project, [D] = Default (plugin)                │
└──────────────────────────────────────────────────────────────┘
```

**Create file from template:**
```bash
# Create lecture for week 5
teach templates new lecture week-05

# Create lab with topic
teach templates new lab week-03 --topic "ANOVA"

# Preview without creating
teach templates new slides week-06 --dry-run
```

**Validate templates:**
```bash
teach templates validate                  # Validate all project templates
teach templates validate lecture.qmd      # Validate specific template
```

**Sync from plugin defaults:**
```bash
teach templates sync --dry-run    # Preview what would change
teach templates sync              # Update project templates
teach templates sync --force      # Overwrite even if newer
```

**Initialize with templates:**
```bash
teach init "STAT-545" --with-templates
```

Creates:
```
.flow/templates/
├── content/     (4 templates)
├── prompts/     (3 templates)
├── metadata/    (3 templates)
└── checklists/  (2 templates)
```

**Resolution order:** Project templates override plugin defaults:
1. `.flow/templates/<type>/<name>` (highest priority)
2. `lib/templates/teaching/<name>` (fallback)

**Shortcuts:** `teach tmpl`, `teach tpl`

**Quick Reference:** See [REFCARD-TEMPLATES.md](REFCARD-TEMPLATES.md)

---

#### LaTeX Macro Management (v5.21.0)

Manage LaTeX macros for consistent AI-generated notation.

**Primary use case:** Ensure Scholar generates `\E{Y}` instead of `E[Y]`.

**List macros:**
```bash
teach macros                         # Show all macros
teach macros list                    # Same with more options
teach macros list --category operators  # Filter by category
teach macros list --format json      # JSON output
```

Output:
```
LaTeX Macros (14 available)

OPERATORS
  \E             → \mathbb{E}           Expectation
  \Var           → \text{Var}           Variance
  \Cov           → \text{Cov}           Covariance

DISTRIBUTIONS
  \Normal        → \mathcal{N}          Normal distribution
  \Binomial      → \text{Bin}           Binomial distribution

SYMBOLS
  \indep         → \perp\!\!\!\perp     Independence
  \iid           → \text{i.i.d.}        IID notation

Source: _macros.qmd (synced 2h ago)
```

**Sync from source files:**
```bash
teach macros sync              # Extract from configured sources
teach macros sync --dry-run    # Preview without changes
teach macros sync --force      # Overwrite existing cache
```

**Export for Scholar:**
```bash
teach macros export                 # Default JSON to stdout
teach macros export --format json   # JSON format
teach macros export --format mathjax  # MathJax config
teach macros export --format latex  # LaTeX \newcommand
```

**Configuration:**
```yaml
scholar:
  latex_macros:
    enabled: true
    sources:
      - path: "_macros.qmd"
        format: "qmd"
    auto_discover: true
    validation:
      warn_undefined: true
      warn_unused: true
    export:
      format: "json"
      include_in_prompts: true
```

**Supported formats:**
- QMD (Quarto) - `{=tex}` blocks with `\newcommand`
- LaTeX - Standard `.tex` files
- MathJax - HTML with `MathJax.Hub.Config`

**Macro categories:**
- operators (`\E`, `\Var`, `\Cov`)
- distributions (`\Normal`, `\Binomial`)
- symbols (`\indep`, `\iid`)
- matrices (`\bX`, `\bbeta`)
- derivatives (`\dd`, `\pd`)
- probability (`\Prob`, `\given`)

**Shortcuts:** `teach macro`, `teach m`

**Quick Reference:** See [REFCARD-MACROS.md](REFCARD-MACROS.md)

---

#### Integration with Quarto

**Render specific lecture:**
```bash
qu render lectures/week-05/regression.qmd
```

**Render all lectures:**
```bash
qu render --website
```

**Preview live:**
```bash
qu preview
# Edit files
# Auto-refresh in browser
```

---

### Reference

<details>
<summary>Complete teach Dispatcher Command List</summary>

**Setup:**
- `teach init` - Initialize course structure
- `teach init --config <file>` - Init with config
- `teach init --github` - Init with GitHub Pages

**Status:**
- `teach status` - Show course status
- `teach scholar status` - Check Scholar integration

**Content Analysis:**
- `teach analyze [path]` - Analyze content (AI-powered)
- `teach analyze --batch` - Batch analysis report

**Generation (Scholar):**
- `teach exam <topic>` - Generate exam
- `teach exam --template <name> <topic>` - Use template
- `teach quiz <topic>` - Generate quiz

**Deployment:**
- `teach deploy` - Deploy to GitHub Pages

**Migration (v5.20.0):**
- `teach migrate-config` - Extract lesson plans from config
- `teach migrate-config --dry-run` - Preview migration
- `teach migrate-config --force` - Skip confirmation
- `teach migrate-config --no-backup` - Don't create backup

**Templates (v5.20.0):**
- `teach templates` - List all templates
- `teach templates list` - List with filtering
- `teach templates new <type> <dest>` - Create from template
- `teach templates validate` - Check template syntax
- `teach templates sync` - Update from plugin defaults

**Macros (v5.21.0):**
- `teach macros` - List all macros
- `teach macros list` - List with filtering/JSON
- `teach macros sync` - Extract from source files
- `teach macros export` - Export for Scholar

**Help:**
- `teach help` - Show help

</details>

---

## tm Dispatcher

**Domain:** Terminal profile management
**Complexity:** Beginner
**Most Used:** Occasionally

### Basics (Beginner)

**What it does:** Manages terminal window settings (title, profile, visibility).

#### Essential Commands

**Set terminal title:**
```bash
tm title "flow-cli development"
```

Window title updates to "flow-cli development".

**Switch profile:**
```bash
tm profile "Solarized Dark"
tm profile "Nord"
```

Changes iTerm2/Terminal.app color profile.

**Ghost mode (hide from Spotlight/Alfred):**
```bash
tm ghost on
```

Hides terminal from application switchers.

**Disable ghost mode:**
```bash
tm ghost off
```

**Show current settings:**
```bash
tm status
```

Output:
```
Profile: Solarized Dark
Title: flow-cli development
Ghost: enabled
```

---

### Intermediate

#### Use Cases

**1. Project-specific profiles:**
```bash
# In work session
work flow-cli
tm title "flow-cli dev"
tm profile "Solarized Dark"

# Switch projects
work teaching
tm title "teaching work"
tm profile "Nord"
```

**2. Focus mode:**
```bash
# Deep work session
tm ghost on
tm title "🎯 Focus Mode"
# No interruptions from app switcher
```

**3. Presentation mode:**
```bash
# Before demo
tm profile "High Contrast"
tm title "Demo - flow-cli"
```

---

### Reference

<details>
<summary>Complete tm Dispatcher Command List</summary>

- `tm title <text>` - Set terminal title
- `tm profile <name>` - Switch color profile
- `tm ghost on` - Enable ghost mode
- `tm ghost off` - Disable ghost mode
- `tm status` - Show current settings
- `tm help` - Show help

</details>

---

## prompt Dispatcher

**Domain:** AI prompt engine switching
**Complexity:** Beginner
**Most Used:** Occasionally

### Basics (Beginner)

**What it does:** Switches between Claude (Anthropic) and Gemini (Google) prompt engines.

#### Essential Commands

**Show current engine:**
```bash
prompt status
```

Output:
```
Current engine: claude (Anthropic)
Available: claude, gemini
```

**Toggle engine:**
```bash
prompt toggle
```

Switches to other engine (claude ↔ gemini).

**Set specific engine:**
```bash
prompt use claude
prompt use gemini
```

---

### Intermediate

#### Use Cases

**1. Compare responses:**
```bash
# Try Claude
prompt use claude
# Ask question, see response

# Try Gemini
prompt use gemini
# Ask same question, compare
```

**2. Cost optimization:**
```bash
# Use Gemini for simple queries (cheaper)
prompt use gemini

# Use Claude for complex tasks (better quality)
prompt use claude
```

**3. Availability:**
```bash
# If Claude is down
prompt use gemini
```

---

### Reference

<details>
<summary>Complete prompt Dispatcher Command List</summary>

- `prompt status` - Show current engine
- `prompt toggle` - Toggle between engines
- `prompt use <engine>` - Set specific engine
- `prompt help` - Show help

</details>

---

## v Dispatcher

**Domain:** Vibe coding mode (focus mode)
**Complexity:** Beginner
**Most Used:** Occasionally

### Basics (Beginner)

**What it does:** Enables "vibe coding mode" - focus environment for deep work.

#### Essential Commands

**Enable vibe mode:**
```bash
v on
```

Activates:
- 🎵 Music playlist (Spotify/Apple Music)
- 🔕 Do Not Disturb
- 🎯 Focus settings
- 📱 Hide notifications

Output:
```
🎵 Vibe coding mode: ON
Music: ✅ Started "Lo-Fi Beats" playlist
Do Not Disturb: ✅ Enabled
Focus: Maximum
Terminal: Ghost mode enabled
```

**Disable vibe mode:**
```bash
v off
```

Output:
```
🎵 Vibe coding mode: OFF
Music: ⏸️  Paused
Do Not Disturb: ✅ Disabled
Focus: Normal
```

**Show status:**
```bash
v status
```

Output:
```
Vibe mode: ON
Started: 2h 15m ago
Sessions today: 3
Total time: 6h 45m
Current playlist: Lo-Fi Beats
```

---

### Intermediate

#### Configuration

**Custom playlist:**
```bash
# Set in ~/.zshrc
export FLOW_VIBE_PLAYLIST="My Coding Playlist"
```

**Auto-enable ghost mode:**
```bash
# Set in ~/.zshrc
export FLOW_VIBE_GHOST=1
```

**Disable music (DND only):**
```bash
# Set in ~/.zshrc
export FLOW_VIBE_MUSIC=0
```

---

#### Use Cases

**1. Deep work sessions:**
```bash
# Start focused work
v on
work my-project

# Code for 2 hours

# Take break
v off
```

**2. Flow state:**
```bash
# When you hit flow state, lock it in
v on
# No interruptions for next 1-2 hours
```

**3. Pomodoro integration:**
```bash
# 25-min work
v on
sleep 1500  # 25 minutes
v off

# 5-min break
```

---

### Reference

<details>
<summary>Complete v Dispatcher Command List</summary>

- `v on` - Enable vibe coding mode
- `v off` - Disable vibe coding mode
- `v status` - Show current status
- `v help` - Show help

</details>

---

## Dispatcher Comparison Table

| Dispatcher | Complexity | Daily Use | Key Feature |
|------------|------------|-----------|-------------|
| g | Beginner → Advanced | ⭐⭐⭐⭐⭐ | Git workflows |
| cc | Beginner | ⭐⭐⭐⭐ | Claude Code launcher |
| r | Intermediate | ⭐⭐⭐⭐ | R package dev |
| qu | Intermediate | ⭐⭐⭐⭐ | Quarto publishing |
| mcp | Intermediate | ⭐⭐⭐ | MCP server management |
| obs | Beginner | ⭐⭐⭐ | Obsidian notes |
| wt | Advanced | ⭐⭐⭐⭐ | Parallel development |
| dot | Intermediate → Advanced | ⭐⭐⭐⭐⭐ | Secrets & dotfiles |
| teach | Intermediate → Advanced | ⭐⭐⭐⭐ | Teaching + AI |
| tm | Beginner | ⭐⭐ | Terminal settings |
| prompt | Beginner | ⭐⭐ | AI engine switching |
| v | Beginner | ⭐⭐⭐ | Focus mode |

---

## Aliases

Flow CLI uses a minimalist alias approach - high-frequency commands only.

### Quick Stats

- **Custom aliases:** 31 (R package + utility)
- **Git aliases:** 226+ (from git plugin)
- **Philosophy:** Memorize less, accomplish more

### Key Aliases by Category

| Category | Aliases | Purpose |
|----------|---------|---------|
| **R Package** | `rload`, `rtest`, `rdoc`, `rcheck` | Development workflow |
| **R Quality** | `rcov`, `rcovrep` | Coverage reports |
| **R CRAN** | `rcheckfast`, `rcheckcran` | Submission checks |
| **Tool** | `cat='bat'` | Modern replacements |

### Dispatcher Shortcuts

Each dispatcher has built-in shortcuts:

```bash
g st          # git status
g co          # git checkout
r t           # r test
qu p          # qu preview
cc y          # cc yolo
```

### Quick Access

```bash
als           # List all aliases by category
```

> **Full Reference:** See archived [ALIAS-REFERENCE-CARD.md](.archive/ALIAS-REFERENCE-CARD.md) for complete alias list with frequencies and descriptions.

---

## Next Steps

- **Beginners:** Start with [g](#g-dispatcher), [cc](#cc-dispatcher), [tm](#tm-dispatcher)
- **Intermediate:** Explore [r](#r-dispatcher), [qu](#qu-dispatcher), [dot](#dot-dispatcher)
- **Advanced:** Master [wt](#wt-dispatcher), [teach](#teach-dispatcher) advanced features
- **Quick Reference:** See [QUICK-REFERENCE.md](../help/QUICK-REFERENCE.md)
- **Workflows:** See [WORKFLOWS.md](../help/WORKFLOWS.md)

---

**Version:** v5.17.0-dev
**Last Updated:** 2026-01-24
**Total:** 12 dispatchers fully documented
**Lines:** 3,000+ lines
