# Interactive Test Guide

**Date:** 2025-12-25
**Features:** Dashboard UI, Session Tracking, Interactive Mode

---

## Quick Test: Dog Feeding 🐕

**The most fun way to test flow-cli!**

```bash
./tests/interactive-dog-feeding.zsh
```

This gamified test validates:

- Plugin loading
- Dashboard display (with comprehensive pattern matching)
- Session management (work/finish)
- Capture commands (catch/win)
- ADHD helpers (js)
- Active session display
- User interactive validation

**Features:**

- 🐕 Feed a virtual dog by confirming commands work
- 👀 Shows comprehensive expected patterns (60+ patterns total!)
- ✅ Interactive y/n validation
- ⭐ Earn 1-5 stars based on performance
- 😊 Track dog happiness and hunger
- 🎮 ADHD-friendly gamification

**Latest Update (Dec 25, 2025):**

- ✅ Fixed parameter parsing bug
- ✅ Added comprehensive expected patterns for all 7 tests
- ✅ Dashboard test now shows 16 detailed patterns
- ✅ Each test shows correct expected output
- ✅ Captures complete box structures, separators, spacing

---

## Prerequisites

```bash
# Reload the plugin
source ~/.config/zsh/.zshenv
# OR
source ~/projects/dev-tools/flow-cli/flow.plugin.zsh
```

---

## Test 1: Basic Dashboard

**Goal:** Verify dashboard displays correctly with all sections

```bash
dash
```

**Expected Output:**

- [ ] Header shows date and current time (🕐)
- [ ] "Today:" stats row visible
- [ ] "ACTIVE NOW" section shows flow-cli (if session active)
- [ ] "QUICK ACCESS" shows 5 projects with active (🟢) first
- [ ] "BY CATEGORY" shows progress bars and "X active / Y" format
- [ ] Footer with tips visible

**Screenshot the output for reference.**

---

## Test 2: Category Expansion

**Goal:** Verify category drill-down works

```bash
dash dev
```

**Expected Output:**

- [ ] Header shows "🔧 DEV-TOOLS"
- [ ] Active projects (🟢) listed first
- [ ] Each project shows progress bar (████░░)
- [ ] Focus text shown below project name
- [ ] Footer says "← 'dash' to return to summary"

**Try other categories:**

```bash
dash r          # R packages
dash research   # Research projects
dash teach      # Teaching
```

---

## Test 3: Session Tracking

### 3a: Check Current Session

```bash
# View session file directly
cat ~/.local/share/flow/.current-session
```

**Expected:** Shows project, start timestamp, date

### 3b: End Current Session

```bash
finish "testing session tracking"
```

**Expected Output:**

- [ ] Shows "Session ended: Xm" (duration)
- [ ] Session file deleted

**Verify:**

```bash
cat ~/.local/share/flow/.current-session
# Should say: No such file or directory
```

### 3c: Start New Session

```bash
work atlas
```

**Expected:**

- [ ] Shows project context (📗 atlas)
- [ ] Status info displayed
- [ ] Session file created

**Verify:**

```bash
cat ~/.local/share/flow/.current-session
# Should show: project=atlas, start=..., date=...
```

### 3d: Check Dashboard Shows Active Session

```bash
dash
```

**Expected:**

- [ ] "ACTIVE NOW" section shows atlas
- [ ] Elapsed time displayed (⏱ Xm)

---

## Test 4: Interactive Mode

**Goal:** Test fzf-based project picker

```bash
dash -i
```

**Expected:**

- [ ] fzf picker opens
- [ ] Projects listed with icons (🔧📦🔬🎓)
- [ ] Status icons visible (🟢🟡⚪)
- [ ] Preview pane shows .STATUS content on right
- [ ] Header shows keybindings

**Actions to test:**

1. [ ] **Arrow keys** - Navigate up/down
2. [ ] **Type** - Filter projects (try typing "med")
3. [ ] **Enter** - Select project (should run `work`)
4. [ ] **Esc** - Cancel without action
5. [ ] **Ctrl-C** - Cancel

**Note:** Ctrl-D was intended for category expansion but may not work in all fzf versions.

---

## Test 5: Dual Format Parsing

**Goal:** Verify both .STATUS formats are parsed

### 5a: Markdown Format (dev-tools projects)

```bash
head -5 ~/projects/dev-tools/flow-cli/.STATUS
```

**Expected:** Uses `## Status:` format

### 5b: YAML Format (research projects)

```bash
head -5 ~/projects/research/collider/.STATUS
```

**Expected:** Uses `status:` format (lowercase, no ##)

### 5c: Dashboard Shows Both

```bash
dash research
```

**Expected:**

- [ ] Research projects show correct status icons
- [ ] Progress bars display (from `progress:` field)
- [ ] Focus text shown (from `next:` field)

---

## Test 6: Time Tracking Accumulation

### 6a: Complete Multiple Sessions

```bash
# End current session
finish "session 1"

# Start and end a quick session
work mcp-servers
sleep 2
finish "session 2"

# Start another
work flow-cli
sleep 2
finish "session 3"
```

### 6b: Check Worklog

```bash
tail -10 ~/.local/share/flow/worklog
```

**Expected:** Each END line shows duration (e.g., "END 0m")

### 6c: Dashboard Shows Accumulated Time

```bash
dash
```

**Expected:**

- [ ] "Today: X sessions" count is correct
- [ ] "⏱ Xm" shows total time (sum of sessions)

---

## Test 7: Edge Cases

### 7a: No Active Session

```bash
# Make sure no session is active
finish 2>/dev/null
dash
```

**Expected:**

- [ ] No "ACTIVE NOW" section displayed
- [ ] Dashboard still works

### 7b: Project Without .STATUS

```bash
dash dev
```

**Look for projects with ⚪ icon** - these have no .STATUS file

**Expected:**

- [ ] Shows ⚪ icon (unknown status)
- [ ] No progress bar
- [ ] No focus text

### 7c: Work on Project Without .STATUS

```bash
work zsh-claude-workflow
```

**Expected:**

- [ ] Session starts successfully
- [ ] Basic context shown (no status info)

---

## Test 8: Aliases

```bash
# Short alias for dash
d

# Interactive alias
di
```

**Expected:** Both work as shortcuts

---

## Test 9: Help

```bash
dash --help
```

**Expected:**

- [ ] Shows usage info
- [ ] Lists all options (-a, -i, -f, -h)
- [ ] Shows category list
- [ ] Shows legend for status icons

---

## Results Summary

| Test                   | Pass | Fail | Notes |
| ---------------------- | ---- | ---- | ----- |
| 1. Basic Dashboard     |      |      |       |
| 2. Category Expansion  |      |      |       |
| 3. Session Tracking    |      |      |       |
| 4. Interactive Mode    |      |      |       |
| 5. Dual Format Parsing |      |      |       |
| 6. Time Accumulation   |      |      |       |
| 7. Edge Cases          |      |      |       |
| 8. Aliases             |      |      |       |
| 9. Help                |      |      |       |

---

## Cleanup

```bash
# End any active session
finish "testing complete"

# Verify clean state
dash
```

---

## Issues Found

_Record any bugs or unexpected behavior here:_

1.
2.
3.
