# Alias Refactoring Plan

**Date:** 2025-12-14
**Current State:** 167 aliases
**Target State:** ~88 aliases (47% reduction)
**Goal:** Remove duplicates, fix conflicts, improve ADHD-friendliness

---

## 📊 Executive Summary

**Analysis of 167 aliases reveals:**

- 19 aliases should be **REMOVED** (deprecated, duplicates, conflicts)
- 30 aliases should be **CONSOLIDATED** (too many variants)
- 118 aliases are **WELL-DESIGNED** and should be kept
- **Impact:** Cleaner mental model, fewer conflicts, better discoverability

---

## 🔴 REMOVE (19 aliases)

### 1. Deprecated with Warnings (3)

These already warn users to use new commands - just remove them:

```bash
unalias dashsync     # Use: nsync
unalias dashclip     # Use: nsyncclip
unalias dashexport   # Use: nsyncexport
```

**Rationale:** Users already migrated. Warning messages are noise.

---

### 2. Duplicate Short Aliases (9)

**R Documentation - Remove `dc` (conflicts with Docker)**

```bash
unalias dc           # ❌ Conflicts with docker-compose users
# Keep: rd='rdoc'    # ✅ R + Doc pattern
```

**R Build - Remove `bd` (conflicts with "back directory")**

```bash
unalias bd           # ❌ Vague, potential conflicts
# Keep: rb='rbuild'  # ✅ R + Build pattern
```

**R Check - Remove `ck` (too vague)**

```bash
unalias ck           # ❌ Vague abbreviation
# Keep: rc='rcheck'  # ✅ R + Check pattern
```

**R Load - Remove `ld` (conflicts with "list directory")**

```bash
unalias ld           # ❌ Conflicts with ld linker, list dir
# Use: rload         # ✅ Already short enough
```

**R Test - Remove `t` (conflicts with tmux)**

```bash
unalias t            # ❌ Conflicts with tmux prefix, tree command
# Keep: ts='rtest'   # ✅ Test Short
```

**Claude - Remove `c` (conflicts with cd users)**

```bash
unalias c            # ❌ Conflicts with common cd aliases
# Keep: cc='claude'  # ✅ Clear, memorable
```

**Quarto - Remove `q` (conflicts with quit)**

```bash
unalias q            # ❌ Conflicts with quit, q in vi/less
# Keep: qp='quarto preview'  # ✅ Clear purpose
```

**Directories - Remove `d` (use dirs -v directly)**

```bash
unalias d            # ❌ Single-letter for uncommon command
# Use: dirs -v       # ✅ Clear, built-in
```

**Dashboard - Remove `do` (too vague)**

```bash
unalias do           # ❌ Conflicts with shell keywords
# Use: dashopen      # ✅ Explicit
```

---

### 3. Redundant Function Wrappers (1)

```bash
unalias gpkgcommit   # Just use: rpkgcommit (function exists)
```

---

### 4. Redundant Aliases to Aliases (7)

These just add `aliases` prefix to `ah` help system:

```bash
unalias aliases-claude   # Use: ah claude
unalias aliases-files    # Use: ah files
unalias aliases-gemini   # Use: ah gemini
unalias aliases-git      # Use: ah git
unalias aliases-quarto   # Use: ah quarto
unalias aliases-r        # Use: ah r
unalias aliases-short    # Use: ah short
```

**Rationale:** `ah` is shorter, more memorable, ADHD-friendly.

---

## 🟡 CONSOLIDATE (30 aliases → 8)

### Claude Code Prompts (17 → 3)

**Currently have 17 prompt aliases:**

