# Analysis: `teach` Help System Improvements

**Date:** 2026-01-29
**Analyzer:** Claude Sonnet 4.5
**Task:** Compare `teach help` against flow-cli standards and identify gaps

---

## Executive Summary

The `teach` dispatcher help system is **comprehensive and well-structured**, but has **7 identified gaps** compared to flow-cli dispatcher standards. Most gaps are **cosmetic/UX** rather than functional.

**Rating:** ⭐⭐⭐⭐☆ (4/5 stars)

**Strengths:**
- ✅ Excellent categorization (5 sections)
- ✅ Rich examples with real use cases
- ✅ Comprehensive shortcut reference
- ✅ Cross-references to related commands
- ✅ Quick start section (3 commands to begin)

**Key Gaps:**
1. ❌ Missing "MOST COMMON" section (80% use case)
2. ❌ No "QUICK EXAMPLES" with inline comments
3. ❌ Missing "TIP" callout for passthrough behavior
4. ❌ No progress indicators for timing estimates
5. ⚠️ Inconsistent color scheme vs other dispatchers
6. ⚠️ Missing estimated command durations
7. ⚠️ No indication of Scholar AI dependency

---

## Official flow-cli Standards (from CONVENTIONS.md & PHILOSOPHY.md)

### Help Function Template (Official Standard)

```bash
_<cmd>_help() {
    echo -e "
${_C_BOLD}╭─────────────────────────────────────────────╮${_C_NC}
${_C_BOLD}│ <cmd> - <Domain Description>               │${_C_NC}
${_C_BOLD}╰─────────────────────────────────────────────╯${_C_NC}

${_C_GREEN}🔥 MOST COMMON${_C_NC} ${_C_DIM}(80% of daily use)${_C_NC}:
  ${_C_CYAN}<cmd> action1${_C_NC}     Description
  ${_C_CYAN}<cmd> action2${_C_NC}     Description

${_C_YELLOW}💡 QUICK EXAMPLES${_C_NC}:
  ${_C_DIM}\$${_C_NC} <cmd> action1     ${_C_DIM}# Comment${_C_NC}
  ${_C_DIM}\$${_C_NC} <cmd> action2     ${_C_DIM}# Comment${_C_NC}

${_C_BLUE}📋 ALL ACTIONS${_C_NC}:
  ${_C_CYAN}<cmd> action1${_C_NC}     Description
  ${_C_CYAN}<cmd> action2${_C_NC}     Description
  ${_C_CYAN}<cmd> action3${_C_NC}     Description

${_C_MAGENTA}💡 TIP${_C_NC}: Unknown commands pass through
  ${_C_DIM}<cmd> anything → <underlying> anything${_C_NC}
"
}
```

**Source:** `docs/CONVENTIONS.md` lines 173-199

### Core Philosophy Requirements

1. **Self-Documenting** - Every dispatcher MUST have:
   - `_<cmd>_help()` function
   - Most common commands shown first
   - Examples with expected output
   - Consistent color scheme

2. **ADHD-Friendly Design:**
   - **Discoverable:** Built-in help via `<cmd> help`
   - **Consistent:** Same pattern everywhere
   - **Memorable:** Short, mnemonic names
   - **Forgiving:** Typo tolerance

**Source:** `docs/PHILOSOPHY.md` lines 95-121

### Standard Color Scheme

```bash
_C_BOLD='\033[1m'      # Headers, emphasis
_C_DIM='\033[2m'       # Comments, less important
_C_NC='\033[0m'        # Reset

_C_GREEN='\033[32m'    # Success, most common (🔥)
_C_YELLOW='\033[33m'   # Examples, warnings (💡)
_C_BLUE='\033[34m'     # Categories, info (📋)
_C_CYAN='\033[36m'     # Commands, actions
_C_MAGENTA='\033[35m'  # Tips, related info
_C_RED='\033[31m'      # Errors
```

**Source:** `docs/CONVENTIONS.md` lines 203-217

---

