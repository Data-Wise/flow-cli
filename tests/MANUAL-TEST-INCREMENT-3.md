# Manual Testing Guide - Increment 3 (Exam Workflow)

**Version:** 2.0 (Increment 3)
**Created:** 2026-01-11
**Purpose:** Manual testing checklist for exam workflow features

---

## Prerequisites

### Required Tools

- [ ] ZSH shell
- [ ] flow-cli installed (feature/teaching-workflow branch)
- [ ] yq installed: `brew install yq`
- [ ] examark installed: `npm install -g examark`
- [ ] Git repository initialized

### Test Environment Setup

```bash
# 1. Create test course directory
mkdir -p ~/test-teaching-exam-workflow
cd ~/test-teaching-exam-workflow

# 2. Initialize git
git init
git add -A
git commit --allow-empty -m "Initial commit"

# 3. Source flow-cli (if not in PATH)
source /path/to/flow-cli/flow.plugin.zsh

# 4. Verify examark installed
examark --version
# Expected: 0.6.6 or higher
```

---

## Test Suite 1: teach-exam Command

### Test 1.1: Command Without Arguments

**Test:**

```bash
teach-exam
```

**Expected Output:**

```
✗ Usage: teach-exam <topic>

Examples:
  teach-exam "Midterm 1: Weeks 1-8"
  teach-exam "Final Exam"
  teach-exam "Quiz 3: ANOVA"
```

**Result:** [ ] PASS / [ ] FAIL

---

### Test 1.2: Command Without Teaching Project

**Test:**

```bash
# From non-teaching project directory
cd ~/test-teaching-exam-workflow
teach-exam "Test Exam"
```

**Expected Output:**

```
✗ Not in a teaching project
Run this command from a teaching project directory
Initialize with: teach-init "Course Name"
```

**Result:** [ ] PASS / [ ] FAIL

---

### Test 1.3: Initialize Teaching Project

**Test:**

```bash
teach-init "Test Course" <<EOF
1
y
2026-01-13


EOF
```

**Expected:**

- [ ] Prompts for migration strategy (choose 1)
- [ ] Prompts for semester dates (accept defaults)
- [ ] Creates `.flow/teach-config.yml`
- [ ] Creates `scripts/` directory
- [ ] Copies `quick-deploy.sh`, `semester-archive.sh`, `exam-to-qti.sh`
- [ ] Shows next steps with optional exam workflow step

**Verify Files:**

```bash
ls -lh scripts/exam-to-qti.sh
# Expected: Executable file exists

yq -r '.examark.enabled' .flow/teach-config.yml
# Expected: false
```

**Result:** [ ] PASS / [ ] FAIL

---

### Test 1.4: teach-exam Without examark Enabled

**Test:**

```bash
teach-exam "Test Midterm 1" <<EOF
y
90
50
test-midterm1
EOF
```

**Expected Output:**

- Warning: "⚠️ examark not enabled in config"
- Instructions to enable
- Prompt: "Continue anyway? [y/N]"
- After 'y': Creates exam file

**Verify:**

```bash
ls -lh exams/test-midterm1.md
# Expected: File exists

head -20 exams/test-midterm1.md
# Expected: Has frontmatter with title, duration, points
```

**Result:** [ ] PASS / [ ] FAIL

---

### Test 1.5: Enable examark in Config

**Test:**

```bash
yq -i '.examark.enabled = true' .flow/teach-config.yml

# Verify
yq -r '.examark.enabled' .flow/teach-config.yml
```

**Expected:** `true`

**Result:** [ ] PASS / [ ] FAIL

---

### Test 1.6: teach-exam With examark Enabled

**Test:**

```bash
teach-exam "Midterm 2: Advanced Topics" <<EOF
120
100
midterm2
EOF
```

**Expected:**

- [ ] No warning about examark
- [ ] Prompts for duration [120]: (press Enter for default)
- [ ] Prompts for points [100]: (press Enter for default)
- [ ] Prompts for filename
- [ ] Creates `exams/midterm2.md`
- [ ] Shows next steps

**Verify File Content:**

```bash
cat exams/midterm2.md | head -30
```

**Expected Content:**

- [ ] Frontmatter with title, course, duration, points
- [ ] Multiple choice section
- [ ] Short answer section
- [ ] Computational problems section
- [ ] Answer key section

