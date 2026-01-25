# Brainstorm: Simplify `dot unlock` Process

**Date:** 2026-01-13
**Context:** `dot unlock` doesn't work reliably; direct `bw unlock` is more reliable
**Goal:** Simplify the unlock process while maintaining security

---

## Current Architecture (Complex)

```
dot unlock
    │
    ├─► _dot_bw_get_status()     # Check bw status JSON
    │       └─► bw status | grep
    │
    ├─► _dot_unlock()
    │       ├─► bw unlock --raw   # Get session token (captures stderr too!)
    │       ├─► export BW_SESSION
    │       ├─► bw unlock --check # Verify session
    │       └─► _dot_session_cache_save()
    │               └─► Write to ~/.cache/dot/session
    │
    └─► Session cache (15-min idle timeout)
            ├─► _dot_session_cache_expired()
            ├─► _dot_session_cache_touch()
            └─► _dot_session_time_remaining()
```

### Problems Identified

1. **`bw unlock --raw 2>&1`** - Captures both stdout AND stderr, so error messages get mixed with session token
2. **Session validation dance** - Multiple checks that can fail independently
3. **Cache file complexity** - Separate cache file that can get out of sync with actual BW state
4. **Export doesn't persist** - `export BW_SESSION` in subshell doesn't work for parent shell
5. **Over-engineered timeout** - 15-min idle timeout with custom cache, but BW has its own session management

---

## Plan A: Minimal Fix (Keep Architecture)

**Effort:** ⚡ Quick (< 30 min)
**Risk:** Low
**Changes:** 1 file

### Fix the Immediate Bug

```zsh
# BEFORE (broken)
session_token=$(bw unlock --raw 2>&1)

# AFTER (fixed - separate stdout/stderr)
local temp_err=$(mktemp)
session_token=$(bw unlock --raw 2>"$temp_err")
local unlock_status=$?
if [[ $unlock_status -ne 0 ]]; then
    cat "$temp_err" >&2
fi
rm -f "$temp_err"
```

### Pros

- Minimal change, low risk
- Fixes the immediate issue
- Keeps existing cache system

### Cons

- Doesn't simplify architecture
- Still has the subshell export problem
- Cache can still get out of sync

---

## Plan B: Delegate to Native `bw` (Simplify)

**Effort:** 🔧 Medium (1-2 hours)
**Risk:** Medium
**Changes:** 2 files

### Philosophy

Trust `bw` CLI to handle session management. Remove custom cache layer.

### Changes

```zsh
_dot_unlock() {
    # Simply run bw unlock interactively
    bw unlock

    # Capture and export the session
    _flow_log_info "Copy the export command above and run it, or:"
    _flow_log_info "  export BW_SESSION=\$(bw unlock --raw)"
}

_dot_bw_session_valid() {
    # Just check if BW_SESSION is set and valid
    [[ -n "$BW_SESSION" ]] && bw unlock --check &>/dev/null
}
```

### Remove

- `_dot_session_cache_*` functions (all 6)
- `DOT_SESSION_*` variables
- `~/.cache/dot/session` file

### Pros

- Much simpler code (~100 lines removed)
- Uses native BW session handling
- No cache sync issues
- Aligns with how users expect `bw` to work

### Cons

- Loses 15-min idle timeout feature
- User must manually export BW_SESSION
- Loses session time remaining display

---

## Plan C: Smart Wrapper (Best of Both)

**Effort:** 🔧 Medium (2-3 hours)
**Risk:** Medium
**Changes:** 2 files

### Philosophy

Thin wrapper that helps the user but doesn't fight the system.

### Key Changes

1. **Remove custom cache** - Trust BW's session management
2. **Fix export issue** - Use `eval` pattern for parent shell
3. **Better UX** - Show copy-paste command OR source pattern

```zsh
_dot_unlock() {
    if ! _dot_require_tool "bw"; then return 1; fi

    local status=$(_dot_bw_get_status)
    case "$status" in
        unlocked)
            _flow_log_success "Already unlocked"
            return 0
            ;;
        unauthenticated)
            _flow_log_error "Not logged in. Run: bw login"
            return 1
            ;;
    esac

    # Interactive unlock (user enters password)
    _flow_log_info "Unlocking Bitwarden..."

    # Method 1: Direct export (for interactive use)
    if [[ -t 0 ]]; then
        # Interactive terminal - use eval trick
        eval "$(bw unlock | grep 'export BW_SESSION')"
        if [[ -n "$BW_SESSION" ]]; then
            _flow_log_success "Unlocked! Session active."
            return 0
        fi
    fi

    # Method 2: Fallback - show instructions
    _flow_log_info "Run this command:"
    echo '  export BW_SESSION=$(bw unlock --raw)'
    return 0
}

_dot_bw_session_valid() {
    [[ -n "$BW_SESSION" ]] && bw unlock --check &>/dev/null
}
```

