# Brainstorm: Automated Date/Deadline Management for Teaching Workflows

**Generated:** 2026-01-16
**Mode:** Deep Feature Analysis
**Duration:** 8 expert questions
**Context:** flow-cli v5.10.0 - Teaching dispatcher + Date automation

---

## Executive Summary

Add intelligent date/deadline synchronization to flow-cli's teaching workflow, allowing instructors to define dates once in `teach-config.yml` and automatically propagate them to syllabus, schedule, assignments, and lecture files. Support relative dates, conflict resolution, and semester rollover.

**Key Insight:** Teaching materials reference the same dates dozens of times across multiple files. Manual updates are error-prone and tedious. A centralized date management system with smart propagation eliminates inconsistencies and saves hours per semester.

---

## User Research Findings

### Pain Points Identified (All selected)

1. **Manual updates across multiple files**
   - Tedious to update dates in syllabus, schedule, assignments
   - Easy to miss files, leading to inconsistencies

2. **Date inconsistencies between documents**
   - Syllabus says one due date, assignment page says another
   - Students get confused, instructor loses credibility

3. **Semester rollover process**
   - Copying entire course for new semester
   - Updating all dates manually (40+ occurrences)
   - High error rate, time-consuming

### Source of Truth

**Selected:** Both - config + external calendar

- Local `teach-config.yml` for course-specific dates
- External academic calendar for holidays, breaks
- Need to merge both sources intelligently

### Date Types to Manage (All selected)

- ✅ Week dates (Week 1: Jan 15, Week 2: Jan 22, ...)
- ✅ Assignment due dates (Homework, projects)
- ✅ Exam dates (Midterms, finals, quizzes)
- ✅ Holiday/break dates (Spring break, reading days)

### UX Preference

**Selected:** File-by-file prompts

- Show changes for each file
- Ask for confirmation before applying
- Allows selective updates
- Safety through review

### File Formats (Selected)

- ✅ Quarto (.qmd) YAML frontmatter updates
- ✅ Markdown content (inline dates)
- Note: HTML tables and YAML data files deferred to future

### Conflict Resolution

**Selected:** Ask user per conflict

- When file date differs from config date
- Prompt: Keep file date or use config date?
- Preserves manual overrides when intentional

### Relative Dates

**Selected:** Support offset syntax

- `week: 3, offset: +2 days` = Assignment due 2 days after Week 3
- Enables flexible scheduling
- Common pattern: homework due 2 days after lecture

### Triggers (Selected)

- ✅ Manual command: `teach dates sync`
- ✅ During semester rollover: `teach semester new <name>`
- Not auto-sync (too invasive)
- Not before deploy (can deploy without sync)

---

## Current State Analysis

### What Exists (v5.10.0)

**teach-config.yml Schema:**

```yaml
course:
  name: STAT 545
  semester: Fall
  year: 2024

semester_info:
  start_date: '2024-08-19' # Semester start (YYYY-MM-DD)
  # ... but no week dates, holidays, or deadlines
```

**Current Limitations:**

- `semester_info` only has `start_date` field
- No week-by-week schedule
- No holidays/breaks definition
- No assignment deadline tracking
- Instructors manually write dates in every file

**teach Commands:**

- `teach exam`, `teach quiz`, `teach slides` generate content
- Generated files have hardcoded dates (if any)
- No sync mechanism between config and files

### What's Missing

1. **Date schema in teach-config.yml**
   - Week definitions (Week 1-15 with dates)
   - Holidays/breaks list
   - Assignment deadlines map
   - Exam schedule

2. **Date parsing from files**
   - Extract dates from Quarto YAML frontmatter
   - Parse inline dates from markdown content
   - Understand date formats (ISO, long, short)

3. **Date synchronization command**
   - `teach dates sync` command
   - Find all teaching files (recursive search)
   - Match dates to config schema
   - Apply updates with confirmation

4. **Relative date computation**
   - Calculate dates from week + offset
   - Handle multi-day offsets
   - Respect academic calendar (skip holidays)

5. **Semester rollover**
   - `teach semester new` command
   - Copy course structure
   - Shift all dates to new semester
   - Preserve relative offsets

---

## Feature Design

### Phase 1: Date Schema Extension (Foundation - 2-3 hours)

**User Story:** As an instructor, I want to define my entire semester schedule in teach-config.yml once, so dates are centralized.

