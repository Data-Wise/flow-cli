#!/bin/zsh
# ============================================================================
# Scribe CLI - Terminal-based note access for Scribe app
# ============================================================================
# Location: ~/.config/zsh/functions/scribe.zsh
# Source:   source ~/.config/zsh/functions/scribe.zsh
# Man page: ~/.local/share/man/man1/scribe.1
#
# Commands:
#   scribe new "Title"           Create a new note
#   scribe daily                 Open/create today's daily note
#   scribe search "query"        Search notes (FTS5)
#   scribe capture "idea"        Quick capture to inbox
#   scribe list [--project NAME] List recent notes
#   scribe open "Title"          Open note in Scribe app
#   scribe edit "Title"          Edit note in $EDITOR
#   scribe tags                  List all tags
#   scribe help                  Show help
# ============================================================================

# Version
SCRIBE_CLI_VERSION="1.1.0"

# Database location
SCRIBE_DB="${HOME}/Library/Application Support/com.scribe.app/scribe.db"

# Colors for output
typeset -A _scribe_colors
_scribe_colors=(
  reset    $'\e[0m'
  bold     $'\e[1m'
  dim      $'\e[2m'
  green    $'\e[32m'
  yellow   $'\e[33m'
  blue     $'\e[34m'
  magenta  $'\e[35m'
  cyan     $'\e[36m'
  red      $'\e[31m'
)

# ============================================================================
# Helper Functions
# ============================================================================

_scribe_check_db() {
  if [[ ! -f "$SCRIBE_DB" ]]; then
    echo "scribe: database not found at $SCRIBE_DB" >&2
    echo "Run Scribe app at least once to create the database." >&2
    return 1
  fi
  return 0
}

_scribe_query() {
  sqlite3 -separator '|' "$SCRIBE_DB" "$1" 2>/dev/null
}

_scribe_exec() {
  sqlite3 "$SCRIBE_DB" "$1" 2>/dev/null
}

# Generate 32-character hex ID (matching Scribe's format)
_scribe_generate_id() {
  # Use OpenSSL for cryptographic random bytes, convert to hex
  openssl rand -hex 16
}

# Escape single quotes for SQL
_scribe_escape() {
  echo "${1//\'/\'\'}"
}

# Format timestamp for display
_scribe_format_time() {
  local ts="$1"
  date -r "$ts" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "Unknown"
}

# ============================================================================
# Core Commands
# ============================================================================

# Create a new note
_scribe_new() {
  _scribe_check_db || return 1

  local title="${*:-Untitled}"
  local escaped_title=$(_scribe_escape "$title")
  local id=$(_scribe_generate_id)
  local now=$(date +%s)

  _scribe_exec "INSERT INTO notes (id, title, content, folder, created_at, updated_at)
                VALUES ('$id', '$escaped_title', '', 'inbox', $now, $now)"

  if [[ $? -eq 0 ]]; then
    echo "${_scribe_colors[green]}Created:${_scribe_colors[reset]} $title"
    echo "${_scribe_colors[dim]}ID: $id${_scribe_colors[reset]}"
    echo "${_scribe_colors[dim]}Folder: inbox${_scribe_colors[reset]}"
  else
    echo "${_scribe_colors[red]}Error: Failed to create note${_scribe_colors[reset]}"
    return 1
  fi
}

# Create/open today's daily note
_scribe_daily() {
  _scribe_check_db || return 1

  local today=$(date "+%Y-%m-%d")
  local title="Daily: $today"
  local escaped_title=$(_scribe_escape "$title")

  # Check if daily note exists
  local existing=$(_scribe_query "SELECT id FROM notes WHERE title = '$escaped_title' AND deleted_at IS NULL LIMIT 1")

  if [[ -n "$existing" ]]; then
    echo "${_scribe_colors[cyan]}Opening today's daily note...${_scribe_colors[reset]}"
    _scribe_open_by_id "$existing"
  else
    # Create new daily note with template
    local id=$(_scribe_generate_id)
    local now=$(date +%s)
    local weekday=$(date "+%A")

    # Simple daily template (BlockNote JSON format - just paragraphs)
    local template="# Daily: $today ($weekday)

## Focus for Today


## Notes


## End of Day Review

"
    local escaped_template=$(_scribe_escape "$template")

    _scribe_exec "INSERT INTO notes (id, title, content, folder, created_at, updated_at)
                  VALUES ('$id', '$escaped_title', '$escaped_template', 'daily', $now, $now)"

    if [[ $? -eq 0 ]]; then
      echo "${_scribe_colors[green]}Created daily note:${_scribe_colors[reset]} $title"
      _scribe_open_by_id "$id"
    else
      echo "${_scribe_colors[red]}Error: Failed to create daily note${_scribe_colors[reset]}"
      return 1
    fi
  fi
}

