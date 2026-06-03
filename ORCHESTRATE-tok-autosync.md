# ORCHESTRATE: tok Auto-Sync to GitHub Actions Secrets

> **Spec:** `docs/specs/SPEC-tok-autosync-2026-06-03.md`
> **Branch:** `feature/tok-autosync` (off `dev`)
> **Worktree:** `~/.git-worktrees/flow-cli/tok-autosync`
> **Run this in a NEW `claude` session started inside the worktree.**

---

## How to implement this with modern Claude Code facilities

This plan is built around the skills/agents you have installed. Use them
in this order — each maps to a phase below.

| Facility | When | Why it fits here |
|---|---|---|
| **`superpowers:test-driven-development` skill** | Every code task | Pure-ZSH dispatcher logic with mockable `gh`/config — ideal RED→GREEN→REFACTOR. Write the `tests/test-tok-sync.zsh` assertion first, watch it fail, then implement. |
| **`superpowers:subagent-driven-development` skill** | Phases 2–4 | Dispatch one subagent per *file-scoped* task so they don't collide. The parent (you) stays the integrator. |
| **`Explore` agent** | Phase 0 | Read-only: confirm exact helper names (`_flow_log_*`, `_dotf_secret_backend`, vault read path) before writing. Cheap, fast. |
| **`Plan` agent** | Optional, Phase 0 | If task ordering feels unclear, have it produce a step plan against the spec. Usually not needed — this file already is the plan. |
| **`/code-review` or `feature-dev:code-reviewer` agent** | After Phase 4 | Review the diff for the security invariants (stdin-only secrets, no `source`, allowlist). |
| **`superpowers:verification-before-completion` skill** | Before PR | Forces you to actually run `./tests/run-all.sh` + `source flow.plugin.zsh` and report real output, not assume. |
| **`superpowers:requesting-code-review` skill** | Before PR | Structured self-review against acceptance criteria. |
| **Git worktree** (already created) | — | Isolates this feature on `feature/tok-autosync`; no conflict with `dev`. |

**Anti-pattern to avoid:** do NOT ask one subagent to "implement the
whole feature." Split by file scope (below). Subagents are one-shot and
can't pause for your decisions — keep integration + any judgment calls
in the parent session.

**Recommended loop per task:** invoke TDD skill → write failing test →
implement minimal code → run that one test file → refactor → move on.

---

## File scope (split for subagent isolation)

| # | File | New/Edit | Depends on |
|---|---|---|---|
| 1 | `lib/tok-sync.zsh` | NEW | none (foundation) |
| 2 | `tests/test-tok-sync.zsh` | NEW | #1 (tests it) |
| 3 | `lib/dispatchers/tok-dispatcher.zsh` | EDIT | #1 (calls it) |
| 4 | `flow.plugin.zsh` | EDIT | #1 (must source new lib) |
| 5 | docs (`MASTER-DISPATCHER-GUIDE.md`, tok help text, cookbook) | EDIT | #3 |

Wave order: **1 → 2 (TDD, interleaved with 1) → 3 → 4 → 5.**

---

## Phase 0 — Recon (Explore agent, read-only)

Confirm before writing:
- [ ] Vault read path for a token value (how `sec <name>` / `bw get` is
      invoked in `_tok_refresh`/`_tok_sync_gh`).
- [ ] Logging helpers + `FLOW_COLORS` usage conventions.
- [ ] How other libs are sourced in `flow.plugin.zsh` (ordering, guard
      pattern — note the `typeset -gr` readonly-scope gotcha).
- [ ] Existing `tok sync` case block (lines ~54–59) to extend safely.

## Phase 1 — `lib/tok-sync.zsh` (foundation, TDD)

- [ ] Load guard: `typeset -g _TOK_SYNC_LOADED=1`. Any module constants
      use `typeset -gr` (NOT bare `readonly` — function-scope gotcha).
- [ ] `_tok_sync_conf_path` → `${FLOW_TOK_SYNC_CONF:-$HOME/.config/flow/tok-sync.conf}`.
- [ ] `_tok_sync_load_targets <name>`: `while read -r n secret repo flag`;
      skip `#`/blank; validate `secret`+`repo` against
      `^[A-Za-z0-9._/-]+$` (warn+skip on fail); emit
      `secret<TAB>repo<TAB>flag` for matching `n`.
- [ ] `_tok_sync_resolve_value <name>`: read value from vault.
- [ ] `_tok_sync_push <name> [value]`:
      - guard gh installed + `gh auth status`; guard config exists.
      - load targets; if none → info no-op, return 0.
      - partition `oidc` rows → print Trusted Publishing note, no push.
      - if no push rows → return 0.
      - list `repo : secret` targets; **confirm once (default N)**.
      - per push row: `printf '%s' "$value" | gh secret set "$secret" --repo "$repo"`.
        **stdin only — never `--body`.** Collect ✓/✗.
      - on mid-failure: continue, summarize at end (per spec Open Q2).

## Phase 2 — `tests/test-tok-sync.zsh` (TDD, write alongside Phase 1)

Use `tests/test-framework.zsh` (`create_mock`, assertions, subshell
isolation). Mock `gh` and point `FLOW_TOK_SYNC_CONF` at a fixture.
- [ ] targets parsing incl. comments/blank lines
- [ ] allowlist rejection (bad repo/secret skipped)
- [ ] confirm-yes pushes; confirm-no writes nothing
- [ ] oidc row skipped + note printed, never pushed
- [ ] missing-gh guard → no-op, non-fatal
- [ ] empty value / zero targets → no-op
- [ ] `--no-sync` / `FLOW_TOK_AUTOSYNC=0` bypass

## Phase 3 — `tok-dispatcher.zsh` wiring

- [ ] Source/ensure `tok-sync.zsh` available.
- [ ] Extend `sync` case: `push <name>`, `repos <name>`; keep `gh`.
- [ ] `repos` = dry inspect (targets + OIDC notes, no writes).
- [ ] Post-store hook in `_tok_github`, `_tok_npm`, `_tok_pypi`,
      `_tok_rotate`, `_tok_refresh`: call `_tok_sync_push "<name>"`
      after successful store, gated by `--no-sync` flag +
      `FLOW_TOK_AUTOSYNC` (default on).
- [ ] Parse/strip `--no-sync` in `tok()` arg loop.
- [ ] Update `_tok_help` with the new `sync` subcommands.

## Phase 4 — `flow.plugin.zsh`

- [ ] Source `lib/tok-sync.zsh` in correct order (after core, near tok).

## Phase 5 — Docs

- [ ] `docs/reference/MASTER-DISPATCHER-GUIDE.md`: `tok sync push/repos`.
- [ ] Cookbook/help entry: chezmoi config format + OIDC note.
- [ ] Seed example `tok-sync.conf` (4 github-app callers incl. nexus-cli).

## Verification (before PR — use verification-before-completion skill)

- [ ] `./tests/run-all.sh` — report real pass count.
- [ ] `source flow.plugin.zsh` clean.
- [ ] Manual: `tok sync repos github-app` shows targets (no writes).
- [ ] `feature-dev:code-reviewer` agent on the diff: confirm stdin-only
      secrets, no `source` of config, allowlist enforced.
- [ ] Update test count refs (CLAUDE.md, TESTING.md, .STATUS) per the
      test-count-propagation checklist.

## Integration

- [ ] `git fetch origin dev && git rebase origin/dev`
- [ ] `./tests/run-all.sh`
- [ ] `gh pr create --base dev`
- [ ] **Do not self-merge** — user performs merges. Delete this
      ORCHESTRATE file as part of the merge-to-dev cleanup.
