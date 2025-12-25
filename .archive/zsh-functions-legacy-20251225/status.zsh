#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# STATUS - Project Status Management
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         ~/.config/zsh/functions/status.zsh
# Version:      1.0
# Date:         2025-12-14
# Purpose:      Easy creation and updating of .STATUS files
#
# Usage:        status <project> [status] [priority] [task] [progress]
# Examples:     status mediationverse
#               status medfit active P1 "Add vignette" 60
#               status newproject --create
#
# ══════════════════════════════════════════════════════════════════════════════

emulate -L zsh

# ═══════════════════════════════════════════════════════════════════
# MAIN STATUS COMMAND
# ═══════════════════════════════════════════════════════════════════

status() {
    local project="$1"

    # Color setup
    local GREEN='\033[0;32m'
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local RED='\033[0;31m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'

    # Show help
    if [[ -z "$project" ]] || [[ "$project" == "--help" ]] || [[ "$project" == "-h" ]]; then
        _status_help
        return 0
    fi

    # Find project directory
    local project_dir=""
    local search_paths=(
        "$HOME/projects/r-packages/active"
        "$HOME/projects/r-packages/stable"
        "$HOME/projects/teaching"
        "$HOME/projects/research"
        "$HOME/projects/dev-tools"
        "$HOME/projects/quarto"
        "$HOME/projects"
    )

    # Direct match
    for base in "${search_paths[@]}"; do
        if [[ -d "$base/$project" ]]; then
            project_dir="$base/$project"
            break
        fi
    done

    # Fuzzy match if not found
    if [[ -z "$project_dir" ]]; then
        project_dir=$(find ~/projects -maxdepth 3 -type d -name "*$project*" 2>/dev/null | head -1)
    fi

    # Check if current directory
    if [[ -z "$project_dir" ]] && [[ "$(basename $PWD)" == "$project" ]]; then
        project_dir="$PWD"
    fi

    if [[ -z "$project_dir" ]]; then
        echo -e "${RED}❌ Project not found: $project${NC}"
        echo ""
        echo "Searched in:"
        for path in "${search_paths[@]}"; do
            echo -e "  ${DIM}$path${NC}"
        done
        return 1
    fi

    local status_file="$project_dir/.STATUS"

    # Handle flags
    case "$2" in
        --create)
            _status_create "$project_dir"
            return $?
            ;;
        --show|--view)
            _status_show "$status_file"
            return $?
            ;;
        --template)
            _status_template
            return $?
            ;;
    esac

    # Quick update mode (all args provided)
    if [[ $# -ge 5 ]]; then
        _status_quick_update "$project_dir" "$2" "$3" "$4" "$5"
        return $?
    fi

    # Interactive update mode
    _status_interactive "$project_dir"
}

# ═══════════════════════════════════════════════════════════════════
# CREATE NEW STATUS FILE
# ═══════════════════════════════════════════════════════════════════

_status_create() {
    local project_dir="$1"
    local status_file="$project_dir/.STATUS"
    local project_name=$(basename "$project_dir")

    if [[ -f "$status_file" ]]; then
        echo -e "${YELLOW}⚠️  .STATUS already exists${NC}"
        echo ""
        read -q "REPLY?Overwrite? (y/n) "
        echo ""
        if [[ "$REPLY" != "y" ]]; then
            echo "Cancelled"
            return 1
        fi
    fi

    # Detect project type
    local project_type="project"
    if [[ -f "$project_dir/DESCRIPTION" ]]; then
        project_type="r-package"
    elif [[ -f "$project_dir/_quarto.yml" ]]; then
        project_type="quarto"
    elif [[ -f "$project_dir/package.json" ]]; then
        project_type="node"
    elif [[ -d "$project_dir/.obsidian" ]]; then
        project_type="obsidian"
    fi

    # Determine category
    local category="other"
    if [[ "$project_dir" == *"/teaching/"* ]]; then
        category="teaching"
    elif [[ "$project_dir" == *"/research/"* ]]; then
        category="research"
    elif [[ "$project_dir" == *"/r-packages/"* ]]; then
        category="r-packages"
    elif [[ "$project_dir" == *"/dev-tools/"* ]]; then
        category="dev-tools"
    fi

    # Create .STATUS file
    cat > "$status_file" << EOF
project: $project_name
type: $project_type
status: ready
priority: P2
progress: 0
next: Define first task
updated: $(date +%Y-%m-%d)
category: $category
EOF

    echo -e "${GREEN}✅ Created $status_file${NC}"
    echo ""
    echo "Edit with: ${CYAN}status $project_name${NC}"
    echo "Or:        ${CYAN}$EDITOR $status_file${NC}"
}

# ═══════════════════════════════════════════════════════════════════
# SHOW STATUS FILE
# ═══════════════════════════════════════════════════════════════════

_status_show() {
    local status_file="$1"

    if [[ ! -f "$status_file" ]]; then
        echo -e "${RED}❌ No .STATUS file found${NC}"
        echo ""
        echo "Create with: ${CYAN}status $(basename $(dirname $status_file)) --create${NC}"
        return 1
    fi

    echo ""
    echo -e "${BOLD}╭─────────────────────────────────────────────╮${NC}"
    echo -e "${BOLD}│ 📋 STATUS: $(basename $(dirname $status_file))${NC}"
    echo -e "${BOLD}╰─────────────────────────────────────────────╯${NC}"
    echo ""
    cat "$status_file"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════
# QUICK UPDATE (all args provided)
# ═══════════════════════════════════════════════════════════════════

_status_quick_update() {
    local project_dir="$1"
    local new_status="$2"
    local new_priority="$3"
    local new_task="$4"
    local new_progress="$5"
    local status_file="$project_dir/.STATUS"

    # Create if doesn't exist
    if [[ ! -f "$status_file" ]]; then
        _status_create "$project_dir"
    fi

    # Update fields
    sed -i.bak "s/^status:.*/status: $new_status/" "$status_file"
    sed -i.bak "s/^priority:.*/priority: $new_priority/" "$status_file"
    sed -i.bak "s/^next:.*/next: $new_task/" "$status_file"
    sed -i.bak "s/^progress:.*/progress: $new_progress/" "$status_file"
    sed -i.bak "s/^updated:.*/updated: $(date +%Y-%m-%d)/" "$status_file"
    rm -f "${status_file}.bak"

    echo -e "${GREEN}✅ Updated $(basename $project_dir)${NC}"
    echo ""
    echo "  Status:   $new_status"
    echo "  Priority: $new_priority"
    echo "  Task:     $new_task"
    echo "  Progress: $new_progress%"
}

# ═══════════════════════════════════════════════════════════════════
# INTERACTIVE UPDATE
# ═══════════════════════════════════════════════════════════════════

_status_interactive() {
    local project_dir="$1"
    local status_file="$project_dir/.STATUS"
    local project_name=$(basename "$project_dir")

    # Create if doesn't exist
    if [[ ! -f "$status_file" ]]; then
        echo -e "${YELLOW}No .STATUS file found. Creating...${NC}"
        echo ""
        _status_create "$project_dir"
    fi

    # Read current values
    local current_status=$(grep "^status:" "$status_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')
    local current_priority=$(grep "^priority:" "$status_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')
    local current_progress=$(grep "^progress:" "$status_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')
    local current_next=$(grep "^next:" "$status_file" 2>/dev/null | cut -d: -f2- | sed 's/^[[:space:]]*//')

    echo ""
    echo -e "${BOLD}╭─────────────────────────────────────────────╮${NC}"
    echo -e "${BOLD}│ 📋 UPDATE STATUS: $project_name${NC}"
    echo -e "${BOLD}╰─────────────────────────────────────────────╯${NC}"
    echo ""

    # Status
    echo -e "${CYAN}Status?${NC} ${DIM}(active/ready/paused/blocked)${NC} [${current_status}]"
    read -r new_status
    [[ -z "$new_status" ]] && new_status="$current_status"

    # Priority
    echo ""
    echo -e "${CYAN}Priority?${NC} ${DIM}(P0/P1/P2)${NC} [${current_priority}]"
    read -r new_priority
    [[ -z "$new_priority" ]] && new_priority="$current_priority"

    # Next task
    echo ""
    echo -e "${CYAN}Next task?${NC} [${current_next}]"
    read -r new_task
    [[ -z "$new_task" ]] && new_task="$current_next"

    # Progress
    echo ""
    echo -e "${CYAN}Progress?${NC} ${DIM}(0-100)${NC} [${current_progress}]"
    read -r new_progress
    [[ -z "$new_progress" ]] && new_progress="$current_progress"

    # Update file
    sed -i.bak "s/^status:.*/status: $new_status/" "$status_file"
    sed -i.bak "s/^priority:.*/priority: $new_priority/" "$status_file"
    sed -i.bak "s/^next:.*/next: $new_task/" "$status_file"
    sed -i.bak "s/^progress:.*/progress: $new_progress/" "$status_file"
    sed -i.bak "s/^updated:.*/updated: $(date +%Y-%m-%d)/" "$status_file"
    rm -f "${status_file}.bak"

    echo ""
    echo -e "${GREEN}✅ Updated $project_name${NC}"
    echo ""
    echo "View all: ${CYAN}dash${NC}"
}

# ═══════════════════════════════════════════════════════════════════
# SHOW TEMPLATE
# ═══════════════════════════════════════════════════════════════════

_status_template() {
    cat << 'EOF'
project: project-name
type: project-type
status: ready
priority: P2
progress: 0
next: Define first task
updated: YYYY-MM-DD
category: category-name
tags: [tag1, tag2]
EOF
}

# ═══════════════════════════════════════════════════════════════════
# HELP
# ═══════════════════════════════════════════════════════════════════

_status_help() {
    local GREEN='\033[0;32m'
    local CYAN='\033[0;36m'
    local YELLOW='\033[1;33m'
    local MAGENTA='\033[0;35m'
    local BOLD='\033[1m'
    local DIM='\033[2m'
    local NC='\033[0m'

    echo ""
    echo -e "${BOLD}╭─────────────────────────────────────────────╮${NC}"
    echo -e "${BOLD}│ status - Project Status Management          │${NC}"
    echo -e "${BOLD}╰─────────────────────────────────────────────╯${NC}"
    echo ""
    echo -e "${GREEN}🔥 USAGE${NC}:"
    echo -e "  ${CYAN}status <project>${NC}                    Interactive update"
    echo -e "  ${CYAN}status <project> <status> <pri> <task> <progress>${NC}"
    echo -e "                                     Quick update"
    echo ""
    echo -e "${YELLOW}💡 EXAMPLES${NC}:"
    echo -e "  ${DIM}\$${NC} status mediationverse             ${DIM}# Interactive${NC}"
    echo -e "  ${DIM}\$${NC} status medfit active P1 \"Docs\" 60 ${DIM}# Quick${NC}"
    echo -e "  ${DIM}\$${NC} status newproject --create        ${DIM}# New .STATUS${NC}"
    echo -e "  ${DIM}\$${NC} status medfit --show              ${DIM}# View current${NC}"
    echo ""
    echo -e "${MAGENTA}📋 STATUS VALUES${NC}:"
    echo -e "  ${GREEN}active${NC}    - Currently working"
    echo -e "  ${CYAN}ready${NC}     - Planned/ready to start"
    echo -e "  ${YELLOW}paused${NC}    - On hold"
    echo -e "  ${RED}blocked${NC}   - Waiting on something"
    echo ""
    echo -e "${MAGENTA}🏷️  PRIORITY VALUES${NC}:"
    echo -e "  ${RED}P0${NC}        - Urgent/critical"
    echo -e "  ${YELLOW}P1${NC}        - High priority"
    echo -e "  ${CYAN}P2${NC}        - Normal priority"
    echo ""
    echo -e "${MAGENTA}🔗 RELATED COMMANDS${NC}:"
    echo -e "  ${CYAN}dash${NC}                Show all projects"
    echo -e "  ${CYAN}work <name>${NC}         Start working"
    echo -e "  ${CYAN}js${NC}                  Just start (picks for you)"
    echo ""
}
