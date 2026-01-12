#!/usr/bin/env zsh
# tests/test-teach-init-phase1.zsh
# Unit tests for teach-init Phase 1 functions (v5.4.0)

# Load test framework
source "${0:A:h}/test-framework.zsh"

# Load plugin
source "${0:A:h}/../flow.plugin.zsh"

# ============================================================================
# TEST SUITE: Phase 1 Functions
# ============================================================================

test_suite_start "teach-init Phase 1 Functions"

# ----------------------------------------------------------------------------
# Test: _teach_detect_project_type - Quarto
# ----------------------------------------------------------------------------
test_case "_teach_detect_project_type detects Quarto" && {
  # Setup: Create test directory with _quarto.yml
  local test_dir=$(mktemp -d)
  cd "$test_dir"
  touch _quarto.yml

  # Execute
  local result=$(_teach_detect_project_type)

  # Assert
  assert_equals "$result" "quarto" "Should detect Quarto project"

  # Cleanup
  cd - >/dev/null
  rm -rf "$test_dir"
}

# ----------------------------------------------------------------------------
# Test: _teach_detect_project_type - MkDocs
# ----------------------------------------------------------------------------
test_case "_teach_detect_project_type detects MkDocs" && {
  # Setup
  local test_dir=$(mktemp -d)
  cd "$test_dir"
  touch mkdocs.yml

  # Execute
  local result=$(_teach_detect_project_type)

  # Assert
  assert_equals "$result" "mkdocs" "Should detect MkDocs project"

  # Cleanup
  cd - >/dev/null
  rm -rf "$test_dir"
}

# ----------------------------------------------------------------------------
# Test: _teach_detect_project_type - Unknown
# ----------------------------------------------------------------------------
test_case "_teach_detect_project_type detects unknown" && {
  # Setup
  local test_dir=$(mktemp -d)
  cd "$test_dir"

  # Execute
  local result=$(_teach_detect_project_type)

  # Assert
  assert_equals "$result" "unknown" "Should detect unknown project type"

  # Cleanup
  cd - >/dev/null
  rm -rf "$test_dir"
}

# ----------------------------------------------------------------------------
# Test: _teach_validate_quarto_project - Valid
# ----------------------------------------------------------------------------
test_case "_teach_validate_quarto_project passes for valid project" && {
  # Setup
  local test_dir=$(mktemp -d)
  cd "$test_dir"
  touch _quarto.yml
  touch index.qmd

  # Execute
  _teach_validate_quarto_project >/dev/null 2>&1
  local exit_code=$?

  # Assert
  assert_equals "$exit_code" "0" "Should pass validation"

  # Cleanup
  cd - >/dev/null
  rm -rf "$test_dir"
}

# ----------------------------------------------------------------------------
# Test: _teach_validate_quarto_project - Missing _quarto.yml
# ----------------------------------------------------------------------------
test_case "_teach_validate_quarto_project fails without _quarto.yml" && {
  # Setup
  local test_dir=$(mktemp -d)
  cd "$test_dir"
  touch index.qmd

  # Execute
  _teach_validate_quarto_project >/dev/null 2>&1
  local exit_code=$?

  # Assert
  assert_equals "$exit_code" "1" "Should fail validation"

  # Cleanup
  cd - >/dev/null
  rm -rf "$test_dir"
}

# ----------------------------------------------------------------------------
# Test: _teach_validate_quarto_project - Missing index.qmd
# ----------------------------------------------------------------------------
test_case "_teach_validate_quarto_project fails without index.qmd" && {
  # Setup
  local test_dir=$(mktemp -d)
  cd "$test_dir"
  touch _quarto.yml

  # Execute
  _teach_validate_quarto_project >/dev/null 2>&1
  local exit_code=$?

  # Assert
  assert_equals "$exit_code" "1" "Should fail validation"

  # Cleanup
  cd - >/dev/null
  rm -rf "$test_dir"
}

# ----------------------------------------------------------------------------
# Test: _teach_handle_renv - No renv directory
# ----------------------------------------------------------------------------
test_case "_teach_handle_renv does nothing when no renv/" && {
  # Setup
  local test_dir=$(mktemp -d)
  cd "$test_dir"

  # Execute
  _teach_handle_renv >/dev/null 2>&1

  # Assert
  assert_file_not_exists ".gitignore" "Should not create .gitignore"

  # Cleanup
  cd - >/dev/null
  rm -rf "$test_dir"
}

