# Scholar Enhancement Tutorial Demo 4: Create Lesson Plan
# Shows creating a YAML lesson plan for week-based generation

Output docs/demos/tutorials/scholar-04-lesson-plan.gif

Set FontSize 16
Set Width 1200
Set Height 800
Set Theme "Catppuccin Mocha"
Set Padding 20

# Create lesson plans directory
Type "mkdir -p .flow/lesson-plans"
Sleep 500ms
Enter
Sleep 1s

# Create lesson plan file
Type "cat > .flow/lesson-plans/week-08.yml <<'EOF'"
Sleep 500ms
Enter
Type "week: 8"
Enter
Type "topic: \"Multiple Regression\""
Enter
Type "style: computational"
Enter
Type ""
Enter
Type "objectives:"
Enter
Type "  - \"Understand multiple regression model assumptions\""
Enter
Type "  - \"Interpret regression coefficients correctly\""
Enter
Type ""
Enter
Type "subtopics:"
Enter
Type "  - \"Model specification\""
Enter
Type "  - \"Coefficient interpretation\""
Enter
Type "  - \"Multicollinearity\""
Enter
Type "EOF"
Sleep 500ms
Enter
Sleep 2s

# Verify
Type "cat .flow/lesson-plans/week-08.yml"
Sleep 500ms
Enter
Sleep 2s
