# SPEC: Himalaya Editor Plugin Evaluation & Implementation

**Status:** partially-implemented (terminal layer done, editor plugins planned)
**Created:** 2026-02-11
**Updated:** 2026-02-11
**From Brainstorm:** `docs/specs/BRAINSTORM-himalaya-editor-plugin-2026-02-11.md`
**Type:** Full Spec (evaluation + implementation path)
**Related:** `feature/em-dispatcher` branch (#331) — terminal layer implementation

---

## Overview

Evaluate and prototype a Himalaya email CLI integration plugin for editor environments. Himalaya (v1.1.0) provides a stateless JSON API via CLI that can be wrapped by any editor's plugin system. The plugin should support email triage, compose/send, search, attachments, and AI-powered actions (summarize, extract todos, draft replies, create meetings) using Claude Code or Gemini CLI as the AI backend. Personal use only, desktop (macOS), single account.

> **Implementation Note (2026-02-11):** The terminal layer (`em` ZSH dispatcher) was built first on `feature/em-dispatcher` (38 commits, ~9,700 lines). All core email + AI operations are working in the terminal. Editor plugins are now about adding GUI/sidebar UX on top of a proven foundation, not building from scratch.

---

## Primary User Story

**As a** developer who uses Himalaya daily for email,
**I want to** read, triage, compose, and AI-process emails from within my editor,
**so that** I can manage email without context-switching away from my development environment.

### Acceptance Criteria

- [x] List inbox envelopes with sender, subject, date — `em inbox` (terminal)
- [x] Read email messages — `em read <ID>` with smart rendering (terminal)
- [ ] Read email messages in the editor (GUI — requires editor plugin)
- [x] Compose and send new emails — `em send` via $EDITOR (terminal)
- [x] Reply and forward emails — `em reply <ID>` (terminal)
- [x] Search/filter emails — `em find <query>` (terminal)
- [x] Download attachments — `em attach <ID>` (terminal)
- [x] AI summarize: pipe email to Claude/Gemini CLI — `em summarize <ID>` (terminal)
- [x] AI extract todos: extract action items — `em respond <ID>` classifies + drafts (terminal)
- [x] AI draft reply: generate a draft reply — `em respond <ID>` (terminal)
- [ ] Editor sidebar with envelope list (GUI — requires editor plugin)
- [ ] HTML email rendering in editor (GUI — requires editor plugin)

---

## Secondary User Stories

**As a** developer who uses multiple editors,
**I want to** have a portable email integration strategy,
**so that** I don't duplicate effort across editors.

**As a** knowledge worker,
**I want to** save important emails as notes/documents,
**so that** email insights persist in my knowledge base.

---

## Architecture

### Current (Terminal Layer — DONE)

```
+------------------+     spawns      +------------------+
|  em dispatcher   | -------------> |  himalaya CLI    |
|  (pure ZSH)      | <------------- |  --output json   |
+------------------+    JSON stdout  +------------------+
   |          |                              |
   | spawns   | renders                     | IMAP/SMTP
   v          v                              v
+----------+ +----------+           +------------------+
| claude/  | | w3m/bat/ |           |  Email Server    |
| gemini   | | glow     |           |  (1 account)     |
+----------+ +----------+           +------------------+
```

**6-layer architecture:** dispatcher -> himalaya adapter (`em-himalaya.zsh`) -> AI layer (`em-ai.zsh`) -> cache (`em-cache.zsh`) -> render (`em-render.zsh`) -> helpers (`email-helpers.zsh`)

### Planned (Editor Plugins — extend terminal layer)

```
+------------------+     spawns/calls  +------------------+
|  Editor Plugin   | ---------------> |  em dispatcher   |
|  (TS/Lua/Elisp)  | <--------------- |  OR himalaya CLI |
+------------------+    JSON/text      +------------------+
        |                                       |
        | renders in                            | IMAP/SMTP
        v                                       v
+------------------+                   +------------------+
| Editor-native UI |                   |  Email Server    |
| (TreeView/buffer)|                   |  (1 account)     |
+------------------+                   +------------------+
```

### Integration Pattern (All Editors)

1. Plugin spawns `himalaya <command> --output json` (or wraps `em` subcommands)
2. Parses JSON stdout into structured data
3. Renders data in editor-native UI (TreeView/buffer/ItemView)
4. For AI: pipes email text to `claude`/`gemini` CLI, captures response (pattern proven in `em-ai.zsh`)
5. Displays AI response in editor (float/panel/buffer)

---

## API Design

N/A - No custom API. The integration surface is Himalaya CLI commands:

| Himalaya Command | Plugin Action |
|-----------------|---------------|
| `envelope list --output json --folder INBOX` | Populate inbox list |
| `envelope list --output json --query "search term"` | Search emails |
| `message read <id> --output json` | Display email |
| `template write` | Open compose buffer/form |
| `message send` | Send composed email |
| `message reply <id>` | Open reply compose |
| `message forward <id>` | Open forward compose |
| `attachment download <id>` | Save attachment to disk |
| `flag add <id> Seen` | Mark as read |
| `flag remove <id> Seen` | Mark as unread |
| `folder list --output json` | Populate folder list |

---

## Data Models

N/A - No persistent data model. All data flows through Himalaya CLI JSON output. Example envelope JSON structure:

```json
{
  "id": "12345",
  "subject": "Meeting tomorrow",
  "from": {"name": "Alice", "addr": "alice@example.com"},
  "date": "2026-02-11T10:00:00Z",
  "flags": ["Seen"]
}
```

---

## Dependencies

| Dependency | Purpose | Required | Status |
|-----------|---------|----------|--------|
| `himalaya` CLI (v1.1.0+) | Email backend | YES | Verified, adapter built |
| `claude` or `gemini` CLI | AI processing | Optional | Verified, `em-ai.zsh` built |
| `em` dispatcher (flow-cli) | Terminal email layer | Foundation | DONE (feature branch) |
| Editor-specific SDK | Plugin framework | For editor plugins | Pending |
| `himalaya-vim` (Neovim only) | Existing plugin base | For Neovim path | Available |
| `himalaya-emacs` (Emacs only) | Existing plugin base | For Emacs path | Available |
| `w3m` / `bat` / `fzf` / `jq` | Rendering + UI | For terminal layer | Verified |

---

## UI/UX Specifications

### User Flow

```
Open editor -> Click inbox icon / run command
    -> Sidebar shows envelope list (folder, subject, from, date)
    -> Click/select envelope -> Message opens in reader pane
    -> Keybinds: r(reply), f(forward), d(delete), a(archive)
    -> AI keybinds: ms(summarize), mt(todos), mr(draft-reply)
    -> Compose: opens editor buffer/modal, send on save/confirm
```

### Wireframe (VS Code - Primary Target)

```
+--sidebar--+--main-editor-area------------------+
| Folders   | [Email Reader Tab]                  |
|  > INBOX  |                                     |
|    Sent   | From: alice@example.com             |
|    Drafts | Subject: Meeting tomorrow           |
|           | Date: 2026-02-11                    |
| Envelopes |                                     |
|  > Meeting| Dear team,                          |
|    PR #42 |                                     |
|    Invoice| The meeting is scheduled for...     |
|           |                                     |
+-----------+                                     |
| Unread: 3 | [AI Summary Panel]                  |
+-----------+ - 3 bullet point summary            |
             | - Action items extracted            |
             +-------------------------------------+
```

### Accessibility Checklist

- [ ] All actions available via keyboard (no mouse required)
- [ ] Screen reader compatible labels on TreeView/ItemView items
- [ ] High contrast theme support (inherit from editor theme)
- [ ] Status bar unread count visible without opening sidebar

---

## Open Questions

1. ~~**Himalaya v1.1.0 breaking changes:**~~ **RESOLVED.** v1.1.0 command surface verified. Key findings: `--html`/`--raw` flags don't exist, use `message export` instead. himalaya returns exit 0 with empty stdout for non-existent UIDs (silent failure). IMAP UIDs are large integers, not sequential. All documented in `em-himalaya.zsh` adapter.
2. ~~**AI CLI interface:**~~ **RESOLVED.** `claude -p "prompt"` with email piped via stdin works. Pluggable backend implemented in `em-ai.zsh` with per-operation timeouts (classify=10s, summarize=15s, draft=30s) and fallback chain.
3. **HTML email rendering:** VS Code Webview can render HTML, but sanitization is needed. What library? DOMPurify? *(Still open for editor plugins — terminal layer uses w3m/pandoc for HTML-to-text.)*
4. **Himalaya MCP server:** Is the MCP server approach worth building as Layer 2, given it works across all AI tools? *(Still open — more valuable now that the terminal layer proves the pattern.)*
5. **Thread/conversation view:** Himalaya doesn't natively support threading. Would need to group by subject/references header client-side. *(Still open.)*
6. **NEW: Editor plugin architecture** — should plugins call `em` subcommands (reuse ZSH logic) or call himalaya directly (reuse only the adapter patterns)?

---

## Review Checklist

- [x] Himalaya CLI v1.1.0 installed and configured — verified on `feature/em-dispatcher`
- [x] All core email operations verified via CLI — adapter in `em-himalaya.zsh`
- [x] AI CLI tools (claude/gemini) verified for spawning — `em-ai.zsh`
- [ ] Editor plugin scaffolding created (pending — VS Code or Neovim)
- [ ] TreeView/sidebar rendering envelopes (pending — editor plugin)
- [x] Message reader displaying email content — `em read` with smart rendering
- [x] Compose flow working end-to-end — `em send` / `em reply` via $EDITOR
- [x] AI summarize action working — `em summarize <ID>`
- [x] Keyboard shortcuts documented — fzf picker keybinds + refcard
- [x] Error handling for missing himalaya / AI CLIs — `em doctor` + graceful degradation

---

## Implementation Notes

### Recommended Implementation Order

1. ~~**Phase -1: Terminal (DONE)**~~ — `em` ZSH dispatcher with 16+ subcommands, AI, fzf, smart rendering, 86+118 tests, full docs
2. **Phase 0: Neovim (Next, 30 min)** - Install himalaya-vim + ~50-line Lua AI wrapper
3. **Phase 1: VS Code MVP (Weekend)** - TreeView sidebar + Webview reader + compose (reuse adapter patterns from `em-himalaya.zsh`)
4. **Phase 2: AI Layer (VS Code)** - Command palette actions for summarize/todos/draft-reply (port prompts from `em-ai.zsh`)
5. **Phase 3: Future** - MCP server for portable AI-tool access, Obsidian save-to-vault

### Key Technical Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Primary editor target | VS Code | Daily driver, richest API, best long-term ceiling |
| Process spawning | `execFile` (not `exec`) | Safety: avoids shell injection |
| UI framework | Native VS Code API | TreeView + Webview sufficient, no extra deps |
| AI backend spawning | Same `execFile` pattern | Consistent, safe, captures stdout |
| Message rendering | Webview (HTML) + Editor tab (plaintext fallback) | Best of both worlds |
| Compose workflow | VS Code editor tab + virtual document | Native editing experience |

### Editor Ranking (from brainstorm)

| Rank | Editor | Score | Verdict |
|:----:|--------|:-----:|---------|
| 1 | Neovim/LazyVim | 27 | SIMPLEST - existing plugin, just add AI |
| 2 | VS Code | 29 | BEST long-term - richest API, daily driver |
| 3 | Emacs | 26 | EXISTS - wait for official Pimalaya plugin |
| 4 | Obsidian | 24 | POSSIBLE - but paradigm mismatch |
| 5 | Zed | 13 | BLOCKED - no custom UI APIs |

---

## History

| Date | Event |
|------|-------|
| 2026-02-11 | Initial spec from max-depth brainstorm with 3 parallel research agents |
| 2026-02-11 | Updated after reviewing `feature/em-dispatcher` branch — terminal layer (Layer -1) complete with 38 commits, ~9,700 lines. 8/10 acceptance criteria met via terminal. Revised architecture, implementation order, and open questions. |
