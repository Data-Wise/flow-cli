# Implementation Plan: Keychain-Default Storage (v5.19.0)

**Date:** 2026-01-24
**Goal:** Make Apple Keychain the default storage backend with optional Bitwarden sync
**Scope:** Architecture change + user experience improvements
**Source:** Comprehensive brainstorm with 12 user decisions
**Estimated Effort:** 18 hours (3 phases)

---

## Executive Summary

Transform flow-cli token storage from dual-storage-always to Keychain-first with optional Bitwarden backup. This plan reflects user decisions from interactive brainstorming.

**Key Changes:**
1. ✅ Default: Keychain-only (silent, no prompt)
2. ✅ Opt-in: `--sync-bitwarden` flag for cloud backup
3. ✅ Migration: Existing tokens become Keychain-authoritative (on upgrade)
4. ✅ Visibility: Color-coded `dot secret list`
5. ✅ Sync management: `dot secret sync enable/disable`
6. ✅ Conflict resolution: Interactive `dot secret reconcile`

---

## User Decisions (Brainstorm Answers)

| Question | User's Choice |
|----------|--------------|
| **Existing tokens** | Keep dual, make Keychain authoritative (immediately on upgrade) |
| **Sync trigger** | One-time choice per token (silent Keychain-only default) |
| **Updates** | Always ask again about Bitwarden sync |
| **Visibility** | Enhanced list with color-coded indicators |
| **Add UX** | Silent default (--sync-bitwarden flag to opt-in) |
| **Authority** | Immediately on upgrade (mark all as Keychain-authoritative) |
| **Conflicts** | Show diff and ask user to choose |
| **Conversion** | `dot secret sync enable/disable <name>` |
| **Rotation** | Always prompt during rotation |
| **List format** | Color-coded (blue=Keychain, green=synced, yellow=conflict) |
| **Bulk ops** | `dot secret sync enable --all` |
| **Bitwarden unavailable** | Warn but continue (no blocking) |

---

## Phase 1: Core Changes (6 hours)

### 1.1 Metadata Schema v2.2 (1 hour)

**Add new fields to token metadata:**

```json
{
  "dot_version": "2.2",
  "type": "github",
  "token_type": "classic",
  "sync_bitwarden": false,        // NEW: Sync preference (default: false)
  "keychain_authoritative": true, // NEW: Keychain is source of truth
  "created": "2026-01-24T14:30:00Z",
  "updated": "2026-01-24T15:00:00Z",  // NEW: Last update timestamp
  "expires_days": 90,
  "expires": "2026-04-24",
  "github_user": "username"
}
```

**Files to modify:**
- `lib/dispatchers/dot-dispatcher.zsh:2100-2200` (metadata generation)

**Implementation:**
```zsh
# In _dot_token_github() around line 2100
local metadata=$(cat << EOF
{
  "dot_version": "2.2",
  "type": "github",
  "token_type": "$token_type",
  "sync_bitwarden": ${sync_bitwarden:-false},
  "keychain_authoritative": true,
  "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "updated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "expires_days": 90,
  "expires": "$(date -d '+90 days' +%Y-%m-%d)",
  "github_user": "$username"
}
EOF
)
```

---

### 1.2 Default to Keychain-Only (2 hours)

**Modify `_dot_token_github()` to skip Bitwarden unless flag is set:**

**Current behavior (lines 2150-2163):**
```zsh
# ALWAYS stores in Bitwarden
echo "$new_item" | bw encode | bw create item --session "$BW_SESSION"
bw sync --session "$BW_SESSION"

# ALSO stores in Keychain
security add-generic-password -a "$token_name" -s flow-cli -w "$token_value" -j "$metadata" -U
```

