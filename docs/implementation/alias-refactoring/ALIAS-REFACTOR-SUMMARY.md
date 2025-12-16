# Alias Refactoring Summary
**Date:** 2025-12-14
**Status:** Planning Complete - Ready for Future Implementation
**Current State:** 167 aliases analyzed

---

## 📁 Planning Documents

All detailed plans are saved in this directory:

1. **ALIAS-REFACTOR-PLAN-2025-12-14.md**
   - Initial comprehensive analysis
   - Detailed breakdown of all 167 aliases
   - First proposal for refactoring

2. **ALIAS-REFACTOR-PLANS-A-B-2025-12-14.md**
   - Two revised plans based on user feedback
   - Plan A: Verb-Noun pattern
   - Plan B: Namespace pattern

3. **ALIAS-REFACTOR-3-PLANS-2025-12-14.md**
   - Three plans extending the `proj-*` pattern
   - Plan A: Full domain names
   - Plan B: Short domain names
   - Plan C: Action-domain pattern

4. **ALIAS-REFACTOR-EXISTING-PATTERNS-2025-12-14.md** ⭐ **FINAL**
   - Most comprehensive analysis
   - Based on existing 5 patterns in current config
   - Three plans with detailed comparison tables
   - **Recommended starting point for implementation**

---

## 🎯 Quick Summary: Three Final Plans

### Plan A: Minimal Changes
- **Aliases:** 125 (25% reduction)
- **Philosophy:** Keep what works, remove duplicates
- **Effort:** 2 hours
- **Risk:** Safe
- **Best for:** Conservative approach, minimal disruption

**What stays:**
- High-frequency shortcuts: `ts`, `rd`, `qp`, `cc`
- Atomic pairs: `lt`, `dt`
- Domain-action: `proj-*`, `nsync`

**What goes:**
- 1-letter conflicts: `c`, `t`, `q`, `d`
- Duplicates: `dc`, `ld`, `ck`, `bd`
- 17 Claude prompts
- 8 Gemini variants
- 3 deprecated

---

### Plan B: Full Standardization
- **Aliases:** 90 (46% reduction)
- **Philosophy:** One pattern everywhere (domain-action)
- **Effort:** 1 week (relearning muscle memory)
- **Risk:** Moderate
- **Best for:** Clean slate, long-term consistency

**Changes:**
- `rtest` → `r-test`
- `qp` → `quarto-preview` or `q-preview`
- `cc` → `claude-start`
- `ccc` → `claude-continue`

---

### Plan C: Hybrid Frequency-Based ⭐ **RECOMMENDED**
- **Aliases:** 110 (34% reduction)
- **Philosophy:** Speed for common (30x/day), clarity for rare (5x/day)
- **Effort:** 3-4 hours
- **Risk:** Low
- **Best for:** ADHD-optimized, pragmatic balance

**Keep shortcuts for high-frequency:**
```bash
ts='rtest'      # 30x/day - keep fast
rd='rdoc'       # 20x/day - keep fast
qp='quarto preview'
cc='claude'
lt='rload && rtest'
dt='rdoc && rtest'
```

**Standardize medium-frequency:**
```bash
ccplan → claude-plan
gmy    → gemini-yolo
gms    → gemini-sandbox
```

**Remove conflicts:**
```bash
c, t, q, d      # 1-letter conflicts
dc, ld, ck, bd  # Duplicates
```

---

## 🔍 Key Insights

### Current Patterns (5 total)
1. **Full names:** `rload`, `rtest`, `rdoc` (clear)
2. **Two-letter:** `ts`, `rd`, `rc` (fast for daily use)
3. **One-letter:** `t`, `c`, `q` (hard to remember - user feedback)
4. **Atomic pairs:** `lt`, `dt` (ADHD gold)
5. **Domain-action:** `proj-status`, `nsync` (user likes this!)

### Problems Identified
- **Duplicates:** 15+ aliases doing the same thing
- **Conflicts:** 1-letter aliases conflict with common tools
- **Over-proliferation:** 17 Claude prompts, 13 Gemini variants
- **Mixed patterns:** Inconsistent naming makes it hard to remember

### User Preferences
- ✅ Likes `proj-*` pattern (domain-action)
- ❌ Finds 1-2 letter aliases hard to remember
- ✅ Values ADHD-friendly mnemonics
- ✅ Wants consolidated, meaningful aliases

---

## 📊 Comparison Table

| Aspect | Plan A | Plan B | Plan C ⭐ |
|--------|--------|--------|----------|
| **Total Aliases** | 125 | 90 | 110 |
| **Reduction** | 25% | 46% | 34% |
| **Effort** | 2 hours | 1 week | 3-4 hours |
| **Risk** | Safe | Moderate | Low |
| **Keep `ts`** | ✅ | ❌ | ✅ |
| **Keep `rd`** | ✅ | ❌ | ✅ |
| **Keep `qp`** | ✅ | ❌ | ✅ |
| **Keep `cc`** | ✅ | ❌ | ✅ |
| **Standardize medium-freq** | ❌ | ✅ | ✅ |
| **ADHD-Friendly** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

---

## ✅ Next Steps (When Ready to Implement)

### Phase 1: Choose Plan
- [ ] Review `ALIAS-REFACTOR-EXISTING-PATTERNS-2025-12-14.md`
- [ ] Decide: Plan A, B, or C
- [ ] Recommendation: Plan C (best ADHD balance)

### Phase 2: Preparation
- [ ] Backup current config
- [ ] Create migration script
- [ ] Document muscle memory changes

### Phase 3: Soft Launch (Week 1)
- [ ] Add new aliases alongside old ones
- [ ] Both systems work in parallel
- [ ] Start using new patterns when remembered

### Phase 4: Transition (Week 2-3)
- [ ] Use new aliases more frequently
- [ ] Monitor what sticks
- [ ] Adjust based on real usage

### Phase 5: Finalize (Week 4)
- [ ] Remove old aliases that aren't being used
- [ ] Update help system
- [ ] Update documentation
- [ ] Run test suite

---

## 📝 Quick Reference

**Want to implement?**
1. Read: `ALIAS-REFACTOR-EXISTING-PATTERNS-2025-12-14.md`
2. Choose: Plan A, B, or C
3. Run migration script (to be created)
4. Test for 1-3 weeks
5. Finalize

**Just want a reminder?**
- Current: 167 aliases (too many, duplicates, conflicts)
- Target: 90-125 aliases (clean, consistent, ADHD-friendly)
- Recommended: Plan C (keep fast shortcuts, standardize the rest)

---

## 🎉 Expected Benefits

**After implementation:**
- ✅ No more "which alias do I use?" confusion
- ✅ Faster discovery (tab completion)
- ✅ Less cognitive load (fewer decisions)
- ✅ Better muscle memory (consistent patterns)
- ✅ Easier onboarding (clear naming)
- ✅ More ADHD-friendly (meaningful mnemonics)

---

*Created: 2025-12-14*
*Status: Ready for future implementation*
*Location: ~/projects/dev-tools/zsh-configuration/*
