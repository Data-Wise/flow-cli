# lib/date-parser.zsh - Date Parsing and Manipulation for Teaching Workflows
# Part of flow-cli v5.11.0 teaching dates automation feature
#
# Provides functions to:
# - Extract dates from Quarto YAML frontmatter and Markdown content
# - Normalize date formats to ISO-8601 (YYYY-MM-DD)
# - Compute dates from week numbers with offsets
# - Find and compare dates across teaching files
# - Apply date changes to files

# ============================================================================
# CONSTANTS & CONFIGURATION
# ============================================================================

# Month abbreviation mapping
typeset -gA MONTH_ABBREV=(
  [Jan]=01 [January]=01
  [Feb]=02 [February]=02
  [Mar]=03 [March]=03
  [Apr]=04 [April]=04
  [May]=05 [May]=05
  [Jun]=06 [June]=06
  [Jul]=07 [July]=07
  [Aug]=08 [August]=08
  [Sep]=09 [September]=09
  [Oct]=10 [October]=10
  [Nov]=11 [November]=11
  [Dec]=12 [December]=12
)

# Regex patterns for date matching
typeset -g ISO_DATE_PATTERN='[0-9]{4}-[0-9]{2}-[0-9]{2}'
typeset -g US_DATE_PATTERN='[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}'
typeset -g ABBREV_DATE_PATTERN='(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [0-9]{1,2}'

# ============================================================================
# 1. YAML FRONTMATTER PARSING
# ============================================================================

# =============================================================================
# Function: _date_parse_quarto_yaml
# Purpose: Extract and normalize a date field from Quarto YAML frontmatter
# =============================================================================
# Arguments:
#   $1 - (required) Path to the Quarto/Markdown file with YAML frontmatter
#   $2 - (required) Name of the date field to extract (e.g., "due", "date")
#
# Returns:
#   0 - Success (date extracted and normalized, or field not found/dynamic)
#   1 - Error (file not found, missing field name, or yq unavailable)
#
# Output:
#   stdout - ISO-8601 date (YYYY-MM-DD) if field exists and is valid
#            Empty output if field not found, null, or dynamic value
#
# Example:
#   _date_parse_quarto_yaml "assignments/hw1.qmd" "due"
#   # Output: 2025-01-22
#
# Notes:
#   - Requires yq to be installed for YAML parsing
#   - Skips dynamic values: "last-modified", "today", "now"
#   - Normalizes extracted dates via _date_normalize()
#   - Quotes are stripped from extracted values
# =============================================================================
_date_parse_quarto_yaml() {
  local file="$1"
  local field="$2"

  # Validate inputs
  if [[ ! -f "$file" ]]; then
    return 1
  fi

  if [[ -z "$field" ]]; then
    return 1
  fi

  # Check if yq is available
  if ! command -v yq >/dev/null 2>&1; then
    echo "ERROR: yq required for YAML parsing" >&2
    return 1
  fi

  # Extract date value from YAML frontmatter
  local date_value
  date_value=$(yq eval ".${field} // \"\"" "$file" 2>/dev/null | tr -d '"')

  # Return empty if not found or null
  if [[ -z "$date_value" || "$date_value" == "null" ]]; then
    return 0
  fi

  # Skip dynamic values
  case "$date_value" in
    last-modified|today|now)
      return 0
      ;;
  esac

  # Normalize the extracted date
  _date_normalize "$date_value"
}

# ============================================================================
# 2. MARKDOWN INLINE DATE PARSING
# ============================================================================

