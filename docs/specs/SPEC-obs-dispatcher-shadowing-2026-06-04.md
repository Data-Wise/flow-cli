# SPEC: Stop the `obs` Dispatcher from Shadowing the Real `obs` Binary

**Status:** WIP — running (worktree `feature/obs-dispatcher-shadowing`)
**Created:** 2026-06-04
**Type:** dispatcher / shell-integration fix
**Trigger:** On 2026-06-04, interactive `obs` failed with `[ERROR] Python CLI not found at: …/flow-cli/.../zsh/functions/python/obs_cli.py`. flow-cli loads an `obs` **dispatcher** that duplicates the obsidian-cli-ops wrapper but (a) looks for a `python/obs_cli.py` flow-cli never bundles and (b) uses `OBS_PYTHON=$(command -v python3)` → a dep-less `python@3.14`. It **shadows** the working Homebrew `obs` binary (`/opt/homebrew/bin/obs`).

---

## Overview

obsidian-cli-ops installs a complete, canonical `obs` on `PATH` (Homebrew binary → `libexec/python/obs_cli.py` under a known interpreter). flow-cli **also** defines `obs` via `lib/dispatchers/obs.zsh` (mirrored in `zsh/functions/obs.zsh`), sourced unconditionally by the dispatcher loop in `flow.plugin.zsh`:

```zsh
if [[ "$FLOW_LOAD_DISPATCHERS" == "yes" ]]; then
  for disp_file in "$FLOW_PLUGIN_DIR/lib/dispatchers/"*.zsh(N); do
    source "$disp_file"
  done
fi
```

Because a shell **function** beats a binary in lookup, the broken flow-cli `obs` wins in every interactive shell. The dispatcher cannot work as written — it needs a Python CLI flow-cli doesn't ship — so it provides nothing the Homebrew binary doesn't, while actively breaking it.

This is a **general hazard**: any dispatcher whose name collides with an installed external binary will shadow it.

---

## Primary User Story

**As a** flow-cli user who also installs obsidian-cli-ops,
**I want** typing `obs` to run the real, working `obs` binary,
**so that** flow-cli doesn't break a tool it doesn't own.

### Acceptance Criteria

- [ ] In an interactive shell with obsidian-cli-ops installed, `obs` resolves to the **binary** (`type obs` → `/opt/homebrew/bin/obs`), not a flow-cli function.
- [ ] flow-cli no longer defines a broken `obs` that errors `Python CLI not found`.
- [ ] Other dispatchers (`v`, `g`, `mcp`, `r`, `qu`, …) are unaffected.
- [ ] No `unfunction obs` workaround required in the user's `~/.config/zsh/.zshrc`.
- [ ] flow-cli's `man/man1/obs.1` is **removed** and `obs` dropped from the flow dispatcher inventory (coordinate with `SPEC-manpage-refresh-2026-06-04.md`, which currently lists `obs` among flow dispatchers and ships `obs.1`).
- [ ] A replacement `obs.1` is **authored in obsidian-cli-ops** (the owner of the binary), covering its v3.2.1 surface — see "Man-Page Ownership" below.

---

## Approaches

| Option | How | Trade-off |
|--------|-----|-----------|
| **A. Drop the obs dispatcher** | Delete `lib/dispatchers/obs.zsh` + `zsh/functions/obs.zsh`; remove `obs` from the "Load v, g, mcp, obs" comment/inventory; drop `obs.1`. | Simplest; obsidian-cli-ops is canonical. Loses any flow-specific obs sugar (there is none working today). |
| **B. Binary-precedence guard (recommended, general)** | In the dispatcher loop, skip sourcing a dispatcher when its command name already resolves to an external binary on `PATH`, unless `FLOW_FORCE_DISPATCHER_<name>=1`. | Fixes `obs` **and** prevents any future dispatcher↔binary collision. Slightly more loader logic. |
| **C. Thin delegator** | Replace the obs dispatcher body with `command obs "$@"` (or exec the Homebrew binary). | Keeps an `obs` function but it just forwards. Pointless indirection vs. A/B. |

