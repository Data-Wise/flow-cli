# SPEC: Email AI Prompt + Bug Fixes

**Status:** draft
**Created:** 2026-02-27
**Issue:** (new — em dispatcher improvements)
**From Brainstorm:** BRAINSTORM-em-prompt-fix-2026-02-27.md
**Prerequisite:** None (standalone)
**Estimated Effort:** 3-4 hours (8 increments)

---

## Overview

Fix two bugs in `em reply` (RETURN trap + TTY detection) and add `--prompt` and `--backend` flags to `em reply`, `em send`, and `em forward` for AI-driven email composition. The `--prompt` flag lets users provide natural-language instructions ("decline politely", "acknowledge and ask for deadline") that the AI uses to generate drafts — aligning with himalaya.nvim's AI integration pattern. Smart TTY detection auto-routes to batch (non-interactive) mode in non-TTY contexts like Claude Code.

---

## Primary User Story

**As a** professor using flow-cli's `em` dispatcher from Claude Code (non-TTY),
**I want** to reply to emails with AI-generated drafts using natural language instructions,
**So that** I can compose contextual replies without manual editing or TTY failures.

### Acceptance Criteria

- [ ] `em reply 123 --prompt 'decline politely'` generates AI draft from prompt and sends via batch path
- [ ] `em reply 123` in non-TTY context auto-routes to batch path (no `dialoguer` crash)
- [ ] `trap "..." RETURN` error no longer appears
- [ ] `em send --prompt 'schedule meeting next Tuesday'` composes new email from prompt
- [ ] `em forward 123 --prompt 'FYI re: our discussion'` forwards with AI body
- [ ] `--backend claude|gemini` overrides AI backend per-command
- [ ] Safety gate (preview + confirm) runs before all sends, even in quick mode
- [ ] `em reply 123` in TTY context still uses interactive path (no regression)

---

## Secondary User Stories

### Professor replying from terminal (interactive, TTY)

**As a** user in a real terminal,
**I want** `em reply` to still open `$EDITOR` with an AI draft and use himalaya's interactive send menu,
**So that** the existing interactive workflow is preserved.

### Professor composing with AI backend choice

**As a** user who prefers Gemini for drafts (faster) but Claude for summaries (better),
**I want** `em reply 123 --prompt 'ack' --backend gemini` to use Gemini for this one draft,
**So that** I can pick the right model per-task without changing global config.

---

## Architecture

```
em reply 123 --prompt "decline politely"
    │
    ▼
_em_reply()                     ← parse --prompt, --backend flags
    │
    ├── [--prompt provided OR non-TTY?]
    │       │
    │       ▼ YES → Path 2 (batch)
    │       _em_ai_query("draft", prompt_with_instructions, email_content, backend_override)
    │           │
    │           ▼
    │       _em_hml_template_reply() → get MML headers
    │       _em_mml_inject_body()    → inject AI body
    │       _em_safety_gate()        → preview + confirm
    │       _em_hml_template_send()  → send via stdin (non-interactive)
    │
    └── [no --prompt AND TTY available?]
            │
            ▼ YES → Path 1 (interactive)
            _em_ai_query("draft", default_draft_prompt, email_content)
            _em_hml_reply()  → $EDITOR + himalaya TUI
```

---

## API Design

N/A — No API changes. This is a ZSH function modification (internal wiring).

### New/Modified Functions

| Function | File | Change |
|----------|------|--------|
| `_em_reply()` (~L681) | `lib/dispatchers/email-dispatcher.zsh` | Add `--prompt`, `--backend` flags; TTY auto-detection |
| `_em_send()` (~L590) | `lib/dispatchers/email-dispatcher.zsh` | Add `--prompt`, `--backend` flags |
| `_em_forward()` | `lib/dispatchers/email-dispatcher.zsh` | Add `--prompt`, `--backend` flags |
| `_em_hml_reply()` (~L274) | `lib/em-himalaya.zsh` | Fix RETURN trap bug |
| `_em_ai_prompt_with_instructions()` (NEW) | `lib/em-ai.zsh` | Build draft prompt with user instructions |
| `_em_help()` | `lib/dispatchers/email-dispatcher.zsh` | Document new flags |

