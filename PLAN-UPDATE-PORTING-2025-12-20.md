# Plan Update: Port Functions Instead of Dependency

**Date:** 2025-12-20
**Decision:** Port essential functions from zsh-claude-workflow instead of using as dependency
**Impact:** Makes zsh-configuration truly standalone and npm-installable

---

## What Changed

### Before (Dependency Approach)

- zsh-configuration would **require** zsh-claude-workflow installed
- Users must install both tools
- Symlinks to external libraries
- Enhanced when available, basic fallback otherwise

### After (Porting Approach) ✅

- zsh-configuration is **standalone**
- Port ~300 lines from zsh-claude-workflow to `cli/vendor/`
- No external dependencies required
- Works out-of-box, npm-installable

---

## Why We Changed

**Reasons for Porting:**

1. **npm Package Goal** - Can publish as standalone package
2. **User Experience** - One-command install, no setup
3. **Independence** - No external tool dependencies
4. **Quick Implementation** - Only 3 hours to port vs managing dependency
5. **Clear Attribution** - Vendored code with proper attribution

**Trade-offs Accepted:**

- Manual syncing if upstream zsh-claude-workflow updates (rare)
- ~300 lines of vendored code (small, manageable)
- Both projects continue independently

---

## What We're Porting

### From zsh-claude-workflow (~300 lines total)

**1. project-detector.sh** (~200 lines)
- Detects 8+ project types (R package, Quarto, Node, Python, etc.)
- Smart type detection with file patterns
- Storage awareness (local, Google Drive, OneDrive, Dropbox)

**2. core.sh** (~100 lines)
- Path normalization utilities
- Cloud storage detection
- Shared helper functions

**Total:** ~300 lines of well-tested, production code

### NOT Porting

