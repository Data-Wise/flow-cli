# flow claude

> **Claude Code environment health checks — detect and fix common configuration drift**

The `flow claude` command inspects the Claude Code environment for settings that silently cause problems: env var mismatches between `settings.json` and your shell, hook failures, memory index drift, and output token limits that truncate long responses mid-run.

---

## Synopsis

```bash
flow claude check           # Run all checks, print report, exit with status
flow claude check --fix     # Run checks + auto-repair safe mismatches
flow claude doctor          # Alias for check
flow claude doctor --fix    # Alias for check --fix
```

---

## Checks

| ID | Name | What it checks | Severity |
|----|------|----------------|----------|
| C1 | Settings parity | Each key in `~/.claude/settings.json` `.env` block has a matching `export KEY=VALUE` in zshrc | WARN |
| C2 | Hook health | `~/.claude/hooks/post-compact-reinject.sh` exists, is executable, passes `shellcheck` | ERROR |
| C3 | Memory index drift | `.md` file count in each `memory/` dir vs entry count in its `MEMORY.md` | WARN |
| C4 | CLAUDE.md length | `~/.claude/CLAUDE.md` line count ≤ 100 (project rule: trim before adding) | WARN |
| C5 | Shell env parity | `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` exported in current shell (proxy for env reaching Electron apps) | INFO |
| C6 | Output token limit | `CLAUDE_CODE_MAX_OUTPUT_TOKENS` set in settings.json or zshrc and value > 8192 | WARN |

---

## Output Format

```
flow claude check

✓ Settings parity         AUTOCOMPACT=65 matches in settings.json + zshrc
✗ Hook health             post-compact-reinject.sh: shellcheck failed (line 12)
⚠ Memory index drift      ~/.claude/projects/-Users-dt--config/memory/: 8 files, 6 MEMORY.md entries
⚠ CLAUDE.md length        148 lines — exceeds 100-line rule (trim before adding)
ℹ Shell env parity        CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65 exported in current session
⚠ Output token limit      CLAUDE_CODE_MAX_OUTPUT_TOKENS not set — default 8192 cap may truncate responses (run --fix to set 32000)
```

---

## `--fix` Mode

`--fix` writes to zshrc only. It never modifies `settings.json` (complex nested JSON — manual edit).

| Check | What `--fix` does |
|-------|------------------|
| C1 | Updates the `export KEY=VALUE` line in zshrc to match the value in settings.json |
| C6 | Appends `export CLAUDE_CODE_MAX_OUTPUT_TOKENS=32000` if missing, or updates the value if ≤ 8192 |
| C2, C3, C4, C5 | Reported only — no auto-repair |

**Why settings.json is canonical:** It's what Claude Code reads directly. zshrc exports are a belt-and-suspenders fallback for [issue #63186](https://github.com/anthropics/claude-code/issues/63186) where the env block is silently ignored in some launch paths. `--fix` brings zshrc into alignment with settings.json, never the reverse.

---

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All checks pass |
| `1` | One or more ERROR checks failed |
| `2` | One or more WARN checks (no ERRORs) |

Use the exit code in scripts:

```bash
flow claude check || echo "Environment issues detected"
```

---

## Why Each Check Matters

**C1 — Settings parity:** `settings.json` env block is silently ignored in some Claude Code launch paths. If zshrc exports diverge, the active value is unpredictable depending on how Claude was launched.

**C2 — Hook health:** `post-compact-reinject.sh` runs after every context compaction and reinjects system context (memory, project state). A broken hook means that context is lost mid-session — silently.

**C3 — Memory index drift:** `MEMORY.md` is the index Claude reads to decide which memory files to load. If files exist that aren't indexed, they're invisible to Claude. If MEMORY.md lists files that don't exist, the index rots and misleads.

**C4 — CLAUDE.md length:** The global rule caps `~/.claude/CLAUDE.md` at 100 lines. Beyond that it starts consuming context on every turn. Every line over 100 is paying a per-turn tax.

**C5 — Shell env parity:** Claude Code Electron apps inherit env from the shell that launched them, not from `settings.json`. This check verifies that `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` is actually in the shell's env — a proxy for "will Electron-launched Claude see my settings?"

**C6 — Output token limit:** Claude Code defaults to 8192 output tokens per response. Long file writes, comprehensive diffs, or detailed analysis can exceed this, interrupting the session with `API Error: Claude's response exceeded the 8192 output token maximum`. Setting `CLAUDE_CODE_MAX_OUTPUT_TOKENS=32000` raises the ceiling.

---

## Manual Fix for C2 (Hook Health)

The hook file must exist, be executable, and pass `shellcheck`:

```bash
# Check it exists and is executable
ls -la ~/.claude/hooks/post-compact-reinject.sh

# Make executable
chmod +x ~/.claude/hooks/post-compact-reinject.sh

# Run shellcheck manually
shellcheck ~/.claude/hooks/post-compact-reinject.sh
```

---

## Manual Fix for C6 (Output Token Limit)

`--fix` handles zshrc. For settings.json, edit manually:

```jsonc
// ~/.claude/settings.json
{
  "env": {
    "CLAUDE_CODE_MAX_OUTPUT_TOKENS": "32000"
  }
}
```

Recommended value: `32000`. Maximum for Sonnet 4.6: ~64000.

---

## Dependencies

| Tool | Required by | Behavior if absent |
|------|-------------|-------------------|
| `jq` | C1, C6 (settings.json parsing) | Skips JSON checks, reports "jq required" |
| `shellcheck` | C2 (hook validation) | Reports existence + executable only, skips lint |

---

## See Also

- [Troubleshooting: Claude Code Environment](../troubleshooting/CLAUDE-CODE-ENVIRONMENT.md) — Shell snapshot limitations and workarounds
- [doctor](doctor.md) — System-wide health check (tools, dependencies, Atlas)
- [Master Dispatcher Guide](../reference/MASTER-DISPATCHER-GUIDE.md) — All dispatchers

---

**Last Updated:** 2026-06-19
**Version:** v7.12.0
**Status:** Implemented in `commands/claude.zsh`
