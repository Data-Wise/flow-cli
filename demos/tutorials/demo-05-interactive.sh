#!/bin/zsh
# Scholar Enhancement Demo 5: Interactive Mode (Wizard)

# Change to flow-cli directory and source plugin
cd /Users/dt/.git-worktrees/flow-cli/feature/teaching-flags
source flow.plugin.zsh 2>/dev/null

# Change back to demos directory
cd docs/demos/tutorials

# Clear screen
clear
sleep 1

# Show command
echo "❯ teach exam --interactive"
sleep 2

# Simulate interactive wizard
cat << 'EOF'

🎓 Scholar Enhancement - Interactive Mode

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Interactive Exam Generation Wizard

Step 1 of 5: Exam Topic
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

What is the main topic for this exam?
EOF

sleep 1.5
echo -n "> "
sleep 0.5
echo "Statistical Inference"
sleep 1.5

cat << 'EOF'

Step 2 of 5: Style Preset
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Choose a style preset:
  1) conceptual     - Explanation + definitions + examples
  2) computational  - Examples + code + practice
  3) rigorous       - Definitions + math + proofs
  4) applied        - Examples + code + real-world

EOF

sleep 1.5
echo -n "> "
sleep 0.5
echo "4"
sleep 1.5

cat << 'EOF'

Selected: applied (examples + code + real-world)

Step 3 of 5: Number of Questions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

How many questions should the exam include? [10-50]
EOF

sleep 1.5
echo -n "> "
sleep 0.5
echo "20"
sleep 1.5

cat << 'EOF'

Step 4 of 5: Exam Duration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

How long should students have? (minutes) [30-180]
EOF

sleep 1.5
echo -n "> "
sleep 0.5
echo "60"
sleep 1.5

cat << 'EOF'

Step 5 of 5: Difficulty Level
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Select difficulty level:
  1) beginner       - Introductory concepts
  2) intermediate   - Standard undergraduate
  3) advanced       - Upper-level/graduate

EOF

sleep 1.5
echo -n "> "
sleep 0.5
echo "2"
sleep 2

cat << 'EOF'

Selected: intermediate


✅ Configuration Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Topic:       Statistical Inference
Style:       applied (examples + code + real-world)
Questions:   20
Duration:    60 minutes
Difficulty:  intermediate

🎯 Generating Exam...

   ✓ Creating question bank
   ✓ Balancing question types
   ✓ Adding R code examples
   ✓ Including real datasets
   ✓ Generating answer key

✅ Generated: exams/statistical-inference.qmd (20 questions)

   Question Types:
     • Conceptual (30%) - 6 questions
     • Computational (40%) - 8 questions
     • Code interpretation (20%) - 4 questions
     • Short answer (10%) - 2 questions

   Answer Key: exams/statistical-inference-answers.qmd

EOF

# Pause for reading
sleep 6

echo "❯ "
sleep 1
