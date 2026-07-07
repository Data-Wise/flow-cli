# SPEC: `em` Dispatcher UX Refactor — Flag/Star Semantics, Help Discoverability & Safety-System Documentation

**Status:** Approved (decisions locked via grill 2026-07-07)
**Date:** 2026-07-07
**Target versions:** Phase 1+2 bundled into one PR targeting `dev` (next patch/minor release); Phase 3 deferred to a later release
**Author:** Claude Code / flow-cli ADHD-UX audit session
**Related:** `lib/dispatchers/email-dispatcher.zsh`, `tests/test-em-dispatcher.zsh`, `docs/internal/conventions/code/ZSH-COMMANDS-HELP.md`, `CLAUDE.md` (Architecture Principles §2 "ADHD-Friendly"), `SPEC-flow-cli-restructure-2026-07-06.md` (already flags this file as a maintainability hotspot)

---

## 1. Context

flow-cli's stated identity (`CLAUDE.md`, Architecture Principles) is: sub-10ms response, discoverable via built-in help, consistent dispatcher patterns, smart defaults. `em` is the email dispatcher — 56 functions, 3,214 lines, ~31 commands, the largest single dispatcher in the plugin.

This session audited `em` directly against those stated principles rather than against feature completeness, and found one correctness bug (P0) and four discoverability/consistency gaps (P1–P2). None require new dependencies or architecture changes; all are scoped to `lib/dispatchers/email-dispatcher.zsh` and its help/test surface.

### 1.1 Why now

The P0 finding is a live behavioral bug: `em flag <ID>` and `em star <ID>` are presented in `em help` as related organize-category shortcuts, but a duplicate `case` label silently makes `flag` a different, non-toggling, one-way operation instead of the toggle a user would reasonably expect. This directly erodes the "smart defaults, fast, consistent" promise this plugin makes about itself.

---

## 2. Current State — Verified Findings

### 2.1 P0: Duplicate `case` label — `flag` dead code + inconsistent semantics

In `em()`'s dispatch `case` statement (`lib/dispatchers/email-dispatcher.zsh`, ~lines 69–160), the word `flag` is bound twice:

```zsh
# MANAGE section (~line 90) — wins, always matches first
flag|fl)       shift; _em_flag "$@" ;;

# ORGANIZE section (~line 140) — "flag" branch here is unreachable dead code
star|flag)     shift; _em_star "$@" ;;
```

Because zsh `case` matches top-down and stops at first match, `em flag` **always** calls `_em_flag`, never `_em_star`. The `flag|` half of the second label is pure dead code.

Three distinct functions currently exist, with three distinct behaviors mapped onto three command names:

| Function | Line (approx) | Semantics | ID support (today) |
|---|---|---|---|
| `_em_flag` | ~1819 | One-way ADD (sets Flagged IMAP flag) | Multi-ID |
| `_em_unflag` | ~1835 | One-way REMOVE (clears Flagged IMAP flag) | Multi-ID |
| `_em_star` | ~2337 | TOGGLE (checks current state via `_em_hml_list` + `jq`, then adds or removes) | Single-ID only |

There is also a harmless duplicate `move|mv)` label (same handler bound twice — dead code, no behavioral impact, removed in the same pass for hygiene).

### 2.2 P1: No topic-scoped help

`em help` (verified live) dumps ~90 lines across 12 sections in a single invocation. No `em help <topic>` to filter to one section. Per-command `--help` exists for some commands (e.g. `em delete --help`) but not most of the 31 commands.

### 2.3 P1: Three-tier confirmation system is undocumented as a system

Verified live, three distinct confirmation tiers exist and are well-designed (graduated friction matching risk):

| Command | Confirmation | Function |
|---|---|---|
| `em delete` | Single keypress `[y/N]` | `_em_delete_confirm` (~line 1644) |
| `em delete --purge` | Must type literal word `yes` | `_em_purge_confirm` (~line 1666) |
| `em delete-folder` | Must type the full folder name | (folder-name confirm, delete-folder path) |

Genuinely good ADHD-friendly design, never stated as an intentional system in `em help`'s SAFETY section.

### 2.4 P2: Alias sprawl vs. discoverability

Short aliases exist for nearly every command but aren't centrally listed anywhere in `em help`'s main table.

### 2.5 P2: No generic `em undo`

`em restore` exists but is scoped only to Trash → INBOX. No generic "undo the last star/flag/move" for fast keyboard-driven sessions.

### 2.6 P2: `em move` has no "recently used folders" quick-list

`em move <ID> [FOLDER]` falls back to a full fzf folder picker when `FOLDER` is omitted.

---

