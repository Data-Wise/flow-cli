# Chezmoi Safety Features - User Guide

**Version:** 6.0.0
**Status:** Production
**Last Updated:** 2026-01-31

## Overview

The Chezmoi safety features provide intelligent protection when managing dotfiles with `chezmoi`. These features prevent common mistakes like tracking large files, generated content, or git repositories, while providing a smooth user experience with preview-before-add functionality and smart ignore pattern management.

## Table of Contents

- [Quick Start](#quick-start)
- [Features](#features)
- [Commands](#commands)
- [Safety Checks](#safety-checks)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

### Basic Workflow

```bash
# Preview files before adding
dot add ~/.config/nvim

# Review the preview showing:
# - File count and total size
# - Large file warnings
# - Generated file detection
# - Git metadata alerts
# - Auto-ignore suggestions

# Confirm or cancel the add operation
```

### Managing Ignore Patterns

```bash
# Add ignore patterns
dot ignore add "*.log"
dot ignore add "*.sqlite"

# List all patterns
dot ignore list

# Edit patterns manually
dot ignore edit
```

### Repository Health

```bash
# Check repository size and health
dot size

# Full health check
flow doctor --dot
```

---

## Features

### 1. Preview-Before-Add

**Automatically analyzes files before adding to chezmoi:**

- **File counting** - Shows exact number of files being added
- **Size calculation** - Displays total size in human-readable format (KB/MB/GB)
- **Large file detection** - Warns about files >50KB
- **Generated file detection** - Identifies `.log`, `.sqlite`, `.db`, `.cache` files
- **Git metadata detection** - Catches nested `.git` directories
- **Smart suggestions** - Offers to auto-add ignore patterns

**Example Preview:**

```
Preview: dot add /Users/dt/.config/obs
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Files to add: 8
Total size: 301K

⚠️  1 git metadata files detected
 ℹ These will be skipped (covered by .chezmoiignore)

⚠️  Large files detected:
  - vault.sqlite (200K)
  - large-config.json (100K)

⚠️  Generated files detected:
  - vault.sqlite (200K)
  - cache.db (11 bytes)
  - app.log (12 bytes)

💡 Consider excluding: *.log, *.sqlite, *.db, *.cache

Auto-add ignore patterns? (Y/n):
```

### 2. Ignore Pattern Management

**Simple commands for managing `.chezmoiignore`:**

```bash
# Add patterns
dot ignore add "*.log"           # Exclude log files
dot ignore add "node_modules"    # Exclude directories
dot ignore add "*.tmp"           # Exclude temporary files

# List patterns with line numbers
dot ignore list
#  1  *.log
#  2  node_modules
#  3  *.tmp

# Remove patterns
dot ignore remove "*.tmp"

# Edit manually in $EDITOR
dot ignore edit
```

**Pattern Syntax:**

- `*.ext` - Match all files with extension
- `dirname` - Match directory name
- `path/to/file` - Specific file path
- `**/pattern` - Recursive matching

### 3. Repository Size Analysis

**Monitor repository size and identify bloat:**

```bash
dot size
```

**Output:**

```
Total: 15MB (cached)

Top 10 largest files:
10M    vault.sqlite
2.5M   large-config.json
1.2M   history.db
500K   icons.cache
...

⚠️  Found 2 nested git directories
 ℹ Consider adding to .chezmoiignore
```

**Performance Features:**

- **5-minute cache** - Size calculations cached to avoid slowness
- **Git directory warnings** - Alerts about nested repos
- **Top 10 listing** - Quick identification of large files

### 4. Doctor Health Checks

**Comprehensive repository health validation:**

```bash
flow doctor --dot
```

**9 Health Checks:**

1. ✅ **Chezmoi installed** - Verifies installation and version
2. ✅ **Repository initialized** - Checks `~/.local/share/chezmoi` exists
3. ✅ **Remote configured** - Validates git remote setup
4. ✅ **Ignore file exists** - Ensures `.chezmoiignore` is present
5. ✅ **Managed file count** - Reports number of tracked files
6. ⚠️ **Repository size** - Warns >5MB, errors >20MB
7. ⚠️ **Large files** - Detects files >100KB
8. ⚠️ **Nested git directories** - Finds unintended `.git` folders
9. ✅ **Sync status** - Checks for uncommitted changes

**Status Indicators:**

- ✅ **Pass** - Check succeeded
- ⚠️ **Warning** - Potential issue detected
- ❌ **Error** - Action required

### 5. Cross-Platform Compatibility

**Works on both macOS (BSD) and Linux (GNU):**

- **BSD `stat`** (macOS) - `stat -f%z`
- **GNU `stat`** (Linux) - `stat -c%s`
- **Automatic detection** - No configuration needed
- **Fallback handling** - Graceful degradation when tools missing

**Performance Optimizations:**

- **Timeout wrappers** - 2-second timeout for large directories
- **Smart caching** - 5-minute TTL for expensive operations
- **Large directory warnings** - Alert when >1000 files detected

---

## Commands

### `dot add <path>`

Add files to chezmoi with preview and safety checks.

**Usage:**

```bash
# Add single file
dot add ~/.zshrc

# Add directory
dot add ~/.config/nvim

# Add with automatic ignore suggestion
dot add ~/.config/obs
```

**Preview Features:**

- File count and total size
- Large file warnings (>50KB)
- Generated file detection
- Git metadata alerts
- Auto-ignore suggestions

**Exit Codes:**

- `0` - User confirmed, add succeeded
- `1` - User cancelled or validation failed

### `dot ignore <subcommand>`

Manage ignore patterns in `.chezmoiignore`.

#### `dot ignore add <pattern>`

Add new ignore pattern.

```bash
dot ignore add "*.log"
dot ignore add "node_modules"
dot ignore add ".DS_Store"
```

**Features:**

- Duplicate detection (skips if pattern exists)
- Creates `.chezmoiignore` if missing
- Provides feedback for each operation

#### `dot ignore list` (alias: `ls`)

List all ignore patterns with line numbers.

```bash
dot ignore list
```

**Output:**

```
 1  *.log
 2  *.sqlite
 3  node_modules
 4  .DS_Store
```

#### `dot ignore remove <pattern>` (alias: `rm`)

Remove ignore pattern.

```bash
dot ignore remove "*.log"
```

**Features:**

- Cross-platform compatible (uses temp file approach)
- Safe removal (pattern must exist)
- Preserves file formatting

#### `dot ignore edit`

Open `.chezmoiignore` in `$EDITOR`.

```bash
dot ignore edit
```

**Default Editor:** `$EDITOR` environment variable (fallback: `vim`)

### `dot size`

Analyze repository size and identify large files.

**Usage:**

```bash
dot size
```

**Features:**

- **Total size** - Cached for 5 minutes
- **Top 10 files** - Largest files in repository
- **Git directory warnings** - Alerts about nested repos
- **Performance** - Fast cached results

**Example Output:**

```
Total: 15MB (cached)

Top 10 largest files:
10M    vault.sqlite
2.5M   large-config.json
1.2M   history.db
500K   icons.cache
250K   .zsh_history
100K   nvim/undo/history
...

⚠️  Found 2 nested git directories
```

### `flow doctor --dot`

Run comprehensive health check on chezmoi repository.

**Usage:**

```bash
# Full health check
flow doctor --dot

# Fix token issues only
flow doctor --fix-token

# Quiet mode (CI/CD)
flow doctor --dot --quiet

# Verbose mode (debugging)
flow doctor --dot --verbose
```

**Exit Codes:**

- `0` - All checks passed
- `1` - Warnings detected
- `2` - Errors requiring action

---

## Safety Checks

### Large File Detection

**Threshold:** 50KB (51,200 bytes)

**Why:** Large files bloat repository size and slow down sync operations.

**Warnings:**

- **>50KB** - Preview warning with file size
- **>100KB** - Doctor health check warning
- **>1MB** - Strong recommendation to exclude

**Example:**

```
⚠️  Large files detected:
  - vault.sqlite (200K)
  - large-config.json (100K)
```

**Recommendation:**

```bash
# Add to ignore patterns
dot ignore add "*.sqlite"
dot ignore add "large-config.json"
```

### Generated File Detection

**Patterns:** `*.log`, `*.sqlite`, `*.db`, `*.cache`

**Why:** Generated files change frequently and shouldn't be tracked.

**Auto-Detection:**

```
⚠️  Generated files detected:
  - vault.sqlite (200K)
  - cache.db (11 bytes)
  - app.log (12 bytes)

💡 Consider excluding: *.log, *.sqlite, *.db, *.cache

Auto-add ignore patterns? (Y/n):
```

**Common Patterns to Exclude:**

```bash
dot ignore add "*.log"
dot ignore add "*.sqlite"
dot ignore add "*.db"
dot ignore add "*.cache"
dot ignore add "*.tmp"
dot ignore add "*.swp"
```

### Git Metadata Detection

**Pattern:** `/.git/` in file path

**Why:** Nested git repositories cause confusion and bloat.

**Detection:**

```
⚠️  1 git metadata files detected
 ℹ These will be skipped (covered by .chezmoiignore)
```

**Default Pattern:**

The `.chezmoiignore` file should include:

```
**/.git
**/.git/**
```

### Performance Timeouts

**Large Directory Protection:**

- **Threshold:** 1000+ files
- **Timeout:** 2 seconds for `find` operations
- **Fallback:** Manual counting or user warning

**Why:** Prevents hanging on massive directories (e.g., `node_modules`, build artifacts).

**Example Warning:**

```
⚠️  Large directory detected (>1000 files)
 ℹ This may take a moment to analyze...
```

---

## Configuration

### Environment Variables

```bash
# Cache TTL (default: 300 seconds = 5 minutes)
export _DOT_CACHE_TTL=600

# Disable preview (skip safety checks)
export DOT_SKIP_PREVIEW=1
```

### Cache Management

**Automatic Cache:**

- **Size calculations** - 5-minute TTL
- **Ignore patterns** - 5-minute TTL
- **Invalidation** - Automatic on file changes

**Manual Cache Clear:**

```bash
# Force fresh size calculation
unset _DOT_SIZE_CACHE
unset _DOT_SIZE_CACHE_TIME

dot size  # Will recalculate
```

### Ignore File Location

**Default:** `~/.local/share/chezmoi/.chezmoiignore`

**Creation:** Automatically created on first `dot ignore add` command.

**Example `.chezmoiignore`:**

```
# Generated files
*.log
*.sqlite
*.db
*.cache
*.tmp

# IDE files
.vscode/
.idea/

# OS files
.DS_Store
Thumbs.db

# Build artifacts
node_modules/
dist/
build/

# Git metadata
**/.git
**/.git/**
```

---

## Troubleshooting

### Preview Shows Incorrect Size

**Problem:** Size calculation seems wrong or slow.

**Solution:**

```bash
# Clear cache and recalculate
unset _DOT_SIZE_CACHE
unset _DOT_SIZE_CACHE_TIME
dot size
```

**Cause:** Stale cache after large file operations.

### Timeout During Large Directory Scan

**Problem:** `dot add` hangs on large directories.

**Solution:**

```bash
# Add directory to ignore patterns first
dot ignore add "node_modules"

# Then add parent without the large subdirectory
dot add ~/.config/my-app
```

**Alternative:**

```bash
# Add specific files instead of directory
dot add ~/.config/my-app/config.yml
dot add ~/.config/my-app/settings.json
```

### Ignore Patterns Not Working

**Problem:** Files still being tracked despite ignore patterns.

**Solution:**

```bash
# Verify pattern syntax
dot ignore list

# Pattern might need adjustment
dot ignore remove "*.log"
dot ignore add "**/*.log"  # Recursive matching

# Force re-apply
chezmoi re-add
```

### Performance Issues with Size Command

**Problem:** `dot size` is slow even with cache.

**Diagnosis:**

```bash
# Check cache status
echo "Cache time: $_DOT_SIZE_CACHE_TIME"
echo "Current time: $(date +%s)"

# Verbose mode for debugging
flow doctor --dot --verbose
```

**Solution:**

```bash
# Increase cache TTL
export _DOT_CACHE_TTL=1800  # 30 minutes

# Or analyze only top-level
cd ~/.local/share/chezmoi
du -sh .  # Quick size check
```

### Cross-Platform Compatibility Issues

**Problem:** Size calculations fail on Linux or macOS.

**Diagnosis:**

```bash
# Check stat version
stat --version 2>/dev/null | grep -q GNU && echo "GNU" || echo "BSD"

# Test helper function
source lib/core.zsh
_flow_get_file_size ~/.zshrc
```

**Solution:**

Falls back automatically to compatible commands. If issues persist:

```bash
# Install GNU coreutils on macOS
brew install coreutils

# Use gstat instead of stat
alias stat=gstat
```

### Doctor Check Fails

**Problem:** `flow doctor --dot` shows errors.

**Common Issues:**

1. **Chezmoi not installed**

   ```bash
   brew install chezmoi
   ```

2. **Repository not initialized**

   ```bash
   chezmoi init
   ```

3. **No remote configured**

   ```bash
   cd ~/.local/share/chezmoi
   git remote add origin git@github.com:username/dotfiles.git
   ```

4. **Repository too large (>20MB)**

   ```bash
   # Find large files
   dot size

   # Add to ignore
   dot ignore add "large-file.db"

   # Remove from chezmoi
   chezmoi remove large-file.db
   ```

---

## Performance Metrics

### Cache Effectiveness

- **Hit rate:** ~85% expected
- **API reduction:** 80% fewer file system calls
- **Response time:** <10ms for cached operations

### Command Performance

| Command             | Without Cache | With Cache | Target   |
| ------------------- | ------------- | ---------- | -------- |
| `dot size`          | 3-5s          | 5-8ms      | <10ms    |
| `dot ignore list`   | 50-100ms      | 5ms        | <10ms    |
| `dot add` (preview) | 2-4s          | 100-200ms  | <500ms   |
| `flow doctor --dot` | 5-10s         | 2-3s       | <3s      |

### Size Thresholds

| Category       | Threshold | Action   |
| -------------- | --------- | -------- |
| Small file     | <50KB     | ✅ Safe  |
| Large file     | 50-100KB  | ⚠️ Warn  |
| Very large     | >100KB    | ⚠️ Alert |
| Repository OK  | <5MB      | ✅ Pass  |
| Repository Big | 5-20MB    | ⚠️ Warn  |
| Repository Too | >20MB     | ❌ Error |

---

## Best Practices

### 1. Regular Health Checks

```bash
# Weekly or before major changes
flow doctor --dot
```

### 2. Use Preview Before Add

```bash
# Always preview, especially for directories
dot add ~/.config/new-app
```

### 3. Maintain Ignore Patterns

```bash
# Keep patterns organized and documented
dot ignore edit

# Common patterns to start with
dot ignore add "*.log"
dot ignore add "*.sqlite"
dot ignore add "node_modules"
dot ignore add ".DS_Store"
```

### 4. Monitor Repository Size

```bash
# Check monthly or after bulk adds
dot size
```

### 5. Clean Up Large Files

```bash
# If repository grows too large
dot size  # Identify culprits
dot ignore add "large-file.db"
chezmoi remove large-file.db
```

---

## Advanced Usage

### Custom Cache TTL

```bash
# In ~/.zshrc or session
export _DOT_CACHE_TTL=1800  # 30 minutes
```

### Batch Ignore Operations

```bash
# Add multiple patterns at once
patterns=("*.log" "*.sqlite" "*.db" "*.cache")
for pattern in "${patterns[@]}"; do
  dot ignore add "$pattern"
done
```

### Integration with Scripts

```bash
#!/bin/zsh
# Automated dotfile addition with safety

if _dot_preview_add "$1"; then
  chezmoi add "$1"
  echo "✅ Added successfully"
else
  echo "❌ Add cancelled"
  exit 1
fi
```

### CI/CD Integration

```bash
# Quiet mode for automated checks
flow doctor --dot --quiet
exit_code=$?

if [[ $exit_code -eq 0 ]]; then
  echo "✅ All checks passed"
elif [[ $exit_code -eq 1 ]]; then
  echo "⚠️ Warnings detected"
else
  echo "❌ Errors found"
  exit 1
fi
```

---

## Related Documentation

- **Quick Reference:** [REFCARD-DOT-SAFETY.md](../reference/REFCARD-DOT-SAFETY.md)
- **API Reference:** [MASTER-API-REFERENCE.md](../reference/MASTER-API-REFERENCE.md)
- **Dispatcher Guide:** [MASTER-DISPATCHER-GUIDE.md](../reference/MASTER-DISPATCHER-GUIDE.md)
- **Testing Guide:** [TESTING.md](TESTING.md)

---

**Version History:**

- **6.0.0** (2026-01-31) - Initial release with comprehensive safety features
- Added preview-before-add functionality
- Added ignore pattern management
- Added size analysis and caching
- Added doctor health checks
- Added cross-platform compatibility

**Feedback:** https://github.com/Data-Wise/flow-cli/issues
