#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# DOT - Dotfile Management Dispatcher
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         lib/dispatchers/dot-dispatcher.zsh
# Version:      2.2.0 (Secret Management v2.0 - Complete)
# Date:         2026-01-10
# Pattern:      command + keyword + options
#
# Usage:        dot <action> [args]
#
# Examples:
#   dot                   # Status overview (default)
#   dot status            # Show sync status
#   dot help              # Show all commands
#   dot edit .zshrc       # Edit dotfile (Phase 2)
#   dot sync              # Pull from remote (Phase 2)
#   dot unlock            # Unlock Bitwarden (Phase 3)
#
# Dependencies:
#   - chezmoi (optional): dotfile sync
#   - bw (optional): secret management
#   - mise (optional): version management
#
# ══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════
# MAIN DOT() DISPATCHER
# ═══════════════════════════════════════════════════════════════════

dot() {
  # No arguments → show status (most common - zero effort)
  if [[ $# -eq 0 ]]; then
    _dot_status
    return
  fi

  case "$1" in
    # ─────────────────────────────────────────────────────────────
    # STATUS & INFO
    # ─────────────────────────────────────────────────────────────
    status|s)
      shift
      _dot_status "$@"
      ;;

    help|--help|-h)
      _dot_help
      ;;

    version|--version|-v)
      _dot_version
      ;;

    # ─────────────────────────────────────────────────────────────
    # DOTFILE MANAGEMENT (Phase 2)
    # ─────────────────────────────────────────────────────────────
    add)
      shift
      _dot_add "$@"
      ;;

    edit|e)
      shift
      _dot_edit "$@"
      ;;

    sync|pull)
      shift
      _dot_sync "$@"
      ;;

    push|p)
      shift
      _dot_push "$@"
      ;;

    diff|d)
      shift
      _dot_diff "$@"
      ;;

    apply|a)
      shift
      _dot_apply "$@"
      ;;

    # ─────────────────────────────────────────────────────────────
    # SECRET MANAGEMENT (Phase 3 - placeholders)
    # ─────────────────────────────────────────────────────────────
    unlock|u)
      shift
      _dot_unlock "$@"
      ;;

    lock|l)
      shift
      _dot_lock "$@"
      ;;

    secret)
      shift
      _dot_secret "$@"
      ;;

    # Token wizards (Phase 2 - Secret Management v2.0)
    token|tok)
      shift
      _dot_token "$@"
      ;;

    # Secrets dashboard (Phase 2 - Secret Management v2.0)
    secrets)
      shift
      _dot_secrets "$@"
      ;;

    # ─────────────────────────────────────────────────────────────
    # TROUBLESHOOTING (Phase 3 - placeholders)
    # ─────────────────────────────────────────────────────────────
    doctor|dr)
      shift
      _dot_doctor "$@"
      ;;

    undo)
      shift
      _dot_undo "$@"
      ;;

    init)
      shift
      _dot_init "$@"
      ;;

    # Direnv integration (Phase 3 - v2.2.0)
    env)
      shift
      _dot_env "$@"
      ;;

    # ─────────────────────────────────────────────────────────────
    # PASSTHROUGH (advanced usage)
    # ─────────────────────────────────────────────────────────────
    *)
      # Pass through to chezmoi if available
      if _dot_has_chezmoi; then
        chezmoi "$@"
      else
        _flow_log_error "Unknown command: $1"
        _flow_log_info "Run 'dot help' for available commands"
        return 1
      fi
      ;;
  esac
}

# ═══════════════════════════════════════════════════════════════════
# STATUS COMMAND (Phase 1)
# ═══════════════════════════════════════════════════════════════════

_dot_status() {
  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}📁 Dotfiles Status${FLOW_COLORS[reset]}                                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

  # Check if chezmoi is installed
  if ! _dot_has_chezmoi; then
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  State: $(_dot_format_status "not-installed")                        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Chezmoi not found. Install:${FLOW_COLORS[reset]}                    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}brew install chezmoi${FLOW_COLORS[reset]}                         ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Then initialize:${FLOW_COLORS[reset]}                               ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}chezmoi init${FLOW_COLORS[reset]}                                  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
    echo ""
    return 1
  fi

  # Get sync status
  local sync_status=$(_dot_get_sync_status)
  local formatted_status=$(_dot_format_status "$sync_status")

  # Display status
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  State: $formatted_status                           ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

  if [[ "$sync_status" == "not-initialized" ]]; then
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Initialize chezmoi:${FLOW_COLORS[reset]}                            ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}chezmoi init${FLOW_COLORS[reset]}                                  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
    echo ""
    return 0
  fi

  # Get additional info
  local last_sync=$(_dot_get_last_sync_time)
  local tracked_count=$(_dot_get_tracked_count)
  local modified_count=$(_dot_get_modified_count)

  # Display info
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Last sync: ${last_sync}                              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Tracked files: ${tracked_count}                                 ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

  if [[ $modified_count -gt 0 ]]; then
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[warning]}Modified: ${modified_count} files${FLOW_COLORS[reset]}                            ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  fi

  # Bitwarden vault status (if installed)
  if _dot_has_bw; then
    if _dot_bw_session_valid; then
      local time_remaining=$(_dot_session_time_remaining_fmt)
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Vault: ${FLOW_COLORS[success]}🔓 Unlocked${FLOW_COLORS[reset]} (${time_remaining} remaining)         ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    else
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Vault: ${FLOW_COLORS[muted]}🔒 Locked${FLOW_COLORS[reset]}                               ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    fi
  fi

  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

  # Show quick actions based on status
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Quick actions:${FLOW_COLORS[reset]}                                 ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

  case "$sync_status" in
    synced)
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot edit .zshrc${FLOW_COLORS[reset]}    Edit shell config             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot sync${FLOW_COLORS[reset]}           Pull latest changes           ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      ;;
    modified)
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot diff${FLOW_COLORS[reset]}           Show pending changes          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot push${FLOW_COLORS[reset]}           Push changes to remote        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      ;;
    behind)
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot sync${FLOW_COLORS[reset]}           Pull latest changes           ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      ;;
    ahead)
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot push${FLOW_COLORS[reset]}           Push changes to remote        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      ;;
  esac

  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot help${FLOW_COLORS[reset]}           Show all commands             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

# ═══════════════════════════════════════════════════════════════════
# HELP COMMAND (Phase 1)
# ═══════════════════════════════════════════════════════════════════

_dot_help() {
  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}dot - Dotfile Management${FLOW_COLORS[reset]}                         ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[accent]}COMMON COMMANDS${FLOW_COLORS[reset]}                                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot${FLOW_COLORS[reset]}              Show status + quick actions     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot add FILE${FLOW_COLORS[reset]}     Add file to chezmoi             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot edit FILE${FLOW_COLORS[reset]}    Edit dotfile (auto-add/create)  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot sync${FLOW_COLORS[reset]}         Pull latest changes from remote ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot push${FLOW_COLORS[reset]}         Push local changes to remote    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot diff${FLOW_COLORS[reset]}         Show pending changes            ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot apply${FLOW_COLORS[reset]}        Apply changes to home directory ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot apply -n${FLOW_COLORS[reset]}     Dry-run (preview without apply) ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[accent]}SECRET MANAGEMENT${FLOW_COLORS[reset]}                             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot unlock${FLOW_COLORS[reset]}       Unlock vault (15m timeout)      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot lock${FLOW_COLORS[reset]}         Lock vault immediately          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot secret NAME${FLOW_COLORS[reset]}  Retrieve secret (no echo)       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot secret list${FLOW_COLORS[reset]}  Show available secrets          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot secret add${FLOW_COLORS[reset]}   Store new secret                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot secret check${FLOW_COLORS[reset]} Show expiring secrets           ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot secrets${FLOW_COLORS[reset]}      Dashboard of all secrets        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[accent]}TOKEN MANAGEMENT${FLOW_COLORS[reset]}                              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot token github${FLOW_COLORS[reset]} GitHub PAT creation wizard      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot token npm${FLOW_COLORS[reset]}    NPM token creation wizard       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot token pypi${FLOW_COLORS[reset]}   PyPI token creation wizard      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot token <name> --refresh${FLOW_COLORS[reset]} Rotate token       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[accent]}INTEGRATION${FLOW_COLORS[reset]}                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot secrets sync github${FLOW_COLORS[reset]}  Sync to GitHub repo    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot env init${FLOW_COLORS[reset]}         Generate .envrc for direnv  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[accent]}TROUBLESHOOTING${FLOW_COLORS[reset]}                               ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot doctor${FLOW_COLORS[reset]}       Run diagnostics                 ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot undo${FLOW_COLORS[reset]}         Rollback last apply             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot help${FLOW_COLORS[reset]}         Show this help                  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[accent]}EXAMPLES${FLOW_COLORS[reset]}                                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot edit .zshrc${FLOW_COLORS[reset]}           Edit shell config      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot edit ~/.newrc${FLOW_COLORS[reset]}         Create + add new file  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot add ~/.bashrc${FLOW_COLORS[reset]}         Start tracking file    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot sync${FLOW_COLORS[reset]}                  Pull from remote       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot secret github-token${FLOW_COLORS[reset]}   Get GitHub token       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[success]}✓ Phase 1: Status & help${FLOW_COLORS[reset]}                      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[success]}✓ Phase 2: Edit/sync workflows${FLOW_COLORS[reset]}                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[success]}✓ Phase 3: Secret management${FLOW_COLORS[reset]}                  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

