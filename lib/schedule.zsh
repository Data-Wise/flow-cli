# lib/schedule.zsh - Forward-looking schedule engine for flow-cli
#
# Shared engine powering the `agenda` command, the dash UPCOMING section, and
# the dated enrichment of morning/today/week. Aggregates forward-looking dated
# activity from two greenfield sources:
#
#   1. `.STATUS` `## Schedule:` blocks (per project) — ZSH-parseable, no yq.
#   2. `.flow/teach-config.yml` teaching dates (per teaching project) — via
#      _date_load_config (lib/date-parser.zsh); guarded by yq + file existence.
#
# Records are normalized to a pipe-delimited stream so every surface renders
# identically:
#
#     date|label|type|project|recurrence|source
#
#   date        ISO YYYY-MM-DD (concrete; recurring tokens are expanded)
#   label       human text (must not contain `|`)
#   type        teaching|research|general|recurring|holiday
#   project     inferred from ${status_file:h:t}
#   recurrence  `none` or `weekly:<dow>`
#   source      status|teach-config
#
# Pure ZSH. Works fully without atlas and without yq (the teaching path is the
# only one that needs yq; the research/general path needs none). Atlas is an
# opportunistic, capability-detected sync target.
#
# Reuses (read-only): _date_load_config / _date_add_days (lib/date-parser.zsh);
# _flow_has_atlas / _flow_atlas_async / _flow_list_projects (lib/atlas-bridge.zsh);
# _dash_find_project_path / _dash_detect_category (commands/dash.zsh);
# FLOW_COLORS (lib/core.zsh).

# Module guard
[[ -n "$_FLOW_SCHEDULE_LOADED" ]] && return
typeset -g _FLOW_SCHEDULE_LOADED=1

zmodload zsh/datetime 2>/dev/null

# ============================================================================
# CONSTANTS
# ============================================================================

# Default look-ahead window (days) for agenda / dash / cadence.
typeset -g SCHEDULE_DEFAULT_WINDOW=7

# Session cache (date+window+category keyed, ~600s TTL) shared across surfaces.
typeset -g SCHEDULE_CACHE_TTL=600
typeset -g _SCHEDULE_CACHE_RECORDS=""
typeset -g _SCHEDULE_CACHE_KEY=""
typeset -g _SCHEDULE_CACHE_TIME=0

# Atlas `schedule` subcommand capability probe (cached per session).
typeset -g _FLOW_ATLAS_HAS_SCHEDULE=""

# ============================================================================
# DATE HELPERS
# ============================================================================

# Today as ISO YYYY-MM-DD (ZSH-native).
_schedule_today() {
  strftime '%Y-%m-%d' $EPOCHSECONDS
}

# =============================================================================
# Function: _schedule_classify
# Purpose: Classify an ISO date relative to today + a window
# Arguments:
#   $1 - ISO date (YYYY-MM-DD)
#   $2 - window in days [default: SCHEDULE_DEFAULT_WINDOW]
# Output:
#   stdout - overdue|today|soon|later
# Notes:
#   - Pure string comparison (ISO dates sort lexically) + _date_add_days.
#   - "soon" = strictly future but within the window; "later" = beyond it.
# =============================================================================
_schedule_classify() {
  local iso="$1"
  local window="${2:-$SCHEDULE_DEFAULT_WINDOW}"
  [[ -z "$iso" ]] && return 1

  local today=$(_schedule_today)

  if [[ "$iso" < "$today" ]]; then
    echo "overdue"
  elif [[ "$iso" == "$today" ]]; then
    echo "today"
  else
    local window_end=$(_date_add_days "$today" "$window")
    if [[ -n "$window_end" && "$iso" > "$window_end" ]]; then
      echo "later"
    else
      echo "soon"
    fi
  fi
}

