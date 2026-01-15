# =============================================================================
# config-validator.zsh - Teaching Config Validation & Change Detection
# Part of flow-cli v5.9.0+
#
# Features:
#   - Schema-based validation for teach-config.yml
#   - Hash-based change detection (SHA-256)
#   - Graceful fallback when yq unavailable
#
# Ownership Protocol:
#   - course, semester_info, branches, deployment, automation: flow-cli owns
#   - scholar: Scholar owns (read-only for flow-cli)
#   - examark, shortcuts: shared
# =============================================================================

# Cache directory for hash files
FLOW_CONFIG_CACHE_DIR="${FLOW_DATA_DIR:-$HOME/.local/share/flow-cli}/cache"

# -----------------------------------------------------------------------------
# Hash-Based Change Detection
# -----------------------------------------------------------------------------

# Compute SHA-256 hash of config file
# Usage: _flow_config_hash [config_file]
_flow_config_hash() {
    local config_file="${1:-.flow/teach-config.yml}"

    if [[ ! -f "$config_file" ]]; then
        echo ""
        return 1
    fi

    # Use shasum (macOS) or sha256sum (Linux)
    if command -v shasum >/dev/null 2>&1; then
        shasum -a 256 "$config_file" | cut -d' ' -f1
    elif command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$config_file" | cut -d' ' -f1
    else
        # Fallback: use file modification time
        stat -f '%m' "$config_file" 2>/dev/null || stat -c '%Y' "$config_file" 2>/dev/null
    fi
}

# Check if config has changed since last read
# Usage: _flow_config_changed [config_file]
# Returns: 0 if changed, 1 if unchanged
_flow_config_changed() {
    local config_file="${1:-.flow/teach-config.yml}"
    local cache_file="$FLOW_CONFIG_CACHE_DIR/teach-config.hash"

    # Ensure cache dir exists
    mkdir -p "$FLOW_CONFIG_CACHE_DIR" 2>/dev/null

    local current_hash=$(_flow_config_hash "$config_file")

    if [[ -z "$current_hash" ]]; then
        return 0  # Config doesn't exist, consider changed
    fi

    if [[ -f "$cache_file" ]]; then
        local cached_hash=$(cat "$cache_file" 2>/dev/null)
        if [[ "$cached_hash" == "$current_hash" ]]; then
            return 1  # Unchanged
        fi
    fi

    # Update cache
    echo "$current_hash" > "$cache_file"
    return 0  # Changed
}

# Force cache invalidation
# Usage: _flow_config_invalidate
_flow_config_invalidate() {
    local cache_file="$FLOW_CONFIG_CACHE_DIR/teach-config.hash"
    rm -f "$cache_file" 2>/dev/null
}

# -----------------------------------------------------------------------------
# Config Validation
# -----------------------------------------------------------------------------

