# tutorial

> Interactive, hands-on flow-cli tutorial with progress tracking

The `tutorial` command teaches flow-cli step by step through three graduated levels — Beginner, Medium, and Advanced. Each lesson explains a command, shows an example, and (for some lessons) offers to run it live. Progress is saved so you can stop and resume later.

---

## Usage

```bash
tutorial [level|action]
```

**Alias:** `tut` (same as `tutorial`)

## Levels

| Level      | Covers                                                        |
| ----------- | --------------------------------------------------------------- |
| `beginner` (or `1`) | Core workflow: `pick`, `work`, `dash`, `finish`            |
| `medium` (or `2`)   | Productivity tools: `catch`/`crumb`, `status`, `timer`, ADHD helpers |
| `advanced` (or `3`) | Power features: Atlas integration, smart dispatchers, customization, `morning` |

## Actions

| Action     | Description                          |
| ----------- | -------------------------------------- |
| `reset`     | Reset progress and start over          |
| `progress`  | Show current progress                  |
| `help` / `--help` / `-h` | Show help                 |

---

## Examples

```bash
# Start from wherever you left off (or the beginning, if never run)
tutorial

# Jump straight to a specific level
tutorial beginner
tutorial medium
tutorial advanced

# Check where you are
tutorial progress

# Start completely fresh
tutorial reset

# Help
tutorial help
```

---

## Auto-Resume Behavior

Running `tutorial` with no arguments checks your saved progress and picks up where you left off:

| Saved progress | What runs next     |
| --------------- | -------------------- |
| *(none / `0`)*  | Beginner lessons     |
| `beginner`      | Medium lessons       |
| `medium`        | Advanced lessons     |
| `advanced`      | Prints a "you've completed everything" message with options to reset or revisit a level |

At the end of each level, the tutorial asks `y/n` whether to continue straight into the next level.

---

## Beginner Lessons

1. **`pick`** — interactive project picker (fzf-based; filter, Ctrl-S for `.STATUS`, Ctrl-L for git log)
2. **`work`** — start a focused work session (cd + context + session timer)
3. **`dash`** — project dashboard (git status, `.STATUS` contents, active tasks)
4. **`finish`** — end the session cleanly (optional commit, duration recorded, note prompt)

Some lessons offer to run the real command (e.g., `pick --help`, `dash`) if you answer `y` to the prompt.

## Medium Lessons

1. **`catch`/`crumb`** — quick capture of ideas without breaking flow; also covers `inbox` and `win`
2. **`status`** — manage `.STATUS` files (`status`, `status set X`, `status next X`, `status all`)
3. **`timer`** — Pomodoro-style focus timers (`timer 25`, `timer status`, `timer stop`, `brk [mins]`)
4. **ADHD helpers** — `js` (Just Start), `stuck`, `focus <text>`, `next`, `why`

## Advanced Lessons

1. **Atlas integration** — optional state engine (`npm install -g @data-wise/atlas`, `atlas status`)
2. **Smart dispatchers** — `g`, `v`, `mcp`, `obs` (context-aware shortcuts per project type)
3. **Customization** — key environment variables (`FLOW_PROJECTS_ROOT`, `FLOW_ATLAS_ENABLED`, `FLOW_LOAD_DISPATCHERS`, `FLOW_QUIET`) and config/data locations (`~/.config/flow/`, `~/.local/share/flow/`)
4. **Morning routine** — the `morning` command (inbox review, active project statuses, suggested first task)

---

## Progress Tracking

Progress is stored as a single plain-text marker in:

```text
${FLOW_DATA_DIR:-$HOME/.local/share/flow}/tutorial-progress
```

The file contains one of: `0` (not started), `beginner`, `medium`, or `advanced` — whichever level you most recently completed.

```bash
tutorial progress
# 📊 Tutorial Progress: medium
# Status: Medium complete, ready for Advanced
```

`tutorial reset` deletes this file, returning you to the very beginning.

---

## Related Commands

| Command                | Description                        |
| ------------------------ | ------------------------------------ |
| [`setup`](setup.md)       | Interactive first-time setup wizard  |
| [`pick`](pick.md)         | Interactive project picker           |
| [`work`](work.md)         | Start a focused work session         |
| [`dash`](dash.md)         | Project dashboard                    |
| [`timer`](timer.md)       | Focus and break timer                |

---

## See Also

- [Master Dispatcher Guide](../reference/MASTER-DISPATCHER-GUIDE.md)

---

**Last Updated:** 2026-07-02
**Status:** Implemented in `commands/tutorial.zsh`
