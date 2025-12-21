# Architecture Enhancement Roadmap - Pragmatic Approach

**Status:** 🎯 Recommended Plan
**Date:** 2025-12-21
**Strategy:** Quick Wins First, Evaluate, Expand If Needed
**Philosophy:** Ship value fast, avoid over-engineering

---

## 🎯 Executive Summary

**Decision:** Start with high-impact Quick Wins (1 week) instead of full Clean Architecture (4 weeks)

**Why:**
- ✅ Immediate DX improvements
- ✅ Low risk, fast delivery
- ✅ Can expand later if needed
- ✅ ADHD-friendly (weekly dopamine hits)
- ✅ No commitment to full refactoring

**Timeline:** 1 week → evaluate → decide next steps

---

## 📊 The Three Options

### Option A: Quick Wins Only ⭐⭐⭐⭐⭐ (RECOMMENDED)

**Time:** 1 week
**Risk:** Very low
**ROI:** Immediate

**What:**
- Error class hierarchy
- Input validation
- TypeScript definitions
- ES modules migration

**When to choose:**
- ✅ Want immediate improvements
- ✅ Limited time
- ✅ Don't want major refactoring
- ✅ Current architecture works fine

---

### Option B: Pragmatic Clean Architecture ⭐⭐⭐⭐

**Time:** 2 weeks
**Risk:** Low
**ROI:** High (if maintained 1+ years)

**What:**
- Week 1: Quick Wins (from Option A)
- Week 2: Session in Clean Architecture (experiment)

**When to choose:**
- ✅ Want to learn patterns
- ✅ Have 2 weeks available
- ✅ Willing to experiment
- ✅ Can stop after week 1

---

### Option C: Full Clean Architecture ⭐⭐⭐

**Time:** 4-6 weeks
**Risk:** Medium
**ROI:** High (if maintained 2+ years AND enjoy architecture)

**What:**
- Complete 4-layer refactoring
- All design patterns
- Comprehensive testing

**When to choose:**
- ✅ Building for long-term
- ✅ Multiple contributors
- ✅ Want comprehensive solution
- ✅ Have time to invest

**Skip if:**
- ❌ Just want it to work
- ❌ Solo developer
- ❌ Time is limited

---

## 🏆 Recommended: Option A (Quick Wins)

### Week 1: High-Impact Quick Wins

**Goal:** Maximum improvement with minimum effort

**Effort:** 4-5 days (16-20 hours)
**Impact:** Immediate DX improvements
**Risk:** Very low

---

#### Monday-Tuesday: Error Classes (1.5 days)

**Create:** `cli/lib/errors.js`

```javascript
// Error hierarchy for better error handling
export class ZshConfigError extends Error {
  constructor(message, code) {
    super(message);
    this.name = 'ZshConfigError';
    this.code = code;
  }
}

export class ValidationError extends ZshConfigError {
  constructor(field, message) {
    super(`Validation failed for ${field}: ${message}`, 'VALIDATION_ERROR');
    this.field = field;
  }
}

export class ProjectNotFoundError extends ZshConfigError {
  constructor(path) {
    super(`Project not found: ${path}`, 'PROJECT_NOT_FOUND');
    this.path = path;
  }
}

export class SessionAlreadyActiveError extends ZshConfigError {
  constructor(session) {
    super(`Session already active for project: ${session.project}`, 'SESSION_ACTIVE');
    this.session = session;
  }
}

export class SessionNotFoundError extends ZshConfigError {
  constructor() {
    super('No active session', 'NO_ACTIVE_SESSION');
  }
}
```

**Update:** All existing APIs to use new error classes
- Replace generic `Error` with semantic error types
- Update catch blocks to handle specific errors

**Test:** Error handling works correctly

**Impact:** ✅ Better error messages, easier debugging

---

#### Wednesday-Thursday: Input Validation (2 days)

**Pattern:** Validate all public API inputs

```javascript
// cli/lib/validation.js

export function validatePath(path, fieldName = 'path') {
  if (!path) {
    throw new ValidationError(fieldName, 'is required');
  }

  if (typeof path !== 'string') {
    throw new ValidationError(fieldName, 'must be a string');
  }

  if (!path.trim()) {
    throw new ValidationError(fieldName, 'cannot be empty');
  }

  return path;
}

export function validateProjectPath(path) {
  validatePath(path, 'projectPath');

  if (!require('path').isAbsolute(path)) {
    throw new ValidationError('projectPath', 'must be absolute');
  }

  return path;
}

export function validateOptions(options, schema) {
  if (typeof options !== 'object') {
    throw new ValidationError('options', 'must be an object');
  }

  // Validate against schema
  for (const [key, validator] of Object.entries(schema)) {
    if (key in options) {
      validator(options[key], key);
    }
  }

  return options;
}
```

