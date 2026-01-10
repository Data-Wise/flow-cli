# Flow-CLI Enhancement Design Decisions

**Date:** 2026-01-09
**Session:** Deep Brainstorm - Workflow Review
**Status:** Approved by User

---

## Summary

All 8 critical design questions have been answered. This document captures the approved design decisions for the 4 upcoming feature enhancements.

---

## Design Decisions

### 1. Command Search Scope

**Decision:** Built-in commands only

**What this means:**

- `flow search <query>` will search only flow-cli built-in commands
- Includes: work, dash, pick, finish, hop, catch, and all 11 dispatchers (g, cc, mcp, r, qu, obs, tm, wt, dot, v, flow)
- Excludes: MCP server tools (rforge, nexus, statistical-research)
- Excludes: Custom plugins

**Rationale:**

- Fast response time (< 100ms guaranteed)
- No dependency on MCP server configuration
- Simpler to implement and maintain
- Can expand to MCP tools in future release (v5.3.0 or later) if users request

**Implementation Impact:**

- Search index: ~50 commands/subcommands
- Index generation: Parse help text from all dispatchers and commands
- Estimated file size: ~15 KB search index

---

### 2. Context Restoration Behavior

**Decision:** Always prompt (no silent behavior)

**What this means:**

- Every time user runs `work <project>`, they see a restoration prompt if session metadata exists
- User chooses: Y (restore), n (skip), skip (skip)
- No configuration required (no FLOW_SESSION_RESTORE env var)
- Restoration prompt is non-blocking (can skip with Enter if default is sensible)

**Example:**

```bash
$ work flow-cli

📋 Last Session (2h ago):
  Branch: feature/context-restoration
  Files: lib/session-metadata.zsh (+89 lines)
  Next: Write tests for capture/restore

🔄 Restore? [Y/n/skip]
```

**Rationale:**

