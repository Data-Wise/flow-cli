# Project Detection User Guide

**Feature:** Automatic project type detection
**Status:** ✅ Available now
**Difficulty:** Beginner-friendly

---

## What is Project Detection?

Project detection automatically identifies what type of project you're working with by looking at files in your project directory. It can detect:

- 📦 **R Packages** - Projects with `DESCRIPTION` files
- 📄 **Quarto Projects** - Projects with `_quarto.yml` or `.qmd` files
- 🔌 **Quarto Extensions** - Quarto plugin projects
- 🔬 **Research Projects** - Projects with LaTeX, bibliographies
- 📁 **Generic Git Projects** - Any project with `.git`
- ❓ **Unknown** - Unrecognized project types

---

## Quick Start

### Using the API (JavaScript/Node.js)

```javascript
import { detectProjectType } from 'flow-cli/cli/lib/project-detector-bridge.js'

// Detect a single project
const type = await detectProjectType('/Users/dt/projects/r-packages/stable/rmediation')
console.log(`Project type: ${type}`) // "r-package"
```bash

### Using a CLI Tool (Coming Soon)

```bash
# Detect current directory
zsh-config detect

# Detect specific directory
zsh-config detect ~/projects/teaching/stat-440
```yaml

---

## Supported Project Types

### R Package (`r-package`)

**Detected when:**

- Project has a `DESCRIPTION` file
- DESCRIPTION contains `Package:` field

**Example:**

```text
my-r-package/
├── DESCRIPTION       ← Must have "Package: mypackage"
├── R/
│   └── functions.R
├── man/
└── NAMESPACE
```text

**Detection:**

```javascript
const type = await detectProjectType('/path/to/my-r-package')
// Returns: 'r-package'
```diff

---

### Quarto Project (`quarto`)

**Detected when project has ANY of:**

- `_quarto.yml` file
- `_quarto.yaml` file
- `index.qmd` file
- `README.qmd` file

**Example:**

```text
my-quarto-project/
├── _quarto.yml       ← Configuration file
├── index.qmd         ← Homepage
└── chapters/
    ├── chapter1.qmd
    └── chapter2.qmd
```text

**Detection:**

```javascript
const type = await detectProjectType('/path/to/my-quarto-project')
// Returns: 'quarto'
```diff

---

### Quarto Extension (`quarto-extension`)

**Detected when project has:**

- `_extension.yml` file OR
- `_extensions.yml` file

**Example:**

```text
my-quarto-extension/
├── _extension.yml    ← Extension config
└── shortcode.lua
```diff

**Note:** Quarto extensions are detected *before* regular Quarto projects, so a project with both `_extension.yml` and `_quarto.yml` will be identified as an extension.

---

### Research Project (`research`)

**Detected when project has ANY of:**

- `main.tex` (LaTeX main file)
- `manuscript.tex` (Manuscript file)
- `literature/` directory
- `references.bib` (Bibliography)

**Example:**

```text
my-research/
├── manuscript.tex
├── references.bib    ← Any of these triggers detection
├── figures/
└── literature/       ← Research papers directory
```text

**Detection:**

```javascript
const type = await detectProjectType('/path/to/my-research')
// Returns: 'research'
```yaml

---

### Generic Git Project (`generic`)

**Detected when:**

- Project has a `.git` directory
- Doesn't match any more specific type

**Example:**

```text
my-project/
├── .git/            ← Git repository
├── README.md
└── src/
    └── code.js
```text

**Detection:**

```javascript
const type = await detectProjectType('/path/to/my-project')
// Returns: 'generic'
```yaml

---

### Unknown (`unknown`)

**Returned when:**

- Project doesn't match any known type
- Path doesn't exist
- Permission denied

**Example:**

```javascript
const type1 = await detectProjectType('/nonexistent/path')
// Returns: 'unknown'

const type2 = await detectProjectType('/random/folder')
// Returns: 'unknown' (no .git, no markers)
```javascript

---

## Common Use Cases

### 1. Detect Current Working Directory

```javascript
import { detectProjectType } from 'flow-cli/cli/lib/project-detector-bridge.js'
import { cwd } from 'process'

const currentType = await detectProjectType(cwd())
console.log(`You're working in a ${currentType} project`)
```text

### 2. Detect Multiple Projects

```javascript
import { detectMultipleProjects } from 'flow-cli/cli/lib/project-detector-bridge.js'

const results = await detectMultipleProjects([
  '/Users/dt/projects/r-packages/stable/rmediation',
  '/Users/dt/projects/teaching/stat-440',
  '/Users/dt/projects/dev-tools/flow-cli'
])

