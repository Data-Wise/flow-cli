# Website Design Guide (MkDocs)

> **TL;DR:** Minimalist, clean documentation sites with ADHD-friendly features. Material theme, dark mode, and clear visual hierarchy.

**Last Updated:** 2025-12-19
**Based on:** zsh-configuration MkDocs site

---

## Design Philosophy

### Core Principles

1. **Minimalist over flashy** - Clean, professional look
2. **Content-first** - No distracting animations or gradients
3. **ADHD-friendly** - Clear hierarchy, scannable sections, visual cues
4. **Dark mode by default** - Respect system preferences
5. **Mobile-responsive** - Works on all devices

### What We DON'T Do

❌ Hero banners with gradients
❌ Excessive animations
❌ Badge soup at the top
❌ Custom fonts beyond Material defaults
❌ Complex CSS overrides

### What We DO

✅ Clean indigo theme
✅ System-respecting dark/light mode
✅ Admonitions for key info (tip, warning, info)
✅ Code copy buttons
✅ Clear navigation tabs
✅ Searchable content

---

## Standard Configuration

### Minimal `mkdocs.yml`

```yaml
site_name: Project Name
site_description: One-line description
site_author: DT
site_url: https://data-wise.github.io/project-name

repo_name: project-name
repo_url: https://github.com/data-wise/project-name
edit_uri: edit/main/docs/

theme:
  name: material
  palette:
    # Light mode
    - media: "(prefers-color-scheme: light)"
      scheme: default
      primary: indigo
      accent: indigo
      toggle:
        icon: material/brightness-7
        name: Switch to dark mode
    # Dark mode
    - media: "(prefers-color-scheme: dark)"
      scheme: slate
      primary: indigo
      accent: indigo
      toggle:
        icon: material/brightness-4
        name: Switch to light mode
  features:
    - navigation.instant
    - navigation.tracking
    - navigation.tabs
    - navigation.sections
    - navigation.expand
    - navigation.top
    - search.suggest
    - search.highlight
    - content.code.copy
    - content.action.edit

plugins:
  - search

markdown_extensions:
  - admonition
  - pymdownx.details
  - pymdownx.superfences
  - pymdownx.highlight:
      anchor_linenums: true
  - pymdownx.inlinehilite
  - pymdownx.snippets
  - pymdownx.tabbed:
      alternate_style: true
  - tables
  - attr_list
  - md_in_html
  - toc:
      permalink: true

extra:
  social:
    - icon: fontawesome/brands/github
      link: https://github.com/data-wise/project-name

extra_css:
  - stylesheets/extra.css
```

---

## Custom Styling (Optional)

### Modern ADHD-Friendly CSS

**File:** `docs/stylesheets/extra.css`

**Design Philosophy:**
- Modern depth with subtle shadows
- Smooth transitions for better UX
- Enhanced interactivity feedback
- Still minimalist (no gradients or flashy effects)
- ADHD-friendly visual hierarchy

**Standard Template:**

```css
/* Modern ADHD-Friendly Design */

/* Code blocks with subtle shadow */
.md-typeset pre {
  border-radius: 12px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  border: 1px solid rgba(var(--md-primary-fg-color--light), 0.1);
}

.md-typeset code {
  border-radius: 6px;
  padding: 0.15em 0.4em;
}

/* Tables with hover effect */
.md-typeset table:not([class]) {
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.06);
}

.md-typeset table:not([class]) tbody tr:hover {
  background-color: rgba(var(--md-primary-fg-color--light), 0.03);
  transition: background-color 0.2s ease;
}

/* Smooth nav links */
.md-nav__link {
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1);
  border-radius: 6px;
  padding: 0.4em 0.8em;
}

.md-nav__link:hover {
  transform: translateX(4px);
  background-color: rgba(var(--md-primary-fg-color--light), 0.05);
}

/* Active nav indicator */
.md-nav__link--active {
  font-weight: 600;
  background-color: rgba(var(--md-primary-fg-color--light), 0.08);
}

/* Enhanced admonitions */
.md-typeset .admonition {
  border-radius: 12px;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.06);
  border-left-width: 4px;
}

/* Smooth scrolling */
html {
  scroll-behavior: smooth;
  scroll-padding-top: 5rem;
}

/* Modern buttons */
.md-button {
  border-radius: 10px !important;
  transition: all 0.25s cubic-bezier(0.4, 0, 0.2, 1) !important;
  box-shadow: 0 2px 4px rgba(0, 0, 0, 0.08) !important;
}

.md-button:hover {
  transform: translateY(-2px) !important;
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.12) !important;
}

/* Headers with borders */
.md-typeset h2 {
  border-bottom: 2px solid rgba(var(--md-primary-fg-color--light), 0.1);
  padding-bottom: 0.4em;
  margin-top: 1.8em;
}

/* Code copy button */
.md-clipboard {
  transition: all 0.2s ease;
  border-radius: 6px;
}

.md-clipboard:hover {
  transform: scale(1.1);
}

/* Mobile responsive */
@media (max-width: 768px) {
  .md-typeset {
    font-size: 0.95rem;
  }
  .md-typeset code {
    font-size: 0.85rem;
  }
}
```

