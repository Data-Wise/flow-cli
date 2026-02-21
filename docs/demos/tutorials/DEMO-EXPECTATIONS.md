# Scholar Enhancement Demo - Expected Outputs

**Purpose:** This guide explains what you should see when running each demo command.

---

## Demo 1: Help System

### Command

```bash
teach slides --help
teach quiz --help
teach lecture --help
```

### What You'll See

**For each `--help` command:**

1. **Command Description**
   - Usage pattern with topic and options
   - Brief explanation of what the command generates

2. **Universal Flags (v5.13.0+)**
   - Topic selection: `--topic`, `--week`
   - Content style presets: conceptual, computational, rigorous, applied
   - Content customization: ~12 flags (explanation, definitions, proof, math, examples, code, etc.)
   - Workflow modes: interactive, revise, context

3. **Command-Specific Options**
   - For slides: theme, format, from-lecture
   - For quiz: number of questions, duration, difficulty
   - For lecture: outline-only, detailed, format

4. **Examples Section**
   - Quick start example
   - Style preset usage
   - Advanced customization

**Expected Behavior:**
- Each help screen is ~40-60 lines
- Color-coded sections (headers in blue/purple)
- Organized into logical groups
- Examples at the end

---

## Demo 2: Basic Generation

### Command

```bash
teach slides "Introduction to Statistics" --style conceptual
```

### What You'll See

1. **Header**

   ```text

   🎓 Scholar Enhancement - Generating Slides
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ```

2. **Configuration Display**
   - Topic: Introduction to Statistics
   - Style: conceptual (explanation + definitions + examples)

3. **Content Structure Progress**

   ```text

   📝 Content Structure:
      ✓ Title slide
      ✓ Learning objectives
      ✓ Key definitions
      ✓ Conceptual explanations
      ✓ Practical examples
      ✓ Summary & takeaways

   ```

4. **Content Preview**

   ```text

   📊 Included Sections:
      • What is statistics?
      • Descriptive vs. inferential statistics
      • Population vs. sample
      • Variables and data types
      • Real-world applications

   ```

5. **Output Summary**

   ```text

   ✅ Generated: slides/intro-statistics.qmd (1,247 words)

      Duration: ~45 minutes
      Slides:   15-20
      Format:   Quarto reveal.js

   ```

**Expected Behavior:**
- Generation takes 5-15 seconds (real Scholar invocation)
- Output file created in course directory
- Word count and metadata displayed
- Estimated presentation duration calculated

**Style Preset Effects (conceptual):**
- Heavy on explanations and definitions
- Multiple examples included
- Minimal mathematical notation
- Focuses on understanding over computation

---

## Demo 3: Style Customization

### Command

```bash
teach quiz "Hypothesis Testing" --style rigorous --technical-depth high
```

### What You'll See

1. **Header with Customization**

   ```text

   🎓 Scholar Enhancement - Generating Quiz

   Topic:            Hypothesis Testing
   Style Preset:     rigorous (definitions + explanation + math + proof)
   Technical Depth:  high

   ```

2. **Style Customization Applied**

   ```text

   📝 Style Customization Applied:
      ✓ Formal mathematical definitions
      ✓ Statistical theory explanations
      ✓ Proof-based questions
      ✓ Advanced technical notation
      ✓ Rigorous problem solving

   ```

3. **Question Distribution**

   ```text

   🎯 Question Types:
      • Theoretical foundations (40%)
      • Mathematical proofs (25%)
      • Statistical derivations (20%)
      • Applied problem solving (15%)

   ```

4. **Content Characteristics**

   ```text

   📊 Content Characteristics:
      • Graduate-level rigor
      • Heavy mathematical notation
      • Proof verification questions
      • Multi-step derivations

   ```

5. **Output Summary**

   ```text

   ✅ Generated: quizzes/hypothesis-testing.qmd (15 questions)

      Difficulty:  Advanced/Graduate
      Duration:    60 minutes
      Topics:      Null hypothesis, Type I/II errors, p-values, power
      Format:      Mix of theoretical and computational

   ```

**Expected Behavior:**
- Combining style preset + flags modifies output
- `--style rigorous` emphasizes proofs and formal definitions
- `--technical-depth high` increases difficulty level
- Question types reflect customization (more theory/proofs)

**Customization Effects:**
- Rigorous style → More math notation, formal definitions
- High technical depth → Graduate-level content
- Combined → Very advanced, proof-heavy questions

---

## Demo 4: YAML-Driven Lesson Plans

### Command

```bash
teach lecture --lesson content/lesson-plans/week03.yml
```

### What You'll See

1. **Lesson Plan Loading**

   ```text

   🎓 Scholar Enhancement - YAML-Driven Content Generation

   📋 Loading Lesson Plan: content/lesson-plans/week03.yml

   Week:      3
   Topic:     Introduction to Linear Regression
   Duration:  75 minutes
   Level:     Undergraduate

   ```

2. **Lesson Plan Structure**

   ```text

   📚 Lesson Plan Structure:
      ✓ 4 learning objectives (understand → apply → analyze)
      ✓ 4 main topics with 12 subtopics
      ✓ 5 structured activities (lecture → code demo → discussion)
      ✓ Reading materials and datasets specified
      ✓ Teaching style overrides applied

   ```

