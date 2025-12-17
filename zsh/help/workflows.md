# Workflow Functions - Complete Guide

**21 ADHD-Optimized Workflow Helpers**

---

## 🚀 QUICK START

**Most important:**
```bash
here           # Where am I? Full context
next           # What's next? Quick view
start medfit   # Start work session
done           # End session (edit status)
morning        # Daily start routine
```

**When stuck:**
```bash
where          # Same as here
recent         # What was I working on?
critical       # What needs attention?
```

---

## 📚 ALL 21 FUNCTIONS

### CATEGORY 1: Context Awareness

#### here / where / context
**Show current context with visual clarity**
```bash
$ here

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📍 LOCATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
/Users/dt/projects/r-packages/active/medfit

📦 R PACKAGE: medfit
Version: 0.1.0

📊 STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[First 5 lines of .STATUS]

🔧 GIT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
## main...origin/main
 M R/fit.R
```

**When to use:**
- After interruption
- Switching projects
- "Where was I?"
- Context reconstruction

---

#### next / nextstep / todo
**Show just the next action from .STATUS**
```bash
$ next

🎯 NEXT ACTION:
Implement fit_mediation() function
- Create skeleton
- Add parameter validation
- Write initial tests
```

**When to use:**
- Quick "what's next?"
- Don't want to read full status
- After completing task

---

#### prog
**Show just progress bars**
```bash
$ prog

📊 PROGRESS:
[███░░░░░] 38% - fit_mediation implementation
[█████░░░] 63% - Documentation
[██████░░] 75% - Test coverage
```

---

### CATEGORY 2: Session Management

#### start / startwork
**Start work session on a project**
```bash
$ start medfit

# Jumps to project
# Shows full context (here)
# Starts Emacs daemon if needed
```

**Available projects:**
- medfit, probmed, medverse
- datawise, planning
- emacs

**Aliases:** `med`, `prob`, `verse`, `data`, `plan`

---

#### done / endwork
**End work session**
```bash
$ done

📝 Updating status...
[Opens .STATUS in Spacemacs]
```

**Use when:**
- Finishing work session
- Need to log what you did
- Update progress

---

#### pomo / timer / worktimer
**Pomodoro-style work timer**
```bash
$ pomo 25              # 25 minutes
$ pomo 50 "coding"     # 50 min labeled

⏱️  Starting 25 min session on: coding
Started at: 14:30
Timer PID: 12345
```

**After timer:**
- Voice notification: "Work session complete"
- Terminal message
- Reminder to update status

---

### CATEGORY 3: R Package Workflows

#### rcycle / rfull
**Complete R development cycle**
```bash
$ rcycle

🔄 Running full R package cycle...

1️⃣ Loading package...
✅ Done

2️⃣ Documenting...
✅ Done

3️⃣ Running tests...
✅ Done

4️⃣ Checking package...
✅ Done

✅ Full cycle complete!
```

**Runs:** load → doc → test → check  
**One command instead of four!**

---

#### rquick
**Quick check (load + test only)**
```bash
$ rquick

⚡ Quick check...
Loading... ✅
Testing... ✅
```

---

#### rpkg
**Smart jump to R package**
```bash
$ rpkg medfit

📦 Package: medfit
Version: 0.1.0
Title: Mediation Model Fitting

🎯 NEXT ACTION:
[Shows next from .STATUS]

## main...origin/main
[Shows git status]
```

**Shows:** Version, title, next action, git status

---

#### rpkgs / rpkgstatus
**Status of all R packages**
```bash
$ rpkgs

📦 R PACKAGES STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
medfit (0.1.0) - 🔴
probmed (0.1.0) - 🟡
mediationverse (0.1.0) - 🟢
medrobust (0.1.0) - ✅
medsim (0.1.0) - 🟡
```

---

### CATEGORY 4: Teaching

#### teach / teaching / class
**Jump to teaching + show what's due**
```bash
$ teach

📚 STAT 440/540
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 NEXT ACTION:
Grade assignment 3 (due Friday)

Recent Canvas updates:
[Last 5 items from canvas-updates.md if exists]
```

---

#### grade
**Start grading session**
```bash
$ grade

# Creates: grading-2025-12-12.md
# Opens in Emacs with template:
# - Assignment
# - Student count
# - Start time
# - Progress checklist
# - Notes section
```

---

### CATEGORY 5: Focus & Distraction

#### focus / concentrate / deep
**Minimize distractions**
```bash
$ focus 90        # 90-minute focus session

🎯 ENTERING FOCUS MODE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Distractions minimized
💪 Focus activated

⏱️  Starting 90 min session
```

**Actions:**
- Turns off macOS notifications
- Quits Slack, Mail, Messages
- Starts timer if minutes provided
- Voice notification when done

---

#### unfocus / break
**Restore distractions**
```bash
$ unfocus

🌅 Exiting focus mode...
✅ Notifications restored
```

