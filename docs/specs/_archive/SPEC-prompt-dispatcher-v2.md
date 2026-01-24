# SPEC: Prompt Engine Dispatcher (v5.7.0) - Complete

**Status:** Draft - Interactive Refinement Complete
**Created:** 2026-01-14
**Version:** 2.0 (Updated from User Feedback)
**From Brainstorm:** BRAINSTORM-flow-cli-prompt-dispatcher.md
**Priority:** High
**Target Release:** v5.7.0

---

## Overview

Integrate the prompt engine management system into flow-cli as a new `prompt` dispatcher. This provides unified control over three prompt engines: Powerlevel10k, Starship, and OhMyPosh. The system validates installations, shows interactive menus for engine selection, and follows flow-cli's architecture patterns.

**Scope:**
- ✅ Support 3 prompt engines (p10k, starship, ohmyposh)
- ✅ Full command: `prompt status|toggle|starship|p10k|ohmyposh`
- ✅ Interactive menu when toggling with 3+ engines
- ✅ Validation before switching
- ✅ Formatted table output for status/list
- ✅ Complete OhMyPosh support (not deferred)

---

## User Stories

### Primary User Story

**As a** flow-cli user
**I want to** easily switch between three prompt engines (Powerlevel10k, Starship, OhMyPosh) via a discoverable flow-cli dispatcher
**So that** I can choose the right prompt for my current workflow without remembering multiple commands or configuration files

**Acceptance Criteria:**
- [ ] `prompt status` displays all available engines in a formatted table
- [ ] `prompt toggle` shows interactive menu to select next engine (when 3+ available)
- [ ] `prompt starship`, `prompt p10k`, `prompt ohmyposh` force-switch to specific engine
- [ ] `prompt list` shows all engines with config paths and descriptions
- [ ] `prompt help` displays complete documentation
- [ ] System validates engine installation before switching
- [ ] No errors when switching between any combination of engines
- [ ] New shell loads correct engine immediately after switch

### Secondary User Story 1

**As a** developer
**I want to** have prompt management fully integrated into flow-cli
**So that** the system is cohesive and all prompt functionality is discoverable through the framework

**Acceptance Criteria:**
- [ ] `prompt` is the primary interface for engine management
- [ ] No external aliases or separate commands
- [ ] Discoverable via `prompt help`
- [ ] Integrates with flow-cli's help system
- [ ] Documented in DISPATCHER-REFERENCE.md

### Secondary User Story 2

**As a** system maintainer
**I want to** easily add new prompt engines in the future
**So that** the system can evolve without architectural changes

**Acceptance Criteria:**
- [ ] Adding a new engine requires minimal changes
- [ ] Each engine has clear interface (name, config path, installation check)
- [ ] Toggle logic automatically works with any number of engines
- [ ] Validation function is extensible

---

## Technical Requirements

### Dispatcher Architecture

```
prompt [subcommand]
    ├── status          → _prompt_status()      [Display all engines + current]
    ├── toggle          → _prompt_toggle()      [Interactive menu for 3+ engines]
    ├── starship        → _prompt_switch()      [Force to starship]
    ├── p10k            → _prompt_switch()      [Force to p10k]
    ├── ohmyposh        → _prompt_switch()      [Force to ohmyposh]
    ├── list            → _prompt_list()        [Show all engines with details]
    └── help            → _prompt_help()        [Display help]
```

### Engine Definitions

Each engine is defined by:

| Property | Description | Example |
|----------|-------------|---------|
| **name** | Engine identifier | `powerlevel10k` |
| **display_name** | Human-readable name | `Powerlevel10k` |
| **config_file** | Primary configuration | `~/.config/zsh/.p10k.zsh` |
| **binary** | Executable path to check | `/opt/homebrew/bin/starship` |
| **description** | Brief description | "Feature-rich, highly customizable" |
| **init_code** | Shell initialization | `eval "$(starship init zsh)"` or `source ~/.config/zsh/.p10k.zsh` |

### Engine Specifications

#### Engine 1: Powerlevel10k

```
Name: powerlevel10k
Display: Powerlevel10k
Config: ~/.config/zsh/.p10k.zsh
Binary: (loaded via antidote plugin manager)
Description: Feature-rich, highly customizable prompt engine
Install Check: grep -q "romkatv/powerlevel10k" ~/.config/zsh/.zsh_plugins.txt
Init Method: source ~/.config/zsh/.p10k.zsh (after antidote loads)
```

