# commands/ref.zsh - Quick reference card
# Display command and workflow quick references

# ============================================================================
# REF COMMAND
# ============================================================================

ref() {
  local type="${1:-command}"
  local ref_file=""

  case "$type" in
    -h|--help|help)
      _ref_help
      return 0
      ;;
    command|cmd|c)
      ref_file="docs/reference/COMMAND-QUICK-REFERENCE.md"
      ;;
    workflow|work|w)
      ref_file="docs/reference/WORKFLOW-QUICK-REFERENCE.md"
      ;;
    *)
      # Default to command reference
      ref_file="docs/reference/COMMAND-QUICK-REFERENCE.md"
      ;;
  esac

  # Find flow-cli root
  local flow_root="${FLOW_PLUGIN_DIR:-}"
  if [[ -z "$flow_root" ]]; then
    # Try to find based on this file's location
    flow_root="${${(%):-%x}:A:h:h}"
  fi

  local full_path="$flow_root/$ref_file"

  if [[ ! -f "$full_path" ]]; then
    _flow_log_error "Reference file not found: $full_path"
    return 1
  fi

  # Display with best available tool
  if command -v bat &>/dev/null; then
    # Use bat for syntax highlighting
    command bat --style=plain --paging=always --language=markdown "$full_path"
  elif command -v glow &>/dev/null; then
    # Use glow for rendered markdown
    glow -p "$full_path"
  else
    # Fallback to less with cat
    if command -v less &>/dev/null; then
      cat "$full_path" | less
    else
      cat "$full_path"
    fi
  fi
}

# Help function
_ref_help() {
  echo ""
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[bold]}ref - Quick Reference Card${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[bold]}Usage:${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[cmd]}ref${FLOW_COLORS[reset]}              Show command quick reference (default)"
  echo "  ${FLOW_COLORS[cmd]}ref command${FLOW_COLORS[reset]}      Show command reference"
  echo "  ${FLOW_COLORS[cmd]}ref workflow${FLOW_COLORS[reset]}     Show workflow reference"
  echo ""
  echo "${FLOW_COLORS[bold]}Aliases:${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[cmd]}ref cmd${FLOW_COLORS[reset]}, ${FLOW_COLORS[cmd]}ref c${FLOW_COLORS[reset]}    Command reference"
  echo "  ${FLOW_COLORS[cmd]}ref work${FLOW_COLORS[reset]}, ${FLOW_COLORS[cmd]}ref w${FLOW_COLORS[reset]}   Workflow reference"
  echo ""
  echo "${FLOW_COLORS[bold]}EXAMPLES:${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} ref                ${FLOW_COLORS[muted]}# Quick lookup of all commands${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} ref workflow        ${FLOW_COLORS[muted]}# See common workflows${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[muted]}\$${FLOW_COLORS[reset]} ref cmd             ${FLOW_COLORS[muted]}# Command reference${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[muted]}📚 See also:${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[cmd]}flow help${FLOW_COLORS[reset]} - Full help system"
  echo "  ${FLOW_COLORS[cmd]}<cmd> help${FLOW_COLORS[reset]} - Command-specific help"
  echo "  ${FLOW_COLORS[cmd]}dash${FLOW_COLORS[reset]} - Project dashboard"
  echo ""
}
