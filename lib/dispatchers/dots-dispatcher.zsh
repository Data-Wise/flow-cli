#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# DOTS - Dotfile Management Dispatcher
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         lib/dispatchers/dots-dispatcher.zsh
# Version:      3.0.0 (Split from dot-dispatcher.zsh)
# Date:         2026-02-14
# Pattern:      command + keyword + options
#
# Usage:        dots <action> [args]
#
# Examples:
#   dots                   # Status overview (default)
#   dots status            # Show sync status
#   dots help              # Show all commands
#   dots edit .zshrc       # Edit dotfile (Phase 2)
#   dots sync              # Pull from remote (Phase 2)
#
# Dependencies:
#   - chezmoi (optional): dotfile sync
#
# ══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════
# MAIN DOTS() DISPATCHER
# ═══════════════════════════════════════════════════════════════════

dots() {
  # No arguments → show status (most common - zero effort)
  if [[ $# -eq 0 ]]; then
    _dots_status
    return
  fi

  case "$1" in
    # ─────────────────────────────────────────────────────────────
    # STATUS & INFO
    # ─────────────────────────────────────────────────────────────
    status|s)
      shift
      _dots_status "$@"
      ;;

    size)
      shift
      _dots_size "$@"
      ;;

    help|--help|-h)
      _dots_help
      ;;

    version|--version|-v)
      _dots_version
      ;;

    # ─────────────────────────────────────────────────────────────
    # DOTFILE MANAGEMENT (Phase 2)
    # ─────────────────────────────────────────────────────────────
    add)
      shift
      _dots_add "$@"
      ;;

    edit|e)
      shift
      _dots_edit "$@"
      ;;

    sync|pull)
      shift
      _dots_sync "$@"
      ;;

    push|p)
      shift
      _dots_push "$@"
      ;;

    diff|d)
      shift
      _dots_diff "$@"
      ;;

    apply|a)
      shift
      _dots_apply "$@"
      ;;

    ignore|ig)
      shift
      _dots_ignore "$@"
      ;;

    # ─────────────────────────────────────────────────────────────
    # TROUBLESHOOTING (Phase 3 - placeholders)
    # ─────────────────────────────────────────────────────────────
    doctor|dr)
      shift
      _dots_doctor "$@"
      ;;

    undo)
      shift
      _dots_undo "$@"
      ;;

    init)
      shift
      _dots_init "$@"
      ;;

    # Direnv integration (Phase 3 - v2.2.0)
    env)
      shift
      _dots_env "$@"
      ;;

    # ─────────────────────────────────────────────────────────────
    # RELATED: sec (secrets), tok (tokens)
    # ─────────────────────────────────────────────────────────────

    # ─────────────────────────────────────────────────────────────
    # PASSTHROUGH (advanced usage)
    # ─────────────────────────────────────────────────────────────
    *)
      # Pass through to chezmoi if available
      if _dotf_has_chezmoi; then
        chezmoi "$@"
      else
        _flow_log_error "Unknown command: $1"
        _flow_log_info "Run 'dots help' for available commands"
        return 1
      fi
      ;;
  esac
}

# ═══════════════════════════════════════════════════════════════════
# STATUS COMMAND (Phase 1)
# ═══════════════════════════════════════════════════════════════════

_dots_status() {
  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}📁 Dotfiles Status${FLOW_COLORS[reset]}                                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

  # Check if chezmoi is installed
  if ! _dotf_has_chezmoi; then
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  State: $(_dotf_format_status "not-installed")                        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
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
  local sync_status=$(_dotf_get_sync_status)
  local formatted_status=$(_dotf_format_status "$sync_status")

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
  local last_sync=$(_dotf_get_last_sync_time)
  local tracked_count=$(_dotf_get_tracked_count)
  local modified_count=$(_dotf_get_modified_count)

  # Display info
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Last sync: ${last_sync}                              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Tracked files: ${tracked_count}                                 ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

  if [[ $modified_count -gt 0 ]]; then
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[warning]}Modified: ${modified_count} files${FLOW_COLORS[reset]}                            ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  fi

  # Bitwarden vault status (if installed)
  if _dotf_has_bw; then
    if _dotf_bw_session_valid; then
      local time_remaining=$(_dotf_session_time_remaining_fmt)
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
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dots edit .zshrc${FLOW_COLORS[reset]}   Edit shell config             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dots sync${FLOW_COLORS[reset]}          Pull latest changes           ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      ;;
    modified)
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dots diff${FLOW_COLORS[reset]}          Show pending changes          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dots push${FLOW_COLORS[reset]}          Push changes to remote        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      ;;
    behind)
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dots sync${FLOW_COLORS[reset]}          Pull latest changes           ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      ;;
    ahead)
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dots push${FLOW_COLORS[reset]}          Push changes to remote        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      ;;
  esac

  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dots help${FLOW_COLORS[reset]}          Show all commands             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

