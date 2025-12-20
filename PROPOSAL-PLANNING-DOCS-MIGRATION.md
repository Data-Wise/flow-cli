# [BRAINSTORM] Planning Docs Migration to Project-Hub

**Date:** 2025-12-19
**Status:** Brainstorm / Proposal
**Context:** After implementing standards sync, consider centralizing planning documentation

---

## 🎯 The Vision

Migrate project-specific planning docs from zsh-configuration to project-hub, establishing project-hub as the central planning coordination center.

```
Current State:
~/projects/dev-tools/zsh-configuration/
    ├── 30+ planning/proposal/session docs
    ├── PROJECT-HUB.md (zsh-configuration specific)
    └── standards/ (synced to other hubs)

Proposed State:
~/projects/project-hub/
    ├── planning/         ← NEW: Planning docs
    ├── proposals/        ← NEW: Proposals
    ├── sessions/         ← NEW: Session summaries
    ├── standards/        ✅ Already synced
    └── PROJECT-HUB.md    ← Enhanced master hub

~/projects/dev-tools/zsh-configuration/
    ├── PROJECT-HUB.md (project-specific control file)
    └── standards/ (source of truth, synced out)
```

---

## 📊 Current State Analysis

### Planning Docs in zsh-configuration

**Count:** ~30 markdown files

**Categories:**

1. **Proposals (14 files):**
   - PROPOSAL-DISPATCHER-CONSOLIDATION-FINAL.md
   - PROPOSAL-DISPATCHER-REFACTORING-V2.md
   - PROPOSAL-DISPATCHER-REFACTORING.md
   - PROPOSAL-FILE-REORGANIZATION.md
   - PROPOSAL-INTERACTIVE-CLEANUP.md
   - PROPOSAL-PICK-COMMAND-ENHANCEMENT.md
   - PROPOSAL-PICK-ENHANCEMENTS.md
   - PROPOSAL-PICK-RECENT-SECTION.md
   - PROPOSAL-STANDARDS-SYNC.md ⭐ Most recent

2. **Session Summaries (3 files):**
   - SESSION-SUMMARY-2025-12-18-PART2.md
   - SESSION-SUMMARY-2025-12-18.md
   - SESSION-SUMMARY-2025-12-19.md ⭐ Today

3. **Completion Reports (10 files):**
   - AGENT4-COMPLETION-REPORT.md
   - ALIAS-CLEANUP-BEFORE-AFTER.md
   - ALIAS-CLEANUP-FINDINGS.md
   - ALIAS-CLEANUP-INDEX.md
   - ALIAS-CLEANUP-PLAN.md
   - ALIAS-CLEANUP-SUMMARY-2025-12-19.md
   - DISPATCHER-CONSOLIDATION-PROGRESS.md
   - DISPATCHER-ENHANCEMENTS-SUMMARY.md
   - IMPLEMENTATION-COMPLETE.md
   - STANDARDS-SYNC-IMPLEMENTATION.md ⭐ Just created

4. **Active Planning (3 files):**
   - NEXT-SESSION.md
   - DELETION-PLAN-2025-12-19.md
   - WORKFLOW-OPTIONS-CLEANUP.md

5. **Control Files (1 file):**
   - PROJECT-HUB.md (zsh-configuration specific)

**Total:** ~30 files, ~400KB of planning documentation

### Central Planning Hub

**Location:** `/Users/dt/projects/.planning/`

**Current files:**
- NOW.md
- ROADMAP.md
- PACKAGES.md
- PROJECTS.md
- PM-FILE-MANAGEMENT-COMPLETE.md
- archive/ folder with historical docs

**Purpose:** Cross-project coordination, not project-specific planning

### Project-Hub Structure

**Location:** `~/projects/project-hub/`

