# Prompt Dispatcher Guide

**Available Since:** v5.7.0
**Status:** Production Ready
**Last Updated:** 2026-01-14

## Overview

The prompt dispatcher (`prompt`) provides unified control over three prompt engines: **Powerlevel10k**, **Starship**, and **Oh My Posh**. Manage your shell prompt with a single command interface.

```bash
prompt status        # See what's active
prompt toggle        # Switch to another engine (interactive)
prompt starship      # Force switch to Starship
prompt list          # List all available engines
```

## Quick Start

### Check Current Prompt

```bash
$ prompt status

Prompt Engines:

  ● Powerlevel10k (current)
    Feature-rich, highly customizable prompt engine
    Config: ~/.config/zsh/.p10k.zsh

  ○ Starship
    Minimal, fast Rust-based prompt engine
    Config: ~/.config/starship.toml

  ○ Oh My Posh
    Modular prompt engine with extensive themes
    Config: ~/.config/ohmyposh/config.json

To switch: prompt toggle
```

### Switch Engines Interactively

```bash
$ prompt toggle

Which prompt engine would you like to use?
1) starship
2) ohmyposh
3) powerlevel10k
#? 1
✅ Switched to Starship
```

### Switch Directly

```bash
$ prompt starship
✅ Switched to Starship

$ prompt p10k
✅ Switched to Powerlevel10k

$ prompt ohmyposh
✅ Switched to Oh My Posh
```

## Commands

### `prompt status` - Show Current Engine

Displays which engine is currently active and what alternatives are available.

```bash
$ prompt status
```

**Output:**
- Current engine marked with `●` (bullet)
- Available alternatives marked with `○` (circle)
- Configuration file path for each engine
- Brief description of each engine

### `prompt toggle` - Interactive Menu

Shows a menu to select a different prompt engine. Best for comparing options.

```bash
$ prompt toggle
```

**Behavior:**
- Shows all available engines except the current one
- Uses shell `select` builtin for familiar interface
- Validates selection before switching
- Reloads shell with new prompt

### `prompt starship` - Switch to Starship

Force-switch to Starship without menu.

```bash
$ prompt starship
```

**Requirements:**
- Starship binary installed (`brew install starship`)
- Config file at `~/.config/starship.toml`

**Error Examples:**
```bash
$ prompt starship
❌ Starship not found in PATH

Install with: brew install starship
```

### `prompt p10k` - Switch to Powerlevel10k

Force-switch to Powerlevel10k without menu.

```bash
$ prompt p10k
```

**Requirements:**
- Powerlevel10k plugin in `.zsh_plugins.txt`
- Config file at `~/.config/zsh/.p10k.zsh`

### `prompt ohmyposh` - Switch to Oh My Posh

Force-switch to Oh My Posh without menu.

```bash
$ prompt ohmyposh
```

**Requirements:**
- Oh My Posh binary installed (`brew install oh-my-posh`)
- Config file at `~/.config/ohmyposh/config.json`

### `prompt list` - Show All Engines

Display a table of all available engines with status and config paths.

```bash
$ prompt list

Available Prompt Engines:

name           active     config file
────────────────────────────────────────────────────
Powerlevel10k  ●          ~/.config/zsh/.p10k.zsh
Starship       ○          ~/.config/starship.toml
Oh My Posh     ○          ~/.config/ohmyposh/config.json

Legend: ● = current, ○ = available
```

### `prompt setup-ohmyposh` - Configure Oh My Posh

Interactive wizard for setting up Oh My Posh for the first time.

```bash
$ prompt setup-ohmyposh
```

**What it does:**
1. Checks if Oh My Posh is installed
2. Creates `~/.config/ohmyposh/` directory if needed
3. Creates default `config.json` with sensible defaults
4. Shows next steps for customization

**Next Steps After Setup:**
```bash
# Customize your configuration
nano ~/.config/ohmyposh/config.json

# Validate the configuration
oh-my-posh config

# Switch to Oh My Posh
prompt ohmyposh
```

### `prompt help` - Show Help

Display complete command reference.

```bash
$ prompt help
```

Shows all subcommands, examples, and links to full documentation.

## Environment Variables

### `FLOW_PROMPT_ENGINE`

The currently active prompt engine. Set automatically when you switch engines.

**Valid Values:**
- `powerlevel10k` - Powerlevel10k (default)
- `starship` - Starship
- `ohmyposh` - Oh My Posh

**Usage:**
```bash
# See current engine
echo $FLOW_PROMPT_ENGINE

# Override in .zshrc (before flow-cli loads)
export FLOW_PROMPT_ENGINE="starship"
```

