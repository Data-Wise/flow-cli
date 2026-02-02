# Scholar Flags Quick Reference

> All flags available for `teach` Scholar wrapper commands (lecture, slides, exam, quiz, assignment, syllabus, rubric, feedback, demo).
>
> **Version:** v6.1.0+ | **Source:** `lib/dispatchers/teach-dispatcher.zsh`

## Selection Flags (Universal)

Available to all Scholar wrapper commands for topic/week selection.

| Flag | Short | Values | Default | Description |
|------|-------|--------|---------|-------------|
| `--topic` | `-t` | String | — | Explicit topic (bypasses lesson plan) |
| `--week` | `-w` | Number | — | Week number (uses lesson plan if exists) |
| `--style` | — | Preset | — | Content style preset (see below) |
| `--interactive` | `-i` | — | — | Interactive wizard (step-by-step prompts) |
| `--context` | — | — | Auto-detect | Include course context from materials |
| `--revise` | — | File path | — | Revision workflow (improve existing file) |

**Notes:**
- When both `--topic` and `--week` are specified, `--topic` takes precedence
- `--context` is automatically enabled if `.flow/lesson-plans.yml` exists
- `--revise` triggers a specialized revision workflow with AI-generated improvements

---

## Content Toggle Flags (Universal)

Available to all Scholar commands for fine-grained content control. These override style preset defaults.

| Flag | Short | Negation | Default | Description |
|------|-------|----------|---------|-------------|
| `--explanation` | `-e` | `--no-explanation` | Varies by style | Include conceptual explanations |
| `--definitions` | — | `--no-definitions` | Varies by style | Include formal definitions |
| `--proof` | — | `--no-proof` | Varies by style | Include mathematical proofs |
| `--math` | `-m` | `--no-math` | Varies by style | Include mathematical notation |
| `--examples` | `-x` | `--no-examples` | Varies by style | Include numerical examples |
| `--code` | `-c` | `--no-code` | Varies by style | Include code snippets |
| `--diagrams` | `-d` | `--no-diagrams` | Varies by style | Include diagrams/visualizations |
| `--practice-problems` | `-p` | `--no-practice-problems` | Varies by style | Include practice problems |
| `--references` | `-r` | `--no-references` | Varies by style | Include citations/references |

**Conflict Detection:**
- Using both `--flag` and `--no-flag` for the same content type triggers an error
- Example error: `"Conflicting flags: --math and --no-math"`

**Resolution Order:**
1. Start with style preset defaults (if `--style` specified)
2. Apply explicit flag overrides (`--math`, `--no-code`, etc.)
3. Result is stored in `TEACH_CONTENT_RESOLVED`

---

## Style Presets

Predefined combinations of content flags for common teaching scenarios.

| Style | Included Content | Description | Best For |
|-------|------------------|-------------|----------|
| `conceptual` | explanation, definitions, examples | Theory and understanding | Intro lectures, foundations, conceptual overviews |
| `computational` | explanation, examples, code, practice-problems | Methods and calculations | Labs, applied work, hands-on sessions |
| `rigorous` | definitions, explanation, math, proof | Proofs and formal treatment | Advanced theory, graduate courses, proofs |
| `applied` | explanation, examples, code, practice-problems | Real-world applications | Case studies, projects, practical work |

**Usage:**
```bash
# Use preset as-is
teach lecture "ANOVA" --style computational

# Use preset + override specific flags
teach lecture "ANOVA" --style computational --no-practice-problems --diagrams
```

**Overriding Examples:**
```bash
# Conceptual lecture with proofs (not in preset)
teach lecture "Probability" --style conceptual --proof

# Computational lecture without code (remove from preset)
teach lecture "Regression" --style computational --no-code

# Rigorous lecture with code (add to preset)
teach lecture "Measure Theory" --style rigorous --code
```

---

## Command-Specific Flags

### teach lecture

Generate lecture notes in Quarto (.qmd) format.

