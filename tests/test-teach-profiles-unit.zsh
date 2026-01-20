#!/usr/bin/env zsh
# tests/test-teach-profiles-unit.zsh - Unit tests for Profile Management
# Tests profile detection, switching, validation, and creation

# Source test framework
TEST_DIR="${0:A:h}"
source "$TEST_DIR/test-framework.zsh"

# Source the modules we're testing
source "$TEST_DIR/../lib/core.zsh"
source "$TEST_DIR/../lib/profile-helpers.zsh"
source "$TEST_DIR/../commands/teach-profiles.zsh"

# ============================================================================
# TEST FIXTURES
# ============================================================================

setup_test_project() {
    local test_dir="$1"

    mkdir -p "$test_dir/.flow"

    # Create a basic _quarto.yml with profiles
    cat > "$test_dir/_quarto.yml" << 'EOF'
project:
  type: website
  title: "Test Course"

profile:
  default:
    format:
      html:
        theme: cosmo
        toc: true
    description: "Standard course website"

  draft:
    format:
      html:
        theme: cosmo
        toc: true
    execute:
      freeze: false
      echo: false
    description: "Draft content (unpublished)"

  print:
    format:
      pdf:
        documentclass: article
        margin-left: 1in
    description: "PDF handout generation"

  slides:
    format:
      revealjs:
        theme: simple
        slide-number: true
    description: "Reveal.js presentations"
EOF

    # Create teaching.yml
    cat > "$test_dir/.flow/teaching.yml" << 'EOF'
course:
  name: "Test Course"
  code: "TEST-101"

quarto:
  profile: default

r_packages:
  - ggplot2
  - dplyr
EOF
}

setup_minimal_project() {
    local test_dir="$1"

    mkdir -p "$test_dir"

    # Minimal _quarto.yml without profiles
    cat > "$test_dir/_quarto.yml" << 'EOF'
project:
  type: website
  title: "Minimal Course"

format:
  html:
    theme: cosmo
EOF
}

# ============================================================================
# PROFILE DETECTION TESTS
# ============================================================================

test_detect_quarto_profiles_success() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"
    local profiles
    profiles=$(_detect_quarto_profiles)
    local ret=$?

    assert_equals 0 $ret "Should detect profiles successfully"
    assert_contains "$profiles" "default" "Should find default profile"
    assert_contains "$profiles" "draft" "Should find draft profile"
    assert_contains "$profiles" "print" "Should find print profile"
    assert_contains "$profiles" "slides" "Should find slides profile"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_detect_quarto_profiles_no_file() {
    local test_dir=$(mktemp -d)

    cd "$test_dir"
    _detect_quarto_profiles > /dev/null 2>&1
    local ret=$?

    assert_equals 1 $ret "Should return 1 when _quarto.yml not found"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_detect_quarto_profiles_no_profiles() {
    local test_dir=$(mktemp -d)
    setup_minimal_project "$test_dir"

    cd "$test_dir"
    _detect_quarto_profiles > /dev/null 2>&1
    local ret=$?

    assert_equals 2 $ret "Should return 2 when no profiles defined"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_get_profile_description() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"
    local desc
    desc=$(_get_profile_description "default")

    assert_contains "$desc" "Standard course website" "Should get description for default profile"

    desc=$(_get_profile_description "draft")
    assert_contains "$desc" "Draft content" "Should get description for draft profile"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_get_profile_config() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"
    local config
    config=$(_get_profile_config "draft")

    assert_contains "$config" "freeze: false" "Should get freeze setting from draft profile"
    assert_contains "$config" "echo: false" "Should get echo setting from draft profile"

    cd - > /dev/null
    rm -rf "$test_dir"
}

# ============================================================================
# PROFILE LISTING TESTS
# ============================================================================

test_list_profiles_human_readable() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"
    local output
    output=$(_list_profiles 2>&1)

    assert_contains "$output" "Available Quarto Profiles" "Should show header"
    assert_contains "$output" "default" "Should list default profile"
    assert_contains "$output" "draft" "Should list draft profile"
    assert_contains "$output" "print" "Should list print profile"
    assert_contains "$output" "slides" "Should list slides profile"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_list_profiles_json() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"
    local output
    output=$(_list_profiles --json)

    assert_contains "$output" '"profiles"' "Should have profiles array"
    assert_contains "$output" '"name": "default"' "Should include default profile"
    assert_contains "$output" '"current"' "Should show current profile"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_list_profiles_quiet() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"
    local output
    output=$(_list_profiles --quiet)

    # Should only have profile names, no descriptions or headers
    assert_not_contains "$output" "Available" "Should not show header in quiet mode"
    assert_contains "$output" "default" "Should list default profile"

    cd - > /dev/null
    rm -rf "$test_dir"
}

