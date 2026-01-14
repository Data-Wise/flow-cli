# Secret Management

The `dot` dispatcher provides two backends for secure secret management:

| Backend | Speed | Auth | Best For |
|---------|-------|------|----------|
| **macOS Keychain** (v5.5.0) | < 50ms | Touch ID | Local dev, scripts |
| **Bitwarden** | 2-5s | Master password | Cross-device sync |

---

## macOS Keychain (v5.5.0) ⭐ NEW

Instant access to secrets with Touch ID authentication. No setup required.

### Quick Start

```bash
# Store a secret
dot secret add api-key
> Enter secret value: ••••••••

# Retrieve (Touch ID prompt)
TOKEN=$(dot secret api-key)

# List all secrets
dot secret list

# Delete
dot secret delete api-key
```

### Why Keychain?

- **Instant** (< 50ms vs 2-5s for Bitwarden)
- **Touch ID** - No typing master password
- **Auto-locks** with screen lock
- **No unlock step** - Just use it
- **Perfect for scripts** - Works in `.zshrc` startup

### Use Cases

```bash
# In .zshrc (instant, no unlock)
export GITHUB_TOKEN=$(dot secret github-token)
export NPM_TOKEN=$(dot secret npm-token)

# In scripts
#!/bin/bash
API_KEY=$(dot secret my-api-key)
curl -H "Authorization: Bearer $API_KEY" https://api.example.com
```

---

## Bitwarden (Cross-Device)

For secrets that need to sync across devices.

### Quick Start

```bash
# 1. Unlock Bitwarden vault
dot unlock

# 2. List available secrets
dot secret list

# 3. Retrieve a secret (returns value without echo)
TOKEN=$(dot secret github-token)
```

### Prerequisites

Install Bitwarden CLI:

```bash
brew install bitwarden-cli
```

Authenticate with Bitwarden (one-time):

```bash
bw login
```

## Commands

### `dot unlock`

Unlocks your Bitwarden vault and exports `BW_SESSION` to your current shell.

**Features:**
- Session token stored in memory only (not persistent)
- Validates session after unlock
- Security reminders displayed
- Session expires when shell closes

**Example:**

```bash
$ dot unlock
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

### `dot secret <name>`

Retrieves a secret from Bitwarden by name or ID.

**Security:**
- Returns value without echoing to terminal
- Suppresses stderr to prevent leaks
- Safe for capturing in variables

**Example:**

```bash
# Capture in variable (secure)
TOKEN=$(dot secret github-token)

# Use in command
curl -H "Authorization: Bearer $(dot secret api-key)" https://api.example.com
```

**Error Handling:**

```bash
$ dot secret nonexistent
✗ Failed to retrieve secret: nonexistent
ℹ Item not found or access denied
  Tip: Use 'dot secret list' to see available items
```

### `dot secret list`

Lists all items in your Bitwarden vault with formatted display.

**Features:**
- Shows item type icons (🔑 login, 📝 note, 💳 card)
- Displays folder organization
- Colored output using FLOW_COLORS
- Falls back gracefully if `jq` not installed

**Example:**

```bash
$ dot secret list
ℹ Retrieving items from vault...

🔑 github-token (Work/GitHub)
🔑 npm-token (Work/Node)
📝 ssh-passphrase (Personal)
💳 stripe-test-key (Work/Stripe)

ℹ Usage: dot secret <name>
```

## Using Secrets in Chezmoi Templates

Chezmoi supports Bitwarden integration natively. Your secrets can be used in templates.

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
# 1. Unlock Bitwarden
dot unlock

# 2. Edit and apply template
dot edit .gitconfig

# Result: ~/.gitconfig contains actual token value
```

### Example: `.zshrc` with API Keys

**Template:** `~/.local/share/chezmoi/dot_zshrc.tmpl`

```bash
# API Keys (from Bitwarden)
export OPENAI_API_KEY="{{ bitwarden "item" "openai-key" }}"
export ANTHROPIC_API_KEY="{{ bitwarden "item" "anthropic-key" }}"
export GITHUB_TOKEN="{{ bitwarden "item" "github-token" }}"
```

**Apply:**

```bash
dot unlock
dot edit .zshrc
# Source the new config
source ~/.zshrc
```

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

## Session Management

### Session Lifetime

- **Scope:** Current shell only
- **Duration:** Until shell closes or `bw lock` is run
- **Inheritance:** Not inherited by subshells
- **Persistence:** Not saved to disk

### Checking Session Status

```bash
# Manual check
bw unlock --check

# Via status command
bw status | jq -r .status
# Output: unlocked, locked, or unauthenticated
```

### Locking Vault

```bash
# Lock immediately
bw lock

# Clear session variable
unset BW_SESSION
```

## Troubleshooting

### "Bitwarden vault is locked"

**Cause:** No active `BW_SESSION` in current shell.

**Solution:**

```bash
dot unlock
```

### "Item not found or access denied"

**Cause:** Item name doesn't match or doesn't exist.

**Solution:**

```bash
# List all items
dot secret list

# Check exact name (case-sensitive)
bw get item github-token
```

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

# Add to .zshrc if needed
HISTIGNORE="*bw unlock*:*bw get*:*BW_SESSION*"
```

## Integration Examples

### Git Credential Helper

Use Bitwarden for git credentials:

```bash
# In ~/.gitconfig.tmpl
[credential]
    helper = "!f() { echo username=youruser; echo password={{ bitwarden \"item\" \"github-token\" }}; }; f"
```

### Environment Variables Script

**Template:** `~/.local/share/chezmoi/private_env.sh.tmpl`

```bash
#!/bin/bash
# Auto-generated from Bitwarden secrets
# Source: source ~/.env.sh

export OPENAI_API_KEY="{{ bitwarden "item" "openai-key" }}"
export ANTHROPIC_API_KEY="{{ bitwarden "item" "anthropic-key" }}"
export GITHUB_TOKEN="{{ bitwarden "item" "github-token" }}"
```

**Apply:**

```bash
dot unlock
chezmoi apply ~/.env.sh
source ~/.env.sh
```

## Advanced Usage

### Retrieve by Item ID

```bash
# Get item ID
bw list items | jq -r '.[] | select(.name=="github-token") | .id'

# Use ID directly
dot secret "a1b2c3d4-e5f6-1234-5678-90abcdef1234"
```

### Custom Fields

Bitwarden items can have custom fields. Access them via chezmoi:

```bash
# In template
{{ bitwardenFields "item" "api-key" "custom-field-name" }}
```

### Secure Notes

Store multi-line secrets in secure notes:

```bash
# In template
{{ bitwardenFields "item" "ssh-private-key" "notes" }}
```

## Version History

- **v1.2.0 (Phase 3):** Initial secret management implementation
  - `dot unlock` - Session management
  - `dot secret <name>` - Secure retrieval
  - `dot secret list` - Item listing
  - Security audit (no secrets in logs/history)

## See Also

- [Bitwarden CLI Documentation](https://bitwarden.com/help/cli/)
- [Chezmoi Bitwarden Integration](https://www.chezmoi.io/user-guide/password-managers/bitwarden/)
- [dot dispatcher reference](./reference/DOT-DISPATCHER-REFERENCE.md)