**New behavior:**
```zsh
# ALWAYS store in Keychain
security add-generic-password \
  -a "$token_name" \
  -s "$_DOT_KEYCHAIN_SERVICE" \
  -w "$token_value" \
  -j "$metadata" \
  -U 2>/dev/null

# CONDITIONALLY store in Bitwarden (if --sync-bitwarden flag)
local sync_bitwarden=false

# Check for flag
if [[ "$@" == *"--sync-bitwarden"* ]]; then
  sync_bitwarden=true

  _flow_log_info "Syncing to Bitwarden..."

  # Store in Bitwarden
  local new_item=$(cat << EOF
{
  "organizationId": null,
  "folderId": null,
  "type": 1,
  "name": "$token_name",
  "notes": "$metadata",
  "favorite": false,
  "login": {
    "username": "$username",
    "password": "$token_value",
    "totp": null
  }
}
EOF
  )
  echo "$new_item" | bw encode | bw create item --session "$BW_SESSION" 2>/dev/null
  bw sync --session "$BW_SESSION" 2>/dev/null

  if [[ $? -eq 0 ]]; then
    _flow_log_success "Synced to Bitwarden"
  else
    _flow_log_warning "Bitwarden sync failed (but token stored in Keychain)"
  fi
else
  _flow_log_info "Stored in Keychain only (use --sync-bitwarden for cloud backup)"
fi
```

**Files to modify:**
- `lib/dispatchers/dot-dispatcher.zsh:2150-2180` (_dot_token_github)
- `lib/dispatchers/dot-dispatcher.zsh` (_dot_token_npm, _dot_token_pypi) - similar changes

---

### 1.3 Enhanced List Command (1 hour)

**Add color-coded sync status to `dot secret list`:**

**Current output:**
```
dot secret list
github-token
npm-token
pypi-token
```

**New output:**
```
dot secret list

🔵 github-token          Keychain only
🟢 npm-token             Synced to Bitwarden
🟡 pypi-token            ⚠ Conflict detected
```

**Implementation:**

Create new helper function in `lib/keychain-helpers.zsh`:

```zsh
# NEW: Check sync status (Keychain vs Bitwarden)
_dot_check_sync_status() {
  local name=$1

  # Get Keychain metadata
  local kc_metadata=$(security find-generic-password \
    -a "$name" \
    -s "$_DOT_KEYCHAIN_SERVICE" \
    -g 2>&1 | grep "note:" | sed 's/note: //')

  if [[ -z "$kc_metadata" ]]; then
    echo "missing"
    return
  fi

  # Check if sync enabled
  local sync_enabled=$(echo "$kc_metadata" | jq -r '.sync_bitwarden // false')

  if [[ "$sync_enabled" != "true" ]]; then
    echo "keychain-only"
    return
  fi

  # Check if Bitwarden copy exists (requires bw CLI)
  if ! command -v bw &>/dev/null; then
    echo "synced"  # Assume synced if bw not available
    return
  fi

  # Get Bitwarden copy (if logged in)
  local bw_value=$(bw get password "$name" --session $BW_SESSION 2>/dev/null)

  if [[ -z "$bw_value" ]]; then
    echo "keychain-only"  # Bitwarden copy missing
    return
  fi

  # Compare values
  local kc_value=$(security find-generic-password -a "$name" -s "$_DOT_KEYCHAIN_SERVICE" -w 2>/dev/null)

  if [[ "$kc_value" == "$bw_value" ]]; then
    echo "synced"
  else
    echo "conflict"
  fi
}
```

**Update `_dot_kc_list()` in `lib/keychain-helpers.zsh:183-200`:**

```zsh
_dot_kc_list() {
  # Get all Keychain entries for flow-cli
  local secrets=$(security dump-keychain 2>/dev/null | grep -A 10 "$_DOT_KEYCHAIN_SERVICE" | grep "0x00000007" | cut -d'"' -f 4 | sort | uniq)

  if [[ -z "$secrets" ]]; then
    echo ""
    echo "${FLOW_COLORS[muted]}No secrets found in Keychain${FLOW_COLORS[reset]}"
    echo ""
    return
  fi

  echo ""
  while IFS= read -r name; do
    local status=$(_dot_check_sync_status "$name")

    case "$status" in
      keychain-only)
        echo "${FLOW_COLORS[info]}🔵 $name${FLOW_COLORS[reset]}          Keychain only"
        ;;
      synced)
        echo "${FLOW_COLORS[success]}🟢 $name${FLOW_COLORS[reset]}             Synced to Bitwarden"
        ;;
      conflict)
        echo "${FLOW_COLORS[warning]}🟡 $name${FLOW_COLORS[reset]}             ⚠ Conflict detected"
        ;;
      missing)
        echo "${FLOW_COLORS[error]}🔴 $name${FLOW_COLORS[reset]}             ❌ Missing in Keychain"
        ;;
    esac
  done <<< "$secrets"
  echo ""
}
```

