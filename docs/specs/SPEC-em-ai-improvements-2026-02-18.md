# SPEC: Email Dispatcher AI Improvements

> **Date:** 2026-02-18
> **Branch:** TBD (feature/em-ai-improvements)
> **Status:** Draft
> **From Brainstorm:** `~/BRAINSTORM-flow-cli-em-improvements-2026-02-18.md`

## Summary

Three enhancements to flow-cli's `em` dispatcher: runtime AI backend switching via `em ai` subcommand, Gemini CLI `extra_args` support for startup optimization, and cross-dispatcher `em catch` integration for email-to-task capture. Mirrors parallel Neovim himalaya-ai improvements.

## Requirements

### 1. `em ai` Subcommand — Runtime Backend Switching

**Problem:** Switching AI backend requires `export FLOW_EMAIL_AI=gemini` or editing `email.conf` — too much friction for quick switching during email triage.

**Solution:** Add `em ai` subcommand following the `prompt` dispatcher pattern.

**User Story:** As a professor triaging email, I want to quickly switch between Claude (better drafts) and Gemini (free, fast) without leaving my workflow.

**Files:**
- `lib/dispatchers/email-dispatcher.zsh` — add `ai|AI` case to dispatcher + `_em_ai_*` functions
- `lib/em-ai.zsh` — add `_em_ai_switch()`, `_em_ai_toggle()`, `_em_ai_status()`

**Subcommands:**

| Command | Action |
|---------|--------|
| `em ai` | Show current backend + available backends |
| `em ai claude` | Switch to Claude |
| `em ai gemini` | Switch to Gemini |
| `em ai none` | Disable AI |
| `em ai toggle` | Cycle through available backends |
| `em ai auto` | Enable per-operation smart routing |

**Implementation:**

```zsh
# In email-dispatcher.zsh dispatcher case:
ai|AI)        shift; _em_ai_cmd "$@" ;;

# New function in em-ai.zsh:
_em_ai_cmd() {
    case "${1:-}" in
        "")       _em_ai_status ;;
        toggle)   _em_ai_toggle ;;
        auto)     _em_ai_switch "auto" ;;
        *)        _em_ai_switch "$1" ;;
    esac
}

_em_ai_switch() {
    local backend="$1"

    # Validate
    if [[ "$backend" != "none" && "$backend" != "auto" ]]; then
        if ! command -v "$backend" &>/dev/null; then
            _flow_log_error "Backend not found: $backend"
            echo "Available: $(_em_ai_available)"
            return 1
        fi
    fi

    # Mutate
    export FLOW_EMAIL_AI="$backend"
    _EM_AI_BACKENDS[default]="$backend"

    _flow_log_success "AI backend → $backend"
}

_em_ai_toggle() {
    local -a available=($(_em_ai_available))
    [[ ${#available} -eq 0 ]] && { _flow_log_error "No AI backends available"; return 1; }

    local current="${FLOW_EMAIL_AI:-claude}"
    local idx=1
    for ((i=1; i<=${#available}; i++)); do
        [[ "${available[$i]}" == "$current" ]] && { idx=$i; break; }
    done
    local next_idx=$(( (idx % ${#available}) + 1 ))
    _em_ai_switch "${available[$next_idx]}"
}

_em_ai_status() {
    echo -e "${_C_BOLD}Email AI Backend${_C_NC}"
    echo ""
    echo -e "  Current:   ${_C_CYAN}${FLOW_EMAIL_AI:-claude}${_C_NC}"
    echo -e "  Available: ${_C_DIM}$(_em_ai_available)${_C_NC}"
    echo -e "  Timeout:   ${_C_DIM}${FLOW_EMAIL_AI_TIMEOUT:-30}s${_C_NC}"
    echo ""
    echo -e "  ${_C_DIM}Switch: em ai claude | em ai gemini | em ai toggle${_C_NC}"
}
```

