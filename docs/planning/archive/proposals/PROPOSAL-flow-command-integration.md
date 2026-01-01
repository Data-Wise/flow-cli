# Flow Command Integration Analysis & Proposal

**Generated:** 2025-12-24
**Context:** Analyzing overlap between `flow` CLI and existing ZSH workflow commands
**Status:** Proposal for review

## 🎯 Executive Summary

The `flow` command has a **naming conflict** with Facebook's Flow (JavaScript type checker), but you've already resolved this by globally installing your flow-cli. However, there's **functional overlap** between the Node.js `flow` CLI and native ZSH workflow commands that needs strategic resolution.

**Key Insight:** You have TWO parallel workflow systems:

1. **Native ZSH functions** - Fast, direct shell integration (`work`, `finish`, `dash`, `status`)
2. **Node.js CLI** - Rich features, visualizations, web dashboard (`flow status`, `flow dashboard`)

---

## 📊 Current State Analysis

### Installed Commands

| Command  | Type         | Location                                   | Purpose                   |
| -------- | ------------ | ------------------------------------------ | ------------------------- |
| `flow`   | Node.js CLI  | `/opt/homebrew/bin/flow` → `@flowcli/core` | Enhanced status/dashboard |
| `work`   | ZSH function | `~/.config/zsh/functions/work.zsh`         | Start work session        |
| `finish` | ZSH function | `~/.config/zsh/functions/adhd-helpers.zsh` | End session + commit      |
| `dash`   | ZSH function | `~/.config/zsh/functions/dash.zsh`         | Project dashboard         |
| `status` | ZSH function | `~/.config/zsh/functions/status.zsh`       | Update .STATUS files      |

### Command Overlap Map

```
┌─────────────────────────────────────────────────────────────┐
│ WORKFLOW COMMAND LANDSCAPE                                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ZSH Native              Node.js CLI         Purpose       │
│  ───────────            ────────────         ─────────     │
│                                                             │
│  work <proj>            [planned]            Start session │
│  finish [msg]           [planned]            End + commit  │
│  dash [category]        flow dashboard       View projects │
│  status <proj>          flow status          Session info  │
│                         flow status --web    Web UI        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Feature Comparison

| Feature               | ZSH Native         | Node.js CLI                      |
| --------------------- | ------------------ | -------------------------------- |
| **Speed**             | ⚡ Instant (<10ms) | 🐌 Node startup (~100ms)         |
| **Rich UI**           | ❌ Text only       | ✅ ASCII art, colors, sparklines |
| **Web Dashboard**     | ❌ No              | ✅ Yes (`--web` flag)            |
| **TUI Dashboard**     | ❌ No              | ✅ Yes (blessed)                 |
| **Shell Integration** | ✅ Direct          | ⚠️ Via subprocess                |
| **Project Detection** | ✅ Native          | ✅ Via adapters                  |
| **Caching**           | ❌ No              | ✅ 10x speedup                   |
| **Portability**       | ⚠️ ZSH only        | ✅ Any shell                     |

---

## 🔍 Conflict Analysis

### 1. **Command Name Conflict**

**Issue:** `flow` is a common package name

- Facebook Flow (JavaScript type checker) - `/opt/homebrew/bin/flow` (if installed)
- Your flow-cli - Currently symlinked to `/opt/homebrew/bin/flow`

**Current Status:** ✅ **RESOLVED** - Your flow-cli is installed, Facebook Flow is not

**Risk:** If you ever need Facebook Flow, you'll have a conflict

### 2. **Functional Overlap**

**Issue:** Duplicate functionality between systems

| Function      | ZSH Command            | Node.js Equivalent      | Conflict Level |
| ------------- | ---------------------- | ----------------------- | -------------- |
| View session  | `work` (shows current) | `flow status`           | 🟡 Medium      |
| Dashboard     | `dash`                 | `flow dashboard`        | 🔴 High        |
| Status update | `status <proj>`        | N/A                     | 🟢 None        |
| Start work    | `work <proj>`          | `flow work` (planned)   | 🟡 Medium      |
| Finish work   | `finish`               | `flow finish` (planned) | 🟡 Medium      |

### 3. **User Experience Confusion**

**Issue:** Which command should users learn?

**Current confusion points:**

- When to use `dash` vs `flow dashboard`?
- When to use native `work` vs planned `flow work`?
- Why do both systems exist?

---

## 💡 Integration Strategy Options

### Option A: **ZSH-First (Recommended for ADHD workflow)**

**Philosophy:** Native ZSH for speed, Node.js for rich features

**Implementation:**

```bash
# Fast, common operations - ZSH
work <project>          # Instant start (ZSH)
finish [msg]            # Instant commit (ZSH)
status <project>        # Update .STATUS (ZSH)

