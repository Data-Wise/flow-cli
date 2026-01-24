# Scholar Integration Guide

**Purpose:** Coordinate teaching workflows between flow-cli and Scholar plugin
**Principle:** Teaching will ALWAYS be coordinated with Scholar

---

## Overview

flow-cli and Scholar are two complementary systems for teaching workflow management:

| System | Purpose | Language | Status |
|--------|---------|----------|--------|
| **flow-cli** | Workflow automation (deployment, Git, archival) | Pure ZSH | v5.6.0 ✅ |
| **Scholar** | Content generation (AI-powered materials) | Node.js | v2.0.1 ✅ |

**Key Principle:**
- Content generation → Scholar (AI-powered, templates, validation)
- Workflow automation → flow-cli (Git, deployment, archival)
- Configuration → Shared `.flow/teach-config.yml`

---

## Scholar Teaching Commands (v2.0.1)

Scholar provides 8 AI-powered teaching commands:

| Command | Purpose | Example |
|---------|---------|---------|
| `/teaching:exam` | Generate comprehensive exams | `/teaching:exam "Hypothesis Testing"` |
| `/teaching:quiz` | Create quick quizzes | `/teaching:quiz "Chapter 5 Review"` |
| `/teaching:syllabus` | Build course syllabus | `/teaching:syllabus` |
| `/teaching:assignment` | Create homework assignments | `/teaching:assignment "Data Analysis"` |
| `/teaching:rubric` | Generate grading rubrics | `/teaching:rubric "Final Project"` |
| `/teaching:slides` | Create lecture slides | `/teaching:slides "Introduction to Regression"` |
| `/teaching:feedback` | Generate student feedback | `/teaching:feedback "Student A Paper"` |
| `/teaching:demo` | Create demo course environment | `/teaching:demo --course-name "STAT-101"` |

### Common Flags

All Scholar teaching commands support:

| Flag | Description |
|------|-------------|
| `--dry-run` | Preview output without saving |
| `--format FORMAT` | Output format: markdown, quarto, latex, json, qti |
| `--output PATH` | Custom output path |

### Output Formats

| Format | Use Case | Extension |
|--------|----------|-----------|
| `markdown` | General purpose | `.md` |
| `quarto` | Academic publishing | `.qmd` |
| `latex` | Print-ready documents | `.tex` |
| `json` | Programmatic access | `.json` |
| `qti` | Canvas LMS import | `.xml` |

---

## flow-cli Teaching Commands (v5.6.0)

flow-cli provides workflow automation:

| Command | Purpose | Example |
|---------|---------|---------|
| `teach init "Course"` | Initialize course repository | `teach init "STAT 545"` |
| `teach deploy` | Deploy draft → production | `teach deploy` |
| `teach status` | Show course status | `teach status` |
| `teach week` | Current week info | `teach week` |
| `teach archive` | Create semester snapshot | `teach archive "Fall 2025"` |
| `teach config` | Edit course settings | `teach config` |

---

## Configuration Coordination

Both systems share the same configuration file: `.flow/teach-config.yml`

### Current Schema (v2.0.1)

```yaml
# Course Information (flow-cli)
course:
  name: "STAT 545"
  full_name: "Statistical Computing"
  semester: "Spring 2026"
  year: 2026
  instructor: "Dr. Smith"

# Branches (flow-cli)
branches:
  draft: "draft"
  production: "production"

# Deployment (flow-cli)
deployment:
  web:
    type: "github-pages"
    branch: "production"

# Scholar Integration (NEW - for Scholar v2.0.1+)
scholar:
  course_info:
    level: "undergraduate"        # undergraduate/graduate/both
    field: "statistics"           # statistics/mathematics/etc.
    difficulty: "intermediate"    # beginner/intermediate/advanced
    credits: 3

  style:
    tone: "formal"                # formal/conversational
    notation: "statistical"       # statistical/mathematical/standard
    examples: true                # include worked examples

  topics:                         # Course topic list (for exam scope)
    - "Descriptive Statistics"
    - "Probability"
    - "Inference"
    - "Regression"

  grading:                        # Grade distribution
    homework: 20
    quizzes: 15
    midterm1: 15
    midterm2: 15
    final: 25
    participation: 10
```

### How Systems Use Config

| System | Reads | Creates |
|--------|-------|---------|
| flow-cli | `course`, `branches`, `deployment` | Full config via `teach init` |
| Scholar | `scholar` section | Nothing (reads only) |

