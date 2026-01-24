# Teaching Workflow v2.0 - Increment 3 Implementation Plan

**Feature:** Exam Workflow (Optional)
**Status:** Planning
**Created:** 2026-01-11
**Estimated:** 8-10 hours

---

## Overview

**Goal:** Optional exam automation workflow for Canvas integration (2-3 exams/semester)

**Problem:** Creating exams and converting them to Canvas QTI format is time-consuming:
- Manual question formatting
- Canvas QTI conversion complexity
- No reusable question banks
- Inconsistent exam formatting

**Solution:** Streamlined exam workflow with markdown authoring and automated Canvas conversion

---

## Scope

### In Scope ✅

- `teach-exam` command for guided exam creation
- examark integration (Markdown → Canvas QTI)
- Exam template generation
- QTI conversion script
- Exam directory structure
- Configuration for exam settings

### Out of Scope ❌

- Scholar AI integration (defer to future)
- Automatic exam generation (manual authoring only)
- Question bank management (simple directory structure)
- Gradescope integration
- Multiple exam formats (Canvas only)

---

## Dependencies

### Required

- ✅ `examark` - npm package for Markdown → Canvas QTI conversion
  - Install: `npm install -g examark`
  - Version: Latest (check compatibility)
  - Docs: https://github.com/daveagp/examark

### Optional

- ❌ Scholar teaching skills (deferred - not yet available)

---

## User Stories

### 1. Create Exam Template

**As a** course instructor
**I want** to quickly create an exam template
**So that** I can focus on writing questions, not formatting

**Acceptance:**

```bash
$ teach-exam "Midterm 1: Weeks 1-8"

📝 Creating exam: Midterm 1: Weeks 1-8

Exam details:
  Duration (minutes) [120]: 90
  Total points [100]:
  Filename (without .md): midterm1

✅ Exam template created: exams/midterm1.md

Next steps:
  1. Edit: $EDITOR exams/midterm1.md
  2. Convert: ./scripts/exam-to-qti.sh exams/midterm1.md
  3. Upload: exams/midterm1.qti → Canvas
```

### 2. Convert to Canvas QTI

**As a** course instructor
**I want** to convert markdown exams to Canvas QTI format
**So that** I can upload them directly to Canvas

**Acceptance:**

```bash
$ ./scripts/exam-to-qti.sh exams/midterm1.md

🔄 Converting exam to Canvas QTI...

✅ Converted: exams/midterm1.qti (23 questions)

Upload to Canvas:
  1. Go to: [course] → Quizzes → Import
  2. Select: QTI 1.2 format
  3. Upload: exams/midterm1.qti
```

### 3. Reuse Questions

**As a** course instructor
**I want** to organize questions by topic
**So that** I can reuse them across exams

**Acceptance:**

```
exams/
├── midterm1.md           # Full exam
├── final.md              # Full exam
└── questions/            # Question bank
    ├── regression.md     # Topic-based
    ├── anova.md
    └── inference.md
```

---

## Implementation Plan

### Phase 1: Command & Template (4 hours)

#### 1.1 Create `commands/teach-exam.zsh` (2 hours)

**Function:** `teach-exam <topic>`

**Steps:**
1. Validate teaching project
2. Load config from `.flow/teach-config.yml`
3. Prompt for exam details:
   - Duration (default: 120 min)
   - Total points (default: 100)
   - Filename (default: exam-YYYYMMDD)
4. Check examark availability
5. Create exam directory if needed
6. Generate template from `lib/templates/teaching/exam-template.md`
7. Show next steps

**Template location:** `lib/templates/teaching/exam-template.md`

**Config fields (add to teach-config.yml):**

```yaml
examark:
  enabled: true
  exam_dir: "exams"
  question_bank: "exams/questions"
  default_duration: 120
  default_points: 100
```

#### 1.2 Create Exam Template (1 hour)

**File:** `lib/templates/teaching/exam-template.md`

**Structure:**

```markdown
---
title: {{TOPIC}}
duration: {{DURATION}} minutes
points: {{POINTS}}
instructions: |
  - You have {{DURATION}} minutes
  - Exam is worth {{POINTS}} points
  - Show all work for partial credit
---

# {{TOPIC}}

**Name:** _______________________________

**Duration:** {{DURATION}} minutes
**Total Points:** {{POINTS}}

---

## Section 1: Multiple Choice (30 points)

1. [3 pts] Question text here?
   - [ ] Option A
   - [ ] Option B
   - [x] Option C (correct)
   - [ ] Option D

---

## Section 2: Short Answer (40 points)

1. [10 pts] Question text here?

   **Answer:**
   <!-- Student writes here -->

---

## Section 3: Computational (30 points)

1. [15 pts] Problem description?

   **Answer:**
   <!-- Student works here -->

---

## Answer Key (instructor only)

1. C
2. [Expected answer]
3. [Expected solution with rubric]
```

