# SPEC: `flow claude` Subcommand

**Status:** Draft  
**Created:** 2026-06-19  
**Scope:** flow-cli — new `claude` top-level subcommand for Claude Code environment health

---

## Problem

Claude Code settings live in two places that can silently diverge:

- `~/.claude/settings.json` env block (canonical — CC reads this directly)
- `~/.config/zsh/.zshrc` export (fallback for issue #63186 where settings.json env block is silently ignored)

No tool currently checks parity, hook health, memory index drift, or CLAUDE.md length. These failures surface as confusing behavior (wrong compaction threshold, missing PostCompact context, stale memory index), not as errors.

---

## Command Surface

New `flow claude` top-level subcommand.

**Implementation files:**
- `commands/claude.zsh` — new file
- `flow.zsh` — add `claude` dispatch case

### Subcommands

```
flow claude check      # run all checks (alias: flow claude doctor)
flow claude check --fix  # run checks + auto-repair safe mismatches
```

---

## Checks

| ID | Name | Logic | Severity | Fix-able |
|----|------|-------|----------|----------|
| C1 | Settings parity | Parse `~/.claude/settings.json` `.env` block; compare each key against matching `export KEY=VAL` in zshrc. Flag when zshrc diverges from settings.json (settings.json is canonical). | WARN | Yes — `--fix` updates zshrc export to match |
| C2 | Hook health | `~/.claude/hooks/post-compact-reinject.sh` exists, is executable, passes `shellcheck`. | ERROR | No — report path and symptom only |
| C3 | Memory index drift | Count `.md` files in `~/.claude/projects/*/memory/` directories; compare vs entry count in each `MEMORY.md` index. | WARN | No — report mismatched dirs |
| C4 | CLAUDE.md length | `wc -l ~/.claude/CLAUDE.md` — warn if > 100 lines (project rule: trim before adding). | WARN | No — report with rule reminder |
| C5 | Shell env parity | Verify `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` is exported in the current shell session (proxy for env reaching Claude Work/Chat Electron apps launched from this shell). | INFO | No — informational only |
| C6 | Output token limit | `CLAUDE_CODE_MAX_OUTPUT_TOKENS` is set in settings.json `.env` block or zshrc and its value exceeds 8192 (the default cap that triggers "response exceeded 8192 output token maximum" errors). Recommended: 32000. | WARN | Yes — `--fix` adds/updates `export CLAUDE_CODE_MAX_OUTPUT_TOKENS=32000` in zshrc |

---

## `--fix` Behavior

Safe writes only. `--fix` never touches `settings.json`.

**What it fixes:**
- C1: String-replace the `export KEY=VAL` line in zshrc to match the value in settings.json. Uses exact line match, not regex glob.
- C6: If `CLAUDE_CODE_MAX_OUTPUT_TOKENS` is missing from zshrc, append `export CLAUDE_CODE_MAX_OUTPUT_TOKENS=32000`. If present but ≤ 8192, update the value to 32000.

**What it never touches:**
- `~/.claude/settings.json` (complex nested JSON — manual edit)
- Hook scripts (logic changes, not data)
- MEMORY.md (structural document)

---

## Source of Truth

`settings.json` env block is canonical for all Claude Code env vars.  
zshrc export is a fallback for session-level env visibility only.

When they diverge, `--fix` brings zshrc into alignment with settings.json — not the reverse.

---

## Out of Scope

- craft rules (branch-guard, pre-commit hooks) — stay in craft
- Claude Work/Chat config APIs (none exist; C5 is the best-effort proxy)
- settings.json structural validation (not env-var domain)
- Plugin or MCP server health (separate concern)

---

## Implementation Notes

- Parse settings.json with `jq` (already a flow-cli dependency)
- zshrc path: `$FLOW_ZSH_ROOT/.zshrc` or detect from `$ZDOTDIR`
- `shellcheck` optional dependency — degrade gracefully if absent (skip C2 shellcheck sub-check, report existence + executable only)
- Exit codes: 0 = all pass, 1 = any ERROR, 2 = any WARN (no ERROR)

---

## Dispatch Addition (flow.zsh)

```zsh
claude) flow_claude "$@" ;;
```

---

## Example Output

```
flow claude check

✓ Settings parity         AUTOCOMPACT=65 matches in settings.json + zshrc
✗ Hook health             post-compact-reinject.sh: shellcheck failed (line 12)
⚠ Memory index drift      ~/.claude/projects/-Users-dt--config/memory/: 8 files, 6 MEMORY.md entries
✓ CLAUDE.md length        148 lines — exceeds 100-line rule (trim before adding)
ℹ Shell env parity        CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65 exported in current session
⚠ Output token limit      CLAUDE_CODE_MAX_OUTPUT_TOKENS not set — default 8192 cap may truncate responses (run --fix to set 32000)
```
