# teach validate --lint Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a `--lint` flag to flow-cli's `teach validate` command that runs 4 Quarto-aware structural lint checks (Phase 1) via the existing custom validator plugin system.

**Architecture:** Add `--lint` flag parsing to `teach-validate()` in `commands/teach-validate.zsh` that dispatches to `_run_custom_validators()` with a `lint-` prefix filter. Create `lint-shared.zsh` in the `.teach/validators/` directory following the existing validator API (VALIDATOR_NAME/VERSION/DESCRIPTION + `_validate()` function). Add thin wrapper to stat-545's pre-commit hook.

**Tech Stack:** ZSH (flow-cli runtime), grep -E (ERE, macOS-compatible), existing custom-validators.zsh framework

**Branch:** `feature/teach-validate-lint` (from `dev`)

**Consumer project:** `~/projects/teaching/stat-545` (STAT 545 course site, 85+ .qmd files)

**Full spec:** `~/projects/teaching/stat-545/docs/specs/SPEC-quarto-lint-rules-2026-01-31.md`

---

## Context

### Problem

The STAT 545 course site has 85+ `.qmd` files across slides, lectures, and labs. The existing `teach validate` checks YAML and syntax, but doesn't catch:

1. **Structural issues** -- Unbalanced fenced divs (`:::`), bare code blocks without language tags, skipped heading levels
2. **Quarto-specific patterns** -- Misspelled callout types silently render as unstyled divs, broken cross-references render as literal `@fig-missing` text
3. **Content-type conventions** -- Quiz slides missing `{.correct}` answers, labs without practice problems, lectures without TL;DR boxes

markdownlint was evaluated and rejected (~60% false positive rate on Quarto syntax).

### Existing Infrastructure

The custom validator plugin system already exists in `lib/custom-validators.zsh`:

- Validators live in `.teach/validators/*.zsh`
- Discovery: `_discover_validators()` finds all `*.zsh` in that dir
- API: `VALIDATOR_NAME`, `VALIDATOR_VERSION`, `VALIDATOR_DESCRIPTION` globals + `_validate($file)` function
- Execution: `_execute_validator()` runs in isolated subshell
- Exit codes: 0=pass, 1=warnings found, 2=crash
- Orchestrator: `_run_custom_validators()` handles discovery, filtering, execution, summary

Three validators already exist as reference implementations:
- `check-citations.zsh` -- Validates Pandoc citations against .bib files
- `check-links.zsh` -- Validates internal/external links
- `check-formatting.zsh` -- Heading hierarchy + chunk options + quote consistency

### Key Files to Modify

| File | Action | Purpose |
|------|--------|---------|
| `commands/teach-validate.zsh:63-160` | MODIFY | Add `--lint` and `--quick-checks` flag parsing + dispatch |
| `commands/teach-validate.zsh:704+` | MODIFY | Add `--lint` to help text |
| `.teach/validators/lint-shared.zsh` | CREATE | 4 shared lint rules for all .qmd files |
| `tests/test-lint-shared-unit.zsh` | CREATE | Unit tests for all 4 rules |
| `tests/fixtures/lint/*.qmd` | CREATE | Test fixture files |
| `tests/test-lint-integration.zsh` | CREATE | Integration test against real stat-545 files |

### Key Files to Read First

Before implementing, read these to understand patterns:

1. `commands/teach-validate.zsh` -- Entry point, flag parsing (lines 51-160), dispatch logic
2. `lib/custom-validators.zsh` -- Validator API, discovery, execution (lines 63-80, 148-187, 272-331, 441-627)
3. `.teach/validators/check-formatting.zsh` -- Reference validator with heading hierarchy (already implemented there)
4. `tests/test-teach-validate-unit.zsh` -- Test patterns, helpers, mock file creation

---

## Task 1: Add `--lint` flag to `teach-validate.zsh`

**Files:**
- Modify: `commands/teach-validate.zsh:63-160`

**Step 1: Write the failing test**

Add to `tests/test-teach-validate-unit.zsh`:

```zsh
test_lint_flag_parsing() {
  test_start "teach validate --lint flag is recognized"

  local output
  output=$(teach-validate --lint --help 2>&1)
  local result=$?

  if assert_success $result "--lint should be recognized"; then
    if assert_contains "$output" "lint" "Help should mention lint"; then
      test_pass
    fi
  fi
}
```

**Step 2: Run test to verify it fails**

```bash
zsh tests/test-teach-validate-unit.zsh
```

Expected: FAIL -- `--lint` hits the `*) Unknown option` case at line 118