# Rich visualizations - Node.js
dash                    # Basic text dashboard (ZSH)
flow dashboard          # Interactive TUI (Node.js)
flow status --web       # Web dashboard (Node.js)
flow status -v          # Verbose ASCII art (Node.js)
```

**Rationale:**

- ✅ **ADHD-optimized** - Fast commands have zero latency
- ✅ **Power features available** - Rich UI when you want it
- ✅ **Clear separation** - `flow` = enhanced visualizations
- ✅ **Backwards compatible** - Existing muscle memory preserved

**Changes needed:**

1. Keep ZSH `work`, `finish`, `status` as-is
2. Rename `dash` → `plist` (project list) or keep as basic view
3. Position `flow` as **"enhanced view"** mode:
   - `flow dashboard` - TUI (replaces/enhances `dash`)
   - `flow status --web` - Web UI (new capability)
   - `flow status -v` - Verbose CLI (enhanced `dash`)

**Documentation:**

```markdown
## Quick Commands (ADHD-friendly - instant)

- `work <project>` - Start working (< 10ms)
- `finish [msg]` - Commit and end session (< 50ms)
- `plist` - Quick project list (text)

## Enhanced Views (rich features)

- `flow dashboard` - Live TUI dashboard (auto-refresh)
- `flow status --web` - Web-based dashboard
- `flow status -v` - Detailed ASCII art status
```

**Effort:** 🟢 Low

- Rename `dash` → `plist` (or similar)
- Update docs to clarify roles
- No breaking changes

---

### Option B: **Node.js-First (Unified CLI)**

**Philosophy:** All commands go through `flow` CLI

**Implementation:**

```bash
# All workflow commands use flow
flow work <project>     # Start session
flow finish [msg]       # End session
flow status            # Show status
flow dashboard         # TUI dashboard
flow status --web      # Web dashboard

# ZSH functions become aliases
alias work='flow work'
alias finish='flow finish'
alias dash='flow dashboard'
```

**Rationale:**

- ✅ **Single command** to learn (`flow`)
- ✅ **Consistent interface** - All flags work same way
- ✅ **Portable** - Works in any shell (bash, fish, etc.)
- ❌ **100ms latency** on every command (Node startup)
- ❌ **Breaks ADHD workflow** - Speed matters for context switching

**Changes needed:**

1. Implement `flow work` and `flow finish` in Node.js
2. Create ZSH aliases for backwards compatibility
3. Update all documentation
4. Migrate worklog integration

**Effort:** 🔴 High

- Implement missing Node.js commands
- Port shell logic to JavaScript
- High risk of breaking existing workflows

---

### Option C: **Hybrid Bridge (Best of Both)**

**Philosophy:** ZSH commands call Node.js when needed

**Implementation:**

```bash
# User types (ZSH functions)
work <project>          # ZSH handles session management
finish [msg]            # ZSH handles git commit
dash                    # ZSH shows basic view
dash --tui              # Calls: flow dashboard
dash --web              # Calls: flow status --web

