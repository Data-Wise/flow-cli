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
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[success]}✓ Phase 1: Status & help${FLOW_COLORS[reset]}                      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[success]}✓ Phase 2: Edit/sync workflows${FLOW_COLORS[reset]}                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}○ Phase 3: Secret management (coming soon)${FLOW_COLORS[reset]}    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

# ═══════════════════════════════════════════════════════════════════
# VERSION COMMAND (Phase 1)
# ═══════════════════════════════════════════════════════════════════

_dot_version() {
  echo "dot dispatcher v1.1.0 (Phase 2 - Core Workflows)"
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
    return 1
  fi

  # Resolve file path (supports fuzzy matching)
  local resolved_path
  resolved_path=$(_dot_resolve_file_path "$file_arg")
  local resolve_status=$?

  if [[ $resolve_status -eq 1 ]]; then
    _flow_log_error "File not found in managed dotfiles: $file_arg"
    _flow_log_info "Use 'chezmoi add <file>' to start tracking a new file"
    return 1
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

  # Get file modification time before editing
  local before_mtime
  if [[ -f "$source_path" ]]; then
    before_mtime=$(stat -f "%m" "$source_path" 2>/dev/null || echo "0")
  else
    before_mtime="0"
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

  # Check if file was modified
  local after_mtime
  if [[ -f "$source_path" ]]; then
    after_mtime=$(stat -f "%m" "$source_path" 2>/dev/null || echo "0")
  else
    after_mtime="0"
  fi

  if [[ "$before_mtime" == "$after_mtime" ]]; then
    _flow_log_muted "No changes made"
    return 0
  fi

  # Show diff preview
  echo ""
  _flow_log_success "Changes detected!"
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

  case "$response" in
    d)
      # Show detailed diff
      chezmoi diff "$resolved_path"
      echo ""
      read -q "?Apply now? [Y/n] " apply_response
      echo ""
      [[ "$apply_response" == "y" ]] && _dot_apply_changes "$resolved_path"
      ;;
    n)
      _flow_log_muted "Changes kept in staging. Run 'dot apply' to apply later"
      ;;
    *)
      _dot_apply_changes "$resolved_path"
      ;;
  esac
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
  _flow_log_info "Applying changes..."

  if chezmoi apply "$file" 2>/dev/null; then
    _flow_log_success "Applied: $file"
  else
    _flow_log_error "Failed to apply changes"
    return 1
  fi
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

  local file="$1"

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

    _dot_apply_changes "$resolved_path"
  else
    # Apply all changes
    _flow_log_info "Applying all pending changes..."
    echo ""

    # Show summary
    local modified_count=$(_dot_get_modified_count)
    _flow_log_info "Files to update: $modified_count"
    echo ""
    chezmoi status 2>/dev/null
    echo ""

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
