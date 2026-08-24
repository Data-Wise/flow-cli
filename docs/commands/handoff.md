# Command Reference: flow handoff

> **Scaffold a structured handoff document for transferring context from a Claude chat/planning session into a repo for a Claude Code session to pick up**

Complete reference for the `flow handoff` command - generate a structured handoff file and
optionally file it as a GitHub issue.

---

## Synopsis

```bash
flow handoff <slug>
flow handoff <slug> --base <branch>
flow handoff <slug> --issue
flow handoff --help
```

---

## Description

The `flow handoff` command scaffolds `docs/planning/HANDOFF-<slug>.md` using a fixed schema
designed for context transfer between AI sessions — whether that's a Claude.ai chat session
handing off to a local Claude Code session, or one Claude Code session handing off to the next
after a context reset.

It solves a problem observed in practice: without a template, handoffs tend to sprawl across
several ad-hoc documents (a spec, a feature request, a free-form note) with overlapping content
and no consistent structure for the next session to rely on. `flow handoff` produces one file,
in one place, every time.

See [docs/planning/PROPOSAL-claude-chat-to-code-handoff.md](../planning/PROPOSAL-claude-chat-to-code-handoff.md)
for the research behind the template's structure, and
[SPEC-flow-handoff-command.md](https://github.com/Data-Wise/flow-cli/blob/main/docs/specs/SPEC-flow-handoff-command.md)
for the full implementation spec (specs aren't published on the docs site).

---

## Options

| Option | Description |
|---|---|
| `<slug>` | Required. Used as the filename suffix: `HANDOFF-<slug>.md` |
| `--base <branch>` | Branch to diff against for the Relevant Files pre-fill. Defaults to `dev`, falling back to `main` if `dev` doesn't exist |
| `--issue` | After creating the file, also run `gh issue create` using the handoff file as the issue body. Requires `gh` to be installed and authenticated |
| `--help`, `-h` | Show usage |

---

## Generated file structure

```markdown
# Handoff: <slug>

**Date:** ...
**Branch:** ...
**Base for diff:** ...

## Summary
## Key Decisions
## Traps to Avoid
## Working Agreements
## Relevant Files
## Open Work
## Verification Note
## Origin
```

**Relevant Files** is the only section pre-filled automatically, from
`git diff --name-only <base>...HEAD`. Every other section is a placeholder for you (or the
authoring session) to fill in before the handoff is used.

**Open Work** should be written as status, not instructions — "X is not yet implemented," not
"implement X next" — so the receiving session isn't nudged toward a specific next step it hasn't
independently evaluated.

**Verification Note** is included by default and should not be removed: it instructs the
receiving session to treat the handoff's claims as things to check against the actual repo
state, not as facts to trust unconditionally.

---

## Behavior notes

- **Refuses to overwrite.** If `docs/planning/HANDOFF-<slug>.md` already exists, the command
  exits non-zero and does not touch the file. Pick a different slug, or edit the existing file
  directly.
- **Empty diff is handled.** If there's no diff against the base branch yet (e.g., a fresh
  branch with no commits), the Relevant Files section gets a placeholder line instead of being
  blank.
- **`--issue` needs `gh` on PATH.** Without it, the command fails clearly rather than silently
  skipping the issue-filing step.

---

## Examples

```bash
# Basic usage — diffs against dev (or main) automatically
flow handoff ai-rewrite-trigger

# Diff against a specific base branch
flow handoff ai-rewrite-trigger --base main

# Also file a GitHub issue with the handoff content as the body
flow handoff ai-rewrite-trigger --issue
```

---

## See also

- [`wt`](../reference/REFCARD-WORKTREE-DISPATCHER.md) — worktree management, typically used
  alongside `flow handoff` when a feature is scoped to its own branch/worktree
- [`status`](status.md) — for ongoing `.STATUS` tracking, distinct from one-time handoffs
