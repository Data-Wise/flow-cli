# Cache Quick Reference

**Quick lookup for project cache commands and configuration**

---

## Commands

| Command | Action |
|---------|--------|
| `flow cache status` | Show cache age and statistics |
| `flow cache refresh` | Force cache regeneration now |
| `flow cache clear` | Delete cache file |
| `flow cache help` | Show help and examples |

---

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `FLOW_CACHE_ENABLED` | `1` | Enable (1) or disable (0) cache |
| `PROJ_CACHE_TTL` | `300` | Cache lifetime in seconds (5 min) |
| `XDG_CACHE_HOME` | `~/.cache` | Base cache directory |

---

## Quick Actions

```bash
# After adding new projects
flow cache refresh

# Check if cache is working
flow cache status

# Disable cache temporarily
FLOW_CACHE_ENABLED=0 pick

# Use longer TTL (10 minutes)
PROJ_CACHE_TTL=600 pick
```

---

## Performance

| Metric | Value |
|--------|-------|
| **Cache hit** | < 10ms |
| **Cache miss** | ~200ms |
| **Speedup** | **40x faster** |
| **TTL** | 5 minutes (configurable) |

---

## Cache Location

```
~/.cache/flow-cli/projects.cache
```

---

## Status Indicators

- 🟢 **Valid** - Cache fresh (< TTL)
- 🟡 **Stale** - Cache expired (will regenerate)
- ❌ **Missing** - No cache file

---

## Common Issues

| Problem | Solution |
|---------|----------|
| Cache not working | `flow cache refresh` |
| New projects missing | `flow cache refresh` |
| Slow on network drive | Increase `PROJ_CACHE_TTL` |
| Cache file corrupt | `flow cache clear && flow cache refresh` |

---

**See also:** [PROJECT-CACHE.md](../guides/PROJECT-CACHE.md) for full documentation
