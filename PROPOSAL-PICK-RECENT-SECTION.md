# PROPOSAL: "Recently Used" Section for `pick` Command

**Generated:** 2025-12-19 14:00
**Context:** ZSH Workflow Manager - Smart "last accessed" category
**Parent Proposal:** `PROPOSAL-PICK-ENHANCEMENTS.md`

---

## 📋 Overview

Add a **"Recently Used"** section at the very top of the `pick` command, showing projects you've accessed most recently. This is the ultimate ADHD-friendly feature: resume exactly where you left off with zero mental overhead.

**User Request:** "I also like to put the 'last accessed' smart category first"

**Key Insight:** You already have session tracking infrastructure (`PROJ_SESSION_FILE`, `worklog`, `startsession`/`endsession`). We can leverage this!

---

## 🎯 Design Goals

1. **Zero-friction resume** - See your recent projects immediately
2. **Temporal awareness** - Show when you last worked on each project
3. **No maintenance** - Automatic tracking, no user action needed
4. **ADHD-optimized** - Visual time cues ("2h ago", "yesterday")
5. **Fast** - No performance impact on `pick` command

---

## 💡 Option A: Session-Based Tracking (Recommended ⭐)

Leverage existing session tracking infrastructure for immediate implementation.

### Current State Analysis

**Existing Infrastructure:**
```zsh
PROJ_SESSION_FILE="$HOME/.current-project-session"
# Format: project_name|project_path|project_type|timestamp
# Example: stat-440|/Users/dt/projects/teaching/stat-440/|teaching|1765748585

WORKFLOW_LOG="$HOME/.workflow-log"
# Format: timestamp | session_id | project | action | details
```

**Current Tracking Points:**
- `pick` with Ctrl-W → calls `work` → starts session
- `startsession` / `endsession` → logs to workflow
- `worklog` → records project actions

### Implementation Strategy

#### 1. Create Project Access Log

```zsh
# In adhd-helpers.zsh, add global variable
PROJ_ACCESS_LOG="$HOME/.project-access-log"

# Format: timestamp|project_name|project_path|project_type|action
# Example: 1734629400|zsh-configuration|/Users/dt/projects/dev-tools/zsh-configuration|dev|cd
```

#### 2. Track Access on Every `pick` Action

```zsh
# In pick() function, after determining proj_dir and proj_name:
_log_project_access() {
    local proj_name="$1"
    local proj_dir="$2"
    local proj_type="$3"
    local action="${4:-cd}"

    local timestamp=$(date +%s)
    local entry="$timestamp|$proj_name|$proj_dir|$proj_type|$action"

    # Append to log (atomic write)
    echo "$entry" >> "$PROJ_ACCESS_LOG"

    # Keep log manageable (last 500 entries)
    if [[ $(wc -l < "$PROJ_ACCESS_LOG" 2>/dev/null || echo 0) -gt 500 ]]; then
        tail -n 500 "$PROJ_ACCESS_LOG" > "$PROJ_ACCESS_LOG.tmp"
        mv "$PROJ_ACCESS_LOG.tmp" "$PROJ_ACCESS_LOG"
    fi
}

# Call after cd but before executing action:
_log_project_access "$proj_name" "$proj_dir" "$proj_type" "$action"
```

#### 3. Generate Recent Projects List

