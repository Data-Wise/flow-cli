# Feature Request: Sass Cache Clearing for `qu` Dispatcher

**Date:** 2026-01-27
**Author:** Davood Tofighi, Ph.D.
**Priority:** Medium
**Effort:** Small (~1-2 hours)

---

## Executive Summary

Add a `--clear-cache` (or `--cc`) option to the `qu` dispatcher that clears Quarto's sass cache before rendering, resolving a common issue where stale cache entries cause render failures.

**Current behavior:**

```bash
qu render   # Fails with: "NotFound: No such file or directory (os error 2)"
# User must manually run: rm -rf ~/Library/Caches/quarto/sass/
```

**Proposed behavior:**

```bash
qu render --clear-cache   # Clears sass cache first, then renders
qu --cc                   # Short form, clears cache then runs default workflow
qu clear-cache            # Standalone command to just clear cache
```

---

## Problem Statement

### The Sass Cache Issue

Quarto caches compiled SCSS/Sass files at `~/Library/Caches/quarto/sass/` on macOS. When cache entries become stale or corrupted, Quarto fails with cryptic errors:

```
ERROR: NotFound: No such file or directory (os error 2): lstat
'/Users/dt/Library/Caches/quarto/sass/0920dd6d7437995b8cdf7429764427b1.css'
```

### When This Happens

1. **Quarto version upgrades** - Different versions may use incompatible cache formats
2. **Extension updates** - Custom themes (e.g., UNM RevealJS) may change cached styles
3. **Concurrent renders** - Multiple `quarto preview` or `quarto render` processes
4. **Interrupted renders** - Ctrl+C during SCSS compilation
5. **IDE integration** - Positron/RStudio bundled Quarto vs system Quarto conflicts

### Real-World Impact

**STAT 545 case study (2026-01-27):**

- Encountered during slide deployment
- `quarto render` failed in pre-push hook
- Required manual cache clearing
- Issue recurs "often" per instructor feedback
- Lost 5-10 minutes per occurrence troubleshooting

---

## Proposed Solution

### New Commands and Flags

```bash
# Clear cache before any render operation
qu render --clear-cache
qu --cc                    # Short form for default workflow

# Standalone cache clearing
qu clear-cache            # Just clear cache, no render
qu cc                     # Alias
```

### Implementation Sketch

```zsh
# Cache locations by platform
_qu_get_cache_dir() {
    case "$(uname -s)" in
        Darwin)  echo "${HOME}/Library/Caches/quarto/sass" ;;
        Linux)   echo "${XDG_CACHE_HOME:-$HOME/.cache}/quarto/sass" ;;
        *)       echo "${HOME}/.cache/quarto/sass" ;;
    esac
}

_qu_clear_cache() {
    local cache_dir="$(_qu_get_cache_dir)"
    if [[ -d "$cache_dir" ]]; then
        local size=$(du -sh "$cache_dir" 2>/dev/null | cut -f1)
        rm -rf "$cache_dir" && echo "🧹 Cleared sass cache ($size)"
    else
        echo "📦 No sass cache to clear"
    fi
}
```

---

## Benefits

- ✅ **Instant fix** for common render failures
- ✅ **No manual intervention** - integrated into workflow
- ✅ **Time savings** - 5-10 minutes per occurrence avoided
- ✅ **Minimal implementation** - ~30 lines of code
- ✅ **Cross-platform** - works on macOS, Linux, Windows

---

## Help Output Update

Add to `_qu_help()`:

```
🧹 CACHE MANAGEMENT:
  qu clear-cache     Clear Quarto sass cache
  qu cc              Alias for clear-cache
  qu --cc            Clear cache before any command
  qu render --cc     Clear cache then render
```

---

## Related

- STAT 545 deployment issue: 2026-01-27
- Quarto sass cache location: `~/Library/Caches/quarto/sass/`

**Recommendation:** Implement in next flow-cli release.