# ═══════════════════════════════════════════════════════════════════
# VERSION COMMAND (Phase 1)
# ═══════════════════════════════════════════════════════════════════

_dot_version() {
  echo "dot dispatcher v2.2.0 (Secret Management v2.0 - Complete)"
  echo "Part of flow-cli v5.1.0"
  echo ""
  echo "Tools:"
  if _dot_has_chezmoi; then
    local chezmoi_version=$(chezmoi --version 2>/dev/null | head -1)
    echo "  ✓ chezmoi: $chezmoi_version"
  else
    echo "  ✗ chezmoi: not installed"
  fi

  if _dot_has_bw; then
    local bw_version=$(bw --version 2>/dev/null)
    echo "  ✓ bw: v$bw_version"
  else
    echo "  ✗ bw: not installed"
  fi

  if _dot_has_mise; then
    local mise_version=$(mise --version 2>/dev/null)
    echo "  ✓ mise: $mise_version"
  else
    echo "  ✗ mise: not installed"
  fi
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 2: CORE WORKFLOWS
# ═══════════════════════════════════════════════════════════════════

# Edit workflow: edit file → show diff → apply
_dot_edit() {
  if ! _dot_require_tool "chezmoi" "brew install chezmoi"; then
    return 1
  fi

  local file_arg="$1"
  if [[ -z "$file_arg" ]]; then
    _flow_log_error "Usage: dot edit <file>"
    _flow_log_info "Examples:"
    echo "  dot edit .zshrc"
    echo "  dot edit zshrc     (fuzzy match)"
    echo "  dot edit ~/.newrc  (create new)"
    return 1
  fi

  # Track state for summary
  local was_added=false
  local was_created=false
  local action_type="Edited"

  # Resolve file path (supports fuzzy matching)
  local resolved_path
  resolved_path=$(_dot_resolve_file_path "$file_arg")
  local resolve_status=$?

  if [[ $resolve_status -eq 1 ]]; then
    # File not tracked - check if it exists or needs creation
    local full_path="${file_arg/#\~/$HOME}"
    [[ "$full_path" != /* ]] && full_path="$HOME/$full_path"

    if [[ -f "$full_path" ]]; then
      # File exists but not tracked - offer to add
      echo ""
      _flow_log_warning "File not tracked: $file_arg"
      echo ""
      echo "  ${FLOW_COLORS[cmd]}a${FLOW_COLORS[reset]} - Add to chezmoi and edit"
      echo "  ${FLOW_COLORS[cmd]}n${FLOW_COLORS[reset]} - Cancel"
      echo ""
      read -q "?Add? [a/n] " add_response
      echo ""

      if [[ "$add_response" == "a" ]]; then
        _dot_add_file "$full_path" || return 1
        was_added=true
        action_type="Added"
        resolved_path="$full_path"
      else
        _flow_log_muted "Cancelled"
        return 0
      fi
    else
      # File doesn't exist - offer to create
      echo ""
      _flow_log_warning "File does not exist: $file_arg"
      echo ""
      echo "  ${FLOW_COLORS[cmd]}c${FLOW_COLORS[reset]} - Create, add to chezmoi, and edit"
      echo "  ${FLOW_COLORS[cmd]}n${FLOW_COLORS[reset]} - Cancel"
      echo ""
      read -q "?Create? [c/n] " create_response
      echo ""

      if [[ "$create_response" == "c" ]]; then
        # Create parent directories if needed
        local parent_dir="${full_path:h}"
        if [[ ! -d "$parent_dir" ]]; then
          mkdir -p "$parent_dir" || { _flow_log_error "Failed to create directory: $parent_dir"; return 1; }
          _flow_log_muted "Created directory: $parent_dir"
        fi

        # Create empty file
        touch "$full_path" || { _flow_log_error "Failed to create file"; return 1; }
        _flow_log_success "Created ${file_arg}"

        # Add to chezmoi
        _dot_add_file "$full_path" || return 1
        was_added=true
        was_created=true
        action_type="Created"
        resolved_path="$full_path"
      else
        _flow_log_muted "Cancelled"
        return 0
      fi
    fi
  elif [[ $resolve_status -eq 2 ]]; then
    # Multiple matches - show selection
    _flow_log_warning "Multiple matches found:"
    echo "$resolved_path"
    _flow_log_info "Please be more specific"
    return 1
  fi

  # Get source file path in chezmoi repo
  local source_path
  source_path=$(chezmoi source-path "$resolved_path" 2>/dev/null)
  if [[ -z "$source_path" ]]; then
    _flow_log_error "Could not determine source path for: $resolved_path"
    return 1
  fi

  # Get file hash before editing (more reliable than mtime)
  local before_hash
  if [[ -f "$source_path" ]]; then
    before_hash=$(shasum -a 256 "$source_path" 2>/dev/null | cut -d' ' -f1 || echo "0")
  else
    before_hash="0"
  fi

  # Open in editor
  local editor="${EDITOR:-vim}"
  _flow_log_info "Opening in $editor: ${source_path:t}"
  echo ""

  $editor "$source_path"
  local edit_status=$?

  if [[ $edit_status -ne 0 ]]; then
    _flow_log_error "Editor exited with error"
    return 1
  fi

  # Check if file was modified (compare hashes)
  local after_hash
  if [[ -f "$source_path" ]]; then
    after_hash=$(shasum -a 256 "$source_path" 2>/dev/null | cut -d' ' -f1 || echo "0")
  else
    after_hash="0"
  fi

  if [[ "$before_hash" == "$after_hash" ]]; then
    _flow_log_muted "No changes made"
    # Show summary for add/create even without edits
    if $was_added || $was_created; then
      _dot_print_summary "${file_arg}" "$action_type" "Applied"
    fi
    return 0
  fi

  # Check if this is a Bitwarden template
  local is_bw_template=false
  local bw_unlocked=false
  if _dot_has_bitwarden_template "$source_path"; then
    is_bw_template=true

    if ! _dot_bw_session_valid; then
      echo ""
      _flow_log_info "🔐 This template uses Bitwarden secrets."
      echo "   Unlock vault to preview expanded values?"
      echo ""
      echo "  ${FLOW_COLORS[cmd]}y${FLOW_COLORS[reset]} - Unlock and preview"
      echo "  ${FLOW_COLORS[cmd]}s${FLOW_COLORS[reset]} - Skip preview (show raw template)"
      echo "  ${FLOW_COLORS[cmd]}n${FLOW_COLORS[reset]} - Cancel"
      echo ""
      read -q "?Unlock? [y/s/n] " unlock_response
      echo ""

      case "$unlock_response" in
        y)
          _dot_unlock || { _flow_log_warning "Continuing without secrets..."; }
          _dot_bw_session_valid && bw_unlocked=true
          ;;
        s)
          _flow_log_muted "Showing raw template diff"
          ;;
        n)
          _flow_log_muted "Cancelled"
          return 0
          ;;
      esac
    else
      bw_unlocked=true
    fi
  fi

  # Show diff preview
  echo ""
  _flow_log_success "Changes detected!"
  if $is_bw_template && ! $bw_unlocked; then
    _flow_log_muted "(Raw template - secrets shown as {{ bitwarden ... }})"
  fi
  _dot_show_file_diff "$resolved_path"

  # Prompt to apply
  echo ""
  _flow_log_info "Apply changes?"
  echo "  ${FLOW_COLORS[cmd]}y${FLOW_COLORS[reset]} - Apply now"
  echo "  ${FLOW_COLORS[cmd]}d${FLOW_COLORS[reset]} - Show detailed diff"
  echo "  ${FLOW_COLORS[cmd]}n${FLOW_COLORS[reset]} - Keep in staging"
  echo ""
  read -q "?Apply? [Y/n/d] " response
  echo ""

  # Track final status for summary
  local final_status="Staging"

  case "$response" in
    d)
      # Show detailed diff
      chezmoi diff "$resolved_path"
      echo ""
      read -q "?Apply now? [Y/n] " apply_response
      echo ""
      if [[ "$apply_response" == "y" ]]; then
        _dot_apply_changes "$resolved_path"
        final_status="Applied"
      fi
      ;;
    n)
      _flow_log_muted "Changes kept in staging. Run 'dot apply' to apply later"
      final_status="Staging"
      ;;
    *)
      _dot_apply_changes "$resolved_path"
      final_status="Applied"
      ;;
  esac

  # Show summary with tip
  local summary_action="$action_type"
  if $is_bw_template && $bw_unlocked; then
    summary_action="$action_type (secrets expanded)"
  fi
  _dot_print_summary "${file_arg}" "$summary_action" "$final_status"
}

# Show diff for a single file
_dot_show_file_diff() {
  local file="$1"
  echo ""
  echo "${FLOW_COLORS[header]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"
  chezmoi diff "$file" 2>/dev/null | head -20
  local line_count=$(chezmoi diff "$file" 2>/dev/null | wc -l | tr -d ' ')
  if [[ $line_count -gt 20 ]]; then
    echo "${FLOW_COLORS[muted]}... (${line_count} lines total, showing first 20)${FLOW_COLORS[reset]}"
  fi
  echo "${FLOW_COLORS[header]}─────────────────────────────────────────────────${FLOW_COLORS[reset]}"
}

# Apply changes for a specific file
_dot_apply_changes() {
  local file="$1"
  local dry_run="$2"

  if [[ -n "$dry_run" ]]; then
    _flow_log_info "Showing what would change (dry-run)..."
    if chezmoi apply --dry-run --verbose "$file" 2>/dev/null; then
      echo ""
      _flow_log_success "Dry-run complete - no changes applied"
    else
      _flow_log_error "Dry-run failed"
      return 1
    fi
  else
    _flow_log_info "Applying changes..."
    if chezmoi apply "$file" 2>/dev/null; then
      _flow_log_success "Applied: $file"
    else
      _flow_log_error "Failed to apply changes"
      return 1
    fi
  fi
}

# ───────────────────────────────────────────────────────────────────
# ADD HELPERS
# ───────────────────────────────────────────────────────────────────

# Internal helper to add a file to chezmoi
_dot_add_file() {
  local file="$1"
  local full_path="${file/#\~/$HOME}"
  [[ "$full_path" != /* ]] && full_path="$HOME/$full_path"

  if [[ ! -f "$full_path" ]]; then
    _flow_log_error "File does not exist: $full_path"
    return 1
  fi

  if chezmoi add "$full_path" 2>/dev/null; then
    _flow_log_success "Added ${file} to chezmoi"
    return 0
  else
    _flow_log_error "Failed to add ${file}"
    return 1
  fi
}

# Standalone dot add command
_dot_add() {
  if ! _dot_require_tool "chezmoi" "brew install chezmoi"; then
    return 1
  fi

  local file_arg="$1"
  if [[ -z "$file_arg" ]]; then
    _flow_log_error "Usage: dot add <file>"
    _flow_log_info "Example: dot add ~/.bashrc"
    return 1
  fi

  # Expand path
  local full_path="${file_arg/#\~/$HOME}"
  [[ "$full_path" != /* ]] && full_path="$HOME/$full_path"

  # Check file exists
  if [[ ! -f "$full_path" ]]; then
    _flow_log_error "File does not exist: $full_path"
    return 1
  fi

  # Check if already tracked
  if chezmoi managed 2>/dev/null | grep -qF "${full_path#$HOME/}"; then
    _flow_log_muted "Already tracked: $file_arg"
    return 0
  fi

  # Add to chezmoi
  if chezmoi add "$full_path" 2>/dev/null; then
    local source_path=$(chezmoi source-path "$full_path" 2>/dev/null)
    _flow_log_success "Added ${file_arg} to chezmoi"
    echo "  Source: ${source_path}"
    echo ""
    echo "💡 Tip: ${FLOW_COLORS[cmd]}dot edit ${file_arg##*/}${FLOW_COLORS[reset]} to make changes"
    return 0
  else
    _flow_log_error "Failed to add ${file_arg}"
    return 1
  fi
}

# Detect if source file is a Bitwarden template
_dot_has_bitwarden_template() {
  local source_path="$1"
  # Check if file is .tmpl and contains bitwarden function
  if [[ "$source_path" == *.tmpl ]] && grep -q '{{ *bitwarden' "$source_path" 2>/dev/null; then
    return 0
  fi
  return 1
}

# Print minimal summary with contextual tip
_dot_print_summary() {
  local file="$1"
  local action="$2"       # Added | Created | Edited
  local apply_status="$3" # Applied | Staging | No changes

  echo ""
  echo "📋 ${file} | ${action} + ${apply_status}"

  # Show contextual next step
  case "$apply_status" in
    Applied)
      echo "💡 Tip: ${FLOW_COLORS[cmd]}dot push${FLOW_COLORS[reset]} to sync to remote"
      ;;
    Staging)
      echo "💡 Tip: ${FLOW_COLORS[cmd]}dot apply${FLOW_COLORS[reset]} to apply, or ${FLOW_COLORS[cmd]}dot diff${FLOW_COLORS[reset]} to review"
      ;;
  esac
}

