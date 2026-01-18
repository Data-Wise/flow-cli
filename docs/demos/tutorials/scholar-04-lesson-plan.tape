# Scholar Enhancement Tutorial Demo 4: Create Lesson Plan
# Shows creating a YAML lesson plan for week-based generation

Output scholar-04-lesson-plan.gif

Set FontSize 13
Set Width 1000
Set Height 650
Set Theme "Catppuccin Mocha"
Set Padding 20
Set TypingSpeed 30ms

# Create lesson plan
Type "cat > .flow/lesson-plans/week-08.yml <<'EOF'"
Sleep 300ms
Enter
Sleep 300ms
Type "week: 8"
Sleep 200ms
Enter
Type "topic: \"Multiple Regression\""
Sleep 200ms
Enter
Type "style: computational"
Sleep 200ms
Enter
Type ""
Enter
Type "objectives:"
Sleep 200ms
Enter
Type "  - \"Understand model assumptions\""
Sleep 200ms
Enter
Type "  - \"Interpret coefficients\""
Sleep 200ms
Enter
Type ""
Enter
Type "subtopics:"
Sleep 200ms
Enter
Type "  - \"Model specification\""
Sleep 200ms
Enter
Type "  - \"Multicollinearity\""
Sleep 200ms
Enter
Type "EOF"
Sleep 500ms
Enter
Sleep 1s

# Verify
Type ""
Enter
Type "$ cat .flow/lesson-plans/week-08.yml"
Enter
Sleep 500ms
Type@300ms "week: 8"
Enter
Type@300ms "topic: \"Multiple Regression\""
Enter
Type@300ms "style: computational"
Enter
Type@300ms "objectives:"
Enter
Type@300ms "  - \"Understand model assumptions\""
Enter
Sleep 2s
