# QU Dispatcher Reference

> **Quarto publishing workflows with smart defaults and one-command preview**

**Location:** `lib/dispatchers/qu-dispatcher.zsh`

---

## Quick Start

```bash
qu                    # Render → preview → open browser
qu preview            # Live preview with hot reload
qu render             # Render document/project
qu publish            # Publish to web
```

---

## Usage

```bash
qu [command] [args]
```

### Key Insight

- `qu` with no arguments runs the smart default workflow
- Smart default: render → start preview server → open browser
- Graceful failure: skips preview if render fails
- ADHD-friendly: one command does everything

---

## Smart Default Workflow

Running `qu` with no arguments:

```bash
qu
```

**What happens:**

1. Renders current Quarto document
2. Starts preview server (`--no-browser`)
3. Auto-opens browser at http://localhost:4200
4. Skips preview if render fails

This is the 80% use case - see your work instantly with one command.

---

## Core Commands

| Command | Shortcut | Description |
|---------|----------|-------------|
| `qu` | - | Smart default: render → preview → open |
| `qu preview` | `qu p` | Start preview server & open browser |
| `qu render` | `qu r` | Render document/project |
| `qu check` | `qu c` | Check Quarto installation |
| `qu clean` | - | Remove _site, *_cache,*_files |
| `qu publish` | - | Publish to web |

### Examples

```bash
qu                    # Full workflow
qu preview            # Live preview only
qu render             # Just render
qu check              # Verify installation
qu clean              # Clean build artifacts
```

---

## Format-Specific Rendering

| Command | Description |
|---------|-------------|
| `qu pdf` | Render to PDF |
| `qu html` | Render to HTML |
| `qu docx` | Render to Word document |

### Examples

```bash
# Render to specific format
qu pdf                # Generate PDF
qu html               # Generate HTML
qu docx               # Generate Word doc

# Render specific file to format
qu pdf chapter1.qmd
```

---

## Project Creation

| Command | Description |
|---------|-------------|
| `qu new <name>` | Create new Quarto project |
| `qu article <name>` | Create article project |
| `qu present <name>` | Create presentation project |
| `qu serve` | Serve project (alias for preview) |

### Examples

```bash
# Create new project
qu new my-report

# Create article (for journals)
qu article my-paper

# Create presentation
qu present my-slides
```

---

## Combined Workflows

| Command | Description |
|---------|-------------|
| `qu commit` | Render and commit changes |

### Example

```bash
# Render and commit in one step
qu commit "Update analysis section"
```

**What happens:**
1. Runs `quarto render`
2. Stages all changes (`git add -A`)
3. Commits with your message

---

## Examples

### Daily Writing Workflow

```bash
# Start working
cd ~/manuscripts/my-paper
qu                    # Render and preview

# After edits, refresh
qu                    # Re-render and preview

# End of session
qu commit "Add results section"
```

### Multi-Format Output

```bash
# Render to multiple formats
qu html               # For web
qu pdf                # For submission
qu docx               # For collaborators
```

### Project Setup

```bash
# New research article
qu article collider-bias
cd collider-bias
qu                    # Preview template
```

### Publishing

```bash
# Publish to GitHub Pages
qu publish gh-pages

# Publish to Quarto Pub
qu publish quarto-pub

# Publish to Netlify
qu publish netlify
```

---

## Preview Server

The preview server provides live reload:

```bash
qu preview
```

**Features:**
- Auto-refresh on file changes
- Runs on http://localhost:4200
- Background process (`&`)
- Auto-opens browser

---

## Clean Build

Remove all build artifacts:

```bash
qu clean
```

**Removes:**
- `_site/` - Generated site
- `*_cache/` - Knitr/Jupyter caches
- `*_files/` - Supporting files

---

## Integration

### With G Dispatcher

Use git workflows with Quarto:

```bash
g feature start new-chapter
qu                    # Preview changes
g aa && g commit "feat: add new chapter"
g promote             # PR to dev
```

### With CC Dispatcher

Launch Claude for Quarto work:

```bash
cc                    # Claude in current dir
# Ask Claude about Quarto formatting, YAML, etc.
```

---

## Troubleshooting

### "quarto: command not found"

Install Quarto:

```bash
# macOS
brew install --cask quarto

# Or download from quarto.org
```

### Preview server won't start

Check if port is in use:

```bash
lsof -i :4200
# Kill existing process if needed
```

### Render fails

Check Quarto installation:

```bash
qu check
```

Common issues:
- Missing LaTeX for PDF (install tinytex: `quarto install tinytex`)
- Missing R packages (check YAML dependencies)
- Invalid YAML frontmatter

---

## See Also

- **Dispatcher:** [g](G-DISPATCHER-REFERENCE.md) - Git workflows for version control
- **Dispatcher:** [r](R-DISPATCHER-REFERENCE.md) - R package development integration
- **Dispatcher:** [cc](CC-DISPATCHER-REFERENCE.md) - Launch Claude for Quarto help
- **Reference:** [Dispatcher Reference](DISPATCHER-REFERENCE.md) - All dispatchers
- **External:** [Quarto Documentation](https://quarto.org/) - Official Quarto guide

---

**Last Updated:** 2026-01-07
**Version:** v4.8.0
**Status:** ✅ Production ready with smart defaults
