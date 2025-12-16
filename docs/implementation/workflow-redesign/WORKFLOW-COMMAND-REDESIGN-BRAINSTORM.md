# Workflow Command Redesign Brainstorm

**Date:** 2025-12-14
**Issue:** Current command design is confusing - need clearer patterns and smart defaults
**Goal:** Reduce cognitive load, make commands more intuitive and context-aware

---

## 🎯 Core Problem

**User feedback:** "It's a bit confusing"

**Key confusion points:**
1. When to use keywords vs options?
2. `status` requires explicit project name (not context-aware)
3. Unclear relationship between `dash`, `status`, `js`, `work`
4. Too many decisions required
5. Not taking advantage of current location

---

## 💡 Proposal A: Smart Defaults (Recommended)

**Philosophy:** Commands should "do the right thing" based on context

### `status` - Context-Aware Status Management

**Current behavior:**
```bash
status mediationverse          # Must specify project
status medfit active P1 "Task" 60
```

**Proposed behavior:**
```bash
# Smart detection based on PWD
status                         # If in project with .STATUS → show it
status                         # If in project without .STATUS → offer to create
status                         # If not in project → fuzzy picker of all projects

# Quick updates (context-aware)
status active P0 "Task" 85     # Updates current project if in one
status medfit active P0 "Task" 85  # Explicit project name

# Special keywords
status --list                  # List all projects with status (like dash)
status --create                # Force create mode
status --show                  # Force show mode for current project
```

**Implementation:**
```zsh
status() {
    local current_dir="$PWD"

    # Case 1: No args - smart detection
    if [[ $# -eq 0 ]]; then
        if [[ -f "$current_dir/.STATUS" ]]; then
            # Show current project's status
            _status_show "$current_dir"
        elif _is_project_dir "$current_dir"; then
            # Offer to create .STATUS
            echo "📋 No .STATUS file found. Create one? (y/n)"
            _status_create "$current_dir"
        else
            # Launch fuzzy picker
            _status_picker
        fi
        return
    fi

    # Case 2: First arg is status keyword (active/paused/blocked/ready)
    if [[ "$1" =~ ^(active|paused|blocked|ready)$ ]]; then
        # Updating current project
        _status_quick_update "$current_dir" "$@"
        return
    fi

    # Case 3: First arg is project name
    # ... existing logic
}
```

**ADHD Impact:**
- ✅ Zero decisions when in a project (`status` just works)
- ✅ No need to remember project names
- ✅ One command does everything
- ✅ Context-aware (location matters)

---

## 💡 Proposal B: Unified Dashboard Command

**Philosophy:** One command to see everything, smart modes

### `dash` - The Everything Dashboard

**Current behavior:**
```bash
dash                 # All projects
dash teaching        # Teaching only
```

**Proposed behavior:**
```bash
# Views
dash                 # All projects (default)
dash teaching        # Category filter
dash active          # Status filter (only active projects)
dash P0              # Priority filter (all P0 projects)
dash blocked         # Status filter (blocked projects)

# Combinations
dash teaching active # Teaching + active
dash research P0     # Research + P0 priority

# Interactive mode
dash -i              # Interactive picker with preview
dash --pick          # Alias for -i

# Quick actions from dashboard
dash --update        # Pick project and update status
dash --start         # Pick project and cd to it (like js)
```

**Integration with `status`:**
```bash
# From anywhere:
dash --update
> Pick project: mediationverse
> Status: active
> Priority: P0
> ... (interactive update)

# This is same as:
status mediationverse
```

**ADHD Impact:**
- ✅ One command for all "seeing" tasks
- ✅ Consistent filtering across all dimensions
- ✅ Can jump from view → action
- ✅ Memorable patterns

---

## 💡 Proposal C: Command Consolidation

**Philosophy:** Fewer commands with smarter modes

### Option C1: Consolidate into `proj` Command

```bash
proj                 # Smart: show current project OR dashboard if not in one
proj list            # Dashboard (all projects)
proj list teaching   # Filtered dashboard
proj status          # Show status of current project
proj status medfit   # Show status of specific project
proj update          # Update current project
proj update medfit   # Update specific project
proj start           # Smart project picker (like js)
proj create          # Create .STATUS in current dir
```

**Pros:**
- One namespace to learn
- Consistent subcommand pattern
- Clear hierarchy

**Cons:**
- More typing (4 chars vs 2-4)
- Breaks existing muscle memory
- Different pattern from existing smart functions

### Option C2: Keep Current Commands, Add Smart Modes

