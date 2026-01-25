# Teaching Feature for flow-cli - Implementation Plan v2.0

**Feature:** Teaching workflow with deployment automation and course context
**Status:** Planning - Updated after Deep Brainstorm (2026-01-11)
**Created:** 2026-01-11 (original), updated 2026-01-11
**Branch Strategy:** feature/teaching-workflow → dev → main

---

## Executive Summary

Implement a **deployment-focused teaching workflow system** in flow-cli that:
1. **Fast Deployment** (Phase 1) - Typo-to-live in < 2 min with branch safety
2. **Course Context** (Phase 1) - Teaching-aware `work` command with status dashboard
3. **Exam Workflow** (Phase 1.5) - Optional exam generation + conversion (2-3 exams/semester)
4. **Generic Framework** (Phase 2) - `teach init` for future courses

**Key Innovation:** Teaching-aware `work` command that auto-detects course context, prevents production branch edits, and provides one-command deployment.

**Major Changes from v1.0:**
- ✅ **Deployment-first** (was assessment-first)
- ✅ **No Canvas API** (manual upload is acceptable)
- ✅ **Scholar skills optional** (Phase 1.5, not Phase 1)
- ✅ **Incremental shipping** (not big-bang 22-hour implementation)
- ✅ **STAT 545 only in Phase 1** (other courses in Phase 2)

---

## Deep Brainstorm Findings

### User Research Summary (8 expert questions, 2026-01-11)

| Insight | Impact on Spec |
|---------|----------------|
| **Pain point:** 5-15 min manual git workflow | Priority 1: Fast deployment automation |
| **Frequency:** 2-3 exams/semester (not weekly) | De-prioritize quiz workflow, focus on deployment |
| **Canvas:** Manual upload acceptable | Remove Canvas API integration entirely |
| **Scholar:** Will build alongside flow-cli | Make scholar integration optional Phase 1.5 |
| **Scope:** STAT 545 only in Phase 1 | Remove multi-course support from Phase 1 |
| **Budget:** Flexible, ship incrementally | Break into 3 shippable increments |
| **Definition of Done:** All 4 success criteria selected | Branch safety + deployment + context + exams |
| **Content generation:** Copy-paste from Claude then format | Scholar skills = Phase 1.5 after core workflow works |

### Revised Success Criteria (Priority Order)

1. ⚡ **Fast deployment < 2 min** (Priority 1) - Typo → live
2. 🛡️ **Branch safety** (Priority 1) - Workflow guard prevents production edits
3. 📚 **Course context** (Priority 2) - `work stat-545` shows current week, status
4. 📝 **Exam workflow** (Priority 3) - One-command generation + conversion (Optional)

---

## Incremental Shipping Strategy

### Increment 1: Core Deployment (MVP - 4-6 hours)

**Goal:** Solve the 5-15 min deployment problem

**Deliverables:**
- Branch safety guard in `work` command
- `scripts/quick-deploy.sh` template
- Teaching project detection
- Basic `.flow/teach-config.yml`

**Success:** Typo deployment < 2 min, production branch warning works

**Ship When:** All tests pass, STAT 545 repo has config + script

---

### Increment 2: Course Context (4-6 hours)

**Goal:** Teaching-aware terminal experience

**Deliverables:**
- Enhanced `work` session with course info
- Current week calculation
- Course shortcuts loaded per-session
- Semester archive script

**Success:** `work stat-545` shows week, shortcuts work, context is clear

**Ship When:** Course context display tested in STAT 545

---

### Increment 3: Exam Workflow (8-10 hours) - OPTIONAL

**Goal:** Optional exam automation (Phase 1.5)

**Deliverables:**
- `teach-exam` command for guided exam creation
- examark integration
- Scholar skill integration (if ready)
- Exam workflow documentation

**Success:** End-to-end exam creation in < 30 min

**Ship When:** At least 1 exam created using the workflow

**Dependencies:**
- examark installed (`npm install -g examark`)
- Scholar teaching skills available (optional)

---

## Architecture Overview (Revised)

### Layer Integration

```
┌─────────────────────────────────────────────────────────────┐
│  scholar (Claude Plugin) - OPTIONAL PHASE 1.5               │
│  /scholar:exam, /scholar:lecture                            │
│  → AI-powered content generation                            │
└────────────────────┬────────────────────────────────────────┘
                     │ (optional)
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  flow-cli (Pure ZSH) ← THIS IMPLEMENTATION                  │
│  ├── work stat-545 (teaching-aware session) ← CORE          │
│  ├── Branch safety guard ← CORE                             │
│  ├── scripts/quick-deploy.sh ← CORE                         │
│  ├── .flow/teach-config.yml ← CORE                          │
│  └── teach-exam command ← OPTIONAL (Phase 1.5)              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  GitHub Actions - Auto-deploy on production push            │
│  → Quarto render → GitHub Pages                             │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow (Increment 1 - Core Deployment)

```
Scenario: Fix typo on website

1. Developer:
   cd ~/projects/teaching/stat-545
   work stat-545

2. flow-cli:
   → Detects teaching project
   → Checks git branch
   → ⚠️  WARN if on production branch
   → Show course context
   → Open editor

3. Developer fixes typo, saves

4. Developer:
   s545d    (shortcut for scripts/quick-deploy.sh)

5. Script:
   → Commit changes
   → Merge draft → production
   → Push to GitHub
   → GitHub Actions deploys

