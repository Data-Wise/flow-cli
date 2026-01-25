# DOT Dispatcher - Visual Mockups

**Purpose:** Show exactly what users will see in their terminal
**Design Philosophy:** ADHD-friendly (clear hierarchy, color coding, actionable hints)

---

## Mockup 1: `dot` (Default Status)

```bash
$ df

📦 Dotfiles Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🟢 Synced with remote
   Last sync: 2 hours ago
   Machine: iMac.local

🔐 Secrets
   ✓ Bitwarden unlocked
   ✓ 3 secrets injected

📝 Tracked Files (12)
   ✓ ~/.config/zsh/.zshrc
   ✓ ~/.gitconfig
   ✓ ~/.ssh/config
   ✓ Brewfile
   ... (8 more)

📊 Repository
   ✓ Up to date with origin/main
   • 0 files modified locally
   • 0 commits behind remote

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 Quick actions:
   df edit .zshrc    Edit config
   df sync           Pull latest
   df push           Push changes
   df help           Full help
```

**Color scheme:**
- 🟢 Green: Everything OK
- Headers: Bold cyan
- Icons: Colorful (📦 🔐 📝 📊 💡)
- Dim text: File lists, metadata

---

## Mockup 2: `dot` (Modified State)

```bash
$ df

📦 Dotfiles Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🟡 Modified (local changes)
   Last sync: 2 hours ago
   Machine: iMac.local

🔐 Secrets
   ✓ Bitwarden unlocked
   ✓ 3 secrets injected

📝 Modified Files (2)
   M ~/.config/zsh/.zshrc (12 lines changed)
   M ~/.gitconfig (1 line added)

📊 Repository
   ✓ Connected to origin/main
   • 2 files modified locally
   • 0 commits behind remote

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 Next step:
   df diff     Preview changes
   df push     Push to remote
   df undo     Discard changes
```

**Color scheme:**
- 🟡 Yellow: Local changes
- M (modified): Yellow highlight
- Next step: Cyan links

---

## Mockup 3: `dot` (Behind Remote)

```bash
$ df

📦 Dotfiles Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔵 Behind remote (2 commits)
   Last sync: 1 day ago
   Machine: MacBook.local

🔐 Secrets
   ✓ Bitwarden unlocked
   ✓ 3 secrets injected

📝 Remote Changes
   • Updates to .zshrc (from iMac)
   • New file: .tmux.conf

📊 Repository
   ✓ Connected to origin/main
   • 0 files modified locally
   • 2 commits behind remote

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠ Remote has newer changes
💡 Run: df sync (to pull and apply)
```

**Color scheme:**
- 🔵 Blue: Remote ahead
- ⚠ Yellow: Warning icon
- Remote changes: Blue highlight

---

## Mockup 4: `dot` (Bitwarden Locked)

```bash
$ df

📦 Dotfiles Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🟢 Synced with remote
   Last sync: 30 minutes ago
   Machine: iMac.local

🔐 Secrets
   ⚠ Bitwarden locked (session expired)
   ✗ Secrets not available

📝 Tracked Files (12)
   ✓ All files synced

📊 Repository
   ✓ Up to date with origin/main

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠ Secrets unavailable
💡 Run: df unlock (to restore secrets)
```

**Color scheme:**
- ⚠ Yellow: Warning (secrets locked)
- ✗ Red: Error indicator

---

## Mockup 5: `dot edit .zshrc`

```bash
$ df edit .zshrc
✓ Opening ~/.config/zsh/.zshrc in vim...

(User edits file and saves)

✓ File saved

📝 Changes preview:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 # ZSH Configuration

-export PATH="/usr/local/bin:$PATH"
+export PATH="/opt/homebrew/bin:$PATH"

 # Aliases
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1 file changed, 1 line modified

Apply changes? [Y/n] y

✓ Creating backup...
✓ Applying changes...
✓ Changes applied successfully

💡 Next: df push (to sync to other machines)
```

**Color scheme:**
- Green: Success steps
- Red: Deletions (-)
- Green: Additions (+)
- Dim: Context lines

---

## Mockup 6: `dot edit zshrc` (Fuzzy Match)

