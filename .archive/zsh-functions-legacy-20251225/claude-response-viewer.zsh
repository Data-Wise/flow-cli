# ============================================
# CLAUDE RESPONSE VIEWER
# ============================================
# Save Claude responses and view with glow in split window
# Created: 2025-12-16

# ============================================
# CONFIGURATION
# ============================================

CLAUDE_RESPONSES_DIR="$HOME/.claude/responses"
CLAUDE_CURRENT_RESPONSE="$CLAUDE_RESPONSES_DIR/current.md"

# Create responses directory if it doesn't exist
mkdir -p "$CLAUDE_RESPONSES_DIR"

# ============================================
# MAIN FUNCTIONS
# ============================================

# Save and view response (with viewing mode options)
glowsplit() {
    local input_file="${1:-}"
    local title="${2:-Response}"
    local view_mode="${3:-split}"  # split, tab, window, or none

    # Determine input source
    if [[ -n "$input_file" ]] && [[ -f "$input_file" ]]; then
        # File provided as argument
        cp "$input_file" "$CLAUDE_CURRENT_RESPONSE"
    elif [[ -p /dev/stdin ]]; then
        # Piped input
        cat > "$CLAUDE_CURRENT_RESPONSE"
    else
        # No input - show help
        _glowsplit_help
        return 1
    fi

    # Add metadata
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local response_file="$CLAUDE_RESPONSES_DIR/response-$(date "+%Y%m%d-%H%M%S").md"

    # Save with header
    {
        echo "# $title"
        echo ""
        echo "**Saved:** $timestamp"
        echo "**Location:** $(pwd)"
        echo ""
        echo "---"
        echo ""
        cat "$CLAUDE_CURRENT_RESPONSE"
    } > "$response_file"

    # Create symlink to latest
    ln -sf "$response_file" "$CLAUDE_CURRENT_RESPONSE"

    echo "✅ Saved to: $response_file"

    # Open with glow based on mode
    case "$view_mode" in
        split)
            _open_in_split "$response_file" "$title"
            ;;
        tab)
            _open_in_tab "$response_file" "$title"
            ;;
        window)
            _open_in_window "$response_file" "$title"
            ;;
        default|system)
            _open_with_default "$response_file"
            ;;
        none)
            echo "📄 File saved (not opening viewer)"
            ;;
        *)
            echo "⚠️  Unknown view mode: $view_mode (use: split, tab, window, default, none)"
            ;;
    esac
}

# Open file in iTerm2 split with glow
_open_in_split() {
    local file="$1"
    local title="${2:-Glow}"

    # Check if we're in iTerm2
    if [[ "$TERM_PROGRAM" != "iTerm.app" ]]; then
        echo "⚠️  Not in iTerm2, opening in current terminal"
        glow "$file"
        return
    fi

    # Use iTerm2 Python API to create split
    # First try: Use osascript (AppleScript)
    osascript <<EOF 2>/dev/null
tell application "iTerm"
    tell current session of current window
        -- Split horizontally (side by side)
        set newSession to (split horizontally with default profile)
        tell newSession
            write text "glow '$file'"
        end tell
    end tell
end tell
EOF

    if [[ $? -eq 0 ]]; then
        echo "✅ Opened in split window"
    else
        # Fallback: Use tmux if available
        if command -v tmux >/dev/null && [[ -n "$TMUX" ]]; then
            tmux split-window -h "glow '$file'"
            echo "✅ Opened in tmux split"
        else
            # Last resort: Just open in current terminal
            echo "⚠️  Could not create split, opening here"
            glow "$file"
        fi
    fi
}

# Open file in iTerm2 new tab with glow
_open_in_tab() {
    local file="$1"
    local title="${2:-Glow}"

    # Check if we're in iTerm2
    if [[ "$TERM_PROGRAM" != "iTerm.app" ]]; then
        echo "⚠️  Not in iTerm2, opening in current terminal"
        glow "$file"
        return
    fi

    # Use AppleScript to create new tab
    osascript <<EOF 2>/dev/null
tell application "iTerm"
    tell current window
        create tab with default profile
        tell current session
            write text "glow '$file'"
        end tell
    end tell
end tell
EOF

    if [[ $? -eq 0 ]]; then
        echo "✅ Opened in new tab"
    else
        # Fallback: Just open in current terminal
        echo "⚠️  Could not create tab, opening here"
        glow "$file"
    fi
}

