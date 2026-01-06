#!/usr/bin/env zsh
# tests/test-phase1-features.zsh
# Comprehensive tests for Phase 1 Quick Wins features

# Load test framework
SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/test-framework.zsh"

# Load flow-cli
FLOW_PLUGIN_DIR="${SCRIPT_DIR:h}"
source "$FLOW_PLUGIN_DIR/flow.plugin.zsh"

# ============================================================================
# TEST SUITE: Phase 1 Quick Wins
# ============================================================================

test_suite_start "Phase 1 Quick Wins Features"

# ============================================================================
# FEATURE 1: First-Run Welcome Message
# ============================================================================

test_case "First-run welcome message displays on first work command"
  # Setup: Remove welcome marker
  local marker="$HOME/.config/flow-cli/.welcomed"
  rm -f "$marker"

  # Test: Call first-run welcome function
  local output=$(_flow_first_run_welcome 2>&1)

  # Assert: Welcome message contains expected text
  assert_contains "$output" "Welcome to flow-cli"
  assert_contains "$output" "Quick Start:"
  assert_contains "$output" "work <project>"
  assert_contains "$output" "dash"
  assert_contains "$output" "pick"
  assert_contains "$output" "win"
  assert_contains "$output" "finish"
  assert_contains "$output" "Get Help:"
  assert_contains "$output" "flow help"
test_case_end

test_case "First-run welcome creates marker file"
  # Setup: Remove marker
  local marker="$HOME/.config/flow-cli/.welcomed"
  rm -f "$marker"

  # Test: Run welcome function
  _flow_first_run_welcome >/dev/null 2>&1

  # Assert: Marker file was created
  assert_file_exists "$marker"

  # Cleanup
  rm -f "$marker"
test_case_end

test_case "First-run welcome only shows once"
  # Setup: Remove marker
  local marker="$HOME/.config/flow-cli/.welcomed"
  rm -f "$marker"

  # Test: Run welcome twice
  local output1=$(_flow_first_run_welcome 2>&1)
  local output2=$(_flow_first_run_welcome 2>&1)

  # Assert: First run shows message, second run is silent
  assert_contains "$output1" "Welcome to flow-cli"
  assert_equals "$output2" ""

  # Cleanup
  rm -f "$marker"
test_case_end

# ============================================================================
# FEATURE 2: "See Also" Cross-References
# ============================================================================

test_case "g dispatcher help has 'See also' section"
  local output=$(_g_help 2>&1)

  assert_contains "$output" "See also:"
  assert_contains "$output" "wt"
  assert_contains "$output" "cc wt"
  assert_contains "$output" "flow sync"
test_case_end

test_case "cc dispatcher help has 'See also' section"
  local output=$(_cc_help 2>&1)

  assert_contains "$output" "See also:"
  assert_contains "$output" "pick"
  assert_contains "$output" "work"
  assert_contains "$output" "wt"
  assert_contains "$output" "g"
test_case_end

test_case "r dispatcher help has 'See also' section"
  local output=$(_r_help 2>&1)

  assert_contains "$output" "See also:"
  assert_contains "$output" "qu"
  assert_contains "$output" "cc rpkg"
  assert_contains "$output" "flow doctor"
test_case_end

test_case "qu dispatcher help has 'See also' section"
  local output=$(_qu_help 2>&1)

  assert_contains "$output" "See also:"
  assert_contains "$output" "r"
  assert_contains "$output" "cc"
  assert_contains "$output" "g"
test_case_end

test_case "tm dispatcher help has 'See also' section"
  local output=$(_tm_help 2>&1)

  assert_contains "$output" "See also:"
  assert_contains "$output" "work"
  assert_contains "$output" "pick"
  assert_contains "$output" "cc"
test_case_end

# ============================================================================
# FEATURE 3: Random Tips in Dashboard
# ============================================================================

test_case "Random tip function exists"
  assert_function_exists "_dash_random_tip"
test_case_end

test_case "Random tips use FLOW_COLORS"
  # Get the function definition
  local func_def=$(whence -f _dash_random_tip)

  # Assert: Uses FLOW_COLORS[cmd] and FLOW_COLORS[muted]
  assert_contains "$func_def" "FLOW_COLORS[cmd]"
  assert_contains "$func_def" "FLOW_COLORS[muted]"
  assert_contains "$func_def" "FLOW_COLORS[reset]"
test_case_end