### New Flags

| Flag | Applies To | Description |
|------|-----------|-------------|
| `--prompt 'text'` | reply, send, forward | Natural-language instruction for AI draft |
| `--backend claude\|gemini` | reply, send, forward | Override AI backend for this command |

### Flag Combinations

| Flags | Behavior |
|-------|----------|
| `em reply 123` (TTY) | Path 1: AI draft → $EDITOR → himalaya TUI (existing) |
| `em reply 123` (non-TTY) | Path 2: AI draft → safety gate → template send (NEW) |
| `em reply 123 --prompt 'decline'` | Path 2: prompt-guided draft → safety gate → send |
| `em reply 123 --prompt 'decline' --backend gemini` | Path 2: Gemini draft → safety gate → send |
| `em reply 123 --batch` | Path 2: existing batch mode (unchanged) |
| `em reply 123 --no-ai` | Path 1/2: skip AI entirely (existing) |

---

## Data Models

N/A — No data model changes. Uses existing AI backend config and email cache.

---

## Dependencies

| Dependency | Status | Required For |
|------------|--------|-------------|
| `_em_ai_query()` | Exists (em-ai.zsh:47) | AI draft generation |
| `_em_ai_execute()` | Exists (em-ai.zsh:141) | Backend execution |
| `_em_ai_draft_prompt()` | Exists (em-ai.zsh:276) | Base draft prompt |
| `_em_hml_template_reply()` | Exists (em-himalaya.zsh:328) | MML template (non-interactive) |
| `_em_hml_template_send()` | Exists (em-himalaya.zsh:346) | Send via stdin (non-interactive) |
| `_em_safety_gate()` | Exists (email-dispatcher.zsh:468) | Preview + confirm |
| `_em_mml_inject_body()` | Exists | Inject body into MML |
| himalaya CLI | Required | Email send/receive |

---

## UI/UX Specifications

N/A — CLI only. No visual changes beyond new flag support.

### Quick Send Mode Flow (--prompt)

```
$ em reply 123 --prompt "decline politely, suggest next semester"

ℹ Generating AI draft...
✓ AI draft ready

────────────────────────────────────────────
  To: student@university.edu
  Subject: Re: Extension Request
────────────────────────────────────────────
  Hi Sarah,

  Thank you for reaching out. Unfortunately, I'm unable to
  grant an extension at this time. I'd encourage you to
  consider retaking the course next semester — I'd be happy
  to have you in class again.

  Best,
  Dr. T
────────────────────────────────────────────

? Send this reply? [y/N/edit]
> y
✓ Reply sent
```

### Non-TTY Auto-Detection Flow

```
$ em reply 123   # from Claude Code (non-TTY)

ℹ Non-interactive mode (no TTY detected)
ℹ Generating AI draft...
✓ AI draft ready

[safety gate preview + confirm]
✓ Reply sent
```

---

## Implementation Plan

### Increment 1: Fix RETURN Trap Bug (15 min)

**File:** `lib/em-himalaya.zsh` (~L274-322)

Replace the `trap "..." RETURN` with ZSH's `always` block pattern:

```zsh
_em_hml_reply() {
    local msg_id="$1" body="$2" reply_all="${3:-false}"
    if ! _em_validate_msg_id "$msg_id"; then return 1; fi
    local -a flags=()
    [[ "$reply_all" == "true" ]] && flags+=(--all)

    local tmplog
    tmplog=$(mktemp "${TMPDIR:-/tmp}/em-reply-XXXXXX.log")
    chmod 0600 "$tmplog"

    # Use always block instead of trap RETURN (ZSH doesn't support RETURN signal)
    {
        if [[ -n "$body" ]]; then
            local tmpbody
            tmpbody=$(mktemp "${TMPDIR:-/tmp}/em-body-XXXXXX")
            chmod 0600 "$tmpbody"
            printf '%s' "$body" > "$tmpbody"
            script -q "$tmplog" sh -c "himalaya message reply ${(j: :)${(@q)flags}} '$msg_id' < '$tmpbody'"
            rm -f "$tmpbody"
        else
            script -q "$tmplog" himalaya message reply "${flags[@]}" "$msg_id"
        fi
    } always {
        local _exit_code=$?
        if grep -aq "Discard" "$tmplog" 2>/dev/null; then
            rm -f "$tmplog"
            return 2
        fi
        rm -f "$tmplog"
        return $_exit_code
    }
}
```

