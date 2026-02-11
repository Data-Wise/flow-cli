# Getting Started with Email in flow-cli

**The `em` email dispatcher — A 60-minute hands-on guide**

**Last Updated:** 2026-02-10
**Read Time:** 60 minutes hands-on (10 parts)
**Difficulty:** Beginner-friendly

---

## 🎯 What You'll Learn

By the end of this tutorial, you'll be able to:

- Check email from the terminal with instant access
- Read and respond to emails without leaving your workflow
- Use AI to draft professional replies automatically
- Browse emails interactively with fzf
- Batch process actionable emails with AI assistance
- Search and organize your inbox efficiently
- Understand caching for faster AI operations

---

## 📖 Tutorial Format

Each part includes:

- 🎯 **Learning Goal** - What you'll accomplish
- 💻 **Commands to Try** - Hands-on examples
- ✅ **Expected Output** - What you should see
- 💡 **What You Learned** - Key takeaways

**Try it now!** prompts appear throughout — follow along!

---

## Part 1: Setup (10 min)

### 🎯 Learning Goal

Install and configure the email stack so `em` commands work.

### Step 1.1: Install himalaya

himalaya is the email CLI backend that `em` uses.

**Option A: Cargo (recommended)**

```bash
cargo install himalaya
```

**Option B: Homebrew**

```bash
brew install himalaya
```

**Verify installation:**

```bash
himalaya --version
```

✅ **Expected:** Version number displayed (v1.0.0 or higher)

### Step 1.2: Configure himalaya

himalaya needs your email account credentials. It supports IMAP/SMTP with OAuth2 for Gmail, Outlook, etc.

**Quick setup:**

```bash
himalaya account add
```

Follow the prompts to configure your email account.

**For detailed setup instructions:**
- Gmail: https://pimalaya.org/himalaya/cli/latest/usage/gmail.html
- Outlook: https://pimalaya.org/himalaya/cli/latest/usage/outlook.html
- IMAP/SMTP: https://pimalaya.org/himalaya/cli/latest/usage/imap-smtp.html

**Test connection:**

```bash
himalaya envelope list --page-size 1
```

✅ **Expected:** One email displayed (or "No messages")

### Step 1.3: Verify em doctor

Now verify flow-cli can access your email:

```bash
em doctor
```

✅ **Expected output:**

```
em doctor — Email Dependency Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ok  himalaya             himalaya 1.0.0
  ok  jq                   jq-1.7.1
  --- fzf (Interactive picker) brew install fzf
  --- bat (Syntax highlighting) brew install bat
  --- w3m (HTML rendering) brew install w3m
  --- glow (Markdown rendering) brew install glow
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
2 passed  4 warnings  0 failed

Config:
  AI backend:  claude
  AI timeout:  30s
  Page size:   25
  Folder:      INBOX
  Config file: (none — using env defaults)
```

**Required tools:** himalaya, jq
**Recommended tools:** fzf, bat, w3m, glow

### Step 1.4: Install optional tools

These enhance the email experience:

```bash
# Interactive email browser
brew install fzf

# Syntax highlighting for email
brew install bat

# HTML email rendering (best)
brew install w3m

# Markdown rendering
brew install glow

# JSON processing (required)
brew install jq

# Pandoc for HTML fallback
brew install pandoc
```

**Run `em doctor` again to verify.**

### 💡 What You Learned

- himalaya is the email CLI backend
- `em doctor` checks all dependencies
- Required: himalaya, jq
- Recommended: fzf, bat, w3m, glow
- AI features require claude or gemini CLI

---

## Part 2: Your First Email Check (5 min)

### 🎯 Learning Goal

See your email status with quick commands.

### Command 1: Quick Pulse

**Try it now!**

```bash
em
```

✅ **Expected output:**

```
em — quick pulse
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  3 unread

Recent:
  ID    *  From                 Subject                                   Date
  ───── ── ──────────────────── ──────────────────────────────────────── ──────────
  42    *+ Alice Johnson        Re: Project proposal review               2026-02-10
  41    *  Bob Smith            Meeting notes from yesterday              2026-02-10
  40       Carol Davis          Weekly update                             2026-02-09
  39       David Lee            [GitHub] PR #123 merged                   2026-02-09
  38    *  Emma Wilson          Question about assignment 2               2026-02-08

Full inbox: em i  Browse: em p  Help: em h
```

