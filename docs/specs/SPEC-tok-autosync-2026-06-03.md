# SPEC: `tok` Auto-Sync to GitHub Actions Secrets

## Metadata

- **Status:** draft
- **Created:** 2026-06-03
- **Component:** `lib/dispatchers/tok-dispatcher.zsh` + new `lib/tok-sync.zsh`
- **From Brainstorm:** this session (interactive brainstorm)
- **Related:** `[[feedback_no_merge_from_worktree]]`, em v2.0 ZSH security patterns

## Overview

Extend the `tok` token dispatcher so that after any successful token
create or rotate, it automatically fans the credential out to a mapped
set of GitHub Actions secrets across multiple repos — showing the
targets and confirming once before writing. The mapping lives in a
chezmoi-managed flat config file. OIDC-capable publish targets (e.g.
PyPI Trusted Publishing) are deliberately **not** pushed; instead `tok`
prints a note recommending OIDC, reducing the number of secrets that
must be managed at all.

The motivating pain: the Homebrew release pipeline migrated from PATs to
a GitHub App (`APP_ID` + `APP_PRIVATE_KEY` repo secrets). Those two
secrets must exist in **every** tap-caller repo. Today they are pushed
by hand with `gh secret set` per repo. nexus-cli is currently **broken**
because its tap secrets were never configured (`.STATUS`:
"homebrew-release.yml auto-update still failing (tap secrets
unconfigured)"). This feature closes that gap.

## Primary User Story

**As** the maintainer (developer) of the Data-Wise tool ecosystem,
**I want** `tok` to push a token to all the repo Actions secrets that
need it immediately after I create or rotate it,
**so that** I never again manually run `gh secret set NAME --repo …`
across four repos, and rotations can't leave a repo (like nexus-cli)
silently broken.

## Acceptance Criteria

- After a successful `tok github|npm|pypi`, `tok rotate`, or
  `tok <name> --refresh`, if the token name has targets in the config,
  `tok` lists every `repo : secret-name` it will write and asks for a
  single `y/N` confirmation before pushing.
- On confirm, each non-OIDC target is written via
  `printf '%s' "$value" | gh secret set <secret> --repo <repo>`
  (stdin only — value never appears in process args or a temp file).
- A per-target `oidc` flag suppresses the push for that row and prints a
  "use Trusted Publishing instead" note (pointer to `id-token: write` +
  `pypa/gh-action-pypi-publish`).
- `tok sync push <name>` triggers the fan-out manually; `tok sync repos
  <name>` shows the planned targets (dry inspect) including OIDC notes.
- `tok sync gh` retains its existing behavior unchanged.
- `--no-sync` flag and `FLOW_TOK_AUTOSYNC=0` disable the automatic hook.
- Missing `gh`, unauthenticated `gh`, missing config, zero non-OIDC
  targets, or empty value each produce a clear message and a no-op (no
  partial writes).
- Tests pass; `source flow.plugin.zsh` succeeds.

## Secondary User Stories

- **As** the maintainer, **I want** `tok sync repos <name>` to show me
  what *would* be pushed without writing anything, so I can audit the
  mapping before trusting auto-push.
- **As** the maintainer, **I want** to add a new tap-caller repo by
  editing one chezmoi-managed file, so the mapping syncs across machines
  and new repos are covered on the next rotate.

## Architecture

```mermaid
flowchart TD
    A[tok github / npm / pypi / rotate / refresh] --> B[store token in vault]
    B --> C{FLOW_TOK_AUTOSYNC\nand not --no-sync?}
    C -- no --> Z[done]
    C -- yes --> D[_tok_sync_push name value]
    D --> E[_tok_sync_load_targets name]
    E --> F{any targets?}
    F -- no --> Z
    F -- yes --> G[partition rows: oidc vs push]
    G --> H[print OIDC notes for oidc rows]
    G --> I[list push targets: repo : secret]
    I --> J{confirm once y/N}
    J -- no --> Z
    J -- yes --> K[for each push row:\nprintf value | gh secret set secret --repo repo]
    K --> L[report check / cross per repo]
```

## API Design

### Config file — `~/.config/flow/tok-sync.conf` (chezmoi-managed)

Flat, whitespace-delimited. Lines beginning with `#` and blank lines are
ignored. Fields: `<token-name> <secret-name> <owner/repo> [oidc]`.

```
# <token-name>  <secret-name>     <owner/repo>     [oidc]
github-app       APP_ID            data-wise/flow-cli
github-app       APP_PRIVATE_KEY   data-wise/flow-cli
github-app       APP_ID            data-wise/aiterm
github-app       APP_PRIVATE_KEY   data-wise/aiterm
github-app       APP_ID            data-wise/examark
github-app       APP_PRIVATE_KEY   data-wise/examark
github-app       APP_ID            data-wise/nexus-cli
github-app       APP_PRIVATE_KEY   data-wise/nexus-cli
pypi             PYPI_TOKEN        data-wise/nexus-cli   oidc
```

- The file is **never** `source`d. Parsed with `while read -r name secret repo flag`.
- `secret` and `repo` validated against `^[A-Za-z0-9._/-]+$`; rows
  failing validation are skipped with a warning.
- Config path overridable via `FLOW_TOK_SYNC_CONF`.

### Functions — `lib/tok-sync.zsh`

