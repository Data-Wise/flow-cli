# Flow-CLI Workflow System Architecture Analysis

**Date:** 2026-01-09
**Scope:** Backend architecture patterns for workflow system design
**Codebase:** flow-cli v4.9.2 (11,373 LOC, 43 ZSH files)

---

## Executive Summary

flow-cli demonstrates a **pure-shell, stateless-by-default architecture** with optional stateful enhancement through atlas. This analysis reveals patterns for scalable workflow systems:

1. **Dual-mode state management** - Local filesystem fallback + optional state engine
2. **Dispatcher pattern** - Single-letter commands with domain-specific subcommands
3. **Graceful degradation** - Works without dependencies, enhanced with them
4. **Context propagation via environment** - Session state in `$FLOW_*` variables + files
5. **Command composition through chaining** - Not orchestration, but sequential execution

---

## 1. State Management Architecture

### 1.1 State Layers

flow-cli manages state across **three persistence layers**:

```
┌─────────────────────────────────────────────────────────┐
│ Layer 1: Environment Variables (Ephemeral)             │
│ - $FLOW_CURRENT_PROJECT                                 │
│ - $FLOW_SESSION_START                                   │
│ - $FLOW_PROJECTS_ROOT                                   │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ Layer 2: Local Files (Persistent, per-session)         │
│ - ~/.config/flow-cli/.current-session                   │
│ - ~/Library/Application Support/flow-cli/worklog        │
│ - ~/Library/Application Support/flow-cli/inbox.md       │
│ - ~/Library/Application Support/flow-cli/wins.md        │
│ - ~/Library/Application Support/flow-cli/trail.log      │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│ Layer 3: Project State (Persistent, per-project)       │
│ - {project}/.STATUS                                     │
│ - {project}/.claude/                                    │
│ - {project}/.git/                                       │
└─────────────────────────────────────────────────────────┘
                        ↓ (optional)
┌─────────────────────────────────────────────────────────┐
│ Layer 4: Atlas State Engine (Enhanced, when available) │
│ - Centralized session tracking                          │
│ - Cross-project context                                 │
│ - Advanced querying                                     │
└─────────────────────────────────────────────────────────┘
```

**Key Pattern:** Each layer is **self-sufficient** for its scope:
- Layer 1 provides in-session context (environment variables)
- Layer 2 provides cross-session user data (logs, inbox, wins)
- Layer 3 provides project-specific metadata (.STATUS files)
- Layer 4 provides enhanced capabilities (atlas, optional)

### 1.2 State Consistency Requirements

**Consistency Model:** **Eventually consistent** across layers

```zsh
# Example: Session state sync (lib/atlas-bridge.zsh:195-250)
_flow_session_start() {
  local project="$1"

  # 1. Write to local file (Layer 2) - ALWAYS
  echo "project=$project" > "$_FLOW_SESSION_FILE"
  echo "start=$EPOCHSECONDS" >> "$_FLOW_SESSION_FILE"

  # 2. Export to environment (Layer 1) - ALWAYS
  export FLOW_CURRENT_PROJECT="$project"
  export FLOW_SESSION_START="$EPOCHSECONDS"

  # 3. Sync to atlas (Layer 4) - OPTIONAL, fire-and-forget
  if _flow_has_atlas; then
    _flow_atlas session start "$project"  # Non-blocking
  else
    # Fallback: Log to worklog
    echo "$(_flow_timestamp) START $project" >> "$worklog"
  fi
}
```

**No distributed locks or transactions** - State propagates through:
1. Function calls (synchronous)
2. File writes (atomic at OS level)
3. Atlas updates (fire-and-forget, eventual)

**Trade-off:** Simplicity over strong consistency. Acceptable because:
- Sessions are single-user
- Conflicts self-resolve (last-write-wins)
- Critical data (git commits) uses git's consistency model

### 1.3 State Storage Patterns

#### Pattern 1: Key-Value Files

