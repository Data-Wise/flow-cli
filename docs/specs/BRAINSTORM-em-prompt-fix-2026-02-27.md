# BRAINSTORM: Email AI Prompt + Bug Fixes

**Date:** 2026-02-27
**Depth:** max | **Focus:** feat | **Action:** save
**Issue:** (new — em dispatcher improvements)

---

## Key Discovery

himalaya has TWO send pathways:
1. **Interactive:** `himalaya message reply/write/forward` → opens $EDITOR → TUI selector (requires TTY)
2. **Non-interactive:** `himalaya template send` → accepts MML on stdin/args → sends directly (no TTY)

flow-cli already has Path 2 (batch) in `_em_reply()` lines 733-790. The TTY bug is that Path 1 (interactive) is chosen even in non-TTY contexts.

---

## Implementation Status

| Component | Status |
|-----------|--------|
| `_em_hml_reply()` interactive path | Working (but RETURN trap bug + TTY issue) |
| `_em_reply()` batch path (Path 2) | Working (uses template_send) |
| `_em_hml_template_send` | Working (non-interactive) |
| AI draft generation | Working (claude/gemini + fallback) |
| `--prompt` flag | NOT implemented |
| `--backend` flag | NOT implemented (but `_em_ai_query` supports override) |
| TTY auto-detection | NOT implemented |
| Smart fallback | NOT implemented |

---

## Bug: RETURN Trap (em-himalaya.zsh:300)

```zsh
trap "rm -f '$tmplog'" RETURN   # ZSH doesn't support RETURN signal
```

Fix: Replace with explicit cleanup before each `return` statement, or use `{ ... } always { cleanup }` block.

## Bug: TTY Required for Interactive Path

`_em_hml_reply()` calls `script -q "$tmplog" himalaya message reply` which requires TTY.
himalaya's interactive selector (`dialoguer` crate) needs a real terminal.

Fix: Auto-detect `[[ ! -t 0 ]]` and route to batch path.

---

## Decisions (from 8 expert questions)

| Decision | Choice |
|----------|--------|
| Prompt mode | Both: quick send + draft-edit-send |
| Scope | All four: reply, send, forward, pick |
| TTY handling | Smart fallback (interactive in TTY, batch otherwise) |
| Safety | Always confirm before send |
| Flag syntax | `--prompt 'instruction'` |
| himalaya.nvim | User browses in nvim, composes via flow-cli |
| AI backend | Per-command `--backend claude\|gemini` |

---

## Quick Wins (< 30 min each)

1. Fix RETURN trap → explicit cleanup
2. Smart TTY detection → auto-switch to batch
3. Apply TTY detection to send/forward

## Medium Effort (1-2 hours)

4. `--prompt` for em reply
5. `--prompt` for em send
6. `--prompt` for em forward
7. `--backend` flag
8. Quick send mode (prompt → confirm → send, no editor)

## Long-term (Future sessions)

9. Pick menu "AI Reply" action
10. Prompt templates (@decline, @acknowledge)
11. himalaya.nvim overlap documentation