**Result:** [ ] PASS / [ ] FAIL

---

### Test 1.7: Custom Duration and Points

**Test:**

```bash
teach-exam "Quiz 1" <<EOF
45
25
quiz1
EOF
```

**Expected:**

```bash
grep "duration: 45" exams/quiz1.md
grep "points: 25" exams/quiz1.md
```

**Both should return matches**

**Result:** [ ] PASS / [ ] FAIL

---

### Test 1.8: Default Filename Generation

**Test:**

```bash
teach-exam "Final Exam: Comprehensive" <<EOF
180
150

EOF
```

**Expected:**

- Default filename: `final-exam-comprehensive`
- Creates: `exams/final-exam-comprehensive.md`

**Verify:**

```bash
ls exams/final-exam-comprehensive.md
```

**Result:** [ ] PASS / [ ] FAIL

---

### Test 1.9: Overwrite Existing File

**Test:**

```bash
# Create exam first
teach-exam "Test Overwrite" <<EOF
60
50
overwrite-test
EOF

# Try to create again with same filename
teach-exam "Test Overwrite Updated" <<EOF
90
75
overwrite-test
y
EOF
```

**Expected:**

- [ ] Warning: "File already exists"
- [ ] Prompt: "Overwrite? [y/N]"
- [ ] After 'y': File is overwritten with new content

**Verify:**

```bash
grep "Test Overwrite Updated" exams/overwrite-test.md
# Should find the new title
```

**Result:** [ ] PASS / [ ] FAIL

---

### Test 1.10: Cancel Overwrite

**Test:**

```bash
teach-exam "Test Overwrite" <<EOF
60
50
overwrite-test
n
EOF
```

**Expected:**

- Warning about existing file
- After 'n': "Cancelled"
- File remains unchanged

**Result:** [ ] PASS / [ ] FAIL

---

## Test Suite 2: Exam Template Validation

### Test 2.1: Template Structure

**Test:**

```bash
cat exams/midterm2.md
```

**Verify Template Sections:**

- [ ] Frontmatter (---, title, course, duration, points, ---)
- [ ] Course name populated from config
- [ ] Header with Name, Date fields
- [ ] Instructions section
- [ ] Section 1: Multiple Choice (~30 points)
- [ ] Section 2: Short Answer (~40 points)
- [ ] Section 3: Problems (~30 points)
- [ ] Answer Key section
- [ ] Example questions in each section

**Result:** [ ] PASS / [ ] FAIL

---

### Test 2.2: Multiple Choice Question Format

**Test:**

```bash
grep -A 5 "Multiple Choice" exams/midterm2.md | head -10
```

**Expected Format:**

```markdown
1. [3 pts] Question text here?
   - [ ] Option A
   - [ ] Option B
   - [x] Option C (correct answer)
   - [ ] Option D
```

**Verify:**

- [ ] Question numbering
- [ ] Point values in brackets
- [ ] Checkbox format (- [ ] and - [x])
- [ ] Correct answer marked with [x]

**Result:** [ ] PASS / [ ] FAIL

---

### Test 2.3: Answer Key Format

**Test:**

```bash
grep -A 20 "Answer Key" exams/midterm2.md
```

**Expected:**

- [ ] "Answer Key (Instructor Only)" header
- [ ] Answers for each section
- [ ] Explanations provided
- [ ] Rubric breakdown for short answer

**Result:** [ ] PASS / [ ] FAIL

---

## Test Suite 3: QTI Conversion Script

### Test 3.1: Script Without Arguments

**Test:**

```bash
./scripts/exam-to-qti.sh
```

**Expected Output:**

```
❌ No input file specified

Usage: ./scripts/exam-to-qti.sh <exam-file.md>

Examples:
  ./scripts/exam-to-qti.sh exams/midterm1.md
  ./scripts/exam-to-qti.sh exams/final.md
```

**Result:** [ ] PASS / [ ] FAIL

---

### Test 3.2: Script With Non-existent File

**Test:**

```bash
./scripts/exam-to-qti.sh exams/nonexistent.md
```

**Expected Output:**

```
❌ File not found: exams/nonexistent.md
```

**Result:** [ ] PASS / [ ] FAIL

---

### Test 3.3: Script With Non-markdown File

