# Teaching Material Generation CLI UX Design

**Version:** 1.0.0
**Author:** Claude (UX/UI Designer)
**Date:** January 17, 2026
**Status:** Design Specification

---

## Executive Summary

This document specifies the CLI user experience for the `teach` dispatcher's AI-powered content generation commands. The design prioritizes ADHD-friendly workflows with clear feedback, smart defaults, and minimal cognitive load.

---

## 1. Command Syntax Design

### 1.1 Priority Command Groups

Based on usage patterns, commands are grouped by workflow priority:

| Priority | Commands | Use Case |
|----------|----------|----------|
| **P1** | `slides`, `lecture` | Presentation prep (often paired) |
| **P2** | `quiz`, `exam` | Assessment creation |
| **P3** | `feedback`, `assignment` | Student work & grading |

### 1.2 Command Syntax Patterns

All generation commands follow a consistent pattern:

```
teach <command> [topic] [options]
```

**Core Pattern:**

```bash
teach <cmd> "Topic"              # Basic: auto-detect week, default format
teach <cmd> "Topic" -i           # Interactive: step-by-step prompts
teach <cmd> "Topic" --revise     # Revise: improve existing file
teach <cmd>                      # Smart default: current week's topic
```

### 1.3 Detailed Command Syntax

#### Slides + Lecture (P1)

```bash
# SLIDES - Generate presentation slides
teach slides "Topic"                      # Basic slides
teach slides "Topic" --format qmd         # Quarto format (default)
teach slides "Topic" --format md          # Markdown format
teach slides "Topic" --theme academic     # Theme: academic|minimal|modern
teach slides "Topic" --from-lecture file  # Generate from lecture notes
teach slides -i                           # Interactive mode
teach slides --revise slides/week03.qmd   # Revise existing slides

# LECTURE - Generate lecture notes
teach lecture "Topic"                     # Basic lecture notes
teach lecture "Topic" --outline           # Outline only (quick)
teach lecture "Topic" --notes             # Include speaker notes
teach lecture "Topic" --from-plan week03  # From lesson plan
teach lecture -i                          # Interactive mode
teach lecture --revise lectures/week03.qmd  # Revise existing
```

#### Quiz + Exam (P2)

```bash
# QUIZ - Generate quiz questions
teach quiz "Topic"                        # Default: 10 questions
teach quiz "Topic" -n 15                  # Custom question count
teach quiz "Topic" --time 20              # 20 minute time limit
teach quiz "Topic" --types mc,tf          # Question types: mc,tf,sa,fill
teach quiz -i                             # Interactive mode
teach quiz --revise quizzes/ch05.qmd      # Revise existing

# EXAM - Generate exam questions
teach exam "Topic"                        # Default: 25 questions, 90 min
teach exam "Topic" -n 30                  # Custom question count
teach exam "Topic" --duration 120         # 2 hour exam
teach exam "Topic" --types mc,sa,essay    # Mixed types
teach exam "Topic" --difficulty mixed     # Difficulty: easy|medium|hard|mixed
teach exam -i                             # Interactive mode
teach exam --revise exams/midterm1.qmd    # Revise existing
```

#### Feedback + Assignment (P3)

```bash
# FEEDBACK - Generate student feedback
teach feedback "submission.pdf"           # Analyze and provide feedback
teach feedback "work/" --batch            # Batch feedback for directory
teach feedback "work.pdf" --rubric rubric.yml   # Use specific rubric
teach feedback "work.pdf" --tone supportive     # Tone: supportive|direct|detailed
teach feedback -i                         # Interactive mode

# ASSIGNMENT - Generate homework assignment
teach assignment "Topic"                  # Basic assignment
teach assignment "Topic" --due 2026-01-24 # With due date
teach assignment "Topic" --points 100     # Point value
teach assignment "Topic" --parts 3        # Multi-part assignment
teach assignment -i                       # Interactive mode
teach assignment --revise hw/hw03.qmd     # Revise existing
```

### 1.4 Universal Flags

These flags work with ALL generation commands:

```bash
--format <fmt>     # Output: qmd (default), md, latex
--output <path>    # Custom output path
--context          # Include full course context (larger prompt)
--dry-run          # Preview without saving
--verbose          # Show AI prompt being sent
-i, --interactive  # Interactive mode (step-by-step)
--revise <file>    # Revise existing file
--week <N>         # Override week number (default: auto-detect)
```

