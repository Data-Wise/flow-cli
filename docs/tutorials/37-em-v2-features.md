---
tags:
  - tutorial
  - email
  - v2.0
---

# Tutorial: em v2.0 — New Features

em v2.0 ships five new capabilities on top of the core email workflow: a safety gate that previews every outbound email before it leaves, calendar event parsing from ICS attachments, a background IMAP IDLE watcher for desktop notifications, granular attachment handling, and folder management. This tutorial walks through each feature with real commands you can run.

**Time:** 15 minutes | **Level:** Intermediate | **Requires:** flow-cli v7.5.0+, himalaya

## What You'll Learn

1. Using the send/reply safety gate and when to bypass it
2. Parsing ICS attachments and adding events to Apple Calendar
3. Running the IMAP IDLE background watcher for desktop notifications
4. Listing and downloading individual attachments by filename
5. Creating and deleting mail folders with type-to-confirm protection
6. Understanding version detection and progressive enhancement

---

## Before You Start

Verify your setup covers the v2.0 requirements:

```zsh
em doctor
```

```text
  ok  himalaya             himalaya 1.1.0
  ok  jq                   jq-1.7.1
  ok  fzf                  0.58.0 (...)
  ---  terminal-notifier   brew install terminal-notifier
```

The `terminal-notifier` line shows as optional (dashes, not red). Install it now if you want desktop notifications in Step 3:

```zsh
brew install terminal-notifier
```

---

## Step 1: Safety Gate

v2.0 adds a two-phase preview-and-confirm step to every outbound operation. `em send` and `em reply` both pause before transmitting, show a formatted preview, and require an explicit response.

### What the gate looks like

Start composing a new email:

```zsh
em send
```

After you write and save in `$EDITOR`, you see:

```text
Send Preview
────────────────────────────────────────────────────────────
  To:      colleague@example.com
  Subject: Q2 data analysis

  Hi Sarah,

  Attached is the completed Q2 breakdown you requested...
────────────────────────────────────────────────────────────

  Send? [y/N/e]
```

The three responses:

| Key | Action |
|-----|--------|
| `y` | Send immediately |
| `N` (or Enter) | Cancel — draft is saved to `$FLOW_DATA_DIR/email-drafts/` |
| `e` | Re-open `$EDITOR` for further edits, then preview again |

The **default is N**. Pressing Enter without typing anything cancels the send and saves the draft automatically. This is the intentional safe default.

The same gate applies to replies:

```zsh
em reply 42
```

```text
Reply Preview
────────────────────────────────────────────────────────────
  To:      sender@example.com
  Subject: Re: Q2 data analysis

  Thanks for the update. I'll review by Friday...
────────────────────────────────────────────────────────────

  Reply? [y/N/e]
```

### Bypassing the gate

In scripts, automation, or when you are confident in the draft, pass `--force`:

```zsh
em send --force
em reply 42 --force
```

`--force` skips the preview entirely and sends immediately. Use it intentionally; the gate exists to prevent accidents.

**Tip:** The first time you run `em send` after upgrading to v2.0, you will see a one-time migration notice explaining the new behavior. It appears only once and is not repeated.

---

## Step 2: Calendar Integration

When a colleague sends a meeting invite, the `.ics` file arrives as an email attachment. `em calendar` extracts and displays the event without opening a GUI mail client.

### Read the event details

```zsh
em calendar 58
```

```text
  Calendar Event
  ──────────────────────────────────
  Team Standup — Q2 Planning
  Start:    2026-03-10 09:00
  End:      2026-03-10 09:30
  Location: Conf Room B / Zoom
  From:     sarah@example.com

1 event(s) parsed
```

`em calendar` automatically detects whether the `icalendar` Python library is available. If it is, the enhanced parser handles recurrence rules and timezone conversions. If not, the pure-ZSH parser covers the common RFC 5545 format used by most calendar servers. Either way, the output is the same.

### Add to Apple Calendar

After the event details print, the command prompts:

```text
Create calendar event:
  Team Standup — Q2 Planning
  2026-03-10 09:00 - 2026-03-10 09:30
  Location: Conf Room B / Zoom

Add to Apple Calendar? [y/N]
```

Press `y` to create the event in Calendar.app via AppleScript. The event lands in your default calendar. Press Enter (or `N`) to skip creation and just keep the display.

**Limits:** The parser reads up to 10 events per ICS file and enforces a 1 MB file size cap. Oversized or malformed files are rejected with a clear error message.

**Tip:** Combine with `em read` when you want to see the email body first, then calendar:

```zsh
em read 58
em calendar 58
```

---

## Step 3: IMAP Watch

`em watch` runs a background process that monitors a mail folder via IMAP IDLE and delivers macOS desktop notifications when new messages arrive. The watcher survives shell exit.

### Start watching INBOX

```zsh
em watch start
```

```text
  Starting email watcher on folder: INBOX
  Watcher started (PID 84321, folder: INBOX)
  Stop: em watch stop
  Logs: em watch log
```

Watch a different folder:

```zsh
em watch start Work
```

Only one watcher runs at a time. Starting a second one when one is already active shows the current status and exits cleanly:

```text
  Watch already running (PID 84321)
```

### Check status

```zsh
em watch status
```

```text
  Email watcher: RUNNING
  ──────────────────────────────────
  PID:    84321
  Folder: INBOX
  Log:    /Users/you/.flow/em-watch.log
```

