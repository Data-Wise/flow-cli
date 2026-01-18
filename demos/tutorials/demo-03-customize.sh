#!/bin/zsh
# Scholar Enhancement Demo 3: Style Customization

# Change to flow-cli directory and source plugin
cd /Users/dt/.git-worktrees/flow-cli/feature/teaching-flags
source flow.plugin.zsh 2>/dev/null

# Change back to demos directory
cd docs/demos/tutorials

# Clear screen
clear
sleep 1

# Show command
echo "❯ teach quiz \"Hypothesis Testing\" --style rigorous --technical-depth high"
sleep 2.5

# Simulate Scholar Enhancement output
cat << 'EOF'

🎓 Scholar Enhancement - Generating Quiz

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Topic:            Hypothesis Testing
Style Preset:     rigorous (definitions + explanation + math + proof)
Technical Depth:  high

📝 Style Customization Applied:
   ✓ Formal mathematical definitions
   ✓ Statistical theory explanations
   ✓ Proof-based questions
   ✓ Advanced technical notation
   ✓ Rigorous problem solving

🎯 Question Types:
   • Theoretical foundations (40%)
   • Mathematical proofs (25%)
   • Statistical derivations (20%)
   • Applied problem solving (15%)

📊 Content Characteristics:
   • Graduate-level rigor
   • Heavy mathematical notation
   • Proof verification questions
   • Multi-step derivations

✅ Generated: quizzes/hypothesis-testing.qmd (15 questions)

   Difficulty:  Advanced/Graduate
   Duration:    60 minutes
   Topics:      Null hypothesis, Type I/II errors, p-values, power
   Format:      Mix of theoretical and computational

EOF

# Pause for reading
sleep 7

echo "❯ "
sleep 1