# ═══════════════════════════════════════════════════════════════════
# SIZE COMMAND (Phase 1 - Repository Analysis)
# ═══════════════════════════════════════════════════════════════════

_dots_size() {
  local chezmoi_dir="$HOME/.local/share/chezmoi"

  # Check chezmoi installed
  if ! _dotf_has_chezmoi; then
    _flow_log_error "Chezmoi not installed"
    _flow_log_info "Install with: ${FLOW_COLORS[cmd]}brew install chezmoi${FLOW_COLORS[reset]}"
    return 1
  fi

  # Check directory exists
  if [[ ! -d "$chezmoi_dir" ]]; then
    _flow_log_error "Chezmoi directory not found: $chezmoi_dir"
    _flow_log_info "Initialize with: ${FLOW_COLORS[cmd]}chezmoi init${FLOW_COLORS[reset]}"
    return 1
  fi

  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}📊 Chezmoi Repository Size${FLOW_COLORS[reset]}                    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

  # Total size with cache
  local size_display
  if size_display=$(_dotf_get_cached_size); then
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Total: ${FLOW_COLORS[bold]}$size_display${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}(cached)${FLOW_COLORS[reset]}                      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  else
    local size=$(du -sh "$chezmoi_dir" 2>/dev/null | cut -f1)
    _dotf_cache_size "$size"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  Total: ${FLOW_COLORS[bold]}$size${FLOW_COLORS[reset]}                                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  fi

  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Top 10 largest files:${FLOW_COLORS[reset]}                         ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

  # Top 10 files
  (
    cd "$chezmoi_dir" || return 1
    find . -type f -not -path "./.git/*" -exec du -h {} + 2>/dev/null | \
    sort -rh | \
    head -10 | \
    while IFS=$'\t' read -r size path; do
      # Strip leading ./
      path="${path#./}"

      # Truncate path if too long (max 35 chars)
      local display_path="$path"
      if [[ ${#path} -gt 35 ]]; then
        display_path="...${path: -32}"
      fi

      # Warn if .git in path
      if [[ "$path" == *".git"* ]] || [[ "$path" == *"dot_git"* ]]; then
        printf "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[warning]}⚠️  %-6s  %-35s${FLOW_COLORS[reset]} ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}\n" "$size" "$display_path"
      else
        printf "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}     %-6s  %-35s ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}\n" "$size" "$display_path"
      fi
    done
  )

  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

  # Check for nested .git directories
  local git_count=$(find "$chezmoi_dir" -name ".git" -type d -not -path "$chezmoi_dir/.git" 2>/dev/null | wc -l | tr -d ' ')
  local git_dotf_count=$(find "$chezmoi_dir" -name "dot_git" -type d 2>/dev/null | wc -l | tr -d ' ')
  local total_git_dirs=$((git_count + git_dotf_count))

  if (( total_git_dirs > 0 )); then
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[warning]}⚠️  Found $total_git_dirs nested git directories${FLOW_COLORS[reset]}          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Fix: dots ignore add '**/.git'${FLOW_COLORS[reset]}                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  fi

  # Check for large files (>100KB)
  local large_count=$(find "$chezmoi_dir" -type f -not -path "$chezmoi_dir/.git/*" -size +100k 2>/dev/null | wc -l | tr -d ' ')
  if (( large_count > 0 )); then
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[warning]}⚠️  Found $large_count files larger than 100KB${FLOW_COLORS[reset]}          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Review with: dots size | grep '⚠️'${FLOW_COLORS[reset]}            ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  fi

  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

# ═══════════════════════════════════════════════════════════════════
# HELP COMMAND (Phase 1)
# ═══════════════════════════════════════════════════════════════════

_dots_help() {
  # Color fallbacks
  if [[ -z "$_C_BOLD" ]]; then
      _C_BOLD='\033[1m'
      _C_DIM='\033[2m'
      _C_NC='\033[0m'
      _C_GREEN='\033[32m'
      _C_YELLOW='\033[33m'
      _C_BLUE='\033[34m'
      _C_MAGENTA='\033[35m'
      _C_CYAN='\033[36m'
  fi

  echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ dots - Dotfile Management                    │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}dots${_C_NC}                Status + quick actions
  ${_C_CYAN}dots add FILE${_C_NC}       Add file to chezmoi
  ${_C_CYAN}dots edit FILE${_C_NC}      Edit dotfile (auto-add/create)
  ${_C_CYAN}dots sync${_C_NC}           Pull latest from remote
  ${_C_CYAN}dots push${_C_NC}           Push changes to remote

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} dots edit .zshrc          ${_C_DIM}# Edit shell config${_C_NC}
  ${_C_DIM}\$${_C_NC} dots add ~/.bashrc        ${_C_DIM}# Start tracking file${_C_NC}
  ${_C_DIM}\$${_C_NC} dots apply -n             ${_C_DIM}# Dry-run apply${_C_NC}

