# Lint Migration Guide

A step-by-step guide for existing courses upgrading to flow-cli v5.24.0 with new lint validation features.

## Overview

### What's New in v5.24.0

flow-cli v5.24.0 introduces **lint validation** - automated quality checks for your Quarto teaching content. Think of it as a spell-checker for your course materials, catching structural issues before they cause rendering problems.

**Four lint rules protect your content:**

| Rule | Detects | Impact |
|------|---------|--------|
| **CODE_LANG_TAG** | Bare code blocks without language tags | Silent render failures, broken syntax highlighting |
| **DIV_BALANCE** | Unclosed or mismatched `:::` divs | Layout corruption, nested content errors |
| **CALLOUT_VALID** | Invalid callout types | Unstyled content, rendering warnings |
| **HEADING_HIERARCHY** | Skipped heading levels | Broken navigation, accessibility issues |

**Quick Win:** Run lint on your existing course and fix issues in 5-10 minutes per file. Most violations are simple fixes (add `{r}` tags, close divs).

### Benefits

- **Catch issues early** - Before students see broken content
- **Improve quality** - Consistent formatting across all materials
- **Save time** - Automated checks vs manual review
- **Confidence** - Know content will render correctly

---

## Quick Start (5-Minute Setup)

Get running with lint validation in 5 minutes:

```bash
# 1. Update flow-cli to v5.24.0+
brew upgrade flow-cli  # or your install method

# 2. Verify version
flow --version
# Expected: flow-cli v5.24.0 or higher

# 3. Navigate to your course
cd ~/teaching/stat-545  # or ~/teaching/stat-579, etc.

# 4. Run lint on a single file
teach validate --lint lectures/week-01-intro.qmd

# 5. Review output and fix violations
# See "Common Patterns & Fixes" section below

# 6. (Optional) Run on all lecture files
teach validate --lint lectures/*.qmd
```

**Expected output:**

```
✅ Validation Checks:
  ✅ YAML valid
  ✅ Syntax valid
  ✅ Lint checks pass

📊 Lint Summary:
  ✅ CODE_LANG_TAG: All code blocks tagged (12 blocks)
  ✅ DIV_BALANCE: All divs balanced (8 pairs)
  ✅ CALLOUT_VALID: All callouts valid (5 callouts)
  ✅ HEADING_HIERARCHY: Sequential hierarchy (6 headings)
```

Or if issues are found:

```
⚠️  Validation Checks:
  ✅ YAML valid
  ✅ Syntax valid
  ❌ Lint checks failed (3 violations)

📊 Lint Summary:
  ❌ CODE_LANG_TAG: 2 bare code blocks found
     Line 45: Bare code block (add language tag)
     Line 78: Bare code block (add language tag)

  ❌ DIV_BALANCE: 1 unclosed div
     Line 92: Unclosed div (add closing :::)
```

---

## Installation & Setup

### For Existing Courses Using flow-cli

If you're already using flow-cli v5.x:

```bash
# 1. Upgrade via Homebrew
brew upgrade flow-cli

# Or via npm (if installed that way)
npm update -g @data-wise/flow-cli

# Or pull latest from git (if using local install)
cd ~/projects/dev-tools/flow-cli
git pull origin main
source flow.plugin.zsh
```

**Verify your environment:**

```bash
# Check version
flow --version

# Verify .teach/ directory exists
ls .teach/
# Expected: config.yml, validators/ (optional)

# Test lint command
teach validate --lint --help
```

**No additional setup needed** - lint validators are built into flow-cli.

### For New Courses

If you're setting up a new course with flow-cli for the first time:

```bash
# Initialize course with full validation setup
cd ~/teaching/stat-601
teach init --with-validators

# This creates:
# .teach/config.yml          # Course configuration
# .teach/validators/         # Validator directory (future custom validators)
# .teach/hooks/              # Git hooks (optional)
```

**Verify setup:**

```bash
teach validate --lint lectures/week-01.qmd
# Should work immediately on any .qmd file
```

### Troubleshooting Install Issues

