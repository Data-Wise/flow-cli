---
tags:
  - tutorial
  - email
  - himalaya
  - ai
  - terminal
---

# Tutorial: Email from the Terminal with em

Read, search, compose, and process email without leaving your shell. The `em` dispatcher wraps the himalaya CLI with AI drafts, fzf browsing, and smart rendering.

**Time:** 20 minutes | **Level:** Beginner-Intermediate | **Requires:** himalaya CLI, flow-cli

## What You'll Learn

1. Checking email with the dashboard
2. Reading emails with smart rendering
3. Inbox browsing and pagination
4. Searching and browsing with fzf
5. Composing and sending email
6. AI-powered replies and drafts
7. Checking dependencies and configuration

---

## Step 1: Quick Pulse

Run `em` with no arguments for an instant summary of what's waiting:

```zsh
em
```

This shows your unread count and the 10 latest messages — a pulse check before diving in.

The same view is available as a named subcommand:

```zsh
em dash
```

**Tip:** Put `em` at the top of a morning workflow alias to start every session with inbox awareness.

---

## Step 2: Reading Email

Read any email by ID:

```zsh
em read 42
```

Shortcut: a bare number works without the `read` keyword:

```zsh
em 42
```

**Rendering options** — choose the format that works best for the message:

```zsh
em read --html 42     # Render HTML in w3m or lynx
em read --md 42       # Convert to Markdown via pandoc
em read --raw 42      # Show raw MIME source
```

| Flag | Renderer | Best For |
|------|----------|----------|
| (none) | plain text | Most emails |
| `--html` | w3m / lynx | Rich HTML newsletters |
| `--md` | pandoc | Structured content, tables |
| `--raw` | none | Debugging headers, MIME parts |

**Tip:** `em r` is an alias for `em read`. `em r --html 42` and `em read --html 42` are identical.

---

## Step 3: Inbox and Pagination

List recent messages:

```zsh
em inbox          # Default page size (25)
em inbox 50       # Show 50 messages
em -n 5           # Shortcut: same as em inbox 5
```

Check only the unread count:

```zsh
em unread
```

See all available mail folders:

```zsh
em folders
```

**How pagination works:** `em inbox N` fetches the N most recent messages from your default folder. Increase N to look further back. The default page size is controlled by `FLOW_EMAIL_PAGE_SIZE` (see Configuration below).

---

## Step 4: Search and Browse

Search by keyword across your mailbox:

```zsh
em find "quarterly report"
```

For interactive browsing with a live preview pane, use `pick`:

```zsh
em pick              # Browse default folder (INBOX)
em pick Archive      # Browse a specific folder
```

`em pick` opens fzf with a preview of each message. Navigate with arrow keys, press Enter to open the selected email in full, or press Escape to cancel.

**Tip:** `em pick Sent` is useful for finding a message you sent recently without remembering exact words.

---

## Step 5: Compose and Reply

Open `$EDITOR` to write a new email:

```zsh
em send
```

Reply to an existing email with an AI-generated draft:

```zsh
em reply 42              # AI draft opened in $EDITOR
em reply 42 --no-ai      # Plain reply template, no AI
em reply 42 --all        # Reply-all
em reply 42 --batch      # Non-interactive: preview then confirm
```

Every send operation requires explicit confirmation:

```text
Send this email? [y/N]:
```

The default is **N** (no). Press `y` to send, anything else to cancel.

**Tip:** Use `--batch` in scripts or when you want a one-step preview-and-send without opening your editor.

---

## Step 6: AI Features

### Batch drafts

Generate AI reply drafts for all actionable emails at once:

```zsh
em respond             # Draft AI replies for actionable emails
em respond --review    # Review and send drafts interactively
```

### Per-email AI actions

```zsh
em classify 42         # AI categorizes the email (meeting, action, FYI, etc.)
em summarize 42        # One-line AI summary
em catch 42            # Capture email as a flow task
em todo 42             # Extract action items
em event 42            # Extract calendar event details
```