**Key indicators:**
- `*` = unread
- `+` = has attachments
- Yellow text = unread (bold)
- Dim text = read

### Command 2: Unread Count

**Try it now!**

```bash
em unread
```

✅ **Expected output:**

```
3 unread in INBOX
```

### Command 3: Full Inbox

**Try it now!**

```bash
em inbox
```

✅ **Expected output:** List of 25 most recent emails (default page size)

**Try it now!**

```bash
em inbox 5
```

✅ **Expected output:** List of 5 most recent emails

### Command 4: Specific Folder

**Try it now!**

```bash
em folders
```

✅ **Expected output:** List of mail folders (INBOX, Sent, Drafts, etc.)

**Try it now!**

```bash
em pick Sent
```

✅ **Expected output:** Interactive browser of Sent folder

### 💡 What You Learned

- `em` alone gives quick pulse (unread + 10 latest)
- `em unread` shows count only
- `em inbox [N]` lists N recent emails (default 25)
- `em folders` lists available folders
- `*` means unread, `+` means attachments
- Yellow/bold = unread, dim = read

---

## Part 3: Reading Email (5 min)

### 🎯 Learning Goal

Read emails with smart content rendering.

### Command 1: Read an Email

**From the inbox list, pick an email ID (e.g., 42):**

**Try it now!**

```bash
em read 42
```

✅ **Expected output:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Message #42 [NEW]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  From:     Alice Johnson <alice@example.com>
  Subject:  Re: Project proposal review
  Date:     2026-02-10

──────────────────────────────────────────────────

Hi,

I reviewed the proposal and have a few questions:

1. What's the timeline for Phase 1?
2. Can we adjust the budget for consulting fees?
3. Who will lead the data collection effort?

Let's discuss on our call tomorrow.

Best,
Alice
```

**Smart rendering:**
- Plain text → displayed with bat (syntax highlighting)
- Markdown → rendered with glow
- HTML → converted to text with w3m/lynx/pandoc

### Command 2: Force HTML Rendering

**Try it now!**

```bash
em html 42
```

✅ **Expected output:** HTML email converted to readable text

**When to use:**
- Email looks garbled in plain text
- You know it's HTML (newsletters, formatted emails)

### Command 3: Download Attachments

**Try it now!**

```bash
em attach 42
```

✅ **Expected output:**

```
Downloading attachments from email #42...
✓ Attachments saved to: /Users/dt/Downloads
```

**Files saved to:** `~/Downloads` by default

**Custom download directory:**

```bash
em attach 42 ~/Desktop/project-files
```

### 💡 What You Learned

- `em read <ID>` reads an email with smart rendering
- Plain text → bat, Markdown → glow, HTML → w3m
- `em html <ID>` forces HTML rendering
- `em attach <ID>` downloads attachments to ~/Downloads
- Content type is auto-detected

---

## Part 4: The fzf Email Browser (5 min)

### 🎯 Learning Goal

Browse and act on emails interactively with keyboard shortcuts.

### Launch the Browser

**Try it now!**

```bash
em pick
```

✅ **Expected output:**

```
Folder: INBOX  |  Unread: 3
Enter=read  Ctrl-R=reply  Ctrl-S=summarize  Ctrl-A=archive  Ctrl-D=delete
* = unread  + = attachment

  42 * + Alice Johnson     Re: Project proposal review           2026-02-10
  41 *   Bob Smith         Meeting notes from yesterday          2026-02-10
  40     Carol Davis       Weekly update                         2026-02-09
> 39     David Lee         [GitHub] PR #123 merged               2026-02-09
  38 *   Emma Wilson       Question about assignment 2           2026-02-08

