---
tags:
  - tutorial
  - email
  - neovim
  - ai
---

# Tutorial: Email in Neovim with Himalaya + AI

Read, compose, and process emails without leaving Neovim. AI actions summarize, extract todos, draft replies, and compose messages.

**Time:** 15 minutes | **Level:** Intermediate | **Requires:** himalaya CLI, Claude CLI, LazyVim

## What You'll Learn

1. Opening and reading email in Neovim
2. Using AI to process emails (summarize, draft, extract)
3. Working with AI results (edit, chain, revise, export)
4. Customizing the AI workflow

## Step 1: Open Email

Press `<leader>eM` or run `:Himalaya` to open the email list.

Navigate with `j`/`k`, press `Enter` to read a message.

**Tip:** The first load may take a few seconds while himalaya fetches envelopes from your IMAP server.

## Step 2: AI Summary

With an email open, press `<leader>ms` to get an AI summary.

A result split opens at the bottom with the summary. You'll see a status line showing all available keybinds.

**Try these on the result:**

- `y` - copy the summary to clipboard
- `f` - toggle fullscreen to read it better
- `q` - close when done

## Step 3: Draft a Reply

Press `<leader>mr` on any email. You'll be prompted:

```
Reply instructions (Enter=default):
```

Type your instruction (e.g., "accept but suggest next Thursday instead") and press Enter. The AI generates a reply shaped by your instruction.

**Working with the draft:**

1. Press `e` to make the buffer editable
2. Tweak the text with normal vim motions
3. Press `p` to paste into a himalaya reply compose buffer
4. Or press `c` and type "make it shorter" to have AI revise

## Step 4: Chain Actions

Press `<leader>mc` for a TL;DR, then press `n` in the result buffer.

You'll see two pickers:

1. **Next AI action:** Summarize, Extract Todos, Draft Reply, TL;DR, Compose
2. **Use as input:** Original email or Current AI result

This lets you chain actions — e.g., TL;DR first to understand the email, then draft a reply.

## Step 5: Extract Action Items

Press `<leader>mt` to extract todos from an email.

Then press `t` to send them somewhere:

1. Pick content: "Full text" or "Action items only"
2. Pick destination: "Obsidian daily note" or "macOS Reminders"

Action items only filters lines starting with `-`, `*`, or numbered items.

## Step 6: Compose a New Email

Press `<leader>mw` anywhere. You'll be prompted:

```
What to write about:
```

Type your topic (e.g., "reschedule tomorrow's meeting to Friday 2pm") and the AI generates a full email.

## Step 7: The Prompt Picker

Can't remember which keybind does what? Press `<leader>mp` to see a menu of all AI actions. Select one and it runs.

## Step 8: Check Settings

Press `<leader>mi` (or `:HimalayaAi status`) to see your current configuration:

- Which AI backend is active (claude/gemini)
- Where results appear (split/tab)
- Obsidian vault path
- Todo target preference

Change settings at runtime:

```vim
:HimalayaAi set backend gemini
:HimalayaAi set result_display tab
:HimalayaAi set todo_target obsidian
```

## Architecture Overview

The integration has three layers:

```
himalaya CLI (Rust)           Email protocol (IMAP/SMTP)
    |
himalaya-vim (VimScript)      Buffer management, keybinds, job control
    |
himalaya-ai.lua (Lua)         AI actions, result display, chaining
```

### himalaya-ai.lua Module Structure

| Component | Purpose |
|-----------|---------|
| `load_config()` | Loads `~/.config/himalaya-ai/config.lua` with fallback defaults |
| `prompts` table | System prompts for each AI action |
| `get_email_text()` | Extracts email content from current buffer |
| `open_result()` | Creates result buffer with 13 keybinds |
| `get_buf_text()` | Reads buffer dynamically (picks up edits) |
| `run_ai()` / `run_ai_with_input()` | Pipes email + prompt to AI backend via `jobstart()` |
| `M._run_ai_custom()` | Internal API for chaining and revision |
| `cmd_set()` / `cmd_status()` | Runtime settings management |
| `persist_config()` | Writes settings changes back to config file |

### Width Safety Patch

The plugin spec patches `s:bufwidth()` in himalaya-vim to prevent a crash in the `comfy-table` Rust crate. The crash occurs when the table formatter truncates multi-byte UTF-8 characters at the exact terminal width boundary.

The patch subtracts 4 columns and rounds to an even number. It's idempotent (safe to run repeatedly) and re-applies after plugin updates.

### Config File Location

```
~/.config/himalaya-ai/config.lua     AI backend, prompts, Obsidian settings
~/.config/himalaya/config.toml       Email account (IMAP/SMTP)
~/.config/nvim/lua/plugins/himalaya.lua   LazyVim plugin spec + width patch
~/.config/nvim/lua/himalaya-ai.lua        AI module (~980 lines)
~/.config/nvim/lua/config/keymaps.lua     Global <leader>m keybinds
```

## FAQ

### Can I use Gemini instead of Claude?

Yes. Run `:HimalayaAi set backend gemini`. Requires `gemini` CLI in PATH.

### Where do Obsidian notes go?

Configured via `obsidian.vault` and `obsidian.subfolder` in config. Default: `Knowledge_Base/Inbox/`.

### What happens if I edit the result buffer?

Press `e` to toggle editable. All export keybinds (`y`, `s`, `a`, `o`, `p`) read the buffer dynamically via `get_buf_text()`, so your edits are picked up automatically.

### Can I chain unlimited actions?

Yes. Each result buffer gets all 13 keybinds including `n` (next action). You can chain indefinitely: TL;DR -> Draft Reply -> Revise -> Revise again -> Copy.

### What does the `n` (next) keybind's source picker do?

When you press `n`, you pick an action and then choose the input source:
- **Original email** - runs the new action on the email you started with
- **Current AI result** - runs the new action on the AI output you're viewing

### How do I customize prompts?

Run `:HimalayaAi prompts` for an interactive browser. Or press `r` in a result split to re-run with an edited prompt. For permanent changes, edit the `prompts` table in `himalaya-ai.lua`.

### What if himalaya crashes with a UTF-8 error?

The width safety patch in `plugins/himalaya.lua` handles this. If crashes persist, increase the margin (change `- 4` to `- 6` in the patch). This is an upstream bug in the `comfy-table` Rust crate.

## Next Steps

- [Quick Reference Card](../reference/REFCARD-HIMALAYA.md) - all keybinds at a glance
- [Neovim Setup Guide](../guides/HIMALAYA-NVIM-SETUP.md) - installation and configuration
- [CLI Email Tutorial](../guides/EMAIL-TUTORIAL.md) - terminal email with `em` dispatcher
- [himalaya documentation](https://pimalaya.org/himalaya/) - CLI reference
