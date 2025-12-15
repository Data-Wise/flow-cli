# Alias Refactoring: Three Plans
**Date:** 2025-12-14
**Key Insight:** User likes existing `proj-*` pattern (e.g., `proj-status`, `proj-info`)
**Goal:** Extend that pattern across all aliases

---

## 🎯 Current "Proj" Pattern (What You Like)

```bash
# Existing aliases you like:
proj-status      # Project status
proj-view        # View projects
proj-info        # Project info
proj-type        # Project type detection
```

**Why this works:**
- ✅ Domain first (proj-)
- ✅ Dash separator (easy to type)
- ✅ Tab completion shows all proj- commands
- ✅ Clear namespace

---

## 📊 Three Plans

### Quick Comparison

| Plan | Pattern | Example | Best For |
|------|---------|---------|----------|
| **A** | `domain-action` | `r-test`, `quarto-preview` | Consistency, tab completion |
| **B** | `domain-short` | `r-test`, `q-preview` | Balance of clarity & brevity |
| **C** | `action-domain` | `test-r`, `preview-quarto` | Natural reading |

---

## 🅰️ Plan A: Full Domain Names (Most Explicit)

**Pattern:** `[full-domain]-[action]`

### Philosophy
- Every alias starts with full domain name
- Maximum clarity, zero ambiguity
- Best tab completion (type domain, see all options)

### Examples
```bash
# R Package Development
r-load, r-test, r-doc, r-check, r-build

# Quarto
quarto-preview, quarto-render, quarto-check

# Claude Code
claude-start, claude-continue, claude-plan, claude-yolo

# Gemini
gemini-start, gemini-yolo, gemini-sandbox

# Git
git-status, git-log, git-undo

# Project Management
proj-status, proj-info, proj-type  # (already have these!)

# Notes
notes-sync, notes-view, notes-clip

# File Viewing
view-file, view-desc, view-news
```

### Full Alias Set (Plan A)

#### R Package Development (25 aliases)
```bash
# Core workflow
alias r-load='Rscript -e "devtools::load_all()"'
alias r-test='Rscript -e "devtools::test()"'
alias r-doc='Rscript -e "devtools::document()"'
alias r-check='Rscript -e "devtools::check()"'
alias r-build='Rscript -e "devtools::build()"'
alias r-install='Rscript -e "devtools::install()"'
alias r-cycle='rpkgcycle'

# Atomic pairs
alias r-load-test='r-load && r-test'
alias r-doc-test='r-doc && r-test'

# Check variants
alias r-check-fast='Rscript -e "devtools::check(args = c(\"--no-examples\", \"--no-tests\", \"--no-vignettes\"))"'
alias r-check-cran='Rscript -e "devtools::check(args = c(\"--as-cran\"))"'
alias r-check-rhub='Rscript -e "rhub::check_for_cran()"'
alias r-check-win='Rscript -e "devtools::check_win_devel()"'

# Package utilities
alias r-pkg-info='rpkginfo'
alias r-pkg-tree='rpkgtree'
alias r-pkg-clean='rpkgclean'
alias r-pkg-deep='rm -rf man/*.Rd NAMESPACE docs/ *.tar.gz *.Rcheck/'
alias r-pkg-down='Rscript -e "pkgdown::build_site()"'
alias r-pkg-preview='Rscript -e "pkgdown::preview_site()"'

# Dependencies
alias r-deps-tree='Rscript -e "pak::pkg_deps_tree()"'
alias r-deps-update='Rscript -e "pak::pkg_install(pak::local_deps())"'
alias r-deps-explain='rdepsexplain'

# Coverage
alias r-coverage='Rscript -e "covr::package_coverage()"'
alias r-coverage-report='Rscript -e "covr::report()"'

# Spelling
alias r-spell='Rscript -e "spelling::spell_check_package()"'
```

