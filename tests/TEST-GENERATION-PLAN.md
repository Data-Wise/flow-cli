# Test Generation Plan - Teaching Workflow v2.0

**Generated:** 2026-01-12
**Purpose:** Comprehensive test coverage for Increments 2 & 3
**Current Coverage:** 58 tests (Increment 2 only)
**Target Coverage:** 100+ tests (both increments)

---

## Executive Summary

### Current State
- ✅ Increment 2: 17 automated tests (100% passing)
- ⚠️ Increment 3: 0 automated tests (only manual tests)
- 📋 Manual tests: 36 test cases documented

### Gaps Identified
1. **No automated tests for teach-exam command**
2. **No automated tests for exam template generation**
3. **No automated tests for QTI conversion script**
4. **Missing integration tests for end-to-end workflows**
5. **No error scenario tests for Increment 3**

### Test Generation Goals
- Add 40+ automated tests for Increment 3
- Achieve 95%+ code coverage
- Cover all error paths
- Test integration points

---

## Test Plan for lib/teaching-utils.zsh

**File:** `lib/teaching-utils.zsh` (173 lines)
**Current Tests:** 17 tests in `test-teaching-workflow-increment-2.zsh`
**Additional Tests Needed:** 8 tests

### Function: _calculate_current_week()

**Signature:**
```zsh
_calculate_current_week(config_file)
# Returns: Week number (1-16), 0 if before start, or empty if no date
```

#### Current Test Coverage (5 tests)
- [x] Week 1 calculation
- [x] Week 8 calculation
- [x] Before semester start
- [x] After semester end
- [x] Missing config

#### Additional Tests Needed

##### 1. Boundary Values
```zsh
test_week_calculation_exact_boundary() {
  # Test: First day of week 2 (day 8)
  # Setup: start_date = 8 days ago
  # Expected: Week 2
}

test_week_calculation_last_day_week_16() {
  # Test: Last day of week 16 (day 112)
  # Setup: start_date = 112 days ago
  # Expected: Week 16 (not 17)
}
```

##### 2. Invalid Date Handling
```zsh
test_week_calculation_malformed_date() {
  # Test: Config with malformed date "2026-13-45"
  # Expected: Empty return (graceful failure)
}

test_week_calculation_non_date_string() {
  # Test: Config with "not-a-date" as start_date
  # Expected: Empty return
}
```

##### 3. Edge Cases
```zsh
test_week_calculation_leap_year() {
  # Test: Semester spanning Feb 29 (leap year)
  # Setup: start_date = 2024-02-01
  # Expected: Correct week calculation accounting for leap day
}

test_week_calculation_year_boundary() {
  # Test: Semester starting Dec, ending Jan next year
  # Setup: start_date = 2025-12-01
  # Expected: Correct cross-year calculation
}
```

---

### Function: _is_break_week()

**Signature:**
```zsh
_is_break_week(config_file, week)
# Returns: 0 and break name if yes, 1 if no
```

#### Current Test Coverage (3 tests)
- [x] Week during break (week 8)
- [x] Week not during break
- [x] No breaks configured

#### Additional Tests Needed

##### 1. Multiple Breaks
```zsh
test_break_detection_multiple_breaks() {
  # Test: Config with 2 breaks (Spring Break week 8, Reading Week 4)
  # Test week 4: Should detect "Reading Week"
  # Test week 8: Should detect "Spring Break"
  # Test week 6: Should return 1 (not a break)
}
```

##### 2. Break Spanning Multiple Weeks
```zsh
test_break_detection_two_week_break() {
  # Test: Break from week 8 to week 9 (14 days)
  # Test week 8: Should detect break
  # Test week 9: Should detect break
  # Test week 7: Should return 1
  # Test week 10: Should return 1
}
```

---

### Function: _validate_date_format()

**Signature:**
```zsh
_validate_date_format(date_str)
# Returns: 0 if valid, 1 if invalid
```

#### Current Test Coverage (4 tests)
- [x] Valid date format
- [x] Invalid format variations

#### Additional Tests Needed

##### 1. Edge Cases
```zsh
test_date_validation_february_29_non_leap() {
  # Test: "2026-02-29" (not a leap year)
  # Expected: Return 1 (invalid)
}

test_date_validation_day_zero() {
  # Test: "2026-01-00"
  # Expected: Return 1 (invalid)
}

test_date_validation_month_13() {
  # Test: "2026-13-01"
  # Expected: Return 1 (invalid)
}
```

