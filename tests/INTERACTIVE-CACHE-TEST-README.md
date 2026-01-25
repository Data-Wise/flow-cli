# Interactive Cache Dog-Feeding Test

## Overview

An ADHD-friendly, gamified test suite for the project cache functionality. Feed a virtual dog by passing cache tests!

## Usage

```bash
./tests/interactive-cache-dogfeeding.zsh
```

## How It Works

### Game Mechanics

1. **Dog Stats**
   - **Hunger**: Starts at 100%, decreases as you feed the dog
   - **Happiness**: Starts at 50%, increases with successful tests
   - **Streak**: Consecutive passes give bonus happiness

2. **Food Values**
   - Basic tests: 10% food
   - Validation tests: 15% food
   - Command tests: 15% food
   - Advanced tests: 20% food
   - Integration tests: 25% food

3. **Streak Bonuses**
   - 3+ consecutive passes: +5 happiness bonus
   - Failing a test resets the streak

### Test Sections

#### Section 1: Basic Cache Generation (3 tests × 10%)

- Cache file creation
- Timestamp header validation
- Project data presence

#### Section 2: TTL Validation (3 tests × 15%)

- Fresh cache validity
- Cache age display
- Stale cache detection

#### Section 3: Cache Commands (3 tests × 15%)

- `flow cache refresh`
- `flow cache status`
- `flow cache clear`

#### Section 4: Auto-Regeneration (3 tests × 20%)

- Missing cache auto-generation
- Stale cache auto-regeneration
- Corrupt cache auto-regeneration

#### Section 5: Performance & Integration (3 tests × 25%)

- Cached access speed (<10ms)
- Cache disabled fallback

## Scoring

### Perfect Score (Dog is Full & Happy)

- Hunger: 0%
- Happiness: >70%
- All 15 tests passed
- Outcome: 🎉 **Dog is full and happy!**

### Good Score (Dog is Mostly Satisfied)

- Tasks: ≥12/15 completed
- Outcome: 😊 **Dog is mostly satisfied!**

### Needs Work (Dog is Still Hungry)

- Tasks: <12/15 completed
- Outcome: 😢 **Dog needs more food...**

## Interactive Features

- **Visual Progress Bars**: See hunger and happiness levels
- **Clear Test Format**: Each test shows:
  - 📝 **Command**: The exact command being run
  - ✨ **Expected**: What output you should see
  - 🔍 **Actual Output**: What actually happened
  - **Exit Code**: Success (0) or failure (non-zero)
- **Real-time Feedback**: Immediate response to each test
- **User Validation**: You confirm if test passed by comparing expected vs actual
- **Streaks & Bonuses**: Rewards for consistent passes
- **Emoji Reactions**: Dog's mood changes based on results

## Example Session

```
╔════════════════════════════════════════════════════════════╗
║  🐕💾  PROJECT CACHE DOG FEEDING TEST  💾🐕           ║
╚════════════════════════════════════════════════════════════╝

╭─ Dog Status ─────────────────────────────────────────────╮
│ Hunger:    ████████████████████░ 95%
│ Happiness: ██████████░░░░░░░░░░ 55% 😊 Very Happy
│ Tasks:     3/15 (Streak: 3)
╰──────────────────────────────────────────────────────────╯

╔═══════════════════════════════════════════════════════════╗
║ 👀 Test 1.1: Cache file is created
╚═══════════════════════════════════════════════════════════╝

📝 Command:
   flow cache refresh && [[ -f "$PROJ_CACHE_FILE" ]] && echo '✅ Cache file exists'

✨ Expected:
   ✅ Cache refreshed message, cache stats displayed, '✅ Cache file exists' message

🔍 Actual Output:
───────────────────────────────────────────────────────────
Refreshing project cache...
✅ Cache refreshed
Cache status: 🟢 Valid
Cache age: 0s (TTL: 300s)
Projects cached: 30
Location: /Users/dt/.cache/flow-cli/projects.cache
✅ Cache file exists at: /Users/dt/.cache/flow-cli/projects.cache
───────────────────────────────────────────────────────────

Exit code: 0 (success)

❓ Did this test pass? (y/n): y
✅ Test passed!
⭐ Streak bonus! +5 happiness
🥩 Fed the dog! 😊 +10% food, +10% happiness
```

## Tips for Success

1. **Compare Expected vs Actual** - Each test clearly shows:
   - What output is expected (✨ Expected)
   - What output actually occurred (🔍 Actual Output)
   - Whether the command succeeded (Exit code: 0)

2. **Look for Success Indicators** - Most tests end with a ✅ message
   - If you see the expected ✅ message in the actual output, the test passed
   - Check that the exit code is 0 (success)

3. **Maintain streaks** - Consecutive passes give +5 happiness bonuses

4. **Use debug mode** - Set `FLOW_DEBUG=1` for even more details

## When to Use This Test

- **Manual verification** after code changes
- **Demonstration** of cache functionality
- **ADHD-friendly** testing sessions
- **Learning** how the cache works

## Complementary Tests

For comprehensive testing, also run:

```bash
# Automated unit tests (faster, more coverage)
./tests/run-unit-tests.zsh

# Integration tests (end-to-end)
zsh tests/integration/test-pick-integration.zsh

# Comprehensive test (original)
zsh tests/test-project-cache.zsh
```

## Troubleshooting

If tests fail:

1. Check cache file location: `echo $PROJ_CACHE_FILE`
2. Verify plugin loaded: `type _proj_cache_is_valid`
3. Check TTL setting: `echo $PROJ_CACHE_TTL`
4. Run unit tests for detailed diagnostics

## Contributing

To add new tests to this interactive suite:

1. Add test case to appropriate section
2. Set food value based on difficulty:
   - Basic: 10%
   - Validation: 15%
   - Commands: 15%
   - Advanced: 20%
   - Integration: 25%
3. Increment `TOTAL_TASKS` variable
4. Use `run_test` function with description and command

---

**Last Updated:** 2026-01-11
**Status:** Complete
**Total Tests:** 15
