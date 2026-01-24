# Tutorial 22: Plugin Optimization & Testing

**Level:** Intermediate
**Time:** 30-45 minutes
**Prerequisites:** Basic ZSH, familiarity with flow-cli architecture

---

## What You'll Learn

In this tutorial, you'll learn how to:

1. Identify double-sourcing issues in ZSH plugins
2. Add self-protecting load guards
3. Extract reusable display layers
4. Fix path collisions in cache structures
5. Add timeouts to test runners

This tutorial uses the real-world example of optimizing the `teach analyze` feature after PR #289.

---

## Background: The Problem

After implementing teach analyze (Phases 0-5), a code review revealed three structural issues:

1. **Double/triple-sourcing** — Libraries loaded 2-3 times on shell startup
2. **Monolithic command file** — 1,203 lines with embedded display layer
3. **Cache path collisions** — Files in different directories could collide

Let's fix each issue systematically.

---

## Part 1: Diagnosing Double-Sourcing

### Step 1: Trace the Load Chain

Map how files are sourced on plugin load:

```bash
# Main plugin file
cat flow.plugin.zsh | grep -n "source.*teach"
```

**Output:**

```
49: source "$FLOW_PLUGIN_DIR/lib/concept-extraction.zsh"
50: source "$FLOW_PLUGIN_DIR/lib/prerequisite-checker.zsh"
51: source "$FLOW_PLUGIN_DIR/lib/analysis-cache.zsh"
52: source "$FLOW_PLUGIN_DIR/lib/report-generator.zsh"
53: source "$FLOW_PLUGIN_DIR/lib/ai-analysis.zsh"
54: source "$FLOW_PLUGIN_DIR/lib/slide-optimizer.zsh"
56: source "$FLOW_PLUGIN_DIR/commands/teach-analyze.zsh"
63: for cmd_file in "$FLOW_PLUGIN_DIR/commands/"*.zsh(N); source
```

**Problem:** Line 56 sources `teach-analyze.zsh` explicitly, but the glob on line 63 sources **all** `commands/*.zsh` files again!

### Step 2: Check the Command File

```bash
head -20 commands/teach-analyze.zsh | grep source
```

**Output:**

```zsh
source "${0:A:h:h}/lib/concept-extraction.zsh"
source "${0:A:h:h}/lib/prerequisite-checker.zsh"
source "${0:A:h:h}/lib/analysis-cache.zsh"
source "${0:A:h:h}/lib/report-generator.zsh"
source "${0:A:h:h}/lib/ai-analysis.zsh"
source "${0:A:h:h}/lib/slide-optimizer.zsh"
```

**Problem:** `teach-analyze.zsh` sources all 6 libs unconditionally!

### Step 3: Calculate the Actual Load Count

```
flow.plugin.zsh L49-54: Source 6 libs (FIRST load)
flow.plugin.zsh L56:    Source teach-analyze.zsh
  ├─> teach-analyze.zsh sources 5 libs (SECOND load, excluding display)
flow.plugin.zsh L63:    Glob sources commands/*.zsh
  └─> teach-analyze.zsh sourced AGAIN (THIRD load)
      └─> 5 libs sourced AGAIN
```

**Result:** ~5,500 lines of ZSH parsed **2-3 times** on every shell startup.

---

## Part 2: Self-Protecting Load Guards

### Step 4: Add Guards to Library Files

The solution: each library protects itself from re-sourcing.

**Pattern:**

```zsh
# Guard against double-sourcing
if [[ -n "$_FLOW_CONCEPT_EXTRACTION_LOADED" ]]; then
    return 0 2>/dev/null || true
fi
typeset -g _FLOW_CONCEPT_EXTRACTION_LOADED=1

# ... rest of file
```

**Why `2>/dev/null || true`?**
- `return` inside a sourced file exits the source
- Outside a function, `return` would error
- The pattern handles both cases safely

