# Help System Update Plan

**Date:** 2025-12-25  
**Status:** Planning  
**Priority:** P1 (High - Production readiness)

---

## Executive Summary

Update command-line help for all newly created/modified commands to ensure consistent, ADHD-friendly, discoverable help system across all dispatchers and core commands.

---

## Current State Analysis

### ✅ Commands with Good Help (7)

| Command | Help Function      | Quality    | Notes                                     |
| ------- | ------------------ | ---------- | ----------------------------------------- |
| `r`     | `_r_help()`        | ⭐⭐⭐⭐⭐ | Excellent - comprehensive, well-organized |
| `qu`    | `_qu_help()`       | ⭐⭐⭐⭐⭐ | Excellent - clear workflow examples       |
| `g`     | `_g_help()`        | ⭐⭐⭐⭐⭐ | Excellent - thorough git commands         |
| `mcp`   | `_mcp_help()`      | ⭐⭐⭐⭐⭐ | Excellent - clear locations and examples  |
| `dash`  | `_dash_help()`     | ⭐⭐⭐⭐   | Good - clear usage and options            |
| `flow`  | `_flow_help()`     | ⭐⭐⭐⭐⭐ | Excellent - comprehensive CLI overview    |
| `pick`  | Help with `--help` | ⭐⭐⭐⭐   | Good - clear categories and keys          |

### ⚠️ Commands with Incomplete Help (6)

| Command  | Current State                | Priority | Issue                      |
| -------- | ---------------------------- | -------- | -------------------------- |
| `work`   | No `--help` flag             | P0       | Core command, needs help   |
| `finish` | No help                      | P0       | Core command, needs help   |
| `hop`    | No help                      | P1       | Useful command, needs help |
| `catch`  | No help                      | P1       | Quick capture needs help   |
| `obs`    | Basic help only              | P1       | Help exists but incomplete |
| `status` | `_flow_status_help()` exists | P2       | Has help, needs review     |

### ❌ Commands with No Help (7)

| Command           | File                 | Priority | Notes                       |
| ----------------- | -------------------- | -------- | --------------------------- |
| `js` (just-start) | commands/adhd.zsh    | P1       | ADHD helper, needs help     |
| `stuck`           | commands/adhd.zsh    | P1       | ADHD helper, needs help     |
| `focus`           | commands/adhd.zsh    | P1       | ADHD helper, needs help     |
| `next`            | commands/adhd.zsh    | P1       | ADHD helper, needs help     |
| `crumb`           | commands/capture.zsh | P2       | Capture command, needs help |
| `inbox`           | commands/capture.zsh | P2       | Capture command, needs help |
| `win`             | commands/capture.zsh | P2       | Capture command, needs help |

---

## Help System Standards

### ADHD-Friendly Principles

1. **Discoverable:** Every command must respond to `--help`, `-h`, or `help`
2. **Scannable:** Use visual hierarchy (headers, sections, icons)
3. **Prioritized:** Show most common uses first (80/20 rule)
4. **Examples:** Include practical examples, not just syntax
5. **Consistent:** Same structure and color scheme across all commands
6. **Fast:** Help should display instantly (< 100ms)

### Visual Format Standard

```bash
╭─────────────────────────────────────────────╮
│ <cmd> - Brief Description                   │
╰─────────────────────────────────────────────╯

🔥 MOST COMMON (80% of daily use):
  <cmd> action1     Description
  <cmd> action2     Description

💡 QUICK EXAMPLES:
  $ <cmd> action1           # Comment
  $ <cmd> action2           # Comment

📋 CATEGORY 1:
  <cmd> sub1        Description
  <cmd> sub2        Description

📋 CATEGORY 2:
  <cmd> sub3        Description
  <cmd> sub4        Description

ℹ️  ADDITIONAL INFO:
  Details about workflows, tips, etc.

💡 TIP: Helpful tip for effective usage
```

### Color Scheme (from lib/core.zsh)

