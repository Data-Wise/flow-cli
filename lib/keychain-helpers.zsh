# lib/keychain-helpers.zsh - macOS Keychain secret management
# Provides: instant, session-free secret access with Touch ID support
#
# Commands:
#   dot secret add <name>      Store a secret (prompts for value)
#   dot secret get <name>      Retrieve a secret
#   dot secret <name>          Shortcut for 'get'
#   dot secret list            List all stored secrets
#   dot secret delete <name>   Remove a secret
#   dot secret import          Import from Bitwarden (one-time)

# ============================================================================
# CONSTANTS
# ============================================================================

# Service name used to identify flow-cli secrets in Keychain
_DOT_KEYCHAIN_SERVICE="flow-cli-secrets"

# ============================================================================
# KEYCHAIN FUNCTIONS
# ============================================================================

# =============================================================================
# Function: _dot_kc_add
# Purpose: Add or update a secret in macOS Keychain with interactive prompt
# =============================================================================
# Arguments:
#   $1 - (required) Name of the secret (e.g., "github-token", "api-key")
#
# Returns:
#   0 - Secret successfully stored in Keychain
#   1 - Error (missing name, empty value, or Keychain failure)
#
# Output:
#   stdout - Success/error messages via _flow_log_* functions
#
# Example:
#   _dot_kc_add "github-token"     # Prompts for value, stores in Keychain
#   _dot_kc_add "openai-api-key"   # Updates if already exists (-U flag)
#
# Notes:
#   - Uses hidden input (read -s) for secure value entry
#   - Automatically updates existing secrets (security -U flag)
#   - Stores under service name "flow-cli-secrets" for namespacing
#   - Touch ID / Apple Watch authentication may be required on retrieval
# =============================================================================
_dot_kc_add() {
    local name="$1"

    if [[ -z "$name" ]]; then
        _flow_log_error "Usage: dot secret add <name>"
        return 1
    fi

    # Prompt for secret (hidden input)
    echo -n "Enter secret value: "
    local secret_value
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

# =============================================================================
# Function: _dot_kc_get
# Purpose: Retrieve a secret value from macOS Keychain
# =============================================================================
# Arguments:
#   $1 - (required) Name of the secret to retrieve
#
# Returns:
#   0 - Secret found and output
#   1 - Error (missing name or secret not found)
#
# Output:
#   stdout - Raw secret value (no formatting, suitable for piping/capture)
#   stderr - Error messages if secret not found
#
# Example:
#   _dot_kc_get "github-token"                    # Outputs: ghp_xxxx...
#   export GITHUB_TOKEN=$(_dot_kc_get "github")   # Capture into variable
#   gh auth login --with-token <<< $(_dot_kc_get "github-token")
#
# Notes:
#   - Output is raw value only (no decoration) for script compatibility
#   - May trigger Touch ID / Apple Watch / password prompt
#   - Searches only within "flow-cli-secrets" service namespace
# =============================================================================
_dot_kc_get() {
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

# =============================================================================
# Function: _dot_kc_list
# Purpose: List all flow-cli secrets stored in macOS Keychain
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always (even if no secrets found)
#
# Output:
#   stdout - Formatted list of secret names with bullet points
#            Shows "(no secrets stored)" message if empty
#
# Example:
#   _dot_kc_list
#   # Output:
#   # Secrets in Keychain (flow-cli):
#   #   • github-token
#   #   • openai-api-key
#   #   • anthropic-key
#
# Notes:
#   - Uses security dump-keychain to scan all entries
#   - Filters to only show secrets with "flow-cli-secrets" service
#   - Creates temp file for parsing (cleaned up automatically)
#   - Shows unique secrets only (deduplicates)
#   - Does NOT show secret values, only names
# =============================================================================
_dot_kc_list() {
    _flow_log_info "Secrets in Keychain (flow-cli):"

    # Extract secrets with our service from keychain
    # Use grep to find service blocks, then extract account names
    local dump_file
    dump_file=$(mktemp)
    security dump-keychain > "$dump_file" 2>/dev/null

    local found_any=false
    local -a secrets=()

    # Find line numbers where our service appears
    local svc_lines
    svc_lines=$(grep -n "\"svce\"<blob>=\"$_DOT_KEYCHAIN_SERVICE\"" "$dump_file" 2>/dev/null | cut -d: -f1)

    for line_num in ${(f)svc_lines}; do
        # Look backwards from service line to find the account name
        # Account line appears before service line in the same entry
        local start_line=$((line_num - 20))
        [[ $start_line -lt 1 ]] && start_line=1

        local acct_line
        acct_line=$(sed -n "${start_line},${line_num}p" "$dump_file" | grep '"acct"<blob>="' | tail -1)

        if [[ -n "$acct_line" ]]; then
            local account_name
            account_name="${acct_line#*\"acct\"<blob>=\"}"
            account_name="${account_name%%\"*}"
            if [[ -n "$account_name" ]]; then
                secrets+=("$account_name")
                found_any=true
            fi
        fi
    done

    rm -f "$dump_file"

    # Print unique secrets
    if [[ "$found_any" == true ]]; then
        for secret in "${(u)secrets[@]}"; do
            echo "  • $secret"
        done
    else
        _flow_log_muted "  (no secrets stored)"
        _flow_log_info "Add one with: ${FLOW_COLORS[cmd]}dot secret add <name>${FLOW_COLORS[reset]}"
    fi
}

# =============================================================================
# Function: _dot_kc_delete
# Purpose: Remove a secret from macOS Keychain
# =============================================================================
# Arguments:
#   $1 - (required) Name of the secret to delete
#
# Returns:
#   0 - Secret successfully deleted
#   1 - Error (missing name or secret not found)
#
# Output:
#   stdout - Success/error message via _flow_log_* functions
#
# Example:
#   _dot_kc_delete "old-api-key"    # Removes secret from Keychain
#   _dot_kc_delete "nonexistent"    # Returns error, secret not found
#
# Notes:
#   - Permanent deletion - cannot be undone
#   - Only deletes secrets within "flow-cli-secrets" service namespace
#   - May require authentication depending on Keychain settings
# =============================================================================
_dot_kc_delete() {
    local name="$1"

    if [[ -z "$name" ]]; then
        _flow_log_error "Usage: dot secret delete <name>"
        return 1
    fi

    if security delete-generic-password \
        -a "$name" \
        -s "$_DOT_KEYCHAIN_SERVICE" &>/dev/null; then
        _flow_log_success "Secret '$name' deleted"
    else
        _flow_log_error "Secret '$name' not found"
        return 1
    fi
}

# =============================================================================
# Function: _dot_kc_import
# Purpose: Bulk import secrets from Bitwarden folder into macOS Keychain
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Import completed (or cancelled by user)
#   1 - Error (Bitwarden CLI missing, not logged in, or folder not found)
#
# Output:
#   stdout - Progress messages showing each imported secret
#            Summary count of imported secrets
#
# Example:
#   _dot_kc_import
#   # Output:
#   # Import secrets from Bitwarden folder 'flow-cli-secrets'?
#   # Continue? [y/N] y
#   # ✓ Imported: github-token
#   # ✓ Imported: openai-api-key
#   # ✓ Imported 2 secret(s) to Keychain
#
# Notes:
#   - Requires Bitwarden CLI (bw) installed and unlocked
#   - Expects a folder named "flow-cli-secrets" in Bitwarden
#   - Uses item name as secret name, password field as value
#   - Falls back to notes field if password is empty
#   - Updates existing secrets (does not duplicate)
#   - One-time migration - after import, use Keychain directly
# =============================================================================
_dot_kc_import() {
    # Check for Bitwarden CLI
    if ! command -v bw &>/dev/null; then
        _flow_log_error "Bitwarden CLI not installed"
        _flow_log_info "Install: ${FLOW_COLORS[cmd]}brew install bitwarden-cli${FLOW_COLORS[reset]}"
        return 1
    fi

    # Check for active session
    if ! _dot_bw_session_valid 2>/dev/null; then
        _flow_log_error "Bitwarden locked. Run: ${FLOW_COLORS[cmd]}dot unlock${FLOW_COLORS[reset]}"
        return 1
    fi

    _flow_log_info "Import secrets from Bitwarden folder 'flow-cli-secrets'?"
    echo -n "Continue? [y/N] "
    local confirm
    read -r confirm
    [[ "$confirm" != [yY]* ]] && return 0

    # Get folder ID
    local folder_id
    folder_id=$(bw list folders --session "$BW_SESSION" 2>/dev/null | \
        jq -r '.[] | select(.name=="flow-cli-secrets") | .id')

    if [[ -z "$folder_id" ]]; then
        _flow_log_error "Folder 'flow-cli-secrets' not found in Bitwarden"
        _flow_log_info "Create a folder named 'flow-cli-secrets' in Bitwarden first"
        return 1
    fi

    # Import each item (use process substitution to avoid subshell count loss)
    local count=0
    local name password

    while IFS=$'\t' read -r name password; do
        if [[ -n "$name" && -n "$password" ]]; then
            security add-generic-password \
                -a "$name" \
                -s "$_DOT_KEYCHAIN_SERVICE" \
                -w "$password" \
                -U 2>/dev/null
            _flow_log_success "Imported: $name"
            ((count++))
        fi
    done < <(bw list items --folderid "$folder_id" --session "$BW_SESSION" 2>/dev/null | \
        jq -r '.[] | "\(.name)\t\(.login.password // .notes)"')

    if [[ $count -gt 0 ]]; then
        _flow_log_success "Imported $count secret(s) to Keychain"
    else
        _flow_log_warning "No secrets found to import"
    fi
}

# =============================================================================
# Function: _dot_kc_help
# Purpose: Display help documentation for keychain secret commands
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Formatted help text with commands, examples, and benefits
#
# Example:
#   _dot_kc_help
#   dot secret help
#   dot secret --help
#
# Notes:
#   - Uses FLOW_COLORS for consistent formatting
#   - Shows all available subcommands with descriptions
#   - Includes script usage examples for common patterns
#   - Highlights benefits of Keychain over Bitwarden (instant access)
# =============================================================================
_dot_kc_help() {
    cat <<EOF
${FLOW_COLORS[header]}dot secret${FLOW_COLORS[reset]} - macOS Keychain secret management

${FLOW_COLORS[warning]}Commands:${FLOW_COLORS[reset]}
  dot secret add <name>      Store a secret (prompts for value)
  dot secret get <name>      Retrieve a secret (or just: dot secret <name>)
  dot secret <name>          Shortcut for 'get'
  dot secret list            List all stored secrets
  dot secret delete <name>   Remove a secret
  dot secret status          Show backend configuration
  dot secret sync            Sync with Bitwarden (--to-bw, --from-bw)
  dot secret import          Import from Bitwarden (one-time)
  dot secret tutorial        Interactive tutorial (10-15 min)

${FLOW_COLORS[warning]}Backend Configuration:${FLOW_COLORS[reset]}
  export FLOW_SECRET_BACKEND=keychain   # Default (Keychain only)
  export FLOW_SECRET_BACKEND=bitwarden  # Bitwarden only (legacy)
  export FLOW_SECRET_BACKEND=both       # Both backends (sync mode)

${FLOW_COLORS[warning]}Examples:${FLOW_COLORS[reset]}
  dot secret add github-token    # Store GitHub token
  dot secret github-token        # Retrieve it
  dot secret list                # See all secrets
  dot secret status              # Check backend config
  dot secret sync --status       # Compare Keychain vs Bitwarden

${FLOW_COLORS[warning]}Usage in scripts:${FLOW_COLORS[reset]}
  export GITHUB_TOKEN=\$(dot secret github-token)
  gh auth login --with-token <<< \$(dot secret github-token)

${FLOW_COLORS[warning]}Benefits (Keychain default):${FLOW_COLORS[reset]}
  ${FLOW_COLORS[success]}\342\200\242${FLOW_COLORS[reset]} Instant access (no unlock needed)
  ${FLOW_COLORS[success]}\342\200\242${FLOW_COLORS[reset]} Touch ID / Apple Watch support
  ${FLOW_COLORS[success]}\342\200\242${FLOW_COLORS[reset]} Auto-locks with screen lock
  ${FLOW_COLORS[success]}\342\200\242${FLOW_COLORS[reset]} Works offline

${FLOW_COLORS[muted]}Secrets stored in: macOS Keychain (service: $_DOT_KEYCHAIN_SERVICE)${FLOW_COLORS[reset]}
EOF
}

# ============================================================================
# DISPATCHER INTEGRATION
# ============================================================================

# Note: The _dot_secret_kc() function has been removed as dead code.
# All routing is now handled by _dot_secret() in lib/dispatchers/dot-dispatcher.zsh
# The helper functions below (_dot_kc_add, _dot_kc_get, etc.) are still used.
