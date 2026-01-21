# Index Manipulation Fixes - Summary

**Date:** 2026-01-20
**File:** `lib/index-helpers.zsh`
**Tests Fixed:** 4/4 (Tests 12, 13, 14, 15)

## Problem

Index ADD/UPDATE/REMOVE operations were incomplete, causing 3-4 test failures:
1. Test 12: `test_add_to_index` - Link not added to index
2. Test 13: Verify sorting - Links not sorted by week number
3. Test 14: `test_update_index_entry` - Title update fails
4. Test 15: `test_remove_from_index` - Link not removed

## Root Causes

1. **Regex pattern matching failed** - ZSH regex `^\-\ \[.*\]\((.*)\)` didn't match markdown links
2. **Insertion point calculation** - Was returning wrong line number (7 instead of 6)
3. **Remove function** - Was searching for basename only, not full path

## Solutions Implemented

### 1. Fixed `_find_insertion_point()` (Line 313-327)

**Problem:** Regex pattern `^\-\ \[.*\]\((.*)\)` never matched markdown links

**Solution:** Replaced regex with simple string matching + sed extraction

```zsh
# OLD (broken regex):
if [[ "$line" =~ ^\-\ \[.*\]\((.*)\) ]]; then
    local linked_file="${match[1]}"

# NEW (string match + sed):
if [[ "$line" == *"]("*")"* || "$line" == *"]("*")" ]]; then
    local linked_file=$(echo "$line" | sed -n 's/.*(\(.*\))/\1/p')
```

**Result:**
- Correctly extracts filenames from markdown links
- Properly calculates insertion point for week-based sorting
- Test 13 (sorting) now passes

### 2. Fixed `_update_index_link()` (Line 236-237)

**Problem:** grep -F with incorrect pattern didn't find existing links

**Solution:** Use fixed string search for exact filename matching

```zsh
# OLD:
local existing_line=$(grep -n "(\s*${basename}\s*)" "$index_file" 2>/dev/null | cut -d: -f1)

# NEW:
local existing_line=$(grep -n -F "($basename)" "$index_file" 2>/dev/null | cut -d: -f1)
```

**Result:**
- Test 12 (add new) now passes
- Test 14 (update existing) now passes

### 3. Fixed `_remove_index_link()` (Line 347-354)

**Problem:** Searched for basename only `(week-10.qmd)`, missed full path `(lectures/week-10.qmd)`

**Solution:** Try full path first, fallback to basename

```zsh
# OLD (basename only):
local line_num=$(grep -n -F "($basename)" "$index_file" 2>/dev/null | cut -d: -f1)

# NEW (full path + fallback):
local line_num=$(grep -n -F "($content_file)" "$index_file" 2>/dev/null | cut -d: -f1)
if [[ -z "$line_num" ]]; then
    # Try basename only
    line_num=$(grep -n -F "($basename)" "$index_file" 2>/dev/null | cut -d: -f1)
fi
```

**Result:**
- Test 15 (remove link) now passes
- Handles both `lectures/week-01.qmd` and `week-01.qmd` formats

## Test Results

**Before fixes:** 18/25 passing (72%)
**After fixes:** 23/25 passing (92%)

**Fixed tests:**
- ✅ Test 12: Add new link to index
- ✅ Test 13: Verify links sorted by week number
- ✅ Test 14: Update existing link in index
- ✅ Test 15: Remove link from index

**Still failing (not part of this task):**
- ❌ Test 16: Find dependencies (sourced files) - Different issue
- ❌ Test 17: Find dependencies (cross-references) - Different issue

## Files Modified

- `lib/index-helpers.zsh`
  - `_find_insertion_point()` - Line 313-327 (regex → sed)
  - `_update_index_link()` - Line 236-237 (grep pattern fix)
  - `_remove_index_link()` - Line 347-354 (fallback search)

## Verification

```bash
./tests/test-index-management-unit.zsh
# Result: 23/25 PASSED (92%)
```

## Impact

- `teach deploy` index updates now work correctly
- Links properly sorted by week number
- Both add and update operations functional
- Remove operation handles both path formats

---

**Completed:** 2026-01-20
**Estimated Time:** 2 hours
**Actual Time:** ~1.5 hours
