#!/usr/bin/env zsh
# tests/test-teach-scholar-wrappers.zsh
# Unit tests for teach Scholar wrapper infrastructure (v5.8.0)
# - Preflight checks
# - Command building
# - Error handling
# - Help functions

# Load test framework
source "${0:A:h}/test-framework.zsh"

# Load plugin
source "${0:A:h}/../flow.plugin.zsh"

# ============================================================================
# TEST SUITE: Scholar Wrapper Infrastructure
# ============================================================================

test_suite_start "teach Scholar Wrappers"

# ----------------------------------------------------------------------------
# UNIT TESTS: Error Formatting
# ----------------------------------------------------------------------------

test_case "_teach_error outputs formatted error message" && {
    local output
    output=$(_teach_error "Test error message" "Recovery hint" 2>&1)

    assert_contains "$output" "teach:" "Should include 'teach:' prefix"
    assert_contains "$output" "Test error message" "Should include error message"
    assert_contains "$output" "Recovery hint" "Should include recovery hint"

    test_pass
}

test_case "_teach_error returns exit code 1" && {
    _teach_error "Test" "" 2>/dev/null
    local exit_code=$?

    assert_equals "$exit_code" "1" "Should return exit code 1"

    test_pass
}

test_case "_teach_warn outputs warning message" && {
    local output
    output=$(_teach_warn "Warning message" "Note here" 2>&1)

    assert_contains "$output" "teach:" "Should include 'teach:' prefix"
    assert_contains "$output" "Warning message" "Should include warning message"
    assert_contains "$output" "Note here" "Should include note"

    test_pass
}

# ----------------------------------------------------------------------------
# UNIT TESTS: Command Building
# ----------------------------------------------------------------------------

test_case "_teach_build_command maps exam correctly" && {
    local cmd
    cmd=$(_teach_build_command "exam" '"Hypothesis Testing"')

    assert_contains "$cmd" "/teaching:exam" "Should map to /teaching:exam"
    assert_contains "$cmd" "Hypothesis Testing" "Should include topic"

    test_pass
}

test_case "_teach_build_command maps quiz correctly" && {
    local cmd
    cmd=$(_teach_build_command "quiz" '"ANOVA"' "--questions" "10")

    assert_contains "$cmd" "/teaching:quiz" "Should map to /teaching:quiz"
    assert_contains "$cmd" "ANOVA" "Should include topic"
    assert_contains "$cmd" "--questions" "Should include flags"

    test_pass
}

test_case "_teach_build_command maps slides correctly" && {
    local cmd
    cmd=$(_teach_build_command "slides" '"Regression"')

    assert_contains "$cmd" "/teaching:slides" "Should map to /teaching:slides"

    test_pass
}

test_case "_teach_build_command maps lecture correctly" && {
    local cmd
    cmd=$(_teach_build_command "lecture" '"Topic"')

    assert_contains "$cmd" "/teaching:lecture" "Should map to /teaching:lecture"

    test_pass
}

test_case "_teach_build_command maps assignment correctly" && {
    local cmd
    cmd=$(_teach_build_command "assignment" '"HW1"')

    assert_contains "$cmd" "/teaching:assignment" "Should map to /teaching:assignment"

    test_pass
}

test_case "_teach_build_command maps syllabus correctly" && {
    local cmd
    cmd=$(_teach_build_command "syllabus")

    assert_contains "$cmd" "/teaching:syllabus" "Should map to /teaching:syllabus"

    test_pass
}

test_case "_teach_build_command maps rubric correctly" && {
    local cmd
    cmd=$(_teach_build_command "rubric" '"Midterm"')

    assert_contains "$cmd" "/teaching:rubric" "Should map to /teaching:rubric"

    test_pass
}

test_case "_teach_build_command maps feedback correctly" && {
    local cmd
    cmd=$(_teach_build_command "feedback" '"Student Work"')

    assert_contains "$cmd" "/teaching:feedback" "Should map to /teaching:feedback"

    test_pass
}

test_case "_teach_build_command maps demo correctly" && {
    local cmd
    cmd=$(_teach_build_command "demo")

    assert_contains "$cmd" "/teaching:demo" "Should map to /teaching:demo"

    test_pass
}

test_case "_teach_build_command rejects unknown command" && {
    local output
    output=$(_teach_build_command "unknown_cmd" 2>&1)
    local exit_code=$?

    assert_equals "$exit_code" "1" "Should return exit code 1 for unknown command"
    assert_contains "$output" "Unknown Scholar command" "Should show error"

    test_pass
}

# ----------------------------------------------------------------------------
# UNIT TESTS: Preflight Checks
# ----------------------------------------------------------------------------

test_case "_teach_preflight fails without config file" && {
    # Setup: Create temp directory without config
    local test_dir=$(mktemp -d)
    cd "$test_dir"

    # Execute
    local output
    output=$(_teach_preflight 2>&1)
    local exit_code=$?

    # Assert
    assert_equals "$exit_code" "1" "Should fail without config"
    assert_contains "$output" "teach-config.yml" "Should mention missing config"
    assert_contains "$output" "teach init" "Should suggest recovery"

    # Cleanup
    cd - >/dev/null
    rm -rf "$test_dir"

    test_pass
}

test_case "_teach_preflight warns without scholar section" && {
    # Setup: Create temp directory with minimal config
    local test_dir=$(mktemp -d)
    cd "$test_dir"
    mkdir -p .flow
    echo "course:" > .flow/teach-config.yml
    echo "  name: Test" >> .flow/teach-config.yml

    # Execute
    local output
    output=$(_teach_preflight 2>&1)

    # Assert - should warn but not fail
    assert_contains "$output" "scholar:" "Should mention missing scholar section"
    assert_contains "$output" "defaults" "Should mention defaults"

    # Cleanup
    cd - >/dev/null
    rm -rf "$test_dir"

    test_pass
}

