# SPEC: API Documentation Completion (#302)

**Date:** 2026-01-28
**Status:** Ready for Implementation
**Target:** 80% coverage (currently 13.8%)
**Branch:** `feature/api-docs-phase-N`
**Effort:** ~6 weeks total (phased)

---

## Executive Summary

Complete API documentation for flow-cli to achieve 80% coverage (566/704 functions).

**Current State:**
- Coverage: 13.8% (97/704 functions)
- Documented: Token automation, teaching libs, git helpers, keychain helpers
- Location: `docs/reference/MASTER-API-REFERENCE.md`

**Target State:**
- Coverage: 80% (566 functions)
- All core libraries fully documented
- All dispatchers fully documented
- All commands documented

---

## Phase Overview

| Phase | Area | Functions | Effort | Priority |
|-------|------|-----------|--------|----------|
| 1 | Core Libraries | ~80 | 1 week | ⭐⭐⭐ Critical |
| 2 | TUI & Display | ~45 | 3 days | ⭐⭐⭐ Critical |
| 3 | Dispatchers (Part 1) | ~100 | 1 week | ⭐⭐ High |
| 4 | Dispatchers (Part 2) | ~100 | 1 week | ⭐⭐ High |
| 5 | Commands | ~80 | 1 week | ⭐⭐ High |
| 6 | Remaining Libraries | ~64 | 1 week | ⭐ Medium |

---

## Phase 1: Core Libraries (~80 functions)

**Branch:** `feature/api-docs-phase-1`
**Effort:** ~1 week
**Priority:** ⭐⭐⭐ Critical (foundational)

### Files to Document

| File | Est. Functions | Description |
|------|----------------|-------------|
| `lib/core.zsh` | ~50 | Colors, logging, utilities, project detection |
| `lib/atlas-bridge.zsh` | ~15 | Atlas integration, state management |
| `lib/config-validator.zsh` | ~15 | Schema validation, hash verification |

### Documentation Template

```markdown
### `_function_name()`

**Purpose:** [One-line description]

**Parameters:**
| Name | Type | Required | Description |
|------|------|----------|-------------|
| `param1` | string | Yes | Description |

**Returns:** [Return value description]

**Example:**
\`\`\`zsh
_function_name "arg1" "arg2"
\`\`\`

**Side Effects:** [Any state changes, file I/O, etc.]

**Performance:** [If relevant - cache behavior, timing]
```

### Orchestration Instructions

```markdown
## Agent: api-docs-core

**Task:** Document core library functions in MASTER-API-REFERENCE.md

**Files to analyze:**
- lib/core.zsh
- lib/atlas-bridge.zsh
- lib/config-validator.zsh

**Output location:** docs/reference/MASTER-API-REFERENCE.md

**Instructions:**
1. Read each source file
2. Extract all function definitions (pattern: `^[a-z_]+\(\)`)
3. For each function:
   - Analyze parameters from code
   - Determine return values
   - Identify side effects
   - Create usage example
4. Add to appropriate section in MASTER-API-REFERENCE.md
5. Use the documentation template format

**Quality checklist:**
- [ ] All public functions documented
- [ ] Parameters accurately described
- [ ] Return values specified
- [ ] Examples are runnable
- [ ] Side effects noted
```

---

## Phase 2: TUI & Display (~45 functions)

**Branch:** `feature/api-docs-phase-2`
**Effort:** ~3 days
**Priority:** ⭐⭐⭐ Critical (used by all commands)

### Files to Document

| File | Est. Functions | Description |
|------|----------------|-------------|
| `lib/tui.zsh` | ~30 | Boxes, tables, spinners, prompts |
| `lib/inventory.zsh` | ~15 | Tool inventory, capability detection |

### Orchestration Instructions

```markdown
## Agent: api-docs-tui

**Task:** Document TUI and display functions

**Files to analyze:**
- lib/tui.zsh
- lib/inventory.zsh

**Output location:** docs/reference/MASTER-API-REFERENCE.md

**Instructions:**
1. Focus on visual output functions
2. Include ASCII art examples where relevant
3. Document color constants and themes
4. Note terminal compatibility requirements

**Special considerations:**
- TUI functions often have complex output - show example renders
- Note any terminal size requirements
- Document ANSI escape sequences used
```

---

## Phase 3: Dispatchers Part 1 (~100 functions)

**Branch:** `feature/api-docs-phase-3`
**Effort:** ~1 week
**Priority:** ⭐⭐ High

### Files to Document

| File | Est. Functions | Description |
|------|----------------|-------------|
| `lib/dispatchers/g-dispatcher.zsh` | ~25 | Git workflows |
| `lib/dispatchers/cc-dispatcher.zsh` | ~20 | Claude Code launcher |
| `lib/dispatchers/dot-dispatcher.zsh` | ~30 | Dotfiles + secrets (partial) |
| `lib/dispatchers/mcp-dispatcher.zsh` | ~25 | MCP server management |

