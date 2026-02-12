# Himalaya + Neovim Email UX/DX Analysis

**Generated:** 2026-02-10
**Context:** ADHD university professor migrating from Apple Mail to terminal email
**Constraint:** LazyVim starter, no Lua experience, 2-5 replies/day, AI-first compose

---

## Executive Summary

After analyzing all four approaches against flow-cli's established ADHD-friendly UX patterns (sub-10ms response, smart defaults, progressive disclosure, safety-first confirmation), **Approach B (nvim as $EDITOR only, hybrid terminal workflow)** is the clear winner.

It matches every pattern already proven in flow-cli: single-letter dispatchers, fzf-driven selection, confirmation gates, graceful degradation, and zero cognitive overhead for the 80% case. Approach D is the strongest runner-up and shares most advantages, differing only in where reading happens.

---

## Pattern Extraction from flow-cli

Before analyzing approaches, here are the UX conventions this email workflow must follow (derived from `/Users/dt/projects/dev-tools/flow-cli/lib/core.zsh`, `/Users/dt/projects/dev-tools/flow-cli/lib/tui.zsh`, and the 12 dispatchers):

| Pattern | Example | Why It Works for ADHD |
|---------|---------|----------------------|
| **Single-letter dispatcher** | `g`, `r`, `cc`, `v` | Zero typing friction, muscle memory |
| **No-arg = smart default** | `g` = `git status -sb`, `cc` = launch Claude HERE | Removes decision paralysis |
| **Verb + keyword** | `g push`, `teach deploy`, `cc wt pick` | Predictable grammar, scannable |
| **fzf for picking** | `_flow_pick_project`, `cc wt pick` | Visual selection defeats blank-prompt anxiety |
| **Confirmation before danger** | `_flow_confirm` defaults to N, `_g_check_workflow` blocks protected branches | Never accidentally destroy |
| **Status colors** | Green = success, yellow = warning, red = error | Instant visual parsing |
| **Help via `<cmd> help`** | Every dispatcher has `_<cmd>_help()` | Discoverable, no memorization |
| **Progressive disclosure** | "80% daily use" section first, then details | Reduces overwhelm |
| **Spinners for latency** | `_flow_with_spinner` | Feedback that something is happening |
| **Graceful degradation** | Atlas optional, gum optional, fzf fallback | Works even when things are missing |

---

## Approach A: Full nvim Plugin

### Concept
Email inbox rendered as nvim buffer. Compose in split window. Everything inside nvim.

### 1. Learning Curve

| Metric | Value |
|--------|-------|
| Hours to productive | 20-40 hours |
| Cognitive overhead | VERY HIGH |
| ADHD friction | SEVERE |

**Why this is the worst for ADHD:** The user must learn two complex systems simultaneously: nvim buffer management (splits, windows, tabs) AND himalaya's plugin API. Neither himalaya-vim nor himalaya.nvim has documentation quality comparable to established nvim plugins. The user is a LazyVim starter with zero Lua experience -- debugging broken buffer rendering will require understanding nvim's buffer/window model, autocommands, and likely Lua API calls.

The flow-cli `cc` dispatcher works precisely because it does not try to embed Claude's entire UI inside the terminal. It launches Claude as a standalone process. The same principle applies here.

### 2. Daily Workflow

```
1. Open nvim
2. Run :HimalayaList (or keymap)          -- Wait: plugin fetches inbox
3. Navigate buffer with j/k               -- Mental model: "is this a buffer or a list?"
4. Press Enter to open email in split      -- Context: now 2 buffers, which has focus?
5. Press 'r' to reply                      -- New split opens with headers pre-filled
6. AI injects draft somehow (?)            -- UNSOLVED: how does AI content get into buffer?
7. Edit draft in buffer
8. :HimalayaSend or keymap                 -- DID THIS ACTUALLY SEND? Where's confirmation?
9. Close splits, return to inbox buffer    -- State management: did the inbox refresh?
```

**Problem count:** 4 unresolved UX questions in a single email reply cycle.

### 3. Context Switching Cost

- **App transitions:** 0 (everything in nvim)
- **Mode transitions:** HIGH (normal mode for navigation, insert mode for editing, command mode for sending, plugin-specific keymaps competing with LazyVim defaults)
- **Mental model transitions:** 3+ (nvim buffer model, email list model, compose model)

The illusion of "zero context switching" is misleading. Mode switching within nvim IS context switching. For an ADHD brain, the question isn't "how many apps?" but "how many mental models am I juggling simultaneously?"