### Pros

- Simpler than current (~50 lines removed)
- Actually works with parent shell
- Still provides nice UX
- Falls back gracefully

### Cons

- No idle timeout feature
- No session time remaining display

---

## Plan D: Full Native Mode (Maximum Simplicity)

**Effort:** 🔧 Medium (1 hour)
**Risk:** Low
**Changes:** 2 files

### Philosophy

`dot unlock` just runs `bw unlock`. Period.

```zsh
_dot_unlock() {
    if ! command -v bw &>/dev/null; then
        _flow_log_error "Install: brew install bitwarden-cli"
        return 1
    fi

    # Just run bw unlock - it handles everything
    bw unlock
}

_dot_bw_session_valid() {
    bw unlock --check &>/dev/null 2>&1
}
```

### Remove Everything Else

- All `_dot_session_cache_*` functions
- All `DOT_SESSION_*` variables
- Session time remaining display
- Custom status checking

### Update Commands That Check Session

Replace `if ! _dot_bw_session_valid; then` with:

```zsh
if ! bw unlock --check &>/dev/null; then
    _flow_log_error "Vault locked. Run: bw unlock"
    return 1
fi
```

### Pros

- Maximum simplicity (~150 lines removed)
- Zero custom session handling
- Uses native BW completely
- Most reliable

### Cons

- Loses all custom UX (time remaining, idle timeout)
- Less "flow-cli" integrated
- User sees raw `bw` output

---

## Recommendation

### For Quick Fix: **Plan A**

If you just want `dot unlock` to work NOW, fix the `2>&1` bug.

### For Long-Term: **Plan C** (Smart Wrapper)

Best balance of simplicity and UX:
- Removes complex cache system
- Fixes the actual export problem
- Still provides helpful messaging
- Falls back gracefully

### For Maximum Reliability: **Plan D**

If you're frustrated with the custom layer:
- Delete all custom code
- Just use `bw unlock` directly
- Most reliable, least code

---

## Quick Wins

1. **⚡ Fix `2>&1` bug** (5 min) - Immediate improvement
2. **⚡ Remove cache check from `_dot_bw_session_valid`** (10 min) - Simplify validation
3. **⚡ Add `dot bw` alias** (2 min) - Direct access to `bw` commands

---

## Decision Needed

Which plan do you want to implement?

| Plan | Effort | Lines Changed | Reliability | UX |
|------|--------|---------------|-------------|-----|
| A: Minimal Fix | ⚡ 30 min | ~10 | Medium | Same |
| B: Delegate | 🔧 1-2h | -100 | High | Reduced |
| C: Smart Wrapper | 🔧 2-3h | -50 | High | Good |
| D: Full Native | 🔧 1h | -150 | Highest | Minimal |
| E: macOS Keychain | 🔧 2-3h | +100 | Highest | Best |

---

## Research Findings

### Bitwarden CLI Known Issues

**Issue:** `bw unlock --raw` in command substitution has known problems:

1. **Password prompt not visible** - When running `session=$(bw unlock --raw)`, the password prompt goes to stderr but gets hidden in command substitution context
2. **stderr/stdout mixing** - Using `2>&1` captures error messages into the session token variable
3. **No TTY for password input** - Command substitution doesn't provide proper TTY

**Community Workarounds:**
- Use `--passwordenv BW_PASSWORD` to pass password via environment variable (security risk)
- Use `--passwordfile` to read from file (also security risk)
- Run `bw unlock` interactively first, then copy the export command

**Official Bitwarden stance:** The CLI is designed for interactive use; session management is intentionally manual.

### macOS Keychain (`security` command)

macOS provides native secure credential storage via the `security` command:

```bash
# Store a password
security add-generic-password \
    -a "account-name" \
    -s "service-name" \
    -w "the-password" \
    -U  # Update if exists

# Retrieve a password
security find-generic-password \
    -a "account-name" \
    -s "service-name" \
    -w  # Output password only

# Delete a password
security delete-generic-password \
    -a "account-name" \
    -s "service-name"
```

**Benefits:**
- Native macOS security (Keychain Access)
- No external dependencies
- Automatic lock with screen lock
- Touch ID / Apple Watch unlock support
- No session management needed
- Works offline

**Limitations:**
- macOS only (no Linux/Windows)
- Separate from Bitwarden vault
- No sync across devices (unless iCloud Keychain)
- Manual migration from Bitwarden

