# SPEC: Teaching Workflow v3.0 Enhancements

**Status:** Approved
**Created:** 2026-01-18
**Author:** DT + Claude
**Target Version:** v5.14.0
**Brainstorm Source:** `/brainstorm max optimize save`

---

## Overview

This spec addresses four key enhancement areas for the teaching workflow, based on v5.13.1 learnings:

1. **Command Consolidation** - Remove `teach-init` only
2. **Health Check (`teach doctor`)** - Full implementation with sensible defaults
3. **Help System** - Add `--help` to sub-commands + more examples
4. **Update Flags** - `--update` with backup, `--version` for versioning

---

## Decisions Summary (Approved 2026-01-18)

| Area | Decision |
|------|----------|
| Command consolidation | Remove `teach-init` only, keep `flow teach` |
| `teach doctor` | Full implementation (deps, config, git, scholar) + `--fix`, `--json` |
| Help system | Add `--help` to all sub-commands + more real-world examples |
| Regeneration | `--update` (auto-backup), `--version` (exam-v2), `--dry-run` |
| Backup storage | `.backups/` inside content folders |
| Backup naming | Timestamp: `midterm.2026-01-18-1430.qmd` |
| Gitignore backups | User choice, configurable in teach-config.yml |
| Retention: Assessments | Archive per semester |
| Retention: Syllabi/Rubrics | Archive per semester |
| Retention: Lectures/Slides | Keep current semester only |

---

## 1. Command Entry Point Analysis

### Current State (v5.13.1)

| Entry Point | What It Does | Location |
|-------------|--------------|----------|
| `work stat-440` | Teaching session with branch safety | `commands/work.zsh` |
| `teach exam` | Scholar wrapper for exams | `lib/dispatchers/teach-dispatcher.zsh` |
| `flow teach` | Alias to `teach` | Plugin routing |
| `teach-init` | Initialize teaching project | `commands/teach-init.zsh` |
| `teach init` | Same as teach-init | Dispatcher routing |

### Decision: Remove `teach-init` only

| Entry Point | Action | Reason |
|-------------|--------|--------|
| `work <course>` | ✅ Keep | Session management, different purpose |
| `teach <cmd>` | ✅ Keep | Unified dispatcher (canonical) |
| `flow teach` | ✅ Keep | Some users prefer explicit `flow` prefix |
| `teach-init` | ❌ Remove | Redundant with `teach init` |

### Implementation

```zsh
# In commands/teach-init.zsh - Add deprecation warning
teach-init() {
    echo "${FLOW_COLORS[warning]}⚠️  'teach-init' is deprecated. Use 'teach init' instead.${FLOW_COLORS[reset]}"
    echo ""
    # Forward to dispatcher
    teach init "$@"
}
```

**Effort:** ⚡ Low (1 hour)

---

## 2. `teach doctor` Command

### Purpose

Validate that the teaching environment is correctly configured. Essential for debugging "why isn't this working?" issues.

### Checks to Perform

```bash
teach doctor

╭────────────────────────────────────────────────────────────╮
│  📚 Teaching Environment Health Check                       │
╰────────────────────────────────────────────────────────────╯

Dependencies:
  ✓ yq (4.35.1) - YAML processing
  ✓ git (2.43.0) - Version control
  ✓ quarto (1.4.550) - Document rendering
  ✓ gh (2.42.0) - GitHub CLI for deployment
  ⚠ examark (not found) - Exam conversion (optional)
    → Install: npm install -g examark

Project Configuration:
  ✓ .flow/teach-config.yml exists
  ✓ Config validates against schema
  ✓ Course name: STAT 440
  ✓ Semester: Spring 2026
  ✓ Dates configured (Jan 13 - May 1)

Git Setup:
  ✓ Git repository initialized
  ✓ Draft branch exists: draft
  ✓ Production branch exists: main
  ✓ Remote configured: origin
  ⚠ 3 uncommitted changes

Scholar Integration:
  ✓ Claude Code available
  ✓ scholar:teaching skills accessible
  ⚠ No lesson-plan.yml found (optional)

────────────────────────────────────────────────────────────
Summary: 11 passed, 3 warnings, 0 failures
────────────────────────────────────────────────────────────
```

### Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--quiet` | `-q` | Only show failures/warnings |
| `--fix` | | Auto-fix what's possible |
| `--json` | | Output as JSON for scripts |

### Check Categories

#### A. Dependencies (Required)

| Check | Command | Auto-Fix |
|-------|---------|----------|
| yq installed | `command -v yq` | `brew install yq` |
| git installed | `command -v git` | Manual (Xcode tools) |
| quarto installed | `command -v quarto` | `brew install --cask quarto` |
| gh installed | `command -v gh` | `brew install gh` |

#### B. Dependencies (Optional)

| Check | Command | Purpose |
|-------|---------|---------|
| examark | `command -v examark` | Exam conversion |
| claude | `command -v claude` | Scholar skills |

#### C. Project Configuration

| Check | Validation | Auto-Fix |
|-------|------------|----------|
| Config exists | `-f .flow/teach-config.yml` | `teach init` |
| Schema valid | `_teach_validate_config` | Manual |
| Course name set | `yq '.course.name'` | Manual |
| Branches defined | `yq '.branches.*'` | Add defaults |
| Dates configured | `yq '.semester_info.start_date'` | `teach dates` |

#### D. Git Status

| Check | Validation | Auto-Fix |
|-------|------------|----------|
| Is git repo | `-d .git` | `git init` |
| Draft branch exists | `git show-ref --verify` | Create branch |
| Production branch exists | `git show-ref --verify` | Create branch |
| Remote configured | `git remote -v` | Manual |
| On correct branch | `git branch --show-current` | Offer checkout |
| Clean working tree | `git status --porcelain` | Warn only |

### Implementation Outline

```zsh
_teach_doctor() {
    local quiet=false fix=false json=false
    local -i passed=0 warnings=0 failures=0

    # Parse flags
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --quiet|-q) quiet=true ;;
            --fix) fix=true ;;
            --json) json=true ;;
            *) ;;
        esac
        shift
    done

    # Header
    [[ "$quiet" == false ]] && {
        echo ""
        echo "╭────────────────────────────────────────────────────────────╮"
        echo "│  📚 Teaching Environment Health Check                       │"
        echo "╰────────────────────────────────────────────────────────────╯"
        echo ""
    }

    # Run checks
    _check_dependencies
    _check_project_config
    _check_git_status
    _check_scholar_integration

    # Summary
    echo ""
    echo "────────────────────────────────────────────────────────────"
    echo "Summary: $passed passed, $warnings warnings, $failures failures"
    echo "────────────────────────────────────────────────────────────"

    [[ $failures -gt 0 ]] && return 1
    return 0
}

_check_dep() {
    local name="$1"
    local cmd="$2"
    local fix_cmd="$3"
    local required="${4:-true}"

    if command -v "$cmd" &>/dev/null; then
        local version=$($cmd --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?')
        _doctor_pass "$name ($version)"
    elif [[ "$required" == "true" ]]; then
        _doctor_fail "$name (not found)" "$fix_cmd"
    else
        _doctor_warn "$name (not found - optional)" "$fix_cmd"
    fi
}

_doctor_pass() {
    ((passed++))
    [[ "$quiet" == false ]] && echo "  ${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $1"
}

_doctor_warn() {
    ((warnings++))
    echo "  ${FLOW_COLORS[warning]}⚠${FLOW_COLORS[reset]} $1"
    [[ -n "$2" ]] && echo "    → $2"
}

_doctor_fail() {
    ((failures++))
    echo "  ${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} $1"
    [[ -n "$2" ]] && echo "    → $2"
}
```

**Effort:** 🔧 Medium (3-4 hours)

---

## 3. Help System Enhancement

### Decision: Add `--help` + More Examples

Keep current help format structure but:
1. Add `--help` flag handling to all sub-commands
2. Add more real-world examples to each command

### Implementation