# =============================================================================
# Function: _schedule_relative_days
# Purpose: Human relative-day label for an ISO date
# Output:
#   stdout - "today" | "in Nd" | "overdue Nd"
# Notes:
#   - Parses at local noon (strftime -r) to avoid DST off-by-one.
# =============================================================================
_schedule_relative_days() {
  local iso="$1"
  [[ -z "$iso" ]] && return 1

  local today=$(_schedule_today)
  local e t
  e=$(strftime -r '%Y-%m-%d %H:%M:%S' "$iso 12:00:00" 2>/dev/null) || return 1
  t=$(strftime -r '%Y-%m-%d %H:%M:%S' "$today 12:00:00" 2>/dev/null) || return 1

  local diff=$(( (e - t) / 86400 ))
  if (( diff == 0 )); then
    echo "today"
  elif (( diff > 0 )); then
    echo "in ${diff}d"
  else
    echo "overdue $(( -diff ))d"
  fi
}

# =============================================================================
# Function: _schedule_type_icon
# Purpose: Map a record type to its display icon
# =============================================================================
_schedule_type_icon() {
  case "$1" in
    teaching)  echo "🎓" ;;
    research)  echo "🔬" ;;
    recurring) echo "🔁" ;;
    holiday)   echo "🏖️" ;;
    general|*) echo "📌" ;;
  esac
}

# ============================================================================
# PARSING — .STATUS `## Schedule:` section (no external commands)
# ============================================================================

# =============================================================================
# Function: _schedule_parse_status
# Purpose: Extract schedule records from a `.STATUS` `## Schedule:` block
# Arguments:
#   $1 - path to a .STATUS file
# Output:
#   stdout - records (date|label|type|project|recurrence|source)
#            ISO entries carry a concrete date; `weekly:<dow>` entries carry an
#            empty date field + recurrence token (expanded later by collect).
# Grammar (one list item per line):
#   - <when> | <label> [| <type>]
#     when  = YYYY-MM-DD | weekly:<dow>
#     type  = teaching|research|general|recurring (optional)
# Notes:
#   - `project` inferred from ${status_file:h:t}. Unknown tokens skipped, not
#     fatal. Empty / malformed lines ignored.
# =============================================================================
_schedule_parse_status() {
  local status_file="$1"
  [[ -f "$status_file" ]] || return 0

  local project="${status_file:h:t}"
  local in_section=0 line

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Enter the Schedule block
    if [[ "$line" == "## Schedule:"* ]]; then
      in_section=1
      continue
    fi
    # Any other `## ` heading ends the block
    if (( in_section )) && [[ "$line" == "## "* ]]; then
      in_section=0
      continue
    fi
    (( in_section )) || continue

    # Only list items ("- ...")
    [[ "$line" == "-"* ]] || continue
    local body="${line#-}"
    body="${body#"${body%%[![:space:]]*}"}"   # trim leading whitespace
    [[ -z "$body" ]] && continue

    # Split on `|`
    local -a parts
    parts=("${(@s:|:)body}")
    local when="${parts[1]}" label="${parts[2]}" typ="${parts[3]}"

    when="${when//[[:space:]]/}"                                   # strip ws
    label="${label#"${label%%[![:space:]]*}"}"                    # ltrim
    label="${label%"${label##*[![:space:]]}"}"                    # rtrim
    typ="${typ//[[:space:]]/}"; typ="${typ:l}"

    [[ -z "$when" || -z "$label" ]] && continue

    if [[ "$when" == [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9] ]]; then
      [[ -z "$typ" ]] && typ="general"
      echo "${when}|${label}|${typ}|${project}|none|status"
    elif [[ "$when" == weekly:* ]]; then
      local dow="${when#weekly:}"
      [[ -z "$dow" ]] && continue
      [[ -z "$typ" ]] && typ="recurring"
      echo "|${label}|${typ}|${project}|weekly:${dow}|status"
    fi
    # unknown `when` tokens are silently skipped
  done < "$status_file"
}

# ============================================================================
# PARSING — teaching config (.flow/teach-config.yml via date-parser)
# ============================================================================

# =============================================================================
# Function: _schedule_teach_items
# Purpose: Derive schedule records from a teaching config's dated entries
# Arguments:
#   $1 - path to .flow/teach-config.yml
#   $2 - project name
#   $3 - window in days (unused for filtering here; kept for symmetry)
# Output:
#   stdout - records (date|label|type|project|none|teach-config)
# Notes:
#   - Reuses _date_load_config -> CONFIG_DATES (week_N / exam_* / deadline_* /
#     holiday_*). Holidays typed `holiday` (callers filter unless --all).
#   - Guarded by `command -v yq` + file existence; no-op (return 0) otherwise.
#   - Uses `local -A CONFIG_DATES` per the date-parser contract.
# =============================================================================
_schedule_teach_items() {
  local config="$1" project="$2"
  [[ -f "$config" ]] || return 0
  command -v yq >/dev/null 2>&1 || return 0

  local -A CONFIG_DATES
  eval "$(_date_load_config "$config" 2>/dev/null)"

  local key val typ label
  for key val in "${(@kv)CONFIG_DATES}"; do
    [[ -z "$val" || "$val" == "null" ]] && continue
    case "$key" in
      week_*)
        label="Week ${key#week_}"
        typ="teaching"
        ;;
      exam_*)
        label="Exam: ${${key#exam_}//_/ }"
        typ="teaching"
        ;;
      deadline_*)
        label="Due: ${${key#deadline_}//_/ }"
        typ="teaching"
        ;;
      holiday_*)
        label="Holiday: ${${key#holiday_}//_/ }"
        typ="holiday"
        ;;
      *)
        continue
        ;;
    esac
    echo "${val}|${label}|${typ}|${project}|none|teach-config"
  done
}

