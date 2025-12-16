# Workflow Commands - Simple Fix

**TL;DR:** Make commands smarter so you don't have to type project names all the time.

---

## 🤔 The Problem

**Right now (annoying):**
```bash
# You're already IN the mediationverse folder
cd ~/projects/r-packages/active/mediationverse

# But you still have to type the name:
status mediationverse active P0 "Run sims" 85
```

**This is dumb because:**
- You're ALREADY in the folder
- Why type the name again?
- Too much typing = too many decisions

---

## ✨ The Fix

**Make it smart (detects where you are):**
```bash
# You're in the mediationverse folder
cd ~/projects/r-packages/active/mediationverse

# Just type this:
status active P0 "Run sims" 85
```

**What changed:**
- ✅ Removed project name (detects automatically)
- ✅ 12 fewer characters
- ✅ Zero decisions

---

## 📋 Three Simple Changes

### Change 1: Smart `status`

**Before:**
```bash
status mediationverse active P0 "Task" 85  # Must type name
```

**After:**
```bash
# When you're IN a project folder:
status active P0 "Task" 85  # Auto-detects!

# When you're NOT in a project folder:
status  # Shows picker of all projects
```

---

### Change 2: Smart `work`

**Before:**
```bash
work mediationverse  # Must type name
```

**After:**
```bash
# When you're IN a project folder:
work  # Just opens it!

# When you're NOT in a project folder:
work  # Shows picker (like js does)
```

---

### Change 3: Short names work (fuzzy match)

**Before:**
```bash
status mediationverse  # Must type full name
```

**After:**
```bash
status med  # Matches "mediationverse"
work stat   # Matches "stat-440"
```

---

## 🎯 Real Example

### Scenario: Update status of current project

**NOW (6 steps, lots of typing):**
```bash
pwd  # Check where you are
# /Users/dt/projects/r-packages/active/mediationverse

status mediationverse active P0 "Run final sims" 85
# ↑ Had to type "mediationverse" even though I'm already here
```

**AFTER FIX (2 steps, less typing):**
```bash
cd ~/projects/r-packages/active/mediationverse

status active P0 "Run final sims" 85
# ↑ Auto-detects I'm in mediationverse!
```

---

## 💡 How It Works

**Simple logic:**

1. **You run `status`**

2. **Command checks: "Am I in a project folder?"**
   - YES → Use this folder
   - NO → Show picker of all projects

3. **Done!**

---

## 🚀 What You Need to Know

### When IN a project:
```bash
status              # Shows current project
status active P0 "Task" 85  # Updates current project
work                # Opens current project
```

### When NOT in a project:
```bash
status              # Picker appears
work                # Picker appears (like js)
```

### From anywhere:
```bash
status med          # Fuzzy match → mediationverse
work stat           # Fuzzy match → stat-440
```

---

## ✅ Three Commands. Three Rules.

| Command | When IN project | When NOT in project |
|---------|----------------|---------------------|
| `status` | Auto-detects current | Shows picker |
| `work` | Opens current | Shows picker (like js) |
| `dash` | (unchanged) | Shows dashboard |

**That's it.**

---

## 🎨 Visual Comparison

### BEFORE (Current System)

```
You: cd ~/projects/r-packages/active/mediationverse
     pwd
     # Check where I am...

     status mediationverse active P0 "Task" 85
     # ↑ Why am I typing this again??
```

**Feels like:** 😤 Lots of typing, lots of decisions

---

### AFTER (Smart System)

```
You: cd ~/projects/r-packages/active/mediationverse

     status active P0 "Task" 85
     # ↑ It knows where I am!
```

**Feels like:** 😊 Just works

---

## 🔧 Implementation

**How long:** 2-3 hours

**Breaking changes:** None (old way still works)

**What changes:**
1. `status` detects current folder
2. `work` detects current folder
3. Both accept short names (fuzzy match)

**What stays the same:**
- `dash` (unchanged)
- `js` (unchanged)
- All explicit names still work

---

## ❓ FAQ

**Q: What if I'm not in a project folder?**
A: You'll get a picker to choose from.

**Q: What if I want to update a DIFFERENT project?**
A: Use the project name: `status medfit active P0 "Task" 85`

**Q: Does `dash` change?**
A: No, stays the same.

**Q: What if I type `status med` and there are two matches?**
A: You'll get a picker showing both.

**Q: Can I still use full names?**
A: Yes! `status mediationverse ...` still works.

---

## 🎯 Bottom Line

**One change:**
Commands detect where you are and do the smart thing.

**Result:**
- ✅ Less typing
- ✅ Fewer decisions
- ✅ Works like you expect

**Time to build:** 2-3 hours

**Should we do it?** 👍 or 👎

---

## 📊 Decision Helper

**If you want:**
- Less typing → YES
- Commands that "just work" → YES
- Fewer decisions → YES
- Keep everything the same → NO

---

*That's the whole proposal. Simple fix, big impact.*