6. Result: Live in < 2 min
```

### Data Flow (Increment 3 - Exam Workflow - OPTIONAL)

```
Scenario: Create exam

1. Developer:
   work stat-545
   teach-exam "midterm covering weeks 1-8"

2. flow-cli:
   → Prompts for exam details (duration, points, topics)
   → Calls scholar skill (if available) OR opens template
   → Saves to exams/midterm-week08.md

3. Developer edits exam content

4. Developer:
   s545e midterm-week08    (convert exam)

5. Script:
   → Runs examark: md → qti.zip
   → Saves to exams/midterm-week08.qti.zip
   → Opens Canvas in browser

6. Developer manually uploads QTI to Canvas
```

---

## Phase 1: STAT 545 Core Deployment (Increment 1)

### 1.1: Teaching Project Detection (Enhanced)

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

    # Validate config if present
    if [[ -f "$dir/.flow/teach-config.yml" ]]; then
      if ! _validate_teaching_config "$dir/.flow/teach-config.yml"; then
        _flow_log_error "Invalid teaching config: $dir/.flow/teach-config.yml"
        return 1
      fi
    fi

    echo "teaching"
    return 0
  fi

  return 1
}

_validate_teaching_config() {
  local config="$1"

  # Check required fields
  command -v yq &>/dev/null || return 1

  yq -e '.course.name' "$config" &>/dev/null || return 1
  yq -e '.branches.draft' "$config" &>/dev/null || return 1
  yq -e '.branches.production' "$config" &>/dev/null || return 1

  return 0
}
```

**Test Cases:**
- [x] Detects existing courses (syllabus.qmd or lectures/ dir)
- [x] Detects new courses (.flow/teach-config.yml)
- [x] Validates config structure
- [x] Returns error for malformed config

---

### 1.2: Teaching Configuration (Simplified)

**New File:** `.flow/teach-config.yml` (in STAT 545 repo)

**Minimal config for Increment 1:**

```yaml
# STAT 545 Teaching Configuration
# Version: 1.0 (Increment 1 - Core Deployment)

course:
  name: "STAT 545"
  full_name: "Design of Experiments"
  semester: "spring"
  year: 2026
  instructor: "DT"

branches:
  draft: "draft"
  production: "production"

deployment:
  web:
    type: "github-pages"
    branch: "production"
    url: "https://data-wise.github.io/stat-545"

automation:
  quick_deploy: "scripts/quick-deploy.sh"

shortcuts:
  s545: "work stat-545"
  s545d: "./scripts/quick-deploy.sh"
```

**Fields for Increment 2 (Course Context):**

```yaml
# Add to above config for Increment 2
semester_info:
  start_date: "2026-01-13"  # ISO 8601
  weeks: 16
  breaks:
    - start: "2026-03-10"
      end: "2026-03-14"
      name: "Spring Break"
```

**Fields for Increment 3 (Exam Workflow - OPTIONAL):**

```yaml
# Add to above config for Increment 3
scholar:
  exam_skill: "/scholar:exam"        # If scholar plugin available
  lecture_skill: "/scholar:lecture"  # Optional

examark:
  enabled: true
  exam_dir: "exams"
  output_format: "qti"

shortcuts:
  s545e: "./scripts/exam-to-qti.sh"  # Exam conversion
```

---

### 1.3: Enhanced `work` Command (Increment 1 - Branch Safety)

**File:** `commands/work.zsh`

**New Function:** `_work_teaching_session()` (Minimal for Increment 1)

```zsh
_work_teaching_session() {
  local project_dir="$1"
  local config_file="$project_dir/.flow/teach-config.yml"

  # 1. Validate config exists
  if [[ ! -f "$config_file" ]]; then
    _flow_log_error "Teaching config not found: $config_file"
    _flow_log_info "Run 'teach-init' to create configuration"
    return 1
  fi

  # 2. Validate yq available
  if ! command -v yq &>/dev/null; then
    _flow_log_error "yq is required for teaching workflow"
    _flow_log_info "Install: brew install yq"
    return 1
  fi

  # 3. Branch safety check
  local current_branch=$(git -C "$project_dir" branch --show-current)
  local production_branch=$(yq -r '.branches.production' "$config_file")
  local draft_branch=$(yq -r '.branches.draft' "$config_file")

  if [[ "$current_branch" == "$production_branch" ]]; then
    echo ""
    echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[error]}⚠️  WARNING: You are on PRODUCTION branch${FLOW_COLORS[reset]}"
    echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
    echo ""
    echo "  ${FLOW_COLORS[bold]}Branch:${FLOW_COLORS[reset]} $production_branch"
    echo "  ${FLOW_COLORS[error]}Students see this branch!${FLOW_COLORS[reset]}"
    echo ""
    echo "  ${FLOW_COLORS[info]}Recommended: Switch to draft branch for edits${FLOW_COLORS[reset]}"
    echo "  ${FLOW_COLORS[info]}Draft branch: $draft_branch${FLOW_COLORS[reset]}"
    echo ""
    echo "${FLOW_COLORS[header]}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${FLOW_COLORS[reset]}"
    echo ""

    # Prompt to switch (with timeout for non-interactive contexts)
    if [[ -z "$FLOW_TEACHING_ALLOW_PRODUCTION" ]]; then
      read -t 30 -q "?Continue on production anyway? [y/N] " continue_anyway
      echo ""

      if [[ "$continue_anyway" != "y" ]]; then
        _flow_log_info "Switching to draft branch: $draft_branch"
        git -C "$project_dir" checkout "$draft_branch"
        current_branch="$draft_branch"
      fi
    fi
  fi

  # 4. Load shortcuts for current session
  _load_teaching_shortcuts "$config_file"

  # 5. Show minimal context
  local course_name=$(yq -r '.course.name' "$config_file")
  echo ""
  echo "${FLOW_COLORS[bold]}📚 $course_name${FLOW_COLORS[reset]}"
  echo "  ${FLOW_COLORS[info]}Branch:${FLOW_COLORS[reset]} $current_branch"
  echo ""

  # 6. Open editor
  cd "$project_dir"
  ${EDITOR:-code} .
}

_load_teaching_shortcuts() {
  local config_file="$1"

  # Create aliases for current session
  eval "$(yq -r '.shortcuts | to_entries[] | "alias \(.key)=\"\(.value)\""' "$config_file")"

  # Show loaded shortcuts
  echo "${FLOW_COLORS[bold]}Shortcuts loaded:${FLOW_COLORS[reset]}"
  yq -r '.shortcuts | to_entries[] | "  \(.key) → \(.value)"' "$config_file"
  echo ""
}
```

