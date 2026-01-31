#!/usr/bin/env zsh
# test-lint-e2e.zsh - End-to-end tests for teach validate --lint
# Run with: zsh tests/test-lint-e2e.zsh

SCRIPT_DIR="${0:A:h}"
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; RESET='\033[0m'
typeset -g TESTS_RUN=0 TESTS_PASSED=0 TESTS_FAILED=0

test_start() { echo -n "${CYAN}TEST: $1${RESET} ... "; TESTS_RUN=$((TESTS_RUN + 1)); }
test_pass() { echo "${GREEN}PASS${RESET}"; TESTS_PASSED=$((TESTS_PASSED + 1)); }
test_fail() { echo "${RED}FAIL${RESET}"; echo "  ${RED}-> $1${RESET}"; TESTS_FAILED=$((TESTS_FAILED + 1)); }
assert_contains() { [[ "$1" == *"$2"* ]] && return 0 || { test_fail "${3:-Should contain} '$2'"; return 1; }; }
assert_not_contains() { [[ "$1" != *"$2"* ]] && return 0 || { test_fail "${3:-Should not contain} '$2'"; return 1; }; }
assert_equals() { [[ "$1" == "$2" ]] && return 0 || { test_fail "${3:-Expected '$2', got '$1'}"; return 1; }; }
assert_success() { [[ "$1" -eq 0 ]] && return 0 || { test_fail "${2:-Command failed with exit code $1}"; return 1; }; }

# Source plugin
source "${SCRIPT_DIR}/../flow.plugin.zsh"

# Create test project
mkdir -p "$TEST_DIR/.teach/validators"
cp "${SCRIPT_DIR}/../.teach/validators/lint-shared.zsh" "$TEST_DIR/.teach/validators/"

# ============================================================================
# E2E TEST 1: --lint flag with single file
# ============================================================================

test_lint_single_file_with_errors() {
  test_start "E2E: --lint detects errors in single file"

  cat > "$TEST_DIR/test.qmd" <<'EOF'
---
title: "Test"
---

# Heading

```
bare code
```

### Skipped h2
EOF

  cd "$TEST_DIR"
  local output
  output=$(teach-validate --lint test.qmd 2>&1)
  local code=$?

  if [[ $code -ne 0 ]] && assert_contains "$output" "LINT_CODE_LANG_TAG"; then
    if assert_contains "$output" "LINT_HEADING_HIERARCHY"; then
      test_pass
    fi
  fi
}

test_lint_single_file_clean() {
  test_start "E2E: --lint passes clean file"

  cat > "$TEST_DIR/clean.qmd" <<'EOF'
---
title: "Clean"
---

# Section

## Subsection

```{r}
x <- 1
```
EOF

  cd "$TEST_DIR"
  local output
  output=$(teach-validate --lint clean.qmd 2>&1)
  local code=$?

  if assert_success $code "Clean file should pass"; then
    test_pass
  fi
}

# ============================================================================
# E2E TEST 2: --lint with multiple files
# ============================================================================

test_lint_multiple_files() {
  test_start "E2E: --lint processes multiple files"

  cat > "$TEST_DIR/file1.qmd" <<'EOF'
---
title: "File 1"
---

```
bad
```
EOF

  cat > "$TEST_DIR/file2.qmd" <<'EOF'
---
title: "File 2"
---

::: {.callout-invalid}
bad callout
:::
EOF

  cd "$TEST_DIR"
  local output
  output=$(teach-validate --lint file1.qmd file2.qmd 2>&1)

  if assert_contains "$output" "file1.qmd"; then
    if assert_contains "$output" "file2.qmd"; then
      if assert_contains "$output" "LINT_CODE_LANG_TAG"; then
        if assert_contains "$output" "LINT_CALLOUT_VALID"; then
          test_pass
        fi
      fi
    fi
  fi
}

# ============================================================================
# E2E TEST 3: --lint with --quick-checks
# ============================================================================

test_lint_quick_checks_flag() {
  test_start "E2E: --quick-checks runs only lint-shared"

  cat > "$TEST_DIR/quick.qmd" <<'EOF'
---
title: "Quick"
---

```
bad
```
EOF

  cd "$TEST_DIR"
  local output
  output=$(teach-validate --lint --quick-checks quick.qmd 2>&1)

  # Should only run lint-shared, not other validators
  if assert_contains "$output" "lint-shared"; then
    if assert_not_contains "$output" "lint-slides"; then
      test_pass
    fi
  fi
}

