# Wave 3: Remaining Work - Action Plan

**Current Status:** 85% Complete
**Time to Complete:** 2-3 hours
**Priority:** Medium (framework works, validators need polish)

---

## Task Breakdown

### Task 1: Refactor Citation Validator (45 minutes)

**File:** `.teach/validators/check-citations.zsh`

**Changes Needed:**

1. **Replace `sort -u` (3 locations)**
   ```zsh
   # BEFORE (lines 73, 104, 125)
   printf '%s\n' "${array[@]}" | sort -u

   # AFTER
   unique=(${(u)array})  # ZSH unique parameter expansion
   printf '%s\n' "${unique[@]}"
   ```

2. **Replace `sed` (line 48)**
   ```zsh
   # BEFORE
   keys=$(echo "$bracketed" | sed 's/\[@//g; s/\]//g; s/;//g' | tr ' ' '\n' | grep -E '^@')

   # AFTER
   keys="${bracketed//\[@/}"    # Remove [@
   keys="${keys//\]/}"          # Remove ]
   keys="${keys//;/}"           # Remove ;
   keys=$(echo "$keys" | tr ' ' '\n' | grep -E '^@')
   ```

3. **Replace `grep -E` patterns**
   ```zsh
   # BEFORE
   if echo "$key" | grep -qE '@[a-zA-Z]+[0-9]'; then

   # AFTER
   if [[ "$key" =~ '@[a-zA-Z]+[0-9]' ]]; then
   ```

**Test After Changes:**
```bash
./tests/test-builtin-validators-unit.zsh | grep "Citation Validator"
```

---

### Task 2: Refactor Link Validator (45 minutes)

**File:** `.teach/validators/check-links.zsh`

**Changes Needed:**

1. **Replace `sed` for URL extraction (lines 31-32)**
   ```zsh
   # BEFORE
   url=$(echo "$link" | sed 's/.*](\([^)]*\)).*/\1/')

   # AFTER
   url="${link##*\(}"   # Remove up to (
   url="${url%%\)*}"    # Remove from ) onward
   ```

2. **Replace `grep -oE` patterns**
   ```zsh
   # BEFORE
   md_links=$(echo "$line" | grep -oE '\[[^]]+\]\([^)]+\)')

   # AFTER
   # Use ZSH pattern matching
   if [[ "$line" =~ '\[[^]]+\]\([^)]+\)' ]]; then
       # Extract matches using BASH_REMATCH or similar
   fi
   ```

3. **Simplify regex to ZSH patterns**
   ```zsh
   # BEFORE
   if echo "$url" | grep -qE '^https?://'; then

   # AFTER
   if [[ "$url" == http://* || "$url" == https://* ]]; then
   ```

**Alternative Approach:**
Since link extraction is complex, consider using a simpler regex-free approach:
```zsh
# Extract links by parsing character-by-character
# This avoids all external command dependencies
```

**Test After Changes:**
```bash
./tests/test-builtin-validators-unit.zsh | grep "Link Validator"
```

---

### Task 3: Refactor Formatting Validator (30 minutes)

**File:** `.teach/validators/check-formatting.zsh`

**Changes Needed:**

1. **Fix heading level calculation (line 86)**
   ```zsh
   # BEFORE
   local level
   level=$(echo "$line" | grep -o '^#*' | wc -c)
   ((level--))

   # AFTER
   local level=0
   local temp="$line"
   while [[ "$temp" == \#* ]]; do
       ((level++))
       temp="${temp#\#}"
   done
   ```

