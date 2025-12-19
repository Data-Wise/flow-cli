# ZSH Functions File Reorganization Plan

**Agent:** Agent 4 (File Organizer)
**Date:** 2025-12-19
**Status:** Ready for Review & Execution

## Overview

This document outlines the complete reorganization of ZSH configuration files from a flat structure into a modular, maintainable directory hierarchy.

## Current State

```
~/.config/zsh/functions/
├── adhd-helpers.zsh (3198 lines - MASSIVE, needs splitting)
├── smart-dispatchers.zsh (880 lines - has r, qu, cc, gm, note, workflow)
├── g-dispatcher.zsh (git dispatcher)
├── v-dispatcher.zsh (vibe/energy dispatcher)
├── mcp-dispatcher.zsh (MCP tools dispatcher)
├── work.zsh
├── dash.zsh
├── fzf-helpers.zsh
├── core-utils.zsh (symlink)
├── bg-agents.zsh
├── claude-workflows.zsh
├── claude-response-viewer.zsh
├── genpass.zsh
├── hub-commands.zsh
├── obsidian-bridge.zsh
├── obs.zsh (symlink)
├── project-detector.zsh (symlink)
├── status.zsh
├── v-utils.zsh
└── zsh-clean.zsh
```

## Target Structure

```
~/.config/zsh/functions/
├── dispatchers/                    # NEW: All dispatchers in one place
│   ├── README.md                   # Index of all dispatchers
│   ├── r-dispatcher.zsh           # Extract from smart-dispatchers.zsh
│   ├── quarto-dispatcher.zsh      # Extract from smart-dispatchers.zsh
│   ├── claude-dispatcher.zsh      # Extract from smart-dispatchers.zsh
│   ├── gemini-dispatcher.zsh      # Extract from smart-dispatchers.zsh (gm)
│   ├── note-dispatcher.zsh        # Extract from smart-dispatchers.zsh
│   ├── workflow-dispatcher.zsh    # Extract from smart-dispatchers.zsh
│   ├── git-dispatcher.zsh         # Rename from g-dispatcher.zsh
│   ├── vibe-dispatcher.zsh        # Rename from v-dispatcher.zsh
│   ├── mcp-dispatcher.zsh         # Move from root
│   ├── pick-dispatcher.zsh        # Extract from adhd-helpers.zsh (lines 1875-2073)
│   ├── timer-dispatcher.zsh       # To be created by Agent 1
│   └── peek-dispatcher.zsh        # To be created by Agent 1
│
├── helpers/                        # NEW: Helper modules
│   ├── session-management.zsh     # Extract from adhd-helpers.zsh
│   ├── energy-helpers.zsh         # Extract from adhd-helpers.zsh
│   ├── project-detection.zsh      # Extract from adhd-helpers.zsh
│   └── adhd-core.zsh              # Core ADHD functions from adhd-helpers.zsh
│
├── work.zsh                        # Keep (already well-organized)
├── dash.zsh                        # Keep
├── fzf-helpers.zsh                # Keep
├── core-utils.zsh                 # Keep (symlink to zsh-claude-workflow)
├── bg-agents.zsh                  # Keep
├── claude-workflows.zsh           # Keep
├── claude-response-viewer.zsh     # Keep
├── genpass.zsh                    # Keep
├── hub-commands.zsh               # Keep
├── obsidian-bridge.zsh            # Keep
├── obs.zsh                        # Keep (symlink)
├── project-detector.zsh           # Keep (symlink)
├── status.zsh                     # Keep
├── v-utils.zsh                    # Keep (utilities for vibe dispatcher)
└── zsh-clean.zsh                  # Keep
```

## Detailed Extraction Plan

### Phase 1: Create Directory Structure

```bash
mkdir -p ~/.config/zsh/functions/dispatchers
mkdir -p ~/.config/zsh/functions/helpers
```

### Phase 2: Extract Dispatchers from smart-dispatchers.zsh

**File:** `smart-dispatchers.zsh` (880 lines)

#### Extract to `dispatchers/r-dispatcher.zsh`
- **Lines:** 37-168
- **Content:** `r()` function + `_r_help()` helper
- **Commands:** load, test, doc, check, build, install, cycle, quick, cov, spell, pkgdown, preview, cran, fast, win, patch, minor, major, info, tree

#### Extract to `dispatchers/quarto-dispatcher.zsh`
- **Lines:** 170-240
- **Content:** `qu()` function + `_qu_help()` helper
- **Commands:** preview, render, check, clean, new, serve

