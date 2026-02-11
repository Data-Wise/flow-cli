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

---

## Phase Overview

| Phase | Task | Hours | Priority | Status |
|-------|------|-------|----------|--------|
| 1 | Dispatcher skeleton + help + completions | 2-3h | High | |
| 2 | Core subcommands (inbox, read, send, reply) | 2-3h | High | |
| 3 | fzf picker + smart rendering | 2-3h | High | |
| 4 | AI draft pipeline (claude -p / gemini) | 2-3h | High | |
| 5 | Doctor integration + dash | 1-2h | Medium | |
| 6 | Tests (unit + e2e with mocked himalaya) | 2-3h | High | |
| 7 | Docs (refcard, help, setup guide) | 1-2h | Medium | |

**Total estimate:** 12-20 hours across 2-4 sessions

---

## Phase 1: Dispatcher Skeleton

### Files to Create

| File | Purpose |
|------|---------|
| `lib/dispatchers/email-dispatcher.zsh` | Main `em()` dispatcher |
| `lib/email-helpers.zsh` | Rendering, fzf, AI helpers |
| `completions/_em` | ZSH completions |

### Subcommands (Phase 1)

```zsh
em() {
    case "$1" in
        inbox|i)    shift; _em_inbox "$@" ;;
        read|r)     shift; _em_read "$@" ;;
        send|s)     shift; _em_send "$@" ;;
        reply|re)   shift; _em_reply "$@" ;;
        find|f)     shift; _em_find "$@" ;;
        pick|p)     shift; _em_pick "$@" ;;
        unread|u)   shift; _em_unread "$@" ;;
        dash|d)     shift; _em_dash "$@" ;;
        folders)    shift; _em_folders "$@" ;;
        html)       shift; _em_html "$@" ;;
        attach|a)   shift; _em_attach "$@" ;;
        doctor)     shift; _em_doctor "$@" ;;
        help|--help|-h) _em_help ;;
        *) _em_help ;;
    esac
}
```

### Registration

Add to `flow.plugin.zsh`:
```zsh
source "${FLOW_DIR}/lib/dispatchers/email-dispatcher.zsh"
source "${FLOW_DIR}/lib/email-helpers.zsh"
```

---

## Phase 2: Core Subcommands

### `em inbox [N]`

```
himalaya envelope list --page-size ${N:-25} --output json | _em_render_inbox
```

### `em read <ID>`

```
himalaya message read <ID> | _em_smart_render
```

### `em reply <ID>` (The AI-First Workflow)

```
[1] Fetch original: himalaya message read <ID>
[2] AI draft: claude -p "Draft a reply to this email: ..." (with spinner)
[3] Write to temp file with ft=mail modeline
[4] nvim opens temp file (user edits, :wq)
[5] SAFETY GATE: Show preview, "Send this reply? [y/N]"
[6] himalaya message send (only on explicit 'y')
```

### `em send` (New Compose)

```
[1] Prompt for To, Subject (or accept from args)
[2] Optional: AI draft from subject line
[3] nvim opens temp file
[4] SAFETY GATE: preview + confirm
[5] himalaya message send
```

### Safety Gate Pattern

```zsh
_em_confirm_send() {
    local draft_file="$1"
    echo ""
    echo "${FLOW_COLORS[info]}  To:${FLOW_COLORS[reset]} $(head -1 "$draft_file" | sed 's/^To: //')"
    echo "${FLOW_COLORS[info]}  Subject:${FLOW_COLORS[reset]} $(sed -n '2p' "$draft_file" | sed 's/^Subject: //')"
    echo ""
    # Show body preview (first 10 lines after headers)
    echo "${FLOW_COLORS[dim]}--- Body Preview ---${FLOW_COLORS[reset]}"
    awk '/^$/{found=1;next} found{print}' "$draft_file" | head -10
    echo "${FLOW_COLORS[dim]}--- End Preview ---${FLOW_COLORS[reset]}"
    echo ""

    local response
    printf "  Send this email? [y/N] "
    read -r response
    [[ "$response" =~ ^[Yy]$ ]] && return 0 || return 1
}
```

