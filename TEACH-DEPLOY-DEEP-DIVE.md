# teach deploy - Deep Dive Specification

**Generated:** 2026-01-20
**Questions Answered:** Q45-Q52 (8 questions on deploy workflow)
**Context:** Daily deployment workflow with partial deploy support

---

## Executive Summary

**teach deploy** evolved from "weekly PR creation" to **"daily single-command deployment"** with **partial deploy support** and **cross-reference validation**.

**Key decisions:**

- ✅ Single-command deployment (not multi-step PR)
- ✅ Daily deployment cadence (aggressive content updates)
- ✅ Auto-commit uncommitted changes before deploy
- ✅ Partial deploys supported (lectures/, assignments/)
- ✅ Dependency tracking (re-render dependent files)
- ✅ Full pre-push validation (even for partial deploys)
- ✅ Git-based filtering (staged + committed changes)
- ✅ Smart navigation updates
- ✅ Cross-reference validation

---

## Deployment Workflow (Finalized)

### Daily Teaching Workflow

```bash
# Morning: Prepare today's lecture
cd ~/projects/teaching/stat-545
quarto preview lectures/week-05.qmd    # Live editing

# Edit lecture, add examples, update slides
# ...

# Noon: Deploy for students
teach deploy lectures/                  # Partial deploy
# Output:
# → Detecting changes in lectures/...
# → Found: week-05_factorial-anova.qmd (modified)
# → Dependency check: week-05 doesn't depend on other files
# → Committing changes...
# → Validating full site (pre-push)...
# → Deploying to production...
# ✅ Deployed in 45s (1 file rendered, full nav updated)

# Afternoon: Release assignment
teach deploy assignments/hw-05.qmd
# Output:
# → Uncommitted changes detected
# → Auto-committing: "Add homework 5"
# → Cross-reference check: hw-05 → lecture-05 ✓
# → Deploying...
# ✅ Deployed in 38s
```

### Weekly Workflow (Comprehensive)

```bash
# Friday: Prepare next week
teach deploy lectures/ assignments/
# Or just:
teach deploy   # Full site (all changes)

# Output:
# → Detecting all changes since last deploy...
# → Found: 3 lectures, 2 assignments, 1 syllabus update
# → Cross-reference validation...
# → Full site render (production profile)...
# ✅ Deployed in 2m 15s (full validation)
```

---

## teach deploy Specification

### Single-Command Deployment (Q46)

**Decision:** Single command, not multi-step PR.

**Rationale:**

- Daily deployment workflow needs speed
- PR creation adds friction (review, merge, wait)
- Teaching content is solo-authored (no PR review needed)

**Implementation:**

```zsh
_teach_deploy() {
    local target="$1"   # Optional: lectures/, assignments/, or empty (all)

    # 1. Handle uncommitted changes (Q48)
    if ! git diff-index --quiet HEAD --; then
        echo "Uncommitted changes detected"
        read "msg?Commit message (or Enter for auto): "
        [[ -z "$msg" ]] && msg="Update: $(date +%Y-%m-%d)"
        git add .
        git commit -m "$msg"
    fi

    # 2. Detect changes (Q50)
    local changed_files=()
    if [[ -n "$target" ]]; then
        # Partial deploy: target directory
        changed_files=($(git diff --name-only origin/production...HEAD | grep "^$target"))
    else
        # Full deploy: all changes
        changed_files=($(git diff --name-only origin/production...HEAD))
    fi

    # 3. Dependency tracking (Q48)
    local files_to_render=()
    for file in $changed_files; do
        files_to_render+=("$file")

        # Find files that depend on this one
        # (cross-references detected via grep)
        local dependents=($(grep -rl "$file" . | grep '\.qmd$'))
        files_to_render+=($dependents)
    done

    # Remove duplicates
    files_to_render=($(echo "${files_to_render[@]}" | tr ' ' '\n' | sort -u))

    echo "Files to render: ${#files_to_render[@]}"
    for f in $files_to_render; do
        echo "  • $f"
    done

    # 4. Cross-reference validation (Q52)
    _validate_cross_references "$files_to_render"

    # 5. Smart navigation (Q51)
    if git diff --name-only origin/production...HEAD | grep -q '_quarto.yml'; then
        echo "→ _quarto.yml changed, full navigation update"
        local render_all_nav=true
    else
        echo "→ Incremental navigation update"
        local render_all_nav=false
    fi

    # 6. Full validation (Q49)
    echo "→ Running full site validation (pre-push)..."
    if ! quarto render --profile production; then
        echo "❌ Validation failed"
        return 1
    fi

    # 7. Merge to production
    git checkout production
    git merge draft --no-edit

    # 8. Push
    git push origin production

    # 9. Return to draft
    git checkout draft

    echo "✅ Deployed successfully"
}
```

