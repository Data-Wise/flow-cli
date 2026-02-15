#!/usr/bin/env zsh
# ═══════════════════════════════════════════════════════════════════
# TOK - Token Management Dispatcher
# ═══════════════════════════════════════════════════════════════════
# Version: 3.0.0
# Extracted from dot-dispatcher.zsh (dot token → tok)
# Manages API tokens: GitHub, NPM, PyPI
# Features: creation wizards, rotation, expiration tracking, gh sync
# ═══════════════════════════════════════════════════════════════════

tok() {
  if [[ $# -eq 0 ]]; then
    _tok_help
    return
  fi

  local subcommand="$1"
  shift 2>/dev/null

  # Check for --refresh flag anywhere in arguments
  local refresh_mode=false
  local token_name=""
  local remaining_args=()

  for arg in "$subcommand" "$@"; do
    case "$arg" in
      --refresh|-r|refresh)
        refresh_mode=true
        ;;
      *)
        remaining_args+=("$arg")
        ;;
    esac
  done

  if [[ "$refresh_mode" == true ]]; then
    if [[ ${#remaining_args[@]} -gt 0 ]]; then
      token_name="${remaining_args[1]}"
      _tok_refresh "$token_name"
      return $?
    else
      _flow_log_error "Usage: tok <name> --refresh"
      _flow_log_info "Example: tok github-token --refresh"
      return 1
    fi
  fi

  case "$subcommand" in
    github|gh)    _tok_github "$@" ;;
    npm)          _tok_npm "$@" ;;
    pypi|pip)     _tok_pypi "$@" ;;
    expiring)     _tok_expiring "$@" ;;
    rotate)       _tok_rotate "$@" ;;
    sync)
      case "$1" in
        gh|github)  _tok_sync_gh ;;
        *)          _flow_log_error "Usage: tok sync gh"; return 1 ;;
      esac
      ;;
    doctor|dr)    _tok_doctor "$@" ;;
    help|--help|-h) _tok_help ;;
    *)
      # Could be a token name for refresh (without --refresh flag)
      # Check if it exists in vault
      if _dotf_bw_session_valid 2>/dev/null; then
        local existing
        existing=$(bw get item "$subcommand" --session "$BW_SESSION" 2>/dev/null)
        if [[ -n "$existing" ]]; then
          # Token exists - check if they want to refresh
          local notes=$(echo "$existing" | jq -r '.notes // ""' 2>/dev/null)
          if echo "$notes" | grep -q '"dot_version"'; then
            _flow_log_info "Token '$subcommand' found in vault"
            echo ""
            echo "  ${FLOW_COLORS[cmd]}--refresh${FLOW_COLORS[reset]}  Rotate this token"
            echo ""
            echo "Example: ${FLOW_COLORS[cmd]}tok $subcommand --refresh${FLOW_COLORS[reset]}"
            return 0
          fi
        fi
      fi

      _flow_log_error "Unknown token provider: $subcommand"
      _flow_log_info "Supported: github, npm, pypi"
      _flow_log_muted "Or use: tok <name> --refresh"
      echo ""
      _tok_help
      return 1
      ;;
  esac
}

_tok_help() {
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
${_C_BOLD}│ tok - Token Management                       │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}tok github${_C_NC}          GitHub PAT wizard
  ${_C_CYAN}tok expiring${_C_NC}        Check expiration status
  ${_C_CYAN}tok rotate${_C_NC}          Rotate existing token
  ${_C_CYAN}tok doctor${_C_NC}          Token health check

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} tok github                    ${_C_DIM}# Create new GitHub PAT${_C_NC}
  ${_C_DIM}\$${_C_NC} tok expiring                  ${_C_DIM}# Check what's expiring${_C_NC}
  ${_C_DIM}\$${_C_NC} tok github-token --refresh    ${_C_DIM}# Rotate a token${_C_NC}

${_C_BLUE}📋 TOKEN WIZARDS${_C_NC}:
  ${_C_CYAN}tok github${_C_NC}          GitHub PAT wizard
  ${_C_CYAN}tok npm${_C_NC}             NPM token wizard
  ${_C_CYAN}tok pypi${_C_NC}            PyPI token wizard

${_C_BLUE}📋 TOKEN AUTOMATION${_C_NC}:
  ${_C_CYAN}tok expiring${_C_NC}        Check expiration status
  ${_C_CYAN}tok rotate${_C_NC}          Rotate existing token
  ${_C_CYAN}tok sync gh${_C_NC}         Sync with gh CLI
  ${_C_CYAN}tok <name> --refresh${_C_NC} Rotate specific token

${_C_MAGENTA}💡 TIP${_C_NC}: Wizards open browser, validate, store in Bitwarden, track expiry

${_C_DIM}📚 See also:${_C_NC}
  ${_C_CYAN}sec${_C_NC} - Secret management (Bitwarden)
  ${_C_CYAN}dots${_C_NC} - Dotfile management
  ${_C_CYAN}flow doctor --dot${_C_NC} - Health check
"
}

# ───────────────────────────────────────────────────────────────────
# TOKEN REFRESH - Rotate existing token (Phase 3 - v2.1.0)
# ───────────────────────────────────────────────────────────────────

