# Option C Optimization: Unified Command Approach

## Problem with Original Option C

The main issue: **`mv` conflicts with Unix move command**

```bash
mv file.txt backup/     # Unix move - CONFLICT!
mv status               # Mediationverse status - CONFLICT!
```

---

## Brainstorm: Alternative Prefixes

| Prefix  | Example        | Pros                         | Cons                  |
| ------- | -------------- | ---------------------------- | --------------------- |
| `med`   | `med status`   | Clear, short, no conflict    | 3 chars               |
| `medi`  | `medi work`    | Clear                        | 4 chars               |
| `mdv`   | `mdv status`   | Short, unique                | Not intuitive         |
| `verse` | `verse status` | Memorable                    | 5 chars, generic      |
| `rp`    | `rp status`    | Very short (R packages)      | Too generic           |
| `rpkg`  | `rpkg work`    | Clear                        | 4 chars               |
| `M`     | `M status`     | Single char!                 | Case-sensitive issues |
| `mm`    | `mm status`    | 2 chars, memorable           | Generic               |
| `mw`    | `mw status`    | 2 chars (mediation workflow) | Generic               |

### Recommendation: `med`

- **Short** (3 chars)
- **Intuitive** (mediation → med)
- **No conflicts** with common commands
- **Easy to type** (home row adjacent)

---

## Optimized Option C: The `med` Command

### Core Design Principles

1. **Single entry point** - One command to remember
2. **Smart defaults** - No args = dashboard
3. **Short subcommands** - `s` for status, `w` for work
4. **Context-aware** - Detect current package directory
5. **Tab completion** - Discoverable
6. **Graceful degradation** - Unknown command = help

### Command Structure

```
┌─────────────────────────────────────────────────────────────┐
│  med [COMMAND] [PKG] [ARGS]                                 │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  DASHBOARD (no args or single letter shortcuts)             │
│    med              Smart dashboard + suggestions           │
│    med s [PKG]      Status (med status)                    │
│    med r            Full report (med report)               │
│                                                             │
│  WORKFLOW                                                   │
│    med w PKG        Start work (med work)                  │
│    med d PKG [MSG]  Done/commit (med done)                 │
│    med f [PKG]      Fix issues (med fix)                   │
│                                                             │
│  GIT OPERATIONS                                             │
│    med c PKG MSG    Commit (med commit)                    │
│    med p PKG        Push (med push)                        │
│    med P [PKG]      Pull (med pull) - capital P            │
│    med m PKG        Merge dev→main (med merge)             │
│    med rb PKG       Rebase dev (med rebase)                │
│                                                             │
│  NAVIGATION                                                 │
│    med cd PKG       Go to package                          │
│    med dev PKG      Switch to dev branch                   │
│    med main PKG     Switch to main branch                  │
│                                                             │
│  INSPECTION                                                 │
│    med log PKG      Recent commits                         │
│    med diff PKG     Show changes                           │
│    med ls           List packages                          │
│                                                             │
│  SYNC                                                       │
│    med sync         Sync to Apple Notes                    │
│    med notes        Open Apple Notes folder                │
│                                                             │
│  HELP                                                       │
│    med h            Quick reference (med help)             │
│    med h CMD        Detailed help for command              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Smart Features

#### 1. Context Detection

```bash
# If you're already in a package directory:
$ cd ~/projects/r-packages/active/medfit
$ med s          # Automatically detects medfit
$ med c "msg"    # Commits medfit without specifying

# Explicit always works:
$ med s medfit   # Works from anywhere
```

#### 2. Fuzzy Package Matching

```bash
$ med w fit      # Matches "medfit"
$ med w robust   # Matches "medrobust"
$ med w sim      # Matches "medsim"
```

#### 3. Interactive Mode

```bash
$ med
╔════════════════════════════════════════════════════════════╗
║  📊 MEDIATIONVERSE                                         ║
╚════════════════════════════════════════════════════════════╝

  [1] medfit          ⚠️ 1 untracked, dev +2 ahead
  [2] mediationverse  ✅ clean
  [3] medrobust       ✅ clean
  [4] medsim          🔄 dev 9 behind
  [5] probmed         🔄 dev 7 behind

────────────────────────────────────────
  💡 Quick actions:
     • Enter number to start work (e.g., 1)
     • 's' for detailed status
     • 'f' to fix all issues
     • 'q' to quit

  Choice: _
