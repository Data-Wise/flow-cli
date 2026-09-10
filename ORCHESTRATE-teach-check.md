# ORCHESTRATE: `teach check` (issue #359)

Spec: `docs/specs/SPEC-teach-check-2026-09-09.md` (committed to `dev`).

## Tasks

1. **`_teach_find_craft_validator()` helper** — new small function, checks 1-2
   plausible Craft install locations for `teaching_validation.py`, returns empty
   (not error) if absent. No existing "is Scholar/Craft installed" shell helper
   to model on (Scholar is a Claude plugin, not a binary) — this is a plain
   file-existence check.
2. **`_teach_check()` implementation** — new file `lib/dispatchers/teach-check.zsh`,
   per the corrected spec: config syntax (`yq`), schema (`_teach_validate_config`),
   content+render `.qmd` (`teach-validate --quiet`, full mode already covers
   yaml+syntax+render+chunks+images), R code (unconditional SKIP — Scholar has
   no availability check, pointer to `teach validate-r`), Craft content (SKIP if
   `_teach_find_craft_validator` returns empty). Aggregate pass/warn/fail/skip,
   render via the existing box style (`lib/tui.zsh`), exit 1 only on FAIL.
3. **`_teach_check_help()`** — usage text, matching sibling `_teach_*_help()`
   functions' format.
4. **Dispatcher wiring** — add `check|chk)` case to `teach()` in
   `lib/dispatchers/teach/teach-main.zsh`, alongside `doctor|doc` (not nested
   under the existing `config` subcommand).
5. **Tests** — new `tests/test-teach-check.zsh`:
   - valid config, no Scholar/Craft → all flow-cli layers PASS, both optional
     layers SKIP, exit 0
   - invalid YAML → syntax FAIL, schema FAIL, exit 1
   - missing config file → single clear error, exit 1
   - `--help` shows usage
   - Register in `tests/run-all.sh`'s explicit `run_test` list (unregistered
     suites never run in CI even on green).
6. **Docs** — add `check|chk` row to `docs/reference/MASTER-DISPATCHER-GUIDE.md`'s
   teach subcommand table and to `docs/help/QUICK-REFERENCE.md`. Add one line to
   `man/man1/teach.1`'s subcommand list (no new man page — this is a subcommand,
   not a new dispatcher).

## Verification before PR

- `./tests/run-all.sh` in this worktree (not the main checkout) — full suite tier,
  since this is new logic. Compare failures against the `origin/main` baseline if
  any appear (see `pre-pr-testing.md`: local env has a known confound if flow-cli
  is Homebrew-installed and a test does `cd` under `set -u` — the fix for that
  shipped in v7.17.3, so it should no longer apply here, but re-verify if
  unexplained failures show up).
- Live dogfood: `cd` into a real or fixture teaching project
  (`tests/fixtures/demo-course/`), run `teach check`, confirm the report matches
  the spec's mockup shape (labels, PASS/WARN/SKIP, summary line, exit code).
- `teach check --help` renders correctly.
- Man-page version-sync guard unaffected (no new `.1` file).

## Out of scope (per spec's open questions — defaults chosen, revisit if wrong)

- Naming: proceeding with top-level `check|chk` (not `status`) despite the
  existing nested `config check` — flag clearly in help text if this causes
  real confusion later.
- R-code layer: SKIP by default with a pointer to `teach validate-r`, no
  `--full` flag in this first pass — add later if requested.
