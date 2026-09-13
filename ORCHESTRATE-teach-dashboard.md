# ORCHESTRATE: `teach dashboard` (issue #275)

Spec: `docs/specs/SPEC-teach-dashboard-2026-09-12.md` (approved, open questions
resolved via `docs/specs/GRILL-teach-dashboard-2026-09-13.md`).

## Tasks

1. **New file `lib/dispatchers/teach-dashboard.zsh`**
   - `_teach_dashboard_dispatcher()` — full sub-dispatcher (modeled on `_teach_dates_dispatcher`,
     `lib/dispatchers/teach-dates.zsh:473`), routes `generate|gen`, `preview|prev`,
     `announce|a`, `status|st`.
   - `_teach_dashboard_generate()` — reads `.flow/teach-config.yml`, computes current
     week via `_calculate_current_week` (`lib/teaching-utils.zsh:44`), break status via
     `_is_break_week` (same file), merges `.teach/announcements.json` if present,
     emits `.teach/semester-data.json` via `jq -n` with a `version`/`schema_version`
     envelope (matching `lib/concept-extraction.zsh:199`'s convention). `--force` to
     overwrite.
   - `_teach_dashboard_preview()` — terminal-only, no writes. Shows current (or
     `--week N`) week/break/topic, box-style output.
   - `_teach_dashboard_announce()` — positional args (`"Title" "Message" --expires
     DATE --type note`) or interactive wizard. Writes to `.teach/announcements.json`
     via `yq -i` (same technique as `dispatchers/teach-deploy-enhanced.zsh:512`, new
     target file). Auto-generates an `id` slug if not given.
   - `_teach_dashboard_status()` — config-only health check: `dashboard:` section
     present, announcement count + expired count, `.teach/semester-data.json`
     presence/age.

2. **`_teach_dashboard_help()`** — new file or alongside the dispatcher, matching the
   house format used by `_teach_check_help()` (#359 precedent: box header,
   Usage/Alias, layers/subcommands list, quick example, exit codes, "See also").

3. **Dispatcher wiring** — add `dashboard|dash)` case to `teach()` in
   `lib/dispatchers/teach/teach-main.zsh`, delegating to
   `_teach_dashboard_dispatcher "$@"` (same shape as the `dates)` case, not the
   simpler help-ternary used by `doctor`/`check`).

4. **Tests** — new `tests/test-teach-dashboard.zsh`:
   - `generate` on a config with full per-week fields → valid `.teach/semester-data.json`
   - `generate` twice without `--force` → refuses, exit 1
   - `preview` and `preview --week N`, including a week inside a configured break
   - `announce` (positional) and wizard mode → both append a well-formed entry to
     `.teach/announcements.json`
   - `status` with an expired announcement → flags it
   - `--help` shows usage
   - Register in `tests/run-all.sh`'s explicit `run_test` list

5. **Docs**
   - `docs/reference/MASTER-DISPATCHER-GUIDE.md` teach subcommand table
   - `docs/help/QUICK-REFERENCE.md`
   - `man/man1/teach.1` — new `dashboard`/`dash` entry
   - `docs/reference/TEACH-CONFIG-SCHEMA.md` — new optional fields (`focus`,
     `lecture`, `lab`, `assignment` per week; `semester_info.timezone`;
     `breaks[].show_next`; `dashboard.fallback_message`)

## Verification before PR

- `./tests/run-all.sh` in this worktree (`ZDOTDIR`-isolated), full-suite tier —
  compare any unexplained failures against the `dev` baseline before treating them
  as real (known pre-existing: `e2e-em-dispatcher`, `test-atlas-contract`).
- Live dogfood: a scratch `.flow/teach-config.yml` with the new per-week fields —
  run `generate`, `preview`, `announce`, `status`, confirm output matches the
  spec's mockup shape and the generated JSON is valid (`jq .` on it).
- `teach dashboard --help` renders correctly.
- Man-page version-sync guard unaffected (no new `.1` file, subcommand only).

## Out of scope (per spec)

- Fixing `teach week` — already done separately (PR #521, merged).
- Any change to the STAT 545 site's own `_quarto.yml`/`stat545.js` — flow-cli side only.
