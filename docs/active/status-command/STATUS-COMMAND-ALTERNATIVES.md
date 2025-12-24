# Status Command Alternatives - Visual Guide

**Date:** 2025-12-14
**TL;DR:** Rename `status` → `up` for clarity

---

## The Problem (Current)

### What Users Expect

```bash
status mediationverse              # Show me the status (READ)
```

### What Actually Happens

```bash
status mediationverse              # Prompt to UPDATE status (WRITE!)
```

**Confusion:** Name suggests READ, behavior is WRITE.

---

## The Solution (Recommended)

### Clear Separation of Concerns

| Action             | Old Command       | New Command | Type  |
| ------------------ | ----------------- | ----------- | ----- |
| **Show** status    | `status --show`   | `dash`      | READ  |
| **Update** status  | `status`          | `up`        | WRITE |
| **Create** .STATUS | `status --create` | `pinit`     | WRITE |

---

## Side-by-Side Comparison

### Current (Confusing)

```bash
# Show status of one project
status mediationverse --show       # Requires flag! Not intuitive

# Show all projects
dash                               # Different command for same concept

# Update status (interactive)
status mediationverse              # Default is update (unexpected!)

# Update status (quick)
status medfit active P1 "Docs" 60  # Same command, different mode

# Create new .STATUS
status newproj --create            # Same command, yet another mode
```

### Proposed (Clear)

```bash
# Show status of one project
dash mediationverse                # Same command as "show all"

# Show all projects
dash                               # Consistent!

# Update status (interactive)
up mediationverse                  # Verb = clear action

# Update status (quick)
up medfit active P1 "Docs" 60      # Same verb, just faster

# Create new .STATUS
pinit newproj                      # Different action = different command
```

---

## Daily Workflow Examples

### Morning Routine

```bash
# OLD WAY
dash                               # See all projects
status medfit                      # Update one (confusing name)
work medfit                        # Start working

# NEW WAY
dash                               # See all projects
up medfit                          # Update one (clear verb!)
work medfit                        # Start working
```

### Quick Updates

```bash
# OLD WAY
status medfit active P1 "Add tests" 75

# NEW WAY
up medfit active P1 "Add tests" 75
```

### New Project Setup

```bash
# OLD WAY
status new-package --create        # "status" doesn't suggest "create"

# NEW WAY
pinit new-package                  # "init" clearly means "create new"
```

---

## Comparison with Your Other Commands

### Current Successful Patterns (All Verbs!)

```bash
work <name>                        # ✅ Verb: start working
finish [msg]                       # ✅ Verb: end session
js                                 # ✅ Verb: just start
dash                              # ⚠️  Noun: but read-only (OK)
```

### The Outlier

```bash
status <name>                      # ❌ Noun: but modifies state (BAD)
```

### The Fix

```bash
up <name>                          # ✅ Verb: update state (GOOD)
```

**Pattern:** Your best commands are SHORT VERBS. Match that!

---

## Detailed Command Reference

### Option D (Recommended)

#### `dash [project]` - Show Status (Existing)

```bash
dash                               # Show all projects
dash mediationverse                # Show one project
dash teaching                      # Show category
dash --help                        # Help
```

**Type:** READ (noun, but read-only = acceptable)
**Frequency:** Multiple times per day
**ADHD Score:** 9/10 (ultra-fast scan)

#### `up <project> [args]` - Update Status (New)

```bash
# Interactive mode
up mediationverse                  # Prompt for status/priority/task/progress

# Quick mode (all args provided)
up medfit active P1 "Add vignette" 60

# Help
up --help
```

**Type:** WRITE (verb = clear action)
**Frequency:** Multiple times per day
**ADHD Score:** 9/10 (2 chars, clear action)

#### `pinit <project>` - Create .STATUS (New)

```bash
pinit new-package                  # Create .STATUS with defaults
pinit new-package --help           # Help
```

**Type:** WRITE (verb = clear action)
**Frequency:** Once per project (rare)
**ADHD Score:** 8/10 (clear, but rare use)

---

## Why "up" is Perfect

### 1. Ultra-Short (ADHD Win)

- Only 2 characters
- Faster than `status` (6 chars)
- Matches `js` (2 chars), `lt` (2 chars) pattern

### 2. Clear Verb

- "up" = "update" (universally understood)
- Action-oriented (not ambiguous like "status")
- Muscle memory: `up` → "I'm making a change"

### 3. No Conflicts

```bash
which up                           # (probably nothing)
# Unlike "set" (git uses it), "get" (many uses), etc.
```

### 4. Pairs Well

```bash
dash                               # Look down at dashboard
up                                 # Move status up (update progress)
```

### 5. Memorable

