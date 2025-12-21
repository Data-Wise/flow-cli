# Architecture & Integration Strategy

**Created:** 2025-12-20
**Purpose:** Define frontend/backend architecture and integration with existing dev-tools packages
**Context:** Project refocus on personal productivity and project management (no MCP hub)

---

## Executive Summary

This document defines how **zsh-configuration** will be architected as a **personal productivity system** that integrates with existing dev-tools packages rather than duplicating their functionality.

**Core Principle:** Port essential functions from existing tools to create a standalone, independently-installable package.

**UPDATE 2025-12-20:** Changed from dependency approach to porting functions. This makes zsh-configuration truly standalone and npm-installable without external dependencies.

---

## 1. Existing Dev-Tools Ecosystem

### Key Packages and Their Capabilities

| Package | Primary Function | Reusable Components | Status |
|---------|------------------|---------------------|--------|
| **zsh-claude-workflow** | Project detection & context | `project-detector.sh`, `claude-context.sh`, templates | ✅ Production |
| **aiterm** | Terminal context switching | Context detection, iTerm2 integration | ✅ 95% complete |
| **apple-notes-sync** | Dashboard generation | `.STATUS` parser, dashboard formatter | ✅ Production |
| **obsidian-cli-ops** | Vault management | ZSH+Python hybrid architecture | ✅ Production |
| **dev-planning** | Coordination hub | Multi-project tracking patterns | ✅ Production |

### Integration Opportunities

#### 1. **zsh-claude-workflow** (PORTED FUNCTIONS)

**What We're Porting:**
- `project-detector.sh` (~200 lines) - Project type detection (8+ types)
- `core.sh` (~100 lines) - Shared utilities (path handling, cloud storage detection)
- Total: ~300 lines of essential code

**Why Porting Instead of Dependency:**
- Makes zsh-configuration standalone (npm-installable)
- No external dependencies required
- Works out-of-box for all users
- Clear attribution to original source

**Where It Goes:**
```
cli/vendor/zsh-claude-workflow/
├── project-detector.sh    # Ported from zsh-claude-workflow
├── core.sh                # Ported from zsh-claude-workflow
└── README.md              # Attribution and license
```

**Usage Code:**
```javascript
// cli/lib/project-detector-bridge.js
import { exec } from 'child_process';
import path from 'path';

const vendoredScript = path.join(__dirname, '../vendor/zsh-claude-workflow/project-detector.sh');

export async function detectProjectType(projectPath) {
  const { stdout } = await execAsync(
    `source ${vendoredScript} && cd "${projectPath}" && detect_project_type`,
    { shell: '/bin/zsh' }
  );
  return stdout.trim();
}
```

#### 2. **apple-notes-sync** (PATTERN REUSE)

**What It Provides:**
- Proven .STATUS file parsing (scanner.sh)
- Dashboard generation patterns
- Multiple output formats (AppleScript, RTF, Markdown)

**How We'll Use It:**
- **Adapt scanner.sh** for multi-project aggregation
- **Reuse dashboard templates** for project overview
- **Extend .STATUS format** with project metadata

**Integration Code:**
```bash
# In zsh-configuration/lib/status-aggregator.sh
# Reuse apple-notes-sync scanner logic
source ~/projects/dev-tools/apple-notes-sync/scanner.sh

aggregate_project_status() {
  local projects=("$@")
  # Scan all projects using existing scanner
  for project in "${projects[@]}"; do
    parse_status_file "$project/.STATUS"
  done
}
```

#### 3. **aiterm** (COMPLEMENTARY TOOL)

**What It Provides:**
- Terminal context switching based on project type
- iTerm2 profile management
- Session-aware environment

**How We'll Use It:**
- **Trigger aiterm** when switching projects
- **Share context detection** logic
- **Coordinate session management**

**Integration Code:**
```zsh
# In zsh-configuration/lib/session-manager.zsh
switch_project() {
  local project="$1"

  # Update session state (our code)
  save_session_state

  # Switch terminal context (aiterm)
  ait context apply "$project"

  # Restore project environment (our code)
  restore_project_context "$project"
}
```

#### 4. **dev-planning** (ORGANIZATIONAL MODEL)

**What It Provides:**
- Domain hub pattern (coordination center for related projects)
- PROJECT-HUB.md structure
- TODOS.md tracking format
- Integration mapping patterns

