# Tool Inventory Generator
# Auto-generates list of all dev-tools projects from .STATUS files

# =============================================================================
# Function: _flow_generate_inventory
# Purpose: Generate project inventory from .STATUS files in dev-tools directory
# =============================================================================
# Arguments:
#   $1 - (optional) Output format: "table" (default), "json", or "markdown"
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - Formatted inventory with columns:
#            - Project name
#            - Status (active/stable/paused/archived with icons)
#            - Type
#            - Progress percentage
#            - Next action (truncated to 40 chars)
#            - Summary counts by status
#
# Example:
#   _flow_generate_inventory              # Table format (default)
#   _flow_generate_inventory json         # JSON format
#   _flow_generate_inventory > inventory.md  # Save to file
#
# Notes:
#   - Scans ~/projects/dev-tools/ for .STATUS files
#   - Projects without .STATUS show "—" for missing fields
#   - Status icons: 🟢 active, ✅ stable, ⏸️ paused, 📦 archived
#   - JSON format delegates to _flow_generate_inventory_json
# =============================================================================
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

# =============================================================================
# Function: _flow_generate_inventory_json
# Purpose: Generate project inventory in JSON format for programmatic use
# =============================================================================
# Arguments:
#   None
#
# Returns:
#   0 - Always succeeds
#
# Output:
#   stdout - JSON object with structure:
#            {
#              "generated": "ISO-8601 timestamp",
#              "source": "~/projects/dev-tools/",
#              "projects": [
#                { "name", "path", "status", "type", "progress", "next" }
#              ]
#            }
#
# Example:
#   _flow_generate_inventory_json | jq '.projects[] | select(.status=="active")'
#   _flow_generate_inventory_json > inventory.json
#
# Notes:
#   - Scans ~/projects/dev-tools/ for .STATUS files
#   - Projects without .STATUS show "unknown" for missing fields
#   - JSON special characters in "next" field are escaped
#   - Timestamp is UTC ISO-8601 format
# =============================================================================
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