${_C_BLUE}📋 FILE MANAGEMENT${_C_NC}:
  ${_C_CYAN}dots add FILE${_C_NC}       Add file to chezmoi (with safety checks)
  ${_C_CYAN}dots edit FILE${_C_NC}      Edit dotfile (auto-add/create)
  ${_C_CYAN}dots diff${_C_NC}           Show pending changes
  ${_C_CYAN}dots apply${_C_NC}          Apply changes to home directory
  ${_C_CYAN}dots apply -n${_C_NC}       Dry-run (preview without apply)
  ${_C_CYAN}dots undo${_C_NC}           Rollback last apply

${_C_BLUE}📋 IGNORE & HEALTH${_C_NC}:
  ${_C_CYAN}dots ignore add <pat>${_C_NC} Add ignore pattern
  ${_C_CYAN}dots ignore list${_C_NC}    List all patterns
  ${_C_CYAN}dots size${_C_NC}           Analyze repository size
  ${_C_CYAN}dots doctor${_C_NC}         Run diagnostics

${_C_MAGENTA}💡 TIP${_C_NC}: Unknown commands pass through to chezmoi
  ${_C_DIM}dots managed → chezmoi managed${_C_NC}

${_C_DIM}📚 See also:${_C_NC}
  ${_C_CYAN}sec${_C_NC} - Secret management (Bitwarden)
  ${_C_CYAN}tok${_C_NC} - Token management (GitHub, NPM, PyPI)
  ${_C_CYAN}flow doctor --dot${_C_NC} - Health check for dotfiles
  ${_C_CYAN}g${_C_NC} - Git commands
"
}

# ═══════════════════════════════════════════════════════════════════
# VERSION COMMAND (Phase 1)
# ═══════════════════════════════════════════════════════════════════