# ----------------------------------------------------------------------------
# Test: _teach_handle_renv - renv exists, already in .gitignore
# ----------------------------------------------------------------------------
test_case "_teach_handle_renv skips if renv already excluded" && {
  # Setup
  local test_dir=$(mktemp -d)
  cd "$test_dir"
  mkdir -p renv
  echo "renv/" > .gitignore

  # Execute (simulate user input: default is yes)
  echo "" | _teach_handle_renv >/dev/null 2>&1

  # Assert: .gitignore should still have only one renv/ entry
  local count=$(grep -c "^renv/$" .gitignore 2>/dev/null || echo 0)
  assert_equals "$count" "1" "Should not duplicate renv/ entry"

  # Cleanup
  cd - >/dev/null
  rm -rf "$test_dir"
}

# ----------------------------------------------------------------------------
# Test: _teach_rollback_migration - Success
# ----------------------------------------------------------------------------
test_case "_teach_rollback_migration resets to tag" && {
  # Setup: Create test git repo
  local test_dir=$(mktemp -d)
  cd "$test_dir"
  git init -q
  echo "initial" > file.txt
  git add . && git commit -q -m "Initial"
  git tag test-rollback

  # Make changes
  mkdir -p .flow scripts
  echo "config" > .flow/test.yml
  echo "script" > scripts/test.sh
  git add . && git commit -q -m "Migration"

  # Execute rollback
  _teach_rollback_migration test-rollback >/dev/null 2>&1
  local exit_code=$?

  # Assert
  assert_equals "$exit_code" "0" "Should succeed"
  assert_file_not_exists ".flow/test.yml" "Should remove .flow/"
  assert_file_not_exists "scripts/test.sh" "Should remove scripts/"

  # Cleanup
  cd - >/dev/null
  rm -rf "$test_dir"
}

# ----------------------------------------------------------------------------
# Test: _teach_rollback_migration - No tag
# ----------------------------------------------------------------------------
test_case "_teach_rollback_migration fails without tag" && {
  # Setup
  local test_dir=$(mktemp -d)
  cd "$test_dir"
  git init -q

  # Execute rollback without tag
  _teach_rollback_migration "" >/dev/null 2>&1
  local exit_code=$?

  # Assert
  assert_equals "$exit_code" "1" "Should fail without tag"

  # Cleanup
  cd - >/dev/null
  rm -rf "$test_dir"
}

# ----------------------------------------------------------------------------
# Test: teach-init --dry-run
# ----------------------------------------------------------------------------
test_case "teach-init --dry-run shows plan" && {
  # Setup
  local test_dir=$(mktemp -d)
  cd "$test_dir"
  git init -q
  touch _quarto.yml index.qmd
  git add . && git commit -q -m "Initial"

  # Execute
  local output=$(teach-init --dry-run "Test Course" 2>&1)
  local exit_code=$?

  # Assert
  assert_equals "$exit_code" "0" "Should succeed"
  assert_contains "$output" "DRY RUN MODE" "Should show dry-run message"
  assert_contains "$output" "Migration Plan" "Should show plan"
  assert_contains "$output" "Quarto website" "Should detect Quarto"

  # Verify no changes made
  assert_file_not_exists ".flow/teach-config.yml" "Should not create files"

  # Cleanup
  cd - >/dev/null
  rm -rf "$test_dir"
}

# ----------------------------------------------------------------------------
# Test: teach-init flag parsing - course name only
# ----------------------------------------------------------------------------
test_case "teach-init parses course name correctly" && {
  # This test verifies flag parsing doesn't break normal usage
  # We can't fully test teach-init without mocking, but we can test parsing

  # Setup: Mock the _teach_migrate_existing_repo function
  _teach_migrate_existing_repo() {
    echo "MIGRATE:$1"
  }

  local test_dir=$(mktemp -d)
  cd "$test_dir"
  git init -q

  # Execute
  local output=$(teach-init "My Course" 2>&1)

  # Assert
  assert_contains "$output" "MIGRATE:My Course" "Should pass course name correctly"

  # Cleanup
  cd - >/dev/null
  rm -rf "$test_dir"
  unfunction _teach_migrate_existing_repo
}

# ----------------------------------------------------------------------------
# Test: teach-init --dry-run with course name
# ----------------------------------------------------------------------------
test_case "teach-init --dry-run with course name" && {
  # Setup
  local test_dir=$(mktemp -d)
  cd "$test_dir"
  git init -q

  # Execute
  local output=$(teach-init --dry-run "Test Course" 2>&1)

  # Assert
  assert_contains "$output" "Test Course" "Should show course name in plan"

  # Cleanup
  cd - >/dev/null
  rm -rf "$test_dir"
}

# ============================================================================
# RUN ALL TESTS
# ============================================================================

test_suite_end

# Print summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Phase 1 Test Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Total tests: $TESTS_RUN"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "✅ All Phase 1 tests passed!"
  exit 0
else
  echo "❌ Some tests failed"
  exit 1
fi