**Implementation:**

1. **Extend teach-config.schema.json:**

```json
{
  "semester_info": {
    "type": "object",
    "properties": {
      "start_date": {
        "type": "string",
        "pattern": "^\\d{4}-\\d{2}-\\d{2}$"
      },
      "end_date": {
        "type": "string",
        "pattern": "^\\d{4}-\\d{2}-\\d{2}$"
      },
      "weeks": {
        "type": "array",
        "items": {
          "type": "object",
          "required": ["number", "start_date"],
          "properties": {
            "number": { "type": "integer", "minimum": 1 },
            "start_date": { "type": "string", "pattern": "^\\d{4}-\\d{2}-\\d{2}$" },
            "topic": { "type": "string" },
            "notes": { "type": "string" }
          }
        }
      },
      "holidays": {
        "type": "array",
        "items": {
          "type": "object",
          "required": ["name", "date"],
          "properties": {
            "name": { "type": "string" },
            "date": { "type": "string" },
            "type": { "enum": ["break", "holiday", "no_class"] }
          }
        }
      },
      "deadlines": {
        "type": "object",
        "additionalProperties": {
          "type": "object",
          "properties": {
            "due_date": { "type": "string" },
            "week": { "type": "integer" },
            "offset_days": { "type": "integer" }
          }
        }
      },
      "exams": {
        "type": "array",
        "items": {
          "type": "object",
          "required": ["name", "date"],
          "properties": {
            "name": { "type": "string" },
            "date": { "type": "string" },
            "time": { "type": "string" },
            "location": { "type": "string" }
          }
        }
      }
    }
  }
}
```

1. **Example teach-config.yml:**

```yaml
semester_info:
  start_date: '2025-01-13'
  end_date: '2025-05-02'

  weeks:
    - number: 1
      start_date: '2025-01-13'
      topic: 'Introduction to Data Science'
    - number: 2
      start_date: '2025-01-20'
      topic: 'Data Wrangling with dplyr'
    # ... weeks 3-15

  holidays:
    - name: 'Martin Luther King Jr. Day'
      date: '2025-01-20'
      type: 'holiday'
    - name: 'Spring Break'
      date: '2025-03-10'
      type: 'break'

  deadlines:
    hw1:
      week: 2
      offset_days: 2 # Due 2 days after Week 2 starts
    hw2:
      due_date: '2025-02-03' # Absolute date
    project1:
      week: 8
      offset_days: 5

  exams:
    - name: 'Midterm 1'
      date: '2025-02-24'
      time: '2:00 PM'
      location: 'Main Hall 101'
    - name: 'Final Exam'
      date: '2025-05-06'
      time: '10:00 AM'
      location: 'TBD'
```

**Files Modified:**

- `lib/templates/teaching/teach-config.schema.json` - Extended schema
- `lib/templates/teaching/teach-config.yml.template` - Example with dates
- `lib/config-validator.zsh` - Validate new date fields

**Success Criteria:**

- Schema validates weeks, holidays, deadlines, exams
- Config validator catches date format errors
- teach status shows validation summary for dates

---

### Phase 2: Date Parser Module (Core - 4-5 hours)

**User Story:** As a developer, I need to extract dates from Quarto and Markdown files, so I can compare them with config dates.

**Implementation:**

1. **Create `lib/date-parser.zsh`:**