**How We'll Use It:**
- **Replicate hub structure** for personal projects
- **Adopt .STATUS format** with extensions
- **Use coordination patterns** for dependency tracking

---

## 2. Frontend/Backend Architecture

### What "Frontend" and "Backend" Mean for a CLI Tool

| Layer | Definition | Technologies | Responsibilities |
|-------|------------|--------------|------------------|
| **Frontend** | User interaction layer | ZSH functions, CLI commands | Command parsing, user prompts, output formatting |
| **Backend** | Core logic & data | Node.js modules, JSON files | State persistence, project scanning, data aggregation |
| **Integration** | External tool coordination | Shell scripts, symlinks | Calling zsh-claude-workflow, aiterm, etc. |

### Three-Layer Architecture

```
┌─────────────────────────────────────────────────────────┐
│ FRONTEND LAYER (ZSH Shell)                              │
│ - User commands (work, finish, dashboard, pp)           │
│ - Interactive prompts                                    │
│ - Terminal UI (colored output, tables)                  │
│ - Fzf integration for pickers                           │
└──────────────────┬──────────────────────────────────────┘
                   │ exec(), JSON communication
┌──────────────────▼──────────────────────────────────────┐
│ BACKEND LAYER (Node.js Core)                            │
│ - Session state manager (save/load/restore)             │
│ - Project scanner (find all projects)                   │
│ - Dependency tracker (map relationships)                │
│ - Dashboard generator (aggregate status)                │
│ - Task aggregator (cross-project tasks)                 │
└──────────────────┬──────────────────────────────────────┘
                   │ import/require, shell exec
┌──────────────────▼──────────────────────────────────────┐
│ VENDOR LAYER (Ported Code)                              │
│ - Vendored zsh-claude-workflow functions (~300 lines)   │
│ - Optional aiterm integration (if installed)            │
│ - Adapted apple-notes-sync patterns                     │
└─────────────────────────────────────────────────────────┘
```

### Directory Structure

```
zsh-configuration/
├── cli/                                # Backend (Node.js)
│   ├── core/                          # NEW: Core business logic
│   │   ├── session-manager.js         # Session persistence
│   │   ├── project-scanner.js         # Project discovery
│   │   ├── dependency-tracker.js      # Relationship mapping
│   │   ├── dashboard-generator.js     # Status aggregation
│   │   └── task-aggregator.js         # Cross-project tasks
│   ├── vendor/                        # NEW: Vendored code from external tools
│   │   └── zsh-claude-workflow/       # Ported functions (~300 lines)
│   │       ├── project-detector.sh    # Project type detection
│   │       ├── core.sh                # Shared utilities
│   │       └── README.md              # Attribution & license
│   ├── adapters/                      # Existing: ZSH wrappers
│   │   ├── session-adapter.js         # NEW: Session commands
│   │   ├── dashboard-adapter.js       # NEW: Dashboard commands
│   │   ├── status.js                  # Existing
│   │   └── workflow.js                # Existing
│   ├── api/                           # Existing: Programmatic APIs
│   │   ├── session-api.js             # NEW
│   │   ├── dashboard-api.js           # NEW
│   │   ├── status-api.js              # Existing
│   │   └── workflow-api.js            # Existing
│   └── lib/                           # NEW: Bridges to vendored code
│       ├── project-detector-bridge.js # Uses vendored functions
│       └── aiterm-bridge.js           # Optional aiterm integration
│
├── config/                            # Configuration
│   └── zsh/                           # Frontend (ZSH)
│       ├── functions/                 # ZSH function library
│       │   ├── session-commands.zsh   # NEW: work, finish, switch
│       │   ├── dashboard-commands.zsh # NEW: dashboard, pp
│       │   ├── project-commands.zsh   # NEW: project management
│       │   ├── adhd-helpers.zsh       # Existing: ADHD optimizations
│       │   └── claude-workflows.zsh   # Existing: Claude integration
│       └── completions/               # ZSH tab completions
│
├── data/                              # Data storage
│   ├── sessions/                      # Session state (JSON)
│   │   ├── current.json               # Active session
│   │   └── history/                   # Past sessions
│   ├── projects/                      # Project registry (JSON)
│   │   ├── registry.json              # All known projects
│   │   └── dependencies.json          # Project relationships
│   └── cache/                         # Computed data cache
```

---

## 3. Data Flow Examples

### Example 1: Starting a Session

