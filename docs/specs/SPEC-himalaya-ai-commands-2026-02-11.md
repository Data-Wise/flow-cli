# SPEC: HimalayaAi Commands — Prompt Management & Settings

**Status:** draft
**Created:** 2026-02-11
**From Brainstorm:** `docs/specs/BRAINSTORM-himalaya-ai-commands-2026-02-11.md`
**Type:** Full Spec
**Files:** `~/.config/nvim/lua/himalaya-ai.lua`, `~/.config/himalaya-ai/config.lua`

---

## Overview

Add `:HimalayaAi <subcommand>` umbrella command to manage AI prompts and settings from within Neovim. Five subcommands: `status`, `prompts`, `edit`, `validate`, `set`. All settings persist to `~/.config/himalaya-ai/config.lua` and take effect immediately.

---

## Primary User Story

**As a** Neovim user who uses himalaya-ai for email triage,
**I want to** view, edit, test, and switch AI settings from within Neovim,
**So that** I don't need to manually edit config files or restart Neovim to change prompts or backends.

### Acceptance Criteria

- [ ] `:HimalayaAi status` shows dashboard with backend, vault, prompts, config state
- [ ] `:HimalayaAi prompts` lists all prompt names with preview text
- [ ] `:HimalayaAi edit` opens config.lua in vsplit, auto-reloads on save
- [ ] `:HimalayaAi validate [name]` test-runs prompt against current buffer or sample email
- [ ] `:HimalayaAi set backend gemini` switches backend with binary verification + persist
- [ ] `:HimalayaAi set vault <path>` changes Obsidian vault path + persist
- [ ] `:HimalayaAi set save_dir <path>` changes save directory + persist
- [ ] `:HimalayaAi set format structured|simple` changes note format + persist
- [ ] Tab completion works for all subcommands and arguments
- [ ] Custom prompts in config.lua override built-in defaults

---

## Secondary User Stories

**As a** user testing different AI backends,
**I want to** quickly toggle between Claude and Gemini,
**So that** I can compare output quality without editing files.

**As a** user refining prompts,
**I want to** edit a prompt and immediately test it against a real email,
**So that** I can iterate on prompt quality in a tight feedback loop.

---

## Architecture

```
:HimalayaAi <subcommand>
    |
    +-- status     --> read M.config --> format + display in split
    +-- prompts    --> read prompts table --> interactive buffer (e/v/q keys)
    +-- edit       --> vsplit config.lua --> BufWritePost auto-reload
    +-- validate   --> select prompt --> detect email source --> run_ai --> result split
    +-- set        --> parse key/value --> validate --> update M.config --> persist to config.lua
```

**Config loading flow:**
```
config.lua (user overrides)
    |
    v
tbl_deep_extend(defaults, config)  -->  M.config  (runtime)
    ^                                       |
    |                                       v
    +--- :HimalayaAi set (writes back) <--- M.config update
```

---

## API Design

N/A — This is a Neovim user command, not an HTTP API.

### Command Interface

```
:HimalayaAi status
:HimalayaAi prompts
:HimalayaAi edit
:HimalayaAi validate [prompt_name]
:HimalayaAi set <key> <value>
```

**Argument table:**

| Subcommand | Required args | Optional args | Tab-complete values |
|------------|---------------|---------------|---------------------|
| `status` | none | none | — |
| `prompts` | none | none | — |
| `edit` | none | none | — |
| `validate` | none | `prompt_name` | summarize, extract_todos, draft_reply, tldr |
| `set` | `key`, `value` | none | key: backend/vault/save_dir/format; value: context-dependent |

---

## Data Models

N/A — No database changes. Config is a Lua table persisted as a `.lua` file.

### Config Schema (Extended)

```lua
return {
  backend = "claude",                    -- string: "claude" | "gemini"
  backends = {
    claude = { cmd = "...", flag = "..." }, -- table: { cmd: string, flag: string }
    gemini = { cmd = "...", flag = "..." },
  },
  obsidian = {
    vault = "...",                        -- string: path (~ expanded)
    subfolder = "Inbox",                  -- string: folder name
    format = "structured",               -- string: "structured" | "simple"
  },
  save_dir = "~",                        -- string: path (~ expanded)
  prompts = {                            -- table (optional, overrides defaults)
    summarize = "...",
    extract_todos = "...",
    draft_reply = "...",
    tldr = "...",
  },
}
```

---

## Dependencies

- Neovim 0.9+ (for `vim.api.nvim_create_user_command`)
- Existing `himalaya-ai.lua` module (current v2)
- `~/.config/himalaya-ai/config.lua` (created by previous work)

No new external dependencies.

---

## UI/UX Specifications

### Status Dashboard Layout

```
HimalayaAi Status
==================
Backend:     claude (/Users/dt/.local/bin/claude) [OK]
Vault:       ~/Library/.../Knowledge_Base/Inbox
Save dir:    ~
Note format: structured
Config:      ~/.config/himalaya-ai/config.lua [loaded]

Prompts (4):
  summarize      Summarize this email in 2-3 concise...
  extract_todos  Extract all action items from this e...
  draft_reply    Draft a professional reply to this e...
  tldr           You are an executive assistant triag...

[q] close
```

