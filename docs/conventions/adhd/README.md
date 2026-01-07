# ADHD-Friendly Documentation Templates

> **Purpose:** Standardized templates for creating accessible, scannable, and ADHD-friendly documentation.

---

## Quick Template Selection

**"Which template should I use?"**

```
What are you documenting?
│
├─ Getting someone running in < 5 minutes?
│  └─ Use: QUICK-START-TEMPLATE.md
│
├─ Teaching one feature step-by-step?
│  └─ Use: TUTORIAL-TEMPLATE.md
│
├─ Showing how to accomplish a real task?
│  └─ Use: WORKFLOW-TEMPLATE.md
│
├─ Explaining concepts in depth?
│  └─ Use: GETTING-STARTED-TEMPLATE.md
│
├─ Documenting a specific command?
│  └─ Use: HELP-PAGE-TEMPLATE.md
│
├─ Creating quick lookup reference?
│  └─ Use: REFCARD-TEMPLATE.md
│
└─ Creating visual demonstration?
   └─ Use: GIF-GUIDELINES.md
```

---

## Available Templates

| Template | Purpose | Length | Example |
|----------|---------|--------|---------|
| **[QUICK-START-TEMPLATE.md](QUICK-START-TEMPLATE.md)** | Get running fast | ~1 page | README files, project onboarding |
| **[GETTING-STARTED-TEMPLATE.md](GETTING-STARTED-TEMPLATE.md)** | Hands-on intro | 2-4 pages | First-time setup guides |
| **[TUTORIAL-TEMPLATE.md](TUTORIAL-TEMPLATE.md)** | Step-by-step learning | 5-15 pages | Feature tutorials |
| **[WORKFLOW-TEMPLATE.md](WORKFLOW-TEMPLATE.md)** | Real-world patterns | 2-3 pages | Common task workflows |
| **[HELP-PAGE-TEMPLATE.md](HELP-PAGE-TEMPLATE.md)** | Command documentation | 2-5 pages | Individual command docs |
| **[REFCARD-TEMPLATE.md](REFCARD-TEMPLATE.md)** | Quick lookup | 1 page | Command references |
| **[GIF-GUIDELINES.md](GIF-GUIDELINES.md)** | Visual content | 5-15 sec | Feature demonstrations |

---

## Decision Tree

### Is this for brand new users?

**Yes** → Use **QUICK-START-TEMPLATE.md**
- 30-second setup
- Common tasks table
- Minimal explanation

**No** → Continue...

### Is this step-by-step learning?

**Yes** → Use **TUTORIAL-TEMPLATE.md**
- Numbered steps
- Checkpoints after each step
- Practice exercises

**No** → Continue...

### Is this showing how to do a task?

**Yes** → Use **WORKFLOW-TEMPLATE.md**
- Scenario-based
- Multiple variations
- Troubleshooting section

**No** → Continue...

### Is this documenting a command?

**Yes** → Use **HELP-PAGE-TEMPLATE.md**
- Complete syntax reference
- All options documented
- Usage examples

**No** → Continue...

### Is this for quick lookup?

**Yes** → Use **REFCARD-TEMPLATE.md**
- One page, no scrolling
- Tables and boxes
- No explanations

**No** → Use **GETTING-STARTED-TEMPLATE.md** (conceptual guide)

---

## Template Comparison

### Content Type Matrix

|  | Quick Start | Getting Started | Tutorial | Workflow | Help Page | Refcard |
|--|:-----------:|:---------------:|:--------:|:--------:|:---------:|:-------:|
| **New users** | ✅ | ✅ | 🟡 | ❌ | ❌ | ❌ |
| **Learning** | 🟡 | ✅ | ✅ | 🟡 | ❌ | ❌ |
| **Task-focused** | ❌ | 🟡 | ❌ | ✅ | 🟡 | ❌ |
| **Reference** | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ |
| **Visual** | ❌ | 🟡 | ✅ | ✅ | 🟡 | ❌ |

Legend: ✅ Primary use | 🟡 Secondary use | ❌ Not suitable

---

## Usage Examples

### Example 1: New Command Added

