# Dashboard UX Improvements - ADHD-Friendly Design

**Date:** 2025-12-25
**Version:** v3.1.0 Planning
**Status:** Design Complete, Ready for Implementation
**Philosophy:** Reduce decision fatigue, increase dopamine, celebrate progress

---

## 🎯 Executive Summary

**Problem:** Current dashboard is functional but doesn't optimize for ADHD challenges:

- Decision paralysis (what should I work on?)
- Missing dopamine triggers (quick wins, celebrations)
- Hard to scan visually (small progress bars, truncated text)
- No urgency awareness (what's blocking, what's due?)

**Solution:** Apply ADHD-friendly design principles to make dashboard:

- Action-oriented ("Just tell me what to do")
- Visually scannable (bigger bars, clear hierarchy)
- Dopamine-optimized (wins, streaks, quick wins)
- Urgency-aware (deadlines, blockers)

---

## 📊 Current Dashboard Analysis

### ✅ Strengths

1. Progressive disclosure (summary → drill-down)
2. Visual hierarchy with icons
3. Color-coded status
4. Quick access to top projects
5. Category grouping

### ⚠️ Issues

1. **No clear next action** → Analysis paralysis
2. **Progress bars too small** → Hard to scan (5-char: ███░░)
3. **Text truncation** → Cuts off at 30 chars
4. **No urgency signals** → Can't see what needs attention
5. **Today stats buried** → Should be prominent
6. **Missing dopamine** → No celebration/quick wins
7. **Footer too complex** → Too many options

---

## 🏆 Design Principles

### 1. Anti-Paralysis Design

**Principle:** Remove decision fatigue by suggesting next action
**Implementation:** "RIGHT NOW" section at top with smart suggestion

### 2. Dopamine Architecture

**Principle:** Celebrate progress to maintain motivation
**Implementation:** Quick wins, recent accomplishments, streaks

### 3. Visual Hierarchy

**Principle:** Most important info dominates visually
**Implementation:** Active session uses different borders, bigger boxes

### 4. Scannable Design

**Principle:** Information density balanced with readability
**Implementation:** Bigger progress bars, full text (no truncation)

### 5. Urgency Awareness

**Principle:** Deadlines and blockers should be visible
**Implementation:** 🔥 urgent, ⏰ due, ⚡ quick win indicators

---

## 📋 Implementation Plan

### Phase 1: High Impact, Low Effort (2-3 hours)

**Priority 1.1: "RIGHT NOW" Section**

- Add smart suggestion at top (what to work on)
- Show today's stats prominently
- Display daily goal/streak
- Provide clear call-to-action

```
  ⚡ RIGHT NOW
  ╭────────────────────────────────────────────────────────────╮
  │  💡 SUGGESTION: Start 'work flow-cli'                       │
  │     Next action: Update README for v3.0.0 (30min)           │
  │                                                              │
  │  📊 TODAY: 0 sessions, 0m  •  🔥 0 day  •  🎯 Goal: 1 session│
  ╰────────────────────────────────────────────────────────────╯
```

**Priority 1.2: Bigger Progress Bars**

- Change from 5-char (███░░) to 10-char ([████████░░])
- Easier to scan at a glance
- More satisfying visual feedback

**Priority 1.3: Active Session Highlighting**

- Use different border style (┏━┓ vs ╭─╮)
- Add session timer with progress bar
- Show target time for time-boxing
- Display full focus text (no truncation)

```
  🎯 ACTIVE SESSION • 47m elapsed
  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
  ┃  🔧 flow-cli                                              ┃
  ┃  Focus: Update README for v3.0.0                          ┃
  ┃  Timer: [████████░░] 52% of 90m target                    ┃
  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛
```

**Priority 1.4: Simplified Footer**

- Reduce from 3 options to 1 context-aware suggestion
- Less decision fatigue

```
  💡 Try: 'work flow-cli' to start  •  'dash -i' for picker  •  'h' for help
```

**Time Estimate:** 2-3 hours
**Impact:** High (immediate usability improvement)

---

### Phase 2: Dopamine Features (2-3 hours)

**Priority 2.1: Quick Wins Section**

- Show tasks < 30min from .STATUS files
- Parse "quick:" or "time:" metadata
- Provides achievable goals

