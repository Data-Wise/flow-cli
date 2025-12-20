# Project Coordination Guide

> **TL;DR:** How to coordinate work across multiple projects, maintain ecosystem health, and prevent conflicts.

**Last Updated:** 2025-12-19
**Scope:** Data-Wise ecosystem (20+ repositories)
**Location:** `~/projects/dev-tools/zsh-configuration/standards/project/`

---

## 📋 Table of Contents

- [Overview](#overview)
- [Coordination Principles](#coordination-principles)
- [Cross-Project Dependencies](#cross-project-dependencies)
- [Breaking Changes](#breaking-changes)
- [Release Coordination](#release-coordination)
- [Documentation Sync](#documentation-sync)
- [Standards Propagation](#standards-propagation)
- [Common Workflows](#common-workflows)

---

## Overview

### The Challenge

When working across 20+ projects:
- Changes in one affect others
- Standards need consistency
- Documentation can drift
- Dependencies create constraints
- Breaking changes need coordination

### The Solution

**Centralized coordination hub:** `/Users/dt/projects/.planning/`

**Key coordination files:**
- `NOW.md` - Current focus across all projects
- `ROADMAP.md` - Quarterly goals
- `PACKAGES.md` - R package status
- Archive files for detailed tracking

---

## Coordination Principles

### 1. Single Source of Truth

**For each concern:**

| Concern | Source of Truth |
|---------|----------------|
| **Alias definitions** | `~/projects/dev-tools/zsh-configuration/` |
| **Documentation standards** | `~/projects/dev-tools/zsh-configuration/standards/documentation/` |
| **Code style** | `~/projects/dev-tools/zsh-configuration/standards/code/` |
| **Project structure** | `~/projects/dev-tools/zsh-configuration/standards/project/` |
| **ADHD templates** | `~/projects/dev-tools/zsh-configuration/standards/adhd/` |
| **R package standards** | MediationVerse lead package |
| **Cross-project status** | `/Users/dt/projects/.planning/` |

### 2. Propagation Strategy

When standards change:
1. **Update source of truth** first
2. **Document change** in CHANGELOG
3. **Propagate to active projects** (within 1 week)
4. **Update .planning/** if affects multiple projects

### 3. Communication Channels

**For coordination:**
- `.STATUS` files - Individual project status
- `PROJECT-HUB.md` - Project strategic plan
- `/Users/dt/projects/.planning/NOW.md` - Cross-project priorities
- Git commits - What changed and why

---

## Cross-Project Dependencies

### Dependency Map

```
zsh-configuration (standards)
    ↓
    ├──→ All projects (use standards)
    │
statistical-research (MCP server)
    ↓
    └──→ Research projects (use MCP tools)

MediationVerse (meta-package)
    ↓
    ├──→ medfit
    ├──→ probmed
    ├──→ medrobust
    ├──→ medsim
    ├──→ RMediation
    └──→ mediationverse

Teaching projects
    ↓
    └──→ stat-440, causal-inference
```

### Dependency Rules

**When updating a dependency:**
1. **Check downstream** - What depends on this?
2. **Test affected projects** - Do they still work?
3. **Update documentation** - Note breaking changes
4. **Coordinate releases** - Don't break downstream

**Example:**
```bash
# Before changing zsh-configuration standards
grep -r "ALIAS-REFERENCE-CARD" ~/projects/*/README.md

# Update all referencing projects
# Update .planning/NOW.md with coordination note
```

---

## Breaking Changes

### Definition

A breaking change is ANY change that:
- Removes a command/alias others use
- Changes command behavior others depend on
- Modifies file structure others reference
- Updates standards others follow
- Breaks backward compatibility

### Breaking Change Protocol

**Before making breaking change:**

1. **Document in proposal:**
   ```markdown
   ## Breaking Changes

   ### What's Breaking
   - Removing `js` alias → use `just-start`

   ### Who's Affected
   - Anyone using shortcuts in scripts
   - Tutorial documentation

   ### Migration Path
   - Find/replace: js → just-start
   - Update all docs referencing old command
   ```

2. **Add to CHANGELOG:**
   ```markdown
   ## [Unreleased]

   ### BREAKING CHANGES
   - Removed `js`, `idk`, `stuck` aliases
   - Use `just-start` instead
   - See MIGRATION.md for full guide
   ```

3. **Create migration guide:**
   ```markdown
   # Migration Guide v1.0 → v2.0

   ## Removed Aliases
   | Old | New | Notes |
   |-----|-----|-------|
   | `js` | `just-start` | Function still exists |
   ```

4. **Update affected projects:**
   - grep for usage across all projects
   - Update within 1 week
   - Test after updates

5. **Announce in .planning/NOW.md:**
   ```markdown
   ## Active Coordination

   **Alias cleanup (2025-12-19):**
   - zsh-configuration: 179→28 aliases
   - Affects: Tutorial docs need rewrite
   - Status: Warning notes added, rewrites planned
   ```

---

## Release Coordination

### R Package Releases

**Coordination needed when:**
- Multiple packages in MediationVerse
- Dependency changes affect downstream
- CRAN submission timing

**Process:**
1. **Check dependency graph:**
   ```R
   # Which packages depend on this?
   tools::package_dependencies("medfit", reverse = TRUE)
   ```

2. **Update in order:**
   - Dependencies first (e.g., RMediation)
   - Dependent packages next (e.g., medfit)
   - Meta-package last (e.g., mediationverse)

3. **Coordinate CRAN submissions:**
   - Don't submit all at once
   - Wait for upstream approval before downstream
   - Document in `.planning/PACKAGES.md`

### Documentation Site Releases

**When updating docs:**
1. **Build and test locally:**
   ```bash
   mkdocs build
   mkdocs serve  # Preview at localhost:8000
   ```

2. **Check for broken links:**
   ```bash
   mkdocs build 2>&1 | grep -i "warning\|error"
   ```

3. **Coordinate across projects:**
   - If standard template changes → update all sites
   - If design changes → decide if ecosystem-wide

---

## Documentation Sync

### Documentation Types

| Type | Location | Sync Strategy |
|------|----------|---------------|
| **Standards** | `zsh-configuration/standards/` | Manual propagation |
| **Tutorials** | Project-specific | Reference standards |
| **API docs** | Auto-generated | No sync needed |
| **Website design** | Template in standards | Copy to projects |

### Keeping Docs in Sync

**Problem:** Documentation drifts across projects

**Solution:**

1. **Link, don't duplicate:**
   ```markdown
   # In project README
   See [ZSH Alias Reference](../zsh-configuration/docs/user/ALIAS-REFERENCE-CARD.md)
   ```

2. **Use templates:**
   ```bash
   # Copy latest template
   cp ~/projects/dev-tools/zsh-configuration/standards/adhd/QUICK-START-TEMPLATE.md \
      ~/projects/my-project/docs/QUICK-START.md
   ```

3. **Reference source of truth:**
   ```markdown
   # Commit Message Standards

   This project follows the standards defined in:
   [zsh-configuration/standards/code/COMMIT-MESSAGES.md](../../zsh-configuration/standards/code/COMMIT-MESSAGES.md)
   ```

4. **Periodic audits:**
   ```bash
   # Check all projects for outdated docs
   grep -r "old-command" ~/projects/*/docs/
   ```

---

## Standards Propagation

### Standards Synchronization ⭐ NEW

**Source of Truth:** `~/projects/dev-tools/zsh-configuration/standards/`

**Synced To:**
- `project-hub/standards/`
- `mediation-planning/standards/`
- `dev-planning/standards/`

**Sync Command:**
```bash
~/projects/dev-tools/zsh-configuration/scripts/sync-standards.sh
```

**Check Sync Status:**
```bash
# See which version each hub has
cat ~/projects/project-hub/standards/.version
cat ~/projects/r-packages/mediation-planning/standards/.version
cat ~/projects/dev-tools/dev-planning/standards/.version
```

**When to Sync:**
- After updating any standard document
- After creating new standard
- Weekly (Friday with other reviews)
- When coordinating major changes

**Version Tracking:**
- `.version` file in each standards folder
- Date-based versioning (YYYY-MM-DD)
- Easy to see if out of sync

### When Standards Change

**Example:** Website design standards updated

**Propagation process:**

1. **Update source:** `zsh-configuration/standards/documentation/WEBSITE-DESIGN-GUIDE.md`

2. **Run sync script:**
   ```bash
   ~/projects/dev-tools/zsh-configuration/scripts/sync-standards.sh
   ```

3. **Document change:**
   ```markdown
   ## CHANGELOG

   ### 2025-12-19 - Modern CSS Standards
   - Added modern depth (subtle shadows)
   - Updated anti-patterns
   - See WEBSITE-DESIGN-GUIDE.md
   ```

4. **Identify affected projects:**
   ```bash
   find ~/projects -name "mkdocs.yml" -type f
   # Lists all projects with documentation sites
   ```

5. **Create propagation plan:**
   ```markdown
   ## Standards Propagation Plan

   **Standard:** Website Design v2.0
   **Affects:** 3 projects with MkDocs sites

   - [ ] Project A - Update extra.css
   - [ ] Project B - Update extra.css
   - [ ] Project C - Update extra.css

   **Timeline:** Week of 2025-12-23
   ```

6. **Track in .planning/NOW.md:**
   ```markdown
   ## Active Coordination

   **Website standards propagation:**
   - Updated: zsh-configuration (✅)
   - Synced to PM hubs: ✅
   - Pending: project-a, project-b, project-c
   - Deadline: End of week
   ```

---

## Common Workflows

### Starting New Project

```bash
# 1. Create project structure
mkdir -p ~/projects/category/new-project
cd ~/projects/category/new-project

# 2. Copy templates
cp ~/projects/dev-tools/zsh-configuration/standards/project/.STATUS-template .STATUS
cp ~/projects/dev-tools/zsh-configuration/standards/project/PROJECT-HUB-template.md PROJECT-HUB.md

# 3. Initialize git
git init
git add .
git commit -m "chore: initial commit with templates"

# 4. Create entry in .planning
# Edit ~/projects/.planning/NOW.md
# Add project to active list

# 5. Set up in dashboard
dash  # Should now show new project
```

### Coordinating Cross-Project Change

**Example:** Updating all projects to use new commit message standard

```bash
# 1. Document change
vim ~/projects/dev-tools/zsh-configuration/standards/code/COMMIT-MESSAGES.md

# 2. Find affected projects
find ~/projects -name ".git" -type d | wc -l
# Shows: 20+ projects

# 3. Create coordination plan
cat > ~/projects/.planning/commit-msg-update.md << 'EOF'
# Commit Message Standard Update
Date: 2025-12-19

## Change
Updated to Conventional Commits format

## Affected
All 20+ projects

## Plan
- Week 1: Update documentation
- Week 2: Apply to new commits
- Week 3: Audit and fix

## Status
- [ ] zsh-configuration
- [ ] medfit
- [ ] probmed
...
EOF

# 4. Update .planning/NOW.md
echo "- Commit message standard update in progress" >> ~/projects/.planning/NOW.md

# 5. Propagate gradually
# Don't try to update all at once
# Update 3-5 projects per day
```

### Weekly Cross-Project Review

```bash
# Friday afternoon routine

# 1. Review all project statuses
dash

# 2. Update strategic plans
for project in $(find ~/projects -name "PROJECT-HUB.md"); do
    echo "Review: $project"
    # Check if needs weekly update
done

# 3. Update coordination hub
vim ~/projects/.planning/NOW.md
# Update: What's active, what's blocked, what's completed

# 4. Check for stale projects
dash | grep "⏸️"  # Find paused projects
# Decide: archive or reactivate?

# 5. Plan next week
vim ~/projects/.planning/ROADMAP.md
# Adjust priorities based on progress
```

### Handling Conflicts

**When two projects need incompatible changes:**

1. **Document conflict:**
   ```markdown
   # Conflict Log

   Date: 2025-12-19
   Projects: medfit, probmed

   Conflict:
   - medfit needs API v2
   - probmed still on API v1

   Options:
   A. Update probmed first (1 day)
   B. Make medfit backward compatible (2 days)
   C. Maintain both versions (ongoing cost)

   Decision: Option A
   Rationale: Faster, cleaner
   ```

2. **Create resolution plan**

3. **Track in .planning/NOW.md**

4. **Execute and verify**

---

## Emergency Procedures

### When Something Breaks Cross-Project

**Immediate:**
1. **Identify scope:**
   ```bash
   # What's broken?
   # Which projects affected?
   dash  # Check all project statuses
   ```

2. **Rollback if critical:**
   ```bash
   git revert <commit>
   # Or restore from backup
   ```

3. **Document incident:**
   ```markdown
   # Incident Log
   Date: 2025-12-19
   Time: 14:30

   What: Alias removal broke scripts
   Affected: 3 projects
   Rollback: Yes

   Fix Plan:
   - Add deprecation warnings first
   - Remove in next version
   ```

4. **Fix properly:**
   - Don't rush
   - Add tests
   - Update coordination docs

---

## Checklist Templates

### New Standard Checklist

- [ ] Update source of truth document
- [ ] Add to CHANGELOG
- [ ] Create migration guide (if breaking)
- [ ] Identify affected projects
- [ ] Create propagation plan
- [ ] Update .planning/NOW.md
- [ ] Execute propagation (gradual)
- [ ] Verify all projects updated
- [ ] Archive old documentation

### Release Coordination Checklist

- [ ] Check dependency graph
- [ ] Update dependencies first
- [ ] Test downstream projects
- [ ] Document breaking changes
- [ ] Create migration guide
- [ ] Coordinate CRAN timing (if R packages)
- [ ] Update .planning/PACKAGES.md
- [ ] Announce in NOW.md

### Weekly Review Checklist

- [ ] Run `dash` to see all projects
- [ ] Update PROJECT-HUB.md for active projects
- [ ] Review .planning/NOW.md
- [ ] Check for stale breadcrumbs
- [ ] Archive completed items
- [ ] Plan next week priorities

---

## Integration with Other Standards

**See also:**
- [PROJECT-MANAGEMENT-STANDARDS.md](./PROJECT-MANAGEMENT-STANDARDS.md) - Two-tier system
- [PROJECT-STRUCTURE.md](./PROJECT-STRUCTURE.md) - File organization
- [COMMIT-MESSAGES.md](../code/COMMIT-MESSAGES.md) - Git standards

---

## References

**Coordination hub:**
- `/Users/dt/projects/.planning/` - Central coordination
- `/Users/dt/projects/.planning/NOW.md` - Current priorities
- `/Users/dt/projects/.planning/ROADMAP.md` - Quarterly goals

**Documentation:**
- `/Users/dt/projects/.planning/README.md` - Planning system overview
- `/Users/dt/projects/.planning/archive/PROJECT_MANAGEMENT_OVERVIEW.md` - Detailed system

---

**Created:** 2025-12-19
**Maintainer:** DT
**Scope:** Data-Wise ecosystem (20+ repositories)
