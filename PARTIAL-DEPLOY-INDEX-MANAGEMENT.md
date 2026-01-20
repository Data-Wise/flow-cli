# Partial Deploy + Index Management Specification

**Generated:** 2026-01-20
**Questions Answered:** Q54-Q69 (16 questions on hybrid rendering + index management)
**Context:** Daily deployment with auto-updating lecture/assignment index pages

---

## Executive Summary

**teach deploy** now supports:

- ✅ Hybrid rendering (local syntax check, CI final build)
- ✅ Partial deploys with dependency tracking
- ✅ Auto-updating index pages (home_lectures.qmd, home_assignments.qmd)
- ✅ Smart link management (ADD/UPDATE/REMOVE)
- ✅ Auto-sorting with custom sort keys
- ✅ Dry-run mode (`--dry-run`)
- ✅ Batch mode (`--batch`)

---

## Hybrid Rendering Architecture (Q54-Q55)

### Decision: Local Syntax Check + CI Final Build

**Workflow:**

```bash
teach deploy lectures/week-05.qmd

# Local (fast):
# 1. Syntax validation (YAML, Quarto inspect)
# 2. Cross-reference check
# 3. Dependency tracking

# Remote (thorough):
# 1. Full site render (GitHub Actions)
# 2. Build _site/ directory
# 3. Deploy to GitHub Pages
```

**Why Hybrid:**

- **Local:** Fast feedback (1-5s), catch errors before push
- **CI:** Reproducible build, fresh environment, \_site/ not in git
- **Trade-off:** CI build takes 2-5min, but ensures correctness

**Implementation:**

```zsh
_teach_deploy() {
    local target="$1"

    # === LOCAL PRE-CHECK ===
    echo "→ Running local validation..."

    # 1. Syntax check (fast)
    for file in $changed_files; do
        # YAML frontmatter
        if ! grep -qE '^---$' "$file"; then
            error "Missing YAML frontmatter: $file"
        fi

        # Quarto syntax
        if ! quarto inspect "$file" &>/dev/null; then
            error "Quarto syntax error: $file"
        fi
    done

    # 2. Cross-reference validation
    _validate_cross_references "$changed_files"

    # 3. Dependency tracking
    _find_and_add_dependencies "$changed_files"

    # NO LOCAL RENDERING (CI handles this)

    # === COMMIT & PUSH ===
    git add .
    git commit -m "$msg"
    git push origin production

    # === CI BUILDS ===
    echo "→ GitHub Actions building site..."
    echo "   Monitor: https://github.com/$REPO/actions"
}
```

---

## Index Page Management

### Architecture Overview

**Index pages:**

- `home_lectures.qmd` - Lecture index with week-by-week links
- `home_assignments.qmd` - Assignment index
- Both are Markdown files with link lists

**Auto-update logic:**

```zsh
teach deploy lectures/week-05.qmd

# Steps:
# 1. Detect if week-05 is new or updated
# 2. Parse home_lectures.qmd for existing link
# 3. Prompt user: Add/Update/Skip
# 4. Auto-sort links by week number
# 5. Write updated home_lectures.qmd
# 6. Commit index update with lecture
```

---

## Link Detection (Q58 + Q62)

**Method:** Both filename + title

**Logic:**

```zsh
_link_exists() {
    local file="$1"              # lectures/week-05.qmd
    local index="$2"             # home_lectures.qmd

    local filename=$(basename "$file")  # week-05.qmd
    local title=$(_extract_title "$file")

    # Check 1: Filename match
    if grep -q "$filename" "$index"; then
        return 0  # Exists
    fi

    # Check 2: Title match
    if grep -q "$title" "$index"; then
        return 0  # Exists
    fi

    return 1  # Not found
}

_extract_title() {
    local file="$1"
    yq '.title' "$file" 2>/dev/null || echo "Untitled"
}
```

**Why both:**

- Filename changes (rename week-05 → week-05-anova)
- Title updates (refine lecture topic)
- Catches both scenarios

---

## ADD/UPDATE/REMOVE Operations

### Adding New Lecture (Q64)

**Scenario:** `lectures/week-05.qmd` is new (never deployed).

**Workflow:**

```bash
teach deploy lectures/week-05.qmd

# Output:
# → New lecture detected: week-05.qmd
# → Title: "Week 5: Factorial ANOVA"
# → Add to home_lectures.qmd? [Y/n] y
# → Auto-sorting by week number...
# ✅ Added to index (position 5)
```

**Implementation:**

