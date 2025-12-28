# Vendor Integration Quick Reference Card

## ZSH Workflow Integration Pattern

**Version:** 1.0 | **Date:** 2025-12-23 | **Print-friendly:** Yes

---

## 🎯 What is "Vendored Code"?

**Vendoring** = Copy external code directly into your repository instead of depending on external installations

```
❌ External Dependency:
User must install zsh-claude-workflow separately
flow-cli calls external commands
→ Fragile! Breaks if not installed

✅ Vendored Code:
Copy core functions into flow-cli/vendor/
flow-cli is self-contained
→ Reliable! Works everywhere npm works
```

---

## 📦 The Pattern

```
┌─────────────────────────────────────────────┐
│ APPLICATION LAYER                           │
│ (CLI tools, REST API, Desktop UI)          │
└──────────────────┬──────────────────────────┘
                   │ calls
┌──────────────────▼──────────────────────────┐
│ JAVASCRIPT BRIDGE                           │
│ cli/lib/project-detector-bridge.js          │
│ - detectProjectType(path)                   │
│ - detectMultipleProjects(paths)             │
└──────────────────┬──────────────────────────┘
                   │ executes via child_process
┌──────────────────▼──────────────────────────┐
│ VENDOR LAYER (Shell Scripts)                │
│ cli/vendor/zsh-claude-workflow/             │
│ ├── core.sh (~100 lines)                    │
│ └── project-detector.sh (~200 lines)        │
│                                              │
│ Functions:                                   │
│ - _is_r_package()                           │
│ - _is_quarto_project()                      │
│ - _detect_project_type()                    │
└──────────────────┬──────────────────────────┘
                   │ reads
┌──────────────────▼──────────────────────────┐
│ FILE SYSTEM                                  │
│ - DESCRIPTION files (R packages)            │
│ - _quarto.yml (Quarto projects)             │
│ - package.json (Node projects)              │
└─────────────────────────────────────────────┘
```

---

## ⚡ Quick Start

### 1. Update Vendored Scripts

```bash
# Copy from source repository
cp ~/projects/dev-tools/zsh-claude-workflow/lib/core.sh \
   cli/vendor/zsh-claude-workflow/

cp ~/projects/dev-tools/zsh-claude-workflow/lib/project-detector.sh \
   cli/vendor/zsh-claude-workflow/

# Attribution is automatic (see header comments)
```

### 2. Use the Bridge API

```javascript
import { detectProjectType } from './lib/project-detector-bridge.js'

// Single project
const type = await detectProjectType('/path/to/project')
// Returns: 'r-package', 'quarto', 'research', etc.

// Multiple projects (parallel detection)
const results = await detectMultipleProjects([
  '/path/to/project1',
  '/path/to/project2',
  '/path/to/project3'
])
// Returns: { '/path/to/project1': 'r-package', ... }
```

### 3. Check Supported Types

```javascript
import { getSupportedTypes, isTypeSupported } from './lib/project-detector-bridge.js'

const types = getSupportedTypes()
// ['r-package', 'quarto', 'quarto-extension', 'research', 'generic', 'unknown']

const supported = isTypeSupported('r-package')
// true
```

---

## 🔍 Detection Logic

### Detection Order (First Match Wins)

```
1. R Package
   ├─ Has DESCRIPTION file?
   └─ Package: field in DESCRIPTION?

2. Quarto Extension
   ├─ Has _extensions/ directory?
   └─ Has _extension.yml?

3. Quarto Project
   ├─ Has _quarto.yml?
   └─ Or has .qmd files?

4. Research Project
   ├─ In ~/projects/research/?
   └─ Has .STATUS file with research markers?

5. Generic Project
   ├─ Has .git directory?
   └─ Or recognizable structure?

6. Unknown
   └─ Default fallback
```

### Example Files Checked

```bash
# R Package
DESCRIPTION               # Must exist
R/                       # Optional but common
tests/                   # Optional

# Quarto
_quarto.yml              # Primary indicator
*.qmd files              # Alternative indicator
_extensions/             # For extensions

# Research
.STATUS                  # Common marker
manuscript/              # Common structure
analysis/
```

---

## 🎨 Clean Architecture Mapping

### Current (3-Layer)

```
Frontend (ZSH) → Backend (Node) → Vendor (Shell)
```

### Target (4-Layer with Hexagonal)