```zsh
# Add to each sub-command handler
_teach_exam() {
    # Help check first
    if [[ "$1" == "--help" || "$1" == "-h" ]]; then
        _teach_exam_help
        return 0
    fi
    # ... rest of implementation
}

_teach_exam_help() {
    echo "teach exam - Generate exam with solutions"
    echo ""
    echo "USAGE"
    echo "  teach exam <topic> [options]"
    echo ""
    echo "OPTIONS"
    echo "  --update, -u    Backup existing and regenerate"
    echo "  --version, -v   Create new version (exam-v2)"
    echo "  --dry-run, -n   Preview without executing"
    echo "  --help, -h      Show this help"
    echo ""
    echo "EXAMPLES"
    echo "  teach exam \"Midterm 1\"              Create midterm exam"
    echo "  teach exam \"Final\" --week 15        Exam for week 15 topics"
    echo "  teach exam \"Quiz 3\" --update        Regenerate with backup"
    echo "  teach exam \"Midterm 2\" --version    Create midterm-2-v2"
    echo ""
}
```

### Commands to Update

| Command | Add `--help` | Add Examples |
|---------|--------------|--------------|
| `teach init` | ✅ | 3 examples |
| `teach deploy` | ✅ | 3 examples |
| `teach exam` | ✅ | 4 examples |
| `teach lecture` | ✅ | 3 examples |
| `teach slides` | ✅ | 3 examples |
| `teach quiz` | ✅ | 3 examples |
| `teach assignment` | ✅ | 3 examples |
| `teach status` | ✅ | 2 examples |
| `teach week` | ✅ | 3 examples |
| `teach doctor` | ✅ | 3 examples |

**Effort:** 🔧 Medium (3 hours)

---

## 4. Regeneration & Backup System

### Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--update` | `-u` | Auto-backup to `.backups/`, then regenerate |
| `--version` | `-v` | Create new version (exam-v2, exam-v3) |
| `--force` | `-f` | Overwrite without backup (destructive) |
| `--dry-run` | `-n` | Preview what would happen |

### User Experience

```bash
# First time - creates exam
$ teach exam "Midterm 1"
✓ Created exams/midterm-1/

# Second time - prompts user
$ teach exam "Midterm 1"
⚠ Midterm 1 already exists at exams/midterm-1/

Options:
  1. Update (backup old, regenerate)
  2. Create new version (midterm-1-v2)
  3. View existing
  4. Cancel

Choice [1/2/3/4]: _

# With --update flag - auto-backup and regenerate
$ teach exam "Midterm 1" --update
  Backed up: exams/midterm-1/ → exams/midterm-1/.backups/midterm-1.2026-01-18-1430/
✓ Regenerated exams/midterm-1/

# With --version flag - create new version
$ teach exam "Midterm 1" --version
✓ Created exams/midterm-1-v2/

# With --dry-run - preview only
$ teach exam "Midterm 1" --update --dry-run
Would backup: exams/midterm-1/ → exams/midterm-1/.backups/midterm-1.2026-01-18-1430/
Would regenerate: exams/midterm-1/
(dry-run, no changes made)
```

### Backup Storage

**Location:** `.backups/` folder inside each content folder

```
exams/
├── midterm-1/
│   ├── exam.qmd
│   ├── solutions.qmd
│   └── .backups/
│       ├── midterm-1.2026-01-18-1430/
│       └── midterm-1.2026-01-15-0900/
└── final/
    ├── exam.qmd
    └── .backups/
```

**Naming:** Timestamp format `<name>.<YYYY-MM-DD-HHMM>/`

### Backup Configuration in teach-config.yml

```yaml
# .flow/teach-config.yml
backups:
  # Whether to gitignore .backups folders (user choice during init)
  gitignore: true  # or false

  # Retention policies by content type
  retention:
    assessments: archive    # exams, quizzes, assignments → archive per semester
    syllabi: archive        # syllabi, rubrics → archive per semester
    lectures: semester      # lectures, slides → keep current semester only

  # Archive location for semester-end
  archive_dir: ".flow/archives"
```

### Retention Policies

| Content Type | Policy | Behavior |
|--------------|--------|----------|
| **Assessments** (exams, quizzes, assignments) | `archive` | Move to archive at semester end, keep forever |
| **Syllabi & Rubrics** | `archive` | Move to archive at semester end, keep forever |
| **Lectures & Slides** | `semester` | Delete `.backups/` at semester end |

