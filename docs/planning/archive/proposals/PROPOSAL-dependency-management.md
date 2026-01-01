# Dependency Management for flow-cli

**Generated:** 2025-12-26
**Context:** Should flow-cli manage ZSH plugins (antidote) and CLI tools (Homebrew)?

## Overview

Flow-cli currently has scattered "install with brew install X" messages but no unified dependency management. This proposal explores whether to add structured dependency management.

---

## Current State Analysis

### What flow-cli does now:

- Ad-hoc error messages: "fzf not installed. Install: brew install fzf"
- No dependency checking on startup
- No unified list of required/optional tools
- Antidote plugins managed separately in `~/.config/zsh/.zsh_plugins.txt`

### Dependencies referenced in flow-cli:

| Tool   | Type     | Required? | Used By              |
| ------ | -------- | --------- | -------------------- |
| fzf    | Homebrew | Optional  | pick, dash, tui      |
| atlas  | npm      | Optional  | session tracking     |
| eza    | Homebrew | Optional  | ls aliases in .zshrc |
| bat    | Homebrew | Optional  | cat alias in .zshrc  |
| zoxide | Homebrew | Optional  | z navigation         |
| radian | pip      | Optional  | R console            |

### Antidote plugins (19 active):

- powerlevel10k, autosuggestions, syntax-highlighting, completions
- OMZ: git, fzf, brew, clipboard tools, etc.

---

## Options

### Option A: Keep Separate (Status Quo)

**Effort:** ⚡ None
**Philosophy:** "Unix way" - each tool manages its own domain

```
Homebrew → CLI tools (eza, bat, fzf, fd, rg)
Antidote → ZSH plugins (p10k, autosuggestions)
flow-cli → Workflow commands only
```

**Pros:**

- No added complexity to flow-cli
- Clear separation of concerns
- Users already know brew/antidote

**Cons:**

- No unified "is my setup complete?" check
- New users must manually discover dependencies
- Scattered install instructions

---

### Option B: Add `flow doctor` Command

**Effort:** 🔧 Medium (2-3 hours)
**Philosophy:** Diagnose but don't manage

Add a single command that checks everything:

```bash
flow doctor
```

Output:

```
╭─────────────────────────────────────────────╮
│  🩺 flow-cli Health Check                   │
╰─────────────────────────────────────────────╯

✅ REQUIRED
  ✓ zsh 5.9
  ✓ git 2.43.0

⚡ RECOMMENDED (enhances experience)
  ✓ fzf 0.45.0      → pick, dash interactive
  ✗ eza             → brew install eza
  ✓ bat 0.24.0      → syntax-highlighted cat
  ✓ zoxide 0.9.2    → smart cd

📦 OPTIONAL
  ✗ atlas           → npm i -g @data-wise/atlas
  ✓ radian 0.6.6    → enhanced R console

🔌 ZSH PLUGINS (via antidote)
  ✓ powerlevel10k
  ✓ zsh-autosuggestions
  ✓ zsh-syntax-highlighting

Run: flow doctor --fix  # Show install commands
```

**Pros:**

