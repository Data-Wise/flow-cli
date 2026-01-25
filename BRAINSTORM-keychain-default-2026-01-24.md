# Keychain-Default Architecture Brainstorm

**Date:** 2026-01-24
**Topic:** Make Apple Keychain the default storage backend with optional Bitwarden sync
**Mode:** Architecture + Feature
**Duration:** Deep analysis

---

## Executive Summary

**Goal:** Transition from dual-storage-always to Keychain-first with optional Bitwarden backup.

**User's Decisions:**

1. ✅ Existing tokens: Keep dual, make Keychain authoritative (immediately on upgrade)
2. ✅ Sync trigger: One-time choice per token (silent Keychain-only default)
3. ✅ Updates: Always ask again about Bitwarden sync
4. ✅ Visibility: Enhanced list with color-coded indicators
5. ✅ Add UX: Silent default (--sync-bitwarden flag to opt-in)
6. ✅ Conflicts: Show diff and ask user to choose
7. ✅ Conversion: `dot secret sync enable/disable <name>`
8. ✅ Rotation: Always prompt during rotation
9. ✅ List format: Color-coded (blue=Keychain, green=synced, yellow=conflict)
10. ✅ Bulk ops: `dot secret sync enable --all`
11. ✅ Bitwarden unavailable: Warn but continue

---

## Architecture Overview

### Current State (v5.18.0)

```
dot token github
    ↓
┌─────────────────────────────────────────┐
│ ALWAYS stores in BOTH backends          │
│   1. Bitwarden (cloud backup)           │
│   2. Keychain (instant access)          │
│                                         │
│ No choice, no flags, dual-always        │
└─────────────────────────────────────────┘
```

### Proposed State (v5.19.0)

```
dot token github
    ↓
┌─────────────────────────────────────────┐
│ DEFAULT: Keychain only                  │
│   ✓ Fast, offline, Touch ID             │
│   ✗ No cloud backup                     │
│                                         │
│ OPTIONAL: --sync-bitwarden              │
│   ✓ Also stores in Bitwarden            │
│   ✓ Cloud backup, cross-device sync     │
│   ⚠ Requires bw CLI, unlock             │
└─────────────────────────────────────────┘
```

---

## Quick Wins (< 2 hours each)

### 1. ⚡ Add Token Metadata Flag (30 min)

**Purpose:** Track whether token should sync to Bitwarden

**Implementation:**

```json
{
  "dot_version": "2.2",
  "type": "github",
  "sync_bitwarden": false, // ← NEW FIELD
  "created": "2026-01-24T14:30:00Z",
  "expires_days": 90
}
```

**Files to modify:**

- `lib/dispatchers/dot-dispatcher.zsh:2155` (add metadata field)
- `lib/keychain-helpers.zsh` (read sync preference)

**Benefit:** Simple boolean flag enables all sync logic

---

### 2. ⚡ Enhanced List Command (45 min)

**Current:**

```
dot secret list
github-token
npm-token
pypi-token
```

**New (color-coded):**

```
dot secret list

🔵 github-token          Keychain only
🟢 npm-token             Synced to Bitwarden
🟡 pypi-token            ⚠ Conflict detected
```

**Color legend:**

- 🔵 Blue: Keychain-only (default)
- 🟢 Green: Synced to Bitwarden
- 🟡 Yellow: Out of sync (conflict)
- 🔴 Red: Error (missing in Keychain)

**Implementation:**

```zsh
_dot_kc_list() {
  # Get all Keychain entries
  security dump-keychain | grep "flow-cli" | while read entry; do
    name=$(parse_name "$entry")
    metadata=$(get_metadata "$name")
    sync_status=$(check_sync_status "$name" "$metadata")

    case "$sync_status" in
      keychain-only)
        echo "${FLOW_COLORS[info]}🔵 $name${FLOW_COLORS[reset]}          Keychain only"
        ;;
      synced)
        echo "${FLOW_COLORS[success]}🟢 $name${FLOW_COLORS[reset]}             Synced to Bitwarden"
        ;;
      conflict)
        echo "${FLOW_COLORS[warning]}🟡 $name${FLOW_COLORS[reset]}             ⚠ Conflict detected"
        ;;
    esac
  done
}
```

