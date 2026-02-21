# Testing Guide - flow-cli

**Status:** ✅ Established (v7.4.0+)
**Last Updated:** 2026-02-16

---

## Overview

flow-cli uses a **shared test framework** (`tests/test-framework.zsh`) with comprehensive coverage across all core functionality. Tests are fast, isolated, and ADHD-friendly with clear colored output.

### Test Philosophy

> **"Tests should be as easy to read as they are to write"**

- ✅ **Shared framework** - One `source`, 14 assertion helpers, mock registry
- ✅ **Fast** - Sub-second execution for most suites
- ✅ **Isolated** - Mock environments and subshell isolation prevent side effects
- ✅ **Clear** - Descriptive test names and colored pass/fail output
- ✅ **Self-policing** - Dogfood scanner catches anti-patterns automatically

### Test Statistics

| Metric | Count |
|--------|-------|
| Test files | 134 |
| Test suites (run-all.sh) | 45/45 passing |
| Test functions | 8,000+ |
| Expected timeouts | 1 (IMAP connectivity) |

---

## Shared Test Framework

All test files source `tests/test-framework.zsh` instead of defining their own inline framework.

### Setup

```zsh
#!/usr/bin/env zsh
# tests/test-<feature>.zsh

PROJECT_ROOT="${0:A:h:h}"
source "${0:A:h}/test-framework.zsh"

test_suite "Feature Name Tests"
```

### Test Case Pattern

```zsh
test_example() {
    test_case "description of what's being tested"

    local result=$(some_command 2>&1)
    assert_contains "$result" "expected output"

    test_pass
}
```

Key mechanics:
- `test_case` registers the test and increments the counter
- `test_pass` marks success (auto-called by `test_case_end` if not explicit)
- `test_fail` marks failure and **clears** `CURRENT_TEST` — subsequent `test_pass` is a no-op (prevents double-counting)

### Assertion Helpers (14)

| Helper | Purpose |
|--------|---------|
| `assert_equals` | Exact string match |
| `assert_not_equals` | Strings differ |
| `assert_contains` | Substring present |
| `assert_not_contains` | Substring absent |
| `assert_empty` | Value is empty |
| `assert_not_empty` | Value is non-empty |
| `assert_file_exists` | File exists |
| `assert_file_not_exists` | File doesn't exist |
| `assert_dir_exists` | Directory exists |
| `assert_function_exists` | ZSH function defined |
| `assert_command_exists` | Command on PATH |
| `assert_exit_code` | Exit code matches |
| `assert_matches_pattern` | Regex match |
| `assert_alias_exists` | ZSH alias defined |

Convenience aliases: `assert_output_contains`, `assert_output_excludes`

### Mock Registry

Track function calls and arguments:

```zsh
# Create a mock (replaces function, tracks calls)
create_mock "_flow_open_editor" 'echo "$1" > /tmp/editor-capture'

# Run code that calls the mocked function
some_function_that_opens_editor

# Assert mock was called
assert_mock_called "_flow_open_editor" 1
assert_mock_args "_flow_open_editor" "expected args"

# Clean up (restores originals)
reset_mocks
```

`create_mock` saves the original function body and restores it on `reset_mocks`.

### Subshell Isolation

Run tests in isolated subshells to prevent global state leakage:

```zsh
test_isolated_feature() {
    # Sources flow.plugin.zsh in subshell, runs function, captures output
    run_isolated "my_test_function"
}
```

`run_isolated` sets `FLOW_QUIET=1`, `FLOW_ATLAS_ENABLED=no`, and sources the plugin in a subshell.

### Utility Helpers

| Helper | Purpose |
|--------|---------|
| `capture_output "cmd"` | Run command, capture stdout+stderr |
| `with_temp_dir "callback"` | Run callback in temp dir, auto-cleanup |
| `with_env "VAR" "value" "callback"` | Run with env var, auto-restore (scalar only) |

**Note:** `with_env` only works with scalar variables. ZSH arrays and associative arrays (`$path`, `$fpath`) need manual save/restore.

---

## Writing Tests

### 1. Test File Structure

```zsh
#!/usr/bin/env zsh
# tests/test-<feature>.zsh - Description

PROJECT_ROOT="${0:A:h:h}"
source "${0:A:h}/test-framework.zsh"

# ── Setup ──────────────────────────────────────────────
TEST_ROOT=$(mktemp -d)
cleanup() { rm -rf "$TEST_ROOT" 2>/dev/null; }
trap cleanup EXIT

# ── Tests ──────────────────────────────────────────────
test_suite "Feature Name"

test_feature_does_thing() {
    test_case "feature does the expected thing"
    # test logic
    test_pass
}

# ── Run ────────────────────────────────────────────────
test_feature_does_thing

test_suite_end
print_summary
exit $(( TESTS_FAILED > 0 ? 1 : 0 ))
```

### 2. Test Naming Convention

**Pattern:** `test_<component>_<behavior>`

```zsh
# Good
test_pick_finds_exact_match()
test_cc_dispatch_mode_yolo()
test_work_editor_flag_cc()

# Bad
test_1()
test_stuff()
```

### 3. Mock Environment Setup

