# lib/ai-usage.zsh - AI usage tracking and personalized suggestions
# Tracks command usage to provide personalized recommendations

# ============================================================================
# USAGE STORAGE
# ============================================================================

# Usage log file
FLOW_AI_USAGE_FILE="${FLOW_DATA_DIR}/ai-usage.jsonl"

# Usage stats file (aggregated)
FLOW_AI_STATS_FILE="${FLOW_DATA_DIR}/ai-stats.json"

# ============================================================================
# USAGE LOGGING
# ============================================================================

# Log an AI command usage
# Usage: _flow_ai_log_usage "command" "mode" "success" "duration_ms"
_flow_ai_log_usage() {
  local command="$1"      # ai, do, recipe, chat
  local mode="$2"         # default, explain, fix, suggest, create, recipe:name
  local success="$3"      # true/false
  local duration="$4"     # milliseconds

  [[ ! -d "${FLOW_DATA_DIR}" ]] && mkdir -p "${FLOW_DATA_DIR}"

  # Create JSON log entry
  local timestamp=$(date -Iseconds)
  local project="${FLOW_SESSION_PROJECT:-${PWD:t}}"
  local proj_type=$(_flow_detect_type 2>/dev/null || echo "unknown")

  # Append to JSONL file
  cat >> "$FLOW_AI_USAGE_FILE" <<EOF
{"ts":"$timestamp","cmd":"$command","mode":"$mode","ok":$success,"ms":$duration,"proj":"$project","type":"$proj_type"}
EOF

  # Update aggregated stats
  _flow_ai_update_stats "$command" "$mode" "$success"
}