[Preview panel shows selected email →]
```

### Navigation

- **Arrow keys:** Navigate emails
- **Type to filter:** Start typing to search subjects/senders
- **Preview:** Right panel shows email content
- **Tab:** Switch between list and preview

### Actions (Keybindings)

**Try these:**

1. **Enter** — Read the selected email
2. **Ctrl-R** — Reply to selected email (AI draft)
3. **Ctrl-S** — Summarize selected email (AI)
4. **Ctrl-A** — Archive (mark read)
5. **Ctrl-D** — Delete (flag as deleted)
6. **Esc** — Exit browser

### Example Workflow

**Try it now!**

1. Launch: `em pick`
2. Type: `alice` (filters to Alice's emails)
3. Press: `Enter` (reads the email)
4. Press: `Ctrl-R` (starts AI reply)

### Browse Specific Folder

**Try it now!**

```bash
em pick Sent
```

✅ **Expected output:** Browser of Sent folder

### 💡 What You Learned

- `em pick` launches interactive email browser
- Type to filter, arrows to navigate
- Enter = read, Ctrl-R = reply, Ctrl-S = summarize
- Ctrl-A = archive, Ctrl-D = delete
- Preview panel shows email content
- Works with any folder: `em pick Sent`

---

## Part 5: Replying with AI (10 min)

### 🎯 Learning Goal

Generate AI-powered draft replies that open in your editor.

### Basic Reply

**Try it now!**

```bash
em reply 42
```

**What happens:**

1. AI reads the original email
2. Generates a professional draft reply
3. Opens your `$EDITOR` (nvim/vim/emacs/nano) with the draft
4. You edit, save, and exit
5. Confirms before sending

✅ **Expected output:**

```
Generating AI draft...
✓ AI draft ready — edit in $EDITOR
```

**In your editor, you'll see:**

```
To: alice@example.com
Subject: Re: Project proposal review
From: you@example.com

Hi Alice,

Thanks for reviewing the proposal. Here are answers to your questions:

1. Phase 1 timeline: We're targeting 6 weeks starting March 1st.
2. Budget adjustment: Yes, we can reallocate $10k to consulting fees.
3. Data collection lead: Dr. Sarah Chen will lead with support from grad students.

I'm looking forward to our call tomorrow to discuss details.

Best,
[Your Name]
```

**Edit the draft:**
- Revise the AI's suggestions
- Add personal touches
- Fix any errors
- Save and exit when done

**Send confirmation:**

```
Send this reply? [y/N] y
```

### Reply-All

**Try it now!**

```bash
em reply 42 --all
```

✅ **Expected output:** Same as above, but includes all recipients (To + CC)

### Skip AI (Blank Reply)

**Try it now!**

```bash
em reply 42 --no-ai
```

✅ **Expected output:** Editor opens with blank reply template (no AI draft)

**When to use:**
- AI backend unavailable
- You prefer writing from scratch
- Quick one-liner response

### Batch Mode (Non-Interactive)

**Try it now!**

```bash
em reply 42 --batch
```

**What happens:**

1. AI generates draft (no editor)
2. Displays preview
3. Asks for confirmation
4. Sends immediately if confirmed

✅ **Expected output:**

```
Fetching email #42...
Draft Reply
────────────────────────────────────────────────────────────────
To: alice@example.com
Subject: Re: Project proposal review
---
[Draft content shown...]
────────────────────────────────────────────────────────────────

  Send this reply? [y/N] y
✓ Reply sent
```

**When to use:**
- Batch processing emails
- Quick approvals
- Scripted workflows

### AI Backend Configuration

**Check current backend:**

```bash
echo $FLOW_EMAIL_AI
```

✅ **Expected output:** `claude` (default)

**Change backend:**

```bash
# Use gemini instead
export FLOW_EMAIL_AI=gemini