---

## Plan E: macOS Keychain (Native Alternative)

**Effort:** 🔧 Medium (2-3 hours)
**Risk:** Low
**Changes:** New file + dispatcher updates

### Philosophy

Use macOS native Keychain for local secrets. Keep Bitwarden for cross-device sync, use Keychain for daily local operations.

### New Commands

```bash
dot secret add <name>         # Prompt for value, store in Keychain
dot secret get <name>         # Retrieve from Keychain (silent)
dot secret list               # List all dot-managed secrets
dot secret delete <name>      # Remove from Keychain
dot secret import             # Import from Bitwarden to Keychain (one-time)
```

### Implementation

```zsh
# Constants
_DOT_KEYCHAIN_SERVICE="flow-cli-secrets"

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

    # Store in Keychain
    security add-generic-password \
        -a "$name" \
        -s "$_DOT_KEYCHAIN_SERVICE" \
        -w "$secret_value" \
        -U 2>/dev/null

    if [[ $? -eq 0 ]]; then
        _flow_log_success "Secret '$name' stored in Keychain"
    else
        _flow_log_error "Failed to store secret"
        return 1
    fi
}

_dot_secret_get() {
    local name="$1"
    security find-generic-password \
        -a "$name" \
        -s "$_DOT_KEYCHAIN_SERVICE" \
        -w 2>/dev/null
}

_dot_secret_list() {
    _flow_log_info "Secrets in Keychain:"
    security dump-keychain 2>/dev/null | \
        grep -A4 "\"svce\"<blob>=\"$_DOT_KEYCHAIN_SERVICE\"" | \
        grep "\"acct\"" | \
        sed 's/.*"\(.*\)".*/  - \1/'
}

_dot_secret_delete() {
    local name="$1"
    security delete-generic-password \
        -a "$name" \
        -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null

    if [[ $? -eq 0 ]]; then
        _flow_log_success "Secret '$name' deleted"
    else
        _flow_log_error "Secret not found"
        return 1
    fi
}

# One-time import from Bitwarden
_dot_secret_import() {
    if ! _dot_bw_session_valid; then
        _flow_log_error "Bitwarden locked. Run: bw unlock"
        return 1
    fi

    _flow_log_info "Importing secrets from Bitwarden to Keychain..."

    # Get all items with 'dot-secret' folder or tag
    local items=$(bw list items --folderid "dot-secrets" 2>/dev/null)

    echo "$items" | jq -r '.[] | "\(.name)\t\(.login.password)"' | \
    while IFS=$'\t' read -r name password; do
        security add-generic-password \
            -a "$name" \
            -s "$_DOT_KEYCHAIN_SERVICE" \
            -w "$password" \
            -U 2>/dev/null
        _flow_log_success "Imported: $name"
    done
}
```

### Usage in Other Commands

```zsh
# Before (Bitwarden)
_dot_get_secret() {
    bw get password "$1"  # Requires unlock, network, etc.
}

# After (Keychain)
_dot_get_secret() {
    _dot_secret_get "$1"  # Instant, local, no unlock needed
}
```

### Pros

- **Instant access** - No unlock step for daily use
- **Native security** - macOS handles encryption, Touch ID
- **Offline** - Works without network
- **No session management** - Keychain handles everything
- **Automatic lock** - Locks with screen lock
- **Simple code** - Just `security` command calls

### Cons

- **macOS only** - No Linux/Windows support
- **Separate storage** - Not synced with Bitwarden
- **Migration effort** - One-time import needed
- **Two systems** - Bitwarden for sync, Keychain for local

### Hybrid Approach

Keep both systems:
1. **Bitwarden** - Master vault, cross-device sync, team sharing
2. **Keychain** - Daily local operations, instant access

```zsh
dot secret get <name>    # Try Keychain first, fallback to Bitwarden
dot secret sync          # Sync specific secrets from BW → Keychain
```

---

## Updated Recommendation

### For macOS Users: **Plan E** (Keychain)

Best for daily local workflow:
- Instant secret access
- No unlock dance
- Touch ID support
- Automatic screen lock integration

### For Cross-Platform: **Plan C** (Smart Wrapper)

If you need Linux/Windows support, fix the BW integration.

### For Quick Fix: **Plan A**

Just fix the `2>&1` bug if you want minimal change.

---

## Implementation Priority

1. **⚡ Plan A** (5 min) - Fix immediate `2>&1` bug
2. **🔧 Plan E** (2-3h) - Add Keychain support
3. **🔄 Deprecate** - Phase out BW session management
4. **📚 Document** - Update secret management guide