**Current:**
```
project-hub/
├── .STATUS
├── PROJECT-HUB.md (master coordination)
├── README.md
├── GETTING-STARTED.md
├── domains/
│   ├── research.md
│   └── teaching.md
├── cross-domain/
│   └── INTEGRATIONS.md
├── weekly/
│   └── WEEK-51.md
├── reference/
└── standards/ ✅ Just synced
```

**Note:** No planning/, proposals/, or sessions/ folders yet

---

## 🎨 Proposed Structure

### Option A: Centralize in Project-Hub (Recommended)

**Create new structure in project-hub:**

```
~/projects/project-hub/
├── .STATUS
├── PROJECT-HUB.md (enhanced master hub)
├── README.md
├── GETTING-STARTED.md
│
├── planning/                        ← NEW
│   ├── active/                      # Current planning
│   │   ├── NEXT-SESSION.md
│   │   └── [active plans]
│   └── archive/                     # Completed plans
│       ├── 2025-12/
│       │   ├── alias-cleanup/
│       │   ├── dispatcher-work/
│       │   └── standards-sync/
│       └── [older months]
│
├── proposals/                       ← NEW
│   ├── active/                      # Under consideration
│   │   └── [active proposals]
│   └── implemented/                 # Completed
│       ├── 2025-12/
│       │   ├── PROPOSAL-STANDARDS-SYNC.md
│       │   └── [other Dec proposals]
│       └── [older months]
│
├── sessions/                        ← NEW
│   ├── 2025-12/
│   │   ├── SESSION-SUMMARY-2025-12-19.md
│   │   ├── SESSION-SUMMARY-2025-12-18.md
│   │   └── SESSION-SUMMARY-2025-12-18-PART2.md
│   └── [older months]
│
├── projects/                        ← NEW
│   ├── zsh-configuration/
│   │   ├── PROJECT-HUB.md           # Moved from zsh-config
│   │   ├── planning/
│   │   │   ├── ALIAS-CLEANUP-SUMMARY-2025-12-19.md
│   │   │   ├── DISPATCHER-ENHANCEMENTS-SUMMARY.md
│   │   │   └── STANDARDS-SYNC-IMPLEMENTATION.md
│   │   └── archive/
│   │       ├── alias-cleanup/
│   │       ├── dispatcher-work/
│   │       └── older-work/
│   ├── mediation-planning/
│   │   └── [planning docs for mediation-planning hub]
│   └── dev-planning/
│       └── [planning docs for dev-planning hub]
│
├── domains/                         ✅ Existing
│   ├── research.md
│   └── teaching.md
│
├── cross-domain/                    ✅ Existing
│   └── INTEGRATIONS.md
│
├── weekly/                          ✅ Existing
│   └── WEEK-51.md
│
├── reference/                       ✅ Existing
│
└── standards/                       ✅ Existing (just synced)
    └── [synced from zsh-configuration]
```

**Benefits:**
- ✅ Single location for ALL planning across ALL projects
- ✅ Easy to find planning docs for any project
- ✅ Consistent structure (planning/, proposals/, sessions/)
- ✅ Historical tracking by month
- ✅ project-hub becomes true "command center"

**Cons:**
- ❌ Requires migration of ~30 files
- ❌ Need to update references in zsh-configuration docs
- ❌ More complex structure

---

### Option B: Hybrid Approach

**Keep zsh-configuration planning local, centralize only cross-project:**

```
~/projects/project-hub/
├── cross-project/                   ← NEW
│   ├── planning/
│   │   └── STANDARDS-SYNC-IMPLEMENTATION.md
│   ├── proposals/
│   │   └── PROPOSAL-STANDARDS-SYNC.md
│   └── sessions/
│       └── SESSION-SUMMARY-2025-12-19.md (only if cross-project)
│
└── [existing structure]

~/projects/dev-tools/zsh-configuration/
├── planning/                        ← NEW (keep local)
│   ├── ALIAS-CLEANUP-SUMMARY-2025-12-19.md
│   ├── DISPATCHER-ENHANCEMENTS-SUMMARY.md
│   └── [other zsh-specific docs]
└── [existing files]
```

