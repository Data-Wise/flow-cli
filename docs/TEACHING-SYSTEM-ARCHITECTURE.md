# Teaching System Architecture - Clarification

**Document Purpose:** Explain the relationship between flow-cli teaching workflow and Scholar plugin teaching features

**Created:** 2026-01-13

---

## TL;DR

**flow-cli** and **Scholar** are TWO SEPARATE but COMPLEMENTARY systems:

| Aspect           | flow-cli Teaching                                             | Scholar Teaching                                                                |
| ---------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| **Purpose**      | Workflow automation                                           | Content generation                                                              |
| **Language**     | Pure ZSH                                                      | Node.js                                                                         |
| **Commands**     | `teach init`, `teach deploy`, `teach status`, `teach archive` | `/teaching:exam`, `/teaching:quiz`, `/teaching:lecture`, `/teaching:assignment` |
| **What it does** | Deploy materials, manage branches, archive semesters          | Generate exam questions, create lecture outlines, design assignments            |
| **Integration**  | Standalone (works alone)                                      | Optional (enhances flow-cli workflows)                                          |

---

## Navigation

- [Why TWO Systems?](#why-two-systems) - Rationale behind the design
- [Architecture](#architecture) - System components and layers
- [Integration Model](#integration-model) - Real-world usage scenarios
- [Key Distinctions](#key-distinctions) - What's implemented vs planned
- [Using This Documentation](#using-this-documentation) - Guide to the guides
- [Timeline](#timeline) - Release history and roadmap

---

## Why TWO Systems?

### Separation of Concerns

| Concern        | Tool        | Why                                                            |
| -------------- | ----------- | -------------------------------------------------------------- |
| **Deployment** | flow-cli    | Pure ZSH = instant, no dependencies, <10ms response            |
| **Generation** | Scholar     | Node.js + Claude API = sophisticated AI, templates, validation |
| **Editing**    | Your editor | Manual refinement, quality control, personalization            |

### Benefits

1. **Modularity** - Use flow-cli without Scholar, or Scholar for other purposes
2. **Performance** - flow-cli runs in shell without external calls
3. **Flexibility** - Scholar can generate content for non-teaching contexts
4. **Composition** - flow-cli wraps Scholar when both are needed

---

## Architecture

### Layer 1: flow-cli Teaching Workflow (Deployment Focus)

**What it is:**

- Pure ZSH plugin for managing course repositories
- Handles Git branching, deployment automation, and semester management
- Runs ENTIRELY in the shell with no external dependencies

**Commands:**

```bash
teach init "STAT 545"     # Initialize course repo
teach deploy              # Deploy draft → production
teach status              # Show course status
teach week                # Current week info
teach archive             # Create semester snapshot
teach config              # Update settings
teach exam "Midterm"      # Create exam (placeholder for Scholar integration)
```

**Key Features:**

- ✅ Branch-based workflow (draft/production)
- ✅ < 2 minute deployment via GitHub Actions
- ✅ Semester tracking and archival
- ✅ Course context detection
- ✅ Integration with work/dash commands

**System Architecture:**

```
┌─────────────────────────────────────────┐
│  flow-cli (Pure ZSH)                    │
├─────────────────────────────────────────┤
│  teach dispatcher                       │
│  ├── teach init      (setup)            │
│  ├── teach deploy    (git merge+push)   │
│  ├── teach status    (dashboard)        │
│  ├── teach week      (semester calc)    │
│  ├── teach archive   (git tag)          │
│  ├── teach config    (YAML editor)      │
│  └── teach exam      (Scholar wrapper)  │
├─────────────────────────────────────────┤
│  Underlying: Git + GitHub Actions       │
└─────────────────────────────────────────┘
```

---

### Layer 2: Scholar Plugin Teaching Features (Content Generation)

**What it is:**

- Node.js plugin that generates educational materials using AI
- Part of broader "Scholar" academic plugin (also supports research)
- OPTIONAL enhancement to flow-cli teaching workflow

**Commands (v2.0.1 - COMPLETE ✅):**

```bash
/teaching:exam "Topic"        # Generate comprehensive exams
/teaching:quiz "Topic"        # Create quick quizzes
/teaching:syllabus            # Build course syllabus
/teaching:assignment "Topic"  # Create homework assignments
/teaching:rubric "Name"       # Generate grading rubrics
/teaching:slides "Topic"      # Create lecture slides
/teaching:feedback "Work"     # Generate student feedback
/teaching:demo                # Create demo course environment
```

**Key Features (v2.0.1 - COMPLETE ✅):**

- ✅ AI-powered content generation
- ✅ Template-based structure (ensures quality)
- ✅ Multiple output formats (Markdown, Quarto, LaTeX, JSON, Canvas QTI)
- ✅ Validation before save
- ✅ Context-aware (reads `.flow/teach-config.yml`)
- ✅ 547 tests (100% pass rate)
- ✅ --dry-run flag for all commands

**System Architecture:**

```
┌─────────────────────────────────────────┐
│  Scholar Plugin (Node.js)               │
├─────────────────────────────────────────┤
│  Teaching Namespace (/teaching:*)       │
│  ├── Commands                           │
│  │   ├── exam.js                        │
│  │   ├── quiz.js                        │
│  │   ├── lecture.js                     │
│  │   ├── assignment.js                  │
│  │   └── syllabus.js                    │
│  │                                      │
│  ├── Templates                          │
│  │   ├── exam.json                      │
│  │   ├── quiz.json                      │
│  │   ├── lecture.json                   │
│  │   ├── assignment.json                │
│  │   └── syllabus.json                  │
│  │                                      │
│  └── Validators                         │
│      ├── schema.js                      │
│      ├── latex.js                       │
│      └── markdown.js                    │
├─────────────────────────────────────────┤
│  Underlying: Claude API + Templates     │
└─────────────────────────────────────────┘
```

---

## Integration Model

### Scenario 1: Using ONLY flow-cli ✅ AVAILABLE NOW

```bash
# 1. Initialize teaching repo
teach init "STAT 545"

# 2. Create course materials manually (in editor)
work stat-545
# → Edit files...

# 3. Deploy
teach deploy
```

**Result:** Full teaching workflow, no Scholar needed

---

### Scenario 2: Using flow-cli WITH Scholar ✅ AVAILABLE NOW

```bash
# 1. Initialize teaching repo
teach init "STAT 545"

# 2. Generate exam questions via Scholar (in Claude Code)
claude
> /teaching:exam "Hypothesis Testing" --format quarto

# 3. Review and edit generated materials
work stat-545
# → Edit generated materials, add custom content...

# 4. Deploy
teach deploy
```

**Result:** flow-cli handles workflow, Scholar handles content generation

**Future (v5.8.0+):** flow-cli wrappers will allow `teach exam "Topic"` directly

---

### Data Flow

```
┌──────────────────────────────────────────────────────────────┐
│                         Instructor                           │
└─────────────────────────────────────┬──────────────────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    │                                   │
         ┌──────────▼──────────┐          ┌────────────▼──────────┐
         │   flow-cli teach    │          │   Scholar /teaching:  │
         │   (deployment)      │          │   (generation)        │
         └─────────┬──────────┘          └────────────┬──────────┘
                   │                                   │
                   │  Creates/updates                  │  Generates
                   │  .flow/teach-config.yml           │  content from
                   │  Manages git branches             │  templates +
                   │  Deploys via GitHub               │  Claude API
                   │                                   │
                   └────────────────┬────────────────────┘
                                    │
                    ┌───────────────▼───────────────┐
                    │   Course Repository           │
                    │   ├── .flow/teach-config.yml  │
                    │   ├── lectures/               │
                    │   ├── assignments/            │
                    │   ├── exams/                  │
                    │   ├── solutions/              │
                    │   └── .github/workflows/      │
                    └───────────────┬───────────────┘
                                    │
                    ┌───────────────▼───────────────┐
                    │   GitHub Pages                │
                    │   (Student-facing)            │
                    └───────────────────────────────┘
```

---

## Key Distinctions

### flow-cli Teaching (What I Documented)

**Already Implemented & Production Ready:**

- ✅ `teach init` - Course setup with git branches
- ✅ `teach deploy` - Deploy materials to students
- ✅ `teach status` - Show course progress
- ✅ `teach week` - Current week calculation
- ✅ `teach archive` - Semester snapshots
- ✅ `teach config` - Edit course settings

**Documentation Created (2026-01-13):**

- `TEACHING-COMMANDS-DETAILED.md` - Deep dive into each command
- `TEACHING-WORKFLOW-VISUAL.md` - Step-by-step visual guides
- `TEACHING-DEMO-GUIDE.md` - Instructions for recording GIFs

**Scope:** Deployment automation and workflow management

---

### Scholar Teaching (v2.0.1 - COMPLETE ✅)

**Status:** Released and production ready (v2.0.1 - 2026-01-13)

- ✅ `/teaching:exam` - Generate comprehensive exams
- ✅ `/teaching:quiz` - Create quick quizzes
- ✅ `/teaching:syllabus` - Build course syllabus
- ✅ `/teaching:assignment` - Create homework assignments
- ✅ `/teaching:rubric` - Generate grading rubrics
- ✅ `/teaching:slides` - Create lecture slides
- ✅ `/teaching:feedback` - Generate student feedback
- ✅ `/teaching:demo` - Create demo course environment

**Documentation Reference:**

- [Scholar Integration Guide](guides/SCHOLAR-WRAPPERS-GUIDE.md) - How to use Scholar with flow-cli
- [Scholar Repository](https://github.com/Data-Wise/scholar) - Full documentation

**Scope:** Content generation and quality validation

---

## Using This Documentation

### For Users Following Teaching Documentation (2026-01-13)

The **three guides I just created** cover the **flow-cli teaching workflow ONLY**:

1. **TEACHING-COMMANDS-DETAILED.md** (850 lines)
   - What: Complete reference for teach commands
   - Use: Understanding each command's capabilities
   - Scope: flow-cli only

2. **TEACHING-WORKFLOW-VISUAL.md** (700 lines)
   - What: Step-by-step visual walkthroughs
   - Use: Learning by example with terminal output
   - Scope: flow-cli only

3. **TEACHING-DEMO-GUIDE.md** (400 lines)
   - What: Instructions for recording GIFs
   - Use: Creating demonstrations
   - Scope: flow-cli only

**For Scholar teaching commands**, see the [Scholar Integration Guide](guides/SCHOLAR-WRAPPERS-GUIDE.md).

---

### For Users Interested in Scholar Teaching

Scholar teaching is **fully implemented (v2.0.1)**. See:

- [Scholar Integration Guide](guides/SCHOLAR-WRAPPERS-GUIDE.md) - How to use Scholar with flow-cli
- [Scholar Repository](https://github.com/Data-Wise/scholar) - Full documentation
- [Scholar API Reference](https://github.com/Data-Wise/scholar/docs/API-REFERENCE.md) - Command details

---

## Timeline

### ✅ Phase 1: flow-cli Teaching Workflow (COMPLETE - 2026-01-13)

- [x] `teach init` command
- [x] `teach deploy` command
- [x] `teach status` command
- [x] `teach week` command
- [x] `teach archive` command
- [x] `teach config` command
- [x] Comprehensive documentation (3 guides, 1,995 lines)
- [x] Help output standardization
- [x] v5.5.0 release with Keychain secrets
- [x] v5.4.1 release with teaching dispatcher

**Status:** Production ready, documented, tested

---

### ✅ Phase 2: Scholar Teaching Features (COMPLETE - 2026-01-13)

- [x] `/teaching:exam` command
- [x] `/teaching:quiz` command
- [x] `/teaching:syllabus` command
- [x] `/teaching:assignment` command
- [x] `/teaching:rubric` command
- [x] `/teaching:slides` command
- [x] `/teaching:feedback` command
- [x] `/teaching:demo` command
- [x] Template system
- [x] Validation system
- [x] 547 tests (100% pass rate)

**Status:** Released v2.0.1 (2026-01-13)

---

## Summary

**flow-cli teaching** ✅ **Production Ready:**

- Standalone ZSH workflow automation
- Commands: `teach init`, `teach deploy`, `teach status`, `teach week`, `teach archive`, `teach config`
- Fully documented in 3 comprehensive guides (1,995 lines)
- Tested and deployed in v5.4.1 and v5.5.0

**Scholar teaching** ✅ **Production Ready (v2.0.1):**

- Optional Node.js content generation plugin
- 8 commands: `/teaching:exam`, `/teaching:quiz`, `/teaching:syllabus`, `/teaching:assignment`, `/teaching:rubric`, `/teaching:slides`, `/teaching:feedback`, `/teaching:demo`
- 547 tests, 5 output formats
- Released 2026-01-13

**They work together but function independently:**

- **flow-cli** = deployment engine (pure ZSH, <10ms, always available)
- **Scholar** = content generator (AI-powered, optional enhancement)