- Most ADHD-friendly: User maintains full control
- No surprises (always explicit about what's happening)
- Zero configuration overhead
- Can quickly skip if in a hurry

**Implementation Impact:**

- Prompt displayed on every `work` command (adds ~50ms)
- User can press Enter to accept default (Y)
- Restoration actions: checkout branch, cd to project, show next action

---

### 3. Workspace Dependencies

**Decision:** Provide fallback (tmux optional, not required)

**What this means:**

- **With tmux installed:** Full workspace features (persistent sessions, window management)
- **Without tmux:** Simple multi-project switcher (picker-based, no persistence)
- Graceful detection: `command -v tmux >/dev/null 2>&1`

**Fallback Mode (No tmux):**

```bash
$ flow workspace start mcp-ecosystem
⚠️  tmux not found - using fallback mode

📦 Workspace: mcp-ecosystem
   Projects: statistical-research, nexus, rforge

Select project:
  1) statistical-research
  2) nexus
  3) rforge
  q) quit

Choice [1-3/q]:
```

**tmux Mode (tmux installed):**

```bash
$ flow workspace start mcp-ecosystem
🚀 Creating tmux session: flow-workspace-mcp-ecosystem

Windows:
  1: statistical-research
  2: nexus
  3: rforge

[Attaches to tmux session]
```

**Rationale:**

- Broader compatibility (works even without tmux)
- Still provides value (quick project switching)
- Progressive enhancement (better experience with tmux)
- Users can install tmux later and get upgraded experience

**Implementation Impact:**

- Dual codepaths: `_workspace_with_tmux()` and `_workspace_fallback()`
- Fallback uses existing `pick` command logic
- Increased complexity: +8 hours implementation time (24h total vs 16h)

---

### 4. Ecosystem Operations Naming

**Decision:** `flow ecosystem`

**What this means:**

- Command namespace: `flow ecosystem <subcommand>`
- Subcommands: detect, cascade, deps, impact, status
- Not limited to R packages (can expand to Node monorepos, Python workspaces)

**Example Usage:**

```bash
flow ecosystem detect    # Auto-detect structure
flow ecosystem cascade   # Plan coordinated updates
flow ecosystem deps      # Show dependency graph
flow ecosystem impact    # Analyze change impact
flow ecosystem status    # Overall ecosystem health
```

**Rationale:**

- Clear, descriptive naming (obvious what it does)
- Broader scope (not R-specific)
- Follows pattern of `flow doctor`, `flow session`, `flow workspace`
- Matches RForge MCP terminology (easy delegation)

**Implementation Impact:**

- New command file: `commands/ecosystem.zsh`
- Delegates to RForge MCP when available
- Graceful degradation: Shows install hint if RForge not configured

---

### 5. Energy-Aware Suggestions

**Decision:** AI-powered (analyze past patterns)

**What this means:**

- Flow-cli tracks task completion patterns:
  - Time of day when tasks completed
  - Task type (high-focus: architecture, debug vs low-focus: docs, formatting)
  - Completion success (finished vs abandoned)
  - Duration of work sessions
- ML model predicts current energy level based on time + recent patterns
- User can override: `flow energy high` (manual override)

**Example:**

```bash
$ flow next
🤖 Predicted Energy: Low (based on 3 PM pattern)

Suggested low-energy tasks:
  1. Write documentation for context restoration
  2. Format code with prettier
  3. Review PR #125 (small change)

Override with: flow energy high
```

**Data Tracked:**

```json
{
  "timestamp": 1736419200,
  "hour": 15,
  "task": "Write documentation",
  "completed": true,
  "duration_minutes": 45,
  "task_type": "low-focus",
  "session_quality": "good"
}
```

**Rationale:**

- Most personalized (learns YOUR energy patterns, not generic assumptions)
- Improves over time (better predictions with more data)
- Still allows manual override (user knows best in the moment)
- Privacy-preserving (all data stored locally)

**Implementation Impact:**

- Data collection: Store task logs in `~/.local/share/flow/energy-logs.json`
- ML model: Simple time-based clustering (high/medium/low energy periods)
- Prediction: Use recent 2-week history to predict current energy
- Fallback: If no data yet, use time-based heuristic (morning=high)
- Privacy: Add `FLOW_ENERGY_TRACKING=no` opt-out
- Complexity: +12 hours implementation (vs +6 hours for manual mode)

---

### 6. Implementation Priority Order

**Decision:** 1→2→3→4 (Context Restoration → Command Search → Ecosystem Ops → Workspaces)

**What this means:**

- **Sprint 1 (Week 1-3):** Context Restoration (12h)
- **Sprint 2 (Week 4-5):** Command Search (6h)
- **Sprint 3 (Week 6-7):** Ecosystem Operations (4h)
- **Sprint 4 (Week 8-12):** Multi-Project Workspaces (24h, including AI energy tracking)

**Rationale:**

- Highest impact/effort ratio first
- Context Restoration addresses #1 ADHD pain point
- Each feature builds on previous (workspaces need session metadata)
- Quick wins early (Command Search in just 6h)

**Adjusted Timeline:**
| Sprint | Feature | Hours | Weeks | Release |
|--------|---------|-------|-------|---------|
| 1 | Context Restoration | 12h | 1-3 | v5.1.0 |
| 2 | Command Search | 6h | 4-5 | v5.2.0 |
| 3 | Ecosystem Ops | 4h | 6-7 | v5.3.0 |
| 4 | Workspaces + AI Energy | 24h | 8-12 | v5.4.0 |
| **Total** | | **46h** | **12 weeks** | |

---

### 7. Release Strategy

**Decision:** Incremental releases (v5.1.0, v5.2.0, v5.3.0, v5.4.0)

**What this means:**

- Four separate releases over 12 weeks
- Each release is complete, tested, documented
- Users get features as they're ready (no waiting for full suite)
- Faster feedback loop (validate each feature before next)

**Release Schedule:**

- **v5.1.0 (Week 3):** Context Restoration
- **v5.2.0 (Week 5):** Command Search
- **v5.3.0 (Week 7):** Ecosystem Operations
- **v5.4.0 (Week 12):** Multi-Project Workspaces + AI Energy

**Release Checklist (Each Release):**

```
[ ] Feature complete (all acceptance criteria met)
[ ] Tests passing (unit + integration + E2E)
[ ] Documentation complete (reference + tutorial)
[ ] CHANGELOG.md updated
[ ] README.md updated (if needed)
[ ] Version bumped (package.json, README badges)
[ ] Git tag created (vX.Y.Z)
[ ] GitHub release created
[ ] Docs deployed (mkdocs gh-deploy)
[ ] Announcement (if major feature)
```

**Rationale:**

- Less risk (smaller changesets per release)
- Faster user feedback (validate assumptions early)
- More ADHD-friendly (celebrate wins quarterly vs one big launch)
- Easier rollback (isolate issues to specific release)
- Maintains momentum (steady progress visible)

**Implementation Impact:**

- More release overhead (4 releases vs 1)
- But: Better quality (more testing cycles)
- Better adoption (users see progress, stay engaged)

---

### 8. Documentation Style

**Decision:** Balanced (both reference + tutorials)

**What this means:**

- **Reference docs:** Complete command syntax, options, flags, examples
- **Tutorials:** Step-by-step guides with real workflows

**Structure (Each Feature):**

```
docs/
├── reference/
│   ├── CONTEXT-RESTORATION-REFERENCE.md    # Command syntax, options
│   ├── COMMAND-SEARCH-REFERENCE.md
│   ├── ECOSYSTEM-OPERATIONS-REFERENCE.md
│   └── WORKSPACE-REFERENCE.md
└── guides/
    ├── context-restoration-guide.md         # Tutorial: How to use
    ├── command-search-guide.md
    ├── ecosystem-operations-guide.md
    └── workspace-guide.md
```

**Reference Doc Template:**

````markdown
# Feature Name Reference

## Commands

- `command subcommand` - Description
- `command --option` - Option description

## Options

| Flag | Description | Default |
| ---- | ----------- | ------- |

## Examples

```bash
# Example 1: Common use case
command subcommand

# Example 2: Advanced use case
command --option value
```
````

## Configuration

Environment variables, config files, etc.

````

**Tutorial Template:**
```markdown
# Feature Name Guide

## What You'll Learn
- Skill 1
- Skill 2

## Prerequisites
- Required knowledge

## Step 1: Setup
[Step-by-step instructions]

## Step 2: Basic Usage
[Common workflow]

## Step 3: Advanced Usage
[Power user tips]

## Troubleshooting
Common issues and solutions
````

**Rationale:**

- Serves different learning styles:
  - Reference: Quick lookup for experienced users
  - Tutorial: Learning for new users
- Matches existing flow-cli documentation pattern
- Comprehensive coverage (both "how to do X" and "what does X do")

**Implementation Impact:**

- 2x documentation time (write both reference + tutorial)
- But: Better user experience (no gaps in docs)
- Better onboarding (tutorials for new users)
- Better retention (reference for power users)

---

## Updated Implementation Plan

### Sprint 1: Context Restoration (Week 1-3) - 12 hours

**Deliverables:**

- [ ] `lib/session-metadata.zsh` (capture/restore functions)
- [ ] Integration into `commands/work.zsh` (restoration prompt)
- [ ] Integration into finish logic (capture on session end)
- [ ] Tests: `tests/session-metadata.test.zsh`
- [ ] Reference: `docs/reference/CONTEXT-RESTORATION-REFERENCE.md`
- [ ] Tutorial: `docs/guides/context-restoration-guide.md`
- [ ] Release: v5.1.0

**Session Metadata Captured:**

```json
{
  "project": "flow-cli",
  "timestamp": 1736419200,
  "branch": "feature/context-restoration",
  "modified_files": ["lib/session-metadata.zsh", "commands/work.zsh"],
  "last_command": "git diff lib/session-metadata.zsh",
  "next_action": "Write tests for capture/restore",
  "uncommitted_changes": true,
  "session_duration_minutes": 120
}
```

**Restoration Prompt:**

```bash
📋 Last Session (2h ago):
  Branch: feature/context-restoration
  Files: lib/session-metadata.zsh (+89 lines)
  Status: 2 uncommitted changes
  Next: Write tests for capture/restore

🔄 Restore? [Y/n/skip]
```

---

### Sprint 2: Command Search (Week 4-5) - 6 hours

**Deliverables:**

- [ ] New command: `flow search <query>`
- [ ] Search index builder (parse help text from all commands)
- [ ] Ranking algorithm (exact > partial > description)
- [ ] Display formatting (command + description + example)
- [ ] Tests: `tests/command-search.test.zsh`
- [ ] Reference: `docs/reference/COMMAND-SEARCH-REFERENCE.md`
- [ ] Tutorial: `docs/guides/command-search-guide.md`
- [ ] Update: `docs/reference/COMMAND-QUICK-REFERENCE.md`
- [ ] Release: v5.2.0

**Search Index Format:**

```json
{
  "commands": [
    {
      "name": "work",
      "description": "Start a new project session",
      "keywords": ["work", "session", "start", "project", "switch"],
      "example": "work flow-cli",
      "dispatcher": false
    },
    {
      "name": "hop",
      "description": "Quick switch between projects (tmux-based)",
      "keywords": ["hop", "switch", "quick", "tmux"],
      "example": "hop nexus",
      "dispatcher": false
    },
    {
      "name": "g status",
      "description": "Show git repository status",
      "keywords": ["git", "status", "repo", "changes"],
      "example": "g status",
      "dispatcher": "g"
    }
  ]
}
```

---

### Sprint 3: Ecosystem Operations (Week 6-7) - 4 hours

**Deliverables:**

- [ ] New command file: `commands/ecosystem.zsh`
- [ ] Commands: detect, cascade, deps, impact, status
- [ ] Delegation to RForge MCP (when available)
- [ ] Graceful degradation (show install hint if no RForge)
- [ ] Tests: `tests/ecosystem.test.zsh`
- [ ] Reference: `docs/reference/ECOSYSTEM-OPERATIONS-REFERENCE.md`
- [ ] Tutorial: `docs/guides/ecosystem-operations-guide.md`
- [ ] Release: v5.3.0

**Command Delegation:**

```bash
# flow ecosystem detect → rforge:detect (MCP)
# flow ecosystem cascade → rforge:cascade (MCP)
# flow ecosystem deps → rforge:deps (MCP)
# flow ecosystem impact → rforge:impact (MCP)
# flow ecosystem status → rforge:status (MCP)
```

---

### Sprint 4: Multi-Project Workspaces + AI Energy (Week 8-12) - 24 hours

**Deliverables:**

- [ ] New command file: `commands/workspace.zsh`
- [ ] Commands: create, start, list, delete, status
- [ ] tmux integration (`_workspace_with_tmux()`)
- [ ] Fallback mode (`_workspace_fallback()`)
- [ ] Session persistence (save/restore workspace state)
- [ ] New file: `lib/energy-tracking.zsh` (AI-powered energy detection)
- [ ] Energy logging: `~/.local/share/flow/energy-logs.json`
- [ ] ML prediction: Time-based clustering (high/medium/low periods)
- [ ] Integration: `flow next` suggests tasks based on predicted energy
- [ ] Tests: `tests/workspace.test.zsh`, `tests/energy-tracking.test.zsh`
- [ ] Reference: `docs/reference/WORKSPACE-REFERENCE.md`, `docs/reference/ENERGY-TRACKING-REFERENCE.md`
- [ ] Tutorial: `docs/guides/workspace-guide.md`, `docs/guides/energy-aware-workflow.md`
- [ ] Privacy: Add `FLOW_ENERGY_TRACKING=no` opt-out
- [ ] Release: v5.4.0

**Workspace State:**

```json
{
  "name": "mcp-ecosystem",
  "projects": ["statistical-research", "nexus", "rforge"],
  "created": 1736419200,
  "tmux_session": "flow-workspace-mcp-ecosystem",
  "active": true
}
```

**Energy Log Entry:**

```json
{
  "timestamp": 1736419200,
  "hour": 15,
  "task": "Write documentation",
  "task_type": "low-focus",
  "completed": true,
  "duration_minutes": 45,
  "session_quality": "good"
}
```

---

## Key Architectural Changes

### 1. Workspace Fallback Mode (NEW)

**Impact:** +8 hours implementation time

**Design:**

```zsh
# Dual codepath detection
_workspace_start() {
    if command -v tmux >/dev/null 2>&1; then
        _workspace_with_tmux "$@"
    else
        _workspace_fallback "$@"
    fi
}

# tmux mode: Full feature set
_workspace_with_tmux() {
    local name=$1
    local projects=(...)

    # Create tmux session with multiple windows
    tmux new-session -d -s "flow-workspace-$name" ...
    tmux new-window ...
    tmux attach -t "flow-workspace-$name"
}

# Fallback mode: Simple picker
_workspace_fallback() {
    local name=$1
    local projects=(...)

    # Show numbered list
    echo "📦 Workspace: $name"
    echo "   Projects: ${projects[@]}"
    echo ""
    echo "Select project:"

    # Use pick-style selection
    for i in {1..${#projects[@]}}; do
        echo "  $i) ${projects[$i]}"
    done

    read "choice?Choice [1-${#projects[@]}/q]: "

    # cd to selected project
    local selected="${projects[$choice]}"
    work "$selected"
}
```

---

### 2. AI-Powered Energy Tracking (NEW)

**Impact:** +12 hours implementation time

**Design:**

```zsh
# lib/energy-tracking.zsh

# Log task completion
_energy_log_task() {
    local task=$1
    local task_type=$2
    local duration=$3
    local completed=$4

    local log_file="$FLOW_STATE_DIR/energy-logs.json"
    local timestamp=$(date +%s)
    local hour=$(date +%H)

    # Append to log
    local entry=$(cat <<EOF
{
  "timestamp": $timestamp,
  "hour": $hour,
  "task": "$task",
  "task_type": "$task_type",
  "completed": $completed,
  "duration_minutes": $duration
}
EOF
    )

    # Add to log array
    jq ". += [$entry]" "$log_file" > "$log_file.tmp"
    mv "$log_file.tmp" "$log_file"
}

# Predict energy level
_energy_predict() {
    local log_file="$FLOW_STATE_DIR/energy-logs.json"
    local current_hour=$(date +%H)

    # Analyze last 2 weeks of logs
    # Find patterns for current hour
    # Return: high, medium, or low

    if [[ ! -f "$log_file" ]]; then
        # No data yet - use time-based heuristic
        if [[ $current_hour -ge 9 && $current_hour -le 12 ]]; then
            echo "high"
        elif [[ $current_hour -ge 13 && $current_hour -le 16 ]]; then
            echo "low"
        else
            echo "medium"
        fi
        return
    fi

    # ML prediction: Cluster by hour, task success rate
    local prediction=$(jq -r "
        [.[] | select(.hour == $current_hour and .completed == true)] |
        group_by(.task_type) |
        map({type: .[0].task_type, count: length}) |
        sort_by(.count) |
        reverse |
        .[0].type
    " "$log_file")

    # Map task_type to energy level
    case "$prediction" in
        "high-focus") echo "high" ;;
        "medium-focus") echo "medium" ;;
        "low-focus") echo "low" ;;
        *) echo "medium" ;;
    esac
}

