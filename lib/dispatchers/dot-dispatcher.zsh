#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# DOT - Dotfile Management Dispatcher
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         lib/dispatchers/dot-dispatcher.zsh
# Version:      1.0.0 (Phase 1 - Foundation)
# Date:         2026-01-08
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
    # DOTFILE MANAGEMENT (Phase 2 - placeholders)
    # ─────────────────────────────────────────────────────────────
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

    secret)
      shift
      _dot_secret "$@"
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
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot edit FILE${FLOW_COLORS[reset]}    Edit dotfile (preview changes)  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot sync${FLOW_COLORS[reset]}         Pull latest changes from remote ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot push${FLOW_COLORS[reset]}         Push local changes to remote    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot diff${FLOW_COLORS[reset]}         Show pending changes            ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[accent]}SECRET MANAGEMENT${FLOW_COLORS[reset]}                             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot unlock${FLOW_COLORS[reset]}       Unlock Bitwarden vault          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot secret NAME${FLOW_COLORS[reset]}  Retrieve secret (no echo)       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot secret list${FLOW_COLORS[reset]}  Show available secrets          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[accent]}TROUBLESHOOTING${FLOW_COLORS[reset]}                               ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot doctor${FLOW_COLORS[reset]}       Run diagnostics                 ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot undo${FLOW_COLORS[reset]}         Rollback last apply             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot help${FLOW_COLORS[reset]}         Show this help                  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[accent]}EXAMPLES${FLOW_COLORS[reset]}                                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot edit .zshrc${FLOW_COLORS[reset]}           Edit shell config      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot sync${FLOW_COLORS[reset]}                  Pull from iMac         ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dot secret github-token${FLOW_COLORS[reset]}   Get GitHub token       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Phase 1 (Foundation): Status & help only${FLOW_COLORS[reset]}       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Phase 2: Edit/sync workflows${FLOW_COLORS[reset]}                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Phase 3: Secret management & troubleshooting${FLOW_COLORS[reset]}   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

# ═══════════════════════════════════════════════════════════════════
# VERSION COMMAND (Phase 1)
# ═══════════════════════════════════════════════════════════════════

_dot_version() {
  echo "dot dispatcher v1.0.0 (Phase 1 - Foundation)"
  echo "Part of flow-cli v5.0.0"
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
# PLACEHOLDER FUNCTIONS (Phase 2 & 3)
# ═══════════════════════════════════════════════════════════════════

_dot_edit() {
  _flow_log_warning "Phase 2: Edit workflow not yet implemented"
  _flow_log_info "Coming in Phase 2 (Core Workflows)"
}

_dot_sync() {
  _flow_log_warning "Phase 2: Sync workflow not yet implemented"
  _flow_log_info "Coming in Phase 2 (Core Workflows)"
}

_dot_push() {
  _flow_log_warning "Phase 2: Push workflow not yet implemented"
  _flow_log_info "Coming in Phase 2 (Core Workflows)"
}

_dot_diff() {
  _flow_log_warning "Phase 2: Diff command not yet implemented"
  _flow_log_info "Coming in Phase 2 (Core Workflows)"
}

_dot_apply() {
  _flow_log_warning "Phase 2: Apply command not yet implemented"
  _flow_log_info "Coming in Phase 2 (Core Workflows)"
}

_dot_unlock() {
  _flow_log_warning "Phase 3: Bitwarden unlock not yet implemented"
  _flow_log_info "Coming in Phase 3 (Secret Management)"
}

_dot_secret() {
  _flow_log_warning "Phase 3: Secret management not yet implemented"
  _flow_log_info "Coming in Phase 3 (Secret Management)"
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
