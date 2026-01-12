# Scholar Plugin Teaching Features - Deep Brainstorm

**Topic:** Scholar plugin expansion for teaching workflows
**Mode:** Feature (deep)
**Date:** 2026-01-11
**Duration:** Deep brainstorm with 8 expert questions
**Context:** Parallel development with flow-cli teaching-workflow

---

## Executive Summary

Expand the scholar plugin to support teaching workflows alongside its existing research capabilities. Add `/teaching:*` namespace with 4-6 core commands that generate educational materials (exams, quizzes, lectures, assignments) using hybrid AI + template approach.

**Key Innovation:** Scholar becomes unified academic plugin (research + teaching) with flow-cli as wrapper for teaching workflows.

---

## Deep Brainstorm Findings (8 Expert Questions)

### Question 1: Primary Purpose

**Answer:** Parallel development with flow-cli teaching-workflow

**Impact:**

- Scholar and flow-cli develop simultaneously
- Scholar provides content generation capabilities
- flow-cli provides workflow automation
- Both tools integrate via shared configuration

### Question 2: Teaching Skills Priority (Selected ALL 4)

**Answers:**

- ✅ Exam/quiz generation from topics
- ✅ Lecture outline creation
- ✅ Assignment/homework design
- ✅ Syllabus/course planning

**Impact:**

- Need 4 primary teaching commands
- Each command supports multiple output formats
- Must validate quality before saving

### Question 3: Integration Model

**Answer:** Flow-cli wrapper (scholar called by flow-cli)

**Architecture:**

```
flow-cli (ZSH)
  └── calls scholar commands
      └── scholar generates content
          └── returns to flow-cli
              └── flow-cli handles workflow
```

**Impact:**

- Scholar is standalone (works without flow-cli)
- flow-cli's `teach-exam` wraps `/teaching:exam`
- Seamless integration via subprocess calls

### Question 4: Output Formats (Selected ALL 4)

**Answers:**

- ✅ Markdown (.md) for version control
- ✅ Quarto (.qmd) for course websites
- ✅ LaTeX (.tex) for PDFs
- ✅ JSON/YAML for programmatic use

**Impact:**

- Commands must support `--format` flag
- Default format from `.flow/teach-config.yml`
- Easy conversion between formats

### Question 5: Generation Method

**Answer:** Hybrid (AI + templates)

**Approach:**

1. Load structured template (JSON/YAML schema)
2. Use AI to generate content for template fields
3. Validate output against schema
4. Format into requested output format

**Impact:**

- Consistent structure across all generated materials
- AI fills in creative content
- Templates ensure required elements present

### Question 6: Context Storage

**Answer:** Read from `.flow/teach-config.yml`

**Configuration Schema:**

```yaml
scholar:
  course_info:
    level: 'undergraduate' # or graduate
    field: 'statistics'
    difficulty: 'intermediate' # beginner/intermediate/advanced

  defaults:
    exam_format: 'markdown'
    lecture_format: 'quarto'
    question_types: ['multiple-choice', 'short-answer', 'essay']

  style:
    tone: 'formal' # or conversational
    notation: 'statistical' # LaTeX math notation style
```

**Impact:**

- Scholar reads course context from flow-cli config
- Consistent generation across all commands
- User configures once, affects all materials

### Question 7: Post-Generation Workflow (Selected 3)

**Answers:**

- ✅ Edit in text editor
- ✅ Commit to git (version control)
- ✅ Deploy to website (Quarto render)

**Impact:**

- Generated files go directly into course repo
- User can edit before committing
- Integrates with existing git workflow

### Question 8: Quality Validation

**Answer:** Critical - must validate before saving

**Validation Requirements:**

- Check format/schema compliance
- Verify answer keys present (for exams/quizzes)
- Validate LaTeX math syntax
- Ensure all required fields populated
- Warn about incomplete generation

**Impact:**

- Add `--no-validate` flag for experienced users
- Default behavior validates everything
- Clear error messages with fix suggestions

---

## Quick Wins (< 30 min each)

⚡ **Create `/teaching:exam` command skeleton**

