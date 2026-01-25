# ZSH Plugin Ecosystem Integration Strategy

**Created:** 2026-01-24
**Status:** Strategic Planning Document
**Purpose:** Guide integration of 22 ZSH plugins into flow-cli tutorial ecosystem

---

## Executive Summary

**Current State:**
- 25 existing tutorials (01-23 + nvim 15-18 + teaching 19-21 + advanced 22-23)
- 22 ZSH plugins (18 OMZ + 4 community) loaded via antidote
- 1,200+ line comprehensive plugin guide exists
- 351 total aliases across all plugins

**Integration Goals:**
1. Create 5-minute plugin quick-starts for common workflows
2. Integrate plugin tips into existing tutorials (non-disruptive)
3. Progressive disclosure (basics → advanced)
4. ADHD-friendly design (visual, scannable, actionable)

**Recommended Approach:**
- **Phase 1:** Create 8 standalone plugin quick-starts (tutorials 24-31)
- **Phase 2:** Add "Plugin Power-Ups" sections to 12 existing tutorials
- **Phase 3:** Create cross-reference index and learning paths

---

## Plugin-to-Tutorial Mapping

### Phase 1: New Plugin Quick-Start Tutorials (24-31)

Create 8 standalone 5-minute tutorials focusing on immediate value:

| Tutorial # | Title | Plugins Covered | Time | Target User |
|------------|-------|-----------------|------|-------------|
| **24** | Plugin Power-Ups: Git Workflow | git, github | 5 min | Git users |
| **25** | Plugin Power-Ups: Clipboard Magic | copybuffer, copypath, copyfile | 5 min | Everyone |
| **26** | Plugin Power-Ups: Smart Suggestions | zsh-autosuggestions, zsh-syntax-highlighting | 5 min | Beginners |
| **27** | Plugin Power-Ups: Directory Navigation | dirhistory, zoxide | 5 min | Multi-project users |
| **28** | Plugin Power-Ups: Command Discovery | alias-finder, aliases, zsh-you-should-use | 5 min | Learning curve reduction |
| **29** | Plugin Power-Ups: Docker & Dev Tools | docker, brew, extract | 5 min | Developers |
| **30** | Plugin Power-Ups: History & Search | history, fzf, web-search | 5 min | Power users |
| **31** | Plugin Power-Ups: Quality of Life | sudo, colored-man-pages, command-not-found | 5 min | Everyone |

**Structure for Each:**

```markdown
# Tutorial XX: Plugin Power-Ups - [Category]

> **What you'll learn:** [Specific outcome in 1 sentence]
> **Time:** 5 minutes | **Level:** Beginner

## Quick Win (60 seconds)

[Single most valuable feature - try it NOW]

## Core Features (3 minutes)

[3-5 features with examples]

## Power User Tips (60 seconds)

[2-3 advanced tricks]

## Integration with flow-cli

[How these plugins enhance flow-cli workflows]

## Cheat Sheet

[One-page reference card]
```

---

### Phase 2: Integrate into Existing Tutorials

Add "Plugin Power-Up" sections (collapsible) to existing tutorials:

#### HIGH PRIORITY (Immediate Value)

| Tutorial | Plugin Integration | Placement | Benefit |
|----------|-------------------|-----------|---------|
| **01 - First Session** | zsh-autosuggestions, zsh-syntax-highlighting | After Part 1 | Help beginners avoid typos |
| **02 - Multiple Projects** | dirhistory, zoxide | After project switching | Faster navigation |
| **06 - Dopamine Features** | aliases, alias-finder | After win tracking | Discover flow-cli aliases |
| **08 - Git Workflow** | git plugin (226 aliases) | Throughout examples | Replace verbose git commands |
| **10 - CC Dispatcher** | copypath, copyfile | After launching Claude | Copy context quickly |
| **12 - DOT Dispatcher** | copybuffer, web-search | After secret management | Copy tokens, search docs |

#### MEDIUM PRIORITY (Enhancement)

