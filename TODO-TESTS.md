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

- [ ] **Test crumbs-clear function** [est: 15 min]
  - Create a breadcrumb file
  - Run crumbs-clear
  - Verify file is removed
  - Check output message
  - **Location:** `~/.config/zsh/tests/test-adhd-helpers.zsh`

- [ ] **Test whatnext alias** [est: 10 min]
  - Verify alias exists
  - Verify it points to what-next
  - **Location:** `~/.config/zsh/tests/test-adhd-helpers.zsh`
  - **Pattern:** One-liner like existing alias tests

- [ ] **Test morning alias variants** [est: 15 min]
  - Verify 'morning' alias exists → pmorning
  - Verify 'gmorning' alias exists → pmorning
  - Verify 'gm' alias does NOT exist in adhd-helpers scope
  - **Location:** `~/.config/zsh/tests/test-adhd-helpers.zsh`

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