- Benefit: Establishes pattern for other commands
- Setup template structure in `src/teaching/templates/exam.json`
- Implement basic validation logic

⚡ **Add `.flow/teach-config.yml` parsing**

- Benefit: Enables context-aware generation
- Reuse existing YAML parsing from scholar
- Add scholar-specific section to config schema

⚡ **Implement markdown output format**

- Benefit: Simplest format, immediate usability
- Template-based generation
- Compatible with examark conversion

⚡ **Create quality validation framework**

- Benefit: Ensures generated content is usable
- JSON schema validation
- Format-specific checks (LaTeX, markdown)

---

## Medium Effort (1-2 hours)

**Add AI generation integration**

- Implement template field filling with Claude API
- Handle context injection (course level, difficulty, topic)
- Retry logic for failed generations

**Support all 4 output formats**

- Markdown → Quarto → LaTeX conversions
- Format-specific templates
- JSON/YAML structured output

**Implement remaining teaching commands**

- `/teaching:quiz` (similar to exam, shorter)
- `/teaching:lecture` (outline generation)
- `/teaching:assignment` (problem sets)

**Create teaching skills (auto-activating)**

- `exam-designer` - Activates on "exam", "test", "assessment"
- `lecture-planner` - Activates on "lecture", "lesson", "class"
- `assignment-creator` - Activates on "homework", "assignment", "problem set"
- `syllabus-architect` - Activates on "syllabus", "course plan", "schedule"

---

## Long-term (Future sessions)

**Advanced features:**

- Question bank management (reusable questions)
- Difficulty calibration (IRT-based)
- Learning objective alignment
- Accessibility compliance (WCAG)

**Integration improvements:**

- Direct Canvas API upload (via flow-cli)
- LMS-agnostic export formats
- Collaborative editing workflow

**Content analysis:**

- Bloom's taxonomy classification
- Reading level assessment
- Topic coverage analysis

---

## Recommended Path

→ **Start with `/teaching:exam` command as pilot**

**Reasoning:**

1. Exams have clear structure (questions + answers)
2. Limited frequency (2-3/semester) reduces pressure
3. Establishes pattern for other commands
4. Immediate value for teaching workflow

**Implementation order:**

1. Week 1: `/teaching:exam` command (markdown output only)
2. Week 2: Add Quarto/LaTeX formats + validation
3. Week 3: `/teaching:quiz`, `/teaching:lecture` commands
4. Week 4: Teaching skills (auto-activation)
5. Week 5: `/teaching:assignment`, `/teaching:syllabus`

---

## Architecture Design

### Command Structure

```
scholar/
├── src/
│   ├── teaching/
│   │   ├── commands/
│   │   │   ├── exam.js          # /teaching:exam
│   │   │   ├── quiz.js          # /teaching:quiz
│   │   │   ├── lecture.js       # /teaching:lecture
│   │   │   ├── assignment.js    # /teaching:assignment
│   │   │   └── syllabus.js      # /teaching:syllabus
│   │   ├── templates/
│   │   │   ├── exam.json        # Exam template schema
│   │   │   ├── quiz.json
│   │   │   ├── lecture.json
│   │   │   ├── assignment.json
│   │   │   └── syllabus.json
│   │   ├── validators/
│   │   │   ├── schema.js        # JSON schema validation
│   │   │   ├── latex.js         # LaTeX syntax validation
│   │   │   └── markdown.js      # Markdown format validation
│   │   ├── generators/
│   │   │   ├── ai-generator.js  # AI content generation
│   │   │   └── template-filler.js
│   │   └── formatters/
│   │       ├── markdown.js
│   │       ├── quarto.js
│   │       ├── latex.js
│   │       └── json.js
│   └── research/               # Existing research commands
│       └── ...
├── docs/
│   └── teaching-commands.md    # NEW documentation
└── tests/
    └── teaching/               # NEW test suite
```

### Data Flow