# ============================================================================
# CURRENT PROFILE DETECTION TESTS
# ============================================================================

test_get_current_profile_from_env() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"
    export QUARTO_PROFILE="draft"

    local current
    current=$(_get_current_profile)

    assert_equals "draft" "$current" "Should get profile from QUARTO_PROFILE env var"

    unset QUARTO_PROFILE
    cd - > /dev/null
    rm -rf "$test_dir"
}

test_get_current_profile_from_teaching_yml() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"
    # Make sure env var is not set
    unset QUARTO_PROFILE

    local current
    current=$(_get_current_profile)

    assert_equals "default" "$current" "Should get profile from teaching.yml"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_get_current_profile_default_fallback() {
    local test_dir=$(mktemp -d)
    mkdir -p "$test_dir"

    cd "$test_dir"
    unset QUARTO_PROFILE

    local current
    current=$(_get_current_profile)

    assert_equals "default" "$current" "Should fall back to 'default' when no profile set"

    cd - > /dev/null
    rm -rf "$test_dir"
}

# ============================================================================
# PROFILE SWITCHING TESTS
# ============================================================================

test_switch_profile_success() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"
    unset QUARTO_PROFILE

    _switch_profile "draft" > /dev/null 2>&1
    local ret=$?

    assert_equals 0 $ret "Should switch profile successfully"
    assert_equals "draft" "$QUARTO_PROFILE" "Should set QUARTO_PROFILE env var"

    # Check teaching.yml was updated
    local yml_profile
    yml_profile=$(yq eval '.quarto.profile' ".flow/teaching.yml" 2>/dev/null)
    assert_equals "draft" "$yml_profile" "Should update teaching.yml"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_switch_profile_invalid() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"

    _switch_profile "nonexistent" > /dev/null 2>&1
    local ret=$?

    assert_not_equals 0 $ret "Should fail for invalid profile"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_switch_profile_no_name() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"

    _switch_profile "" > /dev/null 2>&1
    local ret=$?

    assert_equals 1 $ret "Should fail when no profile name provided"

    cd - > /dev/null
    rm -rf "$test_dir"
}

# ============================================================================
# PROFILE VALIDATION TESTS
# ============================================================================

test_validate_profile_valid() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"

    _validate_profile "default" --quiet
    local ret=$?

    assert_equals 0 $ret "Should validate existing profile"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_validate_profile_invalid() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"

    _validate_profile "nonexistent" --quiet 2>/dev/null
    local ret=$?

    assert_equals 1 $ret "Should fail for non-existent profile"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_validate_profile_no_name() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"

    _validate_profile "" --quiet 2>/dev/null
    local ret=$?

    assert_equals 1 $ret "Should fail when no profile name provided"

    cd - > /dev/null
    rm -rf "$test_dir"
}

# ============================================================================
# PROFILE CREATION TESTS
# ============================================================================

