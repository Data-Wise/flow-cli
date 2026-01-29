# Tutorial 17: LazyVim Basics - Essential Plugins

> **What you'll learn:** Master the core LazyVim plugins that supercharge your nvim workflow
>
> **Time:** ~15 minutes | **Level:** Intermediate

---

## Prerequisites

Before starting, you should:

- [ ] Complete [Tutorial 15: Nvim Quick Start](15-nvim-quick-start.md) and [Tutorial 16: Vim Motions](16-vim-motions.md)
- [ ] Have LazyVim installed (comes configured with flow-cli)
- [ ] Know basic vim motions (w/b, i, ESC, :wq)

**Verify LazyVim is installed:**

```bash
# Check LazyVim config exists
ls ~/.config/nvim/lua/lazyvim.lua

# Open nvim and check plugins are loaded
nvim
# Press :Lazy to see plugin manager
```

---

## What You'll Learn

By the end of this tutorial, you will:

1. Navigate files with Neo-tree sidebar
2. Find files instantly with Telescope fuzzy finder
3. Manage multiple windows and splits
4. Discover keybindings with Which-key
5. Work with Git using gitsigns
6. Use the integrated terminal

---

## Overview

**What is LazyVim?**

LazyVim is a pre-configured nvim distribution with **58 plugins** already set up. Think of it as:

- **Ubuntu** vs raw Linux (LazyVim vs vanilla nvim)
- **Sensible defaults** instead of building from scratch
- **100+ keybindings** already mapped
- **Fast** (sub-100ms startup with lazy loading)

```
Vanilla Nvim:  Raw editor, configure everything yourself
LazyVim:       Batteries included, ready to code
```

**The `<leader>` key:** Most LazyVim commands start with `<leader>` (mapped to `SPACE` by default).

---

## Part 1: File Navigation with Neo-tree

### Step 1.1: Open Neo-tree Sidebar

