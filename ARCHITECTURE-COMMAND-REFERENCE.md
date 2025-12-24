# Architecture Command Reference

**Purpose:** Quick reference for architectural patterns and commands used in flow-cli
**Created:** 2025-12-21
**Use:** Copy-paste when implementing similar patterns in future projects

---

## Table of Contents

1. [Quick Command Patterns](#quick-command-patterns)
2. [Architecture Documentation Commands](#architecture-documentation-commands)
3. [Implementation Patterns](#implementation-patterns)
4. [File Organization](#file-organization)
5. [Testing Patterns](#testing-patterns)

---

## Quick Command Patterns

### 1. Generate Architecture Documentation Sprint

**Command Pattern:**

```bash
# Read existing architecture → Generate comprehensive docs → Create ADRs → Add examples

# Step 1: Analyze current architecture
claude: "Analyze the codebase architecture and create a comprehensive architecture document"

# Step 2: Add TL;DR sections to all architecture docs
claude: "Add TL;DR sections (3-5 bullets, <50 words) to all architecture documents"

# Step 3: Create quick reference card
claude: "Create a 1-page quick reference card for Clean Architecture patterns"

# Step 4: Extract ADRs from architecture decisions
claude: "Extract Architecture Decision Records (ADRs) from ARCHITECTURE-PATTERNS-ANALYSIS.md"

# Step 5: Create code examples document
claude: "Create CODE-EXAMPLES.md with copy-paste ready implementations for all patterns"
```

**Result:** 6,200+ lines of documentation, 88+ code examples, 15+ diagrams

---

### 2. Pragmatic Architecture Enhancement

**Command Pattern:**

```bash
# When you have comprehensive architecture docs and want to implement improvements

# Step 1: Brainstorm implementation options
claude: "[brainstorm] Read the architecture review docs and propose a plan for implementing the recommendations"

# Step 2: Evaluate if full architecture is needed
claude: "[refine] Is this architecture too much? Any middle ground?"

# Step 3: Create pragmatic roadmap
claude: "Create a roadmap with three options: Quick Wins (1 week), Pragmatic (2 weeks), Full (4-6 weeks)"
```

**Result:** Pragmatic roadmap with evaluation points, no over-engineering

---

## Architecture Documentation Commands

### Command: Comprehensive Architecture Review

**Use Case:** Starting a new project or refactoring existing codebase

**Prompt:**

```
Analyze the codebase and create comprehensive architecture documentation:

1. Current architecture analysis (3-layer → 4-layer comparison)
2. Clean Architecture patterns (Domain, Use Cases, Adapters, Frameworks)
3. API design review (best practices for Node.js modules)
4. Code examples (copy-paste ready for all patterns)
5. Quick reference card (1-page desk reference)
6. Architecture Decision Records (ADRs)

Focus on:
- TL;DR sections for every major section
- Visual diagrams (ASCII art, Mermaid)
- Copy-paste ready code examples
- Before/after comparisons
- Clear layer responsibilities
```

**Files Created:**

- `docs/architecture/ARCHITECTURE-PATTERNS-ANALYSIS.md` (~1,200 lines)
- `docs/architecture/API-DESIGN-REVIEW.md` (~920 lines)
- `docs/architecture/CODE-EXAMPLES.md` (~1,000 lines)
- `docs/architecture/QUICK-REFERENCE.md` (~400 lines)
- `docs/architecture/decisions/ADR-001.md` through `ADR-003.md`
- `docs/architecture/README.md` (documentation hub)

---

### Command: Add TL;DR Sections

**Use Case:** Making existing architecture docs scannable

**Prompt:**

```
Add TL;DR sections to all architecture documents:

Format:
> **TL;DR:**
> - Point 1 (actionable insight)
> - Point 2 (key decision)
> - Point 3 (practical outcome)

Requirements:
- 3-5 bullet points
- <50 words total
- Focus on "what" and "why", not "how"
- Place at start of each major section
```

**Example Output:**

```markdown
> **TL;DR:**
>
> - **What**: Vendored code pattern - copy battle-tested shell scripts
> - **Why**: Zero dependencies, one-command install, production reliability
> - **How**: JavaScript bridge → Shell scripts → Filesystem detection
> - **Status**: ✅ Production ready with 7/7 tests passing
```

---

### Command: Extract Architecture Decision Records (ADRs)

**Use Case:** Documenting past decisions explicitly

**Prompt:**

```
Extract ADRs from existing architecture documentation:

1. Find major architectural decisions in ARCHITECTURE-PATTERNS-ANALYSIS.md
2. Create separate ADR file for each (ADR-001, ADR-002, etc.)
3. Use ADR template format:
   - Status (Proposed/Accepted/Rejected/Superseded)
   - Context and Problem Statement
   - Decision Drivers
   - Decision with code examples
   - Consequences (Positive, Negative, Neutral)
   - Alternatives Considered
   - Related Decisions

4. Create ADR index in docs/architecture/decisions/README.md
```

**Example ADRs:**

- ADR-001: Vendored Code Pattern
- ADR-002: Clean Architecture (4 layers)
- ADR-003: Bridge Pattern for Shell Integration

---

## Implementation Patterns

### Pattern: Error Class Hierarchy

**Code Template:**

```javascript
// cli/lib/errors.js

export class ZshConfigError extends Error {
  constructor(message, code) {
    super(message)
    this.name = 'ZshConfigError'
    this.code = code
  }
}

export class ValidationError extends ZshConfigError {
  constructor(field, message) {
    super(`Validation failed for ${field}: ${message}`, 'VALIDATION_ERROR')
    this.field = field
  }
}

export class ProjectNotFoundError extends ZshConfigError {
  constructor(path) {
    super(`Project not found: ${path}`, 'PROJECT_NOT_FOUND')
    this.path = path
  }
}

export class SessionAlreadyActiveError extends ZshConfigError {
  constructor(session) {
    super(`Session already active for project: ${session.project}`, 'SESSION_ACTIVE')
    this.session = session
  }
}
```

**Usage:**

```javascript
import { ProjectNotFoundError } from './lib/errors.js'

if (!fs.existsSync(projectPath)) {
  throw new ProjectNotFoundError(projectPath)
}
```

---

### Pattern: Input Validation

**Code Template:**

```javascript
// cli/lib/validation.js

import { ValidationError } from './errors.js'

export function validatePath(path, fieldName = 'path') {
  if (!path) {
    throw new ValidationError(fieldName, 'is required')
  }

  if (typeof path !== 'string') {
    throw new ValidationError(fieldName, 'must be a string')
  }

  if (!path.trim()) {
    throw new ValidationError(fieldName, 'cannot be empty')
  }

  return path
}

export function validateProjectPath(path) {
  validatePath(path, 'projectPath')

  if (!require('path').isAbsolute(path)) {
    throw new ValidationError('projectPath', 'must be absolute')
  }

  return path
}

export function validateOptions(options, schema) {
  if (typeof options !== 'object') {
    throw new ValidationError('options', 'must be an object')
  }

  for (const [key, validator] of Object.entries(schema)) {
    if (key in options) {
      validator(options[key], key)
    }
  }

  return options
}
```

**Usage:**

```javascript
import { validateProjectPath } from './lib/validation.js'

export async function detectProjectType(projectPath, options = {}) {
  validateProjectPath(projectPath)
  // ... rest of implementation
}
```

---

### Pattern: TypeScript Definitions

**Code Template:**

```typescript
// cli/lib/project-detector-bridge.d.ts

export type ProjectType =
  | 'r-package'
  | 'quarto'
  | 'quarto-extension'
  | 'research'
  | 'generic'
  | 'unknown'

export interface DetectionOptions {
  /** Custom type mappings */
  mappings?: Record<string, ProjectType>
  /** Timeout in milliseconds */
  timeout?: number
  /** Enable caching */
  cache?: boolean
}

/**
 * Detect project type from directory path
 * @param projectPath Absolute path to project directory
 * @param options Detection options
 * @returns Project type string
 */
export function detectProjectType(
  projectPath: string,
  options?: DetectionOptions
): Promise<ProjectType>

/**
 * Detect multiple projects in parallel
 * @param projectPaths Array of absolute paths
 * @param options Detection options
 * @returns Map of path to project type
 */
export function detectMultipleProjects(
  projectPaths: string[],
  options?: DetectionOptions
): Promise<Record<string, ProjectType>>
```

---

### Pattern: Bridge Pattern (JavaScript ↔ Shell)

**Code Template:**

```javascript
// cli/lib/shell-bridge.js

import { exec } from 'child_process'
import { promisify } from 'util'

const execAsync = promisify(exec)

/**
 * Bridge: Adapts shell script interface to JavaScript Promise-based API
 */
export async function executeShellFunction(scriptPath, functionName, args = []) {
  try {
    const argsString = args.map(arg => `"${arg}"`).join(' ')

    const { stdout, stderr } = await execAsync(
      `source "${scriptPath}" && ${functionName} ${argsString}`,
      { shell: '/bin/zsh' }
    )

    if (stderr) {
      console.error(`Warning: ${stderr}`)
    }

    return stdout.trim()
  } catch (error) {
    console.error(`Shell execution failed: ${error.message}`)
    throw error
  }
}

/**
 * Type mapping: Decouple API from shell implementation
 */
export function mapShellType(shellType, mappings = {}) {
  const defaultMappings = {
    rpkg: 'r-package',
    'quarto-ext': 'quarto-extension',
    project: 'generic'
  }

  const allMappings = { ...defaultMappings, ...mappings }
  return allMappings[shellType] || shellType
}
```

**Usage Pattern:**

```
JavaScript World          Bridge               Shell World
─────────────────        ────────             ─────────────
Promise<string>    ←     execAsync()     →    stdout/stderr
Exceptions         ←     try/catch       →    exit codes
'r-package'        ←     mapShellType    →    'rpkg'
```

---

## File Organization

### Directory Structure for Clean Architecture

```
cli/
├── domain/                    # Layer 1 (innermost)
│   ├── entities/              # Session, Project, Task
│   ├── value-objects/         # ProjectType, SessionState
│   └── repositories/          # ISessionRepository (interfaces)
│
├── use-cases/                 # Layer 2
│   ├── CreateSessionUseCase.js
│   └── ScanProjectsUseCase.js
│
├── adapters/                  # Layer 3
│   ├── controllers/           # SessionController
│   ├── gateways/              # ProjectDetectorGateway
│   ├── presenters/            # TerminalPresenter
│   └── repositories/          # FileSystemSessionRepository
│
├── frameworks/                # Layer 4 (outermost)
│   ├── cli/                   # CLI entry point
│   ├── vendor/                # Vendored shell scripts
│   └── di-container.js        # Dependency injection
│
├── lib/                       # Shared utilities
│   ├── errors.js              # Error class hierarchy
│   ├── validation.js          # Input validation
│   └── constants.js           # System constants
│
└── test/                      # Tests mirror structure
    ├── domain/
    ├── use-cases/
    └── adapters/
```

### Documentation Structure

```
docs/
├── architecture/
│   ├── README.md                           # Documentation hub
│   ├── QUICK-REFERENCE.md                  # 1-page desk reference
│   ├── ARCHITECTURE-PATTERNS-ANALYSIS.md   # Full architecture guide
│   ├── API-DESIGN-REVIEW.md                # API best practices
│   ├── CODE-EXAMPLES.md                    # Copy-paste examples
│   ├── VENDOR-INTEGRATION-ARCHITECTURE.md  # Integration patterns
│   └── decisions/
│       ├── README.md                       # ADR index
│       ├── ADR-001-vendored-code.md
│       ├── ADR-002-clean-architecture.md
│       └── ADR-003-bridge-pattern.md
│
├── user/
│   ├── WORKFLOWS-QUICK-WINS.md
│   └── ALIAS-REFERENCE-CARD.md
│
└── reference/
    └── COMMAND-PATTERNS.md
```

---

## Testing Patterns

### Unit Test Pattern (Domain Layer)

```javascript
// test/domain/entities/test-session.js

import { describe, it } from 'node:test'
import assert from 'node:assert'
import { Session } from '../../../domain/entities/Session.js'

describe('Session Entity', () => {
  it('should create session with valid data', () => {
    const session = new Session({
      project: 'my-project',
      path: '/absolute/path',
      type: 'r-package'
    })

    assert.strictEqual(session.project, 'my-project')
    assert.strictEqual(session.isActive(), true)
  })

  it('should validate required fields', () => {
    assert.throws(() => new Session({ project: '' }), { name: 'ValidationError' })
  })
})
```

### Integration Test Pattern (Adapters Layer)

```javascript
// test/adapters/repositories/test-file-system-session-repository.js

import { describe, it, beforeEach, afterEach } from 'node:test'
import assert from 'node:assert'
import { FileSystemSessionRepository } from '../../../adapters/repositories/FileSystemSessionRepository.js'
import fs from 'fs'
import path from 'path'

describe('FileSystemSessionRepository', () => {
  let repo
  let tempDir

  beforeEach(() => {
    tempDir = fs.mkdtempSync('/tmp/test-')
    repo = new FileSystemSessionRepository(tempDir)
  })

  afterEach(() => {
    fs.rmSync(tempDir, { recursive: true, force: true })
  })

  it('should save and retrieve session', async () => {
    const session = { id: '123', project: 'test' }

    await repo.save(session)
    const retrieved = await repo.findById('123')

    assert.deepStrictEqual(retrieved, session)
  })
})
```

### E2E Test Pattern (Full Stack)

```javascript
// test/e2e/test-workflow.js

import { describe, it } from 'node:test'
import assert from 'node:assert'
import { exec } from 'child_process'
import { promisify } from 'util'

const execAsync = promisify(exec)

describe('E2E: Project Detection Workflow', () => {
  it('should detect R package type', async () => {
    const { stdout } = await execAsync(
      'node cli/bin/detect-type.js /Users/dt/projects/r-packages/stable/rmediation'
    )

    assert.strictEqual(stdout.trim(), 'r-package')
  })

  it('should handle invalid path gracefully', async () => {
    const { stdout } = await execAsync('node cli/bin/detect-type.js /nonexistent')

    assert.strictEqual(stdout.trim(), 'unknown')
  })
})
```

---

## Reusable Prompt Templates

### Template: Architecture Sprint

**Copy-paste for new projects:**

```
Create comprehensive architecture documentation for this project:

## Phase 1: Analysis
1. Analyze current architecture
2. Identify design patterns in use
3. Document layer responsibilities
4. Create visual diagrams (Mermaid + ASCII)

## Phase 2: Documentation
1. Create ARCHITECTURE-PATTERNS-ANALYSIS.md
   - Current architecture overview
   - Recommended improvements
   - Before/after comparison
   - Implementation roadmap

2. Create API-DESIGN-REVIEW.md
   - Review all public APIs
   - Best practices analysis
   - Improvement recommendations

3. Create CODE-EXAMPLES.md
   - Copy-paste ready implementations
   - All major patterns
   - Testing examples

4. Create QUICK-REFERENCE.md
   - 1-page desk reference
   - Visual diagrams
   - Common patterns
   - Quick wins

## Phase 3: ADRs
1. Extract major architectural decisions
2. Create ADR files with context and consequences
3. Create ADR index

## Requirements:
- Every section needs TL;DR (3-5 bullets, <50 words)
- Include code examples (not pseudocode)
- Focus on practical, copy-paste ready content
- Visual aids (diagrams) for complex concepts
```

---

### Template: Pragmatic Implementation Roadmap

**Copy-paste when planning implementation:**

```
Create a pragmatic implementation roadmap for [FEATURE/ARCHITECTURE]:

## Requirements:
1. Provide 3 options:
   - Option A: Quick Wins (1 week) - Minimal changes, high impact
   - Option B: Pragmatic Approach (2 weeks) - Balanced improvement
   - Option C: Full Implementation (4-6 weeks) - Comprehensive solution

2. For each option include:
   - Time estimate
   - Risk level
   - ROI assessment
   - What gets delivered
   - When to choose this option

3. Detailed Week 1 Plan:
   - Day-by-day breakdown
   - Copy-paste ready code examples
   - Test requirements
   - Success criteria

4. Evaluation Points:
   - Clear stopping points
   - Decision criteria for continuing
   - What success looks like

5. Decision Tree:
   - When to stop after Week 1
   - When to continue to Week 2
   - When to plan full implementation

## Philosophy:
- ADHD-friendly (weekly milestones, dopamine hits)
- No forced commitment to long timelines
- Try → Evaluate → Decide approach
- Avoid over-engineering
```

---

## Quick Reference: Documentation Standards

### TL;DR Format

```markdown
> **TL;DR:**
>
> - **What**: [One sentence describing the thing]
> - **Why**: [One sentence explaining the motivation]
> - **How**: [One sentence showing the approach]
> - **Status**: [Current state with emoji ✅/⚠️/🔄]
```

### Code Example Format

````markdown
### Pattern Name

**Use Case:** [When to use this pattern]

**Code:**

```javascript
// Full implementation (not pseudocode)
export function exampleFunction() {
  // ... complete working code
}
```
````

**Usage:**

```javascript
// How to use it
import { exampleFunction } from './lib/example.js'
const result = exampleFunction()
```

**Result:** [What this achieves]

````

### ADR Format

```markdown
# ADR-XXX: [Title]

**Status:** 🟡 Proposed / ✅ Accepted / ❌ Rejected / 🔄 Superseded

**Date:** YYYY-MM-DD

---

## Context and Problem Statement

[Problem description]

**Question:** [The question being answered]

---

## Decision

**Chosen option: "[Name]"** because [reasons]

[Implementation with code examples]

---

## Consequences

### Positive
- ✅ [Benefit 1]

### Negative
- ⚠️ [Drawback 1]

### Neutral
- 📝 [Neutral consequence 1]

---

## Alternatives Considered

### Alternative: [Name]

**Rejected because:** [reasons]
````

---

## Key Principles

1. **Documentation is Code**
   - Must be copy-paste ready
   - Test examples before committing
   - Keep in sync with implementation

2. **Pragmatic over Perfect**
   - Start with Quick Wins
   - Evaluate before expanding
   - Avoid over-engineering

3. **ADHD-Friendly**
   - Weekly milestones
   - Clear stopping points
   - Visual hierarchy

4. **Decision Transparency**
   - Document "why" in ADRs
   - Include alternatives considered
   - Track consequences

5. **Layer Discipline**
   - Dependencies point inward only
   - Domain has zero dependencies
   - Clear separation of concerns

---

**Last Updated:** 2025-12-21
**Maintainer:** DT
**See Also:**

- [ARCHITECTURE-ROADMAP.md](ARCHITECTURE-ROADMAP.md) - Implementation plan
- [docs/architecture/README.md](docs/architecture/README.md) - Documentation hub
- [docs/architecture/QUICK-REFERENCE.md](docs/architecture/QUICK-REFERENCE.md) - Patterns reference
