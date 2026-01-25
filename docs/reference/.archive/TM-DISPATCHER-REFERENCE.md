# TM Dispatcher Reference

> **Terminal management with instant shell-native commands and aiterm integration**

**Location:** `lib/dispatchers/tm-dispatcher.zsh`

---

## Quick Start

```bash
tm                    # Show help
tm title "My Task"    # Set tab title (instant)
tm detect             # Detect project context
tm switch             # Apply context to terminal
```

---

## Usage

```bash
tm <command> [args]
```

### Key Insight

- Shell-native commands (`title`, `profile`, `var`, `which`) are **instant** - no Python overhead
- Complex operations delegate to **aiterm** Python CLI
- Works without aiterm installed (shell-native commands still work)

---

## Shell-Native Commands

These commands execute instantly using ZSH escape sequences:

| Command | Description | Notes |
|---------|-------------|-------|
| `tm title <text>` | Set tab/window title | Universal OSC 2 sequence |
| `tm profile <name>` | Switch iTerm2 profile | iTerm2 only |
| `tm var <key> <val>` | Set iTerm2 status bar variable | iTerm2 only |
| `tm which` | Show detected terminal | Returns: iterm2, ghostty, kitty, etc. |

### Examples

```bash
# Set descriptive title for current task
tm title "Working on auth feature"
tm t "Bug fix #123"                   # Shortcut

# Switch iTerm2 profile for visual context
tm profile "Coding Dark"
tm p "Default"                        # Shortcut

# Set status bar variable (iTerm2)
tm var task "Reviewing PR"
tm v project "flow-cli"               # Shortcut

# Check which terminal you're in
tm which                              # → iterm2, ghostty, etc.
tm w                                  # Shortcut
```

---

## Aiterm Delegation

These commands delegate to the aiterm Python CLI:

| Command | Description | Requires |
|---------|-------------|----------|
| `tm ghost` | Ghostty terminal status | aiterm ≥ 0.3.9 |
| `tm ghost theme` | List/set Ghostty themes | aiterm ≥ 0.3.9 |
| `tm ghost font` | Get/set Ghostty font | aiterm ≥ 0.3.9 |
| `tm switch` | Apply terminal context | aiterm |
| `tm detect` | Detect project context | aiterm |
| `tm doctor` | Check terminal health | aiterm |
| `tm compare` | Compare terminal features | aiterm ≥ 0.3.9 |
| `tm features` | Show terminal feature matrix | aiterm |
| `tm status` | Show terminal detection | aiterm |

### Ghostty Management

```bash
# Check Ghostty status
tm ghost

# List available themes
tm ghost theme

# Set theme
tm ghost theme tokyo-night

# Get current font
tm ghost font

# Set font
tm ghost font "JetBrains Mono"
```

### Context Detection

```bash
# Detect current project context
tm detect
# → Shows: terminal, project type, suggested profile

# Apply detected context
tm switch
# → Updates title, profile, and status bar
```

### Health Check

```bash
# Check terminal configuration
tm doctor
# → Validates: fonts, colors, integrations
```

---

## Shortcuts

| Full | Short | Description |
|------|-------|-------------|
| `title` | `t` | Set title |
| `profile` | `p` | Switch profile |
| `var` | `v` | Set variable |
| `which` | `w` | Detect terminal |
| `ghost` | `g` | Ghostty commands |
| `switch` | `s` | Apply context |
| `detect` | `d` | Detect context |

---

## Aliases

| Alias | Expands To | Description |
|-------|------------|-------------|
| `tmt` | `tm title` | Quick title set |
| `tmp` | `tm profile` | Quick profile switch |
| `tmv` | `tm var` | Quick variable set |
| `tmw` | `tm which` | Quick terminal detect |
| `tmg` | `tm ghost` | Ghostty commands |
| `tms` | `tm switch` | Apply context |
| `tmd` | `tm detect` | Detect context |

---

## Terminal Support

The dispatcher auto-detects these terminals:

| Terminal | Detection | Profiles | Themes | Title |
|----------|-----------|----------|--------|-------|
| **iTerm2** | `$TERM_PROGRAM` | ✅ | ✅ | ✅ |
| **Ghostty** | `$TERM_PROGRAM` | - | ✅ | ✅ |
| **WezTerm** | `$TERM_PROGRAM` | ✅ | ✅ | ✅ |
| **Kitty** | `$KITTY_WINDOW_ID` | - | ✅ | ✅ |
| **Alacritty** | `$ALACRITTY_WINDOW_ID` | - | ✅ | ✅ |
| **VS Code** | `$TERM_PROGRAM` | - | - | ✅ |
| **Terminal.app** | `$TERM_PROGRAM` | - | - | ✅ |

---

## Requirements

### Required (for full features)

- **aiterm** - Terminal optimization CLI

  ```bash
  brew install data-wise/tap/aiterm  # macOS
  pip install aiterm-dev              # Cross-platform
  ```

### Optional (shell-native commands work without aiterm)

Shell-native commands (`title`, `profile`, `var`, `which`) work without aiterm installed.

---

## Examples

### Daily Workflow

```bash
# Start of session - set context
tm detect                    # See what context is detected
tm switch                    # Apply it

# Working on a feature
tm title "feature/auth"      # Set descriptive title
tm profile "Coding"          # Switch to coding profile

# Quick terminal check
tm which                     # → iterm2
```

### Ghostty Users

```bash
# Browse available themes
tm ghost theme

# Try a theme
tm ghost theme catppuccin-mocha

# Check font settings
tm ghost font
```

### Debugging

```bash
# Check terminal health
tm doctor

# Compare terminal features
tm compare
```

---

## Configuration

### Auto-Switch on Directory Change

Enable automatic context switching when changing directories:

```bash
export TM_AUTO_SWITCH=1
```

When enabled, `tm switch --quiet` runs after each `cd`.

---

## Integration

- **flow-cli** - Integrated as the `tm` dispatcher
- **aiterm** - Python CLI for rich terminal features
- **pick** - Works with project picker for context

### Related Commands

| Command | Purpose |
|---------|---------|
| `work <project>` | Start session (calls tm switch) |
| `finish` | End session |
| `dash` | Dashboard |

---

## Troubleshooting

### aiterm not found

```bash
# Check if installed
command -v ait

# Install
brew install data-wise/tap/aiterm
# or
pip install aiterm-dev
```

### Ghostty commands not working

```bash
# Check aiterm version
ait --version

# Ghostty support requires >= 0.3.9
brew upgrade aiterm
```

### Profile switching not working

- Profile switching only works in **iTerm2**
- Ghostty uses themes instead: `tm ghost theme <name>`

---

## See Also

- **Command:** [work](../commands/work.md) - Start sessions with terminal context
- **Reference:** [Dispatcher Reference](DISPATCHER-REFERENCE.md) - All dispatchers
- **External:** [aiterm Documentation](https://github.com/Data-Wise/aiterm) - Full aiterm feature guide
- **External:** [aiterm on PyPI](https://pypi.org/project/aiterm-dev/) - Install via pip

---

**Last Updated:** 2026-01-07
**Version:** v4.8.0
**Status:** ✅ Production ready with shell-native commands