# Search notes using FTS5
_scribe_search() {
  _scribe_check_db || return 1

  if [[ -z "$*" ]]; then
    echo "${_scribe_colors[yellow]}Usage: scribe search \"query\"${_scribe_colors[reset]}"
    return 1
  fi

  local query="$*"
  local escaped_query=$(_scribe_escape "$query")

  echo "${_scribe_colors[cyan]}Searching for:${_scribe_colors[reset]} $query"
  echo ""

  # Search using FTS5
  local results=$(_scribe_query "
    SELECT n.id, n.title, n.folder, n.updated_at,
           snippet(notes_fts, 2, '>>>', '<<<', '...', 32) as snippet
    FROM notes_fts f
    JOIN notes n ON f.note_id = n.id
    WHERE notes_fts MATCH '$escaped_query'
      AND n.deleted_at IS NULL
    ORDER BY rank
    LIMIT 20
  ")

  if [[ -z "$results" ]]; then
    echo "${_scribe_colors[dim]}No results found${_scribe_colors[reset]}"
    return 0
  fi

  local count=0
  echo "$results" | while IFS='|' read -r id title folder updated snippet; do
    ((count++))
    local time_str=$(_scribe_format_time "$updated")

    echo "${_scribe_colors[bold]}$count. $title${_scribe_colors[reset]}"
    echo "   ${_scribe_colors[dim]}[$folder] • $time_str${_scribe_colors[reset]}"
    if [[ -n "$snippet" ]]; then
      # Highlight matches
      local highlighted="${snippet//>>>/\\e[33m}"
      highlighted="${highlighted//<<</\\e[0m}"
      echo "   $highlighted"
    fi
    echo ""
  done
}

# Quick capture to inbox
_scribe_capture() {
  _scribe_check_db || return 1

  local content="$*"

  # If no content provided, read from stdin or prompt
  if [[ -z "$content" ]]; then
    if [[ -t 0 ]]; then
      echo "${_scribe_colors[cyan]}Enter your thought (Ctrl+D to finish):${_scribe_colors[reset]}"
      content=$(cat)
    else
      content=$(cat)
    fi
  fi

  if [[ -z "$content" ]]; then
    echo "${_scribe_colors[yellow]}No content to capture${_scribe_colors[reset]}"
    return 1
  fi

  # Generate title from first line or timestamp
  local title
  local first_line=$(echo "$content" | head -1 | cut -c1-50)
  if [[ -n "$first_line" ]]; then
    title="Capture: $first_line"
    [[ ${#first_line} -eq 50 ]] && title="${title}..."
  else
    title="Capture: $(date '+%Y-%m-%d %H:%M')"
  fi

  local escaped_title=$(_scribe_escape "$title")
  local escaped_content=$(_scribe_escape "$content")
  local id=$(_scribe_generate_id)
  local now=$(date +%s)

  _scribe_exec "INSERT INTO notes (id, title, content, folder, created_at, updated_at)
                VALUES ('$id', '$escaped_title', '$escaped_content', 'inbox', $now, $now)"

  if [[ $? -eq 0 ]]; then
    echo "${_scribe_colors[green]}Captured!${_scribe_colors[reset]} $title"
    echo "${_scribe_colors[dim]}ID: $id${_scribe_colors[reset]}"
  else
    echo "${_scribe_colors[red]}Error: Failed to capture${_scribe_colors[reset]}"
    return 1
  fi
}

# List recent notes
_scribe_list() {
  _scribe_check_db || return 1

  local folder=""
  local limit=20

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project|--folder|-f)
        folder="$2"
        shift 2
        ;;
      --limit|-l)
        limit="$2"
        shift 2
        ;;
      *)
        folder="$1"
        shift
        ;;
    esac
  done

  local where_clause="WHERE deleted_at IS NULL"
  if [[ -n "$folder" ]]; then
    local escaped_folder=$(_scribe_escape "$folder")
    where_clause="$where_clause AND folder = '$escaped_folder'"
    echo "${_scribe_colors[cyan]}Notes in '$folder':${_scribe_colors[reset]}"
  else
    echo "${_scribe_colors[cyan]}Recent notes:${_scribe_colors[reset]}"
  fi
  echo ""

  local results=$(_scribe_query "
    SELECT id, title, folder, updated_at, length(content) as size
    FROM notes
    $where_clause
    ORDER BY updated_at DESC
    LIMIT $limit
  ")

  if [[ -z "$results" ]]; then
    echo "${_scribe_colors[dim]}No notes found${_scribe_colors[reset]}"
    return 0
  fi

  # Print as formatted table
  printf "${_scribe_colors[bold]}%-40s %-12s %-16s %s${_scribe_colors[reset]}\n" "Title" "Folder" "Updated" "Size"
  printf "%s\n" "$(printf '─%.0s' {1..80})"

  echo "$results" | while IFS='|' read -r id title folder updated size; do
    local time_str=$(_scribe_format_time "$updated")
    local truncated_title="${title:0:38}"
    [[ ${#title} -gt 38 ]] && truncated_title="${truncated_title}.."

    # Color code by folder
    local folder_color="${_scribe_colors[dim]}"
    case "$folder" in
      inbox)   folder_color="${_scribe_colors[yellow]}" ;;
      daily)   folder_color="${_scribe_colors[green]}" ;;
      archive) folder_color="${_scribe_colors[dim]}" ;;
      *)       folder_color="${_scribe_colors[blue]}" ;;
    esac

    printf "%-40s ${folder_color}%-12s${_scribe_colors[reset]} %-16s %s\n" \
           "$truncated_title" "$folder" "$time_str" "${size}b"
  done
}

# Open note in Scribe app
_scribe_open() {
  _scribe_check_db || return 1

  if [[ -z "$*" ]]; then
    # No argument - just open Scribe
    echo "${_scribe_colors[cyan]}Opening Scribe...${_scribe_colors[reset]}"
    osascript -e 'tell application "Scribe" to activate' 2>/dev/null
    return 0
  fi

  local title="$*"
  local escaped_title=$(_scribe_escape "$title")

  # Search for note by title (exact or partial match)
  local result=$(_scribe_query "
    SELECT id, title FROM notes
    WHERE deleted_at IS NULL
      AND (title = '$escaped_title' OR title LIKE '%$escaped_title%')
    ORDER BY
      CASE WHEN title = '$escaped_title' THEN 0 ELSE 1 END,
      updated_at DESC
    LIMIT 1
  ")

  if [[ -z "$result" ]]; then
    echo "${_scribe_colors[yellow]}Note not found:${_scribe_colors[reset]} $title"
    echo ""
    echo "Create it? [y/N] "
    read -q "REPLY?"
    echo ""
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
      _scribe_new "$title"
    fi
    return 1
  fi

  local id=$(echo "$result" | cut -d'|' -f1)
  local found_title=$(echo "$result" | cut -d'|' -f2)

  echo "${_scribe_colors[cyan]}Opening:${_scribe_colors[reset]} $found_title"
  _scribe_open_by_id "$id"
}

# Internal: Open note by ID
_scribe_open_by_id() {
  local id="$1"

  # Use custom URL scheme if Scribe supports it, otherwise just activate
  # For now, activate Scribe app (it should restore last state)
  osascript -e '
    tell application "Scribe"
      activate
    end tell
  ' 2>/dev/null

  # Alternative: If Scribe has a URL scheme like scribe://note/ID
  # open "scribe://note/$id" 2>/dev/null

  echo "${_scribe_colors[dim]}Note ID: $id${_scribe_colors[reset]}"
}

# Edit note content in terminal editor
_scribe_edit() {
  _scribe_check_db || return 1

  if [[ -z "$*" ]]; then
    echo "${_scribe_colors[yellow]}Usage: scribe edit \"Title\"${_scribe_colors[reset]}"
    return 1
  fi

  local title="$*"
  local escaped_title=$(_scribe_escape "$title")

  # Find the note
  local result=$(_scribe_query "
    SELECT id, title, content FROM notes
    WHERE deleted_at IS NULL
      AND (title = '$escaped_title' OR title LIKE '%$escaped_title%')
    ORDER BY
      CASE WHEN title = '$escaped_title' THEN 0 ELSE 1 END,
      updated_at DESC
    LIMIT 1
  ")

  if [[ -z "$result" ]]; then
    echo "${_scribe_colors[yellow]}Note not found:${_scribe_colors[reset]} $title"
    return 1
  fi

  local id=$(echo "$result" | cut -d'|' -f1)
  local found_title=$(echo "$result" | cut -d'|' -f2)

  # Create temp file with content
  local tmpfile=$(mktemp /tmp/scribe-edit-XXXXXX.md)
  _scribe_query "SELECT content FROM notes WHERE id = '$id'" > "$tmpfile"

  # Get modification time before edit
  local before_mtime=$(stat -f %m "$tmpfile")

  # Open in editor
  ${EDITOR:-vim} "$tmpfile"

  # Check if file was modified
  local after_mtime=$(stat -f %m "$tmpfile")

  if [[ "$before_mtime" != "$after_mtime" ]]; then
    local new_content=$(cat "$tmpfile")
    local escaped_content=$(_scribe_escape "$new_content")
    local now=$(date +%s)

    _scribe_exec "UPDATE notes SET content = '$escaped_content', updated_at = $now WHERE id = '$id'"

    if [[ $? -eq 0 ]]; then
      echo "${_scribe_colors[green]}Updated:${_scribe_colors[reset]} $found_title"
    else
      echo "${_scribe_colors[red]}Error: Failed to save changes${_scribe_colors[reset]}"
    fi
  else
    echo "${_scribe_colors[dim]}No changes made${_scribe_colors[reset]}"
  fi

  rm -f "$tmpfile"
}

# List all tags
_scribe_tags() {
  _scribe_check_db || return 1

  echo "${_scribe_colors[cyan]}Tags:${_scribe_colors[reset]}"
  echo ""

  local results=$(_scribe_query "
    SELECT t.name, t.color, COUNT(nt.note_id) as count
    FROM tags t
    LEFT JOIN note_tags nt ON t.id = nt.tag_id
    GROUP BY t.id
    ORDER BY count DESC, t.name
  ")

  if [[ -z "$results" ]]; then
    echo "${_scribe_colors[dim]}No tags found${_scribe_colors[reset]}"
    return 0
  fi

  echo "$results" | while IFS='|' read -r name color count; do
    printf "  ${_scribe_colors[magenta]}#%-20s${_scribe_colors[reset]} (%d notes)\n" "$name" "$count"
  done
}

# List folders
_scribe_folders() {
  _scribe_check_db || return 1

  echo "${_scribe_colors[cyan]}Folders:${_scribe_colors[reset]}"
  echo ""

  local results=$(_scribe_query "
    SELECT folder, COUNT(*) as count
    FROM notes
    WHERE deleted_at IS NULL
    GROUP BY folder
    ORDER BY count DESC
  ")

  if [[ -z "$results" ]]; then
    echo "${_scribe_colors[dim]}No folders found${_scribe_colors[reset]}"
    return 0
  fi

  echo "$results" | while IFS='|' read -r folder count; do
    local icon="📁"
    case "$folder" in
      inbox)   icon="📥" ;;
      daily)   icon="📅" ;;
      archive) icon="📦" ;;
    esac
    printf "  $icon ${_scribe_colors[blue]}%-20s${_scribe_colors[reset]} (%d notes)\n" "$folder" "$count"
  done
}

# Show statistics
_scribe_stats() {
  _scribe_check_db || return 1

  echo "${_scribe_colors[cyan]}Scribe Statistics${_scribe_colors[reset]}"
  echo ""

  local total=$(_scribe_query "SELECT COUNT(*) FROM notes WHERE deleted_at IS NULL")
  local today=$(date +%s)
  local week_ago=$((today - 604800))
  local this_week=$(_scribe_query "SELECT COUNT(*) FROM notes WHERE deleted_at IS NULL AND created_at > $week_ago")
  local total_words=$(_scribe_query "SELECT SUM(length(content) - length(replace(content, ' ', '')) + 1) FROM notes WHERE deleted_at IS NULL AND content != ''")
  local folders=$(_scribe_query "SELECT COUNT(DISTINCT folder) FROM notes WHERE deleted_at IS NULL")
  local tags=$(_scribe_query "SELECT COUNT(*) FROM tags")

  printf "  ${_scribe_colors[bold]}Total Notes:${_scribe_colors[reset]}    %s\n" "$total"
  printf "  ${_scribe_colors[bold]}Created This Week:${_scribe_colors[reset]} %s\n" "$this_week"
  printf "  ${_scribe_colors[bold]}~Total Words:${_scribe_colors[reset]}   %s\n" "${total_words:-0}"
  printf "  ${_scribe_colors[bold]}Folders:${_scribe_colors[reset]}        %s\n" "$folders"
  printf "  ${_scribe_colors[bold]}Tags:${_scribe_colors[reset]}           %s\n" "$tags"
}

# Show help
_scribe_help() {
  local topic="${1:-}"

  # Handle --all for extended help
  local show_all=false
  [[ "$topic" == "--all" || "$topic" == "-a" ]] && show_all=true

  # Colors (with fallback)
  local _C_BOLD=$'\e[1m'
  local _C_NC=$'\e[0m'
  local _C_GREEN=$'\e[0;32m'
  local _C_CYAN=$'\e[0;36m'
  local _C_BLUE=$'\e[0;34m'
  local _C_YELLOW=$'\e[0;33m'
  local _C_DIM=$'\e[2m'
  local _C_MAGENTA=$'\e[0;35m'

  # Disable colors if NO_COLOR or not a terminal
  if [[ -n "$NO_COLOR" ]] || [[ ! -t 1 ]]; then
    _C_BOLD="" _C_NC="" _C_GREEN="" _C_CYAN="" _C_BLUE="" _C_YELLOW="" _C_DIM="" _C_MAGENTA=""
  fi

  echo -e "
${_C_BOLD}╭─────────────────────────────────────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ 📝 SCRIBE CLI v${SCRIBE_CLI_VERSION} - Terminal-based note access                        │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────────────────────────────────────╯${_C_NC}

${_C_BOLD}Usage:${_C_NC} scribe <command> [arguments]

${_C_GREEN}🔥 QUICK START${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}daily${_C_NC}, ${_C_CYAN}d${_C_NC}              Open/create today's daily note
  ${_C_CYAN}capture${_C_NC}, ${_C_CYAN}c${_C_NC} <text>     Quick capture to inbox
  ${_C_CYAN}search${_C_NC}, ${_C_CYAN}s${_C_NC} <query>     Full-text search (FTS5)
  ${_C_CYAN}list${_C_NC}, ${_C_CYAN}ls${_C_NC} [folder]     List recent notes

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} scribe daily                  ${_C_DIM}# Open today's note${_C_NC}
  ${_C_DIM}\$${_C_NC} scribe c \"Buy milk\"           ${_C_DIM}# Quick capture${_C_NC}
  ${_C_DIM}\$${_C_NC} scribe s \"ADHD focus\"         ${_C_DIM}# Search notes${_C_NC}
  ${_C_DIM}\$${_C_NC} echo \"idea\" | scribe c        ${_C_DIM}# Pipe to capture${_C_NC}
  ${_C_DIM}\$${_C_NC} scribe list inbox             ${_C_DIM}# Show inbox notes${_C_NC}"

  if [[ "$show_all" == "true" ]]; then
    echo -e "
${_C_BLUE}📋 NOTE MANAGEMENT${_C_NC}:
  ${_C_CYAN}new${_C_NC} <title>           Create a new note in inbox
  ${_C_CYAN}daily${_C_NC}, ${_C_CYAN}d${_C_NC}              Open/create today's daily note
  ${_C_CYAN}capture${_C_NC}, ${_C_CYAN}c${_C_NC} [text]     Quick capture thought to inbox
  ${_C_CYAN}open${_C_NC}, ${_C_CYAN}o${_C_NC} [title]       Open note in Scribe app
  ${_C_CYAN}edit${_C_NC}, ${_C_CYAN}e${_C_NC} <title>       Edit note in \$EDITOR

${_C_BLUE}🔍 SEARCH & BROWSE${_C_NC}:
  ${_C_CYAN}search${_C_NC}, ${_C_CYAN}s${_C_NC} <query>     Full-text search (FTS5)
  ${_C_CYAN}list${_C_NC}, ${_C_CYAN}ls${_C_NC} [folder]     List recent notes
  ${_C_CYAN}tags${_C_NC}, ${_C_CYAN}t${_C_NC}               List all tags with note counts
  ${_C_CYAN}folders${_C_NC}, ${_C_CYAN}f${_C_NC}            List all folders with note counts
  ${_C_CYAN}stats${_C_NC}                 Show database statistics

${_C_BLUE}⚙️  OPTIONS${_C_NC}:
  ${_C_CYAN}--project${_C_NC}, ${_C_CYAN}-f${_C_NC} <name>  Filter list by folder
  ${_C_CYAN}--limit${_C_NC}, ${_C_CYAN}-l${_C_NC} <n>       Limit results (default: 20)

${_C_MAGENTA}🚀 WORKFLOWS${_C_NC}:
  ${_C_DIM}\$${_C_NC} pbpaste | scribe c           ${_C_DIM}# Capture from clipboard${_C_NC}
  ${_C_DIM}\$${_C_NC} scribe s \"TODO\" | head       ${_C_DIM}# Quick grep through notes${_C_NC}
  ${_C_DIM}\$${_C_NC} scribe list | fzf            ${_C_DIM}# Interactive note picker${_C_NC}

${_C_MAGENTA}📁 SHELL ALIASES${_C_NC}:
  ${_C_DIM}sd${_C_NC} = scribe daily      ${_C_DIM}sc${_C_NC} = scribe capture
  ${_C_DIM}ss${_C_NC} = scribe search     ${_C_DIM}sl${_C_NC} = scribe list
  ${_C_DIM}sn${_C_NC} = scribe new

${_C_DIM}Database: ~/Library/Application Support/com.scribe.app/scribe.db${_C_NC}
${_C_DIM}Man page: man scribe${_C_NC}"
  else
    echo -e "
${_C_DIM}More commands: scribe help --all${_C_NC}"
  fi
  echo ""
}

# ============================================================================
# Main Entry Point
# ============================================================================

scribe() {
  case "${1:-help}" in
    new)      shift; _scribe_new "$@" ;;
    daily|d)  _scribe_daily ;;
    search|s) shift; _scribe_search "$@" ;;
    capture|c) shift; _scribe_capture "$@" ;;
    list|ls|l) shift; _scribe_list "$@" ;;
    open|o)   shift; _scribe_open "$@" ;;
    edit|e)   shift; _scribe_edit "$@" ;;
    tags|t)   _scribe_tags ;;
    folders|f) _scribe_folders ;;
    stats)    _scribe_stats ;;
    version|-v|--version)
      echo "scribe-cli v${SCRIBE_CLI_VERSION}"
      ;;
    help) shift; _scribe_help "$@" ;;
    -h|--help) _scribe_help ;;
    *)
      echo "scribe: unknown command '$1'" >&2
      echo "Run 'scribe help' for usage." >&2
      return 1
      ;;
  esac
}

# Aliases for quick access
alias sd='scribe daily'
alias sc='scribe capture'
alias ss='scribe search'
alias sl='scribe list'
alias sn='scribe new'

# Completion function
_scribe_completion() {
  local commands=(new daily search capture list open edit tags folders stats help)
  local folders=(inbox daily archive)

  if [[ ${#words[@]} -eq 2 ]]; then
    _describe 'command' commands
  elif [[ ${#words[@]} -eq 3 && ${words[2]} == "list" ]]; then
    _describe 'folder' folders
  fi
}

compdef _scribe_completion scribe 2>/dev/null

# Add local man pages to MANPATH
export MANPATH="$HOME/.local/share/man:$MANPATH"