## 3. Flag/Star/Unflag Semantic Redesign (P0 — Resolution LOCKED)

### 3.1 Resolution: keep 3 command names as distinct verbs, fix the case statement, extend `_em_star` to multi-ID

**Decided (grilled 2026-07-07):** Fix the `case` collision so each command name maps to exactly one function; keep all three names (`flag`, `star`, `unflag`) as deliberately distinct verbs; **extend `_em_star` to multi-ID** to match `_em_flag`/`_em_unflag` (resolves the consistency gap the alternative single-ID-only option would have left open).

Resulting mapping:

| Command | Function | Semantics | ID support |
|---|---|---|---|
| `em flag <ID...>` | `_em_flag` | One-way ADD | Multi-ID (unchanged) |
| `em unflag <ID...>` | `_em_unflag` | One-way REMOVE | Multi-ID (unchanged) |
| `em star <ID...>` | `_em_star` | TOGGLE (per-ID state check) | Multi-ID (**new**) |

Rationale: `flag`/`unflag` as one-way, explicit-direction, multi-ID batch operations and `star` as a toggle are a defensible, IMAP-terminology-aligned split. The actual bug is the case-statement routing, not the three-name design — fixing the routing (not merging the commands) is the minimal, lowest-risk change and preserves existing multi-ID batch usage of `flag`/`unflag`. Extending `_em_star` to multi-ID closes the one remaining inconsistency without behavior change to `flag`/`unflag`.

**Alternative considered and rejected:** consolidating to a single verb with a flag argument (e.g. `em flag <ID> [--toggle|--on|--off]`). Higher blast radius (breaks existing muscle-memory/scripts using bare `star`/`unflag`), fixes nothing beyond what the minimal fix already fixes, and no evidence the three-way split itself (as opposed to the routing bug) confuses users.

### 3.2 Concrete changes

1. **`lib/dispatchers/email-dispatcher.zsh` — dispatch `case` (~lines 69–160):**
   - Remove `flag` from the ORGANIZE-section `star|flag)` label, leaving it as `star)` only.
   - Confirm the MANAGE-section `flag|fl)` label remains bound to `_em_flag` (correct, keep as-is).
   - Remove the duplicate `move|mv)` label (delete the redundant one, keep the first).
2. **`_em_star` (~line 2337):** extend to iterate over `$@` (multiple IDs), applying the existing single-ID toggle logic (`_em_hml_list` + `jq` state check → add/remove) per ID, matching the loop pattern already used in `_em_flag`/`_em_unflag`. Each ID's toggle decision is independent (mixed starting states produce mixed correct end states).
3. **Help text:** update the ORGANIZE section of `em help` (and any per-command `--help` for star/flag/unflag) to state the three verbs explicitly as distinct: "flag/unflag = one-way set/clear (batch-capable); star = toggle (also batch-capable)."

---

## 4. Test Impact

`tests/test-em-dispatcher.zsh` currently does not distinguish `flag` from `star` behaviorally — the bug shipped undetected, which is itself evidence the two were never asserted as different. Required additions:

1. **Regression test — command routing:** assert `em flag <ID>` and `em star <ID>` invoke *different* underlying functions (mock/stub `_em_flag` and `_em_star`, dispatch each command name, assert the correct stub was called exactly once and the other was not called). Core regression guard against the case-statement collision recurring.
2. **Behavioral test — one-way vs toggle:** given a message with Flagged already set, `em flag <ID>` again should be an idempotent re-add, while `em star <ID>` on the same message should clear the flag (toggle-off). Assert divergent end states from the same starting state.
3. **Multi-ID parity test:** `em star <ID1> <ID2> <ID3>` toggles each ID independently based on its own current state (mixed starting states should produce mixed correct end states).
4. **Dead-code removal check:** grep-based guard asserting no duplicate `case` labels exist in the `em()` dispatch block — must specifically detect the same label word appearing in two different case arms with different handlers (not just any repeated word — legitimate multi-word aliases like `flag|fl)` for one handler are valid and must not false-positive).
5. Existing `em delete`/`em delete --purge`/`em delete-folder` confirmation tests are unaffected by this phase.

---

## 5. Phased Plan (bundling decided: Phase 1+2 in one PR)

### Phase 1+2 — bundled into one PR

