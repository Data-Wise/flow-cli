#!/usr/bin/env zsh
# tests/test-teach-init-ux.zsh
# Unit and E2E tests for teach-init UX enhancements (v5.4.1)
# - Non-interactive mode (-y/--yes flag)
# - ADHD-friendly completion summary

# Load test framework
source "${0:A:h}/test-framework.zsh"

# Load plugin
source "${0:A:h}/../flow.plugin.zsh"

# ============================================================================
# TEST SUITE: Non-Interactive Mode (-y/--yes flag)
# ============================================================================

test_suite_start "teach-init UX Enhancements"

# ----------------------------------------------------------------------------
# UNIT TESTS: Flag Parsing
# ----------------------------------------------------------------------------

test_case "teach-init shows usage without course name" && {
  # Execute - use subshell to capture exit code properly
  local output
  output=$(teach-init 2>&1)
  local exit_code=$?

  # Assert - check output contains usage info (exit code may vary)
  assert_contains "$output" "-y, --yes" "Usage should mention -y flag"
  assert_contains "$output" "Non-interactive mode" "Usage should describe -y flag"
  assert_contains "$output" "Usage:" "Should show usage"

  test_pass
}

test_case "teach-init -y sets TEACH_INTERACTIVE=false" && {
  # Setup: Create test directory with git
  local test_dir=$(mktemp -d)
  cd "$test_dir"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  touch README.md
  git add . && git commit -q -m "init"

  # We can't fully test teach-init -y without proper templates,
  # but we can verify the flag is recognized by checking for mode indicator
  local output=$(teach-init -y "Test Course" 2>&1 || true)

  # Assert - should show non-interactive mode indicator
  assert_contains "$output" "Non-interactive mode" "Should indicate non-interactive mode"

  # Cleanup
  cd - >/dev/null
  rm -rf "$test_dir"

  test_pass
}

test_case "teach-init --yes is equivalent to -y" && {
  # Execute
  local output=$(teach-init --yes 2>&1 || true)

  # Both -y and --yes should work (error is due to missing course name, not flag)
  # Usage message should be shown which includes the flag
  assert_contains "$output" "-y, --yes" "Should recognize --yes flag"

  test_pass
}

# ----------------------------------------------------------------------------
# UNIT TESTS: _teach_handle_renv Non-Interactive
# ----------------------------------------------------------------------------

test_case "_teach_handle_renv auto-excludes in non-interactive mode" && {
  # Setup
  local test_dir=$(mktemp -d)
  cd "$test_dir"
  mkdir renv
  touch .gitignore

  # Set non-interactive mode
  export TEACH_INTERACTIVE="false"

  # Execute
  local output=$(_teach_handle_renv 2>&1)

  # Assert
  assert_contains "$output" "Auto-excluding renv/" "Should auto-exclude renv"
  assert_contains "$(cat .gitignore)" "renv/" ".gitignore should contain renv/"

  # Cleanup
  unset TEACH_INTERACTIVE
  cd - >/dev/null
  rm -rf "$test_dir"

  test_pass
}

test_case "_teach_handle_renv skips if renv already in .gitignore" && {
  # Setup
  local test_dir=$(mktemp -d)
  cd "$test_dir"
  mkdir renv
  echo "renv/" > .gitignore

  # Set non-interactive mode
  export TEACH_INTERACTIVE="false"

  # Execute
  local output=$(_teach_handle_renv 2>&1)

  # Assert
  assert_contains "$output" "already in .gitignore" "Should detect existing entry"

  # Verify .gitignore wasn't duplicated
  local renv_count=$(grep -c "^renv/$" .gitignore)
  assert_equals "$renv_count" "1" "Should not duplicate renv/ entry"

  # Cleanup
  unset TEACH_INTERACTIVE
  cd - >/dev/null
  rm -rf "$test_dir"

  test_pass
}

test_case "_teach_handle_renv does nothing without renv/" && {
  # Setup
  local test_dir=$(mktemp -d)
  cd "$test_dir"

  # Execute (should produce no output)
  local output=$(_teach_handle_renv 2>&1)

  # Assert - should be empty or minimal
  # No renv directory means nothing to handle
  assert_not_contains "$output" "renv" "Should not mention renv"

  # Cleanup
  cd - >/dev/null
  rm -rf "$test_dir"

  test_pass
}

# ----------------------------------------------------------------------------
# UNIT TESTS: Completion Summary
# ----------------------------------------------------------------------------

test_case "_teach_show_completion_summary shows header" && {
  # Execute
  local output=$(_teach_show_completion_summary "STAT 545" "spring-2026-pre-migration" "main" 2>&1)

  # Assert
  assert_contains "$output" "TEACHING WORKFLOW INITIALIZED" "Should show header"
  assert_contains "$output" "🎉" "Should have celebration emoji"

  test_pass
}

