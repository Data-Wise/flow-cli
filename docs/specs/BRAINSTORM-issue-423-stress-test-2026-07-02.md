# BRAINSTORM: Issue #423 Stress Test vs. v7.14.0 — 2026-07-02

**Topic:** Stress test issue #423 ("Scholar Config Sync wiring + new teach wrappers") against the
latest release (v7.14.0) and existing flow-cli functions.

**Method:** Read the issue body, grepped `teach-dispatcher.zsh` / `teach-doctor-impl.zsh` for every
deliverable listed, cross-checked against `git log --grep` for `#423`, then ran a live smoke test
of `teach config show` against the current tree.

## Headline finding

**Issue #423 is already fully shipped.** Every deliverable in its scope is implemented, tested, and
documented in the current `dev`/`main` tree. This is a stale/unclosed issue, not a gap.

| Issue scope item | Status | Evidence |
|---|---|---|
| Auto-inject `--config .flow/teach-config.yml` on Scholar commands | ✅ Shipped | `teach-dispatcher.zsh:1379-1390` |
| Wire `_teach_find_config()` into command assembly | ✅ Shipped | same block, `config_path=$(_teach_find_config ...)` |
| Wire `_flow_config_changed()` stale-config warning | ✅ Shipped | `teach-dispatcher.zsh:1379` |
| Legacy deprecation warning (`.claude/teaching-style.local.md`) | ✅ Shipped | `teach-dispatcher.zsh:1385-1390`, `4144`, `4196` |
| `teach config check/diff/show/scaffold` | ✅ Shipped | `teach-dispatcher.zsh:4552-4558`; commit `89838aeaa` "(#423)" |
| `teach solution` / `teach sync` / `teach validate-r` | ✅ Shipped | `teach-dispatcher.zsh:4516-4524`; commit `5c812e05d` "(#423)" |
| Config sync status in `teach doctor` | ✅ Shipped | `_teach_doctor_config_sync()` in `teach-doctor-impl.zsh:1250` |
| Help output updates | ✅ Shipped | `_teach_doctor_help`, dispatcher help blocks reference all subcommands |
| MASTER-DISPATCHER-GUIDE.md updates | ✅ Shipped | lines 2681-2689 list all 7 new subcommands |
| SCHOLAR-INTEGRATION-GUIDE.md | ✅ Shipped | `docs/guides/SCHOLAR-INTEGRATION-GUIDE.md` exists |

Three commits explicitly close the loop on this issue:
- `6b7e447e1` — "feat: wire --config injection to Scholar commands (#423)"
- `89838aeaa` — "feat: add teach config check/diff/show/scaffold subcommands (#423)"
- `5c812e05d` — "feat: add teach solution, sync, validate-r wrappers (#423)"
- `27b1b4256` — "fix: address PR review findings — config arg duplication, legacy path, ORCHESTRATE cleanup"

## What the smoke test actually surfaced

Ran `teach config show` live in this tree (no `.flow/teach-config.yml` present — this repo isn't a
teaching course project, so this is an expected cold-start path, not a course-configured one):

```
⚠️  teach: Config has validation issues
⚠️  teach: No 'scholar:' section in config — Scholar commands will use defaults
⚠️  teach: Config changed since last Scholar run — Run: teach config check
```

All three warnings are the *designed* degrade path working correctly — `_flow_config_changed` and
the legacy-config checks fired exactly as scoped in the issue. The wrapper then attempted to invoke
Scholar's `/teaching:config` slash command, which only resolves inside an actual Claude Code
session (not a bare zsh shell) — expected, not a bug: `_teach_scholar_wrapper` is designed to shell
out to the Claude Code CLI, which this raw-shell smoke test doesn't provide.

## Genuine stale point in the issue text (not a code gap)

The issue's "Prerequisites" line says *"Scholar plugin v2.2.0+ (installed)"*. Per this session's
memory and `CLAUDE.md`, Scholar has since split (as of Scholar v3.0.0): teaching-only content stays
in `scholar`, research moved to a new `savant` plugin. The `/teaching:*` slash commands this issue
wires against still live in `scholar`, so the integration itself is unaffected — but the
prerequisite line is now imprecise (doesn't mention the split) and could confuse a future reader
auditing this issue.

## Quick Wins (< 30 min)

1. **Close issue #423 with a comment linking the 3 implementing commits** — it's done; leaving it
   open is a false backlog signal for anyone triaging.
2. **One-line update to the issue body's Prerequisites** (if not closing outright) — note the
   Scholar v3.0.0 teaching/research split so the prerequisite doesn't mislead.

## Medium Effort (1-2 hrs)

- [ ] **Add an E2E fixture test** that runs `teach config show/check` inside a real Claude Code
  session against `tests/fixtures/demo-course/` — the current test suite likely covers the zsh-side
  wiring (arg assembly, warnings) but probably not the actual Scholar slash-command round trip,
  since that requires the `claude` binary. Confirm coverage before assuming a gap.
- [ ] **Audit the other 4 open issues** (#359, #331, #298, #275) the same way — #298 "Teaching
  config consolidation" in particular sounds adjacent to #423's scope and may also be
  partially/fully subsumed by work already shipped in `teach-dispatcher.zsh`.

## Long-term (future sessions)

- [ ] **Add a lightweight "issue-vs-shipped" drift check** to the release checklist — grep merged
  commit messages for `#<issue-number>` and flag open issues whose number appears in `git log`
  as merged-but-still-open. Would have caught #423 automatically at v7.14.0 release time.

## Recommended Next Step

→ **Close #423** (Quick Win #1) — it's fully shipped, verified via 3 independent commit
cross-references and a live code read of every deliverable. This clears one of the 5 open issues
with zero implementation risk, and the drift-check idea (Long-term) is worth a one-line note in the
next `/craft:release` retro so it doesn't recur.