```zsh
# .current-session format (simple key=value)
project=flow-cli
start=1736451234
date=2026-01-09
```

**Operations:**
- Read: `grep "^key=" file | cut -d= -f2`
- Write: `echo "key=value" >> file`
- Update: No update - always append or overwrite entire file

#### Pattern 2: Append-Only Logs

```zsh
# worklog format (timestamped events)
2026-01-09 14:30:00 START flow-cli
2026-01-09 15:45:00 END 75m (Completed CC unified grammar)
```

**Operations:**
- Append: `echo "$timestamp $event" >> logfile`
- Query: `grep "pattern" logfile | tail -n 20`

**Benefits:**
- No file locking needed
- Crash-safe (append is atomic)
- Natural audit trail

#### Pattern 3: Markdown Lists

```zsh
# wins.md format (structured markdown)
- 💻 Implemented CC unified grammar (@flow-cli) #code [2026-01-09 14:30]
- 🚀 Deployed v4.9.2 to production #ship [2026-01-09 15:45]
```

**Operations:**
- Append: `echo "- $icon $text #$category [$timestamp]" >> wins.md`
- Parse: Regex extraction `[[ "$line" =~ pattern ]]`
- Aggregate: Count matches by date/category

**Benefits:**
- Human-readable
- Git-diffable
- Supports rich formatting (icons, tags, timestamps)

### 1.4 Session State Lifecycle

```
┌─────────────┐
│ work <proj> │  ← User initiates session
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────┐
│ _flow_session_start()           │
│ - Write .current-session        │
│ - Export $FLOW_CURRENT_PROJECT  │
│ - Log to worklog                │
│ - Sync to atlas (optional)      │
└──────┬──────────────────────────┘
       │
       ▼
┌─────────────────────────────────┐
│ Active Session                  │
│ - $FLOW_CURRENT_PROJECT set     │
│ - .current-session exists       │
│ - Timer running                 │
└──────┬──────────────────────────┘
       │
       ▼
┌─────────────┐
│ finish [msg]│  ← User ends session
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────┐
│ _flow_session_end()             │
│ - Calculate duration            │
│ - Log to worklog                │
│ - Clean up .current-session     │
│ - Unset environment vars        │
│ - Sync to atlas (optional)      │
└─────────────────────────────────┘
```

**State Recovery:** If shell crashes, `.current-session` persists:
- Next shell reads orphaned session file
- Can recover or clean up manually
- Duration calculation still possible (start timestamp preserved)

---

## 2. Command Composition Patterns

### 2.1 Current Composition Chains

flow-cli supports **implicit chaining** through command sequences:

#### Chain 1: Full Workflow Session

```bash
# Explicit sequence (user types each)
work flow-cli       # Start session, export $FLOW_CURRENT_PROJECT
win "Fixed bug"     # Log accomplishment (reads $FLOW_CURRENT_PROJECT)
finish "All done"   # End session, optionally commit git changes
```

**Context propagation:**
- `work` → Exports `$FLOW_CURRENT_PROJECT`
- `win` → Reads `$FLOW_CURRENT_PROJECT` to tag win
- `finish` → Reads `.current-session` for duration calculation

#### Chain 2: Pick → Launch → Push

```bash
# User sequence
pick                # cd to project (changes $PWD)
cc                  # Launch Claude in $PWD
g push              # Push changes (reads $PWD/.git)
```

**Context propagation:**
- `pick` → Changes `$PWD` via `cd`
- `cc` → Launches Claude with `$PWD` as context
- `g push` → Operates on `$PWD` git repo

#### Chain 3: Dispatcher → Subcommand

```bash
# Single command with subcommand
r test              # Run R package tests
qu preview          # Preview Quarto document
g feature start foo # Start feature branch
```

**Context propagation:**
- Dispatchers read `$PWD` for project context
- Subcommands inherit dispatcher's context detection

### 2.2 Missing Composition Patterns

**Gap Analysis:** What composition patterns are NOT possible?

#### Missing: Cross-Command Pipes