---

### Function: _calculate_semester_end()

**Signature:**
```zsh
_calculate_semester_end(start_date)
# Returns: End date in YYYY-MM-DD format (start + 112 days)
```

#### Current Test Coverage (2 tests)
- [x] Spring semester calculation
- [x] Fall semester calculation

#### Additional Tests Needed

##### 1. Boundary Conditions
```zsh
test_semester_end_leap_year_boundary() {
  # Test: Start date before leap day, end after
  # Setup: start_date = 2024-02-01
  # Expected: Correct end date accounting for Feb 29
}

test_semester_end_year_transition() {
  # Test: Fall semester crossing year boundary
  # Setup: start_date = 2025-11-15
  # Expected: End date in 2026
}
```

---

## Test Plan for commands/teach-exam.zsh

**File:** `commands/teach-exam.zsh` (218 lines)
**Current Tests:** 0 automated tests (manual only)
**Tests Needed:** 25 tests

### Function: teach-exam()

**Signature:**
```zsh
teach-exam(topic)
# Creates exam template with guided prompts
```

#### Test Categories

##### 1. Input Validation (5 tests)

```zsh
test_teach_exam_no_topic() {
  # Test: teach-exam with no arguments
  # Expected: Error message + usage examples
  # Exit code: 1
}

test_teach_exam_not_teaching_project() {
  # Test: Run in non-teaching project (e.g., R package)
  # Expected: Error "Not in a teaching project"
  # Exit code: 1
}

test_teach_exam_no_config() {
  # Test: Teaching project without .flow/teach-config.yml
  # Expected: Error + suggestion to run teach-init
  # Exit code: 1
}

test_teach_exam_no_yq() {
  # Test: System without yq installed
  # Mock: command -v yq returns false
  # Expected: Error + installation instructions
  # Exit code: 1
}

test_teach_exam_examark_not_enabled() {
  # Test: Config has examark.enabled = false
  # Expected: Warning + prompt to continue
  # Input: "n" (cancel)
  # Expected: "Cancelled", exit code 1
}
```

##### 2. File Creation (5 tests)

```zsh
test_teach_exam_creates_exam_dir() {
  # Test: Exam dir doesn't exist
  # Run: teach-exam "Midterm 1"
  # Expected: Creates exams/ directory
  # Verify: [[ -d exams ]]
}

test_teach_exam_uses_custom_exam_dir() {
  # Test: Config has examark.exam_dir = "assessments"
  # Run: teach-exam "Quiz 1"
  # Expected: Creates assessments/ directory
  # File created in: assessments/quiz-1.md
}

test_teach_exam_generates_filename() {
  # Test: Topic "Midterm 1: ANOVA and Regression"
  # Expected filename: "midterm-1-anova-and-regression.md"
  # Verify: File created with sanitized name
}

test_teach_exam_file_exists_cancel() {
  # Test: File already exists, user cancels
  # Setup: Create exams/midterm-1.md
  # Run: teach-exam "Midterm 1"
  # Input: "n" (don't overwrite)
  # Expected: "Cancelled", original file unchanged
}

test_teach_exam_file_exists_overwrite() {
  # Test: File already exists, user overwrites
  # Setup: Create exams/midterm-1.md with content "OLD"
  # Run: teach-exam "Midterm 1"
  # Input: "y" (overwrite)
  # Expected: New template created, old content gone
}
```

##### 3. Template Generation (5 tests)

```zsh
test_teach_exam_template_has_frontmatter() {
  # Test: Created template has valid YAML frontmatter
  # Run: teach-exam "Final Exam"
  # Verify: File starts with "---"
  # Verify: Contains "title:", "course:", "duration:", "points:"
}

test_teach_exam_template_uses_defaults() {
  # Test: User accepts default duration and points
  # Config: default_duration = 120, default_points = 100
  # Input: "" (accept defaults)
  # Expected: Template has duration: 120, points: 100
}

test_teach_exam_template_custom_values() {
  # Test: User enters custom duration and points
  # Input: duration = "90", points = "75"
  # Expected: Template has duration: 90, points: 75
}

test_teach_exam_template_course_name() {
  # Test: Template includes course name from config
  # Config: course.name = "STAT 545"
  # Expected: Template has "course: STAT 545"
}

test_teach_exam_template_sections() {
  # Test: Template has all required sections
  # Verify: Contains "Multiple Choice", "Short Answer", "Problems"
  # Verify: Contains "Answer Key (instructor only)"
  # Verify: Example questions with [pts] notation
}
```

