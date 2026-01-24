# Tutorial 18: LazyVim Showcase - Comprehensive Tour

> **What you'll learn:** Deep dive into LazyVim's full feature set - LSP, Mason, Treesitter, customization, and advanced workflows
>
> **Time:** ~30 minutes | **Level:** Intermediate to Advanced

---

## Prerequisites

Before starting, you should:

- [ ] Complete Tutorials [15](15-nvim-quick-start.md), [16](16-vim-motions.md), and [17](17-lazyvim-basics.md)
- [ ] Have LazyVim installed and configured
- [ ] Be comfortable with basic vim motions and LazyVim keybindings
- [ ] Have a project to work with (flow-cli or another codebase)

**Quick check:**

```bash
# Verify LazyVim installation
ls ~/.config/nvim/lua/lazyvim.lua

# Check plugin count
nvim +'Lazy' +q
# Should show ~58 plugins
```

---

## What You'll Learn

By the end of this tutorial, you will:

1. Understand LazyVim vs vanilla nvim
2. Use LSP for code intelligence and diagnostics
3. Install language servers with Mason
4. Leverage Treesitter for syntax understanding
5. Customize LazyVim with your own config
6. Enable language extras (R, Python, etc.)
7. Integrate LazyVim with flow-cli workflows

---

## Overview

**LazyVim = Opinionated Nvim Distribution**

Think of nvim distributions like Linux distros:

| Comparison | Vanilla Nvim | LazyVim |
|------------|--------------|---------|
| Config Lines | 0 (you write everything) | ~2000+ (pre-configured) |
| Plugins | 0 (install manually) | 58 (curated ecosystem) |
| LSP Setup | Manual | Automatic via Mason |
| Keybindings | Minimal defaults | 100+ sensible bindings |
| Startup Time | Fast (~50ms) | Still fast (~80ms) |
| Learning Curve | Steep (build from scratch) | Gradual (explore pre-built) |

**Key insight:** LazyVim gives you a **production-ready** editor on day 1, then lets you customize incrementally.

---

## Part 1: LazyVim Architecture

### Step 1.1: Understanding the Config Structure

LazyVim config lives in `~/.config/nvim/`:

```bash
~/.config/nvim/
├── init.lua                  # Entry point (loads LazyVim)
├── lua/
│   ├── config/               # Your customizations
│   │   ├── autocmds.lua      # Auto-commands
│   │   ├── keymaps.lua       # Custom keybindings
│   │   ├── lazy.lua          # Plugin manager setup
│   │   └── options.lua       # Vim options (settings)
│   ├── plugins/              # Your custom plugins
│   │   └── example.lua       # Add new plugins here
│   └── lazyvim/              # LazyVim core (don't edit)
└── lazyvim.json              # Language extras config
```

**Inspect your config:**

```bash
# List config files
ls ~/.config/nvim/lua/config/

# Check current options
nvim ~/.config/nvim/lua/config/options.lua
```

### Step 1.2: The Plugin Manager (Lazy.nvim)

LazyVim uses **lazy.nvim** for plugin management.

**View installed plugins:**

1. Open nvim: `nvim`
2. Type `:Lazy` and press ENTER
3. You see the Lazy.nvim dashboard

**What you see:**
- List of 58+ installed plugins
- Status: ✓ loaded, ⏳ lazy (not loaded yet)
- Update, clean, profile options

**Try it:**
1. `:Lazy` to open
2. Press `U` to update all plugins
3. Press `q` to close

### Step 1.3: What Are All These Plugins?

**Categories of LazyVim plugins:**

| Category | Examples | Purpose |
|----------|----------|---------|
| **Editor UI** | neo-tree, which-key, lualine | File tree, help, statusline |
| **Finding** | telescope, fzf | Fuzzy finder, grep |
| **LSP** | nvim-lspconfig, mason | Language servers, completion |
| **Syntax** | treesitter | Code parsing, highlighting |
| **Git** | gitsigns, lazygit | Git integration |
| **Coding** | nvim-cmp, luasnip | Autocomplete, snippets |
| **Formatting** | conform.nvim | Code formatting |
| **UI** | noice.nvim, notify | Enhanced UI, notifications |

**Checkpoint:** Do you understand the plugin ecosystem? ✅

