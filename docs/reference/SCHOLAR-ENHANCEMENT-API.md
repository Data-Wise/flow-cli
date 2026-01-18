# Scholar Enhancement API Reference

**Feature:** Teaching Content Generation with AI
**Version:** v5.13.0 (Phases 1-6)
**Date:** 2026-01-17
**Status:** Production Ready

---

## Table of Contents

- [Overview](#overview)
- [Universal Flags](#universal-flags)
- [Style Presets](#style-presets)
- [Content Customization](#content-customization)
- [Workflow Modes](#workflow-modes)
- [Scholar Commands](#scholar-commands)
- [Usage Examples](#usage-examples)
- [Advanced Workflows](#advanced-workflows)
- [API Functions](#api-functions)
- [Configuration](#configuration)
- [Troubleshooting](#troubleshooting)

---

## Overview

The Scholar Enhancement extends the teach dispatcher with AI-powered content generation capabilities. It provides a flexible, composable system for creating teaching materials with Claude Code and the Scholar plugin.

### Key Capabilities

- **Style Presets**: 4 predefined content styles (conceptual, computational, rigorous, applied)
- **Content Customization**: 9 flags to add/remove specific content types
- **Lesson Plans**: YAML-based lesson plans with automatic topic/style loading
- **Interactive Mode**: Step-by-step wizards for topic and style selection
- **Revision Workflow**: 6 improvement options for existing content
- **Context Integration**: Course-aware generation using syllabus and config

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│ User Command                                            │
│ teach slides -w 8 --style computational --diagrams      │
└────────────────────┬────────────────────────────────────┘
                     │
         ┌───────────▼────────────┐
         │ teach() dispatcher      │
         └───────────┬────────────┘
                     │
         ┌───────────▼────────────────────────────────────┐
         │ _teach_scholar_wrapper()                       │
         │   Phase 5: Revision workflow (--revise)        │
         │   Phase 6: Context integration (--context)     │
         │   Phase 1: Flag validation                     │
         │   Phase 2: Topic/week parsing                  │
         │   Phase 4: Interactive wizard (-i)             │
         │   Phase 3: Lesson plan integration (-w)        │
         │   Phase 2: Content resolution (--style, flags) │
         │   Phase 2: Build Scholar command               │
         └───────────┬────────────────────────────────────┘
                     │
         ┌───────────▼────────────┐
         │ Claude Code + Scholar   │
         │ (AI content generation) │
         └─────────────────────────┘
```

---

## Universal Flags

These flags work with all Scholar commands: `slides`, `exam`, `quiz`, `lecture`, `assignment`, `syllabus`, `rubric`, `feedback`, `demo`.

### Topic Selection

| Flag | Short | Type | Description |
|------|-------|------|-------------|
| `--topic TOPIC` | `-t` | string | Explicit topic (bypasses lesson plan) |
| `--week N` | `-w` | number | Week number (loads lesson plan if exists) |

**Priority Rules:**
- If both `--topic` and `--week` are specified, `--topic` takes precedence
- `--week` triggers lesson plan loading from `.flow/lesson-plans/week-{N}.yml`
- If lesson plan missing, falls back to `teach-config.yml` semester schedule

**Examples:**
```bash
teach slides --topic "Linear Regression"      # Direct topic
teach exam -w 8                                # Week 8 (loads lesson plan)
teach quiz -t "ANOVA" -w 8                    # Topic overrides week
```

### Content Style Presets

| Flag | Values | Description |
|------|--------|-------------|
| `--style PRESET` | `conceptual`, `computational`, `rigorous`, `applied` | Content style preset |

**Preset Definitions:**

| Preset | Includes | Best For |
|--------|----------|----------|
| `conceptual` | explanation, definitions, examples | Introductory courses, theory |
| `computational` | explanation, examples, code, practice-problems | Applied statistics, data science |
| `rigorous` | definitions, explanation, math, proof | Graduate courses, theory |
| `applied` | explanation, examples, code, practice-problems | Hands-on courses, workshops |

**Examples:**
```bash
teach slides -w 8 --style computational
teach exam "Hypothesis Testing" --style rigorous
```

---

## Content Customization

### Content Flags (Positive)

Add specific content types to the output.

| Flag | Short | Description | Maps To |
|------|-------|-------------|---------|
| `--explanation` | `-e` | Conceptual explanations | "Include conceptual explanations of the topic" |
| `--definitions` | | Formal definitions | "Include formal definitions of terms" |
| `--proof` | | Mathematical proofs | "Include mathematical proofs where appropriate" |
| `--math` | `-m` | Mathematical notation | "Use mathematical notation and formulas" |
| `--examples` | `-x` | Numerical examples | "Include numerical examples to illustrate concepts" |
| `--code` | `-c` | Code snippets | "Include code snippets and programming examples" |
| `--diagrams` | `-d` | Diagrams/visualizations | "Include diagrams, plots, and visualizations" |
| `--practice-problems` | `-p` | Practice problems | "Include practice problems for students" |
| `--references` | `-r` | Citations/references | "Include citations and references to literature" |

### Content Flags (Negation)

Remove specific content types from presets or defaults.

| Flag | Description |
|------|-------------|
| `--no-explanation` | Exclude conceptual explanations |
| `--no-definitions` | Exclude formal definitions |
| `--no-proof` | Exclude mathematical proofs |
| `--no-math` | Exclude mathematical notation |
| `--no-examples` | Exclude numerical examples |
| `--no-code` | Exclude code snippets |
| `--no-diagrams` | Exclude diagrams/visualizations |
| `--no-practice-problems` | Exclude practice problems |
| `--no-references` | Exclude citations/references |

### Content Resolution Rules

1. **Start with preset** (if `--style` specified)
2. **Add positive flags** (`--diagrams`, `--references`)
3. **Remove negation flags** (`--no-proof`, `--no-practice-problems`)
4. **Build instructions** from resolved content list

**Conflict Detection:**
- Cannot use both `--flag` and `--no-flag` (e.g., `--math` and `--no-math`)
- Error message shows fix suggestions

**Examples:**
```bash
# Start with computational preset, add diagrams
teach slides -w 8 --style computational --diagrams
# → explanation, examples, code, practice-problems, diagrams

# Start with rigorous preset, remove proofs
teach exam "Topic" --style rigorous --no-proof
# → definitions, explanation, math (no proof)

# Individual flags (no preset)
teach slides "Topic" --explanation --math --examples
# → explanation, math, examples only

# Short forms
teach quiz "ANOVA" -e -m -x -c
# → explanation, math, examples, code
```

---

## Workflow Modes

### Interactive Mode

**Flags:** `--interactive`, `-i`

Step-by-step wizard for topic and style selection.

**Behavior:**
1. If no week/topic specified → Shows topic selection menu (from config)
2. If no style specified → Shows style preset menu (4 options)
3. Proceeds with selected values

**Menu Example:**
```
╭────────────────────────────────────────────────╮
│ 🎓 Interactive Teaching Content Generator     │
╰────────────────────────────────────────────────╯

📅 Select Week/Topic

  [ 1] Week  1  Introduction to Statistics
  [ 2] Week  2  Probability Basics
  [ 3] Week  3  Random Variables
  ...
  [ 8] Week  8  Multiple Regression

Your choice [1-16]: 8

📚 Content Style

What style should this content use?

  [1] conceptual    Explanation + definitions + examples
  [2] computational Explanation + examples + code + practice
  [3] rigorous      Definitions + explanation + math + proofs
  [4] applied       Explanation + examples + code + practice

Your choice [1-4]: 2

→ Generating slides for Week 8 with computational style
```

**Examples:**
```bash
# Full interactive mode
teach slides -i

# Interactive with week pre-selected
teach exam -i -w 8

# Interactive with style pre-selected
teach quiz -i --style rigorous
```

### Revision Workflow

**Flag:** `--revise FILE`

Improve existing content with 6 revision options.

**Behavior:**
1. Validates file exists and is readable
2. Analyzes file to detect content type (slides, exam, quiz, etc.)
3. Shows git diff preview (if in repo)
4. Presents revision menu (6 options)
5. Applies selected revision with Scholar

**Revision Menu:**
```
📝 Revision Options

What would you like to improve?

  [1] Add missing content          Fill gaps, add sections
  [2] Improve clarity/organization Restructure, clarify
  [3] Fix errors/inconsistencies   Correct mistakes
  [4] Update examples/exercises    Refresh examples
  [5] Enhance formatting/style     Polish presentation
  [6] Custom instructions          Your own guidance

Your choice [1-6]:
```

**Detected Content Types:**
- `slides` - Presentation slides (RevealJS, Quarto)
- `lecture` - Lecture notes
- `exam` - Exams and assessments
- `quiz` - Quizzes
- `assignment` - Homework assignments
- `syllabus` - Course syllabi
- `rubric` - Grading rubrics

**Examples:**
```bash
# Revise existing slides
teach slides --revise slides/week-08.qmd

# Revise with additional content flags
teach exam --revise exams/midterm.qmd --math --examples

# Revise and add diagrams
teach lecture --revise lecture.md --diagrams
```

### Context Integration

**Flag:** `--context`

Include course context from materials (syllabus, config, README).

**Behavior:**
1. Searches for context files in project:
   - `.flow/teach-config.yml` (course metadata)
   - `syllabus.md` (course objectives)
   - `README.md` (project overview)
2. Extracts relevant information
3. Includes in Scholar prompt for context-aware generation

**Examples:**
```bash
# Generate with course context
teach slides -w 8 --context

# Context + style preset
teach exam "Multiple Regression" --context --style rigorous

# Context + revision
teach lecture --revise lecture.md --context
```

---

## Scholar Commands

All Scholar commands support universal flags, style presets, content customization, and workflow modes.

### `teach slides` / `teach sl`

Generate presentation slides.

**Usage:**
```bash
teach slides "Topic" [options]
teach slides -w N [options]
teach slides -i [options]
```

**Slides-Specific Options:**
- `--theme NAME` - Slide theme (default, academic, minimal)
- `--from-lecture FILE` - Generate from lecture file
- `--format FORMAT` - Output format (quarto, markdown)
- `--dry-run` - Preview without saving

**Examples:**
```bash
# Week 8 with computational style
teach slides -w 8 --style computational

# Interactive mode
teach slides -i

# Custom topic with diagrams
teach slides "Linear Regression" --diagrams --code

# Revise existing slides
teach slides --revise slides/week-08.qmd
```

### `teach exam` / `teach e`

Generate exam questions.

**Usage:**
```bash
teach exam "Topic" [options]
```

**Exam-Specific Options:**
- `--questions N` - Number of questions (default: 20)
- `--duration MIN` - Time limit in minutes (default: 120)
- `--types TYPES` - Question types (mc,sa,essay,calc)
- `--format FORMAT` - Output format (quarto, qti, markdown)
- `--dry-run` - Preview without saving

**Examples:**
```bash
# Rigorous exam with proofs
teach exam "Hypothesis Testing" --style rigorous --proof

# 10-question quiz format
teach exam "ANOVA" --questions 10 --duration 30

# Computational exam
teach exam -w 8 --style computational
```

### `teach quiz` / `teach q`

Generate quiz questions.

**Usage:**
```bash
teach quiz "Topic" [options]
```

**Quiz-Specific Options:**
- `--questions N` - Number of questions (default: 10)
- `--time-limit MIN` - Time limit in minutes (default: 15)
- `--format FORMAT` - Output format (quarto, qti, markdown)
- `--dry-run` - Preview without saving

**Examples:**
```bash
# Quick quiz
teach quiz "Probability" --questions 5

# Week 3 computational quiz
teach quiz -w 3 --style computational
```

### `teach lecture` / `teach lec`

Generate lecture content.

**Usage:**
```bash
teach lecture "Topic" [options]
```

**Lecture-Specific Options:**
- `--outline` - Generate outline only
- `--notes` - Include speaker notes
- `--from-plan WEEK` - Generate from lesson plan
- `--format FORMAT` - Output format (quarto, markdown)
- `--dry-run` - Preview without saving

**Examples:**
```bash
# Conceptual lecture
teach lecture "Introduction to Regression" --style conceptual

# Outline only
teach lecture -w 1 --outline

# With context
teach lecture "Topic" --context
```

### `teach assignment` / `teach hw`

Generate homework assignment.

**Usage:**
```bash
teach assignment "Topic" [options]
```

**Assignment-Specific Options:**
- `--due-date DATE` - Due date (YYYY-MM-DD)
- `--points N` - Total points (default: 100)
- `--format FORMAT` - Output format (quarto, markdown)
- `--dry-run` - Preview without saving

**Examples:**
```bash
# Computational assignment
teach assignment "Linear Models" --style computational

# With practice problems
teach assignment -w 8 --practice-problems
```

### `teach syllabus` / `teach syl`

Generate course syllabus.

**Usage:**
```bash
teach syllabus [options]
```

**Syllabus-Specific Options:**
- `--format FORMAT` - Output format (quarto, markdown, pdf)
- `--dry-run` - Preview without saving

**Note:** Uses course info from `.flow/teach-config.yml`

**Examples:**
```bash
# Generate syllabus with context
teach syllabus --context

# PDF format
teach syllabus --format pdf
```

### `teach rubric` / `teach rb`

Generate grading rubric.

**Usage:**
```bash
teach rubric "Assignment Name" [options]
```

**Rubric-Specific Options:**
- `--criteria N` - Number of criteria
- `--format FORMAT` - Output format (quarto, markdown)
- `--dry-run` - Preview without saving

**Examples:**
```bash
# Simple rubric
teach rubric "Homework 3"

# Detailed rubric
teach rubric "Final Project" --criteria 8
```

### `teach feedback` / `teach fb`

Generate student feedback.

**Usage:**
```bash
teach feedback "Student Work" [options]
```

**Feedback-Specific Options:**
- `--tone TONE` - Feedback tone (supportive, direct, detailed)
- `--format FORMAT` - Output format (markdown, text)
- `--dry-run` - Preview without saving

**Examples:**
```bash
# Supportive feedback
teach feedback "student-submission.pdf" --tone supportive

# Detailed feedback
teach feedback "homework.R" --tone detailed
```

### `teach demo`

Create demo course materials.

**Usage:**
```bash
teach demo [options]
```

**Demo-Specific Options:**
- `--course-name NAME` - Course name (default: STAT-101)
- `--force` - Overwrite existing demo files

**Examples:**
```bash
# Create demo course
teach demo

# Custom course name
teach demo --course-name "STAT-440"
```

---

## Usage Examples

### Basic Workflows

**Example 1: Generate slides from lesson plan**
```bash
# Week 8 with default style from lesson plan
teach slides -w 8

# Override style
teach slides -w 8 --style computational

# Add content
teach slides -w 8 --diagrams --references
```

**Example 2: Custom topic with specific content**
```bash
# Explanation and examples only
teach slides "Linear Regression" -e -x

# Full computational style
teach exam "ANOVA" --style computational

# Rigorous with custom overrides
teach lecture "Probability Theory" --style rigorous --no-proof --diagrams
```

**Example 3: Interactive mode**
```bash
# Full interactive
teach slides -i
# → Select week from menu
# → Select style from menu

# Partial interactive (week known)
teach exam -i -w 8
# → Select style only

# Partial interactive (style known)
teach quiz -i --style computational
# → Select week only
```

### Advanced Workflows

**Example 4: Revision workflow**
```bash
# Basic revision
teach slides --revise slides/week-08.qmd
# → Shows diff
# → Choose improvement option
# → Apply with Scholar

# Revision with content additions
teach exam --revise exams/midterm.qmd --math --examples
# → Adds more math and examples based on menu selection

# Revision with context
teach lecture --revise lecture.md --context
# → Uses course context for improvements
```

**Example 5: Context-aware generation**
```bash
# Slides with course context
teach slides -w 8 --context --style computational
# → Uses syllabus objectives
# → Maintains course consistency

# Exam aligned with course
teach exam "Multiple Regression" --context --rigorous
# → References course metadata
# → Aligns with course level
```

**Example 6: Complex combinations**
```bash
# Interactive + context + custom content
teach slides -i --context --diagrams --references

# Revision + style change + additions
teach lecture --revise lecture.md --style computational --code --practice-problems

# Week + preset + overrides + context
teach exam -w 8 --style rigorous --no-proof --diagrams --context
```

---

## API Functions

### Phase 1: Flag Validation

#### `_teach_validate_content_flags [flags...]`

Validates content flags for conflicts.

**Returns:** 0 if valid, 1 if conflicts detected

**Example:**
```zsh
_teach_validate_content_flags --math --examples  # → 0 (valid)
_teach_validate_content_flags --math --no-math   # → 1 (conflict)
```

### Phase 2: Content Resolution

#### `_teach_parse_topic_week [flags...]`

Extracts topic and week from arguments.

**Sets:**
- `TEACH_TOPIC` - Explicit topic string
- `TEACH_WEEK` - Week number

**Example:**
```zsh
_teach_parse_topic_week --topic "Linear Regression"
# TEACH_TOPIC="Linear Regression", TEACH_WEEK=""

_teach_parse_topic_week -w 8
# TEACH_TOPIC="", TEACH_WEEK="8"
```

#### `_teach_resolve_content <style> [flags...]`

Resolves content flags from preset and overrides.

**Args:**
- `style` - Style preset name or empty string
- `flags...` - Content flags to add/remove

**Sets:** `TEACH_CONTENT_RESOLVED` - Space-separated content list

**Example:**
```zsh
_teach_resolve_content "computational" --diagrams --no-practice-problems
# TEACH_CONTENT_RESOLVED="explanation examples code diagrams"
```

#### `_teach_build_content_instructions`

Builds Scholar instructions from resolved content.

**Returns:** Newline-separated instructions

**Example:**
```zsh
TEACH_CONTENT_RESOLVED="explanation math examples"
local instructions=$(_teach_build_content_instructions)
# Returns:
# "Include conceptual explanations of the topic
# Use mathematical notation and formulas
# Include numerical examples to illustrate concepts"
```

### Phase 3: Lesson Plan Integration

#### `_teach_load_lesson_plan <week>`

Loads YAML lesson plan for specified week.

**Args:**
- `week` - Week number

**Sets:**
- `TEACH_PLAN_TOPIC` - Topic from plan
- `TEACH_PLAN_STYLE` - Style preset from plan
- `TEACH_PLAN_OBJECTIVES` - Pipe-separated objectives
- `TEACH_PLAN_SUBTOPICS` - Pipe-separated subtopics
- `TEACH_PLAN_KEY_CONCEPTS` - Pipe-separated concepts
- `TEACH_PLAN_PREREQUISITES` - Pipe-separated prerequisites

**Returns:** 0 if loaded, 1 if not found

**Example:**
```zsh
_teach_load_lesson_plan 8
# Loads .flow/lesson-plans/week-08.yml
# Sets TEACH_PLAN_* variables
```

#### `_teach_lookup_topic <week>`

Fallback topic lookup from teach-config.yml.

**Args:**
- `week` - Week number

**Returns:** Topic string or empty

**Example:**
```zsh
local topic=$(_teach_lookup_topic 12)
# Returns topic from config semester schedule
```

#### `_teach_integrate_lesson_plan <week> <style>`

Main lesson plan integration orchestrator.

**Args:**
- `week` - Week number
- `style` - Style override or empty

**Sets:**
- `TEACH_TOPIC` - Resolved topic
- `TEACH_RESOLVED_STYLE` - Final style

**Returns:** 0 if successful, 1 if cancelled

**Example:**
```zsh
_teach_integrate_lesson_plan 8 "computational"
# Loads plan, applies style override, prompts if needed
```

### Phase 4: Interactive Mode

#### `_teach_select_style_interactive`

Shows style selection menu.

**Returns:** Selected style name

**Example:**
```zsh
local style=$(_teach_select_style_interactive)
# User selects from menu
# Returns: "conceptual" | "computational" | "rigorous" | "applied"
```

#### `_teach_select_topic_interactive`

Shows topic selection menu from schedule.

**Returns:** Selected week number

**Example:**
```zsh
local week=$(_teach_select_topic_interactive)
# User selects from menu
# Returns: "8"
```

#### `_teach_interactive_wizard <cmd> <topic> <style>`

Main interactive wizard orchestrator.

**Args:**
- `cmd` - Subcommand name
- `topic` - Topic (if already set)
- `style` - Style (if already set)

**Sets:**
- `TEACH_WEEK` - Selected week (if not provided)
- `TEACH_TOPIC` - Selected topic (if not provided)

**Returns:** Selected style

**Example:**
```zsh
local style=$(_teach_interactive_wizard "slides" "" "")
# Shows topic menu, then style menu
# Returns selected style
```

### Phase 5: Revision Workflow

#### `_teach_analyze_file <file>`

Detects content type from file.

**Args:**
- `file` - File path

**Returns:** Content type string

**Detectable Types:**
- `slides` - Presentation slides
- `lecture` - Lecture notes
- `exam` - Exams
- `quiz` - Quizzes
- `assignment` - Assignments
- `syllabus` - Syllabi
- `rubric` - Rubrics
- `unknown` - Unknown type

**Example:**
```zsh
local type=$(_teach_analyze_file "slides/week-08.qmd")
# Returns: "slides"
```

#### `_teach_revision_menu <file> <type>`

Shows revision options menu.

**Args:**
- `file` - File path
- `type` - Content type

**Returns:** Revision instruction string

**Example:**
```zsh
local instruction=$(_teach_revision_menu "slides.qmd" "slides")
# User selects option [1-6]
# Returns formatted instruction for Scholar
```

#### `_teach_show_diff_preview <file>`

Shows git diff preview for file.

**Args:**
- `file` - File path

**Example:**
```zsh
_teach_show_diff_preview "slides/week-08.qmd"
# Displays git diff or "untracked" message
```

#### `_teach_revise_workflow <file>`

Main revision workflow orchestrator.

**Args:**
- `file` - File to revise

**Sets:**
- `TEACH_REVISE_MODE` - "improve"
- `TEACH_REVISE_FILE` - File path
- `TEACH_REVISE_INSTRUCTIONS` - Revision instructions

**Returns:** 0 if successful, 1 if error

**Example:**
```zsh
_teach_revise_workflow "slides/week-08.qmd"
# Shows preview, menu, sets globals
```

### Phase 6: Context Integration

#### `_teach_build_context`

Gathers course context from materials.

**Returns:** Context text string

**Sources:**
- `.flow/teach-config.yml`
- `syllabus.md`
- `README.md`

**Example:**
```zsh
local context=$(_teach_build_context)
# Returns formatted context text
```

---

## Configuration

### Lesson Plan Schema

**Location:** `.flow/lesson-plans/week-{NN}.yml`

**Format:**
```yaml
week: 8
topic: "Multiple Regression"
style: computational  # Default style for this week

# Learning objectives (optional)
objectives:
  - "Understand multiple regression model assumptions"
  - "Interpret regression coefficients correctly"
  - "Perform model diagnostics in R"

# Subtopics (optional)
subtopics:
  - "Model specification"
  - "Coefficient interpretation"
  - "Multicollinearity"
  - "Model diagnostics"

# Key concepts (optional)
key_concepts:
  - "Partial regression coefficients"
  - "Adjusted R-squared"
  - "VIF (Variance Inflation Factor)"

# Prerequisites (optional)
prerequisites:
  - "Simple linear regression (Week 6)"
  - "Matrix notation basics (Week 7)"
```

**Required Fields:**
- `topic` - Week's topic (string)

**Optional Fields:**
- `style` - Default style preset
- `objectives` - Learning objectives (array)
- `subtopics` - Subtopics to cover (array)
- `key_concepts` - Key concepts (array)
- `prerequisites` - Prerequisites (array)

### Course Configuration

**Location:** `.flow/teach-config.yml`

**Semester Schedule:**
```yaml
semester_info:
  weeks:
    - week: 1
      topic: "Introduction to Statistics"
    - week: 2
      topic: "Probability Basics"
    - week: 8
      topic: "Multiple Regression"
    # ...
```

**Used for:**
- Interactive mode topic selection
- Fallback when lesson plan missing
- Course context integration

---

## Troubleshooting

### Common Issues

**Issue 1: "Conflicting flags" error**

```
❌ teach: Conflicting flags

  Both --math and --no-math specified. These are mutually exclusive.

Fix: Keep one or the other
  teach slides -w 8 --math        # Include math
  teach slides -w 8 --no-math     # Exclude math
```

**Solution:** Remove one of the conflicting flags.

**Issue 2: "yq not found" warning**

```
⚠️  yq not installed - lesson plans disabled
   Install: brew install yq
```

**Solution:** Install `yq` for YAML parsing:
```bash
brew install yq
```

**Issue 3: No lesson plan found**

```
⚠️  No lesson plan found for Week 12

Topic from config: "Time Series"

Continue with this topic? [Y/n]:
```

**Solution:** Either:
- Create lesson plan: `touch .flow/lesson-plans/week-12.yml`
- Continue with config topic (press Enter)
- Cancel and use explicit topic: `teach slides --topic "Time Series"`

**Issue 4: Invalid preset name**

```
❌ Invalid style preset: "advanced"

Valid presets: conceptual, computational, rigorous, applied
```

**Solution:** Use one of the 4 valid presets:
```bash
teach slides -w 8 --style computational  # Correct
```

### Debug Mode

Enable verbose output to see Scholar command:

```bash
teach slides -w 8 --verbose
# Shows: claude run /teaching:slides ...
```

### Validation

Check flag combinations before running:

```bash
# This will validate but not execute
teach slides -w 8 --style rigorous --no-proof --dry-run
```

---

## Performance

### Benchmarks

| Operation | Time | Notes |
|-----------|------|-------|
| Flag parsing | <1ms | Instant |
| Content resolution | <1ms | In-memory |
| Lesson plan load | ~5ms | YAML parsing with yq |
| Topic lookup | <1ms | Config parsing |
| Interactive menu | User-bound | Waits for input |
| Revision analysis | <5ms | Pattern matching |
| Context building | ~10ms | File I/O |

### Memory Usage

| Component | Size | Impact |
|-----------|------|--------|
| Flag arrays | ~2KB | Minimal |
| Global variables | ~3KB | Minimal |
| Functions | ~20KB | One-time load |
| Total overhead | ~25KB | Negligible |

---

## Backward Compatibility

✅ **All new features are opt-in**
- Existing commands work unchanged
- No flags required for basic usage
- All regression tests pass (111/111)

**Example:**
```bash
# v5.12.0 and earlier - still works
teach slides "Topic"

# v5.13.0 - new features optional
teach slides "Topic" --style computational --diagrams
```

---

## Version History

**v5.13.0** (2026-01-17)
- Phase 1-2: Flag infrastructure + style presets
- Phase 3-4: Lesson plans + interactive mode
- Phase 5-6: Revision workflow + context + polish

**Future Enhancements:**
- Batch revision mode
- Revision history tracking
- Context caching
- Custom style presets
- Template system

---

## See Also

- [Teach Dispatcher Reference](TEACH-DISPATCHER-REFERENCE.md)
- [Implementation Phases 1-2](../reports/IMPLEMENTATION-PHASES-1-2.md)
- [Implementation Phases 3-4](../reports/IMPLEMENTATION-PHASES-3-4.md)
- [Implementation Phases 5-6](../reports/IMPLEMENTATION-PHASES-5-6.md)
- [Test Analysis](../reports/TEST-ANALYSIS-PHASES-1-2.md)

---

**Last Updated:** 2026-01-17
**Status:** Production Ready
**Version:** v5.13.0
