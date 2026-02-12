# Himalaya Email in Neovim

Neovim integration for himalaya email client with AI-powered email assistance.

## Quick Reference

| Action | Keybind | Description |
|--------|---------|-------------|
| **Email Actions** | | |
| Open email list | `<leader>eM` | Launch Himalaya |
| Write new email | `gw` | Compose new message |
| Reply | `gr` | Reply to sender |
| Reply all | `gR` | Reply to all recipients |
| Forward | `gf` | Forward message |
| Add attachment | `ga` | Attach file to message |
| Copy message | `gC` | Copy to another folder |
| Move message | `gM` | Move to another folder |
| **AI Actions** | | |
| Summarize email | `<leader>ms` | AI summary in split |
| Extract todos | `<leader>mt` | Parse action items |
| Draft reply | `<leader>mr` | AI-generated reply (asks for instructions) |
| TL;DR + decision | `<leader>mc` | One-line summary + action needed? |
| Compose email | `<leader>mw` | AI-composed email (asks for topic) |
| Prompt picker | `<leader>mp` | Select any AI action from menu |
| AI Status | `<leader>mi` | Show current AI settings |
| **Post-AI Result Buffer** | | |
| Edit result | `e` | Toggle editable (edits apply to y/s/a/o/p) |
| Revise | `c` | AI-revise current output with instruction |
| Next action | `n` | Chain to another AI action |
| Send to todo | `t` | Send to Obsidian daily note or Reminders |
| Copy to clipboard | `y` | Copy result text |
| Save to file | `s` | Save with path prompt |
| Append to file | `a` | Append to existing file |
| Send to Obsidian | `o` | Save as Obsidian note |
| Paste into reply | `p` | Paste into himalaya compose buffer |
| Re-run prompt | `r` | Re-run with edited prompt |
| Toggle fullscreen | `f` | Expand/collapse split |
| Close | `q`/`Esc` | Close result split |

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
    init = function()
      -- Find himalaya binary
      local paths = {
        "/opt/homebrew/bin/himalaya",
        vim.fn.expand("~/.cargo/bin/himalaya"),
        "himalaya",
      }
      for _, p in ipairs(paths) do
        if vim.fn.executable(p) == 1 then
          vim.g.himalaya_executable = p
          break
        end
      end

      vim.g.himalaya_folder_picker = "native"
      vim.g.himalaya_always_confirm = 1

      -- Width safety patch (prevents comfy-table UTF-8 crash)
      local email_vim = vim.fn.stdpath("data")
        .. "/lazy/himalaya-vim/autoload/himalaya/domain/email.vim"
      if vim.fn.filereadable(email_vim) == 1 then
        local lines = vim.fn.readfile(email_vim)
        for i, line in ipairs(lines) do
          if line:find("return width - numwidth - foldwidth - signwidth", 1, true)
            and not line:find("usable", 1, true) then
            lines[i] = "  let usable = width - numwidth - foldwidth - signwidth - 4\n"
              .. "  return max([40, (usable / 2) * 2])"
            vim.fn.writefile(lines, email_vim)
            break
          end
        end
      end
    end,
    config = function() end,
    keys = {
      {
        "<leader>eM",
        function()
          local ok, err = pcall(vim.cmd, "Himalaya")
          if not ok then
            local msg = "himalaya-vim error:\n" .. tostring(err)
            vim.fn.setreg("+", msg)
            vim.notify(msg .. "\n\n(copied to clipboard)", vim.log.levels.ERROR)
          end
        end,
        desc = "Open Himalaya (Email)",
      },
    },
  },
}
```

### 2. Add AI Wrapper Module

Create `~/.config/nvim/lua/himalaya-ai.lua` (~980 lines). The module:

- Pipes buffer content to AI backend (claude/gemini) asynchronously via `vim.fn.jobstart()`
- Interactive prompts: `draft_reply` asks for instructions, `compose` asks for topic
- Displays results in a configurable split/tab with 13 action keybinds
- Editable results: press `e` to edit, then `y`/`s`/`a`/`o`/`p` pick up your changes
- Action chaining: press `n` to run another AI action on the same email or result
- Revision: press `c` to revise the AI output with new instructions

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
  todo_target = "ask",  -- "obsidian" | "reminders" | "ask"
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
vim.keymap.set("n", "<leader>mw", function() require("himalaya-ai").compose() end, { desc = "AI: Compose email" })
vim.keymap.set("n", "<leader>mp", function()
  local hai = require("himalaya-ai")
  vim.ui.select(
    { "Summarize", "Extract Todos", "Draft Reply", "TL;DR", "Compose" },
    { prompt = "AI Action:" },
    function(choice)
      if not choice then return end
      local actions = {
        Summarize = hai.summarize,
        ["Extract Todos"] = hai.extract_todos,
        ["Draft Reply"] = hai.draft_reply,
        ["TL;DR"] = hai.tldr,
        Compose = hai.compose,
      }
      actions[choice]()
    end
  )
end, { desc = "AI: Prompt picker" })
vim.keymap.set("n", "<leader>mi", function() vim.cmd("HimalayaAi status") end, { desc = "AI: Status info" })
```

