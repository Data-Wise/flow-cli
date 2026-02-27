# ORCHESTRATE: Email AI Prompt + Bug Fixes

**Issue:** (new — em dispatcher improvements)
**Spec:** `docs/specs/SPEC-em-prompt-fix-2026-02-27.md`
**Branch:** `feature/em-prompt`
**Estimated:** 3-4 hours (8 increments)

---

## Pre-Flight

Before starting, verify:

```bash
# Confirm em dispatcher exists and loads
grep -n '_em_reply' lib/dispatchers/email-dispatcher.zsh | head -5
# Confirm em-himalaya adapter
grep -n '_em_hml_reply' lib/em-himalaya.zsh | head -5
# Confirm AI infrastructure
grep -n '_em_ai_query' lib/em-ai.zsh | head -5
# Confirm test framework
ls tests/test-framework.zsh
```

---

## Increment 1: Fix RETURN Trap Bug (15 min)

**File:** `lib/em-himalaya.zsh`

### Task 1.1: Replace trap with always block

**Location:** `_em_hml_reply()` (~lines 274-322)

Replace the entire function body. The key change is:

**Before (broken):**
```zsh
trap "rm -f '$tmplog'" RETURN   # ZSH doesn't support RETURN signal
# ... body ...
if grep -aq "Discard" "$tmplog" 2>/dev/null; then return 2; fi
return 0
```

**After (fixed):**
```zsh
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
    local _reply_discard=false
    if grep -aq "Discard" "$tmplog" 2>/dev/null; then
        _reply_discard=true
    fi
    rm -f "$tmplog"
    if [[ "$_reply_discard" == true ]]; then
        return 2
    fi
}
```

### Verify

```bash
source flow.plugin.zsh
# The trap error should no longer appear
# Manual test: em reply <id> (in a real terminal)
```

---

## Increment 2: Smart TTY Detection (30 min)

**File:** `lib/dispatchers/email-dispatcher.zsh`

### Task 2.1: Modify _em_reply path selection

**Location:** `_em_reply()` (~line 707-708)

Change from:
```zsh
if [[ "$batch_mode" != "true" ]]; then
```

To:
```zsh
# Smart path selection:
# - --prompt flag → always batch (prompt-driven = non-interactive)
# - --batch flag → always batch (explicit)
# - No TTY → batch (non-interactive context)
# - TTY available → interactive (existing behavior)
local use_interactive=false
if [[ "$batch_mode" != "true" && -z "$prompt_text" && -t 0 && -t 1 ]]; then
    use_interactive=true
fi

if [[ "$use_interactive" == "true" ]]; then
```

### Task 2.2: Add non-TTY info message

In the batch path (else branch), add:
```zsh
if [[ ! -t 0 || ! -t 1 ]]; then
    _flow_log_info "Non-interactive mode (no TTY detected)"
fi
```

### Verify

```bash
# From Claude Code Bash tool (non-TTY): should use batch path
# From real terminal (TTY): should use interactive path
```

---

## Increment 3: --prompt and --backend in _em_reply (45 min)

**File:** `lib/dispatchers/email-dispatcher.zsh`

### Task 3.1: Add flag parsing to _em_reply

**Location:** `_em_reply()` flag parsing block (~lines 686-699)

Add new variables and case entries:

```zsh
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

### Task 3.2: Modify batch path AI draft generation

**Location:** Path 2 batch section (~lines 733-747)

Replace the draft prompt with instructions-aware version:

```zsh
# Build prompt — use user instructions if provided
local draft_prompt
if [[ -n "$prompt_text" ]]; then
    draft_prompt=$(_em_ai_prompt_with_instructions "$prompt_text")
else
    draft_prompt=$(_em_ai_draft_prompt)
fi

draft=$(_em_ai_query "draft" "$draft_prompt" "$content" "$backend_override" "$msg_id")
```

### Task 3.3: Pass backend_override in Path 1 too

In Path 1 (interactive), pass `backend_override` to `_em_ai_query`:

```zsh
body=$(_em_ai_query "draft" \
    "$(_em_ai_draft_prompt)" \
    "$original" "$backend_override" "$msg_id" 2>/dev/null)
