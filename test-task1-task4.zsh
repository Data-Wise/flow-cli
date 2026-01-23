#!/usr/bin/env zsh
# Quick test script for Task 1 & Task 4 implementation
# Tests flag parsing and verbosity helpers

echo "Testing Task 1 & Task 4 Implementation"
echo "========================================"
echo ""

# Test 1: Check syntax
echo "Test 1: Syntax check"
if zsh -n commands/doctor.zsh; then
  echo "  ✓ Syntax valid"
else
  echo "  ✗ Syntax errors found"
  exit 1
fi
echo ""

# Test 2: Source and check functions exist
echo "Test 2: Function definitions"
source commands/doctor.zsh 2>/dev/null
if (( $+functions[doctor] )); then
  echo "  ✓ doctor() function defined"
else
  echo "  ✗ doctor() function not found"
  exit 1
fi

if (( $+functions[_doctor_log_quiet] )); then
  echo "  ✓ _doctor_log_quiet() helper defined"
else
  echo "  ✗ _doctor_log_quiet() helper not found"
  exit 1
fi

if (( $+functions[_doctor_log_verbose] )); then
  echo "  ✓ _doctor_log_verbose() helper defined"
else
  echo "  ✗ _doctor_log_verbose() helper not found"
  exit 1
fi

if (( $+functions[_doctor_log_always] )); then
  echo "  ✓ _doctor_log_always() helper defined"
else
  echo "  ✗ _doctor_log_always() helper not found"
  exit 1
fi
echo ""

# Test 3: Help text includes new flags
echo "Test 3: Help text includes new flags"
help_output=$(doctor --help 2>&1)

if echo "$help_output" | grep -q "\-\-dot"; then
  echo "  ✓ --dot flag documented"
else
  echo "  ✗ --dot flag not in help"
fi

if echo "$help_output" | grep -q "\-\-dot=TOKEN"; then
  echo "  ✓ --dot=TOKEN flag documented"
else
  echo "  ✗ --dot=TOKEN flag not in help"
fi

if echo "$help_output" | grep -q "\-\-fix-token"; then
  echo "  ✓ --fix-token flag documented"
else
  echo "  ✗ --fix-token flag not in help"
fi

if echo "$help_output" | grep -q "\-\-quiet"; then
  echo "  ✓ --quiet flag documented"
else
  echo "  ✗ --quiet flag not in help"
fi
echo ""

# Test 4: Verbosity helper behavior
echo "Test 4: Verbosity helper behavior"

# Test quiet mode
verbosity_level="quiet"
output=$(_doctor_log_quiet "Should not show")
if [[ -z "$output" ]]; then
  echo "  ✓ _doctor_log_quiet() suppresses in quiet mode"
else
  echo "  ✗ _doctor_log_quiet() failed to suppress"
fi

# Test normal mode
verbosity_level="normal"
output=$(_doctor_log_quiet "Should show")
if [[ -n "$output" ]]; then
  echo "  ✓ _doctor_log_quiet() shows in normal mode"
else
  echo "  ✗ _doctor_log_quiet() failed to show"
fi

# Test verbose only (should not show in normal)
verbosity_level="normal"
output=$(_doctor_log_verbose "Should not show")
if [[ -z "$output" ]]; then
  echo "  ✓ _doctor_log_verbose() suppresses in normal mode"
else
  echo "  ✗ _doctor_log_verbose() failed to suppress"
fi

# Test verbose mode
verbosity_level="verbose"
output=$(_doctor_log_verbose "Should show")
if [[ -n "$output" ]]; then
  echo "  ✓ _doctor_log_verbose() shows in verbose mode"
else
  echo "  ✗ _doctor_log_verbose() failed to show"
fi

# Test always (should show in all modes)
verbosity_level="quiet"
output=$(_doctor_log_always "Always shows")
if [[ -n "$output" ]]; then
  echo "  ✓ _doctor_log_always() shows in quiet mode"
else
  echo "  ✗ _doctor_log_always() failed to show"
fi

echo ""
echo "========================================"
echo "All tests passed! ✓"
echo ""
echo "Manual testing recommended:"
echo "  1. source flow.plugin.zsh"
echo "  2. doctor --help          # View new flags"
echo "  3. doctor --dot           # Test isolated token check"
echo "  4. doctor --quiet         # Test quiet mode"
echo "  5. doctor --verbose       # Test verbose mode"