```zsh
_add_lecture_to_index() {
    local file="$1"              # lectures/week-05.qmd
    local index="home_lectures.qmd"

    local title=$(_extract_title "$file")
    local link="- [$title]($file)"

    # Find insertion point (auto-sort)
    local week_num=$(echo "$file" | grep -oP 'week-\K[0-9]+')
    local insert_line=$(_find_insert_position "$index" "$week_num")

    # Insert link
    sed -i "${insert_line}i $link" "$index"

    echo "✅ Added to index: $title"
}
```

---

### Updating Existing Lecture (Q65)

**Scenario:** `lectures/week-05.qmd` exists, title changed.

**Old link:**

```markdown
- [Week 5: ANOVA](lectures/week-05.qmd)
```

**New title:** "Week 5: Factorial ANOVA and Contrasts"

**Workflow:**

```bash
teach deploy lectures/week-05.qmd

# Output:
# → Existing link found in home_lectures.qmd
# → Old: "Week 5: ANOVA"
# → New: "Week 5: Factorial ANOVA and Contrasts"
# → Update link? [y/N] y
# ✅ Link updated
```

**Implementation:**

```zsh
_update_lecture_link() {
    local file="$1"
    local index="home_lectures.qmd"

    local old_title=$(_extract_old_title "$index" "$file")
    local new_title=$(_extract_title "$file")

    if [[ "$old_title" != "$new_title" ]]; then
        echo "→ Old: \"$old_title\""
        echo "→ New: \"$new_title\""
        read "response?→ Update link? [y/N] "

        if [[ "$response" =~ ^[Yy]$ ]]; then
            # Replace title in markdown link
            sed -i "s|$old_title|$new_title|" "$index"
            echo "✅ Link updated"
        else
            echo "⏭️  Skipped update"
        fi
    else
        echo "→ Link unchanged (title same)"
    fi
}
```

---

### Removing Deprecated Lecture (Q67)

**Scenario:** `lectures/week-01.qmd` deleted (archived).

**Workflow:**

```bash
# User deletes file
rm lectures/week-01.qmd
git add lectures/week-01.qmd

teach deploy

# Output:
# → Deleted file detected: week-01.qmd
# → Link exists in home_lectures.qmd: "Week 1: Introduction"
# → Remove link? [Y/n] y
# ✅ Link removed from index
```

**Implementation:**

```zsh
_remove_deleted_lectures() {
    local index="home_lectures.qmd"

    # Find deleted .qmd files
    local deleted=($(git diff --cached --name-only --diff-filter=D | grep '\.qmd$'))

    for file in $deleted; do
        if _link_exists "$file" "$index"; then
            local title=$(_extract_old_title "$index" "$file")

            echo "→ Deleted file: $(basename $file)"
            echo "→ Link: \"$title\""
            read "response?→ Remove link? [Y/n] "

            if [[ "$response" =~ ^[Yy]?$ ]]; then
                # Remove line with link
                sed -i "/$file/d" "$index"
                echo "✅ Link removed"
            fi
        fi
    done
}
```

---

## Auto-Sorting (Q66)

**Pattern:** Extract week number, sort numerically.

**Input (unsorted):**

```markdown
- [Week 3: Regression](lectures/week-03.qmd)
- [Week 1: Introduction](lectures/week-01.qmd)
- [Week 2: t-tests](lectures/week-02.qmd)
```

**Output (sorted):**

```markdown
- [Week 1: Introduction](lectures/week-01.qmd)
- [Week 2: t-tests](lectures/week-02.qmd)
- [Week 3: Regression](lectures/week-03.qmd)
```

**Implementation:**

```zsh
_auto_sort_index() {
    local index="$1"

    # Extract links with week numbers
    local links=($(grep -E '- \[.*\]\(lectures/week-[0-9]+' "$index"))

    # Sort by week number
    local sorted=$(echo "${links[@]}" | sort -t- -k2 -n)

    # Rewrite links section
    # (Find start/end markers, replace content)
    sed -i '/^## Lectures$/,/^##/c\
## Lectures\n\n'"$sorted" "$index"
}
```

---

## Custom Sort Keys (Q68)

**Problem:** Non-standard lectures (guest, review, bonus).

**Solution:** YAML frontmatter with `sort_order`.

**Example:**

```yaml
---
title: 'Guest Lecture: Industry Applications'
sort_order: 5.5 # Between week 5 and 6
---
```

**Updated sorting:**

