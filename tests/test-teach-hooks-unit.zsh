#!/usr/bin/env zsh
# tests/test-teach-hooks-unit.zsh - Unit tests for git hooks system
# Tests hook installation, version management, and validation logic

# ============================================================================
# TEST SETUP
# ============================================================================

# Calculate project root once (works when run from project root or tests/)
typeset -g FLOW_TEST_PROJECT_ROOT
if [[ -f "lib/core.zsh" ]]; then
  FLOW_TEST_PROJECT_ROOT="$PWD"
elif [[ -f "../lib/core.zsh" ]]; then
  FLOW_TEST_PROJECT_ROOT="${PWD:h}"
else
  FLOW_TEST_PROJECT_ROOT="${0:A:h:h}"
fi

# Source flow-cli core
source "${FLOW_TEST_PROJECT_ROOT}/lib/core.zsh"

# Source hook installer
source "${FLOW_TEST_PROJECT_ROOT}/lib/hook-installer.zsh"

# Test counters
typeset -g TESTS_RUN=0
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0

# Colors
typeset -gA TEST_COLORS
TEST_COLORS=(
  [reset]='\033[0m'
  [success]='\033[38;5;114m'
  [error]='\033[38;5;203m'
  [info]='\033[38;5;117m'
  [muted]='\033[38;5;245m'
)

# ============================================================================
# TEST UTILITIES
# ============================================================================

_test_log() {
  local level="$1"
  shift
  local color="${TEST_COLORS[$level]}"
  echo -e "${color}$*${TEST_COLORS[reset]}"
}

_test_setup() {
  local test_name="$1"
  ((TESTS_RUN++))
  _test_log info "Test $TESTS_RUN: $test_name"
}

_test_assert() {
  local condition="$1"
  local message="$2"

  if eval "$condition"; then
    ((TESTS_PASSED++))
    _test_log success "  ✓ $message"
    return 0
  else
    ((TESTS_FAILED++))
    _test_log error "  ✗ $message"
    _test_log muted "    Condition failed: $condition"
    return 1
  fi
}

_test_assert_equals() {
  local actual="$1"
  local expected="$2"
  local message="${3:-Values should be equal}"

  if [[ "$actual" == "$expected" ]]; then
    ((TESTS_PASSED++))
    _test_log success "  ✓ $message"
    return 0
  else
    ((TESTS_FAILED++))
    _test_log error "  ✗ $message"
    _test_log muted "    Expected: '$expected'"
    _test_log muted "    Actual:   '$actual'"
    return 1
  fi
}

_test_assert_file_exists() {
  local file="$1"
  local message="${2:-File should exist: $file}"

  if [[ -f "$file" ]]; then
    ((TESTS_PASSED++))
    _test_log success "  ✓ $message"
    return 0
  else
    ((TESTS_FAILED++))
    _test_log error "  ✗ $message"
    return 1
  fi
}

_test_assert_file_contains() {
  local file="$1"
  local pattern="$2"
  local message="${3:-File should contain pattern: $pattern}"

  if grep -q "$pattern" "$file"; then
    ((TESTS_PASSED++))
    _test_log success "  ✓ $message"
    return 0
  else
    ((TESTS_FAILED++))
    _test_log error "  ✗ $message"
    return 1
  fi
}

# ============================================================================
# MOCK GIT REPOSITORY
# ============================================================================