### Archive Command

```bash
# At semester end, run:
$ teach archive

Archiving Spring 2026 backups...
  ✓ Moved 12 assessment backups to .flow/archives/spring-2026/
  ✓ Moved 2 syllabus backups to .flow/archives/spring-2026/
  ✓ Deleted 45 lecture backups (semester retention policy)

Archive complete: .flow/archives/spring-2026/
```

### Implementation

```zsh
_teach_backup_content() {
    local content_path="$1"
    local content_name="$(basename "$content_path")"
    local backup_dir="$content_path/.backups"
    local timestamp=$(date +%Y-%m-%d-%H%M)
    local backup_path="$backup_dir/${content_name}.${timestamp}"

    mkdir -p "$backup_dir"

    # Copy content to backup (exclude .backups itself)
    rsync -a --exclude='.backups' "$content_path/" "$backup_path/"

    echo "$backup_path"
}

_teach_get_retention_policy() {
    local content_type="$1"
    local config_file=".flow/teach-config.yml"

    # Map content type to policy
    case "$content_type" in
        exam|quiz|assignment)
            yq '.backups.retention.assessments // "archive"' "$config_file"
            ;;
        syllabus|rubric)
            yq '.backups.retention.syllabi // "archive"' "$config_file"
            ;;
        lecture|slides)
            yq '.backups.retention.lectures // "semester"' "$config_file"
            ;;
        *)
            echo "archive"  # Default to safe retention
            ;;
    esac
}
```

**Effort:** 🔧 Medium (4-5 hours)

---

## 5. Task Breakdown & Interactive Review

### Task Explanations

Let me explain each implementation task in detail so you can decide which to keep, modify, or remove.

#### Task 1: Deprecate `teach-init` command

**What it does:**
- Adds warning message when user runs `teach-init`
- Redirects to `teach init` (dispatcher version)
- Updates documentation to show `teach init` as canonical

**Code changes:**
```zsh
# In commands/teach-init.zsh
teach-init() {
    echo "⚠️  'teach-init' is deprecated. Use 'teach init' instead."
    teach init "$@"
}
```

**Files modified:** `commands/teach-init.zsh` (5 lines)

**Why:** Simplifies command structure - one way to do things instead of two.

---

#### Task 2: Basic `teach doctor` skeleton

**What it does:**
- Creates new `teach doctor` command
- Checks if yq, git, quarto, gh are installed
- Shows simple pass/fail output

**Example output:**
```
Dependencies:
  ✓ yq (4.35.1)
  ✓ git (2.43.0)
  ✗ gh (not found)
    → Install: brew install gh
```

**Files modified:** `lib/dispatchers/teach-dispatcher.zsh` (~50 lines)

**Why:** Quick way to debug "why isn't this working?" issues.

---

#### Task 3: Add `--help` to all sub-commands

**What it does:**
- Every `teach` sub-command responds to `--help` flag
- Shows usage, options, examples

**Example:**
```bash
$ teach exam --help

teach exam - Generate exam with solutions

USAGE
  teach exam <topic> [options]

OPTIONS
  --help, -h      Show this help

EXAMPLES
  teach exam "Midterm 1"
```

**Files modified:** `lib/dispatchers/teach-dispatcher.zsh` (~10 functions, 3-5 lines each)

**Why:** Discoverability - users can learn commands without reading docs.

---

#### Task 4: Full `teach doctor` implementation

**What it does:**
- Extends Task 2 with more checks:
  - Project config validation
  - Git branch status
  - Scholar integration
- Adds `--fix` flag to auto-install missing tools
- Adds `--json` output for scripts

**Example:**
```bash
$ teach doctor --fix
  ✗ yq (not found)
    → Installing: brew install yq
  ✓ Installed yq (4.35.1)
```

**Files modified:** `lib/dispatchers/teach-dispatcher.zsh` (~150 lines)

**Why:** Comprehensive environment validation + auto-fix capability.

---

