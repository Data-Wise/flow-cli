#!/usr/bin/env zsh
# Teaching workflow utility functions
# Part of Increment 2: Course Context

# =============================================================================
# Function: _calculate_current_week
# Purpose: Calculate current week number from semester start date
# =============================================================================
# Arguments:
#   $1 - (required) Path to course config file (YAML with semester_info.start_date)
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Week number (1-16), "0" if before start, or empty if unconfigured
#
# Example:
#   week=$(_calculate_current_week "course.yml")
#   echo "Current week: $week"
#
# Dependencies:
#   - yq (for YAML parsing)
#   - date (macOS compatible)
#
# Notes:
#   - Semester is 16 weeks standard
#   - Returns 0 for dates before semester start
#   - Returns 16 for dates after semester end (capped)
#   - Config format: semester_info.start_date: "YYYY-MM-DD"
# =============================================================================
_calculate_current_week() {
  local config_file="$1"

  # Read semester start date from config
  local start_date=$(yq -r '.semester_info.start_date // empty' "$config_file" 2>/dev/null)

  if [[ -z "$start_date" || "$start_date" == "null" ]]; then
    return 0
  fi

  # Calculate weeks since start (macOS date compatible)
  local start_epoch=$(date -j -f "%Y-%m-%d" "$start_date" "+%s" 2>/dev/null)
  local now_epoch=$(date "+%s")

  if [[ -z "$start_epoch" ]]; then
    return 0
  fi

  local days_diff=$(( (now_epoch - start_epoch) / 86400 ))
  local week=$(( (days_diff / 7) + 1 ))

  # Handle negative weeks (before semester start)
  if [[ $week -lt 1 ]]; then
    echo "0"
    return 0
  fi

  # Cap at 16 weeks (standard semester)
  if [[ $week -gt 16 ]]; then
    echo "16"
    return 0
  fi

  echo "$week"
}

# =============================================================================
# Function: _is_break_week
# Purpose: Check if a given week falls during a scheduled break
# =============================================================================
# Arguments:
#   $1 - (required) Path to course config file
#   $2 - (required) Week number to check
#
# Returns:
#   0 - Week is during a break (outputs break name)
#   1 - Week is not during a break (or no breaks configured)
#
# Output:
#   stdout - Break name if during a break (e.g., "Spring Break")
#
# Example:
#   if break_name=$(_is_break_week "course.yml" 9); then
#       echo "Week 9 is $break_name"
#   fi
#
# Dependencies:
#   - yq (for YAML parsing)
#   - _date_to_week (internal)
#
# Notes:
#   - Config format: semester_info.breaks[].{name, start, end}
#   - Dates in YYYY-MM-DD format
# =============================================================================
_is_break_week() {
  local config_file="$1"
  local week="$2"

  # Check if breaks section exists
  local breaks=$(yq -r '.semester_info.breaks // empty' "$config_file" 2>/dev/null)
  if [[ -z "$breaks" || "$breaks" == "null" ]]; then
    return 1  # No breaks defined
  fi

  # Check each break period
  local break_count=$(yq -r '.semester_info.breaks | length' "$config_file" 2>/dev/null)

  if [[ -z "$break_count" || "$break_count" == "null" || "$break_count" -eq 0 ]]; then
    return 1
  fi

  local i=0

  while [[ $i -lt $break_count ]]; do
    local break_name=$(yq -r ".semester_info.breaks[$i].name" "$config_file" 2>/dev/null)
    local break_start=$(yq -r ".semester_info.breaks[$i].start" "$config_file" 2>/dev/null)
    local break_end=$(yq -r ".semester_info.breaks[$i].end" "$config_file" 2>/dev/null)

    # Calculate week numbers for break period
    local start_week=$(_date_to_week "$config_file" "$break_start")
    local end_week=$(_date_to_week "$config_file" "$break_end")

    if [[ -n "$start_week" && -n "$end_week" ]]; then
      if [[ $week -ge $start_week && $week -le $end_week ]]; then
        echo "$break_name"
        return 0  # Week is during a break
      fi
    fi

    i=$((i + 1))
  done

  return 1  # Not a break week
}