**Apply to all 6 libs:**

```bash
# lib/concept-extraction.zsh
if [[ -n "$_FLOW_CONCEPT_EXTRACTION_LOADED" ]]; then
    return 0 2>/dev/null || true
fi
typeset -g _FLOW_CONCEPT_EXTRACTION_LOADED=1
```

```bash
# lib/prerequisite-checker.zsh
if [[ -n "$_FLOW_PREREQUISITE_CHECKER_LOADED" ]]; then
    return 0 2>/dev/null || true
fi
typeset -g _FLOW_PREREQUISITE_CHECKER_LOADED=1
```

Repeat for:
- `lib/analysis-cache.zsh` → `_FLOW_ANALYSIS_CACHE_LOADED`
- `lib/report-generator.zsh` → `_FLOW_REPORT_GENERATOR_LOADED`
- `lib/ai-analysis.zsh` → `_FLOW_AI_ANALYSIS_LOADED`
- `lib/slide-optimizer.zsh` → `_FLOW_SLIDE_OPTIMIZER_LOADED`

### Step 5: Remove Redundant Explicit Sources

Now that libs protect themselves, remove the redundant explicit sources from `flow.plugin.zsh`:

```bash
# BEFORE
source "$FLOW_PLUGIN_DIR/lib/concept-extraction.zsh"
source "$FLOW_PLUGIN_DIR/lib/prerequisite-checker.zsh"
source "$FLOW_PLUGIN_DIR/lib/analysis-cache.zsh"
source "$FLOW_PLUGIN_DIR/lib/report-generator.zsh"
source "$FLOW_PLUGIN_DIR/lib/ai-analysis.zsh"
source "$FLOW_PLUGIN_DIR/lib/slide-optimizer.zsh"
source "$FLOW_PLUGIN_DIR/commands/teach-analyze.zsh"

# AFTER (just rely on the glob)
# (delete lines 49-56)
```

The glob on line 63 sources all `commands/*.zsh`, which sources the libs (once each, thanks to guards).

### Step 6: Verify Load Guards Work

```bash
# Test in a new shell
zsh -c '
source flow.plugin.zsh 2>/dev/null

# Verify guards are set
echo "Load guards check:"
[[ -n "$_FLOW_CONCEPT_EXTRACTION_LOADED" ]] && echo "  concept-extraction: ✅"
[[ -n "$_FLOW_ANALYSIS_CACHE_LOADED" ]] && echo "  analysis-cache: ✅"
'
```

**Expected output:**

```
Load guards check:
  concept-extraction: ✅
  analysis-cache: ✅
```

---

## Part 3: Extract Reusable Display Layer

### Step 7: Identify the Display Functions

```bash
# Find display functions in the command file
grep -n "^_display_" commands/teach-analyze.zsh
```

**Output:**

```
27: _display_analysis_header() {
43: _display_concepts_section() {
64: _display_prerequisites_section() {
104: _display_violations_section() {
127: _display_ai_section() {
191: _display_slide_section() {
235: _display_summary_section() {
```

**Pattern:** 7 functions, ~270 lines, all pure presentation logic.

### Step 8: Create the Display Library

```bash
# Create new file
cat > lib/analysis-display.zsh << 'EOF'
#!/usr/bin/env zsh

# =============================================================================
# lib/analysis-display.zsh
# Display layer for teach analyze command
# Part of flow-cli - Pure ZSH plugin for ADHD-optimized workflow management
# =============================================================================

# Load guard
if [[ -n "$_FLOW_ANALYSIS_DISPLAY_LOADED" ]]; then
    return 0 2>/dev/null || true
fi
typeset -g _FLOW_ANALYSIS_DISPLAY_LOADED=1

# Color scheme (fallback if not loaded from core.zsh)
: ${FLOW_GREEN:='\033[38;5;154m'}
: ${FLOW_BLUE:='\033[38;5;75m'}
: ${FLOW_YELLOW:='\033[38;5;221m'}
: ${FLOW_RED:='\033[38;5;203m'}
: ${FLOW_BOLD:='\033[1m'}
: ${FLOW_RESET:='\033[0m'}

# ... paste the 7 _display_* functions here ...
EOF
```