```zsh
_extract_sort_key() {
    local file="$1"

    # Try custom sort_order first
    local sort_key=$(yq '.sort_order' "$file" 2>/dev/null)

    if [[ -n "$sort_key" && "$sort_key" != "null" ]]; then
        echo "$sort_key"
        return
    fi

    # Fall back to week number
    local week_num=$(echo "$file" | grep -oP 'week-\K[0-9]+')
    if [[ -n "$week_num" ]]; then
        echo "$week_num"
        return
    fi

    # No sort key, append to end
    echo "999"
}

_auto_sort_index() {
    # Sort by sort_key (custom or week number)
    local sorted=$(for file in $files; do
        local key=$(_extract_sort_key "$file")
        echo "$key $file"
    done | sort -n | cut -d' ' -f2-)

    # Generate markdown links
    # ...
}
```

**Result:**

```markdown
## Lectures

- [Week 1: Introduction](lectures/week-01.qmd)
- [Week 2: t-tests](lectures/week-02.qmd)
- [Week 3: Regression](lectures/week-03.qmd)
- [Week 4: ANOVA](lectures/week-04.qmd)
- [Week 5: Factorial ANOVA](lectures/week-05.qmd)
- [Guest Lecture: Industry Applications](lectures/guest-industry.qmd) # sort_order: 5.5
- [Week 6: Mixed Models](lectures/week-06.qmd)
```

---

## Link Validation (Q69)

**Decision:** Warning only (not blocking).

**teach doctor check:**

```zsh
_teach_doctor() {
    # ... other checks ...

    # Check lecture index completeness
    local lectures=($(find lectures -name "*.qmd" | sort))
    local missing=()

    for lecture in $lectures; do
        if ! _link_exists "$lecture" "home_lectures.qmd"; then
            missing+=("$lecture")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "⚠️  Lectures not in index:"
        for lec in $missing; do
            echo "   • $lec"
        done
        echo "   Suggestion: Run teach deploy to auto-update index"
    else
        echo "✓ All lectures linked in index"
    fi
}
```

**Pre-deploy warning:**

```zsh
teach deploy lectures/week-05.qmd

# Output:
# ⚠️  WARNING: week-05 not in home_lectures.qmd
# → Add to index? [Y/n] n
# ⏭️  Skipped index update
# → Deploying anyway...
```

---

## Bulk Operations (Q61)

**Batch mode:** `teach deploy lectures/ --batch`

**Behavior:**

- No prompts for index updates
- Auto-add all new lectures
- Auto-update all changed titles
- Auto-sort at end

**Workflow:**

```bash
# Prepare 5 new lectures
touch lectures/week-{06..10}.qmd
# Edit each file...

# Bulk deploy
teach deploy lectures/week-{06..10}.qmd --batch

# Output:
# → Batch mode: Auto-updating index
# → Adding: week-06, week-07, week-08, week-09, week-10
# → Auto-sorting...
# ✅ Deployed 5 lectures, index updated
```

**Implementation:**

```zsh
_teach_deploy() {
    local batch_mode=false
    if [[ "$*" =~ --batch ]]; then
        batch_mode=true
    fi

    # Collect all new/updated lectures
    local to_add=()
    local to_update=()

    for file in $changed_files; do
        if _link_exists "$file" "home_lectures.qmd"; then
            to_update+=("$file")
        else
            to_add+=("$file")
        fi
    done

    if [[ "$batch_mode" == "true" ]]; then
        # Auto-update without prompts
        for file in $to_add; do
            _add_lecture_to_index "$file"
        done

        for file in $to_update; do
            _update_lecture_link "$file" --auto
        done

        _auto_sort_index "home_lectures.qmd"
    else
        # Interactive prompts
        for file in $to_add; do
            read "response?Add $file to index? [Y/n] "
            [[ "$response" =~ ^[Yy]?$ ]] && _add_lecture_to_index "$file"
        done

        for file in $to_update; do
            _update_lecture_link "$file"
        done
    fi
}
```

---

## Dry-Run Mode (Q57)

**Command:** `teach deploy --dry-run`

**Output:**

```bash
teach deploy lectures/week-05.qmd --dry-run

# Output:
# ════════════════════════════════════════
#  DRY RUN: teach deploy
# ════════════════════════════════════════
#
# Files to deploy:
#   • lectures/week-05.qmd (new)
#
# Dependencies:
#   • assignments/hw-05.qmd (cross-reference)
#
# Index updates:
#   • home_lectures.qmd: ADD "Week 5: Factorial ANOVA"
#   • home_assignments.qmd: ADD "Homework 5"
#
# Actions:
#   1. Commit 3 files
#   2. Update 2 index pages
#   3. Push to production
#   4. CI build & deploy
#
# Estimated time: 45s local, 2m CI
#
# ════════════════════════════════════════
#  No changes made (dry run)
# ════════════════════════════════════════
#
# To deploy for real:
#   teach deploy lectures/week-05.qmd
```