```zsh
# Create temporary project structure
TEST_ROOT=$(mktemp -d)
mkdir -p "$TEST_ROOT/dev-tools/mock-proj"
printf "## Status: active\n## Progress: 50\n" > "$TEST_ROOT/dev-tools/mock-proj/.STATUS"

# Mock function with tracking
create_mock "_flow_open_editor" 'echo "$1" > "'$CAPTURE_FILE'"'

# Override env
export FLOW_PROJECTS_ROOT="$TEST_ROOT"
```

### 4. ANSI Code Handling

Strip ANSI color codes for reliable text matching:

```zsh
result=$(pick help 2>&1)
result_clean=$(echo "$result" | sed 's/\x1b\[[0-9;]*m//g')
assert_contains "$result_clean" "PICK - Interactive Project Picker"
```

### 5. Testing Source Code vs Mocked Functions

When testing that source code contains specific patterns, **read the file directly** instead of using `functions` (which shows the mock body):

```zsh
test_source_has_pattern() {
    test_case "work.zsh handles cc/claude/ccy cases"
    local matches=$(grep -c 'cc\|claude\|ccy' "$PROJECT_ROOT/commands/work.zsh" 2>/dev/null)
    if (( matches > 0 )); then test_pass; else test_fail "pattern not found"; fi
}
```

For behavioral tests on mocked functions, restore the real function first:

```zsh
test_real_behavior() {
    test_case "real function behavior"
    reset_mocks
    source "$PROJECT_ROOT/commands/work.zsh" 2>/dev/null
    local output=$(_flow_open_editor "" "/tmp" 2>&1)
    assert_contains "$output" "expected"
    create_mock "_flow_open_editor" "return 0"  # Re-apply mock for remaining tests
}
```

---

## Dogfood Scanner

`tests/dogfood-test-quality.zsh` is a meta-test that scans all test files for anti-patterns:

| Category | What It Catches |
|----------|----------------|
| Permissive exit codes | `exit 0` at end regardless of failures |
| Existence-only tests | Tests that only check function exists, never call it |
| Unused output captures | `local output=$(cmd)` where `$output` is never checked |
| Inline frameworks | Test files defining their own `pass()`/`fail()` instead of sourcing shared framework |

Run: `zsh tests/dogfood-test-quality.zsh`

The scanner enforces migration to the shared framework — any new test file using inline assertions will be flagged.

---

## Running Tests

### Individual Test Suite

```bash
zsh tests/test-pick-command.zsh
zsh tests/test-work.zsh
```

### All Tests

```bash
./tests/run-all.sh
```

45 suites, ~8000 assertions. Expected: 45/45 pass, 1 timeout (IMAP connectivity test).

### Dogfood Quality Check

```bash
zsh tests/dogfood-test-quality.zsh
```

---

## Debugging Test Failures

### Enable Verbose Output

```zsh
test_something() {
    test_case "feature works"
    result=$(some_command)
    echo "[DEBUG] Got: '$result'" >&2
    assert_equals "$result" "expected"
    test_pass
}
```

### Common Issues

| Issue | Cause | Fix |
|-------|-------|-----|
| "Function not defined" | Plugin not sourced | Add `source flow.plugin.zsh` |
| Mock body in `functions` output | Using `functions` on mocked fn | Read source file directly with `grep` |
| ANSI code mismatch | Colors in output | Strip with `sed 's/\x1b\[[0-9;]*m//g'` |
| Dogfood: unused capture | `local output=$(cmd)` not checked | Use `cmd &>/dev/null` if output not needed |
| `with_env` breaks PATH | ZSH `$path` is array | Don't use `with_env` for arrays; save/restore manually |
| Stale mocks | Previous test | Call `reset_mocks` or use `trap cleanup EXIT` |

---

## Continuous Integration

### GitHub Actions (`test.yml`)

Tests run automatically on push and PR:

```yaml
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

---

## Best Practices

### Do

- **Source the shared framework** - `source "${0:A:h}/test-framework.zsh"`
- **Use descriptive names** - `test_pick_finds_exact_match` not `test1`
- **Use assertion helpers** - Consistent error messages
- **Mock external deps** - Isolate from system state
- **Clean up** - Use `trap cleanup EXIT`
- **Test edge cases** - Empty input, missing files, negative numbers
- **Strip ANSI codes** - For reliable text matching

### Don't

- **Don't use inline frameworks** - The dogfood scanner will catch you
- **Don't use `set -e`** - Want to run all tests, not stop at first failure
- **Don't depend on system state** - Create mocks, don't use real projects
- **Don't use `local path=`** - Shadows ZSH's `$path` array (see regression test)
- **Don't use `functions` on mocked fns** - Read source file instead

---

## Contributing Tests

When adding new functionality:

1. **Source `test-framework.zsh`** (not inline pass/fail)
2. **Use `test_case`/`test_pass`/`test_fail`** pattern
3. **Use `create_mock`** for function mocking
4. **Add to `run-all.sh`** if creating new test file
5. **Run dogfood scanner** before PR
6. **Ensure 100% pass rate** before PR

---

**Established:** v5.0.0 (2026-01-11)
**Overhauled:** v7.4.0 (2026-02-16) — shared framework, mock registry, dogfood scanner
**Test Count:** 195 test files, 12000+ assertions, 47/47 suites passing