// Results:
// {
//   '/Users/dt/projects/r-packages/stable/rmediation': 'r-package',
//   '/Users/dt/projects/teaching/stat-440': 'quarto',
//   '/Users/dt/projects/dev-tools/flow-cli': 'generic'
// }
```javascript

### 3. Filter Projects by Type

```javascript
import { detectMultipleProjects } from 'flow-cli/cli/lib/project-detector-bridge.js'
import { readdir } from 'fs/promises'
import { join } from 'path'

// Find all R packages in a directory
const basePath = '/Users/dt/projects/r-packages/stable'
const entries = await readdir(basePath, { withFileTypes: true })
const dirs = entries.filter(e => e.isDirectory()).map(e => join(basePath, e.name))

const types = await detectMultipleProjects(dirs)

// Filter for R packages only
const rPackages = Object.entries(types)
  .filter(([path, type]) => type === 'r-package')
  .map(([path, type]) => path)

console.log(`Found ${rPackages.length} R packages`)
```javascript

### 4. Check if Type is Supported

```javascript
import { isTypeSupported, getSupportedTypes } from 'flow-cli/cli/lib/project-detector-bridge.js'

// Check specific type
if (isTypeSupported('r-package')) {
  console.log('R packages are supported')
}

// List all supported types
const types = getSupportedTypes()
console.log('Supported types:', types)
// ['r-package', 'quarto', 'quarto-extension', 'research', 'generic', 'unknown']
```javascript

---

## Examples with Real Projects

### Example 1: Detect R Package

```javascript
// Project: rmediation (R package for mediation analysis)
const type = await detectProjectType('/Users/dt/projects/r-packages/stable/rmediation')

console.log(type) // 'r-package'

// Why? Has DESCRIPTION file with:
// Package: rmediation
// Title: Parametric and Nonparametric Mediation Analysis
```javascript

### Example 2: Detect Quarto Course

```javascript
// Project: STAT 440 (Regression Analysis course)
const type = await detectProjectType('/Users/dt/projects/teaching/stat-440')

console.log(type) // 'quarto'

// Why? Has _quarto.yml:
// project:
//   type: website
```text

### Example 3: Scan All Teaching Projects

```javascript
import { detectMultipleProjects } from 'flow-cli/cli/lib/project-detector-bridge.js'

const teachingProjects = [
  '/Users/dt/projects/teaching/stat-440', // Regression
  '/Users/dt/projects/teaching/causal-inference', // Causal inference
  '/Users/dt/projects/teaching/S440_regression_Fall_2024' // Archive
]

const results = await detectMultipleProjects(teachingProjects)

// Results:
// {
//   '.../stat-440': 'quarto',
//   '.../causal-inference': 'quarto',
//   '.../S440_regression_Fall_2024': 'quarto'
// }

// All are Quarto projects!
```bash

---

## Troubleshooting

### Problem: Returns `'unknown'` for valid project

**Cause:** Project doesn't have the expected marker files

**Solution:** Check for marker files:

```bash
# R package needs DESCRIPTION with Package: field
cd /path/to/project
grep "^Package:" DESCRIPTION

# Quarto needs _quarto.yml or .qmd files
ls -la _quarto.yml *.qmd

# Research needs LaTeX or bibliography
ls -la *.tex references.bib literature/

# Git project needs .git directory
ls -la .git
```bash

If markers exist but detection still fails, check file permissions:

```bash
chmod +r DESCRIPTION _quarto.yml  # Make files readable
```bash

---

### Problem: "Permission denied" errors

**Cause:** Node.js process can't read project directory

**Solution:** Ensure read permissions:

```bash
# Check permissions
ls -la /path/to/project

# Fix permissions
chmod +r /path/to/project
chmod +rx /path/to/project  # Also need execute for directories
```javascript

---

### Problem: Detection is slow

**Cause:** Detecting many projects sequentially

**Solution:** Use batch detection:

```javascript
// ❌ Slow: Sequential
for (const path of allPaths) {
  const type = await detectProjectType(path) // Waits for each
}

// ✅ Fast: Parallel batch
const types = await detectMultipleProjects(allPaths) // All at once
```diff

**Performance:**

- Sequential (10 projects): ~200-300ms
- Parallel (10 projects): ~50-100ms
- **3x faster with batch detection!**

---

### Problem: Need to detect custom project types

**Status:** Not yet supported (coming in Phase 2)

**Workaround:** Use generic detection and add your own logic:

```javascript
const type = await detectProjectType('/path/to/project')

