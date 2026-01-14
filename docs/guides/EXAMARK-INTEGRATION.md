# examark Integration Guide

**Version:** Teaching Workflow v2.0 (Increment 3)
**Last Updated:** 2026-01-12

---

## Overview

The Teaching Workflow integrates with **examark** (v0.6.6+) to convert markdown-formatted exams to Canvas QTI format for direct upload to Canvas LMS.

---

## examark Features

### Built-in Validation

```bash
# Check exam syntax before conversion
examark check exams/midterm1.md

# Shows errors and warnings
# - Question type validation
# - Correct answer marking
# - Point value verification
# - Duplicate question ID detection
```

### Canvas Compatibility Testing

```bash
# Emulate Canvas import process
examark emulate-canvas exams/midterm1.zip

# Tests:
# - QTI package structure
# - Question format compatibility
# - Answer key handling
# - Point value assignment
```

### Question Type Support

examark supports 8 question types:

| Type | Tag | Example |
|------|-----|---------|
| Multiple Choice | `[MC]` | Single correct answer |
| Multiple Answers | `[MA]` | Select all that apply |
| True/False | `[TF]` | Binary choice |
| Short Answer | `[Short]` | Fill-in-blank |
| Essay | `[Essay]` | Long-form response |
| Numerical | `[Num]` | Numbers with tolerance |
| Matching | `[Match]` | Pair items |
| Fill Multiple Blanks | `[FMB]` | Multiple blanks |

---

## Workflow Integration

### 1. Command: teach-exam

Creates markdown exam from template:

```bash
$ teach-exam "Midterm 1"

📝 Creating exam: Midterm 1

Exam Details
  Duration (minutes) [120]: 90
  Total points [100]: 75
  Filename (without .md) [midterm-1]:

✅ Exam template created: exams/midterm-1.md

Next steps:
  1. Edit exam: $EDITOR exams/midterm-1.md
  2. Convert to Canvas QTI: ./scripts/exam-to-qti.sh exams/midterm-1.md
```

### 2. Script: exam-to-qti.sh

Enhanced conversion script with validation:

```bash
$ ./scripts/exam-to-qti.sh exams/midterm-1.md

🔄 Converting exam to Canvas QTI...

Input:  exams/midterm-1.md
Output: exams/midterm-1.zip

Validating exam format...
Checking file: exams/midterm-1.md...
✅ No errors found

Converting to Canvas QTI format...
✅ Converted successfully

Output file: exams/midterm-1.zip
Questions:   ~15

Testing Canvas compatibility...
✅ Canvas compatibility check passed

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Upload to Canvas:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. Go to your Canvas course
2. Navigate to: Quizzes
3. Click: Import
4. Select: QTI 1.2/1.1 Package
5. Upload: exams/midterm-1.zip
6. Click: Import
```

---

## examark Syntax

### Multiple Choice Questions

```markdown
1. [MC] What is the primary purpose of statistical hypothesis testing? [3pts]
a) To prove that a hypothesis is true
b) To calculate the exact probability of an event
c) To make decisions about population parameters based on sample data [x]
d) To eliminate all sources of variability in data
```

**Key elements:**
- Question number: `1.`
- Type tag: `[MC]`
- Question text
- Point value: `[3pts]`
- Options: `a)`, `b)`, `c)`, `d)`
- Correct answer marker: `[x]`

### Essay Questions

```markdown
1. [Essay] Explain the difference between Type I and Type II errors in hypothesis testing. [10pts]
```

**Key elements:**
- Type tag: `[Essay]`
- Question text
- Point value: `[10pts]`
- No options needed

### Numerical Questions

```markdown
1. [Num] Calculate the test statistic. Round to 2 decimal places. [5pts]
```

**Key elements:**
- Type tag: `[Num]`
- Question text with precision instructions
- Point value: `[5pts]`
- Answer accepted with tolerance

---

## Answer Key Handling

### Important Note

examark parses the entire markdown file. The answer key section in the template will be treated as additional questions unless properly handled.

### Recommended Approach

**Option 1: Remove answer key before conversion**

```bash
# Create exam without answer key for students
sed '/## Answer Key/,$d' exams/midterm1.md > exams/midterm1-student.md

# Convert student version
examark exams/midterm1-student.md
```

**Option 2: Keep answer key in separate file**

```bash
# Create two files
exams/midterm1.md          # Student version (no answers)
exams/midterm1-key.md      # Instructor version (with answers)
```

**Option 3: Use answer key for reference only**

- Keep answer key in markdown file for instructor reference
- Canvas QTI import ignores instructor notes
- Students won't see answer key in Canvas quiz

---

## Validation Workflow

### Pre-Conversion Checklist

1. **Run examark check**
   ```bash
   examark check exams/midterm1.md
   ```

2. **Fix errors**
   - Ensure all MC questions have `[MC]` tag
   - Mark correct answers with `[x]`
   - Verify unique question IDs
   - Check point value format `[Xpts]`

3. **Convert to QTI**
   ```bash
   ./scripts/exam-to-qti.sh exams/midterm1.md
   ```

4. **Test Canvas compatibility**
   ```bash
   examark emulate-canvas exams/midterm1.zip
   ```

### Common Validation Errors