test_create_profile_default_template() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"

    _create_profile "custom" "default" > /dev/null 2>&1
    local ret=$?

    assert_equals 0 $ret "Should create profile successfully"

    # Verify profile was added to _quarto.yml
    _validate_profile "custom" --quiet
    assert_equals 0 $? "New profile should be valid"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_create_profile_draft_template() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"

    _create_profile "my-draft" "draft" > /dev/null 2>&1
    local ret=$?

    assert_equals 0 $ret "Should create draft profile"

    # Check that freeze: false is in the new profile
    local config
    config=$(_get_profile_config "my-draft")
    assert_contains "$config" "freeze: false" "Should have freeze: false from draft template"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_create_profile_print_template() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"

    _create_profile "handouts" "print" > /dev/null 2>&1

    local config
    config=$(_get_profile_config "handouts")
    assert_contains "$config" "pdf" "Should have PDF format from print template"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_create_profile_slides_template() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"

    _create_profile "lecture" "slides" > /dev/null 2>&1

    local config
    config=$(_get_profile_config "lecture")
    assert_contains "$config" "revealjs" "Should have revealjs format from slides template"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_create_profile_already_exists() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"

    _create_profile "default" "default" > /dev/null 2>&1
    local ret=$?

    assert_not_equals 0 $ret "Should fail when profile already exists"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_create_profile_no_name() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"

    _create_profile "" > /dev/null 2>&1
    local ret=$?

    assert_equals 1 $ret "Should fail when no profile name provided"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_create_profile_unknown_template() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"

    _create_profile "custom" "unknown" > /dev/null 2>&1
    local ret=$?

    assert_not_equals 0 $ret "Should fail for unknown template"

    cd - > /dev/null
    rm -rf "$test_dir"
}

# ============================================================================
# PROFILE INFO TESTS
# ============================================================================

test_show_profile_info() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"

    local output
    output=$(_show_profile_info "draft" 2>&1)

    assert_contains "$output" "Profile: draft" "Should show profile name"
    assert_contains "$output" "Draft content" "Should show description"
    assert_contains "$output" "Configuration:" "Should show configuration section"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_show_profile_info_invalid() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"

    _show_profile_info "nonexistent" > /dev/null 2>&1
    local ret=$?

    assert_not_equals 0 $ret "Should fail for invalid profile"

    cd - > /dev/null
    rm -rf "$test_dir"
}

# ============================================================================
# COMMAND TESTS
# ============================================================================

test_teach_profiles_list_command() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"

    local output
    output=$(_teach_profiles list 2>&1)

    assert_contains "$output" "Available Quarto Profiles" "Command should work"
    assert_contains "$output" "default" "Should show profiles"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_teach_profiles_show_command() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"

    local output
    output=$(_teach_profiles show draft 2>&1)

    assert_contains "$output" "Profile: draft" "Should show profile details"

    cd - > /dev/null
    rm -rf "$test_dir"
}

test_teach_profiles_current_command() {
    local test_dir=$(mktemp -d)
    setup_test_project "$test_dir"

    cd "$test_dir"

    local output
    output=$(_teach_profiles current 2>&1)

    assert_contains "$output" "Current Profile" "Should show current profile"

    cd - > /dev/null
    rm -rf "$test_dir"
}

# ============================================================================
# RUN TESTS
# ============================================================================

echo "Running Profile Management Tests..."
echo ""

run_test test_detect_quarto_profiles_success
run_test test_detect_quarto_profiles_no_file
run_test test_detect_quarto_profiles_no_profiles
run_test test_get_profile_description
run_test test_get_profile_config

run_test test_list_profiles_human_readable
run_test test_list_profiles_json
run_test test_list_profiles_quiet

run_test test_get_current_profile_from_env
run_test test_get_current_profile_from_teaching_yml
run_test test_get_current_profile_default_fallback

run_test test_switch_profile_success
run_test test_switch_profile_invalid
run_test test_switch_profile_no_name

run_test test_validate_profile_valid
run_test test_validate_profile_invalid
run_test test_validate_profile_no_name

run_test test_create_profile_default_template
run_test test_create_profile_draft_template
run_test test_create_profile_print_template
run_test test_create_profile_slides_template
run_test test_create_profile_already_exists
run_test test_create_profile_no_name
run_test test_create_profile_unknown_template

run_test test_show_profile_info
run_test test_show_profile_info_invalid

run_test test_teach_profiles_list_command
run_test test_teach_profiles_show_command
run_test test_teach_profiles_current_command

print_test_summary
