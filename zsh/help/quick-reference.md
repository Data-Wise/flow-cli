# Zsh Quick Reference Card

**Version:** 2.0  
**Updated:** 2025-12-12  
**Total Aliases:** ~90

---

## 🚀 MOST USED (Top 20)

```bash
# Navigation (your pain point - SOLVED!)
@proj          # Jump to ~/projects
@medfit        # Jump to medfit package
@zsh           # Jump to zsh config
lsp            # List projects

# Project Management
status         # View .STATUS
hub            # View PROJECT-HUB.md
projects       # View all projects
e.status       # Edit .STATUS

# Spacemacs
e              # Launch Spacemacs
econfig        # Edit .spacemacs
estat          # Edit .STATUS in Spacemacs

# R Development
rload          # Load package
rcheck         # Check package
rtest          # Run tests

# Git
s              # git status
add            # git add
commit         # git commit -m

# Zsh
reload         # Reload config
zshrc          # Edit .zshrc
```

---

## 📂 NAVIGATION & BOOKMARKS (15)

### Main Area Bookmarks

```bash
@proj          # ~/projects
@rpkg          # ~/projects/r-packages/active
@dev           # ~/projects/dev-tools
@zsh           # ~/.config/zsh
@teaching      # ~/Dropbox/Teaching/stat-440-prac
```

### Project Bookmarks

```bash
@medfit        # ~/projects/r-packages/active/medfit
@probmed       # ~/projects/r-packages/active/probmed
@medverse      # ~/projects/r-packages/active/mediationverse
@datawise      # ~/projects/dev-tools/data-wise
@emacs         # ~/projects/dev-tools/spacemacs-rstats
@planning      # ~/projects/dev-tools/data-wise/planning
```

### Listing Helpers

```bash
lsp            # ls -lh ~/projects
lsrpkg         # ls -lh ~/projects/r-packages/active
lsdev          # ls -lh ~/projects/dev-tools
```

### Tree Views

```bash
tree1          # tree -L 1
tree2          # tree -L 2
tree3          # tree -L 3
treep          # tree -L 2 ~/projects
```

### Find Helpers

```bash
findr          # find . -name "*.R" -type f
findstatus     # find . -name ".STATUS" -type f
```

---

## 📝 SPACEMACS (10)

### Launch & Modes

```bash
e              # emacsclient -c -a ""
et             # emacsclient -t (terminal)
ec             # emacsclient -c (GUI)
edir           # Open current directory
```

### Config & Server

```bash
econfig        # Edit ~/.spacemacs
ereload        # Reload Spacemacs config
estart         # Start Emacs daemon
estop          # Stop Emacs daemon
```

### Quick Edits

```bash
ezsh           # Edit .zshrc in Spacemacs
estat          # Edit .STATUS in Spacemacs
ehub           # Edit PROJECT-HUB.md in Spacemacs
```

---

## 📊 PROJECT MANAGEMENT (11)

### View

```bash
status         # View .STATUS
hub            # View PROJECT-HUB.md
projects       # View ~/projects/PROJECTS.md
all            # View both status + hub
```

### Edit

```bash
e.status       # Edit .STATUS
e.hub          # Edit PROJECT-HUB.md
e.projects     # Edit PROJECTS.md
```

### Create

```bash
new.status     # Create .STATUS from template
new.hub        # Create PROJECT-HUB.md from template
```

### Utility

```bash
allstatus      # Find and view all .STATUS files
customize      # View customization tracking
```

---

## 📦 R PACKAGE DEVELOPMENT (12)

### Development Cycle

```bash
rload          # devtools::load_all()
rcheck         # devtools::check()
rtest          # devtools::test()
rdoc           # devtools::document()
rinstall       # devtools::install()
```

### Build & Release

```bash
rbuild         # devtools::build()
rcran          # devtools::check(--as-cran)
rsite          # pkgdown::build_site()
```

### Utilities

```bash
rcov           # covr::package_coverage()
rbump          # usethis::use_version("patch")
rclean         # rm -rf .Rhistory .RData .Rproj.user
rtree          # tree -L 3 (clean)
```

---

## 🤖 AI ASSISTANTS (5)

### Claude

```bash
c              # Interactive
cf             # Safe mode (plan first)
cy             # YOLO mode
```

### Gemini

```bash
g              # Interactive
gy             # YOLO mode
```

**Philosophy:** Use interactively, not pre-defined prompts

---

## 🔌 MCP SERVERS (8)

**Pattern:** `mcp <action> [args]`

### Core Actions

```bash
mcp            # List all servers (default)
mcp cd NAME    # Navigate to server
mcp test NAME  # Test server runs
mcp edit NAME  # Edit in $EDITOR
mcp pick       # Interactive picker (fzf)
```

### Info & Status

```bash
mcp status     # Config status
mcp readme     # View README
mcp help       # Show help
```