# ───────────────────────────────────────────────────────────────────
# DIFF COMMAND
# ───────────────────────────────────────────────────────────────────

_dot_diff() {
  if ! _dot_require_tool "chezmoi" "brew install chezmoi"; then
    return 1
  fi

  local file="$1"

  if [[ -n "$file" ]]; then
    # Show diff for specific file
    local resolved_path
    resolved_path=$(_dot_resolve_file_path "$file")
    local resolve_status=$?

    if [[ $resolve_status -ne 0 ]]; then
      _flow_log_error "File not found: $file"
      return 1
    fi

    _dot_show_file_diff "$resolved_path"
  else
    # Show all diffs
    local status_output
    status_output=$(chezmoi status 2>/dev/null)

    if [[ -z "$status_output" ]]; then
      _flow_log_success "No pending changes"
      return 0
    fi

    _flow_log_info "Pending changes:"
    echo ""
    chezmoi diff 2>/dev/null
  fi
}

# ───────────────────────────────────────────────────────────────────
# APPLY COMMAND
# ───────────────────────────────────────────────────────────────────

_dot_apply() {
  if ! _dot_require_tool "chezmoi" "brew install chezmoi"; then
    return 1
  fi

  # Parse flags
  local dry_run=""
  local file=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run|-n)
        dry_run="--dry-run"
        shift
        ;;
      *)
        file="$1"
        shift
        ;;
    esac
  done

  # Show dry-run mode indicator
  if [[ -n "$dry_run" ]]; then
    _flow_log_info "${FLOW_COLORS[warning]}DRY-RUN MODE${FLOW_COLORS[reset]} - No changes will be applied"
    echo ""
  fi

  # Check if there are any changes
  local status_output
  status_output=$(chezmoi status 2>/dev/null)

  if [[ -z "$status_output" ]]; then
    _flow_log_success "No pending changes"
    return 0
  fi

  if [[ -n "$file" ]]; then
    # Apply specific file
    local resolved_path
    resolved_path=$(_dot_resolve_file_path "$file")
    local resolve_status=$?

    if [[ $resolve_status -ne 0 ]]; then
      _flow_log_error "File not found: $file"
      return 1
    fi

    _dot_apply_changes "$resolved_path" "$dry_run"
  else
    # Apply all changes
    if [[ -n "$dry_run" ]]; then
      _flow_log_info "Showing what would change (dry-run)..."
    else
      _flow_log_info "Applying all pending changes..."
    fi
    echo ""

    # Show summary
    local modified_count=$(_dot_get_modified_count)
    _flow_log_info "Files to update: $modified_count"
    echo ""
    chezmoi status 2>/dev/null
    echo ""

    # Skip confirmation in dry-run mode
    if [[ -n "$dry_run" ]]; then
      if chezmoi apply --dry-run --verbose 2>/dev/null; then
        echo ""
        _flow_log_success "Dry-run complete - no changes applied"
      else
        _flow_log_error "Dry-run failed"
        return 1
      fi
      return 0
    fi

    read -q "?Apply all changes? [Y/n] " response
    echo ""

    if [[ "$response" != "n" ]]; then
      if chezmoi apply 2>/dev/null; then
        _flow_log_success "Applied all changes"
      else
        _flow_log_error "Failed to apply changes"
        return 1
      fi
    else
      _flow_log_muted "Cancelled"
    fi
  fi
}