_create_mock_git_repo() {
  local test_dir="$1"

  mkdir -p "$test_dir"
  cd "$test_dir"

  # Initialize git repo
  git init -q

  # Create minimal Quarto project
  cat > _quarto.yml <<EOF
project:
  type: website
  output-dir: _site

website:
  title: "Test Course"
  navbar:
    left:
      - href: index.qmd
        text: Home

format:
  html:
    theme: cosmo
EOF

  # Create sample .qmd file
  cat > index.qmd <<EOF
---
title: "Test Document"
author: "Test Author"
date: "2026-01-20"
---

# Introduction

This is a test document.

\`\`\`{r}
print("Hello, world!")
\`\`\`
EOF

  git add .
  git commit -q -m "Initial commit"

  return 0
}

_cleanup_mock_repo() {
  local test_dir="$1"
  cd /tmp
  rm -rf "$test_dir"
}

# ============================================================================
# VERSION COMPARISON TESTS
# ============================================================================

test_version_comparison() {
  _test_setup "Version comparison logic"

  # Test equal versions
  _compare_versions "1.0.0" "1.0.0"
  _test_assert_equals "$?" "0" "Equal versions should return 0"

  # Test greater versions
  _compare_versions "2.0.0" "1.0.0"
  _test_assert_equals "$?" "1" "Greater version should return 1"

  _compare_versions "1.1.0" "1.0.0"
  _test_assert_equals "$?" "1" "Greater minor version should return 1"

  _compare_versions "1.0.1" "1.0.0"
  _test_assert_equals "$?" "1" "Greater patch version should return 1"

  # Test lesser versions
  _compare_versions "1.0.0" "2.0.0"
  _test_assert_equals "$?" "2" "Lesser version should return 2"

  _compare_versions "1.0.0" "1.1.0"
  _test_assert_equals "$?" "2" "Lesser minor version should return 2"

  _compare_versions "1.0.0" "1.0.1"
  _test_assert_equals "$?" "2" "Lesser patch version should return 2"

  # Test with missing components
  _compare_versions "1.0" "1.0.0"
  _test_assert_equals "$?" "0" "Missing patch should default to 0"
}

# ============================================================================
# VERSION EXTRACTION TESTS
# ============================================================================

test_version_extraction() {
  _test_setup "Version extraction from hook files"

  local test_dir="/tmp/flow-test-version-$$"
  mkdir -p "$test_dir"

  # Create mock hook file with version
  cat > "$test_dir/hook-with-version.sh" <<EOF
#!/usr/bin/env zsh
# Pre-commit hook
# Version: 1.2.3
# DO NOT EDIT
EOF

  local version
  version=$(_get_installed_hook_version "$test_dir/hook-with-version.sh")
  _test_assert_equals "$version" "1.2.3" "Should extract version 1.2.3"

  # Create hook without version
  cat > "$test_dir/hook-without-version.sh" <<EOF
#!/usr/bin/env zsh
# Pre-commit hook
EOF

  version=$(_get_installed_hook_version "$test_dir/hook-without-version.sh")
  _test_assert_equals "$version" "0.0.0" "Should return 0.0.0 for missing version"

  # Test non-existent file
  version=$(_get_installed_hook_version "$test_dir/nonexistent.sh")
  _test_assert_equals "$version" "0.0.0" "Should return 0.0.0 for missing file"

  rm -rf "$test_dir"
}

# ============================================================================
# HOOK INSTALLATION TESTS
# ============================================================================

test_hook_installation() {
  _test_setup "Hook installation in mock repository"

  local test_dir="/tmp/flow-test-install-$$"
  _create_mock_git_repo "$test_dir"

  # Install hooks
  _install_git_hooks >/dev/null 2>&1
  local install_status=$?

  _test_assert_equals "$install_status" "0" "Installation should succeed"

  # Check each hook was installed
  for hook_name in "${FLOW_HOOKS[@]}"; do
    local hook_file=".git/hooks/${hook_name}"
    _test_assert_file_exists "$hook_file" "Hook should exist: $hook_name"

    # Check hook is executable
    _test_assert "[[ -x '$hook_file' ]]" "Hook should be executable: $hook_name"

    # Check version is correct
    local version
    version=$(_get_installed_hook_version "$hook_file")
    _test_assert_equals "$version" "$FLOW_HOOK_VERSION" "Hook should have version $FLOW_HOOK_VERSION"

    # Check hook contains flow-cli marker
    _test_assert_file_contains "$hook_file" "Auto-generated by: teach hooks install" \
      "Hook should contain flow-cli marker: $hook_name"
  done

  _cleanup_mock_repo "$test_dir"
}

# ============================================================================
# HOOK UPGRADE TESTS
# ============================================================================

test_hook_upgrade() {
  _test_setup "Hook upgrade from older version"

  local test_dir="/tmp/flow-test-upgrade-$$"
  _create_mock_git_repo "$test_dir"

  # Install older version manually
  mkdir -p .git/hooks
  cat > .git/hooks/pre-commit <<EOF
#!/usr/bin/env zsh
# Pre-commit hook for Quarto teaching projects
# Auto-generated by: teach hooks install
# Version: 0.9.0
# DO NOT EDIT
EOF
  chmod +x .git/hooks/pre-commit

  # Check version before upgrade
  local old_version
  old_version=$(_get_installed_hook_version ".git/hooks/pre-commit")
  _test_assert_equals "$old_version" "0.9.0" "Should have old version installed"

  # Perform upgrade (force to avoid prompt)
  _install_git_hooks --force >/dev/null 2>&1

  # Check version after upgrade
  local new_version
  new_version=$(_get_installed_hook_version ".git/hooks/pre-commit")
  _test_assert_equals "$new_version" "$FLOW_HOOK_VERSION" "Should have new version after upgrade"

  _cleanup_mock_repo "$test_dir"
}

# ============================================================================
# HOOK BACKUP TESTS
# ============================================================================

test_hook_backup() {
  _test_setup "Backup of existing non-flow hooks"

  local test_dir="/tmp/flow-test-backup-$$"
  _create_mock_git_repo "$test_dir"

  # Create custom pre-commit hook (not flow-managed)
  mkdir -p .git/hooks
  cat > .git/hooks/pre-commit <<EOF
#!/usr/bin/env zsh
# Custom hook
echo "Custom validation"
EOF
  chmod +x .git/hooks/pre-commit

  # Install flow hooks (should backup custom hook)
  _install_git_hooks --force >/dev/null 2>&1

  # Check backup was created
  local backup_file
  backup_file=$(ls .git/hooks/pre-commit.backup-* 2>/dev/null | head -1)
  _test_assert "[[ -n '$backup_file' ]]" "Backup file should be created"

  if [[ -n "$backup_file" ]]; then
    _test_assert_file_contains "$backup_file" "Custom validation" \
      "Backup should contain original hook content"
  fi

  _cleanup_mock_repo "$test_dir"
}

# ============================================================================
# PRE-COMMIT VALIDATION TESTS
# ============================================================================

test_yaml_validation() {
  _test_setup "YAML frontmatter validation"

  # Note: Cannot source pre-commit-template.zsh as it calls main()
  # Instead, verify the validation logic exists in the template

  local template_file="${FLOW_TEST_PROJECT_ROOT}/lib/hooks/pre-commit-template.zsh"

  _test_assert_file_contains "$template_file" "_validate_yaml" \
    "Template should contain YAML validation function"

  _test_assert_file_contains "$template_file" "yq eval" \
    "Template should use yq for YAML validation"

  _test_assert_file_contains "$template_file" "grep -q '^---'" \
    "Template should check for YAML frontmatter delimiter"
}

# ============================================================================
# EMPTY CODE CHUNK DETECTION TESTS
# ============================================================================

test_empty_chunk_detection() {
  _test_setup "Empty code chunk detection"

  # Note: Cannot source pre-commit-template.zsh as it calls main()
  # Instead, verify the detection logic exists in the template

  local template_file="${FLOW_TEST_PROJECT_ROOT}/lib/hooks/pre-commit-template.zsh"

  _test_assert_file_contains "$template_file" "_check_empty_chunks" \
    "Template should contain empty chunk detection function"

  _test_assert_file_contains "$template_file" "grep.*python" \
    "Template should detect empty R/Python chunks"

  _test_assert_file_contains "$template_file" "Empty code chunks" \
    "Template should warn about empty code chunks"
}

# ============================================================================
# IMAGE VALIDATION TESTS
# ============================================================================

test_image_validation() {
  _test_setup "Image reference validation"

  # Note: Cannot source pre-commit-template.zsh as it calls main()
  # Instead, verify the image validation logic exists in the template

  local template_file="${FLOW_TEST_PROJECT_ROOT}/lib/hooks/pre-commit-template.zsh"

  _test_assert_file_contains "$template_file" "_check_images" \
    "Template should contain image validation function"

  _test_assert_file_contains "$template_file" "grep -oE.*\]" \
    "Template should detect markdown image syntax"

  _test_assert_file_contains "$template_file" "include_graphics" \
    "Template should detect knitr::include_graphics references"

  _test_assert_file_contains "$template_file" "Missing image" \
    "Template should warn about missing images"

  _test_assert_file_contains "$template_file" "https?://" \
    "Template should skip URL images"
}

# ============================================================================
# FREEZE DIRECTORY DETECTION TESTS
# ============================================================================

test_freeze_detection() {
  _test_setup "_freeze/ directory detection"

  # Note: Cannot source pre-commit-template.zsh as it calls main()
  # Instead, verify the _freeze/ detection logic exists in the template

  local template_file="${FLOW_TEST_PROJECT_ROOT}/lib/hooks/pre-commit-template.zsh"

  _test_assert_file_contains "$template_file" "_check_freeze" \
    "Template should contain _freeze/ detection function"

  _test_assert_file_contains "$template_file" "git diff --cached --name-only.*_freeze" \
    "Template should check staged files for _freeze/"

  _test_assert_file_contains "$template_file" "Cannot commit _freeze/" \
    "Template should error on _freeze/ commit"

  _test_assert_file_contains "$template_file" "git restore --staged _freeze/" \
    "Template should suggest unstaging _freeze/"
}

# ============================================================================
# PARALLEL RENDERING TESTS
# ============================================================================

test_parallel_rendering() {
  _test_setup "Parallel rendering with multiple files"

  # This test verifies the parallel rendering logic exists in the template
  local template_file="${FLOW_TEST_PROJECT_ROOT}/lib/hooks/pre-commit-template.zsh"

  _test_assert_file_exists "$template_file" "Pre-commit hook template should exist"

  # Check that parallel rendering function is defined
  _test_assert_file_contains "$template_file" "_render_files_parallel" \
    "Template should contain parallel rendering function"

  # Check that parallel rendering uses background jobs
  _test_assert_file_contains "$template_file" "&" \
    "Template should use background jobs for parallelism"

  # Check that max parallel jobs is configurable
  _test_assert_file_contains "$template_file" "QUARTO_MAX_PARALLEL" \
    "Template should support QUARTO_MAX_PARALLEL configuration"

  # Note: We don't actually call parallel rendering here because it requires quarto
  # and would be too slow for unit tests. Integration tests should cover this.
}

# ============================================================================
# TEST RUNNER
# ============================================================================

run_all_tests() {
  echo ""
  _test_log info "================================"
  _test_log info "Flow-CLI Hook System Unit Tests"
  _test_log info "================================"
  echo ""

  # Run version tests
  test_version_comparison
  test_version_extraction

  # Run installation tests
  test_hook_installation
  test_hook_upgrade
  test_hook_backup

  # Run validation tests
  test_yaml_validation
  test_empty_chunk_detection
  test_image_validation
  test_freeze_detection

  # Run parallel rendering tests
  test_parallel_rendering

  # Summary
  echo ""
  _test_log info "================================"
  _test_log info "Test Summary"
  _test_log info "================================"
  echo ""
  _test_log info "Tests run:    $TESTS_RUN"
  _test_log success "Tests passed: $TESTS_PASSED"

  if [[ $TESTS_FAILED -gt 0 ]]; then
    _test_log error "Tests failed: $TESTS_FAILED"
    echo ""
    _test_log error "TESTS FAILED"
    return 1
  else
    echo ""
    _test_log success "ALL TESTS PASSED"
    return 0
  fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

# Run tests if script is executed directly
if [[ "${(%):-%x}" == "$0" ]]; then
  run_all_tests
  exit $?
fi
