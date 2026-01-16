# Nvim Tutorial GIFs

This directory contains animated GIF demonstrations for the nvim tutorial series.

## Tutorial 15: Nvim Quick Start (3 GIFs)

### 1. opening-nvim.gif
**Scene:** Opening and quitting nvim safely
**Steps:**
1. Show terminal prompt
2. `nvim /tmp/nvim-test.txt`
3. Highlight "-- INSERT --" absence (normal mode)
4. Show bottom command area
5. Type `ESC` (show in status)
6. Type `:q!` (show in status)
7. Press ENTER
8. Back to terminal prompt

**Duration:** ~10 seconds
**Tool:** VHS or asciinema + agg

### 2. basic-edit-save.gif
**Scene:** Making first edit and saving
**Steps:**
1. `nvim /tmp/nvim-test.txt`
2. Press `i` (show `-- INSERT --` at bottom)
3. Type "Hello nvim!"
4. Press `ESC` (show mode change)
5. Type `:w` and ENTER (show "written" message)
6. Type `:q` and ENTER
7. Show terminal prompt

**Duration:** ~15 seconds

### 3. panic-exit.gif
**Scene:** Demonstrating the panic button
**Steps:**
1. `nvim /tmp/nvim-test.txt`
2. Press random keys (show confusion)
3. Text: "Oh no! What did I press?"
4. Big arrow pointing to ESC key
5. Press `ESC`
6. Type `:q!` (highlighted)
7. Press ENTER
8. Text: "Safe! No changes saved."

**Duration:** ~12 seconds
**Style:** Add text overlays for emphasis

## Tutorial 16: Vim Motions (3 GIFs)

### 4. word-motions.gif
**Scene:** Demonstrating w/b/e navigation
**Steps:**
1. Open file with multi-word lines
2. Use `w` to jump forward by words (highlight cursor)
3. Use `b` to jump backward
4. Use `e` to jump to end of words
5. Show how much faster than arrow keys

**Duration:** ~15 seconds

### 5. text-objects.gif
**Scene:** Using text objects (ciw, di", yap)
**Steps:**
1. Show line with quoted text
2. Cursor inside word → type `ciw` → replace word
3. Show line with quotes → type `di"` → delete inside quotes
4. Show paragraph → type `yap` → visual indication of yank

**Duration:** ~18 seconds

### 6. search-jump.gif
**Scene:** Using /, f, t for quick navigation
**Steps:**
1. Show file with multiple occurrences of "function"
2. Type `/function` → highlight matches
3. Press `n` to cycle through
4. Show `f{` to jump to next {
5. Show `t(` to jump before next (

**Duration:** ~20 seconds

## Tutorial 17: LazyVim Basics (4 GIFs)

### 7. neo-tree.gif
**Scene:** File navigation with Neo-tree
**Steps:**
1. Open nvim in project directory
2. Press `<leader>e` to toggle Neo-tree
3. Navigate tree with j/k
4. Press ENTER to open file
5. Show split view (tree + file)

**Duration:** ~15 seconds

### 8. telescope.gif
**Scene:** Fuzzy file finding
**Steps:**
1. Press `<leader>ff` to open Telescope
2. Type partial filename "test"
3. Show filtered results
4. Select with arrow keys
5. Press ENTER to open
6. Show recent files with `<leader>fr`

**Duration:** ~18 seconds

### 9. window-splits.gif
**Scene:** Window management
**Steps:**
1. Open file
2. `<leader>-` for horizontal split
3. `<leader>|` for vertical split
4. `Ctrl-h/j/k/l` to navigate splits
5. `:q` to close split

**Duration:** ~20 seconds

### 10. lazygit.gif
**Scene:** LazyGit integration
**Steps:**
1. Press `<leader>gg` to open LazyGit
2. Show status view
3. Stage a change (arrow keys + space)
4. Write commit message
5. Push changes
6. Return to nvim

**Duration:** ~25 seconds

## Tutorial 18: LazyVim Showcase (4 GIFs)

### 11. which-key-guide.gif
**Scene:** Which-key discovery system
**Steps:**
1. Press `<leader>` and wait
2. Which-key popup appears
3. Highlight categories (b=buffer, f=find, g=git, etc.)
4. Press `f` to see find submenu
5. Press `g` to see git submenu

**Duration:** ~18 seconds

### 12. lsp-workflow.gif
**Scene:** LSP features in action
**Steps:**
1. Open R or Python file with errors
2. Show diagnostic underline
3. Hover over error (`K`)
4. Show code action (`<leader>ca`)
5. Show autocomplete (start typing)
6. Go to definition (`gd`)

**Duration:** ~25 seconds

### 13. mason-install.gif
**Scene:** Installing language server with Mason
**Steps:**
1. Open Mason (`:Mason`)
2. Search for "pyright" (/ to search)
3. Press `i` to install
4. Show installation progress
5. Show checkmark when complete
6. Open Python file → LSP active

**Duration:** ~20 seconds

### 14. customization.gif
**Scene:** Adding custom keybinding
**Steps:**
1. Open `~/.config/nvim/lua/config/keymaps.lua`
2. Add line: `vim.keymap.set("n", "<leader>w", ":w<CR>")`
3. Save file
4. Restart nvim or source config
5. Test new keybinding `<leader>w`
6. Show "written" message

**Duration:** ~25 seconds

---

## Production Guidelines

### Technical Requirements

- **Format:** GIF (optimized with Gifski)
- **Max file size:** 2MB per GIF
- **Dimensions:** 800x600px or 1024x768px
- **FPS:** 15-20 (smooth but not excessive)
- **Color palette:** 256 colors (dithered)

### Recording Tools

**Recommended: VHS (charm.sh/vhs)**
```bash
# Install
brew install vhs

# Create .tape file with commands
# Run: vhs demo.tape
# Output: demo.gif
```

**Alternative: asciinema + agg**
```bash
# Record
asciinema rec demo.cast

# Convert to GIF
agg demo.cast demo.gif
```

**Terminal Setup:**
- Font: JetBrains Mono or Fira Code (14pt)
- Theme: Catppuccin or Tokyo Night
- Size: 80x24 or 100x30
- Cursor: Block, blinking

### Style Guidelines

1. **Keep it short:** 10-25 seconds max
2. **Pause strategically:** Hold on important moments (2-3 sec)
3. **Highlight actions:** Text overlay or arrow for key presses
4. **Clean terminal:** Clear prompt, no distractions
5. **Readable text:** Large enough font, high contrast

### Embedding in Markdown

```markdown
![Opening Nvim](../assets/gifs/nvim/opening-nvim.gif)
*Figure: Opening and safely quitting nvim*
```

---

## Status

- [ ] Tutorial 15 GIFs (1-3): Not created
- [ ] Tutorial 16 GIFs (4-6): Not created
- [ ] Tutorial 17 GIFs (7-10): Not created
- [ ] Tutorial 18 GIFs (11-14): Not created

**Total:** 0/14 GIFs created

---

**Created:** 2026-01-16
**Updated:** 2026-01-16
