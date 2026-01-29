#!/usr/bin/env zsh
# teach-plan.zsh - Lesson plan CRUD management (v5.22.0 - Issue #278)
# Manages week entries in .flow/lesson-plans.yml (centralized format)
#
# Commands: create, list, show, edit, delete, help
# Shortcuts: teach pl, teach plan c, teach plan ls, teach plan s

# Load guard - prevent double-sourcing
[[ -n "$_FLOW_TEACH_PLAN_LOADED" ]] && return 0
typeset -g _FLOW_TEACH_PLAN_LOADED=1

# Source core utilities
if [[ -z "$_FLOW_CORE_LOADED" ]]; then
    local core_path="${0:A:h:h}/lib/core.zsh"
    [[ -f "$core_path" ]] && source "$core_path"
fi

# ============================================================================
# CONSTANTS
# ============================================================================

typeset -g _TEACH_PLAN_FILE=".flow/lesson-plans.yml"
typeset -g _TEACH_PLAN_CONFIG=".flow/teach-config.yml"
typeset -g _TEACH_PLAN_STYLES=("conceptual" "computational" "rigorous" "applied")
typeset -g _TEACH_PLAN_MAX_WEEK=20

# ============================================================================
# MAIN DISPATCHER
# ============================================================================

# Main entry point for teach plan subcommand
# Usage: _teach_plan <action> [args...]
_teach_plan() {
    local action="${1:-list}"
    shift 2>/dev/null || true

    case "$action" in
        create|c|new)
            _teach_plan_create "$@"
            ;;
        list|ls|l)
            _teach_plan_list "$@"
            ;;
        show|s|view)
            _teach_plan_show "$@"
            ;;
        edit|e)
            _teach_plan_edit "$@"
            ;;
        delete|del|rm)
            _teach_plan_delete "$@"
            ;;
        help|--help|-h)
            _teach_plan_help
            ;;
        *)
            # If it looks like a week number, show that week
            if [[ "$action" =~ ^[0-9]+$ ]]; then
                _teach_plan_show "$action" "$@"
            else
                _flow_log_error "Unknown action: $action"
                echo "  Run: teach plan help"
                return 1
            fi
            ;;
    esac
}

# ============================================================================
# CREATE
# ============================================================================

