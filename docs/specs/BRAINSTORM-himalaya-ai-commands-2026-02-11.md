# BRAINSTORM: HimalayaAi Commands — Prompt Management & Settings

**Generated:** 2026-02-11
**Context:** `~/.config/nvim/lua/himalaya-ai.lua` + `~/.config/himalaya-ai/config.lua`
**Mode:** deep | feature | Duration: ~8 min

---

## Overview

Add an umbrella `:HimalayaAi <subcommand>` command to manage AI prompts and settings from within Neovim. Currently, prompt editing requires manually opening Lua files and settings require restarting Neovim. These commands make the workflow self-contained.

---

## Command Design

### Umbrella: `:HimalayaAi <subcommand>`

| Subcommand | Usage | Description |
|------------|-------|-------------|
| `status` | `:HimalayaAi status` | Dashboard: backend, vault, prompts, save_dir |
| `prompts` | `:HimalayaAi prompts` | List all prompts with name + preview |
| `edit` | `:HimalayaAi edit` | Open config.lua in vsplit |
| `validate` | `:HimalayaAi validate [name]` | Test-run prompt on current buffer or sample |
| `set` | `:HimalayaAi set <key> <value>` | Change setting (instant + persist) |

Tab-completion for all subcommands and arguments.

---

### 1. `:HimalayaAi status`

Opens a small float or inline notify showing current state:

```
HimalayaAi Status
==================
Backend:    claude (/Users/dt/.local/bin/claude) [OK]
Vault:      ~/Library/.../Knowledge_Base/Inbox
Save dir:   ~
Note format: structured
Config:     ~/.config/himalaya-ai/config.lua [loaded]

Prompts (4):
  summarize     "Summarize this email in 2-3 concise..."
  extract_todos "Extract all action items from this..."
  draft_reply   "Draft a professional reply to this..."
  tldr          "You are an executive assistant tri..."
```

**Design decisions:**
- Shows `[OK]` or `[MISSING]` next to backend binary (via `vim.fn.executable()`)
- Truncates prompt preview to ~40 chars
- Config path shows `[loaded]` or `[using defaults]`
- Opens in a nofile vsplit buffer (same pattern as result split), closeable with `q`

---

### 2. `:HimalayaAi prompts`

Same as the prompts section of `status`, but just the prompts. Quick glance:

```
Prompts
=======
  summarize      Summarize this email in 2-3 concise bullet points...
  extract_todos  Extract all action items from this email as a mark...
  draft_reply    Draft a professional reply to this email. Be conci...
  tldr           You are an executive assistant triaging email. Ana...

  [e] edit config   [v] validate prompt   [q] close
```

Keybinds in the prompts buffer:
- `e` — opens config.lua for editing (same as `:HimalayaAi edit`)
- `v` — prompts for which prompt to validate, then runs it
- `q` / `Esc` — close

---

### 3. `:HimalayaAi edit`

Opens `~/.config/himalaya-ai/config.lua` in a vertical split.

**Behavior:**
- `vim.cmd("vsplit " .. config_path)`
- If file doesn't exist, create it with defaults first
- After save (`:w`), auto-reload config: `M.config = load_config()`

**Auto-reload approach:**
- Set a `BufWritePost` autocmd on the config buffer
- On write, re-run `load_config()` and update `M.config`
- Notify: "Config reloaded"

---

### 4. `:HimalayaAi validate [prompt_name]`

Test-runs a prompt against email content to verify it works.

**Flow:**
1. If `prompt_name` given, use that prompt. Otherwise, `vim.ui.select()` picker.
2. Detect email source:
   - If current buffer looks like email (has `From:` or `Subject:` header), use it
   - Otherwise, use built-in sample email
3. Run the prompt against the email using current backend
4. Show result in the standard result split

**Built-in sample email** (hardcoded in module):

```
From: Sarah Chen <sarah@example.edu>
Subject: Re: Data science hiring — feedback needed by Friday
Date: Tue, 11 Feb 2026 09:42:00 -0700

Hi,

Following up on our meeting about the data science position.
The committee reviewed three candidates. Could you send me
your ranking by Friday COB?

Also, the budget was approved at the higher band ($95-105k).

Thanks,
Sarah
```