---

## Part 2: LSP - Language Server Protocol

### Step 2.1: What is LSP?

LSP gives nvim **IDE features**:

- **Code completion** - autocomplete as you type
- **Diagnostics** - show errors/warnings inline
- **Go to definition** - jump to function/class source
- **Hover documentation** - see docs without leaving editor
- **Code actions** - automated fixes and refactorings
- **Rename** - rename variables across files

**The magic:** One protocol works with all languages (Python, R, JavaScript, Rust, etc.)

### Step 2.2: LSP in Action

**Open a code file with errors:**

```bash
# Create test Python file with intentional error
cat > /tmp/test.py << 'EOF'
def calculate_sum(numbers):
    total = 0
    for num in numbers:
        total += num
    return totla  # Typo: totla instead of total

result = calculate_sum([1, 2, 3])
print(result)
EOF

nvim /tmp/test.py
```

**What you should see:**
- Red squiggly underline under `totla`
- Error message in status line
- Diagnostic sign in gutter (left side)

**LSP Features to try:**

| Keybinding | Feature | What It Does |
|------------|---------|--------------|
| `K` | Hover | Show documentation for symbol under cursor |
| `gd` | Go to definition | Jump to where function/variable is defined |
| `gr` | References | Find all uses of symbol |
| `<leader>ca` | Code action | Show available fixes |
| `<leader>rn` | Rename | Rename symbol across files |
| `[d` / `]d` | Next/prev diagnostic | Jump to next error |

**Try it:**
1. Put cursor on `totla` (the typo)
2. Press `K` → no docs (undefined)
3. Press `<leader>ca` → see code actions
4. Select "Rename to 'total'" or manually fix
5. Save and errors disappear!

### Step 2.3: Understanding Diagnostics

**Diagnostic severity levels:**

- 🔴 **Error** - code won't run
- 🟡 **Warning** - suspicious code
- 🔵 **Info** - suggestions
- 💡 **Hint** - style recommendations

**Navigate diagnostics:**

```bash
]d     # Next diagnostic
[d     # Previous diagnostic
<leader>xx    # Show all diagnostics in Trouble window
<leader>xd    # Show document diagnostics
```

**Try it:**
1. Open a file with multiple issues
2. Press `]d` to jump to next error
3. Press `<leader>xx` to see all errors in list
4. Navigate list with `j/k`, press `<CR>` to jump to error

**Checkpoint:** Can you use LSP to navigate and fix code? ✅

---

## Part 3: Mason - Language Server Installer

### Step 3.1: What is Mason?

Mason is a **package manager for LSP servers**, formatters, and linters.

**Why Mason?**
- **One-command install** - no manual setup
- **Automatic PATH** - works immediately
- **Version management** - update easily
- **Cross-platform** - works on Mac/Linux/Windows

### Step 3.2: Browse Available Servers

**Open Mason:**

```bash
nvim
:Mason
```

**What you see:**
- List of available language servers
- ✓ Installed servers
- Empty box = not installed

**Categories:**
- LSP servers (intellisense)
- Formatters (prettier, black)
- Linters (eslint, pylint)
- DAP servers (debuggers)

### Step 3.3: Install a Language Server

**Example: Install Python LSP**

1. Open Mason (`:Mason`)
2. Press `/` to search
3. Type `pyright` (Python LSP)
4. Press `ENTER` to select
5. Press `i` to install
6. Watch installation progress
7. See ✓ when complete
8. Press `q` to close Mason

**Verify installation:**

```bash
# Open Python file
nvim /tmp/test.py

# LSP should now be active
# Check: :LspInfo (shows attached servers)
```

### Step 3.4: Common Language Servers

**Popular LSPs to install:**

| Language | LSP Server | Mason Name |
|----------|------------|------------|
| Python | Pyright | `pyright` |
| JavaScript/TypeScript | TypeScript LSP | `typescript-language-server` |
| R | R Language Server | `r-language-server` |
| Rust | Rust Analyzer | `rust-analyzer` |
| Go | Go LSP | `gopls` |
| Lua | Lua LSP | `lua-language-server` |
| Bash | Bash LSP | `bash-language-server` |

**Install LSP for your language:**