# =============================================================================
# Function: _date_parse_markdown_inline
# Purpose: Find and extract all inline dates from markdown content
# =============================================================================
# Arguments:
#   $1 - (required) Path to the markdown file to search
#   $2 - (optional) Custom grep pattern to search for [default: month names + day]
#
# Returns:
#   0 - Success (file exists and was searched)
#   1 - Error (file not found)
#
# Output:
#   stdout - Newline-separated list of "line_number:ISO_date" pairs
#            Each line contains the line number and normalized date
#
# Example:
#   _date_parse_markdown_inline "syllabus.qmd"
#   # Output:
#   # 15:2025-01-22
#   # 42:2025-02-10
#
#   _date_parse_markdown_inline "schedule.md" "Feb"
#   # Output: Only lines matching "Feb" pattern
#
# Notes:
#   - Searches for both long-form (January) and abbreviated (Jan) month names
#   - Normalizes all found dates to ISO-8601 format
#   - Uses _date_extract_from_line helper for extraction
#   - Line numbers are 1-indexed (from grep -n)
# =============================================================================
_date_parse_markdown_inline() {
  local file="$1"
  local pattern="${2:-}" # Optional search pattern

  if [[ ! -f "$file" ]]; then
    return 1
  fi

  # Build grep pattern (search for common date formats)
  local grep_pattern
  if [[ -n "$pattern" ]]; then
    grep_pattern="$pattern"
  else
    # Default: search for both long-form and abbreviated month + day patterns
    grep_pattern='(January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) [0-9]{1,2}'
  fi

  # Extract lines with dates (with line numbers)
  local -a results=()
  while IFS=: read -r line_num line_content; do
    # Try to extract and normalize date from line
    local normalized_date
    normalized_date=$(_date_extract_from_line "$line_content" 2>/dev/null)
    local extract_status=$?
    if [[ $extract_status -eq 0 && -n "$normalized_date" ]]; then
      results+=("${line_num}:${normalized_date}")
    fi
  done < <(grep -nE "$grep_pattern" "$file" 2>/dev/null)

  # Return results (one per line)
  printf '%s\n' "${results[@]}"
}

