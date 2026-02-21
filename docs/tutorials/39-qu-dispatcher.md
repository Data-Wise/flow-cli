---
tags:
  - tutorial
  - dispatchers
  - quarto
---

# Tutorial: Quarto Publishing with qu

Render, preview, and publish Quarto documents without memorizing quarto CLI flags. The `qu` dispatcher provides a consistent shorthand for your entire Quarto workflow.

**Time:** 15 minutes | **Level:** Beginner-Intermediate | **Requires:** quarto CLI, flow-cli

## What You'll Learn

1. Smart default workflow (render + preview)
2. Live preview with auto-reload
3. Rendering to specific formats
4. Checking your Quarto installation
5. Creating new projects
6. Publishing to the web
7. Cleanup and commit workflows

---

## Step 1: Smart Default — `qu`

Running `qu` with no arguments is the daily driver command:

```zsh
qu
```

**What happens:**

1. `quarto render` runs first
2. If render succeeds, a preview server starts in the background
3. Your browser opens automatically at `http://localhost:4200`
4. If render fails, the preview step is skipped with an error message

**Tip:** Run `qu` after every meaningful edit. It is the fastest path from source to browser.

---

## Step 2: Preview

Start a live preview server independently, without re-rendering:

```zsh
qu preview     # or: qu p, qu serve
```

Starts `quarto preview` with auto-reload and opens the browser. The server watches for file changes.

---

## Step 3: Render to Specific Formats

Render without opening a preview:

```zsh
qu render      # or: qu r — render the entire project
```

For specific output formats:

```zsh
qu pdf         # quarto render --to pdf
qu html        # quarto render --to html
qu docx        # quarto render --to docx
```

Render a specific file:

```zsh
qu render slides.qmd
```

---

## Step 4: Check Installation

Verify that Quarto and its dependencies are correctly installed:

```zsh
qu check       # or: qu c
```

Runs `quarto check` and prints a diagnostic report showing available rendering engines (knitr, Jupyter) and flags missing dependencies.

**Tip:** Run `qu check` first when a render fails unexpectedly.

---

## Step 5: Create Projects

Scaffold new Quarto projects:

```zsh
qu new my-project        # or: qu n — default project
qu article my-report     # article project
qu present my-slides     # presentation project
```

---

## Step 6: Publish

Publish your rendered site to a hosting provider:

```zsh
qu publish               # Interactive (prompts for provider)
qu publish gh-pages      # GitHub Pages
qu publish quarto-pub    # Quarto Pub
qu publish netlify       # Netlify
```

Delegates directly to `quarto publish`. First-time use walks through authorization.

**Tip:** For teaching sites managed with `teach`, use `teach deploy` instead — it adds git integration, preflight checks, and rollback support.

---

## Step 7: Cleanup and Commit

**Clean build artifacts:**

```zsh
qu clean
```

Removes `_site/`, `*_cache/`, and `*_files/` directories.

**Render and commit in one step:**

```zsh
qu commit "Add chapter 3 exercises"
```

Renders, stages all changes with `git add -A`, and commits. Default message: "Update Quarto document".

---

## Quick Reference

| Command | Alias | What It Does |
|---------|-------|--------------|
| `qu` | — | Render + preview + open browser |
| `qu preview` | `qu p` | Live preview server |
| `qu render` | `qu r` | Render without preview |
| `qu pdf` | — | Render to PDF |
| `qu html` | — | Render to HTML |
| `qu docx` | — | Render to Word |
| `qu check` | `qu c` | Verify installation |
| `qu new <name>` | `qu n` | Create default project |
| `qu article <name>` | — | Create article project |
| `qu present <name>` | — | Create presentation project |
| `qu publish` | — | Publish to web host |
| `qu clean` | — | Remove build artifacts |
| `qu commit "msg"` | — | Render + git commit |

---

## FAQ

### What is Quarto?

Quarto is an open-source scientific and technical publishing system. It renders `.qmd` files (and `.Rmd`, `.ipynb`, `.md`) into HTML, PDF, Word, slides, websites, and books. It integrates with R (knitr), Python (Jupyter), and Julia.

### Does `qu` work with `.Rmd` files?

Yes. Quarto can render both `.qmd` and `.Rmd` files. All `qu` commands pass through to the `quarto` CLI, which handles both formats.

### What port does the preview server use?

Default: `http://localhost:4200`. If port 4200 is taken, Quarto increments and prints the actual URL.

### How do I stop the preview server?

The preview runs as a background job. Stop it with:

```zsh
kill %1              # Kill most recent background job
pkill -f "quarto preview"  # Kill by name
```

---

## Next Steps

- **[Quarto Documentation](https://quarto.org/docs/guide/)** — Full Quarto reference
- **[Tutorial 14: teach Dispatcher](14-teach-dispatcher.md)** — Uses Quarto for course sites with deploy/rollback
- **[MASTER-DISPATCHER-GUIDE](../reference/MASTER-DISPATCHER-GUIDE.md)** — Complete reference for all 15 dispatchers
