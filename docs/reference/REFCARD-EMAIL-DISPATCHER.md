# Email Dispatcher Quick Reference

> All `em` subcommands at a glance. For detailed guides, see linked documentation.
>
> **Version:** v7.0.0 | **Dispatcher:** `lib/dispatchers/email-dispatcher.zsh`

## Command Taxonomy

```mermaid
mindmap
  root((em<br/>18 commands))
    Core Email<br/>4 commands
      inbox
      read
      send
      reply
    Search & Browse<br/>2 commands
      find
      pick
    AI Features<br/>3 commands
      respond
      classify
      summarize
    Quick Info<br/>3 commands
      unread
      dash
      folders
    Utilities<br/>3 commands
      attach
      html
      cache
    Infrastructure<br/>2 commands
      doctor
      help
```

## All Commands at a Glance

| Command | Aliases | Synopsis | Description |
|---------|---------|----------|-------------|
| **em** | — | `em` | Quick pulse (unread + 10 latest) |
| **em inbox** | `i` | `em inbox [N] [FOLDER]` | List N recent emails (default: 25) |
| **em read** | `r` | `em read <ID>` | Read email with smart rendering |
| **em send** | `s` | `em send [--ai] [to] [subject]` | Compose new email |
| **em reply** | `re` | `em reply <ID> [--no-ai] [--all] [--batch]` | Reply with optional AI draft |
| **em find** | `f` | `em find <query>` | Search emails (subject, from, body) |
| **em pick** | `p` | `em pick [FOLDER]` | fzf browser with preview & actions |
| **em respond** | `resp` | `em respond [--review] [-n COUNT] [--folder F] [--clear]` | Batch AI draft generation |
| **em classify** | `cl` | `em classify <ID>` | Classify email (AI) |
| **em summarize** | `sum` | `em summarize <ID>` | One-line summary (AI) |
| **em unread** | `u` | `em unread [FOLDER]` | Show unread count |
| **em dash** | `d` | `em dash` | Quick dashboard (unread + recent) |
| **em folders** | — | `em folders` | List mail folders |
| **em html** | — | `em html <ID>` | Render HTML email in terminal |
| **em attach** | `a` | `em attach <ID> [OUT_DIR]` | Download attachments |
| **em cache** | — | `em cache <action>` | Cache operations (stats, clear, warm) |
| **em doctor** | `dr` | `em doctor` | Dependency health check |
| **em help** | `h, --help` | `em help` | Show all commands |

---

## Configuration

Environment variables (set in shell, `.env`, or `.flow/email.conf`):

| Variable | Default | Type | Description |
|----------|---------|------|-------------|
| `FLOW_EMAIL_AI` | `claude` | enum | AI backend: `claude` \| `gemini` \| `none` |
| `FLOW_EMAIL_PAGE_SIZE` | `25` | int | Default inbox list size |
| `FLOW_EMAIL_FOLDER` | `INBOX` | string | Default folder (mailbox name) |
| `FLOW_EMAIL_AI_TIMEOUT` | `30` | int | AI draft timeout in seconds |

Load order: env vars → `.flow/email.conf` (project) → `$FLOW_CONFIG_DIR/email.conf` (global)

---

## Architecture Diagram

```mermaid
graph TD
    A["em dispatcher<br/>18 commands"] -->|adapter layer| B["himalaya CLI<br/>(email backend)"]
    A -->|cache layer| C["em-cache<br/>(TTL: 1h-24h)"]
    A -->|AI abstraction| D["em-ai<br/>Backend: claude/gemini"]
    A -->|render pipeline| E["em-render<br/>Smart content detection"]
    D -->|fallback chain| D1["claude"]
    D -->|fallback chain| D2["gemini"]
    E -->|HTML| E1["w3m → lynx → pandoc → bat"]
    E -->|Markdown| E2["glow → bat"]
    E -->|Plain| E3["bat → cat"]
    B -->|OAuth2| B1["email-oauth2-proxy<br/>(for Gmail, etc.)"]
    C -->|cache dir| C1[".flow/email-cache/<br/>summaries, classifications, drafts, schedules"]
```

---

## AI Backends

Three backends available; configured via `$FLOW_EMAIL_AI`:

### Backend: Claude

**Command:** `claude -p "<prompt>" --output-format text`

