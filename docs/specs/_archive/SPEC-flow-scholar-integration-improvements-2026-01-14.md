# SPEC: Flow-CLI + Scholar Teaching Integration Improvements

**Created:** 2026-01-14
**Status:** Draft
**Context:** Brainstorm session - integration review and enhancement proposals

---

## Executive Summary

This spec analyzes the current integration between flow-cli's `teach` dispatcher and Scholar's teaching commands, identifying gaps, pain points, and proposing improvements to create a more seamless teaching workflow.

---

## Current Architecture

### Two-System Model

```
┌─────────────────────────────────────────────────────────────────────┐
│  User Terminal                                                       │
│                                                                      │
│  $ teach exam "Midterm" --questions 25                              │
│         │                                                            │
│         ▼                                                            │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │  flow-cli: teach dispatcher (553 lines)                         ││
│  │  lib/dispatchers/teach-dispatcher.zsh                           ││
│  │                                                                  ││
│  │  ┌─────────────────────────────────────────────────────────────┐││
│  │  │ _teach_preflight()     - Validates environment              │││
│  │  │ _teach_build_command() - Constructs claude invocation       │││
│  │  │ _teach_execute()       - Runs command, handles output       │││
│  │  │ _teach_scholar_wrapper() - Main wrapper pattern             │││
│  │  └─────────────────────────────────────────────────────────────┘││
│  └─────────────────────────────────────────────────────────────────┘│
│         │                                                            │
│         │  claude --print "/teaching:exam"                          │
│         ▼                                                            │
│  ┌─────────────────────────────────────────────────────────────────┐│
│  │  Scholar Plugin                                                  ││
│  │  ~/.claude/plugins/scholar/                                      ││
│  │                                                                  ││
│  │  ┌───────────────────┐  ┌──────────────────────────────────────┐││
│  │  │ Config Loader     │  │ Teaching Commands                    │││
│  │  │ - course_info     │  │ - exam, quiz, syllabus               │││
│  │  │ - defaults        │  │ - assignment, rubric, slides         │││
│  │  │ - style (4-layer) │  │ - lecture*, feedback, demo           │││
│  │  └───────────────────┘  └──────────────────────────────────────┘││
│  └─────────────────────────────────────────────────────────────────┘│
│                                                                      │
│  Shared Config: .flow/teach-config.yml                              │
└─────────────────────────────────────────────────────────────────────┘
```

### Current Command Mapping (9 commands)

| flow-cli Command | Scholar Skill | Status |
|------------------|---------------|--------|
| `teach exam "Topic"` | `/teaching:exam` | ✅ Implemented |
| `teach quiz "Topic"` | `/teaching:quiz` | ✅ Implemented |
| `teach syllabus` | `/teaching:syllabus` | ✅ Implemented |
| `teach assignment "Topic"` | `/teaching:assignment` | ✅ Implemented |
| `teach rubric "Assignment"` | `/teaching:rubric` | ✅ Implemented |
| `teach slides "Topic"` | `/teaching:slides` | ✅ Implemented |
| `teach lecture "Topic"` | `/teaching:lecture` | ⚠️ In Progress (Scholar v2.1.0) |
| `teach feedback` | `/teaching:feedback` | ✅ Implemented |
| `teach demo` | `/teaching:demo` | ✅ Implemented |

### 4-Layer Teaching Style System

