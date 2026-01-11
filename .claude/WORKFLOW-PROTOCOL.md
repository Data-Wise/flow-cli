# Workflow Protocol for Claude Code Sessions

**Status:** Active
**Last Updated:** 2026-01-11

---

## Feature Development Workflow

### Phase 1: Planning (on `dev` branch)

1. **Start on dev branch**

   ```bash
   git checkout dev
   git pull origin dev
   ```

2. **Planning and brainstorming**
   - User requests feature/enhancement
   - Claude assists with planning, design, architecture
   - Create planning documents (specs, proposals, etc.)
   - User reviews and approves plan

### Phase 2: Commit Plan (on `dev` branch)

**CRITICAL:** Before creating worktree, commit planning docs to dev

3. **Update planning document**
   - Finalize spec/proposal with user decisions
   - Mark status as "Approved" or "Ready for implementation"

4. **Commit to dev branch**
   ```bash
   git add docs/specs/SPEC-feature-name.md
   git commit -m "docs: add approved spec for feature-name"
   git push origin dev
   ```

### Phase 3: Create Worktree (from `dev` branch)

5. **Create feature worktree**

   ```bash
   # Using g dispatcher
   g feature start feature-name

   # Or using wt dispatcher
   wt create feature/feature-name
   ```

### Phase 4: Implementation (NEW SESSION)

**CRITICAL:** Do NOT ask user to start working immediately

6. **Ask user to start new session**

   **DO:**

   ```
   ✅ Feature worktree created at ~/.git-worktrees/flow-cli-feature-name

   To start implementation, please start a new session:

   cd ~/.git-worktrees/flow-cli-feature-name
   claude
   ```

   **DON'T:**

   ```
   ❌ "Let's start implementing now..."
   ❌ "Should I begin working on this feature?"
   ❌ Continuing to work in the same session
   ```

---

## Why This Workflow?

### Separation of Concerns

1. **Planning Session (dev branch)**
   - Brain work: design, architecture, decisions
   - Document creation and approval
   - No code changes yet

2. **Implementation Session (feature worktree)**
   - Fresh context
   - Clean working directory
   - Focused on implementation only

### Benefits

- **Clean history:** Planning docs committed separately
- **Fresh context:** New session = clear focus on implementation
- **Safe iteration:** Can abandon worktree without affecting dev
- **Parallel work:** Multiple features can be in planning while others are in implementation

---

## Example Flow

```bash
# Session 1: Planning
$ git checkout dev
$ claude

User: "I want to add clipboard integration to dot secret"
Claude: [Creates spec, brainstorms, gets approval]
Claude: [Updates spec with user decisions]
Claude: [Commits spec to dev]
Claude: [Creates worktree: ~/.git-worktrees/flow-cli-secret-copy]
Claude: "Worktree created. To start implementation, start a new session:
         cd ~/.git-worktrees/flow-cli-secret-copy && claude"

# Session 2: Implementation (NEW SESSION)
$ cd ~/.git-worktrees/flow-cli-secret-copy
$ claude

User: "Let's implement the clipboard integration"
Claude: [Implements feature based on approved spec]
```

---

## Checklist for Claude

When user requests a new feature:

**Planning Phase:**

- [ ] Ensure on dev branch (`git checkout dev`)
- [ ] Create/update planning document
- [ ] Get user approval
- [ ] Commit planning docs to dev
- [ ] Push to origin dev

**Worktree Creation:**

- [ ] Create feature worktree from dev
- [ ] Note the worktree path

**Session Transition:**

- [ ] Do NOT continue implementation
- [ ] Tell user to start new session
- [ ] Provide exact cd command and worktree path

---

## Related Documentation

- [Branch Workflow](../docs/contributing/BRANCH-WORKFLOW.md)
- [PR Workflow Guide](../docs/contributing/PR-WORKFLOW-GUIDE.md)
- [Git Feature Workflow Tutorial](../docs/tutorials/08-git-feature-workflow.md)

---

**Established:** 2026-01-11
**Applies to:** All feature development in flow-cli
