---
template_version: "1.0"
template_type: "prompt"
template_description: "AI prompt for generating RevealJS slides"
---

# RevealJS Presentation Generator

## Purpose

Generate engaging RevealJS Quarto presentations (25+ slides) for statistics courses.

## Format Requirements

### YAML Frontmatter

```yaml
---
title: 'Topic Title'
subtitle: 'Course Name'
format:
  revealjs:
    theme: [default, custom.scss]
    transition: fade
    slide-number: true
    chalkboard: true
execute:
  echo: true
  warning: false
---
```

### Slide Structure

- Use `#` for section dividers
- Use `##` for content slides
- NO horizontal rules (`---`)
- Use `{.smaller}` or `{.scrollable}` for overflow

## Content Organization

### 1. Title Section

```markdown
# Topic Name {background-color="#003366"}

## Learning Objectives

1. [Bloom's verb] + [outcome]
2. [Bloom's verb] + [outcome]
```

### 2. Content Sections

Each major concept:

1. **Concept Introduction** (1 slide)
2. **Theory** (1-2 slides) - key equations
3. **Example** (2-3 slides) - step-by-step
4. **Practice/Quiz** (1 slide)

### 3. Code Display

**Incremental Reveal:**

````markdown
```{r}
#| label: fig-example
#| code-line-numbers: "|1-2|3-4|5"
code here
```
````

````

### 4. Tables

For large tables:

```markdown
## ANOVA Summary {.scrollable}
````

### 5. Interactive Elements

**Quiz Format:**

```markdown
## Question? {.quiz-question}

- [$Correct$]{.correct}
- [$Wrong$]{data-explanation="Why wrong"}
```

**Discussion:**

```markdown
## Think-Pair-Share {background-color="#f0f0f0"}

::: {.callout-question}
**Discussion (2 minutes):** What would happen if...?
:::
```

## Slide Count Guidelines

| Length | Slides | Pacing       |
| ------ | ------ | ------------ |
| 50 min | 25-30  | ~2 min/slide |
| 75 min | 35-40  | ~2 min/slide |
| 90 min | 40-45  | ~2 min/slide |

**Minimum: 25 slides**

## Required Elements

1. Title slide
2. Learning objectives (3-5)
3. Motivating problem
4. Theory with equations
5. R code demonstration
6. Visualization
7. 3-5 quiz questions
8. Practice problem
9. Summary slide
10. Next steps preview

## Notation Standards

| Element        | Convention         |
| -------------- | ------------------ |
| Fixed effects  | Greek (α, β, γ, τ) |
| Random effects | Latin (u, v, w)    |

## Quality Checklist

- [ ] 25+ slides
- [ ] Learning objectives slide 2
- [ ] All code chunks labeled
- [ ] Figures have captions
- [ ] 3-5 quiz questions
- [ ] At least one think-pair-share
- [ ] Incremental code reveal
- [ ] Summary with key takeaways
- [ ] Smooth fade transitions