```bash
# Keep: dash, status, js, work
# Make them smarter:

dash              # Dashboard (unchanged)
dash medfit       # Quick jump: cd to project + show status

status            # Smart context (Proposal A)
status medfit     # Explicit project

js                # Smart picker (unchanged)
js medfit         # Quick jump to specific project

work              # Smart: work on current if in project, else picker
work medfit       # Explicit project
```

**Pros:**
- ✅ Minimal breaking changes
- ✅ Leverages existing commands
- ✅ Adds smart defaults without complexity

**Cons:**
- Still 4 commands to learn

---

## 💡 Proposal D: Context-Aware `work` Command

**Philosophy:** `work` should be the universal entry point

### Enhanced `work` Command

**Current behavior:**
```bash
work mediationverse     # cd + open editor
```

**Proposed behavior:**
```bash
# Context-aware
work                    # If in project → open editor
work                    # If not in project → smart picker (like js)

# Quick project switch
work medfit             # Jump to project + open editor

# With status check
work --check            # Show current project status before opening
work --update           # Update status, then open editor

# From dashboard
dash                    # See all projects
work medfit             # Quick jump from seeing it
```

**Integration:**
```bash
# Morning workflow:
dash                    # See what's active
work                    # Picks highest priority automatically
# OR
work medfit             # Explicit choice
```

**ADHD Impact:**
- ✅ One command to "start working"
- ✅ Works from anywhere
- ✅ Integrates with dashboard
- ✅ Minimal decisions

---

## 💡 Proposal E: Fuzzy Picker Integration

**Philosophy:** When ambiguous, show a picker

### Universal Project Picker

```bash
# Add to all commands:
status ?            # Fuzzy picker of all projects
dash ?              # Interactive project browser
work ?              # Pick and start
js ?                # Alias for work ?

# Fuzzy matching
status med          # If unique → mediationverse
status med          # If ambiguous → picker showing "medfit, mediationverse"

work stat           # Unique match → stat-440
work m              # Ambiguous → picker
```

**Implementation:**
```zsh
_fuzzy_match_project() {
    local query="$1"
    local matches=($(find ~/projects -name ".STATUS" -type f | \
                     grep -i "$query" | \
                     xargs -I {} dirname {}))

    if [[ ${#matches[@]} -eq 1 ]]; then
        echo "${matches[1]}"
        return 0
    elif [[ ${#matches[@]} -gt 1 ]]; then
        # Launch fzf picker
        echo "${matches[@]}" | fzf --prompt="Select project: "
        return 0
    else
        echo "No projects matching: $query" >&2
        return 1
    fi
}
```

**ADHD Impact:**
- ✅ Partial names work
- ✅ No need to remember exact names
- ✅ Visual confirmation when ambiguous
- ✅ Fast typing (fewer characters)

---

## 🎨 Proposal F: Visual Command Menu

**Philosophy:** When confused, show a menu

### `pm` - Project Management Menu

```bash
pm                  # Shows interactive menu

┌─────────────────────────────────────────┐
│ 🎯 PROJECT MANAGEMENT                   │
├─────────────────────────────────────────┤
│ What do you want to do?                 │
│                                         │
│ 1. See all projects (dashboard)         │
│ 2. Update current project status        │
│ 3. Pick a project and start working     │
│ 4. Create .STATUS for current project   │
│ 5. Search for a project                 │
│                                         │
│ Current: 📦 mediationverse [P0] 85%     │
└─────────────────────────────────────────┘

> Choose (1-5):
```

**When to use:**
- First time learning the system
- When confused about which command to use
- As a fallback when stuck

**ADHD Impact:**
- ✅ Visual guidance
- ✅ No need to remember commands
- ✅ Shows current context
- ✅ Progressive disclosure

---

## 📊 Comparison Matrix

| Proposal | Complexity | Breaking Changes | ADHD Score | Implementation |
|----------|-----------|------------------|------------|----------------|
| A: Smart Defaults | Low | None | 9/10 | 2-3 hours |
| B: Unified Dashboard | Medium | Minor | 8/10 | 3-4 hours |
| C1: Consolidate → proj | High | Major | 7/10 | 6-8 hours |
| C2: Keep + Smart Modes | Low | None | 9/10 | 2-3 hours |
| D: Context-Aware work | Low | None | 8/10 | 1-2 hours |
| E: Fuzzy Picker | Medium | None | 9/10 | 2-3 hours |
| F: Visual Menu | Low | None | 8/10 | 2-3 hours |

---

