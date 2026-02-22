# BRAINSTORM: Atlas Plugin Update & Coordination

> **Mode:** Feature | **Depth:** Max | **Duration:** ~12 min
> **Date:** 2026-02-22 | **Project:** flow-cli v7.4.1 + Atlas v0.9.0

---

## Executive Summary

Atlas v0.9.0 is installed and working, but flow-cli only exposes **6 of 30+ Atlas commands** through a bridge layer. The help browser lists only **8 of 15 dispatchers**. This brainstorm covers: enhancing the bridge, fixing help, establishing an API contract, and coordinating development.

---

## Current State Analysis

### What flow-cli exposes (6 bridge functions)

| Bridge Function       | Maps To               | Used By                                  |
| --------------------- | --------------------- | ---------------------------------------- |
| `_flow_session_start` | `atlas session start` | `commands/work.zsh`                      |
| `_flow_session_end`   | `atlas session end`   | `commands/finish.zsh` (via status.zsh)   |
| `_flow_catch`         | `atlas catch`         | `commands/capture.zsh`                   |
| `_flow_where`         | `atlas where`         | Context display                          |
| `_flow_crumb`         | `atlas crumb`         | Breadcrumb trail                         |
| `_flow_list_projects` | `atlas project list`  | `commands/dash.zsh`, `commands/work.zsh` |

### What Atlas CLI has (30+ commands NOT exposed)

| Atlas Command                                     | Category  | Priority | Notes                         |
| ------------------------------------------------- | --------- | -------- | ----------------------------- |
| `atlas session start --energy --estimate --task`  | Session   | HIGH     | Flow only passes project name |
| `atlas session export`                            | Session   | MEDIUM   | iCal export                   |
| `atlas stats [period]`                            | Analytics | HIGH     | Session analytics + charts    |
| `atlas plan`                                      | Planning  | HIGH     | Morning ritual                |
| `atlas park [note]`                               | Context   | HIGH     | Save context before switching |
| `atlas unpark [id]`                               | Context   | HIGH     | Restore parked context        |
| `atlas parked`                                    | Context   | MEDIUM   | List parked contexts          |
| `atlas focus <project> [text]`                    | Status    | MEDIUM   | Get/set focus                 |
| `atlas status --set --progress --next --complete` | Status    | MEDIUM   | Rich status management        |
| `atlas dashboard` / `atlas dash`                  | TUI       | HIGH     | Ink dashboard                 |
| `atlas inbox --triage --stats`                    | Capture   | MEDIUM   | Interactive triage            |
| `atlas trail [project]`                           | Context   | LOW      | Breadcrumb trail view         |
| `atlas project add/show/remove`                   | Registry  | LOW      | Project registry CRUD         |
| `atlas template *`                                | Templates | LOW      | Project templates             |
| `atlas sync`                                      | Registry  | MEDIUM   | Sync from .STATUS files       |
| `atlas init`                                      | Setup     | LOW      | Initialize project            |
| `atlas config *`                                  | Config    | LOW      | Atlas configuration           |

### Help Browser Gaps (7 missing dispatchers)

**Currently listed (8):** `g`, `cc`, `wt`, `mcp`, `r`, `qu`, `obs`, `tm`

**Missing from help browser (7):** `dots`, `sec`, `tok`, `teach`, `prompt`, `v`, `em`

**Also missing:** `at` (Atlas shortcut), `flow` meta-command

### Help Preview Pattern Bug

`_flow_show_help_preview()` only recognizes 8 dispatchers in its regex:

```zsh
if [[ "$cmd" =~ ^(g|cc|wt|mcp|r|qu|obs|tm)$ ]]; then
```

Should be ALL 15 dispatchers.

---

## Proposals

### Proposal 1: Enhanced Atlas Bridge (Priority: HIGH)

**Goal:** Expose all user-requested Atlas features through the bridge layer with hybrid performance.

#### Hot Path (ZSH-native, < 10ms, async Atlas sync)

These stay ZSH-native with background Atlas calls:

