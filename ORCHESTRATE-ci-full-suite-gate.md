# ORCHESTRATE: Gate the full test suite in CI

> **Working artifact** for `feature/ci-full-suite-gate`. Implement in a fresh session from
> this worktree (`cd ~/.git-worktrees/flow-cli/ci-full-suite-gate && claude`).
> Authoritative design: `docs/specs/SPEC-ci-full-suite-gate-2026-06-13.md` (read it first).
> **Delete this file during the dev-merge cleanup.**

## Branch / base
- Worktree: `~/.git-worktrees/flow-cli/ci-full-suite-gate`
- Branch: `feature/ci-full-suite-gate` (off `dev` @ `3b89ff09`)
- Target PR: `--base dev`
- Version: no bump (CI/infra; not a user-facing release on its own)

## Gating-set decision (default — confirm against Phase 1 data)
**Full-minus-IMAP:** the required gate is all 65 suites EXCEPT `e2e-em-dispatcher` (external IMAP,
can only ever skip on a hosted runner). `test-atlas-contract` stays in the gate but must *skip*
its warm-path cleanly. If Phase 1 reveals more genuinely-external suites, widen the skip list and
note it here. (Smaller fallback per the spec: gate only `test-doctor.zsh` first.)

---

## Phase 1 — Measure (non-blocking) ⏱️ first
Goal: capture ground-truth CI results before changing any test.

- [ ] Add a **separate** job `full-suite` to `.github/workflows/test.yml`:
  - mirrors the existing mock-project setup steps (reuse the `Create mock project structure` block)
  - runs `cd ~/projects/dev-tools/flow-cli && ./tests/run-all.sh`
  - **non-blocking:** `continue-on-error: true` (do NOT add to required checks yet)
  - emits the run-all summary to `$GITHUB_STEP_SUMMARY`
- [ ] Open a draft PR to `dev`; let CI run; **record the actual pass/skip/fail list** in this file.
- [ ] Compare runner reality vs the local table in the spec (atlas absent ⇒ expect the
  atlas-skew tests to pass and atlas-contract warm-path to skip).

**Checkpoint:** paste the Phase 1 runner result here before starting Phase 2.

```
Phase 1 CI result (PR #465, run 27483939884, ubuntu-24.04, 2026-06-14):
  51 passed, 14 failed, 0 timeout  (run-all.sh exit 1)
```

### Phase 1 finding — spec table was WRONG; inverse skew
The runner is NOT cleaner than local. The 2 suites the spec predicted would fail
(`e2e-core-commands`, `test-atlas-contract`) **PASS on the runner** (atlas absent ⇒
fallback/skip path fires, exactly as hypothesized). But **14 OTHER suites FAIL** —
they pass locally because the Mac has tools the Ubuntu runner lacks (brew, atlas,
himalaya, R, quarto). `e2e-em-dispatcher` **failed** (not timeout) → 0 timeouts.

14 failing suites (cause = likely, confirm in Phase 2):
| Suite | Likely cause |
|---|---|
| test-doctor | `flow doctor` probes brew/atlas/plugins — none on runner |
| test-cc-dispatcher | cc/claude launcher binary absent |
| test-em-dispatcher | himalaya absent |
| dogfood-em-dispatcher | himalaya absent |
| e2e-em-dispatcher | IMAP/himalaya absent (FAILS, not timeout) |
| dogfood-atlas-bridge | atlas absent |
| dogfood-teach-doctor-v2 | R/renv absent |
| test-teach-deploy-v2-unit | R/quarto/rsync absent |
| test-teach-deploy-v2-integration | R/quarto/rsync absent |
| dogfood-teach-deploy-v2 | R/quarto/rsync absent |
| e2e-teach-deploy-v2 | R/quarto/rsync absent |
| test-help-compliance | `ait`/aiterm absent → `tm` dispatcher degrades (CONFIRMED) |
| test-help-compliance-dogfood | `ait`/aiterm absent → `tm` degrades (CONFIRMED) |
| automated-plugin-dogfood | `ait`/aiterm absent → `tm` is alias not function (CONFIRMED) |

CORRECTION (2026-06-14, runner-instrumented): the 3 "pure-zsh ⚠️" suites are NOT pure-zsh
and NOT real bugs. Root cause confirmed by a CI diagnostic job: the runner has **no `tm`
binary** (`commands[tm]` empty — the binary-precedence guard was never involved). `tm` is
the **aiterm** dispatcher (`lib/dispatchers/tm-dispatcher.zsh:44-55`): when the `ait` CLI is
absent it intentionally degrades to `alias tm='_tm_not_installed'` and early-returns, so
`tm()`/`_tm_help()` are never defined. The 3 suites assert `tm` is a full dispatcher →
they fail only because `ait` is absent. This is the **same tool-absent skew class** as the
other 11 (atlas/himalaya/R/quarto). A first (wrong) attempt added `tm` to
FLOW_INTENTIONAL_SHADOWS — reverted (commit ed98365f); the fix belongs in the TESTS.

