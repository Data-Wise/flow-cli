# Monorepo Package Structure Audit

**Date:** 2025-12-20
**Project:** ZSH Workflow Manager
**Current Setup:** npm workspaces (minimal configuration)

> **UPDATE 2025-12-20:** App workspace has been removed and archived. This audit remains relevant for understanding the CLI workspace structure and package management principles. The recommendations were implemented as "Option A" (minimal improvements). See `docs/archive/2025-12-20-app-removal/` for archived app code.

## Executive Summary

Your monorepo is **intentionally minimal** with a "simplicity-first" philosophy that aligns well with ADHD-friendly design. However, there are several optimization opportunities that can improve developer experience without adding complexity.

### Current State: ⭐⭐⭐ (3/5)

**Strengths:**
- ✅ Clean workspace separation (`app/` and `cli/`)
- ✅ Zero dependency overlap (no bloat)
- ✅ Simple npm workspaces setup
- ✅ CLI has zero dependencies (pure Node.js)

**Weaknesses:**
- ❌ No shared tooling configuration
- ❌ No build orchestration or caching
- ❌ No dependency version management
- ❌ Tests not unified
- ⚠️  Node version mismatch between workspaces

---

## Current Architecture

```
zsh-configuration/
├── package.json          # Root (workspaces: ["app", "cli"])
├── app/
│   ├── package.json      # Electron app
│   └── src/
└── cli/
    ├── package.json      # Node.js adapters (zero deps)
    └── adapters/
```

### Dependency Analysis