# =============================================================================
# Function: _date_extract_from_line
# Purpose: Extract the first date from a single line of text
# =============================================================================
# Arguments:
#   $1 - (required) Text line to extract date from
#
# Returns:
#   0 - Success (date found and extracted)
#   1 - Error (no recognizable date format found)
#
# Output:
#   stdout - Normalized ISO-8601 date (YYYY-MM-DD)
#
# Example:
#   _date_extract_from_line "Due: January 22, 2025"
#   # Output: 2025-01-22
#
#   _date_extract_from_line "Assignment due 1/22/2025 at midnight"
#   # Output: 2025-01-22
#
# Notes:
#   - Tries formats in order: ISO, long month, abbreviated month, US format
#   - For month formats without year, infers current year
#   - Returns first match found (stops after first successful extraction)
#   - Uses ZSH regex matching with ${match[]} array
# =============================================================================
_date_extract_from_line() {
  local line="$1"

  # Try ISO date first
  if [[ "$line" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
    echo "${match[1]}"
    return 0
  fi

  # Try long-form or abbreviated month format: "January 22, 2025" or "Jan 22, 2025" or "Jan 22"
  if [[ "$line" =~ (January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[[:space:]]+([0-9]{1,2})(,[[:space:]]*([0-9]{4}))? ]]; then
    local month="${match[1]}"
    local day="${match[2]}"
    local year="${match[4]}"

    # Build date string and normalize
    if [[ -n "$year" ]]; then
      _date_normalize "$month $day, $year" 2>/dev/null
    else
      _date_normalize "$month $day" 2>/dev/null
    fi
    return 0
  fi

  # Try US date format: "1/22/2025"
  if [[ "$line" =~ ([0-9]{1,2})/([0-9]{1,2})/([0-9]{4}) ]]; then
    local month="${match[1]}"
    local day="${match[2]}"
    local year="${match[3]}"
    _date_normalize "$month/$day/$year" 2>/dev/null
    return 0
  fi

  return 1
}

# ============================================================================
# 3. DATE NORMALIZATION
# ============================================================================

# =============================================================================
# Function: _date_normalize
# Purpose: Convert any supported date format to ISO-8601 (YYYY-MM-DD)
# =============================================================================
# Arguments:
#   $1 - (required) Date string in any supported format
#
# Returns:
#   0 - Success (date normalized successfully)
#   1 - Error (empty input or unrecognized format)
#
# Output:
#   stdout - ISO-8601 formatted date (YYYY-MM-DD)
#
# Example:
#   _date_normalize "2025-01-22"        # Output: 2025-01-22
#   _date_normalize "1/22/2025"         # Output: 2025-01-22
#   _date_normalize "January 22, 2025"  # Output: 2025-01-22
#   _date_normalize "Jan 22, 2025"      # Output: 2025-01-22
#   _date_normalize "Jan 22"            # Output: 2025-01-22 (current year)
#
# Notes:
#   - Supported formats:
#     - ISO: "2025-01-22" (passes through)
#     - US: "M/D/YYYY" or "MM/DD/YYYY"
#     - Long: "January 22, 2025"
#     - Abbreviated: "Jan 22, 2025" or "Jan 22"
#   - Uses MONTH_ABBREV associative array for name-to-number conversion
#   - Pads month and day with leading zeros as needed
#   - Infers current year if year is missing from abbreviated format
# =============================================================================
_date_normalize() {
  local date_string="$1"

  # Empty input
  if [[ -z "$date_string" ]]; then
    return 1
  fi

  # Already ISO format - validate and return
  if [[ "$date_string" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})$ ]]; then
    echo "$date_string"
    return 0
  fi

  # US format: M/D/YYYY or MM/DD/YYYY
  if [[ "$date_string" =~ ^([0-9]{1,2})/([0-9]{1,2})/([0-9]{4})$ ]]; then
    local month="${match[1]}"
    local day="${match[2]}"
    local year="${match[3]}"

    # Pad month and day
    printf "%04d-%02d-%02d\n" "$year" "$month" "$day"
    return 0
  fi

  # Long/abbreviated month format: "January 22, 2025" or "Jan 22, 2025"
  if [[ "$date_string" =~ (January|February|March|April|May|June|July|August|September|October|November|December|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[[:space:]]+([0-9]{1,2})(,[[:space:]]*([0-9]{4}))? ]]; then
    local month_str="${match[1]}"
    local day="${match[2]}"
    local year="${match[4]}"

    # Convert month name to number
    local month_num="${MONTH_ABBREV[$month_str]}"
    if [[ -z "$month_num" ]]; then
      return 1
    fi

    # Infer year if missing (use current year from config or system)
    if [[ -z "$year" ]]; then
      year=$(date +%Y)
    fi

    printf "%04d-%02d-%02d\n" "$year" "$month_num" "$day"
    return 0
  fi

  # If we get here, format not recognized
  return 1
}

# ============================================================================
# 4. DATE COMPUTATION (Week + Offset)
# ============================================================================

# =============================================================================
# Function: _date_compute_from_week
# Purpose: Calculate a date from a semester week number plus day offset
# =============================================================================
# Arguments:
#   $1 - (required) Week number (1-16 typically for a semester)
#   $2 - (required) Offset days from week start (can be negative)
#   $3 - (optional) Path to config file [default: .flow/teach-config.yml]
#
# Returns:
#   0 - Success (date computed successfully)
#   1 - Error (invalid input, missing config, or week not found)
#
# Output:
#   stdout - ISO-8601 date (YYYY-MM-DD)
#   stderr - Error messages if validation fails
#
# Example:
#   _date_compute_from_week 2 2 ".flow/teach-config.yml"
#   # If week 2 starts 2025-01-20, output: 2025-01-22
#
#   _date_compute_from_week 5 -1
#   # One day before week 5 starts
#
# Notes:
#   - Config file must have semester_info.weeks[] array with number and start_date
#   - Uses yq to extract week start date from YAML config
#   - Delegates date arithmetic to _date_add_days()
#   - Supports both positive and negative day offsets
# =============================================================================
_date_compute_from_week() {
  local week_num="$1"
  local offset_days="$2"
  local config_file="${3:-.flow/teach-config.yml}"

  # Validate inputs
  if [[ ! "$week_num" =~ ^[0-9]+$ ]]; then
    echo "ERROR: Invalid week number: $week_num" >&2
    return 1
  fi

  if [[ ! "$offset_days" =~ ^-?[0-9]+$ ]]; then
    echo "ERROR: Invalid offset days: $offset_days" >&2
    return 1
  fi

  if [[ ! -f "$config_file" ]]; then
    echo "ERROR: Config file not found: $config_file" >&2
    return 1
  fi

  # Load week start date from config
  local week_start_date
  week_start_date=$(yq eval ".semester_info.weeks[] | select(.number == $week_num) | .start_date" "$config_file" 2>/dev/null)

  if [[ -z "$week_start_date" || "$week_start_date" == "null" ]]; then
    echo "ERROR: Week $week_num not found in config" >&2
    return 1
  fi

  # Add offset days to week start date
  _date_add_days "$week_start_date" "$offset_days"
}

# ============================================================================
# 5. DATE ARITHMETIC
# ============================================================================

# =============================================================================
# Function: _date_add_days
# Purpose: Add or subtract days from a date (cross-platform compatible)
# =============================================================================
# Arguments:
#   $1 - (required) Base date in ISO-8601 format (YYYY-MM-DD)
#   $2 - (required) Number of days to add (negative to subtract)
#
# Returns:
#   0 - Success (implicitly, via date command)
#   1 - Error (invalid date format)
#
# Output:
#   stdout - Resulting ISO-8601 date (YYYY-MM-DD)
#   stderr - Error message if base_date format is invalid
#
# Example:
#   _date_add_days "2025-01-20" 2    # Output: 2025-01-22
#   _date_add_days "2025-01-20" -5   # Output: 2025-01-15
#   _date_add_days "2025-01-31" 1    # Output: 2025-02-01 (month rollover)
#
# Notes:
#   - Detects and handles both GNU date (Linux) and BSD date (macOS)
#   - GNU date uses: date -d "$base_date + N days"
#   - BSD date uses: date -v+Nd or date -v-Nd for negative
#   - Handles month/year rollovers automatically
#   - Input must be strict ISO format (YYYY-MM-DD)
# =============================================================================
_date_add_days() {
  local base_date="$1"
  local days="$2"

  # Validate ISO date format
  if [[ ! "$base_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo "ERROR: Invalid date format: $base_date (expected YYYY-MM-DD)" >&2
    return 1
  fi

  # Check if GNU date or BSD date
  if date --version >/dev/null 2>&1; then
    # GNU date (Linux)
    date -d "$base_date + $days days" +%Y-%m-%d 2>/dev/null
  else
    # BSD date (macOS)
    if [[ "$days" -lt 0 ]]; then
      # Negative offset: subtract days
      local abs_days=$(( -days ))
      date -v-${abs_days}d -j -f "%Y-%m-%d" "$base_date" +%Y-%m-%d 2>/dev/null
    else
      # Positive offset: add days
      date -v+${days}d -j -f "%Y-%m-%d" "$base_date" +%Y-%m-%d 2>/dev/null
    fi
  fi
}

# ============================================================================
# 6. FILE DISCOVERY
# ============================================================================

# =============================================================================
# Function: _date_find_teaching_files
# Purpose: Find all teaching-related files that may contain date references
# =============================================================================
# Arguments:
#   $1 - (optional) Base path to search from [default: current directory]
#
# Returns:
#   0 - Always (even if no files found)
#
# Output:
#   stdout - Sorted, unique list of file paths (one per line)
#
# Example:
#   _date_find_teaching_files "/path/to/course"
#   # Output:
#   # /path/to/course/assignments/hw1.qmd
#   # /path/to/course/lectures/week01.qmd
#   # /path/to/course/syllabus.qmd
#
# Notes:
#   - Searches these directories (up to depth 2):
#     assignments/, lectures/, exams/, quizzes/, slides/, rubrics/, syllabus/
#   - Also checks root-level files: syllabus.qmd, schedule.qmd, index.qmd, README.md
#   - Only finds .qmd and .md files
#   - Results are sorted and deduplicated
#   - Non-existent directories are silently skipped
# =============================================================================
_date_find_teaching_files() {
  local base_path="${1:-.}"
  local -a files=()

  # Teaching directories to search
  local -a search_dirs=(
    assignments
    lectures
    exams
    quizzes
    slides
    rubrics
    syllabus
  )

  # Find files in teaching directories
  for dir in "${search_dirs[@]}"; do
    if [[ -d "$base_path/$dir" ]]; then
      while IFS= read -r file; do
        files+=("$file")
      done < <(find "$base_path/$dir" -maxdepth 2 \( -name "*.qmd" -o -name "*.md" \) -type f 2>/dev/null)
    fi
  done

  # Also check root for common files
  local -a root_files=(
    syllabus.qmd
    schedule.qmd
    index.qmd
    README.md
  )

  for file in "${root_files[@]}"; do
    if [[ -f "$base_path/$file" ]]; then
      files+=("$base_path/$file")
    fi
  done

  # Return unique, sorted file list
  printf '%s\n' "${files[@]}" | sort -u
}

# ============================================================================
# 7. CONFIG LOADING
# ============================================================================

# =============================================================================
# Function: _date_load_config
# Purpose: Load all dates from teach config into an associative array
# =============================================================================
# Arguments:
#   $1 - (optional) Path to config file [default: .flow/teach-config.yml]
#
# Returns:
#   0 - Success (config loaded and parsed)
#   1 - Error (config file not found or yq unavailable)
#
# Output:
#   stdout - Shell code to populate CONFIG_DATES associative array
#            Use with eval to set variables in caller's scope
#   stderr - Error messages if config or yq unavailable
#
# Example:
#   declare -A CONFIG_DATES
#   eval "$(_date_load_config)"
#   echo "${CONFIG_DATES[week_1]}"        # 2025-01-13
#   echo "${CONFIG_DATES[exam_midterm]}"  # 2025-03-05
#   echo "${CONFIG_DATES[deadline_hw1]}"  # 2025-01-22
#   echo "${CONFIG_DATES[holiday_spring_break]}"  # 2025-03-17
#
# Notes:
#   - Loads four categories of dates from config:
#     1. Week dates: CONFIG_DATES[week_N] (from semester_info.weeks[])
#     2. Exam dates: CONFIG_DATES[exam_NAME] (from semester_info.exams[])
#     3. Deadline dates: CONFIG_DATES[deadline_KEY] (from semester_info.deadlines)
#        - Supports both absolute dates and relative (week + offset) dates
#     4. Holiday dates: CONFIG_DATES[holiday_NAME] (from semester_info.holidays[])
#   - Keys are normalized: lowercase, spaces replaced with underscores
#   - Relative deadlines are computed via _date_compute_from_week()
#   - Requires yq for YAML parsing
# =============================================================================
_date_load_config() {
  local config_file="${1:-.flow/teach-config.yml}"

  if [[ ! -f "$config_file" ]]; then
    echo "# ERROR: Config file not found: $config_file" >&2
    return 1
  fi

  if ! command -v yq >/dev/null 2>&1; then
    echo "# ERROR: yq required. Install: brew install yq" >&2
    return 1
  fi

  # 1. Load week dates
  local week_count
  week_count=$(yq eval '.semester_info.weeks | length' "$config_file" 2>/dev/null)

  if [[ "$week_count" =~ ^[0-9]+$ ]] && (( week_count > 0 )); then
    for (( i=0; i<week_count; i++ )); do
      local week_num
      local week_date
      week_num=$(yq eval ".semester_info.weeks[$i].number" "$config_file" 2>/dev/null)
      week_date=$(yq eval ".semester_info.weeks[$i].start_date" "$config_file" 2>/dev/null)

      if [[ -n "$week_date" && "$week_date" != "null" ]]; then
        printf 'CONFIG_DATES[week_%s]="%s"\n' "$week_num" "$week_date"
      fi
    done
  fi

  # 2. Load exam dates
  local exam_count
  exam_count=$(yq eval '.semester_info.exams | length' "$config_file" 2>/dev/null)

  if [[ "$exam_count" =~ ^[0-9]+$ ]] && (( exam_count > 0 )); then
    for (( i=0; i<exam_count; i++ )); do
      local exam_name
      local exam_date
      exam_name=$(yq eval ".semester_info.exams[$i].name" "$config_file" 2>/dev/null)
      exam_date=$(yq eval ".semester_info.exams[$i].date" "$config_file" 2>/dev/null)

      if [[ -n "$exam_date" && "$exam_date" != "null" ]]; then
        # Normalize exam name to key (lowercase, spaces to underscores)
        local exam_key=$(echo "$exam_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
        printf 'CONFIG_DATES[exam_%s]="%s"\n' "$exam_key" "$exam_date"
      fi
    done
  fi

  # 3. Load deadlines (can be absolute or relative)
  local deadline_keys
  deadline_keys=$(yq eval '.semester_info.deadlines | keys | .[]' "$config_file" 2>/dev/null)

  while IFS= read -r deadline_key; do
    [[ -z "$deadline_key" ]] && continue

    # Check if absolute date
    local due_date
    due_date=$(yq eval ".semester_info.deadlines.${deadline_key}.due_date // \"\"" "$config_file" 2>/dev/null)

    if [[ -n "$due_date" && "$due_date" != "null" && "$due_date" != '""' ]]; then
      # Absolute date
      printf 'CONFIG_DATES[deadline_%s]="%s"\n' "$deadline_key" "$due_date"
    else
      # Relative date - compute it
      local week
      local offset
      week=$(yq eval ".semester_info.deadlines.${deadline_key}.week // \"\"" "$config_file" 2>/dev/null)
      offset=$(yq eval ".semester_info.deadlines.${deadline_key}.offset_days // \"\"" "$config_file" 2>/dev/null)

      if [[ -n "$week" && "$week" != "null" && -n "$offset" && "$offset" != "null" ]]; then
        local computed_date
        computed_date=$(_date_compute_from_week "$week" "$offset" "$config_file" 2>/dev/null)
        if [[ -n "$computed_date" ]]; then
          printf 'CONFIG_DATES[deadline_%s]="%s"\n' "$deadline_key" "$computed_date"
        fi
      fi
    fi
  done <<< "$deadline_keys"

  # 4. Load holiday dates
  local holiday_count
  holiday_count=$(yq eval '.semester_info.holidays | length' "$config_file" 2>/dev/null)

  if [[ "$holiday_count" =~ ^[0-9]+$ ]] && (( holiday_count > 0 )); then
    for (( i=0; i<holiday_count; i++ )); do
      local holiday_name
      local holiday_date
      holiday_name=$(yq eval ".semester_info.holidays[$i].name" "$config_file" 2>/dev/null)
      holiday_date=$(yq eval ".semester_info.holidays[$i].date" "$config_file" 2>/dev/null)

      if [[ -n "$holiday_date" && "$holiday_date" != "null" ]]; then
        local holiday_key=$(echo "$holiday_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
        printf 'CONFIG_DATES[holiday_%s]="%s"\n' "$holiday_key" "$holiday_date"
      fi
    done
  fi
}

# ============================================================================
# 8. DATE COMPARISON
# ============================================================================

# =============================================================================
# Function: _date_compare
# Purpose: Compare dates extracted from a file against config reference dates
# =============================================================================
# Arguments:
#   $1 - (required) Path to the file being compared (for context)
#   $2 - (required) Name of associative array containing file dates (by ref)
#   $3 - (required) Name of associative array containing config dates (by ref)
#
# Returns:
#   0 - Always returns success
#
# Output:
#   stdout - Mismatch records, one per line
#            Format: "field:file_date:config_date:source"
#
# Example:
#   typeset -A file_dates config_dates
#   file_dates[due]="2025-01-20"
#   config_dates[due]="2025-01-22"
#   _date_compare "hw1.qmd" file_dates config_dates
#   # Output: due:2025-01-20:2025-01-22:config
#
# Notes:
#   - Uses ZSH nameref (local -n) to pass arrays by reference
#   - Only reports mismatches (matching dates are skipped)
#   - Only compares keys that exist in both arrays
#   - The "source" field is always "config" (indicates reference source)
#   - Caller must populate both arrays before calling
# =============================================================================
_date_compare() {
  local file="$1"
  shift
  local -n file_dates_ref="$1"  # Pass array by reference
  shift
  local -n config_dates_ref="$1"

  local -a mismatches=()

  # Compare each file date against config
  for key in "${(@k)file_dates_ref}"; do
    local file_date="${file_dates_ref[$key]}"
    local config_date="${config_dates_ref[$key]}"

    if [[ -n "$config_date" && "$file_date" != "$config_date" ]]; then
      # Mismatch found
      mismatches+=("${key}:${file_date}:${config_date}:config")
    fi
  done

  # Return mismatches
  printf '%s\n' "${mismatches[@]}"
}

# ============================================================================
# 9. FILE MODIFICATION
# ============================================================================

# =============================================================================
# Function: _date_apply_to_file
# Purpose: Apply date replacements to a file (YAML frontmatter and inline)
# =============================================================================
# Arguments:
#   $1 - (required) Path to the file to modify
#   $@ - (required) Array of change specifications after shift
#        Format: "field:old_date:new_date"
#
# Returns:
#   0 - Success (at least one modification made)
#   1 - Error (file not found, backup failed, or no changes applied)
#
# Output:
#   stdout - Success message via _flow_log_success (if available)
#   stderr - Error messages if file/backup issues
#
# Example:
#   changes=("due:2025-01-20:2025-01-22" "posted:2025-01-15:2025-01-17")
#   _date_apply_to_file "hw1.qmd" "${changes[@]}"
#
# Notes:
#   - Creates backup file (.bak) before modification
#   - Updates YAML frontmatter fields via yq
#   - Updates inline date occurrences via sed
#   - Handles multiple date formats (ISO, US, long-form)
#   - Converts between formats when replacing (ISO to US, ISO to long)
#   - Removes backup on success, restores on failure
#   - Uses MONTH_ABBREV array for month name lookups
#   - Temporary files (.tmp) are cleaned up after use
# =============================================================================
_date_apply_to_file() {
  local file="$1"
  shift
  local -a changes=("$@")

  if [[ ! -f "$file" ]]; then
    echo "ERROR: File not found: $file" >&2
    return 1
  fi

  # Create backup
  cp "$file" "${file}.bak" || {
    echo "ERROR: Failed to create backup: ${file}.bak" >&2
    return 1
  }

  local modified=false

  for change in "${changes[@]}"; do
    local field="${change%%:*}"
    local rest="${change#*:}"
    local old_date="${rest%%:*}"
    local new_date="${rest#*:}"

    # Update YAML frontmatter field
    if yq eval ".$field" "$file" >/dev/null 2>&1; then
      yq eval ".$field = \"$new_date\"" -i "$file" 2>/dev/null && {
        modified=true
      }
    fi

    # Update inline occurrences (be careful with sed)
    # Only replace exact date matches to avoid partial replacements
    if grep -qF "$old_date" "$file" 2>/dev/null; then
      # Use different delimiters to avoid conflicts
      sed -i.tmp "s|$old_date|$new_date|g" "$file" 2>/dev/null && {
        modified=true
      }
      rm -f "${file}.tmp"
    fi

    # Also try to replace long-form date if old_date is ISO
    if [[ "$old_date" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})$ ]]; then
      local year="${match[1]}"
      local month="${match[2]}"
      local day="${match[3]}"

      # Convert to long-form month names and replace those too
      local month_name="${(k)MONTH_ABBREV[(r)$month]}"
      local month_abbrev="${(k)MONTH_ABBREV[(r)$month]}"

      # Try to find a long-form month name (not abbreviated)
      for key val in "${(@kv)MONTH_ABBREV}"; do
        if [[ "$val" == "$month" && ${#key} -gt 3 ]]; then
          month_name="$key"
          break
        fi
      done

      # Generate possible date formats to replace
      local -a old_formats=(
        "${month#0}/${day#0}/$year"           # US format: 1/20/2025
        "$month_name ${day#0}, $year"         # Long: January 20, 2025
      )

      # Generate new date formats
      local new_month_name
      for key val in "${(@kv)MONTH_ABBREV}"; do
        if [[ "$val" == "${new_date[6,7]}" && ${#key} -gt 3 ]]; then
          new_month_name="$key"
          break
        fi
      done

      local new_year="${new_date[1,4]}"
      local new_month="${new_date[6,7]}"
      local new_day="${new_date[9,10]}"

      # Replace each old format with corresponding new format
      # US format
      local old_us="${month#0}/${day#0}/$year"
      local new_us="${new_month#0}/${new_day#0}/$new_year"
      if grep -qF "$old_us" "$file" 2>/dev/null; then
        sed -i.tmp "s|$old_us|$new_us|g" "$file" 2>/dev/null
        rm -f "${file}.tmp"
        modified=true
      fi

      # Long format
      if [[ -n "$month_name" && -n "$new_month_name" ]]; then
        local old_long="$month_name ${day#0}, $year"
        local new_long="$new_month_name ${new_day#0}, $new_year"
        if grep -qF "$old_long" "$file" 2>/dev/null; then
          sed -i.tmp "s|$old_long|$new_long|g" "$file" 2>/dev/null
          rm -f "${file}.tmp"
          modified=true
        fi
      fi
    fi
  done

  if $modified; then
    # Success - log if function available
    if typeset -f _flow_log_success >/dev/null 2>&1; then
      _flow_log_success "Updated dates in: $file"
    fi
    rm -f "${file}.bak"  # Remove backup on success
    return 0
  else
    # No changes - restore from backup
    mv "${file}.bak" "$file" 2>/dev/null
    return 1
  fi
}

# ============================================================================
# MODULE INITIALIZATION
# ============================================================================

# Mark module as loaded
typeset -g _FLOW_DATE_PARSER_LOADED=1
