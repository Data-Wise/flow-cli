#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# V / VIBE - Utility Functions
# ══════════════════════════════════════════════════════════════════════════════
#
# File:         ~/.config/zsh/functions/v-utils.zsh
# Version:      1.0
# Date:         2025-12-15
# Part of:      V / Vibe Workflow Automation System
#
# Purpose:      Shared helper functions for v/vibe dispatcher
#
# ══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════
# PROJECT TYPE DETECTION
# ═══════════════════════════════════════════════════════════════════

_v_detect_project_type() {
    # Detect project type based on files in current directory
    # Returns: r-package, quarto, node, python, go, rust, or unknown

    if [[ -f "DESCRIPTION" ]] && [[ -f "NAMESPACE" ]]; then
        echo "r-package"
    elif [[ -f "_quarto.yml" ]] || [[ -f "_quarto.yaml" ]]; then
        echo "quarto"
    elif [[ -f "package.json" ]]; then
        echo "node"
    elif [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]]; then
        echo "python"
    elif [[ -f "go.mod" ]]; then
        echo "go"
    elif [[ -f "Cargo.toml" ]]; then
        echo "rust"
    else
        echo "unknown"
    fi
}

# ═══════════════════════════════════════════════════════════════════
# ECOSYSTEM DETECTION
# ═══════════════════════════════════════════════════════════════════

_v_detect_ecosystem() {
    # Detect if current project is part of an ecosystem
    # Returns: ecosystem name or "none"

    local pwd_path="$PWD"

    # Check if we're in mediationverse
    if [[ "$pwd_path" == */r-packages/active/* ]]; then
        echo "mediationverse"
        return 0
    fi

    # Check if we're in teaching
    if [[ "$pwd_path" == */teaching/* ]]; then
        echo "teaching"
        return 0
    fi

    # Check if we're in research
    if [[ "$pwd_path" == */research/* ]]; then
        echo "research"
        return 0
    fi

    echo "none"
}

# ═══════════════════════════════════════════════════════════════════
# YAML PARSING (minimal)
# ═══════════════════════════════════════════════════════════════════

_v_yaml_get() {
    # Simple YAML value extraction
    # Usage: _v_yaml_get <file> <key>

    local file="$1"
    local key="$2"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    # Simple grep-based extraction
    grep "^${key}:" "$file" | head -1 | cut -d: -f2- | sed 's/^ *//' | sed 's/ *$//'
}

# ═══════════════════════════════════════════════════════════════════
# PLACEHOLDER FOR FUTURE UTILITIES
# ═══════════════════════════════════════════════════════════════════

# Additional helper functions will be added as needed in future phases:
# - Ecosystem YAML parsing
# - Sprint/roadmap management
# - Test framework detection
# - Coverage reporting
# - Dependency graph generation
