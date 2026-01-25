# Tutorial: Prompt Dispatcher - Manage Your Shell Prompt

**Level:** Beginner
**Time:** 15 minutes
**Prerequisites:** At least one prompt engine installed

---

## What You'll Learn

By the end of this tutorial, you'll know how to:

- ✅ Check which prompt engine is currently active
- ✅ Switch between prompt engines instantly
- ✅ Use the interactive toggle menu
- ✅ Preview changes with dry-run mode
- ✅ Set up Oh My Posh from scratch
- ✅ Troubleshoot common prompt issues

---

## Prerequisites

You need at least one of these prompt engines installed:

```bash
# Option 1: Powerlevel10k (via ZSH plugin manager)
# Add to ~/.config/zsh/.zsh_plugins.txt:
romkatv/powerlevel10k

# Option 2: Starship
brew install starship

# Option 3: Oh My Posh
brew install oh-my-posh
```

---

## Part 1: Getting Started

### Understanding the Prompt Dispatcher

The `prompt` dispatcher lets you:

- **Switch prompt engines** - Change from Powerlevel10k to Starship to Oh My Posh
- **Preview changes** - See what will happen before committing
- **Set up new engines** - Guided wizard for Oh My Posh

### Check Your Current Status

```bash
prompt status
```

**Example output:**

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

The `●` indicates your current engine; `○` shows available alternatives.

---

## Part 2: Switching Prompt Engines

### Method 1: Interactive Menu

The easiest way to switch is using the toggle command:

```bash
prompt toggle
```

**You'll see:**

```
Which prompt engine would you like to use?

1) starship
2) ohmyposh
#?
```

Enter the number of your choice and press Enter. The shell will reload automatically.

### Method 2: Direct Switch

If you know which engine you want, switch directly:

```bash
# Switch to Starship
prompt starship

# Switch to Powerlevel10k
prompt p10k

# Switch to Oh My Posh
prompt ohmyposh
```

**Output:**

```
✓ Switched to Starship
Reloading shell...
```

---

## Part 3: Preview Before Switching

### Using Dry-Run Mode

Not sure what will happen? Preview first:

```bash
prompt --dry-run starship
```

**Output:**

```
🔍 DRY RUN MODE - No changes will be made

Would perform the following actions:
  1. Set environment variable: FLOW_PROMPT_ENGINE="starship"
  2. Switch prompt engine to: Starship
  3. Reload shell with new configuration

Config file: ~/.config/starship.toml

To apply these changes, run:
  prompt starship
```

### Preview Toggle Options

```bash
prompt --dry-run toggle
```

**Output:**

```
🔍 DRY RUN MODE - No changes will be made

Current engine: Powerlevel10k

Available alternatives to switch to:
  1) Starship
  2) Oh My Posh

To switch engines, run:
  prompt toggle
```

---

## Part 4: Setting Up Oh My Posh

If you haven't configured Oh My Posh yet, use the setup wizard:

### Step 1: Run the Setup Wizard

```bash
prompt setup-ohmyposh
```

**Output:**

```
ℹ Oh My Posh Configuration Wizard

✓ Created ~/.config/ohmyposh
✓ Configuration created at ~/.config/ohmyposh/config.json

Next steps:
  1. Customize your config: nano ~/.config/ohmyposh/config.json
  2. Validate: oh-my-posh config
  3. Switch to OhMyPosh: prompt ohmyposh
```

### Step 2: Switch to Oh My Posh

```bash
prompt ohmyposh
```

### Step 3: Customize (Optional)

Edit the config file to customize your prompt:

```bash
nano ~/.config/ohmyposh/config.json
```

Or browse the [Oh My Posh themes](https://ohmyposh.dev/docs/themes) for inspiration.

---

## Part 5: Viewing All Engines

### Table View

Get a tabular overview of all engines:

```bash
prompt list
```

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

## Part 6: Troubleshooting

### Engine Not Found

**Problem:**

```
✗ Starship not found in PATH
Install with: brew install starship
```

**Solution:**

```bash
brew install starship
```

### Config Missing

**Problem:**

```
⚠ OhMyPosh config missing at ~/.config/ohmyposh/config.json
```

**Solution:**

```bash
prompt setup-ohmyposh
```

### Prompt Doesn't Change After Switch

**Problem:** You switched but the prompt looks the same.

**Solution:** Force a shell reload:

```bash
exec zsh -i
```

Or simply open a new terminal tab.

### Check What's Set

```bash
echo $FLOW_PROMPT_ENGINE
```

This should show `powerlevel10k`, `starship`, or `ohmyposh`.

---

## Quick Reference

| Task | Command |
|------|---------|
| See current engine | `prompt status` |
| Switch interactively | `prompt toggle` |
| Switch to Starship | `prompt starship` |
| Switch to Powerlevel10k | `prompt p10k` |
| Switch to Oh My Posh | `prompt ohmyposh` |
| Preview a switch | `prompt --dry-run <engine>` |
| Set up Oh My Posh | `prompt setup-ohmyposh` |
| List all engines | `prompt list` |
| Show help | `prompt help` |

---

## Engine Comparison

| Feature | Powerlevel10k | Starship | Oh My Posh |
|---------|---------------|----------|-----------|
| **Speed** | ⚡⚡⚡ Very fast | ⚡⚡⚡⚡ Fastest | ⚡⚡ Fast |
| **Customization** | Excellent | Good | Extensive |
| **Themes** | Many built-in | Many presets | 100+ official |
| **Config Format** | ZSH script | TOML | JSON/YAML |
| **Best For** | Feature-rich | Speed-focused | Theme exploration |

---

## What's Next?

Now that you can manage your prompt engine, try:

1. **Experiment** - Try each engine for a day
2. **Customize** - Edit the config files to match your style
3. **Check health** - Run `flow doctor` to verify prompt setup

---

## See Also

- [Prompt Dispatcher Reference](../reference/.archive/PROMPT-DISPATCHER-REFERENCE.md) - Full command reference
- [Prompt Quick Reference Card](../reference/.archive/PROMPT-DISPATCHER-REFCARD.md) - Quick lookup
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - P10k documentation
- [Starship](https://starship.rs) - Starship documentation
- [Oh My Posh](https://ohmyposh.dev) - Oh My Posh documentation

---

**Congratulations!** You can now manage your shell prompt like a pro. 🎨