---

## Partial Deploy Logic

### Dependency Tracking (Q48)

**Problem:** Lecture 5 depends on shared R functions defined in lecture 1.

**Solution:** Parse cross-references, render dependent files.

**Detection:**

```zsh
_find_dependencies() {
    local file="$1"
    local deps=()

    # Extract sourced files
    # Example: source("../R/helpers.R")
    deps+=($(grep -oP 'source\("\K[^"]+' "$file"))

    # Extract cross-references
    # Example: See @sec-intro in Lecture 1
    deps+=($(grep -oP '@sec-\K[a-z0-9-]+' "$file"))

    # Find files defining these sections
    for sec in $deps; do
        local def_files=($(grep -l "^#.*{#$sec}" **/*.qmd))
        echo "${def_files[@]}"
    done
}
```

**Why:**

- Ensures consistency (if helper changed, re-render all users)
- Catches broken references early
- Safer than "render changed file only"

---

### Change Detection (Q50)

**Method:** Staged + committed changes since last production merge.

**Command:**

```bash
git diff --name-only origin/production...HEAD
```

**Why:**

- Captures all changes in draft branch
- Doesn't re-deploy unchanged files
- Works with partial deploys (filter by directory)

**Example:**

```bash
# Draft branch has:
# - lectures/week-05.qmd (modified yesterday)
# - assignments/hw-05.qmd (added today)
# - syllabus/syllabus.qmd (modified last week, already deployed)

# Production branch is 2 commits behind

git diff --name-only origin/production...HEAD
# Output:
#   lectures/week-05.qmd
#   assignments/hw-05.qmd
#   syllabus/syllabus.qmd

# Partial deploy: teach deploy lectures/
# Filters to: lectures/week-05.qmd only
```

---

### Smart Navigation (Q51)

**Logic:**

- If `_quarto.yml` changed → full navigation re-render
- Else → incremental navigation (just updated sections)

**Implementation:**

```zsh
_update_navigation() {
    local full_nav="$1"  # true/false

    if [[ "$full_nav" == "true" ]]; then
        # Re-render all HTML (nav is in header/footer)
        quarto render --profile production
    else
        # Incremental: update only deployed sections
        for file in $files_to_render; do
            quarto render "$file" --profile production
        done

        # Update index.html (nav links)
        quarto render index.qmd --profile production
    fi
}
```

**Why:**