```bash
ccdoc       → claude "Generate documentation for this code"
ccexplain   → claude "Explain this code clearly and concisely"
ccfix       → claude "Fix the bugs in this code"
ccoptimize  → claude "Optimize this code for performance"
ccrefactor  → claude "Refactor this code for better readability"
ccreview    → claude "Review this code for issues and improvements"
ccsecurity  → claude "Review this code for security vulnerabilities"
cctest      → claude "Generate comprehensive tests for this code"
ccrdoc      → claude "Generate roxygen2 documentation for this function"
ccrexplain  → claude "Explain this R code in detail"
ccrfix      → claude "Fix R CMD check issues in this package"
ccroptimize → claude "Optimize this R code for performance"
ccrrefactor → claude "Refactor this R code following tidyverse style guide"
ccrstyle    → claude "Apply tidyverse style guide to this R code"
ccrtest     → claude "Generate testthat tests for this function"
ccjson      → claude --output-format json
ccstream    → claude --output-format stream-json
```

**Remove all 17 prompt aliases.**

**Why:**

- Already have `ccp="claude -p"` for prompts
- Users can just use: `ccp "Explain this code"`
- Cleaner, more flexible, easier to remember
- Reduces 17 aliases to 1 pattern

**Keep only mode/model aliases (8):**

```bash
cc='claude'                                    # Interactive
ccc='claude -c'                                # Continue
cch='claude --model haiku'                     # Haiku model
cco='claude --model opus'                      # Opus model
ccs='claude --model sonnet'                    # Sonnet model
ccplan='claude --permission-mode plan'         # Plan mode
ccauto='claude --permission-mode acceptEdits'  # Auto-accept edits
ccyolo='claude --permission-mode bypassPermissions'  # Bypass all
```

**Migration Guide:**

```bash
# Old way:
ccfix

# New way:
ccp "Fix the bugs in this code"
# Or even simpler:
cc  # Then type your request interactively
```

---

### Gemini Variants (13 → 5)

**Currently have 13 gemini aliases:**

```bash
gm='gemini'                    # Interactive
gmpi='gemini -i'               # Prompt then interactive
gmy='gemini --yolo'            # YOLO mode
gms='gemini --sandbox'         # Sandbox
gmd='gemini --debug'           # Debug
gmr='gemini --resume latest'   # Resume
gmls='gemini --list-sessions'  # List sessions
gmds='gemini --delete-session' # Delete session
gme='gemini extensions'        # Extensions
gmei='gemini extensions install'
gmel='gemini --list-extensions'
gmeu='gemini extensions update'
gmm='gemini mcp'               # MCP management
gmsd='gemini --sandbox --debug'
gmyd='gemini --yolo --debug'
gmys='gemini --yolo --sandbox'
```

**Keep only 5 essential aliases:**

```bash
gm='gemini'                  # Interactive
gmy='gemini --yolo'          # YOLO mode (most used power mode)
gms='gemini --sandbox'       # Sandbox (safety)
gmr='gemini --resume latest' # Resume (common workflow)
gme='gemini extensions'      # Extensions (common management)
```

**Remove 8 aliases:**

```bash
unalias gmpi    # Use: gm -i
unalias gmsd    # Use: gms --debug (if needed)
unalias gmyd    # Use: gmy --debug (if needed)
unalias gmys    # Use: gmy --sandbox (rare combo)
unalias gmds    # Use: gm --delete-session (rare)
unalias gmls    # Use: gm --list-sessions (rare)
unalias gmei    # Use: gme install (clear enough)
unalias gmel    # Use: gm --list-extensions (rare)
unalias gmeu    # Use: gme update (clear enough)
unalias gmm     # Use: gm mcp (clear enough)
```

**Why:**

- Flag combinations (gmsd, gmyd, gmys) are rare - just use flags
- Sub-commands (gmei, gmel, gmeu, gmm) - use `gme`/`gm` directly
- Reduces 13 aliases to 5 core workflows

---

## 🟢 KEEP (118 aliases)

### R Package Development (Core Workflow) ✅

```bash
rload, rtest, rdoc, rcheck, rbuild, rcycle, rinstall
rbumpmajor, rbumpminor, rbumppatch
rpkg, rpkginfo, rpkgdown, rpkgpreview
rdeps, rdepsupdate, rdepsexplain
rtest1, rtestfile
```