**Recommendation:** **B** (a general binary-precedence guard in the loader) and **A** (remove the now-redundant obs dispatcher). B protects the ecosystem long-term; A removes dead, harmful code.

### ⚠️ Filename ≠ command name (corrects the naive sketch)

A guard keyed on the **filename** is only correct for `obs`, by accident. The dispatcher files are named `X-dispatcher.zsh` but each defines command `X`:

| File on disk | `${${disp_file:t}:r}` | Command actually defined | `command -v` of derived name |
|---|---|---|---|
| `obs.zsh` | `obs` | `obs()` | `/opt/homebrew/bin/obs` ✅ |
| `g-dispatcher.zsh` | `g-dispatcher` | `g()` | (nothing) ❌ |
| `mcp-dispatcher.zsh` | `mcp-dispatcher` | `mcp()` | (nothing) ❌ |
| `r-dispatcher.zsh` | `r-dispatcher` | `r()` | (nothing) ❌ |

`obs.zsh` is the **only** bare-named dispatcher file, so a filename-keyed guard tests `obs` and nothing else. Add `node-dispatcher.zsh` (defining `node()`) later and the guard checks `command -v node-dispatcher` → nothing → sources it → **re-shadows the real `node` binary.** That is the exact "general hazard" this spec exists to kill, left open. So the naive guard ≈ Option A with extra steps.

**Fix:** derive the true command name by **stripping the `-dispatcher` suffix**. After Option A deletes the lone exception (`obs.zsh`), **every** remaining file follows `<cmd>-dispatcher.zsh`, so suffix-stripping recovers the real command name for all of them — making the guard genuinely general with a one-line change. Guard this invariant with a convention test (see Implementation Notes).

### Sketch (Option B — corrected, suffix-strip)

```zsh
for disp_file in "$FLOW_PLUGIN_DIR/lib/dispatchers/"*.zsh(N); do
  local name="${${disp_file:t}:r}"            # g-dispatcher
  name="${name%-dispatcher}"                  # → g   (obs.zsh is deleted by Option A)
  local force="FLOW_FORCE_DISPATCHER_${name:u}"
  if [[ -z "${(P)force}" ]] && command -v "$name" >/dev/null 2>&1 \
       && [[ "$(command -v "$name")" != *"flow"* ]]; then
    [[ -n "$FLOW_DEBUG" ]] && _flow_log_info "Skipping dispatcher '$name' (external binary present)"
    continue
  fi
  source "$disp_file"
done
```

> The `disable r` at `flow.plugin.zsh:72` is unaffected — `r` is a zsh **builtin**, not an external binary, so `command -v r` (after `disable`) does not resolve to a `/path` file and the guard never skips it.

---

## Man-Page Ownership (handoff to obsidian-cli-ops)

flow-cli is *dropping* `obs.1` because it doesn't own the command. The man page should not vanish — it should move to **obsidian-cli-ops**, which owns `/opt/homebrew/bin/obs` and currently ships **zero** man pages. This is a cross-repo handoff: flow-cli removes, obsidian-cli-ops adds. Track the "add" half in obsidian-cli-ops (its own branch workflow); this spec only records the contract so the man page isn't lost.

### Command surface to document (obsidian-cli-ops v3.2.1)

Authored from the **dispatch table in `src/obs.zsh`**, not from `obs help` — see the undocumented-command note below.

| Group | Commands |
|---|---|
| Primary | `obs` (list vaults / last-vault stats), `obs stats [vault]`, `obs discover <path>` |
| Graph analysis | `obs analyze <vault>`, `obs health <vault>` |
| AI | `obs ai status`, `obs ai setup`, `obs ai test`, `obs ai similar <note>`, `obs ai analyze <note>`, `obs ai duplicates <vault>`, `obs ai suggest-links <note>`, `obs ai gaps <vault>`, `obs ai summarize <vault>`, `obs ai refactor <vault>` |
| AI — **undocumented in `obs help --all`** | `obs ai merge-suggest`, `obs ai tag-suggest`, `obs ai quality` |
| Utilities | `obs help [--all]`, `obs version` |

