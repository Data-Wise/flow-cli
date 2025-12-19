# PROPOSAL: Interactive Cleanup via Checkboxes

**Generated:** 2025-12-19
**Context:** EXISTING-SYSTEM-SUMMARY.md - Make it interactive for cleanup decisions
**Location:** `/Users/dt/projects/dev-tools/zsh-configuration/`

---

## 📋 Overview

Transform EXISTING-SYSTEM-SUMMARY.md into an **interactive cleanup tool** by adding checkboxes to each documented item (aliases, functions, categories). You mark items for deletion, and Claude reads the checkboxes to process deletions safely.

**ADHD-friendly pattern:** Visual selection → Batch processing → Clean results

---

## 🎯 The Problem

**Current state:**
- EXISTING-SYSTEM-SUMMARY.md is read-only documentation
- No way to mark items for removal/deprecation
- Cleanup requires manual file editing across multiple locations

**Desired state:**
- Check boxes next to each alias/function/category
- Mark items for deletion in one place
- Claude processes all checked items in batch

---

## 💡 Proposed Solution

### Option A: Inline Checkboxes (Recommended)

**Format:**
```markdown
### Ultra-Fast (1-character)

From `ALIAS-REFERENCE-CARD.md`:

- [ ] `t` - rtest (50x/day usage)
- [ ] `c` - claude (30x/day usage)
- [ ] `q` - qp - Quarto preview (10x/day usage)

### Atomic Pairs

- [ ] `lt` - rload && rtest (load then test)
- [ ] `dt` - rdoc && rtest (doc then test)
```

**Workflow:**
1. You edit EXISTING-SYSTEM-SUMMARY.md and check boxes: `- [x]`
2. You say: "Process checked items for deletion"
3. Claude reads the file, detects all `- [x]` items
4. Claude shows you the deletion plan (files to modify, lines to remove)
5. You approve, Claude executes deletions
6. Claude unchecks processed items

**Pros:**
- ⭐ Simple - checkboxes are native markdown
- ⭐ Visual - easy to see what's marked
- ⭐ Readable by Claude - `Read` tool detects `[x]` vs `[ ]`
- ⭐ Version controlled - changes tracked in git
- ⭐ No new infrastructure needed

**Cons:**
- File becomes longer (adds checkboxes to every item)
- Mixing documentation with UI elements

---

### Option B: Separate Cleanup File

**Format:**
Create `CLEANUP-CHECKLIST.md`:

```markdown
# Cleanup Checklist

## Aliases to Remove

- [ ] `t` - Ultra-fast rtest alias
- [ ] `c` - Claude alias
- [ ] `lt` - Load + test atomic pair

## Functions to Remove

- [ ] `work` - Work session starter
- [ ] `finish` - Session finisher

## Categories to Remove

- [ ] `mgmt` - Management category (if not implementing proposal)
```

**Workflow:**
1. You check boxes in CLEANUP-CHECKLIST.md
2. Say: "Process cleanup checklist"
3. Claude reads, plans, executes deletions
4. Archive CLEANUP-CHECKLIST.md when done

**Pros:**
- ⭐ Keeps EXISTING-SYSTEM-SUMMARY.md clean
- ⭐ Focused purpose (cleanup only)
- ⭐ Can have multiple cleanup files for different phases

**Cons:**
- Requires maintaining separate file
- Need to reference EXISTING-SYSTEM-SUMMARY.md for context

---

### Option C: Comment-Based Marking

**Format:**
```markdown
### Ultra-Fast (1-character)

```zsh
t   # rtest (50x/day usage)  <!-- DELETE -->
c   # claude (30x/day usage)
q   # qp - Quarto preview (10x/day usage)  <!-- DELETE -->
```
```

**Workflow:**
1. Add `<!-- DELETE -->` comments to items
2. Claude searches for DELETE markers
3. Process deletions

**Pros:**
- Minimal formatting changes
- Clear intent

**Cons:**
- Less visual than checkboxes
- Harder to scan for marked items
- Comments in code blocks are awkward

---

## 🎨 Recommended Implementation: Option A (Inline Checkboxes)

### Step 1: Add Checkboxes to EXISTING-SYSTEM-SUMMARY.md

Transform sections like this:

**Before:**
```markdown
### R Package Development (30+ aliases)

Core workflow:
- `rload` / `ld` - Load package
- `rtest` / `ts` / `t` - Run tests
- `rdoc` / `dc` / `rd` - Generate docs
```

**After:**
```markdown
### R Package Development (30+ aliases)

Core workflow:
- [ ] `rload` / `ld` - Load package
- [ ] `rtest` / `ts` / `t` - Run tests
- [ ] `rdoc` / `dc` / `rd` - Generate docs
```

### Step 2: Cleanup Workflow

