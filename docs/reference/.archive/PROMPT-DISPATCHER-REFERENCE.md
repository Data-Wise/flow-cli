# Prompt Dispatcher Reference

> **Version:** 5.7.0
> **File:** `lib/dispatchers/prompt-dispatcher.zsh`
> **Status:** ✅ Stable

The `prompt` dispatcher provides unified management of multiple prompt engines: **Powerlevel10k**, **Starship**, and **Oh My Posh**. Switch between engines instantly without manual configuration editing.

---

## Quick Start

```bash
# See current engine
prompt status

# Switch engines interactively
prompt toggle

# Direct switch to specific engine
prompt starship
prompt p10k
prompt ohmyposh
```

---

## Commands

### Status Commands

| Command | Description | Example |
|---------|-------------|---------|
| `prompt status` | Show current engine + alternatives | `prompt status` |
| `prompt list` | Table view of all engines | `prompt list` |

### Engine Switching

| Command | Description | Example |
|---------|-------------|---------|
| `prompt toggle` | Interactive menu to pick engine | `prompt toggle` |
| `prompt starship` | Switch to Starship | `prompt starship` |
| `prompt p10k` | Switch to Powerlevel10k | `prompt p10k` |
| `prompt ohmyposh` | Switch to Oh My Posh | `prompt ohmyposh` |

### Setup & Configuration

| Command | Description | Example |
|---------|-------------|---------|
| `prompt setup-ohmyposh` | Interactive Oh My Posh wizard | `prompt setup-ohmyposh` |
| `prompt help` | Show full help text | `prompt help` |

### Options

| Option | Description | Example |
|--------|-------------|---------|
| `--dry-run` | Preview changes without applying | `prompt --dry-run toggle` |

---

## Engine Comparison

| Feature | Powerlevel10k | Starship | Oh My Posh |
|---------|---------------|----------|-----------|
| **Type** | ZSH plugin | Rust binary | Go binary |
| **Installation** | Via antidote | `brew install` | `brew install` |
| **Speed** | ⚡⚡⚡ Very fast | ⚡⚡⚡⚡ Fastest | ⚡⚡ Fast |
| **Customization** | Excellent | Good | Extensive |
| **Themes** | Many built-in | Many presets | 100+ official |
| **Config Format** | ZSH script | TOML | JSON/YAML |
| **Best For** | Feature-rich | Speed-focused | Theme exploration |

### Configuration Paths

```
Powerlevel10k → ~/.config/zsh/.p10k.zsh
Starship      → ~/.config/starship.toml
Oh My Posh    → ~/.config/ohmyposh/config.json
```

---

## Detailed Command Reference

### `prompt status`

Display the current prompt engine and available alternatives.

**Output:**

```
ℹ Prompt Engines:

  ● Powerlevel10k (current)
    Feature-rich, highly customizable
    Config: ~/.config/zsh/.p10k.zsh

  ○ Starship
    Minimal, fast Rust-based
    Config: ~/.config/starship.toml

  ○ Oh My Posh
    Modular with extensive themes
    Config: ~/.config/ohmyposh/config.json

To switch: prompt toggle
```

---

### `prompt toggle`

Interactive menu to switch between available engines.

**Behavior:**
1. Shows numbered list of alternatives (excludes current)
2. User selects by number
3. Validates engine installation
4. Switches and reloads shell

**Example Session:**

```bash
$ prompt toggle
Which prompt engine would you like to use?

1) starship
2) ohmyposh
#? 1
✓ Switched to Starship
Reloading shell...
```

---

### `prompt starship` / `prompt p10k` / `prompt ohmyposh`

Direct switch to a specific engine without interactive menu.

**Validation Steps:**
1. Checks if binary/plugin is installed
2. Checks if config file exists
3. Sets `FLOW_PROMPT_ENGINE` environment variable
4. Reloads shell (if interactive)

**Error Examples:**

```bash
# Missing binary
$ prompt starship
✗ Starship not found in PATH
Install with: brew install starship

# Missing config
$ prompt ohmyposh
⚠ OhMyPosh config missing at ~/.config/ohmyposh/config.json
```

---

### `prompt list`

Tabular view of all registered prompt engines.

**Output:**

```
ℹ Available Prompt Engines:

name               active     config file
─────────────────────────────────────────────────────────────
Powerlevel10k      ●          ~/.config/zsh/.p10k.zsh
Starship           ○          ~/.config/starship.toml
Oh My Posh         ○          ~/.config/ohmyposh/config.json

Legend: ● = current, ○ = available
```

---

### `prompt setup-ohmyposh`

Interactive wizard to configure Oh My Posh.

**Steps:**
1. Checks if `oh-my-posh` binary is installed
2. Creates `~/.config/ohmyposh/` directory
3. Generates default `config.json`
4. Provides next steps for customization

**Default Config Features:**
- Session segment (username)
- Path segment (folder style)
- Git segment (branch name)
- Powerline-style diamonds

---

### `prompt --dry-run`

