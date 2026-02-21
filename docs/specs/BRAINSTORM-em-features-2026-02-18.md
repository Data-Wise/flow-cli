# Email Dispatcher Feature Brainstorm

**Generated:** 2026-02-18
**Context:** flow-cli `em` dispatcher (v7.3.0) + himalaya-mcp (v1.3.0)
**Mode:** Feature | Depth: Max | Focus: Terminal-native gaps

## Overview

The `em` dispatcher (20 subcommands, 1386 lines) and `himalaya-mcp` (19 MCP tools, 4 prompts) both wrap himalaya but serve different paradigms:

- **em** = keyboard-driven, fzf, $EDITOR, sub-second response
- **himalaya-mcp** = conversation-driven, Claude as interface, MCP protocol

This brainstorm identifies features that would strengthen `em` as a terminal-native email tool, informed by himalaya-mcp's capabilities and gaps in both systems.

---

## Quick Wins (< 30 min each)

1. **em thread `<ID>`** — Show conversation thread for a message
   - himalaya supports `--include-related` flag
   - Display as indented tree with timestamps
   - fzf bindable from `em pick` (Ctrl-H for thread)
   - Effort: Small (single function, ~40 lines)

2. **em snooze `<ID>` `<time>`** — Snooze email (move to Snoozed, schedule reminder)
   - Move to a "Snoozed" folder + write a reminder file
   - `em snooze 42 2h` / `em snooze 42 tomorrow`
   - Integrates with `terminal-notifier` (already in doctor)
   - Effort: Small (~30 lines + date parsing)

3. **em star `<ID>`** — Toggle flagged status (sugar for `himalaya flag add Flagged`)
   - Shorter than `himalaya message flag add 42 Flagged`
   - `em star 42` toggles, `em starred` lists flagged
   - Effort: Trivial (~15 lines)