**Issue:** `teach validate --lint` not recognized

```bash
# Solution 1: Reload plugin
source ~/.zshrc

# Solution 2: Check plugin load order
which teach
# Should show: teach () { ... } from flow-cli

# Solution 3: Reinstall
brew reinstall flow-cli
```

**Issue:** Version shows v5.23.0 or earlier

```bash
# Force upgrade
brew upgrade --fetch-HEAD flow-cli

# Or clean install
brew uninstall flow-cli
brew install data-wise/tap/flow-cli
```

---

## Understanding Lint Rules

Each rule catches a specific class of errors. Here's what they mean and how to fix them.

### Rule 1: CODE_LANG_TAG

**What it checks:** All fenced code blocks (3+ backticks) must have a language tag.

**Why it matters:** Bare code blocks silently fail syntax highlighting and can cause Quarto render errors.

#### Examples

❌ **Bad: Bare code block**

```qmd
Here's some R code:

```
x <- rnorm(100)
mean(x)
```

**Problem:** Quarto doesn't know this is R code → no syntax highlighting, no execution.
```

✅ **Good: Tagged code block**

```qmd
Here's some R code:

```{r}
x <- rnorm(100)
mean(x)
```

**Works:** Quarto recognizes R → highlights syntax, executes code.
```

✅ **Alternative: Non-executable text**

```qmd
Here's pseudocode:

```{.text}
FOR i = 1 to 100
  PRINT i
END
```

**Works:** Tagged as text → renders as preformatted block.
```

#### Common Tags

| Tag | Use Case |
|-----|----------|
| `{r}` | R code (executable) |
| `{python}` | Python code (executable) |
| `{bash}` | Shell commands (executable) |
| `{.text}` | Plain text (non-executable) |
| `{.output}` | Command output examples |

### Rule 2: DIV_BALANCE

**What it checks:** All `:::` div openers must have matching `:::` closers.

**Why it matters:** Unclosed divs corrupt page layout and break nested content rendering.

#### Examples

❌ **Bad: Unclosed div**

```qmd
::: {.callout-note}
This is important information.
<!-- Missing closing ::: -->

Next section starts here.
```

**Problem:** "Next section" gets swallowed into the callout div.

✅ **Good: Balanced divs**

```qmd
::: {.callout-note}
This is important information.
:::

Next section starts here.
```

❌ **Bad: Nested divs closed in wrong order**

```qmd
::: {.column-page}
::: {.callout-tip}
Nested content
::: <!-- Closes column-page, not callout! -->
:::
```

✅ **Good: Proper nesting**

```qmd
::: {.column-page}
::: {.callout-tip}
Nested content
::: <!-- Closes callout-tip -->
::: <!-- Closes column-page -->
```

**Tip:** Match divs like parentheses - inner closes before outer.

### Rule 3: CALLOUT_VALID

**What it checks:** Callout divs use valid Quarto callout types.

**Why it matters:** Invalid callout types render as unstyled divs, breaking visual hierarchy.

#### Valid Callout Types

Quarto supports exactly 5 callout types:

| Type | Purpose | Icon |
|------|---------|------|
| `note` | General information | 📝 |
| `tip` | Helpful suggestions | 💡 |
| `important` | Key concepts | ❗ |
| `warning` | Cautions | ⚠️ |
| `caution` | Danger/risk | 🚨 |

#### Examples

❌ **Bad: Invalid callout type**

```qmd
::: {.callout-info}
<!-- 'info' is not a standard Quarto callout -->
This won't be styled correctly.
:::
```

✅ **Good: Valid callout type**

```qmd
::: {.callout-note}
<!-- 'note' is a standard type -->
This renders with proper styling.
:::
```

**Common mistakes:**

- `.callout-info` → Use `.callout-note` instead
- `.callout-danger` → Use `.callout-caution` instead
- `.callout-success` → Use `.callout-tip` instead

### Rule 4: HEADING_HIERARCHY

**What it checks:** Headings follow sequential levels (no skipped levels).

**Why it matters:** Broken hierarchy confuses navigation, screen readers, and document structure.