#### Engine 2: Starship

```
Name: starship
Display: Starship
Config: ~/.config/starship.toml
Binary: /opt/homebrew/bin/starship (or in PATH)
Description: Minimal, fast Rust-based prompt engine
Install Check: command -v starship >/dev/null 2>&1
Init Method: eval "$(starship init zsh)"
Status: ✅ Currently installed and configured
```

#### Engine 3: OhMyPosh (NEW)

```
Name: ohmyposh
Display: Oh My Posh
Config: ~/.config/ohmyposh/config.json
Binary: /opt/homebrew/bin/oh-my-posh (or in PATH)
Description: Modular prompt engine with extensive themes
Install Check: command -v oh-my-posh >/dev/null 2>&1
Init Method: eval "$(oh-my-posh init zsh)"
Status: ⏳ To be implemented in v5.7.0
```

### File Structure

```
flow-cli/
├── lib/
│   └── dispatchers/
│       └── prompt-dispatcher.zsh            # NEW: Main dispatcher
├── completions/
│   └── _prompt                              # NEW: Tab completion
├── docs/
│   ├── reference/
│   │   ├── DISPATCHER-REFERENCE.md          # ADD: Prompt section
│   │   └── COMMAND-QUICK-REFERENCE.md       # ADD: Prompt entry
│   └── guides/
│       └── PROMPT-DISPATCHER-GUIDE.md       # NEW: Comprehensive guide
├── tests/
│   ├── test-prompt-engine.zsh               # EXISTING: Keep (75 tests)
│   └── test-prompt-dispatcher.zsh           # NEW: Dispatcher tests (50+)
├── setup/
│   └── prompt-setup.zsh                     # NEW: OhMyPosh setup script
└── CLAUDE.md                                # UPDATE: Add prompt dispatcher
```

### Environment Variables

```bash
# Existing variable (keep using)
export FLOW_PROMPT_ENGINE="${FLOW_PROMPT_ENGINE:-powerlevel10k}"

# Valid values
- "powerlevel10k"
- "starship"
- "ohmyposh"

# Usage
if [[ "$FLOW_PROMPT_ENGINE" == "starship" ]]; then
    eval "$(starship init zsh)"
fi
```

---

## Command Specifications

### 1. `prompt status` - Display Current Engine Status

**Purpose:** Show which engine is active and what alternatives are available

**Output Format: Formatted Table**

```
Prompt Engines:

  ● powerlevel10k (current)
    Feature-rich, highly customizable prompt engine
    Config: ~/.config/zsh/.p10k.zsh

  ○ starship
    Minimal, fast Rust-based prompt engine
    Config: ~/.config/starship.toml

  ○ oh-my-posh
    Modular prompt engine with extensive themes
    Config: ~/.config/ohmyposh/config.json

To switch: prompt toggle
```

**Implementation Notes:**
- Use Unicode bullets: `●` for current, `○` for available
- Display in order: current first, then alternatives
- Show full engine name and description
- Include config file path
- Show helpful hint about toggle command

---

### 2. `prompt toggle` - Switch to Different Engine

**Purpose:** Interactive selection for switching between engines

**Behavior:**
- 2 engines: Show simple menu

  ```
  Which prompt engine would you like to use?
  1) starship
  2) powerlevel10k
  ```

- 3+ engines: Show full menu

  ```
  Which prompt engine would you like to use?
  1) starship
  2) ohmyposh
  3) powerlevel10k
  ```

**Validation:**
- Before switching, validate engine is installed
- If engine missing: Show error message with install instructions
- If validation passes: Switch engine
- Show confirmation: `✅ Switched to [engine name]`

**Implementation:**
- Use shell built-in `select` for menu
- Validate engine before confirming
- Set `FLOW_PROMPT_ENGINE` and exec new shell

---

### 3. `prompt starship` - Switch to Starship

**Purpose:** Directly switch to Starship (skip menu)

**Behavior:**
- Validate Starship is installed
- Set `FLOW_PROMPT_ENGINE="starship"`
- Reload shell: `exec zsh -i`
- Show: `✅ Switched to Starship`

**Error Handling:**
- If not installed: `❌ Starship not found. Install: brew install starship`
- If config missing: `⚠️  Starship config missing at ~/.config/starship.toml`