```bash
:Mason
# Search for your language
# Press 'i' to install
```

**Checkpoint:** Can you install language servers with Mason? ✅

---

## Part 4: Treesitter - Advanced Syntax

### Step 4.1: What is Treesitter?

Treesitter **parses code** into a syntax tree, enabling:

- **Better highlighting** - semantic colors (variables vs functions)
- **Smart selections** - select function, class, etc.
- **Code navigation** - jump to function definition
- **Refactoring** - understand code structure

**Vanilla vim:** Regex-based highlighting (dumb)
**Treesitter:** AST-based highlighting (smart)

### Step 4.2: Incremental Selection

Treesitter's killer feature: **expand selection smartly**.

**Try it:**

1. Open any code file
2. Put cursor inside a function
3. Press `Ctrl-Space` repeatedly
4. Watch selection expand: word → expression → statement → function → file

**Keybindings:**

| Key | Action |
|-----|--------|
| `Ctrl-Space` | Expand selection |
| `Backspace` | Shrink selection |

**Use case:**
- Quick way to select function body: `Ctrl-Space` × 3 → `y` to yank

### Step 4.3: Treesitter Text Objects

Treesitter adds **code-aware text objects**.

**Built-in text objects:**

| Command | What It Selects |
|---------|-----------------|
| `vaf` | Around function |
| `vif` | Inside function |
| `vac` | Around class |
| `vic` | Inside class |
| `vaa` | Around argument |

**Try it:**

```bash
# Create test file
cat > /tmp/test.py << 'EOF'
def greet(name, greeting="Hello"):
    message = f"{greeting}, {name}!"
    print(message)
    return message

greet("World")
EOF

nvim /tmp/test.py
```

1. Put cursor anywhere in function
2. Press `vaf` (visual around function)
3. Entire function selected!
4. Press `d` to delete function

### Step 4.4: Treesitter Status

**Check installed parsers:**

```bash
nvim
:TSInstallInfo
```

**What you see:**
- List of languages
- ✓ Installed parsers
- ✗ Not installed

**Install parser:**

```bash
:TSInstall python
:TSInstall r
:TSInstall bash
```

**Checkpoint:** Can you use Treesitter selections? ✅

---

## Part 5: Customization

### Step 5.1: Adding Custom Keybindings

**File:** `~/.config/nvim/lua/config/keymaps.lua`

Let's add a custom keybinding to save files with `<leader>w`:

```bash
nvim ~/.config/nvim/lua/config/keymaps.lua
```

**Add this line:**

```lua
-- Quick save
vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })
```

**What this does:**
- `"n"` = normal mode
- `"<leader>w"` = SPACE + w
- `":w<CR>"` = write command + ENTER
- `{ desc = ... }` = description for which-key

**Test it:**
1. Save keymaps.lua (`:wq`)
2. Restart nvim or source: `:source ~/.config/nvim/lua/config/keymaps.lua`
3. Open any file
4. Press `<leader>w` → file saves!
5. Press `<leader>` → which-key shows "Save file" option

### Step 5.2: Changing Vim Options

**File:** `~/.config/nvim/lua/config/options.lua`

Let's customize some settings:

```bash
nvim ~/.config/nvim/lua/config/options.lua
```

**Add these options:**

```lua
-- Show line numbers (relative)
vim.opt.relativenumber = true

-- Indent with 2 spaces
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Keep cursor centered
vim.opt.scrolloff = 8

-- Persistent undo
vim.opt.undofile = true
```

**Options explained:**

| Option | What It Does |
|--------|--------------|
| `relativenumber` | Show relative line numbers (easier jumps) |
| `tabstop = 2` | Tab equals 2 spaces |
| `expandtab` | Use spaces, not tabs |
| `scrolloff = 8` | Keep 8 lines visible above/below cursor |
| `undofile` | Save undo history to file |

**Test it:**
1. Save options.lua
2. Restart nvim
3. Notice line numbers are now relative
4. Check tab width when editing

### Step 5.3: Adding Custom Plugins

**File:** `~/.config/nvim/lua/plugins/custom.lua`

Let's add a new plugin (example: vim-surround):

```bash
nvim ~/.config/nvim/lua/plugins/custom.lua
```

**Add this:**

