# STAT 545: Exploratory Data Analysis

**Complete backward design example for graduate-level statistics course using flow-cli**

## Course Overview

**Course:** STAT 545 - Exploratory Data Analysis
**Level:** Graduate (MS in Statistics)
**Format:** Flipped classroom (2×75 min/week)
**Credits:** 4
**Typical enrollment:** 25 students
**Prerequisites:** Intro statistics, basic R programming

---

## Files in This Directory

### 1. stat-545-config.yml ✅

Complete `teach-config.yml` demonstrating:
- **Stage 1:** 4 learning outcomes (Bloom's L3-L6)
- **Stage 2:** Full assessment alignment matrix with I/R/M progression
- **Stage 3:** Course structure overview (detailed plans in lesson-plan.yml)
- **Scholar integration:** Style, difficulty, topics
- **GRASPS project design:** Final project with authentic performance task

**Use this as a template for:**
- Graduate-level statistics/data science courses
- Courses emphasizing hands-on analysis
- Mixed assessment types (homework, exams, projects)
- Courses with 15-30 student enrollment

---

### 2. stat-545-lesson-week-05.yml 🚧

**Status:** Planned for Phase 2

**Will include:**
- Complete WHERETO lesson plan for Week 5 (Simple Linear Regression)
- Both class sessions (Monday + Wednesday)
- Hook: Anscombe's quartet
- Activities: Live coding, group practice, discussion
- Formative assessments: Exit tickets, practice quiz
- Differentiation for beginners and advanced students
- Materials list: Slides, code, data

**See:** Section 2.7 in COURSE-PLANNING-BEST-PRACTICES.md for inline version

---

### 3. stat-545-alignment-matrix.md 🚧

**Status:** Planned for Phase 2

**Will include:**
- Visual representation of assessment alignment
- Verification that all outcomes assessed 3+ times
- I→R→M progression checks
- Bloom's level alignment (assessment ≥ outcome)

**See:** Section 2.3 in COURSE-PLANNING-BEST-PRACTICES.md for inline version

---

## Backward Design Implementation

This example demonstrates complete 3-stage backward design:

### Stage 1: Desired Results

**4 Learning Outcomes:**
1. **LO1 (Analyze):** Visualize and explore multivariate data
2. **LO2 (Evaluate):** Build and diagnose regression models
3. **LO3 (Create):** Communicate findings to diverse audiences
4. **LO4 (Apply):** Wrangle messy real-world data

**Essential Questions:**
- "How can we let data tell its story without imposing preconceptions?"
- "When should we trust a pattern we see in data?"
- "What makes a data visualization 'good'?"
- "How do we balance model complexity with interpretability?"

---

### Stage 2: Assessment Evidence

**Assessment Mix:**
- **Homework (30%):** 4 assignments, progressive scaffolding
- **Midterm (15%):** Week 8, covers fundamentals
- **Project (30%):** GRASPS-designed consulting report
- **Final Exam (30%):** Comprehensive, emphasis on Weeks 9-16

**Alignment Matrix Highlights:**
- Every outcome assessed 3-5 times
- I→R→M progression implemented
- Multiple evidence types (homework, exams, project)

**Example alignment for LO2 (Build models):**
```
HW3 (R/20%) → HW4 (M/25%) → Midterm (R/20%) → Project (M/20%) → Final (M/30%)
```

---

### Stage 3: Learning Experiences

**16-Week Structure:**
- **Weeks 1-4:** Foundations (visualize, wrangle)
- **Weeks 5-10:** Modeling (regression, diagnostics, selection)
- **Weeks 11-16:** Integration (advanced topics, project)

**Scaffolding:**
- HW1: Heavy templating
- HW2: Moderate templating
- HW3: Minimal templating
- HW4: No templating (project prep)

**WHERETO Framework:**
- Every lesson addresses all 7 elements (see Week 5 example)
- Essential questions revisited throughout semester
- Reflection built into every class (exit tickets)

---

## How to Use This Example

### Option 1: Direct Adaptation

If teaching similar course (graduate stats, ~25 students, 4 credits):

```bash
# 1. Copy configuration
cp stat-545-config.yml /path/to/your/course/.flow/teach-config.yml

# 2. Edit course-specific details
vim /path/to/your/course/.flow/teach-config.yml
# Change: name, instructor, dates, topics (keep structure)

# 3. Generate content with Scholar
cd /path/to/your/course
teach lecture "Week 1: Introduction" --template quarto
teach exam "Midterm" --scope "Weeks 1-8"
```

---

### Option 2: Selective Borrowing

If teaching different course, borrow specific elements:

**Learning Outcomes:**
- Copy outcome structure (id, description, bloom_level, assessments)
- Adapt to your content area
- Keep 3-5 outcomes (not more)

**Assessment Alignment:**
- Copy alignment_alignment structure
- Map your assessments to outcomes
- Verify I→R→M progression

**GRASPS Project:**
- Copy GRASPS structure
- Adapt Goal, Role, Audience, Situation to your context
- Adjust rubric weights

**Scholar Configuration:**
- Copy scholar section
- Change field, difficulty, topics
- Adjust style (tone, notation)

---

## Implementation Timeline

**8 weeks before semester:**
- ✅ Stage 1 complete (outcomes, essential questions)
- ✅ Stage 2 complete (assessments designed, alignment verified)
- ✅ Configuration file created

**6 weeks before:**
- 🚧 Stage 3 (detailed lesson plans for all 16 weeks)
- 🚧 Create Week 1-4 materials (lectures, slides, code)

**4 weeks before:**
- 🚧 Create all homework assignments
- 🚧 Create exams (midterm, final)
- 🚧 Finalize project rubric

**2 weeks before:**
- 🚧 Deploy website (draft branch)
- 🚧 Test all materials
- 🚧 Run `teach doctor` to verify environment

---

## Key Decisions & Rationale

### Why 4 outcomes (not more)?

**Rationale:** Cognitive load limits. Students can master 3-5 big ideas per course. More outcomes = superficial coverage.

**Research:** Ambrose et al. (2010) - "Students need sufficient time to practice and receive feedback on learning goals"

---

### Why GRASPS for final project?

**Rationale:** Authentic performance tasks require real-world context. GRASPS provides structure for designing authentic assessments.

**Research:** Wiggins & McTighe (1998) - "Students transfer learning better when tasks mirror real-world complexity"

---

### Why I→R→M progression?

**Rationale:** Learning requires multiple exposures with increasing complexity. First exposure (I) is low-stakes, final assessment (M) expects proficiency.

**Research:** Brown et al. (2014) - "Spaced practice with increasing difficulty enhances retention"

---

### Why formative assessments matter?

**Rationale:** Weekly exit tickets + practice quizzes catch misunderstandings early, before high-stakes assessments.

**Research:** Black & Wiliam (1998) - "Formative assessment can raise achievement by 0.4-0.7 SD"

---

## Lessons Learned (After Implementation)

**This section will be updated after first offering of the course.**

**Planned reflections:**
- What worked well?
- What would I change?
- Student feedback highlights
- Time estimates vs reality
- Assessment weights (need adjustment?)

---

## Related Documentation

**Main Guide:**
- [Course Planning Best Practices](../../guides/COURSE-PLANNING-BEST-PRACTICES.md) - Full 18,000+ line guide
- Section 2.5: STAT 545 Backward Design Walkthrough (detailed explanation)

**flow-cli Documentation:**
- [Teaching Workflow v3.0 Guide](../../guides/TEACHING-WORKFLOW-V3-GUIDE.md) - Implementation workflow
- [Teach Dispatcher Reference](../../reference/TEACH-DISPATCHER-REFERENCE-v5.14.0.md) - Commands

**Educational Research:**
- Wiggins, G., & McTighe, J. (1998). *Understanding by Design*. ASCD.
- Ambrose, S. A., et al. (2010). *How Learning Works*. Jossey-Bass.
- Brown, P. C., et al. (2014). *Make It Stick*. Harvard University Press.
- Black, P., & Wiliam, D. (1998). "Assessment and classroom learning." *Assessment in Education*, 5(1), 7-74.

---

## Contact & Contributions

**Questions about this example:**
- GitHub Issues: https://github.com/Data-Wise/flow-cli/issues
- Label: `example-stat-545`

**Improvements:**
- PR welcome with updated materials after course implementation
- Share lessons learned via GitHub Discussions

---

**Last Updated:** 2026-01-19
**Status:** Phase 1 complete (config file), Phase 2 planned (lesson plans)
**Version:** v5.14.0