Implication: ALL 14 failures are one uniform class — service/tool-dependent suites that
must clean-SKIP or accept graceful degradation when their tool is absent. There are NO
real-bug outliers. The spec's "smaller fallback = gate just test-doctor" is non-viable
(test-doctor itself FAILS on the runner). Tools whose absence drives the 14: `atlas`,
`ait` (aiterm), `himalaya` (email/IMAP), `R`/`renv`, `quarto`/`rsync`.

---

## Phase 2 — Make the suite deterministic & green in CI
Goal: `run-all.sh` exits 0 on the runner; identical result locally with/without `atlas` on PATH.

- [ ] **Determinism (atlas-skew):** in tests that assert *standalone* fallback behavior, pin
  `FLOW_ATLAS_ENABLED=no` in setup so installing atlas can't flip the result.
  - `tests/e2e-core-commands.zsh` → `status reads .STATUS` ([1]) and `catch creates capture` ([7]);
    audit the whole file for other atlas-delegating asserts.
- [ ] **Clean-skip service-dependent tests** (skip only when the dep is genuinely absent; `return 77`):
  - `tests/test-atlas-contract.zsh` → route the 4 warm-path tests (`atlas stats|parked|trail`,
    currently exit 127) through `skip_without_atlas()` (or skip when `atlas stats` ≠ 0).
  - `tests/e2e-em-dispatcher.zsh` → skip IMAP cases (`em unread`/`em read`) when no account is
    configured; add a short per-call timeout so a hang can't wedge the suite.
- [ ] **run-all.sh CI semantics:** decide timeout handling. Once IMAP tests SKIP rather than hang,
  make `TIMEOUT>0` a hard failure in the gated context (a real hang must be caught). Keep local
  behavior unchanged or gate on an env flag (e.g. `FLOW_TEST_CI=1`).
- [ ] Run locally **both ways** to prove determinism:
  - with atlas:  `./tests/run-all.sh` → 0
  - without:     `PATH=$(echo $PATH | tr ':' '\n' | grep -v homebrew | paste -sd:) ./tests/run-all.sh`
    (or temporarily shadow atlas) → 0
- [ ] Update `docs/guides/TESTING.md`: document the gate + how service tests skip; refresh counts
  if any test counts change.

**Definition of green:** every non-skipped suite passes; service-dependent cases report SKIP
(visible in output), never FAIL/TIMEOUT.

---

## Phase 3 — Promote to required
- [ ] Flip `full-suite` to blocking (drop `continue-on-error`); confirm green on the PR.
- [ ] Add `full-suite` to required checks on **`dev`** branch protection; soak ≥1 PR.
- [ ] Then add it to **`main`** protection:
  `gh api -X PUT repos/Data-Wise/flow-cli/branches/main/protection --input <json>` (include the
  existing `ZSH Plugin Tests` + new `full-suite`; preserve PR-required/no-force/no-delete).
  ⚠️ Outward-facing — do only after dev soak; confirm with user.
- [ ] Keep the fast smoke job (quick signal) alongside the full gate.

---

## Integrate
- [ ] `git fetch origin dev && git rebase origin/dev`
- [ ] `./tests/run-all.sh` green (the whole point — it now gates itself)
- [ ] `gh pr create --base dev`
- [ ] On merge: delete this ORCHESTRATE file; remove worktree + branch (force-delete via user — hook-blocked).

## Verification (Definition of Done)
1. CI runs the full suite on every PR to dev/main.
2. `run-all.sh` is green on the runner AND locally with/without atlas (determinism proven).
3. Service-dependent cases SKIP visibly; a deliberately-broken test reddens the required check.
4. `docs/guides/TESTING.md` updated; no version/count drift.

## Notes / decisions log (append during impl)
- 2026-06-14 — Phase 1 done. Non-blocking `full-suite` job added (commit 18ba82db),
  draft PR #465 → dev. CI ground truth: 51/14/0. Spec prediction was inverted.
- 2026-06-14 — Triage of the 3 "pure-zsh" failures (user-selected). Runner-instrumented
  diagnostic disproved the binary-precedence guess (no `tm` binary on runner). Real cause:
  `ait`/aiterm absent → `tm` dispatcher degrades to an alias (tm-dispatcher.zsh:44-55).
  Wrong fix (tm→FLOW_INTENTIONAL_SHADOWS) committed then reverted (ed98365f). Conclusion:
  all 14 are ONE class (tool-absent skew); no real bugs. Phase 2 = uniform skip/degrade
  strategy across all 14. Paused for user scoping decision.