```

#### 4. Command Chaining

```bash
$ med w medfit && med c "Add feature" && med m
# Start work → commit → merge (all in one line)
```

#### 5. Dry Run Mode

```bash
$ med m medfit --dry
# Would merge dev → main for medfit
# Currently: dev is 3 commits ahead
# Proceed? [y/N]
```

---

## Short Aliases (Power User Mode)

For maximum speed, also provide ultra-short aliases:

```bash
# Single letter when unambiguous
alias ms='med s'        # med status
alias mw='med w'        # med work
alias md='med d'        # med done
alias mc='med c'        # med commit
alias mp='med p'        # med push
alias mf='med f'        # med fix
alias ml='med log'      # med log
alias mh='med h'        # med help
```

**Usage:**

```bash
$ mw fit        # Start work on medfit
$ mc "message"  # Commit
$ mp            # Push
```

---

## Tab Completion

```bash
$ med <TAB>
status  work  done  commit  push  pull  merge  fix  help  ...

$ med w <TAB>
medfit  mediationverse  medrobust  medsim  probmed

$ med w med<TAB>
medfit  mediationverse  medrobust
```

### Completion Script (zsh)

```zsh
_med_completion() {
    local commands="status work done commit push pull merge rebase fix help log diff cd dev main sync ls"
    local packages="medfit mediationverse medrobust medsim probmed"

    case "$CURRENT" in
        2)
            _values 'command' ${=commands}
            ;;
        3)
            _values 'package' ${=packages}
            ;;
    esac
}
compdef _med_completion med
```

---

## Implementation Architecture

```
med (main function)
├── _med_parse_args()      # Parse command and package
├── _med_detect_package()  # Auto-detect from cwd
├── _med_fuzzy_match()     # Fuzzy package name matching
├── _med_dashboard()       # Main dashboard view
├── _med_status()          # Status command
├── _med_work()            # Start work workflow
├── _med_done()            # Finish work workflow
├── _med_commit()          # Git commit
├── _med_push()            # Git push
├── _med_pull()            # Git pull
├── _med_merge()           # Merge dev→main
├── _med_rebase()          # Rebase dev on main
├── _med_fix()             # Auto-fix issues
├── _med_help()            # Help system
└── _med_interactive()     # Interactive mode
```

---

## Comparison: Option C vs Option C Optimized

| Feature            | Original C        | Optimized C               |
| ------------------ | ----------------- | ------------------------- |
| Prefix             | `mv` (conflicts!) | `med` (safe)              |
| Subcommand length  | Full words        | Short aliases (s, w, d)   |
| Context detection  | No                | Yes (auto-detect package) |
| Fuzzy matching     | No                | Yes                       |
| Interactive mode   | No                | Yes                       |
| Tab completion     | Basic             | Full                      |
| Power user aliases | No                | Yes (ms, mw, md)          |
| Dry run mode       | No                | Yes                       |

---

## Example Workflows

### Daily Workflow

```bash
$ med                    # See dashboard
$ med w fit              # Start work on medfit
# ... do work ...
$ med d "Add feature"    # Commit with message
# Prompted: merge to main? [y/N]
```

### Quick Status Check

```bash
$ med s                  # Status all
$ ms                     # Even shorter
```

### Fix All Issues

```bash
$ med f                  # Interactive fix for all packages
# Guides through: stale branches, uncommitted changes, etc.
```

### From Inside Package Directory

```bash
$ cd ~/projects/r-packages/active/medfit
$ med s                  # Status for medfit (auto-detected)
$ med c "Fix bug"        # Commit medfit
$ med p                  # Push medfit
```

---

## Pros of Optimized Option C

1. **Single mental model** - One command to learn
2. **Progressive mastery** - Start with `med`, learn shortcuts over time
3. **No conflicts** - `med` doesn't clash with anything
4. **Discoverable** - Tab completion teaches the system
5. **Context-aware** - Less typing when in package directory
6. **Power user friendly** - Short aliases for speed
7. **Interactive fallback** - Dashboard when unsure

## Cons of Optimized Option C

1. **Learning curve** - Need to learn subcommand system
2. **Typing overhead** - `med status` vs `mvst` (but short aliases help)
3. **Implementation complexity** - More code to write
4. **Mental overhead** - Remembering command structure

---

## Verdict

**Optimized Option C is viable** if:

- You prefer a unified command structure (like git/docker)
- You want maximum discoverability
- You're okay with slightly more typing for clarity

**Stick with Option D (Hybrid)** if:

- You want the fastest possible typing
- You prefer standalone commands (mvst, mvci)
- You want simpler implementation

---

## Hybrid Possibility: Option C + D

Could have BOTH:

- `med` unified command for discoverability/beginners
- `mv*` shortcuts for power users

```bash
# These would be equivalent:
med status medfit  ←→  mvst medfit
med work medfit    ←→  mvwork medfit
med commit medfit  ←→  mvci medfit
```

This gives best of both worlds but doubles the API surface.

---

## Decision

**Preferred approach:** **\*\***\_\_\_**\*\***

**Notes:**
