#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# SEC - Secret Management Dispatcher
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         lib/dispatchers/sec-dispatcher.zsh
# Version:      3.0.0
# Date:         2026-02-14
# Pattern:      command + keyword + options
#
# Usage:        sec <action> [args]
#
# Examples:
#   sec                   # Help overview
#   sec list              # List Keychain secrets
#   sec <name>            # Get secret by name
#   sec add <name>        # Add secret to Keychain
#   sec delete <name>     # Delete from Keychain
#   sec check             # Check expiring secrets (Bitwarden)
#   sec status            # Show backend configuration
#   sec unlock            # Unlock Bitwarden vault
#   sec lock              # Lock Bitwarden vault
#   sec sync              # Sync between Keychain and Bitwarden
#   sec bw <name>         # Get secret from Bitwarden
#   sec dashboard         # Secrets dashboard
#   sec doctor            # Secret-specific diagnostics
#
# ══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════
# SEC - Main Dispatcher
# ═══════════════════════════════════════════════════════════════════

sec() {
  if [[ $# -eq 0 ]]; then
    _sec_help
    return
  fi

  case "$1" in
    # Named subcommands
    list|ls)   shift; _sec_list "$@" ;;
    add|new)   shift; _sec_add "$@" ;;
    delete|rm|remove) shift; _sec_delete "$@" ;;
    get)       shift; _sec_get "$@" ;;
    check)     shift; _sec_check "$@" ;;
    status)    shift; _sec_status "$@" ;;
    unlock|u)  shift; _sec_unlock "$@" ;;
    lock|l)    shift; _sec_lock "$@" ;;
    sync)      shift; _sec_sync "$@" ;;
    bw)        shift; _sec_bw "$@" ;;
    import)    shift; _dotf_kc_import "$@" ;;
    tutorial)  shift; _sec_tutorial "$@" ;;
    dashboard) shift; _sec_dashboard "$@" ;;
    doctor|dr) shift; _sec_doctor "$@" ;;
    help|--help|-h) _sec_help ;;
    # Default: treat first arg as secret name lookup
    *)         _sec_get "$@" ;;
  esac
}

# ═══════════════════════════════════════════════════════════════════
# HELP
# ═══════════════════════════════════════════════════════════════════

_sec_help() {
  local _C_NC='\033[0m' _C_BOLD='\033[1m' _C_DIM='\033[2m'
  local _C_GREEN='\033[32m' _C_YELLOW='\033[33m' _C_BLUE='\033[34m'
  local _C_MAGENTA='\033[35m' _C_CYAN='\033[36m'

  if [[ -n "$NO_COLOR" ]]; then
      _C_NC='' _C_BOLD='' _C_DIM=''
      _C_GREEN='' _C_YELLOW='' _C_BLUE=''
      _C_MAGENTA='' _C_CYAN=''
  fi

  echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ sec - Secret Management                      │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}sec <name>${_C_NC}          Get secret value
  ${_C_CYAN}sec list${_C_NC}            List all secrets
  ${_C_CYAN}sec add <name>${_C_NC}      Store new secret
  ${_C_CYAN}sec unlock${_C_NC}          Unlock Bitwarden vault

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} sec GITHUB_TOKEN         ${_C_DIM}# Get token value${_C_NC}
  ${_C_DIM}\$${_C_NC} sec add DEPLOY_KEY       ${_C_DIM}# Store new secret${_C_NC}
  ${_C_DIM}\$${_C_NC} sec unlock && sec list   ${_C_DIM}# Unlock vault, list secrets${_C_NC}

${_C_BLUE}📋 KEYCHAIN${_C_NC} ${_C_DIM}(instant, local, Touch ID)${_C_NC}:
  ${_C_CYAN}sec <name>${_C_NC}          Get secret value
  ${_C_CYAN}sec list${_C_NC}            List all secrets
  ${_C_CYAN}sec add <name>${_C_NC}      Store new secret
  ${_C_CYAN}sec delete <name>${_C_NC}   Remove secret

${_C_BLUE}📋 BITWARDEN${_C_NC} ${_C_DIM}(cloud sync)${_C_NC}:
  ${_C_CYAN}sec unlock${_C_NC}          Unlock vault
  ${_C_CYAN}sec lock${_C_NC}            Lock vault
  ${_C_CYAN}sec bw <name>${_C_NC}       Get from Bitwarden
  ${_C_CYAN}sec check${_C_NC}           Check expirations
  ${_C_CYAN}sec sync${_C_NC}            Sync Keychain/BW

${_C_BLUE}📋 OVERVIEW${_C_NC}:
  ${_C_CYAN}sec status${_C_NC}          Backend configuration
  ${_C_CYAN}sec dashboard${_C_NC}       Full secrets overview
  ${_C_CYAN}sec doctor${_C_NC}          Secret diagnostics

${_C_MAGENTA}💡 TIP${_C_NC}: Use ${_C_CYAN}sec <name> | pbcopy${_C_NC} to copy a secret to clipboard

${_C_DIM}📚 See also:${_C_NC}
  ${_C_CYAN}dots${_C_NC} - Dotfile management
  ${_C_CYAN}tok${_C_NC} - Token lifecycle management
  ${_C_CYAN}flow doctor --dot${_C_NC} - Health check
"
}

# ═══════════════════════════════════════════════════════════════════
# UNLOCK - Unlock Bitwarden vault and set session
# ═══════════════════════════════════════════════════════════════════

