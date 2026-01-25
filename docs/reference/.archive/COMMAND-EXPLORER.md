# Command Explorer - Interactive Reference

**Search-friendly command reference organized by frequency and category**

**Version:** v2.0.0-beta.1 | **Last updated:** 2025-12-24

---

## 🔍 Quick Search

Use Cmd+F (Mac) or Ctrl+F (Windows/Linux) to search for commands by:

- **Name:** `flow status`, `rload`, `ccp`
- **Category:** `session`, `project`, `git`, `r-package`
- **Frequency:** `daily`, `weekly`, `occasional`
- **Feature:** `dashboard`, `visualization`, `caching`

---

## 📊 Commands by Frequency

### Daily Commands (Use 5+ times per day)

These are your muscle-memory commands - the ones you'll use constantly.

#### Session Management

| Command            | What it does                                 | Example              | Tutorial                                               |
| ------------------ | -------------------------------------------- | -------------------- | ------------------------------------------------------ |
| `flow status`      | Show current work status with visualizations | `flow status`        | [Tutorial 3](../tutorials/03-status-visualizations.md) |
| `flow status -v`   | Verbose mode with productivity metrics       | `flow status -v`     | [Tutorial 3](../tutorials/03-status-visualizations.md) |
| `work <project>`   | Start work session (ZSH function)            | `work rmediation`    | [Tutorial 1](../tutorials/01-first-session.md)         |
| `finish [message]` | End session and commit (ZSH function)        | `finish "Fixed bug"` | [Tutorial 1](../tutorials/01-first-session.md)         |

#### Project Navigation

| Command           | What it does                              | Example                         | Tutorial                               |
| ----------------- | ----------------------------------------- | ------------------------------- | -------------------------------------- |
| `pick`            | Interactive project picker (ZSH function) | `pick`, `pick r`, `pick --fast` | [Reference](PICK-COMMAND-REFERENCE.md) |
| `dash [category]` | Quick text dashboard (ZSH function)       | `dash r`, `dash teaching`       | [Reference](DASHBOARD-QUICK-REF.md)    |

#### R Package Development (If you use R)

| Command | What it does           | Example | Used in                |
| ------- | ---------------------- | ------- | ---------------------- |
| `rload` | Load package code      | `rload` | Development cycle      |
| `rtest` | Run package tests      | `rtest` | After code changes     |
| `rdoc`  | Generate documentation | `rdoc`  | After roxygen comments |

### Weekly Commands (Use 2-4 times per week)

#### Monitoring & Analysis

| Command             | What it does               | Example             | Tutorial                                       |
| ------------------- | -------------------------- | ------------------- | ---------------------------------------------- |
| `flow dashboard`    | Interactive real-time TUI  | `flow dashboard`    | [Tutorial 4](../tutorials/04-web-dashboard.md) |
| `flow status --web` | Launch web-based dashboard | `flow status --web` | [Tutorial 4](../tutorials/04-web-dashboard.md) |

#### R Package Development

| Command    | What it does                       | Example    | Used in                |
| ---------- | ---------------------------------- | ---------- | ---------------------- |
| `rcheck`   | R CMD check                        | `rcheck`   | Before CRAN submission |
| `rbuild`   | Build package                      | `rbuild`   | Creating .tar.gz       |
| `rinstall` | Install package                    | `rinstall` | Testing installation   |
| `rcycle`   | Full dev cycle (load + doc + test) | `rcycle`   | Quick iteration        |

#### Productivity Tools

| Command | What it does                          | Example | Used in        |
| ------- | ------------------------------------- | ------- | -------------- |
| `f25`   | 25-minute Pomodoro timer (ZSH alias)  | `f25`   | Focus sessions |
| `f50`   | 50-minute deep work timer (ZSH alias) | `f50`   | Deep work      |

### Occasional Commands (Use as needed)

#### Claude Code Integration