```bash
# NOT SUPPORTED: Pipe output between commands
pick --format=json | cc --from-json  # ❌ No JSON pipe interface
```

**Why missing:** Commands are designed for **human interaction**, not machine consumption.

**Solution for workflows:**
- Add `--format=json` to relevant commands
- Commands output structured data
- Downstream commands accept structured input

#### Missing: Conditional Chaining

```bash
# NOT SUPPORTED: Run next command only if previous succeeds
work flow-cli && r test && g push  # ✅ Shell-level (bash &&)
```

**Actually works:** Shell's `&&` provides conditional chaining.

**Flow-CLI role:** Ensure commands exit with correct codes:
- 0 = success
- Non-zero = failure

#### Missing: Workflow Templates

```bash
# NOT SUPPORTED: Named workflow templates
flow workflow run "feature-complete"  # ❌ No workflow engine
```

**Workaround:** User creates shell functions:

```bash
feature_complete() {
  work "$1" || return 1
  r test || return 1
  r check || return 1
  g push || return 1
  gh pr create --fill
  finish "Feature complete"
}
```

**Integration point:** flow-cli could provide:
- `flow workflow define <name> <commands>`
- `flow workflow run <name>`
- Workflow templates in `~/.config/flow-cli/workflows/`

### 2.3 Command Composition APIs

**Current API:** Commands communicate through:

1. **Environment variables**

   ```zsh
   export FLOW_CURRENT_PROJECT="flow-cli"
   ```

2. **File state**

   ```zsh
   echo "project=flow-cli" > ~/.config/flow-cli/.current-session
   ```

3. **Exit codes**

   ```zsh
   return 0  # Success
   return 1  # Failure
   ```

4. **stdout/stderr**

   ```zsh
   echo "Output"        # To stdout
   echo "Error" >&2     # To stderr
   ```

**For workflow system integration:**

Add **structured output mode**:

```zsh
# Example: pick --format=json
pick --format=json
# Output:
# {"project":"flow-cli","path":"/Users/dt/projects/dev-tools/flow-cli","type":"node"}
```

Add **command hooks**:

```zsh
# Example: Run script after successful command
work --after="notify-send 'Session started'"
finish --after="~/scripts/backup-session.sh"
```

---

## 3. Context Propagation Mechanisms

### 3.1 Context Types

flow-cli propagates **three context types**:

#### Project Context

```zsh
# Detected from $PWD
_flow_detect_project_type "$PWD"  # → "r-package" | "node" | "quarto"
_flow_find_project_root           # → "/Users/dt/projects/dev-tools/flow-cli"
_flow_project_name "$path"        # → "flow-cli"
```

**Propagation:**
- Every command that needs project context calls these functions
- No global state - always computed from `$PWD`

#### Session Context

```zsh
# From environment + file
$FLOW_CURRENT_PROJECT              # Exported by work command
$FLOW_SESSION_START                # Exported by work command
~/.config/flow-cli/.current-session # Persisted session state
```

**Propagation:**
- Environment variables (exported, inherited by subshells)
- Session file (read on-demand)

#### User Context

```zsh
# From user data files
~/Library/Application Support/flow-cli/wins.md        # Accomplishments
~/Library/Application Support/flow-cli/inbox.md       # Captured items
~/Library/Application Support/flow-cli/goal.json      # Daily goal
```

**Propagation:**
- Read/written by commands as needed
- No in-memory cache

### 3.2 Context Resolution Order

When a command needs context, it checks sources in order:

```zsh
# Example: win command (commands/capture.zsh:192-197)
win() {
  local project=""

  # 1. Try to detect from current directory
  if _flow_in_project; then
    project=$(_flow_project_name "$(_flow_find_project_root)")
  fi

  # 2. Tag win with project context
  echo "- $icon $text${project:+ (@$project)} #$category [$timestamp]" >> "$wins"
}
```