### ⚠️ Finding: three AI subcommands ship without help

`obs ai merge-suggest`, `obs ai tag-suggest`, and `obs ai quality` are handled in the `obs.zsh` `case` block (≈ lines 464–513) but are **absent from `obs_help()`** (lines 163–174). A man page built from `obs help` would inherit this gap. The obsidian-cli-ops man-page task should: (a) cover all dispatch-table commands, and (b) backfill these three into `obs help --all` so help and man page agree. *(Out of scope for flow-cli — flagged here for the receiving repo.)*

### Suggested shape (in obsidian-cli-ops)

- `obs.1` — top-level, with `ai` as a documented subcommand surface, **or**
- `obs.1` + `obs-ai.1` (SEE ALSO cross-links) if the AI surface warrants its own page (10–13 subcommands suggests it might).
- Mirror flow-cli's troff conventions (model `flow-cli/man/man1/g.1`); add an anti-drift `.TH`-version guard like flow-cli's `test-manpage-version-sync.zsh` so the page tracks the package version.

## Out of Scope / Related

- The **root cause** that `obs` itself broke (missing Python deps in its interpreter) is an obsidian-cli-ops packaging issue: `obsidian-cli-ops/docs/specs/SPEC-dependency-bootstrapping-2026-06-04.md`. It was patched manually on 2026-06-04 (deps installed into `python@3.12`).
- The dashboard `ops`/`obs-project-sync` tool referenced by `MediationVerse_Dashboard.md` is a **different, archived** tool — not this dispatcher and not in scope.

## Implementation Notes

- **Guard keys on the suffix-stripped command name**, not the raw filename — see "Filename ≠ command name" above. The naive filename-keyed sketch only protects `obs`.
- **Convention test (required for B1 to stay valid):** assert every `lib/dispatchers/*.zsh` is named `<cmd>-dispatcher.zsh`. This is the invariant suffix-stripping depends on; make it a hard CI gate so a future bare-named dispatcher can't silently reopen the shadowing hazard.
- Verify `r`'s existing `disable r` handling still works under the new guard (it's a builtin, not a binary — guard only checks external binaries).
- **Shadow regression test:** stub an `obs` executable into a temp dir prepended to `$PATH`, source the plugin, then assert `type obs` is a **file** (not a function) and that `g`/`mcp`/`r` still load normally. Without the stub the assertion is vacuous — the guard has nothing to skip in a bare CI environment that lacks the Homebrew `obs`.
- **Delete the `zsh/functions/obs.zsh` symlink too** (it points into the obsidian-cli-ops source and is *not* sourced by the loader, which globs only `lib/dispatchers/*.zsh`) — leaving it is pure confusion.
- Man-page + inventory cleanup ships in the **same PR** as the deletion: remove `obs.1`, drop `obs` from the loader comment (`flow.plugin.zsh:24`) and any dispatcher inventory/help, or `test-manpage-version-sync.zsh` fails CI (coordinate with `SPEC-manpage-refresh-2026-06-04.md`).

## History

- **2026-06-04** — Created after flow-cli's `obs` dispatcher shadowed and broke the Homebrew `obs` binary; stopgap was `unfunction obs` in user zshrc (blocked/avoided). This spec proposes removing the redundant dispatcher + a general binary-precedence guard.
- **2026-06-04** — Brainstorm pass (`BRAINSTORM-obs-dispatcher-shadowing-2026-06-04.md`) found the Option B sketch keyed the guard on the **filename**, which equals the command name only for `obs.zsh` (every other file is `X-dispatcher.zsh` defining `X`). Replaced with the **suffix-strip (B1)** variant so the guard is genuinely general post-Option-A; added the convention test, stub-binary regression test, and symlink-deletion notes.
- **2026-06-04** — Added Man-Page Ownership handoff: flow-cli removes `obs.1`, obsidian-cli-ops authors a replacement. Audited obsidian-cli-ops **v3.2.1** command surface and found `obs ai merge-suggest`, `obs ai tag-suggest`, `obs ai quality` ship in the dispatch table but are missing from `obs help --all`.
