# WT Enhancement Test Suite

**Feature:** WT Workflow Enhancement (Phases 1-2)
**Spec:** `docs/specs/SPEC-wt-workflow-enhancement-2026-01-17.md`
**Branch:** `feature/wt-enhancement`

---

## Test Files

This directory contains three comprehensive test suites for the WT workflow enhancement:

### 1. Unit Tests

**File:** `test-wt-enhancement-unit.zsh`
**Type:** Automated, non-interactive
**Duration:** ~30 seconds
**Purpose:** Test individual functions and components

**What it tests:**

- `_wt_overview()` function existence and output
- `wt()` dispatcher behavior
- Status icon detection
- Session indicator detection
- `_pick_wt_delete()` and `_pick_wt_refresh()` functions
- Help text integration

**Usage:**

```bash
./tests/test-wt-enhancement-unit.zsh
```

**Expected output:**

- 20+ tests
- All passing (100%)
- Summary with pass/fail counts

---

### 2. E2E Integration Tests

**File:** `test-wt-enhancement-e2e.zsh`
**Type:** Automated, creates test environment
**Duration:** ~1 minute
**Purpose:** Test complete workflows with real git operations

**What it tests:**

- Overview display in real git repo
- Filter functionality
- Help integration
- Refresh function behavior
- Status detection (active, merged, main)
- Passthrough commands

**Usage:**

```bash
./tests/test-wt-enhancement-e2e.zsh
```

**Features:**

- Creates temporary test repository
- Sets up 3 worktrees with different states
- Tests merged branch detection
- Cleans up after itself

**Expected output:**

- 25+ tests
- Creates temp directory (auto-cleaned)
- All tests pass or skip with reason

---

### 3. Interactive Dogfooding Tests

**File:** `interactive-wt-dogfooding.zsh`
**Type:** Human-guided, gamified
**Duration:** ~10 minutes
**Purpose:** Manual validation with user feedback

**What it tests:**

- Visual output quality
- User experience
- Real-world usage patterns
- Keybinding usability

**Features:**

- 🐕 Dog feeding game mechanics
- Shows EXPECTED vs ACTUAL output
- Single keystroke validation (y/n/q)
- Progress tracking
- Happiness meter

**Usage:**

```bash
./tests/interactive-wt-dogfooding.zsh
```

**Test flow:**

1. Shows expected behavior
2. Runs actual command
3. Asks: "Does output match?"
4. Feed dog (✓) or disappoint dog (✗)
5. Final happiness score

**Tests:**

- Phase 1: wt overview display (4 tests)
- Phase 2: pick wt actions (manual tests with instructions)
- Integration: Complete workflow (3 tests)

---

## Running All Tests

### Quick Validation

```bash
# Unit tests only (fast)
./tests/test-wt-enhancement-unit.zsh
```

### Full CI Suite

```bash
# Unit + E2E (automated)
./tests/test-wt-enhancement-unit.zsh && \
./tests/test-wt-enhancement-e2e.zsh
```

### Complete Validation

```bash
# All three suites
./tests/test-wt-enhancement-unit.zsh && \
./tests/test-wt-enhancement-e2e.zsh && \
./tests/interactive-wt-dogfooding.zsh
```

---

## Test Coverage

### Phase 1: Enhanced `wt` Default

| Feature                         | Unit | E2E | Interactive |
| ------------------------------- | ---- | --- | ----------- |
| `_wt_overview()` function       | ✅   | ✅  | ✅          |
| Formatted table output          | ✅   | ✅  | ✅          |
| Status icons (✅🧹⚠️🏠)         | ✅   | ✅  | ✅          |
| Session indicators (🟢🟡⚪)     | ✅   | ✅  | ✅          |
| Filter support (`wt <project>`) | ✅   | ✅  | ✅          |
| Updated help text               | ✅   | ✅  | ✅          |

### Phase 2: `pick wt` Actions

| Feature                       | Unit | E2E | Interactive |
| ----------------------------- | ---- | --- | ----------- |
| `_pick_wt_delete()` function  | ✅   | ⏸️  | ✅ (manual) |
| `_pick_wt_refresh()` function | ✅   | ✅  | ✅          |
| Ctrl-X keybinding             | 📝   | ⏸️  | ✅ (manual) |
| Ctrl-R keybinding             | 📝   | ⏸️  | ✅ (manual) |
| Multi-select (Tab)            | 📝   | ⏸️  | ✅ (manual) |
| Delete confirmation flow      | ⏸️   | ⏸️  | ✅ (manual) |
| Branch deletion prompt        | ⏸️   | ⏸️  | ✅ (manual) |
| Cache invalidation            | ✅   | ✅  | ✅          |
| Updated pick help             | ✅   | ✅  | ✅          |

