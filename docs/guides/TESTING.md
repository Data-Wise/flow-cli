# Testing Guide - flow-cli

**Status:** ✅ Established (v5.0.0+)
**Last Updated:** 2026-01-11

---

## Overview

flow-cli uses **pure ZSH test suites** with comprehensive coverage across all core functionality. Tests are designed to be fast, isolated, and ADHD-friendly with clear output.

### Test Philosophy

> **"Tests should be as easy to read as they are to write"**

- ✅ **Standalone** - Each test file is self-contained and executable
- ✅ **Fast** - Sub-second execution for most suites
- ✅ **Isolated** - Mock environments prevent side effects
- ✅ **Clear** - Descriptive test names and colored output
- ✅ **Comprehensive** - 76+ tests covering core functionality

---

## Test Suite Architecture

### Current Test Files

```
tests/
├── test-pick-command.zsh         # Pick: 39 tests (556 lines)
├── test-cc-dispatcher.zsh        # CC: 37 tests (722 lines)
├── test-cc-unified-grammar.zsh   # CC unified grammar
├── test-dot-v5.1.1-unit.zsh      # DOT dispatcher
├── test-pick-smart-defaults.zsh  # Pick defaults
├── test-pick-wt.zsh              # Pick worktrees
├── interactive-dot-dogfooding.zsh # Interactive DOT tests
└── run-all.sh                     # Master test runner
```

### Test Statistics

| Suite | Tests | Lines | Coverage |
|-------|-------|-------|----------|
| test-pick-command.zsh | 39 | 556 | Pick core functionality |
| test-cc-dispatcher.zsh | 37 | 722 | CC dispatcher + grammar |
| test-dot-v5.1.1-unit.zsh | 112+ | ~800 | DOT dispatcher |
| **Total** | **76+** | **2000+** | **Core commands** |

---

## Test File Structure

### Standard Pattern

Every test file follows this structure:

```zsh
#!/usr/bin/env zsh
# test-<feature>.zsh - Description
# Run with: zsh tests/test-<feature>.zsh

# Don't exit on error - we want to run all tests
# set -e

# ============================================================================
# TEST FRAMEWORK
# ============================================================================

TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_test() {
    echo -n "${CYAN}Testing:${NC} $1 ... "
}

pass() {
    echo "${GREEN}✓ PASS${NC}"
    ((TESTS_PASSED++))
}

fail() {
    echo "${RED}✗ FAIL${NC} - $1"
    ((TESTS_FAILED++))
}

# ============================================================================
# SETUP
# ============================================================================

setup() {
    echo ""
    echo "${YELLOW}Setting up test environment...${NC}"

    # Source plugin or specific files
    source flow.plugin.zsh

    # Setup mock environment
    TEST_ROOT="/tmp/flow-test-$$"
    mkdir -p "$TEST_ROOT"
}

cleanup() {
    rm -rf "$TEST_ROOT" 2>/dev/null
}
trap cleanup EXIT

# ============================================================================
# TESTS
# ============================================================================

test_example() {
    log_test "example test case"

    # Test logic here
    if [[ condition ]]; then
        pass
    else
        fail "reason"
    fi
}

# ============================================================================
# RUN TESTS
# ============================================================================

main() {
    echo "╔════════════════════════════════════════╗"
    echo "║  Test Suite Name                       ║"
    echo "╚════════════════════════════════════════╝"

    setup

    echo "${YELLOW}Test Category${NC}"
    echo "────────────────────────────────────────"
    test_example
    echo ""

    # Summary
    echo "════════════════════════════════════════"
    echo "${CYAN}Summary${NC}"
    echo "────────────────────────────────────────"
    echo "  Passed: ${GREEN}$TESTS_PASSED${NC}"
    echo "  Failed: ${RED}$TESTS_FAILED${NC}"
    echo ""

    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo "${GREEN}✓ All tests passed!${NC}"
        exit 0
    else
        echo "${RED}✗ Some tests failed${NC}"
        exit 1
    fi
}

main "$@"
```

---

## Writing Tests

### 1. Test Naming Convention

**Pattern:** `test_<component>_<behavior>`

```zsh
# Good test names
test_pick_finds_exact_match()
test_cc_dispatch_mode_yolo()
test_frecency_score_returns_1000_for_recent()

# Bad test names
test_1()
test_stuff()
test_it_works()
```

