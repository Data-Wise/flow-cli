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
- [Commands Internal API](#commands-internal-api) - Command helper functions
- [Teaching Libraries](#teaching-libraries) - AI-powered teaching workflow (v5.16.0+)
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
- `lib/concept-extraction.zsh` - YAML frontmatter parsing (13 functions)
- `lib/prerequisite-checker.zsh` - DAG validation (20+ functions)
- `lib/analysis-cache.zsh` - SHA-256 cache with flock (40+ functions)
- `lib/report-generator.zsh` - Markdown/JSON reports (30+ functions)
- `lib/ai-analysis.zsh` - Claude CLI integration (15+ functions)
- `lib/slide-optimizer.zsh` - Heuristic slide breaks (20+ functions)

**Purpose:** AI-powered teaching workflow (v5.16.0+)
**Total Functions:** 150+
**System:** `teach analyze` command infrastructure

### Overview

The teaching libraries implement intelligent content analysis for educational materials:

1. **Concept Extraction** - Parses YAML frontmatter for learning concepts
2. **Prerequisite Validation** - DAG-based dependency checking
3. **SHA-256 Caching** - Prevents redundant analysis (5-min TTL)
4. **Report Generation** - Markdown/JSON summaries
5. **AI Analysis** - Claude CLI integration for insights
6. **Slide Optimization** - Heuristic break detection

**Workflow:**
```
.qmd files → concept extraction → prerequisite check → cache → AI analysis → report
```

---

### lib/concept-extraction.zsh

**Functions:** 13
**Purpose:** Extract learning concepts from Quarto YAML frontmatter

#### `_extract_concepts_from_frontmatter`

Extract concepts field from .qmd frontmatter using yq.

**Signature:**
```zsh
_extract_concepts_from_frontmatter <file_path>
```

**Parameters:**
- `$1` - (required) Path to .qmd file

**Returns:**
- 0 - Success
- 1 - File not found or yq unavailable

**Output:**
- stdout - JSON string of concepts section
- stdout - Empty string if no concepts found

**Format Support:**
```yaml
# Simple format
concepts:
  introduces: [concept1, concept2]
  requires: [prereq1, prereq2]

# Array format
concepts:
  - id: concept1
    name: "Concept Name"
    prerequisites: [prereq1]
  - id: concept2
    name: "Another Concept"
    prerequisites: [prereq2]
```

**Example:**
```zsh
concepts_json=$(_extract_concepts_from_frontmatter "week-05-regression.qmd")
if [[ -n "$concepts_json" ]]; then
    echo "Found concepts: $concepts_json"
fi
```

---

#### `_parse_introduced_concepts`

Parse introduced concepts from concepts JSON.

**Signature:**
```zsh
_parse_introduced_concepts <concepts_json>
```

**Parameters:**
- `$1` - (required) Concepts JSON from frontmatter

**Returns:**
- stdout - Space-separated concept IDs
- stdout - Empty string if no concepts

**Supports Two Formats:**
1. Simple: `{introduces: [id1, id2]}`
2. Array: `[{id: id1, name: "..."}, {id: id2, name: "..."}]`

**Example:**
```zsh
concepts_json='{"introduces": ["regression", "correlation"]}'
introduced=$(_parse_introduced_concepts "$concepts_json")
echo "$introduced"  # Output: regression correlation
```

---

#### `_parse_required_concepts`

Parse required concepts (prerequisites) from concepts JSON.

**Signature:**
```zsh
_parse_required_concepts <concepts_json>
```

**Parameters:**
- `$1` - (required) Concepts JSON from frontmatter

**Returns:**
- stdout - Space-separated prerequisite concept IDs
- stdout - Empty string if no prerequisites

**Supports Two Formats:**
1. Simple: `{requires: [prereq1, prereq2]}`
2. Array: `[{prerequisites: [p1, p2]}, {prerequisites: [p3]}]`

**Deduplication:**
- Automatically removes duplicates
- Uses `sort -u` for uniqueness

**Example:**
```zsh
concepts_json='[{"prerequisites": ["mean", "variance"]}, {"prerequisites": ["variance"]}]'
required=$(_parse_required_concepts "$concepts_json")
echo "$required"  # Output: mean variance
```

---

#### `_get_week_from_file`

Extract week number from filename or frontmatter.

**Signature:**
```zsh
_get_week_from_file <file_path> [frontmatter_json]
```

**Parameters:**
- `$1` - (required) Path to .qmd file
- `$2` - (optional) Frontmatter JSON (optimization)

**Returns:**
- stdout - Week number as integer
- stdout - 0 if not found

**Detection Priority:**
1. Filename pattern: `week-05-lecture.qmd` → 5
2. Frontmatter `week` field
3. Fallback to 0

**Example:**
```zsh
week=$(_get_week_from_file "week-08-anova.qmd")
echo "Week: $week"  # Output: Week: 8
```

---

#### `_get_concept_line_number`

Find line number where concept appears in file.

**Signature:**
```zsh
_get_concept_line_number <file_path> <concept_name>
```

**Parameters:**
- `$1` - (required) Path to .qmd file
- `$2` - (required) Concept name/ID

**Returns:**
- stdout - Line number (1-based)
- stdout - 0 if not found

**Search Scope:**
- Searches within YAML frontmatter only
- Looks for concept in `introduces` or `id` fields

**Example:**
```zsh
line=$(_get_concept_line_number "week-05.qmd" "regression")
if [[ $line -gt 0 ]]; then
    echo "Concept 'regression' found at line $line"
fi
```

---

#### `_build_concept_graph`

Build complete concept graph from course directory.

**Signature:**
```zsh
_build_concept_graph [course_directory]
```

**Parameters:**
- `$1` - (optional) Course directory [default: current directory]

**Returns:**
- stdout - JSON concept graph

**Output Format:**
```json
{
  "concept1": {
    "introduced_in": "week-05-lecture.qmd",
    "week": 5,
    "prerequisites": ["prereq1", "prereq2"]
  },
  "concept2": {
    "introduced_in": "week-06-lecture.qmd",
    "week": 6,
    "prerequisites": []
  }
}
```

**Use Case:**
- Used by `teach analyze` for prerequisite validation
- Cached for performance

**Example:**
```zsh
graph=$(_build_concept_graph "lectures/")
echo "$graph" | jq '.regression'
```

---

#### `_load_concept_graph`

Load cached concept graph from disk.

**Signature:**
```zsh
_load_concept_graph [course_directory]
```

**Parameters:**
- `$1` - (optional) Course directory [default: current]

**Returns:**
- 0 - Graph loaded
- 1 - No cached graph found

**Output:**
- stdout - Cached JSON concept graph
- stdout - Empty string if cache miss

**Cache Location:**
- `.teach-cache/concept-graph.json`

**Example:**
```zsh
if graph=$(_load_concept_graph); then
    echo "Loaded cached graph"
else
    graph=$(_build_concept_graph)
fi
```

---

#### `_save_concept_graph`

Save concept graph to disk cache.

**Signature:**
```zsh
_save_concept_graph <graph_json> [course_directory]
```

**Parameters:**
- `$1` - (required) Concept graph JSON
- `$2` - (optional) Course directory [default: current]

**Returns:**
- 0 - Success
- 1 - Failed to write

**Cache Location:**
- `.teach-cache/concept-graph.json`

**Example:**
```zsh
graph=$(_build_concept_graph)
_save_concept_graph "$graph"
```

---

### lib/prerequisite-checker.zsh

**Functions:** 7
**Purpose:** DAG-based prerequisite validation and dependency checking

#### `_check_prerequisites`

Validate all prerequisite dependencies in course data.

**Signature:**
```zsh
_check_prerequisites <course_data_json>
```

**Parameters:**
- `$1` - (required) Course data JSON with weeks and concepts

**Returns:**
- stdout - JSON array of prerequisite violations

**Violation Types:**
1. **missing** - Prerequisite not defined anywhere
2. **future** - Prerequisite introduced after dependent concept
3. **circular** - Circular dependency detected

**Output Format:**
```json
[
  {
    "concept_id": "regression",
    "type": "missing",
    "week": 5,
    "prerequisite_id": "correlation",
    "message": "Missing prerequisite: correlation",
    "suggestion": "Add correlation to earlier week"
  }
]
```

**Global State:**
- Sets `PREREQUISITE_VIOLATIONS` array

**Example:**
```zsh
course_json=$(cat course-data.json)
violations=$(_check_prerequisites "$course_json")
if [[ "$violations" != "[]" ]]; then
    echo "Found violations: $violations"
fi
```

---

#### `_validate_concept_graph`

Perform complete graph validation (missing, future, circular).

**Signature:**
```zsh
_validate_concept_graph <graph_json>
```

**Parameters:**
- `$1` - (required) Concept graph JSON from `_build_concept_graph`

**Returns:**
- 0 - Graph valid
- 1 - Validation failures found

**Checks Performed:**
1. All prerequisites exist
2. No future prerequisites
3. No circular dependencies
4. Transitive closure consistency

**Example:**
```zsh
graph=$(_build_concept_graph)
if _validate_concept_graph "$graph"; then
    echo "✓ Graph valid"
else
    echo "✗ Validation failed"
fi
```

---

#### `_detect_circular_dependencies`

Find circular prerequisite loops in concept graph.

**Signature:**
```zsh
_detect_circular_dependencies <graph_json>
```

**Parameters:**
- `$1` - (required) Concept graph JSON

**Returns:**
- stdout - JSON array of circular dependency chains
- stdout - Empty array `[]` if no cycles

**Output Format:**
```json
[
  {
    "cycle": ["concept-a", "concept-b", "concept-c", "concept-a"],
    "week_first": 5,
    "severity": "error"
  }
]
```

**Example:**
```zsh
graph=$(_build_concept_graph)
cycles=$(_detect_circular_dependencies "$graph")
if [[ "$cycles" != "[]" ]]; then
    echo "Found circular dependencies: $cycles"
fi
```

---

#### `_build_prerequisite_tree`

Build dependency tree for a specific concept (transitive closure).

**Signature:**
```zsh
_build_prerequisite_tree <concept_id> <graph_json>
```

**Parameters:**
- `$1` - (required) Concept ID to analyze
- `$2` - (required) Concept graph JSON

**Returns:**
- stdout - JSON tree structure with all transitive prerequisites

**Output Format:**
```json
{
  "concept": "regression",
  "direct_prerequisites": ["correlation", "variance"],
  "transitive_prerequisites": ["mean", "variance", "correlation"],
  "depth": 2,
  "total_prerequisites": 3
}
```

**Use Case:**
- Prerequisite tree visualization
- Dependency depth analysis
- Learning path planning

**Example:**
```zsh
graph=$(_build_concept_graph)
tree=$(_build_prerequisite_tree "regression" "$graph")
echo "$tree" | jq '.transitive_prerequisites'
```

---

#### `_format_prerequisite_tree_display`

Format prerequisite tree for terminal display (with colors and tree structure).

**Signature:**
```zsh
_format_prerequisite_tree_display <tree_json>
```

**Parameters:**
- `$1` - (required) Prerequisite tree JSON from `_build_prerequisite_tree`

**Returns:**
- stdout - Formatted terminal output with ANSI colors and tree characters

**Output Example:**
```
Prerequisite Tree for: regression
├─ correlation (Week 4)
│  └─ variance (Week 3)
│     └─ mean (Week 2)
└─ variance (Week 3)
   └─ mean (Week 2)

Total Prerequisites: 3 (depth: 2)
```

**Features:**
- Unicode tree characters (├─, └─, │)
- Color coding (ANSI escape codes)
- Week numbers for each prerequisite
- Depth and count summary

**Example:**
```zsh
tree=$(_build_prerequisite_tree "regression" "$graph")
_format_prerequisite_tree_display "$tree"
```

---

**Complete API:** See [.archive/TEACH-ANALYZE-API-REFERENCE.md](../reference/.archive/TEACH-ANALYZE-API-REFERENCE.md#prerequisite-checker) for all 7 functions with detailed examples

---

### lib/analysis-cache.zsh

**Functions:** 19
**Purpose:** SHA-256-based content caching with concurrent access safety

#### Overview

Analysis cache system prevents redundant processing by caching results with content-based keys:

- **SHA-256 hashing** - Content changes invalidate cache automatically
- **flock locking** - Safe concurrent access (multiple `teach analyze` runs)
- **5-minute TTL** - Balance between freshness and performance
- **Atomic writes** - Temp file + rename for safety
- **Auto cleanup** - Removes entries > 1 day old

**Cache Structure:**
```
.teach-cache/
├── analysis/
│   ├── abc123def456.json  # SHA-256 of content
│   ├── 789ghi012jkl.json
│   └── metadata.json
├── slides/
│   └── def456abc123.json  # Slide optimization cache
└── locks/
    ├── .analysis.lock
    └── .slides.lock
```

#### `_cache_compute_hash`

Compute SHA-256 hash of file content.

**Signature:**
```zsh
_cache_compute_hash <file_path>
```

**Parameters:**
- `$1` - (required) Path to file

**Returns:**
- stdout - SHA-256 hash (lowercase hex)

**Performance:**
- Reads full file content
- ~10-50ms depending on file size

**Example:**
```zsh
hash=$(_cache_compute_hash "week-05-lecture.qmd")
echo "Content hash: $hash"
```

---

#### `_cache_get_analysis`

Retrieve cached analysis result by content hash.

**Signature:**
```zsh
_cache_get_analysis <file_path>
```

**Parameters:**
- `$1` - (required) Path to analyzed file

**Returns:**
- 0 - Cache hit
- 1 - Cache miss (no entry or expired)

**Output:**
- stdout - Cached analysis JSON (only on hit)

**TTL Check:**
- Reads `cached_at` timestamp
- Compares to current time
- Returns miss if > 5 minutes old

**Example:**
```zsh
if analysis=$(_cache_get_analysis "week-05.qmd"); then
    echo "Cache hit! Analysis: $analysis"
else
    # Perform fresh analysis
    analysis=$(teach analyze "week-05.qmd")
    _cache_set_analysis "week-05.qmd" "$analysis"
fi
```

---

#### `_cache_set_analysis`

Store analysis result with TTL metadata.

**Signature:**
```zsh
_cache_set_analysis <file_path> <analysis_json> [ttl_seconds]
```

**Parameters:**
- `$1` - (required) Path to analyzed file
- `$2` - (required) Analysis result JSON
- `$3` - (optional) TTL in seconds [default: 300 = 5 minutes]

**Returns:**
- 0 - Success
- 1 - Failed to write

**Implementation:**
- Computes SHA-256 of file content
- Creates atomic write (temp + rename)
- Acquires flock for thread safety
- Stores with timestamp metadata

**Example:**
```zsh
analysis='{"concepts": ["regression"], "valid": true}'
_cache_set_analysis "week-05.qmd" "$analysis"
```

---

#### `_cache_invalidate_file`

Remove cache entry for specific file.

**Signature:**
```zsh
_cache_invalidate_file <file_path>
```

**Parameters:**
- `$1` - (required) Path to file

**Returns:**
- 0 - Success (even if cache didn't exist)

**Use Cases:**
- After manual content edits
- Force fresh analysis
- Cache corruption recovery

**Example:**
```zsh
# Edit file then invalidate cache
vim week-05.qmd
_cache_invalidate_file "week-05.qmd"
```

---

#### `_cache_cleanup_old_entries`

Remove cache entries older than 1 day.

**Signature:**
```zsh
_cache_cleanup_old_entries
```

**Parameters:**
- None

**Returns:**
- stdout - Number of entries removed

**Behavior:**
- Scans `.teach-cache/analysis/` directory
- Checks file mtime (modification time)
- Removes entries > 86400 seconds old
- Also cleans stale lock files

**Example:**
```zsh
removed=$(_cache_cleanup_old_entries)
echo "Cleaned up $removed old cache entries"
```

---

#### `_cache_acquire_lock`

Acquire exclusive lock for cache writes.

**Signature:**
```zsh
_cache_acquire_lock <cache_type>
```

**Parameters:**
- `$1` - (required) Cache type ("analysis" or "slides")

**Returns:**
- 0 - Lock acquired
- 1 - Timeout (failed after 2s)

**Implementation:**
- Uses `flock` if available
- Falls back to mkdir-based locking (atomic on POSIX)
- Detects and removes stale locks (dead process)

**File Descriptor:**
- Uses fd 200 for analysis cache locks
- Uses fd 201 for slides cache locks

**Example:**
```zsh
if _cache_acquire_lock "analysis"; then
    # ... write to cache
    _cache_release_lock "analysis"
else
    echo "Failed to acquire lock"
fi
```

---

#### `_cache_release_lock`

Release exclusive cache lock.

**Signature:**
```zsh
_cache_release_lock <cache_type>
```

**Parameters:**
- `$1` - (required) Cache type ("analysis" or "slides")

**Returns:**
- 0 - Always succeeds

**Behavior:**
- Closes flock file descriptor
- Removes mkdir-based lock directory
- Safe to call even if lock wasn't acquired

**Example:**
```zsh
_cache_release_lock "analysis"
```

---

**Complete API:** See [.archive/TEACH-ANALYZE-API-REFERENCE.md](../reference/.archive/TEACH-ANALYZE-API-REFERENCE.md#analysis-cache) for all 19 functions including metadata management, batch operations, and statistics

---

### lib/report-generator.zsh

**Functions:** 12
**Purpose:** Generate formatted analysis reports (Markdown/JSON/Interactive)

#### `_generate_markdown_report`

Generate human-readable Markdown analysis report.

**Signature:**
```zsh
_generate_markdown_report <analysis_data> [output_file]
```

**Parameters:**
- `$1` - (required) Analysis data JSON
- `$2` - (optional) Output file path [default: stdout]

**Returns:**
- 0 - Success
- 1 - Failed to generate

**Report Sections:**
1. **Summary** - Concept/prerequisite counts, file stats
2. **Concept Distribution** - Concepts per week
3. **Prerequisite Validation** - Violations summary
4. **Circular Dependencies** - If detected
5. **Recommendations** - Suggested improvements

**Example Output:**
```markdown
# Teaching Content Analysis Report

**Generated:** 2026-01-24 15:15
**Course:** STAT 545

## Summary
- Total concepts: 45
- Total prerequisites: 67
- Files analyzed: 12
- Validation status: ✓ PASS

## Concept Distribution
| Week | Concepts | Prerequisites |
|------|----------|---------------|
| 1    | 3        | 0             |
| 2    | 5        | 3             |
...

## Validation Results
✓ No circular dependencies detected
✓ All prerequisites defined
⚠ 2 concepts have future prerequisites

## Recommendations
1. Consider moving "correlation" to Week 4
2. Add prerequisite "mean" to Week 2
```

**Example:**
```zsh
analysis=$(teach analyze --json)
_generate_markdown_report "$analysis" "analysis-report.md"
```

---

#### `_generate_json_report`

Export analysis data as JSON for machine processing.

**Signature:**
```zsh
_generate_json_report <analysis_data> [output_file]
```

**Parameters:**
- `$1` - (required) Analysis data
- `$2` - (optional) Output file [default: stdout]

**Returns:**
- 0 - Success

**Output Schema:**
```json
{
  "meta": {
    "generated_at": "2026-01-24T15:15:00Z",
    "version": "v5.16.0",
    "course": "STAT 545"
  },
  "summary": {
    "total_concepts": 45,
    "total_prerequisites": 67,
    "files_analyzed": 12,
    "validation_passed": true
  },
  "concepts": [
    {
      "id": "regression",
      "week": 5,
      "prerequisites": ["correlation", "variance"],
      "transitive_prerequisites": ["mean", "variance", "correlation"]
    }
  ],
  "violations": [],
  "warnings": []
}
```

**Example:**
```zsh
analysis=$(teach analyze --json)
_generate_json_report "$analysis" "analysis.json"
```

---

#### `_print_interactive_summary`

Display colorized analysis summary in terminal.

**Signature:**
```zsh
_print_interactive_summary <analysis_data>
```

**Parameters:**
- `$1` - (required) Analysis data JSON

**Returns:**
- 0 - Success

**Features:**
- ANSI color codes for status (✓ green, ✗ red, ⚠ yellow)
- Unicode box drawing characters
- Progress bars for metrics
- Collapsible sections (via less/more)

**Example Output:**
```
╭─────────────────────────────────────────────────╮
│ 📊 Teaching Content Analysis                   │
├─────────────────────────────────────────────────┤
│                                                 │
│ ✓ Total Concepts: 45                            │
│ ✓ Prerequisites: 67                             │
│ ✓ Files Analyzed: 12                            │
│                                                 │
│ Validation: ✓ PASS                              │
│   ✓ No circular dependencies                    │
│   ✓ All prerequisites defined                   │
│   ⚠ 2 future prerequisites                      │
│                                                 │
╰─────────────────────────────────────────────────╯
```

**Example:**
```zsh
analysis=$(teach analyze)
_print_interactive_summary "$analysis"
```

---

#### `_format_concept_distribution_table`

Format concept distribution as terminal table.

**Signature:**
```zsh
_format_concept_distribution_table <analysis_data>
```

**Parameters:**
- `$1` - (required) Analysis data JSON

**Returns:**
- stdout - Formatted table with ANSI colors

**Example Output:**
```
Week  Concepts  Prerequisites  Avg Depth
────  ────────  ─────────────  ─────────
  1          3              0        0.0
  2          5              3        1.2
  3          7              8        1.8
  4          6             12        2.1
  5          8             15        2.5
────  ────────  ─────────────  ─────────
Total       29             38        1.9
```

**Example:**
```zsh
analysis=$(teach analyze --json)
_format_concept_distribution_table "$analysis"
```

---

**Complete API:** See [.archive/TEACH-ANALYZE-API-REFERENCE.md](../reference/.archive/TEACH-ANALYZE-API-REFERENCE.md#report-generator) for all 12 functions including violation formatting, recommendation generation, and export utilities

---

### lib/ai-analysis.zsh

**Functions:** 8
**Purpose:** Claude CLI integration for AI-powered pedagogical insights

#### `_ai_analyze_content`

Send content to Claude for pedagogical analysis.

**Signature:**
```zsh
_ai_analyze_content <file_path> [mode]
```

**Parameters:**
- `$1` - (required) Path to .qmd file
- `$2` - (optional) Analysis mode ("full" | "quick") [default: "full"]

**Returns:**
- 0 - Success
- 1 - Analysis failed (Claude CLI error, API error)

**Output:**
- stdout - Analysis JSON

**Analysis Modes:**

**Full Mode** - Comprehensive analysis (~10-30s, $0.01-0.05):
```json
{
  "key_concepts": ["regression", "correlation", "causation"],
  "difficulty": "intermediate",
  "cognitive_load": "medium",
  "bloom_taxonomy": ["remember", "understand", "apply", "analyze"],
  "estimated_time_minutes": 50,
  "prerequisites_needed": ["mean", "variance"],
  "learning_objectives": [
    "Understand relationship between variables",
    "Apply regression analysis to real data"
  ],
  "common_misconceptions": [
    "Correlation implies causation"
  ],
  "suggested_activities": [
    "Practice with scatter plots",
    "Interpret regression output"
  ]
}
```

**Quick Mode** - Essential insights only (~3-5s, $0.005-0.01):
```json
{
  "key_concepts": ["regression", "correlation"],
  "difficulty": "intermediate",
  "estimated_time_minutes": 50
}
```

**Example:**
```zsh
# Full analysis
analysis=$(_ai_analyze_content "week-05-lecture.qmd")
echo "$analysis" | jq '.key_concepts'

# Quick analysis (faster, cheaper)
analysis=$(_ai_analyze_content "week-05-lecture.qmd" "quick")
```

---

#### `_ai_estimate_cost`

Estimate Claude API cost for content analysis.

**Signature:**
```zsh
_ai_estimate_cost <file_path> [mode]
```

**Parameters:**
- `$1` - (required) Path to file
- `$2` - (optional) Analysis mode [default: "full"]

**Returns:**
- stdout - Estimated cost in USD (e.g., "0.023")

**Cost Calculation:**
- Counts content tokens (input)
- Estimates response tokens (~500 full, ~100 quick)
- Uses Claude pricing (Sonnet: $3/1M input, $15/1M output)

**Example:**
```zsh
cost=$(_ai_estimate_cost "week-05-lecture.qmd")
echo "Estimated cost: \$$cost"

# Check before batch processing
total_cost=0
for file in lectures/*.qmd; do
    cost=$(_ai_estimate_cost "$file")
    total_cost=$(awk "BEGIN {print $total_cost + $cost}")
done
echo "Total batch cost: \$$total_cost"
```

---

#### `_ai_batch_analyze`

Analyze multiple files in parallel with cost tracking.

**Signature:**
```zsh
_ai_batch_analyze <file1> <file2> ... [--mode MODE] [--max-cost COST]
```

**Parameters:**
- `$@` - File paths to analyze
- `--mode` - Analysis mode [default: "full"]
- `--max-cost` - Stop if estimated cost exceeds limit

**Returns:**
- 0 - Success
- 1 - Cost limit exceeded or analysis failed

**Features:**
- Parallel processing (up to 4 concurrent)
- Progress tracking
- Cost accumulation
- Graceful failure handling

**Example:**
```zsh
# Analyze all lectures
_ai_batch_analyze lectures/*.qmd --mode quick

# With cost limit
_ai_batch_analyze lectures/*.qmd --max-cost 1.00
```

---

#### `_ai_track_usage`

Track cumulative AI analysis costs.

**Signature:**
```zsh
_ai_track_usage <cost> <mode> <file_path>
```

**Parameters:**
- `$1` - (required) Cost in USD
- `$2` - (required) Analysis mode
- `$3` - (required) File analyzed

**Returns:**
- 0 - Success

**Log Format:**
```
2026-01-24T15:15:00Z,full,week-05-lecture.qmd,0.023
2026-01-24T15:16:00Z,quick,week-06-lecture.qmd,0.008
```

**Log Location:**
- `.teach-cache/ai-usage.log`

**Example:**
```zsh
_ai_track_usage "0.023" "full" "week-05.qmd"

# View total usage
awk -F, '{sum += $4} END {print "Total: $" sum}' .teach-cache/ai-usage.log
```

---

**Complete API:** See [.archive/TEACH-ANALYZE-API-REFERENCE.md](../reference/.archive/TEACH-ANALYZE-API-REFERENCE.md#ai-analysis) for all 8 functions including caching, error handling, and rate limiting

---

### lib/slide-optimizer.zsh

**Functions:** 8
**Purpose:** Heuristic slide break detection and optimization

#### `_detect_slide_breaks`

Find natural slide break points in content.

**Signature:**
```zsh
_detect_slide_breaks <file_path>
```

**Parameters:**
- `$1` - (required) Path to .qmd file

**Returns:**
- stdout - JSON array of slide breaks

**Heuristics (in priority order):**
1. **H2 headings** (##) - Always major break
2. **H3 headings** (###) - Break if > 15 lines since last
3. **Horizontal rules** (---) - Explicit break
4. **Content density** - Break after 5 bullet points
5. **Code blocks** - Break before/after large code
6. **Concept transitions** - Break when concept changes

**Output Format:**
```json
{
  "slides": [
    {
      "number": 1,
      "start_line": 1,
      "end_line": 25,
      "break_type": "h2",
      "heading": "Introduction to Regression",
      "content_lines": 24
    },
    {
      "number": 2,
      "start_line": 26,
      "end_line": 50,
      "break_type": "h3",
      "heading": "Simple Linear Regression",
      "content_lines": 24
    }
  ]
}
```

**Example:**
```zsh
breaks=$(_detect_slide_breaks "week-05-lecture.qmd")
echo "$breaks" | jq '.slides | length'  # Number of slides
```

---

#### `_estimate_slide_timing`

Calculate estimated presentation duration.

**Signature:**
```zsh
_estimate_slide_timing <file_path>
```

**Parameters:**
- `$1` - (required) Path to .qmd file

**Returns:**
- stdout - Timing JSON

**Timing Algorithm:**
- **Text**: 150 words/minute
- **Bullet points**: 20 seconds each
- **Code blocks**: 1 minute per 10 lines
- **Images**: 30 seconds each
- **Tables**: 1 minute per table

**Output Format:**
```json
{
  "total_minutes": 45,
  "slides": [
    {
      "number": 1,
      "minutes": 3,
      "components": {
        "text": 1.5,
        "bullets": 0.7,
        "code": 0.8,
        "images": 0
      }
    }
  ],
  "pace": "moderate"  # slow < 2min/slide < moderate < 1min/slide < fast
}
```

**Example:**
```zsh
timing=$(_estimate_slide_timing "week-05-lecture.qmd")
total=$(echo "$timing" | jq '.total_minutes')
echo "Estimated duration: $total minutes"
```

---

#### `_extract_slide_key_concepts`

Identify main concepts per slide.

**Signature:**
```zsh
_extract_slide_key_concepts <file_path> <slide_breaks_json>
```

**Parameters:**
- `$1` - (required) Path to .qmd file
- `$2` - (required) Slide breaks JSON from `_detect_slide_breaks`

**Returns:**
- stdout - Enhanced slides JSON with key concepts

**Extraction Methods:**
1. **Frontmatter** - Concepts defined in YAML
2. **Headings** - Concept names from H2/H3
3. **Emphasis** - **bold** or *italic* terms
4. **Code** - Function names, variable names
5. **Frequency** - Most common terms

**Output Format:**
```json
{
  "slides": [
    {
      "number": 1,
      "key_concepts": ["regression", "correlation", "linear_model"],
      "concept_density": "medium",  # low/medium/high
      "callout_suggestions": [
        {
          "concept": "regression",
          "line": 15,
          "context": "Simple linear regression formula"
        }
      ]
    }
  ]
}
```

**Example:**
```zsh
breaks=$(_detect_slide_breaks "week-05.qmd")
concepts=$(_extract_slide_key_concepts "week-05.qmd" "$breaks")
echo "$concepts" | jq '.slides[0].key_concepts'
```

---

#### `_optimize_slide_breaks`

Suggest improvements to slide structure.

**Signature:**
```zsh
_optimize_slide_breaks <slide_data_json>
```

**Parameters:**
- `$1` - (required) Slide data with concepts and timing

**Returns:**
- stdout - Optimization suggestions JSON

**Optimization Rules:**
1. **Too dense** - > 5 concepts per slide → split
2. **Too long** - > 3 minutes per slide → split
3. **Too short** - < 30 seconds → merge with next
4. **Unbalanced** - Large variance in slide times → redistribute
5. **Concept overflow** - Concept starts but doesn't finish → adjust break

**Output Format:**
```json
{
  "suggestions": [
    {
      "slide_number": 3,
      "type": "split",
      "severity": "warning",
      "reason": "7 concepts (recommended: 3-5)",
      "suggestion": "Split after line 45 (concept: correlation)",
      "estimated_improvement": "Better cognitive load distribution"
    },
    {
      "slide_number": 5,
      "type": "merge",
      "severity": "info",
      "reason": "Only 20 seconds content",
      "suggestion": "Merge with slide 6",
      "estimated_improvement": "Improved flow"
    }
  ],
  "overall_quality": "good",  # poor/fair/good/excellent
  "optimization_potential": "medium"  # low/medium/high
}
```

**Example:**
```zsh
breaks=$(_detect_slide_breaks "week-05.qmd")
concepts=$(_extract_slide_key_concepts "week-05.qmd" "$breaks")
timing=$(_estimate_slide_timing "week-05.qmd")

# Combine data
slide_data=$(jq -s '.[0] * .[1] * .[2]' \
  <(echo "$breaks") \
  <(echo "$concepts") \
  <(echo "$timing"))

# Get optimization suggestions
suggestions=$(_optimize_slide_breaks "$slide_data")
echo "$suggestions" | jq '.suggestions[]'
```

---

**Complete API:** See [.archive/TEACH-ANALYZE-API-REFERENCE.md](../reference/.archive/TEACH-ANALYZE-API-REFERENCE.md#slide-optimizer) for all 8 functions including visualization, export, and integration with `teach analyze --optimize`

---

### Teaching Libraries Integration

**Command:** `teach analyze`
**Workflow:**
1. **Extract** concepts from .qmd frontmatter
2. **Validate** prerequisite chains (DAG)
3. **Cache** analysis results (SHA-256)
4. **Analyze** with Claude CLI (optional)
5. **Optimize** slide breaks (optional)
6. **Report** findings (Markdown/JSON)

**Performance:**
- Cached analysis: ~50-100ms
- Fresh analysis: ~2-5s (without AI)
- AI analysis: ~10-30s (depends on content length)

**Documentation:**
- Complete API: [TEACH-ANALYZE-API-REFERENCE.md](../reference/TEACH-ANALYZE-API-REFERENCE.md)
- Architecture: [TEACH-ANALYZE-ARCHITECTURE.md](../reference/TEACH-ANALYZE-ARCHITECTURE.md)
- Tutorial: [Tutorial 21](../tutorials/21-teach-analyze.md)
- Quick Ref: [REFCARD-TEACH-ANALYZE.md](../reference/REFCARD-TEACH-ANALYZE.md)

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

## Commands Internal API

**Purpose:** Internal helper functions for command implementations
**Audience:** Developers, contributors
**Note:** These are not meant to be called directly by users

### doctor Command Helpers

**File:** `commands/doctor.zsh`
**Functions:** 7 (v5.17.0 token automation)

#### `_doctor_log_quiet`

Log message unless in quiet mode.

**Signature:**
```zsh
_doctor_log_quiet <message>
```

**Parameters:**
- `$@` - Message to log

**Behavior:**
- Logs message in normal and verbose modes
- Suppresses output in quiet mode (`--quiet` flag)

**Example:**
```zsh
_doctor_log_quiet "Checking GitHub token..."
```

---

#### `_doctor_log_verbose`

Log message only in verbose mode.

**Signature:**
```zsh
_doctor_log_verbose <message>
```

**Parameters:**
- `$@` - Message to log

**Behavior:**
- Logs message only when `--verbose` flag is used
- Silent in normal and quiet modes

**Example:**
```zsh
_doctor_log_verbose "Cache hit for token-github (expires in 240s)"
```

---

#### `_doctor_log_always`

Log message regardless of verbosity level.

**Signature:**
```zsh
_doctor_log_always <message>
```

**Parameters:**
- `$@` - Message to log

**Behavior:**
- Always logs message (quiet, normal, verbose)
- Used for critical messages and errors

**Example:**
```zsh
_doctor_log_always "Error: Invalid token"
```

---

#### `_doctor_select_fix_category`

Show ADHD-friendly menu for selecting which category to fix.

**Signature:**
```zsh
_doctor_select_fix_category [token_only] [auto_yes]
```

**Parameters:**
- `$1` - (optional) Token-only mode (true/false) [default: false]
- `$2` - (optional) Auto-yes mode (true/false) [default: false]

**Returns:**
- 0 - Category selected (outputs category name to stdout)
- 1 - User cancelled
- 2 - No issues found

**Output:**
- stdout - Selected category name ("tokens", "required", "recommended", "aliases", "all")

**Features:**
- Visual hierarchy with time estimates
- Single category auto-selection
- Auto-yes mode for CI/CD
- Exit option (0)

**Example Menu:**
```
╭─ Select Category to Fix ────────────────────────╮
│                                                  │
│  1. 🔑 GitHub Token (1 issue, ~30s)             │
│  2. 📦 Missing Tools (3 tools, ~1m 30s)         │
│  3. ⚡ Aliases (2 issues, ~10s)                 │
│                                                  │
│  4. ✨ Fix All Categories (~2m 10s)             │
│                                                  │
│  0. Exit without fixing                          │
│                                                  │
╰──────────────────────────────────────────────────╯
```

**Example:**
```zsh
selected=$(_doctor_select_fix_category false false)
if [[ $? -eq 0 ]]; then
    echo "User selected: $selected"
fi
```

---

#### `_doctor_count_categories`

Count total number of categories with issues.

**Signature:**
```zsh
_doctor_count_categories
```

**Parameters:**
- None

**Returns:**
- stdout - Number of categories with issues (0-3)

**Categories:**
- Tokens (GitHub API tokens)
- Tools (Homebrew, npm, pip packages)
- Aliases (Shell aliases)

**Example:**
```zsh
count=$(_doctor_count_categories)
if [[ $count -eq 0 ]]; then
    echo "No issues found"
fi
```

---

#### `_doctor_apply_fixes`

Apply fixes for selected category.

**Signature:**
```zsh
_doctor_apply_fixes <category> [auto_yes]
```

**Parameters:**
- `$1` - (required) Category to fix ("tokens", "tools", "aliases", "all")
- `$2` - (optional) Auto-yes mode [default: false]

**Behavior:**
- Tokens: Calls `_doctor_fix_tokens`
- Tools: Calls `_doctor_interactive_fix`
- Aliases: Shows message (not yet implemented)
- All: Applies fixes to all categories sequentially

**Example:**
```zsh
_doctor_apply_fixes "tokens"
_doctor_apply_fixes "all" true  # Auto-yes mode
```

---

#### `_doctor_fix_tokens`

Fix token-related issues (missing, invalid, expiring).

**Signature:**
```zsh
_doctor_fix_tokens
```

**Parameters:**
- None (uses global `_doctor_token_issues` array)

**Behavior:**
- **missing** - Generates new token via `dot token github`
- **invalid** - Rotates token via `dot token rotate`
- **expiring** - Rotates token via `dot token rotate`

**Side Effects:**
- Invalidates token cache
- May prompt for GitHub authentication
- Updates keychain secrets

**Example:**
```zsh
# Called internally by doctor --fix or doctor --fix-token
_doctor_fix_tokens
```

---

### work Command Helpers

**File:** `commands/work.zsh`
**Functions:** 3 (v5.17.0 token automation)

#### `_work_project_uses_github`

Check if project uses GitHub as remote.

**Signature:**
```zsh
_work_project_uses_github <project_path>
```

**Parameters:**
- `$1` - (required) Path to project directory

**Returns:**
- 0 - Project uses GitHub remote
- 1 - No GitHub remote found

**Example:**
```zsh
if _work_project_uses_github "$HOME/projects/my-repo"; then
    echo "Project uses GitHub"
fi
```

---

#### `_work_get_token_status`

Get GitHub token status for work session.

**Signature:**
```zsh
_work_get_token_status
```

**Parameters:**
- None (uses keychain token)

**Returns:**
- stdout - Token status string

**Status Values:**
- `"not configured"` - No token found in keychain
- `"expired/invalid"` - Token doesn't authenticate (HTTP != 200)
- `"expiring in N days"` - Token valid but expires soon (< 7 days)
- `"ok"` - Token valid with sufficient time remaining

**Example:**
```zsh
status=$(_work_get_token_status)
case "$status" in
    "not configured")
        echo "⚠️  Set up GitHub token: dot token github"
        ;;
    "expired/invalid")
        echo "⚠️  Token expired, rotate: dot token rotate"
        ;;
    "expiring in "*)
        echo "⚠️  $status"
        ;;
    "ok")
        echo "✓ GitHub token valid"
        ;;
esac
```

---

#### `_work_will_push_to_remote`

Check if current branch will push to remote.

**Signature:**
```zsh
_work_will_push_to_remote
```

**Parameters:**
- None (checks current git branch)

**Returns:**
- 0 - Branch tracks a remote (will push)
- 1 - No remote tracking (local-only branch)

**Use Case:**
- Determine if token validation needed before `work` session
- Skip token check for local-only work

**Example:**
```zsh
if _work_will_push_to_remote; then
    # Validate token before allowing push
    if ! _flow_git_validate_token; then
        echo "Invalid token, cannot push"
        return 1
    fi
fi
```

---

### dot Dispatcher Helpers

**File:** `lib/dispatchers/dot-dispatcher.zsh`
**Functions:** 5 (v5.17.0 token automation)

#### `_dot_token_expiring`

Check all GitHub tokens for expiration status.

**Signature:**
```zsh
_dot_token_expiring
```

**Parameters:**
- None (scans all GitHub tokens in keychain)

**Returns:**
- 0 - No expiring tokens
- 1 - Expiring or expired tokens found

**Output:**
- Lists expiring tokens (< 7 days)
- Lists expired tokens (invalid)

**Example:**
```zsh
dot token expiring
# Shows tokens expiring in < 7 days
```

---

#### `_dot_token_age_days`

Get token age in days since creation.

**Signature:**
```zsh
_dot_token_age_days <secret_name>
```

**Parameters:**
- `$1` - (required) Secret name (e.g., "github-token")

**Returns:**
- stdout - Age in days (integer)
- stdout - 90 if no creation metadata (flags for rotation)

**Implementation:**
- Reads creation timestamp from keychain metadata
- Parses JSON metadata field
- Calculates days elapsed

**Example:**
```zsh
age_days=$(_dot_token_age_days "github-token")
if [[ $age_days -gt 80 ]]; then
    echo "Token is $age_days days old, consider rotating"
fi
```

---

#### `_dot_token_rotate`

Rotate GitHub token (delete old, create new).

**Signature:**
```zsh
_dot_token_rotate [token_name]
```

**Parameters:**
- `$1` - (optional) Token name [default: "github-token"]

**Returns:**
- 0 - Rotation successful
- 1 - Rotation failed

**Workflow:**
1. Verify old token exists
2. Validate old token (get username)
3. Generate new token via `gh` CLI
4. Store new token in keychain with metadata
5. Invalidate doctor cache
6. Sync to `gh` CLI config
7. Log rotation event

**Side Effects:**
- Creates rotation log entry
- Clears doctor cache for the provider
- Updates keychain
- Syncs gh CLI configuration

**Example:**
```zsh
dot token rotate github-token
# Rotates token automatically
```

---

#### `_dot_token_log_rotation`

Log token rotation event.

**Signature:**
```zsh
_dot_token_log_rotation <provider> <old_username> <new_username>
```

**Parameters:**
- `$1` - (required) Provider name (e.g., "github")
- `$2` - (required) Old token username
- `$3` - (required) New token username

**Log Format:**
```
[2026-01-23T12:30:00Z] ROTATION github old_user→new_user
```

**Log Location:**
- `~/.flow/logs/token-rotations.log`

**Example:**
```zsh
_dot_token_log_rotation "github" "user" "user"
```

---

#### `_dot_token_sync_gh`

Sync token to gh CLI configuration.

**Signature:**
```zsh
_dot_token_sync_gh <token>
```

**Parameters:**
- `$1` - (required) GitHub token value

**Returns:**
- 0 - Sync successful
- 1 - gh CLI not available

**Behavior:**
- Configures `gh auth login` with provided token
- Uses `gh` CLI's token storage
- Enables `gh` commands to work seamlessly

**Example:**
```zsh
token=$(dot secret github-token)
_dot_token_sync_gh "$token"
```

---

### g Dispatcher Helpers

**File:** `lib/dispatchers/g-dispatcher.zsh`
**Functions:** 2 (v5.17.0 token automation)

#### `_g_is_github_remote`

Check if current repository has GitHub remote.

**Signature:**
```zsh
_g_is_github_remote
```

**Parameters:**
- None (checks current directory git repo)

**Returns:**
- 0 - GitHub remote found
- 1 - No GitHub remote

**Use Case:**
- Determine if token validation needed before `g push`
- Skip token check for non-GitHub remotes

**Example:**
```zsh
if _g_is_github_remote; then
    # Validate token before push
    _g_validate_github_token_silent || {
        echo "Invalid token"
        return 1
    }
fi
```

---

#### `_g_validate_github_token_silent`

Quick token validation without output.

**Signature:**
```zsh
_g_validate_github_token_silent
```

**Parameters:**
- None (uses keychain token)

**Returns:**
- 0 - Token valid (HTTP 200)
- 1 - Token missing, expired, or invalid

**Caching:**
- Uses doctor cache (5-min TTL) if available
- Falls back to API call if cache miss

**Performance:**
- Cached: ~50-80ms
- Uncached: ~2-3s (API roundtrip)

**Example:**
```zsh
if _g_validate_github_token_silent; then
    git push origin dev
else
    echo "Invalid token, run: dot token rotate"
    return 1
fi
```

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
