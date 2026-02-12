# Neovim Himalaya Integration — Orchestration Plan

> **Branch:** `feature/nvim-himalaya-integration`
> **Base:** `dev`
> **Worktree:** `~/.git-worktrees/flow-cli/feature-nvim-himalaya-integration`
> **Version Target:** v7.x (post em-dispatcher merge)

---

## Objective

Add Neovim/LazyVim email integration via himalaya-vim + a custom Lua AI wrapper. This is "Layer 0" in the hybrid email strategy — extending the terminal `em` dispatcher with editor-native keybinds and floating windows for AI actions.

---

## Prerequisites

- [ ] `feature/em-dispatcher` merged to `dev` (provides em AI patterns to port)
- [ ] himalaya CLI v1.1.0 configured and working
- [ ] himalaya-vim plugin installed in LazyVim

---

## Phase Overview

| Phase | Task | Priority | Status |
|-------|------|----------|--------|
| 1 | Install + configure himalaya-vim in LazyVim | High | Done |
| 2 | Write Lua AI wrapper (~50 lines) | High | Done |
| 3 | Test with real email account | High | Manual |
| 4 | Document keybinds + setup in flow-cli docs | Medium | Done |

---

## Phase 1: himalaya-vim Setup

### Tasks

- [x] Add himalaya-vim to lazy.nvim plugin spec
- [x] Configure `g:himalaya_executable` path
- [x] Configure `g:himalaya_folder_picker` (telescope or fzf)
- [ ] Verify envelope listing, read, reply, forward work
- [x] ~~Test mountaineer.nvim~~ (archived Jan 2024, not usable)

### Key Config

```lua
-- lazy.nvim plugin spec
{
  "pimalaya/himalaya-vim",
  dependencies = { "nvim-telescope/telescope.nvim" }, -- optional
  config = function()
    vim.g.himalaya_folder_picker = "telescope"
  end,
}
```

### himalaya-vim Keybinds (built-in)

| Key | Action |
|-----|--------|
| `gw` | Write new email |
| `gr` | Reply |
| `gR` | Reply all |
| `gf` | Forward |
| `ga` | Download attachment |
| `gC` | Copy to folder |
| `gM` | Move to folder |

---

## Phase 2: Lua AI Wrapper

### Tasks

- [x] Create `lua/himalaya-ai.lua` (~88 lines)
- [x] Implement `summarize()` — pipe buffer to `claude -p`
- [x] Implement `extract_todos()` — extract action items
- [x] Implement `draft_reply()` — generate reply draft
- [x] Display AI response in floating window
- [x] Add keybinds: `<leader>ms`, `<leader>mt`, `<leader>mr`, `<leader>mc`

### Design

```lua
-- Core pattern (same as em-ai.zsh but in Lua)
local function ai_action(prompt_prefix)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local email_text = table.concat(lines, "\n")

  vim.fn.jobstart({"claude", "-p", prompt_prefix .. "\n\n" .. email_text}, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      -- Display in floating window
    end,
  })
end
```

### AI Prompts (port from em-ai.zsh)

| Action | Keybind | Prompt |
|--------|---------|--------|
| Summarize | `<leader>ms` | "Summarize this email in 2-3 bullet points" |
| Extract todos | `<leader>mt` | "Extract action items as a checklist" |
| Draft reply | `<leader>mr` | "Draft a professional reply to this email" |
| Classify | `<leader>mc` | "Classify: urgent/action-needed/informational/spam" |

---

## Phase 3: Testing

- [ ] Read real emails via himalaya-vim
- [ ] Reply to a test email via himalaya-vim
- [ ] Summarize an email via AI wrapper
- [ ] Draft reply via AI wrapper
- [ ] Verify floating window display

---

## Phase 4: Documentation

- [ ] Add Neovim section to `docs/guides/EMAIL-DISPATCHER-GUIDE.md`
- [ ] Add himalaya-vim setup to `docs/guides/HIMALAYA-SETUP.md`
- [ ] Update `docs/specs/BRAINSTORM-himalaya-editor-plugin-2026-02-11.md` Layer 0 status

---

## Acceptance Criteria

- [ ] himalaya-vim loads in LazyVim without errors
- [ ] Can list, read, reply to emails from Neovim
- [ ] AI summarize works via `<leader>ms`
- [ ] AI draft reply works via `<leader>mr`
- [ ] Floating window displays AI response cleanly
- [ ] Setup documented for reproduction

---

## Risk Notes

- himalaya-vim is **seeking new maintainers** (Feb 2026) — plugin is functional but long-term ownership uncertain
- VimScript core (not Lua) — AI wrapper is separate Lua, not tightly coupled
- Fallback: `em` in Neovim terminal split if plugin stalls
