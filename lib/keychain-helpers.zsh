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

# Add a secret to Keychain
# Usage: _dot_kc_add <name>
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

# Retrieve a secret from Keychain
# Usage: _dot_kc_get <name>
# Output: Secret value (stdout, silent - no decorations)
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

# List all flow-cli secrets in Keychain
# Usage: _dot_kc_list
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

# Delete a secret from Keychain
# Usage: _dot_kc_delete <name>
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

# Import secrets from Bitwarden folder into Keychain
# Usage: _dot_kc_import
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

# Show help for keychain secret commands
# Usage: _dot_kc_help
_dot_kc_help() {
    cat <<EOF
${FLOW_COLORS[header]}dot secret${FLOW_COLORS[reset]} - macOS Keychain secret management

${FLOW_COLORS[warning]}Commands:${FLOW_COLORS[reset]}
  dot secret add <name>      Store a secret (prompts for value)
  dot secret get <name>      Retrieve a secret (or just: dot secret <name>)
  dot secret <name>          Shortcut for 'get'
  dot secret list            List all stored secrets
  dot secret delete <name>   Remove a secret
  dot secret import          Import from Bitwarden (one-time)

${FLOW_COLORS[warning]}Examples:${FLOW_COLORS[reset]}
  dot secret add github-token    # Store GitHub token
  dot secret github-token        # Retrieve it
  dot secret list                # See all secrets

${FLOW_COLORS[warning]}Usage in scripts:${FLOW_COLORS[reset]}
  export GITHUB_TOKEN=\$(dot secret github-token)
  gh auth login --with-token <<< \$(dot secret github-token)

${FLOW_COLORS[warning]}Benefits:${FLOW_COLORS[reset]}
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

# Main router for dot secret commands
# This replaces the Bitwarden-based _dot_secret for local Keychain operations
_dot_secret_kc() {
    local subcommand="$1"
    shift 2>/dev/null  # Safe shift even if no args

    case "$subcommand" in
        add|new)
            _dot_kc_add "$@"
            ;;

        get)
            _dot_kc_get "$@"
            ;;

        list|ls)
            _dot_kc_list
            ;;

        delete|rm|remove)
            _dot_kc_delete "$@"
            ;;

        import)
            _dot_kc_import
            ;;

        help|--help|-h)
            _dot_kc_help
            ;;

        "")
            _dot_kc_help
            ;;

        *)
            # Default: treat as secret name (get operation)
            _dot_kc_get "$subcommand"
            ;;
    esac
}
