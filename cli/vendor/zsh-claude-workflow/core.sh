#!/usr/bin/env zsh
# core.sh - Core utilities for zsh-claude-workflow

# Colors for output
autoload -U colors && colors

# Print functions
print_success() {
    echo "${fg[green]}✓${reset_color} $1"
}

print_error() {
    echo "${fg[red]}✗${reset_color} $1" >&2
}

print_info() {
    echo "${fg[blue]}ℹ${reset_color} $1"
}

print_warning() {
    echo "${fg[yellow]}⚠${reset_color} $1"
}

print_header() {
    echo ""
    echo "${fg[cyan]}${(l:${#1}::=:):-}${reset_color}"
    echo "${fg[cyan]}$1${reset_color}"
    echo "${fg[cyan]}${(l:${#1}::=:):-}${reset_color}"
    echo ""
}

# Check if we're in a git repository
is_git_repo() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1
    return $?
}

# Get git root directory
get_git_root() {
    if is_git_repo; then
        git rev-parse --show-toplevel
    else
        return 1
    fi
}

# Check if file exists
file_exists() {
    [[ -f "$1" ]]
}

# Check if directory exists
dir_exists() {
    [[ -d "$1" ]]
}

# Get relative path from current directory
get_relative_path() {
    local target="$1"
    local current="${2:-$PWD}"

    if command -v realpath >/dev/null 2>&1; then
        realpath --relative-to="$current" "$target" 2>/dev/null || echo "$target"
    else
        echo "$target"
    fi
}

# Find file in current directory or parent directories
find_up() {
    local filename="$1"
    local dir="$PWD"

    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/$filename" ]]; then
            echo "$dir/$filename"
            return 0
        fi
        dir=$(dirname "$dir")
    done

    return 1
}

# Functions are available when this file is sourced
# No need to export in zsh
