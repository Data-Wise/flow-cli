# dot-doctor-integration.zsh - Doctor integration for dotfile management
# This file provides the _dot_doctor() function to be called from flow doctor

# ============================================================================
# DOT DOCTOR - Dotfile Health Checks
# ============================================================================

_dot_doctor() {
  if ! _dot_has_chezmoi; then
    _flow_log_info "Chezmoi not installed (dotfile management disabled)"
    return 0
  fi

  echo "${FLOW_COLORS[bold]}📁 DOTFILES${FLOW_COLORS[reset]}"

  # Check chezmoi installation
  _doctor_check_cmd "chezmoi" "brew" "optional"

  # Check Bitwarden CLI (for secrets)
  _doctor_check_cmd "bw" "brew:bitwarden-cli" "optional"

  # Check chezmoi initialization
  local chezmoi_dir="${HOME}/.local/share/chezmoi"
  if [[ -d "$chezmoi_dir" ]]; then
    if [[ -d "$chezmoi_dir/.git" ]]; then
      _flow_log_success "Chezmoi initialized with git"

      # Check remote configured
      local remote_url=$(cd "$chezmoi_dir" && git remote get-url origin 2>/dev/null)
      if [[ -n "$remote_url" ]]; then
        _flow_log_success "Remote configured: $remote_url"
      else
        _flow_log_warning "No git remote configured"
      fi

      # Check for uncommitted changes
      local status_output=$(chezmoi status 2>/dev/null)
      if [[ -n "$status_output" ]]; then
        local count=$(echo "$status_output" | wc -l | tr -d ' ')
        _flow_log_warning "$count uncommitted changes"
      else
        _flow_log_success "No uncommitted changes"
      fi

      # Check sync status
      local sync_status=$(_dot_get_sync_status)
      case "$sync_status" in
        synced)
          _flow_log_success "Synced with remote"
          ;;
        ahead)
          _flow_log_warning "Ahead of remote (need to push)"
          ;;
        behind)
          _flow_log_error "Behind remote (need to pull)"
          ;;
        modified)
          _flow_log_warning "Local modifications pending"
          ;;
      esac

    else
      _flow_log_warning "Chezmoi initialized without git"
    fi
  else
    _flow_log_error "Chezmoi not initialized. Run: chezmoi init"
  fi

  # Check Bitwarden session
  if _dot_has_bw; then
    local bw_status=$(_dot_bw_get_status)
    case "$bw_status" in
      unlocked)
        _flow_log_success "Bitwarden vault unlocked"

        # Check for security issues
        if ! _dot_security_check_bw_session; then
          _flow_log_error "Security issue detected (see above)"
        fi
        ;;
      locked)
        _flow_log_info "Bitwarden vault locked (run: dot unlock)"
        ;;
      unauthenticated)
        _flow_log_warning "Bitwarden not authenticated (run: bw login)"
        ;;
    esac
  fi

  echo ""
}

# ============================================================================
# HELPER: Check command (for doctor integration)
# ============================================================================

# This function mimics _doctor_check_cmd from doctor.zsh
# It's a simplified version for when doctor.zsh is not available
_dot_doctor_check_cmd() {
  local cmd="$1"
  local install_method="$2"
  local level="$3"

  if command -v "$cmd" &>/dev/null; then
    local version=$("$cmd" --version 2>/dev/null | head -1)
    echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $cmd ${FLOW_COLORS[muted]}($version)${FLOW_COLORS[reset]}"
  else
    echo "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} $cmd ${FLOW_COLORS[muted]}(not installed)${FLOW_COLORS[reset]}"
    if [[ -n "$install_method" ]]; then
      echo "    ${FLOW_COLORS[info]}Install: ${install_method}${FLOW_COLORS[reset]}"
    fi
  fi
}
