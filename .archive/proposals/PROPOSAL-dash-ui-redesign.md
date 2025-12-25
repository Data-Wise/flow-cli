# PROPOSAL: Dashboard UI Redesign

**Date:** 2025-12-25
**Status:** Draft for Review

---

## Current State Analysis

### Problems Identified

| Issue                     | Impact                | ADHD Impact         |
| ------------------------- | --------------------- | ------------------- |
| Flat list of 40+ projects | Cognitive overload    | Decision paralysis  |
| No grouping               | Hard to find projects | Scanning fatigue    |
| Truncated focus text      | Lost context          | Frustration         |
| No summary stats          | Missing big picture   | No dopamine         |
| All projects shown        | Too much info         | Overwhelm           |
| No visual hierarchy       | Everything looks same | Attention diffusion |

---

## Design Principles

1. **Progressive Disclosure** - Show summary first, details on demand
2. **Visual Hierarchy** - Important things stand out
3. **Grouping** - Related items together
4. **Quick Wins Visible** - Show actionable items prominently
5. **Dopamine Triggers** - Celebrate progress, show streaks

---

## Proposed Designs

### ⭐ Option A: Summary-First Dashboard

```
╭──────────────────────────────────────────────────────────────╮
│  🌊 FLOW DASHBOARD                              Dec 25, 2025 │
╰──────────────────────────────────────────────────────────────╯

  📊 TODAY                      🔥 STREAK: 7 days
  ├─ Sessions: 5                ├─ Flow rate: 85%
  └─ Focus time: 2h 15m         └─ Completion: 92%

  🎯 ACTIVE NOW
  ╭────────────────────────────────────────────────────────────╮
  │  📗 flow-cli                                               │
  │  Focus: Implementing tutorial command                      │
  │  ⏱  45 min elapsed                                        │
  ╰────────────────────────────────────────────────────────────╯

  📁 QUICK ACCESS (Recent)
  ├─ 🟢 atlas          Production ready
  ├─ 🟢 aiterm         PyPI preparation
  └─ 🟢 mediationverse Test coverage 85%

  📋 BY CATEGORY (43 total)
  ├─ 🔧 dev-tools     16 projects  │  5 active
  ├─ 📦 r-packages     6 projects  │  6 active
  ├─ 🔬 research      11 projects  │  4 active
  └─ 🎓 teaching       3 projects  │  3 active

  💡 Run 'dash dev' to expand a category
```

### ⭐ Option B: Card-Based Layout

```
╔══════════════════════════════════════════════════════════════╗
║  🌊 FLOW DASHBOARD                            🔥 7 day streak ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  ┌─ 🎯 CURRENT SESSION ─────────────────────────────────────┐║
║  │  📗 flow-cli                                             │║
║  │  ────────────────────────────────────────────────────────│║
║  │  Focus: Implementing tutorial command                    │║
║  │  Time: ⏱ 45m  │  Status: 🟢 Active  │  Progress: ████░ 80%│║
║  └──────────────────────────────────────────────────────────┘║
║                                                              ║
║  ┌─ 📥 INBOX (3 items) ───────┐  ┌─ 🏆 WINS TODAY ─────────┐║
║  │  • Review PR #42           │  │  ✓ Fixed atlas bug      │║
║  │  • Update docs             │  │  ✓ Tutorial complete    │║
║  │  • Call with team          │  │  ✓ Flow cmd shipped     │║
║  └────────────────────────────┘  └─────────────────────────┘║
║                                                              ║
║  ┌─ 🔧 DEV-TOOLS ────────────────────────────────────────────┐║
║  │  🟢 atlas        🟢 aiterm       ⚪ claude-mcp           │║
║  │  🟢 flow-cli     🟢 nexus        ⚪ rforge               │║
║  └──────────────────────────────────────────────────────────┘║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
```

### Option C: Minimal Focus Mode

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  FLOW DASHBOARD                    🔥 7 │ ⏱ 2h
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  → flow-cli (now)
    Implementing tutorial command

  ─────────────────────────────────────────────

  Recent:
    atlas • aiterm • nexus • mediationverse

  Next:
    [ ] Review PR #42
    [ ] Update rmediation docs