_sec_unlock() {
  if ! _dotf_require_tool "bw" "brew install bitwarden-cli"; then
    return 1
  fi

  # Check current status
  local bw_status=$(_dotf_bw_get_status)

  case "$bw_status" in
    unlocked)
      _flow_log_success "Bitwarden vault is already unlocked"
      _flow_log_muted "BW_SESSION is active in this shell"
      return 0
      ;;
    locked)
      _flow_log_info "Unlocking Bitwarden vault..."
      ;;
    unauthenticated)
      _flow_log_error "Bitwarden not authenticated"
      _flow_log_info "Run: bw login"
      return 1
      ;;
    not-installed)
      _flow_log_error "Bitwarden CLI not found"
      _flow_log_info "Install: brew install bitwarden-cli"
      return 1
      ;;
    *)
      _flow_log_error "Unknown Bitwarden status: $bw_status"
      return 1
      ;;
  esac

  # Unlock and capture session token (separate stdout/stderr to avoid contamination)
  echo ""
  _flow_log_info "Enter your Bitwarden master password:"
  local session_token
  local temp_err=$(mktemp)
  session_token=$(bw unlock --raw 2>"$temp_err")
  local unlock_status=$?

  if [[ $unlock_status -ne 0 ]]; then
    _flow_log_error "Failed to unlock vault"
    # Show stderr if unlock failed (helpful for debugging)
    [[ -s "$temp_err" ]] && cat "$temp_err" >&2
    rm -f "$temp_err"
    return 1
  fi
  rm -f "$temp_err"

  # Validate session token format (should be a UUID-like string)
  if [[ -z "$session_token" ]] || [[ ${#session_token} -lt 20 ]]; then
    _flow_log_error "Invalid session token received"
    return 1
  fi

  # Export session token to current shell
  export BW_SESSION="$session_token"

  # Verify session works
  if bw unlock --check &>/dev/null; then
    # Save session cache (15-min idle timeout)
    _dotf_session_cache_save
    local timeout_min=$((DOT_SESSION_IDLE_TIMEOUT / 60))

    echo ""
    _flow_log_success "Vault unlocked successfully"
    echo ""
    _flow_log_muted "Session will auto-lock after ${timeout_min} min idle"
    _flow_log_info "Use 'sec <name>' to retrieve secrets"

    # Security reminder
    echo ""
    _flow_log_warning "Security reminder:"
    echo "  • Session expires after ${timeout_min} min of inactivity"
    echo "  • Don't export BW_SESSION globally"
    echo "  • Lock vault manually: ${FLOW_COLORS[cmd]}sec lock${FLOW_COLORS[reset]}"
    echo ""

    return 0
  else
    _flow_log_error "Session validation failed"
    unset BW_SESSION
    return 1
  fi
}

# ═══════════════════════════════════════════════════════════════════
# LOCK - Lock Bitwarden vault and clear session cache
# ═══════════════════════════════════════════════════════════════════

_sec_lock() {
  # Clear session cache first
  _dotf_session_cache_clear

  # Lock Bitwarden vault
  if command -v bw &>/dev/null; then
    bw lock &>/dev/null
  fi

  _flow_log_success "Vault locked"
  _flow_log_muted "Session cache cleared"
}

# ═══════════════════════════════════════════════════════════════════
# SECRET OPERATIONS (Keychain - instant, local, Touch ID)
# ═══════════════════════════════════════════════════════════════════

# Get secret by name (default action)
_sec_get() {
  _dotf_kc_get "$@"
}

# List Keychain secrets
_sec_list() {
  _dotf_kc_list
}

# Add secret to Keychain
_sec_add() {
  _dotf_kc_add "$@"
}

# Delete secret from Keychain
_sec_delete() {
  _dotf_kc_delete "$@"
}

# Tutorial
_sec_tutorial() {
  # Load and run interactive tutorial
  local tutorial_file="${FLOW_PLUGIN_DIR}/commands/secret-tutorial.zsh"
  if [[ -f "$tutorial_file" ]]; then
    source "$tutorial_file"
    _sec_tutorial "$@"
  else
    _flow_log_error "Tutorial not found: $tutorial_file"
    return 1
  fi
}

# ═══════════════════════════════════════════════════════════════════
# STATUS
# ═══════════════════════════════════════════════════════════════════

# =============================================================================
# Function: _sec_status
# Purpose: Show current secret backend configuration and status
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Formatted status display with backend info
#
# Example:
#   sec status
#   # Backend: keychain (default)
#   # Keychain: login.keychain-db
#   # Bitwarden: not configured
# =============================================================================
_sec_status() {
  local backend=$(_dotf_secret_backend)

  echo ""
  echo "${FLOW_COLORS[header]}Secret Backend Status${FLOW_COLORS[reset]}"
  echo ""

  # Show current backend
  case "$backend" in
    keychain)
      echo "${FLOW_COLORS[success]}●${FLOW_COLORS[reset]} Backend: ${FLOW_COLORS[bold]}keychain${FLOW_COLORS[reset]} (default)"
      echo ""
      echo "${FLOW_COLORS[info]}Keychain:${FLOW_COLORS[reset]}"
      echo "  • Status: ${FLOW_COLORS[success]}active${FLOW_COLORS[reset]}"
      echo "  • Location: $(security list-keychains 2>/dev/null | head -1 | tr -d ' \"')"

      # Count secrets
      local secret_count=$(_sec_count_keychain 2>/dev/null || echo "0")
      echo "  • Secrets: $secret_count"
      echo ""
      echo "${FLOW_COLORS[muted]}Bitwarden:${FLOW_COLORS[reset]}"
      echo "  • Status: ${FLOW_COLORS[muted]}not configured${FLOW_COLORS[reset]}"
      echo "  • Set FLOW_SECRET_BACKEND=both to enable sync"
      ;;

    bitwarden)
      echo "${FLOW_COLORS[warning]}●${FLOW_COLORS[reset]} Backend: ${FLOW_COLORS[bold]}bitwarden${FLOW_COLORS[reset]} (legacy mode)"
      echo ""
      echo "${FLOW_COLORS[muted]}Keychain:${FLOW_COLORS[reset]}"
      echo "  • Status: ${FLOW_COLORS[muted]}not used${FLOW_COLORS[reset]}"
      echo ""
      echo "${FLOW_COLORS[info]}Bitwarden:${FLOW_COLORS[reset]}"
      if [[ -n "$BW_SESSION" ]]; then
        echo "  • Status: ${FLOW_COLORS[success]}unlocked${FLOW_COLORS[reset]}"
      else
        echo "  • Status: ${FLOW_COLORS[warning]}locked${FLOW_COLORS[reset]} (run: sec unlock)"
      fi
      ;;

    both)
      echo "${FLOW_COLORS[info]}●${FLOW_COLORS[reset]} Backend: ${FLOW_COLORS[bold]}both${FLOW_COLORS[reset]} (sync mode)"
      echo ""
      echo "${FLOW_COLORS[info]}Keychain:${FLOW_COLORS[reset]}"
      echo "  • Status: ${FLOW_COLORS[success]}active${FLOW_COLORS[reset]} (primary)"
      echo "  • Location: $(security list-keychains 2>/dev/null | head -1 | tr -d ' \"')"
      local kc_count=$(_sec_count_keychain 2>/dev/null || echo "0")
      echo "  • Secrets: $kc_count"
      echo ""
      echo "${FLOW_COLORS[info]}Bitwarden:${FLOW_COLORS[reset]}"
      if [[ -n "$BW_SESSION" ]]; then
        echo "  • Status: ${FLOW_COLORS[success]}unlocked${FLOW_COLORS[reset]} (sync enabled)"
      else
        echo "  • Status: ${FLOW_COLORS[warning]}locked${FLOW_COLORS[reset]} (sync disabled until: sec unlock)"
      fi
      ;;
  esac

  echo ""
  echo "${FLOW_COLORS[muted]}Configuration:${FLOW_COLORS[reset]}"
  echo "  FLOW_SECRET_BACKEND=${FLOW_SECRET_BACKEND:-<not set, using keychain>}"
  echo ""
}

