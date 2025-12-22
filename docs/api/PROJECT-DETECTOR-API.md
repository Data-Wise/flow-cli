# Project Detector API Documentation

**Module:** `cli/lib/project-detector-bridge.js`
**Version:** 0.1.0
**Type:** ES Module
**Purpose:** JavaScript bridge to vendored zsh-claude-workflow project detection functions

---

## Overview

The Project Detector API provides Node.js functions to detect project types from filesystem paths. It bridges to vendored shell scripts from [zsh-claude-workflow](https://github.com/Data-Wise/zsh-claude-workflow) to leverage battle-tested detection logic while providing a modern async/Promise-based JavaScript API.

**Supported Project Types:**
- R packages (`r-package`)
- Quarto projects (`quarto`)
- Quarto extensions (`quarto-extension`)
- Research projects (`research`)
- Generic git projects (`generic`)
- Unknown projects (`unknown`)

---

## Installation

```bash
# As part of flow-cli package
npm install flow-cli

# Or import directly (development)
import { detectProjectType } from './cli/lib/project-detector-bridge.js';
```

---

## API Reference

### detectProjectType(projectPath)

Detect the type of a single project.

**Parameters:**
- `projectPath` (string, required) - Absolute path to project directory

**Returns:** `Promise<string>`
- Resolves to project type: `'r-package'`, `'quarto'`, `'quarto-extension'`, `'research'`, `'generic'`, or `'unknown'`
- Never rejects - returns `'unknown'` on errors

**Examples:**

```javascript
import { detectProjectType } from 'flow-cli/cli/lib/project-detector-bridge.js';

// Detect R package
const type1 = await detectProjectType('/Users/dt/projects/r-packages/stable/rmediation');
console.log(type1); // 'r-package'

// Detect Quarto project
const type2 = await detectProjectType('/Users/dt/projects/teaching/stat-440');
console.log(type2); // 'quarto'

// Detect generic git project
const type3 = await detectProjectType('/Users/dt/projects/dev-tools/flow-cli');
console.log(type3); // 'generic'

// Handle invalid path gracefully
const type4 = await detectProjectType('/nonexistent/path');
console.log(type4); // 'unknown'
```

**Detection Logic:**

The function checks for specific files/patterns in this order:

1. **R Package** - Has `DESCRIPTION` file with `Package:` field
2. **Quarto Extension** - Has `_extension.yml` or `_extensions.yml`
3. **Quarto Project** - Has `_quarto.yml`, `_quarto.yaml`, `index.qmd`, or `README.qmd`
4. **Research Project** - Has `main.tex`, `manuscript.tex`, `literature/` dir, or `references.bib`
5. **Generic Git Project** - Has `.git` directory
6. **Unknown** - None of the above

**Error Handling:**

- **Invalid paths**: Returns `'unknown'` instead of throwing
- **Permission errors**: Logs warning, returns `'unknown'`
- **Shell execution errors**: Logs error message, returns `'unknown'`

This graceful degradation ensures applications remain functional even when specific projects can't be detected.

---

### detectMultipleProjects(projectPaths)

Detect types for multiple projects in parallel.

**Parameters:**
- `projectPaths` (string[], required) - Array of absolute paths to project directories

**Returns:** `Promise<Object>`
- Resolves to object mapping `path -> type`
- Example: `{ '/path/1': 'r-package', '/path/2': 'quarto' }`

**Examples:**

```javascript
import { detectMultipleProjects } from 'flow-cli/cli/lib/project-detector-bridge.js';

const results = await detectMultipleProjects([
  '/Users/dt/projects/r-packages/stable/rmediation',
  '/Users/dt/projects/teaching/stat-440',
  '/Users/dt/projects/dev-tools/flow-cli'
]);

console.log(results);
// {
//   '/Users/dt/projects/r-packages/stable/rmediation': 'r-package',
//   '/Users/dt/projects/teaching/stat-440': 'quarto',
//   '/Users/dt/projects/dev-tools/flow-cli': 'generic'
// }
```

**Performance:**

All detections run in parallel using `Promise.all()`, making batch operations significantly faster than sequential detection:

```javascript
// Sequential (slow)
for (const path of paths) {
  const type = await detectProjectType(path);  // Waits for each
}

// Parallel (fast) - built into detectMultipleProjects
const results = await detectMultipleProjects(paths);  // All at once
```

---

### getSupportedTypes()

Get list of all supported project types.

**Parameters:** None

**Returns:** `string[]`
- Array of supported type identifiers

**Example:**

```javascript
import { getSupportedTypes } from 'flow-cli/cli/lib/project-detector-bridge.js';

const types = getSupportedTypes();
console.log(types);
// ['r-package', 'quarto', 'quarto-extension', 'research', 'generic', 'unknown']
```

**Use Cases:**

```javascript
// Validate user input
function isValidType(userType) {
  return getSupportedTypes().includes(userType);
}

// Generate UI dropdown
const typeOptions = getSupportedTypes()
  .filter(t => t !== 'unknown')
  .map(type => ({ value: type, label: formatTypeLabel(type) }));
```

---

### isTypeSupported(type)

Check if a project type is supported.

**Parameters:**
- `type` (string, required) - Project type to check

**Returns:** `boolean`
- `true` if type is supported, `false` otherwise

**Examples:**

```javascript
import { isTypeSupported } from 'flow-cli/cli/lib/project-detector-bridge.js';

console.log(isTypeSupported('r-package'));     // true
console.log(isTypeSupported('quarto'));        // true
console.log(isTypeSupported('invalid-type'));  // false
```

**Use Cases:**

```javascript
// Input validation
if (!isTypeSupported(userType)) {
  throw new Error(`Unsupported project type: ${userType}`);
}

// Conditional logic
if (isTypeSupported(detectedType) && detectedType !== 'unknown') {
  // Handle known project type
}
```

---

## Type Mapping

The API normalizes shell script output to consistent naming:

| Shell Output | API Output | Description |
|--------------|------------|-------------|
| `rpkg` | `r-package` | R package with DESCRIPTION |
| `quarto` | `quarto` | Quarto project or document |
| `quarto-ext` | `quarto-extension` | Quarto extension |
| `research` | `research` | Research project (LaTeX, etc.) |
| `project` | `generic` | Generic git repository |
| `unknown` | `unknown` | Unrecognized project type |

This mapping provides:
- **Consistent naming** across language boundaries
- **API stability** independent of shell implementation
- **Better developer experience** with descriptive names

---

## Integration Examples

### Express.js API Endpoint

```javascript
import express from 'express';
import { detectProjectType, detectMultipleProjects } from 'flow-cli/cli/lib/project-detector-bridge.js';

const app = express();

// Single project detection
app.get('/api/projects/:projectId/type', async (req, res) => {
  const projectPath = getProjectPath(req.params.projectId);
  const type = await detectProjectType(projectPath);

  res.json({
    projectId: req.params.projectId,
    type: type,
    path: projectPath
  });
});

// Batch detection
app.post('/api/projects/detect', async (req, res) => {
  const { paths } = req.body;

  if (!Array.isArray(paths)) {
    return res.status(400).json({ error: 'paths must be an array' });
  }

  const results = await detectMultipleProjects(paths);

  res.json({
    count: paths.length,
    results: Object.entries(results).map(([path, type]) => ({
      path,
      type,
      name: path.split('/').pop()
    }))
  });
});
```

### CLI Tool

```javascript
#!/usr/bin/env node
import { detectProjectType } from 'flow-cli/cli/lib/project-detector-bridge.js';
import { resolve } from 'path';

const projectPath = resolve(process.argv[2] || '.');
const type = await detectProjectType(projectPath);

console.log(`Project type: ${type}`);
process.exit(type === 'unknown' ? 1 : 0);
```

Usage:
```bash
chmod +x detect-type.js
./detect-type.js ~/projects/r-packages/stable/rmediation
# Project type: r-package

./detect-type.js ~/projects/teaching/stat-440
# Project type: quarto
```

### Project Scanner

```javascript
import { detectMultipleProjects } from 'flow-cli/cli/lib/project-detector-bridge.js';
import { readdir } from 'fs/promises';
import { join } from 'path';

async function scanProjects(baseDir) {
  // Get all subdirectories
  const entries = await readdir(baseDir, { withFileTypes: true });
  const dirs = entries
    .filter(e => e.isDirectory())
    .map(e => join(baseDir, e.name));

  // Detect all types in parallel
  const types = await detectMultipleProjects(dirs);

  // Group by type
  const grouped = {};
  for (const [path, type] of Object.entries(types)) {
    if (!grouped[type]) grouped[type] = [];
    grouped[type].push(path);
  }

  return grouped;
}

// Usage
const projects = await scanProjects('/Users/dt/projects/r-packages/stable');
console.log(`Found ${projects['r-package']?.length || 0} R packages`);
```

---

## Technical Details

### Architecture

```
┌─────────────────────────────────────────┐
│  JavaScript Application                 │
│  (Node.js, Express, CLI, etc.)          │
└─────────────┬───────────────────────────┘
              │
              │ import { detectProjectType }
              │
┌─────────────▼───────────────────────────┐
│  project-detector-bridge.js             │
│  - detectProjectType()                  │
│  - detectMultipleProjects()             │
│  - Type mapping (rpkg → r-package)      │
│  - Error handling                       │
└─────────────┬───────────────────────────┘
              │
              │ execAsync() via child_process
              │
┌─────────────▼───────────────────────────┐
│  /bin/zsh Shell Environment             │
│  - source core.sh                       │
│  - source project-detector.sh           │
│  - Execute: get_project_type            │
└─────────────┬───────────────────────────┘
              │
              │ Filesystem checks
              │
┌─────────────▼───────────────────────────┐
│  Project Directory                      │
│  - DESCRIPTION (R package)              │
│  - _quarto.yml (Quarto)                 │
│  - .git (git repo)                      │
│  - etc.                                 │
└─────────────────────────────────────────┘
```

### Dependencies

**Runtime:**
- Node.js ≥18.0.0
- zsh shell (built-in on macOS)

**Vendored Code:**
- `cli/vendor/zsh-claude-workflow/project-detector.sh` (~200 lines)
- `cli/vendor/zsh-claude-workflow/core.sh` (~100 lines)

**Source:** [zsh-claude-workflow v1.5.0](https://github.com/Data-Wise/zsh-claude-workflow)

### Performance

**Benchmarks (M1 Mac):**
- Single detection: ~20-50ms
- Batch of 10 projects: ~100-200ms (parallel)
- Batch of 100 projects: ~800-1200ms (parallel)

**Optimization Tips:**
```javascript
// ✅ Good: Batch parallel detection
const types = await detectMultipleProjects(allPaths);

// ❌ Avoid: Sequential detection
for (const path of allPaths) {
  await detectProjectType(path);  // Slow!
}
```

### Error Messages

The API logs informative error messages to stderr:

```javascript
// Invalid path
Failed to detect project type for /nonexistent: Command failed: ...
zsh:cd:1: no such file or directory: /nonexistent

// Permission denied
Failed to detect project type for /restricted: Command failed: ...
zsh:cd:1: permission denied: /restricted
```

Applications receive `'unknown'` type and continue functioning. Check console for diagnostic information.

---

## Testing

### Test Suite

Run the comprehensive test suite:

```bash
cd cli
npm run test:detector
```

**Test Coverage:**
- ✅ getSupportedTypes() returns correct list
- ✅ isTypeSupported() validates types correctly
- ✅ Detects R packages (DESCRIPTION file)
- ✅ Detects Quarto projects (_quarto.yml)
- ✅ Detects generic git repos (.git)
- ✅ Parallel detection for multiple projects
- ✅ Graceful handling of invalid paths

**Example Test:**

```javascript
import { detectProjectType } from '../lib/project-detector-bridge.js';
import { strict as assert } from 'assert';

// Test R package detection
const rmediation = await detectProjectType(
  '/Users/dt/projects/r-packages/stable/rmediation'
);
assert.equal(rmediation, 'r-package');

// Test error handling
const invalid = await detectProjectType('/nonexistent');
assert.equal(invalid, 'unknown');
```

---

## Troubleshooting

### Common Issues

**Issue:** Returns `'unknown'` for valid projects

**Solution:** Check that the project has the expected marker files:
```bash
# R package needs DESCRIPTION with Package: field
grep "^Package:" DESCRIPTION

# Quarto needs _quarto.yml or .qmd files
ls -la _quarto.yml *.qmd

# Git repo needs .git directory
ls -la .git
```

**Issue:** Permission errors in logs

**Solution:** Ensure the Node.js process has read access to project directories:
```bash
chmod +r /path/to/project
```

**Issue:** `zsh: command not found: get_project_type`

**Solution:** This is an internal error. The vendored scripts should source correctly. Verify files exist:
```bash
ls -la cli/vendor/zsh-claude-workflow/
# Should show: core.sh, project-detector.sh, README.md
```

---

## Version History

### v0.1.0 (2025-12-20)

**Initial Release**
- ✅ Vendored project-detector.sh and core.sh from zsh-claude-workflow v1.5.0
- ✅ Implemented JavaScript bridge with 4 public functions
- ✅ Support for 6 project types (R, Quarto, research, generic, etc.)
- ✅ Comprehensive test suite (7 tests, 100% passing)
- ✅ Full API documentation

**Future Enhancements:**
- Additional project types (Python, Node.js, Rust)
- Caching for repeated detections
- Async event-based detection
- TypeScript type definitions

---

## License

Vendored code: MIT License (zsh-claude-workflow)
Bridge implementation: MIT License

See [cli/vendor/zsh-claude-workflow/README.md](../../cli/vendor/zsh-claude-workflow/README.md) for attribution details.

---

## Related Documentation

- [Architecture Integration](../../ARCHITECTURE-INTEGRATION.md) - Overall system architecture
- [Week 1 Progress Report](../../WEEK-1-PROGRESS-2025-12-20.md) - Implementation details
- [Vendor README](../../cli/vendor/zsh-claude-workflow/README.md) - Vendored code documentation

---

**Last Updated:** 2025-12-20
**Maintainer:** DT
**Status:** Production Ready ✅