**Step 3: Add `--lint` flag parsing and dispatch**

In `commands/teach-validate.zsh`, add to the argument parser (after line 88, before `--validators`):

```zsh
            --lint)
                mode="lint"
                shift
                ;;
            --quick-checks)
                custom_validators="lint-shared"
                shift
                ;;
```

In the dispatch section (after line 146, the `custom` elif), add:

```zsh
    elif [[ "$mode" == "lint" ]]; then
        # Run lint validators (all lint-* validators in .teach/validators/)
        local args=(--project-root ".")
        if [[ -n "$custom_validators" ]]; then
            args+=(--validators "$custom_validators")
        else
            # Filter to only lint-* validators
            args+=(--validators "lint-shared,lint-slides,lint-lectures,lint-labs")
        fi
        [[ $skip_external -eq 1 ]] && args+=(--skip-external)
        _run_custom_validators "${args[@]}" "${files[@]}"
```

**Step 4: Run test to verify it passes**

**Step 5: Update help text**

In `_teach_validate_help()` (around line 704), add:

```
    --lint              Run Quarto-aware lint rules (.teach/validators/lint-*.zsh)
    --quick-checks      Run fast lint subset only (Phase 1 rules)
```

**Step 6: Commit**

```bash
git add commands/teach-validate.zsh tests/test-teach-validate-unit.zsh
git commit -m "feat(teach): add --lint flag to teach validate command"
```

---

## Task 2: Create `lint-shared.zsh` with all 4 Phase 1 rules

**Files:**
- Create: `.teach/validators/lint-shared.zsh`
- Create: `tests/test-lint-shared-unit.zsh`
- Create: `tests/fixtures/lint/bare-code-block.qmd`

**Step 1: Create test fixture `tests/fixtures/lint/bare-code-block.qmd`**

```markdown
---
title: "Test"
---

# Heading

```
bare code with no language
```

```{r}
#| label: good-chunk
x <- 1
```

```text
this is fine
```

```
another bare block
```
```

**Step 2: Write the test file `tests/test-lint-shared-unit.zsh`**

```zsh
#!/usr/bin/env zsh
# Test lint-shared.zsh validator

SCRIPT_DIR="${0:A:h}"
TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; RESET='\033[0m'
typeset -g TESTS_RUN=0 TESTS_PASSED=0 TESTS_FAILED=0

test_start() { echo -n "${CYAN}TEST: $1${RESET} ... "; TESTS_RUN=$((TESTS_RUN + 1)); }
test_pass() { echo "${GREEN}PASS${RESET}"; TESTS_PASSED=$((TESTS_PASSED + 1)); }
test_fail() { echo "${RED}FAIL${RESET}"; echo "  ${RED}-> $1${RESET}"; TESTS_FAILED=$((TESTS_FAILED + 1)); }
assert_contains() { [[ "$1" == *"$2"* ]] && return 0 || { test_fail "${3:-Should contain} '$2'"; return 1; }; }
assert_not_contains() { [[ "$1" != *"$2"* ]] && return 0 || { test_fail "${3:-Should not contain} '$2'"; return 1; }; }
assert_equals() { [[ "$1" == "$2" ]] && return 0 || { test_fail "${3:-Expected '$2', got '$1'}"; return 1; }; }

source "${SCRIPT_DIR}/../.teach/validators/lint-shared.zsh"

# ---- LINT_CODE_LANG_TAG ----

test_bare_code_block_detected() {
  test_start "LINT_CODE_LANG_TAG: detects bare code blocks"
  cp "${SCRIPT_DIR}/fixtures/lint/bare-code-block.qmd" "$TEST_DIR/test.qmd"
  local output; output=$(_validate "$TEST_DIR/test.qmd" 2>&1); local code=$?
  if [[ $code -ne 0 ]] && assert_contains "$output" "LINT_CODE_LANG_TAG"; then test_pass; fi
}

test_all_tagged_passes() {
  test_start "LINT_CODE_LANG_TAG: all-tagged file passes"
  cat > "$TEST_DIR/good.qmd" <<'FIXTURE'
---
title: "Good"
---

```{r}
x <- 1
```

```text
plain text
```
FIXTURE
  local output; output=$(_validate "$TEST_DIR/good.qmd" 2>&1); local code=$?
  if assert_equals "$code" "0" "Should pass"; then test_pass; fi
}

# Run
echo "=== lint-shared.zsh unit tests ==="
test_bare_code_block_detected
test_all_tagged_passes
echo ""; echo "Results: $TESTS_PASSED/$TESTS_RUN passed, $TESTS_FAILED failed"
[[ $TESTS_FAILED -eq 0 ]]
```

