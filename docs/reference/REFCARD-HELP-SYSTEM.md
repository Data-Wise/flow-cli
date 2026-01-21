# Help System Quick Reference

**Version:** v5.14.0 | **Commands:** 18 help functions | **Tutorial:** 15 minutes

---

## Quick Start

```bash
teach --help           # Main dispatcher help
teach <cmd> --help     # Command-specific help
teach <cmd> -h         # Short form
teach <cmd> help       # Alternative form
```

---

## All Help Commands

### Scholar Commands (AI Content Generation)

| Command | Alias | Help | Purpose |
|---------|-------|------|---------|
| `teach lecture` | `lec` | `--help` | Generate 20-40 page lecture notes |
| `teach slides` | `sl` | `--help` | Create presentation slides |
| `teach exam` | `e` | `--help` | Generate comprehensive exam |
| `teach quiz` | `q` | `--help` | Create quiz questions |
| `teach assignment` | `hw` | `--help` | Generate homework assignment |
| `teach syllabus` | `syl` | `--help` | Create course syllabus |
| `teach rubric` | `rb` | `--help` | Generate grading rubric |
| `teach feedback` | `fb` | `--help` | Generate student feedback |

### Validation & Quality

| Command | Alias | Help | Purpose |
|---------|-------|------|---------|
| `teach validate` | `val`, `v` | `--help` | Validate Quarto files |
| `teach hooks` | - | `--help` | Manage git hooks |

### Cache & Cleanup

| Command | Alias | Help | Purpose |
|---------|-------|------|---------|
| `teach cache` | - | `--help` | Interactive cache menu |
| `teach clean` | - | `--help` | Delete _freeze/ + _site/ |

### Health & Setup

| Command | Alias | Help | Purpose |
|---------|-------|------|---------|
| `teach doctor` | `doc` | `--help` | Environment health checks |
| `teach init` | - | `--help` | Initialize teaching project |
| `teach config` | `c` | `--help` | Manage configuration |
| `teach profiles` | - | `--help` | Quarto profile management |

### Deployment

| Command | Alias | Help | Purpose |
|---------|-------|------|---------|
| `teach deploy` | `d` | `--help` | Deploy to GitHub Pages |

### Status

| Command | Alias | Help | Purpose |
|---------|-------|------|---------|
| `teach status` | `s` | `--help` | Project dashboard |
| `teach week` | `w` | `--help` | Current week info |

---

## Help Structure

Every help function follows this pattern:

```
╔════════════════════════════════════════════════════════════╗
║  teach <command> - Description                            ║
╚════════════════════════════════════════════════════════════╝

USAGE          Command syntax
ALIASES        Shortcuts
QUICK START    3 copy-paste examples
OPTIONS        Categorized flags
EXAMPLES       Detailed use cases
TIPS           Pro tips
LEARN MORE     Documentation links
SEE ALSO       Related commands
```

---

## Common Workflows

### Getting Started

```bash
# 1. Check environment
teach doctor --help          # See health check options
teach doctor                 # Run health check
teach doctor --fix           # Auto-install missing deps

# 2. Initialize project
teach init --help            # See initialization options
teach init "Course Name"     # Create new project

# 3. Enable quality checks
teach hooks --help           # See git hook options
teach hooks install          # Install all hooks
```

### Content Creation

```bash
# Generate lecture
teach lecture --help                    # See all options
teach lecture "Linear Regression"       # Basic lecture
teach lecture --week 5                  # Week-specific

# Create exam
teach exam --help                       # See all options
teach exam "Midterm"                    # Basic exam
teach exam "Final" --questions 30       # With custom count
```

### Validation & Quality

```bash
# Validate content
teach validate --help        # See validation modes
teach validate              # Full validation
teach validate --yaml       # YAML-only (fast)
teach validate --watch      # Watch mode

# Manage cache
teach cache --help          # See cache operations
teach cache                 # Interactive menu
teach cache status          # Show cache info
teach cache clear           # Delete cache
```

### Deployment

```bash
# Deploy website
teach deploy --help         # See deployment options
teach deploy               # Full site deployment
teach deploy --preview     # Preview changes first
```

---

## Progressive Disclosure

Help text is designed for **quick scanning**:

### Level 1: Quick Start (3 examples)

Stop here if you just need syntax.

```bash
QUICK START
  # Basic
  $ teach command "arg"

  # With options
  $ teach command "arg" --option

  # Advanced
  $ teach command "arg" --opt1 --opt2
```

### Level 2: Options (categorized)

Explore available flags grouped by purpose.

```bash
OPTIONS
  Content Selection:
    --week N
    --topic "text"

  Output Format:
    --template FORMAT
    --style TONE
```

### Level 3: Examples (detailed)

Learn complete workflows with explanations.

```bash
EXAMPLES
  Basic usage:
    $ teach command "arg"
    # Creates: output/file.ext
    # Explanation of what happens
```

### Level 4: Tips & Links

Pro tips and related documentation.

```bash
TIPS
  • Best practice 1
  • Performance tip 2

LEARN MORE
  📖 docs/guides/GUIDE.md

SEE ALSO:
  teach related - Description
```

---

## Color Coding

