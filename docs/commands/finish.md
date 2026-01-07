# finish

> **End your current work session with optional commit and session tracking**

The `finish` command cleanly ends your work session and optionally commits your changes.

---

## Synopsis

```bash
finish [note]
```

**Quick examples:**
```bash
# End session with a note
finish "Completed auth feature"

# End session without note
finish

# With commit confirmation
finish "Fixed bug #123"
# ✓ Session ended
# Commit 3 change(s)? [y/N] y
```

---

## Usage

```bash
finish [note]
```

## Arguments

| Argument | Description                   | Default                  |
| -------- | ----------------------------- | ------------------------ |
| `note`   | Session note / commit message | "Work session completed" |

---

## What It Does

1. **Ends the session** - Records session end time in atlas
2. **Detects git changes** - Counts uncommitted changes
3. **Prompts for commit** - Asks if you want to commit (if changes exist)
4. **Creates commit** - Uses your note as the commit message

---

## Examples

### Basic Finish

```bash
# End session with a note
finish "Completed feature implementation"

# End session without note
finish
```

### With Commit

```bash
$ finish "Fixed authentication bug"

# Output:
# ✓ Session ended
# Commit 3 change(s)? [y/N] y
# ✓ Changes committed: Fixed authentication bug
```

### Skip Commit

```bash
$ finish "WIP - will continue tomorrow"

# Output:
# ✓ Session ended
# Commit 5 change(s)? [y/N] n
```

---

## Session Tracking

When you `finish`, your session metrics are recorded:

- **Duration** - How long you worked
- **Project** - Which project you were on
- **Note** - What you accomplished

View your session history:

```bash
# See today's sessions
flow status -v

# See session stats in dashboard
dash
```

---

## Git Integration

The `finish` command has smart git integration:

| Scenario      | Behavior                        |
| ------------- | ------------------------------- |
| No git repo   | Skips commit prompt             |
| No changes    | Skips commit prompt             |
| Has changes   | Prompts to commit               |
| User confirms | Runs `git add -A && git commit` |

!!! warning "Stages All Changes"
`finish` uses `git add -A` which stages **all** changes including new files. Review your changes before confirming the commit.

---

## Related Commands

| Command                 | Description                            |
| ----------------------- | -------------------------------------- |
| [`work`](work.md)       | Start a new session                    |
| [`hop`](hop.md)         | Switch projects without ending session |
| [`win`](capture.md#win) | Log an accomplishment before finishing |

---

## Workflow Example

A typical work session:

```bash
# Start
work my-project

# ... do your work ...

# Log accomplishments
win "Implemented user auth"
win "Added tests"

# End session
finish "Auth feature complete"
```

---

## Tips

!!! tip "Log Wins Before Finishing"
Use `win` to log your accomplishments before running `finish`. This builds your streak and gives you a dopamine boost!

!!! tip "Meaningful Notes"
Use descriptive notes - they become your commit messages and help you remember what you did.

---

## See Also

- **Command:** [work](work.md) - Start a work session
- **Command:** [hop](hop.md) - Switch projects
- **Command:** [capture](capture.md) - Log wins and ideas
- **Reference:** [Workflow Quick Reference](../reference/WORKFLOW-QUICK-REFERENCE.md) - Common workflows

---

**Last Updated:** 2026-01-07
**Command Version:** v4.8.0
**Status:** ✅ Production ready with session tracking
