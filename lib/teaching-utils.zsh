#!/usr/bin/env zsh
# Teaching workflow utility functions
# Part of Increment 2: Course Context

# Calculate current week number from semester start
# Returns: Week number (1-16), 0 if before start, or empty if no date configured
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

# Check if week is during a scheduled break
# Returns: 0 and break name if yes, 1 if no
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

# Convert date to week number relative to semester start
# Returns: Week number or empty if invalid
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

# Validate date format (YYYY-MM-DD)
# Returns: 0 if valid, 1 if invalid
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

# Calculate semester end date (16 weeks from start)
# Returns: End date in YYYY-MM-DD format
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

# Suggest semester start date based on current month
# Returns: Suggested date in YYYY-MM-DD format
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