# Update aggregated statistics
_flow_ai_update_stats() {
  local command="$1"
  local mode="$2"
  local success="$3"

  # Initialize stats file if needed
  if [[ ! -f "$FLOW_AI_STATS_FILE" ]]; then
    cat > "$FLOW_AI_STATS_FILE" <<'EOF'
{
  "total_calls": 0,
  "successful": 0,
  "failed": 0,
  "commands": {},
  "modes": {},
  "recipes": {},
  "projects": {},
  "last_used": null,
  "streak_days": 0,
  "last_streak_date": null
}
EOF
  fi

  # Use a simple approach: read, modify, write
  # In production, you'd want proper JSON handling
  local stats=$(cat "$FLOW_AI_STATS_FILE")

  # Increment counters using jq if available, otherwise use basic approach
  if command -v jq >/dev/null 2>&1; then
    local today=$(date +%Y-%m-%d)
    local new_stats=$(echo "$stats" | jq \
      --arg cmd "$command" \
      --arg mode "$mode" \
      --arg ok "$success" \
      --arg today "$today" \
      '
      .total_calls += 1 |
      if $ok == "true" then .successful += 1 else .failed += 1 end |
      .commands[$cmd] = ((.commands[$cmd] // 0) + 1) |
      .modes[$mode] = ((.modes[$mode] // 0) + 1) |
      .last_used = $today |
      if .last_streak_date == null then
        .streak_days = 1 | .last_streak_date = $today
      elif .last_streak_date == $today then
        .
      elif (.last_streak_date | strptime("%Y-%m-%d") | mktime) == (($today | strptime("%Y-%m-%d") | mktime) - 86400) then
        .streak_days += 1 | .last_streak_date = $today
      else
        .streak_days = 1 | .last_streak_date = $today
      end
      ')
    echo "$new_stats" > "$FLOW_AI_STATS_FILE"
  fi
}

# ============================================================================
# USAGE STATISTICS
# ============================================================================

# Get usage statistics
_flow_ai_get_stats() {
  if [[ ! -f "$FLOW_AI_STATS_FILE" ]]; then
    echo "{}"
    return
  fi
  cat "$FLOW_AI_STATS_FILE"
}

# Show usage statistics
flow_ai_stats() {
  echo ""
  echo "${FLOW_COLORS[header]}AI USAGE STATISTICS${FLOW_COLORS[reset]}"
  echo ""

  if [[ ! -f "$FLOW_AI_STATS_FILE" ]]; then
    echo "${FLOW_COLORS[muted]}No usage data yet. Start using AI commands!${FLOW_COLORS[reset]}"
    echo ""
    return
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "${FLOW_COLORS[muted]}Install jq for detailed stats: brew install jq${FLOW_COLORS[reset]}"
    echo ""
    cat "$FLOW_AI_STATS_FILE"
    return
  fi

  local stats=$(cat "$FLOW_AI_STATS_FILE")

  # Total calls
  local total=$(echo "$stats" | jq -r '.total_calls // 0')
  local success=$(echo "$stats" | jq -r '.successful // 0')
  local failed=$(echo "$stats" | jq -r '.failed // 0')
  local streak=$(echo "$stats" | jq -r '.streak_days // 0')

  echo "  ${FLOW_COLORS[bold]}Overview${FLOW_COLORS[reset]}"
  printf "    Total calls:    %s\n" "$total"
  printf "    Successful:     %s\n" "$success"
  printf "    Failed:         %s\n" "$failed"
  printf "    Current streak: %s days\n" "$streak"
  echo ""

  # Top commands
  echo "  ${FLOW_COLORS[bold]}Top Commands${FLOW_COLORS[reset]}"
  echo "$stats" | jq -r '.commands | to_entries | sort_by(-.value) | .[:5] | .[] | "    \(.key): \(.value)"'
  echo ""

  # Top modes
  echo "  ${FLOW_COLORS[bold]}Top Modes${FLOW_COLORS[reset]}"
  echo "$stats" | jq -r '.modes | to_entries | sort_by(-.value) | .[:5] | .[] | "    \(.key): \(.value)"'
  echo ""

  # Top recipes
  local recipes=$(echo "$stats" | jq -r '.recipes | to_entries | length')
  if [[ "$recipes" -gt 0 ]]; then
    echo "  ${FLOW_COLORS[bold]}Top Recipes${FLOW_COLORS[reset]}"
    echo "$stats" | jq -r '.recipes | to_entries | sort_by(-.value) | .[:5] | .[] | "    \(.key): \(.value)"'
    echo ""
  fi
}

# ============================================================================
# PERSONALIZED SUGGESTIONS
# ============================================================================

# Get personalized AI suggestions based on usage history
flow_ai_suggest() {
  echo ""
  echo "${FLOW_COLORS[header]}AI SUGGESTIONS${FLOW_COLORS[reset]}"
  echo ""

  # Check if we have enough data
  if [[ ! -f "$FLOW_AI_USAGE_FILE" ]] || [[ ! -s "$FLOW_AI_USAGE_FILE" ]]; then
    echo "${FLOW_COLORS[muted]}Not enough usage data yet for personalized suggestions.${FLOW_COLORS[reset]}"
    echo ""
    echo "  ${FLOW_COLORS[bold]}Quick Start${FLOW_COLORS[reset]}"
    echo "    ${FLOW_COLORS[accent]}flow ai${FLOW_COLORS[reset]} \"what does this code do?\""
    echo "    ${FLOW_COLORS[accent]}flow ai recipe review${FLOW_COLORS[reset]} \"your code\""
    echo "    ${FLOW_COLORS[accent]}flow ai chat${FLOW_COLORS[reset]}"
    echo ""
    return
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "${FLOW_COLORS[muted]}Install jq for personalized suggestions: brew install jq${FLOW_COLORS[reset]}"
    return
  fi

  local stats=$(cat "$FLOW_AI_STATS_FILE")
  local proj_type=$(_flow_detect_type 2>/dev/null || echo "unknown")

  echo "  ${FLOW_COLORS[bold]}Based on Your Usage${FLOW_COLORS[reset]}"
  echo ""

  # Suggest recipes based on project type
  case "$proj_type" in
    r-package)
      echo "  ${FLOW_COLORS[accent]}For R packages:${FLOW_COLORS[reset]}"
      echo "    flow ai recipe test \"function code\"    # Generate testthat tests"
      echo "    flow ai recipe document \"function\"     # Generate roxygen docs"
      echo "    flow ai --fix \"R CMD check errors\""
      ;;
    node)
      echo "  ${FLOW_COLORS[accent]}For Node.js:${FLOW_COLORS[reset]}"
      echo "    flow ai recipe test \"function code\"    # Generate Jest tests"
      echo "    flow ai --fix \"npm/TypeScript errors\""
      echo "    flow ai recipe refactor \"component\""
      ;;
    quarto)
      echo "  ${FLOW_COLORS[accent]}For Quarto:${FLOW_COLORS[reset]}"
      echo "    flow ai --explain \"YAML frontmatter\""
      echo "    flow ai recipe document \"analysis code\""
      echo "    flow ai --suggest \"better visualizations\""
      ;;
    zsh-plugin)
      echo "  ${FLOW_COLORS[accent]}For ZSH plugins:${FLOW_COLORS[reset]}"
      echo "    flow ai recipe shell \"what you need\""
      echo "    flow ai --create \"completion function\""
      echo "    flow ai --fix \"zsh syntax error\""
      ;;
    *)
      echo "  ${FLOW_COLORS[accent]}General suggestions:${FLOW_COLORS[reset]}"
      echo "    flow ai recipe commit \"\$(git diff --staged)\""
      echo "    flow ai recipe review \"code to review\""
      echo "    flow ai chat --context"
      ;;
  esac

  echo ""

  # Check for unused features
  local used_chat=$(echo "$stats" | jq -r '.commands.chat // 0')
  local used_recipe=$(echo "$stats" | jq -r '.modes | to_entries | map(select(.key | startswith("recipe:"))) | length')

  echo "  ${FLOW_COLORS[bold]}Try These Features${FLOW_COLORS[reset]}"

  if [[ "$used_chat" -eq 0 ]]; then
    echo "    ${FLOW_COLORS[accent]}flow ai chat${FLOW_COLORS[reset]} - You haven't tried chat mode yet!"
  fi

  if [[ "$used_recipe" -lt 3 ]]; then
    echo "    ${FLOW_COLORS[accent]}flow ai recipe list${FLOW_COLORS[reset]} - Explore 10 built-in recipes"
  fi

  # Streak encouragement
  local streak=$(echo "$stats" | jq -r '.streak_days // 0')
  if [[ "$streak" -gt 0 ]]; then
    echo ""
    echo "  ${FLOW_COLORS[success]}🔥 ${streak}-day streak! Keep it going!${FLOW_COLORS[reset]}"
  fi

  echo ""
}