```zsh
# Extract date from Quarto YAML frontmatter
# Usage: _date_parse_quarto_yaml <file> <field>
# Returns: ISO date (YYYY-MM-DD) or empty
_date_parse_quarto_yaml() {
    local file="$1"
    local field="$2"

    # Use yq to extract date field from YAML frontmatter
    # Frontmatter is between --- markers
    local date=$(awk '/^---$/,/^---$/' "$file" | \
                 yq eval ".$field" - 2>/dev/null)

    [[ "$date" != "null" ]] && echo "$date"
}

# Extract inline dates from markdown content
# Usage: _date_parse_markdown_inline <file> <pattern>
# Returns: Array of dates found
_date_parse_markdown_inline() {
    local file="$1"
    local pattern="${2:-Due:|Deadline:|Date:}"

    # Match patterns like:
    #   **Due:** January 22, 2025
    #   Deadline: 2025-01-22
    #   Date: Jan 22, 2025
    grep -E "$pattern" "$file" | \
        sed -E 's/.*($pattern)[[:space:]]*//g'
}

# Parse date string to ISO format (YYYY-MM-DD)
# Handles: ISO, long format, short format
# Usage: _date_normalize "January 22, 2025"
_date_normalize() {
    local input="$1"

    # Try parsing with GNU date (Linux) or BSD date (macOS)
    if command -v gdate >/dev/null 2>&1; then
        gdate -d "$input" "+%Y-%m-%d" 2>/dev/null
    else
        date -j -f "%B %d, %Y" "$input" "+%Y-%m-%d" 2>/dev/null || \
        date -j -f "%b %d, %Y" "$input" "+%Y-%m-%d" 2>/dev/null || \
        date -j -f "%Y-%m-%d" "$input" "+%Y-%m-%d" 2>/dev/null
    fi
}

# Compute date from week + offset
# Usage: _date_compute_from_week <week_start_date> <offset_days>
_date_compute_from_week() {
    local week_start="$1"
    local offset_days="$2"

    # Add offset days to week start date
    if command -v gdate >/dev/null 2>&1; then
        gdate -d "$week_start + $offset_days days" "+%Y-%m-%d"
    else
        date -j -v "+${offset_days}d" -f "%Y-%m-%d" "$week_start" "+%Y-%m-%d"
    fi
}

# Find all teaching files for date sync
# Usage: _date_find_teaching_files [path]
_date_find_teaching_files() {
    local search_path="${1:-.}"

    # Search patterns:
    #   assignments/*.qmd
    #   lectures/*.qmd
    #   exams/*.qmd
    #   schedule.qmd, syllabus.qmd
    find "$search_path" -type f \( \
        -path "*/assignments/*.qmd" -o \
        -path "*/lectures/*.qmd" -o \
        -path "*/exams/*.qmd" -o \
        -name "schedule.qmd" -o \
        -name "syllabus.qmd" \
    \)
}
```

1. **Date extraction workflow:**

```
File → Parse YAML frontmatter → Extract date field
     → Parse markdown content → Match date patterns
     → Normalize all dates → ISO format (YYYY-MM-DD)
     → Compare with config dates → Flag differences
```

**Files Created:**

- `lib/date-parser.zsh` (new module, ~300 lines)
- `tests/test-date-parser.zsh` (unit tests)

**Success Criteria:**

- Extract dates from Quarto YAML (`date:`, `due:`, `deadline:`)
- Parse inline markdown dates (multiple formats)
- Normalize dates to ISO format
- Compute dates from week + offset

---

### Phase 3: Date Sync Command (Core - 5-6 hours)

**User Story:** As an instructor, I want to run `teach dates sync` and have it find all date mismatches and prompt me to fix them.

**Implementation:**

1. **Create `teach dates sync` command:**