```
┌─────────────────────────────────────────────────────────────────┐
│ Layer 4: Lesson-Level (highest priority)                        │
│ Source: YAML frontmatter in lesson file                         │
│ Example: lesson-plan.md → style: casual, difficulty: medium     │
├─────────────────────────────────────────────────────────────────┤
│ Layer 3: Command-Level                                          │
│ Source: --style flag on CLI                                     │
│ Example: teach exam --style formal --difficulty hard            │
├─────────────────────────────────────────────────────────────────┤
│ Layer 2: Course-Level                                           │
│ Source: .flow/teach-config.yml → style section                  │
│ Example: style.formality: professional, style.pace: moderate    │
├─────────────────────────────────────────────────────────────────┤
│ Layer 1: Global Defaults (lowest priority)                      │
│ Source: Scholar plugin defaults                                 │
│ Hardcoded sensible defaults                                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## Identified Gaps & Pain Points

### 1. Critical: Missing `/teaching:lecture` Command

**Impact:** High - Blocks core lesson plan workflow
**Status:** In development (Scholar v2.1.0, Phase 3 pending)

The `teach lecture` wrapper exists in flow-cli but Scholar's `/teaching:lecture` skill is still in development. This is the most critical blocker.

**Current Workaround:**

```bash
# Users must use Claude directly
claude "Create a lecture outline for Week 3: Data Wrangling"
```

### 2. No Explicit Config Passing

**Impact:** Medium - Config discovery can fail silently

Flow-cli doesn't explicitly pass the config file path to Scholar. Scholar searches parent directories, which works but is fragile.

**Current Flow:**

```bash
# flow-cli
teach exam "Midterm"
# Translates to:
claude --print "/teaching:exam" "Midterm"
# Scholar independently searches for .flow/teach-config.yml
```

**Problem:** If user runs from a subdirectory without config, Scholar uses defaults silently.

### 3. Limited Flag Validation

**Impact:** Low-Medium - Poor error messages

Flow-cli passes flags to Scholar without validation. Invalid flags fail inside Claude with cryptic errors.

**Example:**

```bash
teach exam --invalid-flag "Midterm"
# Results in Claude error, not helpful flow-cli error
```

### 4. No Bidirectional State Sync

**Impact:** Medium - Manual sync required

When Scholar generates content (exam, quiz), there's no automatic:
- Git staging of new files
- Update to `.STATUS` file
- Notification of what was created

### 5. Missing Interactive Mode

**Impact:** Medium - ADHD friction

All Scholar commands run non-interactively via `--print`. Users can't iteratively refine output without starting new sessions.

### 6. No Progress Feedback

**Impact:** Medium - ADHD friction

Long-running Scholar commands (like generating a full syllabus) show no progress indication.

### 7. Inconsistent Output Locations

**Impact:** Low - Requires manual organization

Scholar generates files but placement varies:
- Exams might go to `exams/`
- Quizzes might go to `quizzes/`
- Sometimes to current directory

No standardized output directory configuration in flow-cli.

---

## Enhancement Proposals

### 🎯 Enhancement 1: Explicit Config Path Passing

**Priority:** High | **Effort:** 2-4 hours | **Impact:** High

Add `--config` flag support to pass config path explicitly.

**Implementation in flow-cli:**

```bash
# In _teach_build_command()
local config_path=$(_flow_find_teach_config)
if [[ -n "$config_path" ]]; then
    cmd+=" --config \"$config_path\""
fi

# New helper
_flow_find_teach_config() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -f "$dir/.flow/teach-config.yml" ]]; then
            echo "$dir/.flow/teach-config.yml"
            return 0
        fi
        dir="${dir:h}"
    done
}
```

**Scholar changes:** Accept `--config` flag in teaching commands.

### 🎯 Enhancement 2: Output Directory Configuration

**Priority:** Medium | **Effort:** 4-6 hours | **Impact:** Medium

Add standardized output paths in config.

**Config addition (.flow/teach-config.yml):**

```yaml
output:
  exams: exams/
  quizzes: quizzes/
  assignments: assignments/
  lectures: lectures/
  slides: slides/
  rubrics: rubrics/