- Single command to check setup
- Educates users about available enhancements
- Non-invasive (doesn't auto-install)
- ADHD-friendly: clear visual status

**Cons:**

- Adds maintenance burden (version checks)
- Still requires manual installs

---

### Option C: Add `flow setup` Command

**Effort:** 🏗️ Large (4-6 hours)
**Philosophy:** Guided setup wizard

```bash
flow setup
```

Interactive wizard:

```
╭─────────────────────────────────────────────╮
│  🚀 flow-cli Setup Wizard                   │
╰─────────────────────────────────────────────╯

This will help you install recommended tools.

[1/3] CLI Tools (via Homebrew)
  ☑ fzf      - Fuzzy finder (required for pick)
  ☑ eza      - Modern ls with icons
  ☑ bat      - Syntax-highlighted cat
  ☑ zoxide   - Smart directory jumping
  ☐ fd       - Fast find replacement
  ☐ ripgrep  - Fast grep replacement

  Install selected? [Y/n]

[2/3] ZSH Plugins (via Antidote)
  Your plugins file: ~/.config/zsh/.zsh_plugins.txt
  ✓ All recommended plugins already installed

[3/3] Optional Integrations
  ☐ atlas    - Session tracking (npm)
  ☐ radian   - Enhanced R console (pip)

  Install selected? [Y/n]
```

**Pros:**

- Best onboarding experience
- Users can choose what to install
- Documents the "ideal" setup

**Cons:**

- Significant implementation effort
- Must handle Homebrew/npm/pip failures
- May feel "opinionated" to some users

---

### Option D: Brewfile + Antidote Bundle

**Effort:** 🔧 Medium (1-2 hours)
**Philosophy:** Declarative config files

Add config files that users can use with existing tools:

```
flow-cli/
├── setup/
│   ├── Brewfile              # Homebrew bundle
│   ├── zsh_plugins.txt       # Antidote template
│   └── README.md             # Setup instructions
```

**Brewfile:**

```ruby
# flow-cli recommended tools
brew "fzf"
brew "eza"
brew "bat"
brew "zoxide"
brew "fd"
brew "ripgrep"

# Optional
# brew "gh"  # GitHub CLI
```

Usage:

```bash
brew bundle --file=~/projects/dev-tools/flow-cli/setup/Brewfile
```

**Pros:**

- Uses native Homebrew bundle
- Declarative and reproducible
- Easy to customize
- No custom code needed

**Cons:**

- Requires users to know `brew bundle`
- Antidote plugins harder to bundle
- Two separate files to manage

---

## Recommendation

### 🏆 Option B + D Combined (Best Balance)

**Phase 1: Quick Win (30 min)**

- Add `setup/Brewfile` with recommended tools
- Add `setup/README.md` with setup instructions
- Document in main README

**Phase 2: Doctor Command (2 hours)**

- Add `flow doctor` to check setup status
- Show what's installed vs missing
- Provide copy-paste install commands

**Why this approach:**

1. **Respects existing tools** - Uses brew bundle, not reinventing
2. **ADHD-friendly** - `flow doctor` gives clear visual feedback
3. **Progressive enhancement** - Works without optional tools
4. **Low maintenance** - Brewfile is declarative
5. **Onboarding path** - New users run `brew bundle` then `flow doctor`

---

## Implementation Plan

### Quick Wins (< 30 min each)

1. ⚡ Create `setup/Brewfile` with tool list
2. ⚡ Create `setup/README.md` with instructions
3. ⚡ Update main README with setup section

### Medium Effort (1-2 hours)

4. 🔧 Implement `flow doctor` command
5. 🔧 Add `--fix` flag to show install commands
6. 🔧 Add to `dash` as health indicator

### Future (Optional)

7. 🏗️ Interactive `flow setup` wizard
8. 🏗️ Antidote plugin recommendations

---

## File Structure

```
flow-cli/
├── setup/
│   ├── Brewfile              # brew bundle --file=setup/Brewfile
│   ├── Brewfile.optional     # Additional nice-to-haves
│   └── README.md             # Setup guide
├── commands/
│   └── doctor.zsh            # flow doctor command
└── lib/
    └── deps.zsh              # Dependency checking utilities
```

---

## Brewfile Draft

```ruby
# flow-cli/setup/Brewfile
# Install: brew bundle --file=path/to/Brewfile

# Required for full functionality
brew "fzf"        # Fuzzy finder - pick, dash interactive mode

# Highly recommended (modern CLI tools)
brew "eza"        # Modern ls with icons & git status
brew "bat"        # Syntax-highlighted cat
brew "zoxide"     # Smart cd (replaces z)

# Nice to have
brew "fd"         # Fast find replacement
brew "ripgrep"    # Fast grep replacement
brew "dust"       # Disk usage analyzer
brew "duf"        # Disk free viewer
brew "btop"       # System monitor

# Development
brew "gh"         # GitHub CLI
```

---

## Next Steps

**Recommended Path:**
→ Start with Quick Win #1: Create Brewfile

**Questions to decide:**

1. Should antidote plugins be managed by flow-cli at all?
   - Recommendation: No - keep in user's `.zsh_plugins.txt`
2. Should `flow doctor` auto-install anything?
   - Recommendation: No - show commands, let user run
3. Where should Brewfile live?
   - Recommendation: `setup/` subdirectory

---

## Decision Matrix

| Approach        | Effort | User Experience  | Maintenance | Recommendation |
| --------------- | ------ | ---------------- | ----------- | -------------- |
| A: Status Quo   | None   | Poor onboarding  | None        | ❌             |
| B: Doctor Only  | Medium | Good diagnostics | Low         | ✅             |
| C: Setup Wizard | High   | Best onboarding  | High        | ⚠️ Future      |
| D: Brewfile     | Low    | Good if known    | Very Low    | ✅             |
| **B + D**       | Medium | Great            | Low         | 🏆 Winner      |