Restart Neovim.

## Usage

### Reading Email

```vim
:Himalaya
```

Opens email list with native folder picker. Navigate and select to read.

### Composing Email

- **New:** Press `gw` in email list
- **Reply:** Press `gr` when viewing message
- **Reply all:** Press `gR`
- **Forward:** Press `gf`

### AI-Powered Actions

Open an email, then:

- `<leader>ms` - Get AI summary
- `<leader>mt` - Extract todos
- `<leader>mr` - Generate reply draft (asks for instructions first)
- `<leader>mc` - TL;DR + decision needed?
- `<leader>mw` - Compose new email (asks for topic first)
- `<leader>mp` - Pick any action from a menu

### Working with AI Results

Results appear in a split with 13 keybinds. Common workflows:

**Edit and copy:**
`<leader>ms` (summarize) -> `e` (edit) -> tweak text -> `y` (copy)

**Chain actions:**
`<leader>mc` (TL;DR) -> `n` (next) -> Draft Reply -> choose source

**Revise output:**
`<leader>mr` (draft reply) -> `c` (revise) -> "make it more formal"

**Send to todo:**
`<leader>mt` (extract todos) -> `t` -> "Action items only" -> "Obsidian daily note"

## Configuration Options

### Plugin Variables

```vim
" Executable path (if not in PATH)
let g:himalaya_executable = '/usr/local/bin/himalaya'

" Folder picker (telescope, fzflua, fzf, or native)
let g:himalaya_folder_picker = 'native'

" Default account
let g:himalaya_account = 'personal'
```

### Customize AI Backend

Edit `~/.config/himalaya-ai/config.lua` to switch between Claude and Gemini:

```lua
return { backend = "gemini" }  -- switches AI backend
```

### Runtime Settings (`:HimalayaAi set`)

Change settings without editing config files:

| Setting | Values | Default | Description |
|---------|--------|---------|-------------|
| `backend` | `claude`, `gemini` | `claude` | AI backend for prompts |
| `vault` | path string | `~/Documents/Obsidian/...` | Obsidian vault for notes |
| `save_dir` | path string | `~` | Directory for standalone file saves |
| `format` | `structured`, `simple` | `structured` | AI output format |
| `result_display` | `split`, `tab` | `split` | Where AI results appear |
| `todo_target` | `obsidian`, `reminders`, `ask` | `ask` | Where `t` keybind sends todos |

```vim
:HimalayaAi set result_display tab   " Results open in new tab
:HimalayaAi set result_display split  " Results open in split (default)
:HimalayaAi set backend gemini        " Switch to Gemini
:HimalayaAi set todo_target obsidian  " Always send todos to Obsidian
:HimalayaAi status                    " See all current settings
```

All changes are persisted to `~/.config/himalaya-ai/config.lua`.

### Customize AI Prompts

Edit prompts via `:HimalayaAi prompts` (interactive browser) or `r` in a result split to re-run with an edited prompt on the fly.

## Width Safety Patch

The himalaya-vim plugin calculates exact terminal width for email list formatting. The upstream `comfy-table` Rust crate can crash when truncating multi-byte UTF-8 characters at the exact boundary.

The plugin spec includes an idempotent patch that:

- Subtracts 4 columns from the calculated width
- Rounds to an even number (prevents 2-byte char splits)
- Clamps to minimum 40 columns
- Re-applies automatically after plugin updates

If you still see crashes, increase the margin in `plugins/himalaya.lua` (change `- 4` to `- 6`).

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

### Folder picker not working

Set picker to `native` (no dependencies) or install telescope/fzf-lua:
```vim
let g:himalaya_folder_picker = 'native'    " Built-in, no deps
let g:himalaya_folder_picker = 'telescope' " Requires telescope.nvim
let g:himalaya_folder_picker = 'fzflua'    " Requires fzf-lua
```

### comfy-table crash (UTF-8 panic)

If you see `assertion failed: self.is_char_boundary(new_len)`, the width safety patch may need a larger margin. Edit `plugins/himalaya.lua` and increase the subtraction value.

### Performance issues

Disable AI wrapper if Claude is slow:
```lua
-- Comment out in init.lua
-- require('himalaya-ai').setup()
```

## Known Issues

- **Maintenance status:** himalaya-vim seeking new maintainers (Feb 2026)
- **AI latency:** Claude API calls may take 2-5s depending on email length
- **Attachment preview:** Limited support for binary attachments
- **comfy-table crash:** Upstream bug with UTF-8 truncation (mitigated by width patch)

## Related

- himalaya docs: https://pimalaya.org/himalaya/
- [Quick Reference Card](../reference/REFCARD-HIMALAYA.md)

---

**Last Updated:** 2026-02-11