**Atomic Pairs (ADHD Gold):**

```bash
lt='rload && rtest'     # Load then test
dt='rdoc && rtest'      # Document then test
```

### Typo Tolerance (ADHD Essential) ✅

**Keep all 20 typo aliases:**

```bash
# Claude typos
claue, cluade, clade, calue, claudee

# R package typos
rlaod, rlod, rtets, rtset, rdco, rchekc, rchck, rcylce

# Git typos
gti, tgi, gis, gitstatus

# Common typos
clera, claer, sl, pdw

# Quarto typos
qurto, qaurt
```

**Rationale:** These are ADHD lifesavers. Keep them all.

### Project Status & Dashboard ✅

```bash
# Full names (documentation)
pstat, pstatview, pstatshow, pstatlist, pstatcount

# Ultra-short (power users)
psv, psl, psc, pss

# Notes sync
nsync, nsyncview, nsyncclip, nsyncexport
ns, nsv, nsc, nse

# Legacy
dash, dashopen  # (Keep dash for muscle memory)
```

### Git Workflow ✅

```bash
gs='git status -sb'
glog='git log --oneline --graph --decorate --all'
gloga='git log --oneline --graph --decorate --all --author'
gundo='git reset --soft HEAD~1'
```

### Command Replacements (Modern CLI) ✅

```bash
cat='bat'
grep='rg'
find='fd'
peek='bat'
```

### Quarto ✅

```bash
qp='quarto preview'
qr='quarto render'
qc='quarto check'
qclean='rm -rf _site/ *_cache/ *_files/'
cdq='cd $QUARTO_DIR'
```

### Emacs ✅

```bash
e="/opt/homebrew/opt/emacs-plus@30/bin/emacsclient -c -a ''"
ec="/opt/homebrew/opt/emacs-plus@30/bin/emacsclient -c -a ''"
```

### Project Detection (zsh-claude-workflow) ✅

```bash
ptype='proj-type'
pinfo='proj-info'
cctx='claude-ctx'
cinit='claude-init'
cshow='claude-show'
pclaude='proj-claude'
```

### Peek Aliases (bat viewers) ✅

```bash
peek='bat'
peekdesc='bat DESCRIPTION'
peeknews='bat NEWS.md'
peekqmd='bat --language=markdown'
peekr='bat --language=r'
peekrd='bat --language=markdown'
```

### R Package Utilities ✅

```bash
rpkgtree='tree -L 3 -I "renv|.Rproj.user|*.Rcheck|docs|*.tar.gz|src/*.o|src/*.so"'
rpkgclean='rm -rf .Rhistory .RData .Rproj.user'
rpkgdeep='rm -rf man/*.Rd NAMESPACE docs/ *.tar.gz *.Rcheck/'
rspell='Rscript -e "spelling::spell_check_package()"'
rcov='Rscript -e "covr::package_coverage()"'
rcovrep='Rscript -e "covr::report()"'
```

### R Check Variants ✅

```bash
rcheckfast='Rscript -e "devtools::check(args = c(\"--no-examples\", \"--no-tests\", \"--no-vignettes\"))"'
rcheckcran='Rscript -e "devtools::check(args = c(\"--as-cran\"))"'
rcheckrhub='Rscript -e "rhub::check_for_cran()"'
rcheckwin='Rscript -e "devtools::check_win_devel()"'
rdoccheck='Rscript -e "devtools::check_man()"'
```

### Directory Shortcuts ✅

```bash
cdq='cd $QUARTO_DIR'
cdrpkg='cd $R_PACKAGES_DIR'
```

### Claude Code Essentials ✅

```bash
ccl='claude --resume latest'
ccr='claude -r'  # Resume with picker
ccmcp='claude mcp'
ccplugin='claude plugin'
```

---

