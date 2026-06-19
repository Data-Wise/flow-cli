# flow claude

> **Claude Code environment health checks — detect and fix common configuration drift**

The `flow claude` command inspects the Claude Code environment for settings that silently cause problems: env var mismatches between `settings.json` and your shell, hook failures, memory index drift, and output token limits that truncate long responses mid-run.

---

## Synopsis

```bash
flow claude check               # Run all checks, print report, exit with status
flow claude check --fix         # Run checks + auto-repair safe mismatches
flow claude doctor              # Alias for check
flow claude doctor --fix        # Alias for check --fix
flow claude watch               # Start background health daemon (notifies on change)
flow claude watch --interval N  # Poll every N seconds (default: 60)
flow claude watch --stop        # Stop the daemon
flow claude watch --status      # Show daemon state and last check result
```

---

## Checks

| ID | Name | What it checks | Severity |
|----|------|----------------|----------|
| C1 | Settings parity | Each key in `~/.claude/settings.json` `.env` block has a matching `export KEY=VALUE` in zshrc | WARN |
| C2 | Hook health | `~/.claude/hooks/post-compact-reinject.sh` exists, is executable, passes `shellcheck` | ERROR |
| C3 | Memory index drift | `.md` file count in each `memory/` dir vs entry count in its `MEMORY.md` | WARN |
| C4 | CLAUDE.md length | >100 lines → WARN (approaching 180-line limit); >180 lines → ERROR (hard limit exceeded) | WARN/ERROR |
| C5 | Shell env parity | `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` exported in current shell (proxy for env reaching Electron apps) | INFO |
| C6 | Output token limit | `CLAUDE_CODE_MAX_OUTPUT_TOKENS` set in settings.json or zshrc and value > 8192 | WARN |
| C7 | Per-project CLAUDE.md | Scans `$FLOW_CLAUDE_PROJECTS_ROOT` (depth 4); warns on >180 lines or stale version refs | WARN |
| C8 | Orphaned memory dirs | Decodes each memory slug back to a filesystem path; warns if the project no longer exists | WARN |
| C9 | Rules drift | Every `~/.claude/rules/*.md` stem must appear in main `~/.claude/CLAUDE.md` | WARN |
| C10 | Missing hook files | Parses `settings.json` hook commands; errors on absent absolute-path scripts | ERROR |
| C11 | Plugin health | Checks `~/.claude/plugins/*/plugin.json` exists and is valid JSON (skips `cache/`) | WARN |

---

## Output Format

```
flow claude check

✓ Settings parity          AUTOCOMPACT=65 matches in settings.json + zshrc
✗ Hook health              post-compact-reinject.sh: shellcheck failed (line 12)
⚠ Memory index drift       ~/.claude/projects/-Users-dt--config/memory/: 8 files, 6 MEMORY.md entries
⚠ CLAUDE.md length         148 lines — approaching 180-line hard limit (trim before adding)
ℹ Shell env parity         CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65 exported in current session
⚠ Output token limit       CLAUDE_CODE_MAX_OUTPUT_TOKENS not set — default 8192 cap may truncate responses (run --fix to set 32000)
⚠ Per-project CLAUDE.md   ~/projects/my-app/CLAUDE.md: 205 lines — exceeds 180-line limit
⚠ Orphaned memory dirs     slug 'users-dt-projects-old-app': /Users/dt/projects/old-app not found
⚠ Rules drift              ~/.claude/rules/my-rule.md not referenced in ~/.claude/CLAUDE.md
✗ Missing hook files       settings.json references missing script: /Users/dt/.claude/hooks/on-start.sh
⚠ Plugin health            ~/.claude/plugins/myplugin: plugin.json missing or invalid JSON
```

---

## `--fix` Mode

`--fix` writes to zshrc only. It never modifies `settings.json` (complex nested JSON — manual edit).

| Check | What `--fix` does |
|-------|------------------|
| C1 | Updates the `export KEY=VALUE` line in zshrc to match the value in settings.json |
| C6 | Appends `export CLAUDE_CODE_MAX_OUTPUT_TOKENS=32000` if missing, or updates the value if ≤ 8192 |
| C2, C3, C4, C5, C7–C11 | Reported only — no auto-repair |

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