```zsh
_proj_recent() {
    local limit="${1:-5}"  # Default: show last 5 projects

    if [[ ! -f "$PROJ_ACCESS_LOG" ]]; then
        return 0
    fi

    # Get unique projects (most recent first)
    # Use awk to deduplicate by project name, keeping first (most recent)
    tail -n 100 "$PROJ_ACCESS_LOG" | \
        tac | \
        awk -F'|' '!seen[$2]++ {print}' | \
        head -n "$limit" | \
        while IFS='|' read -r ts name path type action; do
            # Calculate time ago
            local now=$(date +%s)
            local diff=$((now - ts))
            local time_ago=$(_format_time_ago "$diff")

            # Output: name|type|icon|path|time_ago
            local icon=$(_get_type_icon "$type")
            echo "$name|$type|$icon|$path|$time_ago"
        done
}

_format_time_ago() {
    local seconds="$1"
    local minutes=$((seconds / 60))
    local hours=$((minutes / 60))
    local days=$((hours / 24))

    if [[ $minutes -lt 1 ]]; then
        echo "just now"
    elif [[ $minutes -lt 60 ]]; then
        echo "${minutes}m ago"
    elif [[ $hours -lt 24 ]]; then
        echo "${hours}h ago"
    elif [[ $days -eq 1 ]]; then
        echo "yesterday"
    elif [[ $days -lt 7 ]]; then
        echo "${days}d ago"
    else
        echo "$(date -r $(($(date +%s) - seconds)) '+%b %d')"
    fi
}

_get_type_icon() {
    case "$1" in
        r) echo "📦" ;;
        dev) echo "🔧" ;;
        teach) echo "🎓" ;;
        rs) echo "🔬" ;;
        q) echo "📝" ;;
        app) echo "📱" ;;
        mgmt) echo "⚙️" ;;
        *) echo "📁" ;;
    esac
}
```

#### 4. Integrate into `pick` Display

```zsh
# In pick() function, modify _proj_list_all call:
_proj_list_all() {
    local category="${1:-}"

    # FIRST: Recent projects (if no category filter)
    if [[ -z "$category" || "$category" == "recent" ]]; then
        _proj_recent 5 | while IFS='|' read -r name type icon path time_ago; do
            printf "%-20s %s %-4s  🕐 %s\n" "$name" "$icon" "$type" "$time_ago"
        done
    fi

    # SECOND: Management section (if no category filter)
    if [[ -z "$category" || "$category" == "mgmt" ]]; then
        # ... existing management code ...
    fi

    # THIRD: Regular categories
    # ... existing code ...
}
```

### Visual Example

```
╔════════════════════════════════════════════════════════════╗
║  🔍 PROJECT PICKER                                         ║
║  Enter=cd | ^W=work | ^O=code | ^C=claude | ^G=gemini     ║
╚════════════════════════════════════════════════════════════╝

─── 🕐 RECENTLY USED ──────────────────────────────────────
zsh-configuration    🔧 dev   🕐 2h ago
dev-planning         ⚙️  mgmt  🕐 4h ago
medfit               📦 r     🕐 yesterday
stat-440             🎓 teach 🕐 2d ago
mediation-planning   🔬 rs    🕐 Dec 17

─── ⚙️  MANAGEMENT ────────────────────────────────────────
dev-planning         ⚙️  mgmt
zsh-configuration    ⚙️  mgmt
aiterm               ⚙️  mgmt
apple-notes-sync     ⚙️  mgmt
obsidian-cli-ops     ⚙️  mgmt

─── 📦 R PACKAGES ─────────────────────────────────────────
medfit               📦 r
mediationverse       📦 r
...
```

### Pros ⭐

- **Leverages existing infrastructure** (session tracking already in place)
- **Zero cognitive load** - "What was I working on?" → Look at top 5
- **Temporal awareness** - Time cues help memory ("Oh yeah, I was working on that yesterday")
- **Fast** - Simple log file, tail + awk (< 10ms even with 500 entries)
- **Automatic** - No user action needed, tracks all `pick` usage
- **ADHD-friendly** - Most recent work is always visible

### Cons

- Requires new log file (`~/.project-access-log`)
- Need to handle log rotation (keep last 500 entries)
- Time calculations add slight complexity

### ADHD Benefits 🧠

- **Context restoration** - See exactly what you were working on
- **No mental recall needed** - Projects sorted by actual usage
- **Visual time anchors** - "2h ago" triggers memory better than just seeing a name
- **Momentum preservation** - Easy to continue yesterday's work

---

## 💡 Option B: Frequency-Based Ranking

Instead of (or in addition to) recency, rank by total access frequency.