```

**Flow-cli change:**

```bash
# After Scholar generates content
_teach_post_process() {
    local output_type="$1"
    local generated_file="$2"
    local target_dir=$(_teach_get_output_dir "$output_type")

    if [[ -n "$target_dir" ]]; then
        mkdir -p "$target_dir"
        mv "$generated_file" "$target_dir/"
        _flow_log_success "Created: $target_dir/$(basename $generated_file)"
    fi
}
```

### 🎯 Enhancement 3: Flag Validation Layer

**Priority:** Medium | **Effort:** 3-4 hours | **Impact:** Medium

Validate flags before passing to Scholar.

**Implementation:**

```bash
# Known flags per command
typeset -A TEACH_EXAM_FLAGS=(
    [questions]="number"
    [duration]="number"
    [difficulty]="easy|medium|hard"
    [format]="markdown|latex|quarto"
)

_teach_validate_flags() {
    local cmd="$1"
    shift
    local -A valid_flags

    case "$cmd" in
        exam) valid_flags=("${(@kv)TEACH_EXAM_FLAGS}") ;;
        quiz) valid_flags=("${(@kv)TEACH_QUIZ_FLAGS}") ;;
        # ...
    esac

    for arg in "$@"; do
        if [[ "$arg" == --* ]]; then
            local flag="${arg%%=*}"
            flag="${flag#--}"
            if [[ -z "${valid_flags[$flag]}" ]]; then
                _flow_log_error "Unknown flag: --$flag"
                _flow_log_info "Valid flags: ${(k)valid_flags}"
                return 1
            fi
        fi
    done
}
```

### 🎯 Enhancement 4: Post-Generation Hooks

**Priority:** Medium | **Effort:** 4-6 hours | **Impact:** High

Auto-process generated content.

**Implementation:**

```bash
_teach_post_hooks() {
    local generated_file="$1"

    # 1. Git stage (optional, configurable)
    if [[ "$TEACH_AUTO_STAGE" == "true" ]]; then
        git add "$generated_file"
        _flow_log_success "Staged: $generated_file"
    fi

    # 2. Update .STATUS
    _teach_update_status "Generated $generated_file"

    # 3. Show summary
    _teach_show_summary "$generated_file"
}

_teach_show_summary() {
    local file="$1"
    local lines=$(wc -l < "$file")
    local words=$(wc -w < "$file")

    echo ""
    echo "📄 Generated: $(basename $file)"
    echo "   Lines: $lines | Words: $words"
    echo "   Path: $file"
    echo ""
    echo "Next steps:"
    echo "  • Review: $EDITOR $file"
    echo "  • Deploy: teach deploy"
}
```

### 🎯 Enhancement 5: Interactive Mode Support

**Priority:** Low-Medium | **Effort:** 6-8 hours | **Impact:** Medium

Add `--interactive` flag for iterative refinement.

**Implementation:**

```bash
teach exam --interactive "Midterm"

