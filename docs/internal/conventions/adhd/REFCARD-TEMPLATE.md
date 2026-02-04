# Reference Card Template

> **Use this template** for quick-lookup reference cards. One page, no scrolling, instant answers.

---

## When to Use

| Guide Type | Purpose | Format |
|------------|---------|--------|
| QUICK-START | Get running | Prose + commands |
| GETTING-STARTED | Learn basics | Structured sections |
| TUTORIAL | Deep learning | Step-by-step |
| **REFCARD** | Quick lookup | Tables + boxes |

**Refcards are for:** Users who already know the tool but need quick reminders.

---

## Design Principles

1. **One page** — No scrolling (print-friendly)
2. **Scannable** — Tables and boxes, not paragraphs
3. **No explanations** — Just commands and syntax
4. **Grouped logically** — By task, not alphabetically
5. **Most-used first** — Common commands at top

---

## Template: ASCII Box Style

````markdown
# [Tool Name] Reference Card

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  [TOOL NAME] REFERENCE CARD                                        v[X.X]  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ESSENTIAL                           │  [CATEGORY 2]                        │
│  ─────────                           │  ────────────                        │
│  [cmd]      [description]            │  [cmd]      [description]            │
│  [cmd]      [description]            │  [cmd]      [description]            │
│  [cmd]      [description]            │  [cmd]      [description]            │
│                                      │  [cmd]      [description]            │
│  [CATEGORY 1]                        │                                      │
│  ────────────                        │  [CATEGORY 3]                        │
│  [cmd]      [description]            │  ────────────                        │
│  [cmd]      [description]            │  [cmd]      [description]            │
│  [cmd]      [description]            │  [cmd]      [description]            │
│  [cmd]      [description]            │  [cmd]      [description]            │
│                                      │                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│  PATTERNS                                                                   │
│  [pattern]                    [what it does]                                │
│  [pattern]                    [what it does]                                │
├─────────────────────────────────────────────────────────────────────────────┤
│  TIPS: [tip 1] • [tip 2] • [tip 3]                                          │
└─────────────────────────────────────────────────────────────────────────────┘
```
````

---

## Template: Markdown Table Style

````markdown
# [Tool Name] Reference Card

> **Version:** X.X | **Last Updated:** YYYY-MM-DD

---

## Essential Commands

| Command | Description |
|---------|-------------|
| `[cmd]` | [description] |
| `[cmd]` | [description] |
| `[cmd]` | [description] |

---

## [Category 1]

| Command | Description |
|---------|-------------|
| `[cmd]` | [description] |
| `[cmd]` | [description] |

## [Category 2]

| Command | Description |
|---------|-------------|
| `[cmd]` | [description] |
| `[cmd]` | [description] |

---

## Common Patterns

```bash
# [Pattern name]
[command pattern]

# [Pattern name]
[command pattern]
```

---

## Quick Tips

- [Tip 1]
- [Tip 2]
- [Tip 3]
````

---

## Template: Compact Grid Style

````markdown
# [Tool Name] Refcard

| Essential | Navigation | Editing |
|-----------|------------|---------|
| `[cmd]` [desc] | `[cmd]` [desc] | `[cmd]` [desc] |
| `[cmd]` [desc] | `[cmd]` [desc] | `[cmd]` [desc] |
| `[cmd]` [desc] | `[cmd]` [desc] | `[cmd]` [desc] |

| Files | Search | Git |
|-------|--------|-----|
| `[cmd]` [desc] | `[cmd]` [desc] | `[cmd]` [desc] |
| `[cmd]` [desc] | `[cmd]` [desc] | `[cmd]` [desc] |

**Patterns:** `[pattern]` • `[pattern]` • `[pattern]`
````

---

## Example: Project Hub Refcard

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  PROJECT HUB REFERENCE CARD                                         v1.0   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  DAILY                               │  NAVIGATION                          │
│  ─────                               │  ──────────                          │
│  focus (f)    Today's priorities     │  hub view       Master dashboard     │
│  week (wk)    This week's plan       │  hub cd         Go to project-hub    │
│                                      │  hub open       Open in Finder       │
│  DOMAIN HUBS                         │  hub edit       Edit dashboard       │
│  ───────────                         │                                      │
│  devhub (dh)  Dev tools hub          │  UTILITIES                           │
│  rhub (rh)    R packages hub         │  ─────────                           │
│                                      │  hub-new-week   Create weekly file   │
│  SUBCOMMANDS                         │                                      │
│  ───────────                         │  FILES                               │
│  view (v)     Display dashboard      │  ─────                               │
│  edit (e)     Open in editor         │  .STATUS        Today's focus        │
│  open (o)     Open in Finder         │  PROJECT-HUB.md Main dashboard       │
│  cd (c)       Change directory       │  TODOS.md       Task list            │
│  todos (t)    Show task list         │  weekly/        Weekly plans         │
│                                      │                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│  WORKFLOW: focus → hub view → [domain]hub cd → work                         │
├─────────────────────────────────────────────────────────────────────────────┤
│  TIPS: Use aliases (f, wk, dh, rh) • All hubs have same subcommands         │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Example: Git Refcard (Compact)

```markdown
# Git Refcard

| Basics | Branches | Remote |
|--------|----------|--------|
| `gs` status | `gb` list | `gp` push |
| `ga .` add all | `gco -b` new | `gl` pull |
| `gc "msg"` commit | `gco name` switch | `gf` fetch |
| `gd` diff | `gm branch` merge | `gr` remote -v |

| History | Stash | Undo |
|---------|-------|------|
| `glog` pretty log | `gst` stash | `gco -- file` |
| `gsh` show | `gstp` pop | `grh HEAD~1` |
| `gbl` blame | `gstl` list | `grs file` |

**Patterns:** `ga . && gc "msg" && gp` • `gf && gm origin/main`
```

---

## Formatting Guidelines

### Command Width

```
SHORT (≤6 chars)     Align descriptions at column 20
MEDIUM (7-12 chars)  Align descriptions at column 25
LONG (>12 chars)     Put description on next line or use table
```

### Descriptions

| Good | Bad |
|------|-----|
| "Show status" | "This command shows the current status" |
| "List branches" | "Lists all branches in the repository" |
| "Push to remote" | "Pushes your commits to the remote" |

**Rules:**
- Start with verb
- 2-4 words max
- No articles (a, the)
- No ending punctuation

### Grouping

Group by **task**, not alphabetically:

```
GOOD                    BAD
─────                   ─────
DAILY                   A
  focus                   add
  week                  B
NAVIGATION                blame
  hub cd                  branch
  hub view              C
                          checkout
                          commit
```

---

## Size Guidelines

| Format | Max Items | Notes |
|--------|-----------|-------|
| ASCII Box | ~30 commands | Best for printing |
| Markdown Tables | ~40 commands | Good for scrolling |
| Compact Grid | ~50 commands | Dense but scannable |

**If you have more:** Split into multiple refcards by topic.

---

## ADHD-Friendly Tips

1. **Visual hierarchy** — Most-used commands at top-left
2. **Consistent structure** — Same layout across all refcards
3. **Aliases shown** — Include shortcuts in parentheses
4. **One workflow line** — Show the typical pattern
5. **Print-friendly** — Keep to one page

---

## Checklist for New Refcards

- [ ] Fits on one page (80 cols × 40 lines for ASCII)
- [ ] Essential/most-used commands first
- [ ] Grouped by task, not alphabet
- [ ] Descriptions are 2-4 words
- [ ] Aliases included
- [ ] At least one workflow pattern shown
- [ ] Version number included
- [ ] No explanatory prose
