#!/usr/bin/env zsh
# tests/test-integration.zsh - Integration tests for dot dispatcher
# Tests full workflows with real chezmoi/bitwarden if available
# Run: zsh tests/test-integration.zsh

# ============================================================================
# SETUP
# ============================================================================

autoload -U colors && colors

typeset -g TESTS_RUN=0
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0
typeset -ga TEST_WARNINGS=()

test_info() {
  echo "${fg[cyan]}ℹ${reset_color} $1"
}

test_pass() {
  ((TESTS_PASSED++))
  echo "${fg[green]}✓${reset_color} $1"
}

test_fail() {
  ((TESTS_FAILED++))
  echo "${fg[red]}✗${reset_color} $1"
  [[ -n "$2" ]] && echo "  ${fg[yellow]}→${reset_color} $2"
}

test_warn() {
  TEST_WARNINGS+=("$1")
  echo "${fg[yellow]}⚠${reset_color} $1"
}

test_skip() {
  echo "${fg[yellow]}⊘${reset_color} $1"
}

echo ""
echo "${fg[cyan]}════════════════════════════════════════════════════════════${reset_color}"
echo "${fg[cyan]}║${reset_color}  ${fg_bold[white]}Dot Dispatcher - Integration Tests${reset_color}                ${fg[cyan]}║${reset_color}"
echo "${fg[cyan]}════════════════════════════════════════════════════════════${reset_color}"
echo ""

# Load plugin
SCRIPT_DIR="${0:A:h}"
PLUGIN_DIR="${SCRIPT_DIR:h}"

test_info "Loading plugin from: $PLUGIN_DIR"
source "$PLUGIN_DIR/flow.plugin.zsh"

if [[ $? -ne 0 ]]; then
  test_fail "Plugin load" "Failed to source flow.plugin.zsh"
  exit 1
fi

test_pass "Plugin loaded"
echo ""

# ============================================================================
# TEST SUITE 1: ENVIRONMENT CHECKS
# ============================================================================

echo "${fg_bold[white]}Test Suite 1: Environment Checks${reset_color}"
echo "${fg[cyan]}────────────────────────────────────────────────────────────${reset_color}"
echo ""

# Check for chezmoi
((TESTS_RUN++))
if command -v chezmoi >/dev/null 2>&1; then
  CHEZMOI_AVAILABLE=true
  version=$(chezmoi --version 2>&1 | head -1)
  test_pass "Chezmoi available: $version"
else
  CHEZMOI_AVAILABLE=false
  test_skip "Chezmoi not installed - some tests will be skipped"
fi

# Check for Bitwarden CLI
((TESTS_RUN++))
if command -v bw >/dev/null 2>&1; then
  BW_AVAILABLE=true
  version=$(bw --version 2>&1)
  test_pass "Bitwarden CLI available: $version"
else
  BW_AVAILABLE=false
  test_skip "Bitwarden CLI not installed - secret tests will be skipped"
fi

# Check for jq (optional)
if command -v jq >/dev/null 2>&1; then
  test_pass "jq available (optional)"
else
  test_skip "jq not installed - secret list may have degraded formatting"
fi
((TESTS_RUN++))

echo ""

# ============================================================================
# TEST SUITE 2: CHEZMOI INTEGRATION
# ============================================================================

echo "${fg_bold[white]}Test Suite 2: Chezmoi Integration${reset_color}"
echo "${fg[cyan]}────────────────────────────────────────────────────────────${reset_color}"
echo ""

if [[ "$CHEZMOI_AVAILABLE" == "true" ]]; then
  # Test: Check if chezmoi is initialized
  ((TESTS_RUN++))
  if [[ -d "$HOME/.local/share/chezmoi" ]]; then
    test_pass "Chezmoi is initialized"
    CHEZMOI_INITIALIZED=true

    # Test: Check if it's a git repo
    ((TESTS_RUN++))
    if [[ -d "$HOME/.local/share/chezmoi/.git" ]]; then
      test_pass "Chezmoi has git initialized"

      # Test: Check for remote
      ((TESTS_RUN++))
      if (cd "$HOME/.local/share/chezmoi" && git remote get-url origin >/dev/null 2>&1); then
        remote_url=$(cd "$HOME/.local/share/chezmoi" && git remote get-url origin)
        test_pass "Git remote configured: $remote_url"
      else
        test_warn "No git remote configured"
      fi
    else
      test_skip "Chezmoi not using git"
    fi

    # Test: Get sync status
    ((TESTS_RUN++))
    sync_status=$(_dots_get_sync_status 2>/dev/null)
    if [[ -n "$sync_status" ]]; then
      test_pass "Sync status check works: $sync_status"
    else
      test_fail "Sync status check" "Empty status returned"
    fi

    # Test: Get tracked count
    ((TESTS_RUN++))
    tracked_count=$(_dots_get_tracked_count 2>/dev/null)
    if [[ "$tracked_count" =~ ^[0-9]+$ ]]; then
      test_pass "Tracked file count works: $tracked_count files"
    else
      test_fail "Tracked file count" "Invalid count: $tracked_count"
    fi

    # Test: Get modified count
    ((TESTS_RUN++))
    modified_count=$(_dots_get_modified_count 2>/dev/null)
    if [[ "$modified_count" =~ ^[0-9]+$ ]]; then
      test_pass "Modified file count works: $modified_count files"
    else
      test_fail "Modified file count" "Invalid count: $modified_count"
    fi

    # Test: Status command
    ((TESTS_RUN++))
    output=$(dots status 2>&1)
    if [[ $? -eq 0 ]] && [[ -n "$output" ]]; then
      test_pass "dots status command works"
    else
      test_fail "dots status command" "Command failed or empty output"
    fi

  else
    CHEZMOI_INITIALIZED=false
    test_skip "Chezmoi not initialized - run 'chezmoi init' to enable full tests"
  fi
