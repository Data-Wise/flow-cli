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
| Test files | 213 |
| Test suites (run-all.sh) | 65 total — 64 passed, 1 skipped, 0 failed |
| Test functions | 12,000+ |
| Expected skips | 1 (`e2e-em-dispatcher` — needs configured IMAP account) |
| CI | runs the full suite on every PR (green on the Ubuntu runner) |

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

65 suites, ~12000 assertions. Expected: **64 passed, 0 failed, 0 timeout, 1 skipped**.
The 1 skip is `e2e-em-dispatcher` (needs a configured IMAP account; skips cleanly
otherwise). `run-all.sh` exits **0** when there are no failures or timeouts.

#### Skip semantics (exit code 77)

A suite that requires an external tool/service which is absent must **skip
cleanly** rather than fail. Exit **77** (the automake "skip" convention) tells
`run-all.sh` to count the suite as ⏭️ skipped, not ❌ failed:

```zsh
# Whole-suite guard — put after sourcing, before the tests:
command -v yq >/dev/null 2>&1 || { echo "SKIP: yq not installed"; exit 77; }
```

For a **mixed** suite (most cases are tool-independent), gate only the
tool-dependent cases instead of skipping the whole file — e.g. include the `tm`
dispatcher in dispatcher-enumeration checks only `if command -v ait`, so the
other assertions still run. This keeps full coverage on a dev machine that has
the tool while staying green on a hosted runner that doesn't.

Tools whose absence triggers a skip on CI: `atlas`, `ait` (aiterm),
`himalaya` (IMAP), `R`/`renv`, `quarto`, `claude`. Skips are printed in the
suite output and summarised in the `run-all.sh` results line, so a skip is
always visible (never a silently-missing pass).

> **Determinism:** suites that assert flow-cli's *standalone* behavior pin
> `FLOW_ATLAS_ENABLED=no` in setup so the result can't flip based on whether
> `atlas` happens to be installed. The suite is green locally **with or without**
> atlas, and on the runner (which has neither atlas nor the other tools above).

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

### GitHub Actions (`.github/workflows/test.yml`)

Tests run automatically on push and PR to `main`/`dev`, in **two parallel jobs**:

| Job | Runs | Purpose |
|-----|------|---------|
| **ZSH Plugin Tests** (`zsh-tests`) | smoke tests (`test-flow.zsh`, `test-install.sh`) + man-page version-sync guard | fast signal; the long-standing required check |
| **Full Test Suite** (`full-suite`) | the whole `./tests/run-all.sh` (~4 min) | comprehensive gate — runs every PR |

The runner has no `atlas`, `ait`, `himalaya`, `R`, or `quarto`, so service-
dependent suites **skip** there (see "Skip semantics" above); everything else
must pass. A git identity is provisioned in the job so deploy suites that
`git commit` work. The `full-suite` job captures the real exit code via
`PIPESTATUS` (so its colour reflects reality) and emits the full `run-all.sh`
output to the job summary.

> **Phasing:** `full-suite` starts as a **non-blocking** measurement job
> (`continue-on-error: true`) so it can never create a perpetually-red gate
> while the suite is being made deterministic. Once it has soaked green it is
> promoted to a **required** status check on `dev`, then `main`.

```yaml
  full-suite:
    name: Full Test Suite (non-blocking)
    runs-on: ubuntu-latest
    continue-on-error: true      # measurement phase; drop when promoting to required
    steps:
      - uses: actions/checkout@v6
      - name: Configure git identity
        run: |
          git config --global user.email "ci@flow-cli.test"
          git config --global user.name "flow-cli CI"
      # ... mock project structure ...
      - name: Run full suite (non-blocking)
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
**Test Count:** 213 test files, 12000+ assertions, 64/64 suites passing