**Scenario:** You added `pick` command to flow-cli

**Documents to create:**
1. **Help Page** (`docs/commands/pick.md`)
   - Use: HELP-PAGE-TEMPLATE.md
   - Complete command reference

2. **Tutorial** (`docs/tutorials/XX-project-picking.md`)
   - Use: TUTORIAL-TEMPLATE.md
   - Teach users how to use pick

3. **Refcard** (`docs/reference/PICK-QUICK-REFERENCE.md`)
   - Use: REFCARD-TEMPLATE.md
   - One-page quick lookup

4. **GIF** (`docs/assets/gifs/commands/pick-basic-usage.gif`)
   - Use: GIF-GUIDELINES.md
   - Visual demonstration

### Example 2: New Feature Workflow

**Scenario:** Documenting Git feature branch workflow

**Documents to create:**
1. **Workflow** (`docs/workflows/git-feature-workflow.md`)
   - Use: WORKFLOW-TEMPLATE.md
   - Show real-world usage

2. **Tutorial** (`docs/tutorials/XX-git-feature.md`)
   - Use: TUTORIAL-TEMPLATE.md
   - Step-by-step learning

3. **GIF** (`docs/assets/gifs/workflows/feature-branch.gif`)
   - Use: GIF-GUIDELINES.md
   - Visual workflow demo

### Example 3: New User Onboarding

**Scenario:** Help new users get started with flow-cli

**Documents to create:**
1. **Quick Start** (`docs/getting-started/quick-start.md`)
   - Use: QUICK-START-TEMPLATE.md
   - 5-minute setup

2. **Getting Started** (`docs/getting-started/first-steps.md`)
   - Use: GETTING-STARTED-TEMPLATE.md
   - Hands-on introduction

3. **Tutorial** (`docs/tutorials/01-first-session.md`)
   - Use: TUTORIAL-TEMPLATE.md
   - Complete first workflow

---

## Template Characteristics

### QUICK-START-TEMPLATE.md

**Key features:**
- TL;DR at top
- 30-second setup
- Common tasks table
- Where things are
- Current status

**When to use:**
- Project README files
- New contributor onboarding
- Plugin quick starts

**Length:** ~1 page (200-300 lines)

### GETTING-STARTED-TEMPLATE.md

**Key features:**
- Prerequisites with verification
- Hands-on testing
- Configuration setup
- Next steps

**When to use:**
- First-time installation
- Configuration guides
- Environment setup

**Length:** 2-4 pages (400-800 lines)

### TUTORIAL-TEMPLATE.md

**Key features:**
- Learning objectives
- Numbered steps
- Checkpoints
- Practice exercises
- Summary

**When to use:**
- Feature tutorials
- Step-by-step guides
- Learning paths

**Length:** 5-15 pages (1000-3000 lines)

### WORKFLOW-TEMPLATE.md

**Key features:**
- Scenario-based
- Multiple variations
- Common patterns
- Troubleshooting
- Best practices

**When to use:**
- Real-world tasks
- Common patterns
- Process documentation

**Length:** 2-3 pages (400-600 lines)

### HELP-PAGE-TEMPLATE.md

**Key features:**
- Complete syntax
- All options documented
- Usage examples
- Exit codes
- Related commands

**When to use:**
- Command documentation
- API reference
- Tool manuals

**Length:** 2-5 pages (400-1000 lines)

### REFCARD-TEMPLATE.md

**Key features:**
- One page, no scrolling
- Tables and boxes
- No explanations
- Most-used first
- Quick patterns

**When to use:**
- Command lookup
- Keyboard shortcuts
- Quick reference

**Length:** 1 page (≤ 40 lines of content)

### GIF-GUIDELINES.md

**Key features:**
- Visual demonstration
- 5-15 seconds
- Optimized file size
- Accessibility captions

**When to use:**
- Interactive features
- Complex workflows
- UI demonstrations

**Duration:** 5-15 seconds (≤ 2MB file size)

---

## ADHD-Friendly Design Principles

All templates follow these principles:

### 1. Visual Hierarchy

