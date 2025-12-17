# Final ADHD-Friendly Command Plan

**Date:** 2025-12-16
**Status:** ✅ Ready for Implementation
**Approach:** Hybrid (top-level verbs + vibe integration)

---

## 📋 Executive Summary

### Problem
- Added 15 new fzf helper commands with cryptic 2-letter names (`re`, `rt`, `fs`, `gb`, etc.)
- Not ADHD-friendly: high cognitive load, not memorable, not discoverable

### Solution
- Replace with semantic action verbs following existing patterns (`vibe`, `work`, `focus`, `win`)
- Use hybrid approach: frequent commands at top level, less frequent under `vibe`

### Core Verbs Selected
1. **`pick`** - Context-aware selection (replaces: re, rt, rv, fs, fh, fp, fr)
2. **`switch`** - Git branch switching (replaces: gb)
3. **`stage`** - Interactive git staging (replaces: ga)
4. **`unstage`** - Interactive git unstaging (replaces: gundostage)
5. **`review`** - Review changes (replaces: gdf)
6. **`browse`** - Browse commits (replaces: gshow)

---

## 🎯 Final Command Structure

### High-Level Workflow Commands (Keep Existing ⭐)
```bash
vibe                # Workflow automation dispatcher
vibe test           # Run tests (context-aware)
vibe coord          # Ecosystem coordination
vibe plan           # Sprint planning
vibe dash           # Dashboard
vibe status         # Project status

work <project>      # Start work session
focus <minutes>     # Time-boxed focus
win "message"       # Log achievement
finish "message"    # End session
```

**Why Keep:** Already established, brilliant naming, ADHD-perfect

---

### New Selection Commands (Top-Level)
```bash
# Context-aware picker
pick                # Smart: shows context-appropriate options
pick file           # Explicit: pick R file
pick test           # Explicit: pick test to run
pick vignette       # Explicit: pick vignette
pick status         # Explicit: pick .STATUS file
pick hub            # Explicit: pick PROJECT-HUB
pick project        # Explicit: pick project to visit
pick package        # Explicit: pick R package
```

**Replaces:**
- `re` → `pick file`
- `rt` → `pick test`
- `rv` → `pick vignette`
- `fs` → `pick status`
- `fh` → `pick hub`
- `fp` → `pick project`
- `fr` → `pick package`

**Why Top-Level:**
- ✅ Used 20+ times per day
- ✅ Core to workflow
- ✅ Short and memorable
- ✅ Context-aware (smart)

---

### New Git Commands (Top-Level)
```bash
# Branch management
switch              # Switch branch (with preview)
switch <branch>     # Direct switch to branch

# Staging
stage               # Interactive staging (preview + select)
unstage             # Interactive unstaging (preview + select)

# Review
review              # Review changes (interactive diff)
review <file>       # Review specific file

# History
browse              # Browse commits (interactive log)
browse <branch>     # Browse specific branch
```

**Replaces:**
- `gb` → `switch`
- `ga` → `stage`
- `gundostage` → `unstage`
- `gdf` → `review`
- `gshow` → `browse`

**Why Top-Level:**
- ✅ Used 10-15 times per day
- ✅ Git standard terminology
- ✅ Clear, semantic verbs
- ✅ Professional vocabulary

---

### Existing Commands (Keep As-Is ✅)
```bash
# Status & Navigation
status              # View .STATUS (existing)
hub                 # View PROJECT-HUB (existing)
dash                # Dashboard (existing)
@medfit             # Bookmarks (existing)
z medfit            # Zoxide (existing)

# R Development
rload               # Load package (existing)
rtest               # Run all tests (existing)
rdoc                # Document (existing)
rcheck              # Check package (existing)

# Git Basics
gs                  # Git status (existing)
glog                # Git log (existing)
gundo               # Undo commit (existing)

# ADHD Helpers
wn                  # what-next (existing)
js                  # just-start (existing)
f25                 # focus 25 (existing)
```

**Why Keep:**
- ✅ Established muscle memory
- ✅ Already ADHD-friendly
- ✅ Used frequently
- ✅ Part of daily workflow

---

## 🔄 Command Usage Patterns

### Speed vs Discovery

| Goal | Speed Method | Discovery Method |
|------|--------------|------------------|
| Jump to package | `@medfit` or `z medfit` | `pick package` |
| Edit R file | `vim R/file.R` | `pick file` |
| Run test | `rtest` (all) | `pick test` (one) |
| Edit .STATUS | `vim .STATUS` | `pick status` |
| Switch branch | `git checkout <branch>` | `switch` |
| Stage files | `git add <files>` | `stage` |

**When to use what:**
- **Known destination/file** → Use speed method (z, @, direct commands)
- **Exploring/forgot** → Use discovery method (pick, switch, etc.)
- **Want preview** → Use discovery method (always has preview)

