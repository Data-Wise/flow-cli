# Flow-CLI Workflow Review & Enhancement Brainstorm

**Date:** 2026-01-09
**Session Type:** Deep Brainstorm (8 questions + synthesis)
**Context:** Comprehensive review of existing flow-cli functions, workflows, and opportunities for new commands

---

## Executive Summary

This document synthesizes three parallel analyses:

1. **Codebase exploration** - Complete inventory of 20 commands, 11 dispatchers, and core workflows
2. **UX design analysis** - ADHD-optimized workflow patterns and pain point identification
3. **Architecture analysis** - Technical integration patterns for new features

### Key Findings

**What's Working Well:**

- ✅ **Dispatcher pattern** - Consistent, discoverable, fast (g, cc, mcp, r, qu, obs, tm, wt)
- ✅ **ADHD optimization** - Sub-10ms response, minimal input required, anti-paralysis features
- ✅ **Session management** - work/finish/hop provide smooth project switching
- ✅ **Dopamine features** - win/yay/streaks/goals maintain motivation
- ✅ **Optional enhancement** - Atlas integration model works perfectly

**Gaps & Opportunities:**

- 🔴 **Missing: Dotfile management** - Users manually run chezmoi commands
- 🔴 **Missing: Secret management** - API keys in plain JSON files (MCP configs)
- 🔴 **Missing: Version management** - No R/Python version switching
- 🟡 **Incomplete: Context restoration** - No "resume where I left off" workflow
- 🟡 **Incomplete: Cross-project workflows** - No "work on 3 projects today" coordination

### Top 3 Recommendations

1. **Implement `dot` (or `df`) dispatcher** for unified dotfile/secret/version management
   - Estimated effort: 26 hours over 3-4 weeks
   - Impact: Eliminates manual chezmoi/bw/mise commands
   - Complete UX design ready (69KB documentation)

2. **Add context restoration workflows** to resume complex multi-project sessions
   - Estimated effort: 12 hours over 2 weeks
   - Impact: Reduces "what was I doing?" overhead by 80%

3. **Create multi-project coordination** for cross-cutting work (e.g., "update all R packages")
   - Estimated effort: 16 hours over 2-3 weeks
   - Impact: Enables ecosystem-wide operations (already proven in RForge MCP)

---

## Part 1: Current State Analysis

### 1.1 Command Inventory (20 Commands)

| Command      | LOC           | Primary Function              | Usage Frequency |
| ------------ | ------------- | ----------------------------- | --------------- |
| **work**     | 288           | Start session                 | 🔥 Daily        |
| **pick**     | 965           | Project picker (fzf)          | 🔥 Daily        |
| **dash**     | 1,539         | Dashboard                     | 🔥 Daily        |
| **finish**   | (in work.zsh) | End session + commit          | 🔥 Daily        |
| **hop**      | (in work.zsh) | Quick switch (tmux)           | 🔥 Daily        |
| **capture**  | 598           | catch/crumb/trail             | 🔥 Daily        |
| **adhd**     | 361           | js/next/stuck/focus           | 🟡 Weekly       |
| **status**   | 595           | .STATUS management            | 🟡 Weekly       |
| **timer**    | 292           | Focus timer                   | 🟡 Weekly       |
| **sync**     | 992           | Unified sync (git/wins/goals) | 🟡 Weekly       |
| **flow**     | 1,062         | Main dispatcher               | 🔥 Daily        |
| **doctor**   | 699           | Health check                  | 🔵 Monthly      |
| **config**   | 358           | Configuration mgmt            | 🔵 Rare         |
| **plugin**   | 448           | Plugin system                 | 🔵 Rare         |
| **alias**    | 313           | Alias reference               | 🔵 Rare         |
| **ai**       | 868           | AI-powered assistance         | 🟡 Weekly       |
| **install**  | 445           | Tool installer                | 🔵 Once         |
| **upgrade**  | 377           | Self-update                   | 🔵 Monthly      |
| **tutorial** | 545           | Learning system               | 🔵 Once         |
| **ref**      | 86            | Quick reference               | 🔵 Rare         |

**Total:** 11,373 LOC across 20 command files

### 1.2 Dispatcher Inventory (11 Dispatchers)