- `_flow_session_start` — enhanced with `--energy`, `--estimate`, `--task` passthrough
- `_flow_session_end` — enhanced with celebration display
- `_flow_catch` — already good
- `_flow_where` — already good
- `_flow_crumb` — already good

#### Warm Path (Direct Atlas CLI, ~200-500ms OK)

New bridge functions that call Atlas directly:

```zsh
_flow_atlas_stats()     # atlas stats [period] --format
_flow_atlas_plan()      # atlas plan [--ecosystem]
_flow_atlas_park()      # atlas park [note]
_flow_atlas_unpark()    # atlas unpark [id]
_flow_atlas_parked()    # atlas parked
_flow_atlas_dash()      # atlas dashboard
_flow_atlas_focus()     # atlas focus <project> [text]
_flow_atlas_triage()    # atlas inbox --triage
```

#### Enhanced `at()` Function

```zsh
at() {
  if _flow_has_atlas; then
    atlas "$@"
  else
    case "$1" in
      # Existing fallbacks
      catch|c)   shift; _flow_catch "$@" ;;
      inbox|i)   _flow_inbox ;;
      where|w)   shift; _flow_where "$@" ;;
      crumb|b)   shift; _flow_crumb "$@" ;;
      # NEW: Helpful messages for Atlas-only features
      stats|plan|park|unpark|dash|focus)
        _flow_log_error "Atlas required for '$1'. Install: npm i -g @data-wise/atlas"
        ;;
      *)
        _flow_log_error "Atlas not installed."
        echo "Available fallback commands: catch, inbox, where, crumb"
        echo "Install Atlas for full features: npm i -g @data-wise/atlas"
        ;;
    esac
  fi
}
```

#### Estimated Effort: 2-3 hours

---

### Proposal 2: Fix Help Browser (Priority: HIGH, parallel with Proposal 1)

#### 2a: Update Command List

Add missing dispatchers and Atlas to help browser:

```zsh
local commands=(
    # ... existing commands ...

    # Missing dispatchers (ADD THESE)
    "dots:Dotfile management (chezmoi sync, diff, edit)"
    "sec:Secret management (macOS Keychain, Bitwarden)"
    "tok:Token management (create, rotate, expire)"
    "teach:Teaching workflow (analyze, deploy, exam, plan)"
    "prompt:Prompt engine switcher (set, show, compare)"
    "v:Vibe coding mode (start, stop, status)"
    "em:Email management (himalaya integration, 31 commands)"

    # Atlas shortcut
    "at:Atlas CLI (session, stats, plan, park, dash)"
)
```

#### 2b: Fix Dispatcher Regex

```zsh
# Before (only 8):
if [[ "$cmd" =~ ^(g|cc|wt|mcp|r|qu|obs|tm)$ ]]; then

# After (all 15 + at):
if [[ "$cmd" =~ ^(g|cc|wt|mcp|r|qu|obs|tm|dots|sec|tok|teach|prompt|v|em|at)$ ]]; then
```

#### Estimated Effort: 30 min

---

### Proposal 3: Atlas API Contract (Priority: MEDIUM)

Create a formal contract between flow-cli and Atlas to prevent integration breakage.

#### Three-Layer Contract

**Layer 1: Markdown Spec** (`docs/ATLAS-CONTRACT.md` in both repos)

```markdown
# Atlas ↔ flow-cli API Contract

## Version Compatibility

| flow-cli | Atlas  | Contract |
| -------- | ------ | -------- |
| v7.4.x   | v0.9.x | v1.0     |

## Required Commands (flow-cli depends on these)

- `atlas session start <project>` → stdout: session info
- `atlas session end [note]` → stdout: duration + celebration
- `atlas project list --format=names` → stdout: one name per line
- `atlas catch <text> [--project=<p>]` → stdout: confirmation
- `atlas where [project]` → stdout: context info
- `atlas crumb <text>` → stdout: confirmation

## Output Formats

- `--format=names`: plain text, one per line (NO JSON)
- `--format=json`: valid JSON object/array
- `--format=table`: human-readable table (default)
- `--format=shell`: shell-evaluable variables

## Exit Codes

- 0: success
- 1: error (message on stderr)
- 2: not found
```

