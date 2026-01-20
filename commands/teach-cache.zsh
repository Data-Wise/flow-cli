# commands/teach-cache.zsh - Interactive cache management for Quarto teaching projects
# Provides: teach cache (interactive TUI menu)

# ============================================================================
# INTERACTIVE CACHE MENU
# ============================================================================

# Interactive cache management menu
# Usage: teach_cache_interactive [project_root]
teach_cache_interactive() {
    local project_root="${1:-$PWD}"

    # Verify we're in a Quarto project
    if [[ ! -f "$project_root/_quarto.yml" ]]; then
        _flow_log_error "Not in a Quarto project"
        return 1
    fi

    while true; do
        # Get current cache status
        local cache_info=$(_cache_status "$project_root")
        eval "$cache_info"

        # Clear screen
        clear

        # Draw menu
        echo ""
        echo "${FLOW_COLORS[header]}┌─────────────────────────────────────────────────────────────┐${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]} ${FLOW_COLORS[bold]}Freeze Cache Management${FLOW_COLORS[reset]}                                    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[header]}├─────────────────────────────────────────────────────────────┤${FLOW_COLORS[reset]}"

        if [[ "$cache_status" == "none" ]]; then
            echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}Cache: None (not yet created)${FLOW_COLORS[reset]}                          ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
            echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
        else
            printf "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]} Cache: %-10s (%-6s files)                            ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}\n" \
                "$size_human" "$file_count"
            printf "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]} Last render: %-44s ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}\n" "$last_render"
            echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
        fi

        echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]} ${FLOW_COLORS[info]}1.${FLOW_COLORS[reset]} View cache details                                      ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]} ${FLOW_COLORS[info]}2.${FLOW_COLORS[reset]} Clear cache (delete _freeze/)                           ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]} ${FLOW_COLORS[info]}3.${FLOW_COLORS[reset]} Rebuild cache (force re-render)                         ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]} ${FLOW_COLORS[info]}4.${FLOW_COLORS[reset]} Clean all (delete _freeze/ + _site/)                    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]} ${FLOW_COLORS[info]}5.${FLOW_COLORS[reset]} Exit                                                    ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}                                                             ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
        echo "${FLOW_COLORS[header]}└─────────────────────────────────────────────────────────────┘${FLOW_COLORS[reset]}"
        echo ""

        # Read choice
        read "?${FLOW_COLORS[info]}Choice:${FLOW_COLORS[reset]} " choice
        echo ""

        case "$choice" in
            1)
                # View cache details
                _cache_analyze "$project_root"
                echo ""
                read "?Press Enter to continue..."
                ;;

            2)
                # Clear cache
                _cache_clear "$project_root"
                echo ""
                read "?Press Enter to continue..."
                ;;

            3)
                # Rebuild cache
                _cache_rebuild "$project_root"
                echo ""
                read "?Press Enter to continue..."
                ;;

            4)
                # Clean all
                _cache_clean "$project_root"
                echo ""
                read "?Press Enter to continue..."
                ;;

            5|q|quit|exit)
                _flow_log_info "Exiting cache management"
                return 0
                ;;

            *)
                _flow_log_error "Invalid choice: $choice"
                sleep 1
                ;;
        esac
    done
}

# ============================================================================
# COMMAND-LINE INTERFACE (non-interactive)
# ============================================================================

# Cache status command
# Usage: teach cache status
teach_cache_status() {
    local project_root="$PWD"

    # Get cache status
    local cache_info=$(_cache_status "$project_root")
    eval "$cache_info"

    echo ""
    echo "${FLOW_COLORS[header]}Freeze Cache Status${FLOW_COLORS[reset]}"
    echo ""

    if [[ "$cache_status" == "none" ]]; then
        echo "  ${FLOW_COLORS[muted]}No cache found${FLOW_COLORS[reset]}"
        echo "  (Cache will be created on first render)"
    else
        echo "  Location:     $project_root/_freeze"
        echo "  Size:         $size_human"
        echo "  Files:        $file_count"
        echo "  Last render:  $last_render"
    fi

    echo ""
}

# Cache clear command
# Usage: teach cache clear [--force]
teach_cache_clear() {
    _cache_clear "$PWD" "$@"
}

# Cache rebuild command
# Usage: teach cache rebuild
teach_cache_rebuild() {
    _cache_rebuild "$PWD"
}

# Cache analyze command
# Usage: teach cache analyze
teach_cache_analyze() {
    _cache_analyze "$PWD"
}

# ============================================================================
# MAIN DISPATCHER
# ============================================================================

# Main teach cache dispatcher
# Usage: teach cache [subcommand]
teach_cache() {
    # No arguments = interactive menu
    if [[ $# -eq 0 ]]; then
        teach_cache_interactive
        return $?
    fi

    # Parse subcommand
    local subcommand="$1"
    shift

    case "$subcommand" in
        status|s)
            teach_cache_status "$@"
            ;;

        clear|c)
            teach_cache_clear "$@"
            ;;

        rebuild|r)
            teach_cache_rebuild "$@"
            ;;

        analyze|a|details|d)
            teach_cache_analyze "$@"
            ;;

        help|--help|-h)
            _teach_cache_help
            ;;

        *)
            _flow_log_error "Unknown cache subcommand: $subcommand"
            echo ""
            echo "Run 'teach cache help' for usage"
            return 1
            ;;
    esac
}

# ============================================================================
# TEACH CLEAN COMMAND (separate from cache dispatcher)
# ============================================================================

# Clean command (delete _freeze/ + _site/)
# Usage: teach clean [--force]
teach_clean() {
    _cache_clean "$PWD" "$@"
}

# ============================================================================
# HELP
# ============================================================================

_teach_cache_help() {
    cat <<'EOF'

teach cache - Manage Quarto freeze cache

USAGE:
  teach cache                    Interactive menu
  teach cache status             Show cache size and file count
  teach cache clear [--force]    Delete _freeze/ directory
  teach cache rebuild            Clear cache and re-render
  teach cache analyze            Detailed cache breakdown

  teach clean [--force]          Delete _freeze/ + _site/

INTERACTIVE MENU:
  When run without arguments, opens an interactive TUI menu:

  ┌─────────────────────────────────────────────────────────────┐
  │ Freeze Cache Management                                     │
  ├─────────────────────────────────────────────────────────────┤
  │ Cache: 71MB (342 files)                                     │
  │ Last render: 2 hours ago                                    │
  │                                                             │
  │ 1. View cache details                                       │
  │ 2. Clear cache (delete _freeze/)                            │
  │ 3. Rebuild cache (force re-render)                          │
  │ 4. Clean all (delete _freeze/ + _site/)                     │
  │ 5. Exit                                                     │
  │                                                             │
  │ Choice: _                                                   │
  └─────────────────────────────────────────────────────────────┘

EXAMPLES:
  # Interactive menu
  teach cache

  # Quick status check
  teach cache status

  # Clear cache (with confirmation)
  teach cache clear

  # Force clear without confirmation
  teach cache clear --force

  # Rebuild from scratch
  teach cache rebuild

  # Detailed analysis
  teach cache analyze

  # Clean everything
  teach clean

ABOUT FREEZE CACHE:
  Quarto's freeze feature caches computation results to speed up
  rendering. The cache is stored in _freeze/ and grows over time.

  When to clear cache:
  - After major code changes
  - When results seem stale
  - To free disk space
  - Before final render

  The cache will be automatically rebuilt on next render.

EOF
}
