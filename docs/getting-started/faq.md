# Frequently Asked Questions

Common questions and solutions for Flow CLI.

---

## Installation & Setup

### Command not found: work / dash / flow

**Problem:** You get "command not found" when running flow-cli commands.

**Solution:** Ensure the plugin is sourced in your `.zshrc`:

```bash
# Check if sourced
which work

# If not found, add to ~/.zshrc:

# Via antidote (recommended)
antidote bundle data-wise/flow-cli

# Or manual source
source /path/to/flow-cli/flow.plugin.zsh

# Then reload
source ~/.zshrc
```

### How do I verify flow-cli is installed correctly?

Run the doctor command:

```bash
flow doctor
```

This checks all dependencies and shows what's missing.

### What dependencies does flow-cli need?

**Required:**

- ZSH (your shell)
- Git (for project detection)

**Recommended:**

- fzf (for interactive pickers)
- bat (for syntax highlighting)

**Optional:**

- tig (for git log viewing)
- Atlas (for enhanced state management)

Install recommended tools:

```bash
brew install fzf bat tig
```

---

## Project Detection

### My project isn't detected

**Problem:** `work my-project` says "Project not found."

**Solutions:**

1. **Check project location:**

   ```bash
   # Projects should be under FLOW_PROJECTS_ROOT
   echo $FLOW_PROJECTS_ROOT  # Default: ~/projects
   ls ~/projects/
   ```

2. **Check for git:**

   ```bash
   # Projects must have a .git directory
   ls -la ~/projects/my-project/.git
   ```

3. **Check category configuration:**
   ```bash
   # View configured categories
   grep -A20 "PROJ_CATEGORIES" ~/.config/zsh/functions/pick.zsh
   ```

### How do I add a new project location?

Edit the `PROJ_CATEGORIES` in your config or set `FLOW_PROJECTS_ROOT`:

```bash
# In .zshrc
export FLOW_PROJECTS_ROOT="$HOME/code"  # Different root

# Or add categories in pick.zsh
PROJ_CATEGORIES=(
    "my-custom-folder:custom:🎨"
    # ... existing categories
)
```

### Wrong project type detected

**Problem:** flow-cli shows wrong icon/type for your project.

**Solution:** Check detection priority in `lib/project-detector.zsh`:

```bash
# Detection order:
# 1. DESCRIPTION → R package
# 2. package.json → Node.js
# 3. _quarto.yml → Quarto
# 4. pyproject.toml → Python
# etc.

# Add a .STATUS file to override:
echo "## Type: my-custom-type" > .STATUS
```

---

## Sessions & Work

### How do I switch projects?

**Option 1: Full session switch**

```bash
work other-project
# Prompts to end current session
```

**Option 2: Quick switch (tmux)**

```bash
hop other-project
# Creates/switches tmux session
```

**Option 3: Just cd**

```bash
pick other-project
# Changes directory without session tracking
```

### Session conflicts: "Active session on X"

**Problem:** You get prompted about an existing session.

**Solutions:**

```bash
# Option 1: End current and start new
work other-project  # Say "yes" to switch

# Option 2: Check current session
flow status

# Option 3: Force end session
finish "Switching context"
```

### How do I see my session history?

```bash
# View worklog
cat ~/.local/share/flow/worklog | tail -20

# Or use dashboard
dash
```

---

## Wins & Goals

### Wins not saving

**Problem:** `win` command runs but wins don't appear in `yay`.

**Solutions:**

```bash
# Check wins file location
echo $FLOW_DATA_DIR
ls -la ~/.local/share/flow/wins.md

# View raw file
cat ~/.local/share/flow/wins.md

# Check permissions
ls -la ~/.local/share/flow/
```

### How do I reset my streak?

Streaks reset automatically if you miss a day. To manually reset:

```bash
# Edit the worklog (advanced)
vim ~/.local/share/flow/worklog
```

### Goal not updating

```bash
# Check global goal
cat ~/.local/share/flow/goal.json

# Check project goal
grep daily_goal .STATUS

# Reset goal
flow goal set 3
```

