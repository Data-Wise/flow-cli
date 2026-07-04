# Proposal: Standardized Handoff Protocol — Claude Chat → Repo → Claude Code

**Date:** 2026-07-04
**Author:** Davood Tofighi (research + drafting assisted by Claude)
**Status:** Implemented — see `docs/specs/SPEC-flow-handoff-command.md` and the
`feature/flow-handoff-command` branch/worktree for the resulting `flow handoff` command.

---

## 1. Executive Summary

An earlier handoff (spec + feature-request + handoff note + GitHub issue, done ad hoc for the
`feature/ai-rewrite-trigger` branch) worked but was more scattered than necessary — four
documents with overlapping content and no template. This proposal researches how the broader
Claude community structures chat-to-Claude-Code handoffs, compares that against what was
actually done, and proposes (and now implements, via `flow handoff`) a single standardized
protocol.

**Core recommendation:** collapse the four-document pattern into one structured handoff file per
feature, following a format the community has already converged on, plus a lightweight
CLAUDE.md-level distinction between stable and session state.

---

## 2. Research: What the Claude Community Actually Does

### 2.1 The stable-vs-session-state split

The most consistent pattern across independent sources is a two-tier memory model: a stable
file (`CLAUDE.md`) holding things that rarely change — working style, standing preferences,
architectural conventions, constraints — and a session/dashboard file holding things that go
stale within days: current task, decisions made this session, open threads. Letting
session-specific state accumulate inside CLAUDE.md pollutes every future session with outdated
context.

### 2.2 The structured `/transfer-context` pattern

A community-published Claude Code skill defines an opinionated schema for handoff content:
Summary (completed work only), Key Decisions (with why), Traps to Avoid (dead ends already
tried), Working Agreements (interaction preferences), Relevant Files (path + line range + why),
Open Work (framed as status, not instructions — "X is not yet implemented," never "implement X
next"), and a closing instruction telling the next session to verify every claim against the
actual code rather than trust the handoff at face value.

### 2.3 Write the handoff before compaction, not after

A separate community pattern favors explicitly writing a handoff document before context runs
out, rather than relying on automatic compaction. The next session starts with only the plan,
not the accumulated back-and-forth of the prior conversation; the old transcript is linked, not
embedded, so it's available on demand without cluttering fresh context.

### 2.4 Anthropic's own documented mechanism

Claude Code's official docs describe a "plan locally, execute remotely" pattern: collaborate on
an approach locally, commit the plan to the repo, then launch a separate execution context
against that committed artifact. The transferable principle: the plan must be committed before
the next session begins, since that session has no access to the prior conversation — only to
what's on disk.

### 2.5 Handoff bundles as a validated general concept

Anthropic's own Claude Design → Claude Code handoff confirms that a purpose-built, structured
handoff format outperforms an unstructured context dump.

---

## 3. Gap Analysis (original ad-hoc handoff vs. best practice)

| Dimension | Ad-hoc approach | Best practice | Resolution |
|---|---|---|---|
| Number of documents | 4, overlapping | 1 structured file | `flow handoff` produces exactly one |
| Stable vs. session state | No distinction | CLAUDE.md vs. per-feature handoff | Handoff scoped to `docs/planning/`, never promoted into CLAUDE.md |
| Open work framing | Mixed status/instructions | Status only | Template enforces status-only phrasing |
| Verify-don't-trust instruction | Missing | Explicit | Built into the template's Verification Note |
| Committed before handoff assumed complete | Done correctly | Matches best practice | No change needed |

---

## 4. Implementation

Implemented as `flow handoff <slug>` — see `docs/specs/SPEC-flow-handoff-command.md` for the
full spec, `docs/commands/handoff.md` for the command reference, and `lib/handoff-helpers.zsh`
for the implementation.

---

## 5. Sources

- jdhodges.com — "Claude Handoff Prompt: How to Keep Context Across Sessions" (2026)
- artemxtech.substack.com — "Never lose your work between Claude Code sessions" (2026)
- GitHub gist (BexTuychiev) — `/transfer-context` skill definition
- github.com/ykdojo/claude-code-tips — community tips repo, `/dx:handoff` plugin command
- code.claude.com/docs — "Use Claude Code on the web" (official docs, plan-locally/execute-remotely pattern)
- claudefa.st/blog — "Claude Design to Claude Code: AI Design Handoff"