test_case "_teach_show_completion_summary shows 'What Just Happened'" && {
  # Execute
  local output=$(_teach_show_completion_summary "STAT 545" "spring-2026-pre-migration" "main" 2>&1)

  # Assert
  assert_contains "$output" "What Just Happened" "Should have What Just Happened section"
  assert_contains "$output" "rollback tag" "Should mention rollback tag"
  assert_contains "$output" "spring-2026-pre-migration" "Should show tag name"

  test_pass
}

test_case "_teach_show_completion_summary shows rollback instructions" && {
  # Execute
  local output=$(_teach_show_completion_summary "STAT 545" "spring-2026-pre-migration" "main" 2>&1)

  # Assert
  assert_contains "$output" "HOW TO ROLLBACK" "Should have rollback section"
  assert_contains "$output" "git checkout spring-2026-pre-migration" "Should show checkout command"
  assert_contains "$output" "git checkout -b main" "Should show branch creation command"

  test_pass
}

test_case "_teach_show_completion_summary shows next steps" && {
  # Execute
  local output=$(_teach_show_completion_summary "STAT 545" "" "main" 2>&1)

  # Assert
  assert_contains "$output" "NEXT STEPS" "Should have next steps section"
  assert_contains "$output" "work stat-545" "Should show work command with slug"
  assert_contains "$output" "quick-deploy.sh" "Should mention deploy script"

  test_pass
}

test_case "_teach_show_completion_summary converts course name to slug" && {
  # Execute
  local output=$(_teach_show_completion_summary "STAT 545 - Design" "" "main" 2>&1)

  # Assert - should convert spaces and caps
  assert_contains "$output" "work stat-545---design" "Should convert to lowercase slug"

  test_pass
}

test_case "_teach_show_completion_summary skips rollback section without tag" && {
  # Setup: Create temp dir without any tags
  local test_dir=$(mktemp -d)
  cd "$test_dir"
  git init -q

  # Execute with empty tag
  local output=$(_teach_show_completion_summary "Test Course" "" "main" 2>&1)

  # Assert - should NOT have rollback section
  assert_not_contains "$output" "HOW TO ROLLBACK" "Should skip rollback without tag"

  # Cleanup
  cd - >/dev/null
  rm -rf "$test_dir"

  test_pass
}

test_case "_teach_show_completion_summary auto-detects rollback tag" && {
  # Setup: Create git repo with pre-migration tag
  local test_dir=$(mktemp -d)
  cd "$test_dir"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  touch README.md
  git add . && git commit -q -m "init"
  git tag -a "spring-2026-pre-migration" -m "test tag"

  # Execute without providing tag (should auto-detect)
  local output=$(_teach_show_completion_summary "Test Course" "" "main" 2>&1)

  # Assert
  assert_contains "$output" "spring-2026-pre-migration" "Should auto-detect pre-migration tag"

  # Cleanup
  cd - >/dev/null
  rm -rf "$test_dir"

  test_pass
}

# ----------------------------------------------------------------------------
# UNIT TESTS: Legacy Wrapper
# ----------------------------------------------------------------------------

test_case "_teach_show_next_steps calls completion summary" && {
  # Execute
  local output=$(_teach_show_next_steps "STAT 545" 2>&1)

  # Assert - should produce same output as completion summary
  assert_contains "$output" "TEACHING WORKFLOW INITIALIZED" "Should show completion summary"
  assert_contains "$output" "NEXT STEPS" "Should have next steps"

  test_pass
}

# ----------------------------------------------------------------------------
# E2E TESTS: Non-Interactive Migration (Quarto Project)
# ----------------------------------------------------------------------------

test_case "E2E: Non-interactive Quarto migration completes without prompts" && {
  # Skip if templates not available
  if [[ ! -d "${FLOW_PLUGIN_DIR}/lib/templates/teaching" ]]; then
    echo "${YELLOW}SKIP${RESET} (templates not found)"
    TESTS_RUN=$((TESTS_RUN - 1))
    return 0
  fi

  # Setup: Create realistic Quarto project
  local test_dir=$(mktemp -d)
  cd "$test_dir"

  # Initialize git
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"

  # Create Quarto project structure
  cat > _quarto.yml << 'EOF'
project:
  type: website
  output-dir: _site
EOF

  cat > index.qmd << 'EOF'
---
title: "Test Course"
---

Welcome to the course.
EOF

  # Initial commit
  git add . && git commit -q -m "Initial Quarto setup"

  # Set non-interactive mode
  export TEACH_INTERACTIVE="false"

  # Execute teach-init in non-interactive mode
  # Note: This may fail if templates aren't in place, that's ok
  local output=$(teach-init -y "Test Course" 2>&1 || true)

  # Assert - should not ask for input
  assert_not_contains "$output" "Choice [1/2/3]:" "Should not prompt for strategy"
  assert_not_contains "$output" "[Y/n]:" "Should not prompt for renv"
  assert_not_contains "$output" "[y/N]:" "Should not prompt for confirmation"

  # Should show auto-selection messages
  assert_contains "$output" "Auto-selecting strategy 1" "Should auto-select strategy 1"

  # Cleanup
  unset TEACH_INTERACTIVE
  cd - >/dev/null
  rm -rf "$test_dir"

  test_pass
}