**Test:**

```bash
touch exams/test.txt
./scripts/exam-to-qti.sh exams/test.txt <<EOF
n
EOF
```

**Expected:**

- Warning: "File does not have .md extension"
- Prompt: "Continue anyway? [y/N]"
- After 'n': "Cancelled"

**Result:** [ ] PASS / [ ] FAIL

---

### Test 3.4: Convert Valid Exam to QTI

**Test:**

```bash
./scripts/exam-to-qti.sh exams/midterm2.md
```

**Expected Output:**

- [ ] "🔄 Converting exam to Canvas QTI..."
- [ ] Shows input and output filenames
- [ ] "✅ Converted successfully"
- [ ] Shows question count (~X questions)
- [ ] Shows Canvas upload instructions

**Verify Output File:**

```bash
ls -lh exams/midterm2.zip
file exams/midterm2.zip
```

**Expected:**

- [ ] ZIP file created
- [ ] File type is "Zip archive data"

**Result:** [ ] PASS / [ ] FAIL

---

### Test 3.5: Inspect QTI ZIP Contents

**Test:**

```bash
unzip -l exams/midterm2.zip
```

**Expected:**

- [ ] Contains XML files
- [ ] Contains manifest file
- [ ] Contains question items

**Result:** [ ] PASS / [ ] FAIL

---

### Test 3.6: Conversion Without examark Installed

**Test:**

```bash
# Temporarily move examark
which examark
# Note the path, then:
sudo mv $(which examark) $(which examark).bak

# Try conversion
./scripts/exam-to-qti.sh exams/midterm2.md

# Restore examark
sudo mv $(which examark).bak $(which examark)
```

**Expected Output:**

```
❌ examark not installed

Install examark:
  npm install -g examark
```

**Result:** [ ] PASS / [ ] FAIL

---

### Test 3.7: Convert Exam With Invalid Format

**Test:**

```bash
# Create invalid exam (missing frontmatter)
cat > exams/invalid.md <<EOF
# Invalid Exam

This has no frontmatter.

1. Question without point value?
   - Option A
   - Option B
EOF

./scripts/exam-to-qti.sh exams/invalid.md
```

**Expected:**

- Conversion fails
- Error message shown
- Suggestions for common issues

**Result:** [ ] PASS / [ ] FAIL

---

## Test Suite 4: Configuration

### Test 4.1: Default examark Configuration

**Test:**

```bash
yq '.examark' .flow/teach-config.yml
```

**Expected Output:**

```yaml
enabled: true
exam_dir: 'exams'
question_bank: 'exams/questions'
default_duration: 120
default_points: 100
```

**Result:** [ ] PASS / [ ] FAIL

---

### Test 4.2: Custom Exam Directory

**Test:**

```bash
# Change config
yq -i '.examark.exam_dir = "assessments"' .flow/teach-config.yml

# Create exam
teach-exam "Test Custom Dir" <<EOF
60
50
custom-dir
EOF

# Verify
ls assessments/custom-dir.md
```

**Expected:** File created in `assessments/` directory

**Result:** [ ] PASS / [ ] FAIL

**Cleanup:**

```bash
yq -i '.examark.exam_dir = "exams"' .flow/teach-config.yml
```

---

### Test 4.3: Custom Default Duration

**Test:**

```bash
# Change config
yq -i '.examark.default_duration = 90' .flow/teach-config.yml

# Create exam (accept default)
teach-exam "Test Duration" <<EOF

75
test-duration
EOF

# Verify
grep "duration: 90" exams/test-duration.md
```

**Expected:** Duration is 90 minutes

**Result:** [ ] PASS / [ ] FAIL

**Cleanup:**

```bash
yq -i '.examark.default_duration = 120' .flow/teach-config.yml
```

---

### Test 4.4: Custom Default Points

**Test:**

```bash
# Change config
yq -i '.examark.default_points = 75' .flow/teach-config.yml

# Create exam (accept default)
teach-exam "Test Points" <<EOF
60

test-points
EOF

# Verify
grep "points: 75" exams/test-points.md
```

**Expected:** Points is 75

**Result:** [ ] PASS / [ ] FAIL

**Cleanup:**

```bash
yq -i '.examark.default_points = 100' .flow/teach-config.yml
```