# Create a new week entry in lesson-plans.yml
# Usage: _teach_plan_create <week> [--topic "Topic"] [--style style] [--force]
_teach_plan_create() {
    local week=""
    local topic=""
    local style=""
    local force=0
    local objectives=""
    local subtopics=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --topic|-t) topic="$2"; shift 2 ;;
            --style|-s) style="$2"; shift 2 ;;
            --force|-f) force=1; shift ;;
            --help|-h) _teach_plan_help; return 0 ;;
            *)
                if [[ -z "$week" && "$1" =~ ^[0-9]+$ ]]; then
                    week="$1"
                else
                    _flow_log_error "Unknown option: $1"
                    return 1
                fi
                shift
                ;;
        esac
    done

    # Validate week number
    if [[ -z "$week" ]]; then
        _flow_log_error "Week number required"
        echo "  Usage: teach plan create <week> [--topic \"Topic\"]"
        return 1
    fi

    if [[ "$week" -lt 1 || "$week" -gt "$_TEACH_PLAN_MAX_WEEK" ]]; then
        _flow_log_error "Week must be between 1 and $_TEACH_PLAN_MAX_WEEK (got: $week)"
        return 1
    fi

    # Check yq availability
    if ! command -v yq &>/dev/null; then
        _flow_log_error "yq not found (required for YAML manipulation)"
        echo "  Install: brew install yq"
        return 1
    fi

    # Create lesson-plans.yml if it doesn't exist
    if [[ ! -f "$_TEACH_PLAN_FILE" ]]; then
        if [[ ! -d ".flow" ]]; then
            _flow_log_error ".flow directory not found"
            echo "  Run: teach init"
            return 1
        fi
        echo "weeks: []" > "$_TEACH_PLAN_FILE"
        _flow_log_info "Created $_TEACH_PLAN_FILE"
    fi

    # Check for duplicate week
    local existing
    existing=$(yq ".weeks[] | select(.number == $week) | .number" "$_TEACH_PLAN_FILE" 2>/dev/null)
    if [[ -n "$existing" && "$force" -eq 0 ]]; then
        _flow_log_error "Week $week already exists in lesson-plans.yml"
        echo "  Use --force to overwrite, or: teach plan edit $week"
        return 1
    fi

    # If forcing, remove existing entry first
    if [[ -n "$existing" && "$force" -eq 1 ]]; then
        yq -i "del(.weeks[] | select(.number == $week))" "$_TEACH_PLAN_FILE" 2>/dev/null
        _flow_log_info "Replacing existing week $week"
    fi

    # Auto-populate topic from teach-config.yml if not provided
    if [[ -z "$topic" && -f "$_TEACH_PLAN_CONFIG" ]]; then
        local config_topic
        config_topic=$(yq ".semester_info.weeks[] | select(.number == $week) | .topic // \"\"" "$_TEACH_PLAN_CONFIG" 2>/dev/null)
        if [[ -n "$config_topic" && "$config_topic" != "null" ]]; then
            topic="$config_topic"
            _flow_log_info "Auto-populated topic from config: \"$topic\""
        fi
    fi

    # Interactive prompts for missing fields
    if [[ -z "$topic" ]]; then
        echo -n "${FLOW_COLORS[prompt]}Topic for Week $week: ${FLOW_COLORS[reset]}"
        read -r topic
        if [[ -z "$topic" ]]; then
            _flow_log_error "Topic is required"
            return 1
        fi
    fi

    # Validate style if provided
    if [[ -n "$style" ]]; then
        local valid=0
        for s in "${_TEACH_PLAN_STYLES[@]}"; do
            [[ "$s" == "$style" ]] && valid=1 && break
        done
        if [[ "$valid" -eq 0 ]]; then
            _flow_log_error "Invalid style: $style"
            echo "  Valid styles: ${_TEACH_PLAN_STYLES[*]}"
            return 1
        fi
    fi

    if [[ -z "$style" ]]; then
        echo -n "${FLOW_COLORS[prompt]}Style [conceptual/computational/rigorous/applied] (default: conceptual): ${FLOW_COLORS[reset]}"
        read -r style
        [[ -z "$style" ]] && style="conceptual"

        # Validate interactive input
        local valid=0
        for s in "${_TEACH_PLAN_STYLES[@]}"; do
            [[ "$s" == "$style" ]] && valid=1 && break
        done
        if [[ "$valid" -eq 0 ]]; then
            _flow_log_error "Invalid style: $style"
            return 1
        fi
    fi

    # Optional: objectives (comma-separated)
    if [[ -z "$objectives" ]]; then
        echo -n "${FLOW_COLORS[prompt]}Objectives (comma-separated, Enter to skip): ${FLOW_COLORS[reset]}"
        read -r objectives
    fi

    # Optional: subtopics (comma-separated)
    if [[ -z "$subtopics" ]]; then
        echo -n "${FLOW_COLORS[prompt]}Subtopics (comma-separated, Enter to skip): ${FLOW_COLORS[reset]}"
        read -r subtopics
    fi

    # Build entry safely using yq env vars (prevents YAML injection)
    local temp_file
    temp_file=$(mktemp)

    # Create base entry — strenv() safely escapes quotes/newlines in user input
    PLAN_TOPIC="$topic" PLAN_STYLE="$style" \
        yq -n ".number = $week | .topic = strenv(PLAN_TOPIC) | .style = strenv(PLAN_STYLE)" > "$temp_file"

    # Add objectives array
    if [[ -n "$objectives" ]]; then
        yq -i '.objectives = []' "$temp_file"
        IFS=',' read -rA obj_list <<< "$objectives"
        for obj in "${obj_list[@]}"; do
            obj="${obj## }"  # trim leading space
            obj="${obj%% }"  # trim trailing space
            PLAN_ITEM="$obj" yq -i '.objectives += [strenv(PLAN_ITEM)]' "$temp_file"
        done
    else
        yq -i '.objectives = []' "$temp_file"
    fi

    # Add subtopics array
    if [[ -n "$subtopics" ]]; then
        yq -i '.subtopics = []' "$temp_file"
        IFS=',' read -rA sub_list <<< "$subtopics"
        for sub in "${sub_list[@]}"; do
            sub="${sub## }"
            sub="${sub%% }"
            PLAN_ITEM="$sub" yq -i '.subtopics += [strenv(PLAN_ITEM)]' "$temp_file"
        done
    else
        yq -i '.subtopics = []' "$temp_file"
    fi

    yq -i '.key_concepts = [] | .prerequisites = []' "$temp_file"

    # Backup before modification (restore on failure)
    local backup_file="${_TEACH_PLAN_FILE}.bak"
    cp "$_TEACH_PLAN_FILE" "$backup_file"

    # Add entry to weeks array from temp file
    yq -i ".weeks += [load(\"$temp_file\")]" "$_TEACH_PLAN_FILE" 2>/dev/null
    rm -f "$temp_file"

    # Sort weeks by number
    yq -i '.weeks |= sort_by(.number)' "$_TEACH_PLAN_FILE" 2>/dev/null

    # Validate result — restore backup on failure
    if ! yq eval '.' "$_TEACH_PLAN_FILE" &>/dev/null; then
        _flow_log_error "Generated invalid YAML - restoring backup"
        cp "$backup_file" "$_TEACH_PLAN_FILE"
        rm -f "$backup_file"
        return 1
    fi
    rm -f "$backup_file"

    echo ""
    _flow_log_success "Created lesson plan for Week $week: \"$topic\" ($style)"
    echo ""
    echo "  ${FLOW_COLORS[dim]}View:  teach plan show $week${FLOW_COLORS[reset]}"
    echo "  ${FLOW_COLORS[dim]}Edit:  teach plan edit $week${FLOW_COLORS[reset]}"
    echo "  ${FLOW_COLORS[dim]}List:  teach plan list${FLOW_COLORS[reset]}"
    echo ""
    return 0
}

