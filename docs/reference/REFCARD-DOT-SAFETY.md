# Chezmoi Safety - Quick Reference Card

**Version:** 6.0.0 | **Type:** Quick Reference | **Updated:** 2026-01-31

## Core Commands

| Command                     | Description                          | Example                                 |
| --------------------------- | ------------------------------------ | --------------------------------------- |
| `dots add <path>`            | Preview and add files to chezmoi     | `dots add ~/.config/nvim`                |
| `dots ignore add <pattern>`  | Add ignore pattern                   | `dots ignore add "*.log"`                |
| `dots ignore list`           | List all ignore patterns             | `dots ignore list`                       |
| `dots ignore remove <pat>`   | Remove ignore pattern                | `dots ignore remove "*.tmp"`             |
| `dots ignore edit`           | Edit .chezmoiignore in $EDITOR       | `dots ignore edit`                       |
| `dots size`                  | Show repository size and large files | `dots size`                              |
| `flow doctor --dot`         | Run health checks                    | `flow doctor --dot`                     |
| `flow doctor --fix-token`   | Fix token issues only                | `flow doctor --fix-token`               |

## Aliases

| Alias            | Expands To          |
| ---------------- | ------------------- |
| `dots ignore ls`  | `dots ignore list`   |
| `dots ignore rm`  | `dots ignore remove` |

---

## Preview Features

When running `dots add <path>`, you get:

✅ **File Analysis**
- File count (single file or directory)
- Total size (human-readable: KB/MB/GB)

⚠️ **Safety Warnings**
- Large files (>50KB)
- Generated files (*.log,*.sqlite, *.db,*.cache)
- Git metadata (/.git/ directories)

💡 **Smart Suggestions**
- Auto-add ignore patterns for detected issues
- User confirmation before adding

**Example Output:**

```yaml
Preview: dots add /Users/dt/.config/obs
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Files to add: 8
Total size: 301K

⚠️  Large files detected:
  - vault.sqlite (200K)

⚠️  Generated files detected:
  - vault.sqlite (200K)
  - app.log (12 bytes)

💡 Consider excluding: *.log, *.sqlite

Auto-add ignore patterns? (Y/n):
```

---

## Ignore Pattern Syntax

| Pattern           | Matches                      | Example                |
| ----------------- | ---------------------------- | ---------------------- |
| `*.ext`           | All files with extension     | `*.log`                |
| `dirname`         | Directory by name            | `node_modules`         |
| `path/to/file`    | Specific path                | `.config/app/cache.db` |
| `**/pattern`      | Recursive matching           | `**/.git`              |
| `!pattern`        | Negation (include exception) | `!important.log`       |

**Common Patterns:**

```bash
# Generated files
*.log
*.sqlite
*.db
*.cache
*.tmp
*.swp

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

## Size Thresholds

| Type             | Threshold | Indicator |
| ---------------- | --------- | --------- |
| Normal file      | <50KB     | ✅        |
| Large file       | 50-100KB  | ⚠️        |
| Very large file  | >100KB    | ⚠️⚠️     |
| Repository OK    | <5MB      | ✅        |
| Repository big   | 5-20MB    | ⚠️        |
| Repository too   | >20MB     | ❌        |

---

## Health Checks (`flow doctor --dot`)

**9 Checks:**

1. ✅ Chezmoi installed (with version)
2. ✅ Repository initialized (`~/.local/share/chezmoi`)
3. ✅ Remote configured (git origin)
4. ✅ Ignore file exists (`.chezmoiignore`)
5. 📊 Managed file count
6. 📏 Repository size (<5MB OK, 5-20MB warn, >20MB error)
7. 📦 Large files (>100KB)
8. 🗂️ Nested git directories
9. 🔄 Sync status (uncommitted changes)

**Exit Codes:**

- `0` - All checks passed
- `1` - Warnings detected
- `2` - Errors requiring action

---

## Performance

### Cache System

- **TTL:** 5 minutes (default)
- **Hit rate:** ~85%
- **API reduction:** 80% fewer file system calls

### Response Times

| Command             | Cached   | Uncached | Target  |
| ------------------- | -------- | -------- | ------- |
| `dots size`          | 5-8ms    | 3-5s     | <10ms   |
| `dots ignore list`   | 5ms      | 50-100ms | <10ms   |
| `dots add` (preview) | 100-200ms| 2-4s     | <500ms  |
| `flow doctor --dot` | 2-3s     | 5-10s    | <3s     |

### Cache Management

```bash
# Clear cache manually
unset _DOT_SIZE_CACHE
unset _DOT_SIZE_CACHE_TIME