| Flag | Values | Default | Description |
|------|--------|---------|-------------|
| `--template` | markdown, quarto, typst, pdf, docx | quarto | Output format template |
| `--difficulty` | easy, medium, hard | medium | Content depth/complexity |
| `--examples` | Number | 3 | Number of worked examples |
| `--math-notation` | LaTeX, unicode, text | LaTeX | Math display style |
| `--length` | Number (pages) | 20-40 | Target page count |

**Example:**
```bash
teach lecture "Neural Networks" --week 10 --template quarto \
  --difficulty hard --examples 5 --math --code
```

---

### teach slides

Create presentation slides from topics or existing lecture files.

| Flag | Values | Default | Description |
|------|--------|---------|-------------|
| `--template` | markdown, quarto | quarto | Output format template |
| `--theme` | default, academic, minimal | default | Slide theme |
| `--from-lecture` | File path | — | Convert lecture .qmd to slides |
| `--optimize` | — | — | AI-powered slide structure analysis |
| `--preview-breaks` | — | — | Show suggested breaks before generating |
| `--apply-suggestions` | — | — | Auto-apply slide break suggestions |
| `--key-concepts` | — | — | Emphasize key concepts with callouts |

**Optimization Flags (v5.15.0+):**

When `--optimize` is specified, AI analyzes lecture structure and suggests optimal slide breaks.

- `--preview-breaks`: Display suggested slide breaks and exit (no file generation)
- `--apply-suggestions`: Auto-apply AI suggestions to slide structure
- `--key-concepts`: Add callout boxes for key concepts

**Hierarchy:**
- `--preview-breaks`, `--apply-suggestions`, and `--key-concepts` all imply `--optimize`
- Use `--optimize` alone for interactive selection
- Use `--apply-suggestions` for automatic application

**Example:**
```bash
# Convert lecture with optimization
teach slides --from-lecture week-05.qmd --optimize

# Preview breaks without generating
teach slides --week 5 --optimize --preview-breaks

# Auto-apply + emphasize key concepts
teach slides --week 5 --optimize --apply-suggestions --key-concepts
```

---

### teach exam

Generate comprehensive exams with multiple question types.

| Flag | Values | Default | Description |
|------|--------|---------|-------------|
| `--questions` | Number | 5 | Total number of questions |
| `--duration` | Number (minutes) | 120 | Exam duration in minutes |
| `--types` | Type breakdown | Balanced | Question type distribution |
| `--format` | quarto, qti, markdown | quarto | Output format |
| `--difficulty` | easy, medium, hard | medium | Question difficulty level |

**Types Format:**
```
"mc:3,sa:2,problem:3"  # 3 multiple choice, 2 short answer, 3 problems
"short answer:5,problem:3"  # 5 short answer, 3 problems
```

**Examples:**
```bash
# Basic exam
teach exam "Hypothesis Testing" --questions 10

# Detailed exam with types
teach exam "ANOVA" --questions 8 --duration 60 --types "short answer:5,problem:3"

# QTI format for LMS import
teach exam "Final Exam" --questions 30 --format qti
```

**LaTeX Macro Integration:**

When `teach macros` is configured, exams automatically inject consistent notation:
```bash
teach macros sync  # Ensure macros are up-to-date
teach exam "Linear Regression" --math  # Auto-uses \E{Y}, \Var{Y}, etc.
```

---

### teach quiz

Create quiz questions for formative assessment.

| Flag | Values | Default | Description |
|------|--------|---------|-------------|
| `--questions` | Number | 10 | Number of quiz questions |
| `--time-limit` | Number (minutes) | 30 | Quiz time limit |
| `--format` | quarto, qti, markdown | quarto | Output format |
| `--difficulty` | easy, medium, hard | medium | Question difficulty |

**Examples:**
```bash
# Short quiz
teach quiz "Correlation" --questions 5

# Timed QTI quiz
teach quiz "ANOVA" --time-limit 20 --format qti
```

---

### teach assignment

Generate homework assignments with problems and grading rubrics.

| Flag | Values | Default | Description |
|------|--------|---------|-------------|
| `--due-date` | YYYY-MM-DD | — | Assignment due date |
| `--points` | Number | 100 | Total point value |
| `--format` | quarto, markdown | quarto | Output format |

