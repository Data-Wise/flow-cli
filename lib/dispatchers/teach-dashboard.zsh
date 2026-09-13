# lib/dispatchers/teach-dashboard.zsh - Dynamic Website Content for Teaching
#
# `teach dashboard` generates, previews, and manages the JSON that a course
# website reads client-side to show "This Week," breaks, and announcements
# without a site rebuild (issue #275).
#
# See docs/specs/SPEC-teach-dashboard-2026-09-12.md for the design and
# docs/specs/GRILL-teach-dashboard-2026-09-13.md for the resolved open
# questions (announcement storage, semester length).

# ============================================================================
# Internal helpers
# ============================================================================

# Look up a single week's data (topic/focus/lecture/lab/assignment/etc.).
# Checks .flow/lesson-plans.yml (current schema) first, then falls back to
# the deprecated semester_info.weeks[] embedded in teach-config.yml — same
# precedence as _teach_show_week's topic lookup (teach-status.zsh).
# Args: config_file week_number
# Output: stdout - a JSON object for that week, or the literal "null"
_teach_dashboard_week_entry() {
    local config_file="$1"
    local week="$2"
    local lesson_plans_file=".flow/lesson-plans.yml"
    local entry=""

    if [[ -f "$lesson_plans_file" ]]; then
        entry=$(yq -o=json ".weeks[] | select(.number == $week)" "$lesson_plans_file" 2>/dev/null \
            | jq -s '.[0] // null' 2>/dev/null)
    fi

    if [[ -z "$entry" || "$entry" == "null" ]]; then
        entry=$(yq -o=json ".semester_info.weeks[] | select(.number == $week)" "$config_file" 2>/dev/null \
            | jq -s '.[0] // null' 2>/dev/null)
    fi

    [[ -z "$entry" ]] && entry="null"
    echo "$entry"
}

# Bulk-load the full weeks array, whichever source has it. Passed through
# as-is (no reshaping) so config-author fields we don't know about survive.
# Args: config_file
# Output: stdout - a JSON array
_teach_dashboard_all_weeks_json() {
    local config_file="$1"
    local lesson_plans_file=".flow/lesson-plans.yml"
    local weeks="[]"

    if [[ -f "$lesson_plans_file" ]]; then
        weeks=$(yq -o=json '.weeks // []' "$lesson_plans_file" 2>/dev/null)
    fi

    if [[ -z "$weeks" || "$weeks" == "null" || "$weeks" == "[]" ]]; then
        weeks=$(yq -o=json '.semester_info.weeks // []' "$config_file" 2>/dev/null)
    fi

    [[ -z "$weeks" || "$weeks" == "null" ]] && weeks="[]"
    echo "$weeks"
}

# ============================================================================
# teach dashboard generate
# ============================================================================