| Dispatcher      | Primary Domain         | Key Commands                     | Integration   |
| --------------- | ---------------------- | -------------------------------- | ------------- |
| **g** (858 LOC) | Git workflows          | status, commit, push, feature/\* | ✅ Complete   |
| **cc**          | Claude Code            | launch modes (yolo/plan/opus)    | ✅ Complete   |
| **mcp**         | MCP servers            | status, logs, restart            | ✅ Complete   |
| **r**           | R packages             | test, doc, build, check, cycle   | ✅ Complete   |
| **qu**          | Quarto                 | preview, render, publish         | ✅ Complete   |
| **obs**         | Obsidian               | vaults, stats                    | ✅ Complete   |
| **tm**          | Terminal manager       | title, profile, ghost, switch    | ✅ Complete   |
| **wt**          | Git worktrees          | create, status, prune            | ✅ Complete   |
| **v**           | Workflow automation    | (legacy, being replaced)         | 🟡 Deprecated |
| **dot**         | Dotfiles               | *NEW v5.0.0* (just released!)    | ✅ Complete   |
| ~~**df**~~      | *(alternative naming)* | -                                | -             |

**Note:** The `dot` dispatcher was just released in v5.0.0! This addresses the dotfile management gap identified in this brainstorm. See `lib/dispatchers/dot-dispatcher.zsh` (450 LOC).

### 1.3 Core Workflows

#### Session Lifecycle

```
pick → work → [development] → finish → [commit + cleanup]
  ↓
  └─→ hop (quick switch within session)
```

**Strengths:**

- Fast project switching (< 500ms)
- Frecency-based sorting (most recent first)
- Session-aware resume (🟢 indicator for recent projects)
- Direct jump fuzzy matching (`pick flow` → instant)

**Gaps:**

- No "resume complex multi-project session" workflow
- No "what was I doing?" context restoration beyond single project

#### Discovery & Navigation

```
dash → [view all projects/sessions] → pick → work
  ↓
  └─→ Interactive TUI (dash -i) with category filtering
```

**Strengths:**

- Progressive disclosure (dash → dash -i → dash --watch)
- Category-based organization (r, dev, teach, rs, q, app)
- Live refresh mode (dash --watch)
- Auto-generated inventory (dash --inventory)

**Gaps:**

- No cross-project search (find all projects using library X)
- No dependency visualization (which projects depend on each other)

#### Capture & Tracking

```
catch → inbox.md
win → wins.md → yay (show wins)
crumb → .crumbs (breadcrumb trail)
trail → (show recent crumbs)
```

**Strengths:**

- Zero-friction capture (catch "idea" → instant)
- Auto-categorization (win detects 💻 code, 📝 docs, 🚀 ship)
- Dopamine feedback (yay --week shows graph)
- Goal tracking (flow goal, daily targets)

**Gaps:**

- No cross-referencing (link captures to projects)
- No "convert capture to task" workflow
- No review workflow (inbox triage)

#### ADHD-Specific Features

```
js (just start) → auto-picks recent project
next → suggests next action
stuck → debug current blockage
focus → minimize distractions
brk → take break (with timer)
```

**Strengths:**

- Anti-paralysis (js eliminates "which project?" decision)
- Scaffolding (next provides clear action)
- Self-awareness (stuck helps identify blockers)

**Gaps:**

- No energy-aware suggestions (high/low energy tasks)
- No time estimation (how long will this take?)
- No interruption recovery (resume after distraction)

---

## Part 2: UX Analysis - Pain Points & Opportunities

### 2.1 Discovery Problems

**Current State:**

