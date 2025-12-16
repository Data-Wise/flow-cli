# CLI Command Patterns Research
# Research: Status/State Management in Developer Tools

**Date:** 2025-12-14
**Purpose:** Find better alternatives to confusing `status` command
**Current Problem:** `status` does 3 things (show/update/create) - unclear what action it performs

---

## Executive Summary

### The Core Problem

Your `status` command suffers from **action ambiguity**:
- No arguments = interactive update (NOT show!)
- `--show` flag = show current status
- `--create` flag = create new .STATUS file
- 5+ arguments = quick update

**The confusion:** Users expect `status` (noun) to **show** state, not **change** it.

### Key Finding

**Best practice:** Separate commands by action (verbs) > Combined commands with modes

---

## Pattern Analysis: Popular CLI Tools

### 1. Git - The Gold Standard

**Command Structure:**
```bash
git status              # NOUN - Shows current state (read-only)
git add                 # VERB - Modifies state
git commit              # VERB - Modifies state
git show                # VERB - Shows something
git config --get        # VERB + flag for action
git config --set        # VERB + flag for action
```

**Pattern:** **VERB-first commands** with nouns as objects
- `status` is READ-ONLY (the exception - it's a noun that only reads)
- All state changes are VERBS (add, commit, push, pull, merge)
- When verbs have multiple modes, flags clarify (`--get` vs `--set`)

**Key Insight:** The word "status" has been claimed by Git to mean "show current state, read-only"

**ADHD Score:** 9/10
- Clear verbs = clear actions
- `git status` is universally understood as "show me what's happening"
- No ambiguity about what will change

---

### 2. GitHub CLI (gh) - Resource-Based

**Command Structure:**
```bash
gh pr view              # RESOURCE + ACTION
gh pr create            # RESOURCE + ACTION
gh pr edit              # RESOURCE + ACTION
gh issue list           # RESOURCE + ACTION
gh repo view            # RESOURCE + ACTION
```

**Pattern:** **RESOURCE + VERB** (noun + verb)
- First word = what you're working with (pr, issue, repo)
- Second word = what you're doing to it (view, create, edit, list)

**ADHD Score:** 8/10
- Two-word structure is longer but very clear
- Auto-complete friendly
- Scales well (many resources, many actions)

---

### 3. npm/yarn - Mixed Patterns

**Command Structure:**
```bash
npm install             # VERB
npm run                 # VERB
npm list                # VERB
npm view                # VERB
npm config get          # NOUN + VERB
npm config set          # NOUN + VERB
```

**Pattern:** Mix of **VERB-first** and **RESOURCE + VERB**
- Simple commands are verbs (install, run, list)
- Complex subsystems use resource+verb (config get/set)

**ADHD Score:** 7/10
- Mostly consistent
- `config get/set` is clear but longer
- Some verbs are non-obvious (view vs show vs list)

---

### 4. tmux - Verbose but Clear

**Command Structure:**
```bash
tmux show-options       # VERB-NOUN (show what?)
tmux set-option         # VERB-NOUN (set what?)
tmux display-message    # VERB-NOUN
tmux list-sessions      # VERB-NOUN
```

**Pattern:** **VERB-NOUN compounds** (hyphenated)
- Very explicit
- Self-documenting
- Long but unambiguous

**ADHD Score:** 6/10
- Very clear what each command does
- Too long for frequent use
- Excellent for discoverability

---

### 5. cargo (Rust) - Verb-First

**Command Structure:**
```bash
cargo build             # VERB
cargo test              # VERB
cargo run               # VERB
cargo update            # VERB
cargo check             # VERB
```

**Pattern:** **Pure VERB** commands
- All actions are verbs
- Short and memorable
- Context (Rust project) provides the noun

**ADHD Score:** 9/10
- Ultra-clear action words
- Short commands
- No ambiguity

---

### 6. kubectl - Resource-Based with Complexity

**Command Structure:**
```bash
kubectl get pods        # VERB + RESOURCE
kubectl describe pod    # VERB + RESOURCE
kubectl edit pod        # VERB + RESOURCE
kubectl apply           # VERB (resource in file)
kubectl delete pod      # VERB + RESOURCE
```

**Pattern:** **VERB + RESOURCE** (opposite of gh)
- Verb first (what to do)
- Resource second (what to do it to)

**ADHD Score:** 8/10
- Clear action verbs
- Flexible resource types
- Can be verbose

---

### 7. Task Management Tools

**taskwarrior:**
```bash
task add                # VERB
task list               # VERB
task done               # VERB
task modify             # VERB
```

**todo.txt:**
```bash
todo.sh add             # VERB
todo.sh list            # VERB
todo.sh do              # VERB
```

**Pattern:** **VERB commands** for actions

**ADHD Score:** 9/10 (taskwarrior), 8/10 (todo.txt)
- Simple verbs
- Memorable
- Clear intent

---

## Pattern Summary Table

| Tool | Pattern | Show Command | Update Command | ADHD Score |
|------|---------|--------------|----------------|------------|
| Git | VERB-first | `git status` | `git add/commit` | 9/10 |
| GitHub CLI | RESOURCE+VERB | `gh pr view` | `gh pr edit` | 8/10 |
| npm | Mixed | `npm list` | `npm install` | 7/10 |
| tmux | VERB-NOUN | `tmux show-options` | `tmux set-option` | 6/10 |
| cargo | Pure VERB | (build shows) | `cargo update` | 9/10 |
| kubectl | VERB+RESOURCE | `kubectl get` | `kubectl edit` | 8/10 |
| taskwarrior | VERB | `task list` | `task modify` | 9/10 |

---

## Key Principles for ADHD-Friendly Commands

### 1. Action Clarity
**Good:**
- `show` - I will see something
- `update` - I will change something
- `create` - I will make something new

**Bad:**
- `status` - Will it show or change? Unclear!
- `manage` - Too vague
- `handle` - What does this do?

### 2. Verb > Noun for Actions
**Good:**
- `update-status` (verb first)
- `show-status` (verb first)

**Bad:**
- `status --update` (noun first, action hidden in flag)
- `status` (noun, action unclear)

### 3. Consistency Wins
- If you use `show-X`, use `update-X` (not `change-X`)
- If you use `get-X`, use `set-X` (not `put-X`)
- Parallel structure aids memory

### 4. Short Commands for Frequent Use
- Daily use: 1-4 characters ideal (`js`, `dash`, `work`)
- Weekly use: 4-8 characters acceptable
- Rare use: Longer is OK if self-documenting

### 5. Avoid Multi-Mode Commands
**Bad pattern:**
```bash
status            # Interactive update
status --show     # Show
status --create   # Create
```

**Better pattern:**
```bash
pshow             # Project show (or: dash)
pupdate           # Project update
pcreate           # Project create
```

---

## Recommendations for Your System

### Current Problem Analysis

Your `status` command:
```bash
status mediationverse              # → Interactive UPDATE (unexpected!)
status mediationverse --show       # → Show (expected, but needs flag)
status mediationverse --create     # → Create (unexpected from "status")
status medfit active P1 "Task" 60  # → Quick UPDATE (reasonable)
```

**Why it's confusing:**
1. Default behavior is UPDATE, not SHOW (violates Git's `status` convention)
2. Name is a NOUN, but primary action is a VERB (update)
3. Multi-mode with hidden actions
4. Requires flags to do the "obvious" thing (show)

---

### Solution Option A: Pure VERB Commands

**Separate everything:**
```bash
pshow <project>                    # Show status (or use existing 'dash')
pupdate <project>                  # Interactive update
pset <project> <status> <pri>...   # Quick update
pinit <project>                    # Create new .STATUS
```

**Pros:**
- Crystal clear action words
- No ambiguity
- Follows Git/cargo pattern
- Easy to remember (all start with 'p')

**Cons:**
- More commands to remember
- `pshow` duplicates `dash` functionality

**ADHD Score:** 9/10

---

### Solution Option B: Keep Short, Split Actions

**Use your existing pattern of ultra-short commands:**
```bash
dash [project]                     # KEEP - Show status (already exists)
pup <project>                      # Project update (interactive)
pup <project> <status> <pri>...    # Project update (quick)
pinit <project>                    # Project init (create .STATUS)
```

**Pros:**
- `dash` already handles "show" perfectly
- `pup` = "project update" (clear verb)
- Only 2 new commands (pup, pinit)
- Follows your 1-char to 4-char philosophy

**Cons:**
- "pup" might be too cute
- Could conflict with Python's `pip`

**ADHD Score:** 8/10

---

### Solution Option C: Resource-Based (gh style)

**Use 'project' as the resource:**
```bash
proj show <name>                   # Show status
proj update <name>                 # Interactive update
proj set <name> <status> <pri>...  # Quick update
proj init <name>                   # Create .STATUS
```

**Pros:**
- Follows GitHub CLI pattern (familiar)
- Self-documenting
- Expandable (could add `proj list`, `proj search`, etc.)
- Clear namespace

**Cons:**
- Two-word commands (longer)
- Duplicates `dash` for show

**ADHD Score:** 7/10 (clear but verbose)

---

### Solution Option D: Hybrid (Recommended)

**Keep best of current, minimize changes:**
```bash
dash [project]                     # KEEP - Show all or one project
up <project>                       # Update status (interactive)
up <project> <status> <pri>...     # Update status (quick)
pinit <project>                    # Create .STATUS (rare operation)
```

**Changes from current:**
- Rename `status` → `up` (ultra-short verb)
- Remove `status --show` (use `dash` instead)
- Keep `status --create` as `pinit` (project init)

**Pros:**
- Minimal disruption (status → up)
- `up` is clear verb (update)
- Ultra-short for daily use (2 chars!)
- Leverages existing `dash` command
- Only one command to change

**Cons:**
- `up` might conflict with uptime or other tools
- Not as self-documenting as longer names

**ADHD Score:** 9/10 ⭐ RECOMMENDED

---

### Solution Option E: Context-Aware Single Command

**Make behavior obvious from arguments:**
```bash
set <project>                      # Interactive update (no other args)
set <project> <status> <pri>...    # Quick update (has args)
init <project>                     # Create .STATUS (different command)
# For show: use existing 'dash'
```

**Pros:**
- `set` is universally understood (Git uses it)
- Clear verb for changing state
- Context determines mode (interactive vs quick)
- Only 2 commands total

**Cons:**
- Can't show with same command (but `dash` handles this)

**ADHD Score:** 8/10

---

## Comparison Matrix

| Solution | Show | Update | Create | Total Commands | ADHD Score |
|----------|------|--------|--------|----------------|------------|
| **Current** | `status --show` | `status` | `status --create` | 1 (multi-mode) | 5/10 |
| **Option A** | `pshow` | `pupdate` | `pinit` | 3 | 9/10 |
| **Option B** | `dash` | `pup` | `pinit` | 2 new | 8/10 |
| **Option C** | `proj show` | `proj update` | `proj init` | 1 (multi-mode) | 7/10 |
| **Option D** ⭐ | `dash` | `up` | `pinit` | 2 new | 9/10 |
| **Option E** | `dash` | `set` | `init` | 2 new | 8/10 |

---

## Final Recommendation: Option D + Variants

### Primary Recommendation: Ultra-Short Verbs

```bash
# SHOW - Use existing command
dash                               # Show all projects
dash mediationverse                # Show one project

# UPDATE - New ultra-short verb
up <project>                       # Interactive update
up medfit active P1 "Docs" 60      # Quick update

# CREATE - Rare operation, can be longer
pinit <project>                    # Project init (create .STATUS)
```

**Why this wins:**
1. Leverages existing `dash` (no duplication)
2. `up` is 2 chars (ultra-fast for daily use)
3. `up` clearly means "update" (verb)
4. `pinit` is rare, longer name is fine
5. Minimal migration (one command rename)

### Alternative: Slightly More Explicit

If `up` feels too short, consider:

```bash
dash [project]                     # Show (existing)
pset <project> ...                 # Project set (like git config set)
pinit <project>                    # Project init
```

### Alternative: Match Your Workflow

Look at your other workflow commands:
```bash
work <name>                        # Start work (verb)
finish [msg]                       # End work (verb)
js                                 # Just start (verb)
dash                              # Dashboard (noun, but read-only)
```

**Pattern:** Your successful commands are mostly VERBS!

Match this pattern:
```bash
dash [project]                     # Keep (exception: noun, read-only)
track <project>                    # Track project status (update)
start <project>                    # Start new project (create)
```

---

## Migration Path

### Step 1: Add Aliases (Test Period)
```bash
alias up='status'                  # Test new name
alias pinit='status --create'      # Test create
```

### Step 2: Use Both for 1 Week
- Keep `status` working
- Try `up` in daily workflow
- Gather feedback from muscle memory

### Step 3: Deprecate Old Name
```bash
status() {
    echo "⚠️  'status' is deprecated. Use 'up' or 'dash' instead."
    echo "  dash $@     # Show status"
    echo "  up $@       # Update status"
}
```

### Step 4: Remove (After 2 Weeks)
- Delete `status` function
- Keep `up` and `pinit`
- Update all documentation

---

## Real-World Examples of Good Naming

### From Your Own System (What Works)

**Already excellent:**
- `js` - Just start (clear action, ultra-short)
- `dash` - Dashboard (noun OK because read-only)
- `work` - Start working (clear verb)
- `finish` - End session (clear verb)

**The pattern:** Short verbs for frequent actions!

### From Git (Why It Works)

```bash
git add                # Verb: add files
git commit             # Verb: commit changes
git push               # Verb: push to remote
git status             # Exception: noun, but universally read-only
```

**The lesson:** If you use `status`, make it read-only like Git!

---

## Conclusion

### The Problem
`status` violates user expectations:
- Looks like a noun (read-only)
- Acts like a verb (modifies state)
- Default action is UPDATE (not show)

### The Solution
**Recommended: Option D**
```bash
dash [project]         # Show status (existing, keep)
up <project> [args]    # Update status (new, ultra-short verb)
pinit <project>        # Project init (new, rare use)
```

### Why This Works
1. **Action clarity:** `up` = update (verb)
2. **ADHD-friendly:** 2 characters for daily use
3. **Consistent:** Matches your `js`, `work`, `finish` pattern
4. **Leverages existing:** Uses `dash` for show
5. **Minimal migration:** One command rename

### Implementation
1. Rename `status()` → `up()`
2. Remove `--show` flag logic (use `dash` instead)
3. Move `--create` logic → `pinit()`
4. Update help text and docs
5. Add deprecation warning for `status`

---

## References

- Git command conventions: Verb-first, except `status` (read-only noun)
- GitHub CLI: Resource + Verb pattern (`gh pr view`)
- cargo/npm: Pure verb commands for actions
- Your successful patterns: `js`, `work`, `finish` (all verbs!)

---

**Next Steps:**
1. Decide on preferred option (recommend D)
2. Test with aliases for 1 week
3. Migrate incrementally
4. Update all documentation

