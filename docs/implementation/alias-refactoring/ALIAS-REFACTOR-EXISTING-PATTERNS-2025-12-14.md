# Alias Refactoring: Extending Existing Patterns

**Date:** 2025-12-14
**Approach:** Analyze EXISTING philosophy, extend it consistently
**Goal:** Clean up, don't reinvent

---

## 🔍 Current State Analysis

### Existing Philosophy (What You Already Have)

Your current 167 aliases follow **5 distinct patterns**:

#### Pattern 1: Full Command Names

```bash
rload, rtest, rdoc, rcheck, rbuild, rcycle, rinstall
```

✅ Clear, self-documenting
✅ Easy to remember
✅ No ambiguity

#### Pattern 2: Two-Letter Shortcuts

```bash
ld='rload'      # Load (50x/day) ⚡
ts='rtest'      # Test Short (30x/day) ⚡
dc='rdoc'       # Doc (20x/day) ⚡
ck='rcheck'     # Check (10x/day) ⚡
bd='rbuild'     # Build (5x/day) ⚡
```

✅ Fast typing for frequent commands
⚠️ Hard to remember (your feedback)
⚠️ Some duplicates (dc, rd both → rdoc)

#### Pattern 3: One-Letter Ultra-Shortcuts

```bash
t='rtest'       # Most frequent R workflow action
c='claude'      # Most frequent AI tool
q='qp'          # Most frequent Quarto (preview)
```

✅ Fastest possible
⚠️ Very hard to remember (your feedback)
⚠️ High conflict potential

#### Pattern 4: Atomic Pairs (ADHD Gold)

```bash
lt='rload && rtest'      # Load then test
dt='rdoc && rtest'       # Document then test
```

✅ Two steps in one command
✅ Common workflows
✅ Easy to remember the combo

#### Pattern 5: Domain-Action (Project Tools)

```bash
# Project detection
ptype='proj-type'
pinfo='proj-info'
cctx='claude-ctx'

# Project status
pstat='~/projects/.../scanner.sh'
pstatview, pstatshow, pstatlist, pstatcount

# Notes sync
nsync='pstat && .../dashboard-applescript.sh'
nsyncview, nsyncclip, nsyncexport
```

✅ Clear domain grouping
✅ Tab completion friendly
✅ **You specifically said you like this pattern**

#### Pattern 6: Prefix Clusters

```bash
# Claude: cc*
cc, ccc, cch, cco, ccs, ccplan, ccauto, ccyolo
+ 17 prompt aliases (ccfix, ccexplain, etc.)

# Gemini: gm*
gm, gmy, gms, gmr, gme
+ 8 more variants

# Quarto: q*
qp, qr, qc, qclean
```

✅ Grouped by tool
⚠️ Some clusters too large (17 cc\* prompts)

---

## 📊 The Problem

### Conflicts & Duplicates

```bash
# Same command, multiple aliases:
rdoc = dc = rd          # 3 ways to document
rcheck = ck = rc        # 3 ways to check
rbuild = bd = rb        # 3 ways to build

# Confusing 1-letter aliases:
c='claude'              # Conflicts with cd, cp workflows
t='rtest'               # Conflicts with tmux users
q='qp'                  # Conflicts with quit in vi/less
d='dirs -v'             # Rarely used, takes valuable letter
```

### Over-Proliferation

```bash
# 17 Claude prompt aliases:
ccdoc, ccexplain, ccfix, ccoptimize, ccrefactor, etc.
# Could be replaced with: cc "your prompt"

# 13 Gemini variants:
gm, gmpi, gmy, gms, gmsd, gmyd, gmys, etc.
# Many are just flag combinations
```

---

## 🎯 Three Plans: Extending Your Existing Philosophy

---

## Plan A: Minimal Changes (Keep Most, Remove Conflicts)

**Philosophy:** Keep what works, remove only duplicates and conflicts

### What Stays (125 aliases)

#### Full R Commands (keep all)

```bash
rload, rtest, rdoc, rcheck, rbuild, rcycle, rinstall
rpkginfo, rpkgtree, rpkgclean, rpkgdown
rdeps, rdepsupdate, rdepsexplain
rspell, rcov, rcovrep
```

#### Two-Letter R Shortcuts (keep best ones)

```bash
ts='rtest'      # Keep (Test Short - clear)
rb='rbuild'     # Keep (R Build - clear)
rc='rcheck'     # Keep (R Check - clear)
rd='rdoc'       # Keep (R Doc - clear)
```

#### Atomic Pairs (keep all - ADHD gold)

```bash
lt='rload && rtest'
dt='rdoc && rtest'
```

#### Domain-Action Aliases (keep all - you like these)