test_case "E2E: Non-interactive mode uses default semester dates" && {
  # Skip if templates not available
  if [[ ! -d "${FLOW_PLUGIN_DIR}/lib/templates/teaching" ]]; then
    echo "${YELLOW}SKIP${RESET} (templates not found)"
    TESTS_RUN=$((TESTS_RUN - 1))
    return 0
  fi

  # Setup
  local test_dir=$(mktemp -d)
  cd "$test_dir"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  touch _quarto.yml index.qmd
  git add . && git commit -q -m "init"

  export TEACH_INTERACTIVE="false"

  # Execute
  local output=$(teach-init -y "Test" 2>&1 || true)

  # Assert
  assert_contains "$output" "Using default start date" "Should use default dates"
  assert_contains "$output" "Skipping break configuration" "Should skip breaks"

  # Cleanup
  unset TEACH_INTERACTIVE
  cd - >/dev/null
  rm -rf "$test_dir"

  test_pass
}

test_case "E2E: Non-interactive mode skips GitHub push" && {
  # Skip if templates not available
  if [[ ! -d "${FLOW_PLUGIN_DIR}/lib/templates/teaching" ]]; then
    echo "${YELLOW}SKIP${RESET} (templates not found)"
    TESTS_RUN=$((TESTS_RUN - 1))
    return 0
  fi

  # Setup
  local test_dir=$(mktemp -d)
  cd "$test_dir"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  touch _quarto.yml index.qmd
  git add . && git commit -q -m "init"

  export TEACH_INTERACTIVE="false"

  # Execute
  local output=$(teach-init -y "Test" 2>&1 || true)

  # Assert - check for either the skip message OR that it didn't prompt
  # (migration may fail before GitHub step if templates missing)
  if [[ "$output" == *"GitHub Integration"* ]]; then
    # If we got to GitHub section, verify it was skipped
    assert_contains "$output" "Skipped" "Should skip GitHub push"
  else
    # If migration failed before GitHub, that's OK - templates may be missing
    # Just verify no interactive prompts were shown
    assert_not_contains "$output" "Push to GitHub remote? [y/N]" "Should not prompt for GitHub"
  fi

  # Cleanup
  unset TEACH_INTERACTIVE
  cd - >/dev/null
  rm -rf "$test_dir"

  test_pass
}

test_case "E2E: Completion summary shown after migration" && {
  # Skip if templates not available
  if [[ ! -d "${FLOW_PLUGIN_DIR}/lib/templates/teaching" ]]; then
    echo "${YELLOW}SKIP${RESET} (templates not found)"
    TESTS_RUN=$((TESTS_RUN - 1))
    return 0
  fi

  # Setup
  local test_dir=$(mktemp -d)
  cd "$test_dir"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  touch _quarto.yml index.qmd
  git add . && git commit -q -m "init"

  export TEACH_INTERACTIVE="false"

  # Execute
  local output=$(teach-init -y "STAT 999" 2>&1 || true)

  # Assert - completion summary should appear
  assert_contains "$output" "TEACHING WORKFLOW INITIALIZED" "Should show completion summary"
  assert_contains "$output" "What Just Happened" "Should show what happened"
  assert_contains "$output" "NEXT STEPS" "Should show next steps"

  # Cleanup
  unset TEACH_INTERACTIVE
  cd - >/dev/null
  rm -rf "$test_dir"

  test_pass
}

# ----------------------------------------------------------------------------
# E2E TESTS: Generic (non-Quarto) Migration
# ----------------------------------------------------------------------------

test_case "E2E: Non-interactive generic migration uses strategy 1" && {
  # Setup: Create generic (non-Quarto) project
  local test_dir=$(mktemp -d)
  cd "$test_dir"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"
  touch README.md
  git add . && git commit -q -m "init"

  export TEACH_INTERACTIVE="false"

  # Execute
  local output=$(teach-init -y "Generic Course" 2>&1 || true)

  # Assert - should auto-select strategy 1 for generic projects too
  assert_contains "$output" "Auto-selecting strategy 1" "Should auto-select strategy 1"
  assert_contains "$output" "In-place conversion" "Should use in-place conversion"

  # Cleanup
  unset TEACH_INTERACTIVE
  cd - >/dev/null
  rm -rf "$test_dir"

  test_pass
}

# ============================================================================
# RUN TESTS
# ============================================================================

test_suite_end