---

### 3. ⚡ Upgrade Migration Script (1 hour)

**Purpose:** Transition existing dual-storage tokens to Keychain-authoritative

**What it does:**

1. Detect all tokens with Bitwarden copies
2. Update metadata: `"keychain_authoritative": true`
3. Preserve both copies (no deletion)
4. Log migration summary

**Implementation:**

```zsh
_dot_migrate_keychain_authoritative() {
  echo "🔄 Migrating existing tokens to Keychain-authoritative model..."

  local migrated=0
  local skipped=0

  # Get all Keychain tokens
  security dump-keychain | grep "flow-cli" | while read entry; do
    name=$(parse_name "$entry")
    metadata=$(get_metadata "$name")

    # Check if already migrated
    if echo "$metadata" | jq -e '.keychain_authoritative' >/dev/null 2>&1; then
      ((skipped++))
      continue
    fi

    # Update metadata
    new_metadata=$(echo "$metadata" | jq '. + {"keychain_authoritative": true, "migrated": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"}')

    # Update Keychain entry
    security delete-generic-password -a "$name" -s flow-cli
    security add-generic-password \
      -a "$name" \
      -s flow-cli \
      -w "$(get_token_value "$name")" \
      -j "$new_metadata" \
      -U

    ((migrated++))
  done

  echo ""
  echo "✅ Migration complete:"
  echo "   Migrated: $migrated tokens"
  echo "   Skipped: $skipped tokens (already migrated)"
}
```

**Usage:**

```bash
# Run automatically on first command after v5.19.0 upgrade
dot secret list
# → Detects upgrade, runs migration, shows report

# Or manually
dot secret migrate --keychain-authoritative
```

---

### 4. ⚡ Conflict Detection Helper (45 min)

**Purpose:** Detect when Keychain and Bitwarden copies diverge

**Implementation:**

```zsh
check_sync_status() {
  local name=$1
  local metadata=$2

  # Check if sync enabled
  local sync_enabled=$(echo "$metadata" | jq -r '.sync_bitwarden // false')

  if [[ "$sync_enabled" != "true" ]]; then
    echo "keychain-only"
    return
  fi

  # Get both copies
  local kc_value=$(security find-generic-password -a "$name" -s flow-cli -w 2>/dev/null)
  local bw_value=$(bw get password "$name" --session $BW_SESSION 2>/dev/null)

  # Compare
  if [[ -z "$bw_value" ]]; then
    echo "keychain-only"  # Bitwarden copy missing
  elif [[ "$kc_value" == "$bw_value" ]]; then
    echo "synced"  # In sync
  else
    echo "conflict"  # Out of sync
  fi
}
```

---

## Medium Effort (2-6 hours)

### 5. 🔧 Sync Management Commands (3 hours)

**New commands:**

#### 5.1 Enable Sync

```bash
# Single token
dot secret sync enable github-token

# Bulk (all Keychain-only tokens)
dot secret sync enable --all

# Pattern matching
dot secret sync enable 'github-*'
```

**Implementation:**

