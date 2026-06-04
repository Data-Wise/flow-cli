# ORCHESTRATE: Man-Page Full Refresh + Anti-Drift Guard

> **Spec:** `docs/specs/SPEC-manpage-refresh-2026-06-04.md`
> **Branch:** `feature/manpage-refresh` (off `dev`)
> **Worktree:** `~/.git-worktrees/flow-cli/manpage-refresh`
> **Run in a NEW `claude` session started inside the worktree.**

---

## Approach (chosen: Hybrid)

Hand-write/update all man pages to **v7.8.0** now, AND add a CI **staleness
guard** (`.TH` version vs `FLOW_VERSION`) so they can't silently re-freeze.
Man pages stay hand-written troff (quality); the guard is the durable
anti-drift mechanism.

Source COMMANDS content from each dispatcher's `_<x>_help` output, but
**de-ANSI/de-emoji it** — the help is box-drawing/colored and not
copy-pasteable into troff. Match the existing structure in `man/man1/g.1`.

## Facilities to use

| Facility | Where |
|---|---|
| `superpowers:test-driven-development` | the guard test — write it failing (mismatched `.TH`) first |
| `superpowers:subagent-driven-development` | Wave 2: one agent per cluster of man pages (file-scoped, no collisions) |
| `Explore` agent | confirm each dispatcher's real subcommand set from `lib/dispatchers/*.zsh` before writing its page |
| `superpowers:verification-before-completion` | run `run-all.sh` + `man -l` spot-checks before PR |

---

## Scope (file-by-file)

**Update (6, existing — bump `.TH` to flow-cli 7.8.0 + fix drifted cmd lists):**
`flow.1` (also rebuild SMART DISPATCHERS to all 15 + at), `g.1`, `r.1`,
`qu.1`, `mcp.1`, `obs.1`.

**Create (11, new troff):**
`cc.1`, `tm.1`, `wt.1`, `dots.1`, `sec.1`, `tok.1`, `teach.1`, `prompt.1`,
`v.1`, `em.1`, `at.1`.

**`tok.1` MUST include:** `tok sync push <name>`, `tok sync repos <name>`,
`tok sync gh`, `--no-sync`, `FLOW_TOK_AUTOSYNC`, plus the wizards
(`github`/`npm`/`pypi`), `expiring`, `rotate`, `doctor`.

---

## Waves

### Wave 0 — Recon (Explore, read-only)
- [ ] For each of the 11 new dispatchers, read `lib/dispatchers/<x>-dispatcher.zsh`
      `_<x>_help` + the `case` block → authoritative subcommand list.
      *(Deferred to Wave 2 start — recon output feeds page-writing; subagent
      results don't persist across sessions. Note: filenames break convention —
      `obs.zsh`, `email-dispatcher.zsh` (em); `at` is the Atlas bridge.)*
- [x] Confirm man-page install path: `setup/README.md` adds `$FLOW_PLUGIN_DIR/man`
      to `MANPATH`. New `*.1` files are picked up automatically (dir-level, not
      per-file) — **no install change needed** for the new pages. (Wave 3 should
      still confirm Brewfile/selective-install ships `man/`.)
- [x] `.TH` format from `g.1`: `.TH G 1 "December 2025" "flow-cli 3.0.0" "User Commands"`
      — 2nd quoted field is `<product> <version>`. Replicate as
      `"flow-cli 7.8.0"`. ⚠ `scribe.1` is a *vendored* page (`scribe 1.1.0`) —
      leave it alone; the guard scopes to `flow-cli` pages only.

**Recon also found:** CI `test.yml` runs **smoke tests only** (not `run-all.sh`),
so the guard needed its own explicit CI step. `version-guard.yml` runs on
release only. 6 existing pages frozen at 3.0.0; `scribe.1` is not ours.

### Wave 1 — Anti-drift guard (TDD, do first so pages are validated as written) ✅
- [x] `tests/test-manpage-version-sync.zsh` (source-scan, standalone harness
      like `test-terminal-hygiene-regression.zsh`; `run_check`/`_th_*` fn names
      for the dogfood scanner — 4/4 clean). Scopes to `flow-cli` product pages;
      4 parser self-tests (match/mismatch/vendored) + presence + the real
      version-match assertion.
- [x] RED confirmed: 5/6 pass, the version-match check FAILS on the 6 pages at
      3.0.0 (expected 7.8.0). GREEN comes as pages are bumped in Wave 2.
- [x] Wired into `tests/run-all.sh` (Regression section) + a dedicated CI step
      in `.github/workflows/test.yml`.
- Committed: `3acd5e89 test(manpage): add version-sync anti-drift guard`.

### Wave 2 — Man pages (subagent-driven, file-scoped clusters)
Dispatch in parallel clusters (no shared files):
- [ ] Cluster A: `flow.1` (index + dispatcher list + SEE ALSO) + update `g.1`,`r.1`,`qu.1`,`mcp.1`,`obs.1`
- [ ] Cluster B: `tok.1` (full, incl. sync), `sec.1`, `dots.1`
- [ ] Cluster C: `cc.1`, `wt.1`, `tm.1`, `v.1`, `prompt.1`
- [ ] Cluster D: `teach.1`, `em.1`, `at.1`
Each page: `.TH … "flow-cli 7.8.0" …`, NAME, SYNOPSIS, DESCRIPTION,
COMMANDS, EXAMPLES, SEE ALSO, AUTHOR.

### Wave 3 — release.sh + install (Open Q3)
- [ ] Add a `release.sh` step that seds `.TH` version on all `man/man1/*.1`
      → `$VERSION` (so the guard is a backstop, not the primary path).
- [ ] Ensure README/`setup/`/Brewfile install the new pages.

### Wave 4 — Verify (verification-before-completion)
- [ ] `tests/test-manpage-version-sync.zsh` → GREEN.
- [ ] `./tests/run-all.sh` — report counts (new test file added → bump
      counts in CLAUDE.md / TESTING.md / .STATUS).
- [ ] `man -l man/man1/tok.1` (+ a few others) render clean.
- [ ] `source flow.plugin.zsh` clean.

## Docs / counts
- [ ] Update test-count refs (new guard test): CLAUDE.md tree+status,
      TESTING.md, .STATUS.
- [ ] CHANGELOG `[Unreleased]`: "Added — full man-page set (all 15
      dispatchers) + man-page version-sync CI guard."

## Integration
- [ ] `git fetch origin dev && git rebase origin/dev`
- [ ] `./tests/run-all.sh`
- [ ] `gh pr create --base dev`
- [ ] **Do not self-merge** — user performs merges. Delete this ORCHESTRATE
      file on merge to dev.

## Open Questions (from spec — resolve while implementing)
1. Include `at.1`? → **yes** (planned above).
2. Missing-page guard now or follow-up? → **version-sync now; missing-page
   guard noted as follow-up**.
3. `release.sh` auto-bump `.TH`? → **yes** (Wave 3).
