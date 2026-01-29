# Teaching Dates Architecture

**Version:** v5.11.0
**Status:** Complete
**Last Updated:** 2026-01-16

---

## Executive Summary

The Teaching Dates Automation system centralizes semester schedule management for academic courses. It provides a single source of truth (teach-config.yml) for all temporal information and automatically synchronizes dates across teaching materials (syllabus, assignments, lectures, schedules).

**Key Components:**
1. **Date Parser Module** (`lib/date-parser.zsh`) - Extract, normalize, and compute dates
2. **Config Schema Extensions** - Store weeks, holidays, deadlines, exams
3. **Sync Command** (`teach dates sync`) - Interactive date synchronization
4. **Init Command** (`teach dates init`) - Wizard for semester setup

**Primary Value:** Eliminate manual date management, prevent inconsistencies, reduce semester rollover from 2 hours to 5 minutes.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Diagrams](#architecture-diagrams)
3. [Component Specifications](#component-specifications)
4. [Data Flow](#data-flow)
5. [Integration Points](#integration-points)
6. [Error Handling](#error-handling)
7. [Performance](#performance)
8. [Security](#security)
9. [Future Enhancements](#future-enhancements)

---

## System Overview

### High-Level Architecture

```mermaid
graph TB
    subgraph "User Interface Layer"
        CMD[teach dates sync]
        INIT[teach dates init]
        STATUS[teach dates status]
        VALIDATE[teach dates validate]
    end

    subgraph "Business Logic Layer"
        PARSER[Date Parser Module]
        SYNC[Sync Engine]
        COMPUTE[Date Computation]
    end

    subgraph "Data Layer"
        CONFIG[teach-config.yml]
        SCHEMA[JSON Schema]
        VALIDATOR[Config Validator]
    end

    subgraph "Teaching Files"
        QMD[*.qmd files]
        MD[*.md files]
        YAML[YAML Frontmatter]
    end

    CMD --> SYNC
    INIT --> CONFIG
    STATUS --> PARSER
    VALIDATE --> VALIDATOR

    SYNC --> PARSER
    SYNC --> COMPUTE
    SYNC --> CONFIG
    SYNC --> QMD
    SYNC --> MD

    PARSER --> YAML
    COMPUTE --> CONFIG
    VALIDATOR --> SCHEMA
    CONFIG --> SCHEMA

    classDef uiLayer fill:#e1f5e1,stroke:#4a9d4a
    classDef logicLayer fill:#e1e5f5,stroke:#4a5d9d
    classDef dataLayer fill:#f5e1e1,stroke:#9d4a4a
    classDef fileLayer fill:#f5f5e1,stroke:#9d9d4a

    class CMD,INIT,STATUS,VALIDATE uiLayer
    class PARSER,SYNC,COMPUTE logicLayer
    class CONFIG,SCHEMA,VALIDATOR dataLayer
    class QMD,MD,YAML fileLayer
```

### System Boundaries

**In Scope:**
- Date extraction from Quarto/Markdown files
- Date normalization (ISO, US, long form)
- Relative date computation (week + offset)
- Config-to-file synchronization
- Interactive sync workflow
- Semester initialization

**Out of Scope:**
- Automatic semester rollover (future v5.12.0)
- Multi-meeting per week (future v5.12.0)
- External calendar import (future v5.13.0)
- Real-time sync (future)

### Design Principles

1. **Single Source of Truth:** Config is authoritative, files are derived
2. **Safety First:** Backups, dry-run mode, interactive prompts
3. **Cross-Platform:** Works on macOS (BSD) and Linux (GNU)
4. **ADHD-Friendly:** Clear prompts, safe defaults, visual feedback
5. **Pure ZSH:** No Node.js/Python dependencies (except `yq` for YAML)

---

## Architecture Diagrams

### Component Interaction Diagram

```mermaid
graph LR
    subgraph "teach dates sync Workflow"
        A[User runs 'teach dates sync'] --> B[Scan for teaching files]
        B --> C[Load config dates]
        C --> D[Extract file dates]
        D --> E{Dates match?}
        E -->|Yes| F[✓ File synced]
        E -->|No| G[Show mismatch]
        G --> H{User confirms?}
        H -->|Yes| I[Apply changes]
        H -->|No| J[Skip file]
        I --> K[Update YAML]
        I --> L[Update content]
        K --> M[Remove backup]
        L --> M
        M --> F
    end

    style A fill:#e1f5e1
    style E fill:#f5e1e1
    style H fill:#f5e1e1
    style F fill:#e1f5e1
```

### Data Flow: Config to Files

```mermaid
sequenceDiagram
    actor User
    participant CMD as teach dates sync
    participant Parser as Date Parser
    participant Config as teach-config.yml
    participant Files as Teaching Files

    User->>CMD: teach dates sync
    CMD->>Files: Scan for *.qmd, *.md
    Files-->>CMD: List of 23 files

    loop For each file
        CMD->>Parser: Extract dates from file
        Parser->>Files: Read YAML + markdown
        Files-->>Parser: File dates
        Parser-->>CMD: {due: "2025-01-20"}

        CMD->>Config: Load config dates
        Config-->>CMD: {hw1: {week: 2, offset: 2}}

        CMD->>Parser: Compute relative date
        Parser-->>CMD: "2025-01-22"

        CMD->>CMD: Compare dates
        CMD->>CMD: Flag mismatch

        CMD->>User: Show: due: 2025-01-20 → 2025-01-22
        User->>CMD: Confirm [y]

        CMD->>Parser: Apply changes
        Parser->>Files: Update YAML + content
        Parser-->>CMD: ✓ Success

        CMD->>User: ✓ Updated file
    end

    CMD->>User: Summary: 3 applied, 2 skipped
```

### Semester Init Flow

```mermaid
stateDiagram-v2
    [*] --> PromptStart: teach dates init
    PromptStart --> ValidateDate: User enters start date
    ValidateDate --> GenerateWeeks: Date valid (ISO format)
    ValidateDate --> PromptStart: Date invalid (retry)

    GenerateWeeks --> ComputeDates: Calculate 15 weeks
    ComputeDates --> WriteConfig: Add to teach-config.yml
    WriteConfig --> ShowSummary: Display summary
    ShowSummary --> [*]: ✓ Complete

    note right of GenerateWeeks
        Week 1 = start_date
        Week 2 = start_date + 7 days
        ...
        Week 15 = start_date + 98 days
    end note

    note right of WriteConfig
        Updates:
        - semester_info.start_date
        - semester_info.end_date
        - semester_info.weeks[]
    end note
```

---

## Component Specifications

### Date Parser Module

**Location:** `lib/date-parser.zsh`

**Responsibilities:**
1. Extract dates from YAML frontmatter
2. Find inline dates in Markdown
3. Normalize dates to ISO-8601
4. Compute relative dates (week + offset)
5. Apply date changes to files

**Public API:**

| Function | Input | Output | Side Effects |
|----------|-------|--------|--------------|
| `_date_parse_quarto_yaml` | file, field | ISO date | None |
| `_date_parse_markdown_inline` | file, [pattern] | line:date array | None |
| `_date_normalize` | date_string | ISO date | None |
| `_date_compute_from_week` | week, offset, [config] | ISO date | None |
| `_date_add_days` | base_date, days | ISO date | None |
| `_date_find_teaching_files` | [path] | file paths | None |
| `_date_load_config` | [config] | shell code | None |
| `_date_apply_to_file` | file, changes | 0/1 | Modifies file + backup |

**Dependencies:**
- `yq` ≥ 4.0 (YAML processing)
- `date` or `gdate` (date arithmetic)
- `sed` (content replacement)
- `find` (file discovery)

**Error Handling:**
- All functions return 0 (success) or 1 (error)
- Errors printed to stderr
- Stdout reserved for data output

### Sync Engine

**Location:** `lib/dispatchers/teach-dates.zsh`

**Responsibilities:**
1. Orchestrate file discovery
2. Load config dates
3. Compare file vs config dates
4. Present mismatches to user
5. Apply changes interactively

**Workflow:**

```
1. Scan teaching files
   ↓
2. Load config dates
   ↓
3. For each file:
   a. Extract file dates
   b. Match to config
   c. Flag mismatches
   ↓
4. Show summary
   ↓
5. For each mismatch:
   a. Show diff
   b. Prompt user
   c. Apply if confirmed
   ↓
6. Show final summary
```

**Modes:**

| Mode | Behavior |
|------|----------|
| Interactive (default) | Prompts for each file |
| `--dry-run` | Preview only, no changes |
| `--force` | Auto-apply all changes |
| `--verbose` | Show detailed progress |

**Filters:**

| Filter | Effect |
|--------|--------|
| `--assignments` | Sync only assignments/ |
| `--lectures` | Sync only lectures/ |
| `--syllabus` | Sync only syllabus/schedule |
| `--file <path>` | Sync single file |

### Config Schema

**Location:** `lib/templates/teaching/teach-config.schema.json`

**Extended Fields:**

```yaml
semester_info:
  start_date: string (YYYY-MM-DD)
  end_date: string (YYYY-MM-DD)

  weeks:
    - number: integer (1-52)
      start_date: string (YYYY-MM-DD)
      topic: string (optional)

  holidays:
    - name: string
      date: string (YYYY-MM-DD)
      type: enum(break|holiday|no_class)

  deadlines:
    <assignment_id>:
      # Absolute date
      due_date: string (YYYY-MM-DD)
      # OR relative date
      week: integer
      offset_days: integer

  exams:
    - name: string
      date: string (YYYY-MM-DD)
      time: string (optional)
      location: string (optional)
```

**Validation Rules:**
- All dates must be ISO format (`YYYY-MM-DD`)
- Week numbers must be sequential (1, 2, 3, ...)
- Deadlines must have `due_date` XOR (`week` AND `offset_days`)
- Exam dates should fall within semester range (warning if not)

### Config Validator

**Location:** `lib/config-validator.zsh`

**Extended Validations:**
1. **Schema validation:** JSON Schema compliance
2. **Date format:** All dates are YYYY-MM-DD
3. **Week sequence:** No gaps or duplicates
4. **Chronology:** End date after start date
5. **Range checks:** Exam dates within semester
6. **Hash tracking:** Detect config changes

**Integration:**
- Called by `teach status`
- Called by `teach dates validate`
- Auto-validates before sync

---

## Data Flow

### teach dates sync - Detailed Flow

```mermaid
flowchart TD
    Start([teach dates sync]) --> Validate{Config exists?}
    Validate -->|No| Error1[Error: Run teach init first]
    Validate -->|Yes| Scan[Scan teaching files]

    Scan --> Filter{Filter flag?}
    Filter -->|--assignments| FilterA[Filter: assignments/]
    Filter -->|--lectures| FilterL[Filter: lectures/]
    Filter -->|--file| FilterF[Single file mode]
    Filter -->|None| NoFilter[All files]

    FilterA --> LoadConfig
    FilterL --> LoadConfig
    FilterF --> LoadConfig
    NoFilter --> LoadConfig

    LoadConfig[Load config dates] --> HasDates{Dates in config?}
    HasDates -->|No| Warn[Warning: No dates in config]
    HasDates -->|Yes| Analyze

    Analyze[Analyze each file] --> Loop{More files?}
    Loop -->|Yes| Extract[Extract file dates]
    Extract --> Match[Match to config]
    Match --> Compare{Dates match?}
    Compare -->|Yes| Loop
    Compare -->|No| FlagMismatch[Flag mismatch]
    FlagMismatch --> Loop

    Loop -->|No| Summary{Mismatches found?}
    Summary -->|No| Success[✅ All dates synced]
    Summary -->|Yes| ShowMismatches[Show mismatch summary]

    ShowMismatches --> DryRun{--dry-run mode?}
    DryRun -->|Yes| PreviewEnd[ℹ  Dry-run: No changes]
    DryRun -->|No| ApplyLoop

    ApplyLoop{More mismatches?} -->|Yes| ShowDiff[Show file diff]
    ShowDiff --> Force{--force mode?}
    Force -->|Yes| Apply[Apply changes]
    Force -->|No| Prompt[Prompt user]

    Prompt --> UserChoice{User choice?}
    UserChoice -->|y| Apply
    UserChoice -->|n| Skip[Skip file]
    UserChoice -->|d| ShowDetailedDiff[Show detailed diff]
    UserChoice -->|q| Quit[Quit sync]
    ShowDetailedDiff --> Prompt

    Apply --> Backup[Create .bak file]
    Backup --> UpdateYAML[Update YAML with yq]
    UpdateYAML --> UpdateContent[Replace inline dates]
    UpdateContent --> ApplySuccess{Success?}
    ApplySuccess -->|Yes| RemoveBackup[Remove .bak]
    ApplySuccess -->|No| RestoreBackup[Restore from .bak]
    RemoveBackup --> ApplyLoop
    RestoreBackup --> ApplyLoop
    Skip --> ApplyLoop

    ApplyLoop -->|No| FinalSummary[Show final summary]
    FinalSummary --> GitPrompt[Suggest git diff]
    GitPrompt --> End([Complete])

    Quit --> FinalSummary
    PreviewEnd --> End
    Success --> End
    Error1 --> End
    Warn --> End

    style Start fill:#e1f5e1
    style End fill:#e1f5e1
    style Error1 fill:#f5e1e1
    style Success fill:#e1f5e1
    style Apply fill:#f5f5e1
    style Backup fill:#f5f5e1
```

### Date Computation Flow

```mermaid
graph TD
    A[deadline_hw1: week 2, offset 2] --> B[Load week 2 start_date]
    B --> C[Config: 2025-01-20]
    C --> D[Add offset days: +2]
    D --> E{Platform?}
    E -->|Linux| F[GNU date: 2025-01-20 + 2 days]
    E -->|macOS| G[BSD date: -v+2d]
    F --> H[Result: 2025-01-22]
    G --> H
    H --> I[Return ISO date]

    style A fill:#e1f5e1
    style E fill:#f5e1e1
    style I fill:#e1f5e1
```

### File Modification Flow

```mermaid
sequenceDiagram
    participant Sync as Sync Engine
    participant Parser as Date Parser
    participant File as hw1.qmd
    participant Backup as hw1.qmd.bak

    Sync->>Parser: Apply changes
    Parser->>File: Copy to .bak
    File-->>Backup: Created

    Parser->>File: Update YAML with yq
    Note over File: due: "2025-01-22"

    Parser->>File: Replace inline dates with sed
    Note over File: "Due: January 22, 2025"

    Parser->>Parser: Check if modified
    alt Modification succeeded
        Parser->>Backup: Remove .bak
        Parser-->>Sync: ✓ Success
    else Modification failed
        Parser->>Backup: Restore from .bak
        Parser-->>Sync: ✗ Failed
    end
```

---

## Integration Points

### Integration with Existing flow-cli Components

```mermaid
graph TB
    subgraph "Teaching Workflow (v5.10.0)"
        TEACH[teach dispatcher]
        INIT[teach init]
        STATUS[teach status]
        DEPLOY[teach deploy]
        EXAM[teach exam]
    end

    subgraph "Date Management (NEW v5.11.0)"
        DATES_SYNC[teach dates sync]
        DATES_INIT[teach dates init]
        DATES_STATUS[teach dates status]
        DATES_VALIDATE[teach dates validate]
    end

    subgraph "Config Management"
        CONFIG[teach-config.yml]
        VALIDATOR[config-validator.zsh]
        SCHEMA[JSON Schema]
    end

    TEACH --> DATES_SYNC
    TEACH --> DATES_INIT
    TEACH --> DATES_STATUS
    TEACH --> DATES_VALIDATE

    INIT --> DATES_INIT
    STATUS --> DATES_STATUS
    STATUS --> VALIDATOR

    DATES_SYNC --> CONFIG
    DATES_INIT --> CONFIG
    DATES_STATUS --> CONFIG
    DATES_VALIDATE --> VALIDATOR

    VALIDATOR --> SCHEMA
    CONFIG --> SCHEMA

    classDef existing fill:#e1e5f5
    classDef new fill:#e1f5e1
    classDef shared fill:#f5e1e1

    class TEACH,INIT,STATUS,DEPLOY,EXAM existing
    class DATES_SYNC,DATES_INIT,DATES_STATUS,DATES_VALIDATE new
    class CONFIG,VALIDATOR,SCHEMA shared
```

### Integration with Scholar MCP

**Current (v5.10.0):**
- Scholar reads `course.name`, `course.semester`, `course.year` from config
- Scholar uses `scholar.grading`, `scholar.style` sections

**Future (v5.12.0+):**
- Scholar reads `semester_info.weeks[]` for course timeline context
- Scholar reads `semester_info.exams[]` to avoid scheduling conflicts
- Scholar reads `semester_info.holidays[]` for pacing

**Example:**

```bash
# Generate exam for Week 8
teach exam "Midterm 1" --week 8

# Scholar reads:
# - Week 8 start date from semester_info
# - Existing exams to avoid duplicates
# - Holiday dates to avoid conflicts
```

### External Tool Dependencies

```mermaid
graph LR
    subgraph "Date Parser Dependencies"
        YQ[yq ≥ 4.0]
        DATE[GNU date / BSD date]
        SED[sed]
        FIND[find]
    end

    subgraph "Date Parser Module"
        PARSER[date-parser.zsh]
    end

    YQ --> PARSER
    DATE --> PARSER
    SED --> PARSER
    FIND --> PARSER

    PARSER --> OUTPUT[ISO Dates]

    style YQ fill:#f5e1e1
    style DATE fill:#f5e1e1
    style SED fill:#f5e1e1
    style FIND fill:#f5e1e1
    style PARSER fill:#e1f5e1
```

**Dependency Management:**
- `yq` - Required for YAML operations (install: `brew install yq`)
- `date` - System tool (GNU on Linux, BSD on macOS)
- `sed` - System tool (present on all Unix-like systems)
- `find` - System tool (present on all Unix-like systems)

**Graceful Degradation:**
- If `yq` missing → Error message with install instructions
- If `date` missing → Error (should never happen on Unix)
- Platform auto-detection for `date` syntax (GNU vs BSD)

---

## Error Handling

### Error Hierarchy

```mermaid
graph TD
    E[Error Occurs] --> T{Type?}

    T -->|Config Error| CE[Config Error]
    T -->|File Error| FE[File Error]
    T -->|Date Error| DE[Date Error]
    T -->|Tool Error| TE[Tool Error]

    CE --> CE1[Missing config]
    CE --> CE2[Invalid YAML]
    CE --> CE3[Schema violation]

    FE --> FE1[File not found]
    FE --> FE2[Permission denied]
    FE --> FE3[Backup failed]

    DE --> DE1[Invalid format]
    DE --> DE2[Week not found]
    DE --> DE3[Computation failed]

    TE --> TE1[yq not installed]
    TE --> TE2[date command error]

    CE1 --> REC1[Suggest: teach init]
    CE2 --> REC2[Show line number]
    CE3 --> REC3[Show validation errors]

    FE1 --> REC4[Check file path]
    FE2 --> REC5[Check permissions]
    FE3 --> REC6[Restore from backup]

    DE1 --> REC7[Show expected format]
    DE2 --> REC8[List available weeks]
    DE3 --> REC9[Debug date arithmetic]

    TE1 --> REC10[Install: brew install yq]
    TE2 --> REC11[Check date syntax]

    style E fill:#f5e1e1
    style REC1,REC2,REC3,REC4,REC5,REC6,REC7,REC8,REC9,REC10,REC11 fill:#e1f5e1
```

### Error Recovery Strategies

| Error | Recovery Strategy | User Action |
|-------|------------------|-------------|
| **Missing config** | Exit gracefully | Run `teach init` |
| **Invalid date** | Skip field, continue | Fix date in config |
| **Week not found** | Skip computation | Add week to config |
| **yq not installed** | Exit with install instructions | Install yq |
| **File write error** | Restore from backup | Check permissions |
| **YAML parse error** | Show line number | Fix YAML syntax |
| **sed replace error** | Restore from backup | Check file encoding |

### Rollback Mechanisms

**File-Level Rollback:**

```zsh
# Before modification
cp file.qmd file.qmd.bak

# If error occurs
mv file.qmd.bak file.qmd  # Restore

# If success
rm file.qmd.bak  # Clean up
```

**Config-Level Rollback:**

```bash
# User can always use git
git restore .flow/teach-config.yml

# Or manual rollback
# Remove semester_info section from config
# Files retain their current dates (no change)
```

**Sync-Level Rollback:**

```bash
# User can quit during interactive sync
# Prompt: [y/n/d/q]
# q = Quit, no more changes

# Or use git after sync
git diff  # Review changes
git restore <file>  # Undo specific file
git restore .  # Undo all
```

---

## Performance

### Benchmarks

**Environment:**
- MacBook Pro M1
- 50 teaching files
- 23 dates in config

| Operation | Time | Notes |
|-----------|------|-------|
| Load config dates | ~100ms | yq subprocess |
| Scan 50 files | ~20ms | find command |
| Extract dates from 1 file | ~5ms | yq + regex |
| Compute 1 relative date | ~10ms | yq + date arithmetic |
| Apply changes to 1 file | ~10ms | yq + sed |
| **Full sync (50 files)** | **~1.2s** | Including user prompts |

### Optimization Strategies

**Current:**
1. Single yq call per file (not per field)
2. Batch date computations (compute once, use many times)
3. Skip files without date fields early
4. Use `find -maxdepth 2` to limit recursion

**Future (if needed):**
1. Cache yq output for repeated reads
2. Parallel file processing (process multiple files concurrently)
3. Incremental sync (only check files modified since last sync)
4. Skip binary files early

### Scalability Limits

| Metric | Current | Limit | Notes |
|--------|---------|-------|-------|
| Files | 50 | 500+ | Linear time growth |
| Dates per config | 23 | 200+ | Hash table lookup |
| File size | 10KB | 1MB+ | sed/yq overhead |
| Sync time | 1.2s | 10s | For 500 files |

**Expected Growth:**
- Typical course: 20-50 files
- Large course: 100-200 files
- No scalability issues expected

---

## Security

### Threat Model

**Potential Threats:**
1. Malicious config file (command injection via YAML)
2. Malicious file content (command injection via dates)
3. Path traversal (reading files outside project)
4. Unauthorized file modification

### Mitigations

**1. Config Validation:**

```yaml
# Schema enforces:
- Date format: YYYY-MM-DD (regex validated)
- Integer types: Week numbers, offsets
- Enum types: semester, holiday types
- No shell commands in YAML
```

**2. Input Sanitization:**

```zsh
# All date inputs validated with regex
if [[ ! "$date" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    return 1
fi

# Week numbers validated as integers
if [[ ! "$week" =~ ^[0-9]+$ ]]; then
    return 1
fi
```

**3. File Path Validation:**

```zsh
# Only operate within project root
# Use relative paths, not arbitrary paths
# find command scoped to specific directories

# No directory traversal
[[ "$file" == *".."* ]] && return 1
```

**4. Backup Before Modification:**

```zsh
# Always create backup before modifying
cp "$file" "${file}.bak"

# Restore on any error
trap 'mv "${file}.bak" "$file"' ERR
```

### Permissions

**Required Permissions:**
- Read: `.flow/teach-config.yml`
- Read/Write: Teaching files (`.qmd`, `.md`)
- Write: Backup files (`.bak`)

**Not Required:**
- System-wide write access
- Root/sudo permissions
- Network access

---

## Future Enhancements

### Roadmap (v5.12.0 - v5.14.0)

```mermaid
timeline
    title Teaching Dates Feature Roadmap
    section v5.11.0 (Current)
        Date sync : Date parser module
                  : teach dates sync
                  : teach dates init
                  : Config schema extensions
    section v5.12.0 (Next)
        Semester rollover : teach semester new
                         : Automatic date shifting
                         : Multi-meeting per week
    section v5.13.0 (Future)
        Calendar import : External calendar import (iCal)
                       : Holiday auto-detection
                       : Finals week detection
    section v5.14.0 (Future)
        Advanced features : Real-time sync
                         : CI/CD integration
                         : Conflict resolution UI
```

### Planned Features

#### 1. Semester Rollover (v5.12.0)

**Command:**

```bash
teach semester new "Spring 2026"
```

**Behavior:**
1. Calculate date shift (Fall 2025 → Spring 2026)
2. Shift all config dates (weeks, exams, holidays)
3. Update `course.semester` and `course.year`
4. Run `teach dates sync --force`
5. Complete rollover in < 5 minutes

**Architecture Changes:**
- Add `_teach_semester_new()` function
- Add date shifting algorithm
- Add `teach semester` dispatcher

#### 2. Multi-Meeting Per Week (v5.12.0)

**Config Schema:**

```yaml
weeks:
  - number: 1
    meetings:
      - date: "2025-01-13"
        topic: "Introduction"
      - date: "2025-01-15"
        topic: "Setup & RStudio"
```

**Use Case:** Courses with MWF or TTh schedules

#### 3. External Calendar Import (v5.13.0)

**Command:**

```bash
teach dates import-calendar university-calendar.ics
```

**Behavior:**
1. Parse iCal file
2. Extract holidays, breaks, finals week
3. Add to `semester_info.holidays[]`
4. Validate no conflicts with existing dates

**Architecture Changes:**
- Add iCal parser module
- Add conflict detection
- Add `teach dates import-calendar` command

---

## Appendices

### A. File Type Support Matrix

| File Type | YAML Parsing | Inline Parsing | Modification | Status |
|-----------|-------------|----------------|--------------|--------|
| `.qmd` (Quarto) | ✅ Yes | ✅ Yes | ✅ Yes | Full support |
| `.md` (Markdown) | ✅ Yes | ✅ Yes | ✅ Yes | Full support |
| `.Rmd` (R Markdown) | ⚠️ Partial | ✅ Yes | ⚠️ Partial | Future |
| `.ipynb` (Jupyter) | ❌ No | ❌ No | ❌ No | Not planned |
| `.tex` (LaTeX) | ❌ No | ⚠️ Partial | ❌ No | Not planned |

### B. Date Format Support Matrix

| Format | Example | Parse | Normalize | Display | Notes |
|--------|---------|-------|-----------|---------|-------|
| ISO-8601 | `2025-01-22` | ✅ | ✅ | ✅ | Primary format |
| US Short | `1/22/2025` | ✅ | ✅ | ✅ | Ambiguous (M/D vs D/M) |
| US Long | `January 22, 2025` | ✅ | ✅ | ✅ | Unambiguous |
| Abbreviated | `Jan 22, 2025` | ✅ | ✅ | ✅ | Common in prose |
| Short Abbrev | `Jan 22` | ✅ | ✅ | ⚠️ | Infers year |
| Relative | `week: 2, offset: 2` | ⚠️ | ✅ | ❌ | Config only |

### C. Cross-Platform Compatibility

| Platform | OS | ZSH Version | yq | date | Status |
|----------|----|-----------|----|------|--------|
| macOS | 13+ | 5.8+ | brew install | BSD date | ✅ Tested |
| Linux (Ubuntu) | 22.04+ | 5.8+ | apt install | GNU date | ✅ Tested |
| Linux (Fedora) | 38+ | 5.8+ | dnf install | GNU date | ✅ Tested |
| WSL2 (Ubuntu) | 22.04+ | 5.8+ | apt install | GNU date | ⚠️ Manual test needed |
| FreeBSD | 13+ | 5.8+ | pkg install | BSD date | ❌ Not tested |

---

## See Also

- [Date Parser API Reference](../reference/MASTER-API-REFERENCE.md#teaching-libraries) - Function documentation
- [Teaching Dates Guide](../guides/TEACHING-DATES-GUIDE.md) - User guide
- [Config Schema Reference](../reference/MASTER-API-REFERENCE.md#config-validation) - Schema docs

---

**Last Updated:** 2026-01-16
**Version:** v5.11.0
**Status:** Complete
