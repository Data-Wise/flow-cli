#!/bin/zsh
# Scholar Enhancement Demo 7: Week-Based Generation

# Change to flow-cli directory and source plugin
cd /Users/dt/.git-worktrees/flow-cli/feature/teaching-flags
source flow.plugin.zsh 2>/dev/null

# Change back to demos directory
cd docs/demos/tutorials

# Clear screen
clear
sleep 1

# Show week-based command
echo "❯ teach quiz --week 5"
sleep 2

# Simulate week-based generation
cat << 'EOF'

🎓 Scholar Enhancement - Week-Based Generation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📅 Auto-Detecting from teach-config.yml

   Week:    5
   Dates:   Feb 10 - Feb 14, 2026
   Topic:   Confidence Intervals (from semester schedule)

📚 Course Configuration Loaded:
   ✓ Course: STAT 101 - Introduction to Statistical Methods
   ✓ Semester: Spring 2026
   ✓ Style: conceptual (default from config)
   ✓ Difficulty: beginner (from config)

🎯 Week 5 Learning Objectives:
   • Construct confidence intervals for population mean
   • Interpret confidence level correctly
   • Choose appropriate confidence level
   • Calculate margin of error

📋 Generating Quiz for Week 5...

   Topic Source:    teach-config.yml week 5
   Style:           conceptual (course default)
   Questions:       10 (recommended for weekly quiz)
   Duration:        15 minutes

   Question Coverage:
     ✓ CI construction (40%)
     ✓ Interpretation (30%)
     ✓ Margin of error (20%)
     ✓ Confidence level (10%)

   Aligned with:
     • Prior weeks: Sampling distributions (Week 4)
     • Current week: Confidence intervals
     • Prerequisite: Normal distribution (Week 3)

✅ Generated: quizzes/week05-confidence-intervals.qmd

   Questions:  10
   Duration:   15 minutes
   Format:     Mix of MC and short answer
   Aligned:    Week 5 learning objectives

   Auto-naming: week05-confidence-intervals.qmd
   (Based on week number and detected topic)

EOF

# Pause for reading
sleep 7

echo "❯ "
sleep 1