## 📋 Implementation Plan

### Phase 1: Backup (5 min)

```bash
# Create backup
cp ~/.config/zsh/.zshrc ~/.config/zsh/.zshrc.backup-2025-12-14

# Create backup of functions too
cp ~/.config/zsh/functions/adhd-helpers.zsh ~/.config/zsh/functions/adhd-helpers.zsh.backup-2025-12-14
```

### Phase 2: Remove Aliases (15 min)

Edit `~/.config/zsh/.zshrc` and remove the 19 aliases listed above:

**Remove these lines:**

```bash
# Deprecated (3)
alias dashsync='echo "⚠️  Use: nsync" && nsync'
alias dashclip='echo "⚠️  Use: nsyncclip" && nsyncclip'
alias dashexport='echo "⚠️  Use: nsyncexport" && nsyncexport'

# Duplicate shorts (9)
alias c='claude'
alias d='dirs -v | head -10'
alias q='qp'
alias t='rtest'
alias bd='rbuild'
alias dc='rdoc'
alias ck='rcheck'
alias ld='rload'
alias do='dashopen'

# Redundant wrappers (1)
alias gpkgcommit='rpkgcommit'

# Redundant aliases-* (7)
alias aliases-claude='aliases claude'
alias aliases-files='aliases files'
alias aliases-gemini='aliases gemini'
alias aliases-git='aliases git'
alias aliases-quarto='aliases quarto'
alias aliases-r='aliases r'
alias aliases-short='aliases short'
```

### Phase 3: Consolidate Claude Aliases (20 min)

**Remove these 17 prompt aliases:**

```bash
alias ccdoc='claude "Generate documentation for this code"'
alias ccexplain='claude -p "Explain this code clearly and concisely"'
alias ccfix='claude "Fix the bugs in this code"'
alias ccoptimize='claude "Optimize this code for performance"'
alias ccrefactor='claude "Refactor this code for better readability"'
alias ccreview='claude "Review this code for issues and improvements"'
alias ccsecurity='claude "Review this code for security vulnerabilities"'
alias cctest='claude "Generate comprehensive tests for this code"'
alias ccrdoc='claude -p "Generate roxygen2 documentation for this function"'
alias ccrexplain='claude -p "Explain this R code in detail"'
alias ccrfix='claude "Fix R CMD check issues in this package"'
alias ccroptimize='claude "Optimize this R code for performance"'
alias ccrrefactor='claude "Refactor this R code following tidyverse style guide"'
alias ccrstyle='claude "Apply tidyverse style guide to this R code"'
alias ccrtest='claude -p "Generate testthat tests for this function"'
alias ccjson='claude -p --output-format json'
alias ccstream='claude -p --output-format stream-json'
```

**Keep only these 8:**

```bash
alias cc='claude'
alias ccc='claude -c'
alias cch='claude --model haiku'
alias cco='claude --model opus'
alias ccs='claude --model sonnet'
alias ccplan='claude --permission-mode plan'
alias ccauto='claude --permission-mode acceptEdits'
alias ccyolo='claude --permission-mode bypassPermissions'
```

### Phase 4: Consolidate Gemini Aliases (10 min)

**Remove these 8:**

```bash
alias gmpi='gemini -i'
alias gmsd='gemini --sandbox --debug'
alias gmyd='gemini --yolo --debug'
alias gmys='gemini --yolo --sandbox'
alias gmds='gemini --delete-session'
alias gmls='gemini --list-sessions'
alias gmei='gemini extensions install'
alias gmel='gemini --list-extensions'
alias gmeu='gemini extensions update'
alias gmm='gemini mcp'
alias gmd='gemini --debug'
```

**Keep only these 5:**

```bash
alias gm='gemini'
alias gmy='gemini --yolo'
alias gms='gemini --sandbox'
alias gmr='gemini --resume latest'
alias gme='gemini extensions'
```

### Phase 5: Update Help System (30 min)