3. **Content Generation Based on Plan**

   ```text

   🎯 Content Generation Based on Plan:
      • Using OLS derivation activity (20 min, step-by-step)
      • Including R implementation demo (mtcars dataset)
      • Incorporating board work for theory section
      • Adding think-pair-share for practice

   ```

4. **Generated Lecture Outline**

   ```text

   📝 Generating Lecture Outline:
      ✓ Opening: Review correlation, introduce regression (5 min)
      ✓ Theory: Model formulation, OLS derivation (25 min)
      ✓ Application: R demo with visualization (25 min)
      ✓ Practice: Coefficient interpretation (15 min)
      ✓ Closing: Summary & homework preview (5 min)

   ```

5. **Output Summary**

   ```text

   ✅ Generated: lectures/week03-linear-regression.qmd (2,847 words)

      Sections:     5 (matches lecture structure)
      Code blocks:  8 (R examples with ggplot2)
      Derivations:  2 (OLS with intuition-first approach)
      Activities:   5 (fully specified with timing)
      Format:       Quarto with reveal.js support

   ```

**Expected Behavior:**
- Scholar reads YAML file structure
- Generates content following lesson plan exactly
- Respects timing, activities, and teaching methods
- Includes specified datasets and materials
- Applies teaching style overrides from YAML

**YAML Lesson Plan Benefits:**
- Structured, reusable lesson plans
- Consistent timing across weeks
- Clear learning objectives
- Specified activities and materials
- Teaching method preferences encoded

**Example YAML Structure:**

```yaml
week: 3
title: "Introduction to Linear Regression"
duration_minutes: 75

learning_objectives:
  - description: "Explain simple linear regression"
    level: understand

topics:
  - name: "OLS Estimation"
    subtopics:
      - "Minimizing sum of squared residuals"

activities:
  - id: act1
    type: lecture
    duration_minutes: 15

teaching_style_overrides:
  explanation_style:
    proof_style: intuition-first
```

---

## Using the Demo Course

### Location

```bash
cd ~/projects/teaching/scholar-demo-course
```

### Structure

```text
scholar-demo-course/
├── .flow/
│   └── teach-config.yml          # Course configuration
├── content/
│   └── lesson-plans/
│       └── week03.yml             # Linear regression lesson
├── lectures/                      # Generated lectures appear here
├── quizzes/                       # Generated quizzes appear here
└── slides/                        # Generated slides appear here
```

### Running Commands in Demo Course

```bash
# Navigate to course
cd ~/projects/teaching/scholar-demo-course

# Ensure flow-cli is loaded
source /Users/dt/.git-worktrees/flow-cli/feature/teaching-flags/flow.plugin.zsh

# Run any teach command
teach slides "Data Visualization" --style computational
teach lecture --lesson content/lesson-plans/week03.yml
teach quiz "Probability" --style conceptual --questions 10
```

### Course Configuration

The `teach-config.yml` provides:
- Course metadata (STAT 101, Spring 2026)
- Semester dates and weeks
- Scholar defaults (style, format, tone)
- Grading breakdown
- Topics list

When you run `teach` commands in this directory, Scholar uses this configuration automatically.

---

## Common Patterns Across All Demos

### 1. Header Format

All demos show:

```text
🎓 Scholar Enhancement - [Action]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 2. Progress Indicators

Checkmarks for completed steps:

```text
✓ Task completed
• Bullet point
```

### 3. Emoji Categories

- 🎓 Scholar Enhancement
- 📝 Content/Structure
- 📊 Data/Sections
- 🎯 Targets/Goals
- ✅ Success/Completion

### 4. Color Coding

- Headers: Bold
- Section names: Blue/Purple
- Values: Default
- Success: Green checkmarks

### 5. Output Summary Format

```text
✅ Generated: path/to/file.qmd (word count)

   Metric 1:  Value
   Metric 2:  Value
   Format:    Type
```

---

## Troubleshooting

### Command Not Found: teach

**Problem:** `teach: command not found`

**Solution:**

```bash
# Load flow-cli first
cd /Users/dt/.git-worktrees/flow-cli/feature/teaching-flags
source flow.plugin.zsh
```

### Not a Teaching Project

**Problem:** "Not in a teaching project directory"

**Solution:**

```bash
# Navigate to teaching course first
cd ~/projects/teaching/scholar-demo-course

# Or run teach init in a directory
teach init "Course Name"
```

### Scholar Not Available

**Problem:** "Scholar commands require Claude Code CLI"

**Solution:**
The demos use simulated output, but real commands require:
1. Claude Code CLI installed
2. Scholar plugin loaded
3. Teaching project configured

---

## Next Demos (Coming Soon)

### Demo 5: Interactive Mode

- Shows wizard-style question prompts
- User answers guide content generation
- Step-by-step workflow

### Demo 6: Revision Workflow

- Takes existing content file
- Applies feedback/improvements
- Shows before/after

### Demo 7: Week-Based Generation

- Uses `--week 5` flag
- Auto-detects topic from config
- Generates for specific week

### Demo 8: Context Integration

- Includes course materials
- References readings and datasets
- Shows context-aware generation

---

**Status:** Demos 1-4 complete (4/8)
**Last Updated:** 2026-01-17
