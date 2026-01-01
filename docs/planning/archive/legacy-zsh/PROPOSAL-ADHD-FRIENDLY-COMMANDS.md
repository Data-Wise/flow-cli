# ADHD-Friendly Command Names Proposal

**Date:** 2025-12-16
**Issue:** New two-letter commands (`re`, `rt`, `fs`, etc.) are not ADHD-friendly
**Goal:** Replace with semantic, memorable, workflow-oriented commands

---

## 🧠 The Problem with Two-Letter Commands

### Current New Commands (Problematic)

| Command      | What It Does       | Problem                     |
| ------------ | ------------------ | --------------------------- |
| `re`         | Fuzzy find R files | What does `re` mean?        |
| `rt`         | Run test           | Conflicts with mental model |
| `rv`         | View vignette      | Not discoverable            |
| `fs`         | Find .STATUS       | Cryptic                     |
| `fh`         | Find PROJECT-HUB   | Not memorable               |
| `fp`         | Find project       | Generic                     |
| `fr`         | Find R package     | Unclear                     |
| `gb`         | Git branch         | Could be anything           |
| `gdf`        | Git diff           | Not semantic                |
| `gshow`      | Git log            | Conflicts with `glog`       |
| `ga`         | Git add            | Common but unclear          |
| `gundostage` | Unstage            | Too long!                   |

### Why They're Not ADHD-Friendly

1. **Not memorable** - Have to memorize arbitrary abbreviations
2. **High cognitive load** - "What does `fs` stand for again?"
3. **Not discoverable** - Can't guess from name
4. **Muscle memory conflicts** - Might type them by mistake
5. **Inconsistent patterns** - Some start with `f`, some with `g`, some with `r`

---

## ✅ Your Existing ADHD-Friendly Patterns

### What Works in Your Current Setup

| Command           | Pattern             | Why It Works                   |
| ----------------- | ------------------- | ------------------------------ |
| `work`            | Action verb         | Clear intent, semantic         |
| `focus`           | Action verb         | Immediately understandable     |
| `win`             | Action verb         | Short but meaningful           |
| `js` (just-start) | Phrase abbreviation | Full form is memorable         |
| `wn` (what-next)  | Phrase abbreviation | Context gives meaning          |
| `status`          | Noun                | Direct, no translation needed  |
| `hub`             | Noun                | Short, clear                   |
| `allstatus`       | Descriptive         | Tells you exactly what it does |

### Key Patterns That Work

1. ✅ **Action verbs** - work, focus, win, finish
2. ✅ **Semantic nouns** - status, hub, projects
3. ✅ **Phrase abbreviations with context** - wn (what-next), js (just-start)
4. ✅ **Context-aware commands** - work detects project type
5. ✅ **Descriptive compounds** - allstatus, rpkginfo, dashupdate

---

## 💡 Proposed Solution: Context-Aware `pick` Command

### Core Concept: One Smart Command

**`pick`** - Context-aware picker that adapts to where you are

```bash
# In R package directory
$ pick              # Shows: R files, tests, vignettes, .STATUS
                    # "What do you want to pick?"

# In any project
$ pick              # Shows: All pickable items (files, status, etc.)

# With subcommands for explicit control
$ pick file         # Force file picker
$ pick test         # Force test picker
$ pick status       # Force .STATUS picker
```

### Why This Works

- ✅ **One command to remember** - Just "pick"
- ✅ **Semantic** - You're picking something
- ✅ **Context-aware** - Smart based on location
- ✅ **Discoverable** - Natural language
- ✅ **Extensible** - Can add more pick types

---

## 🎯 Proposed Command Renaming

### Tier 1: High-Level Workflow Commands (Recommended)

| Old          | New              | Category   | Why Better        |
| ------------ | ---------------- | ---------- | ----------------- |
| `re`         | `pick file`      | R Dev      | Semantic, clear   |
| `rt`         | `pick test`      | R Dev      | Clear intent      |
| `rv`         | `pick vignette`  | R Dev      | Self-documenting  |
| `fs`         | `pick status`    | Project    | Memorable         |
| `fh`         | `pick hub`       | Project    | Clear             |
| `fp`         | `pick project`   | Navigation | Obvious           |
| `fr`         | `pick package`   | Navigation | R-specific, clear |
| `gb`         | `switch branch`  | Git        | Action verb       |
| `gdf`        | `review changes` | Git        | Semantic          |
| `gshow`      | `browse commits` | Git        | Action-oriented   |
| `ga`         | `stage`          | Git        | Short, semantic   |
| `gundostage` | `unstage`        | Git        | Shorter, clear    |

### Tier 2: Alternative - Prefix Pattern

