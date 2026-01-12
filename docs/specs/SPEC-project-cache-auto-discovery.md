# SPEC: Project Cache & Auto-Discovery System

**Feature:** v5.3.0 - Performance & Extensibility Improvements
**Created:** 2026-01-11
**Status:** Planning Complete - Ready for Implementation

---

## Executive Summary

Implement a **caching layer** and **auto-discovery system** for project detection to address:
1. **Performance**: Sub-10ms `pick` response (currently ~200ms with 100+ projects)
2. **Extensibility**: Auto-discover project categories (currently hardcoded)
3. **Maintainability**: Single source of truth for project type detection

**Key Innovation:** Hybrid approach with auto-discovery + user configuration + intelligent caching with 5-minute TTL.

---

## Problem Statement

### Current Issues

#### Issue 1: No Project List Caching (Critical - Performance)

**Code:** `commands/pick.zsh:208-251`

```zsh
_proj_list_all() {
    # Full filesystem scan EVERY TIME
    # 8 categories × 15 projects = 120 stat calls per pick invocation
}
```

**Impact:**
- 100+ stat calls per `pick` invocation
- ~200ms latency on typical setups
- Slow on network filesystems (NFS, Dropbox)
- No benefit from frequent usage

**Measurement:**
```bash
time pick >/dev/null
# Current: ~200ms (100 projects)
# Target: <10ms (cache hit)
```

#### Issue 2: Hardcoded Category List (Medium - Extensibility)

**Code:** `commands/pick.zsh:9-18`

```zsh
PROJ_CATEGORIES=(
    "r-packages/active:r:📦"
    "r-packages/stable:r:📦"
    "dev-tools:dev:🔧"
    # ... must manually update for new categories
)
```

**Impact:**
- Users cannot add custom project directories
- Per-user/per-machine configuration not possible
- Violates "discover, don't configure" principle

#### Issue 3: Duplicate Type Detection Logic (Low - Maintainability)

**Problem:** `project-detector.zsh` and `pick.zsh` both implement type→icon mapping independently.

**Impact:**
- New project types require updates in 2 files
- Inconsistent icons between `pick` and `work` commands
- DRY violation

---

## Solution Architecture

### Three-Phase Rollout

```
Phase 1: Caching Layer (v5.3.0)
   ↓
Phase 2: Auto-Discovery (v5.4.0)
   ↓
Phase 3: Integration (v5.5.0)
```

---

## Phase 1: Caching Layer (v5.3.0)

### Design

**Cache File Format:**
```
# Generated: 1736553600
flow-cli|dev|🔧|/Users/dt/projects/dev-tools/flow-cli|🟢 2h
aiterm|dev|🔧|/Users/dt/projects/dev-tools/aiterm|
scribe|app|📱|/Users/dt/projects/apps/scribe|🟡 old
...
```

**Cache Location:**
```bash
${XDG_CACHE_HOME:-$HOME/.cache}/flow-cli/projects.cache
```

**TTL:** 5 minutes (balances freshness vs performance)

### Implementation

**New File:** `lib/project-cache.zsh` (~100 lines)

```zsh
# Cache configuration
PROJ_CACHE_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/flow-cli/projects.cache"
PROJ_CACHE_TTL=300  # 5 minutes

# Generate cache from filesystem
_proj_cache_generate() {
    local cache_dir=$(dirname "$PROJ_CACHE_FILE")
    mkdir -p "$cache_dir"

    # Write cache with timestamp header
    {
        echo "# Generated: $(date +%s)"
        _proj_list_all_uncached  # Original function renamed
    } > "$PROJ_CACHE_FILE"
}

# Check if cache is valid (< TTL age)
_proj_cache_is_valid() {
    [[ -f "$PROJ_CACHE_FILE" ]] || return 1

    local cache_time=$(head -1 "$PROJ_CACHE_FILE" | sed 's/# Generated: //')
    local now=$(date +%s)
    local age=$((now - cache_time))

    [[ $age -lt $PROJ_CACHE_TTL ]]
}

# Get cached list (or regenerate if stale)
_proj_list_all() {
    if ! _proj_cache_is_valid; then
        _proj_cache_generate
    fi

    # Return cached data (skip timestamp line)
    tail -n +2 "$PROJ_CACHE_FILE"
}

# Invalidate cache (call after project creation/deletion)
_proj_cache_invalidate() {
    rm -f "$PROJ_CACHE_FILE"
}

# Cache statistics
_proj_cache_stats() {
    if [[ ! -f "$PROJ_CACHE_FILE" ]]; then
        echo "No cache file exists"
        return 1
    fi

    local cache_time=$(head -1 "$PROJ_CACHE_FILE" | sed 's/# Generated: //')
    local now=$(date +%s)
    local age=$((now - cache_time))
    local age_str=$(_format_duration $age)

    local count=$(tail -n +2 "$PROJ_CACHE_FILE" | wc -l)

    echo "Cache age: $age_str"
    echo "Projects cached: $count"
    echo "Status: $(_proj_cache_is_valid && echo "Valid" || echo "Stale")"
}

# Format duration in human-readable form
_format_duration() {
    local seconds=$1
    local mins=$((seconds / 60))
    local secs=$((seconds % 60))

    if [[ $mins -gt 0 ]]; then
        echo "${mins}m ${secs}s"
    else
        echo "${secs}s"
    fi
}
```