### 2. Assertion Helpers

Create reusable assertion functions:

```zsh
assert_equals() {
    local actual="$1"
    local expected="$2"
    local message="${3:-Values should be equal}"

    if [[ "$actual" == "$expected" ]]; then
        return 0
    else
        fail "$message (expected: '$expected', got: '$actual')"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-Should contain substring}"

    if [[ "$haystack" == *"$needle"* ]]; then
        return 0
    else
        fail "$message (expected to contain: '$needle')"
        return 1
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-Should NOT contain substring}"

    if [[ "$haystack" != *"$needle"* ]]; then
        return 0
    else
        fail "$message (should not contain: '$needle')"
        return 1
    fi
}
```

### 3. Mock Environment Setup

**Isolated Test Environment:**

```zsh
# Create temporary test root
TEST_PROJECTS_ROOT="/tmp/flow-test-projects-$$"
export FLOW_PROJECTS_ROOT="$TEST_PROJECTS_ROOT"

# Create mock projects
mkdir -p "$TEST_PROJECTS_ROOT/dev-tools/flow-cli"
(cd "$TEST_PROJECTS_ROOT/dev-tools/flow-cli" && git init >/dev/null 2>&1)

mkdir -p "$TEST_PROJECTS_ROOT/r-packages/active/mediationverse"
(cd "$TEST_PROJECTS_ROOT/r-packages/active/mediationverse" && git init >/dev/null 2>&1)

# Cleanup on exit
cleanup() {
    rm -rf "$TEST_PROJECTS_ROOT" 2>/dev/null
}
trap cleanup EXIT
```

**Worktree Mocking:**

```zsh
# Setup test worktree directory
WORKTREE_DIR="/tmp/flow-test-worktrees-$$"
rm -rf "$WORKTREE_DIR" 2>/dev/null
export FLOW_WORKTREE_DIR="$WORKTREE_DIR"
mkdir -p "$WORKTREE_DIR"

# Re-source plugin to pick up new environment variable
source "$PLUGIN_FILE" 2>/dev/null

# Create mock worktree structure
mkdir -p "$WORKTREE_DIR/flow-cli/feature-cache"
(cd "$WORKTREE_DIR/flow-cli/feature-cache" && git init >/dev/null 2>&1)
```

### 4. ANSI Code Handling

Strip ANSI color codes for reliable text matching:

```zsh
test_help_text() {
    log_test "help displays correct text"

    result=$(pick help 2>&1)

    # Strip ANSI codes for matching
    result_clean=$(echo "$result" | sed 's/\x1b\[[0-9;]*m//g')

    if assert_contains "$result_clean" "PICK - Interactive Project Picker"; then
        pass
    fi
}
```

### 5. Function Mocking

**Mock functions for isolated testing:**

```zsh
test_mode_detection() {
    log_test "yolo detected as mode"

    # Mock the dispatch function to verify it's called
    local mode_called=0
    _cc_dispatch_with_mode() { mode_called=1; }

    cc yolo >/dev/null 2>&1 || true

    if [[ $mode_called -eq 1 ]]; then
        pass
    else
        fail "yolo not detected as mode"
    fi

    # Restore original function
    source "$project_root/lib/dispatchers/cc-dispatcher.zsh"
}
```

### 6. PATH Manipulation

**Safely modify PATH for testing:**

```zsh
test_missing_dependency() {
    log_test "handles missing fzf gracefully"

    # Save and restore PATH
    OLD_PATH="$PATH"
    export PATH="/tmp/empty-path-$$"

    result=$(pick 2>&1)

    export PATH="$OLD_PATH"

    if assert_contains "$result" "fzf required"; then
        pass
    fi
}
```

---

## Running Tests

### Individual Test Suite

```bash
# Run single test file (make it executable first)
chmod +x tests/test-pick-command.zsh
./tests/test-pick-command.zsh

# Or run with zsh directly
zsh tests/test-pick-command.zsh
```

### All Tests

```bash
# Run all test suites
./tests/run-all.sh

# Or manually
for test in tests/test-*.zsh; do
    echo "Running: $test"
    zsh "$test"
done
```

### Parallel Execution