# Helper: Count Keychain secrets
_sec_count_keychain() {
  local dump_file
  dump_file=$(mktemp)
  security dump-keychain > "$dump_file" 2>/dev/null

  local count=0
  local svc_lines
  svc_lines=$(grep -c "\"svce\"<blob>=\"$_DOT_KEYCHAIN_SERVICE\"" "$dump_file" 2>/dev/null || echo "0")
  count=$svc_lines

  rm -f "$dump_file"
  echo "$count"
}

# ═══════════════════════════════════════════════════════════════════
# BITWARDEN
# ═══════════════════════════════════════════════════════════════════

# Bitwarden fallback for cloud-synced secrets
# Usage: sec bw <name|list|add|check>
_sec_bw() {
  local subcommand="$1"
  shift 2>/dev/null

  case "$subcommand" in
    list|ls)
      _sec_bw_list "$@"
      return
      ;;

    add|new)
      _sec_bw_add "$@"
      return
      ;;

    check|expiring)
      _sec_bw_check "$@"
      return
      ;;

    help|--help|-h)
      _sec_bw_help
      return
      ;;

    "")
      _sec_bw_help
      return 1
      ;;

    *)
      # Retrieve specific secret from Bitwarden
      _sec_bw_get "$subcommand"
      return
      ;;
  esac
}

# Get secret from Bitwarden
_sec_bw_get() {
  local item_name="$1"

  if [[ -z "$item_name" ]]; then
    _flow_log_error "Usage: sec bw <name>"
    return 1
  fi

  if ! _dotf_require_tool "bw" "brew install bitwarden-cli"; then
    return 1
  fi

  if ! _dotf_bw_session_valid; then
    _flow_log_error "Bitwarden vault is locked"
    _flow_log_info "Run: ${FLOW_COLORS[cmd]}sec unlock${FLOW_COLORS[reset]}"
    return 1
  fi

  local secret_value
  local error_output
  local temp_err=$(mktemp)
  secret_value=$(bw get password "$item_name" 2>"$temp_err")
  local get_status=$?
  error_output=$(cat "$temp_err" 2>/dev/null)
  rm -f "$temp_err"

  if [[ $get_status -ne 0 ]]; then
    case "$error_output" in
      *"Not found"*|*"not found"*)
        _flow_log_error "Secret not found: $item_name"
        _flow_log_muted "Tip: Use 'sec bw list' to see Bitwarden items"
        ;;
      *"Session key"*|*"session"*)
        _flow_log_error "Session expired"
        _flow_log_info "Run: ${FLOW_COLORS[cmd]}sec unlock${FLOW_COLORS[reset]}"
        ;;
      *"locked"*|*"Locked"*)
        _flow_log_error "Vault is locked"
        _flow_log_info "Run: ${FLOW_COLORS[cmd]}sec unlock${FLOW_COLORS[reset]}"
        ;;
      *)
        _flow_log_error "Failed to retrieve secret: $item_name"
        _flow_log_muted "Error: $error_output"
        ;;
    esac
    return 1
  fi

  echo "$secret_value"
}

# Bitwarden help
_sec_bw_help() {
  echo ""
  echo "${FLOW_COLORS[header]}sec bw${FLOW_COLORS[reset]} - Bitwarden cloud secrets (requires unlock)"
  echo ""
  echo "${FLOW_COLORS[warning]}Commands:${FLOW_COLORS[reset]}"
  echo "  sec bw <name>      Get secret from Bitwarden"
  echo "  sec bw list        List Bitwarden items"
  echo "  sec bw add <name>  Add to Bitwarden (with expiration)"
  echo "  sec bw check       Check expiring secrets"
  echo ""
  echo "${FLOW_COLORS[muted]}Note: Bitwarden requires 'sec unlock' first${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[muted]}For instant local access, use: sec <name>${FLOW_COLORS[reset]}"
  echo ""
}

_sec_bw_list() {
  if ! _dotf_require_tool "bw" "brew install bitwarden-cli"; then
    return 1
  fi

  # Check if session is active
  if ! _dotf_bw_session_valid; then
    _flow_log_error "Bitwarden vault is locked"
    _flow_log_info "Run: ${FLOW_COLORS[cmd]}sec unlock${FLOW_COLORS[reset]}"
    return 1
  fi

  _flow_log_info "Retrieving items from vault..."
  echo ""

  # Get items (suppress sensitive output)
  local items_json
  items_json=$(bw list items --session "$BW_SESSION" 2>/dev/null)
  local list_status=$?

  if [[ $list_status -ne 0 ]]; then
    _flow_log_error "Failed to retrieve items"
    return 1
  fi

  # Parse and format items (using jq if available, otherwise basic parsing)
  if command -v jq &>/dev/null; then
    # Pretty format with jq
    echo "$items_json" | jq -r '.[] |
      "\(.type |
        if . == 1 then "🔑"
        elif . == 2 then "📝"
        elif . == 3 then "💳"
        else "📦" end
      ) \(.name)\t\(.folder // "No folder")"' | \
    while IFS=$'\t' read -r item folder; do
      echo "${FLOW_COLORS[accent]}$item${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}($folder)${FLOW_COLORS[reset]}"
    done
  else
    # Fallback: basic parsing without jq
    echo "$items_json" | \
    command grep -o '"name":"[^"]*"' | \
    command cut -d'"' -f4 | \
    while read -r name; do
      echo "${FLOW_COLORS[accent]}🔑 $name${FLOW_COLORS[reset]}"
    done
  fi

  echo ""
  _flow_log_info "Usage: ${FLOW_COLORS[cmd]}sec <name>${FLOW_COLORS[reset]}"
  echo ""
}

# ═══════════════════════════════════════════════════════════════════
# SECRET ADD - Store new secret (Phase 1 - v2.0)
# ═══════════════════════════════════════════════════════════════════