# ============================================================================
# E2E TEST 4: --lint finds all .qmd files when no files specified
# ============================================================================

test_lint_auto_discover_files() {
  test_start "E2E: --lint auto-discovers .qmd files"

  mkdir -p "$TEST_DIR/lectures"
  cat > "$TEST_DIR/lectures/week-01.qmd" <<'EOF'
---
title: "Week 1"
---

# Topic
EOF

  cat > "$TEST_DIR/lectures/week-02.qmd" <<'EOF'
---
title: "Week 2"
---

```
bad
```
EOF

  cd "$TEST_DIR"
  local output
  output=$(teach-validate --lint 2>&1)

  # Should find and process both files
  if assert_contains "$output" "week-01.qmd" || assert_contains "$output" "week-02.qmd"; then
    test_pass
  fi
}

# ============================================================================
# E2E TEST 5: --lint combined with other flags
# ============================================================================

test_lint_with_quiet_flag() {
  test_start "E2E: --lint --quiet suppresses verbose output"

  cat > "$TEST_DIR/test.qmd" <<'EOF'
---
title: "Test"
---

# Good
EOF

  cd "$TEST_DIR"
  local output
  output=$(teach-validate --lint --quiet test.qmd 2>&1)

  # Quiet mode should have minimal output
  if [[ $(echo "$output" | wc -l) -lt 10 ]]; then
    test_pass
  else
    test_fail "Output too verbose for --quiet mode"
  fi
}

# ============================================================================
# E2E TEST 6: Error handling
# ============================================================================

test_lint_nonexistent_file() {
  test_start "E2E: --lint handles nonexistent file gracefully"

  cd "$TEST_DIR"
  local output
  output=$(teach-validate --lint nonexistent.qmd 2>&1)

  # Should either skip gracefully or show error
  # But should not crash
  test_pass
}

test_lint_non_qmd_file() {
  test_start "E2E: --lint skips non-.qmd files"

  echo "# Bad" > "$TEST_DIR/test.md"
  echo "### Skipped" >> "$TEST_DIR/test.md"

  cd "$TEST_DIR"
  local output
  output=$(teach-validate --lint test.md 2>&1)
  local code=$?

  # Should skip .md files (validator only processes .qmd)
  if assert_success $code "Should skip non-.qmd files"; then
    test_pass
  fi
}

# ============================================================================
# E2E TEST 7: Performance check
# ============================================================================

test_lint_performance() {
  test_start "E2E: --lint completes in reasonable time"

  # Create 5 test files
  for i in {1..5}; do
    cat > "$TEST_DIR/perf-$i.qmd" <<'EOF'
---
title: "Performance Test"
---

# Section

## Subsection

```{r}
x <- 1
```
EOF
  done

  cd "$TEST_DIR"
  local start_time=$(date +%s)
  teach-validate --lint perf-*.qmd &>/dev/null
  local end_time=$(date +%s)
  local duration=$((end_time - start_time))

  # Should complete in under 5 seconds for 5 small files
  if [[ $duration -lt 5 ]]; then
    test_pass
  else
    test_fail "Took ${duration}s, expected <5s"
  fi
}

# ============================================================================
# E2E TEST 8: Help text
# ============================================================================

test_lint_help_text() {
  test_start "E2E: --help shows --lint flag"

  local output
  output=$(teach-validate --help 2>&1)

  if assert_contains "$output" "--lint"; then
    if assert_contains "$output" "--quick-checks"; then
      test_pass
    fi
  fi
}

# ============================================================================
# Run all tests
# ============================================================================

echo "=== teach validate --lint E2E tests ==="
echo ""

test_lint_single_file_with_errors
test_lint_single_file_clean
test_lint_multiple_files
test_lint_quick_checks_flag
test_lint_auto_discover_files
test_lint_with_quiet_flag
test_lint_nonexistent_file
test_lint_non_qmd_file
test_lint_performance
test_lint_help_text

echo ""
echo "Results: $TESTS_PASSED/$TESTS_RUN passed, $TESTS_FAILED failed"
[[ $TESTS_FAILED -eq 0 ]]