**Key Features:**
- **Border radius:** 12px for blocks, 6-10px for smaller elements
- **Shadows:** Subtle depth (0 2px 8px, max 0.08 opacity)
- **Transitions:** Cubic-bezier easing (0.25s duration)
- **Hover effects:** Small transforms (2-4px max movement)
- **Colors:** Use CSS variables for theme compatibility
- **Mobile:** Responsive font sizing

**What to AVOID:**
- ❌ Gradients or complex backgrounds
- ❌ Large shadows (>12px blur, >0.15 opacity)
- ❌ Fast animations (<0.15s duration)
- ❌ Large transforms (>5px movement)
- ❌ Custom fonts or colors
- ❌ Complex animations or keyframes

**Creating the file:**

```bash
mkdir -p docs/stylesheets
# Copy template above to docs/stylesheets/extra.css
```

**When to use custom CSS:**
- Want modern depth (shadows) without being flashy
- Need enhanced interactivity feedback
- ADHD-friendly visual improvements
- Better mobile experience

**When to skip custom CSS:**
- Material theme is sufficient
- Want absolute minimal design
- No specific accessibility needs

---

## Navigation Structure

### Recommended Hierarchy

```yaml
nav:
  - Home: index.md
  - Getting Started:
    - Quick Start: getting-started/quick-start.md
    - Installation: getting-started/installation.md
  - User Guide:
    - Main Reference: user/reference.md
    - Tutorials: user/tutorials.md
    - FAQ: user/faq.md
  - Development:
    - Guidelines: dev/guidelines.md
    - Contributing: dev/contributing.md
  - Reference:
    - Complete Index: reference/index.md
```

### Rules

1. **Max 4-5 top-level sections** - Prevents cognitive overload
2. **Max 3 levels deep** - Keep it shallow
3. **5-8 items per section** - Scannable lists
4. **Descriptive names** - "Getting Started" not "Setup"

---

## Home Page Template

### Structure

```markdown
# Project Name

**One-line tagline** - What this project does in 8-12 words.

A brief description (2-3 sentences) explaining the problem and solution.

---

## ⚡ Quick Stats

- **Metric 1:** Value
- **Metric 2:** Value
- **Last updated:** Date

---

## 🚀 Quick Start

### 1. First Step
Brief explanation with code:
\`\`\`bash
command here
\`\`\`

### 2. Second Step
Brief explanation with code:
\`\`\`bash
another command
\`\`\`

---

## 📚 Documentation

!!! tip "Start Here"
    **New to this project?** Read [Guide Name](link) first!

### Core Guides
- **[Guide 1](link)** - Description
- **[Guide 2](link)** - Description

### Specialized Guides
- **[Guide 3](link)** - Description

---

## 🎯 Design Philosophy

Brief explanation of approach/principles.

---

**Last updated:** Date
**Maintainer:** Name
**Repository:** [GitHub](link)
```

### Key Elements

1. **One-line tagline** at top - Immediate clarity
2. **Quick stats** - Scannable metrics
3. **Quick Start** - Actionable steps with code
4. **Clear sections** - Easy navigation
5. **Admonitions** - Highlight key info

---

## ADHD-Friendly Features

### 1. Visual Hierarchy with Emojis

Use sparingly in headers for quick scanning:

```markdown
## ⚡ Quick Start
## 📚 Documentation
## 🎯 Key Concepts
## 🚀 Deployment
## 🛠️ Troubleshooting
```

**Rule:** Max 1 emoji per major section. Use consistently across pages.

### 2. Admonitions for Key Info

