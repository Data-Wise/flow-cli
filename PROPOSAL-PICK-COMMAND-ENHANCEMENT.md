# Pick Command Enhancement Proposal

**Generated:** 2025-12-18
**Updated:** 2025-12-18
**Current Location:** `~/.config/zsh/functions/adhd-helpers.zsh:1864-2010`
**Status:** ✅ IMPLEMENTED - Option B (Comprehensive Fix)

---

## ✅ Implementation Summary

**Completed:** 2025-12-18

### What Was Implemented

1. ✅ **Fixed subshell output pollution** - Process substitution instead of pipe
2. ✅ **Branch name truncation** - Added `_truncate_branch()` helper (20 char limit)
3. ✅ **fzf key bindings** - Ctrl-W (work), Ctrl-O (code), Enter (cd)
4. ✅ **Error handling** - Empty list check, directory validation, stderr redirection
5. ✅ **Fast mode** - `pick --fast [category]` skips git status
6. ✅ **Category normalization** - Supports multiple aliases (r/R/rpack, dev/DEV/tool, etc.)
7. ✅ **Dynamic headers** - Shows category filter in header ("PROJECT PICKER - R Packages")

### Usage

```bash
# All formats work:
pick              # All projects
pick r            # R packages (normalized: r/R/rpack/rpkg)
pick dev          # Dev tools (normalized: dev/DEV/tool/tools)
pick qu           # Quarto projects (normalized: q/Q/qu/quarto)
pick --fast       # Fast mode (no git)
pick --fast dev   # Fast mode with filter

# Aliases still work:
pickr             # Expands to: pick r
pickdev           # Expands to: pick dev
pickq             # Expands to: pick q

# Interactive actions:
# Enter: cd to project
# Ctrl-W: cd + work
# Ctrl-O: cd + code .
# Ctrl-C: cancel
```

### Test Results

All tests passed:
- ✅ Syntax validation
- ✅ No output pollution (debug messages isolated)
- ✅ Long branch names truncated (e.g., `claude/check-meas...`)
- ✅ Category normalization (r/R/dev/DEV/tool all work)
- ✅ Dynamic headers show correct filter
- ✅ Empty category handling
- ✅ Fast mode works

---

## Issues Identified

### 1. **Subshell Output Pollution** (Critical)
**Problem:** The `while` loop runs in a subshell due to the pipe, causing any debug output to leak into the tmpfile:
```zsh
_proj_list_all "$category" | while IFS='|' read -r name type icon dir; do
    # Any echo here goes to tmpfile!
    local git_info=$(_proj_git_status "$dir")
    # ...
done > "$tmpfile"
```

**Impact:** Corrupted fzf display with debug messages mixed into project list

**Root Cause:** Pipe creates subshell; stdout redirects ALL output to tmpfile

---

### 2. **Long Branch Name Formatting** (High)
**Problem:** Git branch names can be very long (e.g., `claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im`)

**Current Output:**
```
medrobust            📦 r    ✅ [claude/check-measurement-error-project-011CV4N39kJ3T4FdXg7G92im]
```

**Impact:** Line wrapping, misaligned columns, hard to scan visually

---

### 3. **Missing fzf Key Bindings** (Medium)
**Problem:** Header says "Ctrl-W=work" but no binding exists:
```zsh
fzf --height=50% --reverse --header="Select project (Enter=cd, Ctrl-W=work)"
```

**Impact:** Misleading UI, broken feature promise

---

### 4. **Performance Issues** (Medium)
**Problem:** For each project, runs 4+ git commands:
- `git branch --show-current`
- `git status --porcelain`
- `git rev-parse --verify main`
- `git rev-parse --verify dev`
- `git rev-list --count main..dev` (2 times)

**Impact:** Slow on large project lists (50+ projects = 250+ git calls)

---

### 5. **No Error Handling** (Medium)
**Problem:** No validation for:
- Empty project list
- Git command failures
- Directory permission issues
- fzf cancellation handling

**Impact:** Silent failures, confusing UX

---

### 6. **Inconsistent IFS Parsing** (Low)
**Problem:** Uses `IFS='|'` in while loop but variable already pipe-delimited:
```zsh
_proj_list_all "$category" | while IFS='|' read -r name type icon dir; do
```

**Current behavior:** Works but fragile if project names contain spaces/special chars

---

## Enhancement Options

### Option A: Quick Fix (⚡ 30 min)
**Focus:** Fix critical subshell issue only

**Changes:**
1. Use process substitution instead of pipe
2. Redirect stderr to /dev/null inside loop
3. Add basic empty check

**Pros:**
- Minimal code change
- Fixes immediate "erratic" behavior

**Cons:**
- Doesn't address performance or UX issues
- Still slow on large repos

---

### Option B: Comprehensive Fix (🔧 1-2 hours)
**Focus:** Fix all major issues, add requested features

**Changes:**
1. **Subshell fix:** Use process substitution + array
2. **Branch truncation:** Truncate to 20 chars with ellipsis
3. **fzf bindings:** Add Ctrl-W for `work`, Ctrl-O for `code .`
4. **Performance:** Cache git status, parallel execution option
5. **Error handling:** Validate inputs, handle empty lists
6. **Better formatting:** Aligned columns, color coding