else
  test_skip "Chezmoi not available - skipping integration tests"
fi

echo ""

# ============================================================================
# TEST SUITE 3: BITWARDEN INTEGRATION
# ============================================================================

echo "${fg_bold[white]}Test Suite 3: Bitwarden Integration${reset_color}"
echo "${fg[cyan]}────────────────────────────────────────────────────────────${reset_color}"
echo ""

if [[ "$BW_AVAILABLE" == "true" ]]; then
  # Test: Get Bitwarden status
  ((TESTS_RUN++))
  bw_status=$(_dotf_bw_get_status 2>/dev/null)
  if [[ -n "$bw_status" ]]; then
    test_pass "Bitwarden status check works: $bw_status"

    # Additional tests based on status
    case "$bw_status" in
      unlocked)
        test_info "Bitwarden is unlocked - testing secret operations"

        # Test: Session validation
        ((TESTS_RUN++))
        if _dotf_bw_session_valid; then
          test_pass "Session validation works"

          # Test: Secret list (if jq available)
          if command -v jq >/dev/null 2>&1; then
            ((TESTS_RUN++))
            output=$(sec list 2>&1)
            if [[ $? -eq 0 ]]; then
              test_pass "sec list works"
            else
              test_warn "sec list failed (vault may be empty)"
            fi
          fi
        else
          test_warn "Session validation failed despite unlocked status"
        fi
        ;;

      locked)
        test_info "Bitwarden is locked - secret tests require unlock"
        test_info "Run 'sec unlock' to enable secret tests"
        ;;

      unauthenticated)
        test_warn "Bitwarden not authenticated - run 'bw login'"
        ;;

      *)
        test_warn "Unknown Bitwarden status: $bw_status"
        ;;
    esac
  else
    test_fail "Bitwarden status check" "Empty status returned"
  fi

  # Test: Security check
  ((TESTS_RUN++))
  if _dotf_security_check_bw_session; then
    test_pass "Security check passes (no global BW_SESSION)"
  else
    test_fail "Security check" "Found security issue with BW_SESSION"
  fi

else
  test_skip "Bitwarden CLI not available - skipping integration tests"
fi

echo ""

# ============================================================================
# TEST SUITE 4: DASHBOARD INTEGRATION
# ============================================================================

echo "${fg_bold[white]}Test Suite 4: Dashboard Integration${reset_color}"
echo "${fg[cyan]}────────────────────────────────────────────────────────────${reset_color}"
echo ""

if [[ "$CHEZMOI_AVAILABLE" == "true" ]] && [[ "$CHEZMOI_INITIALIZED" == "true" ]]; then
  # Test: Dashboard status line
  ((TESTS_RUN++))
  status_line=$(_dots_get_status_line 2>/dev/null)
  if [[ $? -eq 0 ]] && [[ -n "$status_line" ]]; then
    test_pass "Dashboard status line generation"
    test_info "Status line: $status_line"
  else
    test_warn "Dashboard status line empty (may be expected)"
  fi

  # Test: Dashboard function
  ((TESTS_RUN++))
  output=$(_dash_dotfiles 2>/dev/null)
  if [[ $? -eq 0 ]]; then
    test_pass "Dashboard dotfiles function runs"
  else
    test_fail "Dashboard dotfiles function" "Function returned error"
  fi

  # Test: Full dashboard (if available)
  if (( $+functions[dash] )); then
    ((TESTS_RUN++))
    output=$(dash 2>&1)
    if [[ $? -eq 0 ]] && [[ "$output" == *"Dotfiles"* ]]; then
      test_pass "Dashboard includes dotfile status"
    else
      test_warn "Dashboard may not include dotfile status (check output)"
    fi
  fi
else
  test_skip "Dashboard tests require initialized chezmoi"
fi

echo ""

# ============================================================================
# TEST SUITE 5: DOCTOR INTEGRATION
# ============================================================================

echo "${fg_bold[white]}Test Suite 5: Doctor Integration${reset_color}"
echo "${fg[cyan]}────────────────────────────────────────────────────────────${reset_color}"
echo ""