_sec_bw_add() {
  local secret_name="$1"
  local expires_days=""
  local notes=""

  # Parse arguments
  shift 2>/dev/null
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --expires|-e)
        expires_days="$2"
        shift 2
        ;;
      --notes|-n)
        notes="$2"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done

  # Validate name
  if [[ -z "$secret_name" ]]; then
    _flow_log_error "Usage: sec bw add <name> [--expires <days>] [--notes <text>]"
    echo ""
    echo "Examples:"
    echo "  ${FLOW_COLORS[cmd]}sec bw add github-token${FLOW_COLORS[reset]}"
    echo "  ${FLOW_COLORS[cmd]}sec bw add npm-token --expires 90${FLOW_COLORS[reset]}"
    echo "  ${FLOW_COLORS[cmd]}sec bw add api-key --notes 'Production API key'${FLOW_COLORS[reset]}"
    return 1
  fi

  # Validate name format (alphanumeric, hyphens, underscores only)
  if [[ ! "$secret_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    _flow_log_error "Invalid secret name: $secret_name"
    _flow_log_info "Name must contain only letters, numbers, hyphens, and underscores"
    return 1
  fi

  if ! _dotf_require_tool "bw" "brew install bitwarden-cli"; then
    return 1
  fi

  # Check if session is active
  if ! _dotf_bw_session_valid; then
    _flow_log_error "Bitwarden vault is locked"
    _flow_log_info "Run: ${FLOW_COLORS[cmd]}sec unlock${FLOW_COLORS[reset]}"
    return 1
  fi

  # Check if secret already exists
  local existing
  existing=$(bw get item "$secret_name" --session "$BW_SESSION" 2>/dev/null)
  if [[ -n "$existing" ]]; then
    _flow_log_warning "Secret '$secret_name' already exists"
    echo ""
    echo "  ${FLOW_COLORS[cmd]}u${FLOW_COLORS[reset]} - Update existing secret"
    echo "  ${FLOW_COLORS[cmd]}n${FLOW_COLORS[reset]} - Cancel"
    echo ""
    read -q "?Update? [u/n] " update_response
    echo ""
    if [[ "$update_response" != "u" ]]; then
      _flow_log_muted "Cancelled"
      return 0
    fi
  fi

  # Prompt for secret value (hidden input)
  echo ""
  echo -n "${FLOW_COLORS[bold]}Enter secret value:${FLOW_COLORS[reset]} "
  local secret_value
  read -s secret_value
  echo ""

  if [[ -z "$secret_value" ]]; then
    _flow_log_error "Secret value cannot be empty"
    return 1
  fi

  # Build metadata JSON
  local metadata="{\"dot_version\":\"2.0\",\"created\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
  if [[ -n "$expires_days" ]]; then
    local expire_date
    expire_date=$(date -v+${expires_days}d +%Y-%m-%d 2>/dev/null || date -d "+${expires_days} days" +%Y-%m-%d 2>/dev/null)
    metadata="${metadata},\"expires\":\"${expire_date}\""
  fi
  if [[ -n "$notes" ]]; then
    metadata="${metadata},\"notes\":\"${notes}\""
  fi
  metadata="${metadata}}"

  # Create or update item in Bitwarden
  _flow_log_info "Storing secret in vault..."

  if [[ -n "$existing" ]]; then
    # Update existing item
    local item_id
    item_id=$(echo "$existing" | jq -r '.id' 2>/dev/null)
    if [[ -n "$item_id" && "$item_id" != "null" ]]; then
      # Get current item, update password and notes
      local updated_item
      updated_item=$(echo "$existing" | jq --arg pw "$secret_value" --arg notes "$metadata" \
        '.login.password = $pw | .notes = $notes')
      echo "$updated_item" | bw encode | bw edit item "$item_id" --session "$BW_SESSION" >/dev/null 2>&1
      local edit_status=$?
      if [[ $edit_status -eq 0 ]]; then
        _flow_log_success "Updated secret: $secret_name"
      else
        _flow_log_error "Failed to update secret"
        return 1
      fi
    else
      _flow_log_error "Failed to get item ID for update"
      return 1
    fi
  else
    # Create new login item
    local new_item
    new_item=$(cat <<EOF
{
  "type": 1,
  "name": "$secret_name",
  "notes": "$metadata",
  "login": {
    "username": "",
    "password": "$secret_value"
  }
}
EOF
)
    echo "$new_item" | bw encode | bw create item --session "$BW_SESSION" >/dev/null 2>&1
    local create_status=$?
    if [[ $create_status -eq 0 ]]; then
      _flow_log_success "Added secret: $secret_name"
    else
      _flow_log_error "Failed to create secret"
      return 1
    fi
  fi

  # Sync vault
  bw sync --session "$BW_SESSION" >/dev/null 2>&1

  echo ""
  if [[ -n "$expires_days" ]]; then
    _flow_log_muted "Expires: $expire_date ($expires_days days)"
  fi
  echo ""
  echo "💡 Usage: ${FLOW_COLORS[cmd]}TOKEN=\$(sec $secret_name)${FLOW_COLORS[reset]}"
}

# ═══════════════════════════════════════════════════════════════════
# SECRET CHECK - Show expiring secrets (Phase 1 - v2.0)
# ═══════════════════════════════════════════════════════════════════

_sec_bw_check() {
  local warn_days="${1:-30}"  # Default: warn for secrets expiring within 30 days

  if ! _dotf_require_tool "bw" "brew install bitwarden-cli"; then
    return 1
  fi

  if ! command -v jq &>/dev/null; then
    _flow_log_error "jq is required for expiration checking"
    _flow_log_info "Install: ${FLOW_COLORS[cmd]}brew install jq${FLOW_COLORS[reset]}"
    return 1
  fi

  # Check if session is active
  if ! _dotf_bw_session_valid; then
    _flow_log_error "Bitwarden vault is locked"
    _flow_log_info "Run: ${FLOW_COLORS[cmd]}sec unlock${FLOW_COLORS[reset]}"
    return 1
  fi

  _flow_log_info "Checking secret expirations..."
  echo ""

  # Get all items
  local items_json
  items_json=$(bw list items --session "$BW_SESSION" 2>/dev/null)

  if [[ -z "$items_json" || "$items_json" == "[]" ]]; then
    _flow_log_muted "No secrets found in vault"
    return 0
  fi

  local today_epoch
  today_epoch=$(date +%s)
  local warn_epoch=$((today_epoch + warn_days * 86400))

  local expiring_count=0
  local valid_count=0
  local no_expiry_count=0

  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🔐 Secret Expiration Status${FLOW_COLORS[reset]}                      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"

  # Parse items and check expiration
  echo "$items_json" | jq -r '.[] | select(.type == 1) | "\(.name)\t\(.notes // "")"' | \
  while IFS=$'\t' read -r name notes; do
    # Try to parse expiration from notes (dot metadata format)
    local expires=""
    if [[ "$notes" == *'"expires"'* ]]; then
      expires=$(echo "$notes" | jq -r '.expires // empty' 2>/dev/null)
    fi

    if [[ -n "$expires" && "$expires" != "null" ]]; then
      # Parse expiration date
      local expire_epoch
      expire_epoch=$(date -j -f "%Y-%m-%d" "$expires" +%s 2>/dev/null || date -d "$expires" +%s 2>/dev/null)

      if [[ -n "$expire_epoch" ]]; then
        local days_left=$(( (expire_epoch - today_epoch) / 86400 ))

        if [[ $expire_epoch -lt $today_epoch ]]; then
          # Expired
          printf "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[error]}❌ %-20s${FLOW_COLORS[reset]} EXPIRED (%d days ago)     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}\n" "$name" "$((-days_left))"
          ((expiring_count++))
        elif [[ $expire_epoch -lt $warn_epoch ]]; then
          # Expiring soon
          printf "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[warning]}⚠️  %-20s${FLOW_COLORS[reset]} expires in %d days      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}\n" "$name" "$days_left"
          ((expiring_count++))
        else
          # Valid
          printf "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[success]}✓ %-20s${FLOW_COLORS[reset]} expires in %d days      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}\n" "$name" "$days_left"
          ((valid_count++))
        fi
      fi
    else
      # No expiration set
      printf "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}○ %-20s${FLOW_COLORS[reset]} no expiration          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}\n" "$name"
      ((no_expiry_count++))
    fi
  done

  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""

  if [[ $expiring_count -gt 0 ]]; then
    _flow_log_warning "$expiring_count secret(s) expiring or expired"
    echo "💡 Tip: ${FLOW_COLORS[cmd]}tok <name> --refresh${FLOW_COLORS[reset]} to rotate"
  else
    _flow_log_success "No secrets expiring within $warn_days days"
  fi
}

# ═══════════════════════════════════════════════════════════════════
# SECRET HELP - Show secret subcommands (detailed Bitwarden help)
# ═══════════════════════════════════════════════════════════════════

_sec_bw_help_detailed() {
  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🔐 SEC BW - Bitwarden Secret Management${FLOW_COLORS[reset]}         ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Retrieve:${FLOW_COLORS[reset]}                                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}sec <name>${FLOW_COLORS[reset]}            Get secret value        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}sec list${FLOW_COLORS[reset]}              List all secrets        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Manage:${FLOW_COLORS[reset]}                                         ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}sec add <name>${FLOW_COLORS[reset]}        Store new secret        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}sec check${FLOW_COLORS[reset]}             Check expirations       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Options for add:${FLOW_COLORS[reset]}                                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[muted]}--expires, -e <days>${FLOW_COLORS[reset]}  Set expiration          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[muted]}--notes, -n <text>${FLOW_COLORS[reset]}    Add notes               ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Examples:${FLOW_COLORS[reset]}                                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[example]}TOKEN=\$(sec github-token)${FLOW_COLORS[reset]}                  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[example]}sec bw add npm-token --expires 90${FLOW_COLORS[reset]}           ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[example]}sec check${FLOW_COLORS[reset]}                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