| Tutorial | Plugin Integration | Placement | Benefit |
|----------|-------------------|-----------|---------|
| **03 - Status Visualizations** | fzf | After dashboard | Interactive filtering |
| **09 - Worktrees** | git aliases, dirhistory | Throughout | Faster worktree ops |
| **11 - TM Dispatcher** | sudo | After terminal commands | Quick privilege escalation |
| **14 - Teach Dispatcher** | web-search, copyfile | After content creation | Research & sharing |

#### LOW PRIORITY (Nice to Have)

| Tutorial | Plugin Integration | Placement | Benefit |
|----------|-------------------|-----------|---------|
| **04 - Web Dashboard** | web-search | Optional section | External research |
| **13 - Prompt Dispatcher** | aliases | After switching engines | Discover aliases |
| **21 - Teach Analyze** | extract, docker | Advanced section | Handle archives, containers |
| **22 - Plugin Optimization** | brew | Troubleshooting | Update dependencies |

---

## Integration Patterns

### Pattern 1: Inline Tips (Non-Disruptive)

**Example from Tutorial 08 (Git Workflow):**

```markdown
### Step 1.1: Create a Feature Branch

```bash
# Start a new feature from dev
g feature start auth-improvements
```

**Plugin Power-Up:** 💡 Did you know? The `git` plugin provides 226+ shortcuts!
- `gco -b auth` = `git checkout -b feature/auth`
- `gst` = `git status`
- `gl` = `git pull`

<details>
<summary>📚 See all git aliases</summary>

Run `aliases git` to see all 226 git shortcuts, or check Tutorial 24 for common ones.
</details>
```

**Why this works:**
- Non-intrusive (collapsed by default)
- Visual cue (💡 emoji)
- Progressive disclosure (expand to learn more)
- Cross-reference to deep-dive tutorial

---

### Pattern 2: Dedicated Sections (Natural Fit)

**Example from Tutorial 01 (First Session):**

```markdown
## Part 1: Starting Your First Session

### Step 1.1: Check What's Available

```bash
dash
```

---

### 💡 Plugin Power-Up: Smart Typing Assistance

**New to the terminal?** Two plugins are already helping you:

**zsh-autosuggestions** - See gray text as you type:

```bash
$ dash▊                     # Gray suggestion appears
$ dash                      # Press → to accept
```

**zsh-syntax-highlighting** - Colors show valid/invalid:

```bash
$ dash        # Green = valid command
$ dashh       # Red = typo detected
```

**Try it now:** Type `das` slowly and watch the suggestions appear!

<details>
<summary>🎓 Learn More</summary>

See **[Tutorial 26: Smart Suggestions](26-smart-suggestions.md)** for advanced features like word-by-word acceptance and customization.
</details>

---

### Step 1.2: Let Flow Pick For You

```

**Why this works:**
- Natural break in workflow (after first command)
- Helps beginners immediately
- Reduces tutorial follow-along errors
- Links to deep-dive tutorial

---

### Pattern 3: Cheat Sheet Sections (End of Tutorial)

**Example from Tutorial 10 (CC Dispatcher):**

```markdown
## Cheat Sheet

### flow-cli Commands
```bash
cc              # Launch Claude
cc yolo         # Skip approval
cc pick         # Choose project
```

### Plugin Shortcuts (Enhance Your Workflow)

**Copy Context for Claude:**

```bash
copypath file.txt          # Copy file path
copyfile config.json       # Copy file contents
Ctrl+O                     # Copy current command line
```

**Quick Git Operations:**

```bash
gst                        # git status
gaa                        # git add --all
gcmsg "message"            # git commit -m
gp                         # git push
```

**Pro Tip:** Run `aliases claude` to see all Claude-related shortcuts!

📚 **Deep Dive:** Tutorial 24: Git Plugin Power-Ups (planned)

```

**Why this works:**
- Centralized reference
- Shows plugin + flow-cli synergy
- Links to focused plugin tutorial
- Copy-paste friendly

---

## Progressive Disclosure Strategy

### Level 1: Beginners (Tutorials 01-06)

**Focus:** Core productivity plugins that prevent errors

