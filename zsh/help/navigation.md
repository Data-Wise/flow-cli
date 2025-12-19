# Navigation & Bookmarks - Detailed Guide

**The @ Bookmark System - Your Path Memory Solution**

---

## 🎯 THE PROBLEM YOU HAD

❌ Can't remember project paths  
❌ Can't remember project names  
❌ Hard to list subdirectories  
❌ Especially painful with zsh config

**SOLUTION: @ Bookmarks**

---

## 📚 ALL BOOKMARKS (15 total)

### Main Areas (5)
```bash
@proj          # ~/projects
               # Your central workspace
               
@rpkg          # ~/projects/r-packages/active
               # All active R packages
               
@dev           # ~/projects/dev-tools
               # Development tools
               
@zsh           # ~/.config/zsh
               # Zsh configuration (your pain point!)
               
@teaching      # ~/Dropbox/Teaching/stat-440-prac
               # Current teaching materials
```

### R Packages (3)
```bash
@medfit        # ~/projects/r-packages/active/medfit
               # Foundation package (P0)
               
@probmed       # ~/projects/r-packages/active/probmed
               # P_med effect sizes (P1)
               
@medverse      # ~/projects/r-packages/active/mediationverse
               # Meta-package hub (P3)
```

### Dev Tools (2)
```bash
@datawise      # ~/projects/dev-tools/data-wise
               # Ecosystem hub

@emacs         # ~/projects/dev-tools/spacemacs-rstats
               # Spacemacs R development setup
```

### Planning (1)
```bash
@planning      # ~/projects/dev-tools/data-wise/planning
               # NOW.md, ROADMAP.md, etc.
```

---

## 💡 HOW TO USE

### Autocomplete Discovery
```bash
# Type @ and press Tab
$ @<Tab>

# Shows all bookmarks:
@datawise  @dev  @emacs  @medfit  @medverse
@planning  @probmed  @proj  @rpkg  @teaching  @zsh
```

### Quick Jump
```bash
# Anywhere in shell:
$ @medfit
# Instantly at: ~/projects/r-packages/active/medfit

$ @zsh
# Instantly at: ~/.config/zsh
```

### Chain Commands
```bash
# Jump and check status
$ @medfit && status

# Jump and edit
$ @zsh && zshrc

# Jump and list
$ @dev && lsdev
```

---

## 📋 LISTING HELPERS

### Project Listings
```bash
lsp            # List ~/projects
               # Shows: dev-tools, r-packages, research, etc.

lsrpkg         # List ~/projects/r-packages/active
               # Shows: medfit, probmed, mediationverse, etc.

lsdev          # List ~/projects/dev-tools
               # Shows: data-wise, spacemacs-rstats, etc.
```

**When to use:**
- "What projects do I have?"
- "What's in r-packages?"
- "Refresh my memory"

### Tree Views (Structure)
```bash
tree1          # Show 1 level deep
               # Quick shallow view

tree2          # Show 2 levels deep  
               # Standard detail

tree3          # Show 3 levels deep
               # Deep dive

treep          # tree -L 2 ~/projects
               # Projects overview
```

**When to use:**
- "What's the structure?"
- "What directories are here?"
- "Show me the layout"

### Example Tree Output
```bash
$ treep

~/projects
├── dev-tools
│   ├── data-wise
│   ├── spacemacs-rstats
│   └── zsh-claude-workflow
├── r-packages
│   ├── active
│   └── stable
└── research
    └── mediation-planning
```

---

## 🔍 FIND HELPERS

### Find R Files
```bash
findr          # find . -name "*.R" -type f
               # Finds all R scripts in current dir

# Example:
$ @medfit
$ findr
# Shows: R/fit.R, R/plot.R, etc.
```

### Find Status Files
```bash
findstatus     # find . -name ".STATUS" -type f
               # Finds all .STATUS files

# Example:
$ @proj
$ findstatus
# Shows all projects with .STATUS
```

---

## 🔄 COMBINED WITH ZOXIDE

**You have TWO navigation systems:**

### @ Bookmarks (Explicit)
- Fixed paths
- Always work
- Clear destination
- Good for main areas

### Zoxide (Frecency-based)
- Learns from history (frequency + recency)
- Shorter to type
- 10-40x faster than old z plugin (Rust-based)
- Interactive mode with fzf (`zi`)
- Good for frequent dirs

### When to Use Each

**Use @ bookmarks when:**
- Going to main area (`@proj`, `@rpkg`)
- Path you don't visit often
- Want explicit clarity
- Teaching someone your setup

**Use zoxide when:**
- Visited recently
- Type less (`z med` → medfit)
- Muscle memory kicks in
- Want interactive selection (`zi`)

### Zoxide Commands

```bash
z <dir>          # Jump to directory (frecency-based)
zi <dir>         # Interactive selection with fzf
za <dir>         # Manually add directory to database
z -              # Jump to previous directory
zoxide query <term>  # Query the database
```

**Examples:**
```bash
# @ Bookmark (explicit)
$ @medfit
# Goes to medfit package

# Zoxide (frecency-based)
$ z med
# Jumps to most frequent/recent match (likely medfit)

# Interactive selection
$ zi med
# Shows fzf menu of all matches to choose from

# Best practice: Use @ for main areas, zoxide for deep navigation
$ @rpkg          # Jump to r-packages
$ z robust       # Then zoxide to medrobust
```

---

## 💡 WORKFLOWS

### Morning Start
```bash
# Check what needs attention
$ @proj
$ lsp
$ allstatus
```

### Working on Package
```bash
# Quick jump
$ @medfit

# Check status
$ status

# Work...

# Update
$ e.status
```

### Navigate Zsh Config
```bash
# Your pain point - SOLVED!
$ @zsh          # Jump there
$ lszsh         # See files
$ zshrc         # Edit main config
# or
$ ezsh          # Edit in Spacemacs
```

### Explore Projects
```bash
$ @proj
$ treep         # See structure
$ lsp           # See details
$ @medfit       # Pick one
```

---

## 🎯 ADDING MORE BOOKMARKS

**Don't add too many!** Keep it manageable.

**Good candidates:**
- Frequently visited (daily/weekly)
- Hard to remember path
- Deep nested location

**Bad candidates:**
- Rarely visited
- Easy to remember
- One level deep (use cd)

**To add:**
Edit ~/.config/zsh/.zshrc and add:
```bash
alias @myproject='cd ~/path/to/project'
```

Then:
```bash
$ reload
```

---

## 📊 BOOKMARK OVERVIEW

| Bookmark | Path | Use Frequency |
|----------|------|---------------|
| @proj | ~/projects | Daily |
| @rpkg | ~/projects/r-packages/active | Daily |
| @medfit | .../medfit | Daily |
| @zsh | ~/.config/zsh | Weekly |
| @teaching | ~/Dropbox/Teaching/... | Weekly |
| @dev | ~/projects/dev-tools | Weekly |
| @probmed | .../probmed | As needed |
| @datawise | .../data-wise | As needed |
| @planning | .../planning | As needed |

---

## 🚀 QUICK REFERENCE

**Most used:**
```bash
@proj          # Projects home
@medfit        # Active work
@zsh           # Config
lsp            # List projects
treep          # Structure
```

**Remember:**
- `@` + Tab shows all
- Use for main areas
- Combine with z for deep nav
- Add sparingly

---

**See also:** help, helpspc, helpr