**Files to modify:**
- `lib/keychain-helpers.zsh:183-200` (_dot_kc_list)
- `lib/keychain-helpers.zsh` (add _dot_check_sync_status helper)

---

### 1.4 Migration Script (2 hours)

**Auto-detect v5.18.0 → v5.19.0 upgrade and migrate tokens:**

Create new file: `lib/migration-v5.19.0.zsh`

```zsh
#!/usr/bin/env zsh
# Migration: v5.18.0 → v5.19.0 (Keychain-authoritative)

_dot_migrate_v5_19_0() {
  local migration_flag="$HOME/.flow/.migrated-v5.19.0"

  # Check if already migrated
  if [[ -f "$migration_flag" ]]; then
    return 0
  fi

  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🔄 Migrating to v5.19.0${FLOW_COLORS[reset]}                            ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""

  local migrated=0
  local skipped=0
  local errors=0

  # Get all Keychain tokens
  local secrets=$(security dump-keychain 2>/dev/null | grep -A 10 "$_DOT_KEYCHAIN_SERVICE" | grep "0x00000007" | cut -d'"' -f 4 | sort | uniq)

  while IFS= read -r name; do
    [[ -z "$name" ]] && continue

    # Get current metadata
    local metadata=$(security find-generic-password \
      -a "$name" \
      -s "$_DOT_KEYCHAIN_SERVICE" \
      -g 2>&1 | grep "note:" | sed 's/note: //')

    # Check if already migrated (has keychain_authoritative field)
    if echo "$metadata" | jq -e '.keychain_authoritative' >/dev/null 2>&1; then
      ((skipped++))
      continue
    fi

    # Get token value
    local token_value=$(security find-generic-password -a "$name" -s "$_DOT_KEYCHAIN_SERVICE" -w 2>/dev/null)

    if [[ -z "$token_value" ]]; then
      ((errors++))
      continue
    fi

    # Update metadata with new fields
    local new_metadata=$(echo "$metadata" | jq -c '. + {
      "keychain_authoritative": true,
      "sync_bitwarden": true,
      "migrated": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
    }')

    # Update Keychain entry
    security delete-generic-password -a "$name" -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null
    security add-generic-password \
      -a "$name" \
      -s "$_DOT_KEYCHAIN_SERVICE" \
      -w "$token_value" \
      -j "$new_metadata" \
      -U 2>/dev/null

    if [[ $? -eq 0 ]]; then
      ((migrated++))
    else
      ((errors++))
    fi

  done <<< "$secrets"

  # Save migration flag
  mkdir -p "$(dirname "$migration_flag")"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$migration_flag"

  echo ""
  echo "${FLOW_COLORS[success]}✅ Migration complete:${FLOW_COLORS[reset]}"
  echo "   Migrated: $migrated tokens"
  echo "   Skipped: $skipped tokens (already migrated)"
  [[ $errors -gt 0 ]] && echo "   ${FLOW_COLORS[error]}Errors: $errors tokens${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[info]}What changed:${FLOW_COLORS[reset]}"
  echo "   • Existing tokens marked as Keychain-authoritative"
  echo "   • Both Keychain and Bitwarden copies preserved"
  echo "   • New tokens default to Keychain-only"
  echo ""
  echo "${FLOW_COLORS[muted]}Learn more: docs/guides/MIGRATION-V5.19.0-GUIDE.md${FLOW_COLORS[reset]}"
  echo ""
}
```

**Trigger migration on first `dot secret list` or `dot token` command:**

In `lib/dispatchers/dot-dispatcher.zsh`, add at top of `_dot_secret()`:

```zsh
_dot_secret() {
  # Auto-migrate on first use (v5.18.0 → v5.19.0)
  if [[ -f "${0:A:h}/../lib/migration-v5.19.0.zsh" ]]; then
    source "${0:A:h}/../lib/migration-v5.19.0.zsh"
    _dot_migrate_v5_19_0
  fi

  # ... rest of function
}
```

**Files to create:**
- `lib/migration-v5.19.0.zsh` (new file)

**Files to modify:**
- `lib/dispatchers/dot-dispatcher.zsh:1107` (_dot_secret function start)
- `flow.plugin.zsh` (source migration script)

---

## Phase 2: Sync Management (8 hours)

### 2.1 Sync Enable Command (2 hours)

