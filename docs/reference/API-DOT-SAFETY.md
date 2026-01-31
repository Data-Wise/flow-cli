# Chezmoi Safety - API Reference

**Version:** 6.0.0
**Type:** API Reference
**Last Updated:** 2026-01-31

## Table of Contents

- [Platform Abstraction Layer](#platform-abstraction-layer)
- [Cache Management](#cache-management)
- [Safety Features](#safety-features)
- [Utility Functions](#utility-functions)
- [Constants](#constants)

---

## Platform Abstraction Layer

### `_flow_get_file_size()`

**Location:** `lib/core.zsh`

**Purpose:** Get file size in bytes (cross-platform compatible).

**Signature:**

```zsh
_flow_get_file_size() {
  local file="$1"
  # Implementation
}
```

**Arguments:**

- `$1` - (required) File path

**Returns:**

- `stdout` - File size in bytes (integer)
- `0` - If file not found or error

**Platform Support:**

- **macOS (BSD):** Uses `stat -f%z`
- **Linux (GNU):** Uses `stat -c%s`
- **Fallback:** Returns 0

**Examples:**

```zsh
# Get size of single file
size=$(_flow_get_file_size ~/.zshrc)
echo "Size: $size bytes"  # Output: Size: 2048 bytes

# Check if file is large
size=$(_flow_get_file_size vault.sqlite)
if (( size > 51200 )); then
  echo "Large file detected"
fi
```

**Exit Codes:**

- `0` - Always (outputs size or 0)

**Notes:**

- Handles missing files gracefully (returns 0)
- No error messages (silent failure)
- Uses `2>/dev/null` for stderr suppression

---

### `_flow_human_size()`

**Location:** `lib/core.zsh`

**Purpose:** Convert bytes to human-readable format (KB/MB/GB).

**Signature:**

```zsh
_flow_human_size() {
  local bytes="$1"
  # Implementation
}
```

**Arguments:**

- `$1` - (required) Size in bytes (integer)

**Returns:**

- `stdout` - Human-readable size string

**Platform Support:**

- **Preferred:** Uses `numfmt --to=iec` if available
- **Fallback:** Manual calculation (dividing by 1024)

**Examples:**

```zsh
# Convert bytes to human format
echo $(_flow_human_size 512)       # Output: 512 bytes
echo $(_flow_human_size 51200)     # Output: 50K
echo $(_flow_human_size 1048576)   # Output: 1M
echo $(_flow_human_size 1073741824)# Output: 1G

# Use in pipelines
total_bytes=0
for file in *.log; do
  size=$(_flow_get_file_size "$file")
  ((total_bytes += size))
done
echo "Total: $(_flow_human_size $total_bytes)"
```

**Output Format:**

| Bytes           | Output      | Range         |
| --------------- | ----------- | ------------- |
| 0-1023          | "X bytes"   | < 1KB         |
| 1024-1048575    | "XK"        | 1KB - 1MB     |
| 1048576-1073741823 | "XM"     | 1MB - 1GB     |
| 1073741824+     | "XG"        | >= 1GB        |

**Exit Codes:**

- `0` - Always

---

### `_flow_timeout()`

**Location:** `lib/core.zsh`

**Purpose:** Execute command with timeout (cross-platform).

**Signature:**

```zsh
_flow_timeout() {
  local seconds="$1"
  shift
  # Implementation
}
```

**Arguments:**

- `$1` - (required) Timeout in seconds
- `$@` - (required) Command and arguments to execute

**Returns:**

- `stdout/stderr` - Command output
- Exit code from command (or 124 if timeout)

**Platform Support:**

- **GNU coreutils:** Uses `timeout` command
- **Homebrew:** Uses `gtimeout` (macOS with coreutils installed)
- **Fallback:** Executes command without timeout

**Examples:**

```zsh
# Timeout after 2 seconds
_flow_timeout 2 find /large/dir -type f

# Use in conditional
if _flow_timeout 5 git fetch origin; then
  echo "Fetch succeeded"
else
  echo "Fetch failed or timed out"
fi

# Capture output with timeout
large_files=$(_flow_timeout 3 find . -size +100k)
```

**Exit Codes:**

- `0` - Command succeeded within timeout
- `124` - Command timed out (GNU timeout convention)
- `other` - Command's actual exit code

**Notes:**

- Timeout in seconds (integer)
- If no timeout command available, runs normally
- Use for potentially slow operations (find, network, etc.)

---

## Cache Management

### `_dot_is_cache_valid()`

**Location:** `lib/dotfile-helpers.zsh`

**Purpose:** Check if cache is still valid based on TTL.

**Signature:**

```zsh
_dot_is_cache_valid() {
  local cache_time="$1"
  local ttl="${2:-$_DOT_CACHE_TTL}"
  # Implementation
}
```

**Arguments:**

- `$1` - (required) Cache timestamp (Unix epoch)
- `$2` - (optional) TTL in seconds (default: `$_DOT_CACHE_TTL`)

**Returns:**

- `0` - Cache is valid (within TTL)
- `1` - Cache is invalid (expired or missing)

**Examples:**

```zsh
# Check default cache (5 min TTL)
if _dot_is_cache_valid "$_DOT_SIZE_CACHE_TIME"; then
  echo "Cache hit"
else
  echo "Cache miss - recompute needed"
fi

# Check with custom TTL (30 minutes)
if _dot_is_cache_valid "$timestamp" 1800; then
  echo "Valid for 30 min"
fi
```

**Cache Logic:**

```
current_time - cache_time < TTL  →  Valid (return 0)
current_time - cache_time >= TTL  →  Invalid (return 1)
cache_time is empty  →  Invalid (return 1)
```

**Exit Codes:**

- `0` - Cache valid
- `1` - Cache invalid or expired

---

### `_dot_get_cached_size()`

**Location:** `lib/dotfile-helpers.zsh`

**Purpose:** Retrieve cached size if valid.

**Signature:**

```zsh
_dot_get_cached_size() {
  # Implementation
}
```

**Arguments:**

- None

**Returns:**

- `stdout` - Cached size string if valid
- Empty string if invalid or expired

**Examples:**

```zsh
# Try cache first
if size_display=$(_dot_get_cached_size); then
  echo "Total: $size_display (cached)"
else
  # Recompute
  size=$(du -sh ~/.local/share/chezmoi | cut -f1)
  _dot_cache_size "$size"
  echo "Total: $size"
fi
```

**Exit Codes:**

- `0` - Always (may return empty string)

---

### `_dot_cache_size()`

**Location:** `lib/dotfile-helpers.zsh`

**Purpose:** Cache size calculation with timestamp.

**Signature:**

```zsh
_dot_cache_size() {
  local size="$1"
  # Implementation
}
```

**Arguments:**

- `$1` - (required) Size string to cache

**Returns:**

- None (sets global variables)

**Side Effects:**

- Sets `_DOT_SIZE_CACHE` to size value
- Sets `_DOT_SIZE_CACHE_TIME` to current timestamp

**Examples:**

```zsh
# Cache computed size
size=$(du -sh ~/.local/share/chezmoi | cut -f1)
_dot_cache_size "$size"

# Later retrieval
cached=$(_dot_get_cached_size)
```

**Exit Codes:**

- `0` - Always

---

## Safety Features

### `_dot_preview_add()`

**Location:** `lib/dotfile-helpers.zsh`

**Purpose:** Preview files before adding to chezmoi with safety warnings.

**Signature:**

```zsh
_dot_preview_add() {
  local target="$1"
  # Implementation
}
```

**Arguments:**

- `$1` - (required) Target path to add (file or directory)

**Returns:**

- `0` - User confirmed, proceed with add
- `1` - User cancelled or validation failed

**Safety Checks:**

1. **File count** - Shows total files to add
2. **Total size** - Human-readable size calculation
3. **Large files** - Warns about files >50KB
4. **Generated files** - Detects .log, .sqlite, .db, .cache
5. **Git metadata** - Alerts about .git directories
6. **Auto-suggestions** - Offers ignore pattern additions

**Examples:**

```zsh
# Preview and add if confirmed
if _dot_preview_add "$target"; then
  chezmoi add "$target"
  _flow_log_success "Added to chezmoi"
else
  _flow_log_info "Add cancelled"
  return 1
fi

# Use in command
_dot_add() {
  local target="$1"

  # Validate
  [[ -e "$target" ]] || {
    _flow_log_error "Target not found: $target"
    return 1
  }

  # Preview
  _dot_preview_add "$target" || return 1

  # Execute
  chezmoi add "$target"
}
```

**Output Format:**

```
Preview: dot add /path/to/target
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Files to add: 8
Total size: 301K

⚠️  Large files detected:
  - vault.sqlite (200K)

⚠️  Generated files detected:
  - app.log (12 bytes)

💡 Consider excluding: *.log, *.sqlite

Auto-add ignore patterns? (Y/n):
```

**Exit Codes:**

- `0` - User confirmed (Y or Enter)
- `1` - User cancelled (n) or error

**Notes:**

- Interactive (requires user input)
- Uses `read -q` for confirmation
- Displays visual hierarchy with box drawing
- Integrates with `_dot_suggest_ignore_patterns()`

---

### `_dot_check_git_in_path()`

**Location:** `lib/dotfile-helpers.zsh`

**Purpose:** Detect git directories in target path to prevent tracking .git metadata.

**Signature:**

```zsh
_dot_check_git_in_path() {
  local target="$1"
  # Implementation
}
```

**Arguments:**

- `$1` - (required) Target path to check

**Returns:**

- `stdout` - Space-separated list of .git directories found
- `0` - Git directories found
- `1` - No git directories found

**Detection Strategy:**

1. **Symlink handling** - Resolves with user confirmation
2. **Target check** - Checks if target itself has .git
3. **Fast path** - Uses `git submodule status` if inside git repo
4. **Slow path** - Uses `find` with 2-second timeout and maxdepth 5

**Examples:**

```zsh
# Check for git directories
if git_dirs=$(_dot_check_git_in_path "$target"); then
  echo "Found git metadata:"
  for gitdir in ${(z)git_dirs}; do
    echo "  - $gitdir"
  done
else
  echo "No git directories detected"
fi

# Use in preview
if git_dirs=$(_dot_check_git_in_path "$target"); then
  git_count=$(echo "$git_dirs" | wc -w)
  _dot_warn "$git_count git metadata files detected"
fi
```

**Performance:**

- **Fast path:** ~100-200ms (uses git commands)
- **Slow path:** Up to 2 seconds (timeout enforced)
- **Depth limit:** 5 levels (prevents deep recursion)

**Exit Codes:**

- `0` - Found git directories
- `1` - No git directories found

**Notes:**

- Handles symlinks with user confirmation
- Timeout protection for large directories
- Outputs array-safe format (space-separated)

---

### `_dot_suggest_ignore_patterns()`

**Location:** `lib/dotfile-helpers.zsh`

**Purpose:** Automatically add ignore patterns to .chezmoiignore.

**Signature:**

```zsh
_dot_suggest_ignore_patterns() {
  local patterns=("$@")
  # Implementation
}
```

**Arguments:**

- `$@` - (required) One or more ignore patterns to add

**Returns:**

- `0` - Patterns added successfully (or already present)
- `1` - Error (no patterns provided)

**Features:**

- **Creates file** - Makes .chezmoiignore if missing
- **Duplicate detection** - Skips patterns already present
- **Preserves content** - Appends without modifying existing
- **Feedback** - Success/info message for each operation

**Examples:**

```zsh
# Add single pattern
_dot_suggest_ignore_patterns "*.log"

# Add multiple patterns
_dot_suggest_ignore_patterns "*.log" "*.sqlite" "*.db"

# Use with detection
if [[ -n "$generated_files" ]]; then
  patterns=("*.log" "*.sqlite" "*.cache")
  _dot_suggest_ignore_patterns "${patterns[@]}"
fi
```

**Output:**

```
ℹ Created .chezmoiignore
✓ Added *.log to .chezmoiignore
✓ Added *.sqlite to .chezmoiignore
ℹ *.db already in .chezmoiignore
```

**Exit Codes:**

- `0` - Success (patterns added or already present)
- `1` - Error (no patterns provided)

---

## Utility Functions

### `_dot_warn()`

**Location:** `lib/dotfile-helpers.zsh`

**Purpose:** Display warning message with dot context.

**Signature:**

```zsh
_dot_warn() {
  local message="$1"
  # Implementation
}
```

**Arguments:**

- `$1` - (required) Warning message

**Returns:**

- `0` - Always

**Examples:**

```zsh
_dot_warn "Large file detected: config.db"
_dot_warn "Repository size exceeds 5MB"
```

**Output:**

```
⚠️  Large file detected: config.db
```

---

### `_dot_info()`

**Location:** `lib/dotfile-helpers.zsh`

**Purpose:** Display info message with dot context.

**Signature:**

```zsh
_dot_info() {
  local message="$1"
  # Implementation
}
```

**Arguments:**

- `$1` - (required) Info message

**Returns:**

- `0` - Always

**Examples:**

```zsh
_dot_info "Scanning directory..."
_dot_info "These will be skipped (covered by .chezmoiignore)"
```

**Output:**

```
ℹ Scanning directory...
```

---

### `_dot_success()`

**Location:** `lib/dotfile-helpers.zsh`

**Purpose:** Display success message with dot context.

**Signature:**

```zsh
_dot_success() {
  local message="$1"
  # Implementation
}
```

**Arguments:**

- `$1` - (required) Success message

**Returns:**

- `0` - Always

**Examples:**

```zsh
_dot_success "Added 3 files to chezmoi"
_dot_success "Repository health check passed"
```

**Output:**

```
✓ Added 3 files to chezmoi
```

---

### `_dot_header()`

**Location:** `lib/dotfile-helpers.zsh`

**Purpose:** Display section header with visual separation.

**Signature:**

```zsh
_dot_header() {
  local text="$1"
  # Implementation
}
```

**Arguments:**

- `$1` - (required) Header text

**Returns:**

- `0` - Always

**Examples:**

```zsh
_dot_header "Preview: dot add ~/.config"
_dot_header "Repository Health Check"
```

**Output:**

```

Preview: dot add ~/.config
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Constants

### Cache Configuration

```zsh
typeset -g _DOT_SIZE_CACHE          # Cached size string
typeset -g _DOT_SIZE_CACHE_TIME     # Timestamp (Unix epoch)
typeset -g _DOT_IGNORE_CACHE        # Cached ignore patterns
typeset -g _DOT_IGNORE_CACHE_TIME   # Timestamp
typeset -g _DOT_CACHE_TTL=300       # 5 minutes (default)
```

**Environment Variables:**

| Variable          | Type     | Default | Purpose                   |
| ----------------- | -------- | ------- | ------------------------- |
| `_DOT_CACHE_TTL`  | Integer  | 300     | Cache TTL in seconds      |
| `DOT_SKIP_PREVIEW`| Boolean  | 0       | Skip preview (if set to 1)|

---

### Thresholds

```zsh
# File size thresholds
LARGE_FILE_THRESHOLD=51200      # 50KB in bytes
VERY_LARGE_FILE=102400          # 100KB in bytes

# Repository size thresholds
REPO_SIZE_WARNING=5242880       # 5MB in bytes
REPO_SIZE_ERROR=20971520        # 20MB in bytes

# Directory thresholds
LARGE_DIR_COUNT=1000            # Files in directory

# Timeouts
GIT_FIND_TIMEOUT=2              # Seconds
LARGE_DIR_TIMEOUT=5             # Seconds
```

---

### File Patterns

**Generated Files:**

```zsh
GENERATED_PATTERNS=(
  "*.log"
  "*.sqlite"
  "*.db"
  "*.cache"
  "*.tmp"
  "*.swp"
)
```

**Ignore Patterns (Default):**

```zsh
DEFAULT_IGNORE=(
  "**/.git"
  "**/.git/**"
  "*.log"
  "*.tmp"
  ".DS_Store"
)
```

---

## Exit Codes

### Command Exit Codes

| Command                | Success | User Cancel | Error |
| ---------------------- | ------- | ----------- | ----- |
| `dot add` (with preview)| 0      | 1           | 1     |
| `dot ignore add`       | 0       | -           | 1     |
| `dot size`             | 0       | -           | 1     |
| `flow doctor --dot`    | 0 (pass)| -           | 1 (warn), 2 (error)|

### Function Return Codes

| Function                       | Success | Not Found | Error |
| ------------------------------ | ------- | --------- | ----- |
| `_dot_preview_add`             | 0       | 1         | 1     |
| `_dot_check_git_in_path`       | 0 (found)| 1 (not found)| - |
| `_dot_suggest_ignore_patterns` | 0       | -         | 1     |
| `_dot_is_cache_valid`          | 0 (valid)| 1 (invalid)| -   |

---

## Usage Patterns

### Pattern 1: Safe File Addition

```zsh
_dot_add_safe() {
  local target="$1"

  # Validate
  [[ -e "$target" ]] || {
    _dot_warn "Target not found: $target"
    return 1
  }

  # Preview
  _dot_preview_add "$target" || return 1

  # Execute
  chezmoi add "$target"
  _dot_success "Added successfully"
}
```

### Pattern 2: Cached Size Calculation

```zsh
_dot_get_size_with_cache() {
  local chezmoi_dir="$HOME/.local/share/chezmoi"

  # Try cache first
  if size=$(_dot_get_cached_size); then
    echo "Total: $size (cached)"
    return 0
  fi

  # Compute fresh
  size=$(du -sh "$chezmoi_dir" 2>/dev/null | cut -f1)
  _dot_cache_size "$size"
  echo "Total: $size"
}
```

### Pattern 3: Batch Ignore Addition

```zsh
_dot_add_common_ignores() {
  local patterns=(
    "*.log"
    "*.sqlite"
    "*.db"
    "*.cache"
    "*.tmp"
    ".DS_Store"
    "node_modules"
  )

  _dot_header "Adding common ignore patterns"
  _dot_suggest_ignore_patterns "${patterns[@]}"
}
```

---

## Performance Benchmarks

### Function Performance

| Function                   | Cold Run | Cached  | Target   |
| -------------------------- | -------- | ------- | -------- |
| `_flow_get_file_size`      | 1-2ms    | N/A     | <5ms     |
| `_flow_human_size`         | 1-2ms    | N/A     | <5ms     |
| `_dot_is_cache_valid`      | <1ms     | N/A     | <1ms     |
| `_dot_preview_add` (file)  | 10-20ms  | N/A     | <50ms    |
| `_dot_preview_add` (dir)   | 2-4s     | 100-200ms| <500ms  |
| `_dot_check_git_in_path`   | 100-200ms| N/A     | <500ms   |

---

## See Also

- **User Guide:** [CHEZMOI-SAFETY-GUIDE.md](../guides/CHEZMOI-SAFETY-GUIDE.md)
- **Quick Reference:** [REFCARD-DOT-SAFETY.md](REFCARD-DOT-SAFETY.md)
- **Architecture:** [DOT-SAFETY-ARCHITECTURE.md](../architecture/DOT-SAFETY-ARCHITECTURE.md)
- **Master API:** [MASTER-API-REFERENCE.md](MASTER-API-REFERENCE.md)

---

**Version History:**

- **6.0.0** (2026-01-31) - Initial API release

**Maintained by:** Data-Wise Team
**License:** MIT
