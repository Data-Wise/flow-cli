# Brainstorm: `teach map` -- Unified Ecosystem Discovery

**Generated:** 2026-02-08
**Issue:** #358
**Depth:** Deep (8 questions)
**Focus:** Feature
**Duration:** ~8 min

---

## Problem Statement

The teaching ecosystem spans 3 tools (flow-cli, Scholar, Craft) with 35+ commands across them. Users don't know what exists or which tool handles what. The existing `teach help` only covers `teach` subcommands -- it doesn't mention Craft slash commands or how Scholar AI integrates.

**Pain point:** A new user running `teach help` sees 25 commands but has no idea that `/craft:site:publish` or `/scholar:teaching:validate` exist, or that `teach lecture` actually delegates to Scholar under the hood.

---

## Requirements (From Deep Questions)

| Decision | Answer |
|----------|--------|
| Scope | Full ecosystem (teach + Scholar slash cmds + Craft slash cmds) |
| Grouping | By workflow phase (Setup -> Content -> Validate -> Deploy -> Track) |
| Missing tools | Show dimmed with install hint |
| Interactivity | Static reference (print-and-exit) |
| Craft commands | Show as `/craft:site:publish` with "run inside Claude Code" note |
| Flags | None -- keep it minimal |
| vs `teach help` | Complement: help = how to use; map = what exists |
| Context | None -- static output everywhere |

---

## Quick Wins

1. Single function `_teach_map()` -- no new files needed, add to teach-dispatcher.zsh
2. Tool detection reuses existing patterns (check for plugin dirs)
3. No flags, no interactivity -- pure print function
4. Box-drawing follows `_teach_dispatcher_help()` style (already established)

---

## Output Design (Proposed)

```
+-----------------------------------------------+
| teach map -- Teaching Ecosystem               |
+-----------------------------------------------+

 Tools: flow-cli v6.5.0  scholar [dim: not installed]  craft v2.x

 SETUP & CONFIGURATION
   teach init [name]         Initialize project        [flow-cli]
   teach config              Edit configuration        [flow-cli]
   teach doctor [--fix]      Health check              [flow-cli]
   teach dates               Date management           [flow-cli]
   teach hooks               Git hook management       [flow-cli]
   teach plan                Lesson plan CRUD          [flow-cli]
   teach templates           Template management       [flow-cli]
   teach macros              LaTeX macros              [flow-cli]
   teach prompt              AI prompt management      [flow-cli]
   teach style               Teaching style            [flow-cli]

 CONTENT GENERATION                               [scholar AI]
   teach lecture <topic>     Lecture notes
   teach slides <topic>      Presentation slides
   teach exam <topic>        Comprehensive exam
   teach quiz <topic>        Quiz questions
   teach assignment <topic>  Homework assignment
   teach syllabus <course>   Course syllabus
   teach rubric <assign>     Grading rubric
   teach feedback <work>     Student feedback

 VALIDATION & QUALITY
   teach validate [files]    Validate .qmd files       [flow-cli]
   teach analyze <file>      Concept prerequisites     [flow-cli]
   /scholar:teaching:validate  Schema validation       [scholar]
   /craft:site:check           Content + link check    [craft]

 DEPLOYMENT
   teach deploy              Deploy course site        [flow-cli]
   teach deploy --preview    Preview before deploy     [flow-cli]
   /craft:site:publish         Full publish workflow   [craft]
   /craft:site:build           Build site locally      [craft]

 SEMESTER TRACKING
   teach status              Project dashboard         [flow-cli]
   teach week                Current week info         [flow-cli]
   teach backup              Backup management         [flow-cli]
   teach archive             Archive semester          [flow-cli]
   /craft:site:progress        Semester progress       [craft]

 TIP: /craft and /scholar commands run inside Claude Code
 TIP: teach help -- usage details for any teach subcommand
```

---

## Architecture Decisions

### 1. Tool Detection

```zsh
# Reuse from _teach_scholar_wrapper pattern
local has_scholar=false has_craft=false
command -v claude &>/dev/null && {
    [[ -d "${HOME}/.claude/plugins/scholar" ]] && has_scholar=true
    [[ -d "${HOME}/.claude/plugins/craft" ]] && has_craft=true
}
```

### 2. Dimming Unavailable Commands

- Use `$_C_DIM` for commands from missing tools
- Append `(requires scholar)` or `(requires craft)` inline
- Available commands use `$_C_CYAN` (consistent with help)

### 3. Version Detection

- flow-cli: read from `package.json` or hardcoded
- Scholar/Craft: check plugin dir existence, optionally read their package.json

### 4. Placement in Case Statement

Add `map` case between `style` and `*` catch-all:

```zsh
map)
    _teach_map
    ;;
```

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Ecosystem commands change | Output goes stale | Keep command list as data, not hardcoded strings |
| Scholar/Craft detection breaks | Shows wrong availability | Graceful fallback: assume not installed |
| Output too long for terminal | Scrolls off screen | Keep output compact, no excessive decoration |

---

## Alternatives Considered

1. **Dynamic discovery** (scan plugin manifests) -- Over-engineered for 3 known tools
2. **Interactive picker** -- Adds complexity, user chose static
3. **JSON output** -- Not needed for a reference command
4. **Web-based map** -- Already have docs site, this is for terminal

---

## Recommended Path

Implement as a single `_teach_map()` function in `teach-dispatcher.zsh`. No new files. ~100-150 lines. Data-driven: define commands as arrays, render with loop. This makes future updates (add/remove commands) trivial.

## Next Steps

1. [ ] Create spec from this brainstorm
2. [ ] Implement on feature branch
3. [ ] Add to `teach help` footer as cross-reference
4. [ ] Close #358
