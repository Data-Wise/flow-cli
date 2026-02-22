# FAQ: Dependencies & Plugin Ecosystem

**Common questions about flow-cli's relationship with Oh-My-Zsh and other tools**

---

## Does flow-cli require Oh-My-Zsh?

**NO.** flow-cli is a **standalone ZSH plugin** with **ZERO dependencies** on Oh-My-Zsh (OMZ).

```text
┌─────────────────────────────────────────────────────────────┐
│ flow-cli                                                    │
│ ↓                                                           │
│ Pure ZSH (no dependencies)                                  │
└─────────────────────────────────────────────────────────────┘
```

**You can use flow-cli:**
- ✅ Without any plugin manager (manual install)
- ✅ With antidote (recommended)
- ✅ With zinit
- ✅ With Oh-My-Zsh
- ✅ With any other ZSH plugin manager

---

## Why does the documentation mention OMZ?

**Two reasons:**

### 1. Installation Method (Not a Dependency)

OMZ is **one of several ways to install** flow-cli - like choosing between:
- Package manager (Homebrew)
- Plugin manager (antidote, zinit, **OMZ**)
- Manual install

**OMZ is an installation option, not a requirement.**

### 2. User Detection & Support

flow-cli **detects** if you have OMZ installed to:
- Show relevant help (`flow doctor` detects your setup)
- Provide update instructions (`flow upgrade` knows how to update OMZ)
- Avoid conflicts (knows if OMZ git plugin is active)

**Example detection logic:**

```bash
# flow doctor checks your setup
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo "  ✓ oh-my-zsh (plugin manager)"
elif [[ -f "$HOME/.antidoterc" ]]; then
    echo "  ✓ antidote (plugin manager)"
fi
```

---

## What's the difference between "OMZ as plugin manager" vs "OMZ plugins via antidote"?

Great question! These are **two completely different things**:

### OMZ as Plugin Manager (Traditional)

```bash
~/.oh-my-zsh/                    # Full OMZ installation
├── oh-my-zsh.sh                 # Heavy framework
├── plugins/                     # 300+ plugins
├── themes/                      # Theme system
└── custom/                      # Your plugins
    └── plugins/
        └── flow-cli/            ← flow-cli installed HERE
```

**Characteristics:**
- ❌ Large installation (~50MB)
- ❌ Slower shell startup
- ❌ Manual updates (`omz update`)
- ✅ Works if you're already using OMZ

### OMZ Plugins via Antidote (Modern)

```text
~/.config/zsh/
├── .zsh_plugins.txt             # Plugin list
│   ├── Data-Wise/flow-cli       ← flow-cli
│   ├── ohmyzsh/.../git          ← OMZ git plugin
│   └── ohmyzsh/.../docker       ← OMZ docker plugin
└── .zsh_plugins.zsh             # Auto-generated cache
```

**NO ~/.oh-my-zsh/ directory!**

**Characteristics:**
- ✅ Minimal installation
- ✅ Fast shell startup
- ✅ Automatic updates (`antidote update`)
- ✅ Best of both worlds (use OMZ plugins without OMZ framework)

---

## I use OMZ plugins via antidote. Do I need OMZ?

**NO!** This is the optimal setup:

```text
Plugin Manager:  antidote (modern, fast)
Plugins Used:    18 OMZ plugins + 4 community + flow-cli
OMZ Directory:   NONE (no ~/.oh-my-zsh/)
```

**You get:**
- OMZ's excellent plugins (git, docker, clipboard, etc.)
- Without OMZ's framework overhead
- Via antidote's modern management

**This is RECOMMENDED!**

---

## Which plugins does flow-cli actually depend on?

**NONE.** flow-cli has zero plugin dependencies.

**Optional integrations:**

| Tool | Used For | Required? |
|------|----------|-----------|
| `fzf` | Interactive pickers (`pick`, `dash -i`) | No (fallback to basic) |
| `bat` | Syntax-highlighted previews | No (fallback to cat) |
| `zoxide` | Smart `cd` | No (fallback to regular cd) |
| `gh` | GitHub integration (`g pr`, `g issue`) | No (features disabled) |
| `eza` | Better file listing | No (fallback to ls) |

**All features gracefully degrade if tools aren't installed.**

---

## Does flow-cli use OMZ libraries?

**NO.** flow-cli uses **pure ZSH** - no external libraries.

**Your personal ZSH config** might load OMZ libraries (via antidote), but **flow-cli itself doesn't need them**.

**Example:**

```zsh
# Your ~/.config/zsh/.zsh_plugins.txt
ohmyzsh/ohmyzsh path:lib         # YOU load this (optional)
ohmyzsh/ohmyzsh path:plugins/git # YOU load this (optional)
Data-Wise/flow-cli               # flow-cli (independent)
```