---

### 4. `prompt p10k` - Switch to Powerlevel10k

**Purpose:** Directly switch to Powerlevel10k (skip menu)

**Behavior:**
- Validate P10k plugin is loaded (check .zsh_plugins.txt)
- Validate config exists
- Set `FLOW_PROMPT_ENGINE="powerlevel10k"`
- Reload shell: `exec zsh -i`
- Show: `✅ Switched to Powerlevel10k`

**Error Handling:**
- If plugin not in .zsh_plugins.txt: `❌ Powerlevel10k plugin not found`
- If config missing: `⚠️  P10k config missing at ~/.config/zsh/.p10k.zsh`

---

### 5. `prompt ohmyposh` - Switch to OhMyPosh

**Purpose:** Directly switch to OhMyPosh (skip menu)

**Behavior:**
- Validate OhMyPosh is installed
- Validate config exists
- Set `FLOW_PROMPT_ENGINE="ohmyposh"`
- Reload shell: `exec zsh -i`
- Show: `✅ Switched to Oh My Posh`

**Error Handling:**
- If not installed: `❌ Oh My Posh not found. Install: brew install oh-my-posh`
- If config missing: `⚠️  OhMyPosh config missing. Run: prompt setup-ohmyposh`

---

### 6. `prompt list` - Show All Engines with Details

**Purpose:** Display comprehensive information about all engines

**Output Format:**

```
Available Prompt Engines:

name           status    config file
─────────────────────────────────────────────────────────────
powerlevel10k  ●         ~/.config/zsh/.p10k.zsh
starship       ○         ~/.config/starship.toml
oh-my-posh     ○         ~/.config/ohmyposh/config.json

Legend: ● = current, ○ = available
```

**What's Included:**
- All 4 columns: name, status (● = current, ○ = available), config path
- Brief descriptions for each engine
- Installation status indicators
- Legend explaining symbols

---

### 7. `prompt help` - Display Help

**Output Format:**

```
🎨 PROMPT DISPATCHER v5.7.0
   Manage multiple prompt engines: Powerlevel10k, Starship, OhMyPosh

USAGE:
   prompt [subcommand]

SUBCOMMANDS:
   status              Show current engine and alternatives
   toggle              Switch to another engine (interactive menu)
   starship            Force switch to Starship
   p10k                Force switch to Powerlevel10k
   ohmyposh            Force switch to Oh My Posh
   list                List all available engines with details
   help                Show this help

EXAMPLES:
   prompt status               # See what's active
   prompt toggle               # Choose engine from menu
   prompt starship             # Go straight to Starship
   prompt list                 # See all engines

SETUP:
   prompt setup-ohmyposh       # Configure Oh My Posh for first time

For more info:
   https://data-wise.github.io/flow-cli/dispatchers/prompt/
```

---

## Flow Doctor Integration

### Overview

`flow doctor` is extended to include comprehensive diagnostics and auto-fix for prompt engine dependencies. This ensures the prompt dispatcher has all required components installed and properly configured.

### Diagnostics Checked

**Installation Status:**
- ✓ Powerlevel10k plugin loaded (in .zsh_plugins.txt)
- ✓ Starship binary available (in PATH)
- ✓ Oh My Posh binary available (in PATH)

**Configuration Status:**
- ✓ P10k config file exists (~/.config/zsh/.p10k.zsh)
- ✓ Starship config file exists (~/.config/starship.toml)
- ✓ OhMyPosh config file exists (~/.config/ohmyposh/config.json)

**Active Engine:**
- Show current FLOW_PROMPT_ENGINE value
- Verify it matches one of the 3 engines
- Alert if engine set to invalid value

**Shell Initialization:**
- ✓ FLOW_PROMPT_ENGINE exported in .zshenv
- ✓ Dual-mode logic in .zshrc
- ✓ P10k instant prompt conditional
- ✓ Starship init conditional
- ✓ Engine-specific initialization code present

### Output Format (Standard)