**Plugins:**
- zsh-autosuggestions (prevent typos)
- zsh-syntax-highlighting (validate commands)
- command-not-found (helpful suggestions)
- colored-man-pages (easier to read help)

**Integration Style:**
- Inline tips after first command usage
- Visual cues (💡 emoji)
- "Try it now" immediate actions
- Collapsed sections for details

---

### Level 2: Intermediate (Tutorials 08-14)

**Focus:** Workflow acceleration plugins

**Plugins:**
- git (226 shortcuts)
- github (repo commands)
- copybuffer, copypath, copyfile (clipboard)
- dirhistory (navigation)
- fzf (fuzzy finding)

**Integration Style:**
- Dedicated "Plugin Power-Up" sections
- Side-by-side examples (verbose vs shortcut)
- Cheat sheet at end
- Cross-references to plugin tutorials

---

### Level 3: Advanced (Tutorials 21-23)

**Focus:** Developer tooling plugins

**Plugins:**
- docker (container shortcuts)
- brew (package management)
- extract (archive handling)
- sudo (privilege escalation)
- web-search (research)

**Integration Style:**
- Workflow-specific integrations
- Advanced use cases
- Combination patterns
- Custom alias suggestions

---

## Tutorial-Specific Integration Plans

### Tutorial 01: First Session

**Integration Points:**

1. **After `dash` command** (Step 1.1)
   - Add: zsh-autosuggestions + zsh-syntax-highlighting section
   - Benefit: Help beginners type correctly from the start
   - Style: Dedicated section with "Try it now"

2. **After `work` command** (Step 1.2)
   - Add: Inline tip about command-not-found plugin
   - Benefit: If they typo "work" → helpful suggestion
   - Style: Collapsed details section

3. **Cheat Sheet**
   - Add: "Essential Shortcuts" section
   - Plugins: autosuggestions (→ key), aliases command
   - Benefit: Discover more commands

**Estimated addition:** +150 words (5% increase)

---

### Tutorial 02: Multiple Projects

**Integration Points:**

1. **After `hop` command** (Part 2)
   - Add: dirhistory plugin section (Alt+Left/Right)
   - Benefit: Navigate between recently visited projects
   - Style: Inline tip with keyboard shortcuts

2. **After project switching** (Part 3)
   - Add: zoxide integration section
   - Benefit: `z project-name` for instant jumping
   - Style: "Pro Tip" box

3. **Cheat Sheet**
   - Add: Navigation shortcuts
   - Plugins: dirhistory, zoxide, fzf
   - Benefit: Multiple ways to switch projects

**Estimated addition:** +200 words (7% increase)

---

### Tutorial 06: Dopamine Features

**Integration Points:**

1. **After `win` command** (Part 1)
   - Add: alias-finder section
   - Example: "Find shorter commands for what you just did"
   - Benefit: Discover flow-cli aliases while using them
   - Style: Dedicated section

2. **After `yay` command** (Part 2)
   - Add: aliases command section
   - Example: `aliases win` → see all dopamine aliases
   - Benefit: Explore the full feature set
   - Style: Inline tip

3. **Cheat Sheet**
   - Add: "Discover More Aliases" section
   - Plugins: alias-finder, aliases, zsh-you-should-use
   - Benefit: Learn the ecosystem while celebrating wins

**Estimated addition:** +180 words (6% increase)

---

### Tutorial 08: Git Feature Workflow

**Integration Points:**

1. **Step 1.1: Create Feature Branch**
   - Replace verbose git commands with git plugin aliases
   - Show side-by-side: `git checkout -b` vs `gcb`
   - Benefit: 80% faster typing
   - Style: Inline comparison table

2. **Step 2.1: Making Commits**
   - Add: git aliases for staging and committing
   - Show: `gaa` + `gcmsg "message"` + `gp` workflow
   - Benefit: Complete workflow in 3 commands
   - Style: Dedicated section

3. **Step 4.1: Cleaning Up**
   - Add: git aliases for branch cleanup
   - Show: `gbd`, `gbD`, `glo` (log)
   - Benefit: Safe branch deletion
   - Style: Pro tips box

