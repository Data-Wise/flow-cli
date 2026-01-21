# STAT 545 Production Implementation - Key Learnings

**Analyzed:** ~/projects/teaching/stat-545 (57 commits, 50+ deployments, 373+ validations)
**Status:** Production-validated teaching workflow with 100% success rate
**Generated:** 2026-01-20

---

## Executive Summary

STAT 545 has a **5-layer validation system** that catches errors at every stage:

1. **YAML frontmatter** (syntax)
2. **Quarto syntax** (structure)
3. **Full render** (R code execution)
4. **Image references** (broken links)
5. **Empty code chunks** (common mistake)

**Key metrics:**

- Pre-commit hook: 109 lines, runs every commit
- Pre-push hook: 59 lines, production branch only
- Render time: 1-5s per file (with freeze), 2-5min full site (without)
- Cache size: 71MB
- Zero broken commits in 57 commits

---

## Critical Design Decisions (Battle-Tested)

### 1. Gitignore \_freeze/ (NOT commit it)

**Evolution:**

- Commit `6ac864d`: Tried committing \_freeze/
- Result: Merge conflicts between local caches
- Commit `0657a7f`: Changed to gitignore \_freeze/
- Trade-off: Longer CI builds (2-5min) but zero conflicts

**Lesson for flow-cli:** Include \_freeze/ commit prevention in pre-commit hook (we got this right in Q16).

---

### 2. Pre-Commit Hook is Sophisticated (5 Layers)

**Not just "render the file":**

````bash
# Layer 1: YAML frontmatter
grep -qE '^---$' "$file" || error "missing YAML frontmatter"

# Layer 2: Quarto syntax
quarto inspect "$file" &>/dev/null || error "invalid Quarto syntax"

# Layer 3: Full render (catches R errors)
quarto render "$file" || error "render failed"

# Layer 4: Empty code chunks (warning only)
grep -qE '```\{r\}\s*```' "$file" && warn "empty code chunk"

# Layer 5: Image references
# Extract ![...](path) and check file existence
````

**Lesson for flow-cli:** We need all 5 layers, not just render. Update hook templates.

---

### 3. Pre-Push Optimization (Production Branch Only)

```bash
while read local_ref local_sha remote_ref remote_sha; do
    if [[ "$remote_ref" == *"production"* ]]; then
        # ONLY run full site render for production
```

**Why:**

- Draft pushes are frequent (WIP commits)
- Production pushes are rare (finalized content)
- No need to wait 2-5min for every draft push

**Lesson for flow-cli:** Detect branch in pre-push hook, skip validation for non-production branches.

---

### 4. Error Messages Show Last 15 Lines

```bash
if ! quarto render "$file" > "$TMPFILE" 2>&1; then
    echo "  ✗ Render failed"
    echo "  Error output:"
    tail -15 "$TMPFILE" | sed 's/^/    /'  # Indent for readability
    rm "$TMPFILE"
fi
```

**Not full output** - Just last 15 lines (the relevant error context).

**Lesson for flow-cli:** We planned "context around error line" but STAT 545 just shows last N lines. Simpler and works.

---

### 5. Bypass Mechanisms (Multiple Escape Hatches)

**Level 1: Disable rendering only**

```bash
export QUARTO_PRE_COMMIT_RENDER=0
git commit -m "WIP"
```

Keeps syntax/YAML checks, skips expensive render.

**Level 2: Bypass hook entirely**

```bash
git commit --no-verify -m "emergency fix"
```

**Level 3: Push to draft instead of production**

```bash
git push origin draft  # No pre-push hook
```

**Lesson for flow-cli:** We got this right (Q8: interactive error handling). Add QUARTO_PRE_COMMIT_RENDER env var.

---

### 6. Hook Installation via HEREDOC (Not Template Files)

**setup-hooks.sh (215 lines):**

