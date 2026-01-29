# Teaching Workflow v2.0 - Increment 2 Implementation Plan

**Feature:** Course Context
**Duration:** 4-6 hours
**Branch:** `feature/teaching-workflow-increment-2`
**Target:** Dev branch
**Created:** 2026-01-11

---

## Overview

Enhance the teaching workflow with context-aware session display showing current week, semester info, and recent course activity.

### Success Criteria

- [ ] `work stat-545` displays current week number
- [ ] Semester date calculation works correctly
- [ ] Week calculation handles edge cases (breaks, past semesters)
- [ ] Context display adds < 50ms to work command
- [ ] Shortcuts continue to work from Increment 1
- [ ] All tests passing (new + existing)

---

## Implementation Tasks

### Task 1: Week Calculation Function (2h)

**File:** `lib/teaching-utils.zsh` (NEW)

**Create:** Week calculation utilities with edge case handling

```zsh
#!/usr/bin/env zsh
# Teaching workflow utility functions
# Part of Increment 2: Course Context

# Calculate current week number from semester start
_calculate_current_week() {
  local config_file="$1"

  # Read semester start date from config
  local start_date=$(yq -r '.semester_info.start_date // empty' "$config_file" 2>/dev/null)

  if [[ -z "$start_date" || "$start_date" == "null" ]]; then
    return 0
  fi

  # Calculate weeks since start (macOS date compatible)
  local start_epoch=$(date -j -f "%Y-%m-%d" "$start_date" "+%s" 2>/dev/null)
  local now_epoch=$(date "+%s")

  if [[ -z "$start_epoch" ]]; then
    return 0
  fi

  local days_diff=$(( (now_epoch - start_epoch) / 86400 ))
  local week=$(( (days_diff / 7) + 1 ))

  # Handle negative weeks (before semester start)
  if [[ $week -lt 1 ]]; then
    echo "0"
    return 0
  fi

  # Cap at 16 weeks (standard semester)
  if [[ $week -gt 16 ]]; then
    echo "16"
    return 0
  fi

  echo "$week"
}

# Check if week is during a scheduled break
_is_break_week() {
  local config_file="$1"
  local week="$2"

  # Check if breaks section exists
  local breaks=$(yq -r '.semester_info.breaks // empty' "$config_file" 2>/dev/null)
  if [[ -z "$breaks" || "$breaks" == "null" ]]; then
    return 1  # No breaks defined
  fi

  # Check each break period
  local break_count=$(yq -r '.semester_info.breaks | length' "$config_file" 2>/dev/null)
  local i=0

  while [[ $i -lt $break_count ]]; do
    local break_name=$(yq -r ".semester_info.breaks[$i].name" "$config_file" 2>/dev/null)
    local break_start=$(yq -r ".semester_info.breaks[$i].start" "$config_file" 2>/dev/null)
    local break_end=$(yq -r ".semester_info.breaks[$i].end" "$config_file" 2>/dev/null)

    # Calculate week numbers for break period
    local start_week=$(_date_to_week "$config_file" "$break_start")
    local end_week=$(_date_to_week "$config_file" "$break_end")

    if [[ $week -ge $start_week && $week -le $end_week ]]; then
      echo "$break_name"
      return 0  # Week is during a break
    fi

    i=$((i + 1))
  done

  return 1  # Not a break week
}

# Convert date to week number
_date_to_week() {
  local config_file="$1"
  local target_date="$2"

  local start_date=$(yq -r '.semester_info.start_date' "$config_file" 2>/dev/null)
  local start_epoch=$(date -j -f "%Y-%m-%d" "$start_date" "+%s" 2>/dev/null)
  local target_epoch=$(date -j -f "%Y-%m-%d" "$target_date" "+%s" 2>/dev/null)

  local days_diff=$(( (target_epoch - start_epoch) / 86400 ))
  local week=$(( (days_diff / 7) + 1 ))

  echo "$week"
}
```

**Edge Cases to Handle:**
- Before semester start (week 0 or negative)
- After semester end (cap at 16)
- During scheduled breaks
- Invalid/missing date in config
- yq not available

**Tests:**
- Week 1 calculation (first day of semester)
- Week 8 calculation (mid-semester)
- Week 16 calculation (end of semester)
- Week 0 (before start)
- Week 17+ (after end, should cap)
- During spring break
- Missing semester_info
- Invalid date format

