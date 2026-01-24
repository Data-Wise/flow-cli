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
