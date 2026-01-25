# SPEC: flow-cli Teaching Wrappers for Scholar

**Feature:** Unified teaching commands that wrap Scholar plugin
**Status:** implemented
**Created:** 2026-01-14
**Implemented:** 2026-01-14
**Target:** flow-cli v5.8.0

---

## Overview

This specification defines flow-cli wrapper commands that invoke Scholar teaching commands, providing a unified CLI experience for instructors.

**Principle:** Teaching will ALWAYS be coordinated with Scholar.

### Goals

1. **Unified Interface:** Single CLI (`teach`) for all teaching tasks
2. **Validation:** Check prerequisites before Scholar invocation
3. **Error Handling:** Clear error messages and recovery guidance
4. **Future-Proof:** Prepare for Scholar v2.1.0 dual config system

---

## Command Mapping

| flow-cli Command | Scholar Command | Arguments | Priority |
|------------------|-----------------|-----------|----------|
| `teach lecture "Topic"` | `/teaching:lecture` (NEW) | topic, --outline, --notes | PRIMARY |
| `teach slides "Topic"` | `/teaching:slides` | topic, --format, --theme | High |
| `teach exam "Topic"` | `/teaching:exam` | topic, --questions, --duration | High |
| `teach quiz "Topic"` | `/teaching:quiz` | topic, --questions, --time-limit | High |
| `teach assignment "Topic"` | `/teaching:assignment` | topic, --due-date, --points | Medium |
| `teach syllabus` | `/teaching:syllabus` | (uses config) | Medium |
| `teach rubric "Assignment"` | `/teaching:rubric` | assignment-name, --criteria | Medium |
| `teach feedback "Student"` | `/teaching:feedback` | student-work, --tone | Low |
| `teach demo` | `/teaching:demo` | --course-name, --force | Low |

**Note:** `/teaching:lecture` is a NEW command that may need to be added to Scholar.

---

## Flag Reference

### Universal Flags (all wrappers)

| Flag | Description | Passed to Scholar |
|------|-------------|-------------------|
| `--dry-run` | Preview output without saving | Yes |
| `--format FORMAT` | Output format: markdown, quarto, latex, json, qti | Yes |
| `--output PATH` | Custom output path | Yes |
| `--verbose` | Show Scholar command being executed | No (wrapper only) |
| `--help` | Show wrapper help + Scholar command help | No (wrapper only) |

### Command-Specific Flags

#### `teach lecture`

| Flag | Description |
|------|-------------|
| `--outline` | Generate outline only (no full content) |
| `--notes` | Include speaker notes |
| `--from-plan WEEK` | Generate from lesson plan file |

#### `teach slides`

| Flag | Description |
|------|-------------|
| `--theme NAME` | Slide theme (default, academic, minimal) |
| `--from-lecture FILE` | Generate from lecture file |

#### `teach exam`

| Flag | Description |
|------|-------------|
| `--questions N` | Number of questions (default: 20) |
| `--duration MIN` | Time limit in minutes (default: 120) |
| `--types TYPES` | Question types (mc,sa,essay,calc) |

#### `teach quiz`

| Flag | Description |
|------|-------------|
| `--questions N` | Number of questions (default: 10) |
| `--time-limit MIN` | Time limit in minutes (default: 15) |

#### `teach assignment`

| Flag | Description |
|------|-------------|
| `--due-date DATE` | Due date (YYYY-MM-DD) |
| `--points N` | Total points (default: 100) |

---

## Wrapper Behavior

### Execution Flow

```bash
# User runs:
teach exam "Hypothesis Testing" --dry-run --format quarto

# Wrapper executes:
1. _teach_preflight()              # Validate prerequisites
2. _teach_parse_args()             # Parse wrapper + Scholar args
3. _teach_build_command()          # Build Scholar command string
4. _teach_execute()                # Run Claude with Scholar command
5. _teach_postprocess()            # Handle output, show summary
```

### Preflight Checks

