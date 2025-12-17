#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# TEST-PERFORMANCE - Measure shell startup time
# ══════════════════════════════════════════════════════════════════════════════
#
# Usage: ./test-performance.zsh
#
# Target: Shell startup should be < 200ms
#
# ══════════════════════════════════════════════════════════════════════════════

# Colors
_RED='\033[31m'
_GREEN='\033[32m'
_YELLOW='\033[33m'
_NC='\033[0m'
_BOLD='\033[1m'

echo -e "${_BOLD}═══════════════════════════════════════════════════════════${_NC}"
echo -e "${_BOLD}  Shell Startup Performance Test${_NC}"
echo -e "${_BOLD}═══════════════════════════════════════════════════════════${_NC}"
echo ""

# Number of iterations
ITERATIONS=10
TARGET_MS=200

echo -e "Running $ITERATIONS iterations..."
echo ""

# Run timing test
times=()
for i in $(seq 1 $ITERATIONS); do
    # Measure startup time in milliseconds
    start_time=$(python3 -c "import time; print(int(time.time() * 1000))")
    zsh -ic exit 2>/dev/null
    end_time=$(python3 -c "import time; print(int(time.time() * 1000))")

    elapsed=$((end_time - start_time))
    times+=($elapsed)
    printf "  Run %2d: %4d ms\n" $i $elapsed
done

echo ""

# Calculate statistics
total=0
min=${times[1]}
max=${times[1]}

for t in $times; do
    total=$((total + t))
    [[ $t -lt $min ]] && min=$t
    [[ $t -gt $max ]] && max=$t
done

avg=$((total / ITERATIONS))

echo -e "${_BOLD}Results:${_NC}"
echo -e "  Minimum: ${min} ms"
echo -e "  Maximum: ${max} ms"
echo -e "  Average: ${avg} ms"
echo -e "  Target:  ${TARGET_MS} ms"
echo ""

# Verdict
if [[ $avg -lt $TARGET_MS ]]; then
    echo -e "${_GREEN}${_BOLD}✓ PASS${_NC} - Startup time (${avg}ms) is under target (${TARGET_MS}ms)"
    exit 0
elif [[ $avg -lt $((TARGET_MS * 2)) ]]; then
    echo -e "${_YELLOW}${_BOLD}⚠ WARNING${_NC} - Startup time (${avg}ms) is above target but acceptable"
    exit 0
else
    echo -e "${_RED}${_BOLD}✗ FAIL${_NC} - Startup time (${avg}ms) is too slow"
    echo ""
    echo "Suggestions:"
    echo "  - Remove unused plugins"
    echo "  - Lazy load heavy functions"
    echo "  - Profile with: zsh -xv 2>&1 | ts -i '%.s'"
    exit 1
fi
