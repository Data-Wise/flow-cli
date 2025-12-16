# Workflow Analysis & Optimization Proposals

**Date:** 2025-12-14
**Context:** Post-Phase 1 help system overhaul
**Focus:** ADHD-friendly project management and coordination

---

## 🔍 Current State Analysis

### Existing Workflows Tested

**Smart Functions (Enhanced Phase 1):** ✅
- `r help`, `cc help`, `qu help`, `gm help` - All working
- `focus help`, `note help`, `obs help`, `workflow help` - All working
- Colors, examples, visual hierarchy - Perfect
- **ADHD Score:** 9/10 (excellent)

**ADHD Helpers:** ✅
- `js` (just-start) - Working, but limited to R packages only
- `why` - Context recovery working
- `win` / `wins` - Dopamine tracking working
- **ADHD Score:** 7/10 (good but incomplete)

**Work Command:** ✅
- `work <project>` - Multi-editor routing working
- Auto-detection of project type working
- **ADHD Score:** 8/10 (great but underutilized)

### What's Missing or Confusing

**❌ CRITICAL GAPS:**

1. **No Unified Dashboard**
   - Multiple `.STATUS` files across projects
   - No single view of all active work
   - Can't see priorities at a glance
   - **Confusion:** "Where am I? What should I work on?"

2. **Inconsistent .STATUS Format**
   - Some projects have `.STATUS`, some don't
   - Different formats across projects
   - No standard way to update status
   - **Confusion:** "How do I create/update status?"

3. **No Cross-Project Coordination**
   - Teaching projects isolated from research
   - Dev-tools isolated from packages
   - **Confusion:** "How do I see everything?"

4. **Multiple Obsolete Commands**
   - `dash` exists but what does it show?
   - `rst` (research dashboard) - doesn't exist
   - `tst` (teaching dashboard) - doesn't exist
   - **Confusion:** "Which command do I use?"

5. **No Status Update Command**
   - Manually edit `.STATUS` files
   - No template or helper
   - **Confusion:** "What fields should .STATUS have?"

---

## 💡 SMART PROPOSALS

### Option A: Master Dashboard Command (Recommended)

**Command:** `dash` (overhaul existing or create new)

**What it shows:**
```
╭─────────────────────────────────────────────╮
│ 🎯 YOUR WORK DASHBOARD                      │
╰─────────────────────────────────────────────╯

🔥 ACTIVE NOW (3):
  📦 mediationverse    [P0] Simulation running
  📚 stat-440          [P1] Grade assignment 3
  🔧 zsh-configuration [P2] Help Phase 2 ready

📋 READY TO START (5):
  📦 medfit            [P1] Add vignette
  📊 product-of-three  [P1] Review simulations
  ...

⏸️  PAUSED (2):
  📊 sensitivity       [BLOCKED] Waiting on theory
  📦 probmed           [REVIEW] Under peer review

────────────────────────────────────────────────

💡 Quick actions:
  work <name>         Start working
  status <name>       Update status
  dash --detail       Show full details
  dash teaching       Filter by category
```

**ADHD Benefits:**
- ✅ One command to see everything
- ✅ Visual hierarchy (active → ready → paused)
- ✅ Color-coded priorities
- ✅ Quick actions visible
- ✅ <5 second scan time

**Implementation:**
- Scans all `.STATUS` files across ~/projects
- Parses status, priority, progress
- Groups by active/ready/paused
- Shows most recent first

---

### Option B: Smart Status Command

**Command:** `status` (new)

**Update status:**
```bash
# Interactive mode
status mediationverse
> What's the status? (active/paused/blocked/complete)
> active
> Priority? (P0/P1/P2)
> P0
> What are you working on?
> Running final simulations
> Progress? (0-100)
> 85

✅ Updated mediationverse/.STATUS
```

**Quick mode:**
```bash
status mediationverse active P0 "Running simulations" 85
```

**Show status:**
```bash
status mediationverse --show
# Shows current .STATUS contents
```

**Create from template:**
```bash
status newproject --create
# Creates .STATUS from template
```

**ADHD Benefits:**
- ✅ No manual file editing
- ✅ Consistent format guaranteed
- ✅ Quick updates (one command)
- ✅ Clear prompts (no decisions paralysis)