**Pros:**
- Production-ready
- ADHD-friendly (clear visual hierarchy)
- Performance improvements

**Cons:**
- More testing needed
- Larger diff

---

### Option C: Complete Redesign (🏗️ Future)
**Focus:** Modern TUI with live filtering

**Vision:**
- Real-time git status updates
- Multi-select support
- Fuzzy search with previews
- Action menu (cd, work, code, finish)
- Status file integration

**Implementation:**
- Use `gum` or custom TUI framework
- Background worker for git status
- Rich preview pane

**Timeline:** P6 (Future enhancement)

---

## Recommended Path

**→ Start with Option B** because:
1. Fixes immediate "erratic" behavior
2. Delivers the Ctrl-W feature hinted in header
3. Improves performance enough to be usable
4. Sets foundation for future TUI work (Option C)

---

## Implementation Plan (Option B)

### Phase 1: Fix Subshell Issue
```zsh
# BEFORE (broken):
_proj_list_all | while read ...; do
    # output leaks
done > "$tmpfile"

# AFTER (fixed):
while IFS='|' read -r name type icon dir; do
    # stderr isolated
done < <(_proj_list_all "$category") > "$tmpfile" 2>/dev/null
```

### Phase 2: Add Branch Truncation
```zsh
_truncate_branch() {
    local branch="$1"
    local max_len=20
    if [[ ${#branch} -gt $max_len ]]; then
        echo "${branch:0:17}..."
    else
        echo "$branch"
    fi
}
```

### Phase 3: Add fzf Key Bindings
```zsh
local selection=$(cat "$tmpfile" | fzf \
    --height=50% \
    --reverse \
    --header="Enter=cd | Ctrl-W=work | Ctrl-O=code | Ctrl-C=cancel" \
    --bind="ctrl-w:execute-silent(echo work > /tmp/pick-action)+accept" \
    --bind="ctrl-o:execute-silent(echo code > /tmp/pick-action)+accept")
```

### Phase 4: Add Error Handling
```zsh
# Check for empty list
if [[ ! -s "$tmpfile" ]]; then
    echo "❌ No projects found${category:+ in category '$category'}"
    rm -f "$tmpfile"
    return 1
fi

# Handle fzf cancellation
if [[ -z "$selection" ]]; then
    rm -f "$tmpfile"
    return 0  # Clean exit, not error
fi
```

### Phase 5: Performance Optimization (Optional)
```zsh
# Option 1: Skip git status for faster load
pick --fast  # No git info, just list projects

# Option 2: Parallel git calls (GNU parallel or xargs)
# (Add only if testing shows significant slowness)
```

---

## Testing Checklist

- [ ] Empty project list (no .git dirs)
- [ ] Single project
- [ ] 50+ projects (performance)
- [ ] Projects with spaces in names
- [ ] Long branch names (40+ chars)
- [ ] Dirty git status (changes present)
- [ ] Clean git status
- [ ] Non-git directories
- [ ] Ctrl-W binding works
- [ ] Ctrl-O binding works
- [ ] Ctrl-C/Esc cancellation
- [ ] Each category filter (r, dev, q, etc.)

---

## Breaking Changes

None. The function signature remains:
```zsh
pick [category]
```

Aliases remain:
```zsh
pickr, pickdev, pickq
```

---

## Example Output (After Fix)

```
╔════════════════════════════════════════════════════════════╗
║  🔍 PROJECT PICKER                                         ║
╚════════════════════════════════════════════════════════════╝

mediationverse       📦 r    ⚠️  [main]
medfit               📦 r    ✅ [dev]
medrobust            📦 r    ✅ [claude/check-mea...]
zsh-configuration    🔧 dev  ⚠️  [dev]
claude-mcp           🔧 dev  ✅ [main]

Enter=cd | Ctrl-W=work | Ctrl-O=code | Ctrl-C=cancel
```

---

## Files to Modify

1. **`~/.config/zsh/functions/adhd-helpers.zsh`**
   - Lines 1863-1908 (pick function)
   - Add new helper: `_truncate_branch()`

2. **`~/.config/zsh/tests/test-adhd-helpers.zsh`**
   - Add test suite for pick command
   - Edge cases: empty, long names, special chars

3. **Documentation (this repo)**
   - Update `WORKFLOW-QUICK-REFERENCE.md`
   - Update `ALIAS-REFERENCE-CARD.md` with new keybindings

---

## Future Enhancements (P6+)

- [ ] Preview pane showing .STATUS file
- [ ] Multi-select for batch operations
- [ ] Recent projects list (frecency algorithm)
- [ ] Workspace support (open in split editors)
- [ ] Integration with `work` session tracking
- [ ] Visual git graph in preview
- [ ] Search by file contents (ripgrep)

---

## Questions for User

1. **Performance:** Do you have >50 projects? Should we add parallel git calls?
2. **Actions:** Besides `work` and `code`, what other actions would be useful?
   - `finish`?
   - `status`?
   - `gh pr create`?
3. **Formatting:** Prefer truncated branches or wrap to next line?
4. **Filters:** Want to filter by git status (dirty/clean) or .STATUS progress?