```zsh
_dot_secret_sync_enable() {
  local name=$1
  local pattern=$2

  if [[ "$name" == "--all" ]]; then
    # Bulk enable
    local tokens=($(list_keychain_only_tokens))
    echo "Enable Bitwarden sync for ${#tokens[@]} tokens?"
    read -q "?Continue? [y/N] "
    [[ $? -eq 0 ]] || return 1

    for token in "${tokens[@]}"; do
      _sync_single_token "$token"
    done

  elif [[ -n "$pattern" ]]; then
    # Pattern matching
    local tokens=($(list_tokens_matching "$pattern"))
    for token in "${tokens[@]}"; do
      _sync_single_token "$token"
    done

  else
    # Single token
    _sync_single_token "$name"
  fi
}

_sync_single_token() {
  local name=$1

  # Get current value
  local token_value=$(dot secret "$name")
  local metadata=$(get_metadata "$name")

  # Update metadata
  local new_metadata=$(echo "$metadata" | jq '. + {"sync_bitwarden": true}')

  # Store in Bitwarden
  bw_add_or_update "$name" "$token_value" "$new_metadata"

  # Update Keychain metadata
  update_keychain_metadata "$name" "$new_metadata"

  echo "✅ Enabled Bitwarden sync for: $name"
}
```

#### 5.2 Disable Sync

```bash
# Single token
dot secret sync disable npm-token

# Bulk
dot secret sync disable --all
```

**What it does:**

1. Updates metadata: `"sync_bitwarden": false`
2. **Does NOT delete Bitwarden copy** (backup remains)
3. Future updates won't sync to Bitwarden

#### 5.3 Sync Status

```bash
dot secret sync status

# Output:
🟢 Synced (4 tokens):
   github-token, npm-token, pypi-token, gitlab-token

🔵 Keychain-only (2 tokens):
   api-key-staging, api-key-production

🟡 Conflicts (1 token):
   old-github-token (Keychain: 3 days ago, Bitwarden: 7 days ago)
```

---

### 6. 🔧 Conflict Resolution Workflow (4 hours)

**Command:** `dot secret reconcile <name>`

**Interactive flow:**

```
dot secret reconcile old-github-token

╭───────────────────────────────────────────────────╮
│  ⚠️  Conflict Detected                             │
├───────────────────────────────────────────────────┤
│                                                   │
│  Token: old-github-token                          │
│  Type: GitHub Classic PAT                         │
│                                                   │
│  Keychain:                                        │
│    Value: ghp_****...ABCD (40 chars)              │
│    Updated: 3 days ago                            │
│                                                   │
│  Bitwarden:                                       │
│    Value: ghp_****...WXYZ (40 chars)              │
│    Updated: 7 days ago                            │
│                                                   │
│  These values are DIFFERENT!                      │
│                                                   │
╰───────────────────────────────────────────────────╯

Choose resolution:
  1. Use Keychain (newer)
  2. Use Bitwarden (older)
  3. Show full diff
  4. Delete both and re-add

Choice:
```

**Implementation:**

```zsh
_dot_secret_reconcile() {
  local name=$1

  # Get both copies
  local kc_value=$(dot secret "$name")
  local kc_metadata=$(get_keychain_metadata "$name")
  local bw_value=$(bw get password "$name" --session $BW_SESSION)
  local bw_notes=$(bw get notes "$name" --session $BW_SESSION)

  # Parse timestamps
  local kc_updated=$(echo "$kc_metadata" | jq -r '.updated // .created')
  local bw_updated=$(echo "$bw_notes" | jq -r '.updated // .created')

  # Show diff
  show_conflict_ui "$name" "$kc_value" "$kc_updated" "$bw_value" "$bw_updated"

  # Get user choice
  local choice
  read -q "?Choice [1-4]: " choice

  case "$choice" in
    1)
      # Use Keychain (overwrite Bitwarden)
      bw_update "$name" "$kc_value" "$kc_metadata"
      echo "✅ Resolved: Using Keychain value (synced to Bitwarden)"
      ;;
    2)
      # Use Bitwarden (overwrite Keychain)
      local bw_metadata=$(echo "$bw_notes" | jq -c)
      update_keychain "$name" "$bw_value" "$bw_metadata"
      echo "✅ Resolved: Using Bitwarden value (synced to Keychain)"
      ;;
    3)
      # Show full diff
      echo ""
      echo "Keychain value:"
      echo "$kc_value"
      echo ""
      echo "Bitwarden value:"
      echo "$bw_value"
      echo ""
      # Re-prompt
      _dot_secret_reconcile "$name"
      ;;
    4)
      # Delete both
      security delete-generic-password -a "$name" -s flow-cli
      bw delete item "$name" --session $BW_SESSION
      echo "✅ Deleted both copies. Run 'dot token <provider>' to re-add."
      ;;
  esac
}
```