Neo-tree is a file explorer sidebar (like VS Code's file tree).

**Open a project directory:**

```bash
cd ~/projects/dev-tools/flow-cli
nvim
```

**Open Neo-tree:**

Press `<leader>e` (SPACE + e) to toggle the file explorer.

**What you see:**
- Left sidebar with directory tree
- Current file highlighted
- Folder icons (can expand/collapse)

### Step 1.2: Navigate the Tree

**Basic navigation:**

| Key | Action |
|-----|--------|
| `j` / `k` | Move down / up |
| `<CR>` (Enter) | Open file or toggle folder |
| `l` | Expand folder |
| `h` | Collapse folder |
| `<leader>e` | Toggle Neo-tree on/off |

**Try it:**
1. Press `<leader>e` to open Neo-tree
2. Use `j/k` to move up/down files
3. Press `l` to expand a folder
4. Press `<CR>` on a file to open it
5. Press `<leader>e` to hide Neo-tree

### Step 1.3: Neo-tree Actions

**Advanced actions** (when cursor is in Neo-tree):

| Key | Action |
|-----|--------|
| `a` | Add new file |
| `d` | Delete file |
| `r` | Rename file |
| `y` | Copy file |
| `x` | Cut file |
| `p` | Paste file |
| `/` | Search in tree |

**Try it:**
1. Press `<leader>e` to open Neo-tree
2. Press `a` → type `test.txt` → ENTER
3. File created and opened for editing
4. Save and close (`:wq`)
5. In Neo-tree, move to `test.txt`, press `d` to delete

**Checkpoint:** Can you navigate and manage files with Neo-tree? ✅

---

## Part 2: Find Files with Telescope

### Step 2.1: Fuzzy File Finding

Telescope is a **fuzzy finder** - type part of a filename and it finds matches.

**Find files:**

Press `<leader>ff` (SPACE + f + f) to open Telescope file finder.

**What you see:**
- Search prompt at top
- Live filtered list of files
- Preview pane (shows file content)

**Try it:**
1. Press `<leader>ff`
2. Type `work` (partial match)
3. See all files with "work" in name
4. Use arrow keys or `Ctrl-j/k` to move
5. Press `<CR>` to open selected file

### Step 2.2: Telescope Commands

**Essential Telescope pickers:**

| Keybinding | What It Finds | Command |
|------------|---------------|---------|
| `<leader>ff` | Files in project | Find files |
| `<leader>fg` | Text in files (grep) | Live grep |
| `<leader>fb` | Open buffers | Find buffers |
| `<leader>fh` | Help documentation | Find help |
| `<leader>fr` | Recently opened files | Old files |
| `<leader>fw` | Word under cursor | Grep word |

**Try each one:**

1. `<leader>ff` → type partial filename
2. `<leader>fg` → type text to search (e.g., "function")
3. `<leader>fb` → see all open files
4. `<leader>fr` → see recently edited files

### Step 2.3: Telescope Navigation

**Inside Telescope:**

| Key | Action |
|-----|--------|
| `Ctrl-j` / `Ctrl-k` | Move down / up |
| `Ctrl-u` / `Ctrl-d` | Scroll preview up / down |
| `<CR>` | Open in current window |
| `Ctrl-x` | Open in horizontal split |
| `Ctrl-v` | Open in vertical split |
| `Ctrl-t` | Open in new tab |
| `<ESC>` | Close Telescope |

**Try it:**
1. `<leader>ff` to open Telescope
2. Find a file
3. Press `Ctrl-v` to open in vertical split
4. You now see 2 files side-by-side!

**Checkpoint:** Can you find files by name and by content? ✅

---

## Part 3: Window Management

### Step 3.1: Creating Splits

LazyVim makes splits easy with dedicated keybindings.

**Split current window:**

| Keybinding | What It Does |
|------------|--------------|
| `<leader>-` | Horizontal split (window above/below) |
| `<leader>\|` | Vertical split (window left/right) |
| `<leader>wd` | Close current window |

**Try it:**
1. Open a file: `nvim ~/.zshrc`
2. Press `<leader>|` → vertical split
3. Press `<leader>-` → horizontal split
4. You now have 3 windows open!

### Step 3.2: Navigating Between Windows

**Move cursor between windows:**

| Keybinding | Direction |
|------------|-----------|
| `Ctrl-h` | Move to left window |
| `Ctrl-j` | Move to bottom window |
| `Ctrl-k` | Move to top window |
| `Ctrl-l` | Move to right window |

**Try it:**
1. Create 2 vertical splits (`<leader>|`)
2. Press `Ctrl-h` to move left
3. Press `Ctrl-l` to move right
4. Notice cursor moves between windows

### Step 3.3: Resizing Windows

**Adjust window size:**

| Keybinding | What It Does |
|------------|--------------|
| `Ctrl-Up` | Increase height |
| `Ctrl-Down` | Decrease height |
| `Ctrl-Left` | Decrease width |
| `Ctrl-Right` | Increase width |

**Try it:**
1. Create vertical split
2. Press `Ctrl-Right` repeatedly → right window grows
3. Press `Ctrl-Left` → left window grows

### Step 3.4: Window Workflow

**Typical workflow:**

1. `<leader>e` → Open Neo-tree (file explorer)
2. `<leader>|` → Vertical split (code on right, tree on left)
3. `<leader>ff` → Find file in right pane
4. `Ctrl-h/l` → Jump between panes

**Try it:**
1. Close all splits (`:only` or `<leader>wd` on each)
2. Open Neo-tree (`<leader>e`)
3. Create vertical split (`<leader>|`)
4. Move to right pane (`Ctrl-l`)
5. Open Telescope (`<leader>ff`) and select a file
6. You now have tree on left, code on right!

**Checkpoint:** Can you manage multiple files in splits? ✅

---

## Part 4: Which-key - Keybinding Discovery

### Step 4.1: What is Which-key?

Which-key shows available keybindings **as you type**.

**Try it:**
1. Press `<leader>` (SPACE) and **wait 1 second**
2. A popup appears showing all `<leader>` commands!

**What you see:**

```
╭─ <leader> ────────────────────────╮
│ b  buffer commands                │
│ f  find (Telescope)               │
│ g  git commands                   │
│ s  search                         │
│ w  window commands                │
│ ...                               │
╰───────────────────────────────────╯
```

### Step 4.2: Exploring Submenus

Which-key shows **nested menus**.

**Try it:**
1. Press `<leader>` → see top-level menu
2. Press `f` (for find) → see Telescope submenu
3. Press `f` again → opens file finder

**Navigation in Which-key:**
- Just type the letter shown
- Press `<ESC>` to cancel
- Wait for popup to appear

### Step 4.3: Common Which-key Categories

**Main categories:**

| Prefix | Category | Examples |
|--------|----------|----------|
| `<leader>b` | Buffer | List, delete, switch buffers |
| `<leader>f` | Find | Files, grep, help |
| `<leader>g` | Git | Status, blame, commits |
| `<leader>s` | Search | Word, symbols, diagnostics |
| `<leader>w` | Window | Split, close, navigate |
| `<leader>c` | Code | Actions, format, rename |
| `<leader>x` | Diagnostics | Errors, warnings, quickfix |

**Try exploring:**
1. `<leader>` → press `g` → see git commands
2. `<leader>` → press `b` → see buffer commands
3. `<leader>` → press `s` → see search commands

**Checkpoint:** Can you discover keybindings with Which-key? ✅

---

## Part 5: Git Integration with Gitsigns

### Step 5.1: Git Status Indicators

Gitsigns shows **git changes** directly in nvim.

**Open a git-tracked file:**

```bash
cd ~/projects/dev-tools/flow-cli
nvim README.md
```

**What you see:**
- **Green +** in gutter (left side) = added lines
- **Red ~** in gutter = modified lines
- **Red -** in gutter = deleted lines

### Step 5.2: Git Hunk Navigation

A "hunk" is a block of changes.

**Navigate hunks:**

| Keybinding | Action |
|------------|--------|
| `]h` | Jump to next hunk |
| `[h` | Jump to previous hunk |
| `<leader>gp` | Preview hunk (show diff) |
| `<leader>gr` | Reset hunk (discard changes) |
| `<leader>gs` | Stage hunk |

**Try it:**
1. Make a change to README.md
2. Save file (`:w`)
3. See green + in gutter
4. Press `<leader>gp` to preview the diff
5. Press `<leader>gr` to reset (undo) the change

### Step 5.3: Blame Current Line

See **who changed** the current line and when.

**Show blame:**

Press `<leader>gb` (git blame) to toggle blame annotations.

**What you see:**
- Inline text showing commit hash, author, date

**Try it:**
1. Open any git-tracked file
2. Press `<leader>gb`
3. See author and date for each line
4. Press `<leader>gb` again to hide

### Step 5.4: LazyGit Integration

LazyGit is a **terminal UI for Git** integrated into LazyVim.

**Open LazyGit:**

Press `<leader>gg` (git + git) to open LazyGit.

**What you see:**
- Full git status
- Commit history
- Branch management
- Staging interface

**Basic LazyGit navigation:**
- Arrow keys or `j/k` to navigate
- `SPACE` to stage/unstage
- `c` to commit
- `P` to push
- `q` to quit

**Try it:**
1. Make a change to a file and save
2. Press `<leader>gg`
3. See your change in status panel
4. Use `j/k` to navigate
5. Press `q` to close LazyGit

**Checkpoint:** Can you see git changes and stage hunks? ✅

---

## Part 6: Integrated Terminal

### Step 6.1: Open Terminal

LazyVim has built-in terminal support.

**Open terminal:**

| Keybinding | What It Opens |
|------------|---------------|
| `<leader>ft` | Terminal in floating window |
| `<leader>fT` | Terminal in split (horizontal) |

**Try it:**
1. Press `<leader>ft`
2. A terminal appears floating over your editor
3. Type commands normally
4. Press `<ESC>` to exit insert mode in terminal
5. Type `exit` or press `Ctrl-d` to close

### Step 6.2: Terminal Workflow

**Common use case:**

1. Editing code in nvim
2. Press `<leader>fT` → terminal in split
3. Run tests: `./tests/run-all.sh`
4. See output in split
5. Press `Ctrl-k` to jump back to code
6. Fix errors
7. Press `Ctrl-j` to jump back to terminal
8. Re-run tests

**Try it:**
1. Open a file
2. Press `<leader>fT` → terminal in horizontal split
3. Run `ls -l` in terminal
4. Press `Ctrl-k` → back to file
5. Make an edit
6. Press `Ctrl-j` → back to terminal
7. Type `exit` to close terminal

**Checkpoint:** Can you run commands without leaving nvim? ✅

---

## Part 7: Putting It All Together

### Typical Workflow

**Scenario:** Edit flow-cli code with tests running.

```bash
cd ~/projects/dev-tools/flow-cli
nvim
```

**Workflow:**

1. `<leader>e` → Open Neo-tree (see project structure)
2. `<leader>ff` → Find `commands/work.zsh`
3. `<leader>|` → Vertical split
4. `Ctrl-l` → Move to right pane
5. `<leader>fT` → Terminal in split below
6. In terminal: `./tests/run-all.sh`
7. `Ctrl-k` twice → Back to code
8. Make edits
9. `Ctrl-j` → Jump to terminal
10. Re-run tests

**Your screen layout:**

```
┌────────────────┬──────────────────────────┐
│                │                          │
│   Neo-tree     │     work.zsh (editing)   │
│  (file tree)   │                          │
│                │                          │
├────────────────┴──────────────────────────┤
│                                           │
│   Terminal (running tests)                │
│                                           │
└───────────────────────────────────────────┘
```

### Practice Challenge

**Goal:** Set up a 3-pane layout for development.

1. Open nvim in a project directory
2. Neo-tree on left (`<leader>e`)
3. Vertical split (`<leader>|`)
4. Code file on right (`<leader>ff` → select file)
5. Horizontal split on right side (`<leader>-`)
6. Terminal in bottom-right pane (`<leader>fT`)
7. Navigate between all 3 panes with `Ctrl-h/j/k/l`

**Checkpoint:** Can you create a multi-pane development layout? ✅

---

## Part 8: Next Steps

### What You Just Learned ✅

- ✅ Neo-tree for file navigation
- ✅ Telescope for fuzzy finding
- ✅ Window splits and navigation
- ✅ Which-key for discovering keybindings
- ✅ Gitsigns for git integration
- ✅ Integrated terminal

### Essential Keybindings Summary

**Files & Navigation:**
- `<leader>e` - Toggle Neo-tree
- `<leader>ff` - Find files
- `<leader>fg` - Grep files
- `<leader>fr` - Recent files

**Windows:**
- `<leader>|` - Vertical split
- `<leader>-` - Horizontal split
- `Ctrl-h/j/k/l` - Navigate splits
- `<leader>wd` - Close window

**Git:**
- `<leader>gg` - LazyGit
- `<leader>gp` - Preview hunk
- `<leader>gb` - Toggle blame
- `]h` / `[h` - Next/prev hunk

**Terminal:**
- `<leader>ft` - Floating terminal
- `<leader>fT` - Split terminal

### What To Learn Next

**If you want deep dive into LazyVim** → Continue to [Tutorial 18: LazyVim Showcase](18-lazyvim-showcase.md)

**If you need quick reference** → Check [Nvim Quick Reference Card](../reference/MASTER-DISPATCHER-GUIDE.md)

**If you want hands-on practice** → Run the interactive tutorial:

```bash
flow nvim-tutorial
```

---

## Summary

LazyVim transforms nvim into a **modern IDE** with:

- **Neo-tree**: VS Code-like file explorer
- **Telescope**: Instant fuzzy finding
- **Which-key**: Self-documenting keybindings
- **Gitsigns**: Inline git diff and blame
- **Terminal**: Run commands without leaving editor

You now have the **essential tools** for productive development in LazyVim!

Take time to practice these workflows, then explore more features in Tutorial 18.

---

**Next Tutorial:** [18: LazyVim Showcase - Comprehensive Tour](18-lazyvim-showcase.md)

**Previous Tutorial:** [16: Vim Motions](16-vim-motions.md)

**Quick Reference:** [Nvim Quick Reference Card](../reference/MASTER-DISPATCHER-GUIDE.md)

**Interactive Practice:** `flow nvim-tutorial`