| Color | Used For | Example |
|-------|----------|---------|
| **Cyan bold** | Box borders | `╔═══╗` |
| **Green bold** | Command names | `teach lecture` |
| **Yellow bold** | Aliases | `lec → lecture` |
| **Gray** | Comments | `# Basic usage` |
| **White bold** | Section headers | `USAGE` |

---

## Help Flags

All commands support **three formats**:

```bash
teach lecture --help     # Long flag (verbose)
teach lecture -h         # Short flag (quick)
teach lecture help       # Positional (alternative)
```

All three produce identical output.

---

## Quick Reference Workflow

```bash
# Pattern: Get help → Run command → Get more help if needed

$ teach lecture --help           # Read QUICK START section
$ teach lecture "ANOVA"          # Run basic command
$ teach lecture --help           # Read OPTIONS for more flags
$ teach lecture "ANOVA" --week 5 # Run with options
```

---

## 15-Minute Tutorial

For first-time users, follow the **quick-start tutorial**:

```bash
# View tutorial
cat docs/tutorials/TEACHING-QUICK-START.md

# Or visit website
open https://Data-Wise.github.io/flow-cli/tutorials/TEACHING-QUICK-START/
```

**Tutorial steps:**
1. Environment Setup (3 min)
2. Create Course (2 min)
3. Enable Automation (1 min)
4. First Lecture (3 min)
5. Create Assessment (2 min)
6. Validate Content (1 min)
7. Commit Changes (1 min)
8. Deploy Website (2 min)

---

## ADHD-Friendly Features

✅ **Scannable** - Box borders, bold headers
✅ **Progressive** - Quick wins first, details later
✅ **Consistent** - Same structure everywhere
✅ **Colorful** - Visual hierarchy with colors
✅ **Examples** - Copy-paste ready commands
✅ **Grouped** - Options by purpose, not alphabet
✅ **Cross-linked** - Related commands shown

---

## Common Help Commands

```bash
# Scholar commands
teach lecture --help     # Lecture generation
teach exam --help        # Exam creation
teach quiz --help        # Quiz generation
teach assignment --help  # Homework creation

# Quality & validation
teach validate --help    # Content validation
teach hooks --help       # Git hooks management
teach doctor --help      # Health checks

# Deployment
teach deploy --help      # GitHub Pages deployment
teach cache --help       # Cache management

# Setup
teach init --help        # Project initialization
teach config --help      # Configuration management
```

---

## For Contributors

### Adding New Help Functions

Template:

```zsh
_teach_newcmd_help() {
    cat <<EOF
${FLOW_COLORS[header]}╔═══...═══╗${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}  ${FLOW_COLORS[cmd]}teach newcmd${FLOW_COLORS[reset]} - Description  ${FLOW_COLORS[header]}║${FLOW_COLORS[reset]}
${FLOW_COLORS[header]}╚═══...═══╝${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}USAGE${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach newcmd <args>

${FLOW_COLORS[bold]}QUICK START${FLOW_COLORS[reset]}
  $ teach newcmd "arg"
  $ teach newcmd "arg" --option
  $ teach newcmd "arg" --opt1 --opt2

${FLOW_COLORS[bold]}OPTIONS${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}--option${FLOW_COLORS[reset]}  Description

${FLOW_COLORS[bold]}EXAMPLES${FLOW_COLORS[reset]}
  $ teach newcmd "example"
  ${FLOW_COLORS[dim]}# Explanation${FLOW_COLORS[reset]}

${FLOW_COLORS[bold]}TIPS${FLOW_COLORS[reset]}
  • Tip 1

${FLOW_COLORS[bold]}LEARN MORE${FLOW_COLORS[reset]}
  📖 docs/guides/GUIDE.md

${FLOW_COLORS[muted]}SEE ALSO:${FLOW_COLORS[reset]}
  ${FLOW_COLORS[cmd]}teach related${FLOW_COLORS[reset]}

EOF
}
```

### Checklist

- [ ] Box borders exactly 60 chars wide
- [ ] Title ≤ 58 chars (after stripping ANSI)
- [ ] 3 Quick Start examples
- [ ] Options categorized (not alphabetical)
- [ ] Examples with inline comments
- [ ] LEARN MORE section
- [ ] SEE ALSO section
- [ ] Help routing in dispatcher

---

## Related Documentation

### Guides

- [Help System Guide](../guides/HELP-SYSTEM-GUIDE.md) - Comprehensive documentation
- [Teaching Workflow v3.0](../guides/TEACHING-WORKFLOW-V3-GUIDE.md) - Complete workflow
- [Backup System](../guides/BACKUP-SYSTEM-GUIDE.md) - Backup deep dive

### Quick References

- [Teaching Quick Ref](REFCARD-TEACHING-V3.md) - All teaching commands
- [Quarto Phase 2 Quick Ref](REFCARD-QUARTO-PHASE2.md) - Advanced Quarto
- [Command Quick Ref](COMMAND-QUICK-REFERENCE.md) - All flow-cli commands

### Tutorials

- [Teaching Quick Start (15 min)](../tutorials/TEACHING-QUICK-START.md) - Beginner walkthrough
- [Teach Dispatcher](../tutorials/14-teach-dispatcher.md) - Detailed tutorial

---

**Last Updated:** 2026-01-20 | **Version:** v5.14.0 | **Status:** ✅ Production Ready
