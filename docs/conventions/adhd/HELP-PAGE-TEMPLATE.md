# Help Page Template

> **Use this template** for individual command documentation pages (not built-in `--help` output).

---

## When to Use

| Content Type | Use When |
|-------------|----------|
| Quick Start | Get running fast |
| Tutorial | Learn step-by-step |
| Workflow | Show common patterns |
| **Help Page** | **Document individual command/dispatcher** |
| Reference Card | Quick lookup table |

**Help pages are for:** Complete documentation of a specific command or dispatcher.

---

## Design Principles

1. **Comprehensive** — Cover all options and use cases
2. **Structured** — Same format for every command
3. **Examples-heavy** — Show real usage, not just syntax
4. **Scannable** — Tables and code blocks, minimal prose
5. **Cross-referenced** — Link to tutorials, workflows, related commands

---

## Template Structure

```markdown
# [Command Name]

> **[One-sentence description of what this command does]**

---

## Synopsis

\`\`\`bash
[command] [OPTIONS] [ARGUMENTS]
\`\`\`

**Quick examples:**
\`\`\`bash
# [Most common use case]
[command] [simple usage]

# [Second common use case]
[command] [common usage]

# [Third common use case]
[command] [advanced usage]
\`\`\`

---

## Description

[2-3 paragraph explanation of the command's purpose and behavior]

**Use cases:**
- [Primary use case]
- [Secondary use case]
- [Tertiary use case]

**What it does:**
- [Action 1]
- [Action 2]
- [Action 3]

---

## Options

### Required Arguments

| Argument | Description | Example |
|----------|-------------|---------|
| `<arg>` | [What this is] | `command foo` |

### Optional Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `[arg]` | [default value] | [What this does] |

### Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--flag` | `-f` | [What this does] |
| `--option` | `-o` | [What this does] |
| `--verbose` | `-v` | [What this does] |

### Mode Flags

| Mode | Description | When to Use |
|------|-------------|-------------|
| `--mode1` | [Description] | [Scenario] |
| `--mode2` | [Description] | [Scenario] |

---

## Usage Examples

### Basic Usage