---

### Task 2: Display Teaching Context (1.5h)

**File:** `commands/work.zsh`

**Modify:** Add context display after line 275

```zsh
# 5. Show context (Increment 2 enhancement)
_display_teaching_context "$project_dir" "$config_file"

# 6. Open editor (moved from original)
_flow_open_editor "$project_dir"
```

**New Function:** Add after `_load_teaching_shortcuts()`

```zsh
# Display teaching context (Increment 2)
_display_teaching_context() {
  local project_dir="$1"
  local config_file="$2"

  # Get basic course info
  local semester=$(yq -r '.course.semester // empty' "$config_file" 2>/dev/null)
  local year=$(yq -r '.course.year // empty' "$config_file" 2>/dev/null)

  # Display semester info if available
  if [[ -n "$semester" && "$semester" != "null" ]]; then
    echo "  ${FLOW_COLORS[info]}Semester:${FLOW_COLORS[reset]} $semester $year"
  fi

  # Calculate and display current week
  local current_week=$(_calculate_current_week "$config_file")
  if [[ -n "$current_week" && "$current_week" != "0" ]]; then
    # Check if it's a break week
    local break_name=$(_is_break_week "$config_file" "$current_week")
    if [[ $? -eq 0 ]]; then
      echo "  ${FLOW_COLORS[warning]}Current Week:${FLOW_COLORS[reset]} Week $current_week (${break_name})"
    else
      echo "  ${FLOW_COLORS[info]}Current Week:${FLOW_COLORS[reset]} Week $current_week"
    fi
  fi

  # Show recent git activity (last 3 commits)
  local recent_commits=$(git -C "$project_dir" log --oneline -3 --format="%s" 2>/dev/null)
  if [[ -n "$recent_commits" ]]; then
    echo ""
    echo "  ${FLOW_COLORS[bold]}Recent Changes:${FLOW_COLORS[reset]}"
    echo "$recent_commits" | sed 's/^/    /' | head -3
  fi

  echo ""
}
```

**Dependencies:**
- Source `lib/teaching-utils.zsh` in `flow.plugin.zsh`

---

### Task 3: Update Config Template (1h)

**File:** `lib/templates/teaching/teach-config.yml.template`

**Add:** Semester info section

```yaml
course:
  name: "{{COURSE_NAME}}"
  slug: "{{COURSE_SLUG}}"
  semester: "{{SEMESTER}}"
  year: {{YEAR}}

# Semester schedule (Increment 2)
semester_info:
  start_date: "{{START_DATE}}"  # YYYY-MM-DD format
  end_date: "{{END_DATE}}"      # YYYY-MM-DD format

  # Optional: scheduled breaks
  breaks:
    - name: "Spring Break"
      start: "{{SPRING_BREAK_START}}"
      end: "{{SPRING_BREAK_END}}"

branches:
  draft: "draft"
  production: "production"

deployment:
  web:
    url: "https://{{GITHUB_USER}}.github.io/{{COURSE_SLUG}}"
    enabled: true

shortcuts:
  s{{COURSE_ABBREV}}d: "./scripts/quick-deploy.sh"
  s{{COURSE_ABBREV}}a: "./scripts/semester-archive.sh"
```

**New Placeholders:**
- `{{START_DATE}}` - Semester start date
- `{{END_DATE}}` - Semester end date (calculated)
- `{{SPRING_BREAK_START}}` - Optional break start
- `{{SPRING_BREAK_END}}` - Optional break end

---

### Task 4: Update teach-init Command (1.5h)

**File:** `commands/teach-init.zsh`

**Modify:** Add semester date prompts after course name/semester input