# ============================================================================
# LIST
# ============================================================================

# List all week entries in lesson-plans.yml
# Usage: _teach_plan_list [--json]
_teach_plan_list() {
    local output_json=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json|-j) output_json=1; shift ;;
            --help|-h) _teach_plan_help; return 0 ;;
            *) shift ;;
        esac
    done

    # Check file exists
    if [[ ! -f "$_TEACH_PLAN_FILE" ]]; then
        if [[ $output_json -eq 1 ]]; then
            echo "[]"
        else
            echo ""
            _flow_log_warning "No lesson plans found"
            echo ""
            echo "  Create one: teach plan create 1"
            echo "  Or migrate: teach migrate-config"
            echo ""
        fi
        return 0
    fi

    # Check yq
    if ! command -v yq &>/dev/null; then
        _flow_log_error "yq not found"
        echo "  Install: brew install yq"
        return 1
    fi

    # Get week count
    local count
    count=$(yq '.weeks | length' "$_TEACH_PLAN_FILE" 2>/dev/null)

    if [[ -z "$count" || "$count" == "0" || "$count" == "null" ]]; then
        if [[ $output_json -eq 1 ]]; then
            echo "[]"
        else
            echo ""
            _flow_log_warning "No lesson plans defined (file exists but empty)"
            echo ""
            echo "  Create one: teach plan create 1"
            echo ""
        fi
        return 0
    fi

    # JSON output
    if [[ $output_json -eq 1 ]]; then
        yq -o=json '.weeks' "$_TEACH_PLAN_FILE" 2>/dev/null
        return 0
    fi

    # Pretty table output
    echo ""
    printf "  ${FLOW_COLORS[bold]}%-6s %-35s %-15s %-12s${FLOW_COLORS[reset]}\n" \
        "Week" "Topic" "Style" "Objectives"
    printf "  ${FLOW_COLORS[dim]}%-6s %-35s %-15s %-12s${FLOW_COLORS[reset]}\n" \
        "────" "───────────────────────────────────" "───────────────" "──────────"

    local i=0
    while [[ $i -lt $count ]]; do
        local num topic style obj_count
        num=$(yq ".weeks[$i].number" "$_TEACH_PLAN_FILE" 2>/dev/null)
        topic=$(yq ".weeks[$i].topic" "$_TEACH_PLAN_FILE" 2>/dev/null)
        style=$(yq ".weeks[$i].style // \"—\"" "$_TEACH_PLAN_FILE" 2>/dev/null)
        obj_count=$(yq ".weeks[$i].objectives | length" "$_TEACH_PLAN_FILE" 2>/dev/null)
        [[ "$obj_count" == "null" ]] && obj_count=0

        # Truncate topic if too long
        [[ ${#topic} -gt 33 ]] && topic="${topic:0:30}..."

        printf "  %-6s %-35s %-15s %-12s\n" \
            "$num" "$topic" "$style" "$obj_count"

        ((i++))
    done

    echo ""
    echo "  ${FLOW_COLORS[dim]}$count week(s) total${FLOW_COLORS[reset]}"

    # Detect gaps in sequence
    local max_week
    max_week=$(yq '.weeks[-1].number // 0' "$_TEACH_PLAN_FILE" 2>/dev/null)
    if [[ "$max_week" -gt "$count" ]]; then
        local gaps=()
        for ((w=1; w<=max_week; w++)); do
            local found
            found=$(yq ".weeks[] | select(.number == $w) | .number" "$_TEACH_PLAN_FILE" 2>/dev/null)
            [[ -z "$found" ]] && gaps+=("$w")
        done
        if [[ ${#gaps[@]} -gt 0 ]]; then
            echo "  ${FLOW_COLORS[warn]}Gaps: weeks ${gaps[*]}${FLOW_COLORS[reset]}"
        fi
    fi

    echo ""
    return 0
}

# ============================================================================
# SHOW
# ============================================================================

# Display a single week's lesson plan details
# Usage: _teach_plan_show <week> [--json]
_teach_plan_show() {
    local week=""
    local output_json=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json|-j) output_json=1; shift ;;
            --help|-h) _teach_plan_help; return 0 ;;
            *)
                if [[ -z "$week" && "$1" =~ ^[0-9]+$ ]]; then
                    week="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$week" ]]; then
        _flow_log_error "Week number required"
        echo "  Usage: teach plan show <week>"
        return 1
    fi

    if [[ ! -f "$_TEACH_PLAN_FILE" ]]; then
        _flow_log_error "No lesson plans file found"
        echo "  Create one: teach plan create $week"
        return 1
    fi

    if ! command -v yq &>/dev/null; then
        _flow_log_error "yq not found"
        echo "  Install: brew install yq"
        return 1
    fi

    # Extract week data
    local week_data
    week_data=$(yq ".weeks[] | select(.number == $week)" "$_TEACH_PLAN_FILE" 2>/dev/null)

    if [[ -z "$week_data" ]]; then
        _flow_log_error "Week $week not found in lesson plans"
        echo "  Create it: teach plan create $week"
        return 1
    fi

    # JSON output
    if [[ $output_json -eq 1 ]]; then
        echo "$week_data" | yq -o=json '.' 2>/dev/null
        return 0
    fi

    # Formatted display
    local topic style
    topic=$(echo "$week_data" | yq '.topic // ""')
    style=$(echo "$week_data" | yq '.style // "—"')

    echo ""
    echo "${FLOW_COLORS[bold]}╔════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[bold]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}Week $week${FLOW_COLORS[reset]}: $topic"
    echo "${FLOW_COLORS[bold]}╚════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}"
    echo ""
    echo "  ${FLOW_COLORS[bold]}Style:${FLOW_COLORS[reset]}          $style"

    # Objectives
    local obj_count
    obj_count=$(echo "$week_data" | yq '.objectives | length' 2>/dev/null)
    if [[ -n "$obj_count" && "$obj_count" != "0" && "$obj_count" != "null" ]]; then
        echo ""
        echo "  ${FLOW_COLORS[bold]}Objectives:${FLOW_COLORS[reset]}"
        echo "$week_data" | yq '.objectives[]' 2>/dev/null | while read -r obj; do
            echo "    • $obj"
        done
    fi

    # Subtopics
    local sub_count
    sub_count=$(echo "$week_data" | yq '.subtopics | length' 2>/dev/null)
    if [[ -n "$sub_count" && "$sub_count" != "0" && "$sub_count" != "null" ]]; then
        echo ""
        echo "  ${FLOW_COLORS[bold]}Subtopics:${FLOW_COLORS[reset]}"
        echo "$week_data" | yq '.subtopics[]' 2>/dev/null | while read -r sub; do
            echo "    - $sub"
        done
    fi

    # Key concepts
    local kc_count
    kc_count=$(echo "$week_data" | yq '.key_concepts | length' 2>/dev/null)
    if [[ -n "$kc_count" && "$kc_count" != "0" && "$kc_count" != "null" ]]; then
        echo ""
        echo "  ${FLOW_COLORS[bold]}Key Concepts:${FLOW_COLORS[reset]}"
        echo "$week_data" | yq '.key_concepts[]' 2>/dev/null | while read -r kc; do
            echo "    · $kc"
        done
    fi

    # Prerequisites
    local pre_count
    pre_count=$(echo "$week_data" | yq '.prerequisites | length' 2>/dev/null)
    if [[ -n "$pre_count" && "$pre_count" != "0" && "$pre_count" != "null" ]]; then
        echo ""
        echo "  ${FLOW_COLORS[bold]}Prerequisites:${FLOW_COLORS[reset]}"
        echo "$week_data" | yq '.prerequisites[]' 2>/dev/null | while read -r pre; do
            echo "    ← $pre"
        done
    fi

    echo ""
    echo "  ${FLOW_COLORS[dim]}Edit:   teach plan edit $week${FLOW_COLORS[reset]}"
    echo "  ${FLOW_COLORS[dim]}Delete: teach plan delete $week${FLOW_COLORS[reset]}"
    echo ""
    return 0
}

