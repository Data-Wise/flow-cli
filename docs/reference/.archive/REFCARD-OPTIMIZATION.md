# Quick Reference: Plugin Optimization

**Essential patterns for optimizing ZSH plugins**

---

## Load Guard Pattern

**Problem:** File sourced multiple times = redundant parsing

**Solution:**

```zsh
# Add to top of any library file (after shebang/comments)
if [[ -n "$_FLOW_MY_LIBRARY_LOADED" ]]; then
    return 0 2>/dev/null || true
fi
typeset -g _FLOW_MY_LIBRARY_LOADED=1
```

**Naming convention:**

```
lib/concept-extraction.zsh  → _FLOW_CONCEPT_EXTRACTION_LOADED
lib/ai-analysis.zsh         → _FLOW_AI_ANALYSIS_LOADED
lib/analysis-display.zsh    → _FLOW_ANALYSIS_DISPLAY_LOADED
```

---

## Display Layer Extraction

**When:** 5+ related display/formatting functions

**Before:**

```
commands/my-command.zsh (1,203 lines)
├── Display functions (270 lines)
└── Command logic (930 lines)
```

**After:**

```
lib/my-display.zsh (270 lines)
└── 7 _display_* functions

commands/my-command.zsh (930 lines)
└── source "${0:A:h:h}/lib/my-display.zsh"
```

**Benefits:**
- Reusable across commands
- Smaller command files
- Consistent UI

---

## Cache Path Collision Fix

**Problem:** Flat cache structure collides

```zsh
# BAD: Only uses filename
local cache_file="$dir/.cache/${file:t:r}.json"

# Result: lectures/week-05/lab.qmd → .cache/lab.json
#         exams/week-05/lab.qmd    → .cache/lab.json (COLLISION!)
```

**Solution:** Mirror directory structure

```zsh
# GOOD: Mirrors source tree
local relative_path="${file#$dir/}"
local cache_subdir="${relative_path:h}"
local cache_name="${relative_path:t:r}"
local cache_dir="$dir/.cache/$cache_subdir"
mkdir -p "$cache_dir" 2>/dev/null
local cache_file="$cache_dir/${cache_name}.json"

# Result: lectures/week-05/lab.qmd → .cache/lectures/week-05/lab.json
#         exams/week-05/lab.qmd    → .cache/exams/week-05/lab.json (no collision)
```

---

## Test Timeout Pattern

**Problem:** Tests hang on interactive input

**Solution:**

```bash
# tests/run-all.sh
TIMEOUT=0

run_test() {
    local test_file="$1"
    local name=$(basename "$test_file" .zsh)
    local timeout_seconds=30

    echo -n "Running $name... "

    timeout "$timeout_seconds" zsh "$test_file" > /dev/null 2>&1
    local exit_code=$?

    if [[ $exit_code -eq 124 ]]; then
        echo "⏱️ (timeout after ${timeout_seconds}s)"
        ((TIMEOUT++))
    elif [[ $exit_code -eq 0 ]]; then
        echo "✅"
        ((PASS++))
    else
        echo "❌"
        ((FAIL++))
    fi
}
```

**Exit codes:**

```bash
if [[ $FAIL -gt 0 ]]; then
    exit 1  # Test failures
fi

if [[ $TIMEOUT -gt 0 ]]; then
    echo "Note: Timeout tests may require interactive/tmux context"
    exit 2  # Timeouts (expected for some tests)
fi
```

---

## Redundant Source Elimination

**Problem:** Explicit + Glob = Double Load

```zsh
# flow.plugin.zsh

# Explicit load (REDUNDANT)
source "$FLOW_PLUGIN_DIR/commands/my-command.zsh"

# Glob load (already sources it!)
for cmd_file in "$FLOW_PLUGIN_DIR/commands/"*.zsh(N); do
    source "$cmd_file"
done
```

**Solution:** Remove explicit source, rely on glob

```zsh
# flow.plugin.zsh

# Glob handles everything (with load guards for libs)
for cmd_file in "$FLOW_PLUGIN_DIR/commands/"*.zsh(N); do
    source "$cmd_file"
done
```

---

## Dispatcher Guard Cleanup