**Create:** `lib/sync-manager.zsh`

```zsh
#!/usr/bin/env zsh
# Sync management for tokens (enable/disable Bitwarden sync)

_dot_secret_sync_enable() {
  local name=$1

  # Bulk enable
  if [[ "$name" == "--all" ]]; then
    local tokens=($(_dot_list_keychain_only_tokens))
    echo "Enable Bitwarden sync for ${#tokens[@]} tokens?"
    read -q "?Continue? [y/N] "
    echo ""
    [[ $? -ne 0 ]] && return 1

    for token in "${tokens[@]}"; do
      _dot_sync_single_token "$token"
    done
    return 0
  fi

  # Single token
  _dot_sync_single_token "$name"
}

_dot_sync_single_token() {
  local name=$1

  # Get current token value and metadata
  local token_value=$(security find-generic-password -a "$name" -s "$_DOT_KEYCHAIN_SERVICE" -w 2>/dev/null)
  local metadata=$(security find-generic-password -a "$name" -s "$_DOT_KEYCHAIN_SERVICE" -g 2>&1 | grep "note:" | sed 's/note: //')

  if [[ -z "$token_value" || -z "$metadata" ]]; then
    _flow_log_error "Token not found: $name"
    return 1
  fi

  # Check if already synced
  local already_synced=$(echo "$metadata" | jq -r '.sync_bitwarden // false')
  if [[ "$already_synced" == "true" ]]; then
    _flow_log_warning "Already synced to Bitwarden: $name"
    return 0
  fi

  # Update metadata
  local new_metadata=$(echo "$metadata" | jq -c '. + {
    "sync_bitwarden": true,
    "updated": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
  }')

  # Upload to Bitwarden
  local username=$(echo "$metadata" | jq -r '.github_user // "user"')
  local new_item=$(cat << EOF
{
  "organizationId": null,
  "folderId": null,
  "type": 1,
  "name": "$name",
  "notes": "$new_metadata",
  "favorite": false,
  "login": {
    "username": "$username",
    "password": "$token_value",
    "totp": null
  }
}
EOF
  )

  echo "$new_item" | bw encode | bw create item --session "$BW_SESSION" 2>/dev/null
  bw sync --session "$BW_SESSION" 2>/dev/null

  if [[ $? -ne 0 ]]; then
    _flow_log_warning "Bitwarden upload failed (but metadata updated)"
  fi

  # Update Keychain metadata
  security delete-generic-password -a "$name" -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null
  security add-generic-password \
    -a "$name" \
    -s "$_DOT_KEYCHAIN_SERVICE" \
    -w "$token_value" \
    -j "$new_metadata" \
    -U 2>/dev/null

  _flow_log_success "Enabled Bitwarden sync for: $name"
}

_dot_list_keychain_only_tokens() {
  local secrets=$(security dump-keychain 2>/dev/null | grep -A 10 "$_DOT_KEYCHAIN_SERVICE" | grep "0x00000007" | cut -d'"' -f 4 | sort | uniq)

  while IFS= read -r name; do
    [[ -z "$name" ]] && continue
    local status=$(_dot_check_sync_status "$name")
    [[ "$status" == "keychain-only" ]] && echo "$name"
  done <<< "$secrets"
}
```

**Add to dispatcher:**

In `lib/dispatchers/dot-dispatcher.zsh`, add new case to `_dot_secret()`:

```zsh
_dot_secret() {
  # ... existing cases ...

  sync)
    shift
    source "${0:A:h}/../lib/sync-manager.zsh"
    case "$1" in
      enable)
        shift
        _dot_secret_sync_enable "$@"
        ;;
      disable)
        shift
        _dot_secret_sync_disable "$@"
        ;;
      status)
        _dot_secret_sync_status
        ;;
      *)
        echo "Usage: dot secret sync enable|disable|status [name]"
        return 1
        ;;
    esac
    return
    ;;
```

**Files to create:**
- `lib/sync-manager.zsh` (new file)

**Files to modify:**
- `lib/dispatchers/dot-dispatcher.zsh` (add `sync` case)

---

### 2.2 Sync Disable Command (1 hour)

**Add to `lib/sync-manager.zsh`:**