2. **Replace `sed` for chunk option extraction**
   ```zsh
   # BEFORE
   chunk_header=$(echo "$line" | sed 's/```{[^,}]*//' | sed 's/}$//')

   # AFTER
   chunk_header="${line#*\{}"    # Remove up to {
   chunk_header="${chunk_header#*,}"  # Remove first part
   chunk_header="${chunk_header%\}}"  # Remove trailing }
   ```

3. **Replace `wc -l` for quote counting**
   ```zsh
   # BEFORE
   local doubles
   doubles=$(echo "$line" | grep -o '"' | wc -l)

   # AFTER
   local doubles=0
   local temp="$line"
   while [[ "$temp" == *\"* ]]; do
       ((doubles++))
       temp="${temp#*\"}"
   done
   ```

**Test After Changes:**
```bash
./tests/test-builtin-validators-unit.zsh | grep "Formatting Validator"
```

---

### Task 4: Fix Test Cleanup (15 minutes)

**File:** `tests/test-custom-validators-unit.zsh`

**Changes:**

Add `cleanup_validators` calls to these tests:
- `test_run_custom_validators_single` (line ~410)
- `test_run_custom_validators_select_specific` (line ~430)

```zsh
test_run_custom_validators_single() {
    echo -e "\n${TEST_BLUE}Testing orchestrator (single validator)${TEST_RESET}"

    cleanup_validators  # ADD THIS

    # Create validator
    cat > "$TEST_DIR/.teach/validators/test.zsh" <<'EOF'
    ...
```

**Test After Changes:**
```bash
./tests/test-custom-validators-unit.zsh
```

---

### Task 5: Improve Crash Detection (15 minutes)

**File:** `lib/custom-validators.zsh`

**Current Issue:**
Validator crashes don't always return exit code 2.

**Fix:**
```zsh
# In _execute_validator function (around line 175)

# Add better error detection
_validate() {
    local validation_output
    {
        validation_output=$(_validate "$file" 2>&1)
        local validate_exit=$?

        # Detect crashes by checking for error keywords
        if echo "$validation_output" | grep -qE '(command not found|syntax error|segmentation fault)'; then
            echo "ERROR: Validator crashed during execution"
            exit 2
        fi

        # Check exit code
        if [[ $validate_exit -gt 1 ]]; then
            echo "ERROR: Validator crashed with exit code $validate_exit"
            exit 2
        fi

        echo "$validation_output"
        exit $validate_exit
    } || {
        # Catch any other errors
        echo "ERROR: Unexpected validator failure"
        exit 2
    }
}
```

**Test After Changes:**
```bash
./tests/test-custom-validators-unit.zsh | grep "crash"
```

---

### Task 6: Create User Guide (30 minutes)

**File:** `docs/guides/CUSTOM-VALIDATORS-GUIDE.md`

**Contents:**

1. **Introduction**
   - What are custom validators
   - When to use them
   - How they integrate with teaching workflow

2. **Quick Start**
   - 5-minute tutorial
   - Simple example validator
   - Running validators

3. **Plugin API Reference**
   - Required components
   - Optional components
   - Environment variables
   - Error reporting patterns

4. **Built-in Validators**
   - check-citations
   - check-links
   - check-formatting

5. **Advanced Topics**
   - Multi-file validation
   - Caching strategies
   - Performance optimization
   - Testing validators

6. **Examples**
   - Word count validator
   - Required sections validator
   - Code chunk validator
   - Custom citation styles

7. **Troubleshooting**
   - Common errors
   - Debugging validators
   - Performance issues

**Estimated:** 500-800 lines

---

## Testing Checklist

After completing all tasks, verify:

- [ ] All 3 built-in validators work without errors
- [ ] `teach validate --custom` runs successfully
- [ ] `teach validate --custom --validators check-citations` works
- [ ] `teach validate --custom --skip-external` works
- [ ] Framework tests: 30/31 passing (97%+)
- [ ] Validator tests: 24/26 passing (92%+)
- [ ] Manual testing on real course files
- [ ] Documentation is complete and accurate

---

## Priority Order

**If time is limited, do in this order:**

1. **Task 1** (Citation Validator) - Most commonly used
2. **Task 4** (Test Cleanup) - Quick win, fixes 4 tests
3. **Task 6** (User Guide) - Critical for usability
4. **Task 2** (Link Validator) - Useful but complex
5. **Task 3** (Formatting Validator) - Nice to have
6. **Task 5** (Crash Detection) - Edge case handling

---

## Success Metrics

**Before:**
- Framework: 87% tests passing
- Validators: 42% tests passing
- Built-in validators: Buggy in subshells

**After (Target):**
- Framework: 97%+ tests passing
- Validators: 92%+ tests passing
- Built-in validators: Fully functional
- User documentation: Complete

---

## Time Estimates

| Task | Estimated | Priority |
|------|-----------|----------|
| Task 1: Citation validator | 45 min | High |
| Task 2: Link validator | 45 min | Medium |
| Task 3: Formatting validator | 30 min | Low |
| Task 4: Test cleanup | 15 min | High |
| Task 5: Crash detection | 15 min | Low |
| Task 6: User guide | 30 min | High |
| **Total** | **3 hours** | |

**Fast Path (90 minutes):**
- Task 1 + Task 4 + Task 6
- Gets you: Working citations, clean tests, documentation

**Complete Path (3 hours):**
- All 6 tasks
- Gets you: 100% complete Wave 3

---

## Notes

- All validators should use **ZSH built-ins only**
- No external commands (`sort`, `sed`, `grep`, `awk`)
- Test in subshell context: `(source validator.zsh && _validate file.qmd)`
- Keep validators fast (<100ms per file)
- Prioritize clear error messages over complex detection

---

**Created:** 2026-01-20
**Status:** Ready for implementation
**Estimated Completion:** 2-3 hours