```
  ⚡ QUICK WINS (< 30min)
  ├─ ⚡ atlas: Review PR #42 (15m)
  ├─ ⚡ flow-cli: Update README (30m)
  └─ ⚡ mcp-servers: Fix typo in docs (10m)
```

**Priority 2.2: Recent Wins Display**

- Show last 3 accomplishments
- Parse from `win <text>` command log
- Positive reinforcement

```
  🎉 RECENT WINS
  └─ v3.0.0 architecture • Legacy code archived • 5 PRs merged
```

**Priority 2.3: Urgency Indicators**

- Parse deadline/urgency from .STATUS
- Visual indicators: 🔥 urgent, ⏰ due today, ⚡ quick win
- Sort by urgency in Quick Access

```
  📁 QUICK ACCESS (Active first, urgent at top)
  ├─ 🔥 🟢 atlas            [URGENT] Deploy v2.1.0 by EOD
  ├─ ⏰ 🟢 flow-cli         [DUE] README update (today)
  └─ ⚡ 🟢 mcp-servers       [QUICK] Fix typo (10m)
```

**Time Estimate:** 2-3 hours
**Impact:** High (motivation & prioritization)

---

### Phase 3: Polish & Advanced Features (3-4 hours)

**Priority 3.1: Session Timer**

- Show elapsed time with progress bar
- Configurable target duration
- Visual indication when hitting milestones

**Priority 3.2: Streak Visualization**

- Sparkline for last 7 days
- Celebrate milestones (7-day, 30-day)
- Recovery mode when streak breaks

**Priority 3.3: Daily Goals**

- Set daily session target
- Show progress toward goal
- Adaptive suggestions based on time of day

**Priority 3.4: Color Coding Enhancements**

- Red background for overdue
- Yellow for due today
- Blue for quick wins
- Green for on-track

**Time Estimate:** 3-4 hours
**Impact:** Medium (nice-to-have polish)

---

## 🎨 Design Mockups

### Full Improved Dashboard (All Phases)

```
╭──────────────────────────────────────────────────────────────╮
│  🌊 FLOW DASHBOARD                        Dec 25, 2025  20:09 │
╰──────────────────────────────────────────────────────────────╯

  ⚡ RIGHT NOW
  ╭────────────────────────────────────────────────────────────╮
  │  💡 SUGGESTION: Start 'work flow-cli'                       │
  │     Next action: Update README for v3.0.0 (30min)           │
  │                                                              │
  │  📊 TODAY: 0 sessions, 0m  •  🔥 0 day  •  🎯 Goal: 1 session│
  ╰────────────────────────────────────────────────────────────╯

  🎯 ACTIVE SESSION • 47m elapsed
  ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
  ┃  🔧 flow-cli                                              ┃
  ┃  Focus: Update README for v3.0.0                          ┃
  ┃  Timer: [████████░░] 52% of 90m target                    ┃
  ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

  ⚡ QUICK WINS (< 30min)
  ├─ ⚡ atlas: Review PR #42 (15m)
  ├─ ⚡ flow-cli: Update README (30m)
  └─ ⚡ mcp-servers: Fix typo in docs (10m)

  📁 TOP PROJECTS
  ├─ 🔥 🟢 atlas            [URGENT] Deploy v2.1.0 by EOD
  ├─ ⏰ 🟢 flow-cli         [DUE TODAY] README update
  ├─ 🟢 mcp-servers         Unified ecosystem
  └─ 🟢 data-wise.github.io Documentation site

  📋 BY CATEGORY (39 total)
  ├─ 📦 r-packages   [████████░░]  75%  •  6 active / 6
  ├─ 🔧 dev-tools    [███████░░░]  67%  •  4 active / 18
  ├─ 🔬 research     [████░░░░░░]  43%  •  0 active / 10
  └─ 🎓 teaching     [█████████░]  91%  •  0 active / 3

  🎉 RECENT WINS
  └─ v3.0.0 architecture • Legacy code archived • 5 PRs merged

  ─────────────────────────────────────────────────────────────
  📥 Inbox: 5 items  │  💡 'work flow-cli' to start  │  'h' for help
```

---

## 📂 .STATUS File Enhancements