# ───────────────────────────────────────────────────────────────────
# SYNC COMMAND (Pull from remote)
# ───────────────────────────────────────────────────────────────────

_dot_sync() {
  if ! _dot_require_tool "chezmoi" "brew install chezmoi"; then
    return 1
  fi

  local chezmoi_dir="${HOME}/.local/share/chezmoi"
  if [[ ! -d "$chezmoi_dir/.git" ]]; then
    _flow_log_error "Chezmoi not initialized or not using git"
    _flow_log_info "Run: chezmoi init <repo-url>"
    return 1
  fi

  _flow_log_info "Fetching from remote..."

  # Fetch updates (in chezmoi directory)
  (
    cd "$chezmoi_dir" || exit 1
    git fetch --quiet 2>/dev/null
  )

  # Check if behind
  if ! _dot_is_behind_remote; then
    _flow_log_success "Already up to date"
    return 0
  fi

  # Show what will change
  _flow_log_info "Remote has updates:"
  echo ""
  (
    cd "$chezmoi_dir" || exit 1
    git log --oneline HEAD..@{u} 2>/dev/null | head -5
  )
  echo ""

  # Check for local changes
  local has_local_changes=false
  if [[ -n "$(chezmoi status 2>/dev/null)" ]]; then
    has_local_changes=true
    _flow_log_warning "You have local uncommitted changes"
    chezmoi status 2>/dev/null
    echo ""
  fi

  read -q "?Pull updates? [Y/n] " response
  echo ""

  if [[ "$response" == "n" ]]; then
    _flow_log_muted "Cancelled"
    return 0
  fi

  # Pull updates
  _flow_log_info "Pulling updates..."
  if chezmoi update 2>/dev/null; then
    _flow_log_success "Synced with remote"

    # Show what changed
    local modified_count=$(_dot_get_modified_count)
    if [[ $modified_count -gt 0 ]]; then
      _flow_log_info "Run 'dot apply' to apply changes"
    fi
  else
    _flow_log_error "Failed to sync"
    return 1
  fi
}

# ───────────────────────────────────────────────────────────────────
# PUSH COMMAND (Push to remote)
# ───────────────────────────────────────────────────────────────────

_dot_push() {
  if ! _dot_require_tool "chezmoi" "brew install chezmoi"; then
    return 1
  fi

  local chezmoi_dir="${HOME}/.local/share/chezmoi"
  if [[ ! -d "$chezmoi_dir/.git" ]]; then
    _flow_log_error "Chezmoi not initialized or not using git"
    return 1
  fi

  # Check for changes to commit
  local git_status
  git_status=$(cd "$chezmoi_dir" && git status --porcelain 2>/dev/null)

  if [[ -z "$git_status" ]]; then
    # No uncommitted changes, check if ahead
    if _dot_is_ahead_of_remote; then
      _flow_log_info "Pushing committed changes..."
      (
        cd "$chezmoi_dir" || exit 1
        git push 2>&1
      )
      if [[ $? -eq 0 ]]; then
        _flow_log_success "Pushed to remote"
      else
        _flow_log_error "Failed to push"
        return 1
      fi
    else
      _flow_log_success "Nothing to push"
    fi
    return 0
  fi

  # Has uncommitted changes - show them
  _flow_log_info "Uncommitted changes:"
  echo ""
  (
    cd "$chezmoi_dir" || exit 1
    git status --short 2>/dev/null
  )
  echo ""

  # Prompt for commit message
  echo "${FLOW_COLORS[info]}Commit message:${FLOW_COLORS[reset]}"
  read "?> " commit_msg

  if [[ -z "$commit_msg" ]]; then
    _flow_log_error "Commit message required"
    return 1
  fi

  # Commit and push
  _flow_log_info "Committing and pushing..."
  (
    cd "$chezmoi_dir" || exit 1
    git add -A &&
    git commit -m "$commit_msg" &&
    git push 2>&1
  )

  if [[ $? -eq 0 ]]; then
    _flow_log_success "Committed and pushed"
  else
    _flow_log_error "Failed to commit/push"
    return 1
  fi
}

# ───────────────────────────────────────────────────────────────────
# UNDO COMMAND (Rollback last apply)
# ───────────────────────────────────────────────────────────────────

_dot_undo() {
  _flow_log_warning "Phase 2: Undo command not yet implemented"
  _flow_log_info "For now, use: chezmoi diff && chezmoi apply --dry-run"
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 3: SECRET MANAGEMENT (Bitwarden Integration)
# ═══════════════════════════════════════════════════════════════════

_dot_unlock() {
  if ! _dot_require_tool "bw" "brew install bitwarden-cli"; then
    return 1
  fi

  # Check current status
  local bw_status=$(_dot_bw_get_status)

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
    _dot_session_cache_save
    local timeout_min=$((DOT_SESSION_IDLE_TIMEOUT / 60))

    echo ""
    _flow_log_success "Vault unlocked successfully"
    echo ""
    _flow_log_muted "Session will auto-lock after ${timeout_min} min idle"
    _flow_log_info "Use 'dot secret <name>' to retrieve secrets"

    # Security reminder
    echo ""
    _flow_log_warning "Security reminder:"
    echo "  • Session expires after ${timeout_min} min of inactivity"
    echo "  • Don't export BW_SESSION globally"
    echo "  • Lock vault manually: ${FLOW_COLORS[cmd]}dot lock${FLOW_COLORS[reset]}"
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

_dot_lock() {
  # Clear session cache first
  _dot_session_cache_clear

  # Lock Bitwarden vault
  if command -v bw &>/dev/null; then
    bw lock &>/dev/null
  fi

  _flow_log_success "Vault locked"
  _flow_log_muted "Session cache cleared"
}

_dot_secret() {
  local subcommand="$1"
  shift 2>/dev/null  # Safe shift even if no args

  case "$subcommand" in
    # ─────────────────────────────────────────────────────────────
    # KEYCHAIN OPERATIONS (Default - instant, local, Touch ID)
    # ─────────────────────────────────────────────────────────────

    # Add secret to Keychain
    add|new)
      _dot_kc_add "$@"
      return
      ;;

    # Get secret from Keychain
    get)
      _dot_kc_get "$@"
      return
      ;;

    # List Keychain secrets
    list|ls)
      _dot_kc_list
      return
      ;;

    # Delete from Keychain
    delete|rm|remove)
      _dot_kc_delete "$@"
      return
      ;;

    # Import from Bitwarden to Keychain
    import)
      _dot_kc_import
      return
      ;;

    # ─────────────────────────────────────────────────────────────
    # TUTORIAL
    # ─────────────────────────────────────────────────────────────
    tutorial)
      # Load and run interactive tutorial
      local tutorial_file="${0:A:h}/../../commands/secret-tutorial.zsh"
      if [[ -f "$tutorial_file" ]]; then
        source "$tutorial_file"
        _dot_secret_tutorial "$@"
      else
        _flow_log_error "Tutorial not found: $tutorial_file"
        return 1
      fi
      return
      ;;

    # ─────────────────────────────────────────────────────────────
    # BITWARDEN FALLBACK (for cloud-synced secrets)
    # ─────────────────────────────────────────────────────────────
    bw)
      # Delegate to Bitwarden-specific operations
      _dot_secret_bw "$@"
      return
      ;;

    # ─────────────────────────────────────────────────────────────
    # HELP
    # ─────────────────────────────────────────────────────────────
    help|--help|-h)
      _dot_kc_help
      return
      ;;

    # Empty - show help
    "")
      _dot_kc_help
      return 1
      ;;

    *)
      # Default: treat as secret name (get operation from Keychain)
      _dot_kc_get "$subcommand"
      return
      ;;
  esac
}

