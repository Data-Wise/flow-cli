#!/usr/bin/env zsh
# Test lint-shared.zsh validator

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

source "${SCRIPT_DIR}/../.teach/validators/lint-shared.zsh"

# ---- LINT_CODE_LANG_TAG ----

test_bare_code_block_detected() {
  test_start "LINT_CODE_LANG_TAG: detects bare code blocks"
  cp "${SCRIPT_DIR}/fixtures/lint/bare-code-block.qmd" "$TEST_DIR/test.qmd"
  local output; output=$(_validate "$TEST_DIR/test.qmd" 2>&1); local code=$?
  if [[ $code -ne 0 ]] && assert_contains "$output" "LINT_CODE_LANG_TAG"; then test_pass; fi
}

test_all_tagged_passes() {
  test_start "LINT_CODE_LANG_TAG: all-tagged file passes"
  cat > "$TEST_DIR/good.qmd" <<'FIXTURE'
---
title: "Good"
---

```{r}
x <- 1
```

```text
plain text
```
FIXTURE
  local output; output=$(_validate "$TEST_DIR/good.qmd" 2>&1); local code=$?
  if assert_equals "$code" "0" "Should pass"; then test_pass; fi
}

# ---- LINT_DIV_BALANCE tests ----

test_unbalanced_divs_detected() {
  test_start "LINT_DIV_BALANCE: detects unclosed divs"
  cp "${SCRIPT_DIR}/fixtures/lint/unbalanced-divs.qmd" "$TEST_DIR/test.qmd"
  local output
  output=$(_validate "$TEST_DIR/test.qmd" 2>&1)
  if assert_contains "$output" "LINT_DIV_BALANCE"; then
    test_pass
  fi
}

test_balanced_divs_pass() {
  test_start "LINT_DIV_BALANCE: balanced divs pass"
  cat > "$TEST_DIR/balanced.qmd" <<'EOF'
---
title: "Test"
---

::: {.callout-note}
Content here.
:::

::: {.column-margin}
Margin content.
:::
EOF
  local output
  output=$(_validate "$TEST_DIR/balanced.qmd" 2>&1)
  if assert_not_contains "$output" "LINT_DIV_BALANCE" "No div errors expected"; then
    test_pass
  fi
}

# ---- LINT_CALLOUT_VALID tests ----

test_bad_callout_detected() {
  test_start "LINT_CALLOUT_VALID: detects invalid callout types"
  cp "${SCRIPT_DIR}/fixtures/lint/bad-callout.qmd" "$TEST_DIR/test.qmd"
  local output
  output=$(_validate "$TEST_DIR/test.qmd" 2>&1)
  if assert_contains "$output" "LINT_CALLOUT_VALID" && assert_contains "$output" "callout-info"; then
    test_pass
  fi
}

test_valid_callouts_pass() {
  test_start "LINT_CALLOUT_VALID: valid callouts pass"
  cat > "$TEST_DIR/good-callouts.qmd" <<'EOF'
---
title: "Test"
---

::: {.callout-note}
A note.
:::

::: {.callout-tip}
A tip.
:::

::: {.callout-warning}
A warning.
:::

::: {.callout-important}
Important.
:::

::: {.callout-caution}
Caution.
:::
EOF
  local output
  output=$(_validate "$TEST_DIR/good-callouts.qmd" 2>&1)
  if assert_not_contains "$output" "LINT_CALLOUT_VALID" "No callout errors expected"; then
    test_pass
  fi
}

# ---- LINT_HEADING_HIERARCHY tests ----

test_skipped_headings_detected() {
  test_start "LINT_HEADING_HIERARCHY: detects skipped heading levels"
  cp "${SCRIPT_DIR}/fixtures/lint/skipped-headings.qmd" "$TEST_DIR/test.qmd"
  local output
  output=$(_validate "$TEST_DIR/test.qmd" 2>&1)
  if assert_contains "$output" "LINT_HEADING_HIERARCHY"; then
    test_pass
  fi
}

test_proper_headings_pass() {
  test_start "LINT_HEADING_HIERARCHY: proper hierarchy passes"
  cat > "$TEST_DIR/good-headings.qmd" <<'EOF'
---
title: "Test"
---

# Section 1

## Subsection

### Sub-sub

## Another subsection

# Section 2
EOF
  local output
  output=$(_validate "$TEST_DIR/good-headings.qmd" 2>&1)
  if assert_not_contains "$output" "LINT_HEADING_HIERARCHY" "No heading errors expected"; then
    test_pass
  fi
}

test_non_qmd_skipped() {
  test_start "Non-.qmd files are skipped"
  cat > "$TEST_DIR/test.md" <<'EOF'
# Bad

### Skipped
EOF
  local output
  output=$(_validate "$TEST_DIR/test.md" 2>&1)
  local code=$?
  if assert_equals "$code" "0" "Should skip non-.qmd files"; then
    test_pass
  fi
}

# Run
echo "=== lint-shared.zsh unit tests ==="
test_bare_code_block_detected
test_all_tagged_passes
test_unbalanced_divs_detected
test_balanced_divs_pass
test_bad_callout_detected
test_valid_callouts_pass
test_skipped_headings_detected
test_proper_headings_pass
test_non_qmd_skipped
echo ""; echo "Results: $TESTS_PASSED/$TESTS_RUN passed, $TESTS_FAILED failed"
[[ $TESTS_FAILED -eq 0 ]]