```

### Verify

```bash
# em reply 123 --prompt 'decline politely'
# em reply 123 --backend gemini
# em reply 123 --prompt 'acknowledge' --backend gemini
```

---

## Increment 4: _em_ai_prompt_with_instructions (30 min)

**File:** `lib/em-ai.zsh`

### Task 4.1: Add new function after _em_ai_draft_prompt

**Location:** After `_em_ai_draft_prompt()` (~line 317)

```zsh
_em_ai_prompt_with_instructions() {
    # Build draft prompt enhanced with user instructions
    # Mirrors himalaya.nvim pattern: appends "User instructions: ..." to base prompt
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

### Verify

```bash
source flow.plugin.zsh
# Test output includes "User instructions: decline politely"
_em_ai_prompt_with_instructions "decline politely" | grep -c "User instructions"
```

---

## Increment 5: --prompt and --backend in _em_send (30 min)

**File:** `lib/dispatchers/email-dispatcher.zsh`

### Task 5.1: Add flag parsing to _em_send

**Location:** `_em_send()` (~lines 594-608)

Add:
```zsh
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

### Task 5.2: Use prompt_text in AI draft section

**Location:** AI draft block (~lines 628-638)

```zsh
if [[ "$use_ai" == true && "$FLOW_EMAIL_AI" != "none" ]]; then
    _flow_log_info "Generating AI draft..."
    local compose_input
    if [[ -n "$prompt_text" ]]; then
        compose_input="Write a professional email. User instructions: ${prompt_text}"
    else
        compose_input="Compose a professional email about: $subject"
    fi
    ai_body=$(_em_ai_query "draft" \
        "$(_em_ai_draft_prompt)" \
        "$compose_input" "$backend_override" 2>/dev/null)
    if [[ -n "$ai_body" ]]; then
        _flow_log_success "AI draft ready — edit in \$EDITOR"
    fi
fi
```

### Verify

```bash
# em send user@example.com "Meeting" --prompt 'suggest Tuesday 2pm'
# em send user@example.com "Update" --prompt 'brief status' --backend gemini
```

---

## Increment 6: --prompt and --backend in _em_forward (30 min)

**File:** `lib/dispatchers/email-dispatcher.zsh`

### Task 6.1: Find _em_forward and add flags

Apply the same pattern as reply/send:
- Add `--prompt` and `--backend` to flag parsing
- Add TTY detection for auto-batch routing
- Use `_em_ai_prompt_with_instructions` when prompt provided

### Verify

```bash
# em forward 123 user@example.com --prompt 'FYI re: our discussion'
```

---

## Increment 7: Update Help and Completions (15 min)

**File:** `lib/dispatchers/email-dispatcher.zsh` (`_em_help()`)

### Task 7.1: Add AI Composition section to help

Add after existing help content:

```
AI-Powered Composition:
  em reply <ID> --prompt 'instructions'       AI draft with custom instructions
  em send <to> <subj> --prompt 'instructions' AI compose from instructions
  em forward <ID> <to> --prompt 'text'        AI forward with custom body
  --backend claude|gemini                     Override AI backend per-command
```

### Task 7.2: Update completions

**File:** `completions/_em`

Add `--prompt` and `--backend` to completion arrays for reply, send, forward.

### Verify

```bash
em help  # should show new flags
```

---

## Increment 8: Tests (45 min)

**File:** `tests/test-em-prompt-flag.zsh` (NEW)

### Test Cases

1. `test_return_trap_fixed` — source em-himalaya.zsh, verify no trap RETURN in function
2. `test_tty_detection_logic` — verify path selection logic (mock -t checks)
3. `test_prompt_flag_parsed` — `_em_reply` parses `--prompt 'text'`
4. `test_backend_flag_parsed` — `_em_reply` parses `--backend gemini`
5. `test_prompt_forces_batch` — `--prompt` flag sets use_interactive=false
6. `test_prompt_with_instructions_output` — `_em_ai_prompt_with_instructions` includes user text
7. `test_prompt_with_instructions_base` — base prompt is included
8. `test_send_prompt_flag` — `_em_send` parses `--prompt`
9. `test_send_prompt_enables_ai` — `--prompt` implies `--ai`
10. `test_forward_prompt_flag` — `_em_forward` parses `--prompt`
11. `test_help_includes_prompt` — help output contains `--prompt`
12. `test_help_includes_backend` — help output contains `--backend`

### Add to run-all.sh

Add `test-em-prompt-flag.zsh` to `tests/run-all.sh`.

### Verify

```bash
zsh tests/test-em-prompt-flag.zsh        # all pass
./tests/run-all.sh                        # full suite passes
zsh tests/dogfood-test-quality.zsh       # no anti-patterns
```

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

- [ ] RETURN trap bug fixed
- [ ] Non-TTY auto-detection routes to batch
- [ ] `--prompt` works on reply, send, forward
- [ ] `--backend` works on reply, send, forward
- [ ] Interactive path preserved for TTY
- [ ] Safety gate on all paths
- [ ] 12+ tests passing
- [ ] Full suite green
- [ ] Help updated

---

## Post-Implementation

```bash
git fetch origin dev && git rebase origin/dev
./tests/run-all.sh
gh pr create --base dev --title "feat: em --prompt flag + TTY bug fixes"
```
