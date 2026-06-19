---
tags:
  - tutorial
  - configuration
  - claude-code
  - diagnostics
---

# Tutorial 49: Diagnosing Claude Code Environment with `flow claude check`

> **What you'll learn:** how to catch the six most common Claude Code configuration
> problems before they silently derail a session — and how to auto-fix the ones
> that are safe to fix.
>
> **Time:** ~10 minutes | **Level:** Beginner | **v7.12.0**

**Why this matters:** Claude Code configuration lives in two places (`settings.json`
and your shell), and they drift. Hook files break. Memory indexes go stale. The
default 8192-token output cap truncates long responses mid-run. None of these fail
loudly — they just produce confusing behavior. `flow claude check` finds them all in
one pass.

---

## Prerequisites

- [ ] flow-cli installed (`brew install data-wise/tap/flow-cli`)
- [ ] Claude Code installed (`claude --version`)
- [ ] `jq` installed (`brew install jq`) — used for C1/C6 JSON parsing

**Verify:**

```bash
flow claude check --help
# Expected: help text showing check / --fix / exit codes
```

---

## What You'll Learn

1. Run `flow claude check` and read the report
2. Understand each of the six checks (C1–C6)
3. Use `--fix` to auto-repair safe mismatches
4. Know which failures require manual intervention

---

## Step 1: Run the Check

```bash
flow claude check
```

You'll see a six-line report. Each line is one check:

```
✓ Settings parity         AUTOCOMPACT=65 matches in settings.json + zshrc
✗ Hook health             post-compact-reinject.sh: shellcheck failed (line 12)
⚠ Memory index drift      ~/.claude/projects/-Users-dt--config/memory/: 8 files, 6 MEMORY.md entries
⚠ CLAUDE.md length        148 lines — exceeds 100-line rule (trim before adding)
ℹ Shell env parity        CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65 exported in current session
⚠ Output token limit      CLAUDE_CODE_MAX_OUTPUT_TOKENS not set — default 8192 cap may truncate responses (run --fix to set 32000)
```

**Reading the symbols:**

| Symbol | Severity | Meaning |
|--------|----------|---------|
| `✓` | PASS | Check passed |
| `✗` | ERROR | Something is broken — exit code 1 |
| `⚠` | WARN | Potential problem — exit code 2 |
| `ℹ` | INFO | Informational — no effect on exit code |

---

## Step 2: Understand the Six Checks

### C1 — Settings Parity (WARN)