```lua
return {
  -- Surround text with quotes, brackets, etc.
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup()
    end,
  },
}
```

**What this does:**
- Adds nvim-surround plugin
- `event = "VeryLazy"` = load lazily (faster startup)
- `config = function()` = setup code

**Test it:**
1. Save custom.lua
2. Restart nvim or `:Lazy sync`
3. Open file with text: `Hello world`
4. Put cursor on "world"
5. Press `ysiw"` → becomes `"world"`
6. Press `ds"` → removes quotes

**Checkpoint:** Can you customize LazyVim config? ✅

---

## Part 6: Language Extras

### Step 6.1: What Are Extras?

LazyVim has **optional language packs** called "extras".

**Each extra includes:**
- Language-specific LSP config
- Formatters and linters
- Keybindings
- Treesitter parsers
- Recommended plugins

### Step 6.2: Enable Language Extras

**Method 1: Via UI**

```bash
nvim
:LazyExtras
```

**What you see:**
- List of available extras
- Categories: lang, coding, editor, ui
- x = enabled, space = disabled

**Enable Python extra:**
1. Navigate to `lang.python`
2. Press `x` to toggle
3. Restart nvim

**Method 2: Via lazyvim.json**

Edit `~/.config/nvim/lazyvim.json`:

```bash
nvim ~/.config/nvim/lazyvim.json
```

**Add extras:**

```json
{
  "extras": [
    "lazyvim.plugins.extras.lang.python",
    "lazyvim.plugins.extras.lang.typescript",
    "lazyvim.plugins.extras.lang.go",
    "lazyvim.plugins.extras.formatting.prettier"
  ]
}
```

**Save and restart nvim**.

### Step 6.3: Available Language Extras

**Popular extras:**

| Extra | What It Adds |
|-------|--------------|
| `lang.python` | Pyright LSP, black formatter, pytest |
| `lang.typescript` | TS LSP, prettier, eslint |
| `lang.go` | gopls, gofmt |
| `lang.rust` | rust-analyzer, rustfmt |
| `lang.json` | JSON LSP, prettier |
| `lang.markdown` | Markdown preview, lint |

**Non-language extras:**

| Extra | What It Adds |
|-------|--------------|
| `coding.copilot` | GitHub Copilot integration |
| `editor.aerial` | Code outline sidebar |
| `ui.alpha` | Dashboard on startup |

**Checkpoint:** Can you enable language extras? ✅

---

## Part 7: Flow Integration

### Step 7.1: Nvim as Default Editor

Flow-cli uses nvim by default for editing:

```bash
# Opens nvim automatically
work test-project

# Dispatcher commands that open nvim
mcp edit statistical-research  # Edit MCP config
dot edit zsh                    # Edit dotfiles
r edit                          # Edit R package files
```

### Step 7.2: Custom Flow Keybinding

Let's add a keybinding to run flow commands from nvim.

**Edit:** `~/.config/nvim/lua/config/keymaps.lua`

```lua
-- Run flow status in floating terminal
vim.keymap.set("n", "<leader>fs", function()
  require("lazyvim.util").float_term({ "flow", "status" })
end, { desc = "Flow status" })

-- Run flow tests
vim.keymap.set("n", "<leader>ft", function()
  require("lazyvim.util").float_term({ "flow", "test" })
end, { desc = "Flow tests" })
```

**Test it:**
1. Save and reload config
2. Press `<leader>fs` → flow status in terminal
3. Press `<leader>ft` → run tests

### Step 7.3: Project-Specific Config

For R package development, create `.nvim.lua` in project root:

```bash
cd ~/projects/r-packages/active/some-package
cat > .nvim.lua << 'EOF'
-- R package-specific nvim config
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2

-- Custom R keybindings
vim.keymap.set("n", "<leader>rt", ":!Rscript tests/testthat.R<CR>")
vim.keymap.set("n", "<leader>rc", ":!R CMD check .<CR>")
EOF
```

**Now when you open nvim in that directory:**
- Tab width = 2 (R style)
- `<leader>rt` runs tests
- `<leader>rc` runs check

**Checkpoint:** Can you integrate nvim with flow-cli? ✅

---

## Part 8: Advanced Workflows

### Workflow 1: Full-Stack Development