---

## Integrated Workflows

### Workflow 1: Course Setup

```bash
# 1. Initialize course with flow-cli
teach init "STAT 545"
# Creates: .flow/teach-config.yml, Git branches, GitHub Actions

# 2. Edit config to add Scholar settings
# Add: scholar.course_info, scholar.style, scholar.topics

# 3. Generate syllabus with Scholar
claude
> /teaching:syllabus

# 4. Deploy to students
teach deploy
```

### Workflow 2: Create Exam

```bash
# 1. Start work session
work stat-545

# 2. Generate exam with Scholar
claude
> /teaching:exam "Midterm 1: Probability and Inference" --format quarto

# 3. Review and edit generated exam
# (Manual step in your editor)

# 4. Deploy to students
teach deploy
```

### Workflow 3: Weekly Lecture (Planned v2.1.0)

```bash
# 1. Create lesson plan
# Edit: .flow/lesson-plans/week05.yml

# 2. Generate lecture from plan
claude
> /teaching:lecture --from-plan week05

# 3. Generate slides from lecture
claude
> /teaching:slides --from-lecture week05

# 4. Deploy
teach deploy
```

---

## Future Integration (v5.8.0+)

### Planned: flow-cli Wrappers

Future versions of flow-cli will wrap Scholar commands:

```bash
# Instead of:
claude
> /teaching:exam "Topic"

# You'll be able to run:
teach exam "Topic"
```

**Wrapper benefits:**
- Single CLI for all teaching tasks
- Config validation before invocation
- Consistent error handling
- Integration with v2.1.0 dual config sync

### Planned: Lesson Plan Workflow

Scholar v2.1.0 will add lesson plan-driven workflows:

```
Lesson Plan (YAML) → Lecture → Slides → Auto-sync
```

**New commands (planned):**
- `/teaching:lecture` - Generate full lecture notes/outline
- `/scholar:sync` - Sync YAML → JSON configs

---

## Best Practices

### 1. Always Use Shared Config

```bash
# ✅ Good: Both tools use .flow/teach-config.yml
teach init "STAT 545"  # Creates config
/teaching:exam "..."    # Reads config

# ❌ Bad: Separate configs
# Don't create separate config files for Scholar
```

### 2. Generate, Then Edit

```bash
# ✅ Good: AI generates, human refines
/teaching:exam "Topic" --dry-run  # Preview first
/teaching:exam "Topic"            # Generate
# Then edit in your editor

# ❌ Bad: Expect perfect output
# AI-generated content always needs human review
```

### 3. Version Control Everything

```bash
# ✅ Good: Commit generated content
git add exams/midterm1.qmd
git commit -m "Add midterm 1 exam"

# ❌ Bad: Generate without versioning
# Always commit generated materials
```

### 4. Use Dry Run

```bash
# ✅ Good: Preview before generating
/teaching:exam "Topic" --dry-run

# ❌ Bad: Generate blindly
# Always preview first, especially for large content
```

---

## Troubleshooting

### Scholar command not found

```bash
# Check Scholar is installed
claude --version

# If not installed:
# Visit: https://claude.ai/code
```

### Config not detected by Scholar

```bash
# Check config exists
ls -la .flow/teach-config.yml

# If missing, create with flow-cli:
teach init "Course Name"

# Or create manually with scholar section
```

### Wrong output format

```bash
# Specify format explicitly
/teaching:exam "Topic" --format quarto

# Available formats: markdown, quarto, latex, json, qti
```

---

## Related Documentation

### flow-cli

- [Teaching Commands Detailed](TEACHING-COMMANDS-DETAILED.md)
- [Teaching Workflow Visual](TEACHING-WORKFLOW-VISUAL.md)
- [Teaching Demo Guide](TEACHING-DEMO-GUIDE.md)

### Scholar

- [Scholar Documentation](https://github.com/Data-Wise/scholar)
- [Scholar API Reference](https://github.com/Data-Wise/scholar/docs/API-REFERENCE.md)
- [Scholar Configuration](https://github.com/Data-Wise/scholar/docs/CONFIGURATION.md)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-14 | Initial guide documenting Scholar v2.0.1 integration |

---

*Last Updated: 2026-01-14*
*flow-cli v5.6.0 | Scholar v2.0.1*