#### Examples

❌ **Bad: Skipped heading level**

```qmd
# Week 1: Introduction
### Subsection A (skipped ##)
#### Detail
```

**Problem:** Jump from H1 → H3 breaks document outline.

✅ **Good: Sequential hierarchy**

```qmd
# Week 1: Introduction
## Section A
### Subsection A
#### Detail
```

❌ **Bad: Multiple H1s in same file**

```qmd
# Week 1: Introduction
# Week 2: Foundations (should be ##)
```

**Problem:** Multiple top-level headings fragment document structure.

✅ **Good: One H1, structured sections**

```qmd
# Week 1 & 2: Foundations
## Week 1: Introduction
## Week 2: Core Concepts
```

**Tip:** Reserve `#` (H1) for document title, use `##` (H2) for main sections.

---

## Common Patterns & Fixes

Real-world scenarios from stat-545 and stat-579 migrations.

### Pattern 1: Lots of Bare Code Blocks

**Scenario:** You've been using bare blocks for years, now have 100+ violations.

**Diagnosis:**

```bash
# Find all bare code blocks
cd ~/teaching/stat-545
grep -n "^\`\`\`$" lectures/*.qmd

# Example output:
# lectures/week-01.qmd:45:```
# lectures/week-01.qmd:48:```
# lectures/week-02.qmd:23:```
# ...
```

**Fix Strategy A: Bulk tag as R code**

```bash
# For files with mostly R code, tag all bare blocks as {r}
# WARNING: Review first, this replaces ALL bare blocks

# Dry run (shows changes without applying)
sed -n 's/^```$/```{r}/p' lectures/week-01.qmd

# Apply changes
sed -i '' 's/^```$/```{r}/' lectures/week-01.qmd
```

**Fix Strategy B: Manual review (recommended)**

```bash
# Use lint to find violations
teach validate --lint lectures/week-01.qmd

# Open file, jump to line number
vim +45 lectures/week-01.qmd
# Or use your preferred editor
```

Then tag appropriately:

- R code → `{r}`
- Python → `{python}`
- Shell → `{bash}`
- Plain text → `{.text}`

### Pattern 2: Unbalanced Divs from Copy-Paste

**Scenario:** You copied a callout from another file, forgot the closing `:::`.

**Diagnosis:**

```bash
# Lint shows exact line number
teach validate --lint lectures/week-03.qmd

# Output:
# ❌ DIV_BALANCE: 1 unclosed div
#    Line 92: Unclosed div (add closing :::)
```

**Fix:**

```bash
# Open at line 92
vim +92 lectures/week-03.qmd
```

Use your editor's bracket matching (if supported) or manually count:

```qmd
::: {.callout-note}  # Line 92: Opener
Content here.
<!-- Add closing ::: -->
```

**Count trick:**

```bash
# Count openers vs closers
grep -c "^:::" lectures/week-03.qmd  # Total ::: lines
grep -c "^::: {" lectures/week-03.qmd  # Openers only

