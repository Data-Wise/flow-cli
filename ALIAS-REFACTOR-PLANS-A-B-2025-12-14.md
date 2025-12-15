# Alias Refactoring: Two Plans
**Date:** 2025-12-14
**Key Insight:** Short aliases (1-2 letters) are HARD to remember with ADHD
**Solution:** Mnemonic, meaningful aliases with clear patterns

---

## 🎯 Core Problem

**Current state:**
- 167 aliases, many are 1-2 letters (c, d, q, t, bd, dc, ck, etc.)
- **User feedback:** "I do not like one or two letters; it's hard for me to remember"
- Need: Consolidated aliases with **mnemonics** (memory aids)

**ADHD-Friendly Principles:**
1. ✅ **Meaningful names** over brevity
2. ✅ **Consistent patterns** over variety
3. ✅ **Tab-completable** namespaces
4. ✅ **Self-documenting** aliases

---

## 📊 Plan A: Verb-Noun Pattern (Recommended ⭐)

**Philosophy:** Use action-object pairs that read like natural commands

### Pattern Design
```
[verb]-[object]
test-r    → Test R package
doc-r     → Document R package
build-r   → Build R package
check-r   → Check R package
load-r    → Load R package

preview-q → Preview Quarto
render-q  → Render Quarto
check-q   → Check Quarto

claude-continue → Continue Claude conversation
claude-plan     → Claude in plan mode
claude-yolo     → Claude bypass permissions
```

### Full Alias List (Plan A)

#### R Package Development (20 aliases)
```bash
# Core workflow (verb-r pattern)
alias load-r='Rscript -e "devtools::load_all()"'
alias test-r='Rscript -e "devtools::test()"'
alias doc-r='Rscript -e "devtools::document()"'
alias check-r='Rscript -e "devtools::check()"'
alias build-r='Rscript -e "devtools::build()"'
alias install-r='Rscript -e "devtools::install()"'

# Atomic pairs (ADHD gold - two steps in one)
alias load-test='load-r && test-r'
alias doc-test='doc-r && test-r'

# Check variants
alias check-fast='Rscript -e "devtools::check(args = c(\"--no-examples\", \"--no-tests\", \"--no-vignettes\"))"'
alias check-cran='Rscript -e "devtools::check(args = c(\"--as-cran\"))"'
alias check-rhub='Rscript -e "rhub::check_for_cran()"'
alias check-win='Rscript -e "devtools::check_win_devel()"'

# Package utilities
alias pkg-info='rpkginfo'           # Show package info
alias pkg-tree='rpkgtree'           # Show package structure
alias pkg-clean='rpkgclean'         # Clean temp files
alias pkg-cycle='rpkgcycle'         # Full dev cycle (doc+test+check)
alias pkg-down='Rscript -e "pkgdown::build_site()"'
alias pkg-preview='Rscript -e "pkgdown::preview_site()"'

# Dependencies
alias deps-tree='Rscript -e "pak::pkg_deps_tree()"'
alias deps-update='Rscript -e "pak::pkg_install(pak::local_deps())"'
```

#### Quarto (6 aliases)
```bash
alias preview-q='quarto preview'
alias render-q='quarto render'
alias check-q='quarto check'
alias clean-q='rm -rf _site/ *_cache/ *_files/'
alias new-q='qnew'                  # Function to create new project
alias work-q='qwork'                # Open editor + preview
```

#### Claude Code (12 aliases)
```bash
# Core modes
alias claude='claude'
alias claude-continue='claude -c'
alias claude-resume='claude -r'

# Models
alias claude-haiku='claude --model haiku'
alias claude-sonnet='claude --model sonnet'
alias claude-opus='claude --model opus'

# Permission modes
alias claude-plan='claude --permission-mode plan'
alias claude-auto='claude --permission-mode acceptEdits'
alias claude-yolo='claude --permission-mode bypassPermissions'

# Utilities
alias claude-mcp='claude mcp'
alias claude-plugin='claude plugin'
alias claude-ctx='claude-ctx'       # Show context
```

#### Gemini (6 aliases)
```bash
alias gemini='gemini'
alias gemini-yolo='gemini --yolo'
alias gemini-sandbox='gemini --sandbox'
alias gemini-resume='gemini --resume latest'
alias gemini-ext='gemini extensions'
alias gemini-mcp='gemini mcp'
```