#### Quarto (6 aliases)
```bash
alias quarto-preview='quarto preview'
alias quarto-render='quarto render'
alias quarto-check='quarto check'
alias quarto-clean='rm -rf _site/ *_cache/ *_files/'
alias quarto-new='qnew'
alias quarto-work='qwork'
```

#### Claude Code (15 aliases)
```bash
# Core
alias claude-start='claude'
alias claude-continue='claude -c'
alias claude-resume='claude -r'
alias claude-resume-latest='claude --resume latest'

# Models
alias claude-haiku='claude --model haiku'
alias claude-sonnet='claude --model sonnet'
alias claude-opus='claude --model opus'

# Permission modes
alias claude-plan='claude --permission-mode plan'
alias claude-auto='claude --permission-mode acceptEdits'
alias claude-yolo='claude --permission-mode bypassPermissions'

# Tools
alias claude-mcp='claude mcp'
alias claude-plugin='claude plugin'

# Context
alias claude-ctx='claude-ctx'
alias claude-init='claude-init'
alias claude-show='claude-show'
```

#### Gemini (6 aliases)
```bash
alias gemini-start='gemini'
alias gemini-yolo='gemini --yolo'
alias gemini-sandbox='gemini --sandbox'
alias gemini-resume='gemini --resume latest'
alias gemini-extensions='gemini extensions'
alias gemini-mcp='gemini mcp'
```

#### Git (8 aliases)
```bash
alias git-status='git status -sb'
alias git-log='git log --oneline --graph --decorate --all'
alias git-log-author='git log --oneline --graph --decorate --all --author'
alias git-undo='git reset --soft HEAD~1'
alias git-diff='git diff'
alias git-commit='git commit'
alias git-add='git add'
alias git-push='git push'
```

#### Project Management (15 aliases)
```bash
# Project status
alias proj-status='~/projects/dev-tools/apple-notes-sync/scanner.sh'
alias proj-view='pstatview'
alias proj-count='pstatcount'
alias proj-list='pstatlist'
alias proj-show='pstatshow'

# Project detection
alias proj-type='proj-type'
alias proj-info='proj-info'
alias proj-init='claude-init'

# Dashboard
alias dash-update='dashupdate'
alias dash-open='dashopen'

# Notes
alias notes-sync='pstat && ~/projects/dev-tools/apple-notes-sync/dashboard-applescript.sh'
alias notes-view='nsyncview'
alias notes-clip='nsyncclip'
alias notes-export='nsyncexport'
```

#### File Viewing (10 aliases)
```bash
alias view-file='bat'
alias view-desc='bat DESCRIPTION'
alias view-news='bat NEWS.md'
alias view-readme='bat README.md'
alias view-qmd='bat --language=markdown'
alias view-r='bat --language=r'
alias view-md='bat --language=markdown'
alias view-json='bat --language=json'
alias view-yaml='bat --language=yaml'
alias view-toml='bat --language=toml'
```

#### Modern CLI (3 aliases)
```bash
alias cat='bat'
alias find='fd'
alias grep='rg'
```

#### Directories (2 aliases)
```bash
alias dir-quarto='cd $QUARTO_DIR'
alias dir-rpkg='cd $R_PACKAGES_DIR'
```

#### Typo Tolerance (20+ aliases)
```bash
# Claude typos
alias claue='claude'
alias cluade='claude'
alias clade='claude'
alias calue='claude'
alias claudee='claude'

# R typos (map to new names)
alias rlaod='r-load'
alias rlod='r-load'
alias rtets='r-test'
alias rtset='r-test'
alias rdco='r-doc'
alias rchekc='r-check'
alias rchck='r-check'

# Git typos
alias gti='git'
alias tgi='git'

# Common typos
alias clera='clear'
alias claer='clear'
alias sl='ls'
alias pdw='pwd'
```

**Total: ~95 aliases**

---

## 🅱️ Plan B: Short Domain Names (Balanced)