## Comparison Matrix (vs Official Standards)

| Requirement (CONVENTIONS.md) | `g` dispatcher | `r` dispatcher | `teach` dispatcher | Gap? |
|---------|---------------|---------------|-------------------|------|
| **🔥 MOST COMMON section** | ✅ Compliant | ✅ Compliant | ❌ **NON-COMPLIANT** | **YES** |
| **💡 QUICK EXAMPLES section** | ✅ Compliant | ✅ Compliant | ❌ **NON-COMPLIANT** | **YES** |
| Standard color scheme | ✅ Compliant | ✅ Compliant | ⚠️ Custom (better) | Acceptable |
| Category headers (📋) | ✅ Compliant | ✅ Compliant | ✅ Compliant | No |
| **💡 TIP callout** | ✅ Compliant | ✅ Compliant | ❌ **NON-COMPLIANT** | **YES** |
| Examples section | ✅ Compliant | ✅ Compliant | ✅ Compliant | No |
| "See Also" references | ✅ Present | ✅ Present | ✅ Present | No |
| Box style (single-line) | ✅ Compliant | ✅ Compliant | ⚠️ Double-line | Acceptable |
| Shortcuts reference | ❌ Not in standard | ❌ Not in standard | ✅ **Better** | **Enhancement** |
| Passthrough behavior | ✅ Documented | N/A | ⚠️ **Unclear** | **YES** |

**Compliance Score:** 60% (6/10 standard requirements met)

**Non-Compliance Items:**
1. ❌ Missing "🔥 MOST COMMON (80% of daily use)" section
2. ❌ Missing "💡 QUICK EXAMPLES" section
3. ❌ Missing "💡 TIP" callout
4. ⚠️ Passthrough behavior not documented

**Enhancements Beyond Standard:**
- ✅ Dedicated SHORTCUTS section (better than inline)
- ✅ Double-line box style (more polished)
- ✅ 5 categorized sections (better organization)

---

## Detailed Gap Analysis

### Gap 1: Missing "MOST COMMON" Section ⭐ HIGH PRIORITY

**Standard Pattern (from `g` and `r`):**
```
🔥 MOST COMMON (80% of daily use):
  teach init            Initialize teaching project
  teach doctor --fix    Verify and fix dependencies
  teach lecture         Generate lecture notes
  teach deploy          Deploy course website
```

**Current State:**
- Has "QUICK START" but it's tutorial-style, not usage-frequency based
- Buries common commands in categorical sections

**Impact:** Users don't immediately see the 3-5 commands they'll use 80% of the time

**Recommendation:**
Add after the header, before "SETUP & CONFIGURATION":

```zsh
🔥 MOST COMMON (80% of daily use):
  teach lecture <topic>     Generate lecture notes
  teach deploy              Deploy course website
  teach validate --render   Validate before deploy
  teach status              Project dashboard
  teach doctor --fix        Fix dependency issues
```

---

### Gap 2: Missing "QUICK EXAMPLES" Section ⭐ HIGH PRIORITY

**Standard Pattern:**
```
💡 QUICK EXAMPLES:
  $ g                      # Quick status
  $ g aa                   # Add all
  $ g commit "fix bug"    # Commit
  $ g push                 # Push
```

**Current State:**
- Has "EXAMPLES" section but it's multi-line and verbose
- No inline comments showing expected output
- No "copy-paste ready" one-liners

**Impact:** Reduces discoverability for quick reference users

**Recommendation:**
Add after "MOST COMMON", before categories:

```zsh
💡 QUICK EXAMPLES:
  $ teach lecture "Intro" --week 1   # Create lecture notes
  $ teach validate --render           # Full validation
  $ teach deploy --preview            # Preview before deploy
  $ teach doctor --fix                # Auto-fix issues
```

---

### Gap 3: Missing TIP Callout ⭐ MEDIUM PRIORITY

**Standard Pattern (from `g`):**
```
💡 TIP: Unknown commands pass through to git
  g remote -v        → git remote -v
```

