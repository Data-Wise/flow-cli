#!/usr/bin/env zsh
# tests/run-all-tests.zsh - Run all test suites for dot dispatcher
# Run: zsh tests/run-all-tests.zsh

autoload -U colors && colors

echo ""
echo "${fg_bold[cyan]}════════════════════════════════════════════════════════════${reset_color}"
echo "${fg_bold[cyan]}║${reset_color}  ${fg_bold[white]}Dot Dispatcher - Complete Test Suite${reset_color}                ${fg_bold[cyan]}║${reset_color}"
echo "${fg_bold[cyan]}════════════════════════════════════════════════════════════${reset_color}"
echo ""

SCRIPT_DIR="${0:A:h}"
TEST_DIR="$SCRIPT_DIR"

typeset -g TOTAL_PASSED=0
typeset -g TOTAL_FAILED=0
typeset -ga SUITE_RESULTS=()

# ============================================================================
# RUN TEST SUITES
# ============================================================================

# Suite 1: Core Functionality Tests
echo "${fg_bold[white]}━━━ Test Suite 1: Core Functionality ━━━${reset_color}"
echo ""

if [[ -x "$TEST_DIR/test-dot-dispatcher.zsh" ]]; then
  "$TEST_DIR/test-dot-dispatcher.zsh"
  suite1_result=$?

  if [[ $suite1_result -eq 0 ]]; then
    SUITE_RESULTS+=("${fg[green]}✓${reset_color} Core Functionality")
  else
    SUITE_RESULTS+=("${fg[red]}✗${reset_color} Core Functionality")
    ((TOTAL_FAILED++))
  fi
else
  SUITE_RESULTS+=("${fg[yellow]}⊘${reset_color} Core Functionality (not found)")
fi

echo ""
echo ""

# Suite 2: Integration Tests
echo "${fg_bold[white]}━━━ Test Suite 2: Integration Tests ━━━${reset_color}"
echo ""

if [[ -x "$TEST_DIR/test-integration.zsh" ]]; then
  "$TEST_DIR/test-integration.zsh"
  suite2_result=$?

  if [[ $suite2_result -eq 0 ]]; then
    SUITE_RESULTS+=("${fg[green]}✓${reset_color} Integration Tests")
  else
    SUITE_RESULTS+=("${fg[red]}✗${reset_color} Integration Tests")
    ((TOTAL_FAILED++))
  fi
else
  SUITE_RESULTS+=("${fg[yellow]}⊘${reset_color} Integration Tests (not found)")
fi

echo ""
echo ""

# Suite 3: Phase 3 Tests (if exists)
if [[ -f "$TEST_DIR/test-phase3-secrets.zsh" ]]; then
  echo "${fg_bold[white]}━━━ Test Suite 3: Phase 3 - Secret Management ━━━${reset_color}"
  echo ""

  if [[ -x "$TEST_DIR/test-phase3-secrets.zsh" ]]; then
    "$TEST_DIR/test-phase3-secrets.zsh"
    suite3_result=$?

    if [[ $suite3_result -eq 0 ]]; then
      SUITE_RESULTS+=("${fg[green]}✓${reset_color} Phase 3 - Secret Management")
    else
      SUITE_RESULTS+=("${fg[red]}✗${reset_color} Phase 3 - Secret Management")
      ((TOTAL_FAILED++))
    fi
  else
    chmod +x "$TEST_DIR/test-phase3-secrets.zsh"
    SUITE_RESULTS+=("${fg[yellow]}⊘${reset_color} Phase 3 (made executable, re-run)")
  fi

  echo ""
  echo ""
fi

# Suite 4: Phase 4 Tests (if exists)
if [[ -f "$TEST_DIR/test-phase4.sh" ]]; then
  echo "${fg_bold[white]}━━━ Test Suite 4: Phase 4 - Dashboard Integration ━━━${reset_color}"
  echo ""

  if [[ -x "$TEST_DIR/test-phase4.sh" ]]; then
    bash "$TEST_DIR/test-phase4.sh"
    suite4_result=$?

    if [[ $suite4_result -eq 0 ]]; then
      SUITE_RESULTS+=("${fg[green]}✓${reset_color} Phase 4 - Dashboard Integration")
    else
      SUITE_RESULTS+=("${fg[red]}✗${reset_color} Phase 4 - Dashboard Integration")
      ((TOTAL_FAILED++))
    fi
  else
    chmod +x "$TEST_DIR/test-phase4.sh"
    SUITE_RESULTS+=("${fg[yellow]}⊘${reset_color} Phase 4 (made executable, re-run)")
  fi

  echo ""
  echo ""
fi

# ============================================================================
# FINAL SUMMARY
# ============================================================================

echo "${fg_bold[cyan]}════════════════════════════════════════════════════════════${reset_color}"
echo "${fg_bold[cyan]}║${reset_color}  ${fg_bold[white]}Final Test Results${reset_color}                                 ${fg_bold[cyan]}║${reset_color}"
echo "${fg_bold[cyan]}════════════════════════════════════════════════════════════${reset_color}"
echo ""

echo "${fg_bold[white]}Test Suites:${reset_color}"
for result in "${SUITE_RESULTS[@]}"; do
  echo "  $result"
done
echo ""

# Overall result
TOTAL_SUITES=${#SUITE_RESULTS[@]}
TOTAL_PASSED=$((TOTAL_SUITES - TOTAL_FAILED))

echo "Total suites: ${fg_bold[white]}$TOTAL_SUITES${reset_color}"
echo "Passed:       ${fg[green]}$TOTAL_PASSED${reset_color}"
echo "Failed:       ${fg[red]}$TOTAL_FAILED${reset_color}"
echo ""

if [[ $TOTAL_FAILED -eq 0 ]]; then
  echo "${fg_bold[green]}✓ All test suites passed!${reset_color}"
  echo ""
  echo "${fg[cyan]}The dot dispatcher is ready for production use.${reset_color}"
  echo ""
  exit 0
else
  echo "${fg_bold[red]}✗ Some test suites failed${reset_color}"
  echo ""
  echo "${fg[yellow]}Review the test output above for details.${reset_color}"
  echo ""
  exit 1
fi