**Enhancement for Increment 2 (Course Context):**

```zsh
# Add after step 5 in _work_teaching_session()

# 5b. Show course context (Increment 2)
_display_teaching_context "$project_dir" "$config_file"

_display_teaching_context() {
  local project_dir="$1"
  local config_file="$2"

  local semester=$(yq -r '.course.semester' "$config_file")
  local year=$(yq -r '.course.year' "$config_file")

  echo "  ${FLOW_COLORS[info]}Semester:${FLOW_COLORS[reset]} $semester $year"

  # Calculate current week
  local current_week=$(_calculate_current_week "$config_file")
  if [[ -n "$current_week" && "$current_week" != "null" ]]; then
    echo "  ${FLOW_COLORS[info]}Current Week:${FLOW_COLORS[reset]} Week $current_week"
  fi

  # Show recent git activity
  local recent_commits=$(git -C "$project_dir" log --oneline -3 --format="%s")
  if [[ -n "$recent_commits" ]]; then
    echo ""
    echo "  ${FLOW_COLORS[bold]}Recent Changes:${FLOW_COLORS[reset]}"
    echo "$recent_commits" | sed 's/^/    /'
  fi

  echo ""
}

_calculate_current_week() {
  local config_file="$1"

  # Read semester start date from config
  local start_date=$(yq -r '.semester_info.start_date // empty' "$config_file")

  if [[ -z "$start_date" ]]; then
    return 0
  fi

  # Calculate weeks since start (macOS compatible)
  local start_epoch=$(date -j -f "%Y-%m-%d" "$start_date" "+%s" 2>/dev/null)
  local now_epoch=$(date "+%s")

  if [[ -z "$start_epoch" ]]; then
    return 0
  fi

  local days_diff=$(( (now_epoch - start_epoch) / 86400 ))
  local week=$(( (days_diff / 7) + 1 ))

  # Cap at 16 weeks
  if [[ $week -gt 16 ]]; then
    week=16
  fi

  echo "$week"
}
```

---

### 1.4: Automation Scripts (Templates)

**New Directory:** `lib/templates/teaching/` (in flow-cli)

#### Template 1: `quick-deploy.sh` (Increment 1 - CORE)

```bash
#!/usr/bin/env bash
# Quick Deploy - Single commit to production
# Generated by flow-cli teaching framework

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Load course config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG="$PROJECT_DIR/.flow/teach-config.yml"

if [[ ! -f "$CONFIG" ]]; then
  echo -e "${RED}❌ Config not found: $CONFIG${NC}"
  exit 1
fi

# Validate yq available
if ! command -v yq &>/dev/null; then
  echo -e "${RED}❌ yq is required${NC}"
  echo -e "${YELLOW}Install: brew install yq${NC}"
  exit 1
fi

# Read config
DRAFT_BRANCH=$(yq -r '.branches.draft' "$CONFIG")
PRODUCTION_BRANCH=$(yq -r '.branches.production' "$CONFIG")
SITE_URL=$(yq -r '.deployment.web.url' "$CONFIG")

# Safety check
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" != "$DRAFT_BRANCH" ]]; then
  echo -e "${RED}❌ Must be on $DRAFT_BRANCH branch${NC}"
  echo -e "${YELLOW}Current branch: $CURRENT_BRANCH${NC}"
  echo -e "${BLUE}Run: git checkout $DRAFT_BRANCH${NC}"
  exit 1
fi

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
  echo -e "${YELLOW}⚠️  Uncommitted changes detected${NC}"
  read -p "Commit changes first? [Y/n] " commit_first

  if [[ "$commit_first" != "n" ]]; then
    read -p "Commit message: " commit_msg
    git add .
    git commit -m "${commit_msg:-Quick update}"
  else
    echo -e "${RED}❌ Cannot deploy with uncommitted changes${NC}"
    exit 1
  fi
fi

# Quick deploy
echo ""
echo -e "${BLUE}🚀 Quick Deploy: $DRAFT_BRANCH → $PRODUCTION_BRANCH${NC}"
echo ""

# Record start time
START_TIME=$(date +%s)

# Switch to production
git checkout "$PRODUCTION_BRANCH"

# Merge draft
echo -e "${YELLOW}Merging draft...${NC}"
if ! git merge "$DRAFT_BRANCH" --no-edit; then
  echo -e "${RED}❌ Merge conflict detected${NC}"
  echo -e "${YELLOW}Resolve conflicts and run again${NC}"
  git merge --abort
  git checkout "$DRAFT_BRANCH"
  exit 1
fi

# Push to remote
echo -e "${YELLOW}Pushing to remote...${NC}"
git push origin "$PRODUCTION_BRANCH"

# Switch back to draft
git checkout "$DRAFT_BRANCH"

# Calculate duration
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Deployed to production in ${DURATION}s${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}🌐 Site: $SITE_URL${NC}"
echo -e "${YELLOW}⏳ GitHub Actions deploying (usually < 2 min)${NC}"
echo ""
echo -e "${BLUE}💡 Tip: Check deployment status at:${NC}"
echo -e "   https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:\/]\(.*\)\.git/\1/')/actions"
echo ""
```