```bash
# Project
ptype, pinfo, pstat, pstatview, pstatshow, pstatlist, pstatcount

# Notes
nsync, nsyncview, nsyncclip, nsyncexport

# Shortcuts
psv, psl, psc, pss, ns, nsv, nsc, nse
```

#### Claude Core (keep essential)

```bash
cc='claude'
ccc='claude -c'
ccp='claude -p'
ccr='claude -r'
ccl='claude --resume latest'

# Models
cch='claude --model haiku'
ccs='claude --model sonnet'
cco='claude --model opus'

# Modes
ccplan='claude --permission-mode plan'
ccauto='claude --permission-mode acceptEdits'
ccyolo='claude --permission-mode bypassPermissions'
```

#### Gemini Core (keep essential)

```bash
gm='gemini'
gmy='gemini --yolo'
gms='gemini --sandbox'
gmr='gemini --resume latest'
gme='gemini extensions'
```

#### Quarto (keep all)

```bash
qp='quarto preview'
qr='quarto render'
qc='quarto check'
qclean='rm -rf _site/ *_cache/ *_files/'
```

#### Git (keep all)

```bash
gs='git status -sb'
glog='git log --oneline --graph --decorate --all'
gundo='git reset --soft HEAD~1'
```

#### Typo Tolerance (keep ALL)

```bash
# All 20+ typo aliases stay
claue, cluade, clade, rlaod, rtets, gti, clera, etc.
```

### What Goes (42 aliases)

#### Remove 1-Letter Shortcuts (4)

```bash
unalias c    # Too generic, conflicts
unalias t    # Conflicts with tmux
unalias q    # Conflicts with quit
unalias d    # Rarely used
```

#### Remove Duplicate 2-Letter (4)

```bash
unalias ld   # Use: rload (clear)
unalias dc   # Use: rd (R + Doc pattern)
unalias ck   # Use: rc (R + Check pattern)
unalias bd   # Use: rb (R + Build pattern)
```

#### Remove 17 Claude Prompts (17)

```bash
unalias ccdoc, ccexplain, ccfix, ccoptimize, ccrefactor, ccreview,
        ccsecurity, cctest, ccrdoc, ccrexplain, ccrfix, ccroptimize,
        ccrrefactor, ccrstyle, ccrtest, ccjson, ccstream

# Replace with: cc "your prompt" or ccp "your prompt"
```

#### Remove 8 Gemini Variants (8)

```bash
unalias gmpi, gmsd, gmyd, gmys, gmds, gmls, gmei, gmel, gmeu, gmm, gmd

# Use flags directly: gm --debug, gme install, etc.
```

#### Remove Deprecated (3)

```bash
unalias dashsync, dashclip, dashexport
# Already warn users to use nsync*
```

#### Remove Redundant (6)

```bash
unalias aliases-claude, aliases-files, aliases-gemini,
        aliases-git, aliases-quarto, aliases-r
# Use: ah <category>
```

**Total Removed: 42**
**Remaining: 125 aliases (25% reduction)**

---

## Plan B: Standardize on Domain-Action (Your Favorite Pattern)

**Philosophy:** Extend the `proj-*` pattern you like to ALL aliases

### Migration Map

#### R Package Development

```bash
# Current → New
rload    → r-load
rtest    → r-test
rdoc     → r-doc
rcheck   → r-check
rbuild   → r-build

# Atomic pairs
lt       → r-load-test
dt       → r-doc-test

# Two-letter shortcuts: REMOVED
ts, rd, rc, rb, ld, dc, ck, bd → All removed
```

#### Quarto

```bash
# Current → New
qp       → quarto-preview  (or q-preview)
qr       → quarto-render   (or q-render)
qc       → quarto-check    (or q-check)
qclean   → quarto-clean    (or q-clean)
```

#### Claude Code

```bash
# Current → New
cc       → claude-start
ccc      → claude-continue
ccp      → claude-prompt
cch      → claude-haiku
cco      → claude-opus
ccs      → claude-sonnet
ccplan   → claude-plan
ccauto   → claude-auto
ccyolo   → claude-yolo
```

#### Gemini

```bash
# Current → New
gm       → gemini-start
gmy      → gemini-yolo
gms      → gemini-sandbox
gmr      → gemini-resume
gme      → gemini-extensions
```

#### Project (Keep as-is)

```bash
# Already perfect!
proj-status, proj-info, proj-type
pstat, pstatview, etc.
```

#### Notes (Keep as-is)

```bash
# Already follows pattern
nsync, nsyncview, nsyncclip, nsyncexport
```

**Total: ~90 aliases (46% reduction)**

---

## Plan C: Hybrid - Keep Frequency-Based Shortcuts

**Philosophy:** Keep shortcuts for high-frequency commands (10+ times/day), standardize the rest

### High-Frequency Commands (Keep Short)

Based on your comments in .zshrc:

