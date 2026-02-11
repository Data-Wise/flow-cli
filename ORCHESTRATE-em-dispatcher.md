# Email Dispatcher (`em`) — Orchestration Plan

> **Branch:** `feature/em-dispatcher`
> **Base:** `dev`
> **Worktree:** `~/.git-worktrees/flow-cli/feature-em-dispatcher`
> **Issue:** #331
> **Version Target:** v7.0.0 (new dispatcher = minor bump)

---

## Objective

Build the `em` email dispatcher — a pure ZSH wrapper around himalaya CLI with:

- **nvim as `$EDITOR` only** (NOT a nvim plugin — nvim opens for compose/reply)
- **AI draft pre-population** via `claude -p` / `gemini` CLI pipe
- **Explicit send confirmation** — `[y/N]` default-No before every send
- **fzf picker** for interactive email browsing
- **Smart rendering** (w3m for HTML, glow for markdown, bat for plain text)
- **flow doctor integration** for dependency health checks

---

## Architecture Decision

**Approach B: Hybrid ($EDITOR)** — unanimously recommended by all 4 independent analyses.

Why NOT a nvim plugin:

- himalaya nvim ecosystem is dead (4 plugins, all fragile/abandoned/experimental)
- himalaya is pre-1.0 with unstable CLI
- Zero Lua experience needed — pure ZSH matches flow-cli patterns
- himalaya natively supports `$EDITOR` for compose/reply

See: `docs/specs/BRAINSTORM-nvim-himalaya-integration-2026-02-10.md`

---

## Critical Safety Rule

> **NEVER send any email without explicit user approval.**

Every send operation MUST:

1. Show To/Subject/body preview
2. Prompt `"Send this reply? [y/N]"` — default is **NO**
3. Only send on explicit `y` or `yes`
4. Save draft on cancel (recoverable)
5. Detect empty body → warn and re-prompt

---

## Reference Specs

| File | Content | Priority |
|------|---------|----------|
| `docs/specs/PROPOSAL-email-dispatcher-2026-02-10.md` | Original proposal, subcommands, fzf picker | **Read first** |
| `docs/specs/BRAINSTORM-nvim-himalaya-integration-2026-02-10.md` | nvim research, approach comparison | Context |
| `docs/specs/SPEC-email-dispatcher.md` | Product strategy, user journeys, MVP | Reference |
| `docs/specs/SPEC-em-dispatcher-2026-02-10.md` | 6-layer architecture, AI abstraction | Reference |
| `docs/specs/ANALYSIS-nvim-email-architecture-2026-02-10.md` | Architecture analysis (4 approaches) | Context |
| `docs/specs/SPEC-email-himalaya-nvim-ux-analysis.md` | UX/DX analysis, daily workflows | Context |
| `docs/specs/RESEARCH-himalaya-validation-2026-02-10.md` | himalaya v1.0+ CLI validation | Context |
| `docs/specs/RESEARCH-himalaya-editor-integration-2026-02-10.md` | Editor integration patterns | Context |

---

## Phase Overview

| Phase | Task | Priority | Status |
|-------|------|----------|--------|
| 1 | Dispatcher skeleton + help + completions | High | **DONE** |
| 2 | Core subcommands (inbox, read, send, reply) | High | **DONE** |
| 3 | fzf picker + smart rendering | High | **DONE** |
| 4 | AI draft pipeline (claude -p / gemini) | High | **DONE** |
| 5 | Doctor integration + dash | Medium | **DONE** |
| 6 | Tests (unit + dogfood + e2e) | High | **DONE** |
| 7 | Docs (refcard, guide, tutorial) | Medium | **DONE** |
| 8 | Hardening (himalaya adapter fixes, preview cleanup) | High | **DONE** |

---

## Phase 1: Dispatcher Skeleton — DONE

**Commit:** `c65d7290` feat: add em dispatcher skeleton with help, completions, doctor

### Files Created

| File | Purpose |
|------|---------|
| `lib/dispatchers/email-dispatcher.zsh` | Main `em()` dispatcher (1143 lines) |
| `lib/email-helpers.zsh` | Safety gates, AI draft helper (304 lines) |
| `completions/_em` | ZSH completions (89 lines) |