4. **Cheat Sheet**
   - Replace ALL git commands with alias versions
   - Add: "226+ More Aliases" link to Tutorial 24
   - Benefit: Complete git workflow acceleration

**Estimated addition:** +300 words (15% increase)

**CRITICAL:** This tutorial benefits MOST from plugin integration

---

### Tutorial 10: CC Dispatcher

**Integration Points:**

1. **After launching Claude** (Part 1)
   - Add: copypath + copyfile section
   - Use case: Copy file contents to paste in Claude
   - Benefit: Faster context sharing
   - Style: Dedicated section "Sharing Context with Claude"

2. **After `cc pick` command** (Part 2)
   - Add: fzf integration note
   - Benefit: Fuzzy search in project picker
   - Style: Inline tip

3. **After secret management** (Part 3)
   - Add: copybuffer (Ctrl+O) section
   - Use case: Copy API key without exposing it
   - Benefit: Security + speed
   - Style: Security tip box

4. **Cheat Sheet**
   - Add: "Clipboard Workflows" section
   - Show: Complete copy → paste → cleanup pattern
   - Benefit: Professional Claude Code workflow

**Estimated addition:** +250 words (10% increase)

---

### Tutorial 12: DOT Dispatcher

**Integration Points:**

1. **After `dot secret set`** (Part 2)
   - Add: copybuffer section (copy secret without displaying)
   - Benefit: Security best practice
   - Style: Security warning box

2. **After `dot token expiring`** (Part 3)
   - Add: web-search plugin section
   - Use case: `google "github token expiration"`
   - Benefit: Quick documentation lookup
   - Style: Pro tip

3. **Cheat Sheet**
   - Add: "Security-Focused Shortcuts"
   - Plugins: copybuffer, sudo, copyfile
   - Benefit: Safe secret management workflow

**Estimated addition:** +150 words (5% increase)

---

## Standalone Plugin Tutorial Outlines

### Tutorial 24: Plugin Power-Ups - Git Workflow

**Outline:**

```markdown
# Tutorial 24: Plugin Power-Ups - Git Workflow

> **What you'll learn:** Use 226+ git shortcuts to accelerate your workflow
> **Time:** 5 minutes | **Level:** Beginner
> **Plugins:** git (OMZ), github (OMZ)

## Quick Win (60 seconds)

Try this RIGHT NOW:

```bash
# Instead of:
git status
git add --all
git commit -m "Update docs"
git push

# Use this:
gst
gaa
gcmsg "Update docs"
gp
```

**You just saved 80% typing!**

## Top 20 Aliases (3 minutes)

### Status & Info

- `gst` = `git status`
- `gss` = `git status -s` (short)
- `glog` = `git log --oneline --graph`

### Add & Commit

- `ga` = `git add`
- `gaa` = `git add --all`
- `gcmsg` = `git commit -m`
- `gc!` = `git commit --amend`

### Branches

- `gco` = `git checkout`
- `gcb` = `git checkout -b`
- `gbd` = `git branch -d`

### Push & Pull

- `gp` = `git push`
- `gl` = `git pull`
- `gf` = `git fetch`

### Stash

- `gsta` = `git stash`
- `gstp` = `git stash pop`

### Diff & Show

- `gd` = `git diff`
- `gds` = `git diff --staged`
- `gsh` = `git show`

### GitHub Plugin

- `repo` = Open current repo in browser
- `gist file.txt` = Create GitHub gist

## Power User Tips (60 seconds)

**Discover aliases as you type:**

```bash
git status
# zsh-you-should-use will suggest: "Use gst instead"
```

**Find aliases for any command:**

```bash
alias-finder git commit
# → gcmsg='git commit -m'
```

**See all 226 git aliases:**

```bash
aliases git
```

## Integration with flow-cli

**Git Feature Workflow (Tutorial 08):**

```bash
# Start feature
g feature start my-feature

# Work with git aliases
gst                          # Check status
gaa                          # Stage all
gcmsg "feat: add feature"    # Commit
gp                           # Push