**Examples:**
```bash
# Basic assignment
teach assignment "Data Wrangling" --code --practice-problems --points 50

# With due date
teach assignment "ML Intro" --due-date "2026-02-20" --points 50 --explanation
```

---

### teach syllabus

Generate course syllabus with schedule and policies.

| Flag | Values | Default | Description |
|------|--------|---------|-------------|
| `--format` | quarto, markdown, pdf | quarto | Output format |

**Example:**
```bash
teach syllabus --format pdf
```

---

### teach rubric

Create grading rubrics for assignments/projects.

| Flag | Values | Default | Description |
|------|--------|---------|-------------|
| `--criteria` | Number | 5 | Number of grading criteria |
| `--format` | quarto, markdown | quarto | Output format |

**Example:**
```bash
teach rubric "Research Paper" --criteria 6 --explanation
```

---

### teach feedback

Generate personalized student feedback on assignments.

| Flag | Values | Default | Description |
|------|--------|---------|-------------|
| `--format` | markdown, text | markdown | Output format |

**Example:**
```bash
teach feedback "Assignment 3 - Student Name" --format text
```

---

### teach demo

Create demonstration materials for lectures.

| Flag | Values | Default | Description |
|------|--------|---------|-------------|
| `--format` | quarto, markdown | quarto | Output format |

---

## Output Control Flags (Universal)

Control execution behavior and verbosity.

| Flag | Short | Description |
|------|-------|-------------|
| `--dry-run` | — | Preview Scholar command without execution |
| `--verbose` | `-v` | Show detailed execution information |
| `--template` | — | Template selection (command-specific values) |
| `--output` | — | Custom output file path |

**Examples:**
```bash
# Preview command
teach lecture "ANOVA" --week 8 --dry-run

# Verbose execution
teach exam "Final Exam" --questions 30 --verbose

# Custom output
teach slides "Regression" --output custom-slides.qmd
```

---

## Quick Examples with STAT-101 Demo Course

### Conceptual Lecture
```bash
# Theory-focused intro lecture
teach lecture "Introduction to Statistics" --week 1 --style conceptual
```

### Computational Lab
```bash
# Code-heavy data visualization lab
teach lecture "Data Visualization" --week 2 --style computational --code
```

### Rigorous Math Lecture
```bash
# Proof-based probability lecture
teach lecture "Probability Foundations" --week 3 --style rigorous --proof --math
```

### Slides from Lecture
```bash
# Convert lecture to optimized slides
teach slides --from-lecture lectures/week-05-regression.qmd --optimize --apply-suggestions
```

### Math-Heavy Exam
```bash
# Rigorous exam with consistent notation
teach exam "Linear Regression" --questions 12 --math --style rigorous
```

### Quick Quiz
```bash
# 5-question formative quiz
teach quiz "Correlation" --questions 5 --time-limit 15
```

### Hands-On Assignment
```bash
# Computational assignment with code
teach assignment "Data Wrangling" --week 4 --code --practice-problems --points 50
```

---

## Flag Combinations

Recommended flag combinations for common teaching scenarios.

### Intro Course (Conceptual Focus)
```bash
# Week 1: Conceptual foundation
teach lecture "Statistical Thinking" --week 1 --style conceptual --examples

# Week 2: Add some rigor
teach lecture "Probability Basics" --week 2 --style conceptual --math --definitions
```

### Computational Course (R/Python)
```bash
# Lab session with code
teach lecture "Data Manipulation" --week 3 --style computational --code --practice-problems

# No practice problems (lecture only)
teach lecture "Advanced Plotting" --week 4 --style computational --no-practice-problems
```

### Theory Course (Math-Heavy)
```bash
# Rigorous proof-based lecture
teach lecture "Measure Theory" --week 5 --style rigorous --proof --math --no-examples

# Rigorous with computational examples
teach lecture "Asymptotic Theory" --week 6 --style rigorous --code --examples
```

