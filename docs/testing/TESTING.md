# Testing Guide

Comprehensive testing documentation for flow-cli's pure ZSH test suite.

---

## Overview

flow-cli uses a pure ZSH testing framework with **150+ tests** covering all 8 dispatchers, core commands, and integration scenarios.

### Test Philosophy

1. **Pure ZSH**: No external dependencies (no Jest, no Node.js)
2. **Fast Feedback**: Tests run in seconds
3. **CI Integration**: All tests run on every PR (Ubuntu + macOS)
4. **ADHD-Friendly**: Interactive "dog feeding" test for manual validation

---

## Test Statistics

### Current Status (v4.4.3)

| Category | Tests | Files | Status |
|----------|-------|-------|--------|
| **Dispatcher Tests** | 85+ | 8 | ✅ All in CI |
| **Core Command Tests** | 40+ | 4 | ✅ Passing |
| **Integration Tests** | 30+ | 3 | ✅ Passing |
| **Interactive Tests** | 2 | 2 | Manual |

### Dispatcher Test Coverage

| Dispatcher | Test File | Tests | CI Status |
|------------|-----------|-------|-----------|
| `cc` | test-cc-dispatcher.zsh | 24 | ✅ Required |
| `g` | test-g-feature.zsh | 14 | ✅ Required |
| `wt` | test-wt-dispatcher.zsh | 17 | ✅ Required |
| `r` | test-r-dispatcher.zsh | 16 | ✅ Required |
| `qu` | test-qu-dispatcher.zsh | 17 | ✅ Required |
| `mcp` | test-mcp-dispatcher.zsh | 21 | ✅ Required |
| `tm` | test-tm-dispatcher.zsh | 19 | ⚠️ Optional* |
| `obs` | test-obs-dispatcher.zsh | 12 | ✅ Required |

*TM tests require aiterm, which may not be installed on CI runners.

---

## Running Tests

### Quick Start

```bash
# Run a specific dispatcher test
zsh tests/test-cc-dispatcher.zsh

# Run all dispatcher tests
for f in tests/test-*-dispatcher.zsh; do zsh "$f"; done

# Interactive validation (recommended for first-time setup)
./tests/interactive-dog-feeding.zsh
```

### Individual Test Suites

```bash
# Dispatchers
zsh tests/test-cc-dispatcher.zsh      # Claude Code
zsh tests/test-g-feature.zsh          # Git workflows
zsh tests/test-wt-dispatcher.zsh      # Worktrees
zsh tests/test-r-dispatcher.zsh       # R packages
zsh tests/test-qu-dispatcher.zsh      # Quarto
zsh tests/test-mcp-dispatcher.zsh     # MCP servers
zsh tests/test-tm-dispatcher.zsh      # Terminal
zsh tests/test-obs-dispatcher.zsh     # Obsidian

# Core features
zsh tests/test-pick-smart-defaults.zsh
zsh tests/test-sync.zsh
zsh tests/test-status-fields.zsh

# Integration
zsh tests/test-cc-wt.zsh              # CC + Worktree integration
```

### Automated CLI Tests

```bash
bash tests/cli/automated-tests.sh
```

---

## Test Framework

### Structure

Each test file follows this pattern:

```zsh
#!/usr/bin/env zsh

# ============================================================================
# TEST FRAMEWORK
# ============================================================================

TESTS_PASSED=0
TESTS_FAILED=0

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
    # Source required files
    source "$project_root/lib/dispatchers/my-dispatcher.zsh"
}

# ============================================================================
# TESTS
# ============================================================================

test_help_shows_usage() {
    log_test "help shows usage"
    local output=$(my_command help 2>&1)
    if [[ "$output" == *"Usage:"* ]]; then
        pass
    else
        fail "Usage not found in help output"
    fi
}

# ============================================================================
# RUN
# ============================================================================

setup
test_help_shows_usage
# ... more tests

# Summary
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"
[[ $TESTS_FAILED -eq 0 ]] && exit 0 || exit 1
```

### Helper Functions

| Function | Purpose |
|----------|---------|
| `log_test "description"` | Print test name |
| `pass` | Mark test passed, increment counter |
| `fail "reason"` | Mark test failed with reason |
| `setup` | Initialize test environment |

---

## Writing Tests

### Test Template

```zsh
#!/usr/bin/env zsh
# Test script for [component]

# Framework (copy from existing test)
TESTS_PASSED=0
TESTS_FAILED=0
# ... colors, pass/fail functions

# Setup
setup() {
    local project_root="${0:A:h:h}"
    source "$project_root/lib/dispatchers/my-dispatcher.zsh"
}

# Tests
test_function_exists() {
    log_test "my_function is defined"
    if typeset -f my_function > /dev/null; then
        pass
    else
        fail "my_function not defined"
    fi
}

test_help_output() {
    log_test "help shows commands"
    local output=$(my_command help 2>&1)
    if [[ "$output" == *"Commands:"* ]]; then
        pass
    else
        fail "Commands section not found"
    fi
}

test_error_handling() {
    log_test "invalid input shows error"
    local output=$(my_command invalid 2>&1)
    if [[ "$output" == *"Unknown"* ]] || [[ "$output" == *"Error"* ]]; then
        pass
    else
        fail "Error message not shown"
    fi
}

# Run
setup
test_function_exists
test_help_output
test_error_handling

# Summary
echo ""
echo "════════════════════════════════════════"
echo "Summary"
echo "────────────────────────────────────────"
echo "  Passed: ${GREEN}$TESTS_PASSED${NC}"
echo "  Failed: ${RED}$TESTS_FAILED${NC}"

[[ $TESTS_FAILED -eq 0 ]] && echo "${GREEN}✓ All tests passed!${NC}" || echo "${RED}✗ Some tests failed${NC}"
exit $TESTS_FAILED
```