**Modified File:** `commands/pick.zsh`

```zsh
# Rename current _proj_list_all to _proj_list_all_uncached
_proj_list_all_uncached() {
    # ... existing implementation (lines 208-251)
}

# New cached version (imports from lib/project-cache.zsh)
# _proj_list_all() is now defined in project-cache.zsh
```

**Modified File:** `flow.plugin.zsh`

```zsh
# Add after other lib/ sources
source "$FLOW_PLUGIN_ROOT/lib/project-cache.zsh"
```

### User Commands

**New Commands:**

```bash
flow cache refresh   # Manual invalidation (regenerate now)
flow cache clear     # Delete cache file
flow cache status    # Show cache age and stats
```

**Implementation in `commands/flow.zsh`:**

```zsh
flow-cache() {
    case "$1" in
        refresh)
            echo "Refreshing project cache..."
            _proj_cache_invalidate
            _proj_cache_generate
            echo "✅ Cache refreshed"
            _proj_cache_stats
            ;;
        clear)
            rm -f "$PROJ_CACHE_FILE"
            echo "✅ Cache cleared"
            ;;
        status)
            _proj_cache_stats
            ;;
        *)
            echo "Usage: flow cache {refresh|clear|status}"
            return 1
            ;;
    esac
}
```

### Rollout Strategy

**v5.3.0 Alpha:**
- Cache **enabled by default**
- Monitor for issues via GitHub discussions
- Feature flag: `FLOW_CACHE_ENABLED` (default: 1)

**Disable if needed:**
```zsh
export FLOW_CACHE_ENABLED=0  # Skip cache, use direct scan
```

**Expected Issues:**
- Stale cache after git clone in another terminal
- Solution: `flow cache refresh` (or wait 5 min)

**Acceptance Criteria:**
- [ ] `pick` responds in <10ms (cache hit)
- [ ] Cache auto-refreshes every 5 minutes
- [ ] `flow cache` commands work
- [ ] No regressions in project discovery

---

## Phase 2: Auto-Discovery (v5.4.0)

### Design

**Auto-discovery Algorithm:**

1. Scan `$FLOW_PROJECTS_ROOT` (default: `~/projects`)
2. For each top-level directory:
   - Check if contains git repos (1-2 levels deep)
   - Guess category type from directory name
   - Assign appropriate icon
3. Merge with user config overrides
4. Fall back to hardcoded list if discovery fails

**User Configuration File:**

```bash
# ~/.config/flow-cli/project-categories.conf
# Format: path:type:icon
#
# Override auto-discovered categories or add custom ones

# Custom work category
work/clients:work:💼
work/internal:work:🏢

# Override default icon for dev-tools
dev-tools:dev:⚙️
```

### Implementation

**New File:** `lib/project-auto-discover.zsh` (~150 lines)

