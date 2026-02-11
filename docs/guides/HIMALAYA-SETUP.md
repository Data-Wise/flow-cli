# Himalaya Email in Neovim

Neovim integration for himalaya email client with AI-powered email assistance.

## Quick Reference

| Action | Keybind | Description |
|--------|---------|-------------|
| **Email Actions** | | |
| Write new email | `gw` | Compose new message |
| Reply | `gr` | Reply to sender |
| Reply all | `gR` | Reply to all recipients |
| Forward | `gf` | Forward message |
| Add attachment | `ga` | Attach file to message |
| Copy message | `gC` | Copy to another folder |
| Move message | `gM` | Move to another folder |
| **AI Actions** | | |
| Summarize email | `<leader>ms` | AI summary in float |
| Extract todos | `<leader>mt` | Parse action items |
| Draft reply | `<leader>mr` | AI-generated reply |
| TL;DR + decision | `<leader>mc` | One-line summary + action needed? |

## Prerequisites

1. **himalaya CLI** (v1.1.0+)
   ```bash
   # macOS
   brew install himalaya

   # Or via Cargo
   cargo install himalaya
   ```

2. **Configure email account**
   ```bash
   himalaya account configure
   ```

3. **Claude CLI** (for AI features)
   ```bash
   # Verify installation
   claude --version
   ```

4. **Neovim with LazyVim**

## Quick Start

### 1. Install himalaya-vim Plugin

Create `~/.config/nvim/lua/plugins/himalaya.lua`:

```lua
return {
  {
    "pimalaya/himalaya-vim",
    cmd = { "Himalaya" },
    dependencies = {
      { "nvim-telescope/telescope.nvim", optional = true },
    },
    init = function()
      vim.g.himalaya_executable = "/Users/dt/.cargo/bin/himalaya"
      vim.g.himalaya_folder_picker = "telescope"
      vim.g.himalaya_always_confirm = 1
    end,
    keys = {
      { "<leader>eM", "<cmd>Himalaya<cr>", desc = "Open Himalaya (Email)" },
    },
  },
}
```

### 2. Add AI Wrapper Module

Create `~/.config/nvim/lua/himalaya-ai.lua` (~380 lines). The module:

- Pipes buffer content to AI backend (claude/gemini) asynchronously via `vim.fn.jobstart()`
- Displays results in a right vsplit with action keybinds
- Result split keybinds: `y`=copy, `s`=save, `a`=append, `o`=obsidian, `p`=reply, `r`=rerun, `f`=fullscreen, `q`=close

See the full module at `~/.config/nvim/lua/himalaya-ai.lua`.

### 2b. Configure AI Backend (Optional)

Create `~/.config/himalaya-ai/config.lua` to customize backend and Obsidian vault:

```lua
return {
  backend = "claude",  -- or "gemini"
  backends = {
    claude = { cmd = "/Users/dt/.local/bin/claude", flag = "-p" },
    gemini = { cmd = "/opt/homebrew/bin/gemini", flag = "-p" },
  },
  obsidian = {
    vault = "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Knowledge_Base",
    subfolder = "Inbox",
    format = "structured",
  },
  save_dir = "~",
}
```

Falls back to built-in defaults if config file is missing.

### 3. Add Keybinds

Add to `~/.config/nvim/lua/config/keymaps.lua`:

```lua
-- Himalaya AI email actions
vim.keymap.set("n", "<leader>ms", function() require("himalaya-ai").summarize() end, { desc = "AI: Summarize email" })
vim.keymap.set("n", "<leader>mt", function() require("himalaya-ai").extract_todos() end, { desc = "AI: Extract action items" })
vim.keymap.set("n", "<leader>mr", function() require("himalaya-ai").draft_reply() end, { desc = "AI: Draft reply" })
vim.keymap.set("n", "<leader>mc", function() require("himalaya-ai").tldr() end, { desc = "AI: TL;DR + decision" })
```

Restart Neovim.

## Usage

### Reading Email

```vim
:Himalaya
```

Opens email list in telescope picker. Select message to read.

### Composing Email

- **New:** Press `gw` in email list
- **Reply:** Press `gr` when viewing message
- **Reply all:** Press `gR`
- **Forward:** Press `gf`

### AI-Powered Actions

Open an email, then:

- `<leader>ms` - Get AI summary
- `<leader>mt` - Extract todos
- `<leader>mr` - Generate reply draft
- `<leader>mc` - TL;DR + decision needed?

Results appear in right vsplit with action keybinds:

| Key | Action |
|-----|--------|
| `y` | Copy to clipboard |
| `s` | Save to file |
| `a` | Append to existing file |
| `o` | Send to Obsidian vault |
| `p` | Paste into himalaya reply |
| `r` | Re-run with edited prompt |
| `f` | Toggle fullscreen |
| `q`/`Esc` | Close |

## Configuration Options

### Plugin Variables

```vim
" Executable path (if not in PATH)
let g:himalaya_executable = '/usr/local/bin/himalaya'

" Folder picker (telescope, fzf, or native)
let g:himalaya_folder_picker = 'telescope'

" Default account
let g:himalaya_account = 'personal'
```

### Customize AI Backend

Edit `~/.config/himalaya-ai/config.lua` to switch between Claude and Gemini:

```lua
return { backend = "gemini" }  -- switches AI backend
```

### Customize AI Prompts

Edit `~/.config/nvim/lua/himalaya-ai.lua` and modify prompt strings in the `prompts` table. Or use `r` in the result split to re-run with an edited prompt on the fly.

## Troubleshooting

### Plugin not loading

Check plugin installed:
```vim
:Lazy
```

Verify `himalaya-vim` is listed and loaded.

### "himalaya not found"

```bash
# Verify installation
which himalaya

# Set explicit path in Neovim
let g:himalaya_executable = '/path/to/himalaya'
```

### AI commands fail

```bash
# Test claude CLI
echo "test email" | claude -p "summarize this"

# Check PATH in Neovim
:echo $PATH
```

### Telescope picker not working

Install telescope:
```lua
-- In lazy.nvim plugins
{ "nvim-telescope/telescope.nvim" }
```

### Performance issues

Disable AI wrapper if Claude is slow:
```lua
-- Comment out in init.lua
-- require('himalaya-ai').setup()
```

## Fallback: Terminal Mode

If himalaya-vim stalls (plugin maintenance risk as of Feb 2026), use flow-cli's `em` dispatcher in a terminal split:

```vim
:split | terminal em list
```

Navigate with `em` commands directly.

## Known Issues

- **Maintenance status:** himalaya-vim seeking new maintainers (Feb 2026)
- **AI latency:** Claude API calls may take 2-5s depending on email length
- **Attachment preview:** Limited support for binary attachments

## Related

- `em` dispatcher: Terminal-based email workflow
- flow-cli email docs: `docs/reference/DISPATCHERS.md`
- himalaya docs: https://pimalaya.org/himalaya/

---

**Last Updated:** 2026-02-11
