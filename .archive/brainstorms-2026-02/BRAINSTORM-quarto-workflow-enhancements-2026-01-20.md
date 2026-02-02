# 🧠 BRAINSTORM: Quarto Workflow Enhancements for Teaching Sites

**Generated:** 2026-01-20
**Mode:** feature (deep)
**Duration:** 10 questions answered
**Context:** flow-cli teaching workflow enhancement (v4.6.0+)

---

## 📋 Executive Summary

Bring the proven STAT 545 Quarto workflow into flow-cli's `teach` dispatcher:

- **10-100x faster rendering** with automatic freeze caching
- **Zero broken commits** with git hooks that validate before commit
- **Interactive error recovery** ("Commit anyway?" prompt)
- **Parallel rendering** for fast validation of multiple files
- **Smart migration** for existing projects (auto-detect + upgrade)

**Impact:** Transform teaching workflow from "cross fingers and push" to "bulletproof development with instant feedback."

---

## 🎯 Quick Wins (< 30 min each)

### 1. ⚡ Create Hook Templates

**Why first:** Foundation for everything else. No dependencies.

**What:**

- Create `templates/hooks/pre-commit.template`
- Create `templates/hooks/pre-push.template`
- Use ZSH (not bash) - flow-cli is ZSH-native
- Include parallel rendering logic (zsh background jobs)
- Add interactive error prompt ("Commit anyway?")

**Files:**

```
flow-cli/
├── templates/
│   └── hooks/
│       ├── pre-commit.template    # NEW
│       ├── pre-push.template      # NEW
│       └── README.md              # NEW (template docs)
```

**Benefit:** Once templates exist, everything else is template copying + config reading.

---

### 2. ⚡ Extend teaching.yml Schema

**Why now:** Needed by teach init enhancements.

**What:**

- Add `quarto:` section (freeze_enabled, freeze_auto, validate_on_commit)
- Add `hooks:` section (auto_install, pre_commit_render, interactive_errors, parallel_render)
- Update schema validation

**Schema:**

```yaml
quarto:
  freeze_enabled: true
  freeze_auto: true
  validate_on_commit: true
  parallel_render: true # NEW from Q11

hooks:
  auto_install: true
  pre_commit_render: true
  pre_push_full_site: true
  interactive_errors: true
```

**Benefit:** Single source of truth for all Quarto/hook settings.

---

### 3. ⚡ Add \_quarto.yml.template

**Why easy:** Just a YAML file with freeze config.

**What:**

```yaml
project:
  type: website
  execute:
    freeze: auto # 🚀 10-100x faster renders
```

**Benefit:** Copy this during teach init, instant freeze support.

---

## 🔧 Medium Effort (1-2 hours each)

### 4. Implement teach hooks install

**Implementation:**

```zsh
# lib/dispatchers/teach-hooks-impl.zsh

_teach_hooks_install() {
    # 1. Check .git/ exists
    [[ -d .git ]] || { echo "Not a git repo"; return 1 }

    # 2. Read config
    local config="$HOME/.config/flow/teaching.yml"
    local pre_commit_render=$(yq '.hooks.pre_commit_render' "$config")

    # 3. Copy templates
    local template_dir="$FLOW_PLUGIN_ROOT/templates/hooks"
    cp "$template_dir/pre-commit.template" .git/hooks/pre-commit
    cp "$template_dir/pre-push.template" .git/hooks/pre-push

    # 4. Customize hooks (inject config)
    sed -i '' "s/PRE_COMMIT_RENDER=.*/PRE_COMMIT_RENDER=$pre_commit_render/" .git/hooks/pre-commit

    # 5. Make executable
    chmod +x .git/hooks/{pre-commit,pre-push}

    # 6. Success message
    echo "✅ Git hooks installed"
}
```

**Edge Cases:**

- Existing hooks → Backup to `.backup` suffix, prompt to overwrite
- No .git/ → Error with suggestion: "Run git init first"
- Template not found → Error with path

---

### 5. Enhance teach init (Auto-detect + Upgrade)

**Logic:**

```zsh
_teach_init() {
    local project_name="$1"

    # Detect scenario
    if [[ -f _quarto.yml ]]; then
        # Existing project
        _teach_init_upgrade
    else
        # New project
        _teach_init_new "$project_name"
    fi
}

_teach_init_upgrade() {
    echo "Detected existing Quarto project"

    # Check for freeze
    local has_freeze=$(yq '.project.execute.freeze' _quarto.yml 2>/dev/null)

    if [[ "$has_freeze" == "null" ]]; then
        # Prompt for freeze
        read "response?Enable Quarto freeze caching? [Y/n] "
        if [[ "$response" =~ ^[Yy]?$ ]]; then
            yq -i '.project.execute.freeze = "auto"' _quarto.yml
            echo "✅ Added freeze: auto to _quarto.yml"
        fi
    fi

    # Check for hooks
    if [[ ! -x .git/hooks/pre-commit ]]; then
        read "response?Install git hooks for validation? [Y/n] "
        if [[ "$response" =~ ^[Yy]?$ ]]; then
            _teach_hooks_install
        fi
    fi

    echo "✅ Project upgraded"
}
```

**Prompts:**

- "Enable Quarto freeze caching? [Y/n]"
- "Install git hooks for validation? [Y/n]"

---

### 6. Implement teach cache (Interactive Menu)

**Menu UI:**

```zsh
_teach_cache() {
    local cache_dir="_freeze"

    # Show menu
    echo "┌─────────────────────────────────────────────┐"
    echo "│  teach cache - Manage Quarto Freeze Cache  │"
    echo "├─────────────────────────────────────────────┤"

    if [[ -d "$cache_dir" ]]; then
        local size=$(du -sh "$cache_dir" | cut -f1)
        local count=$(find "$cache_dir" -type f | wc -l | tr -d ' ')
        local mtime=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$cache_dir")

        echo "│  Cache: $cache_dir"
        echo "│  Size: $size ($count files)"
        echo "│  Last updated: $mtime"
    else
        echo "│  No cache found"
    fi

    echo "│"
    echo "│  [1] Refresh cache"
    echo "│  [2] Clear cache"
    echo "│  [3] Show stats"
    echo "│  [4] Show info"
    echo "│  [q] Quit"
    echo "│"
    echo "└─────────────────────────────────────────────┘"

    read "choice?Select [1-4, q]: "

    case "$choice" in
        1) _teach_cache_refresh ;;
        2) _teach_cache_clear ;;
        3) _teach_cache_stats ;;
        4) _teach_cache_info ;;
        q) return 0 ;;
        *) echo "Invalid choice" ;;
    esac
}
```