| Command | What it does                                   | Example | Used in               |
| ------- | ---------------------------------------------- | ------- | --------------------- |
| `ccp`   | Claude print mode (ZSH alias)                  | `ccp`   | Quick questions       |
| `ccr`   | Claude resume last session (ZSH alias)         | `ccr`   | Continue conversation |
| `cc`    | Context-aware Claude dispatcher (ZSH function) | `cc`    | Project-specific AI   |

#### Advanced R Package

| Command    | What it does             | Example    | Used in               |
| ---------- | ------------------------ | ---------- | --------------------- |
| `rpkgdown` | Build pkgdown site       | `rpkgdown` | Documentation updates |
| `rcov`     | Test coverage report     | `rcov`     | Quality checks        |
| `rclean`   | Clean build artifacts    | `rclean`   | Fresh start           |
| `rpkgdeep` | Deep clean (destructive) | `rpkgdeep` | Reset everything      |

---

## 📂 Commands by Category

### Session Management (Flow State Tracking)

**Core workflow:** Track work sessions, measure productivity, achieve flow state.

| Command          | Frequency | Description              | Flow State?                 |
| ---------------- | --------- | ------------------------ | --------------------------- |
| `flow status`    | Daily     | Current status dashboard | ✅ Shows flow indicator     |
| `flow status -v` | Daily     | Verbose with metrics     | ✅ Flow %, streak, trend    |
| `work <project>` | Daily     | Start session            | ✅ Starts flow timer        |
| `finish [msg]`   | Daily     | End session              | ✅ Records flow achievement |

**Flow State:** Sessions ≥15 minutes show 🔥 indicator. Track flow % in metrics.

**Learn more:** [Tutorial 1: Your First Session](../tutorials/01-first-session.md)

---

### Project Management (Multi-Project Workflows)

**Core workflow:** Scan, filter, rank, and switch between multiple projects.

| Command       | Frequency | Description        | Performance       |
| ------------- | --------- | ------------------ | ----------------- |
| `pick`        | Daily     | Interactive picker | ⚡ <10ms (cached) |
| `pick --fast` | Daily     | Skip git checks    | ⚡ <5ms           |
| `pick r`      | Daily     | Filter by category | ⚡ <10ms          |
| `dash [cat]`  | Daily     | Text dashboard     | ⚡ ~100ms         |

**Caching:** Project scanning uses 1-hour cache (10x+ speedup). First scan: ~3ms, Cached: <1ms.

**Learn more:** [Tutorial 2: Multiple Projects](../tutorials/02-multiple-projects.md)

---

### Visualization & Monitoring

**Core workflow:** Real-time dashboards, ASCII visualizations, productivity metrics.

| Command             | Frequency  | Description     | Features                     |
| ------------------- | ---------- | --------------- | ---------------------------- |
| `flow status`       | Daily      | ASCII dashboard | Progress bars, sparklines    |
| `flow status -v`    | Weekly     | Verbose metrics | Flow %, completion %, streak |
| `flow dashboard`    | Weekly     | Interactive TUI | Real-time, auto-refresh (5s) |
| `flow status --web` | Occasional | Web dashboard   | Browser-based monitoring     |

**ASCII Visualizations:**

- Progress bars: `[███████░░░] 70%`
- Sparklines: `▁▃▅▇█` (trend visualization)
- Charts: Duration bars, completion indicators

**Learn more:** [Tutorial 3: Status Visualizations](../tutorials/03-status-visualizations.md)

---

### R Package Development (23 Aliases)

**Core workflow:** Load → Edit → Document → Test → Check → Build.

#### Basic Cycle (Use daily)

