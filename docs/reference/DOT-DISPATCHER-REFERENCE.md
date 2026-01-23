# Dot Dispatcher Reference

**Command:** `dot`
**Purpose:** Dotfile management via chezmoi, secrets via Keychain/Bitwarden
**Version:** v5.5.0 (macOS Keychain Integration)

---

## Overview

The `dot` dispatcher provides a unified interface for managing dotfiles with chezmoi and secrets via macOS Keychain (local, instant) or Bitwarden (cloud, synced). It integrates seamlessly with flow-cli's dashboard and doctor commands.

### Key Features

- 📝 **Dotfile sync** (chezmoi integration)
- 🍎 **macOS Keychain** (instant secrets, Touch ID, offline)
- 🔐 **Bitwarden integration** (cloud secrets, team sharing)
- 🧙 **Token wizards** (GitHub, NPM, PyPI token creation)
- 🔄 **Token rotation** (refresh tokens with `--refresh`)
- 📊 **Secrets dashboard** (expiration tracking)
- 🔗 **CI/CD integration** (GitHub secrets sync, direnv)
- 🎯 **ADHD-friendly** (smart defaults, clear status, progressive disclosure)
- ⚡ **Fast** (< 500ms for most operations)
- 🔌 **Optional** (graceful degradation if tools not installed)

**✨ New in v5.5.0 - macOS Keychain Integration:**
- 🔐 **Native Keychain** - `dot secret` uses macOS Keychain by default
- ⚡ **Instant access** - No unlock step needed, Touch ID support
- 🍎 **Touch ID / Apple Watch** - Biometric authentication
- 🔒 **Auto-lock** - Locks with screen lock, works offline
- 🔄 **Bitwarden fallback** - `dot secret bw <cmd>` for cloud secrets
- 📥 **Import** - `dot secret import` migrates from Bitwarden

**✨ v5.2.0 - Secret Management v2.0:**
- 🧙 **Token wizards** - `dot token github/npm/pypi` guided creation
- 🔄 **Token rotation** - `dot token <name> --refresh` to rotate tokens
- 📊 **Secrets dashboard** - `dot secrets` shows all tokens with expiration
- ⏱️ **Session cache** - 15-minute auto-lock for security
- 🔗 **GitHub sync** - `dot secrets sync github` syncs to repo secrets
- 📁 **Direnv integration** - `dot env init` generates `.envrc`

**✨ New in v5.1.1:**
- ➕ **`dot add`** - Standalone command to add files to chezmoi
- 🆕 **Auto-add in edit** - `dot edit` offers to add untracked files
- 📁 **File creation** - `dot edit ~/.newrc` creates new files with `mkdir -p`
- 🔐 **Template auto-unlock** - Auto-prompts for BW vault when editing `.tmpl` files
- 📋 **Summary with tips** - Shows next step hints after operations
- 🏠 **ZDOTDIR support** - Uses standard `${ZDOTDIR:-$HOME}` for shell config paths

**✨ New in v5.1.0:**
- 🔍 **Hash-based change detection** - SHA-256 comparison catches all edits (even < 1s)
- 🎯 **Smart error handling** - Specific guidance for each Bitwarden error type
- 👀 **Dry-run mode** - Preview changes safely with `--dry-run` / `-n` flag

---

## Quick Start

```bash
# Check dotfile status
dot

# Add a file to chezmoi
dot add ~/.bashrc

# Edit a dotfile (with preview & apply)
dot edit .zshrc

# Sync from remote
dot sync

# Preview changes without applying
dot apply --dry-run

# === Keychain Secrets (v5.5.0 - Recommended) ===

# Store a secret (prompts for value, Touch ID enabled)
dot secret add github-token

# Get a secret instantly (no unlock needed!)
TOKEN=$(dot secret github-token)

# List all Keychain secrets
dot secret list

# Delete a secret
dot secret delete old-token

# Import from Bitwarden (one-time migration)
dot secret import

# === Bitwarden Cloud Secrets (fallback) ===

# Unlock Bitwarden vault (15-min session)
dot unlock

# Access Bitwarden secrets directly
TOKEN=$(dot secret bw github-token)

# Create token with guided wizard
dot token github          # GitHub PAT wizard
dot token npm             # NPM token wizard
dot token pypi            # PyPI token wizard

# Rotate an existing token
dot token github-token --refresh

# View all secrets with expiration
dot secrets

# Sync secrets to GitHub repo
dot secrets sync github

# Generate .envrc for direnv
dot env init
```

---

## Command Reference

### Status & Info

#### `dot` / `dot status` / `dot s`

Show dotfile sync status and summary.