**Layer 2: JSON Schema** (`docs/atlas-output-schema.json`)

Formal schemas for each command's JSON output format.

**Layer 3: Integration Tests** (`tests/test-atlas-contract.zsh`)

```zsh
# Verify Atlas CLI contract compliance
test_case "atlas project list --format=names returns plain text"
output=$(atlas project list --format=names 2>/dev/null)
assert_not_contains "$output" "{"  # No JSON
assert_not_contains "$output" "["  # No arrays

test_case "atlas session start returns zero exit code"
atlas session start test-project 2>/dev/null
assert_equals "$?" "0"
atlas session end 2>/dev/null  # cleanup
```

#### Estimated Effort: 2-3 hours

---

### Proposal 4: Doctor Enhancement (Priority: LOW)

Enhance `flow doctor` Atlas checks:

```
## Atlas Integration
  ✓ atlas installed (v0.9.0)
  ✓ atlas connected (filesystem backend)
  ✓ atlas project list works (12 projects)
  ○ atlas MCP server not running (optional)
  ○ atlas dashboard dependencies missing (optional)
```

#### Estimated Effort: 1 hour

---

## Quick Wins (< 30 min each)

1. **Fix help browser dispatcher list** — add 7 missing dispatchers + `at` (30 min)
2. **Fix help preview regex** — update dispatcher match pattern (5 min)
3. **Add `at` to welcome message** — show `at` shortcut in startup info (5 min)
4. **Improve `at()` error messages** — helpful install + fallback info (15 min)

## Medium Effort (1-3 hours)

5. **Enhanced bridge functions** — `_flow_atlas_stats`, `_flow_atlas_plan`, `_flow_atlas_park/unpark` (2h)
6. **Session start enhancement** — pass energy, estimate, task to Atlas (1h)
7. **API contract spec** — `docs/ATLAS-CONTRACT.md` in both repos (2h)

## Long-term (Future sessions)

8. **Contract integration tests** — `tests/test-atlas-contract.zsh` (2h)
9. **JSON schema for Atlas outputs** — formal validation (3h)
10. **Atlas MCP ↔ flow-cli coordination** — MCP server tools alignment (4h)
11. **Ink dashboard integration** — `at dash` from flow-cli with project context (3h)

---

## Recommended Path

→ **Start with Quick Wins #1-2** (fix help browser, 35 min) — immediate user-visible improvement

→ **Then Proposal 1** (enhanced bridge) — unlocks stats, plan, park/unpark

→ **Then Proposal 3** (API contract) — prevents future breakage as both projects evolve

---

## Architecture Decision: Enhanced Bridge (Not Dispatcher)

**Why bridge, not dispatcher?**

The user chose "Enhanced bridge" over "Full dispatcher" because:

1. Atlas already has its own CLI identity (`atlas`, `at`)
2. flow-cli's job is to _coordinate_, not duplicate
3. Bridge pattern allows graceful degradation (works without Atlas)
4. Dispatcher pattern implies flow-cli owns the commands — Atlas owns its own commands

**Hybrid performance model:**

- Hot path (< 10ms): session start/end, catch, where, crumb → ZSH-native + async Atlas
- Warm path (< 500ms): stats, plan, park, dash → Direct Atlas CLI call (acceptable latency)

---

## Atlas CLI Full Command Inventory (v0.9.0)

### Top-Level Commands

