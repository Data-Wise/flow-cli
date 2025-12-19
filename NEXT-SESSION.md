# Next Session - Alias Refactoring

## Quick Context

**Last session:** Fixed Positron parse error + created alias refactoring proposals
**Status:** Planning complete, ready to implement
**Decision needed:** Choose Option 1, 2, or 3

---

## Read This First

📄 **Main Proposal:** `~/ALIAS-REFACTOR-ADHD.md`
- ADHD-friendly structure
- Three clear options
- Step-by-step guides

---

## Three Options (Quick Summary)

### Option 1: Quick Wins (20 min)
- Remove 30 aliases
- Add typo handler
- Consolidate dashboard
- Keep everything else

### Option 2: Dispatcher Pattern ⭐ (1 hour)
- Remove 70 aliases
- Add `r` dispatcher for R commands
- Everything from Option 1
- **Recommended**

### Option 3: Maximum Cleanup (2 hours)
- Remove 85 aliases
- Full namespace organization
- Everything from Option 2
- Enhanced help system

---

## What Never Changes

Your 23 workflow commands stay exactly the same:
- `work`, `finish`, `vibe`, `js`, `why`, `win`, `yay`, `wins`
- `f`, `f15`, `wn`, `wl`, `now`, `next`
- `pt`, `pb`, `pc`, `pr`, `pv`, `pick`
- `rload`, `rtest`, `rdoc`, `rcheck`, `rcycle`
- `cc`, `dash`, `gm`

**Nothing breaks. Zero risk.**

---

## If You Choose Option 2

### Phase 1: Add Functions (10-15 min)
```bash
# I'll create these files:
# 1. Typo handler in adhd-helpers.zsh
# 2. Enhanced dash() function
# 3. R dispatcher function

# You test them alongside existing aliases
```

### Phase 2: Test (A Few Days)
```bash
# Try the new patterns:
dash view         # Instead of nsyncview
r cov             # Instead of rcov
r check:cran      # Instead of rcheckcran

# Old aliases still work during testing
```

### Phase 3: Cleanup (10 min)
```bash
# Once comfortable, remove old aliases:
# - 18 typo aliases
# - 8 dashboard aliases
# - 24 R extended aliases

# Done!
```

---

## Files to Review

1. `~/ALIAS-REFACTOR-ADHD.md` ⭐ **Start here**
2. `~/ALIAS-REFACTORING-PROPOSAL-V2.md` (Technical details)
3. `~/SESSION-SUMMARY-2025-12-18-PART2.md` (What we did)

---

## Quick Start (Next Session)

1. **Read:** `~/ALIAS-REFACTOR-ADHD.md` (3 min)
2. **Decide:** Option 1, 2, or 3
3. **Say:** "Let's implement Option X"
4. **I'll:** Create the files and guide you through testing

---

## Notes

- All proposals preserve your workflow 100%
- Old + new coexist during testing
- Fully reversible at any stage
- No pressure to change anything

**Your current setup works fine. This is optional cleanup.**