**Output:**
```
Dotfile Status: 🟢 Synced

Last sync:     2 hours ago
Tracked files: 12
Remote:        git@github.com:user/dotfiles.git
Modified:      0 files pending

Run 'dot help' for commands
```

**Status Icons:**
- 🟢 **Synced** - Everything up to date
- 🟡 **Modified** - Local changes pending
- 🔴 **Behind** - Remote has new commits
- 🔵 **Ahead** - Local commits not pushed

#### `dot help` / `dot --help` / `dot -h`

Show detailed help with examples.

#### `dot version` / `dot --version` / `dot -v`

Show version information.

---

### Dotfile Management

#### `dot add FILE` (v5.1.1+)

Add a file to chezmoi for tracking.

**Features:**
- Adds existing files to chezmoi
- Shows source path in chezmoi directory
- Provides next step hint

**Examples:**
```bash
dot add ~/.bashrc        # Add bash config
dot add ~/.config/app/config.toml  # Add nested config
```

**Output:**
```
✓ Added ~/.bashrc to chezmoi
  Source: ~/.local/share/chezmoi/dot_bashrc

💡 Tip: dot edit .bashrc to make changes
```

---

#### `dot edit FILE` / `dot e FILE`

Edit a dotfile with preview and apply workflow.

**Features:**
- Opens file in `$EDITOR`
- **Hash-based change detection** (v5.1.0) - SHA-256 comparison catches ALL edits
- Shows diff preview
- Prompts to apply changes
- Fuzzy path matching (e.g., `dot edit zshrc` finds `.zshrc`)
- **Auto-add untracked files** (v5.1.1) - Offers to add existing files not yet tracked
- **Create new files** (v5.1.1) - Creates non-existent files with `mkdir -p`
- **Template auto-unlock** (v5.1.1) - Prompts to unlock BW vault for `.tmpl` files
- **Summary with tips** (v5.1.1) - Shows next step hint after operation

**Examples:**
```bash
dot edit .zshrc          # Edit ZSH config
dot edit zshrc           # Fuzzy match works too
dot e gitconfig          # Short alias
dot edit ~/.bashrc       # Auto-add if untracked (v5.1.1+)
dot edit ~/.config/new/app.zsh  # Create new file (v5.1.1+)
```

**Workflow for tracked files:**
1. Calculates SHA-256 hash of file before editing
2. Opens file in editor
3. You make changes and save (even quick edits < 1s are detected!)
4. Compares hash after saving - detects ANY content change
5. Shows diff: `Modified: ~/.zshrc`
6. Prompts: `Apply changes? [Y/n/d(iff)]`
7. If yes: Runs `chezmoi apply`
8. Shows summary with next step tip

**Workflow for untracked files (v5.1.1+):**
```
$ dot edit ~/.bashrc

⚠ File not tracked: ~/.bashrc

  a - Add to chezmoi and edit
  n - Cancel

Add? [a/n] a

✓ Added ~/.bashrc to chezmoi
ℹ Opening in vim: dot_bashrc

[editor opens, you make changes]

✓ Changes detected!
─────────────────────────────────────────────────
[diff preview]
─────────────────────────────────────────────────

Apply? [Y/n/d] y

✓ Applied changes

📋 ~/.bashrc | Added + Applied
💡 Tip: dot push to sync to remote
```

**Workflow for new files (v5.1.1+):**
```
$ dot edit ~/.config/newapp/config.zsh

⚠ File does not exist: ~/.config/newapp/config.zsh

  c - Create, add to chezmoi, and edit
  n - Cancel

Create? [c/n] c

⊙ Created directory: ~/.config/newapp
✓ Created ~/.config/newapp/config.zsh
✓ Added ~/.config/newapp/config.zsh to chezmoi
ℹ Opening in vim: dot_config/newapp/config.zsh
```

**Template auto-unlock (v5.1.1+):**

When editing `.tmpl` files that contain `{{ bitwarden ... }}` syntax:
```
$ dot edit .env.tmpl

[editor opens, you make changes]

✓ Changes detected!

🔐 This template uses Bitwarden secrets.
   Unlock vault to preview expanded values?

  y - Unlock and preview
  s - Skip preview (show raw template)
  n - Cancel

Unlock? [y/s/n] y

ℹ Unlocking Bitwarden vault...
[password prompt]
✓ Vault unlocked

─────────────────────────────────────────────────
[diff preview with secrets expanded]
─────────────────────────────────────────────────

Apply? [Y/n] y

✓ Applied changes

📋 .env.tmpl | Edited (secrets expanded) + Applied
💡 Tip: dot push to sync to remote
```

If you skip unlock, the diff shows raw template syntax like `{{ bitwarden "item" "field" }}`.

**Why hash-based detection? (v5.1.0)**