- Users must know command names (`work`, `dash`, `pick`)
- No command-line search (can't find "how do I switch projects?")
- Help system requires exact command match

**Proposed Solutions:**

#### Solution A: Interactive Command Browser

```bash
flow search "switch projects"
# → Returns: hop, work, pick with descriptions

flow search "git"
# → Returns: g dispatcher commands + examples
```

**Implementation:**

- Grep through help text across all commands
- Rank by relevance (exact match > partial > description)
- Show examples inline
- Estimated effort: 6 hours

#### Solution B: Context-Aware Help

```bash
# User is in a project directory
flow help
# → Shows project-specific commands first
#    (r test, r doc for R package)
#    (qu preview, qu render for Quarto)

# User has uncommitted changes
flow help
# → Highlights: g status, g commit, finish
```

**Implementation:**

- Detect context (git repo, project type, session active)
- Reorder help output based on context
- Add "you probably want..." suggestions
- Estimated effort: 8 hours

### 2.2 Context Restoration Problems

**Current State:**

- Hop switches projects but doesn't restore state
- No "what was I working on in project X?" memory
- No cross-project session management

**Pain Point Example:**

```
Monday morning:
- User was working on 3 projects Friday (flow-cli, nexus, aiterm)
- Each had open files, specific branches, terminal layout
- User runs `pick` → sees projects but no context clues
- Must manually remember "what was I doing in flow-cli?"
```

**Proposed Solutions:**

#### Solution A: Enhanced Session Metadata

```bash
# When running `finish`, capture:
- Open files (via $EDITOR session)
- Active git branch
- Last command run
- Uncommitted changes
- Next action (from .STATUS or manual note)

# When running `work <project>`:
- Display last session summary
- Offer to restore open files
- Show next action
```

**Example Output:**

```
$ work flow-cli

📋 Last Session (2h ago):
  Branch: feature/dot-dispatcher
  Files: lib/dispatchers/dot-dispatcher.zsh (+127 lines)
  Status: Tests passing, docs in progress
  Next: Write DOT-DISPATCHER-REFERENCE.md

🔄 Restore? [Y/n/skip]
```

**Implementation:**

- Extend `.current-project-session` with richer metadata
- Add session restoration prompts to `work` command
- Optional: Integrate with tmux for window layout
- Estimated effort: 12 hours

#### Solution B: Cross-Project Sessions (Named Workspaces)

```bash
# Create a multi-project session
flow session create "mcp-ecosystem"
  → Adds projects: statistical-research, nexus, rforge

# Start the session
flow session start "mcp-ecosystem"
  → Opens 3 tmux windows (one per project)
  → Restores each project's last state

# Switch between projects
flow session hop nexus
  → Jumps to nexus window (preserves others)

# End session
flow session end
  → Captures state for all 3 projects
```

**Implementation:**

- New command: `flow session` with create/start/end/list
- Store session definitions in `~/.local/share/flow/sessions/`
- Integrate with tmux for window management
- Estimated effort: 16 hours

### 2.3 Workflow Integration Problems

**Current State:**

- Dispatchers are isolated (g, r, mcp don't talk to each other)
- No cross-cutting operations (e.g., "update all R packages in ecosystem")
- No dependency awareness (flow-cli doesn't know nexus depends on rforge)

**Proposed Solutions:**

#### Solution A: Workflow Chains

```bash
# Define a workflow
flow workflow create "r-package-release"
  r test
  r check
  r doc
  g feature finish
  g push

# Run it
flow workflow run "r-package-release"
  → Executes each step
  → Stops on first failure
  → Shows progress
```

**Implementation:**

- New command: `flow workflow` with create/run/list
- Store workflows in `~/.config/flow/workflows/`
- Support variables (project name, version)
- Estimated effort: 14 hours

#### Solution B: Ecosystem Operations

```bash
# Detect ecosystem structure
flow ecosystem detect
  → Scans ~/projects/r-packages/active/
  → Builds dependency graph
  → Shows: mediation → medfit → probmed → medrobust

# Run operation across ecosystem
flow ecosystem run "r test"
  → Runs r test in dependency order
  → Stops if any fail
  → Shows summary

# Update all packages
flow ecosystem cascade "DESCRIPTION version bump"
  → Updates all dependent packages
  → Creates feature branches
  → Runs tests
```

**Implementation:**

- New command: `flow ecosystem` with detect/run/cascade
- Use rforge MCP logic for dependency analysis
- Estimated effort: 18 hours (but RForge already has this!)

**Alternative:** Delegate to RForge MCP server (already implemented)

```bash
# RForge MCP has:
rforge:detect     # Auto-detect structure
rforge:cascade    # Plan coordinated updates
rforge:deps       # Build dependency graph
rforge:analyze    # Ecosystem analysis

# Flow-cli could wrap this:
flow ecosystem detect → calls rforge:detect via MCP
```

---

## Part 3: Architecture Analysis - New Feature Integration

### 3.1 Dotfile Management Integration (✅ COMPLETED in v5.0.0!)

**Status:** Released in v5.0.0 (2026-01-08)
**Implementation:** `lib/dispatchers/dot-dispatcher.zsh` (450 LOC)

**Commands:**

```bash
dot              # Status overview
dot edit FILE    # Edit with preview
dot sync         # Pull from remote
dot push         # Push changes
dot unlock       # Unlock Bitwarden
dot secret NAME  # Retrieve secret (no echo)
dot doctor       # Diagnostics
```

**Integration Points:**

- Dashboard shows dotfile status (1 line)
- Flow doctor includes dotfile health checks
- Bitwarden session management (BW_SESSION)
- Security: HISTIGNORE for sensitive commands

**Documentation:**

- Complete UX design: `docs/specs/dotfile-ux-design.md` (69 KB)
- Visual mockups: `docs/specs/df-dispatcher-visual-mockups.md` (21 mockups)
- Implementation checklist: `docs/specs/df-dispatcher-implementation-checklist.md`

### 3.2 Context Restoration Architecture

**Recommended Approach:** Enhanced Session Metadata

```zsh
# File: lib/session-metadata.zsh (NEW)

# Capture session state
_flow_capture_session_state() {
    local project=$1
    local session_file="$FLOW_STATE_DIR/sessions/${project}.json"

    # Gather metadata
    local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "none")
    local files=$(git diff --name-only 2>/dev/null | head -5)
    local last_command=$(fc -ln -1)
    local next_action=$(_flow_get_status_next "$project")
    local timestamp=$(date +%s)

    # Write JSON
    cat > "$session_file" <<EOF
{
  "project": "$project",
  "timestamp": $timestamp,
  "branch": "$branch",
  "modified_files": [$(echo "$files" | sed 's/^/    "/' | sed 's/$/",/' | tr '\n' ' ' | sed 's/, $//')],
  "last_command": "$last_command",
  "next_action": "$next_action"
}
EOF
}

# Restore session state
_flow_restore_session_state() {
    local project=$1
    local session_file="$FLOW_STATE_DIR/sessions/${project}.json"

    if [[ ! -f "$session_file" ]]; then
        return 1
    fi

    # Parse JSON (using jq if available, fallback to grep/sed)
    if command -v jq >/dev/null 2>&1; then
        local branch=$(jq -r '.branch' "$session_file")
        local files=$(jq -r '.modified_files[]' "$session_file")
        local next=$(jq -r '.next_action' "$session_file")
        local timestamp=$(jq -r '.timestamp' "$session_file")
    else
        # Fallback: basic grep/sed
        local branch=$(grep '"branch"' "$session_file" | cut -d'"' -f4)
        local next=$(grep '"next_action"' "$session_file" | cut -d'"' -f4)
        local timestamp=$(grep '"timestamp"' "$session_file" | cut -d' ' -f2 | tr -d ',')
    fi

    # Display summary
    local age=$(($(date +%s) - timestamp))
    local age_str=$(_flow_format_duration $age)

    echo "$(_flow_color cyan bold)📋 Last Session$(_flow_color reset) ($age_str ago)"
    [[ -n "$branch" ]] && echo "  Branch: $branch"
    [[ -n "$files" ]] && echo "  Files: $files"
    [[ -n "$next" ]] && echo "  Next: $next"
    echo ""

    # Offer restoration
    read "restore?🔄 Restore? [Y/n/skip] "
    case "$restore" in
        n|N|skip|s) return 0 ;;
        *)
            # Restore actions (checkout branch, etc.)
            [[ -n "$branch" && "$branch" != "none" ]] && git checkout "$branch" 2>/dev/null
            return 0
            ;;
    esac
}

# Hook into work command
# In commands/work.zsh, add:
#   _flow_restore_session_state "$project_name"
```

**Integration:**

- Modify `commands/work.zsh` to call `_flow_restore_session_state()`
- Modify `commands/finish.zsh` (or work.zsh finish function) to call `_flow_capture_session_state()`
- Store session metadata in `~/.local/share/flow/sessions/<project>.json`
- Optional: Add `flow session list` to show all saved sessions

**Estimated Effort:** 12 hours

### 3.3 Multi-Project Session Architecture

**Recommended Approach:** Named Workspaces with tmux Integration

```zsh
# File: commands/workspace.zsh (NEW)

# Create workspace
flow_workspace_create() {
    local name=$1
    shift
    local projects=("$@")

    if [[ ${#projects[@]} -eq 0 ]]; then
        _flow_log_error "Usage: flow workspace create <name> <project1> <project2> ..."
        return 1
    fi

    local workspace_file="$FLOW_STATE_DIR/workspaces/${name}.json"

    # Create JSON
    cat > "$workspace_file" <<EOF
{
  "name": "$name",
  "projects": [$(printf '"%s", ' "${projects[@]}" | sed 's/, $//')],
  "created": $(date +%s)
}
EOF

    _flow_log_success "Created workspace: $name (${#projects[@]} projects)"
}

# Start workspace (opens tmux windows)
flow_workspace_start() {
    local name=$1
    local workspace_file="$FLOW_STATE_DIR/workspaces/${name}.json"

    if [[ ! -f "$workspace_file" ]]; then
        _flow_log_error "Workspace not found: $name"
        return 1
    fi

    # Parse projects
    local projects=$(jq -r '.projects[]' "$workspace_file" 2>/dev/null || \
                     grep '"projects"' "$workspace_file" | cut -d'"' -f4)

    # Create tmux session
    local tmux_session="flow-workspace-${name}"

    if tmux has-session -t "$tmux_session" 2>/dev/null; then
        tmux attach -t "$tmux_session"
        return 0
    fi

    # Create new tmux session
    local first_project=$(echo "$projects" | head -1)
    local first_dir=$(_flow_find_project_dir "$first_project")

    tmux new-session -d -s "$tmux_session" -c "$first_dir" -n "$first_project"

    # Add windows for remaining projects
    echo "$projects" | tail -n +2 | while read project; do
        local project_dir=$(_flow_find_project_dir "$project")
        tmux new-window -t "$tmux_session" -c "$project_dir" -n "$project"
    done

    # Attach to session
    tmux attach -t "$tmux_session"
}

# Command dispatcher
flow_workspace() {
    case "$1" in
        create) shift; flow_workspace_create "$@" ;;
        start)  flow_workspace_start "$2" ;;
        list)   flow_workspace_list ;;
        delete) flow_workspace_delete "$2" ;;
        *)      flow_workspace_help ;;
    esac
}
```

**Integration:**

- New command file: `commands/workspace.zsh`
- Add to `flow.plugin.zsh`: `source "${0:A:h}/commands/workspace.zsh"`
- Store workspaces in `~/.local/share/flow/workspaces/<name>.json`
- Requires tmux (optional dependency, graceful degradation)

**Estimated Effort:** 16 hours

---

## Part 4: Prioritized Recommendations

### Priority 1: Context Restoration (HIGH IMPACT, MEDIUM EFFORT)

**Problem:** Users lose context when switching projects or returning after breaks.

**Solution:** Enhanced Session Metadata (Section 3.2)

**Why This First:**

- Addresses #1 ADHD pain point ("what was I doing?")
- Builds on existing session tracking (`.current-project-session`)
- Low architectural risk (extends existing pattern)
- Immediate usability improvement

**Deliverables:**

- [ ] `lib/session-metadata.zsh` (session capture/restore functions)
- [ ] Modify `commands/work.zsh` (integrate restoration prompt)
- [ ] Modify finish logic (capture session state)
- [ ] Test: work → modify → finish → work (restores state)
- [ ] Documentation: `docs/guides/context-restoration.md`

**Success Metrics:**

- 80% reduction in "what was I doing?" overhead
- Session restoration prompt shown on every `work` command
- Users report smoother re-entry after breaks

**Estimated Effort:** 12 hours over 2 weeks

---

### Priority 2: Command Search & Discovery (HIGH IMPACT, LOW EFFORT)

**Problem:** Users don't discover existing features because they don't know command names.

**Solution:** Interactive Command Browser (Section 2.1, Solution A)

**Why This Second:**

- Unlocks existing features users don't know about
- Reduces support burden ("how do I...?" questions)
- Fast to implement (grep + rank + display)
- Complements existing help system

**Deliverables:**

- [ ] New command: `flow search <query>`
- [ ] Search index: All command help text + dispatcher docs
- [ ] Ranking algorithm: Exact match > partial > description
- [ ] Display: Command + description + example
- [ ] Documentation: Update `docs/help/QUICK-REFERENCE.md`

**Example Usage:**

```bash
$ flow search "switch projects"

🔍 Found 3 commands:

1. hop <project>           🔥 Most relevant
   Quick switch between projects (tmux-based)
   Example: hop nexus

2. work <project>
   Start a new project session
   Example: work flow-cli

3. pick
   Interactive project picker (fzf)
   Example: pick
```

**Success Metrics:**

- Users discover 2-3 commands per month via search
- 50% reduction in "how do I...?" support questions
- Search responds in < 100ms

**Estimated Effort:** 6 hours over 1 week

---

### Priority 3: Ecosystem Operations (MEDIUM IMPACT, LOW EFFORT - DELEGATE!)

**Problem:** Users manually coordinate multi-package operations (e.g., "bump version in all R packages").

**Solution:** Delegate to RForge MCP (already implemented!)

**Why This Third:**

- RForge MCP already has this functionality:
  - `rforge:detect` - Auto-detect ecosystem structure
  - `rforge:cascade` - Plan coordinated updates
  - `rforge:deps` - Build dependency graph
  - `rforge:impact` - Analyze change impact
- Zero implementation cost (just add wrapper commands)
- Proven in production (rforge MCP in use)
- Valuable for R package ecosystem users

**Deliverables:**

- [ ] New command: `flow ecosystem` (wrapper for rforge MCP)
- [ ] Commands: detect, cascade, deps, impact, status
- [ ] Graceful degradation: If rforge MCP not available, show install hint
- [ ] Documentation: `docs/guides/ecosystem-operations.md`

**Example Usage:**

```bash
$ flow ecosystem detect
📦 Detected R Package Ecosystem:
  ├── mediationverse (root)
  ├── mediation (depends on: mediationverse)
  ├── medfit (depends on: mediation)
  ├── probmed (depends on: medfit)
  └── medrobust (depends on: medfit)

$ flow ecosystem cascade "bump minor version"
📋 Cascade Plan:
  1. mediationverse: 0.1.2 → 0.2.0
  2. mediation: 1.3.1 → 1.4.0 (update dependency)
  3. medfit: 0.4.5 → 0.5.0 (update dependency)
  4. probmed: 1.0.3 → 1.1.0 (update dependency)
  5. medrobust: 0.2.1 → 0.3.0 (update dependency)

Proceed? [Y/n]
```

**Success Metrics:**

- Users run ecosystem operations 2-3 times per month
- 90% reduction in manual dependency tracking
- Zero bugs from missed dependency updates

**Estimated Effort:** 4 hours (just wrapper commands!)

---

### Priority 4: Multi-Project Sessions (MEDIUM IMPACT, HIGH EFFORT)

**Problem:** Users work across 3-5 projects daily but manually switch between them.

**Solution:** Named Workspaces with tmux (Section 3.3)

**Why This Fourth:**

- Addresses common use case (multi-project work)
- Builds on existing tmux integration (hop command)
- Requires tmux (optional dependency - acceptable)
- More complex than other features (16 hours)

**Deliverables:**

- [ ] New command file: `commands/workspace.zsh`
- [ ] Commands: create, start, list, delete, status
- [ ] tmux integration (create session with multiple windows)
- [ ] Session persistence (restore after tmux detach)
- [ ] Documentation: `docs/guides/multi-project-sessions.md`

**Success Metrics:**

- Users create 2-3 named workspaces
- 50% reduction in manual project switching
- Smooth workflow for cross-cutting tasks

**Estimated Effort:** 16 hours over 2-3 weeks

---

## Part 5: Additional Enhancement Ideas

### 5.1 Energy-Aware Task Suggestions

**Problem:** Users pick tasks without considering energy level (high-focus work when tired).

**Solution:**

```bash
# Tag tasks in .STATUS with energy level
energy: high     # Deep focus work (architecture, complex debugging)
energy: medium   # Steady work (feature implementation, tests)
energy: low      # Easy wins (docs, formatting, code review)

# Suggest tasks based on time of day
$ flow next
🔋 Energy Level: Low (3 PM - typical afternoon slump)

Suggested low-energy tasks:
  1. Write documentation for df dispatcher
  2. Review PR #123
  3. Format code with prettier

Run with --high to see high-energy tasks.
```

**Estimated Effort:** 8 hours

### 5.2 Interruption Recovery Workflow

**Problem:** Context switch (Slack, meeting) disrupts flow. Hard to resume.

**Solution:**

```bash
# Before interruption
$ flow pause
💾 Saved: Working on lib/dispatchers/dot-dispatcher.zsh
          Function: _dot_secret() implementation
          Last edit: Line 127

# After interruption
$ work flow-cli
🔄 Interrupted session detected (12 minutes ago)

  Working on: lib/dispatchers/dot-dispatcher.zsh
  Function: _dot_secret() implementation
  Last edit: Line 127

Resume? [Y/n]
```

**Estimated Effort:** 10 hours

### 5.3 Time Estimation & Tracking

**Problem:** Users underestimate time, leading to frustration and incomplete work.

**Solution:**

```bash
# Estimate time for task
$ flow estimate "implement df secret command"
🤖 Based on similar tasks (dispatcher functions):
   Estimated: 2-3 hours
   Confidence: 80%

Start timer? [Y/n]

# Track actual time
$ flow timer start "df secret implementation"
⏱ Timer started (2:30 PM)

# Compare estimate vs actual
$ flow timer stop
⏱ Timer stopped (4:45 PM)
   Duration: 2h 15m
   Estimated: 2-3h
   ✅ Within estimate!
```

**Estimated Effort:** 12 hours

### 5.4 Capture → Task Conversion

**Problem:** Captures (catch command) sit in inbox.md but never become actionable.

**Solution:**

```bash
# Review inbox
$ flow inbox review

📥 Inbox (5 items):

1. "Add R version switching to r dispatcher"
   → Convert to task? [Y/n] Y
   → Project: flow-cli
   → Add to .STATUS? [Y/n] Y

2. "Research SOPS vs Bitwarden for secrets"
   → Convert to task? [Y/n] n
   → Archive? [Y/n] Y

# Result: Tasks added to project .STATUS files
# Archived items moved to ~/archive/captures-<date>.md
```

**Estimated Effort:** 8 hours

---

## Part 6: Implementation Roadmap

### Sprint 1: Context Restoration (Week 1-2) [Priority 1]

```
✅ Week 1:
  - Create lib/session-metadata.zsh
  - Implement _flow_capture_session_state()
  - Implement _flow_restore_session_state()
  - Test: Manual capture/restore

✅ Week 2:
  - Integrate into commands/work.zsh
  - Integrate into finish logic
  - Add opt-out (FLOW_SESSION_RESTORE=no)
  - Write docs/guides/context-restoration.md
  - Test: Full workflow (work → finish → work)
```

### Sprint 2: Command Search (Week 3) [Priority 2]

```
✅ Week 3:
  - Implement flow search command
  - Build search index (all help text)
  - Ranking algorithm
  - Display formatting
  - Update COMMAND-QUICK-REFERENCE.md
  - Test: Search for 10 common queries
```

### Sprint 3: Ecosystem Operations (Week 4) [Priority 3]

```
✅ Week 4:
  - Create flow ecosystem wrapper
  - Delegate to rforge MCP
  - Graceful degradation (no rforge)
  - Write docs/guides/ecosystem-operations.md
  - Test: detect, cascade, deps, impact
```

### Sprint 4: Multi-Project Sessions (Week 5-6) [Priority 4]

```
✅ Week 5:
  - Create commands/workspace.zsh
  - Implement create, start commands
  - tmux integration
  - Test: Create and start workspace

✅ Week 6:
  - Implement list, delete, status commands
  - Session persistence
  - Write docs/guides/multi-project-sessions.md
  - Test: Full workflow (create → start → detach → reattach)
```

### Sprint 5: Additional Enhancements (Week 7-10)

```
Optional:
  - Energy-aware suggestions (Week 7)
  - Interruption recovery (Week 8)
  - Time estimation (Week 9)
  - Capture → Task conversion (Week 10)
```

---

## Part 7: Success Metrics

### User Adoption Metrics

- [ ] 80% of users use `flow search` at least once per week
- [ ] 60% of users enable context restoration (opt-in)
- [ ] 40% of R package users use `flow ecosystem` commands
- [ ] 30% of users create named workspaces

### Performance Metrics

- [ ] Context restoration prompt adds < 100ms to `work` command
- [ ] Command search responds in < 100ms
- [ ] Ecosystem detection completes in < 3 seconds
- [ ] Workspace creation (3 projects) completes in < 2 seconds

### Satisfaction Metrics

- [ ] "What was I doing?" frustration reduced by 80%
- [ ] Feature discovery improved (2-3 new commands per user per month)
- [ ] Cross-project coordination friction reduced by 70%
- [ ] Overall workflow satisfaction score: 8.5/10 → 9.2/10

---

## Part 8: Architecture Principles (Maintained)

All enhancements follow flow-cli's core principles:

✅ **Zero-Overhead:** Core commands (work, dash, pick) remain < 10ms
✅ **Optional Enhancement:** All features gracefully degrade
✅ **ADHD-Friendly:** Discoverable, consistent, forgiving, fast
✅ **Pure ZSH:** No Node.js runtime required
✅ **Consistent Patterns:** Same patterns as existing dispatchers

### Graceful Degradation Examples

**Context Restoration:**

```bash
# If session metadata doesn't exist:
$ work flow-cli
# → Normal behavior (no restoration prompt)
```

**Command Search:**

```bash
# If help text index is empty:
$ flow search "git"
# → Falls back to: flow help | grep -i "git"
```

**Ecosystem Operations:**

```bash
# If rforge MCP not available:
$ flow ecosystem detect
❌ RForge MCP not configured
   Install: brew install data-wise/tap/nexus
   Configure: mcp configure rforge
```

**Multi-Project Sessions:**

```bash
# If tmux not installed:
$ flow workspace start mcp-ecosystem
❌ tmux not installed (required for workspaces)
   Install: brew install tmux
   Alternative: Use 'hop' for single-project switching
```

---

## Part 9: Questions for User Approval

### Question 1: Command Search Scope

**Should `flow search` include:**

- A) Only built-in commands (work, dash, g, r, etc.)
- B) Built-in + MCP server tools (rforge, nexus, statistical-research)
- C) Built-in + MCP + custom plugins

