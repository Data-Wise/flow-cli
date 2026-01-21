# Mathematical Derivations & Theory Appendix Generator

## Purpose

Generate comprehensive mathematical appendices for statistics topics. Full derivations, proofs, and theoretical foundations.

## Document Structure

### YAML Frontmatter

```yaml
---
title: "Mathematical Appendix: [Topic]"
format:
  html:
    toc: true
    number-sections: true
  pdf:
    toc: true
bibliography: references.bib
---
```

### Sections

1. Overview & Prerequisites
2. Notation Definitions
3. Main Derivations
4. Proofs of Key Theorems
5. Computational Connections (R)
6. Practice Derivations
7. References

## Derivation Format

### Template

```markdown
## [Result Name]

### Statement
**Theorem:** [Formal statement]

### Intuition
[2-3 sentences explaining WHY]

### Derivation
[Step-by-step with annotations]

### Key Insight
::: {.callout-important}
[Main takeaway]
:::
```

### Annotation Style

Every step annotated:

```latex
\begin{align}
E[MS_{Trt}] &= E\left[\frac{SS_{Trt}}{a-1}\right] \\
&= \frac{1}{a-1} E[SS_{Trt}] && \text{(linearity of expectation)} \\
&= \sigma^2 + \frac{n\sum\tau_i^2}{a-1} && \text{(from SS derivation)}
\end{align}
```

### Common Annotations

- (by definition)
- (linearity of expectation)
- (independence)
- (Cochran's theorem)
- (completing the square)
- (law of total variance)

## Key Topics

### EMS Derivations

Show **both** approaches:

1. **Rigorous:** Expected value algebra
2. **Heuristic:** Coefficient rules

Then compare results.

### Variance Decomposition

Prove: $SS_T = SS_{Trt} + SS_E$

Show cross-product term vanishes.

### F-Distribution

Under $H_0$: $F = \frac{MS_{Trt}}{MS_E} \sim F_{a-1, N-a}$

## Notation Standards

| Symbol | Meaning |
|--------|---------|
| μ | Grand mean |
| τ_i | Treatment effect |
| α_i | Factor A effect |
| β_j | Factor B effect |
| (αβ)_{ij} | Interaction |
| ε_{ij} | Error |

### Random Effects

| Symbol | Meaning |
|--------|---------|
| u_i | Random block |
| v_j | Random subject |

### Subscripts

| Notation | Meaning |
|----------|---------|
| y_{ij} | Observation j in i |
| ȳ_{i.} | Mean of group i |
| ȳ_{..} | Grand mean |
| β_{j(i)} | Nested effect |

## R Connection

```r
# Link theory to implementation
model <- aov(response ~ treatment, data = df)
anova_table <- summary(model)[[1]]

# MS_Trt / MS_E gives F-statistic
# Compare to theoretical F distribution
```

## Practice Problems

3-5 derivation exercises with collapsible solutions:

```markdown
### Problem 1
Derive E[MS_A] for two-way ANOVA.

::: {.callout-note collapse="true" title="Solution"}
[Full solution]
:::
```

## Quality Checklist

- [ ] Intuitive explanation before math
- [ ] Every step annotated
- [ ] Both rigorous + heuristic for EMS
- [ ] Notation table included
- [ ] R code shows connection
- [ ] Practice problems with solutions
- [ ] References use @citekey
