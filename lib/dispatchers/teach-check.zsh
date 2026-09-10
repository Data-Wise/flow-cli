# lib/dispatchers/teach-check.zsh - Cross-Tool Validation Summary
#
# `teach check` runs every validation layer available for the current teaching
# project and prints one aggregated pass/warn/fail/skip report. Two layers
# (R code, Craft content) are optional cross-tool integrations and degrade to
# SKIP rather than FAIL when their tool isn't installed.
#
# See docs/specs/SPEC-teach-check-2026-09-09.md for the design and the
# corrections made against the originating issue's (partly stale) sketch.

# Locate the Craft content validator, if the Craft plugin is installed.
# Returns the script path on stdout, or nothing (not an error) if absent.
_teach_find_craft_validator() {
    local -a candidates=(
        "$HOME/.claude/plugins/marketplaces/data-wise/craft/commands/utils/teaching_validation.py"
    )
    local candidate
    for candidate in "${candidates[@]}"; do
        if [[ -f "$candidate" ]]; then
            echo "$candidate"
            return 0
        fi
    done
    return 1
}

_teach_check() {
    local config_file=".flow/teach-config.yml"
    if [[ ! -f "$config_file" ]]; then
        _flow_log_error "No .flow/teach-config.yml found"
        _flow_log_info "Run 'teach init' to create a teaching project"
        return 1
    fi

    local -i pass=0 warn=0 fail=0 skip=0
    local -a report_lines=()

    # 1. Config syntax
    if command -v yq >/dev/null 2>&1; then
        if yq '.' "$config_file" >/dev/null 2>&1; then
            report_lines+=("Config syntax|PASS|flow-cli|")
            ((pass++))
        else
            report_lines+=("Config syntax|FAIL|flow-cli|invalid YAML")
            ((fail++))
        fi
    else
        report_lines+=("Config syntax|SKIP|flow-cli|yq not installed")
        ((skip++))
    fi

    # 2. Schema validation (local to flow-cli, no Scholar dependency)
    if _teach_validate_config "$config_file" --quiet; then
        report_lines+=("Schema|PASS|flow-cli|")
        ((pass++))
    else
        report_lines+=("Schema|FAIL|flow-cli|see 'teach validate' for details")
        ((fail++))
    fi

    # 3. Content + render (.qmd) — full mode already runs
    # yaml,syntax,render,chunks,images in one pass (commands/teach-validate.zsh)
    if teach-validate --quiet >/dev/null 2>&1; then
        report_lines+=("Content + render (.qmd)|PASS|flow-cli|")
        ((pass++))
    else
        report_lines+=("Content + render (.qmd)|WARN|flow-cli|see 'teach validate' for details")
        ((warn++))
    fi

    # 4. R code validation — always skipped by default. Scholar is a Claude
    # Code plugin, not a shell binary, so there is no clean availability
    # check, and teach validate-r is a slow, Claude-mediated call
    # inappropriate for a fast synchronous health check.
    report_lines+=("R code|SKIP|scholar|run 'teach validate-r' separately (slow)")
    ((skip++))

    # 5. Craft content validator — optional, cross-repo
    local craft_validator
    if craft_validator=$(_teach_find_craft_validator); then
        if python3 "$craft_validator" "$config_file" >/dev/null 2>&1; then
            report_lines+=("Craft content|PASS|craft|")
            ((pass++))
        else
            report_lines+=("Craft content|WARN|craft|see output for details")
            ((warn++))
        fi
    else
        report_lines+=("Craft content|SKIP|craft|not installed")
        ((skip++))
    fi

    _teach_check_render_report report_lines "$pass" "$warn" "$fail" "$skip"
    (( fail == 0 ))
}

# Renders the aggregated report box. Takes the report-lines array name (nameref
# via ${(P)}), then pass/warn/fail/skip counts.
_teach_check_render_report() {
    local -a lines=("${(@P)1}")
    local pass="$2" warn="$3" fail="$4" skip="$5"
    local total=$((pass + warn + fail))

    echo ""
    echo "╭─────────────────────────────────────────────╮"
    echo "│  TEACHING PROJECT HEALTH                     │"
    echo "╰─────────────────────────────────────────────╯"

    local line label chk_status source detail rest
    for line in "${lines[@]}"; do
        label="${line%%|*}"
        rest="${line#*|}"
        chk_status="${rest%%|*}"
        rest="${rest#*|}"
        source="${rest%%|*}"
        detail="${rest#*|}"

        local status_display
        case "$chk_status" in
            PASS) status_display="${FLOW_COLORS[success]}PASS${FLOW_COLORS[reset]}" ;;
            WARN) status_display="${FLOW_COLORS[warning]}WARN${FLOW_COLORS[reset]}" ;;
            FAIL) status_display="${FLOW_COLORS[error]}FAIL${FLOW_COLORS[reset]}" ;;
            SKIP) status_display="${FLOW_COLORS[muted]}SKIP${FLOW_COLORS[reset]}" ;;
            *) status_display="$chk_status" ;;
        esac

        printf "  %-28s %-6b [%s]" "$label" "$status_display" "$source"
        [[ -n "$detail" ]] && printf "  %s" "$detail"
        echo ""
    done

    echo ""
    local summary="${pass}/${total} checks passed"
    (( warn > 0 )) && summary+=", ${warn} warning"
    (( warn > 1 )) && summary+="s"
    (( skip > 0 )) && summary+=", ${skip} skipped (optional tools not run/installed)"
    echo "  $summary"
    echo ""
}
