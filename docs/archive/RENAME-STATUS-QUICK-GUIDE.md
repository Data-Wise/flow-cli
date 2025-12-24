# Rename "status" - Quick Visual Guide

**TL;DR:** Replace `status` with `up` (ultra-short verb, saves keystrokes, eliminates confusion)

---

## The Problem (One Image)

```
┌────────────────────────────────────────────────────────────┐
│                                                            │
│  YOU TYPE:    status mediationverse                        │
│                                                            │
│  YOU THINK:   "Show me the status"        👀 (READ)        │
│                                                            │
│  IT DOES:     "Update status prompt"      ✍️  (WRITE!)     │
│                                                            │
│  RESULT:      Confusion! 😵                                │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

**Issue:** NOUN looks like READ, but does WRITE

---

## The Solution (One Command)

```
┌────────────────────────────────────────────────────────────┐
│                                                            │
│  BEFORE:      status mediationverse     (6 chars, noun)    │
│                                                            │
│  AFTER:       up mediationverse         (2 chars, VERB!)   │
│                                                            │
│  SAVINGS:     4 keystrokes + zero confusion                │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## Complete Migration (Three Commands)

| Action     | OLD (confusing)                | NEW (clear)         | Savings  |
| ---------- | ------------------------------ | ------------------- | -------- |
| **Show**   | `status X --show` (16 chars)   | `dash X` (9 chars)  | -7 chars |
| **Update** | `status X` (9 chars)           | `up X` (5 chars)    | -4 chars |
| **Create** | `status X --create` (18 chars) | `pinit X` (9 chars) | -9 chars |

**Daily savings:** ~30 keystrokes (5 updates × 4 + 2 shows × 7)

---

## Why "up" Wins (Five Reasons)

1. **Ultra-short:** 2 chars (like `js`, `lt`)
2. **Clear verb:** "up" = "update" (obvious action)
3. **No conflicts:** Not used by major tools
4. **Matches pattern:** Your other commands are verbs (`work`, `finish`, `js`)
5. **ADHD-perfect:** Fast, clear, zero ambiguity

**Score:** 47/50 (vs current: 23/50)

---

## Test Drive (30 Seconds)

```bash
# Add to your shell (test for 1 week)
alias up='status'
alias pinit='status --create'

# Try it
up mediationverse                  # Does this feel natural?
dash mediationverse                # Is this intuitive?
pinit newproj                      # Is this clear?
```

If yes after 1 week → Implement permanently

---

## Full Implementation (1 Hour)

**Step 1:** Create `/Users/dt/.config/zsh/functions/up.zsh`

- Copy from `status.zsh`
- Remove `--show` logic (use `dash` instead)
- Remove `--create` logic (move to `pinit`)

**Step 2:** Create `/Users/dt/.config/zsh/functions/pinit.zsh`

- Extract `--create` logic from `status.zsh`

**Step 3:** Update `/Users/dt/.config/zsh/functions/dash.zsh`

- Add single-project mode if not exists

**Step 4:** Source new functions in `.zshrc`

**Step 5:** Test everything

**Step 6:** Add deprecation warning to `status`

**Step 7:** Update docs, remove `status` after 2 weeks

---

## Before/After (Daily Workflow)

### Morning Routine

```bash
# BEFORE
dash                               # Show all
status medfit                      # Update (confusing name)
work medfit                        # Start

# AFTER
dash                               # Show all
up medfit                          # Update (clear verb!)
work medfit                        # Start
```

### Quick Update

```bash
# BEFORE
status medfit active P1 "Add tests" 75

# AFTER
up medfit active P1 "Add tests" 75
```

---

## Pattern Consistency Check

```
Your Successful Commands (All Verbs):
├── work <name>                    ✅ Verb
├── finish [msg]                   ✅ Verb
├── js                             ✅ Verb
└── dash                           ⚠️  Noun (but read-only = OK)

The Outlier:
└── status <name>                  ❌ Noun (but modifies = BAD)

Fixed:
└── up <name>                      ✅ Verb (matches pattern!)
```

---

## Research Summary

**Analyzed:** 7 major CLI tools (Git, GitHub CLI, npm, tmux, cargo, kubectl, taskwarrior)

