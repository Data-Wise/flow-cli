#!/usr/bin/env zsh
# ══════════════════════════════════════════════════════════════════════════════
# DIAGNOSTIC: TEACH ANALYZE COMMAND OUTPUTS
# ══════════════════════════════════════════════════════════════════════════════
#
# Purpose: Non-interactive test that captures all teach analyze command outputs
#          for review. This helps verify what commands actually produce before
#          running the interactive dog feeding test.
#
# Usage: ./diagnostic-teach-analyze.zsh
#
# Output: Creates diagnostic-results-YYYYMMDD-HHMMSS.log with all command outputs
#
# ══════════════════════════════════════════════════════════════════════════════

# Determine paths
PLUGIN_DIR="${0:A:h:h}"
TEST_DIR="${0:A:h}"
DEMO_COURSE="$TEST_DIR/fixtures/demo-course"
LOG_FILE="$TEST_DIR/diagnostic-results-$(date +%Y%m%d-%H%M%S).log"

# Colors for terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${BLUE}  TEACH ANALYZE DIAGNOSTIC${NC}"
echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}Logging to: $LOG_FILE${NC}"
echo ""

# Initialize log file
cat > "$LOG_FILE" <<EOF
═══════════════════════════════════════════════════════════════
TEACH ANALYZE DIAGNOSTIC - COMMAND OUTPUT CAPTURE
═══════════════════════════════════════════════════════════════
Date: $(date '+%Y-%m-%d %H:%M:%S')
Demo Course: STAT-101 (Introduction to Statistics)
Plugin: flow-cli
═══════════════════════════════════════════════════════════════

EOF

# Check prerequisites
if [[ ! -d "$DEMO_COURSE" ]]; then
    echo -e "${YELLOW}✗ Demo course not found at: $DEMO_COURSE${NC}"
    echo "ERROR: Demo course not found at: $DEMO_COURSE" >> "$LOG_FILE"
    exit 1
fi

# Source plugin
if ! source "$PLUGIN_DIR/flow.plugin.zsh" 2>/dev/null; then
    echo -e "${YELLOW}✗ Failed to load plugin${NC}"
    echo "ERROR: Failed to load plugin" >> "$LOG_FILE"
    exit 1
fi

# Navigate to demo course
cd "$DEMO_COURSE" || exit 1

echo -e "${GREEN}✓ Plugin loaded${NC}"
echo -e "${GREEN}✓ Demo course ready${NC}"
echo ""

# Clean up any previous test artifacts
rm -rf .teach/analysis-cache 2>/dev/null
rm -rf .teach/reports 2>/dev/null

# ══════════════════════════════════════════════════════════════════════════════
# TEST 1: Analyze Week 1
# ══════════════════════════════════════════════════════════════════════════════

echo -e "${BOLD}Test 1: Analyze Week 1${NC}"

cat >> "$LOG_FILE" <<EOF

═══════════════════════════════════════════════════════════════
TEST 1: Analyze Week 1 Lecture
═══════════════════════════════════════════════════════════════
Command: teach analyze lectures/week-01.qmd
Expected:
  - Concepts: descriptive-stats, data-types, distributions
  - Categories: fundamental, core
  - Prerequisites shown for distributions

Output:
─────────────────────────────────────────────────────────────────
EOF

teach analyze lectures/week-01.qmd >> "$LOG_FILE" 2>&1
echo "" >> "$LOG_FILE"
echo -e "${GREEN}  ✓ Captured${NC}"

# ══════════════════════════════════════════════════════════════════════════════
# TEST 2: Analyze Week 2
# ══════════════════════════════════════════════════════════════════════════════

echo -e "${BOLD}Test 2: Analyze Week 2${NC}"

cat >> "$LOG_FILE" <<EOF

═══════════════════════════════════════════════════════════════
TEST 2: Analyze Week 2 (With Prerequisites)
═══════════════════════════════════════════════════════════════
Command: teach analyze lectures/week-02.qmd
Expected:
  - Concepts: probability-basics, sampling, inference
  - Prerequisites: data-types, distributions
  - Inference requires multiple prerequisites