_teach_dashboard_generate() {
    local config_file=".flow/teach-config.yml"
    local output_file=".teach/semester-data.json"
    local announcements_file=".teach/announcements.json"
    local force=false
    [[ "$1" == "--force" ]] && force=true

    if [[ ! -f "$config_file" ]]; then
        _flow_log_error "No .flow/teach-config.yml found"
        _flow_log_info "Run 'teach init' to create a teaching project"
        return 1
    fi

    if [[ -f "$output_file" && "$force" != "true" ]]; then
        _flow_log_warning "$output_file already exists (use --force to overwrite)"
        return 1
    fi

    if ! command -v yq >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
        _flow_log_error "'yq' and 'jq' are both required for 'teach dashboard generate'"
        return 1
    fi

    local week
    week=$(_calculate_current_week "$config_file")
    if [[ -z "$week" ]]; then
        _flow_log_error "No semester_info.start_date configured in $config_file"
        return 1
    fi

    local break_name=""
    break_name=$(_is_break_week "$config_file" "$week" 2>/dev/null)
    local is_break=false
    [[ -n "$break_name" ]] && is_break=true

    local current_entry weeks_json breaks_json
    current_entry=$(_teach_dashboard_week_entry "$config_file" "$week")
    weeks_json=$(_teach_dashboard_all_weeks_json "$config_file")
    breaks_json=$(yq -o=json '.semester_info.breaks // []' "$config_file" 2>/dev/null)
    [[ -z "$breaks_json" || "$breaks_json" == "null" ]] && breaks_json="[]"

    local announcements_json="[]"
    if [[ -f "$announcements_file" ]]; then
        announcements_json=$(jq -c '.announcements // []' "$announcements_file" 2>/dev/null)
        [[ -z "$announcements_json" || "$announcements_json" == "null" ]] && announcements_json="[]"
    fi

    local course_name course_semester course_year start_date end_date timezone fallback_message
    course_name=$(yq -r '.course.name // ""' "$config_file" 2>/dev/null)
    course_semester=$(yq -r '.course.semester // ""' "$config_file" 2>/dev/null)
    course_year=$(yq -r '.course.year // ""' "$config_file" 2>/dev/null)
    start_date=$(yq -r '.semester_info.start_date // ""' "$config_file" 2>/dev/null)
    end_date=$(yq -r '.semester_info.end_date // ""' "$config_file" 2>/dev/null)
    timezone=$(yq -r '.semester_info.timezone // ""' "$config_file" 2>/dev/null)
    fallback_message=$(yq -r '.dashboard.fallback_message // ""' "$config_file" 2>/dev/null)

    mkdir -p .teach

    if jq -n \
        --arg version "1.0" \
        --arg schema_version "dashboard-v1" \
        --arg generated_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        --arg course_name "$course_name" \
        --arg course_semester "$course_semester" \
        --arg course_year "$course_year" \
        --arg start_date "$start_date" \
        --arg end_date "$end_date" \
        --arg timezone "$timezone" \
        --arg fallback_message "$fallback_message" \
        --argjson current_week_number "$week" \
        --argjson current_week_entry "$current_entry" \
        --argjson is_break "$is_break" \
        --arg break_name "$break_name" \
        --argjson weeks "$weeks_json" \
        --argjson breaks "$breaks_json" \
        --argjson announcements "$announcements_json" \
        '
        def blank_to_null: if . == "" then null else . end;
        {
            version: $version,
            schema_version: $schema_version,
            generated_at: $generated_at,
            course: {
                name: ($course_name | blank_to_null),
                semester: ($course_semester | blank_to_null),
                year: ($course_year | blank_to_null)
            },
            semester_info: {
                start_date: ($start_date | blank_to_null),
                end_date: ($end_date | blank_to_null),
                timezone: ($timezone | blank_to_null)
            },
            current_week: ({
                number: $current_week_number,
                is_break: $is_break,
                break_name: ($break_name | blank_to_null)
            } + ($current_week_entry // {})),
            weeks: $weeks,
            breaks: $breaks,
            announcements: $announcements,
            dashboard: {
                fallback_message: ($fallback_message | blank_to_null)
            }
        }
        ' > "$output_file"
    then
        local msg="Generated $output_file (week $week"
        [[ "$is_break" == "true" ]] && msg+=", break: $break_name"
        msg+=")"
        _flow_log_success "$msg"
    else
        _flow_log_error "Failed to generate $output_file"
        return 1
    fi
}

# ============================================================================
# teach dashboard preview
# ============================================================================

_teach_dashboard_preview() {
    local config_file=".flow/teach-config.yml"
    local week=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --week)
                week="$2"
                shift 2
                ;;
            --help|-h|help)
                _teach_dashboard_help
                return 0
                ;;
            *)
                shift
                ;;
        esac
    done

    if [[ ! -f "$config_file" ]]; then
        _flow_log_error "No .flow/teach-config.yml found"
        _flow_log_info "Run 'teach init' to create a teaching project"
        return 1
    fi

    [[ -z "$week" ]] && week=$(_calculate_current_week "$config_file")

    if [[ -z "$week" ]]; then
        _flow_log_error "No semester_info.start_date configured in $config_file"
        return 1
    fi

    if [[ ! "$week" =~ ^[0-9]+$ ]]; then
        _flow_log_error "Invalid week number: '$week' (must be a positive integer)"
        return 1
    fi

    local break_name=""
    break_name=$(_is_break_week "$config_file" "$week" 2>/dev/null)

    local topic="" focus="" lecture="" lab="" assignment=""
    if command -v yq >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        local entry_json
        entry_json=$(_teach_dashboard_week_entry "$config_file" "$week")
        topic=$(echo "$entry_json" | jq -r '.topic // ""' 2>/dev/null)
        focus=$(echo "$entry_json" | jq -r '.focus // ""' 2>/dev/null)
        lecture=$(echo "$entry_json" | jq -r '.lecture // ""' 2>/dev/null)
        lab=$(echo "$entry_json" | jq -r '.lab // ""' 2>/dev/null)
        assignment=$(echo "$entry_json" | jq -r '.assignment // ""' 2>/dev/null)
    fi

    echo ""
    echo "╭─────────────────────────────────────────────────╮"
    printf "│  %-47s│\n" "DASHBOARD PREVIEW — Week $week"
    echo "╰─────────────────────────────────────────────────╯"
    echo ""

    if [[ -n "$break_name" ]]; then
        echo "  ${FLOW_COLORS[warning]}⚠️  Break: $break_name${FLOW_COLORS[reset]}"
    fi
    [[ -n "$topic" ]] && echo "  Topic:      $topic"
    [[ -n "$focus" ]] && echo "  Focus:      $focus"
    [[ -n "$lecture" ]] && echo "  Lecture:    $lecture"
    [[ -n "$lab" ]] && echo "  Lab:        $lab"
    [[ -n "$assignment" ]] && echo "  Assignment: $assignment"

    if [[ -z "$break_name$topic$focus$lecture$lab$assignment" ]]; then
        _flow_log_muted "  (no lesson-plan data for week $week)"
    fi
    echo ""
}