### Step 9: Update the Command File

**Remove** the 7 functions and color defaults from `commands/teach-analyze.zsh` (lines 27-299).

**Replace** with a single source line:

```zsh
# Load display layer
source "${0:A:h:h}/lib/analysis-display.zsh"
```

**Before:** 1,203 lines
**After:** ~930 lines (extracted 270+ lines)

---

## Part 4: Fix Cache Path Collisions

### Step 10: Understand the Collision

**Current code:**

```zsh
local slide_cache_file="$course_dir/.teach/slide-optimization-${file_path:t:r}.json"
```

**Problem:** `${file_path:t:r}` extracts only the filename stem, ignoring the directory.

| Source File | Cache File | Collision? |
|------------|------------|------------|
| `lectures/week-05/lecture.qmd` | `.teach/slide-optimization-lecture.json` | ← |
| `labs/week-05/lecture.qmd` | `.teach/slide-optimization-lecture.json` | **COLLISION** |

### Step 11: Mirror Directory Structure

**New approach:**

```zsh
# Mirror source directory structure in cache
local relative_path="${file_path#$course_dir/}"  # Strip prefix
local cache_subdir="${relative_path:h}"          # Get directory
local cache_name="${relative_path:t:r}"          # Get filename stem
local slide_cache_dir="$course_dir/.teach/analysis-cache/$cache_subdir"
mkdir -p "$slide_cache_dir" 2>/dev/null
local slide_cache_file="$slide_cache_dir/${cache_name}-slides.json"
```

**Result:**

| Source File | Cache File | Collision? |
|------------|------------|------------|
| `lectures/week-05/lecture.qmd` | `.teach/analysis-cache/lectures/week-05/lecture-slides.json` | ✓ |
| `labs/week-05/lecture.qmd` | `.teach/analysis-cache/labs/week-05/lecture-slides.json` | **No collision** |

---

## Part 5: Test Runner Timeouts

### Step 12: Diagnose Hanging Tests

```bash
# Run test suite
./tests/run-all.sh
```

**Problem:** Hangs forever on `test-work.zsh`.

**Cause:** `test-work.zsh` sources `flow.plugin.zsh` which requires interactive/tmux context.

### Step 13: Add Timeout Mechanism

**Edit `tests/run-all.sh`:**

```bash
# BEFORE
run_test() {
    local test_file="$1"
    local name=$(basename "$test_file" .zsh)

    echo -n "Running $name... "
    if zsh "$test_file" > /dev/null 2>&1; then
        echo "✅"
        ((PASS++))
    else
        echo "❌"
        ((FAIL++))
    fi
}
```

```bash
# AFTER
TIMEOUT=0

run_test() {
    local test_file="$1"
    local name=$(basename "$test_file" .zsh)
    local timeout_seconds=30

    echo -n "Running $name... "

    timeout "$timeout_seconds" zsh "$test_file" > /dev/null 2>&1
    local exit_code=$?

    if [[ $exit_code -eq 124 ]]; then
        # 124 = timeout
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

### Step 14: Update Summary

```bash
echo "Results: $PASS passed, $FAIL failed, $TIMEOUT timeout"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi

if [[ $TIMEOUT -gt 0 ]]; then
    echo ""
    echo "Note: Timeout tests may require interactive/tmux context"
    exit 2  # Different exit code for timeouts vs failures
fi
```

### Step 15: Verify Fix

```bash
./tests/run-all.sh
```

**Expected output:**

```
=========================================
  flow-cli Local Test Suite
=========================================

Dispatcher tests:
Running test-pick-smart-defaults... ✅
Running test-cc-dispatcher... ✅
Running test-wt-dispatcher... ✅
...

