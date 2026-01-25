# Teaching Feature for flow-cli - Implementation Plan

**Feature:** Universal teaching workflow with STAT 545 as first implementation
**Status:** Planning - Awaiting Approval
**Created:** 2026-01-11
**Branch Strategy:** feature/teaching-workflow → dev → main

---

## Executive Summary

Implement a **comprehensive teaching workflow system** in flow-cli that:
1. **STAT 545 Migration** (Phase 1) - Full two-branch workflow with 3-tier automation
2. **Generic Framework** (Phase 2) - `teach init` command for future courses
3. **Integration Layer** - Bridges to scholar (AI generation) and nexus (tracking)

**Key Innovation:** Teaching-aware `work` command that auto-detects course context and enables course-specific shortcuts, safety guards, and status dashboards.

---

## User Requirements (From Brainstorm)

### Scope Decisions

- ✅ **STAT 545 first**, then generalize
- ✅ **flow-cli owns workflows** (pure ZSH, <10ms)
- ✅ **Per-course config** (`.flow/teach-config.yml`)
- ✅ **Full automation** (Scripts + flow-cli + GitHub Actions)

### Integration Decisions

- ✅ **Scholar**: Direct calls (flow-cli wraps scholar commands)
- ✅ **Nexus**: Parallel (nexus tracks, flow-cli operates independently)
- ✅ **Architecture**: Extend `work` command (project-aware, not new dispatcher)

### Workflow Priorities

1. Generate with scholar (`/teaching:quiz`)
2. Convert with examark (`md → qti.zip`)
3. Test in Canvas sandbox
4. Deploy to production via git

### Success Criteria

1. ⚡ **Deployment < 2 min** (typo → live)
2. 📝 **Quiz workflow < 30 min** (generate → Canvas)
3. 🛡️ **Branch safety** (workflow guard prevents production edits)
4. 🤖 **Full automation** (no manual git commands)

---

## Architecture Overview

### Layer Integration

```
┌─────────────────────────────────────────────────────────────┐
│  scholar (Claude Plugin)                                    │
│  /teaching:quiz, /teaching:exam, /teaching:assignment       │
│  → AI-powered content generation                            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  flow-cli (Pure ZSH) ← THIS IMPLEMENTATION                  │
│  ├── work stat-545 (teaching-aware session)                 │
│  ├── .flow/teach-config.yml (course configuration)          │
│  ├── scripts/ templates (deployment automation)             │
│  └── Workflow guard (prevents production edits)             │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  nexus CLI (Python) - Parallel Tracking                     │
│  nexus teach course list, nexus teach course show           │
│  → Optional rich tracking layer                             │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

```
1. Scholar generates quiz:
   /teaching:quiz "ANOVA concepts"
   → ~/projects/teaching/stat-545/quizzes/week08-quiz.md

2. flow-cli converts + deploys:
   work stat-545  (detects teaching project)
   s545q week08   (convert quiz to Canvas)
   s545d          (deploy to production)

3. Nexus tracks (optional):
   nexus teach course show stat-545
   → Shows course status, recent updates
```

---

## Phase 1: STAT 545 Migration

### 1.1: Teaching Project Detection

**File:** `lib/project-detector.zsh`

**Current State:**

```zsh
# Line 30-33: Already detects teaching projects
if [[ -f "$dir/syllabus.qmd" ]] || [[ -d "$dir/lectures" ]]; then
  echo "teaching"
  return 0
fi
```

**Enhancement Needed:**

```zsh
_detect_teaching_enhanced() {
  local dir="$1"

  # Enhanced detection
  if [[ -f "$dir/syllabus.qmd" ]] ||
     [[ -d "$dir/lectures" ]] ||
     [[ -f "$dir/.flow/teach-config.yml" ]]; then

    # Load course metadata
    if [[ -f "$dir/.flow/teach-config.yml" ]]; then
      _load_teaching_config "$dir"
    fi

    echo "teaching"
    return 0
  fi

  return 1
}
```

### 1.2: Teaching Configuration

**New File:** `.flow/teach-config.yml` (in STAT 545 repo)

```yaml
# STAT 545 Teaching Configuration
course:
  name: "STAT 545"
  full_name: "Design of Experiments"
  semester: "spring"
  year: 2026
  instructor: "DT"

branches:
  draft: "draft"
  production: "production"

scholar:
  quiz_command: "/teaching:quiz"
  exam_command: "/teaching:exam"
  assignment_command: "/teaching:assignment"