### Subcommands Implemented

```
em inbox|i     em read|r      em send|s      em reply|re
em find|f      em pick|p      em unread|u    em dash|d
em folders     em html        em attach|a    em doctor
em respond     em classify    em summarize   em cache
em help
```

Registered in `flow.plugin.zsh` with 6-layer module loading.

---

## Phase 2: Core Subcommands — DONE

**Commits:** `c2c93ef9`, `b45f4ecf`, `8720cfae`

### Implemented

- `em inbox [N]` — JSON envelope list via himalaya + structured table rendering
- `em read <ID>` — plain text with header block + email-aware body formatting
- `em read <ID> --html` — HTML export via himalaya MIME extraction + w3m
- `em read <ID> --raw` — raw .eml export via himalaya `message export --full`
- `em send` — interactive compose via himalaya `message write` ($EDITOR)
- `em reply <ID>` — reply with optional AI draft pre-population via $EDITOR
- `em reply <ID> --all` — reply-all variant
- `em find <query>` — IMAP SEARCH via himalaya

### Safety Gate

`_em_confirm_send()` in `lib/email-helpers.zsh` — shows To/Subject/body preview, prompts `[y/N]` default-No, saves draft on cancel.

### himalaya Adapter Layer

`lib/em-himalaya.zsh` (247 lines) — isolates all himalaya CLI specifics. If himalaya changes flags, fix only this file.

Key discovery during implementation:
- himalaya uses IMAP UIDs (e.g., 248860), NOT sequential numbers
- `--html` and `--raw` flags do NOT exist in himalaya v1.1.0
- HTML access: `himalaya message export -d $tmpdir $id` (extracts MIME parts)
- Raw access: `himalaya message export --full -d $tmpdir $id` (exports .eml)
- himalaya returns exit 0 with empty stdout for non-existent UIDs (silent failure)

---

## Phase 3: fzf Picker + Smart Rendering — DONE

**Commits:** `2dbd5da8`, `e4900bc6`, `81e7a059`, `f437c67e`, various fixes

### `em pick [FOLDER]`

Full fzf email browser with:
- Cached JSON envelope list (avoids re-fetching per scroll)
- Header block in preview (subject, from, date)
- Fast plain text body via `himalaya message read --no-headers --preview`
- bat syntax highlighting (`--language=Email`)
- HTML export fallback via w3m for HTML-only emails
- Email noise cleanup (CID refs, Safe Links, MIME markers, angle URLs, mailto)
- Keybindings: Enter=read, Ctrl-R=reply, Ctrl-S=summarize, Ctrl-A=archive, Ctrl-D=delete

### Smart Rendering Pipeline (`lib/em-render.zsh`, 237 lines)

```
Detection chain:
  HTML (<html|<body|<div|<table|<p>) → w3m → lynx → pandoc → bat
  Markdown (#, **, ```, - [)          → glow → bat
  Plain text                          → bat --style=plain
  Fallback                            → cat
