# Comprehensive Help System Guide

**Version:** v5.14.0
**Last Updated:** 2026-01-20
**Status:** ✅ Production Ready

---

## Overview

The comprehensive help system provides **18 detailed help functions** for all teach dispatcher commands, following consistent formatting, progressive disclosure patterns, and ADHD-friendly design principles.

### What's Included

- ✅ **18 Help Functions** - Complete coverage of all teach commands
- ✅ **Consistent Formatting** - Same structure across all help text
- ✅ **Progressive Disclosure** - Quick Start → Options → Examples → Advanced
- ✅ **15-Minute Tutorial** - Quick-start guide for new users
- ✅ **Cross-References** - Related commands and documentation links
- ✅ **Visual Hierarchy** - Box borders, color coding, clear sections

---

## Quick Start

### View Main Help

```bash
$ teach --help
# or
$ teach help
# or
$ teach -h
```

Shows complete dispatcher overview with all command categories.

### View Command-Specific Help

```bash
$ teach lecture --help       # Lecture generation help
$ teach exam -h              # Exam creation help
$ teach validate help        # Validation help
```

All three formats work: `--help`, `-h`, `help`

### Follow the Tutorial

```bash
# Open the quick-start tutorial
cat docs/tutorials/TEACHING-QUICK-START.md

# Or visit on the website
open https://Data-Wise.github.io/flow-cli/tutorials/TEACHING-QUICK-START/
```

15-minute walkthrough from setup to deployment.

---

## Help Function Structure

Every help function follows this **consistent structure**:

```
╔════════════════════════════════════════════════════════════╗
║  teach <command> - Description                            ║
╚════════════════════════════════════════════════════════════╝

USAGE
  teach <command> <args> [options]

ALIASES
  shortcut → command

QUICK START (3 examples)
  # Basic usage
  $ teach command "argument"

  # With options
  $ teach command "arg" --option value

  # Advanced
  $ teach command "arg" --option1 --option2

OPTIONS
  Categorized flags with descriptions

EXAMPLES
  Detailed use cases with explanations

TIPS
  • Pro tips and best practices
  • Common patterns
  • Performance notes

LEARN MORE
  📖 Full guide: docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md
  📖 Quick ref: docs/reference/.archive/REFCARD-TEACHING-V3.md

SEE ALSO:
  teach related-cmd - Description
  teach another-cmd - Description
```

---

## All Help Functions

### Scholar Commands (9)

AI-powered content generation:

| Command | Help Function | Purpose |
|---------|---------------|---------|
| `teach lecture` | `_teach_lecture_help()` | Generate lecture notes (20-40 pages) |
| `teach slides` | `_teach_slides_help()` | Create presentation slides |
| `teach exam` | `_teach_exam_help()` | Generate comprehensive exams |
| `teach quiz` | `_teach_quiz_help()` | Create quiz questions |
| `teach assignment` | `_teach_assignment_help()` | Generate homework assignments |
| `teach syllabus` | `_teach_syllabus_help()` | Create course syllabus |
| `teach rubric` | `_teach_rubric_help()` | Generate grading rubrics |
| `teach feedback` | `_teach_feedback_help()` | Generate student feedback |
| *(demo)* | `_teach_demo_help()` | Demo course generation |

### Validation & Quality (2)

| Command | Help Function | Purpose |
|---------|---------------|---------|
| `teach validate` | `_teach_validate_help()` | Validate Quarto files |
| `teach hooks` | `_teach_hooks_help()` | Manage git hooks |

### Cache Management (2)

| Command | Help Function | Purpose |
|---------|---------------|---------|
| `teach cache` | `_teach_cache_help()` | Interactive cache menu |
| `teach clean` | `_teach_clean_help()` | Clean temporary files |

### Health Checks (1)

| Command | Help Function | Purpose |
|---------|---------------|---------|
| `teach doctor` | `_teach_doctor_help()` | Environment health checks |

### Deployment (1)

| Command | Help Function | Purpose |
|---------|---------------|---------|
| `teach deploy` | `_teach_deploy_help()` | Deploy to GitHub Pages |

### Project Management (3)

| Command | Help Function | Purpose |
|---------|---------------|---------|
| `teach init` | `_teach_init_help()` | Initialize teaching project |
| `teach config` | `_teach_config_help()` | Manage configuration |
| `teach profiles` | `_teach_profiles_help()` | Quarto profile management |