# ============================================================================
# teach dashboard announce
# ============================================================================

_teach_dashboard_announce() {
    local config_file=".flow/teach-config.yml"
    local announcements_file=".teach/announcements.json"

    if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "help" ]]; then
        _teach_dashboard_help
        return 0
    fi

    if [[ ! -f "$config_file" ]]; then
        _flow_log_error "No .flow/teach-config.yml found"
        _flow_log_info "Run 'teach init' to create a teaching project"
        return 1
    fi

    if ! command -v jq >/dev/null 2>&1; then
        _flow_log_error "'jq' is required for 'teach dashboard announce'"
        return 1
    fi

    local title="" message="" expires="" type="note" id=""

    if [[ -n "$1" && "$1" != --* ]]; then
        # Positional mode: "Title" "Message" [--expires DATE] [--type TYPE] [--id ID]
        title="$1"
        message="$2"
        shift 2 2>/dev/null
        while [[ $# -gt 0 ]]; do
            case "$1" in
                --expires) expires="$2"; shift 2 ;;
                --type) type="$2"; shift 2 ;;
                --id) id="$2"; shift 2 ;;
                *) shift ;;
            esac
        done
    else
        # Interactive wizard
        read -r "title?Title: "
        read -r "message?Message: "
        read -r "expires?Expires (YYYY-MM-DD, optional): "
        read -r "type?Type (default: note): "
        [[ -z "$type" ]] && type="note"
    fi

    if [[ -z "$title" || -z "$message" ]]; then
        _flow_log_error "Title and message are required"
        return 1
    fi

    if [[ -n "$expires" ]] && ! _validate_date_format "$expires"; then
        _flow_log_error "Invalid --expires date: '$expires' (use YYYY-MM-DD)"
        return 1
    fi

    [[ -z "$id" ]] && id=$(_teach_slugify "$title")

    mkdir -p .teach
    [[ -f "$announcements_file" ]] || echo '{"announcements": []}' > "$announcements_file"

    local tmp_file="${announcements_file}.tmp.$$"
    if jq --arg id "$id" \
          --arg title "$title" \
          --arg message "$message" \
          --arg expires "$expires" \
          --arg type "$type" \
          --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
          '.announcements += [{
              id: $id,
              title: $title,
              message: $message,
              expires: (if $expires == "" then null else $expires end),
              type: $type,
              created_at: $created_at
          }]' "$announcements_file" > "$tmp_file" \
        && mv "$tmp_file" "$announcements_file"
    then
        _flow_log_success "Added announcement '$id' to $announcements_file"
    else
        rm -f "$tmp_file"
        _flow_log_error "Failed to write $announcements_file"
        return 1
    fi
}