# ============================================================================
# EDIT
# ============================================================================

# Open lesson-plans.yml in $EDITOR, jumping to the week's line
# Usage: _teach_plan_edit <week>
_teach_plan_edit() {
    local week=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h) _teach_plan_help; return 0 ;;
            *)
                if [[ -z "$week" && "$1" =~ ^[0-9]+$ ]]; then
                    week="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$week" ]]; then
        _flow_log_error "Week number required"
        echo "  Usage: teach plan edit <week>"
        return 1
    fi

    if [[ ! -f "$_TEACH_PLAN_FILE" ]]; then
        _flow_log_error "No lesson plans file found"
        echo "  Create one: teach plan create $week"
        return 1
    fi

    # Check week exists
    if command -v yq &>/dev/null; then
        local exists
        exists=$(yq ".weeks[] | select(.number == $week) | .number" "$_TEACH_PLAN_FILE" 2>/dev/null)
        if [[ -z "$exists" ]]; then
            _flow_log_error "Week $week not found in lesson plans"
            echo "  Create it: teach plan create $week"
            return 1
        fi
    fi

    # Find line number for the week entry (-- ends option parsing, $ anchors match)
    local line_num
    line_num=$(grep -n -- "number: ${week}$" "$_TEACH_PLAN_FILE" 2>/dev/null | head -1 | cut -d: -f1)

    local editor="${EDITOR:-vi}"
    local max_edit_attempts=3
    local edit_attempts=0

    # Edit-validate loop (bounded retries instead of unbounded recursion)
    while true; do
        ((edit_attempts++))

        if [[ -n "$line_num" ]]; then
            [[ $edit_attempts -eq 1 ]] && echo "${FLOW_COLORS[info]}Week $week starts at line $line_num${FLOW_COLORS[reset]}"
            case "$editor" in
                *vim*|*vi*|*nvim*)
                    "$editor" "+$line_num" "$_TEACH_PLAN_FILE"
                    ;;
                *nano*)
                    "$editor" "+$line_num" "$_TEACH_PLAN_FILE"
                    ;;
                *code*|*codium*)
                    "$editor" --goto "$_TEACH_PLAN_FILE:$line_num"
                    ;;
                *)
                    "$editor" "$_TEACH_PLAN_FILE"
                    ;;
            esac
        else
            "$editor" "$_TEACH_PLAN_FILE"
        fi

        # Validate YAML after edit
        if ! command -v yq &>/dev/null || yq eval '.' "$_TEACH_PLAN_FILE" &>/dev/null; then
            _flow_log_success "YAML validated successfully"
            break
        fi

        echo ""
        _flow_log_error "Invalid YAML detected after edit"

        if [[ $edit_attempts -ge $max_edit_attempts ]]; then
            _flow_log_warning "Max retries ($max_edit_attempts) reached - please fix YAML manually"
            return 1
        fi

        echo -n "${FLOW_COLORS[prompt]}Re-open editor to fix? [Y/n]: ${FLOW_COLORS[reset]}"
        read -r fix_answer
        case "$fix_answer" in
            n|N|no)
                _flow_log_warning "YAML is invalid - please fix manually"
                return 1
                ;;
        esac
    done

    return 0
}

