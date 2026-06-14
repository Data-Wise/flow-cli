# SPEC: Gate the full test suite in CI

> Status: **DRAFT — awaiting approval.** Spec-only (no code changes). On approval this
> becomes a feature worktree (`feature/ci-full-suite-gate`) + `ORCHESTRATE-ci-full-suite-gate.md`.
> Filed origin: `.STATUS` Next Action #3 / Pending "CI smoke-only gap" (2026-05-13).

## Context — why this change

`.github/workflows/test.yml` (job **ZSH Plugin Tests**, the only required status check on
`main`) runs **smoke tests only**:

```yaml
# Run smoke tests
zsh ./tests/test-flow.zsh
bash ./tests/test-install.sh
# + Man-page version-sync guard
```

The full **65-suite** `./tests/run-all.sh` (~4 min) is **never run in CI** — the step comment
says "run full suite locally." So the required check verifies ~3 of 65 suites. Consequences:

- Regressions land green. (Documented precedent: the `test-doctor` regression in `0880f924`
  passed CI despite exiting 124 under the harness — caught only locally.)
- This session's agenda release leaned entirely on local `run-all.sh`; CI could not have
  caught a schedule-engine regression.
- The gate relies on developer discipline, not enforcement.

**Goal:** make CI run the full suite and promote it to a required check — *without* creating a
perpetually-red gate.

## Current state — the suite is NOT deterministically green (key finding)

A naive "add `run-all.sh` to CI" fails. Investigation (2026-06-13, **atlas present locally**)
shows `run-all.sh` is **environment-sensitive**, not clean:

| Suite | Local result (atlas present) | Root cause | Likely CI result (atlas absent) |
|---|---|---|---|
| `test-atlas-contract` | 4/18 FAIL — `atlas stats`/`parked`/`trail` exit **127** | atlas binary present but those subcommands aren't implemented; the 4 "warm-path" tests don't go through `skip_without_atlas()` | Likely **SKIP/pass** (`command -v atlas` false → guard fires) |
| `e2e-core-commands` | 2/22 FAIL — `status reads .STATUS` (`output=''`), `catch creates capture` | `_flow_status_show` / `catch` **delegate to the installed atlas** instead of the standalone fallback the test asserts (atlas-present skew) | Likely **pass** (fallback path) |
| `e2e-em-dispatcher` | TIMEOUT | `em unread` / `em read` block on IMAP with no configured account | TIMEOUT (no mail server) |

`run-all.sh` exit codes: **1** if any FAIL, **2** if any TIMEOUT. So today it returns non-zero
even though the failures are environment artifacts, not real regressions.

**Two distinct problems, not one:**
1. **Non-determinism / test-isolation bug:** several tests assume *standalone* (no-atlas)
   behavior but don't force it, so results flip based on whether `atlas` happens to be on
   `PATH`. Tests must pin `FLOW_ATLAS_ENABLED=no` where they assert fallback behavior.
2. **Genuinely service-dependent tests** (`e2e-em-dispatcher` IMAP, `test-atlas-contract`
   warm-path) must **skip cleanly** when the service is absent — not fail or hang.

**Real CI behavior is currently unknown** (and probably better than local, since the runner has
no atlas/IMAP). That uncertainty is itself a reason to measure before gating.

## Proposed approach — phased, never red

### Phase 1 — Measure (non-blocking)
Add a **separate, non-required** job `full-suite` to `test.yml` running `./tests/run-all.sh`
(`continue-on-error: true`, or a non-required check). Purpose: capture *ground-truth* CI
results for one or two PRs. No gating yet. Deliverable: the actual CI pass/skip/fail list.

### Phase 2 — Make the suite deterministic & green in CI
Based on Phase 1 output:
- **Pin standalone mode** in tests that assert fallback behavior (`e2e-core-commands` status/
  catch and any other atlas-skew tests): export `FLOW_ATLAS_ENABLED=no` in their setup so the
  result is identical with or without atlas installed. (Fixes the local-vs-CI divergence too.)