##### 4. User Interaction (5 tests)

```zsh
test_teach_exam_prompts_duration() {
  # Test: Prompts for duration with default shown
  # Mock stdin: "" (accept default)
  # Expected: Uses default_duration from config
}

test_teach_exam_prompts_points() {
  # Test: Prompts for total points with default shown
  # Mock stdin: "150"
  # Expected: Uses 150 as points value
}

test_teach_exam_prompts_filename() {
  # Test: Prompts for filename with generated default
  # Topic: "Quiz 5: Chi-Square Tests"
  # Default shown: "quiz-5-chi-square-tests"
  # Mock stdin: "quiz5"
  # Expected: Uses "quiz5" as filename
}

test_teach_exam_shows_next_steps() {
  # Test: After creation, shows next steps
  # Expected output includes:
  # - "Edit exam:" with file path
  # - "Convert to Canvas QTI:" with script command
  # - "Upload to Canvas:" with instructions
}

test_teach_exam_success_message() {
  # Test: Shows success message with file path
  # Run: teach-exam "Midterm 1"
  # Expected: "✅ Exam template created: exams/midterm-1.md"
}
```

##### 5. Error Handling (5 tests)

```zsh
test_teach_exam_invalid_config() {
  # Test: Malformed YAML in teach-config.yml
  # Setup: Write invalid YAML
  # Expected: yq error caught, graceful failure
}

test_teach_exam_no_template_file() {
  # Test: Template file missing from plugin
  # Mock: template file doesn't exist
  # Expected: Uses inline fallback template
  # Verify: Exam still created successfully
}

test_teach_exam_permission_denied() {
  # Test: Can't create exam directory (permissions)
  # Setup: Make current dir read-only
  # Expected: mkdir error, clear error message
}

test_teach_exam_disk_full() {
  # Test: Disk full, can't write file
  # Mock: write operation fails
  # Expected: Error message, no partial file left
}

test_teach_exam_template_substitution_failure() {
  # Test: sed substitution fails (special chars in topic)
  # Topic: "Test $VARIABLE with \backslash"
  # Expected: Proper escaping, valid template created
}
```

---

### Function: _teach_create_exam_template()

**Signature:**
```zsh
_teach_create_exam_template(exam_file, topic, duration, points)
# Internal helper: generates exam file from template
```

#### Test Categories

##### 1. Template Substitution (3 tests)

```zsh
test_template_substitution_basic() {
  # Test: All placeholders replaced correctly
  # Input: topic="Quiz 1", duration=60, points=50
  # Verify: {{TOPIC}} → "Quiz 1"
  # Verify: {{DURATION}} → "60"
  # Verify: {{POINTS}} → "50"
}

test_template_substitution_special_chars() {
  # Test: Topic with special characters
  # Topic: "Midterm #2: R² & p-values"
  # Expected: Proper escaping, valid markdown
}

test_template_fallback_inline() {
  # Test: Template file missing, uses inline fallback
  # Mock: template file not found
  # Expected: Creates basic template from heredoc
  # Verify: File created and valid
}
```

---

## Test Plan for lib/templates/teaching/exam-to-qti.sh

**File:** `lib/templates/teaching/exam-to-qti.sh` (132 lines)
**Current Tests:** 0 automated tests (manual only)
**Tests Needed:** 12 tests

### Script Validation Tests

#### 1. Dependency Checks (3 tests)

```zsh
test_qti_script_requires_examark() {
  # Test: Run script without examark installed
  # Mock: command -v examark returns false
  # Expected: Error message + installation instructions
  # Exit code: 1
}

test_qti_script_requires_input_file() {
  # Test: Run script with no arguments
  # Expected: Usage message with examples
  # Exit code: 1
}

test_qti_script_checks_file_exists() {
  # Test: Run with non-existent file
  # Input: exams/nonexistent.md
  # Expected: "File not found" error
  # Exit code: 1
}
```

#### 2. File Validation (3 tests)

```zsh
test_qti_script_validates_md_extension() {
  # Test: Input file without .md extension
  # Input: exams/exam.txt
  # Expected: Warning + prompt to continue
}

test_qti_script_validates_markdown_format() {
  # Test: File with invalid markdown
  # Setup: Create file without frontmatter
  # Expected: examark conversion fails gracefully
}

test_qti_script_handles_empty_file() {
  # Test: Empty markdown file
  # Expected: examark error + helpful message
}
```