Keep a consistent `pick-` prefix:

| Old  | New             | Why                  |
| ---- | --------------- | -------------------- |
| `re` | `pick-file`     | Consistent pattern   |
| `rt` | `pick-test`     | Easy to autocomplete |
| `rv` | `pick-vignette` | Discoverable         |
| `fs` | `pick-status`   | Clear namespace      |
| `gb` | `pick-branch`   | Git operations clear |

### Tier 3: Hybrid Approach (Recommended ⭐)

**Smart `pick` + semantic git commands:**

```bash
# Context-aware picker
pick                # Smart: detects context
pick file           # Explicit: R files
pick test           # Explicit: tests
pick status         # Explicit: .STATUS
pick project        # Explicit: projects
pick package        # Explicit: R packages

# Semantic git commands (separate namespace)
switch              # Git branch switching
stage               # Git interactive staging
unstage             # Git interactive unstaging
review              # Git review changes
browse              # Git browse commits
```

---

## 🏗️ Implementation Proposal

### Phase 1: Core `pick` Command (Context-Aware)

```bash
pick() {
    # Detect context
    local context=""

    # Check if in R package
    if [[ -f "DESCRIPTION" ]] && grep -q "^Package:" DESCRIPTION 2>/dev/null; then
        context="rpkg"
    # Check if in git repo
    elif git rev-parse --git-dir > /dev/null 2>&1; then
        context="git"
    # Check if in projects
    elif [[ "$PWD" == "$HOME/projects"* ]]; then
        context="projects"
    fi

    # Show context-appropriate picker
    case "$context" in
        rpkg)
            # R package context: pick R file, test, vignette, or .STATUS
            echo "📦 R Package Context - What to pick?"
            echo "1) R file"
            echo "2) Test file"
            echo "3) Vignette"
            echo "4) .STATUS"
            read -r choice
            case "$choice" in
                1) pick-file ;;
                2) pick-test ;;
                3) pick-vignette ;;
                4) pick-status ;;
            esac
            ;;
        git)
            # Git context: pick branch, view diff, etc.
            echo "🔀 Git Repo - What to pick?"
            echo "1) Switch branch"
            echo "2) Review changes"
            echo "3) Browse commits"
            read -r choice
            # ... handle choices
            ;;
        projects)
            # Projects context: pick project or package
            echo "📁 Projects - What to pick?"
            echo "1) Project"
            echo "2) R Package"
            echo "3) .STATUS file"
            read -r choice
            # ... handle choices
            ;;
        *)
            # Default: show all options
            echo "🔍 What to pick?"
            echo "1) Project"
            echo "2) R Package"
            echo "3) .STATUS file"
            read -r choice
            # ... handle choices
            ;;
    esac
}
```

### Phase 2: Subcommands

```bash
pick() {
    local subcommand="${1:-}"

    case "$subcommand" in
        file|files)      pick-file ;;
        test|tests)      pick-test ;;
        vignette|vig)    pick-vignette ;;
        status)          pick-status ;;
        hub)             pick-hub ;;
        project|proj)    pick-project ;;
        package|pkg)     pick-package ;;
        "")              pick-interactive ;;  # No args = interactive
        *)
            echo "❌ Unknown: pick $subcommand"
            echo "Usage: pick [file|test|vignette|status|hub|project|package]"
            return 1
            ;;
    esac
}
```

### Phase 3: Semantic Git Commands

```bash
# Git commands (separate from pick)
switch() {
    # Was: gb
    # Fuzzy branch switcher
}

stage() {
    # Was: ga
    # Interactive git add
}

unstage() {
    # Was: gundostage
    # Interactive git reset
}

review() {
    # Was: gdf
    # Interactive diff viewer
}

browse() {
    # Was: gshow
    # Git log browser
}
```

---

## 📊 Comparison: Old vs New

### Discoverability Test

**Question:** "I want to edit an R file but don't know which one"

| Approach       | Command     | Thought Process                            |
| -------------- | ----------- | ------------------------------------------ |
| Old (cryptic)  | `re`        | "What's `re` again? Let me check docs..."  |
| New (semantic) | `pick file` | "I want to pick a file" ✅                 |
| New (smart)    | `pick`      | "Let me pick something" → shows options ✅ |

### Memory Test (After 1 Week Away)

| Command     | Remember? | Why                        |
| ----------- | --------- | -------------------------- |
| `re`        | ❌ 30%    | "Was it `re` or `rf`?"     |
| `rt`        | ❌ 40%    | "Is this `rtest` or `rt`?" |
| `fs`        | ❌ 20%    | "What's `fs` again?"       |
| `pick file` | ✅ 95%    | Natural language           |
| `pick test` | ✅ 95%    | Self-documenting           |
| `switch`    | ✅ 90%    | Action verb, clear         |
| `stage`     | ✅ 85%    | Git term, semantic         |