```bash
$ df edit zshrc
🔍 Resolving path: "zshrc"...
✓ Matched: ~/.config/zsh/.zshrc

✓ Opening in vim...
```

**Smart matching:**
- Shows what it matched
- Gives user confidence

---

## Mockup 7: `dot edit git` (Multiple Matches)

```bash
$ df edit git
🔍 Multiple matches found:

  1) ~/.gitconfig
  2) ~/.git-credentials
  3) ~/.gitignore_global

Select file [1-3]: 1

✓ Opening ~/.gitconfig in vim...
```

**Disambiguation:**
- Numbered list
- Clear selection prompt
- Falls back to fzf if 5+ matches

---

## Mockup 8: `dot sync`

```bash
$ df sync
🔄 Pulling latest changes from origin/main...
✓ Fetched 2 commits

📝 Remote changes:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  M ~/.config/zsh/.zshrc (3 lines)
  A ~/.tmux.conf (new file)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

2 files will be modified

Preview full diff? [y/N] n

Apply changes? [Y/n] y

✓ Creating backups...
✓ Applying changes...
✓ 2 files updated

✓ Sync complete

💡 Changes from: iMac.local (2 hours ago)
```

**Color scheme:**
- Blue: Sync actions
- Green: Success
- M = modified, A = added, D = deleted

---

## Mockup 9: `dot sync` (Conflict)

```bash
$ df sync
🔄 Pulling latest changes from origin/main...
✓ Fetched 1 commit

⚠ Merge conflict detected:
   ~/.config/zsh/.zshrc

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Local changes:
  export API_KEY="abc123"

Remote changes:
  export API_KEY="xyz789"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

How to resolve?
  1) Keep local (your changes)
  2) Keep remote (other machine's changes)
  3) Manual merge (open in editor)
  4) Abort (stay as-is)

Choice [1-4]: 3

✓ Opening merge editor...

(User resolves conflict)

✓ Conflict resolved
✓ Changes applied

💡 Next: df push (to sync resolution)
```

**Color scheme:**
- Yellow: Warning (conflict)
- Numbered options: Cyan
- Clear distinction: local vs remote

---

## Mockup 10: `dot push`

```bash
$ df push
📤 Preparing to push changes...

📝 Local changes:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  M ~/.config/zsh/.zshrc (update aliases)
  M ~/.gitconfig (add new email)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Commit message: Update shell config and git email

Push to origin/main? [Y/n] y

✓ Creating commit...
✓ Pushing to origin/main...
✓ Push complete

💡 Changes will sync to other machines on next 'df sync'
```

**Color scheme:**
- Green: Upload actions
- Auto-generated commit message (editable)

---

## Mockup 11: `dot diff`

```bash
$ df diff

📝 Modified Files (2)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

File: ~/.config/zsh/.zshrc
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  # Aliases
- alias ll='ls -l'
+ alias ll='eza -l'

  # Exports

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

File: ~/.gitconfig
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  [user]
      name = Data Wise
+     email = dt@statwise.com

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Summary: 2 files, 2 additions, 1 deletion

💡 Next: df apply (to apply changes)
       df undo (to discard changes)
```

**Color scheme:**
- Red: Deletions (-)
- Green: Additions (+)
- Dim: Context lines

---

## Mockup 12: `dot list`

```bash
$ df list

📝 Tracked Dotfiles (12)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Shell:
  ✓ ~/.config/zsh/.zshrc
  ✓ ~/.config/zsh/.zshenv

Git:
  ✓ ~/.gitconfig
  ✓ ~/.gitignore_global

SSH:
  ✓ ~/.ssh/config

Editor:
  ✓ ~/.vimrc
  ✓ ~/.tmux.conf

Packages:
  ✓ Brewfile

Other:
  ✓ ~/.aliases
  ✓ ~/.functions
  ✓ ~/.exports
  ✓ ~/.paths

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 Add file: chezmoi add <file>
   Edit file: df edit <file>
```

**Organization:**
- Grouped by category
- Check marks for tracked files
- Clean hierarchy

---

## Mockup 13: `dot secret list`