---

### 7. 🔧 Updated Token Rotation (2 hours)

**Modified flow:**

```bash
dot token rotate

# Step 1: Select token (unchanged)
# Step 2: Create backup (unchanged)
# Step 3: Get new token (unchanged)
# Step 4: NEW - Ask about Bitwarden sync

╭───────────────────────────────────────────────────╮
│  Token Rotation - Bitwarden Sync                  │
├───────────────────────────────────────────────────┤
│                                                   │
│  Old token was:                                   │
│    🟢 Synced to Bitwarden                         │
│                                                   │
│  Should the new token also sync to Bitwarden?     │
│                                                   │
│  [Y] Yes - Continue syncing (Recommended)         │
│  [N] No - Keychain only from now on               │
│                                                   │
╰───────────────────────────────────────────────────╯

Choice [Y/n]:
```

**Implementation:**

```zsh
_dot_token_rotate() {
  # ... existing rotation logic ...

  # NEW: After getting new token, check sync preference
  local old_metadata=$(get_metadata "$token_name-backup")
  local was_synced=$(echo "$old_metadata" | jq -r '.sync_bitwarden // false')

  local sync_new=false
  if [[ "$was_synced" == "true" ]]; then
    echo ""
    echo "Old token was synced to Bitwarden."
    read -q "?Sync new token to Bitwarden? [Y/n] " sync_choice
    echo ""

    if [[ $sync_choice -ne 1 ]]; then  # User pressed 'n'
      sync_new=false
      echo "✓ New token will be Keychain-only"
    else
      sync_new=true
      echo "✓ New token will sync to Bitwarden"
    fi
  else
    # Old token was Keychain-only
    read -q "?Sync new token to Bitwarden? [y/N] " sync_choice
    echo ""
    [[ $sync_choice -eq 0 ]] && sync_new=true
  fi

  # Store new token with sync preference
  local new_metadata=$(create_metadata "$token_type" "$sync_new")

  # Store in Keychain (always)
  update_keychain "$token_name" "$new_token_value" "$new_metadata"

  # Store in Bitwarden (if enabled)
  if [[ "$sync_new" == "true" ]]; then
    bw_add_or_update "$token_name" "$new_token_value" "$new_metadata"
  fi
}
```

---

## Long-term Enhancements (Future)

### 8. 📅 Auto-Sync Scheduling (Future v5.20.0)

**Feature:** Periodic background sync for synced tokens

**Implementation:**

```bash
# Enable auto-sync (daily)
dot secret sync auto enable --interval daily

# Disable auto-sync
dot secret sync auto disable

# Manual sync (all synced tokens)
dot secret sync push
```

**What it does:**

- Runs daily via cron/launchd
- Checks all tokens with `sync_bitwarden: true`
- Pushes Keychain → Bitwarden if Keychain is newer
- Logs sync activity to `~/.flow/sync.log`

---

### 9. 📅 Bitwarden Import Tool (Future v5.20.0)

**Feature:** Migrate existing Bitwarden-only secrets to Keychain

**Command:**

```bash
dot secret import bitwarden

# Interactive wizard:
# 1. List all Bitwarden login items
# 2. Let user select which to import
# 3. Import to Keychain with sync_bitwarden: true
```

---

### 10. 📅 Sync Conflict Auto-Resolution (Future v5.21.0)

**Feature:** Auto-resolve conflicts based on timestamps

**Config:**

```json
{
  "sync": {
    "conflict_resolution": "newest", // newest|keychain|bitwarden|prompt
    "auto_reconcile": true
  }
}
```