```bash
# Run multiple suites in parallel
./tests/test-pick-command.zsh &
./tests/test-cc-dispatcher.zsh &
wait

# Check exit codes
echo "All tests completed: $?"
```

---

## Test Patterns & Examples

### Pattern 1: Function Existence Tests

```zsh
test_function_exists() {
    log_test "pick function is defined"

    if (( $+functions[pick] )); then
        pass
    else
        fail "pick function not defined"
    fi
}
```

### Pattern 2: Output Validation

```zsh
test_help_output() {
    log_test "help shows usage section"

    local output=$(pick help 2>&1)

    if assert_contains "$output" "USAGE"; then
        if assert_contains "$output" "ARGUMENTS"; then
            pass
        fi
    fi
}
```

### Pattern 3: Error Handling

```zsh
test_error_message() {
    log_test "shows error for nonexistent file"

    local output=$(cc file /nonexistent/file.txt 2>&1)

    if assert_contains "$output" "not found"; then
        pass
    fi
}
```

### Pattern 4: Algorithm Testing

```zsh
test_frecency_scoring() {
    log_test "frecency score decays over time"

    # Recent: 1000 points
    current=$(date +%s)
    score=$(_proj_frecency_score $current)
    assert_equals "$score" "1000" && pass

    # 12 hours ago: 500-999 points
    twelve_hours_ago=$(($(date +%s) - 43200))
    score=$(_proj_frecency_score $twelve_hours_ago)
    if [[ $score -gt 500 && $score -lt 1000 ]]; then
        pass
    fi

    # 30 days ago: < 100 points
    thirty_days_ago=$(($(date +%s) - 2592000))
    score=$(_proj_frecency_score $thirty_days_ago)
    if [[ $score -lt 100 ]]; then
        pass
    fi
}
```

### Pattern 5: Integration Tests

```zsh
test_end_to_end_workflow() {
    log_test "complete pick → cd workflow"

    # Create project
    mkdir -p "$TEST_ROOT/test-project"
    (cd "$TEST_ROOT/test-project" && git init >/dev/null 2>&1)

    # Find it
    result=$(_proj_find "test-project")
    assert_contains "$result" "test-project" || return

    # List it
    projects=$(_proj_list_all)
    assert_contains "$projects" "test-project" || return

    # Session status (should be empty)
    status=$(_proj_get_claude_session_status "$result")
    [[ -z "$status" ]] || { fail "Unexpected session status"; return; }

    pass
}
```

---

## Debugging Test Failures

### 1. Enable Verbose Output

```zsh
# Add debug output to tests
test_something() {
    log_test "feature works"

    result=$(some_command)

    # Debug: Show actual output
    echo "[DEBUG] Got: '$result'" >&2

    if assert_equals "$result" "expected"; then
        pass
    fi
}
```

### 2. Run Tests in Isolation

```zsh
# Run just the failing test
zsh -c 'source flow.plugin.zsh; test_failing_case'

# Or add to test file
if [[ "${1:-}" == "--debug" ]]; then
    set -x  # Enable trace
    test_failing_case
    exit $?
fi
```

### 3. Check Test Environment

```zsh
# Verify environment setup
setup() {
    echo "TEST_ROOT: $TEST_ROOT"
    echo "FLOW_PROJECTS_ROOT: $FLOW_PROJECTS_ROOT"
    echo "FLOW_WORKTREE_DIR: $FLOW_WORKTREE_DIR"

    # List created files
    ls -la "$TEST_ROOT"
}
```

### 4. Common Issues & Fixes

| Issue | Cause | Fix |
|-------|-------|-----|
| "Function not defined" | Plugin not sourced | Add `source flow.plugin.zsh` |
| "File not found" | Wrong path | Use `$SCRIPT_DIR` or absolute paths |
| ANSI code mismatch | Colors in output | Strip with `sed 's/\x1b\[[0-9;]*m//g'` |
| Worktree tests fail | Using real worktrees | Re-source plugin after setting `FLOW_WORKTREE_DIR` |
| PATH pollution | Not restoring PATH | Save/restore: `OLD_PATH="$PATH"` |
| Stale mocks | Previous test run | Add cleanup trap: `trap cleanup EXIT` |

---

## Coverage Goals

### Current Coverage (v5.0.0)

