#!/bin/zsh
# Scholar Enhancement Demo 4: YAML-Driven Lesson Plans

# Change to demo course directory
cd ~/projects/teaching/scholar-demo-course

# Source flow-cli
source /Users/dt/.git-worktrees/flow-cli/feature/teaching-flags/flow.plugin.zsh 2>/dev/null

# Clear screen
clear
sleep 1

# Show command
echo "❯ teach lecture --lesson content/lesson-plans/week03.yml"
sleep 2.5

# Simulate Scholar Enhancement output with lesson plan integration
cat << 'EOF'

🎓 Scholar Enhancement - YAML-Driven Content Generation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Loading Lesson Plan: content/lesson-plans/week03.yml

Week:      3
Topic:     Introduction to Linear Regression
Duration:  75 minutes
Level:     Undergraduate

📚 Lesson Plan Structure:
   ✓ 4 learning objectives (understand → apply → analyze)
   ✓ 4 main topics with 12 subtopics
   ✓ 5 structured activities (lecture → code demo → discussion)
   ✓ Reading materials and datasets specified
   ✓ Teaching style overrides applied

🎯 Content Generation Based on Plan:
   • Using OLS derivation activity (20 min, step-by-step)
   • Including R implementation demo (mtcars dataset)
   • Incorporating board work for theory section
   • Adding think-pair-share for practice

📝 Generating Lecture Outline:
   ✓ Opening: Review correlation, introduce regression (5 min)
   ✓ Theory: Model formulation, OLS derivation (25 min)
   ✓ Application: R demo with visualization (25 min)
   ✓ Practice: Coefficient interpretation (15 min)
   ✓ Closing: Summary & homework preview (5 min)

✅ Generated: lectures/week03-linear-regression.qmd (2,847 words)

   Sections:     5 (matches lecture structure)
   Code blocks:  8 (R examples with ggplot2)
   Derivations:  2 (OLS with intuition-first approach)
   Activities:   5 (fully specified with timing)
   Format:       Quarto with reveal.js support

EOF

# Pause for reading
sleep 8

echo "❯ "
sleep 1
