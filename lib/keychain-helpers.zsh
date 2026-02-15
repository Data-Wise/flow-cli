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
# Function: _dotf_kc_add
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
#   _dotf_kc_add "github-token"     # Prompts for value, stores in Keychain
#   _dotf_kc_add "openai-api-key"   # Updates if already exists (-U flag)
#
# Notes:
#   - Uses hidden input (read -s) for secure value entry
#   - Automatically updates existing secrets (security -U flag)
#   - Stores under service name "flow-cli-secrets" for namespacing
#   - Touch ID / Apple Watch authentication may be required on retrieval
# =============================================================================
_dotf_kc_add() {
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
# Function: _dotf_kc_get
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
#   _dotf_kc_get "github-token"                    # Outputs: ghp_xxxx...
#   export GITHUB_TOKEN=$(_dotf_kc_get "github")   # Capture into variable
#   gh auth login --with-token <<< $(_dotf_kc_get "github-token")
#
# Notes:
#   - Output is raw value only (no decoration) for script compatibility
#   - May trigger Touch ID / Apple Watch / password prompt
#   - Searches only within "flow-cli-secrets" service namespace
# =============================================================================
_dotf_kc_get() {
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
# Function: _dotf_kc_list
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
#   _dotf_kc_list
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
_dotf_kc_list() {
    # Reset shell options to defaults (suppress debug, protect passwords)
    emulate -L zsh
    setopt noxtrace noverbose

    # Extract secret names in subshell to prevent debug output from tracing
    # This isolates variable assignments from any shell hooks that might log them
    local secrets_raw
    secrets_raw=$(
        emulate -L zsh
        setopt noxtrace noverbose

        local dump_file=$(mktemp)
        security dump-keychain > "$dump_file" 2>/dev/null

        local svc_lines=$(grep -n "\"svce\"<blob>=\"$_DOT_KEYCHAIN_SERVICE\"" "$dump_file" 2>/dev/null | cut -d: -f1)

        for line_num in ${(f)svc_lines}; do
            local start_line=$((line_num - 20))
            [[ $start_line -lt 1 ]] && start_line=1

            local acct_line=$(sed -n "${start_line},${line_num}p" "$dump_file" | grep '"acct"<blob>="' | tail -1)

            if [[ -n "$acct_line" ]]; then
                local account_name="${acct_line#*\"acct\"<blob>=\"}"
                account_name="${account_name%%\"*}"
                [[ -n "$account_name" ]] && echo "$account_name"
            fi
        done

        rm -f "$dump_file"
    )

    # Parse the output into array
    local -a secrets=()
    local found_any=false
    if [[ -n "$secrets_raw" ]]; then
        secrets=("${(f)secrets_raw}")
        found_any=true
    fi

    if [[ "$found_any" != true ]]; then
        echo ""
        echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🔐 Secrets (Keychain)${FLOW_COLORS[reset]}                            ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}(no secrets stored)${FLOW_COLORS[reset]}                             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Add one: ${FLOW_COLORS[cmd]}dot secret add <name>${FLOW_COLORS[reset]}                 ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
        return 0
    fi

    # Get unique secrets and fetch metadata
    local -a unique_secrets=("${(u)secrets[@]}")
    local today_epoch=$(date +%s)

    # Track tokens needing attention (for rotation hints)
    local -a _expired_tokens=()
    local -a _expiring_tokens=()

    # Separate active secrets from backups
    local -a active_secrets=()
    local -a backup_secrets=()
    for secret in "${unique_secrets[@]}"; do
        if [[ "$secret" == *"-backup-"* ]]; then
            backup_secrets+=("$secret")
        else
            active_secrets+=("$secret")
        fi
    done

    echo ""
    echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🔐 Secrets (Keychain)${FLOW_COLORS[reset]}                            ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"

    # Display active secrets first
    for secret in "${active_secrets[@]}"; do
        # Get metadata from keychain in subshell to prevent debug output leaking passwords
        # The subshell isolates any shell tracing from exposing sensitive data
        local metadata=""
        metadata=$(
            # Suppress all tracing in subshell
            emulate -L zsh
            setopt noxtrace noverbose
            unset -f preexec precmd 2>/dev/null

            local kc_output
            kc_output=$(security find-generic-password -a "$secret" -s "$_DOT_KEYCHAIN_SERVICE" -g 2>&1)

            # Extract JSON from icmt field (contains metadata like type, expires)
            if [[ "$kc_output" == *'"icmt"<blob>="{'* ]]; then
                local m="${kc_output#*\"icmt\"<blob>=\"}"
                echo "${m%%\}\"*}}"
            fi
        )

        # Parse metadata
        local type_icon="🔑"
        local type_label=""
        local expires=""
        local status_icon=""
        local status_text=""

        if [[ -n "$metadata" && "$metadata" == "{"* ]]; then
            # Extract type
            local token_type=""
            if [[ "$metadata" == *'"type":"github"'* ]]; then
                type_icon="🐙"
                type_label="GitHub"
                if [[ "$metadata" == *'"token_type":"classic"'* ]]; then
                    type_label="GitHub PAT"
                elif [[ "$metadata" == *'"token_type":"fine-grained"'* ]]; then
                    type_label="GitHub FG"
                fi
            elif [[ "$metadata" == *'"type":"npm"'* ]]; then
                type_icon="📦"
                type_label="npm"
            elif [[ "$metadata" == *'"type":"pypi"'* ]]; then
                type_icon="🐍"
                type_label="PyPI"
            fi

            # Extract expiration
            if [[ "$metadata" == *'"expires":"'* ]]; then
                expires="${metadata#*\"expires\":\"}"
                expires="${expires%%\"*}"

                # Calculate days remaining
                local expire_epoch=$(date -j -f "%Y-%m-%d" "$expires" +%s 2>/dev/null)
                if [[ -n "$expire_epoch" ]]; then
                    local days_left=$(( (expire_epoch - today_epoch) / 86400 ))

                    if [[ $days_left -lt 0 ]]; then
                        status_icon="${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]}"
                        status_text="${FLOW_COLORS[error]}expired${FLOW_COLORS[reset]}"
                        _expired_tokens+=("$secret")
                    elif [[ $days_left -le 7 ]]; then
                        status_icon="${FLOW_COLORS[warning]}!${FLOW_COLORS[reset]}"
                        status_text="${FLOW_COLORS[warning]}${days_left}d left${FLOW_COLORS[reset]}"
                        _expiring_tokens+=("$secret")
                    elif [[ $days_left -le 30 ]]; then
                        status_icon="${FLOW_COLORS[warning]}○${FLOW_COLORS[reset]}"
                        status_text="${FLOW_COLORS[muted]}${days_left}d left${FLOW_COLORS[reset]}"
                    else
                        status_icon="${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]}"
                        status_text="${FLOW_COLORS[muted]}${days_left}d left${FLOW_COLORS[reset]}"
                    fi
                fi
            elif [[ "$metadata" == *'"expires_days":0'* ]]; then
                status_icon="${FLOW_COLORS[success]}∞${FLOW_COLORS[reset]}"
                status_text="${FLOW_COLORS[muted]}no expiry${FLOW_COLORS[reset]}"
            fi
        fi

        # Format output row
        local name_col=$(printf "%-20s" "$secret")
        local type_col=""
        local status_col=""

        if [[ -n "$type_label" ]]; then
            type_col=$(printf "%-12s" "$type_label")
        else
            type_col=$(printf "%-12s" "secret")
        fi

        if [[ -n "$status_text" ]]; then
            echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  $status_icon $type_icon ${name_col} ${FLOW_COLORS[muted]}${type_col}${FLOW_COLORS[reset]} $status_text  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
        else
            echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  $type_icon ${name_col} ${FLOW_COLORS[muted]}${type_col}${FLOW_COLORS[reset]}              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
        fi
    done

    # Show backup section if there are any
    if [[ ${#backup_secrets[@]} -gt 0 ]]; then
        echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}📋 Backups (from rotation)${FLOW_COLORS[reset]}                      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"

        for backup in "${backup_secrets[@]}"; do
            # Extract date from backup name (format: token-name-backup-YYYYMMDD)
            local backup_date=""
            if [[ "$backup" =~ -backup-([0-9]{8})$ ]]; then
                local date_str="${match[1]}"
                backup_date=$(date -j -f "%Y%m%d" "$date_str" "+%Y-%m-%d" 2>/dev/null)
            fi

            local name_col=$(printf "%-25s" "$backup")
            if [[ -n "$backup_date" ]]; then
                echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  📋 ${FLOW_COLORS[muted]}${name_col}${FLOW_COLORS[reset]} ${backup_date}    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
            else
                echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  📋 ${FLOW_COLORS[muted]}${name_col}${FLOW_COLORS[reset]}              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
            fi
        done

        echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Cleanup old backups:${FLOW_COLORS[reset]}                            ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
        for backup in "${backup_secrets[@]}"; do
            echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot secret delete $backup${FLOW_COLORS[reset]}${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
        done
    fi

    echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Total: ${#active_secrets[@]} active, ${#backup_secrets[@]} backup(s)${FLOW_COLORS[reset]}               ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

    # Show hints if any active tokens need attention
    if [[ ${#_expired_tokens[@]} -gt 0 || ${#_expiring_tokens[@]} -gt 0 ]]; then
        echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
        if [[ ${#_expired_tokens[@]} -gt 0 ]]; then
            echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[error]}⚠ ${#_expired_tokens[@]} expired${FLOW_COLORS[reset]} - rotate now:                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
            for token in "${_expired_tokens[@]}"; do
                echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot token rotate $token${FLOW_COLORS[reset]}              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
            done
        fi
        if [[ ${#_expiring_tokens[@]} -gt 0 ]]; then
            echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[warning]}⚠ ${#_expiring_tokens[@]} expiring soon${FLOW_COLORS[reset]} - consider rotating:    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
            for token in "${_expiring_tokens[@]}"; do
                echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot token rotate $token${FLOW_COLORS[reset]}              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
            done
        fi
    fi

    echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"

    # Clean up tracking arrays
    unset _expired_tokens _expiring_tokens
}

# =============================================================================
# Function: _dotf_kc_delete
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
#   _dotf_kc_delete "old-api-key"    # Removes secret from Keychain
#   _dotf_kc_delete "nonexistent"    # Returns error, secret not found
#
# Notes:
#   - Permanent deletion - cannot be undone
#   - Only deletes secrets within "flow-cli-secrets" service namespace
#   - May require authentication depending on Keychain settings
# =============================================================================
_dotf_kc_delete() {
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
# Function: _dotf_kc_import
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
#   _dotf_kc_import
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
_dotf_kc_import() {
    # Check for Bitwarden CLI
    if ! command -v bw &>/dev/null; then
        _flow_log_error "Bitwarden CLI not installed"
        _flow_log_info "Install: ${FLOW_COLORS[cmd]}brew install bitwarden-cli${FLOW_COLORS[reset]}"
        return 1
    fi

    # Check for active session
    if ! _dotf_bw_session_valid 2>/dev/null; then
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
# Function: _dotf_kc_help
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
#   _dotf_kc_help
#   dot secret help
#   dot secret --help
#
# Notes:
#   - Uses FLOW_COLORS for consistent formatting
#   - Shows all available subcommands with descriptions
#   - Includes script usage examples for common patterns
#   - Highlights benefits of Keychain over Bitwarden (instant access)
# =============================================================================
_dotf_kc_help() {
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

# Note: The _dotf_secret_kc() function has been removed as dead code.
# All routing is now handled by sec() in lib/dispatchers/sec-dispatcher.zsh
# The helper functions below (_dotf_kc_add, _dotf_kc_get, etc.) are used by dots, sec, tok dispatchers.