**Why this works:** Short enough to be fast, complex enough to test all 4 prompts (has action items, needs reply, has deadline, needs summary).

---

### 5. `:HimalayaAi set <key> <value>`

**Supported keys:**

| Key | Values | Example |
|-----|--------|---------|
| `backend` | `claude`, `gemini` | `:HimalayaAi set backend gemini` |
| `vault` | any path | `:HimalayaAi set vault ~/vaults/Work` |
| `save_dir` | any path | `:HimalayaAi set save_dir ~/Desktop` |
| `format` | `structured`, `simple` | `:HimalayaAi set format simple` |

**Flow for `set backend`:**
1. Check `vim.fn.executable(backends[value].cmd)`
2. If missing: warn "gemini not found at /opt/homebrew/bin/gemini" and abort
3. If found: update `M.config.backend` in memory
4. Persist: rewrite config.lua with updated value
5. Notify: "Backend switched to gemini (persisted)"

**Flow for other keys:**
1. Validate path exists (for vault/save_dir) or value is valid (for format)
2. Update `M.config` in memory
3. Persist to config.lua
4. Notify confirmation

**Config persistence approach:**
- Read current config.lua
- Pattern-match and replace the relevant line
- Write back
- This preserves comments and formatting

---

## Config.lua Evolution

Current config.lua only has settings. After this feature, it also holds custom prompts:

```lua
return {
  backend = "claude",
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

  -- Custom prompts (override defaults)
  prompts = {
    summarize = "Summarize this email in 2-3 concise bullet points...",
    -- add custom prompts here
  },
}
```

**Loading priority:** config.lua `prompts` table merges over built-in defaults (via `tbl_deep_extend`). If a user deletes a prompt from config, the built-in default is used.

---

## Tab Completion

```lua
vim.api.nvim_create_user_command("HimalayaAi", function(opts)
  -- dispatch to subcommands
end, {
  nargs = "+",
  complete = function(arg_lead, cmd_line, cursor_pos)
    local subcmds = { "status", "prompts", "edit", "validate", "set" }
    local set_keys = { "backend", "vault", "save_dir", "format" }
    local backends = { "claude", "gemini" }
    local formats = { "structured", "simple" }
    local prompt_names = { "summarize", "extract_todos", "draft_reply", "tldr" }
    -- context-aware completion based on position
  end,
})
```

---

## Quick Wins (< 30 min each)

1. `:HimalayaAi status` — simplest, just format + display config values
2. `:HimalayaAi edit` — one-liner (vsplit + BufWritePost autocmd)
3. `:HimalayaAi set backend <value>` — in-memory + pattern-replace in config.lua
4. Tab completion for all subcommands

## Medium Effort (1-2 hours)

5. `:HimalayaAi prompts` — interactive buffer with e/v/q keybinds
6. `:HimalayaAi validate` — reuse existing `run_ai` machinery with prompt picker
7. `:HimalayaAi set` for vault/save_dir/format (path validation + persist)
8. Config auto-reload on `:HimalayaAi edit` save

## Long-term (Future sessions)

9. Custom prompt creation (`:HimalayaAi add-prompt <name>`)
10. Prompt history (track which prompts work best)
11. Per-account prompt overrides (work vs personal email)

---

## Recommended Path

Start with quick wins 1-4 (status, edit, set backend, tab completion) since they deliver the most value with least code. Then add validate (#6) and full set (#7) in a second pass. The prompts buffer (#5) is nice-to-have since status already shows them.

## Implementation Order

1. Register `:HimalayaAi` command with subcommand dispatch + tab completion
2. `status` subcommand (read-only, lowest risk)
3. `edit` subcommand (vsplit + auto-reload)
4. `set backend` with binary verification
5. `set vault/save_dir/format` with path validation
6. `validate` with buffer detection + sample fallback
7. `prompts` interactive buffer
8. Config prompts merge (allow custom prompts in config.lua)

---

**Last Updated:** 2026-02-11
