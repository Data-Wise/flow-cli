# ORCHESTRATE: flow-cli Restructure — Phase 1

**Spec:** `docs/specs/SPEC-flow-cli-restructure-2026-07-06.md`  
**Branch:** `feature/flow-cli-restructure-phase1`  
**Base:** `dev`  
**Goal:** Refactor in place to prove a clean core/extensions boundary before any repo split.

---

## Phase 1 Exit Criteria

1. `lib/dispatchers/teach-dispatcher.zsh` < 2,000 lines (from 5,611).
2. `lib/dispatchers/email-dispatcher.zsh` < 1,500 lines (from 3,214).
3. `commands/doctor.zsh` uses a `_doctor_register_check` framework.
4. `./tests/run-all.sh` reports 75 pass / 0 fail / 1 timeout (interactive baseline) / 1 skip (himalaya absent).
5. Man-page version-sync guard still passes (`tests/test-manpage-version-sync.zsh`).

---

## Work Breakdown

### A. Characterization tests for `teach-dispatcher.zsh`

- Add `tests/test-teach-dispatcher-characterization.zsh` that exercises every public subcommand case via mocked helpers.
- Do not change behavior; only capture current outputs/exit codes.
- Run until green before any refactor.

### B. Break up `teach-dispatcher.zsh`

Target modules in `lib/dispatchers/teach/`:

| Module | Responsibility | Source functions |
|--------|----------------|------------------|
| `teach-main.zsh` | Entry point, argument routing, help | top-level `_teach()` and `_teach_help()` |
| `teach-deploy.zsh` | `teach deploy` + rollback + history | deploy/rollback/history helpers |
| `teach-doctor.zsh` | `teach doctor` + checks | doctor impl helpers |
| `teach-config.zsh` | `teach config check/diff/show/scaffold` + style | config/style helpers |
| `teach-analyze.zsh` | `teach analyze/plan/validate` | analyze/plan/validate wrappers |
| `teach-misc.zsh` | `teach macros/templates/profiles/cache/migrate` | smaller commands |

- `lib/dispatchers/teach-dispatcher.zsh` becomes a thin loader that sources `lib/dispatchers/teach/*.zsh` in order.
- Keep function names and command behavior identical.

### C. Characterization tests for `email-dispatcher.zsh`

- Add `tests/test-em-dispatcher-characterization.zsh` mirroring existing `test-em-dispatcher.zsh` but scoped to public command routing only.

### D. Break up `email-dispatcher.zsh`

Target modules in `lib/dispatchers/em/`:

| Module | Responsibility |
|--------|----------------|
| `em-main.zsh` | Entry point, help, backend toggling |
| `em-send.zsh` | `em send/reply/forward/draft` |
| `em-organize.zsh` | `em star/thread/snooze/digest` |
| `em-manage.zsh` | `em delete/move/restore/flag/todo/event/create-folder` |
| `em-pick.zsh` | `em pick` multi-select UI |
| `em-ai.zsh` | `em ai/catch/prompt` AI-backed commands |

- `lib/dispatchers/email-dispatcher.zsh` becomes a thin loader.

### E. Refactor `doctor.zsh` to a plugin-health framework

- Introduce `lib/doctor-framework.zsh` with:
  - `_doctor_register_check <category> <name> <function>`
  - `_doctor_run_checks <category>`
- Move existing checks into registered functions:
  - `install`, `shell`, `git`, `github`, `atlas`, `email`, `teaching`, `tokens`, etc.
- Keep `commands/doctor.zsh` as the CLI wrapper and report renderer.
- Add `tests/test-doctor-framework.zsh`.

### F. Shared-lib stabilization

- Document the public surface of `lib/core.zsh`, `lib/tui.zsh`, `lib/project-detector.zsh`.
- Move any dispatcher-only helpers out of core into the dispatcher modules.
- No new public API without a doc comment.

---

## Verification Plan

After every atomic commit:

```bash
./tests/run-all.sh
zsh tests/test-manpage-version-sync.zsh
mkdocs build --strict 2>&1 | head
```

Final PR checklist:
- [ ] Full suite green (75/0/1/1)
- [ ] Man-page sync guard 12/12
- [ ] `mkdocs build --strict` clean
- [ ] CLAUDE.md architecture section updated
- [ ] CHANGELOG `[Unreleased]` entry added
- [ ] `.STATUS` updated with Phase 1 completion

---

## Risks & Rollback

| Risk | Mitigation |
|------|------------|
| Behavior drift during dispatcher split | Characterization tests must pass before and after each extraction |
| Doctor framework breaks existing checks | Keep original check functions; only change how they are invoked |
| Merge conflicts on dev | Rebase onto `origin/dev` before final PR; run full suite after rebase |

**Rollback trigger:** If characterization tests cannot be made green within the first two commits, abandon the dispatcher split and revert to spec-only changes.

---

## Next Actions After ORCHESTRATE Commit

1. Implement A (characterization tests).
2. Implement B (teach dispatcher split).
3. Implement C/D (email dispatcher split).
4. Implement E (doctor framework).
5. Implement F (shared-lib docs + cleanup).
6. Final verification and PR to `dev`.
