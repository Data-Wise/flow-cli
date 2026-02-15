# Dot Safety Test Guide

Comprehensive testing guide for dot safety features (v6.0.0).

## Test Suite Overview

| Suite                                | Type        | Tests | Duration | Purpose                     |
| ------------------------------------ | ----------- | ----- | -------- | --------------------------- |
| `test-dot-chezmoi-safety.zsh`        | Unit        | 21    | ~5s      | Function-level validation   |
| `e2e-dot-safety.zsh`                 | E2E         | 15+   | ~10s     | Workflow integration        |
| `interactive-dot-safety-dogfood.zsh` | Interactive | 15    | ~5min    | Human QA with real commands |

## Quick Start

```bash
# Run all tests
./tests/run-all.sh

# Run specific test suite
./tests/test-dot-chezmoi-safety.zsh      # Unit tests
./tests/e2e-dot-safety.zsh                # E2E tests
./tests/interactive-dot-safety-dogfood.zsh  # Interactive dogfooding
```

---

## Test Suite Details

### 1. Unit Tests (`test-dot-chezmoi-safety.zsh`)

**Purpose:** Validate individual functions in isolation

**Test Categories:**

- ✅ Utility Functions (3 tests)
  - Cross-platform file size detection
  - Human-readable size formatting
  - Timeout wrapper

- ✅ Git Detection (3 tests)
  - Single directory detection
  - Nested directory detection
  - Non-git directory handling

- ✅ Ignore Management (4 tests)
  - Add patterns
  - List patterns
  - Remove patterns
  - Prevent duplicates

- ✅ Preview Functionality (4 tests)
  - File count calculation
  - Total size calculation
  - Large file detection (>50KB)
  - Generated file warnings

- ✅ Negative Tests (3 tests)
  - Missing chezmoi installation
  - Nonexistent paths
  - Read-only directories

- ✅ Performance Tests (1 test)
  - Large directory handling (<2s)

- ✅ Integration Tests (2 tests)
  - Git detection → auto-ignore
  - Doctor check integration

- ✅ Cache Tests (1 test)
  - 5-minute TTL validation

**Run:**

```bash
./tests/test-dot-chezmoi-safety.zsh
```

**Expected Output:**

```
╔══════════════════════════════════════════════════════════════╗
║  TEST RESULTS                                                ║
╠══════════════════════════════════════════════════════════════╣
║  Tests run:    21                                            ║
║  Passed:       21                                            ║
║  Failed:       0                                             ║
║  Pass rate:    100%                                          ║
╚══════════════════════════════════════════════════════════════╝
```

---

### 2. E2E Tests (`e2e-dot-safety.zsh`)

**Purpose:** Validate complete workflows from start to finish

**Test Scenarios:**

#### Scenario 1: Add File with Git Detection

- Create directory with `.git` subdirectory
- Run git detection
- Verify auto-suggestion for ignore patterns

#### Scenario 2: Ignore Pattern Management

- Add patterns to `.chezmoiignore`
- List all patterns
- Prevent duplicate patterns
- Remove patterns

#### Scenario 3: Repository Size Analysis

- Create files with known sizes
- Calculate total size
- Detect large files (>50KB)
- Cache results

#### Scenario 4: Preview Before Add

- Calculate file count
- Detect large files
- Detect generated files (_.log, _.db)

#### Scenario 5: Flow Doctor Integration

- Verify doctor includes dot checks
- Check `.chezmoiignore` exists
- Validate health checks run

#### Scenario 6: Cache System

- Write to cache
- Read from cache
- Validate TTL (5 minutes)

**Run:**

```bash
./tests/e2e-dot-safety.zsh
```

**Expected Output:**

```
╔══════════════════════════════════════════════════════════════╗
║  E2E TEST RESULTS                                            ║
╠══════════════════════════════════════════════════════════════╣
║  Tests run:    15                                            ║
║  Passed:       15                                            ║
║  Failed:       0                                             ║
║  Pass rate:    100%                                          ║
╚══════════════════════════════════════════════════════════════╝
```

---

### 3. Interactive Dogfooding (`interactive-dot-safety-dogfood.zsh`)

**Purpose:** Human-guided QA with real commands in live environment

**Test Sections:**

#### Section 1: Help & Documentation (2 tests)

- Display `dot help`
- Display `dots ignore help`

#### Section 2: Ignore Pattern Management (3 tests)

- List ignore patterns
- Add pattern (dry-run)
- Verify ignore file location

#### Section 3: Repository Size Analysis (2 tests)

- Analyze repository size
- Check size cache

#### Section 4: Git Directory Detection (2 tests)

- Test git detection helper
- Verify cross-platform file size

#### Section 5: Flow Doctor Integration (2 tests)

- Run `flow doctor --dot`
- Verify check count

#### Section 6: Performance Validation (2 tests)

- Test cache hit performance (<10ms)
- Test file size helper speed (<10ms)

#### Section 7: Documentation Validation (2 tests)

- Check safety guide exists
- Verify all docs present

**Run:**

```bash
./tests/interactive-dot-safety-dogfood.zsh
```

**Interaction:**