**Pattern:** `[short-domain]-[action]`

### Philosophy
- Domain abbreviated to 1-3 chars
- Balance between clarity and brevity
- Still groupable by domain

### Examples
```bash
# R Package Development
r-load, r-test, r-doc, r-check, r-build

# Quarto (q-)
q-preview, q-render, q-check

# Claude Code (c-)
c-start, c-continue, c-plan, c-yolo

# Gemini (g-)
g-start, g-yolo, g-sandbox

# Git (git-)
git-status, git-log, git-undo

# Project Management (proj-)
proj-status, proj-info, proj-type

# Notes (n-)
n-sync, n-view, n-clip
```

### Full Alias Set (Plan B)

#### R Package Development (25 aliases)
```bash
# Same as Plan A, keep r- prefix
alias r-load='Rscript -e "devtools::load_all()"'
alias r-test='Rscript -e "devtools::test()"'
alias r-doc='Rscript -e "devtools::document()"'
alias r-check='Rscript -e "devtools::check()"'
alias r-build='Rscript -e "devtools::build()"'
# ... (all r-* aliases from Plan A)
```

#### Quarto (6 aliases)
```bash
alias q-preview='quarto preview'
alias q-render='quarto render'
alias q-check='quarto check'
alias q-clean='rm -rf _site/ *_cache/ *_files/'
alias q-new='qnew'
alias q-work='qwork'
```

#### Claude Code (15 aliases)
```bash
alias c-start='claude'
alias c-continue='claude -c'
alias c-resume='claude -r'
alias c-latest='claude --resume latest'

# Models
alias c-haiku='claude --model haiku'
alias c-sonnet='claude --model sonnet'
alias c-opus='claude --model opus'

# Modes
alias c-plan='claude --permission-mode plan'
alias c-auto='claude --permission-mode acceptEdits'
alias c-yolo='claude --permission-mode bypassPermissions'

# Tools
alias c-mcp='claude mcp'
alias c-plugin='claude plugin'

# Context
alias c-ctx='claude-ctx'
alias c-init='claude-init'
alias c-show='claude-show'
```

#### Gemini (6 aliases)
```bash
alias g-start='gemini'
alias g-yolo='gemini --yolo'
alias g-sandbox='gemini --sandbox'
alias g-resume='gemini --resume latest'
alias g-ext='gemini extensions'
alias g-mcp='gemini mcp'
```

#### Git (8 aliases)
```bash
# Keep 'git-' (already short, familiar)
alias git-status='git status -sb'
alias git-log='git log --oneline --graph --decorate --all'
alias git-log-author='git log --oneline --graph --decorate --all --author'
alias git-undo='git reset --soft HEAD~1'
alias git-diff='git diff'
alias git-commit='git commit'
alias git-add='git add'
alias git-push='git push'
```

#### Project Management (15 aliases)
```bash
# Keep 'proj-' (already perfect)
alias proj-status='~/projects/dev-tools/apple-notes-sync/scanner.sh'
alias proj-view='pstatview'
alias proj-count='pstatcount'
alias proj-list='pstatlist'
alias proj-show='pstatshow'
alias proj-type='proj-type'
alias proj-info='proj-info'
alias proj-init='claude-init'

# Dashboard
alias dash-update='dashupdate'
alias dash-open='dashopen'

# Notes (n- for brevity)
alias n-sync='pstat && ~/projects/dev-tools/apple-notes-sync/dashboard-applescript.sh'
alias n-view='nsyncview'
alias n-clip='nsyncclip'
alias n-export='nsyncexport'
```

#### File Viewing (10 aliases)
```bash
alias v-file='bat'
alias v-desc='bat DESCRIPTION'
alias v-news='bat NEWS.md'
alias v-readme='bat README.md'
alias v-qmd='bat --language=markdown'
alias v-r='bat --language=r'
alias v-md='bat --language=markdown'
alias v-json='bat --language=json'
alias v-yaml='bat --language=yaml'
alias v-toml='bat --language=toml'
```