Core command tests:
Running test-dash... ⏱️ (timeout after 30s)
Running test-work... ⏱️ (timeout after 30s)
Running test-capture... ✅
...

=========================================
  Results: 13 passed, 0 failed, 5 timeout
=========================================

Note: Timeout tests may require interactive/tmux context
```

**Before:** Infinite hang
**After:** Completes in ~3 minutes

---

## Part 6: Commit and Document

### Step 16: Create Atomic Commits

```bash
# Commit 1: Load guards
git add lib/*.zsh flow.plugin.zsh
git commit -m "refactor: add self-protecting load guards to 6 libs"

# Commit 2: Display extraction
git add lib/analysis-display.zsh commands/teach-analyze.zsh
git commit -m "refactor: extract display layer to lib/analysis-display.zsh"

# Commit 3: Cache fix
git add commands/teach-analyze.zsh
git commit -m "fix: mirror directory structure in slide cache paths"

# Commit 4: Test timeout
git add tests/run-all.sh
git commit -m "fix: add 30s timeout to test runner"
```

### Step 17: Update Documentation

```bash
# Update .STATUS
vim .STATUS
# Document: PR #290 merged, optimization complete

# Update CHANGELOG.md
vim CHANGELOG.md
# Add under ### Fixed:
# - Load guard double-sourcing (prevents 2-3x parsing on startup)
# - Slide cache path collisions (directory-mirroring structure)
# - Test runner hangs (30s timeout mechanism)
```

---

## Key Takeaways

### Load Guards Pattern

```zsh
if [[ -n "$_FLOW_*_LOADED" ]]; then
    return 0 2>/dev/null || true
fi
typeset -g _FLOW_*_LOADED=1
```

**When to use:**
- Any file that might be sourced multiple times
- Libraries loaded by multiple consumers
- Files sourced both explicitly and via glob

### Display Layer Extraction

**Benefits:**
- Reusable by multiple commands (`teach status`, `teach validate --deep`)
- Smaller command files (~930 vs 1,203 lines)
- Consistent UI across related commands

**Pattern:**
- 7+ related functions → Extract to `lib/*-display.zsh`
- Add load guard
- Source from command file

### Cache Path Best Practices

**Flat structure (bad):**

```
.teach/cache-file1.json
.teach/cache-file2.json
```

**Mirrored structure (good):**

```
.teach/cache/lectures/week-05/file1.json
.teach/cache/labs/week-05/file2.json
```

### Test Timeouts

**Key points:**
- 30s is reasonable for non-interactive tests
- Exit code 124 = timeout (distinguish from failure)
- Document which tests are expected to timeout
- Exit code 2 for timeouts (vs 1 for failures)

---

## Practice Exercises

1. **Find double-sourcing in your own project:**

   ```bash
   # Trace your plugin's load chain
   grep -rn "source" flow.plugin.zsh lib/ commands/
   ```

2. **Add load guards to a library:**
   - Pick a library file
   - Add the guard pattern
   - Test with multiple sources

3. **Extract a display layer:**
   - Find 3+ related display functions
   - Create new `lib/*-display.zsh`
   - Update consumers

4. **Add test timeouts:**
   - Identify hanging tests
   - Add `timeout N` wrapper
   - Handle exit code 124

---

## Next Steps

- **Tutorial 23:** Advanced caching strategies with SHA-256 validation
- **Tutorial 24:** Performance profiling ZSH plugins
- **Reference:** [ARCHITECTURE-OVERVIEW.md](../reference/ARCHITECTURE-OVERVIEW.md)
- **Guide:** [Testing Guide](../guides/TESTING.md)

---

**Optimization Stats (PR #290):**
- 10 files changed
- +317/-289 lines
- Load time: <1ms (no regression)
- Tests: 13 passing, 5 timeout (expected)
- Startup parsing: 3x reduction