- **Green (32m):** Section headers, success
- **Cyan (36m):** Command names
- **Yellow (33m):** Examples section
- **Blue (34m):** Category headers
- **Magenta (35m):** Tips
- **Dim (2m):** Comments, secondary text
- **Bold (1m):** Main header

---

## Implementation Plan

### Phase 1: Core Commands (P0) - Week 1

#### 1.1 Add Help to `work` Command

**File:** `commands/work.zsh`

**Function to create:** `_work_help()`

**Content:**

```bash
_work_help() {
    cat << 'EOF'
╭─────────────────────────────────────────────╮
│ work - Start Focused Work Session           │
╰─────────────────────────────────────────────╯

🔥 MOST COMMON (80% of daily use):
  work <project>    Start session on project
  work              Pick project interactively (if fzf installed)

💡 QUICK EXAMPLES:
  $ work flow-cli           # Start working on flow-cli
  $ work                    # Interactive picker
  $ work my-project code    # Open in specific editor

📋 USAGE:
  work <project> [editor]

ARGUMENTS:
  project     Project name (e.g., flow-cli, mediation-planning)
  editor      Editor to use (default: $EDITOR or code)

BEHAVIOR:
  • Checks for active sessions (prevents conflicts)
  • Changes to project directory
  • Shows project context (.STATUS, git status)
  • Starts editor if specified
  • Integrates with atlas (if available)

RELATED:
  finish [note]    End current session
  hop <project>    Quick switch (tmux)
  dash             View all projects
  why              Show current context

💡 TIP: Use 'work' without args for interactive picker!
EOF
}
```

**Changes needed:**

- Add help function at end of file
- Update `work()` to handle `--help`, `-h`, `help`
- Test with: `work --help`, `work -h`

#### 1.2 Add Help to `finish` Command

**File:** `commands/work.zsh`

**Function to create:** `_finish_help()`

**Content:**

```bash
_finish_help() {
    cat << 'EOF'
╭─────────────────────────────────────────────╮
│ finish - End Work Session                   │
╰─────────────────────────────────────────────╯

🔥 MOST COMMON:
  finish                End session, no commit
  finish "msg"          End session with git commit

💡 QUICK EXAMPLES:
  $ finish                      # Simple session end
  $ finish "Completed feature"  # Commit and end
  $ finish -n                   # No commit, skip prompt

📋 USAGE:
  finish [commit-message] [options]

ARGUMENTS:
  message     Optional commit message (triggers git commit)

OPTIONS:
  -n, --no-commit    Skip git commit even if changes exist
  -p, --push         Also push after committing

BEHAVIOR:
  1. Checks for uncommitted changes
  2. Offers to commit if changes exist
  3. Ends session (atlas integration if available)
  4. Optionally pushes to remote

RELATED:
  work <project>    Start new session
  hop <project>     Quick switch
  catch <text>      Quick capture before finishing

💡 TIP: 'finish "msg"' auto-commits, saves a step!
EOF
}
```

**Changes needed:**

- Add help function
- Update `finish()` to handle help flags
- Test with: `finish --help`

#### 1.3 Update `work()` and `finish()` Main Functions

**Pattern:**

```bash
work() {
    # Handle help first
    case "$1" in
        --help|-h|help) _work_help; return 0 ;;
    esac

    # Existing logic...
}
```

---

### Phase 2: ADHD Helpers (P1) - Week 1

#### 2.1 Create Master Help for ADHD Commands

**File:** `commands/adhd.zsh`

**Function to create:** `_adhd_help()`

**Content:**