### 1.5 Smart Defaults

When no topic is provided, the system auto-detects:

```bash
teach slides                  # Auto: Current week's topic from schedule
teach quiz                    # Auto: Topics covered so far this week
teach exam                    # Auto: All topics in current unit
```

**Auto-detection logic:**
1. Read `teach-config.yml` for semester dates
2. Calculate current week number
3. Look up topic in `schedule.yml` or `_schedule.yml`
4. Fall back to prompt if not found

---

## 2. Progress Indicator Design

### 2.1 Three-Phase Progress Display

AI generation has 3 distinct phases:

```
Phase 1: Preparation     (~1-2s)
Phase 2: AI Generation   (~5-25s)
Phase 3: Post-processing (~1-3s)
```

### 2.2 Progress States

**State 1: Starting (Preparation)**

```
 Preparing slides for "Regression Analysis"...
  Context: Week 8 of 15 | STAT 440
```

**State 2: Generating (AI Working)**

```
 Generating slides (estimated ~20-30s)...
  [===============>        ] 60% | 12s elapsed
  Context: Week 8 of 15 | STAT 440
```

**State 3: Finishing (Post-processing)**

```
 Finalizing content...
  Saving to slides/week08-regression.qmd
```

### 2.3 Spinner Implementation

For operations without determinate progress:

```
 Generating exam (~30-60s)...
```

**Spinner frames (Braille dots):** ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` ` `

**With elapsed time counter:**

```
 Generating exam... 15s
 Generating exam... 16s
 Generating exam... 17s
```

### 2.4 Progress Indicator Specification

| Phase | Duration | Display | Update Rate |
|-------|----------|---------|-------------|
| Prep | 1-2s | Static message | Once |
| Generate | 5-25s | Spinner + timer | 100ms |
| Finish | 1-3s | Static message | Once |

**Implementation (ZSH):**

```zsh
_teach_progress_indicator() {
    local message="$1"
    local estimate="$2"
    local start_time=$(date +%s)

    # Use existing spinner from tui.zsh
    _flow_spinner_start "$message" "$estimate"
}
```

---

## 3. Success/Failure Feedback

### 3.1 Success Message Format

```
 Created: slides/week08-regression.qmd

   File: slides/week08-regression.qmd
   Slides: 24 slides
   Sections: 6 sections
   Images: 4 placeholders

Next steps:
  1. Review in editor     teach slides --revise slides/week08-regression.qmd
  2. Preview slides       qu preview slides/week08-regression.qmd
  3. Commit changes       [1] Review  [2] Commit  [3] Skip
```

### 3.2 Error Message Format

**User Error (recoverable):**

```
 teach: Topic not found in schedule

   Week 8 has no scheduled topic in _schedule.yml

Recovery:
   Specify topic explicitly:  teach slides "Regression Analysis"
   Edit schedule:             teach config
```

**System Error (AI failure):**

```
 teach: AI generation failed

   Claude returned an error after 45s

Details:
   Error: Rate limit exceeded

Recovery:
   1. Wait 60 seconds and retry
   2. Try with --dry-run to test
   3. Check status: claude --status

Retry?  [Y/n]
```

**Config Error:**

```
 teach: Configuration missing

   No .flow/teach-config.yml found

Recovery:
   Initialize teaching workflow:  teach init "STAT 440"
```

### 3.3 Warning Message Format

```
 teach: Using cached context (2 hours old)

   Course context from .flow/cache/context.json is stale

Options:
   Continue anyway:  [Enter]
   Refresh context:  teach refresh
```

### 3.4 Status Icons Reference

| Icon | Meaning | Color |
|------|---------|-------|
|  | Success | Green (#72C77E) |
|  | Error | Red (#E06C75) |
|  | Warning | Yellow (#E5C07B) |
|  | Info | Blue (#61AFEF) |
|  | Working | Blue (animated) |

---

## 4. Interactive Mode (-i) Design

### 4.1 Interactive Flow

Interactive mode provides step-by-step guidance:

```bash
teach slides -i
```

**Step 1: Topic Selection**

```
 Create Slides

Topic:
  1. Week 8: Regression Analysis  (scheduled)
  2. Week 9: Multiple Regression  (upcoming)
  3. Enter custom topic

Your choice [1-3]: _
```

**Step 2: Configuration**

```
 Slide Configuration