**Resolution order:**
1. Explicit argument (if provided)
2. Environment variable (`$FLOW_CURRENT_PROJECT`)
3. Current directory (`$PWD` → detect project root)
4. Session file (`.current-session`)
5. Default/fallback

### 3.3 Cross-Project Context

**Challenge:** How to track context across multiple projects?

**Current approach:** Atlas (optional)

```zsh
# atlas tracks:
- Active sessions across projects
- Project relationships
- Cross-project breadcrumbs
```

**Without atlas:**
- Each project's context is isolated
- No cross-project queries
- User manually tracks relationships

**For workflow system:**

Support **project relationships** in `.STATUS`:

```yaml
## Related Projects:
- aiterm (CLI tool)
- atlas (state engine)
- homebrew-tap (distribution)
```

Commands can then:
- Suggest related projects to work on
- Show cross-project dependencies
- Cascade updates (e.g., `flow cascade update CHANGELOG`)

---

## 4. Plugin Integration Architecture

### 4.1 Current Extension Points

flow-cli provides **zero formal extension points**. All customization is:

1. **User functions in ~/.zshrc**

   ```zsh
   # User adds custom function
   my_workflow() {
     work "$1" && r test && g push
   }
   ```

2. **Dispatcher passthrough**

   ```zsh
   # Unknown subcommands pass to underlying tool
   g cherry-pick abc123  # → git cherry-pick abc123
   r install devtools    # → R -e 'install.packages("devtools")'
   ```

3. **Environment variable overrides**

   ```zsh
   export FLOW_PROJECTS_ROOT="$HOME/work"
   export FLOW_ATLAS_ENABLED="no"
   ```

### 4.2 Proposed Plugin Architecture

**Design:** Lightweight plugin system for workflow extensions

```
~/.config/flow-cli/plugins/
  my-workflow/
    plugin.zsh              # Entry point
    commands/
      deploy.zsh            # Custom command: flow deploy
      backup.zsh            # Custom command: flow backup
    hooks/
      pre-work.zsh          # Runs before 'work' command
      post-finish.zsh       # Runs after 'finish' command
```

#### Plugin Manifest

```zsh
# plugin.zsh
PLUGIN_NAME="my-workflow"
PLUGIN_VERSION="1.0.0"
PLUGIN_DESCRIPTION="Custom deployment workflow"

# Register commands
flow_plugin_register_command "deploy" "$PLUGIN_DIR/commands/deploy.zsh"
flow_plugin_register_command "backup" "$PLUGIN_DIR/commands/backup.zsh"

# Register hooks
flow_plugin_register_hook "pre-work" "$PLUGIN_DIR/hooks/pre-work.zsh"
flow_plugin_register_hook "post-finish" "$PLUGIN_DIR/hooks/post-finish.zsh"
```

#### Hook Points

```zsh
# Proposed hook points in flow-cli core

# lib/hooks.zsh
_flow_run_hook() {
  local hook_name="$1"
  shift

  # Run plugin hooks
  for plugin in "${FLOW_PLUGINS[@]}"; do
    local hook_file="$FLOW_PLUGIN_DIR/$plugin/hooks/$hook_name.zsh"
    if [[ -f "$hook_file" ]]; then
      source "$hook_file" "$@"
    fi
  done
}

# commands/work.zsh (modified)
work() {
  _flow_run_hook "pre-work" "$project"  # ← Hook point

  # ... existing work logic ...

  _flow_run_hook "post-work" "$project"  # ← Hook point
}
```

**Hook API:**

```zsh
# hooks/pre-work.zsh example
# Receives: $1 = project name
# Can: Read state, print messages, abort with exit code

if [[ "$1" == "production" ]]; then
  echo "⚠️  Working on production - be careful!"
fi
```

### 4.3 Workflow Plugin Example

