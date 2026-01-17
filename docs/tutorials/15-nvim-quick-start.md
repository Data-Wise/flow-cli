# Tutorial 15: Nvim Quick Start

> **What you'll learn:** Survive and edit files in nvim - the essential commands to get started
>
> **Time:** ~10 minutes | **Level:** Absolute Beginner

---

## Prerequisites

Before starting, you should:

- [ ] Have nvim installed (`nvim --version` shows output)
- [ ] Know that nvim is flow-cli's default editor
- [ ] Be comfortable using a terminal

**Verify nvim is installed:**

```bash
# Check nvim is available
command -v nvim && echo "✅ Nvim found" || echo "❌ Install: brew install neovim"

# Check version (should be 0.9.0+)
nvim --version | head -1
```

---

## What You'll Learn

By the end of this tutorial, you will:

1. Open and close nvim without panic
2. Enter and exit insert mode
3. Make basic edits and save files
4. Navigate with arrow keys (and optionally hjkl)
5. Use nvim with flow-cli commands

---

## Overview

**The #1 thing to remember:** Press `ESC` to get back to normal mode, then type `:q!` to quit without saving.

Nvim has two essential modes:

```
┌─────────────────┐     ┌─────────────────┐
│  Normal Mode    │ <-> │  Insert Mode    │
│  (Navigation)   │     │  (Type text)    │
│  Press ESC here │     │  Press i here   │
└─────────────────┘     └─────────────────┘
```

**The panic button:** `ESC` → `:q!` → `ENTER` (quit without saving)

---

## Part 1: Opening and Closing Files

### Step 1.1: Open a Test File

Let's create a safe practice file:

```bash
# Create a test file
echo "Hello from nvim practice!" > /tmp/nvim-test.txt

# Open it with nvim
nvim /tmp/nvim-test.txt
```

**What happened:** Nvim opens showing your file content. You're in **Normal mode** (can't type yet).

### Step 1.2: The Panic Exit

Don't want to edit? Here's how to quit immediately:

1. Press `ESC` (makes sure you're in normal mode)
2. Type `:q!` (colon, letter q, exclamation mark)
3. Press `ENTER`

**Try it now:** Open the file again and practice the panic exit 3 times.

```bash
nvim /tmp/nvim-test.txt
# ESC → :q! → ENTER
```

**What happened:** You exited nvim without saving any changes.

### Step 1.3: The Safe Exit

To save your work AND quit:

1. Press `ESC`
2. Type `:wq` (colon, w for write, q for quit)
3. Press `ENTER`

```bash
nvim /tmp/nvim-test.txt
# Make no changes
# ESC → :wq → ENTER
```

**Checkpoint:** Can you reliably quit nvim now? ✅

---

## Part 2: Making Your First Edit

### Step 2.1: Enter Insert Mode

Time to actually edit! Open the test file:

```bash
nvim /tmp/nvim-test.txt
```

Now press `i` to enter **Insert mode**. You should see `-- INSERT --` at the bottom.

**What you can do now:**
- Type normally like any text editor
- Use arrow keys to move around
- Use backspace/delete
- Press ENTER for new lines

### Step 2.2: Make a Simple Edit

While in insert mode:

1. Press ENTER to create a new line
2. Type: `This is my first nvim edit!`
3. Press `ESC` to return to normal mode

### Step 2.3: Save Your Changes

From normal mode:

1. Type `:w` (colon, letter w) and press ENTER

**What happened:** File saved! You should see `"/tmp/nvim-test.txt" 3L, 60C written` at the bottom.

### Step 2.4: Quit

Now quit with `:q` and press ENTER.

**Try this flow again:**

```bash
nvim /tmp/nvim-test.txt
# i → type something → ESC → :w → :q
```

**Checkpoint:** Can you open, edit, save, and quit? ✅

---

## Part 3: Essential Survival Commands

### The Six Commands You MUST Know

Open the test file one more time to practice:

```bash
nvim /tmp/nvim-test.txt
```

| Command | What It Does | When To Use |
|---------|--------------|-------------|
| `i` | Enter insert mode | When you want to type |
| `ESC` | Exit to normal mode | When done typing |
| `:w` | Write (save) file | To save your changes |
| `:q` | Quit nvim | To close the file |
| `:wq` | Write and quit | Save and close in one step |
| `:q!` | Quit without saving | Panic button / discard changes |

**Practice drill:**

1. Press `i` → type "test" → `ESC`
2. Type `:w` → ENTER (saved)
3. Press `i` → type "more" → `ESC`
4. Type `:q!` → ENTER (quit without saving "more")

### Navigation in Normal Mode

You can use **arrow keys** to move around in normal mode (not in insert mode).

**Optional power-user keys** (same as arrow keys):

- `h` = left
- `j` = down
- `k` = up
- `l` = right

**Tip:** Ignore hjkl for now. Use arrow keys until you're comfortable!

---

## Part 4: Flow Integration

### Using Nvim with Work Command

The `work` command opens nvim automatically when editing files:

```bash
# Start a work session
work test-project

# Open a file (will use nvim)
# ...when prompted, you'll be in nvim
```

### Using Nvim with MCP Dispatcher

Edit MCP server configs:

```bash
# Opens MCP config in nvim
mcp edit statistical-research
```

**What you'll see:** Nvim opens the config file. Use `i` to edit, `ESC :wq` to save and quit.

### Using Nvim with Dot Dispatcher

Edit dotfiles:

```bash
# Opens .zshrc in nvim
dot edit zsh
```

**Pattern:** Whenever flow-cli needs to edit a file, it uses nvim by default!

---

## Part 5: Next Steps

### What You Just Learned ✅

- ✅ Panic exit: `ESC → :q!`
- ✅ Safe exit: `ESC → :wq`
- ✅ Insert mode: `i`
- ✅ Save: `:w`
- ✅ Basic navigation with arrows
- ✅ Flow integration (work, mcp, dot)

### What To Learn Next

**If you're comfortable with basics** → Try [Tutorial 16: Vim Motions](16-vim-motions.md) to learn efficient navigation

**If you want to see LazyVim features** → Skip to [Tutorial 17: LazyVim Basics](17-lazyvim-basics.md)

**If you need a quick reference** → Check [Nvim Quick Reference Card](../reference/NVIM-QUICK-REFERENCE.md)

**If you want hands-on practice** → Run the interactive tutorial:

```bash
flow nvim-tutorial
```

---

## Common Issues

### "I pressed keys and now nvim is frozen!"

**Solution:** Press `ESC` multiple times, then type `:q!` and ENTER.

### "I can't type anything!"

**Solution:** You're in normal mode. Press `i` to enter insert mode.

### "I accidentally edited and don't want to save"

**Solution:** `ESC → :q! → ENTER` (quit without saving)

### "I want to undo my last change"

**Solution:** In normal mode, press `u` to undo. Press `Ctrl-r` to redo.

### "How do I copy/paste?"

**Solution:** In insert mode, use your terminal's copy/paste (Cmd-C / Cmd-V on Mac). Or learn visual mode in Tutorial 16!

---

## Practice Challenge

**Goal:** Edit your .zshrc file to add a comment.

```bash
# Open your zsh config
nvim ~/.config/zsh/.zshrc

# 1. Press 'i' to enter insert mode
# 2. Use arrow keys to move to the top
# 3. Add a new line: "# Edited with nvim!"
# 4. Press ESC
# 5. Type :wq and press ENTER
```

Verify your edit:

```bash
head -3 ~/.config/zsh/.zshrc
```

**Checkpoint:** Did you successfully edit .zshrc? ✅

---

## Summary

You now know the **absolute essentials** of nvim:

- **Opening:** `nvim filename`
- **Editing:** Press `i`, type, press `ESC`
- **Saving:** `:w`
- **Quitting:** `:q` (or `:wq` to save+quit, `:q!` to discard)
- **Panic:** `ESC :q!`

**These six commands are enough to use nvim in flow-cli!**

Everything else is optimization. Take a break, then continue to Tutorial 16 when ready.

---

**Next Tutorial:** [16: Vim Motions - Efficient Navigation](16-vim-motions.md)

**Quick Reference:** [Nvim Quick Reference Card](../reference/NVIM-QUICK-REFERENCE.md)

**Interactive Practice:** `flow nvim-tutorial`
