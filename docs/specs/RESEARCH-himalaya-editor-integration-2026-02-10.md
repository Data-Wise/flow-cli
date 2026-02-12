# RESEARCH: himalaya Editor Integration Landscape

**Date:** 2026-02-10
**Context:** Issue #331 (em dispatcher), Approach B validation
**Related:** BRAINSTORM-nvim-himalaya-integration-2026-02-10.md, SPEC-em-dispatcher-2026-02-10.md

---

## Summary

Comprehensive web research on himalaya's editor integration ecosystem confirms that **Approach B ($EDITOR only, no plugins) is the correct architecture**. Additionally, himalaya's native `[BODY]` positional argument and `template` subsystem provide a cleaner AI draft injection mechanism than the temp-file approach originally described in the spec.

---

## 1. himalaya nvim Plugin Ecosystem (Confirmed Fragile)

| Plugin | Stars | Commits | Last Activity | Status | Verdict |
|--------|-------|---------|---------------|--------|---------|
| [himalaya-vim](https://github.com/pimalaya/himalaya-vim) (official) | 115 | 27 | Active issues | **Seeking new maintainers** (#28) | FRAGILE |
| [himalaya.nvim](https://github.com/JostBrand/himalaya.nvim) (fork) | 1 | 20 | April 2025 | Single-dev hobby fork | FRAGILE |
| [mountaineer.nvim](https://github.com/elmarsto/mountaineer.nvim) | 2 | 5 | June 2023 | **ARCHIVED** Jan 2024 | DEAD |
| [vim-himalaya-ui](https://github.com/aliyss/vim-himalaya-ui) | Low | 411 | Aug 2025 | "Not ready for use" | EXPERIMENTAL |

### Key Findings

1. **himalaya-vim (official) is abandoned.** The repo explicitly says "looking for new maintainers" (issue #28). The Pimalaya org hasn't found anyone. 115 stars over its lifetime but only 6 forks -- not enough community to sustain it.

2. **himalaya.nvim (JostBrand) is a 1-star hobby fork.** 20 commits by a single developer. Created April 2025. Could disappear at any time.

3. **mountaineer.nvim (Telescope integration) is archived.** Author described it as "a very raw first cut" built in 4 hours. Archived January 2024. No one continued it.

4. **vim-himalaya-ui has volume (411 commits) but warns "not ready for use."** It's one developer's learning project for vim plugin development.

---

## 2. Other Editor Integrations

| Editor | Plugin | Status | Notes |
|--------|--------|--------|-------|
| Emacs | [himalaya-emacs](https://github.com/dantecatalfamo/himalaya-emacs) | Community | Small, community-maintained |
| REPL | [himalaya-repl](https://github.com/pimalaya/himalaya-repl) | Official | Experimental REPL interface |
| Helix | None | N/A | No integrations exist |
| Kakoune | None | N/A | No integrations exist |
| VSCode | None | N/A | No integrations exist |
| Zed | None | N/A | No integrations exist |

**Conclusion:** himalaya's editor plugin ecosystem is sparse across ALL editors, not just vim/nvim. This reinforces that the `$EDITOR` pattern (which works with every editor) is the correct approach.

---

## 3. himalaya Native Editor Support (Key Discovery)

himalaya provides two mechanisms for editor integration that our spec should leverage:

### 3.1 `$EDITOR` via `message write/reply/forward`

```bash
# Opens $EDITOR with a pre-populated MML template
himalaya message write
himalaya message reply <ID>
himalaya message forward <ID>
```

These commands:
- Generate an MML (MIME Meta Language) template with headers pre-filled
- Open `$EDITOR` for the user to edit
- On save+quit, send the message

### 3.2 `[BODY]` Positional Argument (NEW FINDING)

```bash
# Pre-fill the body text BEFORE opening $EDITOR
himalaya message write "Dear Dr. Smith," "Thank you for your email."
himalaya message reply <ID> "Thank you for reaching out."
```

The `[BODY]...` argument accepts one or more strings that get injected into the template body before `$EDITOR` opens. This means:

- AI-generated drafts can be injected directly via the CLI
- No temp file needed
- User sees the draft already populated when nvim opens
- User edits as needed, saves, quits -- same `git commit` muscle memory

### 3.3 `template` Subsystem (SCRIPTING API)

```bash
# Generate template WITHOUT opening $EDITOR
himalaya template write              # Returns MML template to stdout
himalaya template reply <ID>         # Returns reply template to stdout
himalaya template forward <ID>       # Returns forward template to stdout

# Send template from stdin WITHOUT $EDITOR
himalaya template send < draft.mml   # Sends MML from stdin directly
```

The `template` subsystem is the **scripting API** that separates template generation from the interactive `$EDITOR` step. This enables:

1. **Pure-pipe AI workflow:** `template reply <ID>` -> inject AI body -> `template send`
2. **Batch operations:** Generate and send without any editor interaction
3. **Preview before edit:** Generate template, show to user, then open in editor only if they want to modify

---

## 4. Implications for `em` Dispatcher Architecture

### 4.1 Updated AI Draft Pipeline

**OLD approach (spec v0.1.0):** Temp file based
```
AI generates draft -> write to temp file -> open $EDITOR -> read back -> himalaya send < file
```

**NEW approach (using native himalaya features):**

#### Interactive Reply (user edits in nvim):
```
em reply <ID>
  -> AI generates draft body via _em_ai_query("draft", ...)
  -> himalaya message reply <ID> "$ai_draft"
     (himalaya opens $EDITOR with draft pre-populated)
  -> user edits, saves, quits (:wq)
  -> himalaya sends automatically
```

#### Non-interactive Reply (AI sends directly after confirmation):
```
em respond --send <ID>
  -> himalaya template reply <ID>   (get MML template)
  -> inject AI draft body into MML
  -> show preview to user
  -> _flow_confirm "Send this reply? [y/N]"
  -> himalaya template send < modified.mml
```

### 4.2 Updated Adapter Functions

The adapter layer in `lib/em-himalaya.zsh` needs these changes:

| Function | Old Design | New Design |
|----------|-----------|------------|
| `_em_hml_reply()` | `himalaya message reply <ID>` (opens editor with blank body) | `himalaya message reply <ID> "$body"` (pre-fills AI draft) |
| `_em_hml_send()` | `himalaya message send < file` (reads from temp file) | `himalaya template send` (reads MML from stdin) |
| NEW: `_em_hml_template_reply()` | N/A | `himalaya template reply <ID>` (returns MML, no editor) |
| NEW: `_em_hml_template_write()` | N/A | `himalaya template write` (returns MML, no editor) |
| NEW: `_em_hml_template_send()` | N/A | `himalaya template send` (sends MML from stdin) |

### 4.3 Two-Path Architecture

The `em reply` command should support both paths:

```
em reply <ID>              # Interactive: AI draft -> $EDITOR -> send
em reply <ID> --no-ai      # Interactive: blank body -> $EDITOR -> send
em reply <ID> --batch      # Non-interactive: AI draft -> confirm -> send
```

---

## 5. MML (MIME Meta Language) Format

himalaya uses MML as its template format. Example reply template:

```
From: dtofighi@unm.edu
To: student@unm.edu
In-Reply-To: <original-message-id>
Subject: Re: Question about Assignment 3

<body goes here>
```

For the `em` dispatcher, we need to:
1. Parse the `From`/`To`/`Subject` headers from MML for preview display
2. Inject AI-generated body between headers and any signature
3. Preserve `In-Reply-To` and threading headers

---

## 6. Recommendations

### Immediate (Update Spec)

1. **Update `_em_hml_reply()`** to use `[BODY]` argument for AI draft injection
2. **Add `_em_hml_template_reply()`** for non-interactive pipeline
3. **Add `_em_hml_template_send()`** for sending MML from stdin
4. **Remove temp-file references** from the respond workflow

### Phase 1 Implementation

- Use `himalaya message reply <ID> "$draft"` for interactive replies
- Use `himalaya template reply/send` for batch operations
- Both paths go through the same safety gate (`_flow_confirm`)

### Future Consideration

- MML manipulation utilities (header parsing, body injection) in `lib/em-mml.zsh`
- Template caching for faster batch operations
- MML-to-preview renderer for terminal display

---

## Sources

- [himalaya GitHub](https://github.com/pimalaya/himalaya) -- v1.1.0, 5.4K stars
- [himalaya CLI help](~/.cargo/bin/himalaya message write --help) -- `[BODY]...` positional arg
- [himalaya template help](~/.cargo/bin/himalaya template --help) -- write/reply/forward/send
- [himalaya-vim](https://github.com/pimalaya/himalaya-vim) -- "looking for new maintainers"
- [himalaya.nvim](https://github.com/JostBrand/himalaya.nvim) -- 1 star, 20 commits
- [mountaineer.nvim](https://github.com/elmarsto/mountaineer.nvim) -- Archived Jan 2024
- [vim-himalaya-ui](https://github.com/aliyss/vim-himalaya-ui) -- "not ready for use"
- [himalaya-emacs](https://github.com/dantecatalfamo/himalaya-emacs) -- Community Emacs integration
- [Pimalaya org](https://github.com/pimalaya) -- himalaya-repl, Neverest, Mirador, Cardamum