Update `~/.config/zsh/functions/adhd-helpers.zsh` to reflect changes:

**Update `aliashelp()` function to show:**

- Migration notes for removed aliases
- New patterns (e.g., "Use `ccp 'prompt'` instead of cc\* aliases")
- Cleaner categorization

### Phase 6: Test (15 min)

```bash
# Reload config
source ~/.config/zsh/.zshrc

# Test removed aliases give clear errors
c          # Should error
dc         # Should error
ccfix      # Should error

# Test kept aliases work
cc         # Should work
rd         # Should work
ccp "test" # Should work

# Run test suite
~/.config/zsh/tests/test-adhd-helpers.zsh
```

### Phase 7: Update Documentation (20 min)

Update these files:

- `ALIAS-REFERENCE-CARD.md` - Remove old aliases
- `WORKFLOWS-QUICK-WINS.md` - Update examples
- `.STATUS` - Mark refactor complete
- `TODO.md` - Check off task

---

## 🎯 Expected Outcomes

### Quantitative

- **Before:** 167 aliases
- **After:** ~88 aliases
- **Reduction:** 47%
- **Mental load:** Significantly reduced

### Qualitative

- ✅ No more 1-letter conflicts (c, d, q, t)
- ✅ Clearer patterns (use `ccp` for prompts)
- ✅ Less duplication (one way to do things)
- ✅ Better for ADHD (fewer decisions)
- ✅ Easier onboarding (smaller reference card)

---

## 📝 Migration Notes for User

### Quick Reference

**What changed:**

1. **Removed 1-letter aliases:**
   - ❌ `c` → Use `cc` for Claude
   - ❌ `t` → Use `ts` for test
   - ❌ `q` → Use `qp` for Quarto preview
   - ❌ `d` → Use `dirs -v` directly

2. **Removed duplicate R shortcuts:**
   - ❌ `dc`, `bd`, `ck`, `ld` → Use `rd`, `rb`, `rc`, `rload`

3. **Removed prompt aliases:**
   - ❌ `ccfix`, `ccexplain`, etc. → Use `ccp "your prompt"`

4. **Removed alias-\* helpers:**
   - ❌ `aliases-claude`, etc. → Use `ah claude`

5. **Removed deprecated:**
   - ❌ `dashsync`, `dashclip`, `dashexport` → Already using new names

### Muscle Memory Retraining

If you keep typing removed aliases:

**Option A:** Add them back to `.zshrc.local` (machine-specific)

```bash
# ~/.zshrc.local
alias c='cc'
alias t='ts'
```

**Option B:** Let muscle memory adapt (recommended - usually takes 3-5 days)

---

## 🔄 Rollback Plan

If anything breaks:

```bash
# Restore backup
cp ~/.config/zsh/.zshrc.backup-2025-12-14 ~/.config/zsh/.zshrc

# Reload
source ~/.config/zsh/.zshrc
```

---

## ✅ Success Criteria

- [ ] All 19 aliases removed from `.zshrc`
- [ ] All 30 consolidated aliases removed
- [ ] Test suite passes (49 tests, >95% pass rate)
- [ ] Help system updated with migration notes
- [ ] Documentation updated
- [ ] No broken workflows in daily use
- [ ] Muscle memory adapted within 1 week

---

## 📅 Timeline

- **Phase 1-4:** Today (1 hour)
- **Phase 5-6:** Today (45 min)
- **Phase 7:** Today (20 min)
- **Total:** ~2 hours
- **Validation:** 1 week of daily use

---

## 🎉 Why This Matters

**Before:** "I have 167 aliases. Which one do I use?"
**After:** "I have 88 focused aliases. The pattern is clear."

**ADHD Benefits:**

- Fewer decisions = less cognitive load
- Clear patterns = easier memory
- No conflicts = less frustration
- Better help system = easier discovery

---

_Created: 2025-12-14_
_Ready for implementation_