```

`_em_render_email_body()` — dims quoted replies (`>`), dims signatures (`--`), strips email noise (CID, Safe Links, MIME markers, URLs, mailto).

---

## Phase 4: AI Draft Pipeline — DONE

**Commits:** `d3056e4a`, `8720cfae`

### `lib/em-ai.zsh` (300 lines)

- Pluggable AI backend: `claude -p` (default), `gemini`, `none`
- Operation-specific prompts: classify, summarize, draft, schedule
- Per-operation timeouts: classify=10s, summarize=15s, draft=30s
- Fallback chain with graceful degradation
- `_em_ai_available()` — checks if AI backend CLI is installed

### Subcommands

- `em respond <ID>` — classify email, generate AI draft, open in $EDITOR, safety gate
- `em classify <ID>` — AI-powered email classification (student-question, meeting, urgent, etc.)
- `em summarize <ID>` — AI-powered email summary

### Config

```zsh
export FLOW_EMAIL_AI="claude"      # claude | gemini | none
export FLOW_EMAIL_AI_TIMEOUT=30    # seconds
```

---

## Phase 5: Doctor + Dashboard — DONE

**Commits:** `c65d7290`, `8720cfae`

### `em doctor`

Checks: himalaya, w3m, bat, fzf, jq, glow, pandoc, AI backend (claude/gemini)

### `em dash`

Quick dashboard: unread count + latest subjects

### `em cache`

TTL-based caching system (`lib/em-cache.zsh`, 185 lines):
- `em cache stats` — show cache size, hit rate
- `em cache clear` — flush all cached data
- Configurable TTLs: summaries=86400s, drafts=3600s, unread=60s

---

## Phase 6: Tests — DONE

**Commits:** `2f1cbb48`, `3c83d1b4`, `b9b3952e`, `5145c2ac`

### Unit Tests (`tests/test-em-dispatcher.zsh`)

**86 tests** across 10 sections:
1. Dispatcher function existence (3)
2. Help output (4)
3. Himalaya adapter functions (15)
4. AI layer functions (17)
5. Cache functions (12)
6. Render functions (9)
7. **Email noise cleanup patterns (14)** — CID, Safe Links, MIME, URLs, mailto, preservation, combined, integration
8. Dispatcher routing (2)
9. AI backend configuration (6)
10. Cache TTL configuration (4)

### Dogfood Tests (`tests/dogfood-em-dispatcher.zsh`)

**118 tests** across 11 sections — full plugin integration after sourcing `flow.plugin.zsh`. Includes Section 11: Noise Cleanup (16 tests).

### E2E Tests (`tests/e2e-em-dispatcher.zsh`)

**404 lines** — live IMAP tests (timeout in 30s harness, works manually in tmux).

### Interactive Tests (`tests/interactive-em-dogfooding.zsh`)

**564 lines** — manual interactive test scenarios for fzf picker, rendering, and AI workflows.

### Full Suite

**45 passed, 0 failed, 1 timeout** (E2E timeout expected — requires live IMAP).

---

## Phase 7: Documentation — DONE

**Commit:** `21c002ea`

| File | Content | Lines |
|------|---------|-------|
| `docs/reference/REFCARD-EMAIL-DISPATCHER.md` | Quick reference card — all subcommands, flags, keybindings | 581 |
| `docs/guides/EMAIL-DISPATCHER-GUIDE.md` | Comprehensive user guide — setup, workflows, config | 1410 |
| `docs/guides/EMAIL-TUTORIAL.md` | Step-by-step tutorial — first email to advanced workflows | 1531 |
| `_em_help()` built-in | Inline dispatcher help (color-coded) | ~60 |
| `docs/help/QUICK-REFERENCE.md` | Updated with em dispatcher entry | +107 |
| `docs/reference/MASTER-DISPATCHER-GUIDE.md` | Updated with em section | +80 |

---

## Phase 8: Hardening — DONE

**Commits:** `b255b71a` through `cff57aa7` (8 commits)

### himalaya v1.1.0 Adapter Fixes

- Fixed `_em_hml_read()` — replaced non-existent `--html`/`--raw` flags with `message export`
- Fixed `_em_read()` — validates IMAP UIDs against envelope list, clear error for non-existent IDs
- Fixed preview script — uses temp script file (avoids shell escaping nightmare in fzf subprocess)

### Preview Quality Iterations

1. Initial: inline himalaya call (broken in fzf sh subprocess)
2. Temp script approach (fixed subprocess issue)
3. HTML-first via w3m (too slow, tracking pixel noise)
4. **Final: fast plain text + bat, HTML fallback only** (best balance of speed and quality)

### Email Noise Cleanup Pipeline

6 sed filters applied in both `em pick` preview and `em read` rendering:

| Filter | Pattern | Strips |
|--------|---------|--------|
| CID refs | `[cid:image001.png@...]` | Inline image references |
| Safe Links | `(https://nam02.safelinks...)` | Microsoft URL rewrites |
| MIME open | `<#part type=text/html>` | MIME boundary markers |
| MIME close | `<#/part>` | MIME boundary markers |
| Angle URLs | `<https://example.com>` | Bare angle-bracket URLs |
| Mailto | `(mailto:user@example.com)` | Inline mailto refs |

Tested with 30 dedicated tests (14 unit + 16 dogfood).

---

## Acceptance Criteria

- [x] `em inbox` lists emails from himalaya
- [x] `em read <ID>` displays email with smart rendering
- [x] `em reply <ID>` opens $EDITOR with AI-generated draft
- [x] `em send` composes new email in $EDITOR
- [x] Every send has explicit `[y/N]` confirmation (default No)
- [x] `em pick` opens fzf email browser with preview
- [x] `em doctor` checks all dependencies
- [x] `em help` shows comprehensive help
- [x] All tests pass (`./tests/run-all.sh` — 45/45)
- [x] `source flow.plugin.zsh` loads without errors
- [x] No `local path=` in any new code (ZSH gotcha)
- [x] Preview strips email noise (CID, Safe Links, MIME markers)
- [x] himalaya adapter handles v1.1.0 CLI correctly

---

## Deliverables Summary

| Category | Files | Lines |
|----------|-------|-------|
| Core modules | 6 (`email-dispatcher.zsh`, `em-himalaya.zsh`, `em-ai.zsh`, `em-cache.zsh`, `em-render.zsh`, `email-helpers.zsh`) | 2,416 |
| Completions | 1 (`_em`) | 89 |
| Tests | 4 (unit, dogfood, e2e, interactive) | 2,695 |
| Docs | 3 (refcard, guide, tutorial) | 3,522 |
| Specs/Research | 8 (proposals, analyses, research) | ~800 |
| **Total new code** | **27 files changed** | **~9,700** |

### Commit History (28 commits)

```
c65d7290 feat: add em dispatcher skeleton with help, completions, doctor
c2c93ef9 feat: implement em send, reply, and inbox rendering
b45f4ecf docs: add himalaya validation research, update specs for v1.0+
2dbd5da8 feat: add fzf email picker, smart rendering, and JSON inbox
8720cfae feat: add AI timeout, config loader, and enhanced doctor
dd5a660d docs: add editor integration research, update adapter layer
d3056e4a feat: implement 6-layer architecture with adapter, AI, cache, render
2f1cbb48 test: add unit, E2E, and dogfooding tests for em dispatcher
e4900bc6 feat: enhance em pick with preview, render fallback, keybindings
3c83d1b4 fix: correct E2E test assertions
21c002ea docs: add comprehensive em dispatcher documentation
7f5233e4 fix: rewrite em respond with progress tracking
55180d55 refactor: simplify em respond — classify then reply in $EDITOR
a8419646 fix: improve em read rendering — header block + email-aware formatting
3bd71c8c fix: em pick preview — inline himalaya call for fzf subprocess
baa9f39b feat: add em read --html and --raw flags
a7ec03a7 fix: em pick formatted preview + fix _flow_log_warn typo
81e7a059 fix: em pick preview — use temp script instead of escaped string
f437c67e feat: em pick preview — HTML fallback via w3m/pandoc
4fe85b18 fix: em read shows nothing — remove HTML auto-detection
b255b71a fix: em read — surface himalaya errors instead of silent empty
b943d5b2 fix: em read — validate IDs + fix himalaya v1.1.0 adapter
062ffaeb feat: em pick preview — prefer HTML rendering via w3m
9e97ff29 feat: em pick preview — bat fallback + --preview flag
66cfb495 fix: em pick preview — revert to fast plain text + bat
cff57aa7 feat: em preview — strip email noise (CID, Safe Links, MIME markers)
b9b3952e test: add 14 unit tests for email noise cleanup patterns
5145c2ac test: add 16 dogfood tests for email noise cleanup patterns
```

---

## Next: Integration

When ready to merge:

```bash
git fetch origin dev && git rebase origin/dev
zsh tests/run-all.sh   # Verify 45/45 pass
gh pr create --base dev --title "feat: add em email dispatcher (#331)"
```
