# Default Behavior Standards - Proposal

**Date:** 2025-12-20
**Context:** Help standards implementation review

---

## TL;DR

Based on analysis of existing functions, we have **4 distinct default behavior patterns**. This proposal standardizes which pattern to use when.

---

## Current State Analysis

### Pattern Distribution

| Pattern | Count | Examples | ADHD Score |
|---------|-------|----------|------------|
| **Execute Default** | 6 | `g`, `mcp`, `r`, `workflow`, `just-start`, `dash` | 🟢 9-10/10 |
| **Interactive Select** | 2 | `cc`, `gm` (use `pick`) | 🟢 9/10 |
| **Brief Hint** | 1 | `v` | 🟡 7/10 |
| **Full Help** | 4 | `qu`, `note`, `timer`, `peek` | 🟡 5-6/10 |
| **Context Display** | 3 | `why`, `wins`, `dashboard` | 🟢 9-10/10 |
| **Require Input** | Many | `win`, fzf-helpers | 🟡 5-9/10 |

---

## Proposed Standard: Decision Tree

```
When function called with NO arguments:

1. Is there ONE most-common use case (>70% of invocations)?
   YES → Execute that default action
   Examples: g → status, mcp → list, r → console

2. Is it a dispatcher with multiple subcommands?
   a) Can we default to most-common subcommand?
      YES → Execute it (e.g., qu → preview)
      NO  → Go to (b)

   b) Is it complex with many options?
      YES → Show brief hint (like v pattern)
      NO  → Show full help

3. Is it purely informational (no action)?
   YES → Display the information
   Examples: why → context, wins → today's wins

4. Does it REQUIRE specific input to function?
   YES → Show helpful usage message
   Examples: win <description>, ccf <file>
```

---

## Tier System for Functions

### Tier 1: Execute Sensible Default ⭐ BEST
**When to use:** Clear, single most-common action (>70% usage)

**Examples:**
- `g` → `git status -sb`
- `mcp` → list all servers
- `r` → interactive R console
- `workflow` → show recent activity
- `dash` → show all projects

**Benefits:**
- Zero cognitive load
- Instant productivity
- Muscle memory friendly
- ADHD-optimal

---

### Tier 2: Interactive Selection 🎯 GREAT
**When to use:** Need context/project selection before action

**Examples:**
- `cc` → `pick && claude`
- `gm` → `pick && gemini`

**Benefits:**
- Reduces decision fatigue
- Interactive = engaging
- Combines navigation + action

**Implementation:**
```zsh
if [[ $# -eq 0 ]]; then
    if command -v pick >/dev/null 2>&1; then
        pick && toolname
    else
        toolname  # fallback
    fi
    return
fi
```

---

### Tier 3: Brief Hint 💡 GOOD
**When to use:** Complex tool with multiple paths, no clear default

**Examples:**
- `v` → shows 5-line hint with common commands
- Could apply to: `qu`, `peek`

**Benefits:**
- Lightweight guidance
- Not overwhelming
- Shows what's possible

**Implementation:**
```zsh
if [[ $# -eq 0 ]]; then
    echo -e "${BOLD}toolname${NC} - Description"
    echo "Common:"
    echo "  ${CYAN}toolname action1${NC}    Most common task"
    echo "  ${CYAN}toolname action2${NC}    Second common"
    echo "Run 'toolname help' for all options"
    return 0
fi
```

---

### Tier 4: Context Display 📊 SPECIALIZED
**When to use:** Informational tools (no action needed)

**Examples:**
- `why` → shows context (location, goal, recent work)
- `wins` → today's wins
- `dashboard` → project overview

**Benefits:**
- Reorients without requiring decision
- Context recovery for ADHD
- No action paralysis

---

### Tier 5: Require Input ⚠️ NECESSARY EVIL
**When to use:** Function cannot operate without specific input

**Examples:**
- `win <description>` → needs what to log
- `ccf <file>` → needs file path

**Benefits:**
- Clear error messaging
- Helps user understand requirements

**Implementation:**
```zsh
if [[ -z "$required_arg" ]]; then
    echo "functionname: missing required argument <argname>" >&2
    echo "Run 'functionname --help' for usage" >&2
    return 1
fi
```

---

## Current Functions Needing Review

### Upgrade Candidates (Tier 4 → Tier 1 or 3)