**Key Features:**
- ✅ Branch safety check
- ✅ Uncommitted changes detection
- ✅ Deployment time tracking
- ✅ Color-coded output
- ✅ Error handling with rollback

#### Template 2: `semester-archive.sh` (Increment 1 - CORE)

```bash
#!/usr/bin/env bash
# Semester Archive - Annual transition helper

set -euo pipefail

# Load config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG="$PROJECT_DIR/.flow/teach-config.yml"

if [[ ! -f "$CONFIG" ]]; then
  echo "❌ Config not found: $CONFIG"
  exit 1
fi

SEMESTER=$(yq -r '.course.semester' "$CONFIG")
YEAR=$(yq -r '.course.year' "$CONFIG")
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

# Tag production branch
PRODUCTION_BRANCH=$(yq -r '.branches.production' "$CONFIG")
git checkout "$PRODUCTION_BRANCH"
git tag -a "$TAG" -m "$SEMESTER $YEAR - Course Complete"
git push --tags

echo ""
echo "✅ Archived: $TAG"
echo "📝 Next steps:"
echo "   1. Update .flow/teach-config.yml for next semester"
echo "   2. Update course.year (or course.semester)"
echo "   3. Commit config changes to draft branch"
echo ""
```

#### Template 3: `exam-to-qti.sh` (Increment 3 - OPTIONAL)

```bash
#!/usr/bin/env bash
# Exam Converter - Markdown to Canvas QTI
# Uses examark for conversion
# OPTIONAL: Only needed if using exam workflow

set -euo pipefail

EXAM_FILE="$1"

if [[ -z "$EXAM_FILE" ]]; then
  echo "Usage: exam-to-qti.sh <exam-file.md>"
  exit 1
fi

if [[ ! -f "$EXAM_FILE" ]]; then
  echo "❌ Exam file not found: $EXAM_FILE"
  exit 1
fi

# Check examark installed
if ! command -v examark &>/dev/null; then
  echo "❌ examark not installed"
  echo "Install: npm install -g examark"
  exit 1
fi

echo "📝 Converting exam to Canvas format..."
examark "$EXAM_FILE" -o "${EXAM_FILE%.md}.qti.zip"

if [[ $? -eq 0 ]]; then
  echo "✅ Canvas file ready: ${EXAM_FILE%.md}.qti.zip"
  echo "📤 Upload to Canvas manually"
  echo ""
  echo "💡 Tip: Open Canvas in browser and upload the .qti.zip file"
else
  echo "❌ Conversion failed"
  exit 1
fi
```

---

### 1.5: Migration Command `teach-init` (Increment 1)

**New File:** `commands/teach-init.zsh`

**Purpose:** Scaffold teaching workflow in existing or new course repo