**Step 3: Run test -- should fail (validator doesn't exist)**

**Step 4: Create `.teach/validators/lint-shared.zsh`**

Full validator with all 4 rules:

- **LINT_CODE_LANG_TAG**: Fenced code blocks must have a language tag. Walks lines, tracks code block state, flags bare ` ``` ` openers.
- **LINT_DIV_BALANCE**: Fenced divs (`:::`) must be balanced. Tracks a div stack, reports unclosed openers and orphan closers.
- **LINT_CALLOUT_VALID**: Only recognized callout types (`note`, `tip`, `important`, `warning`, `caution`). Extracts `callout-*` from div openers and checks against allowlist.
- **LINT_HEADING_HIERARCHY**: No skipped heading levels. Tracks previous level, flags jumps > 1 deeper (resets are fine).

All rules skip YAML frontmatter and code block interiors. Each rule is a separate `_check_*()` function. The `_validate()` function runs all 4 and aggregates errors.

See the plan file at `~/.claude/plans/velvet-swimming-hippo.md` for the complete source code of `lint-shared.zsh`.

**Step 5: Run tests -- should pass**

**Step 6: Commit**

```bash
git add .teach/validators/lint-shared.zsh tests/test-lint-shared-unit.zsh tests/fixtures/lint/
git commit -m "feat(teach): add lint-shared.zsh with 4 Phase 1 lint rules"
```

---

## Task 3: Add comprehensive tests for remaining rules

**Files:**
- Modify: `tests/test-lint-shared-unit.zsh`
- Create: `tests/fixtures/lint/unbalanced-divs.qmd`
- Create: `tests/fixtures/lint/bad-callout.qmd`
- Create: `tests/fixtures/lint/skipped-headings.qmd`

Add test fixtures and test functions for LINT_DIV_BALANCE, LINT_CALLOUT_VALID, LINT_HEADING_HIERARCHY (both positive and negative cases), plus a test that non-.qmd files are skipped.

See the plan file for complete test code.

**Commit:**

```bash
git add tests/
git commit -m "test(teach): add comprehensive tests for all 4 Phase 1 lint rules"
```

---

## Task 4: Integration test on real stat-545 files

**Files:**
- Create: `tests/test-lint-integration.zsh`

Runs `lint-shared.zsh` against real `~/projects/teaching/stat-545/slides/week-02*.qmd` and `lectures/week-02*.qmd` files. Always passes (informational output only). Skips gracefully if stat-545 not present.

**Commit:**

```bash
git add tests/test-lint-integration.zsh
git commit -m "test(teach): add lint integration test against real stat-545 files"
```

---

## Task 5: Deploy to stat-545

**Files (in ~/projects/teaching/stat-545/):**
- Create: `.teach/validators/lint-shared.zsh` (copy from worktree)
- Modify: `.git/hooks/pre-commit` (add lint wrapper before final exit)

Pre-commit addition (warn-only, never blocks):

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

---

## Task 6: Write this plan doc in worktree

This document. Commit:

```bash
git add docs/plans/2026-01-31-teach-validate-lint.md
git commit -m "docs: add implementation plan for teach validate --lint"
```

---

## Verification Checklist

After all tasks:

1. `zsh tests/test-lint-shared-unit.zsh` -- all pass
2. `zsh tests/test-lint-integration.zsh` -- runs on real files
3. `teach validate --lint slides/week-02*.qmd` -- end-to-end in stat-545
4. `bash .git/hooks/pre-commit` -- includes lint warnings
5. `git log --oneline dev..HEAD` -- clean commit history

---

## Future Phases (Not in This Plan)

### Phase 2: Formatting Rules
- `LINT_LIST_SPACING` -- blank lines around lists
- `LINT_DISPLAY_EQ_SPACING` -- blank lines around `$$`
- `LINT_TABLE_FORMAT` -- pipe table structure
- `LINT_CODE_CHUNK_LABEL` -- R chunks have `#| label:`

### Phase 3: Content-Type Rules
- `lint-slides.zsh` (5 rules): echo explicit, quiz format, lab callout, title level, speaker notes
- `lint-lectures.zsh` (2 rules): TL;DR box, learning objectives
- `lint-labs.zsh` (2 rules): practice problems, setup chunk

### Phase 4: Polish
- Colored output, summary timing, `--fix` suggestions
- Update `docs/MARKDOWN-LINT-RULES.md`