```
🎨 PROMPT ENGINE DIAGNOSTICS:

Powerlevel10k:
  Installation: ✅ Plugin loaded (in .zsh_plugins.txt)
  Config:       ✅ ~/.config/zsh/.p10k.zsh exists
  Status:       ✅ Ready

Starship:
  Installation: ✅ /opt/homebrew/bin/starship
  Config:       ✅ ~/.config/starship.toml exists
  Status:       ✅ Ready

Oh My Posh:
  Installation: ❌ Not found in PATH
  Config:       ⚠️  ~/.config/ohmyposh/config.json missing
  Status:       ⚠️  Install required

Active Engine: powerlevel10k ✅

---
To fix issues: Select 'F' → 'Prompt engines' or run: flow doctor prompt
```

### Auto-Fix Workflow (Delegated to Flow Doctor)

#### Interactive Fix (Smart Flow Doctor System)

```bash
$ flow doctor

[Shows all diagnostics including prompt engines]

🔧 FIXES AVAILABLE:
  Prompt Engines
    1. Install Oh My Posh (missing binary)
    2. Create OhMyPosh config

Fix these issues? (y/n)
```

**Smart Flow Doctor Handles:**
- ✅ Detecting all missing/broken components
- ✅ Intelligent installation order (antidote → p10k, then starship, then ohmyposh)
- ✅ Config file creation from templates
- ✅ Validation after each fix
- ✅ Rollback on failure
- ✅ Clear error messages and next steps

**Flow Doctor Fix Process:**

```
1. Analyze current state (via _doctor_prompt_engines)
2. Determine what's missing
3. Ask user for permission
4. Install in correct order (dependencies first)
5. Create configs from templates
6. Validate all fixes
7. Report results with next steps
```

**User Experience:**

```
Installing Oh My Posh...
  ✓ Binary installed via homebrew
  ✓ Config created from template
  ✓ Validated with: oh-my-posh config

✅ Prompt Engines: Ready to use
Run: prompt help
```

#### Why Delegate to Flow Doctor

**Complexity Reasons:**
- Multiple interdependent fixes (order matters)
- Rollback capability on failure
- Consistent with other flow doctor fixes
- Single source of truth for all diagnostics
- Reuses existing fix infrastructure

**Prompt Dispatcher Responsibility:**
- Validation checks only (detecting issues)
- Error reporting with actionable messages
- Preventing broken switches
- User guidance to `flow doctor`

**Flow Doctor Responsibility:**
- Complex diagnostics
- Smart installation logic
- Config creation from templates
- Verification and rollback
- Integration with other system fixes

### Implementation Details

#### Doctor Function Structure

```bash
# New function in commands/doctor.zsh
_doctor_prompt_engines() {
    # Check all 3 engines
    _check_p10k_installation
    _check_p10k_config
    _check_starship_installation
    _check_starship_config
    _check_ohmyposh_installation
    _check_ohmyposh_config

    # Check active engine
    _check_active_engine

    # Check shell initialization
    _check_shell_init

    # Display results
    _display_prompt_diagnostics
}

_fix_prompt_engines() {
    # Prompt user before fixing
    # Install missing engines
    # Create missing configs
    # Verify all fixed
}
```

#### Installation Logic

```bash
_install_engine_interactive() {
    local engine="$1"

    case "$engine" in
        starship)
            echo "Installing Starship..."
            brew install starship
            ;;
        ohmyposh)
            echo "Installing Oh My Posh..."
            brew install oh-my-posh
            ;;
    esac

    # Verify installation
    _verify_installation "$engine"
}
```

#### Configuration Creation

```bash
_create_engine_config() {
    local engine="$1"

    case "$engine" in
        ohmyposh)
            # Create ~/.config/ohmyposh/config.json
            # Use default config or copy template
            prompt setup-ohmyposh
            ;;
    esac
}
```

### Integration with Existing Doctor

**Location:** `commands/doctor.zsh`

**Additions:**
- New check category: "Prompt Engines"
- New diagnostic functions (10+ helper functions)
- Auto-fix handlers
- Status reporting

**No breaking changes:**
- Existing doctor functionality unchanged
- Prompt engines as one section among many
- Compatible with other doctor checks

### Dependency Checks

**Critical Dependencies:**
- ✅ Antidote plugin manager (required for P10k)
- ✅ At least 1 prompt engine installed (minimum requirement)
- ✅ Current FLOW_PROMPT_ENGINE is valid

**Optional Dependencies:**
- Each of 3 engines (p10k, starship, ohmyposh)
- Config files for each engine

### Binary Detection

**Method:** Use `command -v` for flexible PATH checking
- Works across different systems (macOS, Linux)
- Finds binaries in any PATH location
- No hardcoded paths (more portable)