# Disable AI (always blank drafts)
export FLOW_EMAIL_AI=none
```

**Set timeout:**

```bash
# Default: 30 seconds
export FLOW_EMAIL_AI_TIMEOUT=45
```

### 💡 What You Learned

- `em reply <ID>` generates AI draft → opens in $EDITOR
- AI reads original email and drafts professional response
- Edit draft before sending (always!)
- `--all` includes all recipients (reply-all)
- `--no-ai` skips AI, blank template
- `--batch` non-interactive (preview + confirm + send)
- Safety gate: explicit [y/N] confirmation (default No)
- Configure backend: `$FLOW_EMAIL_AI` (claude|gemini|none)
- Configure timeout: `$FLOW_EMAIL_AI_TIMEOUT` (seconds)

---

## Part 6: Composing New Email (5 min)

### 🎯 Learning Goal

Compose and send new emails from the terminal.

### Basic Compose

**Try it now!**

```bash
em send
```

**What happens:**

1. Prompts for recipient (To:)
2. Prompts for subject
3. Opens $EDITOR with blank email
4. You compose message
5. Confirms before sending

✅ **Expected interaction:**

```
To: colleague@example.com
Subject: Quick question about project
```

**Editor opens with:**

```
To: colleague@example.com
Subject: Quick question about project
From: you@example.com

[Compose your message here]
```

**After you save and exit:**

```
────────────────────────────────────────────────────────────────
[Preview of email shown]
────────────────────────────────────────────────────────────────

  Send this email? [y/N] y
✓ Email sent
```

### Compose with Pre-filled Fields

**Try it now!**

```bash
em send colleague@example.com "Quick question"
```

✅ **Expected output:** Editor opens with To and Subject pre-filled

### Compose with AI Draft (Experimental)

**Try it now!**

```bash
em send colleague@example.com "Project timeline" --ai
```

**What happens:**

1. AI generates draft from subject line
2. Editor opens with AI-drafted message
3. You edit and send

✅ **Expected output:**

```
Generating AI draft from subject...
✓ AI draft ready — edit in $EDITOR
```

**When to use:**
- You know what to say but want AI to structure it
- Formal business emails
- Template-style messages

### 💡 What You Learned

- `em send` composes new email interactively
- Prompts for To, Subject, then opens $EDITOR
- `em send <to> <subject>` pre-fills fields
- `--ai` flag generates draft from subject
- Safety gate: always confirms before sending [y/N]
- Default is No (must explicitly type 'y')

---

## Part 7: AI Power Features (10 min)

### 🎯 Learning Goal

Use AI to classify, summarize, and batch process emails.

### Classify Email

**Try it now!**

```bash
em classify 42
```

✅ **Expected output:**

```
  Q student-question
```

**Categories:**
- **student-question** — Academic query, assignment, grade
- **admin-important** — Department notice, deadline, action required
- **admin-info** — FYI notices, newsletters
- **scheduling** — Meeting request, calendar, office hours
- **newsletter** — External newsletter, marketing
- **personal** — Colleague, friend, non-work
- **automated** — CI/CD, GitHub, system alerts
- **urgent** — Deadline today, emergency

**Category icons:**
- `Q` = student-question (blue)
- `!` = admin-important (red)
- `i` = admin-info (dim)
- `S` = scheduling (cyan)
- `N` = newsletter (dim)
- `P` = personal (green)
- `A` = automated (dim)
- `U` = urgent (red)

### Summarize Email

**Try it now!**

```bash
em summarize 42
```

✅ **Expected output:**

```
  Summary: Alice asks 3 questions about project proposal timeline and budget