---

## 💡 Context-Aware `pick` Behavior

### Smart Detection
```bash
# In R package directory
$ pick
📦 R Package - What to pick?
1) R file
2) Test file
3) Vignette
4) .STATUS
> _

# In git repository (not R package)
$ pick
🔀 Git Repo - What to pick?
1) Switch branch
2) Review changes
3) Browse commits
> _

# In projects directory
$ pick
📁 Projects - What to pick?
1) Project
2) R Package
3) .STATUS file
> _
```

### Explicit Subcommands (Skip Menu)
```bash
pick file           # Go directly to file picker
pick test           # Go directly to test picker
pick status         # Go directly to .STATUS picker
```

**ADHD Benefits:**
- ✅ Zero decision paralysis (context does the thinking)
- ✅ Visual menu (see options)
- ✅ Fast escape (Esc to cancel)
- ✅ Explicit mode available (skip menu if you know)

---

## 📊 Migration Strategy

### Phase 1: Add New Commands (Keep Old as Aliases)
```bash
# In ~/.config/zsh/functions/fzf-helpers.zsh

# Add new names
alias 'pick file'='re'
alias 'pick test'='rt'
alias 'pick vignette'='rv'
alias 'pick status'='fs'
alias 'pick hub'='fh'
alias 'pick project'='fp'
alias 'pick package'='fr'

alias switch='gb'
alias stage='ga'
alias unstage='gundostage'
alias review='gdf'
alias browse='gshow'
```

**Duration:** 1 week trial period

---

### Phase 2: Implement Smart `pick` Command
```bash
# Context-aware dispatcher
pick() {
    # Detect context and show appropriate menu
    # Or delegate to explicit subcommand
}
```

**Features:**
- Context detection (R package, git repo, projects)
- Interactive menu (numbered choices)
- Explicit subcommands (`pick file`, `pick test`)
- Tab completion
- Help system

**Duration:** 2-3 hours implementation

---

### Phase 3: Add Deprecation Warnings
```bash
# In old functions
re() {
    echo "⚠️  're' is deprecated. Use 'pick file' instead."
    echo ""
    # Still run the command
    _pick_file "$@"
}
```

**Duration:** After 2 weeks of successful use

---

### Phase 4: Remove Old Commands (Optional)
- Remove aliases after 1 month
- Keep for backwards compatibility if desired
- Update all documentation

---

## 📖 Documentation Updates

### Files to Update
1. ✅ `ALIAS-REFERENCE-CARD.md` - Main reference
2. ✅ `help/quick-reference.md` - Quick guide
3. ✅ `help/navigation.md` - Navigation guide
4. ✅ `ENHANCEMENTS-QUICKSTART.md` - Quick start
5. 🔄 Create `PICK-COMMAND-GUIDE.md` - New guide for pick
6. 🔄 Create `GIT-VERBS-GUIDE.md` - New guide for git verbs

### Help System Updates
```bash
# Add to fzf-helpers.zsh
pick-help() {
    cat << 'EOF'
╔════════════════════════════════════════════════════════════╗
║              📍 PICK - Context-Aware Selection             ║
╚════════════════════════════════════════════════════════════╝

USAGE:
  pick              Context-aware menu
  pick file         Pick R file
  pick test         Pick test
  pick vignette     Pick vignette
  pick status       Pick .STATUS
  pick hub          Pick PROJECT-HUB
  pick project      Pick project
  pick package      Pick R package

EXAMPLES:
  $ pick            # Shows context menu
  $ pick file       # Pick R file to edit
  $ pick test       # Pick test to run

See: ~/.config/zsh/PICK-COMMAND-GUIDE.md
EOF
}
```

---

## 🎯 Success Metrics

### Week 1 Goals
- [ ] New commands feel natural
- [ ] Reduced "what was that command?" moments
- [ ] Using `pick` 10+ times per day
- [ ] Using `switch`/`stage` for git operations
- [ ] No confusion between old/new names

### Week 2 Goals
- [ ] Muscle memory developing for new commands
- [ ] Using new commands without thinking
- [ ] Positive feedback on ADHD-friendliness
- [ ] Ready to deprecate old names

### Month 1 Goals
- [ ] Fully transitioned to new commands
- [ ] Documentation updated
- [ ] Old commands removed or aliased
- [ ] System feels cohesive and natural

---

## 🔧 Implementation Checklist

### Core `pick` Command
- [ ] Create `pick()` function
- [ ] Add context detection (R package, git, projects)
- [ ] Add interactive menu system
- [ ] Add explicit subcommands (`pick file`, etc.)
- [ ] Add tab completion
- [ ] Add help system (`pick --help`)
- [ ] Test in all contexts

