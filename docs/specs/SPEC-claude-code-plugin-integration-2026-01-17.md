# SPEC: Claude Code Plugin Integration - Scholar & Craft Dispatchers

**Feature:** CLI wrappers for scholar and craft Claude Code plugins  
**Status:** Design Phase  
**Created:** 2026-01-17  
**Target Release:** flow-cli v5.13.0  
**Estimated Effort:** 18-24 hours over 2-3 weeks

---

## Metadata

| Field | Value |
|-------|-------|
| **Status** | Design → Implementation |
| **Priority** | High (enables research + teaching workflows) |
| **Complexity** | Medium (18-24 hours) |
| **Risk Level** | Low (additive, no breaking changes) |
| **Dependencies** | Claude Code CLI, scholar plugin, craft plugin |
| **Related Projects** | scholar v2.3.0+, craft v1.17.0+ |
| **Target Users** | Academic researchers, course instructors |
| **Branch Strategy** | feature/plugin-dispatchers → dev → main |

---

## Executive Summary

**Problem:** Scholar and craft are powerful Claude Code plugins with 108 combined commands (22 scholar + 86 craft), but they only work inside interactive Claude Code sessions. Users cannot leverage them from the command line for scripting, automation, or integration with flow-cli workflows.

**Solution:** Create two new flow-cli dispatchers (`scholar` and `craft`) that wrap Claude Code plugin commands, enabling CLI usage while maintaining the power of AI-assisted generation.

**Key Benefits:**
- **Teaching workflows:** `scholar quiz "topic" > quiz.md` for rapid content generation
- **Research automation:** `scholar arxiv "query" > papers.txt` for literature review  
- **Quality assurance:** `craft check --for release` for pre-publication validation
- **Scripting:** All commands usable in shell scripts and automation
- **ADHD-friendly:** Fast, predictable, composable with existing flow-cli tools

**Impact:**
- 10x faster course material creation (hours → minutes)
- Seamless integration with existing `teach-*`, `work`, `dash` commands
- Scriptable research pipelines (literature → code → paper)
- Zero context switching between terminal and Claude sessions

---

## Problem Statement

### Current State

**Scholar Plugin (22 commands):**
- Literature: `/arxiv`, `/doi`, `/bib:search`, `/bib:add`
- Teaching: `/teaching:exam`, `/teaching:quiz`, `/teaching:syllabus`, `/teaching:slides`
- Research: `/scholar:lit-gap`, `/scholar:hypothesis`, `/scholar:analysis-plan`
- Manuscript: `/manuscript:methods`, `/manuscript:results`, `/manuscript:reviewer`

**Craft Plugin (86 commands):**
- Smart orchestration: `/craft:do`, `/craft:check`, `/craft:hub`
- Testing: `/craft:test:run`, `/craft:test:coverage`
- Quality: `/craft:code:lint`, `/craft:security:scan`
- Documentation: `/craft:docs:validate`, `/craft:site:publish`

**Problem:** Only work inside `claude` interactive sessions.

**Limitations:**
1. Not scriptable - Cannot automate workflows
2. Manual context switching - Must enter/exit Claude sessions
3. No piping - Cannot compose with Unix tools
4. Flow-cli integration friction

### Desired State

```bash
# Scripting
scholar arxiv "bootstrap mediation" > lit-review.txt
scholar quiz "Linear Regression" > quiz.md

# Integration
teach-exam "Hypothesis Testing"  # Calls scholar
craft check --for release        # Pre-publication

# Automation
for topic in "regression" "anova"; do
  scholar quiz "$topic" > "quizzes/$topic.md"
done
```

---

## Design Overview

### Architecture

**3-layer integration:**

```
┌────────────────────────────────────────────────┐
│ Layer 3: flow-cli Workflows                    │
│ teach-exam, teach-quiz, work, dash            │
├────────────────────────────────────────────────┤
│ Layer 2: CLI Dispatchers (NEW)                │
│ scholar-dispatcher.zsh, craft-dispatcher.zsh  │
├────────────────────────────────────────────────┤
│ Layer 1: Claude Code CLI                      │
│ claude -p "/command" (print mode)             │
│ claude "/command" (interactive mode)          │
└────────────────────────────────────────────────┘
```

**Key Decisions:**

| Decision | Rationale |
|----------|-----------|
| Dispatcher pattern | Consistency with g, cc, mcp, r |
| Print mode default | Non-interactive, scriptable |
| Interactive fallback | Complex tasks need iteration |
| Output to stdout | Enable piping, redirection |
| Config integration | Read `.flow/teach-config.yml` |
| Completion support | ZSH completions for discovery |

---

## Technical Validation

### Claude Code CLI Capabilities (Verified 2026-01-17)

**CLI Version:** 2.1.12

**Print Mode (`-p, --print`):**