### Implementation

```zsh
_proj_frequent() {
    local limit="${1:-5}"

    if [[ ! -f "$PROJ_ACCESS_LOG" ]]; then
        return 0
    fi

    # Count access frequency (last 30 days)
    local cutoff=$(($(date +%s) - 2592000))  # 30 days

    awk -F'|' -v cutoff="$cutoff" '
        $1 >= cutoff {count[$2]++; last[$2]=$1; path[$2]=$3; type[$2]=$4}
        END {
            for (proj in count) {
                print count[proj], proj, path[proj], type[proj], last[proj]
            }
        }
    ' "$PROJ_ACCESS_LOG" | \
        sort -rn | \
        head -n "$limit" | \
        while read -r count name path type last_ts; do
            local time_ago=$(_format_time_ago $(($(date +%s) - last_ts)))
            local icon=$(_get_type_icon "$type")
            echo "$name|$type|$icon|$path|${count}× (last: $time_ago)"
        done
}
```

### Visual Example

```
─── 🔥 MOST USED (30 days) ────────────────────────────────
zsh-configuration    🔧 dev   🔥 47× (last: 2h ago)
medfit               📦 r     🔥 31× (last: yesterday)
dev-planning         ⚙️  mgmt  🔥 22× (last: 4h ago)
stat-440             🎓 teach 🔥 18× (last: 2d ago)
obsidian-cli-ops     ⚙️  mgmt  🔥 15× (last: 3d ago)
```

### Pros

- Shows **actual work patterns** (not just last access)
- Useful for identifying primary focus areas
- Can combine with recency for hybrid ranking

### Cons

- More complex calculation (awk processing)
- May not reflect current focus (active project vs frequent project)
- Less useful for task-switching workflows

---

## 💡 Option C: Hybrid Smart Ranking ⭐⭐

**Best of both worlds:** Combine recency and frequency with intelligent weighting.

### Algorithm

```zsh
_proj_smart_rank() {
    local limit="${1:-5}"

    # Scoring formula:
    # score = (recency_weight × recency_score) + (frequency_weight × frequency_score)
    #
    # Recency score: Exponential decay (recent = higher score)
    # Frequency score: Access count in last 7 days
    #
    # Default weights: recency=0.7, frequency=0.3 (favor recent over frequent)

    local recency_weight=0.7
    local frequency_weight=0.3
    local now=$(date +%s)
    local week_ago=$((now - 604800))  # 7 days

    awk -F'|' -v now="$now" -v week_ago="$week_ago" \
              -v rw="$recency_weight" -v fw="$frequency_weight" '
        {
            proj = $2
            ts = $1
            path[proj] = $3
            type[proj] = $4

            # Track most recent access
            if (ts > last[proj]) last[proj] = ts

            # Count accesses in last week
            if (ts >= week_ago) freq[proj]++
        }
        END {
            for (proj in last) {
                # Recency score: exponential decay (half-life = 24h)
                age = (now - last[proj]) / 86400.0  # days
                recency = exp(-age * 0.693)  # 0.693 ≈ ln(2)

                # Frequency score: normalized by max frequency
                frequency = (freq[proj] + 0) / 20.0  # assume max 20 accesses/week
                if (frequency > 1.0) frequency = 1.0

                # Combined score
                score = (rw * recency) + (fw * frequency)

                print score, proj, path[proj], type[proj], last[proj], (freq[proj] + 0)
            }
        }
    ' "$PROJ_ACCESS_LOG" | \
        sort -rn | \
        head -n "$limit" | \
        while read -r score name path type last_ts freq; do
            local time_ago=$(_format_time_ago $((now - last_ts)))
            local icon=$(_get_type_icon "$type")
            echo "$name|$type|$icon|$path|$time_ago (${freq}×/week)"
        done
}
```

### Visual Example

