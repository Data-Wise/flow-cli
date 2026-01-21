# Claude Code Teaching Prompts

Optimized prompts for generating statistics course content with Claude Code.

## Available Prompts

| Prompt | Purpose | Output |
|--------|---------|--------|
| `lecture-notes.md` | Comprehensive lecture documents | 20-40 pages |
| `revealjs-slides.md` | Visual presentations | 25+ slides |
| `derivations-appendix.md` | Mathematical theory appendices | Variable |

## Usage

### With Scholar Plugin

These prompts complement the Scholar plugin's `/teaching:*` commands:

```bash
# Uses lecture-notes.md structure
/teaching:lecture "Topic Name"

# Uses revealjs-slides.md structure
/teaching:slides "Topic Name" 75
```

### Standalone

Reference the prompt when asking Claude Code to generate content:

```
Create lecture notes for "Factorial ANOVA" following the structure
in lib/templates/teaching/claude-prompts/lecture-notes.md
```

## Integration with Teaching Style

These prompts work with the Scholar plugin's 4-layer teaching style system.

Create `.claude/teaching-style.local.md` in your course repository to customize:

- Pedagogical approach
- Proof style
- R packages
- Notation conventions
- Command-specific overrides

See Scholar plugin examples: `scholar/examples/teaching-styles/`

## Key Features

### Lecture Notes

- Problem-based learning structure
- Rigorous-with-intuition derivations
- Hand-calculated + R code examples
- Full diagnostic workflows
- Practice problems with solutions

### RevealJS Slides

- Minimum 25 slides
- Incremental code reveal
- Interactive quiz questions
- Think-pair-share prompts
- Smooth fade transitions

### Derivations Appendix

- Step-by-step proofs
- Every step annotated
- Both rigorous and heuristic approaches
- Matrix notation sections
- Practice derivation problems

## Customization

Modify prompts for your course by adjusting:

1. **R packages** - Add/remove based on course needs
2. **Notation** - Match your textbook conventions
3. **Depth** - Adjust derivation detail level
4. **Examples** - Specify your dataset preferences
5. **LaTeX macros** - Standardize notation (see below)

## LaTeX Macros

For consistent notation across PDF and HTML output, use standardized macros:

### Macro Files

| File | Purpose |
|------|---------|
| `macros.tex` | LaTeX macros for PDF output |
| `mathjax-macros.html` | MathJax macros for HTML |

### Key Macros

| Category | Examples |
|----------|----------|
| Statistical operators | `\E{X}`, `\Var{X}`, `\Cov{X,Y}`, `\Prob{A}` |
| Regression | `\SE`, `\mse`, `\sse`, `\Bias` |
| Vectors/matrices | `\vect{y}`, `\tr`, `\diag` |
| Distributions | `\Normal`, `\Binom`, `\Poiss` |
| Independence | `\indep`, `\nindep` |

### Quarto Configuration

**PDF output:**

```yaml
format:
  pdf:
    pdf-engine: xelatex
    include-in-header:
      - file: path/to/macros.tex
```

**HTML output:**

```yaml
format:
  html:
    include-in-header:
      - file: includes/mathjax-macros.html
    html-math-method:
      method: mathjax
      url: "https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"
```

See `derivations-appendix.md` for the complete macro reference.

## Related Files

- `teach-config.yml.template` - Course configuration
- `exam-template.md` - Exam structure
- Scholar plugin teaching style examples