### 4. ADHD-Specific UX

- **Dopamine:** Minimal. No visual feedback beyond buffer text changes.
- **Hyperfocus risk:** EXTREME. Configuring the perfect nvim email setup will consume entire days. The user will end up deep in Lua plugin configuration instead of answering email.
- **Visual feedback:** Poor. Buffer text with no color-coded status indicators.
- **Failure visibility:** A broken plugin silently fails or throws cryptic Lua errors.

### 5. Apple Mail Migration Path

| Apple Mail Feature | nvim Plugin Equivalent | Familiarity |
|-------------------|----------------------|-------------|
| Inbox list | Buffer with lines | ALIEN |
| Message preview | Split window | Somewhat familiar |
| Compose window | Another split | Somewhat familiar |
| Send button | Keymap or command | ALIEN |
| Unread badge | ??? | MISSING |
| Search | ??? (depends on plugin) | MISSING |

### 6. Failure Modes

- himalaya-vim seeking new maintainers = abandoned within 6 months
- LazyVim update breaks plugin = user cannot debug Lua
- himalaya CLI API change (post-1.0 semver reduces this risk, but nvim plugins are deeper integrations)
- IMAP connection timeout = cryptic buffer error, no spinner, no feedback

### 7. Configuration Burden

- Lua: Plugin installation in `lazy.nvim`, keymaps, options
- YAML: himalaya config (accounts, IMAP, SMTP)
- ZSH: Minimal (just the AI integration)
- Maintenance: HIGH -- must track himalaya CLI changes AND plugin compatibility

**Verdict: DO NOT USE. Too many failure modes, too much cognitive load, ecosystem too fragile.**

---

## Approach B: nvim as $EDITOR Only (Hybrid)

### Concept
Terminal `em` dispatcher for listing/searching/picking (fzf). nvim opens only for compose/reply with AI pre-populated draft. Follows the exact `cc` dispatcher pattern.

### 1. Learning Curve

| Metric | Value |
|--------|-------|
| Hours to productive | 2-4 hours |
| Cognitive overhead | LOW |
| ADHD friction | MINIMAL |

**Why this works:** The user already knows fzf (flow-cli uses it everywhere). The user already knows nvim for editing text. This approach asks them to learn exactly zero new mental models. The `em` command follows the same grammar as `g`, `cc`, `obs`.

### 2. Daily Workflow

```
em                     # Show inbox (fzf list, unread count)
                       # User sees: sender | subject | date | unread indicator
                       # User picks with fzf (familiar from cc pick, work pick)

em read                # Read selected email (bat with syntax highlighting)
                       # Or: em read auto-opens after pick

em reply               # AI generates draft, nvim opens with draft pre-filled
                       # User edits in nvim (FAMILIAR - this is just text editing)
                       # User saves and quits (:wq)

                       # SAFETY GATE: Back in terminal
                       # "Send this reply? [y/N]"
                       # User must explicitly type 'y'

em                     # Back to inbox (sub-second)
```

**Step count for one reply: 4 conscious decisions** (pick email, read, edit draft, confirm send).

Compare to Apple Mail: open email (1), click reply (2), edit (3), click send (4). Same count.

### 3. Context Switching Cost

- **App transitions:** 1 (terminal to nvim and back, but nvim launches and exits cleanly -- this is the `$EDITOR` pattern used by `git commit`, `crontab -e`, and every Unix tool)
- **Mode transitions:** 2 (terminal mode for selection, nvim mode for editing)
- **Mental model transitions:** 1 (fzf picking is already muscle memory from flow-cli)

This is the SAME context switching pattern as `git commit` (which opens `$EDITOR`, user writes message, saves, returns to terminal). Every developer already has this muscle memory.

### 4. ADHD-Specific UX

- **Dopamine:** YES. Unread count in header. Color-coded status (green = sent, yellow = draft, red = urgent). "Sent!" confirmation with checkmark (same as `_flow_log_success`).
- **Hyperfocus risk:** LOW. The tool does one thing per step. There's nothing to configure inside nvim -- it's just a text editor for drafts.
- **Visual feedback:** Excellent. fzf preview for email content, bat for reading, colored status in terminal.
- **Failure visibility:** himalaya CLI errors appear in terminal with clear messages. No hidden buffer state.

### 5. Apple Mail Migration Path