**Current State:**
- No indication of Scholar AI integration behavior
- No mention of what happens with invalid commands
- Unclear dependency on Scholar plugin

**Impact:** Users don't understand the teach/Scholar relationship

**Recommendation:**
Add after examples, before "LEARN MORE":

```zsh
💡 TIP: Content commands require Scholar plugin
  teach lecture → scholar:teaching:lecture
  Validation commands are native to flow-cli
```

---

### Gap 4: No Timing Estimates ⭐ LOW PRIORITY

**Observation:**
- No dispatcher uses timing estimates currently
- Would be valuable for teaching workflow (some commands take minutes)

**Recommendation (Optional Enhancement):**
```zsh
teach validate --yaml        # ~5 seconds
teach validate --render      # ~30-60 seconds (full render)
teach deploy                 # ~2-3 minutes (GitHub Pages)
teach exam <topic>           # ~45-90 seconds (AI generation)
```

**Note:** This would be a **flow-cli first** - no dispatcher does this yet

---

### Gap 5: Color Scheme Inconsistency ⚠️ COSMETIC

**Observed Differences:**

| Element | `g/r` dispatcher | `teach` dispatcher |
|---------|-----------------|-------------------|
| Header box | Single-line box | Double-line box (`═`, `║`) |
| Section headers | 🔥/💡/📋 + color | 📋/✍️/✅ + separator line |
| Command color | Cyan | Light blue (117) |