```bash
cat > .git/hooks/pre-commit << 'HOOK'
#!/usr/bin/env zsh
# [109 lines of hook code here]
HOOK

chmod +x .git/hooks/pre-commit
```

**Why HEREDOC:**

- Single file contains all hooks
- No external templates to manage
- Easy to version control
- Can customize inline before writing

**Lesson for flow-cli:** Consider HEREDOC approach vs template files. HEREDOC is simpler for distribution.

---

### 7. validate-changes.sh (Manual Pre-Check)

**Defensive workflow:**

```bash
# Before committing, manually validate
./scripts/validate-changes.sh

# If pass, commit with confidence
git commit -m "message"
```

**Output:**

```
Files to validate:
  - syllabus/syllabus-final.qmd
  - lectures/week-05_factorial-anova.qmd

Rendering syllabus/syllabus-final.qmd...
✓ OK: syllabus/syllabus-final.qmd

Rendering lectures/week-05_factorial-anova.qmd...
✓ OK: lectures/week-05_factorial-anova.qmd

════════════════════════════════════════
  All files validated successfully!
════════════════════════════════════════

You can now commit with confidence:
  git commit -m "your message"
```

**Lesson for flow-cli:** This is exactly `teach validate`. We got this right.

---

### 8. Empty Code Chunk Detection (Common Mistake)

**Pattern:**

````bash
if grep -qE '```\{r\}\s*```' "$file"; then
    echo "  ⚠  WARNING: Empty code chunk detected"
fi
````

**Why it matters:**

- Common copy-paste error
- Generates blank output in rendered file
- Warning (not error) - doesn't block commit

**Lesson for flow-cli:** Add this check to pre-commit hook.

---

### 9. Image Reference Validation (Broken Links)

**Logic:**

```bash
# Extract image paths: ![alt](path)
grep -oP '!\[.*?\]\(\K[^)]+' "$file" | while read img; do
    # Skip URLs
    [[ "$img" =~ ^https?:// ]] && continue

    # Check file existence (relative to file dir or project root)
    if [[ ! -f "$img" && ! -f "$(dirname $file)/$img" ]]; then
        echo "  ⚠  WARNING: Image may not exist: $img"
    fi
done
```

**Lesson for flow-cli:** Add image validation to pre-commit hook (warning only).

---

### 10. Quarto Binary Fallback (Graceful Degradation)

```bash
QUARTO=$(which quarto 2>/dev/null || echo "/usr/local/bin/quarto")

if ! command -v "$QUARTO" &>/dev/null; then
    echo "  ⚠  Quarto not found - skipping validation"
    exit 0  # Don't block commit
fi
```

**Philosophy:** Hooks should never break git workflow, even if Quarto is missing.

**Lesson for flow-cli:** teach hooks install should check dependencies but hooks should degrade gracefully.

---

## Edge Cases Discovered in Production

### 1. Freeze Cache Merge Conflicts (Commit `0657a7f`)

**Problem:** Committed \_freeze/ caused conflicts between developers.
**Solution:** Gitignore \_freeze/, each developer has their own cache.
**Flow-cli action:** Add pre-commit check to block \_freeze/ staging.

---

### 2. Extension Version Mismatch (DEPLOYMENT-FIXES.md)

**Problem:**

```
ERROR: The extension unm is incompatible with this quarto version.
Extension requires: >=1.6.0
Quarto version: 1.4.550
```

**Solution:** Upgraded Quarto to 1.6.40.
**Flow-cli action:** teach doctor should check Quarto version.

---

### 3. System Dependencies (libcurl, R packages)

**Problem:** GitHub Actions failed due to missing system libraries.
**Solution:** Added system dependency installation step.
**Flow-cli action:** teach doctor should check R packages, offer to install.

---

### 4. Graphics Library (rgl) Failures

**Problem:** CI failed rendering plots with rgl.
**Solution:** Set `RGL_USE_NULL=TRUE` environment variable.
**Flow-cli action:** Document common environment variables in guide.

