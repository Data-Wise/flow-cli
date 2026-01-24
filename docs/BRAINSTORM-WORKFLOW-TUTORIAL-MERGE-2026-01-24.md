# Brainstorm: Workflow-Tutorial Merge + Feature Documentation Procedure

**Date:** 2026-01-24
**Purpose:** Explore merging workflows into tutorials & define procedure for feature documentation updates
**Status:** Brainstorm - Awaiting user feedback

---

## Part 1: Workflow → Tutorial Merge

### Current State Analysis

**Workflow Files (13 total):**

```
docs/guides/
├── ALIAS-MANAGEMENT-WORKFLOW.md
├── CONFIG-MANAGEMENT-WORKFLOW.md
├── DOT-WORKFLOW.md
├── PLUGIN-MANAGEMENT-WORKFLOW.md
├── QUARTO-WORKFLOW-PHASE-2-GUIDE.md
├── TEACHING-QUARTO-WORKFLOW-GUIDE.md
├── TEACHING-WORKFLOW-V3-GUIDE.md
├── TEACHING-WORKFLOW-VISUAL.md
├── TEACHING-WORKFLOW.md (legacy)
├── WORKFLOW-TUTORIAL.md
├── WORKFLOWS-QUICK-WINS.md
├── WORKTREE-WORKFLOW.md
└── YOLO-MODE-WORKFLOW.md
```

**Tutorial Files (25+ total):**

```
docs/tutorials/
├── 01-first-session.md
├── 02-multiple-projects.md
├── ...
├── 08-git-feature-workflow.md
├── 09-worktrees.md
├── ...
└── 23-token-automation.md
```

**Workflow Guide (Consolidation Plan):**

```
docs/help/WORKFLOWS.md (planned)
└── Common workflow patterns
```

### Problem Statement

**Current Issues:**

1. **Duplicate Content**: Tutorial 08 (Git Feature Workflow) + `WORKTREE-WORKFLOW.md`
2. **Unclear Distinction**: What's a workflow vs tutorial?
3. **Navigation Confusion**: Users don't know whether to read tutorial or workflow first
4. **Scattered Information**: Same workflow described in multiple places

**Examples:**

| Workflow File | Overlapping Tutorial | Duplicate? |
|---------------|----------------------|------------|
| `WORKTREE-WORKFLOW.md` | Tutorial 09: Worktrees | ✅ YES |
| `DOT-WORKFLOW.md` | Tutorial 12: DOT Dispatcher | Partial |
| `TEACHING-WORKFLOW-V3-GUIDE.md` | Tutorial 19, 21 | Partial |

---

### Option A: Keep Separate (Status Quo)

**Structure:**

```
docs/
├── tutorials/          # Learning by doing (linear, sequential)
│   └── 01-23.md       # Step-by-step, beginner → advanced
│
├── guides/            # Topic deep-dives
│   └── *-WORKFLOW.md  # Workflow patterns
│
└── help/
    └── WORKFLOWS.md   # Quick reference (consolidated)
```

**Characteristics:**

- **Tutorials:** Learning path, sequential, hands-on
- **Workflows:** Repeatable patterns, reference, non-linear
- **Help/Workflows:** Quick lookup, cheatsheet format

**Pros:**
- ✅ Clear separation of concerns
- ✅ Tutorials remain focused (learning)
- ✅ Workflows remain reference (doing)
- ✅ No disruption to existing tutorials

**Cons:**
- ❌ Duplicate content (tutorial teaches, workflow references same thing)
- ❌ Unclear which to read first
- ❌ Users might miss workflows entirely
- ❌ More files to maintain

**When to Use:**
- If workflows are fundamentally different from tutorials (advanced patterns)
- If tutorials should stay simple (no workflow complexity)

---

### Option B: Merge into Tutorials (Full Integration)

**Structure:**

```
docs/
├── tutorials/          # Learning + Workflows
│   ├── 01-first-session.md
│   ├── 08-git-feature-workflow.md  # Already a workflow!
│   ├── 09-worktree-workflow.md     # Renamed from "worktrees"
│   ├── 12-dot-workflow.md          # Renamed from "dot dispatcher"
│   ├── 19-teaching-workflow.md     # Merged from guides/
│   └── ...
│
└── help/
    └── WORKFLOWS.md   # Quick reference only (1-2 lines per workflow)
```

