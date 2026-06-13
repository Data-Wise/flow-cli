---
tags:
  - guides
  - commands
  - adhd
---

# 📅 Agenda & Schedule Guide

!!! tldr "What this gives you"
    A single forward-looking view of everything *due soon* across all your
    projects — assignment due dates, exam dates, manuscript/grant deadlines,
    milestones, and recurring blocks — so deadlines stop living siloed in
    course configs or in your head.

`dash`, `morning`, `today`, and `week` have always been present- and
backward-looking (status, current session, wins). The **agenda layer** adds the
missing forward-looking dimension, driven by one shared engine
(`lib/schedule.zsh`). It works fully **without atlas** and **without `yq`**.

---

## The `agenda` command

```bash
agenda                # Next 7 days + overdue (default)
agenda today          # Due today + overdue
agenda -w / --week    # Next 7 days (same as default)
agenda -m / --month   # Next 30 days (adds a LATER bucket)
agenda --all          # Everything, including holidays
agenda --overdue      # Overdue items only
agenda <category>     # Filter: dev | r | research | teach | quarto | apps
agenda -h             # Help
```

Items are grouped into **OVERDUE → TODAY → THIS WEEK → LATER** buckets, with
overdue surfaced loudly (🔥 colors first) and a calm empty state when nothing
is due:

```
  📅 AGENDA (next 7 days)

  OVERDUE (1)
  🔬 overdue 3d  Submit JRSS-B revision (manuscript-x)

  TODAY (1)
  📌 today       Project beta milestone (app-y)

  THIS WEEK (2)
  🔬 in 2d       Advisor meeting 🔁 (study-z)
  🔁 in 4d       Grading window (stat-101)

  4 items • 'agenda -h' for options
```

### Aliases

| Alias | Expands to |
|-------|-----------|
| `agt` | `agenda today` |
| `agw` | `agenda -w` |
| `agm` | `agenda -m` |

!!! note "Why not `ag`?"
    `ag` collides with the silver-searcher binary, so the aliases are
    `agt`/`agw`/`agm`.

---

## Where items come from

### 1. `## Schedule:` in a project's `.STATUS` (no `yq` needed)

Add a `## Schedule:` section to any project's `.STATUS` file:

```markdown
## Schedule:
- 2026-06-20 | Submit JRSS-B revision | research
- 2026-07-01 | Project beta milestone | general
- weekly:fri | Grading window | recurring
- weekly:mon | Advisor meeting | research
```

Grammar — one list item per line:

```
- <when> | <label> [| <type>]
```

| Field | Values |
|-------|--------|
| `when`  | ISO date `YYYY-MM-DD`, or a recurring token `weekly:<dow>` (`mon`…`sun`) |
| `label` | Free text (must not contain `\|`) |
| `type`  | `teaching` · `research` · `general` · `recurring` (optional) |

If `type` is omitted it defaults to `general` for dated items and `recurring`
for `weekly:` tokens. The **project** is inferred from the directory name.
Unknown tokens are skipped silently — never fatal.

Recurring `weekly:<dow>` tokens are expanded into concrete dates within the
view's window (correctly across month and year boundaries).

### 2. Teaching dates from `.flow/teach-config.yml` (automatic)

For teaching projects, week start dates, exams, deadlines, and holidays are
read straight from your existing `.flow/teach-config.yml` via the teaching date
engine — no re-entry. This path uses `yq`; if `yq` is absent the rest of the
agenda still works, the teaching items are just skipped.

!!! warning "`weeks[].start_date` required"
    The teaching date loader reads `semester_info.weeks[].start_date`. A config
    that only has `weeks[].date` yields no week items.

Holidays are typed `holiday` and hidden unless you pass `--all`.

---

## Icons

| Icon | Meaning |
|------|---------|
| 🎓 | teaching |
| 🔬 | research |
| 📌 | general |
| 🔁 | recurring |
| 🏖️ | holiday (only with `--all`) |

A trailing 🔁 also flags a recurring item whose *type* isn't `recurring`
(e.g. a research weekly block).

---

## Where the schedule shows up

The same engine feeds every surface, so they all render consistently:

| Surface | What it adds |
|---------|--------------|
| `dash` | **UPCOMING** section (after QUICK WINS) — next 4 items, 7d + overdue; self-suppresses when empty. |
| `morning` | **Upcoming (next 7 days)** block — top 5; `morning -q` adds a `📅 N due soon` one-liner. |
| `today` | **📅 Due today** — today + overdue (window 0). |
| `week` | **📅 This week's deadlines** — 7 days, grouped by weekday (overdue first). |

Results are cached per session (date + window keyed, ~10 min TTL), so running
`agenda` and then `dash` reuses the work.

---

## Atlas integration (optional)

When atlas is installed **and** exposes a `schedule` subcommand, `agenda` pushes
the collected items opportunistically and asynchronously
(`atlas schedule push --format=json`). When atlas is absent — or present but
without that subcommand — the push is a silent no-op. flow-cli owns the model;
atlas is just a sync target. See [ATLAS-CONTRACT](../ATLAS-CONTRACT.md).

---

## Examples

```bash
# Morning triage: what's on fire?
agenda --overdue

# Plan the month for a single research project
agenda -m research

# Quick glance without leaving your flow
agt            # just today
agw            # this week
```
