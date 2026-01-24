# Master API Reference

**Purpose:** Complete API documentation for all flow-cli library functions
**Audience:** Developers, contributors, advanced users
**Format:** Function signatures, parameters, return values, examples
**Version:** v5.17.0-dev
**Last Updated:** 2026-01-24

---

## Overview

This document provides complete API documentation for all flow-cli library functions. Functions are organized by library file and categorized by purpose.

### Coverage Status

**Total Functions:** 853
**Documented:** 421 (49.4%)
**Auto-Generated:** Will be updated by `scripts/generate-api-docs.sh`

### Library Organization

flow-cli's library is organized into focused modules:

```
lib/
├── core.zsh                    # Core utilities (80+ functions)
├── atlas-bridge.zsh            # Atlas integration (15+ functions)
├── project-detector.zsh        # Project type detection (25+ functions)
├── tui.zsh                     # Terminal UI components (30+ functions)
├── inventory.zsh               # Tool inventory (10+ functions)
├── keychain-helpers.zsh        # macOS Keychain (20+ functions)
├── config-validator.zsh        # Config validation (15+ functions)
├── git-helpers.zsh             # Git integration (30+ functions)
├── doctor-cache.zsh            # Token validation caching (13 functions)
├── concept-extraction.zsh      # Teaching: YAML parsing (25+ functions)
├── prerequisite-checker.zsh    # Teaching: DAG validation (20+ functions)
├── analysis-cache.zsh          # Teaching: Cache management (40+ functions)
├── report-generator.zsh        # Teaching: Report generation (30+ functions)
├── ai-analysis.zsh             # Teaching: Claude integration (15+ functions)
├── slide-optimizer.zsh         # Teaching: Slide breaks (20+ functions)
└── dispatchers/                # 12 dispatcher modules (478+ functions)
    ├── g-dispatcher.zsh
    ├── cc-dispatcher.zsh
    ├── r-dispatcher.zsh
    ├── qu-dispatcher.zsh
    ├── mcp-dispatcher.zsh
    ├── obs.zsh
    ├── wt-dispatcher.zsh
    ├── dot-dispatcher.zsh
    ├── teach-dispatcher.zsh
    ├── tm-dispatcher.zsh
    ├── prompt-dispatcher.zsh
    └── v-dispatcher.zsh
```

---

## How to Use This Reference

### For Developers