# =============================================================================
# Function: _date_to_week
# Purpose: Convert a date to week number relative to semester start
# =============================================================================
# Arguments:
#   $1 - (required) Path to course config file
#   $2 - (required) Target date in YYYY-MM-DD format
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Week number (can be negative for dates before start)
#
# Example:
#   week=$(_date_to_week "course.yml" "2026-03-15")
#   echo "March 15 is week $week"
#
# Dependencies:
#   - yq (for YAML parsing)
#   - date (macOS compatible)
#
# Notes:
#   - Returns empty if date is invalid or config missing
#   - Week 1 starts on semester_info.start_date
# =============================================================================
_date_to_week() {
  local config_file="$1"
  local target_date="$2"

  if [[ -z "$target_date" || "$target_date" == "null" ]]; then
    return 0
  fi

  local start_date=$(yq -r '.semester_info.start_date' "$config_file" 2>/dev/null)

  if [[ -z "$start_date" || "$start_date" == "null" ]]; then
    return 0
  fi

  local start_epoch=$(date -j -f "%Y-%m-%d" "$start_date" "+%s" 2>/dev/null)
  local target_epoch=$(date -j -f "%Y-%m-%d" "$target_date" "+%s" 2>/dev/null)

  if [[ -z "$start_epoch" || -z "$target_epoch" ]]; then
    return 0
  fi

  local days_diff=$(( (target_epoch - start_epoch) / 86400 ))
  local week=$(( (days_diff / 7) + 1 ))

  echo "$week"
}

# =============================================================================
# Function: _validate_date_format
# Purpose: Validate that a string is a valid YYYY-MM-DD date
# =============================================================================
# Arguments:
#   $1 - (required) Date string to validate
#
# Returns:
#   0 - Valid date format and real date
#   1 - Invalid format or non-existent date
#
# Example:
#   if _validate_date_format "2026-02-30"; then
#       echo "Valid date"
#   else
#       echo "Invalid date"  # Feb 30 doesn't exist
#   fi
#
# Notes:
#   - Checks both format (YYYY-MM-DD) and validity (real date)
#   - Uses macOS-compatible date parsing
# =============================================================================
_validate_date_format() {
  local date_str="$1"

  # Check basic format with regex
  if [[ ! "$date_str" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    return 1
  fi

  # Verify it's a real date
  if ! date -j -f "%Y-%m-%d" "$date_str" "+%s" &>/dev/null; then
    return 1
  fi

  return 0
}

# =============================================================================
# Function: _calculate_semester_end
# Purpose: Calculate semester end date (16 weeks from start)
# =============================================================================
# Arguments:
#   $1 - (required) Semester start date in YYYY-MM-DD format
#
# Returns:
#   0 - Success
#   1 - Invalid start date
#
# Output:
#   stdout - End date in YYYY-MM-DD format
#
# Example:
#   end_date=$(_calculate_semester_end "2026-01-15")
#   echo "Semester ends: $end_date"  # → 2026-05-06
#
# Notes:
#   - Standard 16-week semester (112 days)
#   - macOS compatible date arithmetic
# =============================================================================
_calculate_semester_end() {
  local start_date="$1"

  local start_epoch=$(date -j -f "%Y-%m-%d" "$start_date" "+%s" 2>/dev/null)

  if [[ -z "$start_epoch" ]]; then
    return 1
  fi

  # Add 16 weeks (112 days)
  local end_epoch=$((start_epoch + (16 * 7 * 86400)))
  local end_date=$(date -j -f "%s" "$end_epoch" "+%Y-%m-%d" 2>/dev/null)

  echo "$end_date"
}

# =============================================================================
# Function: _suggest_semester_start
# Purpose: Suggest a reasonable semester start date based on current month
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always
#
# Output:
#   stdout - Suggested date in YYYY-MM-DD format
#
# Suggestions:
#   - Aug-Dec: Fall semester (Aug 20)
#   - Jan-May: Spring semester (Jan 15)
#   - Jun-Jul: Summer term (Jun 1)
#
# Example:
#   suggested=$(_suggest_semester_start)
#   echo "Suggested start: $suggested"
#
# Notes:
#   - January suggests previous year's fall semester
#   - Provides reasonable defaults for quick setup
# =============================================================================
_suggest_semester_start() {
  local current_month=$(date +%m)
  local current_year=$(date +%Y)

  # Fall semester (August-December)
  if [[ $current_month -ge 8 || $current_month -le 1 ]]; then
    # If Jan, suggest previous year's fall
    if [[ $current_month -le 1 ]]; then
      echo "$((current_year - 1))-08-20"
    else
      echo "${current_year}-08-20"
    fi
  # Spring semester (January-May)
  elif [[ $current_month -ge 1 && $current_month -le 5 ]]; then
    echo "${current_year}-01-15"
  # Summer (if needed)
  else
    echo "${current_year}-06-01"
  fi
}
