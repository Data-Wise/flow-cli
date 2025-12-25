# lib/tui.zsh - Terminal UI components
# Provides: progress bars, sparklines, tables, pickers

# ============================================================================
# PROGRESS & SPARKLINES
# ============================================================================

# Draw a progress bar
_flow_progress_bar() {
  local current="$1"
  local total="$2"
  local width="${3:-20}"
  local filled_char="${4:-█}"
  local empty_char="${5:-░}"
  
  local percent=$(( current * 100 / total ))
  local filled=$(( current * width / total ))
  local empty=$(( width - filled ))
  
  printf "%s%s %d%%" \
    "$(printf '%*s' "$filled" '' | tr ' ' "$filled_char")" \
    "$(printf '%*s' "$empty" '' | tr ' ' "$empty_char")" \
    "$percent"
}

# Draw a sparkline from values
_flow_sparkline() {
  local -a values=("$@")
  local chars='▁▂▃▄▅▆▇█'
  local max=0
  local min=999999
  
  # Find min/max
  for v in "${values[@]}"; do
    (( v > max )) && max=$v
    (( v < min )) && min=$v
  done
  
  local range=$(( max - min ))
  (( range == 0 )) && range=1
  
  local result=""
  for v in "${values[@]}"; do
    local index=$(( (v - min) * 7 / range ))
    result+="${chars:$index:1}"
  done
  
  echo "$result"
}

# ============================================================================
# TABLES
# ============================================================================

# Print a simple table
_flow_table() {
  local -a headers=("${(s:,:)1}")
  shift
  local -a rows=("$@")
  
  # Print header
  printf "${FLOW_COLORS[header]}"
  printf "%-20s " "${headers[@]}"
  printf "${FLOW_COLORS[reset]}\n"
  
  # Print separator
  printf "─%.0s" {1..60}
  echo
  
  # Print rows
  for row in "${rows[@]}"; do
    local -a cols=("${(s:,:)row}")
    printf "%-20s " "${cols[@]}"
    echo
  done
}

# ============================================================================
# BOXES & PANELS
# ============================================================================

# Draw a box around text
_flow_box() {
  local title="$1"
  local content="$2"
  local width="${3:-50}"
  
  local inner_width=$(( width - 4 ))
  
  # Top border
  printf "╭─"
  [[ -n "$title" ]] && printf " %s " "$title"
  local title_len=${#title}
  local remaining=$(( inner_width - title_len - 2 ))
  printf "%${remaining}s" '' | tr ' ' '─'
  printf "╮\n"
  
  # Content
  while IFS= read -r line; do
    printf "│ %-${inner_width}s │\n" "$line"
  done <<< "$content"
  
  # Bottom border
  printf "╰"
  printf "%${width}s" '' | tr ' ' '─'
  printf "╯\n"
}

# ============================================================================
# FZF INTEGRATION
# ============================================================================

# Check if fzf is available
_flow_has_fzf() {
  command -v fzf &>/dev/null
}

# Project picker using fzf
_flow_pick_project() {
  if ! _flow_has_fzf; then
    _flow_log_error "fzf not installed. Install: brew install fzf"
    return 1
  fi
  
  local projects=$(_flow_list_projects)
  
  echo "$projects" | fzf \
    --header="🎯 Select Project" \
    --preview="_flow_show_project_preview {}" \
    --preview-window=right:50%:wrap \
    --height=40% \
    --layout=reverse \
    --border
}

# Project preview for fzf
_flow_show_project_preview() {
  local project="$1"
  local info=$(_flow_get_project "$project" 2>/dev/null)
  
  if [[ -n "$info" ]]; then
    eval "$info"
    echo "📁 $name"
    echo "   Path: $path"
    [[ -n "$status" ]] && echo "   Status: $status"
    
    # Show .STATUS file preview if exists
    if [[ -f "$path/.STATUS" ]]; then
      echo ""
      echo "── .STATUS ──"
      head -20 "$path/.STATUS"
    fi
  else
    echo "Project not found: $project"
  fi
}

# ============================================================================
# GUM INTEGRATION (optional, for prettier UI)
# ============================================================================

_flow_has_gum() {
  command -v gum &>/dev/null
}

# Styled input prompt
_flow_input() {
  local prompt="${1:-Enter value}"
  local placeholder="${2:-}"
  
  if _flow_has_gum; then
    gum input --placeholder="$placeholder" --prompt="$prompt: "
  else
    read "?$prompt: " response
    echo "$response"
  fi
}

# Styled confirmation
_flow_confirm_styled() {
  local prompt="${1:-Continue?}"
  
  if _flow_has_gum; then
    gum confirm "$prompt"
  else
    _flow_confirm "$prompt"
  fi
}

# Styled choice selector
_flow_choose() {
  local header="$1"
  shift
  local -a options=("$@")
  
  if _flow_has_gum; then
    printf '%s\n' "${options[@]}" | gum choose --header="$header"
  elif _flow_has_fzf; then
    printf '%s\n' "${options[@]}" | fzf --header="$header" --height=10
  else
    # Fallback to simple numbered list
    echo "$header"
    local i=1
    for opt in "${options[@]}"; do
      echo "  $i) $opt"
      ((i++))
    done
    read "?Select: " choice
    echo "${options[$choice]}"
  fi
}

# ============================================================================
# DASHBOARD WIDGETS
# ============================================================================

# Status indicator widget
_flow_widget_status() {
  local project="$1"
  local status="$2"
  local focus="$3"
  
  local icon=$(_flow_status_icon "$status")
  local color="${FLOW_COLORS[$status]:-${FLOW_COLORS[muted]}}"
  
  printf "%s ${color}%-15s${FLOW_COLORS[reset]}" "$icon" "$project"
  [[ -n "$focus" ]] && printf " │ %s" "$focus"
  echo
}

# Session timer widget
_flow_widget_timer() {
  local start_time="$1"
  local now=$(date +%s)
  local elapsed=$(( now - start_time ))
  
  printf "⏱️  %s" "$(_flow_format_duration $elapsed)"
}