examark:
  enabled: true
  quiz_dir: "quizzes"
  exam_dir: "exams"
  output_format: "qti"

deployment:
  web:
    type: "github-pages"
    branch: "production"
    url: "https://data-wise.github.io/stat-545"
  lms:
    type: "canvas"
    upload_manual: true  # Phase 2: API integration

automation:
  quick_deploy: "scripts/quick-deploy.sh"
  batch_publish: "scripts/publish-batch.sh"
  quiz_convert: "scripts/quiz-to-qti.sh"
  semester_archive: "scripts/semester-archive.sh"

shortcuts:
  s545: "work stat-545"
  s545q: "quiz-to-qti.sh"
  s545d: "quick-deploy.sh"
  s545b: "publish-batch.sh"
```

### 1.3: Enhanced `work` Command

**File:** `commands/work.zsh`

**New Function:** `_work_teaching_session()`

```zsh
_work_teaching_session() {
  local project_dir="$1"
  local config_file="$project_dir/.flow/teach-config.yml"

  # 1. Load config
  if [[ ! -f "$config_file" ]]; then
    _flow_log_error "Teaching config not found: $config_file"
    return 1
  fi

  local course_name=$(yq '.course.name' "$config_file")
  local current_branch=$(git -C "$project_dir" branch --show-current)
  local production_branch=$(yq '.branches.production' "$config_file")

  # 2. Branch safety check
  if [[ "$current_branch" == "$production_branch" ]]; then
    echo ""
    _flow_log_warning "⚠️  You are on PRODUCTION branch: $production_branch"
    echo ""
    echo "  ${FLOW_COLORS[error]}Students see this branch!${FLOW_COLORS[reset]}"
    echo "  ${FLOW_COLORS[info]}Switch to draft branch for edits${FLOW_COLORS[reset]}"
    echo ""
    read -q "?Continue anyway? [y/N] " continue_anyway
    echo ""

    if [[ "$continue_anyway" != "y" ]]; then
      _flow_log_info "Switching to draft branch..."
      git -C "$project_dir" checkout $(yq '.branches.draft' "$config_file")
    fi
  fi

  # 3. Show course context
  _display_teaching_context "$project_dir" "$config_file"

  # 4. Load shortcuts
  _load_teaching_shortcuts "$config_file"

  # 5. Open editor
  cd "$project_dir"
  ${EDITOR:-code} .
}

_display_teaching_context() {
  local project_dir="$1"
  local config_file="$2"

  local course_name=$(yq '.course.name' "$config_file")
  local semester=$(yq '.course.semester' "$config_file")
  local year=$(yq '.course.year' "$config_file")

  echo ""
  echo "${FLOW_COLORS[bold]}📚 $course_name - $semester $year${FLOW_COLORS[reset]}"
  echo ""

  # Show current week (based on date)
  local current_week=$(_calculate_current_week "$config_file")
  if [[ -n "$current_week" ]]; then
    echo "  ${FLOW_COLORS[info]}Current Week:${FLOW_COLORS[reset]} Week $current_week"
  fi

  # Show recent quiz/assignment status (from nexus if available)
  if command -v nexus &>/dev/null; then
    echo "  ${FLOW_COLORS[info]}Recent Materials:${FLOW_COLORS[reset]}"
    nexus teach course show "$course_name" 2>/dev/null | tail -5
  fi

  # Show shortcuts
  echo ""
  echo "  ${FLOW_COLORS[bold]}Quick Commands:${FLOW_COLORS[reset]}"
  yq -r '.shortcuts | to_entries | .[] | "  \(.key) → \(.value)"' "$config_file"
  echo ""
}

_load_teaching_shortcuts() {
  local config_file="$1"

  # Create aliases for current session
  eval "$(yq -r '.shortcuts | to_entries | .[] | "alias \(.key)=\"\(.value)\""' "$config_file")"
}

_calculate_current_week() {
  local config_file="$1"

  # Simple week calculation based on semester start date
  # TODO: Read semester start from config, calculate week number

  echo "8"  # Placeholder
}
```

### 1.4: Automation Scripts (Templates)

**New Directory:** `lib/templates/teaching/` (in flow-cli)

#### Template 1: `quick-deploy.sh`

```bash
#!/usr/bin/env bash
# Quick Deploy - Single commit to production
# Generated by flow-cli teaching framework

set -euo pipefail