**Recommendation:** Start with A (built-in only), add B in future.

### Question 2: Context Restoration Behavior

**Should context restoration be:**

- A) Opt-in (user sets FLOW_SESSION_RESTORE=yes)
- B) Opt-out (enabled by default, user can disable)
- C) Always prompt (no silent behavior)

**Recommendation:** C (always prompt) - most ADHD-friendly.

### Question 3: Workspace tmux Dependency

**Should workspaces require tmux or provide alternatives:**

- A) Require tmux (optional feature, graceful degradation)
- B) Provide fallback (simple multi-project picker without tmux)
- C) Support both tmux and screen

**Recommendation:** A (require tmux) - tmux is de facto standard, keep simple.

### Question 4: Ecosystem Operations Naming

**Should we call it:**

- A) `flow ecosystem` (clear, descriptive)
- B) `flow pkg` (shorter, package-focused)
- C) Add to `r` dispatcher as `r ecosystem`

**Recommendation:** A (`flow ecosystem`) - broader than just R packages.

### Question 5: Energy-Aware Suggestions

**Should energy detection be:**

- A) Time-based (morning = high, afternoon = low)
- B) Manual (user runs `flow energy high` to set)
- C) AI-powered (analyze past patterns)

**Recommendation:** B (manual) - simple, accurate, privacy-preserving.