---

### Option C: Context-Aware `js` (Just Start)

**Enhancement:** Make `js` work across ALL project types

**Current:** Only checks R packages
**Proposed:** Check teaching, research, dev-tools too

```bash
js
🎲 Finding your next task...

┌─────────────────────────────────────────────┐
│ 🎯 DECISION MADE FOR YOU                    │
├─────────────────────────────────────────────┤
│ Project: stat-440                           │
│ Type:    Teaching (Quarto course)           │
│ Reason:  P0 - Assignment due tomorrow       │
│ Next:    Grade assignment 3                 │
└─────────────────────────────────────────────┘

💡 Quick start: work stat-440
```

**Logic:**
1. Check P0 priorities across ALL projects
2. Check due dates (teaching)
3. Check most recent activity
4. Make decision and show clear next action

**ADHD Benefits:**
- ✅ Zero decision making
- ✅ Context-aware (knows teaching deadlines)
- ✅ Works across all project types
- ✅ Clear next action

---

### Option D: Unified .STATUS Format

**Standard fields:**
```yaml
project: mediationverse
type: r-package
status: active
priority: P0
progress: 85
next: Run final simulations
updated: 2025-12-14
category: r-packages
tags: [mediation, simulation, cran]
```

**Template command:**
```bash
status --template > .STATUS
```

**Benefits:**
- ✅ Machine-readable
- ✅ Consistent across projects
- ✅ Easy to parse for dashboard
- ✅ Clear what fields to include

---

### Option E: Category Dashboards

**Commands:**
- `dash teaching` - Teaching projects only
- `dash research` - Research projects only
- `dash packages` - R packages only
- `dash dev` - Dev tools only

**Example:**
```bash
dash teaching

╭─────────────────────────────────────────────╮
│ 📚 TEACHING DASHBOARD                       │
╰─────────────────────────────────────────────╯

STAT 440 (Regression Analysis):
  ✅ Lecture 12 delivered
  📋 Assignment 3 grading (due tomorrow)
  📅 Lecture 13 prep (due Dec 16)

STAT 579 (Causal Inference):
  ✅ All lectures current
  📋 Final project reviews (due Dec 18)

💡 Next: work stat-440
```

**ADHD Benefits:**
- ✅ Focused view (less overwhelming)
- ✅ Context switching support
- ✅ Clear priorities per category

---

## 🎯 RECOMMENDED IMPLEMENTATION PLAN

### Phase 1: Dashboard Foundation (2-3 hours)

**Tasks:**
1. Create `dash` command (master dashboard)
2. Scan all `.STATUS` files
3. Parse and categorize (active/ready/paused)
4. Display with colors and priorities
5. Add category filters (teaching/research/packages)

**Files to create:**
- `~/.config/zsh/functions/dash.zsh`
- Helper: `_parse_status_files()`
- Helper: `_categorize_projects()`

**Test:**
```bash
dash                 # Show all
dash teaching        # Teaching only
dash --detail        # Full details
```

---

### Phase 2: Status Management (1-2 hours)

**Tasks:**
1. Create `status` command
2. Interactive mode for updates
3. Quick mode for fast updates
4. Template creation
5. Show current status

**Files to create:**
- `~/.config/zsh/functions/status.zsh`
- Template: `~/.config/zsh/templates/STATUS.template`

**Test:**
```bash
status mediationverse              # Interactive
status medfit active P1 "Docs" 60  # Quick
status newproject --create         # Template
status mediationverse --show       # Display
```

---

### Phase 3: Enhanced Just-Start (30 min)

**Tasks:**
1. Update `js` to scan all project types
2. Check priorities across teaching/research/packages
3. Consider due dates
4. Show clear next action

**Files to modify:**
- `~/.config/zsh/functions/adhd-helpers.zsh`
- Update `just-start()` function

**Test:**
```bash
js    # Should find P0 regardless of project type
```

---

### Phase 4: Unified .STATUS Format (1 hour)

**Tasks:**
1. Create standard .STATUS template
2. Migration tool for existing .STATUS files
3. Documentation