**Check Logic:**

```bash
# Check Starship
command -v starship >/dev/null 2>&1

# Check OhMyPosh
command -v oh-my-posh >/dev/null 2>&1

# Check Antidote (required)
command -v antidote >/dev/null 2>&1
```

### Configuration Validation

**Invalid/Broken Config Files:**
- ❌ Report to user
- ❌ Show file location
- ❌ Suggest manual fix (don't auto-recreate)
- ❌ Provide debugging steps

Example:

```
⚠️  Starship config is invalid
   File: ~/.config/starship.toml
   Error: Failed to parse TOML

Manual fix:
   1. Edit file: nano ~/.config/starship.toml
   2. Validate syntax with: starship config
   3. Run: flow doctor  (to verify)
```

### Issue Severity

**All prompt engine issues are warnings (non-blocking):**
- ✅ System works with at least 1 engine
- ⚠️  Missing optional engines = warning (not error)
- ⚠️  Missing configs = warning (not error)
- ⚠️  Invalid config = warning (not error)

**Minimum Passing State:**
- At least 1 engine installed + configured
- FLOW_PROMPT_ENGINE set to valid engine
- Antidote installed (for P10k)

### Diagnostic Output Examples

#### All Healthy

```
🎨 Prompt Engines: ✅ All healthy
  ● Powerlevel10k - installed & configured
  ● Starship - installed & configured
  ● Oh My Posh - installed & configured
  ▸ Current: powerlevel10k ✅

  Antidote: ✅ installed
```

#### Missing Optional Engine

```
🎨 Prompt Engines: ⚠️  Suboptimal setup
  ● Powerlevel10k - installed & configured
  ● Starship - installed & configured
  ⚠️  Oh My Posh - NOT INSTALLED
     Fix: brew install oh-my-posh

  ▸ Current: powerlevel10k ✅
  Antidote: ✅ installed

Status: Working (2/3 engines available)
```

#### Broken Configuration

```
🎨 Prompt Engines: ⚠️  Config issue
  ● Powerlevel10k - installed & configured
  ● Starship - installed (config broken)
  ● Oh My Posh - installed & configured

Broken Config:
  ❌ ~/.config/starship.toml is invalid

Manual fix:
  1. Edit: nano ~/.config/starship.toml
  2. Validate: starship config
  3. Recheck: flow doctor

▸ Current: powerlevel10k ✅ (still working)
```

#### Missing Antidote

```
🎨 Prompt Engines: ⚠️  Dependency issue
  ❌ Antidote not found

Powerlevel10k requires antidote plugin manager
  ● Starship - installed & configured
  ● Oh My Posh - installed & configured

Fix:
  brew install antidote
  # Then restart shell

▸ Current: powerlevel10k ⚠️ (P10k won't load)
Status: Partially working (1/3 engines available)
```

### User Workflow

#### Scenario 1: First Time Setup

```
$ flow doctor

🎨 Prompt Engines:
  ✅ Powerlevel10k ready
  ✅ Starship ready
  ❌ Oh My Posh missing

Fix prompt engines? (y/n) y
✅ Oh My Posh installed
✅ Config created
✅ All checks passing!
```

#### Scenario 2: Troubleshooting

```
$ flow doctor

[Shows all systems]

User: Selects 'F' for fix
User: Selects 'Prompt engines'

🔧 Fixing prompt engines...
✅ Fixed: Oh My Posh installation
✅ Fixed: OhMyPosh config
✅ All issues resolved!
```

#### Scenario 3: Maintenance Check

```
$ flow doctor

Shows that everything is healthy, no action needed
```

---

## Implementation Details

### Function Architecture

```bash
# Main dispatcher
prompt() {
    case "$1" in
        status)      _prompt_status ;;
        toggle)      _prompt_toggle ;;
        starship)    _prompt_switch "starship" ;;
        p10k)        _prompt_switch "powerlevel10k" ;;
        ohmyposh)    _prompt_switch "ohmyposh" ;;
        list)        _prompt_list ;;
        help|--help) _prompt_help ;;
        *)           _prompt_help ;;
    esac
}

# Helper functions
_prompt_status()        # Show current + alternatives in table
_prompt_toggle()        # Interactive menu, switch engine
_prompt_switch()        # Force switch to specific engine
_prompt_list()          # List all engines with details
_prompt_help()          # Display help text
_prompt_validate()      # Check if engine is installed/configured
_prompt_get_current()   # Get current engine safely
_prompt_get_alternatives() # Get list of non-current engines
_prompt_init_engine()   # Initialize chosen engine
_prompt_engine_exists() # Check if engine binary/config exists
```

### Engine Registry (Data Structure)

```bash
# Array of available engines (in order)
declare -a PROMPT_ENGINES=(
    "powerlevel10k:Powerlevel10k:~/.config/zsh/.p10k.zsh:antidote:Feature-rich, highly customizable"
    "starship:Starship:/opt/homebrew/bin/starship:~/.config/starship.toml:Minimal, fast Rust-based"
    "ohmyposh:Oh My Posh:/opt/homebrew/bin/oh-my-posh:~/.config/ohmyposh/config.json:Modular with themes"
)

# Parse function
_prompt_parse_engine() {
    local engine="$1"
    local index="$2"
    local field="$3"

    # Returns requested field (name, display, binary, config, etc.)
}
```

### Validation Logic

```bash
_prompt_validate() {
    local engine="$1"

    case "$engine" in
        powerlevel10k)
            # Check if plugin is in .zsh_plugins.txt
            # Check if config file exists
            ;;
        starship)
            # Check if binary exists in PATH
            # Check if config file exists
            ;;
        ohmyposh)
            # Check if binary exists in PATH
            # Check if config file exists
            ;;
    esac
}
```

### Toggle Logic with 3 Engines

```bash
_prompt_toggle() {
    # Always show menu for 3+ engines
    local current=$(_prompt_get_current)
    local alternatives=($(_prompt_get_alternatives))

    # Show menu
    select engine in "${alternatives[@]}"; do
        _prompt_switch "$engine"
        break
    done
}
```

---

## User Interface

### Command Examples

**Example 1: Check Status**

```
$ prompt status

Prompt Engines:

  ● powerlevel10k (current)
    Feature-rich, highly customizable prompt engine
    Config: ~/.config/zsh/.p10k.zsh

  ○ starship
    Minimal, fast Rust-based prompt engine
    Config: ~/.config/starship.toml

  ○ oh-my-posh
    Modular prompt engine with extensive themes
    Config: ~/.config/ohmyposh/config.json
```

**Example 2: Toggle Interactively**

```
$ prompt toggle

Which prompt engine would you like to use?
1) starship
2) ohmyposh
3) powerlevel10k
#? 1
✅ Switched to Starship

[shell reloads with new prompt]
```

**Example 3: Force Switch**

```
$ prompt starship
✅ Switched to Starship

[new shell loads]
```

**Example 4: List All Engines**

```
$ prompt list

Available Prompt Engines:

name           status    config file
─────────────────────────────────────────────────────────────
powerlevel10k  ●         ~/.config/zsh/.p10k.zsh
starship       ○         ~/.config/starship.toml
oh-my-posh     ○         ~/.config/ohmyposh/config.json

Legend: ● = current, ○ = available
```

**Example 5: Validation Error**

```
$ prompt ohmyposh
❌ Oh My Posh not found in PATH

Install with:
  brew install oh-my-posh

Then configure with:
  prompt setup-ohmyposh
```

---

## Error Handling

### Error Cases

| Case | Message | Recovery |
|------|---------|----------|
| Invalid subcommand | `Unknown command: xyz. Use: prompt help` | Show help |
| Engine not installed | `❌ Starship not found. Install: brew install starship` | Install via homebrew |
| Config missing | `⚠️  Config missing at ~/.config/starship.toml` | Run setup script |
| Invalid FLOW_PROMPT_ENGINE | `⚠️  Invalid engine: foobar` | Validate value |
| Shell reload fails | `❌ Failed to reload shell` | Manual troubleshoot |

### Validation Before Switch

All switching operations:
1. Validate engine is installed (check binary/plugin)
2. Validate config file exists
3. If both pass: proceed with switch
4. If validation fails: show error + instructions
5. Never attempt switch if validation fails

### Dispatcher Behavior with Missing Dependencies

**Missing Engine Binary:**

```bash
$ prompt starship

❌ Starship not found in PATH

Install with:
  brew install starship

Then switch:
  prompt starship

Or use flow doctor:
  flow doctor  (shows 'F' to fix)
```

**Missing Engine Config:**

```bash
$ prompt ohmyposh

⏳ Creating OhMyPosh config...
✅ Config created: ~/.config/ohmyposh/config.json

You can customize it:
  prompt setup-ohmyposh   (interactive wizard)
  nano ~/.config/ohmyposh/config.json

Ready to switch to Oh My Posh? (y/n)
```

**Invalid/Broken Config:**

```bash
$ prompt starship

⚠️  Starship config is invalid
File: ~/.config/starship.toml

Error from starship config:
  [error details...]

Fix manually:
  1. nano ~/.config/starship.toml
  2. starship config  (validate)
  3. prompt starship  (retry)

Or create from template:
  rm ~/.config/starship.toml
  prompt starship  (recreates with defaults)
```

### OhMyPosh Setup Wizard

**Command:** `prompt setup-ohmyposh`

**Interactive Workflow:**

```
Welcome to OhMyPosh Setup Wizard!

This will help you configure Oh My Posh for your shell.

1. Theme Selection
   Available themes: nerd-font, standard, minimal, plus...
   Select theme: [nerd-font]

2. Color Scheme
   Available: dark, light, colorful, pastel...
   Select colors: [colorful]

3. Show Git Status?
   Include git branch and status: (y/n) [y]

4. Show Time Display?
   Include current time in prompt: (y/n) [n]

5. Additional Modules?
   Battery, Node version, Python version, etc.
   Select: [node, python]

Creating config at ~/.config/ohmyposh/config.json...
✅ Configuration saved!

Validate: oh-my-posh config
Switch: prompt ohmyposh
```

---

## Testing Strategy

### Unit Tests (test-prompt-dispatcher.zsh)

- 50+ comprehensive tests covering:
  - All subcommands work correctly
  - Menu rendering (2-engine, 3-engine cases)
  - Validation logic
  - Engine switching
  - Error handling
  - Help output

### E2E Tests

- Actual engine switching in fresh shell
- Verify correct engine loads
- Test toggle menu interaction
- Test all three engines sequentially

### Validation Tests

- Check if installed engines detected
- Check if missing engines properly fail
- Verify config paths are correct

---

## Documentation

### Reference

- Add `prompt` section to `docs/reference/DISPATCHER-REFERENCE.md`
- Add to `docs/reference/COMMAND-QUICK-REFERENCE.md`

### Guides

- Create `docs/guides/PROMPT-DISPATCHER-GUIDE.md` with:
  - All commands explained
  - Examples for each
  - OhMyPosh setup instructions
  - Troubleshooting section

### CLAUDE.md Updates

- Add prompt to dispatcher quick reference
- Document engine switching in ADHD-friendly guide

---

## Roadmap

### v5.7.0 - MVP

- ✅ Three prompt engines (p10k, starship, ohmyposh)
- ✅ Status, toggle, list, help commands
- ✅ Validation before switching
- ✅ Interactive menu for toggle
- ✅ Complete tests and docs

### v5.8.0+ - Future Enhancements

- `prompt theme` - Manage themes per engine
- `prompt history` - Show toggle history
- `prompt profile` - Performance metrics
- Auto-detection of best engine for context
- Export/import configurations

---

## Success Criteria

✅ **Feature Works:**
- All 7 subcommands functional
- Interactive menu for toggle
- Validation prevents broken switches
- 3-way engine support

✅ **Fully Integrated:**
- Loads with flow-cli
- Tab completion works
- Documented in DISPATCHER-REFERENCE.md
- Consistent with other dispatchers

✅ **Well-Tested:**
- 50+ unit tests
- E2E tests verify actual switching
- All edge cases covered
- No breaking changes

✅ **User-Ready:**
- Clear help and documentation
- Error messages are actionable
- Setup instructions for OhMyPosh
- Examples for all commands

---

## Next Steps

1. Create feature branch: `feature/prompt-dispatcher-v5.7.0`
2. Implement Phase 1: Core dispatcher
3. Implement Phase 2: Validation & OhMyPosh
4. Add comprehensive tests
5. Update documentation
6. Create PR to `dev`
7. Merge and release as v5.7.0

---

**Spec Status:** Ready for Implementation
**Session:** 1 of 5 (Planning Complete)
**Next Session:** Feature branch creation + Phase 1 implementation
