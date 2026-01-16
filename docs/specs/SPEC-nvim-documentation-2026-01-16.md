# Implementation Spec: Nvim/LazyVim Documentation & Integration

**Status:** Approved ✅
**Created:** 2026-01-16
**Target Release:** v5.11.0
**Effort Estimate:** 18-22 hours
**Priority:** High

---

## Executive Summary

Add comprehensive nvim/LazyVim documentation to flow-cli targeting complete beginners.

**Key Insight:** nvim is already the default editor (line 54 of `commands/work.zsh`) but completely undocumented, creating a major onboarding gap.

**User Requirements:**
- Target: Beginners (never used vim)
- Formats: Progressive tutorials + Interactive shell command + Quick reference cards
- Features: Core editing, file navigation, LSP (minimal R integration)
- Integration: work command, config edits, Git workflows
- R Integration: Minimal (skip dedicated R tutorial, users figure it out)
- Dispatcher: Not needed (current integration sufficient)

**Total Effort:** 18-22 hours (4 tutorials, honor system checkpoints, no dispatcher)

---

## Core Deliverables

### 1. Progressive Tutorial Series (4 tutorials, 8-10 hours)

**Tutorial 15: Nvim Quick Start** (~10 min)
- **Focus:** Survival + Basic Editing
- Absolute survival: ESC, i, :wq, :q!
- Basic insert mode editing
- Simple navigation and saving
- Integration with flow commands (work, mcp edit, dot edit)
- GIFs: opening-nvim.gif, basic-edit-save.gif, panic-exit.gif
- **File:** `docs/tutorials/15-nvim-quick-start.md`

