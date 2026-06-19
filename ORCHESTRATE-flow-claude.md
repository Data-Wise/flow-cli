# ORCHESTRATE: `flow claude` Subcommand

**Branch:** `feature/flow-claude`  
**Worktree:** `~/.git-worktrees/flow-cli/feature-flow-claude`  
**Spec:** `docs/specs/SPEC-flow-claude-subcommand.md`  
**Base:** dev (at af557cd1)

---

## Task List

### Wave 1 — New command file

- [ ] Create `commands/claude.zsh`
  - `flow_claude()` dispatcher: routes `check`/`doctor` subcommands, prints help for unknown
  - `_flow_claude_check()`: runs C1–C6 in order, collects results, prints summary table, returns exit code (0/1/2)
  - `_flow_claude_fix()`: called when `--fix` passed, repairs C1 (zshrc export alignment) and C6 (token limit)
  - C1: parse `~/.claude/settings.json` with `jq .env`, compare each key against zshrc exports
  - C2: check `~/.claude/hooks/post-compact-reinject.sh` exists + executable + shellcheck (degrade if shellcheck absent)
  - C3: count `.md` files per `~/.claude/projects/*/memory/` dir, compare vs MEMORY.md line count (entries only — lines starting with `- [`)
  - C4: `wc -l ~/.claude/CLAUDE.md`, warn if > 100
  - C5: `[[ -n "${CLAUDE_AUTOCOMPACT_PCT_OVERRIDE}" ]]` — info-only
  - C6: check `CLAUDE_CODE_MAX_OUTPUT_TOKENS` in settings.json `.env` block OR zshrc, value must be > 8192; WARN if missing or ≤ 8192; `--fix` appends/updates to 32000 in zshrc
  - Use `_flow_log_*` helpers from `lib/core.zsh` for output colors
  - Exit codes: 0 = all pass, 1 = any ERROR, 2 = any WARN (no ERROR)

### Wave 2 — Dispatch wiring

- [ ] Edit `flow.plugin.zsh` (or `flow.zsh` — check which file has the main dispatch `case`): add `claude) flow_claude "$@" ;;`
  - Source `commands/claude.zsh` in the plugin load block

### Wave 3 — Completions

- [ ] Add `completions/_flow_claude` (or extend `completions/_flow`):
  - `check`/`doctor` subcommands
  - `--fix` flag for `check`/`doctor`

### Wave 4 — Man page

- [ ] Add `man/man1/flow-claude.1` using existing man pages as template
  - Sections: NAME, SYNOPSIS, DESCRIPTION, SUBCOMMANDS, OPTIONS, EXIT STATUS, EXAMPLES
  - `.TH` version line: `v7.12.0` (next release)

### Wave 5 — Tests

- [ ] Add `tests/test-flow-claude.zsh`
  - Test each check (C1–C6) with mocked inputs
  - Test `--fix` writes correct zshrc line (mock zshrc in temp dir) for C1 and C6
  - Test C6: WARN when var missing, WARN when ≤ 8192, PASS when > 8192
  - Test C6 `--fix`: appends export when missing, updates value when ≤ 8192
  - Test exit codes: 0 all-pass, 1 on ERROR, 2 on WARN-only
  - Test graceful degrade when `shellcheck` absent (C2)
  - Test graceful degrade when `jq` absent (C1, C6)

### Wave 6 — Docs

- [ ] Update `docs/help/QUICK-REFERENCE.md`: add `flow claude check` entry
- [ ] Update `docs/reference/MASTER-DISPATCHER-GUIDE.md` or equivalent: add `claude` section
- [ ] Update `CLAUDE.md` command count if it tracks it

---

## Key Implementation Details

- **zshrc path:** `${ZDOTDIR:-$HOME}/.zshrc` or `$FLOW_ZSH_ROOT/.zshrc` — check which the project uses; `FLOW_ZSH_ROOT` is `~/.config/zsh` per CLAUDE.md
- **settings.json canonical:** `--fix` always writes zshrc → match settings.json, never the reverse
- **`--fix` safety:** exact line match (`export KEY=VALUE`) — no regex glob replacement; use `sed` with anchored pattern
- **jq dependency:** already used in flow-cli; degrade if absent (skip C1 JSON parse, report "jq required")
- **shellcheck:** optional; C2 reports existence + executable even without it
- **Output format:** match example in spec — `✓`/`✗`/`⚠`/`ℹ` prefix, aligned columns

---

## Verification

```zsh
# After each wave:
source flow.plugin.zsh
flow claude check
flow claude doctor  # alias

# Fix mode:
flow claude check --fix

# Tests:
./tests/run-all.sh
# Expect: previous pass count + new test-flow-claude suite passing
```