_dots_version() {
  echo "dots dispatcher v3.0.0 (Dotfile Management)"
  echo "Part of flow-cli v5.1.0"
  echo ""
  echo "Tools:"
  if _dotf_has_chezmoi; then
    local chezmoi_version=$(chezmoi --version 2>/dev/null | head -1)
    echo "  ✓ chezmoi: $chezmoi_version"
  else
    echo "  ✗ chezmoi: not installed"
  fi

  if _dotf_has_bw; then
    local bw_version=$(bw --version 2>/dev/null)
    echo "  ✓ bw: v$bw_version"
  else
    echo "  ✗ bw: not installed"
  fi

  if _dotf_has_mise; then
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
_dots_edit() {
  if ! _dotf_require_tool "chezmoi" "brew install chezmoi"; then
    return 1
  fi

  local file_arg="$1"
  if [[ -z "$file_arg" ]]; then
    _flow_log_error "Usage: dots edit <file>"
    _flow_log_info "Examples:"
    echo "  dots edit .zshrc"
    echo "  dots edit zshrc     (fuzzy match)"
    echo "  dots edit ~/.newrc  (create new)"
    return 1
  fi

  # Track state for summary
  local was_added=false
  local was_created=false
  local action_type="Edited"

  # Resolve file path (supports fuzzy matching)
  local resolved_path
  resolved_path=$(_dotf_resolve_file_path "$file_arg")
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
        _dots_add_file "$full_path" || return 1
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
        _dots_add_file "$full_path" || return 1
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
      _dots_print_summary "${file_arg}" "$action_type" "Applied"
    fi
    return 0
  fi

  # Check if this is a Bitwarden template
  local is_bw_template=false
  local bw_unlocked=false
  if _dots_has_bitwarden_template "$source_path"; then
    is_bw_template=true

    if ! _dotf_bw_session_valid; then
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
          _sec_unlock || { _flow_log_warning "Continuing without secrets..."; }
          _dotf_bw_session_valid && bw_unlocked=true
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
  _dots_show_file_diff "$resolved_path"

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
        _dots_apply_changes "$resolved_path"
        final_status="Applied"
      fi
      ;;
    n)
      _flow_log_muted "Changes kept in staging. Run 'dots apply' to apply later"
      final_status="Staging"
      ;;
    *)
      _dots_apply_changes "$resolved_path"
      final_status="Applied"
      ;;
  esac

  # Show summary with tip
  local summary_action="$action_type"
  if $is_bw_template && $bw_unlocked; then
    summary_action="$action_type (secrets expanded)"
  fi
  _dots_print_summary "${file_arg}" "$summary_action" "$final_status"
}