# Adjust TTL (in ~/.zshrc)
export _DOT_CACHE_TTL=1800  # 30 minutes
```

---

## Cross-Platform Support

### Automatic Detection

✅ **macOS (BSD)** - Uses `stat -f%z`
✅ **Linux (GNU)** - Uses `stat -c%s`
✅ **Fallback** - Graceful degradation

### Performance Features

- **Timeout wrapper** - 2-second timeout for large directories
- **Smart caching** - Avoid repeated expensive operations
- **Large directory warnings** - Alert when >1000 files

---

## Common Workflows

### Initial Setup

```bash
# Install and initialize
brew install chezmoi
chezmoi init

# Add common ignore patterns
dots ignore add "*.log"
dots ignore add "*.sqlite"
dots ignore add "node_modules"
dots ignore add ".DS_Store"
```

### Adding Files Safely

```bash
# Single file
dots add ~/.zshrc

# Directory (with preview)
dots add ~/.config/nvim

# Accept auto-ignore suggestions when prompted
```

### Repository Maintenance

```bash
# Weekly health check
flow doctor --dot

# Monthly size check
dots size

# Clean up if too large
dots ignore add "large-file.db"
chezmoi remove large-file.db
```

### Batch Ignore Operations

```bash
# Add multiple patterns
patterns=("*.log" "*.sqlite" "*.db" "*.cache")
for pattern in "${patterns[@]}"; do
  dots ignore add "$pattern"
done
```

---

## Troubleshooting

| Problem                          | Solution                                       |
| -------------------------------- | ---------------------------------------------- |
| Preview shows wrong size         | Clear cache: `unset _DOT_SIZE_CACHE`           |
| Timeout during large scan        | Add directory to ignore first                  |
| Ignore patterns not working      | Check syntax: `dots ignore list`                |
| Performance issues               | Increase cache TTL: `export _DOT_CACHE_TTL=1800` |
| Doctor check fails               | See specific error and follow fix instructions |
| Cross-platform size issues       | Install GNU coreutils: `brew install coreutils` |

---

## Environment Variables

```bash
# Cache TTL (default: 300 = 5 minutes)
export _DOT_CACHE_TTL=600

# Skip preview (not recommended)
export DOT_SKIP_PREVIEW=1
```

---

## File Locations

| Item                | Path                                    |
| ------------------- | --------------------------------------- |
| Chezmoi repo        | `~/.local/share/chezmoi`                |
| Ignore file         | `~/.local/share/chezmoi/.chezmoiignore` |
| Config file         | `~/.config/chezmoi/chezmoi.toml`        |

---

## Exit Codes

### `dots add`

- `0` - User confirmed, add succeeded
- `1` - User cancelled or validation failed

### `flow doctor --dot`

- `0` - All checks passed
- `1` - Warnings detected
- `2` - Errors requiring action

---

## Advanced Usage

### Custom Preview Function

```bash
# In script or automation
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

if [[ $exit_code -ne 0 ]]; then
  echo "❌ Health check failed"
  exit 1
fi
```

### Batch File Addition

```bash
# Add multiple config directories
configs=(
  ~/.config/nvim
  ~/.config/zsh
  ~/.config/tmux
)

for config in "${configs[@]}"; do
  dots add "$config"
done
```

---

## See Also

- **Full Guide:** [CHEZMOI-SAFETY-GUIDE.md](../guides/CHEZMOI-SAFETY-GUIDE.md)
- **API Reference:** [MASTER-API-REFERENCE.md](MASTER-API-REFERENCE.md)
- **Dispatcher Guide:** [MASTER-DISPATCHER-GUIDE.md](MASTER-DISPATCHER-GUIDE.md)
- **Testing:** [TESTING.md](../guides/TESTING.md)

---

**Quick Help:**

```bash
dots help            # Show all commands
dots ignore help     # Ignore pattern help
flow doctor --help   # Doctor command help
```

**Feedback:** https://github.com/Data-Wise/flow-cli/issues
