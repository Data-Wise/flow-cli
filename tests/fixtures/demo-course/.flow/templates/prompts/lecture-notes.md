---
template_version: "1.0"
template_type: "prompt"
template_description: "Custom lecture notes for STAT-101 (course override)"
scholar:
  command: "lecture"
  model: "claude-opus-4-5"
  temperature: 0.3
variables:
  required: [COURSE, TOPIC]
  optional: [WEEK, STYLE, MACROS, INSTRUCTOR, SEMESTER, DATE]
---

# STAT-101 Lecture Notes Generator

## Course Context

You are creating lecture notes for **{{COURSE}}**, a first course in statistics for undergraduate students with minimal math background. The course emphasizes intuition and practical application over mathematical rigor.

**Instructor:** {{INSTRUCTOR}}
**Semester:** {{SEMESTER}}
**Week:** {{WEEK}}
**Topic:** {{TOPIC}}
**Style:** {{STYLE}}

## Learning Objectives

Create lecture notes that:
- Build intuition through concrete examples from everyday life
- Use visual representations (plots, diagrams) to explain concepts
- Include R code examples for computational demonstrations
- Connect statistical concepts to real-world applications
- Anticipate common student misconceptions

## Structure

### Introduction (10%)
- Hook: Start with a compelling real-world question or scenario
- Learning objectives for this lecture
- Connection to previous topics

### Main Content (70%)
- Break content into 3-4 major sections
- Each section should have:
  - Clear explanation of the concept
  - Visual representation (describe plot/diagram)
  - Worked example with detailed steps
  - R code demonstration (with comments)
  - Common pitfalls and how to avoid them

### Summary (10%)
- Key takeaways (3-5 bullet points)
- Preview of next topic
- Practice problems (2-3 with varying difficulty)

### Additional Resources (10%)
- Recommended textbook sections
- Online resources (videos, interactive demos)
- Office hours topics for struggling students

## Mathematical Notation

{{MACROS}}

Use clear notation:
- $\bar{x}$ for sample mean
- $\mu$ for population mean
- $s$ for sample standard deviation
- $\sigma$ for population standard deviation
- Use \E{X} for expected value (from macros)
- Use \Var{X} for variance (from macros)

## R Code Standards

- Use tidyverse style guide
- Include library() calls at top
- Add comments explaining each step
- Show output for all examples
- Use realistic datasets (built-in R datasets preferred)

## Tone and Style

- Conversational but professional
- Encourage questions and exploration
- Acknowledge that statistics can be confusing
- Use analogies to explain abstract concepts
- Avoid intimidating jargon (define terms when first used)

## Common Student Questions

Anticipate and address:
- "When would I use this in real life?"
- "How is this different from [related concept]?"
- "What if my data doesn't look like the example?"
- "Do I need to memorize this formula?"

---

**Output Format:** Quarto markdown (.qmd) with YAML frontmatter including title, date, and format specifications.