**Acceptance:**
- `em ai` shows current backend
- `em ai gemini` switches immediately, next `em reply` uses Gemini
- `em ai toggle` cycles claude → gemini → claude
- `em ai none` disables AI, `em reply --no-ai` behavior
- Invalid backend shows error + available list

---

### 2. Gemini `extra_args` Support

**Problem:** Gemini CLI loads 8+ extensions on every invocation (~5-8s startup). Passing `-e none` reduces this to ~1-2s, but `_em_ai_execute()` doesn't support extra arguments.

**Solution:** Add per-backend `extra_args` to `_EM_AI_BACKENDS` and spread into execution.

**Files:**
- `lib/em-ai.zsh` — modify `_EM_AI_BACKENDS` array + `_em_ai_execute()` gemini case

**Config change:**
```zsh
# Before:
typeset -gA _EM_AI_BACKENDS=(
    [gemini_cmd]="gemini"
    [gemini_flags]=""
    ...
)

# After:
typeset -gA _EM_AI_BACKENDS=(
    [gemini_cmd]="gemini"
    [gemini_flags]=""
    [gemini_extra_args]="-e none"     # Skip extensions for speed
    [claude_extra_args]=""             # None needed
    ...
)
```

**Code change (`_em_ai_execute`):**
```zsh
gemini)
    if ! command -v gemini &>/dev/null; then
        return 1
    fi
    local extra="${_EM_AI_BACKENDS[gemini_extra_args]:-}"
    echo "$input" | timeout "$timeout_s" \
        gemini ${=extra} "$prompt" 2>/dev/null
    # ... (rest unchanged)
    ;;
```

**Config file override:** `email.conf` can set `FLOW_EMAIL_GEMINI_EXTRA_ARGS="-e none"`.

**Acceptance:**
- Gemini commands complete in < 3s (vs ~8s without `-e none`)
- Claude backend unaffected
- `em doctor` shows extra_args in config summary
- `em ai` status shows extra_args if set

---

### 3. `em catch <ID>` — Email-to-Task Capture

**Problem:** No quick way to turn an email into an action item without leaving the email workflow. Must mentally parse, switch to catch, type summary.

**Solution:** `em catch <ID>` AI-summarizes email and pipes into `catch` command.

**Files:**
- `lib/dispatchers/email-dispatcher.zsh` — add `catch` case + `_em_catch()` function
- `lib/dispatchers/email-dispatcher.zsh` — add Ctrl-C binding to `_em_pick()`

**Implementation:**

```zsh
# In dispatcher case:
catch|c)      shift; _em_catch "$@" ;;

# New function:
_em_catch() {
    _em_require_himalaya || return 1
    local msg_id="$1"

    if [[ -z "$msg_id" ]]; then
        _flow_log_error "Email ID required"
        echo "Usage: ${_C_CYAN}em catch <ID>${_C_NC}"
        return 1
    fi

    # Get email content
    local content
    content=$(_em_hml_read "$msg_id" plain 2>/dev/null)
    if [[ -z "$content" ]]; then
        _flow_log_error "Could not read email $msg_id"
        return 1
    fi

    # AI summarize
    local summary
    if [[ "$FLOW_EMAIL_AI" != "none" ]]; then
        summary=$(_em_ai_query "summarize" "$(_em_ai_summarize_prompt)" \
            "$content" "" "$msg_id")
    fi

    # Fallback to subject line
    if [[ -z "$summary" ]]; then
        summary=$(_em_hml_list "${FLOW_EMAIL_FOLDER:-INBOX}" 100 2>/dev/null \
            | jq -r ".[] | select(.id == \"$msg_id\") | .subject" 2>/dev/null)
    fi

    if [[ -z "$summary" ]]; then
        _flow_log_error "Could not generate summary for email $msg_id"
        return 1
    fi

    # Feed into catch
    if typeset -f catch &>/dev/null; then
        catch "Email #$msg_id: $summary"
        _flow_log_success "Captured: $summary"
    else
        # Fallback: just display for manual capture
        echo -e "${_C_BOLD}Capture:${_C_NC} $summary"
        echo -e "${_C_DIM}(catch command not available — copy manually)${_C_NC}"
    fi
}
```