| Function | Current | Proposed | Rationale |
|----------|---------|----------|-----------|
| **`qu`** | Full help | `qu preview` OR brief hint | Most common: preview current document |
| **`timer`** | Full help | `timer focus 25` OR brief hint | Most common: 25-min pomodoro |
| **`note`** | Full help | `note sync` OR brief hint | Most common: sync + show status |
| **`peek`** | Full help | Brief hint | Complex, no single default |

### Decision Questions

**For each function, ask:**
1. What do I do **>70% of the time** with this tool?
2. If there's a clear answer → make it the default
3. If not → use brief hint pattern (like `v`)

---

## Implementation Strategy

### Phase 1: Document Current Patterns
✅ **DONE** - Analysis complete

### Phase 2: User Review
⏳ **NOW** - Get user feedback on:
1. Is Tier 1 (execute default) the gold standard?
2. Should `qu`, `timer`, `note` default to most-common action?
3. Is brief hint pattern (like `v`) good for complex tools?

### Phase 3: Update Functions
- Implement approved defaults
- Standardize error messages
- Add help to all functions

### Phase 4: Document Standard
- Add to `standards/workflow/DEFAULT-BEHAVIOR.md`
- Update help creation workflow

---

## Examples: Before → After

### Example 1: `qu` (Quarto)

**Before:**
```bash
$ qu
Usage: qu <command>

Commands:
  preview    Preview Quarto document
  render     Render to output
  publish    Publish to web
  ...
```

**After (Option A - Execute Default):**
```bash
$ qu
🔍 Starting Quarto preview...
[Preview server starts]
```

**After (Option B - Brief Hint):**
```bash
$ qu
qu - Quarto Document Tools

Common:
  qu preview     Preview current document (most common)
  qu render      Render to output

Run 'qu help' for all commands
```

---

### Example 2: `timer`

**Before:**
```bash
$ timer
Usage: timer <command> [duration]

Commands:
  focus [min]    Focus timer (default 25 min)
  break [min]    Break timer (default 5 min)
  ...
```

**After (Option A - Execute Default):**
```bash
$ timer
🍅 Focus timer: 25 minutes
Press Ctrl+C to stop
[Timer starts]
```

**After (Option B - Brief Hint):**
```bash
$ timer
timer - ADHD Focus Timers

Quick:
  timer focus    25-min pomodoro (most common)
  timer f50      50-min deep work

Run 'timer help' for all options
```

---

### Example 3: `note`

**Before:**
```bash
$ note
Usage: note <command>

Commands:
  sync     Sync Obsidian vault
  status   Show sync status
  ...
```

**After (Option A - Execute Default):**
```bash
$ note
📓 Syncing Obsidian vault...
✅ Synced 45 notes
📊 Last edit: 5 minutes ago
```

**After (Option B - Brief Hint):**
```bash
$ note
note - Obsidian Vault Manager

Common:
  note sync      Sync vault (most common)
  note status    Show sync status

Run 'note help' for all commands
```

---

## Recommendation

**Primary Pattern:** Tier 1 (Execute Default) whenever possible

**Rationale:**
1. ✅ Matches your existing best functions (`g`, `mcp`, `cc`)
2. ✅ Reduces ADHD friction maximally
3. ✅ Muscle memory friendly
4. ✅ "Just works" philosophy

**Secondary Pattern:** Tier 3 (Brief Hint) for complex tools

**Rationale:**
1. ✅ Better than full help (less overwhelming)
2. ✅ Shows what's possible without requiring --help
3. ✅ Follows `v` pattern (already proven)

---

## Questions for User

1. **Should `qu` default to `preview`?**
   - Is preview the most common action (>70%)?
   - Or show brief hint?

2. **Should `timer` default to `focus 25`?**
   - Is 25-min pomodoro the most common?
   - Or show brief hint?

3. **Should `note` default to `sync`?**
   - Is sync the most common action?
   - Or show brief hint + status?

4. **Should `peek` use brief hint pattern?**
   - Too complex for single default?
   - Brief hint like `v` makes sense?

5. **General principle: Default > Brief Hint > Full Help?**
   - Agree with tier ordering?
   - Any functions break this rule?

---

## Success Criteria

✅ All functions follow ONE of the 5 tier patterns
✅ No arbitrary help-showing when useful default exists
✅ ADHD friction minimized across all tools
✅ Consistent user experience
✅ Documented standard for future functions

---

**Next Step:** User feedback on this proposal before implementation.
