# Prompt Dispatcher - Quick Reference Card

## Commands at a Glance

| Command | Purpose | Example |
|---------|---------|---------|
| `prompt status` | Show current + alternatives | `prompt status` |
| `prompt toggle` | Choose from interactive menu | `prompt toggle` |
| `prompt starship` | Switch to Starship | `prompt starship` |
| `prompt p10k` | Switch to Powerlevel10k | `prompt p10k` |
| `prompt ohmyposh` | Switch to Oh My Posh | `prompt ohmyposh` |
| `prompt list` | Show all engines in table | `prompt list` |
| `prompt setup-ohmyposh` | Configure Oh My Posh | `prompt setup-ohmyposh` |
| `prompt help` | Show full help | `prompt help` |

## Engine Comparison

| Feature | Powerlevel10k | Starship | Oh My Posh |
|---------|---------------|----------|-----------|
| **Installation** | Via antidote plugin | `brew install` | `brew install` |
| **Speed** | ⚡⚡⚡ Very fast | ⚡⚡⚡⚡ Fastest | ⚡⚡ Fast |
| **Customization** | ⭐⭐⭐ Excellent | ⭐⭐ Good | ⭐⭐⭐⭐ Most |
| **Config Format** | `.p10k.zsh` | `starship.toml` | `config.json` |
| **Visual Themes** | Many | Many | 100+ official |
| **Best For** | Feature-rich systems | Speed-focused | Theme exploration |

## Configuration Paths

```
Powerlevel10k → ~/.config/zsh/.p10k.zsh
Starship      → ~/.config/starship.toml
Oh My Posh    → ~/.config/ohmyposh/config.json
```

## Status Indicators

| Symbol | Meaning |
|--------|---------|
| `●` | Current engine |
| `○` | Available engine |
| `✅` | Success |
| `❌` | Error |
| `⚠️` | Warning |

## Environment Variable

```bash
# View current engine
echo $FLOW_PROMPT_ENGINE

# Valid values: powerlevel10k, starship, ohmyposh
export FLOW_PROMPT_ENGINE="starship"
```

## Typical Workflows

### Switch Engines

```bash
prompt toggle       # Interactive
prompt starship     # Direct to Starship
```

### First-Time Setup

```bash
prompt setup-ohmyposh    # Setup Oh My Posh
prompt status            # Verify it worked
prompt ohmyposh          # Switch to it
```

### Diagnostics

```bash
prompt list              # See all engines
prompt status            # See current
flow doctor              # Check health
```

## Installation Checklist

### For Powerlevel10k

```bash
☐ Add to ~/.config/zsh/.zsh_plugins.txt:
    romkatv/powerlevel10k
☐ Run: antidote install
☐ Restart shell: exec zsh
☐ Run: prompt p10k
```

### For Starship

```bash
☐ Install: brew install starship
☐ Create config: mkdir -p ~/.config
☐ Run: prompt starship
☐ Customize: nano ~/.config/starship.toml
```

### For Oh My Posh

```bash
☐ Install: brew install oh-my-posh
☐ Setup config: prompt setup-ohmyposh
☐ Run: prompt ohmyposh
☐ Customize: nano ~/.config/ohmyposh/config.json
```

## Troubleshooting Cheat Sheet

| Problem | Solution |
|---------|----------|
| "Engine not found" | `brew install <engine>` |
| "Config missing" | `prompt setup-ohmyposh` or create manually |
| Prompt doesn't change | `exec zsh -i` to reload shell |
| Want to see what's available | `prompt list` |
| Need help | `prompt help` |

## Related Commands

```bash
flow doctor              # Check all system health (includes prompts)
work <project>           # Start session in project
pick prompt              # Jump to prompt project (if working on it)
```

## Links

- 📖 Full Guide: `/docs/guides/PROMPT-DISPATCHER-GUIDE.md`
- 🔗 Powerlevel10k: https://github.com/romkatv/powerlevel10k
- 🔗 Starship: https://starship.rs
- 🔗 Oh My Posh: https://ohmyposh.dev
- 📚 Flow-CLI Docs: https://data-wise.github.io/flow-cli/

