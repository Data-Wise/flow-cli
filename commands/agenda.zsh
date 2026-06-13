# commands/agenda.zsh - Forward-looking schedule view
#
# `agenda` surfaces in-window + overdue dated activity across all projects —
# assignment due dates, exam dates, manuscript/grant deadlines, milestones, and
# recurring blocks — grouped into OVERDUE / TODAY / THIS WEEK / LATER buckets.
#
# Driven entirely by the shared engine (lib/schedule.zsh). Works fully without
# atlas and without yq (the teaching path is the only one needing yq). `agenda`
# is a top-level command (auto-loaded), NOT a dispatcher: it is not subject to
# the binary-precedence guard and not in _FLOW_HELP_FUNCTIONS.

# ============================================================================
# AGENDA COMMAND
# ============================================================================

agenda() {
  local arg="${1:-}"
  local window=$SCHEDULE_DEFAULT_WINDOW
  local category=""
  local overdue_only=0
  local show_all=0

  case "$arg" in
    -h|--help|help)
      _agenda_help
      return 0
      ;;
    ""|-w|--week)
      window=7
      ;;
    today)
      window=0
      ;;
    -m|--month)
      window=30
      ;;
    --all)
      window=3650
      show_all=1
      ;;
    --overdue)
      overdue_only=1
      window=0
      ;;
    dev|r|research|teach|teaching|general|recurring|quarto|apps)
      # Filter matches the record's TYPE (research/teaching/general/recurring)
      # OR the project's detected category (dev/r/quarto/apps). teach/teaching
      # are synonyms — see _schedule_category_match.
      category="$arg"
      window=7
      ;;
    *)
      _flow_log_warning "Unknown agenda option: $arg"
      echo ""
      _agenda_help
      return 1
      ;;
  esac

  # Pipeline: collect -> window filter -> sort
  local records
  records=$(_schedule_collect "$window" "$category" | _schedule_filter_window "$window" | _schedule_sort)

  # Holidays are noise unless explicitly requested (--all)
  if (( ! show_all )) && [[ -n "$records" ]]; then
    records=$(print -r -- "$records" | grep -v '|holiday|')
  fi

  # Bucketize (THIS WEEK vs LATER split on the fixed 7-day horizon)
  local -a b_overdue=() b_today=() b_week=() b_later=()
  local rec date class
  if [[ -n "$records" ]]; then
    while IFS= read -r rec; do
      [[ -z "$rec" ]] && continue
      date="${rec%%|*}"
      class=$(_schedule_classify "$date" "$SCHEDULE_DEFAULT_WINDOW")
      case "$class" in
        overdue) b_overdue+=("$rec") ;;
        today)   b_today+=("$rec") ;;
        soon)    b_week+=("$rec") ;;
        later)   b_later+=("$rec") ;;
      esac
    done <<< "$records"
  fi

  # --overdue narrows to the overdue bucket only
  if (( overdue_only )); then
    b_today=(); b_week=(); b_later=()
  fi

  local total=$(( ${#b_overdue[@]} + ${#b_today[@]} + ${#b_week[@]} + ${#b_later[@]} ))

  # Header
  echo ""
  echo "  📅 ${FLOW_COLORS[bold]}AGENDA${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}$(_agenda_window_label "$window" "$category" "$overdue_only" "$show_all")${FLOW_COLORS[reset]}"
  echo ""

  # Calm empty state
  if (( total == 0 )); then
    echo "  ${FLOW_COLORS[success]}📅 Nothing scheduled — clear runway${FLOW_COLORS[reset]}"
    echo ""
    _flow_schedule_to_atlas
    return 0
  fi

  _agenda_render_bucket "OVERDUE"   "${FLOW_COLORS[error]}"   b_overdue
  _agenda_render_bucket "TODAY"     "${FLOW_COLORS[warning]}" b_today
  _agenda_render_bucket "THIS WEEK" "${FLOW_COLORS[info]}"    b_week
  _agenda_render_bucket "LATER"     "${FLOW_COLORS[muted]}"   b_later

  echo "  ${FLOW_COLORS[muted]}$total item$( (( total != 1 )) && echo s ) • 'agenda -h' for options${FLOW_COLORS[reset]}"
  echo ""

  # Opportunistic atlas sync (async, no-op when atlas/schedule absent)
  if [[ -n "$records" ]]; then
    local -a all_records=("${(@f)records}")
    _flow_schedule_to_atlas "${all_records[@]}"
  fi
}

# ============================================================================
# RENDER HELPERS
# ============================================================================

# Render one labeled bucket (skips empty buckets). $3 = name of a record array.
_agenda_render_bucket() {
  local title="$1" color="$2" arr_name="$3"
  local -a items=("${(@P)arr_name}")
  (( ${#items[@]} == 0 )) && return 0

  echo "  ${color}${FLOW_COLORS[bold]}$title${FLOW_COLORS[reset]} ${FLOW_COLORS[muted]}(${#items[@]})${FLOW_COLORS[reset]}"
  local rec
  for rec in "${items[@]}"; do
    _schedule_render_line "$rec"
  done
  echo ""
}

# Build the dim window/scope label shown beside the AGENDA header.
_agenda_window_label() {
  local window="$1" category="$2" overdue_only="$3" show_all="$4"
  local label=""

  if (( overdue_only )); then
    label="overdue only"
  elif (( show_all )); then
    label="everything"
  elif (( window == 0 )); then
    label="today"
  elif (( window == 7 )); then
    label="next 7 days"
  elif (( window == 30 )); then
    label="next 30 days"
  else
    label="next ${window} days"
  fi

  [[ -n "$category" ]] && label="$label • $category"
  echo "($label)"
}

# ============================================================================
# ALIASES (avoid `ag` — collides with the silver-searcher binary)
# ============================================================================

agt() { agenda today "$@"; }
agw() { agenda -w "$@"; }
agm() { agenda -m "$@"; }

# ============================================================================
# HELP
# ============================================================================

_agenda_help() {
  local _C_BOLD="${_C_BOLD:-\033[1m}"
  local _C_NC="${_C_NC:-\033[0m}"
  local _C_GREEN="${_C_GREEN:-\033[0;32m}"
  local _C_CYAN="${_C_CYAN:-\033[0;36m}"
  local _C_BLUE="${_C_BLUE:-\033[0;34m}"
  local _C_YELLOW="${_C_YELLOW:-\033[0;33m}"
  local _C_DIM="${_C_DIM:-\033[2m}"

  echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ 📅 AGENDA - Forward-Looking Schedule        │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_BOLD}Usage:${_C_NC} agenda [window | category | --overdue | --all]

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}agenda${_C_NC}            Next 7 days + overdue (default)
  ${_C_CYAN}agenda today${_C_NC}      Due today + overdue
  ${_C_CYAN}agenda --overdue${_C_NC}  Overdue items only

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} agenda                 ${_C_DIM}# This week's dated items${_C_NC}
  ${_C_DIM}\$${_C_NC} agenda -m              ${_C_DIM}# Next 30 days (adds LATER)${_C_NC}
  ${_C_DIM}\$${_C_NC} agenda research        ${_C_DIM}# Filter by item type or project category${_C_NC}
  ${_C_DIM}\$${_C_NC} agenda --all           ${_C_DIM}# Everything, incl. holidays${_C_NC}

${_C_BLUE}📋 WINDOWS${_C_NC}:
  ${_C_CYAN}(none)${_C_NC}, ${_C_CYAN}-w${_C_NC}, ${_C_CYAN}--week${_C_NC}    Next 7 days (default)
  ${_C_CYAN}today${_C_NC}             Today only (+ overdue)
  ${_C_CYAN}-m${_C_NC}, ${_C_CYAN}--month${_C_NC}        Next 30 days
  ${_C_CYAN}--all${_C_NC}             No window cap; includes holidays
  ${_C_CYAN}--overdue${_C_NC}         Overdue items only
  ${_C_CYAN}-h${_C_NC}, ${_C_CYAN}--help${_C_NC}         Show this help

${_C_BLUE}📂 FILTERS${_C_NC} ${_C_DIM}(match item type OR project category)${_C_NC}:
  ${_C_CYAN}research  teaching  general  recurring${_C_NC}  ${_C_DIM}(item type)${_C_NC}
  ${_C_CYAN}dev  r  teach  quarto  apps${_C_NC}            ${_C_DIM}(project category)${_C_NC}

${_C_BLUE}⚡ ALIASES${_C_NC}:
  ${_C_CYAN}agt${_C_NC} = agenda today   ${_C_CYAN}agw${_C_NC} = agenda -w   ${_C_CYAN}agm${_C_NC} = agenda -m

${_C_BLUE}📝 ADDING ITEMS${_C_NC} ${_C_DIM}(per-project .STATUS)${_C_NC}:
  ${_C_DIM}## Schedule:${_C_NC}
  ${_C_DIM}- 2026-06-20 | Submit JRSS-B revision | research${_C_NC}
  ${_C_DIM}- weekly:fri | Grading window | recurring${_C_NC}
  ${_C_DIM}Teaching dates derive from .flow/teach-config.yml automatically.${_C_NC}

${_C_BLUE}🎨 ICONS${_C_NC}:
  🎓 teaching   🔬 research   📌 general   🔁 recurring   🏖️ holiday

${_C_DIM}See also:${_C_NC} dash help, morning, today, week
"
}