---

## Phase 3: fzf Picker + Smart Rendering

### `em pick [FOLDER]`

```zsh
himalaya envelope list -f "${folder:-INBOX}" --output json \
    | jq -r '.[] | "\(.id)\t\(.flags)\t\(.from.name // .from.addr)\t\(.subject)\t\(.date)"' \
    | fzf --delimiter='\t' \
          --with-nth='2..' \
          --preview='himalaya message read {1} | bat --style=plain --color=always' \
          --preview-window='right:60%:wrap' \
          --header='Email Picker (Enter=read, Ctrl-R=reply, Ctrl-D=delete)' \
          --bind='enter:execute(himalaya message read {1} | bat --paging=always)' \
          --bind='ctrl-r:execute(himalaya message reply {1})' \
          --bind='ctrl-d:execute(himalaya envelope flag add {1} Deleted)'
```

### Smart Rendering Pipeline

```
Content type detection:
  text/html → w3m -dump → bat
  text/plain + markdown indicators → glow
  text/plain → bat --style=plain
  fallback → cat
```

---

## Phase 4: AI Draft Pipeline

### AI Abstraction

```zsh
_em_ai_draft() {
    local original_email="$1"
    local ai_backend="${FLOW_EMAIL_AI:-claude}"

    case "$ai_backend" in
        claude)
            echo "$original_email" | claude -p "Draft a professional reply to this email. Be concise. Only output the reply body, no headers."
            ;;
        gemini)
            echo "$original_email" | gemini "Draft a professional reply to this email. Be concise. Only output the reply body, no headers."
            ;;
        none|off)
            return 1  # No AI, user writes from scratch
            ;;
    esac
}
```

### Config

```zsh
# Environment variable
export FLOW_EMAIL_AI="claude"  # claude | gemini | none

# Or in .flow/email-config.yml
email:
  ai_backend: claude
  ai_timeout: 30
```

---

## Phase 5: Doctor + Dashboard

### `em doctor`

Check: himalaya, email-oauth2-proxy, w3m, bat, fzf, glow, jq, terminal-notifier

### `em dash`

Quick dashboard: unread count + latest 10 subjects

---

## Phase 6: Tests

### Unit Tests (`tests/test-email-dispatcher.zsh`)

- Subcommand routing (all 13 commands)
- Help output compliance
- Safety gate (confirm/deny)
- AI backend selection
- Rendering pipeline selection
- Config reading

### E2E Tests (`tests/e2e-email-dispatcher.zsh`)

- Mock himalaya output → test full workflows
- `em inbox` rendering
- `em pick` fzf command construction
- `em doctor` dependency checks

---

## Phase 7: Documentation

| File | Content |
|------|---------|
| `docs/reference/REFCARD-EMAIL.md` | Quick reference card |
| `docs/guides/EMAIL-SETUP-GUIDE.md` | Setup guide (himalaya + oauth proxy) |
| Help text in `_em_help()` | Built-in dispatcher help |

---

## Acceptance Criteria

- [ ] `em inbox` lists emails from himalaya
- [ ] `em read <ID>` displays email with smart rendering
- [ ] `em reply <ID>` opens nvim with AI-generated draft
- [ ] `em send` composes new email in nvim
- [ ] Every send has explicit `[y/N]` confirmation (default No)
- [ ] `em pick` opens fzf email browser with preview
- [ ] `em doctor` checks all dependencies
- [ ] `em help` shows comprehensive help
- [ ] All tests pass (`./tests/run-all.sh`)
- [ ] `source flow.plugin.zsh` loads without errors
- [ ] No `local path=` in any new code (ZSH gotcha)

---

## How to Start

```bash
cd ~/.git-worktrees/flow-cli/feature-em-dispatcher
claude
# Then: "Implement Phase 1 of the em dispatcher following ORCHESTRATE-em-dispatcher.md"
```
