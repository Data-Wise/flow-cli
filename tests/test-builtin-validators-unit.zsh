#!/usr/bin/env zsh
# tests/test-builtin-validators-unit.zsh
# Unit tests for built-in custom validators
# v4.6.0 - Wave 3: Custom Validators Framework
#
# TEST COVERAGE:
#   - Citation validator (extraction, checking)
#   - Link validator (internal/external)
#   - Formatting validator (headings, chunks, quotes)
#   - Line number accuracy
#   - Edge cases (no .bib, no links, etc.)
#
# USAGE:
#   ./tests/test-builtin-validators-unit.zsh

# Load validators
script_dir="${0:A:h}"
source "$script_dir/../lib/core.zsh"

# Test utilities
typeset -g TESTS_RUN=0
typeset -g TESTS_PASSED=0
typeset -g TESTS_FAILED=0

# ANSI colors
typeset -g TEST_GREEN='\033[0;32m'
typeset -g TEST_RED='\033[0;31m'
typeset -g TEST_YELLOW='\033[1;33m'
typeset -g TEST_BLUE='\033[0;34m'
typeset -g TEST_RESET='\033[0m'

# Test assertion helpers
assert_exit_code() {
    local expected_code="$1"
    local actual_code="$2"
    local message="${3:-Exit code assertion failed}"

    ((TESTS_RUN++))

    if [[ $expected_code -eq $actual_code ]]; then
        ((TESTS_PASSED++))
        echo -e "${TEST_GREEN}✓${TEST_RESET} $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "${TEST_RED}✗${TEST_RESET} $message"
        echo "  Expected: $expected_code, Got: $actual_code"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String contains assertion failed}"

    ((TESTS_RUN++))

    if echo "$haystack" | grep -qF "$needle"; then
        ((TESTS_PASSED++))
        echo -e "${TEST_GREEN}✓${TEST_RESET} $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "${TEST_RED}✗${TEST_RESET} $message"
        echo "  Looking for: $needle"
        return 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-String not contains assertion failed}"

    ((TESTS_RUN++))

    if ! echo "$haystack" | grep -qF "$needle"; then
        ((TESTS_PASSED++))
        echo -e "${TEST_GREEN}✓${TEST_RESET} $message"
        return 0
    else
        ((TESTS_FAILED++))
        echo -e "${TEST_RED}✗${TEST_RESET} $message"
        echo "  Should not contain: $needle"
        return 1
    fi
}

# ============================================================================
# TEST SETUP
# ============================================================================

setup_test_env() {
    export TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
}

teardown_test_env() {
    cd /tmp
    [[ -d "$TEST_DIR" ]] && rm -rf "$TEST_DIR"
}

# ============================================================================
# CITATION VALIDATOR TESTS
# ============================================================================

test_citation_validator_valid() {
    echo -e "\n${TEST_BLUE}Testing citation validator (valid)${TEST_RESET}"

    # Source validator
    source "$script_dir/../.teach/validators/check-citations.zsh"

    # Create .bib file
    cat > "$TEST_DIR/references.bib" <<'EOF'
@article{smith2020,
  author = {Smith, John},
  title = {Test Article},
  year = {2020}
}
EOF

    # Create .qmd file with citation
    cat > "$TEST_DIR/test.qmd" <<'EOF'
---
title: Test
---

This is a test [@smith2020].
EOF

    local result
    result=$(_validate "$TEST_DIR/test.qmd")
    local exit_code=$?

    assert_exit_code 0 $exit_code "Valid citation passes"
}

test_citation_validator_missing() {
    echo -e "\n${TEST_BLUE}Testing citation validator (missing)${TEST_RESET}"

    source "$script_dir/../.teach/validators/check-citations.zsh"

    # Create .bib file
    cat > "$TEST_DIR/references.bib" <<'EOF'
@article{smith2020,
  author = {Smith, John},
  title = {Test Article},
  year = {2020}
}
EOF

    # Create .qmd with missing citation
    cat > "$TEST_DIR/test.qmd" <<'EOF'
---
title: Test
---

This references [@jones2021] which doesn't exist.
EOF

    local result
    result=$(_validate "$TEST_DIR/test.qmd")
    local exit_code=$?

    assert_exit_code 1 $exit_code "Missing citation fails"
    assert_contains "$result" "Missing citation: @jones2021" "Error message for missing citation"
    assert_contains "$result" "Line 5" "Correct line number"
}

test_citation_validator_no_bib() {
    echo -e "\n${TEST_BLUE}Testing citation validator (no .bib file)${TEST_RESET}"

    source "$script_dir/../.teach/validators/check-citations.zsh"

    # Create .qmd without .bib
    cat > "$TEST_DIR/test.qmd" <<'EOF'
---
title: Test
---

This has a citation [@smith2020].
EOF

    local result
    result=$(_validate "$TEST_DIR/test.qmd")
    local exit_code=$?

    assert_exit_code 1 $exit_code "No .bib file fails when citations exist"
    assert_contains "$result" "No .bib files found" "Error about missing .bib"
}