# Merge via flow-cli
g feature finish
```

**Worktree Workflow (Tutorial 09):**

```bash
wt create feature-branch     # flow-cli creates worktree
cd $(wt path feature-branch)
gst                          # git plugin in worktree
```

## Cheat Sheet

**Daily Workflow:**

```bash
gst → gaa → gcmsg "message" → gp
```

**Branch Workflow:**

```bash
gcb feature → [work] → gp → [PR] → gco dev → gbd feature
```

**Undo Mistakes:**

```bash
git reset HEAD~1             # (no alias - dangerous)
gc!                          # Amend last commit
gsta → gco main → gstp       # Stash → switch → pop
```

**Full Reference:** Run `aliases git | less`

```

**Estimated length:** ~500 words

---

### Tutorial 25: Plugin Power-Ups - Clipboard Magic

**Outline:**

```markdown
# Tutorial 25: Plugin Power-Ups - Clipboard Magic

> **What you'll learn:** Master clipboard operations for faster workflows
> **Time:** 5 minutes | **Level:** Beginner
> **Plugins:** copybuffer, copypath, copyfile

## Quick Win (60 seconds)

**Copy this long command without retyping:**

```bash
# Type this (don't run yet):
kubectl get pods --all-namespaces --field-selector status.phase=Running

# Press Ctrl+O → Entire line copied!
# Now you can paste it anywhere
```

## Core Features (3 minutes)

### 1. copybuffer (Ctrl+O)

**Copy current terminal line:**

```bash
$ echo "Some long command you want to save"
# Press Ctrl+O → Line copied to clipboard
```

**Use cases:**
- Save commands before running
- Copy error messages
- Share terminal commands

### 2. copypath

**Copy current directory:**

```bash
copypath              # Copies $(pwd)
```

**Copy specific file path:**

```bash
copypath file.txt     # Copies absolute path
copypath .            # Copies current directory
```

**Use cases:**
- Share file locations with Claude
- Include paths in documentation
- Quick navigation between terminals

### 3. copyfile

**Copy file contents to clipboard:**

```bash
copyfile config.json  # File contents → clipboard
copyfile .env.example # Copy example config
```

**Use cases:**
- Paste code into Claude
- Share configurations
- Quick file duplication

## Power User Tips (60 seconds)

**1. Chain with other commands:**

```bash
# Generate SSH key and copy it
ssh-keygen -t ed25519 -C "email@example.com"
copyfile ~/.ssh/id_ed25519.pub
# Now paste into GitHub
```

**2. Copy without displaying sensitive data:**

```bash
# DON'T do this (exposes secret):
cat ~/.env | pbcopy

# DO this instead:
copyfile ~/.env       # Copy without display
```

**3. Copy error messages:**

```bash
npm install 2>&1 | tee /tmp/error.log
copyfile /tmp/error.log
# Paste into ChatGPT for debugging
```

## Integration with flow-cli

### CC Dispatcher (Tutorial 10)

**Share context with Claude:**

```bash
cc                           # Launch Claude Code
copyfile src/main.js         # Copy file contents
# Paste into Claude chat
```

### DOT Dispatcher (Tutorial 12)

**Copy secrets safely:**

```bash
dot secret get GITHUB_TOKEN > /tmp/token.txt
copyfile /tmp/token.txt      # Copy without display
rm /tmp/token.txt            # Clean up
```

### Teach Dispatcher (Tutorial 14)

**Share student code:**

```bash
teach status
copypath assignments/hw1/student-submission.R
# Send path to student
```

## Cheat Sheet

| Action | Command | Shortcut |
|--------|---------|----------|
| Copy current line | - | `Ctrl+O` |
| Copy current dir | `copypath` | - |
| Copy file path | `copypath file.txt` | - |
| Copy file contents | `copyfile file.txt` | - |

**Remember:** All three plugins are ALWAYS available!

```

**Estimated length:** ~450 words

---

### Tutorial 26: Plugin Power-Ups - Smart Suggestions

**Outline:**

