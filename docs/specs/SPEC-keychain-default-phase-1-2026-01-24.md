# SPEC: Keychain Default - Phase 1

**Date:** 2026-01-24
**Status:** Complete
**Branch:** feature/keychain-default-phase-1
**Effort:** 🔧 Medium-High (3-4 hours)
**Risk:** Medium (Architectural change to secret storage)

---

## Overview

Make macOS Keychain the **default** secret backend, with Bitwarden as an **optional** sync/backup target. This removes the friction of `dot unlock` for basic secret operations while preserving cloud backup capabilities for users who want them.

### Background

The current dual-storage architecture stores secrets in BOTH backends:
- **Bitwarden:** Cloud backup, cross-device sync (requires unlock)
- **Keychain:** Local cache, instant access (Touch ID)

**Problem:** All token operations require `dot unlock` first, even for local-only use.

**Solution:** Flip the default - Keychain is primary, Bitwarden is optional sync target.

---

## User Stories

### US-1: Basic Secret Storage (No Bitwarden)
```bash
# Before: Required Bitwarden
dot unlock                         # ← REQUIRED
dot token github                   # Store in both backends

# After: Just works
dot token github                   # Stores in Keychain only (default)
```

### US-2: Optional Cloud Backup
```bash
# Configure Bitwarden sync
export FLOW_SECRET_BACKEND="both"  # or: flow config set secret_backend both

# Now both backends are used
dot token github                   # Stores in Keychain + Bitwarden
```

### US-3: Manual Sync
```bash
dot secret sync                    # Sync Keychain ↔ Bitwarden
dot secret sync --to-bitwarden     # Push Keychain → Bitwarden
dot secret sync --from-bitwarden   # Pull Bitwarden → Keychain
```

### US-4: Backend Selection
```bash
# Check current backend
dot secret status
# Backend: keychain (default)
# Bitwarden: not configured

# Configure backend
export FLOW_SECRET_BACKEND="both"
dot secret status
# Backend: keychain + bitwarden
# Bitwarden: unlocked (session active)
```

---

## Configuration

### Environment Variable

```bash
# Backend options:
export FLOW_SECRET_BACKEND="keychain"    # Default - Keychain only (no Bitwarden)
export FLOW_SECRET_BACKEND="bitwarden"   # Bitwarden only (legacy mode)
export FLOW_SECRET_BACKEND="both"        # Both backends (sync mode)
```

### Priority Matrix

| Backend | `dot secret add` | `dot secret get` | `dot token *` | Requires Unlock |
|---------|------------------|------------------|---------------|-----------------|
| `keychain` (default) | Keychain only | Keychain only | Keychain only | No |
| `bitwarden` | Bitwarden only | Bitwarden only | Bitwarden only | Yes |
| `both` | Both backends | Keychain first, fallback Bitwarden | Both backends | For write ops |

### Configuration File (Future)

```yaml
# ~/.config/flow/config.yml (future enhancement)
secrets:
  backend: keychain
  bitwarden_sync: false
```

---

## API Changes

### New Functions

#### `_dot_secret_backend()`
Returns the configured backend ("keychain", "bitwarden", or "both").

```zsh
_dot_secret_backend() {
  echo "${FLOW_SECRET_BACKEND:-keychain}"
}
```

#### `_dot_secret_sync()`
Syncs secrets between Keychain and Bitwarden.

```zsh
dot secret sync              # Interactive sync
dot secret sync --to-bw      # Push Keychain → Bitwarden
dot secret sync --from-bw    # Pull Bitwarden → Keychain
dot secret sync --status     # Show sync status
```

#### `_dot_secret_status()`
Shows current backend configuration and status.

```zsh
_dot_secret_status() {
  local backend=$(_dot_secret_backend)
  echo "Backend: $backend"

  case $backend in
    keychain)
      echo "Keychain: $(security list-keychains | head -1)"
      echo "Bitwarden: not configured"
      ;;
    bitwarden)
      echo "Keychain: not used"
      echo "Bitwarden: $([[ -n "$BW_SESSION" ]] && echo "unlocked" || echo "locked")"
      ;;
    both)
      echo "Keychain: $(security list-keychains | head -1)"
      echo "Bitwarden: $([[ -n "$BW_SESSION" ]] && echo "unlocked" || echo "locked")"
      ;;
  esac
}
```

### Modified Functions

#### `_dot_token_add_impl()` (lines 2017-2190)
- Check backend config before Bitwarden operations
- Skip Bitwarden if backend is "keychain"
- Add Bitwarden operations if backend is "both"

#### `_dot_token_github()`, `_dot_token_npm()`, `_dot_token_pypi()`
- Remove mandatory `bw` requirement check when backend is "keychain"
- Keep Bitwarden logic for "bitwarden" and "both" modes

#### `_dot_secret()` dispatcher
- Add `status` subcommand
- Add `sync` subcommand
- Route based on backend configuration

---

## Implementation Plan

### Increment 1: Backend Configuration (30 min)

**Files to modify:**
- `lib/core.zsh` - Add `_dot_secret_backend()` function
- `lib/dispatchers/dot-dispatcher.zsh` - Add backend check at start

