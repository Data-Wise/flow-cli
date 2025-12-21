# Plan: Remove App Workspace & Focus on CLI Development

**Created:** 2025-12-20
**Status:** Ready for execution
**Estimated Time:** 30-45 minutes
**Risk Level:** Low (well-documented removal)

---

## Executive Summary

Remove the Electron app workspace (blocked by environment issues) and refocus the monorepo on CLI development. The CLI workspace is fully functional and provides all the core functionality needed for ZSH workflow management.

**Rationale:**
- App is blocked by Electron installation issue (7 troubleshooting attempts failed)
- CLI workspace is 100% functional and fully tested
- Removing app simplifies the monorepo significantly
- Can revisit desktop app later with Tauri or web-based approach
- All valuable work (753 lines of code) is documented for future reference

---

## What Will Be Removed

### 1. App Workspace Directory
```
app/
├── src/
│   ├── main/
│   │   ├── index.js (2 lines)
│   │   └── main.js (56 lines)
│   ├── preload/
│   │   └── preload.js (17 lines)
│   └── renderer/
│       ├── index.html (142 lines)
│       ├── styles.css (450 lines)
│       └── renderer.js (84 lines)
├── assets/ (empty)
├── package.json
├── README.md
└── APP-CODE-REFERENCE.md (400+ lines)
```

**Total:** 753 lines of code + documentation

### 2. App-Related Scripts
From root `package.json`:
- `dev:app`
- `build:app`
- `build:all` (references app)
- `test:app`
- `clean` (references app/dist)

### 3. App Dependencies
From root `node_modules/` (hoisted):
- `electron` (28.x)
- `electron-builder`
- `jest` (if only used by app)
- `electron-store`

**Total:** ~564 packages (if not used by anything else)

### 4. Documentation References
- References to app workspace in root README.md
- References to P5B/P5D in PROJECT-HUB.md
- App workspace in .STATUS progress bars
- App-related next actions

---

## What Will Be Preserved

### 1. CLI Workspace (Fully Functional)
```
cli/
├── adapters/
│   ├── status.js (174 lines)
│   └── workflow.js (220 lines)
├── api/
│   ├── status-api.js (197 lines)
│   └── workflow-api.js (260 lines)
├── test/
│   └── test-status.js (154 lines)
├── package.json
├── README.md
└── IMPLEMENTATION.md
```

**Status:** 100% functional, fully tested, zero dependencies

### 2. Documentation Archive
All app work will be preserved in `docs/archive/`:
- app/ directory → docs/archive/2025-12-20-app-removal/
- APP-SETUP-STATUS-2025-12-20.md → archive
- APP-CODE-REFERENCE.md → archive

**Reason:** 753 lines of production-ready code may be useful if we revisit desktop app with Tauri

### 3. All Other Documentation
- MONOREPO-AUDIT-2025-12-20.md (still relevant for CLI workspace)
- OPTION-A-IMPLEMENTATION-2025-12-20.md (workspace scripts still useful)
- MONOREPO-COMMANDS-TUTORIAL.md (CLI commands still work)

---

## Step-by-Step Removal Plan

### Phase 1: Archive App Code (10 min)

**Step 1.1: Create Archive Directory**
```bash
mkdir -p docs/archive/2025-12-20-app-removal
```

**Step 1.2: Move App Directory**
```bash
git mv app docs/archive/2025-12-20-app-removal/
```

**Step 1.3: Move App Documentation**
```bash
git mv APP-SETUP-STATUS-2025-12-20.md docs/archive/2025-12-20-app-removal/
# APP-CODE-REFERENCE.md is inside app/, already moved
```

**Step 1.4: Create Archive README**
Create `docs/archive/2025-12-20-app-removal/README.md`:
```markdown
# Electron App - Archived 2025-12-20

This directory contains the Electron desktop app that was developed
but blocked by an Electron environment issue.

## What's Here

- `app/` - Complete Electron app (753 lines, production-ready)
- `APP-SETUP-STATUS-2025-12-20.md` - Comprehensive status report
- `APP-CODE-REFERENCE.md` - Complete code documentation

## Why Archived

The Electron app was blocked by a module resolution issue where
`require('electron')` returned a path string instead of the API object.
After 7 troubleshooting attempts, decided to focus on CLI development.

## Future Options

1. Try manual Electron download
2. Switch to Tauri
3. Build web-based dashboard
4. Continue CLI-only

See APP-SETUP-STATUS-2025-12-20.md for full details.
```