**Verify:** `em reply <id>` no longer shows `undefined signal: RETURN`

---

### Increment 2: Smart TTY Detection in _em_reply (30 min)

**File:** `lib/dispatchers/email-dispatcher.zsh` (~L707-731)

Add TTY detection to auto-route to batch path when no terminal is available:

```zsh
# --- Path selection: TTY detection ---
# If --prompt is provided, always use batch path (prompt-driven = non-interactive)
# If no TTY available (Claude Code, piped input), use batch path
# Otherwise, use interactive path
if [[ "$batch_mode" != "true" && -z "$prompt_text" && -t 0 && -t 1 ]]; then
    # Path 1: Interactive reply (existing behavior)
    # ...
else
    # Path 2: Batch/non-interactive
    [[ ! -t 0 || ! -t 1 ]] && _flow_log_info "Non-interactive mode (no TTY detected)"
    # ...
fi
```

**Verify:** `em reply <id>` from Claude Code's Bash tool uses batch path without crashing

---

### Increment 3: Add --prompt and --backend to _em_reply (45 min)

**File:** `lib/dispatchers/email-dispatcher.zsh` (~L681-790)

Add flag parsing:

```zsh
_em_reply() {
    # ... existing setup ...
    local prompt_text=""
    local backend_override=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-ai)         skip_ai=true; shift ;;
            --all|-a)        reply_all=true; shift ;;
            --batch|-b)      batch_mode=true; shift ;;
            --force|--yes)   force_flag="$1"; shift ;;
            --prompt)        prompt_text="$2"; shift 2 ;;
            --backend)       backend_override="$2"; shift 2 ;;
            *)               msg_id="$1"; shift ;;
        esac
    done
```

In Path 2, modify AI draft generation to use prompt instructions:

```zsh
# Build prompt with user instructions (if provided)
local draft_prompt
if [[ -n "$prompt_text" ]]; then
    draft_prompt=$(_em_ai_prompt_with_instructions "$prompt_text")
else
    draft_prompt=$(_em_ai_draft_prompt)
fi

draft=$(_em_ai_query "draft" "$draft_prompt" "$content" "$backend_override" "$msg_id")
```

**Verify:** `em reply 123 --prompt 'decline politely'` generates instruction-guided draft

---

### Increment 4: Add _em_ai_prompt_with_instructions (30 min)

**File:** `lib/em-ai.zsh`

