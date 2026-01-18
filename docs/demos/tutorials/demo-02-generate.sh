#!/bin/zsh
# Scholar Enhancement Demo 2: Basic Generation

# Change to flow-cli directory and source plugin
cd /Users/dt/.git-worktrees/flow-cli/feature/teaching-flags
source flow.plugin.zsh 2>/dev/null

# Change back to demos directory
cd docs/demos/tutorials

# Clear screen
clear
sleep 1

# Show command
echo "❯ teach slides \"Introduction to Statistics\" --style conceptual"
sleep 2

# Simulate Scholar Enhancement output
cat << 'EOF'

🎓 Scholar Enhancement - Generating Slides

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Topic:  Introduction to Statistics
Style:  conceptual (explanation + definitions + examples)

📝 Content Structure:
   ✓ Title slide
   ✓ Learning objectives
   ✓ Key definitions
   ✓ Conceptual explanations
   ✓ Practical examples
   ✓ Summary & takeaways

📊 Included Sections:
   • What is statistics?
   • Descriptive vs. inferential statistics
   • Population vs. sample
   • Variables and data types
   • Real-world applications

✅ Generated: slides/intro-statistics.qmd (1,247 words)

   Duration: ~45 minutes
   Slides:   15-20
   Format:   Quarto reveal.js

EOF

# Pause for reading
sleep 6

echo "❯ "
sleep 1