#### Error: No correct answer marked

```
✗ Line 38: No correct answer marked. Use **bold** or *italics* to mark the correct option.
```

**Fix:** Add `[x]` after the correct answer:
```markdown
c) Correct answer [x]
```

#### Error: Question type missing

```
✗ Line 45: Question type tag missing or invalid
```

**Fix:** Add type tag after question number:
```markdown
1. [MC] Question text? [3pts]
```

#### Error: Duplicate Question ID

```
✗ Line 52: Duplicate Question ID found: 1
```

**Fix:** Ensure questions are numbered sequentially without repeats.

---

## Canvas Import Process

### Step-by-Step

1. **Log into Canvas**
   - Navigate to your course

2. **Go to Quizzes**
   - Click "Quizzes" in left navigation

3. **Import Quiz**
   - Click "+ Quiz" button
   - Or: Select existing quiz → Settings → Import

4. **Upload QTI Package**
   - Choose "QTI 1.2/1.1 Package"
   - Click "Choose File"
   - Select the `.zip` file created by examark
   - Click "Import"

5. **Review Questions**
   - Canvas will process the import
   - Review each question
   - Verify point values
   - Check answer key
   - Adjust settings as needed

6. **Publish Quiz**
   - Set availability dates
   - Configure time limit
   - Enable/disable features
   - Click "Save & Publish"

### Post-Import Verification

- [ ] All questions imported correctly
- [ ] Point values match expected total
- [ ] Correct answers are marked properly
- [ ] Question order is correct
- [ ] Essay questions have appropriate rubrics
- [ ] Time limit set appropriately
- [ ] Availability dates configured
- [ ] Settings reviewed (shuffle, one question at a time, etc.)

---

## Troubleshooting

### Issue: Conversion fails with syntax errors

**Solution:**
1. Run `examark check` to identify errors
2. Fix reported issues
3. Re-run conversion

### Issue: Questions not importing to Canvas

**Solution:**
1. Verify QTI package structure: `unzip -l exam.zip`
2. Check examark version: `examark --version` (need 0.6.6+)
3. Test with `examark emulate-canvas`

### Issue: Answer key visible to students

**Solution:**
- Remove answer key section before conversion
- Or use separate file for answer key
- Canvas QTI import typically ignores instructor notes

### Issue: Points not assigned correctly

**Solution:**
- Verify point format: `[Xpts]` (e.g., `[5pts]`)
- Check total points in frontmatter
- Manually adjust in Canvas after import

---

## Advanced Usage

### Batch Conversion

```bash
# Convert multiple exams
for exam in exams/*.md; do
  examark check "$exam" && examark "$exam"
done
```

### Question Banks

Organize reusable questions:

```
exams/
├── questions/
│   ├── regression.md          # Regression questions
│   ├── anova.md               # ANOVA questions
│   └── hypothesis-testing.md  # Hypothesis testing questions
├── midterm1.md                # Uses questions from banks
└── final.md                   # Uses questions from banks
```

Reference question banks in exams:

```markdown
## Section 1: Regression (30 points)

<!-- Include questions from question bank -->
{{questions/regression.md}}
```

### Custom Point Values

examark supports point ranges:

```markdown
1. [Essay] Complex problem requiring detailed explanation. [5-10pts]
```

Canvas allows partial credit within the range.

---

## examark Documentation

- **Homepage:** https://data-wise.github.io/examark/
- **Repository:** https://github.com/Data-Wise/examark
- **NPM Package:** https://www.npmjs.com/package/examark
- **Installation:** `npm install -g examark`

---

## Teaching Workflow Integration

### Configuration

Enable examark in `.flow/teach-config.yml`:

```yaml
examark:
  enabled: true
  exam_dir: "exams"
  question_bank: "exams/questions"
  default_duration: 120       # Minutes
  default_points: 100
```

### Commands

- `teach-exam <topic>` - Create exam from template
- `./scripts/exam-to-qti.sh <file>` - Convert to Canvas QTI

### Workflow

1. Enable: `yq -i '.examark.enabled = true' .flow/teach-config.yml`
2. Install: `npm install -g examark`
3. Create: `teach-exam "Midterm 1"`
4. Edit: `$EDITOR exams/midterm1.md`
5. Convert: `./scripts/exam-to-qti.sh exams/midterm1.md`
6. Upload: Canvas → Quizzes → Import → QTI 1.2

---

## Best Practices

1. **Validate early and often**
   - Run `examark check` during editing
   - Fix issues incrementally

2. **Test before distributing**
   - Use `examark emulate-canvas` to preview
   - Import to Canvas test course first

3. **Keep answer keys separate**
   - Maintain instructor and student versions
   - Or remove answer key before conversion

4. **Use question banks**
   - Organize questions by topic
   - Reuse across multiple exams

5. **Document point values clearly**
   - Include in question text
   - Match total to frontmatter

6. **Review after Canvas import**
   - Verify all questions imported
   - Check settings and availability
   - Test quiz as student

---

**Related:**
- [Teaching Workflow Guide](TEACHING-WORKFLOW.md)
- [Quick Reference Card](../reference/REFCARD-TEACHING.md)
- [examark Documentation](https://data-wise.github.io/examark/)