# Flow:
# 1. Generate initial draft
# 2. Open in $EDITOR
# 3. Prompt: "Refine? (y/n/done)"
# 4. If y: re-run with feedback
# 5. Loop until done
```

### 🎯 Enhancement 6: Progress Indicator

**Priority:** Low | **Effort:** 2-3 hours | **Impact:** Medium (ADHD)

Show spinner/progress for long operations.

**Implementation:**

```bash
_teach_with_progress() {
    local cmd="$1"
    local msg="$2"

    # Start spinner
    _flow_spinner_start "$msg"

    # Run command
    eval "$cmd"
    local status=$?

    # Stop spinner
    _flow_spinner_stop

    return $status
}
```

### 🎯 Enhancement 7: teach status Integration

**Priority:** Medium | **Effort:** 3-4 hours | **Impact:** High

Show Scholar-generated content in `teach status`.

**Implementation:**

```bash
_teach_status_enhanced() {
    # Current status display
    _teach_status_basic

    # Add generated content summary
    echo ""
    echo "📝 Generated Content:"

    for dir in exams quizzes assignments; do
        if [[ -d "$dir" ]]; then
            local count=$(ls -1 "$dir" 2>/dev/null | wc -l)
            if [[ $count -gt 0 ]]; then
                echo "   $dir/: $count files"
            fi
        fi
    done

    # Recent generations
    echo ""
    echo "🕐 Recent:"
    find . -name "*.md" -newer .flow/teach-config.yml -type f 2>/dev/null | head -5 | while read f; do
        echo "   $(basename $f) - $(stat -f '%Sm' -t '%Y-%m-%d' $f)"
    done
}
```

### 🎯 Enhancement 8: Unified teach help

**Priority:** Low | **Effort:** 2-3 hours | **Impact:** Low

Combine flow-cli and Scholar help in one view.

**Implementation:**

```bash
_teach_help() {
    # Flow-cli native commands
    echo "Flow-CLI Commands:"
    echo "  teach init      Initialize teaching project"
    echo "  teach deploy    Deploy to production"
    echo "  teach status    Show project status"
    echo "  teach week      Current week info"
    echo ""

    # Scholar wrapper commands
    echo "Scholar Content Generation:"
    echo "  teach exam      Create exam questions"
    echo "  teach quiz      Generate quiz"
    # ...

    # Show Scholar availability
    if command -v claude >/dev/null 2>&1; then
        echo ""
        echo "✅ Scholar available (claude CLI found)"
    else
        echo ""
        echo "⚠️  Scholar unavailable (install claude CLI)"
    fi
}
```

---

## Implementation Roadmap

### Phase 1: Quick Wins (4-8 hours)

| Enhancement | Effort | Impact |
|-------------|--------|--------|
| 1. Explicit Config Passing | 2-4h | High |
| 6. Progress Indicator | 2-3h | Medium |
| **Total** | **4-7h** | |

**Deliverables:**
- Config path passed explicitly to Scholar
- Spinner for long operations
- Better error messages

### Phase 2: Core Improvements (8-12 hours)

| Enhancement | Effort | Impact |
|-------------|--------|--------|
| 2. Output Directory Config | 4-6h | Medium |
| 3. Flag Validation | 3-4h | Medium |
| 7. Status Integration | 3-4h | High |
| **Total** | **10-14h** | |

**Deliverables:**
- Standardized output locations
- Pre-flight flag validation
- Enhanced `teach status` with content summary

### Phase 3: Advanced Features (12-16 hours)

| Enhancement | Effort | Impact |
|-------------|--------|--------|
| 4. Post-Generation Hooks | 4-6h | High |
| 5. Interactive Mode | 6-8h | Medium |
| 8. Unified Help | 2-3h | Low |
| **Total** | **12-17h** | |

**Deliverables:**
- Auto-staging and status updates
- Iterative content refinement
- Comprehensive help system

---

## Dependencies

### Waiting on Scholar v2.1.0

The `/teaching:lecture` command is blocked on Scholar v2.1.0 Phase 3:
- **Current:** 70% complete
- **Remaining:** Phase 3 (~24 hours estimated)
- **Blocker for:** `teach lecture` wrapper

### No Breaking Changes

All enhancements are backward-compatible additions. Existing `teach` commands continue to work.

---

## Success Metrics

| Metric | Current | Target |
|--------|---------|--------|
| Commands with explicit config | 0/9 | 9/9 |
| Commands with flag validation | 0/9 | 9/9 |
| Post-generation automation | 0% | 100% |
| User friction points | 7 | 0 |

---

## Next Steps

1. **Immediate:** Implement Enhancement 1 (explicit config passing)
2. **Short-term:** Wait for Scholar v2.1.0 `/teaching:lecture`
3. **Medium-term:** Implement Phase 2 improvements
4. **Long-term:** Interactive mode and advanced features

---

## Appendix: Current Test Coverage

### flow-cli teach dispatcher

- 19 tests for teach-init UX
- Integration tests with Scholar wrappers

### Scholar teaching module

- 683 tests total
- 120 tests for teaching commands (v2.1.0 Phase 2)

---

**Document Version:** 1.0
**Author:** Claude Code (brainstorm session)
**Review Status:** Pending user review