# ============================================================================
# DELETE
# ============================================================================

# Remove a week entry from lesson-plans.yml
# Usage: _teach_plan_delete <week> [--force]
_teach_plan_delete() {
    local week=""
    local force=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force|-f) force=1; shift ;;
            --help|-h) _teach_plan_help; return 0 ;;
            *)
                if [[ -z "$week" && "$1" =~ ^[0-9]+$ ]]; then
                    week="$1"
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$week" ]]; then
        _flow_log_error "Week number required"
        echo "  Usage: teach plan delete <week> [--force]"
        return 1
    fi

    if [[ ! -f "$_TEACH_PLAN_FILE" ]]; then
        _flow_log_error "No lesson plans file found"
        return 1
    fi

    if ! command -v yq &>/dev/null; then
        _flow_log_error "yq not found"
        echo "  Install: brew install yq"
        return 1
    fi

    # Check week exists
    local week_data
    week_data=$(yq ".weeks[] | select(.number == $week)" "$_TEACH_PLAN_FILE" 2>/dev/null)
    if [[ -z "$week_data" ]]; then
        _flow_log_error "Week $week not found in lesson plans"
        return 1
    fi

    local topic
    topic=$(echo "$week_data" | yq '.topic // ""')

    # Confirm unless --force
    if [[ "$force" -eq 0 ]]; then
        echo ""
        echo "${FLOW_COLORS[warn]}Delete Week $week: \"$topic\"?${FLOW_COLORS[reset]}"
        echo -n "${FLOW_COLORS[prompt]}Confirm [y/N]: ${FLOW_COLORS[reset]}"
        read -r confirm
        case "$confirm" in
            y|Y|yes)
                ;;
            *)
                _flow_log_info "Cancelled"
                return 0
                ;;
        esac
    fi

    # Remove the entry
    yq -i "del(.weeks[] | select(.number == $week))" "$_TEACH_PLAN_FILE" 2>/dev/null

    if [[ $? -ne 0 ]]; then
        _flow_log_error "Failed to delete week $week"
        return 1
    fi

    echo ""
    _flow_log_success "Deleted Week $week: \"$topic\""
    echo ""
    return 0
}