# Bitwarden fallback for cloud-synced secrets
# Usage: dot secret bw <name|list|add|check>
_dot_secret_bw() {
  local subcommand="$1"
  shift 2>/dev/null

  case "$subcommand" in
    list|ls)
      _dot_secret_bw_list "$@"
      return
      ;;

    add|new)
      _dot_secret_bw_add "$@"
      return
      ;;

    check|expiring)
      _dot_secret_bw_check "$@"
      return
      ;;

    help|--help|-h)
      _dot_secret_bw_help
      return
      ;;

    "")
      _dot_secret_bw_help
      return 1
      ;;

    *)
      # Retrieve specific secret from Bitwarden
      _dot_secret_bw_get "$subcommand"
      return
      ;;
  esac
}

# Get secret from Bitwarden
_dot_secret_bw_get() {
  local item_name="$1"

  if [[ -z "$item_name" ]]; then
    _flow_log_error "Usage: dot secret bw <name>"
    return 1
  fi

  if ! _dot_require_tool "bw" "brew install bitwarden-cli"; then
    return 1
  fi

  if ! _dot_bw_session_valid; then
    _flow_log_error "Bitwarden vault is locked"
    _flow_log_info "Run: ${FLOW_COLORS[cmd]}dot unlock${FLOW_COLORS[reset]}"
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
        _flow_log_muted "Tip: Use 'dot secret bw list' to see Bitwarden items"
        ;;
      *"Session key"*|*"session"*)
        _flow_log_error "Session expired"
        _flow_log_info "Run: ${FLOW_COLORS[cmd]}dot unlock${FLOW_COLORS[reset]}"
        ;;
      *"locked"*|*"Locked"*)
        _flow_log_error "Vault is locked"
        _flow_log_info "Run: ${FLOW_COLORS[cmd]}dot unlock${FLOW_COLORS[reset]}"
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
_dot_secret_bw_help() {
  echo ""
  echo "${FLOW_COLORS[header]}dot secret bw${FLOW_COLORS[reset]} - Bitwarden cloud secrets (requires unlock)"
  echo ""
  echo "${FLOW_COLORS[warning]}Commands:${FLOW_COLORS[reset]}"
  echo "  dot secret bw <name>      Get secret from Bitwarden"
  echo "  dot secret bw list        List Bitwarden items"
  echo "  dot secret bw add <name>  Add to Bitwarden (with expiration)"
  echo "  dot secret bw check       Check expiring secrets"
  echo ""
  echo "${FLOW_COLORS[muted]}Note: Bitwarden requires 'dot unlock' first${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[muted]}For instant local access, use: dot secret <name>${FLOW_COLORS[reset]}"
  echo ""
}

_dot_secret_bw_list() {
  if ! _dot_require_tool "bw" "brew install bitwarden-cli"; then
    return 1
  fi

  # Check if session is active
  if ! _dot_bw_session_valid; then
    _flow_log_error "Bitwarden vault is locked"
    _flow_log_info "Run: ${FLOW_COLORS[cmd]}dot unlock${FLOW_COLORS[reset]}"
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
  _flow_log_info "Usage: ${FLOW_COLORS[cmd]}dot secret <name>${FLOW_COLORS[reset]}"
  echo ""
}

# ═══════════════════════════════════════════════════════════════════
# SECRET ADD - Store new secret (Phase 1 - v2.0)
# ═══════════════════════════════════════════════════════════════════

_dot_secret_bw_add() {
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
    _flow_log_error "Usage: dot secret add <name> [--expires <days>] [--notes <text>]"
    echo ""
    echo "Examples:"
    echo "  ${FLOW_COLORS[cmd]}dot secret add github-token${FLOW_COLORS[reset]}"
    echo "  ${FLOW_COLORS[cmd]}dot secret add npm-token --expires 90${FLOW_COLORS[reset]}"
    echo "  ${FLOW_COLORS[cmd]}dot secret add api-key --notes 'Production API key'${FLOW_COLORS[reset]}"
    return 1
  fi

  # Validate name format (alphanumeric, hyphens, underscores only)
  if [[ ! "$secret_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    _flow_log_error "Invalid secret name: $secret_name"
    _flow_log_info "Name must contain only letters, numbers, hyphens, and underscores"
    return 1
  fi

  if ! _dot_require_tool "bw" "brew install bitwarden-cli"; then
    return 1
  fi

  # Check if session is active
  if ! _dot_bw_session_valid; then
    _flow_log_error "Bitwarden vault is locked"
    _flow_log_info "Run: ${FLOW_COLORS[cmd]}dot unlock${FLOW_COLORS[reset]}"
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
  echo "💡 Usage: ${FLOW_COLORS[cmd]}TOKEN=\$(dot secret $secret_name)${FLOW_COLORS[reset]}"
}

# ═══════════════════════════════════════════════════════════════════
# SECRET CHECK - Show expiring secrets (Phase 1 - v2.0)
# ═══════════════════════════════════════════════════════════════════

_dot_secret_bw_check() {
  local warn_days="${1:-30}"  # Default: warn for secrets expiring within 30 days

  if ! _dot_require_tool "bw" "brew install bitwarden-cli"; then
    return 1
  fi

  if ! command -v jq &>/dev/null; then
    _flow_log_error "jq is required for expiration checking"
    _flow_log_info "Install: ${FLOW_COLORS[cmd]}brew install jq${FLOW_COLORS[reset]}"
    return 1
  fi

  # Check if session is active
  if ! _dot_bw_session_valid; then
    _flow_log_error "Bitwarden vault is locked"
    _flow_log_info "Run: ${FLOW_COLORS[cmd]}dot unlock${FLOW_COLORS[reset]}"
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
    echo "💡 Tip: ${FLOW_COLORS[cmd]}dot token <name> --refresh${FLOW_COLORS[reset]} to rotate"
  else
    _flow_log_success "No secrets expiring within $warn_days days"
  fi
}

# ═══════════════════════════════════════════════════════════════════
# SECRET HELP - Show secret subcommands
# ═══════════════════════════════════════════════════════════════════

_dot_secret_bw_help_detailed() {
  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🔐 DOT SECRET - Bitwarden Secret Management${FLOW_COLORS[reset]}     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Retrieve:${FLOW_COLORS[reset]}                                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot secret <name>${FLOW_COLORS[reset]}      Get secret value        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot secret list${FLOW_COLORS[reset]}        List all secrets        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Manage:${FLOW_COLORS[reset]}                                         ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot secret add <name>${FLOW_COLORS[reset]}  Store new secret        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot secret check${FLOW_COLORS[reset]}       Check expirations       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Options for add:${FLOW_COLORS[reset]}                                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[muted]}--expires, -e <days>${FLOW_COLORS[reset]}  Set expiration          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[muted]}--notes, -n <text>${FLOW_COLORS[reset]}    Add notes               ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Examples:${FLOW_COLORS[reset]}                                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[example]}TOKEN=\$(dot secret github-token)${FLOW_COLORS[reset]}          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[example]}dot secret add npm-token --expires 90${FLOW_COLORS[reset]}     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[example]}dot secret check${FLOW_COLORS[reset]}                           ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

