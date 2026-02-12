# Himalaya Editor Plugin — Brainstorm & Evaluation

**Generated:** 2026-02-11
**Updated:** 2026-02-11
**Mode:** max + feature + save
**Context:** Evaluating Himalaya email integration for 5 editors
**Duration:** ~8 min (3 parallel research agents + synthesis)

---

## Status Update (2026-02-11)

> **The `em` ZSH dispatcher was built first.** Before any editor plugin work began, a complete terminal email workflow was implemented as a flow-cli dispatcher on the `feature/em-dispatcher` branch (#331). This is "Layer -1" — a foundation that changes the editor plugin calculus.

### What Was Built

The `em` dispatcher (38 commits, ~9,700 lines) provides:

| Capability | em Dispatcher | Status |
|-----------|--------------|--------|
| List inbox envelopes | `em inbox` | DONE |
| Read messages (smart rendering) | `em read <ID>` | DONE |
| Compose & send | `em send` | DONE |
| Reply (with AI draft) | `em reply <ID>` | DONE |
| Search/filter | `em find <query>` | DONE |
| fzf interactive picker | `em pick` | DONE |
| AI summarize | `em summarize <ID>` | DONE |
| AI classify | `em classify <ID>` | DONE |
| AI draft reply | `em respond <ID>` | DONE |
| Download attachments | `em attach <ID>` | DONE |
| Dashboard | `em dash` | DONE |
| Health check | `em doctor` | DONE |

**Architecture:** 6-layer (dispatcher -> himalaya adapter -> AI layer -> cache -> render -> helpers)
**Tests:** 86 unit + 118 dogfood + E2E + interactive (45/45 suites passing)
**Docs:** Refcard (664 lines) + Guide (1,506 lines) + Tutorial (1,604 lines)

### Impact on Editor Plugin Strategy

The original brainstorm evaluated editors as if building email from scratch. With `em` as the foundation:

1. **All AI actions already work** — classify, summarize, draft reply via `claude -p` / `gemini` CLI
2. **himalaya adapter quirks are solved** — IMAP UIDs, missing flags, silent failures, MIME export
3. **Email noise cleanup is production-tested** — 30 dedicated tests for CID, Safe Links, MIME markers
4. **Editor plugins become thin UI wrappers** — they call `em` subcommands or share the himalaya adapter layer, not rebuild everything

### Revised Hybrid Strategy

| Layer | What | Status |
|-------|------|--------|
| **Layer -1: Terminal** | `em` ZSH dispatcher (flow-cli) | **DONE** |
| **Layer 0: Neovim** | himalaya-vim + AI wrapper (~50 lines Lua) | Planned |
| **Layer 1: VS Code** | TreeView + Webview extension (can reuse `em` patterns) | Planned |
| **Layer 2: MCP Server** | Portable himalaya MCP (works with any AI tool) | Planned |
| **Skip** | Emacs (official coming), Obsidian (mismatch), Zed (no UI APIs) | Deferred |

---

## Overview

Himalaya (v1.1.0) is a Rust CLI email client from the Pimalaya project with `--output json` for all commands. It supports IMAP, SMTP, Maildir, Notmuch, PGP, OAuth 2.0, and multi-account. The goal: evaluate building an editor plugin that wraps the CLI for email triage, compose, search, attachments, and AI-powered actions (summaries, todos, meetings) using Claude Code or Gemini CLI as the AI backend.

### Himalaya CLI Commands (Integration Surface)

| Category | Key Commands |
|----------|-------------|
| **Account** | `list`, `configure`, `doctor` |
| **Folder** | `list`, `add` |
| **Envelope** | `list`, `watch`, `get` (supports `--output json`) |
| **Message** | `read`, `write`, `reply`, `forward`, `copy`, `move`, `delete`, `save`, `send`, `edit` |
| **Flag** | `add`, `set`, `remove` |
| **Attachment** | `download` |
| **Template** | `write`, `reply`, `forward`, `save`, `send` |

All commands support `--output json` for structured parsing.

---

## Comparative Analysis

### The Capability Matrix

| Capability | Neovim/LazyVim | VS Code | Emacs | Obsidian | Zed |
|-----------|:-----------:|:-------:|:-----:|:--------:|:---:|
| **Existing himalaya plugin** | YES (official) | NO | YES (community) | NO | NO |
| **Spawn CLI process** | vim.fn.jobstart() | child_process | make-process | child_process | process:exec |
| **Custom sidebar/panel** | splits/floats | TreeView + Webview | buffers/modes | ItemView | NO |
| **Rich HTML rendering** | NO (text only) | Webview (full HTML) | eww/shr (basic) | Full DOM | NO |
| **Background polling** | timer_start() | setInterval | run-with-timer | onload interval | NO |
| **Compose in editor** | native buffer | native editor tab | native buffer | modal/leaf | NO (slash cmd) |
| **AI CLI spawning** | jobstart() | child_process | make-process | child_process | process:exec |
| **Plugin language** | VimScript/Lua | TypeScript | Elisp | TypeScript | Rust (WASM) |
| **Marketplace publishing** | lazy.nvim/GitHub | VS Marketplace | MELPA/GitHub | Community | zed.dev |
| **Dev iteration speed** | FAST (reload) | FAST (F5 debug) | FAST (eval-buffer) | MEDIUM (rebuild) | SLOW (compile) |

### Scoring (1-5, higher = better for this use case)

| Criterion | Neovim | VS Code | Emacs | Obsidian | Zed |
|-----------|:------:|:-------:|:-----:|:--------:|:---:|
| Existing work to build on | 5 | 1 | 4 | 1 | 1 |
| UI richness potential | 3 | 5 | 3 | 5 | 1 |
| Process spawning ease | 5 | 5 | 5 | 4 | 3 |
| Weekend prototype scope | 5 | 3 | 4 | 3 | 2 |
| AI integration ease | 4 | 5 | 4 | 4 | 2 |
| Long-term growth ceiling | 3 | 5 | 4 | 4 | 2* |
| Your daily driver match | 2 | 5 | 2 | 3 | 2 |
| **TOTAL** | **27** | **29** | **26** | **24** | **13** |

*Zed plans to add UI extensibility "in the future" — score may improve.

---

## Editor-by-Editor Deep Dive

### 1. Neovim/LazyVim — SIMPLEST (Use Existing)

**Existing Plugins:**
- `pimalaya/himalaya-vim` — Official. Full-featured Vim/Neovim frontend
  - Envelope listing with keybinds (`gw` write, `gr` reply, `gR` reply-all, `gf` forward)
  - Message reading in nomodifiable buffer with mail filetype
  - Attachment download (`ga`), folder switching, copy/move (`gC`/`gM`)
  - Search/filter via query parameter on envelope list
  - Spawns `himalaya` CLI via VimScript system calls
- `elmarsto/mountaineer.nvim` — Telescope extension for fuzzy email search
- `aliyss/vim-himalaya-ui` — Community UI improvements

**Pros:**
- Plugin already exists and is maintained by the Himalaya project itself
- Zero development needed for core email features
- Keyboard-driven UX aligns with terminal workflow
- LazyVim integration: just add to lazy.nvim plugin spec
- Telescope integration via mountaineer.nvim for fuzzy search
- Lightest resource footprint

**Cons:**
- Text-only rendering (no HTML email preview)
- No graphical attachment preview
- VimScript core (not Lua) — harder to extend with modern Neovim patterns
- No built-in AI integration (would need custom wrapper)
- Less discoverability for non-Vim users

**Weekend Prototype:**
Configure himalaya-vim + mountaineer.nvim, then write a ~50-line Lua wrapper that:
1. Pipes current email buffer to `claude` or `gemini` CLI via `vim.fn.jobstart()`
2. Captures AI response in a floating window
3. Adds keybinds: `<leader>ms` (summarize), `<leader>mt` (extract todos), `<leader>mr` (draft reply)

---

### 2. VS Code — BEST FOR NEW DEVELOPMENT (Your Daily Driver)

**Architecture:**
TypeScript extension with full Node.js runtime. Rich API surface:
- **TreeView** for sidebar email list (folders, envelopes)
- **Webview** for rich HTML email rendering
- **Editor tabs** for composing (use VS Code's native editor as compose window)
- **Status bar** for unread count badge
- **Notifications** for new email alerts
- **Node.js child process** for all himalaya CLI calls

**Pros:**
- Richest UI capabilities of any editor (TreeView + Webview + Status Bar)
- Your primary editor — most daily utility
- Full Node.js runtime (process spawning, fs, networking)
- HTML email rendering via Webview (full browser engine)
- VS Code's editor IS the compose window (markdown or plaintext)
- Excellent debugging (F5 Extension Host)
- Largest ecosystem of reference implementations
- Background polling with extension activation events

**Cons:**
- No existing himalaya extension (build from scratch)
- More boilerplate than Vim/Emacs (package.json, activation, extension.ts)
- Webview to extension communication via message passing (adds complexity)
- Electron resource overhead
- TypeScript compile step (minor)

**Weekend Prototype:**
1. **TreeView sidebar**: Folder list then Envelope list (from `himalaya envelope list --output json`)
2. **Message viewer**: Open email in new editor tab (readonly, markdown-rendered)
3. **Compose**: `himalaya template write` then open in editor then `himalaya message send`
4. **Status bar**: Unread count via periodic `himalaya envelope list --folder INBOX`
5. **AI command**: Command palette then "Summarize Email" then pipes to `claude`/`gemini` CLI

**Key VS Code APIs:**
- `vscode.window.createTreeView()` — sidebar panel
- `vscode.window.createWebviewPanel()` — HTML email viewer
- Node.js process spawning for CLI calls (use execFile for safety)
- `vscode.window.createStatusBarItem()` — unread badge
- `vscode.commands.registerCommand()` — AI actions

---

### 3. Emacs (Spacemacs) — ALREADY EXISTS (Mostly)

**Existing Plugin:**
- `dantecatalfamo/himalaya-emacs` — Community Emacs frontend
  - Spawns himalaya via `call-process` (sync) and `make-process` (async)
  - Buffer-based UI for envelope listing and message reading
  - Basic operations: read, reply, forward, delete
  - Jesse Claven added menus + bug fixes (2025-04)
  - Customizable via Emacs Easy Customize system

**Official Support Coming:**
NLnet funding specifically includes an official Emacs plugin from the Pimalaya project. Building a custom one may be redundant.

**Pros:**
- Plugin already exists and works
- Emacs' process management is best-in-class (`make-process` with callbacks)
- Buffer-based paradigm perfectly matches email reading
- Deep customization via Elisp
- Can compose emails in native Emacs buffer with full editing power
- JSON parsing built into Emacs (`json-parse-string`)
- Async operations via `make-process` with sentinels

**Cons:**
- Community plugin (dantecatalfamo), not official yet
- Elisp learning curve if extending
- No HTML email rendering (text-only, or basic via `shr`/`eww`)
- Spacemacs layer integration would need wrapping
- Official plugin may supersede any custom work
- Less active maintenance than Vim plugin

**Weekend Prototype:**
Install himalaya-emacs, add a thin AI wrapper (~30 lines Elisp) for summarize/todos/draft-reply.

---

### 4. Obsidian — POSSIBLE BUT PARADIGM MISMATCH

**Architecture:**
TypeScript plugin running in Electron. Full Node.js process spawning on desktop.

**Pros:**
- Rich UI (ItemView for custom sidebars, modals, settings tabs)
- Full DOM access — can render HTML emails beautifully
- Process spawning works for himalaya CLI calls
- Natural "save email to vault" workflow (email as markdown note)
- Code block processors for inline email embeds
- Active plugin ecosystem with good documentation

**Cons:**
- Desktop only (Node.js process spawning not available on mobile)
- Obsidian is a PKM tool, not a code editor — email client feels out of place
- No terminal integration (cannot compose in a "real" editor buffer)
- Plugin review process if ever publishing to community
- Email and notes paradigm clash
- Background polling is unreliable (Obsidian may throttle background processes)

**Weekend Prototype:**
1. **ItemView sidebar**: Inbox with envelope list (parsed from JSON)
2. **Message view**: Render email as markdown in a leaf
3. **Save to vault**: One-click "save email as note" with metadata frontmatter
4. **AI action**: "Summarize" button that pipes to AI CLI

**Unique Value:**
The killer feature here is not "email in Obsidian" — it is **"email to knowledge base"**: save important emails as notes, extract action items, link to projects.

---

### 5. Zed — MOST LIMITED (Today)

**Architecture:**
Rust compiled to WASM, sandboxed execution. Has `process:exec` and `network:request` capabilities.

**What's Possible Today:**
- **Slash commands**: `/inbox`, `/read <id>`, `/reply <id>` — inject email content into AI assistant context
- **MCP server**: Build a himalaya MCP server that Zed's agent can use
- **Tasks**: Define tasks that run himalaya commands in terminal

**What's NOT Possible:**
- No custom panels or sidebars
- No webviews for HTML rendering
- No custom UI of any kind (beyond text in assistant)
- No background processes for polling

**Pros:**
- `process:exec` CAN spawn himalaya and capture stdout
- `network:request` for HTTP if needed
- MCP server approach is architecturally clean
- Zed's AI assistant could use email as context via slash commands
- Fastest editor (Rust native)

**Cons:**
- SEVERE UI limitations — cannot build an email client UI
- Must write extension in Rust (compile to WASM) — steepest learning curve
- Slow iteration (compile then reload cycle)
- Future UI extensibility is unscheduled ("planned")
- Smallest extension ecosystem
- No reference implementations for email/PIM extensions

**Weekend Prototype:**
Build a Himalaya MCP server (separate from Zed):
- `himalaya_list_envelopes` tool — returns inbox JSON
- `himalaya_read_message` tool — returns message content
- `himalaya_send_reply` tool — sends a reply
- Configure in Zed as MCP server for AI assistant access

**Plot Twist:** The MCP server approach could work with ANY AI tool (Claude Code, Cursor, etc.), making it the most portable option — but it is not really a "Zed plugin."

---

## Recommendation

### The Ranking (Simplest to Implement)

| Rank | Editor | Effort | What You'd Build | Weekend Deliverable |
|:----:|--------|--------|-------------------|-------------------|
| 1 | **Neovim/LazyVim** | Configure + ~50 lines Lua | AI wrapper on existing plugin | Full email + AI summarize |
| 2 | **Emacs** | Configure + ~30 lines Elisp | AI wrapper on existing plugin | Full email + AI summarize |
| 3 | **VS Code** | ~500 lines TypeScript | New plugin from scratch | TreeView + reader + compose |
| 4 | **Obsidian** | ~400 lines TypeScript | New plugin from scratch | Sidebar inbox + save-to-vault |
| 5 | **Zed** | ~200 lines Rust | MCP server or slash commands | Text-only AI-accessible email |

### The Recommended Path

**If you want email working THIS weekend:**
Use **Neovim/LazyVim** (himalaya-vim + mountaineer.nvim + AI wrapper)

**If you want the richest long-term tool in your daily driver:**
Build **VS Code** extension (TreeView + Webview + AI integration)

**If you want the most portable solution:**
Build **MCP Server** (works with Zed, Claude Code, Cursor, any MCP-compatible tool)

### The Smart Hybrid Strategy (Revised)

Build in layers — **Layer -1 is already done:**

1. ~~**Layer -1 (DONE):** `em` ZSH dispatcher — full terminal email with AI, fzf, smart rendering.~~
2. **Layer 0 (Next, 30 min):** Install `himalaya-vim` in Neovim + AI wrapper.
3. **Layer 1 (Weekend):** Build VS Code extension MVP (can reuse `em` adapter patterns).
4. **Layer 2 (Future):** Build Himalaya MCP server (portable to any AI tool).
5. **Skip:** Emacs (official coming), Obsidian (paradigm mismatch), Zed (wait for UI APIs).

---

## AI Integration Architecture (All Editors)

The AI integration pattern is consistent across all editors:

```
[Editor Plugin] spawns [himalaya CLI --output json] parses JSON
              captures email text
              spawns [claude/gemini CLI] with email as stdin/arg
              captures AI response
              displays in editor (float/panel/buffer)
```

### AI Actions (MVP)

| Action | Keybind | AI Prompt Pattern |
|--------|---------|-------------------|
| Summarize | `<leader>ms` | "Summarize this email in 2-3 bullet points" |
| Extract todos | `<leader>mt` | "Extract action items as a checklist" |
| Draft reply | `<leader>mr` | "Draft a professional reply to this email" |
| Create meeting | `<leader>mm` | "Extract meeting details (date, time, location, agenda)" |
| Classify | `<leader>mc` | "Classify: urgent/action-needed/informational/spam" |

---

## Sources

- [Himalaya CLI - GitHub](https://github.com/pimalaya/himalaya)
- [Pimalaya Project](https://github.com/pimalaya)
- [himalaya-vim Plugin](https://github.com/pimalaya/himalaya-vim)
- [himalaya-emacs Plugin](https://github.com/dantecatalfamo/himalaya-emacs)
- [mountaineer.nvim](https://github.com/elmarsto/mountaineer.nvim)
- [NLnet Himalaya Funding](https://nlnet.nl/project/Himalaya/)
- [email-lib Crate](https://crates.io/crates/email-lib)
- [Zed Extension Docs](https://zed.dev/docs/extensions)
- [Zed Extension Capabilities](https://zed.dev/docs/extensions/capabilities)
- [Zed WASM Blog Post](https://zed.dev/blog/zed-decoded-extensions)
- [Obsidian Plugin API](https://docs.obsidian.md/Reference/TypeScript+API/MarkdownRenderChild)
- [VS Code Extension API](https://code.visualstudio.com/api)
- [VS Code Webview API](https://code.visualstudio.com/api/extension-guides/webview)
- [VS Code TreeView API](https://code.visualstudio.com/api/extension-guides/tree-view)
- [Emacs Async Processes](https://www.gnu.org/software/emacs/manual/html_node/elisp/Asynchronous-Processes.html)
- [Jesse Claven - Himalaya Emacs Contributions](https://www.j-e-s-s-e.com/blog/first-contributions-to-himalaya-emacs-package)
