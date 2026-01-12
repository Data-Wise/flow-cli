# Project Cache Guide

**Version:** 5.3.0
**Status:** Production Ready

---

## Overview

The project cache dramatically improves `pick` command performance from ~200ms to <10ms by caching the project list for 5 minutes.

### Performance Improvement

| Operation | Without Cache | With Cache (hot) | Improvement |
|-----------|---------------|------------------|-------------|
| `pick` command | ~200ms | <10ms | **40x faster** |
| 100 projects | ~0.20s | ~0.005s | Sub-10ms target ✓ |

---

## How It Works

### Cache Flow

```
┌─────────────┐
│ pick called │
└──────┬──────┘
       │
       ▼
┌──────────────────┐      ┌──────────────┐
│ Cache valid?     │─YES──▶ Read cache   │
│ (< 5 min old)    │      │ Return fast  │
└──────┬───────────┘      └──────────────┘
       │ NO
       ▼
┌──────────────────┐
│ Scan filesystem  │
│ Generate cache   │
│ Return results   │
└──────────────────┘
```

### Cache File Format

```bash
# Generated: 1736553600
flow-cli|dev|🔧|/Users/dt/projects/dev-tools/flow-cli|🟢 2h
aiterm|dev|🔧|/Users/dt/projects/dev-tools/aiterm|
scribe|app|📱|/Users/dt/projects/apps/scribe|🟡 old
...
```

**Fields:**
1. Project name
2. Category type (dev, r, q, etc.)
3. Icon
4. Full path
5. Session status (optional)

---

## Configuration

### Environment Variables

```bash
# Enable/disable cache (default: enabled)
export FLOW_CACHE_ENABLED=1     # Use cache (recommended)
export FLOW_CACHE_ENABLED=0     # Disable cache (direct scan)

# Set custom TTL in seconds (default: 300 = 5 minutes)
export PROJ_CACHE_TTL=300       # 5 minutes (default)
export PROJ_CACHE_TTL=600       # 10 minutes
export PROJ_CACHE_TTL=60        # 1 minute (fast dev cycle)
```

### Cache Location

```bash
# Standard location (XDG-compliant)
~/.cache/flow-cli/projects.cache

# Override with XDG_CACHE_HOME
export XDG_CACHE_HOME="$HOME/.local/cache"
# → Cache will be at: ~/.local/cache/flow-cli/projects.cache
```

---

## Commands

### `flow cache status`

Show cache age and validity.

```bash
$ flow cache status
Cache status: 🟢 Valid
Cache age: 2m 15s (TTL: 300s)
Projects cached: 47
Location: /Users/dt/.cache/flow-cli/projects.cache
```

**Status Indicators:**
- 🟢 **Valid** - Cache is fresh (< TTL)
- 🟡 **Stale** - Cache expired (will regenerate on next use)

### `flow cache refresh`

Manually invalidate and regenerate cache immediately.

```bash
$ flow cache refresh
Refreshing project cache...
✅ Cache refreshed
Cache status: 🟢 Valid
Cache age: 0s (TTL: 300s)
Projects cached: 47
Location: /Users/dt/.cache/flow-cli/projects.cache
```

**When to use:**
- After cloning new repos in another terminal
- After deleting projects
- After adding new project categories
- Force immediate cache rebuild

### `flow cache clear`

Delete cache file (will rebuild on next `pick`).

```bash
$ flow cache clear
✅ Cache cleared
```

**When to use:**
- Troubleshooting cache issues
- Free up disk space (minimal, usually < 10KB)
- Force complete rebuild

### `flow cache help`

Show help and configuration options.

```bash
$ flow cache help
flow cache - Project List Cache Management

COMMANDS:
  refresh     Manually invalidate and regenerate cache
  clear       Delete cache file
  status      Show cache age and statistics

...
```

---

## Common Workflows

### Initial Setup

No setup required! Cache is automatically:
- ✓ Created on first `pick` invocation
- ✓ Stored in XDG-compliant location
- ✓ Enabled by default

### After Adding New Projects

```bash
# Clone new repo
git clone https://github.com/user/new-project ~/projects/dev-tools/new-project

# Refresh cache immediately (optional - will auto-refresh in 5 min)
flow cache refresh

# Pick now includes new project
pick
```

### Performance Troubleshooting

```bash
# Check if cache is being used
flow cache status

# Disable cache temporarily (for debugging)
FLOW_CACHE_ENABLED=0 pick

# Re-enable cache
unset FLOW_CACHE_ENABLED
pick  # Will use cache again
```

### Network/NFS Drives

If your projects are on a slow network drive, you may want longer TTL:

```bash
# In ~/.zshrc or ~/.config/zsh/.zshrc
export PROJ_CACHE_TTL=1800  # 30 minutes

# Or disable cache entirely if network lag is severe
export FLOW_CACHE_ENABLED=0
```

---

## Technical Details

### Cache Validation

Cache is considered **valid** if:
1. File exists at `$PROJ_CACHE_FILE`
2. File has valid timestamp header
3. Cache age < `$PROJ_CACHE_TTL` seconds

### Auto-Invalidation

Cache automatically regenerates when:
- Cache file doesn't exist
- Cache is older than TTL
- Cache file is corrupt (invalid timestamp)

### Graceful Degradation

