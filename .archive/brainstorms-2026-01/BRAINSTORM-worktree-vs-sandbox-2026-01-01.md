# Worktree vs Sandbox - Decision Analysis

**Generated:** 2026-01-01
**Context:** flow-cli CC dispatcher design
**Question:** Do we need both `cc sand` and `cc yolo`? What's the difference between worktrees and sandboxes?

---

## TL;DR Answer

**Do we need both?**

- **No, we probably don't need `cc sand`** - Worktrees already solve the isolation problem better
- **Yes, keep `cc yolo`** - It's the fastest path for trusted tasks
- **Maybe add later:** `cc yolo --sandbox` flag for explicit Docker usage

**Key Insight:** Worktrees and sandboxes solve **different problems** with **overlapping benefits**

---

## Part 1: What They Actually Are

### Worktrees (Git Feature)

**What:** Multiple working directories for the same git repository

```
Your Project (flow-cli)
├── Main worktree: ~/projects/dev-tools/flow-cli/
│   └── branch: main
│
└── Feature worktrees: ~/.git-worktrees/
    ├── flow-cli-feature-auth/
    │   └── branch: feature/auth
    │
    └── flow-cli-bugfix-picker/
        └── branch: bugfix/picker
```

**Key Properties:**

- ✅ **Same repo** - Shares .git directory
- ✅ **Different files** - Each worktree has own files
- ✅ **Different branches** - Each on its own branch
- ✅ **Native git** - Built into git (no tools needed)
- ✅ **Instant** - Create in <1 second
- ⚠️ **Host filesystem** - Still on your computer

**Use Case:** Work on multiple features/branches simultaneously without switching

### Sandboxes (Docker Containers)

**What:** Isolated Linux environment running your code

```
Your Mac (Host)
├── ~/projects/dev-tools/flow-cli/  (real files)
│
└── Docker Container (Isolated)
    └── /workspace → ~/projects/dev-tools/flow-cli/  (mounted)
        ├── Limited to this directory
        ├── Can't access ~/.ssh/, /System/, etc.
        └── Disposable (delete → recreate)
```

**Key Properties:**

- ✅ **Isolated** - Can't access rest of computer
- ✅ **Disposable** - Delete and recreate instantly
- ✅ **Controlled network** - Firewall rules
- ✅ **Consistent env** - Same Linux + tools every time
- ⚠️ **Slower startup** - 5-10 seconds vs instant
- ⚠️ **Requires Docker** - Extra dependency

**Use Case:** Run untrusted code or experiment with risky operations safely

---

## Part 2: The Fundamental Difference

### Worktrees = Parallel Workspaces (Same Safety Level as Main Branch)

```
Problem: Need to work on feature-A while feature-B builds
Solution: Create worktree for each feature

Safety Model: Trust-based
- You trust the code you write
- You trust Claude to modify your code
- You trust yourself to review changes
- Git is your safety net (rollback)

Risk: Same as working on main branch
- Claude can still modify anything in worktree
- Claude can still delete files
- Claude can still push bad commits
- Mistakes affect your worktree files
```

**Analogy:** Having multiple desks in the same office

- Each desk has different projects (branches)
- But anyone in the office (Claude) can access any desk
- You rely on **discipline** (git review) for safety

### Sandboxes = Isolated Environments (Different Safety Level)

```
Problem: Want to run risky code without endangering host machine
Solution: Run code in Docker container

Safety Model: Isolation-based
- Don't trust the code being executed
- Don't trust Claude's modifications
- Container has NO access to host
- Delete container = all mistakes gone

Risk: Much lower than host
- Claude limited to /workspace in container
- Claude can't access ~/.ssh/, ~/, etc.
- Claude can't install malware on host
- Delete container → back to clean state
```

**Analogy:** Having a lab with safety protocols

- Lab has restricted access (only /workspace)
- Experiments stay in lab (container)
- Explosions don't damage building (host)
- Clean up = just close the lab (delete container)

---

## Part 3: Side-by-Side Comparison

### Feature Comparison

| Feature             | Worktree                  | Sandbox                    |
| ------------------- | ------------------------- | -------------------------- |
| **Speed**           | ⚡ Instant (<1s)          | 🐢 Slow (~5s)              |
| **Setup**           | ✅ Zero (built into git)  | ⚠️ Requires Docker         |
| **Isolation**       | ❌ None (same filesystem) | ✅ Full (container)        |
| **File access**     | ✅ All files on computer  | 🔒 Only /workspace         |
| **Network access**  | ✅ Full internet          | 🔒 Configurable/blocked    |
| **Cleanup**         | 📝 Manual (git reset)     | ✅ Auto (delete container) |
| **Persistence**     | ✅ Files persist          | ⚠️ Container ephemeral     |
| **Git integration** | ✅ Native (same repo)     | ⚠️ Manual (mount volume)   |
| **Best for**        | Parallel feature work     | Risky experiments          |