**Apply to:**
- `cli/lib/project-detector-bridge.js`
- `cli/api/status-api.js`
- `cli/api/workflow-api.js`

**Impact:** ✅ Fail fast with clear errors, fewer runtime bugs

---

#### Friday: TypeScript Definitions (1 day)

**Create:** `.d.ts` files for better IDE support

```typescript
// cli/lib/project-detector-bridge.d.ts

export type ProjectType =
  | 'r-package'
  | 'quarto'
  | 'quarto-extension'
  | 'research'
  | 'generic'
  | 'unknown';

export interface DetectionOptions {
  /** Custom type mappings */
  mappings?: Record<string, ProjectType>;
  /** Timeout in milliseconds */
  timeout?: number;
  /** Enable caching */
  cache?: boolean;
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
): Promise<ProjectType>;

/**
 * Detect multiple projects in parallel
 * @param projectPaths Array of absolute paths
 * @param options Detection options
 * @returns Map of path to project type
 */
export function detectMultipleProjects(
  projectPaths: string[],
  options?: DetectionOptions
): Promise<Record<string, ProjectType>>;

/**
 * Get list of supported project types
 * @returns Array of supported types
 */
export function getSupportedTypes(): ProjectType[];

/**
 * Check if a type is supported
 * @param type Type to check
 * @returns True if supported
 */
export function isTypeSupported(type: string): type is ProjectType;
```

**Create for:**
- `project-detector-bridge.d.ts`
- `status-api.d.ts`
- `workflow-api.d.ts`
- `errors.d.ts`

**Impact:** ✅ IDE autocomplete, type checking, better DX

---

#### Weekend (Optional): ES Modules Migration (0.5 days)

**Convert:** CommonJS → ES modules for consistency

**Files:**
- `cli/api/status-api.js`
- `cli/api/workflow-api.js`

**Before:**
```javascript
// CommonJS
const statusAdapter = require('../adapters/status');
module.exports = { getDashboardData };
```

**After:**
```javascript
// ES Modules
import { statusAdapter } from '../adapters/status.js';
export { getDashboardData };
```

**Impact:** ✅ Consistency across codebase

---

### Week 1 Deliverables

**By end of week:**
- ✅ Error class hierarchy implemented
- ✅ All APIs validate inputs
- ✅ TypeScript definitions for IDE support
- ✅ (Optional) ES modules consistency
- ✅ Tests passing
- ✅ Documentation updated

**Total effort:** 16-20 hours (4-5 days)

**Impact:**
- Better error messages
- Fewer runtime bugs
- IDE autocomplete works
- Consistent module format
- Professional-grade APIs

---

## 🔄 Evaluation Point (End of Week 1)

After completing Quick Wins, ask yourself:

### ✅ If You Feel:
- "This is enough, system works great now"
- "I want to ship features, not refactor more"
- "The improvements are noticeable"

**→ STOP HERE. Ship features. Done! 🎉**

---

### 🤔 If You Feel:
- "I wish the code was more structured"
- "I want better testability"
- "I'm curious about Clean Architecture"
- "I have another week to invest"

**→ Try Week 2 (Pragmatic Clean)**

---

### 🚀 If You Feel:
- "I want the full refactoring"
- "I'm building for the long term"
- "I enjoy architecture work"
- "I have 3-4 more weeks"

**→ Consider Option C (Full Clean)**

---

## 📅 Optional: Week 2 (Pragmatic Clean)

**Only do this if Week 1 went well and you want more**

### Goal: Experiment with Clean Architecture

**Implement:** Just Session management in 4 layers

**Why Session?**
- Small scope (can complete in 1 week)
- Core feature (high value)
- Good learning example
- Can evaluate pattern

---

#### Day 1-2: Domain Layer

**Create:**
```
cli/domain/
├── entities/
│   └── Session.js
├── value-objects/
│   └── SessionState.js
└── repositories/
    └── ISessionRepository.js
```

**Copy from:** `docs/architecture/CODE-EXAMPLES.md`

**Test:** Domain layer with pure unit tests (no I/O)

---

#### Day 3-4: Use Cases & Adapters

**Create:**
```
cli/use-cases/
└── CreateSessionUseCase.js

cli/adapters/
└── repositories/
    ├── FileSystemSessionRepository.js
    └── InMemorySessionRepository.js
```

**Test:** Use cases with InMemoryRepository

---

#### Day 5-6: Wire & Ship

**Create:**
```
cli/frameworks/
└── di-container.js
```

**Wire:** Everything together
**Create:** `work-beta` command (beta version)
**Test:** E2E with real files

---

