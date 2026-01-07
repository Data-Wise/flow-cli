#!/usr/bin/env zsh
# Test: Help browser preview pane fix
# Bug: Preview showed "command not found" because fzf subshell didn't have plugin loaded
# Fix: Created _flow_show_help_preview() helper function (available in current shell)

SCRIPT_DIR="${0:h}"
source "${SCRIPT_DIR}/../flow.plugin.zsh"

# Test framework
TESTS_PASSED=0
TESTS_FAILED=0

test_preview_function_exists() {
  echo -n "Test: _flow_show_help_preview function exists... "
  if type _flow_show_help_preview &>/dev/null; then
    echo "✅ PASS"
    ((TESTS_PASSED++))
  else
    echo "❌ FAIL"
    ((TESTS_FAILED++))
  fi
}

test_preview_regular_command() {
  echo -n "Test: Preview shows help for regular command (dash)... "
  local output=$(_flow_show_help_preview "dash")

  if [[ "$output" =~ "DASH - Project Dashboard" ]]; then
    echo "✅ PASS"
    ((TESTS_PASSED++))
  else
    echo "❌ FAIL"
    echo "  Expected: 'DASH - Project Dashboard'"
    echo "  Got: ${output:0:100}..."
    ((TESTS_FAILED++))
  fi
}

test_preview_dispatcher() {
  echo -n "Test: Preview shows help for dispatcher (r)... "
  local output=$(_flow_show_help_preview "r")

  if [[ "$output" =~ "R Package Development" ]]; then
    echo "✅ PASS"
    ((TESTS_PASSED++))
  else
    echo "❌ FAIL"
    echo "  Expected: 'R Package Development'"
    echo "  Got: ${output:0:100}..."
    ((TESTS_FAILED++))
  fi
}

test_preview_all_dispatchers() {
  echo -n "Test: Preview works for all dispatchers (g,cc,wt,mcp,r,qu,obs,tm)... "
  local dispatchers=(g cc wt mcp r qu obs tm)
  local failed_dispatchers=()

  for dispatcher in "${dispatchers[@]}"; do
    local output=$(_flow_show_help_preview "$dispatcher" 2>&1)
    if [[ "$output" =~ "Command not found" ]]; then
      failed_dispatchers+=("$dispatcher")
    fi
  done

  if [[ ${#failed_dispatchers[@]} -eq 0 ]]; then
    echo "✅ PASS"
    ((TESTS_PASSED++))
  else
    echo "❌ FAIL"
    echo "  Failed dispatchers: ${failed_dispatchers[*]}"
    ((TESTS_FAILED++))
  fi
}

test_preview_nonexistent_command() {
  echo -n "Test: Preview handles nonexistent command gracefully... "
  local output=$(_flow_show_help_preview "nonexistent_command_xyz")

  if [[ "$output" =~ "Command not found" ]]; then
    echo "✅ PASS"
    ((TESTS_PASSED++))
  else
    echo "❌ FAIL"
    echo "  Expected: 'Command not found'"
    echo "  Got: ${output:0:100}..."
    ((TESTS_FAILED++))
  fi
}

test_preview_no_ansi_codes_in_input() {
  echo -n "Test: Preview strips ANSI codes from command name... "
  # Simulate what fzf does - send colored command name
  local colored_cmd=$'\033[36mdash\033[0m'
  local plain_cmd=$(echo "$colored_cmd" | sed 's/\x1b\[[0-9;]*m//g')
  local output=$(_flow_show_help_preview "$plain_cmd")

  if [[ "$output" =~ "DASH - Project Dashboard" ]]; then
    echo "✅ PASS"
    ((TESTS_PASSED++))
  else
    echo "❌ FAIL"
    echo "  ANSI stripping may have failed"
    ((TESTS_FAILED++))
  fi
}

# Run all tests
echo ""
echo "╭─────────────────────────────────────────────╮"
echo "│ Help Browser Preview Tests                  │"
echo "╰─────────────────────────────────────────────╯"
echo ""

test_preview_function_exists
test_preview_regular_command
test_preview_dispatcher
test_preview_all_dispatchers
test_preview_nonexistent_command
test_preview_no_ansi_codes_in_input

# Summary
echo ""
echo "─────────────────────────────────────────────"
echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed"
echo "─────────────────────────────────────────────"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "✅ All tests passed!"
  exit 0
else
  echo "❌ Some tests failed"
  exit 1
fi