test_citation_validator_multiple() {
    echo -e "\n${TEST_BLUE}Testing citation validator (multiple citations)${TEST_RESET}"

    source "$script_dir/../.teach/validators/check-citations.zsh"

    cat > "$TEST_DIR/references.bib" <<'EOF'
@article{smith2020,
  author = {Smith, John},
  year = {2020}
}
@article{jones2021,
  author = {Jones, Jane},
  year = {2021}
}
EOF

    cat > "$TEST_DIR/test.qmd" <<'EOF'
---
title: Test
---

Multiple citations [@smith2020; @jones2021].
EOF

    local result
    result=$(_validate "$TEST_DIR/test.qmd")
    local exit_code=$?

    assert_exit_code 0 $exit_code "Multiple valid citations pass"
}

# ============================================================================
# LINK VALIDATOR TESTS
# ============================================================================

test_link_validator_internal_valid() {
    echo -e "\n${TEST_BLUE}Testing link validator (valid internal)${TEST_RESET}"

    source "$script_dir/../.teach/validators/check-links.zsh"

    # Create target file
    echo "target" > "$TEST_DIR/target.md"

    # Create .qmd with link
    cat > "$TEST_DIR/test.qmd" <<'EOF'
---
title: Test
---

Link to [target](target.md).
EOF

    local result
    result=$(_validate "$TEST_DIR/test.qmd")
    local exit_code=$?

    assert_exit_code 0 $exit_code "Valid internal link passes"
}

test_link_validator_internal_broken() {
    echo -e "\n${TEST_BLUE}Testing link validator (broken internal)${TEST_RESET}"

    source "$script_dir/../.teach/validators/check-links.zsh"

    cat > "$TEST_DIR/test.qmd" <<'EOF'
---
title: Test
---

Broken link [missing](missing.md).
EOF

    local result
    result=$(_validate "$TEST_DIR/test.qmd")
    local exit_code=$?

    assert_exit_code 1 $exit_code "Broken internal link fails"
    assert_contains "$result" "Broken internal link" "Error about broken link"
    assert_contains "$result" "missing.md" "Shows broken file path"
    assert_contains "$result" "Line 5" "Correct line number"
}

test_link_validator_image_valid() {
    echo -e "\n${TEST_BLUE}Testing link validator (valid image)${TEST_RESET}"

    source "$script_dir/../.teach/validators/check-links.zsh"

    # Create image file
    touch "$TEST_DIR/image.png"

    cat > "$TEST_DIR/test.qmd" <<'EOF'
---
title: Test
---

Image: ![alt](image.png)
EOF

    local result
    result=$(_validate "$TEST_DIR/test.qmd")
    local exit_code=$?

    assert_exit_code 0 $exit_code "Valid image path passes"
}

test_link_validator_image_missing() {
    echo -e "\n${TEST_BLUE}Testing link validator (missing image)${TEST_RESET}"

    source "$script_dir/../.teach/validators/check-links.zsh"

    cat > "$TEST_DIR/test.qmd" <<'EOF'
---
title: Test
---

Missing image: ![alt](missing.png)
EOF

    local result
    result=$(_validate "$TEST_DIR/test.qmd")
    local exit_code=$?

    assert_exit_code 1 $exit_code "Missing image fails"
    assert_contains "$result" "Broken internal image" "Error about broken image"
}

