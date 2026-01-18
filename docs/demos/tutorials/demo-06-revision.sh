#!/bin/zsh
# Scholar Enhancement Demo 6: Revision Workflow

# Change to flow-cli directory and source plugin
cd /Users/dt/.git-worktrees/flow-cli/feature/teaching-flags
source flow.plugin.zsh 2>/dev/null

# Change back to demos directory
cd docs/demos/tutorials

# Clear screen
clear
sleep 1

# Show revision command
echo "❯ teach slides --revise slides-v1.md --feedback \"Add more practical examples\""
sleep 2.5

# Simulate revision workflow
cat << 'EOF'

🎓 Scholar Enhancement - Revision Workflow

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📄 Loading Existing Content: slides-v1.md

   Original:    slides-v1.md (847 words, 12 slides)
   Topic:       ANOVA Basics
   Style:       conceptual
   Generated:   2026-01-15

📝 User Feedback:
   "Add more practical examples"

🔍 Analyzing Content for Improvements:
   ✓ Current example count: 2
   ✓ Identified gaps: Need industry applications
   ✓ Revision strategy: Add 3 real-world examples
   ✓ Preserve: Existing theory sections

🎯 Revision Plan:
   • Keep: Theoretical foundation (slides 1-5)
   • Enhance: Examples section (slides 6-9)
   • Add: 3 new practical examples
     - Manufacturing quality control
     - Clinical trial comparisons
     - Marketing A/B testing
   • Update: Summary with new examples (slide 12)

📊 Generating Revised Content...

   ✓ Added manufacturing example with sample data
   ✓ Included clinical trial visualization
   ✓ Inserted marketing campaign comparison
   ✓ Updated learning objectives
   ✓ Revised summary to reference new examples

✅ Generated: slides-v2.md (1,184 words, 15 slides)

   Changes:
     • +337 words (40% increase)
     • +3 slides (25% more content)
     • +3 practical examples with code
     • Enhanced real-world applications
     • Preserved original theory intact

   Revision: slides-v1.md → slides-v2.md

EOF

# Pause for reading
sleep 7

echo "❯ "
sleep 1
