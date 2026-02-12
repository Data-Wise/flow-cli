# Interactive AI Prompts — Brainstorm

**Generated:** 2026-02-11
**Context:** himalaya-ai.lua v2, feature/nvim-himalaya-integration

## Overview

Make AI actions prompt for user instructions before running, so the user's intent shapes the AI output. Currently all actions fire a static prompt — this adds a `vim.ui.input` step that lets the user inject context like "be firm about the deadline" or "focus on budget items".

## Current Flow

```
<leader>ms → static prompt → AI → result split
<leader>mr → static prompt → AI → result split
```

## Proposed Flow

```
<leader>ms → vim.ui.input("Instructions (Enter=default):") → merge with prompt → AI → result split
<leader>mr → vim.ui.input("Reply tone/instructions:") → merge with prompt → AI → result split
```

## Options

### Option A: Inline Append (Simplest)

**Effort:** ⚡ Quick (< 30 min)

Append user input to existing prompt:
```lua
local base = prompts[key]
if instructions ~= "" then
  prompt = base .. "\n\nAdditional instructions: " .. instructions
else
  prompt = base
end
```

**Pros:** Minimal code change (~15 lines), works immediately
**Cons:** No structured guidance to the AI, user input just tacked on

### Option B: Template with Slot (Recommended)

**Effort:** ⚡ Quick (< 30 min)

Restructure prompts as templates with an `{instructions}` slot:
```lua
draft_reply = table.concat({
  "Draft a professional reply to this email.",
  "{instructions}",          -- replaced or removed
  "Format as markdown."
}, "\n"),
```

When user provides input: slot filled. When empty: slot removed.

**Pros:** Clean separation, AI sees instructions in context, easy to extend
**Cons:** Requires updating prompt strings (one-time)

### Option C: Two-Phase Prompt (Most Powerful)

**Effort:** 🔧 Medium (1-2 hours)

First prompt analyzes the email, second prompt uses analysis + user instructions:
```
Phase 1: "Analyze this email: key points, sender intent, required response"
Phase 2: "Given this analysis + user instructions, draft reply"
```

**Pros:** Best quality output, AI has full context
**Cons:** 2x API calls, slower, more complex

## Scope: Which Actions Get Input

### Tier 1: Always Ask (High-value input)

| Action | Default hint | Why |
|--------|-------------|-----|
| `draft_reply` | "Reply tone/focus:" | Tone/strategy varies per email |
| `compose` (NEW) | "What to write:" | Freeform compose needs intent |

### Tier 2: Ask with Smart Default (Sometimes useful)

| Action | Default hint | Why |
|--------|-------------|-----|
| `summarize` | "Focus on:" | Sometimes want budget-only or action-only summary |
| `extract_todos` | "Filter/priority:" | May want "only deadlines" or "only my items" |
| `tldr` | "Context:" | May want "I'm the manager" vs "I'm the student" |

### Tier 3: Configurable (User decides)

Add `M.config.ask_before` table:
```lua
ask_before = {
  draft_reply = true,   -- always ask
  compose = true,       -- always ask
  summarize = false,    -- skip by default
  extract_todos = false,
  tldr = false,
},
```

User can toggle via `:HimalayaAi set ask_before.summarize true`

## Implementation: Recommended Path (Option B + Tier Config)

### Core Change: `run_ai_with_input()`

```lua
-- New wrapper around run_ai that optionally asks for input
local function run_ai_with_input(prompt_key, title, hint)
  local should_ask = M.config.ask_before and M.config.ask_before[prompt_key]
  if should_ask == nil then
    -- Default: ask for draft_reply and compose, skip others
    should_ask = (prompt_key == "draft_reply" or prompt_key == "compose")
  end

  if should_ask then
    vim.ui.input({ prompt = hint or "Instructions (Enter=skip): " }, function(input)
      if input == nil then return end -- cancelled with Esc
      run_ai(prompt_key, title, input)  -- pass instructions to run_ai
    end)
  else
    run_ai(prompt_key, title, nil)
  end
end
```

### Prompt Merge in `run_ai()`

```lua
local function run_ai(prompt_key, title, instructions)
  -- ... existing code ...
  local prompt_text = get_prompts()[prompt_key]

  -- Merge user instructions into prompt
  if instructions and instructions ~= "" then
    prompt_text = prompt_text .. "\n\nUser instructions: " .. instructions
  end
  -- ... rest of existing code ...
end
```

### Per-Action Hints

```lua
local input_hints = {
  draft_reply = "Reply tone/instructions: ",
  compose = "What to write about: ",
  summarize = "Focus on (Enter=general): ",
  extract_todos = "Filter (Enter=all): ",
  tldr = "Context (Enter=default): ",
}
```

### New Compose Action

```lua
function M.compose()
  vim.ui.input({ prompt = "What to write: " }, function(input)
    if not input or input == "" then
      vim.notify("Compose cancelled", vim.log.levels.WARN)
      return
    end
    local prompt = "Write a professional email about: " .. input
      .. "\nFormat as markdown. Be concise and friendly."
    -- Use current buffer as context (if it's an email, use as reference)
    M._run_ai_custom(prompt, get_buffer_text(), "Compose", {})
  end)
end
```

## Quick Wins

1. ⚡ Add `vim.ui.input` gate to `draft_reply` — 10 lines, immediate value
2. ⚡ Add `instructions` parameter to `run_ai()` — 5 lines, enables all actions
3. ⚡ Add `compose` action + keybind — 15 lines, new capability

## Recommended Next Step

→ Start with Quick Win #1+#2: add the `instructions` parameter to `run_ai()` and gate `draft_reply` behind `vim.ui.input`. This gives you the core behavior in ~15 lines. Then add `compose` and the config toggle as follow-ups.

## Keybind Suggestion

```lua
-- Existing (unchanged)
<leader>ms → summarize (no input by default)
<leader>mt → extract_todos (no input by default)
<leader>mr → draft_reply (NOW asks for instructions first)
<leader>mc → tldr (no input by default)

-- New
<leader>mw → compose (always asks for topic)

-- Override: hold Shift to force input on any action
-- (or press with instructions argument)
```

## Implementation Order

1. [ ] Add `instructions` param to `run_ai()` with prompt merge
2. [ ] Add `run_ai_with_input()` wrapper with `vim.ui.input`
3. [ ] Wire `draft_reply` through new wrapper
4. [ ] Add `ask_before` config table with defaults
5. [ ] Add `compose` action + `<leader>mw` keybind
6. [ ] Wire remaining actions through wrapper (summarize, todos, tldr)
7. [ ] Add `ask_before.*` to `:HimalayaAi set` completion
8. [ ] Update tests (automated + interactive)
