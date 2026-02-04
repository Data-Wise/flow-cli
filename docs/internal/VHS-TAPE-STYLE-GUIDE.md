# VHS Tape Style Guide

**Version:** 1.0.0
**Last Updated:** 2026-01-29
**For:** flow-cli Teaching Workflow GIF Documentation

---

## Overview

This guide establishes quality standards for creating VHS tape files that generate high-quality, readable, and error-free GIFs for flow-cli documentation.

**Why These Standards Matter:**
- Ensures readability on all display types (4K, Retina, mobile)
- Prevents ZSH syntax errors when users copy-paste commands
- Maintains consistent visual appearance across documentation
- Enables automated quality validation

---

## Quick Reference

| Setting | Teaching Tutorials | Dispatcher Demos | Notes |
|---------|-------------------|------------------|-------|
| **FontSize** | 18px (minimum) | 18px (recommended) | Never use < 16px |
| **Width** | 1400 | 1200 | Consistent per category |
| **Height** | 900 | 800 | Consistent per category |
| **Shell** | zsh | zsh | Always specify |
| **Comment Syntax** | `Type "echo '...'"` | `Type "echo '...'"` | Never `Type "#..."` |

---

## Standard Templates

### Teaching Tutorial Template

Use this for all `tutorial-*.tape` files:

```bash
# VHS Demo: <Feature Name>
# Part of flow-cli Teaching Workflow v3.0
# Tutorial: <Brief Description>

Output tutorial-<name>.gif

Require echo

Set Shell zsh
Set FontSize 18          # REQUIRED: Minimum 18px for readability
Set Width 1400           # Standard for teaching tutorials
Set Height 900           # Standard for teaching tutorials
Set TypingSpeed 50ms     # Comfortable pace
Set PlaybackSpeed 0.8    # Slightly slower for clarity
Set Theme "Catppuccin Mocha"

Hide
# Source flow-cli to load latest version
Type "source ~/projects/dev-tools/flow-cli/flow.plugin.zsh" Enter
Sleep 1s
Type "cd ~/projects/teaching/scholar-demo-course" Enter
Sleep 500ms
Type "clear" Enter
Show

# Use echo for all titles and comments (CRITICAL)
Type "echo 'Teaching Workflow v3.0: <Feature>'" Enter
Sleep 1s

# Your demo commands here...

# Cleanup
Type "echo '✓ Demo complete!'" Enter
Sleep 2s
```

### Dispatcher Demo Template

Use this for dispatcher demonstrations (`cc-dispatcher.tape`, `dot-dispatcher.tape`, etc.):

```bash
# VHS Demo: <Dispatcher Name>
# Part of flow-cli v5.x

Output <dispatcher>-demo.gif

Set Shell zsh
Set FontSize 18          # Minimum 18px for dispatchers
Set Width 1200           # Standard for dispatcher demos
Set Height 800           # Standard for dispatcher demos
Set TypingSpeed 50ms
Set PlaybackSpeed 0.8
Set Theme "Catppuccin Mocha"

# Source flow-cli
Hide
Type "source ~/projects/dev-tools/flow-cli/flow.plugin.zsh" Enter
Sleep 1s
Type "clear" Enter
Show

# Use echo for titles
Type "echo '<Dispatcher> Demo'" Enter
Sleep 1s

# Your demo commands here...
```

---

## Critical Guidelines

### 1. Font Size Requirements

**Minimum font size: 18px for ALL teaching-related GIFs**

#### Why 18px?

| Display Type | Resolution | 18px Readability |
|--------------|------------|------------------|
| 4K Monitor | 3840×2160 | ✅ Optimal |
| Retina Laptop | 2880×1800 | ✅ Optimal |
| Standard Laptop | 1920×1080 | ✅ Good |
| Mobile Device | Variable | ✅ Readable |

**Never use:**
- ❌ 14px (too small on all displays)
- ❌ 16px (borderline, only for non-teaching content)

### 2. Comment Syntax (CRITICAL)

**Problem:** Using `Type "# Comment"` causes ZSH to interpret `#` as a command, generating errors.

**❌ WRONG:**
```bash
Type "# Phase 1: Smart Post-Generation" Enter
Type "#   1) Review in editor, then commit" Enter
```

**✅ CORRECT:**
```bash
Type "echo 'Phase 1: Smart Post-Generation'" Enter
Type "echo '  1) Review in editor, then commit'" Enter
```

**Why `echo` is required:**
- ZSH interprets `#` at the start of a line as a command (not a comment)
- `echo` makes it a valid shell command that displays the text
- Preserves visual appearance while ensuring error-free execution

### 3. Shell Directive

**Always specify the shell:**

```bash
Set Shell zsh
```

**Why required:**
- Ensures consistent behavior across environments
- Prevents shell-specific syntax issues
- Required by validation script

### 4. Dimension Standards

Use consistent dimensions per category:

**Teaching Tutorials:**
```bash
Set Width 1400
Set Height 900
```

**Dispatcher Demos:**
```bash
Set Width 1200
Set Height 800
```

**Quick Demos:**
```bash
Set Width 1200
Set Height 600
```

---

## Common Pitfalls

### Pitfall 1: Quote Escaping

