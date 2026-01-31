# Worktree Orchestration Plan: `teach prompt`

**Branch:** `feature/teach-prompt`
**Base:** `dev` (at f9fdcc05)
**Worktree:** `~/.git-worktrees/flow-cli/feature-teach-prompt`
**Target:** v5.23.0

---

## Reference Documents

Read these BEFORE writing any code:

| Document | Purpose | Priority |
|----------|---------|----------|
| `docs/specs/SPEC-teach-prompt-v2-2026-01-29.md` | **Primary spec** - all requirements, function signatures, validation rules | Required |
| `docs/specs/BRAINSTORM-teach-prompt-v2-2026-01-29.md` | Design rationale, Scholar analysis findings, architecture decisions | Reference |
| `commands/teach-templates.zsh` | **Pattern to follow** - load guard, dispatcher, subcommands, help | Required |
| `commands/teach-macros.zsh` | **Pattern to follow** - export, list, validation patterns | Required |
| `lib/template-helpers.zsh` | Functions to **reuse**: `_teach_parse_template_metadata()`, `_teach_substitute_variables()`, `_teach_extract_variables()` | Required |
| `lib/dispatchers/teach-dispatcher.zsh` | Integration point - routing, Scholar wrapper, help | Required |
| `docs/specs/BRAINSTORM-scholar-coordination-2026-01-21.md` | Scholar coordination strategy (Option A: Scholar-Aware Prompts) | Reference |

---

## Key Decisions (Pre-Approved)

- **Override dir:** `.flow/templates/prompts/` (reuses existing template infrastructure)
- **MVP scope:** 5 subcommands: `list`, `show`, `edit`, `validate`, `export`
- **Deferred:** `create`, `diff`, `promote` (Phase 2)
- **Scholar integration:** Auto-resolve prompts for every Scholar call (zero friction)
- **3-tier resolution:** Course (`.flow/templates/prompts/`) > User (`~/.flow/prompts/`) > Plugin (`lib/templates/teaching/claude-prompts/`)

---

## Implementation Sequence

### Increment 1: Helper Library
**File:** `lib/prompt-helpers.zsh` (~300 lines)
**Commit:** `feat: add prompt resolution helpers (3-tier)`

Functions to implement:
1. `_teach_resolve_prompt()` - 3-tier resolution
2. `_teach_get_all_prompts()` - Enumerate across tiers
3. `_teach_prompt_tier()` - Tier detection
4. `_teach_prompt_has_override()` - Override check
5. `_teach_render_prompt()` - Variable substitution + macro injection
6. `_teach_validate_prompt_file()` - Validation

**Key:** Source `lib/template-helpers.zsh` and reuse its functions. Don't reimplement.

### Increment 2: Command Implementation
**File:** `commands/teach-prompt.zsh` (~450 lines)
**Commit:** `feat: add teach prompt command (5 subcommands)`

Subcommands:
1. `_teach_prompt()` - Main dispatcher
2. `_teach_prompt_list()` - List with [C]/[U]/[P] tier indicators
3. `_teach_prompt_show()` - Display in $PAGER
4. `_teach_prompt_edit()` - Copy to course dir + open $EDITOR
5. `_teach_prompt_validate()` - Syntax + Scholar compat
6. `_teach_prompt_export()` - Render with resolved variables
7. `_teach_prompt_help()` - Colorized help (box-header convention)

### Increment 3: Dispatcher Integration
**File:** `lib/dispatchers/teach-dispatcher.zsh` (+45 lines)
**Commit:** `feat: integrate teach prompt into dispatcher and Scholar wrapper`

Changes:
1. Add source guard block (after teach-macros source)
2. Add `prompt|pr)` case in the main `teach()` function
3. Add help entry in `_teach_dispatcher_help()`
4. Modify `_teach_scholar_wrapper()` to auto-resolve + render prompt

### Increment 4: Completions
**File:** `completions/_teach` (+40 lines)
**Commit:** `feat: add teach prompt tab completions`

### Increment 5: Tests
**File:** `tests/test-teach-prompt-unit.zsh` (~300 lines)
**Commit:** `test: add teach prompt unit tests (40 tests)`

Test categories:
- Resolution (10): 3-tier precedence, missing, forced tier
- Rendering (8): Variable substitution, macros, missing vars
- Validation (10): Valid/invalid frontmatter, unknown vars
- List/Show (6): Output format, tier indicators, errors
- Edit (4): Override creation, directory creation
- Export (4): Rendered output, JSON, macros

### Increment 6: Documentation
**Files:** `docs/reference/REFCARD-PROMPTS.md`, `docs/tutorials/28-teach-prompt.md`, `CHANGELOG.md`
**Commit:** `docs: add teach prompt reference and tutorial`

---

## Verification Checklist

After all increments:

```bash
# 1. Plugin loads
source flow.plugin.zsh

# 2. Help works
teach prompt help

# 3. List shows existing prompts
teach prompt list

# 4. Show opens in pager
teach prompt show lecture-notes

# 5. Edit creates course override (need .flow/templates/prompts/ dir)
mkdir -p .flow/templates/prompts
teach prompt edit lecture-notes

# 6. Validate checks all prompts
teach prompt validate

# 7. Export renders variables (need teach-config.yml)
teach prompt export lecture-notes

# 8. Run tests
./tests/test-teach-prompt-unit.zsh
```

---

## Important Patterns to Follow

### Load Guard (from teach-templates.zsh)
```zsh
[[ -n "$_FLOW_TEACH_PROMPT_LOADED" ]] && return 0
typeset -g _FLOW_TEACH_PROMPT_LOADED=1
```

### Help Box Header (from teach-macros.zsh)
```zsh
cat <<EOF
${FLOW_COLORS[header]}+====...====+${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}|${FLOW_COLORS[reset]}  teach prompt - ...
...
EOF
```

### Template Helper Reuse
```zsh
# Source template helpers (needed for metadata parsing)
local helpers_path="${0:A:h:h}/lib/template-helpers.zsh"
[[ -f "$helpers_path" ]] && source "$helpers_path"
```

### Plugin Dir Resolution
```zsh
# Use template-helpers function to find plugin dir
local plugin_dir="$(_template_get_plugin_dir)"
# -> Returns: .../lib/templates/teaching/
# Prompts are at: $plugin_dir/claude-prompts/
```