# Behind the scenes
work() {
    # Fast ZSH logic for session start
    # ...
    # Optional: Call flow CLI for rich output
    if [[ -t 1 ]]; then  # If interactive
        flow status -v   # Show pretty status
    fi
}
```

**Rationale:**

- ✅ **Zero latency** for core operations (ZSH)
- ✅ **Rich features** when desired (Node.js)
- ✅ **Smart delegation** - ZSH calls Node.js only for UI
- ✅ **ADHD-friendly** - Fast path always available
- ⚠️ **Complexity** - Two systems to maintain

**Changes needed:**

1. Add `--tui` and `--web` flags to ZSH `dash` command
2. Bridge ZSH → Node.js for visualization features
3. Keep core logic in ZSH (session management)
4. Use Node.js for enhanced views only

**Effort:** 🟡 Medium

- Modify ZSH commands to accept flags
- Delegate to Node.js for rich features
- Document flag usage

---

### Option D: **Rename Node.js CLI (Avoid Conflict)**

**Philosophy:** Rename `flow` → different command

**Implementation:**

```bash
# Rename flow → workview (or similar)
workview dashboard      # TUI dashboard
workview status --web   # Web dashboard
workview status -v      # Verbose status

# ZSH commands stay the same
work <project>
finish [msg]
dash
```

**Possible names:**

- `workview` - View your workflow
- `wdash` - Workflow dashboard
- `flowviz` - Flow visualization
- `workboard` - Work dashboard
- `flo` - Shorter version

**Rationale:**

- ✅ **No confusion** - Completely separate namespaces
- ✅ **No conflict** with Facebook Flow (if needed later)
- ✅ **Clear purpose** - Name indicates visualization focus
- ❌ **Rebranding effort** - All docs, package.json, etc.
- ❌ **User relearning** - Have to teach new command

**Changes needed:**

1. Rename package: `@flowcli/core` → `@workview/core`
2. Rename binary: `flow` → `workview`
3. Update all documentation
4. Update GitHub repo name
5. Publish to npm with new name

**Effort:** 🔴 High

- Complete rebranding
- Breaking change for existing users (if any)
- All tutorials need updates

---

## 📋 Recommendation Matrix

| Criteria             | Option A: ZSH-First | Option B: Node-First | Option C: Hybrid | Option D: Rename |
| -------------------- | ------------------- | -------------------- | ---------------- | ---------------- |
| **ADHD-friendly**    | ✅ Excellent        | ❌ Poor              | ✅ Excellent     | 🟡 Good          |
| **Speed**            | ✅ Instant          | ❌ Slow              | ✅ Instant       | ✅ Instant       |
| **Rich features**    | ✅ Available        | ✅ Unified           | ✅ Available     | ✅ Available     |
| **Simplicity**       | ✅ Clear roles      | 🟡 One command       | ⚠️ Complex       | ✅ Clear         |
| **Effort**           | 🟢 Low              | 🔴 High              | 🟡 Medium        | 🔴 High          |
| **Risk**             | 🟢 Low              | 🔴 High              | 🟡 Medium        | 🟡 Medium        |
| **Backwards compat** | ✅ Yes              | ⚠️ Aliases only      | ✅ Yes           | ✅ Yes           |

---

## 🎯 Final Recommendation: **Option A (ZSH-First)** + Minor Tweaks

**Why:**

1. ✅ **Preserves ADHD workflow** - Fast commands stay instant
2. ✅ **Adds power features** - Rich UI when you want it
3. ✅ **Minimal disruption** - Small rename, big clarity
4. ✅ **Low effort** - Quick win, high impact

**Proposed Changes:**

### 1. Rename Dashboard Command (ZSH)

```bash
# Before
dash                    # Basic project list (ZSH)

# After
plist                   # Project list (text-based, instant)
# OR
dash                    # Keep name, but document as "basic view"
```

**Rationale:** Reduce confusion between `dash` and `flow dashboard`

### 2. Position `flow` as Enhanced Viewer

```bash
# Basic workflow (fast, ZSH)
work <project>          # Start session
finish [msg]            # End + commit
status <proj>           # Update .STATUS
plist                   # Quick text dashboard

