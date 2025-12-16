# Test TODO List

## Quick Wins (from brainstorm 2025-12-14)

Priority tests that can be completed in < 30 min each.

### 🔥 High Priority

- [x] **Test alias loading after fix** [est: 15 min] ✅ COMPLETED 2025-12-14
  - ✅ Added 3 regression tests (Tests 21-23)
  - ✅ Test 21: ADHD helper aliases (js, idk, stuck → just-start)
  - ✅ Test 22: Morning routine renamed (morning, gmorning → pmorning)
  - ✅ Test 23: gm not overridden (avoids Gemini conflict)
  - ✅ Fixed Test 28 (updated expected aliases)
  - ✅ All new tests passing (49/52 assertions, 94% pass rate)
  - **Location:** `~/.config/zsh/tests/test-adhd-helpers.zsh`

- [x] **Test worklog function basics** [est: 20 min] ✅ COMPLETED 2025-12-14
  - ✅ Added 7 comprehensive tests (Tests 36-42)
  - ✅ Test 36: Function existence
  - ✅ Test 37: Usage message validation
  - ✅ Test 38: Log file creation
  - ✅ Test 39: Entry format (session|project|action|details)
  - ✅ Test 40: Timestamp format (YYYY-MM-DD HH:MM:SS)
  - ✅ Test 41: Confirmation message
  - ✅ Test 42: Aliases (wl, wls, wld)
  - ✅ All tests passing (9 new assertions, 100% pass rate)
  - **Location:** `~/.config/zsh/tests/test-adhd-helpers.zsh`

### 📝 Medium Priority

- [x] **Test crumbs-clear function** [est: 15 min] ✅ COMPLETED 2025-12-14
  - ✅ Added 6 comprehensive tests (Tests 43-48)
  - ✅ Test 43: Function existence
  - ✅ Test 44: Missing file handling
  - ✅ Test 45: Breadcrumb counting
  - ✅ Test 46: Confirmation prompt display
  - ✅ Test 47: Cancellation behavior (preserves file)
  - ✅ Test 48: Deletion test setup
  - ✅ All tests passing (7 new assertions, 100% pass rate)
  - 📝 Note: Full interactive deletion requires manual testing (read -q limitation)
  - **Location:** `~/.config/zsh/tests/test-adhd-helpers.zsh`

- [x] **Test whatnext alias** [est: 10 min] ✅ COMPLETED 2025-12-14
  - ✅ Added Test 36: whatnext function and wnow alias
  - ✅ Function existence check
  - ✅ Alias target verification (wnow → whatnext)
  - ✅ All tests passing (2 new assertions, 100% pass rate)
  - **Location:** `~/.config/zsh/tests/test-adhd-helpers.zsh`

- [x] **Test morning alias variants** [est: 15 min] ✅ ALREADY COMPLETED 2025-12-14
  - ✅ Covered by Test 22: morning routine regression test
  - ✅ Covered by Test 23: gm not overridden test
  - ✅ Verifies: morning, gmorning → pmorning
  - ✅ Verifies: gm NOT defined (avoids Gemini conflict)
  - ✅ All tests passing
  - **Location:** `~/.config/zsh/tests/test-adhd-helpers.zsh` (Tests 22-23)

---

## How to Run Tests

```bash
# Run full test suite
~/.config/zsh/tests/test-adhd-helpers.zsh

# Run and watch for specific test
~/.config/zsh/tests/test-adhd-helpers.zsh | grep -A5 "alias loading"
```

## Adding New Tests

**Pattern to follow:**

```zsh
run_test "Test description"
if [[ condition ]]; then
    pass "Test description"
else
    fail "Test description" "expected" "got"
fi
```

**Where to add:**
- Alias tests → After line 349 (existing "Aliases are defined" test)
- Function tests → Group with similar functions
- Keep tests in logical order

## Success Criteria

- [ ] All new tests pass
- [ ] No regressions (existing 25 tests still pass)
- [ ] Test output is clear and helpful
- [ ] Tests are maintainable (clear, simple)

---

*Created: 2025-12-14*
*Next: Start with "Test alias loading after fix" (15 min)*
