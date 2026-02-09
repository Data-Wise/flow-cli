# SPEC: `teach map` -- Unified Ecosystem Discovery

**Status:** draft
**Created:** 2026-02-08
**Issue:** #358
**From Brainstorm:** BRAINSTORM-teach-map-2026-02-08.md
**Version Target:** v6.6.0

---

## Overview

Add a `teach map` subcommand that displays the complete teaching ecosystem across all three tools (flow-cli, Scholar, Craft) grouped by workflow phase. This gives users a single reference to discover every available command, understand which tool provides it, and see what they're missing. Complements `teach help` (which covers usage details for `teach` subcommands only).

---

## Primary User Story

**As a** teaching workflow user,
**I want to** see every available teaching command across all tools in one place,
**So that** I can discover capabilities I didn't know existed and understand which tool handles each task.

### Acceptance Criteria

- [ ] `teach map` prints a static reference of all teaching commands grouped by workflow phase
- [ ] Each command shows its source tool via `[flow-cli]`, `[scholar]`, or `[craft]` badge
- [ ] Commands from uninstalled tools appear dimmed with install hint
- [ ] Craft commands shown as slash commands (e.g., `/craft:site:publish`)
- [ ] Output uses box-drawing consistent with `_teach_dispatcher_help()`
- [ ] No flags, no interactivity, no context-awareness

---

## Secondary User Stories

**As a** user without Scholar installed,
**I want to** see what Scholar would give me (dimmed),
**So that** I know whether installing it is worth the effort.

**As a** user switching between terminal and Claude Code,
**I want to** see both shell commands and slash commands in one view,
**So that** I know which interface to use for each task.

---

## Architecture

```
teach map
    |
    v
_teach_map()
    |
    +-- _teach_map_detect_tools()   # Check scholar/craft availability
    +-- _teach_map_render()          # Print grouped output
         |
         +-- Phase: SETUP & CONFIGURATION
         +-- Phase: CONTENT GENERATION
         +-- Phase: VALIDATION & QUALITY
         +-- Phase: DEPLOYMENT
         +-- Phase: SEMESTER TRACKING
```

Single function in `teach-dispatcher.zsh`. No new files.

---

## API Design

N/A -- No API changes. This is a pure ZSH print function.

### Command Interface

```
teach map          # Show full ecosystem map
teach map --help   # Same as teach map (it IS the help)
```

**Aliases:** `map` only (no shortcut needed -- it's a discovery command, not a daily-use one).

---

## Data Models

N/A -- No data model changes. Command registry is hardcoded in the function (simple, maintainable for 3 known tools).

---

## Dependencies

- `lib/core.zsh` -- Color variables (`$_C_BOLD`, `$_C_DIM`, `$_C_CYAN`, etc.)
- Scholar plugin detection: `[[ -d "${HOME}/.claude/plugins/scholar" ]]`
- Craft plugin detection: `[[ -d "${HOME}/.claude/plugins/craft" ]]`

No new dependencies.

---

## UI/UX Specifications

### Output Layout

```
+-----------------------------------------------+
| teach map -- Teaching Ecosystem               |
+-----------------------------------------------+

 Tools: flow-cli v6.5.0  scholar v1.x  craft v2.x
                          ^^^^^^ dimmed if not installed

 SETUP & CONFIGURATION
   teach init [name]           Initialize project          [flow-cli]
   teach config                Edit configuration          [flow-cli]
   teach doctor [--fix]        Health check                [flow-cli]
   teach dates                 Date management             [flow-cli]
   teach hooks                 Git hook management         [flow-cli]
   teach plan                  Lesson plan CRUD            [flow-cli]
   teach templates             Template management         [flow-cli]
   teach macros                LaTeX macros                [flow-cli]
   teach prompt                AI prompt management        [flow-cli]
   teach style                 Teaching style              [flow-cli]

 CONTENT GENERATION                            [scholar AI]
   teach lecture <topic>       Lecture notes
   teach slides <topic>        Presentation slides
   teach exam <topic>          Comprehensive exam
   teach quiz <topic>          Quiz questions
   teach assignment <topic>    Homework assignment
   teach syllabus <course>     Course syllabus
   teach rubric <assign>       Grading rubric
   teach feedback <work>       Student feedback
   teach demo                  Demo course

 VALIDATION & QUALITY
   teach validate [files]      Validate .qmd files         [flow-cli]
   teach analyze <file>        Concept prerequisites       [flow-cli]
   teach profiles              Profile management          [flow-cli]
   teach cache                 Cache operations            [flow-cli]
   teach clean                 Delete _freeze/ + _site/    [flow-cli]
   /scholar:teaching:validate  Schema validation           [scholar]
   /craft:site:check           Content + link check        [craft]

 DEPLOYMENT
   teach deploy [--preview]    Deploy course site          [flow-cli]
   /craft:site:publish         Full publish workflow       [craft]
   /craft:site:build           Build site locally          [craft]
   /craft:site:deploy          Deploy to GitHub Pages      [craft]

 SEMESTER TRACKING
   teach status                Project dashboard           [flow-cli]
   teach week                  Current week info           [flow-cli]
   teach backup                Backup management           [flow-cli]
   teach archive               Archive semester            [flow-cli]
   /craft:site:progress        Semester progress           [craft]

 Slash commands (/craft:*, /scholar:*) run inside Claude Code
 For usage details: teach <command> --help
```

### Color Scheme

| Element | Color | Variable |
|---------|-------|----------|
| Box frame | Bold | `$_C_BOLD` |
| Phase headers | Blue | `$_C_BLUE` |
| Available commands | Cyan | `$_C_CYAN` |
| Unavailable commands | Dim | `$_C_DIM` |
| Tool badges | Green (available) / Dim (missing) | `$_C_GREEN` / `$_C_DIM` |
| Tips at bottom | Dim | `$_C_DIM` |

### Accessibility

- No emoji in the output (consistent with existing help style)
- Column-aligned for readability
- No interactivity required

---

## Open Questions

1. Should `teach help` footer reference `teach map`? (Likely yes -- "See also: teach map")
2. Should the Craft commands list be dynamically discovered or hardcoded? (Hardcoded recommended for v1)

---

## Review Checklist

- [ ] Output fits in 80-column terminal
- [ ] Colors degrade gracefully (no-color mode)
- [ ] Tool detection works when Claude Code is not installed
- [ ] All teach subcommands from dispatcher are represented
- [ ] Craft/Scholar commands are accurate
- [ ] No emoji in output
- [ ] `teach map --help` works (routes to map itself)

---

## Implementation Notes

- Add `map` case to `teach()` case statement (line ~4530, before `*` catch-all)
- Function should be ~80-120 lines
- Tool header line shows version if available, "(not installed)" if missing
- Content generation section: all commands get `[scholar]` badge since they all delegate via `_teach_scholar_wrapper`
- Consider extracting tool detection into `_teach_map_detect_tools()` for reuse by future `teach check` (#359)

---

## History

| Date | Change |
|------|--------|
| 2026-02-08 | Initial spec from deep brainstorm session |