---

## 🎯 Final Recommendation (Hybrid Approach)

### Core Commands

```bash
pick                    # Context-aware smart picker
pick file               # Explicit: pick R file
pick test               # Explicit: pick test
pick vignette           # Explicit: pick vignette
pick status             # Explicit: pick .STATUS
pick hub                # Explicit: pick PROJECT-HUB
pick project            # Explicit: pick project
pick package            # Explicit: pick R package
```

### Git Commands (Separate Namespace)

```bash
switch                  # Switch branch (was: gb)
stage                   # Interactive staging (was: ga)
unstage                 # Interactive unstaging (was: gundostage)
review                  # Review changes (was: gdf)
browse                  # Browse commits (was: gshow)
```

### Why This Works

1. ✅ **One mental model** - "pick" for selection, verbs for git actions
2. ✅ **Discoverable** - `pick <tab>` shows all options
3. ✅ **Context-aware** - `pick` alone is smart
4. ✅ **Memorable** - Natural language
5. ✅ **Consistent** - Clear namespacing (pick vs git verbs)
6. ✅ **ADHD-friendly** - Low cognitive load

---

## 🔄 Migration Path

### Step 1: Add New Commands (Aliases for Now)

```bash
# In .zshrc or fzf-helpers.zsh
alias 'pick file'='re'
alias 'pick test'='rt'
alias 'pick status'='fs'
alias switch='gb'
alias stage='ga'
alias unstage='gundostage'
alias review='gdf'
alias browse='gshow'
```

### Step 2: Try for 1 Week

- Use new names
- See if they feel natural
- Gather feedback

### Step 3: Implement Smart `pick`

- Build context-aware picker
- Add tab completion
- Make it the primary interface

### Step 4: Deprecate Old Names

- Add warnings to old commands
- Update documentation
- Remove after transition period

---

## 💡 Alternative Ideas

### Option A: Single-Word Commands

```bash
choose              # Instead of pick (synonym)
find                # Conflicts with fd, not recommended
select              # Longer, but clear
```

### Option B: R-Prefixed Pattern

```bash
redit               # R edit (instead of re)
rtest-pick          # R test pick
rstatus             # R status
```

**Issue:** Only works for R commands, not git/projects

### Option C: Natural Phrases

```bash
edit-r-file         # Very explicit
run-test            # Very explicit
update-status       # Very explicit
```

**Issue:** Too long for frequent use

---

## 🎯 Recommended Next Steps

1. **Implement hybrid approach** (pick + git verbs)
2. **Add tab completion** for pick subcommands
3. **Update help system** with new commands
4. **Create aliases** for migration period
5. **Test for 1 week** with real workflow
6. **Gather usage data** - which commands used most?
7. **Refine based on experience**

---

## 📖 Integration with Existing Workflows

### Morning Workflow

```bash
# OLD (too many commands to remember)
wn                      # What next
fs                      # Edit .STATUS (cryptic!)
re                      # Edit R file (what's re?)

# NEW (semantic, clear)
wn                      # What next (keep - established)
pick status             # Clear intent
pick file               # Clear intent
```

### R Development Workflow

```bash
# OLD
fr                      # Jump to package (?)
re                      # Edit file (?)
rt                      # Run test (?)

# NEW
pick package            # Clear
pick file               # Clear
pick test               # Clear
```

### Git Workflow

```bash
# OLD
gb                      # Switch branch (?)
ga                      # Stage (common but not semantic)
gdf                     # Review (?)

# NEW
switch                  # Clear action verb
stage                   # Git term, semantic
review                  # Clear intent
```

---

## ✅ Benefits Summary

### ADHD-Friendly Improvements

1. **Lower cognitive load** - No translation needed
2. **Better memory retention** - Semantic meaning
3. **Discoverability** - Can guess commands
4. **Reduced errors** - Less confusion
5. **Context awareness** - `pick` adapts to location
6. **Natural language** - Speaks like you think

### Technical Benefits

1. **Tab completion friendly** - `pick <tab>` shows options
2. **Extensible** - Easy to add new pick types
3. **Consistent namespacing** - pick vs git verbs
4. **Self-documenting** - Commands explain themselves
5. **Backwards compatible** - Can keep old as aliases during migration

---

**Status:** 📋 Proposal Draft
**Action Required:** Review and approve approach
**Implementation Time:** 2-3 hours for full migration
**Test Period:** 1 week recommended

**Preferred Approach:** ⭐ Hybrid (smart `pick` + semantic git verbs)