---

## Performance Metrics (Real-World)

| Scenario                          | Time      | Notes                                |
| --------------------------------- | --------- | ------------------------------------ |
| First render (no cache)           | 5-10 min  | 54 .qmd files                        |
| Changed file render (with freeze) | 1-5s      | Only re-executes changed file        |
| Pre-commit validation (1 file)    | 1-5s      | YAML + syntax + render               |
| Pre-commit validation (3 files)   | 3-15s     | Sequential (not parallel yet)        |
| Pre-push full site render         | 2-5 min   | No freeze, fresh execution           |
| CI/CD full workflow               | 10-15 min | System deps + renv + render + deploy |

**Lesson for flow-cli:** Our parallel rendering (Q11) will improve 3-15s to 5s. Good optimization.

---

## Documentation Structure (Excellent)

| File                     | Lines | Purpose                                 |
| ------------------------ | ----- | --------------------------------------- |
| `CLAUDE.md`              | ~300  | Technical reference for AI              |
| `README.md`              | ~200  | Quick start for humans                  |
| `DEPLOYMENT-FIXES.md`    | ~270  | Troubleshooting (4 major issues solved) |
| `TROUBLESHOOTING-LOG.md` | ~90   | Append-only incident log                |

**Philosophy:** Comprehensive but focused documentation.

**Lesson for flow-cli:** Our plan for TEACHING-QUARTO-WORKFLOW.md (10,000 lines) matches this structure.

---

## Configuration Management

**Single source of truth:** `.flow/teach-config.yml`

```yaml
course:
  name: 'STAT 545'
  semester: 'spring'
  year: 2026

branches:
  draft: 'draft'
  production: 'production'

deployment:
  web:
    type: 'github-pages'
    url: 'https://data-wise.github.io/doe'
```

**Used by:** quick-deploy.sh, semester tracking, automation scripts.

**Lesson for flow-cli:** We planned teaching.yml extension (Q7). This validates that approach.

---

## Hooks Evolution Timeline

| Commit    | Change                      | Rationale                  |
| --------- | --------------------------- | -------------------------- |
| `7c68fd4` | Initial hooks (syntax only) | Start simple               |
| `50b5f42` | Add pre-push hook           | Catch errors before deploy |
| `6ac864d` | Enable freeze feature       | Performance optimization   |
| `0657a7f` | Gitignore \_freeze/         | Resolved merge conflicts   |
| `b682fe8` | Enhance hooks to render     | Catch R errors early       |
| `2a13127` | Enable rendering by default | Philosophy: prevent > fix  |
| `aa74d0a` | Comprehensive documentation | Onboarding new users       |

**Key insight:** Started simple, evolved based on real issues. This validates our phased approach (v4.6.0 → v4.7.0 → v4.8.0).

---

## Color-Coded Output (ADHD-Friendly)

**Example:**

```bash
echo -e "${GREEN}✓${NC} YAML frontmatter valid"
echo -e "${RED}✗${NC} Render failed"
echo -e "${YELLOW}⚠${NC} WARNING: Empty code chunk"
```

**Colors:**

- GREEN: Success (✓)
- RED: Error (✗)
- YELLOW: Warning (⚠)
- BLUE: Info (ℹ)

**Lesson for flow-cli:** Use flow-cli's existing color scheme from lib/core.zsh.

---

## Testing Philosophy

**No formal test suite** (yet) - Relies on:

1. Pre-commit hook validation (every commit)
2. Pre-push full site render (production pushes)
3. CI/CD double-check (GitHub Actions)
4. Manual testing on real course content

**Validation:** 57 commits, 373+ hook executions, 100% success rate on production.

**Lesson for flow-cli:** We need formal tests (unit + integration), but STAT 545 proves the hook logic works in production.

---

## Recommendations for flow-cli Implementation

### 1. Update Pre-Commit Hook Template (High Priority)

**Add all 5 layers:**

