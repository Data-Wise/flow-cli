# Why "status" is Confusing

## 🤔 The Core Problem

**The word "status" is a NOUN, not a VERB.**

```bash
status mediationverse
```

**What does this do?**

- Show status? ❓
- Update status? ❓
- Create status? ❓
- All of the above? ❓

**You can't tell from the command name!**

---

## 🧠 ADHD Brain Analysis

### When you see: `git status`

**Your brain knows:** "This shows me the current state"

### When you see: `git add`

**Your brain knows:** "This adds files"

### When you see: `status mediationverse`

**Your brain:** "Uhhh... what?" 😵

---

## 📊 What the Command Actually Does

Looking at the code, `status` does **THREE different things**:

1. **Show status** (read-only)

   ```bash
   status mediationverse --show
   ```

2. **Update status** (write)

   ```bash
   status mediationverse  # Interactive prompts
   status mediationverse active P0 "Task" 85  # Quick mode
   ```

3. **Create status** (create new)
   ```bash
   status mediationverse --create
   ```

**This violates the "do one thing" principle!**

---

## 🎯 Better Patterns from Other Tools

### Git (Clear Verbs)

```bash
git show    # Shows something
git add     # Adds something
git commit  # Commits something
git status  # Shows status (OK because "status" = "show state")
```

**Pattern:** Verb commands, clear actions

---

### GitHub CLI (Resource-based)

```bash
gh issue list      # List issues
gh issue create    # Create issue
gh issue view      # View issue
gh pr create       # Create PR
```

**Pattern:** `gh <resource> <action>`

---

### NPM (Action words)

```bash
npm install   # Install
npm update    # Update
npm run       # Run
npm test      # Test
```

**Pattern:** Clear action verbs

---

## 💡 Alternative Approaches

### Option 1: Separate Commands (Clearest)

```bash
# Show current project
here
# or
show

# Update current project (interactive)
update

# Create .STATUS for current project
track
# or
init
```

**Pros:**

- ✅ Each command does ONE thing
- ✅ Clear verb names
- ✅ Easy to remember
- ✅ Works on current directory (no project name needed)

**Cons:**

- ❌ Three commands instead of one

---

### Option 2: Resource-Based (Git-style)

```bash
# All project operations under one namespace
proj show       # Show current
proj update     # Update current
proj init       # Create .STATUS

# Alternative names
p show
p update
p init
```

**Pros:**

- ✅ Clear hierarchy
- ✅ One namespace
- ✅ Discoverable (proj <tab>)

**Cons:**

- ❌ More typing
- ❌ Need to remember "proj" namespace

---

### Option 3: Smart Single Command (Context-aware)

```bash
# One command, different behavior based on context

# If .STATUS exists → show it
here

# If .STATUS exists + args → update it
here update

# If .STATUS doesn't exist → create it
here init
```

**Pros:**

- ✅ One command to learn
- ✅ Context-aware
- ✅ Short name

**Cons:**

- ❌ Still does multiple things
- ❌ Less clear than separate commands

---

### Option 4: Natural Language (Most ADHD-friendly)

```bash
# Show current project
what

# Update current project
set active
set P0
set "Run sims"
set 85%

# Or combined
update
> prompts...
```

**Pros:**

- ✅ Natural language
- ✅ Reads like English
- ✅ Each action is clear

**Cons:**

- ❌ "what" might conflict with other tools

---

## 🎨 My Recommendation (Option 1 + tweaks)

### Three Simple Commands:

**1. Show current project**

```bash
here
# or
.
```

Shows .STATUS of current directory.

**2. Update current project**

```bash
update
# or
set
```

Interactive prompts to update .STATUS.

**3. Start tracking**

```bash
track
# or
init
```

Create .STATUS in current directory.

---

## 📋 Real Examples

### Current (Confusing)

```bash
cd ~/projects/r-packages/active/mediationverse
status mediationverse --show    # Show
status mediationverse           # Update??
status mediationverse --create  # Create
```

### Proposed (Clear)

```bash
cd ~/projects/r-packages/active/mediationverse

here      # Show current project
update    # Update current project (prompts)
track     # Start tracking (create .STATUS)
```

**Much clearer!**

---

## 🚀 Additional Benefits

### Works with `dash` and `js`:

```bash
# Morning routine
dash        # See all projects
js          # Pick one (goes to that folder)
here        # See details
update      # Make changes
```

### Works with `work`:

```bash
cd ~/projects/r-packages/active/mediationverse
here        # Quick check
work        # Start working
```

---

## ✅ Decision Matrix

| Option                                | Clarity | ADHD Score | Breaking Changes | Effort    |
| ------------------------------------- | ------- | ---------- | ---------------- | --------- |
| Keep `status`                         | 3/10    | 4/10       | None             | 0 hours   |
| Separate commands (here/update/track) | 10/10   | 10/10      | Major            | 2-3 hours |
| Resource-based (proj show/update)     | 8/10    | 7/10       | Major            | 2-3 hours |
| Smart single (here)                   | 7/10    | 7/10       | Major            | 2-3 hours |
| Natural language (what/set)           | 9/10    | 9/10       | Major            | 2-3 hours |

---

## 🎯 Final Recommendation

**Use Option 1: Three separate commands**

```bash
here      # Show current project status
update    # Update current project (interactive)
track     # Create .STATUS for current project
```

**Why:**

1. ✅ Each command name tells you EXACTLY what it does
2. ✅ No ambiguity
3. ✅ Works on current directory (no project name needed)
4. ✅ Follows Unix philosophy (do one thing well)
5. ✅ Easy to remember
6. ✅ Perfect for ADHD (clear, direct, simple)

**Aliases for muscle memory:**

```bash
alias .='here'           # Super short
alias up='update'        # Quick update
alias st='here'          # For people who type 'status'
```

---

## 📊 Full Workflow Comparison

### CURRENT (Confusing)

```bash
dash                              # See projects
cd ~/projects/r-packages/active/mediationverse
status mediationverse --show      # Show (why type name?)
status mediationverse             # Update (prompts)
```

### PROPOSED (Clear)

```bash
dash                              # See projects
cd ~/projects/r-packages/active/mediationverse
here                              # Show (auto-detects!)
update                            # Update (prompts)
```

**27 fewer characters typed!**
**100% clearer what each command does!**

---

**Should we switch to `here`, `update`, `track`?** 👍 or 👎