```zsh
_dot_secret_sync_disable() {
  local name=$1

  # Get current metadata
  local metadata=$(security find-generic-password -a "$name" -s "$_DOT_KEYCHAIN_SERVICE" -g 2>&1 | grep "note:" | sed 's/note: //')

  # Update metadata (disable sync, but don't delete Bitwarden copy)
  local new_metadata=$(echo "$metadata" | jq -c '. + {
    "sync_bitwarden": false,
    "updated": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
  }')

  # Update Keychain
  local token_value=$(security find-generic-password -a "$name" -s "$_DOT_KEYCHAIN_SERVICE" -w 2>/dev/null)

  security delete-generic-password -a "$name" -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null
  security add-generic-password \
    -a "$name" \
    -s "$_DOT_KEYCHAIN_SERVICE" \
    -w "$token_value" \
    -j "$new_metadata" \
    -U 2>/dev/null

  _flow_log_success "Disabled Bitwarden sync for: $name"
  _flow_log_info "Bitwarden copy preserved (not deleted)"
}
```

---

### 2.3 Sync Status Command (1 hour)

**Add to `lib/sync-manager.zsh`:**

```zsh
_dot_secret_sync_status() {
  local secrets=$(security dump-keychain 2>/dev/null | grep -A 10 "$_DOT_KEYCHAIN_SERVICE" | grep "0x00000007" | cut -d'"' -f 4 | sort | uniq)

  local synced=0
  local keychain_only=0
  local conflicts=0

  local synced_list=()
  local keychain_only_list=()
  local conflict_list=()

  while IFS= read -r name; do
    [[ -z "$name" ]] && continue

    local status=$(_dot_check_sync_status "$name")

    case "$status" in
      synced)
        ((synced++))
        synced_list+=("$name")
        ;;
      keychain-only)
        ((keychain_only++))
        keychain_only_list+=("$name")
        ;;
      conflict)
        ((conflicts++))
        conflict_list+=("$name")
        ;;
    esac
  done <<< "$secrets"

  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Sync Status Summary${FLOW_COLORS[reset]}                                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""

  if [[ $synced -gt 0 ]]; then
    echo "${FLOW_COLORS[success]}🟢 Synced ($synced tokens):${FLOW_COLORS[reset]}"
    for token in "${synced_list[@]}"; do
      echo "   $token"
    done
    echo ""
  fi

  if [[ $keychain_only -gt 0 ]]; then
    echo "${FLOW_COLORS[info]}🔵 Keychain-only ($keychain_only tokens):${FLOW_COLORS[reset]}"
    for token in "${keychain_only_list[@]}"; do
      echo "   $token"
    done
    echo ""
  fi

  if [[ $conflicts -gt 0 ]]; then
    echo "${FLOW_COLORS[warning]}🟡 Conflicts ($conflicts tokens):${FLOW_COLORS[reset]}"
    for token in "${conflict_list[@]}"; do
      echo "   $token"
    done
    echo ""
    echo "${FLOW_COLORS[muted]}Run 'dot secret reconcile <name>' to resolve conflicts${FLOW_COLORS[reset]}"
    echo ""
  fi
}
```

---

### 2.4 Conflict Resolution (4 hours)

**Create:** `commands/secret-reconcile.zsh`