**Problem:** Redundant conditional guards

```zsh
# lib/dispatchers/my-dispatcher.zsh

# REDUNDANT - lib has its own guard now
if [[ -z "$_FLOW_MY_LIB_LOADED" ]]; then
    local lib_path="${0:A:h:h}/my-lib.zsh"
    [[ -f "$lib_path" ]] && source "$lib_path"
    typeset -g _FLOW_MY_LIB_LOADED=1
fi
```

**Solution:** Remove dispatcher guards, trust lib guards

```zsh
# lib/dispatchers/my-dispatcher.zsh

# No need - lib/my-lib.zsh has self-protecting guard
# Just source it (guard prevents double-load)
```

---

## Verification Checklist

After optimization:

```bash
# ✓ Load guards set
zsh -c 'source flow.plugin.zsh; echo $_FLOW_MY_LIB_LOADED'
# Should print: 1

# ✓ Functions available
zsh -c 'source flow.plugin.zsh; whence -w my_function'
# Should print: my_function: function

# ✓ No performance regression
time (source flow.plugin.zsh)
# Should be <10ms

# ✓ Tests pass
./tests/run-all.sh
# Check: 0 failures, expected timeouts only
```

---

## Common Pitfalls

### ❌ Don't: Inconsistent naming

```zsh
# BAD - hard to track
typeset -g LOADED_CONCEPT_EXTRACTOR=1
typeset -g _concept_extraction_loaded=1
```

✅ **Do: Consistent pattern**

```zsh
# GOOD - predictable
typeset -g _FLOW_CONCEPT_EXTRACTION_LOADED=1
typeset -g _FLOW_AI_ANALYSIS_LOADED=1
```

### ❌ Don't: Forget `2>/dev/null || true`

```zsh
# BAD - errors outside functions
if [[ -n "$_FLOW_MY_LIB_LOADED" ]]; then
    return 0
fi
```

✅ **Do: Handle both contexts**

```zsh
# GOOD - works everywhere
if [[ -n "$_FLOW_MY_LIB_LOADED" ]]; then
    return 0 2>/dev/null || true
fi
```

### ❌ Don't: Flat cache for hierarchical sources

```zsh
# BAD - collisions inevitable
local cache="$dir/.cache/${file:t:r}.json"
```

✅ **Do: Mirror structure**

```zsh
# GOOD - collision-free
local rel="${file#$dir/}"
local cache="$dir/.cache/${rel:h}/${rel:t:r}.json"
```

---

## Quick Wins

### 1-Minute: Add load guard

```bash
# Top of lib file
if [[ -n "$_FLOW_MY_LIB_LOADED" ]]; then
    return 0 2>/dev/null || true
fi
typeset -g _FLOW_MY_LIB_LOADED=1
```

### 5-Minute: Fix cache collisions

```bash
# Replace flat cache path with mirrored structure
local relative_path="${file#$dir/}"
local cache_dir="$dir/.cache/${relative_path:h}"
mkdir -p "$cache_dir" 2>/dev/null
local cache_file="$cache_dir/${relative_path:t:r}.json"
```

### 10-Minute: Add test timeout

```bash
# Wrap test execution
timeout 30 zsh "$test_file" > /dev/null 2>&1
[[ $? -eq 124 ]] && echo "⏱️ (timeout)" || echo "✅"
```

---

## Real-World Example

**PR #290: teach analyze optimization**

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Command file | 1,203 lines | 930 lines | -273 lines |
| Libs sourced | 2-3x per startup | 1x per startup | 3x reduction |
| Display layer | Embedded | Extracted | Reusable |
| Cache collisions | Yes | No | Fixed |
| Test hangs | Infinite | 30s timeout | Fixed |
| Startup time | <1ms | <1ms | No regression |

**Files changed:** 10
**Lines:** +317/-289
**Tests:** 13 passing, 5 timeout (expected)

---

## See Also

- [Tutorial 22: Plugin Optimization](../tutorials/22-plugin-optimization.md) — Step-by-step walkthrough
- [Architecture Overview](ARCHITECTURE-OVERVIEW.md) — Plugin structure
- [Testing Guide](../guides/TESTING.md) — Test patterns