```bash
# Basic usage - outputs to stdout
claude -p "prompt text"

# With slash commands (skills)
claude -p "/hub"
claude -p "/scholar:teaching:quiz 'Linear Regression'"

# Output formats
claude -p "prompt" --output-format text   # Default: plain text
claude -p "prompt" --output-format json   # Structured JSON with metadata
claude -p "prompt" --output-format stream-json  # Realtime streaming
```

**JSON Output Structure:**

```json
{
  "type": "result",
  "subtype": "success",
  "is_error": false,
  "duration_ms": 28561,
  "num_turns": 4,
  "result": "... output content ...",
  "session_id": "uuid",
  "total_cost_usd": 0.14,
  "usage": { /* token counts */ }
}
```

**Key Flags for Automation:**

| Flag | Purpose | Use Case |
|------|---------|----------|
| `-p, --print` | Non-interactive mode | Required for scripting |
| `--output-format json` | Structured output | Parse results programmatically |
| `--output-format text` | Plain text (default) | Piping to files |
| `--dangerously-skip-permissions` | Bypass confirmations | Sandboxed automation only |
| `--max-budget-usd <amount>` | Cost limit | Prevent runaway costs |
| `--model <model>` | Model selection | `haiku` for fast/cheap |
| `--fallback-model <model>` | Auto-fallback | Handle overload |

**Execution Characteristics:**
- **Latency:** 5-30 seconds typical (depends on task complexity)
- **Exit codes:** 0 on success, non-zero on failure
- **Stderr:** Error messages, debug info (with `--debug`)
- **Multi-turn:** Print mode completes full task before returning

### Dispatcher Implementation Pattern

```zsh
# Core execution function (shared by both dispatchers)
_flow_claude_exec() {
    local cmd="$1"
    local args="$2"
    local output_format="${3:-text}"

    # Build command - arguments are passed as a single quoted string
    local full_cmd="/$cmd $args"

    # Execute with appropriate flags
    # Note: Using ZSH arrays prevents shell injection
    local -a claude_args=(
        -p "$full_cmd"
        --output-format "$output_format"
        --max-budget-usd 0.50
    )
    claude "${claude_args[@]}" 2>&1
}

# Example scholar wrapper
scholar() {
    case "$1" in
        quiz)    shift; _flow_claude_exec "scholar:teaching:quiz" "$*" ;;
        arxiv)   shift; _flow_claude_exec "scholar:literature:arxiv" "$*" ;;
        help)    _scholar_help ;;
        *)       _scholar_help ;;
    esac
}
```

---

## Error Handling

### Error Categories

| Category | Detection | Recovery |
|----------|-----------|----------|
| **Claude not installed** | `command -v claude` fails | Show install instructions |
| **Plugin not available** | Output contains "unknown command" | List available commands |
| **Network failure** | Exit code non-zero + timeout | Retry with backoff |
| **Rate limit** | Output contains "rate limit" | Wait and retry |
| **Permission denied** | Output contains "permission" | Suggest `--dangerously-skip-permissions` |
| **Timeout** | Command exceeds threshold | Increase timeout or switch to interactive |
| **Invalid arguments** | Output contains "invalid" | Show command help |
| **Cost exceeded** | JSON `total_cost_usd` > budget | Warn user, abort |

### Implementation

```zsh
# Error handling wrapper
_flow_claude_safe_exec() {
    local cmd="$1"
    shift

    # Pre-flight checks
    if ! command -v claude &>/dev/null; then
        _flow_log_error "Claude Code not installed"
        _flow_log_info "Install: npm install -g @anthropic-ai/claude-code"
        return 1
    fi

    # Build safe argument array (prevents injection)
    local -a args=("$@")
    local full_prompt="/$cmd ${args[*]}"

    # Execute with timeout
    local output exit_code
    output=$(timeout 120 claude -p "$full_prompt" 2>&1)
    exit_code=$?

    # Handle timeout
    if [[ $exit_code -eq 124 ]]; then
        _flow_log_error "Command timed out after 120s"
        _flow_log_info "Try: claude \"/$cmd ${args[*]}\" (interactive mode)"
        return 124
    fi

    # Handle other errors
    if [[ $exit_code -ne 0 ]]; then
        _flow_log_error "Command failed (exit $exit_code)"
        print -u2 "$output"
        return $exit_code
    fi

    # Check for known error patterns
    if [[ "$output" == *"unknown command"* ]]; then
        _flow_log_error "Plugin command not found: $cmd"
        _flow_log_info "Ensure scholar/craft plugins are installed"
        return 1
    fi

    # Success - output result
    print "$output"
}
```

### Timeout Strategy

| Command Type | Default Timeout | Rationale |
|--------------|-----------------|-----------|
| Quick lookup (doi, bib) | 30s | Simple retrieval |
| Search (arxiv, lit-gap) | 60s | API calls + processing |
| Generation (quiz, exam) | 120s | AI generation time |
| Complex (analysis-plan) | 180s | Multi-step reasoning |
| Interactive fallback | None | User controls |

### User Feedback

