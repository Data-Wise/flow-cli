# SPEC: Neovim Himalaya Integration (Layer 0)

**Status:** draft
**Created:** 2026-02-11
**Branch:** `feature/nvim-himalaya-integration`
**From Brainstorm:** `docs/specs/BRAINSTORM-himalaya-editor-plugin-2026-02-11.md`
**Related:** `feature/em-dispatcher` (#331) — terminal layer (Layer -1)
**Type:** Integration + AI wrapper

---

## Overview

Install himalaya-vim in LazyVim and add a ~50-line Lua AI wrapper for email summarization, todo extraction, and draft replies. This is "Layer 0" — the simplest editor integration, building on the proven terminal `em` dispatcher (Layer -1).

The goal is NOT to build a new plugin from scratch. It is to configure an existing plugin and add AI keybinds that mirror the `em` dispatcher's AI capabilities.

---

## Primary User Story

**As a** developer who sometimes uses Neovim,
**I want to** read and AI-process emails without leaving the editor,
**so that** I can triage email during coding sessions without context-switching to terminal.

### Acceptance Criteria

- [ ] himalaya-vim loads in LazyVim without errors
- [ ] Can list inbox envelopes with keybinds
- [ ] Can read email messages in a Neovim buffer
- [ ] Can reply to emails (opens $EDITOR compose)
- [ ] `<leader>ms` summarizes current email via claude/gemini CLI
- [ ] `<leader>mt` extracts action items as checklist
- [ ] `<leader>mr` generates a draft reply in floating window

---

## Secondary User Stories

**As a** flow-cli user,
**I want to** have consistent AI email actions across terminal and editor,
**so that** the same prompts and patterns work everywhere.

---

## Architecture

```
+------------------+     built-in      +------------------+
|  himalaya-vim    | ----------------> |  himalaya CLI    |
|  (VimScript)     | <---------------- |  --output json   |
+------------------+    JSON/text      +------------------+
        |                                      |
        | keybinds                             | IMAP/SMTP
        v                                      v
+------------------+                   +------------------+
| himalaya-ai.lua  |                   |  Email Server    |
| (~50 lines)      |                   |  (1 account)     |
+------------------+                   +------------------+
        |
        | spawns
        v
+------------------+
| claude -p /      |
| gemini CLI       |
+------------------+
```

### Integration Pattern

1. himalaya-vim handles all email operations (list, read, reply, forward)
2. Custom Lua wrapper intercepts email buffer content
3. Pipes email text to `claude -p` or `gemini` CLI via `vim.fn.jobstart()`
4. Displays AI response in a floating window

---

## API Design

N/A — No custom API. Uses himalaya-vim's built-in keybinds + custom Lua keybinds for AI.

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

### AI Wrapper Keybinds (custom)

| Key | Action | AI Prompt |
|-----|--------|-----------|
| `<leader>ms` | Summarize | "Summarize this email in 2-3 bullet points" |
| `<leader>mt` | Extract todos | "Extract action items as a checklist" |
| `<leader>mr` | Draft reply | "Draft a professional reply to this email" |
| `<leader>mc` | Classify | "Classify: urgent/action-needed/informational/spam" |

---

## Data Models

N/A — No persistent data. Email content flows through himalaya-vim buffers. AI responses are ephemeral (displayed in floating windows, not persisted).

---

## Dependencies

| Dependency | Purpose | Required | Status |
|-----------|---------|----------|--------|
| `himalaya` CLI (v1.1.0+) | Email backend | YES | Verified |
| `himalaya-vim` | Neovim email frontend | YES | Available (seeking maintainer) |
| `claude` or `gemini` CLI | AI processing | Optional | Verified in em-ai.zsh |
| `telescope.nvim` | Fuzzy folder picker | Optional | Common in LazyVim |
| `mountaineer.nvim` | Fuzzy email search | Optional | Available |

---

## UI/UX Specifications

### User Flow

```
Open Neovim -> :Himalaya (or keybind)
    -> Envelope list in buffer (from, subject, date)
    -> Select envelope -> Message opens in readonly buffer
    -> Built-in: gr(reply), gf(forward), ga(attach)
    -> AI: <leader>ms(summarize), <leader>mt(todos), <leader>mr(draft)
    -> AI response appears in floating window
    -> Close float with q or <Esc>
```

### Floating Window Spec

```
+-- AI Summary ─────────────────────────+
|                                        |
| - Meeting scheduled for Thursday 2pm   |
| - Need to prepare Q1 budget slides     |
| - Action: Reply with availability      |
|                                        |
| [q to close]                           |
+────────────────────────────────────────+
```

- Width: 60% of editor width
- Height: auto (content-based, max 50%)
- Position: center
- Border: rounded
- Close: `q`, `<Esc>`, or `<leader>ms` again (toggle)

### Accessibility Checklist

- [x] All actions available via keyboard (inherits from Neovim)
- [ ] Floating window has descriptive title for context
- [x] Inherits editor color scheme
- [ ] Loading indicator while AI processes

---

## Open Questions

1. **mountaineer.nvim compatibility:** Does it work with himalaya v1.1.0? Last commit date unknown.
2. **AI backend detection:** Should the Lua wrapper check for `claude`/`gemini` availability, or just fail with a clear error?
3. **Floating window persistence:** Should AI results be saved to a scratch buffer for later reference?

---

## Review Checklist

- [ ] himalaya-vim loads without errors in LazyVim
- [ ] All built-in keybinds work (gw, gr, gR, gf, ga)
- [ ] AI wrapper keybinds registered
- [ ] Floating window displays correctly
- [ ] Error handling for missing AI CLI
- [ ] Setup documented

---

## Implementation Notes

### Scope

This is intentionally minimal — ~50 lines of Lua + plugin config. The heavy lifting (himalaya adapter, AI prompts, email operations) is already done in the `em` dispatcher. This layer just adds editor-native keybinds and display.

### Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Plugin | himalaya-vim (existing) | Zero email code to write |
| AI wrapper language | Lua | Native Neovim, modern patterns |
| AI display | Floating window | Non-intrusive, dismissible |
| AI spawning | `vim.fn.jobstart()` | Async, non-blocking |
| AI prompts | Port from em-ai.zsh | Consistency across layers |

### Fallback Plan

If himalaya-vim becomes unmaintained:
- Use `em` in a Neovim terminal split (`:terminal em pick`)
- Or build a minimal Lua wrapper around himalaya CLI directly (~200 lines)

---

## History

| Date | Event |
|------|-------|
| 2026-02-11 | Initial spec from editor plugin brainstorm |