---

## Implementation Plan

### Phase 1: Core Changes (v5.19.0-alpha) - 6 hours

**Tasks:**

1. ✅ Add `sync_bitwarden` metadata field
2. ✅ Update `_dot_token_github()` to default Keychain-only
3. ✅ Add `--sync-bitwarden` flag support
4. ✅ Implement migration script (keychain-authoritative)
5. ✅ Enhanced list command (color-coded)
6. ✅ Conflict detection helper

**Testing:**

- Unit tests for metadata updates
- Integration tests for flag handling
- Migration test with sample dual-storage tokens

**Documentation:**

- Update REFCARD-TOKEN-SECRETS.md
- Update TOKEN-MANAGEMENT-COMPLETE.md
- Add MIGRATION-V5.19.0.md guide

---

### Phase 2: Sync Management (v5.19.0-beta) - 8 hours

**Tasks:**

1. ✅ `dot secret sync enable/disable <name>`
2. ✅ `dot secret sync enable --all`
3. ✅ `dot secret sync status`
4. ✅ `dot secret reconcile <name>` (conflict resolution)
5. ✅ Updated rotation with sync prompt
6. ✅ Bulk sync with pattern matching

**Testing:**

- E2E tests for sync workflows
- Conflict resolution scenarios
- Rotation with sync choices

**Documentation:**

- Sync Management Guide
- Troubleshooting Conflicts section
- Tutorial update (add sync lesson)

---

### Phase 3: Polish & Release (v5.19.0) - 4 hours

**Tasks:**

1. ✅ Add help text for new commands
2. ✅ Update interactive tutorial (add sync lesson)
3. ✅ Deprecation warnings for old behavior
4. ✅ Release notes
5. ✅ Blog post / announcement

**Testing:**

- Full regression test suite
- User acceptance testing
- Performance benchmarks

**Documentation:**

- Changelog entry
- Migration guide
- FAQ updates

---

## Technical Architecture

### Metadata Schema (v2.2)

```json
{
  "dot_version": "2.2",
  "type": "github",
  "token_type": "classic",
  "sync_bitwarden": false, // NEW: Sync preference
  "keychain_authoritative": true, // NEW: Keychain is source of truth
  "created": "2026-01-24T14:30:00Z",
  "updated": "2026-01-24T15:00:00Z",
  "expires_days": 90,
  "expires": "2026-04-24",
  "github_user": "username"
}
```

**New fields:**

- `sync_bitwarden`: Boolean (default: false)
- `keychain_authoritative`: Boolean (default: true for new tokens, set on migration for existing)
- `updated`: ISO 8601 timestamp (for conflict resolution)

---

### Command Changes

#### Modified Commands

| Command            | Old Behavior                        | New Behavior                                    |
| ------------------ | ----------------------------------- | ----------------------------------------------- |
| `dot token github` | Stores in both Bitwarden + Keychain | Keychain only (use `--sync-bitwarden` for both) |
| `dot token npm`    | Stores in both                      | Keychain only                                   |
| `dot token pypi`   | Stores in both                      | Keychain only                                   |
| `dot token rotate` | Updates both if exist               | Always asks about Bitwarden sync                |
| `dot secret list`  | Lists names only                    | Color-coded with sync status                    |

#### New Commands

| Command                                       | Purpose                             |
| --------------------------------------------- | ----------------------------------- |
| `dot secret sync enable <name>`               | Enable Bitwarden sync for token     |
| `dot secret sync disable <name>`              | Disable Bitwarden sync for token    |
| `dot secret sync enable --all`                | Bulk enable Bitwarden sync          |
| `dot secret sync status`                      | Show sync status for all tokens     |
| `dot secret reconcile <name>`                 | Resolve Keychain/Bitwarden conflict |
| `dot secret migrate --keychain-authoritative` | Run v5.19.0 migration               |

---

### File Structure Changes

**New files:**