```
TEST 1/15: Display dot help
Command: dot help

Expected:
Should show:
- Command categories (Chezmoi, Secrets, Safety)
- New commands: add, ignore, size
- Color-coded output
- Example usage

Running...

Actual Output:
[command output shown here]

Exit code: 0

Does this match expectations? (y)es/(n)o/(s)kip/(q)uit: y
✓ PASS
```

**Tips for Dogfooding:**

- Run in clean environment first
- Test with real dotfiles (backup first!)
- Verify all documentation references
- Check performance on large repositories
- Test cross-platform (macOS + Linux if available)

---

## Test Coverage Matrix

| Feature                  | Unit | E2E | Dogfood |
| ------------------------ | ---- | --- | ------- |
| Git directory detection  | ✅   | ✅  | ✅      |
| Ignore pattern CRUD      | ✅   | ✅  | ✅      |
| Repository size analysis | ✅   | ✅  | ✅      |
| Preview before add       | ✅   | ✅  | ⚠️      |
| Cross-platform helpers   | ✅   | ✅  | ✅      |
| Cache system             | ✅   | ✅  | ✅      |
| Flow doctor integration  | ✅   | ✅  | ✅      |
| Performance (<10ms)      | ✅   | ⚠️  | ✅      |
| Documentation            | ⚠️   | ⚠️  | ✅      |

Legend:

- ✅ Full coverage
- ⚠️ Partial coverage
- ❌ No coverage

---

## CI Integration

Add to `.github/workflows/test.yml`:

```yaml
- name: Run dot safety unit tests
  run: ./tests/test-dot-chezmoi-safety.zsh

- name: Run dot safety E2E tests
  run: ./tests/e2e-dot-safety.zsh
```

**Note:** Interactive tests are for manual QA only, not CI.

---

## Debugging Failed Tests

### Unit Test Failures

```bash
# Run with debug output
FLOW_DEBUG=1 ./tests/test-dot-chezmoi-safety.zsh

# Check specific function
source flow.plugin.zsh
_dot_check_git_in_path /path/to/test
```

### E2E Test Failures

```bash
# Inspect test environment
E2E_TEST_DIR="/tmp/e2e-dot-$$"
ls -la "$E2E_TEST_DIR/.local/share/chezmoi"

# Check cache
cat ~/.cache/flow/dot-size.cache
```

### Dogfooding Issues

- **Chezmoi not installed:** Install with `brew install chezmoi`
- **Permission errors:** Check `~/.local/share/chezmoi` permissions
- **Cache stale:** Clear with `rm ~/.cache/flow/dot-size.cache`
- **Git not initialized:** Run `chezmoi init` first

---

## Performance Benchmarks

Expected performance (from test suite):

| Operation                | Cached | Uncached | Target |
| ------------------------ | ------ | -------- | ------ |
| `dots size`               | 5-8ms  | 3-5s     | <10ms  |
| `_flow_get_file_size`    | N/A    | 7ms      | <10ms  |
| `_dot_check_git_in_path` | N/A    | <2s      | <2s    |
| `dots ignore list`        | 5ms    | 50ms     | <10ms  |
| `flow doctor --dot`      | 2-3s   | 5-10s    | <3s    |

**Note:** First run always slower due to cache population.

---

## Contributing New Tests

### Adding Unit Tests

Edit `tests/test-dot-chezmoi-safety.zsh`:

```bash
test_new_feature() {
  test_start "Test description"

  # Setup
  local result=$(_your_function "args")

  # Assert
  if assert_equals "$result" "expected"; then
    test_pass
  else
    test_fail "Reason"
  fi
}
```

### Adding E2E Tests

Edit `tests/e2e-dot-safety.zsh`:

```bash
test_new_scenario() {
  print_section "Scenario N: Description"

  test_start "Step description"
  # Run workflow steps
  # Verify end-to-end behavior
  test_pass
}
```

### Adding Dogfooding Tests

Edit `tests/interactive-dot-safety-dogfood.zsh`:

```bash
run_test N "Test name" \
  "actual command to run" \
  "Expected behavior description"
```

---

## Test Maintenance

### When to Update Tests

- ✅ After adding new features
- ✅ After bug fixes
- ✅ After changing function signatures
- ✅ After performance optimizations
- ✅ After documentation updates

### Test Hygiene

```bash
# Run all tests before committing
./tests/run-all.sh

# Update test counts in this README
# Update expected output examples
# Keep test descriptions current
```

---

## Related Documentation

- [CHEZMOI-SAFETY-GUIDE.md](../docs/guides/CHEZMOI-SAFETY-GUIDE.md) - User guide
- [REFCARD-DOT-SAFETY.md](../docs/reference/REFCARD-DOT-SAFETY.md) - Quick reference
- [DOT-SAFETY-ARCHITECTURE.md](../docs/architecture/DOT-SAFETY-ARCHITECTURE.md) - System design
- [API-DOT-SAFETY.md](../docs/reference/API-DOT-SAFETY.md) - API reference

---

**Last Updated:** 2026-01-31
**Test Suite Version:** v6.0.0
**Total Tests:** 51 (21 unit + 15 E2E + 15 interactive)
