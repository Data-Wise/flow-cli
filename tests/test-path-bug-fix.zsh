#!/usr/bin/env zsh
# tests/test-path-bug-fix.zsh
# Regression test for the $path -> $project_path bug (SPEC-planning-coordination
# §3.0, ORCHESTRATE-planning-coordination.md Phase 0).
#
# _flow_get_project_fallback (lib/atlas-bridge.zsh:397) deliberately emits
# `project_path=` (never `path=`) to avoid colliding with ZSH's PATH-tied
# `$path` array. But commands/morning.zsh:83-89 and commands/adhd.zsh:103-108
# read `$path` after `eval "$info"` instead of `$project_path` — so `$path`
# resolves to ZSH's PATH array (always non-empty), the `.STATUS` file lookup
# silently fails, and focus/progress render blank while the project-type
# icon falls back to generic even for a project with clear type markers.
#
# This suite proves that broken behavior is fixed, isolated from the Phase 1
# shared-accessor refactor.

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
source "$SCRIPT_DIR/test-framework.zsh" || { echo "ERROR: Cannot source test-framework.zsh"; exit 1 }

# ============================================================================
# SETUP
# ============================================================================

setup() {
    if [[ ! -f "$PROJECT_ROOT/flow.plugin.zsh" ]]; then
        echo "${RED}ERROR: Cannot find project root${RESET}"
        exit 1
    fi

    FLOW_QUIET=1
    FLOW_ATLAS_ENABLED=no
    FLOW_PLUGIN_DIR="$PROJECT_ROOT"
    source "$PROJECT_ROOT/flow.plugin.zsh" 2>/dev/null || {
        echo "${RED}Plugin failed to load${RESET}"
        exit 1
    }

    # Force filesystem fallback regardless of env (memory:
    # capture-real-agenda-output-for-docs — FLOW_ATLAS_ENABLED=no alone is
    # known-insufficient; override the capability probe directly).
    _flow_has_atlas() { return 1 }

    exec < /dev/null

    # Isolated project root — a single project with nonzero progress, a
    # focus line, and R-package markers (for the icon assertion) so the
    # project-type default ("generic") can't accidentally look correct.
    TEST_ROOT=$(mktemp -d)
    PROJECT_NAME="pathbugtest"
    PROJECT_DIR="$TEST_ROOT/$PROJECT_NAME"
    mkdir -p "$PROJECT_DIR"
    cat > "$PROJECT_DIR/.STATUS" <<'EOF'
## Status: active
## Focus: Ship the widget
## Progress: 42
EOF
    # R-package markers so _flow_detect_project_type resolves to
    # "r-package" (icon 📦) only when given the correct directory.
    touch "$PROJECT_DIR/DESCRIPTION" "$PROJECT_DIR/NAMESPACE"

    FLOW_PROJECTS_ROOT="$TEST_ROOT"
}

cleanup() {
    reset_mocks
    unset -f _flow_has_atlas 2>/dev/null
    [[ -n "$TEST_ROOT" && -d "$TEST_ROOT" ]] && rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

# ============================================================================
# TESTS: next (commands/adhd.zsh) reads project_path, not $path
# ============================================================================

test_next_shows_focus() {
    test_case "next shows the project's Focus line (not blank)"
    local output=$(next 2>&1)
    assert_contains "$output" "Ship the widget" \
        "next should render '## Focus:' from .STATUS via \$project_path" && test_pass
}

test_next_shows_correct_icon() {
    test_case "next shows the r-package icon (project type resolved from real path)"
    local output=$(next 2>&1)
    assert_contains "$output" "📦" \
        "next should detect r-package type via \$project_path, not the generic fallback" && test_pass
}

# ============================================================================
# TESTS: morning (commands/morning.zsh) reads project_path, not $path
# ============================================================================

test_morning_shows_focus() {
    test_case "morning shows the project's Focus line (not blank)"
    local output=$(morning 2>&1)
    assert_contains "$output" "Ship the widget" \
        "morning should render '## Focus:' from .STATUS via \$project_path" && test_pass
}

test_morning_shows_progress() {
    test_case "morning shows the project's Progress percentage (not blank)"
    local output=$(morning 2>&1)
    assert_contains "$output" "42%" \
        "morning should render '## Progress:' from .STATUS via \$project_path" && test_pass
}

test_morning_shows_correct_icon() {
    test_case "morning shows the r-package icon (project type resolved from real path)"
    local output=$(morning 2>&1)
    assert_contains "$output" "📦" \
        "morning should detect r-package type via \$project_path, not the generic fallback" && test_pass
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    test_suite "Path Bug Fix Tests (\$path -> \$project_path)"

    setup

    echo "${CYAN}--- next (adhd.zsh) ---${RESET}"
    test_next_shows_focus
    test_next_shows_correct_icon

    echo ""
    echo "${CYAN}--- morning (morning.zsh) ---${RESET}"
    test_morning_shows_focus
    test_morning_shows_progress
    test_morning_shows_correct_icon

    cleanup
    test_suite_end
    exit $?
}

main "$@"