```text
  Email watcher: STOPPED
  Start: em watch start [folder]
```

### View recent activity

```zsh
em watch log
```

```text
  Watch Log (last 20 entries)
  ──────────────────────────────────
  [2026-03-10 09:04:11] STARTED watching INBOX (PID 84321)
  [2026-03-10 09:07:43] NEW: Re: Q2 data analysis — Sarah Chen
  [2026-03-10 09:07:53] RATE-LIMITED: Project update from Carlos
```

The rate-limiting line shows when a second notification arrived within 10 seconds of the previous one. The watcher allows a maximum of one desktop notification per 10-second window to avoid notification floods.

### Stop the watcher

```zsh
em watch stop
```

```text
  Watcher stopped
```

**Note:** `em watch` is marked experimental. The underlying `himalaya envelope watch` API may change across himalaya versions. Notification content is always sanitized: control characters are stripped, subjects are truncated to 100 characters, and the notification title is always the static string "New Email" — email content never controls the notification title.

---

## Step 4: Enhanced Attachments

v1.x had a single `em attach <ID>` command that downloaded everything. v2.0 adds targeted subcommands for inspection and selective download.

### List attachments before downloading

```zsh
em attach list 42
```

```text
Attachments for email #42
────────────────────────────────────────────────────────────
  report-q2-2026.pdf             application/pdf           1 MB
  data-export.csv                text/csv                  48 KB
  meeting-invite.ics             text/calendar             2 KB
```

The table shows filename, MIME type, and human-readable size. Use this to decide what you actually want before pulling everything down.

### Download one specific file

```zsh
em attach get 42 report-q2-2026.pdf
```

```text
  Downloading 'report-q2-2026.pdf' from email #42...
  Saved: /Users/you/Downloads/report-q2-2026.pdf
```

Download to a custom directory:

```zsh
em attach get 42 data-export.csv ~/projects/q2-analysis/
```

```text
  Saved: /Users/you/projects/q2-analysis/data-export.csv
```

### Download everything (original behavior preserved)

```zsh
em attach 42
em attach 42 ~/Downloads/email-42/
```

The bare `em attach <ID>` command still works exactly as before. The `list` and `get` subcommands are additive.

**Tip:** If you try `em attach get` with a filename that does not exist in the email, the error message tells you what to do:

```text
  File 'wrong-name.pdf' not found in attachments
  Use em attach list 42 to see available files
```

---

## Step 5: Folder Management

v2.0 adds two folder management commands: one for creation, one for deletion with a confirmation requirement.

### Create a folder

```zsh
em create-folder Archive/2026
```

```text
  Folder created: Archive/2026
```

Folder names are validated before the IMAP call — characters that are invalid in IMAP folder names are rejected immediately with a clear error.

The shorthand alias is `cf`:

```zsh
em cf Newsletter
```

### Delete a folder

Folder deletion is permanent and removes all messages inside. To prevent accidents, the command requires you to type the exact folder name:

```zsh
em delete-folder Newsletter
```

```text
  Warning: This will permanently delete folder Newsletter and all its contents.
  Type folder name to confirm deletion: Newsletter
  Folder deleted: Newsletter
```

If the name you type does not match exactly, the deletion is cancelled with no changes made:

```text
  Type folder name to confirm deletion: newsleter
  Deletion cancelled (name did not match)
```

The shorthand alias is `df`:

```zsh
em df OldArchive
```

**Warning:** There is no undo for `em delete-folder`. The type-to-confirm requirement is the only safeguard. Verify with `em folders` before deleting.

---

## Step 6: Version Detection

em v2.0 includes a version-detection layer that reads the installed himalaya version at startup and adjusts behavior accordingly. You do not configure this — it is automatic.

### How it works

On the first call to any himalaya-backed feature in a session, em runs `himalaya --version` once and caches the result. Subsequent calls in the same session use the cached value at no additional cost.

Features that require specific himalaya versions gate themselves:

```text
  em: 'attach list' requires himalaya >= 1.2.0 (installed: 1.1.0)
  Upgrade: brew upgrade himalaya
```

This means you can upgrade himalaya independently and gain features without changing any em configuration.

### Check what himalaya version you have

```zsh
himalaya --version
```

```text
himalaya 1.1.0
```

```zsh
em doctor
```

The doctor output includes a version comparison against the minimum required version (1.0.0). If your version is below the minimum, the line appears with a warning indicator rather than a pass.

---

## Checkpoint

After this tutorial, you should be able to:

- [x] Understand the send/reply safety gate and use `--force` when appropriate
- [x] Run `em calendar <ID>` to extract ICS events and optionally add them to Apple Calendar
- [x] Start and stop the IMAP IDLE watcher with `em watch start` / `em watch stop`
- [x] Use `em attach list <ID>` to inspect attachments before downloading
- [x] Download a specific file with `em attach get <ID> <filename>`
- [x] Create folders with `em create-folder` and delete with type-to-confirm protection
- [x] Understand that version detection is automatic and gates features to the installed himalaya

---

## Next Steps

- **[Tutorial 35: Email from the Terminal](35-em-cli-email.md)** — Core email workflow: inbox, read, send, reply, search
- **[Tutorial 36: Email Management](36-em-delete-actions.md)** — Delete, move, restore, flag, and extract actions
- **[Email Dispatcher Refcard](../reference/REFCARD-EMAIL-DISPATCHER.md)** — All 37 commands at a glance with flags and aliases
