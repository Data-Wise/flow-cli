# Quick Reference: teach validate --lint

**Version:** Phase 1 (v1.0.0)
**Purpose:** Structural lint checks for Quarto documents

---

## Commands

### Basic Usage

```bash
# Lint single file
teach validate --lint file.qmd

# Lint multiple files
teach validate --lint file1.qmd file2.qmd slides/*.qmd

# Auto-discover all .qmd files
teach validate --lint

# Run only Phase 1 quick checks
teach validate --quick-checks file.qmd
```

### Combined Flags

```bash
# Lint with quiet output
teach validate --lint --quiet file.qmd

# Quick checks on all files
teach validate --quick-checks

# Skip external validators
teach validate --lint --skip-external file.qmd
```

---

## Phase 1 Lint Rules

| Rule | Detects | Example |
|------|---------|---------|
| **LINT_CODE_LANG_TAG** | Bare code blocks without language tags | ` ``` ` (no language) |
| **LINT_DIV_BALANCE** | Unbalanced fenced divs | `::: {.note}` (no closing `:::`) |
| **LINT_CALLOUT_VALID** | Invalid callout types | `.callout-danger` (invalid) |
| **LINT_HEADING_HIERARCHY** | Skipped heading levels | `# h1` → `### h3` (skip h2) |

---

## Valid Callout Types

```markdown
::: {.callout-note}        ✅ Valid
::: {.callout-tip}         ✅ Valid
::: {.callout-important}   ✅ Valid
::: {.callout-warning}     ✅ Valid
::: {.callout-caution}     ✅ Valid

::: {.callout-info}        ❌ Invalid
::: {.callout-danger}      ❌ Invalid
```

---

## Code Block Language Tags

### ✅ Valid (with language tag)

```markdown
```{r}
x <- 1
```

```python
print("Hello")
```

```text
Plain text
```
```

### ❌ Invalid (bare blocks)

```markdown
```
no language tag
```
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All files passed |
| `1` | Lint warnings found |
| `2` | Validator crashed |

---

## Output Format

### Success

```
→ lint-shared (v1.0.0)
  ✓ All files passed

────────────────────────────────────────────────────
✓ Summary: All validators passed
  Files checked: 3
  Validators run: 1
  Time: 0s
```

### With Errors

```
→ lint-shared (v1.0.0)
  file.qmd:
    ✗ Line 7: LINT_CODE_LANG_TAG: Fenced code block without language tag
    ✗ Line 13: LINT_HEADING_HIERARCHY: Heading level skip (h1 -> h3)
  ✗ 2 errors found

────────────────────────────────────────────────────
✗ Summary: 2 errors found
  Files checked: 1
  Validators run: 1
  Time: 0s
```

---

## Pre-commit Integration

**File:** `.git/hooks/pre-commit`

```bash
# Lint checks (warn-only, never blocks commit)
if command -v teach &>/dev/null; then
    echo -e "  Running Quarto lint checks..."
    LINT_OUTPUT=$(teach validate --lint --quick-checks $STAGED_QMD 2>&1 || true)
    if [ -n "$LINT_OUTPUT" ]; then
        echo "$LINT_OUTPUT" | head -20
    fi
fi
```

**Note:** Lint runs automatically on commit but never blocks (warn-only mode).

---

## Performance

| Files | Typical Time |
|-------|--------------|
| 1 file | <0.1s |
| 5 files | <1s |
| 20 files | <3s |
| 100 files | <10s |

---

## Common Workflows

### Fix Bare Code Blocks

**Before:**
```markdown
```
x <- 1
```
```

**After:**
```markdown
```{r}
x <- 1
```
```

### Fix Unbalanced Divs

**Before:**
```markdown
::: {.callout-note}
Content
```

**After:**
```markdown
::: {.callout-note}
Content
:::
```

### Fix Skipped Headings

**Before:**
```markdown
# Section
### Subsection (skipped h2)
```

**After:**
```markdown
# Section
## Subsection
### Sub-subsection
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Validator not found: lint-shared" | Copy `.teach/validators/lint-shared.zsh` to project |
| No output | Use `--lint` flag explicitly |
| Too many warnings | Use `--quick-checks` for subset |
| Performance slow | Check file count with `--stats` |

---

## See Also

- **Full Guide:** `docs/guides/LINT-GUIDE.md`
- **Tutorial:** `docs/tutorials/27-lint-quickstart.md`
- **Test Coverage:** `tests/TEST-COVERAGE-LINT.md`
- **Validator API:** `.teach/validators/lint-shared.zsh`

---

**Last Updated:** 2026-01-31
**Feature:** teach validate --lint (Phase 1)