```zsh
# Main entry point: teach dates sync
_teach_dates_sync() {
    local preview=false

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --preview|-p) preview=true; shift ;;
            *) break ;;
        esac
    done

    _flow_log_info "Scanning for teaching files..."

    # 1. Load config dates
    local config_dates=$(_date_load_config)

    # 2. Find all teaching files
    local files=($(_date_find_teaching_files))

    _flow_log_info "Found ${#files[@]} files to check"

    # 3. For each file, extract dates and compare
    local updates=()
    for file in "${files[@]}"; do
        local file_dates=$(_date_extract_from_file "$file")
        local diff=$(_date_compare "$file" "$file_dates" "$config_dates")

        if [[ -n "$diff" ]]; then
            updates+=("$file|$diff")
        fi
    done

    # 4. Show summary
    if [[ ${#updates[@]} -eq 0 ]]; then
        _flow_log_success "All dates are up-to-date! ✓"
        return 0
    fi

    _flow_log_warn "Found ${#updates[@]} files with date mismatches"

    # 5. Preview or apply
    if [[ "$preview" == true ]]; then
        _teach_dates_preview_changes "${updates[@]}"
    else
        _teach_dates_apply_changes "${updates[@]}"
    fi
}

# Preview changes (no modifications)
_teach_dates_preview_changes() {
    local updates=("$@")

    for update in "${updates[@]}"; do
        local file="${update%%|*}"
        local changes="${update#*|}"

        echo ""
        _flow_log_info "File: $file"
        echo "$changes" | while IFS='→' read -r old_date new_date field; do
            echo "  $field: $old_date → $new_date"
        done
    done

    echo ""
    _flow_log_info "Run 'teach dates sync' (without --preview) to apply changes"
}

# Apply changes (file-by-file prompts)
_teach_dates_apply_changes() {
    local updates=("$@")
    local applied=0
    local skipped=0

    for update in "${updates[@]}"; do
        local file="${update%%|*}"
        local changes="${update#*|}"

        echo ""
        _flow_log_info "File: $file"
        echo "$changes" | while IFS='→' read -r old_date new_date field; do
            echo "  $field: $old_date → $new_date"
        done

        # Prompt user
        read -q "REPLY?Apply changes to this file? [y/N] "
        echo ""

        if [[ "$REPLY" =~ ^[Yy]$ ]]; then
            _date_apply_to_file "$file" "$changes"
            _flow_log_success "✓ Updated $file"
            ((applied++))
        else
            _flow_log_info "Skipped $file"
            ((skipped++))
        fi
    done

    echo ""
    _flow_log_success "Applied $applied updates, skipped $skipped"
}

# Apply date changes to a file
_date_apply_to_file() {
    local file="$1"
    local changes="$2"

    # For each change, update the file
    echo "$changes" | while IFS='→' read -r old_date new_date field; do
        # Update YAML frontmatter
        sed -i.bak "s/^$field: $old_date$/$field: $new_date/" "$file"

        # Update inline markdown (with word boundaries)
        sed -i.bak "s/\\b$old_date\\b/$new_date/g" "$file"
    done

    # Remove backup
    rm -f "$file.bak"
}
```

1. **Workflow:**

```
┌─────────────────────────────────────────────────────────────┐
│ teach dates sync                                            │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 🔍 Scanning for teaching files...                           │
│ Found 23 files to check                                     │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ 📊 Date Mismatch Summary                                    │
├─────────────────────────────────────────────────────────────┤
│ Found 5 files with date mismatches:                         │
│   1. assignments/hw1.qmd (due date mismatch)                │
│   2. lectures/week02.qmd (date mismatch)                    │
│   3. syllabus.qmd (multiple dates)                          │
│   4. schedule.qmd (week dates out of sync)                  │
│   5. exams/midterm1.qmd (exam date changed)                 │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ File: assignments/hw1.qmd                                   │
├─────────────────────────────────────────────────────────────┤
│   due: 2025-01-20 → 2025-01-22                             │
│                                                             │
│ Apply changes to this file? [y/N]                           │
└─────────────────────────────────────────────────────────────┘
                          ↓
                  [User responds y/n]
                          ↓
                  [Repeat for each file]
                          ↓
┌─────────────────────────────────────────────────────────────┐
│ ✅ Date Sync Complete                                       │
├─────────────────────────────────────────────────────────────┤
│ Applied 3 updates, skipped 2                                │
│                                                             │
│ Next: Review changes and commit                             │
│   git diff                                                  │
│   git add -A && git commit -m "chore: sync course dates"   │
└─────────────────────────────────────────────────────────────┘
```

**Files Modified:**

- `lib/dispatchers/teach-dispatcher.zsh` - Add dates subcommand
- `lib/date-parser.zsh` - Add sync functions

**Success Criteria:**

- Finds all teaching files automatically
- Detects date mismatches (YAML + inline)
- Shows clear preview of changes
- Prompts file-by-file for safety
- Updates files correctly
- Preserves file formatting

---

### Phase 4: Semester Rollover (High-Value - 3-4 hours)

**User Story:** As an instructor, I want to run `teach semester new "Spring 2026"` and have it copy my course with updated dates automatically.

**Implementation:**

1. **Add `teach semester new` command:**