**Benefits:**
- ✅ Less migration work
- ✅ Project-specific planning stays with project
- ✅ Only cross-project docs centralized

**Cons:**
- ❌ Still scattered across repos
- ❌ Less unified view
- ❌ Hard to track overall progress

**Verdict:** 🟡 Easier but less organized

---

### Option C: Use .planning/ as True Central Hub

**Enhance `/Users/dt/projects/.planning/` instead of project-hub:**

```
~/projects/.planning/
├── NOW.md                           ✅ Existing
├── ROADMAP.md                       ✅ Existing
├── PACKAGES.md                      ✅ Existing
├── PROJECTS.md                      ✅ Existing
│
├── projects/                        ← NEW
│   ├── zsh-configuration/
│   │   ├── planning/
│   │   ├── proposals/
│   │   └── sessions/
│   ├── mediation-planning/
│   └── dev-planning/
│
└── archive/                         ✅ Existing
    └── [historical docs]
```

**Benefits:**
- ✅ `.planning/` already exists for cross-project coordination
- ✅ Natural fit for planning docs
- ✅ Separate from project-hub (which is more strategic)

**Cons:**
- ❌ `.planning/` is hidden folder (harder to discover)
- ❌ Not git-tracked (no history)
- ❌ Project-hub becomes less useful

**Verdict:** 🟡 Logical but hidden

---

## 🚀 Recommended Approach

**Go with Option A (Centralize in Project-Hub) with phased migration:**

### Why Project-Hub?

1. **Already established** as coordination center
2. **Git-tracked** (version history for planning docs)
3. **Visible** (not hidden like .planning/)
4. **Structured** (domains/, cross-domain/, weekly/ already exist)
5. **Standards already there** (just synced standards/)

### Phased Migration Plan

**Phase 1: Set Up Structure (30 min)**
```bash
# Create new folders
mkdir -p ~/projects/project-hub/planning/{active,archive}
mkdir -p ~/projects/project-hub/proposals/{active,implemented}
mkdir -p ~/projects/project-hub/sessions/2025-12
mkdir -p ~/projects/project-hub/projects/zsh-configuration/{planning,archive}

# Create index files
cat > ~/projects/project-hub/planning/README.md << 'EOF'
# Planning Documentation

## Active Planning
Current planning documents for ongoing work.

## Archive
Completed planning documents organized by date.
EOF

cat > ~/projects/project-hub/proposals/README.md << 'EOF'
# Proposals

## Active
Proposals under consideration.

## Implemented
Completed and implemented proposals organized by date.
EOF
```

**Phase 2: Migrate Recent Work (1 hour)**

**Priority 1: Active/Recent (Move first)**
```bash
# Session summaries (most recent)
mv ~/projects/dev-tools/zsh-configuration/SESSION-SUMMARY-2025-12-*.md \
   ~/projects/project-hub/sessions/2025-12/

# Recent proposals
mv ~/projects/dev-tools/zsh-configuration/PROPOSAL-STANDARDS-SYNC.md \
   ~/projects/project-hub/proposals/implemented/2025-12/

# Recent implementation docs
mv ~/projects/dev-tools/zsh-configuration/STANDARDS-SYNC-IMPLEMENTATION.md \
   ~/projects/project-hub/projects/zsh-configuration/planning/

# Active planning
mv ~/projects/dev-tools/zsh-configuration/NEXT-SESSION.md \
   ~/projects/project-hub/planning/active/
```