# Open file in new iTerm2 window with glow
_open_in_window() {
    local file="$1"
    local title="${2:-Glow}"

    # Check if we're in iTerm2
    if [[ "$TERM_PROGRAM" != "iTerm.app" ]]; then
        echo "⚠️  Not in iTerm2, opening in current terminal"
        glow "$file"
        return
    fi

    # Use AppleScript to create new window
    osascript <<EOF 2>/dev/null
tell application "iTerm"
    create window with default profile
    tell current session of current window
        write text "glow '$file'"
    end tell
end tell
EOF

    if [[ $? -eq 0 ]]; then
        echo "✅ Opened in new window"
    else
        # Fallback: Just open in current terminal
        echo "⚠️  Could not create window, opening here"
        glow "$file"
    fi
}

# Open file with system default app
_open_with_default() {
    local file="$1"

    if command -v open >/dev/null; then
        open "$file"
        echo "✅ Opened with default app"
    elif command -v xdg-open >/dev/null; then
        xdg-open "$file"
        echo "✅ Opened with default app"
    else
        echo "⚠️  No system open command available, opening with glow"
        glow "$file"
    fi
}

# Quick save from clipboard
glowclip() {
    local title="${1:-Response}"
    local view_mode="${2:-split}"  # split, tab, window, default, none

    if command -v pbpaste >/dev/null; then
        pbpaste | glowsplit - "$title" "$view_mode"
    else
        echo "❌ pbpaste not available"
        return 1
    fi
}

# View last saved response
glowlast() {
    local view_mode="${1:-split}"  # split, tab, window, default

    if [[ -f "$CLAUDE_CURRENT_RESPONSE" ]]; then
        case "$view_mode" in
            split)
                _open_in_split "$CLAUDE_CURRENT_RESPONSE" "Last Response"
                ;;
            tab)
                _open_in_tab "$CLAUDE_CURRENT_RESPONSE" "Last Response"
                ;;
            window)
                _open_in_window "$CLAUDE_CURRENT_RESPONSE" "Last Response"
                ;;
            default|system)
                _open_with_default "$CLAUDE_CURRENT_RESPONSE"
                ;;
            *)
                echo "⚠️  Unknown view mode: $view_mode (use: split, tab, window, default)"
                ;;
        esac
    else
        echo "❌ No saved response found"
        return 1
    fi
}

# List all saved responses
glowlist() {
    echo "📚 Saved Claude Responses:"
    echo ""

    if [[ ! -d "$CLAUDE_RESPONSES_DIR" ]] || [[ -z "$(ls -A "$CLAUDE_RESPONSES_DIR" 2>/dev/null)" ]]; then
        echo "No saved responses yet"
        return
    fi

    # List responses with metadata
    local count=1
    for file in "$CLAUDE_RESPONSES_DIR"/response-*.md; do
        if [[ -f "$file" ]]; then
            local filename=$(basename "$file")
            local date=$(echo "$filename" | sed 's/response-//;s/-.*//')
            local time=$(echo "$filename" | sed 's/.*-//;s/\.md//')
            local title=$(grep "^# " "$file" | head -1 | sed 's/^# //')
            local size=$(du -h "$file" | cut -f1)

            echo "$count) [$date $time] $title ($size)"
            echo "   $file"
            echo ""
            ((count++))
        fi
    done
}