```bash
$ df secret list

🔐 Bitwarden Secrets
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ Desktop Commander API
   Used in: .zshrc
   Status: Injected

✓ GitHub MCP Token
   Used in: .zshrc
   Status: Injected

✓ Anthropic API Key
   Used in: .zshrc
   Status: Injected

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Total: 3 secrets
Status: All injected successfully

💡 Add secret: df secret add
   Test secrets: df secret test
```

**Color scheme:**
- Green: Injected successfully
- Shows where secrets are used
- Clear status indicators

---

## Mockup 14: `dot secret add`

```bash
$ df secret add

🔐 Add New Secret
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Secret name: OpenAI API Key
Secret value: ********************************

Where to inject?
  1) ~/.config/zsh/.zshrc
  2) ~/.zshenv
  3) Custom file

Choice [1-3]: 1

Variable name: OPENAI_API_KEY

✓ Creating Bitwarden item...
✓ Adding to .zshrc template...
✓ Testing injection...
✓ Secret added successfully

💡 Run: df apply (to apply changes)
```

**Guided process:**
- Step-by-step prompts
- Masked value display
- Validation before saving

---

## Mockup 15: `dot unlock`

```bash
$ df unlock

🔓 Unlock Bitwarden
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Enter master password: ********************************

✓ Unlocked successfully
✓ Session expires in 1 hour

💡 Secrets are now available for injection
```

**Security:**
- Password masked
- Shows session expiry
- Clear success message

---

## Mockup 16: `dot doctor`

```bash
$ df doctor

🩺 Dotfile Health Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ chezmoi installed (v2.46.0)
✓ bitwarden-cli installed (v2024.3.0)
✓ git installed (v2.42.0)

✓ Chezmoi initialized
✓ Repository connected (origin/main)
✓ Git remote accessible

✓ Bitwarden vault accessible
✓ Session active (expires in 45m)

✓ 3 secrets configured
✓ All secrets found in vault
✓ Templates valid

✓ 12 files tracked
✓ No conflicts detected
✓ Synced with remote

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎉 All checks passed!
```

**Comprehensive checks:**
- Dependencies
- Configuration
- Secrets
- Sync status
- Clear pass/fail indicators

---

## Mockup 17: `dot doctor` (Issues Found)

```bash
$ df doctor

🩺 Dotfile Health Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✓ chezmoi installed (v2.46.0)
✗ bitwarden-cli not found
✓ git installed (v2.42.0)

✓ Chezmoi initialized
✓ Repository connected (origin/main)
⚠ Git remote slow to respond

✗ Bitwarden not available
  → Install: brew install bitwarden-cli
  → Then run: bw login

⚠ 2 secrets configured but vault locked
  → Run: df unlock

✓ 12 files tracked
⚠ 2 conflicts detected
  → Run: df sync (to resolve)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

3 issues found

Fix all issues? [Y/n] y

📦 Installing bitwarden-cli...
✓ Installed

🔓 Login to Bitwarden:
...
```

**Color scheme:**
- Red ✗: Errors (blocking)
- Yellow ⚠: Warnings (non-blocking)
- → Arrow: Suggested fix
- Auto-fix option

---

## Mockup 18: `dot undo`

```bash
$ df undo

⏪ Undo Last Change
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Last applied: 10 minutes ago
Changes:
  M ~/.config/zsh/.zshrc (3 lines)
  M ~/.gitconfig (1 line)

Undo and restore previous version? [Y/n] y

✓ Restoring backups...
✓ 2 files restored

✓ Undo complete

💡 Redo: df apply (to reapply)
```

**Safety:**
- Shows what will be undone
- Confirmation prompt
- Reversible

---

## Mockup 19: `dot help` (Abbreviated)

```bash
$ df help

╭─────────────────────────────────────────────╮
│ df - Dotfile Management                     │
╰─────────────────────────────────────────────╯

🔥 MOST COMMON (80% of daily use):
  df                Show status overview
  df edit .zshrc    Edit and apply config
  df sync           Pull latest changes
  df push           Push local changes

💡 QUICK EXAMPLES:
  $ df                  # Quick status
  $ df edit zshrc       # Edit config
  $ df diff             # Preview changes
  $ df sync             # Pull & apply

📝 CORE WORKFLOWS:
  df edit <file>    Edit dotfile (with preview)
  df apply          Apply pending changes
  df sync           Pull latest from remote
  df push           Push local changes
  df diff           Show pending changes

🔐 SECRET MANAGEMENT:
  df secret list    List all secrets
  df secret add     Add new secret
  df unlock         Unlock Bitwarden

📋 STATUS & INFO:
  df                Status overview (default)
  df status         Full sync status
  df list           List tracked files

🛠 SETUP & MAINTENANCE:
  df init           Initialize dotfiles
  df doctor         Health check
  df undo           Undo last apply

💡 TIP: Run 'df' for quick status check
```

