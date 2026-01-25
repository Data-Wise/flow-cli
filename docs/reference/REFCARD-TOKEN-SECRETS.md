# Token & Secret Management - Quick Reference

**Version:** 5.18.0-dev
**Last Updated:** 2026-01-24

---

## Backend Configuration (NEW in v5.18.0)

| Backend | Description | Requires Unlock |
|---------|-------------|-----------------|
| `keychain` (default) | macOS Keychain only - instant access | No |
| `bitwarden` | Bitwarden only - cloud backup | Yes |
| `both` | Both backends - local + cloud | Yes (for writes) |

```bash
# Configure backend (add to .zshrc)
export FLOW_SECRET_BACKEND=keychain   # Default - instant access
export FLOW_SECRET_BACKEND=bitwarden  # Legacy mode
export FLOW_SECRET_BACKEND=both       # Cloud backup enabled

# Check current status
dot secret status
```

---

## Common Commands

| Command | Action | Example |
|---------|--------|---------|
| `dot token github` | Create GitHub token | Interactive wizard |
| `dot token npm` | Create npm token | Interactive wizard |
| `dot token pypi` | Create PyPI token | Interactive wizard |
| `dot secret <name>` | Get secret | `GITHUB_TOKEN=$(dot secret github-token)` |
| `dot secret list` | List all secrets | Shows names only |
| `dot secret add <name>` | Add arbitrary secret | Prompts for value |
| `dot secret delete <name>` | Remove secret | Permanent deletion |
| `dot secret status` | Show backend config | Backend & secrets count |
| `dot secret sync` | Sync Keychain ↔ Bitwarden | Interactive wizard |
| `dot secret sync --status` | Show sync differences | Compare backends |
| `dot token expiring` | Check expiration | Shows 7-day warnings |
| `dot token rotate` | Rotate token | With backup |
| `dot secret help` | Show help | Display all commands |

---

## Quick Workflows

### Add New GitHub Token

```bash
# Interactive wizard
dot token github

# Follow prompts:
# 1. Choose token type (classic or fine-grained)
# 2. Browser opens to GitHub token page
# 3. Create token with recommended scopes
# 4. Paste token when prompted
# 5. Token stored (based on FLOW_SECRET_BACKEND):
#    - keychain: Keychain only (default - no unlock needed!)
#    - bitwarden: Bitwarden only
#    - both: Keychain + Bitwarden

# ✅ Token ready to use instantly
```

### Use Token in Scripts

```bash
# Export as environment variable
export GITHUB_TOKEN=$(dot secret github-token)

# Use with GitHub CLI
gh auth login --with-token <<< $(dot secret github-token)

# Use in scripts (no echo to terminal)
curl -H "Authorization: token $(dot secret github-token)" \
  https://api.github.com/user/repos
```

### Check Token Expiration

```bash
# Check all tokens
dot token expiring

# Output shows tokens expiring in next 7 days:
# ⚠️  github-token expires in 5 days
# ✅  npm-token expires in 67 days
```

### Rotate Expiring Token

```bash
# Interactive rotation wizard
dot token rotate

# Follow prompts:
# 1. Select token to rotate
# 2. Creates backup (old-token-backup-YYYYMMDD)
# 3. Opens browser to create new token
# 4. Paste new token
# 5. Updates both Bitwarden & Keychain
# 6. Old token backed up for 7 days
```

### Delete Old Token

```bash
# List all secrets
dot secret list

# Sample output:
#   github-token
#   npm-token
#   old-github-token-backup-20260117

# Delete backup
dot secret delete old-github-token-backup-20260117
```

---

## Storage Architecture

### Dual Storage System

```
User runs: dot token github
    ↓
┌─────────────────────────────────────────────┐
│ 1. Store in Bitwarden (backup/sync)         │
│    - password field: token value            │
│    - notes field: metadata JSON             │
│                                             │
│ 2. Store in Keychain (instant access)       │
│    - password (-w): token value             │
│    - JSON attrs (-j): metadata JSON         │
└─────────────────────────────────────────────┘
    ↓
User runs: dot secret github-token
    ↓
Retrieves from Keychain (< 50ms, Touch ID supported)
```

### Why Both Backends?

| Backend | Purpose | Speed | Features |
|---------|---------|-------|----------|
| **Bitwarden** | Cloud backup, cross-device sync | ~2-5s (unlock required) | Web access, sharing, cloud sync |
| **Keychain** | Instant local access | < 50ms | Touch ID, offline, no unlock delay |

**Metadata duplication** enables fast expiration checks without Bitwarden unlock.

---

## Token Metadata Format

Each token stores metadata in JSON format (v2.1):

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