**❌ WRONG:**
```bash
Type "teach exam \"Midterm 1\" --template foo" Enter
```

**✅ CORRECT:**
```bash
Type "teach exam 'Midterm 1' --template foo" Enter
```

**Solution:** Use single quotes inside double quotes to avoid escaping.

### Pitfall 2: Missing Shell Initialization

**❌ WRONG:**
```bash
# Starting demo without sourcing flow-cli
Type "teach status" Enter
```

**✅ CORRECT:**
```bash
Hide
Type "source ~/projects/dev-tools/flow-cli/flow.plugin.zsh" Enter
Sleep 1s
Show

Type "teach status" Enter
```

**Solution:** Always source flow-cli in the `Hide` block at the start.

### Pitfall 3: Typing Single `#` Character

**This is OKAY:**
```bash
Type "#" Enter  # Just typing the character for visual separation
```

**This is NOT okay:**
```bash
Type "# This is a comment" Enter  # ❌ Should use echo
```

**Distinction:** Typing a single `#` character is fine. Typing `# <text>` as a comment requires `echo`.

---

## Validation

Before committing VHS tapes, run the validation script:

```bash
./scripts/validate-vhs-tapes.sh
```

**What it checks:**
- ✓ Font size >= 18px (teaching) or >= 16px (other)
- ✓ No problematic `Type "#..."` syntax
- ✓ Shell directive present
- ✓ Output directive present
- ✓ Width and Height settings present

**All tapes must pass validation before commit.**

---

## Example: Complete Teaching Tutorial Tape

```bash
# VHS Demo: teach doctor - Health Check System
# Part of flow-cli Teaching Workflow v3.0
# Tutorial: Demonstrates comprehensive health checking

Output tutorial-teach-doctor.gif

Require echo

Set Shell zsh
Set FontSize 18
Set Width 1400
Set Height 900
Set TypingSpeed 50ms
Set PlaybackSpeed 0.8
Set Theme "Catppuccin Mocha"

Hide
# Load flow-cli
Type "source ~/projects/dev-tools/flow-cli/flow.plugin.zsh" Enter
Sleep 1s
Type "cd ~/projects/teaching/scholar-demo-course" Enter
Sleep 500ms
Type "clear" Enter
Show

# Title
Type "echo 'Teaching Workflow v3.0: Health Check System'" Enter
Sleep 1s

# Scene 1: Basic check
Type "echo 'Scene 1: Run basic health check'" Enter
Sleep 500ms
Type "teach doctor" Enter
Sleep 3s

# Scene 2: Fix mode
Type "echo 'Scene 2: Fix detected issues'" Enter
Sleep 500ms
Type "teach doctor --fix" Enter
Sleep 5s

# Conclusion
Type "echo '✓ All health checks passed!'" Enter
Sleep 2s
```

---

## Best Practices

### 1. Timing and Pacing

- **TypingSpeed:** 50ms (comfortable to watch)
- **PlaybackSpeed:** 0.8 (slightly slower for clarity)
- **Sleep after commands:** 500ms-1s (give time to read)
- **Sleep after output:** 2-3s (enough time to absorb)

### 2. Visual Clarity

- Start with clear title card
- Use `echo` statements to narrate scenes
- Add visual separators between sections
- End with summary or next steps

### 3. Content Structure

```bash
# 1. Title card
Type "echo 'Feature Demo'" Enter

# 2. Scene introduction
Type "echo 'Scene 1: Description'" Enter

# 3. Actual commands
Type "command" Enter
Sleep <appropriate-time>

# 4. Scene conclusion
Type "echo '✓ Scene complete'" Enter
```

### 4. Error Prevention

- Always source flow-cli in `Hide` block
- Use `echo` for all commentary
- Test tape locally before committing
- Run validation script

---

## Themes

**Recommended themes:**
- `Catppuccin Mocha` (warm, easy on eyes)
- `Dracula` (high contrast, classic)
- `Monokai` (vibrant, good for code)

**Avoid:**
- Very light themes (harder to read)
- Themes with low contrast

---

## File Size Optimization

After generating GIFs, optimize with gifsicle:

```bash
gifsicle -O3 input.gif -o input.gif
```

**Expected results:**
- 30-40% file size reduction
- No visual quality loss
- Faster page load times

---

## Troubleshooting

### Issue: GIF looks blurry

**Solution:** Increase font size to 18px or higher

### Issue: Commands generate errors

**Solution:** Check for `Type "#..."` patterns, replace with `Type "echo '...'"`

### Issue: Shell not found

**Solution:** Add `Set Shell zsh` directive

### Issue: GIF too large (> 2MB)

**Solution:**
1. Run gifsicle optimization
2. Reduce duration (trim unnecessary pauses)
3. Consider splitting into multiple shorter GIFs

---

## References

- **VHS Documentation:** https://github.com/charmbracelet/vhs
- **gifsicle Manual:** https://www.lcdf.org/gifsicle/man.html
- **Validation Script:** `scripts/validate-vhs-tapes.sh`
- **Teaching Workflow Guide:** `docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md`

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-01-29 | Initial style guide created |

---

**Questions?** Open an issue or refer to existing VHS tapes in `docs/demos/tutorials/` for examples.
