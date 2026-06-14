---
tags:
  - tutorials
  - commands
  - adhd
---

# Tutorial 48: Forward-Looking Schedule (`agenda`)

> **What you'll build:** a working `## Schedule:` block that drives a single
> forward-looking view of everything due across your projects — surfaced by
> `agenda` and woven into `dash`, `morning`, `today`, and `week`.
>
> **Time:** ~15 minutes | **Level:** Beginner

---

## Prerequisites

Before starting, you should:

- [ ] Have flow-cli installed (`brew install data-wise/tap/flow-cli`)
- [ ] Have at least one project with a `.STATUS` file (or follow along in any repo)
- [ ] Know the basics of `dash` — see [Tutorial 01](01-first-session.md)

**Verify your setup:**

```bash
agenda -h
# Expected: the agenda help screen (options, filters, legend)
```

If `agenda` isn't found, update: `brew upgrade data-wise/tap/flow-cli` (agenda
landed in v7.10.0).

---

## What You'll Learn

By the end of this tutorial, you will:

1. **Add** dated and recurring items to a project's `## Schedule:` block
2. **Run** `agenda` and its windows/filters to see what's due
3. **Recognize** how the same items surface in `dash`, `morning`, `today`, `week`

---

## Overview

`dash`, `morning`, `today`, and `week` are present- and backward-looking: status,
current session, wins. They answer *"where am I?"* — never *"what's coming?"*.

The **agenda layer** adds the forward-looking dimension. One engine
(`lib/schedule.zsh`) reads dated items from two sources, merges them, and renders
them everywhere consistently. It works fully **without atlas** and **without
`yq`**.

```text
  .STATUS  "## Schedule:"  ─┐
                            ├─►  schedule engine  ─►  agenda / dash / morning / today / week
  .flow/teach-config.yml  ─┘        (one source of truth, many surfaces)
```

---

## Part 1: Your First Agenda

### Step 1.1: Run it empty

Before adding anything, see the calm empty state:

```bash
agenda
```

**What happened:** with nothing scheduled you get a quiet "nothing due" message,
not a wall of noise. That calm-when-empty behavior is deliberate.

### Step 1.2: Add a `## Schedule:` block

Open a project's `.STATUS` and add a `## Schedule:` section. The grammar is one
list item per line — **no `yq`, no special tooling**:

```markdown
## Schedule:
- 2026-06-20 | Submit JRSS-B revision | research
- 2026-06-21 | Project beta milestone | general
```

The line grammar is:

```text
- <when> | <label> [| <type>]
```

| Field | Values |
|-------|--------|
| `when`  | ISO date `YYYY-MM-DD`, or a recurring token `weekly:<dow>` |
| `label` | Free text (must not contain a literal `\|`) |
| `type`  | `teaching` · `research` · `general` · `recurring` (optional) |

> **Tip:** Use dates a few days in the future so they land in the 7-day window.
> If `type` is omitted it defaults to `general` for dated items.

### Step 1.3: Run it again

```bash
agenda
```

**What happened:** your two items now appear, grouped into buckets and tagged
with type icons (🔬 research, 📌 general). The project name is inferred from the
directory — you didn't have to type it.

### Checkpoint

At this point you should have:

- [x] A `## Schedule:` block in one project's `.STATUS`
- [x] `agenda` showing those items under **THIS WEEK**

**Verify:**

```bash
agenda
# Expected: a "📅 AGENDA (next 7 days)" header with your items listed
```

---

## Part 2: Windows, Recurring Blocks, and Filters

### Step 2.1: Change the window

Agenda defaults to the next 7 days + anything overdue. Widen or narrow it:

```bash
agenda today        # due today + overdue only
agenda -w           # next 7 days (same as default)
agenda -m           # next 30 days (adds a LATER bucket)
agenda --overdue    # ONLY things past due — your "what's on fire?" view
agenda --all        # everything, including holidays
```

### Step 2.2: Add a recurring block

Recurring items use a `weekly:<dow>` token (`mon`…`sun`) instead of a date:

```markdown
## Schedule:
- 2026-06-20 | Submit JRSS-B revision | research
- 2026-06-21 | Project beta milestone | general
- weekly:fri | Grading window | recurring
- weekly:mon | Advisor meeting | research
```

```bash
agenda -m
```

**What happened:** the engine expands each `weekly:` token into concrete dates
inside the window (correctly across month and year boundaries). The advisor
meeting is typed `research` but still gets a trailing 🔁 to flag that it recurs.

### Step 2.3: Filter by type or category

A filter argument matches either an item's **type** or the project's detected
**category** — whichever hits first:

```bash
agenda research     # every item tagged "| research", in ANY project
agenda recurring    # just the recurring blocks
agenda teach        # items in teaching-category projects ("teaching" works too)
```

> **Note:** `agenda research` finds a manuscript deadline even if you keep it in
> a `dev`-category repo — the type tag wins.

### Checkpoint

**Verify:**

```bash
agenda --overdue    # should list only past-due items (maybe none — that's good)
agenda recurring    # should show your weekly: blocks expanded to dates
```

---

## Part 3: It Shows Up Everywhere

You don't have to run `agenda` explicitly — the same engine feeds your daily
commands.

### Step 3.1: `dash` UPCOMING

```bash
dash
```

**What happened:** a new **UPCOMING** section appears after QUICK WINS (next 4
items, 7 days + overdue). It **self-suppresses** when nothing is due, so it never
adds noise.