# Validate teach-config.yml structure
# Usage: _teach_validate_config [config_file] [--quiet]
# Returns: 0 if valid, 1 if invalid
_teach_validate_config() {
    local config_file="${1:-.flow/teach-config.yml}"
    local quiet=false

    [[ "$2" == "--quiet" ]] && quiet=true

    # Check file exists
    if [[ ! -f "$config_file" ]]; then
        $quiet || _flow_log_error "Config not found: $config_file"
        $quiet || _flow_log_info "Run 'teach init' to create a teaching project"
        return 1
    fi

    # Check yq is available
    if ! command -v yq >/dev/null 2>&1; then
        $quiet || _flow_log_warn "yq not installed - skipping schema validation"
        $quiet || _flow_log_info "Install: brew install yq"
        return 0  # Graceful fallback
    fi

    local errors=()

    # Required field: course.name
    local course_name=$(yq -r '.course.name // ""' "$config_file" 2>/dev/null)
    if [[ -z "$course_name" || "$course_name" == "null" ]]; then
        errors+=("Missing required field: course.name")
    fi

    # Validate semester (if present)
    local semester=$(yq -r '.course.semester // ""' "$config_file" 2>/dev/null)
    if [[ -n "$semester" && "$semester" != "null" ]]; then
        case "$semester" in
            Spring|Summer|Fall|Winter) ;;
            *) errors+=("Invalid semester '$semester' - must be Spring, Summer, Fall, or Winter") ;;
        esac
    fi

    # Validate year (if present)
    local year=$(yq -r '.course.year // 0' "$config_file" 2>/dev/null)
    if [[ "$year" != "0" && "$year" != "null" ]]; then
        if ! [[ "$year" =~ ^[0-9]+$ ]] || [[ "$year" -lt 2020 || "$year" -gt 2100 ]]; then
            errors+=("Invalid year '$year' - must be between 2020 and 2100")
        fi
    fi

    # Validate dates format (if present)
    local start_date=$(yq -r '.semester_info.start_date // ""' "$config_file" 2>/dev/null)
    if [[ -n "$start_date" && "$start_date" != "null" ]]; then
        if ! [[ "$start_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            errors+=("Invalid start_date format '$start_date' - use YYYY-MM-DD")
        fi
    fi

    local end_date=$(yq -r '.semester_info.end_date // ""' "$config_file" 2>/dev/null)
    if [[ -n "$end_date" && "$end_date" != "null" ]]; then
        if ! [[ "$end_date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
            errors+=("Invalid end_date format '$end_date' - use YYYY-MM-DD")
        fi
    fi

    # Validate scholar.course_info.level (if present)
    local level=$(yq -r '.scholar.course_info.level // ""' "$config_file" 2>/dev/null)
    if [[ -n "$level" && "$level" != "null" ]]; then
        case "$level" in
            undergraduate|graduate|both) ;;
            *) errors+=("Invalid scholar.course_info.level '$level' - must be undergraduate, graduate, or both") ;;
        esac
    fi

    # Validate scholar.course_info.difficulty (if present)
    local difficulty=$(yq -r '.scholar.course_info.difficulty // ""' "$config_file" 2>/dev/null)
    if [[ -n "$difficulty" && "$difficulty" != "null" ]]; then
        case "$difficulty" in
            beginner|intermediate|advanced) ;;
            *) errors+=("Invalid scholar.course_info.difficulty '$difficulty' - must be beginner, intermediate, or advanced") ;;
        esac
    fi

    # Validate scholar.style.tone (if present)
    local tone=$(yq -r '.scholar.style.tone // ""' "$config_file" 2>/dev/null)
    if [[ -n "$tone" && "$tone" != "null" ]]; then
        case "$tone" in
            formal|conversational) ;;
            *) errors+=("Invalid scholar.style.tone '$tone' - must be formal or conversational") ;;
        esac
    fi

    # Validate grading sums to ~100 (if present and complete)
    local grading_sum=$(yq -r '[.scholar.grading | to_entries | .[].value] | add // 0' "$config_file" 2>/dev/null)
    if [[ "$grading_sum" != "0" && "$grading_sum" != "null" ]]; then
        if [[ "$grading_sum" -lt 95 || "$grading_sum" -gt 105 ]]; then
            errors+=("Grading percentages sum to $grading_sum% - should be ~100%")
        fi
    fi

    # Report errors
    if [[ ${#errors[@]} -gt 0 ]]; then
        if ! $quiet; then
            _flow_log_error "Config validation failed:"
            for err in "${errors[@]}"; do
                echo "  • $err"
            done
        fi
        return 1
    fi

    $quiet || _flow_log_success "Config validated: $config_file"
    return 0
}

# Get config value with fallback
# Usage: _teach_config_get <key> [default] [config_file]
_teach_config_get() {
    local key="$1"
    local default="${2:-}"
    local config_file="${3:-.flow/teach-config.yml}"

    if [[ ! -f "$config_file" ]]; then
        echo "$default"
        return
    fi

    if ! command -v yq >/dev/null 2>&1; then
        echo "$default"
        return
    fi

    local value=$(yq -r ".$key // \"\"" "$config_file" 2>/dev/null)
    if [[ -z "$value" || "$value" == "null" ]]; then
        echo "$default"
    else
        echo "$value"
    fi
}

# Check if scholar section exists and is configured
# Usage: _teach_has_scholar_config [config_file]
_teach_has_scholar_config() {
    local config_file="${1:-.flow/teach-config.yml}"

    if [[ ! -f "$config_file" ]]; then
        return 1
    fi

    if ! command -v yq >/dev/null 2>&1; then
        # Fallback: grep for scholar section
        grep -q "^scholar:" "$config_file" 2>/dev/null
        return $?
    fi

    local scholar_exists=$(yq -r '.scholar // "none"' "$config_file" 2>/dev/null)
    [[ "$scholar_exists" != "none" && "$scholar_exists" != "null" ]]
}

# Get config file path (searches up directory tree)
# Usage: _teach_find_config
_teach_find_config() {
    local dir="$PWD"

    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/.flow/teach-config.yml" ]]; then
            echo "$dir/.flow/teach-config.yml"
            return 0
        fi
        dir="${dir:h}"
    done

    return 1
}

# -----------------------------------------------------------------------------
# Config Summary
# -----------------------------------------------------------------------------

# Show config summary for teach status
# Usage: _teach_config_summary [config_file]
_teach_config_summary() {
    local config_file="${1:-$(_teach_find_config)}"

    if [[ -z "$config_file" || ! -f "$config_file" ]]; then
        echo "  ${FLOW_COLORS[muted]}No config found${FLOW_COLORS[reset]}"
        return 1
    fi

    local course_name=$(_teach_config_get "course.name" "Unknown" "$config_file")
    local semester=$(_teach_config_get "course.semester" "" "$config_file")
    local year=$(_teach_config_get "course.year" "" "$config_file")
    local level=$(_teach_config_get "scholar.course_info.level" "" "$config_file")

    echo "  📚 ${FLOW_COLORS[bold]}$course_name${FLOW_COLORS[reset]}"
    [[ -n "$semester" && -n "$year" ]] && echo "  📅 $semester $year"
    [[ -n "$level" ]] && echo "  🎓 Level: $level"

    # Scholar status
    if _teach_has_scholar_config "$config_file"; then
        echo "  🔗 Scholar: ${FLOW_COLORS[success]}configured${FLOW_COLORS[reset]}"
    else
        echo "  🔗 Scholar: ${FLOW_COLORS[muted]}not configured${FLOW_COLORS[reset]}"
    fi

    # Validation status
    if _teach_validate_config "$config_file" --quiet; then
        echo "  ✅ Config: valid"
    else
        echo "  ⚠️  Config: ${FLOW_COLORS[warn]}has issues${FLOW_COLORS[reset]}"
    fi
}
