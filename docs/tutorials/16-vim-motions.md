# Tutorial 16: Vim Motions - Efficient Navigation

> **What you'll learn:** Move around files lightning-fast using vim's powerful motion commands
>
> **Time:** ~15 minutes | **Level:** Beginner to Intermediate

---

## Prerequisites

Before starting, you should:

- [ ] Complete [Tutorial 15: Nvim Quick Start](15-nvim-quick-start.md)
- [ ] Know basic nvim commands (i, ESC, :wq)
- [ ] Be comfortable with normal mode

**Quick refresher:**

```bash
# Open a test file
nvim /tmp/vim-motions-practice.txt

# Remember: ESC → :q! to panic exit
```

---

## What You'll Learn

By the end of this tutorial, you will:

1. Navigate by words, lines, and paragraphs
2. Search and jump to specific characters
3. Use text objects to select and modify code
4. Move 10x faster than arrow keys
5. Think in "verbs + nouns" for editing

---

## Overview

**The Big Idea:** In vim, you don't move the cursor character-by-character. You move in meaningful units: **words**, **sentences**, **paragraphs**, **functions**.

```
Arrow keys:  → → → → → → → → → →  (10 keypresses)
Vim motions: w w w                 (3 keypresses, same distance)
```

**Three types of motions:**

1. **Word motions** (w, b, e) - jump by words
2. **Search motions** (/, ?, f, t) - find and jump
3. **Text objects** (iw, ap, i") - select logical units

---

## Part 1: Word Motions

### Step 1.1: Create Practice File

Let's make a file with some real content to practice on:

```bash
cat > /tmp/vim-motions-practice.txt << 'EOF'
The quick brown fox jumps over the lazy dog.
Programming in vim is fast and efficient.
You can navigate code with surgical precision.

Functions, variables, and strings are easy to target.
Master these motions and you'll never go back.

def calculate_total(items):
    total = sum(item.price for item in items)
    return total * 1.1  # Add 10% tax
EOF

nvim /tmp/vim-motions-practice.txt
```

### Step 1.2: Forward Word Motion (w)

In normal mode, press `w` to jump to the beginning of the **next word**.

**Try it:**
1. Put cursor at start of first line
2. Press `w` repeatedly
3. Watch cursor jump from word to word

**Pattern:** `w` skips punctuation. `W` (capital) treats punctuation as part of word.

### Step 1.3: Backward Word Motion (b)

Press `b` to jump **back** to the beginning of the previous word.

**Try it:**
1. Jump to end of first line (with `w` many times)
2. Press `b` repeatedly to go back
3. Notice it's the reverse of `w`

### Step 1.4: End of Word Motion (e)

Press `e` to jump to the **end** of the next word.

**Try it:**
1. Put cursor at start of line
2. Press `e` → jumps to end of "The"
3. Press `e` → jumps to end of "quick"

**Checkpoint:** Navigate the first line using only w/b/e. ✅

---

## Part 2: Line and Document Navigation

### Step 2.1: Beginning and End of Line

| Motion | Where It Goes |
|--------|---------------|
| `0` | Beginning of line (column 0) |
| `^` | First non-whitespace character |
| `$` | End of line |

**Try it:**
1. Press `0` → cursor at start
2. Press `$` → cursor at end
3. Press `^` → cursor at first character (if line has spaces)

### Step 2.2: Top and Bottom of File

| Motion | Where It Goes |
|--------|---------------|
| `gg` | Top of file (line 1) |
| `G` | Bottom of file (last line) |
| `5G` | Line 5 (or any number) |
| `Ctrl-d` | Down half a page |
| `Ctrl-u` | Up half a page |

**Try it:**
1. Press `G` → jump to bottom of file
2. Press `gg` → jump to top
3. Press `7G` → jump to line 7

**Checkpoint:** Can you jump to any line instantly? ✅

---

## Part 3: Search and Jump Motions

### Step 3.1: Search with /

Type `/` followed by text to search forward.

**Try it:**
1. Press `/fox` and ENTER
2. Cursor jumps to "fox"
3. Press `n` to find **next** occurrence
4. Press `N` to find **previous** occurrence

**Reverse search:** Use `?` to search backward.

### Step 3.2: Find Character on Line (f/F)

`f{char}` = **find** and jump to next occurrence of character on current line.

**Try it on first line:**
1. Put cursor at start
2. Press `fo` → jumps to "o" in "brown"
3. Press `;` → jumps to next "o"
4. Press `,` → jumps to previous "o"

**Variants:**
- `f{char}` = jump TO character (forward)
- `F{char}` = jump TO character (backward)
- `t{char}` = jump BEFORE character (forward)
- `T{char}` = jump BEFORE character (backward)

### Step 3.3: Power Combo - f with Delete

Here's where it gets powerful. Combine `f` with editing commands:

**Example:** Delete from cursor to the next period.

1. Put cursor anywhere on first line
2. Press `df.` (delete-find-period)
3. Everything from cursor to period is deleted!

**More combos:**
- `ct"` = change (replace) from cursor to next quote
- `yt)` = yank (copy) from cursor to before next )
- `vf;` = visually select from cursor to next semicolon