test_case "_teach_preflight succeeds with valid config" && {
    # Setup: Create temp directory with full config
    local test_dir=$(mktemp -d)
    cd "$test_dir"
    mkdir -p .flow
    cat > .flow/teach-config.yml << 'EOF'
course:
  name: STAT 545
scholar:
  course_info:
    level: undergraduate
EOF

    # Execute
    local exit_code
    _teach_preflight 2>/dev/null
    exit_code=$?

    # Assert
    assert_equals "$exit_code" "0" "Should succeed with valid config"

    # Cleanup
    cd - >/dev/null
    rm -rf "$test_dir"

    test_pass
}

# ----------------------------------------------------------------------------
# UNIT TESTS: Scholar Help Functions
# ----------------------------------------------------------------------------

test_case "_teach_scholar_help shows exam help" && {
    local output
    output=$(_teach_scholar_help "exam")

    assert_contains "$output" "teach exam" "Should show command"
    assert_contains "$output" "--questions" "Should show --questions flag"
    assert_contains "$output" "--duration" "Should show --duration flag"
    assert_contains "$output" "--dry-run" "Should show --dry-run flag"

    test_pass
}

test_case "_teach_scholar_help shows quiz help" && {
    local output
    output=$(_teach_scholar_help "quiz")

    assert_contains "$output" "teach quiz" "Should show command"
    assert_contains "$output" "--time-limit" "Should show --time-limit flag"

    test_pass
}

test_case "_teach_scholar_help shows slides help" && {
    local output
    output=$(_teach_scholar_help "slides")

    assert_contains "$output" "teach slides" "Should show command"
    assert_contains "$output" "--theme" "Should show --theme flag"

    test_pass
}

test_case "_teach_scholar_help shows lecture help with awaiting note" && {
    local output
    output=$(_teach_scholar_help "lecture")

    assert_contains "$output" "teach lecture" "Should show command"
    assert_contains "$output" "--from-plan" "Should show --from-plan flag"
    assert_contains "$output" "awaiting" "Should note Scholar status"

    test_pass
}

test_case "_teach_scholar_help shows syllabus help" && {
    local output
    output=$(_teach_scholar_help "syllabus")

    assert_contains "$output" "teach syllabus" "Should show command"
    assert_contains "$output" "teach-config.yml" "Should mention config"

    test_pass
}

# ----------------------------------------------------------------------------
# UNIT TESTS: Dispatcher Routing
# ----------------------------------------------------------------------------

test_case "teach dispatcher routes exam to Scholar wrapper" && {
    # We can't test full execution without Claude, but we can verify routing
    # by checking that help works for Scholar commands
    local output
    output=$(teach exam --help 2>&1)

    assert_contains "$output" "teach exam" "Should show exam help"
    assert_contains "$output" "--questions" "Should show exam flags"

    test_pass
}

test_case "teach dispatcher routes quiz to Scholar wrapper" && {
    local output
    output=$(teach quiz --help 2>&1)

    assert_contains "$output" "teach quiz" "Should show quiz help"

    test_pass
}

test_case "teach dispatcher routes slides to Scholar wrapper" && {
    local output
    output=$(teach slides --help 2>&1)

    assert_contains "$output" "teach slides" "Should show slides help"

    test_pass
}

test_case "teach shortcuts work (e, q, sl, etc)" && {
    # Test that shortcuts route correctly
    local output

    output=$(teach e --help 2>&1)
    assert_contains "$output" "teach exam" "e should route to exam"

    output=$(teach q --help 2>&1)
    assert_contains "$output" "teach quiz" "q should route to quiz"

    output=$(teach sl --help 2>&1)
    assert_contains "$output" "teach slides" "sl should route to slides"

    test_pass
}

# ----------------------------------------------------------------------------
# UNIT TESTS: Main Help Function
# ----------------------------------------------------------------------------

test_case "teach help shows Scholar commands section" && {
    local output
    output=$(teach help 2>&1)

    assert_contains "$output" "SCHOLAR COMMANDS" "Should have Scholar section"
    assert_contains "$output" "exam" "Should list exam"
    assert_contains "$output" "quiz" "Should list quiz"
    assert_contains "$output" "slides" "Should list slides"
    assert_contains "$output" "lecture" "Should list lecture"
    assert_contains "$output" "assignment" "Should list assignment"
    assert_contains "$output" "syllabus" "Should list syllabus"
    assert_contains "$output" "rubric" "Should list rubric"
    assert_contains "$output" "feedback" "Should list feedback"
    assert_contains "$output" "demo" "Should list demo"

    test_pass
}

test_case "teach help shows universal flags" && {
    local output
    output=$(teach help 2>&1)

    assert_contains "$output" "--dry-run" "Should show --dry-run"
    assert_contains "$output" "--format" "Should show --format"
    assert_contains "$output" "--output" "Should show --output"
    assert_contains "$output" "--verbose" "Should show --verbose"

    test_pass
}

test_case "teach help shows shortcuts" && {
    local output
    output=$(teach help 2>&1)

    assert_contains "$output" "SHORTCUTS" "Should have shortcuts section"
    assert_contains "$output" "hw" "Should show hw shortcut"
    assert_contains "$output" "syl" "Should show syl shortcut"
    assert_contains "$output" "rb" "Should show rb shortcut"

    test_pass
}

# ----------------------------------------------------------------------------
# END OF TESTS
# ----------------------------------------------------------------------------

test_suite_end