```zsh
teach-init() {
  local course_name="$1"

  if [[ -z "$course_name" ]]; then
    _flow_log_error "Usage: teach-init <course-name>"
    echo ""
    echo "Examples:"
    echo "  teach-init \"STAT 545\""
    echo "  teach-init \"STAT 440\""
    return 1
  fi

  echo "🎓 Initializing teaching workflow for: $course_name"
  echo ""

  # Check dependencies
  if ! command -v yq &>/dev/null; then
    _flow_log_error "yq is required"
    echo "Install: brew install yq"
    return 1
  fi

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

  # Check current branch
  local current_branch=$(git branch --show-current)
  echo "Current branch: $current_branch"
  echo ""

  # Strategy menu
  echo "Choose migration strategy:"
  echo "  ${FLOW_COLORS[bold]}1.${FLOW_COLORS[reset]} In-place conversion (rename $current_branch → production, create draft)"
  echo "  ${FLOW_COLORS[bold]}2.${FLOW_COLORS[reset]} Two-branch setup (keep $current_branch, create draft + production)"
  echo ""

  read -p "Choice [1/2]: " choice

  case "$choice" in
    1) _teach_inplace_conversion "$course_name" ;;
    2) _teach_two_branch_setup "$course_name" ;;
    *) echo "Invalid choice"; return 1 ;;
  esac
}

_teach_inplace_conversion() {
  local course_name="$1"
  local current_branch=$(git branch --show-current)

  echo ""
  echo "⚠️  This will:"
  echo "  1. Rename $current_branch → production"
  echo "  2. Create new draft branch from production"
  echo "  3. Add .flow/teach-config.yml and scripts/"
  echo ""

  read -p "Continue? [y/N] " confirm
  if [[ "$confirm" != "y" ]]; then
    echo "Cancelled"
    return 1
  fi

  # Tag current state
  local semester=$(date +"%B" | sed 's/January\|February\|March\|April\|May/spring/; s/June\|July/summer/; s/August\|September\|October\|November\|December/fall/')
  local year=$(date +%Y)
  git tag -a "$semester-$year-pre-migration" -m "Pre-migration snapshot"

  # Rename to production
  git branch -m "$current_branch" production
  git push -u origin production

  # Create draft from production
  git checkout -b draft production
  git push -u origin draft

  # Install templates
  _teach_install_templates "$course_name"

  echo ""
  echo "✅ Migration complete"
  _teach_show_next_steps "$course_name"
}

_teach_two_branch_setup() {
  local course_name="$1"

  # Create production and draft branches
  git checkout -b production
  git push -u origin production

  git checkout -b draft
  git push -u origin draft

  # Install templates
  _teach_install_templates "$course_name"

  echo ""
  echo "✅ Two-branch setup complete"
  _teach_show_next_steps "$course_name"
}

_teach_install_templates() {
  local course_name="$1"

  # Create directory structure
  mkdir -p .flow scripts

  # Copy script templates from flow-cli
  local template_dir="${FLOW_PLUGIN_ROOT}/lib/templates/teaching"

  cp "$template_dir/quick-deploy.sh" scripts/
  cp "$template_dir/semester-archive.sh" scripts/
  chmod +x scripts/*.sh

  # Generate minimal config (Increment 1)
  local course_slug=$(echo "$course_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
  local semester=$(date +"%B" | sed 's/January\|February\|March\|April\|May/spring/; s/June\|July/summer/; s/August\|September\|October\|November\|December/fall/')
  local year=$(date +%Y)

  cat > .flow/teach-config.yml <<EOF
# $course_name Teaching Configuration
# Version: 1.0 (Increment 1 - Core Deployment)
# Generated: $(date +"%Y-%m-%d")

course:
  name: "$course_name"
  full_name: "$course_name"  # TODO: Update with full course title
  semester: "$semester"
  year: $year
  instructor: "$USER"

branches:
  draft: "draft"
  production: "production"

deployment:
  web:
    type: "github-pages"
    branch: "production"
    url: "https://data-wise.github.io/$course_slug"  # TODO: Update if different

automation:
  quick_deploy: "scripts/quick-deploy.sh"

shortcuts:
  ${course_slug}: "work $course_slug"
  ${course_slug}d: "./scripts/quick-deploy.sh"
EOF

  # Commit setup
  git add .flow scripts
  git commit -m "chore: Initialize teaching workflow

- Add .flow/teach-config.yml (Increment 1)
- Add deployment automation scripts
- Branch structure: draft + production

Generated by flow-cli teach-init"

  git push origin draft

  echo ""
  echo "✅ Templates installed"
}

_teach_show_next_steps() {
  local course_name="$1"

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "🎉 Teaching workflow initialized!"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Next steps:"
  echo ""
  echo "  1. Review config:"
  echo "     ${FLOW_COLORS[cmd]}\$EDITOR .flow/teach-config.yml${FLOW_COLORS[reset]}"
  echo ""
  echo "  2. Update GitHub repo settings:"
  echo "     - Enable GitHub Pages from 'production' branch"
  echo "     - Set Pages source: / (root)"
  echo ""
  echo "  3. Test deployment:"
  echo "     ${FLOW_COLORS[cmd]}./scripts/quick-deploy.sh${FLOW_COLORS[reset]}"
  echo ""
  echo "  4. Start working:"
  echo "     ${FLOW_COLORS[cmd]}work $course_name${FLOW_COLORS[reset]}"
  echo ""
  echo "📚 Documentation:"
  echo "   https://data-wise.github.io/flow-cli/guides/teaching-workflow/"
  echo ""
}

_teach_create_fresh_repo() {
  local course_name="$1"

  echo "📋 No git repository detected"
  echo ""
  echo "Initialize git repository first:"
  echo "  git init"
  echo "  git add ."
  echo "  git commit -m 'Initial commit'"
  echo ""
  echo "Then run teach-init again"
  return 1
}
```

---

### 1.6: GitHub Actions Workflow (Template)

**New File:** `lib/templates/teaching/deploy.yml.template`

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches:
      - production  # Only deploy from production branch

permissions:
  contents: read
  pages: write
  id-token: write

# Cancel in-progress deployments
concurrency:
  group: "pages"
  cancel-in-progress: true

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Quarto
        uses: quarto-dev/quarto-actions/setup@v2
        with:
          version: '1.4.550'  # Update as needed

      - name: Setup R
        uses: r-lib/actions/setup-r@v2
        with:
          r-version: '4.3.0'  # Update as needed

      - name: Install R dependencies
        run: |
          install.packages(c("tidyverse", "knitr", "rmarkdown"))
        shell: Rscript {0}

      - name: Render Quarto
        run: quarto render

      - name: Setup Pages
        uses: actions/configure-pages@v4

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./_site

      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v4
