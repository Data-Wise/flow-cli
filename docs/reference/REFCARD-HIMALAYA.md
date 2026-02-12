---
tags:
  - reference
  - email
  - neovim
---

# Himalaya Quick Reference

Quick reference for himalaya email in Neovim with AI actions.

## Launch

| Key | Action |
|-----|--------|
| `<leader>eM` | Open Himalaya email list |
| `:Himalaya` | Same (command mode) |

## Email Navigation

| Key | Action |
|-----|--------|
| `j`/`k` | Move up/down in list |
| `Enter` | Open selected email |
| `dd` | Delete email |
| `gw` | Compose new message |
| `gr` | Reply to sender |
| `gR` | Reply to all |
| `gf` | Forward message |
| `ga` | Add attachment |
| `gC` | Copy to folder |
| `gM` | Move to folder |

## AI Actions (`<leader>m`)

| Key | Action | Input? |
|-----|--------|--------|
| `<leader>ms` | Summarize email | No |
| `<leader>mt` | Extract action items | No |
| `<leader>mr` | Draft reply | Yes (instructions) |
| `<leader>mc` | TL;DR + decision | No |
| `<leader>mw` | Compose email | Yes (topic) |
| `<leader>mp` | Prompt picker menu | Picker |
| `<leader>mi` | Show AI status | No |

## Result Buffer Actions

After an AI action completes, a result split opens with these keybinds:

### Edit & Iterate

| Key | Action | Details |
|-----|--------|---------|
| `e` | Toggle editable | Make buffer writable; edits apply to y/s/a/o/p |
| `c` | Revise | Prompt for instruction, AI revises current output |
| `n` | Next action | Chain to another AI action (pick action + source) |
| `r` | Re-run | Re-run with edited prompt (needs prompt context) |

### Export & Save

| Key | Action | Details |
|-----|--------|---------|
| `y` | Copy to clipboard | Copies current buffer text to `+` register |
| `s` | Save to file | Prompts for file path |
| `a` | Append to file | Prompts for file path, appends |
| `o` | Save to Obsidian | Saves as note in configured vault |
| `p` | Paste into reply | Yanks to `"` register for himalaya compose |
| `t` | Send to todo | Obsidian daily note or macOS Reminders |

### Display

| Key | Action |
|-----|--------|
| `f` | Toggle fullscreen |
| `q`/`Esc` | Close result split |

## Commands

| Command | Action |
|---------|--------|
| `:HimalayaAi status` | Show current settings |
| `:HimalayaAi set <key> <val>` | Change setting at runtime |
| `:HimalayaAi prompts` | Browse/edit AI prompts |

## Settings

| Key | Values | Default |
|-----|--------|---------|
| `backend` | `claude`, `gemini` | `claude` |
| `result_display` | `split`, `tab` | `split` |
| `todo_target` | `obsidian`, `reminders`, `ask` | `ask` |
| `format` | `structured`, `simple` | `structured` |
| `vault` | path | `~/...Knowledge_Base` |
| `save_dir` | path | `~` |

## Common Workflows

```text
Read email -> <leader>ms -> y (copy summary)
Read email -> <leader>mr -> "be firm" -> c -> "shorter" -> p (paste reply)
Read email -> <leader>mc -> n -> Draft Reply -> use original email
Read email -> <leader>mt -> t -> Action items only -> Obsidian
Any time   -> <leader>mw -> "schedule meeting" -> e -> edit -> s (save)
```

---

**See also:** [Full Setup Guide](../guides/HIMALAYA-NVIM-SETUP.md)
