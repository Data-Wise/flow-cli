# Quarto Lint Guide

**Feature:** `teach validate --lint`
**Version:** Phase 1 (v1.0.0)
**Status:** Production Ready

---

## Table of Contents

1. [Overview](#overview)
2. [Getting Started](#getting-started)
3. [Lint Rules Explained](#lint-rules-explained)
4. [Usage Patterns](#usage-patterns)
5. [Integration](#integration)
6. [Troubleshooting](#troubleshooting)
7. [Best Practices](#best-practices)

---

## Overview

### What is teach validate --lint?

The lint feature provides **structural validation** for Quarto (`.qmd`) documents, catching issues that:
- Won't be detected by Quarto's built-in checks
- Silently render incorrectly
- Break document structure

### Why Not markdownlint?

markdownlint has a **~60% false positive rate** on Quarto syntax because:
- Doesn't understand Quarto-specific fenced divs (`:::`)
- Flags valid R chunk syntax as errors
- Doesn't recognize callout blocks
- Overly strict for academic documents

**Solution:** Custom Quarto-aware lint rules.

### Phase 1 Focus

**4 Structural Rules:**
1. Code blocks must have language tags
2. Fenced divs must be balanced
3. Only valid callout types allowed
4. No skipped heading levels

**Future Phases:**
- Phase 2: Formatting rules (spacing, tables)
- Phase 3: Content-type rules (slides, lectures, labs)
- Phase 4: Auto-fix suggestions, colored output

---

## Getting Started

### Installation

The lint validator is included in flow-cli v5.24.0+.

**Check installation:**
```bash
teach validate --help | grep lint
```

**Expected output:**
```
  --lint              Run Quarto-aware lint rules
  --quick-checks      Run fast lint subset only (Phase 1 rules)
```

### First Lint Run

**1. Navigate to your course project:**
```bash
cd ~/projects/teaching/stat-545
```

**2. Run lint on a single file:**
```bash
teach validate --lint slides/week-01.qmd
```

**3. Interpret results:**

```
→ lint-shared (v1.0.0)
  slides/week-01.qmd:
    ✗ Line 45: LINT_CODE_LANG_TAG: Fenced code block without language tag
    ✗ Line 78: LINT_HEADING_HIERARCHY: Heading level skip (h1 -> h3)
  ✗ 2 errors found
```

**4. Fix issues and re-run:**
```bash
# After fixing
teach validate --lint slides/week-01.qmd
```

```
→ lint-shared (v1.0.0)
  ✓ All files passed
```

---

## Lint Rules Explained

### LINT_CODE_LANG_TAG

**Rule:** All fenced code blocks must have a language tag.

**Why?** Bare code blocks:
- Don't get syntax highlighting
- Confuse readers about the language
- May render unexpectedly

#### ❌ Invalid

```markdown
```
x <- 1 + 1
mean(x)
```
```

**Error:**
```
Line 5: LINT_CODE_LANG_TAG: Fenced code block without language tag
```

#### ✅ Valid

```markdown
```{r}
x <- 1 + 1
mean(x)
```

```python
print("Hello, World!")
```

```text
This is plain text output
```
```

#### Common Language Tags

| Language | Tag | Use Case |
|----------|-----|----------|
| R code | `{r}` | Executable R chunks |
| Python | `{python}` or `python` | Python code |
| Output | `text` | Console output, logs |
| SQL | `sql` | Database queries |
| Bash | `bash` | Shell commands |

---

### LINT_DIV_BALANCE

**Rule:** Every fenced div opener (`:::`) must have a matching closer.

**Why?** Unbalanced divs:
- Break document structure
- Cause layout issues
- May hide content

#### ❌ Invalid

```markdown
::: {.callout-note}
This note is opened but never closed.

## Next Section

Content here...
```

**Error:**
```
Line 1: LINT_DIV_BALANCE: Unclosed fenced div (:::)
```

#### ✅ Valid

```markdown
::: {.callout-note}
This note is properly closed.
:::

## Next Section

::: {.column-margin}
Margin content
:::
```

#### Common Div Types

```markdown
::: {.callout-note}      # Callout blocks
::: {.column-margin}     # Layout columns
::: {.panel-tabset}      # Tab panels
::: {.incremental}       # Slide increments
::: {.fragment}          # Reveal.js fragments
```

---

### LINT_CALLOUT_VALID

**Rule:** Only recognized callout types are allowed.

**Why?** Invalid callout types:
- Render as plain divs (no styling)
- Confuse readers
- Look like bugs

#### Valid Callout Types

```markdown
::: {.callout-note}        # Blue, general information
::: {.callout-tip}         # Green, helpful tips
::: {.callout-important}   # Yellow, key points
::: {.callout-warning}     # Orange, caution
::: {.callout-caution}     # Red, danger/critical
```

#### ❌ Invalid

```markdown
::: {.callout-info}
This will render as an unstyled div.
:::

::: {.callout-danger}
Not a valid Quarto callout type.
:::
```

**Error:**
```
Line 1: LINT_CALLOUT_VALID: Unknown callout type '.callout-info'
        (valid: note, tip, important, warning, caution)
```

#### ✅ Valid

```markdown
::: {.callout-note}
## Note Title
This renders with blue styling.
:::

::: {.callout-warning}
Be careful with this approach.
:::
```

#### Visual Reference

| Type | Color | Icon | Use When |
|------|-------|------|----------|
| `note` | Blue | ℹ️ | General info, explanations |
| `tip` | Green | 💡 | Best practices, shortcuts |
| `important` | Yellow | ⚠️ | Key concepts, highlights |
| `warning` | Orange | ⚠️ | Potential issues, gotchas |
| `caution` | Red | 🛑 | Critical warnings, dangers |

---

### LINT_HEADING_HIERARCHY

**Rule:** Heading levels cannot skip (h1 → h3 is invalid).

**Why?** Skipped headings:
- Break document outline
- Confuse screen readers (accessibility)
- Violate semantic HTML

#### ❌ Invalid

```markdown
# Main Topic

### Subtopic (skipped h2!)

Content here...

##### Detail (skipped h3 and h4!)
```

**Errors:**
```
Line 3: LINT_HEADING_HIERARCHY: Heading level skip (h1 -> h3)
Line 7: LINT_HEADING_HIERARCHY: Heading level skip (h3 -> h5)
```

#### ✅ Valid

```markdown
# Main Topic

## Section

### Subsection

#### Detail

## Another Section (reset to h2 is fine)

# New Topic (reset to h1 is fine)
```

#### Heading Reset Rules

- ✅ **Resetting to shallower level is OK:** h3 → h1, h4 → h2
- ✅ **Incrementing by 1 is OK:** h1 → h2, h2 → h3
- ❌ **Skipping levels is NOT OK:** h1 → h3, h2 → h4

---

## Usage Patterns

### Pattern 1: Pre-commit Validation

**Use case:** Catch issues before they reach the repo.

**Setup** (one-time):

```bash
# Add to .git/hooks/pre-commit
cat >> .git/hooks/pre-commit <<'EOF'

# Lint checks (warn-only, never blocks commit)
if command -v teach &>/dev/null; then
    echo -e "  Running Quarto lint checks..."
    LINT_OUTPUT=$(teach validate --lint --quick-checks $STAGED_QMD 2>&1 || true)
    if [ -n "$LINT_OUTPUT" ]; then
        echo "$LINT_OUTPUT" | head -20
    fi
fi
EOF

chmod +x .git/hooks/pre-commit
```

**Usage:**
```bash
git add slides/week-01.qmd
git commit -m "Update slides"

# Output:
#   Running Quarto lint checks...
#   → lint-shared (v1.0.0)
#     slides/week-01.qmd:
#       ✗ Line 45: LINT_CODE_LANG_TAG: ...
```

**Note:** Lint warnings don't block commits (warn-only mode).

---

### Pattern 2: Bulk Validation

**Use case:** Audit entire course for lint issues.

**Command:**
```bash
teach validate --lint lectures/*.qmd slides/*.qmd labs/*.qmd
```

**Save output:**
```bash
teach validate --lint **/*.qmd > lint-report.txt 2>&1
```

**Count issues:**
```bash
teach validate --lint **/*.qmd 2>&1 | grep "✗ Line" | wc -l
```

---

### Pattern 3: CI/CD Integration

**Use case:** Automated lint checks on pull requests.

**GitHub Actions** (`.github/workflows/lint.yml`):

```yaml
name: Lint Quarto Files

on:
  pull_request:
    paths:
      - '**.qmd'

jobs:
  lint:
    runs-on: ubuntu-latest

    steps:
    - uses: actions/checkout@v3

    - name: Install flow-cli
      run: |
        brew tap Data-Wise/tap
        brew install flow-cli

    - name: Run lint checks
      run: |
        teach validate --lint --quick-checks
      continue-on-error: true  # Don't fail build on warnings
```

---

### Pattern 4: Watch Mode

**Use case:** Continuous validation while editing.

**Shell script** (`watch-lint.sh`):

```bash
#!/bin/bash
while true; do
    clear
    echo "=== Lint Check ($(date +%H:%M:%S)) ==="
    teach validate --lint --quiet "$1"
    sleep 5
done
```

**Usage:**
```bash
./watch-lint.sh slides/week-01.qmd
```

---

## Integration

### Quarto Preview

Lint before rendering:

```bash
# Check first
teach validate --lint slides/week-01.qmd && quarto preview
```

### VS Code

Add task (`.vscode/tasks.json`):

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Lint Quarto",
      "type": "shell",
      "command": "teach validate --lint ${file}",
      "group": "test",
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    }
  ]
}
```

**Run:** Cmd+Shift+P → "Tasks: Run Task" → "Lint Quarto"

---

## Troubleshooting

### Issue: "Validator not found: lint-shared"

**Cause:** Validator not in project's `.teach/validators/` directory.

**Fix:**
```bash
# Copy from flow-cli installation
mkdir -p .teach/validators
cp ~/.local/share/flow-cli/validators/lint-shared.zsh .teach/validators/

# Or if using Homebrew
cp $(brew --prefix flow-cli)/share/validators/lint-shared.zsh .teach/validators/
```

---

### Issue: Lint finds nothing

**Cause:** Not running in lint mode.

**Fix:**
```bash
# ❌ Wrong (runs default validation)
teach validate file.qmd

# ✅ Correct (runs lint)
teach validate --lint file.qmd
```

---

### Issue: Too many warnings

**Cause:** Legacy files with many issues.

**Strategies:**

**1. Incremental fixing:**
```bash
# Fix new files only
teach validate --lint $(git diff --name-only main | grep '\.qmd$')
```

**2. Suppress specific rules:**
```bash
# (Phase 2 feature - not yet available)
teach validate --lint --ignore LINT_HEADING_HIERARCHY file.qmd
```

**3. Use quiet mode:**
```bash
teach validate --lint --quiet file.qmd
```

---

### Issue: Performance slow

**Diagnosis:**
```bash
# Check file count
teach validate --lint --stats
```

**Solutions:**

1. **Lint specific directories:**
   ```bash
   teach validate --lint slides/*.qmd  # Not all files
   ```

2. **Use quick checks:**
   ```bash
   teach validate --quick-checks  # Phase 1 rules only
   ```

3. **Parallel processing** (future):
   ```bash
   # Phase 4 feature
   teach validate --lint --parallel
   ```

---

## Best Practices

### 1. Start with New Files

Don't try to fix all legacy files at once:

```bash
# Lint only files changed in current branch
git diff --name-only main | grep '\.qmd$' | xargs teach validate --lint
```

### 2. Fix Before Commit

Add to your git workflow:

```bash
# Personal habit
git add slides/week-01.qmd
teach validate --lint slides/week-01.qmd  # Check first
git commit -m "Update slides"
```

### 3. Document Exceptions

If you must violate a rule (rare), document why:

```markdown
<!-- Lint: LINT_HEADING_HIERARCHY disabled -->
<!-- Reason: Slide layout requires h1 -> h3 for styling -->

# Main Title

### Subtitle (intentional skip for visual hierarchy)
```

### 4. Use Pre-commit Hooks

Automate lint checks (see [Pattern 1](#pattern-1-pre-commit-validation)).

### 5. Educate Team

Share this guide with collaborators:

```bash
# Add to README.md
echo "See docs/guides/LINT-GUIDE.md for Quarto lint rules" >> README.md
```

---

## See Also

- **Quick Reference:** `docs/reference/REFCARD-LINT.md`
- **Tutorial:** `docs/tutorials/27-lint-quickstart.md`
- **Test Coverage:** `tests/TEST-COVERAGE-LINT.md`
- **Implementation Plan:** `docs/plans/2026-01-31-teach-validate-lint.md`

---

**Last Updated:** 2026-01-31
**Feature:** teach validate --lint (Phase 1)
**Maintained by:** flow-cli team