### Test Categories

1. **Function Existence** - Verify functions are defined
2. **Help Output** - Verify help shows expected sections
3. **Command Behavior** - Verify commands produce expected output
4. **Error Handling** - Verify invalid input is handled gracefully
5. **Integration** - Verify components work together

---

## CI/CD Integration

### GitHub Actions Workflow

Tests run automatically on:
- Every push to `main` or `dev` branches
- Every pull request

### Platforms

| Platform | Job Name | Tests |
|----------|----------|-------|
| Ubuntu | ZSH Plugin Tests | All 8 dispatchers + core |
| macOS | macOS Tests | All 8 dispatchers + core |

### CI Configuration

```yaml
# .github/workflows/test.yml
name: CI Tests

on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main, dev]

jobs:
  zsh-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - name: Install zsh
        run: sudo apt-get update && sudo apt-get install -y zsh
      - name: Run dispatcher tests
        run: zsh ./tests/test-cc-dispatcher.zsh
      # ... more test steps
```

### Optional Tests

Some tests use `continue-on-error: true`:

| Test | Reason |
|------|--------|
| TM dispatcher | Requires aiterm (external tool) |
| AI features | Requires API keys |
| Sync tests | Requires specific environment |

---

## Interactive Testing

### Dog Feeding Test 🐕

The fastest way to validate your installation:

```bash
./tests/interactive-dog-feeding.zsh
```

**Features:**
- Shows expected output for each command
- Runs command and displays actual output
- Asks you to confirm if they match
- Feeds a virtual dog for each success
- Earn 1-5 stars based on performance

**Perfect for:**
- First-time installation validation
- After major refactoring
- Teaching new users
- Making testing fun!

### Manual Validation

```bash
# Quick smoke test
cc help        # Should show Claude Code help
g help         # Should show git workflow help
mcp            # Should list MCP servers
r help         # Should show R package help
```

---

## Troubleshooting

### "Cannot find project root"

Run tests from the project directory:

```bash
cd ~/projects/dev-tools/flow-cli
zsh tests/test-cc-dispatcher.zsh
```

### "Function not defined"

Ensure the dispatcher is sourced:

```bash
source lib/dispatchers/cc-dispatcher.zsh
```

### Tests pass locally but fail in CI

Check if the test requires:
- External tools (aiterm, obs, etc.)
- Specific environment variables
- Mock project structure

CI creates mock directories in `~/projects/` - your test may need adjustment.

---

## Adding Tests to CI

When adding a new dispatcher:

1. Create test file: `tests/test-<name>-dispatcher.zsh`
2. Add to Ubuntu job in `.github/workflows/test.yml`:
   ```yaml
   - name: Run <name> dispatcher tests
     run: |
       cd ~/projects/dev-tools/flow-cli
       zsh ./tests/test-<name>-dispatcher.zsh
   ```
3. Add to macOS job (combined or separate step)
4. Use `continue-on-error: true` if test requires external tools

---

## Test File Inventory

### Dispatcher Tests (in CI)

| File | Dispatcher | Tests |
|------|------------|-------|
| `test-cc-dispatcher.zsh` | `cc` | 24 |
| `test-g-feature.zsh` | `g feature` | 14 |
| `test-wt-dispatcher.zsh` | `wt` | 17 |
| `test-r-dispatcher.zsh` | `r` | 16 |
| `test-qu-dispatcher.zsh` | `qu` | 17 |
| `test-mcp-dispatcher.zsh` | `mcp` | 21 |
| `test-tm-dispatcher.zsh` | `tm` | 19 |
| `test-obs-dispatcher.zsh` | `obs` | 12 |

### Core Tests

| File | Feature | Tests |
|------|---------|-------|
| `test-pick-smart-defaults.zsh` | Project picker | 18 |
| `test-sync.zsh` | Sync command | 40 |
| `test-status-fields.zsh` | .STATUS parsing | 12 |

### Integration Tests

| File | Integration | Tests |
|------|-------------|-------|
| `test-cc-wt.zsh` | CC + Worktree | 20 |
| `test-g-feature-prune.zsh` | Git cleanup | 18 |

### Interactive Tests (Manual)

| File | Purpose |
|------|---------|
| `interactive-dog-feeding.zsh` | Gamified validation |
| `interactive-test.zsh` | Manual command testing |

---

## Performance

### Target Metrics

| Metric | Target | Actual |
|--------|--------|--------|
| Single test file | < 5s | ~1-2s |
| Full CI suite | < 60s | ~30s |
| Plugin source time | < 150ms | ~50ms |

### CI Performance Summary

The workflow includes performance tracking:

```
## 📊 ZSH Tests Performance

| Metric | Value |
|--------|-------|
| Total Duration | 28s |
| Platform | Ubuntu |

### Expected Baselines
- Plugin source: <150ms
- Help commands: <200ms
- Total CI job: <120s
```

---

## Related Documentation

- [COMMAND-QUICK-REFERENCE.md](../reference/COMMAND-QUICK-REFERENCE.md) - Command reference
- [DISPATCHER-REFERENCE.md](../reference/DISPATCHER-REFERENCE.md) - Dispatcher documentation
- [CONTRIBUTING.md](../contributing/CONTRIBUTING.md) - Contribution guidelines

---

**Last Updated:** 2025-12-30
**Test Count:** 150+ tests
**Version:** v4.4.3