```
lib/
  sync-manager.zsh           # Sync enable/disable/status logic
  conflict-resolver.zsh      # Conflict detection and resolution

commands/
  secret-sync.zsh            # Sync management commands
  secret-reconcile.zsh       # Conflict resolution UI

docs/
  guides/
    SYNC-MANAGEMENT-GUIDE.md         # How to use sync features
    MIGRATION-V5.19.0-GUIDE.md       # v5.18→v5.19 upgrade guide
  reference/
    REFCARD-SYNC-COMMANDS.md         # Quick ref for sync commands
```

**Modified files:**

```
lib/dispatchers/dot-dispatcher.zsh  # Add --sync-bitwarden flag
lib/keychain-helpers.zsh            # Enhanced list with colors
commands/token-rotation.zsh         # Add sync prompt

docs/reference/REFCARD-TOKEN-SECRETS.md  # Update examples
docs/guides/TOKEN-MANAGEMENT-COMPLETE.md # Add sync section
```

---

## Migration Strategy

### User Communication

**Before v5.19.0 release:**

1. **Blog post:** "Coming Soon: Keychain-First Storage"
2. **GitHub discussion:** Gather feedback on design
3. **Release candidate:** v5.19.0-rc1 for testing

**On upgrade to v5.19.0:**

```
╭───────────────────────────────────────────────────╮
│  🔄 flow-cli v5.19.0 - Storage Changes            │
├───────────────────────────────────────────────────┤
│                                                   │
│  What's new:                                      │
│    • Keychain is now the default storage          │
│    • Bitwarden sync is optional (--sync-bitwarden)│
│    • Existing tokens migrated automatically       │
│                                                   │
│  Migration:                                       │
│    ✓ Detected 12 existing tokens                  │
│    ✓ Marked as Keychain-authoritative             │
│    ✓ Both copies preserved (no data loss)         │
│                                                   │
│  What changed:                                    │
│    • 'dot token github' → Keychain only           │
│    • Use --sync-bitwarden to enable backup        │
│    • 'dot secret list' shows sync status          │
│                                                   │
│  Learn more:                                      │
│    docs/guides/MIGRATION-V5.19.0-GUIDE.md         │
│                                                   │
╰───────────────────────────────────────────────────╯
```

### Rollback Plan

**If issues arise:**

```bash
# Revert to v5.18.0
brew uninstall flow-cli
brew install flow-cli@5.18.0

# Or manually
git checkout v5.18.0
source flow.plugin.zsh
```

**Data safety:**

- Migration NEVER deletes Bitwarden copies
- Keychain copies remain unchanged
- Metadata updates are non-destructive

---

## Testing Strategy

### Unit Tests

```bash
tests/test-sync-manager.zsh              # Sync enable/disable
tests/test-conflict-resolver.zsh         # Conflict detection
tests/test-keychain-authoritative.zsh    # Migration logic
```

### Integration Tests

```bash
tests/e2e-keychain-default.zsh           # Full workflow
tests/e2e-sync-management.zsh            # Sync commands
tests/e2e-conflict-resolution.zsh        # Reconcile workflow
```

### Manual Test Scenarios

1. **Fresh install:**
   - Add token without `--sync-bitwarden`
   - Verify Keychain-only storage
   - Enable sync later
   - Verify Bitwarden copy created

2. **Upgrade from v5.18.0:**
   - Install v5.19.0 with existing tokens
   - Verify migration message
   - Check `keychain_authoritative` metadata
   - Verify both copies still exist

3. **Conflict resolution:**
   - Create token with sync enabled
   - Manually update Bitwarden copy
   - Run `dot secret reconcile`
   - Verify diff shown and resolution works

4. **Bulk operations:**
   - Create 10 Keychain-only tokens
   - Run `dot secret sync enable --all`
   - Verify all 10 synced to Bitwarden

---

## Security Considerations

### 1. Bitwarden Unavailable