```zsh
_teach_preflight() {
    # 1. Check config exists
    if [[ ! -f ".flow/teach-config.yml" ]]; then
        _teach_error "No .flow/teach-config.yml found" \
            "Run 'teach init' first or create config manually"
        return 1
    fi

    # 2. Check Scholar section exists (warning only)
    if ! grep -q "^scholar:" .flow/teach-config.yml; then
        _teach_warn "No 'scholar:' section in config" \
            "Scholar commands will use defaults"
    fi

    # 3. Check Claude Code available
    if ! command -v claude &>/dev/null; then
        _teach_error "Claude Code CLI not found" \
            "Install: https://claude.ai/code"
        return 1
    fi

    return 0
}
```

### Command Building

```zsh
_teach_build_command() {
    local subcommand="$1"
    shift
    local args=("$@")

    # Map subcommand to Scholar command
    local scholar_cmd
    case "$subcommand" in
        lecture)    scholar_cmd="/teaching:lecture" ;;
        slides)     scholar_cmd="/teaching:slides" ;;
        exam)       scholar_cmd="/teaching:exam" ;;
        quiz)       scholar_cmd="/teaching:quiz" ;;
        assignment) scholar_cmd="/teaching:assignment" ;;
        syllabus)   scholar_cmd="/teaching:syllabus" ;;
        rubric)     scholar_cmd="/teaching:rubric" ;;
        feedback)   scholar_cmd="/teaching:feedback" ;;
        demo)       scholar_cmd="/teaching:demo" ;;
        *)
            _teach_error "Unknown subcommand: $subcommand"
            return 1
            ;;
    esac

    # Build full command
    echo "claude --print \"$scholar_cmd ${args[*]}\""
}
```

---

## Error Handling

### Error Categories

| Error | Message | Recovery |
|-------|---------|----------|
| No config | "No .flow/teach-config.yml found" | `teach init` |
| No Claude | "Claude Code CLI not found" | Install link |
| Scholar error | (Pass through Scholar error) | Show Scholar help |
| Invalid topic | "Topic required: teach exam \"Topic\"" | Show usage |
| Network error | "Claude API unreachable" | Retry guidance |
| Invalid flag | "Unknown flag: --foo" | Show valid flags |

### Error Format

```zsh
_teach_error() {
    local message="$1"
    local recovery="$2"

    echo "❌ teach: $message" >&2
    [[ -n "$recovery" ]] && echo "   $recovery" >&2
    return 1
}

_teach_warn() {
    local message="$1"
    local note="$2"

    echo "⚠️  teach: $message" >&2
    [[ -n "$note" ]] && echo "   $note" >&2
}
```

---

## Configuration

### How Wrappers Use Config

1. **Preflight:** Check `.flow/teach-config.yml` exists
2. **Scholar Section:** Pass to Scholar for context-aware generation
3. **Defaults:** Use config values when flags not provided

### Config Integration

```yaml
# .flow/teach-config.yml
scholar:
  course_info:
    level: "undergraduate"
    field: "statistics"
    difficulty: "intermediate"

  defaults:
    exam_format: "quarto"      # Default --format for teach exam
    lecture_format: "quarto"   # Default --format for teach lecture
```

---

## Primary Workflow: Lesson Plan → Lecture

### User's Desired Workflow

```
1. Create/update lesson plan (YAML)
   └── .flow/lesson-plans/week05.yml

2. Generate lecture from plan
   └── teach lecture --from-plan week05

3. Auto-sync to JSON + validate
   └── Automatic via file watcher (v2.1.0)

4. Generate slides from lecture
   └── teach slides --from-lecture week05

5. Deploy to students
   └── teach deploy
```

### Implementation