# Should be equal or 2x (if closers are also :::)
```

### Pattern 3: Custom Callout Types

**Scenario:** You've been using `.callout-info` or `.callout-success` in your materials.

**Decision Point:** Convert to standard types OR disable the rule.

#### Option A: Convert to Standard Types (Recommended)

```bash
# Find all custom callout types
grep -n "\.callout-info" lectures/*.qmd

# Convert .callout-info → .callout-note
sed -i '' 's/\.callout-info/.callout-note/g' lectures/*.qmd

# Convert .callout-success → .callout-tip
sed -i '' 's/\.callout-success/.callout-tip/g' lectures/*.qmd
```

#### Option B: Disable LINT_CALLOUT_VALID (Not Recommended)

If you have custom Quarto extensions that define additional callout types:

```bash
# Skip callout validation for specific files
teach validate --lint --validators lint-shared lectures/week-custom.qmd
# (Future: custom validator configs)
```

**Trade-off:** Disabling the rule means you won't catch typos like `.callout-notte`.

### Pattern 4: Heading Hierarchy Issues

**Scenario:** You've been using `###` for all subheadings, regardless of nesting.

**Diagnosis:**

```bash
teach validate --lint lectures/week-05.qmd

# Output:
# ❌ HEADING_HIERARCHY: Skipped heading level
#    Line 34: H3 follows H1 (expected H2)
```

**Fix:** Restructure headings sequentially:

```qmd
<!-- Before -->
# Week 5: Regression
### Model Assumptions (skipped H2)
### Diagnostics (skipped H2)

<!-- After -->
# Week 5: Regression
## Model Assumptions
## Diagnostics
```

**Mass fix strategy:**

```bash
# Downgrade all H3 → H2 (review first!)
sed -i '' 's/^### /## /' lectures/week-05.qmd
```

---

## Configuration Options

Customize lint behavior for your workflow.

### Run Lint on Specific Files

```bash
# Single file
teach validate --lint lectures/week-01-intro.qmd

# Multiple files (glob pattern)
teach validate --lint lectures/week-*.qmd

# All .qmd files recursively
teach validate --lint **/*.qmd
```

### Quiet Mode (For CI/CD)

```bash
# Suppress detailed output, return only exit code
teach validate --lint --quiet lectures/week-01.qmd

# Exit code 0 = pass, non-zero = violations found
echo $?
```

**Use case:** GitHub Actions, pre-commit hooks that need pass/fail only.

### Quick Checks Only

```bash
# Run lint-shared validator only (fastest)
teach validate --lint --quick-checks lectures/week-01.qmd

# Alias for: --validators lint-shared
```

**Performance:** ~50% faster on large files, runs core lint rules only.

### Custom Validators (Future)

```bash
# Coming in v5.25.0: Specify validator plugins
teach validate --validators lint-shared,lint-slides lectures/slides.qmd
```

**Planned validators:**

- `lint-slides` - RevealJS-specific checks
- `lint-accessibility` - WCAG compliance
- `lint-citations` - BibTeX validation

---

## Workflow Integration

Integrate lint into your existing teaching workflow.

### Pre-Commit Hook (Warn-Only Mode)

**Goal:** Run lint on staged `.qmd` files before commit, warn about issues without blocking.

**Setup:**

```bash
# 1. Create hooks directory
mkdir -p .teach/hooks

# 2. Create pre-commit hook
cat > .teach/hooks/pre-commit << 'EOF'
#!/bin/bash
# Lint staged .qmd files (warn, don't block)

echo "🔍 Running lint checks on staged .qmd files..."

changed_files=$(git diff --cached --name-only --diff-filter=ACM | grep '\.qmd$')

if [[ -n "$changed_files" ]]; then
    teach validate --lint --quiet $changed_files || true
    # || true = warn but never block commit

    if [[ $? -ne 0 ]]; then
        echo ""
        echo "⚠️  Lint violations found (see above)"
        echo "💡 Tip: Fix with 'teach validate --lint <file>'"
        echo "⏩ Continuing with commit (violations not blocking)"
        echo ""
    fi
fi
EOF

# 3. Make executable
chmod +x .teach/hooks/pre-commit

# 4. Link to git hooks
ln -sf ../../.teach/hooks/pre-commit .git/hooks/pre-commit
```

**Usage:** Violations display as warnings but never block your commit.

**To upgrade to blocking mode:** Remove `|| true` from the hook.

### CI/CD Integration (GitHub Actions)

**Goal:** Run lint checks on every push/PR to catch issues before merge.

**Setup:**

```yaml
# .github/workflows/lint.yml
name: Lint Course Content