- Opens in `botright vnew` (same pattern as result split)
- `buftype=nofile`, `filetype=markdown`, closeable with `q`
- Backend shows `[OK]` if `vim.fn.executable()` passes, `[MISSING]` if not
- Config shows `[loaded]` or `[using defaults]`
- Prompt previews truncated to 40 chars

### Prompts Buffer Layout

```
HimalayaAi Prompts
====================
  summarize      Summarize this email in 2-3 concise...
  extract_todos  Extract all action items from this e...
  draft_reply    Draft a professional reply to this e...
  tldr           You are an executive assistant triag...

[e] edit config   [v] validate   [q] close
```

- `e` opens config.lua in split (same as `:HimalayaAi edit`)
- `v` prompts which prompt to test, then runs validation
- `q` / `Esc` closes

### Validate Flow

1. If `prompt_name` provided: use that prompt
2. Else: `vim.ui.select(prompt_names)` picker
3. Detect email source:
   - Scan current buffer lines 1-5 for `From:` or `Subject:` headers
   - If found: use current buffer content
   - Else: use built-in sample email
4. Run AI via existing `run_ai` / `_run_ai_custom` machinery
5. Show result in standard result split

### Set Command Behavior

| Key | Validation | Example |
|-----|-----------|---------|
| `backend` | `vim.fn.executable(cmd)` must pass | `:HimalayaAi set backend gemini` |
| `vault` | `vim.fn.isdirectory()` after expand | `:HimalayaAi set vault ~/vaults/Work` |
| `save_dir` | `vim.fn.isdirectory()` after expand | `:HimalayaAi set save_dir ~/Desktop` |
| `format` | Must be `structured` or `simple` | `:HimalayaAi set format simple` |

On success: update `M.config` + persist to config.lua + notify confirmation.
On failure: notify error, do not change config.

### Config Persistence Strategy

When `:HimalayaAi set` writes to config.lua:
1. Read current file content
2. Parse as Lua table (via `dofile`)
3. Update the relevant key in the parsed table
4. Serialize table back to Lua source
5. Write file

**Serializer:** Simple key-value rewriter. For flat keys (`backend`, `save_dir`), pattern-match the line. For nested keys (`obsidian.vault`, `obsidian.format`), match within the nested block.

### Accessibility

- All commands tab-completable
- All interactive buffers closeable with `q` or `Esc`
- `vim.notify()` feedback for every action
- Error messages are actionable ("gemini not found at /opt/homebrew/bin/gemini")

---

## Open Questions

1. Should `:HimalayaAi set` support adding new backends (e.g., `ollama`)? — Deferred to future.
2. Should custom prompts be addable via `:HimalayaAi add-prompt <name>`? — Deferred; edit config.lua directly for now.

---

## Review Checklist

- [ ] All 5 subcommands implemented and working
- [ ] Tab completion covers subcommands + arguments
- [ ] Binary verification for backend switching
- [ ] Config persistence survives Neovim restart
- [ ] Auto-reload on config edit save
- [ ] Built-in sample email for validate fallback
- [ ] Custom prompts in config.lua merge over defaults
- [ ] All buffers closeable with q/Esc
- [ ] Error states handled gracefully (missing binary, bad path, empty buffer)

---

## Implementation Notes

### Key Design Decisions

1. **Single umbrella command** — `:HimalayaAi` with subcommands, not separate commands. Reduces namespace pollution, enables tab-completion discovery.
2. **Config.lua as single source of truth** — prompts + settings in one file. No separate prompts.lua.
3. **Instant + persist** — all `:HimalayaAi set` changes take effect immediately AND write to disk. No restart needed.
4. **Reuse existing patterns** — status/prompts buffers use the same `open_result` pattern (vsplit, nofile, markdown, q to close).

### Implementation Order

| # | Task | Effort | Depends on |
|---|------|--------|-----------|
| 1 | Register `:HimalayaAi` + subcommand dispatch + tab completion | 30 min | — |
| 2 | `status` subcommand | 20 min | #1 |
| 3 | `edit` subcommand + BufWritePost auto-reload | 20 min | #1 |
| 4 | `set backend` with binary verification + persist | 30 min | #1 |
| 5 | `set vault/save_dir/format` with validation + persist | 30 min | #4 |
| 6 | Config prompts merge (custom prompts from config.lua) | 20 min | #3 |
| 7 | `validate` with buffer detection + sample fallback | 30 min | #6 |
| 8 | `prompts` interactive buffer with e/v/q keybinds | 30 min | #7 |

### Built-in Sample Email

```
From: Sarah Chen <sarah@example.edu>
Subject: Re: Data science hiring — feedback needed by Friday
Date: Tue, 11 Feb 2026 09:42:00 -0700

Hi,

Following up on our meeting about the data science position.
The committee reviewed three candidates and needs our ranking.
Could you review the materials and send me your top pick with
a brief justification by Friday COB?

Budget approved at $95-105k. Shared drive link below.

Thanks,
Sarah

P.S. Department retreat confirmed for March 15 — can you check
if the stats lab is available?
```

---

## History

| Date | Change |
|------|--------|
| 2026-02-11 | Initial spec from brainstorm |

---

**Last Updated:** 2026-02-11