```zsh
# Auto-discover project categories from filesystem
_proj_discover_categories() {
    local projects_root="${FLOW_PROJECTS_ROOT:-$HOME/projects}"
    local -a discovered=()

    # Scan one level deep for directories with git repos
    setopt local_options nullglob
    for category_dir in "$projects_root"/*/; do
        [[ -d "$category_dir" ]] || continue
        local category_name=$(basename "$category_dir")

        # Skip hidden directories
        [[ "$category_name" == .* ]] && continue

        # Check if category has any git repos (2 levels deep)
        local has_repos=0
        for proj_dir in "$category_dir"/*/ "$category_dir"/*/*/; do
            if [[ -d "$proj_dir/.git" ]]; then
                has_repos=1
                break
            fi
        done

        [[ $has_repos -eq 0 ]] && continue

        # Determine category metadata
        local cat_type=$(_guess_category_type "$category_name")
        local cat_icon=$(_guess_category_icon "$cat_type")

        # For subdirectories (like r-packages/active), handle both levels
        for subcat_dir in "$category_dir"/*/; do
            if [[ -d "$subcat_dir" ]]; then
                local has_git_here=0
                for proj in "$subcat_dir"/*/; do
                    if [[ -d "$proj/.git" ]]; then
                        has_git_here=1
                        break
                    fi
                done

                if [[ $has_git_here -eq 1 ]]; then
                    local rel_path="${category_name}/$(basename "$subcat_dir")"
                    discovered+=("$rel_path:$cat_type:$cat_icon")
                fi
            fi
        done

        # Also include top-level category if it has direct repos
        for proj in "$category_dir"/*/; do
            if [[ -d "$proj/.git" ]]; then
                discovered+=("$category_name:$cat_type:$cat_icon")
                break
            fi
        done
    done

    printf '%s\n' "${discovered[@]}"
}

# Guess category type from directory name
_guess_category_type() {
    local name="$1"
    case "$name" in
        *r-package*|*rpkg*) echo "r" ;;
        *dev*|*tool*) echo "dev" ;;
        *quarto*|*qmd*) echo "q" ;;
        *teach*) echo "teach" ;;
        *research*|*rs*) echo "rs" ;;
        *app*) echo "app" ;;
        *work*) echo "work" ;;  # NEW: work category
        *) echo "misc" ;;  # NEW: generic fallback
    esac
}

# Guess icon from category type
_guess_category_icon() {
    case "$1" in
        r) echo "📦" ;;
        dev) echo "🔧" ;;
        q) echo "📝" ;;
        teach) echo "🎓" ;;
        rs) echo "🔬" ;;
        app) echo "📱" ;;
        work) echo "💼" ;;  # NEW
        misc) echo "📁" ;;  # NEW
    esac
}

# Initialize categories (run at shell startup)
_proj_init_categories() {
    # Priority 1: User config file
    local config_file="${XDG_CONFIG_HOME:-$HOME/.config}/flow-cli/project-categories.conf"
    local -a user_categories=()

    if [[ -f "$config_file" ]]; then
        while IFS=: read -r path type icon; do
            # Skip comments and empty lines
            [[ "$path" == \#* || -z "$path" ]] && continue
            user_categories+=("$path:$type:$icon")
        done < "$config_file"
    fi

    # Priority 2: Auto-discovered categories
    local -a discovered=("${(@f)$(_proj_discover_categories)}")

    # Priority 3: Hardcoded defaults (backward compatibility)
    local -a defaults=(
        "r-packages/active:r:📦"
        "r-packages/stable:r:📦"
        "dev-tools:dev:🔧"
        "teaching:teach:🎓"
        "research:rs:🔬"
        "quarto/manuscripts:q:📝"
        "quarto/presentations:q:📊"
        "apps:app:📱"
    )

    # Merge: user > discovered > defaults (remove duplicates)
    local -A seen_paths
    PROJ_CATEGORIES=()

    for cat in "${user_categories[@]}" "${discovered[@]}" "${defaults[@]}"; do
        local path="${cat%%:*}"
        # Add if not seen before
        if [[ -z "${seen_paths[$path]}" ]]; then
            seen_paths[$path]=1
            PROJ_CATEGORIES+=("$cat")
        fi
    done
}
```

**Modified File:** `commands/pick.zsh`

```zsh
# Remove hardcoded PROJ_CATEGORIES array (lines 9-18)
# Now initialized by _proj_init_categories() in auto-discover.zsh
```

**Modified File:** `flow.plugin.zsh`

```zsh
# Add after other lib/ sources
source "$FLOW_PLUGIN_ROOT/lib/project-auto-discover.zsh"

# Initialize categories at startup
_proj_init_categories
```

### User Commands

**New Command:**

```bash
flow discover        # Show discovered categories
flow discover refresh # Re-scan filesystem
```

**Implementation:**

```zsh
flow-discover() {
    case "$1" in
        refresh)
            echo "Re-scanning project directories..."
            _proj_init_categories
            _proj_cache_invalidate  # Also invalidate cache
            echo "✅ Categories refreshed"
            ;;
        ""|list)
            echo "Discovered categories:"
            for cat in "${PROJ_CATEGORIES[@]}"; do
                local path="${cat%%:*}"
                local rest="${cat#*:}"
                local type="${rest%%:*}"
                local icon="${rest##*:}"
                printf "  %s %-30s %s\n" "$icon" "$path" "$type"
            done
            ;;
        *)
            echo "Usage: flow discover [refresh|list]"
            ;;
    esac
}
```