**Availability Check:**
```bash
command -v claude &>/dev/null && echo "installed" || echo "missing"
```

**Operations:** classify, summarize, draft (reply), schedule

### Backend: Gemini

**Command:** `gemini "<prompt>"`

**Availability Check:**
```bash
command -v gemini &>/dev/null && echo "installed" || echo "missing"
```

**Install:** `pip install google-generativeai`

### Fallback Chain

If configured backend unavailable: `claude` → `gemini` → `none` (timeout gracefully)

---

## Render Pipeline

Smart content detection and rendering:

| Content Type | Detection | Render Chain | Fallback |
|-------------|-----------|--------------|----------|
| **HTML** | `<html>`, `<body>`, `<div>`, `<table>`, `<p>` | w3m → lynx → pandoc → bat | raw HTML |
| **Markdown** | `#`, `**`, `` ` ``, `- [` | glow → bat | plain text |
| **Plain Text** | — | bat --style=plain | cat |

Commands:
- **w3m** (primary): `w3m -dump -T text/html`
- **lynx** (fallback): `lynx -stdin -dump`
- **pandoc** (fallback): `pandoc -f html -t plain`
- **bat** (syntax highlighting): `bat --style=plain --color=always`
- **glow** (markdown): `glow -` (auto-pager)

---

## Safety Features

### Send Safety Gate

Every send (compose, reply, batch) requires explicit confirmation:

```
Send this email? [y/N]
```

**Default:** No (requires `y` or `Y` to proceed)

**Applies to:**
- `em send` → `em send`
- `em reply <ID>` (batch mode `--batch`) → confirm before send
- `em respond --review` → per-draft confirmation

### Draft Preservation

Rejected sends preserve draft for later:

```bash
em respond --review    # Review & send saved drafts
em cache clear         # Clear all cached drafts if needed
```

---

## fzf Key Bindings (em pick)

Interactive fzf email browser with preview:

| Key | Action | Details |
|-----|--------|---------|
| **Enter** | Read email | Default action, shows full content |
| **Ctrl-R** | Reply | Open reply with AI draft |
| **Ctrl-S** | Summarize | Generate 1-line summary (AI) |
| **Ctrl-A** | Archive | Mark as read (folders archives) |
| **Ctrl-D** | Delete | Flag for deletion (with confirm) |
| **Escape** | Exit | Return to shell |

**Header Info:** Folder, unread count, legend

**Indicators:**
- `*` = unread
- `+` = has attachment

---

## AI Operations & Timeouts

Per-operation timeout configuration (seconds):

| Operation | Default Timeout | Backend Preference | Cache TTL |
|-----------|-----------------|-------------------|-----------|
| `classify` | 10s | configured backend | 24h |
| `summarize` | 15s | configured backend | 24h |
| `draft` | 30s | configured backend | 1h |
| `schedule` | 15s | configured backend | 24h |

**Override:** `FLOW_EMAIL_AI_TIMEOUT=<seconds>` (global for all ops)

---

## Cache System

TTL-based AI result caching (project-local):

### Cache Directory Structure

```
.flow/email-cache/
  summaries/           (one-line summaries)
  classifications/     (email categories)
  drafts/              (reply drafts)
  schedules/           (extracted dates/times)
  unread/              (unread count)
```

### TTL Defaults

| Operation | TTL | Reason |
|-----------|-----|--------|
| summaries | 24h | Content rarely changes |
| classifications | 24h | Category is stable |
| drafts | 1h | May need refreshing |
| schedules | 24h | Dates don't change |
| unread | 1m | Count changes often |

### Cache Commands

```bash
em cache stats                  # Show cache usage
em cache clear                  # Clear all cached AI results
em cache warm                   # Pre-warm cache (background)
```

---

## Quick Examples

### Daily Workflow

```bash
# ─────────────────────────────────────────────────────────────
# Quick pulse check
em                              # Unread count + 10 latest

# ─────────────────────────────────────────────────────────────
# Reading & replying
em r 42                         # Read email #42
em re 42                        # Reply with AI draft
em re 42 --no-ai                # Reply without AI
em re 42 --all                  # Reply-all
em re 42 --batch                # Non-interactive (preview+confirm)

# ─────────────────────────────────────────────────────────────
# Composing
em s                            # New email (opens $EDITOR)
em s --ai "Subject here"        # AI draft from subject

# ─────────────────────────────────────────────────────────────
# Browsing & search
em i                            # List recent emails (25)
em i 50                         # List 50 emails
em i 25 "Sent Items"            # List folder
em p                            # fzf browser (interactive)
em f "quarterly report"         # Search emails

# ─────────────────────────────────────────────────────────────
# AI features
em classify 42                  # Classify email (AI)
em sum 42                       # One-line summary (AI)
em respond                      # Batch draft generation
em respond --review             # Review + send drafts
em respond -n 50                # Process 50 emails

# ─────────────────────────────────────────────────────────────
# Quick info
em u                            # Show unread count
em d                            # Quick dashboard
em folders                      # List folders
em html 42                      # Render HTML in terminal

# ─────────────────────────────────────────────────────────────
# Attachments
em attach 42                    # Download attachments
em attach 42 ~/Downloads        # Save to specific directory

# ─────────────────────────────────────────────────────────────
# Management
em cache stats                  # Show cache usage
em cache clear                  # Clear cached AI results
em doctor                       # Check dependencies
em h                            # Show help
```

---

## Doctor Checks

Run `em doctor` for dependency health:

### Required

| Tool | Purpose | Install |
|------|---------|---------|
| `himalaya` | Email CLI backend | `cargo install himalaya` or `brew install himalaya` |
| `jq` | JSON processing | `brew install jq` |

### Recommended

| Tool | Purpose | Install |
|------|---------|---------|
| `fzf` | Interactive picker | `brew install fzf` |
| `bat` | Syntax highlighting | `brew install bat` |
| `w3m` | HTML rendering (primary) | `brew install w3m` |
| `lynx` | HTML fallback | `brew install lynx` |
| `pandoc` | HTML to plain (fallback) | `brew install pandoc` |
| `glow` | Markdown rendering | `brew install glow` |

### Optional (Infrastructure)

| Tool | Purpose | Install |
|------|---------|---------|
| `email-oauth2-proxy` | OAuth2 IMAP/SMTP proxy (Gmail, etc.) | `pip install email-oauth2-proxy` |
| `terminal-notifier` | Desktop notifications | `brew install terminal-notifier` |

### Optional (AI)

| Backend | Detection | Install |
|---------|-----------|---------|
| Claude | When `FLOW_EMAIL_AI=claude` | `npm install -g @anthropic-ai/claude-code` |
| Gemini | When `FLOW_EMAIL_AI=gemini` | `pip install google-generativeai` |

---

## Email Classifications

AI classification categories (for `em classify`, `em respond`):

| Category | Icon | Actionable | Description |
|----------|------|-----------|-------------|
| `student-question` | Q | ✓ | Academic query, assignment question, grade inquiry |
| `admin-important` | ! | ✓ | Department notice, policy, deadline — requires action |
| `admin-info` | i | ✗ | FYI notices, institutional newsletters |
| `scheduling` | S | ✓ | Meeting request, calendar invite, office hours |
| `newsletter` | N | ✗ | External newsletter, marketing, mailing list |
| `personal` | P | ✓ | Colleague, friend, non-work context |
| `automated` | A | ✗ | CI/CD, GitHub, system alerts, receipts |
| `urgent` | U | ✓ | Deadline today, emergency, escalation |

**Non-actionable emails skipped by `em respond`** (admin-info, newsletter, automated)

---

## Common Workflows

### New Session — Quick Pulse

```bash
em                              # Unread count + 10 latest
em u                            # How many unread?
em d                            # Full dashboard
```

### Processing Emails

```bash
em p                            # Browse with fzf
# (Enter=read, Ctrl-R=reply, Ctrl-S=summarize, Ctrl-A=archive)
```

### Batch Draft Generation

```bash
em respond                      # Generate AI drafts for actionable emails
em respond --review             # Review and send generated drafts
em respond --clear              # Clear all cached drafts
```

### Replying

```bash
# Interactive (opens $EDITOR)
em re 42                        # AI draft pre-populated
em re 42 --no-ai                # Manual composition
em re 42 --all                  # Reply to all

# Non-interactive (batch, preview + confirm)
em re 42 --batch                # Preview, then [y/N]
```

### Search & Find

```bash
em f "quarterly report"         # Subject/from/body search
em find "from:john"             # Search emails from John
em find "before:2026-01-01"     # IMAP search syntax
```

### HTML Emails

```bash
em r 42                         # Auto-detects HTML, renders smart
em html 42                      # Force HTML rendering
em html 42 | less               # Pipe to pager
```

### Attachments

```bash
em attach 42                    # Download to ~/Downloads
em attach 42 ~/Documents        # Custom directory
```

---

## Dispatcher Configuration Files

### Global Config

**Path:** `$FLOW_CONFIG_DIR/email.conf`

**Example:**
```bash
FLOW_EMAIL_AI=claude
FLOW_EMAIL_PAGE_SIZE=30
FLOW_EMAIL_FOLDER=INBOX
FLOW_EMAIL_AI_TIMEOUT=45
```

### Project Config (Override)

**Path:** `.flow/email.conf` (in project root)

Takes precedence over global config.

### Himalaya Setup

**Required:** Configure email account first

```bash
himalaya account list           # Show configured accounts
himalaya account add            # Add new account (interactive)
```

For Gmail/OAuth2: `email-oauth2-proxy` recommended (see `em doctor`)

---

## Related Commands

### Flow-cli Layer 1

- **`work`** — Start session (integrates with email via `em dash`)
- **`flow doctor`** — Full system health (includes email subsystem)

### Other Dispatchers

- **`g`** — Git (workflows)
- **`obs`** — Obsidian (quick notes about emails)
- **`tm`** — Terminal manager (email session windows)

### External Tools

- **Himalaya** — Native email CLI (https://github.com/pimalaya/himalaya)
- **Claude Code** — For AI-powered workflows

---

## Architecture Overview

### Layer 1: Dispatcher (`em()`)

Pure ZSH dispatcher. 18 public commands. <10ms response.

### Layer 2: Adapters

- **`em-himalaya.zsh`** — Isolates himalaya CLI specifics
- **`em-cache.zsh`** — TTL-based AI caching
- **`em-ai.zsh`** — Backend abstraction (claude/gemini)
- **`em-render.zsh`** — Content detection + rendering

### Layer 3: Infrastructure

- **Himalaya CLI** — IMAP/SMTP backend
- **email-oauth2-proxy** — OAuth2 for Gmail, Outlook, etc.
- **render chain** — w3m, lynx, pandoc, bat, glow

---

## Troubleshooting

### Problem: "himalaya not found"

**Solution:**
```bash
brew install himalaya          # macOS
cargo install himalaya         # Universal

# Verify
himalaya account list
```

### Problem: "Email ID required"

**Cause:** Missing message ID argument

**Solution:**
```bash
em inbox                        # List emails with IDs
em read 42                      # Use actual ID
```

### Problem: "Cannot connect to mailbox"

**Cause:** Himalaya account not configured

**Solution:**
```bash
himalaya account add           # Add account interactively
himalaya account list          # Verify setup
em doctor                      # Check status
```

### Problem: "AI timed out"

**Cause:** Backend slow or unavailable

**Solution:**
```bash
# Increase timeout
export FLOW_EMAIL_AI_TIMEOUT=60

# Or skip AI
em re 42 --no-ai               # Reply without draft
em respond --clear             # Clear bad drafts
```

### Problem: "No fzf for picker"

**Cause:** `fzf` not installed

**Solution:**
```bash
brew install fzf
em p                           # Try again
```

---

## See Also

### Comprehensive Guides

- [EMAIL-DISPATCHER-GUIDE.md](../guides/EMAIL-DISPATCHER-GUIDE.md) — Complete workflow guide
- [HIMALAYA-SETUP.md](../guides/HIMALAYA-SETUP.md) — Email account configuration

### References

- [MASTER-DISPATCHER-GUIDE.md](MASTER-DISPATCHER-GUIDE.md) — All 13 dispatchers
- [MASTER-API-REFERENCE.md](MASTER-API-REFERENCE.md) — Function signatures
- [MASTER-ARCHITECTURE.md](MASTER-ARCHITECTURE.md) — System design

### External

- [Himalaya Documentation](https://pimalaya.org/)
- [email-oauth2-proxy](https://github.com/simonthum/email-oauth2-proxy)

---

**Version:** v7.0.0
**Last Updated:** 2026-02-10
**Commands:** 18 total (4 core + 2 search + 3 AI + 3 info + 3 util + 2 infra + 1 help)
