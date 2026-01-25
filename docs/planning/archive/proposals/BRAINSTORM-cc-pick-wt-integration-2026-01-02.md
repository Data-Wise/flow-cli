# CC Pick + Worktree Integration Brainstorm

**Date:** 2026-01-02
**Focus:** Feature (command behavior design)
**Depth:** Quick
**Context:** How should `cc pick` handle worktree filtering?

---

## Current Behavior Analysis

### What `cc pick` Does Now (v4.7.1)

```bash
cc pick                   # Shows ALL projects (regular + worktrees)
cc pick wt                # Filters to ONLY worktrees
cc pick r                 # Filters to R packages
cc pick dev               # Filters to dev tools
```

**Implementation:**

```bash
pick --no-claude "$@" && claude --permission-mode acceptEdits
```

**Key insight:** `cc pick` passes ALL args to `pick`, which already supports filtering!

### What `pick` Supports (Built-in Categories)

| Category | Shortcut                | What it shows         |
| -------- | ----------------------- | --------------------- |
| `r`      | r, rpkg, rpackages      | R packages only       |
| `dev`    | dev, devtools           | Dev tools only        |
| `q`      | q, quarto               | Quarto projects       |
| `teach`  | teach, teaching         | Teaching courses      |
| `rs`     | rs, research            | Research projects     |
| `app`    | app, apps               | Applications          |
| **`wt`** | wt, worktree, worktrees | **Worktrees only** ✅ |

**Special flags:**

- `--fast` - Skip git status (faster)
- `-a, --all` - Force picker (skip direct jump)
- `--recent`, `-r` - Recent sessions only

---

## User's Request

> "I like the pick to use the default pick behavior and choose projects and wt"

**Interpretation:**

1. `cc pick` should show **both** regular projects AND worktrees (default behavior)
2. `cc pick wt` should **filter** to show only worktrees
3. Worktrees are not a "mode" but a **filter** applied to picker

**Current state:** ✅ **Already works this way!**

---

## Question: Is the current behavior what you want?

### Scenario 1: Show Everything (Current Default)

```bash
cc pick                   # Shows ALL projects + worktrees
```

**Output includes:**

- Regular projects (flow-cli, scribe, etc.)
- Worktrees (flow-cli/feature-auth, scribe/fix-bug)

### Scenario 2: Filter to Worktrees Only

```bash
cc pick wt                # Shows ONLY worktrees
```

**Output includes:**

- Only worktrees from `~/.git-worktrees/`
- Regular projects hidden

### Scenario 3: Other Filters

```bash
cc pick dev               # Dev tools only (no worktrees)
cc pick r                 # R packages only (no worktrees)
```

---

## Options for Refinement

### Option 1: Keep Current Behavior (Recommended) ✅

**What it is:**

- `cc pick` → All projects + worktrees (default `pick` behavior)
- `cc pick wt` → Worktrees only (filter)
- `cc pick dev` → Dev tools only (filter)

**Pros:**

- ✅ Already implemented
- ✅ Zero changes needed
- ✅ Consistent with standalone `pick` command
- ✅ Flexible filtering

**Cons:**

- None (matches user request)

**No action required.**

---

### Option 2: Make `wt` Modify Behavior (Not Filter)

**What it would be:**

```bash
cc pick                   # Regular projects only (no worktrees)
cc pick wt                # Launch wt picker, then Claude
cc wt pick                # Same as above (unified pattern)
```

**Pros:**

- Separates "project picker" from "worktree picker"
- Clear mental model: pick=projects, wt=worktrees

**Cons:**