**Priority 2: Project-Specific Summaries**
```bash
# Alias cleanup docs (group together)
mkdir -p ~/projects/project-hub/projects/zsh-configuration/archive/alias-cleanup-2025-12
mv ~/projects/dev-tools/zsh-configuration/ALIAS-CLEANUP-*.md \
   ~/projects/project-hub/projects/zsh-configuration/archive/alias-cleanup-2025-12/

# Dispatcher work (group together)
mkdir -p ~/projects/project-hub/projects/zsh-configuration/archive/dispatcher-work-2025-12
mv ~/projects/dev-tools/zsh-configuration/DISPATCHER-*.md \
   ~/projects/project-hub/projects/zsh-configuration/archive/dispatcher-work-2025-12/
mv ~/projects/dev-tools/zsh-configuration/PROPOSAL-DISPATCHER-*.md \
   ~/projects/project-hub/projects/zsh-configuration/archive/dispatcher-work-2025-12/
```

**Priority 3: Older Proposals (Archive)**
```bash
# Pick command proposals
mkdir -p ~/projects/project-hub/projects/zsh-configuration/archive/pick-enhancements-2025-12
mv ~/projects/dev-tools/zsh-configuration/PROPOSAL-PICK-*.md \
   ~/projects/project-hub/projects/zsh-configuration/archive/pick-enhancements-2025-12/

# Other completed work
mkdir -p ~/projects/project-hub/projects/zsh-configuration/archive/misc-2025-12
mv ~/projects/dev-tools/zsh-configuration/{IMPLEMENTATION-COMPLETE,QUICK-WINS-IMPLEMENTED,TASK-2-3-COMPLETION}.md \
   ~/projects/project-hub/projects/zsh-configuration/archive/misc-2025-12/
```

**Phase 3: Update References (30 min)**

```bash
# In zsh-configuration docs, update links:
# Before: See PROPOSAL-STANDARDS-SYNC.md
# After:  See ~/projects/project-hub/proposals/implemented/2025-12/PROPOSAL-STANDARDS-SYNC.md

# Or use relative path:
# After:  See ../../../project-hub/proposals/implemented/2025-12/PROPOSAL-STANDARDS-SYNC.md
```

**Phase 4: Create Index (15 min)**

```bash
# Create master index in project-hub
cat > ~/projects/project-hub/PLANNING-INDEX.md << 'EOF'
# Planning Documentation Index

## Quick Links

| Resource | Location |
|----------|----------|
| **Current Planning** | [planning/active/](planning/active/) |
| **Recent Sessions** | [sessions/2025-12/](sessions/2025-12/) |
| **Active Proposals** | [proposals/active/](proposals/active/) |
| **Project Planning** | [projects/](projects/) |

## By Project

### ZSH Configuration
- [Planning](projects/zsh-configuration/planning/)
- [Archive](projects/zsh-configuration/archive/)

### Mediation Planning
- [Planning](projects/mediation-planning/planning/)

### Dev Planning
- [Planning](projects/dev-planning/planning/)

## Recent Work

See [sessions/2025-12/](sessions/2025-12/) for latest session summaries.
EOF
```

---

## 📋 Migration Script

**Create automated migration script:**

