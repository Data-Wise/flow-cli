# Flow CLI - Friction Log

**Phase:** Production Use (2025-12-24 to 2026-01-07)
**Purpose:** Document real friction points during daily usage

---

## Instructions

When you encounter friction while using flow-cli:

1. **Stop and document it immediately** (don't wait until later)
2. **Be specific** (what command, what happened, what you expected)
3. **Rate impact** (1=minor annoyance, 5=can't work)
4. **Note frequency** (one-time, occasional, every time)
5. **Record workaround** (what did you do instead?)

## Rating Guide

**Impact Scale:**

- 1/5 - Minor annoyance, barely slowed me down
- 2/5 - Noticeable friction, took extra seconds
- 3/5 - Moderate friction, took 30s-1min to work around
- 4/5 - Significant friction, took several minutes to resolve
- 5/5 - Blocker, couldn't complete task without major workaround

**Frequency:**

- One-time - Happened once, unlikely to repeat
- Occasional - Happens sometimes (< 25% of usage)
- Frequent - Happens often (25-75% of usage)
- Every time - Happens consistently (> 75% of usage)

---

## Friction Entries

### [2025-12-24] - Example Entry (DELETE THIS LATER)

**What happened:** Status command showed too much info, hard to scan quickly
**Context:** Checking project status before starting work in the morning
**Expected:** Clear "next action" at top, rest below fold
**Impact:** 3/5 (took 30 seconds to find what I needed)
**Frequency:** Every time I use `flow status`
**Workaround:** Used `flow status | grep "Next Action"` or scrolled past metrics

**Potential fix ideas:**

- Add `--brief` flag for minimal output
- Reorganize to show "Next Action" first
- Make metrics collapsible or off by default

---

### [Date] - Your First Entry

**What happened:**
**Context:**
**Expected:**
**Impact:** [1-5]
**Frequency:** [one-time / occasional / frequent / every time]
**Workaround:**

## **Potential fix ideas:**

---

## Summary (Update Weekly)

### Week 1 Summary (2025-12-24 to 2025-12-31)

**Total entries:** 0
**Critical issues (4-5 impact):** 0
**Patterns observed:**

- None yet

**Top 3 friction points:**

1.
2.
3.

---

### Week 2 Summary (2026-01-01 to 2026-01-07)

**Total entries:**
**Critical issues (4-5 impact):**
**Patterns observed:**

- **Top 3 friction points:**

1.
2.
3.

---

## Analysis (After 2 Weeks)

### High Priority (Fix These)

[Items with: Frequent/Every time + Impact 3-5]

---

### Medium Priority (Consider These)

[Items with: Occasional + Impact 3-5, OR Frequent + Impact 1-2]

---

### Low Priority (Track But Don't Act)

[Items with: One-time OR Impact 1-2]

---

## Notes

- **Be honest:** If something feels awkward, document it (even if you're not sure why)
- **No self-censoring:** Minor friction can reveal design issues
- **Context matters:** Same friction in different contexts may have different priorities
- **Workarounds are clues:** If you're using a workaround regularly, that's a real problem

**Remember:** This log drives decisions on Week 3 features. Empty log = system works well!