Traditional `mtime` (modification time) has ~1 second granularity, causing false negatives on quick edits—especially problematic for ADHD users who edit rapidly. SHA-256 hash comparison is deterministic and catches ALL changes, regardless of timing.

#### `dot sync` / `dot pull`

Pull changes from remote repository.

**Features:**
- Fetches latest from remote
- Shows diff preview
- Prompts before applying
- Handles merge conflicts

**Examples:**
```bash
dot sync                 # Pull with preview
dot pull                 # Alias
```

**Workflow:**
1. Fetches from remote
2. Shows pending changes
3. Prompts: `Apply updates? [Y/n/d(iff)]`
4. If yes: Pulls and applies changes

#### `dot push` / `dot p`

Commit and push changes to remote.

**Features:**
- Auto-stages modified files
- Prompts for commit message
- Pushes to remote

**Examples:**
```bash
dot push                 # Commit & push
dot p                    # Short alias
```

**Workflow:**
1. Shows modified files
2. Prompts for commit message
3. Commits with message
4. Pushes to remote

#### `dot diff` / `dot d`

Show pending changes.

**Features:**
- Shows detailed diff
- Colored output
- Can filter by file

**Examples:**
```bash
dot diff                 # Show all changes
dot d                    # Short alias
dot diff .zshrc          # Show changes for specific file
```

#### `dot apply` / `dot a`

Apply pending changes to home directory.

**Features:**
- Applies templated changes
- Shows files being updated
- Safe operation (creates backups)
- **Dry-run mode** (v5.1.0) - Preview without applying

**Examples:**
```bash
dot apply                # Apply all pending changes
dot a                    # Short alias
dot apply .zshrc         # Apply specific file

# v5.1.0: Dry-run mode (preview only)
dot apply --dry-run      # Preview all changes (no apply)
dot apply -n             # Short flag
dot apply -n .zshrc      # Preview specific file
```

**Dry-Run Mode (v5.1.0):**

Preview exactly what would change WITHOUT actually applying:

```bash
$ dot apply --dry-run

DRY-RUN MODE - No changes will be applied

Showing what would change (dry-run)...

Files to update: 2

M .zshrc
M .gitconfig

[Shows verbose diff of what would change]

✓ Dry-run complete - no changes applied
```

**Use cases for dry-run:**
- ✅ Preview changes before applying
- ✅ Verify template expansions look correct
- ✅ Check Bitwarden secret substitutions
- ✅ Safe exploration (no risk of breaking configs)
- ✅ ADHD-friendly (see before you commit)

---

### macOS Keychain Secrets (v5.5.0+)

The default secret storage uses macOS Keychain for instant, session-free access with Touch ID support.

#### `dot secret add <name>`

Store a secret in macOS Keychain.

**Features:**
- Hidden input (no terminal echo)
- Touch ID / Apple Watch support
- Auto-updates existing secrets
- No unlock step required

**Examples:**
```bash
dot secret add github-token     # Store a GitHub token
dot secret add api-key          # Store any secret
```

**Output:**
```
Enter secret value: ········
✓ Secret 'github-token' stored in Keychain
```

#### `dot secret <name>` / `dot secret get <name>`

Retrieve a secret from Keychain (instant, no unlock needed).

**Features:**
- Instant access (no session required)
- Touch ID authentication
- Silent output (safe for scripts)
- Works offline

**Examples:**
```bash
# Capture in variable
TOKEN=$(dot secret github-token)

# Use in command
gh auth login --with-token <<< $(dot secret github-token)

# Use in curl
curl -H "Authorization: Bearer $(dot secret api-key)" https://api.example.com
```

#### `dot secret list`

List all secrets stored in Keychain.

**Examples:**
```bash
dot secret list
```

**Output:**
```
ℹ Secrets in Keychain (flow-cli):
  • github-token
  • npm-token
  • pypi-token
```

#### `dot secret delete <name>`

Remove a secret from Keychain.

**Examples:**
```bash
dot secret delete old-token
```

**Output:**
```
✓ Secret 'old-token' deleted
```

#### `dot secret import`

One-time import from Bitwarden to Keychain.

**Features:**
- Imports from Bitwarden folder `flow-cli-secrets`
- Requires Bitwarden unlocked first
- Confirmation prompt before import

**Examples:**
```bash
dot unlock                    # Unlock Bitwarden first
dot secret import             # Import to Keychain
```

#### `dot secret bw <cmd>`

Access Bitwarden cloud secrets directly (backwards compatibility).

**Commands:**
```bash
dot secret bw <name>          # Get secret from Bitwarden
dot secret bw list            # List Bitwarden items
dot secret bw add <name>      # Add to Bitwarden
dot secret bw check           # Check expiring secrets
```

