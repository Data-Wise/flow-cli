# Monorepo Commands - ADHD-Friendly Beginner's Tutorial

**For:** Complete beginners to monorepos and npm workspaces
**Time to read:** 10 minutes
**Hands-on practice:** 5 minutes

> **UPDATE 2025-12-20:** This project now uses a single CLI workspace. References to the `app` workspace have been kept for educational purposes, showing how multi-workspace projects work. The CLI-focused commands (`npm run dev`, `npm run test`) still apply.

---

## 🎯 What You'll Learn

By the end of this tutorial, you'll understand:
1. What a monorepo is (in simple terms)
2. How to run commands in this project
3. What each command does and when to use it

**No prior experience needed!**

---

## 📦 Part 1: What is a Monorepo? (2 min read)

### The Simple Explanation

Think of your project like a house:

**Regular project (single repo):**

```
🏠 One house = One project
```

**Monorepo (this project):**

```
🏘️ One neighborhood = Multiple projects living together
   ├── 🏠 App house (desktop application)
   └── 🏠 CLI house (command-line tools)
```

### Why Does This Matter?

Your project has **two separate but related parts**:

1. **App** (`app/` folder) - Desktop application (Electron)
2. **CLI** (`cli/` folder) - Command-line integration layer

They live in the same repository (the "neighborhood") and can share things, but they're separate projects.

---

## 🎮 Part 2: The Basic Pattern (1 min read)

All commands follow this simple pattern:

```bash
npm run [action]:[workspace]
```

**Breaking it down:**
- `npm run` - "Hey npm, run a command"
- `[action]` - What to do (dev, test, build)
- `:[workspace]` - Where to do it (app, cli, or both)

**Example:**

```bash
npm run test:cli
     ↑     ↑    ↑
    npm   test  cli
  (tool) (what) (where)
```

Translation: "Use npm to test the CLI workspace"

---

## 🚀 Part 3: Commands You'll Actually Use (5 min read)

### Category 1: Development (Running Code)

#### Command: `npm run dev`

**What it does:** Runs the desktop app in development mode
**When to use:** When you want to test the app with live reload
**Where it runs:** App workspace only

```bash
npm run dev
```

**Example output:**

```
> Starting Electron app...
> App running on http://localhost:3000
```

---

#### Command: `npm run dev:app`

**What it does:** Same as `npm run dev` (explicitly says "app")
**When to use:** When you want to be clear you're running the app
**Where it runs:** App workspace

```bash
npm run dev:app
```

**Why two commands?**
- `dev` = shortcut (most people want the app)
- `dev:app` = explicit (when you want to be clear)

---

#### Command: `npm run dev:cli`

