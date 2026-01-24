# SPEC: v4.9.0 - Installation & Onboarding

**Status:** Planning
**Created:** 2026-01-05
**Target:** v4.9.0
**Estimated Effort:** 2-3 days
**Priority:** High ⚡

---

## Overview

Transform flow-cli installation from "requires ZSH plugin knowledge" to "works in 30 seconds" with zero-friction onboarding.

### Current State (v4.8.1)

**Homebrew (Primary):**

```bash
brew tap data-wise/tap
brew install flow-cli
# Works immediately, but users don't know what commands exist
```

**Plugin Managers:**

```bash
# Requires understanding of ZSH plugin managers
antidote install data-wise/flow-cli
```

**Pain Points:**
- ❌ No guided onboarding after install
- ❌ Users don't know where to start
- ❌ No verification that everything works
- ❌ Missing dependencies not auto-detected
- ❌ No first-run experience

### Target State (v4.9.0)

**One-Liner Install:**

```bash
curl -fsSL https://get.flow-cli.dev/install.sh | bash
# Auto-detects: Homebrew or plugin manager
# Runs: Health check + first-run wizard
# Result: User knows exactly what to do next
```

**First Run:**

```bash
$ work my-project
👋 Welcome to flow-cli! Let's get you set up.

✓ ZSH detected
✓ Git installed
⚠ fzf not found (recommended for project picker)

Install recommended tools? [Y/n] y
✓ fzf installed
✓ bat installed

Quick tutorial? [Y/n] y
→ Running: work my-project
→ Log wins with: win "text"
→ End session: finish

🎉 You're all set! Type 'flow help' anytime.
```

---

## Goals

1. **Zero-Friction Install** - One command, works everywhere
2. **Auto-Discovery** - Detect what's missing, offer to fix it
3. **Guided Onboarding** - First-run wizard with 30-second tutorial
4. **Smart Defaults** - Works out-of-box, customize later
5. **Progressive Disclosure** - Show basics first, reveal advanced features gradually

---

## Components

### 1. Install Script (`install.sh`)

**Location:** Root of repository + hosted at `get.flow-cli.dev`
**Purpose:** One-liner installation for all environments

**Features:**
- ✅ Auto-detect OS (macOS, Linux, WSL)
- ✅ Auto-detect install method preference
  - Homebrew (if installed) → brew install
  - Plugin manager (antidote, zinit, omz) → plugin install
  - Manual fallback → git clone + source
- ✅ Idempotent (safe to run multiple times)
- ✅ Version pinning support (`FLOW_VERSION=v4.9.0`)
- ✅ Dry-run mode (`--dry-run`)
- ✅ Post-install verification
- ✅ Trigger first-run wizard

**Architecture:**

```bash
install.sh
├── detect_os()           # macOS, Linux, WSL
├── detect_shell()        # zsh, bash (error if not zsh)
├── detect_homebrew()     # Check if brew available
├── detect_plugin_mgr()   # antidote → zinit → omz → manual
├── install_homebrew()    # brew tap + brew install
├── install_plugin()      # Plugin manager specific
├── install_manual()      # git clone + add to .zshrc
├── verify_install()      # flow --version works
└── run_first_setup()     # Trigger flow setup --first-run
```

**Error Handling:**
- Clear error messages with actionable fixes
- Rollback on failure (remove what was added)
- Support contact info on critical errors

**Testing:**
- Docker containers (Ubuntu 22.04, 24.04, Debian, Alpine)
- macOS (Intel + Apple Silicon)
- CI integration

---

### 2. Enhanced `flow doctor --fix`

**Current State (v4.8.1):**

```bash
$ flow doctor
✓ work command found
✓ dash command found
⚠ fzf not found

$ flow doctor --fix
# Just shows what's missing, doesn't actually fix
```

**Target State (v4.9.0):**

```bash
$ flow doctor --fix
🔍 Checking flow-cli health...

Core Commands: ✓ All working
Dispatchers: ✓ All 8 loaded

Recommended Tools:
  ⚠ fzf not found
  ⚠ bat not found
  ✓ git installed

Install missing tools? [Y/n] y

Installing via Homebrew...
  ✓ fzf installed
  ✓ bat installed

🎉 All dependencies satisfied!

Optional enhancements available:
  - eza (modern ls) [y/N]
  - zoxide (smart cd) [y/N]
  - delta (better git diffs) [y/N]

Install optional tools? [y/N] n

✓ Health check complete!
```

**Features:**
- ✅ Interactive mode (ask before installing)
- ✅ Batch mode (`-y` flag, install all)
- ✅ Selective install (prompt for each category)
- ✅ Detection of package manager (brew, apt, pacman, etc.)
- ✅ Progress indicators for downloads
- ✅ Verification after install
- ✅ Undo support (remove what was installed)