```

**Installation:** Copy to `.github/workflows/deploy.yml` during `teach-init`

---

## Phase 1.5: Exam Workflow (OPTIONAL - Increment 3)

### Overview

**Goal:** Optional exam generation + conversion workflow (2-3 exams/semester)

**Dependencies:**
- examark installed: `npm install -g examark`
- Scholar teaching skills (optional)

**Deliverables:**
- `teach-exam` command
- `scripts/exam-to-qti.sh`
- Scholar integration (if available)

### 1.7: Exam Command (NEW)

**New File:** `commands/teach-exam.zsh`

```zsh
teach-exam() {
  local topic="$1"

  if [[ -z "$topic" ]]; then
    _flow_log_error "Usage: teach-exam <topic>"
    echo ""
    echo "Examples:"
    echo "  teach-exam \"midterm covering weeks 1-8\""
    echo "  teach-exam \"final exam\""
    return 1
  fi

  # Detect teaching project
  local project_type=$(_flow_detect_project_type .)
  if [[ "$project_type" != "teaching" ]]; then
    _flow_log_error "Not in a teaching project"
    return 1
  fi

  # Load config
  local config_file=".flow/teach-config.yml"
  if [[ ! -f "$config_file" ]]; then
    _flow_log_error "Teaching config not found: $config_file"
    return 1
  fi

  # Check examark config
  local examark_enabled=$(yq -r '.examark.enabled // false' "$config_file")
  if [[ "$examark_enabled" != "true" ]]; then
    _flow_log_warning "examark not enabled in config"
    echo "To enable: yq -i '.examark.enabled = true' .flow/teach-config.yml"
  fi

  # Get exam directory
  local exam_dir=$(yq -r '.examark.exam_dir // "exams"' "$config_file")
  mkdir -p "$exam_dir"

  echo "📝 Creating exam: $topic"
  echo ""

  # Prompt for exam details
  echo "Exam details:"
  read -p "  Duration (minutes): " duration
  read -p "  Total points: " points
  read -p "  Filename (without .md): " filename

  if [[ -z "$filename" ]]; then
    filename="exam-$(date +%Y%m%d)"
  fi

  local exam_file="$exam_dir/$filename.md"

  # Check if scholar available
  if command -v claude &>/dev/null && yq -e '.scholar.exam_skill' "$config_file" &>/dev/null; then
    local scholar_skill=$(yq -r '.scholar.exam_skill' "$config_file")

    echo ""
    echo "🤖 Scholar skill available: $scholar_skill"
    read -p "Use scholar to generate exam? [Y/n] " use_scholar

    if [[ "$use_scholar" != "n" ]]; then
      echo ""
      echo "Launching Claude with scholar skill..."
      echo "Prompt: $scholar_skill \"$topic\""
      echo ""

      # Launch Claude in current directory
      # User will interact with scholar skill
      # Save output to exam file

      _flow_log_info "After generating content, save to: $exam_file"
      return 0
    fi
  fi

  # Fallback: Create template
  _teach_create_exam_template "$exam_file" "$topic" "$duration" "$points"

  echo ""
  echo "✅ Exam template created: $exam_file"
  echo ""
  echo "Next steps:"
  echo "  1. Edit exam: \$EDITOR $exam_file"
  echo "  2. Convert to Canvas: ./scripts/exam-to-qti.sh $exam_file"
  echo "  3. Upload .qti.zip to Canvas manually"
}

_teach_create_exam_template() {
  local exam_file="$1"
  local topic="$2"
  local duration="$3"
  local points="$4"

  cat > "$exam_file" <<EOF
# Exam: $topic

**Duration:** $duration minutes
**Total Points:** $points
**Format:** Canvas Quiz (QTI)

---

## Instructions

Write your exam instructions here.

---

## Question 1 (10 points)

[Your question here]

a) Option A
b) Option B
c) Option C
d) Option D

**Answer:** [Correct answer]

---

## Question 2 (10 points)

[Your question here]

**Answer:** [Free text answer]

---

## Add more questions as needed

EOF

  echo ""
  echo "✅ Template created: $exam_file"
}
```

---

## Phase 2: Generic Framework (Future)

### 2.1: Multi-Course Support

**Status:** Deferred to Phase 2 (after STAT 545 proves pattern)

**Scope:**
- Support STAT 440, causal-inference courses
- Cross-course shortcuts
- Unified teaching dashboard

**Approach:**
- Copy `.flow/teach-config.yml` pattern
- Run `teach-init` in each course
- Shortcuts namespaced by course (s545d, s440d)

---

## Critical Files Summary

### New Files (flow-cli)

| File | Purpose | Lines | Increment |
|------|---------|-------|-----------|
| `commands/teach-init.zsh` | Course scaffolding | ~300 | 1 |
| `commands/teach-exam.zsh` | Exam workflow (optional) | ~150 | 3 |
| `lib/templates/teaching/quick-deploy.sh` | Fast deployment | ~120 | 1 |
| `lib/templates/teaching/semester-archive.sh` | Archive script | ~50 | 1 |
| `lib/templates/teaching/exam-to-qti.sh` | Exam converter | ~40 | 3 |
| `lib/templates/teaching/deploy.yml.template` | GitHub Actions | ~50 | 1 |

### Modified Files (flow-cli)

| File | Changes | Lines Changed | Increment |
|------|---------|---------------|-----------|
| `commands/work.zsh` | Add `_work_teaching_session()` | ~80 new | 1 |
| `commands/work.zsh` | Add `_display_teaching_context()` | ~50 new | 2 |
| `lib/project-detector.zsh` | Enhanced teaching detection | ~40 modified | 1 |
| `flow.plugin.zsh` | Source teach-init, teach-exam | +2 | 1, 3 |

### New Files (STAT 545 repo) - Created by `teach-init`

| File | Purpose | Increment |
|------|---------|-----------|
| `.flow/teach-config.yml` | Course config | 1 |
| `scripts/quick-deploy.sh` | Deployment automation | 1 |
| `scripts/semester-archive.sh` | Archive tool | 1 |
| `scripts/exam-to-qti.sh` | Exam conversion (optional) | 3 |
| `.github/workflows/deploy.yml` | CI/CD | 1 |

---

## Dependencies

### Required (All Increments)

| Tool | Purpose | Install | Check |
|------|---------|---------|-------|
| `yq` | YAML parsing | `brew install yq` | `command -v yq` |
| `git` | Version control | Built-in | `git --version` |
| `quarto` | Course website | `brew install quarto` | `quarto --version` |

### Optional (Increment 3 - Exam Workflow)

| Tool | Purpose | Install | Check |
|------|---------|---------|-------|
| `examark` | MD → Canvas QTI | `npm install -g examark` | `command -v examark` |
| `scholar` | AI exam generation | Claude Code plugin | `/scholar:exam` works |

### Validation Script

**New File:** `scripts/check-teaching-deps.sh`

```bash
#!/usr/bin/env bash
# Check teaching workflow dependencies