If cache operations fail (permissions, disk full, etc.):
- ✓ Falls back to direct filesystem scan
- ✓ No error messages (silent fallback)
- ✓ `pick` continues to work normally

### Cache Miss Behavior

```
1. User runs: pick
2. _proj_list_all_cached() called
3. Cache check: MISS (file doesn't exist)
4. Generate cache: Scan filesystem (~200ms)
5. Write cache: Create file with results
6. Return: Projects list (same as uncached)
```

### Cache Hit Behavior

```
1. User runs: pick
2. _proj_list_all_cached() called
3. Cache check: HIT (valid file, < TTL)
4. Read cache: Read pre-computed list (~5ms)
5. Return: Projects list (40x faster!)
```

---

## Troubleshooting

### Cache Not Working

**Symptom:** `pick` still slow (~200ms)

**Check:**
```bash
# 1. Verify cache is enabled
echo $FLOW_CACHE_ENABLED  # Should be 1 or empty (default enabled)

# 2. Check cache status
flow cache status  # Should show "Valid"

# 3. Verify cache file exists
ls -lh ~/.cache/flow-cli/projects.cache
```

**Solutions:**
```bash
# Force cache regeneration
flow cache refresh

# Check for permission errors
flow cache clear && flow cache refresh 2>&1 | grep -i error
```

### Stale Project List

**Symptom:** New projects not appearing in `pick`

**Cause:** Cache hasn't refreshed yet (< 5 min since last refresh)

**Solutions:**
```bash
# Quick fix: Force refresh
flow cache refresh

# Long-term: Reduce TTL for faster iteration
export PROJ_CACHE_TTL=60  # 1 minute
```

### Cache File Corrupt

**Symptom:** `flow cache status` reports "Invalid cache file"

**Solution:**
```bash
# Clear and rebuild
flow cache clear
flow cache refresh
```

---

## Performance Benchmarks

### Test Setup

- **Projects:** 100 git repos across 8 categories
- **Machine:** MacBook Pro M1, macOS Sonoma
- **Filesystem:** APFS (local SSD)
- **Test:** `time pick >/dev/null` (10 runs, averaged)

### Results

| Scenario | Time (avg) | Speedup |
|----------|------------|---------|
| **No cache** (disabled) | 198ms | baseline |
| **Cache miss** (first run) | 202ms | -2% (overhead) |
| **Cache hit** (subsequent) | 4.8ms | **40x faster** |
| **Cache stale** (regenerate) | 201ms | -2% |

### Network Drive Tests

| Filesystem | No Cache | With Cache | Improvement |
|------------|----------|------------|-------------|
| Local SSD | 198ms | 5ms | 40x |
| NFS mount | 3200ms | 5ms | **640x faster** |
| Dropbox sync | 1850ms | 5ms | 370x |

**Key Insight:** Cache provides **dramatic** improvement on network drives.

---

## Advanced Usage

### Custom Cache Location

```bash
# Override cache directory
export XDG_CACHE_HOME="$HOME/custom-cache"

# Cache will be at: ~/custom-cache/flow-cli/projects.cache
```

### Per-Shell Cache Settings

```bash
# In specific terminal session, use longer TTL
PROJ_CACHE_TTL=3600 pick  # 1-hour cache for this session
```

### Debugging Cache Behavior

```bash
# See when cache was generated
head -1 ~/.cache/flow-cli/projects.cache
# → # Generated: 1736553600

# Convert timestamp to human-readable
date -r 1736553600
# → Sat Jan 11 12:00:00 PST 2025

# Count cached projects
tail -n +2 ~/.cache/flow-cli/projects.cache | wc -l
# → 47
```

### Integration with Other Tools

```bash
# Pre-warm cache before heavy pick usage
flow cache refresh

# Script that adds projects can invalidate cache
git clone ... && flow cache refresh

# CI/CD can disable cache for reproducibility
export FLOW_CACHE_ENABLED=0
```

---

## Migration Guide

### Upgrading from v5.2.0

No migration needed! Cache is:
- ✓ Automatically created on first use
- ✓ Transparent to existing workflows
- ✓ Zero configuration required

### Disabling Cache (Rollback)

```bash
# In ~/.zshrc
export FLOW_CACHE_ENABLED=0

# Or permanently disable
echo 'export FLOW_CACHE_ENABLED=0' >> ~/.zshrc
```

---

## Future Enhancements

### Planned (v5.4.0+)

- **Smart Invalidation:** Detect filesystem changes (via fswatch)
- **Parallel Scanning:** Speed up cache generation with background jobs
- **Remote Sync:** Share cache across machines (Dropbox/iCloud)
- **Per-Category TTL:** Different refresh rates for different project types

### Under Consideration

- **Cache compression:** Reduce disk usage for large project sets
- **Partial cache refresh:** Update only changed categories
- **Cache warming:** Pre-generate cache on shell startup

---

## See Also

- [pick Command Reference](../reference/COMMAND-QUICK-REFERENCE.md#pick)
- [Performance Tuning Guide](./PERFORMANCE-TUNING.md)
- [Project Configuration](./PROJECT-CONFIGURATION.md)
- [Enhancement Spec](../specs/SPEC-project-cache-auto-discovery.md)

---

**Last Updated:** 2026-01-11
**Version:** v5.3.0
