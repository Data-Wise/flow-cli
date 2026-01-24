# Configuration Management Workflow

**Quick Answer:** `flow config` manages all flow-cli settings. View, edit, save, and manage configuration profiles for different workflows.

---

## Overview

flow-cli configuration controls behavior across all commands, from colors to ADHD features to timer defaults.

**What you can configure:**
- Core settings (projects root, Atlas integration)
- UI preferences (colors, icons, progress bars)
- Timer defaults (focus time, breaks)
- ADHD features (auto-breadcrumb, dopamine mode)
- Git behavior (auto-commit, push settings)
- AI integration (provider, context, verbosity)

---

## Quick Start

### View All Settings

```bash
# Show all configuration
flow config show

# Filter by keyword
flow config show timer
flow config show adhd
```

**Output example:**

```
╔════════════════════════════════════════════╗
║ FLOW-CLI CONFIGURATION                     ║
╚════════════════════════════════════════════╝

Core Settings:
  projects_root       /Users/dt/projects
  atlas_enabled       auto
  quiet               no
  debug               no

Timer Settings:
  timer_default       25
  timer_break         5
  timer_long_break    15
  timer_sound         yes

ADHD Features:
  auto_breadcrumb     yes
  dopamine_mode       yes
  session_timeout     3600
```

---

### Get/Set Individual Values

```bash
# Get current value
flow config get timer_default
# → 25

# Set new value
flow config set timer_default 30
# ✓ timer_default: 25 → 30

# Shorthand (key=value)
flow config timer_default=30
```

---

### Edit Configuration File

```bash
# Open config in editor
flow config edit

# Default editor: $EDITOR (vim/nano/etc)
```

**After editing:**

```bash
# Reload configuration?
# [y/N]: y
# ✓ Configuration reloaded
```

---

## Configuration Profiles

### Built-in Profiles

flow-cli includes 4 optimized profiles:

| Profile | Best For | Features |
|---------|----------|----------|
| **minimal** | Quiet workflows | Minimal output, essential features only |
| **developer** | Full dev work | All features, verbose output |
| **adhd** | Maximum support | Dopamine mode, auto-breadcrumb, timers |
| **researcher** | Academic work | Long timers, quiet mode, export features |

---

### Using Profiles

```bash
# List available profiles
flow config profile list

# Load a profile
flow config profile load adhd
flow config profile adhd      # Shorthand

# Save current config as custom profile
flow config profile save my-workflow
```

**Example output:**

```
Built-in Profiles:
  minimal     Quiet mode, minimal features
  developer   Full dev features
  adhd        Maximum ADHD support
  researcher  Academic workflow

Custom Profiles:
  my-workflow (saved 2026-01-10)
```

---

### Profile Details

**Minimal Profile:**

```yaml
quiet: yes
show_icons: no
dopamine_mode: no
auto_breadcrumb: no
timer_sound: no
```

**Developer Profile:**

```yaml
atlas_enabled: yes
debug: yes
show_icons: yes
dopamine_mode: yes
auto_commit: no  # Manual control
```

**ADHD Profile:**

```yaml
dopamine_mode: yes
auto_breadcrumb: yes
timer_default: 25
timer_break: 5
session_timeout: 1800  # 30min
commit_emoji: yes
```

**Researcher Profile:**

```yaml
quiet: yes
timer_default: 45
timer_long_break: 20
auto_commit: yes
push_after_finish: yes
```

---

## Configuration Keys Reference

### Core Settings

| Key | Values | Default | Description |
|-----|--------|---------|-------------|
| `projects_root` | path | `~/projects` | Root directory for projects |
| `atlas_enabled` | auto/yes/no | `auto` | Enable Atlas integration |
| `load_dispatchers` | yes/no | `yes` | Load all dispatchers (g, r, qu, etc) |
| `quiet` | yes/no | `no` | Suppress non-essential output |
| `debug` | yes/no | `no` | Show debug messages |

---

### UI Settings

| Key | Values | Default | Description |
|-----|--------|---------|-------------|
| `color_theme` | light/dark/auto | `auto` | Color theme |
| `show_icons` | yes/no | `yes` | Show emoji icons |
| `progress_bar_width` | 1-100 | `50` | Progress bar character width |

---

### Timer Settings

| Key | Values | Default | Description |
|-----|--------|---------|-------------|
| `timer_default` | minutes | `25` | Default focus timer duration |
| `timer_break` | minutes | `5` | Short break duration |
| `timer_long_break` | minutes | `15` | Long break duration (after 4 pomodoros) |
| `timer_sound` | yes/no | `yes` | Play sound when timer ends |

---

### ADHD Features

