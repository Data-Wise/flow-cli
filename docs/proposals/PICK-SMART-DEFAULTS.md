# Smart Default Behavior for `pick` and Related Commands

**Generated:** 2025-12-26
**Revised:** 2025-12-26 (v2 - consistent key bindings)
**Context:** flow-cli project picker enhancement

## Overview

Add intelligent default behaviors to `pick` and commands that use it (`cc`, `ccy`, `work`, etc.) with **consistent key bindings** across all commands.

---

## Design Principles

1. **Consistency** - Same keys do same things everywhere
2. **Enter = Default action** - Most common use case
3. **Space = Escape hatch** - Override default, show full picker
4. **Direct name = Fastest path** - Skip picker entirely

---

## Proposed Key Bindings (Consistent)

| Key          | In `pick`           | In `cc`/`ccy`                  | In `work`             |
| ------------ | ------------------- | ------------------------------ | --------------------- |
| **Enter**    | Resume last project | Pick → **NEW** session         | Resume last session   |
| **Space**    | Show full picker    | Show full picker → NEW session | Show full picker      |
| **`<name>`** | Direct jump         | Direct jump → NEW session      | Direct jump → session |

### Key Insight

- `pick` = **Navigation only** (Enter = resume is convenient)
- `cc`/`ccy` = **Always NEW Claude session** (you don't resume pick, you resume Claude)
- `work` = **Session management** (resume makes sense)

---

## Detailed Behaviors

### 1. `pick` Command

```
pick              → Resume last project (Enter) or full picker (Space)
pick flow         → Direct jump to flow-cli
pick r            → R packages picker (category filter)
pick -a           → Force full picker (flag override)
```

**Visual prompt:**

```
$ pick
╔════════════════════════════════════════════════════════════╗
║  🔍 PROJECT PICKER                                         ║
╚════════════════════════════════════════════════════════════╝

  💡 Last: flow-cli (dev) - 2h ago

  [Enter] Resume  │  [Space] Browse all  │  Type to search...

> _
```

**Behavior:**

- **Enter** (empty query) → cd to last project
- **Space** → Show full fzf picker
- **Typing** → Filter projects
- **No session** → Fall back to full picker

---

### 2. `cc` and `ccy` Commands

```
cc                → Pick project → NEW Claude session (acceptEdits)
cc flow           → Direct jump → NEW Claude session
cc now            → Current dir → NEW Claude session (no pick)

ccy               → Pick project → NEW Claude YOLO session
ccy flow          → Direct jump → NEW YOLO session
ccy now           → Current dir → NEW YOLO session (no pick)
```

**Why NEW session (not resume)?**

- Claude has its own resume: `claude -r` or `cc resume`
- When you type `cc`, you want to START working
- Resuming Claude session ≠ resuming project navigation

**Visual prompt:**

```
$ cc
╔════════════════════════════════════════════════════════════╗
║  🤖 CLAUDE CODE                                            ║
╚════════════════════════════════════════════════════════════╝

  💡 Last: flow-cli (dev) - 2h ago

  [Enter] flow-cli → Claude  │  [Space] Browse  │  Type to search...

> _
```

**Key difference from `pick`:**

- After selection, **always launches NEW Claude session**
- To resume a Claude conversation: `cc resume` or `cc continue`

---

### 3. `work` Command

```
work              → Resume last session (if active) or pick new
work flow         → Direct jump → Start/resume session
work -n           → Force new session (even if one exists)
```

**Behavior:**

- **Enter** → Resume last work session (including timers, context)
- **Space** → Browse all projects
- Work sessions are different from Claude sessions

---

## Consistency Matrix

| Command | Enter (default)       | Space               | `<name>`          | Purpose              |
| ------- | --------------------- | ------------------- | ----------------- | -------------------- |
| `pick`  | Resume last dir       | Full picker         | Direct jump       | **Navigate**         |
| `cc`    | Last dir → NEW Claude | Picker → NEW Claude | Jump → NEW Claude | **Code with Claude** |
| `ccy`   | Last dir → NEW YOLO   | Picker → NEW YOLO   | Jump → NEW YOLO   | **YOLO with Claude** |
| `work`  | Resume session        | Full picker         | Direct → session  | **Session mgmt**     |

**Mnemonic:**

- **Enter** = "Do the thing I probably want"
- **Space** = "Wait, let me choose"
- **Name** = "I know exactly what I want"

---

## Implementation

### Phase 1: Direct Jump (Quick Win - 30min)

Add `pick <name>` direct jump:

```zsh
pick() {
    local arg="$1"

    # Direct jump if name provided (not a category/flag)
    if [[ -n "$arg" && "$arg" != -* && "$arg" != "help" ]]; then
        case "$arg" in
            r|dev|q|teach|rs|app) ;; # Category - fall through
            *)
                local match=$(_proj_find "$arg")
                if [[ -n "$match" ]]; then
                    cd "$match"
                    echo "  📂 $match"
                    return 0
                fi
                echo "❌ No project: $arg"
                return 1
                ;;
        esac
    fi
    # ... rest of picker
}
```

### Phase 2: Enter/Space Key Bindings (Medium - 1hr)

Modify fzf to handle Space as escape:

```zsh
pick() {
    # ... setup ...

    # Check for recent session
    local show_resume=0
    if [[ -z "$category" && -f "$PROJ_SESSION_FILE" ]]; then
        # Parse session, check age < 24h
        show_resume=1
    fi

    if [[ $show_resume -eq 1 ]]; then
        echo "  💡 Last: $last_proj (${age}h ago)"
        echo "  [Enter] Resume  │  [Space] Browse  │  Type to search..."
    fi

    # fzf with special handling
    local selection
    selection=$(cat "$tmpfile" | fzf \
        --height=50% \
        --reverse \
        --print-query \
        --expect=space \
        --header="Enter=select | Space=browse all | ^C=cancel" \
        ${show_resume:+--query=""})

    # Parse fzf output
    local query=$(echo "$selection" | sed -n '1p')
    local key=$(echo "$selection" | sed -n '2p')
    local picked=$(echo "$selection" | sed -n '3p')

    # Handle Space key
    if [[ "$key" == "space" ]]; then
        # User pressed Space - show full picker without resume prompt
        # Re-run fzf without resume logic
        pick -a  # Force all
        return
    fi

    # Handle Enter with empty query (resume)
    if [[ -z "$query" && -z "$picked" && $show_resume -eq 1 ]]; then
        cd "$last_dir"
        echo "  📂 Resumed: $last_proj"
        return 0
    fi

    # Normal selection
    # ...
}
```

### Phase 3: Update cc/ccy for Consistency (30min)

```zsh
cc() {
    local arg="$1"

    # No args - smart pick then NEW Claude
    if [[ -z "$arg" ]]; then
        # Use pick's smart behavior, then launch Claude
        if pick; then
            claude --permission-mode acceptEdits
        fi
        return
    fi

    # Known subcommands
    case "$arg" in
        yolo|y|plan|p|now|n|resume|r|continue|c|...)
            # Handle as before
            ;;
        *)
            # Assume project name - direct jump then Claude
            if pick "$arg"; then
                claude --permission-mode acceptEdits
            fi
            ;;
    esac
}
```

---

## Edge Cases

### Q: What if user wants to resume Claude session in last project?

```bash
# Option 1: Resume Claude (with picker)
cc resume          # or: cc r

# Option 2: Go to last project, then resume Claude
pick && cc resume  # Two steps, explicit

# Option 3: Direct resume in specific project
cc flow resume     # Future enhancement?
```

### Q: What about `cc` with no session file?

Falls back to full picker (same as Space behavior).

### Q: What if direct name has multiple matches?

Show filtered fzf picker with matches only.

---

## Quick Wins (< 1hr)

1. ⭐ **Direct jump: `pick <name>`** - Highest value, lowest risk
2. **Update help text** - Document new key bindings
3. **Add `-a` flag** - `pick -a` forces full picker

## Medium Effort (1-3hrs)

4. ⭐ **Enter/Space bindings in fzf** - Consistent escape hatch
5. **Update cc/ccy** - Support `cc flow` direct jump
6. **Session file validation** - Handle stale/missing gracefully

## Big Ideas (1+ day)

7. **Recent projects list** - Track last 5, show as fzf header
8. **Project frecency** - Sort by frequency × recency
9. **Context-aware defaults** - "You usually work on X now"

---

## Summary

| Input        | `pick`       | `cc` / `ccy`                 | `work`              |
| ------------ | ------------ | ---------------------------- | ------------------- |
| **(Enter)**  | Resume last  | Last → **NEW** Claude        | Resume session      |
| **(Space)**  | Full picker  | Full picker → **NEW** Claude | Full picker         |
| **`<name>`** | Direct jump  | Direct → **NEW** Claude      | Direct → session    |
| **`resume`** | N/A          | Resume Claude convo          | Resume work session |
| **`-a`**     | Force picker | N/A                          | N/A                 |

**Key insight:** `cc`/`ccy` always starts NEW Claude sessions because Claude has its own resume mechanism (`cc resume`). The "last project" shortcut is just for navigation convenience.

---

## Recommended Order

1. **Phase 1:** `pick <name>` direct jump (30min, high value)
2. **Phase 2:** Enter/Space key bindings (1hr, consistency)
3. **Phase 3:** `cc flow` direct jump (30min, leverages Phase 1)

Start with Phase 1 - it's the foundation for everything else.
