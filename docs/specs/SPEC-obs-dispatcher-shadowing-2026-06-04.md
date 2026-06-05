# SPEC: Stop the `obs` Dispatcher from Shadowing the Real `obs` Binary

**Status:** draft
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
- [ ] Docs/man-page reflect that `obs` is provided by **obsidian-cli-ops**, not flow-cli (coordinate with `SPEC-manpage-refresh-2026-06-04.md`, which currently lists `obs` among flow dispatchers and ships `obs.1`).

---

## Approaches

| Option | How | Trade-off |
|--------|-----|-----------|
| **A. Drop the obs dispatcher** | Delete `lib/dispatchers/obs.zsh` + `zsh/functions/obs.zsh`; remove `obs` from the "Load v, g, mcp, obs" comment/inventory; drop `obs.1`. | Simplest; obsidian-cli-ops is canonical. Loses any flow-specific obs sugar (there is none working today). |
| **B. Binary-precedence guard (recommended, general)** | In the dispatcher loop, skip sourcing a dispatcher when its command name already resolves to an external binary on `PATH`, unless `FLOW_FORCE_DISPATCHER_<name>=1`. | Fixes `obs` **and** prevents any future dispatcher↔binary collision. Slightly more loader logic. |
| **C. Thin delegator** | Replace the obs dispatcher body with `command obs "$@"` (or exec the Homebrew binary). | Keeps an `obs` function but it just forwards. Pointless indirection vs. A/B. |

**Recommendation:** **B** (a general binary-precedence guard in the loader) and **A** (remove the now-redundant obs dispatcher). B protects the ecosystem long-term; A removes dead, harmful code.

### Sketch (Option B)

```zsh
for disp_file in "$FLOW_PLUGIN_DIR/lib/dispatchers/"*.zsh(N); do
  local name="${${disp_file:t}:r}"            # e.g. obs
  local force="FLOW_FORCE_DISPATCHER_${name:u}"
  if [[ -z "${(P)force}" ]] && command -v "$name" >/dev/null 2>&1 \
       && [[ "$(command -v "$name")" != *"flow"* ]]; then
    [[ -n "$FLOW_DEBUG" ]] && _flow_log_info "Skipping dispatcher '$name' (external binary present)"
    continue
  fi
  source "$disp_file"
done
```

---

## Out of Scope / Related

- The **root cause** that `obs` itself broke (missing Python deps in its interpreter) is an obsidian-cli-ops packaging issue: `obsidian-cli-ops/docs/specs/SPEC-dependency-bootstrapping-2026-06-04.md`. It was patched manually on 2026-06-04 (deps installed into `python@3.12`).
- The dashboard `ops`/`obs-project-sync` tool referenced by `MediationVerse_Dashboard.md` is a **different, archived** tool — not this dispatcher and not in scope.

## Implementation Notes

- Verify `r`'s existing `disable r` handling still works under the new guard (it's a builtin, not a binary — guard only checks external binaries).
- Add a test asserting `type obs` is a file (not a function) when an `obs` binary is on PATH in the test environment.
- If Option A only: also remove the `obs` row from any dispatcher inventory/help and the `obs.1` man page (see man-page spec).

## History

- **2026-06-04** — Created after flow-cli's `obs` dispatcher shadowed and broke the Homebrew `obs` binary; stopgap was `unfunction obs` in user zshrc (blocked/avoided). This spec proposes removing the redundant dispatcher + a general binary-precedence guard.
