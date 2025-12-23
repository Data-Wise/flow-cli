# Link Check Fixes - Quick Patches

**Date:** 2025-12-22
**Related:** LINK-CHECK-REPORT.md

---

## Fix 1: Remove Broken Architecture Links

**File:** `docs/architecture/ARCHITECTURE-QUICK-WINS.md` (lines 611-614)

**Current (broken):**
```markdown
**For quick reference:**

- [Architecture Cheatsheet](ARCHITECTURE-CHEATSHEET.md) - 1-page printable
- [Architecture Command Reference](ARCHITECTURE-COMMAND-REFERENCE.md) - Command patterns
```

**Fix Option A - Remove section:**
```markdown
(Delete lines 611-614)
```

**Fix Option B - Replace with existing docs:**
```markdown
**For quick reference:**

- [Architecture Quick Reference](QUICK-REFERENCE.md) - Comprehensive reference
- [Architecture README](README.md) - Full documentation
```

**Recommended:** Option B (point to actual existing content)

---

## Fix 2: GitHub URL Case

**File:** `docs/index.md` (line 255)

**Current:**
```markdown
**Repository:** [GitHub](https://github.com/Data-Wise/flow-cli)
```

**Fixed:**
```markdown
**Repository:** [GitHub](https://github.com/Data-Wise/flow-cli)
```

**Change:** `data-wise` → `Data-Wise` (capitalize D and W)

---

## Apply Fixes

### Manual Approach

```bash
# Fix 1: Edit ARCHITECTURE-QUICK-WINS.md
# Find lines 611-614 and replace with Option B above

# Fix 2: GitHub URL
sed -i '' 's|github.com/Data-Wise/flow-cli|github.com/Data-Wise/flow-cli|g' docs/index.md
```

### Verification

```bash
# Re-run link checker
node scripts/check-links.js

# Should show: "Broken links: 0"
```

---

## Notes

- Both fixes are non-breaking (documentation only)
- No functionality impact
- Can be applied independently
- Low priority (documentation still usable as-is)
