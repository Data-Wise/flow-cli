# Default Behavior Standard

**Version:** 1.0
**Date:** 2025-12-20
**Status:** Official Standard

---

## Purpose

This standard defines how ZSH functions should behave when called with no arguments, establishing patterns for smart defaults, error handling, and help display that optimize for ADHD-friendly workflows.

---

## Core Principle

> **One mental model: Commands do the obvious thing by default, with zero decisions required.**

Functions should eliminate decision paralysis by executing a sensible default action when called without arguments, rather than showing help or requiring input.

---

## Decision Tree

When a function is called with **NO arguments**:

```
1. Is there ONE most-common use case (>70% of invocations)?
   ✅ YES → Execute that default action
   ❌ NO  → Go to step 2

2. Is it a dispatcher with multiple subcommands?
   a) Can we default to the most-common subcommand?
      ✅ YES → Execute it
      ❌ NO  → Go to (b)

   b) Is it complex with many options?
      ✅ YES → Show brief hint (5 lines, not overwhelming)
      ❌ NO  → Show full help

3. Is it purely informational (no action)?
   ✅ YES → Display the information

4. Does it REQUIRE specific input to function?
   ✅ YES → Show helpful error message with stderr
```

---

## Five Behavior Tiers

### Tier 1: Execute Sensible Default ⭐ BEST

**When to use:** Clear, single most-common action (>70% usage)

**Examples:**
- `g` → `git status -sb`
- `dash` → Update coordination + show all projects
- `timer` → 25-min pomodoro with auto-win logging
- `workflow` → Show recent activity

**Benefits:**
- Zero cognitive load
- Instant productivity
- Muscle memory friendly
- ADHD-optimal

**Implementation:**
```zsh
functionname() {
    # Help check FIRST
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        _functionname_help
        return 0
    fi

    # Smart default when no args
    local action="${1:-default-action}"

    case "$action" in
        default-action)
            # Execute most common task
            ;;
        *)
            # Other actions
            ;;
    esac
}
```

---

### Tier 2: Interactive Selection 🎯 GREAT

**When to use:** Need context/project selection before action

**Examples:**
- `cc` → `pick && claude` (pick project, then launch)
- `gm` → `pick && gemini`

**Benefits:**
- Reduces decision fatigue
- Interactive = engaging
- Combines navigation + action

**Implementation:**
```zsh
functionname() {
    if [[ $# -eq 0 ]]; then
        if command -v pick >/dev/null 2>&1; then
            pick && toolname
        else
            toolname  # fallback
        fi
        return
    fi

    # Rest of implementation
}
```

---

### Tier 3: Brief Hint 💡 GOOD

**When to use:** Complex tool with multiple paths, no clear default

**Examples:**
- `v` → Shows 5-line hint with common commands
- `peek` → Brief hint pattern

**Benefits:**
- Lightweight guidance
- Not overwhelming
- Shows what's possible

**Implementation:**
```zsh
functionname() {
    # Help check FIRST
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        _functionname_help
        return 0
    fi

    # No args = brief hint
    if [[ $# -eq 0 ]]; then
        echo -e "${BOLD}toolname${NC} - Description"
        echo ""
        echo "Common:"
        echo "  ${CYAN}toolname action1${NC}    Most common task"
        echo "  ${CYAN}toolname action2${NC}    Second common"
        echo ""
        echo "Run 'toolname help' for all options"
        return 0
    fi

    # Rest of implementation
}
```

---

### Tier 4: Context Display 📊 SPECIALIZED

**When to use:** Informational tools (no action needed)

**Examples:**
- `why` → Shows context (location, goal, recent work)
- `wins` → Today's wins
- `dashboard` → Project overview

**Benefits:**
- Reorients without requiring decision
- Context recovery for ADHD
- No action paralysis

**Implementation:**
```zsh
functionname() {
    # Help check FIRST
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        _functionname_help
        return 0
    fi

    # Display information by default
    _display_context_info
}
```

---

### Tier 5: Require Input ⚠️ NECESSARY EVIL

**When to use:** Function cannot operate without specific input

**Examples:**
- `win <description>` → Needs what to log
- `cc-file <file>` → Needs file path

**Benefits:**
- Clear error messaging
- Helps user understand requirements

**Implementation:**
```zsh
functionname() {
    # Help check FIRST
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        _functionname_help
        return 0
    fi

    local required_arg="$1"

    if [[ -z "$required_arg" ]]; then
        echo "functionname: missing required argument <argname>" >&2
        echo "Run 'functionname help' for usage" >&2
        return 1
    fi

    # Rest of implementation
}
```

---

## Smart Default Examples

### Complete Workflow: `dash`

**Default behavior:** Execute full coordination workflow

```zsh
dash() {
    # Help check FIRST
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        _dash_help
        return 0
    fi

    local category="${1:-all}"

    # Smart default for "all"
    if [[ "$category" == "all" ]]; then
        echo "🔄 Updating project coordination..."

        # 1. Sync .STATUS files to project-hub
        # 2. Update coordination timestamp
        # 3. Show master dashboard

        # ... implementation
    fi

    # ... rest of function
}
```

**What happens:**
1. Syncs all .STATUS files to project-hub
2. Updates cross-project coordination
3. Shows master dashboard for all projects
4. One command = complete picture

---

### Auto-Chaining: `timer`

**Default behavior:** 25-min pomodoro with auto-win logging

```zsh
timer() {
    # Help check FIRST
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        _timer_help
        return 0
    fi

    local cmd="${1:-focus}"
    local duration="${2:-25}"

    case "$cmd" in
        focus|"")
            # 25-min pomodoro
            _timer_run "$duration" "$task"

            # On completion, auto-log win
            if [[ $? -eq 0 ]]; then
                win "Completed ${duration}-min focus on $task"
            fi
            ;;
    esac
}
```