```
┌────────────────────────────────────────────┐
│ LAYER 4: FRAMEWORKS                        │
│ - ZSH Shell Commands                       │
│ - Vendor Scripts (project-detector.sh)     │
└──────────────┬─────────────────────────────┘
               │
┌──────────────▼─────────────────────────────┐
│ LAYER 3: ADAPTERS                          │
│ ┌────────────────────────────────────────┐ │
│ │ ProjectDetectorGateway                 │ │  ← Adapter
│ │ (implements IProjectDetector)          │ │
│ │                                         │ │
│ │ - Wraps project-detector-bridge.js     │ │
│ │ - Translates shell output → domain     │ │
│ └────────────────────────────────────────┘ │
└──────────────┬─────────────────────────────┘
               │
┌──────────────▼─────────────────────────────┐
│ LAYER 2: USE CASES                         │
│ - ScanProjectsUseCase                      │
│   (uses IProjectDetector port)             │
└──────────────┬─────────────────────────────┘
               │
┌──────────────▼─────────────────────────────┐
│ LAYER 1: DOMAIN                            │
│ - ProjectType (value object)               │
│ - IProjectDetector (interface/port)        │
└────────────────────────────────────────────┘
```

**Key Insight:** Vendor scripts are FRAMEWORK layer, accessed via ADAPTER

---

## 🛠️ Implementation Patterns

### Pattern 1: Simple Bridge (Current)

```javascript
// cli/lib/project-detector-bridge.js

import { execFile } from 'child_process'
import { promisify } from 'util'

const execFileAsync = promisify(execFile)

export async function detectProjectType(projectPath) {
  try {
    const { stdout } = await execFileAsync('bash', [
      './vendor/zsh-claude-workflow/project-detector.sh',
      'detect',
      projectPath
    ])

    return stdout.trim() || 'unknown'
  } catch (error) {
    console.error('Detection failed:', error)
    return 'unknown'
  }
}
```

**Pros:** Simple, direct
**Cons:** Mixes concerns, hard to test

### Pattern 2: Gateway Adapter (Target)

```javascript
// cli/adapters/gateways/ProjectDetectorGateway.js

import { detectProjectType } from '../../lib/project-detector-bridge.js'

export class ProjectDetectorGateway {
  /**
   * Detect project type (implements IProjectDetector port)
   * @param {string} projectPath
   * @returns {Promise<ProjectType>}
   */
  async detect(projectPath) {
    const typeString = await detectProjectType(projectPath)
    return new ProjectType(typeString) // Domain value object
  }

  /**
   * Batch detection with parallelization
   */
  async detectMultiple(projectPaths) {
    const results = await detectMultipleProjects(projectPaths)

    return Object.entries(results).reduce((acc, [path, typeStr]) => {
      acc[path] = new ProjectType(typeStr)
      return acc
    }, {})
  }
}
```

**Pros:** Clean separation, testable, follows ports & adapters
**Cons:** More files (worth it!)

---

## 🧪 Testing Strategy

### Unit Tests (Domain)

```javascript
// No vendor dependency
test('ProjectType validates values', () => {
  expect(() => new ProjectType('invalid')).toThrow()
  expect(new ProjectType('r-package').isRPackage()).toBe(true)
})
```

### Integration Tests (Adapter)

```javascript
// Tests real shell execution
test('ProjectDetectorGateway detects R packages', async () => {
  const gateway = new ProjectDetectorGateway()
  const type = await gateway.detect('/path/to/rmediation')

  expect(type.value).toBe('r-package')
})
```

### Mock for Use Cases

```javascript
// Mock the gateway, not shell scripts
class MockProjectDetector {
  async detect(path) {
    return new ProjectType('r-package') // Controlled output
  }
}

test('ScanProjectsUseCase handles detection', async () => {
  const useCase = new ScanProjectsUseCase(
    new MockProjectDetector() // ← Inject mock
  )

  const result = await useCase.execute({ basePath: '/test' })
  expect(result.projects.length).toBeGreaterThan(0)
})
```

---

## 📋 Maintenance Checklist

### When to Update Vendored Scripts

✅ Source scripts get bug fixes
✅ New project types added to source
✅ Performance improvements in source
✅ Breaking changes (requires bridge updates)

### Update Process

```bash
# 1. Check source for changes
cd ~/projects/dev-tools/zsh-claude-workflow
git log lib/project-detector.sh

# 2. Copy updated files
cp lib/core.sh ~/projects/dev-tools/flow-cli/cli/vendor/zsh-claude-workflow/
cp lib/project-detector.sh ~/projects/dev-tools/flow-cli/cli/vendor/zsh-claude-workflow/

# 3. Update attribution headers (if needed)
# Already in files - no action needed

# 4. Test bridge API
cd ~/projects/dev-tools/flow-cli
npm test -- project-detector-bridge.test.js

# 5. Commit with clear message
git add cli/vendor/
git commit -m "vendor: update project-detector scripts from zsh-claude-workflow@<hash>"
```