# ═══════════════════════════════════════════════════════════════════
# SYNC
# ═══════════════════════════════════════════════════════════════════

# =============================================================================
# Function: _sec_sync
# Purpose: Sync secrets between Keychain and Bitwarden
# =============================================================================
# Arguments:
#   $1 - (optional) Mode: --to-bw, --from-bw, --status (default: interactive)
#
# Returns:
#   0 - Sync successful
#   1 - Error (Bitwarden not available, sync failed)
#
# Example:
#   sec sync              # Interactive comparison and sync
#   sec sync --status     # Show differences
#   sec sync --to-bw      # Push Keychain -> Bitwarden
#   sec sync --from-bw    # Pull Bitwarden -> Keychain
# =============================================================================
_sec_sync() {
  local mode="${1:-interactive}"

  # Check if Bitwarden CLI is available
  if ! command -v bw &>/dev/null; then
    _flow_log_error "Bitwarden CLI not installed"
    _flow_log_info "Install: ${FLOW_COLORS[cmd]}brew install bitwarden-cli${FLOW_COLORS[reset]}"
    return 1
  fi

  case "$mode" in
    --status|-s|status)
      _sec_sync_status
      return
      ;;

    --to-bw|--to-bitwarden|push)
      _sec_sync_to_bitwarden
      return
      ;;

    --from-bw|--from-bitwarden|pull)
      _sec_sync_from_bitwarden
      return
      ;;

    --help|-h|help)
      _sec_sync_help
      return
      ;;

    interactive|"")
      _sec_sync_interactive
      return
      ;;

    *)
      _flow_log_error "Unknown sync mode: $mode"
      _sec_sync_help
      return 1
      ;;
  esac
}

# Sync help
_sec_sync_help() {
  echo ""
  echo "${FLOW_COLORS[header]}sec sync${FLOW_COLORS[reset]} - Sync between Keychain and Bitwarden"
  echo ""
  echo "${FLOW_COLORS[warning]}Commands:${FLOW_COLORS[reset]}"
  echo "  sec sync              Interactive sync wizard"
  echo "  sec sync --status     Show differences between backends"
  echo "  sec sync --to-bw      Push Keychain → Bitwarden"
  echo "  sec sync --from-bw    Pull Bitwarden → Keychain"
  echo ""
  echo "${FLOW_COLORS[muted]}Requires Bitwarden unlocked: sec unlock${FLOW_COLORS[reset]}"
  echo ""
}