---

### 7. Implement teach validate (Staged Validation)

**Logic:**

```zsh
_teach_validate() {
    local target="$1"  # lectures, assignments, or empty (all)

    # Find changed .qmd files
    local changed_files=($(git diff --name-only --cached | grep '\.qmd$'))

    if [[ -n "$target" ]]; then
        # Filter by directory
        changed_files=(${(M)changed_files:#$target/*})
    fi

    if [[ ${#changed_files[@]} -eq 0 ]]; then
        echo "No changed .qmd files to validate"
        return 0
    fi

    echo "Validating ${#changed_files[@]} file(s)..."

    local failed=()

    for file in $changed_files; do
        echo "  Checking: $file"

        # Stage 1: Syntax check
        if ! quarto inspect "$file" &>/dev/null; then
            echo "    ✗ Syntax error"
            failed+=("$file")
            continue
        fi

        # Stage 2: Render (uses freeze cache)
        if ! quarto render "$file" --quiet; then
            echo "    ✗ Render failed"
            failed+=("$file")
            continue
        fi

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

## 🏗️ Long-term (Future phases)

### 8. Phase 2: Enhanced Validation (v4.7.0)

- `teach validate --full` - Full site render
- `teach validate lectures` - Directory filtering
- `teach validate --watch` - Auto-validate on file change
- Progress indicators for long renders

### 9. Phase 3: Documentation Generation (v4.7.0)

- Auto-update README.md with workflow section
- Update CLAUDE.md with freeze/hooks docs
- Generate troubleshooting guide

### 10. Phase 4: Teaching-Specific Helpers (v4.8.0)

- `teach preview week <N>` - Preview specific week's lecture
- `teach check --full` - Health check (dependencies, config, cache)
- `teach status` enhancements - Show freeze cache stats

---

## 🎨 Implementation Details

### Parallel Rendering (Pre-commit Hook)

**From User Answer Q11:** Use parallel rendering for speed.

**Implementation:**

```zsh
# In pre-commit.template

CHANGED_FILES=($(git diff --cached --name-only | grep '\.qmd$'))