# Load course config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG="$PROJECT_DIR/.flow/teach-config.yml"

# Read config
DRAFT_BRANCH=$(yq '.branches.draft' "$CONFIG")
PRODUCTION_BRANCH=$(yq '.branches.production' "$CONFIG")

# Safety check
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "$DRAFT_BRANCH" ]]; then
  echo "❌ Must be on $DRAFT_BRANCH branch"
  exit 1
fi

# Quick deploy
echo "🚀 Quick Deploy: $DRAFT_BRANCH → $PRODUCTION_BRANCH"
echo ""

git checkout "$PRODUCTION_BRANCH"
git merge "$DRAFT_BRANCH" --no-edit
git push origin "$PRODUCTION_BRANCH"
git checkout "$DRAFT_BRANCH"

echo ""
echo "✅ Deployed to production"
echo "🌐 Live at: $(yq '.deployment.web.url' "$CONFIG")"
```

#### Template 2: `quiz-to-qti.sh`

```bash
#!/usr/bin/env bash
# Quiz Converter - Markdown to Canvas QTI
# Uses examark for conversion

set -euo pipefail

QUIZ_FILE="$1"

if [[ -z "$QUIZ_FILE" ]]; then
  echo "Usage: quiz-to-qti.sh <quiz-file.md>"
  exit 1
fi

if [[ ! -f "$QUIZ_FILE" ]]; then
  echo "❌ Quiz file not found: $QUIZ_FILE"
  exit 1
fi

echo "📝 Converting quiz to Canvas format..."
examark "$QUIZ_FILE" -o "${QUIZ_FILE%.md}.qti.zip"

echo "✅ Canvas file ready: ${QUIZ_FILE%.md}.qti.zip"
echo "📤 Upload to Canvas manually (Phase 2: API integration)"
```

#### Template 3: `publish-batch.sh`

```bash
#!/usr/bin/env bash
# Batch Publish - Multiple commits to production

set -euo pipefail

# Load config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG="$PROJECT_DIR/.flow/teach-config.yml"

DRAFT_BRANCH=$(yq '.branches.draft' "$CONFIG")
PRODUCTION_BRANCH=$(yq '.branches.production' "$CONFIG")

# Show commits to deploy
echo "📦 Commits to deploy:"
git log "$PRODUCTION_BRANCH..$DRAFT_BRANCH" --oneline
echo ""

read -p "Deploy all commits? [Y/n] " confirm
if [[ "$confirm" == "n" ]]; then
  exit 0
fi

# Deploy
git checkout "$PRODUCTION_BRANCH"
git merge "$DRAFT_BRANCH" --no-edit
git push origin "$PRODUCTION_BRANCH"
git checkout "$DRAFT_BRANCH"

echo ""
echo "✅ Batch deploy complete"
```

#### Template 4: `semester-archive.sh`

```bash
#!/usr/bin/env bash
# Semester Archive - Annual transition helper

set -euo pipefail

# Load config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG="$PROJECT_DIR/.flow/teach-config.yml"

SEMESTER=$(yq '.course.semester' "$CONFIG")
YEAR=$(yq '.course.year' "$CONFIG")
TAG="$SEMESTER-$YEAR-final"

echo "📋 Semester Archive Tool"
echo ""
echo "  Semester: $SEMESTER $YEAR"
echo "  Tag: $TAG"
echo ""

read -p "Create archive tag? [Y/n] " confirm
if [[ "$confirm" == "n" ]]; then
  exit 0
fi

# Tag production
git tag -a "$TAG" -m "$SEMESTER $YEAR Complete"
git push --tags

echo ""
echo "✅ Archived: $TAG"
echo "📝 Update .flow/teach-config.yml for next semester"
```

### 1.5: GitHub Actions Workflow

**New File:** `.github/workflows/deploy.yml` (template)

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches:
      - {{ production_branch }}  # Variable from config

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Quarto
        uses: quarto-dev/quarto-actions/setup@v2

      - name: Setup R
        uses: r-lib/actions/setup-r@v2
        with:
          r-version: '4.3.0'

      - name: Install R dependencies
        run: |
          install.packages(c("tidyverse", "knitr", "rmarkdown"))
        shell: Rscript {0}

      - name: Render Quarto
        run: quarto render

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./_site
```

### 1.6: Migration Command

**New File:** `commands/teach-init.zsh`