---

## Test Suite 5: Question Bank Organization

### Test 5.1: Create Question Bank Structure

**Test:**

```bash
mkdir -p exams/questions

# Create topic-based question files
cat > exams/questions/regression.md <<EOF
## Regression Questions

1. [5 pts] What is simple linear regression?
   - [ ] A non-linear model
   - [x] A model with one predictor
   - [ ] A model with multiple predictors
   - [ ] A classification method

2. [10 pts] Explain the least squares criterion.

   **Answer:**
   <!-- Minimize sum of squared residuals -->
EOF

cat > exams/questions/anova.md <<EOF
## ANOVA Questions

1. [5 pts] What does ANOVA stand for?
   - [ ] Analysis of Variables
   - [x] Analysis of Variance
   - [ ] Analysis of Variation
   - [ ] Analysis of Values
EOF

# Verify
ls -lh exams/questions/
```

**Expected:**

- [ ] `regression.md` created
- [ ] `anova.md` created
- Both files in `exams/questions/` directory

**Result:** [ ] PASS / [ ] FAIL

---

### Test 5.2: Reuse Questions in Exam

**Test:**

```bash
# Create new exam
teach-exam "Comprehensive Final" <<EOF
180
150
final
EOF

# Append questions from question bank
cat exams/questions/regression.md >> exams/final.md
cat exams/questions/anova.md >> exams/final.md

# Verify
grep "Regression Questions" exams/final.md
grep "ANOVA Questions" exams/final.md
```

**Expected:** Both question sets appear in final exam

**Result:** [ ] PASS / [ ] FAIL

---

## Test Suite 6: Integration Tests

### Test 6.1: End-to-End Workflow

**Test:** Complete exam creation → conversion → upload workflow

```bash
# 1. Enable examark (if not already)
yq -i '.examark.enabled = true' .flow/teach-config.yml

# 2. Create exam
teach-exam "Integration Test Exam" <<EOF
90
100
integration-test
EOF

# 3. Verify exam created
ls -lh exams/integration-test.md

# 4. Edit exam (manual: add/remove questions as needed)
# Skip for automated testing

# 5. Convert to QTI
./scripts/exam-to-qti.sh exams/integration-test.md

# 6. Verify ZIP created
ls -lh exams/integration-test.zip

# 7. Inspect ZIP contents
unzip -l exams/integration-test.zip
```

**Expected:**

- [ ] Exam markdown file created
- [ ] ZIP file created
- [ ] ZIP contains XML and manifest
- [ ] Ready for Canvas upload

**Result:** [ ] PASS / [ ] FAIL

---

### Test 6.2: Multiple Exams in Same Course

**Test:**

```bash
# Create multiple exams
teach-exam "Midterm 1" <<EOF
90
100
midterm1-multi
EOF

teach-exam "Midterm 2" <<EOF
90
100
midterm2-multi
EOF

teach-exam "Final" <<EOF
180
150
final-multi
EOF

# Verify all created
ls -lh exams/ | grep multi
```

**Expected:**

- [ ] All three exams created
- [ ] No conflicts or overwrites
- [ ] Each has unique filename

**Result:** [ ] PASS / [ ] FAIL

---

### Test 6.3: teach-init Next Steps Include Exam Workflow

**Test:**

```bash
# In a fresh directory
mkdir -p ~/test-exam-next-steps
cd ~/test-exam-next-steps
git init
git commit --allow-empty -m "init"

teach-init "Next Steps Test" <<EOF
1
n

n
EOF
```

**Expected Output Should Include:**

```
5. (Optional) Enable exam workflow:
     npm install -g examark
     yq -i '.examark.enabled = true' .flow/teach-config.yml
     teach-exam "Midterm 1"
```

**Result:** [ ] PASS / [ ] FAIL

---

## Test Suite 7: Error Handling

### Test 7.1: teach-exam With Invalid Course Name Characters

**Test:**

```bash
teach-exam "Test/Exam:With|Special*Chars" <<EOF
60
50

EOF
```

**Expected:**

- Filename sanitized (slashes, colons, pipes removed)
- File created successfully

**Verify:**

```bash
ls exams/test-exam-with-special-chars.md
```

**Result:** [ ] PASS / [ ] FAIL

---

### Test 7.2: Conversion With Missing examark Dependency

