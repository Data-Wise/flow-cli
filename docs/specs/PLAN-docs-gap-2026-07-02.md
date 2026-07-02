# PLAN — flow-cli documentation gap & staleness analysis

**Date:** 2026-07-02 · **Status:** Implemented — items 1–4 of "Recommended next steps" applied same session (`e9396bfca`). Item 5 (full remaining ~10-spec sweep) intentionally still out of scope, unstarted.
**Trigger:** post-v7.14.0-release audit (the cloud-agent routine that would have done this was created then disabled — see `.STATUS` — this plan supersedes it, done directly instead)

## Method

Checked, in order: `mkdocs build --strict`, full test suite reproduction, API-reference coverage for functions/features added in the last ~30 commits, spec-status accuracy (cross-referenced against CHANGELOG evidence of actual shipping), test-count references across docs vs. the real current count, and the CHANGELOG root/docs mirror (already fixed earlier this session).

## Findings

### Clean — no action needed

| Check | Result |
|---|---|
| `mkdocs build --strict` | 0 warnings |
| Full suite reproduction | 74 passed, 0 failed, 0 timeout, 1 skipped — matches CLAUDE.md's stated count |
| API-reference coverage for this session's 4 new functions (`_flow_status_field`, `_flow_resolve_project_path`, `_flow_suggest_project`, `_schedule_atlas_items`) | all documented (Phase 4 of the planning-coordination work) |
| `tok mint` dispatcher-guide coverage | documented (10 references in `MASTER-DISPATCHER-GUIDE.md`) |
| `flow claude` C7–C11 checks documented | 12 references in `docs/commands/claude.md` |
| `SPEC-agenda-schedule-2026-06-13.md` status | correctly `Implemented` (table-format status line — my first grep pattern missed it, false alarm on my end, not a real gap) |
| CHANGELOG root/docs mirror | identical (fixed earlier this session) |

### Real gaps found

**1. `docs/guides/TESTING.md` is significantly stale.**
Line 411: `**Test Count:** 219 test files, 12000+ assertions, 67/67 suites passing` — actual current state is **74/74 suites passing** (per `run-all.sh`'s own count) on **230 raw `.zsh` files** under `tests/`. This number has been stale across at least 2 releases (the last update I can find bumped 217→219, well before the 74-suite count existed).

**2. Test-file count itself needs a defined methodology, not just a bump.**
CLAUDE.md currently states **245** test files (set in this session's own Phase 4 commit), but a raw `find tests -name "*.zsh" -type f` count is **230**. `run-all.sh` registers **75** `run_test` calls (74 pass + 1 skip). Three different numbers for "how many tests" (230 files / 75 registered suites / 245 claimed) — the 245 figure looks like an overcount introduced this session, not verified against a `find` at the time. **Recommend:** pick one canonical definition (I'd recommend "registered suites" = the `run_test` count, since that's what `run-all.sh`'s own summary line reports and what a reader actually experiences), state it explicitly in both CLAUDE.md and TESTING.md, and correct both to match. Do not just bump the number again without fixing the counting method, or this recurs at the next release.

**3. At least 5 specs in `docs/specs/` are marked `Status: draft` despite their features having clearly shipped** (confirmed via CHANGELOG hits, not assumption):
- `SPEC-teach-doctor-v2-2026-02-07.md` — draft; CHANGELOG has 6 "teach doctor" hits
- `SPEC-teach-deploy-v2-2026-02-03.md` — draft; CHANGELOG has 8 "teach deploy" hits
- `SPEC-teach-plan-v2-2026-01-29.md` — draft; CHANGELOG has 1+ "teach plan" hits (worth a closer look — lower confidence than the other four)
- `SPEC-em-v2-2026-02-26.md` — draft; CHANGELOG has 8 "em v2" hits
- `SPEC-dot-rename-split-2026-02-14.md` — draft; CHANGELOG has the "Dispatcher split" entry (`dot` → `dots`/`sec`/`tok`, v7.1.0)

**Not yet cross-checked** (lower-confidence candidates, same pattern, worth the same treatment): `SPEC-teach-map-2026-02-08.md`, `SPEC-himalaya-editor-plugin-2026-02-11.md` (already partially annotated as "partially-implemented" — may just need the annotation refreshed), `SPEC-latex-macros-2026-01-28.md`, `SPEC-testing-framework-2026-02-16.md` (no CHANGELOG hits found — could be genuinely still-draft, not stale; needs a feature-existence check, not a CHANGELOG grep, before concluding either way).

**Out of scope for this pass:** the ~10 remaining "draft"/"proposal" specs not mentioned above were not individually checked — this plan prioritized specs with strong positive CHANGELOG evidence over an exhaustive sweep of all ~40 spec files.

## Recommended next steps (not yet executed)

1. Fix `docs/guides/TESTING.md`'s stale count (219/67 → current numbers, once #2 below is settled).
2. Decide the canonical test-count methodology, then correct CLAUDE.md + TESTING.md to match it consistently.
3. Mark the 5 confirmed-stale specs `Implemented` (with a one-line pointer to the shipping version/PR, matching the pattern already used in `SPEC-agenda-schedule-2026-06-13.md` and `SPEC-obs-dispatcher-shadowing-2026-06-04.md`).
4. Do the same check for the "not yet cross-checked" list (§ above) before touching them — don't mark `SPEC-testing-framework-2026-02-16.md` implemented without confirming a real feature exists, since it had zero CHANGELOG evidence either way.
5. Full remaining spec sweep (the ~10 out-of-scope ones) is a separate, larger pass — size it before starting; don't fold it silently into item 3.

## Verification (once fixes are applied)

- `mkdocs build --strict` — must stay 0 warnings.
- `./tests/run-all.sh` — must stay green; re-run count-derivation commands (`find tests -name "*.zsh" | wc -l`, `grep -c "^run_test " tests/run-all.sh`) to confirm the new stated numbers are actually correct, not just different.
- Re-grep spec statuses after the mark-implemented pass to confirm no accidental over-claiming (a spec marked Implemented should have a real, checkable shipped feature — CHANGELOG entry or passing test — not just "looks old").
