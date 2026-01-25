# Scholar Enhancement Architecture

**Feature:** Teaching Content Generation System
**Version:** v5.13.0
**Date:** 2026-01-17

---

## Table of Contents

- [System Overview](#system-overview)
- [Component Architecture](#component-architecture)
- [Data Flow](#data-flow)
- [Phase Integration](#phase-integration)
- [State Management](#state-management)
- [Sequence Diagrams](#sequence-diagrams)
- [Design Patterns](#design-patterns)

---

## System Overview

The Scholar Enhancement is a 6-phase composable system for AI-powered teaching content generation.

### Architecture Layers

```mermaid
graph TB
    subgraph "User Interface Layer"
        CLI[Command Line]
        Completion[ZSH Completion]
        Help[Help System]
    end

    subgraph "Orchestration Layer"
        Dispatcher[teach() dispatcher]
        Wrapper[_teach_scholar_wrapper]
    end

    subgraph "Phase Processing Layer"
        P1[Phase 1: Validation]
        P2[Phase 2: Resolution]
        P3[Phase 3: Lesson Plans]
        P4[Phase 4: Interactive]
        P5[Phase 5: Revision]
        P6[Phase 6: Context]
    end

    subgraph "Data Layer"
        LessonPlans[Lesson Plan YAML]
        Config[Course Config YAML]
        Materials[Course Materials]
    end

    subgraph "AI Layer"
        Claude[Claude Code]
        Scholar[Scholar Plugin]
    end

    CLI --> Dispatcher
    Completion --> Dispatcher
    Help --> Dispatcher

    Dispatcher --> Wrapper

    Wrapper --> P5
    Wrapper --> P6
    Wrapper --> P1
    Wrapper --> P2
    Wrapper --> P4
    Wrapper --> P3

    P3 --> LessonPlans
    P3 --> Config
    P6 --> Config
    P6 --> Materials

    Wrapper --> Claude
    Claude --> Scholar
```

### Key Principles

1. **Composability**: Each phase is independent and composable
2. **Progressive Enhancement**: Features layer on top of each other
3. **Graceful Degradation**: Missing dependencies don't break core functionality
4. **Zero Configuration**: Sensible defaults, configuration optional

---

## Component Architecture

### Phase 1: Flag Infrastructure

**Purpose:** Validate content flags for conflicts

```mermaid
graph LR
    Input[User Flags] --> Validate[_teach_validate_content_flags]
    Validate --> Check{Has Conflicts?}
    Check -->|Yes| Error[Error Message]
    Check -->|No| Parse[_teach_parse_topic_week]
    Parse --> SetGlobals[Set TEACH_TOPIC/TEACH_WEEK]
```

**Components:**
- `TEACH_CONTENT_FLAGS` - Associative array of 9 content flags
- `TEACH_SELECTION_FLAGS` - Associative array of selection flags
- `_teach_validate_content_flags()` - Conflict detection
- `_teach_parse_topic_week()` - Topic/week extraction

**Global State:**

```zsh
TEACH_TOPIC=""        # Explicit topic string
TEACH_WEEK=""         # Week number
```

### Phase 2: Preset System

**Purpose:** Resolve content from style presets and overrides

```mermaid
graph TB
    Style[Style Preset] --> LoadPreset[Load Preset Content]
    Flags[Content Flags] --> LoadPreset
    LoadPreset --> BaseContent[Base Content List]

    BaseContent --> AddFlags[Add Positive Flags]
    AddFlags --> RemoveFlags[Remove Negation Flags]
    RemoveFlags --> Resolved[TEACH_CONTENT_RESOLVED]

    Resolved --> BuildInstr[_teach_build_content_instructions]
    BuildInstr --> Instructions[Scholar Instructions]
```

**Components:**
- `TEACH_STYLE_PRESETS` - Map of 4 style presets
- `_teach_resolve_content()` - Content resolution algorithm
- `_teach_build_content_instructions()` - Instruction builder

**Global State:**

```zsh
TEACH_CONTENT_RESOLVED=""  # Space-separated content list
```

**Resolution Algorithm:**

```zsh
1. Initialize content_list = []
2. If style preset exists:
     content_list = preset_content
3. For each positive flag (--X):
     Add X to content_list
4. For each negation flag (--no-X):
     Remove X from content_list
5. Return deduplicated content_list
```

### Phase 3: Lesson Plan Integration

**Purpose:** Load lesson plans and integrate with course config

```mermaid
graph TB
    Week[Week Number] --> LoadPlan{Lesson Plan\nExists?}
    LoadPlan -->|Yes| ParseYAML[Parse YAML with yq]
    LoadPlan -->|No| Lookup[_teach_lookup_topic]

    ParseYAML --> SetPlanVars[Set TEACH_PLAN_*]
    Lookup --> ConfigTopic{Topic\nFound?}

    ConfigTopic -->|Yes| Prompt[_teach_prompt_missing_plan]
    ConfigTopic -->|No| Error[Error: No topic]

    SetPlanVars --> SetTopic[Set TEACH_TOPIC]
    Prompt -->|Yes| SetTopic
    Prompt -->|No| Cancel[Cancel]
```

**Components:**
- `_teach_load_lesson_plan()` - YAML parsing
- `_teach_lookup_topic()` - Config fallback
- `_teach_prompt_missing_plan()` - User confirmation
- `_teach_integrate_lesson_plan()` - Main orchestrator

**Global State:**

```zsh
TEACH_PLAN_TOPIC=""           # Topic from plan
TEACH_PLAN_STYLE=""           # Style from plan
TEACH_PLAN_OBJECTIVES=""      # Pipe-separated
TEACH_PLAN_SUBTOPICS=""       # Pipe-separated
TEACH_PLAN_KEY_CONCEPTS=""    # Pipe-separated
TEACH_PLAN_PREREQUISITES=""   # Pipe-separated
TEACH_RESOLVED_STYLE=""       # Final style
```

### Phase 4: Interactive Mode

**Purpose:** Step-by-step wizards for topic and style selection

```mermaid
graph TB
    Interactive{-i flag?} -->|Yes| CheckTopic{Topic\nProvided?}
    CheckTopic -->|No| TopicWizard[_teach_select_topic_interactive]
    CheckTopic -->|Yes| CheckStyle{Style\nProvided?}

    TopicWizard --> SetWeek[Set TEACH_WEEK]
    SetWeek --> CheckStyle

    CheckStyle -->|No| StyleWizard[_teach_select_style_interactive]
    CheckStyle -->|Yes| Done[Continue]

    StyleWizard --> ReturnStyle[Return Style]
```

**Components:**
- `_teach_select_style_interactive()` - Style menu (4 options)
- `_teach_select_topic_interactive()` - Topic menu (from schedule)
- `_teach_interactive_wizard()` - Main wizard orchestrator

**UI Flow:**

```
1. Banner: "Interactive Teaching Content Generator"
2. If no week/topic → Show topic selection menu
3. User selects week [1-N]
4. If no style → Show style selection menu
5. User selects style [1-4]
6. Return selected style
```

### Phase 5: Revision Workflow

**Purpose:** Improve existing content with 6 revision options

```mermaid
graph TB
    ReviseFlag[--revise FILE] --> ValidateFile{File\nExists?}
    ValidateFile -->|No| Error[Error]
    ValidateFile -->|Yes| Analyze[_teach_analyze_file]

    Analyze --> Type[Content Type]
    Type --> Preview[_teach_show_diff_preview]
    Preview --> Menu[_teach_revision_menu]

    Menu --> UserChoice{User\nSelects\nOption}
    UserChoice --> Opt1[1: Add missing content]
    UserChoice --> Opt2[2: Improve clarity]
    UserChoice --> Opt3[3: Fix errors]
    UserChoice --> Opt4[4: Update examples]
    UserChoice --> Opt5[5: Enhance formatting]
    UserChoice --> Opt6[6: Custom instructions]

    Opt1 --> SetVars[Set TEACH_REVISE_*]
    Opt2 --> SetVars
    Opt3 --> SetVars
    Opt4 --> SetVars
    Opt5 --> SetVars
    Opt6 --> SetVars
```

**Components:**
- `_teach_analyze_file()` - Content type detection (56 lines)
- `_teach_revision_menu()` - 6-option menu (58 lines)
- `_teach_show_diff_preview()` - Git diff display (26 lines)
- `_teach_revise_workflow()` - Main orchestrator (48 lines)

**Global State:**

```zsh
TEACH_REVISE_MODE="improve"       # Always "improve" for now
TEACH_REVISE_FILE=""              # File being revised
TEACH_REVISE_INSTRUCTIONS=""      # User-selected instruction
```

**Content Type Detection:**

```zsh
# Check YAML frontmatter
format: revealjs → slides
format: beamer → slides
title: "*Exam*" → exam
title: "*Quiz*" → quiz

# Check content patterns
"# Homework" → assignment
"Course: " → syllabus
"Criteria|Rubric" → rubric
```

### Phase 6: Context Integration

**Purpose:** Gather course context from materials

```mermaid
graph TB
    ContextFlag[--context] --> SearchFiles[Search for Context Files]
    SearchFiles --> Config[.flow/teach-config.yml]
    SearchFiles --> Syllabus[syllabus.md]
    SearchFiles --> README[README.md]

    Config --> Extract{File\nExists?}
    Syllabus --> Extract
    README --> Extract

    Extract -->|Yes| ReadFile[Read File Content]
    Extract -->|No| Skip[Skip]

    ReadFile --> BuildContext[Build Context Text]
    Skip --> BuildContext

    BuildContext --> SetVar[Set TEACH_CONTEXT]
```

**Components:**
- `_teach_build_context()` - Context gathering (40 lines)

**Global State:**

```zsh
TEACH_CONTEXT=""  # Course context text
```

**Context Format:**

```
Course Information:
- From: .flow/teach-config.yml
- Content: [course name, semester, year]

Course Materials:
- From: syllabus.md
- Content: [first 500 chars]

Project Overview:
- From: README.md
- Content: [first 500 chars]
```

---

## Data Flow

### Complete Request Flow

```mermaid
sequenceDiagram
    participant User
    participant Dispatcher
    participant Wrapper
    participant Phases
    participant Scholar

    User->>Dispatcher: teach slides -w 8 --style computational --diagrams
    Dispatcher->>Wrapper: _teach_scholar_wrapper("slides", args)

    Note over Wrapper: Phase 5: Check --revise
    Wrapper->>Phases: _teach_validate_content_flags(args)
    Phases-->>Wrapper: Valid

    Note over Wrapper: Phase 1: Validate flags
    Wrapper->>Phases: _teach_parse_topic_week(args)
    Phases-->>Wrapper: TEACH_WEEK=8

    Note over Wrapper: Phase 3: Load lesson plan
    Wrapper->>Phases: _teach_integrate_lesson_plan(8, "computational")
    Phases-->>Wrapper: TEACH_TOPIC="Multiple Regression"

    Note over Wrapper: Phase 2: Resolve content
    Wrapper->>Phases: _teach_resolve_content("computational", --diagrams)
    Phases-->>Wrapper: TEACH_CONTENT_RESOLVED="explanation examples code practice-problems diagrams"

    Note over Wrapper: Phase 2: Build instructions
    Wrapper->>Phases: _teach_build_content_instructions()
    Phases-->>Wrapper: Scholar instructions

    Note over Wrapper: Build Scholar command
    Wrapper->>Scholar: claude run /teaching:slides "Multiple Regression" + instructions
    Scholar-->>Wrapper: Generated content

    Wrapper-->>Dispatcher: Success
    Dispatcher-->>User: Content saved
```

### Interactive Mode Flow

```mermaid
sequenceDiagram
    participant User
    participant Wrapper
    participant Interactive
    participant Phase3
    participant Phase2

    User->>Wrapper: teach slides -i

    Note over Wrapper: Phase 4: Interactive wizard
    Wrapper->>Interactive: _teach_interactive_wizard("slides", "", "")

    Note over Interactive: No week provided
    Interactive->>User: Show topic menu (16 weeks)
    User->>Interactive: Select 8
    Interactive-->>Wrapper: TEACH_WEEK=8

    Note over Interactive: No style provided
    Interactive->>User: Show style menu (4 options)
    User->>Interactive: Select 2 (computational)
    Interactive-->>Wrapper: Return "computational"

    Note over Wrapper: Phase 3: Load lesson plan
    Wrapper->>Phase3: _teach_integrate_lesson_plan(8, "computational")
    Phase3-->>Wrapper: TEACH_TOPIC="Multiple Regression"

    Note over Wrapper: Phase 2: Resolve content
    Wrapper->>Phase2: _teach_resolve_content("computational")
    Phase2-->>Wrapper: TEACH_CONTENT_RESOLVED="explanation examples code practice-problems"
```

### Revision Workflow Flow

```mermaid
sequenceDiagram
    participant User
    participant Wrapper
    participant Revision
    participant Scholar

    User->>Wrapper: teach slides --revise slides/week-08.qmd --diagrams

    Note over Wrapper: Phase 5: Revision workflow
    Wrapper->>Revision: _teach_revise_workflow("slides/week-08.qmd")

    Revision->>Revision: _teach_analyze_file()
    Note over Revision: Detected: slides

    Revision->>Revision: _teach_show_diff_preview()
    Note over Revision: Shows git diff

    Revision->>User: Show revision menu (6 options)
    User->>Revision: Select 1 (Add missing content)

    Revision-->>Wrapper: TEACH_REVISE_INSTRUCTIONS="Add missing content and fill gaps"

    Note over Wrapper: Phase 2: Add diagrams flag
    Wrapper->>Wrapper: _teach_resolve_content("", --diagrams)

    Note over Wrapper: Build Scholar command with revision
    Wrapper->>Scholar: claude run /teaching:slides + revision + diagrams
    Scholar-->>Wrapper: Improved content
```

---

## Phase Integration

### Execution Order

The wrapper executes phases in this specific order:

```zsh
_teach_scholar_wrapper() {
    # 1. PHASE 5: Revision workflow (if --revise)
    if [[ -n "$revise_file" ]]; then
        _teach_revise_workflow "$revise_file" || return 1
    fi

    # 2. PHASE 6: Context integration (if --context)
    if [[ "$use_context" == "true" ]]; then
        course_context=$(_teach_build_context)
    fi

    # 3. PHASE 1: Flag validation
    _teach_validate_content_flags "${args[@]}" || return 1

    # 4. PHASE 1: Topic/week parsing
    _teach_parse_topic_week "${args[@]}" || return 1

    # 5. PHASE 4: Interactive wizard (if -i)
    if [[ "$interactive" == "true" ]]; then
        wizard_style=$(_teach_interactive_wizard "$subcommand" "$topic" "$style") || return 1
    fi

    # 6. PHASE 3: Lesson plan integration (if --week)
    if [[ -n "$TEACH_WEEK" ]]; then
        _teach_integrate_lesson_plan "$TEACH_WEEK" "$style" || return 1
    fi

    # 7. PHASE 2: Content resolution
    _teach_resolve_content "$final_style" "${args[@]}"

    # 8. PHASE 2: Build instructions
    local content_instructions=$(_teach_build_content_instructions)

    # 9. Build and execute Scholar command
    local scholar_cmd="claude run /teaching:$subcommand"
    # ... add revision, context, instructions
}
```

### Why This Order?

1. **Revision first** - Establishes file context before other processing
2. **Context second** - Available throughout remaining phases
3. **Validation third** - Catch errors early
4. **Topic/week fourth** - Needed for interactive and lesson plan phases
5. **Interactive fifth** - Can override or supplement previous selections
6. **Lesson plan sixth** - Uses week from previous phases
7. **Content resolution seventh** - Uses style from all previous phases
8. **Instructions eighth** - Final step before Scholar invocation

---

## State Management

### Global Variables

**Phase 1 Variables:**

```zsh
typeset -g TEACH_TOPIC=""        # Explicit topic
typeset -g TEACH_WEEK=""         # Week number
```

**Phase 2 Variables:**

```zsh
typeset -g TEACH_CONTENT_RESOLVED=""  # Resolved content list
```

**Phase 3 Variables:**

```zsh
typeset -g TEACH_PLAN_TOPIC=""           # From lesson plan
typeset -g TEACH_PLAN_STYLE=""           # From lesson plan
typeset -g TEACH_PLAN_OBJECTIVES=""      # From lesson plan
typeset -g TEACH_PLAN_SUBTOPICS=""       # From lesson plan
typeset -g TEACH_PLAN_KEY_CONCEPTS=""    # From lesson plan
typeset -g TEACH_PLAN_PREREQUISITES=""   # From lesson plan
typeset -g TEACH_RESOLVED_STYLE=""       # Final style
```

**Phase 5 Variables:**

```zsh
typeset -g TEACH_REVISE_MODE=""          # Always "improve"
typeset -g TEACH_REVISE_FILE=""          # File being revised
typeset -g TEACH_REVISE_INSTRUCTIONS=""  # Revision instruction
```

**Phase 6 Variables:**

```zsh
typeset -g TEACH_CONTEXT=""  # Course context
```

### State Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Initialized
    Initialized --> FlagsValidated: Phase 1
    FlagsValidated --> TopicResolved: Phase 1/3/4
    TopicResolved --> StyleResolved: Phase 2/3/4
    StyleResolved --> ContentResolved: Phase 2
    ContentResolved --> InstructionsBuilt: Phase 2
    InstructionsBuilt --> ScholarCalled: Execute
    ScholarCalled --> [*]

    note right of TopicResolved
        Topic can come from:
        - Explicit --topic flag
        - Lesson plan
        - Interactive wizard
        - Config fallback
    end note

    note right of StyleResolved
        Style can come from:
        - Explicit --style flag
        - Lesson plan
        - Interactive wizard
        - Default (none)
    end note
```

---

## Sequence Diagrams

### Complete Workflow (All Phases)

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant W as Wrapper
    participant P1 as Phase 1
    participant P2 as Phase 2
    participant P3 as Phase 3
    participant P4 as Phase 4
    participant P5 as Phase 5
    participant P6 as Phase 6
    participant S as Scholar

    U->>W: teach slides -i -w 8 --context --diagrams

    W->>P6: _teach_build_context()
    P6-->>W: context text

    W->>P1: _teach_validate_content_flags()
    P1-->>W: valid ✓

    W->>P1: _teach_parse_topic_week()
    P1-->>W: TEACH_WEEK=8

    W->>P4: _teach_interactive_wizard()
    P4->>U: Show style menu
    U->>P4: Select "computational"
    P4-->>W: "computational"

    W->>P3: _teach_integrate_lesson_plan(8, "computational")
    P3-->>W: TEACH_TOPIC="Multiple Regression"

    W->>P2: _teach_resolve_content("computational", --diagrams)
    P2-->>W: "explanation examples code practice-problems diagrams"

    W->>P2: _teach_build_content_instructions()
    P2-->>W: instructions

    W->>S: Execute with context + instructions
    S-->>U: Generated slides
```

---

## Design Patterns

### 1. Pipeline Pattern

Each phase transforms data in sequence:

```
Input → Validation → Parsing → Interactive → Integration → Resolution → Output
```

### 2. Composition Pattern

Phases are composable and optional:

```zsh
# Minimal
teach slides "Topic"

# + Style
teach slides "Topic" --style computational

# + Week
teach slides -w 8 --style computational

# + Interactive
teach slides -i --style computational

# + Context
teach slides -i --style computational --context

# + Revision
teach slides --revise file.qmd --context
```

### 3. Strategy Pattern

Content resolution uses different strategies:

- **Preset Strategy**: Load from style preset
- **Override Strategy**: Add/remove from preset
- **Direct Strategy**: No preset, individual flags

### 4. Template Method Pattern

`_teach_scholar_wrapper()` defines the algorithm skeleton, phases fill in the steps:

```zsh
_teach_scholar_wrapper() {
    validate()      # Phase 1
    parse()         # Phase 1
    interactive()   # Phase 4 (optional)
    integrate()     # Phase 3 (optional)
    resolve()       # Phase 2
    execute()       # Final step
}
```

### 5. Facade Pattern

Wrapper provides simple interface to complex phase system:

```zsh
# User sees simple command
teach slides -w 8 --style computational

# Under the hood: 6 phases + Scholar integration
```

---

## Performance Considerations

### Optimization Strategies

1. **Lazy Loading**: Lesson plans loaded only when `-w` specified
2. **Short-circuit**: Validation fails fast on conflicts
3. **Caching**: Config parsed once per invocation
4. **Minimal I/O**: Only read necessary files

### Bottlenecks

| Operation | Time | Mitigation |
|-----------|------|------------|
| yq YAML parsing | ~5ms | Cache results, graceful fallback |
| File I/O | ~10ms | Read only needed files |
| User input | Variable | Cannot optimize |
| Scholar execution | 10-60s | Claude Code overhead, not our code |

---

## Future Architecture

### Planned Enhancements

1. **Context Caching**: Cache course context with invalidation
2. **Batch Mode**: Process multiple files in single invocation
3. **Plugin System**: Allow custom revision options
4. **Template Engine**: User-defined content templates
5. **Revision History**: Track and rollback revisions

### Extensibility Points

- **New Presets**: Add to `TEACH_STYLE_PRESETS` map
- **New Content Flags**: Add to `TEACH_CONTENT_FLAGS` array
- **New Revision Options**: Extend `_teach_revision_menu()`
- **New Context Sources**: Extend `_teach_build_context()`

---

**Last Updated:** 2026-01-17
**Status:** Production Ready
**Version:** v5.13.0