- Short = memorable
- Common word = easy to recall
- Verb = action clear

---

## Alternative Names (If You Don't Like "up")

### If You Want More Explicit

```bash
pupdate <project>                  # "project update" (6 chars)
pset <project>                     # "project set" (4 chars)
track <project>                    # "track progress" (5 chars)
```

### If You Want Matching Prefix

```bash
pshow → dash                       # (dash is better, keep it)
pup <project>                      # "project update" (3 chars)
pinit <project>                    # "project init" (5 chars)
```

### If You Want Git-Style

```bash
proj show                          # (but dash is better)
proj update                        # 2 words = longer
proj init                          # 2 words = longer
```

**Verdict:** `up` is the sweet spot (short + clear)

---

## Migration Strategy

### Week 1: Add Aliases (Test)

```bash
# Add to ~/.config/zsh/functions/aliases.zsh or similar
alias up='status'
alias pinit='status --create'

# Test in real workflow
up mediationverse                  # Does it feel natural?
```

### Week 2: Soft Deprecation

```bash
# Modify status() function
status() {
    echo "💡 TIP: Use 'up' instead of 'status' for updates"
    echo "       Use 'dash' to show status"
    echo ""
    # ... rest of existing function ...
}
```

### Week 3: Full Migration

```bash
# Rename function: status() → up()
# Move create logic: status --create → pinit()
# Remove status() entirely or make it show help
```

### Week 4: Documentation Update

- Update all .md files
- Update help text
- Update WORKFLOW-QUICK-REFERENCE.md
- Update .STATUS file

---

## Before/After Summary

### Before (Confusing)

```
status                             # What does this do?
├── No args → Interactive UPDATE   # Unexpected!
├── --show → Show status          # Requires flag for obvious action
├── --create → Create .STATUS     # Unexpected!
└── 5 args → Quick UPDATE         # Reasonable
```

### After (Clear)

```
dash                               # Show status (existing)
up                                 # Update status (new, verb)
pinit                              # Project init (new, rare)
```

**Clarity:** 3 clear verbs > 1 multi-mode noun

---

## Command Frequency Analysis

| Command  | Frequency | Old Name            | New Name  | Saved Chars |
| -------- | --------- | ------------------- | --------- | ----------- |
| Show all | 10x/day   | `dash`              | `dash`    | 0           |
| Show one | 2x/day    | `status X --show`   | `dash X`  | -7          |
| Update   | 5x/day    | `status X`          | `up X`    | -4          |
| Create   | 1x/month  | `status X --create` | `pinit X` | +1          |

**Daily savings:** ~75 keystrokes (5 updates × 4 chars + 2 shows × 7 chars)

---

## User Testing Questions

Before finalizing, consider:

1. **Does `up` feel natural?**
   - Try: `up mediationverse`
   - Try: `up medfit active P1 "Docs" 60`

2. **Is `pinit` clear enough?**
   - Alternative: `pnew`, `pcreate`, `init-project`

3. **Does removing `status --show` feel OK?**
   - `dash project` should handle this

4. **Any muscle memory conflicts?**
   - Check existing aliases/functions

---

## Implementation Checklist

- [ ] Create `up()` function (copy from `status()`)
- [ ] Create `pinit()` function (extract from `status --create`)
- [ ] Update `dash` to handle single project (if not already)
- [ ] Add deprecation warning to `status()`
- [ ] Test all three modes:
  - [ ] `dash` shows all
  - [ ] `dash mediationverse` shows one
  - [ ] `up mediationverse` updates (interactive)
  - [ ] `up medfit active P1 "X" 60` updates (quick)
  - [ ] `pinit newproj` creates
- [ ] Update documentation:
  - [ ] WORKFLOW-QUICK-REFERENCE.md
  - [ ] ALIAS-REFERENCE-CARD.md
  - [ ] .STATUS file
  - [ ] Help text in functions
- [ ] Update tests (if any)
- [ ] Use in real workflow for 1 week
- [ ] Remove `status()` after confirmation

---

## Final Recommendation

**Replace:**

```bash
status mediationverse              # Confusing multi-mode command
```

**With:**

```bash
dash mediationverse                # Show status (read-only)
up mediationverse                  # Update status (write)
pinit new-project                  # Create .STATUS (rare)
```

**Why:**

- ✅ Clear action verbs (`up`, `pinit`)
- ✅ Consistent with your workflow (`work`, `finish`, `js`)
- ✅ Ultra-short for daily use (`up` = 2 chars)
- ✅ Leverages existing `dash` command
- ✅ Minimal migration (one rename)
- ✅ ADHD-friendly (clear, fast, memorable)

**Next:** Implement and test with aliases for 1 week.