# ============================================================================
# RECURRENCE EXPANSION
# ============================================================================

# =============================================================================
# Function: _schedule_expand_recurring
# Purpose: Expand a `weekly:<dow>` token into concrete in-range ISO dates
# Arguments:
#   $1 - recurrence token (e.g. weekly:fri)
#   $2 - start ISO date (inclusive)
#   $3 - end ISO date (inclusive)
# Output:
#   stdout - one ISO date per occurrence (may cross month/year boundaries)
# Notes:
#   - Jumps to the first matching weekday then strides +7 days (few iterations).
#   - Uses strftime '%u' (1=Mon..7=Sun) + _date_add_days for cross-platform math.
# =============================================================================
_schedule_expand_recurring() {
  local token="$1" start="$2" end="$3"
  local dow="${token#weekly:}"

  local -A dowmap=(
    mon 1 tue 2 wed 3 thu 4 fri 5 sat 6 sun 7
    monday 1 tuesday 2 wednesday 3 thursday 4 friday 5 saturday 6 sunday 7
  )
  local target="${dowmap[${dow:l}]}"
  [[ -z "$target" || -z "$start" || -z "$end" ]] && return 0

  local start_epoch
  start_epoch=$(strftime -r '%Y-%m-%d %H:%M:%S' "$start 12:00:00" 2>/dev/null) || return 0
  local start_dow=$(strftime '%u' "$start_epoch")
  local delta=$(( (target - start_dow + 7) % 7 ))

  local cur=$(_date_add_days "$start" "$delta")
  local guard=0
  while [[ -n "$cur" ]] && { [[ "$cur" < "$end" ]] || [[ "$cur" == "$end" ]]; }; do
    echo "$cur"
    cur=$(_date_add_days "$cur" 7)
    (( ++guard >= 60 )) && break
  done
}

# ============================================================================
# COLLECTION + PIPELINE
# ============================================================================