#### Modern CLI (3 aliases)
```bash
alias cat='bat'
alias find='fd'
alias grep='rg'
```

#### Directories (2 aliases)
```bash
alias dir-q='cd $QUARTO_DIR'
alias dir-r='cd $R_PACKAGES_DIR'
```

#### Typo Tolerance (20+ aliases)
```bash
# Same as Plan A, map to new names
alias rlaod='r-load'
alias rtets='r-test'
# ... (all typo aliases)
```

**Total: ~95 aliases**

---

## 🅲 Plan C: Action-Domain (Natural Reading)

**Pattern:** `[action]-[domain]`

### Philosophy
- Action word comes first
- Reads like natural English
- "test the R package" = test-r

### Examples
```bash
# R Package Development
load-r, test-r, doc-r, check-r, build-r

# Quarto
preview-quarto, render-quarto, check-quarto

# Claude Code
continue-claude, plan-claude, yolo-claude

# Gemini
yolo-gemini, sandbox-gemini, resume-gemini

# Git
status-git, log-git, undo-git

# Project Management
status-proj, info-proj, type-proj  # Or keep proj-*?

# Notes
sync-notes, view-notes, clip-notes
```

### Full Alias Set (Plan C)

#### R Package Development (25 aliases)
```bash
# Core workflow (action-r pattern)
alias load-r='Rscript -e "devtools::load_all()"'
alias test-r='Rscript -e "devtools::test()"'
alias doc-r='Rscript -e "devtools::document()"'
alias check-r='Rscript -e "devtools::check()"'
alias build-r='Rscript -e "devtools::build()"'
alias install-r='Rscript -e "devtools::install()"'
alias cycle-r='rpkgcycle'

# Atomic pairs
alias load-test-r='load-r && test-r'
alias doc-test-r='doc-r && test-r'

# Check variants
alias check-fast-r='Rscript -e "devtools::check(args = c(\"--no-examples\", \"--no-tests\", \"--no-vignettes\"))"'
alias check-cran-r='Rscript -e "devtools::check(args = c(\"--as-cran\"))"'
alias check-rhub-r='Rscript -e "rhub::check_for_cran()"'
alias check-win-r='Rscript -e "devtools::check_win_devel()"'

# Package utilities
alias info-rpkg='rpkginfo'
alias tree-rpkg='rpkgtree'
alias clean-rpkg='rpkgclean'
alias deep-clean-rpkg='rm -rf man/*.Rd NAMESPACE docs/ *.tar.gz *.Rcheck/'
alias down-rpkg='Rscript -e "pkgdown::build_site()"'
alias preview-rpkg='Rscript -e "pkgdown::preview_site()"'

# Dependencies
alias tree-deps='Rscript -e "pak::pkg_deps_tree()"'
alias update-deps='Rscript -e "pak::pkg_install(pak::local_deps())"'
alias explain-deps='rdepsexplain'

# Coverage
alias coverage-r='Rscript -e "covr::package_coverage()"'
alias report-coverage='Rscript -e "covr::report()"'

# Spelling
alias spell-r='Rscript -e "spelling::spell_check_package()"'
```

#### Quarto (6 aliases)
```bash
alias preview-quarto='quarto preview'
alias render-quarto='quarto render'
alias check-quarto='quarto check'
alias clean-quarto='rm -rf _site/ *_cache/ *_files/'
alias new-quarto='qnew'
alias work-quarto='qwork'
```

#### Claude Code (15 aliases)
```bash
# Core
alias start-claude='claude'
alias continue-claude='claude -c'
alias resume-claude='claude -r'
alias latest-claude='claude --resume latest'

# Models
alias haiku-claude='claude --model haiku'
alias sonnet-claude='claude --model sonnet'
alias opus-claude='claude --model opus'

# Modes
alias plan-claude='claude --permission-mode plan'
alias auto-claude='claude --permission-mode acceptEdits'
alias yolo-claude='claude --permission-mode bypassPermissions'

# Tools
alias mcp-claude='claude mcp'
alias plugin-claude='claude plugin'

# Context
alias ctx-claude='claude-ctx'
alias init-claude='claude-init'
alias show-claude='claude-show'
```