_tok_refresh() {
  local token_name="$1"

  if [[ -z "$token_name" ]]; then
    _flow_log_error "Token name required"
    _flow_log_info "Usage: tok <name> --refresh"
    return 1
  fi

  if ! _dotf_require_tool "bw" "brew install bitwarden-cli"; then
    return 1
  fi

  # Check if session is active
  if ! _dotf_bw_session_valid; then
    _flow_log_info "Bitwarden vault is locked. Unlocking..."
    _sec_unlock || return 1
  fi

  # Look up existing token
  _flow_log_info "Looking up token: $token_name"

  local existing
  existing=$(bw get item "$token_name" --session "$BW_SESSION" 2>/dev/null)

  if [[ -z "$existing" ]]; then
    _flow_log_error "Token not found: $token_name"
    _flow_log_info "Use 'sec' to see available tokens"
    return 1
  fi

  # Parse metadata to determine token type
  local notes=$(echo "$existing" | jq -r '.notes // ""' 2>/dev/null)

  if ! echo "$notes" | grep -q '"dot_version"'; then
    _flow_log_error "Token '$token_name' doesn't have DOT metadata"
    _flow_log_muted "This token wasn't created with 'tok' wizard"
    _flow_log_info "Use the wizard to create a new token: tok github"
    return 1
  fi

  local token_type=$(echo "$notes" | jq -r '.type // "unknown"' 2>/dev/null)
  local token_subtype=$(echo "$notes" | jq -r '.token_type // ""' 2>/dev/null)
  local old_expires=$(echo "$notes" | jq -r '.expires // ""' 2>/dev/null)

  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🔄 Token Rotation${FLOW_COLORS[reset]}                                 ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Token: ${FLOW_COLORS[accent]}${token_name}${FLOW_COLORS[reset]}                              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Type:  ${token_type}${token_subtype:+ ($token_subtype)}                             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  if [[ -n "$old_expires" && "$old_expires" != "null" ]]; then
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Was expiring: ${old_expires}                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  fi
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""

  # Determine browser URL based on type
  local token_url=""
  local validation_fn=""

  case "$token_type" in
    github)
      if [[ "$token_subtype" == "fine-grained" ]]; then
        token_url="https://github.com/settings/personal-access-tokens/new"
      else
        token_url="https://github.com/settings/tokens/new"
      fi
      validation_fn="_tok_validate_github"
      ;;
    npm)
      token_url="https://www.npmjs.com/settings/~/tokens/new"
      validation_fn="_tok_validate_npm"
      ;;
    pypi)
      token_url="https://pypi.org/manage/account/token/"
      validation_fn="_tok_validate_pypi"
      ;;
    *)
      _flow_log_error "Unknown token type: $token_type"
      _flow_log_info "Cannot auto-refresh this token type"
      return 1
      ;;
  esac

  # Confirm rotation
  read -q "?Rotate this token? [y/n] " confirm
  echo ""
  [[ "$confirm" != "y" ]] && { _flow_log_muted "Cancelled"; return 0; }

  echo ""
  _flow_log_info "Press Enter to open browser..."
  read

  # Open browser
  osascript -e "open location \"$token_url\"" 2>/dev/null || open "$token_url" 2>/dev/null

  echo ""
  echo -n "${FLOW_COLORS[bold]}Paste your new token:${FLOW_COLORS[reset]} "
  local new_token
  read -s new_token
  echo ""

  if [[ -z "$new_token" ]]; then
    _flow_log_error "Token cannot be empty"
    return 1
  fi

  # Validate token based on type
  case "$token_type" in
    github)
      _flow_log_info "Validating token..."
      local api_response
      api_response=$(curl -s -H "Authorization: token $new_token" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/user" 2>/dev/null)

      if echo "$api_response" | grep -q '"login"'; then
        local username=$(echo "$api_response" | grep -o '"login":"[^"]*"' | cut -d'"' -f4)
        _flow_log_success "Token validated for user: $username"
      else
        _flow_log_warning "Token validation failed - continue anyway?"
        read -q "?Continue? [y/n] " continue_response
        echo ""
        [[ "$continue_response" != "y" ]] && return 1
      fi
      ;;
    npm)
      _flow_log_info "Validating token..."
      local whoami_response
      whoami_response=$(npm whoami --registry=https://registry.npmjs.org 2>&1)
      # Note: npm whoami uses .npmrc, so we'll do a basic format check
      if [[ "$new_token" =~ ^npm_ ]]; then
        _flow_log_success "Token format valid (npm_*)"
      else
        _flow_log_warning "Token doesn't start with 'npm_'"
      fi
      ;;
    pypi)
      if [[ "$new_token" =~ ^pypi- ]]; then
        _flow_log_success "Token format valid (pypi-*)"
      else
        _flow_log_warning "Token doesn't start with 'pypi-'"
      fi
      ;;
  esac

  # Ask for new expiration
  echo ""
  read "?New expiration (days, 0=never) [90]: " expire_days
  [[ -z "$expire_days" ]] && expire_days=90

  # Build new metadata
  local new_expires=""
  if [[ "$expire_days" -gt 0 ]]; then
    new_expires=$(date -v+${expire_days}d +%Y-%m-%d 2>/dev/null || date -d "+${expire_days} days" +%Y-%m-%d 2>/dev/null)
  fi

  local new_metadata="{\"dot_version\":\"2.1\",\"type\":\"${token_type}\""
  [[ -n "$token_subtype" ]] && new_metadata="${new_metadata},\"token_type\":\"${token_subtype}\""
  new_metadata="${new_metadata},\"created\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
  [[ -n "$new_expires" ]] && new_metadata="${new_metadata},\"expires\":\"${new_expires}\""
  new_metadata="${new_metadata},\"rotated_from\":\"${old_expires:-never}\"}"

  # Update token in Bitwarden
  _flow_log_info "Updating token in Bitwarden..."

  local item_id=$(echo "$existing" | jq -r '.id' 2>/dev/null)
  if [[ -z "$item_id" || "$item_id" == "null" ]]; then
    _flow_log_error "Failed to get item ID"
    return 1
  fi

  local updated_item=$(echo "$existing" | jq --arg pw "$new_token" --arg notes "$new_metadata" \
    '.login.password = $pw | .notes = $notes')
  echo "$updated_item" | bw encode | bw edit item "$item_id" --session "$BW_SESSION" >/dev/null 2>&1

  if [[ $? -ne 0 ]]; then
    _flow_log_error "Failed to update token"
    return 1
  fi

  # Sync vault
  bw sync --session "$BW_SESSION" >/dev/null 2>&1

  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[success]}✓ Token rotated successfully${FLOW_COLORS[reset]}                    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Token: ${token_name}                             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Type:  ${token_type}${token_subtype:+ ($token_subtype)}                             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  if [[ -n "$new_expires" ]]; then
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Expires: ${new_expires} (${expire_days} days)                  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  else
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Expires: never                                  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  fi
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Old token has been replaced${FLOW_COLORS[reset]}                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[warning]}⚠ Revoke old token in provider settings${FLOW_COLORS[reset]}        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

