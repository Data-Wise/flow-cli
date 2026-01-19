# Course Planning Examples

This directory contains complete course planning examples demonstrating backward design implementation with flow-cli.

## Available Examples

### 1. STAT 545 - Exploratory Data Analysis (Graduate)

**Location:** `intermediate-stats/`
**Status:** ✅ Partially complete (configuration and lesson plans included)

**Course Context:**
- **Level:** Graduate (MS in Statistics)
- **Format:** Flipped classroom (2×75 min/week)
- **Credits:** 4
- **Enrollment:** ~25 students

**Files:**
- `stat-545-config.yml` - Complete teach-config.yml with backward design annotations
- `stat-545-lesson-week-05.yml` - Detailed WHERETO lesson plan for Week 5
- `stat-545-alignment-matrix.md` - Complete assessment alignment matrix
- `README.md` - Implementation notes and lessons learned

**Key Features:**
- 4 course-level learning outcomes (Bloom's L3-L6)
- 16-week semester with scaffolded progression
- Mixed assessment types (homework, exams, project)
- GRASPS-designed final project
- Scholar integration for content generation

**Use this example if:**
- Graduate-level statistics or data science course
- Small to medium enrollment (15-30 students)
- Emphasis on hands-on analysis and communication
- Flipped or blended learning format

---

### 2. STAT 101 - Introduction to Statistics (Undergraduate)

**Location:** `intro-stats/`
**Status:** 🚧 Phase 2 (Planned)

**Course Context:**
- **Level:** Undergraduate (100-level, General Education)
- **Format:** Large lecture (150 students) + labs (25 students/section)
- **Credits:** 3
- **Enrollment:** ~150 students across 6 lab sections

**Planned Files:**
- `stat-101-config.yml` - Configuration for large enrollment course
- `stat-101-lesson-week-03.yml` - Sample lesson plan
- `stat-101-lab-structure.md` - Lab coordination with lecture
- `stat-101-assessment-strategy.md` - Managing grading at scale

**Key Challenges:**
- Large enrollment (150+ students)
- Multiple TAs coordinating lab sections
- Mix of majors (diverse backgrounds)
- Standardized assessments across sections

**Use this example if:**
- Introductory undergraduate course
- Large enrollment with lab sections
- Need to coordinate multiple instructors/TAs
- Standardized assessment requirements

---

### 3. STAT 899 - Advanced Causal Inference (Doctoral Seminar)

**Location:** `advanced-seminar/`
**Status:** 🚧 Phase 2 (Planned)

**Course Context:**
- **Level:** Doctoral (PhD in Statistics)
- **Format:** Seminar (1×3 hours/week, discussion-based)
- **Credits:** 3
- **Enrollment:** ~10-12 students

**Planned Files:**
- `stat-899-config.yml` - Configuration for seminar format
- `stat-899-lesson-week-07.yml` - Sample discussion-based lesson
- `stat-899-paper-rubric.yml` - Presentation evaluation criteria
- `stat-899-research-proposal.md` - Final project structure

**Key Features:**
- Discussion-based (minimal lecture)
- Student presentations of research papers
- Final project: Original research proposal
- Peer review and feedback

**Use this example if:**
- Advanced graduate seminar
- Small enrollment (<15 students)
- Discussion and presentation focused
- Research skills development

---

## How to Use These Examples

### Step 1: Choose Your Template

Pick the example that most closely matches your course:
- **Large intro lecture?** → STAT 101
- **Graduate flipped classroom?** → STAT 545
- **Advanced seminar?** → STAT 899

### Step 2: Copy Configuration

```bash
# Copy example config to your course
cp docs/examples/course-planning/intermediate-stats/stat-545-config.yml \
   /path/to/your/course/.flow/teach-config.yml

# Edit with your course details
vim /path/to/your/course/.flow/teach-config.yml
```

### Step 3: Adapt to Your Context

**What to change:**
- Course name, instructor, semester dates
- Learning outcomes (keep structure, change content)
- Topics (match your syllabus)
- Assessment weights (match your grading policy)
- Scholar style (tone, notation, difficulty)

**What to keep:**
- Backward design structure (Stages 1-2-3)
- WHERETO lesson plan framework
- Alignment matrix structure
- Quality checklists

### Step 4: Generate Content

```bash
# Use Scholar with your configuration
teach lecture "Week 1: Introduction" --template quarto
teach exam "Midterm" --scope "Weeks 1-8"
teach assignment "HW1: Data Exploration"
```

---

## Comparison Matrix

| Feature | STAT 101 (Intro) | STAT 545 (Grad) | STAT 899 (Seminar) |
|---------|------------------|------------------|-------------------|
| **Enrollment** | 150+ | 15-30 | 10-12 |
| **Format** | Lecture + Lab | Flipped | Discussion |
| **Credits** | 3 | 4 | 3 |
| **Level** | 100 (GenEd) | 500 (MS) | 800 (PhD) |
| **Assessments** | Exams + HW + Labs | HW + Project + Exams | Presentations + Proposal |
| **Grading** | Auto-graded + TA | Mix of auto/manual | Instructor graded |
| **Technology** | Learning Management System | GitHub + Quarto | Papers + Zotero |
| **Scholar Use** | High (standardized content) | Medium (custom analysis) | Low (paper-based) |
| **TAs** | 6 lab TAs | 1-2 graders | None |

---

## File Structure

Each example directory contains:

```
example-course/
├── README.md                      # Implementation notes
├── <course>-config.yml            # Complete teach-config.yml
├── <course>-lesson-week-XX.yml    # Sample lesson plan(s)
├── <course>-alignment-matrix.md   # Assessment alignment
├── <course>-syllabus.md           # Sample syllabus
├── assessments/                   # Sample assessments
│   ├── exam-midterm.md
│   ├── homework-01.md
│   └── project-rubric.md
└── lessons/                       # Sample lesson materials
    ├── week-01-slides.qmd
    └── week-01-code.R
```

---

## Contributing Examples

Have a course using flow-cli? Share it as an example!

**Submission guidelines:**
1. Anonymize student data
2. Include complete config + 2-3 lesson plans
3. Document what worked well and challenges
4. Create PR with new directory under `course-planning/`

**Contact:**
- GitHub: https://github.com/Data-Wise/flow-cli/issues
- Label: `example-submission`

---

## Related Documentation

- [Course Planning Best Practices](../guides/COURSE-PLANNING-BEST-PRACTICES.md) - Main guide (18,000+ lines)
- [Backward Design Walkthrough](../guides/COURSE-PLANNING-BEST-PRACTICES.md#2-backward-design-principles) - Section 2
- [Teaching Workflow v3.0 Guide](../guides/TEACHING-WORKFLOW-V3-GUIDE.md) - Implementation workflow
- [Teach Dispatcher Reference](../reference/TEACH-DISPATCHER-REFERENCE-v5.14.0.md) - Command documentation

---

**Last Updated:** 2026-01-19
**Version:** v5.14.0 (Phase 1)