```zsh
# Add after semester/year collection (around line 145)

# Prompt for semester start date
echo ""
echo "${FLOW_COLORS[bold]}Semester Schedule${FLOW_COLORS[reset]}"
echo "  When does the semester start?"
echo ""

# Provide common defaults
local current_month=$(date +%m)
local suggested_start=""

# Suggest based on current month
if [[ $current_month -ge 8 || $current_month -le 1 ]]; then
  # Fall semester
  suggested_start="$(date +%Y)-08-20"
elif [[ $current_month -ge 1 && $current_month -le 5 ]]; then
  # Spring semester
  suggested_start="$(date +%Y)-01-15"
fi

read "start_date?  Start date (YYYY-MM-DD) [$suggested_start]: "
start_date="${start_date:-$suggested_start}"

# Validate date format
if ! date -j -f "%Y-%m-%d" "$start_date" "+%s" &>/dev/null; then
  _flow_log_error "Invalid date format. Please use YYYY-MM-DD"
  return 1
fi

# Calculate semester end (16 weeks from start)
local start_epoch=$(date -j -f "%Y-%m-%d" "$start_date" "+%s")
local end_epoch=$((start_epoch + (16 * 7 * 86400)))
local end_date=$(date -j -f "%s" "$end_epoch" "+%Y-%m-%d")

echo "  ${FLOW_COLORS[info]}Calculated end date: $end_date${FLOW_COLORS[reset]}"

# Ask about breaks
echo ""
read "?  Add spring/fall break? [y/N]: " add_break

local break_config=""
if [[ "$add_break" == "y" ]]; then
  read "break_name?  Break name [Spring Break]: "
  break_name="${break_name:-Spring Break}"

  # Suggest week 8 for break
  local break_start_epoch=$((start_epoch + (7 * 7 * 86400)))
  local break_end_epoch=$((break_start_epoch + (7 * 86400)))
  local suggested_break_start=$(date -j -f "%s" "$break_start_epoch" "+%Y-%m-%d")
  local suggested_break_end=$(date -j -f "%s" "$break_end_epoch" "+%Y-%m-%d")

  read "break_start?  Break start [$suggested_break_start]: "
  break_start="${break_start:-$suggested_break_start}"

  read "break_end?  Break end [$suggested_break_end]: "
  break_end="${break_end:-$suggested_break_end}"

  break_config="
  breaks:
    - name: \"$break_name\"
      start: \"$break_start\"
      end: \"$break_end\""
fi

# Update template substitution
echo "$config_template" | \
  sed "s/{{COURSE_NAME}}/$course_name/g" | \
  sed "s/{{COURSE_SLUG}}/$course_slug/g" | \
  sed "s/{{SEMESTER}}/$semester/g" | \
  sed "s/{{YEAR}}/$year/g" | \
  sed "s/{{START_DATE}}/$start_date/g" | \
  sed "s/{{END_DATE}}/$end_date/g" | \
  sed "s/{{SPRING_BREAK_START}}/$break_start/g" | \
  sed "s/{{SPRING_BREAK_END}}/$break_end/g" | \
  sed "s/{{COURSE_ABBREV}}/$course_abbrev/g" \
  > .flow/teach-config.yml

# If no break, remove breaks section
if [[ "$add_break" != "y" ]]; then
  yq -i 'del(.semester_info.breaks)' .flow/teach-config.yml
fi
```

**Key Changes:**
- Smart date suggestions based on current month
- Automatic end date calculation (16 weeks)
- Optional break configuration
- Date validation
- Improved user prompts

---

### Task 5: Testing (1.5h)

**File:** `tests/test-teaching-workflow-increment-2.zsh` (NEW)

**Create:** Comprehensive test suite for Increment 2

