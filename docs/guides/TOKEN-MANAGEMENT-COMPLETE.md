---
tags:
  - guide
  - security
  - configuration
---

# Complete Token & Secret Management Guide

**Version:** 5.18.0-dev
**Last Updated:** 2026-01-24
**Author:** flow-cli Documentation Team

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Adding Tokens](#2-adding-tokens)
3. [Retrieving and Using Tokens](#3-retrieving-and-using-tokens)
4. [Updating Tokens](#4-updating-tokens)
5. [Rotating Tokens](#5-rotating-tokens)
6. [Deleting Tokens](#6-deleting-tokens)
7. [Expiration Management](#7-expiration-management)
8. [Troubleshooting](#8-troubleshooting)
9. [Security Best Practices](#9-security-best-practices)
10. [Migration Guide](#10-migration-guide)

---

## 1. Architecture Overview

### 1.1 Dual Storage System

flow-cli uses **two storage backends simultaneously** for optimal balance of security, speed, and reliability:

```
┌─────────────────────────────────────────────────────────────┐
│                   USER ACTION                               │
│                 dot token github                            │
└────────────────────┬────────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
        ▼                         ▼
┌──────────────────┐     ┌──────────────────┐
│   BITWARDEN      │     │    KEYCHAIN      │
│   (Cloud Sync)   │     │  (Instant Access)│
├──────────────────┤     ├──────────────────┤
│ • password:      │     │ • -w: token      │
│   token value    │     │   (protected)    │
│ • notes:         │     │ • -j: metadata   │
│   metadata JSON  │     │   (searchable)   │
│                  │     │                  │
│ Speed: ~2-5s     │     │ Speed: < 50ms    │
│ Requires unlock  │     │ Touch ID         │
│ Web accessible   │     │ Offline ready    │
└──────────────────┘     └──────────────────┘
        │                         │
        └────────────┬────────────┘
                     │
                     ▼
            Token available for use
```

### 1.2 Why Two Backends?

| Requirement | Solution | Backend |
|-------------|----------|---------|
| **Cloud backup** | Encrypted vault sync | Bitwarden |
| **Cross-device access** | Web/mobile apps | Bitwarden |
| **Instant retrieval** | Local encrypted cache | Keychain |
| **Touch ID support** | macOS native integration | Keychain |
| **Offline mode** | No network required | Keychain |
| **Expiration checks** | Metadata without unlock | Keychain (-j flag) |

**Key Principle:** Bitwarden is the **source of truth**, Keychain is the **performance cache**.

### 1.3 Metadata Format (v2.1)

Every token stores metadata in JSON format:

```json
{
  "dot_version": "2.1",
  "type": "github",
  "token_type": "classic",
  "created": "2026-01-24T14:30:00Z",
  "expires_days": 90,
  "expires": "2026-04-24",
  "github_user": "username"
}
```

**Storage locations:**
- **Bitwarden:** `notes` field (full text)
- **Keychain:** `-j` flag (JSON attributes, searchable)

### 1.4 Security Model

#### Keychain Storage

```bash
security add-generic-password \
  -a "$token_name" \           # Account: searchable identifier
  -s "flow-cli" \              # Service: namespace
  -w "$token_value" \          # Password: ENCRYPTED (Touch ID required)
  -j "$metadata" \             # JSON attrs: searchable metadata
  -U                           # Update if exists
```

**Security properties:**
- ✅ Password (`-w`) is **encrypted** (requires authentication)
- ✅ JSON attributes (`-j`) are **searchable** (no unlock needed)
- ✅ JSON attributes are **NOT sensitive** (only dates, types)
- ✅ Service name (`flow-cli`) **isolates** from other apps

**Why `-j` flag is safe:**
- Metadata doesn't contain secrets (only timestamps, types, usernames)
- Enables fast expiration checks without Touch ID prompts
- Still protected by Keychain database encryption
- User can search/filter tokens without unlocking

---

## 2. Adding Tokens

### 2.1 GitHub Personal Access Token

#### 2.1.1 Classic PAT

**When to use:**
- Legacy integrations requiring classic PAT
- Broad permissions needed
- Organization doesn't support fine-grained PATs

**Creation wizard:**

```bash
dot token github
```

**Interactive steps:**

```
╭───────────────────────────────────────────────────╮
│  GitHub Personal Access Token Setup               │
├───────────────────────────────────────────────────┤
│                                                   │
│  1. Classic PAT (90 days, repo-wide access)       │
│  2. Fine-grained PAT (recommended, scoped)        │
│                                                   │
│  Choose: 1 or 2? [2]                              │
╰───────────────────────────────────────────────────╯

[User selects 1]

✓ Opening GitHub token creation page...
  URL: https://github.com/settings/tokens/new

┌─────────────────────────────────────────────┐
│ RECOMMENDED SCOPES (Classic PAT)            │
├─────────────────────────────────────────────┤
│ ✓ repo         Full repository access      │
│ ✓ workflow     Update GitHub workflows      │
│ ✓ read:org     Read org membership          │
│                                             │
│ Expiration: 90 days (recommended)           │
└─────────────────────────────────────────────┘

[Browser opens to https://github.com/settings/tokens/new]

After creating token, paste here:
Token: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

✓ Validating token...
✓ Token valid for user: yourusername
✓ Storing in Bitwarden...
✓ Storing in Keychain...

Token name: github-token
Expires: 2026-04-24 (90 days)

╭───────────────────────────────────────────────────╮
│  ✓ Token stored successfully                     │
│                                                   │
│  Name: github-token                               │
│  Type: GitHub Classic PAT                         │
│  User: yourusername                               │
│  Expires: 2026-04-24 (90 days)                    │
│                                                   │
│  Usage:                                           │
│    export GITHUB_TOKEN=$(dot secret github-token)│
│    gh auth login --with-token <<< \              │
│      $(dot secret github-token)                  │
╰───────────────────────────────────────────────────╯
```

**What happens behind the scenes:**

1. **Validation:**
   - Checks token format (`ghp_*`)
   - Tests against GitHub API (`GET /user`)
   - Verifies scopes

2. **Bitwarden storage:**
   ```
   Item name: github-token
   Username: yourusername
   Password: ghp_xxxx...
   Notes: {"dot_version":"2.1","type":"github",...}
   ```

3. **Keychain storage:**
   ```
   Account: github-token
   Service: flow-cli
   Password: ghp_xxxx... (encrypted)
   JSON attrs: {"dot_version":"2.1","type":"github",...}
   ```

4. **Sync:**
   - Bitwarden vault synced to cloud
   - Keychain immediately available

#### 2.1.2 Fine-grained PAT (Recommended)

**Advantages:**
- Scoped to specific repositories
- Granular permissions
- Works with 2FA
- Better security auditing

**Creation wizard:**

```bash
dot token github
```

**Interactive steps:**

```
╭───────────────────────────────────────────────────╮
│  GitHub Personal Access Token Setup               │
├───────────────────────────────────────────────────┤
│                                                   │
│  1. Classic PAT (90 days, repo-wide access)       │
│  2. Fine-grained PAT (recommended, scoped)        │
│                                                   │
│  Choose: 1 or 2? [2]                              │
╰───────────────────────────────────────────────────╯

[User selects 2]

✓ Opening GitHub fine-grained token page...
  URL: https://github.com/settings/personal-access-tokens/new

┌─────────────────────────────────────────────┐
│ RECOMMENDED SETTINGS (Fine-grained PAT)     │
├─────────────────────────────────────────────┤
│ Token name: flow-cli-token                  │
│ Expiration: 90 days                         │
│ Resource owner: [Your account/org]          │
│ Repository access: Select repositories      │
│                                             │
│ PERMISSIONS:                                │
│   Contents: Read and write                  │
│   Metadata: Read-only (required)            │
│   Pull requests: Read and write             │
│   Workflows: Read and write                 │
└─────────────────────────────────────────────┘

[Browser opens to token creation page]

After creating token, paste here:
Token: github_pat_xxxxxxxxxxxxxxxxxxxxxxxxxxxx

✓ Validating token...
✓ Token valid for user: yourusername
✓ Storing in Bitwarden...
✓ Storing in Keychain...

Token name: github-token
Expires: 2026-04-24 (90 days)
```

**Token format:** `github_pat_*` (different from classic `ghp_*`)

### 2.2 npm Token

**When to use:**
- Publishing npm packages
- CI/CD pipelines
- Automated deployments

**Creation wizard:**

```bash
dot token npm
```

**Interactive steps:**

```
╭───────────────────────────────────────────────────╮
│  npm Access Token Setup                           │
├───────────────────────────────────────────────────┤
│                                                   │
│  Token types:                                     │
│  1. Automation (CI/CD, read-only by default)      │
│  2. Publish (package publishing)                  │
│  3. Read-only (download only)                     │
│                                                   │
│  Choose: 1, 2, or 3? [2]                          │
╰───────────────────────────────────────────────────╯

[User selects 2]

✓ Opening npm token creation page...
  URL: https://www.npmjs.com/settings/~/tokens/new

After creating token, paste here:
Token: npm_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

✓ Validating token...
✓ Token valid for user: yourusername
✓ Storing in Bitwarden...
✓ Storing in Keychain...

Token name: npm-token
Type: Publish
Expires: 2027-01-24 (365 days)
```

**Metadata stored:**

```json
{
  "dot_version": "2.0",
  "type": "npm",
  "token_type": "publish",
  "created": "2026-01-24T14:30:00Z",
  "expires_days": 365
}
```

### 2.3 PyPI API Token

**When to use:**
- Publishing Python packages
- CI/CD pipelines

**Creation wizard:**

```bash
dot token pypi
```

**Interactive steps:**

```
╭───────────────────────────────────────────────────╮
│  PyPI API Token Setup                             │
├───────────────────────────────────────────────────┤
│                                                   │
│  Scope options:                                   │
│  1. Account-wide (all projects)                   │
│  2. Project-specific (recommended)                │
│                                                   │
│  Choose: 1 or 2? [2]                              │
╰───────────────────────────────────────────────────╯

[User selects 2]

Enter project name: my-awesome-package

✓ Opening PyPI token creation page...
  URL: https://pypi.org/manage/account/token/

After creating token, paste here:
Token: pypi-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

✓ Validating token...
✓ Token valid
✓ Storing in Bitwarden...
✓ Storing in Keychain...

Token name: pypi-my-awesome-package
Type: Project-specific
Expires: Never (manual rotation recommended)
```

**Important:** PyPI tokens don't expire automatically. Set calendar reminder for 90-day rotation.

---

## 3. Retrieving and Using Tokens {#3-retrieving-and-using-tokens}

### 3.1 Basic Retrieval

**Command:**

```bash
dot secret <token-name>
```

**Example:**

```bash
# Retrieve GitHub token (no output to terminal)
GITHUB_TOKEN=$(dot secret github-token)

# Verify retrieval (check length, not value)
echo "Token length: ${#GITHUB_TOKEN}"
# Output: Token length: 40
```

**What happens:**

1. Keychain lookup (< 50ms)
2. Touch ID prompt (first access only)
3. Token retrieved from `-w` field
4. **No echo to terminal** (security)

### 3.2 Script Integration

#### GitHub CLI Authentication

```bash
# Method 1: Environment variable
export GITHUB_TOKEN=$(dot secret github-token)
gh auth login --with-token <<< "$GITHUB_TOKEN"

# Method 2: Direct pipe
gh auth login --with-token <<< $(dot secret github-token)

# Method 3: Persistent login
echo $(dot secret github-token) | gh auth login --with-token
gh auth status
```

#### npm Publishing

```bash
# Set npm token for current session
npm config set //registry.npmjs.org/:_authToken \
  "$(dot secret npm-token)"

# Publish package
npm publish

# Or use .npmrc (not recommended - plaintext)
echo "//registry.npmjs.org/:_authToken=$(dot secret npm-token)" >> .npmrc
```

#### PyPI Publishing

```bash
# Set PyPI token in environment
export TWINE_USERNAME=__token__
export TWINE_PASSWORD=$(dot secret pypi-my-package)

# Publish package
python -m twine upload dist/*

# Or use pyproject.toml (poetry)
poetry config pypi-token.pypi $(dot secret pypi-my-package)
poetry publish
```

### 3.3 CI/CD Integration

**GitHub Actions:**

```yaml
name: Publish Package

on:
  release:
    types: [created]

jobs:
  publish:
    runs-on: macos-latest  # Required for Keychain access
    steps:
      - uses: actions/checkout@v3

      # Unlock Keychain (requires runner setup)
      - name: Unlock Keychain
        run: |
          security unlock-keychain -p "${{ secrets.KEYCHAIN_PASSWORD }}" \
            ~/Library/Keychains/login.keychain-db

      # Retrieve token
      - name: Get npm token
        run: |
          export NPM_TOKEN=$(dot secret npm-token)
          echo "::add-mask::$NPM_TOKEN"
          echo "NPM_TOKEN=$NPM_TOKEN" >> $GITHUB_ENV

      # Publish
      - name: Publish to npm
        run: |
          npm config set //registry.npmjs.org/:_authToken "$NPM_TOKEN"
          npm publish
```

**Note:** For CI/CD, consider using GitHub Secrets instead of Keychain for better portability.

---

## 4. Updating Tokens

### 4.1 Update Token Value (Re-add)

**Scenario:** You created a new token on GitHub and want to replace the old one.

**Process:**

```bash
# Method 1: Re-add with same name (overwrites)
dot token github
# Use same token name when prompted
# New token replaces old token in both backends

# Method 2: Manual update (advanced)
# 1. Delete old token
dot secret delete github-token

# 2. Add new token
dot token github
# Create with same name
```

**What happens:**

- Bitwarden item **updated** (not duplicated)
- Keychain entry **replaced** (`-U` flag in security command)
- Metadata updated with new creation date
- Old token value lost (no backup unless you use rotation)

### 4.2 Update Metadata Only

**Current limitation:** No built-in command for metadata-only updates.

**Workaround (manual):**

```bash
# Get current token value
TOKEN_VALUE=$(dot secret github-token)

# Delete entry
dot secret delete github-token

# Re-add with updated metadata
# (Use dot token github and paste same token value)

# OR: Direct Keychain update (advanced)
security delete-generic-password -a github-token -s flow-cli
security add-generic-password \
  -a github-token \
  -s flow-cli \
  -w "$TOKEN_VALUE" \
  -j '{"dot_version":"2.1","type":"github","token_type":"classic","created":"2026-01-24T15:00:00Z","expires_days":90,"expires":"2026-04-24","github_user":"newusername"}'
```

**Future enhancement:** `dot secret update-metadata <name>` command planned.

---

## 5. Rotating Tokens

### 5.1 Automatic Rotation Wizard

**When to rotate:**
- ⚠️ Token expires in < 7 days
- 🔒 Suspected compromise
- 📅 Regular rotation schedule (every 90 days)
- 🔄 Best practice refresh

**Command:**

```bash
dot token rotate
```

**Interactive steps:**

```
╭───────────────────────────────────────────────────╮
│  Token Rotation Wizard                            │
├───────────────────────────────────────────────────┤
│                                                   │
│  Tokens available for rotation:                   │
│                                                   │
│  1. github-token (expires in 5 days)  ⚠️          │
│  2. npm-token (expires in 67 days)   ✅          │
│  3. pypi-token (no expiration)       ⏳          │
│                                                   │
│  Select token to rotate: [1]                      │
╰───────────────────────────────────────────────────╯

[User selects 1]

✓ Creating backup of current token...
  Backup name: github-token-backup-20260124

✓ Opening GitHub token creation page...

After creating new token, paste here:
Token: ghp_NEWTOKEN...

✓ Validating new token...
✓ Updating Bitwarden...
✓ Updating Keychain...

╭───────────────────────────────────────────────────╮
│  ✓ Token rotated successfully                     │
│                                                   │
│  Name: github-token                               │
│  New expiration: 2026-04-24                       │
│                                                   │
│  Backup: github-token-backup-20260124             │
│  (Will be auto-deleted after 7 days)              │
│                                                   │
│  IMPORTANT: Revoke old token on GitHub!           │
│  https://github.com/settings/tokens               │
╰───────────────────────────────────────────────────╯
```

**What happens:**

1. **Backup creation:**
   - Old token copied to `<name>-backup-<YYYYMMDD>`
   - Stored in both Bitwarden and Keychain
   - 7-day retention policy

2. **New token creation:**
   - Browser opens to token creation page
   - User creates new token with same scopes
   - Paste new token into wizard

3. **Validation:**
   - New token tested against provider API
   - Metadata extracted (username, scopes)

4. **Update:**
   - Bitwarden item updated (password field)
   - Keychain entry updated (password + metadata)
   - Backup remains for rollback

5. **Manual cleanup:**
   - User must **manually revoke** old token on provider
   - Wizard provides direct link

### 5.2 Manual Rotation

**When to use:**
- Custom rotation process
- Scripted automation
- Testing rotation flow

**Steps:**

```bash
# 1. Create backup manually
dot secret add github-token-backup-20260124
# Paste current token when prompted

# 2. Create new token on provider
# (Manual process on GitHub/npm/PyPI)

# 3. Update token
dot token github
# Use same name "github-token"
# Paste new token

# 4. Verify new token
export GITHUB_TOKEN=$(dot secret github-token)
gh auth status

# 5. Delete backup (after verification)
dot secret delete github-token-backup-20260124

# 6. Revoke old token on provider
# https://github.com/settings/tokens
```

### 5.3 Backup Strategy

**Automatic backups:**
- Created during rotation
- Named: `<original>-backup-<YYYYMMDD>`
- 7-day retention (manual deletion after)

**Manual backups:**

```bash
# Before risky operation
dot secret add github-token-backup-$(date +%Y%m%d)
# Paste current token

# After verification, delete backup
dot secret delete github-token-backup-20260124
```

**Backup cleanup:**

```bash
# List all backups
dot secret list | grep backup

# Output:
#   github-token-backup-20260117
#   github-token-backup-20260124
#   npm-token-backup-20260120

# Delete old backups (> 7 days)
dot secret delete github-token-backup-20260117
```

---

## 6. Deleting Tokens

### 6.1 Single Token Deletion

**Command:**

```bash
dot secret delete <token-name>
```

**Example:**

```bash
dot secret delete github-token
```

**Interactive confirmation:**

```
╭───────────────────────────────────────────────────╮
│  ⚠️  Confirm Deletion                              │
├───────────────────────────────────────────────────┤
│                                                   │
│  Token: github-token                              │
│  Type: GitHub Classic PAT                         │
│  Created: 2026-01-24                              │
│  Expires: 2026-04-24                              │
│                                                   │
│  This will delete from:                           │
│    • Bitwarden (cloud vault)                      │
│    • Keychain (local cache)                       │
│                                                   │
│  ⚠️  This action cannot be undone!                │
│                                                   │
│  Confirm deletion? [y/N]                          │
╰───────────────────────────────────────────────────╯

[User types 'y']

✓ Deleting from Keychain...
✓ Deleting from Bitwarden...
✓ Syncing Bitwarden vault...

Token deleted successfully.

Remember to revoke on provider:
  https://github.com/settings/tokens
```

**What happens:**

1. **Keychain deletion:**
   ```bash
   security delete-generic-password \
     -a github-token \
     -s flow-cli
   ```

2. **Bitwarden deletion:**
   ```bash
   bw delete item <item-id> --session $BW_SESSION
   bw sync --session $BW_SESSION
   ```

3. **No backup created** (permanent deletion)

### 6.2 Bulk Deletion

**Scenario:** Clean up multiple old backups.

**Current limitation:** No built-in bulk delete.

**Workaround (script):**

```bash
# List backups older than 7 days
dot secret list | grep backup | while read backup; do
  echo "Deleting: $backup"
  dot secret delete "$backup"
done

# Or: Delete specific pattern
for token in github-token-backup-202601{10..23}; do
  dot secret delete "$token" 2>/dev/null || true
done
```

**Future enhancement:** `dot secret prune` command planned.

### 6.3 Provider Token Revocation

**Important:** Deleting from flow-cli does NOT revoke token on provider!

**Manual revocation required:**

#### GitHub

```bash
# Open token management page
open https://github.com/settings/tokens

# Or use GitHub CLI
gh auth refresh -s delete_repo
gh api -X DELETE /applications/{client_id}/token
```

#### npm

```bash
# Open token management page
open https://www.npmjs.com/settings/~/tokens

# Or use npm CLI (requires login)
npm token list
npm token revoke <token-id>
```

#### PyPI

```bash
# Open token management page
open https://pypi.org/manage/account/token/

# No CLI method - manual deletion only
```

---

## 7. Expiration Management

### 7.1 Check Expiration Status

**Command:**

```bash
dot token expiring
```

**Output (multiple tokens):**

```
╭───────────────────────────────────────────────────╮
│  Token Expiration Status                          │
├───────────────────────────────────────────────────┤
│                                                   │
│  ⚠️  github-token                                  │
│      Expires: 2026-01-29 (5 days)                 │
│      Type: GitHub Classic PAT                     │
│      Action: Run 'dot token rotate'               │
│                                                   │
│  ✅  npm-token                                     │
│      Expires: 2026-04-24 (67 days)                │
│      Type: npm Publish                            │
│                                                   │
│  ⏳  pypi-token                                    │
│      Expires: Never                               │
│      Type: PyPI Project-specific                  │
│      Note: Manual rotation recommended            │
│                                                   │
╰───────────────────────────────────────────────────╯

Summary:
  1 token expiring soon (⚠️)
  1 token healthy (✅)
  1 token no expiration (⏳)
```

**Exit codes:**
- `0`: All tokens healthy (> 7 days)
- `1`: At least one token expiring soon (< 7 days)
- `2`: Error (Keychain access denied, etc.)

**Quiet mode (for scripts):**

```bash
# Check without output
if dot token expiring --quiet; then
  echo "All tokens valid"
else
  echo "Tokens expiring soon!" >&2
  exit 1
fi
```

### 7.2 Update Expiration Date

**Scenario:** You manually extended token on provider, need to update metadata.

**Current limitation:** No built-in update command.

**Workaround (manual):**

```bash
# Get current token value
TOKEN_VALUE=$(dot secret github-token)

# Get current metadata
METADATA=$(security find-generic-password \
  -a github-token \
  -s flow-cli \
  -g 2>&1 | grep "note:" | sed 's/note: //')

# Update expires field
NEW_METADATA=$(echo "$METADATA" | \
  jq '.expires = "2026-07-24" | .expires_days = 180')

# Update Keychain
security delete-generic-password -a github-token -s flow-cli
security add-generic-password \
  -a github-token \
  -s flow-cli \
  -w "$TOKEN_VALUE" \
  -j "$NEW_METADATA"

# Verify
dot token expiring
```

**Future enhancement:** `dot token update-expiration <name> <days>` command planned.

### 7.3 Disable Expiration Warnings

**Scenario:** Using long-lived token, don't want warnings.

**Configuration (planned):**

```bash
# Disable for specific token
dot secret config github-token --no-expiration-check

# Disable globally
export FLOW_TOKEN_CHECK_DISABLED=1
```

**Current workaround:** Ignore warnings in scripts.

---

## 8. Troubleshooting

### 8.1 Touch ID Not Prompting

**Symptoms:**
- No Touch ID prompt when retrieving token
- "User interaction is not allowed" error
- Hangs on `dot secret` command

**Causes:**
- Terminal app lacks Accessibility permissions
- Keychain locked
- SSH session (no GUI)

**Solutions:**

#### Enable Accessibility Permissions

```bash
# Open System Settings
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

# Enable Terminal.app or iTerm.app
# System Settings → Privacy & Security → Accessibility
# Click [+] → Add Terminal/iTerm → Toggle ON
```

#### Unlock Keychain Manually

```bash
# Check Keychain status
security show-keychain-info login.keychain-db

# Unlock if locked
security unlock-keychain login.keychain-db
# (Prompts for password)

# Verify unlock
security show-keychain-info login.keychain-db
# Should show: "no-timeout"
```

#### SSH Session Workaround

```bash
# SSH sessions can't use Touch ID
# Use password unlock instead:
security unlock-keychain -p "your-password" login.keychain-db

# Or: Use Bitwarden backend directly
dot secret bw github-token
```

### 8.2 Token Validation Failed

**Symptoms:**
- "Token validation failed" error
- "Invalid token format" message
- "API request failed" error

**Causes:**
- Incorrect token format (copy/paste error)
- Token already revoked on provider
- Network connectivity issues
- Token lacks required scopes

**Solutions:**

#### Verify Token Format

```bash
# GitHub Classic PAT
echo "$TOKEN" | grep -E '^ghp_[A-Za-z0-9]{36}$'

# GitHub Fine-grained PAT
echo "$TOKEN" | grep -E '^github_pat_[A-Za-z0-9_]{82}$'

# npm token
echo "$TOKEN" | grep -E '^npm_[A-Za-z0-9]{36}$'

# PyPI token
echo "$TOKEN" | grep -E '^pypi-[A-Za-z0-9_-]+$'
```

#### Manual Token Test

**GitHub:**

```bash
# Test token manually
curl -H "Authorization: token ghp_YOUR_TOKEN" \
  https://api.github.com/user

# Expected: {"login":"username",...}
# If error: {"message":"Bad credentials"}
```

**npm:**

```bash
# Test token
curl -H "Authorization: Bearer npm_YOUR_TOKEN" \
  https://registry.npmjs.org/-/whoami

# Expected: {"username":"yourname"}
```

**PyPI:**

```bash
# PyPI tokens can't be tested via API
# Only way: try publishing
```

#### Check Token Scopes

**GitHub:**

```bash
# Check scopes
curl -I -H "Authorization: token ghp_YOUR_TOKEN" \
  https://api.github.com/user | grep x-oauth-scopes

# Output: x-oauth-scopes: repo, workflow, read:org
```

**npm:**

```bash
# npm tokens don't expose scopes via API
# Check on website: https://www.npmjs.com/settings/~/tokens
```

### 8.3 Keychain Access Denied

**Symptoms:**
- "The specified item could not be found in the keychain"
- "User interaction is not allowed"
- "SecKeychainItemCopyContent" error

**Solutions:**

#### Reset Keychain Permissions

```bash
# List Keychain items for flow-cli
security find-generic-password \
  -s flow-cli \
  -g

# If error, reset Keychain access:
security delete-generic-password -s flow-cli -a github-token
dot token github  # Re-add
```

#### Verify Service Name

```bash
# Check service name
echo $_DOT_KEYCHAIN_SERVICE
# Should output: flow-cli

# If empty, reload plugin
source flow.plugin.zsh
```

### 8.4 Bitwarden Sync Issues

**Symptoms:**
- "bw command not found"
- "You are not logged in"
- "Session key is invalid"

**Solutions:**

#### Install Bitwarden CLI

```bash
# macOS (Homebrew)
brew install bitwarden-cli

# Verify installation
bw --version
```

#### Login to Bitwarden

```bash
# Check status
bw status

# If not logged in:
bw login

# If session expired:
export BW_SESSION=$(bw unlock --raw)
```

#### Manual Sync

```bash
# Sync vault
bw sync --session $BW_SESSION

# Verify sync
bw list items --session $BW_SESSION | jq '.[] | select(.name=="github-token")'
```

---

## 9. Security Best Practices

### 9.1 Token Hygiene

#### Rotation Schedule

| Token Type | Recommended Rotation | Enforcement |
|------------|---------------------|-------------|
| **GitHub Classic PAT** | 90 days | GitHub enforced |
| **GitHub Fine-grained PAT** | 90 days | GitHub enforced |
| **npm token** | 90-180 days | Manual |
| **PyPI token** | 90 days | Manual |

**Best practice:** Rotate all tokens every 90 days, even if no expiration.

#### Minimum Permissions

**GitHub Classic PAT:**
```
✅ ONLY select required scopes:
  repo          (if you push code)
  workflow      (if you update workflows)
  read:org      (if you need org info)

❌ AVOID broad scopes:
  admin:org     (unless truly needed)
  delete_repo   (rarely needed)
```

**GitHub Fine-grained PAT:**
```
✅ Scope to specific repos:
  Select only repos you need access to

✅ Minimal permissions:
  Contents: Read (or Read/Write if pushing)
  Metadata: Read-only (auto-selected)
  Pull Requests: Read/Write (if needed)

❌ AVOID:
  All repositories (use specific repos)
  Admin permissions (unless required)
```

**npm token:**
```
✅ Use publish token only for publishing
✅ Use read-only token for CI/CD installs
❌ AVOID automation token for publishing
```

#### Token Naming

**Best practices:**
```
✅ GOOD:
  github-token-ci          (purpose clear)
  npm-publish-mypackage    (scoped)
  pypi-project-specific    (descriptive)

❌ BAD:
  token                    (vague)
  github-1                 (meaningless)
  temp                     (forgot to delete?)
```

### 9.2 Keychain Security

#### Enable Touch ID

**Check Touch ID status:**

```bash
# Verify Touch ID available
bioutil -r | grep functionality
# Output: Touch ID functionality: Available

# Test Touch ID
security find-generic-password \
  -s flow-cli \
  -a github-token \
  -g
# Should prompt for Touch ID
```

**Fallback to password:**

```bash
# If Touch ID fails, use password
security unlock-keychain login.keychain-db
# Enter password when prompted
```

#### Lock Screen When Away

**macOS settings:**
```
System Settings → Lock Screen
  • Require password: Immediately
  • Turn display off: 5 minutes
  • Show password hints: OFF
```

**Keyboard shortcut:** `⌃⌘Q` (Control-Command-Q) to lock immediately

#### Regular Keychain Backups

**Backup Keychain:**

```bash
# Create backup
cp ~/Library/Keychains/login.keychain-db \
   ~/Backups/login.keychain-backup-$(date +%Y%m%d).db

# Encrypt backup
zip -e ~/Backups/keychain-backup-$(date +%Y%m%d).zip \
  ~/Backups/login.keychain-backup-*.db

# Upload to secure storage (iCloud, 1Password, etc.)
```

**Restore Keychain:**

```bash
# Unzip backup
unzip ~/Backups/keychain-backup-20260124.zip

# Copy to Keychains directory
cp login.keychain-backup-*.db \
   ~/Library/Keychains/login.keychain-db

# Unlock
security unlock-keychain login.keychain-db
```

### 9.3 Bitwarden Security

#### Strong Master Password

**Requirements:**
- 🔒 At least 14 characters
- 🔤 Mix of uppercase, lowercase, numbers, symbols
- 🚫 Not used elsewhere
- 💭 Memorable passphrase (e.g., "correct-horse-battery-staple")

**Test password strength:**
```bash
# Use Bitwarden password generator
bw generate --length 20 --uppercase --lowercase --number --special
```

#### Enable 2FA

**Bitwarden 2FA setup:**
1. Log in to Bitwarden web vault
2. Settings → Security → Two-step Login
3. Choose method:
   - ✅ **Authenticator app** (recommended: Authy, 1Password)
   - ✅ **FIDO2 WebAuthn** (hardware key)
   - ⚠️ Email (less secure, backup only)

**Recovery codes:**
- Save recovery codes in **separate** secure location
- Print and store physically
- Never store in Bitwarden itself

#### Regular Vault Audits

**Monthly audit checklist:**

```bash
# 1. List all tokens
dot secret list

# 2. Check expiration status
dot token expiring

# 3. Remove unused tokens
# (Delete tokens not used in 90+ days)

# 4. Verify token scopes
# (Check on GitHub/npm/PyPI)

# 5. Rotate expiring tokens
dot token rotate
```

**Automated audit (script):**

```bash
#!/bin/bash
# token-audit.sh - Monthly token security audit

echo "=== Token Security Audit ==="
echo "Date: $(date)"
echo ""

echo "1. Token Inventory:"
dot secret list

echo ""
echo "2. Expiration Status:"
dot token expiring

echo ""
echo "3. Action Items:"
dot token expiring | grep "⚠️" | while read line; do
  echo "   - Rotate: $(echo $line | awk '{print $2}')"
done

# Log audit
echo "Audit completed: $(date)" >> ~/.flow/token-audit.log
```

---

## 10. Migration Guide

### 10.1 From Bitwarden-Only to Dual Storage

**Scenario:** You have tokens in Bitwarden, want to add Keychain for instant access.

**Migration process:**

```bash
# 1. List Bitwarden tokens
bw list items --session $BW_SESSION | \
  jq -r '.[] | select(.type==1) | .name'

# Output:
#   github-token
#   npm-token
#   pypi-token

# 2. For each token, migrate to dual storage
dot secret import

# Interactive:
╭───────────────────────────────────────────────────╮
│  Import from Bitwarden to Keychain                │
├───────────────────────────────────────────────────┤
│                                                   │
│  Available Bitwarden items:                       │
│    1. github-token                                │
│    2. npm-token                                   │
│    3. pypi-token                                  │
│                                                   │
│  Select item to import: [1]                       │
╰───────────────────────────────────────────────────╯

[User selects 1]

✓ Reading from Bitwarden...
✓ Extracting token value...
✓ Parsing metadata (if present)...
✓ Storing in Keychain...

Imported: github-token
```

**Manual migration (batch):**

```bash
# Create migration script
cat > migrate-tokens.sh << 'EOF'
#!/bin/bash

# Get Bitwarden session
export BW_SESSION=$(bw unlock --raw)

# Get all login items
bw list items --session $BW_SESSION | \
  jq -r '.[] | select(.type==1) | .name' | \
  while read name; do
    echo "Migrating: $name"

    # Get password (token value)
    password=$(bw get password "$name" --session $BW_SESSION)

    # Get notes (metadata)
    notes=$(bw get notes "$name" --session $BW_SESSION)

    # Add to Keychain
    security add-generic-password \
      -a "$name" \
      -s flow-cli \
      -w "$password" \
      -j "$notes" \
      -U

    echo "✓ Migrated: $name"
  done

echo "Migration complete!"
EOF

chmod +x migrate-tokens.sh
./migrate-tokens.sh
```

### 10.2 From Environment Variables to Keychain

**Scenario:** You have tokens in `.zshrc` or `.bashrc`, want to migrate to Keychain.

**Current state (insecure):**

```bash
# ~/.zshrc
export GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
export NPM_TOKEN="npm_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

**Migration steps:**

```bash
# 1. Extract tokens from shell config
grep "export.*TOKEN" ~/.zshrc

# 2. For each token, add to flow-cli
# GitHub token:
dot token github
# Paste: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# npm token:
dot token npm
# Paste: npm_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# 3. Update shell config
# Remove hardcoded tokens:
sed -i.backup '/export.*TOKEN/d' ~/.zshrc

# Add dynamic retrieval:
cat >> ~/.zshrc << 'EOF'

# Token retrieval via flow-cli (secure)
export GITHUB_TOKEN=$(dot secret github-token 2>/dev/null || echo "")
export NPM_TOKEN=$(dot secret npm-token 2>/dev/null || echo "")

# Only load if tokens exist
[[ -n "$GITHUB_TOKEN" ]] || echo "Warning: GITHUB_TOKEN not set" >&2
EOF

# 4. Reload shell
source ~/.zshrc

# 5. Verify
echo "GitHub token length: ${#GITHUB_TOKEN}"
echo "npm token length: ${#NPM_TOKEN}"
```

**Result:**
- ✅ Tokens no longer in plaintext config
- ✅ Touch ID required to access
- ✅ Automatic retrieval on shell load
- ✅ Backed up in Bitwarden cloud

### 10.3 Export for Backup

**Scenario:** Want to export all tokens for disaster recovery.

**Security warning:** ⚠️ Exported tokens are **plaintext** - handle with extreme care!

**Export process:**

```bash
# 1. Create encrypted backup directory
mkdir -p ~/Backups/flow-cli-tokens-$(date +%Y%m%d)
cd ~/Backups/flow-cli-tokens-$(date +%Y%m%d)

# 2. Export each token
dot secret list | while read token_name; do
  echo "Exporting: $token_name"

  # Get token value
  token_value=$(dot secret "$token_name")

  # Get metadata
  metadata=$(security find-generic-password \
    -a "$token_name" \
    -s flow-cli \
    -g 2>&1 | grep "note:" | sed 's/note: //')

  # Save to file
  cat > "${token_name}.json" << EOF
{
  "name": "$token_name",
  "value": "$token_value",
  "metadata": $metadata,
  "exported": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
done

# 3. Encrypt backup
cd ..
zip -e -r flow-cli-tokens-$(date +%Y%m%d).zip \
  flow-cli-tokens-$(date +%Y%m%d)/

# Prompt for encryption password
# Use strong password (not your Keychain password!)

# 4. Secure deletion of plaintext
rm -rf flow-cli-tokens-$(date +%Y%m%d)/

# 5. Upload encrypted zip to secure storage
# (iCloud, 1Password, Bitwarden Attachments, etc.)
```

**Restore from backup:**

```bash
# 1. Download and decrypt backup
unzip flow-cli-tokens-20260124.zip
cd flow-cli-tokens-20260124

# 2. Restore each token
for json_file in *.json; do
  token_name=$(jq -r '.name' "$json_file")
  token_value=$(jq -r '.value' "$json_file")
  metadata=$(jq -c '.metadata' "$json_file")

  echo "Restoring: $token_name"

  # Add to Keychain
  security add-generic-password \
    -a "$token_name" \
    -s flow-cli \
    -w "$token_value" \
    -j "$metadata" \
    -U

  # Add to Bitwarden
  # (Manual process via web UI or bw CLI)
done

# 3. Verify restoration
dot secret list

# 4. Secure deletion
cd ..
rm -rf flow-cli-tokens-20260124/
```

---

## Summary

**Key takeaways:**

1. **Dual storage = Best of both worlds**
   - Bitwarden: Cloud backup, sync, web access
   - Keychain: Instant local access, Touch ID

2. **Security is multi-layered**
   - Encrypted storage (Keychain + Bitwarden)
   - Touch ID authentication
   - Minimal token scopes
   - Regular rotation (90 days)

3. **Metadata enables speed**
   - JSON attributes (`-j` flag) allow fast expiration checks
   - No Touch ID prompt for metadata reads
   - Safe because metadata isn't sensitive

4. **Rotation is easy**
   - `dot token rotate` wizard
   - Automatic backups
   - Manual revocation required

5. **Integration is seamless**
   - `$(dot secret <name>)` in scripts
   - No echo to terminal
   - CI/CD compatible

---

**Next steps:**

- 📖 Try the interactive tutorial: `dot secret tutorial`
- 📋 Keep the quick reference handy: `REFCARD-TOKEN-SECRETS.md`
- 🔒 Set calendar reminder for 90-day token rotation
- 💾 Create monthly backup automation
- 🔍 Run security audit: `flow doctor --dot`

**Questions?** Run `dot secret help` or `dot token help`