```bash
# R Development (keep 2-letter for high freq)
ts='rtest'           # 30x/day ⚡
rd='rdoc'            # 20x/day ⚡
rc='rcheck'          # 10x/day ⚡

# Also keep full names
rload, rtest, rdoc, rcheck, rbuild

# Atomic pairs (keep - ADHD gold)
lt='rload && rtest'
dt='rdoc && rtest'

# Quarto (keep - frequently used)
qp='quarto preview'
qr='quarto render'
qc='quarto check'
```

### Medium-Frequency (Use Domain-Action)

```bash
# Claude - moderate use
claude-continue='claude -c'
claude-plan='claude --permission-mode plan'
claude-yolo='claude --permission-mode bypassPermissions'
claude-haiku='claude --model haiku'
claude-opus='claude --model opus'

# Keep ultra-short for starting
cc='claude'
```

### Low-Frequency (Use Full Commands)

```bash
# R Package utilities (use full names)
rpkginfo, rpkgtree, rpkgclean
rdeps, rdepsupdate
rcov, rcovrep

# Check variants (use full names)
rcheckfast, rcheckcran, rcheckrhub
```

### Remove Entirely

```bash
# 1-letter conflicts
unalias c, t, q, d

# Duplicate 2-letter
unalias ld, dc, ck, bd, rb

# All 17 Claude prompts
unalias ccdoc, ccexplain, etc.

# Gemini variants
unalias 8 variants

# Deprecated
unalias 3 deprecated
```

**Total: ~110 aliases (34% reduction)**

---

## 📊 Comparison Table

| Aspect             | Plan A (Minimal)          | Plan B (Standardize)              | Plan C (Hybrid)            |
| ------------------ | ------------------------- | --------------------------------- | -------------------------- |
| **Philosophy**     | Keep most, fix problems   | Extend proj- pattern              | Frequency-based            |
| **Total Aliases**  | 125                       | 90                                | 110                        |
| **Reduction**      | 25%                       | 46%                               | 34%                        |
| **R Commands**     | `rtest`, `ts`, `lt`       | `r-test`, `r-load-test`           | `rtest`, `ts`, `lt`        |
| **Claude**         | `cc`, `ccc`, `ccp`        | `claude-start`, `claude-continue` | `cc`, `claude-continue`    |
| **Quarto**         | `qp`, `qr`, `qc`          | `quarto-preview` or `q-preview`   | `qp`, `qr`, `qc`           |
| **Learning Curve** | ⭐⭐⭐⭐⭐ Minimal        | ⭐⭐ New pattern                  | ⭐⭐⭐⭐ Small changes     |
| **Consistency**    | ⭐⭐ Mixed patterns       | ⭐⭐⭐⭐⭐ One pattern            | ⭐⭐⭐ Balanced            |
| **Speed**          | ⭐⭐⭐⭐⭐ Fast shortcuts | ⭐⭐⭐ Longer typing              | ⭐⭐⭐⭐ Fast where needed |
| **Memory**         | ⭐⭐⭐ Multiple patterns  | ⭐⭐⭐⭐⭐ One pattern            | ⭐⭐⭐⭐ Logical grouping  |
| **ADHD-Friendly**  | ⭐⭐⭐⭐ Familiar         | ⭐⭐⭐⭐ Predictable              | ⭐⭐⭐⭐⭐ Best balance    |

---

## 🎯 Detailed Comparison

### Plan A: Minimal Changes

**Pros:**

- ✅ Least disruption to muscle memory
- ✅ Keep fast shortcuts you use daily (ts, rd, rc)
- ✅ Only remove obvious problems
- ✅ Can implement today, no relearning

**Cons:**

- ⚠️ Still have mixed patterns (rtest vs ts vs lt)
- ⚠️ Not addressing root cause (inconsistency)
- ⚠️ Future you might still forget which shortcut to use

**Best for:** Conservative approach, minimal risk

---

### Plan B: Standardize on Domain-Action

**Pros:**

- ✅ One consistent pattern (like proj- you like)
- ✅ Easy to remember (domain-action everywhere)
- ✅ Best tab completion
- ✅ No duplicate aliases

**Cons:**

- ⚠️ Biggest change from current
- ⚠️ Muscle memory retraining needed
- ⚠️ More typing for common commands (r-test vs ts)
- ⚠️ Might lose speed for daily work

**Best for:** Clean slate, long-term consistency

---

### Plan C: Hybrid Frequency-Based ⭐

**Pros:**

- ✅ Keep shortcuts where they matter (30x/day)
- ✅ Standardize where clarity matters (5x/day)
- ✅ Best balance of speed and memory
- ✅ Respects actual usage patterns
- ✅ Minimal muscle memory disruption

**Cons:**