# Show sync status (differences)
_sec_sync_status() {
  echo ""
  echo "${FLOW_COLORS[header]}Sync Status${FLOW_COLORS[reset]}"
  echo ""

  # Check if Bitwarden is unlocked
  if [[ -z "$BW_SESSION" ]]; then
    _flow_log_warning "Bitwarden is locked"
    _flow_log_info "Run: ${FLOW_COLORS[cmd]}sec unlock${FLOW_COLORS[reset]} to enable sync status"
    echo ""
    echo "${FLOW_COLORS[info]}Keychain secrets:${FLOW_COLORS[reset]}"
    _dotf_kc_list
    return 0
  fi

  # Get Keychain secrets
  echo "${FLOW_COLORS[info]}Keychain secrets:${FLOW_COLORS[reset]}"
  local -a kc_secrets=()
  local dump_file
  dump_file=$(mktemp)
  security dump-keychain > "$dump_file" 2>/dev/null

  local svc_lines
  svc_lines=$(grep -n "\"svce\"<blob>=\"$_DOT_KEYCHAIN_SERVICE\"" "$dump_file" 2>/dev/null | cut -d: -f1)

  for line_num in ${(f)svc_lines}; do
    local start_line=$((line_num - 20))
    [[ $start_line -lt 1 ]] && start_line=1

    local acct_line
    acct_line=$(sed -n "${start_line},${line_num}p" "$dump_file" | grep '"acct"<blob>="' | tail -1)

    if [[ -n "$acct_line" ]]; then
      local account_name
      account_name="${acct_line#*\"acct\"<blob>=\"}"
      account_name="${account_name%%\"*}"
      if [[ -n "$account_name" ]]; then
        kc_secrets+=("$account_name")
        echo "  ${FLOW_COLORS[success]}●${FLOW_COLORS[reset]} $account_name"
      fi
    fi
  done

  rm -f "$dump_file"

  if [[ ${#kc_secrets[@]} -eq 0 ]]; then
    echo "  ${FLOW_COLORS[muted]}(none)${FLOW_COLORS[reset]}"
  fi

  echo ""
  echo "${FLOW_COLORS[info]}Bitwarden secrets (flow-cli):${FLOW_COLORS[reset]}"

  # Get Bitwarden items
  local items_json
  items_json=$(bw list items --session "$BW_SESSION" 2>/dev/null)

  if [[ -z "$items_json" ]] || [[ "$items_json" == "[]" ]]; then
    echo "  ${FLOW_COLORS[muted]}(none)${FLOW_COLORS[reset]}"
  else
    echo "$items_json" | jq -r '.[] | .name' 2>/dev/null | while read -r name; do
      if _flow_array_contains "$name" "${kc_secrets[@]}"; then
        echo "  ${FLOW_COLORS[success]}●${FLOW_COLORS[reset]} $name ${FLOW_COLORS[muted]}(synced)${FLOW_COLORS[reset]}"
      else
        echo "  ${FLOW_COLORS[warning]}○${FLOW_COLORS[reset]} $name ${FLOW_COLORS[muted]}(not in Keychain)${FLOW_COLORS[reset]}"
      fi
    done
  fi

  echo ""
}

# Push Keychain -> Bitwarden
_sec_sync_to_bitwarden() {
  if [[ -z "$BW_SESSION" ]]; then
    _flow_log_error "Bitwarden is locked"
    _flow_log_info "Run: ${FLOW_COLORS[cmd]}sec unlock${FLOW_COLORS[reset]}"
    return 1
  fi

  _flow_log_info "Syncing Keychain → Bitwarden..."

  # Get Keychain secrets
  local dump_file
  dump_file=$(mktemp)
  security dump-keychain > "$dump_file" 2>/dev/null

  local count=0
  local svc_lines
  svc_lines=$(grep -n "\"svce\"<blob>=\"$_DOT_KEYCHAIN_SERVICE\"" "$dump_file" 2>/dev/null | cut -d: -f1)

  for line_num in ${(f)svc_lines}; do
    local start_line=$((line_num - 20))
    [[ $start_line -lt 1 ]] && start_line=1

    local acct_line
    acct_line=$(sed -n "${start_line},${line_num}p" "$dump_file" | grep '"acct"<blob>="' | tail -1)

    if [[ -n "$acct_line" ]]; then
      local secret_name
      secret_name="${acct_line#*\"acct\"<blob>=\"}"
      secret_name="${secret_name%%\"*}"

      if [[ -n "$secret_name" ]]; then
        # Get secret value from Keychain
        local secret_value
        secret_value=$(security find-generic-password -a "$secret_name" -s "$_DOT_KEYCHAIN_SERVICE" -w 2>/dev/null)

        if [[ -n "$secret_value" ]]; then
          # Check if exists in Bitwarden
          local existing
          existing=$(bw get item "$secret_name" --session "$BW_SESSION" 2>/dev/null)

          if [[ -n "$existing" ]]; then
            # Update existing
            local item_id
            item_id=$(echo "$existing" | jq -r '.id')
            local updated_item
            updated_item=$(echo "$existing" | jq --arg pw "$secret_value" '.login.password = $pw')
            echo "$updated_item" | bw encode | bw edit item "$item_id" --session "$BW_SESSION" >/dev/null 2>&1
            _flow_log_success "Updated: $secret_name"
          else
            # Create new
            local new_item
            new_item=$(jq -n \
              --arg name "$secret_name" \
              --arg pw "$secret_value" \
              '{type: 1, name: $name, login: {password: $pw}}')
            echo "$new_item" | bw encode | bw create item --session "$BW_SESSION" >/dev/null 2>&1
            _flow_log_success "Created: $secret_name"
          fi
          ((count++))
        fi
      fi
    fi
  done

  rm -f "$dump_file"

  if [[ $count -gt 0 ]]; then
    bw sync --session "$BW_SESSION" >/dev/null 2>&1
    _flow_log_success "Synced $count secret(s) to Bitwarden"
  else
    _flow_log_muted "No secrets to sync"
  fi
}

# Pull Bitwarden -> Keychain
_sec_sync_from_bitwarden() {
  if [[ -z "$BW_SESSION" ]]; then
    _flow_log_error "Bitwarden is locked"
    _flow_log_info "Run: ${FLOW_COLORS[cmd]}sec unlock${FLOW_COLORS[reset]}"
    return 1
  fi

  _flow_log_info "Syncing Bitwarden → Keychain..."

  local items_json
  items_json=$(bw list items --session "$BW_SESSION" 2>/dev/null)

  if [[ -z "$items_json" ]] || [[ "$items_json" == "[]" ]]; then
    _flow_log_muted "No secrets in Bitwarden to sync"
    return 0
  fi

  local count=0

  echo "$items_json" | jq -c '.[]' 2>/dev/null | while read -r item; do
    local name
    local password
    name=$(echo "$item" | jq -r '.name')
    password=$(echo "$item" | jq -r '.login.password // .notes // empty')

    if [[ -n "$name" ]] && [[ -n "$password" ]]; then
      security add-generic-password \
        -a "$name" \
        -s "$_DOT_KEYCHAIN_SERVICE" \
        -w "$password" \
        -U 2>/dev/null
      _flow_log_success "Synced: $name"
      ((count++))
    fi
  done

  _flow_log_success "Synced secrets from Bitwarden to Keychain"
}

# Interactive sync
_sec_sync_interactive() {
  echo ""
  echo "${FLOW_COLORS[header]}Secret Sync Wizard${FLOW_COLORS[reset]}"
  echo ""

  # Show status first
  _sec_sync_status

  if [[ -z "$BW_SESSION" ]]; then
    _flow_log_warning "Unlock Bitwarden to enable sync: sec unlock"
    return 0
  fi

  echo "${FLOW_COLORS[warning]}Choose sync direction:${FLOW_COLORS[reset]}"
  echo "  1) Push Keychain → Bitwarden"
  echo "  2) Pull Bitwarden → Keychain"
  echo "  3) Cancel"
  echo ""
  echo -n "Choice [1-3]: "
  local choice
  read -r choice

  case "$choice" in
    1)
      _sec_sync_to_bitwarden
      ;;
    2)
      _sec_sync_from_bitwarden
      ;;
    *)
      _flow_log_muted "Cancelled"
      ;;
  esac
}