```zsh
teach-init() {
  local course_name="$1"

  if [[ -z "$course_name" ]]; then
    _flow_log_error "Usage: teach-init <course-name>"
    return 1
  fi

  echo "🎓 Initializing teaching workflow for: $course_name"
  echo ""

  # Detect git state
  if [[ -d .git ]]; then
    _teach_migrate_existing_repo "$course_name"
  else
    _teach_create_fresh_repo "$course_name"
  fi
}

_teach_migrate_existing_repo() {
  local course_name="$1"

  echo "📋 Detected existing git repository"
  echo ""
  echo "Choose migration strategy:"
  echo "  1. In-place conversion (rename main→production, create draft)"
  echo "  2. Fresh start (initialize clean repo)"
  echo ""

  read -p "Choice [1/2]: " choice

  case "$choice" in
    1) _teach_inplace_conversion "$course_name" ;;
    2) _teach_fresh_start "$course_name" ;;
    *) echo "Invalid choice"; return 1 ;;
  esac
}

_teach_inplace_conversion() {
  local course_name="$1"

  # Tag current state
  local semester=$(date +"%Y-%m" | sed 's/01-05/spring/' | sed 's/08-12/fall/')
  local year=$(date +%Y)
  git tag -a "$semester-$year-pre-migration" -m "Pre-migration snapshot"

  # Rename main → production
  git branch -m main production 2>/dev/null || git branch -m master production
  git push -u origin production

  # Create draft from production
  git checkout -b draft production
  git push -u origin draft

  # Create directory structure
  mkdir -p .flow scripts

  # Copy templates
  _teach_install_templates "$course_name"

  echo ""
  echo "✅ Migration complete"
}

_teach_install_templates() {
  local course_name="$1"

  # Copy script templates from flow-cli
  local template_dir="${FLOW_PLUGIN_ROOT}/lib/templates/teaching"

  cp "$template_dir/quick-deploy.sh" scripts/
  cp "$template_dir/quiz-to-qti.sh" scripts/
  cp "$template_dir/publish-batch.sh" scripts/
  cp "$template_dir/semester-archive.sh" scripts/
  chmod +x scripts/*.sh

  # Generate config
  cat > .flow/teach-config.yml <<EOF
course:
  name: "$course_name"
  full_name: "$(read -p "Full course name: " name; echo $name)"
  semester: "spring"
  year: $(date +%Y)
  instructor: "$USER"

branches:
  draft: "draft"
  production: "production"

scholar:
  quiz_command: "/teaching:quiz"
  exam_command: "/teaching:exam"
  assignment_command: "/teaching:assignment"

examark:
  enabled: true
  quiz_dir: "quizzes"
  exam_dir: "exams"

deployment:
  web:
    type: "github-pages"
    branch: "production"

automation:
  quick_deploy: "scripts/quick-deploy.sh"
  batch_publish: "scripts/publish-batch.sh"
  quiz_convert: "scripts/quiz-to-qti.sh"

shortcuts:
  $(echo $course_name | tr '[:upper:]' '[:lower:]' | tr ' ' '-'): "work $course_name"
EOF

  # Generate GitHub Actions workflow
  local gh_dir=".github/workflows"
  mkdir -p "$gh_dir"

  sed "s/{{ production_branch }}/production/g" \
    "$template_dir/deploy.yml.template" > "$gh_dir/deploy.yml"

  # Commit setup
  git add .flow scripts .github
  git commit -m "chore: Initialize teaching workflow

- Add .flow/teach-config.yml
- Add automation scripts
- Add GitHub Actions deployment

Generated by flow-cli teach-init"

  git push origin draft

  echo ""
  echo "✅ Templates installed"
  echo "📝 Edit .flow/teach-config.yml to customize"
  echo ""
  echo "Next steps:"
  echo "  1. work $course_name  # Start teaching session"
  echo "  2. Create quiz with scholar: /teaching:quiz"
  echo "  3. Deploy: s545d (or your custom shortcut)"
}
```

---

## Phase 2: Generalization

### 2.1: Future Courses

After STAT 545 proves the pattern, any new course can use:

```bash
cd ~/projects/teaching/stat-579
teach-init "STAT 579"
```

This creates:
- `.flow/teach-config.yml` (customized for course)
- `scripts/` (automation helpers)
- `.github/workflows/deploy.yml` (CI/CD)
- Branch structure (draft + production)

### 2.2: Shared Patterns

All teaching courses will have:

| Pattern | Implementation |
|---------|----------------|
| **Two-branch workflow** | draft (work) + production (students) |
| **Workflow guard** | Prevents accidental production edits |
| **Scholar integration** | Direct calls to `/teaching:*` commands |
| **examark conversion** | Markdown → Canvas QTI format |
| **Per-course shortcuts** | Loaded by `work <course>` command |
| **Automation scripts** | Templates customizable per course |
| **GitHub Actions** | Auto-deploy on production push |

---

## Critical Files

### New Files (flow-cli)

| File | Purpose | Lines |
|------|---------|-------|
| `commands/teach-init.zsh` | Course scaffolding command | ~300 |
| `lib/templates/teaching/quick-deploy.sh` | Deploy script template | ~50 |
| `lib/templates/teaching/quiz-to-qti.sh` | Quiz converter template | ~30 |
| `lib/templates/teaching/publish-batch.sh` | Batch deploy template | ~40 |
| `lib/templates/teaching/semester-archive.sh` | Semester archive template | ~60 |
| `lib/templates/teaching/deploy.yml.template` | GitHub Actions template | ~40 |
| `lib/templates/teaching/teach-config.yml.template` | Config template | ~60 |

### Modified Files (flow-cli)

| File | Changes | Lines Changed |
|------|---------|---------------|
| `commands/work.zsh` | Add `_work_teaching_session()` | ~150 new |
| `lib/project-detector.zsh` | Enhanced teaching detection | ~30 modified |
| `flow.plugin.zsh` | Source teach-init command | +1 |

### New Files (STAT 545 repo)

| File | Purpose |
|------|---------|
| `.flow/teach-config.yml` | Course-specific configuration |
| `scripts/quick-deploy.sh` | From template (customizable) |
| `scripts/quiz-to-qti.sh` | From template |
| `scripts/publish-batch.sh` | From template |
| `scripts/semester-archive.sh` | From template |
| `.github/workflows/deploy.yml` | GitHub Actions CI/CD |

---

## Verification & Testing

### Unit Tests

**New Test Suite:** `tests/test-teach-init.zsh`

```zsh
# Test 1: teach-init creates directory structure
test_teach_init_creates_structure() {
  cd /tmp/test-course
  teach-init "Test Course"

  assert_directory_exists ".flow"
  assert_file_exists ".flow/teach-config.yml"
  assert_directory_exists "scripts"
  assert_file_executable "scripts/quick-deploy.sh"
}

# Test 2: work command detects teaching project
test_work_detects_teaching() {
  cd /tmp/test-course
  local project_type=$(_flow_detect_project_type .)

  assert_equals "teaching" "$project_type"
}

# Test 3: Branch safety check
test_production_branch_warning() {
  cd /tmp/test-course
  git checkout production

  # Should warn when on production
  output=$(work test-course 2>&1)
  assert_contains "$output" "PRODUCTION branch"
}

# Test 4: Scholar integration
test_scholar_quiz_generation() {
  # Assumes scholar plugin installed
  if ! command -v claude &>/dev/null; then
    skip "Requires Claude Code"
  fi

  cd /tmp/test-course
  # Test workflow would call scholar command
  # Verify quiz file created
}
```

### Integration Tests

**E2E Workflow Test:**

```bash
# 1. Initialize course
cd ~/projects/teaching/stat-545-test
teach-init "STAT 545"

# 2. Verify structure
ls -la .flow/teach-config.yml
ls -la scripts/

# 3. Generate quiz (requires scholar)
/teaching:quiz "ANOVA concepts"
# → Creates quizzes/week08-quiz.md

# 4. Convert quiz
./scripts/quiz-to-qti.sh quizzes/week08-quiz.md
# → Creates quizzes/week08-quiz.qti.zip

# 5. Deploy
./scripts/quick-deploy.sh
# → Merges draft → production, pushes to GitHub

# 6. Verify deployment
curl -s https://data-wise.github.io/stat-545 | grep "Week 8"
```

### Manual Testing Checklist

- [ ] `teach-init` creates all files
- [ ] `work stat-545` shows teaching context
- [ ] Branch safety warning on production
- [ ] Shortcuts loaded (s545, s545q, s545d)
- [ ] Scholar commands work (`/teaching:quiz`)
- [ ] examark conversion works
- [ ] Quick deploy works (draft → production)
- [ ] GitHub Actions triggers on push
- [ ] No manual git commands needed

---

## Dependencies

### Required (flow-cli)