- Fix `case` statement collision (§3.2.1)
- Extend `_em_star` to multi-ID (§3.2.2)
- Update inline help text for flag/star/unflag (§3.2.3)
- Add regression + behavioral + multi-ID + dead-code-guard tests (§4)
- Update `docs/reference/MASTER-DISPATCHER-GUIDE.md` em section describing flag/star/unflag
- Add `em help <topic>` filtering (topics: manage, organize, safety, search, config, etc. — reuse existing section names from current `em help` output)
- Audit all 31 `em` commands for `--help` coverage; add missing ones following the existing pattern (model: `em delete --help`)
- Add an explicit "Confirmation Tiers" subsection to `em help`'s SAFETY section, documenting the three-tier system (§2.3 table) as intentional design
- Update `docs/reference/` em-specific doc page cross-referencing the tier system
- No-arg `em help` output must remain byte-for-byte equivalent to today's dump except for the flag/star/unflag wording fix and the new SAFETY tier note — `<topic>` filtering is additive only

### Phase 3 — deferred to a later release (not in this PR)

- Centralize alias table in `em help` main output
- `em undo` — generic single-step undo of last star/flag/move action, using `lib/em-cache.zsh`'s existing cache API (`_em_cache_get`/`_em_cache_set`) to store `{action, id(s), prior-state}` — explicitly capped at one-step undo, no multi-level stack
- `em move` recently-used-folders quick-list (last N=3 destination folders), also via `lib/em-cache.zsh`

---

## 6. Files & Functions Touched (Summary)

| File | Phase | Change |
|---|---|---|
| `lib/dispatchers/email-dispatcher.zsh` | 1+2 | Fix `case` dead-code (flag/star, move/mv); extend `_em_star` multi-ID; update inline help; `em help <topic>` filtering; missing `--help` coverage; SAFETY tier documentation |
| `tests/test-em-dispatcher.zsh` (or new `tests/test-em-flag-star.zsh`) | 1+2 | Regression, behavioral, multi-ID, dead-code-guard tests |
| `docs/reference/MASTER-DISPATCHER-GUIDE.md` | 1+2 | Update em flag/star/unflag description; confirmation-tier note |
| `docs/reference/` (em-specific page) | 1+2 | Confirmation-tier system writeup |
| `man/man1/em.1` | 1+2 | Update if command surface changes materially (man page confirmed to exist; version-sync guard must pass) |
| `lib/dispatchers/email-dispatcher.zsh` | 3 (deferred) | `em undo`; `em move` recent-folders quick-list |
| `lib/em-cache.zsh` | 3 (deferred) | Reused as-is for undo-state and recent-folders storage — no new cache module needed |

---

## 7. Risks & Rollback Triggers

| Risk | Mitigation | Rollback trigger |
|---|---|---|
| Fixing the case statement changes observed behavior for any existing script relying on `em flag` behaving as a toggle | Document clearly in CHANGELOG as a bug fix, not a feature change; fixed behavior matches what `em help` already claimed | Any user report of a broken automation depending on the old (buggy) `flag` behavior — patch forward with a migration note, do not silently re-break `star` |
| `_em_star` multi-ID extension introduces a partial-failure mode (e.g. IMAP call fails on ID 2 of 3) | Reuse the existing per-ID error handling pattern already present in `_em_flag`/`_em_unflag` loops | Any test showing inconsistent partial-batch state with no reported error |
| `em help <topic>` filtering changes default `em help` (no-arg) output shape, breaking anything that scrapes it | No-arg `em help` must remain byte-for-byte equivalent to today's dump except the two documented wording fixes | Any undocumented diff in no-arg `em help` output vs. pre-change baseline |
| Dead-code-guard test (§4.4) false-positives on legitimate multi-word case patterns | Guard must detect the same label word in two different arms with different handlers, not just any repeated word | Guard fails on a known-good existing pattern — fix guard detection before merging, don't disable it |

---

## 8. Next-Action Checklist

- [x] Grill user on open decisions — DONE 2026-07-07 (bundling: Phase 1+2 combined; star: extend to multi-ID; implementation path: continue in-session)
- [ ] `git worktree add ~/.git-worktrees/flow-cli/em-ux-refactor -b feature/em-ux-refactor dev`
- [ ] Implement in-session (per decision — no separate ORCHESTRATE handoff needed, continuing directly): case-statement fix, `_em_star` multi-ID, help topic filtering, `--help` coverage audit, SAFETY tier docs, tests
- [ ] Run `./tests/run-all.sh` — confirm baseline pass count plus new tests, 0 new failures
- [ ] `source flow.plugin.zsh` sanity check + live `em flag`/`em star` verification showing divergent end states (E2E evidence per repo convention)
- [ ] `mkdocs build --strict` clean
- [ ] `gh pr create --base dev` with test evidence (exact command, pass/fail counts) and E2E transcript
- [ ] Phase 3 (`em undo`, recent-folders) — separate future spec-refresh or new phase under this spec, not blocking this PR