| Command       | Subcommands                                      | flow-cli bridge?         |
| ------------- | ------------------------------------------------ | ------------------------ |
| `project`     | add, list, show, remove                          | Partial (list only)      |
| `session`     | start, end, status, export                       | Partial (start/end only) |
| `focus`       | (direct)                                         | No                       |
| `status`      | (direct)                                         | No                       |
| `stats`       | (direct)                                         | No                       |
| `plan`        | (direct)                                         | No                       |
| `catch`       | (direct)                                         | Yes                      |
| `inbox`       | (direct)                                         | Partial (no triage)      |
| `where`       | (direct)                                         | Yes                      |
| `crumb`       | (direct)                                         | Yes                      |
| `trail`       | (direct)                                         | No                       |
| `park`        | (direct)                                         | No                       |
| `unpark`      | (direct)                                         | No                       |
| `parked`      | (direct)                                         | No                       |
| `dashboard`   | (direct)                                         | No                       |
| `init`        | (direct)                                         | No                       |
| `template`    | list, show, create, export, delete               | No                       |
| `sync`        | (direct)                                         | No                       |
| `migrate`     | (direct)                                         | No                       |
| `completions` | (direct)                                         | No                       |
| `config`      | paths, add-path, remove-path, show, setup, prefs | No                       |

**Coverage: 6/22 top-level commands bridged (27%)**

### Atlas MCP Server Tools (10 tools, not yet coordinated)

| MCP Tool              | Type     | Description                                 |
| --------------------- | -------- | ------------------------------------------- |
| `atlas_get_context`   | Read     | Current session, breadcrumbs, status, inbox |
| `atlas_get_projects`  | Read     | List projects (filter: status, tag)         |
| `atlas_get_sessions`  | Read     | Session statistics                          |
| `atlas_get_trail`     | Read     | Breadcrumb trail                            |
| `atlas_get_inbox`     | Read     | Capture inbox                               |
| `atlas_start_session` | Write    | Start work session                          |
| `atlas_end_session`   | Write    | End session                                 |
| `atlas_capture`       | Write    | Quick capture                               |
| `atlas_breadcrumb`    | Write    | Log breadcrumb                              |
| `atlas_plan`          | Planning | Morning planning summary                    |

### Atlas ADHD Preferences (could align with flow-cli)

| Preference                | Default | Description                 |
| ------------------------- | ------- | --------------------------- |
| `adhd.showStreak`         | true    | Track consecutive work days |
| `adhd.showTimeCues`       | true    | Gentle time awareness       |
| `adhd.showCelebrations`   | true    | Achievement celebrations    |
| `adhd.showContextRestore` | true    | "Last time you..."          |
| `session.pomodoroLength`  | 25      | Work period (minutes)       |
| `dashboard.zenMode`       | false   | Minimal UI                  |

---

## Proposal 5: Atlas CLI Help Standardization (Priority: MEDIUM)

**Goal:** Atlas CLI help output should follow flow-cli conventions for consistency.

### flow-cli Help Convention (from `docs/internal/conventions/adhd/HELP-PAGE-TEMPLATE.md`)

Every dispatcher `_x_help()` follows this pattern:

1. **Box header** — Bold bordered title (`╭──╮ / │ │ / ╰──╯`)
2. **Usage line** — `Usage: x [subcommand] [args]`
3. **Most Common section** — Top 5 commands (80% of daily use)
4. **Quick Examples** — Real-world `$ x foo` examples with dim comments
5. **Full command list** — All subcommands grouped by category
6. **Color scheme** — Cyan for commands, green for headers, dim for comments, yellow for section labels

### Current Atlas CLI Help (plain, no conventions)

```
atlas session start <project>  # Start a work session
atlas catch <text>             # Quick capture
...
```

### Proposed Atlas Help Alignment

Two approaches:

#### 5a: Atlas-side standardization

- Atlas adds `--help-flow` flag that outputs in flow-cli format
- Atlas uses chalk/picocolors for ANSI colors matching flow-cli palette
- Pro: Atlas controls its own output
- Con: Two different help formats to maintain

#### 5b: flow-cli help wrapper (Recommended)

- flow-cli's `at()` function intercepts `at help` / `at --help`
- Renders Atlas help in flow-cli style using `lib/core.zsh` colors
- Pro: Single source of truth for help format
- Con: flow-cli must keep up with Atlas command changes → solved by API contract

#### 5c: Shared help template

- Both repos use the same help page structure from `HELP-PAGE-TEMPLATE.md`
- Atlas Node.js helper generates ANSI output matching ZSH color scheme
- Pro: True consistency
- Con: More coordination effort

### Recommended: 5b (flow-cli help wrapper)