# Show diff for a single file
_dots_show_file_diff() {
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
_dots_apply_changes() {
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
_dots_add_file() {
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

# Standalone dots add command
_dots_add() {
  if ! _dotf_require_tool "chezmoi" "brew install chezmoi"; then
    return 1
  fi

  local file_arg="$1"
  if [[ -z "$file_arg" ]]; then
    _flow_log_error "Usage: dots add <file>"
    _flow_log_info "Example: dots add ~/.bashrc"
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
    echo "💡 Tip: ${FLOW_COLORS[cmd]}dots edit ${file_arg##*/}${FLOW_COLORS[reset]} to make changes"
    return 0
  else
    _flow_log_error "Failed to add ${file_arg}"
    return 1
  fi
}

# Detect if source file is a Bitwarden template
_dots_has_bitwarden_template() {
  local source_path="$1"
  # Check if file is .tmpl and contains bitwarden function
  if [[ "$source_path" == *.tmpl ]] && grep -q '{{ *bitwarden' "$source_path" 2>/dev/null; then
    return 0
  fi
  return 1
}

# Print minimal summary with contextual tip
_dots_print_summary() {
  local file="$1"
  local action="$2"       # Added | Created | Edited
  local apply_status="$3" # Applied | Staging | No changes

  echo ""
  echo "📋 ${file} | ${action} + ${apply_status}"

  # Show contextual next step
  case "$apply_status" in
    Applied)
      echo "💡 Tip: ${FLOW_COLORS[cmd]}dots push${FLOW_COLORS[reset]} to sync to remote"
      ;;
    Staging)
      echo "💡 Tip: ${FLOW_COLORS[cmd]}dots apply${FLOW_COLORS[reset]} to apply, or ${FLOW_COLORS[cmd]}dots diff${FLOW_COLORS[reset]} to review"
      ;;
  esac
}

# ───────────────────────────────────────────────────────────────────
# DIFF COMMAND
# ───────────────────────────────────────────────────────────────────

_dots_diff() {
  if ! _dotf_require_tool "chezmoi" "brew install chezmoi"; then
    return 1
  fi

  local file="$1"

  if [[ -n "$file" ]]; then
    # Show diff for specific file
    local resolved_path
    resolved_path=$(_dotf_resolve_file_path "$file")
    local resolve_status=$?

    if [[ $resolve_status -ne 0 ]]; then
      _flow_log_error "File not found: $file"
      return 1
    fi

    _dots_show_file_diff "$resolved_path"
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

_dots_apply() {
  if ! _dotf_require_tool "chezmoi" "brew install chezmoi"; then
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
    resolved_path=$(_dotf_resolve_file_path "$file")
    local resolve_status=$?

    if [[ $resolve_status -ne 0 ]]; then
      _flow_log_error "File not found: $file"
      return 1
    fi

    _dots_apply_changes "$resolved_path" "$dry_run"
  else
    # Apply all changes
    if [[ -n "$dry_run" ]]; then
      _flow_log_info "Showing what would change (dry-run)..."
    else
      _flow_log_info "Applying all pending changes..."
    fi
    echo ""

    # Show summary
    local modified_count=$(_dotf_get_modified_count)
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
# IGNORE COMMAND - Manage .chezmoiignore patterns
# ───────────────────────────────────────────────────────────────────

_dots_ignore() {
  local ignore_file="$HOME/.local/share/chezmoi/.chezmoiignore"
  local subcommand="${1:-list}"

  case "$subcommand" in
    add)
      if [[ -z "$2" ]]; then
        _flow_log_error "Usage: dots ignore add <pattern>"
        return 1
      fi

      local pattern="$2"

      # Create file if missing
      if [[ ! -f "$ignore_file" ]]; then
        mkdir -p "$(dirname "$ignore_file")"
        touch "$ignore_file"
        _flow_log_info "Created .chezmoiignore"
      fi

      # Check if pattern exists
      if grep -qF "$pattern" "$ignore_file" 2>/dev/null; then
        _flow_log_warning "Pattern already in .chezmoiignore: $pattern"
        return 0
      fi

      # Add pattern
      echo "$pattern" >> "$ignore_file"
      _flow_log_success "Added pattern to .chezmoiignore: $pattern"
      ;;

    list|ls|"")
      if [[ ! -f "$ignore_file" ]]; then
        _flow_log_info "No .chezmoiignore file found"
        _flow_log_info "Create patterns with: ${FLOW_COLORS[cmd]}dots ignore add <pattern>${FLOW_COLORS[reset]}"
        return 0
      fi

      echo ""
      echo "${FLOW_COLORS[header]}.chezmoiignore patterns:${FLOW_COLORS[reset]}"
      echo ""
      nl -w2 -s"  " "$ignore_file"
      echo ""
      ;;

    remove|rm)
      if [[ -z "$2" ]]; then
        _flow_log_error "Usage: dots ignore remove <pattern>"
        return 1
      fi

      local pattern="$2"

      if [[ ! -f "$ignore_file" ]]; then
        _flow_log_error "No .chezmoiignore file found"
        return 1
      fi

      # Check if pattern exists
      if ! grep -qF "$pattern" "$ignore_file" 2>/dev/null; then
        _flow_log_error "Pattern not found in .chezmoiignore: $pattern"
        return 1
      fi

      # Remove using temp file (cross-platform)
      local temp_file
      temp_file=$(mktemp)
      grep -vF "$pattern" "$ignore_file" > "$temp_file"
      mv "$temp_file" "$ignore_file"
      _flow_log_success "Removed pattern from .chezmoiignore: $pattern"
      ;;

    edit)
      if [[ ! -f "$ignore_file" ]]; then
        mkdir -p "$(dirname "$ignore_file")"
        touch "$ignore_file"
        _flow_log_info "Created .chezmoiignore"
      fi

      ${EDITOR:-vim} "$ignore_file"
      ;;

    help|--help|-h)
      echo ""
      echo "${FLOW_COLORS[header]}dots ignore${FLOW_COLORS[reset]} - Manage .chezmoiignore patterns"
      echo ""
      echo "${FLOW_COLORS[bold]}USAGE:${FLOW_COLORS[reset]}"
      echo "  dots ignore [add|list|remove|edit]"
      echo ""
      echo "${FLOW_COLORS[bold]}COMMANDS:${FLOW_COLORS[reset]}"
      echo "  ${FLOW_COLORS[cmd]}add <pattern>${FLOW_COLORS[reset]}     Add pattern to .chezmoiignore"
      echo "  ${FLOW_COLORS[cmd]}list${FLOW_COLORS[reset]}, ${FLOW_COLORS[cmd]}ls${FLOW_COLORS[reset]}        List all patterns (default)"
      echo "  ${FLOW_COLORS[cmd]}remove <pattern>${FLOW_COLORS[reset]}  Remove pattern from .chezmoiignore"
      echo "  ${FLOW_COLORS[cmd]}edit${FLOW_COLORS[reset]}              Open .chezmoiignore in \$EDITOR"
      echo ""
      echo "${FLOW_COLORS[bold]}EXAMPLES:${FLOW_COLORS[reset]}"
      echo "  ${FLOW_COLORS[muted]}# Ignore all .git directories${FLOW_COLORS[reset]}"
      echo "  dots ignore add '**/.git'"
      echo ""
      echo "  ${FLOW_COLORS[muted]}# Ignore log files${FLOW_COLORS[reset]}"
      echo "  dots ignore add '*.log'"
      echo ""
      echo "  ${FLOW_COLORS[muted]}# Show all patterns${FLOW_COLORS[reset]}"
      echo "  dots ignore list"
      echo ""
      echo "  ${FLOW_COLORS[muted]}# Remove pattern${FLOW_COLORS[reset]}"
      echo "  dots ignore remove '*.log'"
      echo ""
      echo "  ${FLOW_COLORS[muted]}# Edit manually${FLOW_COLORS[reset]}"
      echo "  dots ignore edit"
      echo ""
      ;;

    *)
      _flow_log_error "Unknown ignore command: $subcommand"
      echo ""
      _flow_log_info "Usage: ${FLOW_COLORS[cmd]}dots ignore [add|list|remove|edit]${FLOW_COLORS[reset]}"
      _flow_log_info "Run ${FLOW_COLORS[cmd]}dots ignore help${FLOW_COLORS[reset]} for more information"
      return 1
      ;;
  esac
}