**Tutorial 16: Vim Motions** (~15 min)
- **Focus:** Master efficient vim navigation
- Word motions (w/b/e, W/B/E)
- Paragraph/block navigation ({/}, gg/G)
- Search and jump (/, ?, f/F, t/T)
- Text objects (ciw, di", yap, vit)
- Exercises: Navigation challenge, refactoring practice
- GIFs: word-motions.gif, text-objects.gif, search-jump.gif
- **File:** `docs/tutorials/16-vim-motions.md`

**Tutorial 17: LazyVim Basic Features** (~15 min)
- **Focus:** Essential LazyVim plugins
- File navigation (Neo-tree, Telescope)
- Window management and splits
- Which-key helper
- Basic Git integration (gitsigns)
- Terminal integration
- Exercises: Find file with Telescope, split windows, open terminal
- GIFs: neo-tree.gif, telescope.gif, window-splits.gif, lazygit.gif
- **File:** `docs/tutorials/17-lazyvim-basics.md`

**Tutorial 18: LazyVim Feature Showcase** (~20-30 min)
- **Focus:** Comprehensive LazyVim tour
- LazyVim vs vanilla nvim (what's different, 58 plugins)
- LSP features (code intelligence, diagnostics, auto-completion)
- Plugin ecosystem (Lazy.nvim, Mason, Treesitter)
- Advanced Git (LazyGit UI, blame, hunks)
- Customization (keymaps.lua, options.lua, plugins/)
- Language extras system (lazyvim.json)
- Flow integration (work command, config editing)
- Exercises: Install language server, custom keybinding, enable extra
- GIFs: which-key-guide.gif, lsp-workflow.gif, mason-install.gif, customization.gif
- **File:** `docs/tutorials/18-lazyvim-showcase.md`

### 2. Quick Reference Card (2-3 hours)

**NVIM-QUICK-REFERENCE.md**
- 1-page printable landscape reference
- Sections: Survival, Navigation, Editing, Text Objects, Search, LazyVim, Windows, LSP, Terminal, Flow Integration
- Grouped by task, bold for common commands
- R.nvim section REMOVED (minimal R integration per user feedback)
- **File:** `docs/reference/NVIM-QUICK-REFERENCE.md`

### 3. Interactive Shell Command (6-8 hours)

**Command:** `flow nvim-tutorial`

**Features:**
- 5 progressive lessons (5-10 min each)
- **Honor system checkpoints** (trust user, ask "Did you do it? [y/n]")
- Real file editing practice
- Progress tracking (resume capability)
- ADHD-friendly pacing
- Integration with flow commands

**Architecture:**
```zsh
# File: commands/nvim-tutorial.zsh
flow-nvim-tutorial()
  → _nvim_lesson_1_survival()      # ESC, i, :wq, :q! + basic editing
  → _nvim_lesson_2_navigation()    # hjkl, w/b, gg/G
  → _nvim_lesson_3_motions()       # Text objects, search, jump
  → _nvim_lesson_4_lazyvim_basics()  # Telescope, Neo-tree, splits
  → _nvim_lesson_5_lazyvim_advanced() # LSP, Git, customization
  → _nvim_checkpoint_honor()       # "Did you complete this? [y/n]"
  → _nvim_show_progress()          # Track completion
```

**Validation:** Honor system - no strict file checking, trust user

**Usage:**
```bash
flow nvim-tutorial            # Start lesson 1
flow nvim-tutorial 3          # Jump to lesson 3
flow nvim-tutorial status     # Show progress
flow nvim-tutorial reset      # Start over
```

### 4. Documentation Updates (1-2 hours)

**Fix work.md**
- Line 136 incorrectly says VS Code is default
- Update editor table showing nvim is default
- Add nvim configuration section with tutorial links
- **File:** `docs/commands/work.md`

**Update installation.md**
- Add optional nvim installation section
- LazyVim setup instructions
- **File:** `docs/getting-started/installation.md`

**Update mkdocs.yml**
- Add 4 new tutorials (15-18) to Tutorials section
- Add 1 new reference (NVIM) to Reference section

### 5. GIF Demonstrations (4-6 hours)

**Location:** `docs/assets/gifs/nvim/`
**Total:** 14 GIFs

- Tutorial 15: 3 GIFs (opening, basic editing, panic exit)
- Tutorial 16: 3 GIFs (word motions, text objects, search/jump)
- Tutorial 17: 4 GIFs (neo-tree, telescope, splits, lazygit)
- Tutorial 18: 4 GIFs (which-key, LSP, mason, customization)

**Process:** VHS script → Generate → Optimize with Gifski → Embed in docs

---

## Critical Files

### Must Create (7 new files)
1. `docs/tutorials/15-nvim-quick-start.md` (Survival + Basic Editing)
2. `docs/tutorials/16-vim-motions.md` (Efficient Navigation)
3. `docs/tutorials/17-lazyvim-basics.md` (Essential Plugins)
4. `docs/tutorials/18-lazyvim-showcase.md` (Comprehensive Tour)
5. `docs/reference/NVIM-QUICK-REFERENCE.md`
6. `commands/nvim-tutorial.zsh`
7. `docs/assets/gifs/nvim/` (directory with 14 GIFs)

### Must Update (3 files)
1. `docs/commands/work.md` - Fix default editor documentation
2. `docs/getting-started/installation.md` - Add nvim/LazyVim installation
3. `mkdocs.yml` - Add navigation for tutorials and references

---

## Implementation Phases

### Phase 1: Tutorial 15 (Proof of Concept) - 3-4 hours
- Create first tutorial following template
- 3 GIFs for basic workflow
- Test with beginners
- Iterate based on feedback

### Phase 2: Complete Tutorial Series - 4-6 hours
- Tutorials 16 (Vim Motions), 17 (LazyVim Basics), 18 (LazyVim Showcase)
- 11 additional GIFs
- Cross-link tutorials with clear progression
- Exercises and honor system checkpoints

### Phase 3: Reference Card & Interactive Tutorial - 5-7 hours
- 1 quick reference card (general nvim, no R-specific)
- Interactive shell command with guided tour and checkpoints
- Progress tracking and validation system

### Phase 4: Documentation Updates & Deployment - 2-3 hours
- Fix work.md
- Update installation.md and mkdocs.yml
- Build and deploy docs
- Update CHANGELOG.md

---

## Verification Steps

### 1. Documentation Testing
```bash
# Code examples run without errors
cd docs/tutorials && grep -r '```bash' *.md | wc -l

# Links work (internal and external)
# Manual check or use linkchecker

# GIFs load correctly
ls -lh docs/assets/gifs/nvim/*.gif

# Tutorial progression makes sense
cat docs/tutorials/1{5,6,7,8}-*.md | head -20
```

### 2. Interactive Tutorial Testing
```bash
# Fresh user test
flow nvim-tutorial reset
flow nvim-tutorial

# Resume test
flow nvim-tutorial status

# Skip test
flow nvim-tutorial 3
```

### 3. User Acceptance Testing
- 3-5 beginners (never used vim)
- Follow Tutorial 15
- Report confusion, missing info, panic moments
- Integrate feedback (1 hour)

### 4. Integration Testing
```bash
# work command opens nvim correctly
work test-project

# Editor aliases work (if any)
e ~/.zshrc

# R dispatcher integration
cd ~/projects/r-packages/active/some-package
r test
# (nvim opens for failed tests)
```

---

## Key Exploration Findings

### Current State
- nvim is default editor (line 54 of commands/work.zsh) but undocumented
- 58 LazyVim plugins installed including R.nvim
- R LSP configured but languageserver R package missing
- Empty user configs (relies on LazyVim defaults)
- No editor configuration system exists in flow-cli
- `_flow_open_editor()` handles nvim with blocking mode (correct)

### Documentation Patterns
- ADHD-friendly: checkpoints, exercises, short paragraphs
- Tutorial template: 3-part structure (Foundation/Core/Advanced)
- Reference cards: 1-page, grouped by task
- GIF demonstrations required
- Numbered tutorials (01-14 currently exist, we add 15-18)

### LazyVim vs Vanilla Nvim
- LazyVim = opinionated distribution (like Ubuntu)
- 100+ sensible keybindings by default
- lazy.nvim plugin manager integrated
- Mason auto-configures LSP
- Sub-100ms startup with lazy loading
- "Extras" system for language packs (lazyvim.json)

---

## Success Criteria

1. ✅ Beginner with zero vim experience can complete Tutorial 15 in 10 minutes
2. ✅ All 4 tutorials follow ADHD-friendly conventions
3. ✅ Interactive tutorial tracks progress and allows resume
4. ✅ Reference card is 1-page printable
5. ✅ All code examples run without errors
6. ✅ GIFs demonstrate key workflows visually
7. ✅ Documentation deployed to https://Data-Wise.github.io/flow-cli/
8. ✅ work.md correctly documents nvim as default editor
9. ✅ R package developers can use nvim with r dispatcher
10. ✅ Users can find tutorials from Getting Started page

---

## Scope Finalized

**Included:**
- ✅ 4 tutorials total (15: Survival+Editing, 16: Motions, 17: LazyVim Basics, 18: Showcase)
- ✅ Interactive shell command with 5 lessons and honor system checkpoints
- ✅ Quick reference card (general nvim)
- ✅ 14 GIF demonstrations
- ✅ Documentation fixes (work.md, installation.md)

**Excluded (per user specifications):**
- ❌ R-specific tutorial - REMOVED (minimal R integration)
- ❌ R-NVIM-REFERENCE.md - REMOVED
- ❌ nvim dispatcher - REMOVED (not needed)

---

## Tutorial Structure Rationale

- **Tutorial 15:** Quick survival for absolute beginners (10 min)
- **Tutorial 16:** Vim motions for efficient editing (15 min)
- **Tutorial 17:** LazyVim essential plugins (15 min)
- **Tutorial 18:** Comprehensive LazyVim feature tour (30 min)
- **Total learning time:** ~70 minutes progressive path

---

## Next Steps

1. ✅ Spec created and saved
2. ✅ .STATUS updated
3. ⏳ Create feature branch worktree
4. ⏳ Start NEW session in worktree for implementation

---

**Created by:** Claude Code
**Approved by:** User
**Implementation:** To be done in feature branch worktree