```zsh
#!/usr/bin/env zsh
# Interactive conflict resolution for Keychain vs Bitwarden

_dot_secret_reconcile() {
  local name=$1

  if [[ -z "$name" ]]; then
    _flow_log_error "Usage: dot secret reconcile <name>"
    return 1
  fi

  # Get both copies
  local kc_value=$(security find-generic-password -a "$name" -s "$_DOT_KEYCHAIN_SERVICE" -w 2>/dev/null)
  local kc_metadata=$(security find-generic-password -a "$name" -s "$_DOT_KEYCHAIN_SERVICE" -g 2>&1 | grep "note:" | sed 's/note: //')

  local bw_value=$(bw get password "$name" --session $BW_SESSION 2>/dev/null)
  local bw_notes=$(bw get notes "$name" --session $BW_SESSION 2>/dev/null)

  # Parse timestamps
  local kc_updated=$(echo "$kc_metadata" | jq -r '.updated // .created')
  local bw_updated=$(echo "$bw_notes" | jq -r '.updated // .created')

  # Show conflict UI
  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[warning]}⚠️  Conflict Detected${FLOW_COLORS[reset]}                             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Token: $name$(printf '%*s' $((44 - ${#name})) '')${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Keychain:                                        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    Value: ${kc_value:0:10}****${kc_value:(-4)} (${#kc_value} chars)$(printf '%*s' $((13 - ${#kc_value})) '')${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    Updated: $kc_updated$(printf '%*s' $((33 - ${#kc_updated})) '')${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Bitwarden:                                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    Value: ${bw_value:0:10}****${bw_value:(-4)} (${#bw_value} chars)$(printf '%*s' $((13 - ${#bw_value})) '')${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    Updated: $bw_updated$(printf '%*s' $((33 - ${#bw_updated})) '')${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  These values are DIFFERENT!                      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""

  # Get user choice
  echo "Choose resolution:"
  echo "  1. Use Keychain (newer)"
  echo "  2. Use Bitwarden (older)"
  echo "  3. Show full diff"
  echo "  4. Delete both and re-add"
  echo ""

  local choice
  read "choice?Choice [1-4]: "

  case "$choice" in
    1)
      # Use Keychain (overwrite Bitwarden)
      local bw_item_id=$(bw get item "$name" --session $BW_SESSION | jq -r '.id')

      # Update Bitwarden item
      local updated_item=$(cat << EOF
{
  "id": "$bw_item_id",
  "organizationId": null,
  "folderId": null,
  "type": 1,
  "name": "$name",
  "notes": "$kc_metadata",
  "favorite": false,
  "login": {
    "username": "$(echo "$kc_metadata" | jq -r '.github_user // "user"')",
    "password": "$kc_value",
    "totp": null
  }
}
EOF
      )

      echo "$updated_item" | bw encode | bw edit item "$bw_item_id" --session "$BW_SESSION" >/dev/null
      bw sync --session "$BW_SESSION" >/dev/null

      _flow_log_success "Resolved: Using Keychain value (synced to Bitwarden)"
      ;;

    2)
      # Use Bitwarden (overwrite Keychain)
      local bw_metadata=$(echo "$bw_notes" | jq -c)

      security delete-generic-password -a "$name" -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null
      security add-generic-password \
        -a "$name" \
        -s "$_DOT_KEYCHAIN_SERVICE" \
        -w "$bw_value" \
        -j "$bw_metadata" \
        -U 2>/dev/null

      _flow_log_success "Resolved: Using Bitwarden value (synced to Keychain)"
      ;;

    3)
      # Show full diff
      echo ""
      echo "${FLOW_COLORS[section]}Keychain value:${FLOW_COLORS[reset]}"
      echo "$kc_value"
      echo ""
      echo "${FLOW_COLORS[section]}Bitwarden value:${FLOW_COLORS[reset]}"
      echo "$bw_value"
      echo ""
      # Re-prompt
      _dot_secret_reconcile "$name"
      ;;

    4)
      # Delete both
      security delete-generic-password -a "$name" -s "$_DOT_KEYCHAIN_SERVICE" 2>/dev/null
      bw delete item "$name" --session "$BW_SESSION" 2>/dev/null
      bw sync --session "$BW_SESSION" >/dev/null
      _flow_log_success "Deleted both copies. Run 'dot token <provider>' to re-add."
      ;;

    *)
      _flow_log_error "Invalid choice. Aborted."
      return 1
      ;;
  esac
}
```

**Add to dispatcher:**

In `lib/dispatchers/dot-dispatcher.zsh`:

```zsh
_dot_secret() {
  # ... existing cases ...

  reconcile)
    shift
    source "${0:A:h}/../../commands/secret-reconcile.zsh"
    _dot_secret_reconcile "$@"
    return
    ;;
```

**Files to create:**
- `commands/secret-reconcile.zsh` (new file)

**Files to modify:**
- `lib/dispatchers/dot-dispatcher.zsh` (add `reconcile` case)

---

## Phase 3: Polish & Release (4 hours)

### 3.1 Updated Token Rotation (2 hours)

**Modify `_dot_token_rotate()` to always ask about Bitwarden sync:**

In `lib/dispatchers/dot-dispatcher.zsh` (token rotation function):