```zsh
# plugins/feature-workflow/commands/feature-complete.zsh

flow-feature-complete() {
  local branch=$(git branch --show-current)

  echo "🚀 Running feature-complete workflow for $branch"

  # 1. Run tests
  echo "  Running tests..."
  r test || { echo "❌ Tests failed"; return 1; }

  # 2. Update CHANGELOG
  echo "  Updating CHANGELOG..."
  catch "Feature complete: $branch" >> CHANGELOG.md

  # 3. Commit + push
  echo "  Committing changes..."
  g aa
  g commit "feat: Complete $branch"
  g push

  # 4. Create PR
  echo "  Creating PR..."
  gh pr create --fill

  # 5. Log win
  win "Completed feature $branch" --category=ship

  # 6. End session
  finish "Feature $branch shipped"
}
```

**Usage:**

```bash
flow feature-complete  # Runs entire workflow
```

---

## 5. Scalability Analysis

### 5.1 Command Organization

**Current structure:** 43 ZSH files organized as:

```
flow.plugin.zsh              # Entry point
lib/                         # 20 files (core utilities)
  core.zsh                   # Logging, colors, helpers
  atlas-bridge.zsh           # State engine integration
  project-detector.zsh       # Project type detection
  dispatchers/               # 9 files (domain dispatchers)
    g-dispatcher.zsh         # Git workflows
    cc-dispatcher.zsh        # Claude Code
    mcp-dispatcher.zsh       # MCP servers
    obs.zsh                  # Obsidian
    qu-dispatcher.zsh        # Quarto
    r-dispatcher.zsh         # R packages
    tm-dispatcher.zsh        # Terminal manager
    wt-dispatcher.zsh        # Worktrees
commands/                    # 7 files (core commands)
  work.zsh                   # Session management
  dash.zsh                   # Dashboard
  capture.zsh                # Quick capture (win, catch)
  adhd.zsh                   # ADHD helpers (js, next, stuck)
  flow.zsh                   # Meta-command
  doctor.zsh                 # Health check
  pick.zsh                   # Project picker
```

**Pattern: Dispatchers for domains**

- Single-letter function: `g`, `r`, `qu`, `obs`, `cc`, `mcp`, `tm`, `wt`
- Domain-specific subcommands: `g push`, `r test`, `qu preview`
- Help system: `g help`, `r help`

**Scalability:** When to add new dispatcher vs. subcommand?

**Add dispatcher when:**
- Distinct domain (e.g., Docker workflows → `dk` dispatcher)
- 5+ related commands
- Existing dispatchers don't fit

**Add subcommand when:**
- Extends existing domain
- < 5 commands
- Natural fit with dispatcher's scope

**Example: Should "workflow" be a dispatcher?**

```
Option 1: New dispatcher `w` or `wf`
  wf list
  wf run <name>
  wf define <name>

Option 2: Subcommand of `flow`
  flow workflow list
  flow workflow run <name>
  flow workflow define <name>

Decision: Option 2 (subcommand)
Reason: Workflow management is meta-functionality, fits under `flow` namespace
```

### 5.2 Namespace Collision Avoidance

**Current strategy:**

1. **Single-letter dispatchers:** `g`, `r`, `cc`, `qu`, `tm`, `wt`, `mcp`, `obs`
2. **Full-word commands:** `work`, `finish`, `pick`, `dash`, `catch`, `win`
3. **Internal functions:** Prefixed with `_flow_*`

**Future risk:** As command count grows (30+), namespace collisions increase.

**Mitigation strategies:**

1. **Namespaced commands**

   ```bash
   flow:session:start    # Explicit namespace
   flow:project:pick     # Explicit namespace
   ```

2. **Reserved prefixes**

   ```bash
   flow-*     # Reserved for flow-cli
   _flow_*    # Internal functions
   ```

3. **Dispatcher-only for domains**
   - Limit top-level commands to 10-15
   - Everything else under dispatchers

**Recommendation:** Stick with dispatcher pattern, add **workflow dispatcher** when workflow count exceeds 5.

### 5.3 Performance Considerations

**Current performance:** Sub-10ms for core commands

