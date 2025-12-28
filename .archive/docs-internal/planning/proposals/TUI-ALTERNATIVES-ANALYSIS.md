# TUI Alternatives Analysis

**Date:** 2025-12-23
**Decision:** Skip TUI implementation in favor of Hybrid (CLI + Web) approach

---

## Executive Summary

After comprehensive analysis of TUI (Terminal User Interface) libraries and their trade-offs, we've decided to **skip TUI implementation** and instead implement a **Hybrid (CLI + Web) Dashboard** system.

**Key Reasons:**

1. TUI cons outweigh benefits for our use case
2. ADHD-unfriendly (information overload, constant visual stimulation)
3. Hybrid approach provides better flexibility and user choice
4. No breaking changes to existing CLI workflows

---

## TUI Cons Analysis

### 1. Terminal Compatibility Issues

**Problem:** TUI libraries struggle with terminal diversity

- **blessed:** Works best on Linux, issues on macOS Terminal.app, broken on Windows
- **ink:** Better cross-platform but limited to React-style components
- **terminal-kit:** Most compatible but largest dependency footprint

**Real-World Impact:**

- Users with iTerm2 + tmux might see rendering glitches
- Emoji support varies wildly across terminals
- Box-drawing characters break on some fonts
- Color schemes don't respect terminal themes

**Evidence:**

```
┌─────────┐  vs  +---------+  vs  ?---------?
│ Content │      | Content |      ? Content ?
└─────────┘      +---------+      ?---------?
  (Good)           (OK)            (Broken)
```

### 2. ADHD Concerns

**Problem:** Constant visual updates can be overwhelming

- **Always-on display** = cognitive load even when idle
- **Blinking cursors** and animations trigger distractibility
- **Information density** makes it hard to focus on what matters
- **Context switching** between TUI and work is jarring

**Better Alternative:** On-demand status checks (current CLI) or ambient monitoring (web dashboard)

### 3. Performance Overhead

**Problem:** TUI frameworks add significant runtime cost

- **blessed:** 500KB+ bundle, heavy CPU for rendering
- **ink:** React reconciliation overhead for every update
- **terminal-kit:** Continuous terminal polling

**Impact:**

- CLI startup time: 50ms → 200ms+
- Memory usage: 30MB → 80MB+
- Battery drain on laptops (continuous redraws)

### 4. Maintenance Burden

**Problem:** TUI libraries have spotty maintenance

- **blessed:** Last major update 3+ years ago, open issues pile up
- **ink:** Active but React dependency churn
- **terminal-kit:** Solo maintainer, slow updates

**Risk:** Breaking changes in terminal emulators could render dashboard unusable

### 5. Testing Complexity

**Problem:** Hard to test visual terminal output

- No headless testing for TUI interactions
- Screenshot comparisons are brittle
- Mocking terminal capabilities is painful
- E2E tests require pty/pseudo-terminal setup

**Current CLI:** Easy to test (check stdout text, exit codes)

---

## Alternatives Considered

### Top 3 Recommendations

#### 1. 🏆 Hybrid (CLI + Web Dashboard) - **SELECTED**

**Why It's Best:**

- ✅ No breaking changes (CLI still works)
- ✅ Users choose complexity level based on need
- ✅ Web dashboard = modern, rich, well-tested tech
- ✅ ADHD-friendly (can disable when overwhelming)
- ✅ Scriptable CLI + rich monitoring coexist

**Implementation:**

```bash
flow status        # Default: fast CLI output
flow status --web  # Optional: rich web dashboard
```

**Tech Stack:**

- Express + WebSocket for server
- Single HTML file with Chart.js
- Real-time updates via WebSocket
- Auto-open browser with `open` package

**Effort:** 2-3 hours total

**See:** IMPLEMENTATION-PLAN-ABC.md (Day 8-9)

---

#### 2. Enhanced CLI with ASCII Charts

**Why It's Good:**

- ✅ Zero dependencies beyond current setup
- ✅ Works everywhere (even SSH)
- ✅ Fast, lightweight, scriptable
- ✅ ADHD-friendly (minimal visual noise)

**Example Output:**

```
✅ Active Session (45 min) 🔥 IN FLOW

Session Trend: ▁▂▃▅▇█▇▅▃▂▁ (last 10 days)
Progress: [████████████░░░░░░░░] 60%

Recent Sessions:
  rmediation       ████████████░ 45m  (active)
  quarto-doc       ███░░░░░░░░░░ 20m  (complete)
```

**Effort:** 1 hour

**Trade-off:** Limited data visualization vs TUI/Web

---

#### 3. Notifications for Ambient Awareness

**Why It's Good:**

