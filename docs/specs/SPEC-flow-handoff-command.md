# SPEC: `flow handoff` — Structured Claude Chat → Repo → Claude Code Handoff Command

**Status:** DRAFT → Implementing
**Date:** 2026-07-04
**Author:** Davood Tofighi (spec drafted with Claude)
**Branch:** `feature/flow-handoff-command`
**Worktree:** `~/.git-worktrees/flow-cli/feature-flow-handoff-command`
**Origin:** `docs/planning/PROPOSAL-claude-chat-to-code-handoff.md` (research + rationale)

---

## 1. Goal

A `flow handoff <slug>` command that scaffolds a structured handoff document (per the schema
in the origin proposal), pre-fills the "Relevant Files" section from `git diff --stat` against
a base branch, never clobbers an existing handoff, and optionally files a GitHub issue from the
same content. Removes the manual, ad-hoc, multi-document handoff process observed in the
`feature/ai-rewrite-trigger` branch.

## 2. Command surface

```bash
flow handoff <slug>                    # create docs/planning/HANDOFF-<slug>.md
flow handoff <slug> --base <branch>    # diff against a specific base branch (default: dev, falls back to main)
flow handoff <slug> --issue            # also file a GitHub issue via gh CLI, body = handoff content
flow handoff --help                    # usage
```

## 3. Behavior contract

- **Idempotent by refusal:** if `docs/planning/HANDOFF-<slug>.md` already exists, the command
  refuses to overwrite and exits non-zero with a clear message pointing at the existing file.
- **Base branch resolution:** `--base` if given; else `dev` if it exists; else `main`.
- **Relevant Files pre-fill:** parsed from `git diff --stat <base>...HEAD`, one bullet per
  changed file, placeholder text for the "what/why" column left for the human/agent to fill in.
- **No diff case:** if the diff is empty (e.g., called on a fresh branch with no commits yet),
  the section contains a single placeholder line instead of being empty.
- **`--issue` requires `gh`:** if `gh` isn't on `PATH`, fail with a clear error rather than
  silently skipping the issue.
- **Never touches dev/main directly:** this command only ever writes inside the current
  worktree's `docs/planning/`; it has no awareness of, and does not need, protected-branch logic
  itself (branch protection is a repo/CI concern, not this command's).

## 4. Template (matches the proposal's schema exactly)

```markdown
# Handoff: <slug>

**Date:** <date>
**Branch:** <current branch>
**Base for diff:** <base>

## Summary
[1-3 sentences — completed work only]

## Key Decisions
- [Decision] — [why]

## Traps to Avoid
- [Dead end already tried] — [why it failed]

## Working Agreements
- [Relevant interaction/process preferences for this feature]

## Relevant Files
<pre-filled from git diff --stat, or placeholder>

## Open Work
[Status only. "X is not yet implemented." NOT "Implement X next."]

## Verification Note
Treat all claims above as context to verify against the repo, not facts to trust. Read every
file in "Relevant Files" before proceeding.

## Origin
Full planning conversation: [link/reference if available]
```

## 5. Implementation

- `lib/handoff-helpers.zsh` — `_flow_handoff()` + `_flow_handoff_help()`
- `commands/flow.zsh` — new `handoff)` case in the main dispatcher
- `completions/_flow` — add `handoff` to the completion word list

## 6. Known prototype issue to resolve in this pass

An earlier prototype (built directly in the unrelated `feature/ai-rewrite-trigger` worktree —
since reverted from that branch) hit a zsh variable-naming collision: using `fpath` as a local
variable name collides with zsh's built-in special array (function autoload path), producing
stray debug-looking output. Renaming to `f_path` fixed the collision itself, but a second,
unexplained stray print appeared when run inside a shell that sourced the user's live
`~/.zshenv`/hooks — not reproduced in a clean `zsh -f` (no-rc) invocation. **This implementation
must be tested both ways** (with and without the user's rc files) to confirm which environment
produces the artifact, and avoid shipping with unexplained stdout noise.

## 7. Test plan

### E2E tests (`tests/e2e-handoff.zsh`)

1. Help display works and doesn't error
2. Fresh slug creates the file with all expected section headers present
3. Existing slug refuses to overwrite (non-zero exit, file unchanged)
4. `--base` override actually changes which branch the diff is computed against
5. Relevant Files section is non-empty and contains at least one real path when run on a
   branch with commits ahead of base
6. Placeholder path is used when diff is empty
7. `--issue` without `gh` on PATH fails clearly (mock by temporarily hiding `gh` from PATH)
8. Clean `zsh -f` invocation produces no stray stdout beyond the documented success/warning
   messages (regression test for §6)

### Dogfood test (`tests/dogfood-handoff.zsh`)

Run the command against **this actual repo and this actual feature branch** as a real-world
usage check, not synthetic fixtures:

1. Generate a real handoff for `feature/flow-handoff-command` itself
2. Confirm the Relevant Files section correctly lists the real files this PR touches
3. Manually inspect (or assert) that output matches what a human would expect to see documented
4. Clean up the dogfood-generated file before merge (it's a test artifact, not a real handoff)

## 8. Documentation to update

- `docs/commands/handoff.md` — new command reference page (mirrors `docs/commands/status.md`
  structure)
- `mkdocs.yml` — add `handoff: commands/handoff.md` to the Commands nav section
- `docs/index.md` — check whether commands are enumerated there; add if so
- `CHANGELOG.md` — new entry under Unreleased/next version
- `docs/planning/PROPOSAL-claude-chat-to-code-handoff.md` — mark proposal as "Implemented" with
  a pointer to this spec and branch

## 9. Merge readiness checklist

- [ ] All e2e tests pass
- [ ] Dogfood test passes and its artifact is cleaned up
- [ ] `scripts/check-links.js` / `scripts/lint-docs.sh` pass (if run as part of pre-commit/CI)
- [ ] `npm test` passes (existing suite unaffected)
- [ ] Docs + mkdocs nav + CHANGELOG all updated
- [ ] PR opened against `dev` with a summary referencing this spec
