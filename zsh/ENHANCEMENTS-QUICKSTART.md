# 🚀 ZSH Enhancements Quick Start Guide

**Installed:** 2025-12-16
**Tools Added:** atuin, direnv, fzf helpers

---

## ✅ What Was Installed

### 1. **atuin** - Supercharged Shell History
- **What:** Context-aware, searchable, syncable history
- **Where:** Replaces default Ctrl+R
- **Why:** "What was that command I used last week in medfit?"

### 2. **direnv** - Auto Environment Loader
- **What:** Automatically loads/unloads environment per directory
- **Where:** Triggers on `cd` into directories with `.envrc`
- **Why:** No more "did I activate renv?" or "is PATH set?"

### 3. **fzf helpers** - 15 New Interactive Functions
- **What:** Fuzzy find for R files, tests, git, projects
- **Where:** Available anywhere in terminal
- **Why:** Faster navigation, better previews, ADHD-friendly

---

## 🎯 First Steps

### 1. Reload Your Shell

```bash
source ~/.config/zsh/.zshrc
```

Or just restart your terminal.

### 2. Import Existing History to Atuin

```bash
atuin import auto
```

This imports your entire `.zsh_history` into atuin's database.

### 3. Try Atuin

```bash
# Press Ctrl+R and start typing
Ctrl+R

# Or search manually
atuin search rtest
atuin search --cwd ~/projects/r-packages
atuin stats
```

### 4. Set Up Direnv for a Project (Optional)

```bash
# Example: Set up medfit package
cd ~/projects/r-packages/active/medfit

# Create .envrc
cat > .envrc << 'EOF'
export R_LIBS_USER=~/R/medfit-libs
export RENV_ACTIVE=TRUE
EOF

# Allow direnv (one-time per project)
direnv allow

# Now whenever you cd into medfit, these vars load automatically!
```

### 5. Try fzf Helpers

```bash
# In any R package directory
re        # Fuzzy find R files
rt        # Run a test file
rv        # Open vignette

# Anywhere
fs        # Edit .STATUS file
fp        # Jump to any project
fr        # Jump to R package

# In git repository
gb        # Checkout branch (with preview)
ga        # Stage files (with preview)
gshow     # Browse commits

# Help
fzf-help  # Show all commands
```

---

## 📖 Common Use Cases

### "I can't remember that R command I used last week"

```bash
# Press Ctrl+R and type fragments you remember
Ctrl+R → rload

# Or search by directory
atuin search --cwd ~/projects/r-packages/active/medfit
```

### "I want to edit an R file but don't remember the path"

```bash
cd ~/projects/r-packages/active/medfit
re        # Shows all R files with preview, fuzzy find
```

### "I want to run a specific test"

```bash
cd ~/projects/r-packages/active/medfit
rt        # Shows all test files, pick one, runs it
```

### "I want to see what changed in git before staging"

```bash
ga        # Shows all changed files with diff preview
          # Tab to select multiple, Enter to stage
```

### "I want to switch git branches"

```bash
gb        # Shows all branches with recent commits
          # Preview shows commit history
```

### "I want to update a project's .STATUS"

```bash
fs        # Shows all .STATUS files from ~/projects
          # Preview shows content, select to edit
```

### "I want my R package to use a custom library path"

```bash
cd ~/projects/r-packages/active/mypackage

cat > .envrc << 'EOF'
export R_LIBS_USER=~/R/mypackage-libs
EOF

direnv allow

# Now every time you cd here, R_LIBS_USER is set!
# When you cd away, it's unset automatically
```

---

## 🎨 Customization

### Atuin Configuration

Edit `~/.config/atuin/config.toml` (created on first run):

```toml
# Show more context
style = "compact"

# Search mode
search_mode = "fuzzy"  # or "fulltext", "prefix"

# Sync (optional - requires atuin account)
sync_address = "https://api.atuin.sh"
```

### Direnv Templates

Create reusable templates:

```bash
# R package template
cat > ~/.config/direnv/rpkg.envrc << 'EOF'
export R_LIBS_USER=~/R/$(basename $PWD)-libs
export RENV_ACTIVE=TRUE
source_up_if_exists
EOF

# Use in projects:
cd ~/projects/r-packages/active/mypackage
echo "source ~/.config/direnv/rpkg.envrc" > .envrc
direnv allow
```

### fzf Preview Customization

The fzf helpers use:
- `bat` for syntax highlighting
- `fd` for finding files
- `--preview-window right:60%` for preview size

Modify in `~/.config/zsh/functions/fzf-helpers.zsh` if needed.

---

## ⚠️ Troubleshooting

### "direnv: error .envrc is blocked"

```bash
direnv allow
```

This is a security feature. You must explicitly allow each `.envrc` file.

### "atuin Ctrl+R not working"

Make sure atuin is initialized:

```bash
atuin init zsh
source ~/.config/zsh/.zshrc
```

### "fzf helpers not found"

Make sure the file is sourced:

```bash
source ~/.config/zsh/functions/fzf-helpers.zsh
```

Or reload your shell:

```bash
source ~/.config/zsh/.zshrc
```

### "Preview window not showing in fzf"

Install dependencies:

```bash
brew install bat fd
```

---

## 📚 Reference

### All New Commands

**Atuin:**
- `Ctrl+R` - Interactive search
- `atuin search <term>` - Search history
- `atuin search --cwd <dir>` - Search in directory
- `atuin stats` - Show statistics

**Direnv:**
- `direnv allow` - Allow .envrc in current directory
- `direnv deny` - Deny .envrc
- `direnv edit` - Edit .envrc (safer than direct edit)

**fzf Helpers - R:**
- `re` - Edit R files
- `rt` - Run test
- `rv` - View vignettes

**fzf Helpers - Projects:**
- `fs` - Edit .STATUS
- `fh` - View PROJECT-HUB
- `fp` - Jump to project
- `fr` - Jump to R package

**fzf Helpers - Git:**
- `gb` - Checkout branch
- `gdf` - Interactive diff
- `gshow` - Browse commits
- `ga` - Stage files
- `gundostage` - Unstage files

**Help:**
- `fzf-help` - Show all fzf commands

---

## 🎯 Next Steps

1. **Use atuin for a week** - Let it learn your patterns
2. **Set up direnv in your top 3 projects** - Start with medfit, probmed, medverse
3. **Try fzf helpers in your daily workflow** - Use `re`, `fs`, `gb` regularly
4. **Customize as needed** - Tweak fzf preview sizes, atuin settings, etc.

---

## 📖 Full Documentation

- **Main Reference:** `~/.config/zsh/ALIAS-REFERENCE-CARD.md`
- **Navigation Guide:** `~/.config/zsh/help/navigation.md`
- **Quick Reference:** `~/.config/zsh/help/quick-reference.md`
- **This Guide:** `~/.config/zsh/ENHANCEMENTS-QUICKSTART.md`

---

**Installed:** 2025-12-16
**Status:** ✅ Ready to use
**Support:** Run `fzf-help` for quick reference
