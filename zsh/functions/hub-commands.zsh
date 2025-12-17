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
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        cat <<'EOF'
Usage: focus

Show today's focus from the project hub .STATUS file.

Alias: f

See also: week, hub
EOF
        return 0
    fi

    local status_file="$HUB_PROJECT_HUB/.STATUS"

    if [[ -f "$status_file" ]]; then
        echo "━━━ Today's Focus ━━━"
        cat "$status_file"
    else
        echo "focus: no .STATUS file found at $status_file" >&2
        echo "Create one in $HUB_PROJECT_HUB/.STATUS" >&2
        return 1
    fi
}

# -----------------------------------------------------------------------------
# week - Show this week's plan
# -----------------------------------------------------------------------------
week() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        cat <<'EOF'
Usage: week

Show this week's plan from the project hub weekly file.

Alias: wk

See also: focus, hub, hub-new-week
EOF
        return 0
    fi

    local week_num=$(date +%V)
    local week_file="$HUB_PROJECT_HUB/weekly/WEEK-${week_num}.md"

    if [[ -f "$week_file" ]]; then
        echo "━━━ Week $week_num Plan ━━━"
        cat "$week_file"
    else
        echo "week: no weekly file found: $week_file" >&2
        echo "Create with: hub-new-week" >&2
        return 1
    fi
}

# -----------------------------------------------------------------------------
# hub - Project hub navigation
# -----------------------------------------------------------------------------
hub() {
    local cmd="${1:-view}"

    case "$cmd" in
        -h|--help|help)
            cat <<'EOF'
Usage: hub [subcommand]

Navigate the master project hub.

Subcommands:
  view (v)    Display PROJECT-HUB.md (default)
  edit (e)    Open dashboard in editor
  open (o)    Open directory in Finder
  cd (c)      Change to hub directory
  help        Show this help

Examples:
  hub         # View dashboard
  hub edit    # Edit dashboard
  hub cd      # Go to hub directory

See also: devhub, rhub, focus, week
EOF
            return 0
            ;;
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
            echo "hub: unknown subcommand '$cmd'" >&2
            echo "Run 'hub help' for usage" >&2
            return 1
            ;;
    esac
}

# -----------------------------------------------------------------------------
# devhub - Dev planning hub navigation
# -----------------------------------------------------------------------------
devhub() {
    local cmd="${1:-view}"

    case "$cmd" in
        -h|--help|help)
            cat <<'EOF'
Usage: devhub [subcommand]

Navigate the dev tools planning hub.

Subcommands:
  view (v)    Display PROJECT-HUB.md (default)
  edit (e)    Open dashboard in editor
  open (o)    Open directory in Finder
  cd (c)      Change to hub directory
  todos (t)   Show TODOS.md
  help        Show this help

Alias: dh

Examples:
  devhub         # View dashboard
  devhub todos   # Show task list
  dh cd          # Go to hub directory

See also: hub, rhub, focus
EOF
            return 0
            ;;
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
            echo "devhub: unknown subcommand '$cmd'" >&2
            echo "Run 'devhub help' for usage" >&2
            return 1
            ;;
    esac
}

# -----------------------------------------------------------------------------
# rhub - R packages hub navigation
# -----------------------------------------------------------------------------
rhub() {
    local cmd="${1:-view}"

    case "$cmd" in
        -h|--help|help)
            cat <<'EOF'
Usage: rhub [subcommand]

Navigate the R packages planning hub (mediation-planning).

Subcommands:
  view (v)    Display PROJECT-HUB.md (default)
  edit (e)    Open dashboard in editor
  open (o)    Open directory in Finder
  cd (c)      Change to hub directory
  todos (t)   Show TODOS.md
  help        Show this help

Alias: rh

Examples:
  rhub         # View dashboard
  rhub todos   # Show task list
  rh cd        # Go to hub directory

See also: hub, devhub, focus
EOF
            return 0
            ;;
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
            echo "rhub: unknown subcommand '$cmd'" >&2
            echo "Run 'rhub help' for usage" >&2
            return 1
            ;;
    esac
}

# -----------------------------------------------------------------------------
# hub-new-week - Create new weekly file
# -----------------------------------------------------------------------------
hub-new-week() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        cat <<'EOF'
Usage: hub-new-week

Create a new weekly planning file for the current week.

The file is created at: project-hub/weekly/WEEK-XX.md

See also: week, hub
EOF
        return 0
    fi

    local week_num=$(date +%V)
    local week_file="$HUB_PROJECT_HUB/weekly/WEEK-${week_num}.md"

    if [[ -f "$week_file" ]]; then
        echo "hub-new-week: Week $week_num file already exists: $week_file" >&2
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
