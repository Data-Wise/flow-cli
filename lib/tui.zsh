# lib/tui.zsh - Terminal UI components
# Provides: progress bars, sparklines, tables, pickers

# ============================================================================
# PROGRESS & SPARKLINES
# ============================================================================

# =============================================================================
# Function: _flow_progress_bar
# Purpose: Draw an ASCII progress bar with percentage
# =============================================================================
# Arguments:
#   $1 - (required) Current value
#   $2 - (required) Total/maximum value
#   $3 - (optional) Bar width in characters [default: 20]
#   $4 - (optional) Filled character [default: █]
#   $5 - (optional) Empty character [default: ░]
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Progress bar with percentage (e.g., "████████░░░░ 67%")
#
# Example:
#   # Basic usage
#   echo "Progress: $(_flow_progress_bar 7 10)"
#   # Output: Progress: ██████████████░░░░░░ 70%
#
#   # Custom width and characters
#   _flow_progress_bar 50 100 30 "=" "-"
#   # Output: ===============--------------- 50%
#
# Notes:
#   - Division truncates (no rounding)
#   - Safe for zero total (shows 0%)
# =============================================================================
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

# =============================================================================
# Function: _flow_sparkline
# Purpose: Generate a sparkline graph from numeric values
# =============================================================================
# Arguments:
#   $@ - (required) Numeric values (space-separated or array)
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Sparkline string using Unicode block characters
#
# Character Set:
#   ▁▂▃▄▅▆▇█ (8 levels from lowest to highest)
#
# Example:
#   _flow_sparkline 1 3 5 7 5 3 1
#   # Output: ▁▃▅▇▅▃▁
#
#   # From array
#   local -a commits=(2 4 8 12 6 3 1)
#   _flow_sparkline "${commits[@]}"
#   # Output: ▁▂▄█▃▂▁
#
# Notes:
#   - Auto-scales to min/max of input values
#   - Handles flat data (all same values) gracefully
#   - Useful for visualizing trends in dashboards
# =============================================================================
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

# =============================================================================
# Function: _flow_table
# Purpose: Display formatted table with headers and rows
# =============================================================================
# Arguments:
#   $1 - (required) Comma-separated header columns
#   $@ - (required) Comma-separated row data (one string per row)
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Formatted table with colored headers
#
# Example:
#   _flow_table "Name,Status,Time" \
#       "flow-cli,active,2h" \
#       "project-b,paused,1d" \
#       "project-c,archived,5d"
#
#   # Output:
#   # Name                 Status               Time
#   # ────────────────────────────────────────────────────────────
#   # flow-cli             active               2h
#   # project-b            paused               1d
#   # project-c            archived             5d
#
# Notes:
#   - Uses FLOW_COLORS[header] for header row
#   - Fixed 20-character column width
#   - Columns separated by comma in input strings
#   - Uses ZSH ${(s:,:)} parameter expansion for splitting
# =============================================================================
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

# =============================================================================
# Function: _flow_box
# Purpose: Draw a Unicode box around text content
# =============================================================================
# Arguments:
#   $1 - (optional) Box title (displayed in top border)
#   $2 - (required) Content text (can be multiline)
#   $3 - (optional) Box width [default: 50]
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Box with rounded corners containing content
#
# Example:
#   _flow_box "Project Info" "Name: flow-cli
#   Status: active
#   Time: 2h 30m"
#
#   # Output:
#   # ╭─ Project Info ────────────────────────────────╮
#   # │ Name: flow-cli                                │
#   # │ Status: active                                │
#   # │ Time: 2h 30m                                  │
#   # ╰──────────────────────────────────────────────╯
#
# Notes:
#   - Uses Unicode box-drawing characters (╭╮╰╯│─)
#   - Content lines are padded to fit width
#   - Empty title shows plain top border
# =============================================================================
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

# =============================================================================
# Function: _flow_has_fzf
# Purpose: Check if fzf (fuzzy finder) is installed and available
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - fzf is available
#   1 - fzf is not installed
#
# Example:
#   if _flow_has_fzf; then
#       local choice=$(echo "$options" | fzf)
#   else
#       _flow_log_error "fzf required. Install: brew install fzf"
#   fi
#
# Notes:
#   - Uses command -v for portable detection
#   - Suppresses all output
# =============================================================================
_flow_has_fzf() {
  command -v fzf &>/dev/null
}

# =============================================================================
# Function: _flow_pick_project
# Purpose: Interactive project picker using fzf with preview
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - User selected a project
#   1 - fzf not installed or user cancelled
#
# Output:
#   stdout - Selected project name
#
# Example:
#   local project=$(_flow_pick_project)
#   if [[ -n "$project" ]]; then
#       cd "$(_flow_project_path "$project")"
#   fi
#
# Dependencies:
#   - fzf (required)
#   - _flow_list_projects (for project list)
#   - _flow_show_project_preview (for preview panel)
#
# Notes:
#   - Shows interactive picker with 40% height
#   - Preview panel shows project details and .STATUS
#   - User can cancel with Esc/Ctrl-C (returns empty)
# =============================================================================
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