4. **em move `<ID>` `<folder>`** — Move email to folder (himalaya-mcp has this, em doesn't)
   - `em move 42 Archive` / `em move 42 "Work/Projects"`
   - fzf folder picker when no folder specified
   - Effort: Small (~25 lines)

5. **em digest** — Daily email digest (inspired by himalaya-mcp's `daily_email_digest` prompt)
   - `em digest` = AI-grouped summary of today's emails by priority
   - `em digest --week` = weekly rollup
   - Output: terminal-friendly table, not markdown
   - Effort: Small (AI query + formatting, ~50 lines)

---

## Medium Effort (1-2 hours)

1. **em triage** — Interactive inbox triage mode (inspired by himalaya-mcp's `triage_inbox` prompt)
   - Step through unread emails one-at-a-time
   - For each: show snippet + AI classification
   - Actions: [a]rchive, [r]eply, [s]tar, [d]elete, [n]ext, [q]uit
   - ADHD-friendly: shows progress bar "3/12 triaged"
   - Different from `em respond` (which only handles actionable replies)
   - Effort: Medium (~100 lines, interactive loop)

2. **em templates** — Email template system
   - `em templates list` / `em templates use <name>` / `em templates create <name>`
   - Store in `~/.config/flow/email-templates/`
   - Pre-fill subject + body, merge placeholders `{{name}}`, `{{date}}`
   - Use case: recurring emails (status updates, meeting requests, etc.)
   - Effort: Medium (~80 lines + template storage)

3. **em export `<ID>`** — Export email to markdown (himalaya-mcp has `export_to_markdown`)
   - YAML frontmatter (from, to, date, subject, tags)
   - `em export 42` → stdout
   - `em export 42 --obsidian` → saves to Obsidian vault with wikilinks
   - `em export 42 --file notes/` → saves to directory
   - Effort: Medium (~60 lines)

4. **em actions `<ID>`** — Extract action items from email (himalaya-mcp has `create_action_item`)
   - AI-powered extraction of todos, deadlines, commitments
   - Output as checklist: `- [ ] Review budget by Friday (from: Jane)`
   - `em actions 42 --catch` → feeds each item to `catch` command
   - Effort: Medium (~50 lines + AI prompt)

5. **em stats** — Email analytics dashboard
    - Unread by folder, emails per day (7-day sparkline)
    - Top senders, response time estimate
    - Category breakdown (if AI classifications cached)
    - Effort: Medium (~80 lines, reads cache + himalaya data)

---

## Long-term (Future sessions)

1. **em rules** — Client-side email rules engine
    - `em rules add "from:*@github.com" move "Notifications"`
    - `em rules add "subject:*invoice*" star`
    - `em rules run` — apply rules to inbox
    - `em rules list` / `em rules delete <id>`
    - Store in `~/.config/flow/email-rules.json`
    - Effort: Large (~200 lines + rule parser)

2. **em follow** — Follow-up tracker
    - `em follow 42` — mark email as awaiting reply
    - `em follow list` — show all pending follow-ups with age
    - `em follow check` — notify about stale follow-ups (>3 days)
    - Integrates with `em dash` (show pending follow-up count)
    - Effort: Large (~120 lines + tracking file)

3. **em accounts** — Multi-account support in em
    - `em accounts list` / `em accounts switch <name>`
    - `em inbox --account work` / `em inbox --account personal`
    - himalaya already supports multi-account in config
    - `em dash` shows aggregate unread across all accounts
    - Effort: Large (touches most functions for --account flag)

4. **em cal `<ID>`** — Calendar event extraction (himalaya-mcp has this)
    - Parse ICS attachments from email
    - Display event details (time, location, attendees)
    - `em cal 42 --add` → add to Apple Calendar via osascript
    - Effort: Large (~100 lines + ICS parser in ZSH or via python)

5. **em compose** — Compose new email with fzf contact picker
    - `em compose` → fzf contact list → subject → $EDITOR → send
    - Contact list: scan recent From/To addresses, cache as contacts.json
    - `em compose --template weekly-update`
    - Different from `em send` (which is basic himalaya wrapper)
    - Effort: Large (~150 lines + contact scanner)

---

## Coexistence with himalaya-mcp

These features are **complementary**, not competitive:

| Feature     | em (terminal)                  | himalaya-mcp (AI)             | Best in  |
| ----------- | ------------------------------ | ----------------------------- | -------- |
| Thread view | `em thread 42` (tree)          | read + context window         | Terminal |
| Triage      | `em triage` (interactive loop) | `triage_inbox` prompt         | Both     |
| Digest      | `em digest` (terminal table)   | `daily_email_digest` prompt   | Both     |
| Export      | `em export 42` (stdout/file)   | `export_to_markdown` tool     | Both     |
| Actions     | `em actions 42` (checklist)    | `create_action_item` tool     | Both     |
| Calendar    | `em cal 42` (osascript)        | `extract_calendar_event` tool | AI       |
| Templates   | `em templates use X`           | Not applicable                | Terminal |
| Rules       | `em rules run`                 | Not applicable                | Terminal |
| Follow-ups  | `em follow list`               | Not applicable                | Terminal |
| Stats       | `em stats` (sparklines)        | Not applicable                | Terminal |

---

## Recommended Path

**Start with Quick Wins 1-5** (thread, snooze, star, move, digest) — each takes < 30 min, immediately useful, and fills the most obvious gaps vs himalaya-mcp.

**Then do Feature 6 (triage)** — this is the highest-value medium feature. It transforms `em` from "read/reply tool" into a complete inbox management system. The ADHD-friendly progress tracking makes it particularly valuable.

**Architecture note:** Features 6-10 could share a common `_em_interactive_loop` helper that handles the step-through-and-act pattern (triage, respond, and actions all use it).

---

## Next Steps

1. [ ] Pick 2-3 features from Quick Wins
2. [ ] Create spec for selected features
3. [ ] Implement on feature branch (worktree)
4. [ ] Update docs: tutorial, guide, refcard