```bash
#!/bin/bash
# Migrate planning docs from zsh-configuration to project-hub
# Location: ~/projects/project-hub/scripts/migrate-planning-docs.sh

set -e

SOURCE="$HOME/projects/dev-tools/zsh-configuration"
DEST="$HOME/projects/project-hub"

echo "🔄 Migrating planning docs to project-hub..."
echo "📦 Source: $SOURCE"
echo "📍 Destination: $DEST"
echo ""

# Phase 1: Create structure
echo "📁 Creating folder structure..."
mkdir -p "$DEST/planning/"{active,archive}
mkdir -p "$DEST/proposals/"{active,implemented/2025-12}
mkdir -p "$DEST/sessions/2025-12"
mkdir -p "$DEST/projects/zsh-configuration/"{planning,archive}
mkdir -p "$DEST/projects/zsh-configuration/archive/"{alias-cleanup-2025-12,dispatcher-work-2025-12,pick-enhancements-2025-12,misc-2025-12}

# Phase 2: Move files
echo "📦 Moving session summaries..."
mv "$SOURCE"/SESSION-SUMMARY-2025-12-*.md "$DEST/sessions/2025-12/" 2>/dev/null || true

echo "📦 Moving recent proposals..."
mv "$SOURCE/PROPOSAL-STANDARDS-SYNC.md" "$DEST/proposals/implemented/2025-12/" 2>/dev/null || true

echo "📦 Moving implementation docs..."
mv "$SOURCE/STANDARDS-SYNC-IMPLEMENTATION.md" "$DEST/projects/zsh-configuration/planning/" 2>/dev/null || true

echo "📦 Moving active planning..."
mv "$SOURCE/NEXT-SESSION.md" "$DEST/planning/active/" 2>/dev/null || true

echo "📦 Moving alias cleanup docs..."
mv "$SOURCE"/ALIAS-CLEANUP-*.md "$DEST/projects/zsh-configuration/archive/alias-cleanup-2025-12/" 2>/dev/null || true

echo "📦 Moving dispatcher docs..."
mv "$SOURCE"/DISPATCHER-*.md "$DEST/projects/zsh-configuration/archive/dispatcher-work-2025-12/" 2>/dev/null || true
mv "$SOURCE"/PROPOSAL-DISPATCHER-*.md "$DEST/projects/zsh-configuration/archive/dispatcher-work-2025-12/" 2>/dev/null || true

echo "📦 Moving pick enhancement docs..."
mv "$SOURCE"/PROPOSAL-PICK-*.md "$DEST/projects/zsh-configuration/archive/pick-enhancements-2025-12/" 2>/dev/null || true
mv "$SOURCE/PROPOSAL-PICK-ENHANCEMENTS_files" "$DEST/projects/zsh-configuration/archive/pick-enhancements-2025-12/" 2>/dev/null || true

echo "📦 Moving misc completion docs..."
mv "$SOURCE"/{IMPLEMENTATION-COMPLETE,QUICK-WINS-IMPLEMENTED,TASK-2-3-COMPLETION}.md "$DEST/projects/zsh-configuration/archive/misc-2025-12/" 2>/dev/null || true
mv "$SOURCE"/{AGENT4-COMPLETION-REPORT,EXECUTION-SUMMARY-2025-12-19,WORKFLOW-OPTIONS-CLEANUP}.md "$DEST/projects/zsh-configuration/archive/misc-2025-12/" 2>/dev/null || true

echo "📦 Moving other planning docs..."
mv "$SOURCE/DELETION-PLAN-2025-12-19.md" "$DEST/projects/zsh-configuration/archive/misc-2025-12/" 2>/dev/null || true
mv "$SOURCE/PROPOSAL-FILE-REORGANIZATION.md" "$DEST/projects/zsh-configuration/archive/misc-2025-12/" 2>/dev/null || true
mv "$SOURCE/PROPOSAL-INTERACTIVE-CLEANUP.md" "$DEST/projects/zsh-configuration/archive/misc-2025-12/" 2>/dev/null || true

# Phase 3: Create indices
echo "📝 Creating index files..."

cat > "$DEST/planning/README.md" << 'EOF'
# Planning Documentation

## Active Planning
Current planning documents for ongoing work.

## Archive
Completed planning documents organized by date.
EOF

cat > "$DEST/proposals/README.md" << 'EOF'
# Proposals

## Active
Proposals under consideration.

## Implemented
Completed and implemented proposals organized by date.
EOF

cat > "$DEST/sessions/README.md" << 'EOF'
# Session Summaries

Chronological record of work sessions across all projects.

## Recent Sessions
- [2025-12/](2025-12/) - December 2025 sessions
EOF

cat > "$DEST/projects/zsh-configuration/README.md" << 'EOF'
# ZSH Configuration Planning

Planning and historical documentation for zsh-configuration project.

## Current
- [planning/](planning/) - Active planning documents

## Historical
- [archive/](archive/) - Completed work organized by topic
EOF

# Summary
echo ""
echo "✅ Migration complete!"
echo ""
echo "📊 Summary:"
echo "  - Created folder structure in project-hub"
echo "  - Moved ~30 planning docs from zsh-configuration"
echo "  - Organized into: planning/, proposals/, sessions/, projects/"
echo "  - Created README.md indices in each section"
echo ""
echo "📝 Next steps:"
echo "  1. Review migrated files in project-hub"
echo "  2. Update any references in zsh-configuration docs"
echo "  3. Commit changes to both repos"
echo "  4. Update PROJECT-HUB.md with new structure"
```

