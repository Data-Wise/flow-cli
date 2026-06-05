# ORCHESTRATE: obs dispatcher shadowing fix

**Branch:** `feature/obs-dispatcher-shadowing` (worktree: `~/.git-worktrees/flow-cli/obs-dispatcher-shadowing`)
**Base:** `dev`
**Spec:** `docs/specs/SPEC-obs-dispatcher-shadowing-2026-06-04.md`
**Brainstorm:** `docs/specs/BRAINSTORM-obs-dispatcher-shadowing-2026-06-04.md`

> ⚠️ **This file is the plan only.** It was authored in the dev/planning session. Implementation happens in a **new `claude` session started from this worktree directory.** Do not implement from the planning session.

---

## Goal

Stop flow-cli's broken `obs` dispatcher from shadowing the real Homebrew `obs` binary (obsidian-cli-ops), and add a general guard so no future dispatcher can shadow an installed binary.

**Converged approach:** **A** (delete the dead obs dispatcher) + a **general binary-precedence guard** in the loader. The guard's exact form is an open decision — see Phase 2.

---

## Phase 1 — Option A: remove the dead obs dispatcher (fixes the live bug, low risk)

This phase alone fully resolves the reported breakage. No naming assumptions, no loader logic.

### Deletes

- [ ] `lib/dispatchers/obs.zsh` — the broken dispatcher (wants a `python/obs_cli.py` flow-cli never ships).
- [ ] `zsh/functions/obs.zsh` — **symlink** into `../obsidian-cli-ops/src/obs.zsh`; not sourced by the loader (it globs only `lib/dispatchers/*.zsh`). Pure confusion.
- [ ] `man/man1/obs.1` — flow-cli doesn't own `obs` (handoff to obsidian-cli-ops; see spec "Man-Page Ownership").
- [ ] `tests/test-obs-dispatcher.zsh` — tests the removed dispatcher.

### Inventory / reference edits (remove `obs`)

- [ ] `flow.plugin.zsh:24` — comment `# Load v, g, mcp, obs dispatchers` → drop `obs`.
- [ ] `lib/help-compliance.zsh:21` — `_FLOW_HELP_DISPATCHERS=(... tok obs prompt em)` → remove `obs`.
- [ ] `lib/help-compliance.zsh:37` — `[obs]="_obs_help"` mapping → remove.
- [ ] `lib/help-browser.zsh:26` — comment dispatcher list → remove `obs`.
- [ ] `lib/help-browser.zsh:36` — regex `^(g|cc|...|obs|...)$` → remove `obs`.
- [ ] `lib/help-browser.zsh:185` — same regex → remove `obs`.
- [ ] `tests/run-all.sh:64` — `run_test ./tests/test-obs-dispatcher.zsh` → remove the line.

### Guard-test updates

- [ ] `tests/test-manpage-version-sync.zsh` — drop `obs` from its expected dispatcher/man-page set so removing `obs.1` keeps the guard green. **Verify how it enumerates** (explicit list vs. glob of `man/man1/`) before editing.
- [ ] Search for any other `obs` inventory references missed: `grep -rIn -w obs lib/ completions/ flow.plugin.zsh man/ | grep -vi 'obsidian\|jobs\|observ\|probs'`.

### Phase 1 verification

- [ ] `source flow.plugin.zsh` in a shell where `/opt/homebrew/bin/obs` exists → `type obs` resolves to the **binary**, not a function.
- [ ] `obs help` (or bare `obs`) runs the real binary.
- [ ] `./tests/run-all.sh` green (esp. manpage-sync + help-compliance).

---

## Phase 2 — General binary-precedence guard ⚠️ KEY DECISION

### Why the spec's B1 (suffix-strip) is not enough

The spec sketch derives the command name from the filename (`<cmd>-dispatcher.zsh` → `<cmd>`). The planning audit found this invariant is **already false**, independent of obs:

| File | suffix-strip | real command |
|---|---|---|
| `email-dispatcher.zsh` | `email` | **`em`** ❌ mismatch |
| `dot-doctor-integration.zsh` | `dot-doctor-integration` | *(helper, no command)* |
| `teach-dates.zsh` | `teach-dates` | *(helper)* |
| `teach-deploy-enhanced.zsh` | `teach-deploy-enhanced` | *(helper)* |
| `teach-doctor-impl.zsh` | `teach-doctor-impl` | *(helper)* |

So B1 would check the wrong name for `em` and can't tell helpers from dispatchers. A naive "every file is `<cmd>-dispatcher.zsh`" convention test would fail on 5 existing files.

### Options (pick one in the implementing session)

- **B3 — post-source self-check (recommended).** For each file: snapshot `${(k)functions}`, source it, then for every *newly defined* function whose name resolves to an **external file binary** on `PATH` (`[[ $(command -v X) == /* ]]`), `unfunction X` unless `FLOW_FORCE_DISPATCHER_<NAME>=1`. Keys on the **real** command name; ignores helpers automatically; no naming convention needed.
  - Ordering: runs after `disable r`; `r` has no `/path` binary so it's never unfunctioned. Verify.
  - Cost: a before/after function-set diff per file (cheap).
- **B2 — explicit registry.** `typeset -gA FLOW_DISPATCHER_CMDS=(email-dispatcher em  g-dispatcher g …)`; guard skips sourcing when the mapped command is an external binary. Unambiguous but manual upkeep on every new dispatcher.
- **B1 + exceptions.** Keep suffix-strip but special-case `em` and skip helper files via an allowlist. Smallest diff; carries the naming debt forward.

**Recommendation:** **B3.** The `em`/`email` mismatch and helper files make filename-derivation fragile; post-source keys on what's actually defined.

### Phase 2 tasks (once option chosen)

- [ ] Implement the guard in the `flow.plugin.zsh` loader loop (lines 70–77), preserving `disable r` and `FLOW_FORCE_DISPATCHER_<NAME>` escape hatch + `$FLOW_DEBUG` skip log.
- [ ] **Shadow regression test** (`tests/test-dispatcher-binary-precedence.zsh`): stub an `obs` (and a throwaway like `g`) executable into a temp dir prepended to `$PATH`, source the plugin, assert the colliding command resolves to the **file** and non-colliding dispatchers still load. Register in `run-all.sh`.
- [ ] If B1/B2 chosen: add the corresponding convention/registry-coverage test. (B3 needs neither.)

### Phase 2 verification

- [ ] With a stub `obs` on `PATH`: `type obs` → file. Without it: dispatchers load normally.
- [ ] `em`, `g`, `r`, `teach`, etc. all still load and `disable r` still works.
- [ ] `./tests/run-all.sh` green.

---

## Integration

- [ ] Update `.STATUS` (worktree table + status line); update test count if tests net-changed (CLAUDE.md tree + TESTING.md + .STATUS — see memory "Test count propagation").
- [ ] `git fetch origin dev && git rebase origin/dev` → `./tests/run-all.sh` → `gh pr create --base dev`.
- [ ] Coordinate the man-page removal with `SPEC-manpage-refresh-2026-06-04.md` in the same PR (CI man-page guard).
- [ ] Delete this ORCHESTRATE file as part of the merge cleanup (it's a feature-branch artifact).

## Open decisions for the implementer

1. **Guard form: B3 vs B2 vs B1+exceptions** (Phase 2). Recommend B3.
2. Keep `FLOW_FORCE_DISPATCHER_<NAME>` escape hatch? (Recommend yes — only override for the general guard.)
3. obsidian-cli-ops `obs.1` authoring is a **separate cross-repo task** (its own branch); not in this PR.

## History

- **2026-06-04** — Plan authored on `dev`. Audit found B1's filename→command invariant already false (`em`↔`email-dispatcher`, 4 helper files), elevating the guard form to a Phase-2 decision; B3 (post-source self-check) recommended.