**When to use Bitwarden:**
- Cloud-synced secrets across devices
- Team shared secrets
- Token expiration tracking
- CI/CD integration (`dot secrets sync github`)

---

### Bitwarden Secret Management

#### `dot unlock` / `dot u`

Unlock Bitwarden vault for the current shell session.

**Features:**
- Session-scoped (not persistent)
- Exports `BW_SESSION` environment variable
- Shows security reminders
- Validates unlock success

**Examples:**
```bash
dot unlock               # Unlock vault
dot u                    # Short alias
```

**Output:**
```
ℹ Enter your Bitwarden master password:
[password prompt]

✓ Vault unlocked successfully

  Session active in this shell only (not persistent)
ℹ Use 'dot secret <name>' to retrieve secrets

⚠ Security reminder:
  • Session expires when shell closes
  • Don't export BW_SESSION globally
  • Lock vault when done: bw lock
```

**Security:**
- Session token stored in memory only
- Not saved to disk
- Not exported to startup files
- Expires when shell closes

#### `dot secret NAME`

Retrieve a secret by name (returns value without echo).

**Features:**
- No terminal echo (secure)
- Safe for variable capture
- Validates session first
- Suppresses stderr

**Examples:**
```bash
# Capture in variable
TOKEN=$(dot secret github-token)

# Use in command
curl -H "Authorization: Bearer $(dot secret api-key)" https://api.example.com

# Check if available
if dot secret github-token >/dev/null 2>&1; then
  echo "Secret exists"
fi
```

**Error Handling (v5.1.0 - Improved):**

Smart error detection with specific guidance for each error type:

```bash
# Secret not found
$ dot secret nonexistent-item
✗ Secret not found: nonexistent-item
Tip: Use 'dot secret list' to see available items

# Session expired
$ dot secret github-token
✗ Session expired
Run: dot unlock

# Vault locked
$ dot secret api-key
✗ Vault is locked
Run: dot unlock

# Access denied (permissions)
$ dot secret protected-item
✗ Access denied for secret: protected-item
Check Bitwarden permissions for this item
```

**How it works (v5.1.0):**

Instead of generic "failed to retrieve" messages, the dispatcher now:
1. Captures `stderr` from Bitwarden CLI securely (using `mktemp`)
2. Parses error patterns ("Not found", "Session key", "locked", "access denied")
3. Provides specific, actionable guidance for each error type
4. Cleans up temp files automatically (no data leaks)

#### `dot secret list`

List all items in Bitwarden vault.

**Features:**
- Shows item type icons (🔑 login, 📝 note, 💳 card)
- Displays folder organization
- Colored output
- Falls back gracefully if `jq` not installed

**Examples:**
```bash
dot secret list
```

**Output:**
```
ℹ Retrieving items from vault...

🔑 github-token (Work/GitHub)
🔑 npm-token (Work/Node)
📝 ssh-passphrase (Personal)
💳 stripe-test-key (Work/Stripe)

ℹ Usage: dot secret <name>
```

#### `dot secret add <name>`

Store a new secret with hidden input and optional expiration tracking.

**Features:**
- Hidden input (no terminal echo)
- Expiration tracking with `--expires <days>`
- Optional notes with `--notes <text>`
- JSON metadata stored in Bitwarden notes field

**Examples:**
```bash
# Add a secret (prompts for value)
dot secret add api-key

# Add with expiration (90 days)
dot secret add github-token --expires 90

# Add with notes
dot secret add npm-token --notes "Automation token for CI"
```

**Output:**
```
🔐 Add Secret: api-key
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Enter secret value: ········

✓ Secret 'api-key' stored in Bitwarden
  Expires: never

💡 Usage: $(dot secret api-key)
```

#### `dot secret check`

Show expiring and expired secrets.

**Features:**
- Color-coded status (✓ valid, ⚠ expiring, ❌ expired)
- Shows days remaining
- Configurable warning threshold (default 30 days)

**Examples:**
```bash
dot secret check
```

**Output:**
```
🔐 Secret Status Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  ⚠ npm-token         Expiring in 12 days
  ✓ github-token      Valid (45 days)
  ❌ old-api-key       Expired 5 days ago

💡 Run: dot token <name> --refresh to rotate
```

#### `dot lock`

Lock Bitwarden vault immediately.

**Examples:**
```bash
dot lock    # Lock vault and clear session
```

---

### Token Wizards (v5.2.0)

Guided token creation with validation and secure storage.

#### `dot token github`

GitHub Personal Access Token creation wizard.

**Features:**
- Classic vs Fine-grained token selection
- Recommended scopes based on project type
- Opens browser to token creation page
- Token format validation (ghp_ / github_pat_)
- API validation against GitHub
- Stores with expiration metadata