```zsh
_teach_semester_new() {
    local semester="$1"
    local year="$2"

    if [[ -z "$semester" || -z "$year" ]]; then
        _flow_log_error "Usage: teach semester new <semester> <year>"
        return 1
    fi

    # 1. Validate semester
    if [[ ! "$semester" =~ ^(Spring|Summer|Fall|Winter)$ ]]; then
        _flow_log_error "Invalid semester. Must be: Spring, Summer, Fall, Winter"
        return 1
    fi

    # 2. Calculate date shift
    local old_start_date=$(_config_get "semester_info.start_date")
    local new_start_date=$(_semester_calculate_start "$semester" "$year")
    local date_shift=$(( $(date -d "$new_start_date" +%s) - $(date -d "$old_start_date" +%s) ))
    local days_shift=$(( date_shift / 86400 ))

    _flow_log_info "Date shift: +$days_shift days"

    # 3. Shift all dates in config
    _teach_semester_shift_config_dates "$days_shift"

    # 4. Update semester info
    yq eval -i ".course.semester = \"$semester\"" teach-config.yml
    yq eval -i ".course.year = $year" teach-config.yml

    # 5. Sync dates to files
    _flow_log_info "Syncing dates to all files..."
    _teach_dates_sync --no-prompt

    _flow_log_success "Semester rollover complete!"
    _flow_log_info "Review changes: git diff"
}

# Shift all dates in config by N days
_teach_semester_shift_config_dates() {
    local days="$1"

    # Shift semester start/end dates
    local old_start=$(yq eval '.semester_info.start_date' teach-config.yml)
    local new_start=$(_date_add_days "$old_start" "$days")
    yq eval -i ".semester_info.start_date = \"$new_start\"" teach-config.yml

    # Shift week dates
    local week_count=$(yq eval '.semester_info.weeks | length' teach-config.yml)
    for ((i=0; i<week_count; i++)); do
        local old_date=$(yq eval ".semester_info.weeks[$i].start_date" teach-config.yml)
        local new_date=$(_date_add_days "$old_date" "$days")
        yq eval -i ".semester_info.weeks[$i].start_date = \"$new_date\"" teach-config.yml
    done

    # Shift holidays
    # Shift exam dates
    # Shift deadline absolute dates (relative dates auto-compute)
}
```

1. **Semester start date calculation:**

```zsh
# Calculate semester start date based on academic calendar patterns
_semester_calculate_start() {
    local semester="$1"
    local year="$2"

    case "$semester" in
        Spring)
            # Typically second Monday of January
            echo "$year-01-13"
            ;;
        Summer)
            # Typically first Monday of June
            echo "$year-06-02"
            ;;
        Fall)
            # Typically third Monday of August
            echo "$year-08-18"
            ;;
        Winter)
            # Typically first Monday of January (short term)
            echo "$year-01-06"
            ;;
    esac
}
```

**Files Modified:**

- `lib/dispatchers/teach-dispatcher.zsh` - Add semester subcommand
- `lib/date-parser.zsh` - Add date shifting functions

**Success Criteria:**

- One command copies and updates entire course
- All dates shifted by correct number of days
- Relative dates (week + offset) recalculated
- teach-config.yml updated with new semester/year
- All files synced automatically

---

### Phase 5: teach init Integration (Polish - 1-2 hours)

**User Story:** As an instructor starting a new course, teach init should prompt for semester dates and create a populated schedule.

**Implementation:**

1. **Enhanced teach init:**

```zsh
# During teach init, after course name/semester
echo ""
_flow_log_info "Let's set up your semester schedule..."

# Prompt for semester start date
read -r "start_date?Semester start date (YYYY-MM-DD, or press Enter for default): "
if [[ -z "$start_date" ]]; then
    start_date=$(_semester_calculate_start "$semester" "$year")
    _flow_log_info "Using default: $start_date"
fi

# Generate 15 weeks automatically
_flow_log_info "Generating 15-week schedule..."
_teach_init_generate_weeks "$start_date" 15

# Prompt for holidays
echo ""
_flow_log_info "Add any holidays/breaks? (e.g., Spring Break)"
# ... interactive holiday entry

# Save to config
yq eval -i ".semester_info.start_date = \"$start_date\"" teach-config.yml
yq eval -i ".semester_info.weeks = $weeks_array" teach-config.yml
```

1. **Week generation:**

```zsh
_teach_init_generate_weeks() {
    local start_date="$1"
    local num_weeks="$2"

    local weeks_json="["
    for ((i=1; i<=num_weeks; i++)); do
        local week_date=$(_date_add_days "$start_date" "$(( (i-1) * 7 ))")
        weeks_json+="{\"number\": $i, \"start_date\": \"$week_date\", \"topic\": \"Week $i\"}"
        [[ $i -lt $num_weeks ]] && weeks_json+=","
    done
    weeks_json+="]"

    echo "$weeks_json"
}
```

**Files Modified:**

- `commands/teach-init.zsh` - Add date setup