---

## 🎯 Benefits of Migration

### 1. Centralized Planning
- **One location** for all project planning across entire ecosystem
- Easy to find planning docs for any project
- Consistent structure across all projects

### 2. Better Organization
- **Chronological tracking** (sessions by month)
- **Topic grouping** (alias cleanup, dispatcher work, etc.)
- **Clear separation** (active vs archive, proposals vs implementation)

### 3. Historical Context
- **Easy to review** what was done when
- **Learn from past** decisions and proposals
- **Track evolution** of project over time

### 4. Enhanced Project-Hub
- Becomes true "command center" for ALL work
- Not just coordination, but planning hub
- Aligns with name "project-hub"

### 5. Cleaner zsh-configuration
- Repo focuses on code and documentation
- Planning docs don't clutter project root
- Easier to find actual zsh configuration files

---

## ⚠️ Potential Issues

### Issue 1: Broken Links

**Problem:** Docs in zsh-configuration may reference moved files

**Solution:**
```bash
# Find all references
grep -r "PROPOSAL-STANDARDS-SYNC" ~/projects/dev-tools/zsh-configuration/

# Update to relative paths
# Before: See PROPOSAL-STANDARDS-SYNC.md
# After:  See ~/projects/project-hub/proposals/implemented/2025-12/PROPOSAL-STANDARDS-SYNC.md
```

### Issue 2: Git History Loss

**Problem:** Moving files loses git history

**Solution:**
```bash
# Use git mv instead of mv to preserve history
git mv SOURCE DEST

# Or document original locations
cat > ~/projects/project-hub/projects/zsh-configuration/MIGRATION-LOG.md << 'EOF'
# Migration Log

Files migrated from zsh-configuration on 2025-12-19.

Original location: ~/projects/dev-tools/zsh-configuration/
Git history: See zsh-configuration repo commit history before 2025-12-19
EOF
```

### Issue 3: Workflow Disruption

**Problem:** Users accustomed to finding docs in zsh-configuration

**Solution:**
```bash
# Leave README in zsh-configuration pointing to new location
cat > ~/projects/dev-tools/zsh-configuration/PLANNING-MOVED.md << 'EOF'
# Planning Documentation Moved

Planning docs for zsh-configuration have been migrated to project-hub for better organization.

**New Location:** `~/projects/project-hub/projects/zsh-configuration/`

**Quick Links:**
- [Current Planning](~/projects/project-hub/projects/zsh-configuration/planning/)
- [Archive](~/projects/project-hub/projects/zsh-configuration/archive/)
- [Recent Sessions](~/projects/project-hub/sessions/2025-12/)
EOF
```

---

## 📊 Decision Matrix

| Criteria | Option A (Project-Hub) | Option B (Hybrid) | Option C (.planning/) |
|----------|------------------------|-------------------|----------------------|
| **Centralization** | ✅ All in one place | 🟡 Scattered | ✅ All in one place |
| **Discoverability** | ✅ Visible repo | 🟡 Split | ❌ Hidden folder |
| **Git tracking** | ✅ Full history | 🟡 Partial | ❌ No tracking |
| **Organization** | ✅ Structured | 🟡 Less clear | ✅ Structured |
| **Migration effort** | ❌ 2-3 hours | ✅ 30 min | ❌ 2-3 hours |
| **Maintenance** | ✅ Easy | 🟡 Moderate | ✅ Easy |
| **Cross-project** | ✅ Natural fit | 🟡 Awkward | ✅ Natural fit |
| **Cleanup** | ✅ Clean repos | 🟡 Still cluttered | ✅ Clean repos |