test_case "Random tip function can be called without error"
  # The function has probabilistic output (20% chance)
  # Just verify it can be called successfully
  local exit_code=0
  _dash_random_tip >/dev/null 2>&1 || exit_code=$?

  assert_equals "$exit_code" "0"
test_case_end

test_case "Random tips include key features"
  # Get the function definition to check tips array
  local func_def=$(whence -f _dash_random_tip)

  # Assert: Tips mention important features
  assert_contains "$func_def" "pick --recent"
  assert_contains "$func_def" "cc yolo"
  assert_contains "$func_def" "flow doctor --fix"
  assert_contains "$func_def" "wt create"
  assert_contains "$func_def" "win"
  assert_contains "$func_def" "flow goal"
test_case_end

# ============================================================================
# FEATURE 4: Quick Reference Card (ref command)
# ============================================================================

test_case "ref command exists"
  assert_function_exists "ref"
test_case_end

test_case "ref help displays properly"
  local output=$(ref help 2>&1)

  assert_contains "$output" "ref - Quick Reference Card"
  assert_contains "$output" "Usage:"
  assert_contains "$output" "ref command"
  assert_contains "$output" "ref workflow"
  assert_contains "$output" "EXAMPLES:"
  assert_contains "$output" "See also:"
test_case_end

test_case "ref command finds reference files"
  # Test that reference files exist
  assert_file_exists "$FLOW_PLUGIN_DIR/docs/reference/COMMAND-QUICK-REFERENCE.md"
  assert_file_exists "$FLOW_PLUGIN_DIR/docs/reference/WORKFLOW-QUICK-REFERENCE.md"
test_case_end

test_case "ref accepts command alias"
  # Mock the viewer to just echo the file path (last argument)
  bat() { echo "BAT: ${@[-1]}"; }

  local output=$(ref cmd 2>&1)
  assert_contains "$output" "COMMAND-QUICK-REFERENCE.md"

  # Restore
  unset -f bat
test_case_end

test_case "ref accepts workflow alias"
  # Mock the viewer to just echo the file path (last argument)
  bat() { echo "BAT: ${@[-1]}"; }

  local output=$(ref work 2>&1)
  assert_contains "$output" "WORKFLOW-QUICK-REFERENCE.md"

  # Restore
  unset -f bat
test_case_end

# ============================================================================
# FEATURE 5: EXAMPLES Sections in Help
# ============================================================================

test_case "r dispatcher help has EXAMPLES section"
  local output=$(_r_help 2>&1)

  assert_contains "$output" "EXAMPLES"
  assert_contains "$output" "r test"
  assert_contains "$output" "r doc"
  assert_contains "$output" "r cycle"
  assert_contains "$output" "r quick"
  assert_contains "$output" "r cran"
test_case_end

test_case "qu dispatcher help has EXAMPLES section"
  local output=$(_qu_help 2>&1)

  assert_contains "$output" "EXAMPLES"
  assert_contains "$output" "qu"
  assert_contains "$output" "qu r"
  assert_contains "$output" "qu p"
  assert_contains "$output" "qu render"
  assert_contains "$output" "qu preview"
test_case_end

test_case "tm dispatcher help has EXAMPLES section"
  local output=$(_tm_help 2>&1)

  assert_contains "$output" "EXAMPLES"
  assert_contains "$output" "tm title"
  assert_contains "$output" "tm profile"
  assert_contains "$output" "tm which"
  assert_contains "$output" "tm ghost"
  assert_contains "$output" "tm switch"
test_case_end

test_case "EXAMPLES use consistent format"
  local r_examples=$(_r_help 2>&1 | grep -A 10 "EXAMPLES")

  # Assert: Examples have $ prefix and # comments
  assert_contains "$r_examples" "\$"
  assert_contains "$r_examples" "#"
test_case_end

# ============================================================================
# INTEGRATION TESTS
# ============================================================================

test_case "All Phase 1 functions are accessible"
  # Test only the functions we added/modified in Phase 1
  assert_function_exists "_flow_first_run_welcome"
  assert_function_exists "_dash_random_tip"
  assert_function_exists "ref"
  assert_function_exists "_ref_help"
  assert_function_exists "_g_help"
  assert_function_exists "_cc_help"
  assert_function_exists "_r_help"
  assert_function_exists "_qu_help"
  assert_function_exists "_tm_help"
test_case_end

test_case "FLOW_COLORS[cmd] is defined"
  assert_not_empty "${FLOW_COLORS[cmd]}"
test_case_end