#### 3. Conversion Process (3 tests)

```zsh
test_qti_script_creates_zip() {
  # Test: Successful conversion
  # Input: exams/midterm1.md (valid exam)
  # Expected: Creates exams/midterm1.zip
  # Verify: ZIP file exists and is valid
}

test_qti_script_shows_question_count() {
  # Test: Displays question count after conversion
  # Input: Exam with 10 questions
  # Expected: Output shows "Questions: ~10"
}

test_qti_script_shows_canvas_instructions() {
  # Test: Success message includes upload steps
  # Expected: Output contains:
  # - "Upload to Canvas:"
  # - "Quizzes → Import"
  # - "QTI 1.2/1.1 Package"
}
```

#### 4. Error Handling (3 tests)

```zsh
test_qti_script_examark_failure() {
  # Test: examark conversion fails
  # Setup: Invalid question format
  # Expected: Error message + common issues
  # Expected: Links to examark documentation
}

test_qti_script_zip_not_created() {
  # Test: Conversion runs but ZIP not created
  # Mock: examark succeeds but no output file
  # Expected: Warning message about missing output
}

test_qti_script_permission_error() {
  # Test: Can't write ZIP file (permissions)
  # Setup: Read-only directory
  # Expected: Clear error message
}
```

---

## Integration Tests

**Purpose:** Test end-to-end workflows
**File:** `tests/test-teaching-workflow-integration.zsh` (NEW)
**Tests Needed:** 8 tests

### End-to-End Workflows

#### 1. Complete Teaching Session (2 tests)

```zsh
test_integration_work_command_displays_context() {
  # Test: work command in teaching project shows course context
  # Setup: Create teaching project with semester_info
  # Run: work <project>
  # Expected: Displays course name, current week, branch info
  # Verify: Output contains "Week X", "📚 Course Name"
}

test_integration_work_command_branch_warning() {
  # Test: work on production branch shows warning
  # Setup: Create teaching project, checkout production
  # Run: work <project>
  # Expected: Warning banner about production branch
  # Expected: Prompt to switch to draft
}
```

#### 2. Exam Creation Workflow (3 tests)

```zsh
test_integration_exam_creation_full_workflow() {
  # Test: teach-exam → edit → convert → verify
  # Steps:
  # 1. Run teach-exam "Quiz 1"
  # 2. Verify exam file created
  # 3. Run exam-to-qti.sh
  # 4. Verify ZIP created
  # 5. Verify ZIP contains valid QTI XML
}

test_integration_exam_with_question_bank() {
  # Test: Exam references question bank files
  # Setup: Create question bank files
  # Run: teach-exam "Midterm 1"
  # Edit: Add references to question bank
  # Convert: exam-to-qti.sh
  # Verify: Questions from bank included in ZIP
}

test_integration_multiple_exams() {
  # Test: Create and manage multiple exams
  # Steps:
  # 1. Create quiz1.md
  # 2. Create quiz2.md
  # 3. Create midterm.md
  # 4. Convert all three
  # Verify: Three separate ZIP files
  # Verify: No file conflicts
}
```

#### 3. Configuration Integration (3 tests)

```zsh
test_integration_config_changes_reflected() {
  # Test: Config changes affect behavior
  # Setup: Create teaching project
  # Change: Update default_duration from 120 to 90
  # Run: teach-exam "New Exam"
  # Expected: Default shown is 90 minutes
}

test_integration_semester_progression() {
  # Test: Week calculation updates as time passes
  # Setup: Mock system date progression
  # Week 1: Verify displays "Week 1"
  # Week 8: Verify displays "Week 8 (Spring Break)"
  # Week 17: Verify displays "Week 16" (capped)
}

test_integration_teach_init_to_exam() {
  # Test: Complete flow from init to exam creation
  # Steps:
  # 1. Run teach-init "Test Course"
  # 2. Enable examark in config
  # 3. Run teach-exam "Quiz 1"
  # 4. Convert to QTI
  # Verify: All steps succeed, files created correctly
}
```

---

## Performance Tests

**Purpose:** Verify acceptable performance
**File:** `tests/test-teaching-workflow-performance.zsh` (NEW)
**Tests Needed:** 3 tests

### Performance Benchmarks