| Component | Test File | Coverage |
|-----------|-----------|----------|
| **pick command** | test-pick-command.zsh | ✅ 100% |
| **cc dispatcher** | test-cc-dispatcher.zsh | ✅ 100% |
| **dot dispatcher** | test-dot-v5.1.1-unit.zsh | ✅ 100% |
| **Frecency scoring** | test-pick-command.zsh | ✅ Algorithm validated |
| **Session indicators** | test-pick-command.zsh | ✅ 🟢/🟡 icons tested |
| **Worktree detection** | test-pick-wt.zsh | ✅ Full coverage |
| **Unified grammar** | test-cc-unified-grammar.zsh | ✅ Both orders tested |

### Future Coverage Targets

- [ ] `work` command full workflow
- [ ] `dash` command TUI interactions
- [ ] `finish` command git integration
- [ ] `hop` command tmux sessions
- [ ] All dispatcher help systems
- [ ] Integration with Atlas (when enabled)

---

## Continuous Integration

### GitHub Actions

Tests run automatically on PR:

```yaml
# .github/workflows/test.yml
name: ZSH Plugin Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install ZSH
        run: sudo apt-get install -y zsh
      - name: Run Tests
        run: ./tests/run-all.sh
```

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
# Run tests before allowing commit

echo "Running flow-cli tests..."
./tests/run-all.sh

if [ $? -ne 0 ]; then
    echo "❌ Tests failed. Commit aborted."
    exit 1
fi

echo "✅ Tests passed. Proceeding with commit."
```

---

## Best Practices

### ✅ Do

- **Write descriptive test names** - `test_pick_finds_exact_match` not `test1`
- **Use assertion helpers** - Reusable, consistent error messages
- **Mock external dependencies** - Isolate from system state
- **Clean up after tests** - Use `trap cleanup EXIT`
- **Test edge cases** - Empty input, missing files, negative numbers
- **Strip ANSI codes** - For reliable text matching
- **Group related tests** - Sections like "Helper Functions", "Edge Cases"

### ❌ Don't

- **Don't use `set -e`** - Want to run all tests, not stop at first failure
- **Don't depend on system state** - Create mocks, don't use real projects
- **Don't write flaky tests** - Avoid timing-dependent tests
- **Don't test implementation details** - Test behavior, not internals
- **Don't skip cleanup** - Always use `trap cleanup EXIT`
- **Don't hardcode paths** - Use `$TEST_ROOT`, `$SCRIPT_DIR`

---

## Test-Driven Development (TDD)

### Red-Green-Refactor Cycle

1. **Red** - Write failing test first

```zsh
test_new_feature() {
    log_test "new feature works"

    result=$(new_command)

    if assert_equals "$result" "expected"; then
        pass
    fi
}
# Run: ✗ FAIL - new_command not found
```

2. **Green** - Implement minimal code to pass

```zsh
# Add to commands/new.zsh
new_command() {
    echo "expected"
}
```

3. **Refactor** - Improve while keeping tests green

```zsh
new_command() {
    # Better implementation
    local result="expected"
    _validate_input "$@" || return 1
    echo "$result"
}
```

---

## Resources

### Test Files

- `tests/test-pick-command.zsh` - Best example of comprehensive testing
- `tests/test-cc-dispatcher.zsh` - Pattern for dispatcher testing
- `tests/test-dot-v5.1.1-unit.zsh` - Extensive unit tests (112+ tests)

### Documentation

- [CONVENTIONS.md](../CONVENTIONS.md) - Code standards
- [BRANCH-WORKFLOW.md](../contributing/BRANCH-WORKFLOW.md) - Git workflow

### Tools

- **ZSH Manual**: `man zshall`
- **Test Runner**: `./tests/run-all.sh`
- **Interactive Tests**: `./tests/interactive-*.zsh`

---

## Contributing Tests

When adding new functionality:

1. **Write tests first** (TDD approach)
2. **Follow existing patterns** (see test-pick-command.zsh)
3. **Use descriptive names** (`test_component_behavior`)
4. **Add to run-all.sh** if creating new test file
5. **Ensure 100% pass rate** before PR
6. **Document test coverage** in PR description

---

**Established:** v5.0.0 (2026-01-11)
**Test Count:** 76+ tests across 8 suites
**Status:** ✅ Production Ready - All tests passing
