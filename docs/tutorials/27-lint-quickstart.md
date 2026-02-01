# Tutorial 27: Lint Quickstart

**Time:** 10 minutes
**Level:** Beginner
**Prerequisites:** flow-cli installed, Quarto project

---

## Learning Objectives

By the end of this tutorial, you will:
- ✅ Understand what lint checks detect
- ✅ Run lint on your Quarto files
- ✅ Fix common lint issues
- ✅ Integrate lint into your workflow

---

## Step 1: Create a Test File (2 min)

Create a file with intentional issues to see how lint works.

```bash
# Create test file
cat > /tmp/test-lint.qmd <<'EOF'
---
title: "Lint Test"
---

# Main Section

### Skipped heading level

Here's some code:

```
x <- 1 + 1
```

::: {.callout-info}
This is an invalid callout type.
:::

::: {.callout-note}
This callout is never closed.

## Another Section

Content here.
EOF
```

---

## Step 2: Run Your First Lint (2 min)

```bash
teach validate --lint /tmp/test-lint.qmd
```

**Expected Output:**

```
→ lint-shared (v1.0.0)
  /tmp/test-lint.qmd:
    ✗ Line 11: LINT_CODE_LANG_TAG: Fenced code block without language tag
    ✗ Line 19: LINT_DIV_BALANCE: Unclosed fenced div (:::)
    ✗ Line 15: LINT_CALLOUT_VALID: Unknown callout type '.callout-info'
                (valid: note, tip, important, warning, caution)
    ✗ Line 7: LINT_HEADING_HIERARCHY: Heading level skip (h1 -> h3)
  ✗ 4 errors found

────────────────────────────────────────────────────
✗ Summary: 4 errors found
  Files checked: 1
  Validators run: 1
  Time: 0s
```

**What happened?**
- Detected **4 different error types**
- Each error shows **line number** and **explanation**
- Process completed in **<1 second**

---

## Step 3: Fix Each Issue (4 min)

### Fix 1: Add Language Tag

**Before:**
```markdown
```
x <- 1 + 1
```
```

**After:**
```markdown
```{r}
x <- 1 + 1
```
```

---

### Fix 2: Change Callout Type

**Before:**
```markdown
::: {.callout-info}
This is an invalid callout type.
:::
```

**After:**
```markdown
::: {.callout-note}
This is now a valid callout type.
:::
```

---

### Fix 3: Close the Div

**Before:**
```markdown
::: {.callout-note}
This callout is never closed.

## Another Section
```

**After:**
```markdown
::: {.callout-note}
This callout is now properly closed.
:::

## Another Section
```

---

### Fix 4: Fix Heading Hierarchy

**Before:**
```markdown
# Main Section

### Skipped heading level
```

**After:**
```markdown
# Main Section

## Proper heading level

### Now this is correct
```

---

## Step 4: Verify Fixes (1 min)

Run lint again after fixing:

```bash
teach validate --lint /tmp/test-lint.qmd
```

**Expected Output:**

```
→ lint-shared (v1.0.0)
  ✓ All files passed

────────────────────────────────────────────────────
✓ Summary: All validators passed
  Files checked: 1
  Validators run: 1
  Time: 0s
```

**Success!** ✅ All issues resolved.

---

## Step 5: Try on Your Real Files (1 min)

Now run lint on your actual course files:

```bash
# Single file
teach validate --lint lectures/week-01.qmd

# Multiple files
teach validate --lint slides/*.qmd

# All .qmd files (auto-discover)
cd slides && teach validate --lint
```

---

## Common Patterns

### Pattern 1: Check Before Commit

```bash
# Your workflow
vim slides/week-02.qmd          # Edit file
teach validate --lint slides/week-02.qmd   # Check for issues
git add slides/week-02.qmd      # Stage if clean
git commit -m "Update slides"   # Commit
```

---

### Pattern 2: Batch Check All Slides

```bash
# Check all slides at once
teach validate --lint slides/*.qmd

# Save output to review later
teach validate --lint slides/*.qmd > lint-report.txt 2>&1
```

---

### Pattern 3: Quick Checks Only

For faster checking (Phase 1 rules only):

```bash
teach validate --quick-checks slides/*.qmd
```

---

## Cheat Sheet

### Valid Code Block Tags

```markdown
```{r}           # R code (executable)
```python       # Python code
```bash         # Shell commands
```text         # Plain text / output
```sql          # SQL queries
```
```

### Valid Callout Types

```markdown
::: {.callout-note}        # Blue - general info
::: {.callout-tip}         # Green - helpful tips
::: {.callout-important}   # Yellow - key points
::: {.callout-warning}     # Orange - caution
::: {.callout-caution}     # Red - danger
```

### Heading Hierarchy Rules

```markdown
✅ # → ## → ### (increment by 1)
✅ ### → ## (reset is OK)
✅ ### → # (reset is OK)
❌ # → ### (skip is NOT OK)
❌ ## → #### (skip is NOT OK)
```

---

## Next Steps

1. **Integrate into Git:**
   - Add pre-commit hook (see [Integration Guide](../guides/LINT-GUIDE.md#pattern-1-pre-commit-validation))
   - Never commit files with lint issues

2. **Learn Advanced Usage:**
   - Read [Full Lint Guide](../guides/LINT-GUIDE.md)
   - Review [Quick Reference](../reference/REFCARD-LINT.md)

3. **Share with Team:**
   - Add lint documentation to your README
   - Educate collaborators on rules

---

## Troubleshooting

**Q: Lint doesn't find any issues**

A: Make sure you're using `--lint` flag:
```bash
teach validate --lint file.qmd  # Correct
teach validate file.qmd          # Wrong (uses default validation)
```

**Q: "Validator not found" error**

A: Copy validator to your project:
```bash
mkdir -p .teach/validators
# Copy from your flow-cli installation
```

**Q: Too slow on large projects**

A: Use `--quick-checks` for faster validation:
```bash
teach validate --quick-checks *.qmd
```

---

## Summary

You learned:
- ✅ How to run lint checks
- ✅ What the 4 Phase 1 rules detect
- ✅ How to fix common issues
- ✅ Basic integration patterns

**Time invested:** 10 minutes
**Value:** Catch structural issues before they cause problems

---

## See Also

- **Full Guide:** [LINT-GUIDE.md](../guides/LINT-GUIDE.md)
- **Quick Reference:** [REFCARD-LINT.md](../reference/REFCARD-LINT.md)
- **Workflow Integration:** [WORKFLOW-LINT.md](../workflows/WORKFLOW-LINT.md)
- **Migration Guide:** [LINT-MIGRATION-GUIDE.md](../guides/LINT-MIGRATION-GUIDE.md)

---

**Tutorial #27** | Created: 2026-01-31 | Updated: 2026-01-31