- **Clear headings** — H1 for title, H2 for sections
- **Consistent structure** — Same format across all docs
- **Icons and emojis** — Visual markers for quick scanning
- **Tables over prose** — Scannable data, not walls of text

### 2. Progressive Disclosure

- **Start simple** — Most common use case first
- **Build complexity** — Advanced features later
- **No gatekeeping** — Can skip to relevant section
- **Clear navigation** — Always know where you are

### 3. Immediate Feedback

- **Expected output** — Show what success looks like
- **Checkpoints** — Verify progress frequently
- **Error examples** — Show actual error messages
- **Visual indicators** — ✅/❌ for success/failure

### 4. Minimal Cognitive Load

- **Short paragraphs** — 2-3 sentences max
- **Code examples** — Show, don't just tell
- **Callouts** — Use `> **Note:**` for important info
- **Quick reference** — Cheat sheet at end

### 5. Completion Signals

- **Progress indicators** — Step X of Y
- **Checkboxes** — [x] for completed items
- **Next steps** — Clear path forward
- **Summary** — Recap what was learned

---

## File Naming Conventions

### Tutorials

**Format:** `XX-feature-name.md`

```
01-first-session.md
02-multiple-projects.md
10-cc-dispatcher.md
```

**Numbering:**
- 01-09: Core workflow (beginner)
- 10-19: Advanced features (intermediate)
- 20-29: Expert topics (advanced)

### Workflows

**Format:** `task-workflow.md`

```
git-feature-workflow.md
r-package-workflow.md
worktree-workflow.md
```

### Reference Cards

**Format:** `COMPONENT-REFERENCE.md` or `COMPONENT-QUICK-REFERENCE.md`

```
COMMAND-QUICK-REFERENCE.md
CC-DISPATCHER-REFERENCE.md
WORKFLOW-QUICK-REFERENCE.md
```

### GIFs

**Format:** `<feature>-<action>-<variant>.gif`

```
pick-basic-usage.gif
cc-dispatcher-opus-mode.gif
dash-interactive-tui.gif
```

---

## Quality Checklist

Before publishing documentation:

**Content:**
- [ ] Template fully applied
- [ ] All sections completed
- [ ] Examples tested and verified
- [ ] Code blocks have proper syntax highlighting
- [ ] Links tested (no 404s)

**ADHD-Friendly:**
- [ ] Clear visual hierarchy
- [ ] Short paragraphs (≤ 3 sentences)
- [ ] Tables used for scannable data
- [ ] Expected output shown
- [ ] Checkpoints provided
- [ ] Summary/quick reference at end

**Accessibility:**
- [ ] Alt text for images/GIFs
- [ ] Code examples have descriptions
- [ ] Headings properly nested (H1 → H2 → H3)
- [ ] No color-only indicators
- [ ] Links have descriptive text

**Navigation:**
- [ ] Related docs linked
- [ ] Next steps provided
- [ ] Breadcrumbs clear
- [ ] Search keywords optimized

---

## Template Updates

**When to update templates:**
- User feedback identifies pain points
- New ADHD-friendly patterns discovered
- Documentation standards evolve
- MkDocs Material theme updates

**Update process:**
1. Discuss changes in GitHub issue
2. Update template file
3. Update this README
4. Apply to 3-5 example docs
5. Gather feedback
6. Roll out to all docs

---

## Contributing

**Adding new templates:**
1. Identify gap in current templates
2. Create draft in `docs/conventions/adhd/`
3. Include complete example
4. Add to this README
5. Create PR for review

**Improving existing templates:**
1. Test changes on 2-3 real docs
2. Update template file
3. Update this README
4. Create PR with before/after examples

---

## Related Resources

- **MkDocs Material:** https://squidfunk.github.io/mkdocs-material/
- **ADHD-Friendly Design:** https://adhddesign.com/
- **Plain Language Guidelines:** https://www.plainlanguage.gov/
- **Documentation Style Guide:** `../../DOCUMENTATION-STYLE-GUIDE.md`

---

**Last Updated:** 2026-01-07
**Template Collection Version:** 1.0
**Total Templates:** 7