- ❌ Breaking change (removes worktrees from default `cc pick`)
- ❌ Less flexible (can't see all options at once)
- ❌ Inconsistent with standalone `pick` (which shows worktrees)
- ❌ Requires code changes

**Not recommended** - conflicts with user preference for "default pick behavior"

---

### Option 3: Add Explicit Flags

**What it would be:**

```bash
cc pick                   # ALL (projects + worktrees) - default
cc pick --projects        # Projects only (no worktrees)
cc pick --worktrees       # Worktrees only (same as: cc pick wt)
cc pick --all             # Explicit: show everything
```

**Pros:**

- Explicit control
- Self-documenting

**Cons:**

- ❌ Verbose (violates zero-friction)
- ❌ Flags not idiomatic for flow-cli
- ❌ Redundant with existing category system

**Not recommended** - over-engineered

---

### Option 4: Smart Defaults with Context

**What it would be:**

```bash
# In regular project
cc pick                   # Shows all projects (current behavior)

# In worktree
cc pick                   # Smart: shows worktrees first, projects below
```

**Pros:**

- Context-aware UX
- Prioritizes relevant options

**Cons:**

- ❌ Unpredictable (behavior changes based on context)
- ❌ Complex implementation
- ❌ Harder to document

**Not recommended** - adds complexity without clear benefit

---

## Recommended Approach: **Option 1 (No Change)**

### Why No Change Needed

The current behavior **already matches** your stated preference:

> "I like the pick to use the default pick behavior and choose projects and wt"

**Current implementation:**

```bash
cc pick                   # ✅ Default pick behavior (all projects + wt)
cc pick wt                # ✅ Filter to worktrees only
cc pick dev               # ✅ Filter to dev tools
cc pick r                 # ✅ Filter to R packages
```

**This is exactly what you described!**

---

## Clarification Questions

### Q1: Does `cc pick` currently show worktrees?

**Answer:** ✅ **Yes**, by default.

When you run `cc pick`, it shows:

- All regular projects
- All worktrees (from `~/.git-worktrees/`)

Both appear in the same picker with worktree indicators (🌳).

### Q2: What does `cc pick wt` do?

**Answer:** **Filters** the picker to show **only worktrees**.

It's equivalent to:

```bash
pick wt                   # Standalone pick with wt filter
```

Then launches Claude after selection.

### Q3: Is `wt` a "mode" or a "filter"?

**Answer:** **Filter** (category).

- Not a mode like `opus` or `yolo`
- It's a category filter like `dev`, `r`, `teach`
- Passed to `pick` as an argument

### Q4: Can you combine filters?

**Answer:** ❌ **No** (pick accepts one category at a time).

```bash
cc pick dev               # ✅ Dev tools only
cc pick wt                # ✅ Worktrees only
cc pick dev wt            # ❌ Invalid (picks "dev", ignores "wt")
```

---

## Edge Cases

### Case 1: Direct Jump with `wt` Category

```bash
cc pick wt scribe         # What happens?
```

**Current behavior:**

1. `pick wt scribe` → Filters to worktrees, then direct jumps to "scribe" worktree
2. If multiple scribe worktrees exist → Shows picker with matches
3. If one match → Direct jump
4. If no match → Shows all worktrees

**Expected?** Probably yes, but could be confusing.

**Alternative interpretation:**

- User wants: "Pick from scribe's worktrees"
- Current: "Pick from all worktrees matching 'scribe'"

### Case 2: Modes with Worktree Filter

```bash
cc opus pick wt           # Mode + target + filter
```

**Current behavior:**

1. Mode: `opus`
2. Target: `pick`
3. Args to pick: `wt`
4. Result: Opus picker filtered to worktrees ✅

**Works as expected!**

### Case 3: Worktree + Mode (Natural Reading)

```bash
cc pick wt opus           # Target + filter + mode
```

**With unified grammar (from previous spec):**

1. Target: `pick`
2. Filter: `wt`
3. Mode: `opus`
4. Result: Opus picker filtered to worktrees ✅

**Should work** once unified grammar is implemented.

---

## Examples (Current Behavior)

### Example 1: Basic Pick

```bash
$ cc pick

# Shows picker with:
#   flow-cli              (regular project)
#   scribe                (regular project)
#   🌳 flow-cli/feat-123  (worktree)
#   🌳 scribe/fix-bug     (worktree)

# Select → cd + launch Claude
```

### Example 2: Filtered to Worktrees

```bash
$ cc pick wt

# Shows picker with ONLY:
#   🌳 flow-cli/feat-123  (worktree)
#   🌳 scribe/fix-bug     (worktree)

# Select → cd + launch Claude
```

### Example 3: With Mode

```bash
$ cc opus pick wt

# Shows worktree picker
# Select → cd + launch Claude with Opus
```

### Example 4: Direct Jump

```bash
$ cc pick flow

# Direct jump to flow-cli (bypasses picker)
# Launch Claude
```

### Example 5: Direct Jump with Filter

```bash
$ cc pick wt flow

# Filters to worktrees, then direct jumps to "flow" worktree
# If multiple: shows picker with matches
# If one: direct jump
# If none: shows all worktrees (ignores "flow")
```

---

## Potential Confusion Points

### Confusion 1: `cc wt` vs `cc pick wt`

**Different commands, different behaviors:**

| Command          | Behavior                              |
| ---------------- | ------------------------------------- |
| `cc wt`          | List worktrees (no picker, no launch) |
| `cc wt <branch>` | Create/switch to worktree → launch    |
| `cc wt pick`     | Pick worktree → launch                |
| `cc pick wt`     | Pick (filtered to wt) → launch        |

**Are these redundant?**

- `cc wt pick` → Uses `wt`'s own picker logic
- `cc pick wt` → Uses `pick`'s picker with wt filter

**Recommendation:** Both are useful:

- `cc wt pick` → Worktree-first workflow
- `cc pick wt` → Picker-first workflow with filter

### Confusion 2: Filter Position

**Question:** Does filter position matter?

```bash
cc pick wt                # Filter after target
cc wt pick                # Target-like command
```

**Answer:** Different commands!

- `cc pick wt` → pick dispatcher with wt filter
- `cc wt pick` → wt dispatcher with pick subcommand

Both end up at the same place, but via different code paths.

---

## Documentation Needs

### Current Docs Don't Clearly Explain

1. **`cc pick` shows worktrees by default**
   - Users might not realize worktrees appear in picker
   - Should be highlighted in examples

2. **`wt` is a filter, not a mode**
   - Could be confused with `opus`, `yolo`, `plan`
   - Needs clear categorization in help text

3. **Filter categories**
   - All available categories should be listed
   - Examples for each category

### Proposed Help Text Updates

#### Before (Current)

```
cc pick               # Pick project → Claude
```

#### After (Clarified)

```
cc pick               # Pick project or worktree → Claude
cc pick wt            # Pick worktree only → Claude
cc pick dev           # Pick dev tool only → Claude

Categories: r, dev, q, teach, rs, app, wt
```

---

## Summary

### Current Behavior ✅

```bash
cc pick                   # ALL (projects + worktrees)
cc pick wt                # Worktrees only (filter)
cc pick dev               # Dev tools only (filter)
cc opus pick wt           # Opus + worktrees (mode + filter)
```

### Matches User Preference ✅

> "I like the pick to use the default pick behavior and choose projects and wt"

**Current implementation already does this!**

### No Changes Recommended

**Zero code changes needed.** The current behavior is correct.

### Documentation Improvements Recommended

1. **Clarify in help text:**
   - `cc pick` shows both projects and worktrees
   - `wt` is a filter category (like `dev`, `r`, etc.)
   - List all available categories

2. **Add examples:**
   - `cc pick wt` → worktrees only
   - `cc opus pick wt` → Opus + worktrees

3. **Update CLAUDE.md:**
   - Document category filters
   - Show worktree filtering examples

---

## Next Steps

1. **Confirm understanding:**
   - Is current behavior (`cc pick` showing all) what you want?
   - Or do you want `cc pick` to exclude worktrees by default?

2. **If current is correct:**
   - Update documentation (help text, CLAUDE.md)
   - Add category examples
   - Ship as-is

3. **If change needed:**
   - Clarify desired behavior
   - Design new filtering logic
   - Implement + test

---

**Recommendation:** Current behavior is correct. Only documentation needs improvement.