| Command    | Stage       | Description             | Speed   |
| ---------- | ----------- | ----------------------- | ------- |
| `rload`    | 1. Load     | Load package code       | ~1s     |
| `rdoc`     | 2. Document | Generate docs (roxygen) | ~2s     |
| `rtest`    | 3. Test     | Run tests               | ~3-10s  |
| `rcheck`   | 4. Check    | R CMD check             | ~30-60s |
| `rbuild`   | 5. Build    | Build .tar.gz           | ~5s     |
| `rinstall` | 6. Install  | Install package         | ~10s    |

#### Composite Commands (Shortcuts)

| Command  | What it does      | Equivalent               | Time saved    |
| -------- | ----------------- | ------------------------ | ------------- |
| `rcycle` | Load + Doc + Test | `rload && rdoc && rtest` | 10 keystrokes |
| `lt`     | Load + Test       | `rload && rtest`         | 8 keystrokes  |
| `dt`     | Doc + Test        | `rdoc && rtest`          | 8 keystrokes  |

#### Advanced (Use weekly)

| Command    | Purpose                     | When to use           |
| ---------- | --------------------------- | --------------------- |
| `rpkgdown` | Build documentation site    | After major changes   |
| `rcov`     | Test coverage report        | Before release        |
| `rcovr`    | Open coverage report        | Review uncovered code |
| `rclean`   | Clean build artifacts       | Fresh build           |
| `rpkgdeep` | Deep clean (⚠️ destructive) | Reset everything      |

