# Flow-CLI Demos

This directory contains interactive demos and walkthroughs for flow-cli features.

## Available Demos

### Teaching Workflow Demo

**File:** `teaching-workflow.tape`
**Tool:** VHS (https://github.com/charmbracelet/vhs)
**Duration:** ~60 seconds
**Output:** `teaching-workflow.gif`

**What it demonstrates:**
1. Initialize teaching workflow with `teach-init`
2. Branch safety warning when on production
3. Teaching-aware `work` session
4. Fast deployment with `quick-deploy.sh`
5. Configuration review

**Generate the GIF:**

```bash
# Install VHS (if not installed)
brew install vhs

# Generate demo
cd docs/demos
vhs teaching-workflow.tape

# Output: teaching-workflow.gif
```

**Use in documentation:**

```markdown
![Teaching Workflow Demo](../demos/teaching-workflow.gif)
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
- [ ] Secret management (dot workflow)
- [ ] R package development flow
- [ ] Git worktree management

---

## See Also

- [VHS Documentation](https://github.com/charmbracelet/vhs)
- [Teaching Workflow Guide](../guides/TEACHING-WORKFLOW.md)
- [Quick Reference Cards](../reference/)
