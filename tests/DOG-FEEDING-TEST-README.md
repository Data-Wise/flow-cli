# 🐕 Interactive Dog Feeding Test

**The most fun way to test your flow-cli installation!**

## Overview

This gamified test validates your flow-cli setup by having you "feed a virtual dog" through confirming that commands produce expected output. The test runs each command, shows you comprehensive expected patterns, displays the actual output, and asks you to confirm if they match. Each successful confirmation earns you food to feed the dog and increases its happiness level.

**Latest Version:** Completely revised with comprehensive expected patterns that match flow-cli's rich, elaborate outputs (Dec 25, 2025)

## Quick Start

```bash
cd /path/to/flow-cli
./tests/interactive-dog-feeding.zsh
```

## How It Works

For each test task:

1. 📋 Shows the command that will run
2. 👀 Shows **comprehensive** expected output patterns to look for
3. ▶️ Runs the command and displays actual output
4. ❓ Asks you to confirm if actual matches expected
5. ✅ Feeds the dog if you confirm (or 😢 disappoints if not)

### What Makes This Test Special

**Comprehensive Expected Patterns:** Unlike typical tests, this shows you the FULL structure to expect:

- Complete box borders and separators
- All headers and sections
- Progress bars and indicators
- Nested structures and spacing
- Even blank lines are documented!

**Example:** Dashboard test shows 16 detailed patterns covering borders, headers, sections, progress bars, and footer - matching the rich output exactly.

## What It Tests

The dog feeding test validates **7 core flow-cli features**:

1. **Plugin Loading** - Ensures flow.plugin.zsh loads correctly
2. **Dashboard Display** - Tests `dash` command output format
3. **Work Session Start** - Tests `work <project>` command and display
4. **Idea Capture** - Tests `catch <idea>` command and confirmation
5. **Win Logging** - Tests `win <accomplishment>` command
6. **Active Session Display** - Verifies session shows in dashboard
7. **ADHD Helper** - Tests `js` (just start) command
8. **Session Cleanup** - Tests `finish` command completes cleanly

## Features

- 🐕 **Virtual Dog** - Feed and make happy by passing tests
- 🥩 **Food Rewards** - Earn food for each successful task
- ⭐ **Star Rating System** - Get 1-5 stars based on performance
- 😊 **Happiness Meter** - Track dog happiness (0-100%)
- 🎮 **Gamification** - ADHD-friendly, engaging test experience
- 📊 **Progress Tracking** - See X/7 tasks completed
- 🎨 **Colorful UI** - Beautiful terminal output with emojis

## Grading System

| Tasks Completed | Grade      | Stars      | Dog Status      |
| --------------- | ---------- | ---------- | --------------- |
| 7/7             | PERFECT!   | ⭐⭐⭐⭐⭐ | ECSTATIC! 😊⭐  |
| 5-6             | EXCELLENT! | ⭐⭐⭐⭐   | Very happy! 😊  |
| 3-4             | GOOD       | ⭐⭐⭐     | Satisfied 🤔    |
| 0-2             | NEEDS WORK | ⭐         | Still hungry 😢 |

## Sample Output

```
╔════════════════════════════════════════════════════════════╗
║  🐕  INTERACTIVE DOG FEEDING TEST  🐕                     ║
╚════════════════════════════════════════════════════════════╝

Welcome to the Interactive Dog Feeding Test!

Your mission: Feed the dog by confirming flow-cli works

How it works:
  1. We show you what to expect
  2. We run a command
  3. You confirm the output matches
  4. The dog gets fed if you confirm 🥩

Each successful confirmation makes the dog happier! 😊

═══════════════════════════════════════════════════════════
Task: Show Project Dashboard
═══════════════════════════════════════════════════════════

Command to run:
  $ dash

╭─ Expected Output ────────────────────────────────────────╮
│ Look for these patterns:
╰──────────────────────────────────────────────────────────╯
  ╭── or ╔══ (border characters)
  🌊 FLOW DASHBOARD
  Date and time in header
  Project names listed

👀 Watch carefully as the command runs...

╭─ Actual Output ──────────────────────────────────────────╮
╭──────────────────────────────────────────────────────────╮
│  🌊 FLOW DASHBOARD              Dec 25, 2025  🕐 20:24   │
╰──────────────────────────────────────────────────────────╯
... (dashboard content) ...
╰──────────────────────────────────────────────────────────╯

❓ Does the output match the expected patterns?
(y/n, default: y)
> y

✅ Great! Test passed!

The dog sees all your projects! 😊
🥩 Fed the dog! 😊
```