Questions:
  Format?      [1] Quarto  [2] Markdown  (default: 1)
  Theme?       [1] Academic  [2] Minimal  [3] Modern  (default: 1)
  Sections?    [1] Auto  [2] Specify count  (default: 1)

Press Enter for defaults, or enter choices: _
```

**Step 3: Confirmation**

```
 Ready to Generate

   Topic: Regression Analysis
   Format: Quarto (.qmd)
   Theme: Academic
   Week: 8 of 15

Generate now?  [Y/n] _
```

### 4.2 Interactive Shortcuts

| Key | Action |
|-----|--------|
| Enter | Accept default |
| Number | Select option |
| q | Quit/cancel |
| ? | Show help |
| b | Go back |

---

## 5. Revise Workflow (--revise)

### 5.1 Revise Command Flow

```bash
teach slides --revise slides/week08.qmd
```

**Step 1: Analysis**

```
 Analyzing existing file...

   File: slides/week08.qmd
   Created: 2026-01-15 14:32
   Slides: 18 slides
   Last AI edit: None
```

**Step 2: Revision Options**

```
 What would you like to improve?

  [1] Expand content        Add more detail to existing slides
  [2] Add examples          Include practical examples
  [3] Simplify language     Make more accessible
  [4] Add visuals           Suggest images/diagrams
  [5] Custom instructions   Enter specific feedback
  [6] Full regenerate       Start fresh (keeps structure)

Your choice [1-6]: _
```

**Step 3: Custom Instructions (if option 5)**

```
 Custom Instructions

Enter your revision instructions:
> Add a slide about interaction terms after slide 12, and simplify the
> mathematical notation on slides 8-10.

Continue?  [Y/n] _
```

**Step 4: Preview Changes**

```
 Preview Changes

   Slides 8-10: Simplified notation
   + New slide 13: "Interaction Terms"
   + New slide 14: "Interaction Example"

Apply changes?  [1] Yes  [2] Show diff  [3] Cancel
```

### 5.2 Diff Display

```diff
 Slide 8: Model Assumptions

- The regression model assumes $E[\epsilon_i | X_i] = 0$
+ The regression model assumes the errors average to zero
+ (mathematically: E[e|X] = 0)

 Slide 13: Interaction Terms (NEW)

+ When effects depend on other variables, we use interactions
+ Example: Does the effect of study time depend on sleep?
```

---

## 6. ADHD-Friendly UX Principles

### 6.1 Design Principles Applied

| Principle | Implementation |
|-----------|----------------|
| **Instant feedback** | Show spinner within 100ms of command |
| **Time awareness** | Always show elapsed time and estimates |
| **Smart defaults** | Auto-detect week, topic, format |
| **Progressive disclosure** | Basic → Interactive → Advanced |
| **Clear next steps** | Always show 1-3 actionable items |
| **Forgiving** | Typo tolerance, smart suggestions |
| **Consistent** | Same patterns across all commands |

### 6.2 Cognitive Load Reduction

**Before (high cognitive load):**

```bash
teach exam --format quarto --questions 25 --duration 90 --types mc,sa,essay \
  --difficulty mixed --output exams/midterm1.qmd "Chapters 1-5"
```

**After (minimal cognitive load):**

```bash
teach exam "Midterm 1"                    # Smart defaults
teach exam -i                             # Guided if unsure
```

### 6.3 Time Estimates

Always provide realistic time estimates:

| Command | Estimate | Display |
|---------|----------|---------|
| slides | 20-40s | "~30s" |
| lecture | 30-60s | "~45s" |
| quiz | 15-30s | "~20s" |
| exam | 30-90s | "~60s" |
| feedback | 10-30s | "~20s" |
| assignment | 20-40s | "~30s" |

### 6.4 Error Recovery

Every error should include:
1. **What went wrong** (clear, non-technical)
2. **Why it happened** (brief context)
3. **How to fix it** (specific command)
4. **Quick retry option** (if applicable)

---

## 7. Suggested Aliases

### 7.1 Command Shortcuts (in teach-dispatcher.zsh)

Already implemented:

```zsh
# In case statement
slides|sl)    _teach_scholar_wrapper "slides" "$@" ;;
lecture|lec)  _teach_scholar_wrapper "lecture" "$@" ;;
quiz|q)       _teach_scholar_wrapper "quiz" "$@" ;;
exam|e)       _teach_scholar_wrapper "exam" "$@" ;;
feedback|fb)  _teach_scholar_wrapper "feedback" "$@" ;;
assignment|hw) _teach_scholar_wrapper "assignment" "$@" ;;
```

### 7.2 Global Shell Aliases (for power users)

Add to user's `.zshrc` or document as optional:

```zsh
# Teaching workflow shortcuts
alias tsl='teach slides'           # Quick slides
alias tlec='teach lecture'         # Quick lecture
alias tq='teach quiz'              # Quick quiz
alias te='teach exam'              # Quick exam
alias tfb='teach feedback'         # Quick feedback
alias thw='teach assignment'       # Quick homework