```zsh
_dot_token_rotate() {
  # ... existing rotation logic (select token, create backup, get new token) ...

  # NEW: After getting new token, check sync preference
  local old_metadata=$(get_metadata "$token_name-backup")
  local was_synced=$(echo "$old_metadata" | jq -r '.sync_bitwarden // false')

  echo ""
  echo "${FLOW_COLORS[section]}Bitwarden Sync${FLOW_COLORS[reset]}"
  echo ""

  if [[ "$was_synced" == "true" ]]; then
    echo "Old token was synced to Bitwarden."
    echo ""
    read -q "?Sync new token to Bitwarden? [Y/n] " sync_choice
    echo ""

    local sync_new=true
    if [[ "$sync_choice" == "n" || "$sync_choice" == "N" ]]; then
      sync_new=false
      _flow_log_info "New token will be Keychain-only"
    else
      _flow_log_info "New token will sync to Bitwarden"
    fi
  else
    # Old token was Keychain-only
    read -q "?Sync new token to Bitwarden? [y/N] " sync_choice
    echo ""

    local sync_new=false
    if [[ "$sync_choice" == "y" || "$sync_choice" == "Y" ]]; then
      sync_new=true
      _flow_log_info "New token will sync to Bitwarden"
    else
      _flow_log_info "New token will be Keychain-only"
    fi
  fi

  # Create new metadata with sync preference
  local new_metadata=$(create_metadata "$token_type" "$sync_new")

  # Store in Keychain (always)
  update_keychain "$token_name" "$new_token_value" "$new_metadata"

  # Store in Bitwarden (if enabled)
  if [[ "$sync_new" == "true" ]]; then
    bw_add_or_update "$token_name" "$new_token_value" "$new_metadata"
  fi

  _flow_log_success "Token rotated successfully"
}
```

**Files to modify:**
- `lib/dispatchers/dot-dispatcher.zsh` (_dot_token_rotate function)

---

### 3.2 Help Text Updates (1 hour)

**Update `_dot_kc_help()` in `lib/keychain-helpers.zsh:356-385`:**

```zsh
_dot_kc_help() {
    cat <<EOF
${FLOW_COLORS[header]}dot secret${FLOW_COLORS[reset]} - macOS Keychain secret management

${FLOW_COLORS[warning]}Commands:${FLOW_COLORS[reset]}
  dot secret add <name>      Store a secret (prompts for value)
  dot secret get <name>      Retrieve a secret (or just: dot secret <name>)
  dot secret <name>          Shortcut for 'get'
  dot secret list            List all stored secrets (color-coded)
  dot secret delete <name>   Remove a secret
  dot secret import          Import from Bitwarden (one-time)
  dot secret tutorial        Interactive tutorial (10-15 min)

${FLOW_COLORS[warning]}Sync Management (v5.19.0+):${FLOW_COLORS[reset]}
  dot secret sync enable <name>   Enable Bitwarden sync for token
  dot secret sync disable <name>  Disable Bitwarden sync
  dot secret sync enable --all    Bulk enable sync for all tokens
  dot secret sync status          Show sync status summary
  dot secret reconcile <name>     Resolve Keychain/Bitwarden conflict

${FLOW_COLORS[warning]}Examples:${FLOW_COLORS[reset]}
  dot secret add github-token           # Store GitHub token (Keychain-only)
  dot token github --sync-bitwarden     # Store with Bitwarden backup
  dot secret list                       # See all secrets (color-coded)
  dot secret sync enable github-token   # Enable sync later

${FLOW_COLORS[warning]}Usage in scripts:${FLOW_COLORS[reset]}
  export GITHUB_TOKEN=\$(dot secret github-token)
  gh auth login --with-token <<< \$(dot secret github-token)

${FLOW_COLORS[warning]}Benefits:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[success]}•${FLOW_COLORS[reset]} Instant access (Keychain < 50ms)
  ${FLOW_COLORS[success]}•${FLOW_COLORS[reset]} Touch ID / Apple Watch support
  ${FLOW_COLORS[success]}•${FLOW_COLORS[reset]} Auto-locks with screen lock
  ${FLOW_COLORS[success]}•${FLOW_COLORS[reset]} Optional Bitwarden cloud backup

${FLOW_COLORS[muted]}Secrets stored in: macOS Keychain (service: $_DOT_KEYCHAIN_SERVICE)${FLOW_COLORS[reset]}
EOF
}
```

---

### 3.3 Documentation (1 hour)

**Create migration guide:** `docs/guides/MIGRATION-V5.19.0-GUIDE.md`

