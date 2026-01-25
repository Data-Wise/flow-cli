# SPEC: macOS Keychain Secret Management

**Date:** 2026-01-13
**Status:** Draft
**Branch:** feature/keychain-secrets
**Effort:** 🔧 Medium (2-3 hours)
**Risk:** Low

---

## Overview

Add native macOS Keychain support for local secret storage as an alternative to Bitwarden. This provides instant, session-free secret access with Touch ID support.

### Problem Statement

Current `dot unlock` workflow has reliability issues:
1. `bw unlock --raw` has stderr/stdout mixing problems
2. Session tokens require manual export
3. 15-minute cache adds complexity
4. Network dependency for local secrets

### Solution

Use macOS Keychain via the `security` command for local secrets:
- Instant access (no unlock step)
- Touch ID / Apple Watch support
- Automatic lock with screen lock
- Offline operation
- Zero session management

---

## Architecture

### New Commands

```bash
dot secret add <name>         # Store secret in Keychain (prompt for value)
dot secret get <name>         # Retrieve from Keychain (silent output)
dot secret list               # List all flow-cli managed secrets
dot secret delete <name>      # Remove from Keychain
dot secret import             # One-time import from Bitwarden
```

### Constants

```zsh
_DOT_KEYCHAIN_SERVICE="flow-cli-secrets"   # Service name in Keychain
```

### Implementation

#### `_dot_secret_add()`

```zsh
_dot_secret_add() {
    local name="$1"
    if [[ -z "$name" ]]; then
        _flow_log_error "Usage: dot secret add <name>"
        return 1
    fi

    # Prompt for secret (hidden input)
    echo -n "Enter secret value: "
    read -rs secret_value
    echo

    if [[ -z "$secret_value" ]]; then
        _flow_log_error "Secret value cannot be empty"
        return 1
    fi

    # Store in Keychain (-U updates if exists)
    if security add-generic-password \
        -a "$name" \
        -s "$_DOT_KEYCHAIN_SERVICE" \
        -w "$secret_value" \
        -U 2>/dev/null; then
        _flow_log_success "Secret '$name' stored in Keychain"
    else
        _flow_log_error "Failed to store secret"
        return 1
    fi
}
```

#### `_dot_secret_get()`

```zsh
_dot_secret_get() {
    local name="$1"
    if [[ -z "$name" ]]; then
        _flow_log_error "Usage: dot secret get <name>"
        return 1
    fi

    local value
    value=$(security find-generic-password \
        -a "$name" \
        -s "$_DOT_KEYCHAIN_SERVICE" \
        -w 2>/dev/null)

    if [[ -n "$value" ]]; then
        echo "$value"
    else
        _flow_log_error "Secret '$name' not found"
        return 1
    fi
}
```

#### `_dot_secret_list()`

```zsh
_dot_secret_list() {
    _flow_log_info "Secrets in Keychain (flow-cli):"

    # Parse keychain dump for our service
    security dump-keychain 2>/dev/null | \
        awk -v svc="$_DOT_KEYCHAIN_SERVICE" '
            /"svce"<blob>=/ { found = ($0 ~ svc) }
            found && /"acct"<blob>=/ {
                gsub(/.*"acct"<blob>="/, "")
                gsub(/".*/, "")
                print "  • " $0
                found = 0
            }
        '
}
```

#### `_dot_secret_delete()`

```zsh
_dot_secret_delete() {
    local name="$1"
    if [[ -z "$name" ]]; then
        _flow_log_error "Usage: dot secret delete <name>"
        return 1
    fi

    if security delete-generic-password \
        -a "$name" \
        -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null; then
        _flow_log_success "Secret '$name' deleted"
    else
        _flow_log_error "Secret '$name' not found"
        return 1
    fi
}
```

#### `_dot_secret_import()` (Optional)

```zsh
_dot_secret_import() {
    if ! _dot_bw_session_valid; then
        _flow_log_error "Bitwarden locked. Run: bw unlock"
        return 1
    fi

    _flow_log_info "Import secrets from Bitwarden folder 'flow-cli-secrets'?"
    echo -n "Continue? [y/N] "
    read -r confirm
    [[ "$confirm" != [yY]* ]] && return 0

    # Get folder ID
    local folder_id
    folder_id=$(bw list folders --session "$BW_SESSION" 2>/dev/null | \
        jq -r '.[] | select(.name=="flow-cli-secrets") | .id')

    if [[ -z "$folder_id" ]]; then
        _flow_log_error "Folder 'flow-cli-secrets' not found in Bitwarden"
        return 1
    fi

    # Import each item
    local count=0
    bw list items --folderid "$folder_id" --session "$BW_SESSION" 2>/dev/null | \
        jq -r '.[] | "\(.name)\t\(.login.password)"' | \
    while IFS=$'\t' read -r name password; do
        security add-generic-password \
            -a "$name" \
            -s "$_DOT_KEYCHAIN_SERVICE" \
            -w "$password" \
            -U 2>/dev/null
        _flow_log_success "Imported: $name"
        ((count++))
    done

    _flow_log_success "Imported $count secrets to Keychain"
}
```