```markdown
# Tutorial 26: Plugin Power-Ups - Smart Suggestions

> **What you'll learn:** Let your shell help you type faster and avoid errors
> **Time:** 5 minutes | **Level:** Beginner
> **Plugins:** zsh-autosuggestions, zsh-syntax-highlighting, zsh-you-should-use

## Quick Win (60 seconds)

**Try this RIGHT NOW:**

```bash
# 1. Type slowly: git st
#    Notice gray text appearing? That's autosuggestions!

# 2. Press → (right arrow)
#    Command completes to "git status"

# 3. Press Enter
#    Did zsh-you-should-use suggest "gst"?

# You just learned 3 plugins in 60 seconds!
```

## Core Features (3 minutes)

### 1. zsh-autosuggestions

**See suggestions as you type:**

```bash
$ git pu▊                    # Gray: "git push origin main"
                             # (from your history)
```

**Accept suggestions:**
- `→` (Right Arrow) - Accept full suggestion
- `Alt+→` - Accept next word only
- `Ctrl+Space` - Toggle suggestions on/off

**Smart about context:**
- Suggests based on current directory
- Prioritizes recent commands
- Learns your patterns

### 2. zsh-syntax-highlighting

**Real-time validation:**

```bash
$ ls        # Green (valid command)
$ lss       # Red (command not found)
$ cd /tmp   # Green (path exists)
$ cd /xyz   # Red (path doesn't exist)
```

**What it highlights:**
- Commands (green = valid, red = invalid)
- Paths (green = exists, red = doesn't exist)
- Strings (yellow)
- Flags (cyan)

### 3. zsh-you-should-use

**Learn aliases automatically:**

```bash
$ git status
# → You should use: gst

$ docker ps
# → You should use: dkps

$ git add --all
# → You should use: gaa
```

**Configurable:**

```bash
# Disable temporarily
export YSU_IGNORED_ALIASES=("gst")

# Disable for current session
unset YSU_MESSAGE_POSITION
```

## Power User Tips (60 seconds)

**1. History-based workflows:**

```bash
# Type partial command → → → Enter
$ cd ~/proj→                 # Completes to last directory
```

**2. Learn as you go:**

```bash
# Type verbose command
$ git commit --amend --no-edit
# → You should use: gc!

# Next time, use the alias!
```

**3. Combine with fzf:**

```bash
# Ctrl+R for history search
# → to accept suggestion
# Enter to run
```

## Integration with flow-cli

### Tutorial 01 (First Session)

**Prevent typos when starting:**

```bash
$ wor▊                       # Suggests: work
$ work → my-project
```

### Tutorial 06 (Dopamine Features)

**Discover win aliases:**

```bash
$ flow win "Completed feature"
# → You should use: win "Completed feature"
```

### Tutorial 08 (Git Workflow)

**Learn git aliases fast:**

```bash
$ git checkout -b feature
# → You should use: gcb feature

# Every command teaches you!
```

## Cheat Sheet

| Plugin | Key | Action |
|--------|-----|--------|
| autosuggestions | `→` | Accept suggestion |
| autosuggestions | `Alt+→` | Accept word |
| autosuggestions | `Ctrl+Space` | Toggle |
| syntax-highlighting | - | Automatic |
| you-should-use | - | Automatic |

**Disable suggestions:**

```bash
unset ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE
```

**Re-enable:**

```bash
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
```

```

**Estimated length:** ~500 words

---

## Implementation Phases

### Phase 1A: Create Standalone Tutorials (Week 1)

**Priority Order:**

1. **Tutorial 24: Git Workflow** (Highest impact - 226 aliases)
2. **Tutorial 26: Smart Suggestions** (Beginner-friendly)
3. **Tutorial 25: Clipboard Magic** (Universal utility)
4. **Tutorial 27: Directory Navigation** (Multi-project users)
5. **Tutorial 28: Command Discovery** (Learning curve reduction)

**Deliverables:**
- 5 markdown files (~500 words each)
- Cheat sheets for each
- Cross-reference updates in index.md

**Estimated effort:** 8-10 hours

---

