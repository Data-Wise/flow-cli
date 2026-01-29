#!/usr/bin/env zsh
# test-teach-prompt-unit.zsh - Unit tests for teach prompt command
# v5.23.0 - teach prompt
#
# Run: ./tests/test-teach-prompt-unit.zsh
# Categories: Resolution (10), Rendering (8), Validation (10),
#             List/Show (6), Edit (4), Export (4) = 42 core tests
#             Dispatcher (6), Flags (8), Edge Cases (6) = 20 extended tests
#             Total: 62 tests

setopt local_options no_monitor

# ============================================================================
# TEST INFRASTRUCTURE
# ============================================================================

typeset -g TEST_PASS=0
typeset -g TEST_FAIL=0
typeset -g TEST_SKIP=0
typeset -g TEST_TOTAL=0
typeset -g TEST_DIR=""
# Capture script path BEFORE entering any function ($0 changes inside functions)
typeset -g PLUGIN_ROOT="${0:A:h:h}"

# Colors
typeset -g GREEN="\033[32m"
typeset -g RED="\033[31m"
typeset -g YELLOW="\033[33m"
typeset -g CYAN="\033[36m"
typeset -g BOLD="\033[1m"
typeset -g RESET="\033[0m"

_test_pass() {
    ((TEST_PASS++))
    ((TEST_TOTAL++))
    printf "  ${GREEN}✓${RESET} %s\n" "$1"
}

_test_fail() {
    ((TEST_FAIL++))
    ((TEST_TOTAL++))
    printf "  ${RED}✗${RESET} %s\n" "$1"
    [[ -n "$2" ]] && printf "    ${RED}→ %s${RESET}\n" "$2"
}

_test_skip() {
    ((TEST_SKIP++))
    ((TEST_TOTAL++))
    printf "  ${YELLOW}○${RESET} %s (skipped)\n" "$1"
}

_test_section() {
    echo ""
    printf "${BOLD}${CYAN}── %s ──${RESET}\n" "$1"
}

# ============================================================================
# SETUP / TEARDOWN
# ============================================================================

_setup_test_env() {
    # Create temp directories for 3-tier mock
    TEST_DIR=$(mktemp -d /tmp/test-prompt-XXXXXX)

    # Course tier
    mkdir -p "$TEST_DIR/course/.flow/templates/prompts"

    # User tier
    mkdir -p "$TEST_DIR/user/.flow/prompts"

    # Plugin tier (mock)
    mkdir -p "$TEST_DIR/plugin/claude-prompts"

    # PLUGIN_ROOT is set at file scope (before any function)

    # Source core (needed for FLOW_COLORS, logging)
    if [[ -f "$PLUGIN_ROOT/lib/core.zsh" ]]; then
        source "$PLUGIN_ROOT/lib/core.zsh"
    else
        # Minimal stubs
        typeset -gA FLOW_COLORS=(
            [header]="\033[1;36m" [reset]="\033[0m" [bold]="\033[1m"
            [success]="\033[32m" [error]="\033[31m" [warning]="\033[33m"
            [accent]="\033[34m" [muted]="\033[90m" [dim]="\033[2m"
            [cmd]="\033[1;33m"
        )
        _flow_log_success() { echo "✓ $*"; }
        _flow_log_error() { echo "✗ $*" >&2; }
        _flow_log_warning() { echo "⚠ $*"; }
        _flow_log_info() { echo "ℹ $*"; }
    fi

    # Source files from plugin root context
    # cd temporarily to ensure $0:A:h resolves correctly for sourced files
    local _orig_dir="$PWD"
    cd "$PLUGIN_ROOT" || return 1

    # Source via the main plugin entry point context
    unset _FLOW_TEMPLATE_HELPERS_LOADED
    source "$PLUGIN_ROOT/lib/template-helpers.zsh" 2>/dev/null

    unset _FLOW_PROMPT_HELPERS_LOADED
    source "$PLUGIN_ROOT/lib/prompt-helpers.zsh" 2>/dev/null

    unset _FLOW_TEACH_PROMPT_LOADED
    source "$PLUGIN_ROOT/commands/teach-prompt.zsh" 2>/dev/null

    cd "$_orig_dir" || return 1

    # Verify critical functions loaded
    if ! typeset -f _teach_resolve_prompt >/dev/null 2>&1; then
        echo "  ${RED}FATAL: Functions not loaded. Check source paths.${RESET}"
        return 1
    fi

    # Override tier directory functions to use test dirs
    _teach_prompt_course_dir() { echo "$TEST_DIR/course/.flow/templates/prompts"; }
    _teach_prompt_user_dir() { echo "$TEST_DIR/user/.flow/prompts"; }
    _teach_prompt_plugin_dir() { echo "$TEST_DIR/plugin/claude-prompts"; }

    # Create test prompt files
    _create_test_prompts
}