Output:
─────────────────────────────────────────────────────────────────
EOF

teach analyze lectures/week-02.qmd >> "$LOG_FILE" 2>&1
echo "" >> "$LOG_FILE"
echo -e "${GREEN}  ✓ Captured${NC}"

# ══════════════════════════════════════════════════════════════════════════════
# TEST 3: Batch Analysis
# ══════════════════════════════════════════════════════════════════════════════

echo -e "${BOLD}Test 3: Batch Analysis${NC}"

cat >> "$LOG_FILE" <<EOF

═══════════════════════════════════════════════════════════════
TEST 3: Batch Analyze All Lectures
═══════════════════════════════════════════════════════════════
Command: teach analyze --batch lectures/
Expected:
  - Processing: week-01.qmd, week-02.qmd, week-03.qmd
  - Total concepts: 8
  - Summary statistics shown

Output:
─────────────────────────────────────────────────────────────────
EOF

teach analyze --batch lectures/ >> "$LOG_FILE" 2>&1
echo "" >> "$LOG_FILE"
echo -e "${GREEN}  ✓ Captured${NC}"

# ══════════════════════════════════════════════════════════════════════════════
# TEST 4: Cache Usage (Second Run)
# ══════════════════════════════════════════════════════════════════════════════

echo -e "${BOLD}Test 4: Cache Usage (Second Run)${NC}"

cat >> "$LOG_FILE" <<EOF

═══════════════════════════════════════════════════════════════
TEST 4: Verify Cache Usage
═══════════════════════════════════════════════════════════════
Command: teach analyze --batch lectures/ (second run)
Expected:
  - Message about using cached data
  - Or: cache hit / from cache
  - Faster completion time

Output:
─────────────────────────────────────────────────────────────────
EOF

teach analyze --batch lectures/ >> "$LOG_FILE" 2>&1
echo "" >> "$LOG_FILE"
echo -e "${GREEN}  ✓ Captured${NC}"

# ══════════════════════════════════════════════════════════════════════════════
# TEST 5: Cache Directory Check
# ══════════════════════════════════════════════════════════════════════════════

echo -e "${BOLD}Test 5: Cache Directory Check${NC}"

cat >> "$LOG_FILE" <<EOF

═══════════════════════════════════════════════════════════════
TEST 5: Cache Directory Check
═══════════════════════════════════════════════════════════════
Command: ls -la .teach/analysis-cache/
Expected:
  - Cache directory exists
  - Cache files present

Output:
─────────────────────────────────────────────────────────────────
EOF

if [[ -d .teach/analysis-cache ]]; then
    ls -la .teach/analysis-cache/ >> "$LOG_FILE" 2>&1
    echo "" >> "$LOG_FILE"
    echo -e "${GREEN}  ✓ Cache directory exists${NC}"
else
    echo "Cache directory not found" >> "$LOG_FILE"
    echo -e "${YELLOW}  ✗ Cache directory not found${NC}"
fi

# ══════════════════════════════════════════════════════════════════════════════
# TEST 6: Validate Prerequisites
# ══════════════════════════════════════════════════════════════════════════════

echo -e "${BOLD}Test 6: Validate Prerequisites${NC}"

cat >> "$LOG_FILE" <<EOF

