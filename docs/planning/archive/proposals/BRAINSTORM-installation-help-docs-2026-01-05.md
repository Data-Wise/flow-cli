# 🧠 BRAINSTORM: Installation & Help Documentation Improvements

**Created:** 2026-01-05
**Context:** Post v4.8.1 Homebrew documentation overhaul
**Goal:** Identify gaps and improvements for installation and help systems

---

## 📊 Current State Analysis

### ✅ What's Already Complete (v4.8.1)

#### Installation Documentation - EXCELLENT

- **README.md** - Homebrew-first installation ⭐
- **docs/getting-started/installation.md** - Comprehensive (300+ lines)
  - Homebrew, plugin managers, manual install
  - Update/uninstall instructions
  - Troubleshooting section
- **docs/getting-started/quick-start.md** - 5-minute tutorial
- **docs/getting-started/faq.md** - Common questions answered
- **docs/getting-started/00-welcome.md** - Learning paths
- **docs/index.md** - Landing page with install instructions
- **install.sh** - One-liner installer ✅ EXISTS!
- **uninstall.sh** - Clean removal script ✅ EXISTS!

**Status:** 🟢 Installation docs are **comprehensive and well-organized**

#### Help System - SOLID FOUNDATION

- **`flow help`** - Main help command with categories
- **`flow help --list`** - List all commands
- **`flow help --search`** - Search functionality
- **19 command-specific help pages** in `docs/commands/`
- **8 dispatcher reference docs** (cc, g, mcp, obs, qu, r, tm, wt)
- **Multiple reference cards** (COMMAND-QUICK-REFERENCE, ALIAS-REFERENCE-CARD, etc.)
- **11 tutorials** in `docs/tutorials/`
- **9 guides** in `docs/guides/`
  - 00-START-HERE.md - Onboarding guide
  - DOPAMINE-FEATURES-GUIDE.md
  - WORKTREE-WORKFLOW.md
  - YOLO-MODE-WORKFLOW.md
  - etc.

**Status:** 🟡 Help system exists but **discoverability could be improved**

---

## 🎯 Identified Gaps & Opportunities

### Gap 1: Post-Install First-Run Experience

**Current:** User installs via Homebrew → commands work → **what now?**
**Missing:**

- No automatic first-run wizard
- No "getting started" prompt after install
- No verification that tools are installed correctly

**Impact:** High - Users don't know what to do after installing

**Quick Win:** Trigger welcome message on first `work` command

---

### Gap 2: Interactive Help Discovery

**Current:** `flow help` shows text list
**Missing:**

- No interactive help browser
- No searchable help interface
- No contextual help suggestions

**Impact:** Medium - Users have to read through walls of text

**Quick Win:** Add `flow help --interactive` with fzf picker

---

### Gap 3: Command Examples in Help

**Current:** Help shows syntax but limited examples
**Missing:**

- Real-world use cases
- Common workflows
- Error examples and solutions

**Impact:** Medium - Users learn slower without examples

**Quick Win:** Add "Examples" section to each `<command> help` output

---

### Gap 4: Progressive Feature Discovery

**Current:** All features documented, but overwhelming
**Missing:**

- "Feature of the day" tips
- Progressive disclosure (beginner → advanced)
- "Did you know?" hints

**Impact:** Low - Advanced features stay hidden

**Quick Win:** Add random tips to dashboard

---

### Gap 5: Video/Visual Content

**Current:** All text-based documentation
**Missing:**

- Video tutorials
- GIFs showing workflows
- ASCII cinema recordings

**Impact:** Medium - Visual learners need different format

**Long-term:** Create asciinema recordings for key workflows

---

### Gap 6: Troubleshooting Assistant

**Current:** Static troubleshooting doc
**Missing:**

- Interactive troubleshooter
- Auto-diagnosis of common issues
- Guided fix suggestions

**Impact:** Medium - Users get stuck and give up

**Medium Effort:** Enhance `flow doctor` with interactive mode

---

## 💡 Brainstorm: Quick Wins (< 30 min each)

### 1. ⚡ First-Run Welcome Message

**What:** Detect first run, show welcome + quick tour offer
**Where:** Hook into first `work` command
**How:**

```zsh
# In work command
if [[ ! -f ~/.config/flow-cli/.welcomed ]]; then
    _flow_first_run_welcome
    touch ~/.config/flow-cli/.welcomed
fi
```

**Benefit:** Users immediately know what commands exist

---

### 2. ⚡ Add "See also" to Help Output

**What:** Cross-reference related commands in help
**Example:**

