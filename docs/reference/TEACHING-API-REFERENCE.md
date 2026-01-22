# Teaching Libraries API Reference

**Version:** flow-cli v5.15.2
**Last Updated:** 2026-01-22

This document provides complete API documentation for flow-cli's teaching workflow helper libraries. These libraries power the `teach` dispatcher and related teaching functionality.

---

## Overview

The teaching libraries provide infrastructure for:

| Library | Purpose | Functions |
|---------|---------|-----------|
| `validation-helpers.zsh` | Quarto file validation (YAML, syntax, render) | 19 |
| `backup-helpers.zsh` | Content backup and retention | 12 |
| `cache-helpers.zsh` | Freeze cache management | 11 |
| `index-helpers.zsh` | Index file link management | 12 |
| `teaching-utils.zsh` | Date/week utilities | 7 |
| **Total** | | **61** |

---

## Table of Contents

1. [Validation Helpers](#validation-helpers)
   - [Layer 1: YAML Validation](#layer-1-yaml-validation)
   - [Layer 2: Syntax Validation](#layer-2-syntax-validation)
   - [Layer 3: Render Validation](#layer-3-render-validation)
   - [Layer 4: Empty Chunks](#layer-4-empty-chunks)
   - [Layer 5: Image References](#layer-5-image-references)
   - [Watch Mode](#watch-mode)
   - [Combined Validation](#combined-validation)
   - [Performance Tracking](#performance-tracking)
2. [Backup Helpers](#backup-helpers)
   - [Backup Operations](#backup-operations)
   - [Retention Policies](#retention-policies)
   - [Delete Confirmation](#delete-confirmation)
3. [Cache Helpers](#cache-helpers)
   - [Cache Status](#cache-status)
   - [Cache Clearing](#cache-clearing)
   - [Cache Rebuilding](#cache-rebuilding)
   - [Cache Analysis](#cache-analysis)
4. [Index Helpers](#index-helpers)
   - [Dependency Tracking](#dependency-tracking)
   - [Change Detection](#change-detection)
   - [Link Management](#link-management)
   - [Interactive Management](#interactive-management)
5. [Teaching Utils](#teaching-utils)
   - [Week Calculations](#week-calculations)
   - [Date Utilities](#date-utilities)

---

## Validation Helpers

**File:** `lib/validation-helpers.zsh`

Provides granular validation layers for Quarto files, used by `teach validate` and pre-commit hooks.

### Layer 1: YAML Validation

#### `_validate_yaml`

Validate YAML frontmatter in a Quarto file.

```zsh
_validate_yaml <file> [quiet]
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `file` | string | Yes | - | Path to the Quarto file |
| `quiet` | 0\|1 | No | 0 | Suppress output if 1 |

**Returns:** 0 if valid, 1 if invalid

**Example:**
```zsh
# Basic validation
_validate_yaml "lectures/week-01.qmd"

# Quiet mode (for scripting)
if _validate_yaml "$file" 1; then
    echo "YAML is valid"
fi
```

**Performance:** ~100ms per file

---

#### `_validate_yaml_batch`

Validate YAML for multiple files.

```zsh
_validate_yaml_batch <file1> [file2] ...
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `files` | string[] | Yes | List of file paths |

**Returns:** 0 if all pass, 1 if any fail

**Example:**
```zsh
_validate_yaml_batch lectures/*.qmd
```

---

### Layer 2: Syntax Validation

#### `_validate_syntax`

Validate Quarto document syntax using `quarto inspect`.

```zsh
_validate_syntax <file> [quiet]
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `file` | string | Yes | - | Path to the Quarto file |
| `quiet` | 0\|1 | No | 0 | Suppress output if 1 |

**Returns:** 0 if valid, 1 if syntax errors

**Performance:** ~500ms per file

---

#### `_validate_syntax_batch`

Validate syntax for multiple files.

```zsh
_validate_syntax_batch <file1> [file2] ...
```

---

### Layer 3: Render Validation

#### `_validate_render`

Validate by performing a full Quarto render.

```zsh
_validate_render <file> [quiet]
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `file` | string | Yes | - | Path to the Quarto file |
| `quiet` | 0\|1 | No | 0 | Suppress output if 1 |

**Returns:** 0 if renders successfully, 1 if fails

**Performance:** 3-15s per file (depends on complexity)

**Example:**
```zsh
_validate_render "lectures/week-01.qmd"
# Output: ✓ Render valid: lectures/week-01.qmd (5s)
```

---

#### `_validate_render_batch`

Batch render validation.

```zsh
_validate_render_batch <file1> [file2] ...
```

**Environment:**
- `FLOW_MAX_PARALLEL` - Maximum workers (default: 4)

---

### Layer 4: Empty Chunks

#### `_check_empty_chunks`

Detect empty R code chunks (warning only).

```zsh
_check_empty_chunks <file> [quiet]
```

**Returns:** 0 if no empty chunks, 1 if found

**Performance:** ~50ms per file

**Notes:**
- Only checks R chunks (`\`\`\`{r ...}`)
- Chunks with only whitespace are considered empty
- macOS compatible (no Perl regex required)

---

### Layer 5: Image References

#### `_check_images`

Check for missing image references.

```zsh
_check_images <file> [quiet]
```

**Returns:** 0 if all images exist, 1 if any missing

**Performance:** ~100ms per file

**Notes:**
- Extracts `![alt](path)` markdown syntax
- Skips URL references (http://, https://)
- Resolves relative paths from file's directory

---

#### `_check_freeze_staged`

Check if `_freeze/` directory is staged for git commit.

```zsh
_check_freeze_staged [quiet]
```

**Returns:** 0 if not staged, 1 if staged

**Example:**
```zsh
# In pre-commit hook
if ! _check_freeze_staged; then
    echo "Remove _freeze/ from staging: git restore --staged _freeze/"
    exit 1
fi
```

---

### Watch Mode

#### `_is_quarto_preview_running`

Detect if `quarto preview` is currently running.

```zsh
_is_quarto_preview_running
```

**Returns:** 0 if running, 1 if not

---

#### `_get_validation_status`

Get cached validation status for a file.

```zsh
_get_validation_status <file>
```

**Output:** Status string: "pass", "fail", "pending", or "unknown"

---

#### `_update_validation_status`

Update validation status in cache.

```zsh
_update_validation_status <file> <status> [error_message]
```

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `file` | string | Yes | File path |
| `status` | string | Yes | "pass", "fail", or "pending" |
| `error_message` | string | No | Error details if status is "fail" |

---

#### `_debounce_validation`

Debounce file changes to prevent rapid re-validation.

```zsh
_debounce_validation <file> [debounce_ms]
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `file` | string | Yes | - | File path |
| `debounce_ms` | integer | No | 500 | Debounce window |

**Returns:** 0 if should validate, 1 if should wait

---

### Combined Validation

#### `_validate_file_full`

Run all validation layers for a file.

```zsh
_validate_file_full <file> [quiet] [layers]
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `file` | string | Yes | - | File path |
| `quiet` | 0\|1 | No | 0 | Suppress output |
| `layers` | string | No | "yaml,syntax,render" | Comma-separated layers |

**Available Layers:**
- `yaml` - YAML frontmatter (Layer 1)
- `syntax` - Quarto syntax (Layer 2)
- `render` - Full render (Layer 3)
- `chunks` - Empty chunks (Layer 4, warning)
- `images` - Missing images (Layer 5, warning)

**Example:**
```zsh
# Quick validation
_validate_file_full "$file" 0 "yaml,syntax"

# Full validation with all checks
_validate_file_full "$file" 0 "yaml,syntax,render,chunks,images"
```

---

#### `_find_quarto_files`

Find all Quarto files in a directory.

```zsh
_find_quarto_files [directory]
```

**Output:** One file path per line, sorted

---

#### `_get_staged_quarto_files`

Get staged Quarto files for pre-commit.

```zsh
_get_staged_quarto_files
```

**Returns:** 0 on success, 1 if not in git repo

---

### Performance Tracking

#### `_track_validation_start`

Record validation start time.

```zsh
_track_validation_start <file>
```

---

#### `_track_validation_end`

Record end time and calculate duration.

```zsh
duration=$(_track_validation_end <file>)
```

**Output:** Duration in milliseconds

---

#### `_show_validation_stats`

Display validation performance summary.

```zsh
_show_validation_stats
```

**Output:** Total time, file count, average per file

---

## Backup Helpers

**File:** `lib/backup-helpers.zsh`

Teaching content backup and retention system.

### Backup Operations

#### `_resolve_backup_path`

Resolve backup names to full paths.

```zsh
path=$(_resolve_backup_path <backup_identifier>)
```

**Input Patterns:**
1. Full absolute path
2. Relative path
3. Backup name (fuzzy search in content directories)

**Returns:** 0 on success, 1 if not found or ambiguous

**Example:**
```zsh
# By name
path=$(_resolve_backup_path "week-01.2026-01-15-1430")

# By full path
path=$(_resolve_backup_path "lectures/week-01/.backups/week-01.2026-01-15")
```

---

#### `_teach_backup_content`

Create timestamped backup of content folder.

```zsh
backup_path=$(_teach_backup_content <content_path>)
```

**Returns:** Full path to created backup

**Example:**
```zsh
backup=$(_teach_backup_content "lectures/week-01")
echo "Backed up to: $backup"
# Output: lectures/week-01/.backups/week-01.2026-01-22-1430
```

---

#### `_teach_list_backups`

List all backups for a content folder (newest first).

```zsh
_teach_list_backups <content_path>
```

---

#### `_teach_count_backups`

Count backups for a content folder.

```zsh
count=$(_teach_count_backups <content_path>)
```

---

#### `_teach_backup_size`

Get total size of backups.

```zsh
size=$(_teach_backup_size <content_path>)
# Output: "12M"
```

---

#### `_teach_delete_backup`

Delete a specific backup.

```zsh
_teach_delete_backup <backup_path> [--force]
```

**Options:**
- `--force` - Skip confirmation prompt

---

### Retention Policies

#### `_teach_get_retention_policy`

Get retention policy for content type.

```zsh
policy=$(_teach_get_retention_policy <content_type>)
```

**Content Types & Default Policies:**
| Type | Policy | Meaning |
|------|--------|---------|
| exam, quiz, assignment | archive | Keep forever |
| syllabus, rubric | archive | Keep forever |
| lecture, slides | semester | Delete at semester end |

---

#### `_teach_cleanup_backups`

Clean up backups based on retention policy.

```zsh
_teach_cleanup_backups <content_path> <content_type>
```

---

#### `_teach_archive_semester`

Archive all backups for semester-end.

```zsh
_teach_archive_semester <semester_name>
```

**Example:**
```zsh
_teach_archive_semester "fall-2026"
# Creates: .flow/archives/fall-2026/
```

---

### Delete Confirmation

#### `_teach_confirm_delete`

Interactive confirmation before deleting backup.

```zsh
if _teach_confirm_delete <backup_path>; then
    rm -rf "$backup_path"
fi
```

---

#### `_teach_preview_cleanup`

Preview what would be cleaned up (dry run).

```zsh
_teach_preview_cleanup <content_path> <content_type>
```

---

## Cache Helpers

**File:** `lib/cache-helpers.zsh`

Quarto freeze cache management utilities.

### Cache Status

#### `_cache_status`

Get comprehensive freeze cache status.

```zsh
info=$(_cache_status [project_root])
eval "$info"
echo "$size_human ($file_count files)"
```

**Output Variables:**
- `cache_status` - "none" or "exists"
- `size` - Size in bytes
- `size_human` - Human-readable size
- `file_count` - Number of cached files
- `last_render` - Time ago string
- `last_render_timestamp` - Unix timestamp

---

#### `_cache_format_time_ago`

Format timestamp as human-readable "time ago".

```zsh
_cache_format_time_ago <timestamp>
# Output: "5 minutes ago", "2 days ago", etc.
```

---

#### `_cache_format_bytes`

Format bytes to human-readable size.

```zsh
_cache_format_bytes 5242880
# Output: "5MB"
```

---

#### `_cache_is_freeze_enabled`

Check if project has freeze caching enabled.

```zsh
if _cache_is_freeze_enabled; then
    echo "Freeze is enabled"
fi
```

---

### Cache Clearing

#### `_cache_clear`

Clear the entire freeze cache.

```zsh
_cache_clear [project_root] [--force]
```

**Options:**
- `--force` - Skip confirmation

---

#### `_clear_cache_selective`

Clear cache selectively by type or age.

```zsh
_clear_cache_selective [project_root] [options]
```

**Options:**
| Flag | Description |
|------|-------------|
| `--lectures` | Clear lectures/ cache |
| `--assignments` | Clear assignments/ cache |
| `--slides` | Clear slides/ cache |
| `--old` | Files older than 30 days |
| `--unused` | Files with 0 cache hits (placeholder) |
| `--force` | Skip confirmation |

**Example:**
```zsh
_clear_cache_selective --lectures --old --force
```

---

### Cache Rebuilding

#### `_cache_rebuild`

Clear cache and re-render entire project.

```zsh
_cache_rebuild [project_root]
```

**Performance:** 30-60+ seconds for large projects

---

### Cache Analysis

#### `_cache_analyze`

Detailed cache breakdown by directory and age.

```zsh
_cache_analyze [project_root]
```

**Output:**
- Overall status (size, files, last render)
- Breakdown by content directory
- Age distribution (hour/day/week/older)

---

#### `_cache_clean`

Clean both `_freeze/` and `_site/` directories.

```zsh
_cache_clean [project_root] [--force]
```

---

## Index Helpers

**File:** `lib/index-helpers.zsh`

Index file link management for teaching content.

### Dependency Tracking

#### `_find_dependencies`

Find all file dependencies for a Quarto document.

```zsh
deps=$(_find_dependencies <file>)
```

**Dependency Types:**
- R source files: `source("path/to/file.R")`
- Cross-references: `@sec-id`, `@fig-id`, `@tbl-id`

---

#### `_validate_cross_references`

Validate cross-references have valid targets.

```zsh
_validate_cross_references <file1> [file2] ...
```

**Returns:** 0 if all valid, 1 if broken references

---

### Change Detection

#### `_detect_index_changes`

Detect what index change is needed for a file.

```zsh
change=$(_detect_index_changes <file>)
# Output: "ADD", "UPDATE", "REMOVE", or "NONE"
```

---

#### `_extract_title`

Extract title from YAML frontmatter.

```zsh
title=$(_extract_title <file>)
```

---

#### `_parse_week_number`

Parse week number from filename.

```zsh
week=$(_parse_week_number "week-05-regression.qmd")
# Output: 5
```

**Supported Patterns:**
- `week-05.qmd` → 5
- `lecture-week05.qmd` → 5
- `05-topic.qmd` → 5

---

### Link Management

#### `_update_index_link`

Add or update a link in an index file.

```zsh
_update_index_link <content_file> <index_file>
```

**Features:**
- Auto-sorts by week number
- Extracts title from frontmatter
- Updates existing or inserts new

---

#### `_find_insertion_point`

Find correct line for week-sorted insertion.

```zsh
line=$(_find_insertion_point <index_file> <week_num>)
```

---

#### `_remove_index_link`

Remove a link from an index file.

```zsh
_remove_index_link <content_file> <index_file>
```

---

#### `_get_index_file`

Get corresponding index file for content.

```zsh
index=$(_get_index_file "lectures/week-05.qmd")
# Output: "home_lectures.qmd"
```

**Mapping:**
| Directory | Index File |
|-----------|------------|
| lectures/* | home_lectures.qmd |
| labs/* | home_labs.qmd |
| exams/* | home_exams.qmd |

---

### Interactive Management

#### `_prompt_index_action`

Interactive prompt for index actions.

```zsh
if _prompt_index_action "ADD" <file> "" <new_title>; then
    _update_index_link "$file" "$index"
fi
```

| Action | Default | Display |
|--------|---------|---------|
| ADD | Yes | New content detected |
| UPDATE | No | Old vs new title comparison |
| REMOVE | Yes | Deleted content warning |

---

#### `_process_index_changes`

Process all index changes for deployment.

```zsh
_process_index_changes <file1> [file2] ...
```

---

## Teaching Utils

**File:** `lib/teaching-utils.zsh`

Date and week calculation utilities for teaching workflow.

### Week Calculations

#### `_calculate_current_week`

Calculate current week number from semester start.

```zsh
week=$(_calculate_current_week <config_file>)
```

**Returns:**
- 1-16: Week number
- 0: Before semester start
- empty: No date configured

**Config Format:**
```yaml
semester_info:
  start_date: "2026-01-15"
```

---

#### `_is_break_week`

Check if week is during a scheduled break.

```zsh
if break_name=$(_is_break_week <config_file> <week>); then
    echo "Week $week is $break_name"
fi
```

**Config Format:**
```yaml
semester_info:
  breaks:
    - name: "Spring Break"
      start: "2026-03-09"
      end: "2026-03-13"
```

---

#### `_date_to_week`

Convert date to week number.

```zsh
week=$(_date_to_week <config_file> "2026-03-15")
```

---

### Date Utilities

#### `_validate_date_format`

Validate YYYY-MM-DD date format.

```zsh
if _validate_date_format "2026-02-30"; then
    echo "Valid"
else
    echo "Invalid"  # Feb 30 doesn't exist
fi
```

---

#### `_calculate_semester_end`

Calculate semester end (16 weeks from start).

```zsh
end=$(_calculate_semester_end "2026-01-15")
# Output: "2026-05-06"
```

---

#### `_suggest_semester_start`

Suggest semester start date based on current month.

```zsh
suggested=$(_suggest_semester_start)
```

**Suggestions:**
| Month | Suggested |
|-------|-----------|
| Aug-Dec | Aug 20 (Fall) |
| Jan-May | Jan 15 (Spring) |
| Jun-Jul | Jun 1 (Summer) |

---

## Common Patterns

### Validation Workflow

```zsh
# Quick check before commit
files=$(_get_staged_quarto_files)
for file in $files; do
    _validate_file_full "$file" 0 "yaml,syntax"
done

# Full validation with tracking
_track_validation_start "$file"
_validate_file_full "$file" 0 "yaml,syntax,render,chunks,images"
_track_validation_end "$file"
_show_validation_stats
```

### Backup Workflow

```zsh
# Create backup before editing
backup=$(_teach_backup_content "exams/midterm")

# List backups
_teach_list_backups "exams/midterm"

# Archive at semester end
_teach_archive_semester "spring-2026"
```

### Cache Management

```zsh
# Check status
info=$(_cache_status)
eval "$info"
echo "Cache: $size_human"

# Clear old cache
_clear_cache_selective --old --force

# Full rebuild
_cache_rebuild
```

### Index Management

```zsh
# Process changes during deployment
changed=($(git diff --name-only HEAD~1))
_process_index_changes "${changed[@]}"

# Manual link update
_update_index_link "lectures/week-05.qmd" "home_lectures.qmd"
```

---

## See Also

- [Core API Reference](CORE-API-REFERENCE.md) - Core utilities and TUI functions
- [TEACH Dispatcher Reference](TEACH-DISPATCHER-REFERENCE-v3.0.md) - User-facing teach commands
- [Documentation Coverage](DOCUMENTATION-COVERAGE.md) - Coverage metrics
- [Architecture Overview](ARCHITECTURE-OVERVIEW.md) - System architecture

---

**Generated:** 2026-01-22
**Author:** Claude Opus 4.5
