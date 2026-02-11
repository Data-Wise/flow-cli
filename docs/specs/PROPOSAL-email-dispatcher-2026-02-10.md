# PROPOSAL: Email Dispatcher (`em`) — Issue #331

**Generated:** 2026-02-10
**Issue:** https://github.com/Data-Wise/flow-cli/issues/331
**Status:** Brainstorm

## Overview

Add an `em` dispatcher wrapping himalaya CLI with ADHD-friendly email management — fzf pickers, smart rendering, notifications, and dashboard integration.

---

## Options

### Option A: Minimal Dispatcher (Quick Win)
**Effort:** 2-3 hours

Just the dispatcher shell + core aliases. No fzf, no rendering pipeline, no notifications.

```zsh
em() {
    case "$1" in
        inbox|i)   shift; _em_inbox "$@" ;;
        read|r)    shift; _em_read "$@" ;;
        send|s)    shift; _em_send "$@" ;;
        reply|re)  shift; _em_reply "$@" ;;
        find|f)    shift; _em_find "$@" ;;
        folders)   shift; _em_folders "$@" ;;
        unread|u)  shift; _em_unread "$@" ;;
        help|--help|-h) _em_help ;;
        *) _em_help ;;
    esac
}
```

**Pros:** Ships fast, establishes pattern, zero optional deps
**Cons:** Not much value over raw himalaya

### Option B: Full Dispatcher + fzf Picker (Recommended)
**Effort:** 6-8 hours

Core dispatcher + fzf email picker + smart rendering + `teach doctor` integration.

Adds:
- `em pick` — fzf interactive email browser with preview
- `em dash` — quick dashboard (unread count + latest 10)
- `em html <ID>` — HTML rendering via w3m
- Smart pager: HTML → w3m, Markdown → glow, fallback → bat
- `flow doctor` checks for himalaya + optional deps

**Pros:** Real productivity value, ADHD-friendly browsing, consistent with flow-cli DX
**Cons:** More work, needs w3m/bat/fzf (but these are already common in the ecosystem)

### Option C: Full Stack (Max Features)
**Effort:** 12-16 hours (multi-session)

Everything in Option B, plus:
- Notification system (IMAP IDLE watch + terminal-notifier fallback)
- `dash` integration (email section in master dashboard)
- `work` integration (email context per project — filter by sender/subject)
- Offline search via Notmuch/Neverest backend
- LaunchAgent for background poll
- Per-project email filters in `.flow/email-config.yml`

**Pros:** Complete email workflow, deep flow-cli integration
**Cons:** Massive scope, himalaya pre-1.0 risk, launchd complexity

---

## Recommended Path: Option B (phased)

Ship Option B as v1, then incrementally add Option C features.

### Phase 1: Core Dispatcher (v1)
- `em` dispatcher with 8 subcommands
- fzf picker with preview pane
- Smart rendering pipeline (w3m/glow/bat)
- `em dash` for quick inbox check
- `flow doctor` integration (himalaya health check)
- Help system following existing patterns

### Phase 2: Notifications (v2)
- `em watch` — IMAP IDLE via `himalaya envelope watch`
- terminal-notifier integration
- `em watch --daemon` for background operation

### Phase 3: Deep Integration (v3)
- `dash` command email section
- `work` command email context
- Per-project email filters
- Notmuch offline search (if himalaya stabilizes)

---

## Architecture

### Files

| File | Purpose |
|------|---------|
| `lib/dispatchers/email-dispatcher.zsh` | Main dispatcher |
| `lib/email-helpers.zsh` | Rendering pipeline, fzf integration |
| `completions/_em` | ZSH completions |
| `tests/test-email-dispatcher.zsh` | Unit tests |
| `tests/e2e-email-dispatcher.zsh` | E2E tests (mocked himalaya) |
| `docs/reference/REFCARD-EMAIL.md` | Quick reference |
| `docs/guides/EMAIL-SETUP-GUIDE.md` | Setup guide |

### Subcommands

| Command | Alias | Description |
|---------|-------|-------------|
| `em inbox [N]` | `em i` | List inbox (default 25, configurable) |
| `em read <ID>` | `em r` | Read message with smart rendering |
| `em send` | `em s` | Compose new message |
| `em reply <ID>` | `em re` | Reply to message |
| `em find <query>` | `em f` | Search emails |
| `em pick [FOLDER]` | `em p` | fzf interactive picker with preview |
| `em unread` | `em u` | Unread count (fast, cached) |
| `em dash` | `em d` | Dashboard: unread + latest 10 |
| `em folders` | — | List folders |
| `em html <ID>` | — | Render HTML email |
| `em attach <ID>` | `em a` | Download attachments |
| `em doctor` | — | Check email dependencies |
| `em help` | — | Help page |

### Smart Rendering Pipeline

