# Token Automation - Quick Reference

**Version:** v5.17.0 (Phase 1)
**Last Updated:** 2026-01-23

---

## Quick Commands

```bash
# Check token status (fast, < 3s)
doctor --dot

# Check specific provider
doctor --dot=github

# Fix token issues
doctor --fix-token

# Quiet mode (automation)
doctor --dot --quiet

# Verbose debug
doctor --dot --verbose

# Combine flags
doctor --dot --fix-token --verbose
```

---

## Common Workflows

### Morning Health Check

```bash
doctor --dot              # Quick token validation
# ✓ Token valid (45 days remaining)
```

### Pre-Push Validation

```bash
doctor --dot --quiet      # Silent check
echo $?                   # 0 = OK, 1 = issues
```

### Token Rotation

```bash
doctor --fix-token        # Interactive menu
# Select: 1. GitHub Token
# Auto-rotates + clears cache
```

### CI/CD Integration

```bash
#!/bin/bash
if ! doctor --dot --quiet; then
    echo "Token issues detected"
    exit 1
fi
```

---

## Flags Reference

| Flag | Effect | Use When |
|------|--------|----------|
| `--dot` | Check only tokens | Quick health check |
| `--dot=TOKEN` | Check specific provider | Multi-token env |
| `--fix-token` | Fix token issues | Token expiring |
| `--quiet`, `-q` | Minimal output | Automation/scripts |
| `--verbose`, `-v` | Debug output | Troubleshooting |

---

## Cache Behavior

| Operation | Time | Cache |
|-----------|------|-------|
| First check | ~2-3s | Miss → create |
| Cached check | < 100ms | Hit (< 5 min) |
| After rotation | ~2-3s | Cleared → fresh |

**Cache TTL:** 5 minutes
**Cache Location:** `~/.flow/cache/doctor/token-*.cache`

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All tokens valid |
| 1 | Issues detected |
| 2 | Command error |

---

## Verbosity Levels

### Quiet (`--quiet`)

```
(no output unless errors)
```

### Normal (default)

```
🔑 GITHUB TOKEN
✓ Token valid (45 days remaining)
```

### Verbose (`--verbose`)

```
🔑 GITHUB TOKEN
[Cache hit - age: 45s, TTL: 300s]
[Delegation: dot token expiring]
✓ Token valid (45 days remaining)
  Username: your-username
  Token type: fine-grained
  Age: 100 days
```

---

## Performance Targets

| Metric | Target | Actual |
|--------|--------|--------|
| Cache check | < 10ms | ~5-8ms |
| Token check (cached) | < 100ms | ~50-80ms |
| Token check (fresh) | < 3s | ~2-3s |
| Cache effectiveness | 80%+ | ~85% |

---

## Troubleshooting

### Cache Not Working

```bash
# Verify cache directory
ls -la ~/.flow/cache/doctor/

# Clear and retry
rm -rf ~/.flow/cache/doctor
doctor --dot --verbose
```

### Slow Checks

```bash
# Check if cache is being used
doctor --dot --verbose
# Look for "[Cache hit...]" or "[Cache miss...]"
```

### Token Issues Not Detected

```bash
# Force fresh check
rm ~/.flow/cache/doctor/token-github.cache
doctor --dot --verbose
```

---

## Integration

### With Other Commands

```bash
# In work session banner
work <project>
# Shows: ⚠ GitHub token expiring in 5 days

# Before git push
g push
# Validates token before remote operation

# In dashboard
dash
# Shows token status in dev section
```

### In Scripts

```bash
#!/bin/bash
# Daily health check
if ! doctor --dot --quiet; then
    notify "Token issues - run 'doctor --fix-token'"
fi
```

---

## See Also

- [User Guide](../guides/DOCTOR-TOKEN-USER-GUIDE.md) - Complete workflows
- [API Reference](DOCTOR-TOKEN-API-REFERENCE.md) - Function details
- [Architecture](../architecture/DOCTOR-TOKEN-ARCHITECTURE.md) - Design decisions

---

**Quick Tip:** Run `doctor --dot` every 5 minutes for optimal cache usage (85% hit rate)
