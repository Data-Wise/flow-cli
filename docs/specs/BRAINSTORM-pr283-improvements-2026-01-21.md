# BRAINSTORM: PR #283 Teaching Prompts Improvements

**Generated:** 2026-01-21
**Context:** flow-cli / PR #283 follow-up
**Depth:** Deep (8 expert questions)
**Focus:** Feature + Architecture
**Duration:** ~10 minutes

---

## Overview

PR #283 adds teaching prompts to `lib/templates/teaching/claude-prompts/`. This brainstorm addresses three improvements identified during code review and scopes a follow-up implementation.

---

## Decision Summary

| Question | Decision | Rationale |
|----------|----------|-----------|
| IMPLEMENTATION.md location | Move to `docs/specs/` | Archive as planning doc |
| `teach prompt` command | List + Display | `teach prompt list` + `teach prompt <name>` |
| Scholar path reference | Add clarifying note | "In the Scholar plugin repository" |
| Integration priority | teach prompt command | Core functionality first |
| Prompt customization | Future consideration | Wait for v1 usage feedback |
| Additional prompts | Wait for Scholar | Scholar commands cover these |
| Testing strategy | Markdown lint only | Fast structural validation |
| Documentation location | Add to TEACHING-WORKFLOW-V3-GUIDE | Integrate with existing guide |

---

## Quick Wins (< 30 min each)

### ⚡ 1. Fix README Scholar Path Reference

**File:** `lib/templates/teaching/claude-prompts/README.md`
**Change:** Add clarifying note to line 38