```
$ flow help work
...
📚 See also:
   finish - End work session
   hop    - Quick project switch
   dash   - Project dashboard
```

**Benefit:** Improves discoverability

---

### 3. ⚡ Random Tips in Dashboard

**What:** Show helpful tips at bottom of `dash` output
**Example:**

```
💡 Tip: Use 'pick --recent' to see projects with Claude sessions
```

**Benefit:** Progressive feature discovery

---

### 4. ⚡ Quick Reference Card Command

**What:** `flow ref` shows one-page cheat sheet
**Output:** Pretty-printed reference from COMMAND-QUICK-REFERENCE.md

**Benefit:** Fast lookup without leaving terminal

---

### 5. ⚡ Command Usage Examples

**What:** Add real examples to every help function
**Template:**

```
EXAMPLES:
  $ work my-project          # Start working on project
  $ work                     # Interactive picker
  $ work -l                  # List recent projects
```

**Benefit:** Faster learning curve

---

## 🔧 Medium Effort (1-2 hours)

### 1. Interactive Help Browser

**What:** `flow help --interactive` or `flow help -i`
**Implementation:**

- Use fzf to browse all commands
- Show preview of help text
- Press Enter to see full help

**Mockup:**

```
> work - Start work session
  finish - End session
  dash - Project dashboard
  pick - Project picker
  ...

Preview:
work <project> - Start focused work session
Options:
  -l, --list    List recent projects
  -h, --help    Show this help
```

**Benefit:** Much better UX for exploring commands

---

### 2. Enhanced First-Run Wizard

**What:** Full onboarding flow (from v4.9.0 spec)
**Steps:**

1. Verify installation
2. Install recommended tools (`flow doctor --fix`)
3. Configure project directory
4. Quick tutorial (work → win → finish)

**Benefit:** Zero-friction onboarding

---

### 3. Context-Aware Help

**What:** `flow help` shows different content based on context
**Logic:**

```zsh
# In git repo → show git workflows
# In R package → show r dispatcher
# New user → show getting started
# Advanced user → show advanced features
```

**Benefit:** Relevant help at the right time

---

### 4. Command Aliases Reference

**What:** `flow alias` shows all aliases and what they do
**Output:**

```
Aliases:
  ccy  → cc yolo        # Claude Code in YOLO mode
  ccw  → cc wt          # Claude in worktree
  pickr → pick --recent # Recent projects only
  ...
```

**Benefit:** Discover shortcuts

---

### 5. Troubleshooter Mode

**What:** `flow doctor --diagnose` interactive troubleshooter
**Flow:**

```
What's the problem?
○ Commands not found after install
○ fzf picker not working
○ Claude Code not launching
○ Git workflows not working

[Based on selection, run diagnostics + suggest fixes]
```

**Benefit:** Self-service problem solving

---

## 🏗️ Long-term (Future sessions)

### 1. Video Tutorial Series

**What:** 5-10 minute videos for key workflows
**Topics:**

- Installation & Setup (1 min)
- Basic Workflow: work → win → finish (2 min)
- Project Picker & Dispatchers (3 min)
- Git Feature Workflow (4 min)
- ADHD Features (win, yay, streaks) (3 min)

**Platform:** YouTube + embedded in docs site

---

### 2. Interactive Tutorial Mode

**What:** `flow tutorial <topic>` - guided walkthrough
**Implementation:** Step-by-step with validation
**Example:**

```
$ flow tutorial basics

Step 1/5: Start a work session
Run: work my-project

[Wait for user to run command]

✓ Great! You started a work session.

Step 2/5: Log an accomplishment
Run: win "Completed tutorial step 1"

...
```

**Benefit:** Learn by doing

---

### 3. Searchable Documentation Site

**What:** Full-text search on https://data-wise.github.io/flow-cli/
**Implementation:** MkDocs search plugin
**Benefit:** Find answers fast

---

### 4. AI-Powered Help

**What:** `flow ask "how do I switch projects?"` → Claude answers
**Implementation:** Use flow-cli context + docs to answer
**Benefit:** Natural language help

---

### 5. Community Examples Library

**What:** User-contributed workflows and tips
**Location:** `docs/community/` or separate repo
**Examples:**

- "My R package workflow"
- "Multi-project juggling tips"
- "Custom aliases I use"

**Benefit:** Learn from other users

---

## 🎯 Recommended Implementation Order

### Phase 1: Quick Wins (Week 1)