if [[ ${#CHANGED_FILES[@]} -eq 0 ]]; then
    exit 0
fi

# Read config
PARALLEL_RENDER=$(yq '.hooks.parallel_render // true' ~/.config/flow/teaching.yml)

if [[ "$PARALLEL_RENDER" == "true" ]]; then
    # Parallel rendering
    echo "Rendering ${#CHANGED_FILES[@]} files (parallel)..."

    local pids=()
    local failed=()

    for file in $CHANGED_FILES; do
        # Run in background
        (
            if ! quarto render "$file" --quiet; then
                echo "$file" >> /tmp/teach-hook-failures.txt
            fi
        ) &
        pids+=($!)
    done

    # Wait for all renders
    for pid in $pids; do
        wait $pid
    done

    # Check for failures
    if [[ -f /tmp/teach-hook-failures.txt ]]; then
        failed=($(cat /tmp/teach-hook-failures.txt))
        rm /tmp/teach-hook-failures.txt
    fi
else
    # Sequential rendering
    for file in $CHANGED_FILES; do
        if ! quarto render "$file" --quiet; then
            failed+=("$file")
        fi
    done
fi

# Interactive error handling
if [[ ${#failed[@]} -gt 0 ]]; then
    echo ""
    echo "❌ Render failed for ${#failed[@]} file(s)"
    read "response?Commit anyway? [y/N] "

    if [[ "$response" =~ ^[Yy]$ ]]; then
        exit 0
    else
        exit 1
    fi
fi

exit 0
```

**Why Parallel:**

- 3 files @ 5s each = 15s sequential vs 5s parallel (3x speedup)
- 10 files @ 5s each = 50s sequential vs 5s parallel (10x speedup)

**Edge Case:** If 1 file fails, we still render others in parallel. Show all failures at once.

---

### teach deploy Integration (Optional Validation)

**From User Answer Q12:** User choice via `--validate` flag.

**Implementation:**

```zsh
_teach_deploy() {
    local validate_flag="$1"

    # Optional validation
    if [[ "$validate_flag" == "--validate" ]]; then
        echo "Running teach validate before deploy..."
        if ! teach validate; then
            echo "❌ Validation failed. Fix errors before deploying."
            return 1
        fi
        echo "✅ Validation passed"
    fi

    # Existing deploy logic
    gh pr create --base production --head draft
}
```

**Usage:**

```bash
teach deploy              # No validation (rely on pre-push hook)
teach deploy --validate   # Explicit validation before PR
```

**Rationale:** Pre-push hook already validates, so deploy doesn't need to. But offer opt-in for extra safety.

---

### Error Output Design (Rich Context)

**Goal:** Show line numbers, context, and actionable next steps.

**Example:**

```
Validating changed Quarto files...
  Checking: syllabus/syllabus-final.qmd
    ✗ Render failed

════════════════════════════════════════════════════════
 Error in syllabus/syllabus-final.qmd (line 127)
════════════════════════════════════════════════════════

  Error: object 'exam_data' not found

  Context:
    125 | ## Exam Schedule
    126 |
  > 127 | table(exam_data)
        |       ^~~~~~~~~
    128 |
    129 | ### Midterm

════════════════════════════════════════════════════════
 Suggestions
════════════════════════════════════════════════════════

  • Check if exam_data is loaded in setup chunk
  • Verify spelling: exam_data vs examData
  • Run teach cache clear if cache is stale

════════════════════════════════════════════════════════
 Options
════════════════════════════════════════════════════════

  1. Fix error and retry commit
  2. Bypass validation: git commit --no-verify

Commit anyway? [y/N]
```

**Parsing Quarto Errors:**

```zsh
# Extract line number from Quarto error output
# Quarto format: "Error in file.qmd:127:5"

parse_quarto_error() {
    local error_output="$1"
    local file="$2"

    # Extract line number
    local line=$(echo "$error_output" | grep -oE "$file:[0-9]+" | cut -d: -f2)

    # Extract error message
    local message=$(echo "$error_output" | grep "Error:" | head -1)

    # Show context (3 lines before/after)
    show_context "$file" "$line"
}

show_context() {
    local file="$1"
    local line="$2"
    local before=3
    local after=3

    local start=$((line - before))
    local end=$((line + after))

    [[ $start -lt 1 ]] && start=1

    sed -n "${start},${end}p" "$file" | \
    awk -v line="$line" '{
        if (NR == line - start + 1) {
            printf "  > %3d | %s\n", NR + start - 1, $0
        } else {
            printf "    %3d | %s\n", NR + start - 1, $0
        }
    }'
}
```

---

## 📊 Architecture Decisions

### 1. Templates in Repo (Not Generated)

**Decision:** Store hook templates in `templates/hooks/`, copy + customize on install.

**Why:**

- ✅ Easy to version control
- ✅ Users can inspect/modify templates before installing
- ✅ Supports customization (edit installed hooks directly)

**Alternative Rejected:** Generate hooks dynamically from ZSH functions.

- ❌ Harder to debug
- ❌ Less transparent to users

---

### 2. Extend teaching.yml (Not New teach.conf)

**Decision:** Add `quarto:` and `hooks:` sections to existing `~/.config/flow/teaching.yml`.

**Why:**

- ✅ Single config file (ADHD-friendly)
- ✅ YAML is structured, supports nesting
- ✅ Already have schema validation

**Alternative Rejected:** Create `teach.conf` with bash variables.

- ❌ Two config files to manage
- ❌ Bash config is less structured

---

### 3. Interactive Error Handling (Not Strict Block)

**Decision:** Pre-commit hook shows errors, then asks "Commit anyway? [y/N]"

**Why:**

- ✅ Forgiving (ADHD-friendly)
- ✅ Allows WIP commits when needed
- ✅ Always have `--no-verify` escape hatch

**Alternative Rejected:** Strict blocking (fail on any error).

- ❌ Frustrating for WIP commits
- ❌ Forces `--no-verify` more often

---

### 4. Staged Validation (inspect → render)

**Decision:** `teach validate` runs `quarto inspect` first, then `quarto render`.

**Why:**

- ✅ Fast feedback (inspect is instant)
- ✅ Catches syntax errors before expensive render
- ✅ Users can skip render with `--inspect-only` flag

**Alternative Rejected:** Always run full render.

- ❌ Slow for simple syntax errors
- ❌ Wastes time on unrendereable files

---

### 5. Parallel Rendering (Background Jobs)

**Decision:** Use ZSH background jobs (`&`) for parallel rendering.

**Why:**

- ✅ 3-10x speedup for multiple files
- ✅ Native ZSH (no external dependencies)
- ✅ Simple implementation

**Alternative Rejected:** GNU Parallel or xargs.

- ❌ External dependency
- ❌ Overkill for this use case

**Edge Case:** If CPU-bound (4 cores, 8 files), parallel may not be faster. But freeze caching makes renders IO-bound (reading cache), so parallel is effective.

---

## 🧪 Testing Strategy

### Unit Tests

**test-teach-hooks-unit.zsh:**

```zsh
#!/usr/bin/env zsh

# Test 1: Hook installation
test_hooks_install() {
    local tmpdir=$(mktemp -d)
    cd "$tmpdir"
    git init

    # Run
    _teach_hooks_install

    # Assert
    [[ -x .git/hooks/pre-commit ]] || fail "pre-commit not executable"
    [[ -x .git/hooks/pre-push ]] || fail "pre-push not executable"

    cd -
    rm -rf "$tmpdir"
}

# Test 2: Existing hooks backup
test_hooks_backup() {
    local tmpdir=$(mktemp -d)
    cd "$tmpdir"
    git init

    # Create existing hook
    echo "#!/bin/sh" > .git/hooks/pre-commit
    chmod +x .git/hooks/pre-commit

    # Run (should backup)
    _teach_hooks_install

    # Assert
    [[ -f .git/hooks/pre-commit.backup ]] || fail "backup not created"

    cd -
    rm -rf "$tmpdir"
}

# Run tests
test_hooks_install
test_hooks_backup
```

---

### Integration Tests

**test-teach-quarto-workflow-integration.zsh:**

```zsh
#!/usr/bin/env zsh

# Full workflow test
test_full_workflow() {
    local fixture="tests/fixtures/teaching-quarto-test"

    # 1. teach init (with freeze + hooks)
    cd "$fixture"
    teach init test-course --yes  # Auto-accept prompts

    # 2. Verify freeze config
    grep "freeze: auto" _quarto.yml || fail "freeze not enabled"

    # 3. Verify hooks installed
    [[ -x .git/hooks/pre-commit ]] || fail "pre-commit not installed"

    # 4. Edit a file
    echo "\n## New section" >> lectures/lecture-01.qmd

    # 5. Stage file
    git add lectures/lecture-01.qmd

    # 6. Commit (should trigger hook)
    git commit -m "test commit" || fail "commit failed"

    # 7. Verify render happened (check _site/)
    [[ -f _site/lectures/lecture-01.html ]] || fail "render didn't happen"

    cd -
}

test_full_workflow
```

---

### Mock Project Fixture

**tests/fixtures/teaching-quarto-test/:**

```
teaching-quarto-test/
├── _quarto.yml          # Basic Quarto config (no freeze yet)
├── lectures/
│   ├── lecture-01.qmd   # Simple R code
│   └── lecture-02.qmd   # Has intentional error
├── assignments/
│   └── hw-01.qmd
└── .git/                # Initialized git repo
```

**lectures/lecture-01.qmd:**

````yaml
---
title: "Lecture 1"
---

## Introduction

```{r}
x <- 1:10
mean(x)
````

````

**lectures/lecture-02.qmd (error for testing):**
```yaml
---
title: "Lecture 2"
---

## Error Test

```{r}
undefined_variable  # This should fail
````

````

---

## 📚 Documentation Plan

### Comprehensive Guide (Written First)

**docs/guides/TEACHING-QUARTO-WORKFLOW.md** (10,000+ lines):

1. **Overview**
   - What is Quarto freeze caching?
   - Why git hooks for teaching?
   - Performance benefits (10-100x speedup)

2. **Getting Started**
   - New project: `teach init my-course`
   - Existing project: upgrade path
   - Configuration options

3. **Workflow**
   - Local development: `quarto preview`
   - Before committing: `teach validate`
   - Commit: automatic validation
   - Deploy: `teach deploy`

4. **Git Hooks Deep Dive**
   - What happens on `git commit`?
   - What happens on `git push`?
   - How to bypass: `--no-verify`
   - Customizing hooks

5. **Cache Management**
   - `teach cache` interactive menu
   - When to clear cache
   - Troubleshooting cache issues

6. **Error Handling**
   - Understanding error output
   - Common errors + solutions
   - "Commit anyway?" decision tree

7. **Advanced Usage**
   - Parallel rendering configuration
   - Custom hook logic
   - Multi-author repos

8. **Troubleshooting**
   - Hooks not running
   - Renders taking too long
   - Cache corrupt
   - Merge conflicts

9. **Examples**
   - STAT 545 case study
   - Before/after comparison
   - Workflow diagrams

10. **Reference**
    - All commands
    - Config file reference
    - Environment variables

---

### Reference Updates

**docs/reference/TEACH-DISPATCHER-REFERENCE.md:**

Add new sections:
- `teach hooks install` - Full API reference
- `teach hooks uninstall` - Removal
- `teach validate` - Validation commands
- `teach cache` - Cache management

**README.md:**

Add quickstart:
```markdown
## Quarto Workflow (Teaching)

```bash
# New project with freeze + hooks
teach init my-course

# Validate before committing
teach validate

# Commit (auto-validates)
git commit -m "Add lecture 1"

# Manage cache
teach cache
````

````

---

## 🚀 Recommended Path

### Phase 1: Core Infrastructure (v4.6.0)

**Week 1:**
1. ✅ Create hook templates (Task 1) - 30 min
2. ✅ Extend teaching.yml schema (Task 2) - 30 min
3. ✅ Add _quarto.yml.template (Task 3) - 15 min

**Week 2:**
4. ✅ Implement teach hooks install (Task 4) - 2 hours
5. ✅ Enhance teach init with auto-detect (Task 5) - 2 hours

**Week 3:**
6. ✅ Implement teach cache menu (Task 6) - 1 hour
7. ✅ Implement teach validate (Task 7) - 2 hours

**Week 4:**
8. ✅ Write comprehensive guide (10,000+ lines) - 4 hours
9. ✅ Create test suite (unit + integration) - 2 hours
10. ✅ Test on STAT 545 manually - 1 hour

**Total:** ~15 hours

---

### Phase 2: Validation Enhancements (v4.7.0)

**Later:**
- `teach validate --full` - Full site render
- `teach validate lectures` - Directory filtering
- Progress indicators
- Documentation sync (README + CLAUDE.md auto-update)

---

### Phase 3: Teaching Helpers (v4.8.0)

**Much later:**
- `teach preview week <N>`
- `teach check --full`
- `teach status` enhancements

---

## 🎯 Success Metrics

### Performance

| Metric | Baseline | Target | Achieved |
|--------|----------|--------|----------|
| First render | 5-10 min | 5-10 min | N/A |
| Subsequent render | 5-10 min | 5-30s | TBD |
| Pre-commit (1 file) | N/A | < 5s | TBD |
| Pre-commit (5 files) | N/A | < 15s | TBD |

### Reliability

| Metric | Target |
|--------|--------|
| Broken commits (pre-hooks) | 80% fewer |
| Broken commits (post-hooks) | 0% |
| Error messages with context | 100% |

### Adoption

| Metric | Target |
|--------|--------|
| New projects (auto-configured) | 100% |
| Existing projects (upgraded) | 50% in 3 months |
| Documentation coverage | 100% |

---

## 💡 Key Insights

### 1. Freeze Caching is the Foundation

**Without freeze:** Every render takes 5-10 minutes.
**With freeze:** Only changed files re-render (5-30s).

**This enables everything else:**
- Pre-commit hooks (5s per file is acceptable, 5min is not)
- teach validate (fast feedback loop)
- Parallel rendering (3-10x speedup on top of freeze)

### 2. Interactive Error Handling is ADHD-Friendly

**Strict blocking:**
- Error → Commit fails → Frustration → `--no-verify` every time

**Interactive prompt:**
- Error → Show context → Ask "Commit anyway?" → User decides
- Teaches better habits (users see errors, make informed choice)

### 3. Templates in Repo = Transparency

**Users can:**
- Inspect templates before installing
- Customize installed hooks directly
- Copy templates to other projects

**This builds trust** (not a black box).

### 4. Auto-detect Upgrade = Low Friction

**New projects:** `teach init` → Prompts for freeze + hooks → Done
**Existing projects:** `teach init` → Detects config → Prompts for missing features → Non-destructive

**No separate "upgrade" command needed.** Just run `teach init` again.

### 5. Parallel Rendering = Free Performance

**ZSH background jobs are free** (no dependencies).

**3-10x speedup for multiple files** with simple `&` operator.

**Edge case handled:** If one file fails, we still show all failures at once (not fail-fast).

---

## 🔗 Related Work

### Existing flow-cli Features

- ✅ `teach init` - Project scaffolding (enhance)
- ✅ `teach deploy` - GitHub Pages deployment (integrate)
- ✅ `teach status` - Semester tracking (enhance)
- ✅ `teach exam` - Scholar exam generation (no change)

### New Dependencies

- Quarto CLI >= 1.3 (already required)
- yq >= 4.0 (already in flow-cli)
- Git >= 2.0 (universal)

**No new npm/Python packages needed.**

---

## 📝 Next Steps

### Immediate (This Session)

1. ✅ Review this brainstorm
2. ✅ Review generated spec (docs/specs/SPEC-quarto-workflow-enhancements-2026-01-20.md)
3. ⏭️ Decide: Start implementation now or refine spec further?

### If Starting Implementation

1. Create feature branch: `feature/quarto-workflow-v4.6.0`
2. Start with Task 1: Hook templates (30 min)
3. Parallel track: Write comprehensive guide (Task 8)

### If Refining Spec

1. Ask more questions about edge cases
2. Review STAT 545 implementation for inspiration
3. Prototype hook template in scratch space

---

---

## 🎨 Advanced Features (From Deep Dive Q13-17)

### Quarto Profiles (dev vs production)

**From User Answer Q13:** Full profile support

**Problem:** Dev wants freeze caching (fast iteration), but production should always render fresh (avoid stale cache bugs).

**Solution:** Quarto profiles in _quarto.yml

**Implementation:**
```yaml
# _quarto.yml (generated by teach init)
project:
  type: website
  output-dir: _site

# Default profile (dev)
execute:
  freeze: auto  # Fast iteration

---
# Production profile
profile: production
execute:
  freeze: false  # Always fresh renders
````

**Usage:**

```bash
# Development (uses freeze)
quarto preview

# Production deploy (no freeze)
quarto render --profile production
```

**teach deploy Integration:**

```zsh
_teach_deploy() {
    # Always use production profile for deploy
    echo "Rendering with production profile (no freeze)..."
    quarto render --profile production

    # Create PR
    gh pr create --base production --head draft
}
```

**Config:**

```yaml
# ~/.config/flow/teaching.yml
quarto:
  profiles:
    dev:
      freeze: auto
    production:
      freeze: false
  default_profile: dev
```

**Why This Matters:**

- ✅ Dev: Fast iteration (5-30s) with freeze
- ✅ Production: Fresh render (5-10min) guarantees no cache bugs
- ✅ Best of both worlds

---

### R Package Dependency Management

**From User Answer Q14:** Auto-install prompt

**Problem:** Student renders lecture, gets "Error: package 'ggplot2' not found". Frustrating.

**Solution:** Detect missing packages in pre-commit hook, offer to install.

**Implementation:**

```zsh
# In pre-commit.template

check_r_dependencies() {
    local file="$1"

    # Extract required packages from .qmd
    local packages=($(grep -oP 'library\(\K[^)]+' "$file"))

    # Check if installed
    local missing=()
    for pkg in $packages; do
        if ! Rscript -e "library($pkg)" &>/dev/null; then
            missing+=("$pkg")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "⚠️  Missing R packages: ${missing[@]}"
        read "response?Install now? [Y/n] "

        if [[ "$response" =~ ^[Yy]?$ ]]; then
            for pkg in $missing; do
                echo "Installing $pkg..."
                Rscript -e "install.packages('$pkg', repos='https://cran.rstudio.com')"
            done
        else
            echo "Skipping install. Commit will likely fail."
        fi
    fi
}

# Run before rendering
for file in $CHANGED_FILES; do
    check_r_dependencies "$file"
    quarto render "$file"
done
```

**Why Auto-install:**

- ✅ Reduces friction for students/TAs
- ✅ Catches missing deps before render
- ✅ Optional (can decline and install manually)

**Edge Case:** If user has renv or similar, skip auto-install (detect `.Rprofile` or `renv.lock`).

---

### teach doctor (Health Check)

**From User Answer Q15:** Full doctor

**Problem:** User runs `teach init`, but something's broken. How to debug?

**Solution:** `teach doctor` validates entire setup.

**Implementation:**

```zsh
_teach_doctor() {
    echo "┌─────────────────────────────────────────────┐"
    echo "│  teach doctor - Health Check                │"
    echo "├─────────────────────────────────────────────┤"

    local issues=0

    # Check 1: Quarto installed
    if ! command -v quarto &>/dev/null; then
        echo "│  ✗ Quarto not found"
        echo "│    Install: https://quarto.org/docs/get-started/"
        ((issues++))
    else
        local version=$(quarto --version)
        echo "│  ✓ Quarto $version"
    fi

    # Check 2: Git installed
    if ! command -v git &>/dev/null; then
        echo "│  ✗ Git not found"
        ((issues++))
    else
        echo "│  ✓ Git $(git --version | awk '{print $3}')"
    fi

    # Check 3: In git repo
    if [[ ! -d .git ]]; then
        echo "│  ✗ Not a git repository"
        ((issues++))
    else
        echo "│  ✓ Git repository"
    fi

    # Check 4: Freeze config
    if [[ -f _quarto.yml ]]; then
        local freeze=$(yq '.project.execute.freeze' _quarto.yml 2>/dev/null)
        if [[ "$freeze" == "auto" ]]; then
            echo "│  ✓ Freeze caching enabled"
        else
            echo "│  ⚠  Freeze caching not enabled"
            echo "│    Run: teach init (upgrade)"
        fi
    else
        echo "│  ⚠  No _quarto.yml found"
    fi

    # Check 5: Hooks installed
    if [[ -x .git/hooks/pre-commit ]]; then
        echo "│  ✓ Pre-commit hook installed"
    else
        echo "│  ⚠  Pre-commit hook not installed"
        echo "│    Run: teach hooks install"
    fi

    if [[ -x .git/hooks/pre-push ]]; then
        echo "│  ✓ Pre-push hook installed"
    else
        echo "│  ⚠  Pre-push hook not installed"
    fi

    # Check 6: Cache health
    if [[ -d _freeze ]]; then
        local size=$(du -sh _freeze | cut -f1)
        local count=$(find _freeze -type f | wc -l | tr -d ' ')
        echo "│  ✓ Freeze cache: $size ($count files)"
    else
        echo "│  ℹ  No freeze cache yet (run quarto render)"
    fi

    echo "│"
    echo "├─────────────────────────────────────────────┤"

    if [[ $issues -eq 0 ]]; then
        echo "│  ✅ All checks passed"
    else
        echo "│  ❌ $issues issue(s) found"
    fi

    echo "└─────────────────────────────────────────────┘"

    return $issues
}
```

**Usage:**

```bash
teach doctor           # Full health check
teach doctor --fix     # Auto-fix issues (future)
```

**Why Useful:**

- ✅ Onboarding: New users can verify setup
- ✅ Debugging: When something breaks, run doctor first
- ✅ CI/CD: Run in GitHub Actions as pre-check

---

### \_freeze/ Commit Prevention

**From User Answer Q16:** Pre-commit prevention

**Problem:** User accidentally stages `_freeze/` (forgot to add to `.gitignore`), creates 500MB commit. Disaster.

**Solution:** Pre-commit hook blocks if `_freeze/` is staged.

**Implementation:**

```zsh
# In pre-commit.template (before rendering)

# Check if _freeze/ is staged
if git diff --cached --name-only | grep -q '^_freeze/'; then
    echo "❌ ERROR: _freeze/ directory is staged"
    echo ""
    echo "The freeze cache should never be committed to git."
    echo ""
    echo "Fix:"
    echo "  1. Unstage _freeze/:"
    echo "     git restore --staged _freeze/"
    echo ""
    echo "  2. Add to .gitignore:"
    echo "     echo '_freeze/' >> .gitignore"
    echo "     git add .gitignore"
    echo ""
    echo "  3. Retry commit"
    echo ""
    exit 1
fi
```

**Why Critical:**

- ✅ Prevents accidental 500MB commits
- ✅ Keeps repo size small
- ✅ Avoids merge conflicts on \_freeze/

**Edge Case:** If user REALLY wants to commit \_freeze/ (unusual), they can use `--no-verify`.

---

### Custom Validation Scripts (Extensibility)

**From User Answer Q17:** Config-based

**Problem:** Instructor wants to run custom checks (e.g., "ensure all lectures have learning objectives").

**Solution:** Allow custom validation commands in `teaching.yml`.

**Config:**

```yaml
# ~/.config/flow/teaching.yml
validation:
  commands:
    - name: 'Check learning objectives'
      script: './scripts/check-learning-objectives.sh'
      when: 'lectures/*.qmd'

    - name: 'Lint YAML frontmatter'
      script: 'yamllint --strict'
      when: '*.qmd'

    - name: 'Check image sizes'
      script: './scripts/check-image-sizes.sh'
      when: 'lectures/*.qmd'
```

**teach validate Integration:**

```zsh
_teach_validate() {
    # 1. Run Quarto validation (existing)
    # ...

    # 2. Run custom validators
    local config="$HOME/.config/flow/teaching.yml"
    local validators=($(yq '.validation.commands[].name' "$config"))

    for i in {1..${#validators[@]}}; do
        local name=$(yq ".validation.commands[$((i-1))].name" "$config")
        local script=$(yq ".validation.commands[$((i-1))].script" "$config")
        local when=$(yq ".validation.commands[$((i-1))].when" "$config")

        echo "Running custom validator: $name"

        # Find matching files
        local files=($(git diff --cached --name-only | grep "$when"))

        if [[ ${#files[@]} -gt 0 ]]; then
            if ! eval "$script ${files[@]}"; then
                echo "  ✗ $name failed"
                ((failed++))
            else
                echo "  ✓ $name passed"
            fi
        fi
    done
}
```

**Example Custom Validator:**

```bash
#!/bin/bash
# scripts/check-learning-objectives.sh

for file in "$@"; do
    if ! grep -q "^## Learning Objectives" "$file"; then
        echo "Missing 'Learning Objectives' section in $file"
        exit 1
    fi
done

exit 0
```

**Why Extensible:**

- ✅ Instructors have custom requirements
- ✅ Course-specific checks (accessibility, style guides)
- ✅ Easy to add without modifying flow-cli

**Phase:** v4.8.0 (not v4.6.0) - keep initial release simple.

---

## ✅ Completed in 15 questions (deep + 5 more)

**User answers integrated (Q1-12):**

1. Priority: Freeze + Hooks first ✅
2. Freeze config: Prompt on init ✅
3. Hook install: Auto-install with prompt ✅
4. Pre-commit: Render by default ✅
5. Hook storage: Templates in repo ✅
6. Validation: Staged (inspect → render) ✅
7. Config: Extend teaching.yml ✅
8. Error policy: Interactive ("Commit anyway?") ✅
9. Cache API: Interactive menu ✅
10. Testing: Mock project ✅
11. Performance: Parallel rendering ✅
12. Integration: teach deploy --validate (opt-in) ✅

**Advanced features (Q13-17):** 13. **Profiles: Full profile support (dev vs production) ✅** 14. **Dependencies: Auto-install prompt for missing R packages ✅** 15. **Health check: teach doctor (full validation) ✅** 16. **Freeze conflicts: Pre-commit prevention (block staged \_freeze/) ✅** 17. **Extensibility: Config-based custom validators ✅**

---

---

## 🎯 Final Implementation Details (Q18-21)

### Hook Conflict Resolution (Q18: Interactive Choice)

**Scenario:** User has existing custom pre-commit hook.

**Solution:** Show existing hook content, offer 3 options.

**Implementation:**

```zsh
_teach_hooks_install() {
    if [[ -f .git/hooks/pre-commit ]]; then
        echo "Existing pre-commit hook detected:"
        echo ""
        head -10 .git/hooks/pre-commit | sed 's/^/  /'
        echo "  ..."
        echo ""
        echo "Options:"
        echo "  [B]ackup existing hook and install flow-cli hook"
        echo "  [M]erge flow-cli logic into existing hook (advanced)"
        echo "  [A]bort installation"
        echo ""
        read "choice?Choose [B/M/A]: "

        case "$choice" in
            [Bb])
                local backup=".git/hooks/pre-commit.backup.$(date +%s)"
                mv .git/hooks/pre-commit "$backup"
                echo "✅ Backed up to: $backup"
                _install_hook_template
                ;;
            [Mm])
                echo "Manual merge required:"
                echo "  1. Copy flow-cli hook logic from: templates/hooks/pre-commit.template"
                echo "  2. Append to your existing: .git/hooks/pre-commit"
                echo "  3. Test with: git commit --dry-run"
                return 1
                ;;
            [Aa])
                echo "Installation aborted"
                return 1
                ;;
            *)
                echo "Invalid choice"
                return 1
                ;;
        esac
    else
        _install_hook_template
    fi
}
```

**Why Interactive:**

- Respects user's existing hooks
- Offers safe backup option
- Gives advanced users merge control
- Can't accidentally overwrite custom logic

---

### Quarto Project Templates (Q19: Template-Based)

**Scenario:** teach init in directory with no \_quarto.yml.

**Solution:** Offer project type templates.

**Implementation:**

```zsh
_teach_init_select_template() {
    echo "Select Quarto project type:"
    echo ""
    echo "  [1] Website (course site, documentation)"
    echo "  [2] Book (textbook, manual)"
    echo "  [3] Manuscript (research paper, report)"
    echo "  [4] Custom (I'll create _quarto.yml manually)"
    echo ""
    read "choice?Choose [1-4]: "

    case "$choice" in
        1)
            _create_quarto_yml_website
            ;;
        2)
            _create_quarto_yml_book
            ;;
        3)
            _create_quarto_yml_manuscript
            ;;
        4)
            echo "ℹ️  Create _quarto.yml manually, then run teach init again"
            return 1
            ;;
        *)
            echo "Invalid choice"
            return 1
            ;;
    esac
}

_create_quarto_yml_website() {
    cat > _quarto.yml << 'YAML'
project:
  type: website
  output-dir: _site
  execute:
    freeze: auto  # 10-100x faster renders

website:
  title: "My Course"
  navbar:
    left:
      - text: "Home"
        href: index.qmd
      - text: "Lectures"
        href: lectures/
      - text: "Assignments"
        href: assignments/

format:
  html:
    theme: cosmo
    css: styles.css
    toc: true
YAML

    echo "✅ Created _quarto.yml (website template)"
    echo "   Edit title and navigation as needed"
}
```

**Why Templates:**

- Common teaching use case: website (most frequent)
- Book for textbooks
- Manuscript for research-based courses
- Users can still customize after creation

---

### No Git Repo Handling (Q20: Warn + Continue)

**Scenario:** teach validate run in non-git directory.

**Solution:** Warn but continue, validate all .qmd files.

**Implementation:**

```zsh
_teach_validate() {
    local files_to_validate=()

    if [[ ! -d .git ]]; then
        echo "⚠️  WARNING: Not a git repository"
        echo "   Validating all .qmd files instead of changed files only"
        echo ""

        # Find all .qmd files
        files_to_validate=($(find . -name "*.qmd" -not -path "./_site/*" -not -path "./_freeze/*"))
    else
        # Git-aware: only changed files
        files_to_validate=($(git diff --name-only --cached | grep '\.qmd$'))

        if [[ ${#files_to_validate[@]} -eq 0 ]]; then
            # No staged files, check modified files
            files_to_validate=($(git diff --name-only | grep '\.qmd$'))
        fi
    fi

    if [[ ${#files_to_validate[@]} -eq 0 ]]; then
        echo "No .qmd files to validate"
        return 0
    fi

    echo "Validating ${#files_to_validate[@]} file(s)..."

    # Validate each file (same logic as before)
    # ...
}
```

**Why Warn + Continue:**

- Doesn't break teaching workflow (some users may not use git)
- Still provides value (validates all files)
- Warning educates users about git best practice
- Graceful degradation (ADHD-friendly)

---

### Command Naming (Q21: Just teach cache)

**Decision:** No `teach freeze` alias, keep single command `teach cache`.

**Rationale:**

- **teach cache** is clear (manages cache)
- **teach freeze** would be ambiguous (enable freeze? manage cache?)
- Single command = simpler mental model
- Interactive menu shows all options anyway

**Implementation:**

```zsh
teach() {
    case "$1" in
        cache)
            shift
            _teach_cache "$@"
            ;;
        # No freeze alias
        *)
            _teach_help
            ;;
    esac
}
```

**Help text:**

```
teach cache             Manage Quarto freeze cache (interactive menu)
teach cache refresh     Re-render all files (populates cache)
teach cache clear       Delete cache (destructive, asks for confirmation)
teach cache stats       Show cache size and file count
```

**Why Single Command:**

- Less confusion for users
- Easier to document
- Consistent with teach validate, teach doctor, teach deploy pattern
- "cache" is self-documenting (manages the cache)

---

## ✅ Completed in 21 questions (deep + 5 advanced + 4 implementation)

**User answers integrated (Q1-21):**

**Core (Q1-12):**

1. Priority: Freeze + Hooks first ✅
2. Freeze config: Prompt on init ✅
3. Hook install: Auto-install with prompt ✅
4. Pre-commit: Render by default ✅
5. Hook storage: Templates in repo ✅
6. Validation: Staged (inspect → render) ✅
7. Config: Extend teaching.yml ✅
8. Error policy: Interactive ("Commit anyway?") ✅
9. Cache API: Interactive menu ✅
10. Testing: Mock project ✅
11. Performance: Parallel rendering ✅
12. Integration: teach deploy --validate (opt-in) ✅

**Advanced (Q13-17):** 13. Profiles: Full profile support (dev vs production) ✅ 14. Dependencies: Auto-install prompt for R packages ✅ 15. Health check: teach doctor (full validation) ✅ 16. Freeze conflicts: Pre-commit prevention ✅ 17. Extensibility: Config-based custom validators ✅

**Implementation Details (Q18-21):** 18. **Hook conflicts: Interactive choice (Backup/Merge/Abort) ✅** 19. **Quarto init: Template-based (website/book/manuscript) ✅** 20. **No git repo: Warn + continue (validate all files) ✅** 21. **Command naming: Just teach cache (no freeze alias) ✅**

**Edge Cases & UX Polish (Q22-31):** 22. **Multi-format: Config-based (teaching.yml validate_formats) ✅** 23. **Pre-commit parallel: User config (parallel_pre_commit: true/false) ✅** 24. **Missing yq: Prompt to install (brew install yq) ✅** 25. **Cache scope: Separate commands (teach cache clear vs teach clean) ✅** 26. **Existing repo: Standard flow (create \_quarto.yml normally) ✅** 27. **Watch mode: Yes - Phase 2 (v4.7.0 feature) ✅** 28. **renv support: Warn user (detect renv.lock, suggest restore) ✅** 29. **Deploy validation: Both profiles (validate default, deploy production) ✅** 30. **Cache stats: Top 5 largest cached files ✅** 31. **Extensions: Validate extensions (check compatibility in teach doctor) ✅**

**Advanced Scenarios (Q32-39):** 32. **Worktrees: Install hooks in each worktree independently ✅** 33. **Parallel refresh: Auto-detect CPU cores for --jobs ✅** 34. **Python support: Unified validation (quarto handles both R & Python) ✅** 35. **Draft deploy: Phase 2 feature (v4.7.0) ✅** 36. **YAML validation: Use yq (progressive: yq → quarto inspect) ✅** 37. **Commit messages: Yes - prepare-commit-msg hook (append validation time) ✅** 38. **Port conflicts: Offer to kill preview server (detect .quarto-preview.pid) ✅** 39. **Backup system: Yes - teach backup snapshot (timestamped tar.gz) ✅**

**Daily Deployment Workflow (Q40-53):** 40. **Template repos: Phase 2 feature (v4.7.0) ✅** 41. **Binary files: Warn on size > 10MB (suggest git-lfs) ✅** 42. **Rollback: Yes - teach deploy --rollback (revert to previous) ✅** 43. **Data dependencies: Pre-render check (verify CSV/image files exist) ✅** 44. **Smart cache: No - full refresh only (simpler, safer) ✅** 45. **Merge commits: Prompt user (ask: 'Validate N files? [Y/n]') ✅** 46. **Deploy flow: Single command (not PR-based) ✅** 47. **Deploy cadence: Daily (aggressive content updates) ✅** 48. **Uncommitted changes: Auto-commit with prompt ✅** 49. **Partial deploy - Unchanged files: Dependency tracking (render dependents) ✅** 50. **Partial validation: Yes - full site validation (always) ✅** 51. **Change detection: Staged + committed (git diff origin/production...HEAD) ✅** 52. **Navigation: Smart detection (full if \_quarto.yml changed, else incremental) ✅** 53. **Cross-refs: Validate refs (check broken links before deploy) ✅**

**Hybrid Rendering & Index Management (Q54-69):** 54. **Render location: Hybrid (local syntax check, CI final build) ✅** 55. **Commit output: No - gitignore \_site/ (CI generates) ✅** 56. **Render scope: Render target + deps (dependency tracking) ✅** 57. **Dry run: Yes - teach deploy --dry-run (preview mode) ✅** 58. **Index update: Prompt user (Add to home_lectures.qmd? [Y/n]) ✅** 59. **New vs update: Both (git status + index parsing) ✅** 60. **Link format: Markdown list (simple bullets) ✅** 61. **Bulk updates: Batch mode flag (--batch, no prompts) ✅** 62. **Detect existing: Both filename + title (comprehensive) ✅** 63. **Update existing: Prompt user (Update link? [y/N]) ✅** 64. **Link order: Auto-sort (parse week numbers) ✅** 65. **Remove links: Yes - auto-detect (prompt on file delete) ✅** 66. **Sort edge cases: Custom sort keys (YAML sort_order) ✅** 67. **Link validation: Yes - warning only (not blocking) ✅** 68. **Incremental render: Always use incremental (freeze + incremental) ✅** 69. **Deploy history: Yes - git tags only (deploy-YYYY-MM-DD-HHMM) ✅**

**Final Polish & Production Readiness (Q70-84):** 70. **CI failure: Auto-rollback (detect failure, revert to previous tag) ✅** 71. **Scheduled deploy: No - manual timing (user controls) ✅** 72. **Concurrency: Not applicable (solo teaching workflow) ✅** 73. **Starter content: No - empty project (user creates content) ✅** 74. **Status integration: Full dashboard (cache, deploys, index health) ✅** 75. **Hook upgrades: Prompt user (detect version, ask to upgrade) ✅** 76. **Amend commits: Always validate (even for --amend) ✅** 77. **Watch mode: Phase 1 v4.6.0 (implement with conflict detection) ✅** 78. **Multi-environment: Solo teaching (no --env flag needed) ✅** 79. **Migration: Replace with prompt (show existing, ask to replace) ✅** 80. **Validation layers: Granular flags (--yaml, --syntax, --render) ✅** 81. **Auto-fix: Interactive install (prompt to install missing deps) ✅** 82. **Deploy summary: Git tag annotation (detailed changelog in tag) ✅** 83. **Slow renders: Progress indicator (spinner + elapsed time) ✅** 84. **Partial rollback: Interactive selection (choose which dirs to rollback) ✅**

---

**Files generated:**

- `BRAINSTORM-quarto-workflow-enhancements-2026-01-20.md` (this file)
- `docs/specs/SPEC-quarto-workflow-enhancements-2026-01-20.md` (comprehensive spec)
- `STAT-545-ANALYSIS-SUMMARY.md` (production insights)

**Ready for:** Implementation (v4.6.0 Phase 1) with complete implementation details
