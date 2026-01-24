# flow-cli API Reference

> Complete reference for all public functions, commands, and configuration options.

**Version:** 5.9.0
**Last Updated:** 2026-01-14

---

## Table of Contents

1. [Core Library Functions](#core-library-functions)
2. [Configuration Functions](#configuration-functions)
3. [UI/TUI Functions](#uitui-functions)
4. [Validation Functions](#validation-functions)
5. [Dispatcher Commands](#dispatcher-commands)
6. [Environment Variables](#environment-variables)
7. [Configuration Schema](#configuration-schema)

---

## Core Library Functions

### lib/core.zsh

#### Logging Functions

```zsh
_flow_log <level> <message>
```

Unified logging with color support.

| Parameter | Type | Description |
|-----------|------|-------------|
| level | string | One of: `success`, `warning`, `error`, `info`, `debug` |
| message | string | Message to display |

**Convenience Functions:**

```zsh
_flow_log_success "Operation completed"
_flow_log_warning "Check configuration"
_flow_log_error "Failed to connect"
_flow_log_info "Processing..."
_flow_log_debug "Variable value: $var"  # Only if FLOW_DEBUG=1
```

#### Project Functions

```zsh
_flow_find_project_root [start_path]
```

Locate project root by searching for `.git` or `.STATUS` file.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| start_path | string | `$PWD` | Directory to start search |

**Returns:** Path to project root, or empty string if not found.

```zsh
_flow_in_project
```

Check if current directory is inside a project.

**Returns:** Exit code 0 if in project, 1 otherwise.

```zsh
_flow_project_name [path]
```

Extract project name from path.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| path | string | `$PWD` | Path to extract name from |

**Returns:** Project name (last path component).

#### Utility Functions

```zsh
_flow_format_duration <seconds>
```

Format seconds into human-readable duration.

| Input | Output |
|-------|--------|
| 45 | `45s` |
| 125 | `2m 5s` |
| 3725 | `1h 2m` |

```zsh
_flow_time_ago <timestamp>
```

Format timestamp into relative time (e.g., "2 hours ago").

```zsh
_flow_confirm <prompt> [default]
```

Interactive yes/no confirmation prompt.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| prompt | string | required | Question to display |
| default | string | `n` | Default answer (y/n) |

**Returns:** Exit code 0 for yes, 1 for no.

```zsh
_flow_array_contains <needle> <haystack...>
```

Check if array contains value.

**Returns:** Exit code 0 if found, 1 otherwise.

---

## Configuration Functions

### lib/config.zsh

```zsh
_flow_config_init
```

Initialize configuration system. Creates config directory and default config file if needed.

```zsh
_flow_config_get <key> [default]
```

Retrieve configuration value.

| Parameter | Type | Description |
|-----------|------|-------------|
| key | string | Configuration key (dot notation supported) |
| default | string | Default value if key not found |

**Example:**

```zsh
local theme=$(_flow_config_get "ui.color_theme" "default")
```

```zsh
_flow_config_set <key> <value>
```

Set configuration value and persist to file.

```zsh
_flow_config_reset [key]
```

Reset configuration to defaults. If key provided, resets only that key.

### Configuration Keys

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `projects_root` | path | `~/projects` | Base projects directory |
| `atlas_enabled` | auto\|yes\|no | `auto` | Atlas state engine |
| `load_dispatchers` | bool | `yes` | Load dispatcher commands |
| `quiet` | bool | `no` | Suppress welcome message |
| `debug` | bool | `no` | Enable debug logging |
| `color_theme` | string | `default` | UI color theme |
| `timer_default` | int | `25` | Pomodoro work duration (min) |
| `timer_break` | int | `5` | Short break duration (min) |
| `session_timeout` | int | `120` | Session timeout (seconds) |
| `dopamine_mode` | bool | `yes` | Enable win tracking |
| `auto_commit` | bool | `no` | Auto-commit on finish |
| `commit_emoji` | bool | `yes` | Use emoji in commits |

---

## UI/TUI Functions

### lib/tui.zsh

#### Progress Indicators

```zsh
_flow_progress_bar <current> <total> [width]
```

Display ASCII progress bar.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| current | int | required | Current progress value |
| total | int | required | Total/maximum value |
| width | int | `30` | Bar width in characters |

**Output:** `[████████░░░░░░░░░░░░] 40%`

```zsh
_flow_sparkline <values...>
```

Generate sparkline chart from numeric values.

**Example:**

```zsh
_flow_sparkline 1 3 5 7 5 3 1
# Output: ▁▃▅▇▅▃▁
```

#### Spinner Animation (v5.9.0)

```zsh
_flow_spinner_start <message> [estimate]
```

Start background spinner animation.

| Parameter | Type | Description |
|-----------|------|-------------|
| message | string | Message to display alongside spinner |
| estimate | string | Optional time estimate (e.g., "~30-60s") |

```zsh
_flow_spinner_stop [success_message]
```

Stop spinner and optionally display success message.

```zsh
_flow_with_spinner <message> <estimate> <command> [args...]
```

Execute command with spinner wrapper.

**Example:**

```zsh
_flow_with_spinner "Building..." "~10s" make build
```

**Spinner Frames:** `⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏` (Braille dots)

#### User Input

```zsh
_flow_input <prompt> [default]
```

Styled input prompt (uses gum if available).

```zsh
_flow_confirm_styled <prompt>
```

Styled yes/no prompt with visual feedback.

```zsh
_flow_choose <prompt> <options...>
```

Multi-option selector (uses gum/fzf if available).

**Example:**

```zsh
local choice=$(_flow_choose "Select option:" "Option A" "Option B" "Option C")
```

#### Display Widgets

```zsh
_flow_box <text> [title]
```

Draw ASCII box around text.

```zsh
_flow_table <headers> <rows...>
```

Display formatted table.

---

## Validation Functions

### lib/config-validator.zsh (v5.9.0)

#### Hash-Based Change Detection

```zsh
_flow_config_hash <file_path>
```

Compute SHA-256 hash of file.

| Parameter | Type | Description |
|-----------|------|-------------|
| file_path | string | Path to file |

**Returns:** 64-character hex hash string.

```zsh
_flow_config_changed <file_path>
```

Check if file has changed since last check.

| Return | Meaning |
|--------|---------|
| 0 | File changed (or no cache) |
| 1 | File unchanged |

**Cache Location:** `$FLOW_DATA_DIR/cache/teach-config.hash`

```zsh
_flow_config_invalidate
```

Force cache invalidation. Next `_flow_config_changed` will return "changed".

#### Teaching Config Validation

```zsh
_teach_validate_config <config_path> [--quiet]
```

Validate teaching configuration against JSON Schema.

| Parameter | Type | Description |
|-----------|------|-------------|
| config_path | string | Path to teach-config.yml |
| --quiet | flag | Suppress output, only return exit code |

**Validations Performed:**
- Required field: `course.name`
- Enum: `course.semester` (Spring\|Summer\|Fall\|Winter)
- Range: `course.year` (2020-2100)
- Date format: `semester_info.start_date` (YYYY-MM-DD)
- Enum: `scholar.course_info.level` (undergraduate\|graduate\|both)
- Enum: `scholar.course_info.difficulty` (beginner\|intermediate\|advanced)
- Enum: `scholar.style.tone` (formal\|conversational)
- Sum: `scholar.grading` percentages (95-105%)

**Returns:** Exit code 0 if valid, 1 if invalid.

```zsh
_teach_config_get <key> [default] [config_path]
```

Retrieve value from teaching config.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| key | string | required | YAML path (e.g., `course.name`) |
| default | string | `""` | Default if not found |
| config_path | string | auto-detected | Path to config file |

```zsh
_teach_has_scholar_config [config_path]
```

Check if config has Scholar section.

**Returns:** Exit code 0 if Scholar section exists.

```zsh
_teach_find_config
```

Search up directory tree for `.flow/teach-config.yml`.

**Returns:** Full path to config file, or empty if not found.

#### Flag Validation

```zsh
_teach_validate_flags <command> <flags...>
```

Validate flags for teach subcommand before Scholar invocation.

| Parameter | Type | Description |
|-----------|------|-------------|
| command | string | Subcommand (exam, quiz, slides, etc.) |
| flags | array | Flags to validate |

**Valid Flags by Command:**

| Command | Valid Flags |
|---------|-------------|
| exam | `--questions`, `--duration`, `--types`, `--format`, `--dry-run`, `--verbose` |
| quiz | `--questions`, `--time-limit`, `--format`, `--dry-run`, `--verbose` |
| slides | `--theme`, `--from-lecture`, `--format`, `--dry-run`, `--verbose` |
| assignment | `--due-date`, `--points`, `--format`, `--dry-run`, `--verbose` |
| syllabus | `--format`, `--dry-run`, `--verbose` |
| rubric | `--criteria`, `--format`, `--dry-run`, `--verbose` |

**Returns:** Exit code 0 if all flags valid, 1 with error message if invalid.

---

## Dispatcher Commands

### cc - Claude Code

```zsh
cc [mode] [target] [options]
```

**Modes:**

| Mode | Description |
|------|-------------|
| (none) | Default: acceptEdits mode |
| `yolo` | Skip all permission prompts |
| `plan` | Plan mode (research before implement) |
| `opus` | Use Opus model |
| `haiku` | Use Haiku model |

**Targets:**

| Target | Description |
|--------|-------------|
| (none) | Current directory |
| `.` | Explicit current directory |
| `pick` | Interactive project picker |
| `<project>` | Direct project name |

**Subcommands:**

| Command | Description |
|---------|-------------|
| `cc resume` | Resume previous session picker |
| `cc continue` | Continue most recent conversation |
| `cc ask "question"` | Quick question (print mode) |
| `cc file <path>` | Analyze specific file |
| `cc diff` | Analyze git diff |
| `cc wt` | Analyze current worktree |

**Examples:**

```zsh
cc                    # Launch here, acceptEdits
cc yolo               # Launch here, skip permissions
cc pick yolo          # Pick project, then yolo
cc yolo pick          # Same (unified grammar)
cc flow opus          # Project 'flow' with Opus
```

### g - Git

```zsh
g <action> [args...]
```

| Action | Description |
|--------|-------------|
| `status` | Git status |
| `add <files>` | Stage files |
| `commit "msg"` | Commit with message |
| `push` | Push to remote |
| `pull` | Pull from remote |
| `branch <name>` | Create branch |
| `checkout <branch>` | Switch branch |
| `merge <branch>` | Merge branch |
| `delete <branch>` | Delete branch |
| `clean` | Clean merged branches |
| `feature start <name>` | Start feature branch |
| `feature prune` | Clean old features |

### wt - Worktrees

```zsh
wt <action> [args...]
```

| Action | Description |
|--------|-------------|
| `list` | List all worktrees |
| `create <branch>` | Create worktree |
| `status` | Show worktree status |
| `prune` | Clean up old worktrees |
| `remove <name>` | Delete worktree |

### teach - Teaching (v5.8.0+)

```zsh
teach <action> [topic] [options]
```

| Action | Description |
|--------|-------------|
| `init "Course"` | Initialize teaching project |
| `exam "Topic"` | Generate exam |
| `quiz "Topic"` | Generate quiz |
| `slides "Topic"` | Generate slides |
| `lecture "Topic"` | Generate lecture notes |
| `assignment "Task"` | Generate assignment |
| `syllabus` | Generate syllabus |
| `rubric "Criteria"` | Generate rubric |
| `feedback "Work"` | Generate feedback |
| `demo` | Generate demo course |
| `status` | Show project status |
| `week` | Show current week |
| `deploy` | Deploy to production |

**Universal Flags:**

| Flag | Description |
|------|-------------|
| `--dry-run` | Preview without writing |
| `--format <fmt>` | Output format |
| `--output <path>` | Custom output path |
| `--verbose` | Show command details |

### dot - Dotfiles & Secrets

```zsh
dot secret <action> [args...]
```

| Action | Description |
|--------|-------------|
| `add <name>` | Add secret to Keychain |
| `get <name>` | Retrieve secret |
| `list` | List all secrets |
| `delete <name>` | Delete secret |

```zsh
dot token <provider> [--refresh]
```

| Provider | Description |
|----------|-------------|
| `github` | GitHub PAT wizard |
| `npm` | NPM token wizard |
| `pypi` | PyPI token wizard |

### Other Dispatchers

| Dispatcher | Purpose |
|------------|---------|
| `mcp` | MCP server management |
| `r` | R package development |
| `qu` | Quarto publishing |
| `obs` | Obsidian integration |
| `tm` | Terminal manager |
| `prompt` | Prompt engine switcher |

---

## Environment Variables

### Core Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FLOW_PLUGIN_DIR` | auto | Plugin installation directory |
| `FLOW_CONFIG_DIR` | `~/.config/flow` | Configuration directory |
| `FLOW_DATA_DIR` | `~/.local/share/flow` | Data directory |
| `FLOW_PROJECTS_ROOT` | `~/projects` | Projects base directory |
| `FLOW_VERSION` | current | Plugin version |

### Feature Flags

| Variable | Values | Description |
|----------|--------|-------------|
| `FLOW_ATLAS_ENABLED` | auto\|yes\|no | Atlas state engine |
| `FLOW_LOAD_DISPATCHERS` | yes\|no | Load dispatcher commands |
| `FLOW_QUIET` | 0\|1 | Suppress welcome message |
| `FLOW_DEBUG` | 0\|1 | Enable debug logging |

### Session Variables

| Variable | Description |
|----------|-------------|
| `FLOW_CURRENT_PROJECT` | Current working project path |
| `FLOW_SESSION_START` | Session start timestamp |
| `FLOW_SPINNER_PID` | Background spinner process ID |

---

## Configuration Schema

### teach-config.yml

```yaml
# FLOW-CLI SECTION (flow-cli owns)
course:
  name: "STAT 440"              # Required
  full_name: "Regression Analysis"
  semester: Spring              # Spring|Summer|Fall|Winter
  year: 2026                    # 2020-2100
  instructor: "Dr. Name"

semester_info:
  start_date: "2026-01-13"      # YYYY-MM-DD
  end_date: "2026-05-15"
  breaks:
    - name: "Spring Break"
      start: "2026-03-08"
      end: "2026-03-15"

branches:
  draft: draft
  production: main

# SCHOLAR SECTION (Scholar owns)
scholar:
  course_info:
    level: undergraduate        # undergraduate|graduate|both
    field: Statistics
    difficulty: intermediate    # beginner|intermediate|advanced
    credits: 3

  style:
    tone: formal                # formal|conversational
    notation: statistical
    examples: true

  topics:
    - "Simple Linear Regression"
    - "Multiple Regression"
    - "Model Diagnostics"

  grading:                      # Must sum to ~100%
    Participation: 10
    Homework: 30
    Midterm: 30
    Final: 30
```

### Ownership Protocol

| Section | Owner | Description |
|---------|-------|-------------|
| `course` | flow-cli | Basic course info |
| `semester_info` | flow-cli | Schedule information |
| `branches` | flow-cli | Git branch config |
| `deployment` | flow-cli | Deploy settings |
| `scholar` | Scholar | AI generation settings |
| `examark` | shared | Exam rendering |

---

## See Also

- [DISPATCHER-REFERENCE.md](DISPATCHER-REFERENCE.md) - Complete dispatcher documentation
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture
- [COMMAND-QUICK-REFERENCE.md](COMMAND-QUICK-REFERENCE.md) - Quick command lookup