```
USER: work rmediation
  │
  ▼
[FRONTEND] session-commands.zsh
  │ - Parse "rmediation"
  │ - Call session-adapter.js start
  ▼
[BACKEND] session-adapter.js
  │ - exec() → session-manager.js
  ▼
[BACKEND] session-manager.js
  │ - Call project-detector-bridge.js (→ vendored functions)
  │ - Detect project type: "r-package"
  │ - Load context from CLAUDE.md
  │ - Save to data/sessions/current.json
  │ - Return session state (JSON)
  ▼
[INTEGRATION] aiterm-bridge.js
  │ - Call aiterm to switch terminal context
  ▼
[FRONTEND] session-commands.zsh
  │ - cd to project directory
  │ - Display session info (colored output)
  │ - Show last task from session state
```

**Session State JSON:**
```json
{
  "sessionId": "uuid-12345",
  "projectName": "rmediation",
  "projectPath": "/Users/dt/projects/r-packages/stable/rmediation",
  "projectType": "r-package",
  "startTime": "2025-12-20T10:30:00Z",
  "context": {
    "lastTask": "Fix failing test in test-mediation.R",
    "nextAction": "Update documentation after fix",
    "gitBranch": "main",
    "gitDirty": true
  },
  "metadata": {
    "category": "r-packages",
    "priority": "P0",
    "storage": "local"
  }
}
```

### Example 2: Viewing Dashboard

```
USER: dashboard
  │
  ▼
[FRONTEND] dashboard-commands.zsh
  │ - Call dashboard-adapter.js show
  ▼
[BACKEND] dashboard-adapter.js
  │ - exec() → dashboard-generator.js
  ▼
[BACKEND] dashboard-generator.js
  │ - Call project-scanner.js
  │   │ - Use zsh-claude-workflow/project-detector.sh
  │   │ - Scan ~/projects/** for projects
  │   │ - Return list of 32 projects
  │ - Call status-aggregator (adapted from apple-notes-sync)
  │   │ - Parse each .STATUS file
  │   │ - Extract priority, status, progress, next action
  │ - Generate dashboard JSON
  │ - Return formatted output
  ▼
[FRONTEND] dashboard-commands.zsh
  │ - Render colored tables
  │ - Group by category (R packages, teaching, research)
  │ - Highlight active projects
```

**Dashboard Output:**
```
═══════════════════════════════════════════════
Personal Projects Overview (32 total)
═══════════════════════════════════════════════

R Packages (Active: 3, Paused: 3)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  rmediation    ● 3 hours ago    Fix failing test
  medfit        ● Yesterday      Update vignette
  probmed       ⏸ 3 days ago     Blocked: reviewer feedback

Teaching (Active: 2)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  stat-440      ● Today          Grade HW 5
  causal-inf    ● 2 days ago     Prepare Week 14 lecture

Dev Tools (Active: 5, Archive: 3)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  zsh-config    ● Now            Architecture design
  aiterm        ● 2 days ago     Testing v0.1.0
  obs-cli       ● 4 days ago     Simplification phase

Quick Wins Available: 7 tasks < 30 minutes
Next Review: stat-440 (HW 5 due Friday)
```

---

## 4. Integration Strategy

### Principle: Port Essential Functions, Standalone Package

**Port Critical Code, Adapt Patterns:**

| Feature Needed | Existing Tool | Integration Method |
|----------------|---------------|-------------------|
| Project type detection | zsh-claude-workflow | **Port** project-detector.sh (~200 lines) |
| Shared utilities | zsh-claude-workflow | **Port** core.sh (~100 lines) |
| Terminal switching | aiterm | **Optional** - Call `ait context apply` if installed |
| .STATUS parsing | apple-notes-sync | **Adapt** scanner.sh logic |
| Dashboard templates | apple-notes-sync | **Reuse** RTF/AppleScript patterns |
| ZSH+Node.js hybrid | obsidian-cli-ops | **Copy** architecture pattern |
| Hub organization | dev-planning | **Replicate** PROJECT-HUB.md structure |

### Vendored Code Management

**What We're Vendoring:**
- `cli/vendor/zsh-claude-workflow/project-detector.sh` (~200 lines)
- `cli/vendor/zsh-claude-workflow/core.sh` (~100 lines)
- **Total:** ~300 lines of code from zsh-claude-workflow

**Why Vendoring:**
- ✅ Makes package truly standalone (npm-installable)
- ✅ No external dependencies required
- ✅ Works out-of-box for all users
- ✅ Clear attribution to original source