```
User: /teaching:exam "ANOVA concepts"

1. scholar reads ~/.flow/teach-config.yml
   → Gets course context (level, difficulty, style)

2. Load exam template (exam.json)
   → Schema defines required fields

3. AI generation fills template
   → Topic: "ANOVA concepts"
   → Context: undergraduate statistics, intermediate
   → Generates: 5 MC, 2 short answer, 1 essay

4. Validation
   → Schema compliance check
   → Answer key verification
   → LaTeX syntax validation

5. Format output (default: markdown)
   → Generate exams/anova-exam.md
   → Include metadata (date, course, topic)

6. Return file path to flow-cli (or save directly)
```

---

## Integration with flow-cli

### flow-cli's `teach-exam` command wraps scholar

```bash
# In flow-cli's commands/teach-exam.zsh

teach-exam() {
  local topic="$1"

  # Load course config
  local config=".flow/teach-config.yml"
  local exam_format=$(yq -r '.scholar.defaults.exam_format // "markdown"' "$config")

  # Call scholar command
  claude skill teaching:exam "$topic" --format "$exam_format" \
    --config "$config" \
    --output "exams/"

  # Post-processing
  local exam_file=$(find exams/ -name "*.md" -mtime -1m | head -1)

  echo "✅ Exam created: $exam_file"
  echo ""
  echo "Next steps:"
  echo "  1. Edit: \$EDITOR $exam_file"
  echo "  2. Convert: ./scripts/exam-to-qti.sh $exam_file"
}
```

---

## Template Schema Example

### `src/teaching/templates/exam.json`

```json
{
  "schema_version": "1.0",
  "template_type": "exam",
  "metadata": {
    "title": "<required: string>",
    "course": "<auto: from config>",
    "date": "<auto: today>",
    "duration": "<required: number in minutes>",
    "total_points": "<required: number>",
    "instructions": "<optional: string>"
  },
  "questions": [
    {
      "id": "<auto: Q1, Q2, ...>",
      "type": "<required: multiple-choice|short-answer|essay|true-false>",
      "points": "<required: number>",
      "text": "<required: string, AI-generated>",
      "options": "<if multiple-choice: array of strings>",
      "answer": "<required: correct answer>",
      "rubric": "<if essay: grading criteria>",
      "difficulty": "<optional: easy|medium|hard>"
    }
  ],
  "answer_key": {
    "Q1": "<answer>",
    "Q2": "<answer>"
  }
}
```

---

## Validation Rules

### Schema Validation

- All required fields present
- Types match schema
- No empty strings for required fields

### Content Validation

- Answer key complete (all questions have answers)
- Point totals add up correctly
- Question IDs unique
- Duration is reasonable (30-180 minutes)

### Format-Specific Validation

**Markdown:**

- Valid markdown syntax
- LaTeX math delimiters correct (`$...$`, `$$...$$`)

**Quarto:**

- YAML frontmatter valid
- R/Python code blocks (if any) syntactically correct

**LaTeX:**

- Math mode delimiters balanced
- Commands exist (\textbf, \section, etc.)
- Document structure valid (\begin{document}, etc.)

---

## Command Interface Design

### `/teaching:exam`

```bash
# Basic usage
/teaching:exam "topic"

# With options
/teaching:exam "topic" --format latex --duration 60 --points 100

# Interactive mode
/teaching:exam
→ Prompts for topic, duration, points, question types
```

**Options:**

- `--format <md|qmd|tex|json>` - Output format
- `--duration <minutes>` - Exam duration
- `--points <number>` - Total points
- `--questions <count>` - Number of questions
- `--types <mc,sa,essay>` - Question type distribution
- `--config <path>` - Config file (default: .flow/teach-config.yml)
- `--output <dir>` - Output directory
- `--no-validate` - Skip validation

**Output:**

```
📝 Generating exam: ANOVA concepts

Context (from config):
  Course: STAT 545
  Level: Undergraduate
  Difficulty: Intermediate

Questions:
  ✓ 5 multiple-choice (5 points each)
  ✓ 2 short-answer (10 points each)
  ✓ 1 essay (25 points)

Validation:
  ✓ Schema valid
  ✓ Answer key complete
  ✓ LaTeX syntax valid

✅ Exam saved: exams/anova-exam-2026-01-11.md

Next steps:
  1. Review: cat exams/anova-exam-2026-01-11.md
  2. Edit: $EDITOR exams/anova-exam-2026-01-11.md
  3. Convert: examark exams/anova-exam-2026-01-11.md -o exam.qti.zip
```