- `yq` - YAML parsing (for .flow/teach-config.yml)
- `git` - Version control
- `quarto` - Course website rendering

### Required (STAT 545 workflow)

- `scholar` plugin - Quiz/exam generation
- `examark` - Markdown → Canvas QTI conversion
- `nexus` CLI (optional) - Course tracking

### Optional Enhancements

- GitHub CLI (`gh`) - For PR creation
- Canvas API - Phase 2 auto-upload

---

## Implementation Order

### Week 1: Core Framework

1. **Day 1** (4 hours)
   - Create `lib/templates/teaching/` with 4 script templates
   - Create `commands/teach-init.zsh` with scaffolding logic
   - Add `_work_teaching_session()` to `commands/work.zsh`

2. **Day 2** (3 hours)
   - Enhance `lib/project-detector.zsh` for teaching detection
   - Add YAML config loader (`_load_teaching_config`)
   - Add branch safety check (`_check_production_branch`)

3. **Day 3** (2 hours)
   - Test suite: `tests/test-teach-init.zsh`
   - Documentation: `docs/guides/TEACHING-WORKFLOW.md`
   - Update CLAUDE.md with teaching patterns

### Week 2: STAT 545 Migration

1. **Day 1** (3 hours)
   - Run `teach-init` in stat-545 repo
   - Customize scripts for STAT 545 specifics
   - Test quick-deploy workflow

2. **Day 2** (3 hours)
   - Integrate scholar commands
   - Test quiz generation → conversion → deploy
   - Refine .flow/teach-config.yml

3. **Day 3** (2 hours)
   - GitHub Actions setup
   - End-to-end workflow verification
   - Document STAT 545 as reference example

### Week 3: Polish & Documentation

1. **Day 1** (2 hours)
   - Edge case handling
   - Error messages improvement
   - Performance optimization

2. **Day 2** (2 hours)
   - Comprehensive documentation
   - Tutorial: STAT 545 migration walkthrough
   - Quick reference card

3. **Day 3** (1 hour)
   - Code review
   - Final testing
   - Ready for production

**Total Effort:** ~22 hours over 3 weeks (flexible timeline)

---

## Success Metrics

### Performance

- ✅ `work stat-545` responds in < 50ms (teaching context loading)
- ✅ `teach-init` completes in < 5 seconds
- ✅ Quick deploy (typo fix) completes in < 2 min
- ✅ Quiz workflow (generate → Canvas) completes in < 30 min

### Reliability

- ✅ Branch guard prevents 100% of accidental production edits
- ✅ All 4 automation scripts work without manual intervention
- ✅ GitHub Actions deploy succeeds on first push
- ✅ Zero manual git commands needed for daily workflow

### Usability

- ✅ STAT 545 instructor uses shortcuts daily (s545d, s545q)
- ✅ New quiz creation with scholar takes < 10 min
- ✅ Course context visible in terminal (week, recent materials)
- ✅ Semester transition completes in < 30 min with archive script

---

## Open Questions

1. **Scholar availability**: Is scholar plugin installed? (Required for quiz generation)
2. **Canvas API**: Should we add Canvas API upload in Phase 1 or defer to Phase 2?
3. **Week calculation**: How to determine current week? (config start date vs manual override)
4. **Testing strategy**: Should we create a test course or use STAT 545 directly?
5. **Documentation location**: STAT 545 spec file - move to stat-545 repo or keep in flow-cli/docs/specs/?

---

## Next Steps (User Decision Points)

### Before Implementation Begins

1. **Approve this plan** (via ExitPlanMode)
2. **Confirm scholar plugin installed** (verify `/teaching:*` commands work)
3. **Choose testing approach**:
   - Option A: Create test course first (safer)
   - Option B: Use STAT 545 directly (faster)
4. **Decide on STAT 545 spec**:
   - Keep in flow-cli (reference example)
   - Move to stat-545 repo (cleaner separation)

### After Approval

Following workflow protocol:
1. **Commit this plan** to dev branch (docs/specs/SPEC-teaching-workflow.md)
2. **Create worktree** for feature branch
3. **Ask user to start NEW session** in worktree

```
✅ Plan ready for approval!

To start implementation after approval:
  cd ~/.git-worktrees/flow-cli-teaching-workflow
  claude
```

---

**Plan Status:** ✅ Complete - Ready for Review
**Estimated Complexity:** Medium-High (new subsystem, multiple integrations)
**Risk Level:** Low (well-scoped, proven patterns from STAT 545 spec)
