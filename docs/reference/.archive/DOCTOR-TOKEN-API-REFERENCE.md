# Doctor Token API Reference

**Version:** v5.17.0 (Phase 1)
**Last Updated:** 2026-01-23
**Status:** Production Ready

---

## Overview

The flow doctor token enhancement adds comprehensive token automation capabilities to the `flow doctor` health check command. This reference documents all public APIs, functions, and usage patterns.

### Quick Links

- [Command-Line Interface](#command-line-interface)
- [Cache API](#cache-api-reference)
- [Internal Functions](#internal-functions)
- [Error Codes](#error-codes)
- [Performance Targets](#performance-targets)

---

## Command-Line Interface

### doctor --dot

Check only GitHub token health (isolated mode).

**Syntax:**

```bash
doctor --dot [--verbose | --quiet]
```

**Behavior:**
- Skips all non-token health checks (tools, aliases, etc.)
- Delegates to `dot token expiring` for validation
- Uses cache (5-minute TTL) to avoid GitHub API rate limits
- Returns token status: valid, expiring, expired, or invalid

**Performance:**
- **First check:** ~2-3 seconds (GitHub API call)
- **Cached check:** < 10ms (file read)
- **Target:** < 3 seconds total

**Examples:**

```bash
# Basic token check
doctor --dot

# With debug output
doctor --dot --verbose

# Minimal output
doctor --dot --quiet
```

**Exit Codes:**
- `0` - All tokens valid
- `1` - Token issues detected
- `2` - Token check failed (internal error)

---

### doctor --dot=TOKEN

Check specific token by provider name.

**Syntax:**

```bash
doctor --dot=<provider> [--verbose | --quiet]
```

**Supported Providers:**
- `github` - GitHub token (from DOT)
- `npm` - NPM token (future)
- `pypi` - PyPI token (future)

**Examples:**

```bash
# Check GitHub token only
doctor --dot=github

# Check NPM token (when available)
doctor --dot=npm
```

**Exit Codes:**
- `0` - Token valid
- `1` - Token invalid/expiring
- `2` - Provider not found

---

### doctor --fix-token

Fix token issues only (shows category menu).

**Syntax:**

```bash
doctor --fix-token [--yes] [--verbose | --quiet]
```

**Behavior:**
- Shows ADHD-friendly category selection menu
- Filters to token category only
- Offers token rotation via `dot token rotate`
- Clears cache after successful rotation

**Menu Example:**

```
╭─ Select Category to Fix ────────────────────────╮
│                                                  │
│  1. 🔑 GitHub Token (2 issues, ~30s)            │
│                                                  │
│  0. Exit without fixing                         │
│                                                  │
╰──────────────────────────────────────────────────╯

Select [1, 0 to exit]:
```

**With --yes flag:**

```bash
# Auto-fix without menu
doctor --fix-token --yes
```

**Exit Codes:**
- `0` - Fix successful
- `1` - Fix failed or user cancelled
- `2` - No fixes needed

---

### Verbosity Flags

Control output detail level.

#### --quiet / -q

Minimal output (errors only).

**Usage:**

```bash
doctor --dot --quiet
```

**Output:**
- Only shows critical errors
- Suppresses success messages
- Suppresses cache status

#### --verbose / -v

Detailed debug output.

**Usage:**

```bash
doctor --dot --verbose
```

**Output:**
- Shows cache hit/miss status
- Shows API call timing
- Shows delegation details
- Shows JSON parsing steps

**Example Output:**

```
🔑 GITHUB TOKEN
[Cache hit - age: 45s, TTL: 300s]
✓ Token valid (45 days remaining)
```

---

## Cache API Reference

### Overview

The cache manager (`lib/doctor-cache.zsh`) provides a 5-minute TTL cache system for token validation results.

**Cache Location:** `~/.flow/cache/doctor/`

**Performance Targets:**
- Cache check: < 10ms
- Cache write: < 20ms
- Cleanup: < 100ms

---

### Core Functions

#### _doctor_cache_init()

Initialize cache directory and cleanup old entries.

**Syntax:**

```zsh
_doctor_cache_init
```

**Behavior:**
- Creates `~/.flow/cache/doctor/` if missing
- Removes cache entries > 1 day old
- Silent failure (doesn't block if mkdir fails)

**Returns:**
- `0` - Success
- `1` - Initialization failed (non-blocking)

**Example:**

```zsh
# Initialize cache (called automatically by doctor)
_doctor_cache_init 2>/dev/null
```

---

#### _doctor_cache_get(key)

Retrieve cached value if fresh (< 5 min).

**Syntax:**

```zsh
_doctor_cache_get <key>
```

**Arguments:**
- `key` - Cache key (e.g., "token-github")

**Returns:**
- `0` - Cache hit (value printed to stdout)
- `1` - Cache miss or stale

**Output:**
- On hit: JSON string of cached data
- On miss: Empty

**Example:**

```zsh
if cached=$(_doctor_cache_get "token-github"); then
    echo "Cache hit: $cached"
else
    echo "Cache miss - fetching fresh data"
fi
```

**Cache Format:**

```json
{
  "token_name": "github-token",
  "provider": "github",
  "cached_at": "2026-01-23T12:30:00Z",
  "expires_at": "2026-01-23T12:35:00Z",
  "ttl_seconds": 300,
  "status": "valid",
  "days_remaining": 45,
  "username": "your-username",
  "metadata": {
    "token_age_days": 100,
    "token_type": "fine-grained"
  }
}
```

---

#### _doctor_cache_set(key, value, [ttl])

Store value in cache with TTL.

**Syntax:**

```zsh
_doctor_cache_set <key> <value> [ttl]
```

**Arguments:**
- `key` - Cache key (e.g., "token-github")
- `value` - JSON string to cache
- `ttl` - (optional) TTL in seconds (default: 300)

**Returns:**
- `0` - Success
- `1` - Write failed

**Example:**

```zsh
# Cache for 5 minutes (default)
_doctor_cache_set "token-github" "$json_data"

# Cache for 10 minutes
_doctor_cache_set "token-github" "$json_data" 600
```

**Atomicity:**
- Uses temp file + `mv` for atomic writes
- Safe for concurrent access

---

#### _doctor_cache_clear([key])

Clear specific entry or entire cache.

**Syntax:**

```zsh
_doctor_cache_clear [key]
```

**Arguments:**
- `key` - (optional) Specific cache key to clear

**Behavior:**
- With key: Removes single cache file
- Without key: Clears all cache files

**Returns:**
- `0` - Success
- `1` - Clear failed

**Examples:**

```zsh
# Clear specific token cache
_doctor_cache_clear "token-github"

# Clear all cache
_doctor_cache_clear
```

**Use Cases:**
- After token rotation (invalidate cache)
- User requests fresh check
- Cache corruption detected

---

#### _doctor_cache_stats()

Show cache statistics and entries.

**Syntax:**

```zsh
_doctor_cache_stats
```

**Output:**

```
Cache Statistics:
  Directory: ~/.flow/cache/doctor
  Total entries: 3
  Total size: 2.4 KB

Cached Entries:
  token-github    45s ago    valid (45 days remaining)
  token-npm       120s ago   valid (60 days remaining)
  token-pypi      200s ago   expired
```

**Returns:**
- `0` - Always succeeds

---

### Convenience Wrappers

#### _doctor_cache_token_get(provider)

Get cached token validation result.

**Syntax:**

```zsh
_doctor_cache_token_get <provider>
```

**Arguments:**
- `provider` - Token provider (e.g., "github", "npm")

**Returns:**
- `0` - Cache hit (JSON to stdout)
- `1` - Cache miss

**Example:**

```zsh
if result=$(_doctor_cache_token_get "github"); then
    echo "Cached: $result"
fi
```

---

#### _doctor_cache_token_set(provider, value, [ttl])

Cache token validation result.

**Syntax:**

```zsh
_doctor_cache_token_set <provider> <value> [ttl]
```

**Arguments:**
- `provider` - Token provider
- `value` - JSON validation result
- `ttl` - (optional) TTL in seconds

**Example:**

```zsh
_doctor_cache_token_set "github" "$validation_json" 300
```

---

#### _doctor_cache_token_clear(provider)

Clear token cache.

**Syntax:**

```zsh
_doctor_cache_token_clear <provider>
```

**Example:**

```zsh
# After token rotation
_doctor_cache_token_clear "github"
```

---

## Internal Functions

### Category Menu

#### _doctor_select_fix_category()

Display ADHD-friendly category selection menu.

**Syntax:**

```zsh
_doctor_select_fix_category
```

**Returns:**
- `0` - Category selected (prints to stdout)
- `1` - User cancelled

**Output:**
- Category name: "tokens", "tools", "aliases"
- Special: "all", "exit"

**Menu Design:**
- Single-choice (no checkboxes)
- Time estimates per category
- Auto-select if only one issue
- Clear exit option

---

#### _doctor_count_categories()

Count categories with issues.

**Syntax:**

```zsh
_doctor_count_categories
```

**Returns:**
- Count of categories with issues (stdout)

---

#### _doctor_apply_fixes(category)

Route fixes to appropriate handlers.

**Syntax:**

```zsh
_doctor_apply_fixes <category>
```

**Arguments:**
- `category` - Category to fix ("tokens", "tools", "aliases", "all")

**Behavior:**
- Tokens: Calls `_doctor_fix_tokens()`
- Tools: Calls `_doctor_fix_tools()`
- Aliases: Calls `_doctor_fix_aliases()`
- All: Fixes sequentially

---

#### _doctor_fix_tokens()

Fix token-specific issues.

**Behavior:**
1. Calls `_tok_rotate()` for invalid/expiring tokens
2. Clears cache: `_doctor_cache_token_clear()`
3. Logs success as "Security maintenance" win

---

### Verbosity Helpers

#### _doctor_log_quiet(message)

Log in normal and verbose modes.

**Usage:**

```zsh
_doctor_log_quiet "Processing request..."
```

**Output:**
- Quiet mode: Suppressed
- Normal mode: Shown
- Verbose mode: Shown

---

#### _doctor_log_verbose(message)

Log only in verbose mode.

**Usage:**

```zsh
_doctor_log_verbose "Cache hit: 45s old"
```

**Output:**
- Quiet mode: Suppressed
- Normal mode: Suppressed
- Verbose mode: Shown

---

#### _doctor_log_always(message)

Always log (critical messages).

**Usage:**

```zsh
_doctor_log_always "Error: Token validation failed"
```

**Output:**
- All modes: Shown

---

## Error Codes

### Command Exit Codes

| Code | Meaning | Action |
|------|---------|--------|
| 0 | Success | All checks passed or fixes succeeded |
| 1 | Issues found | Token problems detected or fix failed |
| 2 | Internal error | Cache error, delegation failed |

### Cache Function Returns

| Code | Meaning |
|------|---------|
| 0 | Success or cache hit |
| 1 | Failure or cache miss |

---

## Performance Targets

### Response Times

| Operation | Target | Actual (Phase 1) |
|-----------|--------|------------------|
| Cache check | < 10ms | ~5-8ms |
| Cache write | < 20ms | ~10-15ms |
| Token check (cached) | < 100ms | ~50-80ms |
| Token check (fresh) | < 3s | ~2-3s |
| Category menu | < 1s | ~500ms |

### Cache Effectiveness

| Metric | Target | Expected |
|--------|--------|----------|
| Hit rate (5 min) | > 80% | ~85% |
| API call reduction | > 80% | ~85% |
| Storage per entry | < 2 KB | ~1.5 KB |

### Scalability

| Factor | Limit | Notes |
|--------|-------|-------|
| Cache entries | 100 | Auto-cleanup at 1 day |
| Cache size | 200 KB | ~1.5 KB per entry |
| Concurrent access | Unlimited | flock-based safety |

---

## Data Models

### Token Validation Result

**Schema:**

```typescript
interface TokenValidation {
  token_name: string;           // "github-token"
  provider: "github" | "npm" | "pypi";
  cached_at: string;            // ISO 8601 timestamp
  expires_at: string;           // ISO 8601 timestamp
  ttl_seconds: number;          // 300 (5 minutes)
  status: "valid" | "expiring" | "expired" | "invalid";
  days_remaining: number;       // Days until token expires
  username: string;             // Token owner
  metadata: {
    token_age_days: number;
    token_type: "classic" | "fine-grained";
    services: {
      gh_cli: "authenticated" | "missing";
      claude_mcp: "configured" | "missing";
      env_var: "set" | "missing";
    }
  }
}
```

**Example:**

```json
{
  "token_name": "github-token",
  "provider": "github",
  "cached_at": "2026-01-23T12:30:00Z",
  "expires_at": "2026-01-23T12:35:00Z",
  "ttl_seconds": 300,
  "status": "valid",
  "days_remaining": 45,
  "username": "your-username",
  "metadata": {
    "token_age_days": 100,
    "token_type": "fine-grained",
    "services": {
      "gh_cli": "authenticated",
      "claude_mcp": "configured",
      "env_var": "missing"
    }
  }
}
```

---

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DOCTOR_CACHE_DEFAULT_TTL` | 300 | Cache TTL (seconds) |
| `DOCTOR_CACHE_LOCK_TIMEOUT` | 2 | Lock timeout (seconds) |
| `DOCTOR_CACHE_MAX_AGE_SECONDS` | 86400 | Cleanup threshold (1 day) |
| `DOCTOR_CACHE_DIR` | `~/.flow/cache/doctor` | Cache directory |

### Customization

```bash
# Extend cache TTL to 10 minutes
export DOCTOR_CACHE_DEFAULT_TTL=600

# Reduce lock timeout
export DOCTOR_CACHE_LOCK_TIMEOUT=1

# Custom cache directory
export DOCTOR_CACHE_DIR="/tmp/flow-cache"
```

---

## Migration Guide

### From doctor (pre-v5.17.0)

**Old workflow:**

```bash
# Check everything
doctor

# Fix everything
doctor --fix
```

**New workflow (Phase 1):**

```bash
# Check only tokens (fast)
doctor --dot

# Fix only tokens
doctor --fix-token

# Check with cache debug
doctor --dot --verbose
```

**Backward Compatibility:**
- All existing flags work unchanged
- `doctor` without flags still checks everything
- `doctor --fix` still shows full menu

---

## See Also

- [Phase 1 Spec](../../specs/SPEC-flow-doctor-dot-enhancement-2026-01-23.md) - Implementation specification
- [Test Suites](../../tests/) - Comprehensive test coverage
- [DOT Dispatcher Reference](DOT-DISPATCHER-REFERENCE.md) - Token automation commands
- [Cache Implementation](../../lib/doctor-cache.zsh) - Source code

---

**Last Updated:** 2026-01-23
**Maintainer:** flow-cli team
**License:** MIT