### Wrong category detected for win

```bash
# Force category with flag
win --code "My accomplishment"
win --fix "Fixed something"
win --ship "Deployed feature"

# Available flags: --code, --docs, --review, --ship, --fix, --test
```

---

## Dashboard & Display

### Dashboard looks broken / colors wrong

**Problem:** Dashboard has weird characters or no colors.

**Solutions:**

```bash
# Check terminal supports 256 colors
echo $TERM  # Should be xterm-256color or similar

# In .zshrc, ensure:
export TERM=xterm-256color

# Check locale
echo $LANG  # Should be en_US.UTF-8 or similar
```

### Dashboard is slow

**Problem:** `dash` takes several seconds to load.

**Solutions:**

```bash
# Use fast mode
dash --fast

# Or limit scope
dash active  # Only active projects

# Check for too many projects
ls ~/projects | wc -l  # If > 50, consider organizing
```

### fzf picker not working

```bash
# Check fzf installed
which fzf

# Install if missing
brew install fzf

# Check SHELL is zsh
echo $SHELL
```

---

## Git Integration

### "Not in a git repository"

**Problem:** Commands that need git don't work.

**Solution:** Initialize git in your project:

```bash
cd ~/projects/my-project
git init
```

### Finish command doesn't commit

**Problem:** `finish` doesn't prompt for commit.

**Possible reasons:**

1. No git repository
2. No uncommitted changes
3. User said "no" to commit prompt

```bash
# Check git status
git status

# Manual commit
git add -A && git commit -m "Your message"
```

### Sync git failed

```bash
# Check for conflicts
git status

# If rebasing
git rebase --abort  # Cancel
# or
git rebase --continue  # After resolving

# Check remote
git remote -v
```

---

## ADHD-Specific Tips

### I keep forgetting to log wins

Set up reminders:

```bash
# Add to your workflow
alias done='echo "Did you log your win? (win \"text\")"'

# Or use finish prompt
# finish automatically asks about uncommitted work
```

### Too many commands to remember

Start with just three:

```bash
work    # Start
win     # Log accomplishment
finish  # End
```

Everything else is optional enhancement.

### I lose track of what I was doing

Use breadcrumbs:

```bash
# Before switching context
crumb "Was working on auth module line 45"

# To see your trail
trail
```

### Can't decide what to work on

Let flow-cli decide:

```bash
js  # Just start - picks for you

# Or get suggestions
morning
next
```

---

## Performance

### Commands are slow

```bash
# Check for issues
flow doctor

# Disable optional features
export FLOW_ATLAS_ENABLED=no  # If using atlas

# Use fast mode where available
dash --fast
pick --fast
```

### Too much output

```bash
# Quiet mode
export FLOW_QUIET=1

# Or per-command
flow sync all --quiet
```

---

## Common Errors

### "Atlas not found"

Atlas is optional. If you don't use it:

```bash
# Disable in .zshrc
export FLOW_ATLAS_ENABLED=no
```

### "Permission denied"

```bash
# Check file permissions
ls -la ~/.local/share/flow/

# Fix permissions
chmod 755 ~/.local/share/flow
chmod 644 ~/.local/share/flow/*
```

### "fzf not found"

```bash
brew install fzf
```

---

## Getting Help

### Built-in help

```bash
# Main help
flow help

# Specific command
flow help work
work --help

# Dispatcher help
r help
g help
cc help

# Search commands
flow help --search git
```

### Health check

```bash
flow doctor
flow doctor --fix  # Interactive install
```

### Documentation

- **Website:** https://data-wise.github.io/flow-cli/
- **Issues:** https://github.com/Data-Wise/flow-cli/issues

---

## Still Stuck?

1. Run `flow doctor` to check for issues
2. Check the [Troubleshooting Guide](troubleshooting.md)
3. Search [existing issues](https://github.com/Data-Wise/flow-cli/issues)
4. Open a new issue with:
   - Your ZSH version: `echo $ZSH_VERSION`
   - flow-cli version: `flow version`
   - What you tried and what happened