**Examples:**
```bash
dot token github                          # Interactive wizard
dot token github --type fine-grained      # Skip type selection
dot token gh                              # Alias
```

**Flow:**
```
🔐 GitHub Token Setup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Token type:
  [1] Classic PAT (broad permissions)
  [2] Fine-grained PAT (recommended)

Select [1/2]: 2

Recommended scopes for this project (flow-cli):
  ✓ Contents (read/write) - push code
  ✓ Workflows - GitHub Actions
  ✓ Metadata (read) - basic repo info

Press Enter to open github.com...
[browser opens]

Paste your new token: ········

Expiration (days, 0=never) [90]: 90

✓ Token validated (scopes: repo, workflow)
✓ Stored in Bitwarden as "github-token"
✓ Expires: 2026-04-10 (90 days)

💡 Usage: GITHUB_TOKEN=$(dot secret github-token)
```

#### `dot token npm`

NPM token creation wizard.

**Features:**
- Automation/Read-only/Granular token types
- Token format validation (npm_)
- API validation against NPM registry
- Stores with scope metadata

**Examples:**
```bash
dot token npm           # Interactive wizard
```

#### `dot token pypi`

PyPI token creation wizard.

**Features:**
- Account-wide vs Project-scoped tokens
- Token format validation (pypi-)
- Trusted Publishing recommendation
- Stores with scope metadata

**Examples:**
```bash
dot token pypi          # Interactive wizard
```

---

### Token Rotation (v5.2.0)

Rotate existing tokens with full lifecycle tracking.

#### `dot token <name> --refresh`

Rotate an existing DOT-managed token.

**Features:**
- Automatic type detection from metadata
- Opens browser for new token creation
- Validates new token against provider API
- Updates stored token with new value
- Records rotation history in metadata
- Reminds to revoke old token

**Syntax Options:**
```bash
dot token github-token --refresh     # Flag after name
dot token github-token -r            # Short flag
dot token refresh github-token       # Keyword before name
```

**Flow:**
```
🔄 Rotating Token: github-token
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Looking up token metadata...

  Token Type: github (fine-grained)
  Created: 2026-01-10
  Expires: 2026-04-10 (in 45 days)

  Opening browser to create new token...
  [browser opens]

  Paste new token: ········

  Expiration (days) [90]: 90

✓ Token validated against GitHub API
✓ Token updated in Bitwarden
✓ Expiration: 2026-04-11 (90 days)

⚠ Remember to revoke the old token at:
  https://github.com/settings/tokens
```

**Requirements:**
- Token must have DOT metadata (`dot_version` in notes)
- Tokens created with `dot token` wizards have this automatically
- Manually-added tokens need metadata to use `--refresh`

---

### Secrets Dashboard (v5.2.0)

Overview of all DOT-managed secrets.

#### `dot secrets`

Show dashboard of all secrets with status and expiration.

**Features:**
- Token type, status, and expiration display
- Color-coded: ✓ Valid, ⚠ Expiring, ❌ Expired
- Vault unlock status with time remaining
- Actionable tips for expiring tokens

**Examples:**
```bash
dot secrets             # Show dashboard
dot secrets help        # Show subcommand help
```

**Output:**
```
🔐 Secret Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Token              Type      Status      Expires
  ─────────────────────────────────────────────────
  github-token       github    ✓ Valid     in 45 days
  npm-token          npm       ⚠ Expiring  in 12 days
  pypi-flow-cli      pypi      ✓ Valid     in 180 days
  anthropic-key      api       ✓ Valid     never

  Vault: 🔓 Unlocked (12 min remaining)

  ⚠ 1 token expiring soon
  💡 Run: dot token npm --refresh
```

---

### Token Health & Automation (v5.16.0)

Proactive token expiration detection and rotation workflows.

#### `dot token expiring`

Check GitHub token expiration status across all DOT-managed tokens.

**Features:**
- Validates all GitHub tokens via GitHub API
- Calculates age from enhanced Keychain metadata (dot_version 2.1)
- Reports expired and expiring tokens (< 7 days remaining)
- Prompts for rotation if issues found
- Zero output if all tokens are healthy (silent success)

**Examples:**
```bash
dot token expiring          # Check all GitHub tokens
flow token expiring         # Alias via flow command
```

**Output (when issues found):**
```
🔴 EXPIRED tokens:
  🔴 old-github-token - Expired (revoke ASAP)

🟡 EXPIRING tokens (< 7 days remaining):
  🟡 github-token - 3 days remaining

Rotate expiring/expired tokens now? [y/n]
```

**Output (when healthy):**
```
✅ All GitHub tokens are current (> 7 days remaining)
```

**Integration:**
- Called by `g push/pull` before GitHub remote operations
- Displayed in `dash dev` dashboard
- Checked by `work` on session start for GitHub projects
- Validated by `finish` before committing to GitHub repos
- Included in `flow doctor` health checks

