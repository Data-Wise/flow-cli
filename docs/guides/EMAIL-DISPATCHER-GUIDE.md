# Email Dispatcher Guide

**Available Since:** v7.0.0 | **v2.0 Since:** v7.5.0
**Status:** Production Ready
**Last Updated:** 2026-02-26

## Overview

The email dispatcher (`em`) brings ADHD-friendly email management to your terminal through a pure ZSH interface
to [himalaya](https://github.com/pimalaya/himalaya). Think inbox zero in under 5 minutes, with AI-powered draft
generation, smart rendering, and zero browser context-switching.

```bash
em                    # Quick pulse (unread + 10 latest)
em pick               # Interactive fzf browser
em read 42            # Smart rendering (HTML/markdown/plain)
em reply 42           # AI draft in $EDITOR
em respond            # Batch AI drafts for actionable emails
em star 42            # Toggle star/flag
em move 42 Archive    # Move to folder
em thread 42          # Conversation thread view
em snooze 42 2h       # Snooze for later
em digest             # AI-grouped daily summary
em ai gemini          # Switch AI backend at runtime
em catch 42           # Capture email as task
```

**Philosophy:**
- **Pure ZSH** - No Node.js runtime, no build step, sub-100ms commands
- **ADHD-friendly** - Quick pulse checks, smart defaults, keyboard-first
- **No vendor lock-in** - Just a wrapper around himalaya; your email stays portable
- **AI-augmented** - Optional AI features enhance without requiring changes to your workflow

## Why em?

Traditional email clients are heavyweight, distraction-prone, and slow. The `em` dispatcher brings email
management into your flow-cli workflow:

- **Fast** - Sub-second response times for common operations
- **Focused** - No ads, no social features, no distractions
- **Scriptable** - Integrates with your shell workflows
- **Keyboard-first** - fzf picker with preview, multi-action support
- **AI-optional** - Works great without AI, better with it
- **Safe** - Explicit confirmation for all sends (default: No)

## Two Interfaces, One Backend

Both `em` and [himalaya-mcp](https://github.com/Data-Wise/himalaya-mcp) wrap the same himalaya CLI but serve
different interaction models:

| | em (terminal-native) | himalaya-mcp (AI-native) |
| --- | --- | --- |
| **Interface** | Keyboard-driven (fzf, $EDITOR) | Conversation-driven (Claude) |
| **Speed** | Sub-second, interactive | Deliberate, context-rich |
| **Best for** | Quick triage, reading, replying | Batch analysis, digests, drafting |
| **AI role** | Optional enhancement | Core interface |

They coexist naturally — use `em` for fast terminal operations and himalaya-mcp when you want Claude to help
compose, triage, or analyze email content.

## Prerequisites

### Required

| Tool | Purpose | Install |
| --- | --- | --- |
| [himalaya](https://github.com/pimalaya/himalaya) | Email CLI backend (IMAP/SMTP) | `brew install himalaya` or `cargo install himalaya` |
| [jq](https://stedolan.github.io/jq/) | JSON parsing | `brew install jq` |

### Recommended

| Tool | Purpose | Install |
| --- | --- | --- |
| [fzf](https://github.com/junegunn/fzf) | Interactive email picker | `brew install fzf` |
| [bat](https://github.com/sharkdp/bat) | Syntax highlighting | `brew install bat` |
| [w3m](https://w3m.sourceforge.net/) | HTML rendering (primary) | `brew install w3m` |
| [glow](https://github.com/charmbracelet/glow) | Markdown rendering | `brew install glow` |

> **Tip:** HTML rendering uses a fallback chain: w3m → lynx → pandoc → bat → cat

### Optional

| Tool | Purpose | Install |
| --- | --- | --- |
| [email-oauth2-proxy](https://github.com/simonrob/email-oauth2-proxy) | OAuth2 for Gmail/Outlook | `pip install email-oauth2-proxy` |
| terminal-notifier | Desktop notifications | `brew install terminal-notifier` |
| claude CLI | AI drafts (primary) | See [Claude Code docs](https://claude.ai/docs) |
| gemini CLI | AI drafts (fallback) | `pip install google-generativeai` |

### Check Your Setup

```bash
em doctor
```

This checks all dependencies and shows your current configuration:

```text
em doctor — Email Dependency Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ok  himalaya             v1.0.0
  ok  jq                   jq-1.7
  ok  fzf                  0.44.1
  ok  bat                  v0.24.0
  ok  w3m                  w3m/0.5.3+git20230121
  ok  glow                 v1.5.1
  ok  email-oauth2-proxy   v1.1.0
  --- claude (AI drafts)   npm install -g @anthropic-ai/claude-code
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
6 passed  0 warnings  1 failed

Config:
  AI backend:  claude
  AI timeout:  30s
  Page size:   25
  Folder:      INBOX
  Config file: (none — using env defaults)
```

## Setup

### 1. Install himalaya

himalaya is the backend that talks to your email server via IMAP/SMTP.

```bash
# Option 1: Homebrew (recommended)
brew install himalaya

# Option 2: Cargo (cross-platform alternative)
cargo install himalaya
```

Verify installation:

```bash
himalaya --version
```

### 2. Configure himalaya

himalaya supports multiple accounts and authentication methods. See the
[himalaya configuration guide](https://pimalaya.org/himalaya/cli/latest/configuration/index.html) for complete
setup instructions.

**Quick Gmail Setup (OAuth2):**

```bash
# Install OAuth2 proxy for Gmail
pip install email-oauth2-proxy

# Configure himalaya with Gmail account
himalaya account configure gmail
```

**Quick IMAP/SMTP Setup:**

Create `~/.config/himalaya/config.toml`:

```toml
[accounts.personal]
default = true
email = "you@example.com"

backend.type = "imap"
backend.host = "imap.example.com"
backend.port = 993
backend.login = "you@example.com"
backend.auth.type = "password"
backend.auth.raw = "your-password-here"  # Or use keychain

sender.type = "smtp"
sender.host = "smtp.example.com"
sender.port = 587
sender.login = "you@example.com"
sender.auth.type = "password"
sender.auth.raw = "your-password-here"  # Or use keychain
```

> **Security Note:** Use app-specific passwords or OAuth2 for Gmail/Outlook. Store passwords in your system
> keychain rather than plaintext config files.

Test your setup:

```bash
himalaya envelope list --page-size 5
```

If this works, you're ready to use `em`.

### 3. Configure em (Optional)

Set environment variables in your `.zshrc` or create a config file:

#### Option A: Environment Variables

```bash
# In ~/.zshrc or ~/.config/zsh/.zshrc
export FLOW_EMAIL_AI="claude"           # claude | gemini | none
export FLOW_EMAIL_AI_TIMEOUT=30         # AI timeout in seconds
export FLOW_EMAIL_PAGE_SIZE=25          # Default inbox page size
export FLOW_EMAIL_FOLDER="INBOX"        # Default folder
```

#### Option B: Config File

Create `~/.config/flow/email.conf`:

```bash
FLOW_EMAIL_AI="claude"
FLOW_EMAIL_AI_TIMEOUT=30
FLOW_EMAIL_PAGE_SIZE=25
FLOW_EMAIL_FOLDER="INBOX"
```

Or for project-specific settings, create `.flow/email.conf` in your project root.

## Daily Workflow: The 5-Minute Email Routine

Here's how I (DT) use `em` for efficient email management:

### 1. Quick Pulse (10 seconds)

```bash
$ em
em — quick pulse
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  3 unread

Recent:
  ID    * + From                 Subject                                  Date
  ───── ── ──────────────────── ──────────────────────────────────────── ──────────
  142   * + Alice Johnson        Re: STAT-101 Exam Grading Question       2026-02-10
  141     Bob Smith             Department Meeting Notes                 2026-02-10
  140   *   Carol Davis          Urgent: Grant Proposal Deadline          2026-02-09
  139     David Lee             Re: Paper Draft Comments                 2026-02-09
  138     Eve Martinez          Office Hours Schedule Change             2026-02-09

Full inbox: em i  Browse: em p  Help: em h
```

**What I see:**
- Unread count (ADHD dopamine hit when it's zero)
- Latest 10 emails with indicators:
  - `•` = unread
  - `★` = starred (flagged)
  - `+` = has attachment
- Quick next actions

### 2. Scan with fzf Picker (30 seconds)

```bash
$ em pick
```

This opens an interactive fzf picker:

```text
Folder: INBOX  |  Unread: 3
Enter=read  Ctrl-R=reply  Ctrl-S=summarize  Ctrl-T=catch  Ctrl-F=star  Ctrl-M=move  Ctrl-A=archive  Ctrl-D=delete
• = unread  ★ = starred  + = attachment
> •+ Alice Johnson       Re: STAT-101 Exam Grading Question  2026-02-10
  •  Carol Davis          Urgent: Grant Proposal Deadline     2026-02-09
     David Lee            Re: Paper Draft Comments            2026-02-09
     Eve Martinez         Office Hours Schedule Change        2026-02-09
  141/200
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Message #142 [NEW] [ATTACHMENT]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  From:     Alice Johnson <alice@university.edu>
  Subject:  Re: STAT-101 Exam Grading Question
  Date:     2026-02-10
  Flags:    [NEW] [ATTACHMENT]

──────────────────────────────────────────────────
  [email content preview...]
```

**Keyboard shortcuts:**
- `Enter` - Read selected email
- `Ctrl-R` - Reply to selected email
- `Ctrl-S` - Show AI summary
- `Ctrl-T` - Capture as task (via `catch`)
- `Ctrl-F` - Toggle star/flag
- `Ctrl-M` - Move to folder
- `Ctrl-A` - Archive (mark as read)
- `Ctrl-D` - Delete (with confirmation)

### 3. Read & Process (2-3 minutes)

```bash
# Read specific email
$ em read 142

# Smart rendering automatically detects:
# - HTML emails → w3m rendering
# - Markdown content → glow rendering
# - Plain text → bat syntax highlighting

# Reply with AI draft
$ em reply 142

# Your $EDITOR opens with:
From: me@example.com
To: Alice Johnson <alice@university.edu>
Subject: Re: STAT-101 Exam Grading Question

Hi Alice,

[AI-generated draft based on the original email]
Thanks for reaching out about the grading question.
I've reviewed the rubric and here's my assessment...

[Edit as needed, save, and close editor]

# Explicit confirmation (safety feature)
  Send this reply? [y/N] y
✅ Reply sent
```

### 4. Batch Process Remaining (1-2 minutes)

```bash
# Generate AI drafts for all actionable emails
$ em respond

Analyzing 20 emails for actionable messages...
  drafted #140: Urgent: Grant Proposal Deadline
  drafted #136: Student Office Hours Request
  drafted #131: Conference Paper Submission

3 drafts generated (17 skipped)
  Review: em respond --review

# Review and send (or skip)
$ em respond --review

# fzf picker with drafts, edit or send each
```

**Total time:** 5 minutes or less. Inbox zero achieved.

## Reading Email

### Shorthands

The dispatcher accepts convenient shorthand patterns:

```bash
em 42               # Shorthand for: em read 42
em -n 5             # Shorthand for: em inbox 5
em                  # Shorthand for: em dash (quick pulse)
```

### Quick Dashboard

```bash
em                  # or: em dash
```

Shows unread count + latest 10 emails. Perfect for a quick pulse check between tasks.

### List Inbox

```bash
em inbox            # Default page size (25)
em inbox 50         # Show 50 emails
em i                # Shortcut
em -n 10            # Shorthand for inbox 10
```

Output shows structured table with indicators:

```text
  ID    * + From                 Subject                                  Date
  ───── ── ──────────────────── ──────────────────────────────────────── ──────────
  142   * + Alice Johnson        Re: STAT-101 Exam Grading Question       2026-02-10
  141     Bob Smith             Department Meeting Notes                 2026-02-10
```

### Read Individual Email

```bash
em read <ID>        # or: em r <ID>
```

**Smart Rendering Pipeline:**

The `em` dispatcher automatically detects content type and chooses the best renderer:

1. **HTML Email** (contains `<html>`, `<body>`, `<div>` tags)
   - **w3m** (primary) - Best terminal HTML rendering
   - **lynx** (fallback) - Alternative HTML renderer
   - **pandoc** (fallback) - Converts HTML → plain text
   - **bat** (fallback) - Syntax highlighting
   - **cat** (final fallback) - Raw content

2. **Markdown Content** (contains `#`, `**`, ` ``` `, `- [ ]`)
   - **glow** (primary) - Beautiful markdown rendering
   - **bat** (fallback) - Syntax highlighting
   - **cat** (final fallback)

3. **Plain Text**
   - **bat** (primary) - Syntax highlighting + paging
   - **cat** (fallback)

4. **Markdown (explicit `--md` flag)**
   - **pandoc** converts HTML → Markdown with Outlook noise cleanup
   - **glow** (primary) - Beautiful markdown rendering
   - **bat** (fallback) - Syntax highlighting
   - Strips SafeLinks, Outlook attributes, fenced divs, CID refs

**Example:**

```bash
$ em read 142

# Automatically renders HTML newsletter with w3m:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
From: alice@university.edu
Subject: STAT-101 Exam Grading Question
Date: 2026-02-10
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Hi Prof. Davis,

I have a question about the grading rubric for Problem 3...
[rendered content with proper formatting]
```

### Force HTML Rendering

```bash
em html <ID>
```

Explicitly renders HTML emails in the terminal. Useful for HTML-heavy newsletters.

### Clean Markdown Rendering

```bash
em read --md <ID>
em read -M <ID>       # Short flag
```

Converts the HTML email to clean Markdown via pandoc, with a 7-stage Outlook cleanup pipeline:

1. **pandoc conversion** — HTML → Markdown
2. **SafeLinks extraction** — Resolves `nam02.safelinks.protection.outlook.com` wrappers to real URLs
3. **URL-decode** — `%3A` → `:`, `%2F` → `/`, etc.
4. **Outlook attribute removal** — Strips `{originalsrc="..."}`, `{style="..."}`, `.OWAAutoLink` blocks (multi-line aware)
5. **Fenced div stripping** — Removes `:::` / `::::` pandoc wrapper divs
6. **CID/backslash cleanup** — Strips `[cid:...]` image refs and lone `\` (pandoc `<br>`)
7. **Blank line collapsing** — 3+ blank lines → 2

**Requires:** `pandoc` (`brew install pandoc`)
**Rendering:** glow (primary) → bat (fallback) → plain text

**When to use:**
- Outlook/Exchange emails with heavy HTML formatting
- Newsletters with SafeLinks wrappers
- Any HTML email where you want readable, structured content

**Example:**

```bash
$ em read --md 42

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Message #42
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  From:     Alice Johnson <alice@university.edu>
  Subject:  Committee Meeting Follow-up
  Date:     2026-02-10

──────────────────────────────────────────────────

# Committee Meeting Notes

**Action Items:**

- Review the proposal by Friday
- Submit feedback via the [shared document](https://docs.example.com/proposal)

Let me know if you have questions.
```

### Raw MIME Export

```bash
em read --raw <ID>
```

Exports the full `.eml` MIME source. Useful for debugging email formatting, forwarding to other tools, or archiving.

### Email Noise Cleanup

When displaying emails, `em` automatically strips common noise patterns from Microsoft/Outlook and other clients:

- **CID image references** (`[cid:image001.png@...]`) — removed
- **Microsoft Safe Links** (`https://nam02.safelinks.protection...`) — removed
- **MIME markers** (`<#part type=...>`) — removed
- **Angle-bracket URLs** (`<https://...>`) — removed
- **Mailto inline** (`(mailto:user@example.com)`) — removed
- **Quoted lines** (`> original text`) — dimmed for visual separation
- **Signature blocks** (`--` separator onwards) — dimmed

This cleanup runs on all read operations, including the fzf preview in `em pick`.

### Unread Count

```bash
em unread           # INBOX
em unread Sent      # Specific folder
em u                # Shortcut
```

## Composing & Replying

### Reply to Email

```bash
em reply <ID>              # Basic reply
em reply <ID> --all        # Reply-all
em reply <ID> --no-ai      # Skip AI draft
em reply <ID> --batch      # Non-interactive (preview + confirm)
em reply <ID> --prompt "instructions"  # AI draft with custom instructions
em reply <ID> --backend gemini         # Override AI backend
```

**Interactive Flow (v2.0 Default — Two-Phase Safety Gate):**

1. `em` fetches the original email
2. If AI is enabled, generates a draft reply
3. Opens `$EDITOR` with draft pre-populated
4. You edit the draft as needed
5. Save and close `$EDITOR`
6. **Full preview shown** (headers + body)
7. Confirmation prompt `[y/N/e]` — default is **No**
8. Press `e` to re-open editor; `y` to send; anything else cancels

**Example:**

```bash
$ em reply 142

Generating AI draft...
✅ AI draft ready — edit in $EDITOR

# $EDITOR opens with pre-filled draft
# Edit as needed, save, close

─────────────────────────────────────────────────
  To:      alice@university.edu
  Subject: Re: STAT-101 Exam Grading Question
  ─────────────────────────────────────────────
  Hi Alice, thanks for reaching out. I've reviewed
  Problem 3 and the grading was applied correctly...
─────────────────────────────────────────────────

  Send this reply? [y/N/e] y
✅ Reply sent
```

**Bypass the preview (use with care):**

```bash
em reply 142 --force           # Skip preview, send immediately
em reply 142 --yes             # Same as --force
```

**Batch Mode (Non-Interactive):**

```bash
$ em reply 142 --batch

Fetching email #142...
Generating AI draft...

Draft Reply
────────────────────────────────────────────────────────
From: me@example.com
To: alice@university.edu
Subject: Re: STAT-101 Exam Grading Question
---
Hi Alice,

Thanks for reaching out. I've reviewed Problem 3...
────────────────────────────────────────────────────────

  Send this reply? [y/N] y
✅ Reply sent
```

**Reply-All:**

```bash
$ em reply 142 --all

# Includes all original recipients (To + Cc)
```

> **Safety Note:** Every send requires explicit `[y/N]` confirmation with default set to **No**. Hit Enter = No send.

### Compose New Email

```bash
em send                    # Interactive prompts
em send alice@example.com  # Pre-fill recipient
em send alice@example.com "Grant Proposal"  # Pre-fill recipient + subject
em send --ai alice@example.com "Weekly Report"  # AI draft from subject
em send --prompt "thank Alice for the report"  # AI compose from instructions (implies --ai)
em send --backend gemini alice@example.com "Report"  # Override AI backend
```

**Interactive Flow:**

1. Prompts for `To:` (if not provided)
2. Prompts for `Subject:` (if not provided)
3. If `--ai` flag: generates AI draft from subject line
4. Opens `$EDITOR` with draft (or blank if no AI)
5. You compose/edit the email
6. Save and close `$EDITOR`
7. Explicit confirmation prompt
8. Send on confirmation

**Example:**

```bash
$ em send

To: alice@university.edu
Subject: Office Hours Reminder

# $EDITOR opens with blank email template
# Compose email, save, close

─────────────────────────────────────────────────
  To:      alice@university.edu
  Subject: Office Hours Reminder
  ─────────────────────────────────────────────
  Hi Alice,

  Just a reminder that I have office hours on...
─────────────────────────────────────────────────

  Send this email? [y/N/e] y
✅ Email sent
```

**With AI Draft:**

```bash
$ em send --ai alice@university.edu "Weekly Status Update"

Generating AI draft from subject...
✅ AI draft ready — edit in $EDITOR

# $EDITOR opens with AI-generated draft about weekly status
# Edit/refine, save, close

  Send this email? [y/N/e] y
✅ Email sent
```

### Forward Email

```bash
em forward <ID>                         # Forward (opens $EDITOR for note)
em forward <ID> colleague@unm.edu       # Pre-fill recipient
em forward <ID> --prompt "see budget"   # AI-generated forwarding note
em forward <ID> --backend gemini        # Override AI backend
em fwd <ID>                             # Alias
```

**Interactive Flow:**

1. Fetches the original email
2. If `--prompt`: generates AI forwarding note; otherwise opens `$EDITOR`
3. Preview shown with forwarding note + original message
4. Confirmation prompt `[y/N/e]` — default is **No**

**Example — AI forward:**

```bash
$ em forward 42 colleague@unm.edu --prompt "FYI, see the budget section"

Generating AI forwarding note...
✅ AI note ready

───────────────────────────
To: colleague@unm.edu
Subject: Fwd: Q3 Budget Report
───────────────────────────
FYI — the budget section on page 3 has the numbers
you were asking about.

---------- Forwarded message ----------
[original email content]
───────────────────────────

  Send this email? [y/N/e] y
✅ Email forwarded
```

### Download Attachments

```bash
em attach <ID>                  # Download all attachments to ~/Downloads
em attach <ID> /tmp/files       # Download all to specific directory
em a <ID>                       # Shortcut

# v2.0: Targeted attachment operations
em attach list <ID>             # Show attachment table (name, MIME, size)
em attach get <ID> report.pdf   # Download specific file to ~/Downloads
em attach get <ID> report.pdf ~/Documents  # Download to custom directory
```

**Example — attachment list:**

```bash
$ em attach list 42

#  Name              Type              Size
─  ────────────────  ────────────────  ──────
1  agenda.pdf        application/pdf   142 KB
2  invite.ics        text/calendar     2 KB
3  notes.docx        application/mswd  58 KB

# Download just the ICS file
$ em attach get 42 invite.ics
✅ Saved invite.ics → ~/Downloads/invite.ics
```

## Folder Management (v2.0)

Create and delete mail folders directly from the terminal.

### Create a Folder

```bash
em create-folder "Team Updates"    # Create new folder
em cf "Team Updates"               # Alias
```

Folder names are sanitized automatically — characters unsafe for IMAP (backslash, quotes, etc.)
are rejected with a clear error message.

### Delete a Folder

Folder deletion requires typing the folder name to confirm (similar to GitHub repository deletion):

```bash
$ em delete-folder "Old Archive"

  This will permanently delete the folder "Old Archive" and all its contents.
  Type the folder name to confirm: Old Archive
✅ Folder "Old Archive" deleted
```

```bash
em delete-folder "Old Archive"    # Requires type-to-confirm
em df "Old Archive"               # Alias
```

> **Warning:** Folder deletion is permanent and cannot be undone. All messages in the folder
> are deleted. Move important emails first using `em move`.

---

## Calendar Integration (v2.0)

Parse ICS calendar attachments directly from email.

### Extract and View Calendar Events

```bash
em calendar 42     # Parse ICS attachment from email #42
em cal 42          # Alias
```

**Example output:**

```text
Event: Department Meeting
Date:  Thursday, March 5, 2026
Time:  2:00 PM – 3:30 PM (UTC-5)
Loc:   Room 401, Science Building
Org:   Dr. Smith <smith@university.edu>

Add to Apple Calendar? [y/N] y
✅ Event added to Calendar.app
```

**Behavior:**

- Scans email attachments for `.ics` / `text/calendar` MIME parts
- Parses DTSTART, DTEND, SUMMARY, LOCATION, ORGANIZER fields
- Displays a human-readable event card
- Optionally adds to Apple Calendar.app via `osascript` (macOS only)
- Requires `terminal-notifier` for confirmation notifications (optional)

**Apple Calendar integration:**

If you choose `y` at the prompt, `em calendar` creates the event in Apple Calendar. This uses
the same `_em_ics_create_event` function used by `em event` for AI-extracted events — but with
exact datetime precision from the ICS data instead of AI inference.

---

## IMAP Watch — Background Notifications (v2.0, Experimental)

`em watch` starts a background IMAP IDLE process that delivers desktop notifications when new
email arrives.

> **Experimental:** IMAP IDLE support depends on your mail server. Gmail, Fastmail, and most
> Exchange servers support it. Some servers may disconnect idle connections after a short timeout.

### Starting and Stopping

```bash
em watch start         # Start background watcher (daemonized)
em w start             # Alias

em watch stop          # Stop the watcher (sends SIGTERM)
em watch status        # Show PID, uptime, last activity
em watch log           # Tail the watcher log
```

**Start output:**

```text
Starting IMAP watcher for INBOX...
✅ Watcher started (PID 12345)
   Notifications via terminal-notifier
   Log: ~/.local/share/flow/em-watch.log
```

**Status output:**

```text
em watch: running (PID 12345, uptime 2h 14m)
  Folder: INBOX
  Last activity: 14 minutes ago (3 new messages)
  Notifications: terminal-notifier ✓
```

### Notification Behavior

When a new message arrives:
- A desktop notification appears via `terminal-notifier`
- Subject is truncated to 60 chars (injection-safe)
- Notification title is always "New Email" (static, not interpolated from message data)
- Clicking the notification opens the em dispatcher help

### Requirements

```bash
brew install terminal-notifier   # Desktop notifications
em doctor                        # Verify watcher dependencies
```

> **Note:** `em watch` requires `terminal-notifier` for notifications. Without it, the watcher
> runs silently in the background and only logs to file.

---

## AI Features Deep Dive

The `em` dispatcher includes optional AI features powered by Claude or Gemini. All AI operations are:
- **Cached** - Results stored with TTL to avoid redundant API calls
- **Timeout-protected** - Operations have per-type timeouts (10-30s)
- **Fallback-enabled** - Tries alternate backends on failure
- **Opt-in** - Set `FLOW_EMAIL_AI=none` to disable entirely

### AI Backends

Configure via environment variable:

```bash
export FLOW_EMAIL_AI="claude"    # Default (claude CLI)
export FLOW_EMAIL_AI="gemini"    # Google Gemini CLI
export FLOW_EMAIL_AI="none"      # Disable AI features
```

**Backend Selection:**

1. **claude** (primary) - Uses Claude Code CLI (`claude -p`)
   - Requires: `claude` in PATH
   - Timeout: 30s for drafts, 15s for summaries
   - Best for: Professional tone, detailed replies

2. **gemini** (fallback) - Uses Gemini CLI
   - Requires: `gemini` in PATH
   - Timeout: same as Claude
   - Best for: Quick responses, factual content

3. **none** - Disables all AI features
   - `em reply` opens blank draft
   - `em respond` unavailable
   - `em classify` / `em summarize` unavailable

**Fallback Chain:**

If the primary backend fails (timeout, not installed, API error), `em` automatically tries the next available backend:

```text
claude → gemini → fail gracefully
```

## AI Backend Switching

Switch AI backends at runtime without restarting your shell or editing config files.

### Quick Start

```bash
em ai                 # Show current backend status
em ai gemini          # Switch to Gemini (faster startup)
em ai claude          # Switch back to Claude
em ai toggle          # Cycle through available backends
em ai none            # Disable AI entirely
```

### Status Display

Running `em ai` with no arguments shows:

```text
Email AI Backend

  Current:     claude
  Available:   claude gemini
  Timeout:     30s
  Gemini args: -e none

  Switch: em ai claude | em ai gemini | em ai toggle
```

### Gemini Speed Optimization

Gemini CLI supports extra arguments via `FLOW_EMAIL_GEMINI_EXTRA_ARGS`. The default `-e none` skips extension
loading for faster startup:

```bash
# Default (fast, no extensions)
export FLOW_EMAIL_GEMINI_EXTRA_ARGS="-e none"

# Custom extensions
export FLOW_EMAIL_GEMINI_EXTRA_ARGS="-e my_extension"
```

### When to Use Each Backend

| Backend | Best For | Speed | Notes |
| --- | --- | --- | --- |
| `claude` | Complex drafts, nuanced classification | ~3-5s | Default, highest quality |
| `gemini` | Quick classification, summaries | ~1-2s | Faster with `-e none` |
| `none` | Offline, no AI needed | Instant | Falls back to manual |
| `auto` | Mixed workloads | Varies | Per-operation routing |

### Persistence

Backend selection persists for the current shell session via `FLOW_EMAIL_AI` env var. To make it permanent,
add to your config:

```bash
# In $FLOW_CONFIG_DIR/email.conf or .flow/email.conf
FLOW_EMAIL_AI=gemini
```

### Classify Email

```bash
em classify <ID>
em cl <ID>             # Shortcut
```

Categorizes an email into one of these types:

| Category | Description | Icon | Color |
| --- | --- | --- | --- |
| `student` | Student email: absence, question, grade inquiry, accommodation | S | blue |
| `colleague` | Faculty/staff discussion: hiring committee, research, departmental | C | green |
| `admin-action` | Requires YOUR action: accommodation letter, form, review request | ! | red |
| `scheduling` | Meeting request, calendar invite, event RSVP, office hours | @ | cyan |
| `urgent` | Deadline today, emergency, escalation, time-sensitive | U | red |
| `admin-info` | FYI only: university blast, mailing list, policy notice | i | dim |
| `newsletter` | Professional journal, academic association digest | N | dim |
| `vendor` | Commercial marketing, textbook promo, EdTech sales pitch | V | dim |
| `automated` | CI/CD, GitHub, system alerts, delivery receipts | A | dim |

**Example:**

```bash
$ em classify 142
  S student
```

**Use Case:**

```bash
# Classify before deciding how to handle
category=$(em classify 142)
if [[ "$category" == "urgent" ]]; then
    em reply 142 --batch  # Quick response
else
    em reply 142          # Take time to craft response
fi
```

### Summarize Email

```bash
em summarize <ID>
em sum <ID>            # Shortcut
```

Generates a one-line summary (max 80 characters) focused on: **who wants what and by when**.

**Example:**

```bash
$ em summarize 142
  Summary: Alice needs clarification on exam Problem 3 grading by Friday
```

**Use Case:**

```bash
# Quick scan of multiple emails
for id in {140..145}; do
    echo -n "$id: "
    em summarize $id
done
```

### Batch Draft Generation

```bash
em respond                  # Full flow: classify → draft → $EDITOR → send
em respond -n 50            # Process latest 50 emails (default: 10)
em respond --review         # Review/send cached drafts (skip classification)
em respond --dry-run        # Classify only (see what's actionable, no drafts)
em respond --folder Sent    # Process specific folder
em respond --clear          # Clear draft cache
```

**How it works:**

1. Fetches latest N emails from inbox
2. Classifies each email (AI)
3. Skips non-actionable categories (newsletter, automated, admin-info, vendor)
3a. Auto-skips listserv emails (`@LIST.*`, `*-L@*`) before classification
3b. Shows warning banner if actionable email was sent to a mailing list
4. For each actionable email: generates AI draft, opens in `$EDITOR`, confirms send
5. You can quit partway through (`q`) — remaining drafts stay cached
6. Come back later with `em respond --review` to continue

**Example:**

```bash
$ em respond

Analyzing 20 emails for actionable messages...
  drafted #142: Re: STAT-101 Exam Grading Question
  drafted #140: Re: Urgent: Grant Proposal Deadline
  drafted #136: Re: Office Hours Request

3 drafts generated (17 skipped)
  Review: em respond --review
```

**Review Cached Drafts:**

```bash
$ em respond --review

em respond --review — reviewing cached drafts in INBOX
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ✓ #142  Alice Johnson  Re: STAT-101 Exam Grading Question
  ✓ #140  Carol Davis    Urgent: Grant Proposal Deadline
  ✓ #136  Bob Smith      Office Hours Request

  3 cached drafts found in 20 emails
  Review 3 cached drafts? [Y/n] y

# For each draft:
#   - Shows original email snippet
#   - Loads cached draft into $EDITOR
#   - Confirm send [y/N]
#   - Continue to next? [Y/n/q]
```

**Dry Run (Classify Only):**

```bash
$ em respond --dry-run

# Shows classification results without generating drafts
# Useful to preview what's actionable before committing time
```

**Clear Draft Cache:**

```bash
$ em respond --clear
✅ Email cache cleared (2.4M freed)
```

### Listserv Safety

`em respond` includes two layers of protection against accidentally replying to mailing lists:

**Layer 1: Pre-classification skip.** Emails addressed to `*@LIST.*`, `*@list.*`, or `*-L@*` are
auto-skipped before AI classification. They appear as:

```text
  [3/10] graduation@unm.edu        L listserv — skip
```

**Layer 2: Warning banner.** If an actionable email was sent to a list-like address, a warning appears
before drafting:

```text
  ⚠ WARNING: This email was sent to a mailing list
    Replying may go to ALL list members. Review carefully.
```

### Discard Detection

When reviewing drafts, himalaya offers "Send it" and "Discard it" options. `em` properly detects both
outcomes using `script(1)` to capture the interactive terminal output:

- **Send** — Counted as replied, marked in cache
- **Discard** — Counted as skipped, not marked as replied
- **Error** — Logged as warning, counted as skipped

This prevents the counter from showing "1 replied" when you actually chose to discard.

### AI Timeouts

Each AI operation has a specific timeout to prevent hanging:

| Operation | Timeout | Reason |
| --- | --- | --- |
| classify | 10s | Quick category decision |
| summarize | 15s | One-line summary generation |
| draft | 30s | Full reply composition |
| schedule | 15s | Extract dates/times |

Configure global timeout:

```bash
export FLOW_EMAIL_AI_TIMEOUT=45  # Increase to 45s for all ops
```

### Prompt Customization

AI prompts are defined in `lib/em-ai.zsh`. Currently, the only way to customize prompts is to edit the
library file directly. Custom prompt templates are planned for a future version.

## Email-to-Task Capture

Convert emails into quick-capture tasks with `em catch`. Uses AI to generate a one-line summary, then pipes
it to the `catch` command.

### Basic Usage

```bash
em catch 42           # Summarize email #42 → pipe to catch
em catch 99           # Summarize email #99 → pipe to catch
```

### How It Works

1. Reads the email content via himalaya
2. AI generates a one-line summary (using the summarize prompt)
3. Formats as "Email #42: [summary]"
4. Pipes to `catch` command (if available)
5. Falls back to display-only if `catch` is not installed

### Fallback Chain

| Condition | Behavior |
| --- | --- |
| AI available + catch installed | AI summary → catch → "Captured: ..." |
| AI available, no catch | AI summary → display for manual capture |
| No AI, has jq | Falls back to email subject line |
| No AI, no jq | Error: "Could not generate summary" |

### From the Email Picker

Press **Ctrl-T** in `em pick` to capture the highlighted email as a task — no need to exit the picker first.

```bash
em pick               # Browse emails
# Ctrl-T on any email → instant capture
```

## Organize: Star, Move, Thread, Snooze, Digest

These commands help you organize your inbox beyond read/reply — star important emails, move them between folders, view conversation threads, snooze for later, and get AI-grouped digests.

### Star / Flag

Toggle the IMAP `Flagged` flag on an email:

```bash
em star 42              # Toggle star on email #42
em flag 42              # Alias for em star
```

**Output:**

```text
★ Starred #42 — Re: STAT-101 Exam Grading Question
```

Run again to unstar:

```text
☆ Unstarred #42 — Re: STAT-101 Exam Grading Question
```

**List all starred emails:**

```bash
em starred

# Output:
em starred — flagged emails
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ID     From              Subject                              Date
  ───── ─────────────────── ──────────────────────────────────── ──────────
  142    Alice Johnson      Re: STAT-101 Exam Grading Question   2026-02-10
  140    Carol Davis        Urgent: Grant Proposal Deadline       2026-02-09
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2 starred emails
```

### Move

Move an email to a different folder:

```bash
em move 42 Archive      # Move to Archive (with confirmation)
em move 42              # fzf folder picker (requires fzf)
em mv 42 Trash          # Alias
```

**With explicit folder:**

```text
Move #42 → Archive? [y/N] y
✅ Moved #42 to Archive
```

**Without folder (fzf picker):**

Opens an interactive folder picker. Select a folder with Enter, or press Escape to cancel.

### Thread

View the conversation thread for an email — finds related messages by `References` / `In-Reply-To` headers and displays them chronologically:

```bash
em thread 42            # Show thread for email #42
em th 42                # Alias
```

**Output:**

```text
em thread — conversation for #42
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  #138   Alice Johnson     STAT-101 Exam Grading Question    2026-02-08
  #140   You               Re: STAT-101 Exam Grading...      2026-02-09
→ #142   Alice Johnson     Re: STAT-101 Exam Grading...      2026-02-10
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
3 messages in thread
```

The `→` arrow marks the message you started from. If the email is standalone (no thread), you'll see:

```text
This is a standalone message (no thread found)
```

### Snooze

Snooze an email — moves it to the `Snoozed` folder and tracks a wake-up time locally:

```bash
em snooze 42 2h         # Snooze for 2 hours
em snooze 42 1d         # Snooze for 1 day
em snooze 42 3w         # Snooze for 3 weeks
em snooze 42 tomorrow   # Snooze until tomorrow 9:00 AM
em snooze 42 monday     # Snooze until next Monday 9:00 AM
em snz 42 2h            # Alias
```

**Output:**

```text
💤 Snoozed #42 until 2026-02-18 14:30
   Re: STAT-101 Exam Grading Question
```

**Supported time formats:**

| Format | Example | Meaning |
|--------|---------|---------|
| `Nh` | `2h` | N hours from now |
| `Nd` | `1d` | N days from now |
| `Nw` | `3w` | N weeks from now |
| `tomorrow` | `tomorrow` | Next day at 9:00 AM |
| Day name | `monday` | Next occurrence at 9:00 AM |

**List snoozed emails:**

```bash
em snoozed

# Output:
em snoozed — pending reminders
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ID     Subject                              Wake          Spec
  ───── ──────────────────────────────────── ────────────── ──────
  42     Re: STAT-101 Exam Grading...        READY          2h
  99     Budget Proposal                     in 3h          1d
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2 snoozed emails (1 ready)
```

`READY` means the snooze time has passed — time to handle it.

> **Note:** Snooze tracking is local (stored in `~/.flow/email-snooze/`). The IMAP move to `Snoozed` folder requires your mail server to have that folder. If not, the local tracking still works.

### Digest

Get an AI-grouped summary of today's or this week's emails:

```bash
em digest               # Today's emails
em digest --week        # This week's emails
em digest -n 5          # Limit to 5 emails
em dg                   # Alias
```

**Output (with AI):**

```yaml
em digest — 2026-02-18
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Priority:
  142  * Alice Johnson     Re: STAT-101 Exam Grading...    student
  140  * Carol Davis       Urgent: Grant Proposal...       urgent

Informational:
  141    Bob Smith         Department Meeting Notes        admin-info
  139    David Lee         Re: Paper Draft Comments        colleague

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
4 emails today (2 unread)
```

**Output (without AI):**

Falls back to unread/read grouping instead of AI priority classification.

### em pick Organize Keybindings

The fzf email picker (`em pick`) includes keybindings for organize commands:

| Key | Action |
|-----|--------|
| `Ctrl-F` | Toggle star/flag on selected email |
| `Ctrl-M` | Move selected email (opens folder picker) |

These work alongside existing keybindings (`Enter`=read, `Ctrl-R`=reply, `Ctrl-S`=summarize, etc.).

## Interactive Browsing: em pick

The `em pick` command provides a powerful fzf-based email browser with live preview.

```bash
em pick              # Browse INBOX
em pick Sent         # Browse Sent folder
em p                 # Shortcut
```

### Interface Layout

```text
Folder: INBOX  |  Unread: 3
Enter=read  Ctrl-R=reply  Ctrl-S=summarize  Ctrl-T=catch  Ctrl-F=star  Ctrl-M=move  Ctrl-A=archive  Ctrl-D=delete
• = unread  ★ = starred  + = attachment
> •+ Alice Johnson       Re: STAT-101 Exam Grading Question  2026-02-10
  •  Carol Davis          Urgent: Grant Proposal Deadline     2026-02-09
     David Lee            Re: Paper Draft Comments            2026-02-09
│━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
│  Message #142 [NEW] [ATTACHMENT]
│━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
│
│  From:     Alice Johnson <alice@university.edu>
│  Subject:  Re: STAT-101 Exam Grading Question
│  Date:     2026-02-10
│
│──────────────────────────────────────────────────
│  [First 60 lines of email content...]
```

**Left Panel:** Email list with indicators
**Right Panel:** Live preview of selected email

### Keybindings

| Key | Action | Description |
| --- | --- | --- |
| `Enter` | Read | Open selected email with smart rendering |
| `Ctrl-R` | Reply | Generate AI draft and open in $EDITOR |
| `Ctrl-S` | Summarize | Show one-line AI summary |
| `Ctrl-T` | Catch | Capture email as task via `catch` command |
| `Ctrl-A` | Archive | Mark email as read |
| `Ctrl-F` | Star | Toggle star/flag on selected email |
| `Ctrl-M` | Move | Move email to folder (opens folder picker) |
| `Ctrl-D` | Delete | Flag email as deleted (with confirmation) |
| `Esc` / `Ctrl-C` | Exit | Close picker without action |

### Indicators

| Symbol | Meaning |
| --- | --- |
| `*` | Unread email |
| `+` | Has attachment |
| `[NEW]` | Unread (in preview) |
| `[FLAGGED]` | Marked as important |
| `[REPLIED]` | Already replied to |

### Example Session

```bash
$ em pick

# Use arrow keys to navigate
# Preview updates automatically

# Press Ctrl-S on an email
  Summary: Student needs exam grading clarification by Friday

# Press Ctrl-R to reply
Generating AI draft...
✅ AI draft ready — edit in $EDITOR

# Edit draft, save, close
  Send this reply? [y/N] y
✅ Reply sent

# Continue browsing or press Esc to exit
```

## Search

```bash
em find <query>
em f <query>           # Shortcut
```

Searches across email metadata (subject, sender name, sender address). Client-side filtering for speed.

**Example:**

```bash
$ em find "quarterly report"

Searching: quarterly report

42    john@corp.com        Quarterly Report Q4 2025     2026-01-15
31    reports@bi.com       Re: Quarterly Performance    2026-01-08
28    alice@dept.edu       Quarterly Teaching Summary   2026-01-05

3 results
```

**Search Tips:**
- Searches are case-insensitive
- Searches subject + sender name + sender email
- Matches partial strings
- Limited to last 100 emails (performance)

## Email Management

### List Folders

```bash
em folders
```

Shows all available mail folders:

```text
INBOX
Sent
Drafts
Trash
Archive
```

### Delete Emails

```bash
em move 42 Archive      # Move email to Archive (with confirmation)
em move 42              # Move with fzf folder picker
em inbox Sent           # List sent emails
em pick Archive         # Browse archive folder
# Delete by ID (moves to Trash)
em delete 42                     # Single ID
em del 42 43 44                  # Batch delete (aliases: del, rm)

# Delete by folder (all emails in folder)
em delete --folder Spam          # Shows count, requires [y/N]

# Delete by search query
em delete --query "newsletter"   # Shows matching subjects, requires [y/N]

# Interactive delete (fzf multi-select)
em delete --pick                 # Tab to select, Enter to confirm

# PERMANENT delete (purge)
em delete --purge 42             # Flag as Deleted + EXPUNGE
em delete --folder Trash --purge # Purge entire Trash
```

**Safety levels:**

Star/flag emails directly:

```bash
em star 42              # Toggle Flagged flag
em starred              # List all flagged emails
```

Or use the fzf picker (`em pick`) with `Ctrl-F` to toggle star on the selected email.

Lower-level flag management is available via `lib/em-himalaya.zsh` adapter:

```bash
_em_hml_flags add <ID> Seen       # Mark as read
_em_hml_flags add <ID> Flagged    # Mark as flagged
_em_hml_flags add <ID> Deleted    # Mark as deleted
```

| Mode | Confirmation | Reversible? |
|------|-------------|-------------|
| `em delete <ID>` | `[y/N]` (default No) | Yes (in Trash) |
| `em delete --folder` | Subject preview + `[y/N]` | Yes (in Trash) |
| `em delete --query` | Subject preview + `[y/N]` | Yes (in Trash) |
| `em delete --purge` | Must type full word `yes` | **No** |

### Move Emails

```bash
# Move to folder
em move Archive 42               # INBOX → Archive
em mv Archive 10 20 30           # Batch move

# Move from specific source folder
em move --from Sent Archive 42   # Sent → Archive
```

### Restore from Trash

```bash
# Restore to INBOX (default)
em restore 42

# Restore to specific folder
em restore 42 --to Archive

# Batch restore
em restore 10 20 30
```

### Flag / Unflag

```bash
# Star emails (IMAP Flagged)
em flag 42                       # Single
em fl 42 43                      # Batch (alias: fl)

# Remove star
em unflag 42
em unflag 42 43                  # Batch
```

### Extract Action Items (AI)

```bash
em todo 42                       # AI extracts action items
em td 42 43                      # Batch (alias: td)
```

Shows numbered list of action items, captures to `catch`, and optionally adds to macOS Reminders.app.

### Extract Calendar Events (AI)

```bash
em event 42                      # AI extracts dates/times/meetings
em ev 42 43                      # Batch (alias: ev)
```

Shows event details (title, date, time, duration, location), captures to `catch`, and optionally adds to macOS Calendar.app.

## Cache System

All AI operations are cached with time-to-live (TTL) to avoid redundant API calls and improve response times.

### Cache Structure

```text
.flow/email-cache/              # Project-local (if in project)
  summaries/<hash>.txt          # One-line summaries
  classifications/<hash>.txt    # Category classifications
  drafts/<hash>.txt             # Generated reply drafts
  schedules/<hash>.json         # Extracted dates/times
  unread/<hash>.txt             # Unread counts
```

Or globally:

```text
$FLOW_DATA_DIR/email-cache/
  (same structure)
```

### TTL Values

| Cache Type | TTL | Reason |
| --- | --- | --- |
| summaries | 24 hours | Summaries don't change |
| classifications | 24 hours | Category is stable |
| drafts | 1 hour | Drafts might need refreshing |
| schedules | 24 hours | Date extraction is stable |
| unread | 1 minute | Count changes frequently |

### Cache Commands

```bash
em cache stats         # Show cache size, per-op counts, expired count
em cache prune         # Remove expired entries only (report count)
em cache clear         # Clear all cached AI results (report freed space)
em cache warm [N]      # Pre-warm latest N emails (default: 10, background)
```

**Stats Output:**

```bash
$ em cache stats

Email Cache
  summaries          42 items  128K  (3 expired)
  classifications    38 items   12K  (1 expired)
  drafts             5 items    24K
  schedules          8 items    16K
  Location: .flow/email-cache
```

**Prune Expired Entries:**

```bash
$ em cache prune
✅ Pruned 4 expired cache entries
```

Prune only removes entries past their TTL — fresh items are untouched.

**Clear Cache:**

```bash
$ em cache clear
✅ Email cache cleared (2.4M freed)
```

**Warm Cache (Background):**

```bash
$ em cache warm 20

# Runs in background:
# - Fetches latest 20 emails
# - Classifies each (AI)
# - Summarizes each (AI)
# - Caches results
# - Does NOT block shell
```

> **Tip:** Run `em cache warm` at the start of your work session to pre-populate summaries for faster browsing.

### Auto-Prune & Auto-Warm

`em dash` (or plain `em`) automatically triggers background housekeeping on startup:

- **Auto-prune**: removes expired cache entries (non-blocking)
- **Auto-warm**: pre-classifies + summarizes latest 10 emails (background)

This means your cache stays clean and pre-warmed without manual intervention.

### Cache Size Cap

The cache enforces a maximum size to prevent unbounded growth:

```bash
FLOW_EMAIL_CACHE_MAX_MB=50      # Default: 50 MB
FLOW_EMAIL_CACHE_MAX_MB=0       # Disable size cap
```

When the cache exceeds this limit, the oldest files are evicted first (LRU -- Least Recently Used). Eviction
runs automatically after every cache write as a non-blocking background process.

### Cache Invalidation

Cache is automatically invalidated when:
- You reply to an email (draft cache cleared for that message)
- TTL expires (pruned on next access or `em cache prune`)
- Cache exceeds size cap (LRU eviction)
- You explicitly run `em cache clear`

## Configuration Reference

### Environment Variables

| Variable | Default | Description |
| --- | --- | --- |
| `FLOW_EMAIL_AI` | `claude` | AI backend: `claude`, `gemini`, `none` |
| `FLOW_EMAIL_AI_TIMEOUT` | `30` | AI timeout in seconds |
| `FLOW_EMAIL_PAGE_SIZE` | `25` | Default inbox page size |
| `FLOW_EMAIL_FOLDER` | `INBOX` | Default folder |
| `FLOW_EMAIL_CACHE_MAX_MB` | `50` | Max cache size in MB (0 = no limit) |
| `FLOW_EMAIL_CACHE_WARM` | `false` | Enable background cache warming on `em dash` |
| `EDITOR` | `nvim` | Editor for composing emails |

### Config Files

**Priority (highest to lowest):**

1. `.flow/email.conf` (project-local)
2. `~/.config/flow/email.conf` (global)
3. Environment variables
4. Built-in defaults

**Example Config File:**

```bash
# ~/.config/flow/email.conf

# AI Configuration
FLOW_EMAIL_AI="claude"
FLOW_EMAIL_AI_TIMEOUT=45

# Display Configuration
FLOW_EMAIL_PAGE_SIZE=50
FLOW_EMAIL_FOLDER="INBOX"

# Editor
EDITOR="nvim"
```

### himalaya Configuration

See [himalaya docs](https://pimalaya.org/himalaya/cli/latest/configuration/index.html) for complete reference.

**Key Settings:**

- `~/.config/himalaya/config.toml` - Main config
- Multiple accounts supported
- OAuth2 via email-oauth2-proxy
- IMAP IDLE for real-time notifications

## Architecture

The `em` dispatcher follows a clean 6-layer architecture:

```text
┌─────────────────────────────────────────┐
│ em (dispatcher)                          │  User-facing commands
│ lib/dispatchers/email-dispatcher.zsh    │  Routing + help system
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│ Adapter Layer (himalaya)                 │  CLI isolation
│ lib/em-himalaya.zsh                      │  All himalaya specifics
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│ AI Layer (optional)                      │  AI backend abstraction
│ lib/em-ai.zsh                            │  claude/gemini/fallback
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│ Cache Layer                              │  TTL-based caching
│ lib/em-cache.zsh                         │  Reduce AI calls
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│ Render Layer                             │  Content detection
│ lib/em-render.zsh                        │  HTML/markdown/plain
└─────────────────────────────────────────┘
              ↓
┌─────────────────────────────────────────┐
│ himalaya CLI                             │  IMAP/SMTP backend
│ (external)                               │  Handles actual email
└─────────────────────────────────────────┘
```

### Design Principles

1. **Adapter Pattern** - All himalaya CLI specifics are isolated in `lib/em-himalaya.zsh`. If himalaya changes
   its CLI, fix only one file.

2. **Fail-Safe Fallbacks** - Every operation has fallbacks:
   - HTML rendering: w3m → lynx → pandoc → bat → cat
   - AI backend: claude → gemini → none (graceful degradation)
   - Cache miss: always fetch fresh

3. **Explicit Confirmations** - Every send operation requires explicit `[y/N]` with default set to **No**.

4. **Stateless** - No persistent state except caches (which can be cleared). Email state lives in IMAP server.

5. **Pure ZSH** - No Node.js, Python, or Ruby runtime required. Just ZSH + himalaya + optional tools.

### Why himalaya?

[himalaya](https://github.com/pimalaya/himalaya) was chosen as the backend because:

- **Stable CLI** - Semver-guaranteed, predictable interface
- **Multiple protocols** - IMAP, Maildir, Notmuch
- **Multiple accounts** - Easy switching
- **OAuth2 support** - Works with Gmail/Outlook
- **Active development** - Regular releases, responsive maintainers
- **Pure Rust** - Fast, safe, cross-platform

The adapter pattern means we could swap backends in the future without changing the `em` interface.

## Troubleshooting

### "himalaya not found"

**Error:**

```text
❌ himalaya not found
Install: brew install himalaya or cargo install himalaya
```

**Solution:**

```bash
# Option 1: Homebrew (recommended)
brew install himalaya

# Option 2: Cargo (cross-platform alternative)
cargo install himalaya

# Verify
himalaya --version
```

### "himalaya cannot connect to mailbox"

**Error:**

```text
❌ himalaya cannot connect to mailbox
Check config: himalaya account list
```

**Solution:**

```bash
# Check accounts
himalaya account list

# Test connection
himalaya envelope list --page-size 1

# Reconfigure if needed
himalaya account configure
```

**Common causes:**
- Wrong IMAP credentials
- OAuth2 token expired
- Server hostname/port incorrect
- Firewall blocking IMAP (port 993)

### AI features not working

**Error:**

```text
⚠️  Classification failed (no AI backend available?)
```

**Solution:**

```bash
# Check which backends are installed
command -v claude
command -v gemini

# Install Claude Code CLI
# See https://claude.ai/docs

# Or use Gemini
pip install google-generativeai

# Or disable AI entirely
export FLOW_EMAIL_AI="none"
```

### HTML emails not rendering properly

**Error:**

```text
[Raw HTML output with tags visible]
```

**Solution:**

```bash
# Install preferred HTML renderer
brew install w3m

# Or fallback options
brew install lynx
brew install pandoc

# Verify
em doctor
```

### Cache taking up too much space

**Check cache size:**

```bash
em cache stats
```

**Clear cache:**

```bash
em cache clear
```

**Reduce cache lifetime (edit `lib/em-cache.zsh`):**

```bash
typeset -gA _EM_CACHE_TTL=(
    [summaries]=3600       # 1 hour instead of 24
    [classifications]=3600 # 1 hour instead of 24
    [drafts]=1800          # 30 min instead of 1 hour
)
```

### fzf picker not showing preview

**Requirements:**

```bash
brew install fzf
brew install jq
```

**Check:**

```bash
em doctor
```

### Editor not opening for compose/reply

**Check EDITOR variable:**

```bash
echo $EDITOR
```

**Set in ~/.zshrc:**

```bash
export EDITOR="nvim"    # or vim, nano, etc.
```

## Safety Design

The `em` dispatcher is designed with multiple safety layers to prevent accidental sends.

> **v2.0 Breaking Change:** `em send` and `em reply` now show a **full preview** before the
> confirmation prompt. Use `--force` to bypass. The prompt is now `[y/N/e]` where `e` re-opens
> the editor for last-minute edits.

### 1. Two-Phase Safety Gate (v2.0)

Every send operation goes through the `_em_safety_gate` function:

```bash
─────────────────────────────────────────────────────────
  To:      alice@university.edu
  Subject: Re: STAT-101 Exam Grading Question
  ───────────────────────────────────────────────────────
  Hi Alice, thanks for reaching out. I've reviewed
  Problem 3 and the grading was correct...
─────────────────────────────────────────────────────────

  Send this email? [y/N/e]
  y = send now   N = discard (default)   e = edit again
```

**Behavior:**
- **Default is No** — Hitting Enter = no send
- **`e`** — Re-opens `$EDITOR` for revisions (loop repeats)
- **`y` or `Y`** — Sends immediately
- **`--force` / `--yes`** — Bypasses the gate entirely (for scripts/automation)

### 2. Draft Preservation

Rejected sends automatically preserve the draft for later:

```bash
# Drafts saved to:
$FLOW_DATA_DIR/email-drafts/    # Global draft storage
```

AI-generated drafts are also cached in `.flow/email-cache/drafts/` with a 1-hour TTL. Use
`em respond --review` to come back to cached drafts.

### 3. Preview Always Shown (v2.0 Change)

In v2.0, the preview is shown for **all** send paths — not just batch mode:

| Mode | Before v2.0 | v2.0 |
| ---- | ----------- | ----- |
| `em send` (interactive) | Preview shown before `[y/N]` | Preview + `[y/N/e]` gate |
| `em reply` (interactive) | Preview shown before `[y/N]` | Preview + `[y/N/e]` gate |
| `em reply --batch` | Preview + `[y/N]` | Preview + `[y/N]` (no editor step) |
| `em send --force` | n/a | Skip gate, send immediately |
| `em respond --review` | Per-draft `[y/N]` | Per-draft `[y/N]` (unchanged) |

### 4. Editor Interception

In interactive mode, you always edit in $EDITOR before the gate:

```bash
em reply 42

# 1. AI generates draft (if enabled)
# 2. $EDITOR opens with draft
# 3. You edit/review
# 4. Save and close
# 5. Full preview shown
# 6. [y/N/e] gate — press 'e' to loop back to editor
```

### 5. Batch Mode Safety

Even `em respond` (batch draft generation) doesn't auto-send:

```bash
$ em respond

# Generates drafts, caches them
3 drafts generated (17 skipped)
  Review: em respond --review

# Manual review + send
$ em respond --review

# Each draft requires individual confirmation
```

### 6. No Auto-Reply

There is **no** auto-reply feature. Every reply requires:
1. Manual invocation (`em reply`)
2. Manual confirmation (or `--force` for scripted automation)

### Why Default-No?

ADHD-optimized design means removing friction, but email sends are **permanent**. Default-No ensures:

- Muscle memory doesn't cause accidental sends
- Quick "Enter" to continue reviewing emails
- Deliberate "y" + "Enter" to actually send

This is intentionally **opposite** of typical web UI patterns where buttons default to "Yes" or "Continue".

## Common Workflows

### Morning Email Triage (5 minutes)

```bash
# 1. Quick pulse
em

# 2. Scan inbox
em pick

# 3. Use keyboard shortcuts:
#    - Ctrl-S for summaries
#    - Ctrl-A to archive newsletters
#    - Ctrl-R to reply to urgent emails

# 4. Generate drafts for remaining actionable emails
em respond

# Done - inbox triaged
```

### Reply to Urgent Email

```bash
# Option 1: Direct reply (interactive)
em reply 142

# Option 2: Batch reply (faster)
em reply 142 --batch

# Both provide AI draft, both require confirmation
```

### Review Emails from Specific Person

```bash
# Search for sender
em find "alice"

# Get their recent messages
42    alice@university.edu    Re: Exam Question    2026-02-10
31    alice@university.edu    Office Hours         2026-02-08

# Read and reply
em read 42
em reply 42
```

### Process All Actionable Emails

```bash
# Generate drafts for all actionable emails
em respond -n 50

# Review and send (one by one)
em respond --review

# Or manually review specific drafts via cache
```

### Weekly Newsletter Cleanup

```bash
# Pick newsletters via fzf
em pick

# Use search to filter
em find "newsletter"

# Ctrl-A to archive each one
```

## New in v2.0

### Calendar Integration (ICS Parsing)

Parse ICS calendar attachments directly from email and optionally add events to Apple Calendar:

```bash
em calendar 42              # Parse ICS from email #42
em cal 42                   # Alias
```

**How it works:**

1. Reads the email and finds ICS/iCalendar attachments (`.ics` or `text/calendar` MIME type)
2. Parses the ICS file using a pure ZSH parser (RFC 5545 compliant)
3. Displays an event card with title, date, time, location, and organizer
4. Prompts to add to Apple Calendar via AppleScript

```text
em calendar — ICS event from email #42
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Event:     Department Meeting
  Date:      Thursday, March 5, 2026
  Time:      2:00 PM - 3:30 PM
  Location:  Room 204, Science Building
  Organizer: chair@dept.edu
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Add to Apple Calendar? [y/N]
```

**Security:** ICS files are limited to 1MB and 10 events per file. AppleScript values are sanitized to prevent injection.

### IMAP Watch (Background Notifications)

Monitor your inbox in the background with IMAP IDLE and get desktop notifications for new email:

```bash
em watch start              # Start background watcher
em watch stop               # Stop the watcher
em watch status             # Show PID and uptime
em watch log                # Tail the watch log
em w start                  # Alias
```

**Status output:**

```text
em watch: running (PID 12345, uptime 2h 14m)
```

**Requirements:** `terminal-notifier` (`brew install terminal-notifier`) for desktop notifications.

**How it works:**

1. Launches a background subshell that connects to IMAP IDLE
2. On new email: sends a desktop notification via `terminal-notifier`
3. PID and log are tracked in `$FLOW_DATA_DIR/email-watch/`
4. Rate-limited to prevent notification storms (max 1 per 5 seconds)

**Security:** Notification titles use a static "New Email" string (no user-controlled content in `-execute` flag). The `-execute` flag is never used to prevent RCE.

> **Experimental:** `em watch` is marked experimental. It works well for single-account setups but may not handle all IMAP server disconnects gracefully.

### Enhanced Attachments

Download all, list, or selectively download attachments:

```bash
# Download all attachments
em attach 42                # Save to ~/Downloads (default)
em attach 42 ~/Documents   # Save to custom directory

# List attachments with metadata
em attach list 42
```

**List output:**

```text
em attach — attachments for email #42
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  #  Name           Type              Size
  ─  ─────────────  ────────────────  ──────
  1  agenda.pdf     application/pdf   142 KB
  2  invite.ics     text/calendar     2 KB
  3  budget.xlsx    application/xlsx  45 KB
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
3 attachments
```

```bash
# Download a specific file by name
em attach get 42 agenda.pdf
em attach get 42 agenda.pdf ~/Documents   # Custom directory
```

### Folder Management

Create and delete mail folders on your IMAP server:

```bash
# Create a new folder
em create-folder "Project X"
em cf "Project X"           # Alias

# Delete a folder (type-to-confirm)
em delete-folder "Old Archive"
em df "Old Archive"         # Alias
```

**Delete confirmation:**

```text
Delete folder "Old Archive"?
Type the folder name to confirm: _
```

You must type the exact folder name to proceed — a safety gate to prevent accidental deletion.

### Version Detection

`em` detects the installed himalaya version and enables features progressively:

```bash
em version                  # Show himalaya version info
```

The `_em_hml_version_gte` function gates features by version. `em doctor` reports which progressive-enhancement features are available.

---

## Next Steps

Now that you understand the `em` dispatcher:

1. **Set up himalaya** - Configure your email accounts
2. **Install optional tools** - fzf, bat, w3m for enhanced experience
3. **Configure AI** - Set `FLOW_EMAIL_AI` to your preferred backend
4. **Run `em doctor`** - Verify your setup
5. **Try the 5-minute routine** - `em` → `em pick` → `em reply` → `em respond`
6. **Customize shortcuts** - Add `alias mail=em` to your `.zshrc`

## See Also

### Tutorials

- [Tutorial 35: Email from the Terminal](../tutorials/35-em-cli-email.md) — Core email workflow (20 min)
- [Tutorial 36: Email Management](../tutorials/36-em-delete-actions.md) — Delete, move, flag, extract (20 min)
- [Tutorial 46: em v2.0 Features](../tutorials/46-em-v2-features.md) — Calendar, watch, folders, safety gate (15 min)
- [Tutorial 33: Email in Neovim](../tutorials/33-himalaya-email.md) — Neovim-native email with AI actions

### References

- [Email Refcard](../reference/REFCARD-EMAIL-DISPATCHER.md) — All 38 commands at a glance
- [Email Cookbook](EMAIL-COOKBOOK.md) — Practical recipes for common workflows
- [EM-V2-ARCHITECTURE.md](../internal/EM-V2-ARCHITECTURE.md) — Internal architecture documentation
- [MASTER-DISPATCHER-GUIDE](../reference/MASTER-DISPATCHER-GUIDE.md) — All 15 dispatchers

### External

- **himalaya docs:** https://pimalaya.org/himalaya/
- **flow-cli docs:** https://data-wise.github.io/flow-cli/
- **Email OAuth2 Proxy:** https://github.com/simonrob/email-oauth2-proxy
- **fzf:** https://github.com/junegunn/fzf
- **w3m:** https://w3m.sourceforge.net/

---

**Questions or issues?** Open an issue on the [flow-cli GitHub repo](https://github.com/Data-Wise/flow-cli).