// Add custom logic
if (type === 'generic') {
  // Check for custom markers
  if (existsSync(join(projectPath, 'cargo.toml'))) {
    return 'rust'
  }
  if (existsSync(join(projectPath, 'go.mod'))) {
    return 'go'
  }
}
```diff

---

## Tips & Best Practices

### ✅ Do

- **Use batch detection** for multiple projects (faster)
- **Handle `'unknown'` type** gracefully in your application
- **Use absolute paths** for reliability
- **Check `isTypeSupported()`** before using type in logic

### ❌ Don't

- **Don't detect sequentially** when you have multiple projects
- **Don't throw errors** on `'unknown'` type (it's expected)
- **Don't use relative paths** (may give unexpected results)
- **Don't assume types** - always call the API

---

## API Quick Reference

```javascript
// Import functions
import {
  detectProjectType,
  detectMultipleProjects,
  getSupportedTypes,
  isTypeSupported
} from 'flow-cli/cli/lib/project-detector-bridge.js'

// Single detection
const type = await detectProjectType('/path/to/project')

// Batch detection (parallel)
const types = await detectMultipleProjects(['/path1', '/path2'])

// Get all supported types
const allTypes = getSupportedTypes()

// Check if type is supported
if (isTypeSupported('r-package')) {
  /* ... */
}
```yaml

---

## Real-World Examples

### Build a Project Dashboard

```javascript
import { detectMultipleProjects } from 'flow-cli/cli/lib/project-detector-bridge.js'
import { readdir } from 'fs/promises'
import { join } from 'path'

async function buildDashboard(baseDir) {
  // Scan all subdirectories
  const entries = await readdir(baseDir, { withFileTypes: true })
  const dirs = entries.filter(e => e.isDirectory()).map(e => join(baseDir, e.name))

  // Detect all types in parallel
  const types = await detectMultipleProjects(dirs)

  // Group by type
  const grouped = {}
  for (const [path, type] of Object.entries(types)) {
    if (!grouped[type]) grouped[type] = []
    grouped[type].push({
      name: path.split('/').pop(),
      path: path
    })
  }

  return grouped
}

// Usage
const dashboard = await buildDashboard('/Users/dt/projects/r-packages/stable')

console.log(`R Packages: ${dashboard['r-package']?.length || 0}`)
console.log(`Quarto Projects: ${dashboard['quarto']?.length || 0}`)
```javascript

### Conditional Workflow Based on Type

```javascript
import { detectProjectType } from 'flow-cli/cli/lib/project-detector-bridge.js'

async function runBuild(projectPath) {
  const type = await detectProjectType(projectPath)

  switch (type) {
    case 'r-package':
      console.log('Running R CMD build...')
      // R package build logic
      break

    case 'quarto':
      console.log('Running quarto render...')
      // Quarto render logic
      break

    case 'research':
      console.log('Compiling LaTeX...')
      // LaTeX compilation logic
      break

    default:
      console.log('Generic build process...')
    // Default build logic
  }
}
```yaml

---

## What's Next?

### Coming in Phase 2 (Week 2-3)

- [ ] **CLI tool** - `zsh-config detect` command
- [ ] **Project scanner** - Recursive directory scanning
- [ ] **Caching** - Faster repeated detections
- [ ] **TypeScript definitions** - Better IDE support

### Coming in Phase 3 (Month 2+)

- [ ] **More project types** - Python, Node.js, Rust, Go
- [ ] **Custom types** - Plugin system for your own types
- [ ] **Watch mode** - Auto-detect on file changes
- [ ] **API server** - RESTful detection service

---

## Get Help

### Documentation

- [Dispatcher Reference](./DISPATCHER-REFERENCE.md) - All dispatchers
- [Contributing Guide](../contributing/CONTRIBUTING.md) - Development patterns

### Issues & Questions

- GitHub Issues: (coming soon)
- Email: dtofighi@gmail.com
- Or ask Claude Code: "How do I detect Quarto projects?"

---

## Summary

**Key Takeaways:**

1. **Automatic detection** - No manual configuration needed
2. **6 project types** - R, Quarto, research, git, and more
3. **Simple API** - Just call `detectProjectType(path)`
4. **Batch support** - Detect multiple projects in parallel
5. **Graceful errors** - Returns `'unknown'` instead of crashing
6. **Zero dependencies** - Works out of the box

**Quick Start:**

```javascript
import { detectProjectType } from 'flow-cli/cli/lib/project-detector-bridge.js'

const type = await detectProjectType('/path/to/project')
console.log(`Project type: ${type}`)
```

**Next Steps:**

1. Try detecting your own projects
2. Build a project scanner using batch detection
3. Integrate with your workflow tools
4. Share feedback for improvements!

---

**Last Updated:** 2025-12-20
**Version:** 0.1.0
**Difficulty:** ⭐ Beginner