```bash
# 1. User marks items for deletion
vim docs/reference/EXISTING-SYSTEM-SUMMARY.md
# Change: - [ ] → - [x] for items to delete

# 2. User requests processing
"Process checked items for deletion"

# 3. Claude reads and plans
Read: docs/reference/EXISTING-SYSTEM-SUMMARY.md
Parse: All lines with - [x]
Plan: Show deletion locations (file:line)

# 4. User approves

# 5. Claude executes
Edit: ~/.config/zsh/functions/adhd-helpers.zsh (remove aliases)
Edit: docs/user/ALIAS-REFERENCE-CARD.md (remove documentation)
Edit: docs/reference/EXISTING-SYSTEM-SUMMARY.md (uncheck boxes)

# 6. Verify
Bash: source ~/.zshrc
Test: Verify removed aliases don't work
Test: Verify remaining aliases still work
```

### Step 3: Safety Features

**Before deletion, Claude will:**
1. **Show deletion plan** - All files and line numbers to be modified
2. **Check for dependencies** - Search for usage in scripts/docs
3. **Create backup** - `cp adhd-helpers.zsh adhd-helpers.zsh.backup`
4. **Atomic changes** - All or nothing (if one fails, revert all)
5. **Verification** - Test remaining aliases after deletion

**Example deletion plan:**
```
📋 Deletion Plan for 3 checked items:

✗ `lt` alias (load + test)
  - ~/.config/zsh/functions/adhd-helpers.zsh:245
  - docs/user/ALIAS-REFERENCE-CARD.md:67
  - docs/user/WORKFLOWS-QUICK-WINS.md:34

✗ `dt` alias (doc + test)
  - ~/.config/zsh/functions/adhd-helpers.zsh:246
  - docs/user/ALIAS-REFERENCE-CARD.md:68

✗ `qcommit` alias
  - ~/.config/zsh/functions/adhd-helpers.zsh:189
  - docs/user/ALIAS-REFERENCE-CARD.md:102
  - docs/user/WORKFLOWS-QUICK-WINS.md:78

⚠️  Dependencies found:
  - `dt` is mentioned in PROJECT-HUB.md:45 (documentation only)

Total files to modify: 4
Total lines to remove: 8

Proceed? (yes/no)
```

---

## 🔧 Implementation Checklist

### Phase 1: Convert Document (30 min)
- [ ] Read current EXISTING-SYSTEM-SUMMARY.md
- [ ] Add `- [ ]` checkboxes to all alias entries
- [ ] Add `- [ ]` checkboxes to all function entries
- [ ] Add `- [ ]` checkboxes to all category entries
- [ ] Add usage instructions at top of file
- [ ] Commit changes

### Phase 2: Create Processing Logic (1 hour)
- [ ] Create `process-cleanup-checklist` function (or Claude skill)
- [ ] Parse markdown for `- [x]` patterns
- [ ] Extract item names and types (alias/function/category)
- [ ] Search codebase for all occurrences
- [ ] Generate deletion plan
- [ ] Present to user for approval

### Phase 3: Safe Deletion (1 hour)
- [ ] Create backup files
- [ ] Remove from adhd-helpers.zsh
- [ ] Remove from documentation files
- [ ] Uncheck processed boxes in EXISTING-SYSTEM-SUMMARY.md
- [ ] Verify deletions
- [ ] Commit changes with detailed message

### Phase 4: Testing
- [ ] Test with 1-2 low-risk aliases first
- [ ] Verify `source ~/.zshrc` works
- [ ] Check removed aliases don't exist
- [ ] Check remaining aliases still work
- [ ] Verify docs are updated

---

## 📝 Example: Converting EXISTING-SYSTEM-SUMMARY.md

**Current format (Lines 100-108):**
```markdown
### Ultra-Fast (1-character)

From `ALIAS-REFERENCE-CARD.md`:

```zsh
t   # rtest (50x/day usage)
c   # claude (30x/day usage)
q   # qp - Quarto preview (10x/day usage)
```
```

**New interactive format:**
```markdown
### Ultra-Fast (1-character)

From `ALIAS-REFERENCE-CARD.md`:

- [ ] `t` - rtest (50x/day usage)
- [ ] `c` - claude (30x/day usage)
- [ ] `q` - qp - Quarto preview (10x/day usage)
```

---

## 🎯 User Experience

### Scenario 1: Remove unused aliases