### Applied Course (Real-World)
```bash
# Case study with applications
teach lecture "A/B Testing" --week 7 --style applied --code --diagrams

# No code (conceptual case study)
teach lecture "Experimental Design" --week 8 --style applied --no-code --examples
```

### Exam Preparation
```bash
# Conceptual review exam (definitions + explanations)
teach exam "Midterm Review" --questions 10 --explanation --definitions --duration 90

# Computational exam (code + calculations)
teach exam "R Programming Exam" --questions 8 --code --examples --duration 60

# Rigorous exam (proofs + math)
teach exam "Probability Theory" --questions 6 --math --proof --duration 120 --style rigorous
```

### Slide Optimization Workflows
```bash
# Preview suggested breaks
teach slides --from-lecture week-09.qmd --preview-breaks

# Review and apply manually
teach slides --from-lecture week-09.qmd --optimize

# Auto-apply all suggestions
teach slides --from-lecture week-09.qmd --apply-suggestions --key-concepts
```

---

## Interactive Mode Workflow

When `--interactive` is specified, the wrapper launches a step-by-step wizard:

```bash
teach lecture --interactive
```

**Wizard Steps:**
1. **Week Selection** - Choose from lesson plan weeks (or enter manually)
2. **Topic Confirmation** - Confirm or override lesson plan topic
3. **Style Selection** - Choose from 4 presets
4. **Content Customization** - Toggle individual content flags
5. **Review & Generate** - Preview selections before generation

**Benefits:**
- No need to memorize flags
- Visual confirmation of selections
- Guided workflow for beginners
- Still supports flag overrides

**Example Session:**
```
$ teach lecture --interactive

📚 Interactive Lecture Generation

Select week (1-16):
> 5

Topic from lesson plan: "Linear Regression"
Use this topic? [Y/n]
> y

Select style:
  1) conceptual      - Theory and understanding
  2) computational   - Methods and calculations
  3) rigorous        - Proofs and formal treatment
  4) applied         - Real-world applications
> 2

Content options (computational preset):
  ✓ explanation
  ✓ examples
  ✓ code
  ✓ practice-problems
  ☐ math
  ☐ proof

Add math notation? [y/N]
> y

Final selections:
  Week: 5
  Topic: Linear Regression
  Style: computational
  Content: explanation examples code practice-problems math

Generate lecture? [Y/n]
> y

🎓 Generating lecture for "Linear Regression" (Week 5)...
```

---

## Flag Validation & Error Messages

### Conflict Detection

Using both a flag and its negation triggers an error:

```bash
$ teach lecture "ANOVA" --math --no-math
❌ Conflicting flags: --math and --no-math
```

### Invalid Style

Unknown style preset:

```bash
$ teach lecture "ANOVA" --style advanced
❌ Unknown style preset: advanced
Valid styles: conceptual, computational, rigorous, applied
```

### Missing Required Arguments

Week without topic (and no lesson plan):

```bash
$ teach lecture --week 99
❌ Week 99 not found in lesson plans
Hint: Run 'teach plan create 99 --topic "Your Topic"' first
```

---

## Advanced Usage: Template & Prompt Integration

### Custom Templates (v6.1.0+)

Override default template with `--template`:

```bash
# Use custom template from .flow/templates/content/
teach lecture "ANOVA" --template detailed --week 8
```

**Template Resolution:**
1. `.flow/templates/content/<type>/<name>.qmd` (project-local)
2. `~/.flow/templates/content/<type>/<name>.qmd` (user global)
3. Plugin default templates

### Custom Prompts (v6.1.0+)

Auto-inject course-specific prompts:

```bash
# Prompts auto-resolved by 3-tier system
teach lecture "Regression" --week 5

# Resolution order:
# 1. .flow/prompts/lecture.md (course-specific)
# 2. ~/.flow/prompts/lecture.md (user default)
# 3. Plugin default prompt
```

**Prompt Variables:**
- `{{TOPIC}}` - Current topic
- `{{WEEK}}` - Week number
- `{{STYLE}}` - Selected style preset
- `{{COURSE}}` - Course name from config