# ───────────────────────────────────────────────────────────────────
# GITHUB TOKEN WIZARD
# ───────────────────────────────────────────────────────────────────

_tok_github() {
  local backend=$(_dotf_secret_backend)

  # Only require Bitwarden if backend needs it
  if _dotf_secret_needs_bitwarden; then
    if ! _dotf_require_tool "bw" "brew install bitwarden-cli"; then
      return 1
    fi

    # Check if session is active
    if ! _dotf_bw_session_valid; then
      _flow_log_info "Bitwarden vault is locked. Unlocking..."
      _sec_unlock || return 1
    fi
  fi

  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🔐 GitHub Token Setup${FLOW_COLORS[reset]}                            ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Token type:                                      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}1${FLOW_COLORS[reset]} - Classic PAT (broad permissions)            ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}2${FLOW_COLORS[reset]} - Fine-grained PAT (recommended)             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""

  local token_type=""
  local token_url=""

  read "?Select [1/2]: " type_choice
  case "$type_choice" in
    1)
      token_type="classic"
      token_url="https://github.com/settings/tokens/new"
      echo ""
      echo "${FLOW_COLORS[muted]}Classic PAT selected${FLOW_COLORS[reset]}"
      echo ""
      echo "Recommended scopes:"
      echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} repo        - Full repository access"
      echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} workflow    - GitHub Actions"
      echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} read:org    - Organization access"
      ;;
    2)
      token_type="fine-grained"
      token_url="https://github.com/settings/personal-access-tokens/new"
      echo ""
      echo "${FLOW_COLORS[muted]}Fine-grained PAT selected (recommended)${FLOW_COLORS[reset]}"
      echo ""
      echo "Recommended permissions:"
      echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Contents    - Read and write"
      echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Metadata    - Read-only"
      echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Workflows   - Read and write"
      ;;
    *)
      _flow_log_error "Invalid selection"
      return 1
      ;;
  esac

  echo ""
  _flow_log_info "Press Enter to open GitHub in your browser..."
  read

  # Open browser using AppleScript (more reliable than `open`)
  osascript -e "open location \"$token_url\"" 2>/dev/null || open "$token_url" 2>/dev/null

  echo ""
  echo -n "${FLOW_COLORS[bold]}Paste your new token:${FLOW_COLORS[reset]} "
  local token_value
  read -s token_value
  echo ""

  if [[ -z "$token_value" ]]; then
    _flow_log_error "Token cannot be empty"
    return 1
  fi

  # Validate token format
  if [[ "$token_type" == "classic" && ! "$token_value" =~ ^ghp_ ]]; then
    _flow_log_warning "Token doesn't start with 'ghp_' (expected for classic PAT)"
  elif [[ "$token_type" == "fine-grained" && ! "$token_value" =~ ^github_pat_ ]]; then
    _flow_log_warning "Token doesn't start with 'github_pat_' (expected for fine-grained)"
  fi

  # Validate token with GitHub API
  _flow_log_info "Validating token..."
  local api_response
  api_response=$(curl -s -H "Authorization: token $token_value" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/user" 2>/dev/null)

  if echo "$api_response" | grep -q '"login"'; then
    local username=$(echo "$api_response" | grep -o '"login":"[^"]*"' | cut -d'"' -f4)
    _flow_log_success "Token validated for user: $username"
  else
    _flow_log_error "Token validation failed"
    _flow_log_muted "The token may still work - continue anyway?"
    read -q "?Continue? [y/n] " continue_response
    echo ""
    [[ "$continue_response" != "y" ]] && return 1
  fi

  # Ask for expiration
  echo ""
  read "?Expiration (days, 0=never) [90]: " expire_days
  [[ -z "$expire_days" ]] && expire_days=90

  # Ask for token name (or use passed argument from _tok_rotate)
  local token_name="$1"
  if [[ -z "$token_name" ]]; then
    echo ""
    read "?Token name [github-token]: " token_name
    [[ -z "$token_name" ]] && token_name="github-token"
  else
    echo ""
    _flow_log_info "Using token name: $token_name"
  fi

  # Build metadata (ENHANCED with github_user and expires_days)
  local expire_date=""
  if [[ "$expire_days" -gt 0 ]]; then
    expire_date=$(date -v+${expire_days}d +%Y-%m-%d 2>/dev/null || date -d "+${expire_days} days" +%Y-%m-%d 2>/dev/null)
  fi

  local metadata="{\"dot_version\":\"2.1\",\"type\":\"github\",\"token_type\":\"${token_type}\",\"created\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"expires_days\":${expire_days}"
  [[ -n "$expire_date" ]] && metadata="${metadata},\"expires\":\"${expire_date}\""
  [[ -n "$username" ]] && metadata="${metadata},\"github_user\":\"${username}\""
  metadata="${metadata}}"

  # ─────────────────────────────────────────────────────────────────
  # STORAGE: Based on backend configuration
  # ─────────────────────────────────────────────────────────────────
  # Backend options (set via FLOW_SECRET_BACKEND):
  #   - "keychain" (default): Store only in Keychain, no Bitwarden
  #   - "bitwarden": Store only in Bitwarden (legacy mode)
  #   - "both": Store in both backends for cloud backup
  # ─────────────────────────────────────────────────────────────────

  # Store in Bitwarden (if backend requires it)
  if _dotf_secret_needs_bitwarden; then
    _flow_log_info "Storing token in Bitwarden..."

    # Check if token already exists
    local existing
    existing=$(bw get item "$token_name" --session "$BW_SESSION" 2>/dev/null)

    if [[ -n "$existing" ]]; then
      # Update existing
      local item_id=$(echo "$existing" | jq -r '.id' 2>/dev/null)
      if [[ -n "$item_id" && "$item_id" != "null" ]]; then
        local updated_item=$(echo "$existing" | jq --arg pw "$token_value" --arg notes "$metadata" \
          '.login.password = $pw | .notes = $notes')
        echo "$updated_item" | bw encode | bw edit item "$item_id" --session "$BW_SESSION" >/dev/null 2>&1
      fi
    else
      # Create new
      local new_item=$(cat <<EOF
{
  "type": 1,
  "name": "$token_name",
  "notes": "$metadata",
  "login": {
    "username": "github",
    "password": "$token_value"
  }
}
EOF
)
      echo "$new_item" | bw encode | bw create item --session "$BW_SESSION" >/dev/null 2>&1
    fi

    # Sync vault
    bw sync --session "$BW_SESSION" >/dev/null 2>&1
  fi

  # ─────────────────────────────────────────────────────────────────
  # KEYCHAIN METADATA STORAGE
  # ─────────────────────────────────────────────────────────────────
  # The -j flag stores JSON attributes alongside the password.
  # These attributes are NOT protected like the password itself,
  # but are still encrypted in Keychain's database.
  #
  # Security Model:
  #   -w (password): Protected, requires Touch ID/password to access
  #   -j (JSON):     Searchable metadata for fast expiration checks
  #
  # Why this design?
  #   - Enables checking token expiration WITHOUT decrypting password
  #   - Allows filtering tokens by type/provider without unlock
  #   - Metadata includes: version, type, created date, expiration
  #
  # Example metadata stored:
  #   {"dot_version":"2.1","type":"github","token_type":"classic",
  #    "created":"2025-01-24T14:30:00Z","expires":"2025-04-24",
  #    "github_user":"username"}
  # ─────────────────────────────────────────────────────────────────

  # Store in Keychain (if backend uses it - default)
  # Args: -a account, -s service, -w password, -j JSON metadata, -U update if exists
  if _dotf_secret_uses_keychain; then
    _flow_log_info "Storing in Keychain..."
    security add-generic-password \
      -a "$token_name" \
      -s "$_DOT_KEYCHAIN_SERVICE" \
      -w "$token_value" \
      -j "$metadata" \
      -U 2>/dev/null
  fi

  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[success]}✓ Token stored successfully${FLOW_COLORS[reset]}                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Name: ${token_name}                              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Type: GitHub ${token_type} PAT                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  if [[ -n "$expire_date" ]]; then
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Expires: ${expire_date} (${expire_days} days)                  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  else
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Expires: never                                  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  fi
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Usage:${FLOW_COLORS[reset]}                                          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}GITHUB_TOKEN=\$(sec ${token_name})${FLOW_COLORS[reset]}              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