#### Extract to `dispatchers/claude-dispatcher.zsh`
- **Lines:** 242-360
- **Content:** `cc()` function + `_cc_help()` helper
- **Commands:** continue, resume, latest, sonnet, opus, haiku, plan, auto, yolo, mcp, plugin, json, stream, project, fix, review, test, doc, explain, refactor, optimize, security

#### Extract to `dispatchers/gemini-dispatcher.zsh`
- **Lines:** 362-462
- **Content:** `gm()` function + `_gm_help()` helper
- **Commands:** yolo, sandbox, debug, resume, list, delete, mcp, ext, install, update, web, search, yolosafe, yolodebug

#### Extract to `dispatchers/note-dispatcher.zsh`
- **Lines:** 551-620
- **Content:** `note()` function
- **Commands:** sync, view, clip, export, status, show, list, count

#### Extract to `dispatchers/workflow-dispatcher.zsh`
- **Lines:** 807-874
- **Content:** `workflow()` function
- **Commands:** show, recent, today, yesterday, week, started, finished, break, paused

**Remaining in smart-dispatchers.zsh:**
- Color definitions (lines 10-34)
- Unalias commands (lines 37-44)
- Focus dispatcher (commented out, lines 466-549)
- Obsidian dispatcher (commented out, lines 624-802)

**Decision:** After extraction, smart-dispatchers.zsh should be:
1. Renamed to `dispatchers/colors.zsh` (just the color definitions)
2. OR the color definitions should be moved to a shared utilities file
3. The unalias commands should be moved to each individual dispatcher file

### Phase 3: Rename Existing Dispatchers

```bash
mv ~/.config/zsh/functions/g-dispatcher.zsh ~/.config/zsh/functions/dispatchers/git-dispatcher.zsh
mv ~/.config/zsh/functions/v-dispatcher.zsh ~/.config/zsh/functions/dispatchers/vibe-dispatcher.zsh
mv ~/.config/zsh/functions/mcp-dispatcher.zsh ~/.config/zsh/functions/dispatchers/mcp-dispatcher.zsh
```

### Phase 4: Extract pick() from adhd-helpers.zsh

**File:** `adhd-helpers.zsh` (3198 lines)

#### Extract to `dispatchers/pick-dispatcher.zsh`
- **Lines:** 1875-2073 (198 lines)
- **Content:** `pick()` function + category-specific aliases (pickr, pickdev, pickq)
- **Dependencies:**
  - `_proj_list_all()` function (needs to remain in adhd-helpers or move to helpers/project-detection.zsh)
  - `_proj_find()` function (same as above)

### Phase 5: Extract Helpers from adhd-helpers.zsh

This is the most complex part because adhd-helpers.zsh is 3198 lines. We need to identify and extract modular components.

#### Create `helpers/session-management.zsh`
**Functions to extract:**
- `startsession()` - Start a work session
- `endsession()` - End a work session
- `now()` - Current session info
- `next()` - What's next
- `finish()` - Finish current task
- Related session tracking functions

**Search patterns:**
```bash
grep -n "^startsession\(\)" ~/.config/zsh/functions/adhd-helpers.zsh
grep -n "^endsession\(\)" ~/.config/zsh/functions/adhd-helpers.zsh
grep -n "^now\(\)" ~/.config/zsh/functions/adhd-helpers.zsh
grep -n "^next\(\)" ~/.config/zsh/functions/adhd-helpers.zsh
grep -n "^finish\(\)" ~/.config/zsh/functions/adhd-helpers.zsh
```

#### Create `helpers/energy-helpers.zsh`
**Functions to extract:**
- `gm()` / `pmorning()` - Morning routine
- `gn()` / `pnight()` - Night routine
- `win()` - Log a win (dopamine boost)
- `why()` - Show context/reason for current task
- `js()` / `just-start()` - Decision paralysis helper (lines 24-120)
- `stuck()` - When blocked

**Search patterns:**
```bash
grep -n "^just-start\(\)" ~/.config/zsh/functions/adhd-helpers.zsh
grep -n "^js\(\)" ~/.config/zsh/functions/adhd-helpers.zsh
grep -n "^win\(\)" ~/.config/zsh/functions/adhd-helpers.zsh
grep -n "^why\(\)" ~/.config/zsh/functions/adhd-helpers.zsh
grep -n "^stuck\(\)" ~/.config/zsh/functions/adhd-helpers.zsh
```