# Interactive shortcuts
alias tsli='teach slides -i'       # Interactive slides
alias tleci='teach lecture -i'     # Interactive lecture
alias tqi='teach quiz -i'          # Interactive quiz
alias tei='teach exam -i'          # Interactive exam

# Revise shortcuts
alias trev='teach --revise'        # Start revision

# Status shortcuts
alias ts='teach status'            # Quick status
alias tw='teach week'              # Current week
```

### 7.3 fzf-Powered Aliases (if fzf available)

```zsh
# Pick and revise any generated file
alias trevp='teach --revise $(find . -name "*.qmd" -o -name "*.md" | fzf --header="Select file to revise")'

# Pick topic from schedule
alias tpick='teach slides "$(yq -r ".weeks[].topic" _schedule.yml | fzf --header="Select topic")"'
```

---

## 8. Implementation Checklist

### 8.1 Phase 1: Core UX (Current Sprint)

- [ ] Update `_teach_execute()` with improved progress display
- [ ] Add elapsed time counter to spinner
- [ ] Implement structured success messages
- [ ] Implement structured error messages
- [ ] Add `--context` flag support

### 8.2 Phase 2: Interactive Mode

- [ ] Implement `-i` flag for all generation commands
- [ ] Create `_teach_interactive_wizard()` function
- [ ] Add step-by-step prompts for each command
- [ ] Implement keyboard navigation (q, b, ?)

### 8.3 Phase 3: Revise Workflow

- [ ] Implement `--revise` flag for all commands
- [ ] Create `_teach_analyze_file()` for existing content
- [ ] Implement revision options menu
- [ ] Add diff preview functionality

### 8.4 Phase 4: Smart Defaults

- [ ] Implement `_teach_auto_detect_topic()`
- [ ] Add week calculation from semester dates
- [ ] Parse `_schedule.yml` for topic lookup
- [ ] Cache course context with staleness detection

---

## 9. Visual Reference

### 9.1 Complete Happy Path Flow

```
$ teach slides "Regression Analysis"

 Preparing slides for "Regression Analysis"...
  Context: Week 8 of 15 | STAT 440

 Generating slides (~30s)...  12s

 Finalizing content...

 Created: slides/week08-regression.qmd

   File:     slides/week08-regression.qmd
   Slides:   24 slides (6 sections)
   Format:   Quarto RevealJS

Next steps:
  Review:   teach slides --revise slides/week08-regression.qmd
  Preview:  qu preview slides/week08-regression.qmd

Commit this content?  [1] Review  [2] Commit  [3] Skip: _
```

### 9.2 Complete Error Recovery Flow

```
$ teach exam

 teach: Cannot auto-detect topic

   No topic scheduled for Week 8 in _schedule.yml

   Available weeks with topics:
     Week 6: Confidence Intervals
     Week 7: Hypothesis Testing
     Week 9: ANOVA

Recovery options:
  1. Specify topic:  teach exam "Midterm Topics"
  2. Edit schedule:  $EDITOR _schedule.yml
  3. Interactive:    teach exam -i

Your choice [1-3]: _
```

---

## 10. Appendix: Color Palette

### FLOW_COLORS Reference (from core.zsh)

| Name | ANSI Code | Hex | Usage |
|------|-----------|-----|-------|
| success | 38;5;114 | #87D787 | Completion, checkmarks |
| warning | 38;5;221 | #FFD75F | Warnings, cautions |
| error | 38;5;203 | #FF5F5F | Errors, failures |
| info | 38;5;117 | #87D7FF | Information, hints |
| header | 38;5;147 | #AFAFFF | Section headers |
| accent | 38;5;216 | #FFAF87 | Highlights |
| muted | 38;5;245 | #8A8A8A | Secondary text |
| cmd | 38;5;117 | #87D7FF | Command examples |

---

**Document History:**
- v1.0.0 (2026-01-17): Initial design specification