### AI backend management

```zsh
em ai                  # Show current AI backend
em ai toggle           # Cycle through configured backends
```

### Cache management

```zsh
em cache stats         # Show cache size and hit rate
em cache clear         # Wipe cached AI results
```

AI results are cached by default (TTL-based). Clearing the cache forces fresh AI calls on the next run.

---

## Step 7: Health Check

Verify that all dependencies are installed and configured:

```zsh
em doctor
```

This checks: `himalaya`, `jq`, `fzf`, `pandoc`, `w3m` (or `lynx`), and AI backend availability.

A green line means the dependency is found and working. A red line means it is missing — the output includes the install command for each missing tool.

**Tip:** Run `em doctor` when setting up on a new machine or after upgrading himalaya.

---

## Configuration

Add any of these to your `~/.zshrc` (or `~/.config/zsh/`) to override defaults:

```zsh
export FLOW_EMAIL_AI=claude           # AI backend: claude | gemini | none
export FLOW_EMAIL_PAGE_SIZE=25        # Default inbox page size
export FLOW_EMAIL_FOLDER=INBOX        # Default folder
export FLOW_EMAIL_TRASH_FOLDER=Trash  # Trash folder (Exchange: "Deleted Items")
export FLOW_EMAIL_AI_TIMEOUT=30       # AI draft timeout in seconds
```

Project-level overrides are supported: create `.flow/email.conf` in a project root and `em` will load those settings automatically when you are inside that project.

---

## Checkpoint

After this tutorial, you should be able to:

- [x] Check your inbox pulse with `em`
- [x] Read emails in plain, HTML, Markdown, or raw format
- [x] Search with `em find` and browse interactively with `em pick`
- [x] Compose new email and reply with AI drafts
- [x] Use batch AI features (`em respond`, `em classify`, `em summarize`)
- [x] Verify your setup with `em doctor`

---

## FAQ

### How do I switch AI backends?

Run `em ai toggle` to cycle through your configured backends, or set `FLOW_EMAIL_AI=gemini` (or `claude` or `none`) in your shell config. The active backend is shown by `em ai` and also by `em doctor`.

### How do I configure em for Exchange (Microsoft 365)?

Exchange typically uses `"Deleted Items"` instead of `Trash` as the trash folder name. Set:

```zsh
export FLOW_EMAIL_TRASH_FOLDER="Deleted Items"
```

Also make sure your `~/.config/himalaya/config.toml` uses the correct IMAP host and OAuth2 or password credentials for your Exchange account. See the [himalaya documentation](https://pimalaya.org/himalaya/) for account setup details.

### What if himalaya is not installed?

Run `em doctor` — it will report which dependencies are missing and show the install command for each. For himalaya itself:

```zsh
brew install himalaya       # macOS (recommended)
cargo install himalaya      # From source
```

After installing, configure an account in `~/.config/himalaya/config.toml` and run `em doctor` again to verify.

### How does pagination work?

`em inbox N` fetches the N most recent messages from your default folder in a single IMAP call. There is no cursor-based paging — to look further back, increase N (e.g., `em inbox 100`). The default of 25 is set by `FLOW_EMAIL_PAGE_SIZE`. Very large values (500+) may be slow depending on your IMAP server.

---

## Next Steps

- **[Tutorial 36: Email Management](36-em-delete-actions.md)** — Delete, move, restore, flag, and extract actions from email
- **[Tutorial 46: em v2.0 Features](46-em-v2-features.md)** — Calendar integration, IMAP watch, folder management, safety gate
- **[Tutorial 33: Email in Neovim](33-himalaya-email.md)** — Read, reply, and process email without leaving your editor
- **[Email Cookbook](../guides/EMAIL-COOKBOOK.md)** — Practical recipes for common workflows
- **[MASTER-DISPATCHER-GUIDE](../reference/MASTER-DISPATCHER-GUIDE.md)** — Complete reference for all 15 dispatchers