_dot_doctor() {
  _flow_log_warning "Phase 3: Doctor diagnostics not yet implemented"
  _flow_log_info "Coming in Phase 3 (Integration)"
}

_dot_undo() {
  _flow_log_warning "Phase 3: Undo command not yet implemented"
  _flow_log_info "Coming in Phase 2 (Core Workflows)"
}

_dot_init() {
  _flow_log_warning "Phase 3: Init command not yet implemented"
  _flow_log_info "Coming in Phase 3 (Integration)"
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 2: TOKEN WIZARDS (Secret Management v2.0)
# ═══════════════════════════════════════════════════════════════════

_dot_token() {
  local subcommand="$1"
  shift 2>/dev/null  # Safe shift even if no args

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

  # If refresh mode, first non-flag arg is the token name
  if [[ "$refresh_mode" == true ]]; then
    if [[ ${#remaining_args[@]} -gt 0 ]]; then
      token_name="${remaining_args[1]}"
      _dot_token_refresh "$token_name"
      return $?
    else
      _flow_log_error "Usage: dot token <name> --refresh"
      _flow_log_info "Example: dot token github-token --refresh"
      return 1
    fi
  fi

  # Normal mode - handle wizards and subcommands
  case "$subcommand" in
    # Token wizards
    github|gh)
      _dot_token_github "$@"
      ;;
    npm)
      _dot_token_npm "$@"
      ;;
    pypi|pip)
      _dot_token_pypi "$@"
      ;;

    # Token automation subcommands (v5.16.0)
    expiring)
      _dot_token_expiring "$@"
      ;;
    rotate)
      shift  # Remove 'rotate' from args
      _dot_token_rotate "$@"
      ;;
    sync)
      shift  # Remove 'sync' from args
      case "$1" in
        gh|github)
          _dot_token_sync_gh
          ;;
        *)
          _flow_log_error "Usage: dot token sync gh"
          return 1
          ;;
      esac
      ;;

    # Help
    help|--help|-h)
      _dot_token_help
      ;;

    # Empty - show help
    "")
      _dot_token_help
      ;;

    *)
      # Could be a token name for refresh (without --refresh flag)
      # Check if it exists in vault
      if _dot_bw_session_valid 2>/dev/null; then
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
            echo "Example: ${FLOW_COLORS[cmd]}dot token $subcommand --refresh${FLOW_COLORS[reset]}"
            return 0
          fi
        fi
      fi

      _flow_log_error "Unknown token provider: $subcommand"
      _flow_log_info "Supported: github, npm, pypi"
      _flow_log_muted "Or use: dot token <name> --refresh"
      echo ""
      _dot_token_help
      return 1
      ;;
  esac
}

_dot_token_help() {
  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🔐 DOT TOKEN - Token Management${FLOW_COLORS[reset]}                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Create New Token:${FLOW_COLORS[reset]}                               ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot token github${FLOW_COLORS[reset]}   GitHub PAT wizard           ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot token npm${FLOW_COLORS[reset]}      NPM token wizard            ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot token pypi${FLOW_COLORS[reset]}     PyPI token wizard           ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Token Automation (v5.16.0):${FLOW_COLORS[reset]}                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot token expiring${FLOW_COLORS[reset]}  Check expiration status      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot token rotate${FLOW_COLORS[reset]}    Rotate existing token        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot token sync gh${FLOW_COLORS[reset]}   Sync with gh CLI             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Rotate Existing Token:${FLOW_COLORS[reset]}                          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot token <name> --refresh${FLOW_COLORS[reset]}                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    Example:                                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot token github-token --refresh${FLOW_COLORS[reset]}               ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Wizards will:${FLOW_COLORS[reset]}                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    1. Open browser to create token                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    2. Validate the token                          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    3. Store securely in Bitwarden                 ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    4. Track expiration date                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}See also:${FLOW_COLORS[reset]}                                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot secrets${FLOW_COLORS[reset]}        Dashboard of all secrets    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot secret check${FLOW_COLORS[reset]}   Show expiring secrets       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

# ───────────────────────────────────────────────────────────────────
# TOKEN REFRESH - Rotate existing token (Phase 3 - v2.1.0)
# ───────────────────────────────────────────────────────────────────

_dot_token_refresh() {
  local token_name="$1"

  if [[ -z "$token_name" ]]; then
    _flow_log_error "Token name required"
    _flow_log_info "Usage: dot token <name> --refresh"
    return 1
  fi

  if ! _dot_require_tool "bw" "brew install bitwarden-cli"; then
    return 1
  fi

  # Check if session is active
  if ! _dot_bw_session_valid; then
    _flow_log_info "Bitwarden vault is locked. Unlocking..."
    _dot_unlock || return 1
  fi

  # Look up existing token
  _flow_log_info "Looking up token: $token_name"

  local existing
  existing=$(bw get item "$token_name" --session "$BW_SESSION" 2>/dev/null)

  if [[ -z "$existing" ]]; then
    _flow_log_error "Token not found: $token_name"
    _flow_log_info "Use 'dot secrets' to see available tokens"
    return 1
  fi

  # Parse metadata to determine token type
  local notes=$(echo "$existing" | jq -r '.notes // ""' 2>/dev/null)

  if ! echo "$notes" | grep -q '"dot_version"'; then
    _flow_log_error "Token '$token_name' doesn't have DOT metadata"
    _flow_log_muted "This token wasn't created with 'dot token' wizard"
    _flow_log_info "Use the wizard to create a new token: dot token github"
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
      validation_fn="_dot_token_validate_github"
      ;;
    npm)
      token_url="https://www.npmjs.com/settings/~/tokens/new"
      validation_fn="_dot_token_validate_npm"
      ;;
    pypi)
      token_url="https://pypi.org/manage/account/token/"
      validation_fn="_dot_token_validate_pypi"
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

_dot_token_github() {
  if ! _dot_require_tool "bw" "brew install bitwarden-cli"; then
    return 1
  fi

  # Check if session is active
  if ! _dot_bw_session_valid; then
    _flow_log_info "Bitwarden vault is locked. Unlocking..."
    _dot_unlock || return 1
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

  # Ask for token name
  echo ""
  read "?Token name [github-token]: " token_name
  [[ -z "$token_name" ]] && token_name="github-token"

  # Build metadata (ENHANCED with github_user and expires_days)
  local expire_date=""
  if [[ "$expire_days" -gt 0 ]]; then
    expire_date=$(date -v+${expire_days}d +%Y-%m-%d 2>/dev/null || date -d "+${expire_days} days" +%Y-%m-%d 2>/dev/null)
  fi

  local metadata="{\"dot_version\":\"2.1\",\"type\":\"github\",\"token_type\":\"${token_type}\",\"created\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"expires_days\":${expire_days}"
  [[ -n "$expire_date" ]] && metadata="${metadata},\"expires\":\"${expire_date}\""
  [[ -n "$username" ]] && metadata="${metadata},\"github_user\":\"${username}\""
  metadata="${metadata}}"

  # Store in Bitwarden
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

  # ALSO store in Keychain with metadata for instant access
  _flow_log_info "Adding to Keychain for instant access..."
  security add-generic-password \
    -a "$token_name" \           # Account: token name (searchable)
    -s "$_DOT_KEYCHAIN_SERVICE" \ # Service: flow-cli namespace
    -w "$token_value" \           # Password: actual token (protected)
    -j "$metadata" \              # JSON attrs: metadata (searchable)
    -U 2>/dev/null               # Update if exists

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
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}GITHUB_TOKEN=\$(dot secret ${token_name})${FLOW_COLORS[reset]}     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