```zsh
#!/usr/bin/env zsh

# Test suite for Teaching Workflow Increment 2: Course Context
# Tests week calculation, context display, and semester configuration

source "lib/core.zsh"
source "lib/teaching-utils.zsh"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================================
# Test Helpers
# ============================================================================

setup_test_config() {
  local start_date="$1"
  local end_date="$2"

  mkdir -p .flow
  cat > .flow/teach-config.yml <<EOF
course:
  name: "Test Course"
  semester: "Spring"
  year: 2026

semester_info:
  start_date: "$start_date"
  end_date: "$end_date"
  breaks:
    - name: "Spring Break"
      start: "2026-03-09"
      end: "2026-03-14"

branches:
  draft: "draft"
  production: "production"
EOF
}

assert_equals() {
  local expected="$1"
  local actual="$2"
  local message="${3:-}"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ "$expected" == "$actual" ]]; then
    echo -e "${FLOW_COLORS[success]}✓${FLOW_COLORS[reset]} $message"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${FLOW_COLORS[error]}✗${FLOW_COLORS[reset]} $message"
    echo "  Expected: $expected"
    echo "  Got: $actual"
    TESTS_FAILED=$((TESTS_FAILED + 1))
  fi
}

# ============================================================================
# Week Calculation Tests
# ============================================================================

test_week_calculation_first_day() {
  setup_test_config "2026-01-12" "2026-05-04"

  # Mock current date to first day of semester
  local week=$(TZ=UTC faketime "2026-01-12" _calculate_current_week ".flow/teach-config.yml")

  assert_equals "1" "$week" "First day of semester should be week 1"

  rm -rf .flow
}

test_week_calculation_mid_semester() {
  setup_test_config "2026-01-12" "2026-05-04"

  # Week 8 (8 weeks after start)
  local week=$(TZ=UTC faketime "2026-03-09" _calculate_current_week ".flow/teach-config.yml")

  assert_equals "8" "$week" "8 weeks after start should be week 8"

  rm -rf .flow
}

test_week_calculation_before_start() {
  setup_test_config "2026-01-12" "2026-05-04"

  # 1 week before semester
  local week=$(TZ=UTC faketime "2026-01-05" _calculate_current_week ".flow/teach-config.yml")

  assert_equals "0" "$week" "Before semester should return week 0"

  rm -rf .flow
}

test_week_calculation_after_end() {
  setup_test_config "2026-01-12" "2026-05-04"

  # 20 weeks after start (past semester end)
  local week=$(TZ=UTC faketime "2026-05-25" _calculate_current_week ".flow/teach-config.yml")

  assert_equals "16" "$week" "After semester should cap at week 16"

  rm -rf .flow
}

test_week_calculation_missing_config() {
  mkdir -p .flow
  cat > .flow/teach-config.yml <<EOF
course:
  name: "Test Course"
EOF

  local week=$(_calculate_current_week ".flow/teach-config.yml")

  # Should return empty/0 when no semester_info
  assert_equals "" "$week" "Missing semester_info should return empty"

  rm -rf .flow
}

# ============================================================================
# Break Detection Tests
# ============================================================================

test_break_detection_during_break() {
  setup_test_config "2026-01-12" "2026-05-04"

  # Week 8 is spring break (March 9-14)
  local break_name=$(_is_break_week ".flow/teach-config.yml" "8")
  local result=$?

  assert_equals "0" "$result" "Week 8 should be detected as break week"
  assert_equals "Spring Break" "$break_name" "Break name should match config"

  rm -rf .flow
}

test_break_detection_not_break() {
  setup_test_config "2026-01-12" "2026-05-04"

  # Week 5 is not a break
  _is_break_week ".flow/teach-config.yml" "5"
  local result=$?

  assert_equals "1" "$result" "Week 5 should not be a break"

  rm -rf .flow
}

# ============================================================================
# Context Display Tests
# ============================================================================

test_context_display_shows_week() {
  setup_test_config "2026-01-12" "2026-05-04"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"

  # Capture context output
  local output=$(TZ=UTC faketime "2026-03-09" _display_teaching_context "." ".flow/teach-config.yml" 2>&1)

  # Should contain week number
  if echo "$output" | grep -q "Week 8"; then
    assert_equals "1" "1" "Context should display current week"
  else
    assert_equals "1" "0" "Context should display current week"
  fi

  rm -rf .flow .git
}

test_context_display_shows_break() {
  setup_test_config "2026-01-12" "2026-05-04"
  git init -q
  git config user.email "test@test.com"
  git config user.name "Test"

  # During spring break
  local output=$(TZ=UTC faketime "2026-03-09" _display_teaching_context "." ".flow/teach-config.yml" 2>&1)

  # Should mention spring break
  if echo "$output" | grep -q "Spring Break"; then
    assert_equals "1" "1" "Context should show break name"
  else
    assert_equals "1" "0" "Context should show break name"
  fi

  rm -rf .flow .git
}

# ============================================================================
# teach-init Date Validation Tests
# ============================================================================

test_date_validation_valid() {
  # Valid date should parse without error
  if date -j -f "%Y-%m-%d" "2026-01-12" "+%s" &>/dev/null; then
    assert_equals "1" "1" "Valid date format should parse"
  else
    assert_equals "1" "0" "Valid date format should parse"
  fi
}

test_date_validation_invalid() {
  # Invalid date should fail
  if date -j -f "%Y-%m-%d" "not-a-date" "+%s" &>/dev/null; then
    assert_equals "1" "0" "Invalid date should fail validation"
  else
    assert_equals "1" "1" "Invalid date should fail validation"
  fi
}

# ============================================================================
# Run All Tests
# ============================================================================

echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Teaching Workflow Increment 2 - Test Suite               ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

echo "${FLOW_COLORS[info]}━━━ Week Calculation Tests ━━━${FLOW_COLORS[reset]}"
test_week_calculation_first_day
test_week_calculation_mid_semester
test_week_calculation_before_start
test_week_calculation_after_end
test_week_calculation_missing_config

echo ""
echo "${FLOW_COLORS[info]}━━━ Break Detection Tests ━━━${FLOW_COLORS[reset]}"
test_break_detection_during_break
test_break_detection_not_break

echo ""
echo "${FLOW_COLORS[info]}━━━ Context Display Tests ━━━${FLOW_COLORS[reset]}"
test_context_display_shows_week
test_context_display_shows_break

echo ""
echo "${FLOW_COLORS[info]}━━━ Date Validation Tests ━━━${FLOW_COLORS[reset]}"
test_date_validation_valid
test_date_validation_invalid

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Test Summary                                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "  Tests run:    $TESTS_RUN"
echo "  ${FLOW_COLORS[success]}Passed:${FLOW_COLORS[reset]}       $TESTS_PASSED"
echo "  ${FLOW_COLORS[error]}Failed:${FLOW_COLORS[reset]}       $TESTS_FAILED"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
  echo "${FLOW_COLORS[success]}✓ All tests passed!${FLOW_COLORS[reset]}"
  exit 0
else
  echo "${FLOW_COLORS[error]}✗ Some tests failed${FLOW_COLORS[reset]}"
  exit 1
fi
```