### Short Forms

```bash
mcp l          # list
mcp g          # cd (goto)
mcp t          # test
mcp e          # edit
mcp p          # pick
mcp s          # status
mcp r          # readme
mcp h          # help
```

### Alias

```bash
mcpp           # mcp pick (interactive)
```

**Servers:** `~/projects/dev-tools/mcp-servers/`
**Symlinks:** `~/mcp-servers/<name>`

---

## 🔧 GIT (7)

**Note:** Git plugin disabled (was 226 aliases!)

```bash
s              # git status -sb
log            # git log --oneline --graph
undo           # git reset --soft HEAD~1
add            # git add
commit         # git commit -m
push           # git push
pull           # git pull
```

---

## ⚙️ ZSH CONFIG (8)

### Navigate

```bash
@zsh           # cd ~/.config/zsh
@zshconfig     # cd ~/.config/zsh
```

### Edit

```bash
zshrc          # Edit .zshrc
zshplugins     # Edit .zsh_plugins.txt
zshenv         # Edit .zshenv
zshp10k        # Edit .p10k.zsh
```

### View

```bash
catzsh         # bat ~/.config/zsh/.zshrc
catplugins     # bat ~/.config/zsh/.zsh_plugins.txt
```

### Utility

```bash
reload         # source ~/.config/zsh/.zshrc
lszsh          # ls -lah ~/.config/zsh
```

---

## 👀 FILE OPERATIONS (4)

```bash
cat            # bat (better cat)
peek           # bat (semantic)
find           # fd (better find)
grep           # rg (better grep)
```

---

## 📝 QUARTO (3)

```bash
qp             # quarto preview
qr             # quarto render
qclean         # rm -rf _site/ *_cache/ *_files/
```

---

## 🛠️ UTILITIES (5)

```bash
e              # ${EDITOR:-vim}
x              # exit
h              # history | tail -20
reload         # source ~/.config/zsh/.zshrc
R              # radian
```

---

## 📚 HELP SYSTEM

```bash
help           # View this quick reference
zhelp          # Same as help
helpnav        # Navigation help (detailed)
helpspc        # Spacemacs help (detailed)
helpr          # R package help (detailed)
helpall        # View all help files
```

---

## 🎯 COMMON WORKFLOWS

### Start New R Package Work

```bash
@medfit        # Jump to package
status         # Check what's next
rload          # Load package
# ... do work ...
e.status       # Update status
```

### Edit Zsh Config

```bash
@zsh           # Jump to config
zshrc          # Edit in vim/editor
# Or
ezsh           # Edit in Spacemacs
reload         # After saving
```

### Find Something in Projects

```bash
@proj          # Jump to projects
treep          # See structure
# Or
lsp            # List all projects
@medfit        # Jump to specific
```

### Quick Status Check

```bash
projects       # See all projects
allstatus      # See all .STATUS files
```

---

## 💡 TIPS

**Navigation:**

- Type `@` + Tab to see all bookmarks
- Use `z medfit` for frecency-based jumping (zoxide: frequency + recency)
- Use `zi` for interactive fzf selection when unsure
- Use `lsp`, `lsrpkg` to remember what exists

**Spacemacs:**

- `e` launches or connects to daemon
- `estart` once per session
- `estat` fastest way to update status

**R Packages:**

- Common cycle: `rload` → `rcheck` → `rtest`
- `rbump` defaults to patch version
- `rtree` shows clean project structure

**Git:**

- `s` is super fast for status
- `undo` keeps changes (soft reset)
- Use full `git` for advanced operations

---

## 🔍 FINDING ALIASES

```bash
# List all aliases
alias

# Find alias for command
which <command>

# Search aliases
alias | grep <term>

# Homebrew aliases (from plugin)
alias | grep "^b"
```

---

## 📊 STATISTICS

**Total aliases:** ~98

- Custom core: 68
- Homebrew plugin: ~30

**Breakdown:**

- Navigation: 15
- Spacemacs: 10
- Project Mgmt: 11
- R Packages: 12
- MCP Servers: 8
- Zsh Config: 8
- AI: 5
- Git: 7
- File Ops: 4
- Quarto: 3
- Utilities: 5

**Reduction:** From 387 → 98 (75% fewer)

---

## 📖 MORE HELP

**Detailed guides:**

```bash
helpnav        # Navigation in depth
helpspc        # Spacemacs in depth
helpr          # R packages in depth
helpgit        # Git workflows
```

**Files:**

- ~/.config/zsh/help/quick-reference.md (this file)
- ~/.config/zsh/help/navigation.md
- ~/.config/zsh/help/spacemacs.md
- ~/.config/zsh/help/r-packages.md

---

**Version:** 2.2 | **Last Updated:** 2025-12-19 | **Change:** Added MCP Server dispatcher (8 commands)
