# ORCHESTRATE: Email Dispatcher Restructure

**Spec:** `docs/specs/SPEC-flow-cli-restructure-2026-07-06.md`  
**Branch:** `feature/email-dispatcher-restructure`  
**Base:** `dev`  
**Goal:** Apply the same modular split pattern used for `teach` to `email-dispatcher.zsh`.

---

## Exit Criteria

1. `lib/dispatchers/email-dispatcher.zsh` < 1,500 lines (from 3,214).
2. `lib/dispatchers/email/` exists with 3-6 module files.
3. `tests/test-em-dispatcher-characterization.zsh` exists and passes (routing checks for all public `em` subcommands).
4. `./tests/run-all.sh` reports 0 failures.
5. `mkdocs build --strict` clean.
6. Man-page version-sync guard 12/12.

---

## Work Breakdown

### A. Characterization tests for `email-dispatcher.zsh`

- Add `tests/test-em-dispatcher-characterization.zsh`.
- Source `flow.plugin.zsh` with `FLOW_QUIET=1 FLOW_ATLAS_ENABLED=no`.
- Mock action functions (`_em_hml_*`, `_em_create_calendar_event`, `_em_create_reminder`, `_em_ai_*`, etc.) and verify routing for:
  - send/reply/forward/draft
  - star/thread/snooze/digest
  - delete/move/restore/flag/todo/event/create-folder
  - pick
  - ai/catch/prompt
  - backend
  - help / no-args
  - unknown command

### B. Split `email-dispatcher.zsh`

Target modules in `lib/dispatchers/em/`:

| Module | Responsibility | Functions |
|--------|----------------|-----------|
| `em-main.zsh` | Entry point, help, backend toggling | `em()`, `_em_help()`, `_em_backend()` |
| `em-send.zsh` | Compose/send/reply/forward/draft | send/reply/forward/draft helpers |
| `em-organize.zsh` | Star/thread/snooze/digest | organize helpers |
| `em-manage.zsh` | Delete/move/restore/flag/todo/event/folder | manage helpers |
| `em-pick.zsh` | `em pick` multi-select UI | pick helpers |
| `em-ai.zsh` | AI-backed commands (ai, catch, prompt) | ai helpers |

- `lib/dispatchers/email-dispatcher.zsh` becomes a thin loader that sources `lib/dispatchers/em/*.zsh` in order.
- Preserve comments by splitting on function boundaries (do not use `functions[$fn]` extraction).

### C. Update dependent tests

- If any test greps `email-dispatcher.zsh` directly, update it to search the loader + modules (use the same `TEACH_DISPATCHER_FILES` pattern).
- Run `./tests/run-all.sh` and fix regressions.

---

## Verification Plan

After every atomic commit:

```bash
./tests/run-all.sh
zsh tests/test-manpage-version-sync.zsh
mkdocs build --strict 2>&1 | head
```

Final PR checklist:
- [ ] Full suite green
- [ ] Man-page sync guard 12/12
- [ ] `mkdocs build --strict` clean
- [ ] New characterization test passes standalone
- [ ] `.STATUS` updated with email split completion

---

## Risks & Rollback

| Risk | Mitigation |
|------|------------|
| Comments lost during split | Split by line ranges, not by `functions[$fn]` extraction |
| Routing behavior drift | Characterization tests must pass before and after split |
| Man-page coverage detector misses `em` | Already updated in previous PR to scan subdirectories |

**Rollback trigger:** If characterization tests cannot be made green within the first two commits, revert the split and keep the monolithic file.

---

## Next Actions After ORCHESTRATE Commit

1. Implement A (characterization tests).
2. Implement B (email dispatcher split).
3. Implement C (test fixes).
4. Final verification and PR to `dev`.