### Step 3.2: Cadence commands

```bash
morning      # adds an "Upcoming (next 7 days)" block (top 5)
morning -q   # quick mode → a one-line "📅 N due soon"
today        # adds "📅 Due today" (today + overdue)
week         # adds "📅 This week's deadlines", grouped by weekday
```

### Step 3.3: The aliases

For glance-speed, three aliases skip the typing:

| Alias | Expands to |
|-------|-----------|
| `agt` | `agenda today` |
| `agw` | `agenda -w` |
| `agm` | `agenda -m` |

> **Note:** there's deliberately no `ag` — it collides with the silver-searcher
> binary.

### Understanding the two data sources

| Source | Needs `yq`? | What it provides |
|--------|-------------|------------------|
| `## Schedule:` in `.STATUS` | No | Your hand-entered deadlines + recurring blocks |
| `.flow/teach-config.yml` | Yes | Teaching weeks, exams, deadlines, holidays (auto) |

For teaching projects, dates come straight from your existing course config — no
re-entry. (If `yq` is absent, the teaching items are simply skipped and
everything else still works.)

### Checkpoint

**Verify:**

```bash
dash
# Expected: an UPCOMING section listing your nearest items (or no section if none)
```

---

## Putting It All Together

```bash
# Morning triage: what's on fire, then what's today
agenda --overdue
agt

# Plan a single research project for the month
agenda -m research

# Glance from inside your daily flow — no extra command
dash            # UPCOMING section
morning -q      # one-line count
```

**Result:** every dated commitment across your projects in one place, surfaced
right where you already look.

---

## Exercises

### Exercise 1 (Easy)

Add a deadline three days from now and confirm it appears under **THIS WEEK**.

<details>
<summary>Solution</summary>

```markdown
## Schedule:
- <a-date-3-days-out> | Draft outline due | general
```

```bash
agenda
```
</details>

### Exercise 2 (Medium)

Add a weekly research block and show *only* recurring items.

<details>
<summary>Solution</summary>

```markdown
- weekly:wed | Lab meeting | research
```

```bash
agenda recurring
# the lab meeting appears with a 🔁 flag
```
</details>

### Exercise 3 (Challenge)

Put a manuscript deadline (`| research`) in a non-research project, then prove
the type filter finds it regardless of project category.

<details>
<summary>Solution</summary>

```bash
# In any project's .STATUS:
#   - 2026-07-15 | Submit revision | research
agenda research      # shows it, even from a dev/quarto/apps project
```
</details>

---

## Common Issues

### "My items don't show up"

**Cause:** the dates are outside the window, or the line grammar is off.

**Fix:** widen the window (`agenda -m` or `agenda --all`) and check each line is
`- <when> | <label> [| <type>]` with real ` | ` separators (space-pipe-space).
Malformed lines are skipped silently, never fatal.

### "My `weekly:` block isn't appearing"

**Cause:** the token's day-of-week doesn't fall inside the current window, or the
dow spelling is off.

**Fix:** use `mon`…`sun`, and widen with `agenda -m`.

### "Teaching dates are missing"

**Cause:** either `yq` isn't installed, or the config uses `weeks[].date` instead
of `weeks[].start_date`.

**Fix:** install `yq` (`brew install yq`) and ensure
`semester_info.weeks[].start_date` is set. See the
[Agenda & Schedule Guide](../guides/AGENDA-SCHEDULE-GUIDE.md).

---

## Summary

| Concept | What You Did |
|---------|--------------|
| `## Schedule:` block | Added dated + recurring items to `.STATUS` |
| Windows | Switched between today / week / month / overdue / all |
| Filters | Narrowed by item **type** or project **category** |
| Surfaces | Saw items in `dash`, `morning`, `today`, `week` |

**Key commands:**

```bash
agenda             # next 7 days + overdue
agenda --overdue   # only what's past due
agenda -m research # 30-day window, research items
agt / agw / agm    # today / week / month aliases
```

---

## Next Steps

Continue your learning:

1. **[Agenda & Schedule Guide](../guides/AGENDA-SCHEDULE-GUIDE.md)** — the full
   reference (icons, caching, atlas push, every flag)
2. **[ADHD Daily Routine](43-adhd-daily-routine.md)** — fold `agenda` into a
   morning/evening rhythm
3. **[Quick Capture](44-quick-capture.md)** — capture a deadline the moment it
   lands

---

## Quick Reference

```text
┌─────────────────────────────────────────────────────────────┐
│  AGENDA QUICK REFERENCE                                      │
├─────────────────────────────────────────────────────────────┤
│  agenda            next 7 days + overdue (default)          │
│  agenda today      due today + overdue        (agt)        │
│  agenda -w         next 7 days                 (agw)        │
│  agenda -m         next 30 days                (agm)        │
│  agenda --overdue  only past-due items                      │
│  agenda --all      everything, incl. holidays              │
│  agenda <filter>   by type or project category             │
├─────────────────────────────────────────────────────────────┤
│  .STATUS line:  - <when> | <label> [| <type>]              │
│  when:  YYYY-MM-DD   or   weekly:<mon..sun>                │
│  types: teaching 🎓  research 🔬  general 📌  recurring 🔁   │
├─────────────────────────────────────────────────────────────┤
│  Also surfaces in: dash (UPCOMING) · morning · today · week │
└─────────────────────────────────────────────────────────────┘
```
