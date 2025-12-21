#!/usr/bin/env zsh
# project-detector.sh - Detect project types

# Source core utilities
source "${0:A:h}/core.sh"

# Detect if current directory is an R package
is_r_package() {
    local dir="${1:-$PWD}"
    [[ -f "$dir/DESCRIPTION" ]] && grep -q "^Package:" "$dir/DESCRIPTION" 2>/dev/null
}

# Detect if current directory is a Quarto project
is_quarto_project() {
    local dir="${1:-$PWD}"
    [[ -f "$dir/_quarto.yml" ]] || [[ -f "$dir/_quarto.yaml" ]] || \
    [[ -f "$dir/index.qmd" ]] || [[ -f "$dir/README.qmd" ]]
}

# Detect if current directory is a Quarto extension
is_quarto_extension() {
    local dir="${1:-$PWD}"
    [[ -f "$dir/_extension.yml" ]] || [[ -f "$dir/_extensions.yml" ]]
}

# Detect if current directory is a research project (has LaTeX or specific structure)
is_research_project() {
    local dir="${1:-$PWD}"
    [[ -f "$dir/main.tex" ]] || [[ -f "$dir/manuscript.tex" ]] || \
    [[ -d "$dir/literature" ]] || [[ -f "$dir/references.bib" ]]
}

# Detect if current directory is a general project (has .git)
is_general_project() {
    local dir="${1:-$PWD}"
    [[ -d "$dir/.git" ]]
}

# Detect if current directory contains Claude instructions
has_claude_instructions() {
    local dir="${1:-$PWD}"
    [[ -f "$dir/CLAUDE.md" ]] || [[ -f "$dir/.claude/CLAUDE.md" ]] || \
    [[ -d "$dir/.claude" ]]
}

# Get project type (returns: rpkg, quarto, quarto-ext, research, project, unknown)
get_project_type() {
    local dir="${1:-$PWD}"

    if is_r_package "$dir"; then
        echo "rpkg"
    elif is_quarto_extension "$dir"; then
        echo "quarto-ext"
    elif is_quarto_project "$dir"; then
        echo "quarto"
    elif is_research_project "$dir"; then
        echo "research"
    elif is_general_project "$dir"; then
        echo "project"
    else
        echo "unknown"
    fi
}

# Get project name
get_project_name() {
    local dir="${1:-$PWD}"
    local project_type=$(get_project_type "$dir")

    case "$project_type" in
        rpkg)
            # Get package name from DESCRIPTION
            grep "^Package:" "$dir/DESCRIPTION" 2>/dev/null | cut -d' ' -f2 | tr -d '\r'
            ;;
        quarto|quarto-ext)
            # Try to get from _quarto.yml, otherwise use directory name
            if [[ -f "$dir/_quarto.yml" ]]; then
                grep "^  title:" "$dir/_quarto.yml" 2>/dev/null | sed 's/^  title: "\?\([^"]*\)"\?/\1/' | tr -d '\r'
            else
                basename "$dir"
            fi
            ;;
        research|project)
            basename "$dir"
            ;;
        *)
            basename "$dir"
            ;;
    esac
}

# Get project description
get_project_description() {
    local dir="${1:-$PWD}"
    local project_type=$(get_project_type "$dir")

    case "$project_type" in
        rpkg)
            # Get title from DESCRIPTION
            grep "^Title:" "$dir/DESCRIPTION" 2>/dev/null | cut -d':' -f2- | sed 's/^ *//' | tr -d '\r'
            ;;
        quarto|quarto-ext)
            # Try to get description from _quarto.yml
            if [[ -f "$dir/_quarto.yml" ]]; then
                grep "^  description:" "$dir/_quarto.yml" 2>/dev/null | sed 's/^  description: "\?\([^"]*\)"\?/\1/' | tr -d '\r'
            fi
            ;;
        *)
            # Try README first line
            if [[ -f "$dir/README.md" ]]; then
                head -n 3 "$dir/README.md" | grep -v "^#" | grep -v "^$" | head -n 1
            fi
            ;;
    esac
}

# Get project icon/emoji
get_project_icon() {
    local project_type="$1"

    case "$project_type" in
        rpkg) echo "📦" ;;
        quarto) echo "📄" ;;
        quarto-ext) echo "🔌" ;;
        research) echo "🔬" ;;
        project) echo "📁" ;;
        *) echo "❓" ;;
    esac
}

# Get project type label
get_project_type_label() {
    local project_type="$1"

    case "$project_type" in
        rpkg) echo "R Package" ;;
        quarto) echo "Quarto Project" ;;
        quarto-ext) echo "Quarto Extension" ;;
        research) echo "Research Project" ;;
        project) echo "Git Project" ;;
        *) echo "Unknown" ;;
    esac
}

# Detect storage location (local, google-drive, onedrive, dropbox)
get_storage_location() {
    local dir="${1:-$PWD}"

    case "$dir" in
        *"GoogleDrive"*)
            echo "google-drive"
            ;;
        *"OneDrive"*)
            echo "onedrive"
            ;;
        *"Dropbox"*)
            echo "dropbox"
            ;;
        *)
            echo "local"
            ;;
    esac
}

# Get storage tier (active, stable, archive, scratch)
get_storage_tier() {
    local dir="${1:-$PWD}"

    case "$dir" in
        */active/*)
            echo "active"
            ;;
        */stable/*)
            echo "stable"
            ;;
        */archive/*)
            echo "archive"
            ;;
        */scratch/*)
            echo "scratch"
            ;;
        *"-archive"*)
            echo "archive"
            ;;
        *"-stable"*)
            echo "stable"
            ;;
        *)
            echo "primary"
            ;;
    esac
}

# Functions are available when this file is sourced
# No need to export in zsh