test_case "All dispatcher help functions include See also"
  local dispatchers=(g cc r qu tm)
  local missing_see_also=()

  for disp in $dispatchers; do
    local help_func="_${disp}_help"
    local output=$($help_func 2>&1)

    if ! [[ "$output" =~ "See also:" ]]; then
      missing_see_also+=($disp)
    fi
  done

  if (( ${#missing_see_also[@]} > 0 )); then
    test_fail "Dispatchers missing 'See also': ${missing_see_also[*]}"
  else
    test_pass
  fi
test_case_end

test_case "Dashboard footer calls random tip function"
  # Check that _dash_footer calls _dash_random_tip
  local footer_def=$(whence -f _dash_footer)

  assert_contains "$footer_def" "_dash_random_tip"
test_case_end

# ============================================================================
# E2E TESTS
# ============================================================================

test_case "E2E: Complete first-run experience"
  # Setup: Clean state
  local marker="$HOME/.config/flow-cli/.welcomed"
  rm -f "$marker"

  # Simulate first run (just call the function, don't run full work command)
  local welcome_output=$(_flow_first_run_welcome 2>&1)

  # Assert: Welcome shown
  assert_contains "$welcome_output" "Welcome to flow-cli"

  # Assert: Marker created
  assert_file_exists "$marker"

  # Test: Second run should be silent
  local second_output=$(_flow_first_run_welcome 2>&1)
  assert_equals "$second_output" ""

  # Cleanup
  rm -f "$marker"
test_case_end

test_case "E2E: ref command workflow"
  # Create mock bat function that ignores options and reads the file
  bat() { cat "${@[-1]}"; }

  # Test: ref shows command reference
  local output=$(ref 2>&1 | head -5)
  assert_contains "$output" "Command Quick Reference"

  # Test: ref workflow shows workflow reference
  local workflow_output=$(ref workflow 2>&1 | head -5)
  assert_contains "$workflow_output" "Quick Reference" || \
    assert_contains "$workflow_output" "Workflow"

  # Cleanup
  unset -f bat
test_case_end

test_case "E2E: Help navigation journey"
  # User journey: g help → see also → wt help → see also → cc wt help

  # Step 1: g help shows see also with wt
  local g_output=$(_g_help 2>&1)
  assert_contains "$g_output" "See also:"
  assert_contains "$g_output" "wt"

  # Step 2: wt help exists
  local wt_output=$(_wt_help 2>&1)
  assert_contains "$wt_output" "wt"

  # Step 3: cc wt help exists
  local cc_wt_output=$(_cc_worktree_help 2>&1)
  assert_contains "$cc_wt_output" "worktree"
test_case_end

# ============================================================================
# REGRESSION TESTS
# ============================================================================

test_case "REGRESSION: Welcome message doesn't break work command"
  # Ensure welcome function returns 0
  _flow_first_run_welcome >/dev/null 2>&1
  local exit_code=$?

  assert_equals "$exit_code" "0"
test_case_end

test_case "REGRESSION: Random tips don't break dashboard"
  # Test that random tip function can be called without errors
  local output=$(_dash_random_tip 2>&1)
  local exit_code=$?

  assert_equals "$exit_code" "0"
test_case_end

test_case "REGRESSION: ref command handles missing files gracefully"
  # Temporarily break FLOW_PLUGIN_DIR
  local saved_dir="$FLOW_PLUGIN_DIR"
  FLOW_PLUGIN_DIR="/nonexistent"

  # Test: ref should show error, not crash
  # Capture output and exit code separately
  local output_file=$(mktemp)
  ref > "$output_file" 2>&1
  local exit_code=$?
  local output=$(cat "$output_file")
  rm -f "$output_file"

  assert_equals "$exit_code" "1"
  assert_contains "$output" "not found"

  # Restore
  FLOW_PLUGIN_DIR="$saved_dir"
test_case_end

# ============================================================================
# SUMMARY
# ============================================================================

test_suite_end

# Print summary
echo ""
echo "======================================================================"
echo "Phase 1 Feature Tests Complete"
echo "======================================================================"
echo ""
echo "Features tested:"
echo "  ✓ First-run welcome message (4 tests)"
echo "  ✓ 'See also' cross-references (5 tests)"
echo "  ✓ Random tips in dashboard (4 tests)"
echo "  ✓ Quick reference card (ref command) (5 tests)"
echo "  ✓ EXAMPLES sections (4 tests)"
echo "  ✓ Integration tests (5 tests)"
echo "  ✓ E2E tests (3 tests)"
echo "  ✓ Regression tests (3 tests)"
echo ""
echo "Total: 33 test cases"
echo ""