| Workspace | Prod Dependencies | Dev Dependencies | Total |
|-----------|-------------------|------------------|-------|
| **Root** | 0 | 0 | 0 |
| **app/** | 1 (electron-store) | 3 (electron, electron-builder, jest) | 4 |
| **cli/** | 0 | 0 | 0 |

**Overlap:** None (good!)

### Scripts Audit

| Workspace | Scripts | Build Tools | Test Framework |
|-----------|---------|-------------|----------------|
| **Root** | setup, sync, dev, test, build | None | Delegates to workspaces |
| **app/** | start, dev, build, test | electron-builder | jest |
| **cli/** | test, test:status, test:workflow | None (vanilla Node) | Custom (node test/*.js) |

---

## Issues Identified

### 🔴 Critical Issues

#### 1. Node Version Mismatch
**Impact:** HIGH
**Location:** [package.json:32](package.json#L32), [cli/package.json:20](cli/package.json#L20)

```json
// Root requires Node >= 18
"engines": { "node": ">=18.0.0" }

// CLI requires Node >= 14
"engines": { "node": ">=14.0.0" }
```

**Risk:** CLI could use APIs not available in Node 14, or root could break CLI compatibility.

**Fix:** Align all workspaces to same Node version (recommend `>=18.0.0`).

---

### 🟡 Medium Priority Issues

#### 2. No Shared Configuration Management
**Impact:** MEDIUM
**Current State:** Each workspace would need to duplicate configs when added

Missing shared configs:
- TypeScript (`tsconfig.json`)
- ESLint (`.eslintrc.js`)
- Prettier (`.prettierrc`)
- Jest (`jest.config.js`)

**Benefit of fixing:**
- Single source of truth for code style
- Easier to maintain consistency
- Faster to add new workspaces

#### 3. No Build Orchestration
**Impact:** MEDIUM
**Current State:** Manual script coordination

```json
// Root package.json
"scripts": {
  "dev": "npm run dev --workspace=app",    // Only runs app
  "build": "npm run build --workspace=app", // Only runs app
  "test": "npm test --workspaces"           // Runs all (good!)
}
```

**Issues:**
- Can't run parallel builds
- No incremental build caching
- No dependency-aware task execution
- `dev` and `build` ignore CLI workspace

**Example missing capability:**
```bash
# Want: Build CLI first, then app (if CLI changed)
npm run build  # Currently only builds app

# Want: Run dev mode for both workspaces
npm run dev    # Currently only runs app dev mode
```

#### 4. Test Framework Inconsistency
**Impact:** MEDIUM
**Current State:** Different test approaches per workspace

- **app/**: Uses Jest (`jest` command)
- **cli/**: Custom vanilla Node tests (`node test/*.js`)

**Trade-offs:**
- ✅ CLI has zero deps (good for simplicity)
- ❌ Different test APIs/assertions
- ❌ Can't collect unified coverage
- ❌ Different watch modes

#### 5. No Dependency Version Management
**Impact:** LOW (currently)
**Future Risk:** As project grows, dependency conflicts will arise

Currently no issues because:
- CLI has zero dependencies
- App dependencies are isolated

**Future risk scenario:**
```json
// Future: Both workspaces might need shared deps
// app/package.json
"dependencies": { "chalk": "^4.0.0" }

// cli/package.json (future)
"dependencies": { "chalk": "^5.0.0" }

// Without lockfile strategy, version conflicts emerge
```

---

### 🟢 Low Priority / Enhancement Opportunities

#### 6. No Package Exports Map
**Impact:** LOW
**Enhancement:** Enable clean imports between workspaces

```json
// Future: cli/package.json could export specific modules
"exports": {
  ".": "./api/index.js",
  "./adapters": "./adapters/index.js",
  "./workflow": "./adapters/workflow.js"
}

// app/ could then import:
import { getStatus } from '@workspace/cli/adapters'
```

#### 7. Missing Workspace Scripts
**Impact:** LOW
**Enhancement:** Better DX for common operations

```json
// Suggested additions to root package.json
"scripts": {
  "dev:app": "npm run dev --workspace=app",
  "dev:cli": "npm run test --workspace=cli --watch",
  "dev:all": "npm-run-all --parallel dev:app dev:cli",

  "build:app": "npm run build --workspace=app",
  "build:cli": "echo 'No build needed for CLI'",
  "build:all": "npm run build:app",

  "test:app": "npm test --workspace=app",
  "test:cli": "npm test --workspace=cli",
  "test:watch": "npm test --workspaces --watch",

  "clean": "rm -rf app/dist app/node_modules cli/node_modules node_modules",
  "reset": "npm run clean && npm install"
}
```

---

## Recommendations

### Option A: Minimal Improvements (ADHD-Friendly) ⭐ RECOMMENDED

**Philosophy:** Keep simplicity, fix critical issues only
**Effort:** 🔧 Low (1-2 hours)
**Impact:** ⚡ High (fixes compatibility issues)

**Changes:**
1. ✅ **Align Node versions** to `>=18.0.0` everywhere
2. ✅ **Add missing root scripts** for better DX
3. ✅ **Create shared package** for configs (optional, only if needed later)
4. ⚠️ **Keep CLI dependency-free** (maintain simplicity)
5. ⚠️ **Keep vanilla test approach** in CLI (no Jest)

**Result:** Better DX without added complexity

---

### Option B: Modern Monorepo Setup (Full Featured)

**Philosophy:** Adopt industry-standard tooling
**Effort:** 🏗️ High (4-6 hours)
**Impact:** 🚀 Very High (professional-grade setup)

**Changes:**
1. Migrate to **pnpm workspaces** (faster, better hoisting)
2. Add **Turborepo** for build caching and orchestration
3. Create **shared config packages** (`@repo/tsconfig`, `@repo/eslint-config`)
4. Unify test framework (Jest everywhere)
5. Add **remote caching** for CI/CD
6. Set up **changesets** for versioning

**Turborepo Example:**
```json
// turbo.json
{
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "test": {
      "cache": true,
      "outputs": ["coverage/**"]
    }
  }
}
```

**Benefits:**
- ⚡ 2-3x faster builds (caching)
- 🔄 Parallel task execution
- 🎯 Run only affected workspaces
- 📦 Better dependency management

**Drawbacks:**
- 📚 More concepts to learn
- 🔧 More configuration to maintain
- 💾 Larger `node_modules`

---

### Option C: Hybrid Approach (Pragmatic)

**Philosophy:** Add tooling incrementally as needed
**Effort:** 🔧 Medium (2-3 hours)
**Impact:** ⚡⚡ High (best balance)

**Phase 1: Fix Critical (now)**
1. Align Node versions
2. Add workspace scripts
3. Document workspace architecture

**Phase 2: Add Shared Configs (when TypeScript is added)**
4. Create `config/` package with shared tsconfig
5. Add ESLint shared config (when linting needed)

**Phase 3: Add Build Orchestration (when needed)**
6. Add Turborepo only if builds become slow
7. Keep it simple: no remote cache initially

---

## Specific Recommendations by Priority

### 🔴 Do Now (Critical)

1. **Fix Node Version Mismatch**
   ```json
   // Update cli/package.json
   "engines": {
     "node": ">=18.0.0",  // Match root
     "npm": ">=9.0.0"     // Add npm requirement
   }
   ```

2. **Add Missing Workspace Scripts**
   ```json
   // Root package.json
   "scripts": {
     "dev:app": "npm run dev --workspace=app",
     "dev:cli": "npm run test:workflow --workspace=cli",
     "build:all": "npm run build --workspace=app",
     "test:app": "npm test --workspace=app",
     "test:cli": "npm test --workspace=cli",
     "clean": "rm -rf */dist */node_modules node_modules"
   }
   ```

### 🟡 Do Soon (Medium Priority)

3. **Create Shared Config Directory** (when TypeScript added)
   ```
   config/
   ├── package.json
   ├── tsconfig.base.json
   ├── eslint-config.js
   └── prettier.config.js
   ```

4. **Add Workspace Documentation**
   - Document workspace dependencies in README
   - Add architecture diagram
   - Explain when to use app/ vs cli/

### 🟢 Consider Later (Nice to Have)

5. **Evaluate pnpm Migration** (if installs become slow)
6. **Add Turborepo** (if builds become slow)
7. **Unify Test Framework** (if coverage reporting needed)

---

## Comparison: Current vs Recommended

| Feature | Current | Option A | Option B | Option C |
|---------|---------|----------|----------|----------|
| **Workspace Tool** | npm | npm | pnpm | npm |
| **Build Tool** | None | None | Turborepo | (Later) |
| **Node Version** | ⚠️ Mixed | ✅ Aligned | ✅ Aligned | ✅ Aligned |
| **Shared Configs** | ❌ None | ⚠️ Minimal | ✅ Full | 🔄 Incremental |
| **Test Framework** | Mixed | Mixed | Jest | Mixed → Jest |
| **Dependency Count** | 4 total | 4 total | ~15 total | 4 → 10 |
| **Setup Time** | - | 1-2h | 4-6h | 2-3h |
| **Maintenance** | Low | Low | Medium | Low-Medium |
| **ADHD-Friendly** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐ |

---

## Decision Matrix

### Choose Option A if:
- ✅ You want minimal changes
- ✅ Simplicity is paramount
- ✅ Current setup works fine
- ✅ Project stays small (2-3 workspaces max)

### Choose Option B if:
- ✅ Building a long-term production app
- ✅ Team will grow beyond 1-2 developers
- ✅ Build times are already slow
- ✅ Want professional-grade tooling

### Choose Option C if:
- ✅ Want best of both worlds
- ✅ Willing to add complexity incrementally
- ✅ Unclear on future scale
- ✅ Want to learn gradually (ADHD-friendly!)

---

## Next Steps

### Recommended Path: **Option A** (Minimal Improvements)

**Step 1: Fix Critical Issues (15 min)**
```bash
# 1. Update cli/package.json engines
# 2. Update root package.json scripts
# 3. Test everything still works
npm test
```

**Step 2: Enhance DX (30 min)**
```bash
# Add convenience scripts
# Document workspace architecture
# Update README with monorepo structure
```

**Step 3: Validate (15 min)**
```bash
# Test all new scripts
npm run dev:app
npm run test:cli
npm run build:all
```

**Total Time:** ~1 hour
**Risk:** Very low
**Benefit:** Immediate DX improvement

---

## Resources

- Current setup: [package.json](package.json)
- App workspace: [app/package.json](app/package.json)
- CLI workspace: [cli/package.json](cli/package.json)
- Monorepo skill reference: `/Users/dt/.claude/plugins/cache/claude-code-workflows/developer-essentials/1.0.0/skills/monorepo-management`

---

## Questions to Consider

1. **Do you plan to add TypeScript?** → If yes, create shared config now
2. **Will you add more workspaces?** → If yes, consider Option C
3. **Do builds feel slow?** → If yes, consider Turborepo
4. **Is the CLI staying zero-dependency?** → If yes, keep vanilla tests
5. **Do you want to publish packages to npm?** → If yes, add changesets

---

**Generated:** 2025-12-20
**Auditor:** Claude Sonnet 4.5
**Status:** ✅ Ready for review