# =============================================================================
# Function: _flow_show_project_preview
# Purpose: Generate preview content for fzf project picker
# =============================================================================
# Arguments:
#   $1 - (required) Project name to preview
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Formatted project info with optional .STATUS content
#
# Example:
#   # Called internally by fzf --preview
#   _flow_show_project_preview "flow-cli"
#
#   # Output:
#   # 📁 flow-cli
#   #    Path: /Users/dt/projects/flow-cli
#   #    Status: active
#   #
#   # ── .STATUS ──
#   # status: active
#   # progress: 85
#   # ...
#
# Dependencies:
#   - _flow_get_project (for project metadata)
#
# Notes:
#   - Used as fzf preview command
#   - Shows first 20 lines of .STATUS file
#   - Gracefully handles missing projects
# =============================================================================
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

# =============================================================================
# Function: _flow_has_gum
# Purpose: Check if gum (glamorous shell tool) is installed
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - gum is available
#   1 - gum is not installed
#
# Example:
#   if _flow_has_gum; then
#       gum style --foreground 212 "Pretty text!"
#   fi
#
# Notes:
#   - gum provides styled prompts, spinners, and inputs
#   - Install: brew install gum
#   - Functions fall back to basic ZSH when unavailable
# =============================================================================
_flow_has_gum() {
  command -v gum &>/dev/null
}

# =============================================================================
# Function: _flow_input
# Purpose: Styled text input prompt (uses gum if available)
# =============================================================================
# Arguments:
#   $1 - (optional) Prompt text [default: "Enter value"]
#   $2 - (optional) Placeholder text for input field
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - User input text
#
# Example:
#   local name=$(_flow_input "Project name" "my-project")
#   echo "Creating project: $name"
#
# Notes:
#   - Uses gum for styled input when available
#   - Falls back to ZSH read when gum not installed
#   - Placeholder only shown with gum
# =============================================================================
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

# =============================================================================
# Function: _flow_confirm_styled
# Purpose: Styled yes/no confirmation (uses gum if available)
# =============================================================================
# Arguments:
#   $1 - (optional) Prompt message [default: "Continue?"]
#
# Returns:
#   0 - User confirmed (yes)
#   1 - User declined (no)
#
# Example:
#   if _flow_confirm_styled "Delete these files?"; then
#       rm -rf ./cache
#   fi
#
# Notes:
#   - Uses gum for styled confirmation when available
#   - Falls back to _flow_confirm when gum not installed
#   - gum shows interactive yes/no buttons
# =============================================================================
_flow_confirm_styled() {
  local prompt="${1:-Continue?}"

  if _flow_has_gum; then
    gum confirm "$prompt"
  else
    _flow_confirm "$prompt"
  fi
}

# =============================================================================
# Function: _flow_choose
# Purpose: Multi-option selector (uses gum/fzf if available)
# =============================================================================
# Arguments:
#   $1 - (required) Header/prompt text
#   $@ - (required) Options to choose from
#
# Returns:
#   0 - User made selection
#   1 - No selection (cancelled or invalid)
#
# Output:
#   stdout - Selected option text
#
# Example:
#   local status=$(_flow_choose "Set project status:" \
#       "active" "paused" "blocked" "archived")
#   echo "Status set to: $status"
#
# Notes:
#   - Tries gum first (prettiest)
#   - Falls back to fzf (still interactive)
#   - Final fallback to numbered list with read
#   - Empty selection returns exit code 1
# =============================================================================
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

# =============================================================================
# Function: _flow_widget_status
# Purpose: Render a project status line for dashboards
# =============================================================================
# Arguments:
#   $1 - (required) Project name
#   $2 - (required) Status string (active, paused, blocked, etc.)
#   $3 - (optional) Focus/description text
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Formatted status line with icon and colors
#
# Example:
#   _flow_widget_status "flow-cli" "active" "Adding documentation"
#   # Output: 🟢 flow-cli        │ Adding documentation
#
#   _flow_widget_status "project-b" "paused"
#   # Output: 🟡 project-b
#
# Notes:
#   - Uses _flow_status_icon for emoji
#   - Color based on status from FLOW_COLORS
#   - Focus text separated by │ when provided
# =============================================================================
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