## 🎯 Recommended Combination

**Implement these together for maximum impact:**

### Phase 1: Smart Defaults (Proposal A + D)
**Time:** 2-3 hours

```bash
# Context-aware status
status                 # Works on current project OR picker
status active P0 "Task" 85  # Updates current project

# Context-aware work
work                   # Opens current project OR smart picker
work medfit            # Explicit jump
```

**Why:**
- ✅ Zero breaking changes
- ✅ Dramatically reduces decisions
- ✅ Works with existing mental model
- ✅ Easy to implement

### Phase 2: Fuzzy Matching (Proposal E)
**Time:** 2 hours

```bash
status med             # Fuzzy match → mediationverse
work stat              # Fuzzy match → stat-440
```

**Why:**
- ✅ Less typing
- ✅ Typo-tolerant
- ✅ Natural language feel

### Phase 3: Enhanced Dashboard (Proposal B)
**Time:** 2-3 hours

```bash
dash active            # Filter by status
dash P0                # Filter by priority
dash teaching active   # Combined filters
```

**Why:**
- ✅ More powerful views
- ✅ Consistent filtering
- ✅ No new commands to learn

---

## 🚀 Example Workflows (After Implementation)

### Morning Routine (Before)
```bash
# Current way:
dash                           # See projects
work mediationverse            # Must type full name
status mediationverse active P0 "Continue sims" 85  # Must type name again
```

### Morning Routine (After - Phase 1)
```bash
# Smart way:
dash                           # See projects
work med                       # Fuzzy match
status active P0 "Continue sims" 85  # Detects current project
```

### Mid-Day Check (Before)
```bash
# Current way:
cd ~/projects/r-packages/active/medfit
status medfit --show           # Must type name
```

### Mid-Day Check (After - Phase 1)
```bash
# Smart way:
cd ~/projects/r-packages/active/medfit
status                         # Auto-detects current project
```

### End of Day (Before)
```bash
# Current way:
cd ~/projects/r-packages/active/mediationverse
status mediationverse paused P0 "Resume tomorrow" 95
```

### End of Day (After - Phase 1)
```bash
# Smart way:
cd ~/projects/r-packages/active/mediationverse
status paused P0 "Resume tomorrow" 95  # Auto-detects
# OR from anywhere:
status med paused P0 "Resume tomorrow" 95  # Fuzzy match
```

---

## 🎨 Specific Implementation Details

### Smart `status` Detection Algorithm

```zsh
status() {
    # Parse arguments
    local first_arg="$1"

    # Case 1: No arguments
    if [[ $# -eq 0 ]]; then
        if [[ -f "$PWD/.STATUS" ]]; then
            _status_show "$PWD"
            return 0
        elif _is_project_dir "$PWD"; then
            _status_create_interactive "$PWD"
            return 0
        else
            _status_fuzzy_picker
            return 0
        fi
    fi

    # Case 2: First arg is status keyword
    if [[ "$first_arg" =~ ^(active|paused|blocked|ready)$ ]]; then
        if [[ -f "$PWD/.STATUS" ]]; then
            _status_quick_update "$PWD" "$@"
            return 0
        else
            echo "❌ Not in a project directory with .STATUS"
            return 1
        fi
    fi

    # Case 3: First arg is --flag
    if [[ "$first_arg" == --* ]]; then
        case "$first_arg" in
            --list) dash ;;
            --create) _status_create "$PWD" ;;
            --show) _status_show "$PWD" ;;
            --help|-h) _status_help ;;
        esac
        return 0
    fi

    # Case 4: First arg is project name (fuzzy match)
    local project_dir=$(_fuzzy_match_project "$first_arg")
    if [[ -n "$project_dir" ]]; then
        if [[ $# -eq 1 ]]; then
            # Just project name → show/update interactively
            _status_interactive "$project_dir"
        else
            # Project name + args → quick update
            shift  # Remove project name
            _status_quick_update "$project_dir" "$@"
        fi
        return 0
    fi

    echo "❌ Unknown command or project: $first_arg"
    _status_help
    return 1
}
```

### Smart `work` Detection

```zsh
work() {
    # Case 1: No arguments
    if [[ $# -eq 0 ]]; then
        if _is_project_dir "$PWD"; then
            # Already in a project → just open editor
            _work_open_editor "$PWD"
            return 0
        else
            # Not in project → smart picker (like js)
            _work_smart_picker
            return 0
        fi
    fi

    # Case 2: Project name (fuzzy match)
    local project_dir=$(_fuzzy_match_project "$1")
    if [[ -n "$project_dir" ]]; then
        cd "$project_dir"
        _work_open_editor "$project_dir"
        return 0
    fi

    echo "❌ Unknown project: $1"
    return 1
}
```