# ───────────────────────────────────────────────────────────────────
# TOKEN EXPIRATION DETECTION
# ───────────────────────────────────────────────────────────────────

_dot_token_expiring() {
  _flow_log_info "Checking token expiration status..."

  # Get all GitHub tokens from Keychain
  local secrets=$(dot secret list 2>/dev/null | grep "•" | sed 's/.*• //')
  local expiring_tokens=()
  local expired_tokens=()

  for secret in ${(f)secrets}; do
    # Only check GitHub tokens
    if [[ "$secret" =~ github ]]; then
      local token=$(dot secret "$secret" 2>/dev/null)

      # Validate with GitHub API
      local api_response=$(curl -s \
        -H "Authorization: token $token" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/user" 2>/dev/null)

      if echo "$api_response" | grep -q '"message":"Bad credentials"'; then
        expired_tokens+=("$secret")
      elif echo "$api_response" | grep -q '"login"'; then
        # Check if created 83+ days ago (7-day warning before 90-day expiration)
        local token_age_days=$(_dot_token_age_days "$secret")
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
      local days_left=$((90 - $(_dot_token_age_days "$token")))
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
      _dot_token_rotate
    else
      _flow_log_info "Run ${FLOW_COLORS[cmd]}dot token rotate${FLOW_COLORS[reset]} when ready"
    fi
  fi
}

_dot_token_age_days() {
  local secret_name="$1"

  # ─────────────────────────────────────────────────────────────────
  # KEYCHAIN METADATA RETRIEVAL
  # ─────────────────────────────────────────────────────────────────
  # Retrieves JSON metadata from Keychain WITHOUT decrypting password.
  # The metadata was stored via -j flag (see _dot_token_github above).
  # This enables fast expiration checks without Touch ID prompts.
  #
  # Note: 'security find-generic-password -g' outputs metadata to stderr
  #       with format: note: <JSON>
  # ─────────────────────────────────────────────────────────────────

  # Get creation timestamp from Keychain item metadata
  local metadata=$(security find-generic-password \
    -a "$secret_name" \
    -s "$_DOT_KEYCHAIN_SERVICE" \
    -g 2>&1 | grep "note:" | sed 's/note: //')

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

_dot_token_rotate() {
  local token_name="${1:-github-token}"

  _flow_log_info "Starting token rotation for: $token_name"

  # Step 1: Verify old token exists
  local old_token=$(dot secret "$token_name" 2>/dev/null)
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
  echo "$old_token" | dot secret add "$backup_name" 2>/dev/null
  _flow_log_info "Old token backed up as: $backup_name"

  # Step 4: Generate new token (use existing wizard)
  _flow_log_info "Step 1/4: Generating new token..."
  echo ""
  echo "Follow the wizard to create a new token."
  echo "Use the SAME scopes as before for consistency."
  echo ""

  # Call existing wizard
  _dot_token_github

  # Verify new token was created
  local new_token=$(dot secret "$token_name" 2>/dev/null)
  if [[ -z "$new_token" || "$new_token" == "$old_token" ]]; then
    _flow_log_error "New token creation failed or unchanged"
    _flow_log_info "Restoring old token..."
    echo "$old_token" | dot secret add "$token_name"
    dot secret delete "$backup_name" 2>/dev/null
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
    echo "$old_token" | dot secret add "$token_name"
    dot secret delete "$backup_name" 2>/dev/null
    return 1
  fi

  if [[ "$new_token_user" != "$old_token_user" ]]; then
    _flow_log_error "New token user ($new_token_user) doesn't match old token user ($old_token_user)"
    read -q "?Continue anyway? [y/n] " mismatch_continue
    echo ""
    if [[ "$mismatch_continue" != "y" ]]; then
      echo "$old_token" | dot secret add "$token_name"
      dot secret delete "$backup_name" 2>/dev/null
      return 1
    fi
  fi

  _flow_log_success "New token validated for user: $new_token_user"

  # Step 6: Manual revocation prompt
  _flow_log_info "Step 3/5: Revoke old token on GitHub..."
  echo ""
  echo "${FLOW_COLORS[warning]}Manual Step Required:${FLOW_COLORS[reset]}"
  echo "Visit: ${FLOW_COLORS[cmd]}https://github.com/settings/tokens${FLOW_COLORS[reset]}"
  echo "Find token for: ${old_token_user}"
  echo "Look for token created before today"
  echo "Click 'Revoke' to delete old token"
  echo ""

  read -q "?Press 'y' when revocation is complete [y/n] " revoke_confirm
  echo ""

  if [[ "$revoke_confirm" == "y" ]]; then
    # Delete backup token (old token now revoked)
    dot secret delete "$backup_name" 2>/dev/null
    _flow_log_success "Old token backup removed"
  else
    _flow_log_warning "Old token backup kept at: $backup_name"
    _flow_log_info "Delete manually after revocation: dot secret delete $backup_name"
  fi

  # Step 7: Log rotation event
  _dot_token_log_rotation "$token_name" "$new_token_user" "success"

  # Step 8: Sync with gh CLI
  _flow_log_info "Step 4/5: Syncing with gh CLI..."
  _dot_token_sync_gh

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

_dot_token_log_rotation() {
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

_dot_token_sync_gh() {
  _flow_log_info "Syncing token with gh CLI..."

  # Get token from Keychain
  local token=$(dot secret github-token 2>/dev/null)
  if [[ -z "$token" ]]; then
    _flow_log_error "github-token not found in Keychain"
    _flow_log_info "Add one: ${FLOW_COLORS[cmd]}dot token github${FLOW_COLORS[reset]}"
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

_dot_token_npm() {
  if ! _dot_require_tool "bw" "brew install bitwarden-cli"; then
    return 1
  fi

  # Check if session is active
  if ! _dot_bw_session_valid; then
    _flow_log_info "Bitwarden vault is locked. Unlocking..."
    _dot_unlock || return 1
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

  # Store in Bitwarden
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
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}NPM_TOKEN=\$(dot secret ${token_name})${FLOW_COLORS[reset]}         ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[muted]}# or in .npmrc:${FLOW_COLORS[reset]}                               ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}//registry.npmjs.org/:_authToken=\${NPM_TOKEN}${FLOW_COLORS[reset]}${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

# ───────────────────────────────────────────────────────────────────
# PYPI TOKEN WIZARD
# ───────────────────────────────────────────────────────────────────

_dot_token_pypi() {
  if ! _dot_require_tool "bw" "brew install bitwarden-cli"; then
    return 1
  fi

  # Check if session is active
  if ! _dot_bw_session_valid; then
    _flow_log_info "Bitwarden vault is locked. Unlocking..."
    _dot_unlock || return 1
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

  # Store in Bitwarden
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
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}TWINE_PASSWORD=\$(dot secret ${token_name})${FLOW_COLORS[reset]}    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}TWINE_USERNAME=__token__${FLOW_COLORS[reset]}                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Tip: For CI, consider Trusted Publishing${FLOW_COLORS[reset]}       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}(GitHub OIDC - no tokens needed)${FLOW_COLORS[reset]}               ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

# ═══════════════════════════════════════════════════════════════════
# PHASE 2: SECRETS DASHBOARD + SYNC
# ═══════════════════════════════════════════════════════════════════

_dot_secrets() {
  local subcommand="$1"

  case "$subcommand" in
    sync)
      shift
      _dot_secrets_sync "$@"
      return $?
      ;;
    help|--help|-h)
      _dot_secrets_help
      return 0
      ;;
    ""|dashboard)
      # Default: show dashboard
      ;;
    *)
      _flow_log_error "Unknown subcommand: $subcommand"
      _dot_secrets_help
      return 1
      ;;
  esac

  # Dashboard implementation
  if ! _dot_require_tool "bw" "brew install bitwarden-cli"; then
    return 1
  fi

  if ! command -v jq &>/dev/null; then
    _flow_log_error "jq is required for the secrets dashboard"
    _flow_log_info "Install: ${FLOW_COLORS[cmd]}brew install jq${FLOW_COLORS[reset]}"
    return 1
  fi

  # Check if session is active
  if ! _dot_bw_session_valid; then
    _flow_log_info "Bitwarden vault is locked. Unlocking..."
    _dot_unlock || return 1
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
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot token github${FLOW_COLORS[reset]}   Create GitHub token       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot secret add${FLOW_COLORS[reset]}     Add custom secret          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
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
  if _dot_bw_session_valid; then
    local time_remaining=$(_dot_session_time_remaining_fmt)
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
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  💡 Run: ${FLOW_COLORS[cmd]}dot token <type>${FLOW_COLORS[reset]} to rotate                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  fi

  echo "${FLOW_COLORS[header]}╰────────────────────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