```bash
_adhd_help() {
    cat << 'EOF'
╭─────────────────────────────────────────────╮
│ ADHD Workflow Helpers                       │
╰─────────────────────────────────────────────╯

🧠 DECISION PARALYSIS:
  js / just-start   Auto-picks your next task (P0 → P1 → Active)
  next              What should I work on? (manual suggestion)
  pick              Interactive picker (full control)

🚧 WHEN STUCK:
  stuck             Unstuck workflow (break down task)
  break [mins]      Take a proper break (default: 5 min)

🎯 FOCUS MANAGEMENT:
  focus <text>      Set current focus/intention
  focus             Show current focus

💪 MOTIVATION:
  win <text>        Log a win (dopamine boost!)
  wins              Show recent wins

📝 QUICK CAPTURE:
  catch <idea>      Quick inbox capture
  crumb <note>      Leave project breadcrumb
  inbox             View captured items

⏱️  TIMERS:
  timer [mins]      Start focus timer (default: 25)
  timer status      Check remaining time
  timer stop        Cancel timer

💡 TIP: Start your day with 'js' - no decisions needed!

See individual command help: <command> --help
EOF
}
```

#### 2.2 Individual ADHD Command Help

**Commands to update:**

1. `js` / `just-start`
2. `stuck`
3. `focus`
4. `next`

**Example for `just-start`:**

```bash
_js_help() {
    cat << 'EOF'
╭─────────────────────────────────────────────╮
│ js / just-start - Zero-Decision Starter     │
╰─────────────────────────────────────────────╯

🔥 WHAT IT DOES:
  Automatically picks your next task based on:
  1. P0 priority projects (critical)
  2. P1 priority projects (important)
  3. Active status projects
  4. Longest time since last work

💡 ZERO DECISIONS:
  $ js              # Just run it, it decides for you!

📋 SELECTION LOGIC:
  • Filters by priority: P0 > P1 > P2
  • Filters by status: Active > Ready
  • Considers time since last session
  • Shows you what it picked and why

ℹ️  PERFECT FOR:
  ✓ Morning startup (decision fatigue)
  ✓ After breaks (context switching)
  ✓ When overwhelmed (too many choices)
  ✓ Quick productive wins

RELATED:
  next              Manual suggestion with explanation
  pick              Interactive picker (full control)
  work <project>    Explicit project choice

💡 TIP: Create alias 'alias start=js' for even faster!
EOF
}
```

---

### Phase 3: Capture Commands (P1-P2) - Week 2

#### 3.1 Update Capture Commands

**File:** `commands/capture.zsh`

**Commands:**

1. `catch` - Quick capture
2. `inbox` - View inbox
3. `crumb` - Leave breadcrumb
4. `win` - Log win

**Master help function:**

```bash
_capture_help() {
    cat << 'EOF'
╭─────────────────────────────────────────────╮
│ Capture & Track Commands                    │
╰─────────────────────────────────────────────╯

📥 QUICK CAPTURE:
  catch <idea>      Capture to inbox
  catch             View inbox items

🍞 BREADCRUMBS:
  crumb <note>      Leave note in current project
  trail             Show breadcrumb trail
  trail <project>   Show trail for specific project

💪 WINS TRACKING:
  win <text>        Log a win (dopamine!)
  wins              Show recent wins
  wins <project>    Show wins for project

📬 INBOX MANAGEMENT:
  inbox             View all inbox items
  inbox clear       Clear processed items

💡 TIP: 'catch' anything that pops in your head!

See individual command help: <command> --help
EOF
}
```

---

### Phase 4: Secondary Commands (P2) - Week 2

#### 4.1 Enhance `obs` Dispatcher Help

**File:** `lib/dispatchers/obs.zsh`

**Current state:** Basic help exists but incomplete

**Enhancement needed:**

- Expand help with examples
- Add common workflows
- Match dispatcher help standard
- Add Obsidian-specific tips

#### 4.2 Review and Update `status` Command

**File:** `commands/status.zsh`

**Current state:** Has `_flow_status_help()` - review for completeness

**Review checklist:**

- [ ] Matches visual standard
- [ ] Shows common uses first
- [ ] Includes practical examples
- [ ] Explains .STATUS file format
- [ ] Links to related commands

#### 4.3 Add Help to `hop` Command

**File:** `commands/work.zsh`

**Function to create:** `_hop_help()`

**Content:**

