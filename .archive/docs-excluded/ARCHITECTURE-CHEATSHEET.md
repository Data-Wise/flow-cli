# Architecture Cheatsheet - 1 Page

**Quick Reference:** Essential commands and patterns for architecture work
**Created:** 2025-12-21

---

## 🚀 Quick Commands

### Documentation Sprint (Full Architecture Docs)

```bash
claude: "Create comprehensive architecture documentation:
1. Analyze current architecture
2. Create ARCHITECTURE-PATTERNS-ANALYSIS.md (Clean Architecture guide)
3. Create API-DESIGN-REVIEW.md (Node.js API best practices)
4. Create CODE-EXAMPLES.md (copy-paste ready implementations)
5. Create QUICK-REFERENCE.md (1-page desk reference)
6. Extract ADRs (Architecture Decision Records)
7. Add TL;DR sections to all docs (3-5 bullets, <50 words)"
```

**Result:** 6,200+ lines, 88+ examples, 15+ diagrams, 3 ADRs

---

### Pragmatic Enhancement Roadmap

```bash
# Step 1: Brainstorm
claude: "[brainstorm] Read architecture docs and propose implementation plan"

# Step 2: Evaluate if full architecture is needed
claude: "[refine] Is this architecture too much? Any middle ground?"

# Step 3: Create pragmatic roadmap
claude: "Create roadmap with 3 options: Quick Wins (1w), Pragmatic (2w), Full (4-6w)"
```

**Result:** ARCHITECTURE-ROADMAP.md with weekly evaluation points

---

## 📋 Copy-Paste Patterns

### Error Classes (`cli/lib/errors.js`)

```javascript
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
```

---

### Input Validation (`cli/lib/validation.js`)

```javascript
import { ValidationError } from './errors.js'

export function validatePath(path, fieldName = 'path') {
  if (!path) throw new ValidationError(fieldName, 'is required')
  if (typeof path !== 'string') throw new ValidationError(fieldName, 'must be a string')
  if (!path.trim()) throw new ValidationError(fieldName, 'cannot be empty')
  return path
}
```

---

### TypeScript Definitions (`.d.ts`)

```typescript
export type ProjectType = 'r-package' | 'quarto' | 'research' | 'generic' | 'unknown'

export interface DetectionOptions {
  mappings?: Record<string, ProjectType>
  timeout?: number
  cache?: boolean
}

export function detectProjectType(
  projectPath: string,
  options?: DetectionOptions
): Promise<ProjectType>
```

---

### Bridge Pattern (JavaScript ↔ Shell)

```javascript
import { exec } from 'child_process'
import { promisify } from 'util'

const execAsync = promisify(exec)

export async function executeShellFunction(scriptPath, functionName, args = []) {
  try {
    const argsString = args.map(arg => `"${arg}"`).join(' ')
    const { stdout, stderr } = await execAsync(
      `source "${scriptPath}" && ${functionName} ${argsString}`,
      { shell: '/bin/zsh' }
    )
    if (stderr) console.error(`Warning: ${stderr}`)
    return stdout.trim()
  } catch (error) {
    console.error(`Shell execution failed: ${error.message}`)
    throw error
  }
}
```

---

## 📁 Directory Structure

```
cli/
├── domain/           # Layer 1: Business rules (zero dependencies)
│   ├── entities/
│   ├── value-objects/
│   └── repositories/
├── use-cases/        # Layer 2: Application logic
├── adapters/         # Layer 3: Interface adapters
│   ├── controllers/
│   ├── gateways/
│   ├── presenters/
│   └── repositories/
└── frameworks/       # Layer 4: External (CLI, vendor, DI)
```

**Dependency Rule:** Inner layers NEVER depend on outer layers

---

## 📝 Documentation Standards

### TL;DR Format

```markdown
> **TL;DR:**
>
> - **What**: [Thing description]
> - **Why**: [Motivation]
> - **How**: [Approach]
> - **Status**: ✅/⚠️/🔄 [Current state]
```

### ADR Template

```markdown
# ADR-XXX: [Title]

**Status:** 🟡 Proposed / ✅ Accepted / ❌ Rejected

**Date:** YYYY-MM-DD

## Context and Problem Statement

[Problem]

## Decision

**Chosen: "[Name]"** because [reasons]

## Consequences

- ✅ Positive: [benefits]
- ⚠️ Negative: [drawbacks]
- 📝 Neutral: [notes]

## Alternatives Considered

**[Name]** - Rejected because [reasons]
```

---

## ✅ Testing Patterns

### Unit Test (Domain)

```javascript
import { describe, it } from 'node:test'
import assert from 'node:assert'

describe('Entity', () => {
  it('should validate required fields', () => {
    assert.throws(() => new Entity({ field: '' }), { name: 'ValidationError' })
  })
})
```

### Integration Test (Adapters)

```javascript
import { beforeEach, afterEach } from 'node:test'
import fs from 'fs'

describe('Repository', () => {
  let tempDir

  beforeEach(() => {
    tempDir = fs.mkdtempSync('/tmp/test-')
  })

  afterEach(() => {
    fs.rmSync(tempDir, { recursive: true, force: true })
  })

  it('should persist data', async () => {
    // test implementation
  })
})
```

---

## 🎯 Prompt Templates

### Architecture Sprint

```
Create comprehensive architecture docs:
1. ARCHITECTURE-PATTERNS-ANALYSIS.md
2. API-DESIGN-REVIEW.md
3. CODE-EXAMPLES.md (copy-paste ready)
4. QUICK-REFERENCE.md (1-page)
5. Extract ADRs
6. Add TL;DR sections everywhere
```

### Pragmatic Roadmap

```
Create implementation roadmap:
- Option A: Quick Wins (1 week)
- Option B: Pragmatic (2 weeks)
- Option C: Full (4-6 weeks)

Include:
- Day-by-day Week 1 plan
- Copy-paste code examples
- Evaluation points (when to stop)
- Decision tree
- ADHD-friendly milestones
```

---

## 🔑 Key Principles

1. **Pragmatic over Perfect** - Start small, evaluate, expand if needed
2. **TL;DR Everything** - Every section needs 3-5 bullet summary
3. **Copy-Paste Ready** - No pseudocode, full implementations
4. **Layer Discipline** - Dependencies point inward only
5. **ADHD-Friendly** - Weekly milestones, clear stopping points
6. **Document Why** - ADRs capture decisions and trade-offs

---

## 📚 Related Files

- [ARCHITECTURE-COMMAND-REFERENCE.md](ARCHITECTURE-COMMAND-REFERENCE.md) - Full reference (763 lines)
- [ARCHITECTURE-ROADMAP.md](ARCHITECTURE-ROADMAP.md) - Implementation plan
- [docs/architecture/README.md](docs/architecture/README.md) - Documentation hub
- [docs/architecture/QUICK-REFERENCE.md](docs/architecture/QUICK-REFERENCE.md) - Clean Architecture patterns

---

**Last Updated:** 2025-12-21 | **Print this!** 🖨️