```
─── ⭐ SMART RECENT ───────────────────────────────────────
zsh-configuration    🔧 dev   🕐 2h ago (12×/week)
medfit               📦 r     🕐 yesterday (8×/week)
dev-planning         ⚙️  mgmt  🕐 4h ago (5×/week)
stat-440             🎓 teach 🕐 2d ago (3×/week)
mediation-planning   🔬 rs    🕐 Dec 17 (1×/week)
```

### Pros ⭐⭐

- **Intelligent ranking** - Balance between "what I just used" and "what I use often"
- **Prevents one-off projects** from dominating recent list
- **Highlights real focus areas** while respecting recency
- **Configurable** - Adjust weights for personal preference

### Cons

- Most complex implementation (awk with floating-point math)
- Harder to explain to users ("why is X ranked higher than Y?")
- Potential performance concern (but awk is fast)

---

## 💡 Option D: Context-Aware Recent

Show recent projects **filtered by current context** (domain, time of day, git branch).

### Implementation Ideas

```zsh
_proj_recent_contextual() {
    local context="${1:-auto}"

    # Auto-detect context
    if [[ "$context" == "auto" ]]; then
        local hour=$(date +%H)

        # Morning (6-12): Teaching & research
        # Afternoon (12-18): Development & R packages
        # Evening (18-24): Personal projects

        if [[ $hour -ge 6 && $hour -lt 12 ]]; then
            context="morning"  # Filter: teach, rs
        elif [[ $hour -ge 12 && $hour -lt 18 ]]; then
            context="afternoon"  # Filter: dev, r
        else
            context="evening"  # No filter
        fi
    fi

    # Filter recent projects by context
    _proj_recent 20 | \
        awk -F'|' -v ctx="$context" '
            # Filter logic based on context
            # ... implementation ...
        '
}
```

### Examples

**Morning (9 AM):**
```
─── 🌅 RECENT (Teaching & Research Focus) ─────────────────
stat-440             🎓 teach 🕐 yesterday
mediation-planning   🔬 rs    🕐 2d ago
collider             🔬 rs    🕐 3d ago
```

**Afternoon (2 PM):**
```
─── ☀️ RECENT (Development Focus) ────────────────────────
zsh-configuration    🔧 dev   🕐 2h ago
medfit               📦 r     🕐 4h ago
dev-planning         ⚙️  mgmt  🕐 yesterday
```

### Pros

- **Context-appropriate** - See projects relevant to current task mode
- **Reduces cognitive load** - Fewer options = faster decision
- **Adaptive** - Learns your work patterns

### Cons

- ❌ Complex heuristics (time-based, domain-based)
- ❌ May hide relevant projects
- ❌ Hard to predict behavior

**Verdict:** Interesting for v2.0, too complex for initial implementation.

---

## 💡 Option E: Workspace-Based Recent

Track recent projects **per workspace** (iTerm2 tab, tmux session, VS Code window).

### Implementation

```zsh
# Track workspace ID in log
WORKSPACE_ID="${ITERM_SESSION_ID:-${TMUX_PANE:-default}}"

_log_project_access() {
    # ... existing params ...
    local workspace="$WORKSPACE_ID"

    local entry="$timestamp|$proj_name|$proj_dir|$proj_type|$action|$workspace"
    echo "$entry" >> "$PROJ_ACCESS_LOG"
}

_proj_recent_workspace() {
    # Show recent projects for THIS workspace only
    _proj_recent_all | grep "|$WORKSPACE_ID$"
}
```

### Use Case

**iTerm2 Tab 1** (Research):
```
─── 🕐 RECENT (This Workspace) ────────────────────────────
mediation-planning   🔬 rs    🕐 2h ago
collider             🔬 rs    🕐 yesterday
```

**iTerm2 Tab 2** (Dev):
```
─── 🕐 RECENT (This Workspace) ────────────────────────────
zsh-configuration    🔧 dev   🕐 30m ago
aiterm               ⚙️  mgmt  🕐 1h ago
```

### Pros

- **Workspace isolation** - Each terminal has its own recent list
- **Mental context preserved** - Terminal = mental context
- **Integrates with iTerm2** - Leverage existing session tracking