---

#### `dot token rotate [name]`

Semi-automated token rotation workflow with backup and validation.

**Features:**
- Backs up old token before rotation (safety net)
- Validates new token via GitHub API (real-time check)
- Prompts for manual revocation on GitHub (security best practice)
- Logs rotation events with audit trail in metadata
- Auto-syncs with gh CLI (`gh auth login`)
- Updates both Bitwarden vault and Keychain with new metadata

**Examples:**
```bash
dot token rotate              # Rotate github-token (default)
dot token rotate my-token     # Rotate specific token
flow token rotate             # Alias via flow command
```

**Workflow:**
```
🔄 Rotating Token: github-token
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Looking up current token...

  Token Type: github (fine-grained)
  Created: 2026-01-10
  Age: 83 days
  Status: ⚠ Expiring soon

  Backing up current token...
  ✓ Backup saved to: github-token-backup

  Opening browser to create new token...
  https://github.com/settings/tokens/new
  [browser opens]

  Paste new token: ········

  Expiration (days) [90]: 90

  Validating token...
  ✓ Token validated (@your-username)

  Updating storage...
  ✓ Bitwarden vault updated
  ✓ Keychain updated with Touch ID
  ✓ Metadata: dot_version 2.1

  Syncing with gh CLI...
  ✓ gh CLI authenticated

⚠ MANUAL STEP REQUIRED:

  Revoke old token at:
  https://github.com/settings/tokens

  Look for token ending in: ···abc123

✅ Rotation complete!
```

**Requirements:**
- Bitwarden CLI (`bw`) installed and configured
- GitHub API access (for validation)
- `gh` CLI for auto-sync (optional but recommended)

**Safety Features:**
- Old token backed up before deletion
- New token validated before storage
- Manual revocation prompt (prevents premature deletion)
- Atomic updates (all-or-nothing storage)

---

#### `dot token sync gh`

Authenticate gh CLI with Keychain-stored GitHub token.

**Features:**
- Reads token from macOS Keychain (Touch ID)
- Pipes token securely to `gh auth login`
- Validates authentication after sync
- Zero clipboard exposure (direct pipe)

**Examples:**
```bash
dot token sync gh           # Sync github-token with gh CLI
flow token sync gh          # Alias via flow command
```

**Output:**
```
🔄 Syncing GitHub token with gh CLI...

  Reading token from Keychain...
  ✓ Token retrieved

  Authenticating gh CLI...
  ✓ gh CLI authenticated as @your-username

✅ gh CLI sync complete
```

**When to use:**
- After rotating GitHub token (`dot token rotate`)
- When `gh` commands fail with authentication errors
- After fresh gh CLI installation
- When switching between multiple GitHub accounts

**Note:** This command is automatically called by `dot token rotate`, so manual sync is rarely needed.

---

### Session Cache (v5.2.0)

Automatic session management with 15-minute idle timeout.

**Features:**
- File-based cache at `~/.cache/dot/session`
- Tracks unlock time and last activity
- Auto-locks after 15 minutes of inactivity
- Configurable via `DOT_SESSION_IDLE_TIMEOUT`
- Status shown in `dot` command output

**How it works:**
1. When you run `dot unlock`, session timestamp is cached
2. Each `dot` command updates the activity timestamp
3. After 15 minutes of no `dot` commands, session expires
4. Next `dot secret` command prompts for unlock

**Configuration:**
```bash
# Set custom timeout (in seconds)
export DOT_SESSION_IDLE_TIMEOUT=1800  # 30 minutes
```

**Status in `dot` output:**
```
📁 Dotfiles Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  State: 🟢 Synced

  🔐 Vault: 🔓 Unlocked (12 min remaining)
```

---

### CI/CD Integration (v5.2.0)

Sync secrets to CI/CD systems and generate environment files.

#### `dot secrets sync github`

Sync DOT-managed secrets to GitHub repository secrets.

**Features:**
- Interactive selection of which secrets to sync
- Uses `gh secret set` for secure sync
- Shows confirmation with secret names (not values)
- Supports filtering by type

**Examples:**
```bash
dot secrets sync github         # Interactive selection
```

**Flow:**
```
🔄 Sync Secrets to GitHub
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Repository: Data-Wise/flow-cli

  Available secrets:
    [1] github-token (github)
    [2] npm-token (npm)
    [3] anthropic-key (api)

  Select secrets to sync (1,2,3 or 'all'): 2,3

  Syncing 2 secrets...

✓ NPM_TOKEN synced to Data-Wise/flow-cli
✓ ANTHROPIC_KEY synced to Data-Wise/flow-cli

💡 These secrets are now available in GitHub Actions
```