#### Git (6 aliases)
```bash
alias git-status='git status -sb'
alias git-log='git log --oneline --graph --decorate --all'
alias git-undo='git reset --soft HEAD~1'
alias git-author='git log --oneline --graph --decorate --all --author'
alias git-diff='git diff'
alias git-commit='git commit'
```

#### Project Management (15 aliases)
```bash
# Project status
alias proj-status='~/projects/dev-tools/apple-notes-sync/scanner.sh'
alias proj-view='pstatview'
alias proj-count='pstatcount'
alias proj-list='pstatlist'
alias proj-show='pstatshow'

# Notes sync
alias notes-sync='pstat && ~/projects/dev-tools/apple-notes-sync/dashboard-applescript.sh'
alias notes-view='nsyncview'
alias notes-clip='nsyncclip'
alias notes-export='nsyncexport'

# Dashboard
alias dash-update='dashupdate'
alias dash-open='dashopen'

# Project detection
alias proj-type='proj-type'
alias proj-info='proj-info'
alias proj-init='claude-init'
```

#### File Viewing (8 aliases)
```bash
alias view='bat'
alias view-desc='bat DESCRIPTION'
alias view-news='bat NEWS.md'
alias view-qmd='bat --language=markdown'
alias view-r='bat --language=r'
alias view-md='bat --language=markdown'
alias view-json='bat --language=json'
alias view-yaml='bat --language=yaml'
```

#### Modern CLI Replacements (3 aliases)
```bash
alias cat='bat'
alias find='fd'
alias grep='rg'
```

#### Typo Tolerance (Keep all - ADHD essential)
```bash
# Claude typos
alias claue='claude'
alias cluade='claude'
alias clade='claude'
alias calue='claude'
alias claudee='claude'

# R typos
alias laod-r='load-r'
alias tets-r='test-r'
alias chekc-r='check-r'
alias biuld-r='build-r'

# Git typos
alias gti='git'
alias tgi='git'

# Common typos
alias clera='clear'
alias claer='clear'
alias sl='ls'
```

**Total: ~85 aliases (49% reduction from 167)**

---

## 📊 Plan B: Namespace-Prefix Pattern

**Philosophy:** Group aliases by domain with prefixes (like Emacs/Vim packages)

### Pattern Design
```
r:action        → R package development
q:action        → Quarto
claude:mode     → Claude Code
gemini:mode     → Gemini
git:action      → Git
proj:action     → Project management
view:type       → File viewing
```

### Full Alias List (Plan B)

#### R Package Development (20 aliases)
```bash
# Core workflow (r: namespace)
alias r:load='Rscript -e "devtools::load_all()"'
alias r:test='Rscript -e "devtools::test()"'
alias r:doc='Rscript -e "devtools::document()"'
alias r:check='Rscript -e "devtools::check()"'
alias r:build='Rscript -e "devtools::build()"'
alias r:install='Rscript -e "devtools::install()"'
alias r:cycle='rpkgcycle'

# Atomic combinations
alias r:load-test='r:load && r:test'
alias r:doc-test='r:doc && r:test'

# Check variants
alias r:check-fast='Rscript -e "devtools::check(args = c(\"--no-examples\", \"--no-tests\", \"--no-vignettes\"))"'
alias r:check-cran='Rscript -e "devtools::check(args = c(\"--as-cran\"))"'
alias r:check-rhub='Rscript -e "rhub::check_for_cran()"'
alias r:check-win='Rscript -e "devtools::check_win_devel()"'

# Package management
alias r:pkg-info='rpkginfo'
alias r:pkg-tree='rpkgtree'
alias r:pkg-clean='rpkgclean'
alias r:pkg-down='Rscript -e "pkgdown::build_site()"'

# Dependencies
alias r:deps='Rscript -e "pak::pkg_deps_tree()"'
alias r:deps-update='Rscript -e "pak::pkg_install(pak::local_deps())"'

# Coverage
alias r:coverage='Rscript -e "covr::package_coverage()"'
```

#### Quarto (6 aliases)
```bash
alias q:preview='quarto preview'
alias q:render='quarto render'
alias q:check='quarto check'
alias q:clean='rm -rf _site/ *_cache/ *_files/'
alias q:new='qnew'
alias q:work='qwork'
```