# =============================================================================
# Function: _schedule_collect
# Purpose: Aggregate concrete-dated records across all projects
# Arguments:
#   $1 - window in days [default: SCHEDULE_DEFAULT_WINDOW]
#   $2 - category filter (dev|r|research|teach|quarto|apps) [optional]
# Output:
#   stdout - record stream (recurring tokens expanded to concrete dates)
# Notes:
#   - Session cache keyed on today|window|category (TTL SCHEDULE_CACHE_TTL).
#     Set FLOW_SCHEDULE_NO_CACHE=1 to bypass (tests).
#   - Recurrence expansion window is capped at 90 days to keep output sane.
# =============================================================================
_schedule_collect() {
  local window="${1:-$SCHEDULE_DEFAULT_WINDOW}"
  local category="${2:-}"

  local today=$(_schedule_today)
  local cache_key="${today}|${window}|${category}"

  if [[ -z "$FLOW_SCHEDULE_NO_CACHE" ]] \
     && [[ "$_SCHEDULE_CACHE_KEY" == "$cache_key" ]] \
     && (( EPOCHSECONDS - _SCHEDULE_CACHE_TIME < SCHEDULE_CACHE_TTL )); then
    [[ -n "$_SCHEDULE_CACHE_RECORDS" ]] && print -r -- "$_SCHEDULE_CACHE_RECORDS"
    return 0
  fi

  # recurrence expansion range (cap to keep output bounded for wide windows)
  local rwin=$window
  (( rwin > 90 )) && rwin=90
  local rend=$(_date_add_days "$today" "$rwin")

  local -a out=()
  local project proj_path cat rec

  while IFS= read -r project; do
    [[ -z "$project" ]] && continue
    proj_path=$(_dash_find_project_path "$project") || continue
    [[ -z "$proj_path" ]] && continue

    if [[ -n "$category" ]]; then
      cat=$(_dash_detect_category "$proj_path")
      [[ "$cat" != "$category" ]] && continue
    fi

    # 1. .STATUS schedule block
    if [[ -f "$proj_path/.STATUS" ]]; then
      while IFS= read -r rec; do
        [[ -z "$rec" ]] && continue
        if [[ "$rec" == "|"* ]]; then
          # recurring: empty date field -> expand
          local -a rf=("${(@s:|:)rec}")
          local recurrence="${rf[5]}"
          local tail="${rec#|}"   # label|type|project|recurrence|source
          local d
          for d in ${(f)"$(_schedule_expand_recurring "$recurrence" "$today" "$rend")"}; do
            out+=("${d}|${tail}")
          done
        else
          out+=("$rec")
        fi
      done < <(_schedule_parse_status "$proj_path/.STATUS")
    fi

    # 2. teaching config
    if [[ -f "$proj_path/.flow/teach-config.yml" ]]; then
      while IFS= read -r rec; do
        [[ -z "$rec" ]] && continue
        out+=("$rec")
      done < <(_schedule_teach_items "$proj_path/.flow/teach-config.yml" "$project")
    fi
  done < <(_flow_list_projects)

  local records=""
  (( ${#out[@]} > 0 )) && records=$(print -rl -- "${out[@]}")

  _SCHEDULE_CACHE_RECORDS="$records"
  _SCHEDULE_CACHE_KEY="$cache_key"
  _SCHEDULE_CACHE_TIME=$EPOCHSECONDS

  [[ -n "$records" ]] && print -r -- "$records"
  return 0
}

# =============================================================================
# Function: _schedule_filter_window
# Purpose: Keep records within the window (always keep overdue); drop `later`
# Arguments:
#   $1 - window in days [default: SCHEDULE_DEFAULT_WINDOW]
# Input:  stdin  - record stream
# Output: stdout - filtered record stream
# Notes:
#   - Holidays are passed through here; callers drop them unless `--all`.
# =============================================================================
_schedule_filter_window() {
  local window="${1:-$SCHEDULE_DEFAULT_WINDOW}"
  local rec date class
  while IFS= read -r rec; do
    [[ -z "$rec" ]] && continue
    date="${rec%%|*}"
    [[ -z "$date" ]] && continue
    class=$(_schedule_classify "$date" "$window")
    [[ "$class" == "later" ]] && continue
    print -r -- "$rec"
  done
}

# =============================================================================
# Function: _schedule_sort
# Purpose: Sort a record stream by date ascending (overdue first)
# Input:  stdin  - record stream
# Output: stdout - sorted record stream
# =============================================================================
_schedule_sort() {
  sort -t'|' -k1,1
}

# =============================================================================
# Function: _schedule_render_line
# Purpose: Render a single record (type icon + urgency color + relative day)
# Arguments:
#   $1 - record (date|label|type|project|recurrence|source)
# =============================================================================
_schedule_render_line() {
  local rec="$1"
  [[ -z "$rec" ]] && return 0

  local -a f=("${(@s:|:)rec}")
  local date="${f[1]}" label="${f[2]}" typ="${f[3]}" project="${f[4]}" recurrence="${f[5]}"

  local class=$(_schedule_classify "$date" "$SCHEDULE_DEFAULT_WINDOW")
  local rel=$(_schedule_relative_days "$date")

  local color="${FLOW_COLORS[muted]}"
  case "$class" in
    overdue) color="${FLOW_COLORS[error]}" ;;
    today)   color="${FLOW_COLORS[warning]}" ;;
    soon)    color="${FLOW_COLORS[info]}" ;;
    later)   color="${FLOW_COLORS[muted]}" ;;
  esac

  local ticon=$(_schedule_type_icon "$typ")
  # Trailing 🔁 flags recurrence for non-recurring TYPES (e.g. a research
  # weekly block); skip it when the type icon is already 🔁 to avoid doubling.
  local rmark=""
  [[ -n "$recurrence" && "$recurrence" != "none" && "$typ" != "recurring" ]] && rmark=" 🔁"

  printf "  %s ${color}%-11s${FLOW_COLORS[reset]} %s%s ${FLOW_COLORS[muted]}(%s)${FLOW_COLORS[reset]}\n" \
    "$ticon" "$rel" "$label" "$rmark" "$project"
}