**Layout for web development:**

```bash
cd ~/projects/app/examify
nvim
```

**Setup:**
1. `<leader>e` → Neo-tree (left sidebar)
2. `<leader>|` → Vertical split
3. `Ctrl-l` → Move right
4. `<leader>ff` → Open `src/App.tsx`
5. `<leader>-` → Horizontal split
6. `<leader>fT` → Terminal below
7. In terminal: `npm run dev`

**Result:**

```
┌──────────┬────────────────┐
│ Neo-tree │  App.tsx       │
│          │  (edit code)   │
│          ├────────────────┤
│          │  Terminal      │
│          │  (npm dev)     │
└──────────┴────────────────┘
```

### Workflow 2: R Package Development

```bash
cd ~/projects/r-packages/active/rmediation
nvim
```

**Setup:**
1. `<leader>ff` → Open `R/mediation.R`
2. `<leader>-` → Horizontal split
3. `<leader>fT` → Terminal
4. In terminal: `r test` (flow-cli R dispatcher)
5. Make changes to code
6. `Ctrl-j` → Jump to terminal
7. Re-run `r test`

### Workflow 3: Documentation Writing

```bash
cd ~/projects/teaching/stat-440
nvim lectures/week-01/lecture.qmd
```

**Setup:**
1. Open Quarto file
2. `<leader>|` → Vertical split
3. `Ctrl-l` → Right pane
4. `<leader>fT` → Terminal
5. In terminal: `qu preview` (live preview)
6. Edit left, see preview in browser

**Checkpoint:** Can you set up custom workflows? ✅

---

## Part 9: Summary

### What You Learned ✅

- ✅ LazyVim architecture and plugin ecosystem
- ✅ LSP for code intelligence (completion, diagnostics, navigation)
- ✅ Mason for installing language servers
- ✅ Treesitter for smart syntax and selections
- ✅ Customization (keymaps, options, plugins)
- ✅ Language extras system
- ✅ Flow-cli integration
- ✅ Advanced multi-pane workflows

### Essential Commands Reference

**LazyVim Management:**

```bash
:Lazy           # Plugin manager
:LazyExtras     # Enable language extras
:Mason          # Install LSP servers
:TSInstallInfo  # Treesitter parsers
```

**LSP:**

```bash
K              # Hover docs
gd             # Go to definition
gr             # Find references
<leader>ca     # Code actions
<leader>rn     # Rename symbol
[d / ]d        # Next/prev diagnostic
```

**Customization Files:**

```bash
~/.config/nvim/lua/config/keymaps.lua    # Custom keybindings
~/.config/nvim/lua/config/options.lua    # Vim options
~/.config/nvim/lua/plugins/custom.lua    # Add plugins
~/.config/nvim/lazyvim.json              # Language extras
```

### Next Steps

**Practice:**
1. Use LazyVim for all your editing for one week
2. Customize one keybinding per day
3. Install LSP for each language you use
4. Create project-specific `.nvim.lua` files

**Resources:**

- [LazyVim Documentation](https://lazyvim.org)
- [Nvim Quick Reference](../reference/NVIM-QUICK-REFERENCE.md)
- [Nvim Quick Start Tutorial](15-nvim-quick-start.md)

**Troubleshooting:**
- `:checkhealth` - diagnose issues
- `:LspInfo` - check LSP status
- `:Lazy` - manage plugins
- `:Mason` - check language servers

---

## Conclusion

You now have a **complete understanding** of LazyVim:

- **Core vim** (Tutorial 15-16) - survival and motions
- **Essential tools** (Tutorial 17) - Neo-tree, Telescope, splits
- **Advanced features** (Tutorial 18) - LSP, Mason, Treesitter, customization

LazyVim transforms nvim into a **modern, powerful IDE** while keeping the speed and efficiency of vim.

The journey doesn't stop here - LazyVim is **endlessly customizable**. Start with the defaults, then gradually make it your own.

**Happy coding!** 🚀

---

**Previous Tutorial:** [17: LazyVim Basics](17-lazyvim-basics.md)

**Quick Reference:** [Nvim Quick Reference Card](../reference/NVIM-QUICK-REFERENCE.md)

**Interactive Practice:** `flow nvim-tutorial`