**Test Dependencies:**
- `faketime` - For date mocking (install: `brew install libfaketime`)
- Alternative: Manual testing with actual dates

**Test Coverage:**
- Week calculation (5 tests)
- Break detection (2 tests)
- Context display (2 tests)
- Date validation (2 tests)

**Total:** 11 new tests

---

### Task 6: Documentation Updates (1h)

**Files to Update:**

1. **`docs/guides/TEACHING-WORKFLOW.md`**
   - Add "Course Context" section
   - Document week calculation
   - Show example context output
   - Add troubleshooting for date issues

2. **`docs/reference/MASTER-DISPATCHER-GUIDE.md#teach-dispatcher`**
   - Add semester_info configuration fields
   - Add break configuration example
   - Update work command output example

3. **`README.md`**
   - Update teaching workflow section with context features

4. **`TESTING-INSTRUCTIONS.md`**
   - Add Increment 2 testing scenarios
   - Week calculation verification
   - Context display checks

---

## File Changes Summary

### New Files (3)

1. `lib/teaching-utils.zsh` - Week calculation utilities
2. `tests/test-teaching-workflow-increment-2.zsh` - Test suite
3. `docs/specs/PLAN-teaching-workflow-increment-2.md` - This plan

### Modified Files (5)

1. `commands/work.zsh` - Add context display
2. `commands/teach-init.zsh` - Add semester date prompts
3. `lib/templates/teaching/teach-config.yml.template` - Add semester_info
4. `flow.plugin.zsh` - Source teaching-utils.zsh
5. `docs/guides/TEACHING-WORKFLOW.md` - Document context features
6. `docs/reference/MASTER-DISPATCHER-GUIDE.md#teach-dispatcher` - Update reference
7. `README.md` - Update overview
8. `TESTING-INSTRUCTIONS.md` - Add Increment 2 tests

**Total Changes:** ~500-700 lines of code/docs

---

## Implementation Order

1. **Create `lib/teaching-utils.zsh`** (2h)
   - Week calculation function
   - Break detection function
   - Date utilities

2. **Update `commands/work.zsh`** (1h)
   - Add context display function
   - Integrate week calculation
   - Test with existing config

3. **Update templates and teach-init** (1.5h)
   - Update teach-config.yml.template
   - Add date prompts to teach-init
   - Test initialization flow

4. **Create test suite** (1.5h)
   - Write 11 tests
   - Ensure all pass
   - Add to CI if needed

5. **Update documentation** (1h)
   - Update guide
   - Update reference
   - Update testing instructions

6. **Integration testing** (0.5h)
   - Test full workflow with real course
   - Verify performance (< 50ms)
   - Check edge cases