# ============================================================================
# ATLAS (opportunistic, capability-detected)
# ============================================================================

# =============================================================================
# Function: _flow_schedule_to_atlas
# Purpose: Opportunistically push records to atlas (async, no-op if absent)
# Arguments:
#   $@ - records (date|label|type|project|recurrence|source)
# Notes:
#   - Silent no-op when atlas is absent OR lacks a `schedule` subcommand.
#   - Capability is probed once and cached in _FLOW_ATLAS_HAS_SCHEDULE.
#   - See docs/ATLAS-CONTRACT.md for the proposed `atlas schedule push` contract.
# =============================================================================
_flow_schedule_to_atlas() {
  _flow_has_atlas || return 0

  if [[ -z "$_FLOW_ATLAS_HAS_SCHEDULE" ]]; then
    if atlas schedule --help >/dev/null 2>&1; then
      _FLOW_ATLAS_HAS_SCHEDULE="yes"
    else
      _FLOW_ATLAS_HAS_SCHEDULE="no"
    fi
  fi
  [[ "$_FLOW_ATLAS_HAS_SCHEDULE" == "yes" ]] || return 0

  local -a records=("$@")
  (( ${#records[@]} == 0 )) && return 0

  local json="[" first=1 rec
  for rec in "${records[@]}"; do
    [[ -z "$rec" ]] && continue
    local -a f=("${(@s:|:)rec}")
    (( first )) || json+=","
    first=0
    json+=$(printf '{"date":"%s","label":"%s","type":"%s","project":"%s","recurrence":"%s","source":"%s"}' \
      "${f[1]}" "${f[2]}" "${f[3]}" "${f[4]}" "${f[5]}" "${f[6]}")
  done
  json+="]"

  _flow_atlas_async schedule push --format=json --data="$json"
  return 0
}