```zsh
# teach lecture --from-plan week05
_teach_lecture_from_plan() {
    local week="$1"
    local plan_file=".flow/lesson-plans/${week}.yml"

    if [[ ! -f "$plan_file" ]]; then
        _teach_error "Lesson plan not found: $plan_file" \
            "Create the lesson plan file first"
        return 1
    fi

    # Read lesson plan and pass to Scholar
    local topic=$(yq '.topic' "$plan_file")
    local objectives=$(yq '.objectives | join(", ")' "$plan_file")

    # Build Scholar command with context
    claude --print "/teaching:lecture \"$topic\" --objectives \"$objectives\""
}
```

---

## v2.1.0 Integration

### Current Behavior (v2.0.1)

```bash
# Simple: Just check .flow/teach-config.yml
teach exam "Topic"  # Scholar reads YAML directly
```

### Future Behavior (v2.1.0)

```bash
# Enhanced: Trigger sync before Scholar commands
teach exam "Topic"
# 1. Check if YAML changed → trigger JSON sync
# 2. Validate JSON schema
# 3. Run Scholar command
# 4. Auto-sync any new files
```

### Sync Hook (future)

```zsh
_teach_sync_config() {
    # Call Scholar's sync engine before command
    if command -v scholar-sync &>/dev/null; then
        scholar-sync --quiet
    fi
}
```

---

## Implementation Notes

### File Structure

```
lib/dispatchers/
└── teach-dispatcher.zsh
    ├── _teach_scholar_*        # Scholar wrapper functions
    ├── _teach_preflight()      # Validation
    ├── _teach_build_command()  # Command building
    └── _teach_execute()        # Execution

completions/
└── _teach
    └── (Add Scholar subcommands)
```

### Dispatcher Extension

Add to existing `teach-dispatcher.zsh`:

```zsh
teach() {
    case "$1" in
        # Existing flow-cli commands
        init|deploy|status|week|archive|config)
            _teach_$1 "${@:2}"
            ;;

        # NEW: Scholar wrappers
        lecture|slides|exam|quiz|assignment|syllabus|rubric|feedback|demo)
            _teach_scholar_wrapper "$@"
            ;;

        help|--help|-h)
            _teach_help
            ;;

        *)
            _teach_help
            ;;
    esac
}
```

---

## Testing Strategy

### Unit Tests

1. **Preflight validation**
   - Missing config file
   - Missing scholar section (warning)
   - Missing Claude CLI

2. **Command building**
   - All 9 subcommands map correctly
   - Flags pass through correctly
   - Topic escaping works

3. **Error handling**
   - All error categories tested
   - Recovery messages shown

### Integration Tests

1. **End-to-end workflow**
   - teach exam generates via Scholar
   - Output saved correctly
   - Dry-run doesn't save

2. **Config integration**
   - Scholar reads config correctly
   - Defaults applied when flags missing

### Test File

```zsh
# tests/test-teach-scholar-wrappers.zsh

test_teach_exam_dry_run() {
    # Setup
    create_test_config

    # Execute
    output=$(teach exam "Test Topic" --dry-run 2>&1)

    # Assert
    assert_contains "$output" "Preview"
    assert_not_contains "$output" "Saved"
}
```

---

## Acceptance Criteria

### Minimum Viable

- [ ] `teach exam "Topic"` invokes Scholar and generates exam
- [ ] `teach --help` shows all Scholar subcommands
- [ ] Preflight checks run before Scholar invocation
- [ ] Errors show clear messages with recovery guidance

### Full Implementation

- [ ] All 9 wrappers implemented
- [ ] All flags pass through correctly
- [ ] `--from-plan` workflow works for lecture
- [ ] Config defaults applied
- [ ] 20+ tests passing

---

## Timeline

**Status:** Spec only (no implementation)
**Target:** flow-cli v5.8.0
**Estimate:** 2-3 hours implementation

---

## Scholar Command Status

**Last Checked:** 2026-01-14 17:15
**Scholar Version:** v2.0.1 (released 2026-01-13)
**Scholar Tests:** 547 tests, 100% pass rate
**Next Scholar Version:** v2.1.0 (58-71 hours, 7-9 weeks - Unified Course Architecture)