**fzf integration (em pick):**
Add to existing `_em_pick()` fzf `--bind`:
```
--bind "ctrl-c:execute-silent(_em_catch {1})+reload(...)"
```

**Acceptance:**
- `em catch 42` produces summary and logs to catch
- Ctrl-C in `em pick` captures selected email
- Graceful fallback if catch command unavailable
- Graceful fallback if AI unavailable (uses subject line)

---

## Secondary User Stories

### Per-Operation Backend Routing (Future)

As a cost-conscious professor, I want classification/summarization to use Gemini (free) while drafts use Claude (better writing), without manual switching.

Implementation deferred to separate spec. Foundation laid by `em ai auto` subcommand.

### Teaching Triage (Future)

As a teaching-focused professor, I want `teach triage` to surface only student emails and draft contextual replies (week-aware, template-matched).

Depends on `em respond --category` filter (not in this spec).

---

## Architecture

```
em ai claude          em catch 42
    │                     │
    ▼                     ▼
_em_ai_cmd()         _em_catch()
    │                     │
    ▼                     ├── _em_hml_read()
_em_ai_switch()      │   ├── _em_ai_query("summarize")
    │                     │   └── catch "$summary"
    ├── validate          │
    ├── export FLOW_EMAIL_AI
    └── update _EM_AI_BACKENDS[default]
```

## API Design

N/A — CLI-only, no API changes.

## Data Models

N/A — No new data models. Uses existing `_EM_AI_BACKENDS` associative array (extended with `extra_args` keys).

## Dependencies

| Dependency | Required | Purpose |
|------------|----------|---------|
| himalaya | Required | Email backend |
| claude CLI | Optional | AI drafts (default) |
| gemini CLI | Optional | AI drafts (alternative) |
| jq | Optional | JSON parsing (fallback to subject) |
| catch command | Optional | Task capture (graceful fallback) |

## UI/UX Specifications

### `em ai` Status Display

```
Email AI Backend

  Current:   claude
  Available: claude gemini
  Timeout:   30s

  Switch: em ai claude | em ai gemini | em ai toggle
```

### `em ai toggle` Notification

```
✓ AI backend → gemini
```

### `em catch` Output

```
✓ Captured: Student Jane: absent Mon, requests lecture notes
```

### Accessibility

N/A — Terminal CLI, inherits terminal accessibility features.

## Open Questions

- Should `em ai` persist choice to `email.conf`? (Currently: session-only, resets on restart)
- Should `em catch` include a `--no-ai` flag to just capture the subject line?
- Should `em ai auto` be the default once per-op routing is implemented?
- Should `em ai` show latency estimates per backend?

## Review Checklist

- [ ] `em ai` switch doesn't break existing `em respond` pipeline
- [ ] Gemini `extra_args` doesn't break Claude backend
- [ ] `em catch` gracefully handles missing `catch` command
- [ ] `em ai toggle` skips unavailable backends
- [ ] All new subcommands appear in `em help`
- [ ] `em doctor` shows extra_args in config summary
- [ ] Tests added for `_em_ai_switch`, `_em_catch`, `_em_ai_toggle`
- [ ] No `local path=` ZSH gotcha in new functions
- [ ] Help text follows existing color scheme

## Implementation Notes

- Follow `prompt-dispatcher.zsh` model for `em ai` (direct subcommands + toggle)
- State via env var (`FLOW_EMAIL_AI`) — session-scoped, no persistence
- `_em_ai_switch()` is the single point of mutation (validate → set → log)
- `em catch` reuses existing `_em_ai_query("summarize")` + `catch` command
- Gemini `extra_args` uses ZSH `${=var}` word splitting for flag expansion
- All features gracefully degrade when dependencies missing

## History

| Date | Change |
|------|--------|
| 2026-02-18 | Initial draft from max-depth brainstorm |