### Phase 1B: Lower Priority Standalone Tutorials (Week 2)

**Priority Order:**

6. **Tutorial 29: Docker & Dev Tools** (Developer audience)
7. **Tutorial 30: History & Search** (Power users)
8. **Tutorial 31: Quality of Life** (Nice to have)

**Deliverables:**
- 3 markdown files (~400 words each)
- Cheat sheets
- Complete plugin tutorial series

**Estimated effort:** 5-6 hours

---

### Phase 2A: High-Priority Integrations (Week 3)

**Tutorials to update (in order):**

1. **Tutorial 08: Git Workflow** (+300 words, 15% increase)
   - Replace ALL git commands with aliases
   - Side-by-side comparisons
   - Link to Tutorial 24

2. **Tutorial 01: First Session** (+150 words, 5% increase)
   - Add autosuggestions section
   - Help beginners from the start

3. **Tutorial 10: CC Dispatcher** (+250 words, 10% increase)
   - Clipboard workflows
   - Copy context to Claude

4. **Tutorial 06: Dopamine Features** (+180 words, 6% increase)
   - Discover aliases while celebrating wins

**Deliverables:**
- 4 updated tutorial files
- Cheat sheet expansions
- Cross-references to new plugin tutorials

**Estimated effort:** 6-8 hours

---

### Phase 2B: Medium-Priority Integrations (Week 4)

**Tutorials to update:**

5. **Tutorial 02: Multiple Projects** (+200 words, 7% increase)
6. **Tutorial 09: Worktrees** (+150 words, 5% increase)
7. **Tutorial 12: DOT Dispatcher** (+150 words, 5% increase)
8. **Tutorial 14: Teach Dispatcher** (+100 words, 3% increase)

**Deliverables:**
- 4 updated tutorial files
- Navigation and security-focused integrations

**Estimated effort:** 4-5 hours

---

### Phase 3: Documentation Updates (Week 5)

**Files to update:**

1. **`docs/tutorials/index.md`**
   - Add tutorials 24-31 to navigation
   - Update learning paths
   - Add "Plugin Power-Ups" quick path

2. **`mkdocs.yml`**
   - Add 8 new tutorial entries
   - Create "Plugin Power-Ups" section

3. **Create `PLUGIN-LEARNING-PATH.md`**
   - Progressive disclosure guide
   - Plugin → Tutorial cross-reference
   - Workflow-specific plugin combos

4. **Update `README.md`**
   - Mention plugin ecosystem
   - Link to plugin tutorials

**Deliverables:**
- Updated navigation
- Cross-reference guide
- Learning path document

**Estimated effort:** 3-4 hours

---

## Total Effort Estimate

| Phase | Hours | Priority |
|-------|-------|----------|
| Phase 1A | 8-10 | ⭐⭐⭐ HIGH |
| Phase 1B | 5-6 | ⭐⭐ MEDIUM |
| Phase 2A | 6-8 | ⭐⭐⭐ HIGH |
| Phase 2B | 4-5 | ⭐⭐ MEDIUM |
| Phase 3 | 3-4 | ⭐ LOW |
| **Total** | **26-33 hours** | |

**Recommended schedule:** 5-6 weeks at 5-6 hours/week

---

## Success Metrics

### Completion Criteria

**Phase 1A Complete:**
- [ ] 5 plugin tutorials created (24-28)
- [ ] Each tutorial < 600 words
- [ ] Cheat sheets for each
- [ ] Cross-referenced from index.md

**Phase 2A Complete:**
- [ ] 4 tutorials updated (01, 06, 08, 10)
- [ ] Plugin sections non-disruptive
- [ ] Cross-references to plugin tutorials

**Full Integration Complete:**
- [ ] 8 plugin tutorials (24-31)
- [ ] 12 tutorials updated with plugin sections
- [ ] Learning path document created
- [ ] Navigation updated

### Quality Criteria

**Each plugin tutorial must:**
- Start with 60-second quick win
- Include "Try it now" action
- Provide cheat sheet
- Link to flow-cli integration
- Stay under 600 words