#### 1.3 Update Config Template (1 hour)

**File:** `lib/templates/teaching/teach-config.yml.template`

**Add examark section:**

```yaml
# Exam Workflow (Increment 3 - Optional)
examark:
  enabled: false              # Set to true after installing examark
  exam_dir: "exams"
  question_bank: "exams/questions"
  default_duration: 120       # Minutes
  default_points: 100
```

---

### Phase 2: Conversion Script (3 hours)

#### 2.1 Create `scripts/exam-to-qti.sh` (2 hours)

**Template:** `lib/templates/teaching/exam-to-qti.sh`

**Functionality:**
1. Validate examark installed
2. Validate input file exists
3. Run examark conversion
4. Check for errors
5. Show output file location
6. Provide Canvas upload instructions

**Script outline:**

```bash
#!/usr/bin/env bash
set -euo pipefail

# Validate examark
if ! command -v examark &>/dev/null; then
  echo "❌ examark not installed"
  echo "Install: npm install -g examark"
  exit 1
fi

# Get input file
EXAM_FILE="$1"

if [[ ! -f "$EXAM_FILE" ]]; then
  echo "❌ File not found: $EXAM_FILE"
  exit 1
fi

# Convert
echo "🔄 Converting exam to Canvas QTI..."

OUTPUT_FILE="${EXAM_FILE%.md}.qti"

if examark "$EXAM_FILE" --output "$OUTPUT_FILE" --format canvas; then
  # Count questions
  QUESTION_COUNT=$(grep -c '<item' "$OUTPUT_FILE" || echo "0")

  echo ""
  echo "✅ Converted: $OUTPUT_FILE ($QUESTION_COUNT questions)"
  echo ""
  echo "Upload to Canvas:"
  echo "  1. Go to: [course] → Quizzes → Import"
  echo "  2. Select: QTI 1.2 format"
  echo "  3. Upload: $OUTPUT_FILE"
else
  echo ""
  echo "❌ Conversion failed"
  echo "Check exam format: https://github.com/daveagp/examark"
  exit 1
fi
```

#### 2.2 Add Script to teach-init (30 min)

**File:** `commands/teach-init.zsh`

**Modify `_teach_install_templates()`:**

```zsh
# Copy script templates
cp "$template_dir/quick-deploy.sh" scripts/
cp "$template_dir/semester-archive.sh" scripts/
cp "$template_dir/exam-to-qti.sh" scripts/      # NEW
chmod +x scripts/*.sh
```

#### 2.3 Update Next Steps Message (30 min)

**File:** `commands/teach-init.zsh`

**Add to `_teach_show_next_steps()`:**

```zsh
echo "  5. (Optional) Enable exam workflow:"
echo "     npm install -g examark"
echo "     yq -i '.examark.enabled = true' .flow/teach-config.yml"
```

---

### Phase 3: Documentation (2 hours)

#### 3.1 Update TEACHING-WORKFLOW.md (1 hour)

**Add new section:** "Increment 3: Exam Workflow"

**Content:**
- Overview of exam workflow
- examark installation instructions
- teach-exam command usage
- Exam template structure
- QTI conversion process
- Canvas upload steps
- Question bank organization
- Example workflow

#### 3.2 Update REFCARD-TEACHING.md (30 min)

**Add to commands table:**

```markdown
| Command | Purpose | Example |
|---------|---------|---------|
| `teach-exam <topic>` | Create exam template | `teach-exam "Midterm 1"` |
| `./scripts/exam-to-qti.sh <file>` | Convert to Canvas QTI | `./scripts/exam-to-qti.sh exams/midterm1.md` |
```

#### 3.3 Update README.md (30 min)

**Add to teaching features:**
- ✅ **Exam Workflow** (optional) - Markdown exams → Canvas QTI

---

### Phase 4: Testing (1 hour)

#### 4.1 Manual Testing Checklist

**Prerequisites:**
- [ ] Install examark: `npm install -g examark`
- [ ] Test course repository ready

**Test Cases:**
1. **teach-exam command**
   - [ ] Run without arguments (shows usage)
   - [ ] Run with topic
   - [ ] Prompts for duration, points, filename
   - [ ] Creates exam file
   - [ ] Shows next steps

2. **Exam template**
   - [ ] File created in correct directory
   - [ ] Template has correct structure
   - [ ] Placeholders substituted correctly
   - [ ] File is valid markdown

3. **QTI conversion**
   - [ ] Script validates examark installed
   - [ ] Script validates input file exists
   - [ ] Conversion succeeds
   - [ ] Output file created
   - [ ] Question count displayed
   - [ ] Upload instructions shown

4. **Configuration**
   - [ ] Config template includes examark section
   - [ ] teach-init creates exam-to-qti.sh
   - [ ] Next steps mention optional exam workflow

5. **Integration**
   - [ ] teach-exam works in teaching project
   - [ ] teach-exam fails in non-teaching project
   - [ ] Exam directory created automatically
   - [ ] Multiple exams can be created