**Deliverables:**
- `FLOW_SECRET_BACKEND` environment variable support
- Default to "keychain" when not set
- Backend detection function

### Increment 2: Refactor `dot secret` (1 hour)

**Files to modify:**
- `lib/dispatchers/dot-dispatcher.zsh` - `_dot_secret()` function

**Changes:**
- Add `status` subcommand
- Route `add`/`get`/`list`/`delete` based on backend
- For "keychain" backend: use `_dot_kc_*` functions directly
- For "bitwarden" backend: use existing `_dot_secret_bw_*` functions
- For "both" backend: use Keychain primary, sync to Bitwarden

### Increment 3: Refactor Token Workflows (1.5 hours)

**Files to modify:**
- `lib/dispatchers/dot-dispatcher.zsh` - Token functions

**Changes to `_dot_token_github()` (lines 2017-2190):**
```zsh
# Before: Always requires Bitwarden
if ! _dot_require_tool "bw" "brew install bitwarden-cli"; then
  return 1
fi

# After: Check backend first
local backend=$(_dot_secret_backend)
if [[ "$backend" == "bitwarden" ]] || [[ "$backend" == "both" ]]; then
  if ! _dot_require_tool "bw" "brew install bitwarden-cli"; then
    return 1
  fi
fi
```

**Similar changes for:**
- `_dot_token_npm()` (lines 2532-2700)
- `_dot_token_pypi()` (lines 2711-2870)
- `_dot_token_status()` (lines 2902-3000)
- `_dot_env_*()` functions (lines 3100-3500)

### Increment 4: Add Sync Command (45 min)

**Files to create/modify:**
- `lib/dispatchers/dot-dispatcher.zsh` - Add `_dot_secret_sync()`

**Functionality:**
- `dot secret sync` - Interactive comparison and sync
- `dot secret sync --to-bw` - Push all Keychain secrets to Bitwarden
- `dot secret sync --from-bw` - Pull all Bitwarden secrets to Keychain
- `dot secret sync --status` - Show differences

### Increment 5: Update Documentation (30 min)

**Files to update:**
- `docs/reference/REFCARD-TOKEN-SECRETS.md`
- `docs/guides/TOKEN-MANAGEMENT-COMPLETE.md`
- `lib/keychain-helpers.zsh` (help text)

### Increment 6: Tests (30 min)

**Files to create/update:**
- `tests/test-keychain-default.zsh` - New test suite for backend switching
- `tests/test-dot-secret-keychain.zsh` - Update existing tests

---

## Migration Path

### For New Users
- No action needed - Keychain is default
- Optional: Set `FLOW_SECRET_BACKEND=both` for cloud backup

### For Existing Users (Bitwarden)
1. Existing secrets remain in Bitwarden
2. Run `dot secret sync --from-bitwarden` to copy to Keychain
3. Set `FLOW_SECRET_BACKEND=keychain` (now default)
4. Optional: Keep `FLOW_SECRET_BACKEND=both` for continued sync

### Backward Compatibility
- `FLOW_SECRET_BACKEND=bitwarden` preserves old behavior
- Existing `dot unlock` workflow still works
- No breaking changes to API

---

## Testing Strategy

### Unit Tests
- Backend configuration detection
- Routing based on backend
- Keychain-only operations

### Integration Tests
- Token add with Keychain-only backend
- Token add with both backends
- Sync operations

### Manual Testing
```bash
# Test 1: Keychain-only (default)
unset FLOW_SECRET_BACKEND
dot token github           # Should NOT require bw unlock
dot secret list            # Should show Keychain secrets

# Test 2: Bitwarden-only
export FLOW_SECRET_BACKEND=bitwarden
dot unlock
dot token github           # Should require bw unlock
dot secret list            # Should show Bitwarden secrets

# Test 3: Both backends
export FLOW_SECRET_BACKEND=both
dot unlock
dot token github           # Stores in both
dot secret sync --status   # Shows sync status
```

---

## Success Metrics

1. ✅ `dot token github` works without `dot unlock` (default mode)
2. ✅ `FLOW_SECRET_BACKEND` environment variable configures behavior
3. ✅ `dot secret sync` syncs between backends
4. ✅ `dot secret status` shows current configuration
5. ✅ All existing tests pass
6. ✅ New tests for backend switching pass
7. ✅ Documentation updated

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking existing workflows | High | `FLOW_SECRET_BACKEND=bitwarden` preserves old behavior |
| Token sync conflicts | Medium | Sync command shows diff before overwriting |
| Users confused by change | Low | Clear docs, migration guide, status command |

---

## Out of Scope (Future Phases)

1. Configuration file (`~/.config/flow/config.yml`)
2. Auto-sync on session start
3. Conflict resolution UI
4. Multi-device Keychain sync (iCloud Keychain integration)
5. Export/import for backup

---

## Approval

- [x] Spec reviewed
- [x] Implementation started
- [x] Tests passing (67 tests: 20 unit + 47 automated)
- [x] Documentation updated
- [x] PR created to dev (PR #295)

---

**Created:** 2026-01-24
**Author:** Claude (Orchestrator)