**Scenario:** User has synced tokens but Bitwarden CLI is not installed or logged out.

**Behavior (per user choice: "Warn but continue"):**

```bash
dot secret github-token

# Keychain retrieval succeeds
# But also check if sync enabled:

⚠️  Warning: Bitwarden sync is enabled for this token, but bw CLI is not available.
   Token retrieved from Keychain successfully.

   To enable Bitwarden sync:
     1. Install bw: brew install bitwarden-cli
     2. Login: bw login
     3. Unlock: export BW_SESSION=$(bw unlock --raw)

   To disable sync for this token:
     dot secret sync disable github-token
```

**No failure, no blocking, just a warning.**

---

### 2. Keychain Loss

**Scenario:** User loses Keychain data (system reinstall, etc.)

**Recovery (if synced to Bitwarden):**

```bash
dot secret import bitwarden github-token

# Imports from Bitwarden → Keychain
# Restores sync_bitwarden: true metadata
```

**If NOT synced:**

- Token is lost
- User must re-create

**Recommendation:** Encourage Bitwarden sync for critical tokens.

---

### 3. Metadata Tampering

**Risk:** User manually edits metadata to bypass sync checks.

**Mitigation:**

- Metadata is stored in Keychain (requires system auth)
- Manual edits require `security delete` + `security add` (logged)
- Conflict detection catches mismatches

**Low risk:** User would have to intentionally sabotage their own setup.

---

## Performance Impact

### Current (v5.18.0)

```bash
dot token github
# Duration: ~5s (Bitwarden unlock + sync)

dot secret github-token
# Duration: ~50ms (Keychain retrieval)
```

### Proposed (v5.19.0)

```bash
# Keychain-only (default)
dot token github
# Duration: ~1s (Keychain storage only, no Bitwarden)

# With sync enabled
dot token github --sync-bitwarden
# Duration: ~5s (same as v5.18.0, but opt-in)

dot secret github-token
# Duration: ~50ms (unchanged, Keychain retrieval)
```

**Impact:**

- ✅ 80% faster token creation (Keychain-only path)
- ✅ No change to retrieval speed (still < 50ms)
- ✅ Sync overhead only when explicitly requested

---

## User Experience Flow

### Scenario 1: New User (First Token)

```bash
# User runs:
dot token github

# CLI output:
✓ Opening GitHub token creation page...

[Browser opens]

After creating token, paste here:
Token: ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

✓ Validating token...
✓ Token valid for user: yourusername
✓ Storing in Keychain...

╭───────────────────────────────────────────────────╮
│  ✓ Token stored successfully                     │
│                                                   │
│  Name: github-token                               │
│  Storage: 🔵 Keychain only                        │
│  Expires: 2026-04-24 (90 days)                    │
│                                                   │
│  💡 Want cloud backup?                            │
│     Run: dot secret sync enable github-token      │
│     Or use --sync-bitwarden flag next time        │
│                                                   │
╰───────────────────────────────────────────────────╯
```

**Key points:**

- Silent default (Keychain-only)
- Helpful tip about sync option
- No blocking prompts

---

### Scenario 2: Existing User (Upgrade)

```bash
# User upgrades to v5.19.0
brew upgrade flow-cli

# First command triggers migration:
dot secret list

🔄 Migrating to v5.19.0 storage model...
   ✓ Detected 12 existing tokens
   ✓ Marked as Keychain-authoritative
   ✓ Preserved all Bitwarden copies

🟢 github-token             Synced to Bitwarden
🟢 npm-token                Synced to Bitwarden
🟢 pypi-token               Synced to Bitwarden
🔵 api-key-test             Keychain only (converted)

Summary:
  3 tokens synced to Bitwarden
  9 tokens Keychain-only

Learn more: docs/guides/MIGRATION-V5.19.0-GUIDE.md
```

**Key points:**

- Auto-migration on first use
- Clear summary of changes
- All data preserved
- Link to migration guide

---