_dot_secrets_help() {
  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🔐 DOT SECRETS - Secret Management${FLOW_COLORS[reset]}              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Commands:${FLOW_COLORS[reset]}                                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot secrets${FLOW_COLORS[reset]}              Dashboard          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot secrets sync github${FLOW_COLORS[reset]}  Sync to repo       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}See also:${FLOW_COLORS[reset]}                                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot token github${FLOW_COLORS[reset]}   Create new token       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot secret add${FLOW_COLORS[reset]}     Add custom secret      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot env init${FLOW_COLORS[reset]}       Generate .envrc        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

# ───────────────────────────────────────────────────────────────────
# SECRETS SYNC - Sync to GitHub repo secrets (Phase 3 - v2.2.0)
# ───────────────────────────────────────────────────────────────────

_dot_secrets_sync() {
  local target="$1"

  if [[ -z "$target" ]]; then
    _flow_log_error "Sync target required"
    echo ""
    echo "Usage: ${FLOW_COLORS[cmd]}dot secrets sync github${FLOW_COLORS[reset]}"
    echo ""
    echo "Supported targets:"
    echo "  ${FLOW_COLORS[cmd]}github${FLOW_COLORS[reset]}  - Sync to GitHub repository secrets"
    return 1
  fi

  case "$target" in
    github|gh)
      _dot_secrets_sync_github "$@"
      ;;
    *)
      _flow_log_error "Unknown sync target: $target"
      _flow_log_info "Supported: github"
      return 1
      ;;
  esac
}

_dot_secrets_sync_github() {
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
  if ! _dot_require_tool "bw" "brew install bitwarden-cli"; then
    return 1
  fi

  # Check session
  if ! _dot_bw_session_valid; then
    _flow_log_info "Bitwarden vault is locked. Unlocking..."
    _dot_unlock || return 1
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
    _flow_log_info "Use 'dot token' or 'dot secret add' to create secrets"
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
# DOT ENV - Direnv Integration (Phase 3 - v2.2.0)
# ═══════════════════════════════════════════════════════════════════

_dot_env() {
  local subcommand="$1"

  case "$subcommand" in
    init)
      shift
      _dot_env_init "$@"
      ;;
    help|--help|-h)
      _dot_env_help
      ;;
    "")
      _dot_env_help
      ;;
    *)
      _flow_log_error "Unknown subcommand: $subcommand"
      _dot_env_help
      return 1
      ;;
  esac
}

_dot_env_help() {
  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🔧 DOT ENV - Direnv Integration${FLOW_COLORS[reset]}                 ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Commands:${FLOW_COLORS[reset]}                                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot env init${FLOW_COLORS[reset]}   Generate .envrc             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}What it does:${FLOW_COLORS[reset]}                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    Creates .envrc that loads secrets from        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    Bitwarden when you enter the directory.       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Requirements:${FLOW_COLORS[reset]}                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    • direnv installed (brew install direnv)      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    • direnv hook in shell config                 ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

_dot_env_init() {
  # Check for direnv
  if ! command -v direnv &>/dev/null; then
    _flow_log_error "direnv is not installed"
    _flow_log_info "Install: ${FLOW_COLORS[cmd]}brew install direnv${FLOW_COLORS[reset]}"
    echo ""
    echo "Then add to your shell config:"
    echo "  ${FLOW_COLORS[muted]}eval \"\$(direnv hook zsh)\"${FLOW_COLORS[reset]}"
    return 1
  fi

  # Require bw
  if ! _dot_require_tool "bw" "brew install bitwarden-cli"; then
    return 1
  fi

  # Check session
  if ! _dot_bw_session_valid; then
    _flow_log_info "Bitwarden vault is locked. Unlocking..."
    _dot_unlock || return 1
  fi

  # Check if .envrc already exists
  if [[ -f ".envrc" ]]; then
    _flow_log_warning ".envrc already exists"
    read -q "?Overwrite? [y/n] " confirm
    echo ""
    if [[ "$confirm" != "y" ]]; then
      _flow_log_muted "Cancelled"
      return 0
    fi
  fi

  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🔧 Generate .envrc${FLOW_COLORS[reset]}                              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Select secrets to include in .envrc             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
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
    _flow_log_info "Use 'dot token' or 'dot secret add' to create secrets"
    return 0
  fi

  echo "Available secrets:"
  echo ""
  local i=1
  for name in "${names[@]}"; do
    echo "  ${FLOW_COLORS[cmd]}$i${FLOW_COLORS[reset]} - $name"
    ((i++))
  done
  echo "  ${FLOW_COLORS[cmd]}a${FLOW_COLORS[reset]} - Include all"
  echo "  ${FLOW_COLORS[cmd]}q${FLOW_COLORS[reset]} - Cancel"
  echo ""

  read "?Select secrets (e.g., 1,2 or a): " selection

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

  # Generate .envrc content
  local envrc_content="# Generated by dot env init
# Secrets are fetched from Bitwarden vault
# Requires: direnv, bitwarden-cli, flow-cli

# Ensure Bitwarden is unlocked
if ! dot unlock --check 2>/dev/null; then
  echo \"⚠ Bitwarden vault is locked. Run: dot unlock\"
  return 1
fi

# Load secrets
"

  for name in "${selected_secrets[@]}"; do
    # Convert to SCREAMING_SNAKE_CASE
    local env_name=$(echo "${name}" | tr '[:lower:]-' '[:upper:]_')
    envrc_content+="export ${env_name}=\$(dot secret ${name})
"
  done

  # Write .envrc
  echo "$envrc_content" > .envrc

  # Add to .gitignore if needed
  if [[ -f ".gitignore" ]]; then
    if ! grep -q "^\.envrc$" .gitignore 2>/dev/null; then
      echo "" >> .gitignore
      echo "# Local environment (secrets)" >> .gitignore
      echo ".envrc" >> .gitignore
      _flow_log_muted "Added .envrc to .gitignore"
    fi
  else
    echo "# Local environment (secrets)" > .gitignore
    echo ".envrc" >> .gitignore
    _flow_log_muted "Created .gitignore with .envrc"
  fi

  echo ""
  _flow_log_success "Created .envrc with ${#selected_secrets[@]} secret(s)"
  echo ""
  echo "Environment variables:"
  for name in "${selected_secrets[@]}"; do
    local env_name=$(echo "${name}" | tr '[:lower:]-' '[:upper:]_')
    echo "  ${FLOW_COLORS[accent]}\$${env_name}${FLOW_COLORS[reset]}"
  done
  echo ""
  echo "Next steps:"
  echo "  1. ${FLOW_COLORS[cmd]}direnv allow${FLOW_COLORS[reset]}  - Trust this .envrc"
  echo "  2. ${FLOW_COLORS[muted]}cd . ${FLOW_COLORS[reset]}        - Reload environment"
  echo ""
}