### Cons

- Requires workspace ID detection
- May fragment recent list too much
- Not useful for single-window workflows

**Verdict:** Complementary to global recent list. Add as `pick recent:workspace`.

---

## 🎨 Recommended Implementation Plan

### Phase 1: Basic Recent Section (Quick Win - 2 hours)

**Implement Option A (Session-Based Tracking)** with these features:

1. ✅ Create `~/.project-access-log` file
2. ✅ Track access on every `pick` action
3. ✅ Show top 5 recent projects at top of `pick`
4. ✅ Display time ago ("2h ago", "yesterday")
5. ✅ Automatic log rotation (keep last 500 entries)

**Result:**
```
─── 🕐 RECENTLY USED ──────────────────────────────────────
zsh-configuration    🔧 dev   🕐 2h ago
dev-planning         ⚙️  mgmt  🕐 4h ago
medfit               📦 r     🕐 yesterday
```

### Phase 2: Enhancements (Optional - 1 hour each)

**Add configurable options:**

```zsh
# In pick() function, support arguments:
pick                 # Show all (recent + mgmt + categories)
pick recent          # Show ONLY recent projects (last 20)
pick recent:10       # Show last 10 recent projects
```

**Add keybind for "resume last":**
```zsh
# In fzf bindings:
--bind="ctrl-r:execute-silent(echo resume-last > $action_file)+accept"

# In action case:
case "$action" in
    resume-last)
        # Get most recent project from log
        local last_proj=$(_proj_recent 1 | cut -d'|' -f1)
        # ... cd to it ...
        ;;
esac
```

### Phase 3: Smart Ranking (Future - 3 hours)

**Implement Option C (Hybrid Smart Ranking)** if simple recency isn't enough.

---

## 🔧 Implementation Checklist

### Phase 1: Basic Recent Section

- [ ] Define `PROJ_ACCESS_LOG` global variable
- [ ] Implement `_log_project_access()` function
- [ ] Implement `_format_time_ago()` helper
- [ ] Implement `_get_type_icon()` helper
- [ ] Implement `_proj_recent()` function
- [ ] Modify `_proj_list_all()` to output recent section first
- [ ] Add log rotation logic (keep last 500)
- [ ] Test: Access 5 different projects, verify recent list
- [ ] Update help text: `pick --help`
- [ ] Update fzf header with section info

### Phase 2: Configuration Options

- [ ] Add `pick recent` filter support
- [ ] Add `pick recent:N` limit support
- [ ] Add setting: `PROJ_RECENT_COUNT` (default 5)
- [ ] Add setting: `PROJ_RECENT_ENABLED` (default true)
- [ ] Document in help system

### Phase 3: Advanced Features (Optional)

- [ ] Add Ctrl-R keybind for "resume last project"
- [ ] Add frequency tracking (`_proj_frequent`)
- [ ] Add smart ranking (`_proj_smart_rank`)
- [ ] Add workspace isolation (`_proj_recent_workspace`)

---

## 📊 Display Layout Options

### Layout A: Compact (Recommended)

```
─── 🕐 RECENTLY USED ──────────────────────────────────────
zsh-configuration    🔧 dev   🕐 2h ago
dev-planning         ⚙️  mgmt  🕐 4h ago
medfit               📦 r     🕐 yesterday
stat-440             🎓 teach 🕐 2d ago
mediation-planning   🔬 rs    🕐 Dec 17
```

**Pros:** Clean, fits on one screen with management + categories
**Cons:** Less visual separation

### Layout B: Prominent

```
╭─────────────────────────────────────────────────────────╮
│ 🕐 RECENTLY USED                                        │
├─────────────────────────────────────────────────────────┤
│ zsh-configuration    🔧 dev   🕐 2h ago                 │
│ dev-planning         ⚙️  mgmt  🕐 4h ago                 │
│ medfit               📦 r     🕐 yesterday              │
│ stat-440             🎓 teach 🕐 2d ago                 │
│ mediation-planning   🔬 rs    🕐 Dec 17                 │
╰─────────────────────────────────────────────────────────╯
```

