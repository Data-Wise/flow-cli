# Scholar Enhancement Tutorial Demo 6: Interactive Mode
# Shows step-by-step wizard for content generation

Output scholar-06-interactive.gif

Set FontSize 16
Set Width 1200
Set Height 800
Set Theme "Catppuccin Mocha"
Set Padding 20

# Start interactive mode
Type "teach slides -i"
Sleep 500ms
Enter
Sleep 1s

# Show topic menu
Type "# 📅 Select Week/Topic"
Sleep 1s
Enter
Type "#   [ 1] Week  1  Introduction to Statistics"
Enter
Type "#   [ 2] Week  2  Probability Basics"
Enter
Type "#   ..."
Enter
Type "#   [ 8] Week  8  Multiple Regression"
Enter
Sleep 1s
Type "8"
Sleep 500ms
Enter
Sleep 2s

# Show style menu
Type "# 📚 Content Style"
Sleep 1s
Enter
Type "#   [1] conceptual    Explanation + definitions + examples"
Enter
Type "#   [2] computational Explanation + examples + code + practice"
Enter
Type "#   [3] rigorous      Definitions + explanation + math + proofs"
Enter
Type "#   [4] applied       Explanation + examples + code + practice"
Enter
Sleep 1s
Type "2"
Sleep 500ms
Enter
Sleep 2s

# Show result
Type "# → Generating slides for Week 8 with computational style"
Sleep 2s
Type "# ✅ Slides created"
Sleep 2s