```
┌─────────────────────────────────────────┐
│ himalaya message read <ID>              │
│           ↓                             │
│ Detect content type                     │
│           ↓                             │
│ ┌─────────┴─────────┐                   │
│ │ text/html         │ text/plain        │
│ │      ↓            │      ↓            │
│ │ w3m -dump         │ Detect markdown?  │
│ │      ↓            │ ┌────┴────┐       │
│ │ bat --paging      │ │ Yes     │ No    │
│ │                   │ │ glow    │ bat   │
│ └───────────────────┘ └─────────┘       │
└─────────────────────────────────────────┘
```

### fzf Picker Design

```zsh
_em_pick() {
    local folder="${1:-INBOX}"
    himalaya envelope list -f "$folder" --output json \
        | jq -r '.[] | "\(.id)\t\(.flags)\t\(.from.name // .from.addr)\t\(.subject)\t\(.date)"' \
        | fzf --delimiter='\t' \
              --with-nth='2..' \
              --preview='himalaya message read {1} | bat --style=plain --color=always' \
              --preview-window='right:60%:wrap' \
              --header='📬 Email Picker (Enter=read, Ctrl-R=reply, Ctrl-D=delete)' \
              --bind='enter:execute(himalaya message read {1} | bat --paging=always)' \
              --bind='ctrl-r:execute(himalaya message reply {1})' \
              --bind='ctrl-d:execute(himalaya envelope flag add {1} Deleted)'
}
```

### Config Integration

```yaml
# .flow/email-config.yml (optional, per-project)
email:
  default_folder: INBOX
  page_size: 25
  render_html: true      # auto-detect and render HTML
  notifications: false   # IMAP IDLE watch
  color_theme: tokyo     # tokyo | default | minimal
```

### Doctor Integration

Add to `flow doctor` or `em doctor`:

```
Email Dependencies:
  ✓ himalaya (v1.0.0-beta.5)
  ✓ email-oauth2-proxy (running, pid 1234)
  ✓ w3m (HTML rendering)
  ✓ bat (paging)
  ✓ fzf (interactive picker)
  ✗ glow (Markdown rendering — optional)
  ✗ terminal-notifier (notifications — optional)
```

---

## Display Theme (Tokyo Night)

```toml
# himalaya config.toml additions
[accounts.lobomail.envelope.list.table]
preset = "utf8"
name_color = "blue"
date_fmt = "%b %d %H:%M"

[accounts.lobomail.envelope.list.table.unseen_char]
value = "+"
color = "cyan"

[accounts.lobomail.envelope.list.table.flagged_char]
value = "!"
color = "magenta"

[accounts.lobomail.envelope.list.table.attachment_char]
value = "@"
color = "yellow"
```

---

## Testing Strategy

### Unit Tests (mocked)
- Subcommand routing (all 13 commands)
- Help output
- Config reading (default + per-project)
- Rendering pipeline selection (HTML → w3m, markdown → glow, plain → bat)
- fzf command construction

### E2E Tests (sandboxed)
- `em inbox` with mocked himalaya output
- `em pick` fzf invocation (non-interactive)
- `em doctor` dependency checks
- `em dash` dashboard formatting

### Dogfood Tests
- Full plugin load with email dispatcher
- Help compliance
- Completion loading

---

## Dependencies Risk Assessment

| Dep | Required | Risk | Mitigation |
|-----|----------|------|------------|
| himalaya | Yes | Pre-1.0, API may change | Pin version, abstract commands |
| email-oauth2-proxy | Yes (for O365) | Stable, maintained | launchd service, auto-restart |
| w3m | Recommended | Very stable | Graceful fallback to `cat` |
| bat | Recommended | Very stable | Graceful fallback to `less` |
| fzf | Recommended | Very stable | `em list` fallback without fzf |
| glow | Optional | Stable | Skip markdown rendering |
| jq | Recommended | Very stable | Fallback to text parsing |
| terminal-notifier | Optional | Stable | Phase 2, not required |

---

## Quick Wins (ship in 2 hours)

1. `lib/dispatchers/email-dispatcher.zsh` — skeleton with `inbox`, `read`, `send`, `reply`, `find`, `help`
2. `completions/_em` — basic completion
3. Register in `flow.plugin.zsh`
4. `docs/reference/REFCARD-EMAIL.md` — quick reference

## Decisions Needed

| Question | Options | Recommendation |
|----------|---------|----------------|
| Dispatcher name | `em` vs `mail` vs `email` | `em` (2 chars, fast to type) |
| Phase 1 scope | Option A vs B | Option B (fzf picker is the killer feature) |
| himalaya JSON vs text | JSON parsing vs text | JSON (more reliable, enables fzf preview) |
| Config location | Global only vs per-project | Both (global default + `.flow/email-config.yml` override) |
| Doctor integration | `flow doctor` vs `em doctor` | Both (quick check in flow doctor, detailed in em doctor) |

---

## Next Steps

1. Approve scope (Option A / B / C)
2. Create worktree: `git worktree add ~/.git-worktrees/flow-cli/feature-email -b feature/email-dispatcher dev`
3. Implement Phase 1
4. Test with real LoboMail account
5. Ship as v6.8.0 (new dispatcher = minor bump)
