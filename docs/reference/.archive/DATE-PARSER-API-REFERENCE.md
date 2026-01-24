# Date Parser API Reference

**Module:** `lib/date-parser.zsh`
**Version:** v5.11.0
**Status:** Complete
**Last Updated:** 2026-01-16

---

## Overview

The date parser module provides 8 core functions for extracting, normalizing, computing, and applying dates across teaching workflow files. All functions follow ZSH conventions and return status codes (0 = success, 1 = error).

**Primary Use Cases:**
- Extract dates from Quarto YAML frontmatter
- Find inline dates in Markdown prose
- Normalize various date formats to ISO-8601
- Compute relative dates (week + offset)
- Apply date changes to files safely

---

## Function Index

| Function | Purpose | Returns |
|----------|---------|---------|
| [`_date_parse_quarto_yaml`](#_date_parse_quarto_yaml) | Extract date from YAML field | ISO date string |
| [`_date_parse_markdown_inline`](#_date_parse_markdown_inline) | Find inline dates in Markdown | Array of line:date |
| [`_date_normalize`](#_date_normalize) | Convert any format to ISO | ISO date string |
| [`_date_compute_from_week`](#_date_compute_from_week) | Calculate week + offset | ISO date string |
| [`_date_add_days`](#_date_add_days) | Date arithmetic | ISO date string |
| [`_date_find_teaching_files`](#_date_find_teaching_files) | Discover teaching files | File paths array |
| [`_date_load_config`](#_date_load_config) | Load all config dates | Shell code for eval |
| [`_date_apply_to_file`](#_date_apply_to_file) | Apply date changes | 0/1 status code |

---

## Constants & Configuration

### Global Variables

```zsh
# Month abbreviation mapping (associative array)
typeset -gA MONTH_ABBREV=(
  [Jan]=01 [January]=01
  [Feb]=02 [February]=02
  [Mar]=03 [March]=03
  [Apr]=04 [April]=04
  [May]=05 [May]=05
  [Jun]=06 [June]=06
  [Jul]=07 [July]=07
  [Aug]=08 [August]=08
  [Sep]=09 [September]=09
  [Oct]=10 [October]=10
  [Nov]=11 [November]=11
  [Dec]=12 [December]=12
)

# Date regex patterns
typeset -g ISO_DATE_PATTERN='[0-9]{4}-[0-9]{2}-[0-9]{2}'
typeset -g US_DATE_PATTERN='[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}'
typeset -g ABBREV_DATE_PATTERN='(Jan|Feb|...|Dec) [0-9]{1,2}'
```

**Usage:**

```zsh
# Access month number
local month_num="${MONTH_ABBREV[Jan]}"  # → "01"

# Use pattern for validation
[[ "$date" =~ $ISO_DATE_PATTERN ]] && echo "Valid ISO date"
```

---

## Function Reference

### `_date_parse_quarto_yaml`

Extract a date value from Quarto YAML frontmatter.

#### Signature

```zsh
_date_parse_quarto_yaml <file> <field>
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `file` | string | ✅ | Path to Quarto/Markdown file |
| `field` | string | ✅ | YAML field name (e.g., "due", "date") |

#### Returns

- **Success (0):** Prints ISO date to stdout
- **Failure (1):** Returns empty string

#### Behavior

1. Validates file exists and field is non-empty
2. Uses `yq` to extract YAML field value
3. Skips dynamic values (`last-modified`, `today`, `now`)
4. Normalizes extracted date to ISO format
5. Returns empty string if field not found or null

#### Examples

```zsh
# Basic usage
local due_date=$(_date_parse_quarto_yaml "assignments/hw1.qmd" "due")
echo "$due_date"  # → "2025-01-22"

# Check for success
if _date_parse_quarto_yaml "file.qmd" "date" >/dev/null 2>&1; then
    echo "Date field exists"
fi

# Multiple fields
local published=$(_date_parse_quarto_yaml "post.qmd" "published")
local modified=$(_date_parse_quarto_yaml "post.qmd" "modified")
```

#### Error Handling

```zsh
# Missing file
_date_parse_quarto_yaml "nonexistent.qmd" "due"
# Returns: 1, prints nothing

# Missing field
_date_parse_quarto_yaml "file.qmd" ""
# Returns: 1, prints nothing

# Field is null
# YAML: due: null
_date_parse_quarto_yaml "file.qmd" "due"
# Returns: 0, prints nothing

# yq not installed
_date_parse_quarto_yaml "file.qmd" "due"
# Returns: 1, stderr: "ERROR: yq required for YAML parsing"
```

#### Dependencies

- `yq` ≥ 4.0 (YAML processor)
- `_date_normalize` (date normalization)

#### See Also

- [`_date_normalize`](#_date_normalize) - Date format conversion
- [`_date_parse_markdown_inline`](#_date_parse_markdown_inline) - Find dates in prose

---

### `_date_parse_markdown_inline`

Find all inline dates in Markdown content.

#### Signature

```zsh
_date_parse_markdown_inline <file> [pattern]
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `file` | string | ✅ | Path to Markdown/Quarto file |
| `pattern` | string | ❌ | Optional grep pattern (default: month names) |

#### Returns

- **Success (0):** Prints array of "line_number:date" (one per line)
- **Failure (1):** Returns empty

#### Behavior

1. Validates file exists
2. Builds grep pattern (default: month names + day)
3. Scans file line-by-line for dates
4. Extracts and normalizes each date found
5. Returns line numbers with ISO dates

#### Examples

```zsh
# Find all dates
_date_parse_markdown_inline "syllabus.qmd"
# Output:
# 23:2025-01-13
# 45:2025-01-22
# 67:2025-02-05

# Find dates matching pattern
_date_parse_markdown_inline "schedule.qmd" "Week [0-9]+"
# Output:
# 10:2025-01-13
# 15:2025-01-20

# Store in array
local -a date_lines
while IFS= read -r line; do
    date_lines+=("$line")
done < <(_date_parse_markdown_inline "file.qmd")

for entry in "${date_lines[@]}"; do
    local line_num="${entry%%:*}"
    local date="${entry#*:}"
    echo "Line $line_num has date: $date"
done
```

#### Supported Date Patterns

| Format | Example | Regex |
|--------|---------|-------|
| Long form | "January 22, 2025" | `(January|...) [0-9]{1,2}, [0-9]{4}` |
| Abbreviated | "Jan 22, 2025" | `(Jan|...) [0-9]{1,2}, [0-9]{4}` |
| Short form | "Jan 22" | `(Jan|...) [0-9]{1,2}` (infers year) |
| ISO | "2025-01-22" | `[0-9]{4}-[0-9]{2}-[0-9]{2}` |
| US | "1/22/2025" | `[0-9]{1,2}/[0-9]{1,2}/[0-9]{4}` |

#### Error Handling

```zsh
# Missing file
_date_parse_markdown_inline "nonexistent.qmd"
# Returns: 1, prints nothing

# No dates found
_date_parse_markdown_inline "file-without-dates.qmd"
# Returns: 0, prints nothing (empty array)

# Invalid pattern (grep error)
_date_parse_markdown_inline "file.qmd" "["
# Returns: grep error, prints nothing
```

#### Performance

- Scans entire file line-by-line
- Normalizes each date found (uses `_date_extract_from_line`)
- For 100-line file with 10 dates: ~50ms

#### See Also

- [`_date_extract_from_line`](#helper-functions) - Extract date from text
- [`_date_normalize`](#_date_normalize) - Normalize extracted dates

---

### `_date_normalize`

Convert any date format to ISO-8601 (YYYY-MM-DD).

#### Signature

```zsh
_date_normalize <date_string>
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `date_string` | string | ✅ | Date in any supported format |

#### Returns

- **Success (0):** Prints ISO date (YYYY-MM-DD)
- **Failure (1):** Returns empty if format unrecognized

#### Supported Formats

| Input Format | Example | Output |
|--------------|---------|--------|
| ISO-8601 | `2025-01-22` | `2025-01-22` (passthrough) |
| US short | `1/22/2025` | `2025-01-22` |
| US long | `January 22, 2025` | `2025-01-22` |
| Abbreviated | `Jan 22, 2025` | `2025-01-22` |
| Abbreviated (no year) | `Jan 22` | `2025-01-22` (infers current year) |

#### Examples

```zsh
# ISO (already normalized)
_date_normalize "2025-01-22"
# → "2025-01-22"

# US format
_date_normalize "1/22/2025"
# → "2025-01-22"

# Long form
_date_normalize "January 22, 2025"
# → "2025-01-22"

# Abbreviated
_date_normalize "Jan 22, 2025"
# → "2025-01-22"

# Abbreviated (infers year)
_date_normalize "Jan 22"
# → "2025-01-22" (if current year is 2025)

# Use in validation
if normalized_date=$(_date_normalize "$user_input"); then
    echo "Valid date: $normalized_date"
else
    echo "Invalid date format"
fi
```

#### Year Inference

When year is omitted (e.g., "Jan 22"), the function infers the current year:

```zsh
# If current year is 2025:
_date_normalize "Jan 22"      # → "2025-01-22"
_date_normalize "Dec 31"      # → "2025-12-31"
```

#### Error Handling

```zsh
# Empty input
_date_normalize ""
# Returns: 1, prints nothing

# Unrecognized format
_date_normalize "22nd of January"
# Returns: 1, prints nothing

# Invalid date values (month/day out of range)
_date_normalize "13/40/2025"  # Invalid month/day
# Returns: 1, prints nothing (regex fails)
```

#### Implementation Details

The function uses regex matching with ZSH's `=~` operator and `$match` array for capture groups:

```zsh
# ISO format check
if [[ "$date_string" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})$ ]]; then
    echo "$date_string"
    return 0
fi

# Month name extraction
if [[ "$date_string" =~ (January|...|Dec)[[:space:]]+([0-9]{1,2}) ]]; then
    local month_str="${match[1]}"
    local day="${match[2]}"
    local month_num="${MONTH_ABBREV[$month_str]}"
    printf "%04d-%02d-%02d\n" "$year" "$month_num" "$day"
fi
```

#### See Also

- [`MONTH_ABBREV`](#global-variables) - Month name to number mapping
- [`_date_parse_quarto_yaml`](#_date_parse_quarto_yaml) - Uses normalization
- [`_date_parse_markdown_inline`](#_date_parse_markdown_inline) - Uses normalization

---

### `_date_compute_from_week`

Compute an ISO date from a week number and day offset.

#### Signature

```zsh
_date_compute_from_week <week_num> <offset_days> [config_file]
```

#### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `week_num` | integer | ✅ | - | Week number (1-52) |
| `offset_days` | integer | ✅ | - | Days offset from week start (can be negative) |
| `config_file` | string | ❌ | `.flow/teach-config.yml` | Path to config file |

#### Returns

- **Success (0):** Prints computed ISO date
- **Failure (1):** Returns empty with error message to stderr

#### Behavior

1. Validates week_num and offset_days are integers
2. Validates config file exists
3. Uses `yq` to extract week start_date from config
4. Calls `_date_add_days` to compute final date
5. Returns ISO date

#### Examples

```zsh
# Basic usage (Week 2 + 2 days)
_date_compute_from_week 2 2
# → "2025-01-22" (if Week 2 starts 2025-01-20)

# Custom config path
_date_compute_from_week 3 4 ".flow/teach-config.yml"
# → "2025-01-31"

# Negative offset (before week start)
_date_compute_from_week 5 -2
# → "2025-02-08" (if Week 5 starts 2025-02-10)

# Store result
local hw_due_date=$(_date_compute_from_week 3 4)
yq eval ".deadlines.hw3.due_date = \"$hw_due_date\"" -i config.yml
```

#### Config Schema

Config must have `semester_info.weeks` array:

```yaml
semester_info:
  weeks:
    - number: 1
      start_date: "2025-01-13"
    - number: 2
      start_date: "2025-01-20"
    # ... etc
```

#### Error Handling

```zsh
# Invalid week number
_date_compute_from_week "abc" 2
# stderr: "ERROR: Invalid week number: abc"
# Returns: 1

# Invalid offset
_date_compute_from_week 2 "two"
# stderr: "ERROR: Invalid offset days: two"
# Returns: 1

# Missing config
_date_compute_from_week 2 2 "nonexistent.yml"
# stderr: "ERROR: Config file not found: nonexistent.yml"
# Returns: 1

# Week not found in config
_date_compute_from_week 99 2
# stderr: "ERROR: Week 99 not found in config"
# Returns: 1
```

#### Use Cases

**Relative deadline computation:**

```zsh
# All assignments due on Fridays (week start + 4 days)
for week in {2..10}; do
    local due_date=$(_date_compute_from_week $week 4)
    echo "HW $((week-1)) due: $due_date"
done
```

**Deadline before week start:**

```zsh
# Reading due Sunday before week 5
local reading_due=$(_date_compute_from_week 5 -1)
echo "Reading due: $reading_due"  # → Sunday before Week 5
```

#### Dependencies

- `yq` ≥ 4.0 (YAML query)
- `_date_add_days` (date arithmetic)
- Valid `teach-config.yml` with weeks array

#### See Also

- [`_date_add_days`](#_date_add_days) - Date arithmetic backend
- [`_date_load_config`](#_date_load_config) - Load all config dates

---

### `_date_add_days`

Add (or subtract) days from a date. Cross-platform (GNU date / BSD date).

#### Signature

```zsh
_date_add_days <base_date> <days>
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `base_date` | string | ✅ | ISO date (YYYY-MM-DD) |
| `days` | integer | ✅ | Days to add (negative to subtract) |

#### Returns

- **Success (0):** Prints new ISO date
- **Failure (1):** Returns empty with error to stderr

#### Behavior

1. Validates base_date is ISO format
2. Detects GNU date vs BSD date
3. Performs date arithmetic
4. Returns new date in ISO format

#### Platform Support

| Platform | date Command | Syntax |
|----------|--------------|--------|
| Linux | GNU date | `date -d "2025-01-20 + 2 days" +%Y-%m-%d` |
| macOS | BSD date | `date -v+2d -j -f "%Y-%m-%d" "2025-01-20" +%Y-%m-%d` |
| Windows (WSL) | GNU date | Same as Linux |

The function automatically detects which version is available.

#### Examples

```zsh
# Add days
_date_add_days "2025-01-20" 2
# → "2025-01-22"

# Subtract days
_date_add_days "2025-01-20" -2
# → "2025-01-18"

# Cross month boundary
_date_add_days "2025-01-28" 5
# → "2025-02-02"

# Cross year boundary
_date_add_days "2024-12-30" 5
# → "2025-01-04"

# Leap year handling
_date_add_days "2024-02-28" 1
# → "2024-02-29" (2024 is leap year)

_date_add_days "2025-02-28" 1
# → "2025-03-01" (2025 is not leap year)

# Use in loops
local current_date="2025-01-01"
for i in {1..5}; do
    current_date=$(_date_add_days "$current_date" 7)
    echo "Week $i: $current_date"
done
```

#### Error Handling

```zsh
# Invalid date format
_date_add_days "01/20/2025" 2
# stderr: "ERROR: Invalid date format: 01/20/2025 (expected YYYY-MM-DD)"
# Returns: 1

# Non-integer days
_date_add_days "2025-01-20" "two"
# Returns: 1 (caught by ZSH integer check)

# Invalid date (e.g., Feb 30)
_date_add_days "2025-02-30" 1
# Returns: 1 (date command error)
```

#### Implementation Details

**Platform detection:**

```zsh
if date --version >/dev/null 2>&1; then
    # GNU date
    date -d "$base_date + $days days" +%Y-%m-%d
else
    # BSD date (macOS)
    if [[ "$days" -lt 0 ]]; then
        abs_days=$(( -days ))
        date -v-${abs_days}d -j -f "%Y-%m-%d" "$base_date" +%Y-%m-%d
    else
        date -v+${days}d -j -f "%Y-%m-%d" "$base_date" +%Y-%m-%d
    fi
fi
```

#### Performance

- Operation time: < 5ms (subprocess call to `date`)
- No heavy computation (delegates to system date command)

#### See Also

- [`_date_compute_from_week`](#_date_compute_from_week) - Uses this for offset calculation
- [GNU date documentation](https://www.gnu.org/software/coreutils/manual/html_node/date-invocation.html)
- [BSD date documentation](https://www.freebsd.org/cgi/man.cgi?query=date)

---

### `_date_find_teaching_files`

Find all Quarto/Markdown teaching files in a project.

#### Signature

```zsh
_date_find_teaching_files [path]
```

#### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `path` | string | ❌ | `.` (current dir) | Base directory to search |

#### Returns

- **Success (0):** Prints array of file paths (one per line), sorted
- **Failure (1):** Returns empty if no files found

#### Behavior

1. Searches teaching directories: `assignments/`, `lectures/`, `exams/`, `quizzes/`, `slides/`, `rubrics/`, `syllabus/`
2. Searches root for: `syllabus.qmd`, `schedule.qmd`, `index.qmd`, `README.md`
3. Finds `.qmd` and `.md` files (max depth 2)
4. Returns unique, sorted file list

#### Directory Structure

```
teaching-project/
├── assignments/
│   ├── hw1.qmd          ← Found
│   ├── hw2.qmd          ← Found
│   └── solutions/
│       └── sol1.qmd     ← Found (depth 2)
├── lectures/
│   ├── week01.qmd       ← Found
│   └── week02.qmd       ← Found
├── exams/
│   └── midterm.qmd      ← Found
├── syllabus.qmd         ← Found (root)
├── schedule.qmd         ← Found (root)
└── README.md            ← Found (root)
```

#### Examples

```zsh
# Find all teaching files
_date_find_teaching_files
# Output:
# ./assignments/hw1.qmd
# ./assignments/hw2.qmd
# ./lectures/week01.qmd
# ./lectures/week02.qmd
# ./exams/midterm.qmd
# ./syllabus.qmd
# ./schedule.qmd
# ./README.md

# Find in specific directory
_date_find_teaching_files "~/teaching/stat-545"
# Output: (absolute paths from stat-545)

# Store in array
local -a files
while IFS= read -r file; do
    files+=("$file")
done < <(_date_find_teaching_files)

echo "Found ${#files[@]} teaching files"
```

#### Search Depth

- Teaching directories: Max depth 2
  - `assignments/hw1.qmd` ✅ (depth 1)
  - `assignments/week1/hw1.qmd` ✅ (depth 2)
  - `assignments/week1/drafts/hw1.qmd` ❌ (depth 3)

#### Exclusions

- Non-Quarto/Markdown files (`.txt`, `.pdf`, etc.)
- Hidden directories (`.git/`, `.cache/`)
- Build artifacts (`_site/`, `_freeze/`)

#### Performance

- For 50 files across 5 directories: ~20ms
- Uses `find` command (efficient for large repos)
- No recursive file reading (just path collection)

#### Use Cases

**Batch date extraction:**

```zsh
local -a files
while IFS= read -r file; do
    files+=("$file")
done < <(_date_find_teaching_files)

for file in "${files[@]}"; do
    local due_date=$(_date_parse_quarto_yaml "$file" "due" 2>/dev/null)
    [[ -n "$due_date" ]] && echo "$file: $due_date"
done
```

**File filtering:**

```zsh
# Find only assignment files
_date_find_teaching_files | grep "assignments/"

# Find only lectures
_date_find_teaching_files | grep "lectures/"
```

#### See Also

- [`_date_parse_quarto_yaml`](#_date_parse_quarto_yaml) - Parse found files
- [`_date_parse_markdown_inline`](#_date_parse_markdown_inline) - Scan found files

---

### `_date_load_config`

Load all dates from teach-config.yml into shell variables.

#### Signature

```zsh
_date_load_config [config_file]
```

#### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `config_file` | string | ❌ | `.flow/teach-config.yml` | Path to config |

#### Returns

- **Success (0):** Prints shell code for `eval` (sets CONFIG_DATES array)
- **Failure (1):** Prints comment with error to stderr

#### Behavior

1. Validates config file exists
2. Validates `yq` is installed
3. Loads weeks → `CONFIG_DATES[week_N]`
4. Loads exams → `CONFIG_DATES[exam_<name>]`
5. Loads deadlines (absolute + relative) → `CONFIG_DATES[deadline_<id>]`
6. Loads holidays → `CONFIG_DATES[holiday_<name>]`
7. Prints shell code to set associative array

#### Usage Pattern

```zsh
# Load config dates into CONFIG_DATES array
declare -A CONFIG_DATES
eval "$(_date_load_config)"

# Access dates
echo "${CONFIG_DATES[week_1]}"        # → "2025-01-13"
echo "${CONFIG_DATES[deadline_hw1]}"  # → "2025-01-22"
echo "${CONFIG_DATES[exam_midterm]}"  # → "2025-03-05"
```

#### Output Format

```zsh
# Example output (for eval):
CONFIG_DATES[week_1]="2025-01-13"
CONFIG_DATES[week_2]="2025-01-20"
CONFIG_DATES[deadline_hw1]="2025-01-22"
CONFIG_DATES[deadline_hw2]="2025-02-05"
CONFIG_DATES[exam_midterm]="2025-03-05"
CONFIG_DATES[holiday_spring_break]="2025-03-10"
```

#### Config Structure

**Input (YAML):**

```yaml
semester_info:
  weeks:
    - number: 1
      start_date: "2025-01-13"
    - number: 2
      start_date: "2025-01-20"

  deadlines:
    hw1:
      week: 2
      offset_days: 2       # Computed to "2025-01-22"
    hw2:
      due_date: "2025-02-05"  # Absolute

  exams:
    - name: "Midterm"
      date: "2025-03-05"

  holidays:
    - name: "Spring Break"
      date: "2025-03-10"
```

**Output (Shell):**

```zsh
CONFIG_DATES[week_1]="2025-01-13"
CONFIG_DATES[week_2]="2025-01-20"
CONFIG_DATES[deadline_hw1]="2025-01-22"    # Computed
CONFIG_DATES[deadline_hw2]="2025-02-05"    # Absolute
CONFIG_DATES[exam_midterm]="2025-03-05"
CONFIG_DATES[holiday_spring_break]="2025-03-10"
```

#### Key Naming Convention

| Config Type | Key Format | Example |
|-------------|------------|---------|
| Week | `week_N` | `week_1`, `week_2` |
| Deadline | `deadline_<id>` | `deadline_hw1` |
| Exam | `exam_<name>` | `exam_midterm` |
| Holiday | `holiday_<name>` | `holiday_spring_break` |

Names are normalized:
- Lowercase
- Spaces → underscores
- Example: "Spring Break" → `spring_break`

#### Error Handling

```zsh
# Missing config
eval "$(_date_load_config "nonexistent.yml")"
# stderr: "# ERROR: Config file not found: nonexistent.yml"
# CONFIG_DATES remains empty

# Missing yq
eval "$(_date_load_config)"
# stderr: "# ERROR: yq required. Install: brew install yq"
# CONFIG_DATES remains empty

# Malformed YAML
eval "$(_date_load_config "bad.yml")"
# yq errors printed to stderr
# Partial CONFIG_DATES may be set
```

#### Use Cases

**Date sync workflow:**

```zsh
# Load config dates
declare -A CONFIG_DATES
eval "$(_date_load_config)"

# Compare against file dates
local file_date=$(_date_parse_quarto_yaml "hw1.qmd" "due")
local config_date="${CONFIG_DATES[deadline_hw1]}"

if [[ "$file_date" != "$config_date" ]]; then
    echo "Mismatch: $file_date vs $config_date"
fi
```

**List all dates:**

```zsh
declare -A CONFIG_DATES
eval "$(_date_load_config)"

for key in "${(@k)CONFIG_DATES}"; do
    echo "$key: ${CONFIG_DATES[$key]}"
done
```

#### Dependencies

- `yq` ≥ 4.0 (YAML parsing)
- `_date_compute_from_week` (for relative dates)

#### See Also

- [`_date_compute_from_week`](#_date_compute_from_week) - Compute relative dates
- [`teach-config.yml schema`](TEACH-CONFIG-DATES-SCHEMA.md) - Config structure

---

### `_date_apply_to_file`

Apply date changes to a file (YAML frontmatter and inline content).

#### Signature

```zsh
_date_apply_to_file <file> <changes...>
```

#### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `file` | string | ✅ | Path to file to modify |
| `changes...` | array | ✅ | Array of "field:old_date:new_date" strings |

#### Returns

- **Success (0):** File modified, backup removed
- **Failure (1):** File unchanged, backup preserved

#### Behavior

1. Validates file exists
2. Creates backup (`file.bak`)
3. For each change:
   - Updates YAML field using `yq`
   - Replaces inline occurrences using `sed`
   - Handles multiple date formats (ISO, US, long)
4. Removes backup on success
5. Restores from backup on error

#### Change Format

```zsh
# Format: "field:old_date:new_date"
"due:2025-01-20:2025-01-22"
"published:2025-01-15:2025-01-18"
```

#### Examples

```zsh
# Single change
_date_apply_to_file "hw1.qmd" "due:2025-01-20:2025-01-22"

# Multiple changes
local -a changes=(
    "due:2025-01-20:2025-01-22"
    "published:2025-01-15:2025-01-18"
)
_date_apply_to_file "file.qmd" "${changes[@]}"

# Check for success
if _date_apply_to_file "file.qmd" "due:old:new"; then
    echo "✓ File updated"
else
    echo "✗ Update failed (restored from backup)"
fi
```

#### What Gets Modified

**YAML frontmatter:**

```yaml
---
due: "2025-01-20"    # ← Updated to 2025-01-22
---
```

**Inline dates (multiple formats):**

```markdown
Due date: 2025-01-20          # ← Updated (ISO)
Due: 1/20/2025                # ← Updated (US)
Assignment due January 20, 2025   # ← Updated (long form)
```

#### Backup Strategy

```zsh
# Before modification
cp file.qmd file.qmd.bak

# If modification succeeds
rm file.qmd.bak

# If modification fails
mv file.qmd.bak file.qmd  # Restore original
```

#### Error Handling

```zsh
# Missing file
_date_apply_to_file "nonexistent.qmd" "due:old:new"
# stderr: "ERROR: File not found: nonexistent.qmd"
# Returns: 1

# Backup creation fails
# (e.g., no write permissions)
_date_apply_to_file "readonly.qmd" "due:old:new"
# stderr: "ERROR: Failed to create backup: readonly.qmd.bak"
# Returns: 1

# yq/sed errors
# (malformed YAML, sed syntax error)
_date_apply_to_file "file.qmd" "invalid_change"
# File restored from backup
# Returns: 1
```

#### Safety Features

1. **Atomic operations:** Backup before modification
2. **Rollback:** Restore from backup on any error
3. **Validation:** Check file exists before starting
4. **Logging:** Uses `_flow_log_success` if available

#### Format Conversion

The function converts ISO dates to multiple formats for replacement:

```zsh
# Input: "due:2025-01-20:2025-01-22"

# Replaces all these formats:
2025-01-20            → 2025-01-22          # ISO
1/20/2025             → 1/22/2025           # US short
January 20, 2025      → January 22, 2025    # Long form
```

#### Performance

- Small file (< 100 lines): ~10ms
- Large file (1000+ lines): ~50ms
- Depends on: Number of replacements, file size

#### Dependencies

- `yq` ≥ 4.0 (YAML modification)
- `sed` (content replacement)
- `_flow_log_success` (optional logging)

#### See Also

- [`_date_parse_quarto_yaml`](#_date_parse_quarto_yaml) - Extract dates before applying
- [`_date_normalize`](#_date_normalize) - Normalize dates for comparison

---

## Helper Functions

### `_date_extract_from_line`

**Internal helper** - Extract first date from a text line.

#### Signature

```zsh
_date_extract_from_line <line>
```

#### Behavior

Tries multiple patterns in order:
1. ISO date (`2025-01-22`)
2. Long/abbreviated month + day + year (`January 22, 2025`, `Jan 22, 2025`)
3. Long/abbreviated month + day (infers year) (`Jan 22`)
4. US format (`1/22/2025`)

Returns first match found, normalized to ISO.

#### Example

```zsh
# Internal use only (called by _date_parse_markdown_inline)
_date_extract_from_line "Due date: January 22, 2025"
# → "2025-01-22"
```

---

## Type Definitions

### Date String Formats

```zsh
# ISO Date (YYYY-MM-DD)
typeset ISO_DATE="2025-01-22"

# US Short (M/D/YYYY or MM/DD/YYYY)
typeset US_DATE="1/22/2025"

# Long Form (Month Day, Year)
typeset LONG_DATE="January 22, 2025"

# Abbreviated (Mon Day, Year)
typeset ABBREV_DATE="Jan 22, 2025"

# Abbreviated (Mon Day) - infers year
typeset SHORT_ABBREV="Jan 22"
```

### Return Values

```zsh
# Success (0)
_date_normalize "2025-01-22" && echo "Valid"

# Failure (1)
_date_normalize "invalid" || echo "Invalid"

# Status code usage
if _date_parse_quarto_yaml "file.qmd" "due" >/dev/null 2>&1; then
    echo "Field exists"
fi
```

---

## Error Messages

| Error | Function | Meaning | Action |
|-------|----------|---------|--------|
| `ERROR: yq required` | `_date_parse_quarto_yaml` | yq not installed | Install yq: `brew install yq` |
| `ERROR: Invalid week number` | `_date_compute_from_week` | Non-integer week | Use integer (1-52) |
| `ERROR: Week N not found` | `_date_compute_from_week` | Week missing from config | Add week to config |
| `ERROR: File not found` | `_date_apply_to_file` | File doesn't exist | Check file path |
| `ERROR: Invalid date format` | `_date_add_days` | Date not ISO | Use YYYY-MM-DD format |

---

## Performance Characteristics

| Function | Time (avg) | Depends On |
|----------|-----------|------------|
| `_date_parse_quarto_yaml` | 5ms | yq subprocess |
| `_date_parse_markdown_inline` | 50ms | File size |
| `_date_normalize` | < 1ms | Pure string ops |
| `_date_compute_from_week` | 10ms | yq + date arithmetic |
| `_date_add_days` | 5ms | date subprocess |
| `_date_find_teaching_files` | 20ms | Number of dirs/files |
| `_date_load_config` | 100ms | Config size, number of dates |
| `_date_apply_to_file` | 10-50ms | File size, replacements |

**Total workflow time:**
- Load config: ~100ms
- Scan 50 files: ~1s
- Apply 10 changes: ~100ms
- **Total: ~1.2s for full sync**

---

## Examples

### Complete Workflow: Date Sync

```zsh
#!/usr/bin/env zsh

# 1. Load config dates
declare -A CONFIG_DATES
eval "$(_date_load_config .flow/teach-config.yml)"

echo "Loaded ${#CONFIG_DATES[@]} dates from config"

# 2. Find all teaching files
local -a files
while IFS= read -r file; do
    files+=("$file")
done < <(_date_find_teaching_files)

echo "Found ${#files[@]} teaching files"

# 3. Check each file for date mismatches
local -a mismatches=()

for file in "${files[@]}"; do
    # Extract file date
    local file_date=$(_date_parse_quarto_yaml "$file" "due" 2>/dev/null)
    [[ -z "$file_date" ]] && continue

    # Match to config (simplified: assume filename = config key)
    local filename=$(basename "$file" .qmd)
    local config_date="${CONFIG_DATES[deadline_$filename]}"
    [[ -z "$config_date" ]] && continue

    # Check for mismatch
    if [[ "$file_date" != "$config_date" ]]; then
        mismatches+=("$file:due:$file_date:$config_date")
        echo "❌ $file: due $file_date → $config_date"
    else
        echo "✓ $file: due $file_date (synced)"
    fi
done

# 4. Apply changes
if [[ ${#mismatches[@]} -gt 0 ]]; then
    echo ""
    echo "Apply ${#mismatches[@]} changes? [y/N]"
    read -r response

    if [[ "$response" == "y" ]]; then
        for mismatch in "${mismatches[@]}"; do
            local file="${mismatch%%:*}"
            local rest="${mismatch#*:}"
            local field="${rest%%:*}"
            rest="${rest#*:}"
            local old_date="${rest%%:*}"
            local new_date="${rest#*:}"

            if _date_apply_to_file "$file" "$field:$old_date:$new_date"; then
                echo "✓ Updated: $file"
            else
                echo "✗ Failed: $file"
            fi
        done
    fi
fi
```

### Compute All Assignment Due Dates

```zsh
#!/usr/bin/env zsh

# Generate due dates for 10 assignments (all due Fridays)

for i in {1..10}; do
    local week=$((i + 1))  # HW1 due Week 2
    local due_date=$(_date_compute_from_week $week 4)  # Friday (offset 4)

    echo "hw$i:"
    echo "  week: $week"
    echo "  offset_days: 4"
    echo "  computed_due: $due_date"
    echo ""
done
```

---

## See Also

- [Teaching Dates Guide](../guides/TEACHING-DATES-GUIDE.md) - User guide
- [teach-config.yml Schema](TEACH-CONFIG-DATES-SCHEMA.md) - Config reference
- [Architecture Documentation](../architecture/TEACHING-DATES-ARCHITECTURE.md) - System design

---

**Last Updated:** 2026-01-16
**Version:** v5.11.0
**Status:** Complete
