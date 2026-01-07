# Tool Inventory Generator
# Auto-generates list of all dev-tools projects from .STATUS files

_flow_generate_inventory() {
    local dev_tools="$HOME/projects/dev-tools"
    local format="${1:-table}"  # table, json, or markdown

    if [[ "$format" == "json" ]]; then
        _flow_generate_inventory_json
        return
    fi

    # Table format (default)
    echo ""
    echo "# Dev Tools Inventory"
    echo ""
    echo "**Generated:** $(date '+%Y-%m-%d %H:%M:%S')"
    echo "**Source:** .STATUS files in ~/projects/dev-tools/"
    echo ""
    echo "| Project | Status | Type | Progress | Next Action |"
    echo "|---------|--------|------|----------|-------------|"

    # Iterate through all project directories
    for project_dir in "$dev_tools"/*/; do
        [[ ! -d "$project_dir" ]] && continue

        local name=$(basename "$project_dir")
        local proj_status="—"
        local proj_type="—"
        local proj_progress="—"
        local proj_next="—"

        # Read .STATUS if exists
        if [[ -f "$project_dir/.STATUS" ]]; then
            proj_status=$(grep "^status:" "$project_dir/.STATUS" 2>/dev/null | cut -d: -f2- | xargs)
            proj_type=$(grep "^type:" "$project_dir/.STATUS" 2>/dev/null | cut -d: -f2- | xargs)
            proj_progress=$(grep "^progress:" "$project_dir/.STATUS" 2>/dev/null | cut -d: -f2- | xargs)
            proj_next=$(grep "^next:" "$project_dir/.STATUS" 2>/dev/null | cut -d: -f2- | xargs)

            # Truncate long next actions
            if [[ ${#proj_next} -gt 40 ]]; then
                proj_next="${proj_next:0:37}..."
            fi
        fi

        # Status icons
        case "$proj_status" in
            active) proj_status="🟢 active" ;;
            stable) proj_status="✅ stable" ;;
            paused) proj_status="⏸️ paused" ;;
            archived) proj_status="📦 archived" ;;
        esac

        echo "| $name | $proj_status | $proj_type | $proj_progress | $proj_next |"
    done

    echo ""
    echo "---"
    echo ""
    echo "**Summary:**"

    # Count by status
    local active_count=$(grep -l "^status: *active" "$dev_tools"/*/.STATUS 2>/dev/null | wc -l | xargs)
    local stable_count=$(grep -l "^status: *stable" "$dev_tools"/*/.STATUS 2>/dev/null | wc -l | xargs)
    local paused_count=$(grep -l "^status: *paused" "$dev_tools"/*/.STATUS 2>/dev/null | wc -l | xargs)
    local total=$(ls -d "$dev_tools"/*/ 2>/dev/null | wc -l | xargs)

    echo "- 🟢 Active: $active_count"
    echo "- ✅ Stable: $stable_count"
    echo "- ⏸️ Paused: $paused_count"
    echo "- **Total:** $total projects"
    echo ""
}

_flow_generate_inventory_json() {
    local dev_tools="$HOME/projects/dev-tools"

    echo "{"
    echo '  "generated": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",'
    echo '  "source": "~/projects/dev-tools/",'
    echo '  "projects": ['

    local first=true
    for project_dir in "$dev_tools"/*/; do
        [[ ! -d "$project_dir" ]] && continue

        local name=$(basename "$project_dir")
        local proj_status="unknown"
        local proj_type="unknown"
        local proj_progress="unknown"
        local proj_next="unknown"

        # Read .STATUS if exists
        if [[ -f "$project_dir/.STATUS" ]]; then
            proj_status=$(grep "^status:" "$project_dir/.STATUS" 2>/dev/null | cut -d: -f2- | xargs)
            proj_type=$(grep "^type:" "$project_dir/.STATUS" 2>/dev/null | cut -d: -f2- | xargs)
            proj_progress=$(grep "^progress:" "$project_dir/.STATUS" 2>/dev/null | cut -d: -f2- | xargs)
            proj_next=$(grep "^next:" "$project_dir/.STATUS" 2>/dev/null | cut -d: -f2- | xargs)
        fi

        # JSON escaping for next action
        proj_next=$(echo "$proj_next" | sed 's/"/\\"/g')

        if [[ "$first" == true ]]; then
            first=false
        else
            echo ","
        fi

        cat <<EOF
    {
      "name": "$name",
      "path": "$project_dir",
      "status": "$proj_status",
      "type": "$proj_type",
      "progress": "$proj_progress",
      "next": "$proj_next"
    }
EOF
    done

    echo ""
    echo "  ]"
    echo "}"
}

# Export function
typeset -f _flow_generate_inventory >/dev/null 2>&1
