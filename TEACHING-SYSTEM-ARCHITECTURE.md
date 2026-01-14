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

**Does NOT require Scholar** - Works standalone

---

### Layer 2: Scholar Plugin Teaching Features (Content Generation)

**What it is:**

- Node.js plugin that generates educational materials using AI
- Part of broader "Scholar" academic plugin (also supports research)
- OPTIONAL enhancement to flow-cli teaching workflow

**Commands (Planned - Not Yet Implemented):**

```bash
/teaching:exam "Topic"      # Generate exam questions
/teaching:quiz "Topic"      # Generate quiz
/teaching:lecture "Topic"   # Generate lecture outline
/teaching:assignment "Topic" # Generate assignment
/teaching:syllabus "Data"   # Generate course syllabus
```

**Key Features:**

- ✅ AI-powered content generation
- ✅ Template-based structure (ensures quality)
- ✅ Multiple output formats (Markdown, Quarto, LaTeX, JSON)
- ✅ Validation before save
- ✅ Context-aware (reads `.flow/teach-config.yml`)

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

**Does NOT require flow-cli** - Works standalone

---

## Integration Model

### Scenario 1: Using ONLY flow-cli (Current State)

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

### Scenario 2: Using flow-cli WITH Scholar (Future State)

```bash
# 1. Initialize teaching repo
teach init "STAT 545"

# 2. Generate exam questions via Scholar
teach exam "Hypothesis Testing"    # Wraps /teaching:exam

# 3. Create other materials manually or via Scholar
work stat-545
# → Edit generated materials, add custom content...

# 4. Deploy
teach deploy
```

**Result:** flow-cli handles workflow, Scholar handles content generation

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

### Scholar Teaching (Draft/Planned)

**Status:** Spec written, not yet implemented

- 🎯 `/teaching:exam` - Generate exam questions
- 🎯 `/teaching:quiz` - Generate quiz
- 🎯 `/teaching:lecture` - Generate lecture outline
- 🎯 `/teaching:assignment` - Generate assignment
- 🎯 `/teaching:syllabus` - Generate course syllabus

**Documentation Reference:**

- `SPEC-scholar-teaching-2026-01-11.md` - Feature specification
- `BRAINSTORM-scholar-teaching-2026-01-11.md` - Design decisions
- `PLAN-teaching-workflow-increment-3.md` - Implementation roadmap

**Scope:** Content generation and quality validation

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

**These documents do NOT cover Scholar** because Scholar is not yet implemented.

---

### For Users Interested in Scholar Teaching

See these planning documents:

- `docs/specs/SPEC-scholar-teaching-2026-01-11.md` - Feature spec
- `docs/specs/BRAINSTORM-scholar-teaching-2026-01-11.md` - Design
- `docs/specs/PLAN-teaching-workflow-increment-3.md` - Implementation roadmap

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

### 🎯 Phase 2: Scholar Teaching Features (PLANNED - TBD)

- [ ] `/teaching:exam` command
- [ ] `/teaching:quiz` command
- [ ] `/teaching:lecture` command
- [ ] `/teaching:assignment` command
- [ ] `/teaching:syllabus` command
- [ ] Template system
- [ ] Validation system
- [ ] Integration tests with flow-cli

**Status:** Spec written, waiting for implementation

---

## Summary

**To clarify the brainstorm request:**

> "make it clear if teach uses scholar or something else"

**Answer:**

**flow-cli teaching does NOT use Scholar.** It is a standalone ZSH-based workflow automation system for:

- Managing course repositories
- Deploying materials to students
- Tracking semesters
- Creating archives

**Scholar teaching is a COMPLEMENTARY system** (planned, not implemented) that would:

- Generate content (exams, lectures, assignments)
- Validate quality
- Integrate with flow-cli workflows

**They are designed to work together** but function independently:

- flow-cli teaching = deployment engine (pure ZSH)
- Scholar teaching = content generation engine (Node.js + AI)

---

**Documentation Status:**

- ✅ flow-cli teaching: Fully documented, production ready
- 🎯 Scholar teaching: Spec written, implementation pending