- ✅ Non-intrusive, ambient awareness
- ✅ ADHD-friendly (gentle nudges vs constant display)
- ✅ Cross-platform (macOS, Linux, Windows)
- ✅ Works alongside any other solution

**Use Cases:**

- Session hits 15 min (flow state achieved)
- Session hits 90 min (suggest break)
- Project status changes (draft → under review)

**Tech:** `node-notifier` package

**Effort:** 30 minutes

---

## Alternatives Rejected

### TUI with blessed/ink

**Reason:** Cons outweigh benefits (see above)

### Desktop App (Electron/Tauri)

**Reason:** Overkill, high maintenance, Electron footprint too large

### Status File + File Watcher

**Reason:** No real-time updates, polling overhead, limited interactivity

### System Tray / Menu Bar App

**Reason:** Platform-specific, macOS only (no Linux/Windows parity)

### IDE Extensions

**Reason:** Fragments user base, need to support VS Code/Vim/Emacs/Spacemacs/etc.

### Mobile App

**Reason:** Massive scope increase, not aligned with CLI-first philosophy

### Voice Interface

**Reason:** Fun idea but not practical for developer workflows

---

## Decision Matrix

| Criteria           | Hybrid (CLI+Web) | Enhanced CLI   | TUI                    | Desktop App         |
| ------------------ | ---------------- | -------------- | ---------------------- | ------------------- |
| **ADHD-Friendly**  | ✅ (Choice)      | ✅ (Minimal)   | ❌ (Overload)          | ⚠️ (Context switch) |
| **Effort**         | ⚠️ (2-3h)        | ✅ (1h)        | ❌ (8h+)               | ❌ (40h+)           |
| **Maintenance**    | ✅ (Stable tech) | ✅ (Zero deps) | ❌ (TUI library churn) | ❌ (Electron churn) |
| **Cross-Platform** | ✅ (Browser)     | ✅ (Terminal)  | ❌ (Varies)            | ⚠️ (Build matrix)   |
| **Scriptable**     | ✅ (CLI mode)    | ✅ (Pure CLI)  | ❌ (Interactive only)  | ❌ (GUI only)       |
| **Rich Graphics**  | ✅ (Chart.js)    | ⚠️ (ASCII)     | ⚠️ (Limited)           | ✅ (Full GUI)       |
| **Real-Time**      | ✅ (WebSocket)   | ❌ (Poll)      | ✅ (Built-in)          | ✅ (Built-in)       |
| **Testing**        | ✅ (Web tests)   | ✅ (Stdout)    | ❌ (Hard)              | ❌ (E2E)            |

**Winner:** Hybrid (CLI + Web)

---

## Implementation Plan

See: `IMPLEMENTATION-PLAN-ABC.md` (Day 8-9: Hybrid Dashboard)

**Summary:**

### Phase 1: Web Dashboard Foundation (1.5 hours)

- Express server + WebSocket
- Single-file HTML dashboard
- Integration in StatusController with `--web` flag

### Phase 2: Rich Visualizations (1 hour)

- Chart.js for session trends, project distribution
- Real-time updates via WebSocket
- Smooth animations

### Phase 3: Enhanced CLI (30 min)

- ASCII sparklines for trends
- Progress bars for completion
- Color-coded metrics

---

## Benefits Summary

**For Users:**

- ✅ Choose your own complexity (CLI or Web)
- ✅ No learning curve (CLI still works the same)
- ✅ ADHD-friendly flexibility
- ✅ Best tool for the job (CLI for quick checks, Web for deep dives)

**For Developers:**

- ✅ Smaller dependency footprint vs TUI
- ✅ Modern, well-tested web tech
- ✅ Easy to maintain and test
- ✅ Clear separation of concerns (CLI vs Web)

**For Project:**

- ✅ Aligns with CLI-first philosophy
- ✅ Completes P6 goals without technical debt
- ✅ Opens door to future enhancements (mobile view, embeddable widgets)

---

## Conclusion

The Hybrid (CLI + Web) approach provides the best balance of:

- **Flexibility** (users choose their experience)
- **Maintainability** (stable tech stack)
- **ADHD-Friendly Design** (control over stimulation)
- **Rich Functionality** (web dashboard when needed)
- **Zero Breaking Changes** (CLI still works)

We're skipping TUI entirely and proceeding with hybrid implementation.

---

**Next Steps:**

1. ✅ Update IMPLEMENTATION-PLAN-ABC.md with hybrid approach
2. ✅ Document decision in TUI-ALTERNATIVES-ANALYSIS.md
3. ⏭️ Start implementing web dashboard (Day 8-9)

**References:**

- docs/planning/proposals/TUI-DASHBOARD-OPTIONS.md (original TUI analysis)
- IMPLEMENTATION-PLAN-ABC.md (updated with hybrid approach)
