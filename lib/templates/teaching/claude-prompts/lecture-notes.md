# Comprehensive Lecture Notes Generator

## Purpose

Generate instructor-facing lecture notes (20-40 pages) for statistics courses. These are long-form documents with prose explanations, executable R code, LaTeX math, and practice problems.

## Structure Requirements

### 1. Learning Objectives

- Use Bloom's taxonomy verbs: analyze, evaluate, apply, compare, derive, interpret
- 4-6 specific, measurable objectives
- Align with course-level outcomes

### 2. Motivating Problem

- Start with a real-world research scenario
- Use textbook datasets when available
- Frame the statistical question clearly
- Connect to student interests (health, agriculture, engineering, social science)

### 3. Method Introduction

- Present the statistical approach conceptually
- Use analogies where they genuinely clarify
- Avoid jargon initially; introduce terminology gradually
- Connect to prerequisite knowledge with brief review

### 4. Theory & Derivations

**Format: Rigorous with Intuition**

For each derivation:

1. State the result to be derived
2. Provide intuitive explanation of WHY this result makes sense
3. Full step-by-step mathematical derivation
4. Annotate each step with the rule/property used
5. Box or highlight key results

**Example annotation style:**

```latex
\begin{align}
E[MS_{Trt}] &= E\left[\frac{SS_{Trt}}{a-1}\right] \\
&= \frac{1}{a-1} E[SS_{Trt}] \quad \text{(linearity of expectation)} \\
&= \sigma^2 + \frac{n\sum\tau_i^2}{a-1}
\end{align}
```

### 5. R Implementation

**Package Loading:**

```r
pacman::p_load(
  emmeans, lme4, car, ggplot2, dplyr, tidyr,
  modelsummary, broom, gtsummary,
  performance, DHARMa
)
set.seed(545)  # Reproducibility
```

**Code Chunk Requirements:**

- Every chunk must have a label: `#| label: chunk-name`
- Figures: `#| label: fig-name` with `#| fig-cap: "Caption"`
- Tables: `#| label: tbl-name` with `#| tbl-cap: "Caption"`
- Include interpretation paragraph immediately after EVERY code output
- Use tidyverse style (pipes, dplyr verbs)

### 6. Worked Examples

**Required for each concept:**

1. **Hand-calculated example** - Show all arithmetic steps
2. **R code example** - Full analysis workflow with interpretation

### 7. Model Diagnostics

**Always include full diagnostic workflow:**

```r
performance::check_model(model)
```

### 8. Statistical Reporting

**Always report:**

- Effect sizes (η², ω², or Cohen's d)
- p-values
- Confidence intervals
- Sample sizes

### 9. Practice Problems

- Variable count by topic (4-10)
- Mix of conceptual, hand calculations, R-based
- **Complete solutions provided**

### 10. Check Your Understanding

End sections with 2-3 reflection questions.

## Callout Usage

```markdown
::: {.callout-tip}
**Practical Advice:** [Implementation tip]
:::

::: {.callout-warning}
**Common Mistake:** [Misconception to avoid]
:::

::: {.callout-note title="Advanced Topic"}
**Graduate Level:** [Extended content]
:::
```

## Notation Standards

| Element        | Convention         |
| -------------- | ------------------ |
| Fixed effects  | Greek (α, β, γ, τ) |
| Random effects | Latin (u, v, w)    |
| Nesting        | β_j(i) subscript   |
| Sum of squares | SS_Trt, SS_E       |

## LaTeX Macros

Use standardized macros for consistent notation (define in `macros.tex` for PDF, `mathjax-macros.html` for HTML):

| Macro       | Syntax      | Output   |
| ----------- | ----------- | -------- |
| Expectation | `\E{X}`     | E[X]     |
| Variance    | `\Var{X}`   | Var(X)   |
| Covariance  | `\Cov{X,Y}` | Cov(X,Y) |
| Probability | `\Prob{A}`  | P(A)     |
| Vector      | `\vect{y}`  | **y**    |
| Normal      | `\Normal`   | N        |
| MSE         | `\mse`      | MSE      |

### Quarto Configuration

**PDF:**

```yaml
format:
  pdf:
    pdf-engine: xelatex
    include-in-header:
      - file: path/to/macros.tex
```

**HTML:**

```yaml
format:
  html:
    include-in-header:
      - file: includes/mathjax-macros.html
    html-math-method:
      method: mathjax
      url: 'https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js'
```

## Quality Checklist

- [ ] 20-40 pages in length
- [ ] Bloom's taxonomy objectives
- [ ] Real-world motivating problem
- [ ] All derivations annotated
- [ ] Hand + R examples for each concept
- [ ] Code chunks labeled
- [ ] Interpretation after every output
- [ ] Diagnostics workflow included
- [ ] Effect sizes with p-values
- [ ] Misconception callouts
- [ ] Complete practice solutions