| Function | Signature | Behavior |
|---|---|---|
| `_tok_sync_load_targets` | `<name>` | Emits `secret<TAB>repo<TAB>flag` rows matching `<name>`; applies allowlist validation. |
| `_tok_sync_push` | `<name> [value]` | Loads targets; partitions oidc/push; prints OIDC notes; lists push targets; confirms once; writes via `gh secret set` over stdin; reports per-repo result. Resolves `value` from vault when omitted. |
| `_tok_sync_resolve_value` | `<name>` | Reads token value from vault (`sec`/`bw`) for manual-trigger path. |

### Dispatcher — `tok-dispatcher.zsh`

| Command | Behavior |
|---|---|
| `tok sync push <name>` | Manual fan-out for `<name>`. |
| `tok sync repos <name>` | Dry inspect: list targets + OIDC notes, no writes. |
| `tok sync gh` | **Unchanged** (existing gh CLI auth). |
| (post-store hook) | `_tok_github/_tok_npm/_tok_pypi/_tok_rotate/_tok_refresh` call `_tok_sync_push "<name>"` after successful store, unless `--no-sync`/`FLOW_TOK_AUTOSYNC=0`. |

## Data Models

N/A — no persistent data model beyond the flat config file described in
API Design. No database, no JSON state file (token values continue to
live in the existing vault; expiry tracking is unchanged).

## Dependencies

- `gh` CLI (already an optional/expected tool for `tok sync gh`).
- Existing vault backend (`sec` / `bw` / Keychain) — unchanged.
- chezmoi — external to flow-cli; manages the config file as a dotfile.
  flow-cli does **not** call chezmoi; it only reads the resulting file.
- No new runtime dependencies. Pure ZSH; no `yq`/YAML parser (flat
  format chosen specifically to preserve zero-dependency constraint).

## UI/UX Specifications

### User flow (auto-push after rotate)

```
$ tok github-app --refresh
... (existing rotate flow, stores new value) ...

🔁 Auto-sync targets for 'github-app':
  data-wise/flow-cli   : APP_ID, APP_PRIVATE_KEY
  data-wise/aiterm     : APP_ID, APP_PRIVATE_KEY
  data-wise/examark    : APP_ID, APP_PRIVATE_KEY
  data-wise/nexus-cli  : APP_ID, APP_PRIVATE_KEY

Push these secrets now? [y/N]: y
  ✓ data-wise/flow-cli   APP_ID
  ✓ data-wise/flow-cli   APP_PRIVATE_KEY
  ...
  ✓ data-wise/nexus-cli  APP_PRIVATE_KEY
Done: 8 secrets across 4 repos.
```

### OIDC note (dry inspect)

```
$ tok sync repos pypi
ℹ data-wise/nexus-cli  PYPI_TOKEN  → OIDC-capable.
  Recommend Trusted Publishing instead of a token secret:
  add `permissions: id-token: write` + use
  `pypa/gh-action-pypi-publish`. Skipping push.
```

### Accessibility / CLI conventions

- Uses existing `FLOW_COLORS` palette and `_flow_log_*` helpers.
- Honors `NO_COLOR`.
- Single confirmation prompt; default is **N** (safe).
- All output prefixed with status glyphs (✓ / ✗ / ℹ / 🔁) consistent
  with other dispatchers.

## Open Questions

1. Should `tok sync push` (manual) also honor the single-confirm gate,
   or push immediately since it was explicitly invoked? **Tentative:**
   keep the confirm for consistency; revisit if it feels redundant.
2. When a `gh secret set` fails mid-fan-out, continue remaining repos
   and report failures at the end (proposed) vs abort? **Tentative:**
   continue + summarize.

## Review Checklist

- [ ] Config parser never `source`s the file; allowlist enforced.
- [ ] Secret values passed via stdin only (no `--body`, no temp files).
- [ ] `--` terminator / safe arg handling on all `gh` calls.
- [ ] `--no-sync` and `FLOW_TOK_AUTOSYNC=0` both bypass the hook.
- [ ] OIDC-flagged rows are never pushed.
- [ ] Guards produce no-ops, never partial writes.
- [ ] `tok sync gh` behavior unchanged.
- [ ] Tests added in `tests/test-tok-sync.zsh` and passing.
- [ ] `source flow.plugin.zsh` succeeds.
- [ ] Docs updated (MASTER-DISPATCHER-GUIDE, tok help, cookbook).

## Implementation Notes

- New code → feature worktree (`feature/tok-autosync` off `dev`), per
  flow-cli branch workflow. This spec commit stays on `dev`.
- Reuse em v2.0 security patterns: validate at boundaries, stdin for
  secrets, allowlisted parsing.
- Seed `tok-sync.conf` with the 4 known `github-app` callers (flow-cli,
  aiterm, examark, nexus-cli) as the canonical first mapping; nexus-cli
  is the currently-broken repo this unblocks.
- OIDC note content should point at `pypa/gh-action-pypi-publish` +
  `id-token: write`, matching nexus-cli's working release.yml pattern.

## History

- **2026-06-03** — Initial draft from interactive brainstorm. Scope:
  config-driven post-store auto-push (Approach A); chezmoi-managed flat
  config; confirm-once gate; OIDC nudge folded in after reviewing
  nexus-cli's CI release pattern.