**Metadata fields:**
- `dot_version`: Format version (current: 2.1)
- `type`: Token provider (github, npm, pypi)
- `token_type`: Provider-specific type (classic, fine-grained)
- `created`: ISO 8601 creation timestamp
- `expires_days`: Expiration period in days (default: 90)
- `expires`: Calculated expiration date
- `github_user`: GitHub username (for PATs only)

---

## Security Model

### Keychain Storage Security

```
Security add-generic-password command:

  -w "$token_value"    ← PASSWORD: Encrypted, requires Touch ID
  -j "$metadata"       ← JSON ATTRS: Searchable, not password-protected
  -a "$token_name"     ← ACCOUNT: Searchable identifier
  -s "flow-cli"        ← SERVICE: Namespace for flow-cli secrets
```

**Key Points:**
- ✅ Token value encrypted in Keychain (requires Touch ID/password)
- ✅ Metadata searchable (enables fast expiration checks)
- ✅ Metadata NOT sensitive (only timestamps, types)
- ✅ Service name isolates flow-cli secrets from other apps

### Touch ID Integration

**First access:**
1. macOS prompts for Touch ID or password
2. User authenticates once
3. Token retrieved and cached in memory

**Subsequent access (same session):**
- No prompt required
- Instant retrieval (< 50ms)

**New session:**
- Touch ID prompt again
- Session timeout: 5 minutes (macOS default)

---

## Provider-Specific Notes

### GitHub Personal Access Tokens

**Classic PAT:**
- Scopes: repo, workflow, read:org
- Expiration: 90 days (recommended)
- Format: `ghp_XXXX...`

**Fine-grained PAT (Recommended):**
- Scoped to specific repositories
- Works with 2FA
- More granular permissions
- Format: `github_pat_XXXX...`

### npm Tokens

**Token types:**
- Automation (CI/CD)
- Publish (package publishing)
- Read-only (download only)

**Expiration:** 365 days (default)

### PyPI API Tokens

**Scope options:**
- Account-wide
- Project-specific (recommended)

**Expiration:** No expiration (manual rotation recommended)

---

## Troubleshooting

### Touch ID Not Prompting

```bash
# Check Keychain access permissions
# System Settings → Privacy & Security → Full Disk Access
# Ensure Terminal.app or iTerm.app is enabled

# Verify Keychain unlocked
security unlock-keychain login.keychain-db
```

### Token Validation Failed

```bash
# GitHub token validation
curl -H "Authorization: token YOUR_TOKEN" \
  https://api.github.com/user

# npm token validation
npm whoami --registry https://registry.npmjs.org/

# PyPI token validation
pip install keyring  # Test with pip
```

### Bitwarden Sync Issues

```bash
# Manual sync
bw sync --session $BW_SESSION

# Check login status
bw status

# Re-login if needed
bw login
```

---

## Best Practices

### Token Hygiene

- ✅ **Rotate every 90 days** (GitHub enforces this)
- ✅ **Use fine-grained PATs** (GitHub)
- ✅ **Scope to minimum permissions** (principle of least privilege)
- ✅ **Delete unused tokens** (reduce attack surface)
- ✅ **Use unique tokens per purpose** (easier to rotate)

### Backup Strategy

- ✅ **Bitwarden stores master copy** (cloud backup)
- ✅ **Keychain for instant access** (local cache)
- ✅ **Rotation creates backups** (7-day retention)
- ✅ **Export vault regularly** (disaster recovery)

### Automation Tips

```bash
# Check expiration in scripts (exit code 0 if OK)
if dot token expiring --quiet; then
    echo "All tokens valid"
else
    echo "Tokens expiring soon!"
fi

# Get token in scripts (no echo)
export GITHUB_TOKEN=$(dot secret github-token)

# Rotate token in CI/CD (with backup)
dot token rotate --non-interactive github-token
```

---

## Related Commands

| Command | Purpose |
|---------|---------|
| `flow doctor --dot` | Check token health (< 3s) |
| `flow doctor --dot=github` | Check specific provider |
| `flow doctor --fix-token` | Fix token issues |
| `dot secrets` | Dashboard of all secrets |
| `g push` | Validates GitHub token before push |
| `dash dev` | Shows token status |

---

## See Also

- **Comprehensive Guide:** `docs/guides/TOKEN-MANAGEMENT-COMPLETE.md`
- **Interactive Tutorial:** `dot secret tutorial`
- **API Reference:** `docs/reference/MASTER-API-REFERENCE.md` (Keychain section)
- **Architecture:** `docs/reference/MASTER-ARCHITECTURE.md` (Token management)

---

**Questions?** Run `dot secret help` or `dot token help`