**Finding functions:**
1. Use browser search (Ctrl+F / Cmd+F)
2. Check [Function Index](#function-index) (alphabetical)
3. Browse by category

**Understanding function signatures:**
```zsh
function_name() {
    # Parameters:
    #   $1 - description of first parameter
    #   $2 - description of second parameter (optional)
    # Returns:
    #   0 - success
    #   1 - error
    # Example:
    #   function_name "arg1" "arg2"
}
```

### For Contributors

When adding new functions:
1. Follow naming conventions (see [CONVENTIONS.md](../../CONVENTIONS.md))
2. Add inline documentation
3. Run `./scripts/generate-api-docs.sh` to update this file
4. Test examples

---

## Table of Contents

- [Core Library](#core-library) - Essential utilities
- [Atlas Integration](#atlas-integration) - State engine
- [Project Detection](#project-detection) - Project type detection
- [Terminal UI](#terminal-ui) - TUI components
- [Tool Inventory](#tool-inventory) - Dependency tracking
- [Keychain Helpers](#keychain-helpers) - Secret management
- [Config Validation](#config-validation) - Configuration
- [Git Helpers](#git-helpers) - Git integration
- [Doctor Cache](#doctor-cache) - Token validation caching (v5.17.0+)
- [Teaching Libraries](#teaching-libraries) - AI-powered teaching
- [Dispatcher APIs](#dispatcher-apis) - Dispatcher functions
- [Function Index](#function-index) - Alphabetical index

---

## Core Library

**File:** `lib/core.zsh`
**Purpose:** Essential utilities used throughout flow-cli
**Functions:** 80+

### Logging & Output

#### `_flow_log_success`

Logs success message with green checkmark.

**Signature:**
```zsh
_flow_log_success "message"
```

**Parameters:**
- `$1` - Message to log

**Returns:**
- Always returns 0

**Example:**
```zsh
_flow_log_success "Project initialized successfully"
# Output: ✅ Project initialized successfully
```

---

#### `_flow_log_error`

Logs error message with red X.

**Signature:**
```zsh
_flow_log_error "message"
```

**Parameters:**
- `$1` - Error message

**Returns:**
- Always returns 1

**Example:**
```zsh
_flow_log_error "Configuration file not found"
# Output: ❌ Configuration file not found
```

---

#### `_flow_log_warning`

Logs warning message with yellow warning sign.

**Signature:**
```zsh
_flow_log_warning "message"
```

**Parameters:**
- `$1` - Warning message

**Returns:**
- Always returns 0

**Example:**
```zsh
_flow_log_warning "Token expires in 5 days"
# Output: ⚠️  Token expires in 5 days
```

---

#### `_flow_log_info`

Logs info message with blue info icon.

**Signature:**
```zsh
_flow_log_info "message"
```

**Parameters:**
- `$1` - Info message

**Returns:**
- Always returns 0

**Example:**
```zsh
_flow_log_info "Loading configuration from ~/.flowrc"
# Output: ℹ️  Loading configuration from ~/.flowrc
```

---

### Project Utilities

#### `_flow_find_project_root`

Finds git repository root from current directory.

**Signature:**
```zsh
_flow_find_project_root
```

**Parameters:**
- None (uses current directory)

**Returns:**
- 0 - Success, prints root path to stdout
- 1 - Not in git repository

**Example:**
```zsh
root=$(_flow_find_project_root)
if [[ $? -eq 0 ]]; then
    echo "Project root: $root"
else
    echo "Not in git repository"
fi
```

---

#### `_flow_detect_project_type`

Detects project type from directory structure.

**Signature:**
```zsh
_flow_detect_project_type "/path/to/project"
```

**Parameters:**
- `$1` - Project directory path

**Returns:**
- 0 - Success, prints project type to stdout
- 1 - Unknown project type

**Supported Types:**
- `node` - Node.js (package.json)
- `r` - R package (DESCRIPTION with Package:)
- `python` - Python (pyproject.toml, setup.py)
- `quarto` - Quarto (_quarto.yml)
- `teaching` - Teaching course (course-config.yml)
- `mcp` - MCP server (mcp-server/ directory)

**Example:**
```zsh
type=$(_flow_detect_project_type "$PWD")
echo "Project type: $type"
# Output: Project type: node
```

---

### Color Utilities

#### `_flow_color_red`

Outputs text in red.

**Signature:**
```zsh
_flow_color_red "text"
```

**Parameters:**
- `$1` - Text to colorize

**Example:**
```zsh
echo "$(_flow_color_red 'Error occurred')"
```

---

#### `_flow_color_green`

Outputs text in green.

**Signature:**
```zsh
_flow_color_green "text"
```

**Parameters:**
- `$1` - Text to colorize

**Example:**
```zsh
echo "$(_flow_color_green 'Success!')"
```

---

#### `_flow_color_yellow`

Outputs text in yellow.

**Signature:**
```zsh
_flow_color_yellow "text"
```

**Parameters:**
- `$1` - Text to colorize

**Example:**
```zsh
echo "$(_flow_color_yellow 'Warning')"
```

---

#### `_flow_color_blue`

Outputs text in blue.

**Signature:**
```zsh
_flow_color_blue "text"
```

**Parameters:**
- `$1` - Text to colorize

**Example:**
```zsh
echo "$(_flow_color_blue 'Info')"
```

---

## Keychain Helpers

**File:** `lib/keychain-helpers.zsh`
**Purpose:** macOS Keychain integration for secret management
**Functions:** 20+
**Platform:** macOS only

### Secret Storage

#### `_flow_keychain_set`

Stores secret in macOS Keychain with Touch ID.

**Signature:**
```zsh
_flow_keychain_set "SECRET_NAME" "secret_value"
```

**Parameters:**
- `$1` - Secret name (e.g., GITHUB_TOKEN)
- `$2` - Secret value

**Returns:**
- 0 - Success
- 1 - Failed to store (keychain locked, permission denied)

**Security:**
- Uses macOS Keychain
- Requires Touch ID (or password fallback)
- Encrypted at rest

**Example:**
```zsh
if _flow_keychain_set "GITHUB_TOKEN" "ghp_xxxxxxxxxxxx"; then
    _flow_log_success "Token stored in keychain"
else
    _flow_log_error "Failed to store token"
fi
```

---

#### `_flow_keychain_get`

Retrieves secret from macOS Keychain.

**Signature:**
```zsh
_flow_keychain_get "SECRET_NAME"
```

**Parameters:**
- `$1` - Secret name

**Returns:**
- 0 - Success, prints value to stdout
- 1 - Secret not found or keychain locked

**Example:**
```zsh
token=$(_flow_keychain_get "GITHUB_TOKEN")
if [[ $? -eq 0 ]]; then
    export GITHUB_TOKEN="$token"
else
    _flow_log_error "Token not found in keychain"
fi
```

---

#### `_flow_keychain_delete`

Deletes secret from keychain.

**Signature:**
```zsh
_flow_keychain_delete "SECRET_NAME"
```

**Parameters:**
- `$1` - Secret name

**Returns:**
- 0 - Success
- 1 - Failed to delete

**Example:**
```zsh
_flow_keychain_delete "OLD_TOKEN"
```

---

#### `_flow_keychain_list`

Lists all flow-cli secrets in keychain.

**Signature:**
```zsh
_flow_keychain_list
```

**Parameters:**
- None

**Returns:**
- 0 - Success, prints secret names (one per line)

**Example:**
```zsh
_flow_keychain_list
# Output:
# GITHUB_TOKEN
# NPM_TOKEN
# HOMEBREW_GITHUB_API_TOKEN
```

---

## Git Helpers

**File:** `lib/git-helpers.zsh`
**Purpose:** Git integration utilities
**Functions:** 30+

### Token Validation

#### `_flow_git_validate_token`

Validates GitHub token before remote operations.

**Signature:**
```zsh
_flow_git_validate_token
```

**Parameters:**
- None (uses GITHUB_TOKEN from keychain or environment)

**Returns:**
- 0 - Token valid
- 1 - Token invalid or expired

**Caching:**
- Uses 5-minute cache (v5.17.0+)
- Cache file: `~/.cache/flow/doctor/tokens.cache`

**Example:**
```zsh
if _flow_git_validate_token; then
    git push origin dev
else
    _flow_log_error "Invalid token, run: dot secret rotate GITHUB_TOKEN"
    return 1
fi
```

---

### Branch Utilities

#### `_flow_git_current_branch`

Gets current git branch name.

**Signature:**
```zsh
_flow_git_current_branch
```

**Parameters:**
- None

**Returns:**
- 0 - Success, prints branch name
- 1 - Not in git repository

**Example:**
```zsh
branch=$(_flow_git_current_branch)
echo "Current branch: $branch"
```

---

#### `_flow_git_is_clean`

Checks if working tree is clean (no uncommitted changes).

**Signature:**
```zsh
_flow_git_is_clean
```

**Parameters:**
- None

**Returns:**
- 0 - Working tree clean
- 1 - Uncommitted changes exist

**Example:**
```zsh
if _flow_git_is_clean; then
    echo "✅ No uncommitted changes"
else
    echo "⚠️  Uncommitted changes detected"
fi
```

---

## Doctor Cache

**File:** `lib/doctor-cache.zsh`
**Purpose:** Smart caching for token validation results
**Functions:** 13
**Version:** v5.17.0+

### Overview

The doctor cache system provides high-performance caching for token validation results with:

- **5-minute TTL** - Prevents excessive API calls
- **Concurrent safety** - flock-based locking
- **Performance** - < 10ms cache checks, 80% API reduction
- **Automatic cleanup** - Removes entries > 1 day old

**Cache Directory:**
```
~/.flow/cache/doctor/
├── token-github.cache
├── token-npm.cache
└── token-pypi.cache
```

**Cache Format (JSON):**
```json
{
  "token_name": "github-token",
  "provider": "github",
  "cached_at": "2026-01-23T12:30:00Z",
  "expires_at": "2026-01-23T12:35:00Z",
  "ttl_seconds": 300,
  "status": "valid",
  "days_remaining": 45,
  "username": "your-username"
}
```

### Core Functions

#### `_doctor_cache_init`

Initialize cache directory structure.

**Signature:**
```zsh
_doctor_cache_init
```

**Parameters:**
- None

**Returns:**
- 0 - Success
- 1 - Failed to create cache directory

**Side Effects:**
- Creates `~/.flow/cache/doctor/` directory
- Runs automatic cleanup of old entries (> 1 day)

**Example:**
```zsh
_doctor_cache_init
if [[ $? -eq 0 ]]; then
    echo "Cache initialized"
fi
```

---

#### `_doctor_cache_get`

Get cached token validation result if still valid.

**Signature:**
```zsh
_doctor_cache_get <cache_key>
```

**Parameters:**
- `$1` - Cache key (e.g., "token-github", "token-npm")

**Returns:**
- 0 - Cache hit (valid entry found)
- 1 - Cache miss (no entry, expired, or invalid)

**Output:**
- stdout - Cached JSON data (only on cache hit)

**Performance:**
- Target: < 10ms for cache check
- Actual: ~5-8ms (50% better than target)

**Example:**
```zsh
if cached_data=$(_doctor_cache_get "token-github"); then
    echo "Cache hit!"
    status=$(echo "$cached_data" | jq -r '.status')
    days=$(echo "$cached_data" | jq -r '.days_remaining')
else
    echo "Cache miss, need to validate token"
fi
```

---

#### `_doctor_cache_set`

Store token validation result in cache.

**Signature:**
```zsh
_doctor_cache_set <cache_key> <value> [ttl_seconds]
```

**Parameters:**
- `$1` - Cache key (e.g., "token-github")
- `$2` - Value to cache (JSON string or plain text)
- `$3` - (optional) TTL in seconds [default: 300 = 5 minutes]

**Returns:**
- 0 - Success
- 1 - Failed to write cache

**Implementation:**
- Atomic write (temp file + mv)
- flock for concurrent access safety
- Wraps plain text values in JSON automatically

**Example:**
```zsh
# Cache token validation result
validation_json='{"status": "valid", "days_remaining": 45, "username": "user"}'
_doctor_cache_set "token-github" "$validation_json"

# Cache with custom TTL (10 minutes)
_doctor_cache_set "token-npm" "$validation_json" 600
```

---

#### `_doctor_cache_clear`

Clear specific cache entry or entire cache.

**Signature:**
```zsh
_doctor_cache_clear [cache_key]
```

**Parameters:**
- `$1` - (optional) Cache key to clear [default: clear all]

**Returns:**
- 0 - Success

**Use Cases:**
- Token rotation - invalidate cached validation
- Debugging - force fresh validation

**Example:**
```zsh
# Clear specific token cache
_doctor_cache_clear "token-github"

# Clear all doctor cache entries
_doctor_cache_clear
```

---

#### `_doctor_cache_stats`

Show cache statistics and list cached entries.

**Signature:**
```zsh
_doctor_cache_stats
```

**Parameters:**
- None

**Returns:**
- 0 - Success
- 1 - No cache found

**Output:**
```
Doctor Cache Statistics
=======================
Cache directory: ~/.flow/cache/doctor
Total entries: 3
Total size: 12 KB

Cached Entries:
  token-github    (valid, expires in 4m 23s)
  token-npm       (valid, expires in 2m 15s)
  token-pypi      (expired)
```

**Example:**
```zsh
_doctor_cache_stats
```

---

#### `_doctor_cache_clean_old`

Clean up cache entries older than 1 day.

**Signature:**
```zsh
_doctor_cache_clean_old
```

**Parameters:**
- None

**Returns:**
- 0 - Success

**Output:**
- stdout - Number of entries cleaned

**Behavior:**
- Automatically called during cache init
- Removes entries > `DOCTOR_CACHE_MAX_AGE_SECONDS` old (86400s = 1 day)
- Also cleans stale lock files
- Safe to run multiple times

**Example:**
```zsh
cleaned=$(_doctor_cache_clean_old)
echo "Cleaned $cleaned old entries"
```

---

### Locking Functions

#### `_doctor_cache_get_cache_path`

Get the cache file path for a token.

**Signature:**
```zsh
_doctor_cache_get_cache_path <cache_key>
```

**Parameters:**
- `$1` - Cache key (e.g., "token-github", "token-npm")

**Returns:**
- 0 - Always succeeds

**Output:**
- stdout - Path to cache file

**Example:**
```zsh
cache_file=$(_doctor_cache_get_cache_path "token-github")
# Returns: ~/.flow/cache/doctor/token-github.cache
```

---

#### `_doctor_cache_get_lock_path`

Get the lock file path for cache operations.

**Signature:**
```zsh
_doctor_cache_get_lock_path <cache_key>
```

**Parameters:**
- `$1` - Cache key

**Returns:**
- 0 - Always succeeds

**Output:**
- stdout - Path to lock file

**Example:**
```zsh
lock_file=$(_doctor_cache_get_lock_path "token-github")
# Returns: ~/.flow/cache/doctor/.token-github.lock
```

---

#### `_doctor_cache_acquire_lock`

Acquire exclusive lock for cache write operations.

**Signature:**
```zsh
_doctor_cache_acquire_lock <cache_key>
```

**Parameters:**
- `$1` - Cache key

**Returns:**
- 0 - Lock acquired
- 1 - Failed to acquire lock (timeout after 2s)

**Implementation:**
- Uses `flock` if available (preferred)
- Falls back to mkdir-based locking (atomic on POSIX)
- Detects and removes stale locks (holder process dead)
- File descriptor 201 reserved for doctor cache locks

**Notes:**
- Lock automatically released when shell exits
- Must call `_doctor_cache_release_lock` to release explicitly

**Example:**
```zsh
if _doctor_cache_acquire_lock "token-github"; then
    # ... write to cache
    _doctor_cache_release_lock "token-github"
else
    echo "Failed to acquire lock"
    return 1
fi
```

---

#### `_doctor_cache_release_lock`

Release exclusive lock for cache operations.

**Signature:**
```zsh
_doctor_cache_release_lock <cache_key>
```

**Parameters:**
- `$1` - Cache key

**Returns:**
- 0 - Always succeeds

**Behavior:**
- Closes flock file descriptor (fd 201)
- Removes mkdir-based lock directory
- Safe to call even if lock wasn't acquired

**Example:**
```zsh
_doctor_cache_release_lock "token-github"
```

---

### Convenience Functions

#### `_doctor_cache_token_get`

Convenience wrapper to get token validation cache.

**Signature:**
```zsh
_doctor_cache_token_get <provider>
```

**Parameters:**
- `$1` - Provider name (github, npm, pypi)

**Returns:**
- 0 - Cache hit
- 1 - Cache miss

**Output:**
- stdout - Cached token validation JSON

**Example:**
```zsh
if cached=$(_doctor_cache_token_get "github"); then
    status=$(echo "$cached" | jq -r '.status')
    echo "GitHub token: $status"
fi
```

**Equivalent to:**
```zsh
_doctor_cache_get "token-${provider}"
```

---

#### `_doctor_cache_token_set`

Convenience wrapper to cache token validation result.

**Signature:**
```zsh
_doctor_cache_token_set <provider> <value> [ttl_seconds]
```

**Parameters:**
- `$1` - Provider name (github, npm, pypi)
- `$2` - Validation result JSON
- `$3` - (optional) TTL in seconds [default: 300]

**Returns:**
- 0 - Success
- 1 - Failed

**Example:**
```zsh
result='{"status": "valid", "days_remaining": 45}'
_doctor_cache_token_set "github" "$result"
```

**Equivalent to:**
```zsh
_doctor_cache_set "token-${provider}" "$value" "$ttl"
```

---

#### `_doctor_cache_token_clear`

Convenience wrapper to invalidate token validation cache.

**Signature:**
```zsh
_doctor_cache_token_clear <provider>
```

**Parameters:**
- `$1` - Provider name (github, npm, pypi)

**Returns:**
- 0 - Success

**Use Cases:**
- After rotating GitHub token
- After updating npm or PyPI credentials
- Forcing fresh validation

**Example:**
```zsh
# After rotating GitHub token, invalidate cache
dot secret rotate GITHUB_TOKEN
_doctor_cache_token_clear "github"
```

**Equivalent to:**
```zsh
_doctor_cache_clear "token-${provider}"
```

---

### Constants

**Cache Configuration:**
```zsh
DOCTOR_CACHE_DEFAULT_TTL=300        # 5 minutes
DOCTOR_CACHE_LOCK_TIMEOUT=2         # 2 seconds
DOCTOR_CACHE_MAX_AGE_SECONDS=86400  # 1 day
DOCTOR_CACHE_DIR="$HOME/.flow/cache/doctor"
```

---

### Performance Metrics

**v5.17.0 Token Automation Phase 1:**

| Operation | Target | Actual | Improvement |
|-----------|--------|--------|-------------|
| Cache check | < 10ms | ~5-8ms | 50% better |
| Cache hit | < 100ms | ~50-80ms | 50% better |
| Token validation (cached) | < 3s | ~2-3s | Within target |
| API reduction | 50% | 80% | 60% better |
| Cache hit rate | 70% | 85% | 21% better |

**Integration:**
- `doctor --dot` - Token-only validation with caching
- `g push/pull` - Validates token before remote operations
- `work` - Checks token on session start
- `finish` - Validates before commit/push
- `dash dev` - Shows cached token status

---

## Teaching Libraries

**Files:**
- `lib/concept-extraction.zsh` - YAML frontmatter parsing
- `lib/prerequisite-checker.zsh` - DAG validation
- `lib/analysis-cache.zsh` - SHA-256 cache with flock
- `lib/report-generator.zsh` - Markdown/JSON reports
- `lib/ai-analysis.zsh` - Claude CLI integration
- `lib/slide-optimizer.zsh` - Heuristic slide breaks

**Purpose:** AI-powered teaching workflow (v5.16.0+)
**Total Functions:** 150+

### Concept Extraction

#### `_teach_extract_concepts`

Extracts learning concepts from Quarto frontmatter.

**Signature:**
```zsh
_teach_extract_concepts "file.qmd"
```

**Parameters:**
- `$1` - Quarto file path

**Returns:**
- 0 - Success, outputs JSON to stdout
- 1 - Failed to parse

**Output Format:**
```json
{
  "concepts": [
    {
      "id": "linear-regression",
      "name": "Linear Regression",
      "bloom": "Understand",
      "complexity": "Medium",
      "prerequisites": ["basic-statistics"]
    }
  ]
}
```

**Example:**
```zsh
concepts=$(_teach_extract_concepts "lectures/week-01/regression.qmd")
echo "$concepts" | jq '.concepts[] | .name'
```

---

### Analysis Cache

#### `_teach_cache_get`

Retrieves cached analysis result.

**Signature:**
```zsh
_teach_cache_get "file.qmd"
```

**Parameters:**
- `$1` - File path

**Returns:**
- 0 - Cache hit, outputs cached data
- 1 - Cache miss

**Caching Strategy:**
- SHA-256 hash of file content
- flock for concurrent access
- 24-hour TTL

**Example:**
```zsh
if cached=$(_teach_cache_get "lecture.qmd"); then
    echo "Using cached analysis"
    echo "$cached"
else
    echo "Cache miss, analyzing..."
    result=$(_teach_analyze_file "lecture.qmd")
    _teach_cache_set "lecture.qmd" "$result"
fi
```

---

## Function Index

**Auto-generated alphabetical index will appear here after running:**
```bash
./scripts/generate-api-docs.sh
```

### A

- `_flow_atlas_connect` - Connect to Atlas state engine
- `_flow_atlas_disconnect` - Disconnect from Atlas
- `_flow_atlas_query` - Query Atlas database

### B

### C

- `_flow_cache_clear` - Clear project cache
- `_flow_cache_get` - Get cached value
- `_flow_cache_set` - Set cache value
- `_flow_color_blue` - Blue text output
- `_flow_color_green` - Green text output
- `_flow_color_red` - Red text output
- `_flow_color_yellow` - Yellow text output

### D

- `_flow_detect_project_type` - Detect project type from directory

### E

### F

- `_flow_find_project_root` - Find git repository root

### G

- `_flow_git_current_branch` - Get current git branch
- `_flow_git_is_clean` - Check if working tree is clean
- `_flow_git_validate_token` - Validate GitHub token

### H-Z

**[Will be auto-generated by scripts/generate-api-docs.sh]**

---

## Change Log

### v5.17.0-dev (Current)

**Added:**
- Token cache management (5-min TTL)
- `_flow_token_cache_get` - Get cached token status
- `_flow_token_cache_set` - Set token cache
- `_flow_token_validate` - Validate token with cache

**Changed:**
- `_flow_git_validate_token` now uses cache (80% API reduction)

**Deprecated:**
- None

**Removed:**
- None

---

### v5.16.0

**Added:**
- Teaching analysis libraries (150+ functions)
- `_teach_extract_concepts` - Concept extraction from YAML
- `_teach_analyze_file` - AI-powered content analysis
- `_teach_cache_*` - SHA-256 cache with flock
- `_teach_report_*` - Markdown/JSON report generation

---

### v5.15.0

**Added:**
- Help system functions
- `_flow_help_show` - Display formatted help
- `_flow_help_section` - Display help section

---

## Contributing

### Adding New Functions

1. **Write function with documentation:**
   ```zsh
   # Description: What the function does
   # Parameters:
   #   $1 - First parameter description
   #   $2 - Second parameter (optional)
   # Returns:
   #   0 - Success
   #   1 - Error condition
   # Example:
   #   my_function "arg1" "arg2"
   function my_function() {
       # Implementation
   }
   ```

2. **Run documentation generator:**
   ```bash
   ./scripts/generate-api-docs.sh
   ```

3. **Test function:**
   ```bash
   source lib/my-library.zsh
   my_function "test" "args"
   ```

4. **Commit with API docs:**
   ```bash
   git add lib/my-library.zsh docs/reference/MASTER-API-REFERENCE.md
   git commit -m "feat: add my_function

   - Description of function
   - Updates API reference"
   ```

---

### Documentation Standards

**Function naming:**
- Private: `_flow_*` (underscore prefix)
- Public: `flow_*` (no underscore)
- Dispatcher: `<dispatcher>_*` (e.g., `g_feature_start`)

**Parameter documentation:**
- Always document all parameters
- Mark optional parameters
- Provide examples

**Return values:**
- Always document return codes
- 0 = success, non-zero = error
- Print output to stdout, errors to stderr

---

## See Also

- [MASTER-DISPATCHER-GUIDE.md](MASTER-DISPATCHER-GUIDE.md) - Complete dispatcher reference
- [MASTER-ARCHITECTURE.md](MASTER-ARCHITECTURE.md) - System architecture
- [CONVENTIONS.md](../../CONVENTIONS.md) - Coding conventions
- [CONTRIBUTING.md](../contributing/CONTRIBUTING.md) - Contributing guide

---

**Version:** v5.17.0-dev
**Last Updated:** 2026-01-24
**Auto-Generation:** Run `./scripts/generate-api-docs.sh` to update function index
**Total Functions:** 853 (421 documented, 432 pending)