#### Gemini (6 aliases)
```bash
alias start-gemini='gemini'
alias yolo-gemini='gemini --yolo'
alias sandbox-gemini='gemini --sandbox'
alias resume-gemini='gemini --resume latest'
alias ext-gemini='gemini extensions'
alias mcp-gemini='gemini mcp'
```

#### Git (8 aliases)
```bash
alias status-git='git status -sb'
alias log-git='git log --oneline --graph --decorate --all'
alias log-author-git='git log --oneline --graph --decorate --all --author'
alias undo-git='git reset --soft HEAD~1'
alias diff-git='git diff'
alias commit-git='git commit'
alias add-git='git add'
alias push-git='git push'
```

#### Project Management (15 aliases)
```bash
# Keep existing proj-* pattern (you like it!)
alias proj-status='~/projects/dev-tools/apple-notes-sync/scanner.sh'
alias proj-view='pstatview'
alias proj-count='pstatcount'
alias proj-list='pstatlist'
alias proj-show='pstatshow'
alias proj-type='proj-type'
alias proj-info='proj-info'
alias proj-init='claude-init'

# Dashboard
alias update-dash='dashupdate'
alias open-dash='dashopen'

# Notes
alias sync-notes='pstat && ~/projects/dev-tools/apple-notes-sync/dashboard-applescript.sh'
alias view-notes='nsyncview'
alias clip-notes='nsyncclip'
alias export-notes='nsyncexport'
```

#### File Viewing (10 aliases)
```bash
alias view='bat'
alias view-desc='bat DESCRIPTION'
alias view-news='bat NEWS.md'
alias view-readme='bat README.md'
alias view-qmd='bat --language=markdown'
alias view-r='bat --language=r'
alias view-md='bat --language=markdown'
alias view-json='bat --language=json'
alias view-yaml='bat --language=yaml'
alias view-toml='bat --language=toml'
```

#### Modern CLI (3 aliases)
```bash
alias cat='bat'
alias find='fd'
alias grep='rg'
```

#### Directories (2 aliases)
```bash
alias goto-quarto='cd $QUARTO_DIR'
alias goto-rpkg='cd $R_PACKAGES_DIR'
```

#### Typo Tolerance (20+ aliases)
```bash
# Map to new names
alias rlaod='load-r'
alias rtets='test-r'
alias rdco='doc-r'
# ... (all typo aliases)
```

**Total: ~95 aliases**

---

## 📊 Detailed Comparison

### Tab Completion Behavior

**Plan A (domain-action):**
```bash
r-<TAB>
  r-load, r-test, r-doc, r-check, r-build, r-pkg-info, ...

quarto-<TAB>
  quarto-preview, quarto-render, quarto-check, ...

claude-<TAB>
  claude-start, claude-continue, claude-plan, ...
```
✅ Best for: "I want to work with R, show me all R commands"

**Plan B (short-domain-action):**
```bash
r-<TAB>
  r-load, r-test, r-doc, r-check, r-build, ...

q-<TAB>
  q-preview, q-render, q-check, ...

c-<TAB>
  c-start, c-continue, c-plan, ...
```
✅ Best for: Faster typing, still grouped

**Plan C (action-domain):**
```bash
test-<TAB>
  test-r

preview-<TAB>
  preview-quarto, preview-rpkg

check-<TAB>
  check-r, check-quarto, check-cran-r, ...
```
✅ Best for: "I want to test something, show me all test commands"

---

## 🎯 Detailed Evaluation

### Plan A: Full Domain Names