**Categories:**
1. **Core** - Required for basic functionality
2. **Recommended** - Significantly improves UX (fzf, bat)
3. **Optional** - Nice-to-have enhancements (eza, zoxide, delta)

**Implementation:**

```zsh
# In commands/doctor.zsh
_flow_doctor_fix() {
    local interactive=true
    local category="all"  # core, recommended, optional, all

    case "$1" in
        -y|--yes) interactive=false ;;
        --core) category="core" ;;
        --recommended) category="recommended" ;;
        --optional) category="optional" ;;
    esac

    _doctor_check_and_install "core" "$interactive"
    [[ "$category" != "core" ]] && _doctor_check_and_install "recommended" "$interactive"
    [[ "$category" == "all" || "$category" == "optional" ]] && _doctor_check_and_install "optional" "$interactive"
}
```

---

### 3. First-Run Wizard (`flow setup`)

**Trigger Points:**
1. After fresh install (via install.sh)
2. Manual: `flow setup`
3. First time running `work` command
4. Detection: `~/.config/flow-cli/.setup_complete` doesn't exist

**Wizard Flow:**

```
┌────────────────────────────────────────────────┐
│  👋 Welcome to flow-cli!                       │
│                                                │
│  Let's get you set up in 30 seconds.          │
└────────────────────────────────────────────────┘

Step 1/4: Verify Installation
  ✓ flow-cli installed
  ✓ ZSH detected
  ✓ Git configured

Step 2/4: Install Recommended Tools
  ⚠ fzf not found (enables project picker)
  ⚠ bat not found (syntax highlighting)

  Install now? [Y/n] y
  ✓ Installing fzf... done
  ✓ Installing bat... done

Step 3/4: Configure Projects
  Where do you keep your projects?
  [Default: ~/projects]
  → ~/projects

  ✓ Found 12 projects in ~/projects

Step 4/4: Quick Tutorial
  Let's try the core workflow:

  1. Start working:
     $ work my-project

  2. Log accomplishments:
     $ win "Fixed the bug"
     $ win "Added tests"

  3. See your progress:
     $ yay

  4. End session:
     $ finish

  Try it now? [Y/n] y

  [Interactive demo with explanations]

┌────────────────────────────────────────────────┐
│  🎉 You're all set!                            │
│                                                │
│  Quick Reference:                              │
│    work          Start working                 │
│    dash          Project dashboard             │
│    pick          Choose project                │
│    win <text>    Log accomplishment            │
│    flow help     Show all commands             │
│                                                │
│  Documentation: https://flow-cli.dev           │
└────────────────────────────────────────────────┘

Setup complete! ✓
```

**Features:**
- ✅ Skippable (Ctrl-C anytime, `--skip` flag)
- ✅ Resume on interrupt (save progress)
- ✅ Non-intrusive (only runs once)
- ✅ Quick mode (`--quick` for minimal setup)
- ✅ Unattended mode (`--unattended` for CI/scripts)

**Implementation:**

```zsh
# commands/setup.zsh
flow_setup() {
    local mode="interactive"  # interactive, quick, unattended
    local force=false

    # Check if already setup
    if [[ -f ~/.config/flow-cli/.setup_complete ]] && ! $force; then
        echo "✓ Already setup. Use --force to run again."
        return 0
    fi

    case "$1" in
        --first-run) mode="interactive" ;;
        --quick) mode="quick" ;;
        --unattended) mode="unattended" ;;
        --force) force=true ;;
    esac

    _setup_welcome
    _setup_verify_install
    _setup_install_tools "$mode"
    _setup_configure_projects "$mode"
    _setup_tutorial "$mode"
    _setup_complete
}
```

---

### 4. Auto-Discovery & Smart Defaults

**Project Root Detection:**

```bash
# Try in order:
1. $FLOW_PROJECTS_ROOT (if set)
2. ~/projects (if exists)
3. ~/dev (if exists)
4. ~/code (if exists)
5. ~ (fallback, show all subdirectories)
```

**Shell Integration:**

```bash
# Auto-detect shell config file
1. ~/.zshrc (most common)
2. ~/.config/zsh/.zshrc (XDG)
3. $ZDOTDIR/.zshrc (if ZDOTDIR set)
```

**Package Manager Detection:**

```bash
# Order of preference
1. brew (macOS/Linux)
2. apt-get (Debian/Ubuntu)
3. pacman (Arch)
4. dnf (Fedora)
5. yum (RHEL/CentOS)
```

---

## Implementation Plan

### Phase 1: Install Script (Day 1, ~6 hours)