| Key | Values | Default | Description |
|-----|--------|---------|-------------|
| `auto_breadcrumb` | yes/no | `yes` | Auto-save breadcrumbs on dir change |
| `dopamine_mode` | yes/no | `yes` | Enable win tracking and celebrations |
| `session_timeout` | seconds | `3600` | Auto-finish session after inactivity |

---

### Git Behavior

| Key | Values | Default | Description |
|-----|--------|---------|-------------|
| `auto_commit` | yes/no | `no` | Auto-commit on finish |
| `commit_emoji` | yes/no | `yes` | Use emojis in commit messages |
| `push_after_finish` | yes/ask/no | `ask` | Auto-push after finish |

---

### AI Integration

| Key | Values | Default | Description |
|-----|--------|---------|-------------|
| `ai_provider` | claude/openai/local | `claude` | AI provider |
| `ai_context` | minimal/normal/full | `normal` | Context sent to AI |
| `ai_verbose` | yes/no | `no` | Verbose AI output |

---

## Common Workflows

### Workflow 1: First-Time Setup

```bash
# Run interactive wizard
flow config wizard

# Or use profile as starting point
flow config profile load adhd

# Customize specific settings
flow config set timer_default 30
flow config set projects_root ~/work

# Save configuration
flow config save
```

---

### Workflow 2: Project-Specific Config

Different config for work vs personal projects:

**Work profile:**

```bash
# Create work profile
flow config profile load minimal
flow config set quiet yes
flow config set auto_commit yes
flow config set push_after_finish yes
flow config profile save work
```

**Personal profile:**

```bash
# Create personal profile
flow config profile load adhd
flow config set dopamine_mode yes
flow config set timer_default 25
flow config profile save personal
```

**Switch based on context:**

```bash
# In work project
cd ~/work/client-project
flow config profile work

# In personal project
cd ~/projects/hobby-app
flow config profile personal
```

---

### Workflow 3: Team Standardization

Share config across team:

```bash
# Export team config
flow config export > team-flow-config.sh

# Team members import
source team-flow-config.sh
flow config save
```

**Example export:**

```bash
# Generated by flow config export
export FLOW_CONFIG_projects_root="$HOME/workspace"
export FLOW_CONFIG_atlas_enabled="yes"
export FLOW_CONFIG_auto_commit="yes"
export FLOW_CONFIG_timer_default="25"
```

---

### Workflow 4: Temporary Override

Override config for single session:

```bash
# Set for current shell only (doesn't persist)
export FLOW_QUIET=1
export FLOW_DEBUG=1

# Run commands
flow work my-project
flow test

# Exit shell - config reverts to saved
exit
```

---

## Advanced Configuration

### Config File Location

**Default:** `~/.config/flow-cli/config.sh`

**Custom location:**

```bash
export FLOW_CONFIG_FILE="$HOME/.flow/my-config.sh"
```

---

### Config File Format

```bash
# ~/.config/flow-cli/config.sh
# Auto-generated by flow config save

# Core
FLOW_CONFIG[projects_root]="$HOME/projects"
FLOW_CONFIG[atlas_enabled]="auto"
FLOW_CONFIG[quiet]="no"

# Timer
FLOW_CONFIG[timer_default]="25"
FLOW_CONFIG[timer_break]="5"

# ADHD
FLOW_CONFIG[dopamine_mode]="yes"
FLOW_CONFIG[auto_breadcrumb]="yes"

# Git
FLOW_CONFIG[auto_commit]="no"
FLOW_CONFIG[push_after_finish]="ask"
```

---

### Programmatic Access (ZSH)

```bash
# Read config value in your scripts
local timer=$(_flow_config_get "timer_default")
echo "Timer: $timer minutes"

# Set config value
_flow_config_set "timer_default" "30"

# Reset to default
_flow_config_reset "timer_default"
```

---

## Configuration Wizard

Interactive setup for first-time users:

```bash
flow config wizard
```

**Wizard flow:**

```
╔════════════════════════════════════════════╗
║ FLOW-CLI CONFIGURATION WIZARD              ║
╚════════════════════════════════════════════╝

1/8 Projects Location
  Where do you keep your projects?
  [/Users/dt/projects]:

2/8 Timer Preferences
  Default focus time (minutes)?
  [25]:

3/8 ADHD Features
  Enable dopamine mode (win tracking)?
  [yes]:

4/8 Git Behavior
  Auto-commit on finish?
  [no]:

...

✅ Configuration complete!
Saved to: ~/.config/flow-cli/config.sh

Reload shell to apply: exec zsh
```

---

## Reset & Backup

### Reset Configuration

