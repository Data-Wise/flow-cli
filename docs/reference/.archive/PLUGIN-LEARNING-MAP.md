# Plugin Learning Map

**Understand where each of the 22 ZSH plugins appears in your learning journey**

**Purpose:** Help learners discover plugins progressively, understand their relevance, and know when/how to use them.

**Status:** Reference Document
**Last Updated:** 2026-01-24
**Audience:** All levels

---

## Quick Start: Plugin Appearance Timeline

```
BEGINNER PHASE (45 min)
├─ Tutorials 1-3: NO PLUGINS
│  (Learn core flow-cli concepts first)
│
INTERMEDIATE PHASE (1 hr + 20 min)
├─ Tutorials 6-13: CORE PLUGINS START
│  ├─ git plugin (Tutorial 8)
│  ├─ Auto-suggestions (background)
│  └─ All guides reference plugins
│
ADVANCED PHASE (1.5+ hrs)
├─ Tutorials 14-23: PLUGIN MASTERY
│  ├─ All 22 plugins explored
│  ├─ Optimization focus
│  └─ Custom workflows
```

---

## 🎯 Tutorial-Plugin Matrix

### Phase 1: Pure flow-cli (No plugins)

| Tutorial | Title | Plugins Involved | Reason |
|----------|-------|------------------|--------|
| 1 | First Session | None | Core workflow isolated |
| 2 | Multiple Projects | None | Core workflow isolated |
| 3 | Status Visualizations | None | Core workflow isolated |

**Why no plugins here?** Plugins can be confusing for beginners. These tutorials focus on core flow-cli concepts before introducing the ZSH ecosystem.

---

### Phase 2: Core Plugins Introduction

| Tutorial | Title | Plugins | How They're Used |
|----------|-------|---------|------------------|
| 6 | Dopamine Features | None | flow-cli only feature |
| 10 | CC Dispatcher | None | flow-cli dispatcher |
| 11 | TM Dispatcher | None | flow-cli dispatcher |
| 12 | DOT Dispatcher | None | flow-cli dispatcher (secrets) |
| 13 | Prompt Dispatcher | None | flow-cli dispatcher |

**Why no plugins yet?** Dispatchers are flow-cli specific and don't need plugins. Plugins are still background noise at this stage.

---

### Phase 3: Git Workflows (First Plugin Deep Dive)

#### Tutorial 8: Git Feature Workflow ⚙️ **git plugin** (226+ aliases)

**Plugins touched:**

```
OMZ git plugin: 226+ aliases
├─ Core aliases used:
│  ├─ gst     → git status
│  ├─ ga      → git add
│  ├─ gaa     → git add --all
│  ├─ gcmsg   → git commit -m
│  ├─ gp      → git push
│  ├─ gco     → git checkout
│  ├─ gcb     → git checkout -b
│  └─ gd      → git diff
└─ Supported by:
   └─ zsh-you-should-use plugin (suggests these!)
```

**What you learn:**
- Git aliases dramatically speed up workflows
- `zsh-you-should-use` teaches you aliases automatically
- How plugins integrate with flow-cli git commands

**Example progression:**

```bash
# Beginner (slow, verbose)
git status
git add .
git commit -m "fix: update docs"
git push origin feature/docs

# After Tutorial 8 (with git plugin)
gst              # See changes
gaa              # Stage all
gcmsg "fix: update docs"  # Commit
gp               # Push to branch
```

---

#### Tutorial 9: Worktrees ⚙️ **git plugin** continued

**Plugins touched:** Same `git` plugin, but in context of:

```
Worktree commands:
├─ git worktree add/remove (git aliases support)
├─ Switching between worktrees (uses gco to navigate)
└─ Branch operations (all via git aliases)
```

**Why repeat git plugin here?** Worktrees are advanced git workflows. You'll be using git aliases constantly.

---

### Phase 4: Complete Plugin Ecosystem (Tutorial + Guide)

