# Testing Quick Reference

**flow-cli Test Suite Overview**

## Quick Commands

```bash
# Interactive Dog Feeding Test (Most Fun!) 🐕
./tests/interactive-dog-feeding.zsh

# Automated Test Suite (Fast)
./tests/automated-test.zsh

# ZSH Configuration Tests
zsh/tests/run-all-tests.zsh

# Quick check (no performance test)
zsh/tests/run-all-tests.zsh --quick
```

---

## Test Suites

### 1. Interactive Dog Feeding Test 🐕⭐

**Location:** `tests/interactive-dog-feeding.zsh`

**Purpose:** Gamified manual validation of all core commands

**Features:**

- 👀 Shows comprehensive expected patterns
- ▶️ Runs commands and shows actual output
- ❓ Interactive y/n validation
- 🐕 Feed virtual dog by confirming tests pass
- ⭐ Earn 1-5 stars based on performance

**What It Tests (7 tasks):**

1. Dashboard display (16 detailed patterns)
2. Work session start (7 patterns)
3. Idea capture (3 patterns)
4. Win logging (4 patterns)
5. Active session in dashboard (7 patterns)
6. ADHD helper `js` (6 patterns)
7. Session finish (3 patterns)

**Best For:**

- First-time installation validation
- After major changes
- Teaching new users
- Making testing enjoyable

**Time:** ~3-5 minutes (interactive)

---

### 2. Automated Test Suite

**Location:** `tests/automated-test.zsh`

**Purpose:** Non-interactive automated validation

**What It Tests:**

- Plugin loading
- Core commands (dash, work, finish)
- Session tracking
- Status parsing
- Aliases

**Tests:** 16 automated checks

**Time:** ~10 seconds

**Exit Codes:**

- `0` - All tests passed
- `1` - Some tests failed

**Best For:**

- CI/CD pipelines
- Quick validation
- Pre-commit checks

---

### 3. ZSH Configuration Tests

**Location:** `zsh/tests/run-all-tests.zsh`

**Purpose:** Validate ZSH plugin structure

**What It Tests:**

- Duplicate detection
- Dispatcher functions
- Startup performance

**Options:**

```bash
# Full suite (includes performance test)
zsh/tests/run-all-tests.zsh

# Quick (skip performance)
zsh/tests/run-all-tests.zsh --quick
```

**Best For:**

- After refactoring
- Checking for duplicates
- Performance regression

---

## Test Results

### Interactive Dog Feeding

```
Tasks Confirmed: 7 / 7
Final Happiness: 98%
Grade:           PERFECT!
Stars:           ⭐⭐⭐⭐⭐
🐕 The dog is ECSTATIC! All tests confirmed! 😊⭐
```

### Automated Test

```
Tests run:    16
Passed:       16
Failed:       0
✓ All tests passed!
```

### ZSH Tests

```
Passed:  2
Failed:  0
Skipped: 1
OVERALL: PASS
```

---

## Grading System (Dog Feeding Test)

| Tasks | Grade      | Stars      | Dog Status      |
| ----- | ---------- | ---------- | --------------- |
| 7/7   | PERFECT!   | ⭐⭐⭐⭐⭐ | ECSTATIC! 😊⭐  |
| 5-6   | EXCELLENT! | ⭐⭐⭐⭐   | Very happy! 😊  |
| 3-4   | GOOD       | ⭐⭐⭐     | Satisfied 🤔    |
| 0-2   | NEEDS WORK | ⭐         | Still hungry 😢 |

---

## Common Test Scenarios

### After Fresh Install

```bash
git clone https://github.com/data-wise/flow-cli.git
cd flow-cli
./tests/interactive-dog-feeding.zsh
```

### Quick CI Check

```bash
./tests/automated-test.zsh && echo "CI: PASS"
```

### After Code Changes

```bash
# Full validation
./tests/automated-test.zsh
zsh/tests/run-all-tests.zsh --quick
./tests/interactive-dog-feeding.zsh
```

---

## Troubleshooting

### Dog Test Shows Wrong Expected Output

**Fixed in v3.0.0!** Parameter parsing bug resolved.

### Command Not Found Errors

Make sure plugin is loaded:

```bash
source flow.plugin.zsh
```

### Tests Fail But Commands Work

Check for external command dependencies (grep, head, etc.)

---

## Test Coverage

**Total Patterns:** ~60 comprehensive expected patterns  
**Commands Tested:** dash, work, finish, catch, win, js  
**Test Types:** Interactive, Automated, Unit, Integration  
**Pass Rate Target:** 100%

---

## Latest Updates (Dec 25, 2025)

✅ Fixed parameter parsing in interactive test  
✅ Added 60 comprehensive expected patterns  
✅ Dashboard test upgraded: 4 → 16 patterns (+300%)  
✅ All tests updated for v3.0.0 architecture  
✅ ZSH configuration tests fixed for new structure

---

## See Also

- [Dog Feeding Test README](../../tests/DOG-FEEDING-TEST-README.md)
- [Interactive Test Guide](../../tests/INTERACTIVE-TEST-GUIDE.md)
- [Testing Guide](../testing/TESTING.md)
- [Main README](../../README.md)

---

**Quick Tip:** Start with the dog feeding test - it's the most fun and comprehensive! 🐕⭐