---

### Phase 2: Update Package Configuration (5 min)

**Step 2.1: Update Root package.json**

Remove app workspace and app-related scripts:

```json
{
  "name": "zsh-workflow-manager-cli",
  "version": "0.1.0",
  "description": "ADHD-optimized ZSH workflow CLI tools",
  "private": true,
  "workspaces": [
    "cli"
  ],
  "scripts": {
    "setup": "./scripts/setup.sh",
    "sync": "./scripts/sync-zsh.sh",
    "dev": "npm run dev --workspace=cli",
    "test": "npm test --workspace=cli",
    "clean": "rm -rf cli/node_modules node_modules",
    "reset": "npm run clean && npm install"
  },
  "keywords": [
    "zsh",
    "workflow",
    "adhd",
    "productivity",
    "shell",
    "cli"
  ],
  "author": "Your Name",
  "license": "MIT",
  "repository": {
    "type": "git",
    "url": "https://github.com/yourusername/zsh-configuration"
  },
  "engines": {
    "node": ">=18.0.0",
    "npm": ">=9.0.0"
  }
}
```

**Changes:**
- Rename: `zsh-workflow-manager-monorepo` → `zsh-workflow-manager-cli`
- Description: Focus on CLI
- Workspaces: Remove `"app"`
- Remove: `dev:app`, `test:app`, `build:app`, `build:all`, `build`
- Simplify: `dev` → run CLI dev, `test` → run CLI test
- Update: `clean` → remove app references
- Keywords: Remove `electron`, add `cli`

**Step 2.2: Remove App Dependencies**

```bash
npm uninstall electron electron-builder jest electron-store
```

**Note:** Only remove if not used elsewhere. Check first:
```bash
npm list electron electron-builder jest electron-store
```

---

### Phase 3: Update Documentation (15 min)

**Step 3.1: Update README.md**

**Current:** Describes dual CLI/app project
**New:** Focus on CLI-only

Key changes:
- Remove app workspace description
- Remove P5 desktop app phases
- Update "Quick Start" to CLI commands only
- Simplify project structure diagram
- Update "What's Inside" section

**Step 3.2: Update PROJECT-HUB.md**

Update phase descriptions:
- ~~P5A: Project Reorganization~~ → ARCHIVED (app-focused)
- ~~P5B: Core UI Components~~ → ARCHIVED (app-focused)
- ~~P5C: CLI Integration~~ → COMPLETE (CLI already integrated)
- ~~P5D: Alpha Release~~ → ARCHIVED (app-focused)

Add new phase:
- **P6: CLI Enhancement** → Active (focus on CLI features)

**Step 3.3: Update .STATUS**

Remove app progress bars:
```
Phase P5A: Project Reorganization → ARCHIVED
Phase P5B: Core UI Components → ARCHIVED
Phase P5C: CLI Integration → COMPLETE (standalone CLI)
Phase P5D: Alpha Release → ARCHIVED
```

Add CLI-focused next actions:
```
📋 NEXT ACTIONS

A) **Enhance CLI Status Command** [est. 1-2 hours]
   - Add real-time status updates
   - Integrate with worklog
   - Display recent commands
   - Show git status

B) **Build Web Dashboard** [est. 2-3 hours]
   - HTML/CSS dashboard using renderer code
   - Serve via http.server
   - No Electron needed
   - Use CLI APIs for data
```

**Step 3.4: Update CLAUDE.md**

Remove app workspace references:
- Remove app/ from structure
- Remove P5 phase descriptions
- Update to single-workspace project
- Add note about archived app code

**Step 3.5: Update Monorepo Audit Documents**

Add note to top of each:
```markdown
**UPDATE 2025-12-20:** App workspace has been removed. This audit
remains relevant for the CLI workspace structure and package management.
See docs/archive/2025-12-20-app-removal/ for app code.
```

---

### Phase 4: Clean Up File System (5 min)

**Step 4.1: Remove node_modules (if app-only deps)**

```bash
# Only if electron, electron-builder, jest are gone
npm run clean
npm install
```

**Step 4.2: Verify Directory Structure**