**Tasks:**
- [ ] Create `install.sh` in repository root
- [ ] Implement OS/shell detection
- [ ] Implement install method detection
- [ ] Add Homebrew install path
- [ ] Add plugin manager install paths
- [ ] Add manual install fallback
- [ ] Add verification step
- [ ] Add rollback on failure
- [ ] Test on Docker containers
- [ ] Test on macOS (Intel + Apple Silicon)

**Deliverable:** Working `install.sh` that works on all platforms

---

### Phase 2: Enhanced `flow doctor --fix` (Day 1-2, ~4 hours)

**Tasks:**
- [ ] Extend `commands/doctor.zsh`
- [ ] Add interactive install mode
- [ ] Add batch mode (`-y` flag)
- [ ] Implement package manager detection
- [ ] Add progress indicators
- [ ] Add verification after install
- [ ] Categorize tools (core/recommended/optional)
- [ ] Add undo support
- [ ] Write tests
- [ ] Update documentation

**Deliverable:** `flow doctor --fix` that actually installs missing tools

---

### Phase 3: First-Run Wizard (Day 2-3, ~8 hours)

**Tasks:**
- [ ] Create `commands/setup.zsh`
- [ ] Implement wizard flow
- [ ] Add step 1: Verify install
- [ ] Add step 2: Install tools
- [ ] Add step 3: Configure projects
- [ ] Add step 4: Tutorial
- [ ] Add progress saving (resume on interrupt)
- [ ] Add `.setup_complete` marker
- [ ] Integrate with `install.sh`
- [ ] Integrate with first `work` command
- [ ] Add `--quick` mode
- [ ] Add `--unattended` mode
- [ ] Write tests
- [ ] Update documentation

**Deliverable:** Complete first-run wizard experience

---

### Phase 4: Testing & Polish (Day 3, ~4 hours)

**Tasks:**
- [ ] E2E test: Fresh install → wizard → first command
- [ ] Test all OS combinations
- [ ] Test all install methods
- [ ] Test interruption & resume
- [ ] Test idempotency (run install.sh multiple times)
- [ ] Test unattended mode for CI
- [ ] Performance testing (install speed)
- [ ] Update all documentation
- [ ] Create installation video/GIF
- [ ] Update README with new install method

**Deliverable:** Polished, tested, documented v4.9.0 ready for release

---

## Success Metrics

### Quantitative

- **Install time:** < 60 seconds (fresh install to first command)
- **Setup completion rate:** > 80% complete wizard
- **Error rate:** < 5% install failures
- **Time to first win:** < 2 minutes from install

### Qualitative

- **User feedback:** "It just worked!"
- **Support requests:** Reduction in install-related issues
- **Adoption:** More users trying flow-cli

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Install script breaks on new OS | High | Extensive Docker testing, CI matrix |
| Homebrew tap conflicts | Medium | Use unique tap name, test with other taps |
| Plugin manager conflicts | Medium | Detect existing installs, offer choices |
| Network failures during install | High | Add retry logic, offline fallback |
| Wizard too long | Low | Add `--quick` mode, make skippable |

---

## Documentation Updates

**Files to Update:**
- [ ] `README.md` - Add new install method prominently
- [ ] `docs/getting-started/installation.md` - Update with install.sh
- [ ] `docs/getting-started/quick-start.md` - Reference wizard
- [ ] `docs/commands/doctor.md` - Document `--fix` enhancements
- [ ] `docs/commands/setup.md` - New file for wizard
- [ ] `CHANGELOG.md` - Add v4.9.0 entry

**New Documentation:**
- [ ] Installation video/GIF showing full flow
- [ ] Troubleshooting guide for install issues
- [ ] Migration guide from v4.8.x

---

## Future Enhancements (v4.10.0+)

- [ ] GUI installer for non-terminal users
- [ ] Integration with dotfiles managers
- [ ] Cloud backup setup during wizard
- [ ] Team/shared configuration setup
- [ ] Plugin marketplace during setup
- [ ] AI-powered configuration suggestions

---

## References

**Similar Projects:**
- [aiterm installation](https://github.com/Data-Wise/aiterm/blob/main/install.sh) - Good reference for one-liner
- [Oh My Zsh installer](https://ohmyz.sh/#install) - Popular curl | sh pattern
- [Homebrew installer](https://brew.sh/) - Gold standard for ease of use
- [rustup](https://rustup.rs/) - Excellent wizard UX

**Best Practices:**
- Keep install.sh < 500 lines (maintainability)
- Use POSIX-compatible shell (sh, not bash/zsh)
- Provide clear error messages
- Make everything skippable/optional
- Test on clean systems regularly

---

## Next Steps

1. ✅ Create this spec document
2. → Review spec with user
3. → Create implementation tasks
4. → Start with Phase 1 (install.sh)
5. → Iterate based on testing

---

**Status:** Ready for implementation
**Estimated Timeline:** 2-3 days
**Priority:** High ⚡
