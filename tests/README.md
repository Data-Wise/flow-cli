# flow-cli Test Suite

Comprehensive test suite for flow-cli, designed for ADHD-friendly development.

## Quick Start

```bash
# Run all automated tests
zsh tests/automated-test.zsh

# Run specific test file
zsh tests/test-dash.zsh
zsh tests/test-work.zsh
zsh tests/test-doctor.zsh

# Run interactive dogfooding tests
./tests/interactive-dog-feeding.zsh
```

## Test Categories

### Core Commands

| File                           | Tests | Coverage                                |
| ------------------------------ | ----- | --------------------------------------- |
| `test-dash.zsh`                | 27    | Dashboard display, modes, categories    |
| `test-work.zsh`                | 28    | work, finish, hop, session management   |
| `test-doctor.zsh`              | 26    | Health check, dependency validation     |
| `test-capture.zsh`             | 30    | catch, crumb, trail, win, yay           |
| `test-adhd.zsh`                | 30    | js, next, stuck, focus, brk             |
| `test-flow.zsh`                | 38    | flow dispatcher, help, version, routing |
| `test-timer.zsh`               | 30    | timer, pomodoro, focus, break           |
| `test-pick-wt.zsh`             | 22    | pick wt, worktree listing, sessions     |
| `test-pick-smart-defaults.zsh` | -     | Project picker smart defaults           |
| `test-pick-format.zsh`         | -     | Pick output formatting                  |

### Dispatchers

| File                       | Tests | Coverage              |
| -------------------------- | ----- | --------------------- |
| `test-cc-dispatcher.zsh`   | -     | Claude Code launcher  |
| `test-g-feature.zsh`       | -     | Git feature workflow  |
| `test-g-feature-prune.zsh` | -     | Branch cleanup        |
| `test-mcp-dispatcher.zsh`  | -     | MCP server management |
| `test-obs-dispatcher.zsh`  | -     | Obsidian integration  |
| `test-qu-dispatcher.zsh`   | -     | Quarto publishing     |
| `test-r-dispatcher.zsh`    | -     | R package development |
| `test-tm-dispatcher.zsh`   | -     | Terminal manager      |
| `test-wt-dispatcher.zsh`   | -     | Worktree management   |
| `test-dot-dispatcher.zsh`  | 50+   | Dotfile management    |

### Dot Dispatcher Test Suite (NEW)

| File                          | Tests | Coverage                                      |
| ----------------------------- | ----- | --------------------------------------------- |
| `test-dot-dispatcher.zsh`     | 52    | Core functionality, helpers, formatting       |
| `test-integration.zsh`        | 35    | Chezmoi, Bitwarden, dashboard, doctor         |
| `test-phase3-secrets.zsh`     | 15    | Secret management (Bitwarden)                 |
| `test-phase4.sh`              | 10    | Dashboard integration                         |
| `run-all-tests.zsh`           | -     | Test orchestrator (runs all dot tests)        |

**Quick Start:**
```bash
# Run all dot dispatcher tests
./tests/run-all-tests.zsh

# Or run individual suites
./tests/test-dot-dispatcher.zsh   # Core functionality
./tests/test-integration.zsh      # Integration tests
```

### Integration Tests

| File                                     | Purpose                |
| ---------------------------------------- | ---------------------- |
| `test-atlas-e2e.zsh`                     | Full Atlas integration |
| `test-atlas-integration.zsh`             | Atlas bridge functions |
| `test-cc-wt-e2e.zsh`                     | Claude + worktree E2E  |
| `integration/atlas-flow-integration.zsh` | Complete workflow      |

### Interactive Tests

| File                               | Purpose                          |
| ---------------------------------- | -------------------------------- |
| `interactive-dog-feeding.zsh`      | Gamified testing (ADHD-friendly) |
| `interactive-test.zsh`             | Manual verification              |
| `interactive-cc-wt-dogfooding.zsh` | CC worktree dogfooding           |

## Running Tests

### Run All Automated Tests

```bash
cd ~/projects/dev-tools/flow-cli
zsh tests/automated-test.zsh
```

### Run Individual Test File

```bash
# From project root
zsh tests/test-dash.zsh

# Or make executable and run directly
chmod +x tests/test-dash.zsh
./tests/test-dash.zsh
```

### Run Tests in Verbose Mode

Most test files support verbose output via environment variable:

```bash
FLOW_DEBUG=1 zsh tests/test-work.zsh
```

### Run Dispatcher Tests

```bash
# All dispatchers
for f in tests/test-*-dispatcher.zsh; do zsh "$f"; done

# Specific dispatcher
zsh tests/test-cc-dispatcher.zsh
```

### Run Interactive Tests

```bash
# Gamified dogfooding (recommended for ADHD)
./tests/interactive-dog-feeding.zsh

# Manual verification
./tests/interactive-test.zsh
```

## Test Framework

All test files use a consistent framework:

```zsh
TESTS_PASSED=0
TESTS_FAILED=0

log_test() { echo -n "Testing: $1 ... " }
pass()     { echo "✓ PASS"; ((TESTS_PASSED++)) }
fail()     { echo "✗ FAIL - $1"; ((TESTS_FAILED++)) }

# Tests...

# Summary
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
[[ $TESTS_FAILED -gt 0 ]] && exit 1
```

## Writing New Tests

1. **Create test file** in `tests/test-<feature>.zsh`
2. **Use the framework** (copy from existing test)
3. **Test categories:**
   - Command existence
   - Help output
   - Basic functionality
   - Edge cases
   - Error handling

### Example Test

```zsh
test_command_exists() {
    log_test "mycommand exists"
    if type mycommand &>/dev/null; then
        pass
    else
        fail "mycommand not found"
    fi
}

test_help_runs() {
    log_test "mycommand --help runs"
    local output=$(mycommand --help 2>&1)
    if [[ $? -eq 0 ]]; then
        pass
    else
        fail "Exit code: $?"
    fi
}
```

## CI Integration

Tests are designed to work in CI:

```yaml
# .github/workflows/test.yml
- name: Run tests
  run: zsh tests/automated-test.zsh
```

Exit codes:

- `0` - All tests passed
- `1` - One or more tests failed

## Test Coverage Summary

| Component         | Test Files | Status |
| ----------------- | ---------- | ------ |
| Core commands     | 7          | ✅     |
| Dispatchers       | 9          | ✅     |
| Pick command      | 3          | ✅     |
| Atlas integration | 2          | ✅     |
| Interactive       | 3          | ✅     |
| Automated suite   | 1          | ✅     |

**Total: ~33 test files covering all major functionality**

## Tips

- Run `automated-test.zsh` first for quick sanity check
- Use `interactive-dog-feeding.zsh` for thorough manual testing
- Failed tests show what went wrong in the output
- Check `$TESTS_FAILED` for CI integration

---

_Generated: 2025-12-30 | flow-cli v4.6.0_
