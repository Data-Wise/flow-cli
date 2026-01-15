# Future Enhancements: Prompt Dispatcher Integration & Configuration Auto-Generation

**Version:** v5.7.0 Planning Document
**Status:** Design Phase
**Created:** 2026-01-14

---

## Table of Contents

1. [Integration with flow doctor](#integration-with-flow-doctor)
2. [Configuration Auto-Generation](#configuration-auto-generation)
3. [Implementation Roadmap](#implementation-roadmap)
4. [Code Examples](#code-examples)

---

## Integration with flow doctor

### Overview

The `flow doctor` command is a comprehensive health check system for flow-cli that validates system dependencies, installed tools, and plugin status. The prompt dispatcher should integrate with this system to provide unified validation for all three prompt engines.

**File Location:** `commands/doctor.zsh` (766 lines)

### How flow doctor Works

#### Architecture

Doctor operates in **4 distinct modes**:

| Mode | Flag | Purpose | Returns |
|------|------|---------|---------|
| **check** | (default) | Read-only status report | Exit code 0 if clean, 1 if issues |
| **fix** | `--fix, -f` | Interactive installation of missing tools | Exit code 0 on completion |
| **ai** | `--ai, -a` | AI-assisted troubleshooting via Claude | Launches Claude with context |
| **update-docs** | `--update-docs, -u` | Regenerate documentation (internal) | Generated files in docs/reference/ |

#### Validation Categories

Doctor validates 7+ categories organized by priority:

```
Layer 1: 🐚 SHELL          - Core system (zsh, git)
Layer 2: ⚡ REQUIRED       - Essential for flow-cli (fzf)
Layer 3: ✨ RECOMMENDED    - Enhanced experience (eza, bat, rg)
Layer 4: 📦 OPTIONAL       - Nice-to-have (dust, duf, btop)
Layer 5: 🔌 INTEGRATIONS   - Enhancement tools (atlas, radian)
Layer 6: 🔧 ZSH PLUGINS    - Plugin manager & dependencies
Layer 7: 📁 DISPATCHER     - Dispatcher-specific checks (from each dispatcher)
```

### Current Pattern: dot-dispatcher Integration

The `dot` dispatcher already integrates with doctor via a **hook function pattern**:

**In `commands/doctor.zsh` (line 96-98):**
```zsh
if (( $+functions[_dot_doctor] )); then
  _dot_doctor  # Call if function exists
fi
```

**In `lib/dispatchers/dot-doctor-integration.zsh` (114 lines):**
```zsh
_dot_doctor() {
  echo "${FLOW_COLORS[bold]}📁 DOTFILES${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[muted]}Chezmoi sync status and validation${FLOW_COLORS[reset]}"
  echo ""

  # Check 1: chezmoi installed
  _doctor_check_cmd "chezmoi" "brew" "recommended"

  # Check 2: git remote configured
  if command -v chezmoi &>/dev/null; then
    local remote=$(chezmoi data | jq -r '.dotfiles.remote' 2>/dev/null)
    if [[ -z "$remote" ]]; then
      echo "  △ Chezmoi remote not configured (optional)"
    else
      echo "  ✓ Chezmoi remote configured: $remote"
    fi
  fi

  # Check 3: Uncommitted changes
  local dirty=$(cd "$HOME" && chezmoi status 2>/dev/null | wc -l)
  if [[ $dirty -gt 0 ]]; then
    echo "  △ $dirty uncommitted changes in dotfiles"
  fi

  echo ""
}
```

### Proposed: Prompt Dispatcher Integration

Following the same pattern, add `_prompt_doctor()` function to prompt-dispatcher:

**Location:** `lib/dispatchers/prompt-dispatcher.zsh` (add after validation functions, before exports)

```zsh
_prompt_doctor() {
  echo "${FLOW_COLORS[bold]}🎨 PROMPT ENGINES${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[muted]}Prompt engine status and configuration${FLOW_COLORS[reset]}"
  echo ""

  local current_engine=$(_prompt_get_current)

  # Check each engine
  for engine in "${PROMPT_ENGINE_NAMES[@]}"; do
    _prompt_doctor_check_engine "$engine" "$current_engine"
  done

  echo ""
}

_prompt_doctor_check_engine() {
  local engine="$1"
  local current="$2"

  local display="${PROMPT_ENGINES[${engine}_display]}"
  local binary="${PROMPT_ENGINES[${engine}_binary]}"
  local config="${PROMPT_ENGINES[${engine}_config]}"

  # Determine current marker
  local marker=" "
  if [[ "$engine" == "$current" ]]; then
    marker="●"  # Current engine
  fi

  # Status: Online / Configured / Missing / Error
  case "$engine" in
    powerlevel10k)
      _prompt_doctor_check_p10k "$display" "$marker"
      ;;
    starship)
      _prompt_doctor_check_starship "$display" "$marker"
      ;;
    ohmyposh)
      _prompt_doctor_check_ohmyposh "$display" "$marker"
      ;;
  esac
}

_prompt_doctor_check_p10k() {
  local display="$1"
  local marker="$2"

  printf "  %s " "$marker"

  # Check 1: Plugin installed
  if grep -q "romkatv/powerlevel10k" "$HOME/.config/zsh/.zsh_plugins.txt" 2>/dev/null; then
    printf "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} %s" "$display"

    # Check 2: Config exists
    if [[ -f "$HOME/.config/zsh/.p10k.zsh" ]]; then
      echo " (configured)"
    else
      echo " ${FLOW_COLORS[warning]}(plugin installed, config missing)${FLOW_COLORS[reset]}"
    fi
  else
    printf "${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} %s" "$display"
    echo " ← prompt setup-p10k"
  fi
}

_prompt_doctor_check_starship() {
  local display="$1"
  local marker="$2"

  printf "  %s " "$marker"

  # Check 1: Binary in PATH
  if command -v starship &>/dev/null; then
    printf "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} %s" "$display"

    # Check 2: Config exists
    if [[ -f "$HOME/.config/starship.toml" ]]; then
      echo " (configured)"
    else
      echo " ${FLOW_COLORS[warning]}(binary installed, config missing)${FLOW_COLORS[reset]}"
      echo "    → prompt setup-starship"
    fi
  else
    printf "${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} %s" "$display"
    echo " ← brew install starship"
  fi
}

_prompt_doctor_check_ohmyposh() {
  local display="$1"
  local marker="$2"

  printf "  %s " "$marker"

  # Check 1: Binary in PATH
  if command -v oh-my-posh &>/dev/null; then
    printf "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} %s" "$display"

    # Check 2: Config exists
    if [[ -f "$HOME/.config/ohmyposh/config.json" ]]; then
      echo " (configured)"
    else
      echo " ${FLOW_COLORS[warning]}(binary installed, config missing)${FLOW_COLORS[reset]}"
      echo "    → prompt setup-ohmyposh"
    fi
  else
    printf "${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} %s" "$display"
    echo " ← brew install oh-my-posh"
  fi
}
```

**In `commands/doctor.zsh` (after line 98):**
```zsh
if (( $+functions[_prompt_doctor] )); then
  _prompt_doctor
fi
```

### Output Example

```
🎨 PROMPT ENGINES
Prompt engine status and configuration

  ● ✓ Powerlevel10k (configured)
  ○ ✓ Starship (configured)
  ○ ✗ Oh My Posh ← brew install oh-my-posh

Prompt Status: 1/3 engines installed. Quick action: brew install oh-my-posh
```

### Validation Checks Provided

Doctor will validate:

1. ✅ **Binary availability** - Is binary/plugin installed?
2. ✅ **Configuration file** - Does config exist at expected path?
3. ✅ **Current engine** - Which engine is FLOW_PROMPT_ENGINE set to?
4. ✅ **Setup hints** - Actionable next steps for missing engines
5. ✅ **Fix mode integration** - Can install missing binaries via `--fix`

---

## Configuration Auto-Generation

### Overview

Configuration auto-generation is a **wizard-based process** that automatically creates configuration files by:

1. Gathering user input (interactive prompts or defaults)
2. Validating requirements (dependencies, existing state)
3. Generating configs from templates (variable substitution)
4. Creating directory structures
5. Committing changes to git
6. Providing rollback mechanisms

### Real-World Example: teach init

The teaching workflow initialization (`teach init "STAT 545"`) demonstrates the full pattern:

**What Gets Created:**
```
.flow/
├── teach-config.yml          # Course configuration (YAML)
scripts/
├── quick-deploy.sh            # Deployment automation
├── semester-archive.sh        # Archive automation
└── exam-to-qti.sh            # Exam format conversion
.github/workflows/
└── deploy.yml                # GitHub Actions CI/CD
MIGRATION-COMPLETE.md         # Documentation
```

**Lifecycle:**
```
1. VALIDATE
   ├─ Is git initialized?
   ├─ Are dependencies installed? (yq, git)
   └─ Is already initialized? (prevent re-run)

2. GATHER INPUT
   ├─ Course name (user input)
   ├─ Start/end dates (auto-suggested)
   └─ Optional features (breaks, CI/CD)

3. LOAD TEMPLATE
   ├─ Read template: lib/templates/teach-config.yml.template
   ├─ Template has {{PLACEHOLDER}} variables
   └─ Supports conditional sections

4. SUBSTITUTE
   ├─ Use sed for variable replacement
   ├─ Handle multiline sections (course breaks)
   ├─ Write final files
   └─ Set permissions (chmod +x for scripts)

5. PERSIST & DOCUMENT
   ├─ git add + git commit (atomic)
   ├─ Create recovery tag (git tag "pre-migration")
   ├─ Generate rollback mechanism
   └─ Show next steps
```

### Prompt Dispatcher: Configuration Generation Candidates

The prompt dispatcher could implement config auto-generation for setup wizards:

#### Scenario 1: OhMyPosh Setup (Already Partially Implemented)

**Current:** `prompt setup-ohmyposh` creates basic config
**Enhancement:** Full interactive wizard

```bash
prompt setup-ohmyposh --interactive
  # Interactive flow:
  # 1. Check if oh-my-posh is installed (offer: brew install oh-my-posh)
  # 2. Create directory: ~/.config/ohmyposh/
  # 3. Ask: Use default config? Which theme? (powerlevel, agnoster, etc.)
  # 4. Ask: Customize colors? [Y/n]
  # 5. Generate config.json from template (or use preset)
  # 6. git commit (if in repo)
  # 7. Show: "Config created at ~/.config/ohmyposh/config.json"
  # 8. Provide: "Next: source ~/.zshrc && prompt toggle"
```

**Generated File: `~/.config/ohmyposh/config.json`**
```json
{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "version": 3,
  "console_title_template": "{{ .Shell }} in {{ .Folder }}",
  "terminal_background": "#0B1022",
  "accent_color": "#FFB86C",
  "profiles": [
    {
      "name": "default",
      "segments": [
        { "type": "session", "style": "diamond", "template": " {{ .UserName }} " },
        { "type": "path", "style": "diamond", "template": "  {{ path .Path .Location }} " },
        { "type": "git", "style": "diamond" }
      ]
    }
  ]
}
```

#### Scenario 2: Starship Setup (New Feature)

**Proposed:** `prompt setup-starship --interactive`

```bash
prompt setup-starship --interactive
  # Similar flow to OhMyPosh:
  # 1. Validate Starship installed
  # 2. Offer: Use default config | Clone from repo | Full editor
  # 3. Generate starship.toml from template
  # 4. Optional: Show preview of rendered prompt
  # 5. Commit and document
```

**Generated File: `~/.config/starship.toml`**
```toml
# Created by: prompt setup-starship
# Date: 2026-01-14
# Edit with: $EDITOR ~/.config/starship.toml

format = "$username$hostname$directory$git_branch$git_status$fill$cmd_duration$line_break$character"
right_format = "$time"

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[✗](bold red)"

[directory]
truncate_to_repo = true
format = "[$read_only]($read_only_style)[$path]($style) "

[git_branch]
format = "[$symbol$branch]($style) "

[git_status]
format = "([\\[$all_status$ahead_behind\\]]($style) )"

[cmd_duration]
show_milliseconds = false
format = "took [$duration]($style) "
```

#### Scenario 3: Powerlevel10k Setup (New Feature)

**Proposed:** `prompt setup-p10k --interactive`

```bash
prompt setup-p10k --interactive
  # Powerlevel10k-specific flow:
  # 1. Check: Is antidote installed?
  # 2. Check: Is romkatv/powerlevel10k in .zsh_plugins.txt?
  # 3. Offer: Run p10k configure wizard (if already loaded)
  # 4. Generate .p10k.zsh from template
  # 5. Optional: Extract settings from p10k configure
  # 6. Document: "Run source ~/.zshrc && p10k configure to customize"
```

### Implementation Pattern (5-Step Process)

All config generation follows this pattern:

```
STEP 1: VALIDATE
  ├─ Command: if ! command -v <tool> &>/dev/null; then
  ├─ File: [[ -f "$path" ]] || mkdir -p "$(dirname "$path")"
  └─ State: [[ -f "$config" ]] && offer_overwrite

STEP 2: GATHER INPUT
  ├─ Interactive: read "prompt?  Question: " response
  ├─ Defaults: Use env var or smart default (current date, username)
  ├─ Validation: Validate format (dates, paths, etc.)
  └─ Non-interactive: Use -y flag to accept all defaults

STEP 3: LOAD TEMPLATE
  ├─ Template file: lib/templates/<name>-config.template
  ├─ Placeholders: {{VAR_NAME}} for substitution
  ├─ Conditionals: {{#SECTION}} ... {{/SECTION}} for optional parts
  └─ Escape: {{{{ESCAPED}}}} for literal {{ }}

STEP 4: SUBSTITUTE & GENERATE
  ├─ Replace vars: sed "s/{{KEY}}/value/g" template > output
  ├─ Multiline handling: Use printf or heredoc for complex sections
  ├─ Permissions: chmod +x for executable scripts
  ├─ Formatting: Validate generated files (jq for JSON, yq for YAML)
  └─ Backup: Save old config as .bak if overwriting

STEP 5: PERSIST & DOCUMENT
  ├─ Git: git add config && git commit -m "..."
  ├─ Tag: git tag "pre-migration-$(date +%s)" (recovery point)
  ├─ Summary: echo "Config created at ~/.config/..."
  ├─ Next steps: echo "Run: prompt toggle to activate"
  └─ Rollback: Function to undo if something fails
```

### Code Example: OhMyPosh Setup Implementation

```zsh
_prompt_setup_ohmyposh() {
  local setup_mode="${1:-interactive}"  # interactive or --yes
  local auto_yes=false

  [[ "$setup_mode" == "--yes" ]] && auto_yes=true

  echo "${FLOW_COLORS[header]}🎨 Setting up Oh My Posh Prompt${FLOW_COLORS[reset]}"
  echo ""

  # STEP 1: VALIDATE
  if ! command -v oh-my-posh &>/dev/null; then
    echo "${FLOW_COLORS[error]}✗ Oh My Posh not installed${FLOW_COLORS[reset]}"
    echo "  Install with: ${FLOW_COLORS[muted]}brew install oh-my-posh${FLOW_COLORS[reset]}"
    return 1
  fi

  echo "${FLOW_COLORS[success]}✓ Oh My Posh ${$(oh-my-posh --version)##*v}${FLOW_COLORS[reset]}"

  # Create directory
  mkdir -p "$HOME/.config/ohmyposh" || {
    echo "${FLOW_COLORS[error]}✗ Failed to create ~/.config/ohmyposh${FLOW_COLORS[reset]}"
    return 1
  }

  local config_file="$HOME/.config/ohmyposh/config.json"

  # Check for existing config
  if [[ -f "$config_file" ]]; then
    if [[ "$auto_yes" == true ]]; then
      echo "${FLOW_COLORS[warning]}△ Config exists, will overwrite${FLOW_COLORS[reset]}"
    else
      echo ""
      read -r "overwrite?  Config already exists. Overwrite? [y/N]: "
      if [[ "$overwrite" != "y" ]]; then
        echo "${FLOW_COLORS[muted]}Keeping existing config at $config_file${FLOW_COLORS[reset]}"
        return 0
      fi
    fi
  fi

  # STEP 2: GATHER INPUT (unless auto_yes)
  local theme="powerlevel"
  if [[ "$auto_yes" != true ]]; then
    echo ""
    echo "Available themes: powerlevel, agnoster, spaceship, minimal"
    read -r "theme?  Theme [powerlevel]: "
    [[ -z "$theme" ]] && theme="powerlevel"
  fi

  # STEP 3: LOAD TEMPLATE
  local template_file="$FLOW_CLI_ROOT/lib/templates/ohmyposh-config.template"

  if [[ ! -f "$template_file" ]]; then
    echo "${FLOW_COLORS[error]}✗ Template not found: $template_file${FLOW_COLORS[reset]}"
    return 1
  fi

  # STEP 4: SUBSTITUTE & GENERATE
  local generated_config=$(cat "$template_file" | \
    sed "s|{{THEME}}|$theme|g" | \
    sed "s|{{USERNAME}}|$(whoami)|g" | \
    sed "s|{{TIMESTAMP}}|$(date -Iseconds)|g")

  # Validate JSON
  if ! echo "$generated_config" | jq . >/dev/null 2>&1; then
    echo "${FLOW_COLORS[error]}✗ Generated invalid JSON config${FLOW_COLORS[reset]}"
    return 1
  fi

  # STEP 5: PERSIST & DOCUMENT
  # Backup old config
  if [[ -f "$config_file" ]]; then
    cp "$config_file" "$config_file.bak"
    echo "${FLOW_COLORS[muted]}→ Backed up existing config to $config_file.bak${FLOW_COLORS[reset]}"
  fi

  # Write new config
  echo "$generated_config" > "$config_file" || {
    echo "${FLOW_COLORS[error]}✗ Failed to write config${FLOW_COLORS[reset]}"
    return 1
  }

  echo "${FLOW_COLORS[success]}✓ Config created${FLOW_COLORS[reset]}"
  echo "  Location: $config_file"

  # Git commit (if in repo)
  if git rev-parse --git-dir >/dev/null 2>&1; then
    git add "$config_file" 2>/dev/null
    git commit -m "chore: Initialize Oh My Posh configuration with $theme theme" 2>/dev/null
    echo "${FLOW_COLORS[success]}✓ Committed to git${FLOW_COLORS[reset]}"
  fi

  # Summary
  echo ""
  echo "${FLOW_COLORS[header]}Next Steps:${FLOW_COLORS[reset]}"
  echo "  1. Reload shell:   ${FLOW_COLORS[muted]}source ~/.zshrc${FLOW_COLORS[reset]}"
  echo "  2. Test prompt:    ${FLOW_COLORS[muted]}prompt status${FLOW_COLORS[reset]}"
  echo "  3. Customize:      ${FLOW_COLORS[muted]}prompt toggle${FLOW_COLORS[reset]}"
  echo "  4. Edit config:    ${FLOW_COLORS[muted]}\$EDITOR ~/.config/ohmyposh/config.json${FLOW_COLORS[reset]}"
  echo ""

  return 0
}
```

### Benefits of Configuration Auto-Generation

1. **Zero Cognitive Load**
   - Guided step-by-step process
   - Smart defaults for 80% of users
   - No manual JSON/TOML editing needed

2. **Safe by Design**
   - Validates requirements before generating
   - Backs up existing configs
   - Provides rollback mechanisms (git tags)

3. **Discoverable**
   - Inline help and next steps
   - Shows what was created
   - Clear error messages

4. **Non-Interactive Mode**
   - `prompt setup-ohmyposh --yes` for CI/CD
   - Automated environment setup
   - Useful for Docker/containers

5. **Version Controlled**
   - All configs committed to git
   - Full history and undo capability
   - Easy to review what changed

---

## Implementation Roadmap

### Phase 1: flow doctor Integration (Recommended)

**Effort:** 2-3 hours | **Priority:** High | **Deps:** None

**Tasks:**
1. Create `_prompt_doctor()` function in prompt-dispatcher.zsh
2. Add hook in commands/doctor.zsh
3. Test with `flow doctor` (should show prompt engine status)
4. Update docs/reference/DOCTOR-REFERENCE.md (if exists)

**Acceptance Criteria:**
- `flow doctor` displays prompt engine status
- Shows current engine with ● marker
- Shows install hints for missing engines
- Passes all existing tests

**Files to Modify:**
- `lib/dispatchers/prompt-dispatcher.zsh` (add ~80 lines)
- `commands/doctor.zsh` (add 3-line hook)

### Phase 2: Configuration Auto-Generation (Advanced)

**Effort:** 4-6 hours | **Priority:** Medium | **Deps:** Phase 1

**Subtasks:**

2a. **Create Template System**
- `lib/templates/ohmyposh-config.template` (JSON template)
- `lib/templates/starship-config.template` (TOML template)
- `lib/templates/p10k-config.template` (ZSH template)

2b. **Implement Setup Wizard**
- Enhance `_prompt_setup_ohmyposh()` with full wizard
- Add `_prompt_setup_starship()` for Starship
- Add `_prompt_setup_p10k()` for Powerlevel10k

2c. **Add Flags**
- `--interactive` (guided) vs `--yes` (automated)
- `--dry-run` (show plan without changes)
- `--restore` (restore from backup)

2d. **Safety Features**
- Config backup (`.bak` files)
- Git tag recovery points
- Rollback function on failure

**Acceptance Criteria:**
- `prompt setup-ohmyposh --interactive` runs wizard
- `prompt setup-ohmyposh --yes` uses all defaults
- Valid config file created and validated
- Previous config backed up
- Changes committed to git

**Files to Create:**
- `lib/templates/ohmyposh-config.template`
- `lib/templates/starship-config.template`
- Helper functions in prompt-dispatcher.zsh

**Files to Modify:**
- `lib/dispatchers/prompt-dispatcher.zsh` (add ~200 lines)

### Phase 3: Testing & Documentation (Standard)

**Effort:** 2-3 hours | **Priority:** Medium | **Deps:** Phase 1-2

**Tasks:**
1. Create tests for `_prompt_doctor()` function
2. Create tests for setup wizards
3. Update PROMPT-DISPATCHER-GUIDE.md with setup wizard section
4. Add troubleshooting guide (what to do if setup fails)

**Files to Modify/Create:**
- `tests/test-prompt-doctor.zsh` (new)
- `tests/test-prompt-setup-wizards.zsh` (new)
- `docs/guides/PROMPT-DISPATCHER-GUIDE.md` (update)

---

## Code Examples

### Example 1: Integrating _prompt_doctor with flow doctor

**In `commands/doctor.zsh` (line 96, after dot-doctor integration):**

```zsh
# Add prompt dispatcher doctor hook
if (( $+functions[_prompt_doctor] )); then
  _prompt_doctor
fi
```

**In `lib/dispatchers/prompt-dispatcher.zsh` (after line 284, after validation functions):**

```zsh
# ============================================================================
# Doctor Integration
# ============================================================================

_prompt_doctor() {
  echo "${FLOW_COLORS[bold]}🎨 PROMPT ENGINES${FLOW_COLORS[reset]}"
  echo "${FLOW_COLORS[muted]}Prompt engine status and configuration${FLOW_COLORS[reset]}"
  echo ""

  local current_engine=$(_prompt_get_current)
  local engines_ok=0
  local total_engines=${#PROMPT_ENGINE_NAMES[@]}

  # Check each engine
  for engine in "${PROMPT_ENGINE_NAMES[@]}"; do
    if _prompt_doctor_check_engine "$engine" "$current_engine"; then
      ((engines_ok++))
    fi
  done

  # Summary
  echo ""
  if [[ $engines_ok -eq $total_engines ]]; then
    echo "${FLOW_COLORS[success]}✓ All prompt engines are available${FLOW_COLORS[reset]}"
  else
    echo "${FLOW_COLORS[warning]}△ $engines_ok/$total_engines engines configured${FLOW_COLORS[reset]}"
  fi
  echo ""
}

_prompt_doctor_check_engine() {
  local engine="$1"
  local current="$2"
  local is_current=false

  [[ "$engine" == "$current" ]] && is_current=true

  local display="${PROMPT_ENGINES[${engine}_display]}"
  local config="${PROMPT_ENGINES[${engine}_config]}"

  # Build status line
  printf "  "
  [[ "$is_current" == true ]] && printf "●" || printf "○"
  printf " "

  case "$engine" in
    powerlevel10k)
      if grep -q "romkatv/powerlevel10k" "$HOME/.config/zsh/.zsh_plugins.txt" 2>/dev/null; then
        printf "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} %s" "$display"
        if [[ -f "$config" ]]; then
          echo " (configured)"
        else
          echo " ${FLOW_COLORS[warning]}(no config)${FLOW_COLORS[reset]}"
        fi
        return 0
      else
        printf "${FLOW_COLORS[muted]}○${FLOW_COLORS[reset]} %s (not installed)\n" "$display"
        return 1
      fi
      ;;
    starship)
      if command -v starship &>/dev/null; then
        printf "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} %s" "$display"
        if [[ -f "$config" ]]; then
          echo " (configured)"
        else
          echo " ${FLOW_COLORS[warning]}(no config)${FLOW_COLORS[reset]}"
        fi
        return 0
      else
        printf "${FLOW_COLORS[muted]}○${FLOW_COLORS[reset]} %s (not installed)\n" "$display"
        return 1
      fi
      ;;
    ohmyposh)
      if command -v oh-my-posh &>/dev/null; then
        printf "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} %s" "$display"
        if [[ -f "$config" ]]; then
          echo " (configured)"
        else
          echo " ${FLOW_COLORS[warning]}(no config)${FLOW_COLORS[reset]}"
        fi
        return 0
      else
        printf "${FLOW_COLORS[muted]}○${FLOW_COLORS[reset]} %s (not installed)\n" "$display"
        return 1
      fi
      ;;
  esac
}
```

### Example 2: OhMyPosh Setup Wizard

**In `lib/dispatchers/prompt-dispatcher.zsh` (add new function):**

```zsh
_prompt_setup_ohmyposh_interactive() {
  local auto_yes=false
  [[ "$1" == "--yes" ]] && auto_yes=true

  echo "${FLOW_COLORS[header]}🎨 Setting up Oh My Posh${FLOW_COLORS[reset]}"
  echo ""

  # Step 1: Validate
  if ! command -v oh-my-posh &>/dev/null; then
    echo "${FLOW_COLORS[error]}✗ Oh My Posh not installed${FLOW_COLORS[reset]}"
    echo "Install: ${FLOW_COLORS[muted]}brew install oh-my-posh${FLOW_COLORS[reset]}"
    return 1
  fi

  # Step 2: Create directory
  mkdir -p "$HOME/.config/ohmyposh" || {
    echo "${FLOW_COLORS[error]}✗ Failed to create directory${FLOW_COLORS[reset]}"
    return 1
  }

  local config_file="$HOME/.config/ohmyposh/config.json"

  # Step 3: Check existing
  if [[ -f "$config_file" && "$auto_yes" != true ]]; then
    read -r "overwrite?  Config exists. Overwrite? [y/N]: "
    [[ "$overwrite" != "y" ]] && return 0
  fi

  # Step 4: Template substitution (simplified)
  local template_content='{
  "$schema": "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json",
  "version": 3,
  "profiles": [
    {
      "name": "default",
      "segments": [
        { "type": "session", "style": "diamond", "template": " {{ .UserName }} " },
        { "type": "path", "style": "diamond", "template": "  {{ path .Path .Location }} " }
      ]
    }
  ]
}'

  # Step 5: Write and validate
  if ! echo "$template_content" | jq . >/dev/null 2>&1; then
    echo "${FLOW_COLORS[error]}✗ Invalid JSON generated${FLOW_COLORS[reset]}"
    return 1
  fi

  echo "$template_content" > "$config_file"

  # Step 6: Git commit
  if git rev-parse --git-dir >/dev/null 2>&1; then
    git add "$config_file" 2>/dev/null
    git commit -m "chore: Initialize Oh My Posh configuration" 2>/dev/null
  fi

  echo ""
  echo "${FLOW_COLORS[success]}✓ Config created at $config_file${FLOW_COLORS[reset]}"
  echo ""
  echo "Next: ${FLOW_COLORS[muted]}source ~/.zshrc && prompt toggle${FLOW_COLORS[reset]}"
  echo ""
}
```

---

## Summary

Both enhancements follow **established flow-cli patterns**:

1. **flow doctor integration** → Uses dispatcher hook pattern (like dot-dispatcher)
2. **Config auto-generation** → Uses template + substitution pattern (like teach init)

These features are **additive** and **non-breaking** — existing functionality remains unchanged. They can be implemented incrementally, tested thoroughly, and documented comprehensively before release.

