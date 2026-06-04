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

### Wave 2 — Man pages (subagent-driven, file-scoped clusters) ✅
Dispatched in parallel (4 subagents, no shared files — user-approved parallelism;
agents wrote files only, controller committed centrally to avoid git index races):
- [x] Cluster A: `flow.1` (SMART DISPATCHERS → all 15 + at; SEE ALSO) + `g.1`,`r.1`,`qu.1`,`mcp.1`,`obs.1`
- [x] Cluster B: `tok.1` (sync push/repos/gh, --no-sync, FLOW_TOK_AUTOSYNC — all confirmed from source), `sec.1`, `dots.1`
- [x] Cluster C: `cc.1`, `wt.1`, `tm.1`, `v.1`, `prompt.1`
- [x] Cluster D: `teach.1` (13 .SS subsections), `em.1`, `at.1` (Atlas-optional + FLOW_ATLAS_ENABLED)
All 17 flow-cli pages → `.TH … "flow-cli 7.8.0"`; render clean (mandoc exit 0);
no ANSI/box-drawing leakage. Commit `fc97da84`.

### Wave 3 — release.sh + install (Open Q3) ✅
- [x] `release.sh` seds `.TH` → `$VERSION` on flow-cli pages (scoped via
      `"flow-cli X.Y.Z"` so scribe.1 is untouched). Commit `f24760aa`.
- [x] Install verified — **no change needed**: Homebrew formula ships pages via
      `man1.install Dir["man/man1/*"]` (glob); manual installs add `man/` to
      MANPATH (setup/README.md). Both dir/glob-level → new pages auto-covered.

### Wave 4 — Verify (verification-before-completion) ✅
- [x] `tests/test-manpage-version-sync.zsh` → GREEN (6/6).
- [x] `./tests/run-all.sh` → **59 passed, 0 failed, 1 expected timeout** (e2e-em).
- [x] mandoc render-checked all 17 pages → exit 0.
- [x] `source flow.plugin.zsh` clean.

## Docs / counts ✅
- [x] Test-count refs bumped 210→211 files, 58/58→59/59 suites: CLAUDE.md
      (tree, testing, status line), TESTING.md (suite line, footer), .STATUS.
- [x] CHANGELOG `[Unreleased]` Added: full man-page set + version-sync CI guard.
      Commit `ff4c6216`.

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