═══════════════════════════════════════════════════════════════
TEST 6: Validate Prerequisites
═══════════════════════════════════════════════════════════════
Command: teach validate lectures/*.qmd
Expected:
  - All files validate successfully
  - Proper dependency chain confirmed

Output:
─────────────────────────────────────────────────────────────────
EOF

teach validate lectures/*.qmd >> "$LOG_FILE" 2>&1
echo "" >> "$LOG_FILE"
echo -e "${GREEN}  ✓ Captured${NC}"

# ══════════════════════════════════════════════════════════════════════════════
# TEST 7: Detect Circular Dependency
# ══════════════════════════════════════════════════════════════════════════════

echo -e "${BOLD}Test 7: Circular Dependency Detection${NC}"

cat >> "$LOG_FILE" <<EOF

═══════════════════════════════════════════════════════════════
TEST 7: Detect Circular Dependency
═══════════════════════════════════════════════════════════════
Command: teach validate lectures/week-03-broken.qmd
Expected:
  - Error or warning about circular dependency
  - Mentions: correlation <-> linear-regression

Output:
─────────────────────────────────────────────────────────────────
EOF

teach validate lectures/week-03-broken.qmd >> "$LOG_FILE" 2>&1
echo "" >> "$LOG_FILE"
echo -e "${GREEN}  ✓ Captured${NC}"

# ══════════════════════════════════════════════════════════════════════════════
# TEST 8: Slide Optimization
# ══════════════════════════════════════════════════════════════════════════════

echo -e "${BOLD}Test 8: Slide Optimization${NC}"

cat >> "$LOG_FILE" <<EOF

═══════════════════════════════════════════════════════════════
TEST 8: Slide Optimization
═══════════════════════════════════════════════════════════════
Command: teach analyze --slide-breaks lectures/week-01.qmd
Expected:
  - Slide break suggestions
  - Key concepts identified
  - Timing estimates

Output:
─────────────────────────────────────────────────────────────────
EOF

teach analyze --slide-breaks lectures/week-01.qmd >> "$LOG_FILE" 2>&1
echo "" >> "$LOG_FILE"
echo -e "${GREEN}  ✓ Captured${NC}"

# ══════════════════════════════════════════════════════════════════════════════
# TEST 9: Analyze Week 3
# ══════════════════════════════════════════════════════════════════════════════

echo -e "${BOLD}Test 9: Analyze Week 3${NC}"

cat >> "$LOG_FILE" <<EOF

═══════════════════════════════════════════════════════════════
TEST 9: Analyze Week 3 (Advanced Concepts)
═══════════════════════════════════════════════════════════════
Command: teach analyze lectures/week-03.qmd
Expected:
  - Concepts: correlation, linear-regression
  - Prerequisites: descriptive-stats, distributions, inference
  - Advanced level concepts

Output:
─────────────────────────────────────────────────────────────────
EOF

teach analyze lectures/week-03.qmd >> "$LOG_FILE" 2>&1
echo "" >> "$LOG_FILE"
echo -e "${GREEN}  ✓ Captured${NC}"

# ══════════════════════════════════════════════════════════════════════════════
# TEST 10: Concept Graph
# ══════════════════════════════════════════════════════════════════════════════

echo -e "${BOLD}Test 10: View Concept Graph${NC}"

cat >> "$LOG_FILE" <<EOF

═══════════════════════════════════════════════════════════════
TEST 10: View Full Concept Graph
═══════════════════════════════════════════════════════════════
Command: cat .teach/concepts.json
Expected:
  - Full concept registry
  - All 8 concepts listed
  - Prerequisite mappings

Output:
─────────────────────────────────────────────────────────────────
EOF

if [[ -f .teach/concepts.json ]]; then
    cat .teach/concepts.json >> "$LOG_FILE" 2>&1
    echo "" >> "$LOG_FILE"
    echo -e "${GREEN}  ✓ Concepts file found${NC}"
else
    echo "concepts.json not found" >> "$LOG_FILE"
    echo -e "${YELLOW}  ✗ concepts.json not found${NC}"
fi

# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

cat >> "$LOG_FILE" <<EOF

═══════════════════════════════════════════════════════════════
DIAGNOSTIC COMPLETE
═══════════════════════════════════════════════════════════════
Completed: $(date '+%Y-%m-%d %H:%M:%S')

All command outputs have been captured above.
Review this file to verify what teach analyze commands actually produce.

Next steps:
1. Review this log file
2. Run interactive test: ./interactive-dog-teaching.zsh
3. Compare expected vs actual outputs

═══════════════════════════════════════════════════════════════
EOF

echo ""
echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Diagnostic complete!${NC}"
echo ""
echo -e "Results saved to: ${BOLD}$LOG_FILE${NC}"
echo ""
echo -e "Review the log file to see what teach analyze commands produce."
echo -e "Then run: ${BOLD}./interactive-dog-teaching.zsh${NC}"
echo -e "${BOLD}${BLUE}═══════════════════════════════════════════════════${NC}"
echo ""