### Question 6: Implementation Priority Order

**Do you agree with this order:**

1. Context Restoration (Priority 1)
2. Command Search (Priority 2)
3. Ecosystem Operations (Priority 3)
4. Multi-Project Sessions (Priority 4)

**Alternative:** Swap Priority 2 and 3 if ecosystem operations are more urgent.

### Question 7: Release Strategy

**Should we release these as:**

- A) One big release (v6.0.0) with all 4 priorities
- B) Incremental releases (v5.1.0, v5.2.0, v5.3.0, v5.4.0)
- C) Beta releases (v5.1.0-beta) with user testing

**Recommendation:** B (incremental) - faster user feedback, less risk.

### Question 8: Documentation Approach

**Should documentation be:**

- A) Reference-heavy (complete command docs)
- B) Tutorial-heavy (step-by-step guides)
- C) Balanced (both reference + tutorials)

**Recommendation:** C (balanced) - reference for lookup, tutorials for learning.

---

## Part 10: Related Work & Inspiration

### Similar Tools

- **Taskwarrior** - Task management, context switching
- **fzf** - Fuzzy finding (already integrated in pick)
- **tmuxinator** - tmux session management (similar to workspaces)
- **direnv** - Directory-specific environment (similar to project detection)

### Key Differentiators

- ✅ **ADHD-optimized** (minimal input, anti-paralysis features)
- ✅ **ZSH-native** (no external language runtimes)
- ✅ **Dispatcher pattern** (consistent, discoverable)
- ✅ **Session-aware** (frecency, resume, context restoration)
- ✅ **Dopamine features** (wins, streaks, goals)