echo "🔍 Checking teaching workflow dependencies..."
echo ""

# Required
printf "%-15s " "yq:"
command -v yq &>/dev/null && echo "✅" || echo "❌ brew install yq"

printf "%-15s " "git:"
command -v git &>/dev/null && echo "✅" || echo "❌"

printf "%-15s " "quarto:"
command -v quarto &>/dev/null && echo "✅" || echo "❌ brew install quarto"

echo ""
echo "Optional (Exam Workflow):"

printf "%-15s " "examark:"
command -v examark &>/dev/null && echo "✅" || echo "⚠️  npm install -g examark"

printf "%-15s " "scholar:"
if command -v claude &>/dev/null; then
  echo "⚠️  Check /scholar:exam availability"
else
  echo "⚠️  Claude Code not installed"
fi

echo ""
```

---

## Testing Strategy

### Increment 1: Core Deployment

**Unit Tests:**

```zsh
# tests/test-teach-init.zsh

test_teach_init_creates_structure() {
  cd /tmp/test-course
  git init
  git commit --allow-empty -m "Initial"

  teach-init "Test Course"

  assert_directory_exists ".flow"
  assert_file_exists ".flow/teach-config.yml"
  assert_directory_exists "scripts"
  assert_file_executable "scripts/quick-deploy.sh"
}

test_work_detects_teaching() {
  cd /tmp/test-course
  local project_type=$(_flow_detect_project_type .)

  assert_equals "teaching" "$project_type"
}

test_production_branch_warning() {
  cd /tmp/test-course
  git checkout production

  # Mock FLOW_TEACHING_ALLOW_PRODUCTION to skip prompt
  export FLOW_TEACHING_ALLOW_PRODUCTION=1

  output=$(work test-course 2>&1)
  assert_contains "$output" "WARNING: You are on PRODUCTION branch"
}

test_quick_deploy_validates_branch() {
  cd /tmp/test-course
  git checkout production

  ./scripts/quick-deploy.sh 2>&1 | grep "Must be on draft branch"
  assert_equals 1 $?
}
```

**E2E Test (Manual):**

```bash
# 1. Initialize test course
cd ~/projects/teaching/stat-545-test
teach-init "STAT 545 Test"

# 2. Verify structure
ls -la .flow/teach-config.yml
ls -la scripts/

# 3. Make a change
echo "Test content" >> index.qmd
git add index.qmd
git commit -m "test: Add test content"

# 4. Deploy
time ./scripts/quick-deploy.sh
# Should complete in < 2 min

# 5. Verify deployment
curl -s https://data-wise.github.io/stat-545-test | grep "Test content"
```

### Increment 2: Course Context

**Unit Tests:**

```zsh
test_current_week_calculation() {
  # Mock config with known start date
  echo "semester_info:
  start_date: \"2026-01-13\"" > /tmp/test-config.yml

  # Mock current date (2026-02-03 = 3 weeks after start)
  # This test needs date mocking - skip for now or use fixed test date
}

test_course_context_display() {
  cd /tmp/test-course
  git checkout draft

  output=$(work test-course 2>&1)
  assert_contains "$output" "Semester: spring 2026"
  assert_contains "$output" "Current Week:"
}
```

### Increment 3: Exam Workflow (Optional)

**Unit Tests:**

```zsh
test_teach_exam_creates_template() {
  cd /tmp/test-course

  # Mock stdin for prompts
  echo -e "60\n100\nmidterm" | teach-exam "midterm covering weeks 1-8"

  assert_file_exists "exams/midterm.md"
  assert_contains "$(cat exams/midterm.md)" "Duration: 60 minutes"
}