1. ⚡ First-run welcome message → **30 min**
2. ⚡ Add "See also" to help → **20 min**
3. ⚡ Random tips in dashboard → **15 min**
4. ⚡ Quick reference card command → **25 min**
5. ⚡ Command usage examples → **60 min** (update all help functions)

**Total Time:** ~2.5 hours
**Impact:** High - Immediate UX improvement

---

### Phase 2: Interactive Help (Week 2)

1. 🔧 Interactive help browser → **90 min**
2. 🔧 Context-aware help → **60 min**
3. 🔧 Command aliases reference → **30 min**

**Total Time:** ~3 hours
**Impact:** High - Much better help discoverability

---

### Phase 3: Enhanced Onboarding (v4.9.0)

1. 🔧 Enhanced first-run wizard → **4-6 hours** (already specced!)
2. 🔧 `flow doctor --fix` improvements → **2-3 hours** (already specced!)
3. 🔧 Troubleshooter mode → **2 hours**

**Total Time:** ~8-11 hours
**Impact:** Very High - Complete onboarding experience

---

### Phase 4: Long-term (Future)

1. Video tutorials → **Ongoing**
2. Interactive tutorial mode → **6-8 hours**
3. AI-powered help → **4-6 hours**
4. Community examples → **Ongoing**

---

## 📋 Key Insights

### What's Working Well ✅

- **Homebrew installation** - Easiest path (v4.8.1 win!)
- **Comprehensive documentation** - Covers everything
- **Multiple learning paths** - Quick start, tutorials, references
- **Help command exists** - Good foundation

### What Needs Improvement ⚠️

- **Discoverability** - Users don't know features exist
- **First-run experience** - No guided onboarding
- **Interactive help** - Too much reading, not enough exploring
- **Examples** - Need more real-world use cases

### Critical Success Factor 🎯

**Progressive disclosure** - Show beginners the basics, reveal advanced features gradually. Don't overwhelm.

---

## 🤔 Open Questions

1. **First-run trigger:** Should it be on first `work` or first `flow` command?
   - **Recommendation:** First `work` (more natural workflow start)

2. **Interactive help dependency:** Require fzf or fallback to text?
   - **Recommendation:** Check for fzf, offer to install if missing

3. **Tip frequency:** Show tips every time or randomly?
   - **Recommendation:** 20% chance per `dash` invocation (not annoying)

4. **Video hosting:** YouTube or self-hosted?
   - **Recommendation:** YouTube (easier, better player, analytics)

5. **Tutorial mode:** Separate `flow tutorial` or integrate into `flow setup`?
   - **Recommendation:** Both! `setup` for first-run, `tutorial` for later learning

---

## 💬 Decision Needed

Pick **ONE** of these paths to start:

### Option A: Quick Wins Sprint (Recommended ⚡)

- Focus: Phase 1 quick wins
- Time: 1 session (~2-3 hours)
- Impact: Immediate UX improvement
- Effort: Low

### Option B: Interactive Help Focus

- Focus: Phase 2 interactive features
- Time: 1 session (~3 hours)
- Impact: Much better discoverability
- Effort: Medium

### Option C: v4.9.0 Full Onboarding

- Focus: Complete Phase 3 from existing spec
- Time: 2-3 days
- Impact: Transformative onboarding
- Effort: High (but already planned!)

---

## 📝 Next Steps

### If Option A (Quick Wins)

1. Implement first-run welcome message
2. Add "See also" to all help functions
3. Add random tips to dashboard
4. Create `flow ref` command
5. Add examples to help output

### If Option B (Interactive Help)

1. Build interactive help browser with fzf
2. Implement context-aware help
3. Create aliases reference command

### If Option C (v4.9.0 Onboarding)

1. Start with Phase 1 from SPEC-v4.9.0-installation-onboarding.md
2. Build install.sh script
3. Enhance `flow doctor --fix`
4. Create first-run wizard

---

## 🎊 Conclusion

**Key Finding:** Installation and core documentation are **EXCELLENT** (v4.8.1 success!).
**Main Gap:** **Discoverability and first-run experience** need attention.
**Best Next Step:** **Quick Wins Sprint** (Option A) for immediate impact, then v4.9.0 for complete solution.

The foundation is solid. We're adding **polish and discoverability**, not fixing broken things. 🚀

---

**Brainstorm Duration:** Analysis complete
**Files Referenced:**

- README.md
- docs/getting-started/installation.md
- docs/getting-started/quick-start.md
- docs/getting-started/faq.md
- docs/getting-started/00-welcome.md
- commands/flow.zsh
- SPEC-v4.9.0-installation-onboarding.md

**Status:** Ready for decision