To support new features, extend .STATUS format:

```yaml
## Status: active
## Progress: 75
## Focus: Update README for v3.0.0

## Urgency: high          # New: high|medium|low
## Deadline: 2025-12-25   # New: ISO date
## Estimate: 30           # New: minutes
## Tags: quick-win        # New: tags for filtering

## Next:
- Update installation guide
- Add v3.0.0 changelog
```

**Parsing Priority:**

1. `Urgency: high` → 🔥 icon
2. `Deadline: today` → ⏰ icon
3. `Estimate: <30` → ⚡ icon (quick win)
4. `Tags: quick-win` → ⚡ icon

---

## 🔧 Technical Implementation

### File Changes Required

**commands/dash.zsh:**

- Add `_dash_right_now()` function
- Modify `_dash_current()` for better highlighting
- Update `_dash_quick_access()` for urgency sorting
- Add `_dash_quick_wins()` function
- Add `_dash_recent_wins()` function
- Increase progress bar width (5 → 10 chars)

**lib/core.zsh:**

- Add `.STATUS` parser for new fields (urgency, deadline, estimate)
- Add urgency icon helper `_flow_urgency_icon()`
- Add time-until-deadline calculator

**Data Storage:**

- `$FLOW_DATA_DIR/wins.log` - Log of accomplishments
- `$FLOW_DATA_DIR/worklog` - Already exists, enhance format

---

## 🧪 Testing Strategy

### Manual Testing

1. **Phase 1:** Test with 0 sessions, 1 session, multiple sessions
2. **Phase 2:** Create .STATUS files with urgency/deadline
3. **Phase 3:** Test streak across multiple days

### Automated Testing

- Unit tests for new parser functions
- Integration tests for dashboard output
- Visual regression tests (capture output, compare)

---

## 📊 Success Metrics

**Phase 1 Success:**

- Dashboard is more scannable (subjective, user feedback)
- Active session immediately obvious
- Clear next action always visible

**Phase 2 Success:**

- Users report using "quick wins" feature
- Urgency indicators help prioritization
- Wins section provides motivation

**Phase 3 Success:**

- Session timer helps with time-boxing
- Streak feature increases consistency
- Goal tracking provides structure

---

## 🗓️ Timeline

### Option A: Sprint (1 week)

- **Day 1-2:** Phase 1 (high impact)
- **Day 3-4:** Phase 2 (dopamine)
- **Day 5:** Phase 3 (polish)

### Option B: Iterative (2-3 weeks)

- **Week 1:** Phase 1, ship, gather feedback
- **Week 2:** Phase 2 based on feedback
- **Week 3:** Phase 3 if needed

**Recommended:** Option B (iterative) for ADHD-friendly pacing

---

## 🎯 Definition of Done

**Phase 1 Complete When:**

- [ ] RIGHT NOW section shows smart suggestion
- [ ] Progress bars use 10 chars
- [ ] Active session uses ┏━┓ borders
- [ ] Footer simplified to 1 suggestion
- [ ] Manual testing passes all scenarios

**Phase 2 Complete When:**

- [ ] Quick wins section parses estimate from .STATUS
- [ ] Recent wins displays last 3 accomplishments
- [ ] Urgency indicators sort projects correctly
- [ ] All new features have tests

**Phase 3 Complete When:**

- [ ] Session timer shows progress bar
- [ ] Streak visualization works
- [ ] Daily goals configurable
- [ ] Color coding applied correctly

---

## 🔗 Related Documents

- `commands/dash.zsh` - Current implementation
- `lib/tui.zsh` - TUI helpers
- `lib/core.zsh` - Core utilities
- `.STATUS` - Project status format
- `docs/architecture/ADHD-DESIGN-PRINCIPLES.md` - Design philosophy

---

## 💡 Future Enhancements (Post v3.1.0)

**Not in scope but worth considering:**

- Heatmap visualization (productivity by day/hour)
- Project health score (activity, progress, blockers)
- AI suggestions based on patterns
- Mobile companion app
- Desktop widget/menubar

---

**Created:** 2025-12-25
**Status:** Design Complete
**Next Step:** Begin Phase 1 implementation
**Estimated Total Time:** 7-10 hours (all 3 phases)