# ═══════════════════════════════════════════════════════════════════
# DASHBOARD (was _dotf_secrets)
# ═══════════════════════════════════════════════════════════════════

_sec_dashboard() {
  local subcommand="$1"

  case "$subcommand" in
    sync)
      shift
      _sec_dashboard_sync "$@"
      return $?
      ;;
    help|--help|-h)
      _sec_dashboard_help
      return 0
      ;;
    ""|dashboard)
      # Default: show dashboard
      ;;
    *)
      _flow_log_error "Unknown subcommand: $subcommand"
      _sec_dashboard_help
      return 1
      ;;
  esac

  # Dashboard implementation
  if ! _dotf_require_tool "bw" "brew install bitwarden-cli"; then
    return 1
  fi

  if ! command -v jq &>/dev/null; then
    _flow_log_error "jq is required for the secrets dashboard"
    _flow_log_info "Install: ${FLOW_COLORS[cmd]}brew install jq${FLOW_COLORS[reset]}"
    return 1
  fi

  # Check if session is active
  if ! _dotf_bw_session_valid; then
    _flow_log_info "Bitwarden vault is locked. Unlocking..."
    _sec_unlock || return 1
  fi

  _flow_log_info "Loading secrets dashboard..."

  # Get all items
  local items_json
  items_json=$(bw list items --session "$BW_SESSION" 2>/dev/null)

  if [[ -z "$items_json" || "$items_json" == "[]" ]]; then
    echo ""
    echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🔐 Secret Status${FLOW_COLORS[reset]}                                 ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}No secrets found in vault${FLOW_COLORS[reset]}                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Get started:                                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}tok github${FLOW_COLORS[reset]}         Create GitHub token       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}sec add${FLOW_COLORS[reset]}            Add custom secret          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
    echo ""
    return 0
  fi

  local today_epoch=$(date +%s)
  local warn_days=30
  local warn_epoch=$((today_epoch + warn_days * 86400))

  local expiring_count=0
  local expired_count=0
  local valid_count=0

  # Build table data
  local table_data=""

  while IFS=$'\t' read -r name notes; do
    [[ -z "$name" ]] && continue

    local secret_type="custom"
    local expires=""
    local status_icon="${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]}"
    local status_text="Valid"
    local expire_text="never"

    # Parse metadata from notes
    if [[ "$notes" == *'"dot_version"'* ]]; then
      # Has dot metadata
      secret_type=$(echo "$notes" | jq -r '.type // "custom"' 2>/dev/null)
      expires=$(echo "$notes" | jq -r '.expires // empty' 2>/dev/null)
    fi

    # Check expiration
    if [[ -n "$expires" && "$expires" != "null" ]]; then
      local expire_epoch
      expire_epoch=$(date -j -f "%Y-%m-%d" "$expires" +%s 2>/dev/null || date -d "$expires" +%s 2>/dev/null)

      if [[ -n "$expire_epoch" ]]; then
        local days_left=$(( (expire_epoch - today_epoch) / 86400 ))

        if [[ $expire_epoch -lt $today_epoch ]]; then
          status_icon="${FLOW_COLORS[error]}❌${FLOW_COLORS[reset]}"
          status_text="Expired"
          expire_text="$((-days_left)) days ago"
          ((expired_count++))
        elif [[ $expire_epoch -lt $warn_epoch ]]; then
          status_icon="${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]}"
          status_text="Expiring"
          expire_text="in ${days_left} days"
          ((expiring_count++))
        else
          expire_text="in ${days_left} days"
          ((valid_count++))
        fi
      fi
    else
      ((valid_count++))
    fi

    # Truncate name if too long
    local display_name="$name"
    [[ ${#name} -gt 18 ]] && display_name="${name:0:15}..."

    table_data+=$(printf "  %-18s %-8s %s %-8s %-15s\n" "$display_name" "$secret_type" "$status_icon" "$status_text" "$expire_text")
    table_data+=$'\n'
  done < <(echo "$items_json" | jq -r '.[] | select(.type == 1) | "\(.name)\t\(.notes // "")"')

  # Get vault status
  local vault_status=""
  if _dotf_bw_session_valid; then
    local time_remaining=$(_dotf_session_time_remaining_fmt)
    vault_status="🔓 Unlocked (${time_remaining} remaining)"
  else
    vault_status="🔒 Locked"
  fi

  # Display dashboard
  echo ""
  echo "${FLOW_COLORS[header]}╭────────────────────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🔐 Secret Status${FLOW_COLORS[reset]}                                              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├────────────────────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  printf "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  %-18s %-8s   %-8s %-15s          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}\n" "Token" "Type" "Status" "Expires"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ────────────────────────────────────────────────────────────  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

  # Print each row
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}$line${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  done <<< "$table_data"

  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Vault: ${vault_status}                            ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

  # Show warnings if any
  if [[ $expired_count -gt 0 ]]; then
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[error]}❌ ${expired_count} token(s) expired!${FLOW_COLORS[reset]}                                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  fi
  if [[ $expiring_count -gt 0 ]]; then
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[warning]}⚠ ${expiring_count} token(s) expiring soon${FLOW_COLORS[reset]}                               ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  fi
  if [[ $expired_count -gt 0 || $expiring_count -gt 0 ]]; then
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  💡 Run: ${FLOW_COLORS[cmd]}tok <type>${FLOW_COLORS[reset]} to rotate                              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  fi

  echo "${FLOW_COLORS[header]}╰────────────────────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

_sec_dashboard_help() {
  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🔐 SEC DASHBOARD - Secret Management${FLOW_COLORS[reset]}             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Commands:${FLOW_COLORS[reset]}                                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}sec dashboard${FLOW_COLORS[reset]}         Full overview          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}sec dashboard sync github${FLOW_COLORS[reset]}  Sync to repo   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}See also:${FLOW_COLORS[reset]}                                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}tok github${FLOW_COLORS[reset]}            Create new token       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}sec add${FLOW_COLORS[reset]}               Add custom secret      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

# ───────────────────────────────────────────────────────────────────
# DASHBOARD SYNC - Sync to GitHub repo secrets (Phase 3 - v2.2.0)
# ───────────────────────────────────────────────────────────────────

_sec_dashboard_sync() {
  local target="$1"

  if [[ -z "$target" ]]; then
    _flow_log_error "Sync target required"
    echo ""
    echo "Usage: ${FLOW_COLORS[cmd]}sec dashboard sync github${FLOW_COLORS[reset]}"
    echo ""
    echo "Supported targets:"
    echo "  ${FLOW_COLORS[cmd]}github${FLOW_COLORS[reset]}  - Sync to GitHub repository secrets"
    return 1
  fi

  case "$target" in
    github|gh)
      _sec_sync_github "$@"
      ;;
    *)
      _flow_log_error "Unknown sync target: $target"
      _flow_log_info "Supported: github"
      return 1
      ;;
  esac
}

