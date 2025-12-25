# Flow Command Integration Analysis

**Date:** 2025-12-24
**Status:** Analysis Complete - Awaiting Decision

## TL;DR

You have **two workflow systems** with overlapping functionality:

```
┌──────────────────────────────────────────────────┐
│ CURRENT STATE: Dual Workflow Systems            │
├──────────────────────────────────────────────────┤
│                                                  │
│  ZSH Functions          Node.js CLI              │
│  ──────────────         ───────────              │
│                                                  │
│  work → session mgmt    flow status → ASCII UI  │
│  finish → git commit    flow dashboard → TUI    │
│  dash → text list       flow status --web → Web │
│  status → .STATUS mgmt                           │
│                                                  │
│  Speed: ⚡ <10ms         Speed: 🐌 ~100ms        │
│  UI: Text only          UI: Rich visualizations  │
│                                                  │
└──────────────────────────────────────────────────┘
```

**Recommendation:** Keep both, clarify roles (see Option A below)

---

## Key Findings

### 1. No Naming Conflict (Yet)

✅ Your `flow` CLI is installed globally at `/opt/homebrew/bin/flow`
✅ Facebook Flow (JS type checker) is NOT installed
⚠️ Potential future conflict if you need both

### 2. Functional Overlap

| Task           | ZSH Command     | Node.js Command         | Winner             |
| -------------- | --------------- | ----------------------- | ------------------ |
| Start work     | `work <proj>`   | `flow work` (planned)   | ZSH (instant)      |
| End work       | `finish [msg]`  | `flow finish` (planned) | ZSH (instant)      |
| View dashboard | `dash`          | `flow dashboard`        | Node (richer)      |
| Session status | N/A             | `flow status`           | Node (only option) |
| Update .STATUS | `status <proj>` | N/A                     | ZSH (only option)  |

### 3. Performance Gap

```
Benchmark: Session start time
──────────────────────────────
ZSH 'work':     ████ 8ms
Node 'flow':    ████████████████████ 120ms

For ADHD workflow: Speed wins
```

---

## Integration Options (Summary)

### Option A: ZSH-First ⭐ **RECOMMENDED**

**Strategy:** Native ZSH for speed, Node.js for rich features

**User Experience:**

```bash
# Daily workflow (instant)
work my-project         # < 10ms
finish "Added feature"  # < 50ms
plist                   # Quick text view

# When you want rich UI
flow dashboard          # Live TUI
flow status --web       # Browser view
flow status -v          # Verbose CLI
```

**Pros:**

- ✅ ADHD-friendly (zero latency)
- ✅ Clear separation of concerns
- ✅ Backwards compatible
- ✅ Low effort to implement

**Cons:**

- ⚠️ Two systems to maintain
- ⚠️ User needs to learn both

**Effort:** 🟢 **1-2 hours** (just docs + minor rename)

---

### Option B: Node.js-First

**Strategy:** Everything through `flow` CLI

**User Experience:**

```bash
flow work my-project
flow finish "Added feature"
flow dashboard
flow status --web
```

**Pros:**

- ✅ Single command to learn
- ✅ Consistent interface
- ✅ Portable (works in bash, fish)

**Cons:**

- ❌ 100ms latency on every command
- ❌ Breaks ADHD workflow
- ❌ High migration effort

**Effort:** 🔴 **20+ hours** (rewrite commands in Node.js)

---

### Option C: Hybrid Bridge

**Strategy:** ZSH delegates to Node.js for UI features

**User Experience:**

```bash
# Fast commands (ZSH)
work my-project
finish "Done"

# Same commands, rich UI
dash --tui      # Calls: flow dashboard
dash --web      # Calls: flow status --web
```

**Pros:**

- ✅ Fast + Rich features
- ✅ Backwards compatible
- ✅ Single command namespace

**Cons:**

- ⚠️ Complex implementation
- ⚠️ Two systems to maintain

**Effort:** 🟡 **6-8 hours** (bridge ZSH → Node.js)

---

### Option D: Rename CLI

**Strategy:** `flow` → `workview` (or similar)

**User Experience:**

```bash
# ZSH (unchanged)
work my-project
finish "Done"
dash

# Node.js (renamed)
workview dashboard
workview status --web
```

**Pros:**