# ============================================================================
# RECENT ACTIVITY
# ============================================================================

# Show recent AI usage
flow_ai_recent() {
  local limit="${1:-10}"

  echo ""
  echo "${FLOW_COLORS[header]}RECENT AI ACTIVITY${FLOW_COLORS[reset]}"
  echo ""

  if [[ ! -f "$FLOW_AI_USAGE_FILE" ]] || [[ ! -s "$FLOW_AI_USAGE_FILE" ]]; then
    echo "${FLOW_COLORS[muted]}No activity yet.${FLOW_COLORS[reset]}"
    echo ""
    return
  fi

  echo "  ${FLOW_COLORS[bold]}Last $limit commands:${FLOW_COLORS[reset]}"
  echo ""

  # Show last N entries
  tail -n "$limit" "$FLOW_AI_USAGE_FILE" | while read -r line; do
    if command -v jq >/dev/null 2>&1; then
      local ts=$(echo "$line" | jq -r '.ts' | cut -d'T' -f2 | cut -d'+' -f1)
      local cmd=$(echo "$line" | jq -r '.cmd')
      local mode=$(echo "$line" | jq -r '.mode')
      local ok=$(echo "$line" | jq -r '.ok')
      local icon="✓"
      [[ "$ok" == "false" ]] && icon="✗"

      printf "    %s %s %s (%s)\n" "$ts" "$icon" "$cmd" "$mode"
    else
      echo "    $line"
    fi
  done

  echo ""
}

# ============================================================================
# CLEANUP
# ============================================================================

# Clear usage history
flow_ai_clear_history() {
  if _flow_confirm "Clear all AI usage history?"; then
    [[ -f "$FLOW_AI_USAGE_FILE" ]] && rm "$FLOW_AI_USAGE_FILE"
    [[ -f "$FLOW_AI_STATS_FILE" ]] && rm "$FLOW_AI_STATS_FILE"
    _flow_log_success "AI usage history cleared"
  fi
}

# ============================================================================
# COMMAND HANDLER
# ============================================================================

# Add to flow ai command
flow_ai_usage() {
  local action="${1:-stats}"

  case "$action" in
    stats)
      flow_ai_stats
      ;;
    suggest|suggestions)
      flow_ai_suggest
      ;;
    recent|history)
      shift
      flow_ai_recent "$@"
      ;;
    clear)
      flow_ai_clear_history
      ;;
    help|--help|-h)
      _flow_ai_usage_help
      ;;
    *)
      echo "Unknown action: $action"
      _flow_ai_usage_help
      ;;
  esac
}

_flow_ai_usage_help() {
  echo ""
  echo "${FLOW_COLORS[header]}╭─────────────────────────────────────────────╮${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}  ${FLOW_COLORS[bold]}📊 flow ai usage${FLOW_COLORS[reset]} - AI Usage Tracking       ${FLOW_COLORS[header]}│${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[header]}╰─────────────────────────────────────────────╯${FLOW_COLORS[reset]}"
  echo ""
  echo "${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}"
  echo "  flow ai usage [action]"
  echo ""
  echo "${FLOW_COLORS[bold]}ACTIONS${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[accent]}stats${FLOW_COLORS[reset]}        Show usage statistics"
  echo "  ${FLOW_COLORS[accent]}suggest${FLOW_COLORS[reset]}      Get personalized suggestions"
  echo "  ${FLOW_COLORS[accent]}recent [n]${FLOW_COLORS[reset]}   Show last n commands (default: 10)"
  echo "  ${FLOW_COLORS[accent]}clear${FLOW_COLORS[reset]}        Clear usage history"
  echo ""
  echo "${FLOW_COLORS[bold]}FEATURES${FLOW_COLORS[reset]}"
  echo "  • Tracks all AI command usage"
  echo "  • Provides personalized suggestions"
  echo "  • Maintains usage streaks"
  echo "  • Project-type aware recommendations"
  echo ""
}
