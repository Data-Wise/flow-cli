# timer

> Focus and break timer for ADHD-friendly time management

The `timer` command provides Pomodoro-style focus timers with visual countdown, break reminders, and macOS notifications.

---

## Usage

```bash
timer [command] [options]
```

## Commands

| Command     | Alias | Description                     |
| ----------- | ----- | ------------------------------- |
| `[minutes]` | -     | Start focus timer (default: 25) |
| `focus`     | -     | Start focus session             |
| `break`     | `brk` | Start break timer (default: 5)  |
| `pomodoro`  | `pom` | Run pomodoro cycles             |
| `stop`      | -     | Cancel active timer             |
| `status`    | `st`  | Show remaining time             |
| `help`      | `-h`  | Show help                       |

---

## Examples

### Quick Start

```bash
# Default 25-minute focus timer
timer

# Custom duration
timer 45           # 45 minutes

# 5-minute break
timer break
```

### Focus Sessions

```bash
# Start focus session with label
timer focus 30 "Finish documentation"

# Check remaining time
timer status
# ⏱️ focus: 23:45 remaining
#    Finish documentation
```

### Pomodoro Cycles

```bash
# Run 4 pomodoro cycles (default)
timer pomodoro

# Custom: 6 cycles, 30-min focus, 5-min break, 20-min long break
timer pomodoro 6 30 5 20

# Shortcut alias
pom                # Same as: timer pomodoro
```

---

## Visual Output

### Focus Timer

```
🎯 FOCUS MODE
Focus session - 25 minutes

  ⏱️  23:45 [████████████░░░░░░░░]
```

### Break Timer

```
☕ BREAK TIME
5 minutes - stretch, hydrate, move

  ☕ 4:23 remaining
```

### Pomodoro

```
🍅 POMODORO
4 cycles: 25m focus, 5m break

━━━ Cycle 1 of 4 ━━━
```

---

## Notifications

On macOS, `timer` sends system notifications when timers complete:

- **Focus complete:** Glass sound
- **Break over:** Ping sound

---

## Timer State

Timers save state to `$FLOW_DATA_DIR/timer.state`, allowing you to:

- Check status from any terminal
- Cancel from any terminal
- Resume awareness after terminal switch

```bash
# From any terminal
timer status
timer stop
```

---

## Integration with Work Sessions

The `timer` command integrates with the work flow:

```bash
# Start working
work my-project

# Start a focus block
timer 45 "Complete feature X"

# Timer leaves a breadcrumb
# 🍞 Started 45 min focus: Complete feature X

# When done
finish "Completed feature X"
```

---

## Pomodoro Options

```bash
timer pomodoro [cycles] [focus] [break] [long-break]
```

| Parameter    | Default | Description                    |
| ------------ | ------- | ------------------------------ |
| `cycles`     | 4       | Number of pomodoro cycles      |
| `focus`      | 25      | Focus duration (minutes)       |
| `break`      | 5       | Short break duration (minutes) |
| `long-break` | 15      | Long break after all cycles    |

**Long break logic:**

- After every 4th cycle: long break
- After final cycle: long break

---

## Tips

!!! tip "Start Small"
If 25 minutes feels too long, start with `timer 15`. Build up gradually.

!!! tip "Respect the Break"
When the break timer starts, actually step away. The short break is essential for ADHD focus management.

!!! tip "Use Labels"
`timer 25 "Fix the auth bug"` helps you remember what you were doing when you return.

!!! tip "Interrupt = Stop"
Press `Ctrl+C` to interrupt any timer. Your session state is preserved.

---

## Aliases

| Alias | Command          |
| ----- | ---------------- |
| `pom` | `timer pomodoro` |

---

## Related Commands

| Command                 | Description                |
| ----------------------- | -------------------------- |
| [`work`](work.md)       | Start focused work session |
| [`finish`](finish.md)   | End session                |
| [`morning`](morning.md) | Morning startup routine    |
| `flow break`            | Take a proper break        |

---

## See Also

- [Dopamine Features Guide](../guides/DOPAMINE-FEATURES-GUIDE.md)
- [Workflow Quick Reference](../reference/WORKFLOW-QUICK-REFERENCE.md)

---

**Last Updated:** 2026-01-07
**Command Version:** v4.8.0 (timer v1.0)
**Status:** ✅ Production ready with Pomodoro cycles and notifications