**What happens:**
1. Starts 25-minute pomodoro
2. Shows progress/countdown
3. On completion, automatically logs as win
4. Provides dopamine reward

---

### Multi-Step Workflow: `note`

**Default behavior:** Sync → Status → Open dashboard

```zsh
note() {
    # Help check FIRST
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        _note_help
        return 0
    fi

    local cmd="${1:-sync-status-open}"

    case "$cmd" in
        sync-status-open|"")
            # Smart default: full workflow
            echo "📓 Obsidian Vault Workflow..."

            # 1. Sync vault
            _note_sync

            # 2. Show status
            _note_status

            # 3. Open project dashboard
            open "obsidian://open?vault=...&file=Project-Hub.md"
            ;;
    esac
}
```

**What happens:**
1. Syncs Obsidian vault (bidirectional)
2. Shows sync status (# files, last change)
3. Opens Project-Hub dashboard in Obsidian
4. Complete vault workflow in one command

---

## ADHD Optimization Scores

| Command | Before | After | Improvement |
|---------|--------|-------|-------------|
| `dash` | 9/10 (showed all) | 10/10 (updates + coordinates + shows) | +1 |
| `qu` | 6/10 (showed help) | 10/10 (render + preview) | +4 🎯 |
| `timer` | 6/10 (showed help) | 10/10 (focus + auto-log) | +4 🎯 |
| `note` | 6/10 (showed help) | 10/10 (sync + status + open) | +4 🎯 |
| `peek` | 5/10 (full help) | 7/10 (brief hint) | +2 |

**Average Improvement:** +3 points

---

## Implementation Checklist

When creating a new function or updating existing:

### 1. Determine Tier
- [ ] Identify most common use case (>70%)
- [ ] Check if multiple valid approaches exist
- [ ] Determine if input is absolutely required
- [ ] Assign to appropriate tier (1-5)

### 2. Implement Pattern
- [ ] Help check FIRST (all three forms)
- [ ] Implement smart default OR error message
- [ ] Return 0 after help, 1 after errors
- [ ] Use stderr for all errors

### 3. Test Behavior
- [ ] `command help` - Shows help
- [ ] `command -h` - Shows help
- [ ] `command --help` - Shows help
- [ ] `command` - Executes default OR shows error
- [ ] `command invalid` - Shows error on stderr

### 4. Document
- [ ] Add to ALIAS-REFERENCE-CARD.md
- [ ] Include in function's help text
- [ ] Note tier in code comments

---

## Anti-Patterns to Avoid

### ❌ DON'T: Show help by default
```zsh
# BAD: Requires user to type extra args every time
functionname() {
    if [[ $# -eq 0 ]]; then
        _functionname_help
        return
    fi
    # ...
}
```

**Why bad:** Creates friction, requires decision, slows workflow

### ✅ DO: Execute sensible default
```zsh
# GOOD: Does the obvious thing
functionname() {
    if [[ "$1" == "help" || "$1" == "-h" || "$1" == "--help" ]]; then
        _functionname_help
        return 0
    fi

    local action="${1:-most-common-action}"
    # Execute default action
}
```

---

### ❌ DON'T: Require flags for common actions
```zsh
# BAD: Too many decisions
functionname() {
    case "$1" in
        -a|--action1) do_action1 ;;
        -b|--action2) do_action2 ;;
        *) show_help ;;
    esac
}
```

**Why bad:** Forces user to remember flags, slows muscle memory

### ✅ DO: Subcommands with smart default
```zsh
# GOOD: Natural language, with default
functionname() {
    local cmd="${1:-default-cmd}"

    case "$cmd" in
        default-cmd|"") do_most_common ;;
        action1) do_action1 ;;
        action2) do_action2 ;;
    esac
}
```

---

## When to Deviate

**Exceptions to smart defaults:**

1. **Destructive actions** - Never default to deletion/removal
   ```zsh
   # CORRECT: Require explicit confirmation
   git-nuke() {
       if [[ -z "$1" ]]; then
           echo "git-nuke: this is destructive, requires explicit branch name" >&2
           return 1
       fi
   }
   ```

2. **Multi-target operations** - Need to specify what to operate on
   ```zsh
   # CORRECT: Require target specification
   deploy() {
       if [[ -z "$1" ]]; then
           echo "deploy: missing target (staging|production)" >&2
           return 1
       fi
   }
   ```

3. **Ambiguous contexts** - Default might be wrong
   ```zsh
   # CORRECT: Use interactive selection
   switch-project() {
       if [[ $# -eq 0 ]]; then
           pick && cd "$(selected)"  # Interactive = safe
       fi
   }
   ```

---

## Testing Your Implementation

```bash
# For EVERY function, test:

# 1. Help works (all three forms)
command help            # Shows help, exits 0
command --help          # Shows help, exits 0
command -h              # Shows help, exits 0

# 2. Default behavior
command                 # Executes smart default OR shows clear error

# 3. Invalid input
command --invalid       # Shows error on stderr, references help

# 4. ADHD test
# Can user execute it without thinking? Yes = good. No = refine.
```

---

## See Also

- [ZSH Commands Help Standard](../code/ZSH-COMMANDS-HELP.md)
- [Help Creation Workflow](HELP-CREATION-WORKFLOW.md)
- [PROPOSAL-SMART-DEFAULTS.md](../../PROPOSAL-SMART-DEFAULTS.md)

---

**Maintainer:** DT
**Last Updated:** 2025-12-20
**Version:** 1.0