#### Claude Code (12 aliases)
```bash
alias claude:start='claude'
alias claude:continue='claude -c'
alias claude:resume='claude -r'

# Models
alias claude:haiku='claude --model haiku'
alias claude:sonnet='claude --model sonnet'
alias claude:opus='claude --model opus'

# Modes
alias claude:plan='claude --permission-mode plan'
alias claude:auto='claude --permission-mode acceptEdits'
alias claude:yolo='claude --permission-mode bypassPermissions'

# Tools
alias claude:mcp='claude mcp'
alias claude:plugin='claude plugin'
alias claude:ctx='claude-ctx'
```

#### Gemini (6 aliases)
```bash
alias gemini:start='gemini'
alias gemini:yolo='gemini --yolo'
alias gemini:sandbox='gemini --sandbox'
alias gemini:resume='gemini --resume latest'
alias gemini:ext='gemini extensions'
alias gemini:mcp='gemini mcp'
```

#### Git (6 aliases)
```bash
alias git:status='git status -sb'
alias git:log='git log --oneline --graph --decorate --all'
alias git:undo='git reset --soft HEAD~1'
alias git:author='git log --oneline --graph --decorate --all --author'
alias git:diff='git diff'
alias git:commit='git commit'
```

#### Project Management (15 aliases)
```bash
alias proj:status='~/projects/dev-tools/apple-notes-sync/scanner.sh'
alias proj:view='pstatview'
alias proj:count='pstatcount'
alias proj:list='pstatlist'
alias proj:show='pstatshow'
alias proj:type='proj-type'
alias proj:info='proj-info'
alias proj:init='claude-init'

alias notes:sync='pstat && ~/projects/dev-tools/apple-notes-sync/dashboard-applescript.sh'
alias notes:view='nsyncview'
alias notes:clip='nsyncclip'
alias notes:export='nsyncexport'

alias dash:update='dashupdate'
alias dash:open='dashopen'
alias dash:show='dashupdate && open -a "Claude"'
```

#### File Viewing (8 aliases)
```bash
alias view:file='bat'
alias view:desc='bat DESCRIPTION'
alias view:news='bat NEWS.md'
alias view:qmd='bat --language=markdown'
alias view:r='bat --language=r'
alias view:md='bat --language=markdown'
alias view:json='bat --language=json'
alias view:yaml='bat --language=yaml'
```

#### Modern CLI (3 aliases)
```bash
alias cat='bat'
alias find='fd'
alias grep='rg'
```

#### Typo Tolerance (Keep all)
```bash
# Same as Plan A - keep all typo aliases
```

**Total: ~85 aliases (49% reduction from 167)**

---

## 🔍 Plan Comparison

| Feature | Plan A (Verb-Noun) | Plan B (Namespace) |
|---------|-------------------|-------------------|
| **Pattern** | `test-r`, `doc-r` | `r:test`, `r:doc` |
| **Readability** | ⭐⭐⭐⭐⭐ Reads like English | ⭐⭐⭐⭐ Clear structure |
| **Tab Completion** | ⭐⭐⭐ By verb | ⭐⭐⭐⭐⭐ By domain |
| **Memory** | ⭐⭐⭐⭐⭐ Natural language | ⭐⭐⭐⭐ Logical grouping |
| **Typing** | ⭐⭐⭐⭐ Dash separator | ⭐⭐⭐ Colon separator |
| **Discoverability** | ⭐⭐⭐⭐ Search by action | ⭐⭐⭐⭐⭐ Browse by domain |
| **Conflicts** | ⭐⭐⭐ Possible verb conflicts | ⭐⭐⭐⭐⭐ Namespaced, safe |
| **ADHD-Friendly** | ⭐⭐⭐⭐⭐ Reads naturally | ⭐⭐⭐⭐ Organized clearly |

---

## 🎯 My Recommendation: **Plan A (Verb-Noun)** ⭐

### Why Plan A?

**1. Most ADHD-Friendly**
```bash
test-r          # Reads: "test R"
doc-r           # Reads: "document R"
preview-q       # Reads: "preview Quarto"
claude-continue # Reads: "Claude continue"
```
- Natural language flow
- Easy to remember (speaks like you think)
- Self-documenting

**2. Consistent Pattern**
```bash
# R actions
test-r, doc-r, check-r, build-r, load-r

# Quarto actions
preview-q, render-q, check-q, clean-q

# Claude actions
claude-continue, claude-plan, claude-yolo
```
- Same verb-noun structure everywhere
- Muscle memory builds fast
- Predictable