#### 4.2 Create Test Suite (Optional)

**File:** `tests/test-teaching-workflow-increment-3.zsh`

**Coverage:**
- teach-exam command validation
- Template generation
- Directory creation
- Error handling
- Config validation

---

## File Structure After Increment 3

```
flow-cli/
├── commands/
│   ├── teach-init.zsh          # Modified: add exam script
│   └── teach-exam.zsh          # NEW: exam creation command
│
├── lib/templates/teaching/
│   ├── teach-config.yml.template  # Modified: add examark section
│   ├── quick-deploy.sh
│   ├── semester-archive.sh
│   ├── exam-to-qti.sh          # NEW: QTI conversion script
│   └── exam-template.md        # NEW: exam template
│
├── docs/
│   ├── guides/
│   │   └── TEACHING-WORKFLOW.md   # Modified: add Increment 3
│   └── reference/
│       └── REFCARD-TEACHING.md    # Modified: add commands
│
└── tests/
    └── test-teaching-workflow-increment-3.zsh  # NEW: optional
```

---

## Risks & Mitigations

### Risk 1: examark Not Maintained

**Likelihood:** Medium
**Impact:** High

**Mitigation:**
- Document examark as optional dependency
- Provide fallback: manual Canvas question entry
- Consider alternative tools if examark deprecated

### Risk 2: examark Format Incompatibility

**Likelihood:** Medium
**Impact:** Medium

**Mitigation:**
- Test with current Canvas version
- Document known limitations
- Provide template that works with examark

### Risk 3: Low Adoption

**Likelihood:** Medium
**Impact:** Low

**Mitigation:**
- Keep as optional feature
- Clear documentation
- Example exam included

---

## Success Metrics

### Must Have

- ✅ teach-exam creates valid exam template
- ✅ exam-to-qti.sh converts markdown to QTI
- ✅ QTI file imports successfully into Canvas
- ✅ Documentation complete

### Nice to Have

- ✅ Question bank organization guide
- ✅ Multiple exam format examples
- ✅ Test suite with 10+ tests

---

## Timeline

**Total Estimate:** 8-10 hours

| Phase | Task | Hours |
|-------|------|-------|
| 1 | teach-exam command | 2h |
| 1 | Exam template | 1h |
| 1 | Config updates | 1h |
| 2 | QTI conversion script | 2h |
| 2 | teach-init integration | 0.5h |
| 2 | Next steps message | 0.5h |
| 3 | Documentation | 2h |
| 4 | Testing | 1h |
| **Total** | | **10h** |

---

## Incremental Delivery

### Milestone 1: Basic Workflow (6 hours)

- teach-exam command
- Exam template
- QTI conversion script
- Basic documentation

**Ship when:** Can create exam and convert to QTI

### Milestone 2: Polish (2 hours)

- Complete documentation
- Question bank guide
- Examples

**Ship when:** Documentation complete

### Milestone 3: Testing (2 hours)

- Manual testing
- Test suite (optional)

**Ship when:** All test cases pass

---

## Decision Points

### Should we include Scholar integration?

**Decision:** NO - Defer to future increment

**Rationale:**
- Scholar skills not yet available
- Adds complexity
- Manual authoring is sufficient for now

### Should we support multiple exam formats?

**Decision:** NO - Canvas QTI only

**Rationale:**
- examark focuses on Canvas
- Other formats (PDF, Gradescope) have different workflows
- Keep scope focused

### Should we include automated testing?

**Decision:** OPTIONAL - Manual testing sufficient

**Rationale:**
- examark is external dependency
- Manual testing covers core functionality
- Test suite can be added later if needed

---

## Next Steps

1. **Get approval** - Review this plan with stakeholders
2. **Install examark** - Test current version compatibility
3. **Create feature branch** - `feature/teaching-workflow-increment-3`
4. **Implement Phase 1** - Command & template
5. **Test end-to-end** - Create real exam, convert, upload to Canvas

---

## Questions to Resolve

1. **examark version compatibility**
   - What's the latest stable version?
   - Any known Canvas incompatibilities?

2. **Exam directory structure**
   - Where should exams live? (exams/ vs content/exams/)
   - How to organize question banks?

3. **Template complexity**
   - How detailed should default template be?
   - Include answer key in template?

4. **Canvas integration**
   - Test QTI import with current Canvas version
   - Document any Canvas-specific settings needed

---

## References

- examark: https://github.com/daveagp/examark
- Canvas QTI: https://canvas.instructure.com/doc/api/file.quiz_migration.html
- Teaching Workflow Spec: `docs/specs/SPEC-teaching-workflow-v2.md`
- Increment 2 Plan: `docs/specs/PLAN-teaching-workflow-increment-2.md`

---

**Status:** Ready for review
**Next:** Get approval → Create feature branch → Start implementation
