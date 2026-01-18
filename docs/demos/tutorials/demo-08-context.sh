#!/bin/zsh
# Scholar Enhancement Demo 8: Context Integration

# Change to flow-cli directory and source plugin
cd /Users/dt/.git-worktrees/flow-cli/feature/teaching-flags
source flow.plugin.zsh 2>/dev/null

# Change back to demos directory
cd docs/demos/tutorials

# Clear screen
clear
sleep 1

# Show context integration command
echo "❯ teach assignment \"Hypothesis Testing Practice\" --with-readings"
sleep 2.5

# Simulate context-aware generation
cat << 'EOF'

🎓 Scholar Enhancement - Context Integration

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📚 Loading Course Context...

   Config:          .flow/teach-config.yml
   Readings:        content/readings/ (3 files)
   Datasets:        content/datasets/ (5 files)
   Prior content:   lectures/, quizzes/ (analyzed)

🔍 Context Discovery:

   Required Readings:
     ✓ "Hypothesis Testing Fundamentals" (Chapter 7)
     ✓ "Type I and Type II Errors" (Supplemental)
     ✓ "Power Analysis Tutorial" (Online resource)

   Available Datasets:
     ✓ clinical_trial.csv (200 obs, 5 vars)
     ✓ advertising.csv (150 obs, 4 vars)
     ✓ manufacturing.csv (500 obs, 3 vars)

   Previous Coverage:
     ✓ Week 6 lecture: Null hypothesis, p-values
     ✓ Week 6 quiz: Basic hypothesis test questions
     ✓ Prerequisites: Confidence intervals (Week 5)

🎯 Generating Context-Aware Assignment...

   Integration Points:
     • References specific readings (Chapter 7, section 7.2-7.4)
     • Uses clinical_trial.csv dataset from course materials
     • Builds on Week 6 lecture concepts
     • Connects to Week 5 CI material
     • Includes questions from course quiz bank

   Problem Set:
     1. Reading comprehension (Type I/II errors from Chapter 7)
     2. Dataset analysis (clinical_trial.csv hypothesis test)
     3. Power calculation (uses supplemental reading)
     4. Interpretation (connects to lecture examples)
     5. Application (manufacturing.csv analysis)

📊 Enhanced with Course Materials:

   ✓ Cited 3 required readings with page numbers
   ✓ Included 2 course datasets with variable descriptions
   ✓ Referenced Week 6 lecture notation (consistent symbols)
   ✓ Used examples from prior quizzes (familiar context)

✅ Generated: assignments/hw3-hypothesis-testing.qmd

   Problems:   5 (mix of theory and applied)
   Datasets:   2 from course materials
   Readings:   3 references with citations
   Duration:   90 minutes estimated
   Format:     Quarto with R code chunks

   Context files referenced:
     • content/readings/chapter7.pdf (pages 142-156)
     • content/datasets/clinical_trial.csv
     • lectures/week06-hypothesis-tests.qmd
     • quizzes/week06-quiz.qmd (for consistent notation)

EOF

# Pause for reading
sleep 8

echo "❯ "
sleep 1