```zsh
# Progress indication for long-running commands
_flow_claude_with_spinner() {
    local cmd="$1"
    shift
    local -a args=("$@")

    _flow_log_info "Running: $cmd..."

    # Create temp file for output
    local tmpfile=$(mktemp)
    trap "rm -f $tmpfile" EXIT

    # Run in background
    claude -p "/$cmd ${args[*]}" > "$tmpfile" 2>&1 &
    local pid=$!

    # Show spinner for commands > 5s
    local i=0
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while kill -0 $pid 2>/dev/null; do
        printf "\r  ${spin:i++%10:1} Generating..."
        sleep 0.1
    done
    printf "\r"

    wait $pid
    local exit_code=$?

    cat "$tmpfile"
    return $exit_code
}
```

---

## Implementation Plan

### Phase 1: Foundation (Week 1, 6h)

**Deliverables:**
- [ ] `lib/dispatchers/scholar-dispatcher.zsh`
- [ ] `lib/dispatchers/craft-dispatcher.zsh`
- [ ] Argument parsing
- [ ] Help system
- [ ] Error handling

### Phase 2: Scholar (Week 1-2, 10h)

**Deliverables:**
- [ ] Literature commands
- [ ] Teaching commands
- [ ] Config auto-detection
- [ ] Output formatting

### Phase 3: Craft (Week 2-3, 4h)

**Deliverables:**
- [ ] Smart orchestration
- [ ] Testing commands
- [ ] Site management
- [ ] Mode selection

### Phase 4: Integration (Week 3, 5h)

**Deliverables:**
- [ ] Teaching workflow integration
- [ ] Work/dash enhancements
- [ ] Completions
- [ ] Documentation
- [ ] Tests

---

## Success Metrics

**Week 1:** Both dispatchers load, help works  
**Week 2:** All scholar commands work, config auto-detection  
**Week 3:** Craft commands work, integration complete  
**Week 4+:** Daily usage, zero manual plugin invocation

---

## Example Workflows

### Teaching Workflow

```bash
cd ~/teaching/stat-579
work stat-579

scholar slides "Sequential Mediation" 75 --output slides/week08.qmd
scholar quiz "Sequential Mediation" --output quizzes/week08.md
craft site:validate
craft site:publish

finish "Week 8 materials"
```

### Research Workflow  

```bash
cd ~/research/multiply-robust
work mr-paper

scholar arxiv "multiply robust mediation" > lit-review.txt
scholar doi "10.1093/biomet/asz073" > paper.bib
scholar lit-gap "multiply robust" > gaps.md

win "Literature review complete"
```

---

## Documentation

**Reference:**
- `docs/reference/SCHOLAR-DISPATCHER-REFERENCE.md`
- `docs/reference/CRAFT-DISPATCHER-REFERENCE.md`

**Tutorials:**
- `docs/tutorials/scholar-cli-usage.md`
- `docs/tutorials/craft-cli-usage.md`

---

## Phased Brainstorming Plan

This spec uses a **phased brainstorming approach** - detailed specs are created for each domain before implementation:

| Domain | Spec Status | Implementation |
|--------|-------------|----------------|
| **Teaching/Scholar Enhancement** | ✅ Complete | [SPEC-teach-scholar-enhancement-2026-01-17.md](SPEC-teach-scholar-enhancement-2026-01-17.md) |
| **Research/Literature** | 🔜 Pending | Brainstorm after teaching implementation |
| **Craft Commands** | 🔜 Pending | Brainstorm after research implementation |

### Teaching/Scholar Enhancement (Complete)

Deep brainstorm completed with expert agent analysis (merged from 2 original specs):
- **UX Agent:** CLI user experience, progress indicators, ADHD-friendly design
- **Backend Architect:** Config schema, context handling, error strategies

**Key Features:**

- Smart defaults auto-detect current week's topic (`--week`, `--topic`)
- Interactive mode (`-i`) for step-by-step wizard
- Revision workflow (`--revise`) for iterating on content
- Context integration (`--context`) for course materials
- Content customization: 4 style presets + 9 content flags
- Lesson plan integration with YAML schema

**Implementation:** 6 phases, 20-24 hours total

### Research/Literature (Pending)

To brainstorm after teaching implementation:
- `/scholar:literature:arxiv`, `/scholar:literature:doi`
- `/scholar:research:lit-gap`, `/scholar:research:hypothesis`
- Integration with Zotero/bibliography workflows

### Craft Commands (Pending)

To brainstorm after research implementation:
- `/craft:do`, `/craft:check`, `/craft:hub`
- Site management, testing, quality commands

---

## Next Steps

1. ✅ Main specification complete
2. ✅ Teaching/Scholar enhancement spec complete (merged from 2 specs)
3. ⏳ Begin teaching Phase 1 implementation (Flag Infrastructure)
4. 🔜 Complete teaching Phases 2-6
5. 🔜 Brainstorm research/literature after teaching complete
6. 🔜 Brainstorm craft commands after research complete

---

**Contact:**
Issues: [github.com/Data-Wise/flow-cli/issues](https://github.com/Data-Wise/flow-cli/issues)