**Pros:**
- ✅ Maximum clarity (`quarto-preview` is 100% clear)
- ✅ Zero ambiguity
- ✅ Best tab completion by domain
- ✅ Matches existing `proj-` pattern
- ✅ Self-documenting

**Cons:**
- ⚠️ Longer to type (`quarto-` is 7 chars)
- ⚠️ `claude-` and `gemini-` are long prefixes

**Best for:** Maximum clarity, minimal cognitive load

---

### Plan B: Short Domain Names ⭐

**Pros:**
- ✅ Balanced clarity and brevity
- ✅ Still groupable by domain
- ✅ Faster typing (`q-` vs `quarto-`)
- ✅ Matches existing `proj-` pattern
- ✅ Common pattern (npm has `npm-`, git has `git-`)

**Cons:**
- ⚠️ Must remember abbreviations (q=quarto, c=claude, g=gemini)
- ⚠️ Potential conflicts (c- could be claude or code or cd)

**Best for:** Daily heavy use, power users

---

### Plan C: Action-Domain

**Pros:**
- ✅ Reads most naturally (`test-r` = "test R")
- ✅ Action-oriented workflow
- ✅ Can find all "test" commands easily
- ✅ Familiar to English speakers

**Cons:**
- ⚠️ Less grouping by domain
- ⚠️ Tab completion by action, not domain
- ⚠️ Doesn't match existing `proj-` pattern you like

**Best for:** Natural language preference, action-focused thinking

---

## 💡 My Recommendation: **Plan B (Short Domain)** ⭐

### Why Plan B?

**1. Extends Your Existing Pattern**
```bash
# You already have and like:
proj-status
proj-info
proj-type

# Plan B extends this:
r-test
r-doc
q-preview
c-continue
```

**2. Best Balance**
- ✅ Clear enough: `r-test` is obvious
- ✅ Short enough: Easy to type daily
- ✅ Consistent: All follow same pattern

**3. Great Tab Completion**
```bash
r-<TAB>      # See all R commands
q-<TAB>      # See all Quarto commands
c-<TAB>      # See all Claude commands
proj-<TAB>   # See all project commands (existing!)
```

**4. Familiar Abbreviations**
- `r-` = R (obvious)
- `q-` = Quarto (you already use `qp`, `qr`)
- `c-` = Claude (you already use `cc`)
- `g-` = Gemini (you already use `gm`)
- `git-` = Git (standard everywhere)
- `proj-` = Project (already have it!)

**5. Easy Migration**
```bash
# Old → New
rtest  → r-test
rdoc   → r-doc
qp     → q-preview
cc     → c-start
ccc    → c-continue
gm     → g-start
```

---

## 🎯 Alternative: Hybrid Approach

**Keep what you like, change what you don't:**

```bash
# Keep proj-* (you like these)
proj-status, proj-info, proj-type

# Use Plan B for everything else
r-test, r-doc, r-check
q-preview, q-render
c-start, c-continue
g-start, g-yolo

# Keep meaningful full names where clear
claude-yolo   # Not c-yolo (more memorable)
gemini-yolo   # Not g-yolo (more memorable)
git-status    # Not g-status (git is standard)
```

---

## ✅ Recommendation Summary

**Top Choice: Plan B (Short Domain)**
- Extends your existing `proj-` pattern
- Best balance of clarity and brevity
- Great tab completion
- Easy to remember abbreviations

**Second Choice: Plan A (Full Domain)**
- If you want maximum clarity
- If typing speed isn't critical
- If you want zero ambiguity

**Third Choice: Plan C (Action-Domain)**
- If you prefer natural language reading
- If you think action-first

---

## 📋 Next Steps

1. **Choose a plan** (A, B, or C)
2. **I'll create migration script**
3. **Test with your daily workflow**
4. **Iterate based on real use**

Which plan resonates most with your ADHD brain? Plan B is my recommendation, but you know your workflow best!