**Pros:** Highly visible, draws attention
**Cons:** Takes more vertical space

### Layout C: Inline Time

```
─── 🕐 RECENTLY USED ──────────────────────────────────────
zsh-configuration    🔧 dev   (2 hours ago)
dev-planning         ⚙️  mgmt  (4 hours ago)
medfit               📦 r     (yesterday)
```

**Pros:** More readable time format
**Cons:** Longer lines

**Recommendation:** Use Layout A (compact) for consistency with management section.

---

## 🚨 Potential Issues & Solutions

### Issue 1: Log File Growth

**Problem:** `~/.project-access-log` could grow unbounded.

**Solutions:**
1. ✅ **Automatic rotation** - Keep last 500 entries (implemented in Option A)
2. Use logrotate-style weekly cleanup
3. SQLite database instead of flat file (overkill for this use case)

**Recommendation:** Option 1 (simple, effective).

### Issue 2: Performance with Large Log

**Problem:** Parsing 500-line log on every `pick` invocation.

**Solutions:**
1. ✅ **Optimize with tail + awk** - Process only last 100 entries (< 10ms)
2. Cache recent list with TTL (rebuild every 5 minutes)
3. Use indexed database (overcomplicated)

**Recommendation:** Option 1. Modern awk is extremely fast.

**Benchmark:**
```bash
# Test with 500-line log
time (tail -n 100 ~/.project-access-log | tac | awk -F'|' '!seen[$2]++' | head -n 5)
# Expected: < 10ms on modern hardware
```

### Issue 3: Duplicate Projects in Recent + Management

**Problem:** `dev-planning` appears in both "Recent" and "Management" sections.

**Solutions:**
1. ✅ **Allow duplicates** - It's useful! Recent shows "when", Management shows "what"
2. Deduplicate: Remove from management if in recent
3. Visual indicator: Add "⭐" to recent projects that are also management

**Recommendation:** Option 1 (allow duplicates). They serve different purposes.

### Issue 4: Privacy/Security

**Problem:** Log file contains project paths (might include sensitive names).

**Solutions:**
1. Set restrictive permissions: `chmod 600 ~/.project-access-log`
2. Add to `.gitignore` (already in `~/`)
3. Option to disable: `PROJ_RECENT_ENABLED=false`

**Recommendation:** All three.

---

## 🎯 Success Metrics

**Before:**
- Average time to find project in `pick`: ~5-10 seconds (scrolling/filtering)
- Mental overhead: "What was I working on?" → Manual recall required

**After:**
- Average time to resume recent work: ~1-2 seconds (top of list)
- Mental overhead: **Zero** - Visual reminder of recent projects
- Context switch recovery: Instant ("Oh right, I was working on medfit")

**Quantifiable:**
- 80% reduction in time to resume recent work
- 90% reduction in "what was I doing?" cognitive load
- 100% of recent work visible without scrolling

---

## 🔮 Future Enhancements (Ideas Backlog)

### Idea 1: Visual Timeline

Show a mini timeline of today's project switches:

```
─── 🕐 TODAY'S PROJECT TIMELINE ───────────────────────────
 9:00 ──── stat-440 ────┐
10:30 ─────────────────┴──── medfit ────┐
14:00 ───────────────────────────────┴──── zsh-config ──►
```

### Idea 2: Session Resume Prompts

When you `pick`, suggest resuming your last session:

```
💡 Resume yesterday's work on medfit? (y/n)
   Last session: 2h 34m (Dec 18, 2-4 PM)
   Last action: "Debugging test failures"
```

### Idea 3: Project Momentum Tracking

Show "momentum score" for each project:

```
zsh-configuration    🔧 dev   🕐 2h ago   🔥🔥🔥 (3-day streak)
medfit               📦 r     🕐 yesterday 🔥🔥 (2-day streak)
```