**Scenario:** [When you'd use this]

\`\`\`bash
# [Description of what this does]
[command] [args]
\`\`\`

**Output:**
\`\`\`
[Expected output]
\`\`\`

### Intermediate Usage

**Scenario:** [When you'd use this]

\`\`\`bash
# [Description]
[command] [args with options]
\`\`\`

**Output:**
\`\`\`
[Expected output]
\`\`\`

### Advanced Usage

**Scenario:** [Complex use case]

\`\`\`bash
# [Description]
[command] [complex args and options]
\`\`\`

**Output:**
\`\`\`
[Expected output]
\`\`\`

---

## Common Patterns

### Pattern 1: [Pattern Name]

**Use when:** [Scenario]

\`\`\`bash
# [Pattern description]
[command sequence]
\`\`\`

### Pattern 2: [Pattern Name]

**Use when:** [Scenario]

\`\`\`bash
# [Pattern description]
[command sequence]
\`\`\`

### Pattern 3: [Pattern Name]

**Use when:** [Scenario]

\`\`\`bash
# [Pattern description]
[command sequence]
\`\`\`

---

## Combining with Other Commands

### With [Related Command 1]

\`\`\`bash
# [Workflow description]
[command1] && [command2]
\`\`\`

### With [Related Command 2]

\`\`\`bash
# [Workflow description]
[command1] | [command2]
\`\`\`

---

## Interactive Features

### Keybindings

| Key | Action |
|-----|--------|
| `Enter` | [Action] |
| `Ctrl-C` | [Action] |
| `Ctrl-X` | [Action] |

### TUI Controls

| Control | Action |
|---------|--------|
| `↑/↓` | [Navigation] |
| `Tab` | [Switch view] |
| `Esc` | [Cancel] |

---

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `VAR_NAME` | `value` | [What it controls] |

**Example:**
\`\`\`bash
export VAR_NAME="custom-value"
[command]
\`\`\`

### Config File

**Location:** `~/.config/flow/[command].conf`

\`\`\`ini
# [Config file format]
option = value
setting = true
\`\`\`

---

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | General error |
| `2` | [Specific error] |
| `130` | Interrupted (Ctrl-C) |

---

## Troubleshooting

### Issue 1: [Problem]

**Symptoms:**
- [What you see]
- [Error message]

**Cause:** [Why it happens]

**Solution:**
\`\`\`bash
# [Fix]
[solution command]
\`\`\`

### Issue 2: [Problem]

**Symptoms:**
- [What you see]

**Cause:** [Why it happens]

**Solution:**
\`\`\`bash
# [Fix]
[solution command]
\`\`\`

### Issue 3: [Problem]

**Symptoms:**
- [What you see]

**Cause:** [Why it happens]

**Solution:**
\`\`\`bash
# [Fix]
[solution command]
\`\`\`

---

## Best Practices

**Do:**
- ✅ [Best practice 1]
- ✅ [Best practice 2]
- ✅ [Best practice 3]

**Don't:**
- ❌ [Anti-pattern 1]
- ❌ [Anti-pattern 2]
- ❌ [Anti-pattern 3]

---

## Related Commands

- **[Command 1]** — [When to use instead]
- **[Command 2]** — [How it relates]
- **[Command 3]** — [Complementary usage]

---

## See Also

- **Tutorial:** [Link to tutorial]
- **Workflow:** [Link to workflow doc]
- **Reference:** [Link to reference card]
- **Guide:** [Link to conceptual guide]

---

**Last Updated:** [Date]
**Command Version:** [Version when command was added/updated]
```

---

## Example: Pick Command

```markdown
# pick

> **Interactive project picker with FZF interface for quick navigation**

---

## Synopsis

\`\`\`bash
pick [CATEGORY] [OPTIONS]
\`\`\`

**Quick examples:**
\`\`\`bash
# Show all projects
pick

# Filter by category
pick dev

# Show only worktrees
pick wt

# Show recent sessions only
pick --recent
\`\`\`

---

## Description

The `pick` command provides an interactive FZF-based interface for navigating
between projects. It scans your project directories, detects project types,
and presents them in a searchable list.

**Use cases:**
- Quick navigation between projects
- Discovering forgotten projects
- Filtering projects by category (R, dev, quarto, etc.)
- Viewing worktrees with session indicators

**What it does:**
- Scans `$FLOW_PROJECTS_ROOT` for projects
- Detects project types (.STATUS files, DESCRIPTION, package.json, etc.)
- Displays icon-decorated project list
- Filters by category if specified
- Changes directory on selection

---

## Options

### Optional Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `[category]` | `all` | Filter: `r`, `dev`, `q`, `teach`, `rs`, `app`, `wt` |

### Flags

| Flag | Short | Description |
|------|-------|-------------|
| `--recent` | `-r` | Show only projects with Claude sessions |
| `--help` | `-h` | Show help message |

### Category Shortcuts

| Category | Code | Icon | Projects |
|----------|------|------|----------|
| R Packages | `r` | 📦 | r-packages/active, r-packages/stable |
| Dev Tools | `dev` | 🔧 | dev-tools/ |
| Quarto | `q` | 📝 | quarto/manuscripts, quarto/presentations |
| Teaching | `teach` | 🎓 | teaching/ courses |
| Research | `rs` | 🔬 | research/ projects |
| Applications | `app` | 📱 | apps/ |
| Worktrees | `wt` | 🌳 | All git worktrees from ~/.git-worktrees/ |

---

## Usage Examples

### Basic Usage

**Scenario:** Navigate to any project interactively

\`\`\`bash
# Open picker with all projects
pick
\`\`\`

**Output:**
\`\`\`
📦 rmediation
📦 medfit
🔧 flow-cli
🔧 atlas
📝 product-of-three
> _
\`\`\`

### Intermediate Usage

**Scenario:** Filter to specific category before picking

\`\`\`bash
# Show only dev-tools projects
pick dev
\`\`\`

**Output:**
\`\`\`
🔧 flow-cli
🔧 atlas
🔧 aiterm
🔧 nexus-cli
> _
\`\`\`

### Advanced Usage

**Scenario:** Jump directly to a project without picker

\`\`\`bash
# Direct jump (no FZF interface)
pick flow
\`\`\`

**Output:**
\`\`\`
📁 /Users/dt/projects/dev-tools/flow-cli
\`\`\`

---

## Common Patterns

### Pattern 1: Daily Project Rotation

**Use when:** Switching between active projects during day

\`\`\`bash
# Morning: Research
pick rs

# Afternoon: Dev work
pick dev

# Evening: Teaching prep
pick teach
\`\`\`

### Pattern 2: Worktree Management

**Use when:** Working on multiple features in parallel

\`\`\`bash
# Show all worktrees
pick wt

# Filter to specific project's worktrees
pick wt scribe
\`\`\`

### Pattern 3: Recent Projects Only

**Use when:** Resuming work from recent sessions

\`\`\`bash
# Show only projects with Claude sessions
pick --recent
# or
pick -r
\`\`\`

---

## Combining with Other Commands

### With Claude Code Launcher

\`\`\`bash
# Pick project, then launch Claude
pick && cc

# Or use CC dispatcher's built-in pick
cc pick
\`\`\`

### With Work Command

\`\`\`bash
# Pick project, then start work session
pick && work
\`\`\`

---

## Interactive Features

### Keybindings

| Key | Action |
|-----|--------|
| `Enter` | Navigate to selected project |
| `Ctrl-C` | Cancel (stay in current directory) |
| `Ctrl-O` | cd to project + launch Claude |
| `Ctrl-Y` | cd to project + launch Claude YOLO mode |
| `Ctrl-S` | View project .STATUS file |
| `Ctrl-L` | View project git log |

### FZF Search

| Input | Behavior |
|-------|----------|
| `flow` | Filter to projects matching "flow" |
| `^flow` | Match beginning: projects starting with "flow" |
| `flow$` | Match end: projects ending with "flow" |
| `!test` | Exclude: all projects except "test" |

---

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FLOW_PROJECTS_ROOT` | `$HOME/projects` | Root directory to scan |
| `FZF_DEFAULT_OPTS` | (various) | Custom FZF options |

**Example:**
\`\`\`bash
export FLOW_PROJECTS_ROOT="$HOME/work"
pick
\`\`\`

---

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success (project selected) |
| `1` | No project selected (Ctrl-C) |
| `130` | Interrupted (Ctrl-C) |

---

## Troubleshooting

### Issue 1: "No projects found"

**Symptoms:**
- Empty FZF picker
- Message: "No projects found in /Users/dt/projects"

**Cause:** `FLOW_PROJECTS_ROOT` not set or points to wrong directory

**Solution:**
\`\`\`bash
# Check current setting
echo $FLOW_PROJECTS_ROOT

# Set in .zshrc
export FLOW_PROJECTS_ROOT="$HOME/projects"
\`\`\`

### Issue 2: Projects missing from list

**Symptoms:**
- Some projects don't appear in picker
- Expected 10 projects, only see 5

**Cause:** Projects lack detection markers (.STATUS, DESCRIPTION, package.json, etc.)

**Solution:**
\`\`\`bash
# Add .STATUS file to project
cd missing-project
echo "status: active" > .STATUS
\`\`\`

### Issue 3: Keybindings don't work

**Symptoms:**
- Ctrl-O, Ctrl-Y don't launch Claude
- Ctrl-S doesn't show .STATUS

**Cause:** FZF version too old or custom FZF_DEFAULT_OPTS conflict

**Solution:**
\`\`\`bash
# Update FZF
brew upgrade fzf

# Check for conflicting options
echo $FZF_DEFAULT_OPTS
\`\`\`

---

## Best Practices

**Do:**
- ✅ Use category filters for faster navigation (`pick dev`)
- ✅ Add .STATUS files to all projects (improves detection)
- ✅ Use `pick --recent` to resume work quickly
- ✅ Learn keybindings (Ctrl-O for quick Claude launch)

**Don't:**
- ❌ Type full project names when `pick` is faster
- ❌ Navigate manually with `cd` between known projects
- ❌ Ignore session indicators (🟢/🟡) on worktrees
- ❌ Use `ls` when `pick` provides better UX

---

## Related Commands

- **hop** — Quick switch to last project
- **work** — Start work session (can use pick for project selection)
- **dash** — Project dashboard (shows all projects in table)
- **cc pick** — Launch Claude with project picker (combines both)

---

## See Also

- **Tutorial:** [Tutorial 2: Multiple Projects](../../tutorials/02-multiple-projects.md)
- **Workflow:** [Project Navigation Workflow](../../workflows/project-navigation.md)
- **Reference:** [Pick Command Reference](../../reference/PICK-COMMAND-REFERENCE.md)
- **Guide:** [Project Detection Guide](../../guides/PROJECT-DETECTION-GUIDE.md)

---

**Last Updated:** 2026-01-07
**Command Version:** v4.8.0 (worktree-aware)
```

---

## Section Guidelines

### Synopsis Section

**Always include:**
- Command syntax with OPTIONS and ARGUMENTS placeholders
- 3 quick examples (basic, common, advanced)

**Format:**
```markdown
## Synopsis

\`\`\`bash
command [OPTIONS] [ARGUMENTS]
\`\`\`

**Quick examples:**
\`\`\`bash
# [Most common - 80% of users]
command simple

# [Common variation - 15% of users]
command --flag arg

# [Advanced - 5% of users]
command --complex --options
\`\`\`
```

### Description Section

**Structure:**
1. 2-3 paragraphs explaining purpose and behavior
2. "Use cases" bullet list
3. "What it does" bullet list

**Keep it concise:**
- Focus on WHAT it does, not HOW (implementation details)
- Use active voice
- Start with most common use case

### Options Section

**Organization:**
1. Required arguments first
2. Optional arguments second
3. Flags third
4. Mode flags last

**Table format:**
```markdown
| Flag | Short | Description |
|------|-------|-------------|
| `--verbose` | `-v` | Enable verbose output |
```

### Usage Examples Section

**Always show:**
- Basic (beginner)
- Intermediate (common user)
- Advanced (power user)

**Include:**
- Scenario (when you'd use this)
- Command
- Expected output

---

## ADHD-Friendly Tips

1. **Examples first** — Show before explaining
2. **Scannable tables** — Use tables for options, not paragraphs
3. **Real output** — Show actual terminal output, not descriptions
4. **Cross-references** — Link to tutorials, workflows
5. **Quick examples section** — 3 examples right at top
6. **Troubleshooting prominent** — Don't bury common issues
7. **Exit codes documented** — Know what return codes mean

---

## Checklist for New Help Pages

- [ ] One-sentence description at top
- [ ] Synopsis with syntax and 3 quick examples
- [ ] Description section (2-3 paragraphs + use cases)
- [ ] Options organized (required, optional, flags, modes)
- [ ] Usage examples (basic, intermediate, advanced) with output
- [ ] Common patterns section
- [ ] Combining with other commands section
- [ ] Interactive features (if applicable)
- [ ] Configuration options
- [ ] Exit codes table
- [ ] Troubleshooting (at least 3 common issues)
- [ ] Best practices (do/don't lists)
- [ ] Related commands
- [ ] See also (links to tutorials, workflows, guides)
- [ ] Last updated date and version

---

**Last Updated:** 2026-01-07
**Template Version:** 1.0
