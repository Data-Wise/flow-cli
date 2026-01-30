---
template_version: "1.0"
template_type: "prompt"
template_description: "Quiz question generator for STAT-101 with multiple difficulty levels"
scholar:
  command: "quiz"
  model: "claude-opus-4-5"
  temperature: 0.5
variables:
  required: [COURSE, TOPIC]
  optional: [WEEK, DIFFICULTY, MACROS, DATE]
---

# STAT-101 Quiz Question Generator

## Context

Generate quiz questions for **{{COURSE}}** on the topic of **{{TOPIC}}** (Week {{WEEK}}).

**Difficulty Level:** {{DIFFICULTY}}
**Date:** {{DATE}}

## Question Types

Create a balanced mix:
1. **Conceptual** (40%) - Test understanding of ideas
2. **Computational** (30%) - Test ability to calculate
3. **Interpretation** (20%) - Test ability to explain results
4. **Application** (10%) - Test ability to apply concepts to new scenarios

## Difficulty Guidelines

### Easy (Bloom's: Remember, Understand)
- Direct recall of definitions
- Simple calculations with clear steps
- Straightforward interpretations
- Examples: "What is the definition of...?", "Calculate the mean of..."

### Medium (Bloom's: Apply, Analyze)
- Multi-step calculations
- Comparison of concepts
- Error identification
- Examples: "Which test should you use...?", "What's wrong with this analysis...?"

### Hard (Bloom's: Evaluate, Create)
- Novel scenarios requiring synthesis
- Critical evaluation of methods
- Design of analyses
- Examples: "Design a study to...", "Critique this statistical claim..."

## Mathematical Notation

{{MACROS}}

Use consistent notation:
- Clearly distinguish sample vs population parameters
- Use $\bar{x}$ not "x-bar" in text
- Include units where appropriate

## Question Format

For each question provide:
```
**Question X:** [Question text with clear context]

a) [Option A]
b) [Option B]
c) [Option C]
d) [Option D]

**Correct Answer:** [Letter]

**Explanation:** [Brief explanation why correct answer is right and others are wrong]

**Learning Objective:** [Which objective this tests]

**Difficulty:** [Easy/Medium/Hard]
```

## Quality Standards

- All distractors should be plausible (not obviously wrong)
- Avoid "all of the above" and "none of the above"
- Questions should be independent (one doesn't give away another)
- Use realistic scenarios relevant to students' lives
- Avoid trick questions or ambiguous wording
- Include necessary context (don't assume background knowledge)

## Common Mistakes to Avoid

- Questions that test memorization of formulas (unless formula sheet is not provided)
- Overly complex calculations (this is a quiz, not an exam)
- Ambiguous wording that confuses even students who know the material
- Cultural references that not all students may understand
- Unnecessarily complicated scenarios that obscure the statistical concept

## Output Requirements

- Generate **8-10 questions** per quiz
- Balance difficulty: 50% easy, 30% medium, 20% hard
- Balance question types as specified above
- Include answer key and explanations
- Note time estimate (1-2 minutes per question)

---

**Format:** Markdown with clear structure, ready to paste into Canvas or print