```bash
tree -L 2 -I 'node_modules|.git'
```

Expected structure:
```
.
├── cli/
├── docs/
│   ├── archive/
│   │   └── 2025-12-20-app-removal/
│   ├── user/
│   ├── reference/
│   └── ...
├── config/
├── scripts/
├── tests/
├── package.json
├── README.md
├── PROJECT-HUB.md
├── .STATUS
└── CLAUDE.md
```

**Step 4.3: Test CLI Functionality**

```bash
# Verify CLI still works
npm run dev
npm run test
```

Expected output:
```
═══════════════════════════════════════════════
  ZSH Workflow CLI - Status Tests
═══════════════════════════════════════════════
✅ All status tests passed!
```

---

### Phase 5: Update Git (5 min)

**Step 5.1: Stage All Changes**

```bash
git add -A
```

**Step 5.2: Review Changes**

```bash
git status
```

Expected:
- Renamed: app/ → docs/archive/2025-12-20-app-removal/app/
- Modified: package.json, README.md, PROJECT-HUB.md, .STATUS, CLAUDE.md
- Deleted: (possibly some node_modules if uninstalled)
- New: docs/archive/2025-12-20-app-removal/README.md

**Step 5.3: Commit**

```bash
git commit -m "refactor: remove app workspace, focus on CLI development

- Archived Electron app (blocked by environment issue)
- Removed app workspace from monorepo
- Updated all documentation to CLI-only focus
- Preserved all app code in docs/archive/2025-12-20-app-removal/
- CLI workspace remains fully functional

Rationale: After 7 troubleshooting attempts, Electron environment
issue remains unresolved. Focusing on fully-functional CLI development.
App code preserved for potential future Tauri/web implementation.

Files archived:
- app/ (753 lines of production-ready code)
- APP-SETUP-STATUS-2025-12-20.md
- APP-CODE-REFERENCE.md

🤖 Generated with Claude Code"
```

---

## Post-Removal Benefits

### Simplified Structure

**Before (Dual Workspace):**
- 2 workspaces (app, cli)
- 564 packages (mostly Electron)
- Complex build orchestration
- Blocked development path

**After (CLI-Only):**
- 1 workspace (cli)
- 0 dependencies (vanilla Node.js)
- Simple, focused development
- Clear path forward

### Reduced Complexity

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| Workspaces | 2 | 1 | -50% |
| Dependencies | 564 | 0 | -100% |
| node_modules size | ~200MB | ~0MB | -100% |
| npm scripts | 13 | 6 | -54% |
| Blocked features | 1 (app) | 0 | ✅ |
| Working features | 1 (CLI) | 1 (CLI) | ✅ |

### Clearer Focus

**Before:**
- "Should we fix Electron or move on?"
- Two development paths (app vs CLI)
- Split documentation
- Uncertain roadmap

**After:**
- Clear focus: CLI development
- One development path
- Unified documentation
- Clear roadmap (CLI enhancements)

---

## Future Desktop App Options

### Option 1: Tauri (Recommended)

**Pros:**
- Modern Rust-based framework
- Smaller binaries (~600KB vs 80MB)
- Better security model
- Active development
- No npm package issues

**Cons:**
- Requires Rust installation
- Different API from Electron
- Smaller ecosystem

**Effort:** 2-4 hours to port existing renderer code

### Option 2: Web-Based Dashboard

**Pros:**
- Reuse existing HTML/CSS/JS (renderer code)
- No installation needed
- Works everywhere (browser)
- Simple Python/Node server

**Cons:**
- Not a "desktop app"
- Limited system access
- Requires server running

**Effort:** 1-2 hours to adapt renderer code

### Option 3: Manual Electron Download

**Pros:**
- Bypasses npm package issues
- Uses existing code as-is

**Cons:**
- Manual setup required
- Not reproducible
- Still might not work

**Effort:** 10-30 minutes to test

---

## CLI Development Roadmap

### Immediate (Week 1)

**P6A: Enhanced Status Command**
- Real-time worklog integration
- Recent command history
- Git status display
- Session duration tracking

**Estimated:** 1-2 hours

### Short-Term (Week 2-3)

**P6B: Interactive CLI Dashboard**
- TUI (Text User Interface) with blessed/ink
- Live-updating status
- Keyboard shortcuts
- Command palette