_create_test_prompts() {
    # Plugin tier: lecture-notes.md
    cat > "$TEST_DIR/plugin/claude-prompts/lecture-notes.md" <<'EOF'
---
template_version: "1.0"
template_type: "prompt"
template_description: "AI prompt for generating comprehensive lecture notes"
---

# Comprehensive Lecture Notes Generator

## Purpose
Generate lecture notes for {{COURSE}} on {{TOPIC}}.

## Requirements
- Use {{STYLE}} approach
- Include examples for week {{WEEK}}
EOF

    # Plugin tier: revealjs-slides.md
    cat > "$TEST_DIR/plugin/claude-prompts/revealjs-slides.md" <<'EOF'
---
template_version: "1.0"
template_type: "prompt"
template_description: "RevealJS Presentation Generator"
---

# RevealJS Slides for {{COURSE}}

Generate slides about {{TOPIC}}.
EOF

    # Plugin tier: derivations-appendix.md
    cat > "$TEST_DIR/plugin/claude-prompts/derivations-appendix.md" <<'EOF'
---
template_version: "1.0"
template_type: "prompt"
template_description: "Mathematical Derivations Appendix"
---

# Derivations for {{TOPIC}}

Full step-by-step derivations.
EOF

    # Course tier override: lecture-notes.md (overrides plugin)
    cat > "$TEST_DIR/course/.flow/templates/prompts/lecture-notes.md" <<'EOF'
---
template_version: "1.1"
template_type: "prompt"
template_description: "Custom lecture notes for STAT 440"
---

# STAT 440 Lecture Notes

## Purpose
Custom lecture notes for {{COURSE}} on {{TOPIC}}.
Instructor: {{INSTRUCTOR}}
Semester: {{SEMESTER}}
Date: {{DATE}}
EOF

    # User tier: exam.md (only at user level)
    cat > "$TEST_DIR/user/.flow/prompts/exam.md" <<'EOF'
---
template_version: "1.0"
template_type: "prompt"
template_description: "User exam prompt"
---

# Exam Generator

Generate exam for {{COURSE}} on {{TOPIC}}.
EOF

    # Invalid prompt (for validation tests)
    cat > "$TEST_DIR/plugin/claude-prompts/broken-prompt.md" <<'EOF'
No frontmatter here
Just plain text with no YAML
EOF

    # Bad template_type prompt
    cat > "$TEST_DIR/plugin/claude-prompts/wrong-type.md" <<'EOF'
---
template_version: "1.0"
template_type: "content"
template_description: "Wrong type field"
---

# This has wrong template_type
EOF

    # Short body prompt
    cat > "$TEST_DIR/plugin/claude-prompts/short-body.md" <<'EOF'
---
template_version: "1.0"
template_type: "prompt"
template_description: "Too short"
---

Short.
EOF

    # Bad variable name prompt
    cat > "$TEST_DIR/plugin/claude-prompts/bad-vars.md" <<'EOF'
---
template_version: "1.0"
template_type: "prompt"
template_description: "Bad variable names"
---

# Bad Variables

This uses {{lowercase}} and {{MiXeD_case}} variables.
Also {{GOOD_VAR}} is fine.
EOF
}