# ───────────────────────────────────────────────────────────────────
# SYNC COMMAND (Pull from remote)
# ───────────────────────────────────────────────────────────────────

_dots_sync() {
  if ! _dotf_require_tool "chezmoi" "brew install chezmoi"; then
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
  if ! _dotf_is_behind_remote; then
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
    local modified_count=$(_dotf_get_modified_count)
    if [[ $modified_count -gt 0 ]]; then
      _flow_log_info "Run 'dots apply' to apply changes"
    fi
  else
    _flow_log_error "Failed to sync"
    return 1
  fi
}

# ───────────────────────────────────────────────────────────────────
# PUSH COMMAND (Push to remote)
# ───────────────────────────────────────────────────────────────────

_dots_push() {
  if ! _dotf_require_tool "chezmoi" "brew install chezmoi"; then
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
    if _dotf_is_ahead_of_remote; then
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

_dots_undo() {
  _flow_log_warning "Phase 2: Undo command not yet implemented"
  _flow_log_info "For now, use: chezmoi diff && chezmoi apply --dry-run"
}

# ═══════════════════════════════════════════════════════════════════
# DOCTOR HEALTH CHECK (Integrated with flow doctor)
# ═══════════════════════════════════════════════════════════════════

_dots_doctor() {
  _flow_log_warning "Phase 3: Doctor diagnostics not yet implemented"
  _flow_log_info "Coming in Phase 3 (Integration)"
}

_dots_doctor_check_chezmoi_health() {
  local chezmoi_dir="$HOME/.local/share/chezmoi"
  local ignore_file="$chezmoi_dir/.chezmoiignore"

  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🔧 Dotfile Management Health${FLOW_COLORS[reset]}                  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

  # 1. Check chezmoi installed
  if command -v chezmoi &>/dev/null; then
    local version=$(chezmoi --version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} chezmoi installed ($version)                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  else
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} chezmoi not installed                         ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Install: brew install chezmoi${FLOW_COLORS[reset]}                 ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
    echo ""
    return 1
  fi

  # 2. Check repository initialized
  if [[ -d "$chezmoi_dir/.git" ]]; then
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Repository initialized                        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"

    # 3. Check remote configured
    local remote=$(cd "$chezmoi_dir" && git remote get-url origin 2>/dev/null)
    if [[ -n "$remote" ]]; then
      # Truncate remote if too long
      local display_remote="$remote"
      if [[ ${#remote} -gt 30 ]]; then
        display_remote="...${remote: -27}"
      fi
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Remote: $display_remote    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    else
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]}  No remote repository configured              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Add: chezmoi git remote add origin <url>${FLOW_COLORS[reset]}    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    fi
  else
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} Repository not initialized                    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Initialize: chezmoi init${FLOW_COLORS[reset]}                      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
    echo ""
    return 1
  fi

  # 4. Check .chezmoiignore
  if [[ -f "$ignore_file" ]]; then
    local pattern_count=$(grep -c -v '^$' "$ignore_file" 2>/dev/null || echo 0)
    if (( pattern_count > 0 )); then
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} .chezmoiignore configured ($pattern_count patterns)  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    else
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]}  .chezmoiignore is empty                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Add: dots ignore add <pattern>${FLOW_COLORS[reset]}              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    fi
  else
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]}  No .chezmoiignore file found                 ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Create: dots ignore add '**/.git'${FLOW_COLORS[reset]}           ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  fi

  # 5. Check managed file count
  local managed_count=$(chezmoi managed 2>/dev/null | wc -l | tr -d ' ')
  if (( managed_count > 0 )); then
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $managed_count files managed                          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  else
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]}  No files managed by chezmoi                  ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  fi

  # 6. Check repository size
  if [[ -d "$chezmoi_dir" ]]; then
    local size_bytes=$(du -sk "$chezmoi_dir" 2>/dev/null | cut -f1)
    local size_mb=$((size_bytes / 1024))

    if (( size_mb < 5 )); then
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Repository size: ${size_mb} MB (healthy)           ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    elif (( size_mb < 20 )); then
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]}  Repository size: ${size_mb} MB (consider cleanup) ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Analyze: dots size${FLOW_COLORS[reset]}                            ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    else
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} Repository size: ${size_mb} MB (too large)         ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Cleanup: dots size${FLOW_COLORS[reset]}                            ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    fi
  fi

  # 7. Check for large files (>100KB)
  local large_files=$(find "$chezmoi_dir" -type f -not -path "$chezmoi_dir/.git/*" -size +100k 2>/dev/null)
  local large_count=0
  if [[ -n "$large_files" ]]; then
    large_count=$(echo "$large_files" | wc -l | tr -d ' ')
  fi

  if (( large_count > 0 )); then
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]}  Large files tracked (>100KB):                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    echo "$large_files" | head -3 | while read -r file; do
      local size=$(du -h "$file" 2>/dev/null | cut -f1)
      local rel_path="${file#$chezmoi_dir/}"
      # Truncate path if too long
      if [[ ${#rel_path} -gt 35 ]]; then
        rel_path="...${rel_path: -32}"
      fi
      printf "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}     %-6s  %-35s ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}\n" "$size" "$rel_path"
    done
    if (( large_count > 3 )); then
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}     ${FLOW_COLORS[muted]}...and $((large_count - 3)) more${FLOW_COLORS[reset]}                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    fi
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Review: dots size${FLOW_COLORS[reset]}                              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  else
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} No large files tracked                        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  fi

  # 8. Check for nested .git directories
  local git_dirs=$(find "$chezmoi_dir" -name ".git" -type d -not -path "$chezmoi_dir/.git" 2>/dev/null)
  local git_dotf_dirs=$(find "$chezmoi_dir" -name "dot_git" -type d 2>/dev/null)
  local git_count=0
  local git_dotf_count=0
  if [[ -n "$git_dirs" ]]; then
    git_count=$(echo "$git_dirs" | wc -l | tr -d ' ')
  fi
  if [[ -n "$git_dotf_dirs" ]]; then
    git_dotf_count=$(echo "$git_dotf_dirs" | wc -l | tr -d ' ')
  fi
  local total_git=$((git_count + git_dotf_count))

  if [[ -n "$git_dirs" ]] || [[ -n "$git_dotf_dirs" ]]; then
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} Git directories tracked ($total_git found):        ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    if [[ -n "$git_dirs" ]]; then
      echo "$git_dirs" | head -2 | while read -r gitdir; do
        local rel_path="${gitdir#$chezmoi_dir/}"
        if [[ ${#rel_path} -gt 40 ]]; then
          rel_path="...${rel_path: -37}"
        fi
        printf "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}     - %-40s ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}\n" "$rel_path"
      done
    fi
    if [[ -n "$git_dotf_dirs" ]]; then
      echo "$git_dotf_dirs" | head -2 | while read -r gitdir; do
        local rel_path="${gitdir#$chezmoi_dir/}"
        if [[ ${#rel_path} -gt 40 ]]; then
          rel_path="...${rel_path: -37}"
        fi
        printf "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}     - %-40s ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}\n" "$rel_path"
      done
    fi
    if (( total_git > 2 )); then
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}     ${FLOW_COLORS[muted]}...and $((total_git - 2)) more${FLOW_COLORS[reset]}                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
    fi
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Fix: dots ignore add '**/.git'${FLOW_COLORS[reset]}                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  else
    echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} No nested git directories tracked             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  fi

  # 9. Check sync status
  local sync_status=$(_dotf_get_sync_status 2>/dev/null || echo "unknown")
  local last_sync=$(_dotf_get_last_sync_time 2>/dev/null || echo "never")

  case "$sync_status" in
    "synced")
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} Sync status: synced ($last_sync)              ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      ;;
    "modified")
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]}  Sync status: local changes ($last_sync)      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Sync: dots push${FLOW_COLORS[reset]}                               ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      ;;
    "behind")
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]}  Sync status: behind remote ($last_sync)      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Pull: dots sync${FLOW_COLORS[reset]}                               ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      ;;
    "ahead")
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[info]}ℹ${FLOW_COLORS[reset]}  Sync status: ahead of remote ($last_sync)    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[muted]}Push: dots push${FLOW_COLORS[reset]}                               ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      ;;
    *)
      echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[info]}ℹ${FLOW_COLORS[reset]}  Sync status: $sync_status                     ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
      ;;
  esac

  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰───────────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
}

