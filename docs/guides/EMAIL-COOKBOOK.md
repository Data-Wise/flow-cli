# Email Cookbook — Practical Recipes for em

> Copy-paste workflows for common email tasks.
>
> **Dispatcher:** `em` | **Version:** v2.0 (flow-cli v7.4.2+)
> **Last Updated:** 2026-02-26

Each recipe follows the same structure: **Problem** — **Solution** — **Explanation** — **Pro tip**.
For full reference, see the [refcard](../reference/REFCARD-EMAIL-DISPATCHER.md) and [guide](EMAIL-DISPATCHER-GUIDE.md).

---

## Table of Contents

1. [Morning Email Triage](#1-morning-email-triage)
2. [Inbox Zero in 5 Minutes](#2-inbox-zero-in-5-minutes)
3. [Search and Act on Old Email](#3-search-and-act-on-old-email)
4. [Process Calendar Invites](#4-process-calendar-invites)
5. [Monitor Email in Background](#5-monitor-email-in-background)
6. [Manage Folder Structure](#6-manage-folder-structure)
7. [Attachment Workflows](#7-attachment-workflows)
8. [Batch Reply to Students](#8-batch-reply-to-students)
9. [AI Backend Switching](#9-ai-backend-switching)
10. [Weekly Email Digest](#10-weekly-email-digest)
11. [Safe Sending with Preview](#11-safe-sending-with-preview)
12. [Email-to-Task Pipeline](#12-email-to-task-pipeline)
13. [Cache Management](#13-cache-management)
14. [Exchange / Outlook Setup](#14-exchange--outlook-setup)

---

## 1. Morning Email Triage

**Problem:** You open your terminal in the morning and need to know what needs your attention before touching anything else.

**Solution:**

```zsh
# Step 1: Quick pulse — unread count + 10 latest (no AI, instant)
em

# Step 2: See what's actionable before drafting anything
em respond --dry-run

# Step 3: Generate AI drafts for all actionable emails
em respond

# Step 4: Review the queued drafts and send (or skip each one)
em respond --review
```

**Explanation:**

- `em` with no arguments runs the dashboard: unread count and your 10 most recent emails with `•` (unread), `★` (starred), and `+` (attachment) indicators.
- `--dry-run` classifies emails without generating drafts — useful to survey the landscape before committing to AI work.
- `em respond` then generates drafts for all actionable emails (student, colleague, admin-action, scheduling, urgent). Non-actionable categories (newsletter, vendor, admin-info, automated) are skipped automatically.
- `em respond --review` opens each cached draft in an fzf picker so you can inspect, edit in `$EDITOR`, send, or skip.

**Pro tip:** Run `em respond --dry-run` first when your AI quota is low. The classification output tells you how many actionable emails you have so you can prioritize manually with `em reply`.

---

## 2. Inbox Zero in 5 Minutes

**Problem:** Your inbox has 30+ emails and you want to process them all without leaving the terminal.

**Solution:**

```zsh
# Open the interactive fzf browser
em pick

# Inside fzf, use these bindings:
#   Enter      — Read full email
#   Ctrl-R     — Reply (opens AI draft in $EDITOR)
#   Ctrl-S     — One-line AI summary (without opening)
#   Ctrl-A     — Archive (mark as read)
#   Ctrl-D     — Delete (move to Trash, y/N confirm)
#   Ctrl-F     — Star / unstar
#   Ctrl-M     — Move to folder (fzf folder picker)
#   Ctrl-T     — Capture as task (AI summary to catch)
#   Ctrl-O     — Extract action items to Reminders.app
#   Ctrl-E     — Extract calendar event to Calendar.app
#   Escape     — Exit picker

# When done, verify inbox state
em unread
```

**Explanation:**

`em pick` loads your inbox into an fzf browser with a live preview pane. You can act on any email without leaving the picker — archive batches with Ctrl-A, delete junk with Ctrl-D, and reply to what matters with Ctrl-R. The preview updates as you move through the list.

**Pro tip:** Use Ctrl-S on each email to read the AI summary in the preview pane before deciding whether to reply or archive. For a folder other than INBOX, run `em pick "Sent Items"` or any folder name from `em folders`.

---

## 3. Search and Act on Old Email

**Problem:** You need to find an email from two months ago, read it, and either reply, file it, or delete it.

**Solution:**

```zsh
# Search across subject, from, and body
em find "grant proposal"

# Or use IMAP search syntax for precise queries
em find "from:alice before:2026-01-01"
em find "subject:STAT-101"

# Read the email you found (use the ID shown in search results)
em read 87
em read --md 87    # Clean Markdown rendering (better for Outlook emails)

# Now act on it
em reply 87                         # AI-drafted reply
em move 87 Archive                  # File it away
em delete 87                        # Move to Trash (y/N confirm)
em snooze 87 monday                 # Come back to it Monday 9am
```

**Explanation:**

`em find` wraps himalaya's search and returns matching emails with their IDs. The ID is what every other command accepts. `--md` rendering runs the email through pandoc and cleans up Outlook noise (Safe Links, attribute blocks, CID image refs) for much cleaner reading.

**Pro tip:** Pipe a search result directly into `em respond` logic by starring the emails you want to act on (`em star 87`), then processing them from `em starred`.

---

## 4. Process Calendar Invites

**Problem:** You receive a meeting invitation with an ICS attachment and want to add it to Apple Calendar without leaving the terminal.

**Solution:**

```zsh
# Step 1: See the email (attachment indicator '+' in dashboard)
em

# Step 2: Check what attachments are on the email
em attach list 55

# Step 3: Parse the ICS attachment and add to Apple Calendar
em calendar 55
# Output: parsed event details (title, time, location, organizer)
# Prompt: "Add to Apple Calendar? [y/N]" → y
```

**Explanation:**

`em calendar` (alias: `em cal`) reads the ICS file attached to an email, displays the parsed event fields, and optionally calls `osascript` to add the event to Apple Calendar. No copy-pasting into Calendar.app required.

**Pro tip:** If the email contains multiple ICS files (e.g., a meeting update alongside the original), `em attach list <ID>` shows the full attachment table with MIME types so you can confirm which file is the calendar invite before running `em calendar`.

---

## 5. Monitor Email in Background

**Problem:** You want your terminal to notify you when new email arrives while you work, without polling manually.

**Solution:**

```zsh
# Start the background IMAP IDLE watcher
em watch start

# Check whether it is running
em watch status
# Output: watcher PID 83421 — uptime 4m 32s

# Tail the live log if you want to see activity
em watch log

# Stop the watcher when done
em watch stop
```

**Explanation:**

`em watch` starts an IMAP IDLE process in the background that keeps a persistent connection to your mail server. When new mail arrives, it triggers a desktop notification via `terminal-notifier` (if installed). The PID is written to `.flow/email-watch.pid` so `status` and `stop` can find it across sessions.

> **Note:** `em watch` is experimental in v2.0. It requires `terminal-notifier` for desktop notifications (`brew install terminal-notifier`). Run `em doctor` to verify your setup.

**Pro tip:** Add `em watch start` to your `work` session startup alias so monitoring starts automatically when you begin a work session.

---

## 6. Manage Folder Structure

**Problem:** You need to create a new folder for a project, move emails into it, and eventually clean up an old folder.

**Solution:**

```zsh
# See all existing folders
em folders

# Create a new folder
em create-folder "Research 2026"

# Move emails into it (one at a time or batch)
em move 101 "Research 2026"
em mv "Research 2026" 102 103 104   # batch move: folder first, then IDs

# Or move with fzf folder picker (no folder arg = interactive)
em move 105

# List and clean up an old folder
em inbox 50 "Old Archive"

# Delete the folder (type the name to confirm — safety gate)
em delete-folder "Old Archive"
```

**Explanation:**

`em folders` lists every mailbox on the server — useful before creating or deleting to avoid typos. `em create-folder` and `em delete-folder` (aliases: `cf`, `df`) wrap himalaya's folder CRUD. The delete command requires you to type the folder name in full before proceeding, preventing accidental data loss.

**Pro tip:** For Exchange/Outlook accounts, folder names are case-sensitive and must match exactly. Run `em folders` to get the exact names before passing them to `em move` or `em delete-folder`.

---

## 7. Attachment Workflows

**Problem:** An email has multiple attachments. You need to inspect what is there, download one specific file, and save another to a custom directory.

**Solution:**

```zsh
# See all attachments on an email (name, MIME type, size)
em attach list 77

# Download a specific file by name
em attach get 77 report.pdf
em attach get 77 report.pdf ~/Documents/Reports    # custom directory

# Download all attachments at once
em attach 77                       # saves to ~/Downloads
em attach 77 ~/Desktop             # saves to custom directory
```

**Explanation:**

`em attach list` gives you the full attachment table — handy when an email has mixed attachments (PDF, XLSX, ICS) and you only want one. `em attach get` downloads by filename match. `em attach` (no subcommand) downloads everything at once. All three are idempotent — re-running overwrites the local file.

**Pro tip:** Combine with `em calendar` for meeting emails that include both a PDF agenda and an ICS invite. Use `em attach list` to confirm which ID is the calendar file, then run `em calendar` for the ICS and `em attach get` for the PDF separately.

---

## 8. Batch Reply to Students

**Problem:** You have 40+ student emails in a dedicated folder and need to generate AI drafts and reply to all of them efficiently.

**Solution:**

```zsh
# Step 1: Preview what's in the folder and what is actionable
em inbox 50 "Student Emails"
em respond --dry-run --folder "Student Emails" -n 50

# Step 2: Generate drafts for all actionable student emails
em respond --folder "Student Emails" -n 50

# Step 3: Review each draft — send, edit, or skip
em respond --review

# Step 4: For any that need a personal touch, reply manually
em reply 134             # opens AI draft in $EDITOR
em reply 134 --no-ai    # blank compose if you prefer

# Step 5: Reply-all when needed (e.g., group project threads)
em reply 134 --all

# Step 6: Non-interactive batch send (preview + y/N, no editor)
em reply 134 --batch
```

**Explanation:**

`em respond` with `--folder` and `-n` scopes the batch to a specific mailbox. Drafts are cached locally (TTL: 1 hour) so you can interrupt and resume with `em respond --review`. The classifier auto-detects listserv emails and shows a warning banner before drafting to prevent accidental reply-all to a mailing list.

**Pro tip:** Run `--dry-run` first on a large folder to see the classification breakdown (student, scheduling, admin-action, etc.) before generating drafts. This lets you spot misclassified emails and handle them manually before the AI wastes time drafting replies to newsletters.

---

## 9. AI Backend Switching

**Problem:** Your primary AI backend is unavailable (quota exceeded, network issue) and you want to switch to the fallback without restarting your shell.

**Solution:**

```zsh
# Check what backend is active and what is available
em ai

# Switch to a specific backend
em ai claude
em ai gemini
em ai none      # disable AI entirely

# Cycle through available backends one at a time
em ai toggle

# Restore automatic selection (uses first available backend)
em ai auto
```

**Explanation:**

`em ai` changes `FLOW_EMAIL_AI` in the current shell session without touching your config file. The change takes effect immediately for all subsequent `em` commands. The fallback chain is: claude -> gemini -> none (graceful timeout). Use `em ai none` when you need sub-second response times and do not want any AI operations blocking your workflow.

**Pro tip:** Set `FLOW_EMAIL_AI=gemini` in `.flow/email.conf` for a specific project if that project's email volume is high and you want to preserve Claude quota for code tasks. Project config overrides global config automatically.

---

## 10. Weekly Email Digest

**Problem:** It is Friday afternoon and you want a grouped summary of everything that came in this week before you close down.

**Solution:**

```zsh
# Today's digest — AI-grouped by category
em digest

# Full week digest
em digest --week

# Larger digest (default is 25 emails)
em digest --week -n 100
```

**Explanation:**

`em digest` (alias: `em dg`) fetches recent emails and groups them by AI classification: urgent, student, scheduling, colleague, admin-action, then non-actionable categories below. Each group shows sender, subject, and a one-line AI summary. The weekly view (`--week`) gives you a retrospective before the weekend and surfaces anything that slipped through the cracks.

**Pro tip:** Pair `em digest --week` with `yay --week` (the flow-cli wins tracker) as a Friday wrap-up ritual. Email processed + wins logged = a complete picture of the week.

---

## 11. Safe Sending with Preview

**Problem:** You want to compose and send an email — but you want to see exactly what will go out before it leaves your outbox.

**Solution:**

```zsh
# Compose a new email — full preview before send
em send

# AI-assisted compose (drafts from subject line)
em send --ai "Agenda for Tuesday lab meeting"

# Reply flow with preview gate
em reply 42              # AI draft in $EDITOR, then preview
em reply 42 --no-ai      # Manual compose, then preview
em reply 42 --all        # Reply-all with preview

# The preview prompt looks like this:
# ─────────────────────────────────────
#   To:      alice@university.edu
#   Subject: Re: STAT-101 Exam
#   ─────────────────────────────────────
#   [your email body]
# ─────────────────────────────────────
# Send this email? [y/N/e]
#   y = send now
#   N = discard (default)
#   e = open in $EDITOR to revise

# Bypass preview when you are sure (e.g., scripted sends)
em send --force
em reply 42 --force
```

**Explanation:**

The two-phase safety gate is a v2.0 breaking change. Every `em send` and `em reply` now shows a full preview with recipient, subject, and body before the email leaves your machine. The default answer is No — you must press `y` to send. Press `e` to jump back into `$EDITOR` for a last-minute revision. Rejected sends preserve the draft in cache; retrieve with `em respond --review`.

**Pro tip:** Use `--batch` mode (`em reply 42 --batch`) when processing a queue of replies that do not need editor access — it shows the preview and a `[y/N]` prompt only, with no editor step. Faster than the default flow for clear-cut replies.

---

## 12. Email-to-Task Pipeline

**Problem:** An email contains action items, a meeting request, and a follow-up you need to track. You want all three captured without leaving the terminal.

**Solution:**

```zsh
# Capture the email as a task (AI summary → flow catch)
em catch 60
# Adds a task to your catch queue: "Reply to Alice re: exam rubric"

# Extract action items to Reminders.app
em todo 60
# AI parses the email body and creates individual reminders

# Extract calendar events to Calendar.app
em event 60
# AI finds dates/times and creates calendar events via osascript

# Do all three on multiple emails at once
em todo 60 61 62
em event 60 61 62
```

**Explanation:**

These three commands form a capture pipeline for information-dense emails. `em catch` gives you a quick single-line task in the flow-cli capture system. `em todo` goes deeper — it parses the email body for explicit action items and creates each as a separate Reminder. `em event` finds dates, times, and locations and adds them to Calendar.app. All three use the AI backend (cached for 24 hours after first run).

**Pro tip:** You can also trigger these from inside `em pick` without opening the email: `Ctrl-T` for catch, `Ctrl-O` for todo, `Ctrl-E` for event. Fastest path when triaging a long list.

---

## 13. Cache Management

**Problem:** Your AI cache is large, you have stale drafts from yesterday, or you want to pre-warm the cache before a meeting where you will be processing email quickly.

**Solution:**

```zsh
# See what is cached and how large it is
em cache stats
# Shows: total size, per-operation counts, expired entries

# Remove only expired entries (safe, non-destructive)
em cache prune

# Pre-warm cache for the latest 20 emails (runs in background)
em cache warm 20

# Clear the entire cache (use when you have bad drafts or stale data)
em cache clear

# Clear just the drafts (via respond flag)
em respond --clear
```

**Explanation:**

The cache lives in `.flow/email-cache/` and is organized by operation type: summaries (24h TTL), classifications (24h), drafts (1h), schedules (24h), unread counts (1m). Auto-prune runs in the background whenever you open `em dash` or `em inbox`. The size cap is 50 MB by default (configurable via `FLOW_EMAIL_CACHE_MAX_MB`); when exceeded, the oldest files are evicted automatically.

**Pro tip:** Run `em cache warm 30` at the start of a known heavy email session — for example, after a conference or a weekend away. The background pre-warming means your first `em respond` or `em pick` will feel instant because summaries and classifications are already computed.

---

## 14. Exchange / Outlook Setup

**Problem:** You are on an Exchange or Outlook account and `em delete` is not working because the Trash folder is named `Deleted Items`, not `Trash`.

**Solution:**

```zsh
# Set the correct trash folder name for Exchange/Outlook
export FLOW_EMAIL_TRASH_FOLDER="Deleted Items"

# Or persist it in your config file
echo 'FLOW_EMAIL_TRASH_FOLDER="Deleted Items"' >> ~/.config/flow/email.conf

# Verify all dependencies are healthy (includes account detection)
em doctor

# List actual folder names on your Exchange server
em folders
# Look for the exact Trash/Deleted folder name and adjust the variable
```

**Explanation:**

Exchange servers use `Deleted Items` instead of `Trash`. Without this variable set, `em delete` moves email to a `Trash` folder that may not exist, causing a server error. Setting `FLOW_EMAIL_TRASH_FOLDER` tells the dispatcher where to route deleted emails. Similarly, Outlook's Sent folder may be `Sent Items` rather than `Sent` — check `em folders` to confirm exact names.

Config load order: env vars → `.flow/email.conf` (project) → `$FLOW_CONFIG_DIR/email.conf` (global). Project config wins, so you can set different trash folders per project if you have multiple accounts.

**Pro tip:** Run `em doctor` after any configuration change. It shows your current AI backend, AI timeout, page size, folder, and which config file is active — everything in one view. If himalaya cannot connect, it reports the version and which progressive-enhancement features are enabled.

---

## Quick Reference

### Recipe Decision Tree

| You want to... | Use |
| -------------- | --- |
| See what needs attention right now | `em` or `em dash` |
| Process everything in one session | `em respond` then `em respond --review` |
| Browse interactively | `em pick` |
| Find a specific old email | `em find "query"` |
| Reply to one email with AI help | `em reply <ID>` |
| Send email safely with preview | `em send` (default: preview gate) |
| Capture email as task/reminder/event | `em catch`, `em todo`, `em event` |
| Process a specific folder in bulk | `em respond --folder "Name" -n 50` |
| Get a weekly overview | `em digest --week` |
| Check system health | `em doctor` |

### Key Aliases

```zsh
em i     # em inbox
em r     # em read
em re    # em reply
em s     # em send
em p     # em pick
em f     # em find
em u     # em unread
em d     # em dash
em resp  # em respond
em sum   # em summarize
em dg    # em digest
em cal   # em calendar
em a     # em attach
em w     # em watch
em dr    # em doctor
em h     # em help
```

---

## See Also

- [EMAIL-DISPATCHER-GUIDE.md](EMAIL-DISPATCHER-GUIDE.md) — Complete workflow guide with setup, daily routine, and all command details
- [REFCARD-EMAIL-DISPATCHER.md](../reference/REFCARD-EMAIL-DISPATCHER.md) — All 37 commands at a glance with flags, aliases, and configuration reference
- [HIMALAYA-SETUP.md](HIMALAYA-SETUP.md) — Email account configuration (IMAP/SMTP, Gmail OAuth2, Exchange)
- [HIMALAYA-NVIM-SETUP.md](HIMALAYA-NVIM-SETUP.md) — Neovim integration with AI actions

---

**Version:** v2.0 (em dispatcher) — flow-cli v7.4.2+
**Last Updated:** 2026-02-26