on:
  push:
    branches: [main, dev]
  pull_request:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Install flow-cli
        run: |
          brew tap data-wise/tap
          brew install flow-cli

      - name: Run lint on lectures
        run: |
          teach validate --lint lectures/*.qmd

      - name: Run lint on labs
        run: |
          teach validate --lint labs/*.qmd
```

**Result:** PR checks show pass/fail status, blocking merge if violations found.

### Watch Mode (Future)

**Coming in v5.25.0:** Auto-run lint on file changes.

```bash
# Planned feature
teach validate --lint --watch

# Expected behavior:
# 👀 Watching lectures/*.qmd for changes...
# 🔄 week-01.qmd changed → running lint...
# ✅ No violations found
```

**Use case:** Keep lint check running in terminal while editing in IDE.

---

## Migration Strategies

Choose the approach that fits your timeline and course schedule.

### Strategy 1: Big Bang (1-2 Hours)

**Best for:** Small courses (< 20 files), semester break, motivated instructors.

**Timeline:** Complete migration in one sitting.

**Steps:**

```bash
# 1. Upgrade flow-cli
brew upgrade flow-cli

# 2. Run lint on ALL content
cd ~/teaching/stat-545
teach validate --lint lectures/*.qmd > lint-report.txt 2>&1
teach validate --lint labs/*.qmd >> lint-report.txt 2>&1

# 3. Review violations
cat lint-report.txt

# 4. Fix all issues (batch edits where possible)
# Use patterns from "Common Patterns & Fixes" section

# 5. Verify clean state
teach validate --lint lectures/*.qmd labs/*.qmd

# 6. Commit
git add -A
git commit -m "chore: fix all lint violations for v5.24.0"
git push
```

**Pros:** Done immediately, clean slate going forward.

**Cons:** Requires focused time block, may surface old technical debt.

### Strategy 2: Incremental (Ongoing)

**Best for:** Active semester, large courses (50+ files), busy instructors.

**Timeline:** Fix issues gradually as you edit files.

**Steps:**

```bash
# 1. Upgrade flow-cli
brew upgrade flow-cli

# 2. Enable pre-commit hook (warn mode)
# See "Pre-Commit Hook" section above

# 3. Fix files as you edit them
# Example: Updating week 5 lecture
vim lectures/week-05-regression.qmd
# Save changes

# 4. Run lint before commit
teach validate --lint lectures/week-05-regression.qmd
# Fix any violations

# 5. Commit clean file
git add lectures/week-05-regression.qmd
git commit -m "feat(week-05): update regression examples + fix lint"
git push
```

**Pros:** Low friction, spreads work across semester, no dedicated time block.

**Cons:** Slower to achieve full compliance, old files remain unfixed until edited.

### Strategy 3: Selective (Targeted)

**Best for:** Mixed content quality, archived materials, legacy courses.

**Timeline:** Fix only high-priority content, skip archived files.

**Steps:**

```bash
# 1. Identify high-priority files
# - Current semester lectures
# - Public-facing materials (course website)
# - Frequently edited content

# 2. Run lint on priority files only
teach validate --lint lectures/week-{01..10}.qmd

# 3. Fix violations in priority content

# 4. Document non-priority files as "archived"
mkdir -p _archive
git mv lectures/old-* _archive/

# 5. Add .gitignore exception (optional)
echo "_archive/*.qmd" >> .gitignore
```

**Pros:** Focuses effort on content students actually see.

**Cons:** Uneven quality across materials, technical debt in archived files.

---

## Troubleshooting

Common issues and solutions during migration.

### False Positives

**Issue:** Inline code with backticks triggers CODE_LANG_TAG

```qmd
Use the `mean()` function to calculate averages.
```

**Diagnosis:**

```bash
teach validate --lint lectures/week-01.qmd
# ❌ CODE_LANG_TAG: Bare code block at line 23
```

**Solution:** The lint rule only checks fenced blocks (3+ backticks). Inline code (1 backtick) is ignored.

**Likely cause:** You have a bare fenced block elsewhere in the file. Check the exact line number:

```bash
# Jump to reported line
vim +23 lectures/week-01.qmd
```

**Issue:** Nested divs confuse balance checker

```qmd
::: {.column-page}
::: {.callout-note}
::: {.fragment}
Content
::: <!-- Closes fragment -->
::: <!-- Closes callout -->
::: <!-- Closes column-page -->
```

**Diagnosis:**

```bash
teach validate --lint lectures/week-02.qmd
# ❌ DIV_BALANCE: Unbalanced divs (3 openers, 2 closers)
```

**Solution:** Ensure proper nesting. Inner divs must close before outer divs.

**Debug trick:**

```bash
# Count all ::: lines
grep -n "^:::" lectures/week-02.qmd

# Should see openers with {...}, closers without
# 34: ::: {.column-page}
# 35: ::: {.callout-note}
# 36: ::: {.fragment}
# 40: :::  # Closes fragment
# 41: :::  # Closes callout
# 42: :::  # Closes column-page
```

### Performance Issues

**Issue:** Lint is slow on large files (> 1000 lines)

**Diagnosis:**

```bash
time teach validate --lint lectures/week-10-massive.qmd
# real    0m15.432s  (too slow!)
```

**Solution 1: Use quick checks**

```bash
teach validate --lint --quick-checks lectures/week-10-massive.qmd
# Runs core lint rules only, ~50% faster
```

**Solution 2: Split large files**

```qmd
<!-- week-10-massive.qmd → Split into sections -->
week-10-part1-theory.qmd
week-10-part2-examples.qmd
week-10-part3-lab.qmd
```

**Solution 3: Skip lint for specific files (not recommended)**

```bash
# Validate YAML/syntax only, skip lint
teach validate lectures/week-10-massive.qmd
# (No --lint flag)
```

### Validator Conflicts

**Issue:** Custom validators not found

```bash
teach validate --validators lint-shared,my-custom lectures/week-01.qmd
# Error: Validator 'my-custom' not found
```

**Diagnosis:**

```bash
# Check validator directory
ls .teach/validators/
# Expected: lint-shared/ (built-in), my-custom/ (if custom)
```

**Solution:** Custom validators are a future feature (v5.25.0). For now, use built-in validators only:

```bash
# Correct usage (v5.24.0)
teach validate --lint lectures/week-01.qmd
# Uses built-in lint-shared validator
```

---

## Examples from Real Courses

Learn from actual migrations.

### stat-545 Migration (Simon Fraser University)

**Course:** Graduate-level data science (85 .qmd files)

**Timeline:** 1 hour (Big Bang strategy)

**Findings:**

```bash
# Initial lint run
teach validate --lint lectures/*.qmd labs/*.qmd

# Results:
# ✅ YAML valid: 85/85 files
# ✅ Syntax valid: 85/85 files
# ❌ Lint violations: 17 files (20%)

# Breakdown:
# - 12 bare code blocks (all R code)
# - 3 unbalanced divs (copy-paste errors)
# - 2 invalid callouts (.callout-info → .callout-note)
# - 0 heading hierarchy issues
```

**Fixes:**

```bash
# 1. Fixed bare R code blocks (batch edit)
for file in lectures/*.qmd; do
    sed -i '' 's/^```$/```{r}/' "$file"
done

# 2. Fixed unbalanced divs (manual review)
vim +92 lectures/week-03.qmd
vim +156 labs/lab-04.qmd
vim +201 labs/lab-07.qmd

# 3. Fixed invalid callouts
sed -i '' 's/\.callout-info/.callout-note/g' lectures/*.qmd
```

**Outcome:**

```bash
# Final verification
teach validate --lint lectures/*.qmd labs/*.qmd

# Results:
# ✅ All checks pass (85/85 files)
# Total time: 52 minutes
```

### stat-579 Migration (Iowa State University)

**Course:** Causal inference (42 .qmd files)

**Timeline:** 2 weeks (Incremental strategy)

**Approach:**

```bash
# Week 1: Setup pre-commit hook
# See "Pre-Commit Hook" section

# Week 2: Fix files during regular updates
# - Updated week 1-3 lectures → fixed 4 violations
# - Created new week 4 lab → 0 violations (wrote clean)
# - Reviewed old exams → skipped (archived content)
```

**Findings:**

- 6 heading hierarchy issues (lectures used inconsistent H2/H3)
- 2 bare code blocks (Python examples)
- 1 unbalanced div (nested callout)

**Outcome:**

- High-priority content (weeks 1-8): 100% clean
- Archived content (old exams): Unfixed, documented in README
- Pre-commit hook: Prevents new violations

### Before/After Comparison

**Before lint adoption:**

```bash
teach validate lectures/week-01-intro.qmd

# Output:
# ✅ YAML valid
# ✅ Syntax valid
# ❌ Render failed
#    Error: Div not closed (line 92)
#    (Spent 15 minutes debugging render error)
```

**After lint adoption:**

```bash
teach validate --lint lectures/week-01-intro.qmd

# Output:
# ✅ YAML valid
# ✅ Syntax valid
# ✅ Lint checks pass
#
# 📊 Lint Summary:
#   ✅ CODE_LANG_TAG: All code blocks tagged (8 blocks)
#   ✅ DIV_BALANCE: All divs balanced (6 pairs)
#   ✅ CALLOUT_VALID: All callouts valid (3 callouts)
#   ✅ HEADING_HIERARCHY: Sequential hierarchy (5 headings)
#
# ✅ Render successful
# (Issues caught before rendering, saved 15 minutes)
```

---

## Next Steps

After completing your migration:

### Immediate Actions

- [ ] **Run lint on all course content**
  ```bash
  teach validate --lint lectures/*.qmd labs/*.qmd
  ```

- [ ] **Fix violations** (use patterns from "Common Patterns & Fixes")

- [ ] **Verify clean state**
  ```bash
  teach validate --lint lectures/*.qmd labs/*.qmd
  # Should show: ✅ All checks pass
  ```

- [ ] **Commit changes**
  ```bash
  git add -A
  git commit -m "chore: migrate to flow-cli v5.24.0 lint validation"
  git push
  ```

### Optional Enhancements

- [ ] **Enable pre-commit hook** (see "Workflow Integration")
  - Prevents new violations from being committed
  - Warns about issues before they reach students

- [ ] **Add CI/CD integration** (see "CI/CD Integration")
  - Automated lint checks on every PR
  - Blocks merges with violations

- [ ] **Update course README**
  ```markdown
  ## Content Quality

  This course uses flow-cli v5.24.0 lint validation to ensure high-quality materials.

  Before committing .qmd files:
  ```bash
  teach validate --lint <file>
  ```
  ```

### Share Feedback

Help improve lint validation for the teaching community:

- **Report false positives:** https://github.com/Data-Wise/flow-cli/issues/new?labels=lint,bug
- **Request new rules:** https://github.com/Data-wise/flow-cli/issues/new?labels=lint,enhancement
- **Share migration tips:** https://github.com/Data-Wise/flow-cli/discussions

### Learn More

**Documentation:**

- [Lint Quick Start Tutorial](../tutorials/27-lint-quickstart.md) - 10-minute hands-on tutorial
- [Complete Lint Guide](LINT-GUIDE.md) - Deep dive into all rules and validators
- [Lint Quick Reference](../reference/REFCARD-LINT.md) - One-page command cheat sheet
- [Lint Workflow Patterns](../workflows/WORKFLOW-LINT.md) - Integration strategies

**Community:**

- [GitHub Discussions](https://github.com/Data-Wise/flow-cli/discussions) - Ask questions
- [flow-cli Slack](https://data-wise.slack.com) - Real-time support (coming soon)

---

## Summary

**Migration in 3 steps:**

1. **Upgrade:** `brew upgrade flow-cli` (5 minutes)
2. **Diagnose:** `teach validate --lint lectures/*.qmd` (2 minutes)
3. **Fix:** Address violations using patterns from this guide (5-60 minutes depending on strategy)

**Key Takeaways:**

- Lint catches structural issues before they cause rendering problems
- Most violations are quick fixes (add tags, close divs)
- Choose a migration strategy that fits your timeline
- Pre-commit hooks and CI/CD prevent future violations

**Need help?** Open an issue or discussion on GitHub.

---

**Last Updated:** 2026-01-31
**flow-cli Version:** v5.24.0+
**Guide Maintainer:** flow-cli team