- **Clean-skip service-dependent tests** when the dependency is absent:
  - `test-atlas-contract` warm-path: route the 4 `atlas <subcmd>` tests through the existing
    `skip_without_atlas()` (or skip when `atlas stats` returns 127).
  - `e2e-em-dispatcher`: skip IMAP-dependent cases when no account/mailbox is configured
    (`return 77`), so the suite neither fails nor hangs. (Consider a short per-call timeout.)
- Decide `run-all.sh` **timeout policy for CI**: treat `TIMEOUT>0` as failure once IMAP tests
  skip cleanly (so a real hang is caught), OR keep the e2e-em suite out of the gated set.

### Phase 3 — Promote to required
Once `run-all.sh` is reliably green on the runner:
- Make `full-suite` a required status check on **`dev` first** (lower blast radius), observe,
  then add it to **`main`** branch protection (`gh api -X PUT .../branches/main/protection`).
- Keep the fast smoke job too (quick signal); the full job is the comprehensive gate.

## Gating-set decision (to confirm at approval)

Which suites constitute the **required** gate:
- **Recommended:** all 65 except genuinely external-service suites that can only ever skip on a
  hosted runner (`e2e-em-dispatcher` IMAP). Everything else (incl. atlas-contract, which should
  *skip* its warm-path cleanly) must pass.
- Alternative (smaller first step from the original `.STATUS` note): gate just
  `test-doctor.zsh` (~30s) — catches the documented `0880f924`-class regression — then expand.

## Files affected (implementation, later)

| File | Change |
|---|---|
| `.github/workflows/test.yml` | Add `full-suite` job (Phase 1 non-blocking → Phase 3 required) |
| `tests/e2e-core-commands.zsh` | Pin `FLOW_ATLAS_ENABLED=no` for status/catch (and any skew) |
| `tests/test-atlas-contract.zsh` | Route warm-path tests through `skip_without_atlas()` |
| `tests/e2e-em-dispatcher.zsh` | Skip (rc 77) IMAP cases without a configured account; bound timeouts |
| `tests/run-all.sh` | (Maybe) a CI mode / clearer timeout-vs-fail exit semantics |
| `docs/guides/TESTING.md` | Document the CI gate + how to skip service tests locally |
| GitHub branch protection (`dev`, then `main`) | Add `full-suite` to required checks (Phase 3) |

## Acceptance criteria

1. `./tests/run-all.sh` exits **0** on a clean runner (no atlas, no IMAP) — every non-skipped
   suite passes; service-dependent cases report SKIP, not FAIL/TIMEOUT.
2. The same `run-all.sh` still passes locally **whether or not** atlas is installed (determinism).
3. CI runs the full suite on every PR to `dev`/`main`; failures block merge (Phase 3).
4. Fast smoke job retained for quick feedback.
5. `docs/guides/TESTING.md` updated; no version/count drift.

## Risks & mitigations

- **Perpetually-red gate** → Phases 1–2 measure & green *before* requiring (Phase 3).
- **Hidden real failures masked as "env"** → each skip must be conditional on the dependency
  genuinely being absent, never unconditional; log skips so they're visible.
- **CI runtime** (~4 min) → keep it a separate job from smoke; parallel to it. Acceptable for
  a release-gating check; revisit sharding only if it becomes a bottleneck.
- **Branch-protection change on `main`** is outward-facing → apply only after `dev` soak.

## Out of scope (v1)

- Test sharding / matrix parallelism for speed.
- Installing atlas in CI to exercise the *connected* atlas paths (the contract tests should
  skip cleanly when absent; testing the live integration is a separate effort).
- Spinning up a mail server for `e2e-em-dispatcher` IMAP coverage.

## Verification (for the implementing session)

1. Phase 1 job output shows the real CI pass/skip/fail list.
2. After Phase 2: a CI run of `run-all.sh` is green; locally green both with and without
   `atlas` on `PATH` (toggle to prove determinism).
3. Phase 3: a deliberately-broken test reddens the required check and blocks a test PR.