```

### ⭐ Option D: Grouped with Progress Bars

```
╭─────────────────────────────────────────────────────────────────╮
│  🌊 FLOW                                                        │
│                                                                 │
│  Today: ████████████████░░░░ 80%    Streak: 🔥 7 days          │
╰─────────────────────────────────────────────────────────────────╯

  🔧 DEV-TOOLS ──────────────────────────────────────── 16 projects
  │
  ├─ 🟢 flow-cli          ████████░░ 80%  Implementing tutorial
  ├─ 🟢 atlas             ██████████ 100% Production ready
  ├─ 🟢 aiterm            ██████░░░░ 60%  PyPI preparation
  ├─ ⚪ claude-mcp        ░░░░░░░░░░ --
  └─ + 12 more...

  📦 R-PACKAGES ─────────────────────────────────────── 6 projects
  │
  ├─ 🟢 mediationverse    ████████░░ 85%  Test coverage
  ├─ 🟢 rmediation        ██████████ 100% CRAN published
  └─ + 4 more...

  🔬 RESEARCH ───────────────────────────────────────── 11 projects
  │
  ├─ 🟢 collider          ██████░░░░ 60%  Under review
  └─ + 10 more...

  🎓 TEACHING ───────────────────────────────────────── 3 projects
  │
  └─ 🟢 stat-440          ████████░░ 80%  Final exam prep

  ─────────────────────────────────────────────────────────────────
  📥 Inbox: 3  │  🏆 Wins: 5  │  ⏱ Today: 2h 15m
```

---

## Feature Ideas

### Quick Wins (< 1 hour each)

1. ⭐ **Add summary header** - Session count, time, streak
2. ⭐ **Group by category** - Collapsible sections
3. **Show only active by default** - `dash -a` for all
4. **Progress bars** - Visual completion indicator
5. **Highlight current project** - Box around active session

### Medium Effort (1-2 hours)

6. ⭐ **Quick access row** - Last 5 used projects
7. **Inbox preview** - Show top 3 items
8. **Wins section** - Today's completed items
9. **Category counts** - "5 active / 16 total"
10. **Time tracking** - Show today's focus time

### Long-term (Future)

11. **Interactive mode** - Arrow keys to navigate
12. **Sparklines** - Activity trend mini-graphs
13. **Calendar heatmap** - GitHub-style contribution
14. **Custom layouts** - User-configurable sections

---

## Recommended Implementation

### Phase 1: Quick Wins

```zsh
# New default output structure:
dash() {
  _dash_header          # Summary stats, streak
  _dash_current         # Active session (if any)
  _dash_quick_access    # Last 5 projects
  _dash_categories      # Grouped, collapsed
  _dash_footer          # Tips, inbox count
}
```

### Phase 2: Category Expansion

```bash
dash              # Summary view (default)
dash dev          # Expand dev-tools category
dash -a           # Show all projects (flat list)
dash -f           # Full details (TUI if available)
```

### Phase 3: Customization

```bash
# In ~/.config/flow/config
DASH_SECTIONS="header,current,quick,categories"
DASH_QUICK_COUNT=5
DASH_COLLAPSED=true
```

---

## Color Palette

```
Header:     #87afff (blue)
Active:     #87d787 (green)
Warning:    #ffaf5f (orange)
Muted:      #6c6c6c (gray)
Accent:     #af87ff (purple)
Progress:   #5fafff (cyan)
```

---

## Comparison Matrix

| Feature         | Current | Option A | Option B | Option C | Option D |
| --------------- | ------- | -------- | -------- | -------- | -------- |
| Summary stats   | ❌      | ✅       | ✅       | ✅       | ✅       |
| Grouping        | ❌      | ✅       | ✅       | ❌       | ✅       |
| Progress bars   | ❌      | ❌       | ✅       | ❌       | ✅       |
| Collapsible     | ❌      | ✅       | ❌       | ❌       | ✅       |
| Current session | ❌      | ✅       | ✅       | ✅       | ✅       |
| Quick access    | ❌      | ✅       | ❌       | ✅       | ❌       |
| Minimal         | ❌      | ❌       | ❌       | ✅       | ❌       |
| ADHD-friendly   | ⚠️      | ✅       | ✅       | ✅       | ✅       |

---

## Recommendation

**Start with Option A** (Summary-First) because:

- ✅ Progressive disclosure reduces overwhelm
- ✅ Quick wins visible immediately
- ✅ Easy to implement incrementally
- ✅ Naturally supports `dash <category>` expansion
- ✅ Best ADHD-friendly balance

**Then add Option D features** (progress bars, visual grouping) as enhancement.

---

## Next Steps

1. [ ] Implement `_dash_header()` with summary stats
2. [ ] Add `_dash_current()` for active session
3. [ ] Create `_dash_categories()` with grouping
4. [ ] Support `dash <category>` expansion
5. [ ] Add progress bars (optional flag)