**Maintenance:**
```bash
# To sync with upstream zsh-claude-workflow (as needed):
cp ~/projects/dev-tools/zsh-claude-workflow/lib/project-detector.sh cli/vendor/zsh-claude-workflow/
cp ~/projects/dev-tools/zsh-claude-workflow/lib/core.sh cli/vendor/zsh-claude-workflow/
```

### Optional Dependencies

**External Tools (Optional Enhancement):**
- **aiterm** (OPTIONAL) - Enhanced terminal context switching
- **apple-notes-sync** (OPTIONAL) - Export dashboard to Apple Notes

**Installation Strategy:**
```bash
# Core package works standalone
npm install -g zsh-configuration

# Optional: Install aiterm for enhanced terminal context
pipx install git+https://github.com/Data-Wise/aiterm

# Optional: Clone apple-notes-sync for Apple Notes export
git clone https://github.com/Data-Wise/apple-notes-sync ~/projects/dev-tools/apple-notes-sync
```

### Vendored Code Usage

**Using ported functions from cli/vendor/:**

```javascript
// cli/lib/project-detector-bridge.js
// Uses vendored zsh-claude-workflow functions

import { exec } from 'child_process';
import { promisify } from 'util';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const execAsync = promisify(exec);

export async function detectProjectType(projectPath) {
  // Use vendored project-detector.sh
  const vendoredScript = path.join(
    __dirname,
    '../vendor/zsh-claude-workflow/project-detector.sh'
  );

  const { stdout } = await execAsync(
    `source ${vendoredScript} && cd "${projectPath}" && detect_project_type`,
    { shell: '/bin/zsh' }
  );

  return stdout.trim();
}
```

---

## 5. What We're Building (Not Duplicating)

### Our Unique Contributions

| Component | Purpose | Why Not Reusing Existing Tool |
|-----------|---------|-------------------------------|
| **Session State Manager** | Persist and restore workflow context | No existing tool handles session state across sessions |
| **Multi-Project Dashboard** | Aggregate status across 30+ projects | apple-notes-sync works per-category, we need global view |
| **Dependency Tracker** | Map project relationships | Unique to multi-project coordination |
| **Task Aggregator** | Cross-project task list | Not covered by any existing tool |
| **Project Picker (pp)** | Fuzzy finder for all projects | Simple but high-value UX improvement |

### What We're NOT Building

| Feature | Why Not | Existing Tool |
|---------|---------|---------------|
| Project type detection | Already solved | zsh-claude-workflow |
| Context gathering | Already solved | zsh-claude-workflow |
| Terminal profile switching | Already solved | aiterm |
| .STATUS file parsing | Already solved | apple-notes-sync |
| CLAUDE.md templates | Already solved | zsh-claude-workflow |

---

## 6. Implementation Phases

### Phase 1: Foundation (Week 1)

**Goal:** Set up architecture and port essential functions

1. **Create directory structure**
   ```bash
   mkdir -p cli/{core,lib,vendor/zsh-claude-workflow} config/zsh/{functions,completions} data/{sessions,projects,cache}
   ```

2. **Port zsh-claude-workflow functions** (3 hours)
   ```bash
   # Copy essential functions to vendor directory
   cp ~/projects/dev-tools/zsh-claude-workflow/lib/project-detector.sh cli/vendor/zsh-claude-workflow/
   cp ~/projects/dev-tools/zsh-claude-workflow/lib/core.sh cli/vendor/zsh-claude-workflow/

   # Create attribution README
   cat > cli/vendor/zsh-claude-workflow/README.md << 'EOF'
   # Vendored from zsh-claude-workflow
   Source: https://github.com/Data-Wise/zsh-claude-workflow
   Version: 1.5.0
   License: MIT
   Vendored: 2025-12-20
   EOF

   # Create bridge module
   # - cli/lib/project-detector-bridge.js (uses vendored functions)
   # - cli/lib/aiterm-bridge.js (optional integration)
   ```