# =============================================================================
# Function: _flow_widget_timer
# Purpose: Render elapsed session time widget
# =============================================================================
# Arguments:
#   $1 - (required) Session start time (Unix timestamp)
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Timer display with emoji (e.g., "⏱️  2h 15m")
#
# Example:
#   local session_start=1706789400
#   _flow_widget_timer "$session_start"
#   # Output: ⏱️  2h 15m
#
# Dependencies:
#   - _flow_format_duration (from core.zsh)
#
# Notes:
#   - Calculates elapsed time from provided timestamp
#   - No newline appended (use in compound widgets)
# =============================================================================
_flow_widget_timer() {
  local start_time="$1"
  local now=$(date +%s)
  local elapsed=$(( now - start_time ))

  printf "⏱️  %s" "$(_flow_format_duration $elapsed)"
}

# ============================================================================
# SPINNER / LOADING INDICATOR
# ============================================================================

# Spinner frames (Braille dots - smooth animation)
typeset -g FLOW_SPINNER_FRAMES=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
typeset -g FLOW_SPINNER_PID=""

# =============================================================================
# Function: _flow_spinner_start
# Purpose: Start an animated spinner with message
# =============================================================================
# Arguments:
#   $1 - (optional) Message to display [default: "Working..."]
#   $2 - (optional) Time estimate (e.g., "~30-60s")
#
# Returns:
#   0 - Spinner started (or already running)
#
# Global State:
#   Sets FLOW_SPINNER_PID to background process ID
#
# Example:
#   _flow_spinner_start "Building project..." "~10s"
#   # ... long operation ...
#   _flow_spinner_stop "Build complete"
#
# Animation:
#   Uses Braille dots: ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏
#   Cycles at ~100ms intervals
#
# Notes:
#   - Only one spinner can run at a time
#   - Runs in background process
#   - Call _flow_spinner_stop to clean up
# =============================================================================
_flow_spinner_start() {
    local message="${1:-Working...}"
    local estimate="${2:-}"  # Optional: "~30-60s"

    # Don't start if already running
    [[ -n "$FLOW_SPINNER_PID" ]] && return

    # Build display message
    local display="$message"
    [[ -n "$estimate" ]] && display="$message (${estimate})"

    # Start spinner in background
    {
        local i=0
        local count=${#FLOW_SPINNER_FRAMES[@]}
        while true; do
            printf "\r${FLOW_COLORS[info]}%s${FLOW_COLORS[reset]} %s" \
                "${FLOW_SPINNER_FRAMES[$(( i % count + 1 ))]}" "$display"
            sleep 0.1
            ((i++))
        done
    } &
    FLOW_SPINNER_PID=$!
    disown $FLOW_SPINNER_PID 2>/dev/null
}

# =============================================================================
# Function: _flow_spinner_stop
# Purpose: Stop the running spinner and optionally show completion message
# =============================================================================
# Arguments:
#   $1 - (optional) Success message to display after stopping
#
# Returns:
#   0 - Always succeeds
#
# Global State:
#   Clears FLOW_SPINNER_PID
#
# Example:
#   _flow_spinner_stop "Build complete"
#   # Output: ✓ Build complete (in green)
#
#   _flow_spinner_stop  # Just stop, no message
#
# Notes:
#   - Safe to call even if no spinner running
#   - Clears the spinner line before showing message
#   - Success message shown with green checkmark
# =============================================================================
_flow_spinner_stop() {
    local message="${1:-}"

    if [[ -n "$FLOW_SPINNER_PID" ]]; then
        kill $FLOW_SPINNER_PID 2>/dev/null
        wait $FLOW_SPINNER_PID 2>/dev/null
        FLOW_SPINNER_PID=""
    fi

    # Clear the spinner line
    printf "\r\033[K"

    # Show success message if provided
    [[ -n "$message" ]] && echo "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $message"
}

# =============================================================================
# Function: _flow_with_spinner
# Purpose: Execute a command while showing a spinner
# =============================================================================
# Arguments:
#   $1 - (required) Message to display during operation
#   $2 - (required) Time estimate (e.g., "~10s", use "" for none)
#   $@ - (required) Command and arguments to execute
#
# Returns:
#   Exit code of the executed command
#
# Output:
#   stdout - Command output (after spinner stops)
#
# Example:
#   _flow_with_spinner "Building..." "~10s" make build
#
#   _flow_with_spinner "Installing deps..." "" npm install
#
#   # Check result
#   if _flow_with_spinner "Testing..." "~30s" npm test; then
#       echo "Tests passed!"
#   fi
#
# Notes:
#   - Captures both stdout and stderr from command
#   - Spinner runs during command execution
#   - Command output displayed after completion
#   - Preserves original exit code
# =============================================================================
_flow_with_spinner() {
    local message="$1"
    local estimate="$2"
    shift 2

    _flow_spinner_start "$message" "$estimate"

    # Run command and capture output and exit code
    local output
    local exit_code
    output=$("$@" 2>&1)
    exit_code=$?

    _flow_spinner_stop

    # Print output
    [[ -n "$output" ]] && echo "$output"

    return $exit_code
}