#### Create `helpers/project-detection.zsh`
**Functions to extract:**
- `_proj_detect_type()` - Detect project type
- `_proj_list_all()` - List all projects
- `_proj_find()` - Find project directory
- Project category definitions
- Project type detection logic

**Search patterns:**
```bash
grep -n "^_proj_detect_type\(\)" ~/.config/zsh/functions/adhd-helpers.zsh
grep -n "^_proj_list_all\(\)" ~/.config/zsh/functions/adhd-helpers.zsh
grep -n "^_proj_find\(\)" ~/.config/zsh/functions/adhd-helpers.zsh
```

#### Create `helpers/adhd-core.zsh`
**Remaining functions:**
- Core ADHD helper utilities
- Progress tracking functions
- Context helpers
- Any other ADHD-specific utilities not categorized above

### Phase 6: Create dispatchers/README.md

Document all dispatchers with their keywords and common usage.

### Phase 7: Update .zshrc Sourcing

**Current approach (assumed):**
```zsh
source ~/.config/zsh/functions/adhd-helpers.zsh
source ~/.config/zsh/functions/smart-dispatchers.zsh
source ~/.config/zsh/functions/g-dispatcher.zsh
source ~/.config/zsh/functions/v-dispatcher.zsh
source ~/.config/zsh/functions/mcp-dispatcher.zsh
# ... etc
```

**New approach:**
```zsh
# Source all dispatcher files
for dispatcher in ~/.config/zsh/functions/dispatchers/*.zsh(N); do
    [[ -f "$dispatcher" ]] && source "$dispatcher"
done

# Source all helper files
for helper in ~/.config/zsh/functions/helpers/*.zsh(N); do
    [[ -f "$helper" ]] && source "$helper"
done

# Source other function files
for funcfile in ~/.config/zsh/functions/*.zsh(N); do
    [[ -f "$funcfile" ]] && source "$funcfile"
done
```

**Note:** The `(N)` glob qualifier prevents errors if no files match the pattern.

## Safety Checklist

Before executing:

- [ ] **Backup:** Create full backup of `~/.config/zsh/functions/`
  ```bash
  cp -r ~/.config/zsh/functions ~/.config/zsh/functions_backup_$(date +%Y%m%d_%H%M%S)
  ```

- [ ] **Test sourcing:** After each phase, test that ZSH can source the new files
  ```bash
  zsh -c 'source ~/.config/zsh/.zshrc && echo "Success"'
  ```

- [ ] **Function availability:** Verify functions are still accessible
  ```bash
  zsh -c 'source ~/.config/zsh/.zshrc && type r qu cc pick'
  ```

- [ ] **No circular dependencies:** Ensure helpers don't depend on each other in circular ways

- [ ] **Symlinks preserved:** Don't break existing symlinks (core-utils.zsh, project-detector.zsh, obs.zsh)

## Execution Steps

### Step 1: Backup
```bash
cd ~/.config/zsh
cp -r functions functions_backup_$(date +%Y%m%d_%H%M%S)
```

### Step 2: Create Directory Structure
```bash
mkdir -p ~/.config/zsh/functions/dispatchers
mkdir -p ~/.config/zsh/functions/helpers
```

### Step 3: Extract Dispatchers from smart-dispatchers.zsh

This requires careful line extraction. Use a script or manual editing:

```bash
# Extract r dispatcher
sed -n '37,168p' ~/.config/zsh/functions/smart-dispatchers.zsh > \
  ~/.config/zsh/functions/dispatchers/r-dispatcher.zsh

# Add color definitions header to each dispatcher
# (lines 10-34 from smart-dispatchers.zsh)
```

**Better approach:** Create a helper script to extract with proper headers.

### Step 4: Move Existing Dispatchers
```bash
mv ~/.config/zsh/functions/g-dispatcher.zsh \
   ~/.config/zsh/functions/dispatchers/git-dispatcher.zsh

mv ~/.config/zsh/functions/v-dispatcher.zsh \
   ~/.config/zsh/functions/dispatchers/vibe-dispatcher.zsh

mv ~/.config/zsh/functions/mcp-dispatcher.zsh \
   ~/.config/zsh/functions/dispatchers/mcp-dispatcher.zsh
```

### Step 5: Extract pick() from adhd-helpers.zsh

```bash
# Extract pick function (lines 1875-2073)
sed -n '1875,2073p' ~/.config/zsh/functions/adhd-helpers.zsh > \
  ~/.config/zsh/functions/dispatchers/pick-dispatcher.zsh

# Add necessary dependencies or source statements
```