- ⚠️ Still have some mixed patterns
- ⚠️ Need to remember which category (high/med/low freq)

**Best for:** Pragmatic approach, ADHD-optimized

---

## 💡 My Recommendation: **Plan C (Hybrid)** ⭐

### Why Plan C?

**1. Respects Your Current Workflow**

```bash
# Keep what you type 30 times/day:
ts          # Muscle memory is strong here
rd          # Fast, automatic
qp          # Quick preview

# Standardize what you type 5 times/day:
claude-plan      # More memorable than ccplan
gemini-sandbox   # Clearer than gms
```

**2. Frequency-Based Makes Sense**

- If you type it **30+ times/day** → shortcut is worth it
- If you type it **5 times/day** → clarity beats speed
- If you type it **once/week** → full name is fine

**3. ADHD-Friendly**

```bash
# Common tasks = muscle memory (fast)
ts, rd, qp, cc

# Rare tasks = clear names (no memory needed)
claude-yolo, gemini-sandbox, rpkginfo
```

**4. Minimal Disruption**

```bash
# Keep using today:
ts              # Still works
rd              # Still works
qp              # Still works
lt, dt          # Still works

# New additions (extend over time):
claude-plan     # When you remember
gemini-yolo     # When you need it
```

---

## 📋 Comparison: What Changes in Each Plan

### R Package Development

| Current | Plan A    | Plan B        | Plan C            |
| ------- | --------- | ------------- | ----------------- |
| `rtest` | ✅ Keep   | `r-test`      | ✅ Keep           |
| `ts`    | ✅ Keep   | ❌ Remove     | ✅ Keep (30x/day) |
| `t`     | ❌ Remove | ❌ Remove     | ❌ Remove         |
| `lt`    | ✅ Keep   | `r-load-test` | ✅ Keep           |
| `rdoc`  | ✅ Keep   | `r-doc`       | ✅ Keep           |
| `rd`    | ✅ Keep   | ❌ Remove     | ✅ Keep (20x/day) |
| `dc`    | ❌ Remove | ❌ Remove     | ❌ Remove         |

### Quarto

| Current | Plan A    | Plan B           | Plan C    |
| ------- | --------- | ---------------- | --------- |
| `qp`    | ✅ Keep   | `quarto-preview` | ✅ Keep   |
| `qr`    | ✅ Keep   | `quarto-render`  | ✅ Keep   |
| `qc`    | ✅ Keep   | `quarto-check`   | ✅ Keep   |
| `q`     | ❌ Remove | ❌ Remove        | ❌ Remove |

### Claude Code

| Current  | Plan A    | Plan B            | Plan C            |
| -------- | --------- | ----------------- | ----------------- |
| `cc`     | ✅ Keep   | `claude-start`    | ✅ Keep           |
| `ccc`    | ✅ Keep   | `claude-continue` | `claude-continue` |
| `ccplan` | ✅ Keep   | `claude-plan`     | `claude-plan`     |
| `c`      | ❌ Remove | ❌ Remove         | ❌ Remove         |
| `ccdoc`  | ❌ Remove | ❌ Remove         | ❌ Remove         |

### Gemini

| Current | Plan A    | Plan B           | Plan C           |
| ------- | --------- | ---------------- | ---------------- |
| `gm`    | ✅ Keep   | `gemini-start`   | ✅ Keep          |
| `gmy`   | ✅ Keep   | `gemini-yolo`    | `gemini-yolo`    |
| `gms`   | ✅ Keep   | `gemini-sandbox` | `gemini-sandbox` |
| `gmsd`  | ❌ Remove | ❌ Remove        | ❌ Remove        |

---

## ✅ Recommendation: Start with Plan C

### Implementation Strategy

**Week 1: Add new aliases, keep old**

```bash
# Add alongside existing
alias claude-plan='claude --permission-mode plan'
alias claude-yolo='claude --permission-mode bypassPermissions'
alias gemini-yolo='gemini --yolo'

# Both work:
ccplan          # Old way (muscle memory)
claude-plan     # New way (learning)
```

**Week 2: Start using new patterns**

```bash
# Try new ones when you remember
claude-plan     # More memorable
gemini-yolo     # Clearer intent
```

**Week 3: Remove duplicates**

```bash
# Remove what you're not using anymore
# Keep what's become muscle memory
```

---

## 🎉 Summary

**Plan A:** Minimal changes, remove duplicates (125 aliases)
**Plan B:** Full standardization on domain-action (90 aliases)
**Plan C:** ⭐ Hybrid frequency-based (110 aliases)

**Recommendation: Plan C**

- Keep fast shortcuts for daily commands (ts, rd, qp, cc)
- Standardize medium-frequency on domain-action
- Remove conflicts and duplicates
- Best balance for ADHD brain

Which plan resonates with you?