**Update existing docs:**
- `docs/reference/REFCARD-TOKEN-SECRETS.md` - Add sync commands
- `docs/guides/TOKEN-MANAGEMENT-COMPLETE.md` - Add sync management section
- `CHANGELOG.md` - Add v5.19.0 entry

---

## Critical Files Summary

| File | Type | Changes |
|------|------|---------|
| `lib/dispatchers/dot-dispatcher.zsh` | Modify | Metadata v2.2, default Keychain-only, sync case, reconcile case |
| `lib/keychain-helpers.zsh` | Modify | Enhanced list, check_sync_status helper, updated help |
| `lib/migration-v5.19.0.zsh` | New | Auto-migration on upgrade |
| `lib/sync-manager.zsh` | New | Sync enable/disable/status commands |
| `commands/secret-reconcile.zsh` | New | Interactive conflict resolution |
| `docs/guides/MIGRATION-V5.19.0-GUIDE.md` | New | Migration guide for users |

---

## Verification Plan

### 1. Unit Tests

Create `tests/test-keychain-default.zsh`:

```bash
# Test metadata v2.2 fields
# Test Keychain-only storage (no Bitwarden)
# Test --sync-bitwarden flag
# Test migration logic
# Test sync enable/disable
# Test conflict detection
```

### 2. Integration Tests

Create `tests/e2e-keychain-default.zsh`:

```bash
# Fresh install: Add token without flag → verify Keychain-only
# Fresh install: Add token with --sync-bitwarden → verify both backends
# Upgrade from v5.18.0: Verify migration message, check metadata
# Enable sync later: dot secret sync enable → verify Bitwarden copy created
# Conflict resolution: Manually create mismatch, run reconcile
```

### 3. Manual Testing Scenarios

1. **Fresh install (v5.19.0):**
   - Install v5.19.0
   - Run `dot token github` (no flag)
   - Verify Keychain-only storage
   - Run `dot secret list` → see blue indicator
   - Run `dot secret sync enable github-token`
   - Verify Bitwarden copy created
   - Run `dot secret list` → see green indicator

2. **Upgrade from v5.18.0:**
   - Have existing dual-storage tokens
   - Upgrade to v5.19.0
   - Run `dot secret list`
   - See migration message
   - Check metadata has `keychain_authoritative: true`
   - Verify both copies still exist

3. **Rotation with sync choice:**
   - Have synced token
   - Run `dot token rotate`
   - See prompt "Sync new token to Bitwarden? [Y/n]"
   - Choose Y → verify both backends updated
   - Repeat with N → verify only Keychain updated

4. **Conflict resolution:**
   - Create token with sync enabled
   - Manually update Bitwarden copy (via web UI)
   - Run `dot secret list` → see yellow conflict indicator
   - Run `dot secret reconcile <name>`
   - See diff UI
   - Choose option 1 (Use Keychain)
   - Verify Bitwarden overwritten
   - Run `dot secret list` → see green synced indicator

---

## Rollback Plan

If critical issues arise:

```bash
# Revert to v5.18.0
git checkout v5.18.0
source flow.plugin.zsh

# Or Homebrew
brew uninstall flow-cli
brew install flow-cli@5.18.0
```

**Data safety:**
- Migration NEVER deletes data
- Both Keychain and Bitwarden copies preserved
- Metadata updates are additive

---

## Success Criteria

- [ ] Default `dot token github` stores in Keychain-only
- [ ] `--sync-bitwarden` flag enables dual storage
- [ ] Migration runs automatically on first use (v5.18→v5.19)
- [ ] `dot secret list` shows color-coded sync status
- [ ] `dot secret sync enable <name>` works
- [ ] `dot secret sync disable <name>` works
- [ ] `dot secret sync enable --all` works
- [ ] `dot secret sync status` shows summary
- [ ] `dot secret reconcile <name>` resolves conflicts
- [ ] Token rotation prompts for sync preference
- [ ] All existing tests pass
- [ ] New tests pass (unit + E2E)
- [ ] Documentation complete (migration guide, updated refs)

---

## Timeline

**Phase 1:** 6 hours (core changes)
**Phase 2:** 8 hours (sync management)
**Phase 3:** 4 hours (polish & release)

**Total:** 18 hours (3 days @ 6 hours/day)

---

**Ready to implement!** 🚀