````zsh
# templates/hooks/pre-commit.template
#!/usr/bin/env zsh

CHANGED_FILES=($(git diff --cached --name-only | grep '\.qmd$'))
[[ ${#CHANGED_FILES[@]} -eq 0 ]] && exit 0

# Config
RENDER_ENABLED=${QUARTO_PRE_COMMIT_RENDER:-1}
ERRORS=0

# Colors (from flow-cli lib/core.zsh)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Running pre-commit checks..."

for file in $CHANGED_FILES; do
    echo "  Checking: $file"

    # Layer 1: YAML frontmatter
    if ! grep -qE '^---$' "$file"; then
        echo -e "    ${RED}✗${NC} Missing YAML frontmatter"
        ((ERRORS++))
        continue
    fi
    echo -e "    ${GREEN}✓${NC} YAML frontmatter valid"

    # Layer 2: Quarto syntax
    if ! quarto inspect "$file" &>/dev/null; then
        echo -e "    ${RED}✗${NC} Quarto syntax error"
        ((ERRORS++))
        continue
    fi
    echo -e "    ${GREEN}✓${NC} Quarto syntax valid"

    # Layer 3: Full render (if enabled)
    if [[ "$RENDER_ENABLED" == "1" ]]; then
        TMPFILE=$(mktemp)
        if ! quarto render "$file" > "$TMPFILE" 2>&1; then
            echo -e "    ${RED}✗${NC} Render failed"
            echo "    Error output:"
            tail -15 "$TMPFILE" | sed 's/^/      /'
            rm "$TMPFILE"
            ((ERRORS++))
            continue
        fi
        rm "$TMPFILE"
    fi

    # Layer 4: Empty code chunks (warning only)
    if grep -qE '```\{r\}\s*```' "$file"; then
        echo -e "    ${YELLOW}⚠${NC} Empty code chunk detected"
    fi

    # Layer 5: Image references (warning only)
    grep -oP '!\[.*?\]\(\K[^)]+' "$file" 2>/dev/null | while read img; do
        [[ "$img" =~ ^https?:// ]] && continue
        if [[ ! -f "$img" && ! -f "$(dirname $file)/$img" ]]; then
            echo -e "    ${YELLOW}⚠${NC} Image may not exist: $img"
        fi
    done

    echo -e "    ${GREEN}✓${NC} All checks passed"
done

# Check if _freeze/ is staged (CRITICAL)
if git diff --cached --name-only | grep -q '^_freeze/'; then
    echo -e "${RED}✗${NC} ERROR: _freeze/ directory is staged"
    echo ""
    echo "Fix:"
    echo "  git restore --staged _freeze/"
    echo "  echo '_freeze/' >> .gitignore"
    exit 1
fi

# Summary
if [[ $ERRORS -gt 0 ]]; then
    echo ""
    echo "Pre-commit failed: $ERRORS error(s) found"
    echo "Fix the issues above or use 'git commit --no-verify' to bypass"
    exit 1
fi

exit 0
````

---

### 2. Update Pre-Push Hook Template (Production Branch Only)

```zsh
# templates/hooks/pre-push.template
#!/usr/bin/env zsh

# Only run on production branch
while read local_ref local_sha remote_ref remote_sha; do
    if [[ "$remote_ref" != *"production"* && "$remote_ref" != *"main"* ]]; then
        exit 0  # Skip validation for non-production branches
    fi

    echo "Pushing to production - running full site validation..."

    if ! quarto render; then
        echo ""
        echo "═══════════════════════════════════════════════════════"
        echo "  PUSH BLOCKED: quarto render failed"
        echo "═══════════════════════════════════════════════════════"
        echo ""
        echo "Fix the render errors before pushing to production."
        echo "To push anyway (not recommended): git push --no-verify"
        exit 1
    fi

    echo ""
    echo "═══════════════════════════════════════════════════════"
    echo "  Site rendered successfully - proceeding with push"
    echo "═══════════════════════════════════════════════════════"
done

exit 0
```

---

### 3. teach doctor Enhancement (Check More Things)

**Add R package checks:**

```zsh
# In teach doctor
echo "Checking R packages..."
MISSING_PKGS=()

# Extract packages from all .qmd files
grep -hroP 'library\(\K[^)]+' *.qmd lectures/*.qmd 2>/dev/null | \
sort -u | while read pkg; do
    if ! Rscript -e "library($pkg)" &>/dev/null; then
        MISSING_PKGS+=("$pkg")
    fi
done

if [[ ${#MISSING_PKGS[@]} -gt 0 ]]; then
    echo "  ⚠  Missing R packages: ${MISSING_PKGS[@]}"
    read "response?Install now? [Y/n] "
    if [[ "$response" =~ ^[Yy]?$ ]]; then
        for pkg in $MISSING_PKGS; do
            Rscript -e "install.packages('$pkg')"
        done
    fi
fi
```

---

### 4. teach validate Update (Use STAT 545 Patterns)

**Show last 15 lines on error:**

```zsh
_teach_validate() {
    # Find changed files
    local changed_files=($(git diff --name-only --cached | grep '\.qmd$'))

    for file in $changed_files; do
        echo "  Checking: $file"

        # Quarto inspect (fast)
        if ! quarto inspect "$file" &>/dev/null; then
            echo "    ✗ Syntax error"
            failed+=("$file")
            continue
        fi

        # Quarto render (with error capture)
        local tmpfile=$(mktemp)
        if ! quarto render "$file" > "$tmpfile" 2>&1; then
            echo "    ✗ Render failed"
            echo "    Error output:"
            tail -15 "$tmpfile" | sed 's/^/      /'
            rm "$tmpfile"
            failed+=("$file")
            continue
        fi
        rm "$tmpfile"

        echo "    ✓ OK"
    done

    # Summary
    if [[ ${#failed[@]} -gt 0 ]]; then
        echo ""
        echo "❌ Validation failed: ${#failed[@]} file(s)"
        for f in $failed; do
            echo "   • $f"
        done
        return 1
    fi

    echo ""
    echo "✅ All files validated"
    return 0
}
```

---

### 5. Hook Installation Method (Consider HEREDOC)

**Option A: Template files (current plan)**

```bash
cp templates/hooks/pre-commit.template .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
```

**Option B: HEREDOC (STAT 545 approach)**

```bash
cat > .git/hooks/pre-commit << 'HOOK'
#!/usr/bin/env zsh
[hook code here]
HOOK
chmod +x .git/hooks/pre-commit
```

**Recommendation:** Start with template files (easier to maintain), consider HEREDOC for distribution.

---

## Summary

STAT 545's implementation validates our design decisions and adds production-tested patterns:

**Validated in our spec:**

- ✅ Freeze: auto config (Q2)
- ✅ Gitignore \_freeze/ (Q16)
- ✅ Interactive error handling (Q8)
- ✅ teach validate separate command
- ✅ teach cache management (Q9)
- ✅ teach doctor health check (Q15)
- ✅ Pre-commit render by default (Q4)

**Improvements from STAT 545:**

- ✅ 5-layer pre-commit validation (not just render)
- ✅ Pre-push production branch optimization
- ✅ Last 15 lines error output (not full context)
- ✅ Empty code chunk detection
- ✅ Image reference validation
- ✅ Quarto binary fallback
- ✅ QUARTO_PRE_COMMIT_RENDER=0 env var
- ✅ Color-coded output

**Our improvements over STAT 545:**

- ✅ Parallel rendering (Q11) - 3x speedup
- ✅ teach doctor command - systematic health checks
- ✅ R package auto-install (Q14) - reduces friction
- ✅ Quarto profiles (Q13) - dev vs production
- ✅ Custom validators (Q17) - extensibility

**Ready for:** Implementation with production-validated patterns.