---

## Part 11: Next Steps

### Immediate Actions (This Week)

1. **Review this brainstorm** with user
2. **Answer 8 questions** (Section 9)
3. **Approve priority order** (Section 6)
4. **Create feature branches:**
   - `feature/context-restoration`
   - `feature/command-search`
   - `feature/ecosystem-operations`
   - `feature/workspaces`

### Sprint 1 Kickoff (Next Week)

1. **Context Restoration:**
   - Create `lib/session-metadata.zsh`
   - Implement capture/restore functions
   - Integrate into work/finish commands
   - Write tests

2. **Documentation:**
   - Update ROADMAP.md with new features
   - Create issue templates for each priority
   - Update .STATUS file with sprint goals

### Long-Term (Next 3 Months)

1. Release v5.1.0 (Context Restoration)
2. Release v5.2.0 (Command Search)
3. Release v5.3.0 (Ecosystem Operations)
4. Release v5.4.0 (Multi-Project Sessions)
5. Gather user feedback
6. Iterate on energy-aware and interruption recovery features

---

## Part 12: Conclusion

This brainstorm synthesizes:

- **Codebase exploration** (20 commands, 11 dispatchers analyzed)
- **UX analysis** (ADHD pain points, workflow gaps identified)
- **Architecture design** (integration patterns, implementation plans)