Draw attention to important information:

```markdown
!!! tip "Start Here"
    **New users?** Read this guide first!

!!! warning "Breaking Change"
    Version 2.0 removes deprecated features.

!!! info "For Existing Users"
    Migration guide available here.
```

**Types to use:**
- `tip` - Helpful shortcuts, recommendations
- `warning` - Breaking changes, important notices
- `info` - Additional context, FYI
- `note` - General information

**Don't use:** `danger`, `bug`, `example` - Keep it simple.

### 3. Scannable Lists

```markdown
## What Was Removed

**Categories eliminated:**

| Category | Count | Replacement |
|----------|-------|-------------|
| Item 1 | 10 | Use X instead |
| Item 2 | 5 | Use Y instead |
```

**Use tables for:**
- Comparisons (before/after)
- Options (old → new)
- Reference data (command → description)

### 4. TL;DR Sections

Add at top of long pages:

```markdown
> **TL;DR:** One-sentence summary of entire page.

## Full Content Below
```

### 5. Code Examples First

```markdown
## Quick Start

**Try it now:**
\`\`\`bash
command here
\`\`\`

**Explanation:** What this does and why.
```

Lead with action, explain after.

---

## Content Writing Style

### Tone

- **Conversational** - "Let's start" not "One must commence"
- **Direct** - "Use this" not "It is recommended that"
- **Concise** - 2-3 sentences per paragraph max
- **Active voice** - "Click the button" not "The button should be clicked"

### Formatting

1. **Bold for emphasis** - `**important term**`
2. **Inline code for commands** - `` `command` ``
3. **Code blocks for examples** - ````bash ... ````
4. **Lists for steps** - Numbered or bulleted
5. **Tables for comparisons** - Old vs New, Option vs Description

### Avoid

- Long paragraphs (>4 sentences)
- Passive voice
- Jargon without explanation
- Walls of code without context

---

## Common Page Patterns

### Quick Start Page

```markdown
# Quick Start

Get running in 5 minutes.

## Step 1: Install
\`\`\`bash
command
\`\`\`

## Step 2: Configure
\`\`\`bash
command
\`\`\`

## Step 3: Run
\`\`\`bash
command
\`\`\`

## What's Next?
- [Full Guide](link)
- [Tutorials](link)
```

### Reference Page

```markdown
# Command Reference

All commands organized by category.

## Category 1

| Command | Description | Example |
|---------|-------------|---------|
| `cmd1` | What it does | `cmd1 arg` |
| `cmd2` | What it does | `cmd2 arg` |

## Category 2

...
```

### Migration Guide

```markdown
# Migration Guide

Moving from old to new.

## What Changed

!!! warning "Breaking Changes"
    List of breaking changes

## Migration Steps

### Step 1: Update X
\`\`\`bash
command
\`\`\`

### Step 2: Replace Y

| Old | New |
|-----|-----|
| `old-cmd` | `new-cmd` |
```

---

## Color Scheme

### Standard: Indigo

- **Primary:** Indigo (`#4F46E5`)
- **Accent:** Indigo
- **Why:** Professional, calm, not distracting

### When to Customize

Only customize if project has brand colors. Otherwise, stick with indigo.

**Example (if needed):**
```yaml
theme:
  palette:
    - scheme: default
      primary: custom-color
      accent: custom-color
```

---

## Deployment

### GitHub Actions Workflow

Create `.github/workflows/deploy-docs.yml`:

```yaml
name: Deploy Docs
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: 3.x
      - run: pip install mkdocs-material
      - run: mkdocs gh-deploy --force
```

Push to main → Docs automatically deploy to `https://username.github.io/repo-name/`

---

## Checklist

### Before Launch

- [ ] Home page has clear tagline
- [ ] Quick Start shows working example
- [ ] All internal links work
- [ ] Code blocks have copy buttons
- [ ] Dark mode works correctly
- [ ] Mobile responsive (test on phone)
- [ ] Search finds key terms
- [ ] GitHub link in header works

### ADHD-Friendly Check

- [ ] Emojis in major section headers
- [ ] Key info in admonitions (tip/warning/info)
- [ ] Tables for comparisons
- [ ] Code examples before explanations
- [ ] No paragraphs >4 sentences
- [ ] TL;DR on long pages

---

## Examples

### Good Home Page