**Layout:**
- Most common commands at top
- Emoji section headers
- Clear command → description
- Tip at bottom

---

## Mockup 20: Dashboard Integration (`dash`)

```bash
$ dash

📊 Flow Dashboard
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📍 Right Now
  MacBook Pro • 2026-01-08 14:30
  Session: flow-cli (2h 15m)

🎯 Current Project: flow-cli
  Status: ACTIVE
  Next: Add dotfile dispatcher

📦 Dotfiles: 🟢 Synced (2h ago)              ← NEW!
  3 secrets active • 0 pending changes
  💡 df sync to update

🎉 Recent Wins (today: 3)
  ✨ Completed UX design (1h ago)
  💻 Updated documentation (2h ago)
  ...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Integration:**
- One line in dashboard
- Status icon (🟢/🟡/🔴)
- Key metrics
- Next action hint

---

## Mockup 21: Work Integration (`work`)

```bash
$ work flow-cli
✓ Starting session: flow-cli

📦 Checking dotfiles...                      ← NEW!
  ⚠ Behind remote by 2 commits
  💡 Run 'df sync' to update? [Y/n] n

  Skipped. You can sync later with 'df sync'.

✓ Session started
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📂 Project: flow-cli
📁 ~/projects/dev-tools/flow-cli

💡 Ready to code!
```

**Non-intrusive:**
- One-line check
- Optional prompt
- Easy to skip
- Can disable: `export FLOW_DF_CHECK_ON_WORK=0`

---

## Design Principles Demonstrated

### 1. Clear Visual Hierarchy

- Bold headers with icons
- Section separators (━━━)
- Indented content
- Grouped related info

### 2. Status-First Design

- 🟢 Green = All good
- 🟡 Yellow = Action recommended
- 🔴 Red = Error / conflict
- 🔵 Blue = Informational

### 3. Progressive Disclosure

- `dot` → Quick overview
- `dot status` → Detailed status
- `dot help` → Full documentation
- Inline hints → Next action

### 4. Actionable Errors

- Every error shows:
  1. What's wrong (clear message)
  2. Why it matters (context)
  3. How to fix (command)

### 5. Safe Defaults

- Preview before apply
- Backup before changes
- Confirmation prompts
- Undo always available

### 6. ADHD-Optimized

- Zero reading for green status
- Immediate action suggestions
- Short command syntax
- Fuzzy matching (forgiving input)

---

## Color Reference

```bash
# Status colors
🟢 #72B372  Green    → Synced, success
🟡 #DDB05E  Yellow   → Modified, warning
🔴 #CB6B7B  Red      → Conflict, error
🔵 #75B0E3  Blue     → Behind remote, info
⚫ #787878  Gray     → Not initialized

# Icons
📦 Package/Dotfiles
🔐 Security/Secrets
📝 Files/Edits
📊 Stats/Status
🔄 Sync actions
📤 Upload/Push
🔓 Unlock
🩺 Health check
💡 Tips/Hints
✓ Success
✗ Error
⚠ Warning
```

---

## Terminal Width Considerations

All mockups designed for **80 characters minimum**:
- Headers: 45 chars + borders
- Separator lines: Full width
- Content: Indented 2-3 spaces
- No horizontal scrolling
- Responsive to terminal width

---

## Accessibility Notes

- High contrast colors (WCAG AA compliant)
- Icons supplement text (not replace)
- Screen reader friendly (clean text output)
- Keyboard-only navigation
- No color-only information (always has text)

---

**Status:** Visual design complete
**Next:** Implement `dot-dispatcher.zsh` following these mockups
**Testing:** Verify output matches mockups exactly
