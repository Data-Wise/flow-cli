# Scholar Enhancement Tutorial Demo 7: Revision Workflow
# Shows improving existing content with revision menu

Output docs/demos/tutorials/scholar-07-revision.gif

Set FontSize 16
Set Width 1200
Set Height 800
Set Theme "Catppuccin Mocha"
Set Padding 20

# Create test slides first
Type "teach slides \"Linear Regression\" --style computational -o test-slides.qmd"
Sleep 500ms
Enter
Sleep 2s

# Now revise them
Type "teach slides --revise test-slides.qmd"
Sleep 500ms
Enter
Sleep 2s

# Show diff preview
Type "# 📝 Revising: test-slides.qmd"
Sleep 1s
Enter
Type "# 📅 Last modified: 2026-01-17 14:30"
Sleep 1s
Enter
Sleep 1s

# Show revision menu
Type "# 📝 Revision Options"
Sleep 1s
Enter
Type "# What would you like to improve?"
Enter
Sleep 1s
Type "#   [1] Add missing content          Fill gaps, add sections"
Enter
Type "#   [2] Improve clarity/organization Restructure, clarify"
Enter
Type "#   [3] Fix errors/inconsistencies   Correct mistakes"
Enter
Type "#   [4] Update examples/exercises    Refresh examples"
Enter
Type "#   [5] Enhance formatting/style     Polish presentation"
Enter
Type "#   [6] Custom instructions          Your own guidance"
Enter
Sleep 2s
Type "2"
Sleep 500ms
Enter
Sleep 2s

# Show result
Type "# Improving clarity and organization..."
Sleep 2s
Type "# ✅ Revision complete"
Sleep 2s