### Orchestration Instructions (3 Parallel Agents)

```markdown
## Agent: api-docs-git-cc

**Task:** Document g-dispatcher and cc-dispatcher

**Files:**
- lib/dispatchers/g-dispatcher.zsh
- lib/dispatchers/cc-dispatcher.zsh

**Focus:**
- Git workflow functions (commit, push, feature, etc.)
- Claude Code launch modes
- Integration points between the two

---

## Agent: api-docs-dot

**Task:** Document remaining dot-dispatcher functions

**Files:**
- lib/dispatchers/dot-dispatcher.zsh

**Note:** Some functions already documented (token automation)
**Focus:**
- Secret management functions
- Dotfile sync functions
- Bitwarden integration
- Skip already-documented token functions

---

## Agent: api-docs-mcp

**Task:** Document mcp-dispatcher

**Files:**
- lib/dispatchers/mcp-dispatcher.zsh

**Focus:**
- Server lifecycle (start, stop, restart)
- Log viewing functions
- Status checking
- Configuration management
```

---

## Phase 4: Dispatchers Part 2 (~100 functions)

**Branch:** `feature/api-docs-phase-4`
**Effort:** ~1 week
**Priority:** ⭐⭐ High

### Files to Document

| File | Est. Functions | Description |
|------|----------------|-------------|
| `lib/dispatchers/teach-dispatcher.zsh` | ~40 | Teaching workflow |
| `lib/dispatchers/qu-dispatcher.zsh` | ~20 | Quarto publishing |
| `lib/dispatchers/r-dispatcher.zsh` | ~15 | R package development |
| `lib/dispatchers/obs.zsh` | ~10 | Obsidian integration |
| `lib/dispatchers/wt-dispatcher.zsh` | ~10 | Worktree management |
| `lib/dispatchers/tm-dispatcher.zsh` | ~5 | Terminal manager |

### Orchestration Instructions (3 Parallel Agents)

```markdown
## Agent: api-docs-teach

**Task:** Document teach-dispatcher (largest dispatcher)

**Files:**
- lib/dispatchers/teach-dispatcher.zsh

**Focus:**
- Course initialization
- Lesson plan management
- Scholar integration
- Deployment functions
- Exam generation

---

## Agent: api-docs-quarto-r

**Task:** Document qu-dispatcher and r-dispatcher

**Files:**
- lib/dispatchers/qu-dispatcher.zsh
- lib/dispatchers/r-dispatcher.zsh

**Focus:**
- Quarto render/preview/publish
- R package check/test/document
- Integration between Quarto and R

---

## Agent: api-docs-misc-dispatchers

**Task:** Document remaining dispatchers

**Files:**
- lib/dispatchers/obs.zsh
- lib/dispatchers/wt-dispatcher.zsh
- lib/dispatchers/tm-dispatcher.zsh
- lib/dispatchers/prompt-dispatcher.zsh
- lib/dispatchers/v-dispatcher.zsh

**Focus:**
- Obsidian vault operations
- Worktree management
- Terminal profiles
- Prompt engine switching
- Vibe coding mode
```

---

## Phase 5: Commands (~80 functions)

**Branch:** `feature/api-docs-phase-5`
**Effort:** ~1 week
**Priority:** ⭐⭐ High

### Files to Document

| File | Est. Functions | Description |
|------|----------------|-------------|
| `commands/work.zsh` | ~15 | Session management (partial) |
| `commands/dash.zsh` | ~20 | Dashboard display |
| `commands/capture.zsh` | ~10 | Quick capture, crumbs |
| `commands/adhd.zsh` | ~15 | Focus helpers, dopamine features |
| `commands/flow.zsh` | ~10 | Main flow command |
| `commands/doctor.zsh` | ~5 | Health check (partial) |
| `commands/pick.zsh` | ~5 | Project picker |

### Orchestration Instructions (2 Parallel Agents)

```markdown
## Agent: api-docs-commands-core

**Task:** Document core commands

**Files:**
- commands/work.zsh
- commands/dash.zsh
- commands/flow.zsh
- commands/pick.zsh

**Focus:**
- Session start/stop workflows
- Dashboard rendering
- Project detection
- Interactive selection

---

## Agent: api-docs-commands-adhd

**Task:** Document ADHD/productivity commands

**Files:**
- commands/capture.zsh
- commands/adhd.zsh
- commands/doctor.zsh

**Focus:**
- Quick capture mechanics
- Dopamine features (wins, streaks, goals)
- Health check categories
- Fix recommendations
```

---

## Phase 6: Remaining Libraries (~64 functions)