- Plugin management (not relevant)
- 137+ aliases (user's .zshrc)
- Claude Code commands (separate concern)
- Templates (may add later if needed)
- MkDocs site (separate project)

---

## Updated Architecture

### Directory Structure

```
zsh-configuration/
├── cli/
│   ├── vendor/                          # NEW: Vendored code
│   │   └── zsh-claude-workflow/
│   │       ├── project-detector.sh      # Ported (~200 lines)
│   │       ├── core.sh                  # Ported (~100 lines)
│   │       └── README.md                # Attribution & license
│   ├── lib/
│   │   └── project-detector-bridge.js   # Uses vendored code
│   └── core/
│       └── project-scanner.js           # Calls bridge
```

### Integration Flow

```
project-scanner.js
    ↓
project-detector-bridge.js
    ↓
cli/vendor/zsh-claude-workflow/project-detector.sh
    ↓
detect_project_type() function
    ↓
Returns: "r-package", "quarto", "node", etc.
```

---

## Implementation Steps (3 hours)

### Step 1: Create Vendor Directory (5 min)

```bash
mkdir -p cli/vendor/zsh-claude-workflow
```

### Step 2: Copy Essential Files (10 min)

```bash
cp ~/projects/dev-tools/zsh-claude-workflow/lib/project-detector.sh \
   cli/vendor/zsh-claude-workflow/

cp ~/projects/dev-tools/zsh-claude-workflow/lib/core.sh \
   cli/vendor/zsh-claude-workflow/
```

### Step 3: Create Attribution (15 min)

```bash
cat > cli/vendor/zsh-claude-workflow/README.md << 'EOF'
# Vendored from zsh-claude-workflow

**Source:** https://github.com/Data-Wise/zsh-claude-workflow
**Version:** 1.5.0
**License:** MIT
**Vendored:** 2025-12-20

## Files Included

- `project-detector.sh` - Project type detection (8+ types)
- `core.sh` - Shared utilities (path handling, cloud detection)

## Why Vendored

These functions are copied (vendored) to make zsh-configuration
independently installable via npm without requiring users to
install zsh-claude-workflow separately.

## Attribution

Original work by DT as part of zsh-claude-workflow.
Licensed under MIT. See LICENSE file.

## Sync Process

To update vendored code from upstream:

```bash
cp ~/projects/dev-tools/zsh-claude-workflow/lib/project-detector.sh \
   cli/vendor/zsh-claude-workflow/
cp ~/projects/dev-tools/zsh-claude-workflow/lib/core.sh \
   cli/vendor/zsh-claude-workflow/
```

Check for updates periodically, especially if:
- New project types added
- Bug fixes in detection logic
- Performance improvements
```

EOF
```

### Step 4: Build Bridge (30 min)

```javascript
// cli/lib/project-detector-bridge.js

import { exec } from 'child_process';
import { promisify } from 'util';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const execAsync = promisify(exec);

/**
 * Detect project type using vendored zsh-claude-workflow functions
 * @param {string} projectPath - Absolute path to project
 * @returns {Promise<string>} Project type (r-package, quarto, node, etc.)
 */
export async function detectProjectType(projectPath) {
  const vendoredScript = path.join(
    __dirname,
    '../vendor/zsh-claude-workflow/project-detector.sh'
  );

  try {
    const { stdout } = await execAsync(
      `source ${vendoredScript} && cd "${projectPath}" && detect_project_type`,
      { shell: '/bin/zsh' }
    );
    return stdout.trim();
  } catch (error) {
    console.error(`Failed to detect project type for ${projectPath}:`, error);
    return 'unknown';
  }
}

/**
 * Get list of supported project types
 * @returns {string[]} Array of supported types
 */
export function getSupportedTypes() {
  return [
    'r-package',
    'quarto',
    'research',
    'dev-tool',
    'node',
    'python',
    'spacemacs',
    'generic'
  ];
}
```

### Step 5: Test (1 hour)

```bash
# Test with different project types
node -e "
import('./cli/lib/project-detector-bridge.js').then(async (m) => {
  const types = [
    ['~/projects/r-packages/stable/rmediation', 'r-package'],
    ['~/projects/teaching/stat-440', 'quarto'],
    ['~/projects/dev-tools/aiterm', 'python'],
    ['~/projects/dev-tools/zsh-configuration', 'node']
  ];

  for (const [path, expected] of types) {
    const detected = await m.detectProjectType(path);
    console.log(\`\${path}: \${detected} (expected: \${expected})\`);
  }
});
"
```

### Step 6: Document (1 hour)

- [x] Update ARCHITECTURE-INTEGRATION.md
- [x] Update PROJECT-SCOPE.md
- [x] Update PROJECT-REFOCUS-SUMMARY.md
- [x] Create PROPOSAL-MERGE-OR-PORT.md
- [x] Create this file (PLAN-UPDATE-PORTING-2025-12-20.md)

---

## Updated Week 1 Tasks

**Week 1: Foundation & Porting (Dec 20-27)**

- [x] Create PROJECT-SCOPE.md
- [x] Create ARCHITECTURE-INTEGRATION.md
- [x] Create PROPOSAL-MERGE-OR-PORT.md
- [x] Update documents to reflect porting approach
- [ ] Create directory structure
- [ ] Port zsh-claude-workflow functions (3 hours)
  - [ ] Copy files
  - [ ] Create attribution
  - [ ] Build bridge
  - [ ] Test with 3+ projects
- [ ] Build basic project scanner

**Deliverable:** Can scan all projects and detect types (standalone)

---

## Benefits vs Dependency Approach

| Aspect | Dependency | Porting ✅ |
|--------|-----------|-----------|
| **Installation** | Two packages | One package |
| **npm publish** | Complex | Simple |
| **User setup** | Manual steps | One command |
| **Independence** | Requires external tool | Fully standalone |
| **Maintenance** | Auto-updates | Manual sync (rare) |
| **Code duplication** | None | ~300 lines |
| **Time to implement** | 1 hour | 3 hours |
| **Best for** | Local dev | npm package |

**Winner:** Porting (matches npm package goal)

---

## Maintenance Strategy

### When to Sync with Upstream

**Check for updates if:**
- zsh-claude-workflow releases new version
- New project types added
- Bug fixes in detection logic
- Performance improvements

**How often:** Quarterly (every 3 months) or when needed

### Sync Process

```bash
# 1. Check what changed in upstream
cd ~/projects/dev-tools/zsh-claude-workflow
git log --oneline --since="3 months ago" -- lib/project-detector.sh lib/core.sh

# 2. Review changes
git diff HEAD~10 -- lib/project-detector.sh lib/core.sh

# 3. If relevant, copy new version
cd ~/projects/dev-tools/zsh-configuration
cp ~/projects/dev-tools/zsh-claude-workflow/lib/project-detector.sh cli/vendor/zsh-claude-workflow/
cp ~/projects/dev-tools/zsh-claude-workflow/lib/core.sh cli/vendor/zsh-claude-workflow/

# 4. Test
npm test

# 5. Update version in README
# Update "Version: 1.5.0" → "Version: 1.6.0" in cli/vendor/zsh-claude-workflow/README.md

# 6. Commit
git add cli/vendor/
git commit -m "chore: sync vendored code from zsh-claude-workflow v1.6.0"
```

---

## Attribution & License

### In Package

**cli/vendor/zsh-claude-workflow/README.md:**
- Source repository link
- Version number
- License (MIT)
- Vendoring date
- Sync instructions

**package.json:**
```json
{
  "contributors": [
    "Original zsh-claude-workflow code by DT"
  ],
  "licenses": [
    {
      "type": "MIT",
      "url": "https://github.com/Data-Wise/zsh-claude-workflow/blob/main/LICENSE"
    }
  ]
}
```

**Main README:**
```markdown
## Credits

This project uses vendored code from:
- [zsh-claude-workflow](https://github.com/Data-Wise/zsh-claude-workflow) (MIT)
  - Project detection functions (~300 lines)
  - See `cli/vendor/zsh-claude-workflow/README.md` for details
```

---

## Documentation Updates

### Files Updated

1. **ARCHITECTURE-INTEGRATION.md** ✅
   - Changed "dependency" to "vendor"
   - Updated integration strategy
   - New directory structure with `cli/vendor/`
   - Updated code examples

2. **PROJECT-SCOPE.md** ✅
   - Changed "uses zsh-claude-workflow" to "uses vendored functions"
   - Updated Week 1 tasks
   - Updated prerequisites (no external tools required)
   - Updated installation instructions

3. **PROJECT-REFOCUS-SUMMARY.md** ✅
   - Updated integration table
   - Changed dependency approach to porting

4. **PROPOSAL-DEPENDENCY-MANAGEMENT.md** ✅
   - Created with 6 options analyzed
   - Recommended hybrid approach with porting

5. **PROPOSAL-MERGE-OR-PORT.md** ✅
   - Created detailed analysis
   - Recommended porting approach

---

## Next Steps (Immediate)

### Today (Dec 20)

- [x] Update documentation ✅ COMPLETE
- [ ] Create directory structure
- [ ] Port functions (3 hours)

### This Week (Dec 20-27)

- [ ] Build project-detector-bridge.js
- [ ] Test with 3+ project types
- [ ] Build basic project scanner
- [ ] Update Week 1 checklist

### Next Week (Dec 28 - Jan 3)

- Start Week 2: Session Manager implementation

---

## Questions Answered

**Q: Should we merge zsh-claude-workflow into zsh-configuration?**
A: No, too complex (20 hours), loses focus.

**Q: Should we use zsh-claude-workflow as dependency?**
A: No, makes npm packaging complex, requires external tool.

**Q: Should we port functions?**
A: ✅ Yes! Makes standalone, npm-installable, only 3 hours effort.

**Q: How much code to port?**
A: ~300 lines (project-detector.sh + core.sh)

**Q: What about updates?**
A: Manual sync quarterly or as needed (rare, low effort)

**Q: What about attribution?**
A: Clear README in vendor directory, package.json credits, main README

---

## Success Metrics

### Technical Success

- ✅ Standalone package (no external dependencies)
- ✅ npm-installable (simple one-command install)
- ✅ Works out-of-box (no setup required)
- ✅ Clear attribution (proper credits)

### User Success

- ✅ Easy installation (`npm install -g zsh-configuration`)
- ✅ Fast setup (<5 minutes)
- ✅ Works immediately (no configuration)
- ✅ Reliable (vendored code is stable)

### Developer Success

- ✅ Simple maintenance (sync quarterly)
- ✅ Clear process (documented sync steps)
- ✅ Low risk (vendored code is tested)
- ✅ Flexible (can update anytime)

---

**Status:** ✅ Plan updated to porting approach
**Documentation:** ✅ All files updated
**Next Action:** Create directory structure and port functions (3 hours)
**Timeline:** Week 1 tasks adjusted, 3-month roadmap unchanged
**Decision Confidence:** High (matches npm package goal, low effort, clear benefits)