**Already tested in Test 3.6**

**Result:** [ ] PASS / [ ] FAIL

---

### Test 7.3: teach-exam With Empty Topic

**Test:**

```bash
teach-exam "" <<EOF
60
50
empty-topic
EOF
```

**Expected:**

- Usage error shown
- No file created

**Result:** [ ] PASS / [ ] FAIL

---

## Test Suite 8: Documentation Verification

### Test 8.1: Help Available

**Test:**

```bash
teach-exam --help
```

**Expected:** Shows usage information

**Result:** [ ] PASS / [ ] FAIL

---

### Test 8.2: Script Comments and Documentation

**Test:**

```bash
head -20 scripts/exam-to-qti.sh
head -20 commands/teach-exam.zsh
```

**Expected:**

- [ ] Script header with description
- [ ] Usage examples
- [ ] Requirements listed

**Result:** [ ] PASS / [ ] FAIL

---

## Test Suite 9: Canvas Integration (Manual)

### Test 9.1: Upload to Canvas

**Prerequisites:**

- Access to Canvas course
- Admin/instructor permissions

**Steps:**

1. [ ] Go to Canvas course
2. [ ] Navigate to: Quizzes
3. [ ] Click: Import
4. [ ] Select: QTI 1.2/1.1 Package
5. [ ] Upload: `exams/integration-test.zip`
6. [ ] Click: Import
7. [ ] Wait for import to complete
8. [ ] Review imported questions

**Expected:**

- [ ] Import succeeds
- [ ] Multiple choice questions imported
- [ ] Point values correct
- [ ] Question text preserved
- [ ] Answer options present

**Result:** [ ] PASS / [ ] FAIL / [ ] SKIPPED

**Notes:**
_Record any issues with Canvas import here_

---

### Test 9.2: Edit Quiz in Canvas

**Steps:**

1. [ ] Open imported quiz
2. [ ] Edit settings (time limit, availability)
3. [ ] Preview quiz
4. [ ] Verify questions display correctly
5. [ ] Check answer shuffling works
6. [ ] Publish quiz

**Expected:**

- [ ] All settings editable
- [ ] Quiz displays properly
- [ ] Answers can be shuffled
- [ ] Quiz publishable

**Result:** [ ] PASS / [ ] FAIL / [ ] SKIPPED

---

## Test Summary

**Date Tested:** **\*\***\_\_\_**\*\***
**Tester:** **\*\***\_\_\_**\*\***
**Branch:** feature/teaching-workflow
**Commit:** **\*\***\_\_\_**\*\***

### Results Summary

| Test Suite             | Tests  | Passed     | Failed     | Skipped    |
| ---------------------- | ------ | ---------- | ---------- | ---------- |
| 1. teach-exam Command  | 10     | \_\_\_     | \_\_\_     | \_\_\_     |
| 2. Template Validation | 3      | \_\_\_     | \_\_\_     | \_\_\_     |
| 3. QTI Conversion      | 7      | \_\_\_     | \_\_\_     | \_\_\_     |
| 4. Configuration       | 4      | \_\_\_     | \_\_\_     | \_\_\_     |
| 5. Question Banks      | 2      | \_\_\_     | \_\_\_     | \_\_\_     |
| 6. Integration         | 3      | \_\_\_     | \_\_\_     | \_\_\_     |
| 7. Error Handling      | 3      | \_\_\_     | \_\_\_     | \_\_\_     |
| 8. Documentation       | 2      | \_\_\_     | \_\_\_     | \_\_\_     |
| 9. Canvas Integration  | 2      | \_\_\_     | \_\_\_     | \_\_\_     |
| **TOTAL**              | **36** | **\_\_\_** | **\_\_\_** | **\_\_\_** |

### Overall Result

[ ] **PASS** - All critical tests passed
[ ] **PASS WITH WARNINGS** - Some non-critical issues
[ ] **FAIL** - Critical issues found

### Issues Found

1. ***
2. ***
3. ***

### Notes

---

---

---

---

## Cleanup

After testing, clean up test environment:

```bash
# Remove test course
rm -rf ~/test-teaching-exam-workflow
rm -rf ~/test-exam-next-steps

# Verify examark still installed
examark --version
```

---

**End of Manual Test Document**