#### Guide: ZSH Plugin Ecosystem ⚙️ **ALL 22 PLUGINS**

**This is THE reference point for plugin learning**

**Plugins explained:**

**OMZ Plugins (18):**
1. git (226+ aliases)
2. github
3. docker
4. colored-man-pages
5. command-not-found
6. extract
7. copybuffer
8. copypath
9. copyfile
10. dirhistory
11. sudo
12. history
13. web-search
14. fzf
15. alias-finder
16. aliases
17. brew
18. path:lib

**Community Plugins (4):**
19. zsh-autosuggestions
20. zsh-syntax-highlighting
21. zsh-completions
22. zsh-you-should-use

---

### Phase 5: Advanced Optimization

#### Tutorial 22: Plugin Optimization ⚙️ **ALL 22 PLUGINS** (Performance focus)

**Topics covered:**

```
Load Guards:
├─ Check which plugins are slow
├─ Skip unnecessary plugins
└─ Optimize startup sequence

Display Layer Extraction:
├─ Cache plugin output
├─ Reduce redundant checks
└─ Measure performance improvements

Cache Collision Fixes:
├─ Handle competing cache strategies
├─ Prevent conflicts
└─ Maintain plugin independence
```

**Plugins relevant here:**
- All plugins analyzed for performance impact
- Special focus on: git, fzf, zsh-completions
- How to measure: `time zsh -i -c exit`

---

## 📊 Plugin Appearance Chart

```
Plugin Name                    Beginner  Intermediate  Advanced
─────────────────────────────────────────────────────────────────
zsh-autosuggestions            ✓         ✓            ✓
zsh-syntax-highlighting        ✓         ✓            ✓
zsh-you-should-use             ✗         ✓            ✓
git (226+ aliases)             ✗         ✓✓           ✓
fzf                            ✗         ✓            ✓
zsh-completions                ✗         ✓            ✓
aliases (list all)             ✗         ✓            ✓
alias-finder                   ✗         ✓            ✓
history                        ✗         ✓            ✓
web-search                     ✗         ✓            ✓
github                         ✗         ✓            ✓
docker                         ✗         ✓            ✓
brew                           ✗         ✓            ✓
extract                        ✗         ✓            ✓
copybuffer                     ✗         ✓            ✓
copypath                       ✗         ✓            ✓
copyfile                       ✗         ✓            ✓
dirhistory                     ✗         ✓            ✓
sudo                           ✗         ✓            ✓
colored-man-pages              ✗         ✓            ✓
command-not-found              ✓         ✓            ✓
path:lib                       ✗         ✓            ✓
─────────────────────────────────────────────────────────────────
✓ = Mentioned/usable
✓✓ = Deep dive focus
```

---

## 🎓 Plugin Learning Paths

### Path 1: "Just Tell Me What I Need"

**Duration:** 30 minutes

1. **skim** Plugin Ecosystem Guide for overview
2. **Focus on these 3 auto-active plugins:**
   - zsh-autosuggestions → Works automatically
   - zsh-syntax-highlighting → Works automatically
   - zsh-you-should-use → Teaches you aliases