_sec_sync_github() {
  # Require gh CLI
  if ! command -v gh &>/dev/null; then
    _flow_log_error "GitHub CLI (gh) is required for sync"
    _flow_log_info "Install: ${FLOW_COLORS[cmd]}brew install gh${FLOW_COLORS[reset]}"
    return 1
  fi

  # Check gh auth
  if ! gh auth status &>/dev/null 2>&1; then
    _flow_log_error "Not authenticated with GitHub CLI"
    _flow_log_info "Run: ${FLOW_COLORS[cmd]}gh auth login${FLOW_COLORS[reset]}"
    return 1
  fi

  # Require bw
  if ! _dotf_require_tool "bw" "brew install bitwarden-cli"; then
    return 1
  fi

  # Check session
  if ! _dotf_bw_session_valid; then
    _flow_log_info "Bitwarden vault is locked. Unlocking..."
    _sec_unlock || return 1
  fi

  # Check if in a git repo
  if ! git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    _flow_log_error "Not in a git repository"
    return 1
  fi

  # Get repo info
  local repo_url=$(git remote get-url origin 2>/dev/null)
  local repo_name=""

  if [[ "$repo_url" =~ github\.com[:/]([^/]+/[^/.]+) ]]; then
    repo_name="${match[1]%.git}"
  else
    _flow_log_error "Could not determine GitHub repository"
    _flow_log_info "Make sure origin points to a GitHub repo"
    return 1
  fi

  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🔄 Sync Secrets to GitHub${FLOW_COLORS[reset]}                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Repository: ${FLOW_COLORS[accent]}${repo_name}${FLOW_COLORS[reset]}                      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""

  # Get secrets from Bitwarden
  _flow_log_info "Loading secrets from vault..."

  local items_json
  items_json=$(bw list items --session "$BW_SESSION" 2>/dev/null)

  if [[ -z "$items_json" || "$items_json" == "[]" ]]; then
    _flow_log_muted "No secrets found in vault"
    return 0
  fi

  # Filter DOT-managed secrets
  local secrets=()
  local names=()

  while IFS=$'\t' read -r name notes; do
    [[ -z "$name" ]] && continue

    # Only include secrets with DOT metadata
    if [[ "$notes" == *'"dot_version"'* ]]; then
      local secret_type=$(echo "$notes" | jq -r '.type // "custom"' 2>/dev/null)
      names+=("$name ($secret_type)")
      secrets+=("$name")
    fi
  done < <(echo "$items_json" | jq -r '.[] | select(.type == 1) | [.name, (.notes // "")] | @tsv' 2>/dev/null)

  if [[ ${#secrets[@]} -eq 0 ]]; then
    _flow_log_muted "No DOT-managed secrets found"
    _flow_log_info "Use 'tok' or 'sec add' to create secrets"
    return 0
  fi

  echo "Available secrets:"
  echo ""
  local i=1
  for name in "${names[@]}"; do
    echo "  ${FLOW_COLORS[cmd]}$i${FLOW_COLORS[reset]} - $name"
    ((i++))
  done
  echo "  ${FLOW_COLORS[cmd]}a${FLOW_COLORS[reset]} - Sync all"
  echo "  ${FLOW_COLORS[cmd]}q${FLOW_COLORS[reset]} - Cancel"
  echo ""

  read "?Select secrets to sync (e.g., 1,2 or a): " selection

  if [[ "$selection" == "q" ]]; then
    _flow_log_muted "Cancelled"
    return 0
  fi

  local selected_secrets=()

  if [[ "$selection" == "a" ]]; then
    selected_secrets=("${secrets[@]}")
  else
    # Parse comma-separated selection
    IFS=',' read -ra indices <<< "$selection"
    for idx in "${indices[@]}"; do
      idx="${idx// /}"  # Trim whitespace
      if [[ "$idx" =~ ^[0-9]+$ ]] && [[ $idx -ge 1 ]] && [[ $idx -le ${#secrets[@]} ]]; then
        selected_secrets+=("${secrets[$idx]}")
      fi
    done
  fi

  if [[ ${#selected_secrets[@]} -eq 0 ]]; then
    _flow_log_error "No valid secrets selected"
    return 1
  fi

  echo ""
  echo "Will sync ${#selected_secrets[@]} secret(s) to ${repo_name}:"
  for name in "${selected_secrets[@]}"; do
    # Convert to SCREAMING_SNAKE_CASE for GitHub
    local gh_name=$(echo "${name}" | tr '[:lower:]-' '[:upper:]_')
    echo "  ${FLOW_COLORS[muted]}${name}${FLOW_COLORS[reset]} → ${FLOW_COLORS[accent]}${gh_name}${FLOW_COLORS[reset]}"
  done
  echo ""

  read -q "?Proceed? [y/n] " confirm
  echo ""

  if [[ "$confirm" != "y" ]]; then
    _flow_log_muted "Cancelled"
    return 0
  fi

  echo ""
  local success_count=0
  local fail_count=0

  for name in "${selected_secrets[@]}"; do
    # Get secret value
    local secret_value
    secret_value=$(bw get password "$name" --session "$BW_SESSION" 2>/dev/null)

    if [[ -z "$secret_value" ]]; then
      _flow_log_error "Failed to retrieve: $name"
      ((fail_count++))
      continue
    fi

    # Convert to SCREAMING_SNAKE_CASE
    local gh_name=$(echo "${name}" | tr '[:lower:]-' '[:upper:]_')

    # Set GitHub secret
    if echo "$secret_value" | gh secret set "$gh_name" --repo "$repo_name" 2>/dev/null; then
      _flow_log_success "Synced: $name → $gh_name"
      ((success_count++))
    else
      _flow_log_error "Failed to sync: $name"
      ((fail_count++))
    fi
  done

  echo ""
  if [[ $fail_count -eq 0 ]]; then
    _flow_log_success "All ${success_count} secret(s) synced successfully!"
  else
    _flow_log_warning "${success_count} synced, ${fail_count} failed"
  fi

  echo ""
  echo "💡 Use in GitHub Actions:"
  echo "   ${FLOW_COLORS[muted]}\${{ secrets.YOUR_SECRET_NAME }}${FLOW_COLORS[reset]}"
  echo ""
}

# ═══════════════════════════════════════════════════════════════════
# DOCTOR - Secret-specific diagnostics
# ═══════════════════════════════════════════════════════════════════

_sec_doctor() {
  _flow_log_warning "Secret diagnostics not yet implemented"
  _flow_log_info "Coming in a future release"
}