**Success Criteria:**

- teach init prompts for start date
- Automatically generates 15-week schedule
- Allows adding holidays interactively
- Creates ready-to-use config with dates

---

## Quick Wins (< 2 hours each)

1. ⚡ **Date schema extension** (Phase 1)
   - Extend teach-config.yml with weeks, holidays, deadlines
   - Foundation for all other phases
   - High value: enables centralized date management

2. ⚡ **teach dates sync --preview** (Subset of Phase 3)
   - Read-only mode showing date mismatches
   - No file modifications
   - Helps users understand what would change

---

## Medium Effort (3-5 hours)

1. 🔧 **Date parser module** (Phase 2)
   - Extract dates from Quarto and Markdown
   - Normalize date formats
   - Compute relative dates

2. 🔧 **Date sync command** (Phase 3)
   - Full implementation with file-by-file prompts
   - Apply date changes safely
   - Git integration for tracking changes

3. 🔧 **Semester rollover** (Phase 4)
   - One-command course copying with date shifts
   - High value for recurring courses
   - Saves 1-2 hours per semester

---

## Technical Design

### Date Formats Supported

| Format       | Example             | Context                      |
| ------------ | ------------------- | ---------------------------- |
| ISO 8601     | 2025-01-22          | YAML frontmatter (preferred) |
| Long format  | January 22, 2025    | Markdown inline text         |
| Short format | Jan 22, 2025        | Markdown inline text         |
| Relative     | week: 3, offset: +2 | Config deadlines             |

### Config Schema Structure

```yaml
semester_info:
  start_date: '2025-01-13'
  end_date: '2025-05-02'

  weeks:
    - number: 1
      start_date: '2025-01-13'
      topic: 'Topic'
    # ... weeks 2-15

  holidays:
    - name: 'Holiday Name'
      date: '2025-03-10'
      type: 'break|holiday|no_class'

  deadlines:
    hw1:
      week: 2 # Relative to week 2 start
      offset_days: 2 # +2 days
    hw2:
      due_date: '2025-02-03' # Absolute date

  exams:
    - name: 'Midterm 1'
      date: '2025-02-24'
      time: '2:00 PM'
      location: 'Room 101'
```

### Date Matching Algorithm

```
For each file:
  1. Extract YAML frontmatter dates (date, due, deadline)
  2. Extract inline markdown dates (regex patterns)
  3. Normalize all dates to ISO format
  4. Load config dates (weeks, deadlines, exams)
  5. For each file date:
     a. Try to match to config date (by context)
     b. If mismatch:
        - Calculate which should be correct
        - Flag for user review
  6. Build update list (old → new mappings)
  7. Show user and prompt for confirmation
```

### Relative Date Calculation

```
Given: week: 3, offset_days: 2

1. Load week 3 start date from config
   week_3_start = "2025-01-27"

2. Add offset days
   due_date = week_3_start + 2 days
   due_date = "2025-01-29"

3. Check if date falls on holiday
   if in holidays list:
     shift to next non-holiday day

4. Return computed date
```

---

## Integration Points

### With Existing teach Commands

1. **teach init:**
   - Prompts for semester start date
   - Generates initial week schedule
   - Creates populated config

2. **teach exam/quiz/assignment:**
   - When generating content, inject date from config
   - Use week + offset if defined
   - Fall back to prompting if no config date

3. **teach deploy:**
   - Optional pre-flight check: dates synced?
   - Warn if date mismatches detected
   - Suggest running teach dates sync

4. **teach status:**
   - Show date sync status
   - Count files with mismatches
   - Display next deadline

### With Git Integration (Phase B from previous spec)

- After date sync, offer to commit changes
- Generate descriptive commit message:

  ```
  teach: sync course dates for Spring 2025

  Updated 5 files:
  - assignments/hw1.qmd (due date)
  - lectures/week02.qmd (date)
  - syllabus.qmd (multiple dates)

  Generated via: teach dates sync
  ```

---

## Success Metrics

### Quantitative

1. **Reduce manual date updates:** 40+ occurrences → 1 config edit
   - Before: Edit syllabus, schedule, 8 assignments, 10 lectures
   - After: Edit teach-config.yml once, sync automatically

2. **Eliminate date inconsistencies:** 30% error rate → 0%
   - Before: Manual updates miss files, typos common
   - After: Single source of truth, automated propagation