`~/.claude/settings.json` has an `"env"` block that's the canonical source for
Claude Code environment variables. But a [known bug](https://github.com/anthropics/claude-code/issues/63186)
causes that block to be silently ignored in some launch paths (Electron apps launched
from a terminal that doesn't inherit the env).

The fix is to also export the same values in `~/.config/zsh/.zshrc`. C1 checks that
both locations agree.

**Example failure:**

```
⚠ Settings parity   CLAUDE_AUTOCOMPACT_PCT_OVERRIDE: settings.json=65, zshrc=missing
```

### C2 — Hook Health (ERROR)

`~/.claude/hooks/post-compact-reinject.sh` runs after every context compaction. It
reinjects your memory files, project state, and system context back into the
conversation — so Claude doesn't lose track of what it was doing mid-session.

If this hook is missing, not executable, or has a shell error, compaction silently
drops your context.

**Example failure:**

```
✗ Hook health   post-compact-reinject.sh: not executable
```

### C3 — Memory Index Drift (WARN)

Claude reads `MEMORY.md` to decide which memory files to load at the start of a
conversation. If a `.md` file exists in a `memory/` directory but isn't listed in
`MEMORY.md`, Claude never sees it. If `MEMORY.md` lists files that don't exist, the
index rots.

**Example failure:**

```
⚠ Memory index drift   memory/: 8 .md files, 6 MEMORY.md entries (2 unindexed)
```

### C4 — CLAUDE.md Length (WARN)

The global rule caps `~/.claude/CLAUDE.md` at 100 lines. Every line loads into
context on every turn — so a bloated CLAUDE.md is a per-turn tax you pay forever.

**Example failure:**

```
⚠ CLAUDE.md length   148 lines — exceeds 100-line rule (trim before adding)
```

### C5 — Shell Env Parity (INFO)

Verifies that `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` is actually present in the current
shell's environment. This is a proxy check for "will Claude Code launched from this
shell inherit my compaction settings?" — important when using the Electron desktop
app, which inherits env from the terminal that launched it.

This is INFO-only: it doesn't affect the exit code.

### C6 — Output Token Limit (WARN)

Claude Code defaults to 8192 output tokens per response. When a task requires a long
response — writing a large file, generating a comprehensive diff, explaining a complex
system — it hits this cap mid-output and errors with:

```
API Error: Claude's response exceeded the 8192 output token maximum.
To configure this behavior, set the CLAUDE_CODE_MAX_OUTPUT_TOKENS environment variable.
```

C6 checks that `CLAUDE_CODE_MAX_OUTPUT_TOKENS` is set (in `settings.json` or zshrc)
and that its value is greater than 8192.

**Example failure:**

```
⚠ Output token limit   CLAUDE_CODE_MAX_OUTPUT_TOKENS not set — default 8192 cap may truncate responses
```

---

## Step 3: Auto-Fix What's Safe

Two checks are auto-fixable: C1 (settings parity) and C6 (token limit).

```bash
flow claude check --fix
```

**What `--fix` does:**

- **C1:** Updates the `export KEY=VALUE` line in `~/.config/zsh/.zshrc` to match the
  value in `settings.json`. Uses exact line replacement — no regex glob.
- **C6:** Appends `export CLAUDE_CODE_MAX_OUTPUT_TOKENS=32000` to `~/.config/zsh/.zshrc`
  if missing, or updates the value to 32000 if it's present but ≤ 8192.

**What `--fix` never touches:** `settings.json` (complex nested JSON — manual edit
only), hook scripts, MEMORY.md, or CLAUDE.md.

**Example output after `--fix`:**

```
✓ Settings parity      Fixed: CLAUDE_AUTOCOMPACT_PCT_OVERRIDE aligned in zshrc
✗ Hook health          post-compact-reinject.sh: not executable (manual fix needed)
⚠ Memory index drift   memory/: 8 .md files, 6 MEMORY.md entries (2 unindexed)
⚠ CLAUDE.md length     148 lines — exceeds 100-line rule
ℹ Shell env parity     CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=65 exported
✓ Output token limit   Fixed: CLAUDE_CODE_MAX_OUTPUT_TOKENS=32000 added to zshrc
```

After `--fix`, reload your shell: `source ~/.config/zsh/.zshrc`

---

## Step 4: Fix What Requires Manual Attention

### Fix C2 — Hook Not Executable

```bash
chmod +x ~/.claude/hooks/post-compact-reinject.sh
flow claude check  # Should now show ✓
```

### Fix C2 — Hook Fails shellcheck

```bash
shellcheck ~/.claude/hooks/post-compact-reinject.sh
# Read the output, fix the reported lines, re-run check
```

### Fix C3 — Memory Index Drift

Open `~/.claude/projects/<project>/memory/MEMORY.md` and add an entry for each
unindexed `.md` file, following the format:

```markdown
- [Short title](filename.md) — one-line description of what this memory contains
```

### Fix C4 — CLAUDE.md Too Long

Move verbose sections from `~/.claude/CLAUDE.md` into `~/.claude/rules/` files
(referenced via filename convention, not inline) or `~/.claude/reference/` for
reference material. The rule: trim before adding — every line must earn its place.

### Fix C6 — Manual settings.json Update

`--fix` updates zshrc. To also set it in `settings.json` (canonical):

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

## Step 5: Use the Exit Code in Scripts

`flow claude check` exits with a meaningful status code:

| Exit | Meaning |
|------|---------|
| `0` | All checks pass |
| `1` | At least one ERROR (C2) |
| `2` | At least one WARN, no ERRORs |

Use it in your workflow:

```bash
# Gate a session start on environment health
flow claude check && claude

# Warn but proceed
flow claude check; if [[ $? -eq 1 ]]; then echo "⚠ Fix hook before proceeding"; fi
```

---

## Quick Reference

```bash
# Run all checks
flow claude check

# Run + auto-repair C1 and C6
flow claude check --fix

# Alias
flow claude doctor
flow claude doctor --fix

# Reload shell after --fix
source ~/.config/zsh/.zshrc
```

---

## What's Next

- [flow claude reference](../commands/claude.md) — full check table and option docs
- [Claude Code Environment troubleshooting](../troubleshooting/CLAUDE-CODE-ENVIRONMENT.md) — shell snapshot limitations
- [flow doctor](../commands/doctor.md) — system-wide health check (tools, Atlas, dependencies)
- [Tutorial 23: Token Automation](23-token-automation.md) — managing `CLAUDE_CODE_MAX_OUTPUT_TOKENS` alongside other tokens

---

**Last Updated:** 2026-06-19
**Version:** v7.12.0