### Version Tracking

```bash
# Document source version in commit
git log --oneline -1 ~/projects/dev-tools/zsh-claude-workflow/lib/project-detector.sh
# Use that hash in commit message
```

---

## ⚠️ Common Pitfalls

### ❌ Modifying Vendored Scripts Directly

```bash
# DON'T edit vendored files directly
vim cli/vendor/zsh-claude-workflow/project-detector.sh  # ❌ Will be overwritten

# DO contribute fixes to source, then vendor
cd ~/projects/dev-tools/zsh-claude-workflow
vim lib/project-detector.sh  # ✅ Fix at source
# Then vendor the update
```

### ❌ Breaking the Adapter Interface

```javascript
// BAD: Use case depends on implementation details
class ScanProjectsUseCase {
  async execute() {
    const output = await execFile('bash', ...)  // ❌ Knows about shell
  }
}

// GOOD: Use case depends on port (interface)
class ScanProjectsUseCase {
  constructor(projectDetector) {  // ✅ Inject IProjectDetector
    this.detector = projectDetector
  }

  async execute() {
    const type = await this.detector.detect(path)  // ✅ Clean interface
  }
}
```

### ❌ Forgetting Attribution

```bash
# Vendored files MUST include attribution header
# Already present in files:

###############################################################################
# Vendored from: zsh-claude-workflow
# Source: https://github.com/Data-Wise/zsh-claude-workflow
# License: MIT
# Last Updated: 2025-12-20
# Original Author: Data-Wise
#
# This file is vendored (copied) into flow-cli to avoid external dependencies.
###############################################################################
```

---

## 🚀 Benefits of This Pattern

### ✅ Zero Dependencies

```json
// package.json stays clean
{
  "dependencies": {
    // No zsh-claude-workflow dependency!
  }
}
```

### ✅ One-Command Install

```bash
npm install flow-cli  # Everything included, works immediately
```

### ✅ Production Reliability

```
Battle-tested code → Vendor stable version → Ship with confidence
```

### ✅ Easy Testing

```javascript
// Mock the gateway, test use cases independently
const mockDetector = { detect: async () => new ProjectType('r-package') }
const useCase = new ScanProjectsUseCase(mockDetector)
```

### ✅ Future Flexibility

```javascript
// Later: Replace shell scripts with pure JS (no API change!)
class PureJSProjectDetector implements IProjectDetector {
  async detect(path) {
    // Pure Node.js implementation
  }
}

// Use cases don't need to change!
const useCase = new ScanProjectsUseCase(new PureJSProjectDetector())
```

---

## 📚 Related Patterns

| Pattern       | Purpose                     | Example                                      |
| ------------- | --------------------------- | -------------------------------------------- |
| **Vendoring** | Avoid external dependencies | Copy scripts into `vendor/`                  |
| **Adapter**   | Wrap external code          | `ProjectDetectorGateway` wraps shell scripts |
| **Bridge**    | Simple abstraction          | `project-detector-bridge.js`                 |
| **Gateway**   | Clean Architecture adapter  | Implements domain interface                  |
| **Port**      | Define contract             | `IProjectDetector` interface                 |

---

## 🎯 Decision Tree

**"Should I vendor this code?"**

```
Does it have stable API? ─NO─→ Don't vendor (too risky)
         │
        YES
         │
Is it battle-tested? ─NO─→ Don't vendor (wait for stability)
         │
        YES
         │
Can I attribute properly? ─NO─→ Don't vendor (license issue)
         │
        YES
         │
        ✅ VENDOR IT!
```

**"How do I integrate vendored code?"**

```
Simple CLI tool? → Direct bridge (current pattern)
         │
Part of larger system? → Gateway adapter (target pattern)
         │
Need to mock/test? → Gateway adapter (target pattern)
```

---

## 📖 Further Reading

- [VENDOR-INTEGRATION-ARCHITECTURE.md](VENDOR-INTEGRATION-ARCHITECTURE.md) - Full documentation
- [ARCHITECTURE-PATTERNS-ANALYSIS.md](ARCHITECTURE-PATTERNS-ANALYSIS.md) - Clean Architecture
- [API-DESIGN-REVIEW.md](API-DESIGN-REVIEW.md) - API patterns

---

**Generated:** 2025-12-23
**Part of:** Architecture Enhancement Plan (A→C Implementation)
**Purpose:** Quick reference for vendored code integration pattern
