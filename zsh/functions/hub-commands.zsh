#!/usr/bin/env zsh
# HUB COMMANDS - Project Hub Navigation
# Part of: zsh-configuration
# Purpose: Quick navigation between project hubs
#
# Commands:
#   focus     - Show today's focus (.STATUS)
#   week      - Show this week's plan
#   hub       - Project hub navigation
#   devhub    - Dev planning hub navigation
#   rhub      - R packages hub navigation

emulate -L zsh

# Hub locations (override in .zshrc.local if needed)
HUB_PROJECT_HUB="${HUB_PROJECT_HUB:-$HOME/projects/project-hub}"
HUB_DEV_PLANNING="${HUB_DEV_PLANNING:-$HOME/projects/dev-tools/dev-planning}"
HUB_R_PLANNING="${HUB_R_PLANNING:-$HOME/projects/r-packages/mediation-planning}"

# -----------------------------------------------------------------------------
# focus - Show today's focus
# -----------------------------------------------------------------------------
focus() {
    local status_file="$HUB_PROJECT_HUB/.STATUS"

    if [[ -f "$status_file" ]]; then
        echo "━━━ Today's Focus ━━━"
        cat "$status_file"
    else
        echo "No .STATUS file found at $status_file"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# week - Show this week's plan
# -----------------------------------------------------------------------------
week() {
    local week_num=$(date +%V)
    local week_file="$HUB_PROJECT_HUB/weekly/WEEK-${week_num}.md"

    if [[ -f "$week_file" ]]; then
        echo "━━━ Week $week_num Plan ━━━"
        cat "$week_file"
    else
        echo "No weekly file found: $week_file"
        echo "Create with: hub-new-week"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# hub - Project hub navigation
# -----------------------------------------------------------------------------
hub() {
    local cmd="${1:-view}"

    case "$cmd" in
        view|v)
            cat "$HUB_PROJECT_HUB/PROJECT-HUB.md"
            ;;
        edit|e)
            ${EDITOR:-vim} "$HUB_PROJECT_HUB/PROJECT-HUB.md"
            ;;
        open|o)
            open "$HUB_PROJECT_HUB"
            ;;
        cd|c)
            cd "$HUB_PROJECT_HUB"
            ;;
        *)
            echo "Usage: hub [view|edit|open|cd]"
            ;;
    esac
}

# -----------------------------------------------------------------------------
# devhub - Dev planning hub navigation
# -----------------------------------------------------------------------------
devhub() {
    local cmd="${1:-view}"

    case "$cmd" in
        view|v)
            cat "$HUB_DEV_PLANNING/PROJECT-HUB.md"
            ;;
        edit|e)
            ${EDITOR:-vim} "$HUB_DEV_PLANNING/PROJECT-HUB.md"
            ;;
        open|o)
            open "$HUB_DEV_PLANNING"
            ;;
        cd|c)
            cd "$HUB_DEV_PLANNING"
            ;;
        todos|t)
            cat "$HUB_DEV_PLANNING/TODOS.md"
            ;;
        *)
            echo "Usage: devhub [view|edit|open|cd|todos]"
            ;;
    esac
}

# -----------------------------------------------------------------------------
# rhub - R packages hub navigation
# -----------------------------------------------------------------------------
rhub() {
    local cmd="${1:-view}"

    case "$cmd" in
        view|v)
            cat "$HUB_R_PLANNING/PROJECT-HUB.md"
            ;;
        edit|e)
            ${EDITOR:-vim} "$HUB_R_PLANNING/PROJECT-HUB.md"
            ;;
        open|o)
            open "$HUB_R_PLANNING"
            ;;
        cd|c)
            cd "$HUB_R_PLANNING"
            ;;
        todos|t)
            cat "$HUB_R_PLANNING/TODOS.md"
            ;;
        *)
            echo "Usage: rhub [view|edit|open|cd|todos]"
            ;;
    esac
}

# -----------------------------------------------------------------------------
# hub-new-week - Create new weekly file
# -----------------------------------------------------------------------------
hub-new-week() {
    local week_num=$(date +%V)
    local week_file="$HUB_PROJECT_HUB/weekly/WEEK-${week_num}.md"

    if [[ -f "$week_file" ]]; then
        echo "Week $week_num file already exists: $week_file"
        return 1
    fi

    cat > "$week_file" << EOF
# Week $week_num

> **Dates:** $(date -v-$(date +%u)d+1d +%Y-%m-%d) to $(date -v-$(date +%u)d+7d +%Y-%m-%d)

---

## Top 3 Priorities

1. 🔴 **[Domain]:** [Task]
2. 🟡 **[Domain]:** [Task]
3. 🟢 **[Domain]:** [Task]

---

## By Domain

### R Packages
- [ ]

### Dev Tools
- [ ]

### Research
- [ ]

### Teaching
- [ ]

---

## Notes

---

*Created: $(date +%Y-%m-%d)*
EOF

    echo "Created: $week_file"
    ${EDITOR:-vim} "$week_file"
}

# -----------------------------------------------------------------------------
# Aliases
# -----------------------------------------------------------------------------
alias f='focus'
alias wk='week'
alias dh='devhub'
alias rh='rhub'