test_link_validator_skip_external() {
    echo -e "\n${TEST_BLUE}Testing link validator (skip external)${TEST_RESET}"

    source "$script_dir/../.teach/validators/check-links.zsh"

    cat > "$TEST_DIR/test.qmd" <<'EOF'
---
title: Test
---

External link [example](https://example.com).
EOF

    # Set skip external flag
    export VALIDATOR_SKIP_EXTERNAL=1

    local result
    result=$(_validate "$TEST_DIR/test.qmd")
    local exit_code=$?

    unset VALIDATOR_SKIP_EXTERNAL

    assert_exit_code 0 $exit_code "External links skipped when flag set"
}

test_link_validator_anchor() {
    echo -e "\n${TEST_BLUE}Testing link validator (anchor links)${TEST_RESET}"

    source "$script_dir/../.teach/validators/check-links.zsh"

    cat > "$TEST_DIR/test.qmd" <<'EOF'
---
title: Test
---

# Section

Anchor link [link](#section).
EOF

    local result
    result=$(_validate "$TEST_DIR/test.qmd")
    local exit_code=$?

    assert_exit_code 0 $exit_code "Anchor links always valid"
}

# ============================================================================
# FORMATTING VALIDATOR TESTS
# ============================================================================

test_formatting_validator_heading_valid() {
    echo -e "\n${TEST_BLUE}Testing formatting validator (valid headings)${TEST_RESET}"

    source "$script_dir/../.teach/validators/check-formatting.zsh"

    cat > "$TEST_DIR/test.qmd" <<'EOF'
---
title: Test
---

# Heading 1

## Heading 2

### Heading 3

## Another H2
EOF

    local result
    result=$(_validate "$TEST_DIR/test.qmd")
    local exit_code=$?

    assert_exit_code 0 $exit_code "Valid heading hierarchy passes"
}

test_formatting_validator_heading_skip() {
    echo -e "\n${TEST_BLUE}Testing formatting validator (heading skip)${TEST_RESET}"

    source "$script_dir/../.teach/validators/check-formatting.zsh"

    cat > "$TEST_DIR/test.qmd" <<'EOF'
---
title: Test
---

# Heading 1

### Heading 3 (skipped H2!)
EOF

    local result
    result=$(_validate "$TEST_DIR/test.qmd")
    local exit_code=$?

    assert_exit_code 1 $exit_code "Skipped heading level fails"
    assert_contains "$result" "Heading hierarchy skip" "Error about heading skip"
    assert_contains "$result" "Line 7" "Correct line number"
}

test_formatting_validator_chunk_valid() {
    echo -e "\n${TEST_BLUE}Testing formatting validator (valid chunk options)${TEST_RESET}"

    source "$script_dir/../.teach/validators/check-formatting.zsh"

    cat > "$TEST_DIR/test.qmd" <<'EOF'
---
title: Test
---

```{r, echo=TRUE, eval=FALSE}
x <- 1
```
EOF

    local result
    result=$(_validate "$TEST_DIR/test.qmd")
    local exit_code=$?

    assert_exit_code 0 $exit_code "Valid chunk options pass"
}

test_formatting_validator_chunk_invalid() {
    echo -e "\n${TEST_BLUE}Testing formatting validator (invalid chunk option)${TEST_RESET}"

    source "$script_dir/../.teach/validators/check-formatting.zsh"

    cat > "$TEST_DIR/test.qmd" <<'EOF'
---
title: Test
---

```{r, invalidOption=TRUE}
x <- 1
```
EOF

    local result
    result=$(_validate "$TEST_DIR/test.qmd")
    local exit_code=$?

    assert_exit_code 1 $exit_code "Invalid chunk option fails"
    assert_contains "$result" "Unknown chunk option" "Error about invalid option"
}

test_formatting_validator_quotes() {
    echo -e "\n${TEST_BLUE}Testing formatting validator (quote consistency)${TEST_RESET}"

    source "$script_dir/../.teach/validators/check-formatting.zsh"

    cat > "$TEST_DIR/test.qmd" <<'EOF'
---
title: Test
---

"Double quotes here" and 'single quotes there'.
"More doubles" and 'more singles'.
"Again" and 'again'.
"Yet more" and 'yet more'.
"Final" and 'final'.
"Six" and 'six'.
EOF

    local result
    result=$(_validate "$TEST_DIR/test.qmd" 2>&1)
    local exit_code=$?

    # Quote warnings don't fail validation
    assert_exit_code 0 $exit_code "Quote warnings don't fail validation"
    assert_contains "$result" "Mixed quote styles" "Warning about mixed quotes"
}

# ============================================================================
# TEST RUNNER
# ============================================================================

run_all_tests() {
    echo -e "${TEST_YELLOW}═══════════════════════════════════════════════════${TEST_RESET}"
    echo -e "${TEST_YELLOW}  Built-in Validators Unit Tests${TEST_RESET}"
    echo -e "${TEST_YELLOW}═══════════════════════════════════════════════════${TEST_RESET}"

    setup_test_env

    # Citation validator tests
    echo -e "\n${TEST_BLUE}═══ Citation Validator Tests ═══${TEST_RESET}"
    test_citation_validator_valid
    test_citation_validator_missing
    test_citation_validator_no_bib
    test_citation_validator_multiple

    # Link validator tests
    echo -e "\n${TEST_BLUE}═══ Link Validator Tests ═══${TEST_RESET}"
    test_link_validator_internal_valid
    test_link_validator_internal_broken
    test_link_validator_image_valid
    test_link_validator_image_missing
    test_link_validator_skip_external
    test_link_validator_anchor

    # Formatting validator tests
    echo -e "\n${TEST_BLUE}═══ Formatting Validator Tests ═══${TEST_RESET}"
    test_formatting_validator_heading_valid
    test_formatting_validator_heading_skip
    test_formatting_validator_chunk_valid
    test_formatting_validator_chunk_invalid
    test_formatting_validator_quotes

    teardown_test_env

    # Summary
    echo -e "\n${TEST_YELLOW}═══════════════════════════════════════════════════${TEST_RESET}"
    echo -e "${TEST_YELLOW}  Test Summary${TEST_RESET}"
    echo -e "${TEST_YELLOW}═══════════════════════════════════════════════════${TEST_RESET}"
    echo -e "Total tests:  $TESTS_RUN"
    echo -e "${TEST_GREEN}Passed:       $TESTS_PASSED${TEST_RESET}"
    echo -e "${TEST_RED}Failed:       $TESTS_FAILED${TEST_RESET}"

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "\n${TEST_GREEN}✓ All tests passed!${TEST_RESET}"
        return 0
    else
        echo -e "\n${TEST_RED}✗ Some tests failed${TEST_RESET}"
        return 1
    fi
}

# Run tests
run_all_tests