### Lesson Plan Management (1)

| Command | Help Function | Purpose |
|---------|---------------|---------|
| `teach plan` | `_teach_plan_help()` | CRUD management of lesson plan weeks |

**Note:** `teach plan help` shows all subcommands: create, list, show, edit, delete.

---

## Progressive Disclosure Pattern

Help text follows **progressive disclosure** - users can stop reading as soon as they find what they need:

### Level 1: Quick Start (3 examples)

```bash
QUICK START
  # Basic
  $ teach lecture "Linear Regression"

  # With week
  $ teach lecture "ANOVA" --week 5

  # Custom template
  $ teach lecture "Bayesian Stats" --template quarto
```

**Target:** Users who know what they want, just need syntax

### Level 2: Options (categorized flags)

```bash
OPTIONS
  Content Selection:
    --week N           Week number
    --topic "text"     Override topic

  Output Format:
    --template FORMAT  markdown|quarto|typst|pdf
    --style TONE       formal|casual
```

**Target:** Users exploring available options

### Level 3: Examples (detailed use cases)

```bash
EXAMPLES
  Basic lecture generation:
    $ teach lecture "Hypothesis Testing"
    # Creates: lectures/hypothesis-testing.qmd
    # Length: ~2500 words, 3 examples

  Week-based with lesson plan:
    $ teach lecture --week 5
    # Auto-loads topic from lesson-plan.yml
    # Includes learning objectives
```

**Target:** Users learning workflows

### Level 4: Tips & Advanced

```bash
TIPS
  • Create lesson-plan.yml first for better context
  • Content is auto-backed up before overwriting
  • Use --week for consistent naming

LEARN MORE
  📖 docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md#content-creation
```

**Target:** Power users, troubleshooting

---

## Color Coding

All help functions use **FLOW_COLORS** for consistent visual hierarchy:

```zsh
${FLOW_COLORS[header]}     # ╔═══╗ Box borders (cyan)
${FLOW_COLORS[cmd]}        # Command names (green)
${FLOW_COLORS[accent]}     # Aliases, highlights (yellow)
${FLOW_COLORS[muted]}      # Comments, metadata (gray)
${FLOW_COLORS[bold]}       # Section headers (white bold)
${FLOW_COLORS[success]}    # Success messages (green)
${FLOW_COLORS[info]}       # Info messages (blue)
${FLOW_COLORS[dim]}        # Secondary text (dark gray)
${FLOW_COLORS[reset]}      # Reset to default
```

### Visual Hierarchy Example

```
╔════════════════════════════════════════════════════════════╗  ← header
║  teach lecture - Generate Lecture Notes                   ║  ← header + cmd
╚════════════════════════════════════════════════════════════╝  ← header

USAGE                                                           ← bold
  teach lecture <topic> [options]                               ← cmd

ALIASES                                                         ← bold
  lec → lecture                                                 ← accent

# Basic usage                                                   ← muted
$ teach lecture "Linear Regression"                             ← muted
```

---

## ADHD-Friendly Design Principles

The help system follows **ADHD-friendly design**:

### 1. Scannable Structure

✅ **Box borders** - Clear visual boundaries
✅ **Bold section headers** - Easy to scan
✅ **Categorized options** - Grouped by purpose
✅ **Short examples first** - Quick wins at the top

### 2. Progressive Complexity

✅ **Quick Start first** - 3 examples you can copy-paste
✅ **Options next** - Categorized, not alphabetical
✅ **Examples with explanations** - What happens when you run this
✅ **Tips last** - Advanced users can keep reading

### 3. Consistent Patterns

✅ **Same structure everywhere** - Learn once, use everywhere
✅ **Same color coding** - Visual consistency
✅ **Same terminology** - No synonyms for same concept

### 4. Low Cognitive Load

✅ **3 Quick Start examples** - Not 1 (too rigid), not 5 (too many)
✅ **Grouped flags** - By purpose, not alphabet
✅ **Inline comments** - Explain *why*, not just *what*
✅ **Clear next steps** - "SEE ALSO" shows related commands

---

## Help Routing

### How Help is Invoked

Commands support **three help formats**:

```zsh
teach lecture --help     # Long flag
teach lecture -h         # Short flag
teach lecture help       # Positional argument
```

### Routing Implementation

