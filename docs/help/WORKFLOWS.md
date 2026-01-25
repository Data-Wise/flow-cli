# Common Workflows

**Purpose:** Real-world workflow patterns for flow-cli
**Audience:** All users (beginners → advanced)
**Format:** Step-by-step instructions with examples
**Version:** v5.17.0-dev
**Last Updated:** 2026-01-24

---

## Table of Contents

- [Daily Workflows](#daily-workflows)
- [Git Workflows](#git-workflows)
- [Project Workflows](#project-workflows)
- [Teaching Workflows](#teaching-workflows)
- [Research Workflows](#research-workflows)
- [Plugin Workflows](#plugin-workflows)

---

## Daily Workflows

### Morning Routine (Start Your Day)

**Time:** 2-3 minutes
**Frequency:** Daily

**Steps:**

1. **Check project status**

   ```bash
   dash
   ```

   Review: Active projects, upcoming deadlines, token status

2. **Start work session**

   ```bash
   work <project>
   # OR let flow-cli pick:
   js
   ```

3. **Sync with remote**

   ```bash
   g pull
   ```

4. **Check what's next**

   ```bash
   # View dashboard for current project
   dash <project>

   # Check recent captures
   cat ~/.cache/flow/captures/$(date +%Y-%m-%d).md
   ```

**Expected Result:** Ready to work, synced with team, clear next steps

---

### During Work (Active Development)

**Pattern:** Code → Capture → Log Progress

**Quick Capture Pattern:**

```bash
# Before implementing:
catch "Implement user authentication with OAuth2"

# During debugging:
crumb "Found issue in token validation - expires_at field was string"

# After completing task:
win "Implemented OAuth2 authentication"
```

**Benefits:**
- Captures ideas before you forget
- Documents decisions
- Tracks progress for dopamine

---

### End of Day (Wrap Up)

**Time:** 3-5 minutes
**Frequency:** Daily

**Steps:**

1. **Review wins**

   ```bash
   yay
   ```

   See: What you accomplished today

2. **Commit work**

   ```bash
   finish "Daily progress on feature X"
   # OR if not ready to commit:
   g stash
   ```

3. **Update status**

   ```bash
   # If using .STATUS files:
   echo "status: Active" > .STATUS
   echo "progress: 65" >> .STATUS
   echo "next: Complete authentication tests" >> .STATUS
   ```

4. **Push changes (if committed)**

   ```bash
   g push
   ```

**Expected Result:** Work saved, progress tracked, clean slate for tomorrow

---

## Git Workflows

### Feature Branch Workflow (Simple)

**Use When:** Working on isolated feature
**Time:** 5-10 minutes setup + development time

**Steps:**

1. **Start from clean main/dev**

   ```bash
   git checkout dev
   g pull
   ```

2. **Create feature branch**

   ```bash
   g feature start my-feature
   ```

   This creates: `feature/my-feature` from `dev`

3. **Work on feature**

   ```bash
   # Make changes
   g add .
   g commit "feat: add user profile page"
   ```

4. **Push feature**

   ```bash
   g feature push
   ```

5. **Create PR**

   ```bash
   g feature pr
   # OR manually:
   gh pr create --base dev
   ```

6. **After PR merge, cleanup**

   ```bash
   g feature finish
   ```

   This:
   - Switches back to dev
   - Pulls latest
   - Deletes feature branch

**Real Example:**

```bash
# Day 1: Start feature
git checkout dev && g pull
g feature start user-profiles
# ... work on feature ...
g add .
g commit "feat: add user profile page"
g feature push
g feature pr

# Day 5: PR merged, cleanup
g feature finish
```

---

### Worktree Workflow (Parallel Development)

**Use When:** Need to work on multiple features simultaneously or test PR without disrupting current work

**Time:** 5 minutes setup

**Steps:**

1. **Create worktree for feature**

   ```bash
   # Main repo stays on main/dev
   cd ~/projects/dev-tools/flow-cli
   git checkout main

   # Create worktree
   wt create feature/new-feature dev
   ```

   This creates: `~/.git-worktrees/flow-cli/feature-new-feature/`

2. **Work in worktree**

   ```bash
   cd ~/.git-worktrees/flow-cli/feature-new-feature
   work new-feature
   # ... develop feature ...
   finish "Add feature X"
   ```

3. **Parallel: Hotfix needed!**

   ```bash
   # Go back to main repo (NOT the worktree)
   cd ~/projects/dev-tools/flow-cli

   # Create hotfix worktree
   wt create hotfix/critical-bug main

   cd ~/.git-worktrees/flow-cli/hotfix-critical-bug
   # ... fix bug ...
   finish "Fix critical login bug"
   g push
   gh pr create
   ```

4. **Return to feature work**

   ```bash
   cd ~/.git-worktrees/flow-cli/feature-new-feature
   # Continue where you left off
   ```

5. **Cleanup after merge**

   ```bash
   wt prune
   ```

**Real Example:**

```bash
# Working on feature A
wt create feature/user-profiles dev
cd ~/.git-worktrees/flow-cli/feature-user-profiles

# Urgent bug reported!
# Create hotfix without disrupting feature work
cd ~/projects/dev-tools/flow-cli
wt create hotfix/login-timeout main
cd ~/.git-worktrees/flow-cli/hotfix-login-timeout
# ... fix bug, push, PR ...

# Back to feature A
cd ~/.git-worktrees/flow-cli/feature-user-profiles
# Work continues seamlessly

# After PRs merge
wt prune  # Cleanup both worktrees
```

---

### Bug Fix Workflow

**Use When:** Quick bug fix needed
**Time:** 10-30 minutes

**Steps:**

1. **Reproduce bug**

   ```bash
   # Document reproduction steps
   catch "Bug: Login fails with 'Invalid token' error"
   crumb "Reproduce: curl -X POST /api/login with expired token"
   ```

2. **Create fix branch**

   ```bash
   g feature start fix-login-token
   ```

3. **Fix + Test**

   ```bash
   # Make fix
   # Test manually
   # Add regression test if applicable
   ```

4. **Commit with proper message**

   ```bash
   g commit "fix: handle expired tokens in login endpoint

   - Check token expiration before validation
   - Return 401 with clear error message
   - Add test for expired token scenario

   Fixes #123"
   ```

5. **Push + PR**

   ```bash
   g push
   gh pr create
   ```

**Real Example:**

```bash
catch "Users getting 500 error on login"
g feature start fix-login-500
# ... investigate, find null check missing ...
g commit "fix: add null check for user.profile

Prevents 500 error when user has no profile.
Returns empty profile object instead.

Fixes #456"
g push && gh pr create
```

---

## Project Workflows

### New Project Setup

**Use When:** Starting new project
**Time:** 10-15 minutes

**Steps:**

1. **Create project directory**

   ```bash
   mkdir -p ~/projects/dev-tools/my-new-project
   cd ~/projects/dev-tools/my-new-project
   ```

2. **Initialize based on type**

   **Node.js:**

   ```bash
   npm init -y
   git init
   echo "node_modules/" > .gitignore
   ```

   **R Package:**

   ```bash
   Rscript -e "usethis::create_package('.')"
   ```

   **Quarto:**

   ```bash
   quarto create project website
   ```

   **Teaching:**

   ```bash
   teach init --config course-config.yml
   ```

3. **Create .STATUS file**

   ```bash
   cat > .STATUS <<EOF
   status: Active
   progress: 5
   next: Set up basic structure
   target: MVP by end of month
   EOF
   ```

4. **Start work**

   ```bash
   work my-new-project
   ```

5. **First commit**

   ```bash
   g add .
   g commit "chore: initial project setup"
   ```

---

### Project Context Switch

**Use When:** Switching between projects frequently
**Time:** < 1 minute

**Pattern 1: Using hop (tmux)**

```bash
# While in project A
hop project-b
# Instantly in project B's tmux session
```

**Pattern 2: Using pick**

```bash
# From anywhere
pick
# [Interactive fzf picker]
# Select project → auto-cd
```

**Pattern 3: Using work**

```bash
work project-b
# Sets up session, cd's to project
```

**Real Example:**

```bash
# Morning: Start on flow-cli
work flow-cli

# Noon: Quick switch to teaching
hop stat-440
teach status

# Afternoon: Back to flow-cli
hop flow-cli
```

---

## Teaching Workflows

### Course Setup (One-Time)

**Use When:** Starting new course
**Time:** 15-20 minutes

**Steps:**

1. **Initialize course**

   ```bash
   teach init --config course-config.yml
   ```

2. **Set up GitHub repo**

   ```bash
   teach init --github
   ```

3. **Verify Scholar**

   ```bash
   teach scholar status
   ```

4. **Create initial content**

   ```bash
   # Week 1 lecture
   mkdir -p lectures/week-01
   touch lectures/week-01/01-introduction.qmd
   ```

5. **First deploy**

   ```bash
   teach deploy
   ```

**Result:** Course website live at `https://<username>.github.io/<course>/`

---

### Weekly Lecture Preparation

**Use When:** Preparing weekly lecture
**Time:** 30-60 minutes (without AI) / 15-30 minutes (with AI)

**Without AI:**

```bash
# Monday: Create lecture
mkdir -p lectures/week-05
cp lectures/_template.qmd lectures/week-05/regression.qmd
# ... write content ...

# Wednesday: Review
qu preview lectures/week-05/regression.qmd

# Friday: Deploy
teach deploy
```

**With AI (Scholar):**

```bash
# Monday: Analyze existing content
teach analyze lectures/week-04/

# Based on analysis, generate next week
teach exam "Week 5: Linear Regression"

# Review generated content
qu preview lectures/week-05/regression.qmd

# Deploy
teach deploy
```

---

### Exam Generation Workflow

**Use When:** Creating exams
**Time:** 10-20 minutes (with Scholar)

**Steps:**

1. **Define exam scope**

   ```bash
   catch "Midterm 1: Covers weeks 1-5, focus on regression"
   ```

2. **Generate exam**

   ```bash
   teach exam "Midterm 1: Regression and Hypothesis Testing"
   ```

   Scholar will:
   - Analyze course content
   - Generate questions at appropriate Bloom levels
   - Create answer key

3. **Review and edit**

   ```bash
   $EDITOR exams/midterm-1.md
   ```

4. **Render**

   ```bash
   qu render exams/midterm-1.qmd
   ```

**Real Example:**

```bash
# Week 7: Midterm coming up
teach exam "Midterm 1: Chapters 1-4"
# Review generated questions
# Adjust difficulty if needed
qu render exams/midterm-1.qmd
# Print or upload to LMS
```

---

## Research Workflows

### R Package Development

**Use When:** Developing R package
**Time:** Variable (5 min → hours)

**Daily Workflow:**

```bash
# Morning
work my-package
r load              # Load package
r test              # Run tests

# During development
# ... write function ...
r doc               # Update documentation
r test              # Run tests
win "Added feature X"

# Before commit
r check             # R CMD check
finish "Add feature X"
```

**Release Workflow:**

```bash
# Pre-release checks
r check
r test
r doc

# Update version
# Update NEWS.md
# Update DESCRIPTION

# Build and check
r build
r check

# Commit
g commit "chore: release v1.2.0"

# Tag release
git tag v1.2.0
g push --tags

# Submit to CRAN
r submit
```

---

### Quarto Publishing Workflow

**Use When:** Writing academic paper / report
**Time:** Variable

**Iterative Workflow:**

```bash
# Start writing
work my-manuscript
qu preview manuscript.qmd

# Write → Preview → Repeat
# ... make changes ...
# Preview auto-refreshes

# Generate PDF
qu render manuscript.qmd --to pdf

# Generate Word (for collaborators)
qu render manuscript.qmd --to docx
```

**Multi-Format Workflow:**

```bash
# Define output formats in YAML:
---
title: "My Paper"
format:
  html: default
  pdf: default
  docx: default
---

# Render all formats
qu render manuscript.qmd
```

---

## Plugin Workflows

### Git Plugin Workflow (226 Aliases)

**Use When:** Daily git operations
**Time:** Saves ~30% typing

**Common Patterns:**

```bash
# Status check
gst                    # git status
gd                     # git diff
gdca                   # git diff --cached

# Staging
ga .                   # git add .
gaa                    # git add --all

# Committing
gcmsg "message"        # git commit -m
gcam "message"         # git commit -a -m

# Pushing/Pulling
ggp                    # git push origin current-branch
ggl                    # git pull origin current-branch

# Branching
gb                     # git branch
gco branch-name        # git checkout branch-name
gcb new-branch         # git checkout -b new-branch

# Logging
glo                    # git log --oneline
glog                   # git log --oneline --graph --all
```

**Real Workflow:**

```bash
# Morning
gst                          # Check status
ggl                          # Pull latest
gcb feature/new-feature      # Create branch

# During work
ga .                         # Stage changes
gcmsg "feat: add X"          # Commit
ggp                          # Push

# End of day
gco dev                      # Switch to dev
ggl                          # Pull latest
gbd feature/old              # Delete merged branch
```

**See:** [Tutorial 24: Git Workflow](../tutorials/17-lazyvim-basics.md) for complete reference

---

### Clipboard Plugin Workflow

**Use When:** Managing clipboard history
**Plugins:** clipcopy, clippaste

**Pattern:**

```bash
# Copy command output
ls -la | clipcopy

# Paste from clipboard
clippaste > file.txt

# Copy file contents
cat README.md | clipcopy
```

---

### Z Plugin Workflow (Smart Directory Jumping)

**Use When:** Quick navigation to frequent directories
**Plugin:** z (tracks directory frequency)

**Pattern:**

```bash
# After visiting directory a few times:
cd ~/projects/dev-tools/flow-cli

# Later, from anywhere:
z flow        # Jumps to ~/projects/dev-tools/flow-cli
z cli         # Also works
z dev tools   # Partial matching

# List matches
z -l flow

# Go to highest ranked match
z flow
```

**Real Example:**

```bash
# Instead of:
cd ~/projects/dev-tools/flow-cli

# Just use:
z flow

# Works from anywhere:
z teaching    # → ~/projects/teaching/stat-440
z research    # → ~/projects/research/mediation
```

---

## Advanced Workflows

### Parallel Feature Development (Worktrees)

**Scenario:** Working on Feature A, urgent Feature B comes up, don't want to stash/commit

**Steps:**

1. **Feature A in progress**

   ```bash
   # Working on feature A
   cd ~/projects/dev-tools/flow-cli
   # Uncommitted changes in feature/profile-page
   ```

2. **Urgent Feature B needed**

   ```bash
   # Create Feature B worktree (from dev)
   wt create feature/urgent-fix dev

   # Work on Feature B in isolation
   cd ~/.git-worktrees/flow-cli/feature-urgent-fix
   # ... implement urgent fix ...
   finish "Fix urgent issue"
   g push
   gh pr create
   ```

3. **Back to Feature A**

   ```bash
   cd ~/projects/dev-tools/flow-cli
   # All your uncommitted Feature A changes are still here!
   ```

**Benefits:**
- No git stash needed
- Both features can be in progress
- Clean separation
- Can test both features independently

---

### Token Rotation Workflow (Security)

**Use When:** Token about to expire or compromised
**Frequency:** Every 90 days or as needed

**Steps:**

1. **Check expiration**

   ```bash
   flow doctor --dot
   # Output: GitHub Token: 5 days remaining ⚠️
   ```

2. **Generate new token** (on GitHub)

   - Go to Settings → Developer Settings → Personal Access Tokens
   - Generate new token with same scopes
   - Copy token

3. **Rotate in keychain**

   ```bash
   dot secret rotate GITHUB_TOKEN
   # [Touch ID prompt]
   # Enter new token: [paste]
   ```

4. **Verify**

   ```bash
   flow doctor --dot=github --verbose
   # Output: ✅ Valid (expires in 90 days)
   ```

5. **Update CI/CD** (if applicable)

   - Update GitHub secrets
   - Update environment variables

**Automation (v5.17.0):**

```bash
# Set reminder
flow doctor --dot
# Checks and warns 30 days before expiration
```

---

## Troubleshooting Workflows

### "Command not found" Fix

```bash
# 1. Check if flow-cli is sourced
which work
# If nothing: flow-cli not loaded

# 2. Check .zshrc
grep "flow.plugin.zsh" ~/.zshrc
# OR
grep "flow-cli" ~/.zshrc

# 3. Source manually
source ~/projects/dev-tools/flow-cli/flow.plugin.zsh

# 4. Restart shell
exec zsh
```

---

### Git Push Fails (Token Issue)

```bash
# 1. Check token
flow doctor --dot=github

# 2. If expired, rotate
dot secret rotate GITHUB_TOKEN

# 3. Retry push
g push

# 4. If still fails, check scopes
# Token needs: repo, workflow
```

---

### Performance Issues

```bash
# 1. Run health check
flow doctor

# 2. Check cache
# Token cache: ~/.cache/flow/doctor/tokens.cache
# Invalidate: rm ~/.cache/flow/doctor/tokens.cache

# 3. Check Atlas connection
flow doctor --verbose

# 4. Disable Atlas if needed
export FLOW_ATLAS_ENABLED=no
exec zsh
```

---

## Tips for Workflow Efficiency

### Use Aliases Aggressively

```bash
# Instead of typing full commands, use aliases:
work → w (create alias in .zshrc)
finish → f
dash → d
```

### Combine Commands

```bash
# Chain related commands
g add . && g commit "feat: X" && g push

# Alias common chains
alias gcp='g add . && g commit -m "$1" && g push'
```

### Tab Completion is Your Friend

```bash
work <Tab>        # List all projects
g <Tab>           # All git commands
teach <Tab>       # All teach commands
```

### Use Interactive Modes

```bash
dash -i           # Interactive dashboard
pick              # Interactive project picker
```

---

## Next Steps

- **Beginners:** [Quick Start](../getting-started/quick-start.md)
- **Tutorials:** [Tutorial Index](../tutorials/index.md)
- **Commands:** [Quick Reference](QUICK-REFERENCE.md)
- **Troubleshooting:** [Troubleshooting Guide](TROUBLESHOOTING.md)

---

**Version:** v5.17.0-dev
**Last Updated:** 2026-01-24
**Contributors:** See [CHANGELOG.md](../CHANGELOG.md)