**Estimated:** 3-4 hours

### Medium-Term (Month 1)

**P6C: Advanced Workflow Features**
- Session templates
- Custom workflows
- Workflow history
- Analytics/insights

**Estimated:** 4-6 hours

### Long-Term (Month 2+)

**P6D: Web Dashboard**
- Reuse renderer HTML/CSS
- REST API for CLI data
- WebSocket for live updates
- Mobile-friendly

**Estimated:** 4-6 hours

---

## Risk Assessment

### Risks

1. **Lost Work**
   - **Mitigation:** All code archived in docs/archive/
   - **Impact:** Low (fully documented)

2. **Breaking Changes**
   - **Mitigation:** CLI workspace unchanged
   - **Impact:** None (CLI unaffected)

3. **Documentation Out of Date**
   - **Mitigation:** Update all docs in Phase 3
   - **Impact:** Low (comprehensive updates)

4. **Regret Decision**
   - **Mitigation:** Easy to restore from archive
   - **Impact:** Low (reversible)

### Validation Checklist

Before proceeding, verify:
- [ ] CLI tests pass (`npm run test`)
- [ ] All app code is valuable (might reuse)
- [ ] Archive location is appropriate
- [ ] Documentation updates are complete
- [ ] Git commit message is clear

---

## Success Criteria

**Project is simplified if:**
- ✅ Only one workspace remains (cli/)
- ✅ All npm scripts work
- ✅ CLI tests pass
- ✅ Documentation is updated
- ✅ Git history preserved
- ✅ Archive is complete

**Focus is clear if:**
- ✅ README describes CLI-only project
- ✅ Next actions are CLI-focused
- ✅ No references to blocked app development
- ✅ Roadmap shows CLI enhancements

---

## Rollback Plan

If issues arise, rollback is simple:

```bash
# Restore app workspace
git mv docs/archive/2025-12-20-app-removal/app ./app

# Restore package.json
git checkout HEAD -- package.json

# Reinstall dependencies
npm install

# Verify
npm run test:app
```

---

## Timeline

| Phase | Tasks | Time | Can Pause? |
|-------|-------|------|------------|
| 1. Archive | Move files, create README | 10 min | ✅ Yes |
| 2. Package Config | Update package.json, uninstall deps | 5 min | ✅ Yes |
| 3. Documentation | Update 5 docs | 15 min | ✅ Yes |
| 4. Clean Up | Verify structure, test CLI | 5 min | ❌ No |
| 5. Git Commit | Stage, review, commit | 5 min | ❌ No |

**Total:** 30-45 minutes
**Critical Path:** Phases 4-5 (should complete together)

---

## Execution Command Summary

```bash
# Phase 1: Archive
mkdir -p docs/archive/2025-12-20-app-removal
git mv app docs/archive/2025-12-20-app-removal/
git mv APP-SETUP-STATUS-2025-12-20.md docs/archive/2025-12-20-app-removal/
# Create archive README (see Phase 1.4)

# Phase 2: Package Config
# Edit package.json (see Step 2.1)
npm uninstall electron electron-builder jest electron-store

# Phase 3: Documentation
# Edit README.md, PROJECT-HUB.md, .STATUS, CLAUDE.md (see Phase 3)

# Phase 4: Clean Up
npm run clean
npm install
npm run test

# Phase 5: Git
git add -A
git status
git commit -m "refactor: remove app workspace, focus on CLI development..."
```

---

## Questions to Answer Before Proceeding

1. **Do you want to keep any app dependencies?**
   - electron, electron-builder, jest, electron-store
   - Recommendation: Remove all (CLI doesn't need them)

2. **Do you want to update .gitignore?**
   - Remove app-specific ignores
   - Recommendation: Clean up while we're at it

3. **Do you want to archive or delete?**
   - Archive: Keep in docs/archive/ (reversible)
   - Delete: Remove entirely (cleaner but permanent)
   - Recommendation: Archive (preserve work)

4. **Do you want to rename the project?**
   - Current: zsh-workflow-manager-monorepo
   - Suggested: zsh-workflow-manager-cli
   - Recommendation: Yes (reflects CLI focus)

---

**Status:** ✅ Plan complete, ready for execution
**Recommendation:** Archive (don't delete), focus on CLI
**Next Step:** Review plan, then execute Phase 1