**3. Better Tab Completion Flow**
```bash
# Scenario: "I want to test something..."
test-<TAB>
  test-r          # Test R package

# Scenario: "I want to work with R..."
<verb>-r<TAB>
  test-r
  doc-r
  check-r
  build-r
  load-r
```

**4. Natural Combinations**
```bash
load-test       # Load then test (reads naturally)
doc-test        # Document then test (clear intent)
```

**5. Familiar to Other Tools**
- Git uses this: `git-status`, `git-log`
- npm uses this: `npm-install`, `npm-test`
- Follows Unix philosophy: `action-target`

---

## ⚠️ Why NOT Plan B?

**1. Colon Separator Issues**
```bash
r:test          # Harder to type (shift+;)
test-r          # Natural on keyboard (just dash)
```

**2. Less Natural Reading**
```bash
r:test          # Reads: "R colon test" (weird)
test-r          # Reads: "test R" (natural)
```

**3. Tab Completion Less Useful**
```bash
# Plan B: Must remember namespace first
r:<TAB>         # Shows all R commands (could be 20+)

# Plan A: Can search by action
test<TAB>       # Shows all test commands across domains
```

**4. More Mental Load**
- Must remember which namespace (r, q, claude, gemini, git, proj, notes, dash, view)
- Plan A: Just think of action first

---

## 📋 Plan A: Detailed Migration

### Remove (49 aliases)

#### All 1-2 Letter Aliases (20)
```bash
c, d, q, t, ts, bd, dc, ck, ld, rb, rc, rd, do, e, ec,
psv, psl, psc, pss, ns, nsv, nsc, nse
```

#### All cc* Prompt Aliases (17)
```bash
ccdoc, ccexplain, ccfix, ccoptimize, ccrefactor, ccreview,
ccsecurity, cctest, ccrdoc, ccrexplain, ccrfix, ccroptimize,
ccrrefactor, ccrstyle, ccrtest, ccjson, ccstream
```

#### Deprecated (3)
```bash
dashsync, dashclip, dashexport
```

#### Redundant (7)
```bash
aliases-claude, aliases-files, aliases-gemini, aliases-git,
aliases-quarto, aliases-r, aliases-short
```

#### Gemini Over-Specific (8)
```bash
gmpi, gmsd, gmyd, gmys, gmds, gmls, gmei, gmel, gmeu, gmm, gmd
```

**Total removed: 49**

### Add (85 new meaningful aliases)

See "Plan A: Full Alias List" above.

### Migration Script