---

## Incremental Rendering (Q60)

**Decision:** Always use `execute: incremental: true` in \_quarto.yml.

**Why:**

- Faster CI builds (only changed files)
- Complements freeze (freeze = R code cache, incremental = file cache)
- No downside for solo teaching repos

**Config:**

```yaml
# _quarto.yml
project:
  type: website
  execute:
    freeze: auto # Cache R code execution
    incremental: true # Cache file rendering
```

**Behavior:**

```bash
# First CI build (no cache)
quarto render  # 5-10 minutes (all files)

# Second CI build (week-05 changed)
quarto render  # 30-60s (only week-05 + index)

# Third CI build (_quarto.yml changed)
quarto render  # 5-10 minutes (full rebuild)
```

---

## Deployment History (Q61)

**Decision:** Git tags only (deploy-YYYY-MM-DD-HHMM).

**Auto-tagging:**

```zsh
_teach_deploy() {
    # ... merge, push ...

    # Auto-tag
    local tag="deploy-$(date +%Y-%m-%d-%H%M)"
    git tag -a "$tag" -m "Deployment: $(date)"
    git push origin "$tag"

    echo "✅ Deployed and tagged: $tag"
    echo "   View: git show $tag"
    echo "   Rollback: teach deploy --rollback $tag"
}
```

**View history:**

```bash
git tag -l "deploy-*" | tail -5
# Output:
#   deploy-2026-01-15-1430
#   deploy-2026-01-16-0915
#   deploy-2026-01-17-1200
#   deploy-2026-01-19-1430
#   deploy-2026-01-20-0945

git log --oneline --decorate | head -10
# Output:
#   a3b4c5d (tag: deploy-2026-01-20-0945, production) Add week 5 lecture
#   e6f7g8h (tag: deploy-2026-01-19-1430) Update syllabus
#   ...
```

---

## Complete Workflow Example

### Daily Workflow

```bash
# Morning: Prepare lecture
cd ~/projects/teaching/stat-545
quarto preview lectures/week-05_factorial-anova.qmd

# Edit, add examples, refine slides
# ...

# Noon: Deploy for students
teach deploy lectures/week-05_factorial-anova.qmd

# Interactive prompts:
# → New lecture detected: week-05_factorial-anova.qmd
# → Title: "Week 5: Factorial ANOVA and Contrasts"
# → Add to home_lectures.qmd? [Y/n] y
# → Auto-sorting by week number...
# ✅ Added to index (position 5)
#
# → Uncommitted changes detected
# → Commit message (or Enter for auto): _[Enter]_
# ✅ Committed: Update: 2026-01-20 (2 files)
#
# → Running local validation...
# ✓ YAML valid
# ✓ Syntax valid
# ✓ Cross-references valid
#
# → Pushing to production...
# → GitHub Actions building...
# ✅ Deployed in 38s (local), CI building now
#
# → Tagged: deploy-2026-01-20-1230
# → View: https://stat-545.example.com
```

---

## Summary

| Feature                   | Status | Implementation                       |
| ------------------------- | ------ | ------------------------------------ |
| **Hybrid rendering**      | ✅ Q54 | Local syntax check, CI final build   |
| **Index auto-update**     | ✅ Q58 | ADD/UPDATE/REMOVE with prompts       |
| **Link detection**        | ✅ Q62 | Both filename + title                |
| **Auto-sorting**          | ✅ Q66 | Parse week numbers, custom sort keys |
| **Dependency tracking**   | ✅ Q56 | Render target + cross-refs           |
| **Dry-run mode**          | ✅ Q57 | Preview changes before deploy        |
| **Batch mode**            | ✅ Q61 | No prompts, auto-update all          |
| **Link validation**       | ✅ Q69 | Warning in teach doctor              |
| **Incremental rendering** | ✅ Q60 | Always enabled in \_quarto.yml       |
| **Deployment tags**       | ✅ Q61 | Auto-tag: deploy-YYYY-MM-DD-HHMM     |

---

**Generated from:** Q54-Q69 (partial deployment + index management)
**Ready for:** Phase 1 implementation (v4.6.0)