test_exam_conversion() {
  cd /tmp/test-course

  # Requires examark installed
  if ! command -v examark &>/dev/null; then
    skip "examark not installed"
  fi

  ./scripts/exam-to-qti.sh exams/midterm.md
  assert_file_exists "exams/midterm.qti.zip"
}
```

---

## Implementation Timeline (Revised)

### Increment 1: Core Deployment (4-6 hours)

**Week 1, Days 1-2:**

| Task | Duration | Output |
|------|----------|--------|
| Create `lib/templates/teaching/` with scripts | 2h | 3 template scripts |
| Create `commands/teach-init.zsh` | 2h | Scaffolding command |
| Enhance `lib/project-detector.zsh` | 1h | Teaching detection + validation |
| Enhance `commands/work.zsh` (branch safety) | 1h | Production branch warning |
| Test suite: `tests/test-teach-init.zsh` | 1h | 5 unit tests |

**Ship When:**
- [ ] All tests pass
- [ ] STAT 545 has `.flow/teach-config.yml`
- [ ] `scripts/quick-deploy.sh` works
- [ ] Branch safety warning tested

---

### Increment 2: Course Context (4-6 hours)

**Week 1, Days 3-4:**

| Task | Duration | Output |
|------|----------|--------|
| Add `_display_teaching_context()` | 2h | Week calculation, recent commits |
| Update `.flow/teach-config.yml` schema | 1h | semester_info section |
| Add semester start date UI | 1h | Config prompts in teach-init |
| Test current week calculation | 1h | Edge cases (breaks, past semester) |
| Documentation update | 1h | TEACHING-WORKFLOW.md guide |

**Ship When:**
- [ ] `work stat-545` shows current week
- [ ] Semester date calculation works
- [ ] Context display tested in STAT 545

---

### Increment 3: Exam Workflow (8-10 hours) - OPTIONAL

**Week 2:**

| Task | Duration | Output |
|------|----------|--------|
| Create `commands/teach-exam.zsh` | 3h | Exam scaffolding |
| Create `scripts/exam-to-qti.sh` | 1h | Conversion script |
| Add examark dependency check | 1h | Validation in teach-init |
| Scholar integration (if available) | 2h | Optional skill calls |
| Test examark conversion | 1h | E2E exam workflow |
| Documentation: exam workflow | 2h | Tutorial + examples |

**Ship When:**
- [ ] examark installed
- [ ] 1 exam created end-to-end
- [ ] QTI file validates in Canvas
- [ ] Scholar integration works (if available)

**Can Skip If:**
- examark not working
- Scholar skills not ready
- Only 2-3 exams/semester (manual is fine)

---

## Success Metrics (Updated)

### Increment 1: Core Deployment

| Metric | Target | Measurement |
|--------|--------|-------------|
| Deployment speed | < 2 min | Time from `quick-deploy.sh` to live |
| Branch safety | 100% | Production branch warning shown every time |
| Config validation | 100% | Malformed config rejected with helpful error |
| User experience | Smooth | No manual git commands needed |

### Increment 2: Course Context

| Metric | Target | Measurement |
|--------|--------|-------------|
| Week calculation | Accurate | Matches manual calculation |
| Context display | < 50ms | work command response time |
| Semester updates | Easy | Config update + commit |

### Increment 3: Exam Workflow (Optional)

| Metric | Target | Measurement |
|--------|--------|-------------|
| Exam creation | < 30 min | From `teach-exam` to Canvas upload |
| examark success | 100% | QTI files validate in Canvas |
| Scholar integration | Works | Skills generate exam content (if available) |

---

## Open Questions (Updated)

### Resolved (from deep brainstorm)

- ✅ **Which courses in Phase 1?** → STAT 545 only
- ✅ **Primary pain point?** → Deployment speed (5-15 min → < 2 min)
- ✅ **Canvas API needed?** → No, manual upload fine
- ✅ **Scholar availability?** → Build alongside, optional integration
- ✅ **Quiz vs exam focus?** → Focus on deployment, not assessment tools
- ✅ **Time budget?** → Flexible, ship incrementally

### Still Open

1. **GitHub Pages setup:** Should `teach-init` automate GitHub repo settings (enable Pages, set source)?
   - Option A: Manual (document in next steps)
   - Option B: Use `gh` CLI to automate (requires GitHub CLI)
   - **Recommendation:** Option A (manual) for Phase 1

2. **Error recovery:** If `quick-deploy.sh` fails mid-merge, how to recover?
   - Current: Manual `git merge --abort`
   - Future: Add `scripts/rollback.sh` helper

3. **Multi-instructor support:** How to handle TAs contributing to course?
   - Current: No special handling
   - Future: PR workflow before production deploy

4. **Exam templates:** Should we provide exam question templates?
   - Current: Basic markdown template
   - Future: Schema for different question types (MC, short answer, essay)

---

## Next Steps (Decision Points)

### Before Implementation

1. **Approve this updated spec** (deep brainstorm incorporated)
2. **Install examark** (for Increment 3, optional):

   ```bash
   npm install -g examark
   ```

3. **Decide on scholar skills:**
   - Build `/scholar:exam` skill now?
   - Or defer to Phase 1.5?
   - **Recommendation:** Defer to Phase 1.5

### After Approval

Following workflow protocol:

1. **Update original spec** or keep both?
   - Option A: Replace SPEC-teaching-workflow.md with v2
   - Option B: Keep both (v1 = archive, v2 = current)
   - **Recommendation:** Option A (replace)

2. **Commit updated spec** to dev branch
3. **Create worktree** for feature branch:

   ```bash
   git worktree add ~/.git-worktrees/flow-cli-teaching-workflow \
     -b feature/teaching-workflow dev
   ```

4. **Start NEW session** in worktree:

   ```bash
   cd ~/.git-worktrees/flow-cli-teaching-workflow
   claude
   ```

---

## Revision History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-11 | Initial spec (quiz-focused, 22h estimate) |
| 2.0 | 2026-01-11 | Deep brainstorm update (deployment-focused, incremental) |

---

**Plan Status:** ✅ v2.0 Complete - Ready for Review
**Estimated Complexity:** Medium (reduced from Medium-High)
**Total Effort:** 16-22 hours (was 22 hours) split into 3 increments
**Risk Level:** Low (proven patterns, incremental shipping, optional exam workflow)