---

## Testing Strategy

### Unit Tests (per command)

```bash
tests/teaching/test-exam-command.js

✓ Generates valid exam with default options
✓ Respects --format flag (md, qmd, tex, json)
✓ Reads context from .flow/teach-config.yml
✓ Validates schema before saving
✓ Creates answer key automatically
✓ Handles AI generation failures gracefully
✓ Warns on incomplete validation
```

### Integration Tests

```bash
tests/teaching/test-integration.js

✓ flow-cli calls /teaching:exam successfully
✓ Generated exam converts with examark
✓ Quarto format renders without errors
✓ LaTeX compiles to PDF
```

### Validation Tests

```bash
tests/teaching/test-validation.js

✓ Rejects exam without answer key
✓ Catches unbalanced LaTeX delimiters
✓ Warns about missing required fields
✓ Validates point totals match
```

---

## Success Metrics

| Metric              | Target       | Measurement                            |
| ------------------- | ------------ | -------------------------------------- |
| Generation time     | < 30 seconds | Time to generate 10-question exam      |
| Validation accuracy | 100%         | Catch all format errors                |
| Quality score       | > 8/10       | User rating of generated content       |
| Edit time           | < 10 min     | Time from generation to finalized exam |
| Integration success | 100%         | flow-cli → scholar → examark pipeline  |

---

## Dependencies

### Required

- Node.js >= 18.0.0 (scholar requirement)
- Claude API access (for AI generation)
- YAML parser (for config reading)

### Optional

- examark (for Canvas QTI conversion)
- quarto (for .qmd rendering)
- LaTeX distribution (for PDF generation)

---

## Open Questions

1. **AI Provider:** Use Claude API directly or abstract for multi-provider support?
   - Recommendation: Claude only initially, abstract later

2. **Question Bank:** Store generated questions for reuse?
   - Recommendation: Phase 2 feature, start with one-off generation

3. **Collaboration:** Multi-instructor question approval workflow?
   - Recommendation: Out of scope for v1.0

4. **Licensing:** How to handle copyrighted exam content?
   - Recommendation: User responsibility, add disclaimer

---

## Implementation Timeline

### Week 1: Core Exam Command (6-8 hours)

- [ ] Create teaching command structure
- [ ] Implement exam template schema
- [ ] Add basic validation framework
- [ ] Markdown format output
- [ ] Unit tests

### Week 2: Formats & Validation (6-8 hours)

- [ ] Add Quarto format support
- [ ] Add LaTeX format support
- [ ] Add JSON format support
- [ ] Comprehensive validation rules
- [ ] Integration with .flow/teach-config.yml

### Week 3: Additional Commands (8-10 hours)

- [ ] `/teaching:quiz` command
- [ ] `/teaching:lecture` command
- [ ] Shared utilities refactoring
- [ ] Documentation

### Week 4: Teaching Skills (4-6 hours)

- [ ] Auto-activating teaching skills
- [ ] Skill coordination logic
- [ ] Examples and documentation

### Week 5: Polish & Integration (4-6 hours)

- [ ] `/teaching:assignment` command
- [ ] `/teaching:syllabus` command
- [ ] flow-cli wrapper scripts
- [ ] E2E testing with flow-cli

**Total Effort:** 28-38 hours over 5 weeks

---

## Next Steps

1. **Create spec from this brainstorm** (automatic via save flag)
2. **Set up teaching command structure** in scholar repo
3. **Implement `/teaching:exam` as pilot**
4. **Test integration with flow-cli**
5. **Iterate based on real exam generation**

---

**Brainstorm Complete:** 2026-01-11
**Mode:** Feature (deep brainstorm)
**Questions:** 8 expert-level questions
**Ready for:** Spec capture → Implementation