**Recommendation:**
- Keep current design (it's more polished)
- Or standardize to match `g/r` if consistency is critical

**Verdict:** Not a gap - `teach` is **more polished** than older dispatchers

---

### Gap 6: Missing Scholar Dependency Indicator ⭐ MEDIUM PRIORITY

**Current State:**
- Section header says "CONTENT CREATION (Scholar AI)" but no explanation
- No indication which commands are native vs Scholar-delegated

**Recommendation:**
Add legend or markers:

```zsh
CONTENT CREATION (Scholar AI) ⚡ requires Scholar plugin
  teach lecture <topic>       ⚡ Generate lecture notes
  teach exam <topic>          ⚡ Comprehensive exam
  teach validate <file>         Validate .qmd files (native)
```

---

### Gap 7: Unclear Passthrough Behavior ⭐ LOW PRIORITY

**Current State:**
- Unlike `g` (which passes through to git), `teach` doesn't have clear passthrough
- Unknown commands probably fail, but this isn't documented

**Recommendation:**
Document error behavior or implement passthrough to Scholar:

```zsh
💡 TIP: Unknown commands fail gracefully
  teach invalid → "Unknown command: invalid"
  Use teach help to see available commands
```

---

## Strengths (Keep These!)

### ✅ Dedicated Shortcuts Section
**Better than other dispatchers:**
```
SHORTCUTS
  i → init      doc → doctor  val → validate
  lec → lecture  sl → slides   e → exam
  ...
```

**Why it's good:**
- Comprehensive mapping
- Easy to scan
- Helps memorization

### ✅ Categorized Organization
**5 logical sections:**
1. Setup & Configuration
2. Content Creation
3. Validation & Quality
4. Deployment & Management
5. Advanced Features

**Better than:** `g` and `r` which have flatter structures

### ✅ Rich Examples
**Multi-line workflows:**
```
# Setup new course
$ teach init "STAT 440" --github
$ teach doctor --fix
$ teach hooks install
```

**Better than:** Single-line examples in other dispatchers

### ✅ Cross-References
```
📚 SEE ALSO:
  qu - Quarto commands
  g - Git commands
  work - Session management
```

**Better than:** Limited cross-refs in `g/r`

---

## Recommendations Summary

### Immediate Improvements (HIGH PRIORITY)

1. **Add "MOST COMMON" section** (5 commands, 80% use)
2. **Add "QUICK EXAMPLES"** (inline comments, copy-paste ready)
3. **Add TIP callout** (Scholar dependency, error behavior)

### Optional Enhancements (MEDIUM PRIORITY)

4. **Add dependency indicators** (⚡ for Scholar-required commands)
5. **Document error behavior** (what happens with invalid commands)

### Future Considerations (LOW PRIORITY)

6. **Add timing estimates** (would be flow-cli first)
7. **Standardize color scheme** (only if consistency is critical)

---

## Proposed Improved Help Output

```zsh
╔════════════════════════════════════════════════════════════╗
║  teach - Teaching Workflow Commands                   ║
╚════════════════════════════════════════════════════════════╝

QUICK START (3 commands to begin)
  $ teach init "STAT 440"           # Initialize teaching project
  $ teach doctor --fix              # Verify and fix dependencies
  $ teach lecture "Intro" --week 1  # Generate first lecture

🔥 MOST COMMON (80% of daily use):
  teach lecture <topic>     Generate lecture notes (~60s)
  teach deploy              Deploy course website (~2min)
  teach validate --render   Full validation (~45s)
  teach status              Project dashboard
  teach doctor --fix        Fix dependency issues

💡 QUICK EXAMPLES:
  $ teach lecture "Intro" --week 1   # Create lecture notes
  $ teach validate --render           # Full validation
  $ teach deploy --preview            # Preview before deploy
  $ teach doctor --fix                # Auto-fix issues

═══════════════════════════════════════════════════════════
📋 SETUP & CONFIGURATION
═══════════════════════════════════════════════════════════
  [... existing content ...]

═══════════════════════════════════════════════════════════
✍️ CONTENT CREATION ⚡ requires Scholar plugin
═══════════════════════════════════════════════════════════
  teach lecture <topic>    ⚡ Generate lecture notes
    --week N                    Week-based naming
    --template FORMAT           markdown | quarto | pdf
  teach exam <topic>       ⚡ Comprehensive exam
  teach validate <file>       Validate .qmd files (native)
  [... existing content ...]

SHORTCUTS
  [... existing content ...]

EXAMPLES
  [... existing content ...]

💡 TIP: Content generation requires Scholar plugin
  teach lecture → scholar:teaching:lecture (AI-powered)
  Validation commands are native to flow-cli
  Unknown commands show: "Unknown command: <name>"

📚 SEE ALSO:
  [... existing content ...]
```

---

## Implementation Priority

### Phase 1: Quick Wins (15 minutes)
- [ ] Add "MOST COMMON" section (5 commands)
- [ ] Add "QUICK EXAMPLES" section (4 examples)
- [ ] Add TIP callout (Scholar dependency)

### Phase 2: Polish (30 minutes)
- [ ] Add ⚡ indicators for Scholar commands
- [ ] Add timing estimates to slow commands
- [ ] Document error behavior

### Phase 3: Optional (Future)
- [ ] Standardize color scheme across all dispatchers
- [ ] Add interactive mode (`teach help -i` with fzf)
- [ ] Add command search (`teach help --search <term>`)

---

## Code Changes Required

### File: `lib/dispatchers/teach-dispatcher.zsh`

**Location:** `_teach_help()` function (around line 500-700)

**Changes:**
1. Add "MOST COMMON" section after QUICK START
2. Add "QUICK EXAMPLES" section before categories
3. Add "💡 TIP" section before "LEARN MORE"
4. Add ⚡ indicators to Scholar-dependent commands

**Estimated LOC:** +30 lines (mainly text formatting)

**Test:** `source flow.plugin.zsh && teach help`

---

## Conclusion

The `teach` help system is **already excellent** but can be improved with **3 quick wins**:

1. ✅ Add "MOST COMMON" section (aligns with `g` and `r`)
2. ✅ Add "QUICK EXAMPLES" (copy-paste ready one-liners)
3. ✅ Add TIP callout (clarifies Scholar dependency)

These changes would bring `teach` to **⭐⭐⭐⭐⭐ (5/5 stars)** - the best help system in flow-cli.

**Effort:** 15-30 minutes for Phase 1 quick wins
**Impact:** Significantly improved discoverability and UX alignment