---

## Integration with Other Commands

### Lesson Plans

When `--week` is specified, Scholar wrappers automatically load from `.flow/lesson-plans.yml`:

```bash
# Plan defines: topic="ANOVA", style="computational"
teach plan create 8 --topic "ANOVA" --style computational

# Auto-uses plan data (no need to specify topic/style)
teach lecture --week 8
```

**Data Pulled from Plans:**
- `topic` - Week topic
- `style` - Content style preset
- `objectives` - Learning objectives (injected as context)
- `subtopics` - Subtopic list (injected as context)
- `key_concepts` - Key concepts (injected as context)

### LaTeX Macros

When `teach macros` is configured, AI content uses consistent notation:

```bash
# Sync macros from source files
teach macros sync

# Generate exam (auto-injects _macros.qmd)
teach exam "Linear Models" --math --week 5
```

**Ensures:**
- `\E{Y}` instead of `E[Y]` or `\mathbb{E}[Y]`
- `\Var{X}` instead of `Var(X)` or `V[X]`
- Consistent notation across all generated content

### Templates

Project-local templates override plugin defaults:

```bash
# Initialize with templates
teach init --with-templates

# Use project template
teach templates new lecture week-05  # Creates from template

# Generate uses same template style
teach lecture --week 5  # Matches template format
```

### Prompts

Course-specific prompts customize AI behavior:

```bash
# List prompts (shows resolution)
teach prompt list

# Edit course-specific lecture prompt
teach prompt edit lecture

# Export for Scholar integration (automatic)
teach prompt export
```

---

## Performance & Optimization

### Caching

Scholar wrappers cache:
- Lesson plan data (5-minute TTL)
- Config validation results (session-scoped)
- Macro extraction (until file modification)

**Benefits:**
- Sub-100ms for cached operations
- Reduced disk I/O
- Faster repeated commands

### Preflight Checks

All commands run preflight validation before Scholar invocation:

1. ✓ Config file exists and is valid
2. ✓ Scholar plugin available
3. ✓ Week exists in lesson plans (if `--week` specified)
4. ✓ No flag conflicts
5. ✓ Output directory writable

**Fail Fast:**
```bash
$ teach lecture --week 99
❌ Week 99 not found in lesson plans
   (exits immediately, no API call)
```

---

## Troubleshooting

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `Scholar plugin not found` | Scholar not installed | Install Scholar: `brew install scholar` |
| `teach-config.yml not found` | No config file | Run `teach init` to create config |
| `Week N not found in lesson plans` | Lesson plan missing | Run `teach plan create N` |
| `Conflicting flags: --X and --no-X` | Both flag and negation | Remove one of the flags |
| `Unknown style preset` | Invalid style name | Use: conceptual, computational, rigorous, applied |

### Debugging

Enable verbose mode for detailed execution info:

```bash
teach lecture "ANOVA" --verbose
```

**Output includes:**
- Resolved flags and style
- Lesson plan data (if loaded)
- Scholar command being executed
- API call details
- File generation status

### Dry Run

Preview Scholar command without execution:

```bash
teach lecture "ANOVA" --week 8 --dry-run
```

**Shows:**
- Final Scholar command
- Resolved content flags
- Template and prompt paths
- No API call made

---

## See Also

- [Scholar Wrappers Guide](../guides/SCHOLAR-WRAPPERS-GUIDE.md) — Complete wrapper documentation
- [Lesson Plan Quick Reference](REFCARD-TEACH-PLAN.md) — Lesson plan CRUD commands
- [Template Management](REFCARD-TEMPLATES.md) — Template system reference
- [Prompt Management](REFCARD-PROMPTS.md) — AI prompt customization
- [LaTeX Macros](../tutorials/26-latex-macros.md) — Consistent notation system
- [Master Dispatcher Guide](MASTER-DISPATCHER-GUIDE.md) — All teach commands

---

**Version:** v6.1.0
**Last Updated:** 2026-02-02
**Status:** Complete Scholar flag documentation