**Legend:**

- ✅ Automated test
- ✅ (manual) Requires user interaction
- 📝 Documented in help test
- ⏸️ Skipped (requires interactive fzf)

---

## CI Integration

### GitHub Actions Workflow

Add to `.github/workflows/test.yml`:

```yaml
- name: Run WT Enhancement Tests
  run: |
    ./tests/test-wt-enhancement-unit.zsh
    ./tests/test-wt-enhancement-e2e.zsh
```

### Pre-commit Hook

Add to `.git/hooks/pre-commit`:

```bash
#!/bin/bash
./tests/test-wt-enhancement-unit.zsh || exit 1
```

---

## Test Environment Requirements

### Required Tools

- `zsh` (5.0+)
- `git` (2.30+)
- `fzf` (0.40+) - for interactive tests only

### Environment Variables

- `FLOW_WORKTREE_DIR` - Override worktree directory (E2E sets this)

### Git Repository

- Must be run inside a git repository
- E2E creates its own test repo

---

## Debugging Failed Tests

### Unit Test Failures

1. Check function loading:

   ```bash
   source flow.plugin.zsh
   type _wt_overview
   ```

2. Run function directly:

   ```bash
   _wt_overview
   ```

3. Check for errors:
   ```bash
   _wt_overview 2>&1 | grep -i error
   ```

### E2E Test Failures

1. Check test environment:

   ```bash
   # E2E creates /tmp/tmp.XXXXX directory
   ls -la /tmp/tmp.*
   ```

2. Run with debug output:

   ```bash
   DEBUG=1 ./tests/test-wt-enhancement-e2e.zsh
   ```

3. Manual cleanup if needed:
   ```bash
   rm -rf /tmp/tmp.*
   ```

### Interactive Test Issues

1. Ensure fzf is installed:

   ```bash
   which fzf
   fzf --version
   ```

2. Test fzf keybindings:
   ```bash
   echo -e "a\nb\nc" | fzf --multi --bind 'ctrl-x:accept'
   ```

---

## Test Maintenance

### Adding New Tests

1. **Unit tests** - Add to appropriate section in `test-wt-enhancement-unit.zsh`
2. **E2E tests** - Create new scenario function in `test-wt-enhancement-e2e.zsh`
3. **Interactive tests** - Add new `run_test` call in phase section

### Updating Expected Output

When implementation changes:

1. Update test assertions in unit tests
2. Update E2E expected counts/patterns
3. Update interactive test EXPECTED descriptions

### Test Coverage Goals

- Unit: ≥ 80% function coverage
- E2E: ≥ 90% feature coverage
- Interactive: 100% user-facing feature validation

---

## Known Limitations

### Interactive Tests

- Cannot fully automate fzf interactions
- Require user input for delete/refresh actions
- Manual validation of keybindings

### E2E Tests

- Create temporary directories (cleaned up)
- Requires git repository
- Some tests may skip on different git states

### Unit Tests

- Cannot test actual fzf picker
- Cannot test terminal width adjustments
- Cannot test color output rendering

---

## Spec Compliance

All tests validate features from:

- `docs/specs/SPEC-wt-workflow-enhancement-2026-01-17.md`

### Acceptance Criteria Mapping

| Criteria                 | Test Coverage          |
| ------------------------ | ---------------------- |
| wt shows formatted table | Unit, E2E, Interactive |
| Status icons implemented | Unit, E2E, Interactive |
| Session indicators       | Unit, E2E, Interactive |
| Filter support           | Unit, E2E, Interactive |
| pick wt ctrl-x delete    | Interactive (manual)   |
| pick wt ctrl-r refresh   | Unit, E2E, Interactive |
| Multi-select             | Interactive (manual)   |
| Delete confirmation      | Interactive (manual)   |
| Branch deletion prompt   | Interactive (manual)   |
| Cache invalidation       | Unit, E2E              |

---

## Success Metrics

### Expected Results

**Unit Tests:**

- 20+ tests pass
- 0 failures
- Runtime < 30 seconds

**E2E Tests:**

- 25+ tests pass
- ≤ 2 skips (merged status detection)
- Runtime < 1 minute

**Interactive Tests:**

- Dog happiness > 80%
- All manual tests validated
- No usability issues reported

---

## Contributing

When adding new WT features:

1. Write unit tests first (TDD)
2. Add E2E scenario if workflow changes
3. Update interactive tests for UX validation
4. Run all three test suites before PR

---

**Last Updated:** 2026-01-17
**Test Coverage:** ~85% automated, 100% with manual validation
**Status:** ✅ All tests passing