3. **Ignore for now:**
   - Everything else (it's in the background, helps later)

**Outcome:** Understand 3 plugins that don't require any effort.

---

### Path 2: "I Want to Speed Up My Git Workflows"

**Duration:** 1.5 hours

1. **Read:** Tutorial 8: Git Feature Workflow
2. **Learn:** git plugin aliases (ga, gco, gp, etc.)
3. **Practice:** Use 5 aliases in real workflow
4. **Discover:** How zsh-you-should-use teaches you
5. **Explore:** Run `aliases git` to see full list
6. **Advanced:** [Git Plugin Full Reference (OMZ)](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git)

**Key plugins:**
- git (226+ aliases) - Main focus
- zsh-you-should-use - Automatic teacher
- zsh-syntax-highlighting - Real-time validation

---

### Path 3: "I Want to Explore All Plugins"

**Duration:** 2.5 hours

1. **Read:** [Plugin Ecosystem Guide](../guides/ZSH-PLUGIN-ECOSYSTEM-GUIDE.md) (full)
2. **Try:** Each plugin category once:
   - Productivity (zsh-autosuggestions, fzf, history)
   - Safety (zsh-syntax-highlighting, command-not-found)
   - Clipboard (copybuffer, copypath, copyfile)
   - Specialized (docker, github, brew, etc.)

3. **Commands to explore:**

   ```bash
   # See what each plugin provides
   aliases git              # git plugin aliases
   aliases docker           # docker plugin aliases
   aliases brew             # brew plugin aliases

   # Discover available aliases
   alias-finder git status  # Suggests: gst

   # List all aliases
   aliases                  # See everything
   ```

4. **Read:** [Alias Reference Card](ALIAS-REFERENCE-CARD.md)

5. **Study:** [Command Explorer](COMMAND-EXPLORER.md) for integration points

**Key plugins to master:**
- git - 226+ aliases (most valuable)
- fzf - Ctrl+R and Ctrl+T
- docker - If you use containers
- brew - Homebrew shortcuts
- github - GitHub operations

---

### Path 4: "I Want to Optimize My Setup"

**Duration:** 2+ hours

1. **Read:** Tutorial 22: Plugin Optimization
2. **Measure:** Current startup time

   ```bash
   time zsh -i -c exit
   ```

3. **Optimize:** By plugin (step by step)
   - Add load guards
   - Cache expensive checks
   - Measure improvement

4. **Study:** Plugin Management Workflow

5. **Advanced:** Create custom dispatchers using plugins

**Key plugins to optimize:**
- All plugins analyzed for performance
- Focus on: git, fzf, zsh-completions
- Measure: < 1 second startup goal

---

## 🔍 Plugin Reference Quick Links

### By Category

**Productivity (Speed):**
- zsh-autosuggestions - [Guide section](../guides/ZSH-PLUGIN-ECOSYSTEM-GUIDE.md#zsh-autosuggestions)
- zsh-you-should-use - [Guide section](../guides/ZSH-PLUGIN-ECOSYSTEM-GUIDE.md#zsh-you-should-use)
- fzf - [Guide section](../guides/ZSH-PLUGIN-ECOSYSTEM-GUIDE.md#fzf)
- history - [OMZ docs](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/history)
- alias-finder - [OMZ docs](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/alias-finder)

**Git Workflows:**
- git - [Tutorial 8](../tutorials/08-git-feature-workflow.md) | [Guide section](../guides/ZSH-PLUGIN-ECOSYSTEM-GUIDE.md#git-plugin-226-aliases) | [OMZ full](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git)
- github - [Guide section](../guides/ZSH-PLUGIN-ECOSYSTEM-GUIDE.md#github-plugin)

**Safety/Visibility:**
- zsh-syntax-highlighting - [Guide section](../guides/ZSH-PLUGIN-ECOSYSTEM-GUIDE.md#zsh-syntax-highlighting)
- command-not-found - [OMZ docs](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/command-not-found)
- colored-man-pages - [OMZ docs](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/colored-man-pages)

**Clipboard Tools:**
- copybuffer - [Guide section](../guides/ZSH-PLUGIN-ECOSYSTEM-GUIDE.md#copybuffer-ctrlo)
- copypath - [OMZ docs](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/copypath)
- copyfile - [OMZ docs](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/copyfile)

**Specialized Tools:**
- docker - [OMZ docs](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/docker)
- brew - [OMZ docs](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/brew)
- extract - [OMZ docs](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/extract)
- dirhistory - [OMZ docs](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/dirhistory)
- web-search - [OMZ docs](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/web-search)
- sudo - [OMZ docs](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/sudo)

**Completions:**
- zsh-completions - [GitHub](https://github.com/zsh-users/zsh-completions)
- aliases - [OMZ docs](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/aliases)

**Framework:**
- path:lib - [OMZ docs](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/lib)

---

## 📈 Plugin Complexity Ranking

### Complexity: Beginner (Passive - No learning required)

These work automatically, no action needed:

```
⭐ zsh-autosuggestions      → Just accept/reject suggestions
⭐ zsh-syntax-highlighting  → Just read the colors (green=good, red=bad)
⭐ command-not-found        → Automatic error suggestions
⭐ colored-man-pages        → Better looking man pages
```

### Complexity: Intermediate (Active - Learn aliases)

These require learning specific aliases and commands:

```
⭐⭐ git                     → 226+ aliases to explore
⭐⭐ zsh-you-should-use      → Teaches you automatically
⭐⭐ fzf                     → Ctrl+R and Ctrl+T
⭐⭐ history                 → h, hs, hsi commands
⭐⭐ docker                  → dk, dki, dkl aliases
⭐⭐ brew                    → bubo, bubc, bubu
⭐⭐ github                  → repo, gist commands
⭐⭐ extract                 → x command for any archive
⭐⭐ alias-finder            → alias-finder command
⭐⭐ aliases                 → aliases command
⭐⭐ web-search              → google, ddg commands
⭐⭐ zsh-completions         → Better tab-completion
⭐⭐ copybuffer              → Ctrl+O to copy line
⭐⭐ copypath                → copypath command
⭐⭐ copyfile                → copyfile command
⭐⭐ dirhistory              → Alt+← Alt+→ navigation
⭐⭐ sudo                    → ESC ESC to prepend sudo
```

### Complexity: Advanced (Optimization - Tune performance)

These relate to shell performance and customization:

```
⭐⭐⭐ All plugins            → Optimization in Tutorial 22
⭐⭐⭐ Load timing            → Performance analysis
⭐⭐⭐ Cache strategies       → Speed up repeated checks
⭐⭐⭐ Custom dispatchers     → Use plugins in own code
⭐⭐⭐ path:lib              → OMZ framework basics
```

---

## ✅ Plugin Mastery Checklist

### Beginner (Week 1)

- [ ] Understand what plugins are (frameworks for shells)
- [ ] Know you have 22 plugins loaded
- [ ] Experience zsh-autosuggestions and zsh-syntax-highlighting automatically
- [ ] See `zsh-you-should-use` suggest aliases once

**Test:** Type something and see color feedback + auto-suggestions

### Intermediate (Week 2)

- [ ] Read [Plugin Ecosystem Guide](../guides/ZSH-PLUGIN-ECOSYSTEM-GUIDE.md) completely
- [ ] Use 5 git aliases daily (ga, gco, gp, gst, gcmsg)
- [ ] Run `aliases git` once to see full list
- [ ] Try fzf history search (Ctrl+R)
- [ ] Know that `zsh-you-should-use` teaches you aliases

**Test:** Type `git status` and see "You should use: gst" suggestion

### Advanced (Week 3+)

- [ ] Know all 22 plugin names and categories
- [ ] Have tried 10+ different aliases
- [ ] Understand your shell startup time (measure it)
- [ ] Created custom aliases for frequent commands
- [ ] Explored 3 optional plugins (docker, web-search, etc.)
- [ ] Read [Alias Reference Card](ALIAS-REFERENCE-CARD.md)

**Test:** Run `aliases` and recognize 20+ of them

### Master (Month 2+)

- [ ] Have personalized your shell with custom aliases
- [ ] Optimized startup time (< 1 second)
- [ ] Built custom dispatchers using plugins
- [ ] Can help others understand plugins
- [ ] Regularly discover new aliases you didn't know

**Test:** Help someone else learn git aliases effectively

---

## 🛠️ Plugin Workflow Integration

### How Each Dispatcher Interacts with Plugins

```
FLOW-CLI DISPATCHERS  ← Interact with → ZSH PLUGINS

dispatch 'g' (git)
├─ Uses: git plugin (226+ aliases)
├─ Works with: zsh-syntax-highlighting (validates commands)
└─ Taught by: zsh-you-should-use (reminds about aliases)

dispatch 'cc' (Claude)
├─ No direct plugin dependencies
└─ Can be scripted with any plugin

dispatch 'teach' (teaching)
├─ No direct plugin dependencies
└─ Uses: flow-cli specific functionality

dispatch 'wt' (worktrees)
├─ Uses: git plugin (for git operations)
└─ Benefits from: zsh-syntax-highlighting (validation)

dispatch 'dot' (dotfiles)
├─ No direct plugin dependencies
└─ Can use: copybuffer plugin for clipboard ops

dispatch 'tm' (terminal)
├─ No direct plugin dependencies
└─ Benefits from: All plugins (uses them in new shells)
```

---

## 📚 Complete Plugin Documentation Map

### In This Documentation

| Type | Where to Find | Duration |
|------|---|---|
| **Plugin Overview** | [Plugin Ecosystem Guide](../guides/ZSH-PLUGIN-ECOSYSTEM-GUIDE.md) | 20 min |
| **Git Deep Dive** | [Tutorial 8: Git Workflow](../tutorials/08-git-feature-workflow.md) | 20 min |
| **Alias Reference** | [Alias Reference Card](ALIAS-REFERENCE-CARD.md) | 15 min |
| **Command Cheatsheet** | [Command Quick Reference](COMMAND-QUICK-REFERENCE.md) | 10 min |
| **Optimization** | [Tutorial 22: Plugin Optimization](../tutorials/22-plugin-optimization.md) | 20 min |
| **Plugin Management** | [Plugin Management Workflow](../guides/PLUGIN-MANAGEMENT-WORKFLOW.md) | 20 min |

### External Resources

| Plugin | Official Docs | Notes |
|--------|---|---|
| **git (OMZ)** | [OMZ git plugin](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/git) | 226+ aliases |
| **zsh-autosuggestions** | [GitHub](https://github.com/zsh-users/zsh-autosuggestions) | Fish-like suggestions |
| **zsh-syntax-highlighting** | [GitHub](https://github.com/zsh-users/zsh-syntax-highlighting) | Real-time coloring |
| **fzf (OMZ)** | [OMZ fzf](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/fzf) | Fuzzy finder |
| **zsh-completions** | [GitHub](https://github.com/zsh-users/zsh-completions) | Extra completions |
| **zsh-you-should-use** | [GitHub](https://github.com/MichaelAquilina/zsh-you-should-use) | Alias reminders |

---

## 🎯 Key Takeaways

### Remember These 3 Things

1. **22 plugins = 351 aliases + commands**
   - You don't need to memorize them
   - `aliases` command shows what you have
   - `alias-finder` helps discover aliases

2. **Plugins work in 3 ways:**
   - **Automatic** (zsh-autosuggestions, syntax highlighting)
   - **Taught** (zsh-you-should-use reminds you)
   - **Active** (you use their commands/aliases)

3. **Learn progressively:**
   - Week 1: Enjoy automatic plugins
   - Week 2: Master git aliases (most valuable)
   - Week 3+: Explore others as needed
   - Month 2+: Optimize and customize

---

## 🚀 Next Steps

**After understanding this map:**

1. **Go to:** [Plugin Ecosystem Guide](../guides/ZSH-PLUGIN-ECOSYSTEM-GUIDE.md) for details
2. **Try:** Tutorial 8 (Git Workflow) to see plugins in action
3. **Reference:** Use [Alias Reference Card](ALIAS-REFERENCE-CARD.md) when needed
4. **Explore:** [Plugin Management Workflow](../guides/PLUGIN-MANAGEMENT-WORKFLOW.md) when ready to customize

---

**Version:** 1.0
**Last Updated:** 2026-01-24
**Questions?** Check [Plugin Ecosystem Guide](../guides/ZSH-PLUGIN-ECOSYSTEM-GUIDE.md) first