```bash
# Reset single key to default
flow config reset timer_default

# Reset all to defaults (with confirmation)
flow config reset --all

# Force reset without confirmation
flow config reset --all -f
```

---

### Backup Configuration

```bash
# Manual backup
cp ~/.config/flow-cli/config.sh \
   ~/.config/flow-cli/config.sh.backup

# Restore from backup
cp ~/.config/flow-cli/config.sh.backup \
   ~/.config/flow-cli/config.sh
flow config reload
```

---

### Version Control

Track config in git:

```bash
cd ~/.config/flow-cli
git init
git add config.sh
git commit -m "Initial flow-cli config"

# Update config
flow config set timer_default 30
flow config save
git commit -am "Update timer default"

# Restore old version
git checkout HEAD~1 config.sh
flow config reload
```

---

## Troubleshooting

### Issue: Changes not taking effect

**Symptoms:** Settings don't change behavior

**Cause:** Config not saved or not reloaded

**Solution:**

```bash
# Save changes
flow config save

# Reload shell
exec zsh

# Or reload without restarting
flow config reload
```

---

### Issue: Config file not found

**Symptoms:** `No config file found, using defaults`

**Cause:** Config file not created yet

**Solution:**

```bash
# Create config file
flow config save

# Verify location
flow config path
```

---

### Issue: Invalid config value

**Symptoms:** `Invalid value. Use: yes/no`

**Cause:** Wrong value format for key

**Solution:**

```bash
# Check allowed values
flow config set timer_default
# → Shows current value and hints

# Use correct format
# Boolean: yes/no (not 1/0 or true/false)
# Number: integers only
# Enum: specified values only
```

---

### Issue: Profile not found

**Symptoms:** `Profile not found: my-profile`

**Cause:** Typo or profile not saved

**Solution:**

```bash
# List available profiles
flow config profile list

# Save profile if needed
flow config profile save my-profile
```

---

## Best Practices

### DO ✅

**1. Save config after changes**

```bash
flow config set timer_default 30
flow config save  # Don't forget!
```

**2. Use profiles for different contexts**

```bash
flow config profile save work
flow config profile save personal
flow config profile save client-project
```

**3. Document custom settings**

```bash
# Add comments to config file
vim ~/.config/flow-cli/config.sh

# Custom timer for deep work
FLOW_CONFIG[timer_default]="45"  # 45min focus blocks
```

**4. Test changes before saving**

```bash
# Try temporary override
FLOW_QUIET=1 flow dash

# If good, make permanent
flow config set quiet yes
flow config save
```

---

### DON'T ❌

**1. Don't edit config while flow commands running**

```bash
# ❌ Bad: Edit during work session
flow work my-project  # Session running
# ... in another terminal: flow config edit

# ✅ Good: Edit before/after
finish
flow config edit
```

**2. Don't use environment variables for permanent config**

```bash
# ❌ Bad: In .zshrc (overrides config file)
export FLOW_QUIET=1

# ✅ Good: Use config system
flow config set quiet yes
flow config save
```

**3. Don't forget to reload**

```bash
# ❌ Bad: Expect instant changes
flow config set timer_default 30
# Commands still use old value

# ✅ Good: Reload
flow config save
exec zsh
```

---

## Configuration Migration

### From v3.x to v4.x

```bash
# Old format (environment variables)
export FLOW_PROJECTS_ROOT="$HOME/projects"
export FLOW_TIMER_DEFAULT="25"

# New format (config system)
flow config set projects_root "$HOME/projects"
flow config set timer_default 25
flow config save
```

---

### Import Old Config

```bash
# If you have old env vars in .zshrc, migrate:
OLD_ROOT="$FLOW_PROJECTS_ROOT"
OLD_TIMER="$FLOW_TIMER_DEFAULT"

flow config set projects_root "$OLD_ROOT"
flow config set timer_default "$OLD_TIMER"
flow config save

# Remove old vars from .zshrc
vim ~/.zshrc
# Delete: export FLOW_* lines
```

---

## Summary

**Key Points:**

1. ✅ `flow config show` - View all settings
2. ✅ `flow config set key value` - Change settings
3. ✅ `flow config save` - Persist changes
4. ✅ `flow config profile load` - Quick preset switching
5. ✅ `flow config wizard` - Interactive first-time setup

**Quick workflow:**

```bash
# View current
flow config show

# Make changes
flow config set timer_default 30
flow config set dopamine_mode yes

# Save and reload
flow config save
exec zsh

# Or use profile
flow config profile load adhd
```

---

**Last Updated:** 2026-01-10
**Version:** v5.0.0
**Related:** [flow.md](../commands/flow.md), [plugin guide](./PLUGIN-MANAGEMENT-WORKFLOW.md)