```markdown
## Integration with Teaching Style

These prompts work with the Scholar plugin's 4-layer teaching style system.

> **Note:** Teaching style examples are located in the Scholar plugin repository,
> not in flow-cli. See: `~/.claude/plugins/cache/scholar/*/examples/teaching-styles/`
```

**Effort:** 5 minutes

### ⚡ 2. Rename IMPLEMENTATION.md → SPEC-teaching-prompts.md

**Action:** Move and rename after merge

```bash
# After PR #283 merges to dev
git mv IMPLEMENTATION.md docs/specs/SPEC-teaching-prompts.md
```

**Effort:** 2 minutes

### ⚡ 3. Add Markdown Linting to PR Checklist

**File:** `IMPLEMENTATION.md` (before move)
**Add to Test plan:**

```markdown
## Test plan

- [x] Verify all prompts are valid Markdown (`npx markdownlint-cli lib/templates/teaching/claude-prompts/*.md`)
- [ ] Test integration with Scholar `/teaching:lecture`
- [ ] Verify README documentation is accurate
```

**Effort:** 5 minutes

---

## Medium Effort (1-2 hours)

### 🔧 4. Implement `teach prompt` Command

**Location:** `lib/dispatchers/teach-dispatcher.zsh`

**Subcommands:**

| Command | Action |
|---------|--------|
| `teach prompt` | Show help (same as `teach prompt help`) |
| `teach prompt list` | List available prompts |
| `teach prompt <name>` | Display prompt content |
| `teach prompt help` | Show command help |

**Implementation Sketch:**

```zsh
# In teach-dispatcher.zsh, add to case statement:
prompt) shift; _teach_prompt "$@" ;;

# New function
_teach_prompt() {
    local prompts_dir="${FLOW_ROOT}/lib/templates/teaching/claude-prompts"

    case "$1" in
        list)
            _flow_log_header "Available Teaching Prompts"
            echo ""
            for f in "$prompts_dir"/*.md; do
                [[ "$(basename "$f")" == "README.md" ]] && continue
                local name=$(basename "$f" .md)
                local desc=$(head -5 "$f" | grep -E "^#" | head -1 | sed 's/^# //')
                printf "  ${CYAN}%-25s${RESET} %s\n" "$name" "$desc"
            done
            echo ""
            echo "Usage: ${BOLD}teach prompt <name>${RESET} to view a prompt"
            ;;
        help|--help|-h)
            _teach_prompt_help
            ;;
        "")
            _teach_prompt_help
            ;;
        *)
            local prompt_file="$prompts_dir/$1.md"
            if [[ -f "$prompt_file" ]]; then
                ${PAGER:-less} "$prompt_file"
            else
                _flow_log_error "Unknown prompt: $1"
                echo "Run ${BOLD}teach prompt list${RESET} to see available prompts"
                return 1
            fi
            ;;
    esac
}

_teach_prompt_help() {
    cat << 'EOF'
teach prompt - Display Claude Code teaching prompts

USAGE:
    teach prompt <command>

COMMANDS:
    list              List available prompts
    <name>            Display prompt content (opens in pager)
    help              Show this help

AVAILABLE PROMPTS:
    lecture-notes         Comprehensive lecture documents (20-40 pages)
    revealjs-slides       Visual presentations (25+ slides)
    derivations-appendix  Mathematical theory appendices

EXAMPLES:
    teach prompt list                    # See all prompts
    teach prompt lecture-notes           # View lecture prompt
    teach prompt derivations-appendix    # View derivations prompt

INTEGRATION:
    These prompts complement Scholar plugin commands:
    - /teaching:lecture uses lecture-notes.md structure
    - /teaching:slides uses revealjs-slides.md structure

    Customize output via .claude/teaching-style.local.md
EOF
}
```

**Effort:** 45-60 minutes

### 🔧 5. Update TEACHING-WORKFLOW-V3-GUIDE

**Location:** `docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md`

**Add new section:**

```markdown
## Claude Code Teaching Prompts

flow-cli includes optimized prompts for generating statistics course content.

### Available Prompts

| Prompt | Purpose | Output |
|--------|---------|--------|
| `lecture-notes` | Comprehensive lecture documents | 20-40 pages |
| `revealjs-slides` | Visual presentations | 25+ slides |
| `derivations-appendix` | Mathematical theory appendices | Variable |

### Viewing Prompts

```bash
# List all prompts
teach prompt list

# View a specific prompt
teach prompt lecture-notes

# Use with Scholar (recommended)
/teaching:lecture "Factorial ANOVA"
```

### Integration with Scholar

These prompts work with Scholar's `/teaching:*` commands. Configure your
teaching style in `.claude/teaching-style.local.md` for customization.

See [Scholar plugin documentation](https://github.com/Data-Wise/scholar) for
teaching style examples.

```

**Effort:** 30-45 minutes

---

## Long-term (Future Sessions)

### 📋 6. Course-Level Prompt Customization (Future)
**Trigger:** After v1 usage feedback
**Scope:**
- `teach init` option to copy prompts to `.teach/prompts/`
- Course-specific overrides via `teaching.yml`
- Template inheritance system

### 📋 7. Additional Prompts (Scholar Owns)
**Status:** Wait for Scholar plugin
**Candidates:** assignment.md, exam.md, syllabus.md, rubric.md
**Rationale:** Scholar commands (`/teaching:assignment`, etc.) already handle these

### 📋 8. ai-recipes Integration (Future)
**Scope:** Add `[teach-lecture]`, `[teach-slides]` recipes
**Depends on:** Successful teach prompt command adoption

---

## Recommended Path

**Immediate (PR #283 amendments):**
1. ⚡ Fix README Scholar path reference (5 min)
2. ⚡ Add markdown lint to test plan (5 min)

**Follow-up PR (feature/teach-prompt-command):**
3. 🔧 Implement `teach prompt` command (60 min)
4. 🔧 Update TEACHING-WORKFLOW-V3-GUIDE (45 min)
5. ⚡ Move IMPLEMENTATION.md to docs/specs/ (2 min)

**Timeline:** ~2 hours total implementation

---

## Implementation Order

```

PR #283 (current)
├── Quick fix: README path clarification
└── Quick fix: Add markdown lint to test plan
    ↓
[Merge PR #283 to dev]
    ↓
PR #284 (new: feature/teach-prompt-command)
├── Add _teach_prompt() to teach-dispatcher.zsh
├── Add _teach_prompt_help() function
├── Update TEACHING-WORKFLOW-V3-GUIDE.md
├── Move IMPLEMENTATION.md → docs/specs/SPEC-teaching-prompts.md
└── Add completions for teach prompt
    ↓
[Merge to dev, prepare v5.16.0]

```

---

## Files to Modify

| File | Change | Priority |
|------|--------|----------|
| `lib/templates/teaching/claude-prompts/README.md` | Add Scholar path note | Now |
| `IMPLEMENTATION.md` | Add lint to test plan | Now |
| `lib/dispatchers/teach-dispatcher.zsh` | Add prompt subcommand | Follow-up |
| `docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md` | Add prompts section | Follow-up |
| `completions/_teach` | Add prompt completions | Follow-up |
| `IMPLEMENTATION.md` | Move to docs/specs/ | After merge |

---

## Next Steps

1. **Amend PR #283** with quick fixes (README + lint)
2. **Merge PR #283** to dev
3. **Create feature/teach-prompt-command** branch
4. **Implement teach prompt** command
5. **Update documentation**
6. **Release v5.16.0**

---

## Related Commands

- `/workflow:spec-review` - Review this as a spec
- `/craft:do "implement teach prompt"` - Start implementation
- `gh pr view 283` - View current PR

---

*Generated by /workflow:brainstorm deep*