| Apple Mail Feature | Hybrid Equivalent | Familiarity |
|-------------------|-------------------|-------------|
| Inbox list | fzf picker with preview | Better (searchable) |
| Message preview | bat rendering (colors, headers) | Similar |
| Compose window | nvim (full editor) | MORE powerful |
| Send button | Explicit `y/N` confirmation | SAFER |
| Unread badge | `em` header shows count | Similar |
| Search | fzf fuzzy search + himalaya search | Better |

### 6. Failure Modes

- himalaya CLI breaks: clear error message in terminal, user can still use `himalaya` directly
- nvim breaks: falls back to `$EDITOR` (could be `vim`, `nano`, anything)
- IMAP timeout: spinner with message ("Fetching inbox... ~2-5s"), then error
- AI draft fails: nvim opens with empty template, user writes manually

Each failure degrades gracefully. Nothing crashes silently.

### 7. Configuration Burden

- Lua: ZERO (nvim is just `$EDITOR`, no plugins needed)
- YAML: himalaya config (one-time setup)
- ZSH: `em` dispatcher (~100-150 lines following flow-cli patterns)
- Maintenance: LOW -- only depends on himalaya CLI, which is a single binary

**Verdict: RECOMMENDED. Matches every flow-cli UX pattern. Lowest risk, fastest to productive.**

---

## Approach C: Telescope-Only

### Concept
Telescope picker inside nvim for email selection. Everything else in terminal.

### 1. Learning Curve

| Metric | Value |
|--------|-------|
| Hours to productive | 8-15 hours |
| Cognitive overhead | MODERATE |
| ADHD friction | MODERATE |

**Why moderate risk:** Telescope is already installed with LazyVim, but creating a custom Telescope picker requires Lua knowledge the user does not have. The archived `mountaineer.nvim` (January 2024) means there is no maintained Telescope email integration. Building one requires:
- Understanding Telescope's `finders`, `previewers`, `actions` API
- Writing Lua to call himalaya CLI
- Handling async I/O in Lua (callbacks, coroutines)

This is a multi-day yak shave for a Lua beginner.

### 2. Daily Workflow

```
1. Open nvim
2. <leader>fe (custom keymap for email)       -- Telescope opens
3. Type to fuzzy-search emails                -- GOOD: familiar Telescope UX
4. Enter to select                            -- Preview shows email body
5. <C-r> to reply                             -- Telescope action → opens buffer
6. AI draft appears in buffer somehow (?)     -- UNSOLVED without Lua
7. Edit draft
8. Save → send?                               -- Confirmation UX unclear
```

### 3. Context Switching Cost

- **App transitions:** 0-1 (depends on whether you stay in nvim)
- **Mode transitions:** 3 (Telescope insert mode, buffer normal/insert, command mode)
- **Mental model transitions:** 2 (Telescope picker model, buffer editing model)

### 4. ADHD-Specific UX

- **Dopamine:** MODERATE. Telescope's fuzzy search is satisfying but email-specific indicators (unread, urgent) require custom rendering.
- **Hyperfocus risk:** HIGH. Building the "perfect" Telescope email picker will consume days.
- **Visual feedback:** Good within Telescope, poor outside it.

### 5. Failure Modes

- mountaineer.nvim is ARCHIVED -- no starting point
- Custom Telescope extension breaks on LazyVim update
- himalaya API changes require Lua code updates (user cannot maintain)

### 6. Configuration Burden

- Lua: SIGNIFICANT (custom Telescope extension, 200-400 lines)
- YAML: himalaya config
- Maintenance: HIGH -- user must maintain Lua code they don't understand

**Verdict: DO NOT USE unless user plans to invest in Lua literacy. Over-engineered for 2-5 emails/day.**

---

## Approach D: Terminal-Only

### Concept
fzf for picking, bat for reading, nvim is generic `$EDITOR`. Everything in terminal.

### 1. Learning Curve

| Metric | Value |
|--------|-------|
| Hours to productive | 2-4 hours |
| Cognitive overhead | LOW |
| ADHD friction | MINIMAL |

Nearly identical to Approach B. The difference is philosophical: Approach B treats nvim as "the compose tool" with some email-aware configuration (filetype, snippets). Approach D treats nvim as a completely generic editor.

### 2. Daily Workflow

Identical to Approach B. The `em` dispatcher works the same way.

### 3. Context Switching Cost

Same as Approach B.

### 4. ADHD-Specific UX

Same as Approach B, with one subtle difference: reading email in terminal via `bat` means the email is visible alongside the shell prompt. In Approach B, you might optionally read inside a nvim buffer with syntax highlighting. In practice, this difference is negligible for 2-5 emails/day.

### 5. Why B > D (Marginal)

The distinction matters only for the **compose/reply** experience:

| Feature | B (nvim-aware) | D (nvim-generic) |
|---------|---------------|-----------------|
| Draft template | nvim opens with `mail` filetype, headers highlighted | nvim opens plain text |
| AI draft display | Headers in different color, body ready for editing | All text looks the same |
| Snippet expansion | Possible with nvim-cmp | Not available |
| Attachment handling | Could use nvim command for attachment path | Must use terminal command |

For 2-5 emails/day, these are nice-to-haves, not requirements. But since Approach B requires zero extra Lua (just setting `filetype=mail` via modeline in the temp file), the marginal cost is near-zero for real UX benefit.

### 6. Configuration Burden

- Lua: ZERO
- YAML: himalaya config
- ZSH: `em` dispatcher
- Maintenance: LOW

**Verdict: EXCELLENT. Nearly identical to B. Use D if you want absolute minimal configuration; use B for slightly better compose UX at zero additional cost.**

---

## AI-First Compose Workflow (Detailed Design)

This is the critical UX detail. Here is the exact mechanism, designed to match flow-cli conventions:

### Draft Generation Pipeline

```
em reply              # User selected email #42 from fzf
    |
    v
[1] himalaya read --raw 42 > /tmp/em-context-42.eml    # Get original email
    |
    v
[2] AI generates reply draft:
    - Input: original email + user context (signature, role, tone prefs)
    - Output: plain text draft with headers
    - Tool: claude -p "Draft a professional reply..." < /tmp/em-context-42.eml
    - Spinner: "Generating reply draft... ~5-10s"
    |
    v
[3] Write draft to temp file: /tmp/em-reply-42.eml
    Format:
    ┌────────────────────────────────────────┐
    │ # vim: set ft=mail:                    │  <-- modeline for syntax highlighting
    │ To: sender@example.com                 │
    │ Subject: Re: Original Subject          │
    │ ---                                    │
    │                                        │
    │ [AI-generated reply body here]         │
    │                                        │
    │ --                                     │
    │ Dr. [Name]                             │
    │ [University]                           │
    │                                        │
    │ # --- Original Message ---             │  <-- dimmed/commented for context
    │ # From: sender@example.com             │
    │ # [quoted original below]              │
    └────────────────────────────────────────┘
    |
    v
[4] nvim /tmp/em-reply-42.eml              # Opens with mail syntax highlighting
    - User edits body (cursor positioned at first line of body)
    - Original message visible below for reference (read-only feel via comments)
    - User saves and quits (:wq)
    |
    v
[5] SAFETY GATE (back in terminal):
    ┌────────────────────────────────────────┐
    │                                        │
    │  To: sender@example.com                │
    │  Subject: Re: Original Subject         │
    │                                        │
    │  [First 5 lines of body preview]       │
    │                                        │
    │  Send this reply? [y/N] _              │
    │                                        │
    └────────────────────────────────────────┘
    - DEFAULT IS NO (same as _flow_confirm pattern)
    - User must deliberately type 'y'
    |
    v
[6] himalaya send < /tmp/em-reply-42.eml
    - Spinner: "Sending..."
    - Success: "Sent reply to sender@example.com"
    - Temp files cleaned up
```

### Safety Mechanisms (Preventing Accidental Send)

Following the `_g_check_workflow` and `_flow_confirm` patterns:

| Safeguard | Mechanism | flow-cli Precedent |
|-----------|-----------|-------------------|
| No auto-send on `:wq` | Saving nvim only saves the temp file, NOT sends | `finish` prompts before commit |
| Default-No confirmation | `[y/N]` with default N | `_flow_confirm` defaults to "n" |
| Preview before send | Show To/Subject/body preview | `g push` shows branch info before push |
| Empty body detection | Warn if body is empty or unchanged from AI draft | `g commit` with empty message aborts |
| Draft save on cancel | Draft preserved in `/tmp/` for `em draft` command | No work is lost |
| Undo window | `em unsend` within 30s (if provider supports, e.g., Gmail) | N/A but nice to have |

### nvim Configuration for Compose (Zero Lua Required)

The temp file includes a vim modeline (`# vim: set ft=mail:`), which gives:
- Header highlighting (To, Subject, CC in different color)
- Body text in normal color
- Quoted text (lines starting with `>`) dimmed
- Signature block detected

No Lua configuration needed. No plugins needed. This works with stock nvim.

For a nicer experience later (optional, not day-1):
```lua
-- In ~/.config/nvim/after/ftplugin/mail.lua (future enhancement)
vim.opt_local.textwidth = 72
vim.opt_local.spell = true
vim.opt_local.spelllang = "en"
```