```zsh
_at_help() {
    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ at - Atlas Project Intelligence             │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_BOLD}Usage:${_C_NC} at [command] [args]

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(daily workflow)${_C_NC}:
  ${_C_CYAN}at stats${_C_NC}           Session analytics
  ${_C_CYAN}at plan${_C_NC}            Morning planning ritual
  ${_C_CYAN}at park \"note\"${_C_NC}     Save context before switching
  ${_C_CYAN}at unpark${_C_NC}          Restore parked context
  ${_C_CYAN}at dash${_C_NC}            Launch TUI dashboard

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} at stats week        ${_C_DIM}# Weekly session summary${_C_NC}
  ${_C_DIM}\$${_C_NC} at plan              ${_C_DIM}# Morning planning ritual${_C_NC}
  ${_C_DIM}\$${_C_NC} at park \"switching\"  ${_C_DIM}# Save context${_C_NC}
  ${_C_DIM}\$${_C_NC} at dash              ${_C_DIM}# Launch dashboard${_C_NC}

${_C_YELLOW}SESSION${_C_NC}:
  ${_C_CYAN}at session start <project>${_C_NC}  Start session (usually via 'work')
  ${_C_CYAN}at session end [note]${_C_NC}       End session (usually via 'finish')
  ${_C_CYAN}at session status${_C_NC}           Current session info
  ${_C_CYAN}at session export${_C_NC}           Export to iCal

${_C_YELLOW}CAPTURE${_C_NC}:
  ${_C_CYAN}at catch \"text\"${_C_NC}             Quick capture idea
  ${_C_CYAN}at inbox${_C_NC}                    Show inbox
  ${_C_CYAN}at inbox --triage${_C_NC}           Interactive triage

${_C_YELLOW}CONTEXT${_C_NC}:
  ${_C_CYAN}at where${_C_NC}                    Where was I?
  ${_C_CYAN}at crumb \"text\"${_C_NC}             Leave breadcrumb
  ${_C_CYAN}at trail${_C_NC}                    View breadcrumb trail
  ${_C_CYAN}at park [note]${_C_NC}              Save context
  ${_C_CYAN}at unpark [id]${_C_NC}              Restore context
  ${_C_CYAN}at parked${_C_NC}                   List parked contexts

${_C_YELLOW}PROJECT${_C_NC}:
  ${_C_CYAN}at project list${_C_NC}             List all projects
  ${_C_CYAN}at project show <name>${_C_NC}      Project details
  ${_C_CYAN}at focus <project> [text]${_C_NC}   Get/set focus
  ${_C_CYAN}at status [project]${_C_NC}         Get/set status

${_C_DIM}Atlas v\$(atlas -v 2>/dev/null || echo '?') | at = atlas shortcut${_C_NC}
"
}
```

### Files Affected

| File                     | Change                                           |
| ------------------------ | ------------------------------------------------ |
| `lib/atlas-bridge.zsh`   | Add `_at_help()`, update `at()` to handle `help` |
| Atlas docs               | Reference flow-cli help conventions              |
| `docs/ATLAS-CONTRACT.md` | Include help format spec                         |

#### Estimated Effort: 1-2 hours

---

## User Decisions Captured

| Decision                 | Choice                                    | Rationale                         |
| ------------------------ | ----------------------------------------- | --------------------------------- |
| Architecture             | Enhanced bridge (not dispatcher)          | Atlas owns its commands           |
| Help fix                 | Both in parallel with bridge work         | Fix visibility + add features     |
| Atlas features           | All 4 (sessions, dash, planning, parking) | Full integration desired          |
| Development coordination | API contract                              | Formal boundary between projects  |
| Performance model        | Hybrid                                    | Hot path ZSH, warm path Atlas CLI |
| Contract format          | All three (spec + schema + tests)         | Comprehensive protection          |
| Help conventions         | flow-cli wrapper (5b)                     | Single format source of truth     |

---

_Generated by /workflow:brainstorm max feat save_
_Agents: 2 (Atlas bridge analysis, Atlas CLI inventory)_