# Open specific response by number
glowopen() {
    local num="${1:-}"
    local view_mode="${2:-split}"  # split, tab, window, default

    if [[ -z "$num" ]]; then
        glowlist
        return
    fi

    # Get file by number
    local files=("$CLAUDE_RESPONSES_DIR"/response-*.md)
    local file="${files[$num-1]}"

    if [[ -f "$file" ]]; then
        case "$view_mode" in
            split)
                _open_in_split "$file" "Response $num"
                ;;
            tab)
                _open_in_tab "$file" "Response $num"
                ;;
            window)
                _open_in_window "$file" "Response $num"
                ;;
            default|system)
                _open_with_default "$file"
                ;;
            *)
                echo "⚠️  Unknown view mode: $view_mode (use: split, tab, window, default)"
                ;;
        esac
    else
        echo "❌ Response $num not found"
        glowlist
        return 1
    fi
}

# Clean old responses (keep last N)
glowclean() {
    local keep="${1:-10}"

    echo "🗑️  Keeping last $keep responses, deleting older ones..."

    # Get all response files sorted by date (newest first)
    local files=("$CLAUDE_RESPONSES_DIR"/response-*.md)
    local count=${#files[@]}

    if [[ $count -le $keep ]]; then
        echo "✅ Only $count responses found, nothing to delete"
        return
    fi

    local to_delete=$((count - keep))
    echo "Deleting $to_delete old responses..."

    # Delete oldest files
    local deleted=0
    for ((i=keep; i<count; i++)); do
        rm "${files[$i]}"
        ((deleted++))
    done

    echo "✅ Deleted $deleted responses"
}

# Help
_glowsplit_help() {
    cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║        📖 Claude Response Viewer with Glow                 ║
╚════════════════════════════════════════════════════════════╝

USAGE:
  glowsplit <file> ["Title"] [mode]   Save file and open with viewer
  glowsplit - "Title" [mode]          Save from stdin and open
  cat file | glowsplit - "Title" [mode]  Pipe content to save and view

  glowclip "Title" [mode]    Save from clipboard and open
  glowlast [mode]            View last saved response
  glowlist                   List all saved responses
  glowopen <number> [mode]   Open specific response by number
  glowclean [keep]           Delete old responses (default: keep last 10)

VIEWING MODES:
  split    - Open in iTerm2 split (horizontal) [DEFAULT]
  tab      - Open in new iTerm2 tab
  window   - Open in new iTerm2 window
  default  - Open with system default app (Marked 2, Typora, etc.)
  none     - Just save, don't open viewer

EXAMPLES:
  # Save from clipboard and open in split (default)
  glowclip "Brainstorm Results"

  # Save and open in new tab
  glowclip "Analysis" tab

  # Save and open with system default app
  glowclip "Notes" default

  # Pipe response to new window
  cat response.md | glowsplit - "Analysis" window

  # View last response in default app
  glowlast default

  # List and open response #3 in new tab
  glowlist
  glowopen 3 tab

TIPS:
  - Responses saved to: ~/.claude/responses/
  - split/tab/window modes work in iTerm2 (falls back gracefully)
  - default mode uses whatever app opens .md files
  - All responses timestamped and organized

INTEGRATION WITH PROMPT MODES:
  After using [brainstorm], [analyze], or [debug]:
  1. Copy Claude's response (Cmd+C)
  2. Run: glowclip "Brainstorm: Pick Command" tab
  3. Response opens in beautiful new tab!

KEYBOARD SHORTCUT (Optional):
  Bind Ctrl+G to quick-save last response:
  Add to .zshrc: bindkey '^G' _glowsplit_widget

EOF
}

# Alias for help - REMOVED 2025-12-19: glowsplit shows help automatically
# alias glowhelp='_glowsplit_help'

# ============================================
# KEYBOARD SHORTCUT INTEGRATION (Optional)
# ============================================

# Bind Ctrl+G to save last response
# Add to .zshrc: bindkey '^G' _glowsplit_widget
_glowsplit_widget() {
    BUFFER="glowclip"
    zle accept-line
}
zle -N _glowsplit_widget

# ============================================
# AUTO-SAVE INTEGRATION (Optional)
# ============================================

# Auto-save responses when using certain commands
# Uncomment to enable
# alias claude='claude "$@" | tee >(glowsplit - "Claude Response")'