### Rollout Strategy

**v5.4.0 Beta:**
- Auto-discovery **opt-in** initially
- Feature flag: `FLOW_AUTO_DISCOVER=1`
- Monitor user feedback

**v5.4.1 Stable:**
- Auto-discovery **enabled by default**
- Hardcoded categories remain as fallback

**Acceptance Criteria:**
- [ ] Auto-discovers standard layout (~/projects/dev-tools, ~/projects/r-packages, etc.)
- [ ] User config file overrides work
- [ ] Backward compatible with existing setups
- [ ] No performance regression (discovery runs once at shell startup)

---

## Phase 3: Integration (v5.5.0)

### Goal

Unify type detection across all commands using `project-detector.zsh` as single source of truth.

### Changes

**Modified:** `commands/pick.zsh`

```zsh
# OLD: Hardcoded icon mapping
case "$type" in
    r) icon="📦" ;;
    dev) icon="🔧" ;;
    # ...
esac

# NEW: Use project-detector.zsh
local detected_type=$(_flow_detect_project_type "$proj_dir")
local proj_icon=$(_flow_project_icon "$detected_type")

# Override category type/icon with detected values if more specific
local final_type="${detected_type:-$cat_type}"
local final_icon="${proj_icon:-$cat_icon}"
```

**Benefits:**
- Quarto project in dev-tools → shows 📝 (not 🔧)
- Teaching project in research → shows 🎓 (not 🔬)
- Automatic detection based on actual content

**Modified:** `lib/project-detector.zsh`

Add new project types:

```zsh
PROJECT_TYPE_INDICATORS=(
    # ... existing types
    [generic]=""  # Fallback (no special files)
    [worktree]=".git"  # Git worktree
)

# Add icons for new types
_flow_project_icon() {
    case "$1" in
        # ... existing icons
        generic) echo "📁" ;;
        worktree) echo "🌳" ;;
    esac
}
```

---

## Implementation Order

### Week 1: Caching Layer (v5.3.0)

**Day 1** (2 hours):
- Create `lib/project-cache.zsh`
- Implement cache generation, validation, stats
- Add `flow cache` commands

**Day 2** (2 hours):
- Modify `commands/pick.zsh` to use cache
- Add feature flag `FLOW_CACHE_ENABLED`
- Unit tests for cache functions

**Day 3** (1 hour):
- Integration testing
- Documentation update
- Release v5.3.0-alpha

### Week 2: Auto-Discovery (v5.4.0)

**Day 1** (3 hours):
- Create `lib/project-auto-discover.zsh`
- Implement discovery algorithm
- Add `flow discover` command

**Day 2** (2 hours):
- Modify `commands/pick.zsh` to use discovered categories
- Create user config file template
- Add feature flag `FLOW_AUTO_DISCOVER`

**Day 3** (1 hour):
- Integration testing
- Documentation (user config guide)
- Release v5.4.0-beta

### Week 3: Integration (v5.5.0)

**Day 1** (2 hours):
- Integrate project-detector.zsh into pick
- Verify type detection consistency
- Add new project types (generic, worktree)

**Day 2** (1 hour):
- Testing across all commands (pick, work, dash)
- Performance benchmarking

**Day 3** (1 hour):
- Documentation finalization
- Release v5.5.0-stable

**Total Effort:** ~14 hours over 3 weeks

---

## Testing Strategy

### Unit Tests

**New Test Suite:** `tests/test-project-cache.zsh`

```zsh
# Test 1: Cache generation
test_cache_generation() {
    _proj_cache_invalidate
    _proj_cache_generate

    assert_file_exists "$PROJ_CACHE_FILE"
    assert_contains "$(head -1 "$PROJ_CACHE_FILE")" "# Generated:"
}

# Test 2: Cache validity
test_cache_validity() {
    _proj_cache_generate
    assert_true _proj_cache_is_valid

    # Artificially age cache
    local old_time=$(($(date +%s) - 400))  # 6 min 40 sec ago
    sed -i.bak "1s/.*/# Generated: $old_time/" "$PROJ_CACHE_FILE"

    assert_false _proj_cache_is_valid
}

# Test 3: Cache stats
test_cache_stats() {
    _proj_cache_generate
    local output=$(_proj_cache_stats)

    assert_contains "$output" "Cache age:"
    assert_contains "$output" "Projects cached:"
}
```