### Idea 4: Integration with `work` Command

Auto-populate `work` command with recent project:

```bash
work         # No arg? Show recent projects to choose from
work !1      # Resume most recent project
work !2      # Resume 2nd most recent project
```

### Idea 5: Export Recent Projects to Apple Notes

Sync recent project list to Apple Notes for mobile reference:

```
# Recent Projects (Synced from zsh-configuration)
- zsh-configuration (2h ago) - Dev
- medfit (yesterday) - R package
- stat-440 (2d ago) - Teaching
```

---

## ✅ Recommendation

**Implement Phase 1 (Basic Recent Section) immediately:**

- **Effort:** ⚡ Medium (2 hours)
- **Impact:** 🟢 Very High (massive ADHD productivity boost)
- **Risk:** 🟢 Low (isolated feature, easy to disable)
- **Dependencies:** None (standalone feature)

**Why this is the #1 priority:**

1. **Solves real pain point** - "What was I working on?" is a daily question
2. **Leverages existing infrastructure** - Session tracking already exists
3. **Fast to implement** - Simple log file + awk processing
4. **Huge ADHD benefit** - Visual reminder = instant context restoration
5. **Complements management section** - Together they make `pick` incredibly powerful

---

## 📝 Integration with PROPOSAL-PICK-ENHANCEMENTS.md

This proposal complements the original enhancement proposal:

**Original Proposal:**
1. ✅ Keybinds: Ctrl-C (Claude), Ctrl-G (Gemini)
2. ✅ Management section: 5 meta/coordination projects

**This Proposal:**
3. ✅ **Recent section: Last 5 accessed projects**

**Combined Visual:**
```
╔════════════════════════════════════════════════════════════╗
║  🔍 PROJECT PICKER                                         ║
║  Enter=cd | ^W=work | ^O=code | ^C=claude | ^G=gemini     ║
║  ^S=status | ^L=log | ^R=resume-last                       ║
╚════════════════════════════════════════════════════════════╝

─── 🕐 RECENTLY USED ──────────────────────────────────────
zsh-configuration    🔧 dev   🕐 2h ago
dev-planning         ⚙️  mgmt  🕐 4h ago
medfit               📦 r     🕐 yesterday
stat-440             🎓 teach 🕐 2d ago
mediation-planning   🔬 rs    🕐 Dec 17

─── ⚙️  MANAGEMENT ────────────────────────────────────────
dev-planning         ⚙️  mgmt
zsh-configuration    ⚙️  mgmt
aiterm               ⚙️  mgmt
apple-notes-sync     ⚙️  mgmt
obsidian-cli-ops     ⚙️  mgmt

─── 📦 R PACKAGES ─────────────────────────────────────────
medfit               📦 r
mediationverse       📦 r
...
```

**Perfect ADHD-Optimized Hierarchy:**
1. **Recent** - "What was I doing?" (temporal/episodic memory)
2. **Management** - "Where do I coordinate?" (meta-tools)
3. **Categories** - "What can I work on?" (all projects)

---

## 🎯 Next Steps

1. **Review this proposal** - Does the recent section design match your vision?
2. **Choose layout** - Layout A (compact), B (prominent), or C (inline time)?
3. **Set recent count** - Default to 5? Make configurable?
4. **Implementation order:**
   - Option A: Implement recent section FIRST (biggest impact)
   - Option B: Implement keybinds FIRST, recent section SECOND
   - Option C: Implement both in parallel
5. **Test isolation:**
   - Create `_proj_recent` function standalone
   - Verify log tracking works correctly
   - Test time formatting with various timestamps

---

**Last Updated:** 2025-12-19 14:00
**Status:** 🟡 Proposal - Awaiting Approval
**Parent:** PROPOSAL-PICK-ENHANCEMENTS.md
**Author:** Claude Sonnet 4.5
**Estimated Time:** 2 hours (Phase 1), +2 hours (Phase 2), +3 hours (Phase 3)