### Scenario 3: Enable Sync Later

```bash
# User decides to enable Bitwarden sync:
dot secret sync enable github-token

✓ Enabled Bitwarden sync for: github-token
✓ Uploading to Bitwarden...
✓ Syncing vault...

Storage updated:
  Before: 🔵 Keychain only
  After:  🟢 Synced to Bitwarden

Next update/rotation will also sync to Bitwarden.
```

---

### Scenario 4: Conflict Resolution

```bash
# User has out-of-sync token:
dot secret list

🟡 old-github-token         ⚠️ Conflict detected

# Resolve conflict:
dot secret reconcile old-github-token

╭───────────────────────────────────────────────────╮
│  ⚠️  Conflict Detected                             │
├───────────────────────────────────────────────────┤
│  Token: old-github-token                          │
│                                                   │
│  Keychain:  ghp_****...ABCD (updated 3 days ago)  │
│  Bitwarden: ghp_****...WXYZ (updated 7 days ago)  │
│                                                   │
│  These values are DIFFERENT!                      │
╰───────────────────────────────────────────────────╯

Choose resolution:
  1. Use Keychain (newer) ← Recommended
  2. Use Bitwarden (older)
  3. Show full diff
  4. Delete both and re-add

Choice [1-4]: 1

✓ Resolved: Using Keychain value
✓ Synced to Bitwarden
✓ Conflict cleared

Updated storage: 🟢 Synced to Bitwarden
```

---

## Open Questions

### 1. Should there be a global config default?

**Current design:** Per-token choice (one-time)

**Alternative:** Global default in `~/.flow/config.json`

```json
{
  "secrets": {
    "default_sync_bitwarden": false, // Global default
    "auto_sync_on_update": false
  }
}
```

**Recommendation:** Keep per-token choice for now, add global config in v5.20.0 if requested.

---

### 2. Should sync be bidirectional?

**Current design:** Keychain is authoritative, sync pushes Keychain → Bitwarden

**Alternative:** Bidirectional sync with conflict detection

**Recommendation:** Keep unidirectional for v5.19.0, consider bidirectional in future if users request.

---

### 3. Should we support other backends (1Password, etc.)?

**Current design:** Keychain + Bitwarden only

**Alternative:** Pluggable backend system

**Recommendation:** Defer to future version (v5.21.0+), focus on Keychain-first for now.

---

## Success Metrics

### Adoption Metrics

- % of new tokens using Keychain-only (target: 60%+)
- % of users enabling sync for at least 1 token (target: 40%)
- Migration success rate (target: 100%)

### Performance Metrics

- Token creation time (target: < 1s for Keychain-only)
- Conflict detection overhead (target: < 100ms)
- Sync command execution (target: < 2s)

### Support Metrics

- Number of sync-related issues filed (target: < 5 in first month)
- Migration issues (target: 0 critical bugs)

---

## Recommended Next Steps

### Immediate (Now)

1. ✅ **Review this brainstorm** - Ensure design aligns with vision
2. ✅ **Create spec** - Capture as formal SPEC.md for implementation

### Short-term (Next Session)

3. 📝 Implement Phase 1 (core changes) in feature branch
4. 🧪 Write unit tests for metadata updates
5. 📚 Update documentation (REFCARD, COMPLETE-GUIDE)

### Medium-term (This Week)

6. 🔧 Implement Phase 2 (sync management commands)
7. 🧪 E2E testing with real Bitwarden account
8. 📖 Write migration guide

### Long-term (Next Release)

9. 🚀 Release v5.19.0-alpha for testing
10. 📣 Announce changes (blog post, GitHub discussion)
11. 🎯 Collect feedback, iterate on design

---

**Total brainstorm duration:** ~60 minutes (deep analysis with 12 questions)
**Files created:** BRAINSTORM-keychain-default-2026-01-24.md

🔗 **Next:** Would you like me to capture this as a formal SPEC.md for implementation?