**New Test Suite:** `tests/test-auto-discover.zsh`

```zsh
# Test 1: Discovery finds standard layout
test_discovery_standard_layout() {
    local discovered=$(_proj_discover_categories)

    assert_contains "$discovered" "dev-tools:dev:🔧"
    assert_contains "$discovered" "r-packages/active:r:📦"
}

# Test 2: User config overrides
test_user_config_overrides() {
    local config_file="${XDG_CONFIG_HOME:-$HOME/.config}/flow-cli/project-categories.conf"
    mkdir -p "$(dirname "$config_file")"
    echo "dev-tools:dev:⚙️" > "$config_file"

    _proj_init_categories

    # Should use ⚙️ not 🔧
    local match=$(printf '%s\n' "${PROJ_CATEGORIES[@]}" | grep "dev-tools")
    assert_contains "$match" "⚙️"
}

# Test 3: Fallback to hardcoded
test_fallback_to_hardcoded() {
    # Simulate empty projects directory
    FLOW_PROJECTS_ROOT="/tmp/empty-projects-$$"
    mkdir -p "$FLOW_PROJECTS_ROOT"

    _proj_init_categories

    # Should still have categories (from hardcoded)
    assert_true "[[ ${#PROJ_CATEGORIES[@]} -gt 0 ]]"

    rm -rf "$FLOW_PROJECTS_ROOT"
}
```

### Integration Tests

**E2E Workflow:**

```bash
# 1. Clear cache
flow cache clear

# 2. First pick - should generate cache
time pick >/dev/null
# Expected: ~200ms (initial scan)

# 3. Second pick - should use cache
time pick >/dev/null
# Expected: <10ms (cache hit)

# 4. Wait 6 minutes
sleep 360

# 5. Third pick - should regenerate cache
time pick >/dev/null
# Expected: ~200ms (stale cache, regenerate)

# 6. Add new project
mkdir ~/projects/dev-tools/new-tool
git init ~/projects/dev-tools/new-tool

# 7. Refresh cache manually
flow cache refresh

# 8. Verify new project appears
pick dev | grep new-tool
# Expected: new-tool appears in picker
```

### Performance Benchmarks

**Measurement Script:** `tests/benchmark-pick.sh`

```bash
#!/usr/bin/env bash
# Benchmark pick performance with/without cache

echo "Benchmarking pick command..."

# Disable cache
export FLOW_CACHE_ENABLED=0

echo "Without cache (10 runs):"
for i in {1..10}; do
    /usr/bin/time -p pick >/dev/null 2>&1
done | grep real | awk '{sum+=$2; count++} END {print "Average:", sum/count, "seconds"}'

# Enable cache
export FLOW_CACHE_ENABLED=1
rm -f "${XDG_CACHE_HOME:-$HOME/.cache}/flow-cli/projects.cache"

echo "With cache - first run (cold):"
/usr/bin/time -p pick >/dev/null 2>&1 | grep real

echo "With cache - subsequent runs (hot, 10 runs):"
for i in {1..10}; do
    /usr/bin/time -p pick >/dev/null 2>&1
done | grep real | awk '{sum+=$2; count++} END {print "Average:", sum/count, "seconds"}'
```

**Expected Results:**
```
Without cache: ~0.20s average
With cache (cold): ~0.20s (initial generation)
With cache (hot): ~0.005s average (40x faster)
```

---

## Success Metrics

### Performance (v5.3.0)

- ✅ `pick` responds in <10ms (cache hit)
- ✅ Cache auto-refreshes every 5 minutes
- ✅ `flow cache` commands functional
- ✅ No regression in project discovery

### Extensibility (v5.4.0)

- ✅ Auto-discovers standard project layout
- ✅ User config file overrides work
- ✅ New categories appear without code changes
- ✅ Backward compatible with existing setups

### Maintainability (v5.5.0)

- ✅ Single source of truth for project types
- ✅ Consistent icons across commands
- ✅ New project types auto-supported everywhere

---

## Rollout Timeline

| Version | Date | Feature | Status |
|---------|------|---------|--------|
| v5.3.0-alpha | Week 1 | Caching (enabled) | Planning |
| v5.3.0-stable | Week 2 | Caching stable | Planning |
| v5.4.0-beta | Week 3 | Auto-discovery (opt-in) | Planning |
| v5.4.1-stable | Week 4 | Auto-discovery (default) | Planning |
| v5.5.0-stable | Week 5 | Unified type detection | Planning |

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Cache staleness after external git operations | Medium | Low | 5-min TTL + manual refresh command |
| Discovery misdetects project types | Low | Low | User config overrides + fallback |
| Performance regression on slow disks | Low | Medium | Keep opt-out flag permanently |
| Breaking changes for existing workflows | Very Low | High | Extensive testing + backward compat |

