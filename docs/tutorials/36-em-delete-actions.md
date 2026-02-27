---
tags:
  - tutorial
  - email
  - management
  - ai
---

# Tutorial: Email Management — Delete, Move, Flag & Extract

Soft-delete, move, restore, flag emails, and extract action items or calendar events — all from the terminal with `em` commands.

**Time:** 20 minutes | **Level:** Intermediate | **Requires:** himalaya CLI, flow-cli v7.4.0+, jq, fzf (for `--pick` modes)

## What You'll Learn

1. Deleting emails (soft, interactive, permanent)
2. Moving emails between folders
3. Restoring emails from Trash
4. Flagging emails for follow-up
5. Extracting action items to Reminders.app
6. Extracting events to Calendar.app

---

## Step 1: Delete to Trash

The default delete is a soft delete — it moves the email to your Trash folder:

```zsh
em delete 42
```

Delete multiple emails in one command:

```zsh
em delete 42 43 44
```

**What happens:**

- himalaya moves the message(s) to `$FLOW_EMAIL_TRASH_FOLDER`
- Default trash folder is `Trash`
- Exchange/Outlook accounts use `Deleted Items` — configure this with the environment variable

**Configuration:**

```zsh
export FLOW_EMAIL_TRASH_FOLDER=Trash           # Default
# export FLOW_EMAIL_TRASH_FOLDER="Deleted Items"  # Exchange / Outlook
```

You can also use the short alias `em del` or `em rm`.

---

## Step 2: Interactive Delete with fzf

When you want to browse and select which emails to delete, use `--pick`:

```zsh
em delete --pick
```

**What happens:**

- fzf opens with your inbox pre-loaded
- Use `Tab` to select multiple messages
- Press `Enter` to confirm selection
- A confirmation prompt shows before any deletion occurs

Combine with `--folder` to pick from a folder other than INBOX:

```zsh
em delete --pick --folder Newsletters
```

**Tip:** fzf must be installed for `--pick` mode. Run `em doctor` to verify.

---

## Step 3: Permanent Delete

To permanently remove an email with no Trash recovery, use `--purge`:

```zsh
em delete --purge 42
```

This bypasses the trash folder entirely. You will be prompted to type `yes` to confirm before the deletion executes.

**Warning:** There is no undo for purge. The email is gone permanently. Use with extreme caution.

---

## Step 4: Move to a Folder

Move an email to any folder by name:

```zsh
em move Archive 42
```

Move multiple emails at once:

```zsh
em move Archive 42 43 44
```

When the source email is not in INBOX, specify the source folder with `--from`:

```zsh
em move Archive 42 --from "Sent Items"
```

You can also use the short alias `em mv`.

---

## Step 5: Interactive Folder Picker

Can't remember the exact folder name? Use `--pick` to choose the destination interactively:

```zsh
em move --pick 42
```

fzf opens with all available folders listed. Select the destination and the move executes immediately.

This is especially useful for accounts with deep or complex folder hierarchies. Run `em folders` to see the full folder list without moving anything.

---

## Step 6: Restore from Trash

Moved something to Trash by mistake? Restore it to INBOX:

```zsh
em restore 42
```

Restore to a specific folder instead of INBOX:

```zsh
em restore 42 --to Archive
```

Restore multiple emails at once:

```zsh
em restore 42 43 44
```

The source is always `$FLOW_EMAIL_TRASH_FOLDER` (same setting used by `em delete`).

---

## Step 7: Flag for Follow-up

Star an email to mark it for follow-up:

```zsh
em flag 42
```

Flag multiple emails:

```zsh
em flag 42 43
```

Remove the flag:

```zsh
em unflag 42
```

Flags appear as stars in the `em inbox` listing. You can also use the short alias `em fl` for flagging.

---

## Step 8: Extract Action Items to Reminders

Use AI to extract action items from an email and send them to macOS Reminders.app:

```zsh
em todo 42
```

Process multiple emails:

```zsh
em todo 42 43
```

**What happens:**

1. The email body is sent to the configured AI backend (`$FLOW_EMAIL_AI`)
2. AI extracts actionable tasks from the message
3. Items are added to flow captures (visible via `catch`)
4. Items are sent to macOS Reminders.app via AppleScript

**Fallback:** If AI is unavailable or `FLOW_EMAIL_AI=none`, the email subject is used as the task title.

You can also use the short alias `em td`.

---

## Step 9: Extract Events to Calendar

Use AI to extract dates and events from an email and create them in macOS Calendar.app:

```zsh
em event 42
```

Process multiple emails:

```zsh
em event 42 43
```

**What happens:**

1. The email body is sent to the configured AI backend
2. AI extracts event details (title, date, time, location)
3. Extracted details are shown in the terminal for review
4. Events are created in macOS Calendar.app via AppleScript

You can also use the short alias `em ev`.

---

## Configuration Reference

```zsh
export FLOW_EMAIL_TRASH_FOLDER=Trash    # Trash folder name
# Exchange: export FLOW_EMAIL_TRASH_FOLDER="Deleted Items"

export FLOW_EMAIL_AI=claude             # AI backend: claude | gemini | none
export FLOW_EMAIL_AI_TIMEOUT=30         # AI timeout in seconds
```

Check your current configuration at any time:

```zsh
em help     # Shows active FLOW_EMAIL_AI and trash folder settings
```

---

## Checkpoint

After this tutorial, you should be able to:

- [x] Soft-delete emails to Trash with `em delete <ID>`
- [x] Use `--pick` with fzf for interactive selection
- [x] Permanently purge an email with `--purge`
- [x] Move emails between folders with `em move <FOLDER> <ID>`
- [x] Restore emails from Trash with `em restore <ID>`
- [x] Flag and unflag emails with `em flag` / `em unflag`
- [x] Extract action items to Reminders.app with `em todo <ID>`
- [x] Extract calendar events with `em event <ID>`

---

## FAQ

### Can I undo a delete?

Yes, as long as you did not use `--purge`. A soft delete moves the message to Trash. Run `em restore <ID>` to move it back to INBOX, or `em restore <ID> --to <FOLDER>` to restore to a specific folder.

### Does `--purge` really delete permanently?

Yes. `--purge` bypasses the Trash folder and removes the message directly via himalaya. There is no recovery path. The command requires typing `yes` at the confirmation prompt to prevent accidental use.

### What AI backend is used for `em todo` and `em event`?

The `FLOW_EMAIL_AI` setting controls this. Default is `claude` (requires `claude` CLI in PATH). Set `FLOW_EMAIL_AI=gemini` to use the Gemini CLI instead. Set `FLOW_EMAIL_AI=none` to disable AI — `em todo` will fall back to using the email subject as the task title.

### What if fzf is not installed?

The `--pick` flag on `em delete` and `em move` requires fzf. Without it, those flags will not work. All other commands (`em delete <ID>`, `em move <FOLDER> <ID>`, etc.) work without fzf. Run `em doctor` to verify dependencies.

---

## Next Steps

- **[Tutorial 35: em CLI Email](35-em-cli-email.md)** — Core email workflow (inbox, read, send, reply, search)
- **[Tutorial 37: em v2.0 Features](37-em-v2-features.md)** — Calendar integration, IMAP watch, folder management, safety gate
- **[Tutorial 33: Email in Neovim](33-himalaya-email.md)** — Read, compose, and process email without leaving Neovim
- **[Email Cookbook](../guides/EMAIL-COOKBOOK.md)** — Practical recipes for common workflows
- **[MASTER-DISPATCHER-GUIDE](../reference/MASTER-DISPATCHER-GUIDE.md)** — Complete `em` command reference