**Branch:** `feature/api-docs-phase-6`
**Effort:** ~1 week
**Priority:** ⭐ Medium

### Files to Document

| File | Est. Functions | Description |
|------|----------------|-------------|
| `lib/project-detector.zsh` | ~20 | Project type detection |
| `lib/dotfile-helpers.zsh` | ~15 | Dotfile management utilities |
| `lib/doctor-cache.zsh` | ~13 | Already documented - verify |
| `lib/concept-extraction.zsh` | ~8 | Already documented - verify |
| `lib/prerequisite-checker.zsh` | ~5 | Already documented - verify |
| Remaining teaching libs | ~10 | Fill gaps |

### Orchestration Instructions

```markdown
## Agent: api-docs-remaining

**Task:** Document remaining libraries and fill gaps

**Files:**
- lib/project-detector.zsh
- lib/dotfile-helpers.zsh
- Any undocumented functions in previously covered files

**Focus:**
- Project type detection algorithms
- Dotfile sync logic
- Fill any gaps from previous phases

**Verification:**
- Cross-reference with generate-doc-dashboard.sh output
- Ensure no functions missed
```

---

## Orchestration Command Template

### Single Phase Execution

```bash
# In worktree
cd ~/.git-worktrees/flow-cli/feature-api-docs-phase-1

# Start orchestration
/craft:orchestrate

# Prompt:
"Execute Phase 1 API Documentation:
- Document lib/core.zsh (~50 functions)
- Document lib/atlas-bridge.zsh (~15 functions)
- Document lib/config-validator.zsh (~15 functions)
- Output to docs/reference/MASTER-API-REFERENCE.md
- Use standard documentation template
- Run generate-doc-dashboard.sh to verify coverage"
```

### Multi-Agent Parallel Execution

```bash
# For phases with multiple agents (3-4)
/craft:orchestrate

# Prompt:
"Execute Phase 3 API Documentation with 3 parallel agents:

Agent 1 (api-docs-git-cc):
- Document lib/dispatchers/g-dispatcher.zsh
- Document lib/dispatchers/cc-dispatcher.zsh

Agent 2 (api-docs-dot):
- Document remaining lib/dispatchers/dot-dispatcher.zsh functions
- Skip already-documented token automation functions

Agent 3 (api-docs-mcp):
- Document lib/dispatchers/mcp-dispatcher.zsh

All agents output to docs/reference/MASTER-API-REFERENCE.md
Coordinate to avoid conflicts in the same file section."
```

---

## Quality Assurance

### Per-Phase Checklist

- [ ] All functions in scope documented
- [ ] Documentation follows template format
- [ ] Examples are runnable
- [ ] Coverage increased (verify with dashboard)
- [ ] No duplicate entries
- [ ] Internal links work

### Verification Commands

```bash
# Check coverage
./scripts/generate-doc-dashboard.sh

# Verify no broken internal references
./scripts/check-doc-updates.sh

# Build docs to catch errors
mkdocs build
```

### Coverage Targets by Phase

| After Phase | Target Coverage | Functions |
|-------------|-----------------|-----------|
| 1 | 25% | ~177 |
| 2 | 32% | ~222 |
| 3 | 46% | ~322 |
| 4 | 60% | ~422 |
| 5 | 72% | ~502 |
| 6 | 80% | ~566 |

---

## Worktree Setup

### Create Phase Worktree

```bash
# From main repo
cd ~/projects/dev-tools/flow-cli

# Create worktree for phase
git worktree add ~/.git-worktrees/flow-cli/feature-api-docs-phase-1 -b feature/api-docs-phase-1 dev

# Start new session in worktree
cd ~/.git-worktrees/flow-cli/feature-api-docs-phase-1
claude
```

### Phase Completion

```bash
# After completing phase
git add docs/reference/MASTER-API-REFERENCE.md
git commit -m "docs(api): complete Phase N - [area] (~X functions)"

# Create PR
gh pr create --base dev --title "docs(api): Phase N - [Area] Documentation"

# After merge, cleanup
git worktree remove ~/.git-worktrees/flow-cli/feature-api-docs-phase-N
```

---

## Timeline

| Week | Phase | Focus |
|------|-------|-------|
| 1 | Phase 1 | Core libraries |
| 1-2 | Phase 2 | TUI & Display |
| 2 | Phase 3 | Dispatchers (git, cc, dot, mcp) |
| 3 | Phase 4 | Dispatchers (teach, qu, r, misc) |
| 4 | Phase 5 | Commands |
| 5 | Phase 6 | Remaining + gaps |
| 6 | QA | Review, fix, deploy |

---

## Change Log

| Date | Author | Change |
|------|--------|--------|
| 2026-01-28 | Claude | Initial spec |