**Finding:** Best tools use VERBS for actions

**Examples:**

- Git: `add`, `commit`, `push` (verbs)
- cargo: `build`, `update`, `test` (verbs)
- taskwarrior: `add`, `modify`, `done` (verbs)

**Exception:** Git's `status` is READ-ONLY (you're breaking this rule!)

---

## Alternatives (If You Don't Like "up")

| Option         | Command       | Length   | Clarity | Score    |
| -------------- | ------------- | -------- | ------- | -------- |
| **D** (winner) | `up`          | 2 chars  | 9/10    | 47/50 ✅ |
| **E**          | `set`         | 3 chars  | 8/10    | 43/50    |
| **B**          | `pup`         | 3 chars  | 7/10    | 38/50    |
| **A**          | `pupdate`     | 7 chars  | 9/10    | 36/50    |
| **C**          | `proj update` | 11 chars | 9/10    | 31/50    |

---

## Decision Flowchart

```
Do you value speed? ──────────────────────────────┐
                                                  │
                                                 YES
                                                  │
                                                  ▼
                                           Use "up" (2 chars)

Do you value clarity? ────────────────────────────┐
                                                  │
                                                 YES
                                                  │
                                                  ▼
                                   "up" is clear enough? ──── YES ──▶ Use "up"
                                                  │
                                                 NO
                                                  │
                                                  ▼
                                           Use "pupdate" (7 chars)

Do you want Git-style? ───────────────────────────┐
                                                  │
                                                 YES
                                                  │
                                                  ▼
                                           Use "set" (3 chars)
```

**Recommendation:** 95% of users should choose "up"

---

## Risk Assessment

| Risk                    | Likelihood | Impact | Mitigation           |
| ----------------------- | ---------- | ------ | -------------------- |
| Conflicts with `uptime` | Low        | Low    | Different context    |
| Hard to discover        | Low        | Low    | Help system, docs    |
| Muscle memory issues    | Medium     | Low    | 1-week test period   |
| Regret choice           | Low        | Low    | Rollback plan exists |

**Overall risk:** LOW (safe to proceed)

---

## Success Metrics

After 1 week of testing, ask:

- [ ] Does `up` feel natural?
- [ ] Is it faster than `status`?
- [ ] Do I forget what it means?
- [ ] Any muscle memory conflicts?
- [ ] Would I recommend this change?

If 4/5 = YES → Implement permanently

---

## Documentation Links

**Full research:** 5 comprehensive documents

1. `CLI-COMMAND-PATTERNS-RESEARCH.md` - Main analysis (9,500 words)
2. `STATUS-COMMAND-ALTERNATIVES.md` - Visual guide (3,800 words)
3. `COMMAND-RENAME-IMPLEMENTATION.md` - Action plan (4,200 words)
4. `COMMAND-RESEARCH-SUMMARY.md` - Quick ref (2,500 words)
5. `DECISION-MATRIX.md` - Comparison (3,200 words)

**Index:** `COMMAND-RESEARCH-INDEX.md` (navigation guide)

**Location:** `/Users/dt/projects/dev-tools/flow-cli/`

---

## Bottom Line

```
╔═══════════════════════════════════════════════════════╗
║                                                       ║
║  Replace:  status <project>                           ║
║                                                       ║
║  With:     up <project>                               ║
║                                                       ║
║  Why:      - 2 chars (3x faster)                      ║
║            - Clear verb (zero confusion)              ║
║            - ADHD-friendly (47/50 score)              ║
║            - Matches pattern (work, finish, js)       ║
║            - Saves 30 keystrokes/day                  ║
║                                                       ║
║  Next:     alias up='status'  (test 1 week)           ║
║                                                       ║
╚═══════════════════════════════════════════════════════╝
```

---

## Quick Commands

```bash
# Test (now)
alias up='status'
alias pinit='status --create'

# Use (1 week)
up mediationverse
dash mediationverse
pinit newproj

# Implement (if good)
# See COMMAND-RENAME-IMPLEMENTATION.md for steps

# Revert (if bad)
unalias up
unalias pinit
# Keep using status
```

---

**One sentence:** Replace confusing multi-mode `status` with ultra-short verb `up` - saves keystrokes and mental energy.