---

## Open Questions

1. **Cache location:** Use `XDG_CACHE_HOME` (standard) or `~/.config/flow-cli/` (keep all flow files together)?
   - **Decision:** XDG_CACHE_HOME (follows standards, separates transient data)

2. **TTL value:** 5 minutes vs 10 minutes vs 15 minutes?
   - **Decision:** 5 minutes (good balance, users can override: `PROJ_CACHE_TTL=600`)

3. **Auto-discovery depth:** 1 level vs 2 levels vs unlimited?
   - **Decision:** 2 levels max (handles current structure, prevents slow recursive scans)

4. **Feature flags permanent or temporary?**
   - **Decision:** Permanent for cache (users may want to disable on network drives), temporary for auto-discover (remove in v6.0)

---

## Documentation Updates

### Files to Update

1. **README.md** - Add caching/auto-discovery to features list
2. **docs/getting-started/configuration.md** - Document `FLOW_CACHE_ENABLED`, `FLOW_AUTO_DISCOVER`, `project-categories.conf`
3. **docs/reference/COMMAND-QUICK-REFERENCE.md** - Add `flow cache`, `flow discover` commands
4. **docs/guides/PERFORMANCE-TUNING.md** (NEW) - Caching guide, benchmark results
5. **CLAUDE.md** - Update architecture section with caching layer

### New Documentation

**File:** `docs/guides/PROJECT-CONFIGURATION.md`

Topics:
- Auto-discovery explained
- Creating custom categories
- Config file format
- Examples (work projects, client projects, experiments)

---

## Future Enhancements (Post-v5.5.0)

### Smart Cache Invalidation (v5.6.0)

Use filesystem watchers for instant invalidation:

```zsh
# Requires: fswatch (brew install fswatch)
_proj_watch_filesystem() {
    if command -v fswatch &>/dev/null; then
        fswatch -o -1 "$FLOW_PROJECTS_ROOT" 2>/dev/null | while read change; do
            _proj_cache_invalidate
        done &
    fi
}
```

### Parallel Category Scanning (v5.7.0)

Speed up initial scan with ZSH background jobs:

```zsh
_proj_cache_generate_parallel() {
    local tmpfiles=()

    for cat_info in "${PROJ_CATEGORIES[@]}"; do
        local tmpfile=$(mktemp)
        tmpfiles+=("$tmpfile")
        {
            _proj_scan_category "$cat_info"
        } > "$tmpfile" &
    done

    wait  # Wait for all jobs
    cat "${tmpfiles[@]}" > "$PROJ_CACHE_FILE"
    rm -f "${tmpfiles[@]}"
}
```

### Remote Cache Sync (v6.0.0)

Sync cache across machines via cloud storage:

```zsh
# Sync cache to Dropbox/iCloud
flow cache sync --to ~/Dropbox/.flow-cli-cache
flow cache sync --from ~/Dropbox/.flow-cli-cache
```

---

## Files Changed Summary

### New Files (3)

- `lib/project-cache.zsh` (100 lines)
- `lib/project-auto-discover.zsh` (150 lines)
- `docs/guides/PROJECT-CONFIGURATION.md` (200 lines)

### Modified Files (4)

- `commands/pick.zsh` - Use cache, use discovered categories
- `commands/flow.zsh` - Add `flow cache`, `flow discover` commands
- `flow.plugin.zsh` - Source new libs, init categories
- `lib/project-detector.zsh` - Add new types (generic, worktree)

### Test Files (3)

- `tests/test-project-cache.zsh` (NEW)
- `tests/test-auto-discover.zsh` (NEW)
- `tests/benchmark-pick.sh` (NEW)

**Total New Code:** ~450 lines
**Total Modified Code:** ~100 lines
**Total Test Code:** ~200 lines

---

## Approval Checklist

- [ ] Architecture reviewed
- [ ] Performance benchmarks acceptable
- [ ] Rollout strategy approved
- [ ] Testing plan complete
- [ ] Documentation plan complete
- [ ] Feature flags defined
- [ ] Risk mitigation acceptable

---

**Status:** ✅ Ready for Implementation
**Next Step:** Create feature branch `feature/project-cache-auto-discovery` from dev