```

**One-line summary focuses on:**
- Who wants what
- By when (if mentioned)
- Core ask or information

### Batch AI Drafts (Respond Command)

**Try it now!**

```bash
em respond
```

**What happens:**

1. Analyzes latest 20 emails (default)
2. Classifies each email
3. Skips non-actionable (newsletters, automated, admin-info)
4. Generates AI drafts for actionable emails
5. Saves drafts to cache

✅ **Expected output:**

```
Analyzing 20 emails for actionable messages...
  drafted #42: Re: Project proposal review
  drafted #38: Re: Question about assignment 2
  drafted #41: Re: Meeting notes from yesterday
  (skipped #40: Weekly update — newsletter)
  (skipped #39: [GitHub] PR merged — automated)

✓ 3 drafts generated (2 skipped)
  Review: em respond --review
```

**Adjust count:**

```bash
em respond --count 50
```

**Specific folder:**

```bash
em respond --folder Teaching
```

### Review Generated Drafts

**Try it now!**

```bash
em respond --review
```

**What happens:**

1. Launches fzf browser with cached drafts
2. Shows original email context
3. Preview panel shows draft
4. Actions: Enter=send, Ctrl-E=edit, Ctrl-D=discard

✅ **Expected output:**

```
Loading drafts for review...

  42    [Draft] Re: Project proposal review
  38    [Draft] Re: Question about assignment 2
> 41    [Draft] Re: Meeting notes from yesterday

[Preview panel shows draft content →]

Enter=send  Ctrl-E=edit  Ctrl-D=discard
```

### Clear Cached Drafts

**Try it now!**

```bash
em respond --clear
```

✅ **Expected output:**

```
✓ Email cache cleared (2.5M freed)
```

### AI Backend Selection

**Check available backends:**

```bash
command -v claude && echo "claude available"
command -v gemini && echo "gemini available"
```

**Set preferred backend:**

```bash
export FLOW_EMAIL_AI=gemini
```

**Check current config:**

```bash
em doctor
```

### 💡 What You Learned

- `em classify <ID>` categorizes email (8 types)
- `em summarize <ID>` one-line summary (who/what/when)
- `em respond` batch generates AI drafts for actionable emails
- Skips newsletters, automated, admin-info
- `em respond --review` interactive draft browser
- `em respond --count N` processes N emails (default 20)
- `em respond --clear` clears cached drafts
- AI backend: claude (default) or gemini
- Timeout: 30s default (configure with `$FLOW_EMAIL_AI_TIMEOUT`)

---

## Part 8: Search & Organization (5 min)

### 🎯 Learning Goal

Search emails and browse specific folders.

### Search Emails

**Try it now!**

```bash
em find "quarterly report"
```

✅ **Expected output:**

```
Searching: quarterly report

  42  Alice Johnson  Q3 quarterly report review  2026-02-10
  35  Bob Smith      Quarterly report draft     2026-01-15
  28  Carol Davis    Re: Quarterly planning     2026-01-10

3 results
```

**Search criteria:**
- Subject line (case-insensitive)
- Sender name
- Sender email address

### List Folders

**Try it now!**

```bash
em folders
```

✅ **Expected output:**

```
INBOX
Sent
Drafts
Archive
Trash
Teaching
Research
Projects
```

### Browse Specific Folder

**Try it now!**

```bash
em pick Sent
```

✅ **Expected output:** fzf browser of Sent folder

**Try it now!**

```bash
em pick Teaching
```

✅ **Expected output:** fzf browser of Teaching folder

### Dashboard View

**Try it now!**

```bash
em dash
```

✅ **Expected output:** Same as `em` — quick pulse view

**Alias shortcut:**

```bash
em d
```

### 💡 What You Learned

- `em find <query>` searches subject, sender name, sender email
- Case-insensitive search
- `em folders` lists available folders
- `em pick <FOLDER>` browses specific folder
- `em dash` or `em d` shows dashboard
- Search is client-side (fast, no IMAP query lag)

---

## Part 9: Cache & Performance (5 min)

### 🎯 Learning Goal

Understand how caching speeds up AI operations.

### View Cache Stats

**Try it now!**

```bash
em cache stats
```

✅ **Expected output:**

```
Email Cache
  summaries          12 items  48K
  classifications     12 items  1.2K
  drafts              3 items  8.5K
```

**Cache types:**
- **summaries** — One-line summaries (TTL: 24h)
- **classifications** — Category tags (TTL: 24h)
- **drafts** — Generated replies (TTL: 1h)
- **schedules** — Extracted dates (TTL: 24h)

### How Caching Works

**First call (no cache):**

```bash
time em summarize 42
```

✅ **Expected:** ~15 seconds (AI query)

**Second call (cached):**

```bash
time em summarize 42
```

✅ **Expected:** ~0.5 seconds (cache hit)

**Why it's fast:**
- Result stored in `.flow/email-cache/summaries/`
- Keyed by message ID (md5 hash)
- Checked before every AI call
- TTL-based expiration

### Cache Location

**Project-local cache:**

```bash
ls .flow/email-cache/
```

✅ **Expected output:**

```
summaries/
classifications/
drafts/
schedules/
```

**Global cache:**

```bash
ls $FLOW_DATA_DIR/email-cache/
```

### TTL (Time-to-Live)

**Cache lifetimes:**
- Summaries: 24 hours (stable content)
- Classifications: 24 hours (stable content)
- Drafts: 1 hour (might need refresh)
- Schedules: 24 hours

**After TTL expires:**
- Cache entry deleted
- Next call re-queries AI
- Result cached again

### Clear Cache

**Try it now!**

```bash
em cache clear
```

✅ **Expected output:**

```
✓ Email cache cleared (2.5M freed)
```

**When to clear:**
- AI draft quality issues (stale context)
- Disk space concerns
- Testing fresh AI responses

### Pre-warm Cache (Background)

**Manually warm cache:**

```bash
em cache warm 20
```

**What happens:**
- Fetches latest 20 emails
- Background-classifies + summarizes
- Runs asynchronously (doesn't block)

**Auto-warm triggers:**
- `em dash` (background warms latest 10)
- `em inbox` (background warms latest 10)

### 💡 What You Learned

- `em cache stats` shows cached AI results
- Cache stored in `.flow/email-cache/` (project) or `$FLOW_DATA_DIR/` (global)
- TTLs: summaries 24h, classifications 24h, drafts 1h
- Cache hit → <1s, cache miss → ~15s (AI query)
- `em cache clear` deletes all cached results
- `em cache warm N` pre-warms latest N emails
- Auto-warming on `em dash` and `em inbox`
- Cache keys use md5 hash of message ID

---

## Part 10: Workflows & Tips (5 min)

### 🎯 Learning Goal

Learn efficient daily workflows and pro tips.

### Morning Routine

**Try it now!**

```bash
# 1. Quick pulse
em

# 2. Browse and triage
em pick

# 3. Batch generate drafts
em respond

# 4. Review and send drafts
em respond --review
```

**Time:** ~5 minutes
**Result:** Inbox triaged, important emails drafted

### Teaching Workflow

**Scenario:** You teach a class and get lots of student emails.

**Try it now!**

```bash
# 1. See unread count
em unread

# 2. Pick teaching folder (if you have one)
em pick Teaching

# 3. Or search for student emails
em find "assignment"

# 4. Batch process student questions
em respond --count 30

# 5. Review drafts
em respond --review

# 6. Send approved drafts (in fzf: Enter on each)
```

**Time:** ~10 minutes
**Result:** 10-15 student emails answered with consistent, helpful responses

### ADHD Tip: Batch Processing

**Why batch processing helps:**
- Single decision: "draft all actionable emails"
- No context switching between read → think → write
- Review phase separate from drafting phase
- Reduces decision fatigue

**Workflow:**

```bash
# Batch 1: Generate drafts (no decisions)
em respond --count 50

# Break time (5-10 min)

# Batch 2: Review drafts (quick yes/no decisions)
em respond --review
```

### Quick Check Throughout Day

**Try it now!**

```bash
# Just see unread count
em unread

# Quick pulse (unread + 10 latest)
em

# Filter for urgent
em find "urgent"
```

**Time:** ~30 seconds
**Result:** Situational awareness without deep dive

### Search Before Replying

**Scenario:** You think you already answered this question.

**Try it now!**

```bash
# Search Sent folder
em pick Sent

# Type search term in fzf
# (start typing to filter)

# Read previous reply
# (press Enter)

# Copy/paste relevant parts to new reply
```

### Configuration File

**Create project-local config:**

```bash
mkdir -p .flow
cat > .flow/email.conf <<EOF
FLOW_EMAIL_AI=claude
FLOW_EMAIL_AI_TIMEOUT=30
FLOW_EMAIL_PAGE_SIZE=50
FLOW_EMAIL_FOLDER=INBOX
EOF
```

**Create global config:**

```bash
cat > ~/.config/flow/email.conf <<EOF
FLOW_EMAIL_AI=claude
FLOW_EMAIL_AI_TIMEOUT=45
FLOW_EMAIL_PAGE_SIZE=25
EOF
```

**Precedence:** Project config > Global config > Env vars > Defaults

### Keyboard Shortcuts Summary

**In fzf browser (`em pick`):**
- `↑↓` — Navigate
- `Enter` — Read email
- `Ctrl-R` — Reply (AI draft)
- `Ctrl-S` — Summarize (AI)
- `Ctrl-A` — Archive (mark read)
- `Ctrl-D` — Delete (flag)
- `Esc` — Exit

**In draft review (`em respond --review`):**
- `Enter` — Send draft
- `Ctrl-E` — Edit draft
- `Ctrl-D` — Discard draft
- `Esc` — Exit

### Aliases for Speed

**Add to your `.zshrc`:**

```bash
alias e='em'
alias ei='em inbox'
alias ep='em pick'
alias er='em respond'
alias eu='em unread'
```

### 💡 What You Learned

- Morning routine: `em` → `em pick` → `em respond` → `em respond --review`
- Teaching workflow: batch process student emails
- ADHD tip: batch generate drafts, then review separately
- Quick checks: `em unread` (30s)
- Search before replying: `em pick Sent` + filter
- Config files: `.flow/email.conf` (project) or `~/.config/flow/email.conf` (global)
- Keyboard shortcuts: fzf (Ctrl-R/S/A/D), review (Enter/Ctrl-E/D)
- Aliases for speed: `e`, `ei`, `ep`, `er`, `eu`

---

## 🎉 Congratulations

You've completed the email tutorial!

### What You Can Do Now

- ✅ Check email with `em` (quick pulse)
- ✅ Read emails with `em read <ID>`
- ✅ Browse interactively with `em pick`
- ✅ Reply with AI drafts (`em reply <ID>`)
- ✅ Compose new emails (`em send`)
- ✅ Classify and summarize (`em classify/summarize`)
- ✅ Batch process with `em respond`
- ✅ Search emails (`em find`)
- ✅ Understand caching (`em cache stats`)
- ✅ Build efficient workflows

---

## 🚀 Next Steps

### Level Up Your Workflow

**Try these advanced features:**

1. **Custom templates** — Create `.flow/email-templates/` with reply templates
2. **Context files** — Add `.flow/email-context.md` for AI to personalize drafts
3. **Folder workflows** — Organize by project/category and use `em pick <FOLDER>`
4. **Batch scripting** — Combine `em respond` with `em respond --review --batch`

### Integration with Other Tools

**Combine with other flow-cli dispatchers:**

```bash
# Start teaching session
teach

# Check teaching emails
em pick Teaching

# Work on grading
teach exam grade

# Update status
win "Answered 10 student emails"
```

### Customize AI Behavior

**Environment variables:**

```bash
# Try gemini instead of claude
export FLOW_EMAIL_AI=gemini

# Increase timeout for complex emails
export FLOW_EMAIL_AI_TIMEOUT=60

# Larger inbox page size
export FLOW_EMAIL_PAGE_SIZE=50
```

### Read the Docs

**See also:**
- `em help` — Full command reference
- `docs/reference/MASTER-DISPATCHER-GUIDE.md` — All dispatchers
- `docs/guides/WORKFLOW-TUTORIAL.md` — Project management workflow

---

## 📚 Command Reference

**Core Commands:**

| Command                | Purpose                          |
| ---------------------- | -------------------------------- |
| `em`                   | Quick pulse (unread + 10 latest) |
| `em inbox [N]`         | List N emails                    |
| `em read <ID>`         | Read email                       |
| `em reply <ID>`        | Reply with AI draft              |
| `em send`              | Compose new email                |
| `em pick [FOLDER]`     | Interactive browser              |

**AI Commands:**

| Command                | Purpose                          |
| ---------------------- | -------------------------------- |
| `em respond`           | Batch AI drafts                  |
| `em respond --review`  | Review generated drafts          |
| `em classify <ID>`     | Categorize email                 |
| `em summarize <ID>`    | One-line summary                 |

**Search & Info:**

| Command                | Purpose                          |
| ---------------------- | -------------------------------- |
| `em find <query>`      | Search emails                    |
| `em unread`            | Show unread count                |
| `em folders`           | List folders                     |
| `em dash`              | Dashboard                        |

**Utilities:**

| Command                | Purpose                          |
| ---------------------- | -------------------------------- |
| `em html <ID>`         | Force HTML rendering             |
| `em attach <ID>`       | Download attachments             |
| `em cache stats`       | Show cache statistics            |
| `em cache clear`       | Clear cache                      |
| `em doctor`            | Check dependencies               |

**Shortcuts:**

| Shortcut | Expands to  |
| -------- | ----------- |
| `em i`   | `em inbox`  |
| `em r`   | `em read`   |
| `em re`  | `em reply`  |
| `em s`   | `em send`   |
| `em p`   | `em pick`   |
| `em f`   | `em find`   |
| `em u`   | `em unread` |
| `em d`   | `em dash`   |
| `em cl`  | `em classify` |
| `em sum` | `em summarize` |
| `em resp` | `em respond` |
| `em a`   | `em attach` |
| `em dr`  | `em doctor` |

---

## ❓ FAQ

**Q: Does em store my email passwords?**
A: No. himalaya handles authentication. `em` just calls himalaya commands.

**Q: What if AI drafts are low quality?**
A: Edit them in $EDITOR before sending. AI provides structure, you add nuance.

**Q: Can I use em without AI?**
A: Yes! Set `export FLOW_EMAIL_AI=none`. All read/send/browse features work.

**Q: What if himalaya times out?**
A: Check your IMAP connection. Some providers (Gmail) require OAuth2 setup.

**Q: How do I handle multiple accounts?**
A: himalaya supports multiple accounts. See: `himalaya account list`

**Q: What's the difference between `em` and `himalaya`?**
A: `em` is a wrapper with AI features, smart rendering, caching, and flow-cli integration. himalaya is the underlying CLI.

**Q: Can I customize AI prompts?**
A: Yes, but it requires editing `lib/em-ai.zsh`. Future versions will support templates.

**Q: How do I report bugs?**
A: Open an issue on GitHub: https://github.com/Data-Wise/flow-cli/issues

---

## 🎨 Visual Workflow Map

```
YOUR EMAIL WORKFLOW
═══════════════════

Morning:
  em              → Quick pulse (unread + 10 latest)
    ↓
  em pick         → Browse & triage
    ↓
  em respond      → Batch AI drafts for actionable
    ↓
  em respond --review → Review & send drafts

During Day:
  em unread       → Quick check (30s)
    ↓
  em find "..."   → Search specific topic
    ↓
  em read <ID>    → Read one email
    ↓
  em reply <ID>   → AI draft → edit → send

Teaching:
  em pick Teaching → Browse student emails
    ↓
  em respond -n 30 → Batch draft 30 emails
    ↓
  em respond --review → Review & send

Research:
  em pick Research → Browse research emails
    ↓
  em find "grant"  → Find grant-related
    ↓
  em reply <ID> --all → Reply-all to team

End of Day:
  em dash         → Final check
    ↓
  win "Answered 15 emails" → Log accomplishment
```

---

## ✅ Skills Checklist

After this tutorial, you should be able to:

- [ ] Check email with `em` (quick pulse)
- [ ] Read emails with smart rendering
- [ ] Browse interactively with fzf
- [ ] Reply with AI-generated drafts
- [ ] Compose new emails
- [ ] Download attachments
- [ ] Classify and summarize emails (AI)
- [ ] Batch process actionable emails
- [ ] Search emails by subject/sender
- [ ] Browse specific folders
- [ ] Understand cache performance
- [ ] Clear cache when needed
- [ ] Build a morning email routine
- [ ] Batch process student/teaching emails
- [ ] Use keyboard shortcuts in fzf
- [ ] Configure AI backend (claude/gemini)
- [ ] Create project-local config files

---

**Total Time:** ~60 minutes hands-on
**Commands Learned:** 20+ commands
**Workflows Mastered:** 4 (morning, teaching, ADHD batch, quick check)

**You're now an email power user!** 🎯

---

*Last updated: 2026-02-10*
*flow-cli version: 6.7.1*
*Tutorial version: 1.0*
