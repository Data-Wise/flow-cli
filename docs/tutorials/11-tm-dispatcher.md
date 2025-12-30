# Tutorial: Terminal Management with TM Dispatcher

> **What you'll learn:** Control your terminal appearance and context with instant shell commands
>
> **Time:** ~10 minutes | **Level:** Beginner
> **Version:** v4.4.0+

---

## Prerequisites

Before starting, you should:

- [ ] Have flow-cli installed and sourced
- [ ] Be using a supported terminal (iTerm2, Ghostty, Kitty, etc.)
- [ ] Optionally have aiterm installed for advanced features

**Verify your setup:**

```bash
# Check tm dispatcher is available
tm help

# Check which terminal you're using
tm which
```

---

## What You'll Learn

By the end of this tutorial, you will:

1. Set descriptive tab/window titles
2. Switch iTerm2 profiles for visual context
3. Detect and apply project context
4. Manage Ghostty themes (if using Ghostty)
5. Use aliases for faster access

---

## Part 1: Shell-Native Commands (No Dependencies)

These commands work instantly without aiterm installed.

### Step 1.1: Setting Tab Titles

Give your terminal tabs meaningful names:

```bash
# Set a descriptive title
tm title "Working on auth feature"

# Shorter syntax
tm t "Bug fix #123"

# Using the alias
tmt "Code review"
```

**What happens:**
- Your tab/window title updates immediately
- Uses universal OSC 2 escape sequence
- Works in all terminals

**Try it now:**

```bash
tm title "Tutorial in progress"
```

Look at your terminal tab - it should show "Tutorial in progress"!

### Step 1.2: Switching iTerm2 Profiles (iTerm2 Only)

Change your terminal's visual appearance:

```bash
# Switch to a different profile
tm profile "Coding Dark"

# Back to default
tm profile "Default"

# Using shortcut
tm p "Writing"
```

**What happens:**
- Colors, fonts, and settings change instantly
- Profile must exist in iTerm2 preferences
- Only works in iTerm2

### Step 1.3: Detecting Your Terminal

Find out which terminal you're running:

```bash
tm which
# → iterm2, ghostty, kitty, alacritty, wezterm, vscode, or terminal
```

This is useful for:
- Debugging terminal-specific issues
- Conditional scripts based on terminal

---

## Part 2: Context-Aware Features (Requires aiterm)

These features require aiterm for intelligent context detection.

### Step 2.1: Installing aiterm

If you haven't installed aiterm yet:

```bash
# macOS (recommended)
brew install data-wise/tap/aiterm

# Or via pip
pip install aiterm-dev
```

Verify installation:

```bash
ait --version
```

### Step 2.2: Detecting Project Context

Let aiterm analyze your current directory:

```bash
tm detect
```

**Sample output:**
```
Terminal: iTerm2
Project: flow-cli (zsh)
Suggested: Coding profile, "flow-cli" title
```

### Step 2.3: Applying Context Automatically

Apply the detected context to your terminal:

```bash
tm switch
```

**What happens:**
- Sets appropriate title based on project
- Switches to matching profile (if available)
- Updates status bar variables

### Step 2.4: Quick Workflow

Combine detection and switching:

```bash
# Start of work session
cd ~/projects/my-project
tm switch     # Apply context

# Or use the alias
tms
```

---

## Part 3: Ghostty Theme Management

If you're using Ghostty terminal:

### Step 3.1: List Available Themes

```bash
tm ghost theme
```

Shows all 14+ built-in Ghostty themes.

### Step 3.2: Apply a Theme

```bash
# Try different themes
tm ghost theme tokyo-night
tm ghost theme catppuccin-mocha
tm ghost theme dracula
```

### Step 3.3: Check Current Font

```bash
tm ghost font
```

### Step 3.4: Set Font

```bash
tm ghost font "JetBrains Mono"
```

---

## Part 4: Using Aliases

Speed up your workflow with built-in aliases:

| Alias | Command | Use For |
|-------|---------|---------|
| `tmt` | `tm title` | Quick title changes |
| `tmp` | `tm profile` | Profile switching |
| `tmg` | `tm ghost` | Ghostty commands |
| `tms` | `tm switch` | Apply context |
| `tmd` | `tm detect` | Check context |

**Examples:**

```bash
# Quick title
tmt "Feature branch"

# Quick profile switch
tmp "Default"

# Quick context apply
tms
```

---

## Part 5: Practical Workflows

### Workflow 1: Starting a Work Session

```bash
# Navigate to project
cd ~/projects/flow-cli

# Set context
tm switch

# Or manually set title
tm title "flow-cli: adding tm dispatcher"
```

### Workflow 2: Multiple Tabs

When working with multiple terminal tabs:

```bash
# Tab 1: Main development
tm title "flow-cli: main"

# Tab 2: Tests
tm title "flow-cli: tests"

# Tab 3: Docs
tm title "flow-cli: docs"
```

Now you can easily identify each tab!

### Workflow 3: Visual Mode Switching

For iTerm2 users with custom profiles:

```bash
# Coding mode (dark theme)
tm profile "Coding Dark"

# Writing mode (light theme)
tm profile "Writing Light"

# Review mode
tm profile "Review"
```

---

## Troubleshooting

### "aiterm not installed"

Shell-native commands still work. For full features:

```bash
brew install data-wise/tap/aiterm
```

### Profile switching not working

- Only works in iTerm2
- Profile name must match exactly (case-sensitive)
- Check iTerm2 Preferences → Profiles

### Ghostty commands fail

Ghostty support requires aiterm >= 0.3.9:

```bash
brew upgrade aiterm
```

---

## Summary

You've learned to:

| Task | Command |
|------|---------|
| Set tab title | `tm title "text"` or `tmt "text"` |
| Switch profile | `tm profile "name"` or `tmp "name"` |
| Check terminal | `tm which` or `tmw` |
| Detect context | `tm detect` or `tmd` |
| Apply context | `tm switch` or `tms` |
| Ghostty themes | `tm ghost theme [name]` |

---

## Next Steps

- **Explore aiterm features:** `ait --help`
- **Set up auto-switching:** `export TM_AUTO_SWITCH=1`
- **Customize iTerm2 profiles** for different project types
- **Read the reference:** [TM-DISPATCHER-REFERENCE.md](../reference/TM-DISPATCHER-REFERENCE.md)

---

**Congratulations!** You've mastered terminal management with the tm dispatcher.