**Checkpoint:** Can you jump to any character on a line? ✅

---

## Part 4: Text Objects (The Secret Weapon)

### Step 4.1: What Are Text Objects?

Text objects are **semantic units**: words, sentences, paragraphs, code blocks, strings.

**Pattern:** `{operator}{a/i}{text-object}`

- `operator` = what to do (d=delete, c=change, y=yank, v=select)
- `a` = "a" (around, includes delimiters)
- `i` = "inner" (inside, excludes delimiters)
- `text-object` = what unit (w=word, p=paragraph, "=quotes, etc.)

### Step 4.2: Word Text Objects

Put cursor **anywhere inside a word** and try:

| Command | What It Does |
|---------|--------------|
| `diw` | Delete inner word |
| `daw` | Delete a word (includes space) |
| `ciw` | Change inner word (delete + insert mode) |
| `yiw` | Yank (copy) inner word |
| `viw` | Visually select inner word |

**Try it on "calculate":**
1. Put cursor anywhere in word "calculate"
2. Press `ciw`
3. Word deleted, now in insert mode
4. Type "compute" → `ESC`
5. You just replaced a word from anywhere in it!

### Step 4.3: Bracket and Quote Text Objects

On the line with function definition:

| Command | What It Does | Example |
|---------|--------------|---------|
| `di(` | Delete inside parentheses | `(items)` → `()` |
| `da(` | Delete around parentheses | `(items)` → `` |
| `di"` | Delete inside quotes | `"text"` → `""` |
| `ci{` | Change inside braces | `{...}` → `{}` + insert |

**Try it:**
1. Put cursor inside `(items)` on function line
2. Press `di(` → content deleted, parentheses remain
3. Undo with `u`
4. Press `da(` → parentheses and content gone

### Step 4.4: Paragraph Text Objects

| Command | What It Does |
|---------|--------------|
| `dap` | Delete a paragraph |
| `dip` | Delete inner paragraph |
| `yap` | Yank a paragraph |
| `vap` | Select a paragraph |

**Try it:**
1. Put cursor anywhere in first paragraph (first 3 lines)
2. Press `vap` → entire paragraph selected
3. Press `ESC` to deselect

**Checkpoint:** Can you edit code blocks without precise cursor placement? ✅

---

## Part 5: Practical Exercises

### Exercise 5.1: Refactor Function Name

**Goal:** Change `calculate_total` to `compute_sum`

**Efficient way:**
1. Put cursor anywhere in `calculate`
2. Press `/calculate` → ENTER (find first occurrence)
3. Press `ciw` → type `compute` → ESC
4. Press `n` to find next occurrence
5. Press `.` to repeat last change
6. Repeat `n.` for each occurrence

**Checkpoint:** Did you use search + change inner word? ✅

### Exercise 5.2: Delete a Function Argument

**Goal:** Remove `items` parameter from function definition

**Efficient way:**
1. Put cursor inside `(items)`
2. Press `di(` → deletes `items`, keeps parentheses

**Checkpoint:** Did you use text objects? ✅

### Exercise 5.3: Navigate to Specific Code

**Goal:** Jump to the return statement as fast as possible

**Efficient way:**
1. From top of file, press `/return` → ENTER
2. Or: Press `G` (bottom) → `k k` (up 2 lines)
3. Or: Press `8G` (line 8 directly)

**Checkpoint:** Can you jump to code without scrolling? ✅

---

## Part 6: The Motion Mindset

### Thinking in Operators + Motions

Vim commands combine:

```
{operator} + {motion/text-object}
```

**Examples:**

| Command | Operator | Motion | Result |
|---------|----------|--------|--------|
| `dw` | delete | word | delete to end of word |
| `c$` | change | end of line | change to line end |
| `y2j` | yank | 2 lines down | copy 3 lines |
| `>ip` | indent | inner paragraph | indent paragraph |

### Common Patterns to Memorize

**Delete:**
- `dd` = delete current line
- `dw` = delete word forward
- `db` = delete word backward
- `d$` = delete to end of line
- `dip` = delete inner paragraph

**Change (delete + insert):**
- `cc` = change entire line
- `ciw` = change inner word
- `ci"` = change inside quotes
- `ct;` = change until semicolon

**Yank (copy):**
- `yy` = yank current line
- `yiw` = yank inner word
- `yap` = yank around paragraph

**Checkpoint:** Do you understand operator + motion pattern? ✅

---

## Part 7: Advanced Tips

### Tip 1: Counts Work with Motions

Add a number before motion to repeat it:

- `3w` = move 3 words forward
- `2f;` = find second semicolon
- `d3w` = delete next 3 words
- `5dd` = delete 5 lines

### Tip 2: Marks for Bookmarks

Set marks to jump back to locations:

- `ma` = set mark 'a' at cursor position
- `'a` = jump back to mark 'a'
- `mM` = set global mark 'M' (works across files)

### Tip 3: Jump List Navigation

Nvim remembers your jumps:

- `Ctrl-o` = jump to previous location
- `Ctrl-i` = jump to next location
- `:jumps` = show jump list

### Tip 4: Macro Recording (Preview)

Record a sequence of motions and replay:

- `qa` = start recording to register 'a'
- ...perform motions...
- `q` = stop recording
- `@a` = replay macro from register 'a'

**Example:** Record `ciw` to change word, then replay on multiple words with `@a`.

---

## Part 8: Next Steps

### What You Just Learned ✅

- ✅ Word motions: w/b/e
- ✅ Line motions: 0/$/^, gg/G
- ✅ Search: /,?, f/F, t/T
- ✅ Text objects: iw/aw, i"/a", i(/a(, ip/ap
- ✅ Operator + motion pattern
- ✅ Counts and repetition (.)

### Practice Challenge

Open a code file (any language) and practice:

```bash
# Pick a real file from your projects
nvim ~/projects/some-project/src/main.zsh

# Challenge tasks:
# 1. Find all occurrences of a function name (/name → n → n)
# 2. Delete a function parameter (di()
# 3. Change a variable name (ciw)
# 4. Copy a whole function (vap → y)
# 5. Navigate to top/bottom without arrow keys (gg/G)
```

### What To Learn Next

**If you want LazyVim superpowers** → Continue to [Tutorial 17: LazyVim Basics](17-lazyvim-basics.md)

**If you want to master text objects** → Practice with real code for a week, then return

**If you need a quick reference** → Check [Nvim Quick Reference Card](../reference/NVIM-QUICK-REFERENCE.md)

**If you want hands-on drills** → Run the interactive tutorial:

```bash
flow nvim-tutorial
```

---

## Common Patterns Reference

### Navigation Patterns

```bash
w      # Next word
b      # Previous word
e      # End of word
0      # Start of line
$      # End of line
gg     # Top of file
G      # Bottom of file
/text  # Search forward
?text  # Search backward
f{     # Find character forward
t{     # Before character forward
```

### Editing Patterns

```bash
# Delete patterns
dw     # Delete word
dd     # Delete line
d$     # Delete to end of line
diw    # Delete inner word
di"    # Delete inside quotes

# Change patterns (delete + insert)
cw     # Change word
cc     # Change line
ciw    # Change inner word
ct;    # Change until semicolon

# Yank patterns (copy)
yy     # Yank line
yiw    # Yank word
yap    # Yank paragraph
```

---

## Summary

You've learned the **motion engine** that makes vim so powerful:

1. **Think in units:** words, not characters
2. **Combine operators + motions:** delete word (dw), change inside quotes (ci")
3. **Use text objects:** No need for precise cursor placement
4. **Search and jump:** Navigate by intent, not by scrolling

**The secret:** Vim motions are a **language**. Learn the grammar (operator + motion), and you can express any editing operation efficiently.

Practice for a week and these will become muscle memory!

---

**Next Tutorial:** [17: LazyVim Basics - Essential Plugins](17-lazyvim-basics.md)

**Quick Reference:** [Nvim Quick Reference Card](../reference/NVIM-QUICK-REFERENCE.md)

**Interactive Practice:** `flow nvim-tutorial`