**Pattern:**

Every tutorial that teaches a workflow includes:

```markdown
# Tutorial X: [Feature] Workflow

## What You'll Learn
- Core concept
- Basic usage
- **Common workflow patterns** ← NEW

## Step 1: Learn Basics
[Tutorial content]

## Step 2: Practice Workflow
[Hands-on workflow practice]

## Common Workflows

### Workflow 1: [Name]
**When to use:** [Context]
**Steps:**
1. ...
2. ...

### Workflow 2: [Name]
...

## Cheat Sheet
[Quick reference - copied to help/WORKFLOWS.md]
```

**Pros:**
- ✅ No duplicate content (single source of truth)
- ✅ Learn concept AND practical workflow in same place
- ✅ Easier navigation (one place to go)
- ✅ Tutorials become more practical
- ✅ Fewer files to maintain

**Cons:**
- ❌ Tutorials become longer (might overwhelm beginners)
- ❌ Workflow updates require tutorial edits
- ❌ Harder to find "just the workflow" quickly

**When to Use:**
- If workflows are the MAIN use case (not advanced patterns)
- If tutorials are already teaching workflows implicitly
- If users complain "I learned the feature but don't know when to use it"

---

### Option C: Hybrid Approach (Recommended)

**Structure:**

```
docs/
├── tutorials/          # Learning path
│   ├── 01-first-session.md
│   ├── 08-git-feature-workflow.md  # Tutorial teaches workflow
│   ├── 09-worktrees.md             # Tutorial teaches basics
│   ├── 19-teaching-basics.md       # Tutorial teaches basics
│   └── ...
│
├── guides/             # Advanced/complex workflows only
│   ├── TEACHING-WORKFLOW-V3-GUIDE.md  # Too complex for tutorial
│   ├── QUARTO-WORKFLOW-PHASE-2-GUIDE.md  # Advanced multi-step
│   └── YOLO-MODE-WORKFLOW.md       # Power user feature
│
└── help/
    └── WORKFLOWS.md   # Quick reference (links to tutorials/guides)
```

**Decision Matrix:**

| Workflow Complexity | Where It Goes | Format |
|---------------------|---------------|--------|
| **Simple** (1-3 steps) | Tutorial (embedded) | Section in tutorial |
| **Medium** (4-8 steps, single feature) | Tutorial (dedicated section) | "Common Workflows" section |
| **Complex** (9+ steps, multi-feature) | Guide (standalone) | Full guide |
| **Power User** (advanced, optional) | Guide (standalone) | Full guide |

**Examples:**

| Workflow | Complexity | Location | Rationale |
|----------|-----------|----------|-----------|
| Worktree basics | Simple | Tutorial 09 | Core feature, linear learning |
| Git feature workflow | Medium | Tutorial 08 | Already a workflow tutorial |
| Teaching Workflow v3.0 | Complex | Guide | Multi-phase, many features |
| YOLO Mode | Power User | Guide | Advanced, optional |
| DOT secrets | Simple | Tutorial 12 | Core feature |
| Plugin management | Medium | Tutorial 22 | Workflow-focused |
| Config management | Simple | Tutorial (new/merge) | Linear process |

**Pros:**
- ✅ Best of both worlds
- ✅ Simple workflows = easy to find (in tutorials)
- ✅ Complex workflows = standalone (not overwhelming)
- ✅ Clear decision criteria (complexity matrix)
- ✅ Gradual migration (move simple workflows first)