**C4 — CLAUDE.md length:** The global rule caps `~/.claude/CLAUDE.md` at 180 lines (hard limit) with a warning at 100 lines (approaching limit). Beyond 100 lines it starts consuming meaningful context on every turn — every line over that threshold is a per-turn tax.

**C5 — Shell env parity:** Claude Code Electron apps inherit env from the shell that launched them, not from `settings.json`. This check verifies that `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` is actually in the shell's env — a proxy for "will Electron-launched Claude see my settings?"

**C6 — Output token limit:** Claude Code defaults to 8192 output tokens per response. Long file writes, comprehensive diffs, or detailed analysis can exceed this, interrupting the session with `API Error: Claude's response exceeded the 8192 output token maximum`. Setting `CLAUDE_CODE_MAX_OUTPUT_TOKENS=32000` raises the ceiling.

**C7 — Per-project CLAUDE.md:** Project-level `CLAUDE.md` files load into context for every session in that project. An oversized or stale project CLAUDE.md has the same per-turn cost as a bloated global one. C7 scans `$FLOW_CLAUDE_PROJECTS_ROOT` (up to depth 4) and flags any project CLAUDE.md that exceeds 180 lines or contains stale version references.

**C8 — Orphaned memory dirs:** The memory system accumulates slug-encoded project entries under `~/.claude/projects/`. If the underlying project directory no longer exists, the slug is dead weight — context space spent on a project that's gone. C8 decodes each slug back to a filesystem path and warns when the path is missing.

**C9 — Rules drift:** `~/.claude/rules/*.md` files are only active when referenced from the global `CLAUDE.md`. A rule file that isn't listed there is silently ignored — meaning new rules never take effect without this link. C9 checks that every stem in `rules/` appears in `CLAUDE.md`.

**C10 — Missing hook files:** `settings.json` can declare hook scripts via absolute paths. If those scripts are absent on disk, Claude Code silently skips them — missing hooks that were expected to fire. C10 parses the hook declarations and errors if any referenced script doesn't exist.

**C11 — Plugin health:** Plugins require a valid `plugin.json` manifest to be loaded. An invalid or missing manifest means the plugin is silently ignored. C11 validates each installed plugin's manifest before a session starts (skipping the `cache/` subdirectory).

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

## Watch Daemon

`flow claude watch` runs `flow claude check` on a schedule in the background and sends
a desktop notification (via `terminal-notifier`) when health state changes.

```bash
flow claude watch               # Start daemon (default: 60s interval)
flow claude watch --interval 30 # Poll every 30 seconds
flow claude watch --stop        # Stop the daemon
flow claude watch --status      # Print daemon PID, uptime, and last check result
```

**State files:**

| File | Purpose |
|------|---------|
| `~/.flow/claude-watch.pid` | Daemon PID (absent when stopped) |
| `~/.flow/claude-health-state.json` | Last check result + severity |

The daemon only notifies on state **transitions** (healthy → degraded, or degraded →
healthy), not on every poll. This avoids notification spam when the environment is stable.

**Requires:** `terminal-notifier` (`brew install terminal-notifier`). The daemon starts
but skips desktop notifications if `terminal-notifier` is absent.

---

## Dependencies

| Tool | Required by | Behavior if absent |
|------|-------------|-------------------|
| `jq` | C1, C6, C10 (JSON parsing) | Skips JSON checks, reports "jq required" |
| `shellcheck` | C2 (hook validation) | Reports existence + executable only, skips lint |
| `terminal-notifier` | watch daemon | Daemon runs; desktop notifications silently skipped |

---

## See Also

- [Troubleshooting: Claude Code Environment](../troubleshooting/CLAUDE-CODE-ENVIRONMENT.md) — Shell snapshot limitations and workarounds
- [doctor](doctor.md) — System-wide health check (tools, dependencies, Atlas)
- [Master Dispatcher Guide](../reference/MASTER-DISPATCHER-GUIDE.md) — All dispatchers

---

**Last Updated:** 2026-06-19
**Version:** v7.13.0
**Status:** Implemented in `commands/claude.zsh`