```markdown
# ZSH Configuration

**Minimalist ZSH workflow tools with smart dispatchers**

Features 28 essential aliases, 6 smart dispatchers, and 226+ git aliases.

---

## ⚡ Quick Stats

- **Custom aliases:** 28 (down from 179)
- **Reduction:** 84%
- **Last update:** 2025-12-19

---

## 🚀 Quick Start

\`\`\`bash
rload    # Load package
rtest    # Run tests
\`\`\`

!!! tip "Start Here"
    Read [Alias Reference](link) first!
```

### Bad Home Page

```markdown
# Introduction to the ZSH Configuration Management System

Welcome to the comprehensive documentation portal for our advanced shell configuration...

[Long paragraph about history and philosophy without actionable content]
```

---

## Advanced (Optional)

### Mermaid Diagrams

Only if truly needed:

```yaml
markdown_extensions:
  - pymdownx.superfences:
      custom_fences:
        - name: mermaid
          class: mermaid
```

### Tabs

For multiple code examples:

```yaml
markdown_extensions:
  - pymdownx.tabbed:
      alternate_style: true
```

Usage:
````markdown
=== "macOS"
    ```bash
    brew install tool
    ```

=== "Linux"
    ```bash
    apt install tool
    ```
````

---

## Anti-Patterns

### ❌ Don't Do This

1. **Badge soup** - 10+ badges at top of README
2. **Gradient heroes** - Flashy backgrounds or complex gradients
3. **Excessive animations** - Large movements (>5px), fast durations (<150ms)
4. **Heavy shadows** - Large blur (>12px), high opacity (>0.15)
5. **Walls of text** - Paragraphs >4 sentences
6. **Unclear navigation** - >5 top-level sections
7. **Missing quick start** - Just concepts, no code

### ✅ Do This Instead

1. **2-3 key badges** - Version, CI, license only
2. **Clean headers** - Simple text, no gradients
3. **Modern depth** - Subtle shadows (0 2px 8px, 0.08 opacity max)
4. **Smooth transitions** - Cubic-bezier easing, 200-300ms duration
5. **Small transforms** - 2-4px movement on hover
6. **Scannable lists** - Bullet points, tables with hover effects
7. **Clear hierarchy** - 4-5 top sections, 3 levels max
8. **Code first** - Examples before theory

**Modern vs Flashy:**

| Modern (✅) | Flashy (❌) |
|-------------|-------------|
| `box-shadow: 0 2px 8px rgba(0,0,0,0.08)` | `box-shadow: 0 10px 30px rgba(0,0,0,0.3)` |
| `transform: translateY(-2px)` | `transform: scale(1.2) rotate(5deg)` |
| `transition: 0.25s cubic-bezier(...)` | `transition: 0.1s linear` |
| `border-radius: 12px` | `border-radius: 50%` (unless circles) |
| No gradients | `background: linear-gradient(...)` |

---

## Maintenance

### Updating Content

1. Edit markdown in `docs/`
2. Test locally: `mkdocs serve`
3. Commit and push
4. GitHub Actions deploys automatically

### Keeping Fresh

- **Update "Last updated" dates** - On major changes
- **Fix broken links** - Run `mkdocs build` to check
- **Review quarterly** - Remove stale content
- **User feedback** - Add FAQ based on questions

---

## Quick Reference

### File Structure

```
project/
├── mkdocs.yml           # Configuration
├── docs/
│   ├── index.md         # Home page
│   ├── getting-started/
│   │   ├── quick-start.md
│   │   └── installation.md
│   ├── user/
│   │   └── reference.md
│   └── reference/
│       └── index.md
└── .github/workflows/
    └── deploy-docs.yml  # Auto-deploy
```

### Commands

```bash
mkdocs serve           # Preview at localhost:8000
mkdocs build           # Build to site/
mkdocs gh-deploy       # Deploy to GitHub Pages
```

### Common Fixes

**Broken links:**
```bash
mkdocs build 2>&1 | grep WARNING
```

**Port in use:**
```bash
lsof -ti:8000 | xargs kill -9
```

---

## Resources

- **Material Theme:** https://squidfunk.github.io/mkdocs-material/
- **Markdown Guide:** https://www.markdownguide.org/
- **GitHub Pages:** https://pages.github.com/

---

**Created:** 2025-12-19
**Based on:** zsh-configuration MkDocs site
**Location:** `~/projects/dev-tools/zsh-configuration/standards/documentation/`