#### Task 5: Backup system implementation

**What it does:**
- Creates `.backups/` folders inside content directories
- Implements `--update` flag (backup old, regenerate)
- Implements `--version` flag (create exam-v2, exam-v3)
- Adds retention policies (archive assessments, delete old lectures)

**Example:**
```bash
$ teach exam "Midterm 1" --update
  Backed up: exams/midterm-1/ → exams/midterm-1/.backups/midterm-1.2026-01-18-1430/
✓ Regenerated exams/midterm-1/
```

**Files modified:**
- `lib/dispatchers/teach-dispatcher.zsh` (~200 lines)
- `.flow/teach-config.yml` schema (add `backups:` section)

**Why:** Prevents data loss, preserves assessment history for legal/academic records.

---

#### Task 6: Archive command enhancement

**What it does:**
- Enhances `teach archive` to handle backups
- Moves assessment/syllabus backups to `.flow/archives/spring-2026/`
- Deletes lecture backups (ephemeral content)

**Example:**
```bash
$ teach archive

Archiving Spring 2026 backups...
  ✓ Moved 12 assessment backups to .flow/archives/spring-2026/
  ✓ Deleted 45 lecture backups (semester retention policy)
```

**Files modified:** `lib/dispatchers/teach-dispatcher.zsh` (~80 lines)

**Why:** Clean semester transitions, preserve what matters, delete noise.

---

## 5.5. Interactive Review Results (2026-01-18)

### Your Decisions

| Task | Original Plan | Your Decision |
|------|---------------|---------------|
| **Task 1: teach-init** | Deprecate with warning | ❌ Remove entirely |
| **Task 2: Basic doctor** | Check yq, git, quarto, gh | ✅ Keep + add config validation |
| **Task 3: --help flags** | Add to all sub-commands | ✅ Keep as-is |
| **Task 4: Full doctor** | Config, git, --fix, --json | ✅ Keep as-is |
| **Task 5: Backup system** | Full implementation | ✅ Keep as-is |
| **Task 6: Archive** | Auto-delete by policy | ⚠️ Prompt before deleting |

### Additional Enhancements Requested

#### Phase 1 (v5.14.0) - Priority

