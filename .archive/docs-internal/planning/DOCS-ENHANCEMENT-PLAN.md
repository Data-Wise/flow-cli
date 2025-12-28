# Documentation Enhancement Plan

**Created:** 2025-12-27
**Status:** Phase 4 Nearly Complete (only video/GIF content pending)
**Priority:** High

---

## Executive Summary

The flow-cli documentation site has 166 markdown files but suffers from:

1. **Missing core command docs** - `work`, `finish`, `hop` not documented
2. **Outdated content** - Still references Node.js CLI, old paths
3. **No v4.0 tutorials** - Dopamine features, sync command undocumented
4. **Cluttered reference section** - 15+ docs, hard to navigate
5. **No FAQ or Troubleshooting hub**

---

## Quick Wins (< 30 min each)

### 1. ⚡ Add Missing Core Command Docs

**Priority:** Critical - these are the most-used commands!

| Command   | File to Create             | Content                          |
| --------- | -------------------------- | -------------------------------- |
| `work`    | `docs/commands/work.md`    | Start session, project detection |
| `finish`  | `docs/commands/finish.md`  | End session, auto-commit         |
| `hop`     | `docs/commands/hop.md`     | Quick project switch (tmux)      |
| `capture` | `docs/commands/capture.md` | catch, crumb, win, yay           |
| `timer`   | `docs/commands/timer.md`   | Focus timer, pomodoro            |
| `morning` | `docs/commands/morning.md` | Daily routine commands           |
| `pick`    | `docs/commands/pick.md`    | Project picker                   |
| `flow`    | `docs/commands/flow.md`    | Main dispatcher                  |

**Template:**

```markdown
# command-name

> Brief description

## Usage

\`\`\`bash
command [options] [args]
\`\`\`

## Options

| Flag | Description |
| ---- | ----------- |

## Examples

\`\`\`bash

# Example 1

command arg

# Example 2

command --option
\`\`\`

## See Also

- Related command
```

### 2. ⚡ Update Quick Start for v4.0

**File:** `docs/getting-started/quick-start.md`

**Issues:**

- References Node.js CLI (removed in v3.0)
- Mentions `~/.config/zsh/functions/` (legacy)
- Missing dopamine features
- Missing dispatchers

**Changes:**

- Remove Node.js references
- Add `work → finish` flow
- Add `win` command mention
- Update installation paths

### 3. ⚡ Fix Outdated Version References

Search and replace across docs:

- "v3.2.0" → "v4.0.1" where appropriate
- Remove "Node.js" references
- Update architecture descriptions

---

## Medium Effort (1-2 hours)

### 4. 🔧 New Tutorial: Dopamine Features

**File:** `docs/tutorials/06-dopamine-features.md`

**Content:**

1. Introduction to win tracking
2. Setting daily goals
3. Viewing streaks
4. Win categories
5. Weekly summaries

**Why:** v4.0's flagship feature is undocumented in tutorials!

### 5. 🔧 New Tutorial: Sync Command

**File:** `docs/tutorials/07-sync-command.md`

**Content:**

1. What sync does
2. Sync targets (session, status, wins, goals, git)
3. Smart sync vs full sync
4. Scheduled sync setup

### 6. 🔧 Reorganize Reference Section

**Current:** 15 docs, overwhelming

**Proposed Structure:**

```
Reference:
  - Quick References:
      - Command Quick Ref
      - Alias Reference Card
      - Workflow Quick Ref
  - Dispatchers:
      - Dispatcher Overview
      - CC Dispatcher
  - Deep Dives:
      - Project Detection
      - ADHD Helpers Map
```

### 7. 🔧 Create FAQ Page

**File:** `docs/getting-started/faq.md`

**Sections:**

- Installation issues
- "Command not found" fixes
- Atlas integration questions
- Performance concerns
- ADHD-specific tips

---

## Larger Improvements (2+ hours)

### 8. 🏗️ Interactive Command Explorer

Enhance `docs/reference/COMMAND-EXPLORER.md`:

- Add search/filter functionality
- Group by category (workflow, capture, time, etc.)
- Include all 28 aliases
- Add "copy to clipboard" for commands

### 9. 🏗️ Video/GIF Tutorials

Create visual guides:

- `work → dash → finish` workflow
- Dashboard TUI navigation
- Win tracking in action

### 10. 🏗️ Changelog Page

**File:** `docs/CHANGELOG.md`

Auto-generated from git tags or manually maintained.
Current "Recent Updates" section on homepage is good but limited.

---

## Content Audit Results

### ✅ Well-Documented

- Dashboard (`dash.md`, 16KB)
- Status (`status.md`, 10KB)
- Doctor (`doctor.md`, 10KB)
- Sync (`sync.md`, 8KB)
- Dopamine Guide (guide exists)

### ⚠️ Needs Update

- Quick Start (references old architecture)
- AI Tutorial (v3.2.0 reference)
- Installation (may have outdated paths)

### ❌ Missing Entirely

- `work` command (THE core command!)
- `finish` command
- `hop` command
- `capture` commands (win, catch, yay)
- `timer` command
- `pick` command

### 🗑️ Consider Removing/Archiving

- `docs/active/` - Internal planning docs
- `docs/planning/` - Internal planning docs
- `docs/ideas/` - Internal brainstorming
- `docs/standards/` - Internal standards

These are excluded from nav but still in repo.

---

## Navigation Improvements

### Current Nav (11 sections)

```
Home | Getting Started | Tutorials | Guides | Reference |
Commands | Architecture | API | Testing | Development | Decisions
```

### Proposed Nav (Simplified)

```
Home
Getting Started (4 pages)
Tutorials (7 pages) ← Add 2 new
Guides (6 pages)
Commands (18 pages) ← Add 8 new
Reference (reorganized into 3 subsections)
For Developers:
  - Architecture
  - API
  - Testing
  - Contributing
  - Decisions (ADRs)
```

---

## Priority Order

| #   | Task                         | Effort | Impact      |
| --- | ---------------------------- | ------ | ----------- |
| 1   | Add `work` command doc       | 20 min | 🔥 Critical |
| 2   | Add `finish` command doc     | 15 min | 🔥 Critical |
| 3   | Add `capture` commands doc   | 25 min | 🔥 High     |
| 4   | Update Quick Start           | 30 min | 🔥 High     |
| 5   | Add Dopamine tutorial        | 45 min | High        |
| 6   | Add remaining command docs   | 1 hr   | Medium      |
| 7   | Create FAQ                   | 30 min | Medium      |
| 8   | Reorganize Reference section | 1 hr   | Medium      |
| 9   | Add Sync tutorial            | 30 min | Medium      |
| 10  | Fix version references       | 20 min | Low         |

---

## Implementation Checklist

### Phase 1: Critical Gaps (Today) ✅ DONE

- [x] Create `docs/commands/work.md`
- [x] Create `docs/commands/finish.md`
- [x] Create `docs/commands/capture.md`
- [x] Update `docs/getting-started/quick-start.md`

### Phase 2: Complete Commands (This Week) ✅ DONE

- [x] Create `docs/commands/hop.md`
- [x] Create `docs/commands/timer.md`
- [x] Create `docs/commands/morning.md`
- [x] Create `docs/commands/pick.md`
- [x] Create `docs/commands/flow.md`
- [x] Update `mkdocs.yml` navigation

### Phase 3: New Tutorials ✅ DONE

- [x] Create `docs/tutorials/06-dopamine-features.md`
- [x] Create `docs/tutorials/07-sync-command.md`
- [x] Create `docs/getting-started/faq.md`

### Phase 4: Polish (In Progress)

- [x] Reorganize Reference section (PR #45)
- [ ] Add video/GIF content
- [x] Create CHANGELOG page (PR #47)
- [x] Archive internal planning docs (PR #49)

---

## Notes

- Keep ADHD-friendly: short sections, clear headers, lots of examples
- Every command doc should have copy-pasteable examples
- Use admonitions (tip, warning, note) for visual breaks
- Link related commands together
