# Nvim/LazyVim Quick Reference Card

> **1-page landscape printable reference** for essential nvim and LazyVim commands
>
> **Usage:** Keep this open in a split while learning, or print for desk reference

---

## 🆘 Panic Mode - Emergency Exit

```
ESC → :q! → ENTER      ❌ Quit without saving (use when stuck!)
ESC → :wq → ENTER      ✅ Save and quit (normal exit)
```

**Remember:** `ESC` gets you back to normal mode from anywhere. Then type commands starting with `:`.

---

## 📝 Modes

| Mode | How to Enter | Purpose | How to Exit |
|------|--------------|---------|-------------|
| **Normal** | `ESC` | Navigate and run commands | Default mode |
| **Insert** | `i` | Type text | `ESC` |
| **Visual** | `v` | Select text | `ESC` |
| **Command** | `:` | Run Ex commands | `ESC` or `ENTER` |

**Current mode** shown at bottom of screen (e.g., `-- INSERT --`).

---

## 🚶 Basic Navigation (Normal Mode)

### Character & Line Movement

| Key | Action | Key | Action |
|-----|--------|-----|--------|
| `h` | Left | `l` | Right |
| `j` | Down | `k` | Up |
| `w` | Next word | `b` | Previous word |
| `e` | End of word | `0` | Start of line |
| `$` | End of line | `^` | First non-blank |

**Tip:** Arrow keys also work, but `hjkl` is faster once learned.

### Document Navigation

| Key | Action | Key | Action |
|-----|--------|-----|--------|
| `gg` | Top of file | `G` | Bottom of file |
| `5G` | Go to line 5 | `Ctrl-d` | Down half page |
| `Ctrl-u` | Up half page | `{` | Previous paragraph |
| `}` | Next paragraph | `%` | Matching bracket |

### Search & Jump

| Key | Action | Key | Action |
|-----|--------|-----|--------|
| `/text` | Search forward | `?text` | Search backward |
| `n` | Next match | `N` | Previous match |
| `f{char}` | Jump to char → | `F{char}` | Jump to char ← |
| `t{char}` | Before char → | `T{char}` | Before char ← |
| `;` | Repeat f/t | `,` | Reverse f/t |

---

## ✏️ Editing (Normal Mode)

### Insert Mode Variants

| Key | Enters Insert Mode... |
|-----|----------------------|
| `i` | Before cursor |
| `a` | After cursor |
| `I` | Start of line |
| `A` | End of line |
| `o` | New line below |
| `O` | New line above |

### Delete

| Command | Deletes... | Command | Deletes... |
|---------|------------|---------|------------|
| `x` | Character | `dd` | Line |
| `dw` | Word forward | `db` | Word backward |
| `d$` | To end of line | `d0` | To start of line |
| `diw` | Inner word | `daw` | Around word |
| `di"` | Inside quotes | `da"` | Around quotes |
| `dip` | Inner paragraph | `dap` | Around paragraph |

### Change (Delete + Insert)

| Command | Changes... | Command | Changes... |
|---------|------------|---------|------------|
| `cw` | Word | `cc` | Line |
| `c$` | To end of line | `ciw` | Inner word |
| `ci"` | Inside quotes | `ci(` | Inside parens |
| `ct;` | Until semicolon | `c3w` | Next 3 words |

### Copy (Yank) & Paste

| Command | Action | Command | Action |
|---------|--------|---------|--------|
| `yy` | Yank line | `yw` | Yank word |
| `yiw` | Yank inner word | `yap` | Yank paragraph |
| `y$` | Yank to end of line | `p` | Paste after |
| `P` | Paste before | `"0p` | Paste from register 0 |

### Undo & Redo

| Key | Action |
|-----|--------|
| `u` | Undo |
| `Ctrl-r` | Redo |
| `.` | Repeat last change |

---

## 🎯 Text Objects

**Pattern:** `{operator}{a/i}{object}`

- `operator` = `d` (delete), `c` (change), `y` (yank), `v` (visual)
- `a` = around (includes delimiters)
- `i` = inner (excludes delimiters)

### Common Text Objects