# ───────────────────────────────────────────────────────────────────
# TOKEN EXPIRATION DETECTION
# ───────────────────────────────────────────────────────────────────

_tok_expiring() {
  _flow_log_info "Checking token expiration status..."

  # Get all GitHub tokens from Keychain
  local secrets=$(sec list 2>/dev/null | grep "•" | sed 's/.*• //')
  local expiring_tokens=()
  local expired_tokens=()

  for secret in ${(f)secrets}; do
    # Only check GitHub tokens
    if [[ "$secret" =~ github ]]; then
      local token=$(sec "$secret" 2>/dev/null)

      # Validate with GitHub API
      local api_response=$(curl -s \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/user" 2>/dev/null)

      if echo "$api_response" | grep -q '"message":"Bad credentials"'; then
        expired_tokens+=("$secret")
      elif echo "$api_response" | grep -q '"login"'; then
        # Check if created 83+ days ago (7-day warning before 90-day expiration)
        local token_age_days=$(_tok_age_days "$secret")
        if [[ $token_age_days -ge 83 ]]; then
          expiring_tokens+=("$secret")
        fi
      fi
    fi
  done

  # Report findings
  if [[ ${#expired_tokens[@]} -gt 0 ]]; then
    _flow_log_error "EXPIRED tokens (need immediate rotation):"
    for token in "${expired_tokens[@]}"; do
      echo "  🔴 $token"
    done
    echo ""
  fi

  if [[ ${#expiring_tokens[@]} -gt 0 ]]; then
    _flow_log_warning "EXPIRING tokens (< 7 days remaining):"
    for token in "${expiring_tokens[@]}"; do
      local days_left=$((90 - $(_tok_age_days "$token")))
      echo "  🟡 $token - $days_left days remaining"
    done
    echo ""
  fi

  if [[ ${#expired_tokens[@]} -eq 0 && ${#expiring_tokens[@]} -eq 0 ]]; then
    _flow_log_success "All GitHub tokens are current"
    return 0
  fi

  # Offer rotation
  if [[ ${#expired_tokens[@]} -gt 0 || ${#expiring_tokens[@]} -gt 0 ]]; then
    echo ""
    read -q "?Rotate tokens now? [y/n] " rotate_response
    echo ""
    if [[ "$rotate_response" == "y" ]]; then
      _tok_rotate
    else
      _flow_log_info "Run ${FLOW_COLORS[cmd]}tok rotate${FLOW_COLORS[reset]} when ready"
    fi
  fi
}

_tok_age_days() {
  local secret_name="$1"

  # ─────────────────────────────────────────────────────────────────
  # KEYCHAIN METADATA RETRIEVAL
  # ─────────────────────────────────────────────────────────────────
  # Retrieves JSON metadata from Keychain WITHOUT decrypting password.
  # The metadata was stored via -j flag (see _tok_github above).
  # This enables fast expiration checks without Touch ID prompts.
  #
  # Note: 'security find-generic-password -g' outputs metadata to stderr
  #       with format: note: <JSON>
  # ─────────────────────────────────────────────────────────────────

  # Get creation timestamp from Keychain item metadata
  # Note: macOS Keychain stores -j JSON in "icmt" (comment) field, not "note"
  local metadata=$(security find-generic-password \
    -a "$secret_name" \
    -s "$_DOT_KEYCHAIN_SERVICE" \
    -g 2>&1 | grep '"icmt"' | sed 's/.*"icmt"<blob>="\(.*\)"/\1/')

  if [[ -z "$metadata" ]]; then
    # No metadata, assume old token (flag for rotation)
    echo 90
    return
  fi

  # Parse creation date from JSON metadata
  local created_date=$(echo "$metadata" | jq -r '.created // empty' 2>/dev/null)
  if [[ -z "$created_date" ]]; then
    echo 90
    return
  fi

  # Calculate days since creation
  local created_epoch=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$created_date" "+%s" 2>/dev/null)
  local now_epoch=$(date +%s)
  local age_seconds=$((now_epoch - created_epoch))
  local age_days=$((age_seconds / 86400))

  echo $age_days
}

# ───────────────────────────────────────────────────────────────────
# TOKEN ROTATION WORKFLOW
# ───────────────────────────────────────────────────────────────────

_tok_rotate() {
  local token_name="${1:-github-token}"

  _flow_log_info "Starting token rotation for: $token_name"

  # Step 1: Verify old token exists
  local old_token=$(sec "$token_name" 2>/dev/null)
  if [[ -z "$old_token" ]]; then
    _flow_log_error "Token '$token_name' not found in Keychain"
    return 1
  fi

  # Step 2: Validate old token (get user info for confirmation)
  local old_token_user=$(curl -s \
    -H "Authorization: token $old_token" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/user" 2>/dev/null | jq -r '.login // "unknown"')

  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🔄 Token Rotation${FLOW_COLORS[reset]}                                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├─────────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Current token: ${token_name}                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  GitHub user: ${old_token_user}                    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[warning]}⚠ This will:${FLOW_COLORS[reset]}                                    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    1. Generate new token (browser)                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    2. Store in Keychain                            ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    3. Validate new token                           ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    4. Keep old token as backup                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""

  read -q "?Continue with rotation? [y/n] " continue_response
  echo ""
  if [[ "$continue_response" != "y" ]]; then
    _flow_log_info "Rotation cancelled"
    return 0
  fi

  # Step 3: Backup old token
  local backup_name="${token_name}-backup-$(date +%Y%m%d)"
  echo "$old_token" | sec add "$backup_name" 2>/dev/null
  _flow_log_info "Old token backed up as: $backup_name"

  # Step 4: Generate new token (use existing wizard)
  _flow_log_info "Step 1/4: Generating new token..."
  echo ""
  echo "Follow the wizard to create a new token."
  echo "Use the SAME scopes as before for consistency."
  echo ""

  # Call existing wizard with token name to avoid name mismatch
  _tok_github "$token_name"

  # Verify new token was created
  local new_token=$(sec "$token_name" 2>/dev/null)
  if [[ -z "$new_token" || "$new_token" == "$old_token" ]]; then
    _flow_log_error "New token creation failed or unchanged"
    _flow_log_info "Restoring old token..."
    echo "$old_token" | sec add "$token_name"
    sec delete "$backup_name" 2>/dev/null
    return 1
  fi

  # Step 5: Validate new token
  _flow_log_info "Step 2/4: Validating new token..."
  local new_token_user=$(curl -s \
    -H "Authorization: token $new_token" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/user" 2>/dev/null | jq -r '.login // empty')

  if [[ -z "$new_token_user" ]]; then
    _flow_log_error "New token validation failed"
    _flow_log_info "Restoring old token..."
    echo "$old_token" | sec add "$token_name"
    sec delete "$backup_name" 2>/dev/null
    return 1
  fi

  # Only warn if old token was valid AND users don't match
  # Skip check if old token was expired (user = "unknown")
  if [[ "$old_token_user" != "unknown" && "$new_token_user" != "$old_token_user" ]]; then
    _flow_log_error "New token user ($new_token_user) doesn't match old token user ($old_token_user)"
    read -q "?Continue anyway? [y/n] " mismatch_continue
    echo ""
    if [[ "$mismatch_continue" != "y" ]]; then
      echo "$old_token" | sec add "$token_name"
      sec delete "$backup_name" 2>/dev/null
      return 1
    fi
  elif [[ "$old_token_user" == "unknown" ]]; then
    _flow_log_info "Old token was expired - skipping user match check"
  fi

  _flow_log_success "New token validated for user: $new_token_user"

  # Step 6: Manual revocation prompt
  _flow_log_info "Step 3/5: Revoke old token on GitHub..."
  echo ""
  echo "${FLOW_COLORS[warning]}Manual Step Required:${FLOW_COLORS[reset]}"
  echo "Visit: ${FLOW_COLORS[cmd]}https://github.com/settings/tokens${FLOW_COLORS[reset]}"
  if [[ "$old_token_user" != "unknown" ]]; then
    echo "Find token for: ${old_token_user}"
    echo "Look for token created before today"
  else
    echo "Look for any expired/old tokens that are no longer needed"
  fi
  echo "Click 'Revoke' to delete old token"
  echo ""

  read -q "?Press 'y' when revocation is complete [y/n] " revoke_confirm
  echo ""

  if [[ "$revoke_confirm" == "y" ]]; then
    # Delete backup token (old token now revoked)
    sec delete "$backup_name" 2>/dev/null
    _flow_log_success "Old token backup removed"
  else
    _flow_log_warning "Old token backup kept at: $backup_name"
    _flow_log_info "Delete manually after revocation: sec delete $backup_name"
  fi

  # Step 7: Log rotation event
  _tok_log_rotation "$token_name" "$new_token_user" "success"

  # Step 8: Sync with gh CLI
  _flow_log_info "Step 4/5: Syncing with gh CLI..."
  _tok_sync_gh

  # Step 9: Update environment variable
  _flow_log_info "Step 5/5: Updating shell environment..."
  echo ""
  _flow_log_warning "Restart your shell to apply changes:"
  echo "  ${FLOW_COLORS[cmd]}exec zsh${FLOW_COLORS[reset]}"
  echo ""

  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[success]}✓ Token Rotation Complete${FLOW_COLORS[reset]}                        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Token: $token_name                                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  User: $new_token_user                             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Next rotation: ~$(date -v+90d +%Y-%m-%d 2>/dev/null || date -d '+90 days' +%Y-%m-%d)          ${FLOW_COLORS[reset]}${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

_tok_log_rotation() {
  local token_name="$1"
  local user="$2"
  local status="$3"

  local log_file="$HOME/.claude/logs/token-rotation.log"
  mkdir -p "$(dirname "$log_file")"

  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  echo "$timestamp | $token_name | $user | $status" >> "$log_file"
}

# ───────────────────────────────────────────────────────────────────
# GH CLI INTEGRATION
# ───────────────────────────────────────────────────────────────────

_tok_sync_gh() {
  _flow_log_info "Syncing token with gh CLI..."

  # Get token from Keychain
  local token=$(sec github-token 2>/dev/null)
  if [[ -z "$token" ]]; then
    _flow_log_error "github-token not found in Keychain"
    _flow_log_info "Add one: ${FLOW_COLORS[cmd]}tok github${FLOW_COLORS[reset]}"
    return 1
  fi

  # Check if gh CLI is installed
  if ! command -v gh &>/dev/null; then
    _flow_log_warning "gh CLI not installed"
    _flow_log_info "Install: ${FLOW_COLORS[cmd]}brew install gh${FLOW_COLORS[reset]}"
    return 1
  fi

  # Authenticate gh with token
  echo "$token" | gh auth login --with-token 2>/dev/null

  if gh auth status &>/dev/null; then
    local gh_user=$(gh api user --jq '.login' 2>/dev/null)
    _flow_log_success "gh CLI authenticated as: $gh_user"
  else
    _flow_log_error "gh authentication failed"
    return 1
  fi
}

# ───────────────────────────────────────────────────────────────────
# NPM TOKEN WIZARD
# ───────────────────────────────────────────────────────────────────

_tok_npm() {
  local backend=$(_dotf_secret_backend)

  # Only require Bitwarden if backend needs it
  if _dotf_secret_needs_bitwarden; then
    if ! _dotf_require_tool "bw" "brew install bitwarden-cli"; then
      return 1
    fi

    # Check if session is active
    if ! _dotf_bw_session_valid; then
      _flow_log_info "Bitwarden vault is locked. Unlocking..."
      _sec_unlock || return 1
    fi
  fi

  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}📦 NPM Token Setup${FLOW_COLORS[reset]}                               ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Token type:                                      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}1${FLOW_COLORS[reset]} - Automation (CI/CD publishing)              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}2${FLOW_COLORS[reset]} - Read-only (install private packages)       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}3${FLOW_COLORS[reset]} - Granular access (fine-grained)             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""

  local token_type=""
  local token_url="https://www.npmjs.com/settings/~/tokens/new"

  read "?Select [1/2/3]: " type_choice
  case "$type_choice" in
    1)
      token_type="automation"
      echo ""
      echo "${FLOW_COLORS[muted]}Automation token selected${FLOW_COLORS[reset]}"
      echo ""
      echo "Best for:"
      echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} CI/CD pipelines (GitHub Actions, etc.)"
      echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Automated package publishing"
      echo "  ${FLOW_COLORS[warning]}!${FLOW_COLORS[reset]} Cannot be used with 2FA"
      ;;
    2)
      token_type="read-only"
      echo ""
      echo "${FLOW_COLORS[muted]}Read-only token selected${FLOW_COLORS[reset]}"
      echo ""
      echo "Best for:"
      echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Installing private packages"
      echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} CI/CD builds (no publish)"
      ;;
    3)
      token_type="granular"
      token_url="https://www.npmjs.com/settings/~/tokens/granular-access-tokens/new"
      echo ""
      echo "${FLOW_COLORS[muted]}Granular access token selected${FLOW_COLORS[reset]}"
      echo ""
      echo "Best for:"
      echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Scoped to specific packages"
      echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Works with 2FA"
      echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Read/write per package"
      ;;
    *)
      _flow_log_error "Invalid selection"
      return 1
      ;;
  esac

  echo ""
  _flow_log_info "Press Enter to open npmjs.com in your browser..."
  read

  # Open browser
  osascript -e "open location \"$token_url\"" 2>/dev/null || open "$token_url" 2>/dev/null

  echo ""
  echo -n "${FLOW_COLORS[bold]}Paste your new token:${FLOW_COLORS[reset]} "
  local token_value
  read -s token_value
  echo ""

  if [[ -z "$token_value" ]]; then
    _flow_log_error "Token cannot be empty"
    return 1
  fi

  # Validate token format
  if [[ ! "$token_value" =~ ^npm_ ]]; then
    _flow_log_warning "Token doesn't start with 'npm_' (expected format)"
  fi

  # Validate token with npm API
  _flow_log_info "Validating token..."
  local api_response
  api_response=$(curl -s -H "Authorization: Bearer $token_value" \
    "https://registry.npmjs.org/-/npm/v1/user" 2>/dev/null)

  if echo "$api_response" | grep -q '"name"'; then
    local username=$(echo "$api_response" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
    _flow_log_success "Token validated for user: $username"
  else
    _flow_log_warning "Could not validate token (this is normal for some token types)"
  fi

  # Ask for expiration
  echo ""
  read "?Expiration (days, 0=never) [90]: " expire_days
  [[ -z "$expire_days" ]] && expire_days=90

  # Ask for token name
  echo ""
  read "?Token name [npm-token]: " token_name
  [[ -z "$token_name" ]] && token_name="npm-token"

  # Build metadata
  local expire_date=""
  if [[ "$expire_days" -gt 0 ]]; then
    expire_date=$(date -v+${expire_days}d +%Y-%m-%d 2>/dev/null || date -d "+${expire_days} days" +%Y-%m-%d 2>/dev/null)
  fi

  local metadata="{\"dot_version\":\"2.0\",\"type\":\"npm\",\"token_type\":\"${token_type}\",\"created\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
  [[ -n "$expire_date" ]] && metadata="${metadata},\"expires\":\"${expire_date}\""
  metadata="${metadata}}"

  # Store in Bitwarden (if backend requires it)
  if _dotf_secret_needs_bitwarden; then
    _flow_log_info "Storing token in Bitwarden..."

    # Check if token already exists
    local existing
    existing=$(bw get item "$token_name" --session "$BW_SESSION" 2>/dev/null)

    if [[ -n "$existing" ]]; then
      local item_id=$(echo "$existing" | jq -r '.id' 2>/dev/null)
      if [[ -n "$item_id" && "$item_id" != "null" ]]; then
        local updated_item=$(echo "$existing" | jq --arg pw "$token_value" --arg notes "$metadata" \
          '.login.password = $pw | .notes = $notes')
        echo "$updated_item" | bw encode | bw edit item "$item_id" --session "$BW_SESSION" >/dev/null 2>&1
      fi
    else
      local new_item=$(cat <<EOF
{
  "type": 1,
  "name": "$token_name",
  "notes": "$metadata",
  "login": {
    "username": "npm",
    "password": "$token_value"
  }
}
EOF
)
      echo "$new_item" | bw encode | bw create item --session "$BW_SESSION" >/dev/null 2>&1
    fi

    # Sync vault
    bw sync --session "$BW_SESSION" >/dev/null 2>&1
  fi

  # Store in Keychain (if backend uses it - default)
  if _dotf_secret_uses_keychain; then
    _flow_log_info "Storing in Keychain..."
    security add-generic-password \
      -a "$token_name" \
      -s "$_DOT_KEYCHAIN_SERVICE" \
      -w "$token_value" \
      -j "$metadata" \
      -U 2>/dev/null
  fi

  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[success]}✓ Token stored successfully${FLOW_COLORS[reset]}                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Name: ${token_name}                                 ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Type: NPM ${token_type} token                      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  if [[ -n "$expire_date" ]]; then
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Expires: ${expire_date} (${expire_days} days)                  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  else
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Expires: never                                  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  fi
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Usage:${FLOW_COLORS[reset]}                                          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}NPM_TOKEN=\$(sec ${token_name})${FLOW_COLORS[reset]}                 ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[muted]}# or in .npmrc:${FLOW_COLORS[reset]}                               ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}//registry.npmjs.org/:_authToken=\${NPM_TOKEN}${FLOW_COLORS[reset]}${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

# ───────────────────────────────────────────────────────────────────
# PYPI TOKEN WIZARD
# ───────────────────────────────────────────────────────────────────

_tok_pypi() {
  local backend=$(_dotf_secret_backend)

  # Only require Bitwarden if backend needs it
  if _dotf_secret_needs_bitwarden; then
    if ! _dotf_require_tool "bw" "brew install bitwarden-cli"; then
      return 1
      _flow_log_info "Bitwarden vault is locked. Unlocking..."
      _sec_unlock || return 1
    fi
  fi

  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🐍 PyPI Token Setup${FLOW_COLORS[reset]}                              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Token scope:                                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}1${FLOW_COLORS[reset]} - Account-wide (all projects)               ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}2${FLOW_COLORS[reset]} - Project-scoped (recommended)              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Note: For CI/CD, consider Trusted Publishing${FLOW_COLORS[reset]}   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}(no tokens needed - GitHub OIDC auth)${FLOW_COLORS[reset]}          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""

  local token_type=""
  local token_url="https://pypi.org/manage/account/token/"

  read "?Select [1/2]: " type_choice
  case "$type_choice" in
    1)
      token_type="account"
      echo ""
      echo "${FLOW_COLORS[muted]}Account-wide token selected${FLOW_COLORS[reset]}"
      echo ""
      echo "Best for:"
      echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Publishing multiple packages"
      echo "  ${FLOW_COLORS[warning]}!${FLOW_COLORS[reset]} Higher risk if compromised"
      ;;
    2)
      token_type="project"
      echo ""
      echo "${FLOW_COLORS[muted]}Project-scoped token selected (recommended)${FLOW_COLORS[reset]}"
      echo ""
      echo "Best for:"
      echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Single package publishing"
      echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Limited blast radius"
      ;;
    *)
      _flow_log_error "Invalid selection"
      return 1
      ;;
  esac

  echo ""
  _flow_log_info "Press Enter to open pypi.org in your browser..."
  read

  # Open browser
  osascript -e "open location \"$token_url\"" 2>/dev/null || open "$token_url" 2>/dev/null

  echo ""
  echo -n "${FLOW_COLORS[bold]}Paste your new token:${FLOW_COLORS[reset]} "
  local token_value
  read -s token_value
  echo ""

  if [[ -z "$token_value" ]]; then
    _flow_log_error "Token cannot be empty"
    return 1
  fi

  # Validate token format
  if [[ ! "$token_value" =~ ^pypi- ]]; then
    _flow_log_warning "Token doesn't start with 'pypi-' (expected format)"
  fi

  _flow_log_success "Token format validated"

  # Ask for project name if project-scoped
  local project_name=""
  if [[ "$token_type" == "project" ]]; then
    echo ""
    read "?Project name (for reference): " project_name
  fi

  # Ask for token name
  echo ""
  local default_name="pypi-token"
  [[ -n "$project_name" ]] && default_name="pypi-${project_name}"
  read "?Token name [${default_name}]: " token_name
  [[ -z "$token_name" ]] && token_name="$default_name"

  # PyPI tokens don't expire by default, but user might set calendar reminder
  echo ""
  read "?Reminder (days until you want to rotate, 0=none) [180]: " expire_days
  [[ -z "$expire_days" ]] && expire_days=180

  # Build metadata
  local expire_date=""
  if [[ "$expire_days" -gt 0 ]]; then
    expire_date=$(date -v+${expire_days}d +%Y-%m-%d 2>/dev/null || date -d "+${expire_days} days" +%Y-%m-%d 2>/dev/null)
  fi

  local metadata="{\"dot_version\":\"2.0\",\"type\":\"pypi\",\"token_type\":\"${token_type}\",\"created\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
  [[ -n "$project_name" ]] && metadata="${metadata},\"project\":\"${project_name}\""
  [[ -n "$expire_date" ]] && metadata="${metadata},\"expires\":\"${expire_date}\""
  metadata="${metadata}}"

  # Store in Bitwarden (if backend requires it)
  if _dotf_secret_needs_bitwarden; then
    _flow_log_info "Storing token in Bitwarden..."

    # Check if token already exists
    local existing
    existing=$(bw get item "$token_name" --session "$BW_SESSION" 2>/dev/null)

    if [[ -n "$existing" ]]; then
      local item_id=$(echo "$existing" | jq -r '.id' 2>/dev/null)
      if [[ -n "$item_id" && "$item_id" != "null" ]]; then
        local updated_item=$(echo "$existing" | jq --arg pw "$token_value" --arg notes "$metadata" \
          '.login.password = $pw | .notes = $notes')
        echo "$updated_item" | bw encode | bw edit item "$item_id" --session "$BW_SESSION" >/dev/null 2>&1
      fi
    else
      local new_item=$(cat <<EOF
{
  "type": 1,
  "name": "$token_name",
  "notes": "$metadata",
  "login": {
    "username": "pypi",
    "password": "$token_value"
  }
}
EOF
)
      echo "$new_item" | bw encode | bw create item --session "$BW_SESSION" >/dev/null 2>&1
    fi

    # Sync vault
    bw sync --session "$BW_SESSION" >/dev/null 2>&1
  fi

  # Store in Keychain (if backend uses it - default)
  if _dotf_secret_uses_keychain; then
    _flow_log_info "Storing in Keychain..."
    security add-generic-password \
      -a "$token_name" \
      -s "$_DOT_KEYCHAIN_SERVICE" \
      -w "$token_value" \
      -j "$metadata" \
      -U 2>/dev/null
  fi

  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[success]}✓ Token stored successfully${FLOW_COLORS[reset]}                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Name: ${token_name}                               ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Type: PyPI ${token_type} token                    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  if [[ -n "$expire_date" ]]; then
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Reminder: ${expire_date} (rotate token)           ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  fi
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Usage:${FLOW_COLORS[reset]}                                          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}TWINE_PASSWORD=\$(sec ${token_name})${FLOW_COLORS[reset]}           ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}TWINE_USERNAME=__token__${FLOW_COLORS[reset]}                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Tip: For CI, consider Trusted Publishing${FLOW_COLORS[reset]}       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}(GitHub OIDC - no tokens needed)${FLOW_COLORS[reset]}               ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

# ───────────────────────────────────────────────────────────────────
# TOKEN DOCTOR - Health check placeholder
# ───────────────────────────────────────────────────────────────────

_tok_doctor() {
  _flow_log_info "Token health check..."
  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🩺 TOK DOCTOR${FLOW_COLORS[reset]}                                    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Token-specific diagnostics coming soon.${FLOW_COLORS[reset]}         ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  For now, use:                                    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}tok expiring${FLOW_COLORS[reset]}       Check token status           ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}tok sync gh${FLOW_COLORS[reset]}        Verify gh CLI sync           ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}