Preview what a command would do without making changes.

**Examples:**

```bash
# Preview engine switch
$ prompt --dry-run starship

🔍 DRY RUN MODE - No changes will be made

Would perform the following actions:
  1. Set environment variable: FLOW_PROMPT_ENGINE="starship"
  2. Switch prompt engine to: Starship
  3. Reload shell with new configuration

Config file: ~/.config/starship.toml

To apply these changes, run:
  prompt starship
```

```bash
# Preview toggle menu
$ prompt --dry-run toggle

🔍 DRY RUN MODE - No changes will be made

Current engine: Powerlevel10k

Available alternatives to switch to:
  1) Starship
  2) Oh My Posh

To switch engines, run:
  prompt toggle
```

---

## Environment Variables

### `FLOW_PROMPT_ENGINE`

Controls which prompt engine is active.

**Valid Values:** `powerlevel10k`, `starship`, `ohmyposh`

**Default:** `powerlevel10k`

**Usage:**

```bash
# Check current
echo $FLOW_PROMPT_ENGINE

# Set manually (not recommended - use dispatcher)
export FLOW_PROMPT_ENGINE="starship"
```

**Where It's Set:**
- `~/.config/zsh/.zshenv` - persisted across sessions
- Set automatically by `prompt` dispatcher

---

## Installation Requirements

### Powerlevel10k

```bash
# Add to ~/.config/zsh/.zsh_plugins.txt:
romkatv/powerlevel10k

# Install
antidote install

# Configure (first run prompts wizard)
p10k configure
```

### Starship

```bash
# Install
brew install starship

# Create config
mkdir -p ~/.config
touch ~/.config/starship.toml

# Customize
nano ~/.config/starship.toml
```

### Oh My Posh

```bash
# Install
brew install oh-my-posh

# Use setup wizard
prompt setup-ohmyposh

# Or manually create config
mkdir -p ~/.config/ohmyposh
nano ~/.config/ohmyposh/config.json
```

---

## Integration with flow doctor

The `flow doctor` command checks prompt engine health:

```bash
$ flow doctor

🔍 Checking system health...

PROMPT ENGINES:
  ✓ Powerlevel10k installed (via antidote)
  ✓ Starship installed (v1.18.0)
  ○ Oh My Posh not installed

To install Oh My Posh:
  brew install oh-my-posh
  prompt setup-ohmyposh
```

---

## Troubleshooting

### Engine Not Found

**Problem:** `✗ Starship not found in PATH`

**Solution:**

```bash
brew install starship
```

### Config Missing

**Problem:** `⚠ OhMyPosh config missing`

**Solution:**

```bash
prompt setup-ohmyposh
# Or manually create
mkdir -p ~/.config/ohmyposh
nano ~/.config/ohmyposh/config.json
```

### Prompt Doesn't Change After Switch

**Problem:** Prompt looks the same after switching

**Solution:**

```bash
# Force shell reload
exec zsh -i

# Or start new terminal session
```

### Wrong Engine Loading on New Shell

**Problem:** Different engine loads than expected

**Solution:**

```bash
# Check what's set
echo $FLOW_PROMPT_ENGINE

# Verify .zshenv has the correct value
grep FLOW_PROMPT_ENGINE ~/.config/zsh/.zshenv
```

---

## Data Structures

### Engine Registry

The dispatcher maintains a registry of all engines:

```zsh
declare -gA PROMPT_ENGINES=(
    [powerlevel10k_name]="powerlevel10k"
    [powerlevel10k_display]="Powerlevel10k"
    [powerlevel10k_binary]="(antidote)"
    [powerlevel10k_config]="$HOME/.config/zsh/.p10k.zsh"
    [powerlevel10k_description]="Feature-rich, highly customizable"

    [starship_name]="starship"
    [starship_display]="Starship"
    [starship_binary]="starship"
    [starship_config]="$HOME/.config/starship.toml"
    [starship_description]="Minimal, fast Rust-based"

    [ohmyposh_name]="ohmyposh"
    [ohmyposh_display]="Oh My Posh"
    [ohmyposh_binary]="oh-my-posh"
    [ohmyposh_config]="$HOME/.config/ohmyposh/config.json"
    [ohmyposh_description]="Modular with extensive themes"
)
```

---

## Related Commands

| Command | Purpose |
|---------|---------|
| `flow doctor` | System health check (includes prompts) |
| `tm profile` | iTerm2 profile switching |
| `tm ghost theme` | Ghostty theme switching |

---

## Links

- 📖 [Quick Reference Card](PROMPT-DISPATCHER-REFCARD.md)
- 🔗 [Powerlevel10k](https://github.com/romkatv/powerlevel10k)
- 🔗 [Starship](https://starship.rs)
- 🔗 [Oh My Posh](https://ohmyposh.dev)
- 📚 [Flow-CLI Docs](https://data-wise.github.io/flow-cli/)

---

**Last Updated:** 2026-01-14
**Version:** 5.7.0
