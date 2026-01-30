# Teaching Workflow Documentation

> **Complete teaching workflow management for Quarto course websites**
>
> From content creation to deployment, with AI-powered assistance, automated backups, and Git integration

---

## Quick Navigation

### 🚀 Getting Started

New to the teaching workflow? Start here:

- **[Quick Start Guide](../tutorials/14-teach-dispatcher.md)** - 20-minute tutorial covering the basics
- **[Setup & Initialization](../commands/teach-init.md)** - Initialize your first course
- **[Complete v3.0 Workflow](../guides/TEACHING-WORKFLOW-V3-GUIDE.md)** - End-to-end workflow documentation

### 📚 Core Workflows

Learn the essential teaching workflows:

- **[Content Creation](../guides/INTELLIGENT-CONTENT-ANALYSIS.md)** - Create and analyze course content
- **[Git Integration](../tutorials/19-teaching-git-integration.md)** - Version control for teaching materials
- **[Visual Workflow Guide](../guides/TEACHING-WORKFLOW-VISUAL.md)** - Workflow diagrams and flowcharts

### ✨ Features

Explore powerful teaching features:

| Feature | Description | Tutorial |
|---------|-------------|----------|
| **Content Analysis** | AI-powered concept extraction & validation | [Tutorial](../tutorials/21-teach-analyze.md) |
| **AI Prompts** | Generate teaching content with Scholar | [Tutorial](../tutorials/28-teach-prompt.md) |
| **Templates** | Reusable content templates | [Tutorial](../tutorials/24-template-management.md) |
| **LaTeX Macros** | Consistent mathematical notation | [Tutorial](../tutorials/26-latex-macros.md) |
| **Lesson Plans** | CRUD management of weekly plans | [Tutorial](../tutorials/27-lesson-plan-management.md) |
| **Backups** | Automated backup system | [Guide](../guides/BACKUP-SYSTEM-GUIDE.md) |

### 📖 Reference

Quick reference materials:

- **[Command Overview](../commands/teach.md)** - Complete `teach` dispatcher documentation
- **[Templates Quick Ref](../reference/REFCARD-TEMPLATES.md)** - Template system cheat sheet
- **[LaTeX Macros Quick Ref](../reference/REFCARD-MACROS.md)** - Macro definitions and usage
- **[Lesson Plans Quick Ref](../reference/REFCARD-TEACH-PLAN.md)** - Lesson plan commands
- **[Prompts Quick Ref](../reference/REFCARD-PROMPTS.md)** - AI prompt templates
- **[Help System](../guides/HELP-SYSTEM-GUIDE.md)** - Enhanced help system guide

### 🎓 Advanced Topics

For power users and advanced workflows:

- **[Scholar Integration](../tutorials/scholar-enhancement/index.md)** - AI-assisted content generation
- **[Course Planning Best Practices](../guides/COURSE-PLANNING-BEST-PRACTICES.md)** - Design principles
- **[Migration from v2](../guides/TEACHING-V3-MIGRATION-GUIDE.md)** - Upgrade guide
- **[System Architecture](../guides/TEACHING-SYSTEM-ARCHITECTURE.md)** - Technical deep dive
- **[Course Examples](../examples/course-planning/README.md)** - Real-world examples

---

## What is the Teaching Workflow?

The flow-cli teaching workflow provides a complete solution for managing Quarto-based course websites:

### Key Capabilities

1. **Fast Deployment** (< 2 minutes)
   - Branch-based draft/production workflow
   - Preview changes before publishing
   - Automated GitHub Pages deployment

2. **Health Monitoring**
   - Dependency verification (`teach doctor`)
   - Configuration validation
   - Git setup checks
   - Scholar integration status

3. **Content Management**
   - Template-based content creation
   - LaTeX macro consistency
   - Lesson plan management
   - Content analysis and validation

4. **AI Integration**
   - Scholar-powered content generation
   - Smart prompt templates
   - Auto-commit workflows
   - Context-aware assistance

5. **Safety First**
   - Automated backup system
   - Retention policies
   - Preview before deploy
   - Rollback capabilities

### Design Philosophy

- **ADHD-Friendly** - Clear status, visual feedback, minimal cognitive load
- **Context-Aware** - Auto-load lesson plans, detect course structure
- **Safety First** - Preview changes, backup before modifying
- **Automated** - Backups happen automatically, retention policies apply

---

## Common Workflows

### Create New Course

```bash
# Interactive setup
teach init "STAT 545: Regression Analysis"

# Non-interactive (accept defaults)
teach init -y "STAT 440"
```

### Daily Teaching Workflow

```bash
# Check system health
teach doctor

# Check course status
teach status

# Generate content with AI
teach exam "Topic Name"
teach quiz "Topic Name"
teach slides "Topic Name"

# Deploy to production
teach deploy
```

### Semester Management

```bash
# Create weekly lesson plan
teach plan create 3 --topic "Probability" --style rigorous

# List all lesson plans
teach plan list

# End of semester archival
teach archive 2025-fall
```

---

## Version History

### v3.0 (Current)

**Major Features:**
- Health check system (`teach doctor`)
- Automated backup system with retention
- Enhanced status display with deployment info
- Scholar template selection
- Git integration improvements

**Migration:** See [v2 → v3 Migration Guide](../guides/TEACHING-V3-MIGRATION-GUIDE.md)

### v2.x (Legacy)

Legacy documentation available in the **Legacy (v2.x)** section.

---

## Getting Help

### Built-in Help

```bash
# Main help
teach help

# Command-specific help
teach analyze help
teach templates help
teach plan help
```

### Documentation

- **Tutorials** - Step-by-step learning paths
- **Guides** - Comprehensive feature documentation
- **Reference** - Quick lookup and command reference
- **Troubleshooting** - Common issues and solutions

### Support

- **GitHub Issues** - [Report bugs or request features](https://github.com/Data-Wise/flow-cli/issues)
- **Discussions** - [Ask questions and share tips](https://github.com/Data-Wise/flow-cli/discussions)

---

## Next Steps

### For Beginners

1. Read the **[Quick Start Guide](../tutorials/14-teach-dispatcher.md)**
2. Initialize your first course with **[teach init](../commands/teach-init.md)**
3. Follow the **[Complete v3.0 Workflow](../guides/TEACHING-WORKFLOW-V3-GUIDE.md)**

### For Intermediate Users

1. Explore **[Features](#-features)** to enhance your workflow
2. Set up **[Scholar Integration](../tutorials/scholar-enhancement/index.md)** for AI assistance
3. Learn **[Course Planning Best Practices](../guides/COURSE-PLANNING-BEST-PRACTICES.md)**

### For Advanced Users

1. Review **[System Architecture](../guides/TEACHING-SYSTEM-ARCHITECTURE.md)**
2. Customize templates and prompts
3. Contribute to the project on **[GitHub](https://github.com/Data-Wise/flow-cli)**

---

**Last Updated:** 2026-01-29
**Version:** v5.23.0