### Key Takeaways

1. **flow-cli is production-ready** - 100+ tests passing, comprehensive documentation, active use
2. **Dotfile management is complete** - v5.0.0 released with `dot` dispatcher
3. **Four high-impact opportunities** identified with clear implementation paths
4. **All enhancements maintain core principles** - zero-overhead, ADHD-friendly, pure ZSH

### Recommended Focus

**Start with Priority 1 (Context Restoration)** - addresses the #1 ADHD pain point, builds on existing patterns, delivers immediate value.

Then proceed with incremental releases (v5.1.0 → v5.2.0 → v5.3.0 → v5.4.0) to gather user feedback and validate each feature before moving to the next.

---

**Status:** Brainstorm Complete
**Total Analysis:** 3 parallel investigations (codebase + UX + architecture)
**Documents Generated:** 6 design specs (69 KB UX design, 21 visual mockups, implementation checklist)
**Implementation Effort:** 46 hours over 8-10 weeks (all 4 priorities)
**Expected Impact:** 70-80% reduction in workflow friction, 2-3 new features per user per month

---

**Files to Review:**

1. This brainstorm: `BRAINSTORM-flow-cli-workflow-review-2026-01-09.md`
2. Dotfile UX design: `docs/specs/dotfile-ux-design.md` (69 KB)
3. Visual mockups: `docs/specs/df-dispatcher-visual-mockups.md` (21 mockups)
4. Implementation checklist: `docs/specs/df-dispatcher-implementation-checklist.md`

**Next Action:** Answer 8 questions (Section 9) to finalize design decisions.