New helper function that enhances the draft prompt with user instructions (mirrors himalaya.nvim's pattern):

```zsh
_em_ai_prompt_with_instructions() {
    # Build draft prompt with user instructions appended
    # Mirrors himalaya.nvim pattern: "User instructions: ..." appended to base prompt
    # Args: $1 = user instruction text
    local instructions="$1"
    local base_prompt
    base_prompt=$(_em_ai_draft_prompt)

    echo "${base_prompt}

User instructions: ${instructions}

IMPORTANT: Follow the user's instructions above as the primary guide for tone,
content, and intent. The category-specific guidance is secondary."
}
```

**Verify:** Prompt output includes user instructions appended to base draft prompt

---

### Increment 5: Add --prompt and --backend to _em_send (30 min)

**File:** `lib/dispatchers/email-dispatcher.zsh` (~L590-679)

Add flag parsing for `--prompt` and `--backend`:

```zsh
_em_send() {
    _em_require_himalaya || return 1
    local to="" subject="" use_ai=false force_flag=""
    local prompt_text="" backend_override=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --ai) use_ai=true; shift ;;
            --force|--yes) force_flag="$1"; shift ;;
            --prompt) prompt_text="$2"; use_ai=true; shift 2 ;;
            --backend) backend_override="$2"; shift 2 ;;
            *)
                if [[ -z "$to" ]]; then to="$1"
                elif [[ -z "$subject" ]]; then subject="$1"
                fi
                shift ;;
        esac
    done
```

When `--prompt` is provided, use it as the compose instruction:

```zsh
# [2] AI draft — use prompt instructions if provided
if [[ "$use_ai" == true && "$FLOW_EMAIL_AI" != "none" ]]; then
    local compose_prompt
    if [[ -n "$prompt_text" ]]; then
        compose_prompt="Write a professional email. User instructions: ${prompt_text}"
    else
        compose_prompt="Compose a professional email about: $subject"
    fi
    ai_body=$(_em_ai_query "draft" \
        "$(_em_ai_draft_prompt)" \
        "$compose_prompt" "$backend_override" 2>/dev/null)
fi
```

**Verify:** `em send user@example.com "Meeting" --prompt 'suggest Tuesday 2pm'` generates prompt-guided draft

---

### Increment 6: Add --prompt and --backend to _em_forward (30 min)

**File:** `lib/dispatchers/email-dispatcher.zsh`

Apply the same `--prompt` and `--backend` pattern to `_em_forward()`. Add TTY detection for auto-routing to batch path.

**Verify:** `em forward 123 user@example.com --prompt 'FYI re: our discussion'` works

---

### Increment 7: Update Help and Completions (15 min)

**File:** `lib/dispatchers/email-dispatcher.zsh` (`_em_help()`)

Add new flags to help output:

```
AI-Powered Composition:
  em reply <ID> --prompt 'instructions'     AI draft with custom instructions
  em send <to> <subj> --prompt 'instructions'  AI compose from instructions
  em forward <ID> <to> --prompt 'instructions' AI forward with custom body
  em reply <ID> --backend gemini            Override AI backend for this command

Flags:
  --prompt 'text'          Natural-language instructions for AI draft
  --backend claude|gemini  Override AI backend for this command
```

**File:** `completions/_em`

Add `--prompt` and `--backend` to completion.

**Verify:** `em help` shows new flags, tab completion works

---

### Increment 8: Tests (45 min)

**File:** `tests/test-em-prompt-flag.zsh` (NEW)

Test cases:

1. `test_return_trap_fixed` — `_em_hml_reply` no longer outputs "undefined signal: RETURN"
2. `test_tty_detection_non_tty` — In non-TTY, `_em_reply` uses batch path
3. `test_tty_detection_with_tty` — With TTY, `_em_reply` uses interactive path
4. `test_prompt_flag_parsed` — `--prompt 'text'` parsed correctly in `_em_reply`
5. `test_backend_flag_parsed` — `--backend gemini` parsed correctly
6. `test_prompt_forces_batch` — `--prompt` always routes to batch path
7. `test_prompt_with_instructions` — `_em_ai_prompt_with_instructions` appends user text
8. `test_send_prompt_flag` — `_em_send --prompt` parsed correctly
9. `test_forward_prompt_flag` — `_em_forward --prompt` parsed correctly
10. `test_help_includes_prompt` — help output contains `--prompt`
11. `test_help_includes_backend` — help output contains `--backend`
12. `test_prompt_and_backend_combined` — both flags work together

### Framework

```zsh
#!/usr/bin/env zsh
PROJECT_ROOT="${0:A:h:h}"
source "${0:A:h}/test-framework.zsh"
test_suite "Email AI Prompt Flag Tests"
# ... test functions ...
test_suite_end
print_summary
exit $(( TESTS_FAILED > 0 ? 1 : 0 ))
```

### Add to run-all.sh

Add `test-em-prompt-flag.zsh` to `tests/run-all.sh`.

### Verify

```bash
zsh tests/test-em-prompt-flag.zsh        # all pass
./tests/run-all.sh                        # full suite passes
zsh tests/dogfood-test-quality.zsh       # no anti-patterns
```

---

## Open Questions

1. **Quick send vs edit mode:** When `--prompt` is provided, should it always quick-send (prompt → confirm → send), or should there be an `--edit` flag to open in `$EDITOR` after AI generates? Decision: Quick send by default (safety gate provides confirm/edit escape hatch).
2. **Prompt templates:** Should we support `@decline`, `@acknowledge` shortcuts that expand to longer instructions? Decision: Defer to future session (long-term item).
3. **himalaya.nvim overlap:** User browses email in nvim's himalaya plugin, composes via flow-cli. No conflict — different use cases. Document in integration guide.

---

## Review Checklist

- [ ] RETURN trap bug fixed (no "undefined signal" error)
- [ ] Non-TTY auto-detection routes to batch path
- [ ] `--prompt` flag works on reply, send, forward
- [ ] `--backend` flag works on reply, send, forward
- [ ] Combined `--prompt --backend` works
- [ ] Interactive TTY path not broken (no regression)
- [ ] Safety gate runs on all send paths
- [ ] AI draft prompt includes user instructions when `--prompt` provided
- [ ] Help output documents new flags
- [ ] Tests: 12+ test functions covering all scenarios
- [ ] `./tests/run-all.sh` passes with new test file
- [ ] `zsh tests/dogfood-test-quality.zsh` passes

---

## Implementation Notes

- **RETURN trap fix is ~5 lines** — replace `trap "..." RETURN` with `{ ... } always { cleanup }` (ZSH idiom)
- **TTY detection is ~3 lines** — `[[ -t 0 && -t 1 ]]` check before Path 1/2 branch
- **`--prompt` reuses existing infrastructure** — `_em_ai_query` already accepts `backend_override`, `_em_hml_template_send` already handles batch send
- **Aligns with himalaya.nvim** — nvim plugin appends `"User instructions: " .. instructions` to draft prompt; flow-cli mirrors this pattern
- **himalaya.nvim's `ask_before` config** — per-action boolean controlling whether to prompt for instructions. flow-cli's `--prompt` flag is the CLI equivalent (explicit rather than config-driven)
- **Backend selection alignment** — himalaya.nvim uses `M.config.backend` field with `:HimalayaAi set backend <value>` runtime switching. flow-cli uses `$FLOW_EMAIL_AI` env var with `em ai <backend>` command + per-command `--backend` override
- **No changes to em-himalaya.zsh template subsystem** — `_em_hml_template_reply`, `_em_hml_template_write`, `_em_hml_template_send` are unchanged
- **Safety gate always runs** — even with `--prompt`, the two-phase safety gate (preview + confirm) runs before send

---

## Commit Strategy

| Increment | Commit Message |
|-----------|---------------|
| 1 | `fix: replace RETURN trap with always block in _em_hml_reply` |
| 2 | `fix: add TTY auto-detection for non-interactive email reply` |
| 3 | `feat: add --prompt and --backend flags to em reply` |
| 4 | `feat: add _em_ai_prompt_with_instructions helper` |
| 5 | `feat: add --prompt and --backend flags to em send` |
| 6 | `feat: add --prompt and --backend flags to em forward` |
| 7 | `docs: update em help with --prompt and --backend flags` |
| 8 | `test: add email AI prompt flag test suite` |

---

## Definition of Done

- [ ] Both bugs fixed (RETURN trap + TTY detection)
- [ ] `--prompt` flag works on reply, send, forward
- [ ] `--backend` flag works on reply, send, forward
- [ ] Interactive path preserved for TTY users
- [ ] Safety gate on all send paths
- [ ] 12+ tests passing
- [ ] Full test suite green
- [ ] Help output updated

---

## Post-Implementation

After all increments complete:

```bash
git fetch origin dev && git rebase origin/dev
./tests/run-all.sh
gh pr create --base dev --title "feat: em --prompt flag + TTY bug fixes"
```

---

## History

| Date | Event |
|------|-------|
| 2026-02-27 | Spec created from max-depth brainstorm. Key discoveries: (1) himalaya `template send` enables fully non-interactive email, (2) himalaya.nvim's AI module uses `"User instructions: "` pattern for prompt-driven drafts, (3) RETURN trap is bash-ism unsupported in ZSH. 8 expert questions answered. Two research agents: email architecture deep-dive + himalaya CLI capabilities. |