```zsh
test_performance_week_calculation() {
  # Test: Week calculation completes quickly
  # Run: _calculate_current_week 1000 times
  # Expected: Average < 10ms per call
}

test_performance_teach_exam_command() {
  # Test: teach-exam interactive command response
  # Mock: Auto-accept all prompts
  # Run: teach-exam "Test Exam"
  # Expected: Completes in < 2 seconds
}

test_performance_qti_conversion() {
  # Test: QTI conversion for typical exam
  # Setup: Exam with 20 questions
  # Run: exam-to-qti.sh
  # Expected: Completes in < 5 seconds
}
```

---

## Test Implementation Priority

### Phase 1: Critical Path (Week 1)
1. ✅ Increment 2 tests (DONE - 17 tests)
2. 🔥 teach-exam input validation (5 tests)
3. 🔥 teach-exam file creation (5 tests)
4. 🔥 QTI script validation (6 tests)

### Phase 2: Coverage (Week 2)
5. Template generation tests (8 tests)
6. Integration tests (8 tests)
7. Error handling tests (10 tests)

### Phase 3: Polish (Week 3)
8. Performance tests (3 tests)
9. Additional edge cases (8 tests)
10. Documentation examples (5 tests)

---

## Test Framework Structure

### Recommended File Organization

```
tests/
├── test-teaching-workflow-increment-2.zsh   # ✅ Existing (17 tests)
├── test-teaching-workflow-increment-3.zsh   # 🆕 NEW (25 tests)
├── test-teaching-workflow-integration.zsh   # 🆕 NEW (8 tests)
├── test-teaching-workflow-performance.zsh   # 🆕 NEW (3 tests)
├── test-teaching-utils-extended.zsh         # 🆕 NEW (8 tests)
└── test-exam-to-qti.zsh                     # 🆕 NEW (12 tests)
```

### Test Utilities Needed

```zsh
# Mock user input
mock_stdin() {
  local input="$1"
  echo "$input" | command_under_test
}

# Mock system date
mock_date() {
  local date_str="$1"
  # Override date command for testing
}

# Create minimal teaching project
create_test_teaching_project() {
  mkdir -p .flow
  # Create minimal valid config
}

# Verify file contents
assert_file_contains() {
  local file="$1"
  local pattern="$2"
  grep -q "$pattern" "$file"
}

# Count lines in file
assert_line_count() {
  local file="$1"
  local expected="$2"
  local actual=$(wc -l < "$file")
  assert_equals "$expected" "$actual"
}
```

---

## Coverage Goals

### Current Coverage
- Increment 2: **~85%** (17 tests)
- Increment 3: **~0%** (manual only)

### Target Coverage
- Increment 2: **95%+** (25 tests total)
- Increment 3: **90%+** (40+ tests)
- Integration: **100%** (8 tests)

### Coverage by Component

| Component | Lines | Current Tests | Needed Tests | Target Coverage |
|-----------|-------|---------------|--------------|-----------------|
| teaching-utils.zsh | 173 | 17 | +8 | 95% |
| teach-exam.zsh | 218 | 0 | +25 | 90% |
| exam-to-qti.sh | 132 | 0 | +12 | 85% |
| Integration | - | 0 | +8 | 100% |
| **Total** | **523** | **17** | **+53** | **~92%** |

---

## Success Metrics

### Quantitative
- ✅ 100+ total tests
- ✅ 95%+ line coverage
- ✅ 100% function coverage
- ✅ All tests pass in CI
- ✅ < 30s total test runtime

### Qualitative
- ✅ All error paths tested
- ✅ Edge cases documented
- ✅ Integration workflows verified
- ✅ Performance acceptable
- ✅ Easy to add new tests

---

## Next Steps

1. **Review this plan** with user
2. **Create test files** (5 new files)
3. **Implement Phase 1** (critical path - 16 tests)
4. **Run CI** to verify all tests pass
5. **Implement Phase 2** (coverage - 26 tests)
6. **Implement Phase 3** (polish - 16 tests)
7. **Update test documentation** (TESTING.md)

---

## References

- Existing tests: `tests/test-teaching-workflow-increment-2.zsh`
- Manual tests: `tests/MANUAL-TEST-INCREMENT-3.md`
- Implementation spec: `docs/specs/SPEC-teaching-workflow-v2.md`
- ZSH testing guide: `docs/guides/TESTING.md`

---

**Generated by:** Claude Code (Sonnet 4.5)
**Date:** 2026-01-12
**Status:** Ready for review