```bash
# 1. User opens file
vim docs/reference/EXISTING-SYSTEM-SUMMARY.md

# 2. User checks items to remove
- [x] `lt` - rload && rtest (load then test)
- [x] `dt` - rdoc && rtest (doc then test)
- [ ] `t` - rtest (keep this one)

# 3. User asks Claude
"Process checked items for deletion"

# 4. Claude responds
"I found 2 items marked for deletion:
- `lt` alias (2 locations)
- `dt` alias (2 locations)

Creating deletion plan..."

[Shows plan]

"Proceed with deletion? (yes/no)"

# 5. User approves
"yes"

# 6. Claude executes and reports
"✅ Deleted 2 aliases from adhd-helpers.zsh
✅ Removed 2 entries from ALIAS-REFERENCE-CARD.md
✅ Unchecked processed items in EXISTING-SYSTEM-SUMMARY.md
✅ Created backup: adhd-helpers.zsh.backup

Please reload your shell: source ~/.zshrc"
```

### Scenario 2: Bulk category cleanup

```bash
# Remove entire category of old aliases
"Process all checked items in 'Legacy Git Aliases' section"

# Claude detects 15 checked items, plans batch deletion
# User approves
# Claude removes all 15 in one commit
```

---

## 🚨 Safety Guardrails

1. **Always backup before deletion**
   - `cp adhd-helpers.zsh adhd-helpers.zsh.backup-$(date +%Y%m%d-%H%M%S)`

2. **Dependency check**
   - Grep for alias usage in all scripts
   - Warn if found in active code (not just docs)

3. **Atomic operations**
   - If any deletion fails, revert all changes
   - Use git to track changes

4. **Verification step**
   - After deletion, source ~/.zshrc
   - Test that removed aliases are gone
   - Test that remaining aliases work

5. **Commit message template**
   ```
   refactor: remove unused aliases (interactive cleanup)

   Removed via EXISTING-SYSTEM-SUMMARY.md checkbox selection:
   - lt (load + test)
   - dt (doc + test)

   Files modified:
   - ~/.config/zsh/functions/adhd-helpers.zsh
   - docs/user/ALIAS-REFERENCE-CARD.md
   ```

---

## 🔮 Future Enhancements

### Idea 1: Usage Analytics Integration
- Track which aliases are actually used
- Auto-suggest items for removal (0 usage in 30 days)
- Pre-check low-usage aliases

### Idea 2: Undo Feature
- Keep deletion history in `.cleanup-history.json`
- Allow reverting last cleanup batch
- One-command restore: `cleanup-undo`

### Idea 3: Export/Import Cleanup Plans
- Save checkbox states to separate file
- Share cleanup plans across machines
- Version control cleanup decisions

---

## 📚 Documentation Updates

### New section in EXISTING-SYSTEM-SUMMARY.md (top of file):

```markdown
# Existing System Summary - ZSH Workflow Manager

**Generated:** 2025-12-19
**Purpose:** Comprehensive overview + interactive cleanup tool
**Location:** `/Users/dt/projects/dev-tools/zsh-configuration/`

---

## 🧹 How to Use This as a Cleanup Tool

This document doubles as an **interactive cleanup checklist**:

1. **Mark items for deletion:** Change `- [ ]` to `- [x]` for any alias/function/category you want to remove
2. **Ask Claude to process:** Say "Process checked items for deletion"
3. **Review the plan:** Claude will show all files and lines to be modified
4. **Approve:** Claude executes the deletions safely
5. **Reload shell:** `source ~/.zshrc` to apply changes

**Safety:** Claude creates backups before deletion and verifies all changes.

---
```

---

## ✅ Questions Answered

**Q: Can Claude read checked checkboxes?**
**A:** Yes! The `Read` tool can detect the difference between:
- `- [ ]` (unchecked)
- `- [x]` (checked)

**Q: What format should I use?**
**A:** Markdown checkboxes are the recommended format:
```markdown
- [ ] Item to potentially delete
- [x] Item marked for deletion
```

**Q: How does Claude process them?**
**A:**
1. Read file with `Read` tool
2. Parse lines matching `- [x]` pattern
3. Extract item name/description
4. Search codebase for occurrences
5. Create deletion plan
6. Execute after approval

**Q: Is this safe?**
**A:** Yes, with multiple safety layers:
- Backups created before changes
- Dependency checking
- User approval required
- Atomic operations (all or nothing)
- Verification after deletion

---

## 📋 Next Steps

**To implement this proposal:**

1. **Start small:** Convert one section of EXISTING-SYSTEM-SUMMARY.md to checkboxes
2. **Test workflow:** Mark 1-2 low-risk items, ask Claude to process
3. **Verify safety:** Check that backups are created, deletions are correct
4. **Full conversion:** Add checkboxes to all sections
5. **Use regularly:** Mark items during reviews, batch process monthly

**Estimated effort:**
- Document conversion: 30 minutes
- First test run: 15 minutes
- Full adoption: Ongoing (monthly cleanup sessions)

---

**Last Updated:** 2025-12-19
**Status:** 🟡 Proposal - Awaiting Approval
**Author:** Claude Sonnet 4.5
**Recommendation:** Start with Option A (inline checkboxes) for simplicity