# Integration with 'flow next'
flow_next_energy_aware() {
    local energy_level=$(_energy_predict)

    echo "🤖 Predicted Energy: $(echo $energy_level | tr '[:lower:]' '[:upper:]') (based on recent patterns)"
    echo ""

    # Suggest tasks matching energy level
    # ...
}
```

**Data Collection Points:**

- `finish` command logs session (task, duration, completion)
- `win` command logs task completion (high energy indicator)
- `stuck` command logs abandonment (low energy indicator)
- Task types inferred from .STATUS file or user tags

**Privacy Controls:**

- `FLOW_ENERGY_TRACKING=no` disables logging
- `flow energy clear` deletes all logs
- All data stored locally (never sent anywhere)
- Opt-in to cloud backup (future: multi-device sync)

---

## Success Metrics

### v5.1.0 (Context Restoration)

- [ ] 80% reduction in "what was I doing?" overhead
- [ ] Restoration prompt shown on every `work` command
- [ ] User survey: 8/10 satisfaction with context restoration

### v5.2.0 (Command Search)

- [ ] Users discover 2-3 new commands per month
- [ ] 50% reduction in "how do I...?" support questions
- [ ] Search responds in < 100ms

### v5.3.0 (Ecosystem Operations)

- [ ] 40% of R package users adopt `flow ecosystem` commands
- [ ] 90% reduction in dependency tracking errors
- [ ] Successful cascade operations in 95% of cases

### v5.4.0 (Workspaces + AI Energy)

- [ ] 30% of users create named workspaces
- [ ] 50% reduction in manual project switching
- [ ] AI energy prediction accuracy: 75% after 2 weeks of data
- [ ] Users report energy-aware suggestions are helpful (7/10 score)

---

## Architecture Principles Maintained

All enhancements follow flow-cli's core principles:

✅ **Zero-Overhead:** Core commands (work, dash, pick) remain < 10ms
✅ **Optional Enhancement:** All features gracefully degrade
✅ **ADHD-Friendly:** Discoverable, consistent, forgiving, fast
✅ **Pure ZSH:** No Node.js runtime required
✅ **Consistent Patterns:** Same patterns as existing dispatchers
✅ **Privacy-Preserving:** All data stored locally, opt-out available

---

## Next Actions

### Immediate (Today)

1. ✅ Design decisions documented
2. [ ] Update `.STATUS` with v5.1.0 sprint goal
3. [ ] Create feature branch: `git checkout -b feature/context-restoration`
4. [ ] Create GitHub issues for each sprint (v5.1.0, v5.2.0, v5.3.0, v5.4.0)

### This Week (Sprint 1 Kickoff)

1. [ ] Create `lib/session-metadata.zsh` skeleton
2. [ ] Implement `_flow_capture_session_state()` function
3. [ ] Implement `_flow_restore_session_state()` function
4. [ ] Write unit tests for session capture/restore
5. [ ] Integrate into `commands/work.zsh`

### Next 3 Months (All 4 Sprints)

- **Week 3:** Release v5.1.0 (Context Restoration)
- **Week 5:** Release v5.2.0 (Command Search)
- **Week 7:** Release v5.3.0 (Ecosystem Operations)
- **Week 12:** Release v5.4.0 (Workspaces + AI Energy)

---

**Status:** Design decisions approved, ready for implementation
**Total Effort:** 46 hours over 12 weeks (4 incremental releases)
**Expected Impact:** 70-80% reduction in workflow friction

---

**Related Documents:**

- [Brainstorm: Workflow Review](./BRAINSTORM-flow-cli-workflow-review-2026-01-09.md)
- [Dotfile UX Design](./docs/specs/dotfile-ux-design.md)
- [Current .STATUS](./.STATUS)