# ============================================================================
# HELP
# ============================================================================

_teach_plan_help() {
    cat <<EOF

${FLOW_COLORS[bold]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[bold]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach plan${FLOW_COLORS[reset]} — Lesson Plan Management                   ${FLOW_COLORS[bold]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[bold]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  teach plan <action> [options]
  teach pl <action> [options]

${FLOW_COLORS[bold]}ACTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}create${FLOW_COLORS[reset]} <week> [--topic T] [--style S]   Add week to lesson plans
  ${FLOW_COLORS[cmd]}list${FLOW_COLORS[reset]} [--json]                           Show all weeks
  ${FLOW_COLORS[cmd]}show${FLOW_COLORS[reset]} <week> [--json]                    Display week details
  ${FLOW_COLORS[cmd]}edit${FLOW_COLORS[reset]} <week>                             Open in \$EDITOR
  ${FLOW_COLORS[cmd]}delete${FLOW_COLORS[reset]} <week> [--force]                 Remove week entry

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  --topic, -t TOPIC     Topic name (or prompted interactively)
  --style, -s STYLE     ${FLOW_COLORS[muted]}conceptual | computational | rigorous | applied${FLOW_COLORS[reset]}
  --json, -j            Machine-readable JSON output
  --force, -f           Skip confirmation / overwrite existing
  --help, -h            Show this help

${FLOW_COLORS[bold]}SHORTCUTS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}pl${FLOW_COLORS[reset]} → plan    ${FLOW_COLORS[accent]}c${FLOW_COLORS[reset]} → create   ${FLOW_COLORS[accent]}ls${FLOW_COLORS[reset]} → list
  ${FLOW_COLORS[accent]}s${FLOW_COLORS[reset]} → show     ${FLOW_COLORS[accent]}e${FLOW_COLORS[reset]} → edit     ${FLOW_COLORS[accent]}del${FLOW_COLORS[reset]} → delete

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Create week with all options${FLOW_COLORS[reset]}
  \$ teach plan create 3 --topic "Probability" --style rigorous

  ${FLOW_COLORS[muted]}# Interactive creation (prompted for details)${FLOW_COLORS[reset]}
  \$ teach plan create 5

  ${FLOW_COLORS[muted]}# List all weeks${FLOW_COLORS[reset]}
  \$ teach plan list

  ${FLOW_COLORS[muted]}# View week details in JSON${FLOW_COLORS[reset]}
  \$ teach plan show 3 --json

  ${FLOW_COLORS[muted]}# Quick view (number only)${FLOW_COLORS[reset]}
  \$ teach plan 3

  ${FLOW_COLORS[muted]}# Edit in \$EDITOR (jumps to line)${FLOW_COLORS[reset]}
  \$ teach plan edit 3

  ${FLOW_COLORS[muted]}# Delete with confirmation${FLOW_COLORS[reset]}
  \$ teach plan delete 3

  ${FLOW_COLORS[muted]}# Force delete (no confirmation)${FLOW_COLORS[reset]}
  \$ teach plan delete 3 --force

${FLOW_COLORS[bold]}FILES${FLOW_COLORS[reset]}
  .flow/lesson-plans.yml    Centralized lesson plan file
  .flow/teach-config.yml    Course config (topic auto-populate)

${FLOW_COLORS[bold]}SEE ALSO${FLOW_COLORS[reset]}
  teach migrate-config      Extract plans from teach-config.yml
  teach slides --week N     Use plan data in slide generation
  teach lecture --week N    Use plan data in lecture generation

EOF
}