## Exit Codes

- `0` - All tests passed (7/7)
- `1` - Some tests failed (0-6/7)

## Use Cases

### 1. After Fresh Installation

```bash
# Install flow-cli
git clone https://github.com/Data-Wise/flow-cli.git
cd flow-cli

# Validate everything works
./tests/interactive-dog-feeding.zsh
```

### 2. After Major Refactor

```bash
# Made big changes? Feed the dog!
./tests/interactive-dog-feeding.zsh
```

### 3. Teaching New Users

```bash
# Perfect onboarding experience
# Shows all major features in fun way
./tests/interactive-dog-feeding.zsh
```

### 4. CI/CD Integration

```bash
# Non-interactive mode (auto-feeds with 'yes')
yes '' | ./tests/interactive-dog-feeding.zsh

# Check exit code
echo $?  # 0 = success, 1 = failure
```

## ADHD-Friendly Design

This test is specifically designed for ADHD developers:

- ✅ **Show, Don't Tell** - Shows expected output before running
- ✅ **Immediate Feedback** - See actual results right after
- ✅ **Dopamine Hits** - Stars and happy emojis for confirmations
- ✅ **Visual Progress** - Clear X/7 task counter
- ✅ **Gamification** - Feeding dog is more fun than "running tests"
- ✅ **Short Tasks** - Each task is quick and focused
- ✅ **Clear Expectations** - You know exactly what to look for
- ✅ **Simple Decisions** - Just confirm yes/no
- ✅ **Positive Reinforcement** - Dog gets happier with each confirmation
- ✅ **Forgiving** - Can continue even if one test fails

## Technical Details

### File Locations

- **Test Script:** `tests/interactive-dog-feeding.zsh`
- **Session File:** `~/.local/share/flow/.current-session`
- **Captures:** `~/.local/share/flow/captures/`
- **Wins Log:** `~/.wins/`

### Dependencies

- ZSH shell
- flow-cli plugin
- Standard terminal with emoji support

### Variables Tracked

```zsh
HUNGER=100          # Decreases as you feed (0-100)
HAPPINESS=50        # Increases with success (0-100)
TASKS_COMPLETED=0   # Increments per task (0-7)
TOTAL_TASKS=7       # Fixed at 7
```

## Troubleshooting

### Dog is Sad / Tests Fail

**Check plugin loads:**

```bash
source ~/projects/dev-tools/flow-cli/flow.plugin.zsh
type dash  # Should show function
```

**Check session directory:**

```bash
ls -la ~/.local/share/flow/
```

**Run individual commands:**

```bash
dash
work flow-cli
catch "test idea"
finish
```

### No Emoji Support

If emojis don't display:

1. Use a modern terminal (iTerm2, Ghostty, Warp)
2. Install a font with emoji support
3. Set `LANG=en_US.UTF-8`

## Contributing

Want to add more tasks? Edit the script and:

1. Increment `TOTAL_TASKS`
2. Add a new task section following the pattern
3. Use `run_test` helper function
4. Give appropriate food reward (5-20 points)

Example:

```zsh
run_test \
    "New Feature Test" \
    "your-command 2>&1" \
    "${GREEN}Success message ${STAR}${NC}" \
    15  # Food reward
```

## See Also

- **Main Test Suite:** `tests/automated-test.zsh`
- **ZSH Tests:** `zsh/tests/run-all-tests.zsh`
- **Interactive Guide:** `tests/INTERACTIVE-TEST-GUIDE.md`

---

**Made with ❤️ for ADHD developers who deserve fun tests!** 🐕⭐