---

## 💡 Additional Quick Wins

### 1. Consistent Help

All commands should respond to:
```bash
command --help
command -h
command help
command ?          # Fuzzy picker mode
```

### 2. Current Project Indicator

Show current project in prompt when in one:
```zsh
# Add to status detection:
if [[ -f "$PWD/.STATUS" ]]; then
    local project=$(grep "^project:" "$PWD/.STATUS" | cut -d: -f2-)
    local priority=$(grep "^priority:" "$PWD/.STATUS" | cut -d: -f2-)
    echo "📍 Current: $project [$priority]"
fi
```

### 3. Command Aliases

```bash
# Short aliases for common operations:
alias st='status'          # Quick status
alias d='dash'             # Quick dashboard
alias w='work'             # Quick work
alias j='js'               # Quick just-start

# Context aliases (use current project):
alias here='status'        # Status of here
alias now='status active'  # Mark current as active
alias pause='status paused'  # Pause current
```

### 4. Tab Completion

Add zsh completion for project names:
```zsh
# _status completion
_status() {
    local projects=($(find ~/projects -name ".STATUS" -type f | \
                      xargs -I {} dirname {} | \
                      xargs -I {} basename {}))
    _describe 'projects' projects
}

compdef _status status
compdef _status work
compdef _status dash
```

---

## 🎯 Decision Matrix

**Which proposals should we implement?**

| User Need | Best Solution | Effort | Priority |
|-----------|--------------|--------|----------|
| Status without typing name | Proposal A | Low | P0 |
| Work without typing name | Proposal D | Low | P0 |
| Typo tolerance | Proposal E | Medium | P1 |
| Better filtering | Proposal B | Medium | P1 |
| First-time learning | Proposal F | Low | P2 |
| Reduce # of commands | Proposal C | High | P2 |

---

## ✅ Recommended Action Plan

### Step 1: Implement Smart Defaults (Today)
- [x] Already have dash, status, js, work
- [ ] Make `status` context-aware (detect PWD)
- [ ] Make `work` context-aware (detect PWD)
- [ ] Add `status active/paused/etc` shortcuts
- [ ] Test with real workflows

**Time:** 2-3 hours
**Breaking Changes:** None
**Impact:** High (dramatically reduces typing and decisions)

### Step 2: Add Fuzzy Matching (Next)
- [ ] Implement `_fuzzy_match_project` helper
- [ ] Update `status`, `work`, `dash` to use fuzzy matching
- [ ] Add tab completion
- [ ] Test with partial names

**Time:** 2 hours
**Breaking Changes:** None
**Impact:** Medium (nicer UX, less typing)

### Step 3: Enhanced Dashboard (Later)
- [ ] Add filtering to `dash` (active, P0, teaching+active, etc.)
- [ ] Add `dash --update` interactive mode
- [ ] Add `dash --start` quick jump

**Time:** 2-3 hours
**Breaking Changes:** Minor (new flags)
**Impact:** Medium (more powerful views)

---

## 🎉 Expected Outcome

**After Phase 1 (Smart Defaults):**

```bash
# Scenario 1: Already in a project
cd ~/projects/r-packages/active/mediationverse
status                    # Shows current project
status active P0 "Task"   # Updates current project
work                      # Opens current project

# Scenario 2: Not in a project
cd ~
status                    # Fuzzy picker of all projects
work                      # Smart picker (like js)
dash                      # Dashboard view

# Scenario 3: Quick jump
status med                # Fuzzy match → mediationverse
work stat                 # Fuzzy match → stat-440
```

**ADHD Impact:**
- ✅ **66% less typing** (avg 15 chars → 5 chars)
- ✅ **Zero decisions** when in project
- ✅ **Typo tolerant** with fuzzy matching
- ✅ **Context aware** (location matters)
- ✅ **Consistent patterns** across all commands

---

## 📝 Questions for User

Before implementing:

1. **Smart defaults OK?** Should `status` with no args work on current directory?
2. **Fuzzy matching?** Should `work med` match "mediationverse"?
3. **Breaking changes?** OK to change behavior of existing commands slightly?
4. **Priority?** Which phase should we start with (A, E, or B)?

**My recommendation:** Start with Proposal A (Smart Defaults) + D (Context-Aware work) - 2-3 hours, zero breaking changes, huge impact.
