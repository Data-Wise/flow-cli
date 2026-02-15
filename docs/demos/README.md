# Flow-CLI Demos

This directory contains interactive demos and walkthroughs for flow-cli features.

## Available Demos

### Dispatcher Demos

Quick demonstrations of flow-cli's smart dispatchers:

#### Claude Code Dispatcher (`cc`)

![CC Dispatcher Demo](cc-dispatcher.gif)

**File:** `cc-dispatcher.tape`
**Duration:** ~30 seconds

**Demonstrates:**
- `cc` - Launch Claude Code in current directory
- `cc pick` - Interactive project picker
- `cc yolo` - Quick launch in new window

#### Dopamine Features

![Dopamine Features Demo](dopamine-features.gif)

**File:** `dopamine-features.tape`
**Duration:** ~45 seconds

**Demonstrates:**
- `win` - Log accomplishments (auto-categorized)
- `yay` - View recent wins
- `yay --week` - Weekly summary with graph
- `flow goal` - Daily goal progress

#### DOT Dispatcher

![DOT Dispatcher Demo](dot-dispatcher.gif)

**File:** `dot-dispatcher.tape`
**Duration:** ~40 seconds

**Demonstrates:**
- `dots edit` - Quick dotfile editing
- `sec secret` - macOS Keychain secret management
- `dots sync` - Sync dotfiles across machines

#### First Session

![First Session Demo](first-session.gif)

**File:** `first-session.tape`
**Duration:** ~35 seconds

**Demonstrates:**
- Initial setup and welcome
- Project detection
- Quick commands overview

### Teaching Workflow Demo

![Teaching Workflow Demo](teaching-workflow.gif)

**File:** `teaching-workflow.tape`
**Duration:** ~60 seconds

**Demonstrates:**
1. Initialize teaching workflow with `teach init`
2. Branch safety warning when on production
3. Teaching-aware `work` session
4. Fast deployment with `teach deploy`
5. Configuration review

### Tutorial Demos

For comprehensive tutorial GIFs, see:
- [Teaching v3.0 Tutorial GIFs](tutorials/TEACHING-V3-GIFS-README.md) - 6 teaching workflow demos
- [Token Automation Tutorial GIFs](tutorials/) - 4 token automation demos
- [Teaching Dates Tutorial GIFs](tutorials/) - 3 dates automation demos

---

## Generating Demos

### Prerequisites

```bash
# Install VHS (if not installed)
brew install vhs

# Optional: Install gifsicle for optimization
brew install gifsicle
```

### Generate a Single Demo

```bash
cd docs/demos
vhs teaching-workflow.tape

# Output: teaching-workflow.gif
```

### Optimize GIFs

```bash
# Optimize with gifsicle (-O3 for maximum compression)
gifsicle -O3 teaching-workflow.gif -o teaching-workflow.gif

# Typical reduction: 10-20% file size
```

---

## Creating New Demos

### VHS Tape Format

```tape
# Demo Title
# Description

Output demo-name.gif

Set Shell zsh
Set FontSize 14
Set Width 1200
Set Height 700
Set Theme "Catppuccin Mocha"

# Commands
Type "command here"
Sleep 500ms
Enter
```

### Best Practices

1. **Keep it short** - 30-90 seconds max
2. **Clear narration** - Comment each scene
3. **Realistic timing** - Add appropriate sleeps
4. **Clean output** - Use `clear` between scenes
5. **Show success** - Demonstrate working feature

### Useful VHS Commands

| Command | Purpose |
|---------|---------|
| `Type "text"` | Type command/text |
| `Enter` | Press Enter |
| `Sleep 500ms` | Pause for 500ms |
| `Ctrl+C` | Send Ctrl+C |
| `Set Shell zsh` | Use ZSH shell |
| `Output file.gif` | Output filename |

---

## Demo Ideas (Future)

- [ ] Project picker workflow
- [ ] Dash command showcase
- [ ] MCP dispatcher demo
- [ ] Secret management (sec workflow)
- [ ] R package development flow
- [ ] Git worktree management

---

## See Also

- [VHS Documentation](https://github.com/charmbracelet/vhs)
- [Teaching Workflow Guide](../guides/TEACHING-WORKFLOW.md)
- [Quick Reference Cards](../reference/)