**Cons:**
- ⚠️ Requires judgment calls (what's "complex"?)
- ⚠️ Some reorganization needed
- ⚠️ Initial effort to migrate

---

### Proposed Migration Plan (Option C)

**Phase 1: Identify & Categorize (1 hour)**

Go through each workflow file:

```markdown
| Workflow File | Complexity | Decision | New Location |
|---------------|-----------|----------|--------------|
| WORKTREE-WORKFLOW.md | Simple | Merge | Tutorial 09 (add workflows section) |
| DOT-WORKFLOW.md | Simple | Merge | Tutorial 12 (add workflows section) |
| TEACHING-WORKFLOW-V3-GUIDE.md | Complex | Keep | Guide (already correct) |
| ALIAS-MANAGEMENT-WORKFLOW.md | Simple | Merge | Tutorial (new/existing) |
| CONFIG-MANAGEMENT-WORKFLOW.md | Simple | Merge | Tutorial (new/existing) |
| PLUGIN-MANAGEMENT-WORKFLOW.md | Medium | Merge | Tutorial 22 |
| YOLO-MODE-WORKFLOW.md | Power User | Keep | Guide (already correct) |
| QUARTO-WORKFLOW-PHASE-2-GUIDE.md | Complex | Keep | Guide (already correct) |
| TEACHING-QUARTO-WORKFLOW-GUIDE.md | Complex | Keep | Guide (already correct) |
| WORKFLOW-TUTORIAL.md | Meta | Archive? | Generic tutorial about workflows |
| WORKFLOWS-QUICK-WINS.md | Reference | Keep | Guide (quick wins) |
```

**Phase 2: Merge Simple Workflows (2-3 hours)**

For each simple workflow:

1. Read workflow file
2. Find corresponding tutorial
3. Add "Common Workflows" section to tutorial:

```markdown
# Tutorial 09: Worktrees

## [Existing tutorial content...]

---

## Common Workflows

### Workflow 1: Feature Development
**When to use:** Starting a new feature that needs isolation

**Steps:**
1. Create worktree: `wt create feature/new-feature`
2. Work in isolation
3. Merge when done: `g pr create`
4. Cleanup: `wt prune`

### Workflow 2: Bug Fix + Feature Parallel
**When to use:** Need to fix urgent bug while working on feature

**Steps:**
1. Keep feature worktree active
2. Create bug fix worktree: `wt create hotfix/urgent-bug`
3. Fix bug, test, merge
4. Return to feature worktree
5. Cleanup: `wt prune`

---

## Quick Reference

| Command | What It Does |
|---------|--------------|
| `wt create <branch>` | Create new worktree |
| `wt list` | List all worktrees |
| `wt prune` | Cleanup deleted worktrees |
| `wt status` | Show worktree status |
```

1. Update `help/WORKFLOWS.md` with cross-reference:

```markdown
# Common Workflows

## Worktree Workflows

See [Tutorial 09: Worktrees](../tutorials/09-worktrees.md#common-workflows) for detailed workflows.

**Quick Links:**
- [Feature Development](../tutorials/09-worktrees.md#workflow-1-feature-development)
- [Bug Fix + Feature Parallel](../tutorials/09-worktrees.md#workflow-2-bug-fix--feature-parallel)
```

1. Archive old workflow file to `docs/guides/.archive/`

**Phase 3: Update Navigation (30 min)**

Update `mkdocs.yml`:

```yaml
- Workflows:  # Simplified section
    - Quick Wins: guides/WORKFLOWS-QUICK-WINS.md
    - 🎓 Teaching Workflow v3.0: guides/TEACHING-WORKFLOW-V3-GUIDE.md
    - 📚 Quarto Workflow Phase 2: guides/QUARTO-WORKFLOW-PHASE-2-GUIDE.md
    - 🚀 YOLO Mode: guides/YOLO-MODE-WORKFLOW.md
    # Simple workflows now in tutorials
```

**Phase 4: Update Cross-References (30 min)**

Search for links to old workflow files:

```bash
grep -r "WORKTREE-WORKFLOW.md" docs/
# Replace with link to Tutorial 09
```

---

## Part 2: Feature Documentation Update Procedure

### Problem Statement

**When a feature is added/updated/removed, which documents need updating?**

**Current State:**
- No clear checklist
- Easy to forget docs
- Inconsistent updates
- Documentation drift

---

### Proposed Procedure: Feature Documentation Checklist

**Add to `docs/contributing/DOCUMENTATION-META-GUIDE.md`:**

#### New Section: "Feature Documentation Update Checklist"

```markdown
## Feature Documentation Update Checklist

### When a Feature is Added

**Code Changes:**
- [ ] New command created
- [ ] New dispatcher created
- [ ] New library functions created
- [ ] New workflow introduced

**Documentation Requirements:**

1. **Always Required:**
   - [ ] Update `CHANGELOG.md` (add to Unreleased section)
   - [ ] Update version in feature spec (if exists)
   - [ ] Add to `help/QUICK-REFERENCE.md` (command summary)

2. **If New Command:**
   - [ ] Create `docs/commands/<command>.md`
   - [ ] Add completion in `completions/_<command>`
   - [ ] Update `help/QUICK-REFERENCE.md` (commands section)

3. **If New Dispatcher:**
   - [ ] Add section to `MASTER-DISPATCHER-GUIDE.md`
   - [ ] Update `help/QUICK-REFERENCE.md` (dispatchers section)
   - [ ] Create tutorial if complex (or merge workflow into existing)

4. **If New Library Functions:**
   - [ ] Add to `MASTER-API-REFERENCE.md` (correct library section)
   - [ ] Add to function index (alphabetical)
   - [ ] Update change log in API reference

5. **If User-Facing Feature:**
   - [ ] Create tutorial OR update existing tutorial with workflow
   - [ ] Link from `tutorials/index.md` (learning path)
   - [ ] Add to `help/00-START-HERE.md` (if major feature)

6. **If Complex Workflow:**
   - [ ] Decide: Tutorial (simple/medium) or Guide (complex)
   - [ ] Create standalone guide if complex (9+ steps)
   - [ ] OR add "Common Workflows" section to tutorial if simple

7. **If Architecture Decision:**
   - [ ] Create `docs/architecture/<FEATURE>-ARCHITECTURE.md`
   - [ ] Link from `MASTER-ARCHITECTURE.md`

8. **If Teaching-Related:**
   - [ ] Update `TEACHING-WORKFLOW-V3-GUIDE.md`
   - [ ] Update relevant teaching tutorials

9. **Cross-References:**
   - [ ] Add to relevant "See Also" sections
   - [ ] Update `help/00-START-HERE.md` (popular topics if applicable)

---

### When a Feature is Updated

**Code Changes:**
- [ ] Command options changed
- [ ] API signature changed
- [ ] Behavior modified
- [ ] New use case added

**Documentation Requirements:**

1. **Always Required:**
   - [ ] Update `CHANGELOG.md` (Changed section)

2. **If Command Options Changed:**
   - [ ] Update `docs/commands/<command>.md`
   - [ ] Update `help/QUICK-REFERENCE.md`
   - [ ] Update examples in tutorials/guides

3. **If API Changed:**
   - [ ] Update `MASTER-API-REFERENCE.md`
   - [ ] Update function signature
   - [ ] Update examples
   - [ ] Add to change log (API reference)

4. **If Behavior Changed:**
   - [ ] Update affected tutorials
   - [ ] Update affected guides
   - [ ] Update workflow sections
   - [ ] Update expected outputs in docs

5. **If New Use Case Added:**
   - [ ] Add example to command doc
   - [ ] Add to workflow section in tutorial
   - [ ] OR create new workflow guide if complex

6. **Verify:**
   - [ ] All code examples still work
   - [ ] All expected outputs match
   - [ ] All links still valid
   - [ ] Screenshots/GIFs still accurate

---

### When a Feature is Removed/Deprecated

**Code Changes:**
- [ ] Feature deprecated (will be removed)
- [ ] Feature removed entirely

**Documentation Requirements:**

1. **If Deprecated (not yet removed):**
   - [ ] Add deprecation notice to `docs/commands/<command>.md`
   - [ ] Update `CHANGELOG.md` (Deprecated section)
   - [ ] Add migration guide (what to use instead)
   - [ ] Update cross-references with deprecation note

   **Deprecation Notice Template:**
   ```markdown
   !!! warning "Deprecated"
       This feature is deprecated as of v5.X.0 and will be removed in v6.0.0.
       Use [alternative feature](link) instead.

       **Migration Guide:**
       - Old: `old command`
       - New: `new command`
   ```

1. **If Removed Entirely:**
   - [ ] Remove `docs/commands/<command>.md` (or move to archive)
   - [ ] Remove from `help/QUICK-REFERENCE.md`
   - [ ] Remove from `MASTER-DISPATCHER-GUIDE.md` (if dispatcher)
   - [ ] Remove from `MASTER-API-REFERENCE.md` (if library function)
   - [ ] Update `CHANGELOG.md` (Removed section)
   - [ ] Add migration notice in changelog
   - [ ] Update all cross-references (remove or redirect)
   - [ ] Archive tutorial if feature-specific

2. **Verify:**
   - [ ] No broken links remain
   - [ ] All mentions updated with migration info
   - [ ] Builds without warnings

---

### Quick Decision Tree

```
Feature Change Detected
  │
  ├─ Added? ─────→ Full checklist (9 categories)
  │               └─ Minimum: CHANGELOG + QUICK-REFERENCE
  │
  ├─ Updated? ───→ Changed checklist (5 categories)
  │               └─ Minimum: CHANGELOG + affected docs
  │
  └─ Removed? ───→ Removal checklist (3 steps)
                  └─ Minimum: CHANGELOG + remove/archive docs
```

---

### Automation Helpers

**Script:** `scripts/doc-update-checker.sh` (future)

```bash
#!/usr/bin/env bash
# Check which docs need updating based on git diff

# Detect changes
NEW_COMMANDS=$(git diff --name-only | grep "commands/" | grep -v ".md")
NEW_LIBS=$(git diff --name-only | grep "lib/")
NEW_DISPATCHERS=$(git diff --name-only | grep "dispatchers/")

# Suggest docs to update
if [[ -n "$NEW_COMMANDS" ]]; then
    echo "📝 New command detected. Update these docs:"
    echo "  - docs/commands/<command>.md"
    echo "  - help/QUICK-REFERENCE.md"
    echo "  - CHANGELOG.md"
fi

# ... similar for libs, dispatchers
```

---

### PR Template Update

**Add to `.github/pull_request_template.md`:**

```markdown
## Documentation Checklist

**Feature Type:** (check one)
- [ ] New feature
- [ ] Feature update
- [ ] Feature removal
- [ ] Bug fix (no doc impact)

**Documentation Updated:** (if applicable)
- [ ] CHANGELOG.md
- [ ] help/QUICK-REFERENCE.md
- [ ] Command doc: `docs/commands/<name>.md`
- [ ] Tutorial: `docs/tutorials/<number>.md`
- [ ] Guide: `docs/guides/<NAME>.md`
- [ ] API Reference: `MASTER-API-REFERENCE.md`
- [ ] Dispatcher Guide: `MASTER-DISPATCHER-GUIDE.md`
- [ ] Architecture doc: `docs/architecture/<NAME>.md`

**Verification:**
- [ ] All code examples tested
- [ ] Screenshots/GIFs updated (if applicable)
- [ ] Links verified
- [ ] Builds without warnings: `mkdocs build`
- [ ] Linting passes: `./scripts/lint-docs.sh`
```

```

---

## Implementation Plan

### Step 1: Update Meta-Guide (30 min)

Add "Feature Documentation Update Checklist" section to:
`docs/contributing/DOCUMENTATION-META-GUIDE.md`

**Location:** After "Update Workflows" section

### Step 2: Create PR Template (15 min)

Update `.github/pull_request_template.md` with documentation checklist

### Step 3: Migrate Simple Workflows to Tutorials (2-3 hours)

Following Option C (Hybrid Approach):

1. **Tutorial 09 (Worktrees):**
   - Merge `WORKTREE-WORKFLOW.md` content
   - Add "Common Workflows" section
   - Archive old workflow file

2. **Tutorial 12 (DOT Dispatcher):**
   - Merge `DOT-WORKFLOW.md` content
   - Add dotfile management workflows
   - Archive old workflow file

3. **New Tutorial (Alias Management):**
   - Create from `ALIAS-MANAGEMENT-WORKFLOW.md`
   - OR merge into Tutorial 06 (Dopamine Features)

4. **New Tutorial (Config Management):**
   - Create from `CONFIG-MANAGEMENT-WORKFLOW.md`
   - OR merge into existing config tutorial

5. **Tutorial 22 (Plugin Optimization):**
   - Merge `PLUGIN-MANAGEMENT-WORKFLOW.md` content
   - Add plugin workflows

### Step 4: Update help/WORKFLOWS.md (1 hour)

Create consolidated workflow quick reference:

```markdown
# Common Workflows

## Quick Links

### Daily Workflows
- [Start Your Day](../tutorials/01-first-session.md#daily-workflow)
- [End Your Day](../tutorials/01-first-session.md#finish-workflow)

### Project Workflows
- [Create New Feature](../tutorials/08-git-feature-workflow.md#workflow-1)
- [Worktree Development](../tutorials/09-worktrees.md#common-workflows)

### Git Workflows
- [Feature Development](../tutorials/08-git-feature-workflow.md)
- [Hotfix](../tutorials/08-git-feature-workflow.md#hotfix-workflow)

### Teaching Workflows
- [Complete Guide](../guides/TEACHING-WORKFLOW-V3-GUIDE.md)
- [Quick Start](../tutorials/19-teaching-git-integration.md)

## Advanced Workflows (Guides)
- [Teaching Workflow v3.0](../guides/TEACHING-WORKFLOW-V3-GUIDE.md)
- [Quarto Workflow Phase 2](../guides/QUARTO-WORKFLOW-PHASE-2-GUIDE.md)
- [YOLO Mode](../guides/YOLO-MODE-WORKFLOW.md)
```

---

## Questions for User

### Q1: Workflow Merge Approach

**Which option do you prefer?**

A. **Keep Separate** (status quo - workflows in guides, tutorials in tutorials)
B. **Full Merge** (all workflows → tutorials, no standalone workflows)
C. **Hybrid** (simple → tutorials, complex → guides) ← RECOMMENDED

**Your answer:** ___________

### Q2: Complexity Threshold

**For Hybrid approach, where's the cutoff for "complex"?**

A. **3 steps** (if > 3 steps → standalone guide)
B. **5 steps** (if > 5 steps → standalone guide)
C. **8 steps** (if > 8 steps → standalone guide) ← RECOMMENDED

**Your answer:** ___________

### Q3: Workflow Files to Keep as Guides

**Which workflows should stay standalone? (Check all)**

- [ ] TEACHING-WORKFLOW-V3-GUIDE.md (complex, multi-phase)
- [ ] QUARTO-WORKFLOW-PHASE-2-GUIDE.md (advanced, multi-feature)
- [ ] YOLO-MODE-WORKFLOW.md (power user, optional)
- [ ] WORKFLOWS-QUICK-WINS.md (quick wins collection)
- [ ] TEACHING-QUARTO-WORKFLOW-GUIDE.md (teaching-specific, complex)

**Your selections:** ___________

### Q4: Migration Priority

**Which workflows to migrate first?**

A. **Simplest first** (WORKTREE, DOT, then harder)
B. **Most used first** (Git workflows, then less used)
C. **Tutorial-aligned first** (ones with existing tutorials)

**Your answer:** ___________

### Q5: Feature Documentation Checklist

**Should we add automation?**

- [ ] Yes - Create `scripts/doc-update-checker.sh` to detect changes
- [ ] No - Manual checklist in meta-guide is enough
- [ ] Later - After consolidation is done

**Your answer:** ___________

---

## Next Steps

**After user answers questions above:**

1. **Update meta-guide** with feature documentation checklist
2. **Choose workflow merge approach** (A, B, or C)
3. **Migrate workflows** according to chosen approach
4. **Update navigation** in mkdocs.yml
5. **Create help/WORKFLOWS.md** (consolidated reference)
6. **Deploy** updated documentation

---

**Created:** 2026-01-24
**Status:** Awaiting user feedback
**Estimated Time:** 4-6 hours (depending on chosen approach)