#### `dot env init`

Generate `.envrc` file for direnv integration.

**Features:**
- Interactive selection of secrets to include
- Converts secret names to SCREAMING_SNAKE_CASE
- Auto-adds `.envrc` to `.gitignore` if not present
- Uses `dot secret` for secure retrieval

**Examples:**
```bash
dot env init            # Interactive selection
```

**Flow:**
```
📁 Generate .envrc
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Available secrets:
    [1] github-token
    [2] npm-token
    [3] anthropic-key

  Select secrets for .envrc (1,2,3 or 'all'): 1,3

  Generating .envrc...

✓ Created .envrc with 2 secrets
✓ Added .envrc to .gitignore

  Generated file:
  ─────────────────────────────
  export GITHUB_TOKEN=$(dot secret github-token)
  export ANTHROPIC_KEY=$(dot secret anthropic-key)
  ─────────────────────────────

💡 Run: direnv allow
```

---

### Troubleshooting

#### `dot doctor` / `dot dr`

Run diagnostics and health checks.

**Features:**
- Checks chezmoi installation
- Validates git remote
- Shows sync status
- Checks Bitwarden status
- Identifies security issues

**Examples:**
```bash
dot doctor               # Run diagnostics
dot dr                   # Short alias
```

**Also available via:**
```bash
flow doctor              # Includes dotfile checks
```

#### `dot undo`

Rollback last apply operation (emergency recovery).

**Features:**
- Reverts to previous state
- Shows what will be restored
- Confirms before reverting

**Examples:**
```bash
dot undo                 # Rollback last apply
```

---

### Setup

#### `dot init`

Initialize dotfile management (first-time setup).

**Features:**
- Initializes chezmoi
- Optionally clones existing dotfiles repo
- Sets up git remote
- Configures templates

**Examples:**
```bash
dot init                                    # Interactive setup
dot init https://github.com/user/dotfiles  # Clone from repo
```

---

## Integration

### Dashboard Integration

The `dash` command shows dotfile status automatically:

```
╭──────────────────────────────────────────────────────────────╮
│  🌊 FLOW DASHBOARD ✓                  Jan 09, 2026  🕐 14:30 │
╰──────────────────────────────────────────────────────────────╯

  ...

  📝 Dotfiles: 🟢 Synced (2h ago) · 12 files tracked

  ...
```

**Status Line Format:**
```
📝 Dotfiles: [icon] [state] [details] · [file count] tracked
```

**Conditional Display:**
- Only shows if chezmoi is installed
- Gracefully omits if not configured
- Fast (< 100ms, uses cached values)

### Doctor Integration

The `flow doctor` command includes dotfile health checks:

```
🔌 INTEGRATIONS
  ✓ atlas v3.1.0
  ○ radian (R not installed)

📁 DOTFILES
  ✓ chezmoi v2.45.0
  ✓ Bitwarden CLI v2024.1.0
  ✓ Chezmoi initialized with git
  ✓ Remote configured: git@github.com:user/dotfiles.git
  ✓ No uncommitted changes
  ✓ Synced with remote
  ✓ Bitwarden vault unlocked

🔌 PLUGIN MANAGER
  ...
```

---

## Chezmoi Templates

Use Bitwarden secrets in chezmoi templates:

### Template Syntax

```go
{{- /* Retrieve password field from Bitwarden item */ -}}
{{- bitwarden "item" "github-token" -}}

{{- /* Retrieve specific field */ -}}
{{- bitwardenFields "item" "api-key" "custom-field-name" -}}

{{- /* Retrieve from secure notes */ -}}
{{- bitwardenFields "item" "ssh-key" "notes" -}}
```

### Example: `.gitconfig` with GitHub Token

**Template:** `~/.local/share/chezmoi/dot_gitconfig.tmpl`

```ini
[user]
    name = Your Name
    email = your@email.com

[github]
    user = youruser
    token = {{ bitwarden "item" "github-token" }}
```

**Apply:**
```bash
dot unlock           # Unlock Bitwarden
dot edit .gitconfig  # Edit and apply template
```

### Example: `.zshrc` with API Keys

**Template:** `~/.local/share/chezmoi/dot_zshrc.tmpl`

```bash
# API Keys (from Bitwarden)
export OPENAI_API_KEY="{{ bitwarden "item" "openai-key" }}"
export ANTHROPIC_API_KEY="{{ bitwarden "item" "anthropic-key" }}"
export GITHUB_TOKEN="{{ bitwarden "item" "github-token" }}"
```

---

## Security Best Practices

### ✅ DO