# ============================================================================
# teach dashboard status
# ============================================================================

_teach_dashboard_status() {
    local config_file=".flow/teach-config.yml"
    local announcements_file=".teach/announcements.json"
    local output_file=".teach/semester-data.json"

    if [[ ! -f "$config_file" ]]; then
        _flow_log_error "No .flow/teach-config.yml found"
        _flow_log_info "Run 'teach init' to create a teaching project"
        return 1
    fi

    echo ""
    echo "╭─────────────────────────────────────────────────╮"
    printf "│  %-47s│\n" "DASHBOARD STATUS"
    echo "╰─────────────────────────────────────────────────╯"
    echo ""

    local has_dashboard_section="false"
    if command -v yq >/dev/null 2>&1; then
        local section
        section=$(yq -r '.dashboard // ""' "$config_file" 2>/dev/null)
        [[ -n "$section" && "$section" != "null" ]] && has_dashboard_section="true"
    fi
    if [[ "$has_dashboard_section" == "true" ]]; then
        echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} dashboard: section configured"
    else
        echo "  ${FLOW_COLORS[muted]}–${FLOW_COLORS[reset]} dashboard: section not configured (optional)"
    fi

    local total=0 expired=0
    if [[ -f "$announcements_file" ]] && command -v jq >/dev/null 2>&1; then
        total=$(jq '.announcements | length' "$announcements_file" 2>/dev/null)
        [[ -z "$total" || "$total" == "null" ]] && total=0
        local today
        today=$(date +%Y-%m-%d)
        expired=$(jq --arg today "$today" \
            '[.announcements[]? | select(.expires != null and .expires != "" and .expires < $today)] | length' \
            "$announcements_file" 2>/dev/null)
        [[ -z "$expired" || "$expired" == "null" ]] && expired=0
    fi
    echo "  Announcements: $total total"
    if (( expired > 0 )); then
        echo "  ${FLOW_COLORS[warning]}⚠️  $expired expired (flagged for cleanup)${FLOW_COLORS[reset]}"
    fi

    if [[ -f "$output_file" ]]; then
        local mtime now age_desc=""
        mtime=$(stat -f %m "$output_file" 2>/dev/null || stat -c %Y "$output_file" 2>/dev/null)
        now=$(date +%s)
        if [[ -n "$mtime" ]]; then
            age_desc=" ($(( (now - mtime) / 3600 ))h ago)"
        fi
        echo "  $output_file: present${age_desc}"
    else
        echo "  $output_file: ${FLOW_COLORS[muted]}not generated yet${FLOW_COLORS[reset]} — run 'teach dashboard generate'"
    fi
    echo ""
}

# ============================================================================
# Main Dispatcher for 'teach dashboard'
# ============================================================================

_teach_dashboard_dispatcher() {
    if [[ -z "$1" || "$1" == "help" || "$1" == "--help" || "$1" == "-h" ]]; then
        _teach_dashboard_help
        return 0
    fi

    local subcmd="$1"
    shift

    case "$subcmd" in
        generate|gen)
            _teach_dashboard_generate "$@"
            ;;
        preview|prev)
            _teach_dashboard_preview "$@"
            ;;
        announce|a)
            _teach_dashboard_announce "$@"
            ;;
        status|st)
            _teach_dashboard_status "$@"
            ;;
        *)
            _teach_error "Unknown dashboard subcommand: $subcmd"
            echo ""
            _teach_dashboard_help
            return 1
            ;;
    esac
}