**Each integration must:**
- Use collapsible sections
- Not disrupt tutorial flow
- Provide immediate value
- Link to deep-dive tutorial
- Use visual cues (💡 emoji)

---

## Maintenance Plan

### Quarterly Updates

**Every 3 months:**
- Review plugin usage analytics (if available)
- Update based on new plugins added
- Refresh examples with current commands
- Check for broken cross-references

### When to Update

**Trigger:** New plugin added to `.zsh_plugins.txt`

**Actions:**
1. Add to ZSH-PLUGIN-ECOSYSTEM-GUIDE.md
2. Evaluate: Does it warrant standalone tutorial?
3. Find integration points in existing tutorials
4. Update learning path

---

## Appendix: Plugin Categories → Tutorial Map

### Productivity Boosters
- **Primary tutorial:** 26 (Smart Suggestions)
- **Integrations:** 01 (First Session), all beginner tutorials
- **Plugins:** zsh-autosuggestions, zsh-syntax-highlighting, zsh-you-should-use

### Git Workflow
- **Primary tutorial:** 24 (Git Workflow)
- **Integrations:** 08 (Git Feature), 09 (Worktrees)
- **Plugins:** git, github

### Clipboard Tools
- **Primary tutorial:** 25 (Clipboard Magic)
- **Integrations:** 10 (CC Dispatcher), 12 (DOT Dispatcher), 14 (Teach)
- **Plugins:** copybuffer, copypath, copyfile

### Directory Navigation
- **Primary tutorial:** 27 (Directory Navigation)
- **Integrations:** 02 (Multiple Projects), 09 (Worktrees)
- **Plugins:** dirhistory, zoxide

### Command Discovery
- **Primary tutorial:** 28 (Command Discovery)
- **Integrations:** 06 (Dopamine), 08 (Git), all tutorials
- **Plugins:** alias-finder, aliases, zsh-you-should-use

### Developer Tools
- **Primary tutorial:** 29 (Docker & Dev Tools)
- **Integrations:** 21 (Teach Analyze), 22 (Plugin Optimization)
- **Plugins:** docker, brew, extract

### History & Search
- **Primary tutorial:** 30 (History & Search)
- **Integrations:** 03 (Status Visualizations), 12 (DOT)
- **Plugins:** history, fzf, web-search

### Quality of Life
- **Primary tutorial:** 31 (Quality of Life)
- **Integrations:** 11 (TM Dispatcher), all tutorials
- **Plugins:** sudo, colored-man-pages, command-not-found

---

## Appendix: ADHD-Friendly Design Checklist

**Every integration must:**

- [ ] **Visual hierarchy** - Use headers, bullets, tables
- [ ] **Immediate value** - Quick win in first 60 seconds
- [ ] **Scannable** - Can skim in 30 seconds
- [ ] **Actionable** - "Try it now" actions
- [ ] **Progressive disclosure** - Collapsed sections for deep dives
- [ ] **Visual cues** - Emojis for quick identification (💡 ⚡ 🎓)
- [ ] **Cheat sheets** - One-page reference
- [ ] **Cross-references** - Links to related content
- [ ] **Examples > theory** - Show, don't tell
- [ ] **Success feedback** - "You just learned X!"

**Avoid:**
- ❌ Walls of text
- ❌ Theory before practice
- ❌ Buried information
- ❌ Multiple competing priorities
- ❌ Vague outcomes ("learn about" → "use X to do Y")

---

## Next Steps

**Recommended starting point:** Phase 1A - Tutorial 24 (Git Workflow)

**Why start here:**
- Highest impact (226 aliases)
- Aligns with Tutorial 08 (Git Feature Workflow)
- Most requested by users
- Clear, actionable content
- Natural flow-cli integration

**After Tutorial 24:**
- Tutorial 26 (Smart Suggestions) - Help beginners
- Tutorial 25 (Clipboard Magic) - Universal utility
- Then proceed with Phase 2A integrations

---

**Document Status:** Ready for implementation
**Next Review:** After Phase 1A completion
**Owner:** Flow-CLI Documentation Team