- ✅ No namespace conflict
- ✅ Future-proof (won't clash with FB Flow)
- ✅ Clear purpose

**Cons:**

- ❌ Rebranding effort
- ❌ Breaking change
- ❌ All docs need update

**Effort:** 🔴 **10-12 hours** (rename everything)

---

## Decision Matrix

| Criteria             | A: ZSH-First | B: Node-First | C: Hybrid  | D: Rename  |
| -------------------- | ------------ | ------------- | ---------- | ---------- |
| **Speed**            | ⚡⚡⚡⚡⚡   | ⚡            | ⚡⚡⚡⚡⚡ | ⚡⚡⚡⚡⚡ |
| **ADHD-friendly**    | ✅           | ❌            | ✅         | ✅         |
| **Rich features**    | ✅           | ✅            | ✅         | ✅         |
| **Simplicity**       | ✅           | ✅            | ❌         | ✅         |
| **Effort**           | 🟢 Low       | 🔴 High       | 🟡 Med     | 🔴 High    |
| **Backwards compat** | ✅           | ⚠️            | ✅         | ✅         |
| **Risk**             | 🟢           | 🔴            | 🟡         | 🟡         |

**Winner:** Option A (ZSH-First)

---

## Recommended Action Plan

### Phase 1: Document Current State (30 min)

Update README.md with clear roles:

```markdown
## Fast Commands (ADHD-optimized)

Use these for daily workflow (< 10ms response):

- `work <project>` - Start working
- `finish [msg]` - Commit and end session
- `plist` - Quick project overview (text)

## Power Features

Use when you want rich visualizations:

- `flow dashboard` - Interactive TUI with live updates
- `flow status --web` - Web-based dashboard
- `flow status -v` - Detailed ASCII progress bars
```

### Phase 2: Clarify Help Text (30 min)

**In `flow --help`:**

```
💡 For instant commands, use native ZSH:
   work, finish, plist

   Flow CLI provides rich visualizations when you need them.
```

**In `plist` (formerly `dash`):**

```
💡 Want a live dashboard? Try: flow dashboard
```

### Phase 3: Optional Integration (4 hours)

Add delegation flags to ZSH commands:

```bash
# ~/.config/zsh/functions/dash.zsh
dash() {
    case "$1" in
        --tui)
            flow dashboard
            ;;
        --web)
            flow status --web
            ;;
        *)
            # ... existing basic text view ...
            ;;
    esac
}
```

**Total Time:** ~5 hours

---

## Key Insights

### 1. Speed Matters for ADHD

```
Context Switch Cost
───────────────────
Command latency:   100ms = ADHD disruption
                    10ms = Seamless flow

Recommendation: Keep fast commands in ZSH
```

### 2. Rich Features Have a Place

When **actively monitoring** (not context switching):

- `flow dashboard` - Live TUI is valuable
- `flow status --web` - Good for overview
- `flow status -v` - Pretty when you have time

### 3. Two Systems = OK (If Clear Roles)

**Mental model:**

```
ZSH = Fast daily workflow (muscle memory)
flow = Rich views when you want detail
```

This is **complementary**, not competing.

---

## Usage Patterns (Hypothetical)

### Daily Workflow

```bash
8:00 AM  - work flow-cli          # Start session (ZSH, instant)
10:30 AM - flow dashboard          # Check all projects (Node, rich)
12:00 PM - finish "Morning work"   # Commit + end (ZSH, instant)

2:00 PM  - work research/collider  # Afternoon session (ZSH)
4:30 PM  - flow status --web       # Weekly review (Node, browser)
5:00 PM  - finish "Analysis done"  # Done (ZSH)
```

**Pattern:** Fast commands = state changes, Rich commands = viewing

---

## Future Considerations

### If Facebook Flow Needed

```bash
# Rename your CLI
npm uninstall -g @flowcli/core
npm install -g @workview/core

# Install FB Flow
brew install flow

# Now both work
flow           # FB Flow (type checker)
workview       # Your workflow dashboard
```

### If Performance Improves

If Node.js startup drops to <20ms (unlikely):

- Reconsider Option B (Node-First)
- Consolidate to single system

### If More Features Needed

Future `flow` commands:

- `flow work <proj>` - If ZSH version gets too complex
- `flow finish` - If git integration needs rich UI
- `flow ai` - AI-powered suggestions

---

## Conclusion

**Recommendation:** **Option A (ZSH-First)** with documentation updates

**Rationale:**

1. Preserves ADHD-friendly workflow (instant response)
2. Keeps rich features available (best of both)
3. Low effort, low risk implementation
4. Clear mental model for users

**Action:** Review proposal, implement documentation changes, ship it!

---

## Next Steps

1. ✅ **Review this analysis** (you are here)
2. ⬜ **Choose option** (A recommended)
3. ⬜ **Update docs** (~1 hour)
4. ⬜ **Optional: Add bridge** (~4 hours)
5. ⬜ **Ship & monitor usage**

**Decision deadline:** End of week
**Implementation:** 1 day
**Ship date:** This week

---

See full proposal: `PROPOSAL-flow-command-integration.md`