# Enhanced views (rich, Node.js)
flow dashboard          # Interactive TUI (live updates)
flow status --web       # Web-based dashboard
flow status -v          # Verbose ASCII art
```

### 3. Update Documentation

**Quick Start Guide:**

```markdown
## Fast Commands (Muscle Memory)

These are instant (< 10ms) - use daily:

- `work <project>` - Start working
- `finish [msg]` - Commit and stop
- `plist` - Quick project overview

## Power Features

Use when you want rich visualizations:

- `flow dashboard` - Live TUI with auto-refresh
- `flow status --web` - Web UI dashboard
- `flow status -v` - Detailed progress bars
```

**Mental Model:**

```
ZSH functions = Fast daily workflow
flow CLI = Rich visualization mode
```

### 4. Implementation Plan

**Phase 1: Clarify Roles (1 hour)**

- [ ] Update README.md with "Fast vs Rich" distinction
- [ ] Add note to `flow --help` about ZSH commands
- [ ] Create comparison table in docs

**Phase 2: Optional Rename (2 hours)**

- [ ] Consider: `dash` → `plist` (or keep as-is)
- [ ] Update ZSH docs if renamed
- [ ] Add note: "`flow dashboard` for live TUI"

**Phase 3: Integration (4 hours)**

- [ ] Add `dash --tui` → calls `flow dashboard`
- [ ] Add `dash --web` → calls `flow status --web`
- [ ] Update help text for both systems

**Total Effort:** ~7 hours

---

## 🚀 Quick Wins (Independent of Strategy)

These improvements benefit ALL options:

### 1. Cross-Link Documentation

```markdown
# In ZSH dash help:

💡 Want a live dashboard? Try: flow dashboard

# In flow help:

💡 For instant results, use native: work, finish, plist
```

### 2. Add Integration Helpers

```bash
# In ~/.config/zsh/functions/adhd-helpers.zsh
alias tui='flow dashboard'
alias webdash='flow status --web'
alias vstat='flow status -v'
```

### 3. Improve Discoverability

```bash
# When user types 'dash', show tip
dash() {
    # ... existing code ...

    echo ""
    echo "💡 Try: flow dashboard (live TUI with auto-refresh)"
}
```

---

## 🤔 Open Questions

1. **Do you use Facebook Flow?** If yes, need different strategy
2. **Which matters more:** Speed or Rich UI?
3. **Are there users besides you?** Affects breaking change tolerance
4. **How often do you use web dashboard?** Affects priority

---

## 📊 Usage Metrics to Collect

Before deciding, gather data:

```bash
# Add to ~/.config/zsh/.zshrc
typeset -g WORKFLOW_CMD_COUNTS

# In each command function
_track_cmd() {
    local cmd=$1
    ((WORKFLOW_CMD_COUNTS[$cmd]++))
}

# Weekly review
workflow-stats() {
    echo "Command usage this week:"
    for cmd count in ${(kv)WORKFLOW_CMD_COUNTS}; do
        printf "%-15s %d\n" "$cmd" "$count"
    done
}
```

**Decision criteria:**

- If `work`/`finish` > 80% usage → **Option A (ZSH-First)**
- If `flow dashboard` > 50% → **Option B (Node-First)**
- If mixed usage → **Option C (Hybrid)**

---

## 🎬 Next Steps

**Immediate (Today):**

1. Review this proposal
2. Answer open questions above
3. Choose preferred option (A, B, C, or D)

**This Week:**

1. Implement chosen option
2. Update documentation
3. Test integration
4. Deploy to production

**Optional (Later):**

1. Collect usage metrics
2. Refine based on data
3. Consider publishing to npm

---

## 📚 References

- Flow CLI codebase: `/Users/dt/projects/dev-tools/flow-cli/`
- ZSH functions: `~/.config/zsh/functions/`
- Documentation: `~/projects/dev-tools/flow-cli/docs/`
- GitHub: https://github.com/Data-Wise/flow-cli
- Docs site: https://Data-Wise.github.io/flow-cli/