---

## Dispatcher Integration

Update `dot` dispatcher to route `secret` subcommand:

```zsh
# In dot()
secret)
    shift
    case "$1" in
        add)    shift; _dot_secret_add "$@" ;;
        get)    shift; _dot_secret_get "$@" ;;
        list)   _dot_secret_list ;;
        delete) shift; _dot_secret_delete "$@" ;;
        import) _dot_secret_import ;;
        help|--help|-h) _dot_secret_help ;;
        *)
            # Default: get (for quick access)
            if [[ -n "$1" ]]; then
                _dot_secret_get "$1"
            else
                _dot_secret_help
            fi
            ;;
    esac
    ;;
```

---

## Help Text

```zsh
_dot_secret_help() {
    cat <<EOF
${CYAN}dot secret${NC} - macOS Keychain secret management

${YELLOW}Commands:${NC}
  dot secret add <name>      Store a secret (prompts for value)
  dot secret get <name>      Retrieve a secret (or just: dot secret <name>)
  dot secret <name>          Shortcut for 'get'
  dot secret list            List all stored secrets
  dot secret delete <name>   Remove a secret
  dot secret import          Import from Bitwarden (one-time)

${YELLOW}Examples:${NC}
  dot secret add github-token    # Store GitHub token
  dot secret github-token        # Retrieve it
  dot secret list                # See all secrets

${YELLOW}Benefits:${NC}
  • Instant access (no unlock needed)
  • Touch ID / Apple Watch support
  • Auto-locks with screen lock
  • Works offline

${DIM}Secrets stored in: macOS Keychain (service: flow-cli-secrets)${NC}
EOF
}
```

---

## Usage Examples

### Store and Retrieve

```bash
# Store a secret
$ dot secret add github-token
Enter secret value: ********
✓ Secret 'github-token' stored in Keychain

# Retrieve it
$ dot secret github-token
ghp_xxxxxxxxxxxxxxxxxxxx

# Use in scripts
$ gh auth login --with-token <<< $(dot secret github-token)
```

### List and Delete

```bash
$ dot secret list
ℹ Secrets in Keychain (flow-cli):
  • github-token
  • npm-token
  • pypi-token

$ dot secret delete npm-token
✓ Secret 'npm-token' deleted
```

### One-Time Import from Bitwarden

```bash
$ dot secret import
ℹ Import secrets from Bitwarden folder 'flow-cli-secrets'?
Continue? [y/N] y
✓ Imported: github-token
✓ Imported: npm-token
✓ Imported 2 secrets to Keychain
```

---

## File Changes

| File | Changes |
|------|---------|
| `lib/dispatchers/dot-dispatcher.zsh` | Add `secret` subcommand routing |
| `lib/keychain-helpers.zsh` (NEW) | Keychain functions |
| `flow.plugin.zsh` | Source keychain-helpers.zsh |
| `completions/_dot` | Add `secret` completions |

---

## Testing Plan

### Unit Tests

```bash
# Test file: tests/test-dot-secret.zsh

# 1. Add/Get cycle
dot secret add test-secret  # (mock input)
[[ $(dot secret get test-secret) == "test-value" ]]

# 2. List shows secret
dot secret list | grep -q "test-secret"

# 3. Delete removes it
dot secret delete test-secret
! dot secret get test-secret 2>/dev/null

# 4. Error handling
! dot secret add ""          # Empty name
! dot secret get nonexistent # Missing secret
```

### Manual Testing

1. `dot secret add mytoken` - Verify prompt, storage
2. `dot secret mytoken` - Verify retrieval
3. Lock screen, unlock with Touch ID - Verify Keychain access
4. `dot secret list` - Verify listing
5. `dot secret delete mytoken` - Verify removal

---

## Migration Path

### Phase 1: Add Keychain Support (This PR)

- New `dot secret` commands
- Coexists with existing Bitwarden integration

### Phase 2: Hybrid Mode (Future)

- `dot secret get` tries Keychain first, falls back to Bitwarden
- Gradual migration of secrets

### Phase 3: Deprecate BW Session Cache (Future)

- Remove `_dot_session_cache_*` functions
- Keep `dot unlock` for Bitwarden-only operations
- Keychain becomes primary for local secrets

---

## Limitations

- **macOS only** - Uses native Keychain, no Linux/Windows support
- **No sync** - Secrets don't sync across devices (use Bitwarden for that)
- **Separate storage** - Independent from Bitwarden vault

---

## Decision Points

1. **Default behavior for `dot secret <name>`** - Should it be `get` (implemented above) or show help?
2. **Import scope** - Import all Bitwarden items or just a specific folder?
3. **Keychain access** - Should we use login keychain (default) or create a custom keychain?

---

## Approval Checklist

- [ ] Spec reviewed
- [ ] Implementation approach approved
- [ ] File structure approved
- [ ] Ready for feature branch

---

**Next:** Create worktree at `~/.git-worktrees/flow-cli-keychain-secrets`