| Enhancement | Description |
|-------------|-------------|
| **teach status** | Add: deployment status (last deploy, PR status) + backup summary (# backups, last backup time) |
| **teach deploy** | Add: preview changes before creating PR |
| **Scholar wrappers** | Add: templates (exam types) + lesson plan integration (auto-load lesson-plan.yml) |
| **teach init** | Add: project templates (R/Python/Quarto) + GitHub setup - OPTIONAL with flags |

#### Phase 2 (v5.15.0+) - Future

| Enhancement | Description |
|-------------|-------------|
| **teach week** | Add: topic preview from config + content checklist (materials exist) |
| **teach dates** | Add: holiday detection (auto-detect from calendar API) |
| **teach config** | Add: interactive editor (guided config editing) |

### Testing Requirements

- ✅ Unit tests (individual functions)
- ✅ Integration tests (end-to-end workflows)
- ✅ Validate in scholar-demo-course

---

## 5.6. Revised Task List (Post-Review)

### Phase 1 Tasks (v5.14.0)

| # | Task | Effort | Priority |
|---|------|--------|----------|
| 1 | **Remove teach-init** | ⚡ 30m | High |
|   | Delete standalone command entirely | | |
| 2 | **Basic teach doctor** | ⚡ 2h | High |
|   | Check: yq, git, quarto, gh, .flow/teach-config.yml | | |
| 3 | **Add --help to all sub-commands** | ⚡ 1h | Medium |
|   | All 10 sub-commands respond to --help | | |
| 4 | **Full teach doctor** | 🔧 3h | High |
|   | Config validation, git checks, --fix flag, --json output | | |
| 5 | **Backup system implementation** | 🔧 5h | High |
|   | .backups/ folders, --update, --version, retention policies | | |
| 6 | **Archive with prompts** | 🔧 2h | Medium |
|   | Prompt before deleting backups, respect retention policies | | |
| 7 | **teach status enhancements** | 🔧 2h | Medium |
|   | Add deployment status + backup summary | | |
| 8 | **teach deploy preview** | 🔧 1h | Medium |
|   | Show what changed before creating PR | | |
| 9 | **Scholar wrapper enhancements** | 🔧 4h | High |
|   | Templates + lesson plan integration | | |
| 10 | **teach init enhancements** | 🔧 3h | Medium |
|    | Project templates + GitHub setup (optional flags) | | |

**Phase 1 Total:** ~23 hours

### Phase 2 Tasks (v5.15.0+)

| # | Task | Effort | Priority |
|---|------|--------|----------|
| 11 | **teach week enhancements** | 🔧 2h | Low |
|    | Topic preview + content checklist | | |
| 12 | **teach dates holiday detection** | 🔧 3h | Low |
|    | Auto-detect holidays from calendar API | | |
| 13 | **teach config interactive editor** | 🔧 4h | Low |
|    | Guided config editing with prompts | | |

**Phase 2 Total:** ~9 hours

---

## 6. Implementation Plan

### Phase 1: Foundation (v5.14.0-alpha)

```
Week 1:
├── Day 1: teach doctor (basic)
│   ├── Dependency checks
│   ├── Config validation
│   └── Basic output format
│
├── Day 2: Deprecation warnings
│   ├── teach-init → teach init
│   └── flow teach → teach
│
└── Day 3: Help utilities
    ├── _help_header()
    ├── _help_section()
    └── Update main dispatcher help
```

### Phase 2: Enhancement (v5.14.0-beta)

```
Week 2:
├── Day 1: Full teach doctor
│   ├── Git checks
│   ├── Scholar checks
│   ├── --fix flag
│   └── --json output
│
├── Day 2-3: --update flags
│   ├── Backup logic
│   ├── Interactive prompts
│   └── Apply to all Scholar wrappers
│
└── Day 4: Sub-command help
    ├── teach deploy --help
    ├── teach init --help
    ├── teach status --help
    └── All Scholar command help
```

### Phase 3: Polish (v5.14.0)

```
Week 3:
├── Documentation updates
├── Test suite expansion
├── Context-aware help
└── Release
```

---

## 7. Finalized Decisions

All decisions have been approved during interactive brainstorm session (2026-01-18).

| # | Question | Decision | Rationale |
|---|----------|----------|-----------|
| 1 | Command deprecation | Remove `teach-init` only | Keep `flow teach` for users who prefer explicit prefix |
| 2 | `teach doctor` scope | Full implementation | Dependencies, config, git, scholar + `--fix`, `--json` |
| 3 | Help system | Add `--help` + examples | Keep current format, just add discoverability |
| 4 | Regeneration flags | `--update`, `--version`, `--dry-run` | Flexible options for different workflows |
| 5 | Backup location | `.backups/` inside content folder | Close to source, easy to find |
| 6 | Backup naming | Timestamp (`name.2026-01-18-1430`) | Sortable, clear when created |
| 7 | Gitignore backups | User choice in config | Configurable via `backups.gitignore` in teach-config.yml |
| 8 | Assessment retention | Archive per semester | Legal/academic record preservation |
| 9 | Syllabi retention | Archive per semester | Contractual document preservation |
| 10 | Lecture retention | Current semester only | Ephemeral, easily regenerated |

---

## 8. Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| `teach doctor` catches issues | 90%+ | User reports |
| Help discoverable | < 2 commands to find | User testing |
| `--update` prevents data loss | 100% | Backups created |
| Deprecation warnings shown | 100% | Test coverage |

---

## 9. Test Plan

### Unit Tests

```zsh
# tests/test-teach-doctor.zsh
test_doctor_detects_missing_yq() {
    # Mock missing yq
    unset -f yq
    output=$(teach doctor 2>&1)
    assert_contains "$output" "yq (not found)"
}

test_doctor_detects_missing_config() {
    cd /tmp/empty-dir
    output=$(teach doctor 2>&1)
    assert_contains "$output" ".flow/teach-config.yml"
}

test_doctor_quiet_mode() {
    output=$(teach doctor --quiet 2>&1)
    # Should only show warnings/failures
    refute_contains "$output" "✓"
}
```

```zsh
# tests/test-teach-update-flag.zsh
test_update_creates_backup() {
    mkdir -p exams/midterm-1
    teach exam "Midterm 1" --update
    assert_dir_exists "exams/midterm-1.bak.*"
}

test_force_no_backup() {
    mkdir -p exams/midterm-1
    teach exam "Midterm 1" --force
    refute_dir_exists "exams/midterm-1.bak.*"
}
```

### Integration Tests

```bash
# E2E: teach doctor in demo course
cd ~/projects/teaching/scholar-demo-course
teach doctor
# Should pass all checks

# E2E: teach doctor with missing yq
PATH=/bin:/usr/bin teach doctor
# Should show yq failure

# E2E: --update flag
teach exam "Test Exam"
teach exam "Test Exam" --update
ls exams/
# Should show test-exam/ and test-exam.bak.*
```

---

## 10. Files to Create/Modify

### New Files

| File | Purpose | Lines |
|------|---------|-------|
| None | (All in existing dispatcher) | |

### Modified Files

| File | Changes | Lines Changed |
|------|---------|---------------|
| `lib/dispatchers/teach-dispatcher.zsh` | Add `_teach_doctor()`, update help, add flag handling | ~200 |
| `commands/teach-init.zsh` | Add deprecation warning | ~5 |
| `lib/core.zsh` | Add `_help_header()`, `_help_section()` utilities | ~50 |
| `docs/reference/TEACH-DISPATCHER-REFERENCE.md` | Document new features | ~100 |

---

## 11. Next Steps

1. **Review this spec**
2. **Decide on decision points** (Section 7)
3. **Create implementation branch:**
   ```bash
   git worktree add ~/.git-worktrees/flow-cli-teach-v3 \
     -b feature/teach-v3-enhancements dev
   ```
4. **Start with Quick Wins** (teach doctor skeleton)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-18 | Initial draft from brainstorm session |
| 2.0 | 2026-01-18 | Interactive review - finalized core decisions |
| 3.0 | 2026-01-18 | Deep interactive review - task explanations + subcommand enhancements |

---

**Spec Status:** ✅ Approved (Comprehensive)
**Estimated Effort:**
- Phase 1 (v5.14.0): ~23 hours
- Phase 2 (v5.15.0+): ~9 hours
**Risk Level:** Low (incremental, backwards compatible)

## Summary of Changes (v3.0)

### Core Modifications
- ❌ teach-init → **Delete entirely** (not deprecate)
- ✅ teach doctor → **Add config validation** to basic version
- ⚠️ teach archive → **Prompt before deleting** (not auto-delete)

### New Enhancements (Phase 1)
- **teach status**: Deployment status + backup summary
- **teach deploy**: Preview changes before PR
- **Scholar wrappers**: Templates + lesson plan integration
- **teach init**: Project templates + GitHub setup (optional flags)

### Future Enhancements (Phase 2)
- **teach week**: Topic preview + content checklist
- **teach dates**: Holiday detection
- **teach config**: Interactive editor

### Testing Strategy
- Unit tests + Integration tests + scholar-demo-course validation

## Next Steps

1. **Create implementation branch:**
   ```bash
   git worktree add ~/.git-worktrees/flow-cli-teach-v3 \
     -b feature/teach-v3-enhancements dev
   ```

2. **Phase 1 Implementation Order:**
   - Task 1: Remove teach-init (30min)
   - Task 2: Basic teach doctor + config validation (2h)
   - Task 4: Full teach doctor with --fix (3h)
   - Task 5: Backup system (5h)
   - Task 3: Add --help flags (1h)
   - Task 7: teach status enhancements (2h)
   - Task 8: teach deploy preview (1h)
   - Task 9: Scholar wrapper enhancements (4h)
   - Task 6: Archive with prompts (2h)
   - Task 10: teach init enhancements (3h)

3. **Testing & Validation:**
   - Unit tests for each task
   - Integration tests in scholar-demo-course
   - Update test suite in `tests/test-teach-*.zsh`