### Use Case Comparison

| Scenario                              | Better Choice | Why                                              |
| ------------------------------------- | ------------- | ------------------------------------------------ |
| **Work on 2 features at once**        | Worktree      | ⚡ Instant, native git                           |
| **Try risky refactoring**             | Sandbox       | 🔒 Isolated, disposable                          |
| **Test breaking changes**             | Worktree      | Quick to create/delete                           |
| **Run untrusted code**                | Sandbox       | 🔒 Can't access host                             |
| **Parallel builds**                   | Worktree      | ⚡ Fast, no overhead                             |
| **Experiment with YOLO mode**         | Sandbox       | 🔒 Safe even with --dangerously-skip-permissions |
| **Review PR locally**                 | Worktree      | ⚡ Fast checkout                                 |
| **Test with different Node versions** | Sandbox       | 🔒 Consistent environment                        |

### Safety Comparison

| Risk                              | Worktree                         | Sandbox                         |
| --------------------------------- | -------------------------------- | ------------------------------- |
| **Claude deletes important file** | 🔴 High - Can delete anything    | 🟢 Low - Limited to /workspace  |
| **Claude installs malware**       | 🔴 High - Can modify host        | 🟢 Low - Container only         |
| **Claude sends data externally**  | 🔴 High - Full network access    | 🟢 Low - Firewall rules         |
| **Claude corrupts git history**   | 🟡 Medium - Can push bad commits | 🟡 Medium - Same (volume mount) |
| **Accidental rm -rf /**           | 🔴 High - Can delete host files  | 🟢 Low - Container only         |

---

## Part 4: The "Do We Need Both?" Question

### Current Proposal (Before This Analysis)

```bash
# Worktree workflow (already implemented)
cc wt feature/auth          # Create worktree → Claude
cc wt yolo feature/auth     # Worktree + YOLO mode

# Sandbox workflow (proposed)
cc sand                     # Docker sandbox → Claude
cc sand yolo                # Sandbox + YOLO mode
```

**Problems with this approach:**

1. **Overlapping use cases** - Both provide "isolation" (different kinds)
2. **User confusion** - When to use `wt` vs `sand`?
3. **Complexity** - Two systems to maintain
4. **Startup penalty** - Sandbox slower than worktree

### Analysis: Do We Really Need cc sand?

#### Argument FOR cc sand:

**Safety for YOLO mode:**

- Worktrees don't provide real isolation
- `cc wt yolo` still has full host access
- Sandboxes truly isolate risky operations
- Docker is industry-standard for isolation

**Use cases worktrees can't solve:**

- Running untrusted code (e.g., from Stack Overflow)
- Testing package installations without polluting host
- Enforcing network firewall rules
- Guaranteed clean environment

**User mental model:**

- `cc wt` = "I trust this code, work in parallel"
- `cc sand` = "I don't trust this, isolate it"

#### Argument AGAINST cc sand:

**Worktrees already solve most problems:**

- Need to test breaking changes? → `cc wt yolo feature-test`
- Made a mistake? → `wt remove feature-test` (delete worktree)
- Want isolation? → Worktree + git reset is "good enough"

**Startup penalty:**

- Worktrees: <1s to create
- Sandboxes: ~5s to start
- For ADHD users, 5s is significant friction

**Extra dependency:**

- Worktrees: Built into git (everyone has it)
- Sandboxes: Requires Docker (not everyone has it)

**Complexity:**

- Two systems with similar names/purposes = confusing
- "When do I use wt vs sand?" is a cognitive load

**Overlap with existing tools:**

- VS Code has DevContainers (same concept)
- Docker Desktop has sandboxes (official tool)
- We'd be reinventing what already exists

---

## Part 5: Recommended Solution

### Option A: Just Worktrees (Simplest)

**Keep:**

- `cc wt <branch>` - Worktree + Claude
- `cc wt yolo <branch>` - Worktree + YOLO mode

**Add:**

- `cc wt yolo pick` - Pick project → worktree → YOLO

**Remove:**

- Don't implement `cc sand` at all

**Philosophy:** "Worktrees + git discipline is good enough for 95% of use cases"

**Pros:**

- ✅ Zero new dependencies
- ✅ Instant startup (ADHD-friendly)
- ✅ Simple mental model (one isolation tool)
- ✅ Native git integration

**Cons:**

- ❌ No true isolation (trust-based only)
- ❌ Can't enforce network rules
- ❌ Can't run truly untrusted code

**When this fails:**

- User needs to run code they don't trust → Use Docker Desktop directly
- User needs network isolation → Use Docker Desktop with firewall

### Option B: Worktrees + Optional Sandbox Flag (Middle Ground)

**Keep:**

- `cc wt <branch>` - Worktree + Claude
- `cc wt yolo <branch>` - Worktree + YOLO mode

**Add:**

- `cc yolo --sandbox` - Current dir + YOLO + Docker (opt-in)
- `cc wt yolo --sandbox <branch>` - Worktree + YOLO + Docker

**Philosophy:** "Worktrees by default, sandboxes when explicitly needed"

**Pros:**

- ✅ Simple default (worktrees)
- ✅ Safety escape hatch (sandbox flag)
- ✅ Progressive disclosure (learn sandbox later)
- ✅ No new top-level command

**Cons:**

- ⚠️ Slightly complex (need to know about flag)
- ⚠️ Still requires Docker for sandbox users

**When to use:**

```bash
# Normal: Use worktree (fast, trusted)
cc wt yolo feature/auth

# Paranoid: Add --sandbox flag (slow, isolated)
cc wt yolo --sandbox feature/auth
```

### Option C: Full Sandbox Support (Most Complete)

**Keep:**

- `cc wt <branch>` - Worktree + Claude
- `cc wt yolo <branch>` - Worktree + YOLO mode

**Add:**

- `cc sand` - Sandbox + Claude
- `cc sand yolo` - Sandbox + YOLO mode
- `cc sand pick` - Pick project → sandbox

**Philosophy:** "Two tools for two different problems"

**Pros:**

- ✅ Full feature parity (worktrees and sandboxes)
- ✅ Clear separation (wt = parallel, sand = isolated)
- ✅ Best safety for YOLO mode

**Cons:**

- ❌ More complexity (two systems)
- ❌ User confusion (which to use?)
- ❌ Maintenance burden (test both paths)
- ❌ Requires Docker (extra dependency)

---

## Part 6: Decision Matrix

### When to Use What (If We Had Both)

| Scenario                      | Command                  | Reasoning                    |
| ----------------------------- | ------------------------ | ---------------------------- |
| Work on 2 features at once    | `cc wt <branch>`         | ⚡ Fast, parallel work       |
| Quick experiment with YOLO    | `cc wt yolo test-branch` | ⚡ Fast, disposable worktree |
| Run Stack Overflow code       | `cc sand yolo`           | 🔒 Untrusted source          |
| Large refactoring (trusted)   | `cc wt yolo <branch>`    | ⚡ Fast, git safety net      |
| Large refactoring (untrusted) | `cc sand yolo`           | 🔒 Extra isolation           |
| Test package installation     | `cc sand`                | 🔒 Won't pollute host        |
| Review PR with risky code     | `cc sand yolo`           | 🔒 Isolated review           |
| Daily development             | `cc` or `cc wt`          | ⚡ No overhead               |

**Problem:** Most scenarios favor worktrees (faster, simpler)
**Insight:** Sandboxes only needed for **untrusted code** or **network isolation**

---

## Part 7: What Other Tools Do

### Research: How Do Others Handle This?

#### VS Code DevContainers

**Approach:** Sandbox is **optional** via `.devcontainer/` folder

- Default: Work on host (fast)
- Opt-in: Reopen in container (isolated)

**Lesson:** Don't force sandboxes on everyone, make them opt-in

#### Docker Desktop

**Approach:** Sandboxes are **separate tool** (`docker sandbox run`)

- Not integrated with git workflow
- User explicitly chooses sandbox when needed

**Lesson:** Sandboxes are a distinct use case, not daily workflow

#### Cursor AI

**Approach:** No built-in sandboxes

- Trust-based model (user reviews all changes)
- Git is the safety net

**Lesson:** Most AI coding tools don't provide sandboxes

#### GitHub Codespaces

**Approach:** Everything in containers

- Development happens in cloud container
- No local isolation needed

**Lesson:** If you're going all-in on containers, go ALL in (not hybrid)

---

## Part 8: Proposed Final Design

### Recommendation: Option A+ (Worktrees + Manual Sandbox)

**Implementation:**

1. ✅ Keep `cc wt` (worktree integration) - Already implemented
2. ✅ Keep `cc yolo` (fast YOLO mode) - Already implemented
3. ❌ Don't implement `cc sand` - Too complex for marginal benefit
4. 📚 Document Docker Sandbox in YOLO-MODE-WORKFLOW.md as "Method 3"
5. 📚 Provide manual Docker commands for users who need isolation

**Rationale:**

- **KISS principle** - Keep it simple
- **ADHD-friendly** - Fast startup (no 5s penalty)
- **Trust-based** - Worktrees + git is enough for most users
- **Escape hatch** - Users who need Docker can use it directly

### What Users Get

```bash
# Fast workflows (what most people need)
cc                      # Current dir, acceptEdits
cc yolo                 # Current dir, YOLO mode
cc wt yolo <branch>     # Worktree, YOLO mode

# Safe isolation (advanced users, manual)
docker sandbox run docker/sandbox-templates:claude-code \
  -v $PWD:/workspace \
  -- claude --dangerously-skip-permissions
```

**Documentation approach:**

- YOLO-MODE-WORKFLOW.md has 3 methods:
  1. Method 1: VS Code Shift+Tab (limited auto-accept)
  2. Method 2: CLI --dangerously-skip-permissions (full YOLO, no isolation)
  3. Method 3: Docker Sandbox (full YOLO + isolation) ← **manual, documented**

**Benefit:** Users who care about isolation can learn about it, but it's not forced on everyone

---

## Part 9: When Worktrees Fail (Edge Cases)

### Scenarios Where Sandboxes Are Actually Better

1. **Running code from untrusted sources**
   - Example: Testing a package from npm/PyPI you don't fully trust
   - Worktree: ❌ Can still install malware on host
   - Sandbox: ✅ Limited to container

2. **Network isolation**
   - Example: Test code that should NOT access internet
   - Worktree: ❌ Has full network access
   - Sandbox: ✅ Can block network with firewall rules

3. **Consistent environment**
   - Example: Need specific Linux version, Node version, etc.
   - Worktree: ❌ Uses host environment
   - Sandbox: ✅ Container defines exact environment

4. **Truly disposable**
   - Example: Generate 100 files and want instant cleanup
   - Worktree: ⚠️ Need to delete all files (slower)
   - Sandbox: ✅ Delete container (instant)

5. **CI/CD automation**
   - Example: Nightly Claude Code tasks in GitHub Actions
   - Worktree: ⚠️ Needs clean repo state
   - Sandbox: ✅ Fresh environment every run

**Question:** How often do DT's workflows hit these scenarios?

- Untrusted code: Rarely (mostly own code)
- Network isolation: Never (always online)
- Consistent env: Never (Mac environment is stable)
- Truly disposable: Sometimes (experiments)
- CI/CD: Never (not automating Claude yet)

**Answer:** Probably 5% of use cases → Not worth core integration

---

## Part 10: Proposed Aliases (If We Keep Just Worktrees)

### Current Aliases (Already Exist)

```bash
cc                  # Launch Claude HERE
ccy                 # cc yolo (deprecated, use 'cc yolo')
ccw                 # cc wt (worktree)
ccwy                # cc wt yolo (worktree YOLO)
ccwp                # cc wt pick (worktree picker)
```

### Proposed: Simplify to Just These

```bash
cc                  # Launch Claude HERE (acceptEdits)
cc yolo             # Launch HERE (YOLO mode)
cc wt <branch>      # Worktree + Claude
cc wt yolo <branch> # Worktree + YOLO mode
cc wt pick          # Pick worktree → Claude
```

**Remove these deprecated aliases:**

```bash
ccy                 # Confusing (people don't know what it means)
```

**Don't add:**

```bash
ccs                 # (sandbox) - Not implementing
ccsy                # (sandbox yolo) - Not implementing
```

**Reasoning:** Keep aliases minimal, let users type full commands for clarity

---

## Part 11: What About "cc yolo" Name?

### The "YOLO" Problem

**Current:**

```bash
cc yolo             # Sounds fun, but what does it mean?
```

**Issues:**

- ❌ "YOLO" is slang (not professional)
- ❌ Doesn't explain what it does
- ❌ Confusing for new users ("You Only Live Once"?)

**Better names:**

```bash
cc fast             # Implies speed, skip prompts
cc trust            # Implies trust-based (no prompts)
cc auto             # Implies automatic (no prompts)
cc skip             # Implies skip prompts
```

**Counter-argument:**

- "YOLO" is memorable and fun (ADHD-friendly!)
- Already used in community (Stack Overflow, blog posts)
- Technical term now means "high-risk, high-reward"

**Recommendation:** Keep `cc yolo` as primary, add aliases

```bash
cc yolo             # Primary (memorable)
cc y                # Short form (already exists)

# Aliases for clarity
alias cc-fast='cc yolo'
alias cc-trust='cc yolo'
alias cc-auto='cc yolo'
```

---

## Part 12: Final Recommendation

### Simplest Viable Solution

**Implement:**

1. Keep current `cc` dispatcher as-is
2. Keep `cc wt` worktree integration
3. Keep `cc yolo` for fast workflows
4. Document Docker Sandbox as **manual Method 3** in YOLO guide
5. Don't implement `cc sand` command

**Documentation updates:**

1. YOLO-MODE-WORKFLOW.md:
   - Method 1: VS Code Shift+Tab
   - Method 2: CLI --dangerously-skip-permissions
   - Method 3: Docker Sandbox (manual, for advanced users)

2. Add new guide: WORKTREE-WORKFLOW.md:
   - When to use worktrees (parallel work)
   - When to use sandboxes (untrusted code)
   - How to choose between them

**Aliases:**

```bash
# Keep these
cc                  # Current dir, acceptEdits
cc yolo             # Current dir, YOLO mode
cc wt <branch>      # Worktree + Claude
cc wt yolo <branch> # Worktree + YOLO mode
ccw                 # Alias for cc wt
ccwy                # Alias for cc wt yolo

# Remove these (deprecated)
ccy                 # Too cryptic
```

**User experience:**

```bash
# Daily workflow (fast)
cc                  # 90% of the time

# Risky refactoring (fast + disposable)
cc wt yolo test-feature   # 9% of the time

# Untrusted code (manual Docker)
docker sandbox run ...    # 1% of the time
```

---

## Part 13: Decision Summary

### The Core Question: Do We Need cc sand?

**Answer: No, for these reasons:**

1. **Overlapping with worktrees** - Both provide "isolation" (different kinds)
2. **Worktrees are faster** - <1s vs ~5s (ADHD penalty)
3. **Worktrees cover 95% of use cases** - Parallel work + git safety
4. **Docker is already available** - Advanced users can use it directly
5. **Simpler mental model** - One primary isolation tool (worktrees)
6. **Less maintenance** - Don't need to test/doc two paths

### The Worktree vs Sandbox Decision Tree

```
Do you need to work on multiple branches at once?
└─ YES → Use worktrees (cc wt <branch>)
└─ NO ↓

Is the code untrusted (from external source)?
└─ YES → Use Docker Sandbox (manual command)
└─ NO ↓

Do you need network isolation/firewall rules?
└─ YES → Use Docker Sandbox (manual command)
└─ NO ↓

Just need fast YOLO mode for your own code?
└─ YES → Use cc yolo (or cc wt yolo for disposable worktree)
```

**Result:** 95% of use cases = worktrees, 5% = manual Docker

---

## Part 14: What This Means for flow-cli

### Implementation Checklist

**✅ Keep (Already Implemented):**

- [x] `cc` - Launch Claude HERE
- [x] `cc yolo` - YOLO mode HERE
- [x] `cc wt <branch>` - Worktree integration
- [x] `cc wt yolo <branch>` - Worktree YOLO mode
- [x] `ccw`, `ccwy` aliases

**❌ Don't Implement:**

- [ ] `cc sand` - Too complex, overlaps with worktrees
- [ ] `ccs`, `ccsy` aliases - Not needed
- [ ] Sandbox integration in CC dispatcher

**📚 Document (New):**

- [ ] WORKTREE-WORKFLOW.md - When/why to use worktrees
- [ ] Update YOLO-MODE-WORKFLOW.md - Add Docker Sandbox as Method 3 (manual)
- [ ] Update CC-DISPATCHER-REFERENCE.md - Clarify wt vs yolo

**🔧 Optional Future:**

- [ ] `cc yolo --sandbox` flag (opt-in Docker, if users request)
- [ ] `.cc-sandbox.json` config (if Docker flag gets popular)

---

## Summary

**TL;DR:**

- **Worktrees** = Fast parallel work, trust-based safety (git rollback)
- **Sandboxes** = Slow isolated experiments, untrusted code
- **Recommendation:** Keep worktrees (`cc wt`), skip sandboxes (`cc sand`)
- **Reasoning:** Worktrees solve 95% of use cases, Docker available for the other 5%

**Key Insight:** Don't implement `cc sand` - it's a solution looking for a problem that worktrees already solve better (for flow-cli's use cases)

**Next Steps:**

1. Keep current `cc` and `cc wt` implementation
2. Document Docker Sandbox as manual Method 3 in YOLO guide
3. Create WORKTREE-WORKFLOW.md to explain the decision
4. Remove `ccy` alias (deprecated)

---

**Last Updated:** 2026-01-01
**Status:** Decision made - Don't implement cc sand
**Confidence:** High (95% sure worktrees are enough)