```bash
$ time work flow-cli
real    0m0.008s   # 8ms

$ time pick
real    0m0.125s   # 125ms (fzf startup)

$ time g
real    0m0.004s   # 4ms
```

**Performance bottlenecks:**

1. **Project scanning** (pick, dash)
   - Searches entire `$FLOW_PROJECTS_ROOT` for `.STATUS` files
   - Mitigated: Caching, parallel scanning

2. **Git operations** (g, wt)
   - Git commands inherently slow
   - Mitigated: Use git's fast commands (status -sb vs status)

3. **External dependencies** (fzf, gum, atlas)
   - Process startup overhead
   - Mitigated: Optional dependencies, fallback paths

**For workflow system:**

- **Cache project list** in `~/.config/flow-cli/project-cache.json`
- **Invalidate on:** New project detection, manual refresh
- **TTL:** 1 hour (or until next shell restart)

```zsh
_flow_list_projects_cached() {
  local cache_file="$FLOW_CONFIG_DIR/project-cache.json"
  local cache_ttl=3600  # 1 hour

  if [[ -f "$cache_file" ]]; then
    local cache_age=$(( $(date +%s) - $(stat -f %m "$cache_file") ))
    if (( cache_age < cache_ttl )); then
      cat "$cache_file"
      return
    fi
  fi

  # Rebuild cache
  local projects=$(_flow_list_projects)
  echo "$projects" > "$cache_file"
  echo "$projects"
}
```

---

## 6. Integration Patterns

### 6.1 Atlas Integration Pattern

**Design:** Optional state engine with graceful degradation

```zsh
# Pattern: Check availability once, cache result
typeset -g _FLOW_ATLAS_AVAILABLE

_flow_has_atlas() {
  # Return cached result
  if [[ -n "$_FLOW_ATLAS_AVAILABLE" ]]; then
    [[ "$_FLOW_ATLAS_AVAILABLE" == "yes" ]]
    return
  fi

  # Check if atlas exists
  if command -v atlas &>/dev/null; then
    _FLOW_ATLAS_AVAILABLE="yes"
    return 0
  else
    _FLOW_ATLAS_AVAILABLE="no"
    return 1
  fi
}

# Pattern: Use atlas if available, fallback otherwise
_flow_session_start() {
  if _flow_has_atlas; then
    atlas session start "$project"
  else
    # Fallback: local file
    echo "START $project $timestamp" >> "$worklog"
  fi
}
```

