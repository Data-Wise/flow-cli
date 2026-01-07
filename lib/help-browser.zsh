# lib/help-browser.zsh - Interactive help browser with fzf
# Browse all flow-cli commands with preview and full help

# ============================================================================
# INTERACTIVE HELP BROWSER
# ============================================================================

# Preview helper function for fzf
_flow_show_help_preview() {
  local cmd="$1"

  # Command is available in current shell (plugin loaded)
  if type "${cmd}" >/dev/null 2>&1; then
    if [[ "$cmd" =~ ^(g|cc|wt|mcp|r|qu|obs|tm)$ ]]; then
      # Dispatcher - call with help
      $cmd help 2>/dev/null || echo "Help not available for $cmd"
    else
      # Regular command - check for --help or help subcommand
      $cmd --help 2>/dev/null || $cmd help 2>/dev/null || echo "Help not available for $cmd"
    fi
  else
    echo "Command not found: $cmd"
    echo ""
    echo "Note: This command requires flow-cli to be loaded."
  fi
}

_flow_help_browser() {
  # Check for fzf
  if ! command -v fzf &>/dev/null; then
    _flow_log_error "fzf is required for interactive help"
    echo ""
    echo "Install fzf:"
    echo "  ${FLOW_COLORS[cmd]}brew install fzf${FLOW_COLORS[reset]}     # macOS"
    echo "  ${FLOW_COLORS[cmd]}apt install fzf${FLOW_COLORS[reset]}      # Linux"
    echo ""
    echo "Or use non-interactive help: ${FLOW_COLORS[cmd]}flow help${FLOW_COLORS[reset]}"
    return 1
  fi

  # Build command list with descriptions
  local commands=(
    # Core workflow commands
    "work:Start working on a project (session management)"
    "finish:End current work session (optional commit)"
    "hop:Quick switch between tmux sessions"
    "dash:Project dashboard (overview of all projects)"
    "pick:Project picker with fzf (frecency sorted)"
    "catch:Quick capture ideas and tasks"

    # ADHD-friendly commands
    "js:Just start (auto-pick project and begin)"
    "next:Get next action suggestion (AI-powered)"
    "stuck:Get unstuck when blocked (AI-powered)"
    "focus:Set focus mode and timer"
    "brk:Take a break (pomodoro integration)"
    "win:Log an accomplishment (dopamine hit)"
    "yay:Show recent wins and streaks"

    # Status & tracking
    "status:Show current project status"
    "morning:Morning routine (goals, focus, plan)"
    "today:Today's summary (progress, wins, time)"
    "week:Weekly summary and stats"

    # Configuration
    "flow:Main flow-cli command (help, version, config)"
    "doctor:Health check and dependency verification"
    "setup:First-run setup wizard"
    "config:View and edit configuration"
    "sync:Sync project state with remote"

    # Utilities
    "ref:Quick reference card (command or workflow)"
    "timer:Timer management (pomodoro, focus)"

    # Dispatchers (domain-specific workflows)
    "g:Git workflows (status, commit, push, feature)"
    "cc:Claude Code launcher (pick, yolo, plan, resume)"
    "wt:Git worktree management (create, list, prune)"
    "mcp:MCP server management (status, logs, test)"
    "r:R package development (test, doc, check, cran)"
    "qu:Quarto publishing (render, preview, publish)"
    "obs:Obsidian notes (vaults, open, stats, sync)"
    "tm:Terminal manager (title, profile, theme, switch)"
  )

  # Format for fzf
  local formatted_list=""
  for item in "${commands[@]}"; do
    local cmd="${item%%:*}"
    local desc="${item#*:}"
    formatted_list+="${FLOW_COLORS[cmd]}${cmd}${FLOW_COLORS[reset]}\t${desc}\n"
  done

  # fzf with preview showing help output
  local selected=$(echo -e "$formatted_list" | fzf \
    --ansi \
    --prompt="📚 Flow Commands > " \
    --header="Press ENTER for full help | ESC to cancel" \
    --preview-window="right:60%:wrap" \
    --preview='
      cmd=$(echo {} | awk "{print \$1}")
      # Strip ANSI codes from cmd
      cmd=$(echo "$cmd" | sed "s/\x1b\[[0-9;]*m//g")

      # Use helper function (available in current shell environment)
      _flow_show_help_preview "$cmd"
    ' \
    --border=rounded \
    --color="header:bold,prompt:cyan,pointer:cyan,marker:green" \
    --height=80%
  )

  # If user selected a command, show full help
  if [[ -n "$selected" ]]; then
    local cmd=$(echo "$selected" | awk '{print $1}' | sed 's/\x1b\[[0-9;]*m//g')

    echo ""
    echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[bold]}Full Help: $cmd${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
    echo ""

    # Show full help
    if [[ "$cmd" =~ ^(g|cc|wt|mcp|r|qu|obs|tm)$ ]]; then
      $cmd help
    else
      $cmd --help 2>/dev/null || $cmd help 2>/dev/null || {
        echo "Help not available for: $cmd"
        echo ""
        echo "Try: ${FLOW_COLORS[cmd]}$cmd --help${FLOW_COLORS[reset]} or ${FLOW_COLORS[cmd]}$cmd help${FLOW_COLORS[reset]}"
      }
    fi
  fi
}