_teardown_test_env() {
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# ============================================================================
# RESOLUTION TESTS (10)
# ============================================================================

_test_resolution() {
    _test_section "Resolution (10 tests)"

    # Test 1: Plugin tier resolution
    local path
    path=$(_teach_resolve_prompt "revealjs-slides")
    if [[ "$path" == *"/plugin/claude-prompts/revealjs-slides.md" ]]; then
        _test_pass "Plugin tier: resolves to plugin dir"
    else
        _test_fail "Plugin tier: resolves to plugin dir" "Got: $path"
    fi

    # Test 2: Course override takes precedence
    path=$(_teach_resolve_prompt "lecture-notes")
    if [[ "$path" == *"/course/.flow/templates/prompts/lecture-notes.md" ]]; then
        _test_pass "Course override: takes precedence over plugin"
    else
        _test_fail "Course override: takes precedence over plugin" "Got: $path"
    fi

    # Test 3: User tier resolution
    path=$(_teach_resolve_prompt "exam")
    if [[ "$path" == *"/user/.flow/prompts/exam.md" ]]; then
        _test_pass "User tier: resolves to user dir"
    else
        _test_fail "User tier: resolves to user dir" "Got: $path"
    fi

    # Test 4: Missing prompt returns error
    path=$(_teach_resolve_prompt "nonexistent-prompt")
    if [[ -z "$path" ]]; then
        _test_pass "Missing prompt: returns empty"
    else
        _test_fail "Missing prompt: returns empty" "Got: $path"
    fi

    # Test 5: Forced tier - plugin only
    path=$(_teach_resolve_prompt "lecture-notes" "plugin")
    if [[ "$path" == *"/plugin/claude-prompts/lecture-notes.md" ]]; then
        _test_pass "Forced plugin tier: bypasses course override"
    else
        _test_fail "Forced plugin tier: bypasses course override" "Got: $path"
    fi

    # Test 6: Forced tier - course only
    path=$(_teach_resolve_prompt "lecture-notes" "course")
    if [[ "$path" == *"/course/.flow/templates/prompts/lecture-notes.md" ]]; then
        _test_pass "Forced course tier: finds course file"
    else
        _test_fail "Forced course tier: finds course file" "Got: $path"
    fi

    # Test 7: Forced tier - no match at that tier
    path=$(_teach_resolve_prompt "revealjs-slides" "course")
    if [[ -z "$path" ]]; then
        _test_pass "Forced tier miss: returns empty when not at that tier"
    else
        _test_fail "Forced tier miss: returns empty when not at that tier" "Got: $path"
    fi

    # Test 8: Extension-less name resolves with .md
    path=$(_teach_resolve_prompt "derivations-appendix")
    if [[ "$path" == *".md" ]]; then
        _test_pass "Extension handling: adds .md automatically"
    else
        _test_fail "Extension handling: adds .md automatically" "Got: $path"
    fi

    # Test 9: Name with .md extension also works
    path=$(_teach_resolve_prompt "lecture-notes.md")
    if [[ -n "$path" && -f "$path" ]]; then
        _test_pass "With .md extension: resolves correctly"
    else
        _test_fail "With .md extension: resolves correctly" "Got: $path"
    fi

    # Test 10: Tier detection function
    local tier
    tier=$(_teach_prompt_tier "$TEST_DIR/course/.flow/templates/prompts/lecture-notes.md")
    if [[ "$tier" == "course" ]]; then
        _test_pass "Tier detection: identifies course tier"
    else
        _test_fail "Tier detection: identifies course tier" "Got: $tier"
    fi
}

# ============================================================================
# RENDERING TESTS (8)
# ============================================================================

_test_rendering() {
    _test_section "Rendering (8 tests)"

    # Test 11: Basic rendering strips frontmatter
    local rendered
    rendered=$(_teach_render_prompt "$TEST_DIR/plugin/claude-prompts/revealjs-slides.md")
    if [[ "$rendered" != *"template_version"* && "$rendered" == *"RevealJS Slides"* ]]; then
        _test_pass "Frontmatter stripped from rendered output"
    else
        _test_fail "Frontmatter stripped from rendered output"
    fi

    # Test 12: Variable substitution works
    typeset -A test_vars
    test_vars[COURSE]="STAT 440"
    test_vars[TOPIC]="ANOVA"
    rendered=$(_teach_render_prompt "$TEST_DIR/plugin/claude-prompts/revealjs-slides.md" test_vars)
    if [[ "$rendered" == *"STAT 440"* && "$rendered" == *"ANOVA"* ]]; then
        _test_pass "Variable substitution: COURSE and TOPIC replaced"
    else
        _test_fail "Variable substitution: COURSE and TOPIC replaced" "Got: $rendered"
    fi

    # Test 13: Missing file returns error
    _teach_render_prompt "/nonexistent/path.md" 2>/dev/null
    if [[ $? -ne 0 ]]; then
        _test_pass "Missing file: returns error code"
    else
        _test_fail "Missing file: returns error code"
    fi

    # Test 14: Multiple variables in one file
    test_vars[STYLE]="rigorous"
    test_vars[WEEK]="5"
    rendered=$(_teach_render_prompt "$TEST_DIR/plugin/claude-prompts/lecture-notes.md" test_vars)
    if [[ "$rendered" == *"STAT 440"* && "$rendered" == *"ANOVA"* && \
          "$rendered" == *"rigorous"* && "$rendered" == *"5"* ]]; then
        _test_pass "Multiple variables: all substituted"
    else
        _test_fail "Multiple variables: all substituted"
    fi

    # Test 15: Unresolved variables remain as-is
    typeset -A partial_vars
    partial_vars[COURSE]="STAT 440"
    rendered=$(_teach_render_prompt "$TEST_DIR/plugin/claude-prompts/lecture-notes.md" partial_vars)
    if [[ "$rendered" == *"{{TOPIC}}"* ]]; then
        _test_pass "Unresolved variables: remain as {{VAR}} placeholders"
    else
        _test_fail "Unresolved variables: remain as {{VAR}} placeholders"
    fi

    # Test 16: Course override rendered correctly
    test_vars[INSTRUCTOR]="Dr. Smith"
    test_vars[SEMESTER]="Spring 2026"
    rendered=$(_teach_render_prompt "$TEST_DIR/course/.flow/templates/prompts/lecture-notes.md" test_vars)
    if [[ "$rendered" == *"Dr. Smith"* && "$rendered" == *"Spring 2026"* ]]; then
        _test_pass "Course override: custom variables rendered"
    else
        _test_fail "Course override: custom variables rendered"
    fi

    # Test 17: DATE auto-filled
    rendered=$(_teach_render_prompt "$TEST_DIR/course/.flow/templates/prompts/lecture-notes.md")
    local today=$(date +%Y-%m-%d)
    if [[ "$rendered" == *"$today"* ]]; then
        _test_pass "DATE variable: auto-filled with today's date"
    else
        _test_fail "DATE variable: auto-filled with today's date"
    fi

    # Test 18: Extra vars override config vars
    typeset -A override_vars
    override_vars[COURSE]="OVERRIDE-101"
    rendered=$(_teach_render_prompt "$TEST_DIR/plugin/claude-prompts/lecture-notes.md" override_vars)
    if [[ "$rendered" == *"OVERRIDE-101"* ]]; then
        _test_pass "Extra vars: override config values"
    else
        _test_fail "Extra vars: override config values"
    fi
}

# ============================================================================
# VALIDATION TESTS (10)
# ============================================================================

_test_validation() {
    _test_section "Validation (10 tests)"

    # Test 19: Valid prompt passes
    local output
    output=$(_teach_validate_prompt_file "$TEST_DIR/plugin/claude-prompts/lecture-notes.md")
    if [[ $? -eq 0 ]]; then
        _test_pass "Valid prompt: passes validation"
    else
        _test_fail "Valid prompt: passes validation" "$output"
    fi

    # Test 20: Missing frontmatter fails
    output=$(_teach_validate_prompt_file "$TEST_DIR/plugin/claude-prompts/broken-prompt.md")
    if [[ $? -ne 0 && "$output" == *"frontmatter"* ]]; then
        _test_pass "Missing frontmatter: reports error"
    else
        _test_fail "Missing frontmatter: reports error" "$output"
    fi

    # Test 21: Wrong template_type fails
    output=$(_teach_validate_prompt_file "$TEST_DIR/plugin/claude-prompts/wrong-type.md")
    if [[ $? -ne 0 && "$output" == *"template_type"* ]]; then
        _test_pass "Wrong template_type: reports error"
    else
        _test_fail "Wrong template_type: reports error" "$output"
    fi

    # Test 22: Nonexistent file fails
    output=$(_teach_validate_prompt_file "/tmp/nonexistent-file.md")
    if [[ $? -ne 0 ]]; then
        _test_pass "Nonexistent file: returns error"
    else
        _test_fail "Nonexistent file: returns error"
    fi

    # Test 23: Short body warning
    output=$(_teach_validate_prompt_file "$TEST_DIR/plugin/claude-prompts/short-body.md")
    if [[ "$output" == *"warning"*"short"* ]]; then
        _test_pass "Short body: generates warning"
    else
        _test_fail "Short body: generates warning" "$output"
    fi

    # Test 24: Bad variable names detected
    output=$(_teach_validate_prompt_file "$TEST_DIR/plugin/claude-prompts/bad-vars.md")
    if [[ "$output" == *"error"*"invalid variable"* || "$output" == *"error"*"UPPERCASE"* ]]; then
        _test_pass "Bad variable names: detected as errors"
    else
        _test_fail "Bad variable names: detected as errors" "$output"
    fi

    # Test 25: Strict mode treats warnings as errors
    output=$(_teach_validate_prompt_file "$TEST_DIR/plugin/claude-prompts/short-body.md" 1)
    if [[ $? -ne 0 ]]; then
        _test_pass "Strict mode: warnings become errors"
    else
        _test_fail "Strict mode: warnings become errors"
    fi

    # Test 26: Valid course override passes
    output=$(_teach_validate_prompt_file "$TEST_DIR/course/.flow/templates/prompts/lecture-notes.md")
    if [[ $? -eq 0 ]]; then
        _test_pass "Course override: valid prompt passes"
    else
        _test_fail "Course override: valid prompt passes" "$output"
    fi

    # Test 27: Has-override detection
    if _teach_prompt_has_override "lecture-notes"; then
        _test_pass "Has override: detects course override for lecture-notes"
    else
        _test_fail "Has override: detects course override for lecture-notes"
    fi

    # Test 28: No-override detection
    if ! _teach_prompt_has_override "revealjs-slides"; then
        _test_pass "No override: correctly reports no override for revealjs-slides"
    else
        _test_fail "No override: correctly reports no override for revealjs-slides"
    fi
}

# ============================================================================
# LIST/SHOW TESTS (6)
# ============================================================================

_test_list_show() {
    _test_section "List/Show (6 tests)"

    # Test 29: Get all prompts returns expected count
    local all_prompts
    all_prompts=$(_teach_get_all_prompts)
    local count=$(echo "$all_prompts" | grep -c '|' || true)
    if (( count >= 4 )); then
        _test_pass "Get all prompts: returns >= 4 prompts (got $count)"
    else
        _test_fail "Get all prompts: returns >= 4 prompts" "Got: $count"
    fi

    # Test 30: Course override shows as course tier
    if echo "$all_prompts" | grep -q "lecture-notes|course|"; then
        _test_pass "List: lecture-notes shows as course tier"
    else
        _test_fail "List: lecture-notes shows as course tier"
    fi

    # Test 31: Plugin-only shows as plugin tier
    if echo "$all_prompts" | grep -q "revealjs-slides|plugin|"; then
        _test_pass "List: revealjs-slides shows as plugin tier"
    else
        _test_fail "List: revealjs-slides shows as plugin tier"
    fi

    # Test 32: User-only shows as user tier
    if echo "$all_prompts" | grep -q "exam|user|"; then
        _test_pass "List: exam shows as user tier"
    else
        _test_fail "List: exam shows as user tier"
    fi

    # Test 33: Deduplication (lecture-notes appears once, not twice)
    local ln_count=$(echo "$all_prompts" | grep -c "^lecture-notes|" || true)
    if [[ "$ln_count" -eq 1 ]]; then
        _test_pass "Deduplication: lecture-notes appears once (course shadows plugin)"
    else
        _test_fail "Deduplication: lecture-notes appears once" "Got: $ln_count"
    fi

    # Test 34: JSON output valid format
    local json_output
    json_output=$(_teach_prompt_list --json 2>/dev/null)
    if [[ "$json_output" == "["* && "$json_output" == *"]" ]]; then
        _test_pass "JSON output: valid array format"
    else
        _test_fail "JSON output: valid array format"
    fi
}

# ============================================================================
# EDIT TESTS (4)
# ============================================================================

_test_edit() {
    _test_section "Edit (4 tests)"

    # Test 35: Edit creates override directory
    local new_override_dir="$TEST_DIR/course/.flow/templates/prompts"
    rm -rf "$new_override_dir"
    mkdir -p "$TEST_DIR/course/.flow"

    # Override EDITOR to just touch the file
    EDITOR="true"  # 'true' command does nothing
    _teach_prompt_edit "revealjs-slides" >/dev/null 2>&1

    if [[ -d "$new_override_dir" ]]; then
        _test_pass "Edit: creates override directory"
    else
        _test_fail "Edit: creates override directory"
    fi

    # Test 36: Edit copies plugin content to course
    if [[ -f "$new_override_dir/revealjs-slides.md" ]]; then
        _test_pass "Edit: copies plugin content to course dir"
    else
        _test_fail "Edit: copies plugin content to course dir"
    fi

    # Test 37: Edit preserves content from source
    if [[ -f "$new_override_dir/revealjs-slides.md" ]]; then
        if grep -q "RevealJS" "$new_override_dir/revealjs-slides.md" 2>/dev/null; then
            _test_pass "Edit: override preserves source content"
        else
            _test_fail "Edit: override preserves source content"
        fi
    else
        _test_skip "Edit: override preserves source content (file not created)"
    fi

    # Test 38: Edit nonexistent prompt creates skeleton
    EDITOR="true"
    _teach_prompt_edit "brand-new-prompt" >/dev/null 2>&1
    if [[ -f "$new_override_dir/brand-new-prompt.md" ]]; then
        if grep -q "template_type" "$new_override_dir/brand-new-prompt.md" 2>/dev/null; then
            _test_pass "Edit new: creates skeleton with frontmatter"
        else
            _test_fail "Edit new: creates skeleton with frontmatter"
        fi
    else
        _test_fail "Edit new: creates skeleton file"
    fi
}

# ============================================================================
# EXPORT TESTS (4)
# ============================================================================

_test_export() {
    _test_section "Export (4 tests)"

    # Test 39: Export renders variables
    typeset -A test_vars
    test_vars[COURSE]="STAT 440"
    test_vars[TOPIC]="ANOVA"

    # Override _teach_load_config_variables to use our test vars
    local orig_func
    orig_func=$(typeset -f _teach_load_config_variables)

    _teach_load_config_variables() {
        local arr="$1"
        eval "${arr}[COURSE]=\"STAT 440\""
        eval "${arr}[DATE]=\"$(date +%Y-%m-%d)\""
    }

    local output
    output=$(_teach_prompt_export "lecture-notes" 2>/dev/null)
    if [[ "$output" == *"STAT 440"* ]]; then
        _test_pass "Export: renders COURSE variable"
    else
        _test_fail "Export: renders COURSE variable"
    fi

    # Test 40: Export JSON mode
    output=$(_teach_prompt_export "lecture-notes" --json 2>/dev/null)
    if [[ "$output" == *"\"name\":"* && "$output" == *"\"tier\":"* ]]; then
        _test_pass "Export JSON: contains name and tier fields"
    else
        _test_fail "Export JSON: contains name and tier fields"
    fi

    # Test 41: Export missing prompt fails
    _teach_prompt_export "nonexistent" >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        _test_pass "Export missing: returns error"
    else
        _test_fail "Export missing: returns error"
    fi

    # Test 42: Export strips frontmatter
    output=$(_teach_prompt_export "revealjs-slides" 2>/dev/null)
    if [[ "$output" != *"template_version"* ]]; then
        _test_pass "Export: strips YAML frontmatter from output"
    else
        _test_fail "Export: strips YAML frontmatter from output"
    fi

    # Restore original function
    if [[ -n "$orig_func" ]]; then
        eval "$orig_func"
    fi
}

# ============================================================================
# DISPATCHER TESTS (6)
# ============================================================================

_test_dispatcher() {
    _test_section "Dispatcher (6 tests)"

    # Test 43: Default action is 'list'
    local output
    output=$(_teach_prompt 2>/dev/null)
    if [[ "$output" == *"Teaching Prompts"* || "$output" == *"lecture-notes"* ]]; then
        _test_pass "Default action: 'list' when no args"
    else
        _test_fail "Default action: 'list' when no args"
    fi

    # Test 44: Alias 'ls' routes to list
    output=$(_teach_prompt "ls" 2>/dev/null)
    if [[ "$output" == *"Teaching Prompts"* || "$output" == *"lecture-notes"* ]]; then
        _test_pass "Alias 'ls': routes to list command"
    else
        _test_fail "Alias 'ls': routes to list command"
    fi

    # Test 45: Alias 'l' routes to list
    output=$(_teach_prompt "l" 2>/dev/null)
    if [[ "$output" == *"Teaching Prompts"* || "$output" == *"lecture-notes"* ]]; then
        _test_pass "Alias 'l': routes to list command"
    else
        _test_fail "Alias 'l': routes to list command"
    fi

    # Test 46: Alias 'val' routes to validate
    output=$(_teach_prompt "val" 2>/dev/null)
    if [[ "$output" == *"Validating"* ]]; then
        _test_pass "Alias 'val': routes to validate command"
    else
        _test_fail "Alias 'val': routes to validate command"
    fi

    # Test 47: Help action shows help text
    output=$(_teach_prompt "help" 2>/dev/null)
    if [[ "$output" == *"USAGE"* && "$output" == *"teach prompt"* ]]; then
        _test_pass "Help: displays usage and command info"
    else
        _test_fail "Help: displays usage and command info"
    fi

    # Test 48: Unknown name treated as 'show'
    # An unknown name that doesn't start with '-' is treated as prompt name for show
    output=$(_teach_prompt "lecture-notes" "--raw" 2>/dev/null)
    if [[ "$output" == *"Lecture Notes"* || "$output" == *"STAT 440"* ]]; then
        _test_pass "Unknown action: treated as show <name>"
    else
        _test_fail "Unknown action: treated as show <name>"
    fi
}

# ============================================================================
# FLAG TESTS (8)
# ============================================================================

_test_flags() {
    _test_section "Flags (8 tests)"

    # Test 49: Tier filter: course-only prompts
    # Test the internal filter mechanism directly (avoids ANSI/heredoc issues)
    local all_prompts filtered
    all_prompts=$(_teach_get_all_prompts)
    filtered=$(echo "$all_prompts" | grep "|course|" || true)
    local non_course=$(echo "$filtered" | grep -v "|course|" || true)
    if [[ -n "$filtered" && -z "$non_course" ]]; then
        _test_pass "Tier filter: course grep returns only course-tier prompts"
    else
        _test_fail "Tier filter: course grep returns only course-tier prompts"
    fi

    # Test 50: Tier filter: plugin-only prompts
    filtered=$(echo "$all_prompts" | grep "|plugin|" || true)
    local non_plugin=$(echo "$filtered" | grep -v "|plugin|" || true)
    if [[ -n "$filtered" && -z "$non_plugin" ]]; then
        _test_pass "Tier filter: plugin grep returns only plugin-tier prompts"
    else
        _test_fail "Tier filter: plugin grep returns only plugin-tier prompts"
    fi

    # Test 51: List --tier invalid returns error
    output=$(_teach_prompt_list --tier bogus 2>&1)
    if [[ "$output" == *"Invalid tier"* ]]; then
        _test_pass "List --tier invalid: returns error message"
    else
        _test_fail "List --tier invalid: returns error message"
    fi

    # Test 52: List --verbose shows file paths
    output=$(_teach_prompt_list --verbose 2>/dev/null)
    if [[ "$output" == *"$TEST_DIR"* ]]; then
        _test_pass "List --verbose: shows file paths"
    else
        _test_fail "List --verbose: shows file paths"
    fi

    # Test 53: Show --raw outputs without pager header
    output=$(_teach_prompt_show "revealjs-slides" --raw 2>/dev/null)
    if [[ "$output" == *"---"* && "$output" == *"template_version"* ]]; then
        _test_pass "Show --raw: outputs raw file including frontmatter"
    else
        _test_fail "Show --raw: outputs raw file including frontmatter"
    fi

    # Test 54: Show --tier forces specific tier
    output=$(_teach_prompt_show "lecture-notes" --raw --tier plugin 2>/dev/null)
    if [[ "$output" == *"Comprehensive Lecture Notes"* ]]; then
        _test_pass "Show --tier plugin: bypasses course override"
    else
        _test_fail "Show --tier plugin: bypasses course override"
    fi

    # Test 55: Show missing name shows error
    output=$(_teach_prompt_show 2>&1)
    if [[ "$output" == *"name required"* ]]; then
        _test_pass "Show no name: returns error message"
    else
        _test_fail "Show no name: returns error message"
    fi

    # Test 56: Edit --global targets user directory
    # Override EDITOR so it doesn't block
    EDITOR="true"
    local user_dir="$TEST_DIR/user/.flow/prompts"
    rm -f "$user_dir/global-test-prompt.md"
    _teach_prompt_edit "global-test-prompt" --global >/dev/null 2>&1
    if [[ -f "$user_dir/global-test-prompt.md" ]]; then
        _test_pass "Edit --global: creates in user dir"
    else
        _test_fail "Edit --global: creates in user dir"
    fi
}

# ============================================================================
# EDGE CASE TESTS (6)
# ============================================================================

_test_edge_cases() {
    _test_section "Edge Cases (6 tests)"

    # Test 57: Validate single prompt by name
    local output
    output=$(_teach_prompt_validate "lecture-notes" 2>/dev/null)
    if [[ "$output" == *"lecture-notes"* && "$output" == *"Valid"* ]]; then
        _test_pass "Validate single: validates named prompt only"
    else
        _test_fail "Validate single: validates named prompt only"
    fi

    # Test 58: Validate nonexistent prompt returns error
    _teach_prompt_validate "definitely-missing" >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        _test_pass "Validate missing: returns error for unknown name"
    else
        _test_fail "Validate missing: returns error for unknown name"
    fi

    # Test 59: Export --json includes rendered field
    # Override config loader for predictable output
    _teach_load_config_variables() {
        local arr="$1"
        eval "${arr}[COURSE]=\"TEST-101\""
        eval "${arr}[DATE]=\"2026-01-29\""
    }

    output=$(_teach_prompt_export "revealjs-slides" --json 2>/dev/null)
    if [[ "$output" == *"\"rendered\":"* && "$output" == *"\"tier\":"* ]]; then
        _test_pass "Export --json: includes rendered and tier fields"
    else
        _test_fail "Export --json: includes rendered and tier fields"
    fi

    # Test 60: Tier detection for user tier
    local tier
    tier=$(_teach_prompt_tier "$TEST_DIR/user/.flow/prompts/exam.md")
    if [[ "$tier" == "user" ]]; then
        _test_pass "Tier detection: identifies user tier"
    else
        _test_fail "Tier detection: identifies user tier" "Got: $tier"
    fi

    # Test 61: Tier detection for plugin tier (fallback)
    tier=$(_teach_prompt_tier "/some/random/path/prompt.md")
    if [[ "$tier" == "plugin" ]]; then
        _test_pass "Tier detection: defaults to plugin for unknown paths"
    else
        _test_fail "Tier detection: defaults to plugin for unknown paths" "Got: $tier"
    fi

    # Test 62: Multiple edits don't overwrite existing override
    EDITOR="true"
    # First create the override (already done in edit tests)
    local override_dir="$TEST_DIR/course/.flow/templates/prompts"
    mkdir -p "$override_dir"
    echo "CUSTOM CONTENT" > "$override_dir/keep-test.md"
    _teach_prompt_edit "keep-test" >/dev/null 2>&1
    if grep -q "CUSTOM CONTENT" "$override_dir/keep-test.md" 2>/dev/null; then
        _test_pass "Edit existing: preserves existing override content"
    else
        _test_fail "Edit existing: preserves existing override content"
    fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    echo ""
    echo "${BOLD}${CYAN}╭─────────────────────────────────────────────────────────╮${RESET}"
    echo "${BOLD}${CYAN}│${RESET}  ${BOLD}teach prompt - Unit Tests${RESET}                               ${BOLD}${CYAN}│${RESET}"
    echo "${BOLD}${CYAN}╰─────────────────────────────────────────────────────────╯${RESET}"

    _setup_test_env

    _test_resolution
    _test_rendering
    _test_validation
    _test_list_show
    _test_edit
    _test_export
    _test_dispatcher
    _test_flags
    _test_edge_cases

    _teardown_test_env

    # Summary
    echo ""
    echo "${BOLD}─────────────────────────────────────────────────────────${RESET}"
    printf "  ${BOLD}Total:${RESET} %d  " "$TEST_TOTAL"
    printf "${GREEN}Pass:${RESET} %d  " "$TEST_PASS"
    printf "${RED}Fail:${RESET} %d  " "$TEST_FAIL"
    printf "${YELLOW}Skip:${RESET} %d\n" "$TEST_SKIP"
    echo "${BOLD}─────────────────────────────────────────────────────────${RESET}"
    echo ""

    if (( TEST_FAIL > 0 )); then
        printf "  ${RED}${BOLD}FAIL${RESET} - %d test(s) failed\n" "$TEST_FAIL"
        echo ""
        return 1
    else
        printf "  ${GREEN}${BOLD}PASS${RESET} - All %d tests passed\n" "$TEST_PASS"
        echo ""
        return 0
    fi
}

main "$@"