> **Note:** Update this table periodically to track Scholar progress and ensure wrappers stay in sync.

| Scholar Command | Status | flow-cli Wrapper | Ready to Implement | Notes |
|-----------------|--------|------------------|-------------------|-------|
| `/teaching:exam` | ✅ v2.0.1 | 📋 Spec | ✅ Yes | High priority - `--dry-run` supported |
| `/teaching:quiz` | ✅ v2.0.1 | 📋 Spec | ✅ Yes | High priority - `--dry-run` supported |
| `/teaching:slides` | ✅ v2.0.1 | 📋 Spec | ✅ Yes | High priority - `--dry-run` supported |
| `/teaching:lecture` | ⏳ **NOT IMPLEMENTED** | 📋 Spec | ❌ Awaiting Scholar | Generator exists internally, no command exposed yet |
| `/teaching:assignment` | ✅ v2.0.1 | 📋 Spec | ✅ Yes | Medium priority - `--dry-run` supported |
| `/teaching:syllabus` | ✅ v2.0.1 | 📋 Spec | ✅ Yes | Medium priority - `--dry-run` supported |
| `/teaching:rubric` | ✅ v2.0.1 | 📋 Spec | ✅ Yes | Medium priority - `--dry-run` supported |
| `/teaching:feedback` | ✅ v2.0.1 | 📋 Spec | ✅ Yes | Low priority - `--dry-run` supported |
| `/teaching:demo` | ✅ v2.0.1 | 📋 Spec | ✅ Yes | Low priority - creates STAT-101 demo |

### `/teaching:lecture` Status

**Current State:** NOT exposed as command (internal generator only)
**Location:** `scholar/src/teaching/generators/lecture.js` (exists)
**Estimated Work:** 4-6 hours (per original Scholar spec)
**Blocking:** Lesson Plan → Lecture workflow requires this command

**Options:**
1. **Wait for Scholar v2.1.0** - Lecture command may be added as part of unified architecture
2. **Request feature** - Open issue on Scholar repo requesting `/teaching:lecture`
3. **Use `/teaching:slides`** - Partial workaround (slides only, no lecture notes)

### Coordination Checklist

Before implementing any wrapper:

- [ ] Check Scholar repo for latest release
- [ ] Verify command signature: `claude --print "/teaching:X --help"`
- [ ] Test manually with dry-run: `/teaching:X "Topic" --dry-run`
- [ ] Update this status table
- [ ] Update SCHOLAR-INTEGRATION.md if API changed

### Scholar Monitoring

| What to Watch | Where | Frequency |
|---------------|-------|-----------|
| New releases | Scholar GitHub releases | Weekly |
| New commands | Scholar CHANGELOG.md | On release |
| Breaking changes | Scholar migration guide | On major version |
| v2.1.0 progress | Scholar .STATUS + specs | Monthly |

### Scholar v2.1.0 Roadmap (Unified Course Architecture)

**Timeline:** 58-71 hours over 7-9 weeks
**Target:** Dual YAML/JSON config system, lesson plans, teaching styles

**Key Features for flow-cli:**
- YAML source of truth (human-editable) with JSON auto-sync
- Lesson Plan → Lecture workflow (requires `/teaching:lecture`)
- 4-layer teaching style: Global → Course → Command → Lesson
- File watcher sync (< 100ms latency)

**Specs to Watch:**
- `scholar/docs/specs/SPEC-UNIFIED-course-architecture-2026-01-13.md`
- `scholar/docs/specs/SPEC-lesson-plan-metadata-teaching-style-2026-01-13.md`

---

## Open Questions

1. **`/teaching:lecture` command:** Does Scholar need a new command for lecture notes (separate from slides)?
2. **`--from-plan` flag:** How should lesson plan YAML be structured for optimal generation?
3. **v2.1.0 sync:** When should sync be triggered (pre-command hook or manual)?

---

*Last Updated: 2026-01-14*
