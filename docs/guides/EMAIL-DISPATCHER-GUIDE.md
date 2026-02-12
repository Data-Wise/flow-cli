# Email Dispatcher Guide

**Available Since:** v6.8.0
**Status:** Production Ready
**Last Updated:** 2026-02-10

## Overview

The email dispatcher (`em`) brings ADHD-friendly email management to your terminal through a pure ZSH interface to [himalaya](https://github.com/pimalaya/himalaya). Think inbox zero in under 5 minutes, with AI-powered draft generation, smart rendering, and zero browser context-switching.

```bash
em                    # Quick pulse (unread + 10 latest)
em pick               # Interactive fzf browser
em read 42            # Smart rendering (HTML/markdown/plain)
em reply 42           # AI draft in $EDITOR
em respond            # Batch AI drafts for actionable emails
```

**Philosophy:**
- **Pure ZSH** - No Node.js runtime, no build step, sub-100ms commands
- **ADHD-friendly** - Quick pulse checks, smart defaults, keyboard-first
- **No vendor lock-in** - Just a wrapper around himalaya; your email stays portable
- **AI-augmented** - Optional AI features enhance without requiring changes to your workflow

## Why em?

Traditional email clients are heavyweight, distraction-prone, and slow. The `em` dispatcher brings email management into your flow-cli workflow:

- **Fast** - Sub-second response times for common operations
- **Focused** - No ads, no social features, no distractions
- **Scriptable** - Integrates with your shell workflows
- **Keyboard-first** - fzf picker with preview, multi-action support
- **AI-optional** - Works great without AI, better with it
- **Safe** - Explicit confirmation for all sends (default: No)

## Prerequisites

### Required

| Tool | Purpose | Install |
|------|---------|---------|
| [himalaya](https://github.com/pimalaya/himalaya) | Email CLI backend (IMAP/SMTP) | `brew install himalaya` or `cargo install himalaya` |
| [jq](https://stedolan.github.io/jq/) | JSON parsing | `brew install jq` |

### Recommended

| Tool | Purpose | Install |
|------|---------|---------|
| [fzf](https://github.com/junegunn/fzf) | Interactive email picker | `brew install fzf` |
| [bat](https://github.com/sharkdp/bat) | Syntax highlighting | `brew install bat` |
| [w3m](https://w3m.sourceforge.net/) | HTML rendering (primary) | `brew install w3m` |
| [glow](https://github.com/charmbracelet/glow) | Markdown rendering | `brew install glow` |

> **Tip:** HTML rendering uses a fallback chain: w3m → lynx → pandoc → bat → cat

### Optional

| Tool | Purpose | Install |
|------|---------|---------|
| [email-oauth2-proxy](https://github.com/simonrob/email-oauth2-proxy) | OAuth2 for Gmail/Outlook | `pip install email-oauth2-proxy` |
| terminal-notifier | Desktop notifications | `brew install terminal-notifier` |
| claude CLI | AI drafts (primary) | See [Claude Code docs](https://claude.ai/docs) |
| gemini CLI | AI drafts (fallback) | `pip install google-generativeai` |

### Check Your Setup

```bash
em doctor
```

This checks all dependencies and shows your current configuration:

```
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

himalaya supports multiple accounts and authentication methods. See the [himalaya configuration guide](https://pimalaya.org/himalaya/cli/latest/configuration/index.html) for complete setup instructions.

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

> **Security Note:** Use app-specific passwords or OAuth2 for Gmail/Outlook. Store passwords in your system keychain rather than plaintext config files.

Test your setup:

```bash
himalaya envelope list --page-size 5
```

If this works, you're ready to use `em`.

### 3. Configure em (Optional)

Set environment variables in your `.zshrc` or create a config file:

**Option A: Environment Variables**

```bash
# In ~/.zshrc or ~/.config/zsh/.zshrc
export FLOW_EMAIL_AI="claude"           # claude | gemini | none
export FLOW_EMAIL_AI_TIMEOUT=30         # AI timeout in seconds
export FLOW_EMAIL_PAGE_SIZE=25          # Default inbox page size
export FLOW_EMAIL_FOLDER="INBOX"        # Default folder
```

**Option B: Config File**

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
  - `*` = unread
  - `+` = has attachment
- Quick next actions

### 2. Scan with fzf Picker (30 seconds)

```bash
$ em pick
```

This opens an interactive fzf picker:

```
Folder: INBOX  |  Unread: 3
Enter=read  Ctrl-R=reply  Ctrl-S=summarize  Ctrl-A=archive  Ctrl-D=delete
* = unread  + = attachment
> * + Alice Johnson       Re: STAT-101 Exam Grading Question  2026-02-10
  * Carol Davis          Urgent: Grant Proposal Deadline     2026-02-09
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

```
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
- **Signature blocks** (`-- ` separator onwards) — dimmed

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
```

**Interactive Flow (Default):**

1. `em` fetches the original email
2. If AI is enabled, generates a draft reply
3. Opens `$EDITOR` with draft pre-populated
4. You edit the draft as needed
5. Save and close `$EDITOR`
6. Explicit confirmation prompt (default: No)
7. Send on confirmation

**Example:**

```bash
$ em reply 142

Generating AI draft...
✅ AI draft ready — edit in $EDITOR

# $EDITOR opens with pre-filled draft
# Edit as needed, save, close

  Send this reply? [y/N] y
✅ Reply sent
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

Preview:
────────────────────────────────────────────────────────
To: alice@university.edu
Subject: Office Hours Reminder

Hi Alice,

Just a reminder that I have office hours...
────────────────────────────────────────────────────────

  Send this email? [y/N] y
✅ Email sent
```

**With AI Draft:**

```bash
$ em send --ai alice@university.edu "Weekly Status Update"

Generating AI draft from subject...
✅ AI draft ready — edit in $EDITOR

# $EDITOR opens with AI-generated draft about weekly status
# Edit/refine, save, close

  Send this email? [y/N] y
✅ Email sent
```

### Download Attachments

```bash
em attach <ID>              # Download to ~/Downloads
em attach <ID> /tmp/files   # Download to specific directory
em a <ID>                   # Shortcut
```

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

```
claude → gemini → fail gracefully
```

### Classify Email

```bash
em classify <ID>
em cl <ID>             # Shortcut
```

Categorizes an email into one of these types:

| Category | Description | Icon | Color |
|----------|-------------|------|-------|
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

**Layer 1: Pre-classification skip.** Emails addressed to `*@LIST.*`, `*@list.*`, or `*-L@*` are auto-skipped before AI classification. They appear as:

```
  [3/10] graduation@unm.edu        L listserv — skip
```

**Layer 2: Warning banner.** If an actionable email was sent to a list-like address, a warning appears before drafting:

```
  ⚠ WARNING: This email was sent to a mailing list
    Replying may go to ALL list members. Review carefully.
```

### Discard Detection

When reviewing drafts, himalaya offers "Send it" and "Discard it" options. `em` properly detects both outcomes using `script(1)` to capture the interactive terminal output:

- **Send** — Counted as replied, marked in cache
- **Discard** — Counted as skipped, not marked as replied
- **Error** — Logged as warning, counted as skipped

This prevents the counter from showing "1 replied" when you actually chose to discard.

### AI Timeouts

Each AI operation has a specific timeout to prevent hanging:

| Operation | Timeout | Reason |
|-----------|---------|--------|
| classify | 10s | Quick category decision |
| summarize | 15s | One-line summary generation |
| draft | 30s | Full reply composition |
| schedule | 15s | Extract dates/times |

Configure global timeout:

```bash
export FLOW_EMAIL_AI_TIMEOUT=45  # Increase to 45s for all ops
```

### Prompt Customization

AI prompts are defined in `lib/em-ai.zsh`. To customize:

**Option 1: Override via Config**

Create `~/.config/flow/email-prompts.zsh`:

```bash
_em_ai_draft_prompt() {
    cat <<'PROMPT'
Draft a reply to this email.
Use casual, friendly tone.
Keep it under 100 words.
PROMPT
}
```

Source in your `.zshrc`:

```bash
[[ -f ~/.config/flow/email-prompts.zsh ]] && source ~/.config/flow/email-prompts.zsh
```

**Option 2: Edit Library File**

Edit `lib/em-ai.zsh` directly (not recommended for upgrades).

## Interactive Browsing: em pick

The `em pick` command provides a powerful fzf-based email browser with live preview.

```bash
em pick              # Browse INBOX
em pick Sent         # Browse Sent folder
em p                 # Shortcut
```

### Interface Layout

```
Folder: INBOX  |  Unread: 3
Enter=read  Ctrl-R=reply  Ctrl-S=summarize  Ctrl-A=archive  Ctrl-D=delete
* = unread  + = attachment
> * + Alice Johnson       Re: STAT-101 Exam Grading Question  2026-02-10
  * Carol Davis          Urgent: Grant Proposal Deadline     2026-02-09
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
|-----|--------|-------------|
| `Enter` | Read | Open selected email with smart rendering |
| `Ctrl-R` | Reply | Generate AI draft and open in $EDITOR |
| `Ctrl-S` | Summarize | Show one-line AI summary |
| `Ctrl-A` | Archive | Mark email as read |
| `Ctrl-D` | Delete | Flag email as deleted (with confirmation) |
| `Esc` / `Ctrl-C` | Exit | Close picker without action |

### Indicators

| Symbol | Meaning |
|--------|---------|
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

```
INBOX
Sent
Drafts
Trash
Archive
```

### Move Between Folders

```bash
em inbox Sent          # List sent emails
em pick Archive        # Browse archive folder
```

### Flag Management

Flags are managed internally via `lib/em-himalaya.zsh` adapter:

```bash
# Mark as read (via em pick → Ctrl-A)
_em_hml_flags add <ID> Seen

# Mark as flagged
_em_hml_flags add <ID> Flagged

# Mark as deleted
_em_hml_flags add <ID> Deleted
```

Currently flags are not exposed as direct `em` commands. Use `em pick` for interactive flag management.

## Cache System

All AI operations are cached with time-to-live (TTL) to avoid redundant API calls and improve response times.

### Cache Structure

```
.flow/email-cache/              # Project-local (if in project)
  summaries/<hash>.txt          # One-line summaries
  classifications/<hash>.txt    # Category classifications
  drafts/<hash>.txt             # Generated reply drafts
  schedules/<hash>.json         # Extracted dates/times
  unread/<hash>.txt             # Unread counts
```

Or globally:

```
$FLOW_DATA_DIR/email-cache/
  (same structure)
```

### TTL Values

| Cache Type | TTL | Reason |
|------------|-----|--------|
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

`em dash` and `em inbox` automatically trigger background housekeeping on startup:

- **Auto-prune**: removes expired cache entries (non-blocking)
- **Auto-warm**: pre-classifies + summarizes latest 10 emails (background)

This means your cache stays clean and pre-warmed without manual intervention.

### Cache Size Cap

The cache enforces a maximum size to prevent unbounded growth:

```bash
FLOW_EMAIL_CACHE_MAX_MB=50      # Default: 50 MB
FLOW_EMAIL_CACHE_MAX_MB=0       # Disable size cap
```

When the cache exceeds this limit, the oldest files are evicted first (LRU — Least Recently Used). Eviction runs automatically after every cache write as a non-blocking background process.

### Cache Invalidation

Cache is automatically invalidated when:
- You reply to an email (draft cache cleared for that message)
- TTL expires (pruned on next access or `em cache prune`)
- Cache exceeds size cap (LRU eviction)
- You explicitly run `em cache clear`

## Configuration Reference

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
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

```
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

1. **Adapter Pattern** - All himalaya CLI specifics are isolated in `lib/em-himalaya.zsh`. If himalaya changes its CLI, fix only one file.

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

```
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

```
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

```
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

```
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

The `em` dispatcher is designed with multiple safety layers to prevent accidental sends:

### 1. Explicit Confirmation

Every send operation requires explicit confirmation:

```bash
  Send this reply? [y/N]
```

- **Default is No** - Hitting Enter = no send
- **Must type 'y' or 'Y'** - Any other input cancels
- **Always shown** - Even in batch mode

### 2. Draft Preservation

Rejected sends automatically preserve the draft for later:

```bash
# Drafts saved to:
$FLOW_DATA_DIR/email-drafts/    # Global draft storage
```

AI-generated drafts are also cached in `.flow/email-cache/drafts/` with a 1-hour TTL. Use `em respond --review` to come back to cached drafts.

### 3. Preview Before Send

In batch mode, draft is previewed before confirmation:

```bash
Draft Reply
────────────────────────────────────────────────────────
From: me@example.com
To: alice@university.edu
Subject: Re: STAT-101 Exam Grading Question
---
[Full draft content shown]
────────────────────────────────────────────────────────

  Send this reply? [y/N]
```

### 4. Editor Interception

In interactive mode, you always edit in $EDITOR before send:

```bash
em reply 42

# 1. AI generates draft (if enabled)
# 2. $EDITOR opens with draft
# 3. You edit/review
# 4. Save and close
# 5. Only then: confirmation prompt
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
2. Manual confirmation

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

## Next Steps

Now that you understand the `em` dispatcher:

1. **Set up himalaya** - Configure your email accounts
2. **Install optional tools** - fzf, bat, w3m for enhanced experience
3. **Configure AI** - Set `FLOW_EMAIL_AI` to your preferred backend
4. **Run `em doctor`** - Verify your setup
5. **Try the 5-minute routine** - `em` → `em pick` → `em reply` → `em respond`
6. **Customize shortcuts** - Add `alias mail=em` to your `.zshrc`

## More Information

- **himalaya docs:** https://pimalaya.org/himalaya/
- **flow-cli docs:** https://data-wise.github.io/flow-cli/
- **Email OAuth2 Proxy:** https://github.com/simonrob/email-oauth2-proxy
- **fzf:** https://github.com/junegunn/fzf
- **w3m:** https://w3m.sourceforge.net/

---

**Questions or issues?** Open an issue on the [flow-cli GitHub repo](https://github.com/Data-Wise/flow-cli).
