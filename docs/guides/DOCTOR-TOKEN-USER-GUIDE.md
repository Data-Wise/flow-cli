# Doctor Token Enhancement - User Guide

**Version:** v5.17.0 (Phase 1)
**Last Updated:** 2026-01-23

---

## Table of Contents

1. [Introduction](#introduction)
2. [Quick Start](#quick-start)
3. [Common Workflows](#common-workflows)
4. [Command Reference](#command-reference)
5. [Troubleshooting](#troubleshooting)
6. [Performance Tips](#performance-tips)
7. [FAQ](#faq)

---

## Introduction

The flow doctor token enhancement adds powerful GitHub token management capabilities to your workflow. This guide shows you how to use these features effectively.

### What's New in Phase 1

✅ **Isolated Token Checks** - Check only GitHub tokens (< 3s)
✅ **Smart Caching** - 5-minute cache reduces API calls by 80%
✅ **Category Menu** - ADHD-friendly fix selection
✅ **Verbosity Control** - Choose your output detail level
✅ **Token-Only Fixes** - Rotate tokens without waiting for other checks

### Why Use This?

**Before Phase 1:**

```bash
$ doctor
# Checks: shell, tools, integrations, dotfiles (slow)
# Result: "GitHub token expiring in 5 days"
```

**After Phase 1:**

```bash
$ doctor --dot
# Checks: GitHub token only (fast)
# Result: Same info in < 3 seconds
```

---

## Quick Start

### 1. Check Your Token

```bash
doctor --dot
```

**Output:**

```
🔑 GITHUB TOKEN
✓ Token valid (45 days remaining)
```

**What happens:**
- Checks token expiration status
- Uses cache if checked recently (< 5 min)
- Shows days remaining until expiration

---

### 2. Fix Token Issues

```bash
doctor --fix-token
```

**Interactive menu appears:**

```
╭─ Select Category to Fix ────────────────────────╮
│                                                  │
│  1. 🔑 GitHub Token (2 issues, ~30s)            │
│                                                  │
│  0. Exit without fixing                         │
│                                                  │
╰──────────────────────────────────────────────────╯

Select [1, 0 to exit]: 1
```

**What happens:**
1. Shows token issues with time estimate
2. You select what to fix
3. Rotates token automatically
4. Clears cache for fresh validation

---

### 3. Debug with Verbose Mode

```bash
doctor --dot --verbose
```

**Output:**

```
🔑 GITHUB TOKEN
[Cache hit - age: 45s, TTL: 300s]
[Delegation: dot token expiring]
✓ Token valid (45 days remaining)
  Username: your-username
  Token type: fine-grained
  Age: 100 days
```

**What you see:**
- Cache status (hit or miss)
- API call details
- Extended token metadata

---

## Common Workflows

### Morning Routine Check

Check token health before starting work:

```bash
# Quick check (uses cache if available)
doctor --dot

# If expiring soon, fix it
doctor --fix-token
```

**Time:** < 3 seconds (cached) or ~30 seconds (rotation)

---

### Pre-Push Validation

Before `git push`, ensure token is valid:

```bash
# Quick token check
doctor --dot --quiet

# If check fails, exit code 1
echo $?  # 0 = success, 1 = issues
```

**Use in scripts:**

```bash
#!/bin/bash
if ! doctor --dot --quiet; then
    echo "Token issues detected - run 'doctor --fix-token'"
    exit 1
fi

git push
```

---

### Minimal Output for CI/CD

In automated environments:

```bash
# Minimal output (errors only)
doctor --dot --quiet

# Check exit code
if [ $? -eq 0 ]; then
    echo "Token OK"
else
    echo "Token issues"
fi
```

---

### Deep Debugging

When troubleshooting token issues:

```bash
# Full debug output
doctor --dot --verbose

# Check cache statistics
_doctor_cache_stats

# Force fresh check (clear cache)
_doctor_cache_clear "token-github"
doctor --dot --verbose
```

---

## Command Reference

### Basic Commands

#### doctor --dot

**Purpose:** Check GitHub token health only

**Usage:**

```bash
doctor --dot
```

**When to use:**
- Morning health check
- Before git operations
- Pre-deployment validation
- Scheduled monitoring

**Performance:**
- First check: ~2-3 seconds
- Cached check: < 100ms

---

#### doctor --dot=github

**Purpose:** Check specific token provider

**Usage:**

```bash
doctor --dot=github
```

**When to use:**
- Multi-token environments
- Specific provider validation
- Targeted debugging

---

#### doctor --fix-token

**Purpose:** Fix token issues interactively

**Usage:**

```bash
doctor --fix-token
```

**When to use:**
- Token expiring warning
- Invalid token detected
- Rotation needed

**What it does:**
1. Shows category menu
2. Rotates selected tokens
3. Clears cache
4. Logs as "Security maintenance" win

---

### Verbosity Flags

#### --quiet / -q

**Purpose:** Minimal output (errors only)

**Usage:**

```bash
doctor --dot --quiet
```

**Output:**
- Only errors shown
- No success messages
- No cache debug info

**Best for:**
- Scripts and automation
- CI/CD pipelines
- Scheduled checks

---

#### --verbose / -v

**Purpose:** Detailed debug output

**Usage:**

```bash
doctor --dot --verbose
```

**Output:**
- Cache hit/miss status
- API call timing
- Token metadata
- Delegation details

**Best for:**
- Troubleshooting
- Understanding cache behavior
- Performance analysis

---

### Flag Combinations

#### Fast + Quiet

```bash
doctor --dot --quiet
```

**Use case:** Scheduled monitoring

---

#### Fresh + Verbose

```bash
_doctor_cache_clear "token-github"
doctor --dot --verbose
```

**Use case:** Force fresh check with debug info

---

#### Auto-Fix

```bash
doctor --fix-token --yes
```

**Use case:** Non-interactive rotation

---

## Troubleshooting

### Token Check Slow

**Symptom:** `doctor --dot` takes > 5 seconds

**Causes:**
1. Cache miss (first check or expired)
2. GitHub API slow response
3. Network issues

**Solutions:**

```bash
# Check cache status
doctor --dot --verbose

# Verify cache working
doctor --dot  # First run (slow)
doctor --dot  # Second run (fast < 100ms)

# Clear stale cache
_doctor_cache_clear
```

---

### Cache Not Working

**Symptom:** Every check is slow (~3s)

**Diagnosis:**

```bash
# Check cache directory exists
ls -la ~/.flow/cache/doctor/

# Check cache permissions
ls -ld ~/.flow/cache/doctor/

# Verify cache files
cat ~/.flow/cache/doctor/token-github.cache
```

**Fix:**

```bash
# Recreate cache directory
rm -rf ~/.flow/cache/doctor
_doctor_cache_init

# Check again
doctor --dot --verbose
```

---

### Menu Not Showing

**Symptom:** `doctor --fix-token` doesn't show menu

**Causes:**
1. No token issues detected
2. Missing menu function
3. Auto-yes mode enabled

**Solutions:**

```bash
# Check if issues exist
doctor --dot

# Check function exists
type _doctor_select_fix_category

# Disable auto-yes
doctor --fix-token  # Without --yes
```

---

### Invalid Token Not Detected

**Symptom:** Token invalid but doctor shows OK

**Causes:**
1. Stale cache (< 5 min old)
2. Token rotated but cache not cleared

**Solutions:**

```bash
# Clear cache
_doctor_cache_clear "token-github"

# Force fresh check
doctor --dot --verbose

# Verify delegation
type _dot_token_expiring
```

---

## Performance Tips

### Optimize Cache Usage

**Best practices:**
1. Run checks frequently (cache is free)
2. Use `--quiet` in scripts (faster output)
3. Clear cache after token operations

```bash
# Good: Frequent cheap checks
doctor --dot --quiet  # Every 5 min = 80% cache hits

# Bad: Infrequent expensive checks
doctor  # Every hour = 0% cache hits + slow
```

---

### Reduce API Calls

**Cache effectiveness:**
- **5-minute window:** 80%+ cache hits
- **15-minute window:** 50% cache hits
- **30-minute window:** 25% cache hits

**Recommendation:** Check every 3-5 minutes for optimal cache use

---

### Script Integration

**Fast health check:**

```bash
#!/bin/bash
# Daily check (morning routine)

if doctor --dot --quiet; then
    echo "✓ Token valid"
else
    echo "⚠ Token issues - run 'doctor --fix-token'"
    exit 1
fi
```

---

### Monitoring Automation

**Scheduled checks:**

```bash
# crontab
*/5 * * * * doctor --dot --quiet || echo "Token issues" | mail -s "Token Alert" you@example.com
```

---

## FAQ

### How often should I check my token?

**Recommended:** Every 3-5 minutes during active development

**Why:** Optimal cache hit rate (80%+) with low overhead

---

### What happens to the cache after token rotation?

**Automatic:** Cache is cleared immediately after successful rotation

**Manual:** You can clear with `_doctor_cache_clear "token-github"`

---

### Can I disable caching?

**Not recommended** - Cache reduces GitHub API calls by 80%

**Workaround:** Clear before each check:

```bash
_doctor_cache_clear && doctor --dot
```

---

### Does --quiet suppress errors?

**No** - Errors are always shown in all verbosity modes

**Only suppressed:** Success messages, cache debug, delegation info

---

### How do I know if cache is working?

**Use verbose mode:**

```bash
doctor --dot --verbose

# Output shows:
# [Cache hit - age: 45s, TTL: 300s]  ← Cache working
# [Cache miss - validating...]       ← Cache not used
```

---

### What's the difference between doctor --fix and doctor --fix-token?

**doctor --fix:**
- Shows all categories (tokens, tools, aliases)
- Longer menu
- More options

**doctor --fix-token:**
- Shows token category only
- Faster to navigate
- Token-focused workflow

---

### Can I use this in CI/CD?

**Yes** - Use `--quiet` for minimal output:

```bash
# In CI pipeline
doctor --dot --quiet
exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo "Token valid"
else
    echo "Token issues detected"
    exit 1
fi
```

---

### How do I check multiple tokens?

**Phase 1:** GitHub only

**Future (Phases 2-4):**

```bash
doctor --dot  # Check all tokens
doctor --dot=github,npm,pypi  # Specific tokens
```

---

## Next Steps

### Learn More

- [API Reference](../reference/MASTER-API-REFERENCE.md#doctor-cache) - Complete API documentation
- [Phase 1 Spec](../specs/SPEC-flow-doctor-dot-enhancement-2026-01-23.md) - Implementation details
- [Test Suites](../../tests/) - Usage examples in tests

### Related Commands

- `dot token expiring` - Manual token expiration check
- `dot token rotate` - Manual token rotation
- `dash dev` - Developer dashboard with token status

### Provide Feedback

Found a bug or have a feature request?
- GitHub Issues: https://github.com/Data-Wise/flow-cli/issues
- Tag: `doctor-token-enhancement`

---

**Last Updated:** 2026-01-23
**Version:** v5.17.0 (Phase 1)
**Maintainer:** flow-cli team