### Step 6: Extract Helpers from adhd-helpers.zsh

This is complex and requires careful analysis. Recommend doing this manually or with a dedicated script.

### Step 7: Create README.md
```bash
cat > ~/.config/zsh/functions/dispatchers/README.md << 'EOF'
# ZSH Function Dispatchers

[Content from template below]
EOF
```

### Step 8: Update .zshrc
```bash
# Edit ~/.config/zsh/.zshrc to use new sourcing approach
```

### Step 9: Test
```bash
# Test in new shell
zsh

# Verify functions work
r help
qu help
cc help
pick --help
```

## Dependencies & Edge Cases

### Color Definitions
All dispatchers currently use color variables defined in smart-dispatchers.zsh:
- `_C_GREEN`, `_C_CYAN`, `_C_YELLOW`, `_C_MAGENTA`, `_C_BLUE`, `_C_BOLD`, `_C_DIM`, `_C_NC`

**Solution:** Create `dispatchers/00-colors.zsh` (numbered to source first) with:
```zsh
# Color definitions for all dispatchers
if [[ -z "${NO_COLOR}" ]] && [[ -t 1 ]]; then
    _C_GREEN='\033[0;32m'
    _C_CYAN='\033[0;36m'
    _C_YELLOW='\033[1;33m'
    _C_MAGENTA='\033[0;35m'
    _C_BLUE='\033[0;34m'
    _C_BOLD='\033[1m'
    _C_DIM='\033[2m'
    _C_NC='\033[0m'
else
    _C_GREEN=''
    _C_CYAN=''
    _C_YELLOW=''
    _C_MAGENTA=''
    _C_BLUE=''
    _C_BOLD=''
    _C_DIM=''
    _C_NC=''
fi
```

### Unalias Commands
Each dispatcher currently needs to unalias its function name:
```zsh
unalias r 2>/dev/null  # in r-dispatcher.zsh
unalias qu 2>/dev/null  # in quarto-dispatcher.zsh
```

**Solution:** Keep these at the top of each individual dispatcher file.

### Project Detection Functions
Functions like `_proj_list_all()`, `_proj_find()`, `_proj_detect_type()` are used by:
- `pick()` dispatcher
- Session management helpers
- Other project-aware commands

**Solution:** Extract to `helpers/project-detection.zsh` and ensure it's sourced before dispatchers.

### adhd-helpers.zsh Analysis
The file is 3198 lines. Need to map all functions:

```bash
# List all function definitions
grep -n "^[a-zA-Z_-]*\(\)" ~/.config/zsh/functions/adhd-helpers.zsh | head -50
```

This will reveal the structure and help plan the extraction.

## Template: dispatchers/README.md