3. **Semester rollover time:** 2 hours → 5 minutes
   - Before: Copy course, manually update 40+ dates
   - After: teach semester new "Spring 2026" (one command)

### Qualitative

1. **Confidence in accuracy**
   - Dates are always consistent across files
   - Students see same dates everywhere

2. **Reduced cognitive load**
   - Don't need to track dates manually
   - Config is the source of truth

3. **Faster course setup**
   - teach init generates populated schedule
   - Ready to start teaching, not updating dates

---

## Open Questions

1. **Should we support importing dates from external calendars?**
   - Import .ics (iCal) files for holidays
   - Sync with Google Calendar API
   - **Recommendation:** Phase 6 (future enhancement)

2. **How to handle date conflicts across multiple instructors?**
   - TA makes manual edit, instructor runs sync
   - **Recommendation:** Git diff shows conflict, prompt to resolve

3. **Should teach dates sync auto-commit changes?**
   - Pro: Convenient, tracks date changes in git
   - Con: Some users want to review before commit
   - **Recommendation:** Offer to commit (optional prompt)

4. **What about non-Quarto files (HTML, LaTeX)?**
   - Some courses use raw HTML or LaTeX
   - **Recommendation:** Phase 7, focus on Quarto/Markdown first

---

## Recommended Implementation Order

### Sprint 1 (Week 1) - Foundation

1. Phase 1: Date schema extension (2-3h)
2. Phase 2: Date parser module (4-5h)
3. Phase 3: Date sync command (preview only) (2h)

**Why:** Foundation + quick win (preview)

### Sprint 2 (Week 2) - Core Features

1. Phase 3: Date sync command (full implementation) (3-4h)
2. Phase 4: Semester rollover (3-4h)

**Why:** Complete the core workflow

### Sprint 3 (Week 3) - Polish

1. Phase 5: teach init integration (1-2h)
2. Documentation and examples (2-3h)
3. Testing and refinement (2-3h)

**Why:** User experience polish

---

## Files to Create/Modify

### New Files

- `lib/date-parser.zsh` - Date parsing and manipulation functions (~400 lines)
- `tests/test-date-parser.zsh` - Unit tests for date parser
- `tests/test-dates-sync.zsh` - Integration tests for sync command
- `docs/guides/TEACHING-DATES-GUIDE.md` - User guide

### Modified Files

- `lib/templates/teaching/teach-config.schema.json` - Extended date schema
- `lib/templates/teaching/teach-config.yml.template` - Example with dates
- `lib/config-validator.zsh` - Validate date fields
- `lib/dispatchers/teach-dispatcher.zsh` - Add dates and semester subcommands
- `commands/teach-init.zsh` - Date setup wizard
- `docs/reference/MASTER-DISPATCHER-GUIDE.md` - Document teach dates
- `docs/tutorials/14-teach-dispatcher.md` - Add date management section

---

## Related Work

### Similar Tools

1. **Jekyll Date Management:**
   - Uses YAML frontmatter for post dates
   - No automatic sync mechanism
   - **Lesson:** YAML frontmatter is good, need sync

2. **Hugo Shortcodes:**
   - `{{< date "2025-01-22" >}}` in markdown
   - Centralized in config.toml
   - **Lesson:** Shortcodes avoid duplication

3. **Quarto Variables:**
   - `{{< var due_date >}}` references `_variables.yml`
   - Single source of truth
   - **Lesson:** Variables work, but need config integration

---

## Conclusion

Teaching date management is a **high-leverage enhancement** that:

1. **Eliminates pain** - No more manual updates across 20+ files
2. **Prevents errors** - Single source of truth ensures consistency
3. **Saves time** - Semester rollover from 2 hours → 5 minutes
4. **Integrates naturally** - Extends existing teach-config.yml pattern
5. **No breaking changes** - Optional feature, existing workflows unaffected

**Recommended:** Implement Phases 1-3 first (foundation + core), then Phases 4-5 (high-value features).

**Total Effort:** 12-17 hours across 5 phases
**Impact:** Transforms course maintenance from tedious to automated
**Risk:** Low - read-mostly operations, file-by-file prompts ensure safety

---

**Generated by:** Claude Code - Deep Feature Brainstorm
**Duration:** 8 expert questions + comprehensive analysis
**Next Step:** Capture as implementation spec for v5.12.0