- Faster (don't re-render entire site for one lecture)
- Safe (if nav structure changed, full render)
- Smart (detects \_quarto.yml changes automatically)

---

### Cross-Reference Validation (Q52)

**Problem:** Lecture 5 links to Assignment 2, but Assignment 2 not deployed yet.

**Solution:** Validate all cross-references before deploy.

**Detection:**

```zsh
_validate_cross_references() {
    local files=("$@")
    local broken_refs=()

    for file in $files; do
        # Extract cross-references: @sec-id, @fig-id, @tbl-id
        local refs=($(grep -oP '@(sec|fig|tbl|eq)-\K[a-z0-9-]+' "$file"))

        for ref in $refs; do
            # Find target file defining this reference
            local target=$(grep -l "^#.*{#$ref}" **/*.qmd)

            if [[ -z "$target" ]]; then
                broken_refs+=("$file → @$ref (not found)")
            elif [[ ! " ${files[@]} " =~ " ${target} " ]]; then
                # Target exists but not being deployed
                broken_refs+=("$file → @$ref (target: $target not deployed)")
            fi
        done
    done

    if [[ ${#broken_refs[@]} -gt 0 ]]; then
        echo "❌ Broken cross-references detected:"
        for ref in "${broken_refs[@]}"; do
            echo "   • $ref"
        done
        return 1
    fi

    echo "✓ Cross-references validated"
    return 0
}
```

**Why:**

- Prevents broken links in deployed site
- Catches incomplete partial deploys
- Forces user to deploy dependencies together

**Example:**

```bash
teach deploy lectures/week-05.qmd

# Output:
# ❌ Broken cross-references detected:
#    • lectures/week-05.qmd → @sec-anova-intro (target: lectures/week-04.qmd not deployed)
#
# Fix: Deploy both files together:
#   teach deploy lectures/week-04.qmd lectures/week-05.qmd
```

---

## Full Validation (Q49)

**Decision:** Always run full site validation, even for partial deploys.

**Rationale:**

- Safety first: ensure entire site still builds
- Catches global issues (broken nav, missing dependencies)
- Only 2-5 minutes (acceptable for daily deploy)

**Implementation:**

```zsh
_teach_deploy() {
    # ... detect changes, dependency tracking ...

    # ALWAYS full validation
    echo "→ Running full site validation (pre-push)..."
    if ! quarto render --profile production; then
        echo "❌ Full site validation failed"
        echo "   Fix errors, or use: teach deploy --skip-validation (dangerous)"
        return 1
    fi

    # ... merge, push ...
}
```

**Bypass (for emergencies):**

```bash
teach deploy --skip-validation
# Warning: Skipping full site validation
# Deploy anyway? [y/N]
```

---

## Auto-Commit (Q48)

**Decision:** Prompt for commit message, auto-commit if user hits Enter.

**Implementation:**

```zsh
if ! git diff-index --quiet HEAD --; then
    echo "Uncommitted changes detected:"
    git status --short | head -5
    echo ""
    read "msg?Commit message (or Enter for auto): "

    if [[ -z "$msg" ]]; then
        # Auto-generate message
        local changed_files=($(git diff --name-only | wc -l))
        msg="Update: $(date +%Y-%m-%d) ($changed_files files)"
    fi

    git add .
    git commit -m "$msg"
    echo "✅ Committed: $msg"
fi
```

**Example:**

```bash
teach deploy

# Output:
# Uncommitted changes detected:
#  M lectures/week-05.qmd
#  M assignments/hw-05.qmd
#
# Commit message (or Enter for auto): _[user hits Enter]_
# ✅ Committed: Update: 2026-01-20 (2 files)
```

---

## Daily Deployment Cadence (Q47)

**Recommended workflow:**

| Time          | Action            | Command                                |
| ------------- | ----------------- | -------------------------------------- |
| **Morning**   | Edit lecture      | `quarto preview lectures/week-05.qmd`  |
| **Noon**      | Deploy lecture    | `teach deploy lectures/`               |
| **Afternoon** | Edit assignment   | `quarto preview assignments/hw-05.qmd` |
| **Evening**   | Deploy assignment | `teach deploy assignments/`            |

**Why daily:**

- Students expect frequent updates
- Incremental content release (don't overwhelm)
- Early feedback (students find errors, instructor fixes quickly)
- Agile teaching (adapt based on student progress)

**Alternative: Weekly**

```bash
# Friday: Deploy full week
teach deploy
```

---

## Deployment Tags (Q46 - follow-up)

**Decision:** Auto-tag deployments for rollback support.

**Implementation:**

```zsh
_teach_deploy() {
    # ... merge, push ...

    # Auto-tag deployment
    local tag="deploy-$(date +%Y-%m-%d-%H%M)"
    git tag "$tag"
    git push origin "$tag"

    echo "✅ Deployed and tagged: $tag"
    echo "   Rollback: teach deploy --rollback $tag"
}
```

**Rollback (Q43):**

```bash
teach deploy --rollback deploy-2026-01-19-1430

# Output:
# → Rolling back production to: deploy-2026-01-19-1430
# → Resetting production branch to tag...
# → Force pushing to production...
# ✅ Rolled back successfully
# ⚠️  Warning: This force-pushed to production
```

---

## Summary of Decisions

| Question                  | Decision                    | Impact                   |
| ------------------------- | --------------------------- | ------------------------ |
| **Q46: Deploy flow**      | Single command              | Fast daily deploys       |
| **Q47: Cadence**          | Daily (aggressive)          | Frequent content updates |
| **Q48: Uncommitted**      | Auto-commit with prompt     | Friction-free workflow   |
| **Q48: Unchanged files**  | Dependency tracking         | Safe partial deploys     |
| **Q49: Validation**       | Full site (always)          | Safety guarantee         |
| **Q50: Change detection** | Staged + committed          | Accurate change tracking |
| **Q51: Navigation**       | Smart (detect \_quarto.yml) | Fast incremental updates |
| **Q52: Cross-refs**       | Validate before deploy      | No broken links          |

---

## Performance Estimates

| Scenario                  | Time   | Notes                                 |
| ------------------------- | ------ | ------------------------------------- |
| Partial deploy (1 file)   | 30-60s | Freeze cache + dependency check       |
| Partial deploy (3 files)  | 1-2min | Parallel render + full validation     |
| Full deploy (all changes) | 2-5min | Full site render (production profile) |
| Rollback                  | 10-20s | Git reset + force push (no render)    |

---

## Next Steps

1. Implement teach deploy with partial support
2. Add cross-reference validation logic
3. Add dependency tracking parser
4. Test with STAT 545 daily workflow
5. Document in TEACHING-QUARTO-WORKFLOW.md

---

**Generated from:** Q45-Q52 (teach deploy deep dive)
**Ready for:** Phase 1 implementation (v4.6.0)
