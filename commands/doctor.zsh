# commands/doctor.zsh - Health check for flow-cli
# Checks installed dependencies and offers to fix issues

# Resolve directory at source time (not inside functions where $0 = function name)
_DOCTOR_DIR="${0:A:h}"

# Load cache library for token validation caching
if [[ -f "${_DOCTOR_DIR}/../lib/doctor-cache.zsh" ]]; then
  source "${_DOCTOR_DIR}/../lib/doctor-cache.zsh" 2>/dev/null || true
fi

# ============================================================================
# DOCTOR COMMAND
# ============================================================================

doctor() {
  local mode="check"    # check, fix, ai, update-docs
  local verbose=false
  local auto_yes=false

  # Task 1: Token automation flags
  local dot_check=false          # --dot flag: check only DOT tokens
  local dot_token=""             # --dot=TOKEN: check specific token
  local fix_token_only=false     # --fix-token: fix only token issues

  # Help compliance check
  local help_check=false         # --help-check flag

  # Task 4: Verbosity levels
  local verbosity_level="normal" # quiet, normal, verbose

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --fix|-f)         mode="fix"; shift ;;
      --ai|-a)          mode="ai"; shift ;;
      --update-docs|-u) mode="update-docs"; shift ;;
      --yes|-y)         auto_yes=true; shift ;;
      --verbose|-v)     verbose=true; verbosity_level="verbose"; shift ;;
      --quiet|-q)       verbosity_level="quiet"; shift ;;

      # Task 1: Token flags
      --dot)
        dot_check=true
        shift
        ;;
      --dot=*)
        dot_check=true
        dot_token="${1#*=}"
        shift
        ;;
      --fix-token)
        mode="fix"
        fix_token_only=true
        dot_check=true
        shift
        ;;

      --help-check)     help_check=true; shift; continue ;;
      --help|-h)        _doctor_help; return 0 ;;
      *)                shift ;;
    esac
  done

  # Handle update-docs mode separately (doesn't need full health check)
  if [[ "$mode" == "update-docs" ]]; then
    _doctor_update_docs "$verbose"
    return $?
  fi

  # Handle --help-check: run help compliance validation
  if [[ "$help_check" == true ]]; then
    local _hc_lib="${_DOCTOR_DIR}/../lib/help-compliance.zsh"
    if [[ -f "$_hc_lib" ]]; then
      source "$_hc_lib"
      # Color fallbacks for standalone use
      if [[ -z "$_C_BOLD" ]]; then
          _C_BOLD='\033[1m'
          _C_NC='\033[0m'
      fi
      echo ""
      echo -e "${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}"
      echo -e "${_C_BOLD}│  📋 Help Function Compliance Check           │${_C_NC}"
      echo -e "${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}"
      echo ""
      _flow_help_compliance_check_all "$verbose"
      return $?
    else
      echo "ERROR: lib/help-compliance.zsh not found"
      return 1
    fi
  fi

  # Initialize cache on doctor start
  if (( $+functions[_doctor_cache_init] )); then
    _doctor_cache_init 2>/dev/null || true
  fi

  # Task 4: Use verbosity helpers for header
  if [[ "$verbosity_level" != "quiet" ]]; then
    echo ""
    echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🩺 flow-cli Health Check${FLOW_COLORS[reset]}                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
    echo ""
  fi

  # Track issues for fixing
  typeset -ga _doctor_missing_brew=()
  typeset -ga _doctor_missing_npm=()
  typeset -ga _doctor_missing_pip=()
  typeset -gA _doctor_token_issues=()
  typeset -ga _doctor_alias_issues=()
  typeset -ga _doctor_missing_email_brew=()
  typeset -ga _doctor_missing_email_pip=()
  typeset -g _doctor_email_no_config=false

  # Task 1: If --dot flag is active, skip non-token health checks
  if [[ "$dot_check" == false ]]; then
    # ──────────────────────────────────────────────────────────────
    # SHELL & CORE
    # ──────────────────────────────────────────────────────────────
    _doctor_log_quiet "${FLOW_COLORS[bold]}🐚 SHELL${FLOW_COLORS[reset]}"
    _doctor_check_cmd "zsh" "" "shell"
    _doctor_check_cmd "git" "" "shell"
    _doctor_log_quiet ""

    # ──────────────────────────────────────────────────────────────
    # REQUIRED
    # ──────────────────────────────────────────────────────────────
    _doctor_log_quiet "${FLOW_COLORS[bold]}⚡ REQUIRED${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}(core functionality)${FLOW_COLORS[reset]}"
    _doctor_check_cmd "fzf" "brew" "required"
    _doctor_log_quiet ""

    # ──────────────────────────────────────────────────────────────
    # RECOMMENDED
    # ──────────────────────────────────────────────────────────────
    _doctor_log_quiet "${FLOW_COLORS[bold]}✨ RECOMMENDED${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}(enhanced experience)${FLOW_COLORS[reset]}"
    _doctor_check_cmd "eza" "brew" "recommended"
    _doctor_check_cmd "bat" "brew" "recommended"
    _doctor_check_cmd "zoxide" "brew" "recommended"
    _doctor_check_cmd "fd" "brew" "recommended"
    _doctor_check_cmd "rg" "brew:ripgrep" "recommended"
    _doctor_log_quiet ""

    # ──────────────────────────────────────────────────────────────
    # OPTIONAL
    # ──────────────────────────────────────────────────────────────
    _doctor_log_quiet "${FLOW_COLORS[bold]}📦 OPTIONAL${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}(nice to have)${FLOW_COLORS[reset]}"
    _doctor_check_cmd "dust" "brew" "optional"
    _doctor_check_cmd "duf" "brew" "optional"
    _doctor_check_cmd "btop" "brew" "optional"
    _doctor_check_cmd "delta" "brew:git-delta" "optional"
    _doctor_check_cmd "gh" "brew" "optional"
    _doctor_check_cmd "jq" "brew" "optional"
    _doctor_log_quiet ""

    # ──────────────────────────────────────────────────────────────
    # INTEGRATIONS
    # ──────────────────────────────────────────────────────────────
    _doctor_log_quiet "${FLOW_COLORS[bold]}🔌 INTEGRATIONS${FLOW_COLORS[reset]}"
    _doctor_check_cmd "atlas" "npm:@data-wise/atlas" "optional"

    # Check for radian (R console) only if R exists
    if command -v R >/dev/null 2>&1; then
      _doctor_check_cmd "radian" "pip" "optional"
    fi
    _doctor_log_quiet ""

    # ──────────────────────────────────────────────────────────────
    # EMAIL (if em dispatcher is loaded)
    # ──────────────────────────────────────────────────────────────
    if (( $+functions[em] )); then
      _doctor_check_email
    fi
  fi

  # ──────────────────────────────────────────────────────────────
  # DOTFILES (if dot dispatcher is loaded)
  # ──────────────────────────────────────────────────────────────
  # Task 3: Delegate to dot token expiring with cache integration
  if (( $+functions[_dot_doctor] )); then
    if [[ "$dot_check" == true ]]; then
      # Only show token section, delegate to dot token expiring
      _doctor_log_always "${FLOW_COLORS[bold]}🔑 DOT TOKENS${FLOW_COLORS[reset]}"

      if [[ -n "$dot_token" ]]; then
        # Check specific token
        _doctor_log_verbose "Checking specific token: $dot_token"

        # Check cache first
        local cached_result
        if (( $+functions[_doctor_cache_token_get] )); then
          cached_result=$(_doctor_cache_token_get "$dot_token" 2>/dev/null)
        fi

        if [[ -n "$cached_result" ]]; then
          _doctor_log_verbose "  ${FLOW_COLORS[muted]}[Cache hit]${FLOW_COLORS[reset]}"

          # Parse and display cached result
          if command -v jq >/dev/null 2>&1; then
            local status=$(echo "$cached_result" | jq -r '.status // "unknown"')
            local days_remaining=$(echo "$cached_result" | jq -r '.days_remaining // "unknown"')
            local username=$(echo "$cached_result" | jq -r '.username // ""')

            case "$status" in
              valid)
                if [[ "$days_remaining" != "unknown" ]]; then
                  _doctor_log_always "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Valid (@$username)"
                  if [[ "$days_remaining" -le 7 ]]; then
                    _doctor_log_always "  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]}  Expiring in $days_remaining days"
                  fi
                else
                  _doctor_log_always "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Valid"
                fi
                ;;
              invalid|expired)
                _doctor_log_always "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} Invalid/Expired"
                ;;
              *)
                _doctor_log_always "  ${FLOW_COLORS[muted]}○${FLOW_COLORS[reset]} $status"
                ;;
            esac
          else
            echo "$cached_result"
          fi
        else
          # Cache miss - call dot token expiring
          _doctor_log_verbose "  ${FLOW_COLORS[muted]}[Cache miss - validating...]${FLOW_COLORS[reset]}"

          if (( $+functions[_dot_token_expiring] )); then
            local token_status=$(_dot_token_expiring 2>&1)

            # Cache the result (5 min TTL)
            if (( $+functions[_doctor_cache_token_set] )) && [[ -n "$token_status" ]]; then
              _doctor_cache_token_set "$dot_token" "$token_status" 300 2>/dev/null || true
            fi

            # Display result
            echo "$token_status"
          else
            _doctor_log_always "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} dot token expiring not available"
          fi
        fi
      else
        # Check all DOT tokens
        _doctor_log_verbose "Checking all DOT tokens"

        # Check cache first for GitHub token
        local cached_result
        if (( $+functions[_doctor_cache_token_get] )); then
          cached_result=$(_doctor_cache_token_get "github" 2>/dev/null)
        fi

        if [[ -n "$cached_result" ]]; then
          _doctor_log_verbose "  ${FLOW_COLORS[muted]}[Cache hit]${FLOW_COLORS[reset]}"

          # Parse and display cached result
          if command -v jq >/dev/null 2>&1; then
            local status=$(echo "$cached_result" | jq -r '.status // "unknown"')
            local days_remaining=$(echo "$cached_result" | jq -r '.days_remaining // "unknown"')
            local username=$(echo "$cached_result" | jq -r '.username // ""')

            case "$status" in
              valid)
                if [[ "$days_remaining" != "unknown" ]]; then
                  _doctor_log_always "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Valid (@$username)"
                  if [[ "$days_remaining" -le 7 ]]; then
                    _doctor_log_always "  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]}  Expiring in $days_remaining days"
                    _doctor_token_issues[github]="expiring"
                  fi
                else
                  _doctor_log_always "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Valid"
                fi
                ;;
              invalid|expired)
                _doctor_log_always "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} Invalid/Expired"
                _doctor_token_issues[github]="invalid"
                ;;
              *)
                _doctor_log_always "  ${FLOW_COLORS[muted]}○${FLOW_COLORS[reset]} $status"
                ;;
            esac
          else
            echo "$cached_result"
          fi
        else
          # Cache miss - call dot token expiring
          _doctor_log_verbose "  ${FLOW_COLORS[muted]}[Cache miss - validating...]${FLOW_COLORS[reset]}"

          if (( $+functions[_dot_token_expiring] )); then
            local token_status=$(_dot_token_expiring 2>&1)

            # Cache the result (5 min TTL)
            if (( $+functions[_doctor_cache_token_set] )) && [[ -n "$token_status" ]]; then
              _doctor_cache_token_set "github" "$token_status" 300 2>/dev/null || true
            fi

            # Display result
            echo "$token_status"

            # Parse for issues to track
            if echo "$token_status" | grep -q "Expired\|Invalid"; then
              _doctor_token_issues[github]="invalid"
            elif echo "$token_status" | grep -q "Expiring"; then
              _doctor_token_issues[github]="expiring"
            fi
          else
            _doctor_log_always "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} dot token expiring not available"
          fi
        fi
      fi
      _doctor_log_always ""
    else
      # Run full DOT doctor (includes tokens and other DOT features)
      _dot_doctor
    fi
  fi

  # Task 1: Skip remaining checks if --dot is active
  if [[ "$dot_check" == false ]]; then
    # ──────────────────────────────────────────────────────────────
    # ZSH PLUGIN MANAGER
    # ──────────────────────────────────────────────────────────────
    _doctor_check_plugin_manager

    # ──────────────────────────────────────────────────────────────
    # ZSH PLUGINS
    # ──────────────────────────────────────────────────────────────
    _doctor_log_quiet "${FLOW_COLORS[bold]}🔧 ZSH PLUGINS${FLOW_COLORS[reset]}"
    _doctor_check_zsh_plugin "powerlevel10k" "romkatv/powerlevel10k"
    _doctor_check_zsh_plugin "autosuggestions" "zsh-users/zsh-autosuggestions"
    _doctor_check_zsh_plugin "syntax-highlighting" "zsh-users/zsh-syntax-highlighting"
    _doctor_check_zsh_plugin "completions" "zsh-users/zsh-completions"
    _doctor_log_quiet ""

    # ──────────────────────────────────────────────────────────────
    # FLOW-CLI STATUS
    # ──────────────────────────────────────────────────────────────
    _doctor_log_quiet "${FLOW_COLORS[bold]}🌊 FLOW-CLI${FLOW_COLORS[reset]}"
    if [[ -n "$FLOW_PLUGIN_LOADED" ]]; then
      _doctor_log_quiet "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} flow-cli v${FLOW_VERSION:-unknown} loaded"
    else
      _doctor_log_quiet "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} flow-cli not loaded"
    fi

    if _flow_has_atlas 2>/dev/null; then
      _doctor_log_quiet "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} atlas connected"
    else
      _doctor_log_quiet "  ${FLOW_COLORS[muted]}○${FLOW_COLORS[reset]} atlas not connected ${FLOW_COLORS[muted]}(standalone mode)${FLOW_COLORS[reset]}"
    fi
    _doctor_log_quiet ""
  fi

  # ──────────────────────────────────────────────────────────────
  # GITHUB TOKEN HEALTH
  # ──────────────────────────────────────────────────────────────
  # Note: This is the legacy token check. Future phases will delegate to dot token expiring
  if [[ "$dot_check" == false ]]; then
    _doctor_log_quiet "${FLOW_COLORS[bold]}🔑 GITHUB TOKEN${FLOW_COLORS[reset]}"

    local token=$(dot secret github-token 2>/dev/null)
    local -a token_issues=()

    if [[ -z "$token" ]]; then
      _doctor_log_quiet "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} Not configured"
      token_issues+=("missing")
    else
      # Validate token via API
      local api_response=$(curl -s -w "\n%{http_code}" \
        -H "Authorization: token $token" \
        "https://api.github.com/user" 2>/dev/null)

      local http_code=$(echo "$api_response" | tail -1)
      local username=$(echo "$api_response" | sed '$d' | jq -r '.login // "unknown"')

      if [[ "$http_code" != "200" ]]; then
        _doctor_log_quiet "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} Invalid/Expired"
        token_issues+=("invalid")
      else
        _doctor_log_quiet "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Valid (@$username)"

        # Check expiration
        local age_days=$(_dot_token_age_days "github-token")
        local days_remaining=$((90 - age_days))

        if [[ $days_remaining -le 7 ]]; then
          _doctor_log_quiet "  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]}  Expiring in $days_remaining days"
          token_issues+=("expiring")
        fi

        # Test token-dependent services (verbose only)
        _doctor_log_verbose ""
        _doctor_log_verbose "  ${FLOW_COLORS[muted]}Token-Dependent Services:${FLOW_COLORS[reset]}"

        # Test gh CLI
        if command -v gh &>/dev/null; then
          if gh auth status &>/dev/null 2>&1; then
            _doctor_log_verbose "    ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} gh CLI authenticated"
          else
            _doctor_log_verbose "    ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} gh CLI not authenticated"
            token_issues+=("gh-cli")
          fi
        else
          _doctor_log_verbose "    ${FLOW_COLORS[muted]}○${FLOW_COLORS[reset]} gh CLI not installed"
        fi

        # Test Claude Code MCP
        if [[ -f "$HOME/.claude/settings.json" ]]; then
          if grep -q "GITHUB_PERSONAL_ACCESS_TOKEN.*\${GITHUB_TOKEN}" "$HOME/.claude/settings.json"; then
            if [[ -n "$GITHUB_TOKEN" ]]; then
              _doctor_log_verbose "    ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Claude Code MCP configured"
            else
              _doctor_log_verbose "    ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} \$GITHUB_TOKEN not exported"
              token_issues+=("env-var")
            fi
          else
            _doctor_log_verbose "    ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]}  Claude MCP not using env var"
            token_issues+=("mcp-config")
          fi
        fi
      fi
    fi

    # Store token issues for category selection
    if [[ ${#token_issues[@]} -gt 0 ]]; then
      _doctor_token_issues[github]="${token_issues[*]}"
    fi

    _doctor_log_quiet ""
  fi

  # ──────────────────────────────────────────────────────────────
  # ALIAS HEALTH
  # ──────────────────────────────────────────────────────────────
  if [[ "$dot_check" == false ]]; then
    _doctor_check_aliases
  fi

  # ──────────────────────────────────────────────────────────────
  # TASK 2: CATEGORY SELECTION & FIX MODE
  # ──────────────────────────────────────────────────────────────
  if [[ "$mode" == "fix" ]]; then
    # Show category selection menu if there are issues
    local selected_category=$(_doctor_select_fix_category "$fix_token_only" "$auto_yes")
    local selection_exit=$?

    # Exit codes: 0 = category selected, 1 = user cancelled, 2 = no issues found
    if [[ $selection_exit -eq 1 ]]; then
      _doctor_log_quiet "${FLOW_COLORS[muted]}Fix cancelled${FLOW_COLORS[reset]}"
      _doctor_log_quiet ""
      return 0
    elif [[ $selection_exit -eq 2 ]]; then
      # No issues found, already displayed success message
      return 0
    fi

    # Apply fixes based on selected category
    _doctor_apply_fixes "$selected_category" "$auto_yes"
    return $?
  fi

  # ──────────────────────────────────────────────────────────────
  # SUMMARY & ACTIONS (check mode only)
  # ──────────────────────────────────────────────────────────────
  if [[ "$dot_check" == false ]]; then
    local total_missing=$((${#_doctor_missing_brew[@]} + ${#_doctor_missing_npm[@]} + ${#_doctor_missing_pip[@]} + ${#_doctor_missing_email_brew[@]} + ${#_doctor_missing_email_pip[@]}))

    if [[ $total_missing -eq 0 && ${#_doctor_token_issues[@]} -eq 0 ]]; then
      _doctor_log_quiet "${FLOW_COLORS[success]}✓ All essential tools installed!${FLOW_COLORS[reset]}"
      _doctor_log_quiet ""
      return 0
    fi

    # Show summary
    local category_count=$(_doctor_count_categories)
    local category_s="ies"; (( category_count == 1 )) && category_s="y"
    _doctor_log_quiet "${FLOW_COLORS[warning]}△ Found issues in ${category_count} categor${category_s}${FLOW_COLORS[reset]}"
    _doctor_log_quiet ""

    # Handle different modes
    case "$mode" in
      ai)
        _doctor_ai_assist
        ;;
      *)
        # Default: show suggestions
        _doctor_log_quiet "${FLOW_COLORS[header]}───────────────────────────────────────────────${FLOW_COLORS[reset]}"
        _doctor_log_quiet ""
        _doctor_log_quiet "${FLOW_COLORS[bold]}Quick actions:${FLOW_COLORS[reset]}"
        _doctor_log_quiet "  ${FLOW_COLORS[accent]}doctor --fix${FLOW_COLORS[reset]}     Interactive install missing tools"
        _doctor_log_quiet "  ${FLOW_COLORS[accent]}doctor --fix -y${FLOW_COLORS[reset]}  Install all without prompts"
        _doctor_log_quiet "  ${FLOW_COLORS[accent]}doctor --ai${FLOW_COLORS[reset]}      AI-assisted troubleshooting"
        _doctor_log_quiet ""
        _doctor_log_quiet "${FLOW_COLORS[muted]}Or install all via Brewfile:${FLOW_COLORS[reset]}"
        _doctor_log_quiet "  brew bundle --file=$FLOW_PLUGIN_DIR/setup/Brewfile"
        _doctor_log_quiet ""
        ;;
    esac
  fi
}

# ============================================================================
# TASK 4: VERBOSITY HELPER FUNCTIONS
# ============================================================================

# Log only if NOT in quiet mode (normal or verbose)
_doctor_log_quiet() {
  if [[ "$verbosity_level" != "quiet" ]]; then
    echo "$@"
  fi
}

# Log only in verbose mode
_doctor_log_verbose() {
  if [[ "$verbosity_level" == "verbose" ]]; then
    echo "$@"
  fi
}

# Always log regardless of verbosity level (for critical messages)
_doctor_log_always() {
  echo "$@"
}

# ============================================================================
# TASK 2: CATEGORY SELECTION MENU
# ============================================================================

# =============================================================================
# Function: _doctor_select_fix_category
# Purpose: Show ADHD-friendly menu for selecting which category to fix
# =============================================================================
# Arguments:
#   $1 - (optional) Token-only mode (true/false) [default: false]
#   $2 - (optional) Auto-yes mode (true/false) [default: false]
#
# Returns:
#   0 - Category selected (outputs category name to stdout)
#   1 - User cancelled
#   2 - No issues found
#
# Output:
#   stdout - Selected category name ("tokens", "required", "recommended", "aliases", "all")
#
# Example:
#   selected=$(_doctor_select_fix_category false false)
#   if [[ $? -eq 0 ]]; then
#       echo "User selected: $selected"
#   fi
# =============================================================================
_doctor_select_fix_category() {
  local token_only="${1:-false}"
  local auto_yes="${2:-false}"

  # Build list of categories with issues
  typeset -a categories=()
  typeset -A category_info=()

  # Tokens category
  if [[ ${#_doctor_token_issues[@]} -gt 0 ]]; then
    local token_count=${#_doctor_token_issues[@]}
    local token_s=""; (( token_count > 1 )) && token_s="s"
    categories+=("tokens")
    category_info[tokens]="🔑 GitHub Token ($token_count issue${token_s}, ~30s)"
  fi

  # Skip other categories if token-only mode
  if [[ "$token_only" == false ]]; then
    # Required tools category
    if [[ ${#_doctor_missing_brew[@]} -gt 0 ]] || [[ ${#_doctor_missing_npm[@]} -gt 0 ]] || [[ ${#_doctor_missing_pip[@]} -gt 0 ]]; then
      local tools_count=$((${#_doctor_missing_brew[@]} + ${#_doctor_missing_npm[@]} + ${#_doctor_missing_pip[@]}))
      local tools_s=""; (( tools_count > 1 )) && tools_s="s"
      local est_time=$((tools_count * 30))  # Estimate 30s per tool
      local time_str
      if [[ $est_time -lt 60 ]]; then
        time_str="${est_time}s"
      else
        time_str="$((est_time / 60))m $((est_time % 60))s"
      fi
      categories+=("tools")
      category_info[tools]="📦 Missing Tools ($tools_count tool${tools_s}, ~${time_str})"
    fi

    # Aliases category
    if [[ ${#_doctor_alias_issues[@]} -gt 0 ]]; then
      local alias_count=${#_doctor_alias_issues[@]}
      local alias_s=""; (( alias_count > 1 )) && alias_s="s"
      categories+=("aliases")
      category_info[aliases]="⚡ Aliases ($alias_count issue${alias_s}, ~10s)"
    fi

    # Email category
    if [[ ${#_doctor_missing_email_brew[@]} -gt 0 || ${#_doctor_missing_email_pip[@]} -gt 0 || "$_doctor_email_no_config" == true ]]; then
      local email_count=$((${#_doctor_missing_email_brew[@]} + ${#_doctor_missing_email_pip[@]}))
      [[ "$_doctor_email_no_config" == true ]] && ((email_count++))
      local email_s=""; (( email_count > 1 )) && email_s="s"
      local email_time=$((email_count * 30))
      local email_time_str
      if [[ $email_time -lt 60 ]]; then
        email_time_str="${email_time}s"
      else
        email_time_str="$((email_time / 60))m"
      fi
      categories+=("email")
      category_info[email]="📧 Email Tools ($email_count issue${email_s}, ~${email_time_str})"
    fi
  fi

  # No issues found
  if [[ ${#categories[@]} -eq 0 ]]; then
    _doctor_log_always ""
    _doctor_log_always "${FLOW_COLORS[success]}✓ No issues found!${FLOW_COLORS[reset]}"
    _doctor_log_always ""
    return 2
  fi

  # Auto-yes mode: fix all categories
  if [[ "$auto_yes" == true ]]; then
    echo "all"
    return 0
  fi

  # Single category: auto-select it
  if [[ ${#categories[@]} -eq 1 ]]; then
    echo "${categories[1]}"
    return 0
  fi

  # Multiple categories: show menu
  _doctor_log_always ""
  _doctor_log_always "${FLOW_COLORS[header]}╭─ Select Category to Fix ────────────────────────╮${FLOW_COLORS[reset]}"
  _doctor_log_always "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

  # Display each category with numbering
  local idx=1
  for cat in "${categories[@]}"; do
    local info="${category_info[$cat]}"
    _doctor_log_always "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[accent]}${idx}.${FLOW_COLORS[reset]} ${info}$(printf '%*s' $((44 - ${#info})) '')${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    ((idx++))
  done

  _doctor_log_always "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

  # Add "Fix All" option if multiple categories
  local all_idx=$idx
  local total_time=0
  for cat in "${categories[@]}"; do
    case "$cat" in
      tokens) total_time=$((total_time + 30)) ;;
      tools) total_time=$((total_time + ${#_doctor_missing_brew[@]} * 30 + ${#_doctor_missing_npm[@]} * 30 + ${#_doctor_missing_pip[@]} * 30)) ;;
      aliases) total_time=$((total_time + 10)) ;;
      email) total_time=$((total_time + (${#_doctor_missing_email_brew[@]} + ${#_doctor_missing_email_pip[@]}) * 30)) ;;
    esac
  done

  local time_str
  if [[ $total_time -lt 60 ]]; then
    time_str="${total_time}s"
  elif [[ $total_time -lt 3600 ]]; then
    time_str="$((total_time / 60))m $((total_time % 60))s"
  else
    time_str="$((total_time / 3600))h $((total_time % 3600 / 60))m"
  fi

  local all_text="✨ Fix All Categories (~${time_str})"
  _doctor_log_always "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[accent]}${all_idx}.${FLOW_COLORS[reset]} ${all_text}$(printf '%*s' $((44 - ${#all_text})) '')${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  _doctor_log_always "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

  # Add exit option
  local exit_idx=$((all_idx + 1))
  local exit_text="0. Exit without fixing"
  _doctor_log_always "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}${exit_text}${FLOW_COLORS[reset]}$(printf '%*s' $((47 - ${#exit_text})) '')${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  _doctor_log_always "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  _doctor_log_always "${FLOW_COLORS[header]}╰──────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  _doctor_log_always ""

  # Prompt for selection
  local selection
  echo -n "${FLOW_COLORS[info]}Select [1-${all_idx}, 0 to exit]:${FLOW_COLORS[reset]} "
  read -r selection

  # Validate input
  if [[ "$selection" == "0" ]]; then
    return 1
  elif [[ "$selection" == "$all_idx" ]]; then
    echo "all"
    return 0
  elif [[ "$selection" =~ ^[0-9]+$ ]] && (( selection >= 1 && selection <= ${#categories[@]} )); then
    echo "${categories[$selection]}"
    return 0
  else
    _doctor_log_always ""
    _doctor_log_always "${FLOW_COLORS[error]}Invalid selection${FLOW_COLORS[reset]}"
    return 1
  fi
}

# =============================================================================
# Function: _doctor_count_categories
# Purpose: Count total number of categories with issues
# =============================================================================
_doctor_count_categories() {
  local count=0
  [[ ${#_doctor_token_issues[@]} -gt 0 ]] && ((count++))
  [[ ${#_doctor_missing_brew[@]} -gt 0 || ${#_doctor_missing_npm[@]} -gt 0 || ${#_doctor_missing_pip[@]} -gt 0 ]] && ((count++))
  [[ ${#_doctor_alias_issues[@]} -gt 0 ]] && ((count++))
  [[ ${#_doctor_missing_email_brew[@]} -gt 0 || ${#_doctor_missing_email_pip[@]} -gt 0 ]] && ((count++))
  echo "$count"
}

# =============================================================================
# Function: _doctor_apply_fixes
# Purpose: Apply fixes for selected category
# =============================================================================
# Arguments:
#   $1 - (required) Category to fix ("tokens", "tools", "aliases", "all")
#   $2 - (optional) Auto-yes mode [default: false]
# =============================================================================
_doctor_apply_fixes() {
  local category="$1"
  local auto_yes="${2:-false}"

  _doctor_log_quiet ""
  _doctor_log_quiet "${FLOW_COLORS[header]}───────────────────────────────────────────────${FLOW_COLORS[reset]}"
  _doctor_log_quiet ""
  _doctor_log_quiet "${FLOW_COLORS[bold]}🔧 Applying Fixes${FLOW_COLORS[reset]}"
  _doctor_log_quiet ""

  # Fix tokens
  if [[ "$category" == "tokens" || "$category" == "all" ]]; then
    if [[ ${#_doctor_token_issues[@]} -gt 0 ]]; then
      _doctor_fix_tokens
    fi
  fi

  # Fix tools
  if [[ "$category" == "tools" || "$category" == "all" ]]; then
    if [[ ${#_doctor_missing_brew[@]} -gt 0 || ${#_doctor_missing_npm[@]} -gt 0 || ${#_doctor_missing_pip[@]} -gt 0 ]]; then
      _doctor_interactive_fix "$auto_yes"
    fi
  fi

  # Fix aliases
  if [[ "$category" == "aliases" || "$category" == "all" ]]; then
    if [[ ${#_doctor_alias_issues[@]} -gt 0 ]]; then
      _doctor_log_always "${FLOW_COLORS[info]}Alias fixes not yet implemented${FLOW_COLORS[reset]}"
      _doctor_log_always "Run ${FLOW_COLORS[accent]}flow alias doctor${FLOW_COLORS[reset]} for details"
      _doctor_log_always ""
    fi
  fi

  # Fix email
  if [[ "$category" == "email" || "$category" == "all" ]]; then
    if [[ ${#_doctor_missing_email_brew[@]} -gt 0 || ${#_doctor_missing_email_pip[@]} -gt 0 || "$_doctor_email_no_config" == true ]]; then
      _doctor_fix_email "$auto_yes"
    fi
  fi

  _doctor_log_quiet "${FLOW_COLORS[success]}Done!${FLOW_COLORS[reset]} Run ${FLOW_COLORS[accent]}doctor${FLOW_COLORS[reset]} again to verify."
  _doctor_log_quiet ""
}

# =============================================================================
# Function: _doctor_fix_tokens
# Purpose: Fix token-related issues
# =============================================================================
_doctor_fix_tokens() {
  _doctor_log_always "${FLOW_COLORS[info]}Fixing token issues...${FLOW_COLORS[reset]}"
  _doctor_log_always ""

  for provider in "${(@k)_doctor_token_issues}"; do
    local -a issues=(${=_doctor_token_issues[$provider]})

    _doctor_log_always "${FLOW_COLORS[bold]}GitHub Token:${FLOW_COLORS[reset]}"

    for issue in "${issues[@]}"; do
      case "$issue" in
        missing)
          _doctor_log_always "  ${FLOW_COLORS[info]}Generating new GitHub token...${FLOW_COLORS[reset]}"
          dot token github
          ;;

        invalid|expiring)
          _doctor_log_always "  ${FLOW_COLORS[info]}Rotating token...${FLOW_COLORS[reset]}"

          # Call token rotation workflow
          if (( $+functions[_dot_token_rotate] )); then
            _dot_token_rotate

            # Clear cache after rotation
            if (( $+functions[_doctor_cache_token_clear] )); then
              _doctor_cache_token_clear "$provider" 2>/dev/null || true
              _doctor_log_verbose "  ${FLOW_COLORS[muted]}Cache cleared for $provider${FLOW_COLORS[reset]}"
            fi

            _doctor_log_quiet "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Token rotated successfully"
          else
            _doctor_log_error "Token rotation not available"
          fi
          ;;

        gh-cli)
          _doctor_log_always "  ${FLOW_COLORS[info]}Authenticating gh CLI...${FLOW_COLORS[reset]}"
          _dot_token_sync_gh
          ;;

        env-var)
          _doctor_log_always "  ${FLOW_COLORS[warning]}Add to ~/.config/zsh/.zshrc:${FLOW_COLORS[reset]}"
          _doctor_log_always "  export GITHUB_TOKEN=\$(dot secret github-token)"
          ;;

        mcp-config)
          _doctor_log_always "  ${FLOW_COLORS[info]}Run: ${FLOW_COLORS[cmd]}dot claude tokens${FLOW_COLORS[reset]} to fix Claude MCP"
          ;;
      esac
    done
    _doctor_log_always ""
  done
}

# ============================================================================
# INTERACTIVE FIX MODE
# ============================================================================

_doctor_interactive_fix() {
  local auto_yes="${1:-false}"

  # Homebrew packages
  if [[ ${#_doctor_missing_brew[@]} -gt 0 ]]; then
    _doctor_log_quiet "${FLOW_COLORS[info]}Homebrew packages to install:${FLOW_COLORS[reset]}"
    for pkg in "${_doctor_missing_brew[@]}"; do
      _doctor_log_quiet "  • $pkg"
    done
    _doctor_log_quiet ""

    if [[ "$auto_yes" == true ]] || _doctor_confirm "Install ${#_doctor_missing_brew[@]} Homebrew package(s)?"; then
      echo ""
      for pkg in "${_doctor_missing_brew[@]}"; do
        _doctor_log_always "${FLOW_COLORS[info]}Installing $pkg...${FLOW_COLORS[reset]}"
        if brew install "$pkg" 2>&1; then
          _doctor_log_always "${FLOW_COLORS[success]}✓ $pkg installed${FLOW_COLORS[reset]}"
        else
          _doctor_log_always "${FLOW_COLORS[error]}✗ Failed to install $pkg${FLOW_COLORS[reset]}"
        fi
      done
      _doctor_log_quiet ""
    else
      _doctor_log_quiet "${FLOW_COLORS[muted]}Skipped Homebrew packages${FLOW_COLORS[reset]}"
      _doctor_log_quiet ""
    fi
  fi

  # NPM packages
  if [[ ${#_doctor_missing_npm[@]} -gt 0 ]]; then
    _doctor_log_quiet "${FLOW_COLORS[info]}NPM packages to install:${FLOW_COLORS[reset]}"
    for pkg in "${_doctor_missing_npm[@]}"; do
      _doctor_log_quiet "  • $pkg"
    done
    _doctor_log_quiet ""

    if [[ "$auto_yes" == true ]] || _doctor_confirm "Install ${#_doctor_missing_npm[@]} NPM package(s) globally?"; then
      echo ""
      for pkg in "${_doctor_missing_npm[@]}"; do
        _doctor_log_always "${FLOW_COLORS[info]}Installing $pkg...${FLOW_COLORS[reset]}"
        if npm install -g "$pkg" 2>&1; then
          _doctor_log_always "${FLOW_COLORS[success]}✓ $pkg installed${FLOW_COLORS[reset]}"
        else
          _doctor_log_always "${FLOW_COLORS[error]}✗ Failed to install $pkg${FLOW_COLORS[reset]}"
        fi
      done
      _doctor_log_quiet ""
    else
      _doctor_log_quiet "${FLOW_COLORS[muted]}Skipped NPM packages${FLOW_COLORS[reset]}"
      _doctor_log_quiet ""
    fi
  fi

  # Pip packages
  if [[ ${#_doctor_missing_pip[@]} -gt 0 ]]; then
    _doctor_log_quiet "${FLOW_COLORS[info]}Pip packages to install:${FLOW_COLORS[reset]}"
    for pkg in "${_doctor_missing_pip[@]}"; do
      _doctor_log_quiet "  • $pkg"
    done
    _doctor_log_quiet ""

    if [[ "$auto_yes" == true ]] || _doctor_confirm "Install ${#_doctor_missing_pip[@]} pip package(s)?"; then
      echo ""
      for pkg in "${_doctor_missing_pip[@]}"; do
        _doctor_log_always "${FLOW_COLORS[info]}Installing $pkg...${FLOW_COLORS[reset]}"
        if pip install "$pkg" 2>&1; then
          _doctor_log_always "${FLOW_COLORS[success]}✓ $pkg installed${FLOW_COLORS[reset]}"
        else
          _doctor_log_always "${FLOW_COLORS[error]}✗ Failed to install $pkg${FLOW_COLORS[reset]}"
        fi
      done
      _doctor_log_quiet ""
    else
      _doctor_log_quiet "${FLOW_COLORS[muted]}Skipped pip packages${FLOW_COLORS[reset]}"
      _doctor_log_quiet ""
    fi
  fi
}

# ============================================================================
# AI-ASSISTED MODE (Claude CLI)
# ============================================================================

_doctor_ai_assist() {
  _doctor_log_quiet "${FLOW_COLORS[header]}───────────────────────────────────────────────${FLOW_COLORS[reset]}"
  _doctor_log_quiet ""
  _doctor_log_quiet "${FLOW_COLORS[bold]}🤖 AI-Assisted Troubleshooting${FLOW_COLORS[reset]}"
  _doctor_log_quiet ""

  # Check if claude is available
  if ! command -v claude >/dev/null 2>&1; then
    _doctor_log_always "${FLOW_COLORS[error]}✗ Claude CLI not found${FLOW_COLORS[reset]}"
    _doctor_log_always ""
    _doctor_log_always "Install Claude CLI first:"
    _doctor_log_always "  ${FLOW_COLORS[accent]}npm install -g @anthropic-ai/claude-cli${FLOW_COLORS[reset]}"
    _doctor_log_always ""
    return 1
  fi

  # Build context for Claude
  local context="flow-cli doctor found these missing tools:\n"

  if [[ ${#_doctor_missing_brew[@]} -gt 0 ]]; then
    context+="Homebrew: ${_doctor_missing_brew[*]}\n"
  fi
  if [[ ${#_doctor_missing_npm[@]} -gt 0 ]]; then
    context+="NPM: ${_doctor_missing_npm[*]}\n"
  fi
  if [[ ${#_doctor_missing_pip[@]} -gt 0 ]]; then
    context+="Pip: ${_doctor_missing_pip[*]}\n"
  fi

  context+="\nCurrent directory: $PWD\n"
  context+="Shell: $SHELL\n"
  context+="OS: $(uname -s)\n"

  _doctor_log_quiet "${FLOW_COLORS[muted]}Launching Claude CLI for assistance...${FLOW_COLORS[reset]}"
  _doctor_log_quiet ""

  # Launch Claude with context
  local prompt="I'm setting up flow-cli and the doctor command found missing tools. Help me:
1. Understand what each missing tool does
2. Decide which ones I actually need
3. Install them safely

Missing tools:
$(echo -e "$context")

Please explain each tool briefly and ask which ones I want to install."

  # Use claude CLI with the prompt
  if _doctor_confirm "Launch Claude CLI for AI-assisted setup?"; then
    echo ""
    claude --print "$prompt"
  else
    echo ""
    _doctor_log_quiet "${FLOW_COLORS[muted]}You can manually run:${FLOW_COLORS[reset]}"
    _doctor_log_quiet "  claude \"Help me install: ${_doctor_missing_brew[*]} ${_doctor_missing_npm[*]}\""
    _doctor_log_quiet ""
  fi
}

# ============================================================================
# UPDATE DOCS MODE
# ============================================================================

_doctor_update_docs() {
  local verbose="${1:-false}"
  local plugin_dir="${FLOW_PLUGIN_DIR:-$(cd "${0:h}/.." && pwd)}"
  local man_dir="$plugin_dir/man/man1"
  local docs_dir="$plugin_dir/docs"
  local generated_dir="$docs_dir/reference/generated"

  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}📝 Update Documentation${FLOW_COLORS[reset]}                      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""

  # Create generated docs directory if needed
  [[ -d "$generated_dir" ]] || mkdir -p "$generated_dir"

  local updated=0
  local errors=0

  # ────────────────────────────────────────────────
  # 1. Generate command help summary
  # ────────────────────────────────────────────────
  echo "${FLOW_COLORS[bold]}Generating command help...${FLOW_COLORS[reset]}"

  local help_file="$generated_dir/COMMAND-HELP.md"
  {
    echo "# Command Help Reference"
    echo ""
    echo "> Auto-generated by \`doctor --update-docs\` on $(date '+%Y-%m-%d')"
    echo ""

    # Core commands
    echo "## Core Commands"
    echo ""

    local -a core_cmds=(work pick dash finish hop why)
    for cmd in "${core_cmds[@]}"; do
      echo "### \`$cmd\`"
      echo ""
      echo "\`\`\`"
      if (( $+functions[$cmd] )); then
        $cmd help 2>/dev/null || echo "No help available"
      else
        echo "Command not loaded"
      fi
      echo "\`\`\`"
      echo ""
    done

    # ADHD helpers
    echo "## ADHD Helpers"
    echo ""
    local -a adhd_cmds=(js stuck focus next brk)
    for cmd in "${adhd_cmds[@]}"; do
      echo "### \`$cmd\`"
      echo ""
      echo "\`\`\`"
      if (( $+functions[$cmd] )); then
        $cmd help 2>/dev/null || echo "No help available"
      else
        echo "Command not loaded"
      fi
      echo "\`\`\`"
      echo ""
    done

    # Dispatchers
    echo "## Dispatchers"
    echo ""
    local -a dispatchers=(g r qu mcp obs)
    for cmd in "${dispatchers[@]}"; do
      echo "### \`$cmd\`"
      echo ""
      echo "\`\`\`"
      if (( $+functions[$cmd] )); then
        $cmd help 2>/dev/null || echo "No help available"
      else
        echo "Command not loaded"
      fi
      echo "\`\`\`"
      echo ""
    done
  } > "$help_file"

  if [[ -f "$help_file" ]]; then
    echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Generated $help_file"
    ((updated++))
  else
    echo "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} Failed to generate help file"
    ((errors++))
  fi

  # ────────────────────────────────────────────────
  # 2. Update man page metadata
  # ────────────────────────────────────────────────
  echo ""
  echo "${FLOW_COLORS[bold]}Updating man pages...${FLOW_COLORS[reset]}"

  if [[ -d "$man_dir" ]]; then
    local today=$(date '+%B %Y')
    local version="${FLOW_VERSION:-3.1.0}"
    local man_updated=0

    for manfile in "$man_dir"/*.1; do
      [[ -f "$manfile" ]] || continue
      local basename="${manfile:t}"

      # Update date in man page header (TH line)
      if grep -q '\.TH' "$manfile"; then
        # Extract current date from TH line
        local current_date=$(grep '\.TH' "$manfile" | head -1 | sed -E 's/.*"([^"]*)".*"flow-cli.*/\1/')

        if [[ "$verbose" == "true" ]]; then
          echo "  ${FLOW_COLORS[muted]}Checking $basename (current: $current_date)${FLOW_COLORS[reset]}"
        fi

        # Only update if version changed (avoid unnecessary changes)
        if ! grep -q "flow-cli $version" "$manfile"; then
          sed -i '' "s/flow-cli [0-9.]*\"/flow-cli $version\"/" "$manfile" 2>/dev/null
          ((man_updated++))
        fi
      fi
    done

    if (( man_updated > 0 )); then
      echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Updated version in $man_updated man page(s)"
      ((updated++))
    else
      echo "  ${FLOW_COLORS[muted]}○${FLOW_COLORS[reset]} Man pages already up to date"
    fi
  else
    echo "  ${FLOW_COLORS[warning]}△${FLOW_COLORS[reset]} Man directory not found: $man_dir"
  fi

  # ────────────────────────────────────────────────
  # 3. Generate version info
  # ────────────────────────────────────────────────
  echo ""
  echo "${FLOW_COLORS[bold]}Generating version info...${FLOW_COLORS[reset]}"

  local version_file="$generated_dir/VERSION-INFO.md"
  {
    echo "# Version Information"
    echo ""
    echo "> Auto-generated by \`doctor --update-docs\` on $(date '+%Y-%m-%d %H:%M')"
    echo ""
    echo "## flow-cli"
    echo ""
    echo "- **Version:** ${FLOW_VERSION:-3.1.0}"
    echo "- **Plugin Dir:** ${FLOW_PLUGIN_DIR:-unknown}"
    echo "- **Atlas:** $(_flow_has_atlas 2>/dev/null && echo "Connected" || echo "Not connected")"
    echo ""
    echo "## Dependencies"
    echo ""
    echo "| Tool | Status | Version |"
    echo "|------|--------|---------|"

    local -a deps=(fzf eza bat zoxide fd rg git zsh)
    for dep in "${deps[@]}"; do
      if command -v "$dep" >/dev/null 2>&1; then
        local ver=$($dep --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
        echo "| $dep | ✓ Installed | $ver |"
      else
        echo "| $dep | ✗ Missing | - |"
      fi
    done
    echo ""
  } > "$version_file"

  if [[ -f "$version_file" ]]; then
    echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Generated $version_file"
    ((updated++))
  else
    echo "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} Failed to generate version file"
    ((errors++))
  fi

  # ────────────────────────────────────────────────
  # Summary
  # ────────────────────────────────────────────────
  echo ""
  echo "${FLOW_COLORS[header]}───────────────────────────────────────────────${FLOW_COLORS[reset]}"
  echo ""

  if (( errors > 0 )); then
    echo "${FLOW_COLORS[error]}Completed with $errors error(s)${FLOW_COLORS[reset]}"
    return 1
  elif (( updated > 0 )); then
    echo "${FLOW_COLORS[success]}✓ Updated $updated file(s)${FLOW_COLORS[reset]}"
    echo ""
    echo "${FLOW_COLORS[muted]}Generated files:${FLOW_COLORS[reset]}"
    echo "  • $generated_dir/COMMAND-HELP.md"
    echo "  • $generated_dir/VERSION-INFO.md"
    echo ""
  else
    echo "${FLOW_COLORS[muted]}○ No updates needed${FLOW_COLORS[reset]}"
  fi

  return 0
}

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

_doctor_check_cmd() {
  local cmd="$1"
  local install_spec="$2"  # Format: "brew" or "brew:package" or "npm:package" or "pip"
  local category="$3"      # required, recommended, optional

  if command -v "$cmd" >/dev/null 2>&1; then
    local version=""
    version=$($cmd --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    _doctor_log_quiet "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $cmd ${FLOW_COLORS[muted]}${version}${FLOW_COLORS[reset]}"
    return 0
  else
    # Parse install spec
    local manager="${install_spec%%:*}"
    local package="${install_spec#*:}"
    [[ "$package" == "$install_spec" ]] && package="$cmd"

    # Show status
    local icon="○"
    [[ "$category" == "required" ]] && icon="✗"
    local color="${FLOW_COLORS[warning]}"
    [[ "$category" == "required" ]] && color="${FLOW_COLORS[error]}"

    local hint=""
    case "$manager" in
      brew) hint="brew install $package" ;;
      npm)  hint="npm install -g $package" ;;
      pip)  hint="pip install $package" ;;
    esac

    _doctor_log_quiet "  ${color}${icon}${FLOW_COLORS[reset]} $cmd ${FLOW_COLORS[muted]}← $hint${FLOW_COLORS[reset]}"

    # Track for fixing
    case "$manager" in
      brew) _doctor_missing_brew+=("$package") ;;
      npm)  _doctor_missing_npm+=("$package") ;;
      pip)  _doctor_missing_pip+=("$package") ;;
    esac

    return 1
  fi
}

# =============================================================================
# EMAIL DOCTOR FUNCTIONS
# =============================================================================

# Check a single email dependency (mirrors _doctor_check_cmd but uses email arrays)
_doctor_check_email_cmd() {
  local cmd="$1"
  local install_spec="$2"  # "brew" or "brew:package" or "pip" or "npm:package"
  local category="$3"      # required, recommended, optional
  local desc="$4"          # description (e.g., "Markdown rendering")

  local manager="${install_spec%%:*}"
  local package="${install_spec#*:}"
  [[ "$package" == "$install_spec" ]] && package="$cmd"

  if command -v "$cmd" >/dev/null 2>&1; then
    local version=""
    version=$($cmd --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    local desc_text=""
    [[ -n "$desc" ]] && desc_text=" (${desc})"
    _doctor_log_quiet "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $cmd ${FLOW_COLORS[muted]}${version}${desc_text}${FLOW_COLORS[reset]}"
    return 0
  else
    local icon="○"
    [[ "$category" == "required" ]] && icon="✗"
    local color="${FLOW_COLORS[warning]}"
    [[ "$category" == "required" ]] && color="${FLOW_COLORS[error]}"

    local hint=""
    case "$manager" in
      brew) hint="brew install $package" ;;
      npm)  hint="npm install -g $package" ;;
      pip)  hint="pip install $package" ;;
    esac

    local desc_text=""
    [[ -n "$desc" ]] && desc_text="(${desc}) "
    _doctor_log_quiet "  ${color}${icon}${FLOW_COLORS[reset]} $cmd ${FLOW_COLORS[muted]}${desc_text}← $hint${FLOW_COLORS[reset]}"

    # Track in email-specific arrays
    case "$manager" in
      brew) _doctor_missing_email_brew+=("$package") ;;
      pip)  _doctor_missing_email_pip+=("$package") ;;
      npm)  _doctor_missing_email_brew+=("$package") ;;
    esac

    return 1
  fi
}

# Check all email dependencies (called conditionally when em() is loaded)
_doctor_check_email() {
  _doctor_log_quiet "${FLOW_COLORS[bold]}📧 EMAIL${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}(himalaya)${FLOW_COLORS[reset]}"

  # --- himalaya (required) + version check ---
  if command -v himalaya >/dev/null 2>&1; then
    local hv
    hv=$(himalaya --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
    _doctor_log_quiet "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} himalaya ${FLOW_COLORS[muted]}${hv}${FLOW_COLORS[reset]}"

    # Version >= 1.0.0
    if (( $+functions[_em_semver_lt] )) && _em_semver_lt "${hv:-0.0.0}" "1.0.0"; then
      _doctor_log_quiet "  ${FLOW_COLORS[warning]}△${FLOW_COLORS[reset]} himalaya version ${FLOW_COLORS[muted]}${hv} < 1.0.0 ← brew upgrade himalaya${FLOW_COLORS[reset]}"
    else
      _doctor_log_quiet "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} himalaya version ${FLOW_COLORS[muted]}>= 1.0.0${FLOW_COLORS[reset]}"
    fi
  else
    _doctor_log_quiet "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} himalaya ${FLOW_COLORS[muted]}← brew install himalaya${FLOW_COLORS[reset]}"
    _doctor_missing_email_brew+=("himalaya")
  fi

  # --- HTML renderer (any-of: w3m, lynx, pandoc) ---
  local renderer_found=false
  for renderer in w3m lynx pandoc; do
    if command -v "$renderer" >/dev/null 2>&1; then
      local rv
      rv=$($renderer --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)
      _doctor_log_quiet "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $renderer ${FLOW_COLORS[muted]}${rv} (HTML rendering)${FLOW_COLORS[reset]}"
      renderer_found=true
      break
    fi
  done
  if [[ "$renderer_found" == false ]]; then
    _doctor_log_quiet "  ${FLOW_COLORS[warning]}○${FLOW_COLORS[reset]} w3m ${FLOW_COLORS[muted]}(HTML rendering) ← brew install w3m${FLOW_COLORS[reset]}"
    _doctor_missing_email_brew+=("w3m")
  fi

  # --- glow (recommended) ---
  _doctor_check_email_cmd "glow" "brew" "recommended" "Markdown rendering"

  # --- email-oauth2-proxy (recommended) ---
  _doctor_check_email_cmd "email-oauth2-proxy" "pip" "recommended" "OAuth2 IMAP/SMTP proxy"

  # --- terminal-notifier (optional) ---
  _doctor_check_email_cmd "terminal-notifier" "brew" "optional" "Desktop notifications"

  # --- AI backend (conditional on $FLOW_EMAIL_AI) ---
  if [[ -n "$FLOW_EMAIL_AI" && "$FLOW_EMAIL_AI" != "none" ]]; then
    if [[ "$FLOW_EMAIL_AI" == "claude" ]]; then
      _doctor_check_email_cmd "claude" "npm:@anthropic-ai/claude-code" "optional" "AI drafts"
    elif [[ "$FLOW_EMAIL_AI" == "gemini" ]]; then
      _doctor_check_email_cmd "gemini" "pip:google-generativeai" "optional" "AI drafts"
    fi
  fi

  # --- Verbose: connectivity checks ---
  if [[ "$verbose" == true ]]; then
    _doctor_email_connectivity
  fi

  # --- Config summary ---
  _doctor_log_quiet ""
  _doctor_log_quiet "  ${FLOW_COLORS[muted]}Config:${FLOW_COLORS[reset]}"
  _doctor_log_quiet "    AI backend:  ${FLOW_COLORS[accent]}${FLOW_EMAIL_AI:-none}${FLOW_COLORS[reset]}"
  _doctor_log_quiet "    AI timeout:  ${FLOW_COLORS[accent]}${FLOW_EMAIL_AI_TIMEOUT:-30}s${FLOW_COLORS[reset]}"
  _doctor_log_quiet "    Page size:   ${FLOW_COLORS[accent]}${FLOW_EMAIL_PAGE_SIZE:-25}${FLOW_COLORS[reset]}"
  _doctor_log_quiet "    Folder:      ${FLOW_COLORS[accent]}${FLOW_EMAIL_FOLDER:-INBOX}${FLOW_COLORS[reset]}"

  local _email_config_file="${XDG_CONFIG_HOME:-$HOME/.config}/himalaya/config.toml"
  if [[ -f "$_email_config_file" ]]; then
    _doctor_log_quiet "    Config file: ${FLOW_COLORS[success]}${_email_config_file}${FLOW_COLORS[reset]}"
  else
    _doctor_log_quiet "    Config file: ${FLOW_COLORS[muted]}(none — using env defaults)${FLOW_COLORS[reset]}"
    _doctor_email_no_config=true
  fi

  _doctor_log_quiet ""
}

# Test email connectivity (verbose mode only)
# Tests: account config, IMAP ping, OAuth2 proxy, SMTP config
# All failures shown as warnings (yellow), not errors
_doctor_email_connectivity() {
  command -v himalaya >/dev/null 2>&1 || return 0

  _doctor_log_verbose ""
  _doctor_log_verbose "  ${FLOW_COLORS[muted]}Connectivity:${FLOW_COLORS[reset]}"

  # 1. Account config valid?
  local acct_out acct_rc
  acct_out=$(timeout 5 himalaya account list 2>&1)
  acct_rc=$?
  if [[ $acct_rc -eq 0 ]]; then
    local acct_name
    acct_name=$(echo "$acct_out" | grep -oE '\S+' | head -1)
    _doctor_log_verbose "    ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Account config valid ${FLOW_COLORS[muted]}(${acct_name:-default})${FLOW_COLORS[reset]}"
  else
    _doctor_log_verbose "    ${FLOW_COLORS[warning]}△${FLOW_COLORS[reset]} Account config: ${FLOW_COLORS[muted]}${acct_out:0:60}${FLOW_COLORS[reset]}"
  fi

  # 2. IMAP reachable? (fetch 1 envelope)
  local start_ts=$EPOCHREALTIME
  if timeout 5 himalaya envelope list --page-size 1 &>/dev/null; then
    local elapsed
    elapsed=$(printf "%.1f" $(( EPOCHREALTIME - start_ts )))
    _doctor_log_verbose "    ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} IMAP reachable ${FLOW_COLORS[muted]}(${elapsed}s)${FLOW_COLORS[reset]}"
  else
    _doctor_log_verbose "    ${FLOW_COLORS[warning]}△${FLOW_COLORS[reset]} IMAP: connection failed ${FLOW_COLORS[muted]}(check network/config)${FLOW_COLORS[reset]}"
  fi

  # 3. OAuth2 proxy running?
  if command -v email-oauth2-proxy >/dev/null 2>&1; then
    if pgrep -f email-oauth2-proxy &>/dev/null; then
      _doctor_log_verbose "    ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} OAuth2 proxy running"
    else
      _doctor_log_verbose "    ${FLOW_COLORS[warning]}△${FLOW_COLORS[reset]} OAuth2 proxy not running"
    fi
  fi

  # 4. SMTP config validation
  local config_file="${XDG_CONFIG_HOME:-$HOME/.config}/himalaya/config.toml"
  if [[ -f "$config_file" ]]; then
    if grep -q 'smtp' "$config_file" 2>/dev/null; then
      local smtp_info
      smtp_info=$(grep -E '(host|port|auth)' "$config_file" 2>/dev/null | head -3 | tr '\n' ', ' | sed 's/, $//')
      _doctor_log_verbose "    ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} SMTP configured ${FLOW_COLORS[muted]}${smtp_info:0:50}${FLOW_COLORS[reset]}"
    else
      _doctor_log_verbose "    ${FLOW_COLORS[warning]}△${FLOW_COLORS[reset]} SMTP: not configured in config.toml"
    fi
  else
    _doctor_log_verbose "    ${FLOW_COLORS[muted]}○${FLOW_COLORS[reset]} SMTP config: no config.toml found"
  fi
}

# Guided email configuration wizard (--fix mode)
# Creates ~/.config/himalaya/config.toml with interactive prompts
_doctor_email_setup() {
  _doctor_log_always ""
  _doctor_log_always "  ${FLOW_COLORS[bold]}📧 Email Setup${FLOW_COLORS[reset]}"
  _doctor_log_always "  ${FLOW_COLORS[muted]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"

  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/himalaya"
  local config_file="${config_dir}/config.toml"

  # Check existing config
  if [[ -f "$config_file" ]]; then
    _doctor_log_always ""
    _doctor_log_always "  ${FLOW_COLORS[warning]}Config exists:${FLOW_COLORS[reset]} $config_file"
    if ! _doctor_confirm "Overwrite existing config?"; then
      _doctor_log_always "  ${FLOW_COLORS[muted]}Keeping existing config${FLOW_COLORS[reset]}"
      return 0
    fi
  fi

  # Step 1: Email address
  _doctor_log_always ""
  local email_addr
  echo -n "  ${FLOW_COLORS[info]}? Email address:${FLOW_COLORS[reset]} "
  read -r email_addr
  [[ -z "$email_addr" ]] && { _doctor_log_always "  ${FLOW_COLORS[error]}Cancelled${FLOW_COLORS[reset]}"; return 1; }

  # Step 2: Auto-detect provider
  local domain="${email_addr##*@}"
  local imap_host="" imap_port="993" smtp_host="" smtp_port="587" auth_method=""

  case "$domain" in
    gmail.com|googlemail.com)
      imap_host="imap.gmail.com"; smtp_host="smtp.gmail.com"; auth_method="oauth2"
      _doctor_log_always "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Detected Gmail ${FLOW_COLORS[muted]}(OAuth2 recommended)${FLOW_COLORS[reset]}"
      ;;
    outlook.com|hotmail.com|live.com)
      imap_host="outlook.office365.com"; smtp_host="smtp.office365.com"; auth_method="oauth2"
      _doctor_log_always "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Detected Outlook ${FLOW_COLORS[muted]}(OAuth2 recommended)${FLOW_COLORS[reset]}"
      ;;
    yahoo.com|ymail.com)
      imap_host="imap.mail.yahoo.com"; smtp_host="smtp.mail.yahoo.com"; auth_method="password"
      _doctor_log_always "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Detected Yahoo ${FLOW_COLORS[muted]}(App Password required)${FLOW_COLORS[reset]}"
      ;;
    icloud.com|me.com|mac.com)
      imap_host="imap.mail.me.com"; smtp_host="smtp.mail.me.com"; auth_method="password"
      _doctor_log_always "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Detected iCloud ${FLOW_COLORS[muted]}(App Password required)${FLOW_COLORS[reset]}"
      ;;
    *)
      _doctor_log_always "  ${FLOW_COLORS[muted]}Custom provider — please enter server details${FLOW_COLORS[reset]}"
      ;;
  esac

  # Step 3: IMAP server (confirm or enter)
  local input
  echo -n "  ${FLOW_COLORS[info]}? IMAP server${FLOW_COLORS[reset]}${imap_host:+ [${imap_host}]}: "
  read -r input
  [[ -n "$input" ]] && imap_host="$input"
  [[ -z "$imap_host" ]] && { _doctor_log_always "  ${FLOW_COLORS[error]}IMAP server required${FLOW_COLORS[reset]}"; return 1; }

  echo -n "  ${FLOW_COLORS[info]}? IMAP port${FLOW_COLORS[reset]} [${imap_port}]: "
  read -r input
  [[ -n "$input" ]] && imap_port="$input"

  # Step 4: SMTP server
  echo -n "  ${FLOW_COLORS[info]}? SMTP server${FLOW_COLORS[reset]}${smtp_host:+ [${smtp_host}]}: "
  read -r input
  [[ -n "$input" ]] && smtp_host="$input"
  [[ -z "$smtp_host" ]] && { _doctor_log_always "  ${FLOW_COLORS[error]}SMTP server required${FLOW_COLORS[reset]}"; return 1; }

  echo -n "  ${FLOW_COLORS[info]}? SMTP port${FLOW_COLORS[reset]} [${smtp_port}]: "
  read -r input
  [[ -n "$input" ]] && smtp_port="$input"

  # Step 5: Auth method
  if [[ -z "$auth_method" ]]; then
    _doctor_log_always ""
    _doctor_log_always "  ${FLOW_COLORS[bold]}Auth method:${FLOW_COLORS[reset]}"
    _doctor_log_always "    1) OAuth2 ${FLOW_COLORS[muted]}(Gmail, Outlook)${FLOW_COLORS[reset]}"
    _doctor_log_always "    2) App Password ${FLOW_COLORS[muted]}(Yahoo, iCloud)${FLOW_COLORS[reset]}"
    _doctor_log_always "    3) Plain password ${FLOW_COLORS[muted]}(other providers)${FLOW_COLORS[reset]}"
    echo -n "  ${FLOW_COLORS[info]}? Auth [1-3]:${FLOW_COLORS[reset]} "
    read -r input
    case "$input" in
      1) auth_method="oauth2" ;;
      2) auth_method="password" ;;
      3) auth_method="password" ;;
      *) auth_method="password" ;;
    esac
  fi

  # Step 6: Generate config
  mkdir -p "$config_dir"

  if [[ "$auth_method" == "oauth2" ]]; then
    cat > "$config_file" <<TOML
# himalaya config — generated by flow doctor
# Docs: https://pimalaya.org/himalaya/

[accounts.default]
email = "${email_addr}"
display-name = ""
default = true

backend.type = "imap"
backend.host = "${imap_host}"
backend.port = ${imap_port}
backend.encryption = "tls"
backend.auth.type = "oauth2"
backend.auth.method = "xoauth2"
# Configure email-oauth2-proxy or set tokens here

message.send.backend.type = "smtp"
message.send.backend.host = "${smtp_host}"
message.send.backend.port = ${smtp_port}
message.send.backend.encryption = "start-tls"
message.send.backend.auth.type = "oauth2"
message.send.backend.auth.method = "xoauth2"
TOML
  else
    cat > "$config_file" <<TOML
# himalaya config — generated by flow doctor
# Docs: https://pimalaya.org/himalaya/

[accounts.default]
email = "${email_addr}"
display-name = ""
default = true

backend.type = "imap"
backend.host = "${imap_host}"
backend.port = ${imap_port}
backend.encryption = "tls"
backend.auth.type = "password"
backend.auth.command = "security find-generic-password -s himalaya-${domain} -a ${email_addr} -w"

message.send.backend.type = "smtp"
message.send.backend.host = "${smtp_host}"
message.send.backend.port = ${smtp_port}
message.send.backend.encryption = "start-tls"
message.send.backend.auth.type = "password"
message.send.backend.auth.command = "security find-generic-password -s himalaya-${domain} -a ${email_addr} -w"
TOML
  fi

  _doctor_log_always ""
  _doctor_log_always "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Config written to ${config_file}"

  # Step 7: OAuth2 proxy guidance
  if [[ "$auth_method" == "oauth2" ]]; then
    _doctor_log_always ""
    _doctor_log_always "  ${FLOW_COLORS[bold]}OAuth2 setup:${FLOW_COLORS[reset]}"
    if command -v email-oauth2-proxy >/dev/null 2>&1; then
      _doctor_log_always "    ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} email-oauth2-proxy installed"
      _doctor_log_always "    ${FLOW_COLORS[muted]}Configure tokens: email-oauth2-proxy --config${FLOW_COLORS[reset]}"
    else
      _doctor_log_always "    ${FLOW_COLORS[warning]}△${FLOW_COLORS[reset]} email-oauth2-proxy not installed"
      _doctor_log_always "    ${FLOW_COLORS[muted]}Install: pip install email-oauth2-proxy${FLOW_COLORS[reset]}"
    fi
  else
    _doctor_log_always ""
    _doctor_log_always "  ${FLOW_COLORS[bold]}Password setup:${FLOW_COLORS[reset]}"
    _doctor_log_always "    Store password in macOS Keychain:"
    _doctor_log_always "    ${FLOW_COLORS[accent]}security add-generic-password -s himalaya-${domain} -a ${email_addr} -w${FLOW_COLORS[reset]}"
  fi

  # Step 8: Run connectivity test
  _doctor_log_always ""
  _doctor_log_always "  ${FLOW_COLORS[info]}Testing connection...${FLOW_COLORS[reset]}"

  if command -v himalaya >/dev/null 2>&1; then
    local test_out
    test_out=$(timeout 5 himalaya account list 2>&1)
    if [[ $? -eq 0 ]]; then
      _doctor_log_always "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Account config valid"

      if timeout 5 himalaya envelope list --page-size 1 &>/dev/null; then
        _doctor_log_always "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} IMAP connected"
        _doctor_log_always ""
        _doctor_log_always "  ${FLOW_COLORS[success]}✓ Email setup complete!${FLOW_COLORS[reset]}"
      else
        _doctor_log_always "  ${FLOW_COLORS[warning]}△${FLOW_COLORS[reset]} IMAP connection failed ${FLOW_COLORS[muted]}(check auth config)${FLOW_COLORS[reset]}"
      fi
    else
      _doctor_log_always "  ${FLOW_COLORS[warning]}△${FLOW_COLORS[reset]} Config test failed: ${FLOW_COLORS[muted]}${test_out:0:60}${FLOW_COLORS[reset]}"
      _doctor_log_always "  ${FLOW_COLORS[muted]}Edit: ${config_file}${FLOW_COLORS[reset]}"
    fi
  else
    _doctor_log_always "  ${FLOW_COLORS[warning]}△${FLOW_COLORS[reset]} himalaya not installed — install first, then re-run"
  fi

  _doctor_log_always ""
}

# Fix email dependencies (--fix mode)
_doctor_fix_email() {
  local auto_yes="${1:-false}"

  _doctor_log_always "${FLOW_COLORS[info]}📧 Fixing email tools...${FLOW_COLORS[reset]}"
  _doctor_log_always ""

  # Install brew packages
  if [[ ${#_doctor_missing_email_brew[@]} -gt 0 ]]; then
    for pkg in "${_doctor_missing_email_brew[@]}"; do
      if [[ "$auto_yes" == true ]] || _doctor_confirm "Install $pkg via brew?"; then
        _doctor_log_always "  ${FLOW_COLORS[info]}Installing $pkg...${FLOW_COLORS[reset]}"
        if brew install "$pkg" 2>&1 | tail -1; then
          _doctor_log_always "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $pkg installed"
        else
          _doctor_log_always "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} Failed to install $pkg"
        fi
      fi
    done
  fi

  # Install pip packages
  if [[ ${#_doctor_missing_email_pip[@]} -gt 0 ]]; then
    for pkg in "${_doctor_missing_email_pip[@]}"; do
      if [[ "$auto_yes" == true ]] || _doctor_confirm "Install $pkg via pip?"; then
        _doctor_log_always "  ${FLOW_COLORS[info]}Installing $pkg...${FLOW_COLORS[reset]}"
        if pip install "$pkg" 2>&1 | tail -1; then
          _doctor_log_always "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $pkg installed"
        else
          _doctor_log_always "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} Failed to install $pkg"
        fi
      fi
    done
  fi

  # Guided setup if no config found
  if [[ "$_doctor_email_no_config" == true ]]; then
    if [[ "$auto_yes" == true ]] || _doctor_confirm "Set up himalaya email config?"; then
      _doctor_email_setup
    fi
  fi

  _doctor_log_always ""
}

_doctor_check_zsh_plugin() {
  local name="$1"
  local repo="$2"
  local plugins_file="${ZDOTDIR:-$HOME/.config/zsh}/.zsh_plugins.txt"
  local antidote_home="${ANTIDOTE_HOME:-$HOME/.cache/antidote}"

  # Check if in plugins.txt
  local in_list=false
  if [[ -f "$plugins_file" ]] && grep -q "$repo" "$plugins_file" 2>/dev/null; then
    in_list=true
  fi

  # Check if actually loaded (more thorough check)
  local loaded=false
  case "$name" in
    powerlevel10k)
      # p10k sets POWERLEVEL9K_MODE
      [[ -n "$POWERLEVEL9K_MODE" ]] && loaded=true
      ;;
    autosuggestions)
      # Check if _zsh_autosuggest function exists
      (( $+functions[_zsh_autosuggest_start] )) && loaded=true
      ;;
    syntax-highlighting)
      # Check if highlighting is active
      (( $+functions[_zsh_highlight] )) && loaded=true
      ;;
    completions)
      # Check if site-functions includes zsh-completions
      [[ "$fpath" == *"zsh-completions"* ]] && loaded=true
      ;;
    *)
      # Generic check - assume in_list means loaded
      $in_list && loaded=true
      ;;
  esac

  if $loaded; then
    _doctor_log_quiet "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $name ${FLOW_COLORS[muted]}(active)${FLOW_COLORS[reset]}"
    return 0
  elif $in_list; then
    _doctor_log_quiet "  ${FLOW_COLORS[warning]}△${FLOW_COLORS[reset]} $name ${FLOW_COLORS[muted]}(listed but not loaded - restart shell)${FLOW_COLORS[reset]}"
    return 1
  else
    _doctor_log_quiet "  ${FLOW_COLORS[muted]}○${FLOW_COLORS[reset]} $name ${FLOW_COLORS[muted]}(not configured)${FLOW_COLORS[reset]}"
    return 1
  fi
}

# Check ZSH plugin manager
_doctor_check_plugin_manager() {
  _doctor_log_quiet "${FLOW_COLORS[bold]}🔌 PLUGIN MANAGER${FLOW_COLORS[reset]}"

  # Check antidote
  if command -v antidote >/dev/null 2>&1; then
    local version=$(antidote --version 2>/dev/null | head -1)
    _doctor_log_quiet "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} antidote ${FLOW_COLORS[muted]}$version${FLOW_COLORS[reset]}"

    # Check bundle file
    local bundle_file="${ZDOTDIR:-$HOME/.config/zsh}/.zsh_plugins.txt"
    if [[ -f "$bundle_file" ]]; then
      local plugin_count=$(grep -v '^#' "$bundle_file" | grep -v '^$' | wc -l | tr -d ' ')
      _doctor_log_quiet "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} plugins.txt ${FLOW_COLORS[muted]}($plugin_count plugins)${FLOW_COLORS[reset]}"
    else
      _doctor_log_quiet "  ${FLOW_COLORS[warning]}△${FLOW_COLORS[reset]} plugins.txt ${FLOW_COLORS[muted]}not found${FLOW_COLORS[reset]}"
    fi
  elif command -v zinit >/dev/null 2>&1; then
    _doctor_log_quiet "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} zinit"
  elif [[ -d "$HOME/.oh-my-zsh" ]]; then
    _doctor_log_quiet "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} oh-my-zsh"
  else
    _doctor_log_quiet "  ${FLOW_COLORS[muted]}○${FLOW_COLORS[reset]} No plugin manager detected"
  fi
  _doctor_log_quiet ""
}

_doctor_confirm() {
  local prompt="$1"
  local response

  echo -n "${FLOW_COLORS[info]}? ${prompt}${FLOW_COLORS[reset]} [Y/n] "
  read -r response

  case "$response" in
    [nN]|[nN][oO]) return 1 ;;
    *) return 0 ;;
  esac
}

_doctor_help() {
  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}flow doctor${FLOW_COLORS[reset]} - Health Check                  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
  echo "  doctor [options]"
  echo ""
  echo "${FLOW_COLORS[bold]}MODES${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}(default)${FLOW_COLORS[reset]}          Check and show status"
  echo "  ${FLOW_COLORS[accent]}-f, --fix${FLOW_COLORS[reset]}          Interactive install missing tools"
  echo "  ${FLOW_COLORS[accent]}-a, --ai${FLOW_COLORS[reset]}           AI-assisted troubleshooting (Claude CLI)"
  echo "  ${FLOW_COLORS[accent]}-u, --update-docs${FLOW_COLORS[reset]}  Regenerate help files and docs"
  echo ""
  echo "${FLOW_COLORS[bold]}TOKEN AUTOMATION (v5.17.0)${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}--dot${FLOW_COLORS[reset]}              Check only DOT tokens (isolated check)"
  echo "  ${FLOW_COLORS[accent]}--dot=TOKEN${FLOW_COLORS[reset]}        Check specific token (e.g., --dot=github)"
  echo "  ${FLOW_COLORS[accent]}--fix-token${FLOW_COLORS[reset]}        Fix only token issues (< 60s)"
  echo ""
  echo "${FLOW_COLORS[bold]}VERBOSITY OPTIONS${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}-q, --quiet${FLOW_COLORS[reset]}        Minimal output (errors only)"
  echo "  ${FLOW_COLORS[accent]}-v, --verbose${FLOW_COLORS[reset]}      Detailed output + connectivity checks"
  echo ""
  echo "${FLOW_COLORS[bold]}EMAIL (conditional)${FLOW_COLORS[reset]}"
  echo "  When the ${FLOW_COLORS[accent]}em${FLOW_COLORS[reset]} dispatcher is loaded, checks himalaya + email deps."
  echo "  ${FLOW_COLORS[accent]}--verbose${FLOW_COLORS[reset]}          Also tests IMAP connectivity, OAuth2, SMTP"
  echo "  ${FLOW_COLORS[accent]}--fix${FLOW_COLORS[reset]}              Installs missing email tools + guided setup"
  echo ""
  echo "${FLOW_COLORS[bold]}OTHER OPTIONS${FLOW_COLORS[reset]}"
  echo "  -y, --yes      Skip confirmations (use with --fix)"
  echo "  -h, --help     Show this help"
  echo ""
  echo "${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} doctor                # Quick health check"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} doctor --fix          # Interactively fix issues"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} doctor --fix -y       # Auto-install all missing"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} doctor --dot          # Check only DOT tokens (< 3s)"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} doctor --dot=github   # Check GitHub token only"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} doctor --fix-token    # Fix token issues only"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} doctor --quiet        # Show only errors"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} doctor --verbose      # Show detailed info + cache status"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} doctor --ai           # Get AI help deciding what to install"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} doctor --update-docs  # Regenerate documentation"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} flow doctor           # Also works via flow command"
  echo ""
  echo "${FLOW_COLORS[bold]}INSTALL ALL AT ONCE${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}brew bundle --file=\$FLOW_PLUGIN_DIR/setup/Brewfile${FLOW_COLORS[reset]}"
  echo ""
}

# Check aliases health (quick summary for doctor)
_doctor_check_aliases() {
  _doctor_log_quiet "${FLOW_COLORS[bold]}⚡ ALIASES${FLOW_COLORS[reset]}"

  local zshrc="${ZDOTDIR:-$HOME}/.zshrc"
  [[ -f "$zshrc" ]] || zshrc="$HOME/.config/zsh/.zshrc"

  if [[ ! -f "$zshrc" ]]; then
    _doctor_log_quiet "  ${FLOW_COLORS[warning]}△${FLOW_COLORS[reset]} .zshrc not found"
    _doctor_log_quiet ""
    return
  fi

  # Quick count of aliases
  local total_aliases=0
  local shadow_count=0
  local broken_count=0

  while IFS= read -r line; do
    local alias_def="${line#*:}"
    alias_def="${alias_def#alias }"
    local alias_name="${alias_def%%=*}"
    local alias_value="${alias_def#*=}"
    alias_value="${alias_value#[\'\"]}"
    alias_value="${alias_value%[\'\"]}"

    [[ -z "$alias_name" ]] && continue
    ((total_aliases++))

    # Quick shadow check (suppress any debug output)
    local shadow_path=""
    shadow_path=$(command -v "$alias_name" 2>/dev/null) || true
    if [[ -n "$shadow_path" && -x "$shadow_path" ]]; then
      ((shadow_count++))
      _doctor_alias_issues+=("$alias_name")
    fi

    # Quick target check
    local target_cmd="${alias_value%% *}"
    if ! command -v "$target_cmd" &>/dev/null && ! type "$target_cmd" &>/dev/null 2>&1; then
      ((broken_count++))
      _doctor_alias_issues+=("$alias_name")
    fi
  done < <(grep -n "^alias " "$zshrc" 2>/dev/null)

  # Show summary
  if [[ $total_aliases -eq 0 ]]; then
    _doctor_log_quiet "  ${FLOW_COLORS[muted]}○${FLOW_COLORS[reset]} No aliases found in .zshrc"
  elif [[ $shadow_count -eq 0 && $broken_count -eq 0 ]]; then
    _doctor_log_quiet "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $total_aliases aliases ${FLOW_COLORS[muted]}(all healthy)${FLOW_COLORS[reset]}"
  else
    local issues=""
    [[ $shadow_count -gt 0 ]] && issues="$shadow_count shadows"
    [[ $broken_count -gt 0 ]] && {
      [[ -n "$issues" ]] && issues+=", "
      issues+="$broken_count broken"
    }
    _doctor_log_quiet "  ${FLOW_COLORS[warning]}△${FLOW_COLORS[reset]} $total_aliases aliases ${FLOW_COLORS[muted]}($issues)${FLOW_COLORS[reset]}"
    _doctor_log_quiet "    ${FLOW_COLORS[muted]}Run ${FLOW_COLORS[accent]}flow alias doctor${FLOW_COLORS[muted]} for details${FLOW_COLORS[reset]}"
  fi
  _doctor_log_quiet ""
}

# Alias for discoverability
alias flow-doctor='doctor'