3. **Build project scanner**
   - Use vendored project-detector.sh
   - Scan ~/projects/** recursively
   - Create projects/registry.json
   - Test with 3 different project types

### Phase 2: Session Manager (Week 2)

**Goal:** Basic session persistence and restoration

1. **Core session manager** (`cli/core/session-manager.js`)
   - Save current session state
   - Load previous session
   - List recent sessions

2. **ZSH commands** (`config/zsh/functions/session-commands.zsh`)
   - `work <project>` - Start session
   - `finish [message]` - End session
   - `resume` - Restore last session

3. **Adapter** (`cli/adapters/session-adapter.js`)
   - Bridge between ZSH and Node.js core

### Phase 3: Dashboard (Week 3)

**Goal:** Multi-project status overview

1. **Status aggregator** (adapt from apple-notes-sync)
   - Parse .STATUS files
   - Aggregate across all projects
   - Generate dashboard data

2. **Dashboard generator** (`cli/core/dashboard-generator.js`)
   - Group by category
   - Calculate quick wins
   - Identify next reviews

3. **CLI output** (`config/zsh/functions/dashboard-commands.zsh`)
   - Colored tables
   - Interactive filtering
   - Export to Apple Notes (via apple-notes-sync)

### Phase 4: Project Picker (Week 4)

**Goal:** Fast project navigation

1. **Project finder** (`cli/core/project-scanner.js`)
   - Search by name, type, category
   - Recent projects first
   - Fuzzy matching

2. **Fzf integration** (`config/zsh/functions/project-commands.zsh`)
   - `pp` - Project picker
   - Shows: name, type, last activity, next action
   - Preview pane with .STATUS content

---

## 7. Success Criteria

### Integration Success

✅ **Zero Duplication** - No reimplementation of existing tool features
✅ **Loose Coupling** - Works even if optional tools (aiterm) not installed
✅ **Graceful Degradation** - Falls back to basic features if dependencies missing
✅ **Clear Boundaries** - Well-defined API between our code and external tools

### Architecture Success

✅ **Separation of Concerns** - Frontend (ZSH) → Backend (Node.js) → Integration (External)
✅ **Testable** - Core logic in Node.js modules, easily tested
✅ **Maintainable** - Clear structure, documented APIs
✅ **Extensible** - Easy to add new features or integrate new tools

### User Success

✅ **Fast** - Project switching < 1 minute
✅ **Intuitive** - Commands follow existing patterns (work, finish, dashboard)
✅ **Reliable** - Never lose context, always restorable
✅ **ADHD-Friendly** - Clear output, immediate feedback, low cognitive load

---

## 8. Open Questions

### Technical

1. **Session Storage Location**
   - `~/.zsh-sessions/` vs `~/.local/share/zsh-configuration/`?
   - Recommendation: `~/.local/share/zsh-configuration/sessions/` (XDG-compliant)

2. **Auto-save Frequency**
   - Every command? 15 minutes? On idle?
   - Recommendation: Save on `finish`, auto-save every 15 min, prompt on new shell

3. **Project Discovery Scope**
   - Scan all of ~/projects/ or require manual registration?
   - Recommendation: Auto-scan with manual opt-out (.zsh-ignore file)

### Integration

4. **aiterm Coordination**
   - Should we call aiterm automatically or let user opt-in?
   - Recommendation: Auto-call if installed, silent skip if not

5. **apple-notes-sync Integration**
   - Embed scanner.sh logic or call script?
   - Recommendation: Embed logic (avoid external script dependency)

6. **Dependency Version Pinning**
   - How to handle updates to zsh-claude-workflow?
   - Recommendation: Symlink to latest, document minimum version

---

## 9. Next Immediate Steps

1. **Create directory structure** (5 min)
   ```bash
   cd ~/projects/dev-tools/zsh-configuration
   mkdir -p cli/{core,lib} config/zsh/{functions,completions} data/{sessions,projects,cache} integrations
   ```

2. **Set up zsh-claude-workflow integration** (15 min)
   - Create symlink to lib/
   - Build project-detector-bridge.js
   - Test detection on 3 projects

3. **Build minimal session manager** (1-2 hours)
   - session-manager.js (save/load only)
   - session-adapter.js (ZSH bridge)
   - session-commands.zsh (work/finish)
   - Test with 1 real project

4. **Update documentation** (30 min)
   - Remove MCP hub from PROJECT-SCOPE.md
   - Add this architecture to PROJECT-SCOPE.md
   - Update PROJECT-REFOCUS-SUMMARY.md

---

**Status:** ✅ Architecture defined
**Integration Strategy:** ✅ Leverage existing dev-tools packages
**Frontend/Backend Separation:** ✅ ZSH → Node.js → External Tools
**Next Action:** Create directory structure and set up integrations