---

#### break5 / break10
**Quick break timer**
```bash
$ break5          # 5-minute break
$ break10         # 10-minute break

☕ Taking 5 min break
Started: 14:30

# After 5 minutes:
🔔 Break complete - back to work!
```

---

### CATEGORY 6: Git Workflows

#### smartgit / gstat
**Enhanced git status**
```bash
$ smartgit

## main...origin/main
 M R/fit.R
 M tests/test-fit.R

Recent commits:
a1b2c3d Add fit_mediation skeleton
e4f5g6h Fix test failures
h7i8j9k Update documentation

Changed files:
M  R/fit.R
M  tests/test-fit.R
```

**Shows:** Status + recent commits + changed files

---

#### qcommit / qc
**Quick commit (add all + commit)**
```bash
$ qcommit "Implement fit_mediation"

# Runs:
# git add -A
# git status -sb
# git commit -m "Implement fit_mediation"
```

**One command instead of three!**

---

#### qpush / qp
**Quick commit + push**
```bash
$ qpush "Fix tests"

# Runs:
# git add -A
# git commit -m "Fix tests"
# git push
```

---

### CATEGORY 7: Search & Find

#### findproject / fp
**Find files across all projects**
```bash
$ fp fit_mediation

🔍 Searching all projects for: fit_mediation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
~/projects/r-packages/active/medfit/R/fit_mediation.R
~/projects/dev-tools/data-wise/notes/fit_mediation.md
```

---

#### recent / today / thisweek
**Recently modified files**
```bash
$ today          # Files modified today
$ recent 2       # Last 2 days
$ thisweek       # Last 7 days

📁 Files modified in last 1 day(s):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
~/projects/r-packages/active/medfit/R/fit.R
~/projects/r-packages/active/medfit/.STATUS
```

**Perfect after interruption:** "What was I working on?"

---

### CATEGORY 8: Status Management

#### critical / blocked / urgent
**Show all 🔴 items across projects**
```bash
$ critical

🔴 CRITICAL ITEMS (ACROSS ALL PROJECTS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📍 medfit:
🔴 Blocked: fit_mediation() implementation
🔴 Needs: Decision on generic functions

📍 probmed:
🔴 Blocked: Waiting for medfit P0
```

**Instant priority triage!**

---

#### active
**Show all 🟢 active projects**
```bash
$ active

🟢 ACTIVE WORK (ACROSS ALL PROJECTS)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✓ medfit
  ✓ datawise
  ✓ emacs-r-devkit
```

---

### BONUS: Original Ideas

#### morning
**Daily start routine**
```bash
$ morning

[Shows PROJECTS.md]

[Shows all .STATUS files across projects]
```

---

#### now
**Edit current project status in Spacemacs**
```bash
$ now

[Opens .STATUS in Spacemacs]
```

---

#### goto
**Jump to project + show status**
```bash
$ goto medfit

[Jumps to ~/projects/medfit]
[Shows .STATUS]
```

---

## 💡 EXAMPLE WORKFLOWS

### Morning Routine
```bash
$ morning           # What's happening?
$ critical          # What's urgent?
$ start medfit      # Begin work
```

### Deep Work Session
```bash
$ @medfit
$ focus 90          # 90-min focus mode
# ... work ...
$ done              # Update status
```

### R Package Development
```bash
$ rpkg medfit       # Smart jump
$ rcycle            # Full dev cycle
$ qpush "Implement fit_mediation"
$ done
```

### After Interruption
```bash
$ where             # Where am I?
$ next              # What was I doing?
$ recent            # What files was I editing?
```

### Priority Check
```bash
$ critical          # All 🔴 items
$ active            # All 🟢 projects
$ rpkgs             # R package status
```

### Teaching Day
```bash
$ teach             # Jump + show what's due
$ grade             # Start grading session
```

### End of Day
```bash
$ critical          # Check blockers
$ done              # Update all statuses
$ unfocus           # Restore notifications
```

---

## 🎯 TOP 10 FOR ADHD

**Learn these first:**

1. **here** - Context reconstruction
2. **next** - Quick next action
3. **start** - Begin work session
4. **done** - End session
5. **morning** - Daily start
6. **rcycle** - R dev cycle
7. **focus** - Minimize distractions
8. **qpush** - Git in one step
9. **critical** - Priority triage
10. **recent** - Recent files

---

## 📊 FUNCTION COUNT

| Category | Functions | Most Used |
|----------|-----------|-----------|
| Context | 3 | here, next |
| Session | 3 | start, done, pomo |
| R Packages | 4 | rcycle, rpkg |
| Teaching | 2 | teach, grade |
| Focus | 3 | focus, unfocus |
| Git | 3 | qcommit, qpush |
| Search | 2 | recent, fp |
| Status | 2 | critical, active |
| **TOTAL** | **21** | |

---

**See also:** help, helpnav, helpspc, helpr