```bash
#!/bin/bash
# migrate-to-plan-a.sh

echo "🔄 Migrating to Plan A (Verb-Noun Pattern)"
echo ""

# Backup
cp ~/.config/zsh/.zshrc ~/.config/zsh/.zshrc.backup-2025-12-14
echo "✅ Backup created"

# Create new aliases file
cat > ~/.config/zsh/aliases-plan-a.zsh << 'EOF'
# ============================================
# PLAN A: VERB-NOUN PATTERN
# Generated: 2025-12-14
# ============================================

# R Package Development
alias load-r='Rscript -e "devtools::load_all()"'
alias test-r='Rscript -e "devtools::test()"'
alias doc-r='Rscript -e "devtools::document()"'
alias check-r='Rscript -e "devtools::check()"'
alias build-r='Rscript -e "devtools::build()"'
alias install-r='Rscript -e "devtools::install()"'

# Atomic pairs
alias load-test='load-r && test-r'
alias doc-test='doc-r && test-r'

# Check variants
alias check-fast='Rscript -e "devtools::check(args = c(\"--no-examples\", \"--no-tests\", \"--no-vignettes\"))"'
alias check-cran='Rscript -e "devtools::check(args = c(\"--as-cran\"))"'

# Package utilities
alias pkg-info='rpkginfo'
alias pkg-tree='rpkgtree'
alias pkg-clean='rpkgclean'
alias pkg-cycle='rpkgcycle'
alias pkg-down='Rscript -e "pkgdown::build_site()"'

# Quarto
alias preview-q='quarto preview'
alias render-q='quarto render'
alias check-q='quarto check'
alias clean-q='rm -rf _site/ *_cache/ *_files/'

# Claude Code
alias claude='claude'
alias claude-continue='claude -c'
alias claude-resume='claude -r'
alias claude-haiku='claude --model haiku'
alias claude-sonnet='claude --model sonnet'
alias claude-opus='claude --model opus'
alias claude-plan='claude --permission-mode plan'
alias claude-auto='claude --permission-mode acceptEdits'
alias claude-yolo='claude --permission-mode bypassPermissions'

# Gemini
alias gemini='gemini'
alias gemini-yolo='gemini --yolo'
alias gemini-sandbox='gemini --sandbox'
alias gemini-resume='gemini --resume latest'

# Git
alias git-status='git status -sb'
alias git-log='git log --oneline --graph --decorate --all'
alias git-undo='git reset --soft HEAD~1'

# Project Management
alias proj-status='~/projects/dev-tools/apple-notes-sync/scanner.sh'
alias notes-sync='pstat && ~/projects/dev-tools/apple-notes-sync/dashboard-applescript.sh'

# File Viewing
alias view='bat'
alias view-desc='bat DESCRIPTION'
alias view-news='bat NEWS.md'

# Modern CLI
alias cat='bat'
alias find='fd'
alias grep='rg'

# Typo tolerance (keep all)
alias claue='claude'
alias cluade='claude'
alias clade='claude'
alias laod-r='load-r'
alias tets-r='test-r'
alias gti='git'
alias clera='clear'
EOF

echo "✅ New aliases file created: ~/.config/zsh/aliases-plan-a.zsh"
echo ""
echo "📝 Next steps:"
echo "1. Review: cat ~/.config/zsh/aliases-plan-a.zsh"
echo "2. Source it: source ~/.config/zsh/aliases-plan-a.zsh"
echo "3. Add to .zshrc: echo 'source ~/.config/zsh/aliases-plan-a.zsh' >> ~/.config/zsh/.zshrc"
echo "4. Test: test-r, doc-r, preview-q, claude-continue"
echo ""
echo "🔄 Rollback: cp ~/.config/zsh/.zshrc.backup-2025-12-14 ~/.config/zsh/.zshrc"
```

---

## 🎯 Implementation Timeline

### Week 1: Soft Launch
```bash
# Add new aliases alongside old ones
source ~/.config/zsh/aliases-plan-a.zsh

# Use new aliases, old ones still work
test-r     # New way
ts         # Old way (still works)
```

### Week 2: Muscle Memory
```bash
# Start removing old 1-2 letter aliases
# Keep both systems during transition
```

### Week 3: Full Migration
```bash
# Remove all old aliases
# Only Plan A remains
```

---

## ✅ Success Metrics

**Week 1:**
- [ ] New aliases file created
- [ ] Can use both old and new aliases
- [ ] No broken workflows

**Week 2:**
- [ ] Using new aliases 50% of the time
- [ ] Muscle memory forming
- [ ] Tab completion feels natural

**Week 3:**
- [ ] Using new aliases 100% of the time
- [ ] Old aliases removed
- [ ] Help system updated
- [ ] Documentation updated

---

## 💡 Future Enhancements (After Migration)

### Smart Help System
```bash
ah r        # Shows: load-r, test-r, doc-r, check-r, build-r
ah quarto   # Shows: preview-q, render-q, check-q
ah claude   # Shows: claude-continue, claude-plan, etc.
```

### Usage Analytics
```bash
alias-stats # Shows most-used aliases
# Output:
# 1. test-r       (142 times)
# 2. doc-r        (89 times)
# 3. load-r       (67 times)
```

### Interactive Alias Builder
```bash
alias-create
# What tool? (r/quarto/claude/git) › r
# What action? (test/doc/check/build) › test
# Creating: test-r='Rscript -e "devtools::test()"'
# Add to .zshrc? (y/n) › y
```

---

## 🎉 Why This Matters

**Before (Current):**
```bash
# User thinking: "How do I test R package?"
# Options: t, ts, rtest (which one? I forget!)
# Confusion → frustration → wasted time
```

**After (Plan A):**
```bash
# User thinking: "How do I test R package?"
# Answer: test-r (reads naturally!)
# Clear → confident → productive
```

**ADHD Benefits:**
- ✅ No guessing ("was it t or ts or rtest?")
- ✅ Speaks like you think ("test R" = test-r)
- ✅ Tab completion guides you
- ✅ Patterns are predictable
- ✅ Self-documenting code

---

*Recommendation: **Plan A (Verb-Noun Pattern)***
*Rationale: Most natural for ADHD brain, easiest to remember, best long-term*