**Files to create:**
- `~/.config/zsh/templates/STATUS.template`
- `migrate-status.sh` (convert old to new format)

**Test:**
- Create new .STATUS files with standard format
- Migrate existing ones
- Verify dashboard parses correctly

---

## 📊 COMPARISON MATRIX

| Feature | Current | Option A | Option B | Option C | Option D | Option E |
|---------|---------|----------|----------|----------|----------|----------|
| **Unified Dashboard** | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ |
| **Status Updates** | Manual | ❌ | ✅ | ❌ | ✅ | ❌ |
| **Cross-Project** | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **ADHD-Friendly** | 6/10 | 9/10 | 8/10 | 9/10 | 7/10 | 8/10 |
| **Effort (hours)** | - | 2-3 | 1-2 | 0.5 | 1 | 1 |
| **Value** | - | High | High | High | Medium | Medium |

**Recommended:** Implement A + B + C (total: 4-5 hours)

---

## 🎨 ADHD OPTIMIZATION CHECKLIST

**Dashboard (Option A):**
- ✅ Single command (`dash`)
- ✅ Visual hierarchy (active → ready → paused)
- ✅ Color-coded priorities
- ✅ <5 second scan time
- ✅ Quick actions visible
- ✅ Category filters available

**Status Updates (Option B):**
- ✅ No manual file editing
- ✅ Interactive mode (guided)
- ✅ Quick mode (for speed)
- ✅ Consistent format guaranteed
- ✅ Clear prompts

**Just-Start (Option C):**
- ✅ Zero decisions required
- ✅ Context-aware
- ✅ Works across all projects
- ✅ Clear next action shown

---

## 🚀 QUICK WIN: Minimal Dashboard (30 min)

**For immediate relief:**

```bash
# ~/.config/zsh/functions/dash.zsh
dash() {
    echo "╭─────────────────────────────────────────────╮"
    echo "│ 🎯 YOUR WORK DASHBOARD                      │"
    echo "╰─────────────────────────────────────────────╯"
    echo ""

    echo "🔥 ACTIVE PROJECTS:"
    for status in ~/projects/**/\.STATUS; do
        if grep -q "active" "$status" 2>/dev/null; then
            local dir=$(dirname "$status")
            local name=$(basename "$dir")
            local priority=$(grep "priority:" "$status" | cut -d: -f2 | tr -d ' ')
            local next=$(grep "next:" "$status" | cut -d: -f2-)
            echo "  📦 $name [$priority] $next"
        fi
    done

    echo ""
    echo "💡 Quick: work <name> to start"
}
```

**Test:**
```bash
dash
# Shows all active projects with priorities
```

**Benefit:** Immediate visibility in 30 minutes

---

## 📝 NEXT STEPS

**Immediate (30 min):**
1. Implement minimal `dash` command (quick win above)
2. Test with existing .STATUS files
3. Get immediate overview of active work

**Phase 1 (2-3 hours):**
1. Full dashboard implementation (Option A)
2. Category filters
3. Priority sorting

**Phase 2 (1-2 hours):**
1. Status command (Option B)
2. Interactive and quick modes
3. Template creation

**Phase 3 (30 min):**
1. Enhanced `js` (Option C)
2. Cross-project awareness

**Phase 4 (1 hour):**
1. Unified .STATUS format (Option D)
2. Migration tool

**Total Estimated Effort:** 5-7 hours across 4 phases
**Value:** High - Solves major coordination confusion
**ADHD Impact:** Dramatic improvement in project visibility

---

## ✅ SUCCESS CRITERIA

**After implementation, you should be able to:**

1. ✅ See all active work in one command (`dash`)
2. ✅ Update status without editing files (`status project active P0 "Task" 85`)
3. ✅ Get started without deciding (`js`)
4. ✅ Filter by category (`dash teaching`)
5. ✅ Create new projects with proper .STATUS (`status newproject --create`)
6. ✅ No confusion about what to work on
7. ✅ No manual file editing
8. ✅ Consistent format across all projects

---

**Status:** 🎯 Ready to implement
**Recommendation:** Start with minimal `dash` (30 min quick win)
**Full Implementation:** Options A + B + C (4-5 hours total)