```zsh
lecture|lec)
    case "$1" in
        --help|-h|help)
            _teach_lecture_help
            return 0
            ;;
        *)
            _teach_scholar_wrapper "lecture" "$@"
            ;;
    esac
    ;;
```

**Pattern:**
1. Check if first argument is help flag
2. Call help function and exit (return 0)
3. Otherwise pass to command implementation

---

## Cross-References

Every help function includes **cross-references**:

### LEARN MORE Section

Links to comprehensive guides:

```
LEARN MORE
  📖 Full guide: docs/guides/TEACHING-WORKFLOW-V3-GUIDE.md#section
  📖 Quick ref: docs/reference/.archive/REFCARD-TEACHING-V3.md
```

### SEE ALSO Section

Links to related commands:

```
SEE ALSO:
  teach quiz - Create quiz questions
  teach rubric - Generate grading rubric
```

### Cross-Reference Network

```
teach lecture
  ↓
  SEE ALSO:
    • teach slides  → Generate slides from lecture
    • teach exam    → Create exam on lecture topics

teach exam
  ↓
  SEE ALSO:
    • teach quiz    → Shorter assessment format
    • teach rubric  → Create grading rubric
```

---

## Examples Best Practices

### Good Example Structure

```bash
EXAMPLES
  # Category: Basic usage
  $ teach command "argument"
  # Creates: output/file.ext
  # Default behavior explanation

  # Category: With options
  $ teach command "arg" --option value
  # Effect: What changes with this option
  # Use when: Specific use case

  # Category: Advanced
  $ teach command "arg" \
    --option1 \
    --option2 value \
    --option3
  # Complex workflow explanation
```

### Example Elements

Each example should include:

1. **Comment header** - Categorize the example
2. **Command** - Exact copy-pasteable command
3. **Effect** - What happens when you run it
4. **Use case** - When to use this pattern

---

## Quick-Start Tutorial

The **15-minute tutorial** (`docs/tutorials/TEACHING-QUICK-START.md`) provides:

### Step-by-Step Walkthrough

1. **Environment Setup** (3 min) - `teach doctor`
2. **Create Course** (2 min) - `teach init`
3. **Enable Automation** (1 min) - `teach hooks install`
4. **First Lecture** (3 min) - `teach lecture`
5. **Create Assessment** (2 min) - `teach quiz`
6. **Validate Content** (1 min) - `teach validate`
7. **Commit Changes** (1 min) - Git workflow
8. **Deploy Website** (2 min) - `teach deploy`

### Tutorial Design

- ✅ **Time estimates** - Realistic for each step
- ✅ **Expected output** - Show what success looks like
- ✅ **Troubleshooting** - Common issues and fixes
- ✅ **Next steps** - Where to go after completion

---

## For Contributors

### Adding New Help Functions

When adding a new teach subcommand, create a help function:

```zsh
_teach_newcmd_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔════════════════════════════════════════════════════════════╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach newcmd${FLOW_COLORS[reset]} - Description (< 40 chars)          ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚════════════════════════════════════════════════════════════╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach newcmd <args> [options]

${FLOW_COLORS[bold]}ALIASES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[accent]}nc${FLOW_COLORS[reset]} → newcmd

${FLOW_COLORS[bold]}QUICK START${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Basic${FLOW_COLORS[reset]}
  $ teach newcmd "arg"

  ${FLOW_COLORS[muted]}# With options${FLOW_COLORS[reset]}
  $ teach newcmd "arg" --option

  ${FLOW_COLORS[muted]}# Advanced${FLOW_COLORS[reset]}
  $ teach newcmd "arg" --opt1 --opt2

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--option VALUE${FLOW_COLORS[reset]}     Description

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  ${FLOW_COLORS[muted]}# Example 1${FLOW_COLORS[reset]}
  $ teach newcmd "example"
  ${FLOW_COLORS[dim]}# Creates: output${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Pro tip 1
  • Pro tip 2

${FLOW_COLORS[bold]}LEARN MORE${FLOW_COLORS[reset]}
  📖 Guide: docs/guides/GUIDE.md

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach related${FLOW_COLORS[reset]} - Related command

EOF
}
```

### Validation Checklist

Before committing new help functions:

- [ ] Box borders are exactly 60 chars wide
- [ ] Title fits within box (≤ 58 chars after stripping ANSI)
- [ ] All sections present (USAGE, ALIASES, QUICK START, etc.)
- [ ] 3 Quick Start examples included
- [ ] Options are categorized, not alphabetical
- [ ] Examples have inline comments explaining output
- [ ] LEARN MORE has at least 1 documentation link
- [ ] SEE ALSO has at least 1 related command
- [ ] Color codes use FLOW_COLORS variables
- [ ] Help routing added to dispatcher case statement

### Testing Help Functions

```bash
# Test help invocation
teach newcmd --help
teach newcmd -h
teach newcmd help

# Verify output structure
teach newcmd --help | grep -c "╔══"    # Should be 2 (top + bottom)
teach newcmd --help | grep "USAGE"     # Should exist
teach newcmd --help | grep "EXAMPLES"  # Should exist

# Test all commands
for cmd in lecture exam quiz validate deploy doctor; do
    echo "Testing: teach $cmd --help"
    teach $cmd --help > /dev/null || echo "FAIL: $cmd"
done
```

---

## Technical Implementation

### File Location

All help functions are in: `lib/dispatchers/teach-dispatcher.zsh`

```zsh
# Help functions (lines ~100-2000)
_teach_dispatcher_help() { ... }
_teach_lecture_help() { ... }
_teach_exam_help() { ... }
# ... 15 more help functions

# Command routing (lines ~2700-3200)
teach() {
    case "$subcommand" in
        lecture|lec)
            case "$1" in
                --help|-h|help) _teach_lecture_help; return 0 ;;
                *) _teach_scholar_wrapper "lecture" "$@" ;;
            esac
            ;;
        # ... other commands
    esac
}
```

### Box Width Constraints

Box borders are **60 characters wide**:

```
╔════════════════════════════════════════════════════════════╗
^                                                          ^
0                                                         60
```

Title must fit within **58 characters** (60 minus 2 for `║` borders):

```zsh
# Maximum title length example (58 chars)
║  teach profiles - Manage Quarto Profile Configurations  ║
^                                                        ^
2                                                       60
```

### Color Variables

Colors are defined in `lib/core.zsh`:

```zsh
typeset -gA FLOW_COLORS=(
    [header]='\033[1;36m'    # Cyan bold
    [cmd]='\033[1;32m'       # Green bold
    [accent]='\033[1;33m'    # Yellow bold
    [muted]='\033[0;37m'     # Gray
    [bold]='\033[1m'         # White bold
    [success]='\033[1;32m'   # Green bold
    [info]='\033[1;34m'      # Blue bold
    [dim]='\033[2m'          # Dimmed
    [reset]='\033[0m'        # Reset
)
```

---

## Related Documentation

### Comprehensive Guides

- **[Teaching Workflow v3.0 Guide](TEACHING-WORKFLOW-V3-GUIDE.md)** - Complete workflow documentation
- **[Backup System Guide](BACKUP-SYSTEM-GUIDE.md)** - Backup system deep dive
- **[Quarto Workflow Phase 2 Guide](QUARTO-WORKFLOW-PHASE-2-GUIDE.md)** - Advanced Quarto features

### Quick References

- **[Teaching Quick Reference](../reference/.archive/REFCARD-TEACHING-V3.md)** - Command cheat sheet
- **[Quarto Phase 2 Quick Reference](../reference/.archive/REFCARD-QUARTO-PHASE2.md)** - Phase 2 commands
- **[Command Quick Reference](../help/QUICK-REFERENCE.md)** - All flow-cli commands

### Tutorials

- **[Teaching Quick Start (15 min)](../tutorials/TEACHING-QUICK-START.md)** - Beginner walkthrough
- **[Teach Dispatcher Tutorial](../tutorials/14-teach-dispatcher.md)** - Detailed tutorial

---

## Changelog

### v5.14.0 (2026-01-20)

- ✅ Added 18 comprehensive help functions
- ✅ Created 15-minute quick-start tutorial
- ✅ Standardized help structure across all commands
- ✅ Implemented progressive disclosure pattern
- ✅ Added cross-references between commands
- ✅ Updated 6 existing documentation files
- ✅ Added REFCARD-QUARTO-PHASE2.md (490 lines)
- ✅ Expanded TEACHING-WORKFLOW-V3-GUIDE.md (+973 lines)

---

**Last Updated:** 2026-01-20
**Maintainer:** flow-cli team
**Status:** ✅ Production Ready