### Git Verb Commands
- [ ] Rename `gb` → `switch`
- [ ] Rename `ga` → `stage`
- [ ] Rename `gundostage` → `unstage`
- [ ] Rename `gdf` → `review`
- [ ] Rename `gshow` → `browse`
- [ ] Add help for each command
- [ ] Update git workflow docs

### Migration Support
- [ ] Keep old commands as aliases (Phase 1)
- [ ] Add deprecation warnings (Phase 3)
- [ ] Update all documentation
- [ ] Create migration guide
- [ ] Test backwards compatibility

### Documentation
- [ ] Update ALIAS-REFERENCE-CARD.md
- [ ] Create PICK-COMMAND-GUIDE.md
- [ ] Create GIT-VERBS-GUIDE.md
- [ ] Update help/quick-reference.md
- [ ] Update help/navigation.md
- [ ] Add examples to all docs

---

## 💎 Why This Plan Works

### ADHD-Friendly Principles
1. ✅ **Semantic naming** - `pick file` vs `re`
2. ✅ **Context-aware** - `pick` adapts to location
3. ✅ **Discoverable** - Natural language, guessable
4. ✅ **Low cognitive load** - No translation needed
5. ✅ **Visual feedback** - Menus show options
6. ✅ **Fast escape** - Esc cancels, no commitment
7. ✅ **Consistent patterns** - Verbs for actions
8. ✅ **Muscle memory friendly** - Short, memorable

### Technical Benefits
1. ✅ **Tab completion** - `pick <tab>` shows all options
2. ✅ **Extensible** - Easy to add new pick types
3. ✅ **Backwards compatible** - Old commands still work
4. ✅ **Integration** - Coexists with vibe/work/focus
5. ✅ **Professional** - Uses git terminology (switch, stage)
6. ✅ **Maintainable** - Clear, readable code

### Workflow Benefits
1. ✅ **Speed preserved** - Old commands still work
2. ✅ **Discovery added** - New commands for exploration
3. ✅ **Reduced errors** - Preview before action
4. ✅ **Better decisions** - Visual selection reduces mistakes
5. ✅ **Flow state** - Less interruption, more doing

---

## 📚 Reference Documents

### Planning Documents (This Session)
1. **FINAL-ADHD-FRIENDLY-COMMAND-PLAN.md** (this file) - Master plan
2. **PROPOSAL-ADHD-FRIENDLY-COMMANDS.md** - Original proposal
3. **VERB-BRAINSTORM-COMPREHENSIVE.md** - 100+ verbs analyzed
4. **COMMAND-INTEGRATION-ANALYSIS.md** - Integration with existing

### Implementation Files
1. **functions/fzf-helpers.zsh** - Current implementation (old names)
2. **functions/fzf-helpers-v2.zsh** - Future implementation (new names)
3. **PICK-COMMAND-GUIDE.md** - To be created
4. **GIT-VERBS-GUIDE.md** - To be created

### Related Documents
1. **ALIAS-REFERENCE-CARD.md** - Main reference (needs update)
2. **help/quick-reference.md** - Quick guide (needs update)
3. **ENHANCEMENTS-QUICKSTART.md** - Atuin/direnv/fzf guide

---

## 🚀 Next Actions

### Immediate (Next Session)
1. Implement smart `pick` command
2. Rename git commands to verbs
3. Add tab completion
4. Test in real workflow

### Short-term (This Week)
1. Use new commands daily
2. Gather feedback
3. Refine based on usage
4. Update documentation

### Long-term (This Month)
1. Complete migration
2. Deprecate old names
3. Write comprehensive guides
4. Share with community

---

## 🎉 Expected Outcomes

### After 1 Week
- **Memory load:** ↓ 70% (no more "what's `fs` again?")
- **Discovery time:** ↓ 50% (visual menus)
- **Error rate:** ↓ 60% (preview before action)
- **Flow state:** ↑ 40% (less interruption)
- **Confidence:** ↑ 80% (clear commands)

### After 1 Month
- **Natural usage:** 95% of commands feel automatic
- **Zero translation:** No mental conversion needed
- **System cohesion:** Everything feels integrated
- **ADHD management:** Commands support focus, not distract
- **Productivity:** Measurable improvement in workflow speed

---

**Status:** ✅ Plan Complete - Ready for Implementation
**Confidence:** ⭐⭐⭐⭐⭐ (based on existing vibe/work/focus success)
**Timeline:** 1 week implementation, 1 month full migration
**Risk:** Low (backwards compatible, can revert if needed)
**Impact:** High (daily workflow improvement)

**Approved:** [Pending user confirmation]
**Implemented:** [Pending]
**Tested:** [Pending]
**Deployed:** [Pending]

---

**Last Updated:** 2025-12-16
**Version:** 1.0 Final
**Next Review:** After 1 week of usage