- **Unlock per-session:** Run `dot unlock` in each shell where you need secrets
- **Lock when done:** Run `bw lock` after template operations
- **Use templates:** Store templates in chezmoi, not plain files with secrets
- **Capture securely:** Use `VAR=$(dot secret name)` to capture without echo
- **Validate items:** Use `dot secret list` to verify item names

### ❌ DON'T

- **Don't export globally:** Never add `export BW_SESSION=...` to `.zshrc`
- **Don't commit secrets:** Never commit files with actual secret values
- **Don't echo secrets:** Avoid `echo $(dot secret name)` in scripts
- **Don't log secrets:** Ensure secrets aren't written to logs/history
- **Don't share sessions:** Each user should unlock their own vault

---

## Configuration

### Environment Variables

```bash
# No configuration needed - uses chezmoi and bw defaults
# Optional: customize chezmoi directory
export CHEZMOI_SOURCE_DIR="$HOME/.local/share/chezmoi"
```

### Prerequisites

- **Required for dotfiles:** `chezmoi` (brew install chezmoi)
- **Required for secrets:** `bitwarden-cli` (brew install bitwarden-cli)
- **Optional:** `jq` (brew install jq) - for pretty secret listing

**Install all:**
```bash
brew install chezmoi bitwarden-cli jq
```

---

## Performance

### Benchmarks

| Operation | Time | Notes |
|-----------|------|-------|
| `dot` / `dot status` | < 500ms | Runs chezmoi status |
| `dot edit <file>` | instant | Opens editor immediately |
| `dot edit <file>` (hash calc) | +1-2ms | SHA-256 overhead (v5.1.0) |
| `dot apply --dry-run` | same as apply | Uses chezmoi native dry-run |
| `dot sync` | 1-3s | Fetches from remote |
| `dot push` | 1-3s | Pushes to remote |
| `dot secret <name>` | < 200ms | Retrieves from vault |
| `dot secret list` | 300-500ms | Lists all items |
| Dashboard status | < 100ms | Uses cached values |

### Optimization Tips

- **Dashboard caching:** Status cached for fast display
- **Lazy loading:** dot dispatcher only loaded when called
- **Conditional checks:** Operations skip if tools not installed
- **Hash detection** (v5.1.0): SHA-256 is extremely fast (~1ms for typical dotfiles) - the deterministic accuracy far outweighs the negligible overhead

---

## Troubleshooting

### "Chezmoi not initialized"

**Cause:** Chezmoi hasn't been set up yet.

**Solution:**
```bash
dot init                                    # Interactive setup
# OR
chezmoi init https://github.com/user/dotfiles  # Clone existing
```

### "Bitwarden vault is locked"

**Cause:** No active `BW_SESSION` in current shell.

**Solution:**
```bash
dot unlock
```

### "Secret not found" (v5.1.0)

**Cause:** Item name doesn't exist in vault.

**Solution:**
```bash
# List all items to find correct name
dot secret list

# Check exact name (case-sensitive)
bw get item github-token
```

### "Session expired" (v5.1.0)

**Cause:** `BW_SESSION` environment variable is invalid or expired.

**Solution:**
```bash
# Simply unlock again
dot unlock
```

### "Access denied for secret" (v5.1.0)

**Cause:** Bitwarden permissions restrict access to this item.

**Solution:**
- Check if item is in a collection you don't have access to
- Verify item permissions in Bitwarden web vault
- Contact vault administrator if using org vault

### "Bitwarden not authenticated"

**Cause:** Not logged into Bitwarden CLI.

**Solution:**
```bash
bw login
```

### Session Token in History

**Concern:** `bw unlock --raw` output might be in shell history.

**Solution:** The `dot unlock` command captures output safely without exposing tokens. ZSH history exclusion patterns prevent storage of sensitive commands.

**Verify history settings:**
```bash
# Check if HISTIGNORE includes bw commands
echo $HISTIGNORE

# Should include: *bw unlock*:*bw get*:*BW_SESSION*
```

---

## Aliases

Built-in aliases for common operations:

```bash
dot s          # status
dot e FILE     # edit
dot d          # diff
dot a          # apply
dot p          # push
dot u          # unlock
dot dr         # doctor
```

---

## See Also

- [Chezmoi Documentation](https://www.chezmoi.io/)
- [Bitwarden CLI Documentation](https://bitwarden.com/help/cli/)
- [SECRET-MANAGEMENT.md](../SECRET-MANAGEMENT.md) - Comprehensive secret management guide
- [PHASE3-IMPLEMENTATION-SUMMARY.md](../PHASE3-IMPLEMENTATION-SUMMARY.md) - Technical implementation details
- [PHASE4-SUMMARY.md](../PHASE4-SUMMARY.md) - Dashboard integration details

---

**Version:** v5.1.0 (Critical Improvements)
**Last Updated:** 2026-01-10