---

## Dependencies

### Required Tools

- `yq` - YAML processing (already required by Increment 1)
- `date` - macOS date command (built-in)

### Optional Tools

- `faketime` - For date mocking in tests (recommended)

### Code Dependencies

- `lib/core.zsh` - Colors and logging
- `commands/work.zsh` - Work command infrastructure
- `commands/teach-init.zsh` - Initialization command

---

## Testing Strategy

### Automated Tests (11 tests)

1. Week calculation edge cases
2. Break detection
3. Context display output
4. Date validation
5. Missing config handling

### Manual Integration Tests

1. Initialize new course with semester dates
2. Verify week display in work session
3. Test during break week
4. Test before/after semester
5. Verify performance (< 50ms)

### Regression Tests

- Ensure Increment 1 features still work
- Branch safety unchanged
- Shortcuts still load
- Deployment scripts unaffected

---

## Performance Targets

| Operation | Target | Current | Notes |
|-----------|--------|---------|-------|
| Week calculation | < 10ms | TBD | Simple date arithmetic |
| Context display | < 50ms | TBD | One git log call |
| work command total | < 200ms | ~150ms | Including all enhancements |

**Measurement:** Use `time work <project>` to verify

---

## Risk Mitigation

### Risk 1: Date Parsing Compatibility

**Issue:** macOS `date` command differs from GNU date
**Mitigation:** Use macOS-specific `-j -f` format
**Fallback:** Graceful degradation if date parsing fails

### Risk 2: Performance Impact

**Issue:** Context display adds latency
**Mitigation:** Cache week calculation within session
**Target:** Keep total work command < 200ms

### Risk 3: yq Dependency

**Issue:** Users without yq can't use features
**Mitigation:** Graceful fallback already in place (Increment 1)
**Doctor check:** Warn if yq missing

### Risk 4: Date Configuration Errors

**Issue:** Users enter invalid dates
**Mitigation:** Validation in teach-init
**Recovery:** Clear error messages with format examples

---

## Success Metrics

### Code Quality

- [ ] All 11 new tests passing
- [ ] No regression in existing 41 tests
- [ ] Performance target met (< 50ms context)
- [ ] Code follows flow-cli conventions

### User Experience

- [ ] Week display accurate and helpful
- [ ] Date prompts clear and validated
- [ ] Context adds value without clutter
- [ ] Error messages actionable

### Documentation

- [ ] Guide updated with context features
- [ ] Reference card shows new config fields
- [ ] Testing instructions comprehensive
- [ ] Examples show real course usage

---

## Rollback Plan

If critical issues found:

1. **Revert Commits**

   ```bash
   git revert <commit-range>
   git push origin feature/teaching-workflow-increment-2
   ```

2. **Disable Features**
   - Remove `_display_teaching_context()` call
   - Keep utils for future use
   - Document limitations

3. **Fallback State**
   - Increment 1 features remain functional
   - No breaking changes to existing courses
   - Can re-attempt later

---

## Next Steps After Completion

1. **Create PR to dev**
   - Include all tests passing evidence
   - Screenshots of context display
   - Performance measurements

2. **Deploy to STAT 545**
   - Real-world testing
   - Gather user feedback
   - Iterate if needed

3. **Plan Increment 3 (Optional)**
   - Exam workflow features
   - examark integration
   - Scholar skill integration
   - Decision point: Skip or implement?

---

## Open Questions

1. **Break Configuration:**
   - Should we support multiple breaks?
   - Yes - template already supports array

2. **Week Display Format:**
   - "Week 8" vs "Week 8/16" vs "Week 8 (Mar 9-15)"
   - Start simple: "Week 8", can enhance later

3. **Performance Caching:**
   - Cache week calculation for session?
   - Not needed unless performance issues

4. **Future Semesters:**
   - How to handle semester transitions?
   - Use `semester-archive.sh`, update config manually
   - Could add `teach-update-semester` command later

---

## References

- **Spec:** `docs/specs/SPEC-teaching-workflow-v2.md`
- **Increment 1 PR:** #217
- **Testing Guide:** `TESTING-INSTRUCTIONS.md`
- **macOS date:** `man date` (BSD date format)

---

**Status:** Ready for implementation
**Estimated Completion:** 4-6 hours
**Target Release:** v5.4.0