**Benefits:**
- Zero runtime overhead when atlas not installed
- Consistent API for commands (they don't care about implementation)
- Easy to test both modes

### 6.2 Dispatcher Integration Pattern

**Design:** Passthrough for unknown commands

```zsh
# Pattern: Dispatcher with passthrough
g() {
  case "$1" in
    # Known commands
    status|s) git status -sb ;;
    push|p)   _g_check_workflow && git push "$@" ;;

    # Unknown → passthrough to git
    *) git "$@" ;;
  esac
}
```

**Benefits:**
- Progressive enhancement (add shortcuts without breaking existing usage)
- Full git functionality still accessible
- User can use `g` as drop-in replacement for `git`

### 6.3 Tool Integration Patterns

**Pattern: Check → Fallback → Enhance**

```zsh
# Example: gum integration for better UX
_flow_has_gum() {
  command -v gum &>/dev/null
}

catch() {
  if _flow_has_gum; then
    text=$(gum input --placeholder="Quick idea..." --width=60)
  else
    read "text?💡 Quick capture: "
  fi
}
```

---

## 7. Workflow System Recommendations

### 7.1 Architecture Principles

Based on flow-cli analysis, a workflow system should:

1. **Stateless by default, stateful by choice**
   - Commands work without state engine
   - State engine provides enhanced features

2. **File-based state with atomic writes**
   - Append-only logs
   - Key-value files
   - Markdown lists

3. **Context propagation via environment**
   - Export key variables
   - Read from `$PWD` when needed
   - Session files for persistence

4. **Dispatcher pattern for scalability**
   - Domain-specific dispatchers
   - Subcommands within domains
   - Passthrough for flexibility

5. **Plugin system for extensibility**
   - Hook points at lifecycle events
   - Custom command registration
   - Isolated plugin directories

### 7.2 Integration Patterns for Workflow Engine

**Option 1: External workflow engine (like atlas)**

```bash
# flow-cli delegates to workflow engine
work flow-cli  # → workflow start session flow-cli
finish         # → workflow end session
```

**Pros:**
- Separation of concerns
- flow-cli stays simple
- Workflow engine can support multiple tools

**Cons:**
- Extra dependency
- Two tools to maintain
- Complex communication

**Option 2: Built-in workflow commands**

```bash
# flow-cli has workflow subcommands
flow workflow define deploy "r test && g push && gh pr create"
flow workflow run deploy
```

**Pros:**
- Integrated experience
- Single tool
- Easier to use

**Cons:**
- flow-cli becomes more complex
- Hard to scale beyond basic workflows

**Recommendation:** **Hybrid approach**

- Built-in: Simple workflows (templates, sequences)
- External: Complex orchestration (conditional logic, parallel execution)

```bash
# Simple (built-in)
flow workflow run deploy  # Sequential: r test && g push

# Complex (external)
atlas workflow run ci-pipeline  # Parallel, conditional, cross-project
```

### 7.3 Proposed Workflow API

```bash
# Define workflow template
flow workflow define <name> <commands...>
flow workflow define deploy "r test && g push && gh pr create --fill"

# Run workflow
flow workflow run <name>
flow workflow run deploy

# List workflows
flow workflow list

# Edit workflow
flow workflow edit <name>

# Delete workflow
flow workflow delete <name>

# Show workflow steps
flow workflow show <name>
```

**Storage:**

```bash
~/.config/flow-cli/workflows/
  deploy.yaml
  ci.yaml
  release.yaml
```

**Format:**

```yaml
# deploy.yaml
name: deploy
description: Run tests, push, create PR
steps:
  - command: r test
    description: Run R package tests
    on_fail: abort

  - command: g push
    description: Push to remote
    on_fail: abort

  - command: gh pr create --fill
    description: Create pull request
    on_fail: warn

  - command: win "Deployed changes"
    description: Log win
    on_fail: ignore
```

---

## 8. Conclusions

### 8.1 Key Architectural Patterns

1. **Dual-mode state management**
   - Local files for essential state
   - Optional state engine for enhancement
   - Fire-and-forget sync (no blocking)

2. **Dispatcher pattern for scalability**
   - Single-letter dispatchers for domains
   - Domain-specific subcommands
   - Passthrough for full tool access

3. **Context propagation hierarchy**
   - Environment variables (ephemeral)
   - Session files (persistent)
   - Project files (.STATUS)
   - State engine (enhanced)

4. **Graceful degradation everywhere**
   - Check tool availability once, cache result
   - Fallback implementations for all features
   - Works without any external dependencies

### 8.2 Workflow System Integration Points

For a workflow system to integrate with flow-cli:

1. **State persistence:** Use flow-cli's file-based state (wins.md, worklog, .STATUS)
2. **Context access:** Read `$FLOW_CURRENT_PROJECT`, `$PWD`, `.current-session`
3. **Command composition:** Chain commands with `&&`, read exit codes
4. **Hook points:** Add hooks at work/finish lifecycle events
5. **Plugin API:** Register custom workflow commands

### 8.3 Next Steps

1. **Implement plugin system** (hooks + custom commands)
2. **Add workflow subcommands** (define, run, list)
3. **Create workflow templates** (deploy, ci, release)
4. **Integrate with atlas** for advanced orchestration
5. **Document workflow patterns** for users

---

**Document Version:** 1.0
**Last Updated:** 2026-01-09
**Author:** Claude Sonnet 4.5 (Architecture Analysis)
**Codebase Analyzed:** flow-cli v4.9.2 (43 files, 11,373 LOC)