**Learn more:** [R Package Development Guide](https://r-pkgs.org/)

---

### Git Shortcuts (226+ via OMZ Plugin)

**Note:** Flow CLI uses the Oh My Zsh git plugin for 226+ git aliases.

#### Most Common (Top 10)

| Alias   | Git Command         | Use Case            |
| ------- | ------------------- | ------------------- |
| `g`     | `git`               | Base command        |
| `gst`   | `git status`        | Check status        |
| `ga`    | `git add`           | Stage files         |
| `gaa`   | `git add --all`     | Stage everything    |
| `gcmsg` | `git commit -m`     | Commit with message |
| `gp`    | `git push`          | Push to remote      |
| `gl`    | `git pull`          | Pull from remote    |
| `gco`   | `git checkout`      | Switch branch       |
| `gcb`   | `git checkout -b`   | Create branch       |
| `glo`   | `git log --oneline` | View log            |

**Full list:** [OMZ Git Plugin Reference](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git)

---

### Claude Code Integration

**Core workflow:** Context-aware AI assistance for coding.

| Command | Description             | Context Detection           | Learn More                                        |
| ------- | ----------------------- | --------------------------- | ------------------------------------------------- |
| `cc`    | Smart Claude dispatcher | R package, Quarto, Git repo | [ZSH Functions](../ZSH-DEVELOPMENT-GUIDELINES.md) |
| `ccp`   | Claude print mode       | Quick answers               | [Command Reference](ALIAS-REFERENCE-CARD.md)      |
| `ccr`   | Claude resume           | Continue last conversation  | [Command Reference](ALIAS-REFERENCE-CARD.md)      |

---

### Productivity Timers

**Core workflow:** Pomodoro and deep work focus timers.

| Command | Duration   | Use Case         | Based On                 |
| ------- | ---------- | ---------------- | ------------------------ |
| `f25`   | 25 minutes | Pomodoro session | Pomodoro Technique       |
| `f50`   | 50 minutes | Deep work block  | Deep Work by Cal Newport |

**Features:** Notification when complete, auto-break suggestion.

---

## 🎯 Commands by Use Case

### "I'm starting a new work session"

```bash
# Option 1: Quick start (ZSH function)
work rmediation "Fix bug #123"

# Option 2: CLI with explicit parameters
flow work rmediation --task "Fix bug #123"

# Check your status
flow status
```

**See:** [Tutorial 1: Your First Session](../tutorials/01-first-session.md)

---

### "I'm switching between projects"

```bash
# Interactive picker
pick

# Filter by category
pick r          # R packages only
pick teaching   # Teaching projects only
pick research   # Research projects only

# Fast mode (skip git checks)
pick --fast

# Text dashboard
dash r          # R package dashboard
```

**See:** [Tutorial 2: Multiple Projects](../tutorials/02-multiple-projects.md)

---

### "I want to see my productivity metrics"

```bash
# Basic status
flow status

# With metrics (flow %, completion rate, streak)
flow status -v

# Real-time dashboard
flow dashboard

# Web-based dashboard
flow status --web
```

**See:** [Tutorial 3: Status Visualizations](../tutorials/03-status-visualizations.md)

---

### "I'm developing an R package"

```bash
# Quick iteration cycle
rload     # Load package code
# ... edit code ...
rdoc      # Generate docs
rtest     # Run tests

# Or use composite command
rcycle    # Load + Doc + Test in one command

# Before CRAN submission
rcheck    # R CMD check
rcov      # Coverage report
rpkgdown  # Update documentation site
```

**See:** [R Package Guide](https://r-pkgs.org/)

---

### "I want real-time monitoring"

```bash
# Interactive TUI (Terminal User Interface)
flow dashboard

# Features:
# - Auto-refresh every 5 seconds
# - Keyboard shortcuts (r=refresh, /=filter, q=quit, ?=help)
# - 4-widget grid layout
# - Real-time session updates
```

**See:** [Tutorial 4: Web Dashboard](../tutorials/04-web-dashboard.md)

---

## 🚀 Performance Characteristics

### Speed by Command Type

| Command Type                   | First Run | Cached | Speedup           |
| ------------------------------ | --------- | ------ | ----------------- |
| ZSH functions                  | <10ms     | <10ms  | N/A (always fast) |
| flow CLI (no scan)             | ~50ms     | ~50ms  | N/A               |
| flow CLI (with scan)           | ~100ms    | ~3ms   | 33x faster        |
| Project scanning (60 projects) | ~3ms      | <1ms   | 10x+ faster       |

**Caching:** Flow CLI uses in-memory cache (1-hour TTL) for project scanning. Cache automatically invalidates after 1 hour or on manual refresh.

---

## 📖 Related Documentation

### Quick References

- [Alias Reference Card](ALIAS-REFERENCE-CARD.md) - All 28 custom aliases
- [Workflow Quick Reference](WORKFLOW-QUICK-REFERENCE.md) - Daily workflows
- [Pick Command Reference](PICK-COMMAND-REFERENCE.md) - Project picker details
- [Dashboard Quick Ref](DASHBOARD-QUICK-REF.md) - Dashboard commands

### Tutorials

- [Tutorial 1: Your First Session](../tutorials/01-first-session.md)
- [Tutorial 2: Multiple Projects](../tutorials/02-multiple-projects.md)
- [Tutorial 3: Status Visualizations](../tutorials/03-status-visualizations.md)
- [Tutorial 4: Web Dashboard](../tutorials/04-web-dashboard.md)

---

## 💡 Tips for Efficient Usage

### Muscle Memory Development (Week 1)

- **Focus on 5 commands:** `flow status`, `work`, `finish`, `pick`, `rload`
- **Use aliases over full commands:** `rtest` vs `Rscript -e "devtools::test()"`
- **Practice daily:** Repetition builds muscle memory

### Advanced Usage (Week 2+)

- **Combine commands:** `rload && rdoc && rtest` or use `rcycle`
- **Use filters:** `pick r` instead of scrolling through all projects
- **Monitor metrics:** `flow status -v` to track productivity trends

### Performance Optimization

- **Use fast mode when appropriate:** `pick --fast` skips git checks
- **Leverage caching:** Project scanning is cached for 1 hour
- **Prefer ZSH functions:** <10ms vs ~100ms for Node.js CLI

---

**Version:** v2.0.0-beta.1
**Status:** Production Use Phase
**Last updated:** 2025-12-24
**Total commands documented:** 50+ (28 custom + 226 git plugin)