**What it does:** Runs CLI tests (CLI doesn't have a "dev mode")
**When to use:** When developing/testing CLI features
**Where it runs:** CLI workspace

```bash
npm run dev:cli
```

**Example output:**

```
═══════════════════════════════════════════════
  ZSH Workflow CLI - Status Tests
═══════════════════════════════════════════════
✅ All status tests passed!
```

---

### Category 2: Testing (Making Sure Things Work)

#### Command: `npm test`

**What it does:** Tests EVERYTHING (both app and CLI)
**When to use:** Before committing code, to make sure nothing broke
**Where it runs:** All workspaces

```bash
npm test
```

**What happens:**
1. Tests the app (using Jest)
2. Tests the CLI (using custom tests)
3. Shows results for both

---

#### Command: `npm run test:app`

**What it does:** Tests only the app
**When to use:** When you changed app code and want quick feedback
**Where it runs:** App workspace only

```bash
npm run test:app
```

---

#### Command: `npm run test:cli`

**What it does:** Tests only the CLI
**When to use:** When you changed CLI code and want quick feedback
**Where it runs:** CLI workspace only

```bash
npm run test:cli
```

**Example output:**

```
🧪 Testing Status Adapter...
Test 1: Get Current Session ✅
Test 2: Get Project Status ✅
```

---

### Category 3: Building (Creating Final Version)

#### Command: `npm run build`

**What it does:** Builds the app for production
**When to use:** When you want to create a distributable version
**Where it runs:** App workspace only

```bash
npm run build
```

**What happens:**
- Takes your source code
- Packages it into a desktop app (.dmg for Mac)
- Puts result in `app/dist/`

---

#### Command: `npm run build:app`

**What it does:** Same as `npm run build` (explicit)
**When to use:** When you want to be clear you're building the app

```bash
npm run build:app
```

---

#### Command: `npm run build:all`

**What it does:** Builds all workspaces that need building
**When to use:** Before releasing, to build everything
**Where it runs:** Currently just app (CLI doesn't need building)

```bash
npm run build:all
```

**Note:** Right now this only builds the app, but in the future if you add more workspaces, this will build them all.

---

### Category 4: Cleanup (Fresh Start)

#### Command: `npm run clean`

**What it does:** Deletes all installed dependencies and build files
**When to use:** When things are broken and you want a fresh start
**What it removes:**
- `app/node_modules/`
- `cli/node_modules/`
- `node_modules/` (root)
- `app/dist/` (build output)

```bash
npm run clean
```

**⚠️ Warning:** This deletes files! You'll need to run `npm install` after.

---

#### Command: `npm run reset`

**What it does:** Cleans everything AND reinstalls dependencies
**When to use:** "Turn it off and on again" for npm projects
**Steps it runs:**
1. Deletes all `node_modules/` and build files
2. Runs `npm install` to reinstall everything fresh

```bash
npm run reset
```

**Use this when:**
- Weird errors you can't explain
- Dependencies seem corrupted
- You want a completely fresh start

---

## 🧠 Part 4: Decision Tree (Quick Reference)

```
What do you want to do?

├─ 🚀 Run the app
│  └─ npm run dev
│
├─ 🧪 Test my changes
│  ├─ Changed app code? → npm run test:app
│  ├─ Changed CLI code? → npm run test:cli
│  └─ Want to test everything? → npm test
│
├─ 📦 Build for distribution
│  └─ npm run build
│
└─ 🔧 Fix weird errors
   └─ npm run reset
```

---

## 💡 Part 5: Common Scenarios (Hands-On Examples)

### Scenario 1: First Time Setup

**Goal:** Get the project running for the first time

```bash
# Step 1: Install all dependencies
npm install

# Step 2: Test that everything works
npm test

# Step 3: Run the app
npm run dev
```

**Time:** 2-5 minutes (depending on internet speed)

---

### Scenario 2: Daily Development

**Goal:** Work on the app, make changes, test them

```bash
# Step 1: Start development mode
npm run dev

# (Make your code changes)

# Step 2: Test your changes
npm run test:app

# Step 3: If all good, you're done!
```

---

### Scenario 3: Working on CLI Features

**Goal:** Add or fix CLI functionality

```bash
# Step 1: Run CLI tests to see current state
npm run dev:cli

# (Make your code changes in cli/ folder)

# Step 2: Test again to see if it worked
npm run test:cli

# Step 3: Test everything to make sure nothing broke
npm test
```

---

### Scenario 4: Something is Broken

**Goal:** Fix weird errors or corrupted dependencies

```bash
# Nuclear option: Fresh start
npm run reset

# Wait for reinstall...

# Test that it works now
npm test
```

**Common reasons you'd do this:**
- "Module not found" errors
- "Cannot find package" errors
- Things that worked yesterday don't work today
- After pulling changes from git

---

### Scenario 5: Preparing for Release

**Goal:** Build the final app to share with others

```bash
# Step 1: Make sure everything works
npm test

# Step 2: Build the app
npm run build:all

# Step 3: Find your built app
ls app/dist/
```

**Result:** You'll have a `.dmg` file (Mac) or `.exe` (Windows) you can distribute

---

## 📊 Part 6: Command Cheat Sheet (Print This!)

| Command | Quick Description | Use When |
|---------|-------------------|----------|
| `npm run dev` | Run app in dev mode | Developing app |
| `npm run dev:cli` | Test CLI features | Developing CLI |
| `npm test` | Test everything | Before committing |
| `npm run test:app` | Test app only | Quick app check |
| `npm run test:cli` | Test CLI only | Quick CLI check |
| `npm run build` | Build app for release | Making distributable |
| `npm run clean` | Delete all installs | Need fresh start |
| `npm run reset` | Clean + reinstall | Fix weird errors |

---

## 🎯 Part 7: Practice Exercise (5 minutes)

Let's practice! Follow these steps:

### Exercise 1: Your First Test

```bash
# 1. Test the CLI (safest to start with)
npm run test:cli

# Did you see this?
# ✅ All status tests passed!
```

**✅ Success!** You just ran your first monorepo command!

---

### Exercise 2: Understanding Workspaces

```bash
# 1. Test ONLY the app
npm run test:app

# 2. Test ONLY the CLI
npm run test:cli

# 3. Test BOTH
npm test
```

**Notice:** The third command runs both of the first two!

---

### Exercise 3: Check What's Available

```bash
# See all available commands
npm run
```

**Look for:**
- All the commands we learned
- They're grouped by action (dev, test, build, etc.)

---

## 🚨 Common Mistakes & How to Avoid Them

### Mistake 1: Forgetting the Colon

```bash
# ❌ Wrong
npm run testcli

# ✅ Right
npm run test:cli
```

**Remember:** Action**:**workspace (with the colon!)

---

### Mistake 2: Running in Wrong Directory

```bash
# ❌ Wrong (in app/ folder)
cd app/
npm run dev:app  # Won't work!

# ✅ Right (in root folder)
cd /Users/dt/projects/dev-tools/flow-cli/
npm run dev:app  # Works!
```

**Remember:** Always run from the **root** of the project (where the main `package.json` is)

---

### Mistake 3: Not Installing Dependencies First

```bash
# ❌ Wrong order
npm run dev     # Error: modules not found

# ✅ Right order
npm install     # Install first
npm run dev     # Then run
```

**Remember:** First time? Run `npm install` before anything else!

---

## 🎓 Part 8: What You Learned

Congratulations! You now know:

- ✅ What a monorepo is (multiple projects in one repo)
- ✅ The basic pattern (`npm run action:workspace`)
- ✅ How to develop (`npm run dev`)
- ✅ How to test (`npm test`)
- ✅ How to build (`npm run build`)
- ✅ How to fix problems (`npm run reset`)

---

## 🔗 Part 9: Where to Go Next

### If you want to learn more

1. **Explore the workspaces:**
   - `app/README.md` - Desktop app documentation
   - `cli/README.md` - CLI integration documentation

### If you get stuck

1. **Try the reset command:**

   ```bash
   npm run reset
   ```

2. **Check you're in the right place:**

   ```bash
   pwd
   # Should show: /Users/dt/projects/dev-tools/flow-cli
   ```

3. **Verify Node version:**

   ```bash
   node --version
   # Should show: v18.x.x or higher
   ```

---

## 💭 Part 10: Understanding the "Why"

### Why Separate Commands?

**Traditional approach:**

```bash
# One big test command
npm test
# Tests EVERYTHING (slow!)
```

**Workspace approach:**

```bash
# Test just what you changed
npm run test:cli   # Fast! Only CLI
npm run test:app   # Fast! Only app
npm test           # Slow but thorough
```

**Benefit:** Faster feedback while developing!

---

### Why the Colon Pattern?

The `:` creates a namespace:

```bash
npm run dev:app   # Dev mode for app
npm run dev:cli   # Dev mode for CLI
npm run test:app  # Test app
npm run test:cli  # Test CLI
```

**Pattern recognition:** Your brain learns the pattern quickly!
- First part = action (dev, test, build)
- Second part = target (app, cli, all)

**ADHD-friendly:** Predictable = easier to remember

---

### Why Clean and Reset?

Sometimes `node_modules/` gets corrupted:
- Interrupted installs
- Version conflicts
- Cached issues

**The fix:**

```bash
npm run clean   # Delete everything
npm install     # Fresh start
```

**Shortcut:**

```bash
npm run reset   # Does both!
```

**When to use:**
- After pulling big changes from git
- When you get "module not found" errors
- When nothing makes sense anymore

---

## 🎮 Quick Start Guide (TL;DR)

**Never used this before? Start here:**

```bash
# 1. First time setup
npm install

# 2. Make sure it works
npm test

# 3. Start developing
npm run dev

# 4. Made changes? Test them
npm run test:app  # or test:cli

# 5. Something broken?
npm run reset
```

**That's it! You're ready to go! 🚀**

---

## 📝 Notes for ADHD Users

### Memory Aids

**Can't remember the commands?**

```bash
# Just type this to see ALL commands
npm run
```

**Forget which workspace?**
- `app` = Desktop application
- `cli` = Command-line tools
- No suffix = Usually app (the main thing)

### Hyperfocus-Friendly

**In the zone and don't want to stop?**

```bash
# Quick test while coding
npm run test:app   # Super fast

# Full test when done
npm test           # Comprehensive
```

### Dopamine Hits

**Celebrate small wins!**

```bash
✅ All status tests passed!
```

Every green checkmark is progress! 🎉

---

**Tutorial created:** 2025-12-20
**For:** ADHD-optimized ZSH Workflow Manager
**Difficulty:** Beginner-friendly
**Estimated time:** 15-20 minutes total (read + practice)