### Week 2 Deliverables

- ✅ Session management in Clean Architecture
- ✅ All 4 layers implemented
- ✅ `work-beta` command works
- ✅ Tests passing
- ✅ Can evaluate if pattern is worth it

---

## 🎯 Decision Tree

```
Start
  │
  ├─ Do Week 1 (Quick Wins)
  │   │
  │   ├─ Satisfied? → STOP, ship features ✅
  │   │
  │   ├─ Want more? → Do Week 2 (Pragmatic)
  │   │   │
  │   │   ├─ Like it? → Continue with more features
  │   │   │
  │   │   └─ Too complex? → STOP, keep Quick Wins
  │   │
  │   └─ Want full refactor? → Plan 4-week project
  │
  └─ Skip architecture work → Ship features
```

---

## 📊 Comparison Table

| Metric | Quick Wins | Pragmatic | Full Clean |
|--------|-----------|-----------|------------|
| **Time** | 1 week | 2 weeks | 4-6 weeks |
| **Risk** | Very low | Low | Medium |
| **Files Added** | ~5 | ~20 | ~50+ |
| **Complexity** | None | Moderate | High |
| **Testability** | Same | Better | Best |
| **Flexibility** | Same | Better | Best |
| **Learning** | Minimal | Moderate | High |
| **ADHD Score** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |

---

## 🎁 What You Get

### After Quick Wins (Week 1):

**Code Quality:**
- ✅ Professional error handling
- ✅ Input validation everywhere
- ✅ TypeScript support
- ✅ Consistent modules

**Developer Experience:**
- ✅ Better error messages
- ✅ IDE autocomplete
- ✅ Fewer bugs
- ✅ Easier debugging

**Maintenance:**
- ✅ Same architecture (no learning curve)
- ✅ Incremental improvements
- ✅ Can expand later

---

### After Pragmatic Clean (Week 2):

**Everything from Week 1, plus:**
- ✅ Testable domain logic
- ✅ Clean separation of concerns
- ✅ Repository pattern (swap storage)
- ✅ Use cases isolated
- ✅ Know if Clean Architecture fits your style

---

## 🚀 Getting Started

### Tomorrow (Monday):

```bash
# 1. Create error classes directory
mkdir -p cli/lib

# 2. Create errors.js
# Copy from this document (lines 67-97)

# 3. Write tests
mkdir -p cli/test
# Create cli/test/test-errors.js

# 4. Update one API to use new errors
# Start with project-detector-bridge.js
```

---

### This Week:

**Monday-Tuesday:** Error classes
**Wednesday-Thursday:** Input validation
**Friday:** TypeScript definitions
**Weekend:** (Optional) ES modules

---

### Next Week:

**If satisfied:** Ship features! 🎉
**If curious:** Try Week 2 experiment
**If ambitious:** Plan full refactoring

---

## 📝 Success Criteria

### Week 1 Complete When:

- [ ] Error class hierarchy created
- [ ] All APIs validate inputs
- [ ] TypeScript .d.ts files added
- [ ] (Optional) ES modules migrated
- [ ] All tests passing
- [ ] Documentation updated
- [ ] Can ship to users

### Week 2 Complete When (if doing):

- [ ] Session entity works
- [ ] CreateSessionUseCase works
- [ ] FileSystemRepository works
- [ ] `work-beta` command ships
- [ ] Evaluated pattern fit
- [ ] Decided next steps

---

## 🎯 Recommendation

**Start with Week 1 (Quick Wins)**

**Reasons:**
1. ✅ Immediate value (better DX)
2. ✅ Low commitment (1 week)
3. ✅ No risk (incremental improvements)
4. ✅ Can stop or continue
5. ✅ ADHD-friendly (fast feedback)

**Don't commit to full refactoring upfront.**

Try 1 week → Evaluate → Decide.

---

## 📚 Resources

**Code Examples:**
- Error classes: This document
- Validation: `docs/architecture/API-DESIGN-REVIEW.md`
- TypeScript: `docs/architecture/CODE-EXAMPLES.md`
- Clean Architecture: `docs/architecture/ARCHITECTURE-PATTERNS-ANALYSIS.md`

**ADRs:**
- [ADR-001: Vendored Code](docs/architecture/decisions/ADR-001-vendored-code-pattern.md)
- [ADR-002: Clean Architecture](docs/architecture/decisions/ADR-002-clean-architecture.md)
- [ADR-003: Bridge Pattern](docs/architecture/decisions/ADR-003-bridge-pattern.md)

---

**Last Updated:** 2025-12-21
**Status:** Recommended Plan
**Next Action:** Start Week 1 (Quick Wins)
**Time Commitment:** 1 week → evaluate → decide
