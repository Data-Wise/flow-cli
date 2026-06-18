# SPEC: Bring the flow-cli atlas surface up to standard (v0.9.3 contract)

> Status: **DRAFT — awaiting approval.** Spec-only (no code changes here).
> On approval this becomes feature branch `feature/atlas-surface-standard` off `dev`, PR → `dev`.
> Origin: atlas v0.9.3 added 5 CLI flags flow-cli already calls; flow-cli's contract doc, two
> wrong calls, and the `at` dispatcher's help/man/completions are stale or missing.
> Companion: atlas-side spec `docs/specs/SPEC-flow-cli-integration-2026-06-13.md` (in the atlas repo).

## Context — why this change

atlas v0.9.3 implemented 5 flags flow-cli already invokes:

| atlas flag | flow-cli caller |
|---|---|
| `session status --format json` → `{project,durationMinutes,state,task,startedAt}` or `null` | `commands/work.zsh:136` |
| `project list --count` (bare integer) | `commands/morning.zsh` |
| `project list --suggest` (one active project name) | `commands/adhd.zsh:32` |
| `inbox --count` (bare integer) | `commands/adhd.zsh:76` |
| `trail --limit <n>` (newest-N) | `commands/capture.zsh:82` |

atlas also fixed `project list --status=<s>` to resolve status from metadata (previously matched 0 scanned projects — silently breaking flow-cli's contracted `project list --status=active --format=names`).

Two flow-cli calls target atlas commands that **do not exist**, and the `at` dispatcher's user-facing help/man/completions don't reflect any of the above. Per flow-cli's own standard (`docs/internal/conventions/code/ZSH-COMMANDS-HELP.md`), every dispatcher needs **help fn + man page + completions + version-sync test + docs** — the `at` dispatcher is missing completions and has stale help/man.

## Scope — six items

### 1. `docs/ATLAS-CONTRACT.md` → v1.1.0
- Replace the "Output Format Specifications" section (currently implies `--format` is universal) with a **per-command** matrix: `--format <table|json|names>` on `project list`/`project show` (show also `shell`); `--format <table|json|text|md>` on `stats`; `--format <ical|json>` on `session export`; `--json` on `plan`; **NEW** `--format <table|json>` on `session status`.
- Document the 5 new flags in the command tables; add `session status` (currently absent on both sides).
- Add a Version Compatibility row: flow-cli v7.10.x ↔ atlas v0.9.3.
- Bump header to `**Version:** 1.1.0`.

### 2. `commands/doctor.zsh` — OOS-1: fix `atlas config get backend`
`atlas config get` does not exist. atlas provides `atlas config show` and `atlas config prefs get <path>`. Replace the backend-detection call accordingly (prefer parsing `atlas config show`). Keep the check non-fatal (diagnostic).

### 3. `commands/doctor.zsh` — OOS-2: fix `atlas mcp status`
There is no `atlas mcp` subcommand; the MCP server is the separate binary `atlas-mcp` (atlas `package.json` `bin`). Replace `atlas mcp status` with a PATH probe (`command -v atlas-mcp`). Keep non-fatal.

### 4. `lib/atlas-bridge.zsh` — refresh `_at_help()` (currently ~lines 926–996)
Add the 5 new flags to the existing box/color/grouped help, in the right sections:
- SESSION → `at session status --format json` (machine-readable)
- CAPTURE → `at inbox --count`
- CONTEXT → `at trail --limit N`
- PROJECT → `at project list --count`, `at project list --suggest`
Preserve the existing format (color vars from `lib/core.zsh`, box borders, MOST COMMON / SESSION / CAPTURE / CONTEXT / PROJECT grouping, fallback note).

### 5. `man/man1/at.1` — document the new flags
Add the flags to the relevant command entries and add flag-usage EXAMPLES (currently none show flags). Keep `.TH` version in sync with `FLOW_VERSION` (7.10.1) so `tests/test-manpage-version-sync.zsh` stays green.

### 6. `completions/_at` — NEW (hard standard violation: missing)
Create a ZSH completion for the `at` dispatcher: subcommands (session, catch, inbox, triage, where, crumb, trail, focus, stats, plan, park, unpark, parked, dash, project) and the new flags (`--format`, `--count`, `--suggest`, `--limit`, `--days`, `--project`). Match the structure of an existing completion (e.g. `completions/_dash`, `completions/_work`). Wire it in per the completion-loading convention.

## Acceptance Criteria

- [ ] `at --help` (and `at <sub> --help` where applicable) lists all 5 new flags; format unchanged.
- [ ] `man at` documents the new flags and shows at least one flag-based example.
- [ ] `completions/_at` exists and tab-completes `at` subcommands + flags.
- [ ] `doctor` backend + MCP checks use existing atlas surfaces (`config show`, `atlas-mcp` binary) and are non-fatal.
- [ ] `docs/ATLAS-CONTRACT.md` is v1.1.0 with the corrected per-command `--format` matrix + 5 flags + `session status`.
- [ ] `tests/test-manpage-version-sync.zsh` passes (at.1 `.TH` == FLOW_VERSION).
- [ ] `tests/run-all.sh` green; `source flow.plugin.zsh` clean (one expected interactive `e2e-em-dispatcher` timeout acceptable).

## Standard conformance (before → after)

| Component | Before | After |
|---|---|---|
| `_at_help()` | ⚠️ stale (no new flags) | ✅ current |
| `man/man1/at.1` | ⚠️ stale (no flag docs/examples) | ✅ current |
| `completions/_at` | ❌ missing | ✅ created |
| version-sync test | ✅ passing | ✅ still passing |
| `ATLAS-CONTRACT.md` | ⚠️ over-promises `--format` | ✅ v1.1.0 accurate |
| `doctor.zsh` calls | ❌ 2 nonexistent calls | ✅ corrected |

## Branch model & workflow

flow-cli is **multi-branch** (`main` ← `dev` ← `feature/*`). Implement on `feature/atlas-surface-standard` off `dev`; PR → `dev` (draft). Conventional commits. Do not push to `dev`/`main` directly.

## Open Questions

1. Completion depth: full subcommand+flag completion, or subcommands only for v1? (Recommend: subcommands + the 6 common flags.)
2. Should `at session status --format json` be surfaced in MOST COMMON, or only SESSION? (Recommend: SESSION only — it's a scripting aid, not a daily verb.)

## History

- 2026-06-14 — Initial draft. Consolidates the flow-cli-side work surfaced by the atlas↔flow-cli integration audit: contract bump, 2 wrong-call fixes, and `at`-dispatcher help/man/completions conformance for the atlas v0.9.3 flags.