# ═══════════════════════════════════════════════════════════════════
# INIT
# ═══════════════════════════════════════════════════════════════════

_dots_init() {
  _flow_log_warning "Phase 3: Init command not yet implemented"
  _flow_log_info "Coming in Phase 3 (Integration)"
}

# ═══════════════════════════════════════════════════════════════════
# DOT ENV - Direnv Integration (Phase 3 - v2.2.0)
# ═══════════════════════════════════════════════════════════════════

_dots_env() {
  local subcommand="$1"

  case "$subcommand" in
    init)
      shift
      _dots_env_init "$@"
      ;;
    help|--help|-h)
      _dots_env_help
      ;;
    "")
      _dots_env_help
      ;;
    *)
      _flow_log_error "Unknown subcommand: $subcommand"
      _dots_env_help
      return 1
      ;;
  esac
}

_dots_env_help() {
  echo ""
  echo "${FLOW_COLORS[header]}╭───────────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}🔧 DOTS ENV - Direnv Integration${FLOW_COLORS[reset]}                ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}├───────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                   ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}Commands:${FLOW_COLORS[reset]}                                       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}    ${FLOW_COLORS[cmd]}dots env init${FLOW_COLORS[reset]}  Generate .envrc             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
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

_dots_env_init() {
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
  if ! _dotf_require_tool "bw" "brew install bitwarden-cli"; then
    return 1
  fi

  # Check session
  if ! _dotf_bw_session_valid; then
    _flow_log_info "Bitwarden vault is locked. Unlocking..."
    _sec_unlock || return 1
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
    _flow_log_info "Use 'tok' or 'sec' to create secrets"
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
  local envrc_content="# Generated by dots env init
# Secrets are fetched from Bitwarden vault
# Requires: direnv, bitwarden-cli, flow-cli

# Ensure Bitwarden is unlocked
if ! dots unlock --check 2>/dev/null; then
  echo \"⚠ Bitwarden vault is locked. Run: sec unlock\"
  return 1
fi

# Load secrets
"

  for name in "${selected_secrets[@]}"; do
    # Convert to SCREAMING_SNAKE_CASE
    local env_name=$(echo "${name}" | tr '[:lower:]-' '[:upper:]_')
    envrc_content+="export ${env_name}=\$(sec get ${name})
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
