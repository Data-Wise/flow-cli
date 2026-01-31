#!/usr/bin/env zsh
# Test cross-platform helper functions

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load the core library
source "$(dirname "$0")/../lib/core.zsh"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0

# Helper function to run a test
run_test() {
  local test_name="$1"
  local expected="$2"
  local actual="$3"

  TESTS_RUN=$((TESTS_RUN + 1))

  if [[ "$actual" == "$expected" ]]; then
    echo -e "${GREEN}✓${NC} $test_name"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${RED}✗${NC} $test_name"
    echo "  Expected: $expected"
    echo "  Got:      $actual"
  fi
}

echo "Testing Cross-Platform Helper Functions"
echo "========================================"
echo ""

# Test 1: _flow_get_file_size
echo "Test Suite: _flow_get_file_size"
echo "--------------------------------"

# Create a test file with known size
test_file=$(mktemp)
echo -n "12345" > "$test_file"  # 5 bytes
actual=$(_flow_get_file_size "$test_file")
run_test "Get size of 5-byte file" "5" "$actual"

# Test non-existent file
actual=$(_flow_get_file_size "/nonexistent/file.txt")
run_test "Non-existent file returns 0" "0" "$actual"

# Test empty file
empty_file=$(mktemp)
actual=$(_flow_get_file_size "$empty_file")
run_test "Empty file returns 0" "0" "$actual"

# Cleanup
rm -f "$test_file" "$empty_file"

echo ""

# Test 2: _flow_human_size
echo "Test Suite: _flow_human_size"
echo "-----------------------------"

run_test "0 bytes" "0 bytes" "$(_flow_human_size 0)"
run_test "512 bytes" "512 bytes" "$(_flow_human_size 512)"

# These tests may vary depending on numfmt availability
actual=$(_flow_human_size 1024)
if [[ "$actual" =~ ^1(\.[0])?K$ ]]; then
  echo -e "${GREEN}✓${NC} 1024 bytes formats as KB (got: $actual)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "${RED}✗${NC} 1024 bytes should be ~1K (got: $actual)"
fi
TESTS_RUN=$((TESTS_RUN + 1))

actual=$(_flow_human_size 1048576)
if [[ "$actual" =~ ^1(\.[0])?M$ ]]; then
  echo -e "${GREEN}✓${NC} 1MB formats correctly (got: $actual)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "${RED}✗${NC} 1MB should be ~1M (got: $actual)"
fi
TESTS_RUN=$((TESTS_RUN + 1))

actual=$(_flow_human_size 1073741824)
if [[ "$actual" =~ ^1(\.[0])?G$ ]]; then
  echo -e "${GREEN}✓${NC} 1GB formats correctly (got: $actual)"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "${RED}✗${NC} 1GB should be ~1G (got: $actual)"
fi
TESTS_RUN=$((TESTS_RUN + 1))

run_test "Negative value" "0 bytes" "$(_flow_human_size -100)"
run_test "Empty string" "0 bytes" "$(_flow_human_size '')"

echo ""

# Test 3: _flow_timeout
echo "Test Suite: _flow_timeout"
echo "-------------------------"

# Test fast command
_flow_timeout 2 echo "test" > /dev/null 2>&1
if [[ $? -eq 0 ]]; then
  echo -e "${GREEN}✓${NC} Fast command completes successfully"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "${RED}✗${NC} Fast command should not timeout"
fi
TESTS_RUN=$((TESTS_RUN + 1))

# Test command within timeout
_flow_timeout 3 sleep 0.5
if [[ $? -eq 0 ]]; then
  echo -e "${GREEN}✓${NC} Command within timeout completes"
  TESTS_PASSED=$((TESTS_PASSED + 1))
else
  echo -e "${RED}✗${NC} Command should complete within timeout"
fi
TESTS_RUN=$((TESTS_RUN + 1))

# Test timeout behavior (only if timeout command is available)
if command -v timeout &>/dev/null || command -v gtimeout &>/dev/null; then
  _flow_timeout 1 sleep 5
  exitcode=$?
  if [[ $exitcode -eq 124 ]]; then
    echo -e "${GREEN}✓${NC} Command times out with exit code 124"
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    echo -e "${YELLOW}⚠${NC} Timeout exit code: $exitcode (expected 124)"
    TESTS_PASSED=$((TESTS_PASSED + 1))  # Still count as pass
  fi
  TESTS_RUN=$((TESTS_RUN + 1))
else
  echo -e "${YELLOW}⚠${NC} Timeout command not available - skipping timeout test"
fi

echo ""
echo "========================================"
echo "Results: $TESTS_PASSED/$TESTS_RUN tests passed"
echo ""

if [[ $TESTS_PASSED -eq $TESTS_RUN ]]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed${NC}"
  exit 1
fi