```bash
_hop_help() {
    cat << 'EOF'
╭─────────────────────────────────────────────╮
│ hop - Quick Project Switch (tmux)           │
╰─────────────────────────────────────────────╯

🔥 MOST COMMON:
  hop <project>     Switch to project (tmux session)

💡 QUICK EXAMPLES:
  $ hop mediation-planning      # Switch to project
  $ hop flow-cli                # Jump to flow-cli

📋 USAGE:
  hop <project>

BEHAVIOR:
  • Creates tmux session if not exists
  • Switches to existing session if exists
  • Changes to project directory
  • Preserves current session in background

REQUIREMENTS:
  • tmux must be installed
  • Must be in tmux session to switch

RELATED:
  work <project>    Start full work session
  finish            End current session
  pick              Interactive project picker

💡 TIP: Use 'hop' for quick context switches without ending current session!
EOF
}
```

---

## Implementation Checklist

### Week 1: Core & ADHD Commands

**Day 1-2: Core Commands**

- [ ] Create `_work_help()` function
- [ ] Update `work()` to handle help flags
- [ ] Test `work --help`, `work -h`
- [ ] Create `_finish_help()` function
- [ ] Update `finish()` to handle help flags
- [ ] Test `finish --help`, `finish -h`
- [ ] Create `_hop_help()` function
- [ ] Update `hop()` to handle help flags

**Day 3-4: ADHD Commands**

- [ ] Create `_adhd_help()` master function
- [ ] Create `_js_help()` function
- [ ] Update `js()` / `just-start()` to handle help
- [ ] Create `_stuck_help()` function
- [ ] Update `stuck()` to handle help
- [ ] Create `_focus_help()` function
- [ ] Update `focus()` to handle help
- [ ] Create `_next_help()` function
- [ ] Update `next()` to handle help

**Day 5: Testing**

- [ ] Test all new help functions
- [ ] Verify visual consistency
- [ ] Check color output
- [ ] Verify help flags work (`--help`, `-h`, `help`)

### Week 2: Capture & Secondary Commands

**Day 1-2: Capture Commands**

- [ ] Create `_capture_help()` master function
- [ ] Create `_catch_help()` function
- [ ] Update `catch()` to handle help
- [ ] Create `_inbox_help()` function
- [ ] Update `inbox()` to handle help
- [ ] Create `_crumb_help()` function
- [ ] Update `crumb()` to handle help
- [ ] Create `_win_help()` function
- [ ] Update `win()` to handle help

**Day 3: Secondary Commands**

- [ ] Enhance `_obs_help()` in obs.zsh
- [ ] Review `_flow_status_help()` in status.zsh
- [ ] Update if needed for consistency

**Day 4: Documentation**

- [ ] Update docs/reference/COMMAND-QUICK-REFERENCE.md
- [ ] Add help examples to tutorials
- [ ] Update getting-started/quick-start.md with help tips

**Day 5: Final Testing**

- [ ] Test all help commands
- [ ] Verify consistency across all commands
- [ ] Update CLAUDE.md with help info
- [ ] Deploy documentation to website

---

## Testing Plan

### Automated Testing

Create test script: `tests/test-help-system.zsh`

```bash
#!/usr/bin/env zsh

source flow.plugin.zsh

echo "Testing help system..."
errors=0

# Test all commands with help
commands=(
    "work" "finish" "hop"
    "js" "stuck" "focus" "next"
    "catch" "inbox" "crumb" "win"
    "r" "qu" "g" "mcp" "obs"
    "dash" "flow" "pick" "status"
)

for cmd in "${commands[@]}"; do
    echo -n "Testing: $cmd --help ... "
    if $cmd --help >/dev/null 2>&1; then
        echo "✓"
    else
        echo "✗ FAILED"
        ((errors++))
    fi
done

echo ""
echo "Total errors: $errors"
exit $errors
```

### Manual Testing Checklist

For each command:

- [ ] `<cmd> --help` displays help
- [ ] `<cmd> -h` displays help
- [ ] `<cmd> help` displays help (for dispatchers)
- [ ] Help uses consistent color scheme
- [ ] Help follows visual standard
- [ ] Examples are practical and accurate
- [ ] Most common uses shown first
- [ ] Related commands mentioned
- [ ] Tips provided where helpful

---

## Success Criteria

### Must Have

1. ✅ All core commands have `--help` support
2. ✅ All ADHD helpers have help functions
3. ✅ All capture commands have help
4. ✅ Help follows consistent visual standard
5. ✅ Help displays in < 100ms
6. ✅ All dispatchers have comprehensive help

### Should Have

1. ✅ Examples in every help output
2. ✅ Related commands cross-referenced
3. ✅ Tips for effective usage
4. ✅ Visual hierarchy (emojis, sections)
5. ✅ Test script passes 100%

### Nice to Have

1. ⭐ Man pages (future enhancement)
2. ⭐ HTML help output option
3. ⭐ Interactive help tutorials
4. ⭐ Video walkthroughs

---

## Documentation Updates

### Files to Update

1. **docs/reference/COMMAND-QUICK-REFERENCE.md**
   - Add "Getting Help" section
   - Show `--help` flag for each command

2. **docs/getting-started/quick-start.md**
   - Add section on discovering commands
   - Show help examples early

3. **docs/tutorials/\*.md**
   - Use `--help` examples in tutorials
   - Encourage exploration via help

4. **CLAUDE.md**
   - Document help system standards
   - Add help testing to development section

5. **README.md**
   - Mention help system in features
   - Show help examples in quick start

---

## Timeline

### Week 1 (Days 1-5)

- Core commands help (work, finish, hop)
- ADHD commands help (js, stuck, focus, next)
- Testing and fixes

### Week 2 (Days 6-10)

- Capture commands help (catch, inbox, crumb, win)
- Secondary commands review (obs, status)
- Documentation updates
- Final testing and deployment

**Total Effort:** 10 days (2 weeks)  
**Complexity:** Medium  
**Dependencies:** None (can start immediately)

---

## Maintenance

### Ongoing Standards

1. **New Commands:** Must include help from day 1
2. **Help Changes:** Document in commit messages
3. **Visual Consistency:** Use lib/core.zsh colors
4. **Testing:** Run help test script before commits

### Review Schedule

- **Monthly:** Review help accuracy
- **Quarterly:** Check for new patterns/improvements
- **Release:** Verify all help is up-to-date

---

## Future Enhancements

### Phase 5: Advanced Features (Future)

1. **Man Pages:**
   - Generate from help functions
   - Install to `/usr/local/share/man/`

2. **Interactive Tutorials:**
   - `flow learn help-system`
   - Guided tour of help features

3. **HTML Output:**
   - `<cmd> --help --html > help.html`
   - For documentation website

4. **Searchable Help:**
   - `flow help search <keyword>`
   - Cross-command search

5. **Context-Aware Help:**
   - Show different help based on current state
   - Project-type specific examples

---

## References

### Existing Good Examples

1. **r dispatcher** - lib/dispatchers/r-dispatcher.zsh
   - Comprehensive categories
   - Clear examples
   - Well-organized

2. **flow command** - commands/flow.zsh
   - Great visual hierarchy
   - Multiple sections
   - Context-aware grouping

3. **g dispatcher** - lib/dispatchers/g-dispatcher.zsh
   - Thorough command list
   - Practical examples
   - Short forms documented

### Color Standards

See `lib/core.zsh` for:

- `_c_bold()` - Bold text
- `_c_dim()` - Dimmed text
- Color codes for consistency

### ADHD-Friendly Resources

- Keep it scannable (emojis, headers)
- Prioritize common uses (80/20)
- Show examples, not just syntax
- Make it fast (no waiting)
- Allow discovery (related commands)

---

**Last Updated:** 2025-12-25  
**Status:** Ready for implementation  
**Owner:** Development team  
**Est. Completion:** 2 weeks