## Setup by Engine

### Powerlevel10k

Assuming you use the recommended `antidote` plugin manager:

**1. Install via antidote:**
```bash
# Add to ~/.config/zsh/.zsh_plugins.txt
romkatv/powerlevel10k

# Load plugins
antidote install
```

**2. Configure:**
On first load, Powerlevel10k shows a configuration wizard. Or:
```bash
p10k configure
```

**3. Verify:**
```bash
prompt status
```

**4. Switch to it:**
```bash
prompt p10k
```

### Starship

Starship is a minimal, language-agnostic prompt engine.

**1. Install:**
```bash
brew install starship
```

**2. Create basic config:**
```bash
mkdir -p ~/.config
starship config  # Validates existing config
```

Starship provides a default configuration if none exists.

**3. Customize (optional):**
```bash
nano ~/.config/starship.toml
```

**4. Switch to it:**
```bash
prompt starship
```

### Oh My Posh

Oh My Posh provides extensive themes and customization.

**1. Install:**
```bash
brew install oh-my-posh
```

**2. Use setup wizard:**
```bash
prompt setup-ohmyposh
```

This creates `~/.config/ohmyposh/config.json` with defaults.

**3. Customize (optional):**
```bash
nano ~/.config/ohmyposh/config.json
oh-my-posh config  # Validate
```

**4. Switch to it:**
```bash
prompt ohmyposh
```

## Troubleshooting

### "Engine not found in PATH"

Example:
```
❌ Starship not found in PATH
Install with: brew install starship
```

**Solution:**
```bash
brew install starship
# Restart shell
exec zsh
```

### "Config missing"

Example:
```
⚠️  OhMyPosh config missing at ~/.config/ohmyposh/config.json
```

**Solution:**
```bash
prompt setup-ohmyposh
# Or manually create the config
```

### Prompt doesn't change after switching

**Causes:**
1. Shell hasn't reloaded yet
2. `.zshrc` doesn't check `FLOW_PROMPT_ENGINE`

**Solution:**
```bash
# Reload shell manually
exec zsh -i
```

### Antidote not finding Powerlevel10k

**Check:**
```bash
grep powerlevel10k ~/.config/zsh/.zsh_plugins.txt
```

**Solution:**
Add to `.zsh_plugins.txt`:
```
romkatv/powerlevel10k
```

Then reload antidote:
```bash
antidote install
exec zsh
```

## Performance Tips

### Starship

Starship is the fastest option - optimized for shell startup speed.

```bash
prompt starship
```

### Powerlevel10k

Very fast with instant prompt feature. Configure for your system:

```bash
p10k configure
```

### Oh My Posh

Performance depends on configuration. For best speed:
- Keep module count minimal
- Avoid expensive git operations
- Use simple themes

## Customization

### Powerlevel10k

```bash
p10k configure
```

Interactive configuration wizard with many options.

### Starship

Edit `~/.config/starship.toml`:

```toml
# Example: add Python version
[python]
symbol = "🐍"

# Example: customize git branch
[git_branch]
symbol = "🌿"
```

### Oh My Posh

Edit `~/.config/ohmyposh/config.json`:

```json
{
  "profiles": [
    {
      "name": "default",
      "template": "...",
      "segments": [...]
    }
  ]
}
```

## Integration with flow-cli

The prompt dispatcher integrates with `flow doctor` for diagnostics:

```bash
flow doctor
```

Checks all prompt engines for:
- Installation status
- Configuration files
- Current active engine
- Validity of settings

## Common Workflows

### Daily Development (Starship)

Fast and minimal - great for speed:

```bash
prompt starship
```

### Feature Development (Powerlevel10k)

Rich information and customizable:

```bash
prompt p10k
```

### Theme Exploration (Oh My Posh)

Extensive themes and modular:

```bash
prompt ohmyposh
```

### Test All Engines

```bash
prompt status    # Check current
prompt toggle    # Try different one
prompt p10k      # Try p10k
prompt list      # See all
```

## Next Steps

- **Customize your engine:** See setup section above
- **Explore themes:** Each engine has many theme options
- **Integrate with flow-cli:** Use `work` command for project-specific prompts
- **Performance tuning:** Check each engine's documentation

## More Information

- **Powerlevel10k:** https://github.com/romkatv/powerlevel10k
- **Starship:** https://starship.rs
- **Oh My Posh:** https://ohmyposh.dev
- **Flow-CLI:** https://data-wise.github.io/flow-cli/