All three plugins **coexist independently**.

---

## Will flow-cli conflict with OMZ plugins?

**Rarely, and only with specific plugins.**

### Known Conflicts

| OMZ Plugin | Conflict | Solution |
|------------|----------|----------|
| `git` | `g` alias | flow-cli unaliases and replaces with dispatcher |
| `z` | Directory jumping | Use zoxide instead (faster, better) |

### How flow-cli Handles Conflicts

```zsh
# In flow-cli/lib/dispatchers/g-dispatcher.zsh
unalias g 2>/dev/null            # Remove OMZ git alias
g() { ... }                      # Replace with flow-cli dispatcher
```

**Result:** flow-cli's `g` dispatcher wins, OMZ git aliases (ga, gco, etc.) still work.

---

## Can I use both flow-cli's `g` dispatcher and OMZ git aliases?

**YES!** They complement each other:

**OMZ git plugin provides:**

```bash
ga          # git add
gaa         # git add --all
gco         # git checkout
gst         # git status
gp          # git push
# ... 226+ more aliases
```

**flow-cli `g` dispatcher provides:**

```bash
g status    # Enhanced status with branch info
g push      # Token-validated push
g commit    # Conventional commit wizard
g feature   # Feature branch workflow
```

**Use together:**

```bash
gaa                  # Quick add (OMZ)
g commit             # Interactive commit (flow-cli)
gp                   # Quick push (OMZ)
```

---

## Should I switch from OMZ to antidote?

**Depends on your needs:**

### Stay with OMZ if

- ✅ You're comfortable with OMZ
- ✅ You have custom OMZ configurations
- ✅ You don't mind manual updates
- ✅ Shell startup speed isn't critical

### Switch to antidote if

- ✅ You want faster shell startup
- ✅ You want automatic plugin updates
- ✅ You want a modern, minimal setup
- ✅ You want to use non-OMZ plugins easily

**Both work perfectly with flow-cli!**

---

## How do I check what plugins I'm using?

```bash
# List all loaded plugins
ls -1 ~/.local/share/antidote/     # Antidote
ls -1 ~/.oh-my-zsh/plugins/        # OMZ
zinit list                         # Zinit

# Check specific plugins
which g                            # Shows if flow-cli dispatcher
alias | grep "^g"                  # Shows if OMZ git plugin
```

---

## I don't have any plugin manager. Can I still use flow-cli?

**YES!** Manual installation:

```bash
# 1. Clone
git clone https://github.com/Data-Wise/flow-cli.git ~/.flow-cli

# 2. Add to .zshrc
echo 'source ~/.flow-cli/flow.plugin.zsh' >> ~/.zshrc

# 3. Reload
source ~/.zshrc
```

**No plugin manager required!**

---

## Does flow-cli slow down my shell?

**NO.** flow-cli is designed for sub-10ms performance:

```bash
# Benchmark
time ( source flow.plugin.zsh )
# → ~5-8ms (negligible)
```

**Optimizations:**
- Load guards prevent double-sourcing
- Lazy loading for heavy features
- Minimal dependencies
- Pure ZSH (no external processes)

**If shell is slow, the cause is likely:**
- ❌ Too many plugins (unrelated to flow-cli)
- ❌ Heavy OMZ framework (if using OMZ as manager)
- ❌ Unoptimized .zshrc

---

## Where can I learn more about the plugin ecosystem?

**Read the comprehensive guide:**

📖 **[ZSH Plugin Ecosystem Guide](../guides/ZSH-PLUGIN-ECOSYSTEM-GUIDE.md)**

Covers:
- Understanding antidote + OMZ plugins
- Tutorial for all 22 plugins
- How to use git aliases, clipboard tools, navigation
- Troubleshooting and optimization

---

## Quick Reference

### flow-cli Independence

```text
✅ flow-cli works WITHOUT:
   - Oh-My-Zsh
   - Any plugin manager
   - Any external plugins

✅ flow-cli works WITH:
   - Homebrew (recommended)
   - antidote (recommended plugin manager)
   - zinit
   - Oh-My-Zsh
   - Manual install
```

### Plugin Ecosystem (Optional)

```text
YOUR ZSH SETUP (example):
├── Plugin Manager: antidote (your choice)
├── Plugins: 18 OMZ + 4 community (your choice)
└── flow-cli: Independent (no dependencies)
```

**All are independent choices!**

---

**Still have questions?**

- 📖 Read: [Installation Guide](installation.md)
- 🔧 Run: `flow doctor` to check your setup
- 💬 Ask: [GitHub Discussions](https://github.com/Data-Wise/flow-cli/discussions)

---

**Last Updated:** 2026-01-24
**Version:** 1.0.0