**Recommendation:** **Option A (Project-Hub)** ⭐

---

## 📝 Next Steps

**Choose your path:**

### Path 1: Full Migration (Recommended)
```bash
# 1. Create migration script (copy from above)
vim ~/projects/project-hub/scripts/migrate-planning-docs.sh
chmod +x ~/projects/project-hub/scripts/migrate-planning-docs.sh

# 2. Run migration
~/projects/project-hub/scripts/migrate-planning-docs.sh

# 3. Review migrated files
cd ~/projects/project-hub
tree planning/ proposals/ sessions/ projects/

# 4. Update references in zsh-configuration
# (manual review and update)

# 5. Commit to both repos
cd ~/projects/project-hub
git add .
git commit -m "feat: migrate planning docs from zsh-configuration"

cd ~/projects/dev-tools/zsh-configuration
git add .
git commit -m "refactor: migrate planning docs to project-hub"

# 6. Push changes
cd ~/projects/project-hub && git push
cd ~/projects/dev-tools/zsh-configuration && git push
```

**Time:** 2-3 hours total

### Path 2: Gradual Migration
```bash
# 1. Start with recent work only
mkdir -p ~/projects/project-hub/sessions/2025-12
mv ~/projects/dev-tools/zsh-configuration/SESSION-SUMMARY-2025-12-*.md \
   ~/projects/project-hub/sessions/2025-12/

# 2. Move more over time as needed
# 3. Eventually get to full migration
```

**Time:** 30 min now, ongoing

### Path 3: Keep As-Is
```bash
# Just organize better in zsh-configuration
mkdir -p ~/projects/dev-tools/zsh-configuration/planning/{active,archive}
mv ~/projects/dev-tools/zsh-configuration/PROPOSAL-*.md \
   ~/projects/dev-tools/zsh-configuration/planning/archive/
```

**Time:** 15 min

---

## 🔗 Integration with Existing Systems

### PROJECT-HUB.md Enhancement

Add section documenting new planning structure:

```markdown
## Planning Documentation

This hub now centralizes planning docs for all projects.

**Quick Links:**
- [Active Planning](planning/active/) - Current work
- [Recent Sessions](sessions/2025-12/) - Latest summaries
- [Proposals](proposals/) - All proposals
- [Project Planning](projects/) - By project

**By Project:**
- [ZSH Configuration](projects/zsh-configuration/)
- [Mediation Planning](projects/mediation-planning/)
- [Dev Planning](projects/dev-planning/)
```

### Update .planning/NOW.md

Reference project-hub for detailed planning:

```markdown
## Planning Documentation

**Project-specific planning:** See `~/projects/project-hub/projects/`
**Recent sessions:** See `~/projects/project-hub/sessions/2025-12/`

This file (NOW.md) tracks cross-project priorities only.
```

---

## ✅ Success Metrics

**After migration:**
- ✅ All planning docs in one location (project-hub)
- ✅ Clear structure (planning/, proposals/, sessions/, projects/)
- ✅ Easy to find any planning doc
- ✅ zsh-configuration repo cleaner (no planning clutter)
- ✅ Git history preserved (or documented)
- ✅ References updated (no broken links)

---

**Created:** 2025-12-19
**Status:** Brainstorm / Proposal
**Estimated Time:**
- Option A (Full Migration): 2-3 hours
- Option B (Hybrid): 30 min + ongoing
- Option C (Keep As-Is): 15 min

**Recommendation:** **Option A (Full Migration to Project-Hub)** ⭐

Ready to implement when approved!