# Test: Doctor dotfile function
((TESTS_RUN++))
output=$(_dots_doctor 2>&1)
if [[ $? -eq 0 ]] && [[ -n "$output" ]]; then
  test_pass "Doctor dotfile check runs"

  # Verify output contains expected elements
  if [[ "$output" == *"DOTFILES"* ]]; then
    test_pass "Doctor output includes DOTFILES section"
  else
    test_warn "Doctor output may not include DOTFILES header"
  fi
  ((TESTS_RUN++))
else
  test_fail "Doctor dotfile check" "Function failed or empty output"
fi

# Test: Full doctor command (if available)
if (( $+functions[doctor] )); then
  ((TESTS_RUN++))
  output=$(doctor 2>&1)
  if [[ $? -eq 0 ]] && [[ "$output" == *"DOTFILES"* ]]; then
    test_pass "Flow doctor includes dotfile checks"
  else
    test_warn "Flow doctor may not include dotfile checks"
  fi
fi

echo ""

# ============================================================================
# TEST SUITE 6: PERFORMANCE CHECKS
# ============================================================================

echo "${fg_bold[white]}Test Suite 6: Performance Checks${reset_color}"
echo "${fg[cyan]}────────────────────────────────────────────────────────────${reset_color}"
echo ""

if [[ "$CHEZMOI_INITIALIZED" == "true" ]]; then
  # Test: Status check performance
  ((TESTS_RUN++))
  start_time=$SECONDS
  dots status >/dev/null 2>&1
  end_time=$SECONDS
  duration=$((end_time - start_time))

  if [[ $duration -le 1 ]]; then
    test_pass "Status check completes quickly (${duration}s < 1s)"
  else
    test_warn "Status check took ${duration}s (target: < 1s)"
  fi

  # Test: Dashboard status line performance
  ((TESTS_RUN++))
  start_time=$SECONDS
  _dots_get_status_line >/dev/null 2>&1
  end_time=$SECONDS
  duration=$((end_time - start_time))

  if [[ $duration -eq 0 ]]; then
    test_pass "Dashboard status line is fast (< 1s)"
  else
    test_warn "Dashboard status line took ${duration}s (target: < 0.1s)"
  fi
else
  test_skip "Performance tests require initialized chezmoi"
fi

echo ""

# ============================================================================
# TEST SUITE 7: ERROR HANDLING
# ============================================================================

echo "${fg_bold[white]}Test Suite 7: Error Handling${reset_color}"
echo "${fg[cyan]}────────────────────────────────────────────────────────────${reset_color}"
echo ""

# Test: Invalid command handling
((TESTS_RUN++))
output=$(dots invalid_command_xyz 2>&1)
if [[ $? -ne 0 ]] || [[ "$output" == *"help"* ]]; then
  test_pass "Invalid commands handled gracefully"
else
  test_warn "Invalid command may need better error handling"
fi

# Test: Missing tool handling
if [[ "$CHEZMOI_AVAILABLE" != "true" ]]; then
  ((TESTS_RUN++))
  output=$(dots status 2>&1)
  if [[ "$output" == *"not found"* ]] || [[ "$output" == *"not installed"* ]]; then
    test_pass "Missing chezmoi handled gracefully"
  else
    test_warn "Missing chezmoi error message could be clearer"
  fi
fi

echo ""

# ============================================================================
# TEST SUMMARY
# ============================================================================

echo ""
echo "${fg[cyan]}════════════════════════════════════════════════════════════${reset_color}"
echo "${fg[cyan]}║${reset_color}  ${fg_bold[white]}Integration Test Results${reset_color}                           ${fg[cyan]}║${reset_color}"
echo "${fg[cyan]}════════════════════════════════════════════════════════════${reset_color}"
echo ""

echo "Tests run:    ${fg_bold[white]}$TESTS_RUN${reset_color}"
echo "Tests passed: ${fg[green]}$TESTS_PASSED${reset_color}"
echo "Tests failed: ${fg[red]}$TESTS_FAILED${reset_color}"

if [[ ${#TEST_WARNINGS[@]} -gt 0 ]]; then
  echo "Warnings:     ${fg[yellow]}${#TEST_WARNINGS[@]}${reset_color}"
fi

echo ""

# Show warnings
if [[ ${#TEST_WARNINGS[@]} -gt 0 ]]; then
  echo "${fg_bold[yellow]}Warnings:${reset_color}"
  for warning in "${TEST_WARNINGS[@]}"; do
    echo "  ${fg[yellow]}⚠${reset_color} $warning"
  done
  echo ""
fi

# Environment info
echo "${fg_bold[white]}Environment:${reset_color}"
echo "  Chezmoi:    ${CHEZMOI_AVAILABLE:-false} ${CHEZMOI_INITIALIZED:+(initialized)}"
echo "  Bitwarden:  ${BW_AVAILABLE:-false}"
echo ""

# Final result
if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "${fg_bold[green]}✓ All integration tests passed!${reset_color}"
  echo ""
  exit 0
else
  echo "${fg_bold[red]}✗ Some integration tests failed${reset_color}"
  echo ""
  exit 1
fi