---

## Proposed `em` Dispatcher Design

Following the exact pattern of `g()`, `cc()`, `obs()`:

```
em                     # Inbox (fzf list) -- same as g (no-arg = status)
em inbox               # Explicit inbox
em read [id]           # Read email (bat)
em reply [id]          # AI draft + nvim + confirm + send
em compose             # New email (AI or manual)
em search <query>      # Search emails
em draft               # List/resume saved drafts
em send                # Send a saved draft
em accounts            # Show configured accounts
em doctor              # Health check (himalaya, IMAP, SMTP)
em help                # Help (80% section + full reference)
```

**Grammar:** `em [verb] [target]` -- identical to `g [verb] [target]`.

**No-arg default:** Show inbox with unread count header. Same as `g` showing `git status -sb`.

### Inbox Display (fzf)

```
em
    ┌──────────────────────────────────────────────────────┐
    │  Inbox (3 unread)                                     │
    │  ──────────────────────────────────────────────────── │
    │  * Dr. Smith       | Re: Grades question    | 10m ago │
    │  * Student A       | Assignment extension   | 1h ago  │
    │    Dept. Chair     | Faculty meeting notes  | 3h ago  │
    │  * IT Support      | Password reset         | 1d ago  │
    │                                                       │
    │  > Preview:                                           │
    │  Hi Professor,                                        │
    │  I wanted to ask about the midterm grades...          │
    └──────────────────────────────────────────────────────┘
```

- `*` = unread (bold, colored)
- fzf preview panel shows email body
- Enter = read full email
- Ctrl-R = reply directly from picker

---

## Comparison Matrix

| Criterion | A (Full nvim) | B (Hybrid) | C (Telescope) | D (Terminal) |
|-----------|:------------:|:----------:|:-------------:|:------------:|
| Learning curve (hours) | 20-40 | **2-4** | 8-15 | **2-4** |
| ADHD friction | Severe | **Minimal** | Moderate | **Minimal** |
| Context switches per email | 0 (illusory) | **1** (clean) | 0-1 | **1** (clean) |
| Failure recoverability | Poor | **Excellent** | Poor | **Excellent** |
| Configuration burden | High | **Low** | High | **Zero** |
| Ecosystem risk | Critical | **Low** | Critical | **Low** |
| AI draft integration | Hard | **Natural** | Hard | **Natural** |
| Send safety | Unclear | **Explicit** | Unclear | **Explicit** |
| flow-cli pattern match | 1/10 | **9/10** | 4/10 | **8/10** |
| Apple Mail familiarity | 2/10 | **7/10** | 4/10 | **6/10** |

---

## Recommendation

### Use Approach B

Build an `em` dispatcher following the exact conventions of the `g`, `cc`, and `obs` dispatchers in flow-cli:

1. **ZSH dispatcher** (~150 lines) with `em()` case statement
2. **fzf integration** for inbox browsing (reuse `_flow_has_fzf`, `_flow_choose` patterns)
3. **bat for reading** emails with syntax highlighting
4. **nvim as `$EDITOR`** for compose only, with mail filetype via modeline
5. **AI draft via `claude -p`** piped to temp file with spinner
6. **Explicit `[y/N]` confirmation** before every send (default No)
7. **`em doctor`** for health check (himalaya binary, IMAP connectivity, SMTP test)
8. **`em help`** with 80% section first

### Implementation Order

1. `himalaya` CLI setup + account config (YAML)
2. `em` dispatcher skeleton (inbox, read, help)
3. AI draft pipeline (reply with `claude -p`)
4. Send safety gate (confirmation + preview)
5. Compose (new email, not just reply)
6. Search and draft management
7. Optional: nvim `after/ftplugin/mail.lua` for spell check + line width

### What NOT to Do

- Do NOT install himalaya-vim or any nvim email plugin
- Do NOT write Lua for Telescope email integration
- Do NOT try to render inbox inside nvim buffers
- Do NOT auto-send on any action (always require confirmation)
- Do NOT over-engineer for 2-5 emails/day

---

## Next Steps

1. Set up himalaya CLI with university IMAP/SMTP credentials
2. Create `em` dispatcher as new flow-cli feature (or standalone ZSH function)
3. Wire up AI draft generation with claude CLI
4. Test the full reply cycle: pick, read, draft, edit, confirm, send

---

*Analysis based on flow-cli v6.7.0 UX patterns, himalaya ecosystem state as of February 2026.*