```markdown
# ZSH Function Dispatchers

This directory contains all ZSH function dispatchers - single-letter or short commands that dispatch to various sub-commands.

## Dispatcher Index

### Development Tools

| Command | File | Description | Common Keywords |
|---------|------|-------------|-----------------|
| `r` | r-dispatcher.zsh | R package development | load, test, doc, check, cycle |
| `qu` | quarto-dispatcher.zsh | Quarto publishing | preview, render, clean |
| `cc` | claude-dispatcher.zsh | Claude Code CLI | continue, plan, auto, yolo |
| `gm` | gemini-dispatcher.zsh | Gemini CLI | yolo, web, resume |

### Project Management

| Command | File | Description | Common Keywords |
|---------|------|-------------|-----------------|
| `pick` | pick-dispatcher.zsh | Interactive project picker | r, dev, q, teach, rs, app |
| `g` | git-dispatcher.zsh | Git operations | status, commit, push, pull |

### Workflow & Energy

| Command | File | Description | Common Keywords |
|---------|------|-------------|-----------------|
| `v` | vibe-dispatcher.zsh | Energy & vibe management | check, log, boost |
| `timer` | timer-dispatcher.zsh | Focus timer | 15, 25, 50, 90, check, stop |
| `peek` | peek-dispatcher.zsh | Quick file viewer | - |

### Integrations

| Command | File | Description | Common Keywords |
|---------|------|-------------|-----------------|
| `mcp` | mcp-dispatcher.zsh | MCP server management | list, status, restart |
| `note` | note-dispatcher.zsh | Apple Notes sync | sync, view, status |
| `workflow` | workflow-dispatcher.zsh | Activity logging | today, week, started, finished |

## Usage Pattern

All dispatchers follow a consistent pattern:

```bash
command [action] [args]
```

**Examples:**
```bash
r test              # Run R package tests
qu preview          # Preview Quarto document
cc plan "task"      # Claude Code in plan mode
pick r              # Pick from R packages
g status            # Git status (enhanced)
v check             # Check current energy level
timer 25            # 25 minute focus timer
```

## Help System

Every dispatcher supports `help`:

```bash
r help
qu help
cc help
pick --help
```

## Adding a New Dispatcher

1. Create `dispatchers/your-dispatcher.zsh`
2. Follow the standard pattern:
   ```zsh
   unalias yourcommand 2>/dev/null

   yourcommand() {
       if [[ $# -eq 0 ]]; then
           # Default action
           return
       fi

       case "$1" in
           action1) shift; your_function1 "$@" ;;
           action2) shift; your_function2 "$@" ;;
           help|h)
               echo "Your help text"
               ;;
           *)
               echo "Unknown action: $1"
               echo "Run: yourcommand help"
               return 1
               ;;
       esac
   }
   ```
3. Add entry to this README
4. No changes needed to .zshrc (auto-sourced)

## Dispatcher Design Principles

1. **Discoverable:** All commands have `help`
2. **Consistent:** Same pattern across all dispatchers
3. **Mnemonic:** Keywords are memorable abbreviations
4. **ADHD-Friendly:** Visual hierarchy, clear examples, quick wins highlighted
5. **Backward Compatible:** Original shortcuts still work (aliased)

## Color Support

All dispatchers use shared color definitions from `00-colors.zsh`:
- `_C_GREEN` - Headers, success
- `_C_CYAN` - Commands, actions
- `_C_YELLOW` - Examples, warnings
- `_C_MAGENTA` - Related, references
- `_C_BLUE` - Info, notes
- `_C_BOLD` - Bold text
- `_C_DIM` - Dimmed text
- `_C_NC` - No color (reset)

Colors respect `NO_COLOR` environment variable and TTY detection.
```

## Benefits of This Reorganization

1. **Discoverability:** All dispatchers in one place
2. **Maintainability:** Smaller, focused files instead of monolithic adhd-helpers.zsh
3. **Modularity:** Can disable/enable specific dispatchers
4. **Testing:** Easier to test individual dispatchers
5. **Documentation:** Clear separation of concerns
6. **Performance:** Can lazy-load helpers if needed
7. **Onboarding:** New users can see structure at a glance

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Breaking existing sessions | Keep backup, test in new shell first |
| Circular dependencies | Map dependencies before extraction |
| Missing functions | Comprehensive testing after each phase |
| Performance impact | Benchmark sourcing time before/after |
| Lost functionality | Verify all commands still work |

## Timeline Estimate

- **Phase 1-2:** 30 minutes (directory structure + simple extractions)
- **Phase 3-4:** 1 hour (dispatcher extractions from smart-dispatchers.zsh)
- **Phase 5:** 2-3 hours (helper extractions from adhd-helpers.zsh) - MOST COMPLEX
- **Phase 6-7:** 30 minutes (README + .zshrc updates)
- **Testing:** 1 hour (comprehensive verification)

**Total:** 5-6 hours for complete reorganization

## Next Steps

1. **Review this proposal** - Make sure the structure makes sense
2. **Agent coordination** - Coordinate with Agent 1 (timer/peek dispatchers)
3. **Analyze adhd-helpers.zsh** - Map all functions to determine extraction plan
4. **Create extraction scripts** - Automate the tedious parts
5. **Execute phase by phase** - Don't do everything at once
6. **Test thoroughly** - Verify each phase works before proceeding

## Related Documents

- `/Users/dt/projects/dev-tools/zsh-configuration/docs/reference/ALIAS-REFERENCE-CARD.md`
- `/Users/dt/projects/dev-tools/zsh-configuration/docs/user/WORKFLOWS-QUICK-WINS.md`
- `/Users/dt/projects/dev-tools/zsh-configuration/PROJECT-HUB.md`

## Questions for Review

1. Should timer and peek be dispatchers or regular functions?
2. Should colors be in `00-colors.zsh` or shared utility file?
3. How to handle project detection functions used by multiple modules?
4. Should we extract in one go or incrementally over multiple sessions?
5. Any functions that should stay in adhd-helpers.zsh as a "catch-all"?

---

**Status:** Ready for review and approval before execution.