| Object | Meaning | Example: `diw` | Example: `ci"` |
|--------|---------|----------------|----------------|
| `w` | word | Delete inner word | - |
| `"` | quotes | - | Change inside quotes |
| `'` | single quotes | - | Change inside single quotes |
| `` ` `` | backticks | - | Change inside backticks |
| `(` or `)` | parentheses | `di(` → delete inside `()` | - |
| `{` or `}` | braces | `di{` → delete inside `{}` | - |
| `[` or `]` | brackets | `di[` → delete inside `[]` | - |
| `<` or `>` | angle brackets | `di<` → delete inside `<>` | - |
| `t` | HTML tag | `dit` → delete inside tag | - |
| `p` | paragraph | `dap` → delete paragraph | - |

**Examples:**
- `ciw` - change inner word (cursor anywhere in word)
- `di"` - delete text inside quotes
- `dap` - delete around paragraph
- `vit` - visually select inside HTML tag

---

## 🎨 Visual Mode

| Key | Action | Key | Action |
|-----|--------|-----|--------|
| `v` | Start character-wise | `V` | Start line-wise |
| `Ctrl-v` | Start block (column) | `gv` | Re-select last |
| `o` | Toggle cursor end | `O` | Toggle cursor (block) |
| `aw` | Select word | `ap` | Select paragraph |

**After selection:** `d` delete, `c` change, `y` yank, `>` indent, `<` outdent

---

## 📁 LazyVim - Files & Navigation

### File Explorer (Neo-tree)

| Key | Action | Key | Action |
|-----|--------|-----|--------|
| **`<leader>e`** | **Toggle Neo-tree** | `j` / `k` | Navigate |
| `<CR>` | Open file/folder | `l` | Expand folder |
| `h` | Collapse folder | `a` | Add file |
| `d` | Delete | `r` | Rename |
| `/` | Search tree | `?` | Show help |

### Fuzzy Finder (Telescope)

| Key | Action |
|-----|--------|
| **`<leader>ff`** | **Find files** |
| **`<leader>fg`** | **Live grep (search text)** |
| `<leader>fb` | Find buffers |
| `<leader>fr` | Recent files |
| `<leader>fh` | Help tags |
| `<leader>fw` | Grep word under cursor |

**Inside Telescope:**
- `Ctrl-j` / `Ctrl-k` = move down/up
- `Ctrl-v` = open in vertical split
- `Ctrl-x` = open in horizontal split
- `<CR>` = open in current window
- `ESC` = close

---

## 🪟 LazyVim - Window Management

### Splits

| Key | Action | Key | Action |
|-----|--------|-----|--------|
| **`<leader>\|`** | **Vertical split** | **`<leader>-`** | **Horizontal split** |
| `Ctrl-h` | Move left | `Ctrl-l` | Move right |
| `Ctrl-j` | Move down | `Ctrl-k` | Move up |
| `<leader>wd` | Close window | `:only` | Close all but current |

### Resize Windows

| Key | Action |
|-----|--------|
| `Ctrl-Up` | Increase height |
| `Ctrl-Down` | Decrease height |
| `Ctrl-Left` | Decrease width |
| `Ctrl-Right` | Increase width |

---

## 📚 LazyVim - Buffers & Tabs

### Buffers

| Key | Action | Key | Action |
|-----|--------|-----|--------|
| `<leader>bb` | Switch buffer | `<leader>bd` | Delete buffer |
| `[b` | Previous buffer | `]b` | Next buffer |
| `<leader>fb` | Find buffer (Telescope) | | |

### Tabs

| Key | Action | Key | Action |
|-----|--------|-----|--------|
| `:tabnew` | New tab | `:tabclose` | Close tab |
| `gt` | Next tab | `gT` | Previous tab |
| `1gt` | Go to tab 1 | `2gt` | Go to tab 2 |

---

## 🔧 LazyVim - LSP (Language Server)

### Code Intelligence

| Key | Action | Key | Action |
|-----|--------|-----|--------|
| **`K`** | **Hover documentation** | **`gd`** | **Go to definition** |
| `gr` | Find references | `gI` | Go to implementation |
| **`<leader>ca`** | **Code actions** | **`<leader>rn`** | **Rename symbol** |
| `[d` | Previous diagnostic | `]d` | Next diagnostic |
| `<leader>xx` | Show all diagnostics | `<leader>xd` | Document diagnostics |

### Autocomplete

**In insert mode:**
- Start typing → autocomplete appears
- `Ctrl-n` = next suggestion
- `Ctrl-p` = previous suggestion
- `<CR>` = accept
- `Ctrl-e` = close

---

## 🎮 LazyVim - Git Integration

### Gitsigns (Hunks)

| Key | Action | Key | Action |
|-----|--------|-----|--------|
| **`]h`** | **Next hunk** | **`[h`** | **Previous hunk** |
| `<leader>gp` | Preview hunk | `<leader>gr` | Reset hunk |
| `<leader>gs` | Stage hunk | `<leader>gu` | Unstage hunk |
| **`<leader>gb`** | **Toggle blame** | `<leader>gd` | Diff this file |

### LazyGit

| Key | Action |
|-----|--------|
| **`<leader>gg`** | **Open LazyGit** |
| (in LazyGit) `j/k` | Navigate |
| (in LazyGit) `SPACE` | Stage/unstage |
| (in LazyGit) `c` | Commit |
| (in LazyGit) `P` | Push |
| (in LazyGit) `q` | Quit |

---

## 💻 LazyVim - Terminal

| Key | Action |
|-----|--------|
| **`<leader>ft`** | **Floating terminal** |
| `<leader>fT` | Horizontal split terminal |
| (in terminal) `ESC` | Exit insert mode |
| (in terminal) `Ctrl-d` | Close terminal |

---

## 🔍 LazyVim - Which-key

| Key | Action |
|-----|--------|
| **`<leader>`** (wait) | **Show all `<leader>` commands** |
| `<leader>f` (wait) | Show find submenu |
| `<leader>g` (wait) | Show git submenu |
| `<leader>b` (wait) | Show buffer submenu |
| `<leader>w` (wait) | Show window submenu |

**Categories:**
- `b` = buffers
- `c` = code actions
- `f` = find/telescope
- `g` = git
- `s` = search
- `w` = windows
- `x` = diagnostics

---

## 🛠️ Commands & Management

### Essential Commands

| Command | Action | Command | Action |
|---------|--------|---------|--------|
| `:w` | Save | `:q` | Quit |
| `:wq` | Save and quit | `:q!` | Quit without saving |
| `:e file.txt` | Edit file | `:wa` | Save all |
| `:qa` | Quit all | `:wqa` | Save and quit all |
| `:only` | Close all but current window |

### LazyVim Management

| Command | Purpose |
|---------|---------|
| `:Lazy` | Plugin manager |
| `:LazyExtras` | Enable language extras |
| `:Mason` | Install LSP servers |
| `:TSInstallInfo` | Treesitter parsers |
| `:checkhealth` | Diagnose issues |
| `:LspInfo` | LSP server status |

---

## 🎓 Flow-CLI Integration

| Command | Opens nvim for... |
|---------|-------------------|
| `work <project>` | Starting work session |
| `mcp edit <server>` | Editing MCP config |
| `dot edit <file>` | Editing dotfiles |
| `r edit` | Editing R package files |

**Default editor:** Nvim is flow-cli's default editor. Most edit operations use nvim automatically.

---

## 📖 Learning Path

1. **Start:** [Tutorial 15: Nvim Quick Start](../tutorials/15-nvim-quick-start.md) (~10 min)
2. **Master motions:** [Tutorial 16: Vim Motions](../tutorials/16-vim-motions.md) (~15 min)
3. **Learn tools:** [Tutorial 17: LazyVim Basics](../tutorials/17-lazyvim-basics.md) (~15 min)
4. **Go deep:** [Tutorial 18: LazyVim Showcase](../tutorials/18-lazyvim-showcase.md) (~30 min)

**Interactive:** Run `flow nvim-tutorial` for hands-on practice with checkpoints.

---

## 💡 Pro Tips

1. **The leader key is SPACE** - All `<leader>` commands start with spacebar
2. **ESC is your panic button** - Press ESC then `:q!` to abort anything
3. **Use text objects** - `ciw` to change word, `di"` to delete inside quotes
4. **Which-key helps** - Press `<leader>` and wait to see available commands
5. **Search is powerful** - `/text` then `n` to cycle through matches
6. **Splits for parallel work** - `<leader>|` then `Ctrl-h/l` to switch
7. **Telescope for everything** - `<leader>ff` files, `<leader>fg` grep
8. **LSP for code** - `K` for docs, `gd` for definition, `<leader>ca` for actions
9. **Practice daily** - Takes ~1 week for muscle memory
10. **Customize gradually** - Start with defaults, add keybindings as needed

---

## 🚀 Common Workflows

### Edit Flow Config

```
mcp edit statistical-research → nvim opens config → i → edit → ESC → :wq
```

### Find and Fix Code

```
<leader>fg "function_name" → Ctrl-j to select → <CR> → edit → <leader>ca for fixes
```

### Multi-file Development

```
<leader>e (Neo-tree) → <leader>| (split) → Ctrl-l → <leader>ff (find file) → <leader>- (split) → <leader>fT (terminal)
```

### Git Workflow

```
Make edits → :w → <leader>gp (preview hunk) → <leader>gs (stage) → <leader>gg (LazyGit) → commit & push
```

---

**Print this reference** and keep it visible while learning!

**Version:** flow-cli v5.11.0 | **Last Updated:** 2026-01-16
