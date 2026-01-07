# flow config

> Configuration management with profiles

## Synopsis

```bash
flow config [command] [options]
flow config show [filter]
flow config set <key> <value>
flow config profile load <name>
```

## Description

`flow config` provides a comprehensive configuration system for flow-cli. It supports viewing and modifying settings, saving/loading configuration profiles, and an interactive wizard for first-time setup.

Configuration is stored in `~/.config/flow/config.zsh` and organized into 6 categories with 20+ configurable options.

## Commands

| Command             | Description                                    |
| ------------------- | ---------------------------------------------- |
| `show [filter]`     | Show all config (optionally filter by keyword) |
| `get <key>`         | Get a specific config value                    |
| `set <key> <value>` | Set a config value                             |
| `edit`              | Open config file in editor                     |
| `reset <key>`       | Reset a key to default                         |
| `reset --all`       | Reset all to defaults                          |
| `save`              | Save current config to file                    |
| `reload`            | Reload config from file                        |
| `wizard`            | Interactive configuration wizard               |
| `profile <action>`  | Manage configuration profiles                  |
| `export`            | Export config in shell format                  |
| `path`              | Show config file paths                         |

## Configuration Keys

### Core Settings

| Key                | Default      | Description                           |
| ------------------ | ------------ | ------------------------------------- |
| `projects_root`    | `~/projects` | Root directory for projects           |
| `atlas_enabled`    | `auto`       | Atlas integration (`auto`/`yes`/`no`) |
| `load_dispatchers` | `yes`        | Load g, r, qu, mcp, obs dispatchers   |
| `quiet`            | `0`          | Suppress startup messages             |
| `debug`            | `0`          | Enable debug output                   |

### UI Settings

| Key                  | Default   | Description            |
| -------------------- | --------- | ---------------------- |
| `color_theme`        | `default` | Color theme            |
| `progress_bar_width` | `10`      | Width of progress bars |
| `show_icons`         | `yes`     | Show icons in output   |

### Timer Settings

| Key                | Default | Description                      |
| ------------------ | ------- | -------------------------------- |
| `timer_default`    | `25`    | Default timer duration (minutes) |
| `timer_break`      | `5`     | Break timer duration (minutes)   |
| `timer_long_break` | `15`    | Long break duration (minutes)    |
| `timer_sound`      | `yes`   | Play sound when timer completes  |

### ADHD Settings

| Key               | Default | Description                              |
| ----------------- | ------- | ---------------------------------------- |
| `auto_breadcrumb` | `yes`   | Auto-create breadcrumbs on session start |
| `session_timeout` | `120`   | Session timeout (minutes)                |
| `dopamine_mode`   | `yes`   | Enable dopamine-boosting feedback        |

### Git Settings

| Key                 | Default | Description                          |
| ------------------- | ------- | ------------------------------------ |
| `auto_commit`       | `no`    | Auto-commit on finish                |
| `commit_emoji`      | `yes`   | Use emoji in commit messages         |
| `push_after_finish` | `ask`   | Push after finish (`yes`/`no`/`ask`) |

### AI Settings

| Key           | Default  | Description       |
| ------------- | -------- | ----------------- |
| `ai_provider` | `claude` | AI provider       |
| `ai_context`  | `auto`   | AI context mode   |
| `ai_verbose`  | `no`     | Verbose AI output |

## Profiles

### Built-in Profiles

| Profile      | Description                  | Key Changes                              |
| ------------ | ---------------------------- | ---------------------------------------- |
| `minimal`    | Quiet mode, minimal features | quiet=1, show_icons=no, dopamine_mode=no |
| `developer`  | Full developer settings      | load_dispatchers=yes, commit_emoji=yes   |
| `adhd`       | Maximum ADHD support         | dopamine_mode=yes, session_timeout=90    |
| `researcher` | Academic workflow optimized  | timer_default=45, push_after_finish=no   |

### Profile Commands

```bash
# List all profiles
flow config profile list

# Load a built-in profile
flow config profile load adhd

# Save current config as profile
flow config profile save work

# Delete a user profile
flow config profile delete work
```

## Examples

### View Configuration

```bash
# Show all settings
flow config show

# Filter by category
flow config show timer

# Filter by keyword
flow config show adhd
```

Output:

```
FLOW-CLI CONFIGURATION

  TIMER
    timer_default        = 25
    timer_break          = 5
    timer_long_break     = 15
    timer_sound          = yes

  * = modified from default
  Config file: ~/.config/flow/config.zsh
```

### Get/Set Values

```bash
# Get a value
flow config get timer_default
# Output: 25

# Set a value
flow config set timer_default 30
# Output: ✓ timer_default: 25 → 30

# Shorthand syntax
flow config timer_default=30
```

### Reset to Defaults

```bash
# Reset single key
flow config reset timer_default

# Reset everything
flow config reset --all
```

### Using Profiles

```bash
# Load ADHD-optimized settings
flow config profile load adhd

# Save current settings for later
flow config profile save work

# List available profiles
flow config profile list
```

Output:

```
CONFIGURATION PROFILES

  Built-in:
    minimal     - Minimal settings, quiet mode
    developer   - Full developer settings
    adhd        - Maximum ADHD support features
    researcher  - Academic workflow optimized

  User Profiles:
    work (saved: 2025-12-26)
```

### Interactive Setup

```bash
flow config wizard
```

Launches an interactive wizard that guides you through:

1. Core settings (projects root, atlas integration)
2. Timer settings (pomodoro durations)
3. ADHD settings (dopamine mode, breadcrumbs)
4. Git settings (push behavior, emoji)

### Export Configuration

```bash
# Export in shell format (for sharing or backup)
flow config export > my-config.zsh

# Show config file locations
flow config path
```

## Configuration File

The configuration file is located at:

```
~/.config/flow/config.zsh
```

Format:

```zsh
# flow-cli configuration
FLOW_CONFIG[timer_default]="25"
FLOW_CONFIG[dopamine_mode]="yes"
# ...
```

### Profile Storage

User profiles are stored in:

```
~/.config/flow/profiles/<name>.zsh
```

## Environment Variables

These can be set in `.zshrc` before sourcing flow-cli:

```zsh
# Override config directory
export FLOW_CONFIG_DIR=~/.config/flow

# Override data directory
export FLOW_DATA_DIR=~/.local/share/flow

# Override projects root
export FLOW_PROJECTS_ROOT=~/projects
```

## Related Commands

- [`flow doctor`](doctor.md) - Check system health
- [`flow install`](install.md) - Install recommended tools
- [`flow upgrade`](upgrade.md) - Update flow-cli

## See Also

- [Getting Started](../getting-started/quick-start.md)
- [ADHD Helpers Reference](../reference/ADHD-HELPERS-FUNCTION-MAP.md)

---

**Last Updated:** 2026-01-07
**Command Version:** v4.8.0 (config v3.3.0)
**Status:** ✅ Production ready with profiles
